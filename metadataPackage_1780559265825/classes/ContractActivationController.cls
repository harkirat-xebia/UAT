public with sharing class ContractActivationController {
    
    @AuraEnabled(cacheable=false)
    public static List<ContractWrapper> getContractStatuses(List<Id> contractIds) {
        List<ContractWrapper> contractWrappers = new List<ContractWrapper>();
        
        try {
            // Query contracts with relevant fields
            List<Contract> contracts = [
                SELECT Id, ContractNumber, Status, 
                       Contract_Category__c, 
                       ER_WS_StatusCode__c,
                       LastModifiedDate
                FROM Contract
                WHERE Id IN :contractIds
                WITH SECURITY_ENFORCED
            ];
            
            for (Contract con : contracts) {
                ContractWrapper wrapper = new ContractWrapper();
                wrapper.contractId = con.Id;
                wrapper.contractNumber = con.ContractNumber;
                wrapper.status = con.Status;
                wrapper.contractCategory = con.Contract_Category__c;
                wrapper.syncStatusCode = con.ER_WS_StatusCode__c;
                wrapper.lastModifiedDate = con.LastModifiedDate;
                wrapper.recordUrl = '/' + con.Id;
                
                contractWrappers.add(wrapper);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching contract statuses: ' + e.getMessage());
        }
        
        return contractWrappers;
    }
    
    public class ContractWrapper {
        @AuraEnabled public Id contractId;
        @AuraEnabled public String contractNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String contractCategory;
        @AuraEnabled public String syncStatusCode;
        @AuraEnabled public DateTime lastModifiedDate;
        @AuraEnabled public String recordUrl;
    }
}