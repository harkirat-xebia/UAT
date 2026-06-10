/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : SMEPlatformEngagementTest
* Author          : Harkirat Singh
* Created Date    : May 18, 2026
* Last Modified By: Harkirat Singh
* Last Modified On: May 18, 2026
* Description     : This class runs tests for UpdateSMEOpportunityQuoteQueueable
*  
* Change History  :
*  Date          │    Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  May 18, 2026  │ Harkirat Singh│ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/
@isTest
private class SMEPlatformEngagementTest {
    
    /**
     * Setup test data
     */
    /*@TestSetup
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
            
            // 3. Create Custom Pricebooks
            Pricebook2 customPricebook = new Pricebook2(
                Name = 'SME Custom Pricebook',
                IsActive = true,
                Description = 'Primary Contract Pricebook'
            );
            insert customPricebook;
            
            Pricebook2 engagementPricebook = new Pricebook2(
                Name = 'Engagement Pricebook BE',
                IsActive = true,
                Description = 'SME Platform Engagement Pricebook'
            );
            insert engagementPricebook;
            
            // 4. Get Record Types
            RecordType rtRange = [SELECT Id FROM RecordType 
                                  WHERE SObjectType = 'Product2' 
                                  AND DeveloperName = 'Range' LIMIT 1];
            RecordType rtService = [SELECT Id FROM RecordType 
                                    WHERE SObjectType = 'Product2' 
                                    AND DeveloperName = 'Service' LIMIT 1];
            
            // 5. Create Solution Product
            Product2 solutionProduct = new Product2(
                Name = 'Edenred Meal',
                ER_Type__c = 'Solution',
                ProductCode = 'TRE',
                IsActive = true,
                QuantityUnitOfMeasure = 'Per Unit',
                ER_BUPicklist__c = 'BE',
                Solution_Group__c = 'Benefits',
                Load_Per_Year__c = 12,
                Days_per_Month__c = 20,
                Face_Value__c = 8
            );
            insert solutionProduct;
            
            // 6. Create Range Product
            Product2 rangeProduct = new Product2(
                Name = '100 to 200',
                ER_Type__c = 'Range',
                ProductCode = 'TRE-RANGE',
                IsActive = true,
                QuantityUnitOfMeasure = 'Per Unit',
                ER_BUPicklist__c = 'BE',
                Solution_Group__c = 'Benefits',
                RecordTypeId = rtRange.Id,
                ER_Solution2__c = solutionProduct.Id
            );
            insert rangeProduct;
            
            // 7. Create Service Product (for primary contract)
            Product2 serviceProduct = new Product2(
                Name = 'Card Service',
                ER_Type__c = 'Service',
                ProductCode = 'TRC',
                IsActive = true,
                QuantityUnitOfMeasure = 'Per Unit',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = rtService.Id,
                Solution_Group__c = 'Benefits',
                ER_Service_Number_of_Ranges__c = 0
            );
            insert serviceProduct;
            
            // 8. Create Engagement Products
            Product2 wellbeingProduct = new Product2(
                Name = 'Wellbeing Discount',
                ER_Type__c = 'Service',
                ProductCode = 'WELLBEING_DISC',
                IsActive = true,
                QuantityUnitOfMeasure = 'Per Unit',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = rtService.Id,
                Solution_Group__c = 'Benefits'
            );
            insert wellbeingProduct;
            
            Product2 freemiumProduct = new Product2(
                Name = 'Freemium Service',
                ER_Type__c = 'Service',
                ProductCode = 'FREEMIUM_SVC',
                IsActive = true,
                QuantityUnitOfMeasure = 'Per Unit',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = rtService.Id,
                Solution_Group__c = 'Benefits'
            );
            insert freemiumProduct;
            
            // 9. Create Standard Pricebook Entries (Required before custom PBEs)
            List<PricebookEntry> standardPBEs = new List<PricebookEntry>{
                new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = rangeProduct.Id,
                    UnitPrice = 100,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Currency'
                ),
                new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = serviceProduct.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Currency'
                ),
                new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = wellbeingProduct.Id,
                    UnitPrice = 50,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Currency'
                ),
                new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = freemiumProduct.Id,
                    UnitPrice = 30,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Currency'
                )
            };
            insert standardPBEs;
            
            // 10. Create Promo Code
            //ER_Promo_Code__c promoCode = new ER_Promo_Code__c(
                //Name = 'SME_PROMO_2026',
                //ER_Promo_Code__c = 'SMEPROMO',
                //Solution__c = 'TRE',
                //Discount_Percentage__c = 10,
                //Discount_Type__c = 'Solution and Cards',
                //ER_Business_Unit__c = 'BE',
                //ER_Start_Date__c = Date.today().addDays(-30),
                //ER_End_Date__c = Date.today().addDays(60),
                //Create_SME_Platform_Engagement__c = true,
            //insert promoCode;
            
            // 11. Create Custom Pricebook Entries
            List<PricebookEntry> customPBEs = new List<PricebookEntry>{
                new PricebookEntry(
                    Pricebook2Id = customPricebook.Id,
                    Product2Id = rangeProduct.Id,
                    UnitPrice = 100,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Currency',
                    ER_Min__c = 100,
                    ER_Max__c = 200,
                    //ER_Promo_Code2__c = promoCode.Id
                ),
                new PricebookEntry(
                    Pricebook2Id = customPricebook.Id,
                    Product2Id = serviceProduct.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Currency',
                    //ER_Promo_Code2__c = promoCode.Id
                )
            };
            insert customPBEs;
            
            // 12. Create Engagement Pricebook Entries
            List<PricebookEntry> engagementPBEs = new List<PricebookEntry>{
                new PricebookEntry(
                    Pricebook2Id = engagementPricebook.Id,
                    Product2Id = wellbeingProduct.Id,
                    UnitPrice = 50,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Percentage',
                    ER_Percentage__c = 5
                ),
                new PricebookEntry(
                    Pricebook2Id = engagementPricebook.Id,
                    Product2Id = freemiumProduct.Id,
                    UnitPrice = 30,
                    IsActive = true,
                    UseStandardPrice = false,
                    ER_BUPicklist__c = 'BE',
                    ER_ValueType__c = 'Percentage',
                    ER_Percentage__c = 5
                )
            };
            insert engagementPBEs;
            
            // 13. Create Account
            Account testAccount = new Account(
                Name = 'SME Test Company',
                ER_BUPicklist__c = 'BE',
                ER_Registration_Number__c = 'SME123456',
                ER_Enterprise_Number__c = 'SME123456',
                NumberOfEmployees = 50,
                BillingStreet = '123 Test Street',
                BillingCity = 'Brussels',
                BillingPostalCode = '1000',
                BillingCountry = 'Belgium'
            );
            insert testAccount;
            
            // 14. Create Contacts
            Contact primaryContact = new Contact(
                FirstName = 'Primary',
                LastName = 'SME Contact',
                Email = 'primary.sme@test.com',
                Phone = '+32123456789',
                AccountId = testAccount.Id,
                ER_Language__c = 'FR',
                ER_Status__c = 'Active'
            );
            insert primaryContact;
            
            Contact billingContact = new Contact(
                FirstName = 'Billing',
                LastName = 'SME Contact',
                Email = 'billing.sme@test.com',
                Phone = '+32987654321',
                AccountId = testAccount.Id,
                ER_Language__c = 'FR',
                ER_Status__c = 'Active'
            );
            insert billingContact;
            
            // 15. Create Campaign
            Campaign testCampaign = new Campaign(
                Name = 'SME Test Campaign',
                ER_Source_ID__c = 'SME_CAMPAIGN_001',
                IsActive = true,
                Status = 'In Progress',
                Type = 'Email'
            );
            insert testCampaign;
            
            // 16. Create Opportunity
            Opportunity testOpp = new Opportunity(
                Name = 'SME Test Opportunity',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = customPricebook.Id,
                CampaignId = testCampaign.Id,
                //ER_Promo_Code2__c = promoCode.Id,
                ER_BUPicklist__c = 'BE',
                ER_Contract_Expected_Start_Date__c = Date.today(),
                Type = 'Operational',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Opportunity.SObjectType,
                    'ER_Client_Opportunity_RT'
                )
            );
            insert testOpp;
            
            // 17. Create Opportunity Contact Roles
            List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>{
                new OpportunityContactRole(
                    OpportunityId = testOpp.Id,
                    ContactId = primaryContact.Id,
                    Role = 'Primary Contact',
                    IsPrimary = true
                ),
                new OpportunityContactRole(
                    OpportunityId = testOpp.Id,
                    ContactId = billingContact.Id,
                    Role = 'Invoicing Contact',
                    IsPrimary = false
                )
            };
            insert ocrList;
            
            // 18. Create Opportunity Line Items
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>{
                new OpportunityLineItem(
                    OpportunityId = testOpp.Id,
                    PricebookEntryId = customPBEs[0].Id,
                    Quantity = 150,
                    UnitPrice = 100,
                    TotalPrice = 15000
                ),
                new OpportunityLineItem(
                    OpportunityId = testOpp.Id,
                    PricebookEntryId = customPBEs[1].Id,
                    Quantity = 1,
                    UnitPrice = 200,
                    TotalPrice = 200
                )
            };
            insert oliList;
            
            // 19. Create Quote
            Quote testQuote = new Quote(
                Name = 'SME Test Quote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = customPricebook.Id,
                ContactId = primaryContact.Id,
                Status = 'Accepted',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Quote.SObjectType,
                    'ER_Client_Quote'
                )
            );
            insert testQuote;
            
            // 20. Create Quote Line Items
            List<QuoteLineItem> qliList = new List<QuoteLineItem>{
                new QuoteLineItem(
                    QuoteId = testQuote.Id,
                    PricebookEntryId = customPBEs[0].Id,
                    Quantity = 150,
                    UnitPrice = 100
                ),
                new QuoteLineItem(
                    QuoteId = testQuote.Id,
                    PricebookEntryId = customPBEs[1].Id,
                    Quantity = 1,
                    UnitPrice = 200
                )
            };
            insert qliList;
            
            // 21. Create Primary Contract (Draft)
            Contract primaryContract = new Contract(
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
                Primary_Contact__c = primaryContact.Id,
                Billing_Contact__c = billingContact.Id,
                CustomerSignedId = primaryContact.Id,
                CustomerSignedDate = Date.today(),
                ER_BUPicklist__c = 'BE',
                ER_Contract_Type__c = 'Operational'
            );
            insert primaryContract;
            
            // 22. Create Contract Line Items using APER07_UtilityTestMethod
            List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>{
                APER07_UtilityTestMethod.getContractLineItem(
                    primaryContract.Id,
                    rangeProduct.Id,
                    customPBEs[0].Id,
                    150,
                    100
                ),
                APER07_UtilityTestMethod.getContractLineItem(
                    primaryContract.Id,
                    serviceProduct.Id,
                    customPBEs[1].Id,
                    1,
                    200
                )
            };
            insert cliList;
        }
    }
    */
    
    
    /**
     * Test: SME Platform Engagement Creation (Positive)
     */
    /*@isTest
    static void testSMEPlatformEngagementCreation() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            // Get test data
            Contract primaryContract = [
                SELECT Id, Status, ER_OpportunityId__c, AccountId
                FROM Contract
                WHERE ER_OpportunityId__c != null
                LIMIT 1
            ];
            
            // Mock callout
            Test.setMock(HttpCalloutMock.class, new SmarterAPIMock());
            
            Test.startTest();
            // Activate primary contract (triggers SME platform logic)
            primaryContract.Status = 'Activated';
            update primaryContract;
            Test.stopTest();
            
            // Verify SME Opportunity created
            List<Opportunity> smeOpps = [
                SELECT Id, Name, StageName, AccountId, ER_Original_Agreement__c, ContractId
                FROM Opportunity
                WHERE ER_Original_Agreement__c = :primaryContract.Id
            ];
            System.assertEquals(1, smeOpps.size(), 'SME Opportunity should be created');
            System.assertEquals(primaryContract.Id, smeOpps[0].ER_Original_Agreement__c, 
                               'Should link to primary contract');
            
            // Verify SME Quote created
            List<Quote> smeQuotes = [
                SELECT Id, Name, OpportunityId, ContractId
                FROM Quote
                WHERE OpportunityId = :smeOpps[0].Id
            ];
            System.assertEquals(1, smeQuotes.size(), 'SME Quote should be created');
            
            // Verify SME Contract created
            List<Contract> smeContracts = [
                SELECT Id, Status, ER_OpportunityId__c, ER_QuoteId__c, ER_Original_Agreement__c
                FROM Contract
                WHERE ER_Original_Agreement__c = :primaryContract.Id
            ];
            System.assertEquals(1, smeContracts.size(), 'SME Contract should be created');
            System.assertEquals('Draft', smeContracts[0].Status, 'SME Contract should be Draft initially');
            
            // Verify Contract Line Items created
            List<ER_ContractLineItem__c> cliList = [
                SELECT Id, ER_Contract__c
                FROM ER_ContractLineItem__c
                WHERE ER_Contract__c = :smeContracts[0].Id
            ];
            System.assert(cliList.size() > 0, 'Contract Line Items should be created');
        }
    }
    */
                
