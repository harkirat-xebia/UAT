/**
 * @author : AAZ
 * @date : 31/05/2021
 * @desc : ZuoraQuoteTrigger
 * @see ZuoraQuoteTrigger
 */

trigger ZuoraQuoteTrigger on zqu__Quote__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ZuoraQuoteTriggerHandler());
}