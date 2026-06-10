/**
 * @author : AAZ
 * @date : 24/01/2023
 * @desc : ZuoraQuoteRatePlanChargeTrigger
 * @see ZuoraQuoteRatePlanChargeTrigger
 */

trigger ZuoraQuoteRatePlanChargeTrigger on zqu__QuoteRatePlanCharge__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new ZuoraQuoteRatePlanChargeTriggerHandler());
}