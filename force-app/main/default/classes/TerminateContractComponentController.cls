public class TerminateContractComponentController {
    @AuraEnabled
    public static Map<String, Object> terminateContract(String contractId, String terminationReason, String subTerminationReason, Date contractEndDate){
        try {
            String accountId = fetchAccountId(contractId);
            List<Contract> contractsToUpdate = new List<Contract>();
            Map<String, Object> responseMap = new Map<String, Object>();

            Contract con = new Contract();
            con.Id = contractId;
            con.ER_TerminationReason__c = terminationReason;
            con.Termination_Sub_Reason__c = subTerminationReason;
            con.EndDate = contractEndDate;
            if(contractEndDate <= Date.Today()){
                con.Status = 'Terminated';
                con.ER_Terminated_Date__c = Date.today();
            }
            contractsToUpdate.add(con);

            System.debug('contractsToUpdate: ' + contractsToUpdate);
            update contractsToUpdate;
            /* if(!contractsToUpdate.isEmpty()){
                SyncClientContractService service = new SyncClientContractService();
                responseMap = service.createClientContractCallout(accountId, null);
                System.debug('responseMap: ' + responseMap);
                if(responseMap != null){
                    System.debug('contractsToUpdate: ' + contractsToUpdate);
                    update contractsToUpdate;
                }
            } */
            responseMap.put('status', 'success');
            return responseMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static boolean checkErrors(String contractId){
        try {
            Boolean hasError = false;
            String accountId = fetchAccountId(contractId);
            Integer count = 0;
            for(Contract con : [Select Id, Status from Contract WHERE AccountId =: accountId AND Status = 'Activated']){
                count++;
            }
            if(!(count>=2)){
                //hasError = true;
            }
            return hasError;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void setStatusPendingTermination(String contractId){
        try {
            String accountId = fetchAccountId(contractId);
            List<Contract> contractsToUpdate = new List<Contract>();

            Contract con = new Contract();
            con.Id = contractId;
            con.Status = 'Pending Termination';
            contractsToUpdate.add(con);

            if(!contractsToUpdate.isEmpty()){
                update contractsToUpdate;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static string fetchAccountId(String contractId){
        return [Select Id, AccountId FROM Contract WHERE Id=: contractId LIMIT 1].AccountId;
    }
}