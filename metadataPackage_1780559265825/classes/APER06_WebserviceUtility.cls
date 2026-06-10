/*
----------------------------------------------------------------------
-- - Name          : APER06_WebserviceUtility
-- - Author        : OLA
-- - Description   : Class for Web service methods (Get customMetadata, getToken ...)
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 03-OCT-2018  OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class APER06_WebserviceUtility {
  /*  All EDG call out attributes */
  public static String xp_salesforce_clientSecret;
  public static String xp_salesforce_endpoint;
  public static String xp_salesforce_clientId;
  public static String xp_salesforce_requester;
  public static Decimal xp_salesforce_Time_Out;
  public static Boolean Offline_Sales_WS = false;
  public static Boolean Offline_Service_WS = false;
  //public static final String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));
  public static final String currentDate = String.valueOf((datetime.now().getTime()) / 1000);
  public static CMER01_EDG_Webservice_Setting__mdt edgWsConfiguration;

  static {
    try {
      String bu;
      if (
        UserInfo.getUserType() == Constants.AUTOMATED_PROCESS &&
        !String.isBlank(APER30_AutoEnrollment_Management.syncRecordBU)
      )
        bu = APER30_AutoEnrollment_Management.syncRecordBU;
      else if (String.isNotBlank(APER10_User_Management.userBU))
        bu = APER10_User_Management.userBU;
      System.debug('>>> bu: ' + bu);

      edgWsConfiguration = CMER01_EDG_Webservice_Setting__mdt.getInstance(bu);

      if (edgWsConfiguration != null) {
        Offline_Sales_WS = edgWsConfiguration.ER_Offline_Sales_WS__c;
        Offline_Service_WS = edgWsConfiguration.ER_Offline_Service_WS__c;
      }
      checkWsSettings();
    } catch (Exception e) {
      System.debug('Exception msg: ' + e.getMessage());
      System.debug('Exception line: ' + e.getLineNumber());
      System.debug('Exception cause: ' + e.getCause());
      throw new CustomException(Label.LABS_SF_WS_SettingNotFilled);
    }
  }
  public static void checkWsSettings() {
    if (runningInASandbox()) {
      System.debug('SANDBOX CALL EDG');
      if (Test.isRunningTest()) {
        //For test class we need to create a mock webservice
        xp_salesforce_clientSecret = 'TEST';
        xp_salesforce_endpoint = 'TEST';
        xp_salesforce_clientId = 'TEST';
        xp_salesforce_requester = 'SF';
        xp_salesforce_Time_Out = 60000;
      } else if (
        String.isBlank(edgWsConfiguration.sdx_xp_salesforce_clientSecret__c) ||
        String.isBlank(edgWsConfiguration.sdx_xp_salesforce_url__c) ||
        String.isBlank(edgWsConfiguration.sdx_xp_salesforce_clientId__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_requester__c) ||
        edgWsConfiguration.xp_salesforce_Time_Out__c == null
      ) {
        throw new CustomException(Label.LABS_SF_WS_SettingNotFilled);
      } else {
        xp_salesforce_clientSecret = edgWsConfiguration.sdx_xp_salesforce_clientSecret__c;
        xp_salesforce_endpoint = edgWsConfiguration.sdx_xp_salesforce_url__c;
        xp_salesforce_clientId = edgWsConfiguration.sdx_xp_salesforce_clientId__c;
        xp_salesforce_requester = edgWsConfiguration.xp_salesforce_requester__c;
        xp_salesforce_Time_Out = edgWsConfiguration.xp_salesforce_Time_Out__c;
      }
    } else {
      System.debug('PRODUCTION CALL EDG');
      if (Test.isRunningTest()) {
        xp_salesforce_clientSecret = 'TEST';
        xp_salesforce_endpoint = 'TEST';
        xp_salesforce_clientId = 'TEST';
        xp_salesforce_requester = 'SF';
        xp_salesforce_Time_Out = 60000;
      } else if (
        String.isBlank(edgWsConfiguration.xp_salesforce_clientSecret__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_url__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_clientId__c) ||
        String.isBlank(edgWsConfiguration.xp_salesforce_requester__c) ||
        edgWsConfiguration.xp_salesforce_Time_Out__c == null
      ) {
        throw new CustomException(Label.LABS_SF_WS_SettingNotFilled);
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
  /*
    //hmac calculation for EDG V2
    public static String getHmacToken(String url, String body) {

        // encoded uri
        String uri = (EncodingUtil.urlEncode(url, 'UTF-8')).toLowerCase();

        Blob hash;
        String paramvalue;

        if (String.isNotBlank(body)) {
            hash = Crypto.generateDigest('SHA-256', Blob.valueOf(body));
            paramvalue = EncodingUtil.convertToHex(hash);
        }

        System.debug('--- Input data to calculate hmac:');
        System.debug('--- uri: ' + uri);
        System.debug('--- hashed body: ' + paramvalue);
        System.debug('--- requester: ' + xp_salesforce_requester);
        System.debug('--- requestDate: ' + currentDate);

        // Authentication encoded MAC
        String rawHmac;
        if (String.isNotBlank(paramvalue)) {
            rawHmac = uri + '#' + paramvalue + '#' + xp_salesforce_requester + '#' + currentDate;
        } else {
            rawHmac = uri + '#' + xp_salesforce_requester + '#' + currentDate;
        }
        Blob encodedHmac = crypto.generateMac('HmacSHA256', Blob.valueOf(rawHmac), Blob.valueOf(xp_salesforce_clientSecret));
        String hmacToken = EncodingUtil.convertToHex(encodedHmac);
        System.debug('--- encoded hmacToken : ' + hmacToken);

        return hmacToken;
    } */
  //hmac calculation for EDG V3
  public static String getHmacToken(String apimethod, String body, String nonce, String currentDate, String method) {
    // encoded uri -- Ok
    String url = xp_salesforce_endpoint + apimethod;
    String uri = (EncodingUtil.urlEncode(url, 'UTF-8')).toLowerCase();
    String sharedKey = '4fa9d3b008f6d5c679357b03444a9082';
    String rawHmac = '';

    System.debug('--- Input data to calculate hmac:');
    System.debug('--- url: ' + url);
    System.debug('--- method: ' + method);
    System.debug('--- nonce: ' + nonce);
    System.debug('--- requester: ' + xp_salesforce_requester);
    System.debug('--- xp_salesforce_clientId: ' + xp_salesforce_clientId);
    System.debug('--- xp_salesforce_clientSecret: ' + xp_salesforce_clientSecret);
    System.debug('--- requestDate: ' + currentDate);

    if (method == 'GET')
      rawHmac = (xp_salesforce_clientId + method + uri + currentDate + nonce + xp_salesforce_requester).toLowerCase();
    else {
      Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(body));
      string paramvalue = EncodingUtil.convertToHex(hash);
      System.debug('--- hashed body: ' + paramvalue);
      rawHmac = (xp_salesforce_clientId +
        method +
        uri +
        currentDate +
        nonce +
        xp_salesforce_requester +
        paramvalue)
        .toLowerCase();
    }

    System.debug('--- encoded rawHmac : ' + rawHmac);
    Blob encodedHmac = Crypto.generateMac('HmacSHA256', Blob.valueOf(rawHmac), Blob.valueOf(sharedKey));
    String hmacToken = EncodingUtil.convertToHex(encodedHmac);

    System.debug('--- encoded hmacToken : ' + hmacToken);

    return hmacToken;
  }
  //http request for EDG V3
  public static HttpRequest getHttpRequest(String endpoint, String method, String body, Integer timeOut) {
    String finalEndpoint = xp_salesforce_endpoint + endpoint;
    HttpRequest req = new HttpRequest();
    req.setEndpoint(finalEndpoint);
    req.setMethod(method);
    String nonce = String.valueOf(Crypto.getRandomLong());
    // Prepare the header
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('X-Client-Id', xp_salesforce_clientId);
    req.setHeader('X-Client-Secret', xp_salesforce_clientSecret);
    req.setHeader('X-Signature-Token', getHmacToken(endpoint, body, nonce, currentDate, method));
    req.setHeader('Authorization', nonce);
    req.setHeader('X-Request-Datetime', currentDate);
    req.setHeader('X-Requester', xp_salesforce_requester);
    req.setHeader('X-Request-Nonce', nonce);

    if (String.isNotBlank(body)) {
      System.debug('--- final JSON body : ' + body.replaceAll('\\s+', ''));
      req.setBody(body);
    }
    if (timeOut == null) {
      req.setTimeout(Integer.valueOf(xp_salesforce_Time_Out));
    } else {
      req.setTimeout(timeOut);
    }
    return req;
  }
  /*
    // request for the V2
    public static HttpRequest getHttpRequest(String endpoint, string method, String body, Integer timeOut) {
        
        checkWsSettings();
        String finalEndpoint = xp_salesforce_endpoint + endpoint;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(finalEndpoint);
        req.setMethod(method);
        // Prepare the header
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Client-Id', xp_salesforce_clientId);
        req.setHeader('X-Requester', xp_salesforce_requester);
        req.setHeader('X-Request-Date', currentDate);
        req.setHeader('Authorization', getHmacToken(finalEndpoint, body));
        req.setHeader('X-Client-Secret', xp_salesforce_clientSecret);
        if (String.isNotBlank(body)) {
            System.debug('--- final JSON body : ' + body.replaceAll('\\s+', ''));
            req.setBody(body);
        }
        if (timeOut == null) {
            req.setTimeout(Integer.valueOf(xp_salesforce_Time_Out));
        } else {
            req.setTimeout(timeOut);
        }
        return req;
    }
    */

  //description Custom error handling class
  public class CustomException extends Exception {
  }
}