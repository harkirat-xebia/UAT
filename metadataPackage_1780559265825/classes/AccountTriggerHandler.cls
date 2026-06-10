/**
 * @author : AAM
 * @date : 27/05/2021
 * @desc : AccountTriggerHandler
 * @see AccountTriggerHandler
 */

 public with sharing class AccountTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('AccountTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //AAZ - SmartER Set SmartER context on the contact
    APER20_Account_Management.setAccountAsSmartERContext(Trigger.new);

    //Noor update shipping address (rewrite trigger)
    APER20_Account_Management.updateShippingAddress((List<Account>) newItems);

    //Noor update recordType and Status for merchant (rewrite trigger)
    APER20_Account_Management.manageRTMerchant(newItems);

    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER20_Account_Management.updateLastModifiedDateFunctionalUser(Trigger.new);

    //ALK - Medallia populate Individual Invitation Trigger Date
    //APER20_Account_Management.populateIndividualInvitationTriggerDate(Trigger.new);

    //AAZ - Set The Last Customer Number
    APER20_Account_Management.setLastCustomerNumberSequence(Trigger.new);

    //AAZ - Account Defaulting values
    APER20_Account_Management.defaultAccountValues(Trigger.new);

    //Noor - update Client Priority
    APER20_Account_Management.updateClientPriority(Trigger.new, null);
    
    //Ticket 2326 added by harkirat
    APER20_Account_Management.validateHierarchyOwnerOnInsert((List<Account>) newItems);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
      BE_General_Cond_Without_Sharing_Ctrl.handleEmployeeCountRollup( new Map<Id, Account>(), (Map<Id, Account>) Trigger.newMap, (List<Account>) Trigger.new, new List<Account>(), true, false, false, false );
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - SmartER Set SmartER context on the contact
    APER20_Account_Management.setAccountAsSmartERContext(Trigger.new);

    // KHAD Fill the creation date in OS in the account level
    APER20_Account_Management.syncAccountFlags(newItems, oldItems);

    //Noor update shipping address (rewrite trigger)
    APER20_Account_Management.updateShippingAddress((List<Account>) newItems.values());

    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER20_Account_Management.updateLastModifiedDateFunctionalUser(Trigger.new);

    //ALK - Medallia populate Individual Invitation Trigger Date
    //APER20_Account_Management.populateIndividualInvitationTriggerDate(Trigger.new);

    //AAZ - Set The Last Customer Number
    APER20_Account_Management.setLastCustomerNumberSequence(Trigger.new);

    //ALK - Update Smarter Sync fields
    APER20_Account_Management.updateSmarterSyncFields(Trigger.new, (Map<Id, Account>) oldItems);

    //Noor - update Client Priority
    APER20_Account_Management.updateClientPriority(Trigger.new, (Map<Id, Account>) oldItems);

    //ALK - [Smarter] Override the account Source and Subsource by the ones coming from the lead conversion
    APER20_Account_Management.updateAccountSource(Trigger.new, (Map<Id, Account>) oldItems);
      
    //Ticket 2326 added by harkirat
    APER20_Account_Management.validateHierarchyAndOwnerGovernance( (Map<Id, Account>) newItems, (Map<Id, Account>) oldItems);
 
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Noor sync address from Account to Contacts when billing address is changed (rewrite trigger)
    APER20_Account_Management.syncAddressToContacts((List<Account>) newItems.values(), (Map<Id, Account>) oldItems);

    //ALK - Sync Accounts with EDG v3 if acc.ER_Creation_date_in_OS__c not null
    //APER20_Account_Management.syncAccounts(Trigger.new, (Map<Id, Account>) oldItems); //commented Snehil 18/09/2024

    //AAZ - Update a Billing Account in Zuora
    APER20_Account_Management.updateZuoraBillingAccount(Trigger.new, (Map<Id, Account>) oldItems);

    //ALK - Medallia
    //APER20_Account_Management.sendInvitationWhenFirstVisitChanged(Trigger.new, (Map<Id, Account>) oldItems);
    //Noor - sync account to Smarter
    APER20_Account_Management.syncClientToSmarterWhenUpdate(Trigger.new, (Map<Id, Account>) oldItems);

    //KHAD - Send Financial centers and contact to be synced with smarter
    APER20_Account_Management.syncSmarterContactsAndFinancialCenters(Trigger.new, (Map<Id, Account>) oldItems);

    //AAZ - Mark Financial Center and Contact as synced when the parent account is updated with Customer Id
    APER20_Account_Management.markFCandContactAsSynced(Trigger.new, (Map<Id, Account>) oldItems);

    //AAZ - Sync offline TCs
    APER20_Account_Management.syncOfflineTCs(Trigger.new, (Map<Id, Account>) oldItems);
      
    BE_General_Cond_Without_Sharing_Ctrl.handleEmployeeCountRollup( (Map<Id, Account>) Trigger.oldMap, (Map<Id, Account>) Trigger.newMap, (List<Account>) Trigger.new, (List<Account>) Trigger.old, false, true, false, false );
      
    //Snehil - Sync Client in NEMO
    //APER20_Account_Management.syncAccountUpdateInNEMO(Trigger.new, (Map<Id, Account>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
      BE_General_Cond_Without_Sharing_Ctrl.handleEmployeeCountRollup( (Map<Id, Account>) Trigger.oldMap, new Map<Id, Account>(), new List<Account>(), (List<Account>) Trigger.old, false, false, true, false );
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
      BE_General_Cond_Without_Sharing_Ctrl.handleEmployeeCountRollup( new Map<Id, Account>(), (Map<Id, Account>) Trigger.newMap, (List<Account>) Trigger.new, new List<Account>(), false, false, false, true );
  }
}