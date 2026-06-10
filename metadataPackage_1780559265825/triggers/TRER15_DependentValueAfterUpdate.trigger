/*
----------------------------------------------------------------------
-- - Name          : TRER15_DependentValueAfterUpdate
-- - Author        : VJOY
-- - Description   : Trigger on DependentValue update (To re-calculate child categories hierachical level based on parent level)
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 08-JAN-2020  VJOY                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

trigger TRER15_DependentValueAfterUpdate on ER_DependentValue__c(after update) {
  if (APER10_User_Management.canTrigger) {
    Map<Id, ER_DependentValue__c> dependentValueNewMap = Trigger.newMap;
    Map<Id, ER_DependentValue__c> dependentValueOldMap = Trigger.oldMap;

    Set<ER_DependentValue__c> dependentRecSet = new Set<ER_DependentValue__c>();

    System.debug('### TRER15_DependentValueAfterUpdate Start');
    for (ER_DependentValue__c dependentVal : dependentValueNewMap.values()) {
      if (
        dependentVal.Parent_Dependent_Value__c != dependentValueOldMap.get(dependentVal.Id).Parent_Dependent_Value__c
      ) {
        dependentRecSet.add(dependentVal);
      }
    }
    if (dependentRecSet.size() > 0) {
      APER27_DependentValue_Management.updateChildDependentLevel(dependentRecSet);
    }
    System.debug('###:TRER15_DependentValueAfterUpdate Finish');
  }

}