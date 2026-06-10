/*
----------------------------------------------------------------------
-- - Name          : TRER15_DependentValueBeforeUpdate
-- - Author        : VJOY
-- - Description   : Trigger on DependentValue update (To re-calculate hierachical level based on parent level)
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 08-JAN-2020  VJOY                 1.0         Initial version
-- 28-JAN-2020  VJOY                 1.1         Order Processing
---------------------------------------------------------------------------------------
*/

trigger TRER15_DependentValueBeforeUpdate on ER_DependentValue__c(before update) {
  if (APER10_User_Management.canTrigger) {
    Map<Id, ER_DependentValue__c> dependentValueNewMap = Trigger.newMap;
    Map<Id, ER_DependentValue__c> dependentValueOldMap = Trigger.oldMap;

    Set<ER_DependentValue__c> dependentRecSet = new Set<ER_DependentValue__c>();
    Set<ER_DependentValue__c> dependentRecOrderChangedSet = new Set<ER_DependentValue__c>();

    System.debug('### TRER15_DependentValueBeforeUpdate Start');
    for (ER_DependentValue__c dependentVal : dependentValueNewMap.values()) {
      if (
        dependentVal.Parent_Dependent_Value__c != dependentValueOldMap.get(dependentVal.Id).Parent_Dependent_Value__c
      ) {
        dependentRecSet.add(dependentVal);
      }
      if (
        (dependentVal.ER_Ordering__c != dependentValueOldMap.get(dependentVal.Id).ER_Ordering__c) ||
        (dependentVal.ER_Ordering__c == null)
      ) {
        if (APER27_DependentValue_Management.firstRun) {
          dependentRecOrderChangedSet.add(dependentVal);
          APER27_DependentValue_Management.firstRun = false;
        }
      }
    }
    if (dependentRecSet.size() > 0) {
      APER27_DependentValue_Management.reCalculateCategoryLevelOnChildRecords(dependentRecSet);
    }
    //if order is changed or set to null, process new order number
    if (dependentRecOrderChangedSet.size() > 0) {
      APER27_DependentValue_Management.processOrderNumberOnCategories(
        dependentRecOrderChangedSet,
        dependentValueOldMap
      );
    }
    System.debug('###:TRER15_DependentValueBeforeUpdate  Finish');
  }

}