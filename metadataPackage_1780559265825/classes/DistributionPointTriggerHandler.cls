/**
 * Created by davram on 3/22/2021.
 */

public with sharing class DistributionPointTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('DistributionPointTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    try {
      System.debug('Trigger called after insert');
      APER29_DistributionPoint_Management.manageDPLIForNewDistributionPoint(
        (Map<Id, ER_Distribution_Point__c>) Trigger.newMap
      );

      //added By harkirat
      APER29_DistributionPoint_Management.createAcrForDistributionPoints(newItems, null);


      APER24_ContactRole_Management.CreatePrimaryContactRole(Trigger.new);
    } catch (Exception e) {
      Trigger.new[0].adderror(e.getMessage());
    }
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //KHAD Fill the creation date in OS in the Store level
    APER29_DistributionPoint_Management.syncDistributionPointFlags(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('Trigger called after update');

    // added by harkirat
    APER29_DistributionPoint_Management.createAcrForDistributionPoints(newItems, oldItems);


    APER29_DistributionPoint_Management.updatePrimaryContactRole(
      (Map<Id, ER_Distribution_Point__c>) Trigger.newMap,
      (Map<Id, ER_Distribution_Point__c>) Trigger.oldMap
    );
    //KHAD - Sync Stores with EDG v3
    /*APER29_DistributionPoint_Management.syncDistributionPoint(
      Trigger.new,
      (Map<Id, ER_Distribution_Point__c>) oldItems
    );*///commented Snehil 20/09/2024
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}