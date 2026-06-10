/**
 * @author : ALK
 * @date : 01/03/2021
 * @desc : SolutionLineItemTrigger
 * @see SolutionLineItemTrigger
 */

trigger SolutionLineItemTrigger on ER_Solution_Line_Item__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new SolutionLineItemTriggerHandler());
}