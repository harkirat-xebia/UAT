/**
 * @author : AAZ
 * @date : 09/06/2021
 * @desc : SendToZuoraMock
 * @see SendToZuoraMock
 */

public with sharing class SendToZuoraMock implements HttpCalloutMock {
  public static String fcId { get; set; }
  public static HttpResponse respond(HttpRequest req) {
    String jsonString;
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');

    if (req.getEndpoint().endsWith('oauth/token') || req.getEndpoint().endsWith('oauth/token/')) {
      jsonString = '{"access_token":"47efd258cecc49578b5d569e3963e3a8","token_type":"bearer","expires_in":3598,"scope":"entity.8adc8f99-77f2-67df-0177-f7762a022cdd entity.8adc9dee-78ef-3458-0178-f02508a62960 entity.8adce421-6daf-d3bc-016d-afe8e470079b platform.write service.events.read service.events.write service.notifications.read service.notifications.write service.usage.delete service.usage.update service.usage.write tenant.2000534 user.8adc9dee78ef34580178ef8fda863f32","jti":"47efd258cecc49578b5d569e3963e3a8"}';
    } else if (req.getEndpoint().endsWith('/v1/accounts') || req.getEndpoint().endsWith('/v1/accounts/')) {
      jsonString = '{"success":true,"accountId":"8adcba9c79ef70d10179f079ab1629df","accountNumber":"A00000093","billToContactId":"8adcba9c79ef70d10179f079ab4029e9","soldToContactId":"8adcba9c79ef70d10179f079ab4529eb"}';
    } else if (req.getEndpoint().endsWith('v1/action/create') || req.getEndpoint().endsWith('v1/action/create/')) {
      jsonString = '';
    } else if (req.getEndpoint().endsWith('v1/orders') || req.getEndpoint().endsWith('v1/orders/')) {
      jsonString = '{"success":true,"accountNumber":"A00000092","orderNumber":"O-00000059","status":"Pending","subscriptionNumbers":"(A-S00000047)"}';
    } else if (req.getEndpoint().endsWith('v1/action/update') || req.getEndpoint().endsWith('v1/action/update/')) {
      jsonString = '[{"Success":true,"Id":"8adc9a417a0e6041017a114a74032b6a"}]';
    } else if (req.getEndpoint().contains('/v1/accounts/') || req.getEndpoint().contains('/v1/accounts/A/')) {
      jsonString = '{"success":true,"accountId":"8adcba9c79ef70d10179f079ab1629df","accountNumber":"A00000093","billToContactId":"8adcba9c79ef70d10179f079ab4029e9","soldToContactId":"8adcba9c79ef70d10179f079ab4529eb"}';
    } else if (req.getEndpoint().contains('/v1/object/account/')) {
      jsonString = '{"success":true,"accountId":"8adcba9c79ef70d10179f079ab1629df","accountNumber":"A00000093","billToContactId":"8adcba9c79ef70d10179f079ab4029e9","soldToContactId":"8adcba9c79ef70d10179f079ab4529eb"}';
    } else if (req.getEndpoint().contains('/v1/creditmemos/')) {
      jsonString = '{"latestPDFFileId":"8adcba9c79ef70d10179f079ab1629df"}';
    } else if (req.getEndpoint().contains('/v1/debitmemos/')) {
      jsonString = '{"latestPDFFileId":"8adcba9c79ef70d10179f079ab1629xx"}';
    } else if (req.getEndpoint().contains('/v1/files/')) {
      res.setBodyAsBlob(Blob.valueOf('Some Text'));
      res.setStatusCode(200);
      return res;
    } else if (req.getEndpoint().contains('/v1/rateplans/')) {
      jsonString = '{"success": true,"id": "8adc94ed7d86086e017d9115de7f7eba","order": {"orderActions": [{"type": "AddProduct","addProduct": {"chargeOverrides": [{"productRateplanChargeId": "8adc8f9979f3d4f40179f556cf1c06a1","pricing": {"usagePerUnit": {"listPrice": 40.00}}}]}}]}}';
    } else if (
      req.getEndpoint().contains(Constants.GET_FC_UPDATES_SERVICE_VERSION + Constants.SLASH + 'financial-centers')
    ) {
      jsonString = '[{"id": "a055r000003TGarAAG","invoicingStreet": "6 RUE JOLIOT CURIE","invoicingCity": "THOUROTTE","invoicingZipCode": "60150","invoicingCountry": "France","invoicingCountryCode":"FR","isMaster": true}]';
      res.setBody(jsonString);
      res.setStatusCode(204);
    } else if (req.getEndpoint().contains('/v1/action/query')) {
      jsonString =
        '{"size": 1,"records": [{"TECH_Financial_Center__c": "' +
        fcId +
        '","Id": "8adc8ed085e78a440185e97b2353314c","PaymentTerm": "At reception of invoice","AccountNumber": "A00000100"}], "done": true}';
    } else {
      System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
    }

    res.setBody(jsonString);
    res.setStatusCode(200);
    return res;
  }
}