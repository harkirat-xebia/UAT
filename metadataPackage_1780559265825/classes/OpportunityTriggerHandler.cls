/**
 * @author : AAM
 * @date : 03/06/2021
 * @desc : OpportunityTriggerHandler
 * @see OpportunityTriggerHandler
 */

 public with sharing class OpportunityTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('OpportunityTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //ALK - Set Opportunity as Smarter Context
    APER04_Opportunity_Management.setOppAsSmartERContext(Trigger.new);

    //ELAK: manage opportunity records before insert
    APER04_Opportunity_Management.manageOppRecordsBeforeInsert((List<Opportunity>) newItems);

    //Set Indexation fields default values
    APER04_Opportunity_Management.setIndexationFields((List<Opportunity>) newItems);

    //CWA: Check if financial approver is needed
    APER04_Opportunity_Management.checkNeedFinancialApprover(Trigger.new);

    //AAZ - Defaulting values
    APER04_Opportunity_Management.opportunityDefaultingValues(Trigger.new);

    //snica Set Indexation fields default values for FI
    APER04_Opportunity_Management.updateIndexationField(Trigger.new);

    //HD - Default autoenrollment opportunities values
    APER04_Opportunity_Management.autoenrollmentDefaultingValues(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Manage Affiliation and Promo Codes
    //APER04_Opportunity_Management.manageDiscountCodes(Trigger.new, null);

    //HD Create OLIs for FI
    APER04_Opportunity_Management.generateOpportunityLineItem(Trigger.new, null);
    //OpportunityManagementWithoutSharing.syncOCRFromOpportunity(Trigger.new);
    //Snehil - Store Role Id on Opportunity
    OpportunityManagementWithoutSharing.storeRoleIdOnOpportunityForVisibility(Trigger.new, null);
    //OpportunityManagementWithoutSharing.addStageErrorOnOpportunity(Trigger.new, null);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Set Opportunity as Smarter Context
    APER04_Opportunity_Management.setOppAsSmartERContext(Trigger.new);

    // Create the Sales Quote and Quote Line Items once the opportunity is approved
    APER04_Opportunity_Management.manageOppRecordsBeforeUpdate(Trigger.new, (Map<Id, Opportunity>) oldItems);

    //Set Indexation fields default values
    APER04_Opportunity_Management.setIndexationFields(Trigger.new);

    //VJO - EKIVITA MPV CHECK
    APER04_Opportunity_Management.checkVatMpvError(Trigger.new);

    //CWA - Calculate Approval Step
    APER04_Opportunity_Management.calculateApprovalSteps(
      (Map<Id, Opportunity>) newItems,
      (Map<Id, Opportunity>) oldItems
    );

    //CWA: Check if financial approver is needed
    APER04_Opportunity_Management.checkNeedFinancialApprover(Trigger.new);

    //AAZ - Defaulting values
    APER04_Opportunity_Management.opportunityDefaultingValues(Trigger.new);

    //snica Set Indexation fields default values for FI
    APER04_Opportunity_Management.updateIndexationField(Trigger.new);

    //HDA setting pricebook on the autoEnrollemnt opportunities
    APER04_Opportunity_Management.autoenrollmentSetPriceBook(Trigger.new, (Map<Id, Opportunity>) oldItems);
    OpportunityManagementWithoutSharing.addErrorOnOpportunity(Trigger.new, (Map<Id, Opportunity>) oldItems);
    OpportunityManagementWithoutSharing.addStageErrorOnOpportunity(Trigger.new, (Map<Id, Opportunity>) oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Manage Affiliation and Promo Codes
    //APER04_Opportunity_Management.manageDiscountCodes(Trigger.new, (Map<Id, Opportunity>) oldItems);

    //Noor - validate PriceBook Based On PromoCode
    APER04_Opportunity_Management.validatePriceBookBasedOnPromoCode(
      (Map<Id, Opportunity>) newItems,
      (Map<Id, Opportunity>) oldItems
    );

    //HD Create OLIs
    APER04_Opportunity_Management.generateOpportunityLineItem(Trigger.new, (Map<Id, Opportunity>) oldItems);

    //snica Translate Payment Terms, Payment Method and Indexation Index after update
    APER11_Quote_Management.getLabelsTranslationsBeforeUpdate(Trigger.new, (Map<Id, Opportunity>) oldItems);
      
    //Snehil - Store Role Id on Opportunity
    OpportunityManagementWithoutSharing.storeRoleIdOnOpportunityForVisibility(Trigger.new, (Map<Id, Opportunity>) oldItems);
    OpportunityManagementWithoutSharing.executeSecondaryApproval((List<Opportunity>) newItems.values(), (Map<Id, Opportunity>) oldItems);
    //OpportunityManagementWithoutSharing.syncOCRFromOpportunity(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}