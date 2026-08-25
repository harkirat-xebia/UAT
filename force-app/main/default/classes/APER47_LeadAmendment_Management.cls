/*
----------------------------------------------------------------------
-- - Name          : APER47_LeadAmendment_Management
-- - Author        : Harkirat Singh
-- - Description   : Decides whether a Lead can amend an already activated
--                   Contract instead of being converted into a brand new
--                   Opportunity. Eligible when the Lead's product of interest
--                   belongs to the same Product Family as the Contract, so a
--                   customer only ever holds one active contract per family.
--
--                   Read only. The mutating half (amendAndConvert) reuses
--                   APER04_Opportunity_Management.createOpportunityFromContract.
--
--                   Runs without sharing to match APER46_RecordInsight_Management:
--                   a contract the running user cannot see through sharing is
--                   still a contract that must not be duplicated.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2026     Harkirat Singh       1.0         Initial version
----------------------------------------------------------------------
*/
public without sharing class APER47_LeadAmendment_Management {
  private static final String PRODUCT_TYPE_DISCOUNT = 'Discount';
  private static final String PRODUCT_TYPE_RANGE = 'Range';
  private static final String CONTRACT_TYPE_FRAMEWORK = 'Framework agreement';
  private static final String CONTRACT_TYPE_REFERRAL = 'Referral agreement';
  private static final String STATUS_TERMINATED = 'Terminated';

  // harkirat - exact string APER12_Contract_Management reads to set Contract.CustomerSignedId
  private static final String ROLE_PRIMARY_CONTACT = 'Primary Contact';

  // harkirat - client scope only, merchant leads and contracts are out of scope for this flow
  private static final String LEAD_RT_CLIENT = 'ER_Client_Lead_RT';
  private static final String CONTRACT_RT_CLIENT = 'ER_Client_Contract_RT';

  // harkirat - matches the insight row's match limit, an account with more is a data problem
  private static final Integer MAX_CANDIDATE_CONTRACTS = 6;

  /*  Product2.Solution_Group__c and Contract.Contract_Category__c do not share a value set:
      the lead side is Benefits / Savings / Mobility, the contract side is a formula returning
      Benefits / Engagement / Benefits and Engagement / Services Only. This translates the lead
      value into the token the contract formula uses. A family with no entry never matches. */
  // harkirat - Mobility is deliberately absent, it has no Contract_Category__c outcome
  private static final Map<String, String> FAMILY_TOKENS = new Map<String, String>{
    'Benefits' => 'Benefits',
    'Savings' => 'Engagement'
  };

  // harkirat - internal only, so blocking reasons survive the trip to the client intact
  public class LeadAmendmentException extends Exception {
  }

  /*=================================================================
    WRAPPERS
  =================================================================*/

  public class AmendEligibility {
    @AuraEnabled
    public String contractId { get; set; }
    @AuraEnabled
    public String contractNumber { get; set; }
    @AuraEnabled
    public Boolean isEligible { get; set; }
    @AuraEnabled
    public String blockedReason { get; set; }
    // harkirat - true when this contract already carries the lead's solution, which wins the ranking
    @AuraEnabled
    public Boolean matchesSolution { get; set; }

    public AmendEligibility(Id contractId) {
      this.contractId = contractId;
      this.isEligible = false;
      this.matchesSolution = false;
    }
  }

  public class AmendPreview {
    @AuraEnabled
    public String contractId { get; set; }
    @AuraEnabled
    public String contractNumber { get; set; }
    @AuraEnabled
    public String accountName { get; set; }
    @AuraEnabled
    public Boolean isEligible { get; set; }
    @AuraEnabled
    public String blockedReason { get; set; }
    @AuraEnabled
    public List<LineView> existingLines { get; set; }
    @AuraEnabled
    public LineView newLine { get; set; }
    /*  Range bands the user can choose between - the child Range products of the lead's service.
        Empty for a flat product, in which case newLine is simply the product itself. */
    @AuraEnabled
    public List<LineView> availableBands { get; set; }
    @AuraEnabled
    public String selectedPricebookEntryId { get; set; }
    @AuraEnabled
    public String currencyIsoCode { get; set; }
    /*  How many activated contracts in this family the customer holds. More than one is a data
        problem the business wants sales to clean up, so the client shows a steering message. */
    @AuraEnabled
    public Integer eligibleContractCount { get; set; }

    public AmendPreview() {
      this.isEligible = false;
      this.existingLines = new List<LineView>();
      this.availableBands = new List<LineView>();
      this.eligibleContractCount = 0;
    }
  }

  public class LineView {
    @AuraEnabled
    public String productId { get; set; }
    @AuraEnabled
    public String pricebookEntryId { get; set; }
    @AuraEnabled
    public String productName { get; set; }
    @AuraEnabled
    public String solutionName { get; set; }
    // harkirat - the parent service, without it a band called "3 to 15 cards" means nothing
    @AuraEnabled
    public String parentName { get; set; }
    @AuraEnabled
    public Decimal quantity { get; set; }
    @AuraEnabled
    public Decimal unitPrice { get; set; }
    @AuraEnabled
    public Decimal minValue { get; set; }
    @AuraEnabled
    public Decimal maxValue { get; set; }
    @AuraEnabled
    public Decimal percentage { get; set; }
    @AuraEnabled
    public String valueType { get; set; }
  }

  /*=================================================================
    ENTRY POINTS
  =================================================================*/

  /*  The three cacheable methods below deliberately do NOT write to ER_Error_Log__c. A cacheable
      Apex method cannot perform DML, and EventBus.publish counts as DML, so both APER45 paths
      would throw a second exception on top of the first. Same reasoning as APER46's getInsights.
      Every mutating entry point in this class does log. */
  @AuraEnabled(cacheable=true)
  public static List<AmendEligibility> getEligibility(Id leadId, List<Id> contractIds) {
    try {
      return ordered(evaluate(leadId, contractIds), contractIds);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'APER47.getEligibility failed: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*  The insight row already knows its matched contracts, the quick action does not -
      it starts from the lead alone and has to find the candidates itself. */
  // harkirat - same CRN plus activated filter the Duplicate_Lookup insight uses
  @AuraEnabled(cacheable=true)
  public static List<AmendEligibility> getAmendableContracts(Id leadId) {
    try {
      return rankedCandidates(leadId);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'APER47.getAmendableContracts failed: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*  Ranking, per decision 14:
        1. eligible before ineligible
        2. among eligible, a contract carrying the lead's solution wins
        3. otherwise most recent, which the SOQL ORDER BY already established

      A stable two-pass filter rather than a sort comparator, so recency order survives within
      each bucket - the same technique the insights LWC uses to re-order its rows. */
  // harkirat - the caller takes the first entry, which is the contract that gets amended
  private static List<AmendEligibility> rankedCandidates(Id leadId) {
    Lead lead = queryLead(leadId);
    if (lead == null || String.isBlank(lead.ER_Registration_Number__c)) {
      return new List<AmendEligibility>();
    }

    String crn = lead.ER_Registration_Number__c;
    String activated = Label.LABS_SF_Contract_Status_Activated;
    List<Id> candidateIds = new List<Id>();
    for (Contract contractInst : [
      SELECT Id
      FROM Contract
      WHERE ER_Account_CRN__c = :crn AND Status = :activated
      ORDER BY StartDate DESC NULLS LAST, CreatedDate DESC
      LIMIT :MAX_CANDIDATE_CONTRACTS
    ]) {
      candidateIds.add(contractInst.Id);
    }

    List<AmendEligibility> byRecency = ordered(evaluate(leadId, candidateIds), candidateIds);

    List<AmendEligibility> solutionMatches = new List<AmendEligibility>();
    List<AmendEligibility> familyOnly = new List<AmendEligibility>();
    List<AmendEligibility> ineligible = new List<AmendEligibility>();

    for (AmendEligibility candidate : byRecency) {
      if (!candidate.isEligible) {
        ineligible.add(candidate);
      } else if (candidate.matchesSolution) {
        solutionMatches.add(candidate);
      } else {
        familyOnly.add(candidate);
      }
    }

    List<AmendEligibility> ranked = new List<AmendEligibility>();
    ranked.addAll(solutionMatches);
    ranked.addAll(familyOnly);
    ranked.addAll(ineligible);

    if (ranked.isEmpty() || !ranked[0].isEligible) {
      System.debug('>>>>> APER47 - rankedCandidates: no contract picked for lead ' + leadId);
    } else {
      System.debug(
        '>>>>> APER47 - rankedCandidates: picked contract ' +
          ranked[0].contractId +
          ' (' +
          ranked[0].contractNumber +
          ') | solution match ' +
          ranked[0].matchesSolution +
          ' | ' +
          solutionMatches.size() +
          ' solution + ' +
          familyOnly.size() +
          ' family-only candidate(s)'
      );
    }
    return ranked;
  }

  // harkirat - drives the steering message, counted server side so both entry points agree
  private static Integer countEligible(List<AmendEligibility> candidates) {
    Integer total = 0;
    for (AmendEligibility candidate : candidates) {
      if (candidate.isEligible) {
        total++;
      }
    }
    return total;
  }

  /*  Apex does not guarantee Map iteration order, so the caller's ordering - which for
      getAmendableContracts is most-recent-first - would otherwise be lost on the way out. */
  private static List<AmendEligibility> ordered(Map<Id, AmendEligibility> byContract, List<Id> contractIds) {
    List<AmendEligibility> results = new List<AmendEligibility>();
    for (Id contractId : contractIds) {
      if (byContract.containsKey(contractId)) {
        results.add(byContract.get(contractId));
      }
    }
    return results;
  }

  @AuraEnabled(cacheable=true)
  public static AmendPreview getPreview(Id leadId, Id contractId) {
    try {
      return buildPreview(leadId, contractId);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'APER47.getPreview failed: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*  Amends the contract, adds the lead's product to the resulting opportunity and
      converts the lead onto it. One savepoint around the lot: a half amended
      opportunity with an unconverted lead is worse than a clean failure. */
  @AuraEnabled
  public static Id amendAndConvert(Id leadId, Id contractId, Id pricebookEntryId) {
    Savepoint sp = Database.setSavepoint();
    try {
      /*  Queried once here and threaded through every step. Each of these used to be re-queried
          two or three times, and this transaction has no headroom: it chains
          createOpportunityFromContract, a full lead conversion firing four objects' triggers, and
          our own DML, and was hitting the 100 SOQL ceiling. */
      Lead lead = queryLead(leadId);

      /*  Checked before anything is priced: resolvePrices reads the lead's product, and with no
          product there is nothing to price and no family to match on. */
      // harkirat - never trust the client's view of eligibility
      String leadReason = checkLead(lead);
      if (leadReason != null) {
        throw new LeadAmendmentException(leadReason);
      }

      List<Contract> contracts = queryContracts(new List<Id>{ contractId });
      if (contracts.isEmpty()) {
        throw new LeadAmendmentException(Label.LABS_SF_Amend_Contract_Other_Account);
      }
      Contract contractInst = contracts[0];
      Map<Id, PricebookEntry> priceByContract = resolvePrices(contracts, lead);

      String familyToken = FAMILY_TOKENS.get(lead.ERBE_Initial_Product_Of_Interest__r.Solution_Group__c);
      String blockedReason = checkContract(contractInst, familyToken, lead, priceByContract);
      if (blockedReason != null) {
        throw new LeadAmendmentException(blockedReason);
      }

      // harkirat - a client supplied band is re-resolved server side, never taken on trust
      PricebookEntry chosen = resolveChosenBand(lead, contractInst, pricebookEntryId, priceByContract.get(contractId));

      Opportunity amendmentOpp = APER04_Opportunity_Management.createOpportunityFromContract(
        contractId,
        contractInst.ER_OpportunityId__c
      );
      if (amendmentOpp == null || amendmentOpp.Id == null) {
        throw new LeadAmendmentException(Label.LABS_SF_AvoidAmendement);
      }

      addLeadProduct(amendmentOpp.Id, contractInst, chosen);

      // harkirat - stamped before the convert, a converted lead is read only
      update new Lead(Id = lead.Id, Contract__c = contractId);

      Id primaryContactId = convertLeadOntoOpportunity(lead, contractInst, amendmentOpp.Id);
      stampLeadValuesOnOpportunity(amendmentOpp.Id, lead, primaryContactId);

      return amendmentOpp.Id;
    } catch (Exception e) {
      Database.rollback(sp);
      /*  logDurable rather than log: the rollback above and the exception thrown below would
          each discard a directly inserted record. ER_Error_Log_Event__e is PublishImmediately,
          so the log survives both. */
      logFailure('amendAndConvert', e, leadId, 'leadId=' + leadId + '; contractId=' + contractId);

      /*  Rebuilt from a plain exception rather than rethrown: an AuraHandledException
          that crosses a rethrow degrades to "Script-thrown exception" client side. */
      AuraHandledException surfaced = new AuraHandledException(e.getMessage());
      surfaced.setMessage(e.getMessage());
      throw surfaced;
    }
  }

  /*=================================================================
    ERROR LOGGING
  =================================================================*/

  /*  Every durable rather than direct, because the callers that log are the ones that roll back.
      APER45 never throws, so a logging failure can never mask the original error. */
  // harkirat - single funnel so every failure in this class lands in ER_Error_Log__c the same way
  private static void logFailure(String sourceMethod, Exception e, Id relatedRecordId, String payload) {
    APER45_ErrorLog_Management.logDurable(
      new APER45_ErrorLog_Management.ErrorLogEntry()
        .withLogLevel(APER45_ErrorLog_Management.LogLevel.Error)
        .withSourceClass('APER47_LeadAmendment_Management')
        .withSourceMethod(sourceMethod)
        .withSourceType('Apex Class')
        .withException(e)
        .withRelatedRecordId(relatedRecordId)
        .withPayload(payload)
        .withBusinessUnit(APER10_User_Management.userBU)
    );
  }

  /*=================================================================
    AMENDMENT STEPS
  =================================================================*/

  /*  Re-resolves whatever the client selected against the bands this contract actually offers.
      An Id arriving from the browser is only ever used to look up a row we produced ourselves,
      so a tampered or stale value falls back to the server's own choice rather than pricing a
      line off an arbitrary entry. */
  // harkirat - validated, not trusted
  private static PricebookEntry resolveChosenBand(Lead lead, Contract contractInst, Id requestedId, PricebookEntry fallback) {
    if (requestedId == null) {
      return fallback;
    }

    for (PricebookEntry pbe : bandEntries(new Set<Id>{ contractInst.Pricebook2Id }, priceableProductIds(lead))) {
      Boolean sameCurrency = priceKey(contractInst.Pricebook2Id, contractInst.CurrencyIsoCode) ==
        priceKey(pbe.Pricebook2Id, pbe.CurrencyIsoCode);
      if (pbe.Id == requestedId && sameCurrency) {
        return pbe;
      }
    }

    // harkirat - not one of this contract's bands, fall back rather than fail the amendment
    System.debug(LoggingLevel.WARN, '>>>>> APER47 - rejected client band ' + requestedId + ', using the server default');
    return fallback;
  }

  /*  Inserted directly rather than through NEMO_ContractAmendmentService: that service exists to
      apply a bulk list of changes from the REST integration, and everything it would do here is
      already resolved - one product, one band, one row. Going through it meant building three DTOs
      to insert a single line and coupling this flow to a class whose DTOs are a published REST
      contract.

      When the contract already carries the lead's product the cloned line is left exactly as it is,
      so it keeps the contract's pricing rather than the lead's (decision 8). */
  // harkirat - the upsell case adds nothing, sales adjusts quantity on the opportunity
  private static void addLeadProduct(Id opportunityId, Contract contractInst, PricebookEntry pbe) {
    if (pbe == null) {
      throw new LeadAmendmentException(Label.LABS_SF_Amend_No_Price);
    }
    Id leadProductId = pbe.Product2Id;

    /*  One query doing the work of two: the total proves every contract line was cloned across
        (createOpportunityFromContract inserts with allOrNone false, so a bad line vanishes
        silently), and the per-product count decides whether this is an upsell. */
    Integer total = 0;
    Integer alreadyPresent = 0;
    for (AggregateResult row : [
      SELECT Product2Id, COUNT(Id) lineCount
      FROM OpportunityLineItem
      WHERE OpportunityId = :opportunityId
      GROUP BY Product2Id
    ]) {
      Integer lineCount = (Integer) row.get('lineCount');
      total += lineCount;
      if (leadProductId == (Id) row.get('Product2Id')) {
        alreadyPresent += lineCount;
      }
    }

    if (total < contractInst.ER_ContractLineItems__r.size()) {
      throw new LeadAmendmentException(Label.LABS_SF_Amend_Lines_Not_Copied);
    }

    if (alreadyPresent > 0) {
      // harkirat - upsell case, the cloned line keeps the contract's pricing
      System.debug('>>>>> APER47 - addLeadProduct: product ' + leadProductId + ' already on the amendment, nothing added');
      return;
    }

    /*  Product2Id is deliberately not set: the platform derives it from PricebookEntryId, and it is
        not reliably writeable on create. APER04 and the NEMO service both set it, but both insert
        with allOrNone false, so a rejection there would be swallowed rather than surfaced. This
        insert is allOrNone, so it must not depend on a field that might be refused. */
    OpportunityLineItem newLine = new OpportunityLineItem();
    newLine.OpportunityId = opportunityId;
    newLine.PricebookEntryId = pbe.Id;
    newLine.Quantity = 1;
    newLine.UnitPrice = pbe.UnitPrice;
    newLine.ER_Percentage__c = pbe.ER_Percentage__c;
    newLine.ER_Min__c = pbe.ER_Min__c;
    newLine.ER_Max__c = pbe.ER_Max__c;
    insert newLine;

    System.debug(
      '>>>>> APER47 - addLeadProduct: added product ' +
        leadProductId +
        ' to opportunity ' +
        opportunityId +
        ' at ' +
        pbe.UnitPrice +
        ' (PBE ' +
        pbe.Id +
        ')'
    );
  }

  /*  setOpportunityId attaches the lead to the amendment instead of creating a second
      opportunity, which is what makes ConvertedOpportunityId point at the amendment. */
  private static Id convertLeadOntoOpportunity(Lead lead, Contract contractInst, Id opportunityId) {
    Database.LeadConvert leadConvert = new Database.LeadConvert();
    leadConvert.setLeadId(lead.Id);
    leadConvert.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1].MasterLabel);
    leadConvert.setAccountId(contractInst.AccountId);
    leadConvert.setOpportunityId(opportunityId);

    // harkirat - matched contact is reused, otherwise the conversion creates one
    Id existingContactId = resolveContactId(lead, contractInst.AccountId);
    if (existingContactId != null) {
      leadConvert.setContactId(existingContactId);
    }

    Database.LeadConvertResult result = Database.convertLead(leadConvert, false);
    if (!result.isSuccess()) {
      List<String> messages = new List<String>();
      for (Database.Error error : result.getErrors()) {
        messages.add(error.getMessage());
      }
      throw new LeadAmendmentException(String.join(messages, ' - '));
    }

    applyPrimaryContactRole(opportunityId, result.getContactId());
    return result.getContactId();
  }

  /*  Email plus first and last name, scoped to the contract's account so a contact belonging
      to a different company is never attached. Names are compared in Apex rather than SOQL
      because FirstName is frequently blank and null handling in a bind is awkward. */
  // harkirat - returns null to let the conversion create the contact itself
  @TestVisible
  private static Id resolveContactId(Lead lead, Id accountId) {
    if (String.isBlank(lead.Email) || accountId == null) {
      return null;
    }
    String email = lead.Email;
    // harkirat - newest first, so a genuine duplicate resolves to the most recent contact.
    // Id DESC breaks ties when two contacts share the same CreatedDate millisecond
    // (routine when both are inserted in the same transaction).
    for (Contact existing : [
      SELECT Id, FirstName, LastName
      FROM Contact
      WHERE AccountId = :accountId AND Email = :email
      ORDER BY CreatedDate DESC, Id DESC
    ]) {
      if (sameName(existing.FirstName, lead.FirstName) && sameName(existing.LastName, lead.LastName)) {
        return existing.Id;
      }
    }
    return null;
  }

  private static Boolean sameName(String left, String right) {
    if (String.isBlank(left) && String.isBlank(right)) {
      return true;
    }
    return left != null && right != null && left.trim().equalsIgnoreCase(right.trim());
  }

  /*  createContractFromQuote keys its role map on Role, NOT IsPrimary, so leaving a demoted row
      on 'Primary Contact' would collide and CustomerSignedId could name the wrong person. The
      inherited row therefore has its Role cleared, keeping the contact on the opportunity. */
  // harkirat - nothing to do when the lead's contact is already the primary
  private static void applyPrimaryContactRole(Id opportunityId, Id contactId) {
    if (contactId == null) {
      return;
    }

    OpportunityContactRole leadRole;
    List<OpportunityContactRole> toUpdate = new List<OpportunityContactRole>();

    for (OpportunityContactRole ocr : [
      SELECT Id, ContactId, Role, IsPrimary
      FROM OpportunityContactRole
      WHERE OpportunityId = :opportunityId
    ]) {
      if (ocr.ContactId == contactId) {
        leadRole = ocr;
      } else if (ROLE_PRIMARY_CONTACT.equalsIgnoreCase(ocr.Role) || ocr.IsPrimary) {
        ocr.Role = null;
        ocr.IsPrimary = false;
        toUpdate.add(ocr);
      }
    }

    if (leadRole != null && (!ROLE_PRIMARY_CONTACT.equals(leadRole.Role) || !leadRole.IsPrimary)) {
      leadRole.Role = ROLE_PRIMARY_CONTACT;
      leadRole.IsPrimary = true;
      toUpdate.add(leadRole);
    }
    if (!toUpdate.isEmpty()) {
      update toUpdate;
    }

    if (leadRole == null) {
      insert new OpportunityContactRole(
        OpportunityId = opportunityId,
        ContactId = contactId,
        Role = ROLE_PRIMARY_CONTACT,
        IsPrimary = true
      );
    }

    /*  Opportunity.Primary_Contact__c is deliberately NOT written here. It is folded into the
        single update in stampLeadValuesOnOpportunity instead: each Opportunity DML fires a
        query-heavy trigger chain, and two updates in this transaction was what pushed it past
        the 100 SOQL ceiling. */
  }

  /*  LeadConvertSettings mappings only fire for an opportunity the conversion CREATES, so
      attaching to an existing one skips them and they are applied by hand here.

      Source of truth for this list:
        force-app/main/default/LeadConvertSettings/LeadConvertSettings.LeadConvertSetting-meta.xml

      Apex has no runtime API for lead convert mappings, so this cannot self-sync. A mapping added
      in Setup and not mirrored here silently leaves the field blank on amended opportunities only.
      APER47_LeadAmendment_Management_Test pins every field below. */
  // harkirat - the ONLY Opportunity update in this transaction, primary contact folded in
  private static void stampLeadValuesOnOpportunity(Id opportunityId, Lead lead, Id primaryContactId) {
    Lead converted = [
      SELECT
        Id,
        ERBE_Initial_Product_Of_Interest__c,
        ER_Product_Family_Interest__c,
        ER_Face_Value__c,
        ER_Number_Of_Beneficiaries__c,
        ER_EShop__c,
        ER_Lead_Type__c,
        ER_UTM_tag__c,
        L2W_ID__c
      FROM Lead
      WHERE Id = :lead.Id
      LIMIT 1
    ];

    Opportunity opp = new Opportunity(Id = opportunityId);
    opp.Product_of_Interest__c = converted.ERBE_Initial_Product_Of_Interest__c;
    opp.ER_Product_Family__c = converted.ER_Product_Family_Interest__c;
    opp.ER_Face_Value__c = converted.ER_Face_Value__c;
    opp.ER_Estimated_Number_Of_Beneficiaries__c = converted.ER_Number_Of_Beneficiaries__c;
    opp.ER_DocuGen_E_Shop__c = converted.ER_EShop__c;
    opp.ER_Lead_Source_Type__c = converted.ER_Lead_Type__c;
    opp.ER_UTM_tag__c = converted.ER_UTM_tag__c;
    opp.Leads2Win_Id__c = converted.L2W_ID__c;
    if (primaryContactId != null) {
      opp.Primary_Contact__c = primaryContactId;
    }
    // harkirat - promo code is left to APER18_Lead_Management.assignPromoCodeToOpp on convert
    update opp;
  }

  /*=================================================================
    ELIGIBILITY
  =================================================================*/

  // harkirat - bulk core, called by getEligibility, APER46 and (later) amendAndConvert
  public static Map<Id, AmendEligibility> evaluate(Id leadId, List<Id> contractIds) {
    Map<Id, AmendEligibility> results = new Map<Id, AmendEligibility>();
    if (leadId == null || contractIds == null || contractIds.isEmpty()) {
      return results;
    }

    // harkirat - guard against a non Lead host, the insight config is generic
    if (leadId.getSObjectType() != Lead.SObjectType) {
      return results;
    }

    for (Id contractId : contractIds) {
      results.put(contractId, new AmendEligibility(contractId));
    }

    Lead lead = queryLead(leadId);
    String leadLevelReason = checkLead(lead);
    if (leadLevelReason != null) {
      for (AmendEligibility eligibility : results.values()) {
        eligibility.blockedReason = leadLevelReason;
      }
      return results;
    }

    String familyToken = FAMILY_TOKENS.get(lead.ERBE_Initial_Product_Of_Interest__r.Solution_Group__c);
    Id leadSolutionId = lead.ERBE_Initial_Product_Of_Interest__r.ER_Solution2__c;

    List<Contract> contracts = queryContracts(contractIds);
    Map<Id, PricebookEntry> priceByContract = resolvePrices(contracts, lead);

    for (Contract contractInst : contracts) {
      AmendEligibility eligibility = results.get(contractInst.Id);
      eligibility.contractNumber = contractInst.ContractNumber;
      eligibility.blockedReason = checkContract(contractInst, familyToken, lead, priceByContract);
      eligibility.isEligible = eligibility.blockedReason == null;
      eligibility.matchesSolution = carriesSolution(contractInst, leadSolutionId);
    }

    Integer eligibleCount = countEligible(results.values());
    System.debug(
      '>>>>> APER47 - evaluate: lead ' +
        leadId +
        ' | family ' +
        familyToken +
        ' | ' +
        contracts.size() +
        ' candidate(s) read, ' +
        eligibleCount +
        ' eligible'
    );

    return results;
  }

  /*  Family decides whether an amendment applies at all; the solution only decides WHICH contract
      when a customer holds more than one in the same family. A contract that does not carry the
      lead's solution is still a valid target - that is the cross-sell case. */
  // harkirat - ranking input only, never a blocking rule
  private static Boolean carriesSolution(Contract contractInst, Id leadSolutionId) {
    if (leadSolutionId == null) {
      return false;
    }
    for (ER_ContractLineItem__c cli : contractInst.ER_ContractLineItems__r) {
      if (cli.ER_Product2__r != null && leadSolutionId == cli.ER_Product2__r.ER_Solution2__c) {
        return true;
      }
    }
    return false;
  }

  // harkirat - reasons that kill every contract at once, evaluated before the contract loop
  private static String checkLead(Lead lead) {
    if (lead == null) {
      return Label.LABS_SF_Amend_Lead_Not_Found;
    }
    if (lead.IsConverted) {
      return Label.LABS_SF_Amend_Lead_Converted;
    }
    if (String.isBlank(lead.ER_Registration_Number__c)) {
      return Label.LABS_SF_Amend_Lead_No_CRN;
    }
    if (lead.ERBE_Initial_Product_Of_Interest__c == null) {
      return Label.LABS_SF_Amend_Lead_No_Product;
    }
    /*  A family with no token - Mobility today - can never match a Contract_Category__c value,
        so it is refused outright rather than falling through to an unfiltered match. */
    if (!FAMILY_TOKENS.containsKey(lead.ERBE_Initial_Product_Of_Interest__r.Solution_Group__c)) {
      return Label.LABS_SF_Amend_Family_Not_Supported;
    }
    // harkirat - merchant leads are out of scope, gated here so no page can bypass it
    if (!LEAD_RT_CLIENT.equals(lead.RecordType.DeveloperName)) {
      return Label.LABS_SF_Amend_Client_Only;
    }
    return null;
  }

  // harkirat - returns the blocking reason, or null when this contract can be amended
  private static String checkContract(
    Contract contractInst,
    String familyToken,
    Lead lead,
    Map<Id, PricebookEntry> priceByContract
  ) {
    if (!Label.LABS_SF_Contract_Status_Activated.equalsIgnoreCase(contractInst.Status)) {
      return Label.LABS_SF_Amend_Contract_Not_Active;
    }
    // harkirat - the entry point already matched on CRN, re-checked so other callers cannot skip it
    if (
      contractInst.ER_Account_CRN__c == null ||
      !contractInst.ER_Account_CRN__c.equalsIgnoreCase(lead.ER_Registration_Number__c)
    ) {
      return Label.LABS_SF_Amend_Contract_Other_Account;
    }
    // harkirat - the amendment engine clones the source opportunity, without one there is nothing to clone
    if (contractInst.ER_OpportunityId__c == null) {
      return Label.LABS_SF_Amend_Contract_No_Opportunity;
    }
    // harkirat - createOpportunityFromContract skips line items entirely for Zuora contracts
    if (contractInst.Subscription__c != null) {
      return Label.LABS_SF_Amend_Contract_Subscription;
    }
    // harkirat - same guard as the LCER04_Contract_Amend aura component
    if (
      isAgreementContract(contractInst.ER_Contract_Type__c) &&
      contractInst.ER_Original_Agreement__c != null &&
      STATUS_TERMINATED.equalsIgnoreCase(contractInst.ER_Original_Agreement__r.Status)
    ) {
      return Label.LABS_SF_Amend_Contract_Terminated_Agreement;
    }
    // harkirat - createOpportunityFromContract filters on the running user's BU
    if (!isSameBusinessUnit(contractInst.ER_Business_Unit__c, APER10_User_Management.userBU)) {
      return Label.LABS_SF_Amend_Contract_Other_BU;
    }
    // harkirat - a client lead must not amend a merchant contract
    if (!CONTRACT_RT_CLIENT.equals(contractInst.RecordType.DeveloperName)) {
      return Label.LABS_SF_Amend_Client_Only;
    }

    /*  Containment, not equality: Contract_Category__c returns "Benefits and Engagement" for a
        contract holding lines of both types, and such a contract IS a benefits contract for a
        benefits lead. Equality would miss it and let a second contract be created. A benefits
        lead still never matches a pure "Engagement" contract, which is the rule that matters. */
    // harkirat - family match, one active contract per customer per family
    if (String.isBlank(contractInst.Contract_Category__c) || !contractInst.Contract_Category__c.containsIgnoreCase(familyToken)) {
      return Label.LABS_SF_Amend_Different_Family;
    }
    if (!priceByContract.containsKey(contractInst.Id)) {
      return Label.LABS_SF_Amend_No_Price;
    }
    return null;
  }

  private static Boolean isAgreementContract(String contractType) {
    return CONTRACT_TYPE_FRAMEWORK.equalsIgnoreCase(contractType) || CONTRACT_TYPE_REFERRAL.equalsIgnoreCase(contractType);
  }

  /*  Contract.ER_Business_Unit__c is a formula over Account.ER_BUPicklist__c and returns
      an empty string rather than null, so a strict compare would reject a blank BU pair
      that APER04's SOQL bind treats as a match. */
  // harkirat - blank tolerant, case insensitive, same as the SOQL bind it mirrors
  @TestVisible
  private static Boolean isSameBusinessUnit(String contractBU, String userBU) {
    if (String.isBlank(contractBU) && String.isBlank(userBU)) {
      return true;
    }
    return contractBU != null && contractBU.equalsIgnoreCase(userBU);
  }

  /*=================================================================
    PRICING
  =================================================================*/

  /*  Ranges are NOT several PricebookEntries of one product. A service product has child Range
      products - "1 to 3 cards", "3 to 15 cards", "> 15 cards" - each a Product2 in its own right
      with ER_Solution__c pointing back at the parent service, and each carrying a single
      PricebookEntry whose ER_Min__c/ER_Max__c define the band. See the same treatment in
      clientAutoEnrollmentComponentController.

      So the priceable products for a lead are: the lead's product itself, plus any Range children
      of it. Both are queried together and the band is chosen from the resulting set. */
  // harkirat - the lead's product plus its range children, all in one query
  private static Set<Id> priceableProductIds(Lead lead) {
    Id leadProductId = lead.ERBE_Initial_Product_Of_Interest__c;
    Set<Id> productIds = new Set<Id>{ leadProductId };

    for (Product2 child : [
      SELECT Id
      FROM Product2
      WHERE ER_Solution__c = :leadProductId AND ER_Type__c = :PRODUCT_TYPE_RANGE AND IsActive = TRUE
    ]) {
      productIds.add(child.Id);
    }
    return productIds;
  }

  // harkirat - one query for every candidate contract, then the right band per contract
  private static Map<Id, PricebookEntry> resolvePrices(List<Contract> contracts, Lead lead) {
    Map<Id, PricebookEntry> priceByContract = new Map<Id, PricebookEntry>();

    Set<Id> pricebookIds = new Set<Id>();
    for (Contract contractInst : contracts) {
      if (contractInst.Pricebook2Id != null) {
        pricebookIds.add(contractInst.Pricebook2Id);
      }
    }
    if (pricebookIds.isEmpty()) {
      return priceByContract;
    }

    Set<Id> productIds = priceableProductIds(lead);
    Map<String, List<PricebookEntry>> entriesByKey = new Map<String, List<PricebookEntry>>();
    for (PricebookEntry pbe : bandEntries(pricebookIds, productIds)) {
      String key = priceKey(pbe.Pricebook2Id, pbe.CurrencyIsoCode);
      if (!entriesByKey.containsKey(key)) {
        entriesByKey.put(key, new List<PricebookEntry>());
      }
      entriesByKey.get(key).add(pbe);
    }

    for (Contract contractInst : contracts) {
      List<PricebookEntry> candidates = entriesByKey.get(priceKey(contractInst.Pricebook2Id, contractInst.CurrencyIsoCode));
      PricebookEntry chosen = pickBand(candidates, lead.ER_Number_Of_Beneficiaries__c);
      if (chosen != null) {
        priceByContract.put(contractInst.Id, chosen);
      }
    }
    return priceByContract;
  }

  /*  Entries are grouped by pricebook AND currency: a multi-currency org holds one entry per
      currency for the same product, and pricing a line off the wrong one is silent and wrong. */
  // harkirat - map key for "the prices that apply to this contract"
  private static String priceKey(Id pricebookId, String currencyIsoCode) {
    return String.valueOf(pricebookId) + '|' + String.valueOf(currencyIsoCode);
  }

  // harkirat - shared shape so the preview and the add path price a line identically
  private static List<PricebookEntry> bandEntries(Set<Id> pricebookIds, Set<Id> productIds) {
    return [
      SELECT
        Id,
        Pricebook2Id,
        Product2Id,
        CurrencyIsoCode,
        UnitPrice,
        ER_Min__c,
        ER_Max__c,
        ER_Percentage__c,
        ER_ValueType__c,
        Product2.Name,
        Product2.ER_Type__c,
        Product2.ER_Solution__r.Name,
        Product2.ER_Solution2__r.Name
      FROM PricebookEntry
      WHERE Pricebook2Id IN :pricebookIds AND Product2Id IN :productIds AND IsActive = TRUE
      ORDER BY ER_Min__c NULLS FIRST
    ];
  }

  /*  Prefers the Range band whose min/max brackets the lead's volume. Falls back to the first
      entry rather than refusing outright - with a picker in the modal the user can correct it,
      and refusing here would hide the button for a product that is perfectly sellable. */
  // harkirat - the default selection only, sales can change it in the modal
  @TestVisible
  private static PricebookEntry pickBand(List<PricebookEntry> candidates, Decimal volume) {
    if (candidates == null || candidates.isEmpty()) {
      return null;
    }
    if (volume != null) {
      for (PricebookEntry pbe : candidates) {
        if (!PRODUCT_TYPE_RANGE.equalsIgnoreCase(pbe.Product2.ER_Type__c)) {
          continue;
        }
        Boolean aboveMin = pbe.ER_Min__c == null || volume >= pbe.ER_Min__c;
        Boolean belowMax = pbe.ER_Max__c == null || volume <= pbe.ER_Max__c;
        if (aboveMin && belowMax) {
          return pbe;
        }
      }
    }
    return candidates[0];
  }

  /*=================================================================
    TRIGGER FLAG
  =================================================================*/

  /*  Materialises the verdict onto the Lead so a flexipage visibility rule can hide the
      standard Convert button - those rules can only read fields on the record.
      Before-context by design: mutates the records in place, no second DML, no recursion.

      Deliberately runs the full check including pricing rather than a cheap approximation:
      a flag that hides Convert while the amend action is blocked would dead-end the user. */
  /*  Guarded because this runs in a before trigger on every Lead insert and update: an
      unhandled exception here would block lead creation org-wide, including the SmartER and
      autoenrollment paths that have nothing to do with amendments. A failure leaves the flag
      false, which shows the standard Convert button - the safe fallback. */
  // harkirat - eligibility is never worth failing a lead save over
  public static void flagAmendableContracts(List<Lead> leads) {
    try {
      computeAmendableFlags(leads);

      Integer flagged = 0;
      for (Lead lead : leads) {
        if (lead.ER_Has_Amendable_Contract__c == true) {
          flagged++;
        }
      }
      System.debug('>>>>> APER47 - flagAmendableContracts: ' + leads.size() + ' lead(s) evaluated, ' + flagged + ' flagged');
    } catch (Exception e) {
      Id firstLeadId = leads != null && !leads.isEmpty() ? leads[0].Id : null;
      logFailure('flagAmendableContracts', e, firstLeadId, 'leads=' + (leads == null ? 0 : leads.size()));
    }
  }

  // harkirat - fully bulkified, four queries regardless of how many leads are in scope
  private static void computeAmendableFlags(List<Lead> leads) {
    Set<String> crns = new Set<String>();
    Set<Id> productIds = new Set<Id>();

    // harkirat - relationship fields are unavailable on Trigger.new, so the RT is matched by Id
    Id clientLeadRtId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
      .get(LEAD_RT_CLIENT)
      .getRecordTypeId();

    for (Lead lead : leads) {
      lead.ER_Has_Amendable_Contract__c = false;
      if (
        lead.RecordTypeId == clientLeadRtId &&
        String.isNotBlank(lead.ER_Registration_Number__c) &&
        lead.ERBE_Initial_Product_Of_Interest__c != null
      ) {
        crns.add(lead.ER_Registration_Number__c);
        productIds.add(lead.ERBE_Initial_Product_Of_Interest__c);
      }
    }
    if (crns.isEmpty()) {
      return;
    }

    /*  product_family_based_on_solution__c is a formula, so it is not computed on an unsaved
        record - the family has to come from the product itself in this context. */
    // harkirat - relationship fields are not populated on Trigger.new, so the product is queried
    Map<Id, Product2> productsById = new Map<Id, Product2>(
      [SELECT Id, ER_Type__c, Solution_Group__c FROM Product2 WHERE Id IN :productIds]
    );

    Map<String, List<Contract>> contractsByCrn = new Map<String, List<Contract>>();
    Set<Id> pricebookIds = new Set<Id>();
    String activated = Label.LABS_SF_Contract_Status_Activated;

    for (Contract contractInst : [
      SELECT
        Id,
        Status,
        RecordType.DeveloperName,
        ER_Account_CRN__c,
        ER_OpportunityId__c,
        Subscription__c,
        Pricebook2Id,
        CurrencyIsoCode,
        ER_Business_Unit__c,
        ER_Contract_Type__c,
        ER_Original_Agreement__c,
        ER_Original_Agreement__r.Status,
        Contract_Category__c
      FROM Contract
      WHERE ER_Account_CRN__c IN :crns AND Status = :activated
      ORDER BY StartDate DESC NULLS LAST, CreatedDate DESC
    ]) {
      if (!contractsByCrn.containsKey(contractInst.ER_Account_CRN__c)) {
        contractsByCrn.put(contractInst.ER_Account_CRN__c, new List<Contract>());
      }
      contractsByCrn.get(contractInst.ER_Account_CRN__c).add(contractInst);
      if (contractInst.Pricebook2Id != null) {
        pricebookIds.add(contractInst.Pricebook2Id);
      }
    }
    if (contractsByCrn.isEmpty()) {
      return;
    }

    /*  A service prices through its child Range products, not through its own entry, so the
        priceable set for each lead product is the product plus its Range children. */
    // harkirat - one query for every lead product's children, then filtered per lead in memory
    Map<Id, Set<Id>> priceableByLeadProduct = new Map<Id, Set<Id>>();
    Set<Id> allPriceableIds = new Set<Id>(productIds);
    for (Id leadProductId : productIds) {
      priceableByLeadProduct.put(leadProductId, new Set<Id>{ leadProductId });
    }
    for (Product2 child : [
      SELECT Id, ER_Solution__c
      FROM Product2
      WHERE ER_Solution__c IN :productIds AND ER_Type__c = :PRODUCT_TYPE_RANGE AND IsActive = TRUE
    ]) {
      priceableByLeadProduct.get(child.ER_Solution__c).add(child.Id);
      allPriceableIds.add(child.Id);
    }

    Map<String, List<PricebookEntry>> entriesByKey = new Map<String, List<PricebookEntry>>();
    for (PricebookEntry pbe : bandEntries(pricebookIds, allPriceableIds)) {
      String key = priceKey(pbe.Pricebook2Id, pbe.CurrencyIsoCode);
      if (!entriesByKey.containsKey(key)) {
        entriesByKey.put(key, new List<PricebookEntry>());
      }
      entriesByKey.get(key).add(pbe);
    }

    for (Lead lead : leads) {
      // harkirat - re-checked, a merchant lead could share a CRN with a client lead in the same batch
      if (lead.RecordTypeId != clientLeadRtId) {
        continue;
      }
      List<Contract> candidates = contractsByCrn.get(lead.ER_Registration_Number__c);
      Product2 product = productsById.get(lead.ERBE_Initial_Product_Of_Interest__c);
      String familyToken = product == null ? null : FAMILY_TOKENS.get(product.Solution_Group__c);
      if (candidates == null || familyToken == null) {
        continue;
      }

      Set<Id> priceable = priceableByLeadProduct.get(product.Id);

      for (Contract contractInst : candidates) {
        List<PricebookEntry> forContract = entriesByKey.get(priceKey(contractInst.Pricebook2Id, contractInst.CurrencyIsoCode));
        List<PricebookEntry> forProduct = new List<PricebookEntry>();
        if (forContract != null) {
          for (PricebookEntry pbe : forContract) {
            if (priceable.contains(pbe.Product2Id)) {
              forProduct.add(pbe);
            }
          }
        }
        PricebookEntry band = pickBand(forProduct, lead.ER_Number_Of_Beneficiaries__c);

        Map<Id, PricebookEntry> priceByContract = new Map<Id, PricebookEntry>();
        if (band != null) {
          priceByContract.put(contractInst.Id, band);
        }

        // harkirat - same rule set the button uses, so the flag and the action never disagree
        if (checkContract(contractInst, familyToken, lead, priceByContract) == null) {
          lead.ER_Has_Amendable_Contract__c = true;
          System.debug(
            '>>>>> APER47 - flag TRUE for lead CRN ' +
              lead.ER_Registration_Number__c +
              ' | family ' +
              familyToken +
              ' | matched contract ' +
              contractInst.Id
          );
          break;
        }
      }
    }
  }

  /*=================================================================
    PREVIEW
  =================================================================*/

  private static AmendPreview buildPreview(Id leadId, Id contractId) {
    AmendPreview preview = new AmendPreview();
    preview.contractId = contractId;
    if (leadId == null || contractId == null) {
      return preview;
    }

    Map<Id, AmendEligibility> eligibilityByContract = evaluate(leadId, new List<Id>{ contractId });
    AmendEligibility eligibility = eligibilityByContract.get(contractId);
    if (eligibility != null) {
      preview.isEligible = eligibility.isEligible;
      preview.blockedReason = eligibility.blockedReason;
      preview.contractNumber = eligibility.contractNumber;
    }
    if (!preview.isEligible) {
      return preview;
    }

    // harkirat - counted here so the modal and the insight row agree on when to steer
    preview.eligibleContractCount = countEligible(rankedCandidates(leadId));

    Lead lead = queryLead(leadId);
    List<Contract> contracts = queryContracts(new List<Id>{ contractId });
    Contract contractInst = contracts[0];
    preview.accountName = contractInst.Account.Name;
    preview.currencyIsoCode = contractInst.CurrencyIsoCode;

    for (ER_ContractLineItem__c cli : contractInst.ER_ContractLineItems__r) {
      LineView line = new LineView();
      line.productId = cli.ER_Product2__c;
      line.productName = cli.ER_Product2__r.Name;
      // harkirat - a band named "3 to 15 cards" is meaningless without the service it prices
      line.parentName = cli.ER_Product2__r.ER_Solution__r.Name;
      line.solutionName = cli.ER_Product2__r.ER_Solution2__r.Name;
      line.quantity = cli.ER_Quantity__c;
      line.unitPrice = cli.ER_UnitPrice__c;
      line.minValue = cli.ER_Min__c;
      line.maxValue = cli.ER_Max__c;
      line.percentage = cli.ER_Percentage__c;
      preview.existingLines.add(line);
    }

    /*  Every band the user may choose between: the lead's product plus its Range children, priced
        in this contract's pricebook and currency. One entry means a flat product and the picker
        stays hidden. */
    Set<Id> pricebookIds = new Set<Id>{ contractInst.Pricebook2Id };
    List<PricebookEntry> bands = bandEntries(pricebookIds, priceableProductIds(lead));

    List<PricebookEntry> forCurrency = new List<PricebookEntry>();
    for (PricebookEntry pbe : bands) {
      if (priceKey(contractInst.Pricebook2Id, contractInst.CurrencyIsoCode) == priceKey(pbe.Pricebook2Id, pbe.CurrencyIsoCode)) {
        forCurrency.add(pbe);
      }
    }

    for (PricebookEntry pbe : forCurrency) {
      preview.availableBands.add(toLineView(pbe));
    }

    PricebookEntry chosen = pickBand(forCurrency, lead.ER_Number_Of_Beneficiaries__c);
    if (chosen != null) {
      preview.newLine = toLineView(chosen);
      preview.selectedPricebookEntryId = chosen.Id;
    }

    return preview;
  }

  // harkirat - single shape for a priceable band, used for both the default and the picker
  private static LineView toLineView(PricebookEntry pbe) {
    LineView line = new LineView();
    line.productId = pbe.Product2Id;
    line.pricebookEntryId = pbe.Id;
    line.productName = pbe.Product2.Name;
    line.parentName = pbe.Product2.ER_Solution__r.Name;
    line.solutionName = pbe.Product2.ER_Solution2__r.Name;
    line.quantity = 1;
    line.unitPrice = pbe.UnitPrice;
    line.minValue = pbe.ER_Min__c;
    line.maxValue = pbe.ER_Max__c;
    line.percentage = pbe.ER_Percentage__c;
    line.valueType = pbe.ER_ValueType__c;
    return line;
  }

  /*=================================================================
    QUERIES
  =================================================================*/

  // harkirat - Email and names are selected because resolveContactId matches the contact on them
  private static Lead queryLead(Id leadId) {
    List<Lead> leads = [
      SELECT
        Id,
        IsConverted,
        Email,
        FirstName,
        LastName,
        RecordType.DeveloperName,
        ER_Registration_Number__c,
        ER_Number_Of_Beneficiaries__c,
        ERBE_Initial_Product_Of_Interest__c,
        ERBE_Initial_Product_Of_Interest__r.Name,
        ERBE_Initial_Product_Of_Interest__r.ER_Type__c,
        ERBE_Initial_Product_Of_Interest__r.Solution_Group__c,
        ERBE_Initial_Product_Of_Interest__r.ER_Solution2__c,
        ERBE_Initial_Product_Of_Interest__r.ER_Solution2__r.Name
      FROM Lead
      WHERE Id = :leadId
      LIMIT 1
    ];
    return leads.isEmpty() ? null : leads[0];
  }

  private static List<Contract> queryContracts(List<Id> contractIds) {
    return [
      SELECT
        Id,
        ContractNumber,
        Status,
        RecordType.DeveloperName,
        AccountId,
        Account.Name,
        ER_Account_CRN__c,
        ER_OpportunityId__c,
        Subscription__c,
        Pricebook2Id,
        CurrencyIsoCode,
        ER_Business_Unit__c,
        ER_Contract_Type__c,
        ER_Original_Agreement__c,
        ER_Original_Agreement__r.Status,
        Contract_Category__c,
        (
          SELECT
            Id,
            ER_Product2__c,
            ER_Quantity__c,
            ER_UnitPrice__c,
            ER_Min__c,
            ER_Max__c,
            ER_Percentage__c,
            ER_Product2__r.Name,
            ER_Product2__r.ER_Solution__r.Name,
            ER_Product2__r.ER_Solution2__c,
            ER_Product2__r.ER_Solution2__r.Name
          FROM ER_ContractLineItems__r
          WHERE ER_Product2__r.ER_Type__c != :PRODUCT_TYPE_DISCOUNT
        )
      FROM Contract
      WHERE Id IN :contractIds
    ];
  }
}
