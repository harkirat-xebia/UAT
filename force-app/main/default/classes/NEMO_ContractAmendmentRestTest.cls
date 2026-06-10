@IsTest
private class NEMO_ContractAmendmentRestTest {

    private static User createBypassUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            Username = 'bypass' + System.currentTimeMillis() + '@test.com',
            Email = 'bypass@test.com',
            LastName = 'Bypass',
            Alias = 'bypas',
            TimeZoneSidKey = 'Europe/Brussels',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        // Make user bypass VR
        u.put('ER_BypassVR__c', true);

        if (Schema.SObjectType.User.fields.getMap().containsKey('ER_Business_Unit__c')) {
            u.put('ER_Business_Unit__c', 'BE');
        }

        insert u;
        return u;
    }

    /**
     * Assigns Custom Permission NEMO_AMEND_API to the user by:
     * - finding CustomPermission by DeveloperName
     * - finding any PermissionSet that grants it (SetupEntityAccess)
     * - creating PermissionSetAssignment
     *
     * If nothing is found, does nothing (test will then cover PERMISSION_DENIED path).
     */
    
    private static Id tweakId(Id realId) {
    String s = (String)realId;
    String last = s.substring(s.length()-1);
    String newLast = (last == 'A') ? 'B' : 'A';
    return (Id)(s.substring(0, s.length()-1) + newLast);
}
    
    private static void assignNemoAmendPermissionIfPossible(User u) {
        List<CustomPermission> cps = [
            SELECT Id, DeveloperName
            FROM CustomPermission
            WHERE DeveloperName = 'NEMO_AMEND_API'
            LIMIT 1
        ];
        if (cps.isEmpty()) return;

        List<SetupEntityAccess> sea = [
            SELECT ParentId
            FROM SetupEntityAccess
            WHERE SetupEntityId = :cps[0].Id
              AND SetupEntityType = 'CustomPermission'
            LIMIT 1
        ];
        if (sea.isEmpty()) return;

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = sea[0].ParentId
        );
        insert psa;
    }

    private static Account createAccount() {
        Account a = new Account(Name = 'TestAccount');

        // Satisfy  VAT/Registration VR
        if (Schema.SObjectType.Account.fields.getMap().containsKey('ER_VAT_Number__c')) {
            a.put('ER_VAT_Number__c', 'BE0123456789');
        } else if (Schema.SObjectType.Account.fields.getMap().containsKey('ER_Registration_Number__c')) {
            a.put('ER_Registration_Number__c', 'BE0123456789');
        }

        insert a;
        return a;
    }

    private static Contract createContract(Account a) {
    Contract c = new Contract(
        AccountId = a.Id,
        StartDate = Date.today()
    );

    if (Schema.SObjectType.Contract.fields.getMap().containsKey('ER_Customer_Domain__c')) {
        DescribeFieldResult d = Schema.SObjectType.Contract.fields.getMap().get('ER_Customer_Domain__c').getDescribe();
        if (!d.isCalculated() && d.isCreateable()) {
            c.put('ER_Customer_Domain__c', 'testaccount');
        }
    }

    insert c;
    return c;
}

    private static void setRestContext(String jsonBody) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/nemo/v1/contract-amendments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    // -------------------------
    // Tests
    // -------------------------

    @IsTest
