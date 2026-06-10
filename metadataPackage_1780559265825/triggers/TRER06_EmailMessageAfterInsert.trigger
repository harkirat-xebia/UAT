/*
----------------------------------------------------------------------
-- - Name          : TRER06_EmailMessageAfterInsert
-- - Author        : OLA
-- - Description   : 1 - When PDF is sent to Contact, change quote status to Presented
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  JAN-2019       OLA                 1.0         Initial version
--  JUL-2019       OLA                 1.1         Add Email message Quote condition.
--  APR-2021       AAM				   1.2		   Bypass if automated process user (Auto enrollment)
---------------------------------------------------------------------------------------
*/
trigger TRER06_EmailMessageAfterInsert on EmailMessage(after insert) {
  Map<id, EmailMessage> newEmailMessageMap = Trigger.newMap;
  Set<id> emailMessageQuoteIds = new Set<id>();
  Set<id> emailMessageCaseIds = new Set<id>();
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
  if (APER10_User_Management.canTrigger && UserInfo.getUserType() != 'AutomatedProcess') {
    System.debug('###:TRER06_EmailMessageAfterInsert after insert Start');
    List<UserRole> usrRole = [SELECT Name, DeveloperName FROM UserRole WHERE id = :UserInfo.getUserRoleId()];
    if (!usrRole.isEmpty()) {
      roleName = usrRole[0].name;
    }
    for (EmailMessage EMinst : newEmailMessageMap.values()) {
      //10 JULY Check if From Name starts with user BU or equals user Name.
      if (
        !EMinst.Incoming &&
        String.isNotBlank(EMinst.FromName) &&
        EMinst.FromName != userInfo.getName() &&
        (!EMinst.FromName.startsWith(APER10_User_Management.userBU) ||
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
        SELECT id, Status, Opportunity.StageName, OpportunityId
        FROM quote
        WHERE id IN :emailMessageQuoteIds AND Status = :Label.LABS_SF_Quote_Status_Draft
      ];

      if (!quoteList.isEmpty()) {
        APER11_Quote_Management.updateQuoteStatus(quoteList);
      }
    }
    List<QueueSobject> queueList = [
      SELECT Id, queue.name
      FROM QueueSobject
      WHERE
        SobjectType = 'Case'
        AND queue.Name IN ('ERFI Beneficiary', 'ERFI Client', 'ERFI Merchant 1st line', 'ERFI Delicard')
    ];
    if (!queueList.isEmpty()) {
      for (QueueSobject queueItem : queueList) {
        queueMap.put(queueItem.queue.Name, queueItem.queue.Id);
      }
    }
    if (!emailMessageCaseIds.isEmpty()) {
      List<Case> caseList = [
        SELECT id, Status, ER_EmailReceivedWhileClosed__c, OwnerId
        FROM Case
        WHERE
          id IN :emailMessageCaseIds
          AND (Status = :Label.LAB_SF_Case_resolved
          OR Status = :Label.LAB_SF_Case_Closed
          OR Status = :Label.LAB_SF_Case_Cancelled)
      ];

      List<Case> pendingCaseList = [
        SELECT Id, Status, OwnerId
        FROM Case
        WHERE id IN :emailMessageCaseIds AND Status = :Label.LAB_SF_Case_Pending AND ER_BUPicklist__c = 'FI'
      ];

      if (!pendingCaseList.isEmpty()) {
        for (Case casee : pendingCaseList) {
          switch on relatedCaseMap.get(casee.Id) {
            when 'edunsaaja-fi@edenred.com' {
              casee.ownerId = queueMap.get('ERFI Beneficiary');
            }
            when 'yritys-fi@edenred.com' {
              casee.OwnerId = queueMap.get('ERFI Client');
            }
            when 'kumppanit-fi@edenred.com' {
              casee.OwnerId = queueMap.get('ERFI Merchant 1st line');
            }
            when 'delicard-fi@edenred.com', 'info@delicard.fi' {
              casee.OwnerId = queueMap.get('ERFI Delicard');
            }
          }
          casee.Status = Label.LAB_SF_Case_inProgress;
        }
        update pendingCaseList;
      }
      if (!caseList.isEmpty()) {
        for (Case c : caseList) {
          c.ER_EmailReceivedWhileClosed__c = true;
          c.Status = 'Reopen';
        }
        update caseList;
      }
    }

    System.debug('###:TRER06_EmailMessageAfterInsert after insert End');
  }

}