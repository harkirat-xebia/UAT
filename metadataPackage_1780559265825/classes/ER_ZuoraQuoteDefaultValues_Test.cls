/*
----------------------------------------------------------------------
-- - Name          : ER_ZuoraQuoteDefaultValues
-- - Author        : AAZ
-- - Description   : Test class for ER_ZuoraQuoteDefaultValues     
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JUNE-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
@isTest
public class ER_ZuoraQuoteDefaultValues_Test {
  @testSetup
  static void testSetup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testnewZuoraQuote');
    insert newMerchantAccount;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'Opp testnewZuoraQuote'
    );
    newOpportunity.AccountId = newMerchantAccount.Id;
    newOpportunity.ER_Reason__c = 'New';
    newOpportunity.ER_Contract_Expected_Start_Date__c = Date.today();
    insert newOpportunity;

    Zuora__CustomerAccount__c newBA = new Zuora__CustomerAccount__c();
    newBA.Name = 'A00000001';
    newBA.Zuora__Account__c = newMerchantAccount.Id;
    newBA.Zuora__Status__c = 'Active';
    newBA.Zuora__PaymentTerm__c = '14 days';
    newBA.Zuora__AccountNumber__c = 'A00000001';
    newBA.Zuora__DefaultPaymentMethod__c = 'WireTransfer';
    insert newBA;

    zqu__Quote__c newZQuote = APER07_UtilityTestMethod.getZuoraQuote('Default');
    newZQuote.zqu__Account__c = newMerchantAccount.Id;
    newZQuote.zqu__Opportunity__c = newOpportunity.Id;
    newZQuote.zqu__Currency__c = 'PLN';
    newZQuote.zqu__startdate__c = Date.today();
    newZQuote.zqu__Zuora_Account_Number__c = 'A00000001';
    insert newZQuote;

    Contact conct = new Contact();
    conct.MailingCountry = 'Poland';
    conct.AccountId = newMerchantAccount.Id;
    conct.LastName = 'bilTto';
    conct.FirstName = 'contact';
    conct.Email = 'bilTto.contact@zuora.com';
    insert conct;
  }

  static testMethod void testZQuoteDefaultValues() {
    zqu__Quote__c newZQuote = [
      SELECT Id, zqu__Account__c, zqu__Opportunity__c, zqu__ValidUntil__c, zqu__Zuora_Account_Number__c
      FROM zqu__Quote__c
      LIMIT 1
    ];
    Opportunity newOpp = [SELECT Id FROM Opportunity LIMIT 1];

    ER_ZuoraQuoteDefaultValues controller = new ER_ZuoraQuoteDefaultValues();
    PageReference createQuote = Page.zqu__CreateQuote;
    createQuote.getParameters().put('oppId', newOpp.Id);
    createQuote.getParameters().put('quoteType', 'Subscription');
    createQuote.getParameters().put('stepNumber', '2');
    Test.setCurrentPage(createQuote);

    Test.startTest();
    controller.populateDefaultFieldValue(newZQuote, new zqu.PropertyComponentController.ParentController());
    System.debug('>>>>> AAZ - testZQuoteDefaultValues: ' + newZQuote.zqu__ValidUntil__c);
    System.assertEquals(Date.today().addDays(30), newZQuote.zqu__ValidUntil__c);
    Test.stopTest();
  }
}