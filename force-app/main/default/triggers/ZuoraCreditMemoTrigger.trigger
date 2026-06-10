/**
 * @author : AAZ
 * @date : 29/11/2021
 * @desc : ZuoraCreditMemoTrigger
 * @see ZuoraCreditMemoTrigger
 */

trigger ZuoraCreditMemoTrigger on Zuora__CreditMemo__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ZuoraCreditMemoTriggerHandler());
}