/**
 * @author: ALK
 * @date: 04/01/2023
 * @desc: DistributedTransactionEvtManagement
 * @see: DistributedTransactionEvtManagement
 */

public with sharing class DistributedTransactionEvtManagement {
  public static void executeTransaction(List<Distributed_Transaction_Event__e> newItems) {
    for (Distributed_Transaction_Event__e e : newItems) {
      switch on e.Transaction_Name__c {
        when 'MANAGE_SOLUTION_LINE_ITEMS' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            Contract eventContract = ((Contract) JSON.deserialize(e.Transaction_Content__c, Contract.class));
            if (eventContract.Id != null) {
              ER_SyncStructureWS.alreadyExecutedSync = true;
              List<Contract> activatedContracts = APER12_Contract_Management.getContract(
                new List<Id>{ eventContract.Id }
              );
              if (!activatedContracts.isEmpty())
                APER12_Contract_Management.manageSolutionLineItems(activatedContracts[0]);
            }
          }
        }
        when 'RUN_STORE_TO_LOOP_CREATION' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            ER_SyncStructureWS.alreadyExecutedSync = true;
            Set<Id> accountToLoops = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (accountToLoops != null && !accountToLoops.isEmpty())
              APER21_StoreToLoopManagement.createStoreToLoop(accountToLoops);
          }
        }
        when 'RUN_STORE_TO_LOOP_UPDATE' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            ER_SyncStructureWS.alreadyExecutedSync = true;
            Set<Id> accountToLoops = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (accountToLoops != null && !accountToLoops.isEmpty())
              APER21_StoreToLoopManagement.updateStoreToLoop(accountToLoops);
          }
        }
        when 'RUN_ACCEPTOR_TO_LOOP_CREATION' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            ER_SyncStructureWS.alreadyExecutedSync = true;
            Set<Id> storesToLoops = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (storesToLoops != null && !storesToLoops.isEmpty())
              APER22_AcceptorToLoopManagement.createAcceptorToLoop(storesToLoops);
          }
        }
        when 'RUN_ACCEPTOR_TO_LOOP_UPDATE' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            ER_SyncStructureWS.alreadyExecutedSync = true;
            Set<Id> storesToLoops = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (storesToLoops != null && !storesToLoops.isEmpty())
              APER22_AcceptorToLoopManagement.updateAcceptorToLoop(storesToLoops);
          }
        }
        when 'SYNC_FC_TO_SMARTER' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            Set<Id> eventFCs = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (eventFCs != null && !eventFCs.isEmpty()) {
              ER_SyncStructureWS.alreadyExecutedSync = true;
              APER30_FinancialCenter_Management.doSyncFinancialCentersToSmartER(eventFCs);
            }
          }
        }
        when 'RUN_SYNC_CLIENT_TO_SMARTER' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            Set<Id> eventAccountIds = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            ER_SyncStructureWS.alreadyExecutedSync = true;
            if (eventAccountIds != null && !eventAccountIds.isEmpty())
              APER20_Account_Management.syncClientToSmarter(eventAccountIds);
          }
        }
        when 'RUN_SYNC_OFFLINE_TCS' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            Set<Id> contractsIds = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (contractsIds != null && !contractsIds.isEmpty())
              APER20_Account_Management.syncOfflineTcsToSmarter(contractsIds);
          }
        }
        when 'RUN_SYNC_CONTACTS_TO_SMARTER' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            Set<Id> contactsIds = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (contactsIds != null && !contactsIds.isEmpty())
              APER17_Contact_Management.doSyncContactsToSmartER(contactsIds);
          }
        }
        when 'SMARTER_PUSH_BACK_IDS' {
          if (String.isNotBlank(e.Transaction_Content__c)) {
            Set<Id> fcIds = (Set<Id>) JSON.deserialize(e.Transaction_Content__c, Set<Id>.class);
            if (fcIds != null && !fcIds.isEmpty())
              APER30_FinancialCenter_Management.pushBackLeadConversionIds(fcIds);
          }
        }
        /*when 'MANAGE_ZQUOTE_SYNC_FIELDS' {
                    if(String.isNotBlank(e.Transaction_Content__c)) {
                        System.debug('>>>>> AAZ DistributedTransactionEvtManagement - MANAGE_ZQUOTE_SYNC_FIELDS:'+e.Transaction_Content__c);
                        zqu__Quote__c eventZQuote = ((zqu__Quote__c) JSON.deserialize(e.Transaction_Content__c, zqu__Quote__c.class));
                        if(eventZQuote.Id != null) {
                            ZuoraUtils.updateZuoraAccounts(new List<sObject>{eventZQuote}, null); 
                        }
                    }
                }*/
      }
    }
  }
}