public with sharing class StoreToLoopTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('StoreToLoopTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
    APER21_StoreToLoopManagement.checkDuplicateStoreToLoop(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER22_AcceptorToLoopManagement.runAcceptorToLoopCreation(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER22_AcceptorToLoopManagement.runAcceptorToLoopUpdate(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}