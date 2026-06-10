/*
----------------------------------------------------------------------
-- - Name          : SyncClientContractService 
-- - Author        : Snehil Verma
-- - Description   : NEMO Sync, This class is used to perform NEMO callouts for Clients and Contracts
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Nov-2024     Snehil Verma        1.0         Initial version
---------------------------------------------------------------------------------------
*/
public without sharing class SyncClientContractService {
    
    public List<Integration_Log__c> ilList = new List<Integration_Log__c>();
    
    //Get Wrapper for CreateClientRequest
    public String getCreateClientRequestWrapper(Id contractId){
        
        String wrapper; Datetime myDateTime;
        Boolean isFinancialCenterEmpty = false;
        Time myTime = Time.newInstance(0, 0, 0, 0);
        Set<Id> deliverySiteIdSet = new Set<Id>();
        Map<String, Id> operationalRoleContactIdMap = new Map<String, Id>();
        Map<String, List<ER_ContractLineItem__c>> cliSolutionServiceMap = new Map<String, List<ER_ContractLineItem__c>>();
        Map<Id, List<ER_Delivery_Site__c>> financialCenterDeliverySiteMap = new Map<Id, List<ER_Delivery_Site__c>>();
        Map<Id, List<ER_Distribution_Point__c>> deliverySiteDistributionPointMap = new Map<Id, List<ER_Distribution_Point__c>>();
        //Map<String, Boolean> solutionDiscountAppliedMap = new Map<String, Boolean>();
        Map<String, Map<String, Boolean>> solutionDiscountAppliedMap = new Map<String, Map<String, Boolean>>();
        
        CreateClientRequestWrapper wrapObj = new CreateClientRequestWrapper();
        List<CreateClientRequestWrapper.ContractWrapper> contractWrapList = new List<CreateClientRequestWrapper.ContractWrapper>();
        List<CreateClientRequestWrapper.ContractProductWrapper> contractProductWrapList = new List<CreateClientRequestWrapper.ContractProductWrapper>();
        List<CreateClientRequestWrapper.ServiceWrapper> serviceWrapList = new List<CreateClientRequestWrapper.ServiceWrapper>();
        List<CreateClientRequestWrapper.FinancialCenterWrapper> financialWrapList = new List<CreateClientRequestWrapper.FinancialCenterWrapper>();
        List<CreateClientRequestWrapper.DeliverySiteWrapper> deliverySiteWrapList = new List<CreateClientRequestWrapper.DeliverySiteWrapper>();
        List<CreateClientRequestWrapper.DistributionPointWrapper> distributionPointWrapList = new List<CreateClientRequestWrapper.DistributionPointWrapper>();
        List<CreateClientRequestWrapper.ContactWrapper> contactWrapList = new List<CreateClientRequestWrapper.ContactWrapper>();
        Set<Id> processedContactIds = new Set<Id>();
        
        //Updated query for adding sme parent account id 
        //List<Contract> contract = [SELECT Id, Name, AccountId, Creditting__c, Billing_Contact__c,ER_Delivery_Type__c, Primary_Contact__c, Card_Replacement_Payment__c, ER_Impacted_Beneficiaries__c, ER_PaymentTerms2__c, ER_PaymentMethod2__c, ER_Program_Name__c, ER_Customer_Domain__c, ER_Onboarding_Method__c, ER_InvoicingFrequency2__c, ER_OpportunityId__r.Impacted_Beneficiaries__c, Account.Name, Account.BillingCountry, Account.ER_Legal_Name__c, Account.ER_Registration_Number__c, Account.ER_Not_subject_to_VAT__c, Account.ER_Language__c, LastModifiedDate, StartDate,Contract_Category__c, ER_Start_Date__c, CustomerSignedDate, ER_OpportunityId__r.Invoicing_Contact__c, CustomerSignedId, ER_OpportunityId__r.ER_Promo_Code2__r.ER_Promo_Code__c, ER_OpportunityId__r.Primary_Contact__c, Account.ER_VAT_Number__c, Account.BillingStreet, Account.ER_Country_Code__c, Account.BillingCity, Account.BillingPostalCode FROM Contract WHERE Id = :contractId];
        List<Contract> contract = [SELECT Id, Name, AccountId, Creditting__c, Billing_Contact__c,ER_Delivery_Type__c, Primary_Contact__c, Card_Replacement_Payment__c, ER_Impacted_Beneficiaries__c, ER_PaymentTerms2__c, ER_PaymentMethod2__c, ER_Program_Name__c, ER_Customer_Domain__c, ER_Onboarding_Method__c, ER_InvoicingFrequency2__c, ER_OpportunityId__r.Impacted_Beneficiaries__c, Account.Name, Account.BillingCountry, Account.ER_Legal_Name__c, Account.ER_Registration_Number__c, Account.ER_Not_subject_to_VAT__c, Account.ER_Language__c, LastModifiedDate, StartDate,Contract_Category__c, ER_Start_Date__c, CustomerSignedDate, ER_OpportunityId__r.Invoicing_Contact__c, CustomerSignedId, ER_OpportunityId__r.ER_Promo_Code2__r.ER_Promo_Code__c, ER_OpportunityId__r.Primary_Contact__c, Account.ER_VAT_Number__c, Account.BillingStreet, Account.ER_Country_Code__c, Account.BillingCity, Account.BillingPostalCode, Main_Platform__c FROM Contract WHERE Id = :contractId];
        List<ER_ContractLineItem__c> contractLineItemList = [SELECT Id, Name, ER_Solution__c, ER_Product2__r.ER_Do_Not_Synchronize__c, ER_Product2__r.ER_Type__c, ER_ProductCode__c, ER_Percentage__c, ER_Quantity__c, ER_Minimum_Fee__c, LastModifiedDate, ER_UnitPrice__c, ER_ListPrice__c, Solution_Group__c, ER_Line_Type__c, Parent_Product__c, Fee_Type__c, Product_Type__c FROM ER_ContractLineItem__c WHERE ER_Contract__c = :contractId AND ER_Solution__c != null AND ER_Product2__r.ER_Do_Not_Synchronize__c = false];

        // New code for Engagement
        String contractType = 'Savings'; // 'Savings' or 'Benefits'
        for (ER_ContractLineItem__c cli : contractLineItemList) {
            if (cli.Solution_Group__c == 'Benefits') {
                contractType = 'Benefits';
                break;
            }
            if (cli.Solution_Group__c == 'Savings' || cli.Solution_Group__c == 'Engagement') {
                contractType = 'Savings';
                //break;
            }
        }

        // Fallback (optional): if still null, treat as Benefits to avoid breaking existing flow
        if (contractType == null) {
            contractType = 'Benefits';
        }
        if(!contract.isEmpty()){

            //List<Contact> contactList = [SELECT Id,BE_Operational_Role__c, LastModifiedDate, Phone, MobilePhone, Email, ER_Language__c, LastName, FirstName from Contact where AccountId =:contract[0].AccountId and ER_Status__c ='Active' and BE_Operational_Role__c != null order by LastModifiedDate DESC];
            List<ContractContactRole> ccrList = [SELECT Id, Role, ContactId,Contact.FirstName,Contact.Lastname,Contact.Email, Contact.MobilePhone, contact.LastModifiedDate,Contact.phone,Contact.ER_Language__c, ContractId FROM ContractContactRole where ContractId =: contractId];
            List<AccountContactRelation> acrList = [SELECT Id, AccountId, ContactId, Roles, Contact.FirstName, Contact.LastName, Contact.Email,Contact.MobilePhone, Contact.LastModifiedDate, Contact.Phone, Contact.ER_Language__c FROM AccountContactRelation WHERE AccountId = :contract[0].AccountId];

            Map<Id, List<AccountContactRelation>> contactIdToAcrMap = new Map<Id, List<AccountContactRelation>>();
            for (AccountContactRelation acr : acrList) {
                if (!contactIdToAcrMap.containsKey(acr.ContactId)) {
                    contactIdToAcrMap.put(acr.ContactId, new List<AccountContactRelation>());
                }
                contactIdToAcrMap.get(acr.ContactId).add(acr);
            }
            Map<Id, Id> contactToAcrIdMap = new Map<Id, Id>();
            for (Id conId : contactIdToAcrMap.keySet()) {
                List<AccountContactRelation> lst = contactIdToAcrMap.get(conId);
                if (!lst.isEmpty()) {
                    contactToAcrIdMap.put(conId, lst[0].Id);
                }
            }
            List<ER_Financial_Center__c> financialCenterList = [SELECT Id, Name, ER_Contact__c, ER_Contact__r.FirstName, ER_Contact__r.LastName, ER_Contact__r.Email, ER_Contact__r.Phone, ER_Contact__r.ER_Language__c, ER_Contact__r.LastModifiedDate, ER_Invoicing_Country__c, ER_Invoicing_Country_Code__c, ER_Street__c, LastModifiedDate, ER_Country_Code__c, ER_City__c, ER_Zip_Code__c, ER_Bank_Account__r.ER_BIC__c, ER_Bank_Account__r.ER_IBAN__c, ER_Invoicing_Zip_Code__c, ER_Invoicing_City__c, ER_Invoicing_Street__c from ER_Financial_Center__c where ER_Account_Name__c =:contract[0].AccountId ];

            //Updated Logic
            if (financialCenterList.isEmpty()) {
                isFinancialCenterEmpty = true;
            } else {
                for (ER_Financial_Center__c fcObj : financialCenterList) {
                    Id acrIdForFcContact = fcObj.ER_Contact__c != null ? contactToAcrIdMap.get(fcObj.ER_Contact__c) : null;
                    Id fcCrmId = acrIdForFcContact != null ? acrIdForFcContact : fcObj.ER_Contact__c;
                    if (fcCrmId != null && !processedContactIds.contains(fcCrmId)) {
                        processedContactIds.add(fcCrmId);

                        CreateClientRequestWrapper.ContactWrapper contactWrap = new CreateClientRequestWrapper.ContactWrapper();
                        contactWrap.crm_id = fcCrmId;
                        contactWrap.first_name = fcObj.ER_Contact__r.FirstName;
                        contactWrap.last_name = fcObj.ER_Contact__r.LastName;
                        contactWrap.language = fcObj.ER_Contact__r.ER_Language__c != null ? fcObj.ER_Contact__r.ER_Language__c.toLowerCase() : null;
                        contactWrap.email = fcObj.ER_Contact__r.Email;
                        contactWrap.phone_number = fcObj.ER_Contact__r.Phone;
                        //Adding new To be updated
                        //contactWrap.mobile_number = fcObj.ER_Contact__r.MobilePhone;
                        contactWrap.last_modification_date =
                            fcObj.ER_Contact__r.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                        contactWrapList.add(contactWrap);
                    }
                }
            }

            for (ER_Delivery_Site__c dsObj : [ SELECT Id, ER_Financial_Center__c, Name, ER_Country_Code__c, ER_Country__c, ER_City__c, ER_Zip_Code__c, ER_Street__c, LastModifiedDate, ER_Delivery_Contact__c, ER_Delivery_Contact__r.FirstName, ER_Delivery_Contact__r.LastName, ER_Delivery_Contact__r.Email, ER_Delivery_Contact__r.Phone, ER_Delivery_Contact__r.ER_Language__c, ER_Delivery_Contact__r.LastModifiedDate FROM ER_Delivery_Site__c WHERE ER_Financial_Center__c IN :financialCenterList ]) {
                deliverySiteIdSet.add(dsObj.Id);

                if (!financialCenterDeliverySiteMap.containsKey(dsObj.ER_Financial_Center__c)) {
                    financialCenterDeliverySiteMap.put(
                        dsObj.ER_Financial_Center__c,
                        new List<ER_Delivery_Site__c>{ dsObj }
                    );
                } else {
                    financialCenterDeliverySiteMap.get(dsObj.ER_Financial_Center__c).add(dsObj);
                }

                Id acrIdForDsContact = dsObj.ER_Delivery_Contact__c != null ? contactToAcrIdMap.get(dsObj.ER_Delivery_Contact__c) : null;
                Id dsCrmId = acrIdForDsContact != null ? acrIdForDsContact : dsObj.ER_Delivery_Contact__c;
                if (dsCrmId != null && !processedContactIds.contains(dsCrmId)) {
                    processedContactIds.add(dsCrmId);

                    CreateClientRequestWrapper.ContactWrapper contactWrap = new CreateClientRequestWrapper.ContactWrapper();

                    contactWrap.crm_id = dsCrmId;
                    contactWrap.first_name = dsObj.ER_Delivery_Contact__r.FirstName;
                    contactWrap.last_name = dsObj.ER_Delivery_Contact__r.LastName;
                    contactWrap.language = dsObj.ER_Delivery_Contact__r.ER_Language__c != null ? dsObj.ER_Delivery_Contact__r.ER_Language__c.toLowerCase() : null;
                    contactWrap.email = dsObj.ER_Delivery_Contact__r.Email;
                    contactWrap.phone_number = dsObj.ER_Delivery_Contact__r.Phone;
                    //Adding new // Giving error to be checked
                    //contactWrap.mobile_number = dsObj.Contact.MobilePhone;
                    contactWrap.last_modification_date = dsObj.ER_Delivery_Contact__r.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                    contactWrapList.add(contactWrap);
                }
            }

            
            for(ER_Distribution_Point__c dpObj : [SELECT Id, ER_Delivery_Site__c, Name, ER_Contact__c, ER_Contact__r.FirstName, ER_Contact__r.LastName, ER_Contact__r.Email, 
            ER_Contact__r.Phone, ER_Contact__r.ER_Language__c, ER_Contact__r.LastModifiedDate, ER_Country__c, LastModifiedDate, ER_Country_Code__c, ER_City__c, ER_Zip_Code__c, ER_Street__c from ER_Distribution_Point__c where ER_Delivery_Site__c IN:deliverySiteIdSet ]){
                if(!deliverySiteDistributionPointMap.containsKey(dpObj.ER_Delivery_Site__c)){
                    deliverySiteDistributionPointMap.put(dpObj.ER_Delivery_Site__c, new List<ER_Distribution_Point__c>{dpObj});
                }else{
                    deliverySiteDistributionPointMap.get(dpObj.ER_Delivery_Site__c).add(dpObj);
                }

                Id acrIdForDpContact = dpObj.ER_Contact__c != null
                    ? contactToAcrIdMap.get(dpObj.ER_Contact__c)
                    : null;

                Id dpCrmId = acrIdForDpContact != null
                    ? acrIdForDpContact
                    : dpObj.ER_Contact__c;

                //if(dpObj.ER_Contact__c != null && !processedContactIds.contains(dpObj.ER_Contact__c)){
                if (dpCrmId != null && !processedContactIds.contains(dpCrmId)) {
                    //processedContactIds.add(dpObj.ER_Contact__c);
                    processedContactIds.add(dpCrmId);
                
                    CreateClientRequestWrapper.ContactWrapper contactWrap = new CreateClientRequestWrapper.ContactWrapper();
                    //contactWrap.crm_id = dpObj.ER_Contact__c;
                    contactWrap.crm_id = dpCrmId;
                    contactWrap.first_name = dpObj.ER_Contact__r.FirstName;
                    contactWrap.last_name = dpObj.ER_Contact__r.LastName;
                    contactWrap.language = dpObj.ER_Contact__r.ER_Language__c != null 
                        ? dpObj.ER_Contact__r.ER_Language__c.toLowerCase() : null;
                    contactWrap.email = dpObj.ER_Contact__r.Email;
                    contactWrap.phone_number = dpObj.ER_Contact__r.Phone;
                    //Adding new line
                    //contactWrap.mobile_number = dpObj.ER_Contact__r.MobilePhone;
                    contactWrap.last_modification_date = dpObj.ER_Contact__r.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                    
                    contactWrapList.add(contactWrap);
                }
            }

            //New Logic to send AccountContactRelation 
            // Map<Id, List<AccountContactRelation>> contactIdToAcrMap = new Map<Id, List<AccountContactRelation>>();
            // for (AccountContactRelation acr : acrList) {
            //     if (!contactIdToAcrMap.containsKey(acr.ContactId)) {
            //         contactIdToAcrMap.put(acr.ContactId, new List<AccountContactRelation>());
            //     }
            //     contactIdToAcrMap.get(acr.ContactId).add(acr);
            // }
            // New Code
            // Map<Id, Id> contactToAcrIdMap = new Map<Id, Id>();
            // for (Id conId : contactIdToAcrMap.keySet()) {
            //     List<AccountContactRelation> lst = contactIdToAcrMap.get(conId);
            //     if (!lst.isEmpty()) {
            //         contactToAcrIdMap.put(conId, lst[0].Id);
            //     }
            // }

            //New Code
            for (ContractContactRole ccrObj : ccrList) {
            // Fetch relevant ACRs for this contact
            List<AccountContactRelation> relatedAcrList =
                contactIdToAcrMap.get(ccrObj.ContactId);

            // Find matching ACR based on role
            AccountContactRelation matchedAcr =
                findMatchingAcr(relatedAcrList, ccrObj.Role);

            if (matchedAcr == null) {
                //System.DEBUG('CCR_NO_ACR_MATCH contactId=' + ccrObj.ContactId + ', role=' + ccrObj.Role);
                //System.debug('No matching ACR found for Contact: ' + ccrObj.ContactId + ' Role: ' + ccrObj.Role);
                continue;
            }

            // Populate role map using ACR Id instead of CCR Id
            if (!operationalRoleContactIdMap.containsKey(ccrObj.Role)) {
                operationalRoleContactIdMap.put(ccrObj.Role, matchedAcr.Id); 
                //operationalRoleContactIdMap.put(ccrObj.Role, ccrObj.ContactId);
            }

            // Avoid duplicate contacts in wrapper
            if (!processedContactIds.contains(matchedAcr.Id)) {

                processedContactIds.add(matchedAcr.Id);

                CreateClientRequestWrapper.ContactWrapper contactWrap =
                    new CreateClientRequestWrapper.ContactWrapper();

                contactWrap.crm_id = matchedAcr.Id; // We want the Contact id and not the acr id  
                //contactWrap.crm_id = ccrObj.ContactId;
                contactWrap.first_name = ccrObj.Contact.FirstName;
                contactWrap.last_name = ccrObj.Contact.LastName;
                contactWrap.language = ccrObj.Contact.ER_Language__c != null
                    ? ccrObj.Contact.ER_Language__c.toLowerCase()
                    : 'en';
                contactWrap.email = ccrObj.Contact.Email;
                contactWrap.phone_number = ccrObj.Contact.Phone;
                //Adding new
                //contactWrap.mobile_number = ccrObj.Contact.MobilePhone;
                contactWrap.last_modification_date =
                    ccrObj.Contact.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                contactWrapList.add(contactWrap);
            }
        }
            
            /*for(ER_ContractLineItem__c cliObj : contractLineItemList){
                if(!solutionDiscountAppliedMap.containsKey(cliObj.ER_Solution__c)){
                    solutionDiscountAppliedMap.put(cliObj.ER_Solution__c, new Map<String, Boolean>());
                    solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).put(cliObj.ER_ProductCode__c, false);
                    if(cliObj.ER_Product2__r.ER_Type__c == 'Discount'){
                        solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).put(cliObj.ER_ProductCode__c, true);
                    }
                }else{
                    if(!solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).containsKey(cliObj.ER_ProductCode__c)){
                        solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).put(cliObj.ER_ProductCode__c, false);
                    }
                    if(cliObj.ER_Product2__r.ER_Type__c == 'Discount'){
                        solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).put(cliObj.ER_ProductCode__c, true);
                    }
                }
            }*/
            
            for (ER_ContractLineItem__c cliObj : contractLineItemList) {
                String effectiveSolution = getEffectiveSolution(cliObj);
            
                if (!solutionDiscountAppliedMap.containsKey(effectiveSolution)) {
                    solutionDiscountAppliedMap.put(effectiveSolution, new Map<String, Boolean>());
                }
            
                if (!solutionDiscountAppliedMap.get(effectiveSolution).containsKey(cliObj.ER_ProductCode__c)) {
                    solutionDiscountAppliedMap.get(effectiveSolution).put(cliObj.ER_ProductCode__c, false);
                }
            
                if (cliObj.ER_Product2__r.ER_Type__c == 'Discount') {
                    solutionDiscountAppliedMap.get(effectiveSolution).put(cliObj.ER_ProductCode__c, true);
                }
            }
            for (ER_ContractLineItem__c cliObj : contractLineItemList) {
                String effectiveSolution = getEffectiveSolution(cliObj);
                
                if (solutionDiscountAppliedMap.containsKey(effectiveSolution)) {
                    if (solutionDiscountAppliedMap.get(effectiveSolution).containsKey(cliObj.ER_ProductCode__c)) {
                        
                        if (solutionDiscountAppliedMap.get(effectiveSolution).get(cliObj.ER_ProductCode__c)) {
                            
                            if (cliObj.ER_Product2__r.ER_Type__c == 'Discount') {
                                
                                if (!cliSolutionServiceMap.containsKey(effectiveSolution)) {
                                    cliSolutionServiceMap.put(effectiveSolution, new List<ER_ContractLineItem__c>{cliObj});
                                } else {
                                    cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                                }
                            }
                            
                        } else {
                            
                            if (!cliSolutionServiceMap.containsKey(effectiveSolution)) {
                                cliSolutionServiceMap.put(effectiveSolution, new List<ER_ContractLineItem__c>{cliObj});
                            } else {
                                cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                            }
                        }
                    }
                }
            }
            
            /*for(ER_ContractLineItem__c cliObj : contractLineItemList){
                if(solutionDiscountAppliedMap.containsKey(cliObj.ER_Solution__c)){
                    if(solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).containsKey(cliObj.ER_ProductCode__c)){
                        if(solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).get(cliObj.ER_ProductCode__c)){
                            if(cliObj.ER_Product2__r.ER_Type__c == 'Discount'){
                                if(!cliSolutionServiceMap.containsKey(cliObj.ER_Solution__c)){
                                    cliSolutionServiceMap.put(cliObj.ER_Solution__c, new List<ER_ContractLineItem__c>{cliObj});
                                }else{
                                    cliSolutionServiceMap.get(cliObj.ER_Solution__c).add(cliObj);
                                }
                            }
                        }else{
                            if(!cliSolutionServiceMap.containsKey(cliObj.ER_Solution__c)){
                                cliSolutionServiceMap.put(cliObj.ER_Solution__c, new List<ER_ContractLineItem__c>{cliObj});
                            }else{
                                cliSolutionServiceMap.get(cliObj.ER_Solution__c).add(cliObj);
                            }
                        }
                    }
                }
            }*/

            //commenting this bcoz  of duplication and creating new, har
            /*for(ER_ContractLineItem__c cliObj : contractLineItemList){
                //if(solutionDiscountAppliedMap.containsKey(cliObj.ER_Solution__c)){
                String effectiveSolution = getEffectiveSolution(cliObj);
				if(solutionDiscountAppliedMap.containsKey(effectiveSolution)){
                    if(solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).containsKey(cliObj.ER_ProductCode__c)){
                        if(solutionDiscountAppliedMap.get(cliObj.ER_Solution__c).get(cliObj.ER_ProductCode__c)){
                            if(cliObj.ER_Product2__r.ER_Type__c == 'Discount'){
                                if(!cliSolutionServiceMap.containsKey(cliObj.ER_Solution__c)){
                                    //cliSolutionServiceMap.put(cliObj.ER_Solution__c, new List<ER_ContractLineItem__c>{cliObj});
                                    //String effectiveSolution = getEffectiveSolution(cliObj);
                                    if(!cliSolutionServiceMap.containsKey(effectiveSolution)){
                                        cliSolutionServiceMap.put(effectiveSolution, new List<ER_ContractLineItem__c>{cliObj});
                                    }else{
                                        cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                                    }
                                }else{
                                    cliSolutionServiceMap.get(cliObj.ER_Solution__c).add(cliObj);
                                }
                            }
                        }else{
                            if(!cliSolutionServiceMap.containsKey(cliObj.ER_Solution__c)){
                                //cliSolutionServiceMap.put(cliObj.ER_Solution__c, new List<ER_ContractLineItem__c>{cliObj});
                                //String effectiveSolution = getEffectiveSolution(cliObj);
                                if(!cliSolutionServiceMap.containsKey(effectiveSolution)){
                                    cliSolutionServiceMap.put(effectiveSolution, new List<ER_ContractLineItem__c>{cliObj});
                                }else{
                                    cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                                }
                            }else{
                                cliSolutionServiceMap.get(cliObj.ER_Solution__c).add(cliObj);
                            }
                        }
                    }
                }
            }*/
            //Commenting this temp
            /*for(ER_ContractLineItem__c cliObj : contractLineItemList){
                String effectiveSolution = getEffectiveSolution(cliObj);

                if(solutionDiscountAppliedMap.containsKey(effectiveSolution)){
                    if(solutionDiscountAppliedMap.get(effectiveSolution).containsKey(cliObj.ER_ProductCode__c)){
                        if(solutionDiscountAppliedMap.get(effectiveSolution).get(cliObj.ER_ProductCode__c)){
                            
                            if(cliObj.ER_Product2__r.ER_Type__c == 'Discount'){
                                
                                if(!cliSolutionServiceMap.containsKey(effectiveSolution)){
                                    if(!cliSolutionServiceMap.containsKey(effectiveSolution)){
                                        cliSolutionServiceMap.put(effectiveSolution, new List<ER_ContractLineItem__c>{cliObj});
                                    }else{
                                        cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                                    }
                                }else{
                                    cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                                }
                            }

                        }else{

                            if(!cliSolutionServiceMap.containsKey(effectiveSolution)){
                                if(!cliSolutionServiceMap.containsKey(effectiveSolution)){
                                    cliSolutionServiceMap.put(effectiveSolution, new List<ER_ContractLineItem__c>{cliObj});
                                }else{
                                    cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                                }
                            }else{
                                cliSolutionServiceMap.get(effectiveSolution).add(cliObj);
                            }

                        }
                    }
                }
            }*/
            
            wrapObj.crm_id = contract[0].AccountId;
            wrapObj.name = contract[0].Account.Name; 
            wrapObj.legal_name = contract[0].Account.ER_Legal_Name__c;
            wrapObj.company_registration_number = contract[0].Account.ER_Registration_Number__c;
            wrapObj.vat_number = contract[0].Account.ER_VAT_Number__c;
            wrapObj.vat_type = contract[0].Account.ER_Not_subject_to_VAT__c ? 'not_liable' : 'liable';//exempt
            wrapObj.last_modification_date = contract[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
            //Adding new field in the json file
            wrapObj.engagement_platform_id = contract[0].Main_Platform__c;
            
            //Contract
            CreateClientRequestWrapper.ContractWrapper contractWrap = new CreateClientRequestWrapper.ContractWrapper();
            contractWrap.crm_id = contract[0].Id;
            contractWrap.name = contract[0].Name;
            //New logic for showing the 3 fields
            contractWrap.program_name = contract[0].ER_Program_Name__c;
            contractWrap.customer_domain = contract[0].ER_Customer_Domain__c;
            contractWrap.customer_management = contract[0].ER_Onboarding_Method__c;

            //Adding new field Delivery site
            contractWrap.delivery_type = contract[0].ER_Delivery_Type__c;

            // New line for adding the invoicing Frequency
            contractWrap.invoicing_frequency = contract[0].ER_InvoicingFrequency2__c;

            // New Code for v4
            // client expects this key to exist even if null
                contractWrap.end_date = null;

                // payment method + deadline at CONTRACT level (not as services)
                if (contract[0].ER_PaymentMethod2__c != null) {
                    Map<String, String> paymentMethodMap = Constants.getPaymentMethodMap();
                    contractWrap.payment_method = paymentMethodMap.get(contract[0].ER_PaymentMethod2__c);
                }

                if (contract[0].ER_PaymentTerms2__c != null) {
                    Map<String, String> paymentTermsMap = Constants.getPaymentTermsMap();
                    contractWrap.payment_deadline = paymentTermsMap.get(contract[0].ER_PaymentTerms2__c);
                }

                // crediting delay at CONTRACT level
                if (contract[0].Creditting__c != null) {
                    Map<String, String> creditingMap = Constants.getCreditingMap();
                    contractWrap.crediting_delay = creditingMap.get(contract[0].Creditting__c);
                }

            // New code for v4 ends
            // New logic added to display the beneficiers affected
            String method = null;
            //Adding new logic
            if (contract[0].ER_Impacted_Beneficiaries__c == 'TRE Only') {
                method = 'TRE';
            } else if (contract[0].ER_Impacted_Beneficiaries__c == 'All') {
                method = 'ALL';
            }
            contractWrap.selection_method = method;
            /*if (contract[0].ER_OpportunityId__r.Impacted_Beneficiaries__c == 'TRE Only') {
                method = 'TRE';
            } else if (contract[0].ER_OpportunityId__r.Impacted_Beneficiaries__c == 'All') {
                method = 'ALL';
            }*/
            // Logic ends
            
            //myDateTime = contract[0].ER_Start_Date__c != null ? Datetime.newInstance(contract[0].ER_Start_Date__c, myTime) : null;
            //contractWrap.start_date = myDateTime != null ? myDateTime.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'') : null;
            Date startDateToUse;
            if (contract[0].Contract_Category__c == 'Benefits') {
                startDateToUse = contract[0].StartDate;
            } else {
                startDateToUse = contract[0].ER_Start_Date__c;
            }
            myDateTime = startDateToUse != null ? Datetime.newInstance(startDateToUse, myTime) : null;
            System.debug('startDateToUse' + startDateToUse);
            System.debug('Contract_Category__c' + contract[0].Contract_Category__c);

            contractWrap.start_date = myDateTime != null ? myDateTime.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'') : null;
            myDateTime = contract[0].CustomerSignedDate != null ? Datetime.newInstance(contract[0].CustomerSignedDate, myTime) : null;
            contractWrap.signed_date = myDateTime != null ? myDateTime.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\''): null;
            contractWrap.invoicing_contact_id = operationalRoleContactIdMap.containsKey('Invoicing Contact') ? operationalRoleContactIdMap.get('Invoicing Contact') : null;
            //New 
            Id counterpartyCrmId;
            if (contract[0].CustomerSignedId != null) {
                Id acrIdForCounterparty = contactToAcrIdMap.get(contract[0].CustomerSignedId);
                counterpartyCrmId = (acrIdForCounterparty != null)
                    ? acrIdForCounterparty
                    : contract[0].CustomerSignedId; // fallback to Contact Id
            }
            contractWrap.contact_counterparty_signed_id = counterpartyCrmId;
            //New logic
                if (counterpartyCrmId != null && !processedContactIds.contains(counterpartyCrmId)) {
                // Query the contact details
                List<Contact> counterpartyContacts = [
                    SELECT Id, FirstName, LastName, Email, Phone, ER_Language__c, LastModifiedDate 
                    FROM Contact 
                    WHERE Id = :contract[0].CustomerSignedId
                    LIMIT 1
                ];
                
                if (!counterpartyContacts.isEmpty()) {
                    Contact conObj = counterpartyContacts[0];
                    processedContactIds.add(counterpartyCrmId);
                    
                    CreateClientRequestWrapper.ContactWrapper contactWrap = new CreateClientRequestWrapper.ContactWrapper();
                    //CreateClientRequestWrapper.Contact contactWrap = new CreateClientRequestWrapper.Contact();
                    contactWrap.crm_id = counterpartyCrmId; // ACR ID or Contact ID
                    contactWrap.first_name = conObj.FirstName;
                    contactWrap.last_name = conObj.LastName;
                    contactWrap.language = conObj.ER_Language__c != null 
                        ? conObj.ER_Language__c.toLowerCase() 
                        : 'en';
                    contactWrap.email = conObj.Email;
                    contactWrap.phone_number = conObj.Phone;
                    contactWrap.last_modification_date = conObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                    contactWrapList.add(contactWrap);
                }
            }

            //contractWrap.contact_counterparty_signed_id = contract[0].CustomerSignedId;
            contractWrap.last_modification_date = contract[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
            
            if(!cliSolutionServiceMap.isEmpty()){
                for(String solutionCode : cliSolutionServiceMap.keySet()){
                    //Solutions
                    CreateClientRequestWrapper.ContractProductWrapper prodWrapObj = new CreateClientRequestWrapper.ContractProductWrapper();
                    //Adding new line
                    //Integer licenses = null;
                    prodWrapObj.start_date = contractWrap.start_date;
                    prodWrapObj.signed_date = contractWrap.signed_date;
                    prodWrapObj.order_contact_id = operationalRoleContactIdMap.containsKey('Order Contact') ? operationalRoleContactIdMap.get('Order Contact') : operationalRoleContactIdMap.get('Primary Contact');
                    prodWrapObj.product = solutionCode.toLowerCase();
                    serviceWrapList = new List<CreateClientRequestWrapper.ServiceWrapper>();
                    //New line to filter acc to the smarthub logic, to show only once
                    Set<String> addedServiceCodes = new Set<String>();
                    
                    for(ER_ContractLineItem__c cliObj : cliSolutionServiceMap.get(solutionCode)){
                        //Adding new 
                            //Commenting temporary
                            //if (cliObj.Solution_Group__c == 'Benefits') {
                            //    continue;
                            //}
                        //Adding new condition
                        // this is to be removed now.
                        /*if (licenses == null && cliObj.Solution_Group__c == 'Savings') {
                            licenses = cliObj.ER_Quantity__c != null ? Integer.valueOf(cliObj.ER_Quantity__c) : null;
                        }*/
                        if(cliObj.ER_Product2__r.ER_Type__c == 'Discount'){
                            prodWrapObj.promo_code = contract[0].ER_OpportunityId__r.ER_Promo_Code2__r.ER_Promo_Code__c;
                        }
                        
                        //Services
                        if(contract[0].Card_Replacement_Payment__c != null && (contract[0].Card_Replacement_Payment__c == 'Paid by beneficiary' || contract[0].Card_Replacement_Payment__c == 'Paid by customer') && (solutionCode == Constants.ADDITIONAL_SERVICE_CODE_BE || solutionCode == Constants.ADDITIONAL_SERVICE_CODE_LU) && (cliObj.ER_ProductCode__c == Constants.CARD_RP_CT || cliObj.ER_ProductCode__c == Constants.CARD_RP_BF)){
                            CreateClientRequestWrapper.ServiceWrapper serviceWrapObj = new CreateClientRequestWrapper.ServiceWrapper();
                            serviceWrapObj.code = contract[0].Card_Replacement_Payment__c == 'Paid by beneficiary'? Constants.CARD_RP_BF : contract[0].Card_Replacement_Payment__c == 'Paid by customer' ? Constants.CARD_RP_CT : null;
                            serviceWrapObj.percentage = contract[0].Card_Replacement_Payment__c == 'Paid by beneficiary' ? 0 : cliObj.ER_Percentage__c != null ? cliObj.ER_Percentage__c.setScale(6) : 0;
                            //Commenting this as we dont need the quantity be empty
                            //serviceWrapObj.quantity = 0;
                            serviceWrapObj.quantity =
                                (cliObj.Solution_Group__c == 'Savings' || cliObj.Solution_Group__c == 'Engagement')
                                ? (cliObj.ER_Quantity__c != null ? cliObj.ER_Quantity__c : 0)
                                : 0; 


                            serviceWrapObj.amount = contract[0].Card_Replacement_Payment__c == 'Paid by beneficiary' ? 0 : cliObj.ER_UnitPrice__c != null ? cliObj.ER_UnitPrice__c.setScale(2) : 0;
                            serviceWrapObj.minimum_fee = contract[0].Card_Replacement_Payment__c == 'Paid by beneficiary' ? 0 : cliObj.ER_Minimum_Fee__c != null ? cliObj.ER_Minimum_Fee__c.setScale(2) : 0;
                            serviceWrapObj.discount = 0;
                            serviceWrapObj.sales_price = 0;
                            serviceWrapObj.standard_price = 0;
                            serviceWrapObj.solution = cliObj.Solution_Group__c == 'Benefits' ? 'benefit' : cliObj.Solution_Group__c == 'Savings'  ? 'engagement' : null;
                            serviceWrapObj.fee_type = cliObj.Fee_Type__c;
                            serviceWrapObj.product_type = cliObj.Product_Type__c;
                            serviceWrapObj.last_modification_date = cliObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                            serviceWrapList.add(serviceWrapObj);
                        }else{
                            CreateClientRequestWrapper.ServiceWrapper serviceWrapObj = new CreateClientRequestWrapper.ServiceWrapper();
                            String codeToSend = cliObj.ER_ProductCode__c; // default
                            //For savings only
                            if (cliObj.Solution_Group__c == 'Savings') {
                                String parent = cliObj.Parent_Product__c;

                                if (!String.isBlank(parent)) {
                                    String p = parent.toLowerCase();

                                    //New map for values
                                    Map<String, String> parentToCode = new Map<String, String>{
                                        'premium implementation fees' => 'Implementation_Premium',
                                        'implementation fees'         => 'Implementation',
                                        'license fees'                => 'License',
                                        'premium license fees'        => 'License_Premium',
                                        'freemium license fees'       => 'License_Freemium',
                                        'reward'                      => 'Reward',
                                        'smarthub'                    => 'SmartHub',
                                        'recognition'                 => 'Recognition',
                                        'freemium implementation fees'=> 'Implementation_Freemium'
                                    };
                                    if (parentToCode.containsKey(p)) {
                                        codeToSend = parentToCode.get(p);
                                    } else {
                                        if (p.contains('premium implementation fees')) codeToSend = 'Implementation_Premium';
                                        else if (p.contains('freemium implementation fees')) codeToSend = 'Implementation_Freemium';
                                        else if (p.contains('premium license fees')) codeToSend = 'License_Premium';
                                        else if (p.contains('freemium license fees')) codeToSend = 'License_Freemium';
                                        else if (p.contains('implementation fees')) codeToSend = 'Implementation';
                                        else if (p.contains('license fees')) codeToSend = 'License';
                                        else if (p.contains('reward')) codeToSend = 'Reward';
                                        else if (p.contains('recognition')) codeToSend = 'Recognition';
                                        else if (p.contains('smarthub')) codeToSend = 'SmartHub';
                                    }
                                }
                            }
                            serviceWrapObj.code = codeToSend;

                            if (!shouldIncludeSavingsService(cliObj, codeToSend)) {
                                continue; 
                            }

                            // OPTIONAL: make sure SmartHub is added only once per solution
                            // (declare this Set<String> once per solutionCode, before looping CLIs)
                            if (codeToSend == 'SmartHub' && addedServiceCodes.contains('SmartHub')) {
                                continue;
                            }
                            addedServiceCodes.add(codeToSend);
                            //serviceWrapList.add(serviceWrapObj);

                            //Logic ends

                            serviceWrapObj.percentage = cliObj.ER_Percentage__c != null ? cliObj.ER_Percentage__c.setScale(6) : 0;
                            //serviceWrapObj.quantity = 0;
                            serviceWrapObj.quantity =
                            (cliObj.Solution_Group__c == 'Savings' || cliObj.Solution_Group__c == 'Engagement')
                            ? (cliObj.ER_Quantity__c != null ? cliObj.ER_Quantity__c : 0)
                            : 0;

                            serviceWrapObj.amount = cliObj.ER_UnitPrice__c != null ? cliObj.ER_UnitPrice__c.setScale(2) : 0;
                            serviceWrapObj.minimum_fee = cliObj.ER_Minimum_Fee__c != null ? cliObj.ER_Minimum_Fee__c.setScale(2) : 0;
                            serviceWrapObj.discount = 0;
                            serviceWrapObj.sales_price = 0;
                            serviceWrapObj.standard_price = 0;
                            serviceWrapObj.solution = cliObj.Solution_Group__c == 'Benefits' ? 'benefit' : cliObj.Solution_Group__c == 'Savings'  ? 'engagement' : null;
                            serviceWrapObj.fee_type = cliObj.Fee_Type__c;
                            serviceWrapObj.product_type = cliObj.Product_Type__c;
                            serviceWrapObj.last_modification_date = cliObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                            serviceWrapList.add(serviceWrapObj);
                        }
                    }
                    //System.debug('contract[0].ER_PaymentTerms2__c'+contract[0].ER_PaymentTerms2__c);
                    //Payment terms

                    /*if (contract[0].ER_PaymentTerms2__c != null && solutionCode == Constants.BENEFIT) {
                        Map<String, String> paymentTermsMap = Constants.getPaymentTermsMap();
                            if(paymentTermsMap.containsKey(contract[0].ER_PaymentTerms2__c)){
                                CreateClientRequestWrapper.ServiceWrapper paymentTermsServiceWrapObj = new CreateClientRequestWrapper.ServiceWrapper();
                                paymentTermsServiceWrapObj.code = paymentTermsMap.get(contract[0].ER_PaymentTerms2__c);
                                paymentTermsServiceWrapObj.percentage = 0;
                                paymentTermsServiceWrapObj.quantity = 0;
                                paymentTermsServiceWrapObj.amount = 0;
                                paymentTermsServiceWrapObj.minimum_fee = 0;
                                paymentTermsServiceWrapObj.discount = 0;
                                paymentTermsServiceWrapObj.sales_price = 0;
                                paymentTermsServiceWrapObj.standard_price = 0;
                                paymentTermsServiceWrapObj.solution = Constants.BENEFIT;
                                paymentTermsServiceWrapObj.last_modification_date = cliSolutionServiceMap.get(solutionCode)[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                                serviceWrapList.add(paymentTermsServiceWrapObj);
                            }
                        }

                        //Payment method
                    if (contract[0].ER_PaymentMethod2__c != null && solutionCode == Constants.BENEFIT) {
                        Map<String, String> paymentMethodMap = Constants.getPaymentMethodMap();
                        if(paymentMethodMap.containsKey(contract[0].ER_PaymentMethod2__c)){
                            CreateClientRequestWrapper.ServiceWrapper paymentMethodServiceWrapObj = new CreateClientRequestWrapper.ServiceWrapper();
                            paymentMethodServiceWrapObj.code = paymentMethodMap.get(contract[0].ER_PaymentMethod2__c);
                            paymentMethodServiceWrapObj.percentage = 0;
                            paymentMethodServiceWrapObj.quantity = 0;
                            paymentMethodServiceWrapObj.amount = 0;
                            paymentMethodServiceWrapObj.minimum_fee = 0;
                            paymentMethodServiceWrapObj.discount = 0;
                            paymentMethodServiceWrapObj.sales_price = 0;
                            paymentMethodServiceWrapObj.standard_price = 0;
                            paymentMethodServiceWrapObj.solution = Constants.BENEFIT;
                            paymentMethodServiceWrapObj.last_modification_date = cliSolutionServiceMap.get(solutionCode)[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                            serviceWrapList.add(paymentMethodServiceWrapObj);
                        }
                    }*/
                    Boolean isBenefitsProduct = false;

                    // Option A: if solutionCode is benefit
                    if (solutionCode != null && solutionCode.equalsIgnoreCase('benefit')) {
                        isBenefitsProduct = true;
                    }

                    // Option B: safer — check CLI group
                    if (!isBenefitsProduct) {
                        for (ER_ContractLineItem__c tmpCli : cliSolutionServiceMap.get(solutionCode)) {
                            if (tmpCli.Solution_Group__c == 'Benefits') {
                                isBenefitsProduct = true;
                                break;
                            }
                        }
                    }

                    // Add Payment Terms service
                    if (isBenefitsProduct && contract[0].ER_PaymentTerms2__c != null) {
                        Map<String, String> paymentTermsMap = Constants.getPaymentTermsMap();
                        if (paymentTermsMap.containsKey(contract[0].ER_PaymentTerms2__c)) {
                            CreateClientRequestWrapper.ServiceWrapper paymentTermsServiceWrapObj =
                                new CreateClientRequestWrapper.ServiceWrapper();

                            paymentTermsServiceWrapObj.code =
                                paymentTermsMap.get(contract[0].ER_PaymentTerms2__c);
                            paymentTermsServiceWrapObj.percentage = 0;
                            paymentTermsServiceWrapObj.quantity = 0;
                            paymentTermsServiceWrapObj.amount = 0;
                            paymentTermsServiceWrapObj.minimum_fee = 0;
                            paymentTermsServiceWrapObj.discount = 0;
                            paymentTermsServiceWrapObj.sales_price = 0;
                            paymentTermsServiceWrapObj.standard_price = 0;
                            paymentTermsServiceWrapObj.solution = 'benefit';
                            paymentTermsServiceWrapObj.last_modification_date =
                                cliSolutionServiceMap.get(solutionCode)[0].LastModifiedDate
                                    .formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                            serviceWrapList.add(paymentTermsServiceWrapObj);
                        }
                    }

                    // Add Payment Method service
                    if (isBenefitsProduct && contract[0].ER_PaymentMethod2__c != null) {
                        Map<String, String> paymentMethodMap = Constants.getPaymentMethodMap();
                        if (paymentMethodMap.containsKey(contract[0].ER_PaymentMethod2__c)) {
                            CreateClientRequestWrapper.ServiceWrapper paymentMethodServiceWrapObj =
                                new CreateClientRequestWrapper.ServiceWrapper();

                            paymentMethodServiceWrapObj.code =
                                paymentMethodMap.get(contract[0].ER_PaymentMethod2__c);
                            paymentMethodServiceWrapObj.percentage = 0;
                            paymentMethodServiceWrapObj.quantity = 0;
                            paymentMethodServiceWrapObj.amount = 0;
                            paymentMethodServiceWrapObj.minimum_fee = 0;
                            paymentMethodServiceWrapObj.discount = 0;
                            paymentMethodServiceWrapObj.sales_price = 0;
                            paymentMethodServiceWrapObj.standard_price = 0;
                            paymentMethodServiceWrapObj.solution = 'benefit';
                            paymentMethodServiceWrapObj.last_modification_date =
                                cliSolutionServiceMap.get(solutionCode)[0].LastModifiedDate
                                    .formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                            serviceWrapList.add(paymentMethodServiceWrapObj);
                        }
                    }
                    //Adding Crediting delays
                    if (isBenefitsProduct && contract[0].Creditting__c != null) {
                        Map<String, String> creditingMap = Constants.getCreditingMap();
                        if (creditingMap.containsKey(contract[0].Creditting__c)) {
                            CreateClientRequestWrapper.ServiceWrapper creditingServiceWrapObj =
                                new CreateClientRequestWrapper.ServiceWrapper();

                            creditingServiceWrapObj.code = creditingMap.get(contract[0].Creditting__c);
                            creditingServiceWrapObj.percentage = 0;
                            creditingServiceWrapObj.quantity = 0;
                            creditingServiceWrapObj.amount = 0;
                            creditingServiceWrapObj.minimum_fee = 0;
                            creditingServiceWrapObj.discount = 0;
                            creditingServiceWrapObj.sales_price = 0;
                            creditingServiceWrapObj.standard_price = 0;
                            creditingServiceWrapObj.solution = 'benefit';
                            creditingServiceWrapObj.last_modification_date =
                                cliSolutionServiceMap.get(solutionCode)[0].LastModifiedDate
                                    .formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                            serviceWrapList.add(creditingServiceWrapObj);
                        }
                    }
                    prodWrapObj.services = serviceWrapList;
                    contractProductWrapList.add(prodWrapObj);
                }
            }
            contractWrap.contract_products = contractProductWrapList;
            contractWrapList.add(contractWrap);
            wrapObj.contracts = contractWrapList;
            
            //Legal Site
            CreateClientRequestWrapper.LegalSiteWrapper legalWrap = new CreateClientRequestWrapper.LegalSiteWrapper();
            legalWrap.contact_id = operationalRoleContactIdMap.containsKey('Primary Contact') ? operationalRoleContactIdMap.get('Primary Contact') : null;
            legalWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
            CreateClientRequestWrapper.AddressWrapper legalAddressWrap = new CreateClientRequestWrapper.AddressWrapper();
            legalAddressWrap.street = contract[0].Account.BillingStreet;
            legalAddressWrap.street_number = null;
            legalAddressWrap.po_box = '';
            legalAddressWrap.zip_code = contract[0].Account.BillingPostalCode;
            legalAddressWrap.city = contract[0].Account.BillingCity;
            legalAddressWrap.country_code = contract[0].Account.ER_Country_Code__c != null ? contract[0].Account.ER_Country_Code__c.toLowerCase() : null;  
            legalWrap.address = legalAddressWrap;
            if(!isFinancialCenterEmpty){
                for(ER_Financial_Center__c fcObj : financialCenterList){
                    // Resolve ACR ID for Financial Center Contact
                    Id acrIdForFcContact = fcObj.ER_Contact__c != null
                        ? contactToAcrIdMap.get(fcObj.ER_Contact__c)
                        : null;

                    Id fcCrmId = acrIdForFcContact != null
                        ? acrIdForFcContact
                        : fcObj.ER_Contact__c;

                    //Financial Center
                    CreateClientRequestWrapper.FinancialCenterWrapper financialWrap = new CreateClientRequestWrapper.FinancialCenterWrapper();
                    financialWrap.crm_id = fcObj.Id;
                    financialWrap.name = fcObj.Name;
                    //financialWrap.contact_id = fcobj.ER_Contact__c;
                    //New
                    financialWrap.contact_id = fcCrmId; // this should send the acr id
                    //financialWrap.contact_id = fcObj.ER_Contact__c;
                    financialWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                    financialWrap.last_modification_date = fcObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                    //FC Address
                    CreateClientRequestWrapper.AddressWrapper financialAddressWrap = new CreateClientRequestWrapper.AddressWrapper();
                    financialAddressWrap.street = fcObj.ER_Invoicing_Street__c;
                    financialAddressWrap.street_number = null;
                    financialAddressWrap.po_box = '';
                    financialAddressWrap.zip_code = fcObj.ER_Invoicing_Zip_Code__c;
                    financialAddressWrap.city = fcObj.ER_Invoicing_City__c;
                    financialAddressWrap.country_code = fcObj.ER_Invoicing_Country_Code__c != null ? fcObj.ER_Invoicing_Country_Code__c.toLowerCase() : null;
                    
                    //FC Bank Account
                    CreateClientRequestWrapper.BankAccountWrapper bankAccountWrap = new CreateClientRequestWrapper.BankAccountWrapper();
                    bankAccountWrap.iban = fcObj.ER_Bank_Account__r.ER_IBAN__c;
                    bankAccountWrap.bic = fcObj.ER_Bank_Account__r.ER_BIC__c;
                    deliverySiteWrapList = new List<CreateClientRequestWrapper.DeliverySiteWrapper>();
                    if (financialCenterDeliverySiteMap.containsKey(fcObj.Id)) {
                        for (ER_Delivery_Site__c dsObj : financialCenterDeliverySiteMap.get(fcObj.Id)) {
                                Id acrIdForDsContact = dsObj.ER_Delivery_Contact__c != null ? contactToAcrIdMap.get(dsObj.ER_Delivery_Contact__c) : null;
                                Id dsCrmId = acrIdForDsContact != null ? acrIdForDsContact : dsObj.ER_Delivery_Contact__c;
                            //FC Delivery Site
                            CreateClientRequestWrapper.DeliverySiteWrapper dsWrap = new CreateClientRequestWrapper.DeliverySiteWrapper();
                            dsWrap.crm_id = dsObj.Id;
                            dsWrap.name = dsObj.Name;
                            //New
                            dsWrap.contact_id = dsCrmId;
                            dsWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                            dsWrap.last_modification_date = dsObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                            
                            //FC delivery Site Address
                            CreateClientRequestWrapper.AddressWrapper deliveryAddWrap = new CreateClientRequestWrapper.AddressWrapper();
                            deliveryAddWrap.street = dsObj.ER_Street__c;
                            deliveryAddWrap.street_number = null;
                            deliveryAddWrap.po_box = '';
                            deliveryAddWrap.zip_code = dsObj.ER_Zip_Code__c;
                            deliveryAddWrap.city = dsObj.ER_City__c;
                            deliveryAddWrap.country_code = dsObj.ER_Country_Code__c != null ? dsObj.ER_Country_Code__c.toLowerCase() : null;
                            dsWrap.address = deliveryAddWrap;
                            distributionPointWrapList = new List<CreateClientRequestWrapper.DistributionPointWrapper>();
                            if(deliverySiteDistributionPointMap.containsKey(dsObj.Id)){
                                for(ER_Distribution_Point__c dpObj : deliverySiteDistributionPointMap.get(dsObj.Id)){
                                    //Commenting
                                    //Id dpAcrId = dpObj.ER_Contact__c != null ? contactToAcrIdMap.get(dpObj.ER_Contact__c) : null;
                                    //Id dpCrmId = (dpAcrId != null) ? dpAcrId : dpObj.ER_Contact__c;
                                    //FC Delivery Site Distribution Point
                                    Id orderContactAcrId = operationalRoleContactIdMap.get('Order Contact');
                                    Id primaryContactAcrId = operationalRoleContactIdMap.get('Primary Contact');

                                    // If DP doesn't have its own contact, use Order Contact ACR (fallback to Primary Contact ACR)
                                    Id dpContactAcrId = orderContactAcrId != null ? orderContactAcrId : primaryContactAcrId;
                                    CreateClientRequestWrapper.DistributionPointWrapper distPointWrap = new CreateClientRequestWrapper.DistributionPointWrapper();
                                    distPointWrap.crm_id = dpObj.Id;
                                    distPointWrap.name = dpObj.Name;
                                    //New
                                    distPointWrap.contact_id = dpContactAcrId;
                                    //distPointWrap.contact_id = dpObj.ER_Contact__c;
                                    //distPointWrap.contact_id = dsObj.ER_Delivery_Contact__c;
                                    distPointWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                                    distPointWrap.last_modification_date = dpObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                                    
                                    //FC Delivery Site Distribution Point Address
                                    CreateClientRequestWrapper.AddressWrapper distPointAddWrap = new CreateClientRequestWrapper.AddressWrapper();
                                    distPointAddWrap.street = dpObj.ER_Street__c;
                                    distPointAddWrap.street_number = null;
                                    distPointAddWrap.po_box = '';
                                    distPointAddWrap.zip_code = dpObj.ER_Zip_Code__c;
                                    distPointAddWrap.city = dpObj.ER_City__c;
                                    distPointAddWrap.country_code = dpObj.ER_Country_Code__c != null ? dpObj.ER_Country_Code__c.toLowerCase() : null;
                                    distPointWrap.address = distPointAddWrap;
                                    distributionPointWrapList.add(distPointWrap);
                                }
                            }else{
                                // Create Distribution Point Wrapper
                                CreateClientRequestWrapper.DistributionPointWrapper distPointWrap = new CreateClientRequestWrapper.DistributionPointWrapper();
                                distPointWrap.crm_id = 'DP_' + fcObj.Id;
                                distPointWrap.name = dsObj.Name;
                                distPointWrap.contact_id = operationalRoleContactIdMap.containsKey('Primary Contact') ? operationalRoleContactIdMap.get('Primary Contact') : null;
                                distPointWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                                distPointWrap.last_modification_date = dsObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                                // Distribution Point Address
                                CreateClientRequestWrapper.AddressWrapper distPointAddWrap = new CreateClientRequestWrapper.AddressWrapper();
                                distPointAddWrap.street = dsObj.ER_Street__c;
                                distPointAddWrap.street_number = null;
                                distPointAddWrap.po_box = '';
                                distPointAddWrap.zip_code = dsObj.ER_Zip_Code__c;
                                distPointAddWrap.city = dsObj.ER_City__c;
                                distPointAddWrap.country_code = dsObj.ER_Country_Code__c != null ? dsObj.ER_Country_Code__c.toLowerCase() : null;
                                distPointWrap.address = distPointAddWrap;

                                // Add distribution point to the list
                                distributionPointWrapList.add(distPointWrap);
                            }
                            dsWrap.distribution_points = distributionPointWrapList;
                            deliverySiteWrapList.add(dsWrap);
                        }
                    }else{
                        // Create Delivery Site Wrapper
                        CreateClientRequestWrapper.DeliverySiteWrapper dsWrap = new CreateClientRequestWrapper.DeliverySiteWrapper();
                        dsWrap.crm_id = 'DS_' + fcObj.Id;
                        dsWrap.name = fcObj.Name;
                        dsWrap.contact_id = operationalRoleContactIdMap.containsKey('Primary Contact') ? operationalRoleContactIdMap.get('Primary Contact') : null;
                        dsWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                        dsWrap.last_modification_date = fcObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                        //Delivery Site Address
                        CreateClientRequestWrapper.AddressWrapper deliveryAddWrap = new CreateClientRequestWrapper.AddressWrapper();
                        deliveryAddWrap.street = fcObj.ER_Invoicing_Street__c;
                        deliveryAddWrap.street_number = null;
                        deliveryAddWrap.po_box = '';
                        deliveryAddWrap.zip_code = fcObj.ER_Invoicing_Zip_Code__c;
                        deliveryAddWrap.city = fcObj.ER_Invoicing_City__c;
                        deliveryAddWrap.country_code = fcObj.ER_Invoicing_Country_Code__c != null ? fcObj.ER_Invoicing_Country_Code__c.toLowerCase() : null;
                        dsWrap.address = deliveryAddWrap;

                        // Create Distribution Point Wrapper
                        CreateClientRequestWrapper.DistributionPointWrapper distPointWrap = new CreateClientRequestWrapper.DistributionPointWrapper();
                        distPointWrap.crm_id = 'DP_' + fcObj.Id;
                        distPointWrap.name = fcObj.Name;
                        distPointWrap.contact_id = operationalRoleContactIdMap.containsKey('Primary Contact') ? operationalRoleContactIdMap.get('Primary Contact') : null;
                        distPointWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                        distPointWrap.last_modification_date = fcObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                        // Distribution Point Address
                        CreateClientRequestWrapper.AddressWrapper distPointAddWrap = new CreateClientRequestWrapper.AddressWrapper();
                        distPointAddWrap.street = fcObj.ER_Invoicing_Street__c;
                        distPointAddWrap.street_number = null;
                        distPointAddWrap.po_box = '';
                        distPointAddWrap.zip_code = fcObj.ER_Invoicing_Zip_Code__c;
                        distPointAddWrap.city = fcObj.ER_Invoicing_City__c;
                        distPointAddWrap.country_code = fcObj.ER_Invoicing_Country_Code__c != null ? fcObj.ER_Invoicing_Country_Code__c.toLowerCase() : null;
                        distPointWrap.address = distPointAddWrap;

                        // Assigning distribution point to delivery site
                        dsWrap.distribution_points = new List<CreateClientRequestWrapper.DistributionPointWrapper>{distPointWrap};

                        // Add delivery site to the list
                        deliverySiteWrapList.add(dsWrap);
                    }    
                    
                    financialWrap.address = financialAddressWrap;
                    financialWrap.bank_account = bankAccountWrap;
                    financialWrap.delivery_sites = deliverySiteWrapList;
                    
                    financialWrapList.add(financialWrap);
                }
            }else{

                // Financial Center Wrapper
                CreateClientRequestWrapper.FinancialCenterWrapper financialWrap = new CreateClientRequestWrapper.FinancialCenterWrapper();
                financialWrap.crm_id = null;
                financialWrap.name = contract[0].Account.Name;
                financialWrap.contact_id = operationalRoleContactIdMap.containsKey('Billing Contact') ? operationalRoleContactIdMap.get('Billing Contact') : null;
                financialWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                financialWrap.last_modification_date = contract[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                // Financial Center Address Wrapper
                CreateClientRequestWrapper.AddressWrapper financialAddressWrap = new CreateClientRequestWrapper.AddressWrapper();
                financialAddressWrap.street = contract[0].Account.BillingStreet;
                financialAddressWrap.street_number = null;
                financialAddressWrap.po_box = '';
                financialAddressWrap.zip_code = contract[0].Account.BillingPostalCode;
                financialAddressWrap.city = contract[0].Account.BillingCity;
                financialAddressWrap.country_code = contract[0].Account.ER_Country_Code__c != null ? contract[0].Account.ER_Country_Code__c.toLowerCase() : null;

                // Financial Center Bank Account Wrapper
                CreateClientRequestWrapper.BankAccountWrapper bankAccountWrap = new CreateClientRequestWrapper.BankAccountWrapper();
                //Commenting this (date 9/2/26)
                //bankAccountWrap.iban = null;
                //bankAccountWrap.bic = null;

                // Delivery Site Wrapper
                CreateClientRequestWrapper.DeliverySiteWrapper dsWrap = new CreateClientRequestWrapper.DeliverySiteWrapper();
                dsWrap.crm_id = null;
                dsWrap.name = contract[0].Account.Name;
                dsWrap.contact_id = operationalRoleContactIdMap.containsKey('Primary Contact') ? operationalRoleContactIdMap.get('Primary Contact') : null;
                dsWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                dsWrap.last_modification_date = contract[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                // Delivery Site Address Wrapper
                CreateClientRequestWrapper.AddressWrapper deliveryAddWrap = new CreateClientRequestWrapper.AddressWrapper();
                deliveryAddWrap.street = contract[0].Account.BillingStreet;
                deliveryAddWrap.street_number = null;
                deliveryAddWrap.po_box = '';
                deliveryAddWrap.zip_code = contract[0].Account.BillingPostalCode;
                deliveryAddWrap.country_code = contract[0].Account.ER_Country_Code__c != null ? contract[0].Account.ER_Country_Code__c.toLowerCase() : null;
                dsWrap.address = deliveryAddWrap;

                // Distribution Point Wrapper
                CreateClientRequestWrapper.DistributionPointWrapper distPointWrap = new CreateClientRequestWrapper.DistributionPointWrapper();
                distPointWrap.crm_id = null;
                distPointWrap.name = contract[0].Account.Name;
                distPointWrap.contact_id = operationalRoleContactIdMap.containsKey('Primary Contact') ? operationalRoleContactIdMap.get('Primary Contact') : null;
                distPointWrap.language_code = contract[0].Account.ER_Language__c.toLowerCase();
                distPointWrap.last_modification_date = contract[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                // Distribution Point Address Wrapper
                distPointWrap.address = new CreateClientRequestWrapper.AddressWrapper();
                distPointWrap.address.street = contract[0].Account.BillingStreet;
                distPointWrap.address.street_number = null;
                distPointWrap.address.po_box = '';
                distPointWrap.address.zip_code = contract[0].Account.BillingPostalCode;
                distPointWrap.address.city = contract[0].Account.BillingCity;
                distPointWrap.address.country_code = contract[0].Account.ER_Country_Code__c != null ? contract[0].Account.ER_Country_Code__c.toLowerCase() : null;

                // Assign hierarchy
                dsWrap.distribution_points = new List<CreateClientRequestWrapper.DistributionPointWrapper>{distPointWrap};
                financialWrap.delivery_sites = new List<CreateClientRequestWrapper.DeliverySiteWrapper>{dsWrap};
                financialWrap.address = financialAddressWrap;
                financialWrap.bank_account = bankAccountWrap;

                // Final Financial Wrap List
                financialWrapList = new List<CreateClientRequestWrapper.FinancialCenterWrapper>{financialWrap};

            }
            
			legalWrap.financial_centers = financialWrapList;
            wrapObj.legal_site = legalWrap;
            wrapObj.contacts = contactWrapList;
            //wrapper = JSON.serialize(wrapObj).replaceAll('street_number', 'number');
        	//return wrapper;
            if (contractType == 'Savings') {
                wrapper = buildSavingsJson(wrapObj).replaceAll('street_number', 'number');
                    return wrapper;
                //return buildSavingsJson(wrapObj).replaceAll('street_number', 'number');
            }

            // default (Benefit) – unchanged behavior
            //wrapper = JSON.serialize(wrapObj).replaceAll('street_number', 'number');
            //return wrapper;
            //commenting above and adding new line for benefit wrapper
            return buildBenefitJson(wrapObj).replaceAll('street_number', 'number');
        }
        
        return null;
    }

    //New Logic to filter Smarthub acc to the contract line item Name
    private static Boolean shouldIncludeSavingsService(ER_ContractLineItem__c cliObj, String codeToSend) {
        if (String.isBlank(codeToSend)) return true;

        // Only include SmartHub if the CLI Name is exactly "SmartHub Admin Access"
        if (codeToSend == 'SmartHub') {
            return cliObj != null
                && !String.isBlank(cliObj.Name)
                && cliObj.Name.trim().equalsIgnoreCase('SmartHub Admin Access');
        }

        return true;
    }

    private static AccountContactRelation findMatchingAcr(
                List<AccountContactRelation> acrList,
                String contractRole
            ) {
                if (acrList == null) return null;

                for (AccountContactRelation acr : acrList) {
                    if (acr.Roles != null && acr.Roles.contains(contractRole)) {
                        return acr;
                    }
                }
                return null;
            }
    

             private static void writeStringOrNull(JSONGenerator gen, String fieldName, String value) {
    if (value == null) gen.writeNullField(fieldName);
    else gen.writeStringField(fieldName, value);
}

private static void writeDecimalOrNull(JSONGenerator gen, String fieldName, Decimal value) {
    if (value == null) gen.writeNullField(fieldName);
    else gen.writeNumberField(fieldName, value);
}


//JSON Method for update savings (creates json file for savings)
   /*private static String buildUpdateSavingsJson(UpdateClientRequestWrapper w) {
    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();

    // top-level (same as update benefit fields)
    writeStringOrNull(gen, 'crm_id', w.crm_id);
    writeStringOrNull(gen, 'card_id', w.card_id);
    writeStringOrNull(gen, 'name', w.name);
    writeStringOrNull(gen, 'legal_name', w.legal_name);
    writeStringOrNull(gen, 'company_registration_number', w.company_registration_number);
    writeStringOrNull(gen, 'vat_number', w.vat_number);
    writeStringOrNull(gen, 'vat_type', w.vat_type);
    writeStringOrNull(gen, 'last_modification_date', w.last_modification_date);

    // legal_site
    gen.writeFieldName('legal_site');
    if (w.legal_site == null) {
        gen.writeNull();
    } else {
        gen.writeStartObject();
        writeStringOrNull(gen, 'contact_id', w.legal_site.contact_id);

        gen.writeFieldName('address');
        if (w.legal_site.address == null) {
            gen.writeNull();
        } else {
            gen.writeStartObject();
            writeStringOrNull(gen, 'street', w.legal_site.address.street);
            // IMPORTANT: output "number" directly so no replaceAll needed
            writeStringOrNull(gen, 'number', w.legal_site.address.street_number);
            writeStringOrNull(gen, 'po_box', w.legal_site.address.po_box);
            writeStringOrNull(gen, 'zip_code', w.legal_site.address.zip_code);
            writeStringOrNull(gen, 'city', w.legal_site.address.city);
            writeStringOrNull(gen, 'country_code', w.legal_site.address.country_code);
            writeStringOrNull(gen, 'last_modification_date', w.legal_site.address.last_modification_date);
            gen.writeEndObject();
        }

        gen.writeEndObject();
    }

    // contacts
    gen.writeFieldName('contacts');
    gen.writeStartArray();
    if (w.contacts != null) {
        for (UpdateClientRequestWrapper.Contact c : w.contacts) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'crm_id', c.crm_id);
            writeStringOrNull(gen, 'card_id', c.card_id);
            writeStringOrNull(gen, 'first_name', c.first_name);
            writeStringOrNull(gen, 'last_name', c.last_name);
            writeStringOrNull(gen, 'language', c.language);
            writeStringOrNull(gen, 'email', c.email);
            writeStringOrNull(gen, 'phone_number', c.phone_number);

            // If you want to include mobile_number in savings update, keep it.
            // If you want it optional, wrap it like benefit create does.
            //Commenting mobile number
            //writeStringOrNull(gen, 'mobile_number', c.mobile_number);

            writeStringOrNull(gen, 'last_modification_date', c.last_modification_date);
            gen.writeEndObject();
        }
    }
    gen.writeEndArray();

    gen.writeEndObject();
    return gen.getAsString();
}*/

//JSON Method for update savings (creates json file for savings) ends
//---------------------------------------------------------------------------
//JSON Method for benefit starts (creates json file for benefit)
private static String buildBenefitJson(CreateClientRequestWrapper w) {
    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();

    // top-level
    writeStringOrNull(gen, 'crm_id', w.crm_id);
    writeStringOrNull(gen, 'company_registration_number', w.company_registration_number);
    writeStringOrNull(gen, 'last_modification_date', w.last_modification_date);
    writeStringOrNull(gen, 'name', w.name);
    writeStringOrNull(gen, 'legal_name', w.legal_name);
    writeStringOrNull(gen, 'vat_number', w.vat_number);
    writeStringOrNull(gen, 'vat_type', w.vat_type);
    if (w.engagement_platform_id != null) {
        gen.writeStringField('engagement_platform_id', w.engagement_platform_id);
    }

    // contacts (if benefit should still send them)
    gen.writeFieldName('contacts');
    gen.writeStartArray();
    if (w.contacts != null) {
        for (CreateClientRequestWrapper.ContactWrapper c : w.contacts) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'first_name', c.first_name);
            writeStringOrNull(gen, 'last_name', c.last_name);
            writeStringOrNull(gen, 'language', c.language);
            writeStringOrNull(gen, 'crm_id', c.crm_id);
            writeStringOrNull(gen, 'last_modification_date', c.last_modification_date);
            writeStringOrNull(gen, 'email', c.email);
            writeStringOrNull(gen, 'phone_number', c.phone_number);

            // include only if you want it in Benefit
            if (!String.isBlank(c.mobile_number)) {
                gen.writeStringField('mobile_number', c.mobile_number);
            }

            gen.writeEndObject();
        }
    }
    gen.writeEndArray();

    // contracts
    gen.writeFieldName('contracts');
    gen.writeStartArray();

    if (w.contracts != null) {
        for (Object oCon : w.contracts) {
            CreateClientRequestWrapper.ContractWrapper con =
                (CreateClientRequestWrapper.ContractWrapper) oCon;

            gen.writeStartObject();

            writeStringOrNull(gen, 'crm_id', con.crm_id);
            writeStringOrNull(gen, 'name', con.name);
            writeStringOrNull(gen, 'start_date', con.start_date);
            writeStringOrNull(gen, 'signed_date', con.signed_date);

            // If you want to REMOVE benefit fields, just don't write them.
            // Example: remove end_date/payment_method/payment_deadline/crediting_delay:
            // (do nothing)

            //writeStringOrNull(gen, 'program_name', con.program_name);
            //writeStringOrNull(gen, 'customer_domain', con.customer_domain);
            //writeStringOrNull(gen, 'customer_management', con.customer_management);
            writeStringOrNull(gen, 'delivery_type', con.delivery_type);
            //writeStringOrNull(gen, 'invoicing_frequency', con.invoicing_frequency);
            //writeStringOrNull(gen, 'selection_method', con.selection_method);
            writeStringOrNull(gen, 'invoicing_contact_id', con.invoicing_contact_id);
            writeStringOrNull(gen, 'contact_counterparty_signed_id', con.contact_counterparty_signed_id);
            writeStringOrNull(gen, 'last_modification_date', con.last_modification_date);

            // contract_products
            gen.writeFieldName('contract_products');
            gen.writeStartArray();
            if (con.contract_products != null) {
                for (CreateClientRequestWrapper.ContractProductWrapper cp : con.contract_products) {
                    gen.writeStartObject();
                    writeStringOrNull(gen, 'start_date', cp.start_date);
                    writeStringOrNull(gen, 'signed_date', cp.signed_date);
                    writeStringOrNull(gen, 'order_contact_id', cp.order_contact_id);
                    writeStringOrNull(gen, 'product', cp.product);
                    writeStringOrNull(gen, 'promo_code', cp.promo_code);
                    // services
                    gen.writeFieldName('services');
                    gen.writeStartArray();
                    if (cp.services != null) {
                        for (Object oSrv : cp.services) {
                            CreateClientRequestWrapper.ServiceWrapper s =
                                (CreateClientRequestWrapper.ServiceWrapper) oSrv;

                            gen.writeStartObject();
                            writeStringOrNull(gen, 'solution', s.solution);
                            writeStringOrNull(gen, 'code', s.code);
                            gen.writeNumberField('amount', s.amount == null ? 0 : s.amount);
                            gen.writeNumberField('standard_price', s.standard_price == null ? 0 : s.standard_price);
                            gen.writeNumberField('sales_price', s.sales_price == null ? 0 : s.sales_price);
                            gen.writeNumberField('quantity', s.quantity == null ? 0 : s.quantity);
                            gen.writeNumberField('percentage', s.percentage == null ? 0 : s.percentage);
                            gen.writeNumberField('minimum_fee', s.minimum_fee == null ? 0 : s.minimum_fee);
                            gen.writeNumberField('discount', s.discount == null ? 0 : s.discount);

                            writeStringOrNull(gen, 'last_modification_date', s.last_modification_date);

                            // omit any unwanted service fields by not writing them
                            gen.writeEndObject();
                        }
                    }
                    gen.writeEndArray();

                    gen.writeEndObject();
                }
            }
            gen.writeEndArray();

            gen.writeEndObject();
        }
    }
    gen.writeEndArray();

    // legal_site
    gen.writeFieldName('legal_site');
    if (w.legal_site == null) gen.writeNull();
    else writeLegalSite(gen, w.legal_site);

    gen.writeEndObject();
    return gen.getAsString();
}

//Method for benefit ends


        private static String buildSavingsJson(CreateClientRequestWrapper w) {
    JSONGenerator gen = JSON.createGenerator(true);

    gen.writeStartObject();

    // Top-level
    writeStringOrNull(gen, 'crm_id', w.crm_id);
    writeStringOrNull(gen, 'company_registration_number', w.company_registration_number);
    writeStringOrNull(gen, 'last_modification_date', w.last_modification_date);
    writeStringOrNull(gen, 'name', w.name);
    writeStringOrNull(gen, 'legal_name', w.legal_name);
    writeStringOrNull(gen, 'vat_number', w.vat_number);
    writeStringOrNull(gen, 'vat_type', w.vat_type);
    if (w.engagement_platform_id != null) {
        gen.writeStringField('engagement_platform_id', w.engagement_platform_id);
    }

    // contacts
    gen.writeFieldName('contacts');
    gen.writeStartArray();
    if (w.contacts != null) {
        for (CreateClientRequestWrapper.ContactWrapper c : w.contacts) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'first_name', c.first_name);
            writeStringOrNull(gen, 'last_name', c.last_name);
            writeStringOrNull(gen, 'language', c.language);
            writeStringOrNull(gen, 'crm_id', c.crm_id);
            writeStringOrNull(gen, 'last_modification_date', c.last_modification_date);
            writeStringOrNull(gen, 'email', c.email);
            writeStringOrNull(gen, 'phone_number', c.phone_number);
            writeStringOrNull(gen, 'mobile_number', c.mobile_number);

            // only write if present
            /*if (!String.isBlank(c.mobile_number)) {
                gen.writeStringField('mobile_number', c.mobile_number);
            }*/
            gen.writeEndObject();
        }
    }
    gen.writeEndArray();

    // contracts
    gen.writeFieldName('contracts');
    gen.writeStartArray();
    if (w.contracts != null) {

        // in your wrapper, w.contracts behaves like List<Object> in generator context
        for (Object oCon : w.contracts) {
            CreateClientRequestWrapper.ContractWrapper con = (CreateClientRequestWrapper.ContractWrapper) oCon;
            gen.writeStartObject();
            writeStringOrNull(gen, 'crm_id', con.crm_id);
            writeStringOrNull(gen, 'last_modification_date', con.last_modification_date);
            writeStringOrNull(gen, 'name', con.name);
            writeStringOrNull(gen, 'start_date', con.start_date);
            gen.writeNullField('end_date');
            writeStringOrNull(gen, 'signed_date', con.signed_date);
            writeStringOrNull(gen, 'invoicing_contact_id', con.invoicing_contact_id);
            writeStringOrNull(gen, 'contact_counterparty_signed_id', con.contact_counterparty_signed_id);
            writeStringOrNull(gen, 'program_name', con.program_name);
            writeStringOrNull(gen, 'customer_domain', con.customer_domain);
            writeStringOrNull(gen, 'selection_method', con.selection_method);
            writeStringOrNull(gen, 'invoicing_frequency', con.invoicing_frequency);
            writeStringOrNull(gen, 'customer_management', con.customer_management);
            writeStringOrNull(gen, 'payment_method', con.payment_method);
            writeStringOrNull(gen, 'payment_deadline', con.payment_deadline);
            writeStringOrNull(gen, 'crediting_delay', con.crediting_delay);
            gen.writeFieldName('contract_products');
            gen.writeStartArray();

            if (con.contract_products != null && !con.contract_products.isEmpty()) {
                for (CreateClientRequestWrapper.ContractProductWrapper cp : con.contract_products) {
                    gen.writeStartObject();
                    writeStringOrNull(gen, 'start_date', cp.start_date);
                    writeStringOrNull(gen, 'signed_date', cp.signed_date);
                    writeStringOrNull(gen, 'promo_code', cp.promo_code);
                    writeStringOrNull(gen, 'product', cp.product);
                    //Commenting this part since baptiste asked to display this only once
                    writeStringOrNull(gen, 'order_contact_id', cp.order_contact_id);
                    if (cp.services != null && !cp.services.isEmpty()) {
                        gen.writeFieldName('services');
                        gen.writeStartArray();

                        // cp.services might be List<Object>
                        for (Object oSrv : cp.services) {
                            CreateClientRequestWrapper.ServiceWrapper s = (CreateClientRequestWrapper.ServiceWrapper) oSrv;

                            gen.writeStartObject();
                            writeStringOrNull(gen, 'solution', s.solution);
                            writeStringOrNull(gen, 'last_modification_date', s.last_modification_date);
                            writeStringOrNull(gen, 'code', s.code);
                            gen.writeNumberField('amount', s.amount == null ? 0 : s.amount);
                            //Adding Quantity
                            gen.writeNumberField('quantity', s.quantity == null ? 0 : s.quantity);
                            gen.writeEndObject();
                        }

                        gen.writeEndArray();
                    }
                    gen.writeEndObject();
                }
            }
            gen.writeEndArray();   // contract_products
            gen.writeEndObject();  // contract
        }
    }
    gen.writeEndArray(); // contracts

    // legal_site (top level)
    gen.writeFieldName('legal_site');
    if (w.legal_site == null) gen.writeNull();
    else writeLegalSite(gen, w.legal_site);

    gen.writeEndObject();
    return gen.getAsString();
}




