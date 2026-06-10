/**
 * -----------------------------------------------------
 * @author : AAZ
 * @date : 24/06/2021
 * @desc : Product2Trigger
 * @see Product2Trigger
 * -----------------------------------------------------
 */

trigger Product2Trigger on Product2(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new Product2TriggerHandler());
}