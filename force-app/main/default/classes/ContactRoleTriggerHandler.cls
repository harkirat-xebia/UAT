/**
 * Created by khaddouch on 14/06/2021.
 * @author KHAD
 * @date 14/06/2021
 */

 public with sharing class ContactRoleTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ContactRoleTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //KHAD Add sync method for contact role
    //APER24_ContactRole_Management.syncContactRoles(Trigger.new, null);//Commented Snehil 19/09/2024
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //KHAD Fill the creation date in OS in the Store level
    APER24_ContactRole_Management.syncContactRoleFlags(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //KHAD Add sync method for contact role
    APER24_ContactRole_Management.syncContactRoles(Trigger.new, (Map<Id, ER_Contact_Role__c>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    //VJOY - Avoid Primary contact role deletion
    APER24_ContactRole_Management.primaryContactDeleteErrorNotification(Trigger.old);
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}