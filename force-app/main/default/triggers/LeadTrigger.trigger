/**
 * @author : ALK
 * @date : 12/11/2021
 * @desc : LeadTrigger
 * @see LeadTrigger
 */

trigger LeadTrigger on Lead(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new LeadTriggerHandler());
}