/**
 * Created by khaddouch on 06/05/2021.
 */

 public with sharing class QuoteTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('QuoteTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    APER11_Quote_Management.setQuoteName(Trigger.new);        
    
    //SNICA - Translate Payment Terms, Payment Method and Indexation Index
		APER11_Quote_Management.getLabelsTranslationsFromScheme(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Create Docugen records to be used for the contract template
    APER11_Quote_Management.createDocugenQuoteStoreAcceptor(Trigger.new);
    APER11_Quote_Management.createSendQuoteTask(Trigger.new);
    APER11_Quote_Management.createAnonymizedId(Trigger.new);
    APER11_Quote_Management.updateOppStageFromQuotes(Trigger.new, null);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Check if it is the last quote on the opportunity that has been accepted and display error msg
    //When quote is denied check if contract can be deleted and display error msg
    if (APER10_User_Management.canTrigger)
      APER11_Quote_Management.checkRecentQuote((Map<Id, Quote>) newItems, (Map<Id, Quote>) oldItems);

    //Create contract when quote is accepted and associate new contract to quote
    if (APER10_User_Management.canTrigger)
      APER11_Quote_Management.createContract((Map<Id, Quote>) newItems, (Map<Id, Quote>) oldItems);

    //Remove contract when quote is denied
    if (APER10_User_Management.canTrigger)
      APER11_Quote_Management.removeContractFromQuote((Map<Id, Quote>) newItems, (Map<Id, Quote>) oldItems);

    //Noor update Docusign Template Id
    if (UtilsBypass.canTrigger('updateDocusignTemplateId'))
      APER11_Quote_Management.updateDocusignTemplateId((List<Quote>) newItems.values(), (Map<Id, Quote>) oldItems);

      //SNICA - Translate Payment Terms, Payment Method and Indexation Index before update
      APER11_Quote_Management.getLabelsTranslations(Trigger.new, (Map<Id, Quote>) oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    if (UserInfo.getUserType() != Constants.AUTOMATED_PROCESS) {
      //AAM To exclude auto enrollment context
      //AAZ - Purge Docugen records
      APER11_Quote_Management.purgeDocugenQuoteStoreAcceptor(Trigger.new);
	  APER11_Quote_Management.completeSendQuoteTasks(Trigger.new, (Map<Id, Quote>) oldItems);
      //AAZ - Get Product Translations
      APER11_Quote_Management.getProductsNameTranslations(Trigger.new, (Map<Id, Quote>) oldItems);
      APER11_Quote_Management.handleOpportunityStageAccStatus(Trigger.new, (Map<Id, Quote>) oldItems);
      APER11_Quote_Management.updateOppStageFromQuotes(Trigger.new, (Map<Id, Quote>) oldItems);
    }
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}