static void test_ContractNotFound_404_AndLogCreated() {
    User u = createBypassUser();
    assignNemoAmendPermissionIfPossible(u);

    System.runAs(u) {
        Account a = createAccount();
        Contract real = createContract(a);
        Id fakeContractId = tweakId(real.Id); // valid format, but not existing

        String body = JSON.serialize(new Map<String,Object>{
            'requestId' => 'REQ-NOTFOUND-001',
            'contractId' => (String)fakeContractId,
            'changes' => new List<Object>{
                new Map<String,Object>{
                    'match' => new Map<String,Object>{ 'product2Id' => '01t000000000000AAA' },
                    'updates' => new Map<String,Object>{ 'quantity' => 2 }
                }
            }
        });
        setRestContext(body);

        Test.startTest();
        NEMO_ContractAmendmentRest.amend();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('CONTRACT_NOT_FOUND'));

        // log should exist
        Integration_Log__c logRec = [
            SELECT Status__c, Status_Message__c
            FROM Integration_Log__c
            WHERE Correlation_Id__c = 'REQ-NOTFOUND-001'
            LIMIT 1
        ];
        System.assertEquals('Error', logRec.Status__c);
        System.assertEquals('CONTRACT_NOT_FOUND', logRec.Status_Message__c);
    }
}
    
    @IsTest
    static void test_Idempotency_ReturnsStoredSuccessResponse() {
        User u = createBypassUser();
        assignNemoAmendPermissionIfPossible(u);

        System.runAs(u) {
            // Insert an existing SUCCESS log for requestId
            Integration_Log__c il = new Integration_Log__c();
            il.put('Correlation_Id__c', 'REQ-SUCCESS-001');
            if (Schema.SObjectType.Integration_Log__c.fields.getMap().containsKey('Endpoint__c')) {
                il.put('Endpoint__c', 'dummy');
            }
            if (Schema.SObjectType.Integration_Log__c.fields.getMap().containsKey('Method__c')) {
                il.put('Method__c', 'POST');
            }
            il.put('Status__c', 'Success');
            il.put('Response_Body__c', '{"status":"SUCCESS","requestId":"REQ-SUCCESS-001"}');
            insert il;

            String body = JSON.serialize(new Map<String,Object>{
                'requestId' => 'REQ-SUCCESS-001',
                'contractId' => '800000000000000AAA',
                'changes' => new List<Object>{ new Map<String,Object>{ 'match' => new Map<String,Object>{ 'product2Id' => '01t000000000000AAA' } } }
            });
            setRestContext(body);

            Test.startTest();
            NEMO_ContractAmendmentRest.amend();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode, 'Should return stored response');
            System.assert(RestContext.response.responseBody.toString().contains('"REQ-SUCCESS-001"'));
        }
    }

    @IsTest
    static void test_DuplicateRequestId_Returns409_AndUpdatesExistingLog() {
        User u = createBypassUser();
        assignNemoAmendPermissionIfPossible(u);

        System.runAs(u) {
            // Existing NON-success log
            Integration_Log__c il = new Integration_Log__c();
            il.put('Correlation_Id__c', 'REQ-DUP-001');
            if (Schema.SObjectType.Integration_Log__c.fields.getMap().containsKey('Endpoint__c')) {
                il.put('Endpoint__c', 'dummy');
            }
            if (Schema.SObjectType.Integration_Log__c.fields.getMap().containsKey('Method__c')) {
                il.put('Method__c', 'POST');
            }
            il.put('Status__c', 'Error');
            il.put('Response_Body__c', '{"status":"ERROR","requestId":"REQ-DUP-001"}');
            insert il;

            String body = JSON.serialize(new Map<String,Object>{
                'requestId' => 'REQ-DUP-001',
                'contractId' => '800000000000000AAA',
                'changes' => new List<Object>{ new Map<String,Object>{ 'match' => new Map<String,Object>{ 'product2Id' => '01t000000000000AAA' } } }
            });
            setRestContext(body);

            Test.startTest();
            NEMO_ContractAmendmentRest.amend();
            Test.stopTest();

            System.assertEquals(409, RestContext.response.statusCode);
            System.assert(RestContext.response.responseBody.toString().contains('DUPLICATE_REQUEST_ID'));

            // Verify existing log updated with 409
            Integration_Log__c updated = [SELECT Status_Code__c, Status_Message__c, Response_Body__c
                                          FROM Integration_Log__c WHERE Id = :il.Id LIMIT 1];
            System.assertEquals(409, Integer.valueOf(updated.Status_Code__c));
            System.assertEquals('DUPLICATE_REQUEST_ID', updated.Status_Message__c);
        }
    }

    @IsTest
