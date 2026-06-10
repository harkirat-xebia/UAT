/*
----------------------------------------------------------------------
-- - Name          : PromoCodeExpiredContractSyncBatch 
-- - Author        : Snehil Verma
-- - Description   : Batch class to sync promo code expired contracts in NEMO 
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Jan-2025     Snehil Verma        1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class PromoCodeExpiredContractSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id FROM Account where ER_Sync_result__c=\'pending_synchronization\' AND Account.ER_Card_Client_Operational_System_ID__c != null';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> account){
        
        if(account.size() == 1){
            List<Contract> contractList = [SELECT Id from Contract where Status = 'Activated' AND AccountId =:account[0].Id];
            if(!contractList.isEmpty()){
                SyncClientContractService service = new SyncClientContractService();
                service.createClientContractCallout(account[0].Id, null);
            }
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('Batch Job ID (finish): ' + bc.getJobId());
    }
}