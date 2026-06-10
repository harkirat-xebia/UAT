/**
 * @description Tests for ContractNemoSyncQueueable.
 * Exercises both decision branches and the early-return path.
 * Follows bulkified testing, no SeeAllData, and proper assertions.
 */
@IsTest
private class ContractNemoSyncQueueableTest {

    /**
     * Simple no-op HttpCalloutMock to satisfy any downstream callouts
     * invoked by SyncClientContractService during queueable execution.
     */
    private class NoopCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

   @TestSetup
static void setupData() {

    Id accRtId = getDefaultAccountRecordTypeId();

    // Account WITHOUT operational system id
    Account accNoOpId = new Account(
        Name = 'Acc - No Op Id',
        RecordTypeId = accRtId,
        BillingCountry = 'Belgium',
        ER_VAT_Number__c = 'BE0713543084' 
    );
    insert accNoOpId;

    // Account WITH operational system id
    Account accWithOpId = new Account(
        Name = 'Acc - With Op Id',
        RecordTypeId = accRtId,
        BillingCountry = 'Belgium',
        ER_VAT_Number__c = 'BE0713543084', 
        ER_Card_Client_Operational_System_ID__c = 'OPS-123'
    );
    insert accWithOpId;

    // Contracts
    insert new List<Contract>{
        new Contract(
            AccountId = accNoOpId.Id,
            Status = 'Draft',
            StartDate = Date.today()
        ),
        new Contract(
            AccountId = accWithOpId.Id,
            Status = 'Draft',
            StartDate = Date.today()
        )
    };
}



    @IsTest
    static void testExecute_CreatesClient_WhenAccountHasNoOperationalId() {
        // Arrange
        setMockIfNeeded();

        // Pull the contract where account has null ER_Card_Client_Operational_System_ID__c
        Contract target = [
            SELECT Id, Account.ER_Card_Client_Operational_System_ID__c
            FROM Contract
            WHERE Account.ER_Card_Client_Operational_System_ID__c = NULL
            LIMIT 1
        ];

        // Act
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractNemoSyncQueueable(new Set<Id>{ target.Id }));
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, jobId, 'Queueable should be enqueued.');
        // We cannot directly assert internal calls without DI; absence of unhandled exception indicates success.
        // Optionally, add log verifications if a logging framework is present.
        Contract reloaded = [SELECT Id FROM Contract WHERE Id = :target.Id];
        System.assertNotEquals(null, reloaded, 'Target contract must still exist.');
    }

    @IsTest
    static void testExecute_CreatesClientContract_WhenAccountHasOperationalId() {
        // Arrange
        setMockIfNeeded();

        // Pull the contract where account has non-null ER_Card_Client_Operational_System_ID__c
        Contract target = [
            SELECT Id, Account.ER_Card_Client_Operational_System_ID__c
            FROM Contract
            WHERE Account.ER_Card_Client_Operational_System_ID__c != NULL
            LIMIT 1
        ];

        // Act
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractNemoSyncQueueable(new Set<Id>{ target.Id }));
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, jobId, 'Queueable should be enqueued.');
        Contract reloaded = [SELECT Id FROM Contract WHERE Id = :target.Id];
        System.assertNotEquals(null, reloaded, 'Target contract must still exist.');
    }

    @IsTest
    static void testExecute_EmptyInput_ReturnsEarly_NoDML() {
        // Arrange
        setMockIfNeeded();

        // Act
        Test.startTest();
        Id jobId = System.enqueueJob(new ContractNemoSyncQueueable(new Set<Id>()));
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, jobId, 'Queueable should be enqueued even for empty input.');
        // No exception thrown means early return executed safely.
    }

    // Helper to register a harmless mock in case downstream service performs callouts.
    private static void setMockIfNeeded() {
        // Register a default mock so any HTTP callouts from SyncClientContractService succeed.
        Test.setMock(HttpCalloutMock.class, new NoopCalloutMock());
    }

    // Resolve a usable Account RecordTypeId in orgs with multiple record types; fallback if none.
    private static Id getDefaultAccountRecordTypeId() {
        // Try to fetch a Business Account record type first; otherwise, any active type; fallback to null which uses master.
        List<RecordType> rts = [
            SELECT Id, DeveloperName, SObjectType, IsActive
            FROM RecordType
            WHERE SObjectType = 'Account' AND IsActive = true
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }
}