/**
 * @author : ALK
 * @date : 20/04/2021
 * @desc : UtilsTest
 * @see UtilsTest
 */

@IsTest
private class UtilsTest {
  @IsTest
  static void testAllMethods() {
    Test.startTest();

    //ALK - Test generateUniqueId
    String uniqueId = Utils.generateUniqueId();
    System.assert(String.isNotBlank(uniqueId), 'No Id generated');

    //ALK - getGlobalSettingsValueFromKey
    String someValue = Utils.getGlobalSettingsValueFromKey('NonExistantKey');
    System.assert(someValue == null, 'Finally found the key');

    //ALK - Test getRecordTypeIdByDeveloperName
    String rtId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, 'ER_Company_Account_RT');
    System.assert(String.isNotBlank(rtId), 'No recordTypeId returned');

    //ALK - getPricebookId
    Id priceBookId = Utils.getPricebookId('SomePriceBook' + Datetime.now().getTime());
    System.assert(priceBookId == null, 'It seem it exists finally');

    //ALK - getZuoraToken
    SendToZuoraMock mock = new SendToZuoraMock();
    Test.setMock(HttpCalloutMock.class, mock);
    String token = ZuoraUtils.getZuoraToken();
    //System.assert(String.isNotBlank(token), 'No token generated');

    List<String> lst = Utils.splitValues('some;values;to;be;splited');
    System.assert(!lst.isEmpty(), 'values not splited');

    Boolean checkDates = Utils.checkDatesBetween2Dates(null, null, null, null);
    System.assert(checkDates, 'check date not between');

    String txt = Utils.getOriginalNameFromOpportunity('Some-Name');
    System.assert(txt != null, 'No original Name');

    txt = Utils.updateNameIfOpportunityFromLead('Some Name-');
    System.assert(txt != null, 'No original Name');

    Map<String, String> picklistValues = Utils.getPicklistValues('Opportunity', 'StageName');
    System.assert(!picklistValues.isEmpty(), 'No stage found');

    Map<String, String> picklistTranslations = Utils.getPicklistValuesTranslations('Opportunity', 'StageName');

    Map<String, String> mapRT = Utils.getRecordTypeMapIdByDeveloperName(Account.SObjectType);
    System.assert(!mapRT.isEmpty(), 'No record type found');

    //Set<Id> queueUsers = Utils.getQueueUsers(UserInfo.getUserId());
    //System.debug('>>>>> ALK - queueUsers : ' + queueUsers);

    String countryCode = Utils.getBUCode('BE');
    System.assert(countryCode == 'BENELUX', 'Error getting country code');

    String countryCode2 = Utils.getCountryCode('Belgium');
    System.assert(countryCode2 == 'BE', 'Error getting country code');

    Integer weekNumber = Utils.getWeekNumber(Date.today());
    System.assert(weekNumber > 0, 'Error calculating week number');

    Utils.logMessage(
      new List<Utils.LogMessage>{
        new Utils.LogMessage(UserInfo.getUserId(), 'someClass', 'someMethod', 'someType', 'someMessage')
      }
    );

    Map<Id, User> mapUsers = Utils.getUserMap();
    System.assert(!mapUsers.isEmpty(), 'No active user found');

    Map<Id, Group> groups = Utils.getQueueMap();
    System.assert(!groups.isEmpty(), 'No group user found');

    //Utils.getQueueIdByName();
    String sandboxName = Utils.getSandboxName();
    System.assert(String.isNotBlank(sandboxName), 'No name found');

    String sequence = Utils.getLastCustomerNumberSequence();
    System.assert(String.isNotBlank(sequence), 'No sequence generated');

    String npsDate = Utils.getNPSDateSurvey();
    System.assert(String.isNotBlank(npsDate), 'No npsDate returned');

    Boolean isMatch = Utils.dateTimeIsoMatcher('2023-01-10T13:45:56.000Z');
    System.assert(isMatch, 'Datetime not matching');

    Boolean isValidSFId18 = Utils.isValidSalesforceId(UserInfo.getUserId());
    System.assert(isValidSFId18, 'The SF Id is not valid');

    Boolean isValidSFId15 = Utils.isValidSalesforceId('00E6N000000klV2');
    System.assert(isValidSFId15, 'The SF Id is not valid');

    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'BELUX'];
    System.assert(ur != null, 'No role found');
    Map<Id, UserRole> subordinates = Utils.getRoleSubordinates(ur.Id);
    System.assert(!subordinates.isEmpty(), 'No subordinate role found');

    String uniqueTxt = Utils.generateUniqueString(Constants.TYPE_STRING, 10);
    System.assert(uniqueTxt != null, 'No unique text generated');

    String uniqueNumber = Utils.generateUniqueString(Constants.TYPE_INTEGER, 10);
    System.assert(uniqueNumber != null, 'No unique text generated');

    Test.stopTest();
  }
}