public without sharing class ContractNemoSyncQueueable
    implements Queueable, Database.AllowsCallouts {

    private Set<Id> contractIds;

    public ContractNemoSyncQueueable(Set<Id> contractIds) {
        this.contractIds = contractIds;
    }

    public void execute(QueueableContext context) {

        if (contractIds == null || contractIds.isEmpty()) {
            return;
        }

        SyncClientContractService service =
            new SyncClientContractService();

        List<Contract> contracts = [
            SELECT Id, AccountId,
                   Account.ER_Card_Client_Operational_System_ID__c, NEMO_Sync_Pending__c
            FROM Contract
            WHERE Id IN :contractIds
        ];

        List<Contract> contractsToUpdate = new List<Contract>();

        for (Contract con : contracts) {
            try {
                if (con.Account.ER_Card_Client_Operational_System_ID__c == null) {
                    service.createClientCallout(con.Id);
                } else {
                    service.createClientContractCallout(
                        con.AccountId,
                        con.Id
                    );
                }
                if (con.NEMO_Sync_Pending__c) {
                    contractsToUpdate.add(
                        new Contract(
                            Id = con.Id,
                            NEMO_Sync_Pending__c = false
                        )
                    );
                }
            } catch (Exception e) {
                // Existing error handling / retry framework will handle this
                System.debug(
                    'NEMO sync failed for Contract ' +
                    con.Id + ' → ' + e.getMessage()
                );
            }
        }

        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
    }
}