/**
 * Created by davram on 3/31/2021.
 */

public with sharing class StoreTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('StoreTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    APER14_Store_Management.manageStoreWithPaymentSites(Trigger.new);

    //ALK - Create Aggregator merchant for Store Aggregator
    APER14_Store_Management.createAggregatorMerchant(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER14_Store_Management.handleStoreContactRoleStoreToLoop(
      (Map<Id, ER_Store__c>) Trigger.newMap,
      (Map<Id, ER_Store__c>) Trigger.oldMap,
      true,
      false
    );

    //AAZ - Create Docugen records to be used for the contract template
    APER14_Store_Management.createDocugenQuoteStoreAcceptor(Trigger.new);

    //ALK - Create Merchant Aggregator Partner Accounts
    APER14_Store_Management.createAccountPartnerStoreAggregators(Trigger.new);

    //ALK - Create Virtual Web Auth Acceptor
    APER14_Store_Management.createWebAuthAccepterStoreAggregator(Trigger.new, (Map<Id, ER_Store__c>) Trigger.oldMap);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER14_Store_Management.enableDisableStore(
      (Map<Id, ER_Store__c>) Trigger.newMap,
      (Map<Id, ER_Store__c>) Trigger.oldMap
    );

    APER14_Store_Management.checkDigitalStoreStatusChange(
      (Map<Id, ER_Store__c>) Trigger.newMap,
      (Map<Id, ER_Store__c>) Trigger.oldMap
    );

    //Fill the creation date in OS in the Store level
    APER14_Store_Management.syncStoreFlags(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER14_Store_Management.handleStoreContactRoleStoreToLoop(
      (Map<Id, ER_Store__c>) Trigger.newMap,
      (Map<Id, ER_Store__c>) Trigger.oldMap,
      false,
      true
    );
    //APER14_Store_Management.checkDigitalStoreStatusChange((Map<Id,ER_Store__c>)trigger.newMap,(Map<Id,ER_Store__c>)trigger.oldMap);

    //ALK - Recalculate Account Partners once an aggregator store has been updated
    APER14_Store_Management.recalculateAccountPartnerAggregator(Trigger.new, (Map<Id, ER_Store__c>) Trigger.oldMap);

    //ALK - Create Virtual Web Auth Acceptor
    APER14_Store_Management.createWebAuthAccepterStoreAggregator(Trigger.new, (Map<Id, ER_Store__c>) Trigger.oldMap);

    //ALK - Sync Stores with EDG v3
    APER14_Store_Management.syncStores(Trigger.new, (Map<Id, ER_Store__c>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}