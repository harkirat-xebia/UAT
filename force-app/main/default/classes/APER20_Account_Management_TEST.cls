/*
----------------------------------------------------------------------
-- - Name          : APER20_Account_Management_TEST
-- - Author        : KHAD
-- - Description   : Test class for Account Management.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- FEB-2021     KHAD                    1.0     Initial version
-- 07/06/21		AAM						1.1		Rework AccountTrigger (Framework)
-- Jul-2023     MAME        1.2         COUL3020 Apply lead assignment rules when creating leads
---------------------------------------------------------------------------------------
*/
@isTest
public class APER20_Account_Management_TEST {
    @testSetup
    static void testSetup() {
        String businessUnit = 'ES';
        User u = TestDataFactory.newUser(
            'FirstName' + Datetime.now().getTime(),
            'LastName' + Datetime.now().getTime(),
            Constants.PROFILE_ER_INTEGRATION,
            'Spain',
            businessUnit
        );
        u.ER_BypassVR__c = true;
        u.ER_Bypass_Flows__c = true;
        insert u;
        
        System.runAs(u) {
            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
            Account newMerchantAccount = APER07_UtilityTestMethod.insertAccount('acctWithContract', 'ER_Company_Account_RT');
            Account newMerchantAccount1 = APER07_UtilityTestMethod.insertAccount(
                'acctWithContract1',
                'ER_Company_Account_RT'
            );
            ER_Financial_Center__c fc = APER07_UtilityTestMethod.insertFinancialCenter(
                'fc' + Datetime.now().getTime(),
                newMerchantAccount.Id,
                'Some Street',
                'Warsaw',
                '00-001',
                'Poland',
                Label.LABS_SF_FinancialCenter_Merchant,
                null,
                'PL'
            );
            Account newMerchantAggAccount = APER07_UtilityTestMethod.insertAccount(
                'merchantAccount',
                'ER_Company_Account_RT'
            );
            newMerchantAggAccount.Description = 'ERBE_TCE-M';
            newMerchantAggAccount.ER_BUPicklist__c = 'BENELUX';
            update newMerchantAggAccount;
            Account newAggAccount = APER07_UtilityTestMethod.insertAccount('aggAccount', 'Aggregator_Merchant');
            AccountPartner partner1 = APER07_UtilityTestMethod.newAccountPartner(
                'AggregatorMerchant',
                newMerchantAggAccount.Id,
                newAggAccount.Id
            );
            insert partner1;
            AccountPartner partner2 = APER07_UtilityTestMethod.newAccountPartner(
                Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR,
                newAggAccount.Id,
                newMerchantAggAccount.Id
            );
            insert partner2;
            Contract testContract = APER07_UtilityTestMethod.insertContract(
                newMerchantAccount.Id,
                Date.today(),
                Label.LABS_SF_Contract_Status_Draft,
                newPriceBook.Id,
                'ER_Merchant_Contract_RT',
                u.Id
            );
            //Solutions
            Product2 newSolution = APER07_UtilityTestMethod.insertProduct2(
                'ERBE_TCE-M',
                businessUnit,
                'ERBE_TCE-M',
                'Solution',
                null
            );
            Product2 newSolution1 = APER07_UtilityTestMethod.insertProduct2(
                'ERBE_TRE-M',
                businessUnit,
                'ERBE_TRE-M',
                'Solution',
                null
            );
            //Services
            Product2 newService = APER07_UtilityTestMethod.insertProduct2(
                'testService',
                businessUnit,
                null,
                'service',
                newSolution.Id
            );
            //PriceBookEntries
            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.Id, newService.id);
            insert newPriceBookEntry;
            //contractLineItems
            ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(
                testContract.Id,
                newService.id,
                newPriceBookEntry.id,
                1,
                1
            );
            insert testContractLineItem;
            testContract.status = Label.LABS_SF_Contract_Status_Activated;
            testContract.ER_Offline__c = true; // AAM
            update testContract;
            //AccountLineItems
            ER_Solution_Line_Item__c testAccountLineItem = APER07_UtilityTestMethod.getAccountLineItem(
                testContract.AccountId,
                testContract.Id,
                newSolution1.id
            );
            insert testAccountLineItem;
            ER_Solution_Line_Item__c testAccountLineItem1 = APER07_UtilityTestMethod.getAccountLineItem(
                newMerchantAccount1.Id,
                null,
                newSolution.id
            );
            insert testAccountLineItem1;
        }
    }
    
    @IsTest
    static void manageAccountLineItemsForContract() {
        List<Contract> contractList = [
            SELECT id, AccountId, Status
            FROM Contract
            WHERE Status = :Label.LABS_SF_Contract_Status_Activated
        ];
        if (!contractList.isEmpty()) {
            Test.startTest();
            APER20_Account_Management.manageAccountLineItemsForContract(contractList[0]);
            APER20_Account_Management.deactivateAccountsStatusForTerminatedContracts(new Set<Id>{ contractList[0].Id });
            Test.stopTest();
        }
    }
    
    static testMethod void processAggregatorAccountsTest() {
        
        list<Account> aggAccounts = [SELECT Id,Description, Name, ER_Legal_Name__c, BillingCity, BillingCountry, BillingPostalCode, ER_Registration_Number__c,
                                     BillingStreet, ER_VAT_Number__c, BillingState, ER_BUPicklist__c FROM Account WHERE Name  = 'merchantAccount']; 
        
        User u = [SELECT Id FROM User WHERE LastName like 'LastName%'];
        System.runAs(u) {
            if(!aggAccounts.isEmpty()){
                Test.startTest();
                APER20_Account_Management.processAggregatorAccounts(aggAccounts);
                Test.stopTest();
                List<Lead> leads = [SELECT Id, Name , Owner.Type FROM Lead];
                for(Lead l:leads){
                    System.assertEquals(l.Owner.Type, 'Queue', 'Lead assignment rules weren\'t enforced');
                    System.assert(l.Name.startsWith('Aggregator merchantAccount - ERBE'));
                }
            }
        }
        
    }
    
    @IsTest
    static void updateAccountLineItemsForAccountTest() {
        List<Account> accts = [SELECT id, Name FROM Account WHERE Name = 'acctWithContract1'];
        List<Contract> contracts = [
            SELECT Id, status
            FROM Contract
            WHERE status = :Label.LABS_SF_Contract_Status_Activated
        ];
        List<ER_Solution_Line_Item__c> solLIs = [
            SELECT Id, ER_Contract__c, ER_Solution__c
            FROM ER_Solution_Line_Item__c
            WHERE ER_Account__c = :accts[0].Id
        ];
        Set<String> solutions = new Set<String>{ solLIs.get(0).ER_Solution__c };
            GenericWithoutSharing.updateAccountLineItemsForAccount(
                solutions,
                contracts[0].Id,
                accts[0].Id,
                contracts[0].Status
            );
        List<ER_Solution_Line_Item__c> slis = [
            SELECT Id, ER_Contract__c
            FROM ER_Solution_Line_Item__c
            WHERE
            RecordType.DeveloperName = 'ER_Account_Line_Item'
            AND ER_Solution__c IN :solutions
            AND ER_Account__c = :accts[0].Id
        ];
        System.debug('slis: ' + slis);
    }
    
    @IsTest
    static void manageRTMerchant() {
        User u = [SELECT Id FROM User WHERE LastName LIKE 'LastName%'];
        
        System.runAs(u) {
            APER07_UtilityTestMethod.insertAccount('rtMerchantAccount', 'ER_Company_Account_RT');
        }
    }
    
    @IsTest
    static void testUpdate() {
        List<Account> accountList = [
            SELECT Id, ER_Match_Legal_Address__c
            FROM Account
            WHERE Name = 'rtMerchantAccount'
            LIMIT 1
        ];
        
        if (!accountList.isEmpty()) {
            accountList[0].Name = 'rtMerchantAccount';
            accountList[0].ER_Match_Legal_Address__c = true;
            Test.startTest();
            update accountList[0];
            Test.stopTest();
        }
    }
    
    @IsTest
    static void updateZuoraBillingAccount() {
        Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Zuora Sales'];
        UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
        User u = new User(
            LastName = 'PL User',
            Username = 'test@clientsales.com',
            Email = 'test@clientsales.com',
            Alias = 'pluser',
            CommunityNickname = 'pusr',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'fr_FR',
            EmailEncodingKey = 'UTF-8',
            ProfileId = pr.Id,
            LanguageLocaleKey = 'en_US',
            ER_Business_Unit__c = 'PL',
            UserRoleId = ur.Id
        );
        insert u;
        
        System.runAs(u) {
            Account a = APER07_UtilityTestMethod.insertAccount(
                'APER30_FinancialCenter_Management_TEST_PL_Zuora',
                'ER_Company_Account_RT'
            );
            Contact c = TestDataFactory.newContact(a);
            insert c;
            ER_Financial_Center__c fc = APER07_UtilityTestMethod.insertFinancialCenter(
                'fc' + Datetime.now().getTime(),
                a.Id,
                'Some Street',
                'Warsaw',
                '00-001',
                'Poland',
                Label.LABS_SF_FinancialCenter_Merchant,
                c.Id,
                'PL'
            );
            APER07_UtilityTestMethod.insertZuoraCustomerAccount(
                'BaName',
                fc.Id,
                'A00000111',
                a.Id,
                'AFFILIATE',
                'Active',
                'PLN'
            );
            
            Test.startTest();
            //SendToZuoraMock zuoraMock = new SendToZuoraMock();
            SmarterAPIMock zuoraMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, zuoraMock);
            a.ER_Legal_Name__c = 'ZIP999';
            update a;
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testgenerateAggregatorLeads() {
        List<Account> accountList = [SELECT id, Name FROM Account WHERE Name = 'merchantAccount'];
        Test.startTest();
        if (!accountList.isEmpty()) {
            APER33_GenerateLeadsMeAggregator.generateAggregatorLeads(accountList[0].Id);
            List<Lead> aggreLeads = [SELECT Id, Name, Company FROM Lead];
            //System.assertEquals('Aggregator aggAccount - testSolution', aggreLeads.get(0).Name);
            //System.assertEquals('Aggregator - aggAccount - testSolution', aggreLeads.get(0).company);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testManageStatus() {
        Account newMerchantAccount = APER07_UtilityTestMethod.insertAccount('acctWithContract', 'ER_Company_Account_RT');
        List<Account> accountList = [
            SELECT id, Name, ER_Status__c, ER_Inactive_date__c, ER_Inactive_Reason__c
            FROM Account
            WHERE Name IN ('acctWithContract', 'aggAccount')
        ];
        Test.startTest();
        if (!accountList.isEmpty()) {
            APER20_Account_Management.manageStatusOnContractActivation(accountList[0].Id);
            APER20_Account_Management.manageStatusOnContractTermination(accountList[0].Id);
            APER20_Account_Management.manageStatusOnContractTermination(accountList[1].Id);
            List<Account> postAccts = [
                SELECT id, Name, ER_Status__c, ER_Inactive_date__c, ER_Inactive_Reason__c
                FROM Account
                WHERE Name IN ('acctWithContract', 'aggAccount')
            ];
            System.assertNotEquals(postAccts[0].ER_Inactive_Reason__c, Label.LABS_SF_Account_Inactive_Reason);
            //System.assertEquals(postAccts[1].ER_Status__c, Label.LABS_SF_Account_Status_Inactive);
            System.assertEquals(postAccts[1].ER_Inactive_date__c, Date.today());
            System.assertEquals(postAccts[1].ER_Inactive_Reason__c, Label.LABS_SF_Account_Inactive_Reason);
        }
        Test.stopTest();
    }
    
    /*
@IsTest
static void populateIndividualInvitationTriggerDate() {
Account newIndividual = APER07_UtilityTestMethod.getIndividual('Mr.', 'NewIndividualName', 'Test');
newIndividual.ER_Do_not_contact__pc = true;
newIndividual.ER_BUPicklist__c = 'ES';
insert newIndividual;

Test.startTest();
APER20_Account_Management.populateIndividualInvitationTriggerDate(new List<Account>{ newIndividual });
Test.stopTest();
}*/
    
    @IsTest
    static void syncOfflineTCsTest() {
        UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
        User u = TestDataFactory.newUser(
            'FirstName' + Datetime.now().getTime(),
            'LastName' + Datetime.now().getTime(),
            Constants.PROFILE_ER_INTEGRATION,
            'FR'
        );
        u.UserRoleId = ur.Id;
        u.ER_Bypass_Flows__c = true;
        insert u;
        
        System.runAs(u) {
            Account acc = APER07_UtilityTestMethod.getCompany('syncOfflineTCsTest');
            insert acc;
            
            Contract testContract = APER07_UtilityTestMethod.insertContract(
                acc.Id,
                Date.today(),
                Label.LABS_SF_Contract_Status_Draft,
                null,
                'ER_Client_Contract_RT',
                u.Id
            );
            
            Test.startTest();
            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            
            testContract.ER_Customer_Signed_Version__c = '20220230';
            testContract.ER_TCs_Signed_Link__c = 'link';
            testContract.ER_Agreement_DateTime__c = Datetime.now();
            testContract.Status = 'Activated';
            testContract.ER_Offline__c = true;
            update testContract;
            
            acc.SmartER_Customer_Id__c = '12345678';
            acc.ER_SmartER_Context__c = true;
            update acc;
            
            system.debug('######## syncOfflineTCsTest after update:' + acc);
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testSyncAccountSmarter() {
        User u = TestDataFactory.newUser(
            'FirstName' + Datetime.now().getTime(),
            'LastName' + Datetime.now().getTime(),
            Constants.PROFILE_ER_INTEGRATION,
            'France',
            'FR'
        );
        u.ER_BypassVR__c = true;
        u.ER_Bypass_Flows__c = true;
        insert u;
        
        System.runAs(u) {
            Account acc = APER07_UtilityTestMethod.getCompany('testSyncAccountSmarter');
            acc.ER_SmartER_Context__c = true;
            insert acc;
            Contract testContract = APER07_UtilityTestMethod.insertContract(
                acc.Id,
                Date.today(),
                Label.LABS_SF_Contract_Status_Draft,
                null,
                'ER_Client_Contract_RT',
                u.Id
            );
            
            Test.startTest();
            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            
            testContract.Status = 'Activated';
            update testContract;
            
            acc.SmartER_Customer_Id__c = '12345678';
            acc.BillingStreet = 'some street';
            update acc;
            
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testSyncNewAccountSmarter() {
        User u = TestDataFactory.newUser(
            'FirstName' + Datetime.now().getTime(),
            'LastName' + Datetime.now().getTime(),
            Constants.PROFILE_ER_INTEGRATION,
            'France',
            'FR'
        );
        u.ER_BypassVR__c = true;
        u.ER_Bypass_Flows__c = true;
        insert u;
        
        System.runAs(u) {
            Account acc = APER07_UtilityTestMethod.getCompany('testSyncAccountSmarter');
            acc.ER_SmartER_Context__c = true;
            insert acc;
            
            Contract testContract = APER07_UtilityTestMethod.insertContract(
                acc.Id,
                Date.today(),
                Label.LABS_SF_Contract_Status_Draft,
                null,
                'ER_Client_Contract_RT',
                u.Id
            );
            
            Test.startTest();
            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            
            testContract.Status = 'Activated';
            update testContract;
            
            APER20_Account_Management.syncClientToSmarter(new Set<Id>{ acc.Id });
            
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testSyncAccountSmarterKO() {
        User u = TestDataFactory.newUser(
            'FirstName' + Datetime.now().getTime(),
            'LastName' + Datetime.now().getTime(),
            Constants.PROFILE_ER_INTEGRATION,
            'France',
            'FR'
        );
        u.ER_BypassVR__c = true;
        u.ER_Bypass_Flows__c = true;
        insert u;
        
        System.runAs(u) {
            Account acc = APER07_UtilityTestMethod.getCompany('testSyncAccountSmarter');
            acc.ER_SmartER_Context__c = true;
            insert acc;
            
            Contract testContract = APER07_UtilityTestMethod.insertContract(
                acc.Id,
                Date.today(),
                Label.LABS_SF_Contract_Status_Draft,
                null,
                'ER_Client_Contract_RT',
                u.Id
            );
            
            Test.startTest();
            
            SmarterAPIMock smarterMock = new SmarterAPIMock();
            SmarterAPIMock.serviceToFail = Constants.SMARTER_ACCOUNT_REF_SERVICE_NAME;
            Test.setMock(HttpCalloutMock.class, smarterMock);
            
            testContract.Status = 'Activated';
            update testContract;
            
            acc.SmartER_Customer_Id__c = '12345678';
            acc.BillingStreet = 'some street';
            update acc;
            
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testUpdateClientPriority() {
        User u = TestDataFactory.newUser(
            'FirstName' + Datetime.now().getTime(),
            'LastName' + Datetime.now().getTime(),
            Constants.PROFILE_ER_INTEGRATION,
            'Greece',
            'GR'
        );
        u.ER_BypassVR__c = true;
        u.ER_Bypass_Flows__c = true;
        insert u;
        
        System.runAs(u) {
            Account acc = APER07_UtilityTestMethod.getCompany('testSyncAccountSmarter');
            insert acc;
            Test.startTest();
            
            Account a = [SELECT Id, ER_Client_Priority__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals('Ultra High', a.ER_Client_Priority__c);
            Test.stopTest();
        }
    }
    
    @isTest static void testUpdateClient(){
        String mockResponseBody = '{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1731935419","not_before":"1731931519","resource":"7f73991c-df92-4a33-9668-81e58b5ebfe7","access_token":"test"}';
        HTTPCalloutServiceMock testMock = new HTTPCalloutServiceMock(200, mockResponseBody);
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, testMock);
        Account acc = APER07_UtilityTestMethod.getCompany('syncOfflineTCsTest');
        
        Test.startTest();
        insert acc;
        acc.BillingStreet = 'street';
        acc.ER_Card_Client_Operational_System_ID__c = '123';
        update acc;
        Test.stopTest();
    }
    
}