    /**
     * Test: No SME Platform Creation if Promo Checkbox is False
     */
    /*@isTest
    static void testNoSMECreationWhenPromoCheckboxFalse() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            // Update promo code checkbox to false
            ER_Promo_Code__c promo = [
                SELECT Id, Create_SME_Platform_Engagement__c 
                FROM ER_Promo_Code__c 
                LIMIT 1
            ];
            promo.Create_SME_Platform_Engagement__c = false;
            update promo;
            
            Contract primaryContract = [SELECT Id, Status FROM Contract WHERE ER_OpportunityId__c != null LIMIT 1];
            
            Test.startTest();
            primaryContract.Status = 'Activated';
            update primaryContract;
            Test.stopTest();
            
            // Verify NO SME Opportunity created
            List<Opportunity> smeOpps = [
                SELECT Id
                FROM Opportunity
                WHERE ER_Original_Agreement__c = :primaryContract.Id
            ];
            System.assertEquals(0, smeOpps.size(), 
                               'No SME Opportunity should be created when checkbox is false');
        }
    }
    */
                
    /**
     * Test: No SME Creation if Contract has no Opportunity
     */
    /*@isTest
    static void testNoSMECreationWithoutOpportunity() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Contact con = [SELECT Id FROM Contact WHERE ER_Role__c = 'Primary Contact' LIMIT 1];
            Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'SME Custom Pricebook' LIMIT 1];
            
            // Create contract without Opportunity
            Contract contractWithoutOpp = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = 'Draft',
                Pricebook2Id = pb.Id,
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Contract.SObjectType,
                    'ER_Client_Contract_RT'
                ),
                Primary_Contact__c = con.Id,
                ER_BUPicklist__c = 'BE'
            );
            insert contractWithoutOpp;
            
            Test.startTest();
            contractWithoutOpp.Status = 'Activated';
            update contractWithoutOpp;
            Test.stopTest();
            
            // Verify NO SME records created
            List<Opportunity> smeOpps = [
                SELECT Id
                FROM Opportunity
                WHERE ER_Original_Agreement__c = :contractWithoutOpp.Id
            ];
            System.assertEquals(0, smeOpps.size(), 
                               'No SME Opportunity should be created without primary Opportunity');
        }
    }
    */
                
