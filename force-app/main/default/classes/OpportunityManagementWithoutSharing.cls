/*
----------------------------------------------------------------------
-- - Name          : OpportunityManagementWithoutSharing
-- - Author        : SNEHIL
-- - Description   : To manage role id on Opportunity for visibility of specific sections
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  JAN-25       SNEHIL               1.0       Initial version
---------------------------------------------------------------------------------------
*/
public without sharing class OpportunityManagementWithoutSharing {
    private static final Map<String, String> roleToFieldMap = new Map<String, String>{'Primary Contact' => 'Primary_Contact__c', 'Invoicing Contact' => 'Invoicing_Contact__c','Delivering Contact' => 'Delivering_Contact__c','Order Contact' => 'Order_Contact__c'};
        
        /*public static void syncOCRFromOpportunity(List<Opportunity> oppList) {
            Set<Id> oppIds = new Set<Id>();
            for (Opportunity opp : oppList) {
                if (opp.Id != null) oppIds.add(opp.Id);
            }
            
            Map<Id, List<OpportunityContactRole>> existingOCRMap = new Map<Id, List<OpportunityContactRole>>();
            for (OpportunityContactRole ocr : [
                SELECT Id, OpportunityId, ContactId, Role
                FROM OpportunityContactRole
                WHERE OpportunityId IN :oppIds
            ]) {
                if (!existingOCRMap.containsKey(ocr.OpportunityId)) {
                    existingOCRMap.put(ocr.OpportunityId, new List<OpportunityContactRole>());
                }
                existingOCRMap.get(ocr.OpportunityId).add(ocr);
            }
            
            List<OpportunityContactRole> ocrsToUpsert = new List<OpportunityContactRole>();
            List<OpportunityContactRole> ocrsToDelete = new List<OpportunityContactRole>();
            
            for (Opportunity opp : oppList) {
                if (opp.Id == null) continue;
                List<OpportunityContactRole> existing = existingOCRMap.get(opp.Id);
                
                for (String role : roleToFieldMap.keySet()) {
                    String fieldName = roleToFieldMap.get(role);
                    Id newContactId = (Id) opp.get(fieldName);
                    Boolean matched = false;
                    
                    if (existing != null) {
                        for (OpportunityContactRole ocr : existing) {
                            if (ocr.Role == role) {
                                matched = true;
                                
                                if (newContactId == null) {
                                    ocrsToDelete.add(ocr);
                                } else if (ocr.ContactId != newContactId) {
                                    ocr.ContactId = newContactId;
                                    ocrsToUpsert.add(ocr);
                                }
                                break;
                            }
                        }
                    }
                    
                    if (!matched && newContactId != null) {
                        ocrsToUpsert.add(new OpportunityContactRole(
                            OpportunityId = opp.Id,
                            ContactId = newContactId,
                            Role = role
                        ));
                    }
                }
            }
            System.debug('ocrsToUpsert ::: '+ocrsToUpsert);                    
            if (!ocrsToUpsert.isEmpty()) {
                upsert ocrsToUpsert;
            }
            System.debug('ocrsToDelete ::: '+ocrsToDelete);
            if (!ocrsToDelete.isEmpty()) {
                delete ocrsToDelete;
            }
        }*/
    /**
    * @description : Sync and create/update ACR from OpportunityContactRole
    *                - On insert/update of OCR, create ACR if not exists using key = AccountId + ContactId + Role
    *                - If ACR exists, append role to it (no duplicates)
    *                - Ensures only one ACR per Contact+Account+Role combo
    *                - Bulk-safe for large volumes (e.g., 100+ OCRs per Contact)
    * @author      : Mayank Sankhla
    */
    public static void syncACRFromOCR(List<OpportunityContactRole> ocrsToUpsert, List<OpportunityContactRole> ocrsToDelete) {
        /*Set<Id> oppIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        
        for (OpportunityContactRole ocr : ocrsToUpsert) {
            if (ocr.OpportunityId != null && ocr.ContactId != null && !String.isBlank(ocr.Role)) {
                oppIds.add(ocr.OpportunityId);
                contactIds.add(ocr.ContactId);
            }
        }
        if (oppIds.isEmpty()) return;*/

        // Handle upsert OCRs
        Set<Id> oppIdsUpsert = new Set<Id>();
        Set<Id> contactIdsUpsert = new Set<Id>();

        if (ocrsToUpsert != null && !ocrsToUpsert.isEmpty()) {
            for (OpportunityContactRole ocr : ocrsToUpsert) {
                if (ocr.OpportunityId != null && ocr.ContactId != null && !String.isBlank(ocr.Role)) {
                    oppIdsUpsert.add(ocr.OpportunityId);
                    contactIdsUpsert.add(ocr.ContactId);
                }
            }
        }

        // Handle delete OCRs
        Set<Id> oppIdsDelete = new Set<Id>();
        Set<Id> contactIdsDelete = new Set<Id>();

        if (ocrsToDelete != null && !ocrsToDelete.isEmpty()) {
            for (OpportunityContactRole ocr : ocrsToDelete) {
                if (ocr.OpportunityId != null && ocr.ContactId != null) {
                    oppIdsDelete.add(ocr.OpportunityId);
                    contactIdsDelete.add(ocr.ContactId);
                }
            }
        }

        // Combine all IDs for queries
        Set<Id> oppIds = new Set<Id>();
        oppIds.addAll(oppIdsUpsert);
        oppIds.addAll(oppIdsDelete);

        Set<Id> contactIds = new Set<Id>();
        contactIds.addAll(contactIdsUpsert);
        contactIds.addAll(contactIdsDelete);

        if (oppIds.isEmpty() && contactIds.isEmpty()) return;
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, AccountId FROM Opportunity WHERE Id IN :oppIds]
        );
        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : oppMap.values()) if (o.AccountId != null) accountIds.add(o.AccountId);
        
        List<AccountContactRelation> existingAcrs = [
            SELECT Id, AccountId, ContactId, Roles, IsDirect
            FROM AccountContactRelation
            WHERE AccountId IN :accountIds AND ContactId IN :contactIds
        ];
        
        Map<String, AccountContactRelation> baseAcrMap       = new Map<String, AccountContactRelation>(); 
        Map<String, Set<String>>            existingRoleMap  = new Map<String, Set<String>>();
        
        for (AccountContactRelation acr : existingAcrs) {
            String pair = acr.AccountId + '_' + acr.ContactId;
            baseAcrMap.put(pair, acr);
            existingRoleMap.put(pair, new Set<String>(getRoleList(acr.Roles)));
        }
        
        Map<String, Set<String>> incomingRoleMap = new Map<String, Set<String>>();
        
        if (ocrsToUpsert != null && !ocrsToUpsert.isEmpty()) {
            for (OpportunityContactRole ocr : ocrsToUpsert) {
                Opportunity opp = oppMap.get(ocr.OpportunityId);
                if (opp == null || opp.AccountId == null || String.isBlank(ocr.Role)) continue;
                
                String pair = opp.AccountId + '_' + ocr.ContactId;
                
                Set<String> roleSet = incomingRoleMap.containsKey(pair)
                    ? incomingRoleMap.get(pair)
                    : new Set<String>();
                
                roleSet.add(ocr.Role);
                incomingRoleMap.put(pair, roleSet);
            }
        }
        
        Map<String, AccountContactRelation> toInsertMap = new Map<String, AccountContactRelation>();
        Map<Id,    AccountContactRelation> toUpdateMap = new Map<Id,    AccountContactRelation>();

        //New Logic
        // ===== NEW: PART 4 - Process Delete (Remove roles or delete ACRs) =====
