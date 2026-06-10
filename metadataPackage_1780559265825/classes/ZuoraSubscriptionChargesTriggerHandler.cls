/**
 * @author : AAZ
 * @date : 29/07/2021
 * @desc : ZuoraSubscriptionChargesTriggerHandler
 * @see ZuoraSubscriptionChargesTriggerHandler
 */

public with sharing class ZuoraSubscriptionChargesTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ZuoraSubscriptionChargesTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Clone master Subscription for child Billing Accounts having no sub
    ZuoraSubscription_Management_AP01.cloneMasterSub(Trigger.new);
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