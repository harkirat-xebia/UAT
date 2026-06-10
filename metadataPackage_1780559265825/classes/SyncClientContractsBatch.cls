global class SyncClientContractsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        Integer accountLimit = 10;

        List<Batch_Setting__mdt> batchSettingList = [Select DeveloperName, Batch_Size__c, Query_Limit__c FROM Batch_Setting__mdt WHERE DeveloperName = 'SyncClientContractsBatch'];
        if(!batchSettingList.isEmpty()){
            accountLimit = Integer.valueOf(batchSettingList[0].Query_Limit__c);
        }
        String accountQuery = 
            'SELECT Id, Name, ER_Card_Client_Operational_System_ID__c ' +
            'FROM Account ' +
            'WHERE Id IN (SELECT AccountId FROM Contract ' +
            'WHERE Status = \'Draft\' ' +
            'AND CreatedBy.Profile.Name NOT IN (\'Integration Profile\', \'Marketing Automation Integration User\', \'Sales Insights Integration User\')) ' +
            'AND ER_Sync_Result__c != \'synchronized\' ' +
            'AND ER_Card_Client_Operational_System_ID__c != NULL ' +
            'LIMIT ' + accountLimit;

        return Database.getQueryLocator(accountQuery);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {

        if (!scope.isEmpty() && scope.size() == 1) {
            List<Contract> contracts = [SELECT Id FROM Contract WHERE AccountId = :scope[0].Id AND Status IN ('Draft')];  
            for (Contract con : contracts) {
                SyncClientContractService service = new SyncClientContractService();
                service.createClientContractCallout(scope[0].Id, con.Id);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Client Contract Sync Batch Completed');
    }
}