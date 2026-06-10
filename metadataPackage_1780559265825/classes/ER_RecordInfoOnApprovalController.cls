public with sharing class ER_RecordInfoOnApprovalController {
    @AuraEnabled(cacheable=true)
  public static Map<String, Object> getOpportunityDataFromWorkItem(String workItemId) {
    Map<String, Object> result = new Map<String, Object>();

    ProcessInstanceWorkitem workItem = [
      SELECT Id, ProcessInstance.TargetObjectId
      FROM ProcessInstanceWorkitem
      WHERE Id = :workItemId
      LIMIT 1
    ];

    Id opportunityId = workItem.ProcessInstance.TargetObjectId;

    Opportunity opp = [
      SELECT Id, Name, StageName, Amount, CloseDate
      FROM Opportunity
      WHERE Id = :opportunityId
      LIMIT 1
    ];
    result.put('opportunity', opp);

    List<OpportunityLineItem> items = [
      SELECT Id, Quantity, UnitPrice, TotalPrice, Product2.Name,PriceBookEntry.ER_SolutionName__c, 
      ER_Percentage__c ,Discount ,PriceBookEntry.Name,ER_Estimated_Value__c,Total_Amount__c,ER_Face_Value__c ,ER_Days_Per_Month__c 
      ,ER_Load_Per_Year__c 
      ,ER_Nb_Beneficiaries__c 
      FROM OpportunityLineItem
      WHERE OpportunityId = :opportunityId
    ];
    result.put('lineItems', items);

    return result;
  }
}