public with sharing class FrameworkScopeController {

    @AuraEnabled
    public static List<Framework_Scope__c> getScopeRecords(Id quoteId) {
        Quote q = [SELECT OpportunityId, Opportunity.AccountId FROM Quote WHERE Id = :quoteId LIMIT 1];
        Id rootAccountId = q.Opportunity?.AccountId;

        if (rootAccountId != null) {
            Map<Id, Account> currentDescendants =
                APER11_FrameworkAgreement_Management.buildDescendantMap(
                    new Set<Id>{ rootAccountId }
                ).get(rootAccountId);

            Set<Id> existingAccountIds = new Set<Id>();
            for (Framework_Scope__c s : [SELECT Account__c FROM Framework_Scope__c WHERE Quote__c = :quoteId]) {
                existingAccountIds.add(s.Account__c);
            }

            List<Framework_Scope__c> toInsert = new List<Framework_Scope__c>();
            if (currentDescendants != null) {
                for (Account a : currentDescendants.values()) {
                    if (!existingAccountIds.contains(a.Id)) {
                        toInsert.add(new Framework_Scope__c(
                            Quote__c = quoteId,
                            Account__c = a.Id,
                            Entity_Name__c = a.Name,
                            Entity_Legal_Registration_Number__c = a.ER_Registration_Number__c,
                            Included__c = false,
                            Sent_to_DocuSign__c = false
                        ));
                    }
                }
            }
            if (!toInsert.isEmpty()) insert toInsert;
        }

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

    @AuraEnabled
    public static Map<String, Object> getFrameworkScopeSummary(Id quoteId) {
        Quote q = [SELECT Is_Framework_Agreement__c, Framework_Scope_Defined__c FROM Quote WHERE Id = :quoteId LIMIT 1];
        if (!q.Is_Framework_Agreement__c) return null;

        Integer includedCount = [SELECT COUNT() FROM Framework_Scope__c WHERE Quote__c = :quoteId AND Included__c = true];

        List<Framework_Scope__c> recent = [
            SELECT LastModifiedDate FROM Framework_Scope__c
            WHERE Quote__c = :quoteId
            ORDER BY LastModifiedDate DESC LIMIT 1
        ];

        return new Map<String, Object>{
            'isFramework' => true,
            'scopeDefined' => q.Framework_Scope_Defined__c,
            'includedCount' => includedCount,
            'lastModified' => recent.isEmpty() ? null : recent[0].LastModifiedDate
        };
    }
}
