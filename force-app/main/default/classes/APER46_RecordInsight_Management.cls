/*
----------------------------------------------------------------------
-- - Name          : APER46_RecordInsight_Management
-- - Author        : Harkirat Singh
-- - Description   : Controller for the generic erRecordInsights LWC. Reads
--                   CMER04_Record_Insight_Config__mdt rows for whichever object
--                   the component sits on and returns two kinds of insight:
--                     Field_Check      - is the configured field populated?
--                     Duplicate_Lookup - does another object already hold a
--                                        record with the same field value?
--                   Bad configuration is skipped, never fatal: a record page
--                   must not break because a field was renamed or deleted.
--
--                   Runs without sharing so a duplicate check still reports a
--                   match the running user cannot see through sharing rules -
--                   knowing the record exists is the point of the check. Field
--                   level security is still honoured: every configured field is
--                   gated through isAccessible() before it reaches a query.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2026     Harkirat Singh       1.0         Initial version
----------------------------------------------------------------------
*/
public without sharing class APER46_RecordInsight_Management {
  private static final String TYPE_FIELD_CHECK = 'Field_Check';
  private static final String TYPE_DUPLICATE_LOOKUP = 'Duplicate_Lookup';
  private static final String TYPE_RELATED_RECORD_CHECK = 'Related_Record_Check';

  // harkirat - anything else, blank included, keeps the original exact comparison
  private static final String MATCH_MODE_CONTAINS = 'Contains';

  /*  Explicit status rather than leaving the component to infer meaning from the type.
      The polarity genuinely inverts between types - a duplicate found is bad, a related
      record found is good - and inferring that client side is how colours end up wrong. */
  private static final String STATUS_OK = 'Ok';
  private static final String STATUS_MISSING = 'Missing';
  private static final String STATUS_ATTENTION = 'Attention';

  // harkirat - the only action type that needs a server side eligibility check today
  private static final String ACTION_AMEND_AND_CONVERT = 'Amend_And_Convert';

  private static final String CATEGORY_REQUIRED = 'Required';
  private static final String CATEGORY_WARNING = 'Warning';
  private static final String DEFAULT_DISPLAY_FIELD = 'Name';
  private static final Integer MAX_DISPLAY_VALUE = 255;

  /*  One more than the number of matches we render, so the LWC can say "and more" */
  private static final Integer MATCH_QUERY_LIMIT = 6;

  /*  Every API name coming out of configuration is checked against this before it is
      allowed near a dynamic query. Rejects quotes, spaces, commas, parentheses and
      dots - which also rules out relationship paths, unsupported in this version. */
  private static final Pattern SAFE_API_NAME = Pattern.compile('^[A-Za-z0-9_]{1,80}$');

  /*  Test seam: custom metadata rows cannot be inserted by DML, but they can be built
      in memory. Tests assign this so loadConfig() short-circuits before the SOQL. */
  @TestVisible
  private static List<CMER04_Record_Insight_Config__mdt> configOverride;

  /*=================================================================
    WRAPPERS
  =================================================================*/

  public class InsightResult {
    @AuraEnabled
    public String objectApiName { get; set; }
    @AuraEnabled
    public Boolean hasConfig { get; set; }
    @AuraEnabled
    public Integer missingRequiredCount { get; set; }
    @AuraEnabled
    public List<InsightItem> fields { get; set; }
    @AuraEnabled
    public List<InsightMessage> messages { get; set; }

    public InsightResult() {
      this.hasConfig = false;
      this.missingRequiredCount = 0;
      this.fields = new List<InsightItem>();
      this.messages = new List<InsightMessage>();
    }
  }

  public class InsightItem {
    @AuraEnabled
    public String key { get; set; }
    @AuraEnabled
    public String fieldApiName { get; set; }
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String displayValue { get; set; }
    @AuraEnabled
    public String category { get; set; }
    @AuraEnabled
    public String insightType { get; set; }
    @AuraEnabled
    public Boolean isFilled { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String message { get; set; }
    @AuraEnabled
    public String actionLabel { get; set; }
    @AuraEnabled
    public String actionType { get; set; }
    @AuraEnabled
    public String actionButtonLabel { get; set; }
    @AuraEnabled
    public List<InsightMatch> matches { get; set; }

    public InsightItem() {
      this.isFilled = false;
      this.status = STATUS_MISSING;
      this.matches = new List<InsightMatch>();
    }
  }

  public class InsightMatch {
    @AuraEnabled
    public String recordId { get; set; }
    @AuraEnabled
    public String displayLabel { get; set; }
    // harkirat - action state is per match, eligibility differs between two contracts on the same row
    @AuraEnabled
    public Boolean canAct { get; set; }
    @AuraEnabled
    public String blockedReason { get; set; }

    public InsightMatch() {
      this.canAct = false;
    }
  }

  public class InsightMessage {
    @AuraEnabled
    public String key { get; set; }
    @AuraEnabled
    public String category { get; set; }
    @AuraEnabled
    public String message { get; set; }
  }

  /*=================================================================
    ENTRY POINT
  =================================================================*/

  /*  The object name is resolved from the record Id server-side and never accepted
      from the client, so the caller cannot influence any FROM clause. */
  @AuraEnabled(cacheable=true)
  public static InsightResult getInsights(Id recordId) {
    InsightResult result = new InsightResult();
    if (recordId == null) {
      return result;
    }

    try {
      Schema.DescribeSObjectResult hostDescribe = recordId.getSObjectType().getDescribe();
      String objectApiName = hostDescribe.getName();
      result.objectApiName = objectApiName;

      List<CMER04_Record_Insight_Config__mdt> configs = loadConfig(objectApiName);
      if (configs.isEmpty()) {
        return result;
      }
      result.hasConfig = true;

      Map<String, Schema.SObjectField> hostFields = hostDescribe.fields.getMap();

      /*  Classify once, preserving configured order. A related record check needs
          nothing off the host record - it matches on the record's own Id - so it must
          not be mistaken for a message row just because its field is blank. */
      List<CMER04_Record_Insight_Config__mdt> itemRows = new List<CMER04_Record_Insight_Config__mdt>();
      Set<String> fieldsToQuery = new Set<String>();

      for (CMER04_Record_Insight_Config__mdt config : configs) {
        if (TYPE_RELATED_RECORD_CHECK.equals(config.ER_Insight_Type__c)) {
          if (!registerCondition(config, hostFields, fieldsToQuery)) {
            continue;
          }
          itemRows.add(config);
          continue;
        }

        if (isMessageRow(config)) {
          result.messages.add(buildMessage(config));
          continue;
        }

        if (!registerCondition(config, hostFields, fieldsToQuery)) {
          continue;
        }

        Schema.DescribeFieldResult dfr = resolveField(hostFields, config.ER_Field_API_Name__c);
        if (dfr == null) {
          /*  Field renamed, deleted, or not readable by this user - skip the row
              rather than letting one bad config blank the whole component. */
          continue;
        }
        itemRows.add(config);
        fieldsToQuery.add(dfr.getName());

        /*  A Duplicate_Lookup row may narrow itself using a value read off the host
            record - pull that field into the same query rather than a second one. */
        if (TYPE_DUPLICATE_LOOKUP.equals(config.ER_Insight_Type__c) && String.isNotBlank(config.ER_Dynamic_Filter_Source_Field__c)) {
          Schema.DescribeFieldResult dynamicSourceDfr = resolveField(hostFields, config.ER_Dynamic_Filter_Source_Field__c);
          if (dynamicSourceDfr != null) {
            fieldsToQuery.add(dynamicSourceDfr.getName());
          }
        }
      }

      if (itemRows.isEmpty()) {
        return result;
      }

      /*  Skipped entirely when only related record checks are configured. */
      SObject record = fieldsToQuery.isEmpty() ? null : queryHostRecord(objectApiName, fieldsToQuery, recordId);

      for (CMER04_Record_Insight_Config__mdt config : itemRows) {
        if (!conditionMet(config, hostFields, record)) {
          continue;
        }

        InsightItem item;

        if (TYPE_RELATED_RECORD_CHECK.equals(config.ER_Insight_Type__c)) {
          item = buildRelatedItem(config, recordId);
        } else {
          if (record == null) {
            continue;
          }
          Schema.DescribeFieldResult dfr = resolveField(hostFields, config.ER_Field_API_Name__c);
          Object value = record.get(dfr.getName());
          item = TYPE_DUPLICATE_LOOKUP.equals(config.ER_Insight_Type__c)
            ? buildLookupItem(config, dfr, value, recordId, hostFields, record)
            : buildFieldItem(config, dfr, value);
        }

        if (item == null) {
          continue;
        }
        result.fields.add(item);

        /*  Only Missing counts. A duplicate found is Attention, not a gap to fill. */
        if (CATEGORY_REQUIRED.equals(item.category) && STATUS_MISSING.equals(item.status)) {
          result.missingRequiredCount++;
        }
      }

      return result;
    } catch (Exception e) {
      /*  Deliberately not routed through APER45_ErrorLog_Management: a cacheable
          method cannot perform DML or publish a platform event, so logging here
          would throw a second, more confusing exception on top of the first. */
      //System.debug(LoggingLevel.ERROR, '>>>>> APER46 - getInsights failed: ' + e.getTypeName() + ': ' + e.getMessage());

      /*  setMessage as well as the constructor: without it the client receives
          "Script-thrown exception" and the real cause - a limit, a bad field - is lost. */
      AuraHandledException surfaced = new AuraHandledException(e.getMessage());
      surfaced.setMessage(e.getMessage());
      throw surfaced;
    }
  }

  /*=================================================================
    CONFIGURATION
  =================================================================*/

  private static List<CMER04_Record_Insight_Config__mdt> loadConfig(String objectApiName) {
    if (configOverride != null) {
      return dedupe(configOverride);
    }

    /*  Admin-owned configuration rather than user data, so no user-mode enforcement
        here. A security review will otherwise flag this line as a false positive. */
    List<CMER04_Record_Insight_Config__mdt> configs = [
      SELECT
        DeveloperName,
        ER_Object_API_Name__c,
        ER_Insight_Type__c,
        ER_Field_API_Name__c,
        ER_Lookup_Object__c,
        ER_Lookup_Field__c,
        ER_Lookup_Display_Field__c,
        ER_Filter_Field__c,
        ER_Filter_Value__c,
        ER_Dynamic_Filter_Field__c,
        ER_Dynamic_Filter_Source_Field__c,
        ER_Dynamic_Filter_Value_Map__c,
        ER_Dynamic_Filter_Match_Mode__c,
        ER_Condition_Field__c,
        ER_Condition_Value__c,
        ER_Action_Label__c,
        ER_Action_Type__c,
        ER_Action_Button_Label__c,
        ER_Category__c,
        ER_Display_Order__c,
        ER_Display_Label__c,
        ER_Message__c
      FROM CMER04_Record_Insight_Config__mdt
      WHERE ER_Object_API_Name__c = :objectApiName AND ER_Active__c = TRUE
      ORDER BY ER_Display_Order__c NULLS LAST, ER_Field_API_Name__c
    ];
    return dedupe(configs);
  }

  /*  Custom metadata cannot enforce a composite unique key, so two rows for the same
      object/field/type would render the same insight twice. */
  private static List<CMER04_Record_Insight_Config__mdt> dedupe(List<CMER04_Record_Insight_Config__mdt> configs) {
    List<CMER04_Record_Insight_Config__mdt> unique = new List<CMER04_Record_Insight_Config__mdt>();
    Set<String> seen = new Set<String>();

    for (CMER04_Record_Insight_Config__mdt config : configs) {
      String signature =
        String.valueOf(config.ER_Insight_Type__c) +
        '|' +
        String.valueOf(config.ER_Field_API_Name__c) +
        '|' +
        String.valueOf(config.ER_Lookup_Object__c) +
        '|' +
        String.valueOf(config.ER_Filter_Value__c) +
        '|' +
        String.valueOf(config.ER_Condition_Field__c) +
        '|' +
        String.valueOf(config.ER_Condition_Value__c) +
        '|' +
        String.valueOf(config.ER_Message__c) +
        '|' +
        String.valueOf(config.ER_Action_Type__c);
      if (seen.add(signature)) {
        unique.add(config);
      }
    }
    return unique;
  }

  /*  A row with no field to evaluate is pure text for the Warnings / Information section */
  private static Boolean isMessageRow(CMER04_Record_Insight_Config__mdt config) {
    return String.isBlank(config.ER_Field_API_Name__c) && String.isNotBlank(config.ER_Message__c);
  }

  private static InsightMessage buildMessage(CMER04_Record_Insight_Config__mdt config) {
    InsightMessage msg = new InsightMessage();
    msg.key = config.DeveloperName;
    msg.category = config.ER_Category__c;
    msg.message = config.ER_Message__c;
    return msg;
  }

  /*  Resolves and registers a row's condition field for the upcoming host query.
      Returns false when a condition is configured but its field cannot be resolved -
      the row is skipped outright rather than guessing whether it applies. Returns
      true (nothing to register) when no condition is configured, unchanged from
      before this field existed. */
  @TestVisible
  private static Boolean registerCondition(
    CMER04_Record_Insight_Config__mdt config,
    Map<String, Schema.SObjectField> hostFields,
    Set<String> fieldsToQuery
  ) {
    if (String.isBlank(config.ER_Condition_Field__c)) {
      return true;
    }
    Schema.DescribeFieldResult conditionDfr = resolveField(hostFields, config.ER_Condition_Field__c);
    if (conditionDfr == null) {
      return false;
    }
    fieldsToQuery.add(conditionDfr.getName());
    return true;
  }

  /*  Gates whether a row applies to THIS host record at all - e.g. an RCS Number
      check that only matters for Luxembourg leads. A row with no condition
      configured always applies. Comparison is case-insensitive since picklist
      API values and free text are both plausible here. */
  @TestVisible
  private static Boolean conditionMet(
    CMER04_Record_Insight_Config__mdt config,
    Map<String, Schema.SObjectField> hostFields,
    SObject record
  ) {
    if (String.isBlank(config.ER_Condition_Field__c)) {
      return true;
    }
    if (record == null) {
      return false;
    }
    Schema.DescribeFieldResult conditionDfr = resolveField(hostFields, config.ER_Condition_Field__c);
    if (conditionDfr == null) {
      return false;
    }
    Object actual = record.get(conditionDfr.getName());
    return actual != null &&
      config.ER_Condition_Value__c != null &&
      String.valueOf(actual).equalsIgnoreCase(config.ER_Condition_Value__c);
  }

  /*=================================================================
    VALIDATION
  =================================================================*/

  /*  The four gates every configured API name passes before reaching a query:
      shape, existence, field-level security, then canonical spelling from the
      describe rather than the configuration string. Returns null when any fail. */
  private static Schema.DescribeFieldResult resolveField(Map<String, Schema.SObjectField> fieldMap, String apiName) {
    if (String.isBlank(apiName) || !SAFE_API_NAME.matcher(apiName).matches()) {
      return null;
    }

    /*  getMap() is keyed lower case - without this a config row saying "email"
        would silently never match. */
    Schema.SObjectField token = fieldMap.get(apiName.toLowerCase());
    if (token == null) {
      return null;
    }

    Schema.DescribeFieldResult dfr = token.getDescribe();
    return dfr.isAccessible() ? dfr : null;
  }

  private static Schema.DescribeSObjectResult resolveObject(String objectApiName) {
    if (String.isBlank(objectApiName) || !SAFE_API_NAME.matcher(objectApiName).matches()) {
      return null;
    }

    Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
    if (objType == null) {
      return null;
    }

    Schema.DescribeSObjectResult describe = objType.getDescribe();
    return describe.isAccessible() ? describe : null;
  }

  /*=================================================================
    QUERIES
  =================================================================*/

  private static SObject queryHostRecord(String objectApiName, Set<String> fieldNames, Id recordId) {
    List<String> selectFields = new List<String>{ 'Id' };
    for (String fieldName : fieldNames) {
      selectFields.add(String.escapeSingleQuotes(fieldName));
    }

    String soql =
      'SELECT ' +
      String.join(selectFields, ', ') +
      ' FROM ' +
      String.escapeSingleQuotes(objectApiName) +
      ' WHERE Id = :recordId LIMIT 1';

    /*  System mode so the class-level without sharing declaration takes effect.
        Field level security is not lost: every field in the SELECT already passed
        the isAccessible() gate in resolveField() before reaching this point. */
    List<SObject> records = Database.queryWithBinds(
      soql,
      new Map<String, Object>{ 'recordId' => recordId },
      AccessLevel.SYSTEM_MODE
    );
    return records.isEmpty() ? null : records[0];
  }

  /*=================================================================
    HANDLERS
  =================================================================*/

  private static InsightItem buildFieldItem(
    CMER04_Record_Insight_Config__mdt config,
    Schema.DescribeFieldResult dfr,
    Object value
  ) {
    InsightItem item = new InsightItem();
    item.key = config.DeveloperName;
    item.insightType = TYPE_FIELD_CHECK;
    item.fieldApiName = dfr.getName();
    item.label = resolveLabel(config, dfr.getLabel());
    item.category = config.ER_Category__c;
    item.message = config.ER_Message__c;
    item.isFilled = isFilled(value);
    item.status = item.isFilled ? STATUS_OK : STATUS_MISSING;
    item.displayValue = toDisplayValue(value, dfr.getType());
    return item;
  }

  private static InsightItem buildLookupItem(
    CMER04_Record_Insight_Config__mdt config,
    Schema.DescribeFieldResult sourceDfr,
    Object value,
    Id recordId,
    Map<String, Schema.SObjectField> hostFields,
    SObject hostRecord
  ) {
    /*  No value to match on means there is nothing to say - skip the row entirely
        rather than claiming no duplicates exist. */
    if (!isFilled(value)) {
      return null;
    }

    Schema.DescribeSObjectResult lookupDescribe = resolveObject(config.ER_Lookup_Object__c);
    if (lookupDescribe == null) {
      return null;
    }

    Map<String, Schema.SObjectField> lookupFields = lookupDescribe.fields.getMap();
    Schema.DescribeFieldResult matchDfr = resolveField(lookupFields, config.ER_Lookup_Field__c);
    if (matchDfr == null) {
      return null;
    }

    String displayFieldName = String.isBlank(config.ER_Lookup_Display_Field__c)
      ? DEFAULT_DISPLAY_FIELD
      : config.ER_Lookup_Display_Field__c;
    Schema.DescribeFieldResult displayDfr = resolveField(lookupFields, displayFieldName);
    if (displayDfr == null) {
      return null;
    }

    InsightItem item = new InsightItem();
    item.key = config.DeveloperName;
    item.insightType = TYPE_DUPLICATE_LOOKUP;
    item.fieldApiName = sourceDfr.getName();
    item.label = resolveLabel(config, lookupDescribe.getLabel());
    item.category = config.ER_Category__c;
    item.message = config.ER_Message__c;
    item.actionLabel = String.isBlank(config.ER_Action_Label__c)
      ? lookupDescribe.getLabel() + ' Found'
      : config.ER_Action_Label__c;
    /*  Optional narrowing, e.g. only match Accounts of a given record type. */
    Schema.DescribeFieldResult filterDfr = null;
    if (String.isNotBlank(config.ER_Filter_Field__c)) {
      filterDfr = resolveField(lookupFields, config.ER_Filter_Field__c);
      if (filterDfr == null) {
        return null;
      }
    }

    Schema.DescribeFieldResult dynamicFilterDfr = null;
    String dynamicFilterValue = null;
    if (String.isNotBlank(config.ER_Dynamic_Filter_Field__c) && String.isNotBlank(config.ER_Dynamic_Filter_Source_Field__c)) {
      Schema.DescribeFieldResult hostSourceDfr = resolveField(hostFields, config.ER_Dynamic_Filter_Source_Field__c);
      if (hostSourceDfr == null) {
        return null;
      }

      /*  An unmapped or blank host value drops the narrowing rather than the row: a Mobility
          lead still needs to see the contracts it cannot amend, and the action layer already
          states the reason per match. */
      String mappedValue = mapDynamicFilterValue(
        config.ER_Dynamic_Filter_Value_Map__c,
        String.valueOf(hostRecord.get(hostSourceDfr.getName()))
      );
      if (String.isNotBlank(mappedValue)) {
        dynamicFilterDfr = resolveField(lookupFields, config.ER_Dynamic_Filter_Field__c);
        if (dynamicFilterDfr == null) {
          return null;
        }
        dynamicFilterValue = mappedValue;
      }
    }

    List<InsightMatch> matches = findMatches(
      lookupDescribe,
      matchDfr,
      displayDfr,
      filterDfr,
      config.ER_Filter_Value__c,
      dynamicFilterDfr,
      dynamicFilterValue,
      MATCH_MODE_CONTAINS.equalsIgnoreCase(config.ER_Dynamic_Filter_Match_Mode__c),
      String.valueOf(value),
      recordId
    );

    /*  No duplicate is not an insight worth a row - only a match found is worth
        flagging. A clean field would otherwise sit on the page as a permanent
        green checkmark for something that was never actually in question. */
    if (matches.isEmpty()) {
      return null;
    }

    item.matches = matches;
    item.actionType = config.ER_Action_Type__c;
    item.actionButtonLabel = config.ER_Action_Button_Label__c;
    stampActionState(config, matches, recordId);

    item.isFilled = false;
    item.status = STATUS_ATTENTION;
    item.displayValue = String.valueOf(value);
    return item;
  }

  // harkirat - one bulk call for every match on the row, not one per match
  private static void stampActionState(CMER04_Record_Insight_Config__mdt config, List<InsightMatch> matches, Id recordId) {
    if (!ACTION_AMEND_AND_CONVERT.equals(config.ER_Action_Type__c)) {
      return;
    }

    try {
      List<Id> matchIds = new List<Id>();
      for (InsightMatch match : matches) {
        matchIds.add((Id) match.recordId);
      }

      Map<Id, APER47_LeadAmendment_Management.AmendEligibility> eligibilityByContract = APER47_LeadAmendment_Management.evaluate(
        recordId,
        matchIds
      );

      for (InsightMatch match : matches) {
        APER47_LeadAmendment_Management.AmendEligibility eligibility = eligibilityByContract.get((Id) match.recordId);
        if (eligibility != null) {
          match.canAct = eligibility.isEligible;
          match.blockedReason = eligibility.blockedReason;
        }
      }
    } catch (Exception e) {
      // harkirat - leave the row as a plain duplicate warning rather than losing it
      System.debug(LoggingLevel.ERROR, 'stampActionState failed: ' + e.getMessage());
    }
  }

  /*  Inverse polarity to the duplicate lookup above: here a match is what we WANT.
      Zero matching children means a required related record is missing. */
  private static InsightItem buildRelatedItem(CMER04_Record_Insight_Config__mdt config, Id recordId) {
    Schema.DescribeSObjectResult childDescribe = resolveObject(config.ER_Lookup_Object__c);
    if (childDescribe == null) {
      return null;
    }

    Map<String, Schema.SObjectField> childFields = childDescribe.fields.getMap();
    Schema.DescribeFieldResult parentDfr = resolveField(childFields, config.ER_Lookup_Field__c);
    if (parentDfr == null) {
      return null;
    }

    /*  Optional. A blank filter field means "any child record counts". */
    Schema.DescribeFieldResult filterDfr = null;
    if (String.isNotBlank(config.ER_Filter_Field__c)) {
      filterDfr = resolveField(childFields, config.ER_Filter_Field__c);
      if (filterDfr == null) {
        return null;
      }
    }

    Integer found = countRelated(childDescribe, parentDfr, filterDfr, config.ER_Filter_Value__c, recordId);

    InsightItem item = new InsightItem();
    item.key = config.DeveloperName;
    item.insightType = TYPE_RELATED_RECORD_CHECK;
    item.fieldApiName = parentDfr.getName();
    item.label = resolveLabel(config, childDescribe.getLabel());
    item.category = config.ER_Category__c;
    item.message = config.ER_Message__c;
    item.isFilled = found > 0;
    item.status = found > 0 ? STATUS_OK : STATUS_MISSING;
    return item;
  }

  /*  COUNT() rather than selecting a display field. Not an optimisation: several child
      objects worth checking - OpportunityContactRole among them - have no Name field,
      so a display query would fail to resolve and silently drop the row. Existence is
      the whole signal anyway. */
  private static Integer countRelated(
    Schema.DescribeSObjectResult childDescribe,
    Schema.DescribeFieldResult parentDfr,
    Schema.DescribeFieldResult filterDfr,
    String filterValue,
    Id recordId
  ) {
    String soql =
      'SELECT COUNT() FROM ' +
      String.escapeSingleQuotes(childDescribe.getName()) +
      ' WHERE ' +
      String.escapeSingleQuotes(parentDfr.getName()) +
      ' = :recordId';

    Map<String, Object> binds = new Map<String, Object>{ 'recordId' => recordId };

    if (filterDfr != null) {
      soql += ' AND ' + String.escapeSingleQuotes(filterDfr.getName()) + ' = :filterValue';
      binds.put('filterValue', filterValue);
    }

    return Database.countQueryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE);
  }

  private static List<InsightMatch> findMatches(
    Schema.DescribeSObjectResult lookupDescribe,
    Schema.DescribeFieldResult matchDfr,
    Schema.DescribeFieldResult displayDfr,
    Schema.DescribeFieldResult filterDfr,
    String filterValue,
    Schema.DescribeFieldResult dynamicFilterDfr,
    String dynamicFilterValue,
    Boolean dynamicFilterContains,
    String matchValue,
    Id recordId
  ) {
    List<InsightMatch> matches = new List<InsightMatch>();

    String soql =
      'SELECT Id, ' +
      String.escapeSingleQuotes(displayDfr.getName()) +
      ' FROM ' +
      String.escapeSingleQuotes(lookupDescribe.getName()) +
      ' WHERE ' +
      String.escapeSingleQuotes(matchDfr.getName()) +
      ' = :matchValue AND Id != :recordId';

    Map<String, Object> binds = new Map<String, Object>{ 'matchValue' => matchValue, 'recordId' => recordId };

    if (filterDfr != null) {
      soql += ' AND ' + String.escapeSingleQuotes(filterDfr.getName()) + ' = :filterValue';
      binds.put('filterValue', filterValue);
    }

    if (dynamicFilterDfr != null) {
      /*  Contains exists because Contract_Category__c returns composites like "Benefits and
          Engagement" that a Benefits lead must still match - the rule APER47 already applies
          when it decides whether that same contract is amendable. */
      soql +=
        ' AND ' +
        String.escapeSingleQuotes(dynamicFilterDfr.getName()) +
        (dynamicFilterContains == true ? ' LIKE :dynamicFilterValue' : ' = :dynamicFilterValue');
      binds.put('dynamicFilterValue', dynamicFilterContains == true ? '%' + dynamicFilterValue + '%' : dynamicFilterValue);
    }

    soql += ' LIMIT ' + MATCH_QUERY_LIMIT;

    /*  Deliberately system mode: a duplicate owned by a team the running user
        cannot see is exactly the duplicate worth warning them about. Both fields
        below already passed the isAccessible() gate. */
    List<SObject> found = Database.queryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE);

    for (SObject row : found) {
      InsightMatch match = new InsightMatch();
      match.recordId = String.valueOf(row.get('Id'));
      Object displayValue = row.get(displayDfr.getName());
      match.displayLabel = displayValue == null ? match.recordId : String.valueOf(displayValue);
      matches.add(match);
    }
    return matches;
  }

  /*=================================================================
    HELPERS
  =================================================================*/

  /*  harkirat - lets config override the text shown, falls back to the Salesforce label */
  private static String resolveLabel(CMER04_Record_Insight_Config__mdt config, String standardLabel) {
    return String.isNotBlank(config.ER_Display_Label__c) ? config.ER_Display_Label__c : standardLabel;
  }

  /*  One rule, one place. A checkbox is never null in SOQL, so a null-only test would
      mark every checkbox green forever - an unticked box is treated as not filled.
      Zero is left as filled: it is a legitimate business answer (0 employees, 0 EUR)
      and flagging it would be a false positive. */
  @TestVisible
  private static Boolean isFilled(Object value) {
    if (value == null) {
      return false;
    }
    if (value instanceof String) {
      return String.isNotBlank((String) value);
    }
    if (value instanceof Boolean) {
      return (Boolean) value;
    }
    return true;
  }

  /*  Parses "SourceValue:TargetValue;SourceValue2:TargetValue2" and returns the target
      for the given raw value, or null if the map is blank, the raw value is blank, or
      no entry matches - callers treat null as "skip the dynamic filter", never fatal. */
  @TestVisible
  private static String mapDynamicFilterValue(String mapConfig, String rawValue) {
    if (String.isBlank(mapConfig) || String.isBlank(rawValue)) {
      return null;
    }
    for (String pair : mapConfig.split(';')) {
      List<String> parts = pair.split(':');
      if (parts.size() == 2 && parts[0].trim().equalsIgnoreCase(rawValue.trim())) {
        return parts[1].trim();
      }
    }
    return null;
  }

  /*  Checkboxes return null: the green tick already says "ticked" and printing
      the word "true" next to it reads like a bug. */
  private static String toDisplayValue(Object value, Schema.DisplayType fieldType) {
    if (value == null || fieldType == Schema.DisplayType.BOOLEAN) {
      return null;
    }
    String rendered = String.valueOf(value);
    return rendered.length() > MAX_DISPLAY_VALUE ? rendered.substring(0, MAX_DISPLAY_VALUE) : rendered;
  }
}