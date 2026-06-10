/**
----------------------------------------------------------------------
-- Name          : DependentValueTrigger
-- Author        : Noor
-- Description   : Trigger on DependentValue
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 22/09/2022   Noor                 1.0         Convert existing trigger to trigger handler framework
---------------------------------------------------------------------------------------
*/
trigger DependentValueTrigger on ER_DependentValue__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new DependentValueTriggerHandler());
}