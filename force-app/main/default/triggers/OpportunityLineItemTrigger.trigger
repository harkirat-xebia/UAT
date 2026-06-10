/**
 * Created by khaddouch on 29/04/2021.
 */

trigger OpportunityLineItemTrigger on OpportunityLineItem(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new OpportunityLineItemTriggerHandler());
}