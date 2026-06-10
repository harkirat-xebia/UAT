/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : UpdateSMEOpportunityQuoteQueueableTest
* Author          : Harkirat Singh
* Created Date    : May 20, 2026
* Last Modified By: Harkirat Singh
* Last Modified On: May 20, 2026
* Description     : Test class for UpdateSMEOpportunityQuoteQueueable
*  
* Change History  :
*  Date          │    Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  May 20, 2026  │ Harkirat Singh│ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/
@isTest
private class UpdateSMEOpportunityQuoteQueueableTest {
    
    @testSetup
    static void setupTestData() {
        // Create test user with predictable name
        User testUser = TestDataFactory.newUser('UpdateSME', 'TestUser', 'Local Admin', 'BELUX', 'PL');
        testUser.ER_BypassVR__c = true;
        testUser.ER_bypassTrigger__c = true;
        insert testUser;
        
        System.runAs(testUser) {
            // Create Main Platform Account
            Account mainPlatformAcc = APER07_UtilityTestMethod.insertAccount(
                'Main Platform Account',
                'ER_Company_Account_RT'
            );
            mainPlatformAcc.Main_Platform__c = true;
            mainPlatformAcc.Customer_Domain_Reference__c = 'MAIN_PLATFORM_DOMAIN';
            update mainPlatformAcc;
            
            // Create Regular Account (SME Account)
            Account smeAccount = APER07_UtilityTestMethod.insertAccount(
                'SME Test Account',
                'ER_Company_Account_RT'
            );
            
            // Create Pricebook
            PriceBook2 pb = APER07_UtilityTestMethod.getpriceBook();
            
            // Create Opportunity
            Opportunity opp = APER07_UtilityTestMethod.getOpportunity(
                'ER_Client_Opportunity_RT',
                'Test Opportunity'
            );
            opp.AccountId = smeAccount.Id;
            opp.Pricebook2Id = pb.Id;
            opp.StageName = 'Qualification';
            insert opp;
            
            // Create Quote
            Quote quote = APER07_UtilityTestMethod.getQuote(
                'ER_Client_Quote',
                'Test Quote',
                opp.Id,
                pb.Id
            );
            quote.Status = 'Draft';
            insert quote;
            
            // Create Contract linked to Opportunity and Quote
            Contract testContract = APER07_UtilityTestMethod.insertContract(
                smeAccount.Id,
                Date.today(),
                'Draft',
                pb.Id,
                'ER_Client_Contract_RT',
                testUser.Id
            );
            testContract.ER_OpportunityId__c = opp.Id;
            testContract.ER_QuoteId__c = quote.Id;
            testContract.Main_Platform__c = mainPlatformAcc.Id;
            update testContract;
        }
    }
    
    /**
     * @description Test successful update of Opportunity, Quote, and Account
     */
    @isTest
    static void test_UpdateSMEOpportunityQuote_Success() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'TestUser' LIMIT 1];
        
        System.runAs(testUser) {
            // Get test data
            Contract testContract = [
                SELECT Id, ER_OpportunityId__c, ER_QuoteId__c, AccountId
                FROM Contract
                LIMIT 1
            ];
            
            Opportunity oppBefore = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id = :testContract.ER_OpportunityId__c
            ];
            
            Quote quoteBefore = [
                SELECT Id, ContractId
                FROM Quote
                WHERE Id = :testContract.ER_QuoteId__c
            ];
            
            Account accBefore = [
                SELECT Id, Customer_Domain_Reference__c
                FROM Account
                WHERE Id = :testContract.AccountId
            ];
            
            // Verify initial state
            System.assertEquals('Qualification', oppBefore.StageName, 'Opportunity should start in Qualification stage');
            System.assertEquals(null, oppBefore.ContractId, 'Opportunity should not have Contract linked initially');
            System.assertEquals(null, quoteBefore.ContractId, 'Quote should not have Contract linked initially');
            System.assertEquals(null, accBefore.Customer_Domain_Reference__c, 'Account should not have Customer Domain initially');
            
            Test.startTest();
            
            // Execute queueable
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>{ testContract.Id }));
            
            Test.stopTest();
            
            // Verify Opportunity updated
            Opportunity oppAfter = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id = :testContract.ER_OpportunityId__c
            ];
            
            System.assertEquals('Closed Won', oppAfter.StageName, 'Opportunity should be Closed Won');
            System.assertEquals(testContract.Id, oppAfter.ContractId, 'Opportunity should be linked to Contract');
            
            // Verify Quote updated
            Quote quoteAfter = [
                SELECT Id, ContractId
                FROM Quote
                WHERE Id = :testContract.ER_QuoteId__c
            ];
            
            System.assertEquals(testContract.Id, quoteAfter.ContractId, 'Quote should be linked to Contract');
            
            // Verify Account updated
            Account accAfter = [
                SELECT Id, Customer_Domain_Reference__c
                FROM Account
                WHERE Id = :testContract.AccountId
            ];
            
            System.assertEquals('MAIN_PLATFORM_DOMAIN', accAfter.Customer_Domain_Reference__c, 
                'Account should have Customer Domain Reference from Main Platform');
        }
    }
    
    @isTest
    static void test_UpdateSMEOpportunityQuote_MultipleContracts() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'TestUser' LIMIT 1];
        
        System.runAs(testUser) {
            // Get existing contract
            Contract existingContract = [SELECT Id, ER_OpportunityId__c FROM Contract LIMIT 1];
            
            // Create additional test data
            Account smeAccount2 = APER07_UtilityTestMethod.insertAccount(
                'SME Test Account 2',
                'ER_Company_Account_RT'
            );
            
            PriceBook2 pb = APER07_UtilityTestMethod.getpriceBook();
            
            Opportunity opp2 = APER07_UtilityTestMethod.getOpportunity(
                'ER_Client_Opportunity_RT',
                'Test Opportunity 2'
            );
            opp2.AccountId = smeAccount2.Id;
            opp2.Pricebook2Id = pb.Id;
            opp2.StageName = 'Qualification';
            insert opp2;
            
            Quote quote2 = APER07_UtilityTestMethod.getQuote(
                'ER_Client_Quote',
                'Test Quote 2',
                opp2.Id,
                pb.Id
            );
            insert quote2;
            
            Contract testContract2 = APER07_UtilityTestMethod.insertContract(
                smeAccount2.Id,
                Date.today(),
                'Draft',
                pb.Id,
                'ER_Client_Contract_RT',
                testUser.Id
            );
            testContract2.ER_OpportunityId__c = opp2.Id;
            testContract2.ER_QuoteId__c = quote2.Id;
            update testContract2;
            
            Test.startTest();
            
            // Execute queueable with multiple contracts
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(
                new List<Id>{ existingContract.Id, testContract2.Id }
            ));
            
            Test.stopTest();
            
            // Verify both opportunities updated
            List<Opportunity> oppsAfter = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id IN (:existingContract.ER_OpportunityId__c, :opp2.Id)
            ];
            
            System.assertEquals(2, oppsAfter.size(), 'Both opportunities should be updated');
            for (Opportunity opp : oppsAfter) {
                System.assertEquals('Closed Won', opp.StageName, 'All opportunities should be Closed Won');
                System.assertNotEquals(null, opp.ContractId, 'All opportunities should have Contract linked');
            }
        }
    }
    
}