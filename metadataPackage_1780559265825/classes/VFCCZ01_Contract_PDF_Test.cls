/*
----------------------------------------------------------------------
-- - Name          : VFCCZ01_Contract_PDF_Test
-- - Author        : OLA
-- - Description   : Test Class for VFCCZ01_Contract_PDF
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Sep-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class VFCCZ01_Contract_PDF_Test {
  @testSetup
  static void testSetup() {
    Account newCompanyAccount = APER07_UtilityTestMethod.getCompany('VFCCZ01_Contract_PDF_Test');
    newCompanyAccount.BillingStreet = '49 Jasovská';
    newCompanyAccount.BillingCity = 'Bratislava';
    newCompanyAccount.BillingPostalCode = '851 07';
    insert newCompanyAccount;

    Contact contact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'TEST', 'TEST');
    contact.accountId = newCompanyAccount.id;
    insert contact;

    ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
      'VFCCZ01_Contract_PDF_Test',
      newCompanyAccount.id,
      Label.LABS_SF_FinancialCenter_Merchant,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    insert testFinancialCenter;

    ER_Bank_Account__c testBankAccount = APER07_UtilityTestMethod.getBankAccount(
      testFinancialCenter.id,
      'VFCCZ01_Contract_PDF_Test',
      'Open',
      'Test',
      'Test',
      '30001019-01000006-00000000'
    );
    insert testBankAccount;

    testFinancialCenter.ER_Bank_Account__c = testBankAccount.id;
    testFinancialCenter.ER_Contact__c = contact.id;
    update testFinancialCenter;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
    //update newPriceBook;
    String pricebookId = newPriceBook.id;

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    insert newSolution;

    Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
    insert newService;

    PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
    insert newPriceBookEntry;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'VFCCZ01_Contract_PDF_Test'
    );
    newOpportunity.AccountId = newCompanyAccount.Id;
    insert newOpportunity;

    OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
      newOpportunity.id,
      newPriceBookEntry.id
    );
    insert newOpportunityProduct;

    Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
      'ER_Merchant_Quote',
      'VFCCZ01_Contract_PDF_Test',
      newOpportunity.id,
      null
    );
    merchantQuote.Pricebook2Id = newPriceBook.id;
    insert merchantQuote;

    QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
    insert qli;
  }

  static testMethod void testController() {
    Quote testQuote = [SELECT id, Name FROM Quote ORDER BY CreatedDate DESC LIMIT 1];
    ApexPages.currentPage().getParameters().put('id', testQuote.Id);
    VFCCZ01_Contract_PDF controller = new VFCCZ01_Contract_PDF();
  }
}