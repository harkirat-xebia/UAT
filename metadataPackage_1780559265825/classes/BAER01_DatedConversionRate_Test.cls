@isTest
private class BAER01_DatedConversionRate_Test {
  static testMethod void testBatch() {
    Test.startTest();
    String hour = String.valueOf(Datetime.now().hour());
    String min = String.valueOf(Datetime.now().minute());
    String ss = String.valueOf(Datetime.now().second());

    String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
    Test.setMock(HttpCalloutMock.class, new ECBWSMockImpl(200));
    BAER01_DatedConversionRate s = new BAER01_DatedConversionRate();
    System.schedule('Test Change : ' + String.valueOf(Datetime.now()), nextFireTime, s);

    Test.stopTest();
  }

  public class ECBWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public ECBWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      String WSOK =
        '<?xml version="1.0" encoding="UTF-8"?>' +
        '<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">' +
        '    <gesmes:subject>Reference rates</gesmes:subject>' +
        '    <gesmes:Sender>' +
        '        <gesmes:name>European Central Bank</gesmes:name>' +
        '    </gesmes:Sender>' +
        '    <Cube>' +
        '        <Cube time=\'2018-10-19\'>' +
        '            <Cube currency=\'HUF\' rate=\'323.20\'/>' +
        '            <Cube currency=\'PHP\' rate=\'61.605\'/>' +
        '            <Cube currency=\'SGD\' rate=\'1.5800\'/>' +
        '            <Cube currency=\'THB\' rate=\'37.358\'/>' +
        '            <Cube currency=\'ZAR\' rate=\'16.4499\'/></Cube>' +
        '   </Cube>' +
        '</gesmes:Envelope>';
      System.debug('####TEST req.getEndpoint() : ' + req.getEndpoint());
      res.setBody(WSOK);
      res.setStatusCode(statusCode);
      return res;
    }
  }
}