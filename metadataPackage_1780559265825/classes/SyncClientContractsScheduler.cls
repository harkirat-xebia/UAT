global class SyncClientContractsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Integer batchSize = 1;
        List<Batch_Setting__mdt> batchSettingList = [Select DeveloperName, Batch_Size__c, Query_Limit__c FROM Batch_Setting__mdt WHERE DeveloperName = 'SyncClientContractsBatch'];
        if(!batchSettingList.isEmpty()){
            batchSize = Integer.valueOf(batchSettingList[0].Batch_Size__c);
        }
        SyncClientContractsBatch batchJob = new SyncClientContractsBatch();
        Database.executeBatch(batchJob, batchSize);
    }
}