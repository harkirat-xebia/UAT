/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Implementation of public register for France
   @see           : PublicRegister
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--18/12/2022    Noor                 1.0         Initial version
--08/08/2023    Malha AMEUR          1.1         COUL-4629 - [ERFR] Update the get Public register mapping to add legal name
---------------------------------------------------------------------------------------
*/
public with sharing class PublicRegister_FR implements PublicRegisterInterface {
  /**
   * @see PublicRegister.getWebserviceResponse
   * @param searchStr
   *
   * @return JSON from webservice
   */
  public String getWebserviceResponse(String searchStr) {
    HttpRequest req = new HttpRequest();
    //Use Named Credential
    req.setEndpoint('callout:PublicRegisterFR/v1/societes/rechercher');
    req.setMethod('GET');

    req.setBody(generateJSONBody(searchStr));
    Http http = new Http();
    HTTPResponse res = http.send(req);
    if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', searchStr));
    System.debug(res.getBody());
    return res.getBody();
  }

  /**
   * @description generate JSON Body to be sent to Webservice
   * @param searchStr
   *
   * @return
   */
  public String generateJSONBody(String searchStr) {
    JSONGenerator gen = JSON.createGenerator(true);

    gen.writeStartObject();
    gen.writeFieldName('filtresSociete');
    gen.writeStartArray();

    gen.writeStartObject();
    gen.writeStringField('valeur', searchStr);
    gen.writeStringField('cle', 'Siret');
    gen.writeEndObject();

    gen.writeEndArray();
    gen.writeEndObject();

    return gen.getAsString();
  }

  public Map<String, String> mapResponse(String json) {
    PublicRegisterParserFR parser = PublicRegisterParserFR.parse(json);
    Map<String, String> fields = new Map<String, String>();

    System.debug('NGO Parser FR:' + parser);

    for (PublicRegisterParserFR.Societes sc : parser.societes) {
      fields.put('Name', sc.nom);
      fields.put('Company', sc.nom);
      fields.put('ER_Legal_Name__c',sc.nom);
      fields.put('ER_Legal_Form__c', sc.categorieJuridique);
      fields.put('ER_Employee_Size_Range__c', sc.trancheEffective);
      if (sc.siretActif == 'oui')
        fields.put('ER_Legal_Status__c', 'Active');
      if (sc.siretActif == 'non')
        fields.put('ER_Legal_Status__c', 'Closed');

      fields.put('ER_VAT_Number__c', sc.numeroTVA);

      fields.put('BillingStreet', sc.adresse1 + ' ' + sc.adresse2 + ' ' + sc.adresse3);
      fields.put('BillingCity', sc.ville);
      fields.put('BillingPostalCode', sc.codePostal);
      fields.put('BillingCountry', 'France');
      fields.put('ER_Country_Code__c', 'Fr');

      fields.put('Street', sc.adresse1 + ' ' + sc.adresse2 + ' ' + sc.adresse3);
      fields.put('City', sc.ville);
      fields.put('PostalCode', sc.codePostal);
      fields.put('Country', 'France');
      fields.put('ER_Country_Code__c', 'Fr');

      fields.put('ER_Legal_Street__c', sc.adresse1 + ' ' + sc.adresse2 + ' ' + sc.adresse3);
      fields.put('ER_Legal_City__c', sc.ville);
      fields.put('ER_Legal_Zip_Code__c', sc.codePostal);
      fields.put('ER_Legal_Country__c', 'France');
      fields.put('ER_Legal_Country_Code__c', 'Fr');
      fields.put('ER_NaceList__c', sc.naf08);
    }

    return fields;
  }

  public Map<String, String> getFieldsToDisplay(String type) {
    List<String> values = new List<String>();

    if (type == Constants.ACCOUNT)
      values = Utils.splitValues(
        Utils.getGlobalSettingsValueFromKeyBySOQL(Constants.PUBLIC_REGISTER_FIELDS_ACCOUNT_FR)
      );
    else
      values = Utils.splitValues(Utils.getGlobalSettingsValueFromKeyBySOQL(Constants.PUBLIC_REGISTER_FIELDS_LEAD_FR));

    return Utils.splitKeyPairValues(values, Constants.DELIMITER_HASH);
  }
  public void addError(SObject sObj) {
  }
}