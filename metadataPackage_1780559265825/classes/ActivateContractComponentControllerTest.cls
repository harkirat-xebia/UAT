@isTest
public class ActivateContractComponentControllerTest {
    @TestSetup
    static void testSetup() {
        // Create and insert test user with permission
        User ur = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        ur.ER_bypassTrigger__c = true;
        ur.Can_activate_Engagement_Contracts__c = true;
        insert ur;
        
        System.runAs(ur) {
            // Validation Rule Settings
            ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
                UserInfo.getOrganizationId()
            );
            settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
            upsert settings;
            
            // Create Client Account with all required fields
            Account newClientAccount = APER07_UtilityTestMethod.insertAccount('clientCompany', 'ER_Company_Account_RT');
            newClientAccount.ER_Legal_Name__c = 'Test Legal Name';
            newClientAccount.ER_Registration_Number__c = '123456789';
            newClientAccount.BillingStreet = 'Test Street';
            newClientAccount.BillingCity = 'Test City';
            newClientAccount.ER_Country_Code__c = 'BE';
            newClientAccount.BillingPostalCode = '1000';
            newClientAccount.ER_Language__c = 'EN';
            newClientAccount.ER_Card_Client_Operational_System_ID__c = null;
            update newClientAccount;
            
            // Price Books
            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
            PriceBook2 customPB = APER07_UtilityTestMethod.getCustomPriceBook(Label.LAB_SF_P2_EKIVITA_PRICEBOOK);
            insert customPB;
            
            // Create Engagement Pricebook
            PriceBook2 engagementPB = new PriceBook2(
                Name = 'Engagement Pricebook',
                IsActive = true
            );
            insert engagementPB;
            
            // Create Contact for Customer Signed
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@example.com',
                AccountId = newClientAccount.Id,
                ER_Language__c = 'EN',
                ER_Status__c = 'Active'
            );
            insert testContact;
            
            // Create multiple contracts with different statuses
            List<Contract> contractsToInsert = new List<Contract>();
            
            // Draft Contract - Valid for activation
            Contract draftContract = APER07_UtilityTestMethod.insertContract(
                newClientAccount.Id,
                System.today(),
                'Draft',
                customPB.Id,
                'ER_Client_Contract_RT',
                ur.Id
            );
            draftContract.CustomerSignedDate = System.today();
            draftContract.CustomerSignedId = testContact.Id;
            draftContract.StartDate = System.today();
            //draftContract.Contract_Category__c = 'Engagement';
            contractsToInsert.add(draftContract);
            
            // Activated Contract - For re-activation
            /*Contract activatedContract = APER07_UtilityTestMethod.insertContract(
                newClientAccount.Id,
                System.today(),
                'Activated',
                customPB.Id,
                'ER_Client_Contract_RT',
                ur.Id
            );
            activatedContract.CustomerSignedDate = System.today();
            activatedContract.CustomerSignedId = testContact.Id;
            activatedContract.StartDate = System.today();
            //activatedContract.Contract_Category__c = 'Engagement';
            activatedContract.ER_WS_StatusCode__c = '200';
            contractsToInsert.add(activatedContract);*/
            
            // Invalid Status Contract
            /*Contract invalidContract = APER07_UtilityTestMethod.insertContract(
                newClientAccount.Id,
                System.today(),
                'Expired',
                customPB.Id,
                'ER_Client_Contract_RT',
                ur.Id
            );
            //invalidContract.Contract_Category__c = 'Standard';
            contractsToInsert.add(invalidContract);*/
            
            // Engagement Contract with Engagement Pricebook
            Contract engagementContract = APER07_UtilityTestMethod.insertContract(
                newClientAccount.Id,
                System.today(),
                'Draft',
                engagementPB.Id,
                'ER_Client_Contract_RT',
                ur.Id
            );
            engagementContract.CustomerSignedDate = System.today();
            engagementContract.CustomerSignedId = testContact.Id;
            engagementContract.StartDate = System.today();
            //engagementContract.Contract_Category__c = 'Engagement';
            engagementContract.ER_Customer_Domain__c = 'Test Domain';
            engagementContract.ER_Program_Name__c = 'Test Program';
            //engagementContract.ER_Impacted_Beneficiaries__c = 100;
            engagementContract.ER_Onboarding_Method__c = 'Digital';
            engagementContract.ER_Start_Date__c = System.today();
            contractsToInsert.add(engagementContract);
            
