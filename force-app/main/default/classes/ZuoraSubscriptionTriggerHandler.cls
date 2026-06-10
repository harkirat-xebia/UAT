/**
 * @author : AAZ
 * @date : 28/07/2021
 * @desc : ZuoraSubscriptionTriggerHandler
 * @see ZuoraSubscriptionTriggerHandler
 */

public with sharing class ZuoraSubscriptionTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ZuoraSubscriptionTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Noor Link the subscription to the contract
    ZuoraSubscription_Management_AP01.updateContractSubscription(
      (Map<Id, Zuora__Subscription__c>) newItems,
      (Map<Id, Zuora__Subscription__c>) oldItems
    );

    //AAZ: link the Contract to Child Subs
    //IMPORTANT - THIS METHOD SHOULD BE KEPT AFTER ZuoraSubscription_Management_AP01.updateContractSubscription
    ZuoraSubscription_Management_AP01.setContractIdOnChildSubscription(Trigger.new);
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