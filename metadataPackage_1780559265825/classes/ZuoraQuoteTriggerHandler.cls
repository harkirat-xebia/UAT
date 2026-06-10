/**
 * @author : AAZ
 * @date : 31/05/2021
 * @desc : ZuoraQuoteTriggerHandler
 * @see ZuoraQuoteTriggerHandler
 */

public with sharing class ZuoraQuoteTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ZuoraQuoteTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Update Quote Status to Draft
    if (!System.isFuture() && !System.isBatch() && !System.isQueueable() && !System.isScheduled())
      ZuoraQuote_Management_AP01.updateStatutAsync(Trigger.newMap.keySet());
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Noor - check if quote has RatePlans when status is changed to accepted
    if (UtilsBypass.canTrigger('checkIfQuoteHasRatePlans'))
      ZuoraQuote_Management_AP01.checkIfQuoteHasRatePlans(
        (Map<Id, zqu__Quote__c>) newItems,
        (Map<Id, zqu__Quote__c>) oldItems
      );

    //AAZ - Update the agreement date after accepting the quote
    ZuoraQuote_Management_AP01.updateTCsAgreementDate(Trigger.new);

    //AAZ - Default ZQuote values
    ZuoraQuote_Management_AP01.zQuoteDefaultingValues(Trigger.new, (Map<Id, zqu__Quote__c>) oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Create Salesforce Contracts
    ZuoraQuote_Management_AP01.createSFContract(oldItems, newItems);

    //Noor - alignQuoteAmendmentDate
    if (UtilsBypass.canTrigger('alignQuoteAmendmentDate'))
      ZuoraQuote_Management_AP01.alignQuoteAmendmentDate(
        (Map<Id, zqu__Quote__c>) oldItems,
        (Map<Id, zqu__Quote__c>) newItems
      );

    //AAZ - Approve any change on the ZQuote for PaymentTerm, PaymentMethod and SubscriptionTerm
    ZuoraQuote_Management_AP01.approveChange(Trigger.new, (Map<Id, zqu__Quote__c>) oldItems);

    //AAZ - Update the Zuora Approval Status to be used later in the other transaction to unlock the ZQuote record
    ZuoraQuote_Management_AP01.updateZuoraApprovalStatus(Trigger.new, (Map<Id, zqu__Quote__c>) oldItems);

    //AAZ - Align PaymentTerm, PaymentMethod and SubscriptionTerm (Opp/BA/Zquote)
    ZuoraQuote_Management_AP01.syncFieldsOppBaZquote(Trigger.new, (Map<Id, zqu__Quote__c>) oldItems);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    if (UtilsBypass.canTrigger('blockZQuoteDeletion'))
      ZuoraQuote_Management_AP01.blockZQuoteDeletion(oldItems.values());
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}