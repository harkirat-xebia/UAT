@isTest
public class VFCSK02_Proposal_PDF_Test {
    
    
    @testSetup
    static void testSetup(){
        
        Account merchantAccount = APER07_UtilityTestMethod.getCompany('VFCSK02_Proposal_PDF_Test');
        merchantAccount.BillingStreet='Test';
        merchantAccount.BillingPostalCode='Test';
        merchantAccount.BillingCity='Test';
        merchantAccount.ER_VAT_Number__c = '134567677';
        insert merchantAccount;
        
        Contact contactTest = new Contact(
            Email = 'test@test.com',
            FirstName = 'firstName' ,
            LastName = 'lastName' ,
            recordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ER_Contact_RT').getRecordTypeId(),
            AccountId  =merchantAccount.Id
        );
        insert contactTest;
        
        PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
        //update newPriceBook;
        
        Product2 newSolution = APER07_UtilityTestMethod.getsolution('testsolution');
        insert newSolution;
        
        //Pour chaque  service  (TRV, HC, TR, TC, TM)
        List<Product2> newServices = new List<Product2>();
        
        Product2 newServiceTRV0 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTRV0.productCode = 'ERSK_TRV_001';
        newServices.add(newServiceTRV0);
        Product2 newServiceTRV1 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTRV1.productCode = 'ERSK_TRV_003';
        newServices.add(newServiceTRV1);
        Product2 newServiceTRV2 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTRV2.productCode = 'ERSK_TRV_005';
        newServices.add(newServiceTRV2);
        Product2 newServiceTRV3 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTRV3.productCode = 'ERSK_TRV_010';
        newServices.add(newServiceTRV3);
        
        Product2 newServiceHC1 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceHC1.productCode = 'ERSK_HC_001';
        newServices.add(newServiceHC1);
        Product2 newServiceHC2 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceHC2.productCode = 'ERSK_HC_009';
        newServices.add(newServiceHC2);
        Product2 newServiceHC3 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceHC3.productCode = 'ERSK_HC_005';
        newServices.add(newServiceHC3);
        Product2 newServiceHC4 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceHC4.productCode = 'ERSK_HC_010';
        newServices.add(newServiceHC4);
        Product2 newServiceHC5 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceHC5.productCode = 'ERSK_HC_002';
        newServices.add(newServiceHC5);
        Product2 newServiceHC6 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceHC6.productCode = 'ERSK_HC_013';
        newServices.add(newServiceHC6);
        
        Product2 newServiceTR1 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTR1.productCode = 'ERSK_TR_001';
        newServices.add(newServiceTR1);
        Product2 newServiceTR2 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTR2.productCode = 'ERSK_TR_004';
        newServices.add(newServiceTR2);
        Product2 newServiceTR3 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTR3.productCode = 'ERSK_TR_008';
        newServices.add(newServiceTR3);
        Product2 newServiceTR4 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTR4.productCode = 'ERSK_TR_010';
        newServices.add(newServiceTR4);
        Product2 newServiceTR5 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTR5.productCode = 'ERSK_TR_015';
        newServices.add(newServiceTR5);
        Product2 newServiceTR6 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTR6.productCode = 'ERSK_TR_002';
        newServices.add(newServiceTR6);
        Product2 newServiceTR7 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTR7.productCode = 'ERSK_TR_013';
        newServices.add(newServiceTR7);
        
        Product2 newServiceTC1 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC1.productCode = 'ERSK_TC_001';
        newServices.add(newServiceTC1);
        Product2 newServiceTC2 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC2.productCode = 'ERSK_TC_005';
        newServices.add(newServiceTC2);
        Product2 newServiceTC3 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC3.productCode = 'ERSK_TC_014';
        newServices.add(newServiceTC3);
        Product2 newServiceTC4 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC4.productCode = 'ERSK_TC_008';
        newServices.add(newServiceTC4);
        Product2 newServiceTC5 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC5.productCode = 'ERSK_TC_003';
        newServices.add(newServiceTC5);
        Product2 newServiceTC6 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC6.productCode = 'ERSK_TC_016';
        newServices.add(newServiceTC6);
        Product2 newServiceTC7 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC7.productCode = 'ERSK_TC_018';
        newServices.add(newServiceTC7);
        Product2 newServiceTC8 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC8.productCode = 'ERSK_TC_017';
        newServices.add(newServiceTC8);
        Product2 newServiceTC9 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTC9.productCode = 'ERSK_TC_019';
        newServices.add(newServiceTC9);
        
        Product2 newServiceTM1 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM1.productCode = 'ERSK_TM_001';
        newServices.add(newServiceTM1);
        Product2 newServiceTM2 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM2.productCode = 'ERSK_TM_003';
        newServices.add(newServiceTM2);
        Product2 newServiceTM3 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM3.productCode = 'ERSK_TM_014';
        newServices.add(newServiceTM3);
        Product2 newServiceTM4 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM4.productCode = 'ERSK_TM_019';
        newServices.add(newServiceTM4);
        Product2 newServiceTM5 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM5.productCode = 'ERSK_TM_005';
        newServices.add(newServiceTM5);
        Product2 newServiceTM6 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM6.productCode = 'ERSK_TM_009';
        newServices.add(newServiceTM6);
        Product2 newServiceTM7 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM7.productCode = 'ERSK_TM_016';
        newServices.add(newServiceTM7);
        Product2 newServiceTM8 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceTM8.productCode = 'ERSK_TM_018';
        newServices.add(newServiceTM8);

        // COUL-2322
        Product2 newServiceEB1 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceEB1.productCode = 'ERSK_EB_001';
        newServices.add(newServiceEB1);
        Product2 newServiceEB2 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceEB2.productCode = 'ERSK_EB_009';
        newServices.add(newServiceEB2);
        Product2 newServiceEB3 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceEB3.productCode = 'ERSK_EB_005';
        newServices.add(newServiceEB3);
        Product2 newServiceEB4 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceEB4.productCode = 'ERSK_EB_010';
        newServices.add(newServiceEB4);
        Product2 newServiceEB5 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceEB5.productCode = 'ERSK_EB_002';
        newServices.add(newServiceEB5);
        Product2 newServiceEB6 = APER07_UtilityTestMethod.getservice('testService',newSolution.id);
        newServiceEB6.productCode = 'ERSK_EB_013';
        newServices.add(newServiceEB6);
        // COUL-2322
        
        insert newServices;
        
        //Pour chaque PriceBook (TRV, HC, TR, TC, TM)
        List<PriceBookEntry> newPriceBookEntrys = new List<PriceBookEntry>();
        
        PriceBookEntry newPriceBookEntryTRV0 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTRV0.id);
        newPriceBookEntrys.add(newPriceBookEntryTRV0);
        PriceBookEntry newPriceBookEntryTRV1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTRV1.id);
        newPriceBookEntrys.add(newPriceBookEntryTRV1);
        PriceBookEntry newPriceBookEntryTRV2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTRV2.id);
        newPriceBookEntrys.add(newPriceBookEntryTRV2);
        PriceBookEntry newPriceBookEntryTRV3 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTRV3.id);
        newPriceBookEntrys.add(newPriceBookEntryTRV3);
        
        PriceBookEntry newPriceBookEntryHC1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceHC1.id);
        newPriceBookEntrys.add(newPriceBookEntryHC1);
        PriceBookEntry newPriceBookEntryHC2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceHC2.id);
        newPriceBookEntrys.add(newPriceBookEntryHC2);
        PriceBookEntry newPriceBookEntryHC3 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceHC3.id);
        newPriceBookEntrys.add(newPriceBookEntryHC3);
        PriceBookEntry newPriceBookEntryHC4 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceHC4.id);
        newPriceBookEntrys.add(newPriceBookEntryHC4);
        PriceBookEntry newPriceBookEntryHC5 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceHC5.id);
        newPriceBookEntrys.add(newPriceBookEntryHC5);
        PriceBookEntry newPriceBookEntryHC6 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceHC6.id);
        newPriceBookEntrys.add(newPriceBookEntryHC6);

        // COUL-2322
        PriceBookEntry newPriceBookEntryEB1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceEB1.id);
        newPriceBookEntrys.add(newPriceBookEntryEB1);
        PriceBookEntry newPriceBookEntryEB2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceEB2.id);
        newPriceBookEntrys.add(newPriceBookEntryEB2);
        PriceBookEntry newPriceBookEntryEB3 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceEB3.id);
        newPriceBookEntrys.add(newPriceBookEntryEB3);
        PriceBookEntry newPriceBookEntryEB4 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceEB4.id);
        newPriceBookEntrys.add(newPriceBookEntryEB4);
        PriceBookEntry newPriceBookEntryEB5 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceEB5.id);
        newPriceBookEntrys.add(newPriceBookEntryEB5);
        PriceBookEntry newPriceBookEntryEB6 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceEB6.id);
        newPriceBookEntrys.add(newPriceBookEntryEB6);
        // COUL-2322

        
        PriceBookEntry newPriceBookEntryTR1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTR1.id);
        newPriceBookEntrys.add(newPriceBookEntryTR1);
        PriceBookEntry newPriceBookEntryTR2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTR2.id);
        newPriceBookEntrys.add(newPriceBookEntryTR2);
        PriceBookEntry newPriceBookEntryTR3 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTR3.id);
        newPriceBookEntrys.add(newPriceBookEntryTR3);
        PriceBookEntry newPriceBookEntryTR4 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTR4.id);
        newPriceBookEntrys.add(newPriceBookEntryTR4);
        PriceBookEntry newPriceBookEntryTR5 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTR5.id);
        newPriceBookEntrys.add(newPriceBookEntryTR5);
        PriceBookEntry newPriceBookEntryTR6 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTR6.id);
        newPriceBookEntrys.add(newPriceBookEntryTR6);
        PriceBookEntry newPriceBookEntryTR7 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTR7.id);
        newPriceBookEntrys.add(newPriceBookEntryTR7);
        
        PriceBookEntry newPriceBookEntryTC1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC1.id);
        newPriceBookEntrys.add(newPriceBookEntryTC1);
        PriceBookEntry newPriceBookEntryTC2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC2.id);
        newPriceBookEntrys.add(newPriceBookEntryTC2);
        PriceBookEntry newPriceBookEntryTC3 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC3.id);
        newPriceBookEntrys.add(newPriceBookEntryTC3);
        PriceBookEntry newPriceBookEntryTC4 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC4.id);
        newPriceBookEntrys.add(newPriceBookEntryTC4);
        PriceBookEntry newPriceBookEntryTC5 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC5.id);
        newPriceBookEntrys.add(newPriceBookEntryTC5);
        PriceBookEntry newPriceBookEntryTC6 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC6.id);
        newPriceBookEntrys.add(newPriceBookEntryTC6);
        PriceBookEntry newPriceBookEntryTC7 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC7.id);
        newPriceBookEntrys.add(newPriceBookEntryTC7);
        PriceBookEntry newPriceBookEntryTC8 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC8.id);
        newPriceBookEntrys.add(newPriceBookEntryTC8);
        PriceBookEntry newPriceBookEntryTC9 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTC9.id);
        newPriceBookEntrys.add(newPriceBookEntryTC9);
        
        PriceBookEntry newPriceBookEntryTM1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM1.id);
        newPriceBookEntrys.add(newPriceBookEntryTM1);
         PriceBookEntry newPriceBookEntryTM2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM2.id);
        newPriceBookEntrys.add(newPriceBookEntryTM2);
         PriceBookEntry newPriceBookEntryTM3 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM3.id);
        newPriceBookEntrys.add(newPriceBookEntryTM3);
         PriceBookEntry newPriceBookEntryTM4 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM4.id);
        newPriceBookEntrys.add(newPriceBookEntryTM4);
         PriceBookEntry newPriceBookEntryTM5 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM5.id);
        newPriceBookEntrys.add(newPriceBookEntryTM5);
         PriceBookEntry newPriceBookEntryTM6 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM6.id);
        newPriceBookEntrys.add(newPriceBookEntryTM6);
        PriceBookEntry newPriceBookEntryTM7 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM7.id);
        newPriceBookEntrys.add(newPriceBookEntryTM7);
        PriceBookEntry newPriceBookEntryTM8 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newServiceTM8.id);
        newPriceBookEntrys.add(newPriceBookEntryTM8);
        
        
        insert newPriceBookEntrys;
        // une seule opp pour les services et solution précédents 
        Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'VFSK02_Proposal_PDF_Test');
        newOpportunity.AccountId = merchantAccount.id;
        insert newOpportunity;
        
        //une seule quote pour les services et solution précédents 
        Quote merchantQuote = APER07_UtilityTestMethod.getQuote('ER_Merchant_Quote', 'VFSK02_Proposal_PDF_Test', newOpportunity.id, newPriceBook.id);
        insert merchantQuote;
        
        //Pour tous les service (TRV, HC, TR, TC, TM)
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        QuoteLineItem qliTRV0 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTRV0.id);
        qlis.add(qliTRV0);
        QuoteLineItem qliTRV1 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTRV1.id);
        qlis.add(qliTRV1);
        QuoteLineItem qliTRV2 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTRV2.id);
        qlis.add(qliTRV2);
        QuoteLineItem qliTRV3 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTRV3.id);
        qlis.add(qliTRV3);
        
        QuoteLineItem qliHC1 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryHC4.id);
        qlis.add(qliHC1);
        QuoteLineItem qliHC2 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryHC2.id);
        qlis.add(qliHC2);
        QuoteLineItem qliHC3 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryHC3.id);
        qlis.add(qliHC3);
        QuoteLineItem qliHC4 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryHC4.id);
        qlis.add(qliHC4);
        QuoteLineItem qliHC5 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryHC5.id);
        qlis.add(qliHC5);
        QuoteLineItem qliHC6 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryHC6.id);
        qlis.add(qliHC6);

        // COUL-2322
        QuoteLineItem qliEB1 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryEB4.id);
        qlis.add(qliEB1);
        QuoteLineItem qliEB2 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryEB2.id);
        qlis.add(qliEB2);
        QuoteLineItem qliEB3 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryEB3.id);
        qlis.add(qliEB3);
        QuoteLineItem qliEB4 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryEB4.id);
        qlis.add(qliEB4);
        QuoteLineItem qliEB5 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryEB5.id);
        qlis.add(qliEB5);
        QuoteLineItem qliEB6 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryEB6.id);
        qlis.add(qliEB6);
        // COUL-2322
        
        QuoteLineItem qliTR1 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTR1.id);
        qlis.add(qliTR1);
        QuoteLineItem qliTR2 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTR2.id);
        qlis.add(qliTR2);
        QuoteLineItem qliTR3 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTR3.id);
        qlis.add(qliTR3);
        QuoteLineItem qliTR4 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTR4.id);
        qlis.add(qliTR4);
        QuoteLineItem qliTR5 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTR5.id);
        qlis.add(qliTR5);
        QuoteLineItem qliTR6 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTR6.id);
        qlis.add(qliTR6);
        QuoteLineItem qliTR7 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTR7.id);
        qlis.add(qliTR7);
        
        QuoteLineItem qliTC1 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC1.id);
        qlis.add(qliTC1);
        QuoteLineItem qliTC2 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC2.id);
        qlis.add(qliTC2);
        QuoteLineItem qliTC3 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC3.id);
        qlis.add(qliTC3);
        QuoteLineItem qliTC4 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC4.id);
        qlis.add(qliTC4);
        QuoteLineItem qliTC5 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC5.id);
        qlis.add(qliTC5);
        QuoteLineItem qliTC6 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC6.id);
        qlis.add(qliTC6);
        QuoteLineItem qliTC7 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC7.id);
        qlis.add(qliTC7);
        QuoteLineItem qliTC8 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC8.id);
        qlis.add(qliTC8);
        QuoteLineItem qliTC9 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTC9.id);
        qlis.add(qliTC9);
        
        QuoteLineItem qliTM1 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM1.id);
        qlis.add(qliTM1);
        QuoteLineItem qliTM2 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM2.id);
        qlis.add(qliTM2);
        QuoteLineItem qliTM3 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM3.id);
        qlis.add(qliTM3);
        QuoteLineItem qliTM4 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM4.id);
        qlis.add(qliTM4);
        QuoteLineItem qliTM5 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM5.id);
        qlis.add(qliTM5);
        QuoteLineItem qliTM6 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM6.id);
        qlis.add(qliTM6);
        QuoteLineItem qliTM7 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM7.id);
        qlis.add(qliTM7);
        QuoteLineItem qliTM8 = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntryTM8.id);
        qlis.add(qliTM8);
        
        
        insert qlis;

        
        //Error should insert paymentsite 'ER_Bank_Account__c'
        ER_Bank_Account__c  bankAcc = new ER_Bank_Account__c(Name ='TestBank', ER_Bank_Account_Status__c='Open', ER_IBAN__c='SK19AZER33669988774455');
        insert bankAcc;
        ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter('VFSK02_Proposal_PDF_Test',merchantAccount.id, Label.LABS_SF_FinancialCenter_Merchant,'Test','Test','Test','Test');
        testFinancialCenter.ER_Contact__c = contactTest.id;
        testFinancialCenter.ER_Bank_Account__c = bankAcc.id;
        testFinancialCenter.ER_Payment_Site__c = true;
        insert testFinancialCenter;
        
    }
    static testMethod void testController(){
        
        Test.StartTest();
        
        Quote testQuote = [select id, Name from Quote order by CreatedDate desc limit 1];
        ApexPages.currentPage().getParameters().put('id',testQuote.Id);
        VFCSK02_Proposal_PDF_SK contr = new  VFCSK02_Proposal_PDF_SK(); 
        //System.assertEquals();
        //contr.quoteId = testQuote.Id;
        //contr.VFSK02_Proposal_PDF_SK() = 'VFSK02_Proposal_PDF_SK';
        //Test.StopTest();
        
    }
}