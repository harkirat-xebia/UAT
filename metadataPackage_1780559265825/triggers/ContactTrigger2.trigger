/**
 * @author : AAM
 * @date : 26/05/2021
 * @desc : ContactTrigger2
 * @see ContactTrigger2
 */

trigger ContactTrigger2 on Contact(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ContactTriggerHandler());
}