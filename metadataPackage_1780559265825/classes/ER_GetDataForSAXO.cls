/**
 * @author : AAZ
 * @date : 10/05/2021
 * @desc : ER_GetDataForSAXO
 * @see ER_GetDataForSAXO
 */

@RestResource(UrlMapping='/getDataForSAXO/*')
global with sharing class ER_GetDataForSAXO {
  /**
   *@author AAZ
   * @date 07/05/2021
   * @description getDataForSAXO provides a REST endpoint that exposes the service to retrieve all FC linked to a BU that has been updated since a specific date
   * @example {{_endpoint}}/services/apexrest/getDataForSAXO?bu=BE&date=2021-05-11&account-type=affiliate
   * @return
   */
  @HttpGet
  global static SaxoStructureResponse doGet() {
    Set<Id> setFC = new Set<Id>();
    List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();
    Set<String> accountStatuses = new Set<String>{ 'Active', 'Inactive' };
    RestRequest req = RestContext.request;
    SaxoStructureResponse resp = new SaxoStructureResponse();

    String bu = req.params.get('bu');
    String dte = req.params.get('date');
    Datetime dateProcess = (String.isNotBlank(dte) && dte.contains('T')
      ? Datetime.valueOfGmt(dte.replace('T', ' '))
      : Date.valueOf(dte));
    String accountType = req.params.get('accountType');

    if (String.isNotBlank(bu) && dateProcess != null && String.isNotBlank(accountType)) {
      ////////////////////////////////////////////////
      // Accounts
      ////////////////////////////////////////////////
      Id companyRtId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);
      for (Account a : [
        SELECT Id, (SELECT Id FROM Financial_Centers__r)
        FROM Account
        WHERE
          ER_BUPicklist__c = :bu
          AND ER_Status__c IN :accountStatuses
          AND ER_Last_Modified_Date_Functional_User__c >= :dateProcess
          AND RecordTypeId = :companyRtId
        //WITH SECURITY_ENFORCED
      ]) {
        for (ER_Financial_Center__c fc : a.Financial_Centers__r)
          setFC.add(fc.Id);
      }

      ////////////////////////////////////////////////
      // Contacts
      ////////////////////////////////////////////////
      for (Contact c : [
        SELECT Id, (SELECT Id FROM Financial_Centers_Contact__r)
        FROM Contact
        WHERE
          ER_BUPicklist__c = :bu
          AND ER_Last_Modified_Date_Functional_User__c >= :dateProcess
          AND Account.ER_Status__c IN :accountStatuses
        //WITH SECURITY_ENFORCED
      ]) {
        for (ER_Financial_Center__c fc : c.Financial_Centers_Contact__r)
          setFC.add(fc.Id);
      }

      ////////////////////////////////////////////////
      // Bank Account
      ////////////////////////////////////////////////
      for (ER_Bank_Account__c ba : [
        SELECT Id, (SELECT Id FROM Financial_Centers_BankAccount__r)
        FROM ER_Bank_Account__c
        WHERE ER_Business_Unit__c = :bu AND ER_Last_Modified_Date_Functional_User__c >= :dateProcess
        //WITH SECURITY_ENFORCED
      ]) {
        for (ER_Financial_Center__c fc : ba.Financial_Centers_BankAccount__r)
          setFC.add(fc.Id);
      }

      ////////////////////////////////////////////////
      // Financial Centers
      ////////////////////////////////////////////////
      String type = (accountType.toUpperCase() == 'AFFILIATE' ? 'Merchant' : 'Client');
      for (ER_Financial_Center__c f : [
        SELECT
          Id,
          Name,
          ER_Street__c,
          ER_Zip_Code__c,
          ER_City__c,
          ER_State_Province__c,
          ER_Country__c,
          CurrencyIsoCode,
          ER_Type__c,
          ER_Bank_Account__r.ER_IBAN__c,
          ER_Card_Operational_System_ID__c,
          ER_Email__c,
          ER_Account_Name__c,
          ER_Account_Name__r.Name,
          ER_Account_Name__r.ER_Registration_Number__c,
          ER_Account_Name__r.ParentId,
          ER_Account_Name__r.ER_Legal_Name__c,
          ER_Account_Name__r.ER_Customer_Number__c,
          ER_Account_Name__r.ER_VAT_Number__c,
          ER_Account_Name__r.ER_Not_subject_to_VAT__c,
          ER_Account_Name__r.ER_Other_Fiscal_ID__c,
          ER_Account_Name__r.ER_Status__c,
          ER_Account_Name__r.ER_BUPicklist__c,
          ER_Account_Name__r.BillingStreet,
          ER_Account_Name__r.BillingPostalCode,
          ER_Account_Name__r.BillingCity,
          ER_Account_Name__r.ER_Country_Code__c,
          ER_Account_Name__r.BillingState,
          ER_Account_Name__r.BillingCountry,
          ER_Account_Name__r.BillingLongitude,
          ER_Account_Name__r.BillingLatitude,
          ER_Contact__c,
          ER_Contact__r.LastName,
          ER_Contact__r.FirstName,
          ER_Contact__r.Phone,
          ER_Contact__r.Fax,
          ER_Contact__r.Email,
          ER_Contact__r.ER_Language__c,
          ER_Invoicing_Street__c,
          ER_Invoicing_Zip_Code__c,
          ER_Invoicing_City__c,
          ER_Invoicing_Country_Code__c,
          ER_Invoicing_Country__c,
          ER_Bank_Account__r.ER_Bank_Account_Owner__c,
          ER_Bank_Account__r.Name,
          ER_Bank_Account__r.ER_SEPA_reference__c,
          ER_Bank_Account__r.ER_SEPA_start_date__c,
          ER_Bank_Account__r.ER_SEPA_end_date__c,
          ER_Bank_Account__r.ER_SEPA_active__c,
          ER_Bank_Account__r.ER_SEPA_Direct_Debit_Type__c
        FROM ER_Financial_Center__c
        WHERE
          ER_Account_Name__r.ER_Status__c IN :accountStatuses
          AND ER_Type__c = :type
          AND (Id IN :setFC
          OR (ER_Business_Unit__c = :bu
          AND ER_Last_Modified_Date_Functional_User__c >= :dateProcess))
        //WITH SECURITY_ENFORCED
      ]) {
        f.ER_Account_Name__r.ER_Legal_Name__c = (String.isBlank(f.ER_Account_Name__r.ER_Legal_Name__c)
          ? f.ER_Account_Name__r.Name
          : f.ER_Account_Name__r.ER_Legal_Name__c);
        financialCenters.add(f);
      }
      if (!financialCenters.isEmpty())
        resp.financialCenters = financialCenters;

      if (resp.financialCenters == null)
        resp.errorMessage = 'No data found';
    } else
      resp.errorMessage = 'Please check the inbound parameters';

    return resp;
  }

  global class SaxoStructureResponse {
    public List<ER_Financial_Center__c> financialCenters { get; set; }
    public String errorMessage { get; set; }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public SaxoStructureResponse() {
    }
  }
}