//new method for udpate savings json
/*private UpdateClientRequestWrapper buildUpdateClientWrapObj(Id accountId) {

    UpdateClientRequestWrapper wrapObj = new UpdateClientRequestWrapper();
    List<UpdateClientRequestWrapper.Contact> contactWrapList = new List<UpdateClientRequestWrapper.Contact>();

    List<Account> accList = [
        SELECT Id,
               ER_Card_Client_Operational_System_ID__c,
               Name,
               ER_Registration_Number__c,
               HU_HQ_Contact__c,
               ER_Legal_Name__c,
               BillingCountry,
               ER_VAT_Number__c,
               ER_Not_subject_to_VAT__c,
               ER_Country_Code__c,
               BillingCity,
               BillingPostalCode,
               BillingStreet,
               LastModifiedDate
        FROM Account
        WHERE Id = :accountId
    ];

    if (accList.isEmpty()) {
        return null;
    }

    // Map ContactId -> ACR Id
    Map<Id, Id> contactToAcrIdMap = new Map<Id, Id>();
    for (AccountContactRelation acr : [
        SELECT Id, ContactId
        FROM AccountContactRelation
        WHERE AccountId = :accList[0].Id
    ]) {
        if (acr.ContactId != null && !contactToAcrIdMap.containsKey(acr.ContactId)) {
            contactToAcrIdMap.put(acr.ContactId, acr.Id);
        }
    }

    // Account
    wrapObj.crm_id = accList[0].Id;
    wrapObj.card_id = accList[0].ER_Card_Client_Operational_System_ID__c;
    wrapObj.name = accList[0].Name;
    wrapObj.legal_name = accList[0].ER_Legal_Name__c;
    wrapObj.company_registration_number = accList[0].ER_Registration_Number__c;
    wrapObj.vat_number = accList[0].ER_VAT_Number__c;
    wrapObj.vat_type = accList[0].ER_Not_subject_to_VAT__c ? 'not_liable' : 'liable';
    wrapObj.last_modification_date = accList[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

    // Legal Site
    UpdateClientRequestWrapper.LegalSite legalSiteWrapper = new UpdateClientRequestWrapper.LegalSite();

    // HQ Contact -> send ACR Id if present else ContactId
    Id hqContactId = accList[0].HU_HQ_Contact__c; // ContactId
    Id hqAcrId = (hqContactId != null) ? contactToAcrIdMap.get(hqContactId) : null;
    legalSiteWrapper.contact_id = (hqAcrId != null) ? hqAcrId : hqContactId;

    // Legal Site Address
    UpdateClientRequestWrapper.Address addressWrap = new UpdateClientRequestWrapper.Address();
    addressWrap.street = accList[0].BillingStreet;
    addressWrap.street_number = null;
    addressWrap.po_box = '';
    addressWrap.zip_code = accList[0].BillingPostalCode;
    addressWrap.city = accList[0].BillingCity;
    addressWrap.country_code = accList[0].ER_Country_Code__c != null ? accList[0].ER_Country_Code__c.toLowerCase() : null;
    addressWrap.last_modification_date = accList[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

    legalSiteWrapper.address = addressWrap;

    // Contacts
    for (Contact conObj : [
        SELECT Id,
               ER_Client_Card_Operational_System_ID__c,
               LastModifiedDate,
               Phone,
               MobilePhone,
               Email,
               ER_Language__c,
               LastName,
               FirstName
        FROM Contact
        WHERE AccountId = :accList[0].Id
          AND ER_Status__c = 'Active'
          AND BE_Operational_Role__c != null
          AND ER_Client_Card_Operational_System_ID__c != null
        ORDER BY LastModifiedDate DESC
    ]) {
        UpdateClientRequestWrapper.Contact conWrap = new UpdateClientRequestWrapper.Contact();

        // Send ACR Id if present else ContactId
        Id acrId = contactToAcrIdMap.get(conObj.Id);
        conWrap.crm_id = (acrId != null) ? acrId : conObj.Id;

        conWrap.card_id = conObj.ER_Client_Card_Operational_System_ID__c;
        conWrap.first_name = conObj.FirstName;
        conWrap.last_name = conObj.LastName;
        conWrap.language = conObj.ER_Language__c != null ? conObj.ER_Language__c.toLowerCase() : null;
        conWrap.email = conObj.Email;
        conWrap.phone_number = conObj.Phone;
        // conWrap.mobile_number = conObj.MobilePhone; // keep commented if your wrapper supports it
        conWrap.last_modification_date = conObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

        contactWrapList.add(conWrap);
    }

    wrapObj.legal_site = legalSiteWrapper;
    wrapObj.contacts = contactWrapList;

    return wrapObj;
}*/
//new method for udpate savings json ends





    //Get Wrapper for UpdateClientRequest
    public String getUpdateClientRequestWrapper(Id accountId){
        String wrapper; 
        UpdateClientRequestWrapper wrapObj = new UpdateClientRequestWrapper();
        List<UpdateClientRequestWrapper.Contact> contactWrapList = new List<UpdateClientRequestWrapper.Contact>();
        List<Account> accList = [SELECT Id, ER_Card_Client_Operational_System_ID__c, Name, ER_Registration_Number__c, HU_HQ_Contact__c, ER_Legal_Name__c, BillingCountry, ER_VAT_Number__c, ER_Not_subject_to_VAT__c, ER_Country_Code__c, BillingCity, BillingPostalCode, BillingStreet, LastModifiedDate from Account where Id=: accountId];
        if(!accList.isEmpty()){
            //New code
            Map<Id, Id> contactToAcrIdMap = new Map<Id, Id>();
            for (AccountContactRelation acr : [ SELECT Id, ContactId FROM AccountContactRelation WHERE AccountId = :accList[0].Id ]) {
                if (acr.ContactId != null && !contactToAcrIdMap.containsKey(acr.ContactId)) {
                    contactToAcrIdMap.put(acr.ContactId, acr.Id);
                }
            }
            //Account
            wrapObj.crm_id = accList[0].Id;
            wrapObj.card_id = accList[0].ER_Card_Client_Operational_System_ID__c;
            wrapObj.name = accList[0].Name;
            wrapObj.legal_name = accList[0].ER_Legal_Name__c;
            wrapObj.company_registration_number = accList[0].ER_Registration_Number__c;
            wrapObj.vat_number = accList[0].ER_VAT_Number__c;
            wrapObj.vat_type = accList[0].ER_Not_subject_to_VAT__c ? 'not_liable' : 'liable';//exempt
            wrapObj.last_modification_date = accList[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
            //Account Legal Site
            UpdateClientRequestWrapper.LegalSite legalSiteWrapper = new UpdateClientRequestWrapper.LegalSite();
            //legalSiteWrapper.contact_id = accList[0].HU_HQ_Contact__c;
            //New code to send the acr id
            Id hqContactId = accList[0].HU_HQ_Contact__c; // ContactId
            Id hqAcrId = (hqContactId != null) ? contactToAcrIdMap.get(hqContactId) : null;
            legalSiteWrapper.contact_id = (hqAcrId != null) ? hqAcrId : hqContactId;
            
            //Account Legal Site Address
            UpdateClientRequestWrapper.Address addressWrap = new UpdateClientRequestWrapper.Address();
            addressWrap.street = accList[0].BillingStreet;
            addressWrap.street_number = null;
            addressWrap.po_box = '';
            addressWrap.zip_code = accList[0].BillingPostalCode;
            addressWrap.city = accList[0].BillingCity;
            addressWrap.country_code = accList[0].ER_Country_Code__c != null ? accList[0].ER_Country_Code__c.toLowerCase() : null; 
            addressWrap.last_modification_date = accList[0].LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
            legalSiteWrapper.address = addressWrap;
            
            for(Contact conObj : [SELECT Id,ER_Client_Card_Operational_System_ID__c, LastModifiedDate, Phone, MobilePhone, Email, ER_Language__c, LastName, FirstName from Contact where AccountId =:accList[0].Id and ER_Status__c ='Active' and BE_Operational_Role__c != null and ER_Client_Card_Operational_System_ID__c != null order by LastModifiedDate DESC]){
                //Contact
                UpdateClientRequestWrapper.Contact conWrap = new UpdateClientRequestWrapper.Contact();
                //New code for acr id
                Id acrId = contactToAcrIdMap.get(conObj.Id);
                conWrap.crm_id = (acrId != null) ? acrId : conObj.Id;
                //conWrap.crm_id = conObj.Id;
                conWrap.card_id = conObj.ER_Client_Card_Operational_System_ID__c;
                conWrap.first_name = conObj.FirstName;
                conWrap.last_name = conObj.LastName;
                conWrap.language = conObj.ER_Language__c.toLowerCase();
                conWrap.email = conObj.Email;
                conWrap.phone_number = conObj.Phone;
                //conWrap.mobile_number = conObj.MobilePhone;
                conWrap.last_modification_date = conObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                contactWrapList.add(conWrap);
            }
            
            wrapObj.legal_site = legalSiteWrapper;
            wrapObj.contacts = contactWrapList;
            // new logic for seperating the savings update file
            // System.debug('UPDATE_JSON_MODE isSavings=' + isSavings);
            // if (isSavings) {
            //     wrapper = buildUpdateSavingsJson(wrapObj);
            // } else {
            //     wrapper = JSON.serialize(wrapObj).replaceAll('street_number', 'number');
            // }

            // System.debug('UPDATE_JSON_OUTPUT=' + wrapper);
            // return wrapper;

            //Commenting below part
            wrapper = JSON.serialize(wrapObj).replaceAll('street_number', 'number');
            return wrapper;
        }
        return null;
    }


    // ---------------------------------------------------Update code-------------------------------------
    //Get Wrapper for CreateClientContractRequest
    public String getCreateClientContractRequestWrapper(Id accountId, Id contractId){
        Set<Id> contractIdSet = new Set<Id>();
        CreateClientContractRequestWrapper wrapObj = new CreateClientContractRequestWrapper();

        Map<Id,Map<String, Id>> contractOperationalRoleContactIdMap = new Map<Id,Map<String, Id>>();
        Map<Id, Map<String, List<ER_ContractLineItem__c>>> contractLineItemWithSolutionMap = new Map<Id, Map<String, List<ER_ContractLineItem__c>>>();
        Map<Id, List<AccountContactRelation>> contactIdToAcrMap = new Map<Id, List<AccountContactRelation>>();
        List<CreateClientContractRequestWrapper.Service> serviceWrapList = new List<CreateClientContractRequestWrapper.Service>();
        List<CreateClientContractRequestWrapper.Contact> contactWrapList = new List<CreateClientContractRequestWrapper.Contact>();
        List<CreateClientContractRequestWrapper.Contract> contractWrapList = new List<CreateClientContractRequestWrapper.Contract>();
        List<CreateClientContractRequestWrapper.ContractProduct> contractProductWrapList = new List<CreateClientContractRequestWrapper.ContractProduct>();
        //Adding new
        Set<Id> processedAcrIds = new Set<Id>();
        
        //Commenting below part to send same category contracts
        /*for(Contract contractObj : [SELECT Id from Contract where Status = 'Activated' AND AccountId =:accountId]){
            contractIdSet.add(contractObj.Id);
        }
        if(contractId != null){
            contractIdSet.add(contractId);
        }*/
        //New code harkirat savings update
        String categoryToSync;

        if (contractId != null) {
            Contract triggerCtr = [ SELECT Id, AccountId, Contract_Category__c, Status FROM Contract WHERE Id = :contractId LIMIT 1 ];
            categoryToSync = triggerCtr.Contract_Category__c;
            System.debug('NEMO_SYNC | categoryToSync=' + categoryToSync + ' contractIdSetSize=' + contractIdSet.size());

            // Always include the triggering contract
            contractIdSet.add(triggerCtr.Id);

            // Add only Activated contracts of SAME category for this account
            for (Contract c : [ SELECT Id FROM Contract WHERE AccountId = :accountId AND Status = 'Activated' AND Contract_Category__c = :categoryToSync  ]) {
                contractIdSet.add(c.Id);
            }
        } else {
            // Fallback: if no contractId provided, keep old behavior (all activated)
            for (Contract c : [ SELECT Id FROM Contract WHERE AccountId = :accountId AND Status = 'Activated' ]) {
                contractIdSet.add(c.Id);
            }
        }
        //New code ends
        
        //List<Contract> contract = [SELECT Id, Name, AccountId, Account.LastModifiedDate, Creditting__c, Card_Replacement_Payment__c, ER_PaymentTerms2__c, ER_Impacted_Beneficiaries__c, Billing_Contact__c, ER_PaymentMethod2__c, ER_Program_Name__c, ER_Delivery_Type__c, ER_Customer_Domain__c, ER_Onboarding_Method__c, ER_InvoicingFrequency2__c, ER_OpportunityId__r.Impacted_Beneficiaries__c, Account.Name, Account.BillingCountry, Account.ER_Legal_Name__c, Account.ER_Registration_Number__c, Account.ER_Card_Client_Operational_System_ID__c, Account.ER_Not_subject_to_VAT__c, Contract_Category__c, LastModifiedDate, StartDate, ER_Start_Date__c, CustomerSignedDate, ER_OpportunityId__r.Invoicing_Contact__c, CustomerSignedId, ER_OpportunityId__r.ER_Promo_Code2__r.ER_Promo_Code__c, ER_OpportunityId__r.Primary_Contact__c, Account.ER_VAT_Number__c, Account.BillingStreet, Account.ER_Country_Code__c, Account.BillingCity, Account.BillingPostalCode FROM Contract WHERE Id IN :contractIdSet];
        List<Contract> contract = [SELECT Id, Name, AccountId, Account.LastModifiedDate, Creditting__c, Card_Replacement_Payment__c, ER_PaymentTerms2__c, ER_Impacted_Beneficiaries__c, Billing_Contact__c, ER_PaymentMethod2__c, ER_Program_Name__c, ER_Delivery_Type__c, ER_Customer_Domain__c, ER_Onboarding_Method__c, ER_InvoicingFrequency2__c, ER_OpportunityId__r.Impacted_Beneficiaries__c, Account.Name, Account.BillingCountry, Account.ER_Legal_Name__c, Account.ER_Registration_Number__c, Account.ER_Card_Client_Operational_System_ID__c, Account.ER_Not_subject_to_VAT__c, Contract_Category__c, LastModifiedDate, StartDate, ER_Start_Date__c, CustomerSignedDate, ER_OpportunityId__r.Invoicing_Contact__c, CustomerSignedId, ER_OpportunityId__r.ER_Promo_Code2__r.ER_Promo_Code__c, ER_OpportunityId__r.Primary_Contact__c, Account.ER_VAT_Number__c, Account.BillingStreet, Account.ER_Country_Code__c, Account.BillingCity, Account.BillingPostalCode, Main_Platform__c FROM Contract WHERE Id IN :contractIdSet];
        /*for(ER_ContractLineItem__c contractLineItemObj : [SELECT Id, Name, ER_Solution__c, ER_Contract__c, ER_ProductCode__c, ER_Percentage__c, ER_Quantity__c, ER_Minimum_Fee__c, LastModifiedDate, ER_UnitPrice__c, ER_ListPrice__c, Solution_Group__c, Parent_Product__c, Fee_Type__c, Product_Type__c, ER_Line_Type__c, ER_Price_Start_Date__c, ER_Product2__r.ER_Type__c FROM ER_ContractLineItem__c WHERE ER_Contract__c IN :contractIdSet AND ER_Solution__c != null AND ER_Product2__r.ER_Do_Not_Synchronize__c = false AND ER_IsActive__c = true]) {
            if(!contractLineItemWithSolutionMap.containsKey(contractLineItemObj.ER_Contract__c)){
                contractLineItemWithSolutionMap.put(contractLineItemObj.ER_Contract__c, new Map<String, List<ER_ContractLineItem__c>>());
                contractLineItemWithSolutionMap.get(contractLineItemObj.ER_Contract__c).put(contractLineItemObj.ER_Solution__c, new List<ER_ContractLineItem__c>{contractLineItemObj});
            }else{
                if(!contractLineItemWithSolutionMap.get(contractLineItemObj.ER_Contract__c).containsKey(contractLineItemObj.ER_Solution__c)){
                    contractLineItemWithSolutionMap.get(contractLineItemObj.ER_Contract__c).put(contractLineItemObj.ER_Solution__c, new List<ER_ContractLineItem__c>{contractLineItemObj});
                }else{
                    contractLineItemWithSolutionMap.get(contractLineItemObj.ER_Contract__c).get(contractLineItemObj.ER_Solution__c).add(contractLineItemObj);
                }
            }
        }*/
        for(ER_ContractLineItem__c contractLineItemObj : [SELECT Id, Name, ER_Solution__c, ER_Contract__c, ER_ProductCode__c, ER_Percentage__c, ER_Quantity__c, ER_Minimum_Fee__c, LastModifiedDate, ER_UnitPrice__c, ER_ListPrice__c, Solution_Group__c, Parent_Product__c, Fee_Type__c, Product_Type__c, ER_Line_Type__c, ER_Price_Start_Date__c, ER_Product2__r.ER_Type__c FROM ER_ContractLineItem__c WHERE ER_Contract__c IN :contractIdSet AND ER_Solution__c != null AND ER_Product2__r.ER_Do_Not_Synchronize__c = false AND ER_IsActive__c = true]) {
            String effectiveSolution = getEffectiveSolution(contractLineItemObj);
            if(!contractLineItemWithSolutionMap.containsKey(contractLineItemObj.ER_Contract__c)){
                contractLineItemWithSolutionMap.put(contractLineItemObj.ER_Contract__c, new Map<String, List<ER_ContractLineItem__c>>());
            }
            Map<String, List<ER_ContractLineItem__c>> solutionMap =
        contractLineItemWithSolutionMap.get(contractLineItemObj.ER_Contract__c);

    if (!solutionMap.containsKey(effectiveSolution)) {
        solutionMap.put(effectiveSolution, new List<ER_ContractLineItem__c>());
    }

    solutionMap.get(effectiveSolution).add(contractLineItemObj);
}
        
        if(!contract.isEmpty()){
            //List<Contact> contactList = [SELECT Id,BE_Operational_Role__c, LastModifiedDate, Phone, MobilePhone, Email, ER_Language__c, LastName, FirstName from Contact where AccountId =:accountId and ER_Status__c ='Active' and BE_Operational_Role__c != null order by LastModifiedDate DESC];
            List<ContractContactRole> ccrList = [SELECT Id, Role, ContactId,Contact.FirstName,Contact.Lastname,Contact.Email, Contact.MobilePhone, contact.LastModifiedDate,Contact.phone,Contact.ER_Language__c, ContractId FROM ContractContactRole where ContractId IN: contractIdSet];
            List<AccountContactRelation> acrList = [SELECT Id, AccountId, ContactId, Roles, Contact.FirstName, Contact.LastName, Contact.MobilePhone, Contact.Email, Contact.LastModifiedDate, Contact.Phone, Contact.ER_Language__c FROM AccountContactRelation WHERE AccountId = :contract[0].AccountId];
            // Query for financial center
             List<ER_Financial_Center__c> financialCenterList = [SELECT Id, Name, ER_Contact__c, ER_Contact__r.FirstName, ER_Contact__r.LastName, ER_Contact__r.Email, ER_Contact__r.Phone, ER_Contact__r.ER_Language__c, ER_Contact__r.LastModifiedDate, ER_Invoicing_Country__c, ER_Invoicing_Country_Code__c, ER_Street__c, LastModifiedDate, ER_Country_Code__c, ER_City__c, ER_Zip_Code__c, ER_Bank_Account__r.ER_BIC__c, ER_Bank_Account__r.ER_IBAN__c, ER_Invoicing_Zip_Code__c, ER_Invoicing_City__c, ER_Invoicing_Street__c from ER_Financial_Center__c where ER_Account_Name__c =:contract[0].AccountId ];
            //New Code
            for (AccountContactRelation acr : acrList) {
                if (!contactIdToAcrMap.containsKey(acr.ContactId)) {
                    contactIdToAcrMap.put(acr.ContactId, new List<AccountContactRelation>());
                }
                contactIdToAcrMap.get(acr.ContactId).add(acr);
            }
            //New 
            Map<Id, Id> contactToAcrIdMap = new Map<Id, Id>();
            for (Id conId : contactIdToAcrMap.keySet()) {
                List<AccountContactRelation> lst = contactIdToAcrMap.get(conId);
                if (!lst.isEmpty()) {
                    contactToAcrIdMap.put(conId, lst[0].Id);
                }
            }
            if (!ccrList.isEmpty()) {
            //Set<Id> processedAcrIds = new Set<Id>();
        
            for (ContractContactRole ccrObj : ccrList) {
        
                // Ensure entry exists for the contract
                if (!contractOperationalRoleContactIdMap.containsKey(ccrObj.ContractId)) {
                    contractOperationalRoleContactIdMap.put(
                        ccrObj.ContractId,
                        new Map<String, Id>()
                    );
                }
        
                Map<String, Id> operationalRoleContactIdMap =
                    contractOperationalRoleContactIdMap.get(ccrObj.ContractId);
        
                // Get related ACRs for this contact
                List<AccountContactRelation> relatedAcrList =
                    contactIdToAcrMap.get(ccrObj.ContactId);
        
                // Find matching ACR based on role
                AccountContactRelation matchedAcr = findMatchingAcr(relatedAcrList, ccrObj.Role);
        
                if (matchedAcr == null) {
                    // System.DEBUG('CCR_NO_ACR_MATCH contactId=' + ccrObj.ContactId);
                    // System.DEBUG('CCR_NO_ACR_MATCH2 role=' + ccrObj.Role);
                    // System.debug('No matching ACR found for ' + 'ContactId: ' + ccrObj.ContactId + ' Role: ' + ccrObj.Role);
                    continue;
                }
        
                // Role Mapping - Now using ACR Id
                if (!operationalRoleContactIdMap.containsKey(ccrObj.Role)) {
                    operationalRoleContactIdMap.put(ccrObj.Role, matchedAcr.Id); 
                    //operationalRoleContactIdMap.put(ccrObj.Role, ccrObj.ContactId);
                }
                // Contact Wrapper logic
                if (!processedAcrIds.contains(matchedAcr.Id)) {
                    processedAcrIds.add(matchedAcr.Id);
                    CreateClientContractRequestWrapper.Contact contactWrap = new CreateClientContractRequestWrapper.Contact();
        
                    contactWrap.crm_id = matchedAcr.Id;
                    contactWrap.first_name = ccrObj.Contact.FirstName;
                    contactWrap.last_name = ccrObj.Contact.LastName;
                    contactWrap.language = ccrObj.Contact.ER_Language__c != null ? ccrObj.Contact.ER_Language__c.toLowerCase() : null;
                    contactWrap.email = ccrObj.Contact.Email;
                    contactWrap.phone_number = ccrObj.Contact.Phone;
                    //to be added in the wrapper
                    contactWrap.mobile_number = ccrObj.Contact.MobilePhone;
                    contactWrap.last_modification_date =
                        ccrObj.Contact.LastModifiedDate != null
                        ? ccrObj.Contact.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'')
                        : null;
        
                    contactWrapList.add(contactWrap);
                }
            }
}
            //Account
            CreateClientContractRequestWrapper.Client clientWrap = new CreateClientContractRequestWrapper.Client();
            clientWrap.crm_id = contract[0].AccountId;
            clientWrap.card_id = contract[0].Account.ER_Card_Client_Operational_System_ID__c;
            clientWrap.company_registration_number = contract[0].Account.ER_Registration_Number__c;
            clientWrap.last_modification_date = contract[0].Account.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
            clientWrap.engagement_platform_id = contract[0].Main_Platform__c;
            
            //Adding new code for showing Legal site
            //List<ER_Financial_Center__c> financialCenterList = [SELECT Id, Name, ER_Bank_Account__r.ER_IBAN__c, ER_Bank_Account__r.ER_BIC__c, LastModifiedDate FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :contract[0].AccountId];
            
            CreateClientContractRequestWrapper.LegalSite legalSite = new CreateClientContractRequestWrapper.LegalSite();
            legalSite.financial_centers = new List<CreateClientContractRequestWrapper.FinancialCenter>();

            for (ER_Financial_Center__c fcObj : financialCenterList) {
                CreateClientContractRequestWrapper.FinancialCenter fcWrap = new CreateClientContractRequestWrapper.FinancialCenter();
                // CRM ID = Financial Center record Id
                fcWrap.crm_id = (String)fcObj.Id;
                fcWrap.name   = fcObj.Name;

                CreateClientContractRequestWrapper.BankAccount bankWrap = new CreateClientContractRequestWrapper.BankAccount();
                bankWrap.iban = (fcObj.ER_Bank_Account__r != null) ? fcObj.ER_Bank_Account__r.ER_IBAN__c : null;
                bankWrap.bic  = (fcObj.ER_Bank_Account__r != null) ? fcObj.ER_Bank_Account__r.ER_BIC__c : null;
                fcWrap.bank_account = bankWrap;
                legalSite.financial_centers.add(fcWrap);
            }

            // Attach to client
            clientWrap.legal_site = legalSite;

            //Adding new code for showing Legal site ends

            Map<String, Id> roleMap;
            for(Contract contractObj : contract){
                CreateClientContractRequestWrapper.Contract contractWrap = new CreateClientContractRequestWrapper.Contract();
                contractWrap.crm_id = contractObj.Id;
                contractWrap.name = contractObj.Name;
                //New field 
                contractWrap.delivery_type = contractObj.ER_Delivery_Type__c;
                String method = null;
                if (contract[0].ER_Impacted_Beneficiaries__c == 'TRE Only') {
                    method = 'TRE';
                } else if (contract[0].ER_Impacted_Beneficiaries__c == 'All') {
                    method = 'ALL';
                }
                contractWrap.selection_method = method;

                /*if (contractObj.ER_OpportunityId__r.Impacted_Beneficiaries__c == 'TRE Only') {
                    method = 'TRE';
                } else if (contractObj.ER_OpportunityId__r.Impacted_Beneficiaries__c == 'All') {
                    method = 'ALL';
                }
                contractWrap.selection_method = method;*/

                //Fields required for Engagement contract
                contractWrap.program_name = contractObj.ER_Program_Name__c;
                contractWrap.customer_domain = contractObj.ER_Customer_Domain__c;
                contractWrap.customer_management = contractObj.ER_Onboarding_Method__c;
                contractWrap.invoicing_frequency = contractObj.ER_InvoicingFrequency2__c;
                // payment_method / payment_deadline / crediting_delay
                if (contractObj.ER_PaymentMethod2__c != null) {
                    Map<String, String> pm = Constants.getPaymentMethodMap();
                    contractWrap.payment_method = pm.get(contractObj.ER_PaymentMethod2__c);
                }
                if (contractObj.ER_PaymentTerms2__c != null) {
                    Map<String, String> pt = Constants.getPaymentTermsMap();
                    contractWrap.payment_deadline = pt.get(contractObj.ER_PaymentTerms2__c);
                }
                if (contractObj.Creditting__c != null) {
                    Map<String, String> cr = Constants.getCreditingMap();
                    contractWrap.crediting_delay = cr.get(contractObj.Creditting__c);
                }
                //Logic ends
                //contractWrap.start_date = contractObj.ER_Start_Date__c != null ? ((DateTime)contractObj.ER_Start_Date__c).formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'') : null;
                
                Date startDateToUse;
                if (contract[0].Contract_Category__c == 'Benefits') {
                    startDateToUse = contract[0].StartDate;
                } else {
                    startDateToUse = contract[0].ER_Start_Date__c;
                }
                contractWrap.start_date = startDateToUse != null ? Datetime.newInstance(startDateToUse, Time.newInstance(0, 0, 0, 0)).formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'') : null;
                System.debug('startDateToUse' + startDateToUse);



                contractWrap.end_date = null;
                //contractWrap.end_reason = null;
                contractWrap.signed_date = contractObj.CustomerSignedDate != null ? ((DateTime)contractObj.CustomerSignedDate).formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'') : null;
            	roleMap = contractOperationalRoleContactIdMap.containsKey(contractObj.Id) ? contractOperationalRoleContactIdMap.get(contractObj.Id) : new Map<String, Id>();
                contractWrap.invoicing_contact_id = roleMap.containsKey('Invoicing Contact') ? roleMap.get('Invoicing Contact') : null;
                //New 
                //Commenting this as we need to send the contact id
                Id counterpartyCrmId;
                if (contractObj.CustomerSignedId != null) {
                    Id acrIdForCounterparty = contactToAcrIdMap.get(contractObj.CustomerSignedId);
                    counterpartyCrmId = (acrIdForCounterparty != null)
                        ? acrIdForCounterparty
                        : contractObj.CustomerSignedId; // fallback to Contact Id
                }
                contractWrap.contact_counterparty_signed_id = counterpartyCrmId;

                //New logic
                if (counterpartyCrmId != null && !processedAcrIds.contains(counterpartyCrmId)) {
                // Query the contact details
                List<Contact> counterpartyContacts = [
                    SELECT Id, FirstName, LastName, Email, Phone, ER_Language__c, LastModifiedDate 
                    FROM Contact 
                    WHERE Id = :contractObj.CustomerSignedId 
                    LIMIT 1
                ];
                
                if (!counterpartyContacts.isEmpty()) {
                    Contact conObj = counterpartyContacts[0];
                    processedAcrIds.add(counterpartyCrmId);
                    
                    //CreateClientRequestWrapper.ContactWrapper contactWrap = new CreateClientRequestWrapper.ContactWrapper();
                    CreateClientContractRequestWrapper.Contact contactWrap = new CreateClientContractRequestWrapper.Contact();
                    contactWrap.crm_id = counterpartyCrmId; // ACR ID or Contact ID
                    contactWrap.first_name = conObj.FirstName;
                    contactWrap.last_name = conObj.LastName;
                    contactWrap.language = conObj.ER_Language__c != null 
                        ? conObj.ER_Language__c.toLowerCase() 
                        : 'en';
                    contactWrap.email = conObj.Email;
                    contactWrap.phone_number = conObj.Phone;
                    contactWrap.last_modification_date = conObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                    contactWrapList.add(contactWrap);
                }
            }
                //contractWrap.contact_counterparty_signed_id = contractObj.CustomerSignedId;
                contractWrap.last_modification_date = contractObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                contractProductWrapList = new List<CreateClientContractRequestWrapper.ContractProduct>();
                if(contractLineItemWithSolutionMap.containsKey(contractObj.Id)){
                    for(String solutionCode : contractLineItemWithSolutionMap.get(contractObj.Id).keySet()){
                        //Solutions
                        CreateClientContractRequestWrapper.ContractProduct prodWrapObj = new CreateClientContractRequestWrapper.ContractProduct();
                        //Adding new line
                        //Integer licenses = null;
                        prodWrapObj.start_date = contractWrap.start_date;
                        prodWrapObj.end_date = null;
                        prodWrapObj.signed_date = contractWrap.signed_date;
                        roleMap = contractOperationalRoleContactIdMap.containsKey(contractObj.Id) ? contractOperationalRoleContactIdMap.get(contractObj.Id) : new Map<String, Id>();
                        prodWrapObj.order_contact_id = roleMap.containsKey('Order Contact') ? roleMap.get('Order Contact') : roleMap.get('Primary Contact');                        
                        prodWrapObj.product = solutionCode.toLowerCase();
                        serviceWrapList = new List<CreateClientContractRequestWrapper.Service>();
                        //New line to filter acc to the smartHub
                        Set<String> addedServiceCodes = new Set<String>();
                        
                        for(ER_ContractLineItem__c cliObj : contractLineItemWithSolutionMap.get(contractObj.Id).get(solutionCode)){
                            /*if (licenses == null && cliObj.Solution_Group__c == 'Savings') {
                                licenses = cliObj.ER_Quantity__c != null
                                ? Integer.valueOf(cliObj.ER_Quantity__c)
                                : null;
                            }*/
                            if(cliObj.ER_Product2__r.ER_Type__c == 'Discount'){
                                prodWrapObj.promo_code = contractObj.ER_OpportunityId__r.ER_Promo_Code2__r.ER_Promo_Code__c;
                            }
                            if(cliObj.ER_Price_Start_Date__c != null){
                                prodWrapObj.start_date = ((DateTime)cliObj.ER_Price_Start_Date__c).formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                            }
                            //Services
                            if(contractObj.Card_Replacement_Payment__c != null && (contractObj.Card_Replacement_Payment__c == 'Paid by beneficiary' || contractObj.Card_Replacement_Payment__c == 'Paid by customer') && (solutionCode == Constants.ADDITIONAL_SERVICE_CODE_BE || solutionCode == Constants.ADDITIONAL_SERVICE_CODE_LU) && (cliObj.ER_ProductCode__c == Constants.CARD_RP_CT || cliObj.ER_ProductCode__c == Constants.CARD_RP_BF)){
                                CreateClientContractRequestWrapper.Service serviceWrapObj = new CreateClientContractRequestWrapper.Service();
                                serviceWrapObj.code = contractObj.Card_Replacement_Payment__c == 'Paid by beneficiary'? Constants.CARD_RP_BF : contractObj.Card_Replacement_Payment__c == 'Paid by customer' ? Constants.CARD_RP_CT : null;
                                serviceWrapObj.percentage = contractObj.Card_Replacement_Payment__c == 'Paid by beneficiary' ? 0 : cliObj.ER_Percentage__c != null ? cliObj.ER_Percentage__c.setScale(6) : 0;
                                //serviceWrapObj.quantity = 0;
                                serviceWrapObj.quantity =
                                (cliObj.Solution_Group__c == 'Savings' || cliObj.Solution_Group__c == 'Engagement')
                                ? (cliObj.ER_Quantity__c != null ? cliObj.ER_Quantity__c : 0)
                                : 0; 
                                serviceWrapObj.amount = contractObj.Card_Replacement_Payment__c == 'Paid by beneficiary' ? 0 : cliObj.ER_UnitPrice__c != null ? cliObj.ER_UnitPrice__c.setScale(2) : 0;
                                serviceWrapObj.minimum_fee = contractObj.Card_Replacement_Payment__c == 'Paid by beneficiary' ? 0 : cliObj.ER_Minimum_Fee__c != null ? cliObj.ER_Minimum_Fee__c.setScale(2) : 0;
                                serviceWrapObj.discount = 0;
                                serviceWrapObj.sales_price = 0;
                                serviceWrapObj.standard_price = 0;
                                serviceWrapObj.solution = cliObj.Solution_Group__c == 'Benefits' ? 'benefit' : cliObj.Solution_Group__c == 'Savings'  ? 'engagement' : null;
                                serviceWrapObj.last_modification_date = cliObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                                System.debug( 'SERVICE_ADD: contract=' + contractObj.Id + ' solution=' + solutionCode + ' cliId=' + cliObj.Id + ' cliName=' + cliObj.Name + ' parent=' + cliObj.Parent_Product__c + ' unitPrice=' + cliObj.ER_UnitPrice__c + ' lineType=' + cliObj.ER_Line_Type__c );
                                serviceWrapList.add(serviceWrapObj);
                            }else{
                                CreateClientContractRequestWrapper.Service serviceWrapObj = new CreateClientContractRequestWrapper.Service();
                                //serviceWrapObj.code = cliObj.ER_ProductCode__c; 
                                //New Logic
                                String codeToSend = cliObj.ER_ProductCode__c; // default
                            //For savings only
                            if (cliObj.Solution_Group__c == 'Savings') {
                                String parent = cliObj.Parent_Product__c;
                            // Apply ONLY for engagement PRODUCT
                            //if (solutionCode != null && solutionCode.toLowerCase() == 'engagement') {
                            //if (solutionCode != null && solutionCode.toLowerCase() == 'savings') {

                                if (!String.isBlank(parent)) {
                                    String p = parent.toLowerCase();

                                    //New map for values
                                    Map<String, String> parentToCode = new Map<String, String>{
                                        'premium implementation fees' => 'Implementation_Premium',
                                        'implementation fees'         => 'Implementation',
                                        'license fees'                => 'License',
                                        'premium license fees'        => 'License_Premium',
                                        'freemium license fees'       => 'License_Freemium',
                                        'reward'                      => 'Reward',
                                        'smarthub'                    => 'SmartHub',
                                        'recognition'                 => 'Recognition',
                                        'freemium implementation fees'=> 'Implementation_Freemium'
                                    };
                                    if (parentToCode.containsKey(p)) {
                                        codeToSend = parentToCode.get(p);
                                    } else {
                                        if (p.contains('premium implementation fees')) codeToSend = 'Implementation_Premium';
                                        else if (p.contains('freemium implementation fees')) codeToSend = 'Implementation_Freemium';
                                        else if (p.contains('premium license fees')) codeToSend = 'License_Premium';
                                        else if (p.contains('freemium license fees')) codeToSend = 'License_Freemium';
                                        else if (p.contains('implementation fees')) codeToSend = 'Implementation';
                                        else if (p.contains('license fees')) codeToSend = 'License';
                                        else if (p.contains('reward')) codeToSend = 'Reward';
                                        else if (p.contains('recognition')) codeToSend = 'Recognition';
                                        else if (p.contains('smarthub')) codeToSend = 'SmartHub';
                                    }
                                }
                            }
                            serviceWrapObj.code = codeToSend;
                            if (codeToSend == 'SmartHub'
                                && (cliObj == null || String.isBlank(cliObj.Name) || !cliObj.Name.trim().equalsIgnoreCase('SmartHub Admin Access'))) {
                                continue;
                            }

                            // OPTIONAL: SmartHub only once per solution (declare per solutionCode)
                            if (codeToSend == 'SmartHub' && addedServiceCodes.contains('SmartHub')) {
                                continue;
                            }
                            addedServiceCodes.add(codeToSend);
                            //Logic ends
                                serviceWrapObj.percentage = cliObj.ER_Percentage__c != null ? cliObj.ER_Percentage__c.setScale(6) : 0;
                                //serviceWrapObj.quantity = 0;
                                serviceWrapObj.quantity =
                                    (cliObj.Solution_Group__c == 'Savings' || cliObj.Solution_Group__c == 'Engagement')
                                    ? (cliObj.ER_Quantity__c != null ? cliObj.ER_Quantity__c : 0)
                                    : 0; 
                                serviceWrapObj.amount = cliObj.ER_UnitPrice__c != null ? cliObj.ER_UnitPrice__c.setScale(2) : 0;
                                serviceWrapObj.minimum_fee = cliObj.ER_Minimum_Fee__c != null ? cliObj.ER_Minimum_Fee__c.setScale(2) : 0;
                                serviceWrapObj.discount = 0;
                                serviceWrapObj.sales_price = 0;
                                serviceWrapObj.standard_price = 0;
                                serviceWrapObj.solution = cliObj.Solution_Group__c == 'Benefits' ? 'benefit' : cliObj.Solution_Group__c == 'Savings'  ? 'engagement' : null;
                                serviceWrapObj.last_modification_date = cliObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                                serviceWrapList.add(serviceWrapObj);
                            }
                        }

                        //Payment Terms
                        /*if(contractObj.ER_PaymentTerms2__c != null){
                            Map<String, String> paymentTermsMap = Constants.getPaymentTermsMap();
                            if (solutionCode == Constants.BENEFIT) {
                                if(paymentTermsMap.containsKey(contractObj.ER_PaymentTerms2__c)){
                                    CreateClientContractRequestWrapper.Service paymentTermsServiceWrapObj = new CreateClientContractRequestWrapper.Service();
                                    paymentTermsServiceWrapObj.code = paymentTermsMap.get(contractObj.ER_PaymentTerms2__c);
                                    paymentTermsServiceWrapObj.percentage = 0;
                                    paymentTermsServiceWrapObj.quantity = 0;
                                    paymentTermsServiceWrapObj.amount = 0;
                                    paymentTermsServiceWrapObj.minimum_fee = 0;
                                    paymentTermsServiceWrapObj.discount = 0;
                                    paymentTermsServiceWrapObj.sales_price = 0;
                                    paymentTermsServiceWrapObj.standard_price = 0;
                                    paymentTermsServiceWrapObj.solution = Constants.BENEFIT;
                                    paymentTermsServiceWrapObj.last_modification_date = contractObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                                    serviceWrapList.add(paymentTermsServiceWrapObj);
                                }
                            }
                        }
                        //Payment Method
                        if(contractObj.ER_PaymentMethod2__c != null){
                            Map<String, String> paymentMethodMap = Constants.getPaymentMethodMap();
                            if (solutionCode == Constants.BENEFIT){
                                if(paymentMethodMap.containsKey(contractObj.ER_PaymentMethod2__c)){
                                    CreateClientContractRequestWrapper.Service paymentMethodServiceWrapObj = new CreateClientContractRequestWrapper.Service();
                                    paymentMethodServiceWrapObj.code = paymentMethodMap.get(contractObj.ER_PaymentMethod2__c);
                                    paymentMethodServiceWrapObj.percentage = 0;
                                    paymentMethodServiceWrapObj.quantity = 0;
                                    paymentMethodServiceWrapObj.amount = 0;
                                    paymentMethodServiceWrapObj.minimum_fee = 0;
                                    paymentMethodServiceWrapObj.discount = 0;
                                    paymentMethodServiceWrapObj.sales_price = 0;
                                    paymentMethodServiceWrapObj.standard_price = 0;
                                    paymentMethodServiceWrapObj.solution = Constants.BENEFIT;
                                    paymentMethodServiceWrapObj.last_modification_date = contractObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
                                    serviceWrapList.add(paymentMethodServiceWrapObj);
                                }
                            }
                        }*/
                        Boolean isBenefitsProduct = false;

                        for (ER_ContractLineItem__c tmpCli :
                            contractLineItemWithSolutionMap.get(contractObj.Id).get(solutionCode)) {
                            if (tmpCli.Solution_Group__c == 'Benefits') {
                                isBenefitsProduct = true;
                                break;
                            }
                        }

                        // Add Payment Terms
                        if (isBenefitsProduct && contractObj.ER_PaymentTerms2__c != null) {
                            Map<String, String> pt = Constants.getPaymentTermsMap();
                            if (pt.containsKey(contractObj.ER_PaymentTerms2__c)) {
                                CreateClientContractRequestWrapper.Service s =
                                    new CreateClientContractRequestWrapper.Service();

                                s.code = pt.get(contractObj.ER_PaymentTerms2__c);
                                s.percentage = 0;
                                s.quantity = 0;
                                s.amount = 0;
                                s.minimum_fee = 0;
                                s.discount = 0;
                                s.sales_price = 0;
                                s.standard_price = 0;
                                s.solution = 'benefit';
                                s.last_modification_date =
                                    contractObj.LastModifiedDate
                                        .formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                                serviceWrapList.add(s);
                            }
                        }

                        // Add Payment Method
                        if (isBenefitsProduct && contractObj.ER_PaymentMethod2__c != null) {
                            Map<String, String> pm = Constants.getPaymentMethodMap();
                            if (pm.containsKey(contractObj.ER_PaymentMethod2__c)) {
                                CreateClientContractRequestWrapper.Service s =
                                    new CreateClientContractRequestWrapper.Service();

                                s.code = pm.get(contractObj.ER_PaymentMethod2__c);
                                s.percentage = 0;
                                s.quantity = 0;
                                s.amount = 0;
                                s.minimum_fee = 0;
                                s.discount = 0;
                                s.sales_price = 0;
                                s.standard_price = 0;
                                s.solution = 'benefit';
                                s.last_modification_date =
                                    contractObj.LastModifiedDate
                                        .formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                                serviceWrapList.add(s);
                            }
                        }

                        //Adding Crediting delay
                        if (isBenefitsProduct && contractObj.Creditting__c != null) {
                            Map<String, String> cr = Constants.getCreditingMap();
                            if (cr.containsKey(contractObj.Creditting__c)) {
                                CreateClientContractRequestWrapper.Service s =
                                    new CreateClientContractRequestWrapper.Service();

                                s.code = cr.get(contractObj.Creditting__c);
                                s.percentage = 0;
                                s.quantity = 0;
                                s.amount = 0;
                                s.minimum_fee = 0;
                                s.discount = 0;
                                s.sales_price = 0;
                                s.standard_price = 0;
                                s.solution = 'benefit';
                                s.last_modification_date =
                                    contractObj.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');

                                serviceWrapList.add(s);
                            }
                        }
                        prodWrapObj.services = serviceWrapList;
                        //Adding new line
                        //prodWrapObj.licenses = licenses;
                        contractProductWrapList.add(prodWrapObj);
                    }
                }
                contractWrap.contract_products = contractProductWrapList;
                contractWrapList.add(contractWrap);
            }
            
            wrapObj.client = clientWrap;
            wrapObj.contracts = contractWrapList;
            wrapObj.contacts = contactWrapList;
            // DEBUG: which path?
            //System.debug(LoggingLevel.ERROR, 'NEMO_SYNC | CCC categoryToSync=' + categoryToSync);

            if (categoryToSync != null && categoryToSync.equalsIgnoreCase('Engagement')) {
                String outJson = buildCreateClientContractSavingsJson(wrapObj);
                //System.debug(LoggingLevel.ERROR, 'NEMO_SYNC | CCC SAVINGS JSON length=' + (outJson != null ? outJson.length() : 0));

                //System.debug(LoggingLevel.ERROR, 'NEMO_SYNC | CCC SAVINGS JSON=' + outJson);
                return outJson;
            }

            if (categoryToSync != null && categoryToSync.equalsIgnoreCase('Benefits')) {
                String outJson = buildCreateClientContractBenefitJson(wrapObj);
                //System.debug(LoggingLevel.ERROR, 'NEMO_SYNC | CCC BENEFITS JSON length=' + (outJson != null ? outJson.length() : 0) );
                return outJson;
            }

            // default: keep existing behavior untouched
            String out = JSON.serialize(wrapObj);
            System.debug(LoggingLevel.ERROR, 'NEMO_SYNC | CCC DEFAULT JSON length=' + (out != null ? out.length() : 0));
            return out;
            //             System.debug('NEMO_SYNC | getCreateClientContractRequestWrapper END contractCount=' + (contractWrapList == null ? 0 : contractWrapList.size()) +
            //     ' contactsCount=' + (contactWrapList == null ? 0 : contactWrapList.size())
            // );
            //             return JSON.serialize(wrapObj);
        }else if(contract.isEmpty()){

            Account account = [Select Id, ER_Card_Client_Operational_System_ID__c, ER_Registration_Number__c, LastModifiedDate FROM Account WHERE Id =: accountId];
            CreateClientContractRequestWrapper.Client clientWrap = new CreateClientContractRequestWrapper.Client();
            clientWrap.crm_id = account.Id;
            clientWrap.card_id = account.ER_Card_Client_Operational_System_ID__c;
            clientWrap.company_registration_number = account.ER_Registration_Number__c;
            clientWrap.last_modification_date = account.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'00:00:00\'Z\'');
            
            CreateClientContractRequestWrapper.Contact contactWrap = new CreateClientContractRequestWrapper.Contact();
            CreateClientContractRequestWrapper.Contract contractWrap = new CreateClientContractRequestWrapper.Contract();

            wrapObj.client = clientWrap;
            wrapObj.contracts = contractWrapList;
            wrapObj.contacts = contactWrapList;
            return JSON.serialize(wrapObj);
        }
        return null;
    }

    //Build json for update benefits

    private static String buildCreateClientContractBenefitJson(CreateClientContractRequestWrapper w) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();

        // client (same as savings)
        gen.writeFieldName('client');
        if (w == null || w.client == null) {
            gen.writeNull();
        } else {
            gen.writeStartObject();
            //writeStringOrNull(gen, 'legal_site', null); // placeholder
            //gen.writeEndObject();
            // Re-open client object properly
            //gen.writeFieldName('client');
            //gen.writeStartObject();

        // legal_site
        gen.writeFieldName('legal_site');
        if (w.client.legal_site == null) {
            gen.writeNull();
        } else {
            gen.writeStartObject();
            gen.writeFieldName('financial_centers');
            gen.writeStartArray();

            if (w.client.legal_site.financial_centers != null) {
                for (CreateClientContractRequestWrapper.FinancialCenter fc : w.client.legal_site.financial_centers) {
                    gen.writeStartObject();
                    writeStringOrNull(gen, 'name', fc.name);
                    writeStringOrNull(gen, 'crm_id', fc.crm_id);

                    gen.writeFieldName('bank_account');
                    if (fc.bank_account == null) {
                        gen.writeNull();
                    } else {
                        gen.writeStartObject();
                        writeStringOrNull(gen, 'iban', fc.bank_account.iban);
                        writeStringOrNull(gen, 'bic', fc.bank_account.bic);
                        gen.writeEndObject();
                    }

                    gen.writeEndObject();
                }
            }

            gen.writeEndArray();
            gen.writeEndObject();
        }

        // remaining client fields
        writeStringOrNull(gen, 'last_modification_date', w.client.last_modification_date);
        writeStringOrNull(gen, 'crm_id', w.client.crm_id);
        writeStringOrNull(gen, 'company_registration_number', w.client.company_registration_number);
        writeStringOrNull(gen, 'card_id', w.client.card_id);

        if (w.client.engagement_platform_id != null) {
            gen.writeStringField('engagement_platform_id', w.client.engagement_platform_id);
        }

        gen.writeEndObject();
    }

    // contacts
    gen.writeFieldName('contacts');
    gen.writeStartArray();
    if (w != null && w.contacts != null) {
        for (CreateClientContractRequestWrapper.Contact c : w.contacts) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'phone_number', c.phone_number);
            writeStringOrNull(gen, 'mobile_number', c.mobile_number);
            writeStringOrNull(gen, 'last_name', c.last_name);
            writeStringOrNull(gen, 'last_modification_date', c.last_modification_date);
            writeStringOrNull(gen, 'language', c.language);
            writeStringOrNull(gen, 'first_name', c.first_name);
            writeStringOrNull(gen, 'email', c.email);
            writeStringOrNull(gen, 'crm_id', c.crm_id);
            gen.writeEndObject();
        }
    }
    gen.writeEndArray();

    // contracts
    gen.writeFieldName('contracts');
    gen.writeStartArray();

    if (w != null && w.contracts != null) {
        for (CreateClientContractRequestWrapper.Contract con : w.contracts) {
            gen.writeStartObject();

            writeStringOrNull(gen, 'start_date', con.start_date);
            writeStringOrNull(gen, 'signed_date', con.signed_date);
            writeStringOrNull(gen, 'name', con.name);
            writeStringOrNull(gen, 'last_modification_date', con.last_modification_date);
            writeStringOrNull(gen, 'invoicing_frequency', con.invoicing_frequency);
            writeStringOrNull(gen, 'invoicing_contact_id', con.invoicing_contact_id);
            writeStringOrNull(gen, 'crediting_delay', con.crediting_delay);

            // explicit null in sample
            gen.writeNullField('end_date');

            // delivery_type is present in sample (can be null)
            if (con.delivery_type == null) gen.writeNullField('delivery_type');
            else gen.writeStringField('delivery_type', con.delivery_type);

            writeStringOrNull(gen, 'crm_id', con.crm_id);

            // contract_products
            gen.writeFieldName('contract_products');
            gen.writeStartArray();
            if (con.contract_products != null) {
                for (CreateClientContractRequestWrapper.ContractProduct cp : con.contract_products) {
                    gen.writeStartObject();

                    writeStringOrNull(gen, 'start_date', cp.start_date);
                    writeStringOrNull(gen, 'signed_date', cp.signed_date);

                    // services
                    gen.writeFieldName('services');
                    gen.writeStartArray();
                    if (cp.services != null) {
                        for (CreateClientContractRequestWrapper.Service s : cp.services) {
                            gen.writeStartObject();

                            // exact field set from sample
                            writeDecimalOrNull(gen, 'standard_price', s.standard_price);
                            writeStringOrNull(gen, 'solution', s.solution);
                            writeDecimalOrNull(gen, 'sales_price', s.sales_price);
                            writeDecimalOrNull(gen, 'quantity', s.quantity);
                            writeDecimalOrNull(gen, 'percentage', s.percentage);
                            writeDecimalOrNull(gen, 'minimum_fee', s.minimum_fee);
                            writeStringOrNull(gen, 'last_modification_date', s.last_modification_date);
                            writeDecimalOrNull(gen, 'discount', s.discount);
                            writeStringOrNull(gen, 'code', s.code);
                            writeDecimalOrNull(gen, 'amount', s.amount);

                            gen.writeEndObject();
                        }
                    }
                    gen.writeEndArray();

                    // promo_code present (null allowed)
                    writeStringOrNull(gen, 'promo_code', cp.promo_code);

                    writeStringOrNull(gen, 'product', cp.product);
                    writeStringOrNull(gen, 'order_contact_id', cp.order_contact_id);

                    // explicit null in sample
                    gen.writeNullField('end_date');

                    gen.writeEndObject();
                }
            }
            gen.writeEndArray();

            writeStringOrNull(gen, 'contact_counterparty_signed_id', con.contact_counterparty_signed_id);

            gen.writeEndObject();
        }
    }

    gen.writeEndArray(); // contracts

    gen.writeEndObject();
    return gen.getAsString();
}

    //Build json for update benefits ends
