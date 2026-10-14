@IsTest
private class BenefitsContractMergeBatchTest {
  @TestSetup
  static void setupUser() {
    User runner = new User(
      Alias = 'bmerge', LastName = 'BenefitsMergeTest',
      Email = 'benefitsmerge@example.invalid',
      Username = 'benefitsmerge.' + UserInfo.getOrganizationId() + '.' +
        DateTime.now().getTime() + '@example.invalid',
      ProfileId = UserInfo.getProfileId(),
      TimeZoneSidKey = 'Europe/Brussels', LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'BE', ER_BypassVR__c = true, ER_bypassTrigger__c = true
    );
    insert runner;
  }

  private static User runner() {
    return [SELECT Id FROM User WHERE Alias = 'bmerge' AND LastName = 'BenefitsMergeTest' LIMIT 1];
  }

  private static Account newAccount(String name) {
    Account record = new Account(Name = name, ER_BUPicklist__c = 'BE');
    insert record;
    return record;
  }

  private static Contract newContract(Account account, String solution, String status, Integer age) {
    Contract record = new Contract(
      AccountId = account.Id, Status = 'Draft', StartDate = Date.today().addDays(-age),
      ContractTerm = 12, ER_BUPicklist__c = 'BE', ER_Solutions__c = solution,
      Number_of_Benefit_Lines__c = 1, Number_of_Savings_Line__c = 0
    );
    insert record;
    record.Status = status;
    update record;
    return record;
  }

  private static Product2 newProduct(String type) {
    Product2 product = new Product2(Name = type + ' Test Product', ER_Type__c = type, IsActive = true);
    insert product;
    return product;
  }

  private static ER_ContractLineItem__c newLine(Contract parent, Product2 product, Boolean active) {
    ER_ContractLineItem__c line = new ER_ContractLineItem__c(
      Name = 'Merge Test Line', ER_Contract__c = parent.Id,
      ER_Product2__c = product == null ? null : product.Id,
      ER_IsActive__c = active, ER_Line_Type__c = 'Service',
      ER_Quantity__c = 3, ER_UnitPrice__c = 12.5, ER_ListPrice__c = 15,
      ER_Discount__c = 2.5, ER_Min__c = 1, ER_Max__c = 100,
      ER_Minimum_Fee__c = 5,
      ER_Description__c = 'Source description',
      ER_Price_Start_Date__c = Date.today().addDays(-10),
      ER_Price_End_Date__c = Date.today().addDays(30),
      ER_Offer_validity_end_date__c = Date.today().addDays(40)
    );
    insert line;
    return line;
  }

  private static Contract savedContract(Id contractId) {
    return [SELECT Id, Status, ER_Solutions__c, Is_Master_Contract__c, Offer_Validity_End_Date__c
            FROM Contract WHERE Id = :contractId];
  }

  private static Integer lineCount(Id contractId) {
    return [SELECT COUNT() FROM ER_ContractLineItem__c WHERE ER_Contract__c = :contractId];
  }

  private static void executeNow(Account account, Boolean dryRun) {
    new BenefitsContractMergeBatch(new Set<Id>{ account.Id }, dryRun)
      .execute(null, new List<Account>{ account });
  }

