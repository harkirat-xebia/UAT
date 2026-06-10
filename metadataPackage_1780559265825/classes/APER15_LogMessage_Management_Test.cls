/*
----------------------------------------------------------------------
-- - Name          : APER15_LogMessage_Management_Test
-- - Author        : OLA
-- - Description   : test class for APER15_LogMessage_Management
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Jun-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER15_LogMessage_Management_Test {
  static testMethod void testLogMessage() {
    APER15_LogMessage_Management.logMessage(
      APER15_LogMessage_Management.LogLevel.Debug,
      'APER15_LogMessage_Management_Test',
      'testLogMessage',
      'Just a test',
      true
    );
  }
}