/**
/**
 * @author : Noor
 * @date : 11/07/2023
 * @desc : LoopTriggerHandler
 */
public with sharing class LoopTriggerHandler implements ITriggerHandler {

    public void beforeInsert(List<SObject> newItems) {
    }

    public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //AAZ 16/08/2023 - Sync Smarter Loops to Legacy
        APER43_LoopManagement.createSmarterMerchantLoop((List<ER_Loop__c>) newItems.values(), null);
    }

    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }

    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //AAZ 16/08/2023 - Sync Smarter Loops to Legacy
        APER43_LoopManagement.createSmarterMerchantLoop((List<ER_Loop__c>) newItems.values(), null);

        //Noor - call smarter API CreateMerchantLoopStoreGroup to synchronize loops when ER_Merchant_loop_ID__c is updated
        APER43_LoopManagement.createMerchantLoopStoreGroup((List<ER_Loop__c>) newItems.values(), (Map<Id, ER_Loop__c>) oldItems);
    }

    public void beforeDelete(Map<Id, SObject> oldItems) {
    }

    public void afterDelete(Map<Id, SObject> oldItems) {
    }

    public void afterUndelete(Map<Id, SObject> oldItems) {
    }

    public static Boolean triggerDisabled = false;

    public Boolean isDisabled() {
        if(UtilsBypass.canTrigger('LoopTrigger')) {return triggerDisabled;}
        else {return true;}
    }
}