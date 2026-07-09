public with sharing class APER11_FrameworkAgreement_Management {

    public static void setFrameworkFlag(List<Quote> newQuotes) {
        Set<Id> oppIds = new Set<Id>();
        for (Quote q : newQuotes) {
            if (q.OpportunityId != null) oppIds.add(q.OpportunityId);
        }
        if (oppIds.isEmpty()) return;

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Type FROM Opportunity WHERE Id IN :oppIds]
        );

        for (Quote q : newQuotes) {
            Opportunity opp = oppMap.get(q.OpportunityId);
            if (opp != null && opp.Type == 'Framework Agreement') {
                q.Is_Framework_Agreement__c = true;
            }
        }
    }

    // Must be called from after-insert context — quote Ids must be populated
    public static void createFrameworkScopeRecords(List<Quote> newQuotes) {
        List<Quote> frameworkQuotes = new List<Quote>();
        Set<Id> oppIds = new Set<Id>();

        for (Quote q : newQuotes) {
            if (q.Is_Framework_Agreement__c && q.OpportunityId != null) {
                frameworkQuotes.add(q);
                oppIds.add(q.OpportunityId);
            }
        }
        if (frameworkQuotes.isEmpty()) return;

        // Duplicate prevention — skip quotes that already have Framework_Scope__c records
        Set<Id> frameworkQuoteIds = new Set<Id>();
        for (Quote q : frameworkQuotes) frameworkQuoteIds.add(q.Id);

        Set<Id> quotesWithExistingScope = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Quote__c q FROM Framework_Scope__c
            WHERE Quote__c IN :frameworkQuoteIds
            GROUP BY Quote__c
        ]) {
            quotesWithExistingScope.add((Id) ar.get('q'));
        }

        List<Quote> quotesToProcess = new List<Quote>();
        for (Quote q : frameworkQuotes) {
            if (!quotesWithExistingScope.contains(q.Id)) quotesToProcess.add(q);
        }
        frameworkQuotes = quotesToProcess;
        if (frameworkQuotes.isEmpty()) return;

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, AccountId FROM Opportunity WHERE Id IN :oppIds]
        );

        Map<Id, Id> quoteToRootAccount = new Map<Id, Id>();
        Set<Id> rootAccountIds = new Set<Id>();
        for (Quote q : frameworkQuotes) {
            Opportunity opp = oppMap.get(q.OpportunityId);
            if (opp != null && opp.AccountId != null) {
                quoteToRootAccount.put(q.Id, opp.AccountId);
                rootAccountIds.add(opp.AccountId);
            }
        }
        if (rootAccountIds.isEmpty()) return;

        Map<Id, Map<Id, Account>> rootToDescendants = buildDescendantMap(rootAccountIds);

        List<Framework_Scope__c> scopeRecords = new List<Framework_Scope__c>();
        for (Quote q : frameworkQuotes) {
            Id rootAccId = quoteToRootAccount.get(q.Id);
            if (rootAccId == null) continue;
            Map<Id, Account> descendants = rootToDescendants.get(rootAccId);
            if (descendants == null || descendants.isEmpty()) continue;
            for (Account child : descendants.values()) {
                scopeRecords.add(new Framework_Scope__c(
                    Quote__c = q.Id,
                    Account__c = child.Id,
                    Entity_Name__c = child.Name,
                    Entity_Legal_Registration_Number__c = child.ER_Registration_Number__c,
                    Included__c = false,
                    Sent_to_DocuSign__c = false
                ));
            }
        }

        if (!scopeRecords.isEmpty()) insert scopeRecords;
    }

    // Single shared BFS across ALL root accounts — at most 5 SOQL queries total regardless of root count
    @TestVisible
    private static Map<Id, Map<Id, Account>> buildDescendantMap(Set<Id> rootAccountIds) {
        Map<Id, Map<Id, Account>> result = new Map<Id, Map<Id, Account>>();
        for (Id rootId : rootAccountIds) {
            result.put(rootId, new Map<Id, Account>());
        }

        // Track which root ancestor each visited account belongs to
        Map<Id, Id> accountToRoot = new Map<Id, Id>();
        for (Id rootId : rootAccountIds) {
            accountToRoot.put(rootId, rootId);
        }

        Set<Id> currentLevel = new Set<Id>(rootAccountIds);
        Integer maxDepth = 5;

        while (!currentLevel.isEmpty() && maxDepth-- > 0) {
            List<Account> children = [
                SELECT Id, Name, ER_Registration_Number__c, ParentId
                FROM Account
                WHERE ParentId IN :currentLevel
            ];
            currentLevel.clear();
            for (Account a : children) {
                Id rootId = accountToRoot.get(a.ParentId);
                if (rootId == null || result.get(rootId).containsKey(a.Id)) continue;
                result.get(rootId).put(a.Id, a);
                accountToRoot.put(a.Id, rootId);
                currentLevel.add(a.Id);
            }
        }
        return result;
    }
}
