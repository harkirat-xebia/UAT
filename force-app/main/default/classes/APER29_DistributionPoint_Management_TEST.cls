/*
----------------------------------------------------------------------
-- - Name          : APER29_DistributionPoint_Management_TEST
-- - Author        : KHAD
-- - Description   : Test class for Distribution Point Management.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- FEB-2021     KHAD                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
@isTest
public class APER29_DistributionPoint_Management_TEST {
  @testSetup
  static void testSetup() {
    User runningUser = [SELECT id, ER_Business_Unit__c FROM User WHERE id = :UserInfo.getUserId()];
    Account clientAccount = APER07_UtilityTestMethod.getCompany('APER29_DistributionPoint_Management_Test');
    insert clientAccount;

    ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
      'APER29_DistributionPoint_Management_Test',
      clientAccount.id,
      Label.LABS_SF_FinancialCenter_Client,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Client;
    insert testFinancialCenter;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

    List<Product2> solutionListToInsert = new List<Product2>();
    List<Product2> serviceListToInsert = new List<Product2>();
    List<PriceBookEntry> pbeListToInsert = new List<PriceBookEntry>();
    List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
    List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
    List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();
    List<ER_Delivery_Site__c> dsListToInsert = new List<ER_Delivery_Site__c>();
    List<ER_Solution_Line_Item__c> dsliListToInsert = new List<ER_Solution_Line_Item__c>();

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    newSolution.ProductCode = 'testSolution';
    newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    solutionListToInsert.add(newSolution);

    Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
    newSolution2.ProductCode = 'testSolution2';
    newSolution2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    solutionListToInsert.add(newSolution2);

    insert solutionListToInsert;

    Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
    newService.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    serviceListToInsert.add(newService);

    Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice2', newSolution2.id);
    newService2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    serviceListToInsert.add(newService2);

    insert serviceListToInsert;

    PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
    pbeListToInsert.add(newPriceBookEntry);

    PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
    pbeListToInsert.add(newPriceBookEntry2);

    insert pbeListToInsert;

    Contract testContract = APER07_UtilityTestMethod.getContract(
      clientAccount.id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id
    );
    testContract.recordtypeid = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
      .get('ER_Client_Contract_RT')
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
      clientAccount.Id,
      testContract.Id,
      newSolution.Id
    );
    testAccountLineItem.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
    aliListToInsert.add(testAccountLineItem);

    ER_Solution_Line_Item__c testAccountLineItem2 = APER07_UtilityTestMethod.getAccountLineItem(
      clientAccount.Id,
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

    List<Contact> contactList = new List<Contact>();

    Contact c = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test1', 'test1');
    c.AccountId = clientAccount.Id;
    c.Salutation = 'Mr';
    Contact c1 = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test2', 'test2');
    c1.AccountId = clientAccount.Id;
    c1.Salutation = 'Mr';
    contactList.add(c);
    contactList.add(c1);
    insert contactList;

    ER_Delivery_Site__c testDeliverySite = APER07_UtilityTestMethod.getDeliverySite(
      'APER29_DistributionPoint_Management_Test',
      clientAccount.id,
      testFinancialCenter.id
    );
    testDeliverySite.ER_Street__c = 'Test Street';
    testDeliverySite.ER_Zip_Code__c = '75001';
    testDeliverySite.ER_City__c = 'Paris';
    testDeliverySite.ER_Country__c = 'BE';
    dsListToInsert.add(testDeliverySite);

    ER_Delivery_Site__c testDeliverySite2 = APER07_UtilityTestMethod.getDeliverySite(
      'APER29_DistributionPoint_Management_Test2',
      clientAccount.id,
      testFinancialCenter.id
    );
    testDeliverySite2.ER_Street__c = 'Test Street 2';
    testDeliverySite2.ER_Zip_Code__c = '75002';
    testDeliverySite2.ER_City__c = 'Paris';
    testDeliverySite2.ER_Country__c = 'BE';
    dsListToInsert.add(testDeliverySite2);

    insert dsListToInsert;

    ER_Solution_Line_Item__c testDeliverySiteLineItem = APER07_UtilityTestMethod.getDeliverySiteLineItem(
      testDeliverySite.id,
      testContract.id,
      testFinancialCenterLineItem.id,
      newSolution.id
    );
    dsliListToInsert.add(testDeliverySiteLineItem);

    ER_Solution_Line_Item__c testDeliverySiteLineItem2 = APER07_UtilityTestMethod.getDeliverySiteLineItem(
      testDeliverySite2.id,
      testContract.id,
      testFinancialCenterLineItem2.id,
      newSolution2.id
    );
    dsliListToInsert.add(testDeliverySiteLineItem2);

    ER_Solution_Line_Item__c testDeliverySiteLineItem3 = APER07_UtilityTestMethod.getDeliverySiteLineItem(
      testDeliverySite.id,
      testContract.id,
      testFinancialCenterLineItem2.id,
      newSolution2.id
    );
    dsliListToInsert.add(testDeliverySiteLineItem3);

    insert dsliListToInsert;

    ER_Distribution_Point__c testDistributionPoint = APER07_UtilityTestMethod.getDistributionPoint(
      'APER29_DistributionPoint_Management_Test',
      testDeliverySite.id
    );
    testDistributionPoint.ER_Contact__c = c.Id;
    testDistributionPoint.ER_Street__c = 'Test Street';
    testDistributionPoint.ER_Zip_Code__c = '75001';
    testDistributionPoint.ER_City__c = 'Paris';
    testDistributionPoint.ER_Country__c = 'BE';
    insert testDistributionPoint;

    ER_Solution_Line_Item__c testDistributionPointLineItem = APER07_UtilityTestMethod.getDistributionPointLineItem(
      testDistributionPoint.id,
      testContract.id,
      testDeliverySiteLineItem.id,
      newSolution.id
    );
    insert testDistributionPointLineItem;

    ER_Solution_Line_Item__c testDistributionPointLineItem2 = APER07_UtilityTestMethod.getDistributionPointLineItem(
      testDistributionPoint.id,
      testContract.id,
      testDeliverySiteLineItem2.id,
      newSolution2.id
    );
    insert testDistributionPointLineItem2;
  }

  static testMethod void manageDPLIFromContract() {
    List<Contract> contractList = [
      SELECT id, AccountId, Status
      FROM Contract
      WHERE Status = :Label.LABS_SF_Contract_Status_Activated
    ];
    if (!contractList.isEmpty()) {
      APER29_DistributionPoint_Management.manageDPLIFromContract(contractList[0]);
    }
  }

  static testMethod void manageDPLIForNewDistributionPoint() {
    Map<Id, ER_Distribution_Point__c> distributionPointMap = new Map<Id, ER_Distribution_Point__c>();

    Account clientAccount = [SELECT id FROM Account WHERE Name = 'APER29_DistributionPoint_Management_Test'];
    ER_Delivery_Site__c testDeliverySite = [
      SELECT Id
      FROM ER_Delivery_Site__c
      WHERE Name = 'APER29_DistributionPoint_Management_Test'
    ];

    ER_Distribution_Point__c testDistributionPoint2 = APER07_UtilityTestMethod.getDistributionPoint(
      'APER29_DistributionPoint_Management_Test3',
      testDeliverySite.id
    );
    testDistributionPoint2.ER_Street__c = 'Test Street 3';
    testDistributionPoint2.ER_Zip_Code__c = '75003';
    testDistributionPoint2.ER_City__c = 'Paris';
    testDistributionPoint2.ER_Country__c = 'BE';
    insert testDistributionPoint2;

    distributionPointMap.put(testDistributionPoint2.Id, testDistributionPoint2);

    APER29_DistributionPoint_Management.manageDPLIForNewDistributionPoint(distributionPointMap);
  }

  static testMethod void updatePrimaryContactRole() {
    Map<Id, ER_Distribution_Point__c> distributionPointNewMap = new Map<Id, ER_Distribution_Point__c>();
    Map<Id, ER_Distribution_Point__c> distributionPointOldMap = new Map<Id, ER_Distribution_Point__c>();
    ER_Distribution_Point__c dp = [SELECT id, ER_Contact__c FROM ER_Distribution_Point__c LIMIT 1];
    Contact c = [SELECT id FROM Contact WHERE FirstName = 'test2' LIMIT 1];
    distributionPointNewMap.put(dp.Id, dp);
    dp.ER_Contact__c = c.Id;
    update dp;
    distributionPointOldMap.put(dp.Id, dp);

    Test.startTest();
    APER29_DistributionPoint_Management.updatePrimaryContactRole(distributionPointNewMap, distributionPointOldMap);
    Test.stopTest();
  }

  @IsTest
  static void updateDistributionPointLineItemsForAccount() {
    String accId = [SELECT Id FROM Account LIMIT 1].Id;
    String contractId = [SELECT Id FROM Contract LIMIT 1].Id;

    String solution2 = [SELECT ProductCode FROM Product2 LIMIT 3][1].ProductCode;
    String solution3 = [SELECT ProductCode FROM Product2 LIMIT 3][2].ProductCode;

    Set<String> solutions = new Set<String>();
    solutions.add(solution2);
    solutions.add(solution3);

    Test.startTest();
    GenericWithoutSharing.updateDistributionPointLineItemsForAccount(solutions, contractId, accId, 'Activated');
    Test.stopTest();
  }
}