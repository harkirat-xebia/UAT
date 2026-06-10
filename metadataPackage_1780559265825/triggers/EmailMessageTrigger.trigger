/*
----------------------------------------------------------------------
-- - Name          : EmailMessageTrigger
-- - Author        : Noor
-- - Description   : Handler for all EmailMessage Trigger
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 12/10/2021   Noor                1.0         Trigger Handler Rework.
---------------------------------------------------------------------------------------
*/
trigger EmailMessageTrigger on EmailMessage(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new EmailMessageTriggerHandler());
}