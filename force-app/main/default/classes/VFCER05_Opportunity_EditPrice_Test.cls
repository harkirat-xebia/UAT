/*
----------------------------------------------------------------------
-- - Name          : VFCER05_Opportunity_EditPrice_Test
-- - Author        : OLA
-- - Description   : test class of VFCER05_Opportunity_EditPrice
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Dec-2018       OLA                 1.0         Initial version
--  FEB- 2021      VJOY                2.0         Added method for range
---------------------------------------------------------------------------------------
*/
@isTest
public class VFCER05_Opportunity_EditPrice_Test {
  static VFCER05_Opportunity_EditPrice controller;

  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('Garcia', 'LorcaTest', 'Local Admin', 'Spain', 'BE');
    insert ur;
    System.runAs(ur) {
      Account merchantAccount = APER07_UtilityTestMethod.getCompany('VFCER05_Opportunity_EditPrice_Test');
      insert merchantAccount;

      PriceBook2 customPB = APER07_UtilityTestMethod.getCustomPriceBook('ERES PB');
      insert customPB;

      //Solutions
      Product2 newSolution = APER07_UtilityTestMethod.insertProduct2(
        'testSolution',
        ur.ER_Business_Unit__c,
        'testSolution',
        'Solution',
        null
      );
      newSolution.ER_Service_Number_of_Ranges__c = 1;
      update newSolution;
      //Services
      Product2 newService = APER07_UtilityTestMethod.insertProduct2(
        'testService',
        ur.ER_Business_Unit__c,
        null,
        'service',
        newSolution.Id
      );
      newService.ER_Service_Number_of_Ranges__c = 2;
      update newService;
      PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
        Test.getStandardPricebookId(),
        newService.id
      );
      PriceBookEntry standardPBEntrySol = APER07_UtilityTestMethod.getpriceBookEntry(
        Test.getStandardPricebookId(),
        newSolution.id
      );
      PriceBookEntry newPriceBookEntryService = APER07_UtilityTestMethod.getpriceBookEntry(customPB.id, newService.id);
      PriceBookEntry newPriceBookEntrySolution = APER07_UtilityTestMethod.getpriceBookEntry(
        customPB.id,
        newSolution.id
      );
      List<PriceBookEntry> pbEntries = new List<PriceBookEntry>();
      pbEntries.add(standardPriceBookEntry);
      pbEntries.add(standardPBEntrySol);
      pbEntries.add(newPriceBookEntryService);
      pbEntries.add(newPriceBookEntrySolution);
      insert pbEntries;

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'VFCER05_Opportunity_EditPrice_Test'
      );
      newOpportunity.AccountId = merchantAccount.Id;
      newOpportunity.Pricebook2Id = customPB.Id;
      insert newOpportunity;

      OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
        newOpportunity.id,
        newPriceBookEntryService.id
      );
      insert newOpportunityProduct;
    }
  }

  static testMethod void testVFCER05_Opportunity_EditPrice() {
    User ur = [SELECT Id FROM User WHERE LastName = 'LorcaTest'];
    System.runAs(ur) {
      Opportunity testOpp = [SELECT id, AccountId, Pricebook2.name, Pricebook2Id FROM Opportunity LIMIT 1];
      PageReference testPage = Page.VFER05_Opportunity_EditPrice;
      Test.setCurrentPage(testPage);
      testPage.getParameters().put('Id', String.valueOf(testOpp.Id));
      ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
      VFCER05_Opportunity_EditPrice ext = new VFCER05_Opportunity_EditPrice(sc);
      System.assertEquals('ERES PB', ext.priceBookName);
    }
  }

  static testMethod void testgetServices() {
    User ur = [SELECT Id FROM User WHERE LastName = 'LorcaTest'];
    System.runAs(ur) {
      Opportunity testOpp = [SELECT id, AccountId, Pricebook2.name, Pricebook2Id FROM Opportunity LIMIT 1];
      ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
      controller = new VFCER05_Opportunity_EditPrice(sc);

      List<PricebookEntry> pbEntryList = controller.getsolutions;
      List<String> solutionsListIds = new List<String>();
      for (PricebookEntry pb : pbEntryList) {
        solutionsListIds.add(pb.product2Id);
      }
      Test.startTest();
      List<pricebookentry> services = VFCER05_Opportunity_EditPrice.getServices(
        solutionsListIds,
        testOpp.Pricebook2Id,
        testOpp.AccountId,
        false,
        null,
        'Framework Agreement',
        testOpp.Id
      );
      Test.stopTest();
      System.assertEquals(1, services.size());
      System.assertEquals('testService', services[0].Name);
    }
  }

  static testMethod void testgetRangesByServices() {
    User ur = [SELECT Id, ER_Business_Unit__c FROM User WHERE LastName = 'LorcaTest'];
    System.runAs(ur) {
      Opportunity testOpp = [SELECT id, AccountId, Pricebook2.name, Pricebook2Id FROM Opportunity LIMIT 1];
      ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
      controller = new VFCER05_Opportunity_EditPrice(sc);

      List<PricebookEntry> pbEntryList = controller.getsolutions;
      List<String> solutionsListIds = new List<String>();
      for (PricebookEntry pb : pbEntryList) {
        solutionsListIds.add(pb.product2.ER_solution__c);
      }
      String range = VFCER05_Opportunity_EditPrice.getRangesByServices(
        solutionsListIds,
        testOpp.Pricebook2Id,
        testOpp.AccountId,
        false,
        null
      );
      Map<Id, ER_Product_Dependency__c> productDependencies = VFCER05_Opportunity_EditPrice.getProductDependencies(
        ur.ER_Business_Unit__c
      );
      System.debug('zzz range: ' + range);
      System.debug('zzz productDependencies: ' + productDependencies);
    }
  }

  static testMethod void testgetdiscountByParents() {
    User ur = [SELECT Id FROM User WHERE LastName = 'LorcaTest'];
    System.runAs(ur) {
      Opportunity testOpp = [SELECT id, AccountId, Pricebook2.name, Pricebook2Id FROM Opportunity LIMIT 1];
      ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
      controller = new VFCER05_Opportunity_EditPrice(sc);

      List<PricebookEntry> pbEntryList = controller.getsolutions;
      List<String> solutionsListIds = new List<String>();
      for (PricebookEntry pb : pbEntryList) {
        solutionsListIds.add(pb.id);
      }
      VFCER05_Opportunity_EditPrice.getdiscountByParents(
        solutionsListIds,
        testOpp.Pricebook2Id,
        testOpp.AccountId,
        false,
        null,
        testOpp.Id
      );
    }
  }

  static testMethod void testsaveOpportunityProducts() {
    User ur = [SELECT Id FROM User WHERE LastName = 'LorcaTest'];
    String additionalDataJson;
    System.runAs(ur) {
      Opportunity testOpp = [SELECT id, Pricebook2.name, Pricebook2Id FROM Opportunity LIMIT 1];

      OpportunityLineItem opportunityLineItemToSave = new OpportunityLineItem();
      List<OpportunityLineItem> opportunityLineItemToSaveList = new List<OpportunityLineItem>();

      Map<String, OpportunityLineItem> opportunityLineItemMap = VFCER05_Opportunity_EditPrice.getOpportunityProduct(
        testOpp.Id
      );
      if (!opportunityLineItemMap.isEmpty()) {
        opportunityLineItemToSave.Product2Id = opportunityLineItemMap.values().get(0).Product2Id;
        opportunityLineItemToSave.UnitPrice = opportunityLineItemMap.values().get(0).UnitPrice;
        opportunityLineItemToSave.Quantity = opportunityLineItemMap.values().get(0).Quantity;
        opportunityLineItemToSave.OpportunityId = opportunityLineItemMap.values().get(0).OpportunityId;
        opportunityLineItemToSaveList.add(opportunityLineItemToSave);
      }

      VFCER05_Opportunity_EditPrice.saveOpportunityProducts(opportunityLineItemToSaveList, testOpp.Id, additionalDataJson, 1.0);
    }
  }

  static testMethod void testgetOpportunityProduct() {
    User ur = [SELECT Id FROM User WHERE LastName = 'LorcaTest'];
    System.runAs(ur) {
      Opportunity testOpp = [SELECT id, Pricebook2.name, Pricebook2Id FROM Opportunity LIMIT 1];
      VFCER05_Opportunity_EditPrice.getOpportunityProduct(testOpp.Id);
      VFCER05_Opportunity_EditPrice.getDefaultProductSelection(testOpp.Id);
    }
  }
}