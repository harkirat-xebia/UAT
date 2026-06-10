/*
----------------------------------------------------------------------
-- - Name          : APER20_Account_Management 
-- - Author        : Nicolae C
-- - Description   : Account Management, This class is used to group all the functionality linked to the object Account
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Dec-2019     Nicolae C           1.0         Initial version
-- FEB-2021     KHAD                2.0         Solution at all level
-- Jul-2023     MAME                2.1         COUL3020 Apply lead assignment rules when creating leads
---------------------------------------------------------------------------------------
*/
public class APER20_Account_Management { 
    /*
*
* Nicolae C
* Dec 2019
* manageStatusOnContractActivation: Manage status based on contract activation.
*
*/
    public static void manageStatusOnContractActivation(Id accountId) { 
        if (UtilsBypass.canTrigger('manageStatusOnContractActivation')) {
            GenericWithoutSharing.manageStatusOnContractActivation(accountId);
        }
    }
    /*
*
* Nicolae C
* Dec 2019
* manageStatusOnContractTermination: Manage status based on contract termination.
*
*/
    public static Void manageStatusOnContractTermination(Id accountId) {
        Boolean flag = false;
        List<ER_Store__c> stores = new List<ER_Store__c>();
        Account acc = [SELECT Id, ER_Status__c, ER_Inactive_date__c FROM Account WHERE ID = :accountId];
        List<Contract> cntrs = new List<Contract>();
        for (Contract c : [SELECT Id, Status FROM Contract WHERE AccountId = :accountId]) {
            flag = (c.Status == Label.LABS_SF_Contract_Status_Activated);
        }
        if (!flag && acc != null) {
            acc.ER_Status__c = Label.LABS_SF_Account_Status_Inactive;
            acc.ER_Inactive_date__c = Date.today();
            acc.ER_Inactive_Reason__c = Label.LABS_SF_Account_Inactive_Reason;
            WSHU02_SynchronizeMerchantWS.alreadyExecutedAccount = true;
            update acc;
            //PBI-3426
            //OLA : Disabling Store is already managed in TRER10_ER_StoreBeforeUpdate, when the store has no more SLI we disable it with Doesn’t accept any Solution ER_Closure_Reason__.
            //You can also merge manageStatusOnContractActivation & manageStatusOnContractTermination functions to manageAccountStatus and the query can be like [SELECT Id, ER_Status__c,(select id,Status from Contracts) FROM Account WHERE ID =: accountId
            /*for (ER_Store__c store : [SELECT Id, ER_Status__c, ER_Closure_Date__c, ER_Closure_Reason__c FROM ER_Store__c WHERE ER_Merchant__c =: accountId]) {
store.ER_Status__c = Label.LABS_SF_Store_Inactive;
store.ER_Closure_Date__c = Date.today();
store.ER_Closure_Reason__c = Label.LABS_SF_Store_Reason_Other;
stores.add(store);
}
if (!stores.isEmpty()) 
update stores;
*/
        }
    }
    
    /**
* @author ALK
* @date 30/09/2021
* @description Deactivate account having no more active contracts
* @param contactsIds
*/
    public static void deactivateAccountsStatusForTerminatedContracts(Set<Id> contactsIds) {
        Map<Id, Account> mapAccounts = new Map<Id, Account>();
        for (Contract c : [
            SELECT Id, AccountId, Account.ER_Status__c, Status
            FROM Contract
            WHERE
            Id IN :contactsIds
            AND Status = :Label.LABS_SF_Contract_Status_Terminated
            AND Account.ER_Status__c = :Label.LABS_SF_Account_Status_Active
        ]) {
            mapAccounts.put(
                c.AccountId,
                new Account(
                    Id = c.AccountId,
                    ER_Status__c = Label.LABS_SF_Account_Status_Inactive,
                    ER_Inactive_date__c = Date.today(),
                    ER_Inactive_Reason__c = Label.LABS_SF_Account_Inactive_Reason
                )
            );
        }
        
        if (!mapAccounts.isEmpty()) {
            for (Contract c : [
                SELECT Id, AccountId
                FROM Contract
                WHERE AccountId IN :mapAccounts.keySet() AND Status = :Label.LABS_SF_Contract_Status_Activated
            ]) {
                mapAccounts.remove(c.AccountId);
            }
            
            if (!mapAccounts.isEmpty())
                Database.update(mapAccounts.values(), false);
        }
    }
    
    /*
*
* Nicolae C
* Dec 2019
* manageStatusOnOpportunityClose: Manage status based on opportunity close.
*
*/
    /* commented for now!

public static Void manageStatusOnOpportunityClose(List<ID> accountIds) { 
Boolean flag = false;
List<Account> accsToUpdate = new List<Account>();
List<Account> accs = [SELECT Id, ER_Status__c, (SELECT ID, StageName FROM Opportunities) FROM Account WHERE ID =: accountIds];
system.debug('#accs: ' + accs);
for(Account acc : accs) {
for(Opportunity opp : acc.Opportunities) {
flag = flag ? flag : (opp.StageName == Label.LABS_SF_Opp_Status_ClosedLost);
}
if(flag) {
acc.ER_Status__c = Label.LABS_SF_Account_Status_Suspect;
accsToUpdate.add(acc);
}
}
if(!accsToUpdate.isEmpty())
update accsToUpdate;
}

*/
    
    /**
* @author AAZ
* @date 17/01/2022
* @param contract
*/
    public static void manageAccountLineItemsForContract(Contract contract) {
        if (UtilsBypass.canTrigger('manageAccountLineItemsForContract')) {
            GenericWithoutSharing.manageAccountLineItemsForContract(contract);
        }
    }
    
    public static Map<Id, ER_Solution_Line_Item__c> getAllAccountLineItems(Set<String> companyIds) {
        return new Map<Id, ER_Solution_Line_Item__c>(
            [
                SELECT
                Id,
                Name,
                ER_Financial_Center__c,
                ER_Solution__c,
                ER_Contract__c,
                ER_Status__c,
                ER_Scope__c,
                ER_Account__c
                FROM ER_Solution_Line_Item__c
                WHERE RecordType.DeveloperName = 'ER_Account_Line_Item' AND ER_Account__c IN :companyIds
            ]
        );
    }

