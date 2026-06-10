/**
 * @author : AAM
 * @date : 27/05/2021
 * @desc : AccountTrigger
 * @see AccountTrigger
 */

trigger ER_ContractLineItemTrigger on ER_ContractLineItem__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ER_ContractLineItemTriggerHandler());
}