//---------------------------
    //Builds json for Update Savings
    private static String buildCreateClientContractSavingsJson(CreateClientContractRequestWrapper w) {
    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();

    // client
    gen.writeFieldName('client');
    if (w.client == null) {
        gen.writeNull();
    } else {
        gen.writeStartObject();
        writeStringOrNull(gen, 'crm_id', w.client.crm_id);
        writeStringOrNull(gen, 'card_id', w.client.card_id);
        writeStringOrNull(gen, 'company_registration_number', w.client.company_registration_number);
        writeStringOrNull(gen, 'last_modification_date', w.client.last_modification_date);
        
        // NEW LINE - Add engagement_platform_id
        if (w.client.engagement_platform_id != null) {
            gen.writeStringField('engagement_platform_id', w.client.engagement_platform_id);
        }

        // legal_site
        gen.writeFieldName('legal_site');
        if (w.client.legal_site == null) {
            gen.writeNull();
        } else {
            gen.writeStartObject();
            gen.writeFieldName('financial_centers');
            gen.writeStartArray();

            if (w.client.legal_site.financial_centers != null) {
                for (CreateClientContractRequestWrapper.FinancialCenter fc : w.client.legal_site.financial_centers) {
                    gen.writeStartObject();
                    writeStringOrNull(gen, 'crm_id', fc.crm_id);
                    writeStringOrNull(gen, 'name', fc.name);

                    gen.writeFieldName('bank_account');
                    if (fc.bank_account == null) {
                        gen.writeNull();
                    } else {
                        gen.writeStartObject();
                        writeStringOrNull(gen, 'iban', fc.bank_account.iban);
                        writeStringOrNull(gen, 'bic', fc.bank_account.bic);
                        gen.writeEndObject();
                    }

                    gen.writeEndObject();
                }
            }

            gen.writeEndArray();
            gen.writeEndObject();
        }

        gen.writeEndObject();
    }

    // contacts
    gen.writeFieldName('contacts');
    gen.writeStartArray();
    if (w.contacts != null) {
        for (CreateClientContractRequestWrapper.Contact c : w.contacts) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'crm_id', c.crm_id);
            writeStringOrNull(gen, 'first_name', c.first_name);
            writeStringOrNull(gen, 'last_name', c.last_name);
            writeStringOrNull(gen, 'language', c.language);
            writeStringOrNull(gen, 'email', c.email);
            writeStringOrNull(gen, 'phone_number', c.phone_number);
            writeStringOrNull(gen, 'mobile_number', c.mobile_number);
            writeStringOrNull(gen, 'last_modification_date', c.last_modification_date);
            gen.writeEndObject();
        }
    }
    gen.writeEndArray();

    // contracts
    gen.writeFieldName('contracts');
    gen.writeStartArray();
    if (w.contracts != null) {
        for (CreateClientContractRequestWrapper.Contract con : w.contracts) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'crm_id', con.crm_id);
            writeStringOrNull(gen, 'name', con.name);
            writeStringOrNull(gen, 'start_date', con.start_date);
            // keep end_date explicit null (your current code uses null)
            gen.writeNullField('end_date');
            writeStringOrNull(gen, 'signed_date', con.signed_date);
            //New fields added for update savings
             writeStringOrNull(gen, 'program_name', con.program_name);
            writeStringOrNull(gen, 'customer_domain', con.customer_domain);
            writeStringOrNull(gen, 'selection_method', con.selection_method);
            writeStringOrNull(gen, 'invoicing_frequency', con.invoicing_frequency);
            writeStringOrNull(gen, 'customer_management', con.customer_management);
            writeStringOrNull(gen, 'payment_method', con.payment_method);
            writeStringOrNull(gen, 'payment_deadline', con.payment_deadline);
            writeStringOrNull(gen, 'crediting_delay', con.crediting_delay);
            //New fields added for update savings ends
            writeStringOrNull(gen, 'invoicing_contact_id', con.invoicing_contact_id);
            writeStringOrNull(gen, 'contact_counterparty_signed_id', con.contact_counterparty_signed_id);
            writeStringOrNull(gen, 'last_modification_date', con.last_modification_date);

            // contract_products
            gen.writeFieldName('contract_products');
            gen.writeStartArray();
            if (con.contract_products != null) {
                for (CreateClientContractRequestWrapper.ContractProduct cp : con.contract_products) {
                    gen.writeStartObject();
                    writeStringOrNull(gen, 'start_date', cp.start_date);
                    gen.writeNullField('end_date');
                    writeStringOrNull(gen, 'signed_date', cp.signed_date);
                    writeStringOrNull(gen, 'order_contact_id', cp.order_contact_id);
                    writeStringOrNull(gen, 'promo_code', cp.promo_code);
                    writeStringOrNull(gen, 'product', cp.product);

                    // services
                    gen.writeFieldName('services');
                    gen.writeStartArray();
                    if (cp.services != null) {
                        for (CreateClientContractRequestWrapper.Service s : cp.services) {
                            gen.writeStartObject();
                            writeStringOrNull(gen, 'code', s.code);
                            writeStringOrNull(gen, 'solution', s.solution);
                            writeDecimalOrNull(gen, 'amount', s.amount);
                            //writeDecimalOrNull(gen, 'standard_price', s.standard_price);
                            //writeDecimalOrNull(gen, 'sales_price', s.sales_price);
                            writeDecimalOrNull(gen, 'quantity', s.quantity);
                            //writeDecimalOrNull(gen, 'percentage', s.percentage);
                            //writeDecimalOrNull(gen, 'minimum_fee', s.minimum_fee);
                            //writeDecimalOrNull(gen, 'discount', s.discount);
                            writeStringOrNull(gen, 'last_modification_date', s.last_modification_date);
                            gen.writeEndObject();
                        }
                    }
                    gen.writeEndArray();

                    gen.writeEndObject();
                }
            }
            gen.writeEndArray();

            gen.writeEndObject();
        }
    }
    gen.writeEndArray();

    gen.writeEndObject();
    return gen.getAsString();
}


    //New helper added by harkirat
    private static Boolean isSavingsAccount(Id accountId) {
        List<Contract> ctrs = [
            SELECT Id, Status, Contract_Category__c
            FROM Contract
            WHERE AccountId = :accountId
            AND Status = 'Activated'
            ORDER BY LastModifiedDate DESC
            LIMIT 50
        ];

        Boolean foundSavings = false;
        Boolean foundBenefits = false;

        for (Contract c : ctrs) {
            if (c.Contract_Category__c == 'Savings') foundSavings = true;
            if (c.Contract_Category__c == 'Benefits') foundBenefits = true;
        }

        System.debug(LoggingLevel.ERROR,
            'NEMO_SYNC | isSavingsAccount accountId=' + accountId +
            ' activatedContracts=' + ctrs.size() +
            ' foundSavings=' + foundSavings +
            ' foundBenefits=' + foundBenefits
        );
        return foundSavings && !foundBenefits;
    }
    //New helper added by harkirat ends
	
    //Fetch token for NEMO callout
    public String fetchAuthToken(){
        String CLIENT_ID, CLIENT_SECRET, RESOURCE;
        List<String> bodyParams = new List<String>();
        HTTPCalloutConfiguration__mdt metadata = HTTPCalloutConfiguration__mdt.getInstance('NEMO_TOKEN');
        CLIENT_ID = metadata.Client_ID__c;
        CLIENT_SECRET = metadata.Client_Secret__c; 
        RESOURCE = metadata.Resource__c; 
        Map<String, String> params = new Map<String, String>{
            'client_id' => CLIENT_ID,
            'client_secret' => CLIENT_SECRET,
            'grant_type' => 'client_credentials',
            'resource' => RESOURCE
        };
        for (String key : params.keySet()) {
            bodyParams.add(key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
        }
        
        HTTPCalloutService service = new HTTPCalloutService('NEMO_TOKEN',String.join(bodyParams, '&'));
        service.setILFlag(false);
        try {
            HttpResponse res = service.sendRequest();
            ilList.add(service.integrationLogsHandler(res));
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (String) responseMap.get('access_token');
            } else {
                throw new CalloutException('Failed to fetch token: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('ex msg'+e.getMessage());
            System.debug('ex line'+e.getLineNumber());
            throw new CalloutException('Token retrieval failed');
        }
    }
    
    //Callout for Create New Client & Contract in NEMO
    public Map<String, Object> createClientCallout(Id contractId){
        System.debug('=== CREATE CLIENT CALLED === contractId=' + contractId);
        String REQUEST_BODY = getCreateClientRequestWrapper(contractId);
        System.debug('CREATE CLIENT REQUEST BODY: ' + REQUEST_BODY);
        String BEARER_TOKEN = fetchAuthToken();
        System.debug('TOKEN FETCHED SUCCESSFULLY');
		return calloutHelper('NEMO_CREATE_CLIENT',REQUEST_BODY,BEARER_TOKEN, null, contractId);
    }

    //Callout for Create Existing Client's Contract in NEMO
    public Map<String, Object> createClientContractCallout(Id accountId, Id contractId){
        //System.debug('=== UPDATE CLIENT CALLED === accountId=' + accountId);
        System.debug('NEMO_SYNC | CREATE CLIENT CONTRACT CALLOUT accountId=' + accountId + ' contractId=' + contractId);
        String REQUEST_BODY = getCreateClientContractRequestWrapper(accountId, contractId);
        System.debug('NEMO_SYNC | CREATE CLIENT CONTRACT REQUEST BODY: ' + REQUEST_BODY);

        /*Boolean isSavings = isSavingsAccount(accountId);
        String REQUEST_BODY;
        if (isSavings) {
            System.debug('NEMO_SYNC | updateClientCallout -> getUpdateClientRequestWrapper_Savings');
            REQUEST_BODY = getUpdateClientRequestWrapper_Savings(accountId);
        } else {
            System.debug('NEMO_SYNC | updateClientCallout -> getUpdateClientRequestWrapper (benefit/default)');
            REQUEST_BODY = getUpdateClientRequestWrapper(accountId);
        }*/

        //Commenting
        //String REQUEST_BODY = getCreateClientContractRequestWrapper(accountId, contractId);


        //System.debug('NEMO_SYNC | CREATE CLIENT CONTRACT BODY_LEN=' + (requestBody == null ? 0 : requestBody.length()));
        //System.debug('NEMO_SYNC | CREATE CLIENT CONTRACT BODY_HEAD=' + (requestBody != null ? requestBody.left(Math.min(600, requestBody.length())) : 'null'));

        String BEARER_TOKEN = fetchAuthToken();
        return calloutHelper('NEMO_CREATE_CLIENT_CONTRACT',REQUEST_BODY,BEARER_TOKEN, accountId, contractId);
    }
    
    //Callout for Update Existing Client in NEMO
    public Map<String, Object> updateClientCallout(Id accountId){
        String REQUEST_BODY = getUpdateClientRequestWrapper(accountId);
        System.debug('NEMO_SYNC | Should not go in this UPDATE CLIENT CALLOUT accountId=' + accountId);

        //new logic
        /*Boolean isSavings = isSavingsAccount(accountId);
        System.debug('NEMO_SYNC | updateClientCallout mode isSavings=' + isSavings);

        String REQUEST_BODY;
        if (isSavings) {
            System.debug('NEMO_SYNC | updateClientCallout -> getUpdateClientRequestWrapper_Savings');
            REQUEST_BODY = getUpdateClientRequestWrapper_Savings(accountId);
        } else {
            System.debug('NEMO_SYNC | updateClientCallout -> getUpdateClientRequestWrapper (benefit/default)');
            REQUEST_BODY = getUpdateClientRequestWrapper(accountId);
        }*/

        //String REQUEST_BODY = getUpdateClientRequestWrapper(accountId);
        //String BEARER_TOKEN = fetchAuthToken();
        //return calloutHelper('NEMO_UPDATE_CLIENT',REQUEST_BODY,BEARER_TOKEN, accountId, null);
        return new Map<String, Object>();
    }

    /*public Map<String, Object> updateClientCallout_Savings(Id accountId){
        System.debug('=== UPDATE CLIENT (SAVINGS) CALLED === accountId=' + accountId);
        String REQUEST_BODY = getUpdateClientRequestWrapper_Savings(accountId);
        // token + calloutHelper same as current update flow once enabled
        return new Map<String, Object>();
    }*/



    //new method
    /*public String getUpdateClientRequestWrapper_Savings(Id accountId) {
        System.debug('NEMO_SYNC | getUpdateClientRequestWrapper_Savings CALLED accountId=' + accountId);
        UpdateClientRequestWrapper wrapObj = buildUpdateClientWrapObj(accountId);
        if (wrapObj == null) return null;

        String wrapper = buildUpdateSavingsJson(wrapObj);

        System.debug('UPDATE_SAVINGS_JSON_OUTPUT=' + wrapper);
        return wrapper;
    }*/

    //New method added by harkirat to send the savings json file
    // public String getUpdateClientRequestWrapper(Id accountId, Boolean isSavings){
    //     // existing code that builds wrapObj stays SAME
    //     String wrapper;
    //     // at the end replace the serialize line with:
    //     if (isSavings) {
    //         wrapper = buildUpdateSavingsJson(wrapObj); // NEW
    //     } else {
    //         wrapper = JSON.serialize(wrapObj).replaceAll('street_number', 'number');
    //     }

    //     System.debug('UPDATE_JSON_MODE isSavings=' + isSavings);
    //     System.debug('UPDATE_JSON_LENGTH=' + (wrapper != null ? wrapper.length() : 0));
    //     return wrapper;
    // }
    
    //Callout helper for NEMO Callout
    public Map<String, Object> calloutHelper(String metadata, String requestBody, String token, String accountId, String contractId){
        
        Map<String, Object> responseMap = null;
        HTTPCalloutService service = new HTTPCalloutService(metadata,requestBody);
        service.setContractId(contractId);
        service.setAccountId(accountId);
        service.setHeaderParameter('Authorization','Bearer '+token);
        service.setILFlag(false);
        try {
            HttpResponse res = service.sendRequest();
            ilList.add(service.integrationLogsHandler(res));
            handleSyncDetail(contractId, accountId, res);
            if (res.getStatusCode() == 200) {
                if(res.getBody() != null){
                    responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                }
            }
        } catch (Exception e) {
            System.debug('line'+e.getLineNumber());
            System.debug('Exception: ' + e.getMessage());
        }
        if(!ilList.isEmpty()){
            insert ilList;
        }
        return responseMap;
    }
    
    //NEMO Response Handler
    public void handleSyncDetail(String contractId, String accountId, HttpResponse res){
        Set<String> solutionIds = new Set<String>();
        List<ER_Solution_Line_Item__c> activeSolToInsert = new List<ER_Solution_Line_Item__c>();
        String recordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName().get('ER_Account_Line_Item').getRecordTypeId();
        
        if(String.isNotBlank(contractId)){
            Contract contObj = [Select Id, ER_OpportunityId__r.StageName, ER_OpportunityId__c, ER_OpportunityId__r.ER_Won_Reason__c, AccountId, ER_BUPicklist__c, Status FROM Contract WHERE Id =:contractId LIMIT 1];
            List<ER_ContractLineItem__c> contractLIList = [Select Id, ER_Product2__c, ER_Product2__r.ER_Solution2__r.ProductCode FROM ER_ContractLineItem__c WHERE ER_Product2__r.ER_Solution2__c != null AND ER_Contract__c =:contractId];
            if(contObj.Status != 'Activated' && (res.getStatusCode() == 200 || res.getStatusCode() == 201)){
                contObj.Status = 'Activated';
                
                //Active Solution Creation
                if(!contractLIList.isEmpty()){
                    for(ER_ContractLineItem__c coli : contractLIList){
                        if(coli.ER_Product2__r.ER_Solution2__r.ProductCode!= Constants.ADDITIONAL_SERVICE_CODE_LU && coli.ER_Product2__r.ER_Solution2__r.ProductCode!= Constants.ADDITIONAL_SERVICE_CODE_BE){
                            if(!solutionIds.contains(coli.ER_Product2__r.ER_Solution2__c)){
                                solutionIds.add(coli.ER_Product2__r.ER_Solution2__c);
                            }
                        }
                    }
                }
                
                if(!solutionIds.isEmpty()){
                    for(String solution : solutionIds){
                        ER_Solution_Line_Item__c activeSol = new ER_Solution_Line_Item__c();
                        activeSol.RecordTypeId = recordTypeId;
                        activeSol.ER_Contract__c = contractId;
                        activeSol.ER_Account__c = contObj.AccountId;
                        activeSol.ER_Solution__c = solution;
                        activeSol.ER_BUPicklist__c = contObj.ER_BUPicklist__c;
                        activeSol.ER_Creation_date_in_OS__c = System.today();
                        activeSol.ER_Scope__c = 'Client';
                        activeSol.ER_Status__c = 'Active';
                        activeSolToInsert.add(activeSol);
                    }
                }
            }
            contObj.ER_Last_date_of_Sync__c = System.today();
            contObj.ER_Creation_date_in_OS__c = System.today();
            contObj.ER_WS_Message_Long__c = res.getStatus();

            contObj.ER_WS_StatusCode__c = res.getStatusCode() == 200 || res.getStatusCode() == 201 ? 'In Progress' : 'Not Valid';
            contObj.ER_Sync_Code__c = String.valueOf(res.getStatusCode());
            update contObj;
            
            Account accObj = new Account(Id=contObj.AccountId);
            accObj.ER_Sync_Code__c = String.valueOf(res.getStatusCode());
            String responseStr = res.getStatusCode() != 200 && res.getStatusCode() != 201 ? res.getBody() : null;
            String extractedMessage = responseStr;
            try {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseStr);
                if (responseMap.containsKey('meta')) {
                    Map<String, Object> metaMap = (Map<String, Object>) responseMap.get('meta');
                    if (metaMap.containsKey('messages')) {
                        List<Object> messages = (List<Object>) metaMap.get('messages');
                        if (!messages.isEmpty()) {
                            Map<String, Object> firstMessage = (Map<String, Object>) messages[0];
                            if (firstMessage.containsKey('text')) {
                                extractedMessage = (String) firstMessage.get('text');
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
            }
            if(extractedMessage == null){
                accObj.ER_WS_result_Text_Long__c = extractedMessage;
            }else{
                accObj.ER_WS_result_Text_Long__c = extractedMessage;
            }
            accObj.ER_Sync_result__c = res.getStatusCode() == 200 || res.getStatusCode() == 201 ? 'synchronized' : 'not_synchronized';
            accObj.ER_Last_date_of_Sync__c = System.today();
            update accObj;
            
            if(!activeSolToInsert.isEmpty()){
                insert activeSolToInsert;
            }
        }else if(String.isNotBlank(accountId)){
            Account accObj = new Account(Id=accountId);
            accObj.ER_Sync_Code__c = String.valueOf(res.getStatusCode());
            accObj.ER_Sync_result__c = res.getStatusCode() == 200 || res.getStatusCode() == 201 ? 'synchronized' : 'pending_synchronization';
            accObj.ER_Last_date_of_Sync__c = System.today();
            update accObj;
        }
    }

private static void writeLegalSite(JSONGenerator gen, CreateClientRequestWrapper.LegalSiteWrapper ls) {
    gen.writeStartObject();
    writeStringOrNull(gen, 'contact_id', ls.contact_id);
    writeStringOrNull(gen, 'language_code', ls.language_code);
    // address
    gen.writeFieldName('address');
    if (ls.address == null) {
        gen.writeNull();
    } else {
        writeAddress(gen, ls.address);
    }
    // financial_centers (always output array)
    gen.writeFieldName('financial_centers');
    gen.writeStartArray();
    if (ls.financial_centers != null) {
        for (CreateClientRequestWrapper.FinancialCenterWrapper fc : ls.financial_centers) {
            writeFinancialCenter(gen, fc);
        }
    }
    gen.writeEndArray();

    gen.writeEndObject();
}
private static void writeAddress(JSONGenerator gen, CreateClientRequestWrapper.AddressWrapper a) {
    gen.writeStartObject();
    writeStringOrNull(gen, 'street', a.street);
    // If you want final JSON key as "number", write it as "number" here
    // (then you don't need replaceAll('street_number','number') for Savings).
    writeStringOrNull(gen, 'number', a.street_number);
    writeStringOrNull(gen, 'po_box', a.po_box);
    writeStringOrNull(gen, 'zip_code', a.zip_code);
    writeStringOrNull(gen, 'city', a.city);
    writeStringOrNull(gen, 'country_code', a.country_code);
    gen.writeEndObject();
}
private static void writeFinancialCenter(JSONGenerator gen, CreateClientRequestWrapper.FinancialCenterWrapper fc) {
    gen.writeStartObject();
    writeStringOrNull(gen, 'crm_id', fc.crm_id);
    writeStringOrNull(gen, 'name', fc.name);
    writeStringOrNull(gen, 'contact_id', fc.contact_id);
    writeStringOrNull(gen, 'language_code', fc.language_code);
    writeStringOrNull(gen, 'last_modification_date', fc.last_modification_date);
    gen.writeFieldName('address');
    if (fc.address == null) gen.writeNull();
    else writeAddress(gen, fc.address);
    gen.writeFieldName('bank_account');
    if (fc.bank_account == null) {
        gen.writeNull();
    } else {
        gen.writeStartObject();
        writeStringOrNull(gen, 'iban', fc.bank_account.iban);
        writeStringOrNull(gen, 'bic', fc.bank_account.bic);
        gen.writeEndObject();
    }
    gen.writeFieldName('delivery_sites');
    gen.writeStartArray();
    if (fc.delivery_sites != null) {
        for (CreateClientRequestWrapper.DeliverySiteWrapper ds : fc.delivery_sites) {
            writeDeliverySite(gen, ds);
        }
    }
    gen.writeEndArray();
    gen.writeEndObject();
}
private static void writeDeliverySite(JSONGenerator gen, CreateClientRequestWrapper.DeliverySiteWrapper ds) {
    gen.writeStartObject();
    writeStringOrNull(gen, 'crm_id', ds.crm_id);
    writeStringOrNull(gen, 'name', ds.name);
    writeStringOrNull(gen, 'contact_id', ds.contact_id);
    writeStringOrNull(gen, 'language_code', ds.language_code);
    writeStringOrNull(gen, 'last_modification_date', ds.last_modification_date);
    gen.writeFieldName('address');
    if (ds.address == null) gen.writeNull();
    else writeAddress(gen, ds.address);
    gen.writeFieldName('distribution_points');
    gen.writeStartArray();
    if (ds.distribution_points != null) {
        for (CreateClientRequestWrapper.DistributionPointWrapper dp : ds.distribution_points) {
            writeDistributionPoint(gen, dp);
        }
    }
    gen.writeEndArray();
    gen.writeEndObject();
}

private static void writeDistributionPoint(JSONGenerator gen, CreateClientRequestWrapper.DistributionPointWrapper dp) {
    gen.writeStartObject();
    writeStringOrNull(gen, 'crm_id', dp.crm_id);
    writeStringOrNull(gen, 'name', dp.name);
    writeStringOrNull(gen, 'contact_id', dp.contact_id);
    writeStringOrNull(gen, 'language_code', dp.language_code);
    writeStringOrNull(gen, 'last_modification_date', dp.last_modification_date);
    gen.writeFieldName('address');
    if (dp.address == null) gen.writeNull();
    else writeAddress(gen, dp.address);
    gen.writeEndObject();
}
    
    private static String getEffectiveSolution(ER_ContractLineItem__c cliObj) {
    if (cliObj == null) return null;

    if (cliObj.ER_ProductCode__c == 'VC_TRL' || 
        cliObj.ER_ProductCode__c == 'VC_TCL') {
        return 'CLU';
    }

    return cliObj.ER_Solution__c;
}
}