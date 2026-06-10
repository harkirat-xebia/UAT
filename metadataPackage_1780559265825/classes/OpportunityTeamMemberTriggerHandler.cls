public class OpportunityTeamMemberTriggerHandler implements ITriggerHandler {
    public static Boolean triggerDisabled = false;
    
    public Boolean isDisabled() {
        if (UtilsBypass.canTrigger('OpportunityTeamMemberTrigger'))
            return triggerDisabled;
        else
            return true;
    }
    
    public void beforeInsert(List<SObject> newItems) {
    }
    
    public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        OpportunityTeamMemberManagement.storeUserIdOnOpportunityForVisibility((List<OpportunityTeamMember>) newItems.values(), null);
    }
    
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        OpportunityTeamMemberManagement.storeUserIdOnOpportunityForVisibility((List<OpportunityTeamMember>) newItems.values(), (Map<Id, OpportunityTeamMember>) oldItems);
    }
    
    public void beforeDelete(Map<Id, SObject> oldItems) {
    }
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        OpportunityTeamMemberManagement.storeUserIdOnOpportunityForVisibility(null, (Map<Id, OpportunityTeamMember>) oldItems);
    }
    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        OpportunityTeamMemberManagement.storeUserIdOnOpportunityForVisibility(null, (Map<Id, OpportunityTeamMember>) oldItems);
    }
    
}