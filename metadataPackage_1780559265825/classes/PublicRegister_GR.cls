/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Implementation of public register for Greece
   @see           : PublicRegister
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--11/05/2023    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class PublicRegister_GR implements PublicRegisterInterface {
  /**
   * @author Noor
   * @date 15/05/2023
   * @see PublicRegister.getWebserviceResponse
   * @param searchStr
   *
   * @return JSON from webservice
   */
  public String getWebserviceResponse(String searchStr) {
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:' + Constants.PUBLIC_REGISTER_WEBSERVICE_GR);
    req.setHeader('Content-Type', 'text/xml');
    req.setBody(
      '<?xml version="1.0" encoding="UTF-8"?> <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" ' +
      'xmlns:ns="http://gr/gsis/rgwspublic/RgWsPublic.wsdl" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
      'xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ns1="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-' +
      'wssecurity-secext-1.0.xsd"> <env:Header> <ns1:Security> <ns1:UsernameToken> ' +
      '<ns1:Username>{!$Credential.UserName}</ns1:Username>' +
      ' <ns1:Password>{!$Credential.Password}</ns1:Password> </ns1:UsernameToken> </ns1:Security> </env:Header> <env:Body> ' +
      '<ns:rgWsPublicAfmMethod> <RgWsPublicInputRt_in xsi:type="ns:RgWsPublicInputRtUser">' +
      ' <ns:afmCalledBy></ns:afmCalledBy>' +
      ' <ns:afmCalledFor>' +
      searchStr +
      ' </ns:afmCalledFor>' +
      ' </RgWsPublicInputRt_in> <RgWsPublicBasicRt_out xsi:type="ns:RgWsPublicBasicRtUser"> <ns:afm xsi:nil="true"/> ' +
      '<ns:stopDate xsi:nil="true"/> <ns:postalAddressNo xsi:nil="true"/> <ns:doyDescr xsi:nil="true"/> <ns:doy xsi:nil="true"/> ' +
      ' <ns:onomasia xsi:nil="true"/> <ns:legalStatusDescr xsi:nil="true"/> <ns:registDate xsi:nil="true"/> ' +
      '<ns:deactivationFlag xsi:nil="true"/> <ns:deactivationFlagDescr xsi:nil="true"/> <ns:postalAddress xsi:nil="true"/> ' +
      '<ns:firmFlagDescr xsi:nil="true"/> <ns:commerTitle xsi:nil="true"/> <ns:postalAreaDescription xsi:nil="true"/> ' +
      '<ns:INiFlagDescr xsi:nil="true"/> <ns:postalZipCode xsi:nil="true"/> </RgWsPublicBasicRt_out>' +
      ' <arrayOfRgWsPublicFirmActRt_out xsi:type="ns:RgWsPublicFirmActRtUserArray"/> <pCallSeqId_out xsi:type="xsd:decimal">' +
      '0</pCallSeqId_out> <pErrorRec_out xsi:type="ns:GenWsErrorRtUser"> <ns:errorDescr xsi:nil="true"/>' +
      ' <ns:errorCode xsi:nil="true"/> </pErrorRec_out> </ns:rgWsPublicAfmMethod> </env:Body> </env:Envelope> '
    );

    req.setMethod('POST');
    req.setTimeout(120000);
    HttpResponse res;
    res = http.send(req);
    System.debug('NGO response' + res.getBody());
    return res.getBody();
  }

  /**
   * @author Noor
   * @date 15/05/2023
   * @see PublicRegister.mapResponse
   * @param json
   *
   * @return Map of field values
   */
  public Map<String, String> mapResponse(String json) {
    PublicAfmMethodResponse response = parse(json);

    if (String.isNotBlank(response.errorDescr))
      throw new ApplicationException(response.errorDescr);
    Map<String, String> fields = new Map<String, String>();
    fields.put('Name', response.onomasia);
    fields.put('Company', response.onomasia);
    fields.put('ER_Legal_Name__c', response.commerTitle);
    fields.put('ER_Tax_Office__c', response.doyDescr);

    if (response.firmFlagDescr.trim().equalsIgnoreCase('ΕΠΙΤΗΔΕΥΜΑΤΙΑΣ'))
      fields.put('ER_Legal_Status__c', 'Active');

    if (response.firmFlagDescr.trim().equalsIgnoreCase('ΠΡΩΗΝ ΕΠΙΤΗΔΕΥΜΑΤΙΑΣ'))
      fields.put('ER_Legal_Status__c', 'Closed');

    fields.put('BillingStreet', response.postalAddressNo + response.postalAddress);
    fields.put('BillingCity', response.postalAreaDescription);
    fields.put('BillingPostalCode', response.postalZipCode);
    fields.put('BillingCountry', 'Greece');
    fields.put('ER_Country_Code__c', 'GR');

    fields.put('Street', response.postalAddressNo + ' ' + response.postalAddress);
    fields.put('City', response.postalAreaDescription);
    fields.put('PostalCode', response.postalZipCode);
    fields.put('Country', 'Greece');
    fields.put('ER_Country_Code__c', 'GR');

    fields.put('ER_Legal_Street__c', response.postalAddressNo + ' ' + response.postalAddress);
    fields.put('ER_Legal_City__c', response.postalAreaDescription);
    fields.put('ER_Legal_Zip_Code__c', response.postalZipCode);
    fields.put('ER_Legal_Country__c', 'Greece');
    fields.put('ER_Legal_Country_Code__c', 'GR');

    if (!response.activities.isEmpty()) {
      for (RgWsPublicFirmActRtUser nace : response.activities) {
        if (String.isNotBlank(nace.firmActDescr) && nace.firmActKind == '1') {
          fields.put('ER_NaceNameList__c', nace.firmActDescr);
          fields.put('ER_NaceList__c', nace.firmActCode);
        }
      }
    }
    return fields;
  }

  /**
   * @author Noor
   * @date 15/05/2023
   * @description @see PublicRegister.getFieldsToDisplay
   * @param type
   *
   * @return Map of field definition
   */
  public Map<String, String> getFieldsToDisplay(String type) {
    List<String> values = new List<String>();

    if (type == Constants.ACCOUNT)
      values = Utils.splitValues(
        Utils.getGlobalSettingsValueFromKeyBySOQL(Constants.PUBLIC_REGISTER_FIELDS_ACCOUNT_GR)
      );
    else
      values = Utils.splitValues(Utils.getGlobalSettingsValueFromKeyBySOQL(Constants.PUBLIC_REGISTER_FIELDS_LEAD_GR));

    return Utils.splitKeyPairValues(values, Constants.DELIMITER_HASH);
  }

  /**
   * @author Noor
   * @date 15/05/2023
   * @description Parse the response from the webservice to the wrapper class PublicAfmMethodResponse
   * @param response from Public Afm Method
   *
   * @return PublicAfmMethodResponse wrapper
   */
  private PublicAfmMethodResponse parse(String response) {
    PublicAfmMethodResponse rsp = new PublicAfmMethodResponse();
    Dom.Document doc = new Dom.Document();
    doc.load(response);
    Dom.XMLNode mainEnv = doc.getRootElement();
    Dom.XMLNode envBody = mainEnv.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
    Dom.XmlNode rgWsPublicAfmMethodResponse = envBody.getChildElement(
      'rgWsPublicAfmMethodResponse',
      'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
    );
    Dom.XmlNode pErrorRec_out = rgWsPublicAfmMethodResponse.getChildElement('pErrorRec_out', null);
    rsp.errorDescr = pErrorRec_out.getChildElement('errorDescr', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl').getText();
    rsp.errorCode = pErrorRec_out.getChildElement('errorCode', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl').getText();
    Dom.XmlNode RgWsPublicBasicRt_out = rgWsPublicAfmMethodResponse.getChildElement('RgWsPublicBasicRt_out', null);
    rsp.afm = RgWsPublicBasicRt_out.getChildElement('afm', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl').getText();
    rsp.stopDate = RgWsPublicBasicRt_out.getChildElement('stopDate', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl')
      .getText();
    rsp.postalAddressNo = RgWsPublicBasicRt_out.getChildElement(
        'postalAddressNo',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.doyDescr = RgWsPublicBasicRt_out.getChildElement('doyDescr', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl')
      .getText();
    rsp.doy = RgWsPublicBasicRt_out.getChildElement('doy', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl').getText();
    rsp.onomasia = RgWsPublicBasicRt_out.getChildElement('onomasia', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl')
      .getText();
    rsp.legalStatusDescr = RgWsPublicBasicRt_out.getChildElement(
        'legalStatusDescr',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.registDate = RgWsPublicBasicRt_out.getChildElement('registDate', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl')
      .getText();
    rsp.deactivationFlag = RgWsPublicBasicRt_out.getChildElement(
        'deactivationFlag',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.deactivationFlagDescr = RgWsPublicBasicRt_out.getChildElement(
        'deactivationFlagDescr',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.postalAddress = RgWsPublicBasicRt_out.getChildElement(
        'postalAddress',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.firmFlagDescr = RgWsPublicBasicRt_out.getChildElement(
        'firmFlagDescr',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.commerTitle = RgWsPublicBasicRt_out.getChildElement('commerTitle', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl')
      .getText();
    rsp.postalAreaDescription = RgWsPublicBasicRt_out.getChildElement(
        'postalAreaDescription',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.INiFlagDescr = RgWsPublicBasicRt_out.getChildElement(
        'INiFlagDescr',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    rsp.postalZipCode = RgWsPublicBasicRt_out.getChildElement(
        'postalZipCode',
        'http://gr/gsis/rgwspublic/RgWsPublic.wsdl'
      )
      .getText();
    system.debug('rsp = ' + rsp);
    Dom.XmlNode firmActArray = rgWsPublicAfmMethodResponse.getChildElement('arrayOfRgWsPublicFirmActRt_out', null);
    rsp.activities = new List<RgWsPublicFirmActRtUser>();
    for (Dom.XMLNode fa : firmActArray.getChildElements()) {
      if (fa.getText() != null) {
        system.debug('fa.Name = ' + fa.getName() + ' ' + fa.getText());
        RgWsPublicFirmActRtUser act = new RgWsPublicFirmActRtUser();
        act.firmActDescr = fa.getChildElement('firmActDescr', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl').getText();
        act.firmActKind = fa.getChildElement('firmActKind', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl').getText();
        act.firmActKindDescr = fa.getChildElement('firmActKindDescr', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl')
          .getText();
        act.firmActCode = fa.getChildElement('firmActCode', 'http://gr/gsis/rgwspublic/RgWsPublic.wsdl').getText();
        rsp.activities.add(act);
      }
    }
    return rsp;
  }

  public class PublicAfmMethodResponse {
    public String afm { get; set; }
    public String stopDate { get; set; }
    public String postalAddressNo { get; set; }
    public String doyDescr { get; set; }
    public String doy { get; set; }
    public String onomasia { get; set; }
    public String legalStatusDescr { get; set; }
    public String registDate { get; set; }
    public String deactivationFlag { get; set; }
    public String deactivationFlagDescr { get; set; }
    public String postalAddress { get; set; }
    public String firmFlagDescr { get; set; }
    public String commerTitle { get; set; }
    public String postalAreaDescription { get; set; }
    public String INiFlagDescr { get; set; }
    public String postalZipCode { get; set; }
    public String errorCode { get; set; }
    public String errorDescr { get; set; }
    public List<RgWsPublicFirmActRtUser> activities { get; set; }
    public PublicAfmMethodResponse() {
    }
  }

  public class RgWsPublicFirmActRtUser {
    public String firmActDescr { get; set; }
    public String firmActKind { get; set; }
    public String firmActKindDescr { get; set; }
    public String firmActCode { get; set; }
    public RgWsPublicFirmActRtUser() {
    }
  }

  /**
   * @author Noor
   * @date 15/05/2023
   * @description Throw an exception if the status is not Active
   *
   * @param sObj
   */
  public void addError(SObject sObj) {
    /*Boolean isActive;

    if (sObj.getSObjectType().getDescribe().getName().equals(Constants.ACCOUNT))
      isActive = ((Account) sObj).ER_Legal_Status__c != null && ((Account) sObj).ER_Legal_Status__c.equals('Active');
    else if (sObj.getSObjectType().getDescribe().getName().equals(Constants.LEAD))
      isActive = ((Lead) sObj).ER_Legal_Status__c != null && ((Lead) sObj).ER_Legal_Status__c.equals('Active');

        if(!isActive) throw new ApplicationException(Label.LAB_SF_PublicRegister_Status_Inactive);*/
  }
}