/**
----------------------------------------------------------------------
-- - Name          : EmailMessageTriggerHandler
-- - Author        : Noor
-- - Description   : Handler for all EmailMessage Trigger
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 12/10/2021   Noor                1.0         Trigger Handler Rework.
---------------------------------------------------------------------------------------
*/
public with sharing class EmailMessageTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('EmailMessageTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    APER35_EmailMessage_Management.blockSendingZuoraErrorEmails(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //When PDF is sent to Contact, change quote status to Presented
    if (APER10_User_Management.canTrigger && UserInfo.getUserType() != 'AutomatedProcess')
      APER35_EmailMessage_Management.changeQuoteStatusToPresented((Map<id, EmailMessage>) newItems);

    //CWA Update Case Status upon Inbound or outbound email
    APER35_EmailMessage_Management.UpdateCaseStatusInboundOutboundEmail(Trigger.new);

    //CWA Reopen Case or New Case Creation depending on the date an email is received
    APER35_EmailMessage_Management.CaseReopenBehaviour(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}