  @IsTest
  static void clonesApprovalLinesAndPreservesValues() {
    System.runAs(runner()) {
      Account account = newAccount('Fidelity');
      Contract master = newContract(account, 'TRC', 'Activated', 10);
      Contract source = newContract(account, 'ECE', 'In Approval Process', 20);
      Product2 product = newProduct('Service');
      newLine(master, product, true);
      ER_ContractLineItem__c original = newLine(source, product, false);
      original.ER_MDMId__c = 'unique-source-mdm';
      update original;
      newLine(source, product, true);

      Test.startTest();
      Database.executeBatch(new BenefitsContractMergeBatch(new Set<Id>{ account.Id }, false), 1);
      Test.stopTest();

      System.assertEquals(3, lineCount(master.Id), 'Both active and inactive source lines must be cloned.');
      System.assertEquals(2, lineCount(source.Id), 'Original lines must remain on the source.');
      Contract saved = savedContract(master.Id);
      System.assertEquals(true, saved.Is_Master_Contract__c, 'Successful cloning must mark the master.');
      System.assertEquals('TRC / ECE', saved.ER_Solutions__c, 'Solutions must be combined.');
      System.assertEquals('In Approval Process', savedContract(source.Id).Status, 'Source status must remain unchanged.');
      System.assertEquals(false, savedContract(source.Id).Is_Master_Contract__c, 'Sources are not masters.');

      ER_Error_Log__c audit = [
        SELECT ER_Source_Class__c, ER_Source_Method__c, ER_Log_Level__c, ER_Message__c, ER_Payload__c
        FROM ER_Error_Log__c
        WHERE ER_Source_Class__c = 'BenefitsContractMergeBatch'
          AND ER_Source_Method__c = 'finish'
        LIMIT 1
      ];
      System.assertEquals('BenefitsContractMergeBatch', audit.ER_Source_Class__c, 'Log must identify the batch.');
      System.assertEquals('Info', audit.ER_Log_Level__c, 'Success summaries use Info level.');
      System.assert(audit.ER_Payload__c.contains(String.valueOf(account.Id)), 'Log payload must contain the merged account ID.');

      ER_ContractLineItem__c copy = [
        SELECT Name, ER_Product2__c, ER_IsActive__c, ER_Line_Type__c, ER_Quantity__c,
          ER_UnitPrice__c, ER_ListPrice__c, ER_Discount__c, ER_Min__c, ER_Max__c,
          ER_Minimum_Fee__c, ER_Description__c,
          ER_Price_Start_Date__c, ER_Price_End_Date__c, ER_Offer_validity_end_date__c,
          ER_MDMId__c, Contract_Line_Item__c
        FROM ER_ContractLineItem__c WHERE Contract_Line_Item__c = :original.Id
      ];
      for (String field : new List<String>{
        'Name', 'ER_Product2__c', 'ER_IsActive__c', 'ER_Line_Type__c', 'ER_Quantity__c',
        'ER_UnitPrice__c', 'ER_ListPrice__c', 'ER_Discount__c', 'ER_Min__c', 'ER_Max__c',
        'ER_Minimum_Fee__c', 'ER_Description__c',
        'ER_Price_Start_Date__c', 'ER_Price_End_Date__c', 'ER_Offer_validity_end_date__c'
      }) {
        System.assertEquals(original.get(field), copy.get(field), 'Changed clone field: ' + field);
      }
      System.assertEquals(null, copy.ER_MDMId__c, 'Unique external IDs must not be duplicated.');
      System.assertEquals(original.Id, copy.Contract_Line_Item__c, 'Clone provenance must reference the original.');
    }
  }

  @IsTest
  static void dryRunDoesNotWrite() {
    System.runAs(runner()) {
      Account account = newAccount('Dry Run');
      Contract master = newContract(account, 'TRC', 'Activated', 20);
      Contract source = newContract(account, 'ECE', 'Activated', 10);
      source.Offer_Validity_End_Date__c = Date.today().addDays(25);
      update source;
      newLine(source, newProduct('Discount'), true);
      Test.startTest();
      Database.executeBatch(new BenefitsContractMergeBatch(new Set<Id>{ account.Id }, true), 1);
      Test.stopTest();
      System.assertEquals(0, lineCount(master.Id), 'Dry runs must not insert lines.');
      System.assertEquals(false, savedContract(master.Id).Is_Master_Contract__c, 'Dry runs must not stamp the master.');
      System.assertEquals(null, savedContract(master.Id).Offer_Validity_End_Date__c, 'Dry runs must not transfer dates.');
      System.assertEquals('TRC', savedContract(master.Id).ER_Solutions__c, 'Dry runs must not update solutions.');
    }
  }

