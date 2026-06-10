/*
----------------------------------------------------------------------
-- - Name          : OpportunityTeamMemberManagement
-- - Author        : Snehil Verma
-- - Description   : User Management, This class is used to all opportunity team members userid on Opportunity for visibility control.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  DEC-2024    SNEHIL                1.0       Initial version
---------------------------------------------------------------------------------------
*/
public class OpportunityTeamMemberManagement {
	public static void storeUserIdOnOpportunityForVisibility(List<OpportunityTeamMember> opportunityTeamMembers, Map<Id, OpportunityTeamMember> oldItems) {
        
        Set<Id> opportunityIdSet = new Set<Id>();
        Map<Id, Set<Id>> opportunityMembersMap = new Map<Id, Set<Id>>();
        List<Opportunity> opportunityUpdateList = new List<Opportunity>();
        
        if(opportunityTeamMembers != null){
            for (OpportunityTeamMember otmObj : opportunityTeamMembers) {
                if((oldItems == null || (oldItems != null && (oldItems.get(otmObj.Id).UserId != otmObj.UserId || oldItems.get(otmObj.Id).OpportunityId  != otmObj.OpportunityId ))) && otmObj.OpportunityId != null && otmObj.UserId != null){
                    opportunityIdSet.add(otmObj.OpportunityId);
                }
            }
        }
        
        if(opportunityTeamMembers == null && oldItems != null){
            for(OpportunityTeamMember otmObj : oldItems.values()){
                if(otmObj.OpportunityId != null && otmObj.UserId != null){
                    opportunityIdSet.add(otmObj.OpportunityId);
                }
            }
        }
        
        for(OpportunityTeamMember otmObj : [SELECT Id, OpportunityId, UserId from OpportunityTeamMember where OpportunityId IN: opportunityIdSet]){
            if(!opportunityMembersMap.containsKey(otmObj.OpportunityId)){
                opportunityMembersMap.put(otmObj.OpportunityId, new Set<Id>{otmObj.UserId});
            }else{
                opportunityMembersMap.get(otmObj.OpportunityId).add(otmObj.UserId);
            }
        }
        
        for(Id oppId : opportunityIdSet){
            String concatenatedUserIds = '';
            if(opportunityMembersMap.containsKey(oppId)){
                concatenatedUserIds = String.join(opportunityMembersMap.get(oppId), ';');
                if (concatenatedUserIds.length() > 255) {
                    Integer lastIndex = concatenatedUserIds.substring(0, 255).lastIndexOf(';');
                    if (lastIndex != -1) {
                        concatenatedUserIds = concatenatedUserIds.substring(0, lastIndex);
                    }
                }
            }
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            opp.User_Id_for_Visibility__c  = concatenatedUserIds;
            opportunityUpdateList.add(opp);
        }
        
        if(!opportunityUpdateList.isEmpty()){
            update opportunityUpdateList;
        }
    }
}