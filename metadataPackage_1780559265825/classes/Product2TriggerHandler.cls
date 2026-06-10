/**
 * -----------------------------------------------------
 * @author : AAZ
 * @date : 24/06/2021
 * @desc : Product2TriggerHandler
 * @see Product2TriggerHandler
 * -----------------------------------------------------
 */

public with sharing class Product2TriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('Product2TriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //Activate all Zuora products created by Zuora API.
    APER32_Product2_Management.activateZuoraProducts(Trigger.new);

    //Noor populate default values to product from parent based on their type
    APER32_Product2_Management.populateRangeAndDiscountProduct((List<Product2>) newItems);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Zuora Product should be automatically added to Standard PriceBook.
    APER32_Product2_Management.addProductToStandardPriceBook(Trigger.new);

    //Noor update Range And Discount Counter On Service
    APER32_Product2_Management.updateRangeAndDiscountCounterOnService((List<Product2>) newItems.values());
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Activate all Zuora products updated by Zuora API.
    APER32_Product2_Management.activateZuoraProducts(Trigger.new);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Zuora Product should be automatically added to Standard PriceBook.
    APER32_Product2_Management.addProductToStandardPriceBook(Trigger.new);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
    //Noor update Range And Discount Counter On Service
    APER32_Product2_Management.updateRangeAndDiscountCounterOnService((List<Product2>) oldItems.values());
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}