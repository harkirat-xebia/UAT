/**
 * @author : KHAD
 * @date : 02/07/2021
 * @desc : StoreCategoryTriggerHandler
 * @see StoreCategoryTriggerHandler
 */

public with sharing class StoreCategoryTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('StoreCategoryTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //KHAD - Sync Store Category with EDG v3
    APER14_Store_Management.syncStoreCategory(Trigger.new, null);

    //Noor - update Main Category on Store
    APER14_Store_Management.updateStoreMainCategory((List<ER_StoreCategory__c>) newItems.values());
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Fill the creation date in OS in the Store Category level
    APER14_Store_Management.syncStoreCategoryFlags(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //KHAD - Sync Store Category with EDG v3
    APER14_Store_Management.syncStoreCategory(Trigger.new, (Map<Id, ER_StoreCategory__c>) oldItems);

    //Noor - update Main Category on Store
    APER14_Store_Management.updateStoreMainCategory((List<ER_StoreCategory__c>) newItems.values());
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}