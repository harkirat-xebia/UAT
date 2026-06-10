public class APER16_StoreAddressController {
  public class StorePopUp {
    public String oId { get; set; }
    public String sStreet { get; set; }
    public String sPostalCode { get; set; }
    public String sProvince { get; set; }
    public String sCity { get; set; }
    public Decimal sLat { get; set; }
    public Decimal sLong { get; set; }
    public String sCountry { get; set; }
    public String sCountryCode { get; set; }
  }
  @AuraEnabled
  public static string getAddressAutoComplete(String input) {
    String url =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=' +
      EncodingUtil.urlEncode(input, 'UTF-8') +
      '&key=' +
      APER16_StoreAddressController.getGoogleMapsAPIKey() +
      '&libraries=places';
    system.debug('AutoComplete JSON: ' + APER16_StoreAddressController.getHttp(url));
    return APER16_StoreAddressController.getHttp(url);
  }
  @AuraEnabled
  public static string getAddressDetails(String placeid) {
    String url =
      'https://maps.googleapis.com/maps/api/place/details/json?placeid=' +
      placeid +
      '&key=' +
      APER16_StoreAddressController.getGoogleMapsAPIKey();
    system.debug('GetAddressDetails JSON : ' + APER16_StoreAddressController.getHttp(url));
    return APER16_StoreAddressController.getHttp(url);
  }
  @AuraEnabled
  public static String getHttp(String url) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    req.setMethod('GET');
    req.setEndpoint(url);
    HTTPResponse res = http.send(req);
    system.debug('KHAD test address : ' + res.getBody());
    return res.getBody();
  }
  @AuraEnabled
  public static String getGoogleMapsAPIKey() {
    return label.LABS_SF_GOOGLE_API_KEY;
  }

  @AuraEnabled
  public static String getAccountDetails(String aFCId) {
    String accId = [SELECT Id, ER_Account_Name__c FROM ER_Financial_Center__c WHERE Id = :aFCId LIMIT 1]
    ?.ER_Account_Name__c;
    System.debug('accId ' + accId);
    return accId;
  }

  @AuraEnabled
  public static ER_Store__c updateStore(String sJson) {
    system.debug('sJson : ' + sJson);
    StorePopUp oPopUp = (StorePopUp) JSON.deserialize(sJson, StorePopUp.class);
    system.debug('oPopUp : ' + oPopUp);
    List<ER_Store__c> oList = [
      SELECT
        Id,
        ER_Street__c,
        ER_Zip_Code__c,
        ER_State_Province__c,
        ER_City__c,
        ER_Country__c,
        ER_Latitude_Longitude__Latitude__s,
        ER_Latitude_Longitude__Longitude__s
      FROM ER_Store__c
      WHERE Id = :oPopUp.oId
    ];

    oList[0].ER_Street__c = oPopUp.sStreet;
    oList[0].ER_Zip_Code__c = oPopUp.sPostalCode;
    oList[0].ER_State_Province__c = oPopUp.sProvince;
    oList[0].ER_City__c = oPopUp.sCity;
    oList[0].ER_Latitude_Longitude__Latitude__s = oPopUp.sLat;
    oList[0].ER_Latitude_Longitude__Longitude__s = oPopUp.sLong;
    oList[0].ER_Country__c = oPopUp.sCountry;
    oList[0].ER_Country_Code__c = oPopUp.sCountryCode;
    update oList;

    return oList[0];
  }
}