  @IsTest
  static void singleDiscountCopiesDateAndRerunIsIdempotent() {
    System.runAs(runner()) {
      Account account = newAccount('Single Discount');
      Contract master = newContract(account, 'TRC', 'Activated', 20);
      Contract source = newContract(account, 'ECE', 'Activated', 10);
      source.Offer_Validity_End_Date__c = Date.today().addDays(25);
      update source;
      newLine(source, newProduct('Discount'), false);
      Test.startTest();
      executeNow(account, false);
      System.assertEquals(1, lineCount(master.Id), 'The single discounted source must be cloned.');
      System.assertEquals(source.Offer_Validity_End_Date__c, savedContract(master.Id).Offer_Validity_End_Date__c,
        'The discounted source offer date must be transferred.');
      executeNow(account, false);
      Test.stopTest();
      System.assertEquals(1, lineCount(master.Id), 'An imported discount must not block or duplicate a rerun.');
      System.assertEquals(true, savedContract(master.Id).Is_Master_Contract__c, 'The rerun must retain the master marker.');
    }
  }

  @IsTest
  static void twoDiscountedContractsSkipEntireAccount() {
    System.runAs(runner()) {
      Account account = newAccount('Multiple Discounts');
      Contract master = newContract(account, 'TRC', 'Activated', 20);
      Contract source = newContract(account, 'ECE', 'In Approval Process', 10);
      Product2 discount = newProduct('Discount');
      newLine(master, discount, true);
      newLine(source, discount, false);
      Test.startTest();
      executeNow(account, false);
      Test.stopTest();
      System.assertEquals(1, lineCount(master.Id), 'Multiple discounted contracts must prevent cloning.');
      System.assertEquals(1, lineCount(source.Id), 'Source lines must remain untouched.');
      System.assertEquals(false, savedContract(master.Id).Is_Master_Contract__c, 'Skipped accounts must not be marked.');
      System.assertEquals('TRC', savedContract(master.Id).ER_Solutions__c, 'Skipped accounts must retain solutions.');
    }
  }

  @IsTest
  static void blankDiscountDatePreservesMasterDate() {
    System.runAs(runner()) {
      Account account = newAccount('Blank Discount Date');
      Contract master = newContract(account, 'TRC', 'Activated', 20);
      master.Offer_Validity_End_Date__c = Date.today().addDays(15);
      update master;
      Contract source = newContract(account, 'TRC', 'Activated', 10);
      ER_ContractLineItem__c discount = newLine(source, newProduct('Service'), true);
      discount.ER_Line_Type__c = 'Discount';
      update discount;
      Test.startTest();
      executeNow(account, false);
      Test.stopTest();
      System.assertEquals(master.Offer_Validity_End_Date__c, savedContract(master.Id).Offer_Validity_End_Date__c,
        'A blank discount offer date must not clear the existing master date.');
      System.assertEquals(true, savedContract(master.Id).Is_Master_Contract__c,
        'The checkbox must be stamped even when no solutions/date change is needed.');
      System.assertEquals(1, lineCount(master.Id), 'A line-type discount must still be cloned.');
    }
  }

