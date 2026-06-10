global class UpdateGroupEmployeeCountBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name 
            FROM Account 
            WHERE ER_Decision_maker__c = TRUE 
            AND ParentId = null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> grandParentAccounts) {
        Map<Id, Decimal> accountToEmployeeCount = new Map<Id, Decimal>();

        for (Account grandParent : grandParentAccounts) {
            Set<Id> hierarchyIds = new Set<Id>();
            hierarchyIds.add(grandParent.Id);
            hierarchyIds.addAll(getChildAccounts(grandParent.Id));

            AggregateResult[] results = [
                SELECT SUM(NumberOfEmployees) totalEmployees
                FROM Account
                WHERE Id IN :hierarchyIds
            ];

            Decimal totalEmployees = (Decimal)results[0].get('totalEmployees');
            accountToEmployeeCount.put(grandParent.Id, totalEmployees != null ? totalEmployees : 0);
        }

        // Prepare updates
        List<Account> updatesAccRec = new List<Account>();
        for (Account acc : grandParentAccounts) {
            if (accountToEmployeeCount.containsKey(acc.Id)) {
                acc.Total_Group_Employees__c = accountToEmployeeCount.get(acc.Id);
                updatesAccRec.add(acc);
            }
        }

        if (!updatesAccRec.isEmpty()) {
            update updatesAccRec;
        }
    }

    global void finish(Database.BatchableContext bc) {}

    private Set<Id> getChildAccounts(Id parentId) {
        Set<Id> allChildren = new Set<Id>();
        List<Account> children = [SELECT Id FROM Account WHERE ParentId = :parentId];
        for (Account child : children) {
            allChildren.add(child.Id);
            allChildren.addAll(getChildAccounts(child.Id));
        }
        return allChildren;
    }
}