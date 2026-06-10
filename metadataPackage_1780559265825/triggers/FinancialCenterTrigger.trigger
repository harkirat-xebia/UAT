/**
 * -----------------------------------------------------
 * @author : AAZ
 * @date : 26/04/2021
 * @desc : FinancialCenterTrigger
 * @see FinancialCenterTrigger
 * -----------------------------------------------------
 */

trigger FinancialCenterTrigger on ER_Financial_Center__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new FinancialCenterTriggerHandler());
}