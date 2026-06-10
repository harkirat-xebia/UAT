@isTest
public class APER23_Acceptor_Management_TEST {
  @testSetup
  static void testSetup() {
    //User runningUser = [select id,ER_Business_Unit__c,ER_BUText__c  FROM User WHERE id =: UserInfo.getUserId()];
    String testedBU = 'ES';
    User ur = TestDataFactory.newUser('APER23', 'APER23', 'Local Admin', testedBU);
    ur.ER_BypassVR__c = true;
    insert ur;

    System.runAs(ur) {
      Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER23_Acceptor_Management_Test');
      insert merchantAccount;

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'APER23_Acceptor_Management_Test',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      insert testFinancialCenter;

      PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

      List<Product2> solutionListToInsert = new List<Product2>();
      List<Product2> serviceListToInsert = new List<Product2>();
      List<PriceBookEntry> pbeListToInsert = new List<PriceBookEntry>();
      List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
      List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
      List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();
      List<ER_Solution_Line_Item__c> sliListToInsert = new List<ER_Solution_Line_Item__c>();

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'testSolution';
      newSolution.ER_Business_Unit__c = testedBU;
      solutionListToInsert.add(newSolution);

      Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
      newSolution2.ProductCode = 'testSolution2';
      newSolution2.ER_Business_Unit__c = testedBU;
      solutionListToInsert.add(newSolution2);

      insert solutionListToInsert;

      Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
      newService.ER_Business_Unit__c = testedBU;
      newService.ER_Solution2__c = newSolution2.Id;
      serviceListToInsert.add(newService);

      Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice3', newSolution2.id);
      newService2.ER_Business_Unit__c = testedBU;
      newService2.ER_Solution2__c = newSolution2.Id;
      serviceListToInsert.add(newService2);

      insert serviceListToInsert;

      PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
      pbeListToInsert.add(newPriceBookEntry);

      PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
      pbeListToInsert.add(newPriceBookEntry2);

      insert pbeListToInsert;

      Contract testContract = APER07_UtilityTestMethod.getContract(
        merchantAccount.id,
        Date.today(),
        'Draft',
        newPriceBook.Id
      );
      testContract.recordtypeid = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
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

      ER_ContractLineItem__c testContractLineItem2 = APER07_UtilityTestMethod.getContractLineItem(
        testContract.id,
        newService2.id,
        newPriceBookEntry2.id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem2);

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
        testFinancialCenter.Id,
        testContract.Id,
        testAccountLineItem.id,
        newSolution.Id
      );
      fcliListToInsert.add(testFinancialCenterLineItem);

      ER_Solution_Line_Item__c testFinancialCenterLineItem2 = APER07_UtilityTestMethod.getFinancialCenterLineItem(
        testFinancialCenter.Id,
        testContract.Id,
        testAccountLineItem2.id,
        newSolution2.Id
      );
      fcliListToInsert.add(testFinancialCenterLineItem2);

      insert fcliListToInsert;

      ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
        'APER23_Acceptor_Management_Test',
        merchantAccount.id,
        testFinancialCenter.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      insert testStore;

      ER_Solution_Line_Item__c testStoreLineItem = APER07_UtilityTestMethod.getStoreLineItemNew(
        testStore.id,
        testContract.id,
        testFinancialCenterLineItem.id,
        newSolution.id
      );
      sliListToInsert.add(testStoreLineItem);

      ER_Solution_Line_Item__c testStoreLineItem2 = APER07_UtilityTestMethod.getStoreLineItemNew(
        testStore.id,
        testContract.id,
        testFinancialCenterLineItem2.id,
        newSolution2.id
      );
      sliListToInsert.add(testStoreLineItem2);

      insert sliListToInsert;

      ER_Acceptor__c testAcceptor = APER07_UtilityTestMethod.getAcceptor(testStore.id);
      insert testAcceptor;

      ER_Solution_Line_Item__c testAcceptorLineItem = APER07_UtilityTestMethod.getAcceptorLineItem(
        testAcceptor.id,
        testContract.id,
        testStoreLineItem.id,
        newSolution.id
      );
      insert testAcceptorLineItem;

      ER_Solution_Line_Item__c testAcceptorLineItem2 = APER07_UtilityTestMethod.getAcceptorLineItem(
        testAcceptor.id,
        testContract.id,
        testStoreLineItem.id,
        newSolution2.id
      );
      insert testAcceptorLineItem2;
    }
  }
  @IsTest
  static void manageAcceptorLIFromContract() {
    Test.startTest();

    User u = [SELECT Id FROM User WHERE LastName = 'APER23'];

    System.runAs(u) {
      List<Contract> contractList = [
        SELECT id, AccountId, Status
        FROM Contract
        WHERE Status = :Label.LABS_SF_Contract_Status_Activated
      ];
      if (!contractList.isEmpty()) {
        APER23_Acceptor_Management.manageAcceptorLIFromContract(contractList[0]);
      }

      Test.stopTest();
    }
  }

  @IsTest
  static void manageAccLIForNewAcceptor() {
    Test.startTest();

    User u = [SELECT Id FROM User WHERE LastName = 'APER23'];

    System.runAs(u) {
      Map<Id, ER_Acceptor__c> acceptorMap = new Map<Id, ER_Acceptor__c>();

      Account merchantAccount = [SELECT id FROM Account WHERE Name = 'APER23_Acceptor_Management_Test'];
      ER_Store__c testStore = [SELECT Id FROM ER_Store__c WHERE Name = 'APER23_Acceptor_Management_Test'];
      ER_Acceptor__c testAcceptor2 = [SELECT Id, ER_Store__c, RecordTypeId FROM ER_Acceptor__c LIMIT 1];

      //update testAcceptor2;
      List<ER_Acceptor__c> acceptorList = new List<ER_Acceptor__c>();
      acceptorList.add(testAcceptor2);
      testAcceptor2.ER_MID_Authorization__c = '123';
      update testAcceptor2;
      acceptorMap.put(testAcceptor2.Id, testAcceptor2);
      APER23_Acceptor_Management.manageAccLIForNewAcceptor(acceptorMap);
      APER23_Acceptor_Management.updateDigitalStoreStatus(acceptorList, null);
      APER23_Acceptor_Management.setInactiveAcceptors(acceptorList);
      APER23_Acceptor_Management.updateAddAcceptorFuture(acceptorList);
      Test.stopTest();
    }

  }

  @IsTest
  static void preventAcceptorDuplicatesPLTest() {
    Test.startTest();
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Integration'];
    User u = new User(
      LastName = 'admin',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'cli',
      CommunityNickname = 'cli',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'PL'
    );
    insert u;

    System.runAs(u) {
      ER_Acceptor__c acc = new ER_Acceptor__c();
      acc.ER_MID_Authorization__c = 'Test auth';
      acc.ER_SubMID_Authorization__c = 'Test auth';
      acc.Name = 'Test';
      acc.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
      acc.ER_End_Date__c = Date.newInstance(2021, 11, 11);
      insert acc;

      ER_Acceptor__c acc2 = new ER_Acceptor__c();
      acc2.ER_MID_Authorization__c = 'Test auth2';
      acc2.ER_SubMID_Authorization__c = 'Test auth2';
      acc2.Name = 'Test2';
      acc2.ER_Start_Date__c = Date.newInstance(2021, 11, 12);
      acc2.ER_End_Date__c = Date.newInstance(2021, 11, 13);
      insert acc2;

      ER_Acceptor__c acc3 = new ER_Acceptor__c();
      acc3.ER_MID_Authorization__c = 'Test auth3';
      acc3.ER_SubMID_Authorization__c = 'Test auth3';
      acc3.Name = 'Test3';
      acc3.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
      acc3.ER_End_Date__c = Date.newInstance(2021, 11, 11);
      insert acc3;

      List<ER_Acceptor__c> acceptorIds = new List<ER_Acceptor__c>();
      acceptorIds.add(acc3);

      APER23_Acceptor_Management.checkAcceptorUniqueness(acceptorIds, null);
      APER23_Acceptor_Management.checkAcceptorUniquenessPL(acceptorIds, null);
      Test.stopTest();
    }
  }

  @IsTest
  static void preventAcceptorDuplicatesGRTest() {
    Test.startTest();

    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ER_INTEGRATION,
      'Greece',
      'GR'
    );

    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      ER_Acceptor__c acc = new ER_Acceptor__c();
      acc.ER_Acceptor_Scheme__c = 'MasterCard';
      acc.ER_Acceptor_Type__c = 'POS';
      acc.ER_MID_Authorization__c = 'Test auth';
      acc.ER_SubMID_Authorization__c = 'Test auth';
      acc.Name = 'Test';
      acc.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
      acc.ER_End_Date__c = Date.newInstance(2021, 11, 11);
      insert acc;

      ER_Acceptor__c acc2 = new ER_Acceptor__c();
      acc.ER_Acceptor_Scheme__c = 'MasterCard';
      acc.ER_Acceptor_Type__c = 'POS';
      acc2.ER_MID_Authorization__c = 'Test auth2';
      acc2.ER_SubMID_Authorization__c = 'Test auth2';
      acc2.Name = 'Test2';
      acc2.ER_Start_Date__c = Date.newInstance(2021, 11, 12);
      acc2.ER_End_Date__c = Date.newInstance(2021, 11, 13);
      insert acc2;

      ER_Acceptor__c acc3 = new ER_Acceptor__c();
      acc.ER_Acceptor_Scheme__c = 'MasterCard';
      acc.ER_Acceptor_Type__c = 'POS';
      acc3.ER_MID_Authorization__c = 'Test auth2';
      acc3.ER_SubMID_Authorization__c = 'Test auth2';
      acc3.Name = 'Test3';
      acc3.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
      acc3.ER_End_Date__c = Date.newInstance(2021, 11, 11);
      try {
        insert acc3;
      } catch (Exception e) {
        System.assert(e.getMessage().contains(Label.LAB_SF_DUPLICATE_ACCEPTOR_GR));
      }

      List<ER_Acceptor__c> acceptorIds = new List<ER_Acceptor__c>();
      acceptorIds.add(acc3);

      APER23_Acceptor_Management.checkAcceptorUniqueness(acceptorIds, null);
      APER23_Acceptor_Management.checkAcceptorUniquenessGR(acceptorIds);
      Test.stopTest();
    }
  }

  @IsTest
  static void preventAcceptorDuplicatesESTest() {
    Test.startTest();

    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Integration'];
    User u = new User(
      LastName = 'admin',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'cli',
      CommunityNickname = 'cli',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'ES'
    );
    insert u;

    System.runAs(u) {
      ER_Acceptor__c acc = new ER_Acceptor__c();
      acc.ER_MID_Authorization__c = 'Test auth';
      acc.ER_SubMID_Authorization__c = 'Test auth';
      acc.Name = 'Test';
      acc.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
      acc.ER_End_Date__c = Date.newInstance(2021, 11, 11);
      insert acc;

      ER_Acceptor__c acc2 = new ER_Acceptor__c();
      acc2.ER_MID_Authorization__c = 'Test auth2';
      acc2.ER_SubMID_Authorization__c = 'Test auth2';
      acc2.Name = 'Test2';
      acc2.ER_Start_Date__c = Date.newInstance(2021, 11, 12);
      acc2.ER_End_Date__c = Date.newInstance(2021, 11, 13);
      insert acc2;

      ER_Acceptor__c acc3 = new ER_Acceptor__c();
      acc3.ER_MID_Authorization__c = 'Test auth3';
      acc3.ER_SubMID_Authorization__c = 'Test auth3';
      acc3.Name = 'Test3';
      acc3.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
      acc3.ER_End_Date__c = Date.newInstance(2021, 11, 11);
      insert acc3;

      List<ER_Acceptor__c> acceptorIds = new List<ER_Acceptor__c>();
      acceptorIds.add(acc3);

      try {
        ER_Acceptor__c acc4 = new ER_Acceptor__c();
        acc4.ER_MID_Authorization__c = 'Test auth3';
        acc4.ER_SubMID_Authorization__c = 'Test auth3';
        acc4.Name = 'Test3';
        acc4.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
        acc4.ER_End_Date__c = Date.newInstance(2021, 11, 11);
        insert acc4;
      } catch (Exception e) {
        System.debug('>>>>> ALK - duplicates detected assertException : ' + e.getMessage());
        Boolean expectedExceptionThrown = e.getMessage().toLowerCase().contains('exception') ? true : false;
        System.assertEquals(expectedExceptionThrown, true);
      }

      APER23_Acceptor_Management.checkAcceptorUniqueness(acceptorIds, null);
      Test.stopTest();
    }
  }

  @IsTest
  static void testDuplicatesBENELUX() {
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Integration'];
    User u = new User(
      LastName = 'admin',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'cli',
      CommunityNickname = 'cli',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'BENELUX'
    );
    u.ER_BypassVR__c = true;
    insert u;

    System.runAs(u) {
      Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
      merchantAccount.ER_Registration_Number__c = 'X8576171T';
      merchantAccount.ER_BUPicklist__c = 'BENELUX';
      insert merchantAccount;

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'APER14_Store_Management_Test',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      insert testFinancialCenter;

      ER_Store__c store = APER07_UtilityTestMethod.getStore(
        'APER14_Store_Management_Test',
        merchantAccount.id,
        testFinancialCenter.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      insert store;

      Test.startTest();

      ER_Acceptor__c a1 = APER07_UtilityTestMethod.getAcceptor(store.Id, 'APER23_01', null, null);
      a1.ER_Acceptor_Scheme__c = 'WEBAuth';
      insert a1;

      a1 = [SELECT Id, ER_TID_Authorization__c, ER_MID_Authorization__c FROM ER_Acceptor__c WHERE Id = :a1.Id];
      System.assert(String.isNotBlank(a1.ER_TID_Authorization__c));
      System.assert(String.isNotBlank(a1.ER_MID_Authorization__c));

      ER_Acceptor__c a2 = APER07_UtilityTestMethod.getAcceptor(store.Id, 'APER23_02', '12345678', null);
      a2.ER_Acceptor_Scheme__c = 'C-TAP';
      insert a2;

      try {
        ER_Acceptor__c a3 = APER07_UtilityTestMethod.getAcceptor(store.Id, 'APER23_03', '12345678', null);
        a3.ER_Acceptor_Scheme__c = 'C-TAP';
        insert a3;
      } catch (Exception e) {
        System.debug('>>>>> ALK - duplicates detected assertException : ' + e.getMessage());
        Boolean expectedExceptionThrown = e.getMessage().toLowerCase().contains('duplicate') ? true : false;
        System.assertEquals(expectedExceptionThrown, true);
      }

      Test.stopTest();
    }
  }

  @IsTest
  static void testDuplicatesBENELUXMC() {
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Integration'];
    User u = new User(
      LastName = 'admin',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'cli',
      CommunityNickname = 'cli',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'BENELUX'
    );
    u.ER_BypassVR__c = true;
    insert u;

    System.runAs(u) {
      Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
      merchantAccount.ER_Registration_Number__c = 'X8576171T';
      merchantAccount.ER_BUPicklist__c = 'BENELUX';
      insert merchantAccount;

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'APER14_Store_Management_Test',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      insert testFinancialCenter;

      ER_Store__c store = APER07_UtilityTestMethod.getStore(
        'APER14_Store_Management_Test',
        merchantAccount.id,
        testFinancialCenter.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      insert store;

      Test.startTest();

      ER_Acceptor__c a1 = APER07_UtilityTestMethod.getAcceptor(store.Id, 'APER23_01', null, '123456');
      a1.ER_Acceptor_Scheme__c = 'MasterCard';
      insert a1;

      a1 = [SELECT Id, ER_TID_Authorization__c, ER_MID_Authorization__c FROM ER_Acceptor__c WHERE Id = :a1.Id];
      System.assert(String.isNotBlank(a1.ER_TID_Authorization__c));
      System.assert(String.isNotBlank(a1.ER_MID_Authorization__c));

      ER_Acceptor__c a2 = APER07_UtilityTestMethod.getAcceptor(store.Id, 'APER23_02', '123456', '123456');
      a2.ER_SubMID_Authorization__c = '1234';
      a2.ER_Acceptor_Scheme__c = 'MasterCard';
      insert a2;

      try {
        ER_Acceptor__c a3 = APER07_UtilityTestMethod.getAcceptor(store.Id, 'APER23_03', '123456', '123456');
        a3.ER_SubMID_Authorization__c = '1234';
        a3.ER_Acceptor_Scheme__c = 'MasterCard';
        insert a3;
      } catch (Exception e) {
        System.debug('>>>>> ALK - duplicates detected assertException : ' + e.getMessage());
        Boolean expectedExceptionThrown = e.getMessage().toLowerCase().contains('duplicate') ? true : false;
        System.assertEquals(expectedExceptionThrown, true);
      }

      Test.stopTest();
    }
  }

  @IsTest
  static void testAddBlockingRulesForEdenredPOS() {
    Test.startTest();

    User u = [SELECT Id FROM User WHERE LastName = 'APER23'];

    System.runAs(u) {
      ER_Store__c store = [SELECT Id FROM ER_Store__c WHERE Name = 'APER23_Acceptor_Management_Test'];
      Id posRecordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_Acceptor__c.SObjectType, 'Edenred_POS');
      try {
        ER_Acceptor__c acceptor = new ER_Acceptor__c();

        acceptor.ER_Store__c = store.Id;
        acceptor.Name = 'Test3';
        acceptor.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
        acceptor.ER_End_Date__c = Date.newInstance(2021, 11, 11);
        acceptor.RecordTypeId = posRecordTypeId;
        insert acceptor;
      } catch (Exception e) {
        //System.assertEquals(e.ge, true);
      }
      Test.stopTest();
    }
  }
}