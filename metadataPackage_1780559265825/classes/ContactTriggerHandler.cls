/**
 * @author : AAM
 * @date : 26/05/2021
 * @desc : ContactTriggerHandler
 * @see ContactTriggerHandler
 */

 public with sharing class ContactTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ContactTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //AAZ - SmartER - Set Contact SmartER context
    APER17_Contact_Management.setContactAsSmartERContext(Trigger.new);

    //AAZ - Mark Contacts to be synced with Smarter
    APER17_Contact_Management.markContactToBeSyncedWithSmarter(Trigger.new);

    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER17_Contact_Management.updateLastModifiedDateFunctionalUser(Trigger.new);

    //Noor - Update contact country code
    APER17_Contact_Management.initializeFields((List<Contact>) newItems);

    //CWA- Update Inactive Date following the contact Status
    APER17_Contact_Management.updateInactiveDate(Trigger.new, null);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Sync Contacts to EDG v3
    //APER17_Contact_Management.syncContacts(Trigger.new, null); //Commented Snehil 18/09/2024

    //AAZ - Sync SmartER contacts to SmartER client Referential
    //APER17_Contact_Management.syncContactsToSmartER(Trigger.new, null);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - SmartER - Set Contact SmartER context
    APER17_Contact_Management.setContactAsSmartERContext(Trigger.new);

    //AAZ - Mark Contacts to be synced with Smarter
    APER17_Contact_Management.markContactToBeSyncedWithSmarter(Trigger.new);

    //Fill the creation date in OS in the Store level
    APER17_Contact_Management.syncContactFlags(newItems, oldItems);

    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER17_Contact_Management.updateLastModifiedDateFunctionalUser(Trigger.new);

    //CWA- Update Inactive Date following the contact Status
    APER17_Contact_Management.updateInactiveDate(Trigger.new, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Sync Contacts to EDG v3
    //APER17_Contact_Management.syncContacts(Trigger.new, (Map<Id, Contact>) oldItems);//Commented Snehil 18/09/2024

    //AAZ - Sync SmartER contacts to SmartER client Referential
    //APER17_Contact_Management.syncContactsToSmartER(Trigger.new, (Map<Id, Contact>) oldItems);

    //AAZ - Update a Billing Account in Zuora
    APER17_Contact_Management.updateZuoraBillingAccount(Trigger.new, (Map<Id, Contact>) oldItems);

    //KHAD block the desactivation of a primary contact
    APER17_Contact_Management.BlockPrimaryContactDeactivation(newItems, oldItems);

    //AAZ - Get Products Translations
    APER17_Contact_Management.getProductsNameTranslations(Trigger.new, (Map<Id, Contact>) oldItems);
      
    //Snehil - Sync Client Update in NEMO
    //APER17_Contact_Management.syncContactUpdateInNEMO(Trigger.new, (Map<Id, Contact>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    APER17_Contact_Management.preventRestrictedDeletions(oldItems);
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}