    // New method added by harkirat for allowing only the manager and owner of the account to change the owner, ticket - 2326
    public static void validateHierarchyAndOwnerGovernance(
    Map<Id, Account> newMap,
    Map<Id, Account> oldMap
) {
    if (newMap == null || newMap.isEmpty() || oldMap == null || oldMap.isEmpty()) return;

    Id currentUserId = UserInfo.getUserId();
    Id currentUserRoleId = UserInfo.getUserRoleId(); // can be null

    // -----------------------------------------
    // Collect parents we need to validate against
    // -----------------------------------------
    Set<Id> parentIdsToQuery = new Set<Id>();

    // We need parent info when:
    // 1) ParentId changed to a non-null value
    // 2) OwnerId changed AND record has a parent (because Scenario 2 requires owner == parent owner)
    for (Account a : newMap.values()) {
        Account oldA = oldMap.get(a.Id);
        if (oldA == null) continue;

        Boolean parentChanged = (a.ParentId != oldA.ParentId);
        Boolean ownerChanged  = (a.OwnerId  != oldA.OwnerId);

        if (parentChanged && a.ParentId != null) {
            parentIdsToQuery.add(a.ParentId);
        }

        // if it has a parent (new value), and owner changed, we must enforce owner==parentOwner
        if (ownerChanged && a.ParentId != null) {
            parentIdsToQuery.add(a.ParentId);
        }
    }

    Map<Id, Account> parentMap = new Map<Id, Account>();
    if (!parentIdsToQuery.isEmpty()) {
        parentMap = new Map<Id, Account>([
            SELECT Id, OwnerId
            FROM Account
            WHERE Id IN :parentIdsToQuery
        ]);
    }

    // -----------------------------------------
    // Owner change restriction data (AC#2)
    // -----------------------------------------
    Set<Id> oldOwnerUserIds = new Set<Id>();
    for (Account a : newMap.values()) {
        Account oldA = oldMap.get(a.Id);
        if (oldA == null) continue;

        if (a.OwnerId != oldA.OwnerId && String.valueOf(oldA.OwnerId).startsWith('005')) {
            oldOwnerUserIds.add(oldA.OwnerId);
        }
    }

    Map<Id, User> oldOwnerUsers = new Map<Id, User>();
    if (!oldOwnerUserIds.isEmpty()) {
        oldOwnerUsers = new Map<Id, User>([
            SELECT Id, UserRoleId, Profile.Name, Name
            FROM User
            WHERE Id IN :oldOwnerUserIds
        ]);
    }

    Set<Id> seedRoleIds = new Set<Id>();
    for (User u : oldOwnerUsers.values()) {
        if (u.UserRoleId != null) seedRoleIds.add(u.UserRoleId);
    }
    Map<Id, Id> roleToParent = buildRoleParentMap(seedRoleIds);

    //Adding new logic for solving prod bug
    // Top-level parent (ParentId == null) child-owner map
    Set<Id> topParentsNeedingChildCheck = new Set<Id>();
    for (Account a : newMap.values()) {
        Account oldA = oldMap.get(a.Id);
        if (oldA == null) continue;

        Boolean ownerChanged = (a.OwnerId != oldA.OwnerId);
        if (ownerChanged && a.ParentId == null) {
            topParentsNeedingChildCheck.add(a.Id);
        }
    }

    Map<Id, Set<Id>> parentToChildOwners = new Map<Id, Set<Id>>();
    if (!topParentsNeedingChildCheck.isEmpty()) {
        for (Account child : [
            SELECT ParentId, OwnerId
            FROM Account
            WHERE ParentId IN :topParentsNeedingChildCheck
        ]) {
            if (!parentToChildOwners.containsKey(child.ParentId)) {
                parentToChildOwners.put(child.ParentId, new Set<Id>());
            }
            parentToChildOwners.get(child.ParentId).add(child.OwnerId);
        }
    }

    // -----------------------------------------
    // Validate rules
    // -----------------------------------------
    // Commenting below line and adding 
    //String profName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
    String profName;

    List<User> currentUser = [
        SELECT Profile.Name
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];

    if(!currentUser.isEmpty()){
        profName = currentUser[0].Profile.Name;
    }

    Boolean isAdminOrSalesOps = (profName == 'System Administrator' || profName == 'Sales Operations');

    for (Account a : newMap.values()) {
        Account oldA = oldMap.get(a.Id);
        if (oldA == null) continue;

        Boolean parentChanged = (a.ParentId != oldA.ParentId);
        Boolean ownerChanged  = (a.OwnerId  != oldA.OwnerId);

        // -----------------------------
        // AC#1 + Scenario 2 enforcement:
        // If account has a parent, child.OwnerId MUST equal parent.OwnerId
        // when linking/changing parent OR changing owner.
        // -----------------------------
        //if ((parentChanged || ownerChanged) && a.ParentId != null) {
        if (!isAdminOrSalesOps && (parentChanged || ownerChanged) && a.ParentId != null) {
            Account p = parentMap.get(a.ParentId);
            if (p != null && a.OwnerId != p.OwnerId) {
                a.addError('Child Account Owner must match the Parent Account Owner.');
            }
        }

        // -----------------------------
        // AC#2: restrict who can change OwnerId
        // -----------------------------
        if (ownerChanged) {
            
            //Allowing Accounts having admin owner to bypass this VR (Regression ticket - 2407) har
            User oldOwner = oldOwnerUsers.get(oldA.OwnerId);

            if (oldOwner != null && oldOwner.Name != null) {
                String ownerName = oldOwner.Name.toLowerCase().trim();

                // strict contains check (you can refine further if needed)
                if (ownerName.contains('admin')) {
                    continue;
                }
            }

            // allow if user is the current (old) owner
            if (currentUserId == oldA.OwnerId) {
                continue;
            }
            //Adding new code to solbe the prod bug
            /*if (profName == 'System Administrator' || profName == 'Sales Operations') {
                continue;
            }*/

            if (isAdminOrSalesOps) {
                continue;
            }

            if (a.ParentId == null
                && parentToChildOwners.containsKey(a.Id)
                && parentToChildOwners.get(a.Id).contains(currentUserId)) {
                continue;
            }

            // --- Bypass: Parent Account Owner can change child owner ---
            if (a.ParentId != null) {
                Account p = parentMap.get(a.ParentId);
                if (p != null && currentUserId == p.OwnerId) {
                    continue;
                }
            }

            // if old owner is not a User (queue), block (unless you want queue logic)
            if (!String.valueOf(oldA.OwnerId).startsWith('005')) {
                a.addError('Only the current Account Owner or their Managers can change the Account Owner.');
                continue;
            }

            //User oldOwner = oldOwnerUsers.get(oldA.OwnerId);

            // if we can’t evaluate role chain, block
            if (currentUserRoleId == null || oldOwner == null || oldOwner.UserRoleId == null) {
                a.addError('Only the current Account Owner or their Managers can change the Account Owner.');
                continue;
            }

            // allow if current user is in old owner’s management chain
            if (!isManagerInRoleChain(currentUserRoleId, oldOwner.UserRoleId, roleToParent)) {
                a.addError('Only the current Account Owner or their Managers can change the Account Owner.');
            }
        }
    }
}


    // role -> parentRole map (unlimited depth, bulk-safe)
    private static Map<Id, Id> buildRoleParentMap(Set<Id> startingRoleIds) {
        Map<Id, Id> roleToParent = new Map<Id, Id>();
        if (startingRoleIds == null || startingRoleIds.isEmpty()) return roleToParent;

        Set<Id> toQuery = new Set<Id>(startingRoleIds);

        while (!toQuery.isEmpty()) {
            toQuery.removeAll(roleToParent.keySet());
            if (toQuery.isEmpty()) break;

            Map<Id, UserRole> roles = new Map<Id, UserRole>([
                SELECT Id, ParentRoleId
                FROM UserRole
                WHERE Id IN :toQuery
            ]);

            Set<Id> next = new Set<Id>();
            for (UserRole r : roles.values()) {
                roleToParent.put(r.Id, r.ParentRoleId);
                if (r.ParentRoleId != null && !roleToParent.containsKey(r.ParentRoleId)) {
                    next.add(r.ParentRoleId);
                }
            }
            toQuery = next;
        }

        return roleToParent;
    }

    // true if managerRoleId is an ancestor of employeeRoleId
    private static Boolean isManagerInRoleChain(Id managerRoleId, Id employeeRoleId, Map<Id, Id> roleToParent) {
        if (managerRoleId == null || employeeRoleId == null) return false;

        Id cursor = employeeRoleId;
        Integer safety = 0;

        while (cursor != null && safety < 50) {
            Id parent = roleToParent.get(cursor);
            if (parent == managerRoleId) return true;
            cursor = parent;
            safety++;
        }
        return false;
    }
    // code ends

