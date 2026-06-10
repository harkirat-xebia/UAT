/**
 * @author : AAM
 * @date : 27/05/2021
 * @desc : AccountTrigger
 * @see AccountTrigger
 */

trigger AccountTrigger on Account(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new AccountTriggerHandler());
}