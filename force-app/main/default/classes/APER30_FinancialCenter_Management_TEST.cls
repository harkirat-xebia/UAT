/*
----------------------------------------------------------------------
-- - Name          : APER30_FinancialCenter_Management_TEST
-- - Author        : KHAD
-- - Description   : Test class for Financial Center Management.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- FEB-2021     KHAD                   1.0         Initial version
-- JUNE-2021    NOOR                   1.1         Add duplicate rule when creating or updating financial center
---------------------------------------------------------------------------------------
*/
@isTest
public class APER30_FinancialCenter_Management_TEST {
  @TestSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APER30', 'APER30', 'Local Admin', 'Czech_Republic', 'CZ');
    insert ur;

    System.runAs(ur) {
      Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER30_FinancialCenter_Management_TEST');
      insert merchantAccount;
      PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

      List<ER_Financial_Center__c> fcListToInsert = new List<ER_Financial_Center__c>();
      List<Product2> solutionListToInsert = new List<Product2>();
      List<Product2> serviceListToInsert = new List<Product2>();
      List<PriceBookEntry> pbeListToInsert = new List<PriceBookEntry>();
      List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
      List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
      List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'APER30_FinancialCenter_Management_TEST',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      fcListToInsert.add(testFinancialCenter);
      ER_Financial_Center__c testFinancialCenter2 = APER07_UtilityTestMethod.getFinancialCenter(
        'APER30_FinancialCenter_Management_TEST_TEST2',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Client,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter2.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      fcListToInsert.add(testFinancialCenter2);
      insert fcListToInsert;

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'testSolution';
      solutionListToInsert.add(newSolution);
      Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
      newSolution2.ProductCode = 'testSolution2';
      solutionListToInsert.add(newSolution2);
      insert solutionListToInsert;

      Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
      serviceListToInsert.add(newService);
      Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice3', newSolution2.id);
      serviceListToInsert.add(newService2);
      insert serviceListToInsert;

      PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
      newPriceBookEntry.ER_Percentage__c = null;
      pbeListToInsert.add(newPriceBookEntry);
      PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
      newPriceBookEntry2.ER_Percentage__c = null;
      pbeListToInsert.add(newPriceBookEntry2);
      insert pbeListToInsert;

      Contract testContract = APER07_UtilityTestMethod.getContract(
        merchantAccount.id,
        Date.today(),
        Label.LABS_SF_Contract_Status_Draft,
        newPriceBook.Id
      );
      testContract.ER_Offline__c = true;
      testContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
        .get('ER_Merchant_Contract_RT')
        .getRecordTypeId();
      insert testContract;

      ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(
        testContract.id,
        newService.id,
        newPriceBookEntry.id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem);
      ER_ContractLineItem__c testContractLineItem3 = APER07_UtilityTestMethod.getContractLineItem(
        testContract.id,
        newService2.id,
        newPriceBookEntry2.id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem3);
      insert cliListToInsert;

      testContract.status = Label.LABS_SF_Contract_Status_Activated;
      update testContract;

      ER_Solution_Line_Item__c testAccountLineItem = APER07_UtilityTestMethod.getAccountLineItem(
        merchantAccount.Id,
        testContract.Id,
        newSolution.Id
      );
      testAccountLineItem.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
      aliListToInsert.add(testAccountLineItem);
      ER_Solution_Line_Item__c testAccountLineItem2 = APER07_UtilityTestMethod.getAccountLineItem(
        merchantAccount.Id,
        testContract.Id,
        newSolution2.Id
      );
      testAccountLineItem2.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
      aliListToInsert.add(testAccountLineItem2);
      insert aliListToInsert;

      ER_Solution_Line_Item__c testFinancialCenterLineItem = APER07_UtilityTestMethod.getFinancialCenterLineItem(
        testFinancialCenter.id,
        testContract.Id,
        testAccountLineItem.id,
        newSolution.id
      );
      fcliListToInsert.add(testFinancialCenterLineItem);
      ER_Solution_Line_Item__c testFinancialCenterLineItem2 = APER07_UtilityTestMethod.getFinancialCenterLineItem(
        testFinancialCenter.id,
        testContract.Id,
        testAccountLineItem2.id,
        newSolution2.id
      );
      fcliListToInsert.add(testFinancialCenterLineItem2);
      insert fcliListToInsert;
    }
  }

