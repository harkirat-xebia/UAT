/*
----------------------------------------------------------------------
-- - Name          : PromoCodeExpirationBatch 
-- - Author        : Snehil Verma
-- - Description   : Batch class to deactivate discounted line items and activate non discounted line items with new start date for account re-synchronization
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Jan-2025     Snehil Verma        1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class PromoCodeExpirationBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc){
        Date expirationDate = System.today().addDays(-1);
        String query = 'SELECT Id, AccountId FROM Contract where Offer_Validity_End_Date__c =:expirationDate AND Account.ER_Card_Client_Operational_System_ID__c != null and Status=\'Activated\'';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Contract> contract){
        
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Boolean> benefitMap = new Map<Id, Boolean>();
        Map<Id, List<ER_ContractLineItem__c>> cliMap = new Map<Id, List<ER_ContractLineItem__c>>();
        Map<Id, Map<String, Map<String, Boolean>>> solutionDiscountAppliedMap = new Map<Id, Map<String, Map<String, Boolean>>>();
        List<Account> accountUpdateList = new List<Account>();
        List<ER_ContractLineItem__c> cliUpdateList = new List<ER_ContractLineItem__c>();
        
        for(ER_ContractLineItem__c cli : [SELECT Id, ER_Contract__c, ER_IsActive__c, ER_Product2__r.Solution_Group__c, ER_Product2__r.ER_Type__c, ER_Product2__r.ProductCode, ER_Product2__r.ER_Solution2__r.ProductCode, ER_Contract__r.Offer_Validity_End_Date__c, ER_Contract__r.AccountId from ER_ContractLineItem__c where ER_Contract__c IN:contract ]){
            if(!cliMap.containsKey(cli.ER_Contract__c)){
                cliMap.put(cli.ER_Contract__c, new List<ER_ContractLineItem__c>{cli});
            }else{
                cliMap.get(cli.ER_Contract__c).add(cli);
            }
            
            if(!benefitMap.containsKey(cli.ER_Contract__c)){
                benefitMap.put(cli.ER_Contract__c, false);
            }
            if(cli.ER_Product2__r.Solution_Group__c == 'Benefits'){
                benefitMap.put(cli.ER_Contract__c, true);
            }
            
            if(!solutionDiscountAppliedMap.containsKey(cli.ER_Contract__c)){
                solutionDiscountAppliedMap.put(cli.ER_Contract__c, new Map<String, Map<String, Boolean>>());
                solutionDiscountAppliedMap.get(cli.ER_Contract__c).put(cli.ER_Product2__r.ER_Solution2__r.ProductCode, new Map<String, Boolean>());
                solutionDiscountAppliedMap.get(cli.ER_Contract__c).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).put(cli.ER_Product2__r.ProductCode, false);
                if(cli.ER_Product2__r.ER_Type__c == 'Discount'){
                    solutionDiscountAppliedMap.get(cli.ER_Contract__c).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).put(cli.ER_Product2__r.ProductCode, true);
                }
            }else{
                if(!solutionDiscountAppliedMap.get(cli.ER_Contract__c).containsKey(cli.ER_Product2__r.ER_Solution2__r.ProductCode)){
                    solutionDiscountAppliedMap.get(cli.ER_Contract__c).put(cli.ER_Product2__r.ER_Solution2__r.ProductCode, new Map<String, Boolean>());
                    solutionDiscountAppliedMap.get(cli.ER_Contract__c).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).put(cli.ER_Product2__r.ProductCode, false);
                    if(cli.ER_Product2__r.ER_Type__c == 'Discount'){
                        solutionDiscountAppliedMap.get(cli.ER_Contract__c).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).put(cli.ER_Product2__r.ProductCode, true);
                    }
                }else{
                    if(!solutionDiscountAppliedMap.get(cli.ER_Contract__c).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).containsKey(cli.ER_Product2__r.ProductCode)){
                        solutionDiscountAppliedMap.get(cli.ER_Contract__c).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).put(cli.ER_Product2__r.ProductCode, false);
                    }
                    if(cli.ER_Product2__r.ER_Type__c == 'Discount'){
                        solutionDiscountAppliedMap.get(cli.ER_Contract__c).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).put(cli.ER_Product2__r.ProductCode, true);
                    }
                }
            }
        }
        
        for(Id contractId : cliMap.keySet()){
            if(benefitMap.get(contractId)){
                for(ER_ContractLineItem__c cli : cliMap.get(contractId)){
                    if(solutionDiscountAppliedMap.get(contractId).get(cli.ER_Product2__r.ER_Solution2__r.ProductCode).get(cli.ER_Product2__r.ProductCode)){
                        System.debug('cli.ER_Product2__r.ER_Type__c inside'+cli.ER_Product2__r.ER_Type__c);
                        if(cli.ER_Product2__r.ER_Type__c == 'Discount'){
                            cli.ER_IsActive__c  = false;
                        }else{
                            cli.ER_IsActive__c  = true;
                            cli.ER_Price_Start_Date__c = cli.ER_Contract__r.Offer_Validity_End_Date__c.addDays(1);
                        }
                        cliUpdateList.add(cli);
                        accountIdSet.add(cli.ER_Contract__r.AccountId);
                    }
                }
            }
        }
        
        for(Id accountId : accountIdSet){
            Account accObj = new Account(Id=accountId, ER_Sync_result__c='pending_synchronization');
            accountUpdateList.add(accObj);
        }
        
        if(!cliUpdateList.isEmpty()){
            update cliUpdateList;
        }
        
        if(!accountUpdateList.isEmpty()){
            update accountUpdateList;
        }
        
        
    }
    
    public void finish(Database.BatchableContext bc){
        Database.executeBatch(new PromoCodeExpiredContractSyncBatch(), 1);
        System.debug('Batch Job ID (finish): ' + bc.getJobId());
    }
}