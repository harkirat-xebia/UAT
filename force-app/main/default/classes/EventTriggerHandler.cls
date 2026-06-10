/**
 * Created by noorg on 04/08/2021.
 */

public with sharing class EventTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('EventTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER34_Event_Management.isUserAboveInRoleHierarchy(Trigger.new, (Map<Id, Event>) oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}