    /**
     * Test: Queueable Updates Opportunity & Quote
     */
    /*@isTest
    static void testUpdateSMEOpportunityQuoteQueueable() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            Contract primaryContract = [
                SELECT Id, AccountId 
                FROM Contract 
                WHERE ER_OpportunityId__c != null 
                LIMIT 1
            ];
            Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'SME Custom Pricebook' LIMIT 1];
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            
            // Manually create SME records
            Opportunity smeOpp = new Opportunity(
                Name = 'Test SME Opp',
                AccountId = primaryContract.AccountId,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = pb.Id,
                ER_Original_Agreement__c = primaryContract.Id,
                ER_BUPicklist__c = 'BE',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Opportunity.SObjectType,
                    'ER_Client_Opportunity_RT'
                )
            );
            insert smeOpp;
            
            Quote smeQuote = new Quote(
                Name = 'Test SME Quote',
                OpportunityId = smeOpp.Id,
                Pricebook2Id = pb.Id,
                ContactId = con.Id,
                Status = 'Accepted',
                ER_BUPicklist__c = 'BE',
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Quote.SObjectType,
                    'ER_Client_Quote'
                )
            );
            insert smeQuote;
            
            Contract smeContract = new Contract(
                AccountId = primaryContract.AccountId,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = 'Draft',
                Pricebook2Id = pb.Id,
                RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Contract.SObjectType,
                    'ER_Client_Contract_RT'
                ),
                ER_OpportunityId__c = smeOpp.Id,
                ER_QuoteId__c = smeQuote.Id,
                ER_Original_Agreement__c = primaryContract.Id,
                ER_BUPicklist__c = 'BE',
                Primary_Contact__c = con.Id
            );
            insert smeContract;
            
            Test.startTest();
            // Execute queueable
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>{smeContract.Id}));
            Test.stopTest();
            
            // Verify Opportunity updated
            Opportunity updatedOpp = [
                SELECT Id, StageName, ContractId
                FROM Opportunity
                WHERE Id = :smeOpp.Id
            ];
            System.assertEquals('Closed Won', updatedOpp.StageName, 'Opportunity should be Closed Won');
            System.assertEquals(smeContract.Id, updatedOpp.ContractId, 'Opportunity should have Contract ID');
            
            // Verify Quote updated
            Quote updatedQuote = [
                SELECT Id, ContractId
                FROM Quote
                WHERE Id = :smeQuote.Id
            ];
            System.assertEquals(smeContract.Id, updatedQuote.ContractId, 'Quote should have Contract ID');
        }
    }
    */
                
