/**
 * @author Noor
 * @date 25/01/2022.
 * @description QuoteLineItemTriggerHandler
 */

public with sharing class QuoteLineItemTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('QuoteLineTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Noor - update field Quote.ER_DocuGen_Solution__c with quotelineItems solutions
    APER36_QuoteLineItem_Management.updateSolutionCodeOnQuote((List<QuoteLineItem>) newItems.values());

    //snica - update field Quote.ER_Main_Solution__c with quotelineItems solution
    APER36_QuoteLineItem_Management.updateMainSolutionOnQuote((List<QuoteLineItem>) newItems.values());

    //AAZ - Get Products Translations
    APER36_QuoteLineItem_Management.getProductsNameTranslations(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //snica - update field Quote.ER_Main_Solution__c with quotelineItems solution
    APER36_QuoteLineItem_Management.updateMainSolutionOnQuote((List<QuoteLineItem>) newItems.values());

    //AAZ - Get Products Translations
    APER36_QuoteLineItem_Management.getProductsNameTranslations(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    //Block the Quote Line Item Deletion
    APER36_QuoteLineItem_Management.blockQuoteLineItemDeletion((List<QuoteLineItem>) oldItems.values());
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
    //Noor - update field Quote.ER_DocuGen_Solution__c with quotelineItems solutions
    APER36_QuoteLineItem_Management.updateSolutionCodeOnQuote((List<QuoteLineItem>) oldItems.values());
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}