static void test_PermissionDenied_403() {
    User u = createBypassUser();

    System.runAs(u) {
        String body = JSON.serialize(new Map<String,Object>{
            'requestId' => 'REQ-PERM-001',
            'contractId' => '800000000000000AAA',
            'changes' => new List<Object>{
                new Map<String,Object>{ 'match' => new Map<String,Object>{ 'product2Id' => '01t000000000000AAA' } }
            }
        });
        setRestContext(body);

        Test.startTest();
        NEMO_ContractAmendmentRest.amend();
        Test.stopTest();

        System.assertEquals(403, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('PERMISSION_DENIED'));
    }
}
    @IsTest
static void test_InvalidJson_400() {
    User u = createBypassUser();
    assignNemoAmendPermissionIfPossible(u);

    System.runAs(u) {
        setRestContext('{"requestId":'); // broken JSON

        Test.startTest();
        NEMO_ContractAmendmentRest.amend();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Invalid JSON'));
    }
}
    
    @IsTest
    static void test_ContractNotActive_Returns400_AndCreatesLog() {
        User u = createBypassUser();
        assignNemoAmendPermissionIfPossible(u);

        System.runAs(u) {
            Account a = createAccount();

            // Create a NOT Activated contract
            // Use a status value different from your label (commonly Draft)
            String notActiveStatus = 'Draft';
            Contract c = createContract(a);

            String body = JSON.serialize(new Map<String,Object>{
                'requestId' => 'REQ-NOTACTIVE-001',
                'contractId' => c.Id,
                'changes' => new List<Object>{
                    new Map<String,Object>{
                        'match' => new Map<String,Object>{ 'product2Id' => '01t000000000000AAA' },
                        'updates' => new Map<String,Object>{ 'quantity' => 2 }
                    }
                }
            });
            setRestContext(body);

            Test.startTest();
            NEMO_ContractAmendmentRest.amend();
            Test.stopTest();

            System.assertEquals(400, RestContext.response.statusCode);
            System.assert(RestContext.response.responseBody.toString().contains('CONTRACT_NOT_ACTIVE'));

            // Log should exist for this requestId
            List<Integration_Log__c> logs = [
                SELECT Id, Status__c, Status_Message__c
                FROM Integration_Log__c
                WHERE Correlation_Id__c = 'REQ-NOTACTIVE-001'
                LIMIT 1
            ];
            System.assertEquals(1, logs.size());
            System.assertEquals('Error', logs[0].Status__c);
            System.assertEquals('CONTRACT_NOT_ACTIVE', logs[0].Status_Message__c);
        }
    }

    /*@IsTest
    static void test_AmendmentFailed_Path_UpdatesLog() {
        User u = createBypassUser();
        assignNemoAmendPermissionIfPossible(u);

        System.runAs(u) {
            Account a = createAccount();

            // Create an Activated contract so it passes your active check
            String activeStatus = System.Label.LABS_SF_Contract_Status_Activated;
            Contract c = createContract(a);

            // Minimal "changes" list – the actual amend creation may fail due to org dependencies,
            // which is OK: we want to cover AMENDMENT_FAILED path + log update.
            String body = JSON.serialize(new Map<String,Object>{
                'requestId' => 'REQ-AMENDFAIL-001',
                'contractId' => c.Id,
                'changes' => new List<Object>{
                    new Map<String,Object>{
                        'match' => new Map<String,Object>{ 'product2Id' => '01t000000000000AAA' },
                        'updates' => new Map<String,Object>{ 'quantity' => 2 }
                    }
                }
            });
            setRestContext(body);

            Test.startTest();
            NEMO_ContractAmendmentRest.amend();
            Test.stopTest();

            // Could be 400 AMENDMENT_FAILED or 500 depending on internal logic; assert log updated at least.
            List<Integration_Log__c> logs = [
                SELECT Status__c, Status_Message__c, Response_Body__c
                FROM Integration_Log__c
                WHERE Correlation_Id__c = 'REQ-AMENDFAIL-001'
                LIMIT 1
            ];
            System.assertEquals(1, logs.size());
            System.assertEquals('Error', logs[0].Status__c);
            System.assert(logs[0].Status_Message__c == 'AMENDMENT_FAILED' || logs[0].Status_Message__c == 'UNHANDLED_EXCEPTION',
                          'Expected AMENDMENT_FAILED or UNHANDLED_EXCEPTION, got ' + logs[0].Status_Message__c);
        }
    }*/
}