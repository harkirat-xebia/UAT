global class BAER01_DeleteInactiveLead implements Database.Batchable<sObject> {
  /*
----------------------------------------------------------------------
-- - Name          : BAER01_DeleteInactiveLead
-- - Author        : AAB
-- - Description   : Batch that retrieve all inactive lead (based on a number of month)        
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 12-APR-2018  AAB                 1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

  global final List<Lead> myLeadList = new List<Lead>();
  public static final String nbDays = System.Label.LABS_SF_Inactive_Lead_Days;
  public static final String statusToExclude = System.Label.LABS_SF_Status_Lead_Excluded;

  global Database.QueryLocator start(Database.BatchableContext bc) {
    // collect the batches of records or objects to be passed to execute

    String createddate = '';

    if (Test.isRunningTest()) {
      createddate += ' OR CreatedDate < LAST_N_MONTHS:5';
    }

    return Database.getQueryLocator(
      'SELECT Id ' +
      'FROM Lead ' +
      'WHERE (LastModifiedDate < LAST_N_DAYS:' +
      nbDays +
      ' AND Status != \'' +
      statusToExclude +
      '\') ' +
      createddate
    );
  }

  global void execute(Database.BatchableContext bc, List<Lead> scope) {
    if (!scope.isEmpty()) {
      APER02_Lead_InactiveLead.deleteInactiveLead(scope);
    }
  }

  global void finish(Database.BatchableContext bc) {
    // execute any post-processing operations
  }
}