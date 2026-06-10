/*
----------------------------------------------------------------------
-- - Name          : APER11_Quote_Management_Test
-- - Author        : OLA
-- - Description   :
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  FEB-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER11_Quote_Management_Test {
    @testSetup
    static void testSetup() {
    User ur = TestDataFactory.newUser('APER11', 'APER11', 'Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        insert ur;
        UtilsBypass.reset();
        System.runAs(ur) {
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany');
            newMerchantAccount.ER_BUPicklist__c = 'BENELUX';
            insert newMerchantAccount;

            PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();
            //update standardPriceBook;

            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('ERBE MERCHANT');
            insert newPriceBook;

            Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER11', 'APER11');
            newContact.ER_Language__c = 'FR';
            insert newContact;

            Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'ERBE_TRE-M';
      newSolution.BU_External_Reference__c = 'ERBE_TRE-M';
            insert newSolution;

            Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
            insert newService;

      PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
        standardPriceBook.id,
        newService.id
      );
            insert standardPriceBookEntry;

            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
            insert newPriceBookEntry;

      Contract con = APER07_UtilityTestMethod.getContract(
        newMerchantAccount.Id,
        System.today(),
        'Draft',
        newPriceBook.Id
      );
            insert con;
            
            Pricebook2 pricebook5 = new Pricebook2();
            pricebook5.Name = 'ERBE Merchant EKIVITA';
            pricebook5.ER_Business_Unit__c = 'BENELUX';
            pricebook5.isActive = true;
            insert pricebook5;
            System.assert(pricebook5.Id != null);

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'APER11_Quote_Management_Test'
      );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ContractId = con.Id;
            newOpportunity.Pricebook2Id = newPriceBook.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            insert newOpportunity;

      OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
        newOpportunity.id,
        newPriceBookEntry.id
      );
            insert newOpportunityProduct;

      Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
        'ER_Merchant_Quote',
        'APER11_Quote_Management_Test',
        newOpportunity.id,
        newPriceBook.id
      );
            merchantQuote.ContactId = newContact.Id;
            merchantQuote.ER_Main_Solution__c = newSolution.Id;
            //merchantQuote.ER_Business_Unit__c = 'BENELUX';
            insert merchantQuote;

            QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
            insert qli;
        }
    }
    
    static testMethod void testSendPDF() {
    List<Quote> quoteList = [SELECT id FROM Quote];
        
        if (!quoteList.isEmpty()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String emailAddress = 'JustFotTest@edennred.com';
            String[] toAddresses = emailAddress.split(';');
      mail.setToAddresses(toAddresses);
            mail.setPlainTextBody('');
            mail.setWhatId(quoteList[0].Id);
            mail.setSaveAsActivity(true);
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }

    static testMethod void testCreatedSyncQuote() {
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE LastName = 'APER11'];

        System.runAs(ur) {
      List<Opportunity> opportunities = [
        SELECT ER_InvoicingFrequency__c, ERBE_Weekly_Frequence__c, id
        FROM Opportunity
      ];
      System.debug('NGO List opportunities : ' + opportunities);
            for (Opportunity opp : opportunities) {
                opp.ER_Approved__c = true;
            }

            update opportunities;
        }
        Test.stopTest();
    }

    /*static testMethod void testAcceptedQuote() {
        User ur = [SELECT Id FROM User WHERE LastName = 'APER11'];

        System.runAs(ur) {
      List<Quote> quoteList = [SELECT id FROM Quote];
            for (Quote myQuote : quoteList) {
                myQuote.Status = Label.LABS_SF_Quote_Status_Accepted;
            }
			System.debug('SOQL Count before: ' + Limits.getQueries());

            update quoteList;
        }
    }*/

    static testMethod void testDeniedQuote() {
        User ur = [SELECT Id FROM User WHERE LastName = 'APER11'];

        System.runAs(ur) {
      List<Quote> quoteList = [SELECT id FROM Quote];
            /*for (Quote myQuote : quoteList) {
                myQuote.Status = Label.LABS_SF_Quote_Status_Accepted;
            }

            update quoteList;*/

            for (Quote myQuote : quoteList) {
                myQuote.Status = Label.LABS_SF_Quote_Status_Denied;
            }

            update quoteList;
        }
    }

    static testMethod void testSetWebOffer() {
        User ur = [SELECT Id FROM User WHERE LastName = 'APER11'];

        System.runAs(ur) {
        List<Quote> quoteList = [SELECT id FROM Quote];
            if(!quoteList.isEmpty()){
                APER11_Quote_Management.setWebOffer(quoteList[0].Id);
            }   
        }
    }

    /* static testMethod void testDocugenTemplateId() {
        User ur = [SELECT Id FROM User WHERE LastName = 'APER11'];
        System.runAs(ur) {
      List<Quote> quotes = [SELECT Id, ER_Docusign_Template__c, ContactId FROM Quote];

            System.assert(String.isNotBlank(quotes[0].ER_Docusign_Template__c));

            update new Contact(Id= quotes[0].ContactId, ER_Language__c = 'EN');
        }
    }

    static testMethod void test_FI_DocuSignTemplateId(){

        User ur = TestDataFactory.newUser('test_FI_DocuSignTemplateId', 'APER11','Local Admin', 'Finland', 'FI');
        ur.ER_BypassVR__c = true;
        insert ur;
        UtilsBypass.reset();
        System.runAs(ur) {
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('test_FI_DocuSignTemplateId');
            newMerchantAccount.ER_BUPicklist__c = 'FI';
            insert newMerchantAccount;

            PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();
            update standardPriceBook;

            PriceBook2 clientPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('ERFI_C_TOW');
            clientPriceBook.ER_MDMId__c = 'ERFI_C_TOW';
            insert clientPriceBook;

            Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER11', 'APER11');
            newContact.ER_Language__c = 'EN';
            insert newContact;

            Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
            newSolution.ProductCode = 'ERFI_C_TOW-m';
            newSolution.BU_External_Reference__c = 'ERFI_C_TOW-m';
            insert newSolution;

            Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
            insert newService;

            PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(standardPriceBook.id, newService.id);
            insert standardPriceBookEntry;

            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(clientPriceBook.id, newService.id);
            insert newPriceBookEntry;

            Contract con = APER07_UtilityTestMethod.getContract(newMerchantAccount.Id,System.today(),'Draft',clientPriceBook.Id);
            insert con;

            Test.startTest();

            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'APER11_Quote_Management_Test');
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ContractId = con.Id;
            newOpportunity.Pricebook2Id = clientPriceBook.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            insert newOpportunity;

            OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(newOpportunity.id, newPriceBookEntry.id);
            insert newOpportunityProduct;

            Quote merchantQuote = APER07_UtilityTestMethod.getQuote('ER_Merchant_Quote', 'APER11_Quote_Management_Test', newOpportunity.id, clientPriceBook.id);
            merchantQuote.ContactId = newContact.Id;
            merchantQuote.ER_Main_Solution__c = newSolution.Id;
            insert merchantQuote;

            QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
            insert qli;

            Opportunity clientOpp = APER07_UtilityTestMethod.getOpportunity('ER_Client_Opportunity_RT', 'APER11_Quote_Management_Test');
            clientOpp.AccountId = newMerchantAccount.Id;
            clientOpp.ContractId = con.Id;
            clientOpp.Type = 'Framework agreement';
            clientOpp.Pricebook2Id = clientPriceBook.Id;
            clientOpp.ER_BUPicklist__c = 'BE';
            clientOpp.Contract_End_Date__c = System.today().addDays(30);
            insert clientOpp;

            Quote clientQuote = APER07_UtilityTestMethod.getQuote('ER_Client_Quote', 'APER11_Quote_Management_Test', clientOpp.id, clientPriceBook.id);
            clientQuote.ContactId = newContact.Id;
            clientQuote.ER_Main_Solution__c = newSolution.Id;
            insert clientQuote;

            QuoteLineItem qliC = APER07_UtilityTestMethod.getQuoteLineItem(clientQuote.id, newPriceBookEntry.id);
            insert qliC;

            List<Quote> quotes = [SELECT Id, ER_Docusign_Template__c FROM Quote WHERE Id =: merchantQuote.Id];

            System.assert(String.isNotBlank(quotes[0].ER_Docusign_Template__c));

            quotes = [SELECT Id, ER_Docusign_Template__c FROM Quote WHERE Id =: clientQuote.Id];

            System.assert(String.isNotBlank(quotes[0].ER_Docusign_Template__c));
            Test.stopTest();
        }
    } */

  /* static testMethod void testDocugenTemplateIdES() {
    User ur = TestDataFactory.newUser('APER11ES', 'APER11ES', 'Local Admin', 'Spain', 'BE');
        ur.ER_BypassVR__c = true;
        insert ur;
        UtilsBypass.reset();
        Test.startTest();
        System.runAs(ur) {
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('APER11ES');
            newMerchantAccount.ER_BUPicklist__c = 'ES';
            insert newMerchantAccount;

            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('ERES MERCHANT');
            insert newPriceBook;

            Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER11', 'APER11');
            newContact.ER_Language__c = 'FR';
            insert newContact;

            Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'ERES_TRE-M';
      newSolution.BU_External_Reference__c = 'ERES_TRE-M';
            insert newSolution;

            Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
            insert newService;

      PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
        Test.getStandardPricebookId(),
        newService.id
      );
            insert standardPriceBookEntry;

            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
            insert newPriceBookEntry;

      Contract con = APER07_UtilityTestMethod.getContract(
        newMerchantAccount.Id,
        System.today(),
        'Draft',
        newPriceBook.Id
      );
            insert con;

            Pricebook2 pricebook5 = new Pricebook2();
            pricebook5.Name = 'ERES Merchant EKIVITA';
            pricebook5.ER_Business_Unit__c = 'ES';
            pricebook5.isActive = true;
            insert pricebook5;
            System.assert(pricebook5.Id != null);

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'APER11_Quote_Management_Test'
      );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ContractId = con.Id;
            newOpportunity.Pricebook2Id = newPriceBook.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            insert newOpportunity;

      OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
        newOpportunity.id,
        newPriceBookEntry.id
      );
            insert newOpportunityProduct;

      Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
        'ER_Merchant_Quote',
        'APER11_Quote_Management_Test',
        newOpportunity.id,
        newPriceBook.id
      );
            merchantQuote.ContactId = newContact.Id;
            merchantQuote.ER_Main_Solution__c = newSolution.Id;

            insert merchantQuote;

            QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
            insert qli;

            List<Quote> quotes = [SELECT Id, ER_Docusign_Template__c FROM Quote WHERE ER_Business_Unit__c = 'ES'];

            System.assert(String.isNotBlank(quotes[0].ER_Docusign_Template__c));
        }
        Test.stopTest();
  } */
    static testMethod void testDocugenTemplateDefaultLanguage() {
    User ur = TestDataFactory.newUser('APER11', 'APER11', 'Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        insert ur;
        UtilsBypass.reset();
        System.runAs(ur) {
            Test.startTest();
            //Account newMerchantAccount = [SELECT Id FROM Account LIMIT 1/*WHERE Name = 'testCompany'*/];
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany333');
            newMerchantAccount.ER_BUPicklist__c = 'BENELUX';
            insert newMerchantAccount;

            PriceBook2 newPriceBook = [SELECT Id FROM Pricebook2 WHERE Name = 'ERBE MERCHANT'];

            Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER11', 'Default');
            newContact.ER_Language__c = '';
            newContact.AccountId = newMerchantAccount.id;
            insert newContact;

            Product2 newSolution = [SELECT Id FROM Product2 WHERE ProductCode = 'ERBE_TRE-m'];

            Product2 newService = [SELECT Id FROM Product2 WHERE Name = 'testService'];

            PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();

      PriceBookEntry standardPriceBookEntry = [
        SELECT Id
        FROM PricebookEntry
        WHERE Product2Id = :newService.Id AND Pricebook2Id = :standardPriceBook.Id
      ];

      PriceBookEntry newPriceBookEntry = [
        SELECT Id
        FROM PricebookEntry
        WHERE Product2Id = :newService.Id AND Pricebook2Id = :newPriceBook.Id
      ];

      Contract con = APER07_UtilityTestMethod.getContract(
        newMerchantAccount.Id,
        System.today(),
        'Draft',
        newPriceBook.Id
      );
            insert con;

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'APER11_Quote_Management_Test2'
      );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ContractId = con.Id;
            newOpportunity.Pricebook2Id = newPriceBook.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            insert newOpportunity;

      OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
        newOpportunity.id,
        newPriceBookEntry.id
      );
            insert newOpportunityProduct;

      Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
        'ER_Merchant_Quote',
        'APER11_Quote_Management_Test',
        newOpportunity.id,
        newPriceBook.id
      );
            merchantQuote.ContactId = newContact.Id;
            merchantQuote.ER_Main_Solution__c = newSolution.Id;

            insert merchantQuote;

            QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
            insert qli;

            List<Quote> quotes = [SELECT Id, ER_Docusign_Template__c FROM Quote WHERE ER_Business_Unit__c = 'BENELUX'];

            System.assert(String.isNotBlank(quotes[0].ER_Docusign_Template__c));
            Test.stopTest();
        }
    }  
        
      static testMethod void testGetLabelsTranslationsFromScheme() {

        User ur = TestDataFactory.newUser('APER11', 'APER11','Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        insert ur;
        UtilsBypass.reset();
        System.runAs(ur) {
            Test.startTest();
            ER_Translation__c trl = new ER_Translation__c(); 
            trl.Language__c = 'gr';
            trl.ER_Object_Name__c = 'Opportunity';
            trl.Field_API_Name__c = 'ER_PaymentTerms__c';
            trl.ER_Text_To_Be_Translated__c = 'Pre-paid';
            trl.Text__c = 'Translated PT Text';
            insert trl;
            
            ER_Translation__c trl2 = new ER_Translation__c();
            trl2.Language__c = 'gr';
            trl2.ER_Object_Name__c = 'Opportunity';
            trl2.Field_API_Name__c = 'ER_PaymentMethod__c';
            trl2.ER_Text_To_Be_Translated__c = 'Pre-paid';
            trl2.Text__c = 'Translated PM Text';
            insert trl2;
            
             List<ER_Translation__c> translationList = [
                SELECT ER_Text_To_Be_Translated__c, Text__c, Language__c, ER_Object_Name__c, Field_API_Name__c
                FROM ER_Translation__c];
            //Account newMerchantAccount = [SELECT Id FROM Account LIMIT 1/* WHERE Name = 'testCompany'*/];
            
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany3333');
            newMerchantAccount.ER_BUPicklist__c = 'BENELUX';
            insert newMerchantAccount;
            
            Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER11', 'Default');
            newContact.ER_Language__c = 'FR';
            newContact.AccountId = newMerchantAccount.id;
            insert newContact;

            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'APER11_Quote_Management_Test2');
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            insert newOpportunity;

            Quote merchantQuote = APER07_UtilityTestMethod.getQuote('ER_Merchant_Quote', 'APER11_Quote_Management_Test', newOpportunity.id, null);
            merchantQuote.ContactId = newContact.Id;

            insert merchantQuote;
            
            Test.stopTest();
        }
    }
    
    @isTest
	static void testCreateTask() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER11' LIMIT 1];

    System.runAs(ur) {
        Quote q = [SELECT Id, OwnerId, Name FROM Quote LIMIT 1];

        Test.startTest();
        Task t = APER11_Quote_Management.createTask('Follow Up', q);
        insert t;
        Test.stopTest();

        // Assertions
        Task insertedTask = [
            SELECT Subject, WhatId, OwnerId, Status, Priority, ActivityDate, Description
            FROM Task
            WHERE Id = :t.Id
        ];

        System.assertEquals('Follow Up', insertedTask.Subject);
        System.assertEquals(q.Id, insertedTask.WhatId);
        System.assertEquals(q.OwnerId, insertedTask.OwnerId);
        System.assertEquals('Not Started', insertedTask.Status);
        System.assertEquals('Normal', insertedTask.Priority);
        System.assertEquals(
            Date.today().addDays(1),
            insertedTask.ActivityDate
        );
        System.assertEquals(
            'Auto-created task for follow up.',
            insertedTask.Description
        );
    }
}    
  }