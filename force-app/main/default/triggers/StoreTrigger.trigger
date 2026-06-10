/**
 * Created by davram on 3/31/2021.
 */

trigger StoreTrigger on ER_Store__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new StoreTriggerHandler());
}