/**
 * @author : ALK
 * @date : 19/04/2021
 * @desc : Utils
 * @see Utils
 */

public with sharing class Utils {
  public static Map<String, Global_Settings__mdt> mapSettings { get; set; }

  public static Map<Id, User> userMap { get; set; }
  public static Map<Id, Group> queueMap { get; set; }

  public class RecordTypeException extends Exception {
  }

  public static Map<Id, List<UserRole>> roleHierarchy { get; set; }
  public static Map<String, String> mapAccessToken { get; set; }

  /**
   * @author ALK
   * @date 16/01/2021
   * @description Generate a Unique ID
   * @return String 36 char
   * @see Crypto
   * @see EncodingUtil
   */
  public static String generateUniqueId() {
    Blob b = Crypto.generateAesKey(128);
    String h = EncodingUtil.convertToHex(b);
    String uniqueID =
      h.substring(0, 8) +
      '-' +
      h.substring(8, 12) +
      '-' +
      h.substring(12, 16) +
      '-' +
      h.substring(16, 20) +
      '-' +
      h.substring(20);
    return uniqueID;
  }

  /**
   * @author ALK
   * @date 16/01/2021
   * @description get all Global_Settings__mdt entries
   * @return Map<String, Global_Settings__mdt>
   */
  public static Map<String, Global_Settings__mdt> getGlobalSettings() {
    if (mapSettings == null || mapSettings.isEmpty()) {
      mapSettings = new Map<String, Global_Settings__mdt>();
      for (Global_Settings__mdt mdt : Global_Settings__mdt.getAll().values())
        mapSettings.put(mdt.DeveloperName, mdt);
    }

    return mapSettings;
  }

  /**
   * @author ALK
   * @date 16/01/2021
   * @description return a Global Setting value from a key
   * @param key
   *
   * @return String
   */
  public static String getGlobalSettingsValueFromKey(String key) {
    Map<String, Global_Settings__mdt> settings = Utils.getGlobalSettings();
    return (settings.get(key) != null &&
      settings.get(key).Active__c &&
      String.isNotBlank(settings.get(key).Value__c)
      ? settings.get(key).Value__c
      : null);
  }

  /**
   * @author Noor
   * @date 27/04/2023
   * @description return a Global Setting value from a key using SOQL to be able to retrieve value more than 255 characters
   * @param key
   *
   * @return String
   */
  public static String getGlobalSettingsValueFromKeyBySOQL(String key) {
    Map<String, Global_Settings__mdt> settings = Utils.getGlobalSettings();
    List<Global_Settings__mdt> mdts = [
      SELECT Id, Value__c
      FROM Global_Settings__mdt
      WHERE DeveloperName = :key AND Active__c = TRUE
    ];
    if (!mdts.isEmpty())
      return mdts[0].Value__c;
    else
      throw new ApplicationException('Global Settings Key {0} is not configured'.replace('{0}', key));
  }

  /**
   * @author ALK
   * @date 16/01/2021
   * @description Get recordTypeId from rt developerName
   *
   * @param sObjectType
   * @param recordTypeName
   *
   * @return String
   */
  public static String getRecordTypeIdByDeveloperName(SObjectType sObjectType, String recordTypeName) {
    //Generate a map of tokens for all the Record Types for the desired object
    Map<String, Schema.RecordTypeInfo> recordTypeInfo = sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
    if (!recordTypeInfo.containsKey(recordTypeName))
      throw new RecordTypeException('Record type "' + recordTypeName + '" does not exist.');

    //Retrieve the record type id by name
    return recordTypeInfo.get(recordTypeName).getRecordTypeId();
  }

  /**
   * @author ALK
   * @date 16/01/2021
   * @description Get recordTypeId from rt developerName
   *
   * @param sObjectType
   * @param recordTypeName
   *
   * @return String
   */
  public static Map<String, String> getRecordTypeMapIdByDeveloperName(SObjectType sObjectType) {
    //Generate a map of tokens for all the Record Types for the desired object
    Map<String, String> recordTypeMapIdByDeveloperName = new Map<String, String>();

    for (Schema.RecordTypeInfo typeInfo : sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().values())
      recordTypeMapIdByDeveloperName.put(typeInfo.recordTypeId, typeInfo.developerName);

    return recordTypeMapIdByDeveloperName;
  }

  /**
   * @author AAM
   * @date 21/04/2021
   * @description Get Pricebook Id from name
   *
   * @param pbName
   *
   * @return String
   */
  public static Id getPricebookId(String pbName) {
    List<Pricebook2> pbList = [SELECT Id FROM Pricebook2 WHERE Name = :pbName AND IsActive = TRUE];
    return pbList.isEmpty() ? null : pbList[0].Id;
  }

  /**
   * @Noor
   * @date 17/06/2021
   * @description split string by semi colon else return empty list if value is null
   * @param values
   *
   * @return
   */
  public static List<String> splitValues(String values) {
    return splitValues(values, Constants.SEMICOLON);
  }

  /**
   * @ALK
   * @date 17/06/2021
   * @description split string by semi colon else return empty list if value is null
   * @param values
   * @param separator
   *
   * @return List<String>
   */
  public static List<String> splitValues(String values, String separator) {
    return values != null ? values.split(separator) : new List<String>();
  }

  /**
   * @Noor
   * @date 27/04/2023
   * @description split list of values to a key pair value separated by @param separator
   * @param values list of values
   * @param separator separator delimiter
   *
   * @return List<String>
   */
  public static Map<String, String> splitKeyPairValues(List<String> values, String separator) {
    Map<String, String> mapProperties = new Map<String, String>();
    for (String value : values) {
      if (value.contains(separator))
        mapProperties.put(value.split(separator)[0], value.split(separator)[1]);
      else
        mapProperties.put(value, null);
    }
    return mapProperties;
  }

  /**
   * @author AAZ
   * @date 02/06/2021
   * @description Check overlapping dates
   * @param newStartDate
   * @param newEndDate
   * @param oldStartdDate
   * @param oldEndDate
   *
   * @return
   */
  public static Boolean checkDatesBetween2Dates(
    Date newStartDate,
    Date newEndDate,
    Date oldStartdDate,
    Date oldEndDate
  ) {
    newStartDate = (newStartDate == null ? Date.valueOf('1900-01-01') : newStartDate);
    newEndDate = (newEndDate == null ? Date.valueOf('2900-01-01') : newEndDate);
    oldStartdDate = (oldStartdDate == null ? Date.valueOf('1900-01-01') : oldStartdDate);
    oldEndDate = (oldEndDate == null ? Date.valueOf('2900-01-01') : oldEndDate);
    return (newStartDate <= oldEndDate && oldStartdDate <= newEndDate);
  }

  /**
   * @author AAM
   * @date 24/06/2021
   * @description Get all users from Queue ID
   *
   * @param Queue or Group Id
   *
   * @return Set<Id>
   */
  private static Set<Id> userIdSet = new Set<Id>();
  private static Set<Id> activeUserIdSet = new Set<Id>();
  private static Map<Id, Set<Id>> userIdsByRoleMap = new Map<Id, Set<Id>>();
  private static Map<Id, Group> groupMap = new Map<Id, Group>();
  private static Map<Id, Set<Id>> groupMemberMap = new Map<Id, Set<Id>>();
  private static Map<Id, Set<Id>> parentRoleMap = new Map<Id, Set<Id>>();
  private static Set<Id> curRoleAndSubSet = new Set<Id>();

  public static Set<Id> getQueueUsers(Id groupId) {
    System.debug('>>> getQueueUsers Start');

    // Prepare all available datas regarding queues (Group, GroupMember, UserRole, User), in order to do one shot queries and to avoid
    for (User usr : [SELECT Id, UserRoleId FROM User WHERE isActive = TRUE AND UserType = 'Standard']) {
      activeUserIdSet.add(usr.Id);
      if (userIdsByRoleMap.containsKey(usr.UserRoleId))
        userIdsByRoleMap.get(usr.UserRoleId).add(usr.Id);
      else
        userIdsByRoleMap.put(usr.UserRoleId, new Set<Id>{ usr.Id });
    }

    // Init parent roles map
    for (UserRole ur : [SELECT Id, ParentRoleId FROM UserRole WHERE ParentRoleId != NULL]) {
      if (parentRoleMap.containsKey(ur.ParentRoleId))
        parentRoleMap.get(ur.ParentRoleId).add(ur.Id);
      else
        parentRoleMap.put(ur.ParentRoleId, new Set<Id>{ ur.Id });
    }

    Set<Id> nonEmptyGroupSet = new Set<Id>();

    // Init group members map
    for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember]) {
      if (groupMemberMap.containsKey(gm.GroupId))
        groupMemberMap.get(gm.GroupId).add(gm.UserOrGroupId);
      else
        groupMemberMap.put(gm.GroupId, new Set<Id>{ gm.UserOrGroupId });
      nonEmptyGroupSet.add(gm.GroupId);
    }

    // Init group map
    groupMap = new Map<Id, Group>(
      [SELECT Id, RelatedId, Type FROM Group WHERE (Id IN :nonEmptyGroupSet AND Type = 'Regular') OR Type != 'Regular']
    );

    getGroupUsers(groupId);

    System.debug('>>> getQueueUsers End. userIdSet: ' + userIdSet);
    return userIdSet;
  }

  public static void getGroupUsers(Id groupId) {
    for (Id gmId : groupMemberMap.get(groupid)) {
      switch on ((String) gmId).substring(0, 3) {
        when '005' {
          if (activeUserIdSet.contains(gmId))
            userIdSet.add(gmId);
        }
        when '00G' {
          Group curGroup = groupMap.get(gmId);
          switch on curGroup?.Type {
            when 'Regular' {
              getGroupUsers(gmId);
            }
            when 'Role' {
              getUsersByRole(new Set<Id>{ curGroup.RelatedId });
            }
            when 'RoleAndSubordinates' {
              Set<Id> roleIdSet = getSubRoles(curGroup.RelatedId);
              roleIdSet.add(curGroup.RelatedId); // Include also top parent role
              getUsersByRole(roleIdSet);
            }
            /* If needed, add territories management */
            // when 'Territory' {}
            // when 'TerritoryAndSubordinates' {}
          }
        }
      }
    }
  }

  private static void getUsersByRole(Set<Id> RoleIdSet) {
    for (Id rlId : RoleIdSet)
      if (userIdsByRoleMap.get(rlId) != null)
        userIdSet.addAll(userIdsByRoleMap.get(rlId));
  }

  private static Set<Id> getSubRoles(Id RoleId) {
    if (parentRoleMap.keySet().contains(RoleId)) {
      curRoleAndSubSet.addAll(parentRoleMap.get(RoleId));
      for (Id rId : parentRoleMap.get(RoleId))
        if (parentRoleMap.keySet().contains(rId))
          getSubRoles(rId);
    }
    return curRoleAndSubSet;
  }

  /**
   * @author Noor
   * @description retrieve opportunity original name from
   *              the naming convention {Opportunity.BU} - {Account.Name} - {Opportunity.Creation Date } - {sequence 01} - {Original opportunity name}
   * @param oppName
   *
   * @return
   */
  public static String getOriginalNameFromOpportunity(String oppName) {
    return oppName.indexOf(Constants.NAME_OPP_DELIMITER) > 0
      ? oppName.substringAfterLast(Constants.NAME_OPP_DELIMITER)
      : oppName.left(50);
  }

  /**
   * @author Noor
   * @description Consider if name end with -, the name of the opportunity comes from converted lead,
   *              Update name to have from Lead
   * @param oppName
   *
   * @return opportunity Name
   */
  public static String updateNameIfOpportunityFromLead(String oppName) {
    String originalName = oppName;
    if (String.isNotBlank(originalName) && originalName.endsWith('-'))
      originalName = Label.OPPORTUNITY_DEFAULT_NAMING_FROM_LEAD;
    return originalName;
  }

  /**
   * @author ALK
   * @date 21/10/2021
   * @description Get a Picklist Values
   * @param aObject
   * @param aField
   *
   * @return
   */
  public static Map<String, String> getPicklistValues(String aObject, String aField) {
    System.debug(LoggingLevel.DEBUG, '>>>> ALK - getPicklistValues');
    Map<String, String> mapValues = new Map<String, String>();
    try {
      Schema.SObjectType objType = Schema.getGlobalDescribe().get(aObject).getDescribe().getSObjectType();
      Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
      Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
      for (Schema.PicklistEntry value : fieldMap.get(aField).getDescribe().getPicklistValues()) {
        mapValues.put(value.getValue(), value.getLabel());
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'getPicklistValues Error : ' + e.getLineNumber() + ' : ' + e.getMessage());
    }

    return mapValues;
  }

  /**
   * @author ALK
   * @date 21/10/2021
   * @description Get a Picklist values translations
   * @param aObject
   * @param aField
   *
   * @return
   */
  public static Map<String, String> getPicklistValuesTranslations(String aObject, String aField) {
    Map<String, String> mapPicklistValues = new Map<String, String>();
    try {
      Schema.SObjectType objType = Schema.getGlobalDescribe().get(aObject).getDescribe().getSObjectType();
      Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
      Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
      List<Schema.PicklistEntry> picklistValues = fieldMap.get(aField).getDescribe().getPicklistValues();

      for (Schema.PicklistEntry pe : picklistValues) {
        mapPicklistValues.put(pe.getValue(), pe.getLabel());
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '>>>>>> ALK - getPicklistValues Error : ' +
        e.getLineNumber() +
        ' : ' +
        e.getMessage()
      );
    }

    return mapPicklistValues;
  }

  /**
   * @author AAM
   * @date 03/01/2022
   * @description Get BU code according to country code (in order to manage specific case like BENELUX)
   *
   * @param countryCode
   *
   * @return String
   */
  public static String getBUCode(String countryCode) {
    return (countryCode == 'BE' || countryCode == 'LU') ? 'BENELUX' : countryCode;
  }

  /**
   * @author AAM
   * @date 01/03/2022
   * @description Get country code according to country name
   *
   * @param countryName
   *
   * @return String
   */

  public static String getCountryCode(String countryName) {
    System.debug('>>> getCountryCode - Start.  countryName = ' + countryName);
    return COUNTRY_CODE_MAP.get(countryName.toUpperCase());
  }

  /**
   * @author ALK
   * @date 04/03/2022
   * @description get Week number based on the date sent as param
   * <ul>
   *     <li>Theweek number is based on ISO 8601 Date format</li>
   *     <li>A week in a year starts on the first thursday in the calendar</li>
   *     <li>https://en.wikipedia.org/wiki/ISO_8601#Week_dates</li>
   *     <li>Week numbers : https://www.epochconverter.com/weeks/2021</li>
   * </ul>
   * @param dateValue
   *
   * @return
   */
  public static Integer getWeekNumber(Date dateValue) {
    if (dateValue != null) {
      return Integer.valueOf(
        Datetime.newInstanceGmt(
            Date.newInstance(dateValue.year(), dateValue.month(), dateValue.day()).toStartOfWeek(),
            Time.newInstance(12, 0, 0, 0)
          )
          .format('w')
      );
    }
    return null;
  }

  /**
   * @author AAM
   * @date 19/07/2022
   * @description country code map in static variable (in order to )
   *
   * @return Map<String,String>
   */
  public static final Map<String, String> COUNTRY_CODE_MAP;
  static {
    if (COUNTRY_CODE_MAP == null) {
      COUNTRY_CODE_MAP = new Map<String, String>();
      Auto_Enrollment__mdt countryCodes = [
        SELECT Picklist_Values__c, Picklist_Labels__c
        FROM Auto_Enrollment__mdt
        WHERE Label = 'pk_country_codes'
      ];
      System.debug('>>> COUNTRY_CODE_MAP - countryCodes.Picklist_Values__c ' + countryCodes.Picklist_Values__c);
      System.debug('>>> COUNTRY_CODE_MAP - countryCodes.Picklist_Labels__c ' + countryCodes.Picklist_Labels__c);
      Map<String, String> countryCodeMap = new Map<String, String>();
      List<String> countryCodeList = countryCodes.Picklist_Values__c.split('\\|');
      List<String> countryNameList = countryCodes.Picklist_Labels__c.split('\\|');
      for (Integer i = 0; i < countryCodeList.size(); i++)
        COUNTRY_CODE_MAP.put(countryNameList[i], countryCodeList[i]);
      System.debug('>>> COUNTRY_CODE_MAP - result ' + COUNTRY_CODE_MAP);
    }
  }

  /**
   * @author ALK
   * @description log all messages into the ER_Log_Message__c
   * @param messages
   */
  public static void logMessage(List<Utils.LogMessage> messages) {
    System.debug('>>>>> ALK - messages : ' + messages);
  }

  public class LogMessage {
    Id recordId { get; set; }
    String className { get; set; }
    String methodName { get; set; }
    String logType { get; set; }
    String message { get; set; }

    public LogMessage(Id recordId, String className, String methodName, String logType, String message) {
      this.recordId = recordId;
      this.className = className;
      this.methodName = methodName;
      this.logType = logType;
      this.message = message;
    }
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description query the active user
   * @return list of all active user
   */
  public static Map<Id, User> getUserMap() {
    if (userMap == null || userMap.isEmpty())
      userMap = new Map<Id, User>(
        [SELECT Id, UserRoleId, UserRole.DeveloperName, ER_Queue_CTI__c, Email FROM User WHERE IsActive = TRUE]
      );
    return userMap;
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description query all the group
   * @return list of all group
   */
  public static Map<Id, Group> getQueueMap() {
    if (queueMap == null || queueMap.isEmpty())
      queueMap = new Map<Id, Group>([SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']);
    return queueMap;
  }

  /**
   * @author Noor
   * @date 10/10/2022
   * @description get Queue Id By DeveloperName
   * @return list of all group
   */
  public static Id getQueueIdByName(String queueDeveloperName) {
    Map<Id, Group> queueMap = getQueueMap();

    for (Group g : queueMap.values())
      if (g.DeveloperName == queueDeveloperName)
        return g.Id;

    throw new ApplicationException('Queue {0} is not configured'.replace('{0}', queueDeveloperName));
  }

  /**
   * @author ALK
   * @date 17/10/2022
   * @description Get the env name
   * @return
   */
  public static String getSandboxName() {
    final String PROD_ENVIRONMENT = 'prod';
    final String SANDBOX_NAME_PREFIX = '--';
    final String SANDBOX_NAME_END = '.';
    String hostName = System.Url.getSalesforceBaseUrl().getHost();

    Boolean isSandbox = hostName.indexOf(SANDBOX_NAME_PREFIX) != -1;
    if (isSandbox) {
      Integer startIndexOfSandboxName = hostName.indexOf(SANDBOX_NAME_PREFIX) + SANDBOX_NAME_PREFIX.length();
      Integer endIndex = hostName.indexOf(SANDBOX_NAME_END);
      return hostName.mid(startIndexOfSandboxName, endIndex - startIndexOfSandboxName);
    }

    //When no sandbox is found then just return a string that signifies this is production
    return PROD_ENVIRONMENT;
  }

  /**
   * @author AAZ
   * @date 08/12/2022
   * @description Return the last customer number
   * @return
   */
  public static String getLastCustomerNumberSequence() {
    return GenericWithoutSharing.getLastCustomerNumberSequence();
  }

  /**
   * @author ALK
   * @date 17/01/2023
   * @description Date time validator, The date time string should respect the following format 2023-01-10T13:45:56.000Z
   * @param incomingDate
   *
   * @return
   */
  public static Boolean dateTimeIsoMatcher(String incomingDate) {
    if (String.isNotBlank(incomingDate)) {
      String patternRegex = '^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$';
      Pattern datePattern = Pattern.compile(patternRegex);
      Matcher matchDate = datePattern.matcher(incomingDate);
      return matchDate.matches();
    }

    return false;
  }

  /**
   * @author ALK
   * @date 17/01/2023
   * @description Check if a salesforce Id has a valid format (18 char)
   * @param recordId
   *
   * @return
   */
  public static Boolean isValidSalesforceId18(String recordId) {
    if (String.isNotBlank(recordId)) {
      String patternRegex = '^[a-zA-Z0-9]{18}$';
      Pattern sfdcIdPattern = Pattern.compile(patternRegex);
      Matcher matchDate = sfdcIdPattern.matcher(recordId);
      return matchDate.matches();
    }

    return false;
  }

  /**
   * @author ALK
   * @date 17/01/2023
   * @description Check if a salesforce Id has a valid format (15 char)
   * @param recordId
   *
   * @return
   */
  public static Boolean isValidSalesforceId15(String recordId) {
    if (String.isNotBlank(recordId)) {
      String patternRegex = '^[a-zA-Z0-9]{15}$';
      Pattern sfdcIdPattern = Pattern.compile(patternRegex);
      Matcher matchDate = sfdcIdPattern.matcher(recordId);
      return matchDate.matches();
    }

    return false;
  }

  /**
   * @author ALK
   * @date 17/01/2023
   * @description Check if a salesforce Id has a valid format (15 char)
   * @param recordId
   *
   * @return
   */
  public static Boolean isValidSalesforceId(String recordId) {
    return (isValidSalesforceId15(recordId) || isValidSalesforceId18(recordId));
  }

  /**
   * @author ALK
   * @description Check if a salesforce Id is valid (Format, Number of char and check the id for a specific SObject)
   * @param sfdcId
   * @param t
   *
   * @return
   */
  public static Boolean isValidSalesforceId(String sfdcId, System.Type t) {
    try {
      if (Pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}').matcher(sfdcId).matches()) {
        // Try to assign it to an Id before checking the type
        Id id = sfdcId;

        // Use the Type to construct an instance of this sObject
        SObject sObj = (SObject) t.newInstance();

        // Set the ID of the new object to the value to test
        sObj.Id = id;

        // If the tests passed, it's valid
        return true;
      }
    } catch (Exception e) {
      System.debug('>>>>> ALK - isValidSalesforceId exception : ' + e.getMessage());
    }

    // ID is not valid
    return false;
  }

  /**
   * @author ALK
   * @date 22/01/2023
   * @description return today's NPS string date
   * @return
   */
  public static String getNPSDateSurvey() {
    return Date.today().day() +
      '/' +
      (Date.today().month() < 10 ? '0' + Date.today().month() : String.valueOf(Date.today().month()));
  }

  /**
   * @author ALK
   * @date 12/01/2023
   * @description Return All Role Subordinates by Parent Id
   * @param roleId
   *
   * @return
   */
  public static Map<Id, UserRole> getRoleSubordinates(Id roleId) {
    List<UserRole> childRoles = new List<UserRole>();
    Map<Id, UserRole> mapSubordinates = new Map<Id, UserRole>();

    if (String.isNotBlank(roleId)) {
      if (roleHierarchy == null || roleHierarchy.isEmpty()) {
        roleHierarchy = new Map<Id, List<UserRole>>();
        for (UserRole ur : [SELECT Id, Name, DeveloperName, ParentRoleId FROM UserRole WHERE ParentRoleId != NULL]) {
          if (!roleHierarchy.containsKey(ur.ParentRoleId))
            roleHierarchy.put(ur.ParentRoleId, new List<UserRole>());
          roleHierarchy.get(ur.ParentRoleId).add(ur);
        }
      }

      if (String.isNotEmpty(roleId) && roleHierarchy.containsKey(roleId)) {
        for (UserRole ur : roleHierarchy.get(roleId)) {
          childRoles.add(ur);
          mapSubordinates.put(ur.Id, ur);
          mapSubordinates.putAll(getRoleSubordinates(ur.Id));
        }
      }
    }

    return mapSubordinates;
  }

  /**
   * @description get SObject Type based on id
   * @param objectId
   *
   * @return object Name
   */
  public static String getSObjectType(Id objectId) {
    return objectId.getSObjectType().getDescribe().getName();
  }

  /**
   * @author ALK
   * @date 24/02/2023
   * @description Generate Unique text
   * @param strType
   * @param len
   *
   * @return
   */
  public static String generateUniqueString(String strType, Integer len) {
    if ((strType == Constants.TYPE_STRING || strType == Constants.TYPE_INTEGER) && len != null) {
      String allowedChars;
      String uniqueNumber = '';

      if (strType == Constants.TYPE_STRING)
        allowedChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      else if (strType == Constants.TYPE_INTEGER)
        allowedChars = '0123456789';

      while (uniqueNumber.length() < len) {
        Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), allowedChars.length());
        uniqueNumber += allowedChars.substring(randomIndex, randomIndex + 1);
      }

      return uniqueNumber;
    }

    return null;
  }

  /**
   * @author ALK
   * @date 07/03/2023
   * @description This method is used to get Azure AD Access Token
   * @return Map<String, String>
   * @example
   * 'token_type' => 'Bearer',
   * 'access_token' => 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ii1LSTNROW5OUjdiUm'
   */
  public static Map<String, String> getSmarterAccessToken() {
    if (mapAccessToken == null || mapAccessToken.isEmpty()) {
      String clientId = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_MS_AD_CLIENTID);
      String clientSecret = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_MS_AD_CLIENTSECRET);
      String scope = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_MS_AD_SCOPE);

      if (clientId != null && clientSecret != null && scope != null) {
        String payLoad =
          'grant_type=client_credentials' +
          '&client_id=' +
          EncodingUtil.urlEncode(clientId, Constants.UTF8_ENCODING) +
          '&client_secret=' +
          EncodingUtil.urlEncode(clientSecret, Constants.UTF8_ENCODING) +
          '&scope=' +
          scope;

        //REQUEST
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + Constants.SMARTER_MS_AD_NAMED_CREDENTIAL);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('grant_type', 'client_credentials');
        req.setBody(payLoad);

        //RESPONSE
        HttpResponse resp = http.send(req);
        System.debug(LoggingLevel.DEBUG, '>>>>> ALK - Success resp.getStatusCode(): ' + resp.getStatusCode());
        if (resp.getStatusCode() == 200) {
          Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          if (mapResponse != null) {
            String tokenType = (String) mapResponse.get(Constants.SMARTER_MS_TOKEN_TYPE);
            String accessToken = (String) mapResponse.get(Constants.SMARTER_MS_ACCESS_TOKEN);
            System.debug(LoggingLevel.DEBUG, '>>>>> ALK - tokenType : ' + tokenType);
            System.debug(LoggingLevel.DEBUG, '>>>>> ALK - accessToken : ' + accessToken);
            if (tokenType != null && accessToken != null) {
              mapAccessToken = new Map<String, String>{
                Constants.SMARTER_MS_TOKEN_TYPE => tokenType,
                Constants.SMARTER_MS_ACCESS_TOKEN => accessToken
              };
            }
          }
        }
      }
    }
    return mapAccessToken;
  }

  /**
   * @description Convert DateTime to string with the following format
   * @param myDate
   *
   * @return date in String @example 2023-03-30T08:32:18.364+0200
   */
  public static String convertDateTimeToString(Datetime myDate) {
    return myDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description check if owner has been changed from user to Queue
   * @param newId
   * @param oldId
   *
   * @return true if owner has been changed from User to Queue
   */
  public static boolean isChangeOwnerFromUserToQueue(Id newId, Id oldId) {
    return Utils.getSObjectType(oldId) == 'User' && Utils.getSObjectType(newId) == 'Group';
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description check if owner has been changed from user to Queue
   * @param newId
   * @param oldId
   *
   * @return true if owner has been changed from User to Queue
   */
  public static boolean isChangeOwnerFromQueueToUser(Id newId, Id oldId) {
    return Utils.getSObjectType(oldId) == 'Group' && Utils.getSObjectType(newId) == 'User';
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description map RecordType with code used for Custom metadata
   *              ER_Client_Case_RT -> CL
   *              ER_User_Case_RT -> UR
   * @param mapIdRecordType
   * @param recordTypeId
   * @return code
   */
  public static String mapRecordTypeCode(Map<String, String> mapIdRecordType, String recordTypeId) {
    String recordType = mapIdRecordType.get(recordTypeId);
    if (recordType == Constants.CASE_CLIENT_RT)
      return 'CL';
    if (recordType == Constants.CASE_USER_RT)
      return 'UR';
    return '';
  }

  /**
   * @date 11/07/2023
   * @author Noor
   * @description retrieve error message from Smarter error response
   * @param response error response
   *
   * @return message
   */
  public static String getMessageErrorFromSmarter(String response) {
    try {
      Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(response);
      Map<String, Object> dataMeta = (Map<String, Object>) (mapRespData.get('meta'));
      if (dataMeta.get('status').equals('failed')) {
        List<Object> messages = (List<Object>) dataMeta.get('messages');
        if (!messages.isEmpty()) {
          Map<String, Object> messageMap = (Map<String, Object>) messages[0];
          return (String) messageMap.get('text');
        }
      }
    } catch (Exception e) {
      System.debug('//callSmarterClientWS parsing error ' + e.getMessage());
    }
    return '';
  }

  /**
   * @date 29/08/2023
   * @author AAM
   * @description retrieve product names translated
   * @param language code
   * @return map of product codes / names
   */
  public static Map<String,String> getProductTranslationsMap(String lang) {
    Map<String,String> productTranslationsMap = new Map<String,String>();
    for (ER_Translation__c trs : [  SELECT Id, Product__c, Text__c
                                    FROM ER_Translation__c
                                    WHERE Product__c != NULL AND Language__c = :lang ]) productTranslationsMap.put(trs.Product__c, trs.Text__c);
    return productTranslationsMap;
  }

}