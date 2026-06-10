/**
 * Created by davram on 3/30/2021.
 */

public with sharing class AcceptorTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('AcceptorTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //NGO Add blocking rules for Edenred POS acceptors for BU ES
    APER23_Acceptor_Management.addBlockingRulesForEdenredPOS((List<ER_Acceptor__c>) newItems);

    APER23_Acceptor_Management.checkAndUpdateStore(Trigger.new);
    APER23_Acceptor_Management.checkAndUpdateStoreStatus(Trigger.new);

    //NOOR - generate MID TID Authorization Code
    APER23_Acceptor_Management.generateMID_TID_Authorization((List<ER_Acceptor__c>) newItems);

    //AAZ - Check the Acceptor Uniqueness
    APER23_Acceptor_Management.checkAcceptorUniqueness(Trigger.new, null);

    //VJO - Update Aggregator
    APER23_Acceptor_Management.updateAcceptorAggregatorOnInsert(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //APER23_Acceptor_Management.updateAddAcceptorFuture(Trigger.new);

    APER22_AcceptorToLoopManagement.CreatenewAcceptorToLoopOnAcceptorInsert(Trigger.new);

    APER23_Acceptor_Management.manageAccLIForNewAcceptor((Map<Id, ER_Acceptor__c>) Trigger.newMap);

    //AAZ - Create Docugen records to be used for the contract template
    APER23_Acceptor_Management.createDocugenQuoteStoreAcceptor(Trigger.new);

    //AAM - Set tech flag for MID fixed by users
    APER23_Acceptor_Management.updateMIDFlag(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Fill the creation date in OS in the Store level
    APER23_Acceptor_Management.syncAcceptorFlags(newItems, oldItems);
    APER23_Acceptor_Management.checkAndUpdateStore(Trigger.new);
    APER23_Acceptor_Management.checkAndUpdateStoreStatus(Trigger.new);

    //AAZ - Check the Acceptor Uniqueness
    APER23_Acceptor_Management.checkAcceptorUniqueness(Trigger.new, (Map<Id, ER_Acceptor__c>) Trigger.oldMap);

    //VJO - Update Aggregator
    APER23_Acceptor_Management.updateAcceptorAggregator(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //APER23_Acceptor_Management.updateAddAcceptorFuture(Trigger.new);
    APER23_Acceptor_Management.updateDigitalStoreStatus(Trigger.new, (Map<Id, ER_Acceptor__c>) Trigger.oldMap);

    //ALK - Sync Acceptors with EDG v3
    APER23_Acceptor_Management.syncAcceptors(Trigger.new, (Map<Id, ER_Acceptor__c>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}