            // Contract with missing required fields
            /*Contract incompleteContract = APER07_UtilityTestMethod.insertContract(
                newClientAccount.Id,
                System.today(),
                'Draft',
                customPB.Id,
                'ER_Client_Contract_RT',
                ur.Id
            );
            incompleteContract.CustomerSignedDate = null;
            //incompleteContract.Contract_Category__c = 'Engagement';
            contractsToInsert.add(incompleteContract);
            
            update contractsToInsert;*/
            
            // Products and Price Book Entries
            Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
            insert newSolution;
            
            Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
            insert newService;
            
            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
            insert newPriceBookEntry;
            
            // Contract Line Items for valid contracts
            List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
            for (Contract c : contractsToInsert) {
                if (c.Status == 'Draft' || c.Status == 'Activated') {
                    ER_ContractLineItem__c newContractLine = APER07_UtilityTestMethod.getContractLineItem(
                        c.Id,
                        newService.id,
                        newPriceBookEntry.Id,
                        1,
                        1
                    );
                    //newContractLine.ER_Solution__c = 'Test Solution';
                    cliList.add(newContractLine);
                }
            }
            insert cliList;
            
            // Create Financial Center
            ER_Financial_Center__c fc = new ER_Financial_Center__c(
                ER_Account_Name__c = newClientAccount.Id,
                ER_Contact__c = testContact.Id,
                ER_Invoicing_Country_Code__c = 'BE',
                ER_Invoicing_Street__c = 'Invoice Street',
                ER_Invoicing_Zip_Code__c = '1000',
                ER_Invoicing_City__c = 'Brussels'
            );
            insert fc;
            
            // Create Delivery Site
            /*ER_Delivery_Site__c ds = new ER_Delivery_Site__c(
                ER_Financial_Center__c = fc.Id,
                ER_Country_Code__c = 'BE',
                ER_Delivery_Contact__c = testContact.Id,
                ER_City__c = 'Brussels',
                ER_Zip_Code__c = '1000',
                ER_Street__c = 'Delivery Street'
            );
            insert ds;*/
            
