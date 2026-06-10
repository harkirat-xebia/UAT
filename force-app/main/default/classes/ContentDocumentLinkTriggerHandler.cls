/**
 * @author : Snehil
 * @date : 29/11/2024
 * @desc : ContentDocumentLinkTriggerHandler
 * @see ContentDocumentLinkTriggerHandler
 */
public with sharing class ContentDocumentLinkTriggerHandler implements ITriggerHandler {
    
    public static Boolean triggerDisabled = false;
    
    public Boolean isDisabled() {
        if (UtilsBypass.canTrigger('ContentDocumentLinkTrigger'))
            return triggerDisabled;
        else
            return true;
    }
    
    public void beforeInsert(List<SObject> newItems) {
        
    }
    
    public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ContentDocumentLinkManagement.attachDocumentFromQuoteToOpportunity(Trigger.New);
    }
    
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void beforeDelete(Map<Id, SObject> oldItems) {}
    
    public void afterDelete(Map<Id, SObject> oldItems) {}
    
    public void afterUndelete(Map<Id, SObject> oldItems) {}
    
}