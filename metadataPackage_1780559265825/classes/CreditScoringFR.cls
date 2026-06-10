/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Service which retrieves credit information for a specified list of records in Salesforce,
                    either Accounts or Leads, by making a REST API call to a third-party service (CreditSafe) using the specified registration number.
                    The received credit information is then used to update the corresponding records in Salesforce.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--11/02/2023    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

public with sharing class CreditScoringFR implements CreditScoringInterface {
  /**
   * @see CreditScoringInterface.callWebserviceAndUpdateRecords
   *
   */
  public static String callWebserviceAndUpdateRecords(Id sObjectId) {
    String type = Utils.getSObjectType(sObjectId);
    String registrationNumber = getRegistrationNumber(sObjectId, type);
    String token = getToken();
    String companyId = searchCompanyByRegistrationNumber(registrationNumber, token);
    String json = searchCompanyReportById(companyId, token);
    CreditSafeReport report = CreditSafeReport.parse(json);

    if (
      report.report != null &&
      report.report.companySummary != null &&
      report.report.companySummary.creditRating != null
    )
      return updateRecords(sObjectId, type, report);
    else
      throw new ApplicationException(Label.LAB_SF_CREDIT_RATING_NOT_FOUND.replace('{0}', registrationNumber));
  }

  /**
   * @date 12/02/2023
   * @description Get token from CreditSafe Webservice (Authentication)
   * @return token
   */
  public static String getToken() {
    HttpRequest req = new HttpRequest();
    //Use Named Credential
    req.setEndpoint('callout:CreditSafeConnect/v1/authenticate');
    req.setMethod('POST');
    req.setBody(getCredentials());
    Http http = new Http();

    HttpResponse res = http.send(req);
    if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData);
    Map<String, Object> mapJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    String token = (String) mapJson.get('token');

    return token;
  }

  /**
   * @date 12/02/2023
   * @description get Credentials in JSON format
   * @param searchStr
   *
   * @return
   */
  public static String getCredentials() {
    return Utils.getGlobalSettingsValueFromKey('CREDIT_SAFE_FR_CREDENTIAL');
  }

  /**
   * @date 12/02/2023
   * @description search Company By Registration Number (1st callout)
   * @param registrationNumber existing registration number
   * @param token
   *
   * @return company Id used by credit Safe
   */
  public static String searchCompanyByRegistrationNumber(String registrationNumber, String token) {
    HttpRequest req = new HttpRequest();
    //Use Named Credential
    req.setEndpoint(
      'callout:CreditSafeConnect/v1/companies?page=1&pageSize=5&language=en&regNo=' +
      registrationNumber +
      '&countries=fr'
    );
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + token);
    Http http = new Http();
    HttpResponse res = http.send(req);
    if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', registrationNumber));
    System.debug(res.getBody());

    CreditSafeCompanies csCompanies = CreditSafeCompanies.parse(res.getBody());
    if (csCompanies.companies.isEmpty())
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', registrationNumber));

    return csCompanies.companies[0].id;
  }

  /**
   * @date 12/02/2023
   * @description search Company By Registration Number (2nd callout)
   * @param companyId creditSafe company Id
   * @param token
   *
   * @return company Id used by credit Safe
   */
  public static String searchCompanyReportById(String companyId, String token) {
    HttpRequest req = new HttpRequest();
    //Use Named Credential
    req.setEndpoint('callout:CreditSafeConnect/v1/companies/' + companyId + '?language=fr');
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + token);
    Http http = new Http();
    HttpResponse res = http.send(req);
    if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', companyId));

    return res.getBody();
  }

  /**
   * @date 12/02/2023
   * @description Update record (lead or account) with the credit scoring fields
   * @param sObjectId
   * @param type
   * @param creditSafe
   *
   * @return database result else throw exception
   */
  public static String updateRecords(Id sObjectId, String type, CreditSafeReport creditSafe) {
    List<SObject> objects = new List<SObject>();
    String results;

    if (type == Constants.ACCOUNT) {
      Account a = new Account(Id = sObjectId, ER_Last_Credit_Scoring_Update__c = Date.today());
      if (creditSafe.report.companySummary.creditRating.creditLimit.value.isNumeric())
        a.ER_Credit_Limit__c = Decimal.valueOf(creditSafe.report.companySummary.creditRating.creditLimit.value);
      if (creditSafe.report.companySummary.creditRating.providerValue.value.isNumeric())
        a.ER_Credit_Scoring__c = Decimal.valueOf(creditSafe.report.companySummary.creditRating.providerValue.value);
      a.ER_ProviderDescription__c = creditSafe.report.companySummary.creditRating.providerDescription;
      objects.add(a);
    } else {
      Lead l = new Lead(Id = sObjectId, ER_Last_Credit_Scoring_Update__c = Date.today());
      if (creditSafe.report.companySummary.creditRating.creditLimit.value.isNumeric())
        l.ER_Credit_Limit__c = Decimal.valueOf(creditSafe.report.companySummary.creditRating.creditLimit.value);
      if (creditSafe.report.companySummary.creditRating.providerValue.value.isNumeric())
        l.ER_Credit_Scoring__c = Decimal.valueOf(creditSafe.report.companySummary.creditRating.providerValue.value);
      l.ER_ProviderDescription__c = creditSafe.report.companySummary.creditRating.providerDescription;
      objects.add(l);
    }

    List<Database.SaveResult> sr = Database.update(objects);

    for (Database.SaveResult result : sr) {
      if (result.isSuccess())
        results = 'Account ' + result.getId() + ' updated successfully';
      else
        throw new ApplicationException(
          'Error updating account ' +
          result.getId() +
          ': ' +
          result.getErrors()[0].getMessage()
        );
    }

    return results;
  }

  /**
   * @date 12/02/2023
   * @description get Credentials in JSON format
   * @param id sobject Id
   * @param type object type
   * @return registration number
   */
  private static String getRegistrationNumber(Id id, String type) {
    String registrationNumber;

    if (type == Constants.ACCOUNT) {
      Account ac = [SELECT Id, ER_BUPicklist__c, ER_Registration_Number__c FROM Account WHERE Id = :id];
      registrationNumber = ac.ER_Registration_Number__c;
    } else {
      Lead l = [SELECT Id, ER_BUPicklist__c, ER_Registration_Number__c FROM Lead WHERE Id = :id];
      registrationNumber = l.ER_Registration_Number__c;
    }
    return registrationNumber;
  }
}