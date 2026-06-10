/*
----------------------------------------------------------------------
-- - Name          : APER15_LogMessage_Management
-- - Author        : OLA
-- - Description   : Log Message Management, This class is used to group all the functionnality linked to the object Log Message
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Jun-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class APER15_LogMessage_Management {
  /*------------------------------------------------------------
	Description:   Enumeration of supported log levels
	------------------------------------------------------------*/
  public enum LogLevel {
    Debug,
    Info,
    Error,
    Warning
  }

  public static ER_Log_Message__c logMessage(
    LogLevel logLevel,
    String source,
    String sourceFunction,
    String logMessage,
    Boolean executeDML
  ) {
    ER_Log_Message__c log = new ER_Log_Message__c();

    log.ER_Source__c = source;
    log.ER_Source_Function__c = sourceFunction;
    log.ER_Message__c = logMessage;
    log.ER_Debug_Level__c = logLevel.name();

    if (executeDML)
      insert log;

    return log;
  }
}