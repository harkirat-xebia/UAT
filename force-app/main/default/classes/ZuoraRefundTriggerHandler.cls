/**
 * @author : AAZ
 * @date : 30/11/2021
 * @desc : ZuoraRefundTriggerHandler
 * @see ZuoraRefundTriggerHandler
 */

public with sharing class ZuoraRefundTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ZuoraRefundTriggerHandler')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Delete Refund Record if it's a draft
    //if(UtilsBypass.canTrigger('deleteRefund'))
    ZuoraRefund_Management_AP01.deleteRefund(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Delete Refund Record if it's a draft
    //if(UtilsBypass.canTrigger('deleteRefund'))
    ZuoraRefund_Management_AP01.deleteRefund(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}