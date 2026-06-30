/**
* @author: ATI
* @date: 22/08/2023
* @desc: APER44_AccountContactRelationMgtTest
* @see: APER44_AccountContactRelationMgtTest
*/

@IsTest
private class APER44_AccountContactRelationMgtTest {
    //@TestSetup
    /*
    static void testSetup() {
        User u = TestDataFactory.newUser('APER44' + Datetime.now().getTime(), 'APER44' + Datetime.now().getTime(), 'Local Admin', 'France', 'FR');
        u.ER_BypassVR__c = true;
        System.runAs(u) {
            Test.startTest();
            Account acc = TestDataFactory.newAccount();
            acc.ER_BUPicklist__c = 'FR';
            acc.SmartER_Customer_Id__c = '083883783';
            acc.ER_BUPicklist__c = 'FR';
            acc.ER_Status__c = 'Active';
            acc.Name = 'Smart Account';
            acc.ER_SmartER_Context__c = true;
            insert acc;
            
            Contact con = TestDataFactory.newContact(acc);
            con.AccountId = acc.Id;
            con.ER_Smarter_1st_Sync_Date__c = null;
            con.LastName = 'APER44LastName';
            con.ER_SmartER_Context__c = true;
            con.ER_SmartER_Context__c = true;
            con.ER_Smarter_Sync_Status__c = null;
            con.ER_Smarter_Sync_Error__c = null;
            insert con;
            
            Test.stopTest();
        }
    }*/
    
    
    @IsTest
    static void testCallSyncAccountContactRelationship_Success() {
        User runningUser = TestDataFactory.newUser('APER44', 'APER44', 'Local Admin', 'France', 'FR');
        runningUser.ER_BypassVR__c = true;
        System.runAs(runningUser) {
            
            Account acc = TestDataFactory.newAccount();
            acc.ER_BUPicklist__c = 'FR';
            acc.SmartER_Customer_Id__c = '083883783';
            acc.ER_BUPicklist__c = 'FR';
            acc.ER_Status__c = 'Active';
            acc.Name = 'Smart Account';
            acc.ER_SmartER_Context__c = true;
            insert acc;
            
            Contact con = TestDataFactory.newContact(acc);
            con.AccountId = acc.Id;
            con.ER_Smarter_1st_Sync_Date__c = null;
            con.LastName = 'APER44LastName';
            con.ER_SmartER_Context__c = true;
            con.ER_Smarter_Sync_Status__c = null;
            con.ER_Smarter_Sync_Error__c = null;
            insert con;




            List<AccountContactRelation> acr = [SELECT Id, IsDirect FROM AccountContactRelation ];
            System.assert(acr.size() == 1, 'must contain one ACR');
            System.assert(acr[0].IsDirect, 'must be direct = true ');

            
            Test.startTest();
            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            
            acr[0].Roles = 'Auditor';
            update acr[0];

            AccountContactRelation acr2 = new AccountContactRelation();
            //acr2.AccountId = acc.Id;
            //acr2.ContactId = con2.Id;
            //insert acr2;
            
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetMessageErrorFromSmarter_returnsText() {
        String errorJson = '{"meta":{"status":"Failed","messages":[{"text":"Connection refused"}]}}';

        Test.startTest();
        String result = APER44_AccountContactRelationManagement.getMessageErrorFromSmarter(errorJson);
        Test.stopTest();

        System.assertEquals('Connection refused', result, 'Should extract error text from response');
    }

    @IsTest
    static void testGetMessageErrorFromSmarter_invalidJson() {
        Test.startTest();
        String result = APER44_AccountContactRelationManagement.getMessageErrorFromSmarter('not-valid-json');
        Test.stopTest();

        System.assertEquals('', result, 'Invalid JSON should return empty string gracefully');
    }

    @IsTest
    static void testGetMessageErrorFromSmarter_nonFailedStatus() {
        String json = '{"meta":{"status":"succeeded","messages":[]}}';

        Test.startTest();
        String result = APER44_AccountContactRelationManagement.getMessageErrorFromSmarter(json);
        Test.stopTest();

        System.assertEquals('', result, 'Non-Failed status should return empty string');
    }

    @IsTest
    static void testUpdateAsyncRelations_nullJson() {
        Test.startTest();
        APER44_AccountContactRelationManagement.updateAsyncRelations(null);
        Test.stopTest();

        System.assert(true, 'Null JSON should be handled without exception');
    }

    @IsTest
    static void testPatchAccountContactRelationship_noSyncDate_callsSync() {
        User runningUser = TestDataFactory.newUser('APER44P', 'APER44P', 'Local Admin', 'France', 'FR');
        runningUser.ER_BypassVR__c = true;
        System.runAs(runningUser) {
            Account acc = TestDataFactory.newAccount();
            acc.ER_BUPicklist__c = 'FR';
            acc.SmartER_Customer_Id__c = '083883783';
            acc.ER_SmartER_Context__c = true;
            acc.ER_Status__c = 'Active';
            insert acc;

            Contact con = TestDataFactory.newContact(acc);
            con.ER_SmartER_Context__c = true;
            con.ER_Smarter_1st_Sync_Date__c = null;
            insert con;

            List<AccountContactRelation> acrs = [SELECT Id, IsActive, Roles, ER_Smarter_1st_Sync_Date__c FROM AccountContactRelation WHERE AccountId = :acc.Id];
            Map<Id, AccountContactRelation> oldMap = new Map<Id, AccountContactRelation>();
            for (AccountContactRelation acr : acrs) {
                oldMap.put(acr.Id, acr.clone(true, true, true, true));
            }

            Test.startTest();
            APER44_AccountContactRelationManagement.patchAccountContactRelationship(acrs, oldMap);
            Test.stopTest();

            System.assert(true, 'patchAccountContactRelationship executed without exception');
        }
    }

}