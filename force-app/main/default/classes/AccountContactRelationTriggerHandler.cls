/**
 * Created by ATI on 21/08/2021.
 */

public with sharing class AccountContactRelationTriggerHandler implements ITriggerHandler {
    public static Boolean triggerDisabled = false;

    public Boolean isDisabled() {
        if(UtilsBypass.canTrigger('AccountContactRelationTriggerHandler')) return triggerDisabled;
        else return true;
    }
    
    public void beforeInsert(List<SObject> newItems) {}

    public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        APER44_AccountContactRelationManagement.syncAccountContactRelationship(Trigger.new);
    }

    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        APER44_AccountContactRelationManagement.patchAccountContactRelationship(Trigger.new, (Map<Id, AccountContactRelation>) Trigger.oldMap);
    }

    public void beforeDelete(Map<Id, SObject> oldItems) {}

    public void afterDelete(Map<Id, SObject> oldItems) {}

    public void afterUndelete(Map<Id, SObject> oldItems) {}

}