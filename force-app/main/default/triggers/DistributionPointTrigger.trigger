/**
 * Created by davram on 3/22/2021.
 */

trigger DistributionPointTrigger on ER_Distribution_Point__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new DistributionPointTriggerHandler());
}