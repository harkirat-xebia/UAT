/**
 * Created by davram on 3/18/2021.
 */

public with sharing class DeliverSiteTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('DeliverSiteTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    try {
      System.debug('trigger called after insert');
      APER28_DeliverySite_Management.manageDSLIForNewDeliverySite((Map<Id, ER_Delivery_Site__c>) Trigger.newMap);
        System.debug('trigger called after manageDSLIForNewDeliverySite');

      //Method by harkirat
      APER28_DeliverySite_Management.createAcrForDeliverySites(newItems, null);

      //APER24_ContactRole_Management.CreatePrimaryContactRole(Trigger.new);//commented Snehil 19/09/2024
        System.debug('trigger called after CreatePrimaryContactRole');
    } catch (Exception e) {
        System.debug('trigger msg'+e.getMessage());
        System.debug('trigger line'+e.getLineNumber());
      Trigger.new[0].adderror(e.getMessage());
    }
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //KHAD Fill the creation date in OS in the Store level
    APER28_DeliverySite_Management.syncDeliverySiteFlags(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('trigger called after update');
  //Added by harkirat

  APER28_DeliverySite_Management.createAcrForDeliverySites(newItems, oldItems);

    APER28_DeliverySite_Management.updatePrimaryContactRole(
      (Map<Id, ER_Delivery_Site__c>) Trigger.newMap,
      (Map<Id, ER_Delivery_Site__c>) Trigger.oldMap
    );
    //KHAD - Sync Stores with EDG v3
    //APER28_DeliverySite_Management.syncDeliverySite(Trigger.new, (Map<Id, ER_Delivery_Site__c>) oldItems);//commented Snehil 20/09/2024
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}