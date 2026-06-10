/*
----------------------------------------------------------------------
-- - Name          : APER21_StoreToLoopManagement_Test
-- - Author        : snica
-- - Description   : Test class for Store to Loop Management.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- Jun-2023     snica               1.0     Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER21_StoreToLoopManagement_Test {

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

            ER_Loop__c testLoop = new ER_Loop__c(Name = 'Test loop', ER_External_Reference__c = 'EXT-REF_test');
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
           
        }    
    }

    @IsTest
    static void checkDuplicateStoreToLoopTest() {
        
        User u = [SELECT Id FROM User WHERE LastName = 'APER21']; 
        u.ER_bypassTrigger__c = false;
        System.runAs(u) {
            ER_Store__c store = [SELECT Id FROM ER_Store__c WHERE Name = 'CANDA HOTEL' ];
            ER_Loop__c testLoop = [SELECT Id FROM ER_Loop__c WHERE Name = 'Test loop'];

            ER_Store_to_Loop__c store1 = new ER_Store_to_Loop__c(
                ER_Loop__c = testLoop.Id,
                ER_Store__c = store.id,
                ER_Behaviour__c = 'DECLINE'
                );
            insert store1;

            ER_Store_to_Loop__c store2 = new ER_Store_to_Loop__c(
                ER_Loop__c = testLoop.Id,
                ER_Store__c = store.id,
                ER_Behaviour__c = 'DECLINE'
                );
            insert store2;
            List<ER_Store_to_Loop__c> newItems = new List<ER_Store_to_Loop__c>();
            newItems.add(store1);
            newItems.add(store2);

            Test.startTest();
                APER21_StoreToLoopManagement.checkDuplicateStoreToLoop(newItems);
            Test.stopTest();
        }
    }    

    @IsTest
    static void CreatenewStoreToLoopOnStoreInsertTest() {
        
        User u = [SELECT Id FROM User WHERE LastName = 'APER21'];
        u.ER_bypassTrigger__c = false;
        update u;
        System.runAs(u) {
            Account acc = [SELECT Id FROM Account LIMIT 1 ];
            Contact contact = [SELECT Id FROM Contact LIMIT 1];
            ER_Financial_Center__c fc = [SELECT Id FROM ER_Financial_Center__c LIMIT 1]; 
            ER_Loop__c looptst = [SELECT Id FROM ER_Loop__c LIMIT 1]; 

            ER_Store__c store = new ER_Store__c(
                Name = 'CANDA HOTEL',
                ER_Merchant__c = acc.Id,
                ER_Financial_Center__c = fc.Id,
                ER_Contact__c = contact.Id,
                ER_Street__c = 'Test APER 21',
                ER_City__c = 'BUDAPEST',
                ER_Zip_Code__c = '1095'
                );
            insert store;
            ER_Store__c store2 = new ER_Store__c(
                Name = '2CANDA HOTEL',
                ER_Merchant__c = acc.Id,
                ER_Financial_Center__c = fc.Id,
                ER_Contact__c = contact.Id,
                ER_Street__c = '2Test APER 21',
                ER_City__c = '2BUDAPEST',
                ER_Zip_Code__c = '21095'
                );
            insert store2;
            List<ER_Store__c> storeList = new List<ER_Store__c>();
            storeList.add(store); 
            storeList.add(store2);
            
            ER_Account_to_Loop__c newAccountToLoop = new ER_Account_to_Loop__c(
              ER_Behaviour__c = 'DECLINE',
              ER_Loop__c = looptst.Id,
              ER_Account__c = acc.Id
            );
            insert newAccountToLoop;
            newAccountToLoop.ER_Behaviour__c = 'ACCEPT';
            update newAccountToLoop;

            Test.startTest();
                APER21_StoreToLoopManagement.CreatenewStoreToLoopOnStoreInsert(storeList);
            Test.stopTest();
        }
    } 

}