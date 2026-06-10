/**
 * @author : Noor
 * @date : 11/07/2023
 * @desc : LoopTrigger
 * @see LoopTriggerHandler
 */
trigger LoopTrigger on ER_Loop__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete
) {
  TriggerDispatcher.run(new LoopTriggerHandler());
}