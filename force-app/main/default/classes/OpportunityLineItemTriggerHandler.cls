/**
 * Created by khaddouch on 29/04/2021.
 */

public without sharing class OpportunityLineItemTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('OpportunityLineItemTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //Adding new method for restricting the change on oppLineItem field ER_Nb_Beneficiaries__c har
    List<OpportunityLineItem> oliList = (List<OpportunityLineItem>) newItems;
    OpportunityManagementWithoutSharing.validateNbBeneficiaries(oliList);

    //ALK - Check if the solution to be added exists already on an active contract having the same type
    APER04_Opportunity_Management.checkExistingSolutionInActiveContract((List<OpportunityLineItem>) newItems);
    //Noor Update lookup field Solution on Opportunity Line item each time it is created
    APER04_Opportunity_Management.updateSolutionOnOppLineItem((List<OpportunityLineItem>) newItems);
    OpportunityManagementWithoutSharing.preventDMLForFrameworkAgreement( (List<OpportunityLineItem>) newItems, null);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER04_Opportunity_Management.calculateOpportunitySolutions((List<OpportunityLineItem>) newItems.values(), null);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

    //Adding new method for restricting the change on oppLineItem field ER_Nb_Beneficiaries__c
    List<OpportunityLineItem> oliList = (List<OpportunityLineItem>) newItems.values();
    OpportunityManagementWithoutSharing.validateNbBeneficiaries(oliList);

    OpportunityManagementWithoutSharing.preventDMLForFrameworkAgreement( (List<OpportunityLineItem>) newItems.values(), (Map<Id, OpportunityLineItem>) oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Noor - sum up Estimates On Opportunity When Estimate on line item is changedChange
    APER04_Opportunity_Management.sumUpEstimatesOnOpportunityWhenChange(
      (List<OpportunityLineItem>) newItems.values(),
      (Map<Id, OpportunityLineItem>) oldItems
    );
    APER04_Opportunity_Management.calculateOpportunitySolutions(null,  (Map<Id, OpportunityLineItem>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    OpportunityManagementWithoutSharing.preventDMLForFrameworkAgreement(null, (Map<Id, OpportunityLineItem>) oldItems);
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
    APER04_Opportunity_Management.calculateOpportunitySolutions(null, (Map<Id, OpportunityLineItem>) oldItems);

    //Noor - sum up Estimates On Opportunity When Estimate on line item is changedChange
    APER04_Opportunity_Management.sumUpEstimatesOnOpportunityWhenChange(
      (List<OpportunityLineItem>) oldItems.values(),
      null
    );
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}