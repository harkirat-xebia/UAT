/**
 * Created by noorgoolamnabee on 13/02/2023.
 */

public with sharing class CreditScoring_FR_WS_Mock implements HttpCalloutMock {
  public String responseBody { get; set; }

  public CreditScoring_FR_WS_Mock(String responseBody) {
    this.responseBody = responseBody;
  }

  public HttpResponse respond(HttpRequest param) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody(responseBody);
    res.setStatusCode(200);
    return res;
  }
}