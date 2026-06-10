/*
----------------------------------------------------------------------
-- - Name          : TRER15_DependentValueBeforeInsert
-- - Author        : VJOY
-- - Description   : Trigger on DependentValue insert (To update hierachical level based on parent level)
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 08-JAN-2020  VJOY                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

trigger TRER15_DependentValueBeforeInsert on ER_DependentValue__c(before insert) {
  if (APER10_User_Management.canTrigger) {
    System.debug('### TRER15_DependentValueBeforeInsert Start');
    APER27_DependentValue_Management.setCategoryLevel(Trigger.new);
    APER27_DependentValue_Management.setOrderCategory(Trigger.new);
    System.debug('###:TRER15_DependentValueBeforeInsert  Finish');
  }

}