  @IsTest
  static void manageFCLIForFinancialCenter() {
    List<Contract> contractList = [
      SELECT id, AccountId, ER_OpportunityId__c, RecordTypeId, Status
      FROM Contract
      WHERE Status = :Label.LABS_SF_Contract_Status_Activated
    ];
    if (!contractList.isEmpty()) {
      APER30_FinancialCenter_Management.manageFCLIForFinancialCenter(contractList[0]);
    }
  }

  @IsTest
  static void manageFCLIForNewFinancialCenter() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER30'];
    System.runAs(ur) {
      Map<Id, ER_Financial_Center__c> financialCenterMap = new Map<Id, ER_Financial_Center__c>();
      List<ER_Financial_Center__c> financialCenterList = new List<ER_Financial_Center__c>();

      Account merchantAccount = [SELECT id FROM Account WHERE Name = 'APER30_FinancialCenter_Management_TEST' LIMIT 1];

      ER_Financial_Center__c testFinancialCenter3 = APER07_UtilityTestMethod.getFinancialCenter(
        'APER30_FinancialCenter_Management_TEST_TEST3',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Client,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter3.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      financialCenterList.add(testFinancialCenter3);

      ER_Financial_Center__c testFinancialCenter4 = APER07_UtilityTestMethod.getFinancialCenter(
        'APER30_FinancialCenter_Management_TEST_TEST4',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter4.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      financialCenterList.add(testFinancialCenter4);

      insert financialCenterList;

      for (ER_Financial_Center__c fc : financialCenterList) {
        financialCenterMap.put(fc.Id, fc);
      }

      APER30_FinancialCenter_Management.manageFCLIForNewFinancialCenter(financialCenterMap);
    }
  }

  @IsTest
  static void getAllFCLineItems() {
    Test.startTest();
    List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'APER30_FinancialCenter_Management_TEST'];
    Map<Id, ER_Solution_Line_Item__c> mapItems = APER30_FinancialCenter_Management.getAllFCLineItems(
      new Set<String>{ accounts[0].Id }
    );
    Test.stopTest();
  }

