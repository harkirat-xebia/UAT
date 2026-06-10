/**
 * @author : ALK
 * @date : 18/05/2021
 * @desc : BillingAccountTrigger2
 * @see BillingAccountTrigger2
 */

trigger BillingAccountTrigger2 on Zuora__CustomerAccount__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new BillingAccountTriggerHandler());
}