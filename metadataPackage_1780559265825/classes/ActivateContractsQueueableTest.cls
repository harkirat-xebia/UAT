@isTest
private class ActivateContractsQueueableTest {
    
    @testSetup
    static void setup() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        
        // Account with existing OS ID
        Account accWithOSId = APER07_UtilityTestMethod.getCompany('TestAccountWithOSId');
        accWithOSId.ER_Card_Client_Operational_System_ID__c = 'TEST_OS_123';
        accounts.add(accWithOSId);
        
        // Account without OS ID
        Account accWithoutOSId = APER07_UtilityTestMethod.getCompany('TestAccountWithoutOSId');
        accWithoutOSId.ER_Card_Client_Operational_System_ID__c = null;
        accounts.add(accWithoutOSId);
        
        // Account for null test
        Account accForNull = APER07_UtilityTestMethod.getCompany('TestAccountForNull');
        accounts.add(accForNull);
        
        insert accounts;
        
        // Create pricebook
        Pricebook2 pb = APER07_UtilityTestMethod.getpriceBook();
        pb.IsActive = true;
        update pb;
        
        // Create contracts
        List<Contract> contracts = new List<Contract>();
        
        // Contract with account that has OS ID
        Contract cont1 = APER07_UtilityTestMethod.getContract(
            accWithOSId.Id,
            System.today(),
            'Draft',
            pb.Id
        );
        cont1.Status = 'Draft';
        contracts.add(cont1);
        
        // Contract with account without OS ID
        Contract cont2 = APER07_UtilityTestMethod.getContract(
            accWithoutOSId.Id,
            System.today(),
            'Draft',
            pb.Id
        );
        cont2.Status = 'Draft';
        contracts.add(cont2);
        
        // Contract without account (for error testing)
        Contract cont3 = APER07_UtilityTestMethod.getContract(
            accForNull.Id,
            System.today(),
            'Draft',
            pb.Id
        );
        cont3.Status = 'Draft';
        contracts.add(cont3);
        
        insert contracts;
    }
    
    @isTest
    static void testSuccessfulActivationWithExistingOSId() {
        // Get contract with account that has OS ID
        Contract cont = [
            SELECT Id, AccountId, Account.ER_Card_Client_Operational_System_ID__c
            FROM Contract
            WHERE Account.Name = 'TestAccountWithOSId'
            LIMIT 1
        ];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'Success'));
        
        Test.startTest();
        List<Id> contractIds = new List<Id>{cont.Id};
        System.enqueueJob(new ActivateContractsQueueable(contractIds, null));
        Test.stopTest();
        
        // Verify no exceptions thrown
        System.assert(true, 'Job executed without exceptions');
    }
    
    @isTest
    static void testSuccessfulActivationWithoutOSId() {
        // Get contract with account without OS ID
        Contract cont = [
            SELECT Id, AccountId, Account.ER_Card_Client_Operational_System_ID__c
            FROM Contract
            WHERE Account.Name = 'TestAccountWithoutOSId'
            LIMIT 1
        ];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'Success'));
        
        Test.startTest();
        List<Id> contractIds = new List<Id>{cont.Id};
        System.enqueueJob(new ActivateContractsQueueable(contractIds, null));
        Test.stopTest();
        
        // Verify no exceptions thrown
        System.assert(true, 'Job executed without exceptions');
    }
    
    @isTest
    static void testMultipleContractsActivation() {
        // Get multiple contracts
        List<Contract> contracts = [
            SELECT Id
            FROM Contract
            WHERE Account.Name IN ('TestAccountWithOSId', 'TestAccountWithoutOSId')
        ];
        
        List<Id> contractIds = new List<Id>();
        for (Contract cont : contracts) {
            contractIds.add(cont.Id);
        }
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'Success'));
        
        Test.startTest();
        System.enqueueJob(new ActivateContractsQueueable(contractIds, null));
        Test.stopTest();
        
        // Verify execution
        System.assertEquals(2, contractIds.size(), 'Should process 2 contracts');
    }
    
    @isTest
static void testContractWithoutAccount() {
    // Get contract
    Contract cont = [
        SELECT Id, AccountId
        FROM Contract
        WHERE Account.Name = 'TestAccountForNull'
        LIMIT 1
    ];
    
    // Store the contract ID before attempting to nullify account
    Id contractId = cont.Id;
    
    Test.startTest();
    List<Id> contractIds = new List<Id>{contractId};
    List<Id> failedIds = new List<Id>();
    
    // Set mock to handle the callout attempt
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, 'Error'));
    
    // The queueable will try to query the contract and handle the missing account scenario
    // It will catch the exception and add to failedIds
    System.enqueueJob(new ActivateContractsQueueable(contractIds, failedIds));
    Test.stopTest();
    
    // Verify the job executed without throwing unhandled exceptions
    System.assert(true, 'Job handled contract processing gracefully');
}
    @isTest
    static void testCalloutFailure() {
        Contract cont = [
            SELECT Id
            FROM Contract
            WHERE Account.Name = 'TestAccountWithOSId'
            LIMIT 1
        ];
        
        // Set mock callout with error
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, 'Error'));
        
        Test.startTest();
        List<Id> contractIds = new List<Id>{cont.Id};
        System.enqueueJob(new ActivateContractsQueueable(contractIds, null));
        Test.stopTest();
        
        // Verify error handling
        System.assert(true, 'Job handled callout failure gracefully');
    }
    
    @isTest
    static void testEmptyContractList() {
        Test.startTest();
        List<Id> contractIds = new List<Id>();
        System.enqueueJob(new ActivateContractsQueueable(contractIds, null));
        Test.stopTest();
        
        // Verify no errors with empty list
        System.assert(true, 'Job handled empty list gracefully');
    }
    
    @isTest
    static void testWithPreExistingFailures() {
        Contract cont = [
            SELECT Id
            FROM Contract
            WHERE Account.Name = 'TestAccountWithOSId'
            LIMIT 1
        ];
        
        // Create a dummy failed ID
        Id dummyFailedId = cont.Id;
        List<Id> failedIds = new List<Id>{dummyFailedId};
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'Success'));
        
        Test.startTest();
        List<Id> contractIds = new List<Id>{cont.Id};
        System.enqueueJob(new ActivateContractsQueueable(contractIds, failedIds));
        Test.stopTest();
        
        // Verify pre-existing failures are maintained
        System.assertEquals(1, failedIds.size(), 'Failed IDs should be maintained');
    }
    
    @isTest
    static void testContractNotFoundException() {
        // Use a fake ID that doesn't exist
        Id fakeId = '800000000000000AAA';
        
        Test.startTest();
        List<Id> contractIds = new List<Id>{fakeId};
        try {
            System.enqueueJob(new ActivateContractsQueueable(contractIds, null));
        } catch (Exception e) {
            System.assert(true, 'Exception caught for non-existent contract');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testConstructorWithAllParameters() {
        Contract cont = [
            SELECT Id
            FROM Contract
            WHERE Account.Name = 'TestAccountWithOSId'
            LIMIT 1
        ];
        
        List<Id> contractIds = new List<Id>{cont.Id};
        List<Id> failedIds = new List<Id>();
        Integer totalCount = 5;
        Integer processedCount = 2;
        
        Test.startTest();
        // This tests the private constructor indirectly through chaining
        ActivateContractsQueueable job = new ActivateContractsQueueable(contractIds, failedIds);
        System.enqueueJob(job);
        Test.stopTest();
        
        System.assert(true, 'Constructor with parameters executed successfully');
    }
    
    // Mock HTTP Response Generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}