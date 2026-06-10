public with sharing class CaseTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('CaseTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    APER08_Case_Management.processCaseBeforeInsert((List<Case>) newItems);

    //Noor - update case as spam
    APER08_Case_Management.updateCaseAsSpam((List<Case>) newItems);

    //Snica - fill in Individual when Account (personal Account) is filled
    APER08_Case_Management.populateIndividualFieldBasedOnRT((List<Case>) newItems);
    APER08_Case_Management.populateContactId((List<Case>) newItems);

    //SNICA - Migrate all case WF
    APER08_Case_Management.updateCaseSubject(Trigger.new);

    //Noor update customer segment, Reason, Priority
    APER08_Case_Management.updateCaseField((List<Case>) newItems);

    //Noor - assignment rule for FI
    //APER08_Case_Management.caseAutoAssignment((List<Case>) newItems);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //IML processCaseAfterInsert
    APER08_Case_Management.processCaseAfterInsert(Trigger.new, oldItems);
    APER08_Case_Management.updateTimeOpenedField(Trigger.new, (Map<Id, Case>) oldItems);

    APER08_Case_Management.triggerAutoResponse(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    if (APER10_User_Management.canTrigger)
      APER08_Case_Management.processCaseBeforeUpdate(Trigger.new, newItems, oldItems);
    //Snica - fill in Individual when Account (personal Account) is filled
    APER08_Case_Management.populateIndividualFieldBasedOnRT(Trigger.new);
    APER08_Case_Management.populateContactId(Trigger.new);
    APER08_Case_Management.UpdateMergedOwner(Trigger.new, (Map<Id, Case>) oldItems);
    APER08_Case_Management.updateTimeOpenedField(Trigger.new, (Map<Id, Case>) oldItems);
    //SNICA - Migrate all case WF
    APER08_Case_Management.updateCaseSubject(Trigger.new);

    //Noor update customer segment, Reason, Priority
    APER08_Case_Management.updateCaseField((List<Case>) newItems.values());

    //Noor update Escalation Field
    APER08_Case_Management.updateEscalationField((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

    //Noor update Account On Case when contact is changed
    APER08_Case_Management.updateAccountOnCase((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER08_Case_Management.processCaseAfterUpdate(Trigger.new, oldItems);

    //Noor - When a case is closed disconnect the related task in Genesys
    APER08_Case_Management.disconnectRelatedTaskOnClosedCase((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

    //Noor - close related case when parent case is closed
    APER08_Case_Management.closeRelatedCase((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

    //Noor - each time a case is created route case to Genesys and create a task
    //Please note that this code is in AfterUpdate because we need the case assignment to execute
    APER08_Case_Management.routeCaseToGenesys((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}