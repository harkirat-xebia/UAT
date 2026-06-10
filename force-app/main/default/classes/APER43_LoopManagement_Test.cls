/**
 * Created by noorgoolamnabee on 11/08/2023.
 */

@IsTest
private class APER43_LoopManagement_Test {

    @TestSetup
    static void testSetup() {
        User u = TestDataFactory.newUser('APER43' + Datetime.now().getTime(), 'APER43' + Datetime.now().getTime(), 'Local Admin', 'France', 'FR');
        u.ER_BypassVR__c = true;
        u.ER_bypassTrigger__c = true;
        System.runAs(u) {
            Test.startTest();
            ER_Loop__c l = new ER_Loop__c(Name = 'TestSetuploop',
                                ER_Context__c = 'Smarter',
                                ER_External_Reference__c = String.valueOf(Datetime.now().getTime()),
                                ER_Merchant_loop_ID__c = '6eca4f44-b405-4684-8a63-8c1bea83a',
                                ER_Smarter_1st_Sync_Date__c = Datetime.now(),
                                ER_Smarter_Last_Sync_Date__c = Datetime.now(),
                                ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_SYNCED);
            insert l;
            Test.stopTest();
        }
    }


    @IsTest
    static void testCallCreateMerchantLoop() {
        User runningUser = TestDataFactory.newUser('APER43', 'APER43', 'Local Admin', 'France', 'FR');
        runningUser.ER_BypassVR__c = true;
        System.runAs(runningUser) {
            Test.startTest();

            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            ER_Loop__c l = new ER_Loop__c(Name = 'Test loop',ER_Context__c = 'Smarter', ER_External_Reference__c = 'EXT-REF_test');
            insert l;

            Test.stopTest();
        }
    }

    @IsTest
    static void testCallCreateMerchantLoopFailure() {
        User runningUser = TestDataFactory.newUser('APER43', 'APER43', 'Local Admin', 'France', 'FR');
        runningUser.ER_BypassVR__c = true;
        System.runAs(runningUser) {
            Test.startTest();

            SmarterAPIMock smarterMock = new SmarterAPIMock();
            SmarterAPIMock.serviceToFail = Constants.SMARTER_SYNC_LOOP_MERCHANT_SERVICE_NAME;
            Test.setMock(HttpCalloutMock.class, smarterMock);
            ER_Loop__c l = new ER_Loop__c(Name = 'Test loop',ER_Context__c = 'Smarter', ER_External_Reference__c = 'EXT-REF_test');
            insert l;

            Test.stopTest();
        }
    }

    @IsTest
    static void testCallCreateMerchantLoopStoreGroup() {
        User runningUser = TestDataFactory.newUser('APER43', 'APER43', 'Local Admin', 'France', 'FR');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_bypassTrigger__c = true;
        System.runAs(runningUser) {
            Test.startTest();

            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            List<ER_Loop__c> loopsToSync = [SELECT Id, Name, ER_Merchant_loop_ID__c, ER_BUPicklist__c
                                FROM ER_Loop__c
                                WHERE ER_Context__c = :Constants.SMARTER
                                AND ER_Merchant_loop_ID__c != NULL];
            System.debug('>>>>> ALK - loopsToSync : ' + loopsToSync);
            APER43_LoopManagement.callCreateMerchantLoopStoreGroup(loopsToSync);

            Test.stopTest();
        }
    }

}