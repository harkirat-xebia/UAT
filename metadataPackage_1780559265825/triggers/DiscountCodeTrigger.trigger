/**
 * @author : VJOY
 * @date : 27/03/2022
 * @desc : DiscountCodeTrigger
 * @see DiscountCodeTrigger
 */

trigger DiscountCodeTrigger on ER_Promo_Code__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new DiscountCodeTriggerHandler());
}