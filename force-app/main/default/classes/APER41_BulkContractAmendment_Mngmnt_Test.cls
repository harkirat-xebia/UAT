/**
 * Created by khaddouch on 10/05/2023.
 */
@isTest
public with sharing class APER41_BulkContractAmendment_Mngmnt_Test {
    @testSetup
    static void testSetup() {

        User ur = TestDataFactory.newUser('APER12', 'APER12','Local Admin', 'Spain', 'ES');
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
            clientOpp.ER_BUPicklist__c = 'BE';

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

            ER_Bulk_Contract_Amendment__c blkMassAmendmentTest = new ER_Bulk_Contract_Amendment__c();
            blkMassAmendmentTest.ER_Contract__c = con.Id;
            blkMassAmendmentTest.ER_Type__c = 'UpdateT&C';
            blkMassAmendmentTest.ER_BUPicklist__c = 'BE';
            blkMassAmendmentTest.ER_Contract_Start_Date__c = Date.today() ;
            blkMassAmendmentTest.ER_Invoicing_Frequency__c = 'Monthly';
            insert blkMassAmendmentTest;

            ER_Bulk_Contract_Amendment__c blkMassAmendmentTest2 = new ER_Bulk_Contract_Amendment__c();
            blkMassAmendmentTest2.ER_Contract__c = con2.Id;
            blkMassAmendmentTest2.ER_Type__c = 'UpdateT&C';
            blkMassAmendmentTest2.ER_BUPicklist__c = 'BE';
            blkMassAmendmentTest2.ER_Contract_Start_Date__c = Date.today() ;
            blkMassAmendmentTest2.ER_Invoicing_Frequency__c = 'Monthly';
            insert blkMassAmendmentTest2;

        }
    }

    @IsTest
    static void fillTechnicalFields() {
        Test.startTest();
        Contract con2 = [
                SELECT Id, RecordType.DeveloperName
                FROM Contract
                WHERE RecordType.DeveloperName = 'ER_Merchant_Contract_RT'
                LIMIT 1
        ];
        ER_Bulk_Contract_Amendment__c blkMassAmendment = new ER_Bulk_Contract_Amendment__c();
        blkMassAmendment.ER_Contract__c = con2.id;
        blkMassAmendment.ER_Type__c = 'UpdateT&C';
        blkMassAmendment.ER_BUPicklist__c = 'BE';
        blkMassAmendment.ER_Contract_Start_Date__c = Date.today()+1 ;
        blkMassAmendment.ER_Invoicing_Frequency__c = 'Monthly';
        insert blkMassAmendment;
        Test.stopTest();
    }

    @IsTest
    static void amendContracts() {
        Test.startTest();
        List<ER_Bulk_Contract_Amendment__c> contractsToAmend = [SELECT Id, OwnerId, ER_Contract__c, ER_Type__c, ER_Service_Reference__c, ER_New_Price__c, ER_Contract_Start_Date__c, ER_BUPicklist__c, ER_Payment_Term__c, ER_Payment_Method__c, ER_Invoicing_Frequency__c, ER_Tech_ContractId__c, ER_Tech_Service_Reference__c, ER_Tech_Start_Date__c FROM ER_Bulk_Contract_Amendment__c WHERE ER_Contract_Start_Date__c = TODAY AND ER_BUPicklist__c = 'BE' ORDER BY ER_Contract__c];
        APER41_BulkContractAmendment_Management.amendContracts(contractsToAmend);
        Test.stopTest();
    }
}