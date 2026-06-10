/**
 * -----------------------------------------------------
 * @author : AAZ
 * @date : 26/04/2021
 * @desc : FinancialCenterTriggerHandler
 * @see FinancialCenterTriggerHandler
 * -----------------------------------------------------
 */

public with sharing class FinancialCenterTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('FinancialCenterTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //ALK - Set FC as Smarter Context
    APER30_FinancialCenter_Management.setFCAsSmartERContext(Trigger.new);

    //KHAD flag the fc to be synced with smarter
    APER30_FinancialCenter_Management.markFinancialCenterToBeSyncedWithSmarter(Trigger.new);

    //AAZ: Zuora use - Set Master FC
    APER30_FinancialCenter_Management.setMaster(Trigger.new);

    //VJB PBI 10658 - Group type management
    APER30_FinancialCenter_Management.manageFinancialCenterInvoicingCenter(Trigger.New);

    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER30_FinancialCenter_Management.updateLastModifiedDateFunctionalUser(Trigger.new);

    //AAZ - Manage Financial Center Addresses
    APER30_FinancialCenter_Management.manageFinancialCenterAddresses(Trigger.new);
    //Noor update Docusign Template Id
    APER30_FinancialCenter_Management.updateDocusignTemplateId((List<ER_Financial_Center__c>) newItems);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Added by harkirat for ACR creation
    APER30_FinancialCenter_Management.createAcrForFinancialCenters(newItems, null);

    //PUSH BACK IDS Send Ids (AccountId, ContactId, OpportunityId, FinancialCenterId,  BillingAccountNumber)
    APER30_FinancialCenter_Management.pushBackSmartERIds(Trigger.new);

    //AAZ - Create a Billing Account for the BUs having Zuora deployed
    APER30_FinancialCenter_Management.createZuoraBillingAccount(Trigger.new);

    //APER24_ContactRole_Management.CreatePrimaryContactRole(Trigger.new);//commented Snehil 20/09/2024

    //Manage FCLI
    APER30_FinancialCenter_Management.manageFCLIForNewFinancialCenter((Map<Id, ER_Financial_Center__c>) newItems);

    // Sync SmartER Financial Center to SmartER client Referential
    APER30_FinancialCenter_Management.syncFinancialCenterToSmartER(Trigger.new, null);

    //Noor - Updates the Master Financial Center field on the related Account records
    APER30_FinancialCenter_Management.setMasterFC_OnAccount((Map<Id, ER_Financial_Center__c>) newItems);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Set FC as Smarter Context
    APER30_FinancialCenter_Management.setFCAsSmartERContext(Trigger.new);

    //KHAD flag the fc to be synced with smarter
    APER30_FinancialCenter_Management.markFinancialCenterToBeSyncedWithSmarter(Trigger.new);

    // Fill the creation date is on field on the financial center level
    APER30_FinancialCenter_Management.syncFinancialCenterFlags(newItems, oldItems);

    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER30_FinancialCenter_Management.updateLastModifiedDateFunctionalUser(Trigger.new);

    //VJO - PBI 10658 ERES - Group type management (Financial center)
    APER30_FinancialCenter_Management.manageFinancialCenterInvoicingCenter(Trigger.new);

    //AAZ - Manage Financial Center Addresses
    APER30_FinancialCenter_Management.manageFinancialCenterAddresses(Trigger.new);

    //Noor update Docusign Template Id
    APER30_FinancialCenter_Management.updateDocusignTemplateId((List<ER_Financial_Center__c>) newItems.values());
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

    //Added by harkirat
    APER30_FinancialCenter_Management.createAcrForFinancialCenters(newItems, oldItems);

    //Manage Financial Center Stores
    APER30_FinancialCenter_Management.manageFinancialCenterStores(newItems, oldItems);

    //AAZ - Create a Billing Account for the BUs having Zuora deployed
    //APER30_FinancialCenter_Management.createZuoraBillingAccount(Trigger.new);

    //AAZ - Update a Billing Account in Zuora
    APER30_FinancialCenter_Management.updateZuoraBillingAccount(
      Trigger.new,
      (Map<Id, ER_Financial_Center__c>) oldItems
    );

    //Sync new Financial center with EDG if the account ER_Creation_date_in_OS__c not null
    //APER30_FinancialCenter_Management.syncFinancialcenters(Trigger.new, (Map<Id, ER_Financial_Center__c>) oldItems);// commented Snehil 19/09/2024

    //APER24_ContactRole_Management.updateContactRoleUpdate(Trigger.new, (Map<Id, ER_Financial_Center__c>) oldItems);////commented Snehil 20/09/2024

    //KHAD - Sync SmartER Financial Center to SmartER client Referential
    APER30_FinancialCenter_Management.syncFinancialCenterToSmartER(
      Trigger.new,
      (Map<Id, ER_Financial_Center__c>) oldItems
    );

    //Noor - Generate Bank Account form Docusign Form
    APER30_FinancialCenter_Management.generateBankAccount(
      (Map<Id, ER_Financial_Center__c>) newItems,
      (Map<Id, ER_Financial_Center__c>) oldItems
    );

    //AAZ - Check whether a Bank Account/Iban is valid and create the Mandat in Cegedim
    APER30_FinancialCenter_Management.validateIban(Trigger.new, (Map<Id, ER_Financial_Center__c>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}