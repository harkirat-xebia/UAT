/**
 * @author: ALK
 * @date: 07/02/2022
 * @desc: MedalliaFeedbackTriggerHandler
 * @see: MedalliaFeedbackTriggerHandler
 */

public with sharing class MedalliaFeedbackTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('MedalliaFeedbackTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //ALK - Autopopulate the individual lookup on the feedback record
    //Medallia_Feedback_Management.fillInIndividualLookup(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Create Medallia Cases
    //Medallia_Feedback_Management.createMedalliaCases(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Autopopulate the individual lookup on the feedback record
    //Medallia_Feedback_Management.fillInIndividualLookup(Trigger.new);
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