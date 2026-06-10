/*
----------------------------------------------------------------------
-- - Name          : APER24_ContactRole_Management_Test 
-- - Author        : OLA
-- - Description   : TEST for Contact Role Management class
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  APR-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

@isTest
public class APER24_ContactRole_Management_Test {
    
    @testSetup
    static void testSetup() {
                
        Account newMerchantAccount = TestDataFactory.newAccount();
        newMerchantAccount.Name='APER17_Contact_Management_Test'; 
        insert newMerchantAccount;

        ER_Financial_Center__c testFinancialCenter = TestDataFactory.newFinancialCenter(newMerchantAccount, Label.LABS_SF_FinancialCenter_Client);
        testFinancialCenter.Name = 'APER24_ContactRole_Management_Test';
        insert testFinancialCenter;        
        
        Contact contactTest = TestDataFactory.newContact(newMerchantAccount);
        contactTest.ER_Account_Address_Sync__c = LAbel.LABS_SF_Account_SyncAddressContact ;
        insert contactTest;
        
        User runningUser = [select id,ER_Business_Unit__c  FROM User WHERE id =: UserInfo.getUserId()];
        Account clientAccount = APER07_UtilityTestMethod.getCompany('APER28_DeliverySite_Management_TEST');
        insert clientAccount;
        
        PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
        
        List<Product2> solutionListToInsert = new List<Product2>();
        List<Product2> serviceListToInsert = new List<Product2>();
        List<PriceBookEntry> pbeListToInsert = new List<PriceBookEntry>();
        List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
        List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
        List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();

        Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
        newSolution.ProductCode = 'testSolution';
        newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        solutionListToInsert.add(newSolution);

        Product2 newSolution4 = APER07_UtilityTestMethod.getsolution('testSolution2');
        newSolution4.ProductCode = 'testSolution2';
        newSolution4.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        solutionListToInsert.add(newSolution4);

        insert solutionListToInsert;
        
        Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
        newService.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        serviceListToInsert.add(newService);

        Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice2', newSolution4.id);
        newService2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        serviceListToInsert.add(newService2);

        insert serviceListToInsert;
        
        PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
        pbeListToInsert.add(newPriceBookEntry);

        PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
        pbeListToInsert.add(newPriceBookEntry2);

        insert pbeListToInsert;
        
        Contract testContract = APER07_UtilityTestMethod.getContract(clientAccount.id, Date.today(),Label.LABS_SF_Contract_Status_Draft,newPriceBook.Id);
        testContract.recordtypeid =Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId();
        insert testContract;

        ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(testContract.id, newService.id,newPriceBookEntry.id, 1, 1);
        cliListToInsert.add(testContractLineItem);

        ER_ContractLineItem__c testContractLineItem2 = APER07_UtilityTestMethod.getContractLineItem(testContract.id, newService2.id,newPriceBookEntry2.id, 1, 1);
        cliListToInsert.add(testContractLineItem2);

        insert cliListToInsert;

        testContract.status = Label.LABS_SF_Contract_Status_Activated; 
        //update testContract;
        
        ER_Solution_Line_Item__c testAccountLineItem = APER07_UtilityTestMethod.getAccountLineItem(clientAccount.Id, testContract.Id, newSolution.Id);
        testAccountLineItem.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
        aliListToInsert.add(testAccountLineItem);
        
        ER_Solution_Line_Item__c testAccountLineItem2 = APER07_UtilityTestMethod.getAccountLineItem(clientAccount.Id, testContract.Id, newSolution4.Id);
        testAccountLineItem2.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
        aliListToInsert.add(testAccountLineItem2);
        
        insert aliListToInsert;
        
        ER_Solution_Line_Item__c testFinancialCenterLineItem = APER07_UtilityTestMethod.getFinancialCenterLineItem(testFinancialCenter.Id, testContract.Id,testAccountLineItem.id, newSolution.Id);
        fcliListToInsert.add(testFinancialCenterLineItem);
        
        ER_Solution_Line_Item__c testFinancialCenterLineItem2 = APER07_UtilityTestMethod.getFinancialCenterLineItem(testFinancialCenter.Id, testContract.Id,testAccountLineItem2.id, newSolution4.Id);
        fcliListToInsert.add(testFinancialCenterLineItem2);
        
        insert fcliListToInsert;

        List<Contact> contactList = new List<Contact>();

        Contact c = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test1', 'test1');
        c.AccountId = clientAccount.Id;
        Contact c1 = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test2', 'test2');
        c1.AccountId = clientAccount.Id;
        contactList.add(c);
        contactList.add(c1);
        insert contactList;
        
        ER_Contact_Role__c contactRolePrimaryTest = TestDataFactory.newContactRole(contactTest.id,testFinancialCenter.id,'ER_CR_Financial_Center_Merchant',false);
        insert contactRolePrimaryTest;
        contactRolePrimaryTest.ER_Sync_result__c = 'synchronized';
        update contactRolePrimaryTest;
        
        insertDateAsync(); 
    }
    
    @future
    private static void insertDateAsync() {
        User runningUser = [select id,ER_Business_Unit__c  FROM User WHERE id =: UserInfo.getUserId()];
        Account cAccount2 = APER07_UtilityTestMethod.getCompany('APER29_DistributionPoint_Management_Test');
        insert cAccount2;
        
        Account newMerchantAccount = TestDataFactory.newAccount();
        newMerchantAccount.Name='APER17_Contact_Management_Test'; 
        insert newMerchantAccount;
        
        Contact contactTest = TestDataFactory.newContact(newMerchantAccount);
        contactTest.ER_Account_Address_Sync__c = LAbel.LABS_SF_Account_SyncAddressContact ;
        insert contactTest;
        
        ER_Financial_Center__c testFinancialCenter2 = APER07_UtilityTestMethod.getFinancialCenter('APER29_DistributionPoint_Management_Test', cAccount2.id, Label.LABS_SF_FinancialCenter_Client,'Test','Test','Test','Test');
        testFinancialCenter2.ER_Type__c = Label.LABS_SF_FinancialCenter_Client;
        insert testFinancialCenter2;
        
        ER_Delivery_Site__c testDeliverySite = TestDataFactory.newDeliverySite(newMerchantAccount, 'APER26_DeliverySite_Management_Test', testFinancialCenter2);
        testDeliverySite.ER_Street__c = '123 Dummy St';
        testDeliverySite.ER_Zip_Code__c = '99000';
        testDeliverySite.ER_City__c = 'Anycity';
        testDeliverySite.ER_Country__c = 'Country';
        insert testDeliverySite; 
                
        ER_Distribution_Point__c testDistributionPoint = TestDataFactory.newDistributionPoint('APER27_DistributionPoint_Management_Test', testDeliverySite.id);
        testDistributionPoint.ER_Street__c = '123 Dummy St';
        testDistributionPoint.ER_Zip_Code__c = '99000';
        testDistributionPoint.ER_City__c = 'Anycity';
        testDistributionPoint.ER_Country__c = 'Country';
        insert testDistributionPoint;
        
        PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
        
        PriceBook2 newPriceBook2 = APER07_UtilityTestMethod.getpriceBook();
        
        List<Product2> solutionListToInsert2 = new List<Product2>();
        List<Product2> serviceListToInsert2 = new List<Product2>();
        List<PriceBookEntry> pbeListToInsert2 = new List<PriceBookEntry>();
        List<ER_ContractLineItem__c> cliListToInsert2 = new List<ER_ContractLineItem__c>();
        List<ER_Solution_Line_Item__c> aliListToInsert2 = new List<ER_Solution_Line_Item__c>();
        List<ER_Solution_Line_Item__c> fcliListToInsert2 = new List<ER_Solution_Line_Item__c>();
        List<ER_Delivery_Site__c> dsListToInsert = new List<ER_Delivery_Site__c>();
        List<ER_Solution_Line_Item__c> dsliListToInsert = new List<ER_Solution_Line_Item__c>();
        
        Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
        newSolution.ProductCode = 'testSolution';
        newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        solutionListToInsert2.add(newSolution);
        
        Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
        newSolution2.ProductCode = 'testSolution2';
        newSolution2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        solutionListToInsert2.add(newSolution2);

        Product2 newSolution3 = APER07_UtilityTestMethod.getsolution('newSolution3');
        newSolution3.ProductCode = 'newSolution3';
        newSolution3.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        solutionListToInsert2.add(newSolution3);
        
        Product2 newSolution4 = APER07_UtilityTestMethod.getsolution('newSolution4');
        newSolution4.ProductCode = 'newSolution4';
        newSolution4.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        solutionListToInsert2.add(newSolution4);
        
        insert solutionListToInsert2;
        
        Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice2', newSolution4.id);
        newService2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        serviceListToInsert2.add(newService2);

        Product2 newService3 = APER07_UtilityTestMethod.getservice('testservice', newSolution2.id);
        newService3.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        serviceListToInsert2.add(newService3);

        Product2 newService4 = APER07_UtilityTestMethod.getservice('testservice2', newSolution3.id);
        newService4.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
        serviceListToInsert2.add(newService4);

        insert serviceListToInsert2;
        
        PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
        pbeListToInsert2.add(newPriceBookEntry2);
        
        PriceBookEntry newPriceBookEntry3 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook2.id, newService3.id);
        pbeListToInsert2.add(newPriceBookEntry3);

        PriceBookEntry newPriceBookEntry4 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook2.id, newService4.id);
        pbeListToInsert2.add(newPriceBookEntry4);

        insert pbeListToInsert2;
        
        Contract testContract2 = APER07_UtilityTestMethod.getContract(cAccount2.id, Date.today(),Label.LABS_SF_Contract_Status_Draft,newPriceBook2.Id);
        testContract2.recordtypeid =Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId();
        insert testContract2;

        ER_ContractLineItem__c testContractLineItem4 = APER07_UtilityTestMethod.getContractLineItem(testContract2.id, newService2.id,newPriceBookEntry2.id, 1, 1);
        cliListToInsert2.add(testContractLineItem4);

        ER_ContractLineItem__c testContractLineItem3 = APER07_UtilityTestMethod.getContractLineItem(testContract2.id, newService3.id,newPriceBookEntry3.id, 1, 1);
        cliListToInsert2.add(testContractLineItem3);

        insert cliListToInsert2;

        //testContract2.status = Label.LABS_SF_Contract_Status_Activated; 
        //update testContract2;
        
        ER_Solution_Line_Item__c testAccountLineItem3 = APER07_UtilityTestMethod.getAccountLineItem(cAccount2.Id, testContract2.Id, newSolution2.Id);
        testAccountLineItem3.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
        aliListToInsert2.add(testAccountLineItem3);
        
        ER_Solution_Line_Item__c testAccountLineItem4 = APER07_UtilityTestMethod.getAccountLineItem(cAccount2.Id, testContract2.Id, newSolution3.Id);
        testAccountLineItem4.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
        aliListToInsert2.add(testAccountLineItem4);
        
        insert aliListToInsert2;
        
        ER_Solution_Line_Item__c testFinancialCenterLineItem3 = APER07_UtilityTestMethod.getFinancialCenterLineItem(testFinancialCenter2.Id, testContract2.Id,testAccountLineItem4.id, newSolution2.Id);
        fcliListToInsert2.add(testFinancialCenterLineItem3);
        
        ER_Solution_Line_Item__c testFinancialCenterLineItem4 = APER07_UtilityTestMethod.getFinancialCenterLineItem(testFinancialCenter2.Id, testContract2.Id,testAccountLineItem3.id, newSolution3.Id);
        fcliListToInsert2.add(testFinancialCenterLineItem4);
        
        insert fcliListToInsert2;

        List<Contact> contactList2 = new List<Contact>();

        Contact c2 = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test12', 'test13');
        c2.AccountId = cAccount2.Id;
        c2.Email = 'test2@test.com';
        
        Contact c3 = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test24', 'test25');
        c3.AccountId = cAccount2.Id;
        c3.Email = 'test3@test.com';
        contactList2.add(c2);
        contactList2.add(c3);
        insert contactList2;
        
        ER_Delivery_Site__c testDeliverySite2 = APER07_UtilityTestMethod.getDeliverySite('APER29_DistributionPoint_Management_Test',cAccount2.id, testFinancialCenter2.id);
        testDeliverySite2.ER_Street__c = '123 Dummy St';
        testDeliverySite2.ER_Zip_Code__c = '99000';
        testDeliverySite2.ER_City__c = 'Anycity';
        testDeliverySite2.ER_Country__c = 'Country';
        dsListToInsert.add(testDeliverySite2);
        
        ER_Delivery_Site__c testDeliverySite3 = APER07_UtilityTestMethod.getDeliverySite('APER29_DistributionPoint_Management_Test2',cAccount2.id, testFinancialCenter2.id);
        testDeliverySite3.ER_Street__c = '123 Dummy St';
        testDeliverySite3.ER_Zip_Code__c = '99000';
        testDeliverySite3.ER_City__c = 'Anycity';
        testDeliverySite3.ER_Country__c = 'Country';
        dsListToInsert.add(testDeliverySite3);
        
        insert dsListToInsert;
        
        ER_Solution_Line_Item__c testDeliverySiteLineItem = APER07_UtilityTestMethod.getDeliverySiteLineItem(testDeliverySite.id, testContract2.id,testFinancialCenterLineItem4.id, newSolution.id);
        dsliListToInsert.add(testDeliverySiteLineItem);
        
        ER_Solution_Line_Item__c testDeliverySiteLineItem2 = APER07_UtilityTestMethod.getDeliverySiteLineItem(testDeliverySite3.id, testContract2.id, testFinancialCenterLineItem3.id, newSolution2.id);
        dsliListToInsert.add(testDeliverySiteLineItem2);
        
        ER_Solution_Line_Item__c testDeliverySiteLineItem3 = APER07_UtilityTestMethod.getDeliverySiteLineItem(testDeliverySite2.id, testContract2.id, testFinancialCenterLineItem4.id, newSolution2.id);
        dsliListToInsert.add(testDeliverySiteLineItem3);
        
        insert dsliListToInsert;
        
        ER_Distribution_Point__c testDistributionPoint2 = APER07_UtilityTestMethod.getDistributionPoint('APER24_DistributionPoint_Management_Test2', testDeliverySite.id);
        testDistributionPoint2.ER_Contact__c = c2.Id;
        testDistributionPoint2.ER_Street__c = '123 Dummy St';
        testDistributionPoint2.ER_Zip_Code__c = '99000';
        testDistributionPoint2.ER_City__c = 'Anycity';
        testDistributionPoint2.ER_Country__c = 'Country';
        insert testDistributionPoint2;
        
        ER_Solution_Line_Item__c testDistributionPointLineItem = APER07_UtilityTestMethod.getDistributionPointLineItem(testDistributionPoint2.id, testContract2.id, testDeliverySiteLineItem.id, newSolution.id);
        insert testDistributionPointLineItem;
        
        ER_Solution_Line_Item__c testDistributionPointLineItem2 = APER07_UtilityTestMethod.getDistributionPointLineItem(testDistributionPoint2.id, testContract2.id, testDeliverySiteLineItem2.id, newSolution2.id);
        insert testDistributionPointLineItem2;
        
        ER_Financial_Center__c testFinancialCenterS = APER07_UtilityTestMethod.getFinancialCenter('APER14_Store_Management_Test',newMerchantAccount.id, Label.LABS_SF_FinancialCenter_Merchant,'Test','Test','Test','Test');
        testFinancialCenterS.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
        insert testFinancialCenterS;

        ER_Store__c testStore = APER07_UtilityTestMethod.getStore('APER14_Store_Management_Test',newMerchantAccount.id, testFinancialCenterS.id, Date.today(),'Test','Test','Test','Test');
        insert testStore;
        
        testDeliverySite.ER_Delivery_Contact__c = contactTest.id;
        update testDeliverySite;
    }
    
    static testMethod void deletePrimaryContact() {
        
        List<ER_Contact_Role__c> contractRoleList = [select id, ER_Primary__c from ER_Contact_Role__c limit 1];
        if(!contractRoleList.isEmpty()){
            
            delete contractRoleList;
        }
        
    }
    
    static testMethod void updatePrimaryContactRole(){
        Map<Id, ER_Delivery_Site__c> deliverySiteMap = new Map<Id,ER_Delivery_Site__c>();
        Map<Id, ER_Delivery_Site__c> deliverySiteOldMap = new Map<Id, ER_Delivery_Site__c>();
        
        ER_Delivery_Site__c ds = [Select id, name, ER_Delivery_Contact__c from ER_Delivery_Site__c WHERE Name = 'APER29_DistributionPoint_Management_Test' limit 1];
        
        Contact c = [Select id from Contact WHERE FirstName = 'test24' limit 1];
        
        deliverySiteMap.put(ds.id,ds);
        
        ds.ER_Delivery_Contact__c = c.Id;
        update ds;
        
        deliverySiteOldMap.put(ds.Id, ds);
        
        Test.startTest();
        APER28_DeliverySite_Management.updatePrimaryContactRole(deliverySiteMap, deliverySiteOldMap);
        Test.stopTest();
        
    }
    
    static testMethod  void updatePrimaryContactRoleTest(){
        Map<Id, ER_Distribution_Point__c> distributionPointNewMap = new Map<Id, ER_Distribution_Point__c>();
        Map<Id, ER_Distribution_Point__c> distributionPointOldMap = new Map<Id, ER_Distribution_Point__c>();
        ER_Distribution_Point__c dp = [SELECT id,ER_Contact__c FROM ER_Distribution_Point__c LIMIT 1];
        Contact c = [SELECT  id FROM Contact LIMIT 1];
        distributionPointNewMap.put(dp.Id,dp);
        dp.ER_Contact__c = c.Id;
        update dp;
        distributionPointOldMap.put(dp.Id,dp);

        Test.startTest();
        APER29_DistributionPoint_Management.updatePrimaryContactRole(distributionPointNewMap, distributionPointOldMap);
        Test.stopTest();


    }
    
    static testMethod  void updatePrimaryContactRoleTest2(){
        Map<Id, ER_Distribution_Point__c> distributionPointNewMap = new Map<Id, ER_Distribution_Point__c>();
        Map<Id, ER_Distribution_Point__c> distributionPointOldMap = new Map<Id, ER_Distribution_Point__c>();
        ER_Distribution_Point__c dp = [SELECT id,ER_Contact__c FROM ER_Distribution_Point__c LIMIT 1];
        
        Contact c = [SELECT  id FROM Contact LIMIT 1];
        distributionPointNewMap.put(dp.Id,dp);
        dp.ER_Contact__c = c.Id;
        update dp;
        distributionPointOldMap.put(dp.Id,dp);

        Test.startTest();
        APER24_ContactRole_Management.UpdatePrimaryContactRole(distributionPointNewMap, distributionPointOldMap);
        Test.stopTest();
    }
    
    @IsTest
    static void createZuoraBillingAccount() {
        Account a = APER07_UtilityTestMethod.getCompany('APER17_Contact_Management_Test_Zuora');
        insert a;
        
        Contact c = TestDataFactory.newContact(a);
        insert c;
        
        Test.startTest();
        SendToZuoraMock zuoraMock = new SendToZuoraMock();
        Test.setMock(HttpCalloutMock.class, zuoraMock);
        ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter('fc' + Datetime.now().getTime(), a.Id, Label.LABS_SF_FinancialCenter_Client, 'Some Street', 'Warsaw', '00-001', 'Poland');
        fc.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
        fc.ER_Contact__c = c.Id;
        insert fc;
        
        Test.stopTest();
        
    }
    
    @IsTest
    static void updateZuoraBillingAccount() {
    
        Account a = APER07_UtilityTestMethod.getCompany('APER17_Contact_Management_Test_Zuora');
        insert a;
        
        Contact c = TestDataFactory.newContact(a);
        insert c;
        
        ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter('fc' + Datetime.now().getTime(), a.Id, Label.LABS_SF_FinancialCenter_Client, 'Some Street', 'Warsaw', '00-001', 'Poland');
        fc.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
        fc.ER_Contact__c = c.Id;
        insert fc;
        
        Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
        ba.Name = 'BaName';
        ba.ER_Financial_Center__c = fc.Id;
        ba.Zuora__AccountNumber__c = 'A00000111';
        ba.Zuora__Account__c = a.Id;
        ba.SEQUENCE_SET__c = 'AFFILIATE';
        ba.Zuora__Status__c = 'Active';
        ba.CurrencyIsoCode = 'PLN';
        insert ba;
        
        Test.startTest();
        SendToZuoraMock zuoraMock = new SendToZuoraMock();
        Test.setMock(HttpCalloutMock.class, zuoraMock);
        fc.ER_Zip_Code__c  = 'ZIP999';
        update fc;
        Test.stopTest();
        
    }
    
    @IsTest
    static void manageFCLIForNewFinancialCenter() {

        Map<Id, ER_Financial_Center__c> financialCenterMap = new Map<Id, ER_Financial_Center__c>();
        List<ER_Financial_Center__c> financialCenterList = new List<ER_Financial_Center__c>();

        Account merchantAccount = [select id from Account where Name = 'APER17_Contact_Management_Test' LIMIT 1];

        ER_Financial_Center__c testFinancialCenter3 = APER07_UtilityTestMethod.getFinancialCenter('APER30_FinancialCenter_Management_TEST_TEST3', merchantAccount.id, Label.LABS_SF_FinancialCenter_Client, 'Test', 'Test', 'Test', 'Test');
        testFinancialCenter3.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
        financialCenterList.add(testFinancialCenter3);

        ER_Financial_Center__c testFinancialCenter4 = APER07_UtilityTestMethod.getFinancialCenter('APER30_FinancialCenter_Management_TEST_TEST4', merchantAccount.id, Label.LABS_SF_FinancialCenter_Merchant, 'Test', 'Test', 'Test', 'Test');
        testFinancialCenter4.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
        financialCenterList.add(testFinancialCenter4);

        insert financialCenterList;

        for(ER_Financial_Center__c fc : financialCenterList) {

            financialCenterMap.put(fc.Id, fc);
        }
		
        Test.startTest();
        APER30_FinancialCenter_Management.manageFCLIForNewFinancialCenter(financialCenterMap);
        Test.stopTest();
    }
    
    static testMethod void manageDSLIFromContract() {
        
        List<Contract> contractList = [select id, AccountId,Status from Contract where Status=: Label.LABS_SF_Contract_Status_Activated];
        if(!contractList.isEmpty()){
            Test.startTest();
            APER28_DeliverySite_Management.manageDSLIFromContract(contractList[0]);
            Test.stopTest();
        }
    }
    
    static testMethod void manageDSLIForNewDeliverySite() {
        
        Map<Id, ER_Delivery_Site__c> deliverySiteMap = new Map<Id, ER_Delivery_Site__c>();
        
        Account clientAccount = [select id from Account where Name = 'APER17_Contact_Management_Test' LIMIT 1];
        ER_Financial_Center__c testFinancialCenter = [select Id from ER_Financial_Center__c where Name = 'APER24_ContactRole_Management_Test'];

        ER_Delivery_Site__c testDeliverySite2 = APER07_UtilityTestMethod.getDeliverySite('APER28_DeliverySite_Management_TEST1',clientAccount.id, testFinancialCenter.id);
        insert testDeliverySite2;
        
        deliverySiteMap.put(testDeliverySite2.Id, testDeliverySite2);
        
        Test.startTest();
        APER28_DeliverySite_Management.manageDSLIForNewDeliverySite(deliverySiteMap);
        Test.stopTest();
    }

    @IsTest
    static void updateDistributionPointLineItemsForAccount(){
        String accId = [SELECT Id FROM Account LIMIT 1].Id;
        String contractId = [SELECT Id FROM Contract LIMIT 1].Id;

        String solution2 = [SELECT ProductCode FROM Product2 Limit 3][1].ProductCode;
        String solution3 = [SELECT ProductCode FROM Product2 Limit 3][2].ProductCode;

        Set<String> solutions = new Set<String>();
        solutions.add(solution2);
        solutions.add(solution3);

        Test.startTest();
        GenericWithoutSharing.updateDistributionPointLineItemsForAccount(solutions, contractId, accId, 'Activated'); 
        Test.stopTest();
    }
    
    static testMethod void manageDPLIFromContract() {
        
        List<Contract> contractList = [select id, AccountId,Status from Contract where Status=: Label.LABS_SF_Contract_Status_Activated];
        if(!contractList.isEmpty()){
            
            APER29_DistributionPoint_Management.manageDPLIFromContract(contractList[0]);
        }
    }
    
    static testMethod void manageDPLIForNewDistributionPoint() {
        
        Map<Id, ER_Distribution_Point__c> distributionPointMap = new Map<Id, ER_Distribution_Point__c>();
    
        Account clientAccount = [SELECT id FROM Account WHERE Name = 'APER17_Contact_Management_Test' LIMIT 1];
        ER_Delivery_Site__c testDeliverySite = [SELECT Id FROM ER_Delivery_Site__c LIMIT 1];
    
        ER_Distribution_Point__c testDistributionPoint2 = APER07_UtilityTestMethod.getDistributionPoint('APER29_DistributionPoint_Management_Test3', testDeliverySite.id);
        insert testDistributionPoint2;
    
        distributionPointMap.put(testDistributionPoint2.Id, testDistributionPoint2);
    	Test.startTest();
        APER29_DistributionPoint_Management.manageDPLIForNewDistributionPoint(distributionPointMap);
        Test.stopTest();
  }

}