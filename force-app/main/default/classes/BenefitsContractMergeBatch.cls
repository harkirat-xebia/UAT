/**
 * @description Consolidates an Account's Benefits contracts onto a single master contract by
 *              cloning the contract line items of every other Benefits contract onto it.
 *              The master is the Activated contract carrying a TRC line (oldest StartDate wins);
 *              if no TRC contract exists, the oldest Activated Benefits contract is used.
 *              Source contracts and their line items are never modified.
 *              Engagement contracts (ER_Contract_Type__c = 'Employee Engagement Platform') are excluded.
 *
 * Run from Execute Anonymous. Keep the scope size low: each account's line items are held in
 * memory at once, so scope 1-5 is the safe range for accounts with large line item volumes.
 *
 *   // dry run, no DML
 *   Database.executeBatch(new BenefitsContractMergeBatch(new Set<Id>{ '001AU00000ae9KSYAY' }, true), 1);
 *
 *   // live run
 *   Database.executeBatch(new BenefitsContractMergeBatch(new Set<Id>{ '001AU00000ae9KSYAY' }, false), 1);
 *
 *   // full org run (all accounts with 2+ Benefits contracts)
 *   Database.executeBatch(new BenefitsContractMergeBatch(null, false), 5);
 *   
 *   //The excluded contracts
 *   Contracts in the Luxembourg business unit, or with a pricebook name containing
 *   Luxembourg, Reduction or Mobility, are excluded.
 */
