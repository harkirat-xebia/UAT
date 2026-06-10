/**
 * @author : ALK
 * @date : 25/05/2021
 * @desc : AcceptorToLoopTrigger
 * @see AcceptorToLoopTrigger
 */

trigger AcceptorToLoopTrigger on ER_Acceptor_to_Loop__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new AcceptorToLoopTriggerHandler());
}