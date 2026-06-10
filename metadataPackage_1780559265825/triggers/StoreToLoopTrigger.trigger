trigger StoreToLoopTrigger on ER_Store_to_Loop__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new StoreToLoopTriggerHandler());
}