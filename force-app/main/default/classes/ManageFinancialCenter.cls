/**
 * Created by Saad on 19/06/2023.
 */

public with sharing class ManageFinancialCenter {
  @AuraEnabled
  public static Map<String, String> getFinancialCenterInfos(String financialCenterId) {
    return ManageFinancialCenterWOS.getFinancialCenterInfos(financialCenterId);
  }

  @AuraEnabled
  public static void updateFinancialCenter(
    Boolean updatedContact,
    Boolean updatedMainInfos,
    String companyInfosJSON,
    String financialCenterId
  ) {
    UtilsBypass.setBypassedTriggersByApex(new Set<String>{ 'updateContactRoleUpdate' });
    ManageFinancialCenterWOS.updateFinancialCenter(
      updatedContact,
      updatedMainInfos,
      companyInfosJSON,
      financialCenterId
    );
  }

  @AuraEnabled
  public static void createFinancialCenter(String companyInfosJSON, String scope) {
    //UtilsBypass.setBypassedTriggersByApex(new Set<String>{'updateContactRoleUpdate'});
    //UtilsBypass.setBypassedTriggersByApex(new Set<String>{'CreatePrimaryContactRole'});
    //UtilsBypass.setBypassedTriggersByApex(new Set<String>{'FinancialCenterTrigger'});
    ManageFinancialCenterWOS.createFinancialCenter(companyInfosJSON, scope);
  }

  @AuraEnabled
  public static String getMainContactInfos(String crn) {
    return ManageFinancialCenterWOS.getMainContactInfos(crn);
  }

  @AuraEnabled
  public static List<Map<String, String>> getFinCentersInfosByCRN(String crn, String scope) {
    return ManageFinancialCenterWOS.getFinCentersInfosByCRN(crn, scope);
  }

  @AuraEnabled
  public static List<Map<String, Object>> getFcStoresInfos(String fcId, String locale) {
    return ManageFinancialCenterWOS.getFcStoresInfos(fcId, locale);
  }
}