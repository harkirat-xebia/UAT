public with sharing class FrameworkScopeController {

    @AuraEnabled
    public static List<Framework_Scope__c> getScopeRecords(Id quoteId) {
        return [
            SELECT Id, Entity_Name__c, Entity_Legal_Registration_Number__c, Included__c
            FROM Framework_Scope__c
            WHERE Quote__c = :quoteId
            ORDER BY Entity_Name__c
        ];
    }

    @AuraEnabled
    public static void saveScopeSelections(List<Framework_Scope__c> records, Id quoteId) {
        update records;
        update new Quote(Id = quoteId, Framework_Scope_Defined__c = true);
    }
}
