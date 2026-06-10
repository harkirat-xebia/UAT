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


}