/**
 * Created by khaddouch on 06/05/2021.
 */

trigger QuoteTrigger on Quote(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new QuoteTriggerHandler());
}