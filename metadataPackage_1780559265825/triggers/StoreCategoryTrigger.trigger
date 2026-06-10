/**
 * Created by khaddouch on 02/07/2021.
 */

trigger StoreCategoryTrigger on ER_StoreCategory__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new StoreCategoryTriggerHandler());
}