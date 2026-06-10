/**
 * @description       :
 * @author            : Hassan DAKHCHA
 * @group             :
 * @last modified on  : 08-31-2023
 * @last modified by  : Hassan DAKHCHA
 **/
@IsTest
private class AutoenrollmentManageStoreTest {
  @testSetup
  static void testSetup() {
    Account newMerchantAccount = TestDataFactory.newAccount();
    newMerchantAccount.Name = 'test';
    newMerchantAccount.ER_Registration_Number__c = '2629495-9';
    insert newMerchantAccount;

    Contact contactTest = TestDataFactory.newContact(newMerchantAccount);
    contactTest.ER_Account_Address_Sync__c = LAbel.LABS_SF_Account_SyncAddressContact;
    contactTest.firstName = 'test manageStore';
    contactTest.lastName = 'test manageStore';
    contactTest.email = 'testManageStore@mailinator.com.test';
    contactTest.phone = '0102030405';
    contactTest.ER_BUPicklist__c = 'FI';
    insert contactTest;

    ER_Financial_Center__c testFinancialCenter = TestDataFactory.newFinancialCenter(
      newMerchantAccount,
      Label.LABS_SF_FinancialCenter_Client
    );
    testFinancialCenter.ERFI_OVT_Code__c = 'test';
    testFinancialCenter.ERFI_OVT_Operator__c = 'test';
    testFinancialCenter.Name = 'test';
    testFinancialCenter.ER_Type__c = 'Merchant';
    testFinancialCenter.ER_Invoicing_Country_Code__c = 'FR';
    testFinancialCenter.ER_Invoicing_Country__c = 'France';
    testFinancialCenter.ER_Contact__c = contactTest.id;
    testFinancialCenter.ER_BUPicklist__c = 'FI';
    testFinancialCenter.ER_Preferred_Invoicing_Method__c = 'E-invoice';
    insert testFinancialCenter;

    User runningUser = [SELECT id, ER_Business_Unit__c FROM User WHERE id = :UserInfo.getUserId()];
    Account clientAccount = APER07_UtilityTestMethod.getCompany('test');
    clientAccount.ER_Registration_Number__c = '0000112-1';
    insert clientAccount;

    List<ER_DependentValue__c> listCategoriesToCreate = new List<ER_DependentValue__c>();

    ER_DependentValue__c categoryParent1 = new ER_DependentValue__c();
    categoryParent1.Name = 'Parent1';
    categoryParent1.ER_Object__c = 'Store Category';
    categoryParent1.ER_Status__c = 'Active';
    categoryParent1.ER_Business_Unit__c = 'FI';

    ER_DependentValue__c categoryParent2 = new ER_DependentValue__c();
    categoryParent2.Name = 'Parent2';
    categoryParent2.ER_Object__c = 'Store Category';
    categoryParent2.ER_Status__c = 'Active';
    categoryParent2.ER_Business_Unit__c = 'FI';

    listCategoriesToCreate.add(categoryParent1);
    listCategoriesToCreate.add(categoryParent2);

    Database.insert(listCategoriesToCreate, true);
    System.assert(categoryParent1.Id != null);

    listCategoriesToCreate.clear();

    ER_DependentValue__c categoryChild = new ER_DependentValue__c();
    categoryChild.Name = 'Child1';
    categoryChild.ER_Object__c = 'Store Category';
    categoryChild.Parent_Dependent_Value__c = categoryParent1.Id;
    categoryChild.ER_Ordering__c = 2;
    categoryChild.ER_Status__c = 'Active';
    categoryChild.ER_Business_Unit__c = 'FI';
    listCategoriesToCreate.add(categoryChild);

    ER_DependentValue__c categoryChild2 = new ER_DependentValue__c();
    categoryChild2.Name = 'Child2';
    categoryChild2.ER_Object__c = 'Store Category';
    categoryChild2.Parent_Dependent_Value__c = categoryParent2.Id;
    categoryChild2.ER_Status__c = 'Active';
    categoryChild2.ER_Business_Unit__c = 'FI';
    listCategoriesToCreate.add(categoryChild2);

    Database.insert(listCategoriesToCreate, true);
    System.assert(categoryChild2.Id != null);

    listCategoriesToCreate.clear();

    ER_DependentValue__c categoryGrandChild = new ER_DependentValue__c();
    categoryGrandChild.Name = 'categoryGrandChild1';
    categoryGrandChild.ER_Object__c = 'Store Category';
    categoryGrandChild.ER_Status__c = 'Active';
    categoryGrandChild.Parent_Dependent_Value__c = categoryChild.Id;
    categoryGrandChild.ER_Business_Unit__c = 'FI';
    listCategoriesToCreate.add(categoryGrandChild);
    Database.insert(listCategoriesToCreate, true);
    System.assert(categoryGrandChild.Id != null);

    ER_Store__c store = new ER_Store__c(
      Name = 'CANDA HOTEL',
      ER_Merchant__c = newMerchantAccount.Id,
      ER_Financial_Center__c = testFinancialCenter.Id,
      ER_Contact__c = contactTest.Id,
      ER_Street__c = 'Test Street',
      ER_City__c = 'BUDAPEST',
      ER_Zip_Code__c = '1095'
    );
    insert store;

    insert new ER_StoreCategory__c(Store__c = store.id, Main_Category__c = true, Category__c = categoryGrandChild.id);

    ER_Acceptor__c acceptor = new ER_Acceptor__c(
      Name = 'CANDA HOTEL',
      ER_Store__c = store.Id,
      ER_MID_Authorization__c = '12341993',
      ER_SubMID_Authorization__c = '12341999',
      ER_Start_Date__c = date.today() + 10
    );
    insert acceptor;
  }

