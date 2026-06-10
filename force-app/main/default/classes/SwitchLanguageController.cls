/**
 * @author : ALK
 * @date : 15/04/2021
 * @desc : SwitchLanguageController
 * @see SwitchLanguageController
 */

public with sharing class SwitchLanguageController {
  @AuraEnabled
  public static String updateUserLanguage(User usr) {
    try {
      update usr;
    } catch (Exception e) {
      System.debug(
        '>>>>> ALK - QuadientPortalLogin.addPortalUser Line ' +
        e.getLineNumber() +
        ' - Error :  ' +
        e.getMessage()
      );
      return e.getMessage();
    }
    return null;
  }

  @AuraEnabled(Cacheable=true)
  public static String getBULanguages() {
    User currentUser = UtilsBypass.getCurrentUser();
    String languages = Utils.getGlobalSettingsValueFromKey('SWITCH_LANGUAGE_' + currentUser.ER_Business_Unit__c);
    return (String.isBlank(languages)
      ? currentUser.get('labelLanguage') + ':' + currentUser.LanguageLocaleKey
      : languages);
  }
}