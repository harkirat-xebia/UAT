/**
 * Created by khaddouch on 10/05/2023.
 */

public with sharing class BulkContractAmendmentTriggerHandler implements ITriggerHandler {
    public static Boolean triggerDisabled = false;

    public Boolean isDisabled() {
        if(UtilsBypass.canTrigger('BulkContractAmendmentTriggerHandler')) return triggerDisabled; else return true;
    }

    public void beforeInsert(List<SObject> newItems) {
        APER41_BulkContractAmendment_Management.fillTechnicalFields(Trigger.new);
    }

    public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }

    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        APER41_BulkContractAmendment_Management.fillTechnicalFields(Trigger.new);
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