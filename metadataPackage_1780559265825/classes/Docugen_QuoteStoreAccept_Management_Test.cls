/**
 * @author : AAZ
 * @date : 13/03/2022
 * @desc : Docugen_QuoteStoreAccept_Management_Test
 * @see Docugen_QuoteStoreAcceptor_Management
 */

 @IsTest
 public class Docugen_QuoteStoreAccept_Management_Test {
   @testSetup
   static void testSetup() {
     User ur = TestDataFactory.newUser('Docugen', 'Docugen', 'Local Admin', 'BELUX', 'BENELUX');
     ur.ER_BypassVR__c = true;
     insert ur;
     System.runAs(ur) {
       Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany');
       insert newMerchantAccount;
 
       ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
         'Docugen_QuoteStoreAccept_Management_Test',
         newMerchantAccount.id,
         Label.LABS_SF_FinancialCenter_Merchant,
         'Test',
         'Test',
         'Test',
         'Test'
       );
       testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
       insert testFinancialCenter;
 
       PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();
       //update standardPriceBook;
 
       PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('ERBE MERCHANT');
       insert newPriceBook;
 
       Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER11', 'APER11');
       newContact.ER_Language__c = 'FR';
       insert newContact;
 
       Contract con = APER07_UtilityTestMethod.getContract(
         newMerchantAccount.Id,
         System.today(),
         'Draft',
         newPriceBook.Id
       );
       insert con;
 
       Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
         'ER_Merchant_Opportunity',
         'APER11_Quote_Management_Test'
       );
       newOpportunity.AccountId = newMerchantAccount.Id;
       newOpportunity.ContractId = con.Id;
       newOpportunity.Pricebook2Id = newPriceBook.Id;
       insert newOpportunity;
 
       Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
         'ER_Merchant_Quote',
         'APER11_Quote_Management_Test',
         newOpportunity.id,
         newPriceBook.id
       );
       merchantQuote.ContactId = newContact.Id;
       insert merchantQuote;
 
       ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
         'Docugen_QuoteStoreAccept_Management_Test',
         newMerchantAccount.id,
         testFinancialCenter.id,
         Date.today(),
         'Test',
         'Test',
         'Test',
         'Test'
       );
       insert testStore;
 
       ER_Docugen_Quote_Store_Acceptor__c qsa = new ER_Docugen_Quote_Store_Acceptor__c();
       //qsa.ER_Financial_Center__c = testFinancialCenter.Id;
       qsa.ER_Quote__c = merchantQuote.Id;
       qsa.ER_Store__c = testStore.Id;
       insert qsa;
     }
   }
 
   @IsTest
   static void testUpdateQuoteNbOfStores_insert() {
     User u = [SELECT Id FROM User WHERE LastName = 'Docugen'];
     System.runAs(u) {
       Test.startTest();
       ER_Docugen_Quote_Store_Acceptor__c qsa = new ER_Docugen_Quote_Store_Acceptor__c();
       //qsa.ER_Financial_Center__c = [SELECT Id FROM ER_Financial_Center__c LIMIT 1].Id;
       qsa.ER_Quote__c = [SELECT Id FROM Quote LIMIT 1].Id;
       qsa.ER_Store__c = [SELECT Id FROM ER_Store__c LIMIT 1].Id;
       insert qsa;
       Test.stopTest();
     }
   }
 
   @IsTest
   static void testUpdateQuoteNbOfStores_delete() {
     User u = [SELECT Id FROM User WHERE LastName = 'Docugen'];
 
     System.runAs(u) {
       Test.startTest();
       ER_Docugen_Quote_Store_Acceptor__c qsa = [
         SELECT Id, ER_Quote__c, ER_Store__c
         FROM ER_Docugen_Quote_Store_Acceptor__c
         LIMIT 1
       ];
       System.debug('#####AAZ Docugen_QuoteStoreAccept_Management_Test qsa:' + qsa);
       delete qsa;
       Test.stopTest();
     }
   }
 
   @IsTest
   static void increaseCoverage() {
     ER_Docugen_Quote_Store_Acceptor__c qsa = [
       SELECT Id, ER_Quote__c, ER_Store__c
       FROM ER_Docugen_Quote_Store_Acceptor__c
       LIMIT 1
     ];
     qsa.ER_Acceptor__c = null;
     update qsa;
     delete qsa;
     undelete qsa;
   }
 }