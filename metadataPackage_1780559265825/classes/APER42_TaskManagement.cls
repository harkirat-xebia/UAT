/*
----------------------------------------------------------------------
-- - Name          : APER42_TaskManagement
-- - Author        : Noor
-- - Description   : Class that contain all task management business logic
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  07/03/2023     Noor              1.0         Initial version.
---------------------------------------------------------------------------------------
 */
public with sharing class APER42_TaskManagement {
  /**
   * @author Noor
   * @date 26/05/2023
   * @description  Prevent deletion of task related to Genesys
   * @param tasks deleted task
   */
  public static void preventTaskDeletion(List<Task> tasks) {
    for (Task t : tasks)
      if (t.Subject == Constants.GENESYS_TASK_TYPE)
        t.addError(Label.LAB_SF_TASK_DELETION_ERROR);
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description create Follow Up Task when task from Genesys is created in Salesforce
   * @param newItems
   * @param oldItems
   */
  public static void createFollowUpTask(Map<Id, Task> newItems, Map<Id, Task> oldItems) {
    List<Task> taskToBeCreated = new List<Task>();
    Map<Id, User> userMap = Utils.getUserMap();
    Set<Id> whoIds = new Set<Id>();
    Map<Id, Task> existingTaskOnLeadMap = new Map<Id, Task>();
    for (Task t : newItems.values())
      if (t.WhoId != null && Utils.getSObjectType(t.WhoId) == Constants.LEAD && isFollowUpTask(t, oldItems))
        whoIds.add(t.WhoId);
    System.debug('//NGO createFollowUpTask whoIds : ' + whoIds);
    if (!whoIds.isEmpty()) {
      for (Task t : [
        SELECT Id, WhoId
        FROM Task
        WHERE WhoId IN :whoIds AND Gsys_Activity_Type__c = :Constants.GENESYS_TASK_FOLLOW_UP_TYPE
        ORDER BY CreatedDate DESC
      ])
        existingTaskOnLeadMap.put(t.WhoId, t);
    }

    for (Task t : newItems.values()) {
      String queueId = getQueue(userMap, t.OwnerId);
      String keyFlow = Constants.GENESYS_TASK_FLOW_ID_CONFIG + t.ER_Business_Unit__c;
      String flowName = Utils.getGlobalSettingsValueFromKey(keyFlow.toUpperCase());

      if (isFollowUpTask(t, oldItems) && flowName != null)
        taskToBeCreated.add(createTask(t, existingTaskOnLeadMap, queueId));
    }
    System.debug('//NGO createFollowUpTask taskToBeCreated : ' + taskToBeCreated);
    if (!taskToBeCreated.isEmpty())
      insert taskToBeCreated;
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description closed Genesys Related Task when a completed task call is received in salesforce
   * @param newItems
   * @param oldItems
   */
  public static void closedGenesysRelatedTask(Map<Id, Task> newItems, Map<Id, Task> oldItems) {
    List<Task> taskToBeClosed = new List<Task>();

    Set<String> genesysCall_Ids = new Set<String>();
    Set<String> bus = new Set<String>();

    for (Task t : newItems.values()) {
      System.debug('//NGO createFollowUpTask task : ' + t);
      if (t.Gsys_Call_ConversationId__c != null && t.IsClosed) {
        genesysCall_Ids.add(t.Gsys_Call_ConversationId__c);
        bus.add(t.ER_Business_Unit__c);
      }
    }

    if (!genesysCall_Ids.isEmpty()) {
      for (Task t : [
        SELECT Id
        FROM Task
        WHERE
          Gsys_Call_ConversationId__c IN :genesysCall_Ids
          AND Status = 'Open'
          AND ER_Business_Unit__c IN :bus
          AND CreatedDate = THIS_YEAR
        ORDER BY CreatedDate DESC
      ])
        taskToBeClosed.add(new Task(Id = t.Id, Status = Constants.GENESYS_TASK_STATUS_COMPLETED));
    }
    System.debug('//NGO createFollowUpTask taskToBeClosed : ' + taskToBeClosed);
    if (!taskToBeClosed.isEmpty())
      Database.update(taskToBeClosed);
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description create manual Follow Up Task based on the Reason for follow up is Chosen
   * @param newItems
   * @param oldItems
   */
  public static void createFollowUpTaskManually(List<Task> newItems) {
    Map<Id, User> userMap = Utils.getUserMap();
    Map<Id, Task> existingTaskOnLead = getExistingTaskOnLead(newItems);
    for (Task t : newItems) {
      String queueId = getQueue(userMap, t.OwnerId);
      if (isManualFollowUpTask(t)) {
        t.Gsys_Activity_Type__c = Constants.GENESYS_TASK_FOLLOW_UP_TYPE;
        t.Gsys_Call_QueueName__c = queueId;
        calculatePriorityForManualFollowUp(t, existingTaskOnLead);
        if (t.Gsys_Planned_Date__c != null && t.ActivityDate == null) {
          t.ActivityDate = t.Gsys_Planned_Date__c.date();
          t.ReminderDateTime = t.Gsys_Planned_Date__c;
          t.IsReminderSet = true;
        }
      }
    }
  }

  /**
   * @author Noor
   * @date 08/06/2023
   * @description check if the task created in Salesforce is a followup task
   * @param t
   * @param oldItems
   *
   * @return
   */
  public static Boolean isManualFollowUpTask(Task t) {
    return (Constants.GENESYS_TASK_FOLLOW_UP_REASON_CODE.contains(t.Gsys_Reason_For_Follow_up__c) &&
    t.Gsys_Activity_Type__c != Constants.GENESYS_TASK_FOLLOW_UP_TYPE);
  }

  public static Map<Id, Task> getExistingTaskOnLead(List<Task> tasks) {
    Set<Id> whoIds = new Set<Id>();
    Map<Id, Task> existingTaskOnLeadMap = new Map<Id, Task>();

    for (Task t : tasks)
      if (t.WhoId != null && Utils.getSObjectType(t.WhoId) == Constants.LEAD && isManualFollowUpTask(t))
        whoIds.add(t.WhoId);
    System.debug('//NGO createFollowUpTask whoIds : ' + whoIds);
    if (!whoIds.isEmpty()) {
      for (Task t : [
        SELECT Id, WhoId
        FROM Task
        WHERE WhoId IN :whoIds AND Gsys_Activity_Type__c = :Constants.GENESYS_TASK_FOLLOW_UP_TYPE
        ORDER BY CreatedDate DESC
      ])
        existingTaskOnLeadMap.put(t.WhoId, t);
    }

    return existingTaskOnLeadMap;
  }

  /**
   * @author Noor
   * @date 08/06/2023
   * @description check if the created task from Genesys need to have a followup task
   * @param t
   * @param oldItems
   *
   * @return
   */
  public static Boolean isFollowUpTask(Task t, Map<Id, Task> oldItems) {
    return (Constants.GENESYS_TASK_FOLLOW_UP_CODE.contains(t.CallDisposition) &&
    t.CallDisposition != oldItems?.get(t.Id).CallDisposition);
  }

  /**
   * @author Noor
   * @date 08/06/2023
   * @description create FollowUp Task
   *
   * @param parentTask
   * @param existingTaskOnRelatedRecordMap
   * @param queueId
   * @return Task
   */
  public static Task createTask(Task parentTask, Map<Id, Task> existingTaskOnRelatedRecordMap, String queueId) {
    Task t = new Task();
    t.Subject = Constants.GENESYS_TASK_FOLLOW_UP_SUBJECT;
    t.Status = Constants.GENESYS_TASK_STATUS_OPEN;
    t.OwnerId = parentTask.OwnerId;
    t.Gsys_Activity_Type__c = Constants.GENESYS_TASK_FOLLOW_UP_TYPE;
    t.Gsys_Call_QueueName__c = queueId;
    calculatePriorityAndSchedule(parentTask, t, existingTaskOnRelatedRecordMap);
    t.WhatId = parentTask.WhatId;
    t.WhoId = parentTask.WhoId;
    t.Gsys_Reason_For_Follow_up__c = mapWrapCodeWithFollowupReason(
      Constants.FR,
      parentTask.Gsys_Salesforce_WrapUpCode__c
    );

    return t;
  }

  /**
   * @author Noor
   * @date 08/06/2023
   * @description map the genesys wrapCode With the picklist followupReason code from custom metadata
   * @param BU
   * @param wrapupCode
   *
   * @return followupReason code
   */
  public static String mapWrapCodeWithFollowupReason(String BU, String wrapupCode) {
    String result = wrapupCode.toUpperCase().replaceAll(' ', Constants.UNDERSCORE).replaceAll('[ÉÈÊ]', 'E');
    return Utils.getGlobalSettingsValueFromKey(
      Constants.GENESYS_MAPPING_METADATA_PREFIX +
      BU +
      Constants.UNDERSCORE +
      result
    );
  }

  /**
   * @author Noor
   * @date 08/06/2023
   * @description calculate Planned Date and priority for automatic followUp
   * @param parentTask parent task from Genesys
   * @param t task
   * @param existingTaskOnRelatedRecordMap existing Task On task Related Record Map
   */
  public static void calculatePriorityAndSchedule(
    Task parentTask,
    Task t,
    Map<Id, Task> existingTaskOnRelatedRecordMap
  ) {
    if (parentTask.WhoId != null && Utils.getSObjectType(parentTask.WhoId) == Constants.LEAD) {
      System.debug(
        '//NGO routeRelaunchTaskToGenesys existingTaskOnLeadMap.get(t.WhoId) : ' +
        existingTaskOnRelatedRecordMap.get(parentTask.WhoId) +
        ' task id : ' +
        parentTask.Id
      );

      if (
        existingTaskOnRelatedRecordMap.containsKey(parentTask.WhoId) &&
        existingTaskOnRelatedRecordMap.get(parentTask.WhoId).Id != parentTask.Id
      ) {
        t.Gsys_Planned_Date__c = Datetime.now().addDays(1);
        t.Priority = Constants.NORMAL;
      } else {
        t.Gsys_Planned_Date__c = Datetime.now().addHours(2);
        t.Priority = Constants.CASE_PRIORITY_HIGH;
      }
    } else {
      t.Gsys_Planned_Date__c = Datetime.now().addDays(1);
      t.Priority = Constants.NORMAL;
    }
    t.ActivityDate = t.Gsys_Planned_Date__c.date();
    t.ReminderDateTime = t.Gsys_Planned_Date__c;
    t.IsReminderSet = true;
  }

  /**
   * @author Noor
   * @date 08/06/2023
   * @description calculate  priority for manual followUp
   * @param t task
   * @param existingTaskOnRelatedRecordMap existing Task On task Related Record Map
   */
  public static void calculatePriorityForManualFollowUp(Task t, Map<Id, Task> existingTaskOnRelatedRecordMap) {
    if (t.WhoId != null && Utils.getSObjectType(t.WhoId) == Constants.LEAD) {
      System.debug(
        '//NGO calculatePriorityForManualFollowUP existingTaskOnLeadMap.get(t.WhoId) : ' +
        existingTaskOnRelatedRecordMap.get(t.WhoId) +
        ' task id : ' +
        t.Id
      );
      if (existingTaskOnRelatedRecordMap.containsKey(t.WhoId) && existingTaskOnRelatedRecordMap.get(t.WhoId).Id != t.Id)
        t.Priority = Constants.NORMAL;
      else
        t.Priority = Constants.CASE_PRIORITY_HIGH;
    } else {
      t.Priority = Constants.NORMAL;
    }
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description get the queue configured on the Owner
   * @param userMap
   * @param ownerId
   *
   * @return Owner queue Id
   */
  public static String getQueue(Map<Id, User> userMap, Id ownerId) {
    if (userMap.containsKey(ownerId) && userMap.get(ownerId).ER_Queue_CTI__c != '')
      return userMap.get(ownerId).ER_Queue_CTI__c;
    return null;
  }

  /**
   * @author Noor
   * @date 19/06/2023
   * @description When planned date is changed update Due Date and Reminder date
   * @param newItems
   * @param oldItems
   */
  public static void updateTaskDate(Map<Id, Task> newItems, Map<Id, Task> oldItems) {
    for (Task t : newItems.values()) {
      if (t.Gsys_Planned_Date__c != oldItems.get(t.Id).Gsys_Planned_Date__c) {
        t.ActivityDate = t.Gsys_Planned_Date__c.date();
        t.ReminderDateTime = t.Gsys_Planned_Date__c;
        t.IsReminderSet = true;
      }
    }
  }
}