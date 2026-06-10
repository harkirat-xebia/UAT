/*
----------------------------------------------------------------------
-- - Name          : VFCHU01_Contract_PDF_Test
-- - Author        : OLA
-- - Description   : test class of VFCHU01_Contract_PDF
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Apr-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class VFCHU01_Contract_PDF_Test {
  @testSetup
  static void testSetup() {
    Account merchantAccount = APER07_UtilityTestMethod.getCompany('VFCHU01_Contract_PDF_Test');
    merchantAccount.BillingStreet = 'Test';
    merchantAccount.BillingPostalCode = 'Test';
    merchantAccount.BillingCity = 'Test';
    insert merchantAccount;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
    //update newPriceBook;

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    insert newSolution;

    Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
    newService.productCode = 'FixedFee';
    insert newService;

    PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
    insert newPriceBookEntry;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'VFCHU01_Contract_PDF_Test'
    );
    newOpportunity.AccountId = merchantAccount.id;
    insert newOpportunity;

    Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
      'ER_Merchant_Quote',
      'VFCHU01_Contract_PDF_Test',
      newOpportunity.id,
      newPriceBook.id
    );
    insert merchantQuote;

    QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
    insert qli;

    Contact contactTest = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'Test', 'Test');
    contactTest.AccountId = merchantAccount.Id;
    insert contactTest;

    merchantQuote.contactid = contactTest.id;
    update merchantQuote;

    merchantAccount.HU_HQ_Contact__c = contactTest.id;
    update merchantAccount;

    ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
      'VFCHU01_Contract_PDF_Test',
      merchantAccount.id,
      Label.LABS_SF_FinancialCenter_Merchant,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testFinancialCenter.ER_Contact__c = contactTest.id;
    insert testFinancialCenter;
  }

  static testMethod void testController() {
    Quote testQuote = [SELECT id, Name FROM Quote WHERE name = 'VFCHU01_Contract_PDF_Test' LIMIT 1];
    ApexPages.currentPage().getParameters().put('id', testQuote.Id);
    VFCHU01_Contract_PDF controller = new VFCHU01_Contract_PDF();
  }
}