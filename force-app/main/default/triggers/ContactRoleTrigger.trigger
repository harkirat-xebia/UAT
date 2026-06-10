/**
 * Created by khaddouch on 14/06/2021.
 */

trigger ContactRoleTrigger on ER_Contact_Role__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new ContactRoleTriggerHandler());
}