    //Code for insert
    public static void validateHierarchyOwnerOnInsert(List<Account> newList) {
    if (newList == null || newList.isEmpty()) return;

    Set<Id> parentIds = new Set<Id>();
    for (Account a : newList) {
        if (a.ParentId != null) {
            parentIds.add(a.ParentId);
        }
    }

    if (parentIds.isEmpty()) return;

    Map<Id, Account> parentMap = new Map<Id, Account>([
        SELECT Id, OwnerId
        FROM Account
        WHERE Id IN :parentIds
    ]);

    for (Account a : newList) {
        if (a.ParentId == null) continue;

        Account p = parentMap.get(a.ParentId);
        if (p != null && a.OwnerId != p.OwnerId) {
            a.addError('Child Account Owner must match the Parent Account Owner before adding it to the hierarchy.');
        }
    }
}

    //Code for insert ends
    /**
* @param accountIds
* @description Method to replace WF WFER01_Account_RT_Merchant
*/
    public static void manageRTMerchant(List<Account> accountIds) {
        for (Account acc : accountIds) {
            if (!acc.ER_SmartER_Context__c && acc.ER_Lead_Source_Type__c == 'Merchant') {
                acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('ER_Company_Account_RT')
                    .getRecordTypeId();
                acc.ER_Status__c = 'Prospect';
            }
        }
    }
    
    /**
* @author ALK
* @date 02/06/2021
* @description Sync Accounts with EDG v3
* @param newAccounts
*/
    public static void syncAccounts(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
    /* Set<Id> accounts = new Set<Id>();
        Set<Id> contractID = new Set<Id>();
        
        if (!newAccounts.isEmpty())
            APER30_AutoEnrollment_Management.syncRecordBU = newAccounts[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
        Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
        Map<Id, String> accountsInputScope = new Map<Id, String>();
        System.debug('### Account after update isOffline : ' + isOfflineBU);
        System.debug('### Account after update alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync);
        
        if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
            for (Account a : newAccounts) {
                if (
                    !a.ER_SmartER_Context__c &&
                    a.ER_Creation_date_in_OS__c != null &&
                    (a.ER_Last_date_of_Sync__c == oldAccounts.get(a.Id).ER_Last_date_of_Sync__c)
                )
                    accounts.add(a.Id);
            }
            
            //if(!accounts.isEmpty()) ER_SyncStructureWithLegacy.syncContract(accounts, null, 'PUT');
            if (!accounts.isEmpty())
                System.enqueueJob(new ER_SyncStructureWS(accounts, contractID, 'PUT', accounts, accountsInputScope));
    } */
    }
    
    /**
* @author KHAD
* @date 00/06/2021
* @description Update the creation date in ios field for account v3
* @param newItems
* @param oldItems
*/
    public static void syncAccountFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug('### syncAccountFlags Start');
        Map<Id, Account> newAccountMap = (Map<Id, Account>) newItems;
        Map<Id, Account> oldAccountMap = (Map<Id, Account>) oldItems;
        
