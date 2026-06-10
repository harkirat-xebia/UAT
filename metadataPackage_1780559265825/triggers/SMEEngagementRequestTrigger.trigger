trigger SMEEngagementRequestTrigger on SME_Engagement_Request__e (after insert) {
    System.debug('Running User: ' + UserInfo.getName());
    System.debug('User Type: ' + UserInfo.getUserType());
    System.debug('Processing ' + Trigger.new.size() + ' events');
    
    for (SME_Engagement_Request__e event : Trigger.new) {
        try {
            System.debug('Processing event with Contract IDs: ' + event.Contract_Ids__c);
            
            // Parse contract IDs
            List<String> contractIdStrings = event.Contract_Ids__c.split(',');
            List<Id> contractIds = new List<Id>();
            
            for (String idStr : contractIdStrings) {
                if (String.isNotBlank(idStr)) {
                    contractIds.add((Id)idStr.trim());
                }
            }
            
            System.debug('Parsed ' + contractIds.size() + ' contract IDs');
            
            if (!contractIds.isEmpty()) {
                // Enqueue queueable - now runs as Automated Process user
                System.enqueueJob(new SMEPlatformEngagementQueueable(contractIds));
                System.debug('✓ Queueable enqueued successfully');
            }
            
        } catch (Exception e) {
            System.debug('ERROR processing event: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
        }
    }
}