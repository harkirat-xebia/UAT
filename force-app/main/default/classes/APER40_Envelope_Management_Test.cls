/*
----------------------------------------------------------------------
-- - Name          : APER40_Envelope_Management_Test
-- - Author        : Snica
-- - Description   : Test class for APER40_Envelope_Management
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Aug-2022     snica               1.0         Initial version.
---------------------------------------------------------------------------------------
*/
@isTest
public class APER40_Envelope_Management_Test {
  @testSetup
  static void testSetup() {
    User runningUser = [SELECT id, ER_Business_Unit__c, ER_BUText__c FROM User WHERE id = :UserInfo.getUserId()];
    Lead lead = APER07_UtilityTestMethod.getLead(
      Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
    );
    insert lead;
    Case testCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
    testCase.ownerId = runningUser.Id;
    insert testCase;
    Account newMerchantAccount = APER07_UtilityTestMethod.insertAccount(
      'APHU12_Contract_Management_Test',
      'ER_Company_Account_RT'
    );
    PriceBook2 stdPriceBook = APER07_UtilityTestMethod.getpriceBook();
    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('Pricebook');
    insert newPriceBook;
    Product2 newSolution = APER07_UtilityTestMethod.insertProduct2(
      'testSolution',
      runningUser.ER_Business_Unit__c,
      null,
      'Solution',
      null
    );
    Product2 newService = APER07_UtilityTestMethod.insertProduct2(
      'testService',
      runningUser.ER_Business_Unit__c,
      null,
      'service',
      newSolution.Id
    );
    PricebookEntry standardPrice = APER07_UtilityTestMethod.getpriceBookEntry(stdPriceBook.id, newService.id);
    insert standardPrice;
    PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
    insert newPriceBookEntry;
    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'APHU12_Contract_Management_Test'
    );
    newOpportunity.AccountId = newMerchantAccount.Id;
    insert newOpportunity;

    Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
      'ER_Merchant_Quote',
      'APHU12_Contract_Management_Test',
      newOpportunity.id,
      newPriceBook.Id
    );
    insert merchantQuote;
    Contract newContract = APER07_UtilityTestMethod.insertContract(
      newMerchantAccount.Id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id,
      'ER_Merchant_Contract_RT',
      runningUser.Id
    );
  }
  static testMethod void fillSignatureInformationTest() {
    String qteId = [SELECT Id FROM Quote LIMIT 1].Id;
    String crtId = [SELECT Id FROM Contract LIMIT 1].Id;
    Contract crt = [
      SELECT
        Id,
        ER_QuoteId__c,
        CustomerSignedId,
        CustomerSignedTitle,
        CustomerSignedDate,
        CompanySignedId,
        CompanySignedDate
      FROM Contract
      LIMIT 1
    ];
    crt.ER_QuoteId__c = qteId;
    update crt;

    Quote qte = [SELECT ContractId, ContactId, Contact.Title, Id FROM Quote WHERE Id = :qteId];
    qte.ContractId = crtId;
    update qte;

    dfsle__EnvelopeStatus__c newEnv = new dfsle__EnvelopeStatus__c();
    newEnv.dfsle__EmailSubject__c = 'Email';
    insert newEnv;

    dfsle__EnvelopeStatus__c env = [SELECT Id, dfsle__SourceId__c FROM dfsle__EnvelopeStatus__c LIMIT 1];
    env.dfsle__Status__c = 'Completed';
    update env;
  }
}