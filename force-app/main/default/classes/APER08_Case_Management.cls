/*
----------------------------------------------------------------------
-- - Name          : APER08_Case_Management
-- - Author        : OLA
-- - Description   : Case Management, This class is used to group all the functionnality linked to the object Case
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Nov-2018       OLA                 1.0         Initial version
--  Jan 2021       IMU                 1.1         #TICKET_NUMBER# closeAsSpam: This method is used to close cases detected as Spam
---------------------------------------------------------------------------------------
*/
public class APER08_Case_Management {
  public static void caseFreezeResetMilestone(List<Case> caseList) {
    for (Case c : caseList) {
      if (
        (c.Status == Constants.WAITING_FOR_SUPPORT || c.Status == Constants.WAITING_FOR_CUSTOMER) &&
        c.ER_Business_Unit__c == 'FI'
      ) {
        c.isStopped = false;
      } else if (
        (c.Status == 'New' || c.Status == 'In_Progress' || c.status == 'Escalated' || c.Status == 'Feedback Sent') &&
        c.ER_Business_Unit__c == 'FI'
      ) {
        c.isStopped = true;
      }
    }
  }

  public static void completeMilestone(Map<String, List<Id>> CaseMilestone, DateTime complDate) {
    List<Id> caseIds = new List<Id>();
    for (List<Id> ids : CaseMilestone.values()) {
      caseIds.addall(ids);
    }

    List<CaseMilestone> cmsToUpdate = [
      SELECT Id, completionDate
      FROM CaseMilestone cm
      WHERE caseId IN :caseIds AND cm.MilestoneType.Name IN :CaseMilestone.keyset() AND completionDate = NULL
    ];

    if (!cmsToUpdate.isEmpty()) {
      for (CaseMilestone cm : cmsToUpdate) {
        cm.completionDate = complDate;
      }

      update cmsToUpdate;
    }
  }

  /*
   *
   * OLA
   * Nov 2018
   * GetEmployeeCaseOptions: This method is used to get all the cases per Employee:
   *                         The purpose is to give the posibility to the User to link an activity to an existing Case
   *
   */

  public static List<SelectOption> GetEmployeeCaseOptions(String Employee) {
    System.debug('GetEmployeeCaseOptions Employee : ' + Employee);
    List<SelectOption> caseOptions = new List<SelectOption>();
    caseOptions.add(new SelectOption('', '--' + Label.LAB_SF_None + '--'));

    if (String.isNotBlank(Employee)) {
      List<Case> cases = GetEmployeeCases(Employee);
      System.debug('GetEmployeeCaseOptions cases : ' + cases);
      if (!cases.isEmpty()) {
        for (Case c : cases) {
          caseOptions.add(
            new SelectOption(c.Id + '', c.CaseNumber + (String.isBlank(c.ER_Reason__c) ? '' : ' - ' + c.ER_Reason__c))
          );
        }
      }
    }

    return caseOptions;
  }

  /*
   *
   * OLA
   * Nov 2018
   * GetEmployeeCases: This method is used to get all the cases per Employee:
   *                   The purpose is to give the posibility to the User to link an activity to an existing Case
   *
   */

  public static List<Case> GetEmployeeCases(String Employee) {
    System.debug('GetEmployeeCases Employee : ' + Employee);
    if (Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT') != null) {
      String RecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('ER_User_Case_RT')
        .getRecordTypeId();
      string query =
        'SELECT Id,CaseNumber,toLabel(ER_Reason__c) ' +
        ' FROM Case' +
        ' WHERE ER_Employee__c = \'' +
        Employee +
        '\'' +
        ' AND isclosed= false and recordtypeid = \'' +
        RecordtypeId +
        '\' order by CaseNumber desc';

      return (List<Case>) Database.query(query);
    }

    return new List<Case>();
  }

  /*
   *
   * OLA
   * Nov 2018
   * CreateCase : Quick case creation with case Reason and Case Detailed Reason
   *              Used to create case after an Asset Action: Block Card/Get Pin Reset
   *
   */

  public static Case CreateCase(String reason, String detailedReason, String assetID) {
    User runningUser = [SELECT Id, ER_Business_Unit__c FROM User WHERE Id = :UserInfo.getUserId()];

    Case newCase = new Case();
    newCase.AssetId = assetID;
    newCase.RecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('ER_User_Case_RT')
      .getRecordTypeId();
    newCase.ER_Reason__c = reason;
    newCase.ER_CaseReason2__c = detailedReason;
    newCase.ER_BUPicklist__c = runningUser.ER_Business_Unit__c;
    insert newCase;

    return newCase;
  }

  /*
   *
   * Nicolae Ciausu
   * Jan 2020
   * CreateIndividualCase : Quick case creation with case Reason and Case Detailed Reason
   *                        Used to create case after an Individual Email Update request
   *
   */

  public static Case CreateIndividualCase(String accId) {
    User runningUser = [SELECT Id, ER_Business_Unit__c FROM User WHERE Id = :UserInfo.getUserId()];

    Case newCase = new Case();
    newCase.RecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('ER_User_Case_RT')
      .getRecordTypeId();
    newCase.ER_Reason__c = Label.LAB_SF_Case_Reason_UpdateEmailAddress;
    newCase.ER_CaseReason2__c = Label.LAB_SF_Case_UpdateEmailAddress;
    newCase.Status = Label.LAB_SF_Case_inProgress;
    newCase.Origin = Label.LAB_SF_Case_Origin_Phone;
    newCase.Subject = Label.LAB_SF_Case_Subject_RemindModifyEmailAddress;
    newCase.ER_Individual__c = accId;
    newCase.ER_BUPicklist__c = runningUser.ER_Business_Unit__c;
    insert newCase;

    return newCase;
  }

  /*
   *
   * OLA
   * JUN 2019
   * manageCasesAssets: This method is used to Linked inserted cases to Asset, Indivudual, Employee and entitlment
   *
   *
   */
  public static void manageCasesAssets(List<Case> caseList) {
    Map<String, Asset> assetMap = new Map<String, Asset>();
    Map<id, Asset> assetidMap = new Map<id, Asset>();
    Set<String> assetNumberSet = new Set<String>();
    Set<id> assetidSet = new Set<id>();

    for (Case caseInst : caseList) {
      if (caseInst.ER_Card_Number__c != null) {
        assetNumberSet.add(String.valueOf(caseInst.ER_Card_Number__c));
      }
      if (caseInst.AssetId != null) {
        assetidSet.add(caseInst.AssetId);
      }
    }
    for (Asset asset : [
      SELECT Name, SerialNumber, ER_Employee__c, ER_Individual__c, Product2Id
      FROM Asset
      WHERE Name IN :assetNumberSet OR id IN :assetidSet
    ]) {
      if (assetMap.containsKey(asset.Name)) {
        assetMap.remove(asset.Name);
      } else
        assetMap.put(asset.Name, asset);
      assetIdMap.put(asset.Id, asset);
    }

    if (!assetMap.isEmpty()) {
      for (Case caseInst : caseList) {
        if (caseInst.ER_Card_Number__c != null && assetMap.containsKey(String.valueOf(caseInst.ER_Card_Number__c))) {
          caseInst.ER_Employee__c = assetMap.get(String.valueOf(caseInst.ER_Card_Number__c)).ER_Employee__c;
          caseInst.ER_Individual__c = assetMap.get(String.valueOf(caseInst.ER_Card_Number__c)).ER_Individual__c;
          caseInst.AssetId = assetMap.get(String.valueOf(caseInst.ER_Card_Number__c)).Id;
        }
        if (caseInst.AssetId != null) {
          caseInst.ER_Employee__c = assetIdMap.get(caseInst.AssetId).ER_Employee__c;
          caseInst.ER_Individual__c = assetIdMap.get(caseInst.AssetId).ER_Individual__c;
          caseInst.ProductId = assetIdMap.get(caseInst.AssetId).Product2Id;
        }
      }
    }
  }

  /**
   * @author ALK
   * @description Link automatically an entitlement to new created cases based on their BU
   * @date 23/03/2022
   * @param cases
   */
  public static void manageCasesEntitlment(List<Case> cases) {
    Entitlement defaultEntitlemnt;
    Map<String, List<Entitlement>> mapBUENtitlements = new Map<String, List<Entitlement>>();
    Id medalliaNPSRT = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_NPS_ALERT_CASE);

    for (Entitlement e : [
      SELECT Id, Name, StartDate, EndDate, AccountId, AssetId, ER_Business_Unit__c
      FROM Entitlement
      WHERE Status = :Constants.ACTIVE AND SlaProcessId != NULL
    ]) {
      if (!mapBUENtitlements.containsKey(e.ER_Business_Unit__c))
        mapBUENtitlements.put(e.ER_Business_Unit__c, new List<Entitlement>());
      mapBUENtitlements.get(e.ER_Business_Unit__c).add(e);

      if (String.isEmpty(e.ER_Business_Unit__c))
        defaultEntitlemnt = e;
    }

