/*
----------------------------------------------------------------------
-- - Name          : APER14_Store_Management_Test
-- - Author        : OLA
-- - Description   : TEST for Store Management class
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Jun-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER14_Store_Management_Test {
  // @testSetup
  // static void testSetup() {
  //     User runningUser = [select id,ER_Business_Unit__c  FROM User WHERE id =: UserInfo.getUserId()];
  //     Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
  //     merchantAccount.ER_Registration_Number__c = 'X8576171T';
  //     insert merchantAccount;

  //     ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter('APER14_Store_Management_Test',merchantAccount.id, Label.LABS_SF_FinancialCenter_Merchant,'Test','Test','Test','Test');
  //     testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
  //     insert testFinancialCenter;

  //     PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

  //     List<Product2> solutionListToInsert = new List<Product2>();
  //     List<Product2> serviceListToInsert = new List<Product2>();
  //     List<PriceBookEntry> pbeListToInsert = new List<PriceBookEntry>();
  //     List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
  //     List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
  //     List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();
  //     List<ER_Solution_Line_Item__c> sliListToInsert = new List<ER_Solution_Line_Item__c>();

  // Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
  // newSolution.ProductCode = 'testSolution';
  // newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
  // solutionListToInsert.add(newSolution);

  //     Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
  //    	newSolution2.ProductCode = 'testSolution2';
  //    	newSolution2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
  //     solutionListToInsert.add(newSolution2);

  //     insert solutionListToInsert;

  //     Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
  //     newService.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
  //     serviceListToInsert.add(newService);
  //     Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice2', newSolution2.id);
  //    	newService2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
  //     serviceListToInsert.add(newService2);

  //     insert serviceListToInsert;

  //     PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
  //     pbeListToInsert.add(newPriceBookEntry);

  //     PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
  //     pbeListToInsert.add(newPriceBookEntry2);

  //     insert pbeListToInsert;

  // Contract testContract = APER07_UtilityTestMethod.getContract(merchantAccount.id, Date.today(),Label.LABS_SF_Contract_Status_Draft,newPriceBook.Id);
  // testContract.recordtypeid =Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Contract_RT').getRecordTypeId();
  // insert testContract;

  //     ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(testContract.id, newService.id,newPriceBookEntry.id, 1, 1);
  //     cliListToInsert.add(testContractLineItem);

  //     ER_ContractLineItem__c testContractLineItem2 = APER07_UtilityTestMethod.getContractLineItem(testContract.id, newService2.id,newPriceBookEntry2.id, 1, 1);
  //     cliListToInsert.add(testContractLineItem2);

  //     insert cliListToInsert;

  //     testContract.status = Label.LABS_SF_Contract_Status_Activated;
  //     System.debug('testContract: '+testContract);
  //     update testContract;

  //     ER_Solution_Line_Item__c testAccountLineItem = APER07_UtilityTestMethod.getAccountLineItem(merchantAccount.Id, testContract.Id, newSolution.Id);
  //    	testAccountLineItem.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
  //     aliListToInsert.add(testAccountLineItem);

  // ER_Solution_Line_Item__c testAccountLineItem2 = APER07_UtilityTestMethod.getAccountLineItem(merchantAccount.Id, testContract.Id, newSolution2.Id);
  // testAccountLineItem2.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
  // aliListToInsert.add(testAccountLineItem2);

  //     insert aliListToInsert;

  //     ER_Solution_Line_Item__c testFinancialCenterLineItem = APER07_UtilityTestMethod.getFinancialCenterLineItem(testFinancialCenter.Id, testContract.Id,testAccountLineItem.id, newSolution.Id);
  //     testFinancialCenterLineItem.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
  //     fcliListToInsert.add(testFinancialCenterLineItem);

  //     ER_Solution_Line_Item__c testFinancialCenterLineItem2 = APER07_UtilityTestMethod.getFinancialCenterLineItem(testFinancialCenter.Id, testContract.Id,testAccountLineItem2.id, newSolution2.Id);
  //     testFinancialCenterLineItem2.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
  //     fcliListToInsert.add(testFinancialCenterLineItem2);

  //     insert fcliListToInsert;

  //     ER_Store__c testStore = APER07_UtilityTestMethod.getStore('APER14_Store_Management_Test',merchantAccount.id, testFinancialCenter.id, Date.today(),'Test','Test','Test','Test');
  //     insert testStore;

  //     ER_Store_Line_Item__c testStoreLineItem = APER07_UtilityTestMethod.getStoreLineItem(testStore.id, Label.LABS_SF_StoreLineItem_Decline, newSolution2.id);
  //     insert testStoreLineItem;
  //     /////////////solution line item

  //     ER_Solution_Line_Item__c testStoreLineItem2 = APER07_UtilityTestMethod.getStoreLineItemNew(testStore.id, testContract.id, testFinancialCenterLineItem.id, newSolution.id);
  //     sliListToInsert.add(testStoreLineItem2);
  // 	ER_Solution_Line_Item__c testStoreLineItem3 = APER07_UtilityTestMethod.getStoreLineItemNew(testStore.id, testContract.id, testFinancialCenterLineItem2.id, newSolution2.id);
  //     sliListToInsert.add(testStoreLineItem3);
  // 	insert sliListToInsert;
  // 	testFinancialCenterLineItem.ER_Status__c = Label.LAB_SF_SolutionLineItem_Active;
  //     update testFinancialCenterLineItem;

  //     ER_StoreCategory__c sc = new ER_StoreCategory__c();
  //     sc.Store__c = testStore.Id;
  //     insert sc;

  //     Id recordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_Store__c.SObjectType, 'Store_Aggregator');
  //     ER_Store__c testAggStore = APER07_UtilityTestMethod.getStore('APER14_Store_Management_Test',merchantAccount.id, testFinancialCenter.id, Date.today(),'Test','Test','Test','Test');
  //     testAggStore.RecordTypeId = recordTypeId;
  //     insert testAggStore;
  // }

  @IsTest
  static void disableStores() {
    APER14_Store_Management.isAPER14Test = true;

    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    merchantAccount.ER_Registration_Number__c = 'X8576171T';
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

    ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
      'APER14_Store_Management_Test',
      merchantAccount.id,
      testFinancialCenter.id,
      Date.today(),
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testStore.ER_BUPicklist__c = 'ES';
    insert testStore;

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    newSolution.ProductCode = 'testSolution';
    // newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    insert newSolution;

    ER_Store_Line_Item__c testStoreLineItem = APER07_UtilityTestMethod.getStoreLineItem(
      testStore.Id,
      Label.LABS_SF_StoreLineItem_Decline,
      newSolution.Id
    );
    insert testStoreLineItem;

    List<ER_Store_Line_Item__c> sliToUpdate = new List<ER_Store_Line_Item__c>();
    for (ER_Store__c store : [
      SELECT id, ER_Merchant__c, (SELECT id, ER_Solution__c FROM Store_line_Items__r)
      FROM ER_Store__c
      WHERE Name = 'APER14_Store_Management_Test'
    ]) {
      for (ER_Store_Line_Item__c sli : store.Store_line_Items__r) {
        sli.ER_Status__c = Label.LABS_SF_StoreLineItem_Decline;
        sliToUpdate.add(sli);
      }
    }

    if (!sliToUpdate.isEmpty()) {
      System.debug('sliToUpdate : ' + sliToUpdate);
      update sliToUpdate;
    }
  }

  @IsTest
  static void disableStoresTest() {
    APER14_Store_Management.isAPER14Test = true;

    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    merchantAccount.ER_Registration_Number__c = 'X8576171T';
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

    ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
      'APER14_Store_Management_Test',
      merchantAccount.id,
      testFinancialCenter.id,
      Date.today(),
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testStore.ER_BUPicklist__c = 'ES';
    insert testStore;

    String sliRecTypId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Store_Line_Item'
    );
    ER_Solution_Line_Item__c sli = new ER_Solution_Line_Item__c();
    sli.ER_Last_date_of_Sync__c = Date.today();
    sli.RecordTypeId = sliRecTypId;
    sli.ER_Store__c = testStore.Id;
    insert sli;

    ER_Solution_Line_Item__c sli2 = new ER_Solution_Line_Item__c();
    sli2.ER_Last_date_of_Sync__c = Date.today();
    sli2.ER_Status__c = 'Active';
    sli2.RecordTypeId = sliRecTypId;
    sli2.ER_Store__c = testStore.Id;
    insert sli2;

    ER_Solution_Line_Item__c sli3 = new ER_Solution_Line_Item__c();
    sli3.ER_Last_date_of_Sync__c = Date.today();
    sli3.ER_Status__c = 'Inactive';
    sli3.RecordTypeId = sliRecTypId;
    sli3.ER_Store__c = testStore.Id;
    insert sli3;

    List<ER_Store__c> storeList = [SELECT Id, RecordTypeId, ER_Merchant__c, Edenred_Store__c FROM ER_Store__c LIMIT 1];
    Test.startTest();
    APER14_Store_Management.disableStores(storeList);
    APER14_Store_Management.enableStores(storeList);
    //APER14_Store_Management.processAggregatorStore(storeList);
    Test.stopTest();
  }

  // (List<ER_Solution_Line_Item__c> sliToSync)
  @IsTest
  static void syncUpdateLineItemsTest() {
    APER14_Store_Management.isAPER14Test = true;

    User runningUser = [SELECT id, ER_Business_Unit__c FROM User WHERE id = :UserInfo.getUserId()];
    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    merchantAccount.ER_Registration_Number__c = 'X8576171T';
    insert merchantAccount;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

    Contract testContract = APER07_UtilityTestMethod.getContract(
      merchantAccount.id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id
    );
    testContract.recordtypeid = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
      .get('ER_Merchant_Contract_RT')
      .getRecordTypeId();
    insert testContract;

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    newSolution.ProductCode = 'testSolution';
    newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    insert newSolution;

    ER_Solution_Line_Item__c testAccountLineItem2 = APER07_UtilityTestMethod.getAccountLineItem(
      merchantAccount.Id,
      testContract.Id,
      newSolution.Id
    );
    testAccountLineItem2.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
    insert testAccountLineItem2;

    List<ER_Solution_Line_Item__c> SliList = new List<ER_Solution_Line_Item__c>();
    SliList = [SELECT Id, ER_BUPicklist__c FROM ER_Solution_Line_Item__c LIMIT 1];
    Map<Id, ER_Solution_Line_Item__c> scMap = new Map<Id, ER_Solution_Line_Item__c>();
    for (ER_Solution_Line_Item__c sc : SliList) {
      scMap.put(sc.Id, sc);
    }
    Test.startTest();
    APER14_Store_Management.syncUpdateLineItems(SliList, scMap);
    APER14_Store_Management.manageSLIFromContract(merchantAccount.Id);
    Test.stopTest();
  }

  @IsTest
  static void syncStoreCategoryTest() {
    APER14_Store_Management.isAPER14Test = true;

    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    merchantAccount.ER_Registration_Number__c = 'X8576171T';
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

    ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
      'APER14_Store_Management_Test',
      merchantAccount.id,
      testFinancialCenter.id,
      Date.today(),
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testStore.ER_BUPicklist__c = 'ES';
    insert testStore;

    String sliRecTypId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Store_Line_Item'
    );
    ER_Solution_Line_Item__c sli = new ER_Solution_Line_Item__c();
    sli.ER_Last_date_of_Sync__c = Date.today();
    sli.RecordTypeId = sliRecTypId;
    sli.ER_Store__c = testStore.Id;
    insert sli;

    ER_Solution_Line_Item__c sli2 = new ER_Solution_Line_Item__c();
    sli2.ER_Last_date_of_Sync__c = Date.today();
    sli2.ER_Status__c = 'Active';
    sli2.RecordTypeId = sliRecTypId;
    sli2.ER_Store__c = testStore.Id;
    insert sli2;

    ER_Solution_Line_Item__c sli3 = new ER_Solution_Line_Item__c();
    sli3.ER_Last_date_of_Sync__c = Date.today();
    sli3.ER_Status__c = 'Inactive';
    sli3.RecordTypeId = sliRecTypId;
    sli3.ER_Store__c = testStore.Id;
    insert sli3;

    List<ER_Store__c> storeList = [
      SELECT Id, RecordTypeId, ER_Merchant__c, Edenred_Store__c, ER_BUPicklist__c
      FROM ER_Store__c
      LIMIT 1
    ];

    ER_StoreCategory__c storeCat = new ER_StoreCategory__c();
    storeCat.ER_Last_date_of_Sync__c = Date.Today();
    storeCat.Store__c = storeList[0].Id;
    insert storeCat;

    List<ER_StoreCategory__c> storeCategories = [
      SELECT Id, ER_Last_date_of_Sync__c, Store__c, ER_BUPicklist__c
      FROM ER_StoreCategory__c
      LIMIT 1
    ];
    Map<Id, ER_StoreCategory__c> scMap = new Map<Id, ER_StoreCategory__c>();
    for (ER_StoreCategory__c sc : storeCategories) {
      scMap.put(sc.Id, sc);
    }
    Test.startTest();
    APER14_Store_Management.syncStoreCategory(storeCategories, scMap);
    storeCat.ER_Sync_result__c = 'pending_synchronization';
    update storeCat;
    Test.stopTest();
  }

  @IsTest
  static void updateMainStoreCategoryTest() {
    APER14_Store_Management.isAPER14Test = true;

    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    merchantAccount.ER_Registration_Number__c = 'X8576171T';
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

    ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
      'APER14_Store_Management_Test',
      merchantAccount.id,
      testFinancialCenter.id,
      Date.today(),
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testStore.ER_BUPicklist__c = 'ES';
    insert testStore;

    String sliRecTypId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Store_Line_Item'
    );
    ER_Solution_Line_Item__c sli = new ER_Solution_Line_Item__c();
    sli.ER_Last_date_of_Sync__c = Date.today();
    sli.RecordTypeId = sliRecTypId;
    sli.ER_Store__c = testStore.Id;
    insert sli;

    ER_Solution_Line_Item__c sli2 = new ER_Solution_Line_Item__c();
    sli2.ER_Last_date_of_Sync__c = Date.today();
    sli2.ER_Status__c = 'Active';
    sli2.RecordTypeId = sliRecTypId;
    sli2.ER_Store__c = testStore.Id;
    insert sli2;

    ER_Solution_Line_Item__c sli3 = new ER_Solution_Line_Item__c();
    sli3.ER_Last_date_of_Sync__c = Date.today();
    sli3.ER_Status__c = 'Inactive';
    sli3.RecordTypeId = sliRecTypId;
    sli3.ER_Store__c = testStore.Id;
    insert sli3;

    List<ER_Store__c> storeList = [SELECT Id, RecordTypeId, ER_Merchant__c, Edenred_Store__c FROM ER_Store__c LIMIT 1];

    ER_StoreCategory__c storeCat = new ER_StoreCategory__c();
    ER_DependentValue__c cat = new ER_DependentValue__c(
      RecordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_DependentValue__c.SObjectType, 'Category'),
      Name = 'Station essence', // Name
      Level__c = 1, // Level
      ER_Status__c = 'Active', // Status
      ER_Category_Code__c = 'MKT-CAT.BE.TRE.002' // Category Code
    );
    insert cat;

    storeCat.ER_Last_date_of_Sync__c = Date.Today();
    storeCat.Store__c = storeList[0].Id;
    storeCat.Category__c = cat.Id;
    insert storeCat;
    List<ER_StoreCategory__c> storCats = [SELECT Id, Main_Category__c FROM ER_StoreCategory__c];
    for (ER_StoreCategory__c storeCateg : storCats) {
      storeCateg.Main_Category__c = true;
    }
    update storCats;
  }

  @IsTest
  static void manageStoreStatusTest() {
    APER14_Store_Management.isAPER14Test = true;

    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    merchantAccount.ER_Registration_Number__c = 'X8576171T';
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

    ER_Financial_Center__c testFinancialCenterClient = APER07_UtilityTestMethod.getFinancialCenter(
      'APER14_Store_Management_Test2',
      merchantAccount.id,
      Label.LABS_SF_FinancialCenter_Client,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    insert testFinancialCenterClient;

    String fcliRecTypId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Financial_Center_Line_Item'
    );
    ER_Solution_Line_Item__c fcli = new ER_Solution_Line_Item__c();
    fcli.ER_Financial_Center__c = testFinancialCenter.Id;
    fcli.ER_Status__c = 'Undefined';
    fcli.RecordTypeId = fcliRecTypId;
    fcli.ER_Creation_date_in_OS__c = Date.today();
    fcli.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
    insert fcli;

    ER_Solution_Line_Item__c fcli1 = new ER_Solution_Line_Item__c();
    fcli1.ER_Last_date_of_Sync__c = Date.today();
    fcli1.ER_Creation_date_in_OS__c = Date.today();
    fcli1.ER_Status__c = 'Active';
    fcli1.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
    fcli1.RecordTypeId = fcliRecTypId;
    fcli1.ER_Financial_Center__c = testFinancialCenter.Id;
    fcli1.ER_Parent_Line_Item__c = fcli.Id;
    insert fcli1;

    ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
      'APER14_Store_Management_Test',
      merchantAccount.id,
      testFinancialCenter.id,
      Date.today(),
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testStore.ER_Status__c = 'Active';
    testStore.ER_BUPicklist__c = 'ES';
    insert testStore;

    String sliRecTypId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Store_Line_Item'
    );
    ER_Solution_Line_Item__c sli = new ER_Solution_Line_Item__c();
    sli.ER_Last_date_of_Sync__c = Date.today();
    sli.RecordTypeId = sliRecTypId;
    sli.ER_Store__c = testStore.Id;
    insert sli;

    ER_Solution_Line_Item__c sli2 = new ER_Solution_Line_Item__c();
    sli2.ER_Last_date_of_Sync__c = Date.today();
    sli2.ER_Status__c = 'Active';
    sli2.RecordTypeId = sliRecTypId;
    sli2.ER_Store__c = testStore.Id;
    insert sli2;

    ER_Solution_Line_Item__c sli3 = new ER_Solution_Line_Item__c();
    sli3.ER_Last_date_of_Sync__c = Date.today();
    sli3.ER_Status__c = 'Inactive';
    sli3.RecordTypeId = sliRecTypId;
    sli3.ER_Store__c = testStore.Id;
    insert sli3;

    Id posRecordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_Acceptor__c.SObjectType, 'Edenred_POS');
    ER_Acceptor__c acceptor = new ER_Acceptor__c();
    acceptor.ER_Store__c = testStore.Id;
    acceptor.Name = 'Test Acceptor';
    acceptor.ER_Start_Date__c = Date.newInstance(2021, 11, 9);
    acceptor.RecordTypeId = posRecordTypeId;
    insert acceptor;

    ER_Delivery_Site__c testDeliverySite = TestDataFactory.newDeliverySite(
      merchantAccount,
      'DeliverySite Test',
      testFinancialCenterClient
    );
    testDeliverySite.ER_Street__c = '123 Dummy St';
    testDeliverySite.ER_Zip_Code__c = '99000';
    testDeliverySite.ER_City__c = 'Anycity';
    testDeliverySite.ER_Country__c = 'Country';
    insert testDeliverySite;

    String dsliRecTypId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Delivery_Site_Line_Item'
    );
    ER_Solution_Line_Item__c sli4 = new ER_Solution_Line_Item__c();
    sli4.ER_Last_date_of_Sync__c = Date.today();
    sli4.ER_Creation_date_in_OS__c = Date.today();
    sli4.ER_Status__c = 'Active';
    sli4.RecordTypeId = dsliRecTypId;
    sli4.ER_Delivery_Site__c = testDeliverySite.Id;
    insert sli4;

    ER_Solution_Line_Item__c sli5 = new ER_Solution_Line_Item__c();
    sli5.ER_Last_date_of_Sync__c = Date.today();
    sli5.ER_Status__c = 'Active';
    sli5.RecordTypeId = dsliRecTypId;
    sli5.ER_Delivery_Site__c = testDeliverySite.Id;
    sli5.ER_Parent_Line_Item__c = sli4.Id;
    insert sli5;

    ER_Distribution_Point__c testDistributionPoint = TestDataFactory.newDistributionPoint(
      'APER14_Store_Management_Test',
      testDeliverySite.id
    );
    testDistributionPoint.ER_Street__c = '123 Dummy St';
    testDistributionPoint.ER_Zip_Code__c = '99000';
    testDistributionPoint.ER_City__c = 'Anycity';
    testDistributionPoint.ER_Country__c = 'Country';
    insert testDistributionPoint;

    String dpliRecTypId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Distribution_Point_Line_Item'
    );
    ER_Solution_Line_Item__c dpli = new ER_Solution_Line_Item__c();
    dpli.ER_Last_date_of_Sync__c = Date.today();
    dpli.ER_Creation_date_in_OS__c = Date.today();
    dpli.ER_Status__c = 'Active';
    dpli.RecordTypeId = dpliRecTypId;
    dpli.ER_Distribution_Point__c = testDistributionPoint.Id;
    dpli.ER_Delivery_Site__c = testDeliverySite.Id;
    insert dpli;

    ER_Solution_Line_Item__c dpli2 = new ER_Solution_Line_Item__c();
    dpli2.ER_Last_date_of_Sync__c = Date.today();
    dpli2.ER_Creation_date_in_OS__c = Date.today();
    dpli2.ER_Status__c = 'Active';
    dpli2.RecordTypeId = dpliRecTypId;
    dpli2.ER_Distribution_Point__c = testDistributionPoint.Id;
    dpli2.ER_Delivery_Site__c = testDeliverySite.Id;
    dpli2.ER_Parent_Line_Item__c = dpli.Id;
    insert dpli2;

    List<ER_Solution_Line_Item__c> sliList = [
      SELECT Id, ER_Store__c, RecordTypeId
      FROM ER_Solution_Line_Item__c
    ];
    Test.startTest();
    APER14_Store_Management.manageStoreStatus(sliList);
    update sliList;
    acceptor.ER_Creation_date_in_OS__c = null;
    update acceptor;
    update testStore;
    Test.stopTest();
  }

  @IsTest
  static void testCreateAccountPartnerStoreAggregators() {
    APER14_Store_Management.isAPER14Test = true;
    User ur = TestDataFactory.newUser('APER14', 'APER14', 'Local Admin', 'CEN');
    ur.ER_bypassTrigger__c = true;
    insert ur;
    System.runAs(ur) {
      Account merAcct = APER07_UtilityTestMethod.getCompany('merAcct');
      //merAcct.ER_VAT_Number__c = '12345678-9-10';
      insert merAcct;
      Account newAggAccount = APER07_UtilityTestMethod.insertAccount('aggAccount', 'Aggregator_Merchant');
      newAggAccount.ER_VAT_Number__c = '12345678-9-10';
      update newAggAccount;

      Account newAggAccount2 = APER07_UtilityTestMethod.insertAccount('aggAccount2', 'Aggregator_Merchant');
      newAggAccount2.ER_VAT_Number__c = '12345678-9-110';
      update newAggAccount2;

      ER_Financial_Center__c merFC = APER07_UtilityTestMethod.getFinancialCenter(
        'merFC',
        merAcct.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      merFC.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      insert merFC;

      Partner partner1 = new Partner(
        Role = Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR,
        AccountFromId = merAcct.Id,
        AccountToId = newAggAccount.Id
      );
      insert partner1;
      Partner partner2 = new Partner(Role = 'Aggregator', AccountFromId = newAggAccount.Id, AccountToId = merAcct.Id);
      insert partner2;

      ER_Store__c merStore = APER07_UtilityTestMethod.getStore(
        'merStore',
        merAcct.id,
        merFc.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      merStore.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
        ER_Store__c.SObjectType,
        Constants.STORE_STORE_AGGREGATOR_RT
      );
      merStore.ER_VAT_Number__c = '12345678-9-10';
      merStore.ER_Aggregator_Merchant__c = newAggAccount.Id;
      merStore.ER_Merchant__c = merAcct.Id;
      merStore.ER_BUPicklist__c = 'ES';
      insert merStore;

      merStore.ER_VAT_Number__c = '12345678-9-11';
      merStore.ER_Aggregator_Merchant__c = newAggAccount2.Id;
      update merStore;

      APER14_Store_Management.createAccountPartnerStoreAggregators(new List<ER_Store__c>{ merStore });
      APER14_Store_Management.createAggregatorMerchant(new List<ER_Store__c>{ merStore });
      //APER14_Store_Management.createWebAuthAccepterStoreAggregator(new List<ER_Store__c>{merStore});
    }
  }

  @IsTest
  static void testrecalculateAccountPartnerAggregator() {
    APER14_Store_Management.isAPER14Test = true;
    User ur = TestDataFactory.newUser('APER14', 'APER14', 'Local Admin', 'CEN');

    insert ur;
    System.runAs(ur) {
      Account merAcct = APER07_UtilityTestMethod.getCompany('merAcct');
      Database.insert(merAcct, true);

      Account newAggAccount = APER07_UtilityTestMethod.insertAccount('aggAccount', 'Aggregator_Merchant');
      newAggAccount.ER_VAT_Number__c = '12345678-9-10';
      Database.update(newAggAccount, true);

      Account newAggAccount2 = APER07_UtilityTestMethod.insertAccount('aggAccount2', 'Aggregator_Merchant');
      newAggAccount2.ER_VAT_Number__c = '12345678-9-110';
      Database.update(newAggAccount2, true);

      ER_Financial_Center__c merFC = APER07_UtilityTestMethod.getFinancialCenter(
        'merFC',
        merAcct.Id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      merFC.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      Database.insert(merFC, true);

      Partner partner1 = new Partner(
        Role = Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR,
        AccountFromId = merAcct.Id,
        AccountToId = newAggAccount2.Id
      );
      insert partner1;
      Partner partner2 = new Partner(Role = 'Aggregator', AccountFromId = newAggAccount2.Id, AccountToId = merAcct.Id);
      insert partner2;

      ER_Store__c merStore = APER07_UtilityTestMethod.getStore(
        'merStore',
        merAcct.Id,
        merFc.Id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      merStore.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
        ER_Store__c.SObjectType,
        Constants.STORE_STORE_AGGREGATOR_RT
      );
      merStore.ER_VAT_Number__c = '12345678-9-10';
      merStore.ER_Aggregator_Merchant__c = newAggAccount.Id;
      merStore.ER_Merchant__c = merAcct.Id;
      merStore.ER_BUPicklist__c = 'ES';
      Database.insert(merStore, false);

      merStore.ER_VAT_Number__c = '12345678-9-11';
      merStore.ER_Aggregator_Merchant__c = newAggAccount2.Id;
      Database.update(merStore, false);
    }
  }

  @IsTest
  static void testcreateWebAuthAccepterStoreAggregator() {
    APER14_Store_Management.isAPER14Test = true;
    User ur = TestDataFactory.newUser('APER14', 'APER14', 'Local Admin', 'CEN');
    ur.ER_Bypass_Triggers__c = 'AcceptorToLoopTrigger';

    insert ur;
    System.runAs(ur) {
      Account merAcct = APER07_UtilityTestMethod.getCompany('merAcct');
      Database.insert(merAcct, true);

      Account newAggAccount = APER07_UtilityTestMethod.insertAccount('aggAccount', 'Aggregator_Merchant');
      newAggAccount.ER_VAT_Number__c = '12345678-9-10';
      Database.update(newAggAccount, true);

      Account newAggAccount2 = APER07_UtilityTestMethod.insertAccount('aggAccount2', 'Aggregator_Merchant');
      newAggAccount2.ER_VAT_Number__c = '12345678-9-110';
      Database.update(newAggAccount2, true);

      ER_Financial_Center__c merFC = APER07_UtilityTestMethod.getFinancialCenter(
        'merFC',
        merAcct.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      merFC.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      Database.insert(merFC, true);

      Partner partner1 = new Partner(
        Role = Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR,
        AccountFromId = merAcct.Id,
        AccountToId = newAggAccount2.Id
      );
      insert partner1;
      Partner partner2 = new Partner(Role = 'Aggregator', AccountFromId = newAggAccount2.Id, AccountToId = merAcct.Id);
      insert partner2;

      ER_Store__c store = APER07_UtilityTestMethod.getStore(
        'store',
        merAcct.id,
        merFC.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      store.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_Store__c.SObjectType, 'ER_Merchant_Store');
      store.ER_BUPicklist__c = 'ES';
      insert store;

      ER_Store__c store2 = APER07_UtilityTestMethod.getStore(
        'store2',
        merAcct.id,
        merFC.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      store2.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_Store__c.SObjectType, 'ER_Merchant_Store');
      store2.ER_BUPicklist__c = 'ES';
      insert store2;

      ER_Store__c merStore = APER07_UtilityTestMethod.getStore(
        'merStore',
        merAcct.id,
        merFc.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      merStore.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
        ER_Store__c.SObjectType,
        Constants.STORE_STORE_AGGREGATOR_RT
      );
      merStore.ER_VAT_Number__c = '12345678-9-10';
      merStore.ER_Aggregator_Merchant__c = newAggAccount.Id;
      merStore.ER_Merchant__c = merAcct.Id;
      merStore.Edenred_Store__c = store.Id;
      merStore.ER_BUPicklist__c = 'ES';
      insert merStore;

      merStore.ER_VAT_Number__c = '12345678-9-11';
      merStore.Edenred_Store__c = store2.Id;
      merStore.ER_Aggregator_Merchant__c = newAggAccount2.Id;
      update merStore;
    }
  }

  static testMethod void manageSLIFromContract() {
    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    merchantAccount.ER_Registration_Number__c = 'X8576171T';
    insert merchantAccount;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

    Contract testContract = APER07_UtilityTestMethod.getContract(
      merchantAccount.id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id
    );
    testContract.recordtypeid = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
      .get('ER_Merchant_Contract_RT')
      .getRecordTypeId();
    insert testContract;

    List<Contract> contractList = [
      SELECT id, AccountId
      FROM Contract
      WHERE Status = :Label.LABS_SF_Contract_Status_Activated
    ];
    if (!contractList.isEmpty()) {
      APER14_Store_Management.manageSLIFromContract(contractList[0].AccountId);
    }
  }

  static testMethod void manageSLIFromContractNew() {
    List<Contract> contractList = [
      SELECT id, AccountId, Status
      FROM Contract
      WHERE Status = :Label.LABS_SF_Contract_Status_Activated
    ];
    if (!contractList.isEmpty()) {
      APER14_Store_Management.manageSLIFromContractNew(contractList[0]);
    }
  }
  // static testMethod void testVirtualAcceptors() {

  //     List<ER_StoreCategory__c> sclist = [select id, ER_Sync_result__c from ER_StoreCategory__c];
  //     Map<Id, ER_StoreCategory__c> scMap = new Map<Id, ER_StoreCategory__c>();
  //     for(ER_StoreCategory__c sc : scList){
  //         scMap.put(sc.Id, sc);
  //     }

  //     Set<String> pList = new Set<String>();
  //     for(Product2 p : [select Id, Name from product2]){
  //         pList.add(p.id);
  //     }

  //     if(!sclist.isEmpty()){

  //         APER14_Store_Management.syncStoreCategory(sclist);
  //         APER14_Store_Management.syncStoreCategoryFlags(scMap, scMap);
  //         APER14_Store_Management.deleteStoreLineItemsForAccount(pList,'APER14_Store_Management_Test');
  //     }
  // }

  // // Stefania
  // static testMethod void disableStoresTest() {

  //     List<ER_Store__c> storeList = [select id, ER_Status__c, ER_Closure_Date__c, ER_Closure_Reason__c from ER_Store__c];
  //     if(!storeList.isEmpty()){

  //         APER14_Store_Management.disableStores(storeList);
  //         APER14_Store_Management.enableStores(storeList);
  //     }
  // }

  // static testMethod void manageStoreStatusTest() {

  //     List<ER_Solution_Line_Item__c> storeLiList = [select id, ER_Store__c from ER_Solution_Line_Item__c];
  //     if(!storeLiList.isEmpty()){

  //         APER14_Store_Management.manageStoreStatus(storeLiList);
  //     }
  // }
}