/*
----------------------------------------------------------------------
-- - Name          : BAHU01_ManageTerminatedContract
-- - Author        : OLA
-- - Description   : Batch to Synchronize Terminated Contract
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Mar-2019       OLA                 1.0         Initial version
--  Nov-2019       OLA                 2.0         Replace old query : business Unit is now dynamically taken from user.
--  Dec-2019       OLA                 3.0         Add Offline Mode.
---------------------------------------------------------------------------------------
*/
global class BAHU01_ManageTerminatedContract implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
  String query;

  global BAHU01_ManageTerminatedContract() {
    String userBu = APER10_User_Management.userBU;
    query = Label.LABS_SF_BAHU01_ManageTerminatedContract_Query;
    query = query.replace('{0}', '\'' + userBu + '\'');
  }

  global BAHU01_ManageTerminatedContract(String query) {
    this.query = query;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    System.debug('###query : ' + query);
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Contract> scope) {
    List<Contract> offlineContracts = new List<Contract>();
    List<Contract> onlineContracts = new List<Contract>();
    for (Contract ctr : scope) {
      if (APER12_Contract_Management.isOfflineBU(ctr))
        offlineContracts.add(ctr);
      else
        onlineContracts.add(ctr);
    }
    System.debug('offlineContracts !! : ' + offlineContracts);
    System.debug('onlineContracts !! : ' + onlineContracts);
    //Call OfflineTerminated Contracts
    if (!offlineContracts.isEmpty())
      APER12_Contract_Management.terminatedContacts(offlineContracts);

    for (Contract contractInst : onlineContracts) {
      Set<Id> accounts = new Set<Id>();
      Set<Id> contracts = new Set<Id>();
      Set<Id> ModifiedElements = new Set<Id>();
      Map<Id, String> accountsInputScope = new Map<Id, String>();
      accountsInputScope.put(
        contractInst.AccountId,
        (contractInst.RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? 'merchant' : 'client')
      );
      accounts.add(contractInst.AccountId);
      contracts.add(contractInst.Id);
      System.debug('call terminate contract start !!');
      ER_SyncStructureWS.createStructureWS(
        accounts,
        contracts,
        'PUT',
        'Termination',
        ModifiedElements,
        accountsInputScope
      );
      System.debug('call terminate contract end !!');
    }
  }

  global void execute(SchedulableContext sc) {
    BAHU01_ManageTerminatedContract terminatedContractBatch = new BAHU01_ManageTerminatedContract();
    Database.executeBatch(
      terminatedContractBatch,
      Integer.valueOf(Label.LABS_SF_BAHU01_ManageTerminatedContract_batchSize)
    );
  }

  global void finish(Database.BatchableContext BC) {
  }
}