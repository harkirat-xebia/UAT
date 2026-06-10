/**
 * @author: AAZ
 * @date: 11/03/2022
 * @desc: DocugenQuoteStoreAcceptorTriggerHandler
 * @see: DocugenQuoteStoreAcceptorTriggerHandler
 */

public with sharing class DocugenQuoteStoreAcceptorTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('DocugenQuoteStoreAcceptorTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Update Number Of Stores in Quote_Store_Acceptor for Quotes
    Docugen_QuoteStoreAcceptor_Management.updateQuoteNbOfStores(Trigger.new, false);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
    //AAZ - Update Number Of Stores in Quote_Store_Acceptor for Quotes
    Docugen_QuoteStoreAcceptor_Management.updateQuoteNbOfStores(Trigger.old, true);
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}