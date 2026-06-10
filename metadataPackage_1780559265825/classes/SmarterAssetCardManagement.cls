/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : This class contains the @InvocableMethod `blockUnBlockCard` that blocks or unblocks a card
                    in the Smarter Asset Card Management system.
--
-- @Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--13/03/2023    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

global with sharing class SmarterAssetCardManagement {
  /**
     * @description method that push a card status to
                    the Smarter Asset Card Management system.
     * @param requests
     *
     * @return
     */
  @InvocableMethod
  public static List<SmarterAssetCardManagement.Response> blockUnBlockCard(
    List<SmarterAssetCardManagement.Request> requests
  ) {
    List<SmarterAssetCardManagement.Response> result = new List<SmarterAssetCardManagement.Response>();
    System.debug('//NGO requests' + requests[0]);
    try {
      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      if (
        smarterAT != null &&
        !smarterAT.isEmpty() &&
        smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
        smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
      ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
          'callout:' +
          Constants.SMARTER_NAMED_CREDENTIAL +
          Constants.SLASH +
          Constants.SMARTER_GET_TCs_SERVICE_VERSION +
          Constants.SMARTER_GET_CARD_SERVICE_NAME +
          requests[0].ER_Card_Operational_System_ID
        );
        req.setMethod('PATCH');
        req.setHeader(Constants.X_TENANT, requests[0].ER_BUPicklist.toLowerCase());
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/pdf');
        req.setHeader(
          'Authorization',
          smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
          ' ' +
          smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
        );
        req.setBody(createJSONRequest(requests[0].Status.toUpperCase()));
        Http http = new Http();
        HttpResponse resp = http.send(req);
        System.debug('//NGO resp.body' + resp.getBody());
        System.debug('//NGO resp.getStatusCode()' + resp.getStatusCode());
        if (resp.getBody() != null) {
          Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          Map<String, Object> dataMeta = (Map<String, Object>) (mapRespData.get('meta'));

          if (dataMeta.get('status').equals('Succeeded')) {
            Map<String, Object> dataData = (Map<String, Object>) (mapRespData.get('data'));
            result.add(
              new SmarterAssetCardManagement.Response(
                dataMeta.get('status').toString(),
                'Success',
                dataData.get('currentStatus').toString()
              )
            );
          }

          if (dataMeta.get('status').equals('failed')) {
            List<Object> messages = (List<Object>) dataMeta.get('messages');
            if (!messages.isEmpty()) {
              Map<String, Object> messageMap = (Map<String, Object>) messages[0];
              result.add(
                new SmarterAssetCardManagement.Response(
                  dataMeta.get('status').toString(),
                  (String) messageMap.get('text'),
                  ''
                )
              );
            }
          }
        }
      }
    } catch (Exception ex) {
      throw new ApplicationException(ex.getMessage());
    }
    return result;
  }

  private static String createJSONRequest(String status) {
    Map<String, String> data = new Map<String, String>{ 'newStatus' => status };
    return JSON.serialize(data);
  }

  /**
   * @author Noor
   * @description Wrapper class that is used to push data from screen flow to apex.
   */
  global class Request {
    @InvocableVariable(required=true)
    public String Id;
    @InvocableVariable(required=true)
    public String ER_Card_Operational_System_ID;
    @InvocableVariable(required=true)
    public String ER_BUPicklist;
    @InvocableVariable(required=true)
    public String Status;
  }

  /**
   * @author Noor
   * @description Wrapper class that is used to pull data from apex to screen flow.
   */
  global class Response {
    public Response(String status, String message, String currentStatus) {
      this.status = status;
      this.message = message;
      this.currentStatus = currentStatus;
    }
    @InvocableVariable(required=true)
    public String status;
    @InvocableVariable(required=true)
    public String message;
    @InvocableVariable(required=true)
    public String currentStatus;
  }
}