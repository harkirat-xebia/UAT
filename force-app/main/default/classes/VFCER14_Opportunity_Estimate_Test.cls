/*
----------------------------------------------------------------------
-- - Name          : VFCER14_Opportunity_Estimate_Test
-- - Author        : Noor
-- - Description   : test class of VFCER14_Opportunity_Estimate_Test
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  02/06/2022       Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public with sharing class VFCER14_Opportunity_Estimate_Test {
  @testSetup
  static void testSetup() {
    Account acc = APER07_UtilityTestMethod.getCompany('ER_Merchant_Account');
    insert acc;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'VFCER04_Opportunity_Product_Test'
    );
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
      SELECT id, ER_Approved__c, ER_NeedApproval__c
      FROM Opportunity
      WHERE name = 'VFCER04_Opportunity_Product_Test'
      LIMIT 1
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
    VFCER14_Opportunity_Estimate controller = new VFCER14_Opportunity_Estimate(sc);

    controller.saveItems();
  }
}