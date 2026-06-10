/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Controller that implements an invocable method named "callCreditScoring" (used by screen flow getCreditScoring)
                    which retrieves credit information for a specified list of records in Salesforce,
                    either Accounts or Leads, by making a REST API call to a third-party service (CreditSafe) using the specified registration number.
                    The received credit information is then used to update the corresponding records in Salesforce.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--11/02/2023    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
global with sharing class CreditScoringController {
  @InvocableMethod
  public static List<String> callCreditScoring(List<Id> sObjectIds) {
    CreditScoring creditScoring = new CreditScoring(getBusinessUnit(sObjectIds[0]));
    String result = creditScoring.callWebserviceAndUpdateRecords(sObjectIds[0]);
    return new List<String>{ result };
  }

  private static String getBusinessUnit(Id id) {
    if (Utils.getSObjectType(id) == Constants.ACCOUNT) {
      Account ac = [SELECT Id, ER_BUPicklist__c FROM Account WHERE Id = :id];
      return ac.ER_BUPicklist__c;
    } else {
      Lead l = [SELECT Id, ER_BUPicklist__c FROM Lead WHERE Id = :id];
      return l.ER_BUPicklist__c;
    }
  }
}