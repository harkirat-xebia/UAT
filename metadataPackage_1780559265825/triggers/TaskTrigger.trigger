/**
 * Created by noorgoolamnabee on 26/05/2023.
 */

trigger TaskTrigger on Task(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new TaskTriggerHandler());
}