/*
----------------------------------------------------------------------
-- - Name          : APER35_EmailMessage_Management
-- - Author        : Noor
-- - Description   : Class for all EmailMessage object logic
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 12/10/2021   Noor                1.0         Trigger Handler Rework.
---------------------------------------------------------------------------------------
*/
public with sharing class APER35_EmailMessage_Management {
  /**
   * @author Noor
   * @description When PDF is sent to Contact, change quote status to Presented
   * @param newEmailMessageMap newly created email message
   */
  public static void changeQuoteStatusToPresented(Map<Id, EmailMessage> newEmailMessageMap) {
    Set<Id> emailMessageQuoteIds = new Set<Id>();
    Set<Id> emailMessageCaseIds = new Set<Id>();
    //PBI-11332
    Map<Id, String> relatedCaseMap = new Map<Id, String>();
    Map<String, Id> queueMap = new Map<String, Id>();

    //PBI-10647
    List<String> careRoles = new List<String>{
      Label.LABS_SF_Role_ERCZ_Customer_Care_Manager,
      Label.LABS_SF_Role_ERCZ_Customer_Care_Operator,
      Label.LABS_SF_Role_ERCZ_External_Customer_Care
    };
    List<String> salesRoles = new List<String>{
      Label.LABS_SF_Role_ERCZ_Merchant_Sales_Manager,
      Label.LABS_SF_Role_ERCZ_Customer_Care_Operator,
      Label.LABS_SF_Role_ERCZ_Merchant_Telesales
    };
    String roleName = '';

    System.debug('###:TRER06_EmailMessageAfterInsert after insert Start');
    List<UserRole> usrRole = [SELECT Name, DeveloperName FROM UserRole WHERE Id = :UserInfo.getUserRoleId()];
    if (!usrRole.isEmpty())
      roleName = usrRole[0].Name;

    for (EmailMessage EMinst : newEmailMessageMap.values()) {
      //10 JULY Check if From Name starts with user BU or equals user Name.
      if (
        !EMinst.Incoming &&
        String.isNotBlank(EMinst.FromName) &&
        EMinst.FromName != UserInfo.getName() &&
        (APER10_User_Management.userBU != null && !EMinst.FromName.startsWith(APER10_User_Management.userBU.substring(0, 2)) ||
        (roleName != '' &&
        !careRoles.contains(roleName) &&
        (EMinst.FromAddress == Label.LABS_SF_Care_Mailing_List ||
        EMinst.FromAddress == Label.LABS_SF_uzivatel_Mailing_List)) ||
        (roleName != '' &&
        !salesRoles.contains(roleName) &&
        EMinst.FromAddress == Label.LABS_SF_Sales_Mailing_List))
      ) {
        //EMinst.addError(Label.LABS_SF_EmailMessage_FromAdressForbidden);
      }
      if (String.isNotBlank(EMinst.RelatedToId) && String.valueOf(EMinst.RelatedToId).startsWith('0Q0')) {
        emailMessageQuoteIds.add(EMinst.RelatedToId);
      }
      if (
        String.isNotBlank(EMinst.RelatedToId) &&
        String.valueOf(EMinst.RelatedToId).startsWith('500') &&
        EMinst.Incoming
      ) {
        emailMessageCaseIds.add(EMinst.RelatedToId);
        relatedCaseMap.put(EMinst.RelatedToId, EMinst.ToAddress);
      }
    }
    if (!emailMessageQuoteIds.isEmpty()) {
      List<Quote> quoteList = [
        SELECT Id, Status, Opportunity.StageName, OpportunityId
        FROM Quote
        WHERE Id IN :emailMessageQuoteIds AND Status = :Label.LABS_SF_Quote_Status_Draft
      ];

      if (!quoteList.isEmpty())
        APER11_Quote_Management.updateQuoteStatus(quoteList);
    }

    /*
     for (QueueSobject queueItem : [
      SELECT Id, Queue.DeveloperName
      FROM QueueSobject
      WHERE
        SobjectType = 'Case'
        AND Queue.DeveloperName IN ('ERFI_Beneficiary', 'ERFI_Client', 'ERFI_Delicard', 'ERFI_Merchant_1st_line','Default_Case_Assignment_Queue')
    ]) {
      queueMap.put(queueItem.Queue.DeveloperName, queueItem.Queue.Id);
    }
   */

    if (!emailMessageCaseIds.isEmpty()) {
      List<Case> caseList = [
        SELECT Id, Status, ER_EmailReceivedWhileClosed__c, OwnerId
        FROM Case
        WHERE
          Id IN :emailMessageCaseIds
          AND (Status = :Label.LAB_SF_Case_resolved
          OR Status = :Label.LAB_SF_Case_Closed
          OR Status = :Label.LAB_SF_Case_Cancelled)
      ];
     /* 
      List<Case> pendingCaseList = [
        SELECT Id, Status, OwnerId
        FROM Case
        WHERE Id IN :emailMessageCaseIds AND Status = :Label.LAB_SF_Case_Pending AND ER_BUPicklist__c = 'FI'
      ];

      if (!pendingCaseList.isEmpty()) {
        for (Case pendingCase : pendingCaseList) {
          switch on relatedCaseMap.get(pendingCase.Id) {
            when 'edunsaaja-fi@edenred.com' {
              pendingCase.OwnerId = queueMap.get('Default_Case_Assignment_Queue');
            }
            when 'yritys-fi@edenred.com' {
              pendingCase.OwnerId = queueMap.get('Default_Case_Assignment_Queue');
            }
            when 'kumppanit-fi@edenred.com' {
              pendingCase.OwnerId = queueMap.get('Default_Case_Assignment_Queue');
            }
            when 'delicard-fi@edenred.com', 'info@delicard.fi' {
              pendingCase.OwnerId = queueMap.get('Default_Case_Assignment_Queue');
            }
          }
          
        }
        update pendingCaseList;
      }*/
      if (!caseList.isEmpty()) {
        for (Case c : caseList) {
          c.ER_EmailReceivedWhileClosed__c = true;
          c.Status = Constants.IN_PROGRESS;
          C.ER_Case_Reopened__c = true;
        }
        update caseList;
      }
    }

    System.debug('###:TRER06_EmailMessageAfterInsert after insert End');
  }

  /**
   * @author AAZ
   * @date 05/11/2021
   * @description Block sending zuora error emails to Zuora doamin
   */
  public static void blockSendingZuoraErrorEmails(List<EmailMessage> messages) {
    for (EmailMessage em : messages) {
      if (String.isNotBlank(em.ToAddress) && em.ToAddress.contains('@zuora.com'))
        em.addError('Zuora emails not allowed');
    }
  }
  /**
   * @author CWA
   * @date 08/11/2022
   * @description Update Case Status upon outbound or inbound email
   */
  public static void UpdateCaseStatusInboundOutboundEmail(List<EmailMessage> messages) {
    Map<Id, Boolean> mapCaseEmailType = new Map<Id, Boolean>();
    List<Case> casesList = new List<Case>();

    for (EmailMessage em : messages) {
      System.debug('##CWAN em.ParentId : ' + em.ParentId);
      if (em.ParentId != null)
        mapCaseEmailType.put(em.ParentId, em.Incoming);
    }

    if (mapCaseEmailType.keySet() != null) {
      for (Case c : [SELECT Id, Status FROM Case WHERE Id IN :mapCaseEmailType.keySet()]) {
        Boolean isIncomingMail = mapCaseEmailType.get(c.Id);
        if (isIncomingMail && c.Status == Constants.WAITING_FOR_CUSTOMER)
          c.Status = Constants.IN_PROGRESS;
        else if (!isIncomingMail)
          c.Status = Constants.WAITING_FOR_CUSTOMER;
        casesList.add(c);
      }

      System.debug('##CWAN casesList : ' + casesList);
      if (!casesList.isEmpty())
        Database.update(casesList, false);
    }
  }
  /**
   * @author CWA
   * @date 17/11/2022
   * @description Reopen Case or New Case Creation depending on the date an email is received and send to Genesys
   */
  public static void caseReopenBehaviour(List<EmailMessage> messages) {
    List<Case> casesToBeCreated = new List<Case>();
    List<Case> casesToBeUpdated = new List<Case>();
    List<Case> openCasesFirstTime = new List<Case>();
    List<Case> openCasesSecondTime = new List<Case>();
    List<String> statusesToBeExcluded = new List<String>{ Constants.SPAM };
    Date todayDt = Date.today();
    Map<Id, EmailMessage> mapCaseEmails = new Map<Id, EmailMessage>();
    Map<Id, Case> mapGRGenesysCases = new Map<Id, Case>();

    for (EmailMessage em : messages) {
      if (em.ParentId != null && em.Incoming) {
        mapCaseEmails.put(em.ParentId, em);
      }
    }

    if (!mapCaseEmails.isEmpty()) {
      List<String> toEmails = Utils.getGlobalSettingsValueFromKey(Constants.GENESYS_GR_TO_EMAIL_ADD)
        ?.split(Constants.SEMICOLON);
      /*Id queueId = Utils.getQueueIdByName(
        Utils.getGlobalSettingsValueFromKey(Constants.GENESYS_GR_EMAIL_MESSAGE_QUEUE)
      );*/
      for (Case c : [
        SELECT
          Id,
          CaseNumber,
          Status,
          ClosedDate,
          OwnerId,
          Subject,
          Description,
          ContactPhone,
          Origin,
          Type,
          IsClosed,
          ER_BUPicklist__c,
          ER_Employee__c,
          ER_Individual__c,
          ContactId,
          ER_Reason__c,
          ER_CaseReason2__c,
          AccountId,
          SuppliedEmail,
          SuppliedCompany,
          SuppliedPhone,
          SuppliedName,
          ER_Customer_Segment__c,
          ER_Solution__c,
          ER_Sub_Product__c,
          RecordTypeId,
          (SELECT Id FROM EmailMessages WHERE Incoming = TRUE)
        FROM Case
        WHERE Id IN :mapCaseEmails.keySet() AND Status NOT IN :statusesToBeExcluded
      ]) {
        if (c.IsClosed) {
          if (todayDt > c.ClosedDate.addDays(7)) {
            Case newCase = c.clone();
            newCase.Status = Constants.CASE_STATUS_NEW;
            newCase.Subject = mapCaseEmails.get(c.Id).Subject;
            if ((mapCaseEmails.get(c.Id).TextBody).length() >= 32000) {
              newCase.Description = mapCaseEmails.get(c.Id).TextBody.substring(0, 32000);
            } else {
              newCase.Description = mapCaseEmails.get(c.Id).TextBody;
            }
            newCase.ParentId = c.Id;
            casesToBeCreated.add(newCase);
          } else {
            c.Status = Constants.IN_PROGRESS;
            c.ER_EmailReceivedWhileClosed__c = true;
            c.ER_Case_Reopened__c = true;
            casesToBeUpdated.add(c);
          }
        } else {
          if (c.EmailMessages.size() > 1)
            openCasesSecondTime.add(c);
          else
            openCasesFirstTime.add(c);
        }
        System.debug('//NGO caseReopenBehaviour c.ER_BUPicklist__c : ' + c.ER_BUPicklist__c);
        System.debug('//NGO caseReopenBehaviour mapCaseEmails.containsKey(c.Id) : ' + mapCaseEmails.containsKey(c.Id));
        System.debug(
          '//NGO caseReopenBehaviour mapCaseEmails.get(c.Id).ToAddress : ' + mapCaseEmails.get(c.Id).ToAddress
        );
        System.debug('//NGO caseReopenBehaviour c.OwnerId : ' + c.OwnerId);
        /*
        if (
          c.ER_BUPicklist__c == Constants.GR &&
          mapCaseEmails.containsKey(c.Id) &&
          toEmails.contains(mapCaseEmails.get(c.Id)?.ToAddress) &&
          c.OwnerId == queueId
        )
          mapGRGenesysCases.put(c.Id, c);
          */
      }
      System.debug('//NGO caseReopenBehaviour mapGRGenesysCases : ' + mapGRGenesysCases);
      if (!casesToBeCreated.isEmpty()) {
        Database.insert(casesToBeCreated, false);
        routeEmailMessageToGenesys(casesToBeCreated, true, false, mapGRGenesysCases);
      }
      if (!casesToBeUpdated.isEmpty()) {
        Database.update(casesToBeUpdated, false);
        routeEmailMessageToGenesys(casesToBeUpdated, false, false, mapGRGenesysCases);
      }
      if (!openCasesFirstTime.isEmpty()) {
        routeEmailMessageToGenesys(openCasesFirstTime, false, true, mapGRGenesysCases);
      }
      if (!openCasesSecondTime.isEmpty()) {
        routeEmailMessageToGenesys(openCasesSecondTime, false, false, mapGRGenesysCases);
      }
    }
  }

  public static void routeEmailMessageToGenesys(
    List<Case> cases,
    Boolean isNewCaseCreated,
    Boolean isFirstMail,
    Map<Id, Case> casesByIds
  ) {
    List<GenesysRoutingRequest> genesysRoutingRequests = new List<GenesysRoutingRequest>();
    List<Case> validCases = new List<Case>();
    Set<Id> accountIds = new Set<Id>();

    for (Case c : cases) {
      Id caseId = c.Id;
      if (isNewCaseCreated)
        caseId = c.ParentId;
      if (String.isNotBlank(c.Id) && casesByIds.containsKey(caseId)) {
        validCases.add(c);
        accountIds.add(c.AccountId);
      }
    }

    if (!validCases.isEmpty())
      genesysRoutingRequests = getGenesysInfoGR(validCases, accountIds, isFirstMail);

    if (!genesysRoutingRequests.isEmpty())
      GenesysCloud_API.createConversation(JSON.serializePretty(genesysRoutingRequests));
  }

  public static List<GenesysRoutingRequest> getGenesysInfoGR(
    List<Case> cases,
    Set<Id> accountIds,
    Boolean isFirstMail
  ) {
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
      String flowName;
      String queueId;
      String remoteName;
      if (isFirstMail) {
        flowName = Utils.getGlobalSettingsValueFromKey(
          (Constants.GENESYS_EMAIL_MESSAGE_FLOW_ID_CONFIG +
            c.ER_BUPicklist__c +
            Constants.UNDERSCORE +
            Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
            .toUpperCase()
        );
        queueId = Utils.getGlobalSettingsValueFromKey(
          (Constants.GENESYS_EMAIL_MESSAGE_QUEUE_ID_CONFIG +
            c.ER_BUPicklist__c +
            Constants.UNDERSCORE +
            Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
            .toUpperCase()
        );
        remoteName = 'GR_Business_Email';
      } else {
        flowName = Utils.getGlobalSettingsValueFromKey(
          (Constants.GENESYS_EMAIL_MESSAGE_FLOW_ID_CONFIG +
            '_2_' +
            c.ER_BUPicklist__c +
            Constants.UNDERSCORE +
            Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
            .toUpperCase()
        );
        queueId = Utils.getGlobalSettingsValueFromKey(
          (Constants.GENESYS_EMAIL_MESSAGE_QUEUE_ID_CONFIG +
            '_2_' +
            c.ER_BUPicklist__c +
            Constants.UNDERSCORE +
            Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
            .toUpperCase()
        );
        remoteName = 'GR_2ndEmail_Case';
      }
      System.debug(
        '//NGO getGenesysInfoGR  flowName : ' +
        (Constants.GENESYS_EMAIL_MESSAGE_FLOW_ID_CONFIG +
          c.ER_BUPicklist__c +
          Constants.UNDERSCORE +
          Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
          .toUpperCase()
      );
      System.debug(
        '//NGO getGenesysInfoGR  queueId : ' +
        (Constants.GENESYS_EMAIL_MESSAGE_QUEUE_ID_CONFIG +
          c.ER_BUPicklist__c +
          Constants.UNDERSCORE +
          Utils.mapRecordTypeCode(mapIdRecordType, c.RecordTypeId))
          .toUpperCase()
      );

      genesysRoutingRequests.add(
        createGenesysRoutingRequestGR(
          remoteName,
          flowName,
          queueId,
          c,
          preferredAgent1Map.get(c.AccountId),
          preferredAgent2Map.get(c.AccountId),
          accountPriorityMap.get(c.AccountId)
        )
      );
    }
    System.debug('//NGO getGenesysInfoGR  : ' + genesysRoutingRequests);
    return genesysRoutingRequests;
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
    String remoteName,
    String flowName,
    String queueId,
    Case c,
    ER_Preferred_Agent__c agent1,
    ER_Preferred_Agent__c agent2,
    String priority
  ) {
    GenesysRoutingRequest req = new GenesysRoutingRequest();
    req.flowId = flowName;
    req.fromName = remoteName;
    req.attributes.fa_sf = queueId;
    req.attributes.sf_urlpop = c.Id;
    req.attributes.type_activite = 'Case';
    req.attributes.owner_id = c.OwnerId;
    req.attributes.pref_Agent = agent1?.ER_User__r.Email;
    req.attributes.agent_Backup = agent2?.ER_User__r.Email;
    req.attributes.client_Priority = priority;
    req.attributes.email_Description = c.Description;
    req.attributes.email_Subject = c.Subject;
    return req;
  }
}