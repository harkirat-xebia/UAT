/**
 * @author Oussama LASFAR
 * @date 15/03/2019 (dd/mm/yyyy)
 * @description TEST Batch to Synchronize Terminated Contract
 */
@isTest
public class BAHU01_ManageTerminatedContract_Test {
  @testSetup
  static void setup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('BAHU01_ManageTerminatedContract_Test');
    insert newMerchantAccount;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
    //update newPriceBook;

    Contract contractInst = APER07_UtilityTestMethod.getContract(
      newMerchantAccount.Id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id
    );
    insert contractInst;

    contractInst.Status = 'Activated';
    contractInst.EndDate = Date.today();
    update contractInst;
  }

  @IsTest
  static void testBatchMigration() {
    Test.startTest();
    String queryStr =
      'SELECT id, AccountId, Status, StartDate, EndDate, CustomerSignedDate, ER_Creation_date_in_OS__c, ER_Last_date_of_Sync__c, ' +
      'ER_OpportunityId__c, ER_OpportunityId__r.ER_IsAmended__c, ER_Offline__c, ER_BUPicklist__c ' +
      'FROM Contract WHERE EndDate = TODAY AND Status=\'Activated\' AND ER_Termination_date_in_OS__c = null AND ER_Business_Unit__c = \'HU\' order by LastModifiedDate asc';

    BAHU01_ManageTerminatedContract terminatedContractBatch = new BAHU01_ManageTerminatedContract(queryStr);
    Database.executeBatch(
      terminatedContractBatch,
      Integer.valueOf(Label.LABS_SF_BAHU01_ManageTerminatedContract_batchSize)
    );

    Test.stopTest();
  }

  @IsTest
  static void testSchedule() {
    BAHU01_ManageTerminatedContract scheduler = new BAHU01_ManageTerminatedContract();
    System.schedule('BAHU01_ManageTerminatedContractSchedulerTest', '0 0 1 * * ? *', scheduler);
  }
}