/**
----------------------------------------------------------------------
-- Name          : DependentValueTriggerHandler
-- Author        : Noor
-- Description   : Trigger Handler for DependentValue

-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 22/09/2022   Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class DependentValueTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('DependentValueTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    if (UtilsBypass.canTrigger('setCategoryLevel'))
      APER27_DependentValue_Management.setCategoryLevel((List<ER_DependentValue__c>) newItems);
    if (UtilsBypass.canTrigger('setOrderCategory'))
      APER27_DependentValue_Management.setOrderCategory((List<ER_DependentValue__c>) newItems);
    APER27_DependentValue_Management.updateMaxLevelOnCategories(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    if (UtilsBypass.canTrigger('reCalculateCategoryLevelOnChildRecords'))
      APER27_DependentValue_Management.reCalculateCategoryLevelOnChildRecords(
        (Map<Id, ER_DependentValue__c>) newItems,
        (Map<Id, ER_DependentValue__c>) oldItems
      );

    if (UtilsBypass.canTrigger('processOrderNumberOnCategories'))
      APER27_DependentValue_Management.processOrderNumberOnCategories(
        (Map<Id, ER_DependentValue__c>) newItems,
        (Map<Id, ER_DependentValue__c>) oldItems
      );

    APER27_DependentValue_Management.updateMaxLevelOnCategories(Trigger.new);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    if (UtilsBypass.canTrigger('updateChildDependentLevel'))
      APER27_DependentValue_Management.updateChildDependentLevel(
        (Map<Id, ER_DependentValue__c>) newItems,
        (Map<Id, ER_DependentValue__c>) oldItems
      );
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    if (UtilsBypass.canTrigger('checkChildCategoryBeforeDelete'))
      APER27_DependentValue_Management.checkChildCategoryBeforeDelete((List<ER_DependentValue__c>) oldItems.values());
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}