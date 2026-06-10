/**
 * @author : AAM
 * @date : 29/03/2021
 * @desc : GuestEventTriggerHandler
 * @see GuestEventTriggerHandler
 */

public with sharing class GuestEventTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('GuestEventTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    // AAM - Create Lead, Convert leads ...
    APER30_AutoEnrollment_Management.doGuestEventOperations(newItems);
    AutoenrollmentManageStoreWOS.manageStoreEvents((List<Guest_Event__e>) Trigger.New);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
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