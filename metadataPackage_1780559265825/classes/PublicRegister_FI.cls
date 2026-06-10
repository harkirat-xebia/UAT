/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Implementation of public register for Finland
   @see           : PublicRegister
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--18/12/2022    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class PublicRegister_FI implements PublicRegisterInterface {
  public static String FIELD_TO_QUERY = 'company_name,business_id,form_of_company,staff_number,staff_number,status,vat_number,address,city,postal';

  public String getWebserviceResponse(String searchStr) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:PublicRegisterFI/?country=FI&fields=' + FIELD_TO_QUERY + '&business_id=' + searchStr);
    req.setMethod('GET');
    Http http = new Http();
    HttpResponse res = http.send(req);
    if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', searchStr));
    System.debug(res.getBody());
    return res.getBody();
  }

  public Map<String, String> mapResponse(String json) {
    PublicRegisterParserFI parser = PublicRegisterParserFI.parse(json);
    Map<String, String> fields = new Map<String, String>();

    System.debug('NGO Parser FI:' + parser);
    if (parser.results.isEmpty())
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', ''));
    for (PublicRegisterParserFI.Results sc : parser.results) {
      fields.put('Name', sc.company_name);
      fields.put('Company', sc.company_name);
      fields.put('ER_Registration_Number__c', sc.business_id);
      fields.put('ER_Legal_Form__c', sc.form_of_company);
      fields.put('ER_Employee_Size_Range__c', sc.staff_number);
      if (String.isNotBlank(sc.status))
        fields.put('ER_Legal_Status__c', sc.status.capitalize());
      fields.put('ER_VAT_Number__c', sc.vat_number);

      fields.put('BillingStreet', sc.address);
      fields.put('BillingCity', sc.city);
      fields.put('BillingPostalCode', sc.postal);
      fields.put('BillingCountry', 'Finland');
      fields.put('ER_Country_Code__c', 'Fi');

      fields.put('Street', sc.address);
      fields.put('City', sc.city);
      fields.put('PostalCode', sc.postal);
      fields.put('Country', 'Finland');
      fields.put('ER_Country_Code__c', 'Fi');

      fields.put('ER_Legal_Street__c', sc.address);
      fields.put('ER_Legal_City__c', sc.city);
      fields.put('ER_Legal_Zip_Code__c', sc.postal);
      fields.put('ER_Legal_Country__c', 'Finland');
      fields.put('ER_Legal_Country_Code__c', 'Fi');
    }

    return fields;
  }

  public Map<String, String> getFieldsToDisplay(String type) {
    List<String> values = new List<String>();

    if (type == Constants.ACCOUNT)
      values = Utils.splitValues(
        Utils.getGlobalSettingsValueFromKeyBySOQL(Constants.PUBLIC_REGISTER_FIELDS_ACCOUNT_FI)
      );
    else
      values = Utils.splitValues(Utils.getGlobalSettingsValueFromKeyBySOQL(Constants.PUBLIC_REGISTER_FIELDS_LEAD_FI));

    return Utils.splitKeyPairValues(values, Constants.DELIMITER_HASH);
  }
  public void addError(SObject sObj) {
  }
}