/*
----------------------------------------------------------------------
-- - Name          : TRER15_DependentValueBeforeDelete
-- - Author        : VJOY
-- - Description   : Trigger on DependentValue delete (To block delete if lookup parentrecord is used in another child category)
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 08-JAN-2020  VJOY                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
trigger TRER15_DependentValueBeforeDelete on ER_DependentValue__c(before delete) {
  if (APER10_User_Management.canTrigger) {
    System.debug('### TRER15_DependentValueBeforeDelete Start');
    APER27_DependentValue_Management.checkChildCategoryBeforeDelete(Trigger.old);
    System.debug('###:TRER15_DependentValueBeforeDelete Finish');
  }

}