/*
----------------------------------------------------------------------
-- - Name          : APER45_ErrorLog_Management
-- - Author        : Harkirat Singh
-- - Description   : Central failsafe error logging API backed by ER_Error_Log__c.
--                   All new development should call this class from catch blocks
--                   instead of System.debug or silently swallowing exceptions.
--                   log()/logException() write directly (subject to rollback);
--                   logDurable() publishes ER_Error_Log_Event__e so the log
--                   survives a transaction rollback. This class never throws.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2026     Harkirat Singh       1.0         Initial version
----------------------------------------------------------------------
*/
public without sharing class APER45_ErrorLog_Management {
  public enum LogLevel {
    Fatal,
    Error,
    Warning,
    Info,
    Debug
  }

  private static final Integer MAX_TEXT_255 = 255;
  private static final Integer MAX_TRANSACTION_ID = 64;
  private static final Integer MAX_QUIDDITY = 40;
  private static final Integer MAX_LONG_TEXT = 131072;
  private static final Integer MAX_MEDIUM_TEXT = 32768;
  private static final Integer MAX_RELATED_RECORD_ID = 18;

  private static Boolean isSandboxCache;

  /*------------------------------------------------------------
	Description:   Fluent wrapper describing a single error to log
	------------------------------------------------------------*/
  public class ErrorLogEntry {
    private LogLevel level = LogLevel.Error;
    private String sourceClass;
    private String sourceMethod;
    private String sourceType = 'Apex Class';
    private String exceptionType;
    private String message;
    private String stackTrace;
    private String cause;
    private Integer lineNumber;
    private Id relatedRecordId;
    private String relatedObject;
    private String payload;
    private String businessUnit;

    public ErrorLogEntry withLogLevel(LogLevel value) {
      this.level = value;
      return this;
    }

    public ErrorLogEntry withSourceClass(String value) {
      this.sourceClass = value;
      return this;
    }

    public ErrorLogEntry withSourceMethod(String value) {
      this.sourceMethod = value;
      return this;
    }

    public ErrorLogEntry withSourceType(String value) {
      this.sourceType = value;
      return this;
    }

    public ErrorLogEntry withMessage(String value) {
      this.message = value;
      return this;
    }

    public ErrorLogEntry withStackTrace(String value) {
      this.stackTrace = value;
      return this;
    }

    public ErrorLogEntry withRelatedRecordId(Id value) {
      this.relatedRecordId = value;
      return this;
    }

    public ErrorLogEntry withRelatedObject(String value) {
      this.relatedObject = value;
      return this;
    }

    public ErrorLogEntry withPayload(String value) {
      this.payload = value;
      return this;
    }

    public ErrorLogEntry withBusinessUnit(String value) {
      this.businessUnit = value;
      return this;
    }

    /*  Populates exception-derived fields (type, message, stack trace, line, cause chain) */
    public ErrorLogEntry withException(Exception e) {
      if (e == null) {
        return this;
      }
      this.exceptionType = e.getTypeName();
      this.message = e.getMessage();
      this.stackTrace = e.getStackTraceString();
      this.lineNumber = e.getLineNumber();
      this.cause = describeCause(e.getCause());
      return this;
    }

    private String describeCause(Exception causeEx) {
      if (causeEx == null) {
        return null;
      }
      return causeEx.getTypeName() + ': ' + causeEx.getMessage();
    }
  }

  /*------------------------------------------------------------
	Description:   Shared runtime context captured once per log entry
	------------------------------------------------------------*/
  private class LogContext {
    String transactionId;
    String quiddity;
    String orgId;
    String orgDomainUrl;
    Datetime occurredAt;
    Boolean isSandbox;
    String limitsSnapshot;
  }

  /*=================================================================
    PUBLIC ENTRY POINTS
  =================================================================*/

  public static ER_Error_Log__c logException(Exception e, String sourceClass, String sourceMethod) {
    return logException(e, sourceClass, sourceMethod, null);
  }

  public static ER_Error_Log__c logException(Exception e, String sourceClass, String sourceMethod, Id relatedRecordId) {
    ErrorLogEntry entry = new ErrorLogEntry()
      .withLogLevel(LogLevel.Error)
      .withSourceClass(sourceClass)
      .withSourceMethod(sourceMethod)
      .withRelatedRecordId(relatedRecordId)
      .withException(e);
    return log(entry);
  }

  public static ER_Error_Log__c logError(String sourceClass, String sourceMethod, String message) {
    ErrorLogEntry entry = new ErrorLogEntry()
      .withLogLevel(LogLevel.Error)
      .withSourceClass(sourceClass)
      .withSourceMethod(sourceMethod)
      .withMessage(message);
    return log(entry);
  }

  public static ER_Error_Log__c log(ErrorLogEntry entry) {
    List<ER_Error_Log__c> results = log(new List<ErrorLogEntry>{ entry });
    return results.isEmpty() ? null : results[0];
  }

  /*  Bulk-safe; a failure building or inserting one entry never blocks the others */
  public static List<ER_Error_Log__c> log(List<ErrorLogEntry> entries) {
    List<ER_Error_Log__c> records = new List<ER_Error_Log__c>();
    if (entries == null) {
      return records;
    }

    for (ErrorLogEntry entry : entries) {
      if (entry == null) {
        continue;
      }
      try {
        records.add(buildRecord(entry));
      } catch (Exception buildEx) {
        System.debug(LoggingLevel.ERROR, 'APER45_ErrorLog_Management.log - failed to build record: ' + buildEx.getMessage());
      }
    }

    if (!records.isEmpty()) {
      try {
        List<Database.SaveResult> saveResults = Database.insert(records, false);
        reportInsertFailures(saveResults, records);
      } catch (Exception insertEx) {
        System.debug(LoggingLevel.ERROR, 'APER45_ErrorLog_Management.log - failed to insert records: ' + insertEx.getMessage());
      }
    }

    return records;
  }

  /*  Row-level failures don't throw under allOrNone=false, so they'd otherwise vanish silently.
      Surface them in the debug log and make one attempt to capture them via the durable/event
      path, which is a different write mechanism than the direct insert that just failed. */
  private static void reportInsertFailures(List<Database.SaveResult> saveResults, List<ER_Error_Log__c> records) {
    List<String> failureDetails = new List<String>();
    for (Integer i = 0; i < saveResults.size(); i++) {
      if (!saveResults[i].isSuccess()) {
        failureDetails.add('record ' + i + ': ' + describeErrors(saveResults[i].getErrors()));
      }
    }
    if (failureDetails.isEmpty()) {
      return;
    }

    String summary = failureDetails.size() + ' of ' + saveResults.size() + ' error-log records failed to insert: ' + String.join(failureDetails, ' | ');
    System.debug(LoggingLevel.ERROR, 'APER45_ErrorLog_Management.log - ' + summary);

    logDurable(
      new ErrorLogEntry()
        .withLogLevel(LogLevel.Fatal)
        .withSourceClass('APER45_ErrorLog_Management')
        .withSourceMethod('log')
        .withSourceType('Apex Class')
        .withMessage(summary)
    );
  }

  private static String describeErrors(List<Database.Error> errors) {
    List<String> parts = new List<String>();
    for (Database.Error err : errors) {
      String fieldSuffix = err.getFields().isEmpty() ? '' : ' [' + String.join(err.getFields(), ',') + ']';
      parts.add(err.getStatusCode() + ': ' + err.getMessage() + fieldSuffix);
    }
    return String.join(parts, '; ');
  }

  /*  Publishes a platform event so the log survives a rollback of the current transaction */
  public static void logDurable(ErrorLogEntry entry) {
    if (entry == null) {
      return;
    }
    try {
      Database.SaveResult result = EventBus.publish(buildEvent(entry));
      if (!result.isSuccess()) {
        System.debug(LoggingLevel.ERROR, 'APER45_ErrorLog_Management.logDurable - failed to publish event: ' + describeErrors(result.getErrors()));
      }
    } catch (Exception publishEx) {
      System.debug(LoggingLevel.ERROR, 'APER45_ErrorLog_Management.logDurable - failed to publish event: ' + publishEx.getMessage());
    }
  }

  /*=================================================================
    FLOW SUPPORT
  =================================================================*/
  public class InvocableLogRequest {
    @InvocableVariable(label='Log Level' description='Fatal, Error, Warning, Info or Debug' required=false)
    public String logLevel;

    @InvocableVariable(label='Source Flow Name' required=true)
    public String sourceClass;

    @InvocableVariable(label='Source Element' required=false)
    public String sourceMethod;

    @InvocableVariable(label='Message' required=true)
    public String message;

    @InvocableVariable(label='Related Record Id' required=false)
    public Id relatedRecordId;

    @InvocableVariable(label='Business Unit' required=false)
    public String businessUnit;
  }

  @InvocableMethod(label='Log Error' description='Creates an ER_Error_Log__c record for a Flow fault or business error' category='Error Logging')
  public static void logFromFlow(List<InvocableLogRequest> requests) {
    if (requests == null) {
      return;
    }
    List<ErrorLogEntry> entries = new List<ErrorLogEntry>();
    for (InvocableLogRequest request : requests) {
      if (request == null) {
        continue;
      }
      entries.add(
        new ErrorLogEntry()
          .withLogLevel(resolveLogLevel(request.logLevel))
          .withSourceClass(request.sourceClass)
          .withSourceMethod(request.sourceMethod)
          .withSourceType('Flow')
          .withMessage(request.message)
          .withRelatedRecordId(request.relatedRecordId)
          .withBusinessUnit(request.businessUnit)
      );
    }
    log(entries);
  }

  /*=================================================================
    LWC / AURA SUPPORT
  =================================================================*/
  /*  Accepts discrete scalar params rather than a raw payload to avoid deserializing untrusted input */
  @AuraEnabled(cacheable=false)
  public static void logFromClient(String sourceComponent, String message, String stackTrace, Id relatedRecordId) {
    log(
      new ErrorLogEntry()
        .withLogLevel(LogLevel.Error)
        .withSourceClass(sourceComponent)
        .withSourceType('LWC')
        .withMessage(message)
        .withStackTrace(stackTrace)
        .withRelatedRecordId(relatedRecordId)
    );
  }

  /*=================================================================
    RECORD / EVENT BUILDERS
  =================================================================*/
  private static ER_Error_Log__c buildRecord(ErrorLogEntry entry) {
    LogContext ctx = captureContext();

    ER_Error_Log__c logRecord = new ER_Error_Log__c();
    logRecord.ER_Log_Level__c = entry.level != null ? entry.level.name() : LogLevel.Error.name();
    logRecord.ER_Source_Class__c = truncate(entry.sourceClass, MAX_TEXT_255);
    logRecord.ER_Source_Method__c = truncate(entry.sourceMethod, MAX_TEXT_255);
    logRecord.ER_Source_Type__c = String.isNotBlank(entry.sourceType) ? entry.sourceType : 'Apex Class';
    logRecord.ER_Exception_Type__c = truncate(entry.exceptionType, MAX_TEXT_255);
    logRecord.ER_Message__c = truncate(entry.message, MAX_LONG_TEXT);
    logRecord.ER_Stack_Trace__c = truncate(entry.stackTrace, MAX_LONG_TEXT);
    logRecord.ER_Cause__c = truncate(entry.cause, MAX_MEDIUM_TEXT);
    logRecord.ER_Line_Number__c = entry.lineNumber;
    logRecord.ER_Related_Record_Id__c = truncate(entry.relatedRecordId, MAX_RELATED_RECORD_ID);
    logRecord.ER_Related_Object__c = truncate(
      String.isNotBlank(entry.relatedObject) ? entry.relatedObject : resolveSObjectType(entry.relatedRecordId),
      MAX_TEXT_255
    );
    logRecord.ER_Payload__c = truncate(entry.payload, MAX_LONG_TEXT);
    logRecord.ER_Business_Unit__c = entry.businessUnit;
    logRecord.ER_Running_User__c = UserInfo.getUserId();
    logRecord.ER_Org_Id__c = ctx.orgId;
    logRecord.ER_Org_Domain_URL__c = truncate(ctx.orgDomainUrl, MAX_TEXT_255);
    logRecord.ER_Transaction_Id__c = truncate(ctx.transactionId, MAX_TRANSACTION_ID);
    logRecord.ER_Quiddity__c = truncate(ctx.quiddity, MAX_QUIDDITY);
    logRecord.ER_Occurred_At__c = ctx.occurredAt;
    logRecord.ER_Is_Sandbox__c = ctx.isSandbox;
    logRecord.ER_Limits_Snapshot__c = ctx.limitsSnapshot;
    logRecord.ER_Status__c = 'New';

    if (entry.relatedRecordId != null && String.isNotBlank(logRecord.ER_Org_Domain_URL__c)) {
      logRecord.ER_Record_URL__c = logRecord.ER_Org_Domain_URL__c + '/' + entry.relatedRecordId;
    }

    logRecord.ER_Fingerprint__c = buildFingerprint(
      logRecord.ER_Source_Class__c,
      logRecord.ER_Source_Method__c,
      logRecord.ER_Exception_Type__c,
      logRecord.ER_Message__c
    );

    return logRecord;
  }

  private static ER_Error_Log_Event__e buildEvent(ErrorLogEntry entry) {
    LogContext ctx = captureContext();

    ER_Error_Log_Event__e evt = new ER_Error_Log_Event__e();
    evt.ER_Log_Level__c = entry.level != null ? entry.level.name() : LogLevel.Error.name();
    evt.ER_Source_Class__c = truncate(entry.sourceClass, MAX_TEXT_255);
    evt.ER_Source_Method__c = truncate(entry.sourceMethod, MAX_TEXT_255);
    evt.ER_Source_Type__c = String.isNotBlank(entry.sourceType) ? entry.sourceType : 'Apex Class';
    evt.ER_Exception_Type__c = truncate(entry.exceptionType, MAX_TEXT_255);
    evt.ER_Message__c = truncate(entry.message, MAX_LONG_TEXT);
    evt.ER_Stack_Trace__c = truncate(entry.stackTrace, MAX_LONG_TEXT);
    evt.ER_Cause__c = truncate(entry.cause, MAX_MEDIUM_TEXT);
    evt.ER_Line_Number__c = entry.lineNumber;
    evt.ER_Related_Record_Id__c = truncate(entry.relatedRecordId, MAX_RELATED_RECORD_ID);
    evt.ER_Related_Object__c = truncate(
      String.isNotBlank(entry.relatedObject) ? entry.relatedObject : resolveSObjectType(entry.relatedRecordId),
      MAX_TEXT_255
    );
    evt.ER_Payload__c = truncate(entry.payload, MAX_LONG_TEXT);
    evt.ER_Business_Unit__c = entry.businessUnit;
    evt.ER_Running_User_Id__c = UserInfo.getUserId();
    evt.ER_Org_Id__c = ctx.orgId;
    evt.ER_Org_Domain_URL__c = truncate(ctx.orgDomainUrl, MAX_TEXT_255);
    evt.ER_Transaction_Id__c = truncate(ctx.transactionId, MAX_TRANSACTION_ID);
    evt.ER_Quiddity__c = truncate(ctx.quiddity, MAX_QUIDDITY);
    evt.ER_Occurred_At__c = ctx.occurredAt;
    evt.ER_Is_Sandbox__c = ctx.isSandbox;
    evt.ER_Limits_Snapshot__c = ctx.limitsSnapshot;

    if (entry.relatedRecordId != null && String.isNotBlank(evt.ER_Org_Domain_URL__c)) {
      evt.ER_Record_URL__c = evt.ER_Org_Domain_URL__c + '/' + entry.relatedRecordId;
    }

    return evt;
  }

  /*=================================================================
    HELPERS
  =================================================================*/
  private static LogContext captureContext() {
    LogContext ctx = new LogContext();
    ctx.orgId = UserInfo.getOrganizationId();
    ctx.occurredAt = System.now();
    ctx.isSandbox = getIsSandbox();
    ctx.limitsSnapshot = buildLimitsSnapshot();

    try {
      ctx.transactionId = Request.getCurrent().getRequestId();
      ctx.quiddity = String.valueOf(Request.getCurrent().getQuiddity());
    } catch (Exception reqEx) {
      // Request context unavailable in this execution context (e.g. some test/async paths)
    }

    try {
      ctx.orgDomainUrl = Url.getOrgDomainUrl() != null ? Url.getOrgDomainUrl().toExternalForm() : null;
    } catch (Exception urlEx) {
      // Domain URL unavailable in this execution context
    }

    return ctx;
  }

  private static Boolean getIsSandbox() {
    if (isSandboxCache == null) {
      try {
        isSandboxCache = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
      } catch (Exception orgEx) {
        isSandboxCache = false;
      }
    }
    return isSandboxCache;
  }

  private static String buildLimitsSnapshot() {
    return 'SOQL '
      + Limits.getQueries()
      + '/'
      + Limits.getLimitQueries()
      + ', DML '
      + Limits.getDmlStatements()
      + '/'
      + Limits.getLimitDmlStatements()
      + ', CPU '
      + Limits.getCpuTime()
      + '/'
      + Limits.getLimitCpuTime()
      + 'ms, Heap '
      + Limits.getHeapSize()
      + '/'
      + Limits.getLimitHeapSize()
      + ' bytes, DmlRows '
      + Limits.getDmlRows()
      + '/'
      + Limits.getLimitDmlRows();
  }

  private static String buildFingerprint(String sourceClass, String sourceMethod, String exceptionType, String message) {
    try {
      String raw = String.join(
        new List<String>{
          String.isBlank(sourceClass) ? '' : sourceClass,
          String.isBlank(sourceMethod) ? '' : sourceMethod,
          String.isBlank(exceptionType) ? '' : exceptionType,
          String.isBlank(message) ? '' : message
        },
        '|'
      );
      return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(raw)));
    } catch (Exception fingerprintEx) {
      return null;
    }
  }

  private static String resolveSObjectType(Id recordId) {
    if (recordId == null) {
      return null;
    }
    try {
      return recordId.getSObjectType().getDescribe().getName();
    } catch (Exception describeEx) {
      return null;
    }
  }

  private static LogLevel resolveLogLevel(String value) {
    if (String.isBlank(value)) {
      return LogLevel.Error;
    }
    for (LogLevel level : LogLevel.values()) {
      if (level.name().equalsIgnoreCase(value)) {
        return level;
      }
    }
    return LogLevel.Error;
  }

  private static String truncate(String value, Integer maxLength) {
    if (value == null) {
      return null;
    }
    return value.length() > maxLength ? value.substring(0, maxLength) : value;
  }

  private static String truncate(Id value, Integer maxLength) {
    return value == null ? null : truncate(String.valueOf(value), maxLength);
  }
}
