/**
 * @author : ALK
 * @date : 12/11/2021
 * @desc : LeadTriggerHandler
 * @see LeadTriggerHandler
 */

public with sharing class LeadTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('LeadTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
    //ALK - Set Lead as Smarter Context
    APER18_Lead_Management.setLeadAsSmartERContext(Trigger.new);

    //ALK - Manage Lead rating
    APER18_Lead_Management.manageRating(Trigger.new);

    //ELAK - Manage Merchant Lead created By Client Sales
    APER18_Lead_Management.manageMerchantLeadCreationByClientSales(Trigger.new);

    //AAZ - SMARTER - Check if is there an existing lead having the same email address and same CRN
    APER18_Lead_Management.checkExistingLeads(Trigger.new);

    //CWA- For ERFI update the field Initial Product Interest
    APER18_Lead_Management.UpdateProductOfInterest(Trigger.new);

    //Noor - Manage Number of Employees
    APER18_Lead_Management.manageNumberOfEmployees((List<Lead>) newItems);

    //Harkirat - Flag leads that should amend an activated contract instead of converting
    APER18_Lead_Management.setAmendableContractFlag((List<Lead>) newItems, null);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ELAK- Enforce assignment rule when leads are bulk imported
    APER18_Lead_Management.manageLeadAssignRule(Trigger.new);

    //ALK - SmartER Convert all leads having the flag ER_To_Be_Converted__c enabled
    APER18_Lead_Management.convertLeads(Trigger.new);

    //Noor - each time a Lead is created route Lead to Genesys and create a task
    APER18_Lead_Management.routeLeadToGenesys((Map<Id, Lead>) newItems, (Map<Id, Lead>) oldItems);

    // Auto-populate legal fields from Belfirst when enterprise number is set but fields are empty
    Set<Id> belfirstLeadIds = new Set<Id>();
    for (Lead lead : (List<Lead>) newItems.values()) {
      if (APBE01_LeadBelfirst.isEligible(lead)) belfirstLeadIds.add(lead.Id);
    }
    //System.debug('APBE01 afterInsert: eligible lead IDs = ' + belfirstLeadIds);
    if (!belfirstLeadIds.isEmpty()) APBE01_LeadBelfirst.autoPopulateIfEmpty(belfirstLeadIds);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Set Lead as Smarter Context
    APER18_Lead_Management.setLeadAsSmartERContext(Trigger.new);

    //ELAK - Manage rating for changed leadSources before updating leads
    APER18_Lead_Management.manageRatingChangedLS(Trigger.new, oldItems);

    //AAZ - SmartER - Link a lead to an existing contact
    APER18_Lead_Management.linkLeadToExistingContact(Trigger.new);

    //Noor - Manage Number of Employees
    APER18_Lead_Management.manageNumberOfEmployees((List<Lead>) newItems.values());

    // Dinesh - COUL-4301 - Update autoenrollment Ext Ref to avoid having duplicates for incoming ones
    APER18_Lead_Management.updateAutoenrollmentExtId(Trigger.new);

    //Harkirat - Flag leads that should amend an activated contract instead of converting
    APER18_Lead_Management.setAmendableContractFlag((List<Lead>) newItems.values(), oldItems);
  
    //harkirat - Stamp qualification end when the lead is converted or rejected
    APER18_Lead_Management.stampQualificationEnd(Trigger.new);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    // Auto-populate from Belfirst when enterprise number is newly set on an existing lead
    Set<Id> belfirstLeadIds = new Set<Id>();
    for (Lead newLead : (List<Lead>) newItems.values()) {
      Lead oldLead = (Lead) oldItems.get(newLead.Id);
      Boolean regNumJustSet = String.isBlank(oldLead.ER_Registration_Number__c)
        && String.isNotBlank(newLead.ER_Registration_Number__c);
      Boolean vatBeJustSet = newLead.ER_BUPicklist__c == 'BE'
        && String.isBlank(newLead.ER_Registration_Number__c)
        && String.isBlank(oldLead.ER_VAT_Number__c)
        && String.isNotBlank(newLead.ER_VAT_Number__c)
        && newLead.ER_VAT_Number__c.toUpperCase().startsWith('BE');
      if ((regNumJustSet || vatBeJustSet) && APBE01_LeadBelfirst.isEligible(newLead)) belfirstLeadIds.add(newLead.Id);
    }
    //System.debug('APBE01 afterUpdate: eligible lead IDs = ' + belfirstLeadIds);
    if (!belfirstLeadIds.isEmpty()) APBE01_LeadBelfirst.autoPopulateIfEmpty(belfirstLeadIds);

    APER18_Lead_Management.updateCompetitors(Trigger.new);

    APER03_Lead_CreateFinancialCenter.createFinancialCenter(Trigger.new);

    //ELAK- Create unmatched transaction tasks
    APER18_Lead_Management.createUnmatchedTrTasks(Trigger.new, oldItems);

    //VJOY - Assign a promo code to the linked opportunity
    APER18_Lead_Management.assignPromoCodeToOpp(Trigger.new);

    //ALK - Convert all leads having the flag ER_To_Be_Converted__c enabled
    APER18_Lead_Management.convertLeads(Trigger.new);

    //Noor - When a Lead is converted or rejected or owner is change from Queue to User disconnect the related task in Genesys
    APER18_Lead_Management.disconnectRelatedTaskOnClosedLead((Map<Id, Lead>) newItems, (Map<Id, Lead>) oldItems);

    //Noor -route converted opportunity  to Genesys and create a task
    //APER18_Lead_Management.routeConvertedOpportunityToGenesys((Map<Id,Lead>) newItems,(Map<Id,Lead>)oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}