public without sharing class BenefitsContractMergeBatch implements Database.Batchable<SObject>, Database.Stateful {
  private static final String TRC_SOLUTION_CODE = 'TRC';
  private static final String BENEFITS_CONTRACT_CATEGORY = 'Benefits';
  private static final String STATUS_ACTIVATED = 'Activated';
  private static final String SOLUTIONS_SEPARATOR = ' / ';
  private static final Set<String> SOURCE_STATUSES = new Set<String>{ STATUS_ACTIVATED, 'In Approval Process' };
  private static final Set<String> BYPASSED_TRIGGERS = new Set<String>{
    'ContractTrigger',
    'ER_ContractLineItemTrigger'
  };
  /** Caps stateful heap growth on large runs. */
  private static final Integer MAX_SUMMARY_ROWS = 1000;

  private final Set<Id> accountIds;
  private final Boolean dryRun;

  private Integer accountsEvaluated = 0;
  private Integer accountsMerged = 0;
  private Integer accountsSkipped = 0;
  private Integer accountsAlreadyMerged = 0;
  private Integer linesCloned = 0;
  private Integer lineErrors = 0;
  private Boolean summaryTruncated = false;
  private final List<String> summary = new List<String>();
  private final List<String> successfulMergedAccountIds = new List<String>();
  private String currentJobId;
  private final List<APER45_ErrorLog_Management.ErrorLogEntry> dmlErrorEntries =
    new List<APER45_ErrorLog_Management.ErrorLogEntry>();

  /** Transient so the per-chunk line item cache is never carried in Stateful serialization. */
  private transient Map<Id, List<ER_ContractLineItem__c>> linesByContractId;

  /** Source line ids that already have a clone on the master, so re-runs never duplicate. */
  private transient Set<Id> clonedSourceLineIds;

  private static final String EXCLUDED_BUSINESS_UNIT = 'Luxembourg';
  private static final List<String> EXCLUDED_PRICEBOOK_KEYWORDS = new List<String>{
    'Luxembourg',
    'Reduction',
    'Mobility'
  };

  /**
   * @description Constructs the batch.
   * @param accountIds Accounts to process. Pass null or an empty set to process every eligible account.
   * @param dryRun     When true the batch plans and logs the merge but performs no DML.
   */
  public BenefitsContractMergeBatch(Set<Id> accountIds, Boolean dryRun) {
    this.accountIds = accountIds;
    this.dryRun = dryRun == true;
  }

  /**
   * @description Selects the accounts in scope.
   * @param context Batch context.
   * @return Locator over the accounts to evaluate.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    if (accountIds == null || accountIds.isEmpty()) {
      Set<Id> excludedPricebookIds = getExcludedPricebookIds();
      if (excludedPricebookIds.isEmpty()) {
        return Database.getQueryLocator(
          [
            SELECT Id, Name
            FROM Account
            WHERE Id IN (
              SELECT AccountId
              FROM Contract
              WHERE Status IN :SOURCE_STATUSES
                AND Contract_Category__c = :BENEFITS_CONTRACT_CATEGORY
                AND (ER_BUPicklist__c = NULL OR ER_BUPicklist__c != :EXCLUDED_BUSINESS_UNIT)
            )
          ]
        );
      }
      return Database.getQueryLocator(
        [
          SELECT Id, Name
          FROM Account
          WHERE Id IN (
            SELECT AccountId
            FROM Contract
            WHERE Status IN :SOURCE_STATUSES
              AND Contract_Category__c = :BENEFITS_CONTRACT_CATEGORY
              AND (ER_BUPicklist__c = NULL OR ER_BUPicklist__c != :EXCLUDED_BUSINESS_UNIT)
              AND (Pricebook2Id = NULL OR Pricebook2Id NOT IN :excludedPricebookIds)
          )
        ]
      );
    }
    return Database.getQueryLocator([SELECT Id, Name FROM Account WHERE Id IN :accountIds]);
  }

  private Set<Id> getExcludedPricebookIds() {
    Set<Id> excludedIds = new Set<Id>();
    for (Pricebook2 pricebook : [
      SELECT Id
      FROM Pricebook2
      WHERE Name LIKE '%Luxembourg%'
        OR Name LIKE '%Reduction%'
        OR Name LIKE '%Mobility%'
    ]) {
      excludedIds.add(pricebook.Id);
    }
    return excludedIds;
  }

  /**
   * @description Merges the Benefits contracts of each account in the chunk.
   * @param context Batch context.
   * @param scope   Accounts to merge.
   */
  public void execute(Database.BatchableContext context, List<Account> scope) {
    currentJobId = context == null ? null : context.getJobId();
    UtilsBypass.setBypassedTriggersByApex(BYPASSED_TRIGGERS);
    try {
      mergeAccounts(new Map<Id, Account>(scope));
    } catch (Exception e) {
      addSummary('FATAL: ' + e.getTypeName() + ' - ' + e.getMessage() + ' | ' + e.getStackTraceString());
      APER45_ErrorLog_Management.logException(e, 'BenefitsContractMergeBatch', 'execute');
    } finally {
      flushDmlErrors();
      UtilsBypass.reset();
    }
  }

  /**
   * @description Writes the run summary to the debug log.
   * @param context Batch context.
   */
  public void finish(Database.BatchableContext context) {
    writeSuccessfulAccountLogs();
    System.debug(LoggingLevel.INFO, '=== BenefitsContractMergeBatch ' + (dryRun ? '[DRY RUN]' : '[LIVE]') + ' ===');
    System.debug(LoggingLevel.INFO, 'Accounts evaluated     : ' + accountsEvaluated);
    System.debug(LoggingLevel.INFO, 'Accounts merged        : ' + accountsMerged);
    System.debug(LoggingLevel.INFO, 'Accounts already merged: ' + accountsAlreadyMerged);
    System.debug(LoggingLevel.INFO, 'Accounts skipped       : ' + accountsSkipped);
    System.debug(LoggingLevel.INFO, 'Line items cloned      : ' + linesCloned);
    System.debug(LoggingLevel.INFO, 'Line item errors       : ' + lineErrors);
    for (String row : summary) {
      System.debug(LoggingLevel.INFO, row);
    }
    if (summaryTruncated) {
      System.debug(LoggingLevel.INFO, '... summary truncated at ' + MAX_SUMMARY_ROWS + ' rows.');
    }
  }

  private void mergeAccounts(Map<Id, Account> accountsById) {
    Map<Id, List<Contract>> contractsByAccount = loadBenefitsContracts(accountsById.keySet());
    if (contractsByAccount.isEmpty()) {
      return;
    }

    Set<Id> contractIds = new Set<Id>();
    for (List<Contract> contracts : contractsByAccount.values()) {
      for (Contract contractRecord : contracts) {
        contractIds.add(contractRecord.Id);
      }
    }
    loadLineItems(contractIds);
    loadClonedSourceLineIds(contractIds);

    MergePlan plan = new MergePlan();
    for (Id accountId : contractsByAccount.keySet()) {
      accountsEvaluated++;
      try {
        planAccount(accountsById.get(accountId), contractsByAccount.get(accountId), plan);
      } catch (Exception e) {
        accountsSkipped++;
        addSummary('ERROR planning account ' + accountId + ': ' + e.getTypeName() + ' - ' + e.getMessage());
      }
    }

    if (dryRun) {
      addSummary(
        'DRY RUN - no DML performed. Would clone ' + plan.clones.size() + ' line item(s) and update ' +
        plan.masters.size() + ' master contract(s).'
      );
      return;
    }

    Map<Id, Integer> successfulCloneCounts = insertClones(plan.clones);
    markSuccessfulMasters(plan, successfulCloneCounts.keySet());
    Set<Id> updatedMasterIds = updateMasters(plan.masters);
    trackSuccessfulAccounts(plan, successfulCloneCounts, updatedMasterIds);
  }

  private void markSuccessfulMasters(MergePlan plan, Set<Id> masterIds) {
    Map<Id, Contract> updatesById = new Map<Id, Contract>(plan.masters);
    for (Id masterId : masterIds) {
      if (!updatesById.containsKey(masterId)) {
        updatesById.put(masterId, new Contract(Id = masterId));
      }
      updatesById.get(masterId).Is_Master_Contract__c = true;
    }
    plan.masters.clear();
    plan.masters.addAll(updatesById.values());
  }

  private void planAccount(Account account, List<Contract> contracts, MergePlan plan) {
    if (contracts.size() < 2) {
      skip(account, 'only ' + contracts.size() + ' eligible Benefits contract(s) in Activated/In Approval Process');
      return;
    }

    List<Contract> discountedContracts = findDiscountedContracts(contracts);
    if (discountedContracts.size() > 1) {
      skip(account, 'multiple eligible contracts have discounted line items');
      return;
    }

    Contract master = selectMaster(contracts);
    if (master == null) {
      skip(account, 'no Activated Benefits contract with TRC available to act as master');
      return;
    }

    CloneSet collected = collectClones(contracts, master);
    Contract refreshed = rebuildSolutions(master, collected);
    refreshed = applyDiscountOfferDate(master, refreshed, discountedContracts);
    if (collected.clones.isEmpty()) {
      if (refreshed != null) {
        plan.masters.add(refreshed);
      }
      accountsAlreadyMerged++;
      addSummary(
        'NOOP ' + account.Name + ' [' + account.Id + ']: master ' + master.ContractNumber +
        ' already holds every source line item.'
      );
      return;
    }

    accountsMerged++;
    addSummary(
      'MERGE ' + account.Name + ' [' + account.Id + '] -> master ' + master.ContractNumber +
      ' [' + master.Id + '] | lines=' + collected.clones.size() +
      ' | sources=' + String.join(collected.sourceLabels, ', ')
    );

    plan.clones.addAll(collected.clones);
    MergeAuditData auditData = new MergeAuditData();
    auditData.accountId = account.Id;
    auditData.expectedCloneCount = collected.clones.size();
    plan.auditByMaster.put(master.Id, auditData);
    if (refreshed != null) {
      plan.masters.add(refreshed);
    }
  }

  private List<Contract> findDiscountedContracts(List<Contract> contracts) {
    List<Contract> discounted = new List<Contract>();
    for (Contract candidate : contracts) {
      if (hasOriginalDiscountLine(linesByContractId.get(candidate.Id))) {
        discounted.add(candidate);
      }
    }
    return discounted;
  }

  private Boolean hasOriginalDiscountLine(List<ER_ContractLineItem__c> lines) {
    if (lines == null) {
      return false;
    }
    for (ER_ContractLineItem__c line : lines) {
      // Imported clones must not make the master count as a second discounted contract on re-runs.
      if (line.Contract_Line_Item__c != null) {
        continue;
      }
      if ('Discount'.equalsIgnoreCase(line.ER_Line_Type__c) ||
          (line.ER_Product2__r != null && 'Discount'.equalsIgnoreCase(line.ER_Product2__r.ER_Type__c))) {
        return true;
      }
    }
    return false;
  }

  private Contract applyDiscountOfferDate(Contract master, Contract refreshed, List<Contract> discounted) {
    if (discounted.isEmpty() || discounted[0].Offer_Validity_End_Date__c == null ||
        discounted[0].Offer_Validity_End_Date__c == master.Offer_Validity_End_Date__c) {
      return refreshed;
    }
    Contract updateRecord = refreshed == null ? new Contract(Id = master.Id) : refreshed;
    updateRecord.Offer_Validity_End_Date__c = discounted[0].Offer_Validity_End_Date__c;
    addSummary('OFFER DATE master ' + master.ContractNumber + ': ' + master.Offer_Validity_End_Date__c +
      ' -> ' + updateRecord.Offer_Validity_End_Date__c + ' from contract ' + discounted[0].ContractNumber);
    return updateRecord;
  }

  private CloneSet collectClones(List<Contract> contracts, Contract master) {
    CloneSet collected = new CloneSet();
    for (Contract source : contracts) {
      if (source.Id == master.Id) {
        continue;
      }
      List<ER_ContractLineItem__c> sourceLines = linesByContractId.get(source.Id);
      if (sourceLines == null || sourceLines.isEmpty()) {
        continue;
      }
      collected.sourceSolutions.add(source.ER_Solutions__c);

      Integer added = 0;
      for (ER_ContractLineItem__c sourceLine : sourceLines) {
        if (clonedSourceLineIds.contains(sourceLine.Id)) {
          continue;
        }
        collected.clones.add(buildClone(sourceLine, master.Id));
        added++;
      }
      if (added > 0) {
        collected.sourceLabels.add(source.ContractNumber + '(' + source.Status + ':' + added + ')');
      }
    }
    return collected;
  }

  private class MergePlan {
    private final List<ER_ContractLineItem__c> clones = new List<ER_ContractLineItem__c>();
    private final List<Contract> masters = new List<Contract>();
    private final Map<Id, MergeAuditData> auditByMaster = new Map<Id, MergeAuditData>();
  }

  private class MergeAuditData {
    private Id accountId;
    private Integer expectedCloneCount;
  }

  private class CloneSet {
    private final List<ER_ContractLineItem__c> clones = new List<ER_ContractLineItem__c>();
    private final List<String> sourceLabels = new List<String>();
    private final List<String> sourceSolutions = new List<String>();
  }

  private Map<Id, List<Contract>> loadBenefitsContracts(Set<Id> accountIdsInScope) {
    Map<Id, List<Contract>> contractsByAccount = new Map<Id, List<Contract>>();
    for (Contract contractRecord : [
      SELECT Id, ContractNumber, AccountId, Status, StartDate, Contract_Category__c, ER_Contract_Type__c,
        ER_Solutions__c, ER_BUPicklist__c, Pricebook2Id, Pricebook2.Name, Offer_Validity_End_Date__c
      FROM Contract
      WHERE AccountId IN :accountIdsInScope AND Status IN :SOURCE_STATUSES
        AND Contract_Category__c = :BENEFITS_CONTRACT_CATEGORY
      ORDER BY StartDate ASC NULLS LAST, CreatedDate ASC, ContractNumber ASC
    ]) {
      if (isExcludedContract(contractRecord)) {
        continue;
      }
      if (!contractsByAccount.containsKey(contractRecord.AccountId)) {
        contractsByAccount.put(contractRecord.AccountId, new List<Contract>());
      }
      contractsByAccount.get(contractRecord.AccountId).add(contractRecord);
    }
    return contractsByAccount;
  }

  private void loadLineItems(Set<Id> contractIds) {
    linesByContractId = new Map<Id, List<ER_ContractLineItem__c>>();
    String soql =
      'SELECT ' + getCloneableFieldList() + ', ER_Solution__c, ER_Product2__r.ER_Type__c ' +
      'FROM ER_ContractLineItem__c ' +
      'WHERE ER_Contract__c IN :contractIds ' +
      'ORDER BY ER_Contract__c, ER_LineNumber__c ASC NULLS LAST, CreatedDate ASC';
    for (ER_ContractLineItem__c line : (List<ER_ContractLineItem__c>) Database.query(soql)) {
      if (!linesByContractId.containsKey(line.ER_Contract__c)) {
        linesByContractId.put(line.ER_Contract__c, new List<ER_ContractLineItem__c>());
      }
      linesByContractId.get(line.ER_Contract__c).add(line);
    }
  }

  /**
   * @description Reads the clone back-links already present on the account's contracts so a re-run
   *              never copies the same source line twice.
   * @param contractIds Contracts in the current chunk.
   */
  private void loadClonedSourceLineIds(Set<Id> contractIds) {
    clonedSourceLineIds = new Set<Id>();
    for (ER_ContractLineItem__c line : [
      SELECT Contract_Line_Item__c
      FROM ER_ContractLineItem__c
      WHERE ER_Contract__c IN :contractIds AND Contract_Line_Item__c != NULL
    ]) {
      clonedSourceLineIds.add(line.Contract_Line_Item__c);
    }
  }

  /**
   * @description Picks the master contract. Contracts arrive ordered by StartDate, so the first
   *              Activated match wins the oldest-StartDate tiebreak.
   * @param contracts Benefits contracts for one account, oldest StartDate first.
   * @return The Activated contract carrying a TRC line, else the oldest Activated contract, else null.
   */
  private Contract selectMaster(List<Contract> contracts) {
    for (Contract candidate : contracts) {
      if (candidate.Status != STATUS_ACTIVATED) {
        continue;
      }
      if (hasTrcSolution(candidate)) {
        return candidate;
      }
    }
    return null;
  }
  /**
   * @description Contracts in the Luxembourg business unit, or whose pricebook name contains
   *              Luxembourg, Reduction or Mobility, are left out of the merge entirely. They are
   *              never chosen as master and never used as a source.
   * @param contractRecord Contract to test.
   * @return True when the contract must be skipped.
   */
  private Boolean isExcludedContract(Contract contractRecord) {
    if (EXCLUDED_BUSINESS_UNIT.equalsIgnoreCase(contractRecord.ER_BUPicklist__c)) {
      return true;
    }
    String pricebookName = contractRecord.Pricebook2 == null ? null : contractRecord.Pricebook2.Name;
    if (String.isBlank(pricebookName)) {
      return false;
    }
    String lowerName = pricebookName.toLowerCase();
    for (String keyword : EXCLUDED_PRICEBOOK_KEYWORDS) {
      if (lowerName.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /**
   * @description TRC is read from the contract header first because ER_ContractLineItem__c.ER_Solution__c
   *              resolves through ER_Product2__r.ER_Solution2__r.ProductCode, which is blank on products
   *              that have no solution linked.
   * @param candidate Contract to test.
   * @return True when the contract or any of its line items carries the TRC solution.
   */
  private Boolean hasTrcSolution(Contract candidate) {
    if (String.isNotBlank(candidate.ER_Solutions__c)) {
      for (String token : candidate.ER_Solutions__c.split('/')) {
        if (TRC_SOLUTION_CODE.equalsIgnoreCase(token.trim())) {
          return true;
        }
      }
    }
    return hasTrcLine(linesByContractId.get(candidate.Id));
  }

  private Boolean hasTrcLine(List<ER_ContractLineItem__c> lines) {
    if (lines == null) {
      return false;
    }
    for (ER_ContractLineItem__c line : lines) {
      if (TRC_SOLUTION_CODE.equalsIgnoreCase(line.ER_Solution__c)) {
        return true;
      }
    }
    return false;
  }

  /**
   * @description Copies a line item onto the master. ER_MDMId__c is a unique external id so it must
   *              not survive the clone; Contract_Line_Item__c back-links the clone to its source.
   * @param source           Line item to copy.
   * @param masterContractId Contract the copy is attached to.
   * @return The unsaved clone.
   */
  private ER_ContractLineItem__c buildClone(ER_ContractLineItem__c source, Id masterContractId) {
    ER_ContractLineItem__c copy = source.clone(false, true, false, false);
    copy.putSObject('ER_Product2__r', null);
    copy.ER_MDMId__c = null;
    copy.ER_Contract__c = masterContractId;
    copy.Contract_Line_Item__c = source.Id;
    return copy;
  }

  /**
   * @description Combines the master's solutions with those of every merged contract. Source contract
   *              headers are used because line level ER_Solution__c is blank whenever the product has
   *              no ER_Solution2__c linked.
   * @param master    Contract receiving the clones.
   * @param collected Clones and source contract solutions gathered for this account.
   * @return Contract carrying the updated ER_Solutions__c, or null when nothing changed.
   */
  private Contract rebuildSolutions(Contract master, CloneSet collected) {
    List<String> ordered = new List<String>();
    Set<String> seen = new Set<String>();

    addSolutionTokens(ordered, seen, master.ER_Solutions__c);
    addSolutionsFromLines(ordered, seen, linesByContractId.get(master.Id));
    for (String sourceSolutions : collected.sourceSolutions) {
      addSolutionTokens(ordered, seen, sourceSolutions);
    }
    addSolutionsFromLines(ordered, seen, collected.clones);

    String combined = String.join(ordered, SOLUTIONS_SEPARATOR);
    if (String.isBlank(combined) || combined == master.ER_Solutions__c) {
      return null;
    }
    return new Contract(Id = master.Id, ER_Solutions__c = combined);
  }

  private void addSolutionsFromLines(List<String> ordered, Set<String> seen, List<ER_ContractLineItem__c> lines) {
    if (lines == null) {
      return;
    }
    for (ER_ContractLineItem__c line : lines) {
      addSolution(ordered, seen, line.ER_Solution__c);
    }
  }

  private void addSolutionTokens(List<String> ordered, Set<String> seen, String solutions) {
    if (String.isBlank(solutions)) {
      return;
    }
    for (String token : solutions.split('/')) {
      addSolution(ordered, seen, token);
    }
  }

  private void addSolution(List<String> ordered, Set<String> seen, String value) {
    if (String.isBlank(value)) {
      return;
    }
    String trimmed = value.trim();
    if (seen.add(trimmed.toUpperCase())) {
      ordered.add(trimmed);
    }
  }

  private Map<Id, Integer> insertClones(List<ER_ContractLineItem__c> clones) {
    Map<Id, Integer> successfulCloneCounts = new Map<Id, Integer>();
    if (clones.isEmpty()) {
      return successfulCloneCounts;
    }
    if (!hasDmlBudget(clones.size())) {
      String message = 'DML row limit would be exceeded by ' + clones.size() +
        ' line item(s). Lower the batch scope size and re-run.';
      dmlErrorEntries.add(
        new APER45_ErrorLog_Management.ErrorLogEntry()
          .withLogLevel(APER45_ErrorLog_Management.LogLevel.Error)
          .withSourceClass('BenefitsContractMergeBatch')
          .withSourceMethod('insertClones')
          .withRelatedObject('ER_ContractLineItem__c')
          .withMessage(message)
      );
      addSummary('ERROR: ' + message);
      lineErrors += clones.size();
      return successfulCloneCounts;
    }
    List<Database.SaveResult> results = Database.insert(clones, false);
    for (Integer i = 0; i < results.size(); i++) {
      if (results[i].isSuccess()) {
        linesCloned++;
        Id masterId = clones[i].ER_Contract__c;
        successfulCloneCounts.put(
          masterId,
          successfulCloneCounts.containsKey(masterId) ? successfulCloneCounts.get(masterId) + 1 : 1
        );
      } else {
        lineErrors++;
        String errorDetails = describeDmlErrors(results[i].getErrors());
        dmlErrorEntries.add(
          new APER45_ErrorLog_Management.ErrorLogEntry()
            .withLogLevel(APER45_ErrorLog_Management.LogLevel.Error)
            .withSourceClass('BenefitsContractMergeBatch')
            .withSourceMethod('insertClones')
            .withRelatedRecordId(clones[i].Contract_Line_Item__c)
            .withRelatedObject('ER_ContractLineItem__c')
            .withMessage('Failed to clone contract line item. ' + errorDetails)
            .withPayload(
              'Source CLI Id=' + clones[i].Contract_Line_Item__c +
              '; Target Contract Id=' + clones[i].ER_Contract__c
            )
        );
        addSummary(
          'ERROR cloning line ' + clones[i].Contract_Line_Item__c + ' -> contract ' +
          clones[i].ER_Contract__c + ': ' + errorDetails
        );
      }
    }
    return successfulCloneCounts;
  }

  private Set<Id> updateMasters(List<Contract> masters) {
    Set<Id> updatedMasterIds = new Set<Id>();
    if (masters.isEmpty()) {
      return updatedMasterIds;
    }
    if (!hasDmlBudget(masters.size())) {
      String message = 'DML row limit would be exceeded updating ' + masters.size() + ' master contract(s).';
      dmlErrorEntries.add(
        new APER45_ErrorLog_Management.ErrorLogEntry()
          .withLogLevel(APER45_ErrorLog_Management.LogLevel.Error)
          .withSourceClass('BenefitsContractMergeBatch')
          .withSourceMethod('updateMasters')
          .withRelatedObject('Contract')
          .withMessage(message)
      );
      addSummary('ERROR: ' + message);
      return updatedMasterIds;
    }
    List<Database.SaveResult> results = Database.update(masters, false);
    for (Integer i = 0; i < results.size(); i++) {
      if (results[i].isSuccess()) {
        updatedMasterIds.add(masters[i].Id);
      } else {
        String errorDetails = describeDmlErrors(results[i].getErrors());
        dmlErrorEntries.add(
          new APER45_ErrorLog_Management.ErrorLogEntry()
            .withLogLevel(APER45_ErrorLog_Management.LogLevel.Error)
            .withSourceClass('BenefitsContractMergeBatch')
            .withSourceMethod('updateMasters')
            .withRelatedRecordId(masters[i].Id)
            .withRelatedObject('Contract')
            .withMessage('Failed to update master contract fields. ' + errorDetails)
            .withPayload(
              'Master Contract Id=' + masters[i].Id +
              '; Fields=' + String.join(new List<String>(masters[i].getPopulatedFieldsAsMap().keySet()), ', ')
            )
        );
        addSummary(
          'ERROR updating master contract ' + masters[i].Id + ': ' + errorDetails
        );
      }
    }
    return updatedMasterIds;
  }

  private void trackSuccessfulAccounts(
    MergePlan plan,
    Map<Id, Integer> successfulCloneCounts,
    Set<Id> updatedMasterIds
  ) {
    for (Id masterId : plan.auditByMaster.keySet()) {
      MergeAuditData auditData = plan.auditByMaster.get(masterId);
      Integer successfulCount = successfulCloneCounts.get(masterId);
      if (successfulCount != auditData.expectedCloneCount || !updatedMasterIds.contains(masterId)) {
        continue;
      }
      successfulMergedAccountIds.add(String.valueOf(auditData.accountId));
    }
  }

  private void writeSuccessfulAccountLogs() {
    if (successfulMergedAccountIds.isEmpty()) {
      return;
    }

    successfulMergedAccountIds.sort();
    List<APER45_ErrorLog_Management.ErrorLogEntry> entries =
      new List<APER45_ErrorLog_Management.ErrorLogEntry>();
    Integer idsPerLog = 2500;
    for (Integer startIndex = 0; startIndex < successfulMergedAccountIds.size(); startIndex += idsPerLog) {
      Integer endIndex = Math.min(startIndex + idsPerLog, successfulMergedAccountIds.size());
      List<String> idGroup = new List<String>();
      for (Integer index = startIndex; index < endIndex; index++) {
        idGroup.add(successfulMergedAccountIds[index]);
      }
      entries.add(
        new APER45_ErrorLog_Management.ErrorLogEntry()
          .withLogLevel(APER45_ErrorLog_Management.LogLevel.Info)
          .withSourceClass('BenefitsContractMergeBatch')
          .withSourceMethod('finish')
          .withRelatedObject('Account')
          .withMessage(
            'Successfully merged Account IDs ' + (startIndex + 1) + '-' + endIndex +
            ' of ' + successfulMergedAccountIds.size() + '. Batch job: ' + currentJobId
          )
          .withPayload(String.join(idGroup, ', '))
      );
    }
    APER45_ErrorLog_Management.log(entries);
  }

  private String describeDmlErrors(List<Database.Error> errors) {
    List<String> details = new List<String>();
    for (Database.Error dmlError : errors) {
      String fields = dmlError.getFields().isEmpty()
        ? ''
        : ' [Fields: ' + String.join(dmlError.getFields(), ', ') + ']';
      details.add(String.valueOf(dmlError.getStatusCode()) + ': ' + dmlError.getMessage() + fields);
    }
    return String.join(details, ' | ');
  }

  private void flushDmlErrors() {
    if (dmlErrorEntries.isEmpty()) {
      return;
    }
    APER45_ErrorLog_Management.log(dmlErrorEntries);
    dmlErrorEntries.clear();
  }

  private Boolean hasDmlBudget(Integer rows) {
    return (Limits.getDmlRows() + rows) <= Limits.getLimitDmlRows();
  }

  private void skip(Account account, String reason) {
    accountsSkipped++;
    String label = account == null ? 'unknown account' : account.Name + ' [' + account.Id + ']';
    addSummary('SKIP ' + label + ': ' + reason);
  }

  private void addSummary(String row) {
    if (summary.size() >= MAX_SUMMARY_ROWS) {
      summaryTruncated = true;
      return;
    }
    summary.add(row);
  }

  private static String cloneableFieldList;

  /**
   * @description Describe-driven so formula, rollup and audit fields are excluded automatically and
   *              any field added to the object later is picked up without touching this class.
   * @return Comma separated SOQL field list for cloning.
   */
  private static String getCloneableFieldList() {
    if (cloneableFieldList == null) {
      Set<String> fieldNames = new Set<String>{ 'Id', 'LastModifiedDate' };
      for (Schema.SObjectField field : Schema.SObjectType.ER_ContractLineItem__c.fields.getMap().values()) {
        Schema.DescribeFieldResult describe = field.getDescribe();
        if (describe.isCreateable() && !describe.isCalculated()) {
          fieldNames.add(describe.getName());
        }
      }
      cloneableFieldList = String.join(new List<String>(fieldNames), ', ');
    }
    return cloneableFieldList;
  }
}
