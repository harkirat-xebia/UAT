/**
 * @author : ALK
 * @date : 01/03/2021
 * @desc : SolutionLineItemTriggerHandler
 * @see SolutionLineItemTriggerHandler
 */

 public with sharing class SolutionLineItemTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('SolutionLineItemTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //HD - activate autoenrollment SLIs
    APER30_AutoEnrollment_Management.activateAutoenrollmentSLIs(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    // ALK - Manage Store Status
    APER14_Store_Management.manageStoreStatus(Trigger.new);
    //KHAD Evaluate object sync on creation
    //APER14_Store_Management.manageSliSync(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    // ELAK - Manage Store Status
    //APER14_Store_Management.manageStoreStatus(trigger.new);
    //ELAK - Manage Solution line item status
    APER14_Store_Management.updateSLIStatus(newItems, oldItems);
    //Fill the creation date in OS in the Store level
    APER14_Store_Management.syncSLIFlags(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    // ALK - Manage Store Status
    APER14_Store_Management.manageStoreStatus(Trigger.new);
    // KHAD - Method to sync updated line item status
    APER14_Store_Management.syncUpdateLineItems(Trigger.new, (Map<Id, ER_Solution_Line_Item__c>) oldItems);
    // ELAK - Manage SLI
    APER14_Store_Management.manageChildSLI(newItems, oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}