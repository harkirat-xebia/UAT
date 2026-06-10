/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Interface for retrieves credit information for a specified list of records in Salesforce,
                    either Accounts or Leads, by making a REST API call to CreditSafe using the specified registration number.
                    The received credit information is then used to update the corresponding records in Salesforce.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--11/02/2023    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public interface CreditScoringInterface {
  /**
      * @description retrieves credit information for a specified list of records in Salesforce,
                    either Accounts or Leads, by making a REST API call to CreditSafe using the specified registration number.
                    The received credit information is then used to update the corresponding records in Salesforce.
      * @param sOjectId
      *
      * @return Json
      */
  String callWebserviceAndUpdateRecords(Id sOjectId);
}