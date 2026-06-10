public without sharing class ActivateContractsQueueable 
implements Queueable, Database.AllowsCallouts {
    
    private List<Id> contractIds;
    private List<Id> failedIds;
    private Integer totalCount;
    private Integer processedCount;  
    
    public ActivateContractsQueueable(List<Id> contractIds, List<Id> failedIds) {
        this.contractIds = contractIds;
        this.failedIds = failedIds == null ? new List<Id>() : failedIds;
        this.totalCount = contractIds.size();
        this.processedCount = 0;
    }
    
    private ActivateContractsQueueable(List<Id> contractIds, List<Id> failedIds, 
                                      Integer totalCount, Integer processedCount) {
        this.contractIds = contractIds;
        this.failedIds = failedIds;
        this.totalCount = totalCount;
        this.processedCount = processedCount;
    }
    
    public void execute(QueueableContext context) {
        /*System.debug('=== Contract Activation Queueable ===');
        System.debug('Job ID: ' + context.getJobId());
        System.debug('Progress: ' + processedCount + '/' + totalCount);
        System.debug('Remaining: ' + contractIds.size());
        System.debug('Failed so far: ' + failedIds.size());*/
        
        if (contractIds.isEmpty()) {
            logFailures(failedIds);
            return;
        }
        
        Id currentId = contractIds.remove(0);
        processedCount++;
        
        System.debug('Processing contract ' + processedCount + '/' + totalCount + ': ' + currentId);
        
        SyncClientContractService service = new SyncClientContractService();
        try {
            Contract cont = [
                SELECT Id, Name, AccountId,
                       Account.ER_Card_Client_Operational_System_ID__c
                FROM Contract
                WHERE Id = :currentId
                LIMIT 1
            ];
            
            if (cont.AccountId == null) {
                throw new ContractException('Contract has no Account: ' + cont.Name);
            }
            
            if (cont.Account.ER_Card_Client_Operational_System_ID__c == null) {
                //System.debug('Creating new client for contract: ' + cont.Name);
                service.createClientCallout(cont.Id);
            } else {
                //System.debug('Creating contract for existing client: ' + cont.Name);
                service.createClientContractCallout(cont.AccountId, cont.Id);
            }
            
            //System.debug('Successfully processed: ' + cont.Name);
            
        } catch (Exception e) {
            //System.debug('Error for contract ' + currentId + ' : ' + e.getMessage());
            //System.debug('Stack trace: ' + e.getStackTraceString());  // ADD THIS
            failedIds.add(currentId);
            
            logIndividualFailure(currentId, e.getMessage());
        }
        
        if (!Test.isRunningTest()) {  
            System.enqueueJob(
                new ActivateContractsQueueable(contractIds, failedIds, totalCount, processedCount)
            );
        }
    }
    
    private void logFailures(List<Id> failedIds) {
        Integer successCount = totalCount - failedIds.size();
        
        /*System.debug('=== FINAL RESULTS ===');
        System.debug('Total Contracts: ' + totalCount);
        System.debug('Successfully Activated: ' + successCount);
        System.debug('Failed: ' + failedIds.size());*/
        
        if (failedIds.isEmpty()) {
            //System.debug('All contracts activated successfully!');
            return;
        }
        
        //System.debug('Failed Contract IDs: ' + failedIds);
        
        createFailureSummary(failedIds, successCount);
        
        sendNotification(successCount, failedIds.size());
    }
    
    private void logIndividualFailure(Id contractId, String errorMessage) {
        try {
            // Option 1: Use Platform Events (recommended for async)
            /*
            Contract_Activation_Error__e errorEvent = new Contract_Activation_Error__e(
                Contract_Id__c = contractId,
                Error_Message__c = errorMessage,
                Timestamp__c = System.now()
            );
            EventBus.publish(errorEvent);
            */
            
            // Option 2: Insert error log (if you have custom object)
            /*
            Contract_Activation_Log__c log = new Contract_Activation_Log__c(
                Contract__c = contractId,
                Status__c = 'Failed',
                Error_Message__c = errorMessage.left(255),
                Processed_Date__c = System.now()
            );
            insert log;
            */
            
            // For now, just debug
            //System.debug('Logged failure for: ' + contractId);
            
        } catch (Exception e) {
            //System.debug('Failed to log error: ' + e.getMessage());
        }
    }
    
    private void createFailureSummary(List<Id> failedIds, Integer successCount) {
        try {
            
            String failedIdsStr = String.join(new List<Id>(failedIds), ', ');
            //System.debug('Summary - Success: ' + successCount + ', Failed IDs: ' + failedIdsStr);
            
            // Optional: Insert summary record
            /*
            Contract_Activation_Summary__c summary = new Contract_Activation_Summary__c(
                Total_Contracts__c = totalCount,
                Successful__c = successCount,
                Failed__c = failedIds.size(),
                Failed_Contract_IDs__c = failedIdsStr.left(32000),
                Completion_Date__c = System.now(),
                Initiated_By__c = UserInfo.getUserId()
            );
            insert summary;
            */
            
        } catch (Exception e) {
            //System.debug('Failed to create summary: ' + e.getMessage());
        }
    }
    
    private void sendNotification(Integer successCount, Integer failureCount) {
        try {
            // Option 1: Custom Notification (requires Custom Notification Type setup)
            /*
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Contract Activation Complete');
            notification.setBody('Activated: ' + successCount + ', Failed: ' + failureCount);
            notification.setNotificationTypeId('YOUR_NOTIFICATION_TYPE_ID');
            notification.setTargetId(UserInfo.getUserId());
            notification.send(new Set<String>{UserInfo.getUserId()});
            */
            
            // Option 2: Email notification
            /*
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{UserInfo.getUserEmail()});
            email.setSubject('Contract Activation Complete');
            email.setPlainTextBody(
                'Total: ' + totalCount + '\n' +
                'Successful: ' + successCount + '\n' +
                'Failed: ' + failureCount
            );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            */
            
            //System.debug('Notification would be sent here');
            
        } catch (Exception e) {
            //System.debug('Failed to send notification: ' + e.getMessage());
        }
    }
    
    public class ContractException extends Exception {}
}