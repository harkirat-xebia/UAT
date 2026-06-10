/*
----------------------------------------------------------------------
-- - Name          : AcceptorToLoopTriggerHandlerTest
-- - Author        : snica
-- - Description   :
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Oct-2022    snica                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@IsTest
private class AcceptorToLoopTriggerHandlerTest {
  @TestSetup
  static void testSetup() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'PL');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account merchantAccount = APER07_UtilityTestMethod.getCompany('ER_SyncStructureWithLegacy_Test');
      insert merchantAccount;

      Contact contactTest = APER07_UtilityTestMethod.getContact(
        'ER_Contact_RT',
        'Test',
        'ER_SyncStructureWithLegacy_Test'
      );
      contactTest.AccountId = merchantAccount.Id;
      contactTest.Email = 'ER_SyncStructureWithLegacy_Test@edenred.com';
      contactTest.ER_Account_Address_Sync__c = Label.LABS_SF_Account_SyncAddressContact;
      insert contactTest;

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'ER_SyncStructureWithLegacy_Test',
        merchantAccount.Id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      testFinancialCenter.ER_Contact__c = contactTest.Id;
      insert testFinancialCenter;

      ER_Bank_Account__c bankAccount = APER07_UtilityTestMethod.getBankAccount(
        testFinancialCenter.Id,
        'ER_SyncStructureWithLegacy_Test',
        'Open',
        'Paris',
        'Paris street',
        '00000000-00000000-00000000'
      );
      insert bankAccount;

      testFinancialCenter.ER_Bank_Account__c = bankAccount.Id;
      update testFinancialCenter;

      Pricebook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

      List<Product2> solutionListToInsert = new List<Product2>();
      List<Product2> serviceListToInsert = new List<Product2>();
      List<PricebookEntry> pbeListToInsert = new List<PricebookEntry>();
      List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
      List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
      List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();
      List<ER_Solution_Line_Item__c> sliListToInsert = new List<ER_Solution_Line_Item__c>();
      List<ER_Solution_Line_Item__c> acclIListToInsert = new List<ER_Solution_Line_Item__c>();

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'testSolution';
      newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
      solutionListToInsert.add(newSolution);

      Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
      newSolution2.ProductCode = 'testSolution2';
      newSolution2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
      solutionListToInsert.add(newSolution2);

      insert solutionListToInsert;

      Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.Id);
      newService.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
      serviceListToInsert.add(newService);
      Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice2', newSolution2.Id);
      newService2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
      serviceListToInsert.add(newService2);

      insert serviceListToInsert;

      PricebookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.Id, newService.Id);
      pbeListToInsert.add(newPriceBookEntry);

      PricebookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.Id, newService2.Id);
      pbeListToInsert.add(newPriceBookEntry2);

      insert pbeListToInsert;

      Contract testContract = APER07_UtilityTestMethod.getContract(
        merchantAccount.Id,
        Date.today(),
        Label.LABS_SF_Contract_Status_Draft,
        newPriceBook.Id
      );
      testContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
        .get('ER_Merchant_Contract_RT')
        .getRecordTypeId();
      insert testContract;

      ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(
        testContract.Id,
        newService.Id,
        newPriceBookEntry.Id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem);

      ER_ContractLineItem__c testContractLineItem2 = APER07_UtilityTestMethod.getContractLineItem(
        testContract.Id,
        newService2.Id,
        newPriceBookEntry2.Id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem2);

      insert cliListToInsert;

      testContract.Status = Label.LABS_SF_Contract_Status_Activated;
      update testContract;

      ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
        'ER_SyncStructureWithLegacy_Test',
        merchantAccount.Id,
        testFinancialCenter.Id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      insert testStore;

      ER_Store_Line_Item__c testStoreLineItem = APER07_UtilityTestMethod.getStoreLineItem(
        testStore.Id,
        Label.LABS_SF_StoreLineItem_Decline,
        newSolution2.Id
      );
      insert testStoreLineItem;
    }
  }

  @IsTest
  static void testBehavior() {
    Test.startTest();
    List<Account> accounts = [SELECT Id FROM Account];
    List<ER_Financial_Center__c> fcs = [SELECT Id, ER_Account_Name__c, ER_Type__c FROM ER_Financial_Center__c];
    List<Contact> contacts = [SELECT Id FROM Contact];

    ER_Loop__c looptst = new ER_Loop__c(Name = 'Test loop', ER_External_Reference__c = 'EXT-REF_test');
    insert looptst;

    ER_Account_to_Loop__c newAccountToLoop = new ER_Account_to_Loop__c(
      ER_Behaviour__c = 'DECLINE',
      ER_Loop__c = looptst.Id,
      ER_Account__c = accounts[0].Id
    );
    insert newAccountToLoop;

    ER_Loop__c looptst2 = new ER_Loop__c(Name = 'Test loop2', ER_External_Reference__c = 'EXT-REF_test2');
    insert looptst2;

    ER_Account_to_Loop__c newAccountToLoop2 = new ER_Account_to_Loop__c(
      ER_Behaviour__c = 'DECLINE',
      ER_Loop__c = looptst2.Id,
      ER_Account__c = accounts[0].Id
    );
    insert newAccountToLoop2;
    newAccountToLoop2.ER_Behaviour__c = 'ACCEPT';
    update newAccountToLoop2;

    ER_Store__c store = new ER_Store__c(
      Name = 'CANDA HOTEL',
      ER_Merchant__c = accounts[0].Id,
      ER_Financial_Center__c = fcs[0].Id,
      ER_Contact__c = contacts[0].Id,
      ER_Street__c = 'Test Street',
      ER_City__c = 'BUDAPEST',
      ER_Zip_Code__c = '1095'
    );
    insert store;

    ER_Acceptor__c acceptor = new ER_Acceptor__c(
      Name = 'CANDA HOTEL',
      ER_Store__c = store.Id,
      ER_MID_Authorization__c = '12341993',
      ER_Start_Date__c = date.today() + 10
    );
    insert acceptor;

    ER_Acceptor_to_Loop__c testAcceptorToLoop = new ER_Acceptor_to_Loop__c(
      ER_Acceptor__c = acceptor.Id,
      ER_Loop__c = looptst.Id
    );

    try {
      insert testAcceptorToLoop;
    } catch (Exception ex) {
    }

    ER_Acceptor_to_Loop__c testAcceptorToLoop2 = [
      SELECT Id
      FROM ER_Acceptor_to_Loop__c
      WHERE ER_Acceptor__c = :acceptor.Id
      LIMIT 1
    ];
    update testAcceptorToLoop2;
    delete testAcceptorToLoop2;
    Test.stopTest();
  }
}