Map<String, Set<String>> deletedRoleMap = new Map<String, Set<String>>();

if (ocrsToDelete != null && !ocrsToDelete.isEmpty()) {
    for (OpportunityContactRole ocr : ocrsToDelete) {
        Opportunity opp = oppMap.get(ocr.OpportunityId);
        if (opp == null || opp.AccountId == null) continue;
        
        String pair = opp.AccountId + '_' + ocr.ContactId;
        
        Set<String> roleSet = deletedRoleMap.containsKey(pair)
            ? deletedRoleMap.get(pair)
            : new Set<String>();
        
        if (!String.isBlank(ocr.Role)) {
            roleSet.add(ocr.Role);
        }
        deletedRoleMap.put(pair, roleSet);
    }
}

List<AccountContactRelation> toDelete = new List<AccountContactRelation>();

for (String pair : deletedRoleMap.keySet()) {
    AccountContactRelation acr = baseAcrMap.get(pair);
    if (acr == null) continue;
    
    // Skip direct relationships (cannot be deleted)
    if (acr.IsDirect) {
        System.debug('Cannot delete direct ACR for pair: ' + pair + '. This is a system-created relationship.');
        continue;
    }
    
    Set<String> rolesToRemove = deletedRoleMap.get(pair);
    Set<String> currentRoles = existingRoleMap.get(pair);
    
    if (currentRoles == null || currentRoles.isEmpty()) {
        // No roles - delete ACR
        toDelete.add(acr);
    } else {
        // Remove deleted roles
        currentRoles.removeAll(rolesToRemove);
        
        if (currentRoles.isEmpty()) {
            // No roles left - delete ACR
            toDelete.add(acr);
        } else {
            // Still has roles - update ACR (only if not already in update map)
            if (!toUpdateMap.containsKey(acr.Id)) {
                acr.Roles = joinRoles(currentRoles);
                toUpdateMap.put(acr.Id, acr);
            }
        }
    }
}
//New Logic ends
        
        for (String pair : incomingRoleMap.keySet()) {
            Set<String> incomingRoles  = incomingRoleMap.get(pair);
            Set<String> existingRoles  = existingRoleMap.get(pair);
            
            if (existingRoles == null) {
                AccountContactRelation newAcr = new AccountContactRelation(
                    AccountId = (Id)pair.split('_')[0],
                    ContactId = (Id)pair.split('_')[1],
                    Roles     = joinRoles(incomingRoles)
                );
                toInsertMap.put(pair, newAcr);
            } else {
                Boolean changed = existingRoles.addAll(incomingRoles);
                if (changed) {
                    AccountContactRelation acr = baseAcrMap.get(pair);
                    acr.Roles = joinRoles(existingRoles);
                    toUpdateMap.put(acr.Id, acr);
                }
            }
        }
        
        /*if (!toInsertMap.isEmpty()) insert toInsertMap.values();
        if (!toUpdateMap.isEmpty()) update toUpdateMap.values();*/
        // Perform DML operations with error handling
        try {
            if (!toInsertMap.isEmpty()) {
                Database.SaveResult[] insertResults = Database.insert(toInsertMap.values(), false);
                logACRResults('Insert', insertResults);
            }
            
            if (!toUpdateMap.isEmpty()) {
                Database.SaveResult[] updateResults = Database.update(toUpdateMap.values(), false);
                logACRResults('Update', updateResults);
            }
            
            if (!toDelete.isEmpty()) {
                Database.DeleteResult[] deleteResults = Database.delete(toDelete, false);
                logACRDeleteResults(deleteResults);
            }
            
        } catch (DmlException e) {
            System.debug('ACR Sync Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
    
    private static List<String> getRoleList(String rolesStr) {
        return String.isBlank(rolesStr) ? new List<String>() : rolesStr.split(';');
    }
    private static String joinRoles(Set<String> rolesSet) {
        return String.join(new List<String>(rolesSet), ';');
    }
    
    /**
    * @description : to not allow user to create duplicate OpportunityContactRole
    * @author Mayank Sankhla
    **/
    public static void preventDuplicateRoles(List<OpportunityContactRole> newOCRs) {
        Set<Id> opportunityIds = new Set<Id>();
        for (OpportunityContactRole ocr : newOCRs) {
            if (ocr.OpportunityId != null && roleToFieldMap.containsKey(ocr.Role)) {
                opportunityIds.add(ocr.OpportunityId);
            }
        }
        
        Map<Id, List<OpportunityContactRole>> existingOCRMap = new Map<Id, List<OpportunityContactRole>>();
        for (OpportunityContactRole existing : [
            SELECT Id, OpportunityId, Role
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIds
        ]) {
            if (!existingOCRMap.containsKey(existing.OpportunityId)) {
                existingOCRMap.put(existing.OpportunityId, new List<OpportunityContactRole>());
            }
            existingOCRMap.get(existing.OpportunityId).add(existing);
        }
        
        Map<Id, Set<String>> seenRolesByOpp = new Map<Id, Set<String>>();
        
        for (Id oppId : existingOCRMap.keySet()) {
            Set<String> roles = new Set<String>();
            for (OpportunityContactRole ocr : existingOCRMap.get(oppId)) {
                roles.add(ocr.Role);
            }
            seenRolesByOpp.put(oppId, roles);
        }
        
        for (OpportunityContactRole ocr : newOCRs) {
            if (ocr.OpportunityId == null || !roleToFieldMap.containsKey(ocr.Role)) continue;
            
            Set<String> rolesSeen = seenRolesByOpp.get(ocr.OpportunityId);
            if (rolesSeen == null) {
                rolesSeen = new Set<String>();
                seenRolesByOpp.put(ocr.OpportunityId, rolesSeen);
            }
            
            Boolean isSelfUpdate = false;
            if (ocr.Id != null) {
                for (OpportunityContactRole existing : existingOCRMap.get(ocr.OpportunityId)) {
                    if (existing.Id == ocr.Id && existing.Role == ocr.Role) {
                        isSelfUpdate = true;
                        break;
                    }
                }
            }
            
            if (!isSelfUpdate && rolesSeen.contains(ocr.Role)) {
                ocr.addError('Only one contact role with this role is allowed per Opportunity.');
            } else {
                rolesSeen.add(ocr.Role);
            }
        }
    }
    
    
    /**
    * @description : to clear opportunity fields (primary contact etc.) on deletion of OpportunityContactRole
    * @author Mayank Sankhla
    **/
    /*public static void clearOpportunityFieldsOnOCRDelete(List<OpportunityContactRole> deletedOCRs) {
        Set<Id> oppIds = new Set<Id>();
        
        for (OpportunityContactRole ocr : deletedOCRs) {
            if (ocr.OpportunityId == null || !roleToFieldMap.containsKey(ocr.Role)) continue;
            oppIds.add(ocr.OpportunityId);
        }
        
        if (oppIds.isEmpty()) return;
        
        Map<Id, Opportunity> existingOpps = new Map<Id, Opportunity>(
            [SELECT Id, 
             Primary_Contact__c,
             Order_Contact__c,
             Invoicing_Contact__c,
             Delivering_Contact__c
             FROM Opportunity 
             WHERE Id IN :oppIds]
        );
        
        Map<Id, Opportunity> oppUpdates = new Map<Id, Opportunity>();
        
        for (OpportunityContactRole ocr : deletedOCRs) {
            if (ocr.OpportunityId == null || ocr.ContactId == null || !roleToFieldMap.containsKey(ocr.Role)) continue;
            
            String fieldName = roleToFieldMap.get(ocr.Role);
            Opportunity existingOpp = existingOpps.get(ocr.OpportunityId);
            if (existingOpp == null) continue;
            
            Id currentValue = (Id)existingOpp.get(fieldName);
            if (currentValue == null || currentValue != ocr.ContactId) continue;
            
            Opportunity oppToUpdate = oppUpdates.containsKey(ocr.OpportunityId)
                ? oppUpdates.get(ocr.OpportunityId)
                : new Opportunity(Id = ocr.OpportunityId);
            oppToUpdate.put(fieldName, null);
            oppUpdates.put(ocr.OpportunityId, oppToUpdate);
        }
        System.debug('Delete OCR : '+oppUpdates.size());
        if (!oppUpdates.isEmpty()) {
            update oppUpdates.values();
        }
    }*/
    
    /**
    * @description : to sync opportunity fields (primary contact) From OpportunityContactRole
    * @author Mayank Sankhla
    **/
    /*public static void syncOpportunityFieldsFromOCR(List<OpportunityContactRole> ocrList) {
        Map<Id, Opportunity> oppUpdates = new Map<Id, Opportunity>();
        List<OpportunityContactRole> oppPriFieldUpdates = new List<OpportunityContactRole>();
        Set<Id> oppIds = new Set<Id>();
        
        for(OpportunityContactRole ocr : ocrList){
            if(roleToFieldMap.containsKey(ocr.Role) && ocr.Role == 'Primary Contact'){
                oppPriFieldUpdates.add(ocr);
            }
        }
        
        for (OpportunityContactRole ocr : oppPriFieldUpdates) {
            if (ocr.OpportunityId == null || ocr.ContactId == null || !roleToFieldMap.containsKey(ocr.Role)) continue;
            oppIds.add(ocr.OpportunityId);
        }
        
        Map<Id, Opportunity> existingOpps = new Map<Id, Opportunity>([SELECT Id, Primary_Contact__c FROM Opportunity WHERE Id IN :oppIds]);
        
        for (OpportunityContactRole ocr : oppPriFieldUpdates) {
            if (ocr.OpportunityId == null || ocr.ContactId == null || !roleToFieldMap.containsKey(ocr.Role)) continue;
            
            String fieldName = roleToFieldMap.get(ocr.Role);
            Opportunity existingOpp = existingOpps.get(ocr.OpportunityId);
            
            if (existingOpp.get(fieldName) == ocr.ContactId) continue;
            
            Opportunity oppToUpdate = oppUpdates.containsKey(ocr.OpportunityId)
                ? oppUpdates.get(ocr.OpportunityId)
                : new Opportunity(Id = ocr.OpportunityId);
            
            oppToUpdate.put(fieldName, ocr.ContactId);
            oppUpdates.put(ocr.OpportunityId, oppToUpdate);
        }
        
        System.debug('OCR trigger oppUpdates : '+oppUpdates.size());
        
        if (!oppUpdates.isEmpty()) {
            update oppUpdates.values();
        }
    }*/
    
    /**
    * @description : to create ContractContactRole From OpportunityContactRole
    * @author Mayank Sankhla
    **/
    public static void createCCRForContractFromOCR(List<Contract> newContracts) {
        Map<Id, Id> contractToOpportunityMap = new Map<Id, Id>();
        Set<Id> opportunityIds = new Set<Id>();
        
        for (Contract contractRec : newContracts) {
            if (contractRec.ER_OpportunityId__c != null) {
                contractToOpportunityMap.put(contractRec.Id, contractRec.ER_OpportunityId__c);
                opportunityIds.add(contractRec.ER_OpportunityId__c);
            }
        }
        
        if (opportunityIds.isEmpty()) return;
        
        List<OpportunityContactRole> ocrList = [
            SELECT ContactId, OpportunityId, Role
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIds
        ];
        
        Map<Id, List<OpportunityContactRole>> oppIdToOCRsMap = new Map<Id, List<OpportunityContactRole>>();
        for (OpportunityContactRole ocr : ocrList) {
            if (!oppIdToOCRsMap.containsKey(ocr.OpportunityId)) {
                oppIdToOCRsMap.put(ocr.OpportunityId, new List<OpportunityContactRole>());
            }
            oppIdToOCRsMap.get(ocr.OpportunityId).add(ocr);
        }
        
        List<ContractContactRole> ccrsToInsert = new List<ContractContactRole>();
        for (Contract contractRec : newContracts) {
            Id oppId = contractRec.ER_OpportunityId__c;
            if (oppId == null) continue;
            
            List<OpportunityContactRole> ocrs = oppIdToOCRsMap.get(oppId);
            if (ocrs == null || ocrs.isEmpty()) continue;
            
            for (OpportunityContactRole ocr : ocrs) {
                ccrsToInsert.add(new ContractContactRole(
                    ContractId = contractRec.Id,
                    ContactId = ocr.ContactId,
                    Role = ocr.Role
                ));
            }
        }
        
        if (!ccrsToInsert.isEmpty()) {
            try {
                insert ccrsToInsert;
            } catch (DmlException e) {
                System.debug('Error inserting CCRs: ' + e.getMessage());
            }
        }
    }
    
    /*@AuraEnabled
    public static String syncCCRtoOCR(Id contractId) {
        Contract contractRec = [
            SELECT Id, ER_OpportunityId__c
            FROM Contract
            WHERE Id = :contractId
            LIMIT 1
        ];
        
        if (contractRec.ER_OpportunityId__c == null) {
            throw new AuraHandledException('Contract is not linked to any Opportunity.');
        }
        
        Id oppId = contractRec.ER_OpportunityId__c;
        
        Opportunity recOpp = new Opportunity(Id = oppId, byPassVR__c = true);
        update recOpp;
        
        List<ContractContactRole> ccrs = [
            SELECT ContactId, Role
            FROM ContractContactRole
            WHERE ContractId = :contractId
            AND Role IN ('Primary Contact', 'Invoicing Contact', 'Delivering Contact', 'Order Contact')
        ];
        
        if (ccrs.isEmpty()) {
            throw new AuraHandledException('No contact roles found on the contract for synchronization.');
        }
        
        List<OpportunityContactRole> existingOCRs = [
            SELECT Id, ContactId, Role
            FROM OpportunityContactRole
            WHERE OpportunityId = :oppId
            AND Role IN ('Primary Contact', 'Invoicing Contact', 'Delivering Contact', 'Order Contact')
        ];
        
        Map<String, List<OpportunityContactRole>> roleToOCRsMap = new Map<String, List<OpportunityContactRole>>();
        for (OpportunityContactRole ocr : existingOCRs) {
            if (!roleToOCRsMap.containsKey(ocr.Role)) {
                roleToOCRsMap.put(ocr.Role, new List<OpportunityContactRole>());
            }
            roleToOCRsMap.get(ocr.Role).add(ocr);
        }
        
        List<OpportunityContactRole> ocrsToInsert = new List<OpportunityContactRole>();
        List<OpportunityContactRole> ocrsToUpdate = new List<OpportunityContactRole>();
        List<OpportunityContactRole> ocrsToDelete = new List<OpportunityContactRole>();
        System.debug('hereee in '+roleToOCRsMap);*/
        /*for (ContractContactRole ccr : ccrs) {
            String role = ccr.Role;
            Id contactId = ccr.ContactId;
            System.debug('hereee in CCR Loop');
            System.debug('Role'+Role);
            if (roleToOCRsMap.containsKey(role)) {
                System.debug('hereee in first If Loop'+roleToOCRsMap);
                List<OpportunityContactRole> ocrList = roleToOCRsMap.get(role);
                
                if (ocrList.size() == 1) {
                    System.debug('hereee in sec If Loop');
                    OpportunityContactRole existingOCR = ocrList[0];
                    if (existingOCR.ContactId != contactId) {
                        existingOCR.ContactId = contactId;
                        ocrsToUpdate.add(existingOCR);
                    }
                } else {
                    System.debug('hereee in first esle Loop');
                    ocrsToDelete.addAll(ocrList);
                    
                    ocrsToInsert.add(new OpportunityContactRole(
                        OpportunityId = oppId,
                        ContactId = contactId,
                        Role = role,
                        IsPrimary = false
                    ));
                }
            } else {
                System.debug('hereee in else');
                ocrsToInsert.add(new OpportunityContactRole(
                    OpportunityId = oppId,
                    ContactId = contactId,
                    Role = role,
                    IsPrimary = false
                ));
            }
        }
        */
        
        // Build map of existing CCR by role
    /*Map<String, ContractContactRole> existingCCRByRole = new Map<String, ContractContactRole>();
    for (ContractContactRole ccr : ccrs) {
        existingCCRByRole.put(ccr.Role.trim(), ccr);
    }

    List<ContractContactRole> ccrsToInsert = new List<ContractContactRole>();
    List<ContractContactRole> ccrsToUpdate = new List<ContractContactRole>();

    // Loop through OCR roles — this is the correct direction
    for (OpportunityContactRole ocr : existingOCRs) {
        String role = ocr.Role.trim();
        Id contactId = ocr.ContactId;

        ContractContactRole existing = existingCCRByRole.get(role);

        if (existing == null) {
            // INSERT new CCR for missing role
            ccrsToInsert.add(new ContractContactRole(
                ContractId = contractId,
                ContactId = contactId,
                Role = role
            ));
        } else {
            // UPDATE existing CCR if contact changed
            if (existing.ContactId != contactId) {
                existing.ContactId = contactId;
                ccrsToUpdate.add(existing);
            }
        }
    }*/

            
            /*try {
                System.debug('ocrsToDelete ...'+ocrsToDelete);
                System.debug('ocrsToUpdate ...'+ocrsToUpdate);
                System.debug('ocrsToInsert ...'+ocrsToInsert);
                if (!ocrsToDelete.isEmpty()) delete ocrsToDelete;
                if (!ocrsToUpdate.isEmpty()) update ocrsToUpdate;
                if (!ocrsToInsert.isEmpty()) insert ocrsToInsert;
                
                recOpp.byPassVR__c = false;
                update recOpp;
            } catch (DmlException e) {
                throw new AuraHandledException('Error during OCR sync: ' + e.getMessage());
            }*/
            /*try {
        if (!ccrsToUpdate.isEmpty()) update ccrsToUpdate;
        if (!ccrsToInsert.isEmpty()) insert ccrsToInsert;

        recOpp.byPassVR__c = false;
        update recOpp;

    } catch (Exception e) {
        throw new AuraHandledException('Error during CCR sync: ' + e.getMessage());
    }
        
        if (ocrsToInsert.isEmpty() && ocrsToUpdate.isEmpty() && ocrsToDelete.isEmpty()) {
            return 'NO_CHANGES';
        }
        
        return 'UPDATED';
    }*/

    @AuraEnabled
public static String syncCCRtoOCR(Id contractId) {
    // Get Contract with Opportunity link and Account
    Contract contractRec = [
        SELECT Id, ER_OpportunityId__c, AccountId
        FROM Contract
        WHERE Id = :contractId
        LIMIT 1
    ];
    
    if (contractRec.AccountId == null) {
        throw new AuraHandledException('Contract must have an associated Account.');
    }
    
    Id oppId = contractRec.ER_OpportunityId__c;
    Id accountId = contractRec.AccountId;
    Boolean hasOpportunity = (oppId != null);
    
    // Bypass validation rules only if opportunity exists
    if (hasOpportunity) {
        Opportunity recOpp = new Opportunity(Id = oppId, byPassVR__c = true);
        update recOpp;
    }
    
    // Get all CCRs with specific roles
    List<ContractContactRole> ccrs = [
        SELECT ContactId, Role
        FROM ContractContactRole
        WHERE ContractId = :contractId
        AND Role IN ('Primary Contact', 'Invoicing Contact', 'Delivering Contact', 'Order Contact')
    ];
    
    // Get all OCRs with specific roles (only if opportunity exists)
    List<OpportunityContactRole> existingOCRs = new List<OpportunityContactRole>();
    if (hasOpportunity) {
        existingOCRs = [
            SELECT Id, ContactId, Role
            FROM OpportunityContactRole
            WHERE OpportunityId = :oppId
            AND Role IN ('Primary Contact', 'Invoicing Contact', 'Delivering Contact', 'Order Contact')
        ];
    }
    
    // Get all existing ACRs for this account (with IsDirect field)
    List<AccountContactRelation> existingACRs = [
        SELECT Id, ContactId, AccountId, Roles, IsDirect
        FROM AccountContactRelation
        WHERE AccountId = :accountId
    ];
    
    // Build maps for quick lookup
    Map<String, ContractContactRole> ccrByRole = new Map<String, ContractContactRole>();
    Set<Id> ccrContactIds = new Set<Id>();
    Map<Id, Set<String>> contactToRolesMap = new Map<Id, Set<String>>();
    
    for (ContractContactRole ccr : ccrs) {
        ccrByRole.put(ccr.Role.trim(), ccr);
        ccrContactIds.add(ccr.ContactId);
        
        // Aggregate roles per contact (for ACR creation)
        if (!contactToRolesMap.containsKey(ccr.ContactId)) {
            contactToRolesMap.put(ccr.ContactId, new Set<String>());
        }
        contactToRolesMap.get(ccr.ContactId).add(ccr.Role.trim());
    }
    
    Map<String, List<OpportunityContactRole>> roleToOCRsMap = new Map<String, List<OpportunityContactRole>>();
    Set<Id> ocrContactIds = new Set<Id>();
    for (OpportunityContactRole ocr : existingOCRs) {
        if (!roleToOCRsMap.containsKey(ocr.Role)) {
            roleToOCRsMap.put(ocr.Role, new List<OpportunityContactRole>());
        }
        roleToOCRsMap.get(ocr.Role).add(ocr);
        ocrContactIds.add(ocr.ContactId);
    }
    
    Map<Id, AccountContactRelation> contactIdToACRMap = new Map<Id, AccountContactRelation>();
    for (AccountContactRelation acr : existingACRs) {
        contactIdToACRMap.put(acr.ContactId, acr);
    }
    
    // Prepare DML lists for OCR
    List<OpportunityContactRole> ocrsToInsert = new List<OpportunityContactRole>();
    List<OpportunityContactRole> ocrsToUpdate = new List<OpportunityContactRole>();
    List<OpportunityContactRole> ocrsToDelete = new List<OpportunityContactRole>();
    
    // Prepare DML lists for ACR
    List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();
    List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
    List<AccountContactRelation> acrsToDelete = new List<AccountContactRelation>();
    
    // ===== PART 1: CCR → OCR Sync (only if opportunity exists) =====
    if (hasOpportunity) {
        for (ContractContactRole ccr : ccrs) {
            String role = ccr.Role.trim();
            Id contactId = ccr.ContactId;
            
            if (roleToOCRsMap.containsKey(role)) {
                List<OpportunityContactRole> ocrList = roleToOCRsMap.get(role);
                
                if (ocrList.size() == 1) {
                    // Single OCR exists - update if contact is different
                    OpportunityContactRole existingOCR = ocrList[0];
                    if (existingOCR.ContactId != contactId) {
                        existingOCR.ContactId = contactId;
                        ocrsToUpdate.add(existingOCR);
                    }
                } else {
                    // Multiple OCRs exist - clean up and create new
                    ocrsToDelete.addAll(ocrList);
                    
                    ocrsToInsert.add(new OpportunityContactRole(
                        OpportunityId = oppId,
                        ContactId = contactId,
                        Role = role,
                        IsPrimary = false
                    ));
                }
            } else {
                // No OCR exists - create new
                ocrsToInsert.add(new OpportunityContactRole(
                    OpportunityId = oppId,
                    ContactId = contactId,
                    Role = role,
                    IsPrimary = false
                ));
            }
        }
        
        // ===== PART 2: Delete OCRs where CCR doesn't exist =====
        for (OpportunityContactRole ocr : existingOCRs) {
            String role = ocr.Role.trim();
            
            // If no CCR exists for this role, mark OCR for deletion
            if (!ccrByRole.containsKey(role)) {
                ocrsToDelete.add(ocr);
            }
        }
    }
    
    // ===== PART 3: CCR → ACR Direct Sync (when no opportunity OR as backup) =====
    if (!hasOpportunity) {
        // NO OPPORTUNITY: Create/Update ACRs directly from CCRs
        for (Id contactId : contactToRolesMap.keySet()) {
            Set<String> roles = contactToRolesMap.get(contactId);
            String rolesString = String.join(new List<String>(roles), ';');
            
            if (contactIdToACRMap.containsKey(contactId)) {
                // ACR exists - update with all CCR roles
                AccountContactRelation existingACR = contactIdToACRMap.get(contactId);
                
                // Only update if it's NOT a direct relationship
                if (!existingACR.IsDirect) {
                    // Get current roles from ACR
                    Set<String> currentACRRoles = new Set<String>();
                    if (String.isNotBlank(existingACR.Roles)) {
                        currentACRRoles.addAll(existingACR.Roles.split(';'));
                    }
                    
                    // Replace with CCR roles only (CCR is source of truth)
                    String updatedRolesString = String.join(new List<String>(roles), ';');
                    
                    if (existingACR.Roles != updatedRolesString) {
                        existingACR.Roles = updatedRolesString;
                        acrsToUpdate.add(existingACR);
                    }
                } else {
                    System.debug('Skipping direct ACR update for Contact: ' + contactId);
                }
            } else {
                // ACR doesn't exist - create new (indirect relationship)
                AccountContactRelation newACR = new AccountContactRelation(
                    AccountId = accountId,
                    ContactId = contactId,
                    Roles = rolesString
                );
                acrsToInsert.add(newACR);
            }
        }
        
        // Delete ACRs where CCR doesn't exist (only indirect relationships)
        for (AccountContactRelation acr : existingACRs) {
            if (!ccrContactIds.contains(acr.ContactId)) {
                // Only delete if it's NOT a direct relationship
                if (!acr.IsDirect) {
                    acrsToDelete.add(acr);
                } else {
                    System.debug('Cannot delete direct ACR for Contact: ' + acr.ContactId + 
                               '. Contact.AccountId must be changed or Contact must be deleted.');
                }
            }
        }
    } else {
        // HAS OPPORTUNITY: ACR will be created by OCR trigger
        // But we still need to handle deletion if OCR is deleted
        Set<Id> contactIdsToDelete = new Set<Id>();
        
        for (OpportunityContactRole ocr : ocrsToDelete) {
            contactIdsToDelete.add(ocr.ContactId);
        }
        
        // Remove contacts that still have CCRs (they should keep their ACRs)
        contactIdsToDelete.removeAll(ccrContactIds);
        
        // Delete ACRs for contacts that no longer have CCRs (only indirect relationships)
        for (Id contactId : contactIdsToDelete) {
            if (contactIdToACRMap.containsKey(contactId)) {
                AccountContactRelation acrToDelete = contactIdToACRMap.get(contactId);
                
                // Only delete if it's NOT a direct relationship
                if (!acrToDelete.IsDirect) {
                    acrsToDelete.add(acrToDelete);
                } else {
                    System.debug('Cannot delete direct ACR for Contact: ' + contactId + 
                               '. This is a system-created relationship.');
                }
            }
        }
    }
    
    // Perform DML operations
    try {
        // OCR operations (only if opportunity exists)
        if (hasOpportunity) {
            if (!ocrsToDelete.isEmpty()) delete ocrsToDelete;
            if (!ocrsToUpdate.isEmpty()) update ocrsToUpdate;
            if (!ocrsToInsert.isEmpty()) insert ocrsToInsert;
            // Note: OCR trigger will create ACRs automatically
        }
        
        // ACR operations (direct from CCR when no opportunity, or cleanup when opportunity exists)
        if (!acrsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(acrsToInsert, false);
            logACRResults('Insert', insertResults);
        }
        
        if (!acrsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(acrsToUpdate, false);
            logACRResults('Update', updateResults);
        }
        
        if (!acrsToDelete.isEmpty()) {
            Database.DeleteResult[] deleteResults = Database.delete(acrsToDelete, false);
            logACRDeleteResults(deleteResults);
        }
        
        // Re-enable validation rules (only if opportunity exists)
        if (hasOpportunity) {
            Opportunity recOpp = new Opportunity(Id = oppId, byPassVR__c = false);
            update recOpp;
        }
        
    } catch (DmlException e) {
        System.debug('DML Error: ' + e.getMessage());
        System.debug('Stack Trace: ' + e.getStackTraceString());
        throw new AuraHandledException('Error during sync: ' + e.getMessage());
    }
    
    // Check if any changes were made
    Boolean hasChanges = !ocrsToInsert.isEmpty() || !ocrsToUpdate.isEmpty() || !ocrsToDelete.isEmpty() ||
                         !acrsToInsert.isEmpty() || !acrsToUpdate.isEmpty() || !acrsToDelete.isEmpty();
    
    return hasChanges ? 'UPDATED' : 'NO_CHANGES';
}

// Helper method to log ACR insert/update results
private static void logACRResults(String operation, Database.SaveResult[] results) {
    if (results == null) return;
    
    for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
            for (Database.Error error : result.getErrors()) {
                System.debug('ACR ' + operation + ' Error: ' + error.getMessage() + 
                           ' | Fields: ' + error.getFields() + 
                           ' | Status Code: ' + error.getStatusCode());
            }
        }
    }
}