  @isTest
  static void testGetStoreCategories() {
    Map<String, Map<String, String>> categories = AutoenrollmentManageStore.getStoreCategories('FI', 'en');
    System.assertNotEquals(true, categories.isEmpty());
  }

  @isTest
  static void testGetFCContact() {
    List<ER_Financial_Center__c> financialCenters = [SELECT Id FROM ER_Financial_Center__c];
    Test.startTest();
    Map<String, String> contactInfos = AutoenrollmentManageStore.getFCContact(financialCenters[0].Id);
    Test.stopTest();
    System.assertEquals(false, contactInfos.isEmpty());
    System.debug(contactInfos);
    System.assertEquals('test manageStore', contactInfos.get('firstName'));
    System.assertEquals('test manageStore', contactInfos.get('lastName'));
    System.assertEquals('0102030405', contactInfos.get('phone'));
    System.assertEquals('testManageStore@mailinator.com.test'.toLowerCase(), contactInfos.get('mail'));
  }

  @isTest
  static void testGetStoreRecord() {
    Map<String, String> storeInfos = AutoenrollmentManageStore.getStoreRecord([SELECT Id FROM ER_Store__c].id);
    System.debug('testGetStoreRecord ' + storeInfos);
    System.assertEquals([SELECT Id FROM ER_Financial_Center__c].id, storeInfos.get('parentId'));
    System.assertEquals('testManageStore@mailinator.com.test'.toLowerCase(), storeInfos.get('ctcEmail'));
    System.assertEquals('0102030405', storeInfos.get('ctcPhone'));
    System.assertEquals('test manageStore', storeInfos.get('firstName'));
    System.assertEquals('test manageStore', storeInfos.get('lastName'));
  }

  @isTest
  static void testGetStoreActivities() {
    List<ER_StoreCategory__c> categories = AutoenrollmentManageStore.getStoreActivities(
      [SELECT Id FROM ER_Store__c].id
    );
    System.assertEquals('categoryGrandChild1', categories[0].Category__r.Name);
    System.assertEquals(true, categories[0].Main_Category__c);
  }

  @isTest
  static void testGetStoreTerminals() {
    List<ER_Acceptor__c> acceptors = AutoenrollmentManageStore.getStoreTerminals([SELECT Id FROM ER_Store__c].id);
    System.assertEquals('CANDA HOTEL', acceptors[0].Name);
    System.assertEquals('12341993', acceptors[0].ER_MID_Authorization__c);
    System.assertEquals('12341999', acceptors[0].ER_SubMID_Authorization__c);
  }

