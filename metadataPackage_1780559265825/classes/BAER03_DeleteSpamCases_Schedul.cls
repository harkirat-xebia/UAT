/*
-------------------------------------------------------------------------------------------------------------------------------
-- Maintenance History:
--
-- Date           Name       Version  Remarks
-- -----------    ----       -------  ------------------------------------------------------------------------------------------------
-- 10-Mar-2021    VJoye    1.0      Scheduler to schedule batch BAER03 to delete spam cases

-------------------------------------------------------------------------------------------------------------------------------
*******************************************************************************************************************************
*/
global class BAER03_DeleteSpamCases_Schedul implements Schedulable {
  global void execute(SchedulableContext sc) {
    Integer batchsize = 100;

    /*String query ='';*/

    String soqlDyn = Label.LAB_SF_CASE_SOQLBATCH03;

    if (Test.isRunningTest()) {
      soqlDyn = 'SELECT Id, Status, ClosedDate FROM Case';
    }

    BAER03_DeleteSpamCases job = new BAER03_DeleteSpamCases(soqlDyn);
    Database.executeBatch(job, batchsize);
  }
}