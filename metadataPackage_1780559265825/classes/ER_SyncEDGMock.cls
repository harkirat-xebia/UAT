/**
 * Created by khaddouch on 16/06/2021.
 * @author KHAD
 * @date 16/06/2021
 * @description Mock of the callout to EDG
 */

public with sharing class ER_SyncEDGMock implements HttpCalloutMock {
  public static HttpResponse respond(HttpRequest req) {
    String jsonString;
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    if (req.getEndpoint().endsWith('/accounts')) {
      jsonString = '{"meta": {"status": "succeeded","messages": [{"code": "string","text": "string","ref": "string"}]},"data": {"synchronization_results": [{"attributes": {"type": "account","record_id": "0015r00000CW0gSAAT"},"synchronization_result": {"scope": "merchant","status": "not_synchronized","message": "some other error","code": "500","event_date": "2021-04-27"}},{"attributes": {"type": "contact","record_id": "0035r00000AFCTpAAP"},"synchronization_result": {"scope": "merchant","status": "not_synchronized","message": "some error","code": "404","event_date": "2021-04-27"}}]}}';
    }
    res.setBody(jsonString);
    res.setStatusCode(200);
    res.setStatus('OK');
    return res;
  }
}