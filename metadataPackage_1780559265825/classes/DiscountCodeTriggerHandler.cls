/**
 * @author : VJOY
 * @date : 27/03/2022
 * @desc : DiscountCodeTriggerHandler
 * @see DiscountCodeTriggerHandler
 */

public with sharing class DiscountCodeTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('DiscountCodeTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    APER39_DiscountCode_Mangement.checkUnicityForDiscountCodes(Trigger.New);
    APER39_DiscountCode_Mangement.checkForDiscountCodesContract(Trigger.New);
    APER39_DiscountCode_Mangement.setDiscountCodeStatus(Trigger.New);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER39_DiscountCode_Mangement.insertPbeForDiscountCodes(Trigger.New);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER39_DiscountCode_Mangement.checkUnicityForDiscountCodes(Trigger.New);
    APER39_DiscountCode_Mangement.checkForDiscountCodesContractUpdate(
      Trigger.New,
      (Map<Id, ER_Promo_Code__c>) oldItems
    );
    APER39_DiscountCode_Mangement.setDiscountCodeStatus(Trigger.New);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    APER39_DiscountCode_Mangement.removeDiscountCodesFromOpenOpportunities(
      Trigger.new,
      (Map<Id, ER_Promo_Code__c>) oldItems
    );
    APER39_DiscountCode_Mangement.updateDatesOnPricebookEnteries(
      Trigger.new,
      (Map<Id, ER_Promo_Code__c>) oldItems
    );
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}