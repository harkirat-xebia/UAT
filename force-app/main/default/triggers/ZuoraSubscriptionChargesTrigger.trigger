/**
 * @author : AAZ
 * @date : 29/07/2021
 * @desc : ZuoraSubscriptionChargesTrigger
 * @see ZuoraSubscriptionChargesTrigger
 */

trigger ZuoraSubscriptionChargesTrigger on Zuora__SubscriptionProductCharge__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ZuoraSubscriptionChargesTriggerHandler());
}