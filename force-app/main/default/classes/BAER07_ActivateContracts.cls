/**
 * Created by khaddouch on 30/12/2022.
 */


global class BAER07_ActivateContracts implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    String query;

    global BAER07_ActivateContracts() {
        String userBu = APER10_User_Management.userBU;
        query = Label.LABS_SF_BAER07_ActivateContracts;
        query = query.replace('XXX', '\'' + userBu + '\'');
    }

    global BAER07_ActivateContracts(String query) {

        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        System.debug('###query : ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contract> scope) {

        for(Contract contractInst : scope) {
            Set<Id> accounts = new Set<Id>();
            Set<Id> contracts = new Set<Id>();
            Set<Id> ModifiedElements = new Set<Id>();
            Map<Id,String> accountsInputScope = new Map<Id, String>();
            accountsInputScope.put(contractInst.AccountId,(contractInst.RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? 'merchant' : 'client'));
            accounts.add(contractInst.AccountId);
            contracts.add(contractInst.Id);
            System.debug('call activation contract start !!');
            if(!Test.isRunningTest()) ER_SyncStructureWS.createStructureWS(accounts, contracts, 'PUT', 'Activation', ModifiedElements, accountsInputScope);
            System.debug('call activation contract end !!');
        }
    }

    global void execute(SchedulableContext sc) {
        BAER07_ActivateContracts activateContractBatch = new BAER07_ActivateContracts();
        Database.executeBatch(activateContractBatch, Integer.valueOf(Label.LABS_SF_BAHU01_ManageTerminatedContract_batchSize));
    }

    global void finish(Database.BatchableContext BC) {

    }
}