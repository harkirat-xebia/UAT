/**
 * @author : ELAK
 * @date : 07/12/2021
 * @desc : OpportunityTrigger
 * @see OpportunityTrigger
 */

trigger OpportunityTrigger on Opportunity(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new OpportunityTriggerHandler());
}