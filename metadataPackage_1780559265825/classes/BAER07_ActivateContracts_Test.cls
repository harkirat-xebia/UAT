@isTest
public class BAER07_ActivateContracts_Test {

    @testSetup
    static void setup() {

        Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('BAER07_ActivateContracts_Test');
        insert newMerchantAccount;

        PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
        //update newPriceBook;

        Contract contractInst = APER07_UtilityTestMethod.getContract(newMerchantAccount.Id, Date.today(), Label.LABS_SF_Contract_Status_Draft, newPriceBook.Id);
        contractInst.Status = 'Draft';
        contractInst.ER_BUPicklist__c = 'HU';
        insert contractInst;

    }

    @IsTest
    static void testBatchMigration() {

        Test.startTest();
        String queryStr = 'SELECT Id, AccountId, Status, StartDate, EndDate, CustomerSignedDate, ER_Creation_date_in_OS__c, ER_Last_date_of_Sync__c, ' +
                'ER_OpportunityId__c, ER_OpportunityId__r.ER_IsAmended__c, ER_Offline__c, Subscription__c, RecordType.DeveloperName ' +
                'FROM Contract WHERE Status=\'Draft\' AND ER_BUPicklist__c = \'HU\' order by LastModifiedDate asc';

        BAER07_ActivateContracts activateContractBatch = new BAER07_ActivateContracts(queryStr);
        Database.executeBatch(activateContractBatch , Integer.valueOf(Label.LABS_SF_BAHU01_ManageTerminatedContract_batchSize));

        Test.stopTest();
    }

    @IsTest
    static void testSchedule() {
        BAER07_ActivateContracts scheduler = new BAER07_ActivateContracts();
        System.schedule('BAER07_ActivateContractsSchedulerTest', '0 0 1 * * ? *', scheduler);

    }
}