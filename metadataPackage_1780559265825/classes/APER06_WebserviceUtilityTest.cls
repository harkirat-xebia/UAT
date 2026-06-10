/*
----------------------------------------------------------------------
-- - Name          : APER06_WebserviceUtilityTest
-- - Author        : snica
-- - Description   : Test class for APER06_WebserviceUtility
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- OCT-2012     snica               1.0         Initial version
---------------------------------------------------------------------------------------
*/
@IsTest
public class APER06_WebserviceUtilityTest {
  static testMethod void getHttpRequestTest() {
    String endpoint = '/cards/' + '2801001840' + '-ERBE_TRE-M/balances';
    String method = 'GET';
    String body = '';
    integer timeOut;

    Test.startTest();
    APER06_WebserviceUtility.getHttpRequest(endpoint, 'GET', '', timeOut);
    APER06_WebserviceUtility.getHttpRequest(endpoint, 'POST', 'body', 2);
    Test.stopTest();
  }
}