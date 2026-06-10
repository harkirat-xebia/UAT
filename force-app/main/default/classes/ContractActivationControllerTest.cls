@isTest
private class ContractActivationControllerTest {
    
    @testSetup
static void setup() {
    // Create test account
    Account testAccount = APER07_UtilityTestMethod.getCompany('TestAccount');
    insert testAccount;
    
    // Create pricebook
    Pricebook2 pb = APER07_UtilityTestMethod.getpriceBook();
    pb.IsActive = true;
    update pb;
    
    // Create multiple contracts with different statuses
    List<Contract> contracts = new List<Contract>();
    
    // Contract 1 - Draft with Synchronized status
    Contract cont1 = APER07_UtilityTestMethod.getContract(
        testAccount.Id,
        System.today(),
        'Draft',
        pb.Id
    );
    cont1.Status = 'Draft';
    cont1.ER_WS_StatusCode__c = 'Synchronized';
    contracts.add(cont1);
    
    // Contract 2 - Draft with Pending Synchronization
    Contract cont2 = APER07_UtilityTestMethod.getContract(
        testAccount.Id,
        System.today(),
        'Draft',
        pb.Id
    );
    cont2.Status = 'Draft';
    cont2.ER_WS_StatusCode__c = 'Pending Synchronization';
    contracts.add(cont2);
    
    // Contract 3 - Draft with Not Synchronized
    Contract cont3 = APER07_UtilityTestMethod.getContract(
        testAccount.Id,
        System.today(),
        'Draft',
        pb.Id
    );
    cont3.Status = 'Draft';
    cont3.ER_WS_StatusCode__c = 'Not Synchronized';
    contracts.add(cont3);
    
    insert contracts;
    
    // Update one to Activated status
    cont2.Status = 'Activated';
    update cont2;
}
    @isTest
    static void testGetContractStatusesSingleContract() {
        // Get a single contract
        Contract testContract = [
            SELECT Id, ContractNumber, Status
            FROM Contract
            WHERE Status = 'Draft'
            LIMIT 1
        ];
        
        Test.startTest();
        List<Id> contractIds = new List<Id>{testContract.Id};
        List<ContractActivationController.ContractWrapper> results = 
            ContractActivationController.getContractStatuses(contractIds);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return 1 contract');
        System.assertEquals(testContract.Id, results[0].contractId, 'Contract ID should match');
        System.assertEquals(testContract.ContractNumber, results[0].contractNumber, 'Contract number should match');
        System.assertEquals(testContract.Status, results[0].status, 'Status should match');
        System.assertNotEquals(null, results[0].recordUrl, 'Record URL should not be null');
        System.assert(results[0].recordUrl.contains(testContract.Id), 'URL should contain contract ID');
    }
    
    @isTest
    static void testGetContractStatusesMultipleContracts() {
        // Get all contracts
        List<Contract> testContracts = [
            SELECT Id, ContractNumber, Status, Contract_Category__c, ER_WS_StatusCode__c
            FROM Contract
        ];
        
        List<Id> contractIds = new List<Id>();
        for (Contract con : testContracts) {
            contractIds.add(con.Id);
        }
        
        Test.startTest();
        List<ContractActivationController.ContractWrapper> results = 
            ContractActivationController.getContractStatuses(contractIds);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(3, results.size(), 'Should return 3 contracts');
        
        // Verify all contracts are returned
        Set<Id> returnedIds = new Set<Id>();
        for (ContractActivationController.ContractWrapper wrapper : results) {
            returnedIds.add(wrapper.contractId);
            System.assertNotEquals(null, wrapper.contractNumber, 'Contract number should not be null');
            System.assertNotEquals(null, wrapper.status, 'Status should not be null');
            System.assertNotEquals(null, wrapper.recordUrl, 'Record URL should not be null');
        }
        
        for (Id contractId : contractIds) {
            System.assert(returnedIds.contains(contractId), 'All contract IDs should be returned');
        }
    }
    