  @isTest
  static void testCreateStoreEvent() {
    List<Guest_Event__e> levt = new List<Guest_Event__e>();
    levt.add(
      new Guest_Event__e(
        Operation_Name__c = 'manageStoreCreation',
        Operation_Parameters__c = '{"fcid":"' +
          [SELECT Id FROM ER_Financial_Center__c]
          .id +
          '",' +
          '"store": {"city":"test city", "country":"FI", "ctcEmail":"email_ctc@test.com", "ctcPhone":"2321212332", "email":"email_test_Store@test.com",' +
          '"postalCode":"ZIP2324","facebook":"FB_NAME","website":"WS_NAME","firstName":"CTCNAME", "lastName":"LASTCTCNAME", "name":"testEvent", "phone":"0932843847", "street":"test treet"},' +
          '"categories":"' +
          [SELECT id FROM ER_DependentValue__c WHERE Name = 'Child1']
          .id +
          '",' +
          '"maincategory":"' +
          [SELECT id FROM ER_DependentValue__c WHERE Name = 'Child1']
          .id +
          '"}'
      )
    );

    AutoenrollmentManageStoreWOS.manageStoreEvents(levt);
    ER_Store__c store = [SELECT Id, Name FROM ER_Store__c WHERE NAME = 'testEvent'];
    System.assertEquals('testEvent', store.name);

    Map<String, String> storeInfos = AutoenrollmentManageStore.getStoreRecord(store.id);
    System.assertEquals([SELECT Id FROM ER_Financial_Center__c].id, storeInfos.get('parentId'));
    System.assertEquals('email_ctc@test.com', storeInfos.get('ctcEmail'));
    System.assertEquals('2321212332', storeInfos.get('ctcPhone'));
    System.assertEquals('CTCNAME', storeInfos.get('firstName'));
    System.assertEquals('LASTCTCNAME', storeInfos.get('lastName'));

    List<ER_StoreCategory__c> categories = AutoenrollmentManageStore.getStoreActivities(
      [SELECT Id FROM ER_Store__c WHERE NAME = 'testEvent'].id
    );
    System.assertEquals('Child1', categories[0].Category__r.Name);
    System.assertEquals(true, categories[0].Main_Category__c);
  }

  @isTest
  static void testUpdateStoreEvent() {
    List<Guest_Event__e> levt = new List<Guest_Event__e>();
    levt.add(
      new Guest_Event__e(
        Operation_Name__c = 'manageStoreInfoSave',
        Operation_Parameters__c = '{"id":"' +
          [SELECT Id FROM ER_Store__c]
          .id +
          '",' +
          '"storeInfos": {"city":"test city", "country":"FI", "ctcEmail":"email_ctc@test.com", "ctcPhone":"2321212332", "email":"email_test_Store@test.com",' +
          '"postalCode":"ZIP2324","facebook":"FB_NAME","website":"WS_NAME","firstName":"CTCNAME", "lastName":"LASTCTCNAME", "name":"testEvent", "phone":"0932843847", "street":"test treet"}' +
          '}'
      )
    );

    AutoenrollmentManageStoreWOS.manageStoreEvents(levt);
    ER_Store__c store = [SELECT Id, Name FROM ER_Store__c];
    System.assertEquals('testEvent', store.name);

    Map<String, String> storeInfos = AutoenrollmentManageStore.getStoreRecord(store.id);
    System.assertEquals([SELECT Id FROM ER_Financial_Center__c].id, storeInfos.get('parentId'));
    System.assertEquals('email_ctc@test.com', storeInfos.get('ctcEmail'));
    System.assertEquals('2321212332', storeInfos.get('ctcPhone'));
    System.assertEquals('CTCNAME', storeInfos.get('firstName'));
    System.assertEquals('LASTCTCNAME', storeInfos.get('lastName'));
  }

  @isTest
  static void testUpdateStoreActivitiesEvent() {
    List<Guest_Event__e> levt = new List<Guest_Event__e>();
    levt.add(
      new Guest_Event__e(
        Operation_Name__c = 'manageStoreActivitySave',
        Operation_Parameters__c = '{"id":"' +
          [SELECT Id FROM ER_Store__c]
          .id +
          '",' +
          '"categories":"' +
          [SELECT id FROM ER_DependentValue__c WHERE Name = 'Child1']
          .id +
          '|' +
          [SELECT id FROM ER_DependentValue__c WHERE Name = 'Child2']
          .id +
          '",' +
          '"maincategory":"' +
          [SELECT id FROM ER_DependentValue__c WHERE Name = 'Child1']
          .id +
          '"}'
      )
    );
    AutoenrollmentManageStoreWOS.manageStoreEvents(levt);

    List<ER_StoreCategory__c> categories = AutoenrollmentManageStore.getStoreActivities(
      [SELECT Id FROM ER_Store__c].id
    );
    System.assertEquals(true, categories[0].Category__r.Name == 'Child1' || categories[1].Category__r.Name == 'Child1');
    System.assertEquals(true, categories[0].Category__r.Name == 'Child2' || categories[1].Category__r.Name == 'Child2');

    System.assertEquals(true, categories[0].Main_Category__c || categories[1].Main_Category__c);
  }
}