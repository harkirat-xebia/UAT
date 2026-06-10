/*
----------------------------------------------------------------------
-- - Name          : WSER11_PL_PublicRegister
-- - Author        : Noor
-- - Description   : Webservice to call public register for Poland

-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 23-JUN-2021  Noor                 1.0         Initial version

---------------------------------------------------------------------------------------

*/
public with sharing class WSER11_PL_PublicRegister {
  /**
   * @author Noor
   * @date 23/06/2021
   * @description - Get account Info from public register
   *
   * @param registrationNumber Existing registration number on the Account or Lead
   * @return return a wrapper that contains all info need
   *
   */
  public static WSERPL11_Response_Wrapper queryAccountInfo(String identificationNumber) {
    String response;

    WSERPL11_Response_Wrapper wrapper = new WSERPL11_Response_Wrapper();

    //Make second call to obtain the result
    if (String.isNotBlank(identificationNumber))
      response = getDataFromIdentificationNumber(identificationNumber);
    else
      throw new ApplicationException(Label.WSER11_Identification_Number_Not_Found);

    if (String.isNotBlank(response))
      wrapper = populateWrapper(response);
    else
      throw new ApplicationException(Label.WSER11_Webservice_Error);

    if (new List<String>{ 'in_progress', 'quened' }.contains(wrapper.status))
      wrapper.message = 'in_progress';

    if (wrapper.status.equals('error'))
      throw new ApplicationException(wrapper.message);

    return wrapper;
  }

  /**
   * @author Noor
   * @date 23/06/2021
   * @description - Convert JSON to wrapper class
   * @param jsonData json data obtain from Webservice
   *
   * @return return a wrapper that contains all info need
   */
  public static WSERPL11_Response_Wrapper populateWrapper(String jsonData) {
    JSONParser parser = JSON.createParser(jsonData);
    WSERPL11_Response_Wrapper wrapper = new WSERPL11_Response_Wrapper();
    wrapper.message = '';
    while (parser.nextToken() != null) {
      if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
        if (parser.getText().equals('relation'))
          break; //stop parser when we  reach relation tag as we did not need to parse all the json
        if (parser.getText().equals('court')) {
          parser.nextToken();
          parser.nextToken();
          parser.nextToken();
        } //Skip this tag, as it contain duplicate field name
        if (parser.getText() != null && parser.getText().equals('name')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.name = trimSpecialChar(parser.getText());
        }
        if (parser.getText() != null && parser.getText().equals('legal_form')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.legal_form = trimSpecialChar(parser.getText());
        }
        if (parser.getText() != null && parser.getText().equals('nip')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.nip = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('krs')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.krs = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('regon')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.regon = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('street')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.street = trimSpecialChar(parser.getText());
        }
        if (parser.getText() != null && parser.getText().equals('number')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.streetNumber = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('postcode')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.postcode = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('city')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.city = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('country')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.country = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('email')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.email = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('www')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.www = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('pkd')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.pkd = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('representation')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.representation = trimSpecialChar(parser.getText());
        }
        if (parser.getText() != null && parser.getText().equals('status')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.status = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('error_message')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.message = parser.getText();
        }
        if (parser.getText() != null && parser.getText().equals('phone')) {
          parser.nextToken();
          if (isNotNull(parser.getText()))
            wrapper.phone = parser.getText();
        }
      }
    }
    System.debug('wrapper : ' + wrapper);
    return wrapper;
  }

  /**
   * @author Noor
   * @date 23/06/2021
   * @description Make a first call to ODPIS KRS Json to obtain an identification number
   * @param registrationNumber
   *
   * @return the identification number (format example '3c4a88e4-e4b0-4af2-914b-be91a2df32c7') used to perform second call.
   */
  public static String getJobIdentificationNumber(String registrationNumber) {
    Http http = new Http();
    String identification;
    try {
      String key = Utils.getGlobalSettingsValueFromKey('ERPL_WebserviceKey');
      HttpRequest req = getPOSTRequest('callout:ERPL_Transparent_data_api/' + key + '/add', 'POST');
      req.setBody(
        '{  \n' +
        '   "source":"krs",\n' +
        '   "method":"data",\n' +
        '   "params":{  \n' +
        '      "nip":"' +
        registrationNumber +
        '",\n' +
        '      "timeout": 1\n' +
        '   }\n' +
        '}'
      );
      System.debug('WSER11_PL_PublicRegister initiateFirstResponse - requestBody : ' + req.getBody());
      HttpResponse res = http.send(req);
      String jsonResp = res.getBody();

      System.debug('WSER11_PL_PublicRegister initiateFirstResponse - jsonResp : ' + jsonResp);

      Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonResp);

      System.debug('getJobIdentificationNumber : ' + m.get('status') + ' ' + m.get('message'));

      if (m.get('status').equals('error'))
        throw new ApplicationException(m.get('message').toString());

      identification = (String) m.get('ident');

      //Make a first call to ODPIS KRS Json to obtain an identification number
      if (String.isBlank(identification))
        throw new ApplicationException(Label.WSER11_Registration_Number_Not_Found);
    } catch (Exception e) {
      System.debug('>>>> getJobIdentificationNumber - Line ' + e.getLineNumber() + ' - Error :  ' + e.getMessage());
      throw e;
    }

    return identification;
  }
  public static boolean isNotNull(String value) {
    return String.isNotBlank(value) && value != 'null';
  }

  public static String trimSpecialChar(String value) {
    return value.replaceAll('"', '');
  }

  /**
   * @author Noor
   * @date 23/06/2021
   * @description Make a second call to obtain the data
   * @param identificationNumber the identification number (format example '3c4a88e4-e4b0-4af2-914b-be91a2df32c7') used to perform second call
   *
   * @return a json with all the data
   */
  public static String getDataFromIdentificationNumber(String identificationNumber) {
    Http http = new Http();
    String jsonResp;

    try {
      String key = Utils.getGlobalSettingsValueFromKey('ERPL_WebserviceKey');
      HttpRequest req = getPOSTRequest(
        'callout:ERPL_Transparent_data_api/' +
        key +
        '/result?ident=' +
        identificationNumber,
        'GET'
      );
      HttpResponse res = http.send(req);

      jsonResp = res.getBody();
      System.debug('WSER11_PL_PublicRegister - jsonResp : ' + jsonResp);
    } catch (Exception e) {
      System.debug('>>>> getAccountInfo - Line ' + e.getLineNumber() + ' - Error :  ' + e.getMessage());
      throw e;
    }

    return jsonResp;
  }

  /**
   * @author Noor
   * @date 25/06/2021
   * @description This method is used to instantiate and set up the request
   *
   * @return
   */
  public static HttpRequest getPOSTRequest(String namedCredential, String method) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(namedCredential);
    //header of the request
    req.setHeader('content-type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setHeader('Application', 'sfdc');
    req.setMethod(method);
    return req;
  }

  /**
   * Inner wrapper class used to output data in Lightning component
   */
  public class WSERPL11_Response_Wrapper {
    @AuraEnabled
    public String name { get; set; } //company name
    @AuraEnabled
    public String legal_form { get; set; }
    @AuraEnabled
    public String nip { get; set; } //Tax Identification Number
    @AuraEnabled
    public String krs { get; set; } //Company Number
    @AuraEnabled
    public String regon { get; set; }
    @AuraEnabled
    public String street { get; set; }
    @AuraEnabled
    public String streetNumber { get; set; }
    @AuraEnabled
    public String postcode { get; set; }
    @AuraEnabled
    public String city { get; set; }
    @AuraEnabled
    public String country { get; set; }
    @AuraEnabled
    public String email { get; set; }
    @AuraEnabled
    public String www { get; set; } //website
    @AuraEnabled
    public String pkd { get; set; } //Nace code
    @AuraEnabled
    public String representation { get; set; } //nace text
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String message { get; set; } //message in case of errors
    //@AuraEnabled
    //public String NumberOfEmployees { get; set; } //not present in Webservice
    @AuraEnabled
    public String phone { get; set; } //not present in Webservice
    //@AuraEnabled
    //public String SubjectToVAT { get; set; } //not present in Webservice

    public WSERPL11_Response_Wrapper() {
      this.name = '';
      this.legal_form = '';
      this.nip = '';
      this.krs = '';
      this.regon = '';
      this.street = '';
      this.streetNumber = '';
      this.postcode = '';
      this.city = '';
      this.country = '';
      this.email = '';
      this.www = '';
      this.pkd = '';
      this.representation = '';
      this.status = '';
      this.phone = '';
    }
  }
}