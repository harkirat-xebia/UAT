/**
 * Created by davram on 3/30/2021.
 */

trigger AcceptorTrigger on ER_Acceptor__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new AcceptorTriggerHandler());
}