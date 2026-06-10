/**
 * @author : AAZ
 * @date : 29/11/2021
 * @desc : ZuoraCreditMemoTriggerHandler
 * @see ZuoraCreditMemoTriggerHandler
 */

public with sharing class ZuoraCreditMemoTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ZuoraCreditMemoTriggerHandler')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Delete CreditMemo Record if it's a draft
    //if(UtilsBypass.canTrigger('deleteCreditMemo'))
    ZuoraCreditMemo_Management_AP01.deleteCreditMemo(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Delete CreditMemo Record if it's a draft
    //if(UtilsBypass.canTrigger('deleteCreditMemo'))
    ZuoraCreditMemo_Management_AP01.deleteCreditMemo(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}