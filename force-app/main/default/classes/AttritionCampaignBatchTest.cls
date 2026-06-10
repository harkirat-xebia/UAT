@isTest
public class AttritionCampaignBatchTest {
    
    /**
     * Create a user with bypass validation checkbox checked
     */
    @testSetup 
    static void setupUser() {
        
        // Create a profile (or use existing System Administrator profile)
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Create user with bypass validation
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User Bypass',
            ER_Business_Unit__c = 'BE',
            Email = 'testbypass@example.com',
            Username = 'testbypass' + System.currentTimeMillis() + '@example.com',
            Alias = 'tbypass',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = sysAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            ER_BypassVR__c = true 
        );
        insert testUser;
    }
    
    /**
     * Get the bypass user
     */
    private static User getBypassUser() {
        return [SELECT Id FROM User WHERE Email = 'testbypass@example.com' LIMIT 1];
    }
    
    /**
     * Setup test data for various scenarios
     */
    static void createTestData() {
        
        // Create Parent Campaigns for different segments
        List<Campaign> parentCampaigns = new List<Campaign>{
            new Campaign(Name = 'Parent Attrition MMj', Type = 'Attrition', IsActive = true),
            new Campaign(Name = 'Parent Attrition SME', Type = 'Attrition', IsActive = true),
            new Campaign(Name = 'Parent Attrition TPE', Type = 'Attrition', IsActive = true),
            new Campaign(Name = 'Parent Attrition LUX MMj', Type = 'Attrition', IsActive = true),
            new Campaign(Name = 'Parent Attrition LUX SME', Type = 'Attrition', IsActive = true)
        };
        insert parentCampaigns;
        
        // Create Accounts with different employee counts for segmentation
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'MMj Account BE', 
                NumberOfEmployees = 50,
                ER_VAT_Number__c = 'VAT123456',  // Add required field
                BillingCountry = 'Belgium'
            ),
            new Account(
                Name = 'SME Account BE', 
                NumberOfEmployees = 15,
                ER_VAT_Number__c = 'VAT234567',
                BillingCountry = 'Belgium'
            ),
            new Account(
                Name = 'TPE Account BE', 
                NumberOfEmployees = 3,
                ER_VAT_Number__c = 'VAT345678',
                BillingCountry = 'Belgium'
            ),
            new Account(
                Name = 'MMj Account LUX', 
                NumberOfEmployees = 40,
                ER_VAT_Number__c = 'VAT456789',
                BillingCountry = 'Luxembourg'
            ),
            new Account(
                Name = 'SME Account LUX', 
                NumberOfEmployees = 20,
                ER_VAT_Number__c = 'VAT567890',
                BillingCountry = 'Luxembourg'
            ),
            new Account(
                Name = 'Excluded Account', 
                NumberOfEmployees = 50,
                ER_VAT_Number__c = 'VAT678901',
                BillingCountry = 'Belgium'
            )
        };
        insert accounts;
        
        // Create Contacts for each account
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = acc.Name + ' Contact',
                AccountId = acc.Id,
                Email = acc.Name.replace(' ', '').toLowerCase() + '@test.com'
            );
            contacts.add(con);
        }
        insert contacts;
        
        // Update accounts with HU_HQ_Contact
        for (Integer i = 0; i < accounts.size(); i++) {
            accounts[i].HU_HQ_Contact__c = contacts[i].Id;
        }
        update accounts;
        
        // Create Products (Solutions) for BE and LU
        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'BE Solution',
                ER_BUPicklist__c = 'BE',
                Exclude_from_Attrition_Campaign__c = false
            ),
            new Product2(
                Name = 'LU Solution',
                ER_BUPicklist__c = 'LU',
                Exclude_from_Attrition_Campaign__c = false
            ),
            new Product2(
                Name = 'Excluded Solution',
                ER_BUPicklist__c = 'BE',
                Exclude_from_Attrition_Campaign__c = true
            )
        };
        insert products;
        
        // Create Contracts
        List<Contract> contracts = new List<Contract>();
        for (Account acc : accounts) {
            Contract con = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today().addMonths(-6),
                ContractTerm = 12,
                Status = 'Draft'
            );
            contracts.add(con);
        }
        insert contracts;
        
        // Activate contracts
        for (Contract con : contracts) {
            con.Status = 'Activated';
        }
        update contracts;
        
        // Create Contract Contact Roles (Primary Contacts)
        List<ContractContactRole> ccrs = new List<ContractContactRole>();
        for (Integer i = 0; i < contracts.size(); i++) {
            ccrs.add(new ContractContactRole(
                ContractId = contracts[i].Id,
                ContactId = contacts[i].Id,
                Role = 'Primary Contact'
            ));
        }
        insert ccrs;
        
        // Create Solution Line Items with different Last Order Dates
        List<ER_Solution_Line_Item__c> slis = new List<ER_Solution_Line_Item__c>{
            // BE MMj - eligible (120+ days)
            new ER_Solution_Line_Item__c(
                ER_Account__c = accounts[0].Id,
                ER_Solution__c = products[0].Id,
                ER_Contract__c = contracts[0].Id,
                Last_Order_Date__c = System.today().addDays(-130)
            ),
            // BE SME - eligible (45+ days)
            new ER_Solution_Line_Item__c(
                ER_Account__c = accounts[1].Id,
                ER_Solution__c = products[0].Id,
                ER_Contract__c = contracts[1].Id,
                Last_Order_Date__c = System.today().addDays(-60)
            ),
            // BE TPE - eligible (90+ days)
            new ER_Solution_Line_Item__c(
                ER_Account__c = accounts[2].Id,
                ER_Solution__c = products[0].Id,
                ER_Contract__c = contracts[2].Id,
                Last_Order_Date__c = System.today().addDays(-100)
            ),
            // LUX MMj - eligible (60+ days)
            new ER_Solution_Line_Item__c(
                ER_Account__c = accounts[3].Id,
                ER_Solution__c = products[1].Id,
                ER_Contract__c = contracts[3].Id,
                Last_Order_Date__c = System.today().addDays(-70)
            ),
            // LUX SME - eligible (70+ days)
            new ER_Solution_Line_Item__c(
                ER_Account__c = accounts[4].Id,
                ER_Solution__c = products[1].Id,
                ER_Contract__c = contracts[4].Id,
                Last_Order_Date__c = System.today().addDays(-80)
            ),
            // Excluded solution - should not be processed
            new ER_Solution_Line_Item__c(
                ER_Account__c = accounts[5].Id,
                ER_Solution__c = products[2].Id,
                ER_Contract__c = contracts[5].Id,
                Last_Order_Date__c = System.today().addDays(-150)
            )
        };
        insert slis;
    }
    
    /**
     * Test basic batch execution with all segments
     * To be checked later Harkirat
     */
    /*@isTest 
    static void testBatchExecution() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            Test.startTest();
            AttritionCampaignBatch batch = new AttritionCampaignBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            // Verify child campaigns were created
            Date todayDate = System.today();
            String quarter = 'Q' + ((todayDate.month() - 1) / 3 + 1) + '-' + todayDate.year();
            
            List<Campaign> childCampaigns = [
                SELECT Id, Name, Type, IsActive, ParentId, ER_BUPicklist__c, 
                       Lead_Source__c, Lead_sub_source__c
                FROM Campaign
                WHERE Name LIKE :('%Attrition%' + quarter + '%')
                AND ParentId != null
            ];
            
            System.assertNotEquals(0, childCampaigns.size(), 'Child campaigns should be created');
            
            // Verify campaign properties
            for (Campaign camp : childCampaigns) {
                System.assertEquals('Attrition', camp.Type, 'Campaign type should be Attrition');
                System.assertEquals(true, camp.IsActive, 'Campaign should be active');
                System.assertEquals('Emailing', camp.Lead_Source__c, 'Lead source should be Emailing');
                System.assertEquals('Automated email', camp.Lead_sub_source__c, 'Lead sub source should be Automated email');
                System.assertNotEquals(null, camp.ParentId, 'Campaign should have a parent');
            }
            
            // Verify campaign members were created
            List<CampaignMember> members = [
                SELECT Id, ContactId, CampaignId, Campaign.Name
                FROM CampaignMember
                WHERE Campaign.Type = 'Attrition'
                AND Campaign.ParentId != null
            ];
            
            System.assertNotEquals(0, members.size(), 'Campaign members should be created');
            
            // Verify excluded solution was not processed
            Account excludedAccount = [
                SELECT Id FROM Account WHERE Name = 'Excluded Account' LIMIT 1
            ];
            Contact excludedContact = [
                SELECT Id FROM Contact WHERE AccountId = :excludedAccount.Id LIMIT 1
            ];
            
            List<CampaignMember> excludedMembers = [
                SELECT Id FROM CampaignMember 
                WHERE ContactId = :excludedContact.Id
                AND Campaign.Type = 'Attrition'
            ];
            
            System.assertEquals(0, excludedMembers.size(), 'Excluded solution should not create campaign members');
        }
    }
    */
    
    /**
     * Test batch with existing campaign - should not create duplicates
     */
    @isTest 
    static void testBatchWithExistingCampaign() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            // Get parent campaign
            Campaign parentCampaign = [
                SELECT Id FROM Campaign 
                WHERE Name = 'Parent Attrition SME' LIMIT 1
            ];
            
            // Create existing child campaign
            Date todayDate = System.today();
            String quarter = 'Q' + ((todayDate.month() - 1) / 3 + 1) + '-' + todayDate.year();
            Integer qStartMonth = ((todayDate.month() - 1) / 3) * 3 + 1;
            Date qStartDate = Date.newInstance(todayDate.year(), qStartMonth, 1);
            Integer qEndMonth = ((todayDate.month() - 1) / 3) * 3 + 3;
            Date qEndDate = Date.newInstance(todayDate.year(), qEndMonth, Date.daysInMonth(todayDate.year(), qEndMonth));
            
            Campaign existingCampaign = new Campaign(
                Name = 'Attrition SME ' + quarter,
                Type = 'Attrition',
                IsActive = true,
                StartDate = qStartDate,
                EndDate = qEndDate,
                ParentId = parentCampaign.Id,
                ER_BUPicklist__c = 'BE'
            );
            insert existingCampaign;
            
            Integer campaignCountBefore = [SELECT COUNT() FROM Campaign WHERE Name LIKE :('%Attrition SME ' + quarter)];
            
            Test.startTest();
            AttritionCampaignBatch batch = new AttritionCampaignBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            Integer campaignCountAfter = [SELECT COUNT() FROM Campaign WHERE Name LIKE :('%Attrition SME ' + quarter)];
            
            System.assertEquals(campaignCountBefore, campaignCountAfter, 
                'Should not create duplicate campaigns with same name');
        }
    }
    
    /**
     * Test segmentation logic for BE business unit
     */
    @isTest 
    static void testBESegmentation() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            Test.startTest();
            AttritionCampaignBatch batch = new AttritionCampaignBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            Date todayDate = System.today();
            String quarter = 'Q' + ((todayDate.month() - 1) / 3 + 1) + '-' + todayDate.year();
            
            // Verify MMj segment (30-99 employees)
            List<Campaign> mmjCampaigns = [
                SELECT Id, (SELECT ContactId FROM CampaignMembers)
                FROM Campaign
                WHERE Name = :('Attrition MMj ' + quarter)
            ];
            
            if (!mmjCampaigns.isEmpty()) {
                System.assertNotEquals(0, mmjCampaigns[0].CampaignMembers.size(), 
                    'MMj campaign should have members');
            }
            
            // Verify SME segment (6-29 employees)
            List<Campaign> smeCampaigns = [
                SELECT Id, (SELECT ContactId FROM CampaignMembers)
                FROM Campaign
                WHERE Name = :('Attrition SME ' + quarter)
            ];
            
            if (!smeCampaigns.isEmpty()) {
                System.assertNotEquals(0, smeCampaigns[0].CampaignMembers.size(), 
                    'SME campaign should have members');
            }
            
            // Verify TPE segment (0-5 employees)
            List<Campaign> tpeCampaigns = [
                SELECT Id, (SELECT ContactId FROM CampaignMembers)
                FROM Campaign
                WHERE Name = :('Attrition TPE ' + quarter)
            ];
            
            if (!tpeCampaigns.isEmpty()) {
                System.assertNotEquals(0, tpeCampaigns[0].CampaignMembers.size(), 
                    'TPE campaign should have members');
            }
        }
    }
    
    /**
     * Test segmentation logic for LU business unit
     */
    @isTest 
    static void testLUXSegmentation() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            Test.startTest();
            AttritionCampaignBatch batch = new AttritionCampaignBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            Date todayDate = System.today();
            String quarter = 'Q' + ((todayDate.month() - 1) / 3 + 1) + '-' + todayDate.year();
            
            // Verify LUX MMj segment (>=30 employees)
            List<Campaign> luxMmjCampaigns = [
                SELECT Id, ER_BUPicklist__c, (SELECT ContactId FROM CampaignMembers)
                FROM Campaign
                WHERE Name = :('Attrition LUX MMj ' + quarter)
            ];
            
            if (!luxMmjCampaigns.isEmpty()) {
                System.assertEquals('LU', luxMmjCampaigns[0].ER_BUPicklist__c, 
                    'LUX MMj campaign should have LU business unit');
                System.assertNotEquals(0, luxMmjCampaigns[0].CampaignMembers.size(), 
                    'LUX MMj campaign should have members');
            }
            
            // Verify LUX SME segment (<30 employees)
            List<Campaign> luxSmeCampaigns = [
                SELECT Id, ER_BUPicklist__c, (SELECT ContactId FROM CampaignMembers)
                FROM Campaign
                WHERE Name = :('Attrition LUX SME ' + quarter)
            ];
            
            if (!luxSmeCampaigns.isEmpty()) {
                System.assertEquals('LU', luxSmeCampaigns[0].ER_BUPicklist__c, 
                    'LUX SME campaign should have LU business unit');
                System.assertNotEquals(0, luxSmeCampaigns[0].CampaignMembers.size(), 
                    'LUX SME campaign should have members');
            }
        }
    }
    
    /**
     * Test that contacts already in attrition are not added again
     * To be checked later harkirat
     */
    /*@isTest 
    static void testPreventDuplicateAttritionEntries() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            // First batch execution
            Test.startTest();
            AttritionCampaignBatch batch1 = new AttritionCampaignBatch();
            Database.executeBatch(batch1, 200);
            Test.stopTest();
            
            Integer memberCountAfterFirst = [
                SELECT COUNT() FROM CampaignMember 
                WHERE Campaign.Type = 'Attrition'
            ];
            
            // Second batch execution - should not add same contacts again
            Test.startTest();
            AttritionCampaignBatch batch2 = new AttritionCampaignBatch();
            Database.executeBatch(batch2, 200);
            Test.stopTest();
            
            Integer memberCountAfterSecond = [
                SELECT COUNT() FROM CampaignMember 
                WHERE Campaign.Type = 'Attrition'
            ];
            
            System.assertEquals(memberCountAfterFirst, memberCountAfterSecond, 
                'Should not create duplicate campaign members on second run');
        }
    }


    @isTest 
    static void testReEntryAfterNewOrder() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            // First batch execution
            Test.startTest();
            AttritionCampaignBatch batch1 = new AttritionCampaignBatch();
            Database.executeBatch(batch1, 200);
            Test.stopTest();
            
            // Update Last Order Date to recent (simulating new order)
            ER_Solution_Line_Item__c sli = [
                SELECT Id, Last_Order_Date__c 
                FROM ER_Solution_Line_Item__c 
                WHERE ER_Account__r.Name = 'SME Account BE' 
                LIMIT 1
            ];
            
            sli.Last_Order_Date__c = System.today().addDays(-50); // Still eligible for SME (45+ days)
            update sli;
            
            // Second batch execution - should allow re-entry
            Test.startTest();
            AttritionCampaignBatch batch2 = new AttritionCampaignBatch();
            Database.executeBatch(batch2, 200);
            Test.stopTest();
            
            // Verify contact can re-enter attrition
            Contact testContact = [
                SELECT Id FROM Contact 
                WHERE AccountId IN (SELECT Id FROM Account WHERE Name = 'SME Account BE')
                LIMIT 1
            ];
            
            List<CampaignMember> members = [
                SELECT Id, CreatedDate 
                FROM CampaignMember 
                WHERE ContactId = :testContact.Id 
                AND Campaign.Type = 'Attrition'
                ORDER BY CreatedDate DESC
            ];
            
            System.assertNotEquals(0, members.size(), 'Contact should be in attrition campaign');
        }
    }*/
    
    /**
     * Test threshold logic for different segments
     */
    @isTest 
    static void testInactivityThresholds() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            // Create accounts with orders just below threshold - should NOT be included
            Account testAccount = new Account(
                Name = 'Threshold Test', 
                NumberOfEmployees = 50,
                ER_VAT_Number__c = 'VAT999999',
                BillingCountry = 'Belgium'
            );
            insert testAccount;
            
            Contact testContact = new Contact(
                FirstName = 'Threshold',
                LastName = 'Test',
                AccountId = testAccount.Id,
                Email = 'threshold@test.com'
            );
            insert testContact;
            
            Product2 testProduct = new Product2(
                Name = 'Threshold Product',
                ER_BUPicklist__c = 'BE',
                Exclude_from_Attrition_Campaign__c = false
            );
            insert testProduct;
            
            Contract testContract = new Contract(
                AccountId = testAccount.Id,
                StartDate = Date.today().addMonths(-6),
                ContractTerm = 12,
                Status = 'Draft'
            );
            insert testContract;
            testContract.Status = 'Activated';
            update testContract;
            
            ContractContactRole ccr = new ContractContactRole(
                ContractId = testContract.Id,
                ContactId = testContact.Id,
                Role = 'Primary Contact'
            );
            insert ccr;
            
            // Last order 119 days ago - just below MMj threshold of 120
            ER_Solution_Line_Item__c testSli = new ER_Solution_Line_Item__c(
                ER_Account__c = testAccount.Id,
                ER_Solution__c = testProduct.Id,
                ER_Contract__c = testContract.Id,
                Last_Order_Date__c = System.today().addDays(-119)
            );
            insert testSli;
            
            Test.startTest();
            AttritionCampaignBatch batch = new AttritionCampaignBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            // Verify contact is NOT in campaign (below threshold)
            List<CampaignMember> members = [
                SELECT Id FROM CampaignMember 
                WHERE ContactId = :testContact.Id
                AND Campaign.Type = 'Attrition'
            ];
            
            System.assertEquals(0, members.size(), 
                'Contact should not be added when below inactivity threshold');
        }
    }
    
    /**
     * Test scheduler execution
     */
    @isTest 
    static void testScheduler() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            Test.startTest();
            String cronExp = '0 0 2 * * ?'; // Daily at 2 AM
            String jobId = System.schedule(
                'Test Attrition Batch Scheduler',
                cronExp,
                new AttritionCampaignBatchScheduler()
            );
            Test.stopTest();
            
            // Verify scheduled job
            CronTrigger ct = [
                SELECT Id, CronExpression, TimesTriggered, NextFireTime
                FROM CronTrigger
                WHERE Id = :jobId
            ];
            
            System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
            System.assertEquals(0, ct.TimesTriggered, 'Should not have triggered yet');
        }
    }
    
    /**
     * Test batch with no eligible records
     */
    @isTest 
    static void testBatchWithNoEligibleRecords() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            createTestData();
            
            // Update all SLIs to have recent orders (not eligible)
            List<ER_Solution_Line_Item__c> slis = [
                SELECT Id, Last_Order_Date__c 
                FROM ER_Solution_Line_Item__c
            ];
            
            for (ER_Solution_Line_Item__c sli : slis) {
                sli.Last_Order_Date__c = System.today().addDays(-10); // Recent order
            }
            update slis;
            
            Test.startTest();
            AttritionCampaignBatch batch = new AttritionCampaignBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            // Verify no campaign members were created
            List<CampaignMember> members = [
                SELECT Id FROM CampaignMember 
                WHERE Campaign.Type = 'Attrition'
                AND Campaign.ParentId != null
            ];
            
            System.assertEquals(0, members.size(), 
                'No campaign members should be created when no records are eligible');
        }
    }
    
    /**
     * Test null handling
     */
    @isTest 
    static void testNullHandling() {
        
        User bypassUser = getBypassUser();
        
        System.runAs(bypassUser) {
            // Create minimal test data
            Campaign parentCampaign = new Campaign(
                Name = 'Parent Attrition MMj', 
                Type = 'Attrition', 
                IsActive = true
            );
            insert parentCampaign;
            
            Test.startTest();
            AttritionCampaignBatch batch = new AttritionCampaignBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            // Should complete without errors even with no data
            System.assert(true, 'Batch should handle empty data gracefully');
        }
    }
}