public without sharing class BE_General_Cond_Without_Sharing_Ctrl {

    public static Boolean isOfferLight(String key, Id opportunityId){
        return BE_Webform_Controller_Helper.isOfferLight(key, opportunityId);
    }    

    /*public static BE_General_Condition__c getGeneralCondition(String language, String product, Id opportunityId,
    														  String stakeholderType){
    	return BE_General_Conditions_Controller.getGeneralCondition(language, product, opportunityId, stakeholdertype);
    }*/

    public static String submitAgreedToGeneralConditions(Boolean agreedToGeneralConditions, Boolean prepaymentAccepted,
                                                       Id opportunityId, Id accountId, String stakeholderType,
                                                       String productName, String emailAddress, String formLanguage){
    	return BE_General_Conditions_Controller.submitAgreedToGeneralConditions(agreedToGeneralConditions, prepaymentAccepted,
                                       									        opportunityId, accountId, stakeholderType,
                                       									        productName, emailAddress, formLanguage);
	}
     
    public static String createQuote(String opportunityId){
    	return BE_General_Conditions_Controller.createQuote(opportunityId);
	}
    
    public static void createContract(String quoteId){
    	BE_General_Conditions_Controller.createContract(quoteId);
	}
    
     /**
* @author Mayank Sankhla
* @date 18/04/2024
* @description Sync Total Group Employees on grand Parent
*/
    public static void handleEmployeeCountRollup(
        Map<Id, Account> oldMap,
        Map<Id, Account> newMap,
        List<Account> newList,
        List<Account> oldList,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        Boolean isUndelete
    ) {
        Set<Id> affectedAccountIds = new Set<Id>();
        
        if (isInsert || isUndelete) {
            for (Account acc : newList) {
                affectedAccountIds.add(acc.Id);
            }
        }
        
        if (isDelete) {
            for (Account acc : oldList) {
                affectedAccountIds.add(acc.Id);
            }
        }
        
        if (isUpdate) {
            for (Id accId : newMap.keySet()) {
                Account oldAcc = oldMap.get(accId);
                Account newAcc = newMap.get(accId);
                
                if (oldAcc.NumberOfEmployees != newAcc.NumberOfEmployees) {
                    affectedAccountIds.add(accId);
                    
                    // If the updated account has children, it may be a grandparent
                    List<Account> children = [
                        SELECT Id FROM Account WHERE ParentId = :accId LIMIT 1
                    ];
                    if (!children.isEmpty()) {
                        affectedAccountIds.add(accId); // ensure it's processed as a grandparent
                    }
                }
            }
        }
        
        if (affectedAccountIds.isEmpty()) return;
        
        Map<Id, Account> affectedAccounts = new Map<Id, Account>(
            [SELECT Id, ParentId FROM Account WHERE Id IN :affectedAccountIds]
        );
        
        Set<Id> allAncestorIds = new Set<Id>();
        
        for (Account acc : affectedAccounts.values()) {
            Id parentId = acc.ParentId;
            if (parentId == null) {
                allAncestorIds.add(acc.Id); // It may be a grandparent being updated
                continue;
            }
            
            Account parent = [SELECT Id, ParentId FROM Account WHERE Id = :parentId LIMIT 1];
            if (parent.ParentId != null) {
                allAncestorIds.add(parent.ParentId);
            } else {
                allAncestorIds.add(parent.Id); // parent is grandparent
            }
        }
        
        if (allAncestorIds.isEmpty()) return;
        
        // Fetch grandparent accounts to include their own NumberOfEmployees
        Map<Id, Account> grandParentAccounts = new Map<Id, Account>(
            [SELECT Id, NumberOfEmployees FROM Account WHERE Id IN :allAncestorIds]
        );
        
        Set<Id> descendantIds = getAllDescendantAccountIds(allAncestorIds);
        descendantIds.addAll(allAncestorIds);
        
        // Fetch the actual Account records to sum
        List<Account> descendants = [
            SELECT Id, ParentId, NumberOfEmployees FROM Account
            WHERE Id IN :descendantIds
        ];
        
        Map<Id, Integer> grandParentToEmployeeSum = new Map<Id, Integer>();
        
        Map<Id, Id> accountToParent = new Map<Id, Id>();
        for (Account acc : descendants) {
            accountToParent.put(acc.Id, acc.ParentId);
        }
        
        for (Account acc : descendants) {
            Id grandParentId = findGrandParentId(acc.Id, accountToParent, allAncestorIds);
            if (grandParentId != null) {
                Integer sum = grandParentToEmployeeSum.get(grandParentId);
                grandParentToEmployeeSum.put(
                    grandParentId,
                    (sum == null ? 0 : sum) + (acc.NumberOfEmployees == null ? 0 : acc.NumberOfEmployees)
                );
            }
        }
        
        // Include grandparent's own NumberOfEmployees
        for (Id gpId : allAncestorIds) {
            Account gp = grandParentAccounts.get(gpId);
            if (gp != null && gp.NumberOfEmployees != null) {
                Integer currentSum = grandParentToEmployeeSum.get(gpId);
                grandParentToEmployeeSum.put(gpId, (currentSum == null ? 0 : currentSum) + gp.NumberOfEmployees);
            }
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        for (Id gpId : grandParentToEmployeeSum.keySet()) {
            accountsToUpdate.add(new Account(
                Id = gpId,
                Total_Group_Employees__c = grandParentToEmployeeSum.get(gpId)
            ));
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
    
    private static Set<Id> getAllDescendantAccountIds(Set<Id> parentIds) {
        Set<Id> allDescendantIds = new Set<Id>();
        Set<Id> currentLevel = new Set<Id>(parentIds);
        
        while (!currentLevel.isEmpty()) {
            List<Account> children = [
                SELECT Id FROM Account WHERE ParentId IN :currentLevel
            ];
            Set<Id> nextLevel = new Set<Id>();
            
            for (Account child : children) {
                if (!allDescendantIds.contains(child.Id)) {
                    allDescendantIds.add(child.Id);
                    nextLevel.add(child.Id);
                }
            }
            
            currentLevel = nextLevel;
        }
        
        return allDescendantIds;
    }
    
    // Traces an account’s grandparent ID (from accountToParent map)
    private static Id findGrandParentId(Id accId, Map<Id, Id> accountToParent, Set<Id> knownGrandParents) {
        Id parentId = accountToParent.get(accId);
        if (parentId == null) return null;
        
        Id grandParentId = accountToParent.get(parentId);
        if (grandParentId != null && knownGrandParents.contains(grandParentId)) {
            return grandParentId;
        }
        
        if (knownGrandParents.contains(parentId)) {
            return parentId;
        }
        
        return null;
    }
}