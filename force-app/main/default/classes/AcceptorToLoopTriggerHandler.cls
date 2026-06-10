/**
 * @author : ALK
 * @date : 25/05/2021
 * @desc : AcceptorToLoopTriggerHandler
 * @see AcceptorToLoopTriggerHandler
 * @see ITriggerHandler
 */

public with sharing class AcceptorToLoopTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('AcceptorToLoopTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  public void beforeInsert(List<SObject> newItems) {
    APER22_AcceptorToLoopManagement.CheckAcceptorToLoop(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        APER22_AcceptorToLoopManagement.handleAcceptorToLoopsSync(Trigger.new);
  }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //APER22_AcceptorToLoopManagement.handleAcceptorToLoopsSync(Trigger.new);
  }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}