    @isTest
static void testGetContractStatusesWithAllFields() {
    // Get contract with all fields populated
    Contract testContract = [
        SELECT Id, ContractNumber, Status, Contract_Category__c, 
               ER_WS_StatusCode__c, LastModifiedDate
        FROM Contract
        WHERE ER_WS_StatusCode__c = 'Pending Synchronization'
        LIMIT 1
    ];
    
    Test.startTest();
    List<Id> contractIds = new List<Id>{testContract.Id};
    List<ContractActivationController.ContractWrapper> results = 
        ContractActivationController.getContractStatuses(contractIds);
    Test.stopTest();
    
    // Assertions - verify all fields are populated
    System.assertEquals(1, results.size(), 'Should return 1 contract');
    ContractActivationController.ContractWrapper wrapper = results[0];
    
    System.assertEquals(testContract.Id, wrapper.contractId, 'Contract ID should match');
    System.assertEquals(testContract.ContractNumber, wrapper.contractNumber, 'Contract number should match');
    System.assertEquals(testContract.Status, wrapper.status, 'Status should match');
    System.assertEquals(testContract.Contract_Category__c, wrapper.contractCategory, 'Category should match');
    System.assertEquals('Pending Synchronization', wrapper.syncStatusCode, 'Status code should match');
    System.assertEquals(testContract.LastModifiedDate, wrapper.lastModifiedDate, 'Last modified date should match');
    System.assertEquals('/' + testContract.Id, wrapper.recordUrl, 'Record URL should match');
}
    @isTest
    static void testGetContractStatusesEmptyList() {
        Test.startTest();
        List<Id> contractIds = new List<Id>();
        List<ContractActivationController.ContractWrapper> results = 
            ContractActivationController.getContractStatuses(contractIds);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }
    
    @isTest
    static void testGetContractStatusesNonExistentIds() {
        // Create fake contract IDs that don't exist
        List<Id> contractIds = new List<Id>{
            '800000000000000AAA',
            '800000000000000AAB'
        };
        
        Test.startTest();
        List<ContractActivationController.ContractWrapper> results = 
            ContractActivationController.getContractStatuses(contractIds);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(0, results.size(), 'Should return empty list for non-existent IDs');
    }
    
    @isTest
    static void testGetContractStatusesMixedValidInvalidIds() {
        // Get one valid contract
        Contract validContract = [
            SELECT Id
            FROM Contract
            LIMIT 1
        ];
        
        // Mix valid and invalid IDs
        List<Id> contractIds = new List<Id>{
            validContract.Id,
            '800000000000000AAA'
        };
        
        Test.startTest();
        List<ContractActivationController.ContractWrapper> results = 
            ContractActivationController.getContractStatuses(contractIds);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return only valid contract');
        System.assertEquals(validContract.Id, results[0].contractId, 'Should return the valid contract');
    }
    
    @isTest
    static void testGetContractStatusesWithDifferentStatuses() {
        // Get contracts with different statuses
        List<Contract> testContracts = [
            SELECT Id, Status
            FROM Contract
        ];
        
        List<Id> contractIds = new List<Id>();
        for (Contract con : testContracts) {
            contractIds.add(con.Id);
        }
        
        Test.startTest();
        List<ContractActivationController.ContractWrapper> results = 
            ContractActivationController.getContractStatuses(contractIds);
        Test.stopTest();
        
        // Verify different statuses are returned
        Set<String> statuses = new Set<String>();
        for (ContractActivationController.ContractWrapper wrapper : results) {
            statuses.add(wrapper.status);
        }
        
        System.assert(statuses.size() > 0, 'Should have at least one status');
        System.assert(statuses.contains('Draft') || statuses.contains('Activated'), 
                     'Should contain expected statuses');
    }
    
    @isTest
    static void testContractWrapperInstantiation() {
        // Test wrapper class can be instantiated and fields set
        Test.startTest();
        ContractActivationController.ContractWrapper wrapper = 
            new ContractActivationController.ContractWrapper();
        
        wrapper.contractId = '800000000000000AAA';
        wrapper.contractNumber = 'TEST-001';
        wrapper.status = 'Draft';
        wrapper.contractCategory = 'Standard';
        wrapper.syncStatusCode = '200';
        wrapper.lastModifiedDate = System.now();
        wrapper.recordUrl = '/800000000000000AAA';
        Test.stopTest();
        
        // Assertions
        System.assertEquals('800000000000000AAA', wrapper.contractId, 'Contract ID should be set');
        System.assertEquals('TEST-001', wrapper.contractNumber, 'Contract number should be set');
        System.assertEquals('Draft', wrapper.status, 'Status should be set');
        System.assertEquals('Standard', wrapper.contractCategory, 'Category should be set');
        System.assertEquals('200', wrapper.syncStatusCode, 'Status code should be set');
        System.assertNotEquals(null, wrapper.lastModifiedDate, 'Last modified date should be set');
        System.assertEquals('/800000000000000AAA', wrapper.recordUrl, 'Record URL should be set');
    }
    
    @isTest
    static void testExceptionHandling() {
        // This test verifies exception handling by passing null
        // Note: In practice, this would be caught by the LWC/Aura component
        Test.startTest();
        try {
            List<ContractActivationController.ContractWrapper> results = 
                ContractActivationController.getContractStatuses(null);
            // If no exception, verify empty result
            System.assertEquals(0, results.size(), 'Should handle null gracefully');
        } catch (Exception e) {
            // Exception is expected and handled
            System.assert(e instanceof AuraHandledException || e instanceof NullPointerException, 
                         'Should throw appropriate exception');
        }
        Test.stopTest();
    }
}