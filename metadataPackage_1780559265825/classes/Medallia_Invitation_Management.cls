/**
 * @author: ALK
 * @date: 17/03/2022
 * @desc: Medallia_Invitation_Management
 * @see: Medallia_Invitation_Management
 */

public with sharing class Medallia_Invitation_Management {
  /**
   * @author ALK
   * @date 17/03/2022
   * @description Update the last invite on the account level
   * @param invitations
   */
  /*public static void updateAccountLastInvite(List<medallia_xm__Invitation__c> invitations) {
    List<String> invitStatuses = new List<String>{ Constants.RECEIVED, Constants.INVITED };
    Map<Id, Datetime> mapAccountsInvitDate = new Map<Id, Datetime>();
    User currentUser = UtilsBypass.getCurrentUser();

    try {
      //Bypass all triggers not required need for this dml
      currentUser.ER_bypassTrigger__c = true;

      for (medallia_xm__Invitation__c item : invitations) {
        if (invitStatuses.contains(item.medallia_xm__Status__c) && item.medallia_xm__Account__c != null) {
          if (item.medallia_xm__Account__c != null)
            mapAccountsInvitDate.put(item.medallia_xm__Account__c, item.medallia_xm__Invitation_Delivered_Date__c);
        }
      }

      if (!mapAccountsInvitDate.isEmpty()) {
        for (List<Account> accounts : [
          SELECT
            Id,
            RecordTypeId,
            ER_BUPicklist__c,
            ER_Medallia_Invitation_Trigger_Date__c,
            ER_Medallia_Invitation_Week_Number__c
          FROM Account
          WHERE Id IN :mapAccountsInvitDate.keySet()
        ]) {
          for (Account a : accounts)
            a.ER_Medallia_Invitation_Delivered_Date__c = mapAccountsInvitDate.get(a.Id);
          APER20_Account_Management.populateIndividualInvitationTriggerDate(accounts);

          Database.update(accounts, false);
        }
      }
    } catch (Exception e) {
      System.debug('>>>>> ALK - updateAccountLastInvite error occurs : ' + e.getMessage());
    } finally {
      currentUser.ER_bypassTrigger__c = false;
    }
  }*/
}