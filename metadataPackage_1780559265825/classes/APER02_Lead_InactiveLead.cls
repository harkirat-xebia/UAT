public with sharing class APER02_Lead_InactiveLead {
  /*
----------------------------------------------------------------------
-- - Name          : APER02_Lead_InactiveLead
-- - Author        : AAB
-- - Description   : Process the inactive Lead deletion       
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 12-FAPR-2018  AAB    				1.0      	Initial version
---------------------------------------------------------------------------------------
*/

  public static void deleteInactiveLead(List<Lead> leadToDelete) {
    Database.DeleteResult[] srList = new List<Database.DeleteResult>();
    Database.EmptyRecycleBinResult[] srListbis = new List<Database.EmptyRecycleBinResult>();

    // Delete all the "Lead"
    srList = Database.delete(leadToDelete, false);

    // Check the database deletion
    Check_theDatabaseDelete(srList);

    // Empty the recycle bin from the deleted records
    Database.emptyRecycleBin(leadToDelete);
  }

  static void Check_theDatabaseDelete(List<Database.DeleteResult> srList) {
    // Verify that the deletion should process by the batch
    // Iterate through each returned result
    System.debug('## >>> Check the Database delete  <<< ');
    for (Database.DeleteResult sr : srList) {
      if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('The batch has been successfully proceed. Lead ID: ' + sr.getId());
      } else {
        // Operation failed, so get all errors
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Lead fields that affected this error: ' + err.getFields());
        }
      }
    }
  }
}