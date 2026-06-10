/*
----------------------------------------------------------------------
-- - Name          : TaskTriggerHandler
-- - Author        : Noor
-- - Description   : TaskTriggerHandler for task
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  07/03/2023     Noor              1.0         Initial version.
---------------------------------------------------------------------------------------
 */

public with sharing class TaskTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('TaskTriggerHandler')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
    //NGO create Follow Up Task when task from Genesys is created in Salesforce manually
    APER42_TaskManagement.createFollowUpTaskManually((List<Task>) newItems);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //NGO closed Genesys Related Task when a completed task call is received in salesforce
    APER42_TaskManagement.closedGenesysRelatedTask((Map<Id, Task>) newItems, (Map<Id, Task>) oldItems);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //NGO When planned date is changed update Due Date and Reminder date
    APER42_TaskManagement.updateTaskDate((Map<Id, Task>) newItems, (Map<Id, Task>) oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //NGO create Follow Up Task when task from Genesys is created in Salesforce
    APER42_TaskManagement.createFollowUpTask((Map<Id, Task>) newItems, (Map<Id, Task>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    //NGO Prevent deletion of task related to Genesys
    if (UtilsBypass.canTrigger('preventTaskDeletion'))
      APER42_TaskManagement.preventTaskDeletion((List<Task>) oldItems.values());
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}