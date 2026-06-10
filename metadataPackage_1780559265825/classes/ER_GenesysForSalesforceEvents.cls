/**
 * @author: ALK
 * @date: 22/06/2022
 * @desc: ER_GenesysForSalesforceEvents
 * @see: ER_GenesysForSalesforceEvents
 */

public with sharing class ER_GenesysForSalesforceEvents {
  @AuraEnabled
  public static String changeRecordOwner(String recordId) {
    try {
      if (String.isNotBlank(recordId) && (recordId.length() == 15 || recordId.length() == 18)) {
        if (recordId.startsWith(Constants.LEAD_OBJECT_PREFIX)) {
          update new Lead(Id = recordId, OwnerId = UserInfo.getUserId());
        } else if (recordId.startsWith(Constants.CASE_OBJECT_PREFIX)) {
          update new Case(Id = recordId, OwnerId = UserInfo.getUserId());
        }
      }
    } catch (Exception e) {
      System.debug(
        '>>>>> ALK - ER_GenesysForSalesforceEvents.changeRecordOwner Line ' +
        e.getLineNumber() +
        ' - Error :  ' +
        e.getMessage()
      );
      return e.getMessage();
    }

    return null;
  }
}