/*
----------------------------------------------------------------------
-- - Name          : VFCER04_Opportunity_Product_Test
-- - Author        : OLA
-- - Description   : test class of VFCER04_Opportunity_Product
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Dec-2018       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class VFCER04_Opportunity_Product_Test {
  static VFCER04_Opportunity_Product controller;

  @testSetup
  static void testSetup() {
    Account acc = APER07_UtilityTestMethod.getCompany('ER_Merchant_Account');
    insert acc;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'VFCER04_Opportunity_Product_Test'
    );
    newOpportunity.Commercial_Origin__c = 'Greenfield';
    newOpportunity.ER_Contract_Expected_Start_Date__c = Date.today().addDays(20);
    insert newOpportunity;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
    //update newPriceBook;
    System.debug('newPriceBook: ' + newPriceBook);
    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    insert newSolution;

    Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
    insert newService;

    PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
    insert newPriceBookEntry;

    OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
      newOpportunity.id,
      newPriceBookEntry.id
    );
    insert newOpportunityProduct;
  }

  static testMethod void test() {
    Opportunity testOpp = [
      SELECT id, ER_Approved__c, ER_NeedApproval__c,Derieved_from_Framework_Opp__c
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
    controller = new VFCER04_Opportunity_Product(sc);
  }

  static testMethod void checkExistingContract() {
    List<OpportunityLineItem> testOpp = [
      SELECT id, ProductCode, OpportunityId, Opportunity.Type
      FROM OpportunityLineItem
    ];
    Account acc = [SELECT id FROM Account WHERE Name = 'ER_Merchant_Account'];
    //checkExistingContract(solutionMap, accountId, aOpportunityId, contractType);
    //VFCER05_Opportunity_EditPrice.checkExistingContract(solutionMap, accountId, aOpportunityId, contractType);
    //VFCER04_Opportunity_Product.checkExistingContract(acc.Id, testOpp);

  }

  static testMethod void testEditPrice() {
    Opportunity testOpp = [
      SELECT id, ER_Approved__c, ER_NeedApproval__c,Derieved_from_Framework_Opp__c
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
    controller = new VFCER04_Opportunity_Product(sc);
    controller.EditPrice();
  }

  static testMethod void testGetOpportunityProducts() {
    Opportunity testOpp = [
      SELECT id, ER_Approved__c, ER_NeedApproval__c
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
    VFCER04_Opportunity_Product.getOpportunityProducts(testOpp.id);
  }

  static testMethod void testSaveAsQuote() {
    Opportunity testOpp = [
      SELECT id, ER_Approved__c, ER_NeedApproval__c, ER_Need_Financial_Approval_2__c, AccountId
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
      
      // new - Create Primary Contact
    Contact testContact = new Contact(
        FirstName = 'Test',
        LastName = 'Primary Contact',
        Email = 'testprimary@test.com',
        AccountId = testOpp.AccountId
    );
    insert testContact;
    
    OpportunityContactRole ocr = new OpportunityContactRole(
        OpportunityId = testOpp.Id,
        ContactId = testContact.Id,
        Role = 'Primary contact',
        IsPrimary = true
    );
    insert ocr;
    // END OF NEW CODE
    VFCER04_Opportunity_Product.saveAsQuote(testOpp.id);
  }

  static testMethod void testSaveAsQuoteForCZ() {
    Opportunity testOpp = [
      SELECT id, ER_Approved__c, ER_NeedApproval__c, AccountId
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
      
      // new - Create Primary Contact BEFORE updating opportunity
    Contact testContact = new Contact(
        FirstName = 'Test',
        LastName = 'Primary Contact',
        Email = 'testprimary@test.com',
        AccountId = testOpp.AccountId
    );
    insert testContact;
    
    OpportunityContactRole ocr = new OpportunityContactRole(
        OpportunityId = testOpp.Id,
        ContactId = testContact.Id,
        Role = 'Primary contact',
        IsPrimary = true
    );
    insert ocr;
    // END OF NEW CODE
    testOpp.ER_BUPicklist__c = 'CZ';
    testOpp.ER_PaymentTerms__c = '7 days after invoice issuance';
    testOpp.ER_ReimbursementTerm__c = '4 days';
    testOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('ER_Merchant_Opportunity')
      .getRecordTypeId();
    update testOpp;
    Test.startTest();
    try {
      VFCER04_Opportunity_Product.saveAsQuote(testOpp.id);
    } catch (Exception ex) {
      Boolean expectedExceptionThrown = ex.getMessage().contains('Need Financial Approval') ? true : false;
      System.assertEquals(expectedExceptionThrown, true);
    }
    Test.stopTest();
  }

  static testMethod void testUpdateOpportunity() {
    Opportunity testOpp = [
      SELECT id, ER_Approved__c, ER_NeedApproval__c
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
    VFCER04_Opportunity_Product.updateOpportunity(testOpp.id, 'Comment TEST', true);
  }

  static testMethod void testApprovalProcess() {
    Opportunity testOpp = [
      SELECT id, ER_Approved__c, ER_NeedApproval__c
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
    testOpp.ER_Approved__c = true;
    update testOpp;
  }
}