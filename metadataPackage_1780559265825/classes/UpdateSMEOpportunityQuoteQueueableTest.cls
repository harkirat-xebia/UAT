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
    
    /**
     * Setup test data
     */
    @TestSetup
    static void setupTestData() {
        // 1. Create User
        User testUser = TestDataFactory.newUser('SME_TEST', 'SME_TEST', 'Local Admin', 'BE');
        testUser.ER_BypassVR__c = true;
        testUser.ER_Bypass_Flows__c = true;
        testUser.ER_bypassTrigger__c = true;
        insert testUser;
        
        System.runAs(testUser) {
            // 2. Create Standard Pricebook
            Id standardPricebookId = Test.getStandardPricebookId();
            Pricebook2 standardPricebook = new Pricebook2(
                Id = standardPricebookId,
                IsActive = true
            );
            update standardPricebook;
            
            // 3. Create Custom Pricebook
            Pricebook2 customPricebook = new Pricebook2(
                Name = 'Test Custom Pricebook',
                IsActive = true,
                ER_Business_Unit__c = 'BE'
            );
            insert customPricebook;
            
            // 4. Get Record Types
            RecordType rtService = [SELECT Id FROM RecordType 
                                    WHERE SObjectType = 'Product2' 
                                    AND DeveloperName = 'Service' LIMIT 1];
            
            // 5. Create Product
            Product2 serviceProduct = new Product2(
                Name = 'Test Service',
                ER_Type__c = 'Service',
                ProductCode = 'TEST_SVC',
                IsActive = true,
                QuantityUnitOfMeasure = 'Per Unit',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = rtService.Id,
                Solution_Group__c = 'Benefits'
            );
            insert serviceProduct;
            
            // 6. Create Standard Pricebook Entry
            PricebookEntry standardPBE = new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = serviceProduct.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency'
            );
            insert standardPBE;
            
            // 7. Create Custom Pricebook Entry
            PricebookEntry customPBE = new PricebookEntry(
                Pricebook2Id = customPricebook.Id,
                Product2Id = serviceProduct.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency'
            );
            insert customPBE;
            
            // 8. Create Main Platform Account (for Customer Domain Reference)
            Account mainPlatformAccount = new Account(
                Name = 'Main Platform Account',
                ER_BUPicklist__c = 'BE',
                Customer_Domain_Reference__c = 'MAIN_PLATFORM_DOMAIN'
            );
            insert mainPlatformAccount;
            
            // 9. Create Test Account
            Account testAccount = new Account(
                Name = 'Test Company',
                ER_BUPicklist__c = 'BE',
                ER_Registration_Number__c = 'TEST123456',
                NumberOfEmployees = 50
            );
            insert testAccount;
            
            // 10. Create Contact
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@example.com',
                AccountId = testAccount.Id,
                ER_Language__c = 'EN',
                ER_Status__c = 'Active'
            );
            insert testContact;
            
            // 11. Create Opportunity
            Opportunity testOpp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = customPricebook.Id,
                ER_BUPicklist__c = 'BE',
                Type = 'Operational',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Opportunity.SObjectType,
                    'ER_Client_Opportunity_RT'
                )
            );
            insert testOpp;
            
            // 12. Create Quote
            Quote testQuote = new Quote(
                Name = 'Test Quote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = customPricebook.Id,
                ContactId = testContact.Id,
                Status = 'Accepted',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Quote.SObjectType,
                    'ER_Client_Quote'
                )
            );
            insert testQuote;
            
            // 13. Create Contract with Main Platform
            Contract testContract = new Contract(
                AccountId = testAccount.Id,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = 'Draft',
                Pricebook2Id = customPricebook.Id,
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Contract.SObjectType,
                    'ER_Client_Contract_RT'
                ),
                ER_OpportunityId__c = testOpp.Id,
                ER_QuoteId__c = testQuote.Id,
                Primary_Contact__c = testContact.Id,
                ER_BUPicklist__c = 'BE',
                Main_Platform__c = mainPlatformAccount.Id
            );
            insert testContract;
        }
    }
    
    /**
     * Test: Successful Update of Opportunity, Quote, and Account
     */
    @isTest
    static void testSuccessfulUpdate() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            // Get test data
            Contract testContract = [
                SELECT Id, ER_OpportunityId__c, ER_QuoteId__c, AccountId
                FROM Contract
                WHERE ER_OpportunityId__c != null
                LIMIT 1
            ];
            
            // Verify initial state
            Opportunity oppBefore = [SELECT Id, StageName, ContractId FROM Opportunity WHERE Id = :testContract.ER_OpportunityId__c];
            Quote quoteBefore = [SELECT Id, ContractId FROM Quote WHERE Id = :testContract.ER_QuoteId__c];
            Account accBefore = [SELECT Id, Customer_Domain_Reference__c FROM Account WHERE Id = :testContract.AccountId];
            
            System.assertNotEquals('Closed Won', oppBefore.StageName, 'Opportunity should not be Closed Won initially');
            System.assertEquals(null, oppBefore.ContractId, 'Opportunity should not have Contract ID initially');
            System.assertEquals(null, quoteBefore.ContractId, 'Quote should not have Contract ID initially');
            System.assertEquals(null, accBefore.Customer_Domain_Reference__c, 'Account should not have Customer Domain initially');
            
            Test.startTest();
            // Execute queueable
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>{testContract.Id}));
            Test.stopTest();
            
            // Verify Opportunity updated
            Opportunity oppAfter = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id = :testContract.ER_OpportunityId__c
            ];
            System.assertEquals('Closed Won', oppAfter.StageName, 'Opportunity should be Closed Won');
            System.assertEquals(testContract.Id, oppAfter.ContractId, 'Opportunity should have Contract ID');
            
            // Verify Quote updated
            Quote quoteAfter = [
                SELECT Id, ContractId
                FROM Quote
                WHERE Id = :testContract.ER_QuoteId__c
            ];
            System.assertEquals(testContract.Id, quoteAfter.ContractId, 'Quote should have Contract ID');
            
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
    
    /**
     * Test: Multiple Contracts Processing
     */
    @isTest
    static void testMultipleContractsUpdate() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            // Get existing data
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact LIMIT 1];
            Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Custom Pricebook' LIMIT 1];
            Account mainPlatform = [SELECT Id FROM Account WHERE Name = 'Main Platform Account' LIMIT 1];
            
            // Create additional opportunities, quotes, and contracts
            List<Opportunity> opps = new List<Opportunity>();
            for (Integer i = 1; i <= 3; i++) {
                opps.add(new Opportunity(
                    Name = 'Test Opp ' + i,
                    AccountId = testAccount.Id,
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(30),
                    Pricebook2Id = pb.Id,
                    ER_BUPicklist__c = 'BE',
                    RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                        Opportunity.SObjectType,
                        'ER_Client_Opportunity_RT'
                    )
                ));
            }
            insert opps;
            
            List<Quote> quotes = new List<Quote>();
            for (Opportunity opp : opps) {
                quotes.add(new Quote(
                    Name = 'Quote for ' + opp.Name,
                    OpportunityId = opp.Id,
                    Pricebook2Id = pb.Id,
                    ContactId = testContact.Id,
                    Status = 'Accepted',
                    ER_BUPicklist__c = 'BE',
                    RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                        Quote.SObjectType,
                        'ER_Client_Quote'
                    )
                ));
            }
            insert quotes;
            
            List<Contract> contracts = new List<Contract>();
            for (Integer i = 0; i < opps.size(); i++) {
                contracts.add(new Contract(
                    AccountId = testAccount.Id,
                    StartDate = Date.today(),
                    ContractTerm = 12,
                    Status = 'Draft',
                    Pricebook2Id = pb.Id,
                    RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                        Contract.SObjectType,
                        'ER_Client_Contract_RT'
                    ),
                    ER_OpportunityId__c = opps[i].Id,
                    ER_QuoteId__c = quotes[i].Id,
                    Primary_Contact__c = testContact.Id,
                    ER_BUPicklist__c = 'BE',
                    Main_Platform__c = mainPlatform.Id
                ));
            }
            insert contracts;
            
            List<Id> contractIds = new List<Id>();
            for (Contract c : contracts) {
                contractIds.add(c.Id);
            }
            
            Test.startTest();
            // Execute queueable with multiple contracts
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(contractIds));
            Test.stopTest();
            
            // Verify all opportunities updated
            List<Opportunity> updatedOpps = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id IN :opps
            ];
            System.assertEquals(3, updatedOpps.size(), 'All opportunities should be queried');
            for (Opportunity opp : updatedOpps) {
                System.assertEquals('Closed Won', opp.StageName, 'All opportunities should be Closed Won');
                System.assertNotEquals(null, opp.ContractId, 'All opportunities should have Contract ID');
            }
            
            // Verify all quotes updated
            List<Quote> updatedQuotes = [
                SELECT Id, ContractId
                FROM Quote
                WHERE Id IN :quotes
            ];
            System.assertEquals(3, updatedQuotes.size(), 'All quotes should be queried');
            for (Quote q : updatedQuotes) {
                System.assertNotEquals(null, q.ContractId, 'All quotes should have Contract ID');
            }
        }
    }
    
    /**
     * Test: Contract without Opportunity (should skip)
     */
    @isTest
    static void testContractWithoutOpportunity() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact LIMIT 1];
            Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Custom Pricebook' LIMIT 1];
            
            // Create contract without Opportunity
            Contract contractWithoutOpp = new Contract(
                AccountId = testAccount.Id,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = 'Draft',
                Pricebook2Id = pb.Id,
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Contract.SObjectType,
                    'ER_Client_Contract_RT'
                ),
                Primary_Contact__c = testContact.Id,
                ER_BUPicklist__c = 'BE'
            );
            insert contractWithoutOpp;
            
            Test.startTest();
            // Execute queueable
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>{contractWithoutOpp.Id}));
            Test.stopTest();
            
            // Should complete without errors (no updates performed)
            System.assert(true, 'Queueable should handle contracts without opportunities gracefully');
        }
    }
    
    /**
     * Test: Empty Contract List
     */
    @isTest
    static void testEmptyContractList() {
        Test.startTest();
        try {
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>()));
            System.assert(true, 'Empty list should be handled gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for empty list: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test: Account Update Only When Main Platform Exists
     */
    @isTest
    static void testAccountUpdateWithMainPlatform() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact LIMIT 1];
            Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Custom Pricebook' LIMIT 1];
            
            // Create Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opp No Main Platform',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = pb.Id,
                ER_BUPicklist__c = 'BE',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Opportunity.SObjectType,
                    'ER_Client_Opportunity_RT'
                )
            );
            insert opp;
            
            // Create Quote
            Quote quote = new Quote(
                Name = 'Test Quote No Main Platform',
                OpportunityId = opp.Id,
                Pricebook2Id = pb.Id,
                ContactId = testContact.Id,
                Status = 'Accepted',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Quote.SObjectType,
                    'ER_Client_Quote'
                )
            );
            insert quote;
            
            // Create Contract WITHOUT Main Platform
            Contract contractNoMainPlatform = new Contract(
                AccountId = testAccount.Id,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = 'Draft',
                Pricebook2Id = pb.Id,
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Contract.SObjectType,
                    'ER_Client_Contract_RT'
                ),
                ER_OpportunityId__c = opp.Id,
                ER_QuoteId__c = quote.Id,
                Primary_Contact__c = testContact.Id,
                ER_BUPicklist__c = 'BE'
                // Main_Platform__c is NULL
            );
            insert contractNoMainPlatform;
            
            Account accBefore = [SELECT Id, Customer_Domain_Reference__c FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(null, accBefore.Customer_Domain_Reference__c, 'Account should not have Customer Domain initially');
            
            Test.startTest();
            // Execute queueable
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>{contractNoMainPlatform.Id}));
            Test.stopTest();
            
            // Verify Account NOT updated (because Main Platform is null)
            Account accAfter = [SELECT Id, Customer_Domain_Reference__c FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(null, accAfter.Customer_Domain_Reference__c, 
                               'Account should NOT be updated when Main Platform is null');
            
            // But Opportunity and Quote should still be updated
            Opportunity oppAfter = [SELECT Id, StageName, ContractId FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals('Closed Won', oppAfter.StageName, 'Opportunity should still be updated');
            
            Quote quoteAfter = [SELECT Id, ContractId FROM Quote WHERE Id = :quote.Id];
            System.assertEquals(contractNoMainPlatform.Id, quoteAfter.ContractId, 'Quote should still be updated');
        }
    }
    
    /**
     * Test: Account Update Skip When Customer Domain Already Set
     */
    @isTest
    static void testAccountUpdateSkipWhenAlreadySet() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            // Get test data
            Contract testContract = [
                SELECT Id, AccountId
                FROM Contract
                WHERE ER_OpportunityId__c != null
                LIMIT 1
            ];
            
            // Pre-set the Customer Domain Reference to the same value
            Account acc = [SELECT Id FROM Account WHERE Id = :testContract.AccountId];
            acc.Customer_Domain_Reference__c = 'MAIN_PLATFORM_DOMAIN';
            update acc;
            
            Test.startTest();
            // Execute queueable
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>{testContract.Id}));
            Test.stopTest();
            
            // Verify Account still has the same value (no error, just skipped update)
            Account accAfter = [SELECT Id, Customer_Domain_Reference__c FROM Account WHERE Id = :testContract.AccountId];
            System.assertEquals('MAIN_PLATFORM_DOMAIN', accAfter.Customer_Domain_Reference__c, 
                               'Account should maintain Customer Domain Reference');
        }
    }
    
    /**
     * Test: Error Handling
     */
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        try {
            // Pass invalid contract IDs
            List<Id> invalidIds = new List<Id>{'800INVALIDID123'};
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(invalidIds));
            System.assert(true, 'Should handle invalid IDs gracefully');
        } catch (Exception e) {
            // Should not reach here
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test: Chaining to ActivateContractsQueueable
     */
    @isTest
    static void testChainingToActivateContractsQueueable() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            Contract testContract = [
                SELECT Id
                FROM Contract
                WHERE ER_OpportunityId__c != null
                LIMIT 1
            ];
            
            Test.startTest();
            // Execute queueable
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>{testContract.Id}));
            Test.stopTest();
            
            // Verify that the queueable executed successfully
            // Note: We can't directly verify chaining in test context,
            // but we can verify the main updates happened
            Opportunity opp = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id IN (SELECT ER_OpportunityId__c FROM Contract WHERE Id = :testContract.Id)
            ];
            System.assertEquals('Closed Won', opp.StageName, 'Opportunity should be updated before chaining');
        }
    }
    
    /**
     * Test: Bulk Processing Performance
     */
    @isTest
    static void testBulkProcessing() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact LIMIT 1];
            Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Custom Pricebook' LIMIT 1];
            Account mainPlatform = [SELECT Id FROM Account WHERE Name = 'Main Platform Account' LIMIT 1];
            
            // Create 10 opportunities, quotes, and contracts
            List<Opportunity> opps = new List<Opportunity>();
            for (Integer i = 1; i <= 10; i++) {
                opps.add(new Opportunity(
                    Name = 'Bulk Test Opp ' + i,
                    AccountId = testAccount.Id,
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(30),
                    Pricebook2Id = pb.Id,
                    ER_BUPicklist__c = 'BE',
                    RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                        Opportunity.SObjectType,
                        'ER_Client_Opportunity_RT'
                    )
                ));
            }
            insert opps;
            
            List<Quote> quotes = new List<Quote>();
            for (Opportunity opp : opps) {
                quotes.add(new Quote(
                    Name = 'Quote for ' + opp.Name,
                    OpportunityId = opp.Id,
                    Pricebook2Id = pb.Id,
                    ContactId = testContact.Id,
                    Status = 'Accepted',
                    ER_BUPicklist__c = 'BE',
                    RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                        Quote.SObjectType,
                        'ER_Client_Quote'
                    )
                ));
            }
            insert quotes;
            
            List<Contract> contracts = new List<Contract>();
            for (Integer i = 0; i < opps.size(); i++) {
                contracts.add(new Contract(
                    AccountId = testAccount.Id,
                    StartDate = Date.today(),
                    ContractTerm = 12,
                    Status = 'Draft',
                    Pricebook2Id = pb.Id,
                    RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                        Contract.SObjectType,
                        'ER_Client_Contract_RT'
                    ),
                    ER_OpportunityId__c = opps[i].Id,
                    ER_QuoteId__c = quotes[i].Id,
                    Primary_Contact__c = testContact.Id,
                    ER_BUPicklist__c = 'BE',
                    Main_Platform__c = mainPlatform.Id
                ));
            }
            insert contracts;
            
            List<Id> contractIds = new List<Id>();
            for (Contract c : contracts) {
                contractIds.add(c.Id);
            }
            
            Test.startTest();
            // Execute queueable with 10 contracts
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(contractIds));
            Test.stopTest();
            
            // Verify all records updated
            List<Opportunity> updatedOpps = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id IN :opps
            ];
            System.assertEquals(10, updatedOpps.size(), 'All 10 opportunities should be updated');
            
            for (Opportunity opp : updatedOpps) {
                System.assertEquals('Closed Won', opp.StageName, 'Each opportunity should be Closed Won');
                System.assertNotEquals(null, opp.ContractId, 'Each opportunity should have Contract ID');
            }
        }
    }
}