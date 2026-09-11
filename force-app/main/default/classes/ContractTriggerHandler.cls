/**
 * Created by khaddouch on 06/05/2021.
 */

public with sharing class ContractTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ContractTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    APER12_Contract_Management.setContractName(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //method added by harkirat for acr
    APER12_Contract_Management.createAcrForContracts(newItems, null);

    //ALK 31/05/2021 - Link the new contract to the quote signed (docusign pdf) document.
    APER12_Contract_Management.linkContractToSignedDocument((Map<Id, Contract>) Trigger.newMap);

    //AAZ 29/08/2022 - activate smarter contracts created via Quote API
    APER12_Contract_Management.activateContract(Trigger.new);

    //CWA 22/09/2022- Task creation on opportunity
    APER12_Contract_Management.contractTaskCreation(Trigger.new);

    //AAZ 17/01/2023 - map some ZQuote fields to the linked Contract
    APER12_Contract_Management.mapFieldsFromZQuote(Trigger.new);
      
    OpportunityManagementWithoutSharing.createCCRForContractFromOCR(Trigger.new);

    //NEW: SME Platform Engagement Logic (for contracts created as Activated)
    //APER12_Contract_Management.createSMEPlatformEngagement((Map<Id, Contract>) newItems, null);
    //System.debug('Sme Trigger called');
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER12_Contract_Management.handleStatusTransitions(
      (Map<Id, Contract>) newItems,
      (Map<Id, Contract>) oldItems
    );
    APER12_Contract_Management.validateIfContractDateOverlap(
      (Map<Id, Contract>) newItems,
      (Map<Id, Contract>) oldItems
    );
    // for marking the field as true
    APER12_Contract_Management.markNemoSyncPending(
        (Map<Id, Contract>) newItems,
        (Map<Id, Contract>) oldItems
    );

  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Added by harkirat
    APER12_Contract_Management.createAcrForContracts(newItems, oldItems);

    // Create tasks
    APER12_Contract_Management.createTasksAfterUpdate((Map<Id, Contract>) newItems, (Map<Id, Contract>) oldItems);

    APER12_Contract_Management.createZuoraSubscription((Map<Id, Contract>) newItems, (Map<Id, Contract>) oldItems);

    APER12_Contract_Management.endZuoraSubscription((Map<Id, Contract>) newItems, (Map<Id, Contract>) oldItems);

    APER12_Contract_Management.activateAccount((Map<Id, Contract>) newItems, (Map<Id, Contract>) oldItems);

    //Added by harkirat for nemo sync 
    APER12_Contract_Management.syncContractToNemo((Map<Id, Contract>) newItems, (Map<Id, Contract>) oldItems);

    APER20_Account_Management.deactivateAccountsStatusForTerminatedContracts(((Map<Id, Contract>) newItems).keySet());

    APER39_DiscountCode_Mangement.deactivateAffiliationCodesForTerminatedContracts(
      ((Map<Id, Contract>) newItems).keySet()
    );

    //AAZ - Mark Objects to be synced with Smarter
    APER12_Contract_Management.markObjectsToBeSyncedWithSmarter(Trigger.new, (Map<Id, Contract>) oldItems);

    //Noor - Sync Account to Smarter when contract is activated
    APER12_Contract_Management.syncAccountToSmarter((Map<Id, Contract>) newItems, (Map<Id, Contract>) oldItems);

    //NEW: SME Platform Engagement Logic
    APER12_Contract_Management.createSMEPlatformEngagement((Map<Id, Contract>) newItems, (Map<Id, Contract>) oldItems);
    //System.debug('Sme Trigger called update');
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    APER12_Contract_Management.processContractBeforeDelete((Map<Id, Contract>) oldItems);
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
  
}