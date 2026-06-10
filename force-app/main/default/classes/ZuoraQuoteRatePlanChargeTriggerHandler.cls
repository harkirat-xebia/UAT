/**
 * @author : AAZ
 * @date : 24/01/2023
 * @desc : ZuoraQuoteRatePlanChargeTriggerHandler
 * @see ZuoraQuoteRatePlanChargeTriggerHandler
 */

public class ZuoraQuoteRatePlanChargeTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ZuoraQuoteRatePlanChargeTrigger')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Update ER_Number_Of_High_Discounts on Quote
    ZuoraQuote_Management_AP01.updateNumberOfHighDiscounts(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Update ER_Number_Of_High_Discounts on Quote
    ZuoraQuote_Management_AP01.updateNumberOfHighDiscounts(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}