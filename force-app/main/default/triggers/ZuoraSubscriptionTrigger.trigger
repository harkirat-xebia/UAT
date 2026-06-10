/**
 * @author : AAZ
 * @date : 28/07/2021
 * @desc : ZuoraSubscriptionTrigger
 * @see ZuoraSubscriptionTrigger
 */

trigger ZuoraSubscriptionTrigger on Zuora__Subscription__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ZuoraSubscriptionTriggerHandler());
}