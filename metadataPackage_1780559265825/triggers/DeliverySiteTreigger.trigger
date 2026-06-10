/**
 * Created by davram on 3/18/2021.
 */

trigger DeliverySiteTreigger on ER_Delivery_Site__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new DeliverSiteTriggerHandler());
}