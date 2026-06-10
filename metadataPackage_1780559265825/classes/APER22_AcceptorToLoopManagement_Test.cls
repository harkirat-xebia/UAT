/*
----------------------------------------------------------------------
-- - Name          : APER22_AcceptorToLoopManagement_Test
-- - Author        : snica
-- - Description   : Test class for Acceptor to Loop Management.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- Jun-2023     snica               1.0     Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER22_AcceptorToLoopManagement_Test { 
    @TestSetup
    static void testSetup() {
        
        User runningUser = TestDataFactory.newUser('APER21', 'APER21', 'Local Admin', 'BELUX', 'PL');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_Bypass_Flows__c = true;
        runningUser.ER_bypassTrigger__c = true;

        System.runAs(runningUser) {
            Account merchantAccount = APER07_UtilityTestMethod.getCompany('ER_SyncStructureWithLegacy_Test');
            insert merchantAccount;

            Contact contactTest = new Contact();
            contactTest.FirstName = 'Test Aper21';
            contactTest.LastName = 'Test Aper21';
            contactTest.Email = 'test@test.com';
            contactTest.AccountId = merchantAccount.Id;
            contactTest.Email = 'testAper21@edenred.com';
            contactTest.ER_Account_Address_Sync__c = Label.LABS_SF_Account_SyncAddressContact;
            insert contactTest;

            ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
                    'ER_SyncStructureWithLegacy_Test',
                    merchantAccount.Id,
                    Label.LABS_SF_FinancialCenter_Merchant,
                    'Test',
                    'Test',
                    'Test',
                    'Test'
                );
            testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
            testFinancialCenter.ER_Contact__c = contactTest.Id;
            insert testFinancialCenter;

            ER_Store__c store = new ER_Store__c(
                Name = 'CANDA HOTEL',
                ER_Merchant__c = merchantAccount.Id,
                ER_Financial_Center__c = testFinancialCenter.Id,
                ER_Contact__c = contactTest.Id,
                ER_Street__c = 'Test APER 21',
                ER_City__c = 'BUDAPEST',
                ER_Zip_Code__c = '1095'
                );
            insert store;

            ER_Loop__c testLoop = new ER_Loop__c(Name = 'Test loop', ER_External_Reference__c = 'EXT-REF_test', ER_Context__c = 'Smarter');
            insert testLoop;

            ER_Store_to_Loop__c storeToLoop = new ER_Store_to_Loop__c(
            ER_Loop__c = testLoop.Id,
            ER_Store__c = store.id,
            ER_Behaviour__c = 'ACCEPT'
            );
            insert storeToLoop;

            ER_Store_to_Loop__c storeToLoop2 = new ER_Store_to_Loop__c(
            ER_Loop__c = testLoop.Id,
            ER_Store__c = store.id,
            ER_Behaviour__c = 'ACCEPT'
            );
            insert storeToLoop2;
            
            ER_Store_to_Loop__c storeToLoop3 = new ER_Store_to_Loop__c(
            ER_Loop__c = testLoop.Id,
            ER_Store__c = store.id,
            ER_Behaviour__c = 'ACCEPT'
            );
            insert storeToLoop3;
            
            ER_Acceptor__c acceptor = new ER_Acceptor__c( Name = 'CANDA HOTEL',ER_Store__c = store.Id,ER_MID_Authorization__c = '12341993', ER_Start_Date__c = date.today()+10);
            insert acceptor;
            
            ER_Acceptor_to_Loop__c acceptorToLoop = new ER_Acceptor_to_Loop__c();
            acceptorToLoop.ER_Behaviour__c = 'ACCEPT';
            acceptorToLoop.ER_Acceptor__c = acceptor.Id;
            acceptorToLoop.ER_BUPicklist__c = 'FR';
            acceptorToLoop.ER_Loop__c = testLoop.Id;
            Database.insert(acceptorToLoop, true);
           
        }    
    }
    

    @IsTest
    static void testrunAcceptorToLoopCreation() {
        User runningUser = TestDataFactory.newUser('APER21', 'APER21', 'Local Admin', 'BELUX', 'PL');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_Bypass_Flows__c = true;
        runningUser.ER_bypassTrigger__c = true;
        
        List<ER_Store_to_Loop__c> storesList = [SELECT Id, Name FROM ER_Store_to_Loop__c WHERE ER_Loop__r.Name = 'Test loop'];
        
        System.runAs(runningUser) {
            Test.startTest();
            APER22_AcceptorToLoopManagement.runAcceptorToLoopCreation(storesList);
            APER22_AcceptorToLoopManagement.runAcceptorToLoopUpdate(storesList);
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testCheckAcceptorToLoop() {
        User runningUser = TestDataFactory.newUser('APER21', 'APER21', 'Local Admin', 'BELUX', 'PL');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_Bypass_Flows__c = true;
        runningUser.ER_bypassTrigger__c = true;
        Id acceptorId = [SELECT Id FROM ER_Acceptor__c WHERE Name = 'CANDA HOTEL'].Id;
        List<ER_Acceptor_to_Loop__c> acceptortoLoopList = [SELECT Id, Name, ER_Acceptor__c FROM ER_Acceptor_to_Loop__c WHERE ER_Acceptor__c =: acceptorId ];
        
        System.runAs(runningUser) {
            APER22_AcceptorToLoopManagement.CheckAcceptorToLoop(acceptortoLoopList);
        }
    }
    
    @IsTest
    static void testhandleAcceptorToLoopsSync() {
        User runningUser = TestDataFactory.newUser('APER21', 'APER21', 'Local Admin', 'BELUX', 'PL');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_Bypass_Flows__c = true;
        runningUser.ER_bypassTrigger__c = true;
        
        Id acceptorId = [SELECT Id FROM ER_Acceptor__c WHERE Name = 'CANDA HOTEL'].Id;
        List<ER_Acceptor_to_Loop__c> acceptortoLoopList = [SELECT Id, Name, ER_Acceptor__c, ER_Behaviour__c, ER_Loop__r.ER_Context__c,
                                                           ER_Loop__r.ER_Store_Group_ID__c, ER_Acceptor__r.ER_MID_Authorization__c,
                                                           ER_Acceptor__r.ER_MID_Clearing__c, ER_Acceptor__r.ER_SubMID_Authorization__c,
                                                           ER_Acceptor__r.ER_Sub_MID_Clearing__c, ER_Loop__r.ER_Merchant_loop_ID__c, ER_BUPicklist__c ,
                                                            ER_Smarter_1st_Sync_Date__c, ER_Smarter_Last_Sync_Date__c, ER_Smarter_Sync_Error__c, ER_Smarter_Sync_Status__c
                                                           FROM ER_Acceptor_to_Loop__c
                                                           WHERE ER_Acceptor__c =: acceptorId ];
        
        System.runAs(runningUser) {
            Test.startTest();
            APER22_AcceptorToLoopManagement.handleAcceptorToLoopsSync(acceptortoLoopList);
            Test.stopTest();
        }
    }

    @IsTest
    static void testbulkifyAcceptorToLoopsSync() {
        User runningUser = TestDataFactory.newUser('APER22', 'APER22', 'System Administrator', 'France', 'FR');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_bypassTrigger__c = true;
        
        Id acceptorId = [SELECT Id FROM ER_Acceptor__c WHERE Name = 'CANDA HOTEL'].Id;
        List<ER_Acceptor_to_Loop__c> acceptortoLoopList = [SELECT Id, Name, ER_Acceptor__c, ER_Behaviour__c, ER_Loop__r.ER_Context__c,
                                                           ER_Loop__r.ER_Store_Group_ID__c, ER_Acceptor__r.ER_MID_Authorization__c,
                                                           ER_Acceptor__r.ER_MID_Clearing__c, ER_Acceptor__r.ER_SubMID_Authorization__c,
                                                           ER_Acceptor__r.ER_Sub_MID_Clearing__c, ER_Loop__r.ER_Merchant_loop_ID__c, ER_BUPicklist__c 
                                                           FROM ER_Acceptor_to_Loop__c
                                                           WHERE ER_Acceptor__c =: acceptorId ];
        
        System.runAs(runningUser) {
            Test.startTest();
            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            APER22_AcceptorToLoopManagement.bulkifyAcceptorToLoopsSync(acceptortoLoopList);
            Test.stopTest();
        }
    }

}