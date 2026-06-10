public with sharing class APHU06_CryptoTokenGeneration {
  /*
    ----------------------------------------------------------------------
    -- - Name          : APHU06_CryptoTokenGeneration
    -- - Author        : AAB
    -- - Description   : Process the WS Token generation and other security requirement        
    -- Maintenance History:
    --
    -- Date         Name                Version     Remarks 
    -- -----------  -----------         --------    ---------------------------------------
    -- 23-APR-2018  AAB                 1.0         Initial version
    -- 09-NOV-2018  OLA                 1.1         new header parameter (X-Client-Secret)
    -- 12-DEC-2018  OLA                 1.2         EDG Switch
    ---------------------------------------------------------------------------------------
    */

  public static final String xp_salesforce_clientSecret;
  public static final String xp_salesforce_endpoint; // = System.Label.LAB_SF_EndpointEDG_WS;
  public static final String xp_salesforce_clientId; // = System.Label.LAB_SF_Client_Id_WS;
  public static final String xp_salesforce_requester; // = System.Label.LAB_SF_Requester_WS;
  //public static final String xp_salesforce_hmacToken;// = System.Label.LAB_SF_Authorization_WS;
  public static final Decimal xp_salesforce_Time_Out;

  /*
   * OLA
   * 21.12.2018
   * Get the WS configuration from the custom Setting : CMER01_EDG_Webservice_Setting__mdt
   */

  public static CMER01_EDG_Webservice_Setting__mdt edgWsConfiguration {
    get {
      if (edgWsConfiguration == null) {
        try {
          edgWsConfiguration = [
            SELECT
              xp_salesforce_clientId__c,
              xp_salesforce_clientSecret__c,
              xp_salesforce_url__c,
              xp_salesforce_requester__c,
              xp_salesforce_Time_Out__c,
              sdx_xp_salesforce_clientId__c,
              sdx_xp_salesforce_clientSecret__c,
              sdx_xp_salesforce_url__c
            FROM CMER01_EDG_Webservice_Setting__mdt
            WHERE DeveloperName = :APER10_User_Management.userBU
          ];
        } catch (Exception e) {
          throw new CustomException(Label.LABS_SF_WS_SettingNotFilledEUROPE);
        }
      }

      return edgWsConfiguration;
    }
    set;
  }

  static {
    if (runningInASandbox()) {
      System.debug('SANDBOX CALL EDG');
      if (
        String.isBlank(edgWsConfiguration.sdx_xp_salesforce_clientSecret__c) ||
        String.isBlank(edgWsConfiguration.sdx_xp_salesforce_url__c) ||
        String.isBlank(edgWsConfiguration.sdx_xp_salesforce_clientId__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_requester__c) ||
        edgWsConfiguration.xp_salesforce_Time_Out__c == null
      ) {
        throw new CustomException(Label.LABS_SF_WS_SettingNotFilledEUROPESandbox);
      } else {
        xp_salesforce_clientSecret = edgWsConfiguration.sdx_xp_salesforce_clientSecret__c;
        xp_salesforce_endpoint = edgWsConfiguration.sdx_xp_salesforce_url__c;
        xp_salesforce_clientId = edgWsConfiguration.sdx_xp_salesforce_clientId__c;
        xp_salesforce_requester = edgWsConfiguration.xp_salesforce_requester__c;
        xp_salesforce_Time_Out = edgWsConfiguration.xp_salesforce_Time_Out__c;
      }
    } else {
      System.debug('PRODUCTION CALL EDG');
      if (
        String.isBlank(edgWsConfiguration.xp_salesforce_clientSecret__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_url__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_clientId__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_requester__c) ||
        edgWsConfiguration.xp_salesforce_Time_Out__c == null
      ) {
        throw new CustomException(Label.LABS_SF_WS_SettingNotFilledEUROPEProduction);
      } else {
        xp_salesforce_clientSecret = edgWsConfiguration.xp_salesforce_clientSecret__c;
        xp_salesforce_endpoint = edgWsConfiguration.xp_salesforce_url__c;
        xp_salesforce_clientId = edgWsConfiguration.xp_salesforce_clientId__c;
        xp_salesforce_requester = edgWsConfiguration.xp_salesforce_requester__c;
        xp_salesforce_Time_Out = edgWsConfiguration.xp_salesforce_Time_Out__c;
      }
    }
  }

  public static Boolean runningInASandbox() {
    return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
  }

  /* generate the HmacToken
   *
   */
  public static String getHmacToken(String apimethod, string body, String currentDate) {
    // encoded uri -- Ok
    String url = xp_salesforce_endpoint + apimethod;
    String uri = (EncodingUtil.urlEncode(url, 'UTF-8')).toLowerCase();

    Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(body));

    string paramvalue = EncodingUtil.convertToHex(hash);

    System.debug('--- Input data to calculate hmac:');
    System.debug('--- uri: ' + uri);
    System.debug('--- hashed body: ' + paramvalue);
    System.debug('--- requester: ' + xp_salesforce_requester);
    System.debug('--- requestDate: ' + currentDate);

    // Authentication encoded MAC -- Ok
    String rawHmac = uri + '#' + paramvalue + '#' + xp_salesforce_requester + '#' + currentDate;
    Blob encodedHmac = crypto.generateMac(
      'HmacSHA256',
      Blob.valueOf(rawHmac),
      Blob.valueOf(xp_salesforce_clientSecret)
    );

    String hmacToken = EncodingUtil.convertToHex(encodedHmac);

    System.debug('--- encoded hmacToken : ' + hmacToken);

    return hmacToken;
  }

  /* generate the HmacToken
   *
   */
  public static String getHmacTokenV3(String apimethod, String body, String nonce, String currentDate, String method) {
    // encoded uri -- Ok
    String url = xp_salesforce_endpoint + apimethod;
    String uri = (EncodingUtil.urlEncode(url, 'UTF-8')).toLowerCase();
    String sharedKey = '4fa9d3b008f6d5c679357b03444a9082';
    Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(body));

    string paramvalue = EncodingUtil.convertToHex(hash);

    System.debug('--- Input data to calculate hmac:');
    System.debug('--- uri: ' + uri);
    System.debug('--- nonce: ' + nonce);
    System.debug('--- hashed body: ' + paramvalue);
    System.debug('--- requester: ' + xp_salesforce_requester);
    System.debug('--- xp_salesforce_clientId: ' + xp_salesforce_clientId);
    System.debug('--- xp_salesforce_clientSecret: ' + xp_salesforce_clientSecret);
    System.debug('--- requestDate: ' + currentDate);

    String rawHmac = (xp_salesforce_clientId +
      method +
      uri +
      currentDate +
      nonce +
      xp_salesforce_requester +
      paramvalue)
      .toLowerCase();
    System.debug('--- encoded rawHmac : ' + rawHmac);
    Blob encodedHmac = Crypto.generateMac('HmacSHA256', Blob.valueOf(rawHmac), Blob.valueOf(sharedKey));
    String hmacToken = EncodingUtil.convertToHex(encodedHmac);

    System.debug('--- encoded hmacToken : ' + hmacToken);

    return hmacToken;
  }

  public static String getEncodedbody(String body) {
    String hashedBodybis = EncodingUtil.base64Encode(Blob.valueOf(body));
    Blob afterblobbis = EncodingUtil.base64Decode(hashedBodybis);

    return afterblobbis.toString();
  }

  public static HttpRequest getHttpRequest(
    String endpoint,
    string method,
    String hmacToken,
    String currentDate,
    String afterblobToString
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(xp_salesforce_endpoint + endpoint);
    req.setMethod(method);

    // Prepare the header
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('X-Client-Id', xp_salesforce_clientId);
    req.setHeader('X-Requester', xp_salesforce_requester);
    req.setHeader('X-Request-Date', currentDate);
    req.setHeader('Authorization', hmacToken);

    if ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
      req.setHeader('X-Client-Secret', xp_salesforce_clientSecret);
    }

    System.debug('--- final JSON body : ' + afterblobToString.replaceAll('\\s+', ''));

    req.setBody(afterblobToString);

    //Update OLA EDG Switch 21.12.2018
    req.setTimeout(Integer.valueOf(xp_salesforce_Time_Out));

    return req;
  }
  public static HttpRequest getHttpRequestV3(
    String endpoint,
    string method,
    String hmacToken,
    String currentDate,
    String nonce,
    String afterblobToString
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(xp_salesforce_endpoint + endpoint);
    req.setMethod(method);

    // Prepare the header
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('X-Client-Id', xp_salesforce_clientId);
    req.setHeader('X-Client-Secret', xp_salesforce_clientSecret);
    req.setHeader('X-Signature-Token', hmacToken);
    req.setHeader('X-Request-Datetime', currentDate);
    req.setHeader('X-Requester', xp_salesforce_requester);
    req.setHeader('X-Request-Nonce', nonce);

    if ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
      req.setHeader('X-Client-Secret', xp_salesforce_clientSecret);
    }

    //System.debug('--- final JSON body : ' + afterblobToString.replaceAll('\\s+', ''));
    System.debug('--- final JSON body : ' + afterblobToString);

    req.setBody(afterblobToString);

    //req.setTimeout(Integer.valueOf(xp_salesforce_Time_Out));
    req.setTimeout(120000);

    return req;
  }
  public class CustomException extends Exception {
  }
}