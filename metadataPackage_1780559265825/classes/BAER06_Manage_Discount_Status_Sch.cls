/*
-------------------------------------------------------------------------------------------------------------------------------
-- Maintenance History:
--
-- Date           Name       Version  Remarks
-- -----------    ----       -------  ------------------------------------------------------------------------------------------------
-- 28-Apr-2022    VJoye    1.0      Scheduler to schedule batch BAER06

-------------------------------------------------------------------------------------------------------------------------------
*******************************************************************************************************************************
*/
global class BAER06_Manage_Discount_Status_Sch implements Schedulable {
  global void execute(SchedulableContext sc) {
    Integer batchsize = 100;
    //SELECT Id, ER_Status__c, ER_Contract__c, RecordtypeId, ER_Start_Date__c, ER_End_Date__c FROM ER_Promo_Code__c LIMIT 50000
    String soqlDyn = Label.LABS_SF_BAER06_Query_Promo_Code;

    BAER06_Manage_Discount_Status job = new BAER06_Manage_Discount_Status(soqlDyn);
    Database.executeBatch(job, batchsize);
  }
}