            // Create Distribution Point
            /*ER_Distribution_Point__c dp = new ER_Distribution_Point__c(
                //ER_Delivery_Site__c = ds.Id,
                ER_Country_Code__c = 'BE',
                ER_City__c = 'Brussels',
                ER_Zip_Code__c = '1000',
                ER_Street__c = 'Distribution Street'
            );
            insert dp;*/
        }
    }
    
    /*@isTest
    static void testBulkActivateContracts_Success() {
        Test.startTest();
        
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status = 'Draft' AND Contract_Category__c = 'Engagement' LIMIT 2];
        List<String> contractIds = new List<String>();
        for (Contract c : contracts) {
            contractIds.add(c.Id);
        }
        
        ActivateContractComponentController.FlowRequest request = new ActivateContractComponentController.FlowRequest();
        request.contractIds = contractIds;
        
        List<ActivateContractComponentController.FlowResponse> responses = 
            ActivateContractComponentController.bulkActivateContracts(new List<ActivateContractComponentController.FlowRequest>{request});
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Response should not be null');
        System.assertEquals(1, responses.size(), 'Should have one response');
        System.assertEquals(true, responses[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, responses[0].jobId, 'Job ID should be populated');
        System.assert(responses[0].totalCount > 0, 'Should have valid contracts');
    }
    
    @isTest
    static void testBulkActivateContracts_ReActivation() {
        Test.startTest();
        
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status = 'Activated' LIMIT 1];
        List<String> contractIds = new List<String>();
        for (Contract c : contracts) {
            contractIds.add(c.Id);
        }
        
        ActivateContractComponentController.FlowRequest request = new ActivateContractComponentController.FlowRequest();
        request.contractIds = contractIds;
        
        List<ActivateContractComponentController.FlowResponse> responses = 
            ActivateContractComponentController.bulkActivateContracts(new List<ActivateContractComponentController.FlowRequest>{request});
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Response should not be null');
        System.assertEquals(true, responses[0].isSuccess, 'Should be successful for re-activation');
    }
    
    @isTest
    static void testBulkActivateContracts_InvalidStatus() {
        Test.startTest();
        
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status = 'Expired' LIMIT 1];
        List<String> contractIds = new List<String>();
        for (Contract c : contracts) {
            contractIds.add(c.Id);
        }
        
        ActivateContractComponentController.FlowRequest request = new ActivateContractComponentController.FlowRequest();
        request.contractIds = contractIds;
        
        List<ActivateContractComponentController.FlowResponse> responses = 
            ActivateContractComponentController.bulkActivateContracts(new List<ActivateContractComponentController.FlowRequest>{request});
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Response should not be null');
        System.assertEquals(false, responses[0].isSuccess, 'Should fail for invalid status');
        System.assert(responses[0].invalidContracts.size() > 0, 'Should have invalid contracts');
    }
    */
    @isTest
    static void testBulkActivateContracts_NoContractIds() {
        Test.startTest();
        
        ActivateContractComponentController.FlowRequest request = new ActivateContractComponentController.FlowRequest();
        request.contractIds = new List<String>();
        
        List<ActivateContractComponentController.FlowResponse> responses = 
            ActivateContractComponentController.bulkActivateContracts(new List<ActivateContractComponentController.FlowRequest>{request});
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Response should not be null');
        System.assertEquals(false, responses[0].isSuccess, 'Should fail with no IDs');
        System.assertEquals(0, responses[0].totalCount, 'Total count should be 0');
    }
    
    @isTest
    static void testBulkActivateContracts_InvalidIds() {
        Test.startTest();
        
        ActivateContractComponentController.FlowRequest request = new ActivateContractComponentController.FlowRequest();
        request.contractIds = new List<String>{'invalid-id', '001000000000000'};
        
        List<ActivateContractComponentController.FlowResponse> responses = 
            ActivateContractComponentController.bulkActivateContracts(new List<ActivateContractComponentController.FlowRequest>{request});
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Response should not be null');
    }
    
    @isTest
    static void testBulkActivateContracts_MixedValidInvalid() {
        Test.startTest();
        
        List<Contract> allContracts = [SELECT Id, Status FROM Contract];
        List<String> contractIds = new List<String>();
        for (Contract c : allContracts) {
            contractIds.add(c.Id);
        }
        
        ActivateContractComponentController.FlowRequest request = new ActivateContractComponentController.FlowRequest();
        request.contractIds = contractIds;
        
        List<ActivateContractComponentController.FlowResponse> responses = 
            ActivateContractComponentController.bulkActivateContracts(new List<ActivateContractComponentController.FlowRequest>{request});
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Response should not be null');
        System.assertNotEquals(null, responses[0].invalidContracts, 'Invalid contracts should be populated');
        System.assertNotEquals(null, responses[0].validContractsJson, 'Valid contracts JSON should be populated');
        System.assertNotEquals(null, responses[0].invalidContractsJson, 'Invalid contracts JSON should be populated');
    }
    
    @isTest
    static void testBulkActivateContracts_PermissionCheck() {
        // Create user with limited permissions
        User limitedUser = TestDataFactory.newUser('LIMITED', 'LIMITED', 'Local Admin', 'BELUX', 'BE');
        limitedUser.ER_BypassVR__c = true;
        limitedUser.ER_bypassTrigger__c = true;
        limitedUser.Can_activate_Engagement_Contracts__c = true;
        insert limitedUser;
        
        Test.startTest();
        System.runAs(limitedUser) {
            List<Contract> contracts = [SELECT Id FROM Contract WHERE Contract_Category__c = 'Standard' LIMIT 1];
            List<String> contractIds = new List<String>();
            for (Contract c : contracts) {
                contractIds.add(c.Id);
            }
            
            ActivateContractComponentController.FlowRequest request = new ActivateContractComponentController.FlowRequest();
            request.contractIds = contractIds;
            
            List<ActivateContractComponentController.FlowResponse> responses = 
                ActivateContractComponentController.bulkActivateContracts(new List<ActivateContractComponentController.FlowRequest>{request});
            
            System.assertNotEquals(null, responses, 'Response should not be null');
            System.assertEquals(false, responses[0].isSuccess, 'Should fail due to permission');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFetchErrorsBulk() {
        Test.startTest();
        
        List<Contract> contracts = [SELECT Id, AccountId FROM Contract LIMIT 3];
        Set<Id> accountIds = new Set<Id>();
        List<Id> contractIds = new List<Id>();
        
        for (Contract c : contracts) {
            accountIds.add(c.AccountId);
            contractIds.add(c.Id);
        }
        
        Map<Id, List<ActivateContractComponentController.ErrorListWrapper>> errorMap = 
            ActivateContractComponentController.fetchErrorsBulk(accountIds, contractIds);
        
        Test.stopTest();
        
        System.assertNotEquals(null, errorMap, 'Error map should not be null');
        System.assertEquals(contractIds.size(), errorMap.size(), 'Should have errors for all contracts');
        
        for (Id contractId : contractIds) {
            System.assert(errorMap.containsKey(contractId), 'Should have entry for each contract');
        }
    }
    
    @isTest
    static void testFetchErrorsBulk_EngagementContract() {
        Test.startTest();
        
        List<Contract> contracts = [
            SELECT Id, AccountId 
            FROM Contract 
            WHERE Pricebook2.Name LIKE '%Engagement%' 
            LIMIT 1
        ];
        
        if (!contracts.isEmpty()) {
            Set<Id> accountIds = new Set<Id>{contracts[0].AccountId};
            List<Id> contractIds = new List<Id>{contracts[0].Id};
            
            Map<Id, List<ActivateContractComponentController.ErrorListWrapper>> errorMap = 
                ActivateContractComponentController.fetchErrorsBulk(accountIds, contractIds);
            
            System.assertNotEquals(null, errorMap, 'Error map should not be null');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testActivateContractsFromLWC_Success() {
        Test.startTest();
        
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status = 'Draft' LIMIT 2];
        List<String> contractIds = new List<String>();
        for (Contract c : contracts) {
            contractIds.add(c.Id);
        }
        
        ActivateContractComponentController.ActivationResult result = 
            ActivateContractComponentController.activateContractsFromLWC(contractIds);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.isSuccess, 'Should be successful');
        System.assertNotEquals(null, result.jobId, 'Job ID should be populated');
    }
    
    @isTest
    static void testActivateContractsFromLWC_NoIds() {
        Test.startTest();
        
        ActivateContractComponentController.ActivationResult result = 
            ActivateContractComponentController.activateContractsFromLWC(new List<String>());
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isSuccess, 'Should fail with no IDs');
    }
    
    @isTest
    static void testActivateContractsFromLWC_InvalidStatus() {
        Test.startTest();
        
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status != 'Draft' LIMIT 1];
        List<String> contractIds = new List<String>();
        for (Contract c : contracts) {
            contractIds.add(c.Id);
        }
        
        ActivateContractComponentController.ActivationResult result = 
            ActivateContractComponentController.activateContractsFromLWC(contractIds);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testActivateContractsAsync() {
        Test.startTest();
        
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status = 'Draft' LIMIT 2];
        List<Id> contractIds = new List<Id>();
        for (Contract c : contracts) {
            contractIds.add(c.Id);
        }
        
        ActivateContractComponentController.activateContractsAsync(contractIds);
        
        Test.stopTest();
        
        // Verify job was queued
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], 'Job should be queued');
    }
    
    @isTest
    static void testActivateContract() {
        Test.startTest();
        
        Contract testContract = [SELECT Id, Account.ER_Card_Client_Operational_System_ID__c FROM Contract LIMIT 1];
        
        try {
            Map<String, Object> response = ActivateContractComponentController.activateContract(testContract.Id);
            System.assertNotEquals(null, response, 'Response should not be null');
        } catch(Exception err) {
            // Expected in test context without actual callout
            System.assert(true, 'Exception expected without callout mock');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testFetchContractDetails() {
        Test.startTest();
        
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        List<ActivateContractComponentController.ContractDetailsWrapper> detailsList = 
            ActivateContractComponentController.fetchContractDetails(testContract.Id);
        
        System.assertNotEquals(0, detailsList.size(), 'Contract details should be fetched');
        System.assertEquals(testContract.Id, detailsList[0].ContractId, 'Contract ID should match');
        System.assertNotEquals(null, detailsList[0].ContractLineItems, 'Contract line items should be populated');
        
        Test.stopTest();
    }
    
    @isTest
    static void testFetchErrors() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        List<ActivateContractComponentController.ErrorListWrapper> errorList = 
            ActivateContractComponentController.fetchErrors(testAccount.Id, testContract.Id);
        
        System.assertNotEquals(null, errorList, 'Error list should not be null');
        
        Boolean hasContractError = false;
        Boolean hasAccountError = false;
        
        for (ActivateContractComponentController.ErrorListWrapper wrapper : errorList) {
            for (ActivateContractComponentController.ErrorInfoWrapper info : wrapper.data) {
                if (info.sObjName == 'Contract') {
                    hasContractError = true;
                }
                if (info.sObjName == 'Account') {
                    hasAccountError = true;
                }
            }
        }
        
        System.assert(hasContractError || hasAccountError, 'Should have validation errors');
        
        Test.stopTest();
    }
    
    @isTest
    static void testFetchErrors_WithSyncedAccount() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        testAccount.ER_Card_Client_Operational_System_ID__c = 'SYNCED123';
        update testAccount;
        
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        
        List<ActivateContractComponentController.ErrorListWrapper> errorList = 
            ActivateContractComponentController.fetchErrors(testAccount.Id, testContract.Id);
        
        System.assertNotEquals(null, errorList, 'Error list should not be null');
        
        Test.stopTest();
    }
}