/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Factory implementation based on business unit
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--11/02/2023    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class CreditScoring implements CreditScoringInterface {
  public String BU;

  private final Map<String, System.Type> BU_SERVICES = new Map<String, System.Type>{ 'FR' => CreditScoringFR.class };

  /**
   * @author Noor
   * @description instantiate class with the BU
   * @param BU
   */
  public CreditScoring(String BU) {
    this.BU = BU;
  }

  /**
     * @description retrieves credit information for a specified list of records in Salesforce,
                    either Accounts or Leads, by making a REST API call to CreditSafe using the specified registration number.
                    The received credit information is then used to update the corresponding records in Salesforce.
     * @param sOjectId
     *
     * @return the json result
     */
  public String callWebserviceAndUpdateRecords(Id sOjectId) {
    CreditScoringInterface creditScoring = (CreditScoringInterface) BU_SERVICES.get(BU).newInstance();
    return creditScoring.callWebserviceAndUpdateRecords(sOjectId);
  }
}