// Helper method to log ACR delete results
private static void logACRDeleteResults(Database.DeleteResult[] results) {
    if (results == null) return;
    
    for (Database.DeleteResult result : results) {
        if (!result.isSuccess()) {
            for (Database.Error error : result.getErrors()) {
                System.debug('ACR Delete Error: ' + error.getMessage() + 
                           ' | Fields: ' + error.getFields() + 
                           ' | Status Code: ' + error.getStatusCode());
            }
        }
    }
}

    /**
    * @description : to store role id on Opportunity for visibility of specific sections
    * @author Snehil Verma | 15-01-2025
    * @param opportunities
    * @param oldItems
    **/
    public static void storeRoleIdOnOpportunityForVisibility(List<Opportunity> opportunities, Map<Id, Opportunity> oldItems) {
        
        Set<Id> ownerIdSet = new Set<Id>();
        Map<Id, List<Id>> ownerToParentRolesMap = new Map<Id, List<Id>>();
        Map<Id, Set<String>> userRoleMap = new Map<Id, Set<String>>();
        List<Opportunity> filteredOpportunityList = new List<Opportunity>();
        List<Opportunity> opportunityUpdateList = new List<Opportunity>();
        
        for (Opportunity oppObj : opportunities) {
            if(oldItems == null || (oldItems != null && oldItems.get(oppObj.Id).OwnerId != oppObj.OwnerId)){
                if (oppObj.OwnerId != null) { 
                    ownerIdSet.add(oppObj.OwnerId);
                    filteredOpportunityList.add(oppObj);
                }
            }
        }
        
        Map<Id, User> usersByOwnerId = new Map<Id, User>([SELECT Id, UserRoleId FROM User WHERE Id IN :ownerIdSet]);
        
        Map<Id, UserRole> allUserRoles = new Map<Id, UserRole>([SELECT Id, ParentRoleId, Name FROM UserRole]);
        
        for (User owner : usersByOwnerId.values()) {
            Id currentRoleId = owner.UserRoleId;
            List<Id> parentRoleIds = new List<Id>();
            
            if(currentRoleId != null && (allUserRoles.get(currentRoleId).Name == 'SME L2W/Partners channel Sales Rep' || allUserRoles.get(currentRoleId).Name == 'SME Telesales Hunting Sales Rep' || allUserRoles.get(currentRoleId).Name == 'SME Telesales Farming Sales Rep' || allUserRoles.get(currentRoleId).Name == 'Engagement Manager')){
                parentRoleIds.add(currentRoleId);
            }
            
            while (currentRoleId != null) {
                UserRole currentUserRole = allUserRoles.get(currentRoleId);
                currentRoleId = currentUserRole.ParentRoleId; 
                if(currentRoleId != null){
                    parentRoleIds.add(currentRoleId);
                }
            }
            ownerToParentRolesMap.put(owner.Id, parentRoleIds);
        }
        
        for(Opportunity oppObj : filteredOpportunityList){
            Set<String> allHigherUserIdSet = new Set<String>();
            if(ownerToParentRolesMap.containsKey(oppObj.OwnerId)){
                String concatenatedRoleIds = String.join(ownerToParentRolesMap.get(oppObj.OwnerId), ';');
                if (concatenatedRoleIds.length() > 255) {
                    Integer lastIndex = concatenatedRoleIds.substring(0, 255).lastIndexOf(';');
                    if (lastIndex != -1) {
                        concatenatedRoleIds = concatenatedRoleIds.substring(0, lastIndex);
                    }
                }
                Opportunity opp = new Opportunity();
                opp.Id = oppObj.Id;
                opp.Role_Id_for_Visibility__c  = concatenatedRoleIds;
                opportunityUpdateList.add(opp);
            }
        }
        
        if (!opportunityUpdateList.isEmpty()) {
            
            Database.SaveResult[] results = Database.update(opportunityUpdateList, false);
            
            List<Integration_Log__c> logs = new List<Integration_Log__c>();
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        Integration_Log__c log = new Integration_Log__c();
                        log.Request_Body__c = 'Role Id updation failed for: ' + opportunityUpdateList[i].Id;
                        log.Response_Body__c = err.getMessage();
                        log.Status__c = 'Error';
                        log.Status_Code__c = 500;
                        log.Status_Message__c = 'Updation Failed';
                        logs.add(log);
                    }
                }
            }
            
            if (!logs.isEmpty()) {
                Database.insert(logs, false);
            }
        }
        
    }
    /*
    * Pranjal Tiwari
    * 30/01/2025
    * createOpportunityFromContract : Automate the execution of the second approval process if required
    */
    public static void executeSecondaryApproval(List<Opportunity> opportunities, Map<id, Opportunity> oldItems) {
        
        List<Opportunity> opportunityToUpdate = new List<Opportunity>();
        List<Approval.ProcessSubmitRequest> approvalRequestForSubmission = new List<Approval.ProcessSubmitRequest>();
        Map<Id,Integer> oppIdCountMap = new Map<Id,Integer>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Integer count = 0;
        String approvalComment = '';
        Set<Id> excludedOpportunities = new Set<Id>();
        
        List<OpportunityLineItem> oliList = [Select Id, ER_NeedApproval__c, Has_Auto_Discount__c, Opportunity.OwnerId, OpportunityId FROM OpportunityLineItem WHERE OpportunityId IN: opportunities AND ER_NeedApproval__c = true AND Opportunity.Derieved_from_Framework_Opp__c = false];
        
        if(!oliList.isEmpty()){    
            for (OpportunityLineItem oli : oliList) {
                if (oli.Has_Auto_Discount__c) {
                    excludedOpportunities.add(oli.OpportunityId);
                }
            }
        }
        if(!oliList.isEmpty()){
            for (OpportunityLineItem oli : oliList) {
                if (!excludedOpportunities.contains(oli.OpportunityId)) {
                    oppIdCountMap.put(oli.OpportunityId, count++);
                }
            }
        }
        for(Opportunity opp : opportunities){
            if((oldItems.get(opp.Id).ER_NeedFinancialApproval__c == true && opp.ER_NeedFinancialApproval__c == false) && (oppIdCountMap.containsKey(opp.Id))){
                opportunityIdSet.add(opp.Id);
            }
        }
        if(!(opportunityIdSet.isEmpty())){
            for(Opportunity opp : [Select Id, ER_NeedApproval__c, OwnerId FROM Opportunity WHERE Id IN: opportunityIdSet]){
                opp.ER_NeedApproval__c = true;
                opportunityToUpdate.add(opp);
                
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments(approvalComment);
                req1.setObjectId(opp.id);
                
                // Submit on behalf of a specific submitter
                req1.setSubmitterId(opp.OwnerId);
                req1.setProcessDefinitionNameOrId('Benefits_Reduction_fee_Approval');
                approvalRequestForSubmission.add(req1);
            }
        }
        if(!opportunityToUpdate.isEmpty()){
            update opportunityToUpdate;
        }
        if(!approvalRequestForSubmission.isEmpty()){
            List<Approval.ProcessResult> results = Approval.process(approvalRequestForSubmission);
            for (Approval.ProcessResult result : results) {
                if (result.isSuccess()) {
                    System.debug('Submitted for approval successfully: ' + result.isSuccess());
                } else {
                    System.debug('Submitted for approval error: ' + result.getErrors());
                }
            }
        }
    }
    /*
* Pranjal Tiwari
* 4/02/2025
* createdSyncQuote : Automatically create quote on Approval of Approval Process
*/
    public static void createdSyncQuote(List<Opportunity> syncOpportunityList) {
        APER11_Quote_Management.createdSyncQuote(syncOpportunityList);
    }
    
    /*
* Pranjal Tiwari
* 27/03/2025
* createdSyncQuote : Prevent DML Operations for Framework Agreements
*/
    public static void preventDMLForFrameworkAgreement(List<OpportunityLineItem> oppLineItems, Map<id, OpportunityLineItem> oldItems){
        
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        if(oppLineItems != null){
            for(OpportunityLineItem oli : oppLineItems){
                oppIdSet.add(oli.OpportunityId);
            }
        }
        if(oldItems != null){
            for(OpportunityLineItem oli : oldItems.values()){
                oppIdSet.add(oli.OpportunityId);
            }
        }
        
        for(Opportunity opp : [Select Id, Derieved_from_Framework_Opp__c FROM Opportunity WHERE Id IN: oppIdSet AND Derieved_from_Framework_Opp__c = true]){
            opportunityMap.put(opp.Id, opp);
        }
        if(oppLineItems != null && oldItems == null){
            for(OpportunityLineItem oli : oppLineItems){
                if(opportunityMap.containsKey(oli.OpportunityId)){
                    oli.addError('This opportunity is derived from a framework agreement and cannot be edited.');
                }
            }
        }
        if (oppLineItems != null && oldItems != null) {
            Set<String> allowedFields = new Set<String>{
                'er_face_value__c',
                    'er_nb_beneficiaries__c',
                    'er_days_per_month__c',
                    'er_load_per_year__c',
                    'total_amount__c',
                    'er_min__c',
                    'er_max__c',
                    'er_needapproval__c',
                    'er_minimum_fee__c',
                    'er_offer_validity_end_date__c',
                    'er_offer_validity_start_date__c',
                    'subtotal',
                    'quantity',
                    'ER_Percentage__c',
                    'UnitPrice'
                    };
                        
                        Set<String> systemFields = new Set<String>{
                            'Id', 'CreatedById', 'CreatedDate', 'LastModifiedById', 'LastModifiedDate', 'SystemModstamp'
                                };
                                    
                                    Set<String> allowedFieldsLower = new Set<String>();
            for (String field : allowedFields) {
                allowedFieldsLower.add(field.toLowerCase());
            }
            
            for (OpportunityLineItem oli : oppLineItems) {
                if (opportunityMap.containsKey(oli.OpportunityId)) {
                    OpportunityLineItem oldOli = oldItems.get(oli.Id);
                    Boolean hasInvalidChanges = false;
                    String changedField = '';
                    
                    for (Schema.SObjectField field : Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().values()) {
                        String fieldName = field.getDescribe().getName();
                        String fieldNameLower = fieldName.toLowerCase();
                        Schema.DisplayType fieldType = field.getDescribe().getType();
                        
                        if (!systemFields.contains(fieldName) && !field.getDescribe().isCalculated()) {
                            if (!allowedFieldsLower.contains(fieldNameLower)) {
                                Object oldValue = oldOli.get(field);
                                Object newValue = oli.get(field);
                                
                                if (fieldType == Schema.DisplayType.PERCENT && oldValue != null && newValue != null) {
                                    Decimal oldDecimal = ((Decimal) oldValue).setScale(4);
                                    Decimal newDecimal = ((Decimal) newValue).setScale(4);
                                    
                                    if (oldDecimal != newDecimal) {
                                        hasInvalidChanges = true;
                                        changedField = fieldName;
                                        System.debug('Restricted field changed: ' + fieldName + ', Old Value: ' + oldDecimal + ', New Value: ' + newDecimal);
                                        break;
                                    }
                                }
                                else if ((oldValue == null && newValue != null) || (oldValue != null && !oldValue.equals(newValue))) {
                                    hasInvalidChanges = true;
                                    changedField = fieldName;
                                    System.debug('Restricted field changed: ' + fieldName + ', Old Value: ' + oldValue + ', New Value: ' + newValue);
                                    break;
                                }
                            }
                        } else {
                            System.debug('Skipping system/formula field: ' + fieldName);
                        }
                    }
                    
                    if (hasInvalidChanges) {
                        oli.addError('Only specific fields can be updated for opportunities derived from a framework agreement. Restricted field: ' + changedField);
                    }
                }
            }
        }
        
        
        
        
        if(oppLineItems == null && oldItems != null){
            for(OpportunityLineItem oli : oldItems.values()){
                if(opportunityMap.containsKey(oli.OpportunityId)){
                    oli.addError('This opportunity is derived from a framework agreement and cannot be edited.');
                }
            }           
        }
    }
    
    @InvocableMethod(label='Update Opportunity RoleId' description='Updates Role Id on Opportunity' category='Opportunity')
    public static void callStoreRoleIdOnOpportunityForVisibility(List<InputVariables> inputWrapperList) {
        if (inputWrapperList == null || inputWrapperList.isEmpty()) return;
        
        List<Opportunity> oppList = inputWrapperList[0].allOpps;
        if (oppList != null && !oppList.isEmpty()) {
            List<Id> oppIds = new List<Id>();
            for (Opportunity o : oppList) {
                oppIds.add(o.Id);
            }
            updateRoleIdAsync(oppIds);
        }
    }
    
    public class InputVariables {
        @InvocableVariable
        public List<Opportunity> allOpps;
    }
    
    @future
    public static void updateRoleIdAsync(List<Id> oppIds) {
        List<Opportunity> opps = [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :oppIds];
        storeRoleIdOnOpportunityForVisibility(opps, null); 
    }
    /**
     * @author SNICA
     * @date 08/03/2022
     * @description 15039 - Calculate the opportunity solutions
     * @param newItems
     * @param oldItems
     */
    public static void calculateOpportunitySolutions(
            List<OpportunityLineItem> newItems,
            Map<Id, OpportunityLineItem> oldItems
    ) {
        /* Map<Id, String> mapOppsSolutions = new Map<Id, String>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<OpportunityLineItem> items = (newItems != null && !newItems.isEmpty()
                ? newItems
                : (oldItems != null && !oldItems.isEmpty() ? oldItems.values() : null));
  
        if (items != null) {
            for (OpportunityLineItem oli : items) {
                    mapOppsSolutions.put(oli.OpportunityId, '');
            }
  
        for (OpportunityLineItem oli : [
                    SELECT Id, Product2.ER_Solution2__r.ProductCode, OpportunityId
                    FROM OpportunityLineItem
                    WHERE OpportunityId IN :mapOppsSolutions.keySet()
            ]) {
          if (String.isNotBlank(oli.Product2.ER_Solution2__r?.ProductCode)) {
                    String solutionCode = oli.Product2.ER_Solution2__r.ProductCode;
            if (mapOppsSolutions.get(oli.OpportunityId) == null || mapOppsSolutions.get(oli.OpportunityId) == '')
                        mapOppsSolutions.put(oli.OpportunityId, solutionCode);
            else if (!mapOppsSolutions.get(oli.OpportunityId).contains(solutionCode))
                        mapOppsSolutions.put(
                                oli.OpportunityId,
                                mapOppsSolutions.get(oli.OpportunityId) + ' / ' + oli.Product2.ER_Solution2__r.ProductCode
                        );
                }
            }
  
        for (Id oppId : mapOppsSolutions.keySet()) {
                opportunitiesToUpdate.add(new Opportunity(Id = oppId, ER_Solutions__c = mapOppsSolutions.get(oppId)));
            }
  
        if (!opportunitiesToUpdate.isEmpty())
                update opportunitiesToUpdate;
        } */
    }
    public static void addErrorOnOpportunity(List<Opportunity> oppList, Map<Id, Opportunity> oldMap) {
        /*if (!Test.isRunningTest()) {
            Set<Id> oppIdsToCheck = new Set<Id>();
            for (Opportunity opp : oppList) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                Boolean movedToProposal = (opp.StageName == 'Proposal' && oldOpp != null && oldOpp.StageName != 'Proposal');
                Boolean needApprovalChanged = (opp.ER_NeedApproval__c == true && (oldOpp == null || oldOpp.ER_NeedApproval__c != true));
                Boolean needFinancialApprovalChanged = (opp.ER_NeedFinancialApproval__c == true && (oldOpp == null || oldOpp.ER_NeedFinancialApproval__c != true));
                if (movedToProposal || needApprovalChanged || needFinancialApprovalChanged) {
                    oppIdsToCheck.add(opp.Id);
                }
            }
            if (oppIdsToCheck.isEmpty()) return;
            Set<Id> oppIdsWithPrimaryContact = new Set<Id>();
            for (OpportunityContactRole ocr : [
                SELECT OpportunityId
                FROM OpportunityContactRole
                WHERE OpportunityId IN :oppIdsToCheck
                      AND Role = 'Primary contact'
            ]) {
                oppIdsWithPrimaryContact.add(ocr.OpportunityId);
            }
            for (Opportunity opp : oppList) {
                if (oppIdsToCheck.contains(opp.Id) && !oppIdsWithPrimaryContact.contains(opp.Id)) {
                    opp.addError('You must assign a Primary contact before proceeding (Quote creation or Approval).');
                }
            }
        }*/
    }
    public static void addStageErrorOnOpportunity(List<Opportunity> oppList, Map<Id, Opportunity> oldMap) {
        if (!Test.isRunningTest()) {
            Set<Id> movedToProposalOppIds = new Set<Id>();
            Set<Id> movedToNegotiationOppIds = new Set<Id>();
    
            for (Opportunity opp : oppList) {
                Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
                Boolean movedToProposal = (opp.StageName == 'Proposal' && oldOpp != null && oldOpp.StageName != 'Proposal');
                Boolean movedToNegotiation = (opp.StageName == 'Negotiation' && oldOpp != null && oldOpp.StageName != 'Negotiation');
                if (movedToProposal) movedToProposalOppIds.add(opp.Id);
                if (movedToNegotiation) movedToNegotiationOppIds.add(opp.Id);
            }
    
            if (movedToProposalOppIds.isEmpty() && movedToNegotiationOppIds.isEmpty()) return;
    
            Set<Id> oppsWithLineItems = new Set<Id>();
            if (!movedToProposalOppIds.isEmpty()) {
                for (OpportunityLineItem oli : [
                    SELECT OpportunityId
                    FROM OpportunityLineItem
                    WHERE OpportunityId IN :movedToProposalOppIds
                ]) {
                    oppsWithLineItems.add(oli.OpportunityId);
                }
            }
    
            Set<Id> oppsWithActiveQuotes = new Set<Id>();
            if (!movedToNegotiationOppIds.isEmpty()) {
                for (Quote q : [
                    SELECT OpportunityId
                    FROM Quote
                    WHERE OpportunityId IN :movedToNegotiationOppIds
                    AND Status != 'Contract Accepted'
                    AND Status != 'Denied'
                ]) {
                    oppsWithActiveQuotes.add(q.OpportunityId);
                }
            }
    
            for (Opportunity opp : oppList) {
                if (movedToProposalOppIds.contains(opp.Id) && !oppsWithLineItems.contains(opp.Id)) {
                    opp.addError('Cannot update Opportunity Stage without price configuration');
                } else if (movedToNegotiationOppIds.contains(opp.Id) && !oppsWithActiveQuotes.contains(opp.Id)) {
                    opp.addError('Create a Quote before changing stage to Negotiation');
                }
            }
        }
    }      
    
    // Added by harkirat for restricting the change on oppLineItem field ER_Nb_Beneficiaries__c har v2
    public static void validateNbBeneficiaries(List<OpportunityLineItem> newOLIs) {

    Set<Id> oppIds = new Set<Id>();
    Set<Id> incomingOliIds = new Set<Id>();

    for (OpportunityLineItem oli : newOLIs) {
        if (oli.OpportunityId != null) {
            oppIds.add(oli.OpportunityId);
        }
        if (oli.Id != null) {
            incomingOliIds.add(oli.Id);
        }
    }

    if (oppIds.isEmpty()) {
        return;
    }

    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
        SELECT Id, Pricebook2.Name
        FROM Opportunity
        WHERE Id IN :oppIds
    ]);

    Map<Id, List<OpportunityLineItem>> oppToOLIs = new Map<Id, List<OpportunityLineItem>>();

    // Add existing DB OLIs except the ones being updated now
    for (OpportunityLineItem dbOli : [
        SELECT Id, OpportunityId, ER_Nb_Beneficiaries__c
        FROM OpportunityLineItem
        WHERE OpportunityId IN :oppIds
    ]) {
        if (incomingOliIds.contains(dbOli.Id)) {
            continue;
        }

        if (!oppToOLIs.containsKey(dbOli.OpportunityId)) {
            oppToOLIs.put(dbOli.OpportunityId, new List<OpportunityLineItem>());
        }
        oppToOLIs.get(dbOli.OpportunityId).add(dbOli);
    }

    // Add incoming records (inserted or updated values)
    for (OpportunityLineItem newOli : newOLIs) {
        if (!oppToOLIs.containsKey(newOli.OpportunityId)) {
            oppToOLIs.put(newOli.OpportunityId, new List<OpportunityLineItem>());
        }
        oppToOLIs.get(newOli.OpportunityId).add(newOli);
    }

    // Validate final state
    for (Id oppId : oppToOLIs.keySet()) {
        Opportunity opp = oppMap.get(oppId);

        if (opp == null || opp.Pricebook2.Name == null ||
            !opp.Pricebook2.Name.toLowerCase().contains('engagement')) {
            continue;
        }

        Set<Decimal> nbSet = new Set<Decimal>();

        for (OpportunityLineItem oli : oppToOLIs.get(oppId)) {
            if (oli.ER_Nb_Beneficiaries__c != null) {
                nbSet.add(oli.ER_Nb_Beneficiaries__c);
            }
        }

        if (nbSet.size() > 1) {
            for (OpportunityLineItem oli : newOLIs) {
                if (oli.OpportunityId == oppId) {
                    oli.addError('You must apply the same NB Beneficiaries among all the solutions for an Engagement opportunity');
                }
            }
        }
    }
}
}