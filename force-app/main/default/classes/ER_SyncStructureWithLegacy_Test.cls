/**
 * Created by khaddouch on 15/06/2021.
 * @author KHAD
 * @date 15/16/2021
 * @description test class to build json to sync
 */
@IsTest
public with sharing class ER_SyncStructureWithLegacy_Test {
  @TestSetup
  static void testSetup() {
    User runningUser = [SELECT Id, ER_Business_Unit__c FROM User WHERE Id = :UserInfo.getUserId()];
    Account merchantAccount = APER07_UtilityTestMethod.getCompany('ER_SyncStructureWithLegacy_Test');
    insert merchantAccount;

    Account partnerAccount = APER07_UtilityTestMethod.getCompany('Partner_ER_SyncStructureWithLegacy_Test');
    insert partnerAccount;

    AccountPartner apr = new AccountPartner(
      AccountFromId = merchantAccount.Id,
      AccountToId = partnerAccount.Id,
      Role = 'Distributor',
      IsPrimary = false
    );
    insert apr;

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
      merchantAccount.id,
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
      testAccountLineItem.Id,
      newSolution.Id
    );
    testFinancialCenterLineItem.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
    fcliListToInsert.add(testFinancialCenterLineItem);

    ER_Solution_Line_Item__c testFinancialCenterLineItem2 = APER07_UtilityTestMethod.getFinancialCenterLineItem(
      testFinancialCenter.Id,
      testContract.Id,
      testAccountLineItem2.Id,
      newSolution2.Id
    );
    testFinancialCenterLineItem2.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
    fcliListToInsert.add(testFinancialCenterLineItem2);

    insert fcliListToInsert;

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
    /////////////solution line item

    ER_Solution_Line_Item__c testStoreLineItem2 = APER07_UtilityTestMethod.getStoreLineItemNew(
      testStore.Id,
      testContract.Id,
      testFinancialCenterLineItem.Id,
      newSolution.Id
    );
    sliListToInsert.add(testStoreLineItem2);
    ER_Solution_Line_Item__c testStoreLineItem3 = APER07_UtilityTestMethod.getStoreLineItemNew(
      testStore.Id,
      testContract.Id,
      testFinancialCenterLineItem2.Id,
      newSolution2.Id
    );
    sliListToInsert.add(testStoreLineItem3);
    insert sliListToInsert;

    ER_Acceptor__c testAcceptor = APER07_UtilityTestMethod.getAcceptor(testStore.Id);
    insert testAcceptor;

    ER_Solution_Line_Item__c testAcceptorLineItem = APER07_UtilityTestMethod.getAcceptorLineItem(
      testAcceptor.Id,
      testContract.Id,
      testStoreLineItem2.Id,
      newSolution.Id
    );
    acclIListToInsert.add(testAcceptorLineItem);
    ER_Solution_Line_Item__c testAcceptorLineItem2 = APER07_UtilityTestMethod.getAcceptorLineItem(
      testAcceptor.Id,
      testContract.Id,
      testStoreLineItem3.Id,
      newSolution2.Id
    );
    acclIListToInsert.add(testAcceptorLineItem2);
    insert acclIListToInsert;
    ///// Store categories
    List<ER_DependentValue__c> listCategoriesToCreate = new List<ER_DependentValue__c>();

    ER_DependentValue__c categoryParent1 = new ER_DependentValue__c();
    categoryParent1.Name = 'Parent1';
    categoryParent1.ER_Status__c = 'Active';
    categoryParent1.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;

    ER_DependentValue__c categoryParent2 = new ER_DependentValue__c();
    categoryParent2.Name = 'Parent2';
    categoryParent2.ER_Status__c = 'Active';
    categoryParent2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;

    listCategoriesToCreate.add(categoryParent1);
    listCategoriesToCreate.add(categoryParent2);

    Database.insert(listCategoriesToCreate, true);
    System.assert(categoryParent1.Id != null);

    listCategoriesToCreate = new List<ER_DependentValue__c>();

    ER_DependentValue__c categoryChild = new ER_DependentValue__c();
    categoryChild.Name = 'Child1';
    categoryChild.Parent_Dependent_Value__c = categoryParent1.Id;
    categoryChild.ER_Ordering__c = 2;
    categoryChild.ER_Status__c = 'Active';
    categoryChild.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    listCategoriesToCreate.add(categoryChild);

    ER_DependentValue__c categoryChild2 = new ER_DependentValue__c();
    categoryChild2.Name = 'Child2';
    categoryChild2.Parent_Dependent_Value__c = categoryParent2.Id;
    categoryChild2.ER_Status__c = 'Active';
    categoryChild2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    listCategoriesToCreate.add(categoryChild2);
    insert listCategoriesToCreate;

    ER_StoreCategory__c strCategory = new ER_StoreCategory__c(Store__c = testStore.Id, Category__c = categoryChild.Id);
    insert strCategory;
  }

  @IsTest
  static void syncContractTest() {
    Set<Id> accountIds = new Set<Id>();
    Set<Id> contractIds = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    //String bodySync;
    Account merchantAccount = [SELECT Id FROM Account WHERE Name = 'ER_SyncStructureWithLegacy_Test'];
    accountIds.add(merchantAccount.Id);
    Contract contract = [SELECT Id FROM Contract ORDER BY CreatedDate DESC LIMIT 1];
    contractIds.add(contract.Id);
    //bodySync = ER_SyncStructureWithLegacy.syncContract(accountIds,null, null);
    Test.startTest();
    ER_SyncEDGMock edgMock = new ER_SyncEDGMock();
    Test.setMock(HttpCalloutMock.class, edgMock);
    //ER_SyncStructureWithLegacy.syncContract(accountIds,null, null);
    System.enqueueJob(new ER_SyncStructureWS(accountIds, contractIds, 'POST', ModifiedElements, accountsInputScope));
    Test.stopTest();
  }
}