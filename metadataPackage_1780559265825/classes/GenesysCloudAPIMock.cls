@isTest
global class GenesysCloudAPIMock implements HttpCalloutMock {
  global HTTPResponse respond(HTTPRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    if (req.getEndpoint().contains(Constants.GENESYS_CLOUD_AUTH_NAMED_CREDENTIAL)) {
      res.setBody(
        '{"token_type":"Bearer","expires_in":3599,"ext_expires_in":3599,"access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIs"}'
      );
      res.setStatusCode(200);
    } else if (req.getEndpoint().contains(Constants.GENESYS_CLOUD_CALLBACK_SERVICE)) {
      res.setStatusCode(202);
      // Set the response body
      String responseBody = '{"conversation": { "id": "50c752d6-989e-460d-9885-9880e736b6f6", "selfUri": "/api/v2/conversations/50c752d6-989e-460d-9885-9880e736b6f6" }, "callbackIdentifiers": [ { "type": "EXTERNAL", "id": "eccbb495-94b4-410d-8177-9cfb7e332dff" }, { "type": "ACD", "id": "a44d270b-7d3f-4d51-b83b-d0be37cee24f" } ]}';
      res.setBody(responseBody);
    } else if (req.getEndpoint().contains(Constants.GENESYS_CLOUD_SEARCH)) {
      res.setStatusCode(200);
      // Set the response body
      String responseBody =
        '{\n' +
        '    "total": 1,\n' +
        '    "pageCount": 1,\n' +
        '    "pageSize": 25,\n' +
        '    "pageNumber": 1,\n' +
        '    "currentPage": "/api/v2/search?q64=H4sIAAAAAAAAAD2OywrCMBBF_2XWtaDgpitFI26s2NaFiJS0mdZAk9RJIqj476YtuJw75z4-4F49Wkiu4C2ShVsE1pA7kkCCBPLNMWMQwcMjvQL1GfnwKFh2CHojsROjHRWX3WB_8s4PhDJ3rlDEstKKeIVuVRttfeekbmeNoRgFagpAbVRIMj0Sd2YoXadb-IaknreYy3cIWyynK_WqGnbNIyB0nvTu3y_FuB051fdi2ng6s-xSFnuWljtWbPbw_QEX9EV-7wAAAA%3D%3D",\n' +
        '    "types": [\n' +
        '        "users"\n' +
        '    ],\n' +
        '    "results": [\n' +
        '        {\n' +
        '            "guid": "18f410f0-1759-4939-a17d-c7ccfec19ed9",\n' +
        '            "_type": "users"\n' +
        '        }\n' +
        '    ]\n' +
        '}';

      res.setBody(responseBody);
    } else if (req.getEndpoint().contains(Constants.GENESYS_CLOUD_DISCONNECT_CONVERSATION_SERVICE + Constants.SLASH)) {
      res.setStatusCode(200);
      // Set the response body
      String responseBody =
        '{\n' +
        '    "id": "50d47fe8-e64b-4242-85cc-f9b1e2d05f1b",\n' +
        '    "otherMediaUris": [],\n' +
        '    "selfUri": "/api/v2/conversations/emails/50d47fe8-e64b-4242-85cc-f9b1e2d05f1b"\n' +
        '}';

      res.setBody(responseBody);
    } else if (req.getEndpoint().contains(Constants.GENESYS_CLOUD_DISCONNECT_CONVERSATION_SERVICE)) {
      res.setStatusCode(200);
      // Set the response body
      String responseBody = '{\n' + '"participants": [],\n' + '"state": "disconnected"' + '}';

      res.setBody(responseBody);
    } else {
      System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
      res.setBody('jsonString');
      res.setStatusCode(200);
    }
    return res;
  }
}