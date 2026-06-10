/**
 * @author : AAZ
 * @date : 30/11/2021
 * @desc : ZuoraRefundTrigger
 * @see ZuoraRefundTrigger
 */

trigger ZuoraRefundTrigger on Zuora__Refund__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ZuoraRefundTriggerHandler());
}