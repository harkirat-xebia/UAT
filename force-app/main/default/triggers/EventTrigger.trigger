/**
 * Created by noorg on 04/08/2021.
 */

trigger EventTrigger on Event(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new EventTriggerHandler());
}