  @IsTest
  static void excludesPricebooksEngagementAndDraft() {
    System.runAs(runner()) {
      Account account = newAccount('Exclusions');
      Contract master = newContract(account, 'TRC', 'Activated', 30);
      Contract included = newContract(account, 'TRE', 'Activated', 20);
      newLine(included, null, true);
      List<Pricebook2> pricebooks = new List<Pricebook2>();
      for (String keyword : new List<String>{ 'Luxembourg', 'Reduction', 'Mobility' }) {
        pricebooks.add(new Pricebook2(Name = keyword + ' Test', IsActive = true));
      }
      insert pricebooks;
      List<Contract> excludedContracts = new List<Contract>();
      Product2 excludedDiscount = newProduct('Discount');
      for (Pricebook2 pricebook : pricebooks) {
        Contract excluded = newContract(account, 'ECE', 'Activated', 10);
        excluded.Pricebook2Id = pricebook.Id;
        excludedContracts.add(excluded);
        newLine(excluded, excludedDiscount, true);
      }
      update excludedContracts;
      Contract engagement = newContract(account, 'ENG-COM', 'Activated', 10);
      engagement.Number_of_Benefit_Lines__c = 0;
      engagement.Number_of_Savings_Line__c = 1;
      update engagement;
      newLine(engagement, null, true);
      Contract draft = newContract(account, 'ECE', 'Draft', 5);
      newLine(draft, null, true);
      Test.startTest();
      executeNow(account, false);
      Test.stopTest();
      System.assertEquals(1, lineCount(master.Id), 'Only the eligible TRE line should be copied.');
      System.assertEquals('TRC / TRE', savedContract(master.Id).ER_Solutions__c, 'Excluded solutions must not be combined.');
      System.assertEquals(false, savedContract(engagement.Id).Is_Master_Contract__c, 'Engagement must stay untouched.');
    }
  }

  @IsTest
  static void skipsSingleContractAndNoActivatedMaster() {
    System.runAs(runner()) {
      Account single = newAccount('Single Contract');
      Contract only = newContract(single, 'TRC', 'Activated', 10);
      Account approval = newAccount('Approval Only');
      Contract first = newContract(approval, 'TRC', 'In Approval Process', 20);
      Contract second = newContract(approval, 'ECE', 'In Approval Process', 10);
      newLine(second, null, true);
      Test.startTest();
      new BenefitsContractMergeBatch(null, false).execute(null, new List<Account>{ single, approval });
      Test.stopTest();
      System.assertEquals(0, lineCount(first.Id), 'Approval-only accounts have no Activated master.');
      System.assertEquals(false, savedContract(first.Id).Is_Master_Contract__c, 'An approval contract cannot be master.');
      System.assertEquals(false, savedContract(only.Id).Is_Master_Contract__c, 'A single contract cannot be merged.');
    }
  }

  @IsTest
  static void skipsWhenNoActivatedTrcContract() {
    System.runAs(runner()) {
      Account account = newAccount('No TRC Master');
      Contract oldest = newContract(account, 'TRE', 'Activated', 30);
      Contract newer = newContract(account, 'ECE', 'Activated', 10);
      newLine(newer, null, true);
      Test.startTest();
      executeNow(account, false);
      Test.stopTest();
      System.assertEquals(0, lineCount(oldest.Id), 'No source lines should be cloned without an Activated TRC contract.');
      System.assertEquals(false, savedContract(oldest.Id).Is_Master_Contract__c, 'A non-TRC contract must not become master.');
      System.assertEquals('TRE', savedContract(oldest.Id).ER_Solutions__c, 'Skipped contracts must remain unchanged.');
    }
  }

  @IsTest
  static void explicitScopeLeavesOtherAccountUntouched() {
    System.runAs(runner()) {
      Account included = newAccount('Included Account');
      Contract master = newContract(included, 'TRC', 'Activated', 20);
      newLine(newContract(included, 'ECE', 'Activated', 10), null, true);
      Account excluded = newAccount('Unselected Account');
      Contract otherMaster = newContract(excluded, 'TRC', 'Activated', 20);
      newLine(newContract(excluded, 'ECE', 'Activated', 10), null, true);
      Test.startTest();
      Database.executeBatch(new BenefitsContractMergeBatch(new Set<Id>{ included.Id }, false), 1);
      Test.stopTest();
      System.assertEquals(1, lineCount(master.Id), 'The selected account must be merged.');
      System.assertEquals(0, lineCount(otherMaster.Id), 'Unselected accounts must not receive clones.');
      System.assertEquals(false, savedContract(otherMaster.Id).Is_Master_Contract__c, 'Unselected accounts must not be marked.');
    }
  }
}