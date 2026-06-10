/**
 * Created by khalilhaddouch on 04/09/2023.
 */
@isTest
public with sharing class BAER08_GenerateAmendedContracts_Test {

    @testSetup
    static void testSetup() {

        User ur = TestDataFactory.newUser('APER12', 'APER12','Local Admin', 'Spain', 'BE');
        ur.ER_BypassVR__c =true;
        ur.ER_bypassTrigger__c =true;
        insert ur;

        System.runAs(ur) {

            ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(UserInfo.getOrganizationId());
            settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
            upsert settings;

            Account newMerchantAccount = APER07_UtilityTestMethod.insertAccount('testCompany', 'ER_Company_Account_RT');
            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
            Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
            insert newSolution;

            Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
            insert newService;

            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
            insert newPriceBookEntry;

            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'APER12_Contract_Management_Test');
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.Pricebook2Id = newPriceBook.Id;
            insert newOpportunity;

            OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(newOpportunity.id, newPriceBookEntry.id);
            insert newOpportunityProduct;



            //Client records
            Account newClientAccount = APER07_UtilityTestMethod.insertAccount('clientCompany', 'ER_Company_Account_RT');
            Opportunity clientOpp = APER07_UtilityTestMethod.getOpportunity('ER_Client_Opportunity_RT', 'APER12_Client_Test');
            clientOpp.AccountId = newClientAccount.Id;
            clientOpp.Pricebook2Id = newPriceBook.Id;

            insert clientOpp;
            OpportunityLineItem clientOli = APER07_UtilityTestMethod.getOpportunityLineItem(clientOpp.id, newPriceBookEntry.id);
            insert clientOli;


            Contract con = APER07_UtilityTestMethod.getContract(newMerchantAccount.Id,System.today(),'Draft',newPriceBook.Id);
            con.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Client_Contract_RT');
            insert con;
            con.Status = 'Activated';
            con.ER_BUPicklist__c = 'BE';
            con.ER_Contract_Type__c = 'Operational';
            update con;

            ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(
                    con.Id,
                    newService.Id,
                    newPriceBookEntry.Id,
                    1,
                    1
            );
            insert testContractLineItem;


            Contract con2 = APER07_UtilityTestMethod.getContract(newMerchantAccount.Id,System.today(), 'Draft', newPriceBook.Id);
            con2.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Merchant_Contract_RT');
            insert con2;
            con2.Status = 'Activated';
            con2.ER_BUPicklist__c = 'BE';
            con2.ER_Contract_Type__c = 'Operational';
            update con2;


            ER_ContractLineItem__c testContractLineItem2 = APER07_UtilityTestMethod.getContractLineItem(
                    con2.Id,
                    newService.Id,
                    newPriceBookEntry.Id,
                    1,
                    1
            );
            insert testContractLineItem2;


            ER_Bulk_Contract_Amendment__c blkMassAmendment = new ER_Bulk_Contract_Amendment__c();
            blkMassAmendment.ER_Contract__c = con.Id;
            blkMassAmendment.ER_Type__c = 'UpdateT&C';
            blkMassAmendment.ER_BUPicklist__c = 'BE';
            blkMassAmendment.ER_Contract_Start_Date__c = Date.today() ;
            blkMassAmendment.ER_Invoicing_Frequency__c = 'Monthly';
            insert blkMassAmendment;

            ER_Bulk_Contract_Amendment__c blkMassAmendment1 = new ER_Bulk_Contract_Amendment__c();
            blkMassAmendment1.ER_Contract__c = con2.Id;
            blkMassAmendment1.ER_Type__c = 'UpdateT&C';
            blkMassAmendment1.ER_BUPicklist__c = 'BE';
            blkMassAmendment1.ER_Contract_Start_Date__c = Date.today() ;
            blkMassAmendment1.ER_Invoicing_Frequency__c = 'Monthly';
            insert blkMassAmendment1;

        }
    }

    @IsTest
    static void testBatchAmendment() {

        Test.startTest();

        String queryStr = 'SELECT Id, OwnerId, ER_Contract__c, ER_Type__c, ER_Service_Reference__c, ER_New_Price__c, ' +
                'ER_Contract_Start_Date__c, ER_BUPicklist__c, ER_Payment_Term__c, ER_Payment_Method__c, ER_Invoicing_Frequency__c, ' +
                'ER_Tech_ContractId__c, ER_Tech_Service_Reference__c, ER_Tech_Start_Date__c ' +
                'FROM ER_Bulk_Contract_Amendment__c ' +
                'WHERE ER_Contract_Start_Date__c = TODAY AND ER_BUPicklist__c = \'BE\' ORDER BY ER_Contract__c';

        BAER08_GenerateAmendedContracts createAmendmentsBatch = new BAER08_GenerateAmendedContracts(queryStr);
        Database.executeBatch(createAmendmentsBatch);

        Test.stopTest();
    }

    @IsTest
    static void testSchedule() {
        BAER08_GenerateAmendedContracts scheduler = new BAER08_GenerateAmendedContracts();
        System.schedule('BAER08_GenerateAmendedContractsTest', '0 0 1 * * ? *', scheduler);

    }

}