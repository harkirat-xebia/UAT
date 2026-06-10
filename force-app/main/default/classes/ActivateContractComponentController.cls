public without sharing class ActivateContractComponentController {


        // new method added by harkirat for bulk contract activation
        public class FlowRequest {
        @InvocableVariable(required=true label='Contract IDs' 
                          description='List of Contract IDs to activate')
        public List<String> contractIds;
    }
    
    public class FlowResponse {
        @InvocableVariable(label='Job ID' description='Queueable Job ID for tracking')
        public String jobId;
        
        @InvocableVariable(label='Message' description='Status message')
        public String message;
        
        @InvocableVariable(label='Total Count' description='Total contracts queued')
        public Integer totalCount;
        
        @InvocableVariable(label='Is Success' description='Whether job was queued successfully')
        public Boolean isSuccess;
        @InvocableVariable public List<InvalidContractWrapper> invalidContracts;
        @InvocableVariable public List<Id> validIds;
        // NEW: Add JSON string version for LWC
        @InvocableVariable(label='Invalid Contracts JSON' description='JSON string of invalid contracts for LWC')
        public String invalidContractsJson;
        @InvocableVariable(label='Valid Contracts JSON')
        public String validContractsJson;
    }
    
    
    @InvocableMethod(label='Bulk Activate Contracts' 
                    description='Activates multiple contracts with external system integration'
                    category='Contract')
    public static List<FlowResponse> bulkActivateContracts(List<FlowRequest> requests) {
        List<FlowResponse> responses = new List<FlowResponse>();
        FlowResponse response = new FlowResponse();
        
        try {
            if (requests == null || requests.isEmpty() || 
                requests[0].contractIds == null || requests[0].contractIds.isEmpty()) {
                response.isSuccess = false;
                response.message = 'No Contract IDs provided. Please select at least one contract.';
                response.totalCount = 0;
                //Adding new
                response.invalidContractsJson = '[]';
                response.validContractsJson = '[]';
                responses.add(response);
                return responses;
            }
            
            // CHECK USER PERMISSION
            User currentUser = [
                SELECT Id, Can_activate_Engagement_Contracts__c 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            Boolean canActivateEngagementOnly = currentUser.Can_activate_Engagement_Contracts__c;
            
            List<String> contractIds = requests[0].contractIds;
            
            // Convert String IDs to Id type
            List<Id> contractIdList = new List<Id>();
            for (String idStr : contractIds) {
                try {
                    contractIdList.add((Id)idStr.trim());
                } catch (Exception e) {
                    System.debug('Invalid ID: ' + idStr);
                }
            }
            
            if (contractIdList.isEmpty()) {
                response.isSuccess = false;
                response.message = 'No valid Contract IDs found.';
                response.totalCount = 0;
                response.invalidContractsJson = '[]';
                response.validContractsJson = '[]';
                responses.add(response);
                return responses;
            }
            
            // Initialize
            List<Id> validIds = new List<Id>();
            List<InvalidContractWrapper> invalidContracts = new List<InvalidContractWrapper>();
            List<ValidContractWrapper> validContracts = new List<ValidContractWrapper>();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            
            // Bulk query contracts with ER_WS_StatusCode__c
            List<Contract> contracts = [
                SELECT Id, ContractNumber, Status, AccountId, Contract_Category__c, ER_WS_StatusCode__c,
                    Account.ER_Legal_Name__c, Account.ER_Registration_Number__c, Account.BillingStreet,
                    Account.BillingCity, Account.ER_Country_Code__c, Account.BillingPostalCode,
                    Account.ER_Language__c, Account.ER_Card_Client_Operational_System_ID__c,
                    CustomerSignedDate, CustomerSignedId, StartDate,
                    ER_Customer_Domain__c, ER_Program_Name__c, ER_Impacted_Beneficiaries__c,
                    ER_Onboarding_Method__c, ER_Start_Date__c, Pricebook2Id, Pricebook2.Name
                FROM Contract
                WHERE Id IN :contractIdList
            ];
        
        //BULKIFIED: Get all account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Contract c : contracts) {
            accountIds.add(c.AccountId);
        }
        
        //BULKIFIED: Query all validation data at once
        Map<Id, List<ErrorListWrapper>> contractErrorsMap = fetchErrorsBulk(accountIds, contractIdList);

            // Validate each contract
        for (Contract c : contracts) {
            Boolean hasError = false;
            List<String> contractErrors = new List<String>();
            
            //CHECK CONTRACT CATEGORY PERMISSION
            if (canActivateEngagementOnly) {
                // User can ONLY activate Engagement contracts
                if (c.Contract_Category__c != 'Engagement') {
                    contractErrors.add('• You do not have permission to activate ' + 
                                     (String.isBlank(c.Contract_Category__c) ? 'contracts without a category' : c.Contract_Category__c + ' contracts') + 
                                     '. You can only activate Engagement contracts.');
                    hasError = true;
                }
            }
            
            // CHECK STATUS - UPDATED LOGIC
            Boolean isValidStatus = false;
            String statusReason = '';
            
            if (c.Status == 'Draft') {
                isValidStatus = true;
            } else if (c.Status == 'Activated') {
                isValidStatus = true;
                statusReason = ' (Re-activation)';
            } else {
                isValidStatus = false;
                statusReason = ' - Invalid status for activation';
            }
            
            if (!isValidStatus) {
                contractErrors.add('• Contract cannot be activated. Current status: ' + c.Status + statusReason);
                hasError = true;
            }
            
            // GET PRE-FETCHED VALIDATION ERRORS
            if (!hasError && contractErrorsMap.containsKey(c.Id)) {
                List<ErrorListWrapper> errors = contractErrorsMap.get(c.Id);
                
                if (!errors.isEmpty()) {
                    // Contract has validation errors
                    for (ErrorListWrapper errorWrapper : errors) {
                        if (errorWrapper.data != null) {
                            for (ErrorInfoWrapper errorInfo : errorWrapper.data) {
                                contractErrors.add('• ' + errorInfo.sMessage);
                            }
                        }
                    }
                    hasError = true;
                }
            }
            
            // Add to appropriate list
            if (hasError) {
                InvalidContractWrapper wrapper = new InvalidContractWrapper();
                wrapper.contractId = c.Id;
                wrapper.contractNumber = c.ContractNumber;
                wrapper.status = c.Status;
                wrapper.recordUrl = baseUrl + '/' + c.Id;
                wrapper.errorDetails = String.join(contractErrors, '\n');
                wrapper.contractCategory = c.Contract_Category__c;
                wrapper.syncStatusCode = c.ER_WS_StatusCode__c;
                invalidContracts.add(wrapper);
            } else {
                // Contract is valid
                validIds.add(c.Id);
                
                ValidContractWrapper validWrapper = new ValidContractWrapper();
                validWrapper.contractId = c.Id;
                validWrapper.contractNumber = c.ContractNumber;
                validWrapper.status = c.Status + statusReason;
                validWrapper.recordUrl = baseUrl + '/' + c.Id;
                validWrapper.contractCategory = c.Contract_Category__c;
                validWrapper.syncStatusCode = c.ER_WS_StatusCode__c;
                validContracts.add(validWrapper);
            }
        }
        
        // If no valid contracts
        if (validIds.isEmpty()) {
            response.isSuccess = false;
            response.message = canActivateEngagementOnly 
                ? 'No valid Engagement contracts found. You can only activate Engagement contracts.' 
                : 'No valid contracts found. All contracts have validation errors or are already synchronized.';
            response.invalidContracts = invalidContracts;
            response.validContractsJson = JSON.serialize(validContracts);
            response.invalidContractsJson = JSON.serialize(invalidContracts);
            response.totalCount = 0;
            responses.add(response);
            return responses;
        }
        
        // Queue only valid contracts
        Id jobId = System.enqueueJob(
            new ActivateContractsQueueable(validIds, new List<Id>())
        );
        
        // Response
        response.isSuccess = true;
        response.jobId = jobId;
        response.totalCount = validIds.size();
        response.validIds = validIds;
        response.invalidContracts = invalidContracts;
        response.validContractsJson = JSON.serialize(validContracts);
        response.invalidContractsJson = JSON.serialize(invalidContracts);
        
        if (!invalidContracts.isEmpty()) {
            response.message = 
                'Processed ' + validIds.size() + ' contract(s) for activation/re-activation. ' +
                invalidContracts.size() + ' contract(s) failed validation.';
        } else {
            response.message = 'All contracts validated and queued successfully.';
        }
        
        System.debug('Enqueued job: ' + jobId + ' for ' + validIds.size() + ' contracts');
        System.debug('User can activate Engagement only: ' + canActivateEngagementOnly);
        
    } catch (Exception e) {
        response.isSuccess = false;
        response.message = 'Error: ' + e.getMessage();
        response.totalCount = 0;
        response.invalidContractsJson = '[]';
        response.validContractsJson = '[]';
        //System.debug('Error: ' + e.getMessage());
        //System.debug('Stack trace: ' + e.getStackTraceString());
    }
    
    responses.add(response);
    return responses;
}

// BULKIFIED VERSION - All validations included
public static Map<Id, List<ErrorListWrapper>> fetchErrorsBulk(Set<Id> accountIds, List<Id> contractIds) {
    Map<Id, List<ErrorListWrapper>> contractErrorsMap = new Map<Id, List<ErrorListWrapper>>();
    
    // Initialize map
    for (Id contractId : contractIds) {
        contractErrorsMap.put(contractId, new List<ErrorListWrapper>());
    }
    
    // 1. Query all contracts with full account data
    Map<Id, Contract> contractMap = new Map<Id, Contract>([
        SELECT Id, Name, AccountId, 
               Account.Name, Account.ER_Legal_Name__c, Account.ER_Registration_Number__c, 
               Account.ER_Language__c, Account.ER_Card_Client_Operational_System_ID__c, 
               Account.ER_Not_subject_to_VAT__c, Account.BillingStreet, Account.BillingCountry, 
               Account.BillingCity, Account.BillingPostalCode, Account.ER_Country_Code__c,
               ER_PaymentMethod2__c, LastModifiedDate, StartDate, CustomerSignedDate, 
               CustomerSignedId, ER_OpportunityId__c,
               ER_Customer_Domain__c, ER_Program_Name__c, ER_Impacted_Beneficiaries__c, 
               ER_Onboarding_Method__c, ER_Start_Date__c, Pricebook2Id, Pricebook2.Name
        FROM Contract
        WHERE Id IN :contractIds
    ]);
    
    // 2. Query all Contract Line Items
    Map<Id, List<ER_ContractLineItem__c>> contractLineItemsMap = new Map<Id, List<ER_ContractLineItem__c>>();
    for (ER_ContractLineItem__c cli : [
        SELECT Id, ER_Contract__c, ER_Solution__c
        FROM ER_ContractLineItem__c
        WHERE ER_Contract__c IN :contractIds AND ER_Solution__c != null
    ]) {
        if (!contractLineItemsMap.containsKey(cli.ER_Contract__c)) {
            contractLineItemsMap.put(cli.ER_Contract__c, new List<ER_ContractLineItem__c>());
        }
        contractLineItemsMap.get(cli.ER_Contract__c).add(cli);
    }
    
    // 3. Query all Financial Centers
    Map<Id, List<ER_Financial_Center__c>> accountFinancialCentersMap = new Map<Id, List<ER_Financial_Center__c>>();
    List<ER_Financial_Center__c> allFinancialCenters = [
        SELECT Id, ER_Account_Name__c, ER_Contact__c, 
               ER_Bank_Account__r.ER_BIC__c, ER_Bank_Account__r.ER_IBAN__c,
               ER_Invoicing_Country_Code__c, ER_Invoicing_Street__c, 
               ER_Invoicing_Zip_Code__c, ER_Invoicing_City__c
        FROM ER_Financial_Center__c
        WHERE ER_Account_Name__c IN :accountIds
    ];
    
    Set<Id> allFinancialCenterIds = new Set<Id>();
    for (ER_Financial_Center__c fc : allFinancialCenters) {
        if (!accountFinancialCentersMap.containsKey(fc.ER_Account_Name__c)) {
            accountFinancialCentersMap.put(fc.ER_Account_Name__c, new List<ER_Financial_Center__c>());
        }
        accountFinancialCentersMap.get(fc.ER_Account_Name__c).add(fc);
        allFinancialCenterIds.add(fc.Id);
    }
    
    // 4. Query all Delivery Sites
    Map<Id, List<ER_Delivery_Site__c>> fcDeliverySitesMap = new Map<Id, List<ER_Delivery_Site__c>>();
    List<ER_Delivery_Site__c> allDeliverySites = new List<ER_Delivery_Site__c>();
    
    if (!allFinancialCenterIds.isEmpty()) {
        allDeliverySites = [
            SELECT Id, ER_Financial_Center__c, ER_Country__c, ER_Country_Code__c, 
                   ER_Delivery_Contact__c, ER_City__c, ER_Zip_Code__c, ER_Street__c
            FROM ER_Delivery_Site__c
            WHERE ER_Financial_Center__c IN :allFinancialCenterIds
        ];
        
        for (ER_Delivery_Site__c ds : allDeliverySites) {
            if (!fcDeliverySitesMap.containsKey(ds.ER_Financial_Center__c)) {
                fcDeliverySitesMap.put(ds.ER_Financial_Center__c, new List<ER_Delivery_Site__c>());
            }
            fcDeliverySitesMap.get(ds.ER_Financial_Center__c).add(ds);
        }
    }
    
    //5. Query all Distribution Points
    Set<Id> allDeliverySiteIds = new Set<Id>();
    for (ER_Delivery_Site__c ds : allDeliverySites) {
        allDeliverySiteIds.add(ds.Id);
    }
    
    Map<Id, List<ER_Distribution_Point__c>> dsDistributionPointsMap = new Map<Id, List<ER_Distribution_Point__c>>();
    if (!allDeliverySiteIds.isEmpty()) {
        for (ER_Distribution_Point__c dp : [
            SELECT Id, ER_Delivery_Site__c, ER_Country__c, ER_Country_Code__c, 
                   ER_City__c, ER_Zip_Code__c, ER_Street__c
            FROM ER_Distribution_Point__c
            WHERE ER_Delivery_Site__c IN :allDeliverySiteIds
        ]) {
            if (!dsDistributionPointsMap.containsKey(dp.ER_Delivery_Site__c)) {
                dsDistributionPointsMap.put(dp.ER_Delivery_Site__c, new List<ER_Distribution_Point__c>());
            }
            dsDistributionPointsMap.get(dp.ER_Delivery_Site__c).add(dp);
        }
    }
    
    // NOW VALIDATE EACH CONTRACT
    for (Id contractId : contractIds) {
        List<ErrorListWrapper> errors = new List<ErrorListWrapper>();
        Contract contract = contractMap.get(contractId);
        
        if (contract == null) {
            errors.add(createErrorWrapper('Contract', 'Contract Record', 'Contract record not found', 
                '/lightning/r/Contract/' + contractId + '/view', 'Contract'));
            contractErrorsMap.put(contractId, errors);
            continue;
        }
        
        String cardId = contract.Account.ER_Card_Client_Operational_System_ID__c;
        Boolean isEngagementPricebook = contract.Pricebook2Id != null 
            && contract.Pricebook2 != null 
            && String.isNotBlank(contract.Pricebook2.Name) 
            && contract.Pricebook2.Name.contains('Engagement');
        
        //ENGAGEMENT CONTRACT VALIDATIONS
        if (isEngagementPricebook) {
            if (contract.ER_Customer_Domain__c == null) {
                errors.add(createErrorWrapper('Contract', 'Customer Domain', 
                    'Customer Domain is missing for the Contract', 
                    '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
            if (contract.ER_Program_Name__c == null) {
                errors.add(createErrorWrapper('Contract', 'Program Name', 
                    'Program Name is missing for the Contract', 
                    '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
            if (contract.ER_Impacted_Beneficiaries__c == null) {
                errors.add(createErrorWrapper('Contract', 'Impacted Beneficiaries', 
                    'Impacted Beneficiaries is missing for the Contract', 
                    '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
            if (contract.ER_Onboarding_Method__c == null) {
                errors.add(createErrorWrapper('Contract', 'Onboarding Method', 
                    'Onboarding Method is missing for the Contract', 
                    '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
            if (contract.ER_Start_Date__c == null) {
                errors.add(createErrorWrapper('Contract', 'Onboarding Date', 
                    'Onboarding Date is missing for the Contract', 
                    '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
        }
        
        //ACCOUNT VALIDATIONS
        if (contract.Account.ER_Legal_Name__c == null) {
            errors.add(createErrorWrapper('Account', 'Legal Name', 
                'Legal name is missing for the Account', 
                '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Name'));
        }
        if (contract.Account.ER_Registration_Number__c == null) {
            errors.add(createErrorWrapper('Account', 'Company Registration Number', 
                'Company Registration Number is missing for the Account', 
                '/lightning/r/Account/' + contract.AccountId + '/view', 'Registration Number'));
        }
        if (contract.Account.BillingStreet == null) {
            errors.add(createErrorWrapper('Account', 'Legal Street', 
                'Legal street is missing for the Account', 
                '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
        }
        if (contract.Account.BillingCity == null) {
            errors.add(createErrorWrapper('Account', 'Legal City', 
                'Legal city is missing for the Account', 
                '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
        }
        if (contract.Account.ER_Country_Code__c == null) {
            errors.add(createErrorWrapper('Account', 'Legal Country', 
                'Legal country code is missing for the Account', 
                '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
        }
        if (contract.Account.BillingPostalCode == null) {
            errors.add(createErrorWrapper('Account', 'Legal Postal Code', 
                'Legal postal code is missing for the Account', 
                '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
        }
        if (contract.Account.ER_Language__c == null) {
            errors.add(createErrorWrapper('Account', 'Language', 
                'Language is missing for the Account', 
                '/lightning/r/Account/' + contract.AccountId + '/view', 'Account'));
        }
        
        //CONTRACT VALIDATIONS
        if (contract.CustomerSignedDate == null) {
            errors.add(createErrorWrapper('Contract', 'Customer Signed Date', 
                'Customer Signed Date is missing for the Contract', 
                '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
        }
        if (contract.CustomerSignedId == null) {
            errors.add(createErrorWrapper('Contract', 'Customer Signed Id', 
                'Customer Signed Id is missing for the Contract', 
                '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
        }
        if (contract.StartDate == null) {
            errors.add(createErrorWrapper('Contract', 'Start Date', 
                'Start Date is missing for the Contract', 
                '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
        }
        
        //CONTRACT LINE ITEMS VALIDATION
        if (!contractLineItemsMap.containsKey(contractId) || contractLineItemsMap.get(contractId).isEmpty()) {
            errors.add(createErrorWrapper('ER_ContractLineItem__c', 'Contract Line Items', 
                'No contract line items found with a solution', 
                '/lightning/r/Contract/' + contractId + '/view', 'Contract Line Items'));
        }
        
        //FINANCIAL CENTER VALIDATIONS (only if not synced)
        if (cardId == null) {
            List<ER_Financial_Center__c> financialCenters = accountFinancialCentersMap.get(contract.AccountId);
            
            if (financialCenters == null || financialCenters.isEmpty()) {
                errors.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 
                    'No Financial Centers found for this Account', 
                    '/lightning/r/Account/' + contract.AccountId + '/view', 'Financial Center'));
            } else {
                for (ER_Financial_Center__c fc : financialCenters) {
                    if (fc.ER_Contact__c == null) {
                        errors.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 
                            'No Contact found for the Financial Center', 
                            '/lightning/r/ER_Financial_Center__c/' + fc.Id + '/view', 'Financial Center'));
                    }
                    if (fc.ER_Invoicing_Country_Code__c == null) {
                        errors.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 
                            'Invoicing Country code not found on Financial Center', 
                            '/lightning/r/ER_Financial_Center__c/' + fc.Id + '/view', 'Financial Center'));
                    }
                    if (fc.ER_Invoicing_City__c == null) {
                        errors.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 
                            'Invoicing City not found on Financial Center', 
                            '/lightning/r/ER_Financial_Center__c/' + fc.Id + '/view', 'Financial Center'));
                    }
                    if (fc.ER_Invoicing_Zip_Code__c == null) {
                        errors.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 
                            'Invoicing Zip Code not found on Financial Center', 
                            '/lightning/r/ER_Financial_Center__c/' + fc.Id + '/view', 'Financial Center'));
                    }
                    if (fc.ER_Invoicing_Street__c == null) {
                        errors.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 
                            'Invoicing Street not found on Financial Center', 
                            '/lightning/r/ER_Financial_Center__c/' + fc.Id + '/view', 'Financial Center'));
                    }
                    
                    // DELIVERY SITES VALIDATION
                    List<ER_Delivery_Site__c> deliverySites = fcDeliverySitesMap.get(fc.Id);
                    if (deliverySites != null && !deliverySites.isEmpty()) {
                        for (ER_Delivery_Site__c ds : deliverySites) {
                            if (ds.ER_Country_Code__c == null) {
                                errors.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 
                                    'Delivery Site Country code is missing', 
                                    '/lightning/r/ER_Delivery_Site__c/' + ds.Id + '/view', 'Delivery Sites'));
                            }
                            if (ds.ER_Delivery_Contact__c == null) {
                                errors.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 
                                    'No Delivery Contact found for this delivery site', 
                                    '/lightning/r/ER_Delivery_Site__c/' + ds.Id + '/view', 'Delivery Sites'));
                            }
                            if (ds.ER_City__c == null) {
                                errors.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 
                                    'No City found for this delivery site', 
                                    '/lightning/r/ER_Delivery_Site__c/' + ds.Id + '/view', 'Delivery Sites'));
                            }
                            if (ds.ER_Zip_Code__c == null) {
                                errors.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 
                                    'No Zip code found for this delivery site', 
                                    '/lightning/r/ER_Delivery_Site__c/' + ds.Id + '/view', 'Delivery Sites'));
                            }
                            if (ds.ER_Street__c == null) {
                                errors.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 
                                    'No Street found for this delivery site', 
                                    '/lightning/r/ER_Delivery_Site__c/' + ds.Id + '/view', 'Delivery Sites'));
                            }
                            
                            // DISTRIBUTION POINTS VALIDATION
                            List<ER_Distribution_Point__c> distributionPoints = dsDistributionPointsMap.get(ds.Id);
                            if (distributionPoints != null && !distributionPoints.isEmpty()) {
                                for (ER_Distribution_Point__c dp : distributionPoints) {
                                    if (dp.ER_Country_Code__c == null) {
                                        errors.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 
                                            'Distribution Point country code is missing', 
                                            '/lightning/r/ER_Distribution_Point__c/' + dp.Id + '/view', 'Distribution Point'));
                                    }
                                    if (dp.ER_City__c == null) {
                                        errors.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 
                                            'No City found for this distribution point', 
                                            '/lightning/r/ER_Distribution_Point__c/' + dp.Id + '/view', 'Distribution Point'));
                                    }
                                    if (dp.ER_Zip_Code__c == null) {
                                        errors.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 
                                            'No Zip code found for this distribution point', 
                                            '/lightning/r/ER_Distribution_Point__c/' + dp.Id + '/view', 'Distribution Point'));
                                    }
                                    if (dp.ER_Street__c == null) {
                                        errors.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 
                                            'No Street found for this distribution point', 
                                            '/lightning/r/ER_Distribution_Point__c/' + dp.Id + '/view', 'Distribution Point'));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        contractErrorsMap.put(contractId, errors);
    }
    
    return contractErrorsMap;
}
    //method ends

    // new method for lwc
    @AuraEnabled
public static ActivationResult activateContractsFromLWC(List<String> contractIds) {
    ActivationResult result = new ActivationResult();
    result.invalidContracts = new List<InvalidContractWrapper>();
    result.validIds = new List<String>();
    result.totalCount = 0;
    
    try {
        if (contractIds == null || contractIds.isEmpty()) {
            result.isSuccess = false;
            result.message = 'No Contract IDs provided. Please select at least one contract.';
            return result;
        }
        
        // Convert String IDs to Id type
        List<Id> contractIdList = new List<Id>();
        for (String idStr : contractIds) {
            try {
                contractIdList.add((Id)idStr.trim());
            } catch (Exception e) {
                System.debug('Invalid ID: ' + idStr);
            }
        }
        
        if (contractIdList.isEmpty()) {
            result.isSuccess = false;
            result.message = 'No valid Contract IDs found.';
            return result;
        }
        
        // Initialize
        List<Id> validIds = new List<Id>();
        List<InvalidContractWrapper> invalidContracts = new List<InvalidContractWrapper>();
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        
        // Bulk query contracts
        List<Contract> contracts = [
            SELECT Id, ContractNumber, Status
            FROM Contract
            WHERE Id IN :contractIdList
        ];
        
        for (Contract c : contracts) {
            if (c.Status == 'Draft') {
                validIds.add(c.Id);
            } else {
                InvalidContractWrapper wrapper = new InvalidContractWrapper();
                wrapper.contractId = c.Id;
                wrapper.contractNumber = c.ContractNumber;
                wrapper.status = c.Status;
                wrapper.recordUrl = baseUrl + '/' + c.Id;
                invalidContracts.add(wrapper);
            }
        }
        
        // If no valid contracts
        if (validIds.isEmpty()) {
            result.isSuccess = false;
            result.message = 'No valid Draft contracts found. Please review invalid records.';
            result.invalidContracts = invalidContracts;
            result.totalCount = 0;
            return result;
        }
        
        // Queue only valid contracts
        Id jobId = System.enqueueJob(
            new ActivateContractsQueueable(validIds, new List<Id>())
        );
        
        // Response
        result.isSuccess = true;
        result.jobId = jobId;
        result.totalCount = validIds.size();
        result.validIds = new List<String>();
        for (Id vid : validIds) {
            result.validIds.add(String.valueOf(vid));
        }
        result.invalidContracts = invalidContracts;
        
        if (!invalidContracts.isEmpty()) {
            result.message = 
                'Processed ' + validIds.size() + ' contract(s). ' +
                invalidContracts.size() + ' contract(s) skipped (not in Draft).';
        } else {
            result.message = 'All contracts processed successfully.';
        }
        
        System.debug('Enqueued job: ' + jobId + ' for ' + validIds.size() + ' contracts');
        
    } catch (Exception e) {
        result.isSuccess = false;
        result.message = 'Error: ' + e.getMessage();
        result.totalCount = 0;
        System.debug('Error enqueueing job: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
    
    return result;
}

// Add this wrapper class for LWC response
public class ActivationResult {
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public String message;
    @AuraEnabled public String jobId;
    @AuraEnabled public Integer totalCount;
    @AuraEnabled public List<String> validIds;
    @AuraEnabled public List<InvalidContractWrapper> invalidContracts;
}

// new method ends
    @AuraEnabled
    public static Map<String, Object> activateContract(Id contractId){
        Map<String, Object> responseMap = new Map<String, Object>();
        try {
            SyncClientContractService service = new SyncClientContractService();
            Contract cont = [Select Id, AccountId, Contract_Category__c, Account.ER_Card_Client_Operational_System_ID__c FROM Contract WHERE Id =:contractId LIMIT 1];
            //In Contract_Category__c, Savings is the api name and actual value is Engagement.
            /*if (cont.Contract_Category__c == 'Savings') {
                cont.Status = 'Activated';
                update cont;
                return new Map<String, Object>();
            }*/ 
            if(cont.Account.ER_Card_Client_Operational_System_ID__c == null){
                responseMap = service.createClientCallout(contractId);
            }else{
                responseMap = service.createClientContractCallout(cont.AccountId, contractId); 
            }
            return responseMap;
        } catch (Exception e) {
            System.debug('e msg'+e.getMessage());
            System.debug('e line'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Adding new method by harkirat to bulkify the contracts sync
    @AuraEnabled
    public static void activateContractsAsync(List<Id> contractIds) {
        System.enqueueJob(new ActivateContractsQueueable(contractIds, null));
    }
    /* @AuraEnabled
    public static void updateContractStatus(Id contractId){
        Map<String, Object> responseMap = new Map<String, Object>();
        try {
            Contract cont = [Select Id, Status, ER_OpportunityId__r.StageName, ER_OpportunityId__c, ER_OpportunityId__r.ER_Won_Reason__c FROM Contract WHERE Id =:contractId LIMIT 1];
            cont.Status = 'Activated';
            update cont;
            if(cont.ER_OpportunityId__c != null){
                Opportunity opp = new Opportunity();
                opp.Id = cont.ER_OpportunityId__c;
                opp.StageName = 'Closed Won';
                opp.ER_Won_Reason__c = 'Other';
                update opp;
            }            

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    } */
    @AuraEnabled
    public static List<ContractDetailsWrapper> fetchContractDetails(Id contractId) {
        try {
            List<ContractDetailsWrapper> contDetailsWrapperList = new List<ContractDetailsWrapper>();

            // Query the contract records
            List<Contract> contracts = [
                SELECT
                    Id,
                    RecordTypeId,
                    ER_Business_Unit__c,
                    ER_InvoicingFrequency2__c,
                    ER_ReimbursementTerm2__c,
                    CustomerSigned.Email,
                    CustomerSignedId,
                    ERBE_Reimbursement_Statement_Frequency__c,
                    Status,
                    ER_Indexation__c,
                    ER_OppIndexation2__c,
                    ER_PaymentTerms2__c,
                    ER_PaymentMethod2__c,
                    Account.ER_VIP__c,
                    Subscription__c,
                    ERBE_Reimbursement_statement_Support__c,
                    AccountId,
                    Account.Name,
                    StartDate,
                    EndDate,
                    ER_OpportunityId__c,
                    ER_OpportunityId__r.ER_IsAmended__c,
                    ER_OpportunityId__r.ER_AmendedFromContract__c,
                    ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId,
                    ContractNumber,
                    ER_Creation_date_in_OS__c,
                    CustomerSignedDate,
                    ER_OpportunityId__r.ER_AmendedFromContract__r.StartDate,
                    ER_Contract_Type__c,
                    ER_Original_Agreement__c,
                    ER_Original_Agreement__r.Status,
                    ER_Original_Agreement__r.ER_Contract_Type__c,
                    RecordType.DeveloperName,
                    ER_OpportunityId__r.ER_SmartER_Context__c,
                    ER_BUPicklist__c,
                    (
                        SELECT
                            Id,
                            ER_Contract__c,
                            Name,
                            ER_Solution__c,
                            ER_ProductCode__c,
                            ER_Creation_date_in_OS__c,
                            ER_Product2__c,
                            ER_Product2__r.Name
                        FROM ER_ContractLineItems__r
                    )
                FROM Contract
                WHERE Id = :contractId
            ];

            // Populate the wrapper list
            for (Contract cont : contracts) {
                ContractDetailsWrapper wrapper = new ContractDetailsWrapper();
                wrapper.ContractId = cont.Id;
                wrapper.RecordTypeId = cont.RecordTypeId;
                wrapper.ER_Business_Unit = cont.ER_Business_Unit__c;
                wrapper.ER_InvoicingFrequency2 = cont.ER_InvoicingFrequency2__c;
                wrapper.ER_ReimbursementTerm2 = cont.ER_ReimbursementTerm2__c;
                wrapper.CustomerSignedEmail = (cont.CustomerSigned != null) ? cont.CustomerSigned.Email : null;
                wrapper.CustomerSignedId = cont.CustomerSignedId;
                wrapper.ERBE_Reimbursement_Statement_Frequency = cont.ERBE_Reimbursement_Statement_Frequency__c;
                wrapper.Status = cont.Status;
                wrapper.ER_PaymentTerms2 = cont.ER_PaymentTerms2__c;
                wrapper.ER_PaymentMethod2 = cont.ER_PaymentMethod2__c;
                wrapper.AccountER_VIP = (cont.Account != null) ? cont.Account.ER_VIP__c : null;
                wrapper.Subscription = cont.Subscription__c;
                wrapper.ERBE_Reimbursement_statement_Support = cont.ERBE_Reimbursement_statement_Support__c;
                wrapper.AccountId = cont.AccountId;
                wrapper.AccountName = (cont.Account != null) ? cont.Account.Name : null;
                wrapper.StartDate = cont.StartDate;
                wrapper.EndDate = cont.EndDate;
                wrapper.ER_OpportunityId = cont.ER_OpportunityId__c;
                wrapper.ER_OpportunityIsAmended = (cont.ER_OpportunityId__r != null) ? cont.ER_OpportunityId__r.ER_IsAmended__c : null;
                wrapper.ER_AmendedFromContract = (cont.ER_OpportunityId__r != null) ? cont.ER_OpportunityId__r.ER_AmendedFromContract__c : null;
                wrapper.ER_AmendedFromOpportunityContractId = (cont.ER_OpportunityId__r != null && cont.ER_OpportunityId__r.ER_AmendedFromOpportunity__r != null) ? cont.ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId : null;
                wrapper.ContractNumber = cont.ContractNumber;
                wrapper.ER_Creation_date_in_OS = cont.ER_Creation_date_in_OS__c;
                wrapper.CustomerSignedDate = cont.CustomerSignedDate;
                wrapper.ER_AmendedFromContractStartDate = (cont.ER_OpportunityId__r != null && cont.ER_OpportunityId__r.ER_AmendedFromContract__r != null) ? cont.ER_OpportunityId__r.ER_AmendedFromContract__r.StartDate : null;
                wrapper.ER_Contract_Type = cont.ER_Contract_Type__c;
                wrapper.ER_Original_Agreement = cont.ER_Original_Agreement__c;
                wrapper.ER_Original_AgreementStatus = (cont.ER_Original_Agreement__r != null) ? cont.ER_Original_Agreement__r.Status : null;
                wrapper.ER_Original_AgreementType = (cont.ER_Original_Agreement__r != null) ? cont.ER_Original_Agreement__r.ER_Contract_Type__c : null;
                wrapper.RecordTypeDeveloperName = cont.RecordType.DeveloperName;
                wrapper.ER_BUPicklist = cont.ER_BUPicklist__c;

                // Map related list of ER_ContractLineItems__r to wrapper class
                wrapper.ContractLineItems = new List<ContractLineItemWrapper>();
                for (ER_ContractLineItem__c item : cont.ER_ContractLineItems__r) {
                    ContractLineItemWrapper lineItemWrapper = new ContractLineItemWrapper();
                    lineItemWrapper.Id = item.Id;
                    lineItemWrapper.ER_Contract = item.ER_Contract__c;
                    lineItemWrapper.Name = item.Name;
                    lineItemWrapper.ER_Solution = item.ER_Solution__c;
                    lineItemWrapper.ER_ProductCode = item.ER_ProductCode__c;
                    lineItemWrapper.ER_Creation_date_in_OS = item.ER_Creation_date_in_OS__c;
                    lineItemWrapper.ER_Product2 = item.ER_Product2__c;
                    lineItemWrapper.ProductName = (item.ER_Product2__r != null) ? item.ER_Product2__r.Name : null;
                    wrapper.ContractLineItems.add(lineItemWrapper);
                }

                contDetailsWrapperList.add(wrapper);
            }

            return contDetailsWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Wrapper class for Contract details
    public class ContractDetailsWrapper {
        @AuraEnabled public Id ContractId {get; set;}
        @AuraEnabled public Id RecordTypeId {get; set;}
        @AuraEnabled public String ER_Business_Unit {get; set;}
        @AuraEnabled public String ER_InvoicingFrequency2 {get; set;}
        @AuraEnabled public String ER_ReimbursementTerm2 {get; set;}
        @AuraEnabled public String CustomerSignedEmail {get; set;}
        @AuraEnabled public Id CustomerSignedId {get; set;}
        @AuraEnabled public String ERBE_Reimbursement_Statement_Frequency {get; set;}
        @AuraEnabled public String Status {get; set;}
        @AuraEnabled public String ER_PaymentTerms2 {get; set;}
        @AuraEnabled public String ER_PaymentMethod2 {get; set;}
        @AuraEnabled public Boolean AccountER_VIP {get; set;}
        @AuraEnabled public String Subscription {get; set;}
        @AuraEnabled public String ERBE_Reimbursement_statement_Support {get; set;}
        @AuraEnabled public Id AccountId {get; set;}
        @AuraEnabled public String AccountName {get; set;}
        @AuraEnabled public Date StartDate {get; set;}
        @AuraEnabled public Date EndDate {get; set;}
        @AuraEnabled public Id ER_OpportunityId {get; set;}
        @AuraEnabled public Boolean ER_OpportunityIsAmended {get; set;}
        @AuraEnabled public Id ER_AmendedFromContract {get; set;}
        @AuraEnabled public Id ER_AmendedFromOpportunityContractId {get; set;}
        @AuraEnabled public String ContractNumber {get; set;}
        @AuraEnabled public DateTime ER_Creation_date_in_OS {get; set;}
        @AuraEnabled public Date CustomerSignedDate {get; set;}
        @AuraEnabled public Date ER_AmendedFromContractStartDate {get; set;}
        @AuraEnabled public String ER_Contract_Type {get; set;}
        @AuraEnabled public Id ER_Original_Agreement {get; set;}
        @AuraEnabled public String ER_Original_AgreementStatus {get; set;}
        @AuraEnabled public String ER_Original_AgreementType {get; set;}
        @AuraEnabled public String RecordTypeDeveloperName {get; set;}
        @AuraEnabled public String ER_BUPicklist {get; set;}
        @AuraEnabled public List<ContractLineItemWrapper> ContractLineItems {get; set;}
    }

    // Wrapper class for Contract Line Items
    public class ContractLineItemWrapper {
        @AuraEnabled public Id Id {get; set;}
        @AuraEnabled public Id ER_Contract {get; set;}
        @AuraEnabled public String Name {get; set;}
        @AuraEnabled public String ER_Solution {get; set;}
        @AuraEnabled public String ER_ProductCode {get; set;}
        @AuraEnabled public DateTime ER_Creation_date_in_OS {get; set;}
        @AuraEnabled public Id ER_Product2 {get; set;}
        @AuraEnabled public String ProductName {get; set;}
    }
    @AuraEnabled
    public static List<ErrorListWrapper> fetchErrors(Id accountId, Id contractId) {
        List<ErrorListWrapper> errorWrapperList = new List<ErrorListWrapper>();
    
        Contract contract;
        List<ER_ContractLineItem__c> contractLineItemList = new List<ER_ContractLineItem__c>();
        List<Contact> contactList = new List<Contact>();
        List<ER_Financial_Center__c> financialCenterList = new List<ER_Financial_Center__c>(); 
        Map<Id, ER_Delivery_Site__c> deliverySiteMap = new Map<Id, ER_Delivery_Site__c>();
        Map<Id, ER_Distribution_Point__c> distributionPointMap = new Map<Id, ER_Distribution_Point__c>();
        Set<Id> financialCenterIds = new Set<Id>();
        Set<Id> deliverySiteIds = new Set<Id>();
        String paymentMethod;
        String cardId;
    
        // Fetch Contract
        try {
            contract = [
                SELECT Id, Name, AccountId, Account.Name, Account.ER_Legal_Name__c, Account.ER_Registration_Number__c, Account.ER_Language__c, Account.ER_Card_Client_Operational_System_ID__c, Account.ER_Not_subject_to_VAT__c, ER_PaymentMethod2__c,
                       LastModifiedDate, StartDate, CustomerSignedDate, ER_OpportunityId__r.Invoicing_Contact__c, ER_OpportunityId__r.Primary_Contact__c, CustomerSignedId, Account.BillingStreet,
                       Account.BillingCountry, Account.BillingCity, Account.BillingPostalCode, Account.ER_Country_Code__c, ER_OpportunityId__c, ER_Customer_Domain__c, ER_Program_Name__c, ER_Impacted_Beneficiaries__c, ER_Onboarding_Method__c, ER_Start_Date__c, Pricebook2Id, Pricebook2.Name 
                FROM Contract
                WHERE Id = :contractId
                LIMIT 1
            ];
            paymentMethod = contract.ER_PaymentMethod2__c;
            cardId = contract.Account.ER_Card_Client_Operational_System_ID__c;
            
            //Check for Engagement Contract
            Boolean isEngagementPricebook =
            contract.Pricebook2Id != null &&
            contract.Pricebook2 != null &&
            String.isNotBlank(contract.Pricebook2.Name) &&
            contract.Pricebook2.Name.contains('Engagement');

            
            // Validate Contract fields
            if (isEngagementPricebook) {
            if (contract.ER_Customer_Domain__c == null) {
    			errorWrapperList.add(createErrorWrapper('Contract','Customer Domain', 'Customer Domain is missing for the Contract','/lightning/r/Contract/' + contract.Id + '/view','Contract' ));
            }
            if (contract.ER_Program_Name__c == null) {
    			errorWrapperList.add(createErrorWrapper('Contract','Program Name','Program Name is missing for the Contract','/lightning/r/Contract/' + contract.Id + '/view','Contract'));
            }

            if (contract.ER_Impacted_Beneficiaries__c == null) {
                errorWrapperList.add(createErrorWrapper('Contract','Impacted Beneficiaries','Impacted Beneficiaries is missing for the Contract','/lightning/r/Contract/' + contract.Id + '/view','Contract'));
            }

            if (contract.ER_Onboarding_Method__c == null) {
                errorWrapperList.add(createErrorWrapper('Contract','Onboarding Method','Onboarding Method is missing for the Contract','/lightning/r/Contract/' + contract.Id + '/view','Contract'));
            }

            if (contract.ER_Start_Date__c == null) {
                errorWrapperList.add(createErrorWrapper('Contract','Onboarding Date','Onboarding Date is missing for the Contract','/lightning/r/Contract/' + contract.Id + '/view','Contract'));
            }
            }

            // Validate Account Billing Details
            if (contract.Account.ER_Legal_Name__c == null) {
                errorWrapperList.add(createErrorWrapper('Account', 'Legal Name', 'Legal name is missing for the Account', '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Name'));
            }
            if (contract.Account.ER_Registration_Number__c == null) {
                errorWrapperList.add(createErrorWrapper('Account', 'Company Registration Number', 'Company Registration Number is missing for the Account', '/lightning/r/Account/' + contract.AccountId + '/view', 'Registration Number'));
            }
            if (contract.Account.BillingStreet == null) {
                errorWrapperList.add(createErrorWrapper('Account', 'Legal Street', 'Legal street is missing for the Account', '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
            }
            if (contract.Account.BillingCity == null) {
                errorWrapperList.add(createErrorWrapper('Account', 'Legal City', 'Legal city is missing for the Account', '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
            }
            if (contract.Account.ER_Country_Code__c == null) {
                errorWrapperList.add(createErrorWrapper('Account', 'Legal Country', 'Legal country code is missing for the Account', '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
            }
            if (contract.Account.BillingPostalCode == null) {
                errorWrapperList.add(createErrorWrapper('Account', 'Legal Postal Code', 'Legal postal code is missing for the Account', '/lightning/r/Account/' + contract.AccountId + '/view', 'Legal Address'));
            }
            if (contract.CustomerSignedDate == null) {
                errorWrapperList.add(createErrorWrapper('Contract', 'Customer Signed Date', 'Customer Signed Date is missing for the Contract', '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
            if (contract.CustomerSignedId == null) {
                errorWrapperList.add(createErrorWrapper('Contract', 'Customer Signed Id', 'Customer Signed Id is missing for the Contract', '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
            if (contract.StartDate == null) {
                errorWrapperList.add(createErrorWrapper('Contract', 'Start Date', 'Start Date is missing for the Contract', '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
            }
            if (contract.Account.ER_Language__c == null) {
                errorWrapperList.add(createErrorWrapper('Account', 'Language', 'Language is missing for the Account', '/lightning/r/Account/' + contract.AccountId + '/view', 'Account'));
            }
        } catch (Exception e) {
            errorWrapperList.add(createErrorWrapper('Contract', 'Contract Record', 'Contract record not found', '/lightning/r/Contract/' + contract.Id + '/view', 'Contract'));
        }
    
        // Fetch Contract Line Items
        try {
            contractLineItemList = [
                SELECT Id, ER_Solution__c
                FROM ER_ContractLineItem__c
                WHERE ER_Contract__c = :contractId AND ER_Solution__c != null
            ];
            if (contractLineItemList.isEmpty()) {
                errorWrapperList.add(createErrorWrapper('ER_ContractLineItem__c', 'Contract Line Items', 'No contract line items found with a solution', '/lightning/r/Contract/' + contractId + '/view', 'Contract Line Items'));
            }
        } catch (Exception e) {
            errorWrapperList.add(createErrorWrapper('ER_ContractLineItem__c', 'Contract Line Items', 'Error fetching contract line items', '/lightning/r/Contract/' + contractId + '/view', 'Contract Line Items'));
        }
    
        // Fetch Contacts
        // Commenting this temporily
        /*try {
            Id oppId = contract.ER_OpportunityId__c;
        
            // Fetch Opportunity Contact Roles with their Contacts
            List<OpportunityContactRole> oppRoles = [
                SELECT Id, Role, Contact.Id, Contact.Email, Contact.FirstName, Contact.LastName, Contact.ER_Language__c,Contact.ER_Status__c
                FROM OpportunityContactRole
                WHERE OpportunityId = :oppId AND Contact.ER_Status__c = 'Active'
            ];
        
            if (oppRoles.isEmpty()) {
                errorWrapperList.add(createErrorWrapper('Contact Role', 'Opportunity Contacts', 'No contacts found for the opportunity', '/lightning/r/Opportunity/' + oppId + '/view', 'Contacts'));
            } else {
                Boolean hasPrimaryContact = false;
                Boolean hasInvoicingContact = false;

                for (OpportunityContactRole ocr : oppRoles) {
                    if (ocr.Role == 'Primary Contact') {
                        hasPrimaryContact = true;
                    }
                    if (ocr.Role == 'Invoicing Contact') {
                        hasInvoicingContact = true;
                    }
                }
        
                for (OpportunityContactRole ocr : oppRoles) {
                    Contact con = ocr.Contact;
                    if (con != null) {
                        if (con.Email == null) {
                            errorWrapperList.add(createErrorWrapper('Contact', 'Email', 'Email is missing for the Contact', '/lightning/r/Contact/' + con.Id + '/view', 'Contacts'));
                        }
                        if (con.ER_Language__c == null) {
                            errorWrapperList.add(createErrorWrapper('Contact', 'Language', 'Language is missing for the Contact', '/lightning/r/Contact/' + con.Id + '/view', 'Contacts'));
                        }
                        if (con.FirstName == null) {
                            errorWrapperList.add(createErrorWrapper('Contact', 'First Name', 'First Name is missing for the Contact', '/lightning/r/Contact/' + con.Id + '/view', 'Contacts'));
                        }
                        if (con.LastName == null) {
                            errorWrapperList.add(createErrorWrapper('Contact', 'Last Name', 'Last Name is missing for the Contact', '/lightning/r/Contact/' + con.Id + '/view', 'Contacts'));
                        }
                    }
                }
        
                if (!hasPrimaryContact) {
                    errorWrapperList.add(createErrorWrapper('Contact Role', 'Primary Contact', 'No contact with role Primary Contact found', '/lightning/r/Opportunity/' + oppId + '/view', 'Contacts'));
                }
                if (!hasInvoicingContact) {
                    errorWrapperList.add(createErrorWrapper('Contact Role', 'Invoicing Contact', 'No contact with role Invoicing Contact found', '/lightning/r/Opportunity/' + oppId + '/view', 'Contacts'));
                }
            }
        } catch (Exception e) {
            errorWrapperList.add(createErrorWrapper('Contact Role', 'Opportunity Contacts', 'Error fetching contacts from Opportunity Contact Roles', '/lightning/r/Opportunity/' + contract.ER_OpportunityId__c + '/view', 'Contacts'));
        }*/
        
    
        // Fetch Financial Centers
        try {
            financialCenterList = [
                SELECT Id, Name, ER_Contact__c, ER_Bank_Account__r.ER_BIC__c, ER_Bank_Account__r.ER_IBAN__c, ER_Invoicing_Country_Code__c, ER_Invoicing_Street__c, ER_Invoicing_Zip_Code__c, ER_Invoicing_City__c 
                FROM ER_Financial_Center__c
                WHERE ER_Account_Name__c = :accountId
            ];
            if(cardId == null){
                for (ER_Financial_Center__c center : financialCenterList) {
                    financialCenterIds.add(center.Id);
        
                    // Validate Bank Account
                    /* if (paymentMethod == 'Direct debit') {
                        if (center.ER_Bank_Account__c == null) {
                            errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Bank Account', 'No Bank Account found for the Financial Center', '/lightning/r/ER_Financial_Center__c/' + center.Id + '/view', 'Financial Center'));
                        } else {
                            if (center.ER_Bank_Account__r.ER_BIC__c == null) {
                                errorWrapperList.add(createErrorWrapper('ER_Bank_Account__c', 'Bank Account', 'No BIC found for the Bank Account', '/lightning/r/ER_Bank_Account__c/' + center.ER_Bank_Account__c + '/view', 'Bank Account'));
                            }
                            if (center.ER_Bank_Account__r.ER_IBAN__c == null) {
                                errorWrapperList.add(createErrorWrapper('ER_Bank_Account__c', 'Bank Account', 'No IBAN found for the Bank Account', '/lightning/r/ER_Bank_Account__c/' + center.ER_Bank_Account__c + '/view', 'Bank Account'));
                            }
                        }
                    } */
        
                    // Validate Contact
                    if (center.ER_Contact__c == null) {
                        errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 'No Contact found for the Financial Center', '/lightning/r/ER_Financial_Center__c/' + center.Id + '/view', 'Financial Center'));
                    }
                    if (center.ER_Invoicing_Country_Code__c == null) {
                        errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 'Invoicing Country code not found on Financial Center', '/lightning/r/ER_Financial_Center__c/' + center.Id + '/view', 'Financial Center'));
                    }
                    if (center.ER_Invoicing_City__c == null) {
                        errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 'Invoicing City not found on Financial Center', '/lightning/r/ER_Financial_Center__c/' + center.Id + '/view', 'Financial Center'));
                    }
                    if (center.ER_Invoicing_Zip_Code__c == null) {
                        errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 'Invoicing Zip Code not found on Financial Center', '/lightning/r/ER_Financial_Center__c/' + center.Id + '/view', 'Financial Center'));
                    }
                    if (center.ER_Invoicing_Street__c == null) {
                        errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 'Invoicing Street not found on Financial Center', '/lightning/r/ER_Financial_Center__c/' + center.Id + '/view', 'Financial Center'));
                    }
                }
            }   
            if(financialCenterList.isEmpty()){
                errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 'No Financial Centers found for this Account', '/lightning/r/Account/' + accountId + '/view', 'Financial Center'));
                /* if (paymentMethod == 'Direct debit') {
                        errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Bank Account', 'No Bank Account found for the Financial Center', '/lightning/r/Account/' + accountId + '/view', 'Financial Center'));
                } */
            }
        } catch (Exception e) {
            errorWrapperList.add(createErrorWrapper('ER_Financial_Center__c', 'Financial Center', 'Error fetching Financial Centers', '/lightning/r/Account/' + accountId + '/view', 'Financial Center'));
        }
    
        // Fetch Delivery Sites in Bulk
        if (!financialCenterIds.isEmpty() && cardId == null) {
            try {
                Map<Id, List<ER_Delivery_Site__c>> dsMap = new Map<Id, List<ER_Delivery_Site__c>>();
                for(Id fcId : financialCenterIds){
                    dsMap.put(fcId, new List<ER_Delivery_Site__c>());
                }
                List<ER_Delivery_Site__c> deliverySites = [
                    SELECT Id, ER_Financial_Center__c, ER_Country__c, ER_Country_Code__c, ER_Delivery_Contact__c, ER_City__c, ER_Zip_Code__c, ER_Street__c  
                    FROM ER_Delivery_Site__c
                    WHERE ER_Financial_Center__c IN :financialCenterIds
                ];
                for(ER_Delivery_Site__c site : deliverySites){
                    if(dsMap.containsKey(site.ER_Financial_Center__c)){
                        dsMap.get(site.ER_Financial_Center__c).add(site);
                    }
                    deliverySiteMap.put(site.ER_Financial_Center__c, site);
                    deliverySiteIds.add(site.Id);
                    if(site.ER_Country_Code__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'Error fetching Delivery Site Country code', '/lightning/r/ER_Delivery_Site__c/' + site.Id + '/view', 'Delivery Sites'));
                    }
                    if(site.ER_Delivery_Contact__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'No Delivery Contact found for this delivery site.', '/lightning/r/ER_Delivery_Site__c/' + site.Id + '/view', 'Delivery Sites'));
                    }
                    if(site.ER_City__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'No City found for this delivery site.', '/lightning/r/ER_Delivery_Site__c/' + site.Id + '/view', 'Delivery Sites'));
                    }
                    if(site.ER_Zip_Code__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'No Zip code found for this delivery site.', '/lightning/r/ER_Delivery_Site__c/' + site.Id + '/view', 'Delivery Sites'));
                    }
                    if(site.ER_Street__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'No Street found for this delivery site.', '/lightning/r/ER_Delivery_Site__c/' + site.Id + '/view', 'Delivery Sites'));
                    }
                }
                for(Id fcId : dsMap.keySet()){
                    if(dsMap.get(fcId).isEmpty()){
                        //errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'No delivery sites found under Financial Center.', '/lightning/r/ER_Financial_Center__c/' + fcId + '/view', 'Delivery Sites'));
                    }
                }
                if(deliverySites.isEmpty()){
                    //errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'No delivery sites found under Financial Center.', '/lightning/r/Account/' + accountId + '/view', 'Delivery Sites'));
                }
            } catch (Exception e) {
                //errorWrapperList.add(createErrorWrapper('ER_Delivery_Site__c', 'Delivery Site', 'Error fetching delivery sites', '/lightning/r/Account/' + accountId + '/view', 'Delivery Sites'));
            }
        }
    
        // Fetch Distribution Points in Bulk
        if (!deliverySiteIds.isEmpty() && cardId == null) {
            try {
                Map<Id, List<ER_Distribution_Point__c>> dpMap = new Map<Id, List<ER_Distribution_Point__c>>();
                for(Id dsId : deliverySiteIds){
                    dpMap.put(dsId, new List<ER_Distribution_Point__c>());
                }
                List<ER_Distribution_Point__c> distributionPoints = [
                    SELECT Id, ER_Delivery_Site__c, ER_Country__c, ER_Country_Code__c, ER_City__c, ER_Zip_Code__c, ER_Street__c
                    FROM ER_Distribution_Point__c
                    WHERE ER_Delivery_Site__c IN :deliverySiteIds
                ];
                for (ER_Distribution_Point__c point : distributionPoints) {
                    distributionPointMap.put(point.ER_Delivery_Site__c, point);
                    if(dpMap.containsKey(point.ER_Delivery_Site__c)){
                        dpMap.get(point.ER_Delivery_Site__c).add(point);
                    }
                    if(point.ER_Country_Code__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 'Error fetching Distribution Point country code', '/lightning/r/ER_Distribution_Point__c/' + point.Id + '/view', 'Distribution Point'));
                    }
                    if(point.ER_City__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 'No City found for this distribution point.', '/lightning/r/ER_Distribution_Point__c/' + point.Id + '/view', 'Distribution Point'));
                    }
                    if(point.ER_Zip_Code__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 'No Zip code found for this distribution point.', '/lightning/r/ER_Distribution_Point__c/' + point.Id + '/view', 'Distribution Point'));
                    }
                    if(point.ER_Street__c == null){
                        errorWrapperList.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 'No Street found for this distribution point.', '/lightning/r/ER_Distribution_Point__c/' + point.Id + '/view', 'Distribution Point'));
                    }
                }
                for(Id dsId : dpMap.keySet()){
                    if(dpMap.get(dsId).isEmpty()){
                        //errorWrapperList.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 'No distribution point found under Delivery Site.', '/lightning/r/ER_Delivery_Site__c/' + dsId + '/view', 'Delivery Sites'));
                    }
                }
                if(distributionPoints.isEmpty()){
                     //errorWrapperList.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 'No distribution points found under Delivery Site.', '/lightning/r/Account/' + accountId + '/view', 'Distribution Points')); 
                }
            } catch (Exception e) {
                //errorWrapperList.add(createErrorWrapper('ER_Distribution_Point__c', 'Distribution Point', 'Error fetching distribution points', '/lightning/r/Account/' + accountId + '/view', 'Distribution Points'));
            }
        }
    
        return errorWrapperList;
    }

    
    private static ErrorListWrapper createErrorWrapper(String sObjName, String sName, String sMessage, String sLink, String sSection) {
        ErrorListWrapper wrapper = new ErrorListWrapper();
        wrapper.count = 1;
        wrapper.data = new List<ErrorInfoWrapper>();
    
        ErrorInfoWrapper info = new ErrorInfoWrapper();
        info.sObjName = sObjName;
        info.sName = sName;
        info.sMessage = sMessage;
        info.sLink = sLink;
        info.sSection = sSection;
    
        wrapper.data.add(info);
        return wrapper;
    }
    

    public class ErrorListWrapper {
        @AuraEnabled
        public Integer count { get; set; }
        @AuraEnabled
        public List<ErrorInfoWrapper> data { get; set; }
    }
    public class ErrorInfoWrapper {
        @AuraEnabled
        public String sObjName { get; set; }
        @AuraEnabled
        public String sName { get; set; }
        @AuraEnabled
        public String sMessage { get; set; }
        @AuraEnabled
        public String sLink { get; set; }
        @AuraEnabled
        public String sSection { get; set; }
    }
}