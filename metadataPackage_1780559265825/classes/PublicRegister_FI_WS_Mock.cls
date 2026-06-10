/**
 * Created by noorgoolamnabee on 23/12/2022.
 */

public with sharing class PublicRegister_FI_WS_Mock implements HttpCalloutMock {
  public HttpResponse respond(HttpRequest param1) {
    String jsonString;
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');

    jsonString = getMockJSON();

    res.setBody(jsonString);
    res.setStatusCode(200);
    return res;
  }

  public static String getMockJSON() {
    String json =
      '{' +
      '    \"results\": [' +
      '        {' +
      '            \"status\": \"active\",' +
      '            \"company_name\": \"Apple Aktiebolag, filial i Finland\",' +
      '            \"business_id\": \"09247878\",' +
      '            \"postal\": \"00100\",' +
      '            \"vat_number\": \"FI09247878\",' +
      '            \"form_of_company\": \"SL\",' +
      '            \"city\": \"HELSINKI\",' +
      '            \"address\": \"Fabianinkatu 31 C\",' +
      '            \"staff_number\": null' +
      '        }' +
      '    ]' +
      '}';

    return json;
  }
}