        // Loop through the Account lists and add fill the creation date in OS
        for (Account acc : newAccountMap.values()) {
            if (
                !acc.ER_SmartER_Context__c &&
                acc.ER_Sync_result__c != oldAccountMap.get(acc.Id).ER_Sync_result__c &&
                (acc.ER_Sync_result__c == 'synchronized' ||
                 acc.ER_Sync_result__c == 'pending_synchronization') &&
                acc.ER_Creation_date_in_OS__c == null
            ) {
                acc.ER_Creation_date_in_OS__c = Datetime.now();
            }
        }
        System.debug('### syncAccountFlags End');
    }
    
    /**
* @author AAZ
* @date 25/06/2021
* @description update Zuora Customer Account after an update in SF
* @param newAccounts
* @param oldAccounts
*/
    public static void updateZuoraBillingAccount(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Map<Id, Account> accountsMap = new Map<Id, Account>(newAccounts);
        List<String> changedFields = new List<String>();
        List<Zuora__CustomerAccount__c> listBAToSync = new List<Zuora__CustomerAccount__c>();
        
        for (Account newAcc : [
            SELECT
            Id,
            ER_Business_Unit__c,
            ER_Legal_Name__c,
            ER_VAT_Number__c,
            BillingStreet,
            BillingCity,
            BillingPostalCode,
            BillingState,
            BillingCountry,
            ER_Country_Code__c,
            ER_BUPicklist__c,
            ER_Not_subject_to_VAT__c,
            (
                SELECT
                Id,
                Zuora__Zuora_Id__c,
                Zuora__AccountNumber__c,
                Zuora__Account__r.Name,
                Zuora__Account__r.ER_Legal_Name__c,
                Zuora__Account__r.ER_Business_Unit__c,
                Zuora__Account__r.ER_VAT_Number__c,
                ER_Financial_Center__r.ER_Bank_Account__r.ER_IBAN__c,
                ER_Financial_Center__r.ER_Type__c,
                Zuora__Account__r.BillingStreet,
                Zuora__Account__r.BillingCity,
                Zuora__Account__r.BillingPostalCode,
                Zuora__Account__r.BillingState,
                Zuora__Account__r.BillingCountry,
                Zuora__Account__r.ER_Country_Code__c,
                ER_Financial_Center__r.ER_SmartER_Context__c,
                Zuora__Account__r.ER_BUPicklist__c,
                Zuora__Account__r.ER_Not_subject_to_VAT__c
                FROM Zuora__R00N40000001kyLcEAI__r
            )
            FROM Account
            WHERE Id IN :accountsMap.keySet()
        ]) {
            changedFields = Utils.splitValues(
                Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ACCOUNT_CHANGEDFIELDS + newAcc.ER_Business_Unit__c)
            );
            Account oldAcc = oldAccounts.get(newAcc.Id);
            
            for (String fld : changedFields) {
                if (!newAcc.Zuora__R00N40000001kyLcEAI__r.isEmpty() && newAcc.get(fld) != oldAcc.get(fld)) {
                    listBAToSync.addAll(newAcc.Zuora__R00N40000001kyLcEAI__r);
                    break;
                }
            }
        }
        
        if (!listBAToSync.isEmpty())
            System.enqueueJob(new ER_CreateZuoraBillingAccount(null, listBAToSync));
    }
    
    /**
* @author VJO
* @description Generate Lead from an aggregator
* @param aggMerchants
*/
    public static void processAggregatorAccounts(List<Account> aggMerchants) {
        //Check if they have merchants
        //Map<Id, Account> mapAggregatorMerchant = new Map<Id, Account>(aggMerchants);
        Map<Id, List<Id>> mapEdenredMerchantAggMerchant = new Map<Id, List<Id>>();
        Map<Id, List<String>> mapAggMerchantActiveSolution = new Map<Id, List<String>>();
        Map<String, Id> mapProducts = new Map<String, Id>();
        List<String> activeSolutions = new List<String>();
        Id companyRTId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);
        
        //Get All Merchant linked to Agg Merchant via Account Partners
        for (AccountPartner a : [
            SELECT Id, AccountFromId, AccountToId, Role
            FROM AccountPartner
            WHERE AccountFromId IN :aggMerchants AND Role = :Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR
        ]) {
            if (!mapEdenredMerchantAggMerchant.containsKey(a.AccountToId))
                mapEdenredMerchantAggMerchant.put(a.AccountToId, new List<Id>());
            mapEdenredMerchantAggMerchant.get(a.AccountToId).add(a.AccountFromId);
        }
        System.debug('>>>>> ALK - mapEdenredMerchantAggMerchant : ' + mapEdenredMerchantAggMerchant);
        
        // Get Active Solution from Merchant linked to Agg Merchant
        for (Account a : [
            SELECT
            Id,
            (
                SELECT Id, ER_Solution__r.ProductCode
                FROM Solution_Line_Items__r
                WHERE ER_Global_Status__c = :Constants.ACTIVE
            )
            FROM Account
            WHERE RecordTypeId = :companyRTId AND Id IN :mapEdenredMerchantAggMerchant.keySet()
        ]) {
            for (Id aggMerchantId : mapEdenredMerchantAggMerchant.get(a.Id)) {
                if (!mapAggMerchantActiveSolution.containsKey(aggMerchantId))
                    mapAggMerchantActiveSolution.put(aggMerchantId, new List<String>());
                for (ER_Solution_Line_Item__c s : a.Solution_Line_Items__r)
                    mapAggMerchantActiveSolution.get(aggMerchantId).add(s.ER_Solution__r.ProductCode);
            }
        }
        System.debug('>>>>> ALK - mapAggMerchantActiveSolution : ' + mapAggMerchantActiveSolution);
        
        //Prepare leads to be created
        Set<String> setSolutionToBeUsed = new Set<String>();
        List<Lead> leads = new List<Lead>();
        
        for (Account a : aggMerchants) {
            List<String> solutions = a.Description?.split(Constants.SEMICOLON);
            if (solutions != null && !solutions.isEmpty())
                setSolutionToBeUsed.addAll(solutions);
        }
        System.debug('>>>>> ALK - setSolutionToBeUsed : ' + setSolutionToBeUsed);
        
        for (Product2 p : [
            SELECT Id, BU_External_Reference__c, ProductCode
            FROM Product2
            WHERE ProductCode IN :setSolutionToBeUsed AND ER_Type__c = :Constants.SOLUTION
        ]) {
            mapProducts.put(p.ProductCode, p.Id);
        }
        System.debug('>>>>> ALK - mapProducts : ' + mapProducts);
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        for (Account a : aggMerchants) {
            if (a.Description == null)
                continue;
            for (String s : a.Description?.split(Constants.SEMICOLON)) {
                System.debug('>>>>> ALK - a.Id : ' + a.Id);
                if (mapAggMerchantActiveSolution.containsKey(a.Id))
                    activeSolutions = mapAggMerchantActiveSolution.get(a.Id);
                System.debug('>>>>> ALK - activeSolutions : ' + activeSolutions);
                if (activeSolutions.isEmpty() || (!activeSolutions.isEmpty() && !activeSolutions.contains(s))) {
                    Lead l = new Lead();
                    l.FirstName = Constants.PARTNER_ROLE_AGGREGATOR;
                    l.LastName = ((a.Name + ' - ' + s).length() < 80
                                  ? a.Name + ' - ' + s
                                  : (a.Name + ' - ' + s).substring(0, 80));
                    l.City = a.BillingCity;
                    l.Country = a.BillingCountry;
                    l.PostalCode = a.BillingPostalCode;
                    l.State = a.BillingState;
                    l.Street = a.BillingStreet;
                    l.ER_Lead_Type__c = Label.LAB_SF_Lead_Type_Merchant;
                    l.LeadSource = Constants.PARTNER_ROLE_AGGREGATOR;
                    l.Company = ((Constants.PARTNER_ROLE_AGGREGATOR + ' - ' + a.Name + ' - ' + s).length() < 255
                                 ? Constants.PARTNER_ROLE_AGGREGATOR + ' - ' + a.Name + ' - ' + s
                                 : (Constants.PARTNER_ROLE_AGGREGATOR + ' - ' + a.Name + ' - ' + s).substring(0, 255));
                    l.ER_Registration_Number__c = a.ER_Registration_Number__c;
                    l.ER_VAT_Number__c = a.ER_VAT_Number__c;
                    l.ER_BUPicklist__c = a.ER_BUPicklist__c;
                    System.debug(
                        '>>>>> ALK - lead ER_BUPicklist__c : ' +
                        l.ER_BUPicklist__c +
                        ' - a.ER_BUPicklist__c : ' +
                        a.ER_BUPicklist__c
                    );
                    l.ER_Not_Subject_to_VAT__c = (String.isNotBlank(a.ER_VAT_Number__c) ? false : true);
                    System.debug('>>>>> ALK - mapProducts.get(' + s + ') : ' + mapProducts.get(s));
                    l.ERBE_Initial_Product_Of_Interest__c = mapProducts.get(s);
                    // COUL3020  Apply lead assignment rules when creating leads
                    l.setOptions(dmo);
                    leads.add(l);
                }
            }
        }
        
        if (!leads.isEmpty())
            Database.insert(leads, false);
    }
    
    /**
* @author Noor
* @date 11/10/2021
* @description update shipping address with billing address
* @param newAccounts
* @param oldAccounts
*/
    public static void updateShippingAddress(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            System.debug(
                '//NGO updateShippingAddress ER_Match_Legal_Address__c : ' +
                acc.Name +
                ' -' +
                acc.ER_Match_Legal_Address__c
            );
            if (!acc.ER_SmartER_Context__c && acc.ER_Match_Legal_Address__c) {
                acc.ShippingStreet = acc.BillingStreet;
                acc.ShippingPostalCode = acc.BillingPostalCode;
                acc.ShippingCity = acc.BillingCity;
                acc.ShippingCountry = acc.BillingCountry;
                //back to false
                acc.ER_Match_Legal_Address__c = false;
            }
        }
    }
    
    /**
* @author Noor
* @date 11/10/2021
* @description check if the address changed and the field Account address sync is flaged, if so update all contact (linked to the account) addresses
* @param newAccounts
* @param oldAccounts
*/
    public static void syncAddressToContacts(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Map<Id, Account> syncAddressToContacts = new Map<Id, Account>();
        for (Account acc : newAccounts) {
            if (isBillingAddressChanged(acc, oldAccounts.get(acc.Id)))
                syncAddressToContacts.put(acc.id, acc);
        }
        
        if (!syncAddressToContacts.isEmpty())
            APER17_Contact_Management.syncAddressFromAccount(syncAddressToContacts);
    }
    
    public static Boolean isBillingAddressChanged(Account acc, Account oldAccount) {
        return acc.BillingStreet != oldAccount.BillingStreet ||
            acc.BillingPostalCode != oldAccount.BillingPostalCode ||
            acc.BillingCity != oldAccount.BillingCity ||
            acc.BillingCountry != oldAccount.BillingCountry ||
            acc.ER_Country_Code__c != oldAccount.ER_Country_Code__c;
    }
    
    /**
* @author AAZ
* @date 29/11/2021
* @description Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
* @param newItems
*/
    public static void updateLastModifiedDateFunctionalUser(List<Account> newItems) {
        ER_Validation_Rules_Settings__c profileSetting = ER_Validation_Rules_Settings__c.getInstance(
            UserInfo.getProfileId()
        );
        ER_Validation_Rules_Settings__c userSetting = ER_Validation_Rules_Settings__c.getInstance(UserInfo.getUserId());
        
        for (Account a : newItems) {
            if (
                !profileSetting.ER_Last_Modified_Date_Functional_User__c &&
                !userSetting.ER_Last_Modified_Date_Functional_User__c
            )
                a.ER_Last_Modified_Date_Functional_User__c = Datetime.now();
        }
    }
    
    /**
* @author ALK
* @date 07/02/2022
* @description Send Medallia invitation when first visit
* @param accounts
* @param oldMap
* @see APER37_MedalliaProcess
*/
    /*public static void sendInvitationWhenFirstVisitChanged(List<Account> accounts, Map<Id, Account> oldMap) {
List<Account> accountToBeSent = new List<Account>();
for(Account a :accounts) {
if(a.ER_First_visit__c != oldMap.get(a.Id).ER_First_visit__c) accountToBeSent.add(a);
}

if(!accountToBeSent.isEmpty()) {APER37_MedalliaProcess.sendInvitationWhenFirstVisitChanged(accountToBeSent);}
}*/
    
    /**
* @author ALK
* @date 07/06/2022
* @description Medallia - populate Individual Invitation Trigger Date
* @param items
*/
    /*public static void populateIndividualInvitationTriggerDate(List<Account> items) {
List<String> medalliaDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_DEPLOYED_BUS)
?.split(Constants.SEMICOLON);
for (Account a : items) {
if (
a.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_INDVIDUAL_RT) &&
(medalliaDeployedBUs != null &&
(medalliaDeployedBUs.contains(a.ER_BUPicklist__c) || medalliaDeployedBUs.contains(Constants.ALL)))
) {
a.ER_Medallia_Invitation_Trigger_Date__c = (String.isBlank(a.ER_Medallia_Invitation_Trigger_Date__c)
? (Date.today().addMonths(6).day() < 10
? '0' + Date.today().addMonths(6).day()
: String.valueOf(Date.today().addMonths(6).day())) +
'/' +
(Date.today().addMonths(6).month() < 10
? '0' + Date.today().addMonths(6).month()
: String.valueOf(Date.today().addMonths(6).month()))
: a.ER_Medallia_Invitation_Trigger_Date__c);
a.ER_Medallia_Invitation_Week_Number__c = (a.ER_Medallia_Invitation_Week_Number__c == null
? Utils.getWeekNumber(Date.today().addMonths(6))
: a.ER_Medallia_Invitation_Week_Number__c);
}
}
}*/
    
    /**
* @author AAZ
* @date 28/06/2022
* @description SmartER Set SmartER context on the contact
* @param newItems
*/
    public static void setAccountAsSmartERContext(List<Account> newItems) {
        List<String> smartERDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
            ?.split(Constants.SEMICOLON);
        Id companyRTId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);
        
        for (Account a : newItems) {
            if (
                smartERDeployedBUs != null &&
                a.RecordTypeId == companyRTId &&
                (smartERDeployedBUs.contains(a.ER_BUPicklist__c) || smartERDeployedBUs.contains(Constants.ALL)) &&
                !a.ER_SmartER_Context__c
            ) {
        a.ER_SmartER_Context__c = false;
            }
        }
    }
    
    /**
* @author AAZ
* @date 08/12/2022
* @description set the customer number sequence
* @param accounts
*/
    public static void setLastCustomerNumberSequence(List<Account> accounts) {
        Id companyRTId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);
        List<Account> smarterERAccounts = new List<Account>();
        for (Account acc : accounts) {
            if (acc.RecordTypeId == companyRTId && acc.ER_SmartER_Context__c == true)
                smarterERAccounts.add(acc);
        }
        
        if (!smarterERAccounts.isEmpty()) {
            String lastSequence = Utils.getLastCustomerNumberSequence();
            for (Integer i = 1; i <= smarterERAccounts.size(); i++) {
                Account a = smarterERAccounts[i - 1];
                Integer currentSequence = Integer.valueOf(lastSequence) + i;
                if (String.isBlank(a.ER_Customer_Number__c))
                    a.ER_Customer_Number__c = String.valueOf(currentSequence).leftPad(8, '0');
            }
        }
    }
    
    /**
* @author KHAD
* @date 15/02/2022
* @description Sync contacts and financial centers when the account smarterRef is filled
* @param newItems
* @param oldAccounts
*/
    public static void syncSmarterContactsAndFinancialCenters(List<Account> newItems, Map<Id, Account> oldAccounts) {
        Set<Id> smartERAccounts = new Set<Id>();
        
        for (Account acc : newItems) {
            if (
                acc.ER_SmartER_Context__c &&
                acc.SmartER_Customer_Id__c != null &&
                acc.SmartER_Customer_Id__c != oldAccounts.get(acc.Id).SmartER_Customer_Id__c
            ) {
                smartERAccounts.add(acc.Id);
            }
        }
        
        if (!smartERAccounts.isEmpty()) {
            List<Account> accounts = new List<Account>();
            for (Account acc : [
                SELECT
                Id,
                ER_SmartER_Context__c,
                SmartER_Customer_Id__c,
                (SELECT Id, Status FROM Contracts WHERE Status = :Constants.ACTIVATED)
                FROM Account
                WHERE Id IN :smartERAccounts
            ]) {
                if (!acc.Contracts.isEmpty())
                    accounts.add(acc);
            }
            
            if (!accounts.isEmpty()) {
                Map<Id, ER_Financial_Center__c> financialCentersToSyncWithSmarter = new Map<Id, ER_Financial_Center__c>(
                    [
                        SELECT Id
                        FROM ER_Financial_Center__c
                        WHERE
                        ER_Account_Name__c IN :accounts
                        AND ER_To_sync_with_smarter__c = TRUE
                        AND ER_SmartER_Context__c = TRUE
                        AND ER_BUPicklist__c != NULL
                    ]
                );
                
                if (!financialCentersToSyncWithSmarter.isEmpty())
                    APER30_FinancialCenter_Management.syncFinancialCenterToSmartER(financialCentersToSyncWithSmarter.keySet());
                
                Map<Id, Contact> contactsToSyncWithSmarter = new Map<Id, Contact>(
                    [
                        SELECT Id
                        FROM Contact
                        WHERE
                        AccountId IN :accounts
                        AND ER_To_sync_with_smarter__c = TRUE
                        AND ER_SmartER_Context__c = TRUE
                        AND ER_BUPicklist__c != NULL
                    ]
                );
                if (!contactsToSyncWithSmarter.isEmpty())
                    APER17_Contact_Management.publishContactsToBeSyncedWithSmarter(contactsToSyncWithSmarter.keySet());
            }
        }
    }
    
    /**
* @author Noor
* @date 21/03/2023
* @description Sync Account to Smarter when fields are updated
* @param newItems set of account Id
* @param oldAccounts set of account Id
*/
    public static void syncClientToSmarterWhenUpdate(List<Account> newItems, Map<Id, Account> oldAccounts) {
        Set<Id> accounts = new Set<Id>();
        for (Account a : newItems) {
            if (a.ER_SmartER_Context__c && isSmarterAccountFieldChanged(a, oldAccounts.get(a.Id)))
                accounts.add(a.Id);
        }
        
        if (!accounts.isEmpty())
            runSyncClientToSmarter(accounts);
    }
    
    /**
* @author Noor
* @date 21/03/2023
* @description Create event platform to sync account with Smarter
* @param accounts
*/
    public static void runSyncClientToSmarter(Set<Id> accountSet) {
        Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
        dte.Transaction_Name__c = Constants.RUN_SYNC_CLIENT_TO_SMARTER;
        dte.Transaction_Content__c = JSON.serializePretty(accountSet);
        EventBus.publish(dte);
    }
    
    /**
* @author Noor
* @date 21/03/2023
* @description Create event platform to sync account with Smarter
* @param accountIds set of account Id
*/
    @future(Callout=true)
    public static void syncClientToSmarter(Set<Id> accountIds) {
        Map<String, List<Map<String, Object>>> accountMap = retrieveAndConstructAccountToSync(accountIds);
        
        if (!accountMap.isEmpty() && Limits.getCallouts() < Limits.getLimitCallouts()) {
            Map<String, String> smarterAT = Utils.getSmarterAccessToken();
            if (
                smarterAT != null &&
                !smarterAT.isEmpty() &&
                smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
                smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
            ) {
                for (String key : accountMap.keySet()) {
                    String bu = key.split(Constants.SEMICOLON)[0];
                    String method = key.split(Constants.SEMICOLON)[1];
                    callSmarterClientWS(accountMap.get(key), bu, method, smarterAT);
                }
            }
        }
    }
    
    /**
* @author Noor
* @date 21/03/2023
* @description retrieve And Construct Account To Sync to smarter for the accountIds
*              Method is @future since it is called from triggers of a platform event
* @param accountIds set of account Ids
*
* @return list of account per BU and per Method to send
*/
    public static Map<String, List<Map<String, Object>>> retrieveAndConstructAccountToSync(Set<Id> accountIds) {
        Map<String, Object> mapData = new Map<String, Object>();
        Map<String, List<Map<String, Object>>> accountMap = new Map<String, List<Map<String, Object>>>();
        
        List<Account> accounts = [
            SELECT
            Id,
            ER_BUPicklist__c,
            Name,
            ER_Legal_Name__c,
            ER_Registration_Number__c,
            BillingStreet,
            SmartER_Customer_Id__c,
            BillingCity,
            BillingPostalCode,
            BillingCountry,
            ER_Country_Code__c,
            ER_SmartER_Original_Lead_Id__c,
            ER_SmartER_Context__c,
            ER_Customer_Number__c,
            ER_Smarter_1st_Sync_Date__c,
            ER_Smarter_Last_Sync_Date__c,
            ER_Smarter_Sync_Status__c
            FROM Account
            WHERE Id IN :accountIds
        ];
        
        if (!accounts.isEmpty()) {
            for (Account a : accounts) {
                if (a.ER_SmartER_Context__c && String.isNotBlank(a.ER_BUPicklist__c)) {
                    String key = a.ER_BUPicklist__c + Constants.SEMICOLON + getAccountStateForSmarter(a);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_ID, a.Id);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_OPP_ID, a.Id);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_NAME, a.Name);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_LEGAL_NAME, a.ER_Legal_Name__c);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_COMPANY_REGISTRATION_NUM, a.ER_Registration_Number__c);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_STREET, a.BillingStreet);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_CITY, a.BillingCity);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_ZIP_CODE, a.BillingPostalCode);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_COUNTRY, a.BillingCountry);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_COUNTRY_CODE, a.ER_Country_Code__c);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_ORIGINAL_LEAD_ID, a.ER_SmartER_Original_Lead_Id__c);
                    mapData.put(Constants.SMARTER_ACCOUNT_REF_CUSTOMER_NUMBER, a.ER_Customer_Number__c);
                    if (accountMap.containsKey(key))
                        accountMap.get(key).add(mapData);
                    else
                        accountMap.put(key, new List<Map<String, Object>>{ mapData });
                }
            }
        }
        return accountMap;
    }
    
    /**
* @author Noor
* @date 21/03/2023
* @description call webservice by bu and by method (post or patch)
* @param accountMap
* @param bu business unit
* @param method webservice method
* @param smarterAT credential to connect to Webservice
*/
    public static void callSmarterClientWS(
        List<Map<String, Object>> accountMap,
        String bu,
        String method,
        Map<String, String> smarterAT
    ) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        
        req.setEndpoint(
            'callout:' +
            Constants.SMARTER_NAMED_CREDENTIAL +
            Constants.SLASH +
            Constants.SMARTER_ACCOUNT_REF_VERSION +
            Constants.SLASH +
            Constants.SMARTER_ACCOUNT_REF_SERVICE_NAME
        );
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('X-Tenant', bu);
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        req.setHeader(
            'Authorization',
            smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
            ' ' +
            smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
        );
        
        String payload = JSON.serialize(accountMap);
        
        req.setBody(payload);
        resp = http.send(req);
        List<Account> accountToUpdate = new List<Account>();
        if (resp.getStatusCode() == 204 || resp.getStatusCode() == 200) {
            System.debug('//NGO - Success resp.getStatusCode(): ' + resp.getBody());
            for (Map<String, Object> dataMap : accountMap) {
                Id accountId = (Id) dataMap.get(Constants.SMARTER_ACCOUNT_REF_ID);
                if (method.equals(Constants.POST_METHOD))
                    accountToUpdate.add(
                        new Account(
                            Id = accountId,
                            ER_Smarter_1st_Sync_Date__c = DateTime.now(),
                            ER_Smarter_Last_Sync_Date__c = DateTime.now(),
                            ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_SYNCED
                        )
                    );
                if (method.equals(Constants.PATCH_METHOD))
                    accountToUpdate.add(
                        new Account(
                            Id = accountId,
                            ER_Smarter_Last_Sync_Date__c = Date.today(),
                            ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_SYNCED
                        )
                    );
            }
        } else {
            System.debug('//NGO - Failed response : ' + resp.getBody());
            for (Map<String, Object> dataMap : accountMap) {
                Id accountId = (Id) dataMap.get(Constants.SMARTER_ACCOUNT_REF_ID);
                
                if (method.equals(Constants.POST_METHOD))
                    accountToUpdate.add(
                        new Account(
                            Id = accountId,
                            ER_Smarter_Last_Sync_Date__c = DateTime.now(),
                            ER_Smarter_Sync_Error__c = getMessageError(resp.getBody()),
                            ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_NOT_SYNCED
                        )
                    );
                if (method.equals(Constants.PATCH_METHOD))
                    accountToUpdate.add(
                        new Account(
                            Id = accountId,
                            ER_Smarter_Last_Sync_Date__c = DateTime.now(),
                            ER_Smarter_Sync_Error__c = getMessageError(resp.getBody()),
                            ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_NOT_SYNCED
                        )
                    );
            }
        }
        if (!accountToUpdate.isEmpty())
            update accountToUpdate;
    }
    
    /**
* @date 21/03/2023
* @author Noor
* @description retrieve error message from response
* @param response
*
* @return
*/
    public static String getMessageError(String response) {
        try {
            Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(response);
            Map<String, Object> dataMeta = (Map<String, Object>) (mapRespData.get('meta'));
            if (dataMeta.get('status').equals('failed')) {
                List<Object> messages = (List<Object>) dataMeta.get('messages');
                if (!messages.isEmpty()) {
                    Map<String, Object> messageMap = (Map<String, Object>) messages[0];
                    return (String) messageMap.get('text');
                }
            }
        } catch (Exception e) {
            System.debug('//callSmarterClientWS parsing error ' + e.getMessage());
        }
        return '';
    }
    
    /**
* @author Noor
* @description check if any of the specified fields have changed
* @param newItem the updated Account record
* @param oldItem the original Account record before the update.
*
* @return
*/
    public static boolean isSmarterAccountFieldChanged(Account newItem, Account oldItem) {
        List<String> fieldNames = new List<String>{
            'Id',
                'Name',
                'ER_Legal_Name__c',
                'ER_Registration_Number__c',
                'BillingStreet',
                'BillingCity',
                'BillingPostalCode',
                'BillingCountry',
                'ER_Country_Code__c',
                'ER_SmartER_Original_Lead_Id__c',
                'ER_Customer_Number__c'
                };
                    for (String fieldName : fieldNames) {
                        if (newItem.get(fieldName) != oldItem.get(fieldName))
                            return true;
                    }
        return false;
    }
    /**
* @author Noor
* @description Get the method type to be used base on the account fields state
* @param a account
*
* @return the method to use in Webservice either post or patch
*/
    public static String getAccountStateForSmarter(Account a) {
        if (a.ER_Smarter_1st_Sync_Date__c == null && a.SmartER_Customer_Id__c == null)
            return Constants.POST_METHOD;
        else if (a.ER_Smarter_1st_Sync_Date__c != null && a.SmartER_Customer_Id__c == null)
            return Constants.POST_METHOD;
        else if (a.ER_Smarter_1st_Sync_Date__c == null && a.SmartER_Customer_Id__c != null)
            return Constants.PATCH_METHOD;
        else if (a.ER_Smarter_1st_Sync_Date__c != null && a.SmartER_Customer_Id__c != null)
            return Constants.PATCH_METHOD;
        else
            return Constants.PATCH_METHOD;
    }
    
    /**
* @author AAZ
* @date 20/03/2023
* @description Sync offline TCs to smarter
* @param newItems
* @param oldItems
*/
    public static void syncOfflineTCs(List<Account> newItems, Map<Id, Account> oldItems) {
        Set<Id> contracts = new Set<Id>();
        for (Account a : [
            SELECT
            Id,
            ER_SmartER_Context__c,
            SmartER_Customer_Id__c,
            (SELECT Id, ER_Customer_Signed_Version__c FROM Contracts WHERE Status = :Constants.ACTIVATED)
            FROM Account
            WHERE Id IN :newItems
        ]) {
            if (
                a.ER_SmartER_Context__c &&
                !a.Contracts.isEmpty() &&
                a.SmartER_Customer_Id__c != null &&
                oldItems.get(a.Id).SmartER_Customer_Id__c == null &&
                a.SmartER_Customer_Id__c != oldItems.get(a.Id).SmartER_Customer_Id__c
            ) {
                for (Contract c : a.Contracts) {
                    if (c.ER_Customer_Signed_Version__c != null)
                        contracts.add(c.Id);
                }
            }
        }
        
        if (!contracts.isEmpty()) {
            Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
            dte.Transaction_Name__c = Constants.RUN_SYNC_OFFLINE_TCS;
            System.debug('>>>>> AAZ- JSON.serializePretty(contracts) length : ' + JSON.serializePretty(contracts).length());
            dte.Transaction_Content__c = JSON.serializePretty(contracts);
            EventBus.publish(dte);
        }
    }
    
    /**
* @author AAZ
* @date 20/03/2023
* @description Sync offline TCs to smarter Callout
* @param contracts
*/
    @Future(Callout=true)
    public static void syncOfflineTcsToSmarter(Set<Id> contracts) {
        System.debug('>>>>> AAZ- pass in syncOfflineTcsToSmarter');
        
        Map<String, Object> mapRequest = new Map<String, Object>();
        Map<String, List<Object>> mapBUPayload = new Map<String, List<Object>>();
        
        for (Contract c : [
            SELECT
            Id,
            AccountId,
            ER_BUPicklist__c,
            ER_Customer_Signed_Version__c,
            ER_TCs_Signed_Link__c,
            ER_Agreement_DateTime__c,
            ER_ZuoraQuote__r.zqu__BillToContact__r.ER_Language__c
            FROM Contract
            WHERE Id IN :contracts AND Status = :Constants.ACTIVATED
        ]) {
            if (!mapBUPayload.containsKey(c.ER_BUPicklist__c))
                mapBUPayload.put(c.ER_BUPicklist__c, new List<Object>());
            mapRequest.put('accountOneforceId', c.AccountId);
            mapRequest.put('contractOneforceId', c.Id);
            mapRequest.put('version', c.ER_Customer_Signed_Version__c);
            mapRequest.put('fileUrl', c.ER_TCs_Signed_Link__c);
            mapRequest.put('agreementDateTime', c.ER_Agreement_DateTime__c);
            mapRequest.put('language', c.ER_ZuoraQuote__r.zqu__BillToContact__r.ER_Language__c);
            mapBUPayload.get(c.ER_BUPicklist__c).add(mapRequest);
        }
        
        if (!mapBUPayload.isEmpty()) {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse resp = new HttpResponse();
            
            Map<String, String> smarterAT = Utils.getSmarterAccessToken();
            if (smarterAT != null && !smarterAT.isEmpty()) {
                String tokenType = smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE);
                String accessToken = smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN);
                if (tokenType != null && accessToken != null) {
                    for (String bu : mapBUPayload.keySet()) {
                        req.setEndpoint(
                            'callout:' +
                            Constants.SMARTER_NAMED_CREDENTIAL +
                            Constants.SLASH +
                            Constants.SMARTER_OFFLINE_TCS_SERVICE_VERSION +
                            Constants.SLASH +
                            Constants.SMARTER_OFFLINE_TCS_SERVICE_NAME
                        );
                        req.setMethod(Constants.POST_METHOD);
                        req.setHeader('Content-Type', 'application/json');
                        req.setHeader('Accept', 'application/json');
                        req.setHeader('X-Tenant', bu);
                        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
                        req.setHeader('Authorization', tokenType + ' ' + accessToken);
                        
                        String payload = JSON.serialize(mapBUPayload.get(bu));
                        System.debug('>>>>> AAZ - payload : ' + payload);
                        req.setBody(payload);
                        resp = http.send(req);
                        
                        System.debug('>>>>> AAZ - resp.getStatusCode() : ' + resp.getStatusCode());
                        if (resp.getStatusCode() == 204) {
                            System.debug('>>>>> AAZ - Success resp.getStatusCode(): ' + resp.getStatusCode());
                            System.debug('>>>>> AAZ - Success resp.getBody(): ' + resp.getBody());
                        } else {
                            System.debug('>>>>> AAZ - Failed response : ' + resp.getBody());
                        }
                    }
                }
            }
        }
    }
    
    /**
* @author ALK
* @date 20/03/2023
* @description Update Smarter Sync fields (if empty) once we get the smarter customer Id
* @param newItems
* @param oldItems
*/
    public static void updateSmarterSyncFields(List<Account> newItems, Map<Id, Account> oldItems) {
        for (Account a : newItems) {
            if (
                a.ER_SmartER_Context__c &&
                String.isNotBlank(a.SmartER_Customer_Id__c) &&
                a.SmartER_Customer_Id__c != oldItems.get(a.Id).SmartER_Customer_Id__c &&
                oldItems.get(a.Id).SmartER_Customer_Id__c == null &&
                a.ER_Smarter_1st_Sync_Date__c == null
            ) {
                a.ER_Smarter_1st_Sync_Date__c = Datetime.now();
                a.ER_Smarter_Last_Sync_Date__c = Datetime.now();
                a.ER_Smarter_Sync_Status__c = Constants.SYNCHRONIZED_STATUS;
                a.ER_Smarter_Sync_Error__c = '';
            }
        }
    }
    
    /**
* @author AAZ
* @date 24/04/2023
* @description Default account fields
* @param accounts
*/
    public static void defaultAccountValues(List<Account> accounts) {
        Id companyRT = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);
        for (Account a : accounts) {
            if (a.RecordTypeId == companyRT && a.ER_SmartER_Context__c == true && a.ER_BUPicklist__c == 'FR')
                a.ER_Segment__c = Constants.SEGMENT_SME;
        }
    }
    
    /**
* @author AAZ
* @date 05/05/2023
* @description Mark Financial Center and Contact as synced when the parent account is updated with Customer Id
* ofr the online process
* @param newItems
* @param oldItems
*/
    public static void markFCandContactAsSynced(List<Account> newItems, Map<Id, Account> oldItems) {
        List<Account> selectedAccounts = new List<Account>();
        
        for (Account a : newItems) {
            if (
                a.ER_SmartER_Context__c &&
                String.isNotBlank(a.SmartER_Customer_Id__c) &&
                oldItems.get(a.Id).SmartER_Customer_Id__c == null &&
                a.SmartER_Customer_Id__c != oldItems.get(a.Id).SmartER_Customer_Id__c &&
                String.isNotBlank(a.ER_SmartER_Original_Lead_Id__c)
            ) {
                selectedAccounts.add(a);
            }
        }
        
        if (!selectedAccounts.isEmpty()) {
            Set<Id> leadsIds = new Set<Id>();
            List<Contact> contacts = new List<Contact>();
            List<ER_Financial_Center__c> fcs = new List<ER_Financial_Center__c>();
            Map<Id, User> mapIntegnUsers = new Map<Id, User>(
                [SELECT Id, Name, ProfileId FROM User WHERE Profile.Name = :Constants.PROFILE_ER_INTEGRATION]
            );
            
            for (Account acc : selectedAccounts) {
                if (mapIntegnUsers.containsKey(acc.CreatedById))
                    leadsIds.add(acc.ER_SmartER_Original_Lead_Id__c);
            }
            
            for (ER_Financial_Center__c fc : [
                SELECT Id, ER_Smarter_1st_Sync_Date__c, ER_Smarter_Last_Sync_Date__c, ER_Smarter_Sync_Status__c
                FROM ER_Financial_Center__c
                WHERE
                ER_SmartER_Original_Lead_Id__c IN :leadsIds
                AND ER_Smarter_1st_Sync_Date__c = NULL
                AND CreatedBy.Profile.Name = :Constants.PROFILE_ER_INTEGRATION
            ]) {
                fc.ER_Smarter_1st_Sync_Date__c = Datetime.now();
                fc.ER_Smarter_Last_Sync_Date__c = Datetime.now();
                fc.ER_Smarter_Sync_Status__c = Constants.SYNCHRONIZED_STATUS;
                fc.ER_Smarter_Sync_Error__c = '';
                fcs.add(fc);
            }
            
            for (Contact c : [
                SELECT Id, ER_Smarter_1st_Sync_Date__c, ER_Smarter_Last_Sync_Date__c, ER_Smarter_Sync_Status__c
                FROM Contact
                WHERE
                ER_SmartER_Original_Lead_Id__c IN :leadsIds
                AND ER_Smarter_1st_Sync_Date__c = NULL
                AND CreatedBy.Profile.Name = :Constants.PROFILE_ER_INTEGRATION
            ]) {
                c.ER_Smarter_1st_Sync_Date__c = Datetime.now();
                c.ER_Smarter_Last_Sync_Date__c = Datetime.now();
                c.ER_Smarter_Sync_Status__c = Constants.SYNCHRONIZED_STATUS;
                c.ER_Smarter_Sync_Error__c = '';
                contacts.add(c);
            }
            
            if (!fcs.isEmpty())
                Database.update(fcs, false);
            if (!contacts.isEmpty())
                Database.update(contacts, false);
        }
    }
    
    /**
* @author Noor
* @date 07/07/2023
* @description update field ER_Client_Priority__c based on field ER_RFM_Client_Persona__c, mapping is defined in
*              custom metadata ACCOUNT_GR_RFM_CLIENT_PRIORITY_MAPPING
* @param newItems
* @param oldItems only for before update for before insert its is null
*/
    public static void updateClientPriority(List<Account> newItems, Map<Id, Account> oldItems) {
        List<String> rfmSettings = Utils.splitValues(
            Utils.getGlobalSettingsValueFromKey('ACCOUNT_GR_RFM_CLIENT_PRIORITY_MAPPING')
        );
        Map<String, String> rfmPriorityMap = Utils.splitKeyPairValues(rfmSettings, Constants.COLON);
        //Add null to represent the default as the value is blank from the custom metadata
        rfmPriorityMap.put(null, rfmPriorityMap.get(''));
        for (Account a : newItems) {
            if (
                a.ER_BUPicklist__c != null &&
                a.ER_BUPicklist__c.equalsIgnoreCase(Constants.GR) &&
                rfmPriorityMap.containsKey(a.ER_RFM_Client_Persona__c) &&
                (String.isBlank(a.ER_Client_Priority__c) ||
                 (oldItems != null &&
                  a.ER_RFM_Client_Persona__c != oldItems.get(a.Id).ER_RFM_Client_Persona__c))
            )
                a.ER_Client_Priority__c = rfmPriorityMap.get(a.ER_RFM_Client_Persona__c);
        }
    }
    
    /**
* @author ALK
* @date 27/07/2023
* @description [Smarter] Override the account Source and Subsource by the ones coming from the lead conversion
* @param accounts
* @param oldMap
*/
    public static void updateAccountSource(List<Account> accounts, Map<Id, Account> oldMap) {
        List<String> smarterBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
            ?.split(Constants.SEMICOLON);
        
        Map<Id, Account> updatedAccounts = new Map<Id, Account>();
        for (Account a : accounts) {
            if (
                String.isEmpty(oldMap.get(a.Id).ER_Account_SubSource__c) &&
                a.ER_Account_SubSource__c != oldMap.get(a.Id).ER_Account_SubSource__c &&
                (a.ER_SmartER_Context__c ||
                 (smarterBUs != null && (smarterBUs.contains(a.ER_BUPicklist__c) || smarterBUs.contains(Constants.ALL))))
            )
                updatedAccounts.put(a.Id, a);
        }
        
        if (!updatedAccounts.isEmpty()) {
            for (Lead l : [
                SELECT Id, LeadSource, ER_Lead_sub_source__c, ConvertedAccountId
                FROM Lead
                WHERE ConvertedAccountId IN :updatedAccounts.keySet()
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ]) {
                updatedAccounts.get(l.ConvertedAccountId).AccountSource = l.LeadSource;
                updatedAccounts.get(l.ConvertedAccountId).ER_Account_SubSource__c = l.ER_Lead_sub_source__c;
            }
        }
    }
    
    
    /**
* @author Snehil Verma
* @date 14/11/2024
* @description Sync account and contact in NEMO when account is updated
* @param newItems
* @param oldAccounts
*/
    /*public static void syncAccountUpdateInNEMO(List<Account> accounts, Map<Id, Account> oldMap) {
Set<Id> accIdSet = new Set<Id>();
for(Account accObj : accounts){
if((oldMap.get(accObj.Id).Name != accObj.Name || oldMap.get(accObj.Id).ER_Legal_Name__c != accObj.ER_Legal_Name__c || oldMap.get(accObj.Id).ER_Registration_Number__c != accObj.ER_Registration_Number__c || oldMap.get(accObj.Id).ER_VAT_Number__c != accObj.ER_VAT_Number__c || oldMap.get(accObj.Id).ER_Not_subject_to_VAT__c != accObj.ER_Not_subject_to_VAT__c || oldMap.get(accObj.Id).HU_HQ_Contact__c != accObj.HU_HQ_Contact__c || oldMap.get(accObj.Id).BillingStreet != accObj.BillingStreet || oldMap.get(accObj.Id).BillingPostalCode != accObj.BillingPostalCode || oldMap.get(accObj.Id).BillingCity != accObj.BillingCity || oldMap.get(accObj.Id).BillingCountry != accObj.BillingCountry) && accObj.ER_Card_Client_Operational_System_ID__c != null){
accIdSet.add(accObj.Id);
}
}

if(!accIdSet.isEmpty()){
System.enqueueJob(new UpdateClientQueueable(new List<Id>(accIdSet), 0));
}
}*/
}