    /**
     * Test: Recursion Prevention
     */
    /*@isTest
    static void testRecursionPrevention() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            Contract primaryContract = [
                SELECT Id, Status
                FROM Contract
                WHERE ER_OpportunityId__c != null
                LIMIT 1
            ];
            
            Test.setMock(HttpCalloutMock.class, new SmarterAPIMock());
            
            Test.startTest();
            // Activate contract
            primaryContract.Status = 'Activated';
            update primaryContract;
            
            // Try to trigger again (should be prevented by static variable)
            primaryContract.Status = 'Draft';
            update primaryContract;
            
            primaryContract.Status = 'Activated';
            update primaryContract;
            Test.stopTest();
            
            // Verify only ONE SME Opportunity created (not multiple)
            List<Opportunity> smeOpps = [
                SELECT Id
                FROM Opportunity
                WHERE ER_Original_Agreement__c = :primaryContract.Id
            ];
            System.assertEquals(1, smeOpps.size(), 
                               'Only one SME Opportunity should be created (recursion prevented)');
        }
    }
    */
                
    /**
     * Test: Error Handling in Queueable
     */
    /*@isTest
    static void testQueueableErrorHandling() {
        Test.startTest();
        // Try to execute queueable with empty list
        try {
            System.enqueueJob(new UpdateSMEOpportunityQuoteQueueable(new List<Id>()));
            System.assert(true, 'Empty list should be handled gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for empty list: ' + e.getMessage());
        }
        Test.stopTest();
    }
    */
                
    /**
     * Test: Bulk Processing
     */
    /*@isTest
    static void testBulkSMECreation() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'SME_TEST' LIMIT 1];
        
        System.runAs(testUser) {
            List<Contract> contracts = [
                SELECT Id, Status 
                FROM Contract 
                WHERE ER_OpportunityId__c != null
            ];
            
            Test.setMock(HttpCalloutMock.class, new SmarterAPIMock());
            
            Test.startTest();
            for (Contract c : contracts) {
                c.Status = 'Activated';
            }
            update contracts;
            Test.stopTest();
            
            // Verify SME records created for all contracts
            List<Opportunity> smeOpps = [
                SELECT Id, ER_Original_Agreement__c
                FROM Opportunity
                WHERE ER_Original_Agreement__c IN :contracts
            ];
            System.assert(smeOpps.size() > 0, 'SME Opportunities should be created for bulk processing');
        }
    }
	*/
                
}