    for (Case c : cases) {
      if (mapBUENtitlements.containsKey(c.ER_BUPicklist__c)) {
        for (Entitlement e : mapBUENtitlements.get(c.ER_BUPicklist__c)) {
          if (
            c.RecordTypeId == medalliaNPSRT && e.Name.toUpperCase().contains(Constants.MEDALLIA_STRING) ||
            c.RecordTypeId != medalliaNPSRT && !e.Name.toUpperCase().contains(Constants.MEDALLIA_STRING)
          )
            c.EntitlementId = e.Id;
        }
      } else
        c.EntitlementId = defaultEntitlemnt?.Id;
    }
  }

  /*
   *
   * Ignacio Mula
   * JAN 2021
   * closeAsSpam: This method is used to close cases detected as Spam
   *
   *
   */
  @AuraEnabled
  public static Case closeAsSpam(Id caseId) {
    Case caseToClose = new Case(Id = caseId, Status = 'Spam');
    update caseToClose;
    return caseToClose;
  }

  /*
   *
   * Ignacio Mula
   * JAN 2021
   * getListViews: This method is used to retrieve the Case List views
   *
   *
   */
  @AuraEnabled
  public static List<ListView> getListViews() {
    List<ListView> listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'Case'];
    return listviews;
  }

  /*
   *
   * Daniel Sandu
   * SEP 2020
   * returnCasesWithOpenTasks: This method is used to return closing cases with active tasks
   *
   *
   */
  public static List<Case> returnCasesWithOpenTasks(Set<Id> caseIds) {
    Map<Id, List<Task>> tasksCaseIdMap = new Map<Id, List<Task>>();

    List<Case> casesOpenTasks = new List<Case>();
    List<Task> tasksList = [SELECT Id, Status, WhatId FROM Task WHERE WhatId IN :caseIds];

    //Loop to build Map Cases Ids to Tasks
    for (Task task : tasksList) {
      List<Task> allCaseTasks = new List<Task>();

      if (!tasksCaseIdMap.containsKey(task.WhatId)) {
        allCaseTasks.add(task);
        tasksCaseIdMap.put(task.WhatId, allCaseTasks);
      } else {
        allCaseTasks = tasksCaseIdMap.get(task.WhatId);
        allCaseTasks.add(task);
        tasksCaseIdMap.put(task.WhatId, allCaseTasks);
      }
    }

    if (!tasksCaseIdMap.isEmpty()) {
      for (Case c : [SELECT Id FROM Case WHERE Id IN :caseIds]) {
        for (Task task : tasksCaseIdMap.get(c.Id)) {
          if (task.Status == Label.LAB_SF_Task_StatusOpen) {
            casesOpenTasks.add(c);
            break;
          }
        }
      }
    }
    return casesOpenTasks;
  }

  /*
   *
   * GRE (Guillaume Revol)
   * FEB 2021
   * manageCasesWithOpenTasks(casesWithOpenTasks, Trigger.newMap): This method is used to add error message
   *
   *
   */
  public static void manageCasesWithOpenTasks(List<Case> casesOpenTasks, Map<Id, sObject> newCases) {
    for (Case c : casesOpenTasks) {
      Case actualCaseRecord = (Case) newCases.get(c.Id);
      System.debug('Actual Record ' + actualCaseRecord);
      actualCaseRecord.addError(Label.LAB_SF_Case_CaseCannotBeClosed);
    }
  }

  /*
   *
   * Vershley Joyejob
   * Mar 2021
   * deleteSpamCases: Delete cases marked as spam returned by batch BAER03
   *
   *
   */
  public static void deleteSpamCases(List<Case> aListSpamCasesList) {
    System.debug('Scope Delete Spam cases: ' + aListSpamCasesList);
    Database.delete(aListSpamCasesList, false);
    Database.emptyRecycleBin(aListSpamCasesList);
  }

  /*
   *
   * Vershley Joyejob
   * Mar 2021
   * updateBUEmailWebCases: Update BU on the cases from email-to-case and web-to-case
   *
   *
   */
  public static void updateBUEmailWebCases(List<Case> aCaseToProcess) {
    Set<Id> queueList = new Set<Id>();
    Set<Id> userList = new Set<Id>();
    Map<String, String> queueBUByIdMap = new Map<String, String>();
    Map<String, String> userBUByIdMap = new Map<String, String>();

    for (Case cs : aCaseToProcess) {
      if (String.valueOf(cs?.OwnerId?.getSobjectType()) == Constants.USER_OBJECT_TYPE)
        userList.add(cs.OwnerId);
      else if (String.valueOf(cs?.OwnerId?.getSobjectType()) == Constants.GROUP_OBJECT_TYPE)
        queueList.add(cs.OwnerId);
    }

    if (!queueList.isEmpty())
      queueBUByIdMap = getQueueDetails(queueList);
    if (!userList.isEmpty())
      userBUByIdMap = getUserDetails(userList);

    for (Case cs : aCaseToProcess) {
      try {
        if (String.valueOf(cs.OwnerId.getSobjectType()) == Constants.GROUP_OBJECT_TYPE) {
          String bu = queueBUByIdMap.get(cs.OwnerId);
          cs.ER_BUPicklist__c = (bu != null ? bu : cs.ER_BUPicklist__c);
        } else {
          cs.ER_BUPicklist__c = (String.isBlank(cs.ER_BUPicklist__c)
            ? userBUByIdMap.get(cs.OwnerId)
            : cs.ER_BUPicklist__c);
        }
      } catch (Exception e) {
        System.debug('Owner not set');
      }
    }
  }

  private static Map<String, String> getQueueDetails(Set<Id> aQueueList) {
    Map<String, String> queueBUByIdMap = new Map<String, String>();

    for (Group que : [SELECT Id, DeveloperName FROM Group WHERE Id IN :aQueueList]) {
      String businessUnitQueue = que.DeveloperName.substring(2, 4);
      if (Utils.getPicklistValues(Constants.CASE_OBJECT, Constants.BU_FIELD_NAME).containsKey(businessUnitQueue))
        queueBUByIdMap.put(que.Id, businessUnitQueue);
      else
        queueBUByIdMap.put(que.Id, null);
    }
    return queueBUByIdMap;
  }

  private static Map<String, String> getUserDetails(Set<Id> aUserList) {
    Map<String, String> userBUByIdMap = new Map<String, String>();

    for (User us : [SELECT Id, ER_Business_Unit__c FROM User WHERE Id IN :aUserList]) {
      userBUByIdMap.put(us.Id, us.ER_Business_Unit__c);
    }
    return userBUByIdMap;
  }

  /*
   *
   * Guillaume Revol
   * Mar 2021
   * populateMaventaClientFields: prepopulate fields on the cases associated with the ERFI Maventa client Queue
   *
   *
   */
  public static void populateMaventaClientFields(List<Case> aCaseToProcess) {
    for (Case cs : aCaseToProcess) {
      try {
        cs.ER_Reason__c = 'ER_Invoicing';
        cs.ER_CaseReason2__c = 'Incorrect data on invoice';
      } catch (Exception e) {
        System.debug('Owner not set');
      }
    }
  }

  public static void populateSubjectRTUser(List<Case> aCaseToProcess) {
    String reason = '';
    String detailedReason = '';
    Set<Id> assetIds = new Set<Id>();
    Map<Id, String> assetNameMap = new Map<Id, String>();

    for (Case cas : aCaseToProcess) {
      assetIds.add(cas.AssetId);
    }
    for (Asset ass : [SELECT Id, Name FROM Asset WHERE Id IN :assetIds]) {
      assetNameMap.put(ass.Id, ass.Name);
    }

    for (Case cs : aCaseToProcess) {
      try {
        if (cs.ER_Reason__c.contains('ER_')) {
          reason = cs.ER_Reason__c.removeStart('ER_');
        } else {
          reason = cs.ER_Reason__c;
        }
        if (cs.ER_CaseReason2__c.contains('ER_')) {
          detailedReason = cs.ER_CaseReason2__c.removeStart('ER_');
        } else {
          detailedReason = cs.ER_CaseReason2__c;
        }
        system.debug('Asset Name : ' + assetNameMap.get(cs.AssetId));
        cs.Subject = assetNameMap.get(cs.AssetId) + '/' + reason + '/' + detailedReason;
      } catch (Exception e) {
        System.debug('Subject not set');
      }
    }
  }

  public static void populateSubjectRTNotUser(List<Case> aCaseToProcess) {
    String reason = '';
    String detailedReason = '';
    for (Case cs : aCaseToProcess) {
      try {
        cs.Subject = cs.ER_Reason__c + '-' + cs.ER_CaseReason2__c;
      } catch (Exception e) {
        System.debug('Subject not set');
      }
    }
  }

  /*
   *
   * VJO
   * MAY 2021
   * processCaseMiletstone: Process case records after update
   *
   */
  public static void processCaseAfterUpdate(List<Case> aCaseToProcessList, Map<Id, SObject> oldItems) {
    DateTime completionDate = System.now();
    Map<String, List<String>> CaseMilestone = new Map<String, List<String>>();
    List<String> casesStandard;
    List<String> cases2Level;
    List<Case> reopenedCases = new List<Case>();
    for (Case c : aCaseToProcessList) {
      Case oldcase = (Case) oldItems.get(c.ID);

      if (c.Status != oldcase.Status) {
        casesStandard = new List<String>();
        cases2Level = new List<String>();

        if ((Test.isRunningTest() || (c.SlaStartDate <= completionDate)) && (c.SlaExitDate == null)) {
          if (c.isClosed || c.Status == Label.LAB_SF_Case_feedbackSent) {
            if (CaseMilestone.get('Support 2nd Level') != null) {
              cases2Level = CaseMilestone.get('Support 2nd Level');
            }
            cases2Level.add(c.id);
            CaseMilestone.put('Support 2nd Level', cases2Level);
          }
          if (c.isClosed || c.Status == Label.LAB_SF_Case_resolved) {
            if (CaseMilestone.get('Resolution Time') != null) {
              casesStandard = CaseMilestone.get('Resolution Time');
            }
            casesStandard.add(c.id);
            CaseMilestone.put('Resolution Time', casesStandard);
          }
        }
      }
    }

    if (!CaseMilestone.isEmpty()) {
      completeMilestone(CaseMilestone, completionDate);
    }
    if (!reopenedCases.isEmpty()) {
      update reopenedCases;
    }
  }

  /*
   *
   * VJO
   * MAY 2021
   * processCaseMiletstone: Process case records before insert
   *
   */
  public static void processCaseBeforeInsert(List<Case> aCaseToProcessList) {
    List<Case> casesAssets = new List<Case>();
    List<Case> caseToProcessList = new List<Case>();
    List<Case> caseMaventaClientToProcessList = new List<Case>();
    List<Case> caseRTToProcessList = new List<Case>();
    List<Case> caseDetailedReasonToProcessList = new List<Case>();

    System.debug('###:TRER04_CaseBeforeInsert before insert Start');

    // PBI-10276
    /*Group MaventaClientQueue = [
      SELECT Id
      FROM Group
      WHERE Type = :Label.LAB_SF_Group_Type_Queue AND Name = :Label.LAB_SF_Queue_Name_FI_Maventa_Client
      LIMIT 1
    ];
*/
    for (Case cs : aCaseToProcessList) {
      system.debug('@@@ Case Origin ' + cs.Origin + ' Owner ' + cs.OwnerId);
      // Check that the case is a user case and that the origin is "Web"
      if (
        (cs.Origin == Label.LABS_SF_Case_Origin_Web || cs.AssetId != null) &&
        cs.RecordTypeId ==
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId()
      )
        casesAssets.add(cs);

      if (cs.Origin == Label.LABS_SF_Case_Origin_Web || cs.Origin == Label.LABS_SF_Case_Origin_Email)
        caseToProcessList.add(cs);

      //if (cs.OwnerId == MaventaClientQueue.Id)
      //  caseMaventaClientToProcessList.add(cs);

      if (
        cs.Subject == null &&
        cs.ER_Reason__c != null &&
        cs.RecordTypeId ==
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId()
      )
        caseRTToProcessList.add(cs);

      if (
        cs.Subject == null &&
        cs.ER_Reason__c != null &&
        cs.ER_CaseReason2__c != null &&
        cs.RecordTypeId !=
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId()
      )
        caseDetailedReasonToProcessList.add(cs);
    }

    if (!casesAssets.isEmpty())
      manageCasesAssets(casesAssets);

    if (!aCaseToProcessList.isEmpty())
      manageCasesEntitlment(aCaseToProcessList);

    if (!caseToProcessList.isEmpty())
      updateBUEmailWebCases(caseToProcessList);

    if (!caseRTToProcessList.isEmpty())
      populateSubjectRTUser(caseRTToProcessList);

    if (!caseDetailedReasonToProcessList.isEmpty())
      populateSubjectRTNotUser(caseDetailedReasonToProcessList);

    if (!aCaseToProcessList.isEmpty())
      caseFreezeResetMilestone(aCaseToProcessList);
  }

  /**
   * @author IML
   * @date JUN 2021
   * @description processCaseAfterInsert: Process case records after insert
   * @param aCaseToProcessList
   * @param oldItems
   */
  public static void processCaseAfterInsert(List<Case> aCaseToProcessList, Map<Id, SObject> oldItems) {
    Set<Id> insertedCasesIds = new Set<Id>();
    for (Case c : aCaseToProcessList) {
      if (c.EntitlementId == null)
        insertedCasesIds.add(c.Id);
    }
    List<Case> aCaseToUpdateList = new List<Case>(
      [SELECT Id, ER_BUPicklist__c, EntitlementId, RecordTypeId FROM Case WHERE Id IN :insertedCasesIds]
    );
    manageCasesEntitlment(aCaseToUpdateList);
    update (aCaseToUpdateList);
  }

  /**
   *
   * @author VJO
   * @date MAY 2021
   * @description  processCaseMiletstone: Process case records after update
   * @param newItems
   * @param oldItems
   * @param aCaseToProcessList
   */
  public static void processCaseBeforeUpdate(
    List<Case> aCaseToProcessList,
    Map<Id, SObject> newItems,
    Map<Id, SObject> oldItems
  ) {
    List<Case> casesAssets = new List<Case>();
    Set<Id> caseIds = new Set<Id>();
    List<Case> caseToProcessList = new List<Case>();
    //List<Case> caseMaventaClientToProcessList = new List<Case>();
    List<Case> caseRTToProcessList = new List<Case>();
    List<Case> caseDetailedReasonToProcessList = new List<Case>();

    System.debug('###:TRER04_CaseBeforeUpdate before update Start');
    // PBI-10276
    //Group MaventaClientQueue = [SELECT Id FROM Group WHERE Type = :Label.LAB_SF_Group_Type_Queue AND Name = :Label.LAB_SF_Queue_Name_FI_Maventa_Client];

    for (Case cs : aCaseToProcessList) {
      Case oldcase = (Case) oldItems.get(cs.Id);
      if (cs.ER_Business_Unit__c != oldcase.ER_Business_Unit__c && String.isNotBlank(cs.ER_Business_Unit__c))
        cs.ER_BUPicklist__c = cs.ER_Business_Unit__c;

      if (cs.AssetId != oldcase.AssetId)
        casesAssets.add(cs);

      // Daniel Sandu code
      //Es-Saadiya LAKOUISMI : PBI-10634 : Case Management - SFR-806  - Case with open task - closing issue. Add a filter on BU : ES
      if (
        cs.ER_Business_Unit__c == 'ES' &&
        cs.Status != oldcase.Status &&
        (cs.Status == Label.LAB_SF_Case_resolved ||
        cs.Status == Label.LAB_SF_Case_Closed ||
        cs.Status == Label.LAB_SF_Case_Cancelled)
      )
        caseIds.add(cs.Id);

      if (cs.Origin == Label.LABS_SF_Case_Origin_Web || cs.Origin == Label.LABS_SF_Case_Origin_Email)
        caseToProcessList.add(cs);

      //if (cs.OwnerId == MaventaClientQueue.Id && cs.OwnerId != oldcase.OwnerId) caseMaventaClientToProcessList.add(cs);

      if (
        cs.Subject == null &&
        cs.ER_Reason__c != null &&
        cs.RecordTypeId ==
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId()
      )
        caseRTToProcessList.add(cs);

      if (
        cs.Subject == null &&
        cs.ER_Reason__c != null &&
        cs.ER_CaseReason2__c != null &&
        cs.RecordTypeId !=
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId()
      )
        caseDetailedReasonToProcessList.add(cs);
    }

    System.debug('###:TRER04_CaseBeforeUpdate before update Start');

    if (!casesAssets.isEmpty())
      manageCasesAssets(casesAssets);

    //Daniel Sandu code
    if (!caseIds.isEmpty()) {
      System.debug('###:TRER04_CaseBeforeUpdate caseIds ' + caseIds);
      List<Case> casesWithOpenTasks = returnCasesWithOpenTasks(caseIds);

      if (!casesWithOpenTasks.isEmpty())
        manageCasesWithOpenTasks(casesWithOpenTasks, newItems);
    }

    // IMT Added a call to manageCaseEntitlement so it would update Entitlement Name on the record
    if (!aCaseToProcessList.isEmpty())
      manageCasesEntitlment(aCaseToProcessList);

    if (!caseToProcessList.isEmpty())
      updateBUEmailWebCases(caseToProcessList);

    //if(!caseMaventaClientToProcessList.isEmpty()) populateMaventaClientFields(caseMaventaClientToProcessList);

    if (!caseRTToProcessList.isEmpty())
      populateSubjectRTUser(caseRTToProcessList);

    if (!caseDetailedReasonToProcessList.isEmpty())
      populateSubjectRTNotUser(caseDetailedReasonToProcessList);

    if (!aCaseToProcessList.isEmpty())
      caseFreezeResetMilestone(aCaseToProcessList);
  }

  /**
   * @author Noor
   * @date 21/01/2022
   * @description Check and update case as SPAM
   *
   * @param newItems new cases created
   *
   */
  public static void updateCaseAsSpam(List<Case> newItems) {
    for (Case cs : newItems) {
      if (cs.ER_BUPicklist__c == Constants.ES && isSpamES(cs)) {
        cs.Status = Constants.CASE_STATUS_SPAM;
        //cs.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERES_SPAM);
      } else if (cs.ER_BUPicklist__c == Constants.FI && isSpamFI(cs)) {
        cs.Status = Constants.CASE_STATUS_SPAM;
      } else if (cs.ER_BUPicklist__c == Constants.GR && isSpamGR(cs)) {
        cs.Status = Constants.CASE_STATUS_SPAM;
        //cs.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERGR_UNMANAGEABLE_CASE);
      }
    }
  }

  /**
   * @author Noor
   * @date 21/01/2022
   * @description Check is case is SPAM
   *
   * @param cs case
   *
   * @return check if case is SPAM
   */
  private static Boolean isSpamGR(Case cs) {
    List<String> spamSubjects = Utils.getGlobalSettingsValueFromKey('CASE_GR_SUBJECT_SPAM')?.split(Constants.SEMICOLON);
    List<String> spamEmails = Utils.getGlobalSettingsValueFromKey('CASE_GR_EMAIL_SPAM')?.split(Constants.SEMICOLON);
    List<String> senderSubjectKeyPairs = Utils.getGlobalSettingsValueFromKey('CASE_GR_SPECIFIC_EMAIL_SUBJECT_SPAM')
      ?.split(Constants.SEMICOLON);

    return (checkIfContains(cs.SuppliedEmail, spamEmails) ||
    checkIfContains(cs.Subject, spamSubjects) ||
    isSpecificSubjectFromSender(cs, senderSubjectKeyPairs));
  }

  /**
   * @author Noor
   * @date 21/01/2022
   * @description Check sender and subject match on case
   *
   * @param c case
   * @param senderSubjectKeyPairs
   *
   * @return
   */
  public static Boolean isSpecificSubjectFromSender(Case c, List<String> senderSubjectKeyPairs) {
    for (String keyPair : senderSubjectKeyPairs) {
      if (keyPair.contains(Constants.COLON + Constants.COLON)) {
        List<String> senderSubjectKeyPair = keyPair.split(Constants.COLON + Constants.COLON);
        if (senderSubjectKeyPair[0] == c.SuppliedEmail && senderSubjectKeyPair[1] == c.Subject)
          return true;
      }
    }
    return false;
  }

  /**
   * @author Noor
   * @date 21/01/2022
   * @description Check is case is SPAM
   *
   * @param cs case
   *
   * @return check if case is SPAM
   */
  private static Boolean isSpamES(Case cs) {
    List<String> spamSubjects = Utils.getGlobalSettingsValueFromKey('CASE_ES_SUBJECT_SPAM')?.split(Constants.SEMICOLON);
    //TODO custom metadata need to be merged as soon as the limitation on getting text area > 255 is solved
    //https://ideas.salesforce.com/s/idea/a0B8W00000GdakyUAB/custom-metadatas-getinstance-doesnt-retrieve-complete-long-text-area-fields
    spamSubjects.addAll(Utils.getGlobalSettingsValueFromKey('CASE_ES_SUBJECT_SPAM_2')?.split(Constants.SEMICOLON));

    List<String> spamEmails = Utils.getGlobalSettingsValueFromKey('CASE_ES_EMAIL_SPAM')?.split(Constants.SEMICOLON);

    return (checkIfContains(cs.ContactEmail, spamEmails) || checkIfContains(cs.Subject, spamSubjects)) &&
      cs.Status.equals('New') &&
      cs.Priority.equals('Medium') &&
      cs.Origin.equals('Email');
  }

  /**
   * @author Noor
   * @date 13/10/2022
   * @description Check is case is SPAM for FI
   *
   * @param cs case
   *
   * @return check if case is SPAM
   */
  private static Boolean isSpamFI(Case cs) {
    Pattern supplierPattern = Pattern.compile('.*\\d+.*');
    Map<Id, Group> queueMap = Utils.getQueueMap();

    Boolean isSupplierSpam = false;

    if (String.isNotBlank(cs.SuppliedName)) {
      Matcher supplierSpamMatcher = supplierPattern.matcher(cs.SuppliedName);
      isSupplierSpam = supplierSpamMatcher.matches();
    }

    return (cs.Origin.equals(Constants.CASE_ORIGIN_WEB) && cs.Description == 'Muchas gracias' ||
      isSupplierSpam ||
      cs.SuppliedCompany == 'google') ||
      (cs.Origin.equals(Constants.CASE_ORIGIN_EMAIL) &&
      cs.Subject == 'DHL shipment sender - delicard.fi' &&
      queueMap.containsKey(cs.OwnerId) &&
      queueMap.get(cs.OwnerId).DeveloperName == 'ERFI_Delicard');
  }

  private static Boolean checkIfContains(String subject, List<String> values) {
    for (String spamValue : values)
      if (String.isNotBlank(subject) && subject.containsIgnoreCase(spamValue))
        return true;
    return false;
  }

  /**
   * @author Daniel Sandu
   * @date Jan 2022
   * @description createMedalliaCases: This method is used to handle Medallia cases from Alert Management
   * @param feedbacksMeddaliaIds
   */
  /*public static void createMedalliaCases(List<Id> feedbacksMeddaliaIds) {
    String casePriority;
    String caseDetailedReason;
    List<Case> casesToInsert = new List<Case>();
    String medalliaAlertRT = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_NPS_ALERT_CASE);
    Map<String, String> mapEntitlementsBUId = new Map<String, String>();

    for (Entitlement ent : [SELECT Id, ER_Business_Unit__c, Name FROM Entitlement WHERE Name LIKE '%Medallia%']) {
      mapEntitlementsBUId.put(ent.ER_Business_Unit__c, ent.Id);
    }

    for (medallia_xm__Medallia_Feedback__c feedbackMedallia : [
      SELECT
        Id,
        medallia_xm__Invitation__c,
        medallia_xm__Invitation__r.medallia_xm__Medallia_Service__c,
        medallia_xm__Account_Id__c,
        medallia_xm__Contact_Id__c,
        medallia_xm__Alert_Type__c,
        medallia_xm__Original_case_Number__c,
        medallia_xm__Invitation__r.medallia_xm__Account__r.ER_Business_Unit__c,
        medallia_xm__Invitation__r.medallia_xm__Medallia_Internal_Id__c,
        medallia_xm__Original_case_Number__r.RecordType.DeveloperName,
        medallia_xm__Contact_Id__r.ER_med_pr_customer_type__c,
        ER_Individual_Id__c
      FROM medallia_xm__Medallia_Feedback__c
      WHERE Id IN :feedbacksMeddaliaIds
    ]) {
      String feedbackBU = feedbackMedallia.medallia_xm__Invitation__r.medallia_xm__Account__r.ER_Business_Unit__c;

      //Fill in the values for Case Detailed Reason and Priority based on alert type
      if (feedbackMedallia.medallia_xm__Alert_Type__c.contains(Label.LABS_SF_AlertType_UnresolvedProblem)) {
        caseDetailedReason = Label.LABS_SF_AlertType_UnresolvedProblem;
        casePriority = Label.LABS_SF_Priority_High;
      } else if (feedbackMedallia.medallia_xm__Alert_Type__c.contains(Label.LABS_SF_AlertType_ExtremeDetractor)) {
        caseDetailedReason = Label.LABS_SF_AlertType_ExtremeDetractor;
        casePriority = Label.LABS_SF_Priority_Medium;
      } else if (feedbackMedallia.medallia_xm__Alert_Type__c.contains(Label.LABS_SF_AlertType_MildDetractor)) {
        caseDetailedReason = Label.LABS_SF_AlertType_MildDetractor;
        casePriority = Label.LABS_SF_Priority_Low;
      }

      //Add cases to the list of cases to be inserted
      //take into consideration the type of case
      // If Pulse Relationship => check Customer Type value from the Contact
      // If Customer Care => Check Case Record Type
      if (
        feedbackMedallia.medallia_xm__Invitation__r.medallia_xm__Medallia_Service__c ==
        Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_PULSE_SURVEY)
      ) {
        Case c = createMedalliaPulseRelathionshipCase(
          medalliaAlertRT,
          caseDetailedReason,
          casePriority,
          feedbackBU,
          feedbackMedallia.medallia_xm__Account_Id__c,
          feedbackMedallia.medallia_xm__Contact_Id__c,
          mapEntitlementsBUId.get(feedbackBU),
          feedbackMedallia.Id,
          feedbackMedallia.medallia_xm__Invitation__r.medallia_xm__Medallia_Internal_Id__c
        );
        casesToInsert.add(c);
      } else if (
        feedbackMedallia.medallia_xm__Invitation__r.medallia_xm__Medallia_Service__c ==
        Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_CASE_CLOSED_SURVEY)
      ) {
        Case c = createMedalliaCustomerCareCase(
          medalliaAlertRT,
          caseDetailedReason,
          casePriority,
          feedbackBU,
          feedbackMedallia.medallia_xm__Account_Id__c,
          feedbackMedallia.medallia_xm__Contact_Id__c,
          mapEntitlementsBUId.get(feedbackBU),
          feedbackMedallia.Id,
          feedbackMedallia.medallia_xm__Invitation__r.medallia_xm__Medallia_Internal_Id__c
        );
        casesToInsert.add(c);
      }
    }
    
    if (!casesToInsert.isEmpty())
      insert casesToInsert;
  }*/

  /**
   * @author Daniel Sandu
   * @param recordTypeMedallia
   * @param detailedReason
   * @param priority
   * @param BU
   * @param accountId
   * @param contactId
   * @param entitlement
   * @param feedbackId
   * @param mInternalID
   *
   * @return
   */
  /*public static Case createMedalliaPulseRelathionshipCase(
    String recordTypeMedallia,
    String detailedReason,
    String priority,
    String BU,
    String accountId,
    String contactId,
    String entitlement,
    String feedbackId,
    String mInternalID
  ) {
    Case c = new Case();
    c.RecordTypeId = recordTypeMedallia;
    c.Origin = Label.LABS_SF_Case_Origin_NPS_Alert;
    c.ER_Reason__c = Label.LAB_SF_Case_Reason_Pulse_Alert;
    c.ER_CaseReason2__c = detailedReason;
    c.Priority = priority;
    c.Status = 'New';
    c.ER_BUPicklist__c = BU;
    c.Subject = Label.LAB_SF_Case_Subject_PulseRelationship + ' ' + mInternalID;
    c.AccountId = accountId;
    c.ContactId = contactId;
    c.EntitlementId = entitlement;
    c.medallia_xm__Medallia_Feedback_id__c = feedbackId;
    c.medallia_xm__Medallia_internal_id__c = mInternalID;

    return c;
  }
*/
  /**
   * @author Daniel Sandu
   * @param recordTypeMedallia
   * @param detailedReason
   * @param priority
   * @param BU
   * @param accountId
   * @param contactId
   * @param entitlement
   * @param feedbackId
   * @param mInternalID
   *
   * @return
   */
  /*public static Case createMedalliaCustomerCareCase(
    String recordTypeMedallia,
    String detailedReason,
    String priority,
    String BU,
    String accountId,
    String contactId,
    String entitlement,
    String feedbackId,
    String mInternalID
  ) {
    Case c = new Case();
    c.RecordTypeId = recordTypeMedallia;
    c.Origin = Label.LABS_SF_Case_Origin_NPS_Alert;
    c.ER_Reason__c = Label.LAB_SF_Case_Reason_Customer_Care_Alert;
    c.ER_CaseReason2__c = detailedReason;
    c.Priority = priority;
    c.Status = 'New';
    c.ER_BUPicklist__c = BU;
    c.Subject = Label.LAB_SF_Case_Subject_CustomerCare + ' ' + mInternalID;
    c.AccountId = accountId;
    c.ContactId = contactId;
    c.EntitlementId = entitlement;
    c.medallia_xm__Medallia_Feedback_id__c = feedbackId;
    c.medallia_xm__Medallia_internal_id__c = mInternalID;

    return c;
  }
  */
  /**
   * @author snica
   * @date 21/03/2022
   * @param newItems
   */
  public static void populateIndividualFieldBasedOnRT(List<Case> newItems) {
    Id caseUserRT = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_USER_RT);
    String individualRT = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_INDVIDUAL_RT);
    Map<Id, List<Case>> mapAccountCases = new Map<Id, List<Case>>();
    Map<Id, List<Case>> mapContactCase = new Map<Id, List<Case>>();

    for (Case c : newItems) {
      if (c.RecordTypeId == caseUserRT) {
        if (c.AccountId != null) {
          if (!mapAccountCases.containsKey(c.AccountId))
            mapAccountCases.put(c.AccountId, new List<Case>());
          mapAccountCases.get(c.AccountId).add(c);
        }

        if (c.ContactId != null) {
          if (!mapContactCase.containsKey(c.ContactId))
            mapContactCase.put(c.ContactId, new List<Case>());
          mapContactCase.get(c.ContactId).add(c);
        }
      }
    }

    for (Contact c : [
      SELECT Id, AccountId
      FROM Contact
      WHERE
        IsPersonAccount = TRUE
        AND Account.RecordTypeId = :individualRT
        AND (Id IN :mapContactCase.keySet()
        OR AccountId IN :mapAccountCases.keySet())
    ]) {
      if (mapAccountCases.containsKey(c.AccountId)) {
        for (Case item : mapAccountCases.get(c.AccountId))
          item.ER_Individual__c = c.AccountId;
      }
      if (mapContactCase.containsKey(c.Id)) {
        for (Case item : mapContactCase.get(c.Id))
          item.ER_Individual__c = c.AccountId;
      }
    }
  }

  /**
   * @author snica
   * @date 16/05/2022
   * @param newItems
   * @param oldItems
   * @description - Method that updates Contact Id if Contact Name is blank and Individual is filled.
   * @description - Ticket #15861
   */
  public static void populateContactId(List<Case> newItems) {
    Map<Id, List<Case>> mapIndividualCases = new Map<Id, List<Case>>();
    Id caseUserRTId = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_USER_RT);

    for (Case c : newItems) {
      if (c.RecordTypeId == caseUserRTId && c.IsClosed == false) {
        if (!mapIndividualCases.containsKey(c.ER_Individual__c))
          mapIndividualCases.put(c.ER_Individual__c, new List<Case>());
        mapIndividualCases.get(c.ER_Individual__c).add(c);
      }
    }

    if (!mapIndividualCases.isEmpty()) {
      for (Account pa : [SELECT Id, PersonContactId FROM Account WHERE Id IN :mapIndividualCases.keySet()]) {
        for (Case c : mapIndividualCases.get(pa.Id))
          c.ER_Individual__r = pa;
      }

      for (Case c : newItems) {
        if (c.ContactId == null && c.ER_Individual__c != null) {
          c.ContactId = c.ER_Individual__r.PersonContactId;
          c.AccountId = c.ER_Individual__c;
        }
      }
    }
  }

  /**
   * @author CWA
   * @date 21/04/2022
   * @description Update merged case owner to queue
   */
  public static void UpdateMergedOwner(List<Case> newCases, Map<Id, Case> oldItems) {
    system.debug('APER08_CASE_UPDATE_OWNER BEGIN');

    //Get all merged case queues
    List<Group> queues = [
      SELECT Id, DeveloperName, Name
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName LIKE '%Merged%'
    ];
    System.debug('CWAGetQueues : ' + queues);
    // Associate Queue ID to name
    Map<String, String> Q1 = new Map<String, String>();
    for (Group theGroup : queues) {
      Q1.put(theGroup.DeveloperName, theGroup.ID);
    }
    System.debug('CWAMap : ' + Q1);

    // Queues Assignment

    for (Case cs : newCases) {
      System.debug('CWACase bu : ' + cs.ER_BUPicklist__c);
      System.debug('CWACase cs.Status : ' + cs.Status);
      System.debug('CWACase oldItems.get(cs.Id)?.Status : ' + oldItems.get(cs.Id)?.Status);
      System.debug('CWACase cond1 : ' + (cs.Status == 'Merged' && cs.Status != oldItems.get(cs.Id)?.Status));
      System.debug('CWACase cond2 : ' + (cs.ER_BUPicklist__c == 'ES'));
      System.debug('CWACase conget mapd2 : ' + Q1.get('ERES_Merged_Cases'));
      //Case oldcase = (Case)oldItems.get(cs.Id);
      if (cs.Status == Constants.MERGED && cs.Status != oldItems.get(cs.Id)?.Status) {
        string queueName = 'ER' + cs.ER_BUPicklist__c.left(2) + '_Merged_Cases';
        System.debug('CWACase queueName : ' + queueName);
        if (Q1.get(queueName) != null)
          cs.OwnerId = Q1.get(queueName);
      }
    }
    system.debug('APER08_CASE_UPDATE_OWNER END');
  }

  /**
   * @author CWA
   * @date 17/08/2022
   * @description Update the Time Opened field according to the user's time zone
   */

  public static void updateTimeOpenedField(List<Case> newCases, Map<Id, Case> oldItems) {
    List<Case> Cases = new List<Case>();

    //Get the time zone of the BU

    Map<String, Global_Settings__mdt> globalSettingsMap = Utils.getGlobalSettings();
    String PREFIX = 'TIMEZONE_ER';

    // Update ER_time_Opened field with local time zone

    for (Case c : newCases) {
      String formattedFilterKey = PREFIX + c.ER_BUPicklist__c;

      if (globalSettingsMap.containsKey(formattedFilterKey) && c.Status != Constants.SPAM) {
        if (Trigger.isAfter && Trigger.isInsert) {
          Case cs = new Case(Id = c.Id);
          String strConvertedDate = c.CreatedDate.format(
            'yyyy-MM-dd HH:mm:ss',
            globalSettingsMap.get(formattedFilterKey).Value__c
          );
          Datetime myDate = Datetime.valueOfGMT(strConvertedDate); // server format make the string date a datetime again in GMT
          cs.ER_Time_Opened__c = myDate.timeGmt();
          Cases.add(cs);

          if (!Cases.isEmpty())
            update Cases;
        }

        if (Trigger.isBefore && Trigger.isUpdate) {
          if (c.ER_BUPicklist__c != oldItems.get(c.Id)?.ER_BUPicklist__c) {
            String strConvertedDate = c.CreatedDate.format(
              'yyyy-MM-dd HH:mm:ss',
              globalSettingsMap.get(formattedFilterKey).Value__c
            );
            Datetime myDate = Datetime.valueOfGMT(strConvertedDate);
            c.ER_Time_Opened__c = myDate.timeGmt();
          }
        }
      }
    }
  }

  /**
   * @author snica
   * @date 19/09/2022
   * @description Migrate the remaining Case WF
   * @param newItems
   */
  public static void updateCaseSubject(List<Case> newItems) {
    Set<Id> assetIdsSet = new Set<Id>();
    Map<Id, String> assetNameMap = new Map<Id, String>();

    for (Case cs : newItems) {
      assetIdsSet.add(cs.AssetId);
    }

    for (Asset asst : [SELECT Name, Id FROM Asset WHERE Id IN :assetIdsSet]) {
      assetNameMap.put(asst.Id, asst.Name);
    }

    for (Case cs : newItems) {
      //WFER01_Case_RT_User
      if (
        cs.Subject == null &&
        cs.ER_Reason__c != null &&
        cs.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_USER_RT)
      ) {
        String reason = cs.ER_Reason__c.Contains('ER_') ? cs.ER_Reason__c.replace('ER_', '') : cs.ER_Reason__c;
        if (cs.ER_CaseReason2__c != null) {
          String reason2 = cs.ER_CaseReason2__c.Contains('ER_')
            ? cs.ER_CaseReason2__c.replace('ER_', '')
            : cs.ER_CaseReason2__c;
          cs.Subject = (cs.AssetId != null ? assetNameMap.get(cs.AssetId) : '') + '/' + reason + '/' + reason2;
        } else {
          cs.Subject = (cs.AssetId != null ? assetNameMap.get(cs.AssetId) : '') + '/' + reason + '/' + '';
        }
      }

      //WFER02_Case_RT_ClientMerchant
      if (
        cs.Subject == null &&
        cs.ER_Reason__c != null &&
        cs.RecordTypeId != Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_USER_RT) &&
        cs.ER_CaseReason2__c != null
      ) {
        cs.Subject = cs.ER_Reason__c + '-' + cs.ER_CaseReason2__c;
      }
    }
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description closeRelatedCase and update Case Reason, Case detailed reason with value from parent
   *               for matching recordTypes
   * @param newMap updated case
   * @param oldMap old value map
   */
  public static void closeRelatedCase(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
    Set<Case> caseToClose = new Set<Case>();

    for (Case c : newMap.values()) {
      if (c.IsClosed && !oldMap.get(c.Id).IsClosed)
        caseToClose.add(c);
    }

    if (!caseToClose.isEmpty()) {
      List<Case> caseToUpdate = new List<Case>();

      for (Case c : [
        SELECT Id, ParentId, Parent.ER_Reason__c, Parent.ER_CaseReason2__c, Parent.Status, RecordTypeId
        FROM Case
        WHERE ParentId IN :caseToClose AND IsClosed = FALSE
      ]) {
        if (c.RecordTypeId == newMap.get(c.ParentId).RecordTypeId)
          caseToUpdate.add(
            new Case(
              Id = c.Id,
              ER_Reason__c = c.Parent.ER_Reason__c,
              ER_CaseReason2__c = c.Parent.ER_CaseReason2__c,
              Status = c.Parent.Status
            )
          );
      }
      if (!caseToUpdate.isEmpty())
        update caseToUpdate;
    }
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description update customer segment and reason and priority
   * @param newMap updated case
   */
  public static void updateCaseField(List<Case> newItems) {
    Id clientRT = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_CLIENT_RT);
    Id merchantRT = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_MERCHANT_RT);
    Id userCaseRT = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_USER_RT);

    List<String> caseOriginEmailWeb = new List<String>{ Constants.CASE_ORIGIN_EMAIL, Constants.CASE_ORIGIN_WEB };

    Map<Id, Group> queueMap = Utils.getQueueMap();

    for (Case c : newItems) {
      if (
        (queueMap.containsKey(c.OwnerId) &&
        queueMap.get(c.OwnerId).DeveloperName == Constants.CASE_QUEUE_ERFI_CLIENT &&
        caseOriginEmailWeb.contains(c.Origin)) ||
        (c.Origin == Constants.CASE_ORIGIN_PHONE &&
        c.RecordTypeId == clientRT)
      )
        c.ER_Customer_Segment__c = Constants.CASE_CUSTOMER_SEGMENT_CLIENT;
      else if (
        (queueMap.containsKey(c.OwnerId) &&
        queueMap.get(c.OwnerId).DeveloperName == Constants.CASE_QUEUE_ERFI_MERCHANT &&
        caseOriginEmailWeb.contains(c.Origin)) ||
        (c.Origin == Constants.CASE_ORIGIN_PHONE &&
        c.RecordTypeId == merchantRT)
      )
        c.ER_Customer_Segment__c = Constants.CASE_CUSTOMER_SEGMENT_MERCHANT;
      else if (
        (queueMap.containsKey(c.OwnerId) &&
        queueMap.get(c.OwnerId).DeveloperName == Constants.CASE_QUEUE_ERFI_BENEFICIARY &&
        caseOriginEmailWeb.contains(c.Origin)) ||
        (c.Origin == Constants.CASE_ORIGIN_PHONE &&
        c.RecordTypeId == userCaseRT)
      )
        c.ER_Customer_Segment__c = Constants.CASE_CUSTOMER_SEGMENT_BENEFICIARY;
      else if (
        queueMap.containsKey(c.OwnerId) &&
        queueMap.get(c.OwnerId).DeveloperName == Constants.CASE_QUEUE_ERFI_DELICARD &&
        caseOriginEmailWeb.contains(c.Origin)
      )
        c.ER_Customer_Segment__c = Constants.CASE_CUSTOMER_SEGMENT_DELICARD;
      else if (
        queueMap.containsKey(c.OwnerId) &&
        queueMap.get(c.OwnerId).DeveloperName == Constants.CASE_QUEUE_ERSK_ROBOT_FAILED
      ) {
        c.ER_CaseReason2__c = Constants.CASE_DETAILED_REASON_CARD_LOAD;
        c.ER_Reason__c = Constants.CASE_REASON_ORDER_DELIVERY;
      }
      if (
        (c.ER_BUPicklist__c == Constants.FI ||
        queueMap.containsKey(c.OwnerId) && queueMap.get(c.OwnerId).DeveloperName.contains('ERFI')) &&
        c.Origin == Constants.CASE_ORIGIN_WEB
      )
        c.Priority = Constants.CASE_PRIORITY_LOW;
    }
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description update escalation field for BU CZ and FI
   * @param newMap updated case
   * @param oldMap old values map
   */
  public static void updateEscalationField(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
    List<Case> casesCZ = new List<Case>();
    List<Case> caseFI = new List<Case>();

    Map<Id, User> ownerRoles = Utils.getUserMap();
    Map<Id, Group> queueIdMapName = Utils.getQueueMap();

    for (Case c : newMap.values()) {
      if (c.ER_BUPicklist__c == Constants.CZ && c.Status == Constants.CASE_STATUS_ESCALATED && !c.hasBeenEscalated__c)
        casesCZ.add(c);

      if (
        c.ER_BUPicklist__c == Constants.FI &&
        c.OwnerId != oldMap.get(c.Id).OwnerId &&
        (c.Status == Constants.CASE_STATUS_ESCALATED ||
        c.Status == Constants.CASE_STATUS_NEW)
      )
        caseFI.add(c);
    }

    if (!casesCZ.isEmpty())
      updateEscalationCZ(casesCZ, ownerRoles);
    if (!caseFI.isEmpty())
      updateEscalationFI(caseFI, ownerRoles, queueIdMapName);
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description update escalation field for BU CZ
   * @param cases updated case
   * @param ownerRoles user map roles
   */
  private static void updateEscalationCZ(List<Case> cases, Map<Id, User> ownerRoles) {
    List<String> roles = Utils.getGlobalSettingsValueFromKey('CASE_CZ_ESCALATION_ROLES')?.split(Constants.SEMICOLON);

    for (Case c : cases) {
      if (ownerRoles.containsKey(c.OwnerId) && roles.contains(ownerRoles.get(c.OwnerId).UserRole.DeveloperName))
        c.hasBeenEscalated__c = true;
    }
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description update escalation field for BU FI
   * @param cases updated case
   * @param ownerRoles user map roles
   * @param queueNameMap
   */
  private static void updateEscalationFI(List<Case> cases, Map<Id, User> ownerRoles, Map<Id, Group> queueNameMap) {
    List<String> escalationRolesTier1Queue = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER1_QUEUE')
      ?.split(Constants.SEMICOLON);
    List<String> escalationRolesTier2 = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER2_ROLES')
      ?.split(Constants.SEMICOLON);

    List<String> escalationTier2Queue = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER2_QUEUE')
      ?.split(Constants.SEMICOLON);

    for (Case c : cases) {
      if (
        String.isNotBlank(c.ERFI_Escalation_level__c) &&
        c.ERFI_Escalation_level__c != Constants.CASE_ESCALATION_LEVEL_TECHNICAL &&
        c.Status == Constants.CASE_STATUS_ESCALATED &&
        c.OwnerId.getSobjectType() == Group.SObjectType &&
        escalationRolesTier1Queue.contains(queueNameMap.get(c.OwnerId).DeveloperName)
      )
        c.ERFI_Escalation_level__c = Constants.CASE_ESCALATION_LEVEL_TECHNICAL;

      if (
        String.isBlank(c.ERFI_Escalation_level__c) &&
        ((c.OwnerId.getSobjectType() == User.SObjectType &&
        escalationRolesTier2.contains(ownerRoles.get(c.OwnerId).UserRole.DeveloperName)) ||
        (c.OwnerId.getSobjectType() == Group.SObjectType &&
        escalationTier2Queue.contains(queueNameMap.get(c.OwnerId).DeveloperName)))
      )
        c.ERFI_Escalation_level__c = Constants.CASE_ESCALATION_LEVEL_TIER2;
    }
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description update escalation field for BU CZ
   * @param newMap updated case
   * @param oldMap old values map
   */
  /*
  public static void caseAutoAssignment(List<Case> newItems) {
    String balanceAdjustmentQueueId = Utils.getQueueIdByName('ERFI_Balance_adjustments_client');
    List<String> suppliedNameFI = Utils.getGlobalSettingsValueFromKey('CASE_FI_AUTO_ASSIGNMENT_SUPPLIED_NAME')
      ?.split(Constants.SEMICOLON);

    for (Case c : newItems) {
      if (c.ER_BUPicklist__c == Constants.FI && suppliedNameFI.contains(c.SuppliedEmail))
        c.OwnerId = balanceAdjustmentQueueId;
    }
  }
  */

  /**
   * @author Noor
   * @date 10/10/2022
   * @description update Account On Case when contact is changed
   * @param newMap updated case
   * @param oldMap old values map
   */
  public static void updateAccountOnCase(Map<Id, Case> newItems, Map<Id, Case> oldMap) {
    Set<Id> contactIds = new Set<Id>();
    List<Case> casesToUpdate = new List<Case>();

    Id clientRT = Utils.getRecordTypeIdByDeveloperName(Case.SObjectType, Constants.CASE_CLIENT_RT);

    for (Case c : newItems.values()) {
      if (
        c.RecordTypeId == clientRT &&
        String.isBlank(c.AccountId) &&
        String.isNotBlank(c.ContactId) &&
        c.ContactId != oldMap.get(c.Id).ContactId
      ) {
        casesToUpdate.add(c);
        contactIds.add(c.ContactId);
      }
    }

    if (!contactIds.isEmpty()) {
      Map<Id, Contact> contactsMap = new Map<Id, Contact>(
        [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds AND AccountId != '']
      );
      for (Case c : casesToUpdate) {
        if (contactsMap.containsKey(c.ContactId)) {
          c.AccountId = contactsMap.get(c.ContactId).AccountId;
        }
      }
    }
  }

  /**
   * @author ALK
   * @date 09/03/2023
   * @description Trigger Auto response for cases created via REST API (Smarter Context)
   * @param cases
   */
  public static void triggerAutoResponse(List<Case> cases) {
    List<Case> casesToBeAutoResponded = new List<Case>();
    List<String> deployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
      ?.split(Constants.SEMICOLON);
    Map<Id, User> integrationUsers = new Map<Id, User>(
      [SELECT Id FROM User WHERE Profile.Name = :Constants.PROFILE_ER_INTEGRATION]
    );

    for (Case c : [SELECT Id, CreatedById, ER_BUPicklist__c FROM Case WHERE Id IN :cases]) {
      if (
        deployedBUs != null &&
        deployedBUs.contains(c.ER_BUPicklist__c) &&
        integrationUsers != null &&
        integrationUsers.containsKey(c.CreatedById)
      ) {
        casesToBeAutoResponded.add(c);
      }
    }

    if (!casesToBeAutoResponded.isEmpty()) {
      Database.DMLOptions autoResponseOptions = new Database.DMLOptions();
      autoResponseOptions.emailHeader.triggerAutoResponseEmail = true;

      for (Case c : casesToBeAutoResponded)
        Database.update(c, autoResponseOptions);
    }
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description route Case To Genesys

   * @param newItems
   * @param oldItems
   */
  public static void routeCaseToGenesys(Map<Id, Case> newItems, Map<Id, Case> oldItems) {
    List<GenesysRoutingRequest> genesysRoutingRequests = new List<GenesysRoutingRequest>();
    List<Case> casesFR = new List<Case>();
    List<Case> casesGR = new List<Case>();

    Map<Id, Group> queueMap = Utils.getQueueMap();
    for (Case c : newItems.values()) {
      if (c.ER_BUPicklist__c == Constants.FR)
        casesFR.add(c);
      if (c.ER_BUPicklist__c == Constants.GR)
        casesGR.add(c);
    }

    if (!casesFR.isEmpty())
      genesysRoutingRequests = routeCaseToGenesysFR(casesFR, oldItems, queueMap);
    if (!casesGR.isEmpty())
      genesysRoutingRequests = routeCaseToGenesysGR(casesGR, oldItems, queueMap);

    if (!genesysRoutingRequests.isEmpty())
      GenesysCloud_API.createConversation(JSON.serializePretty(genesysRoutingRequests));
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description route Case To Genesys FR
   * @param newItems
   * @param oldItems
   * @param queueMap
   */
  public static List<GenesysRoutingRequest> routeCaseToGenesysFR(
    List<Case> cases,
    Map<Id, Case> oldItems,
    Map<Id, Group> queueMap
  ) {
    List<GenesysRoutingRequest> genesysRoutingRequests = new List<GenesysRoutingRequest>();

    Map<String, String> mapIdRecordType = Utils.getRecordTypeMapIdByDeveloperName(Case.SObjectType);

    for (Case c : cases) {
      String keyFlow =
        Constants.GENESYS_CASE_FLOW_ID_CONFIG +
        c.ER_BUPicklist__c +
        Constants.UNDERSCORE +
        Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId);
      String keyQueue =
        Constants.GENESYS_CASE_QUEUE_ID_CONFIG +
        c.ER_BUPicklist__c +
        Constants.UNDERSCORE +
        Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId) +
        +Constants.UNDERSCORE +
        c.ER_Reason__c;

      String flowName = Utils.getGlobalSettingsValueFromKey(keyFlow.toUpperCase());
      String queueId = Utils.getGlobalSettingsValueFromKey(
        keyQueue.toUpperCase().replaceAll(' ', Constants.UNDERSCORE)
      );

      if (isCaseValidForGenesysFR(c, oldItems.get(c.Id), flowName, queueId, queueMap))
        genesysRoutingRequests.add(createGenesysRoutingRequestFR(flowName, queueId, c));
    }

    return genesysRoutingRequests;
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description route Case To Genesys GR
   * @param newItems
   * @param oldItems
   * @param queueMap
   */
  public static List<GenesysRoutingRequest> routeCaseToGenesysGR(
    List<Case> cases,
    Map<Id, Case> oldItems,
    Map<Id, Group> queueMap
  ) {
    List<GenesysRoutingRequest> genesysRoutingRequests = new List<GenesysRoutingRequest>();
    Map<String, String> mapIdRecordType = Utils.getRecordTypeMapIdByDeveloperName(Case.SObjectType);
    List<Case> validCases = new List<Case>();
    Set<Id> accountIds = new Set<Id>();
    for (Case c : cases) {
      String flowName = Utils.getGlobalSettingsValueFromKey(
        (Constants.GENESYS_CASE_FLOW_ID_CONFIG +
          c.ER_BUPicklist__c +
          Constants.UNDERSCORE +
          Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
          .toUpperCase()
      );
      String queueId = Utils.getGlobalSettingsValueFromKey(
        (Constants.GENESYS_CASE_QUEUE_ID_CONFIG +
          c.ER_BUPicklist__c +
          Constants.UNDERSCORE +
          Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
          .toUpperCase()
      );
      if (isCaseValidForGenesysGR(c, oldItems.get(c.Id), flowName, queueId, queueMap)) {
        validCases.add(c);
        accountIds.add(c.AccountId);
      }
    }
    if (!validCases.isEmpty())
      genesysRoutingRequests = getGenesysInfoGR(validCases, accountIds);

    return genesysRoutingRequests;
  }

  public static List<GenesysRoutingRequest> getGenesysInfoGR(List<Case> cases, Set<Id> accountIds) {
    List<GenesysRoutingRequest> genesysRoutingRequests = new List<GenesysRoutingRequest>();
    Map<String, String> mapIdRecordType = Utils.getRecordTypeMapIdByDeveloperName(Case.SObjectType);
    Map<Id, ER_Preferred_Agent__c> preferredAgent1Map = new Map<Id, ER_Preferred_Agent__c>();
    Map<Id, ER_Preferred_Agent__c> preferredAgent2Map = new Map<Id, ER_Preferred_Agent__c>();
    Map<Id, String> accountPriorityMap = new Map<Id, String>();

    for (Account a : [
      SELECT
        Id,
        ER_Client_Priority__c,
        (
          SELECT Id, ER_Priority__c, ER_Account__c, ER_User__r.Email
          FROM Preferred_Agents__r
          WHERE ER_Status__c = 'Active'
        )
      FROM Account
      WHERE Id IN :accountIds
    ]) {
      for (ER_Preferred_Agent__c pA : a.Preferred_Agents__r) {
        if (pA.ER_Priority__c == 1)
          preferredAgent1Map.put(a.Id, pA);
        if (pA.ER_Priority__c == 2)
          preferredAgent2Map.put(a.Id, pA);
      }
      accountPriorityMap.put(a.Id, a.ER_Client_Priority__c);
    }
    for (Case c : cases) {
      String flowName = Utils.getGlobalSettingsValueFromKey(
        (Constants.GENESYS_CASE_FLOW_ID_CONFIG +
          c.ER_BUPicklist__c +
          Constants.UNDERSCORE +
          Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
          .toUpperCase()
      );
      String queueId = Utils.getGlobalSettingsValueFromKey(
        (Constants.GENESYS_CASE_QUEUE_ID_CONFIG +
          c.ER_BUPicklist__c +
          Constants.UNDERSCORE +
          Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
          .toUpperCase()
      );

      genesysRoutingRequests.add(
        createGenesysRoutingRequestGR(
          flowName,
          queueId,
          c,
          preferredAgent1Map.get(c.AccountId),
          preferredAgent2Map.get(c.AccountId),
          accountPriorityMap.get(c.AccountId)
        )
      );
    }

    return genesysRoutingRequests;
  }

  private static Boolean isCaseValidForGenesysFR(
    Case c,
    Case oldCase,
    String flowName,
    String queueId,
    Map<Id, Group> queueMap
  ) {
    return c.Origin == 'Web' &&
      flowName != null &&
      queueId != null &&
      Utils.isChangeOwnerFromUserToQueue(c.OwnerId, oldCase.OwnerId) &&
      isDistributionQueue(queueMap.get(c.OwnerId)) &&
      !c.IsClosed;
  }

  private static Boolean isCaseValidForGenesysGR(
    Case c,
    Case oldCase,
    String flowName,
    String queueId,
    Map<Id, Group> queueMap
  ) {
    //TODO check Origin value for Chatbot
    return c.Origin == 'Chat' &&
      flowName != null &&
      queueId != null &&
      Utils.isChangeOwnerFromUserToQueue(c.OwnerId, oldCase.OwnerId) &&
      queueMap.get(c.OwnerId).DeveloperName == Constants.GENESYS_GR_CHATBOT_QUEUE &&
      !c.IsClosed;
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description create Genesys Routing Request

   * @param flowName
   * @param queueId
   * @param c case
   * @return GenesysRoutingRequest
   */
  private static GenesysRoutingRequest createGenesysRoutingRequestFR(String flowName, String queueId, Case c) {
    GenesysRoutingRequest req = new GenesysRoutingRequest();
    req.flowId = flowName;
    req.fromName = c.CaseNumber;
    req.attributes.fa_sf = queueId;
    req.attributes.sf_urlpop = c.Id;
    req.attributes.type_activite = 'Case';
    req.attributes.owner_id = c.OwnerId;
    return req;
  }

  /**
     * @author Noor
     * @date 02/06/2023
     * @description create Genesys Routing Request

     * @param flowName
     * @param queueId
     * @param c case
     * @return GenesysRoutingRequest
     */
  private static GenesysRoutingRequest createGenesysRoutingRequestGR(
    String flowName,
    String queueId,
    Case c,
    ER_Preferred_Agent__c agent1,
    ER_Preferred_Agent__c agent2,
    String priority
  ) {
    GenesysRoutingRequest req = new GenesysRoutingRequest();
    req.flowId = flowName;
    req.fromName = c.CaseNumber;
    req.attributes.fa_sf = queueId;
    req.attributes.sf_urlpop = c.Id;
    req.attributes.type_activite = 'Case';
    req.attributes.owner_id = c.OwnerId;
    req.attributes.pref_Agent = agent1?.ER_User__r.Email;
    req.attributes.agent_Backup = agent2?.ER_User__r.Email;
    req.attributes.client_Priority = priority;
    return req;
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description get the list of Queue that is distributed for Genesys

   * @param caseGroup
   * @return true if the queue need to be distributed
   */
  public static boolean isDistributionQueue(Group caseGroup) {
    return caseGroup != null && Constants.CASE_LIST_DISTRIBUTION_QUEUE.contains(caseGroup.DeveloperName);
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description disconnect Related Task On Closed Case
   * @param newItems
   * @param oldItems
   */
  public static void disconnectRelatedTaskOnClosedCase(Map<Id, Case> newItems, Map<Id, Case> oldItems) {
    Set<Id> caseClosed = new Set<Id>();
    Map<String, String> conversationIds = new Map<String, String>();
    for (Case c : newItems.values())
      if (c.IsClosed && !oldItems.get(c.Id).IsClosed)
        caseClosed.add(c.Id);

    if (!caseClosed.isEmpty()) {
      for (Task t : [
        SELECT Id, Gsys_Call_ConversationId__c
        FROM Task
        WHERE WhatId IN :caseClosed AND Gsys_Call_ConversationId__c != ''
      ])
        conversationIds.put(t.Gsys_Call_ConversationId__c, t.Id);

      if (!conversationIds.isEmpty())
        GenesysCloud_API.disconnectConversation(conversationIds);
    }
  }
}