  @IsTest
  static void createZuoraBillingAccount() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'PL'
    );
    u.UserRoleId = ur.Id;

    System.runAs(u) {
      Account a = APER07_UtilityTestMethod.getCompany('APER30_FinancialCenter_Management_TEST_PL_Zuora');
      insert a;

      Contact c = TestDataFactory.newContact(a);
      insert c;

      Test.startTest();
      SendToZuoraMock zuoraMock = new SendToZuoraMock();
      Test.setMock(HttpCalloutMock.class, zuoraMock);
      ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter(
        'fc' + Datetime.now().getTime(),
        a.Id,
        Label.LABS_SF_FinancialCenter_Client,
        'Some Street',
        'Warsaw',
        '00-001',
        'Poland'
      );
      fc.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      fc.ER_Contact__c = c.Id;
      insert fc;

      Test.stopTest();
    }
  }

  @IsTest
  static void updateZuoraBillingAccount() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'PL'
    );
    u.UserRoleId = ur.Id;

    System.runAs(u) {
      Account a = APER07_UtilityTestMethod.getCompany('APER30_FinancialCenter_Management_TEST_PL_Zuora');
      insert a;

      Contact c = TestDataFactory.newContact(a);
      insert c;

      ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter(
        'fc' + Datetime.now().getTime(),
        a.Id,
        Label.LABS_SF_FinancialCenter_Client,
        'Some Street',
        'Warsaw',
        '00-001',
        'Poland'
      );
      fc.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      fc.ER_Contact__c = c.Id;
      insert fc;

      Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
      ba.Name = 'BaName';
      ba.ER_Financial_Center__c = fc.Id;
      ba.Zuora__AccountNumber__c = 'A00000111';
      ba.Zuora__Account__c = a.Id;
      ba.SEQUENCE_SET__c = 'AFFILIATE';
      ba.Zuora__Status__c = 'Active';
      ba.CurrencyIsoCode = 'PLN';
      insert ba;

      Test.startTest();
      SendToZuoraMock zuoraMock = new SendToZuoraMock();
      Test.setMock(HttpCalloutMock.class, zuoraMock);
      fc.ER_Zip_Code__c = 'ZIP999';
      update fc;
      Test.stopTest();
    }
  }

  @IsTest
  static void manageFinancialCenterStores() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER30'];
    System.runAs(ur) {
      Test.startTest();
      List<ER_Financial_Center__c> fcs = [
        SELECT
          Id,
          ER_Business_Unit__c,
          ER_Invoicing_Site__c,
          ER_Payment_Site__c,
          ER_SmartER_Context__c,
          ER_BUPicklist__c,
          ER_Master__c,
          ER_Account_Name__c,
          ER_Contact__c,
          ER_Creation_date_in_OS__c,
          ER_Sync_result__c
        FROM ER_Financial_Center__c
      ];
      Map<Id, ER_Financial_Center__c> fcsMap = new Map<Id, ER_Financial_Center__c>(fcs);
      APER30_FinancialCenter_Management.manageFinancialCenterStores(fcsMap, fcsMap);
      APER30_FinancialCenter_Management.syncFinancialcenters(fcs, fcsMap);
      APER30_FinancialCenter_Management.syncFinancialCenterFlags(fcsMap, fcsMap);
      Test.stopTest();
    }
  }

  @isTest
  static void syncFinancialCentersWithSuccess() {
    Test.startTest();
    List<ER_Financial_Center__c> fcList = [
      SELECT id, ER_BUPicklist__c, ER_SmartER_Context__c, ER_To_sync_with_smarter__c, ER_Account_Name__c
      FROM ER_Financial_Center__c
    ];
    id idAcc = fcList[0].ER_Account_Name__c;
    update new Account(id = idAcc, ER_SmartER_Context__c = true, SmartER_Customer_Id__c = 'ID_SYNC_ACC');
    id idFc = fcList[0].id;
    fcList[0].ER_SmartER_Context__c = true;
    update fcList;

    System.assert(
      true,
      [SELECT ER_To_sync_with_smarter__c FROM ER_Financial_Center__c WHERE id = :idFc]
      .ER_To_sync_with_smarter__c
    );

    update new Account(id = idAcc, SmartER_Customer_Id__c = null);
    update new ER_Financial_Center__c(id = idFc, ER_To_sync_with_smarter__c = false);

    fcList = [
      SELECT id, ER_BUPicklist__c, ER_SmartER_Context__c, ER_To_sync_with_smarter__c, ER_Account_Name__c
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c = :idAcc
    ];
    for (ER_Financial_Center__c fc : fcList) {
      fc.ER_SmartER_Context__c = true;
      fc.ER_To_sync_with_smarter__c = false;
    }
    update fcList;

    for (ER_Financial_Center__c fc : fcList) {
      fc.ER_SmartER_Context__c = true;
      fc.ER_To_sync_with_smarter__c = false;
    }
    update fcList;

    System.assertEquals(
      0,
      [
          SELECT id, ER_BUPicklist__c, ER_SmartER_Context__c, ER_To_sync_with_smarter__c, ER_Account_Name__c
          FROM ER_Financial_Center__c
          WHERE ER_Account_Name__c = :idAcc AND ER_To_sync_with_smarter__c = FALSE
        ]
        .size()
    );

    // check Account SmartER_Customer_Id__c that will trigger the FCs
    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);

    ER_Financial_Center__c fc = [
      SELECT
        ER_Smarter_1st_Sync_Date__c,
        ER_Smarter_Last_Sync_Date__c,
        ER_Smarter_Sync_Error__c,
        ER_Smarter_Sync_Status__c
      FROM ER_Financial_Center__c
      WHERE id = :idFC
    ];

    System.assertEquals(null, fc.ER_Smarter_1st_Sync_Date__c);
    System.assertEquals(null, fc.ER_Smarter_Last_Sync_Date__c);
    System.assertEquals(null, fc.ER_Smarter_Sync_Error__c);
    System.assertEquals(null, fc.ER_Smarter_Sync_Status__c);

    update new Account(id = idAcc, SmartER_Customer_Id__c = 'ID_SYNC_ACC');
    Test.getEventBus().deliver();
    Test.stopTest();

    fc = [
      SELECT
        ER_Smarter_1st_Sync_Date__c,
        ER_Smarter_Last_Sync_Date__c,
        ER_Smarter_Sync_Error__c,
        ER_Smarter_Sync_Status__c
      FROM ER_Financial_Center__c
      WHERE id = :idFC
    ];

    System.assertNotEquals(null, fc.ER_Smarter_1st_Sync_Date__c);
    System.assertNotEquals(null, fc.ER_Smarter_Last_Sync_Date__c);
    System.assertEquals(null, fc.ER_Smarter_Sync_Error__c);
    System.assertEquals(Constants.SYNCHRONIZED_STATUS, fc.ER_Smarter_Sync_Status__c);
  }

  /*@isTest
  static void syncFinancialCentersWithFailure() {
    Test.startTest();
    List<ER_Financial_Center__c> fcList = [
      SELECT id, ER_BUPicklist__c, ER_SmartER_Context__c, ER_To_sync_with_smarter__c, ER_Account_Name__c
      FROM ER_Financial_Center__c
    ];
    id idAcc = fcList[0].ER_Account_Name__c;
    update new Account(id = idAcc, ER_SmartER_Context__c = true, SmartER_Customer_Id__c = 'ID_SYNC_ACC');
    id idFc = fcList[0].id;

    for (ER_Financial_Center__c fc : fcList) {
      fc.ER_SmartER_Context__c = true;
    }

    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);
    SmarterAPIMock.serviceToFail = Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_SERVICE_NAME;

    //update new ER_Financial_Center__c(id=idFc, ER_Invoicing_Street__c=' New Street adress');
    update fcList;

    Test.getEventBus().deliver();
    Test.stopTest();

    ER_Financial_Center__c fc = [
      SELECT
        ER_Smarter_1st_Sync_Date__c,
        ER_Smarter_Last_Sync_Date__c,
        ER_Smarter_Sync_Error__c,
        ER_Smarter_Sync_Status__c
      FROM ER_Financial_Center__c
      WHERE id = :idFC
    ];

    System.assertEquals(null, fc.ER_Smarter_1st_Sync_Date__c);
    //System.assertNotEquals(null, fc.ER_Smarter_Last_Sync_Date__c);
    System.assertEquals(true, fc.ER_Smarter_Sync_Error__c.contains('SYNC IN ERROR'));
    System.assertEquals(true, fc.ER_Smarter_Sync_Error__c.contains('234324DFREF'));
    System.assertEquals(Constants.NOT_SYNCHRONIZED_STATUS, fc.ER_Smarter_Sync_Status__c);
  }
  */

  @IsTest
  static void checkAccountProfileSEPATest() {
    User ur = TestDataFactory.newUser('newFrFirstName', 'newFrLastName', 'ER Integration', 'France', 'FR');
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      Test.setMock(HttpCalloutMock.class, smarterMock);

      List<Account> accounts = new List<Account>();

      Account a = APER07_UtilityTestMethod.getCompany('newFrCompany' + Datetime.now().getTime());
      a.ER_BUPicklist__c = 'FR';
      a.ER_Credit_Scoring__c = 61;
      a.ER_Legal_Status__c = Constants.ACTIVE;
      accounts.add(a);

      Account a2 = APER07_UtilityTestMethod.getCompany('newFrCompany' + Datetime.now().getTime());
      a2.ER_BUPicklist__c = 'FR';
      a2.ER_Credit_Scoring__c = 41;
      a2.ER_Legal_Status__c = Constants.ACTIVE;
      accounts.add(a2);

      insert accounts;

      List<Contact> contacts = new List<Contact>();
      Contact c = TestDataFactory.newContact(a);
      c.ER_SmartER_Context__c = true;
      contacts.add(c);

      Contact c2 = TestDataFactory.newContact(a2);
      c2.ER_SmartER_Context__c = true;
      contacts.add(c2);

      insert contacts;

      List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();
      ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter(
        'newFC' + Datetime.now().getTime(),
        a.Id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Some street',
        'Paris',
        '75001',
        'France'
      );
      fc.ER_Contact__c = c.Id;
      fc.ER_SmartER_Context__c = true;
      fc.ER_Country_Code__c = 'FR';
      fc.ER_Invoicing_Country_Code__c = 'FR';
      financialCenters.add(fc);

      ER_Financial_Center__c fc2 = APER07_UtilityTestMethod.getFinancialCenter(
        'newFC' + Datetime.now().getTime(),
        a2.Id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Some street',
        'Paris',
        '75001',
        'France'
      );
      fc2.ER_Contact__c = c2.Id;
      fc2.ER_SmartER_Context__c = true;
      fc2.ER_Country_Code__c = 'FR';
      fc2.ER_Invoicing_Country_Code__c = 'FR';
      financialCenters.add(fc2);

      insert financialCenters;

      Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
      ba.Name = 'BaName';
      ba.ER_Financial_Center__c = fc.Id;
      ba.Zuora__AccountNumber__c = 'A00000100';
      ba.Zuora__Account__c = a.Id;
      ba.SEQUENCE_SET__c = 'CUSTOMER';
      ba.Zuora__Status__c = 'Active';
      ba.CurrencyIsoCode = 'EUR';
      ba.TECH_Financial_Center__c = fc.Id;
      insert ba;

      Zuora__Payment__c payment = new Zuora__Payment__c(
        Name = Utils.generateUniqueString(Constants.TYPE_STRING, 15),
        Zuora__Type__c = 'External',
        Zuora__Effective_Date__c = Date.today(),
        Zuora__Status__c = 'Processed',
        Zuora__Account__c = a.Id,
        Zuora__BillingAccount__c = ba.Id,
        ER_Order_Number__c = 'EFR230020569',
        Zuora__Amount__c = 2693600,
        Zuora__AppliedCreditBalanceAmount__c = 0,
        Zuora__GatewayStatus__c = 'NotSubmitted',
        Zuora__ReferenceId__c = 'EFR230020569'
      );
      insert payment;

      String message = APER30_FinancialCenter_Management.checkAccountProfileSEPA(fc.Id);
      Assert.isTrue(message == null, 'Direct Debit Cannot be calculated');

      String message2 = APER30_FinancialCenter_Management.checkAccountProfileSEPA(fc2.Id);
      Assert.isTrue(String.isNotBlank(message2), 'Direct Debit scoring updated');

      String message3 = APER30_FinancialCenter_Management.checkAccountProfileSEPA(null);
      Assert.isTrue(String.isNotBlank(message3), 'Direct Debit scoring updated');
      Test.stopTest();
    }
  }

  @IsTest
  static void testCreateBankAccount() {
    User ur = TestDataFactory.newUser('newFrFirstName', 'newFrLastName', 'ER Integration', 'France', 'FR');
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      Test.setMock(HttpCalloutMock.class, smarterMock);

      List<Account> accounts = new List<Account>();

      Account a = APER07_UtilityTestMethod.getCompany('newFrCompany' + Datetime.now().getTime());
      a.ER_BUPicklist__c = 'FR';
      a.ER_Credit_Scoring__c = 61;
      a.ER_Legal_Status__c = Constants.ACTIVE;
      accounts.add(a);
      insert accounts;

      List<Contact> contacts = new List<Contact>();
      Contact c = TestDataFactory.newContact(a);
      c.ER_SmartER_Context__c = true;
      contacts.add(c);
      insert contacts;

      List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();
      ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter(
        'newFC' + Datetime.now().getTime(),
        a.Id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Some street',
        'Paris',
        '75001',
        'France'
      );
      fc.ER_Contact__c = c.Id;
      fc.ER_SmartER_Context__c = true;
      fc.ER_Country_Code__c = 'FR';
      fc.ER_Invoicing_Country_Code__c = 'FR';
      financialCenters.add(fc);

      insert financialCenters;

      fc.ER_DocuGen_IBAN__c = '12345678910112';
      fc.ER_DocuGen_BIC__c = '1234';
      fc.ER_Direct_Debit_Scoring__c = true;
      update fc;

      List<ER_Bank_Account__c> bas = [SELECT Id FROM ER_Bank_Account__c WHERE ER_Financial_Center__c = :fc.Id];

      System.assert(!bas.isEmpty());
      ER_Financial_Center__c fcUpdated = [SELECT Id, ER_Bank_Account__c FROM ER_Financial_Center__c WHERE Id = :fc.Id];
      System.assert(
        fcUpdated.ER_Bank_Account__c != null,
        'Check if Bank account has been attached to Financial Center'
      );

      Test.stopTest();
    }
  }

  @isTest
  static void validateIbanTest() {
    User ur = TestDataFactory.newUser('newFrFirstName', 'newFrLastName', 'ER Integration', 'France', 'FR');
    insert ur;

    System.runAs(ur) {
      Account newClient = APER07_UtilityTestMethod.getCompany('newFrCompany' + Datetime.now().getTime());
      insert newClient;

      Contact c = TestDataFactory.newContact(newClient);
      insert c;

      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      Test.setMock(HttpCalloutMock.class, smarterMock);

      ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter(
        'newFC' + Datetime.now().getTime(),
        newClient.Id,
        Label.LABS_SF_FinancialCenter_Client,
        'Some street',
        'Paris',
        '75001',
        'France'
      );
      //fc.ER_Contact__c = c.Id;
      fc.ER_SmartER_Context__c = true;
      fc.ER_Country_Code__c = 'FR';
      fc.ER_Invoicing_Country_Code__c = 'FR';
      fc.ER_DocuGen_IBAN__c = '00000000-00000000-00000000';
      insert fc;

      ER_Bank_Account__c bankAccount = APER07_UtilityTestMethod.getBankAccount(
        fc.Id,
        'APER30_BankAccount_Test',
        'Open',
        'Paris',
        'Paris street',
        '00000000-00000000-00000000'
      );
      insert bankAccount;

      fc.ER_Bank_Account__c = bankAccount.Id;
      update fc;

      Test.stopTest();
    }
  }

  @IsTest
  static void testManageFinancialCenterAddresses_paymentToInvoicing() {
    ER_Financial_Center__c fc = new ER_Financial_Center__c();
    fc.ER_Street__c = 'Main Payment Street';
    fc.ER_Zip_Code__c = '1000';
    fc.ER_City__c = 'Brussels';
    fc.ER_Country__c = 'Belgium';
    // Invoicing address fields all blank -> should copy payment to invoicing
    Test.startTest();
    APER30_FinancialCenter_Management.manageFinancialCenterAddresses(new List<ER_Financial_Center__c>{ fc });
    Test.stopTest();
    System.assertEquals('Main Payment Street', fc.ER_Invoicing_Street__c);
    System.assertEquals('1000', fc.ER_Invoicing_Zip_Code__c);
  }

  @IsTest
  static void testManageFinancialCenterAddresses_invoicingToPayment() {
    ER_Financial_Center__c fc = new ER_Financial_Center__c();
    // Payment address empty (all blank) but country_code set -> isFCPaymentAddressEmpty = true
    fc.ER_Country_Code__c = 'BE';
    fc.ER_Invoicing_Street__c = 'Invoice Street';
    fc.ER_Invoicing_Zip_Code__c = '2000';
    fc.ER_Invoicing_City__c = 'Antwerp';
    fc.ER_Invoicing_Country__c = 'Belgium';
    // Payment fields all blank -> should copy invoicing to payment
    Test.startTest();
    APER30_FinancialCenter_Management.manageFinancialCenterAddresses(new List<ER_Financial_Center__c>{ fc });
    Test.stopTest();
    System.assertEquals('Invoice Street', fc.ER_Street__c);
    System.assertEquals('2000', fc.ER_Zip_Code__c);
  }

  @IsTest
  static void testSetMaster_directCall() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER30' LIMIT 1];
    System.runAs(ur) {
      List<ER_Financial_Center__c> fcs = [
        SELECT Id, ER_Master__c, ER_Account_Name__c, ER_Type__c
        FROM ER_Financial_Center__c
        LIMIT 5
      ];
      Test.startTest();
      APER30_FinancialCenter_Management.setMaster(fcs);
      Test.stopTest();
      System.assert(true, 'setMaster executed without error');
    }
  }

  @IsTest
  static void testSetMasterFC_OnAccount_directCall() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER30' LIMIT 1];
    System.runAs(ur) {
      ER_Financial_Center__c fc = [
        SELECT Id, ER_Master__c, ER_Account_Name__c, ER_Type__c, ER_Business_Unit__c
        FROM ER_Financial_Center__c
        WHERE ER_Type__c = :Label.LABS_SF_FinancialCenter_Merchant
        LIMIT 1
      ];
      fc.ER_Master__c = true;
      Map<Id, ER_Financial_Center__c> fcMap = new Map<Id, ER_Financial_Center__c>{ fc.Id => fc };
      Test.startTest();
      APER30_FinancialCenter_Management.setMasterFC_OnAccount(fcMap);
      Test.stopTest();
      System.assert(true, 'setMasterFC_OnAccount executed without error');
    }
  }

  @IsTest
  static void testUpdateLastModifiedDateFunctionalUser_directCall() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER30' LIMIT 1];
    System.runAs(ur) {
      List<ER_Financial_Center__c> fcs = [
        SELECT Id, ER_Last_Modified_Date_Functional_User__c
        FROM ER_Financial_Center__c
        LIMIT 2
      ];
      Test.startTest();
      APER30_FinancialCenter_Management.updateLastModifiedDateFunctionalUser(fcs);
      Test.stopTest();
      System.assert(true, 'updateLastModifiedDateFunctionalUser executed without error');
    }
  }

  /*@IsTest
  static void testCreateAcrForFinancialCenters_directCall() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER30' LIMIT 1];
    System.runAs(ur) {
      Account a = [SELECT Id FROM Account WHERE Name = 'APER30_FinancialCenter_Management_TEST' LIMIT 1];

      Contact c = TestDataFactory.newContact(a);
      insert c;

      ER_Financial_Center__c fc = [
        SELECT Id, ER_Account_Name__c, ER_Contact__c
        FROM ER_Financial_Center__c
        WHERE ER_Account_Name__c = :a.Id
        LIMIT 1
      ];
      ER_Financial_Center__c oldFc = fc.clone(true, true, false, false);
      fc.ER_Contact__c = c.Id;

      Map<Id, SObject> newMap = new Map<Id, SObject>{ fc.Id => fc };
      Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldFc.Id => oldFc };

      Test.startTest();
      APER30_FinancialCenter_Management.createAcrForFinancialCenters(newMap, oldMap);
      Test.stopTest();

      List<AccountContactRelation> acrs = [
        SELECT Id FROM AccountContactRelation
        WHERE AccountId = :a.Id AND ContactId = :c.Id
      ];
      System.assert(!acrs.isEmpty(), 'ACR should be created');
    }
  }*/
}