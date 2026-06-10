public without sharing class ApprovalBannerAlertController {
    @AuraEnabled
    public static string checkApprovalConditions(Id recordId){
        try {
            String approvalCondition = 'None'; //Will return values: None, Discount Approval, Finance Approval, Both
            Integer count = 0;
            Opportunity opportunityRecord  = [Select Id, ER_NeedFinancialApproval__c FROM Opportunity WHERE Id =:recordId];
            List<OpportunityLineItem> oliList = [Select Id, ER_NeedApproval__c, Opportunity.ER_NeedApproval__c FROM OpportunityLineItem WHERE OpportunityId =: recordId];
            
            if(!oliList.isEmpty()){
                for(OpportunityLineItem oli : oliList){
                    if(oli.ER_NeedApproval__c == true && oli.Opportunity.ER_NeedApproval__c == true){
                        count++;
                    }
                }
            }
            if(count > 0 && opportunityRecord.ER_NeedFinancialApproval__c == true){
                approvalCondition = 'Both';
            }else if(count > 0){
                approvalCondition = 'Discount Approval';
            }else if(opportunityRecord.ER_NeedFinancialApproval__c == true){
                approvalCondition = 'Finance Approval';
            }

            return approvalCondition;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}