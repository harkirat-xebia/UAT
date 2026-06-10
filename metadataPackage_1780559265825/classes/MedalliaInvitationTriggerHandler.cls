/**
 * @author: ALK
 * @date: 17/03/2022
 * @desc: MedalliaInvitationTriggerHandler
 * @see: MedalliaInvitationTriggerHandler
 */

public with sharing class MedalliaInvitationTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('MedalliaInvitationTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK 17/03/2022 - Update the last invite on the account level
    //Medallia_Invitation_Management.updateAccountLastInvite(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK 17/03/2022 - Update the last invite on the account level
    //Medallia_Invitation_Management.updateAccountLastInvite(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}