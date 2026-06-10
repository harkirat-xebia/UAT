/*
----------------------------------------------------------------------
-- - Name          : WSSK01_GetFinstat_Test
-- - Author        : OLA
-- - Description   : get information from Finstat public register
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Sep-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class WSSK01_GetFinstat_Test {
  static testMethod void GetFinstatInfos() {
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new FinstatWSMockImpl(200));
    WSSK01_GetFinstat.GetFinstatInfos('12345678');
    try {
      Test.setMock(HttpCalloutMock.class, new FinstatWSMockImpl(404));
      WSSK01_GetFinstat.GetFinstatInfos('12345678');
    } catch (Exception e) {
      System.debug(e.getMessage());
    }
    try {
      Test.setMock(HttpCalloutMock.class, new FinstatWSMockImpl(500));
      WSSK01_GetFinstat.GetFinstatInfos('12345678');
    } catch (Exception e) {
      System.debug(e.getMessage());
    }
    try {
      Test.setMock(HttpCalloutMock.class, new FinstatWSMockImpl(400));
      WSSK01_GetFinstat.GetFinstatInfos('12345678');
    } catch (Exception e) {
      System.debug(e.getMessage());
    }
    Test.StopTest();
  }
  public class FinstatWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public FinstatWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      String WSOK =
        '<?xml version="1.0" encoding="utf-8"?>' +
        '<ExtendedResult xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
        '<Street>Jasovská</Street>' +
        '<StreetNumber>49</StreetNumber>' +
        '<ZipCode>851 07</ZipCode>' +
        '<City>Bratislava</City>' +
        '<Region>Bratislavský</Region>' +
        '<District>Bratislava V</District>' +
        '<Name>GRAFFITI - X, s.r.o.</Name>' +
        '<Ico>35870923</Ico>' +
        '<RegisterNumberText>Zapísaná na Bratislava I, odd. Sro, vl.č.30171/B</RegisterNumberText>' +
        '<Dic>2020217562</Dic>' +
        '<SkNaceCode>01500</SkNaceCode>' +
        '<SkNaceText>Zmiešané hospodárstvo</SkNaceText>' +
        '<SkNaceDivision>Pestovanie plodín a chov zvierat, poľovníctvo a služby s tým súvisiace</SkNaceDivision>' +
        '<SkNaceGroup>Zmiešané hospodárstvo</SkNaceGroup>' +
        '<LegalFormCode>112</LegalFormCode>' +
        '<LegalFormText>Spol. s r. o.</LegalFormText>' +
        '</ExtendedResult>';
      System.debug('####TEST req.getEndpoint() : ' + req.getEndpoint());
      res.setBody(WSOK);
      res.setStatusCode(statusCode);
      return res;
    }
  }
}