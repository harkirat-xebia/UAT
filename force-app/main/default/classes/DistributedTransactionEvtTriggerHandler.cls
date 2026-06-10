/**
 * @author: ALK
 * @date: 04/01/2023
 * @desc: DistributedTransactionEvtTriggerHandler
 * @see: DistributedTransactionEvtTriggerHandler
 */

public with sharing class DistributedTransactionEvtTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('DistributedTransactionEvtTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    DistributedTransactionEvtManagement.executeTransaction(Trigger.new);
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