/*
----------------------------------------------------------------------
-- - Name          : GenesysCloud_API
-- - Author        : Noor
-- - Description   : This class contains all the API used to connect to Genesys Cloud
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  07/03/2023     Noor              1.0         Initial version.
---------------------------------------------------------------------------------------
 */
global with sharing class GenesysCloud_API {
  public static Map<String, String> mapAccessToken { get; set; }

  /**
   * @author ALK
   * @date 07/03/2023
   * @description This method is used to get Genesys Cloud token
   * @return Map<String, String>
   * @example
   * 'token_type' => 'Bearer',
   * 'access_token' => 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ii1LSTNROW5OUjdiUm'
   */
  public static Map<String, String> getAccessToken() {
    if (mapAccessToken == null || mapAccessToken.isEmpty()) {
      String clientId = Utils.getGlobalSettingsValueFromKey(Constants.GENESYS_CLOUD_CLIENTID);
      String clientSecret = Utils.getGlobalSettingsValueFromKey(Constants.GENESYS_CLOUD_CLIENTSECRET);

      if (clientId != null && clientSecret != null) {
        String payLoad =
          'grant_type=client_credentials' +
          '&client_id=' +
          EncodingUtil.urlEncode(clientId, Constants.UTF8_ENCODING) +
          '&client_secret=' +
          EncodingUtil.urlEncode(clientSecret, Constants.UTF8_ENCODING);
        //REQUEST
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + Constants.GENESYS_CLOUD_AUTH_NAMED_CREDENTIAL);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('grant_type', 'client_credentials');
        req.setBody(payLoad);
        //RESPONSE
        HttpResponse resp = http.send(req);
        if (resp.getStatusCode() == 200) {
          Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          if (mapResponse != null) {
            String tokenType = (String) mapResponse.get(Constants.GENESYS_CLOUD_TOKEN_TYPE);
            String accessToken = (String) mapResponse.get(Constants.GENESYS_CLOUD_ACCESS_TOKEN);
            if (tokenType != null && accessToken != null) {
              mapAccessToken = new Map<String, String>{
                Constants.GENESYS_CLOUD_TOKEN_TYPE => tokenType,
                Constants.GENESYS_CLOUD_ACCESS_TOKEN => accessToken
              };
            }
          }
        }
      }
    }
    return mapAccessToken;
  }

  /**
   * @author Noor
   * @date 10/06/2023
   * @description used Genesys API to close all pending interaction Conversation
   * @param conversationIds genesys conversation Id
   */
  @Future(Callout=true)
  public static void disconnectConversation(Map<String, String> conversationIds) {
    Map<String, String> accessToken = getAccessToken();
    List<Task> tasks = new List<Task>();

    if (
      accessToken != null &&
      !accessToken.isEmpty() &&
      accessToken.containsKey(Constants.GENESYS_CLOUD_ACCESS_TOKEN)
    ) {
      for (String conversationId : conversationIds.keySet()) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
          'callout:' +
          Constants.GENESYS_CLOUD_NAMED_CREDENTIAL +
          Constants.GENESYS_CLOUD_DISCONNECT_CONVERSATION_SERVICE +
          Constants.SLASH +
          conversationId
        );
        req.setMethod(Constants.PATCH_METHOD);
        req.setHeader('Authorization', 'Bearer ' + accessToken.get(Constants.GENESYS_CLOUD_ACCESS_TOKEN));
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"state": "disconnected"}');

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('disconnectConversation response : ' + res.getStatusCode() + ' ' + res.getBody());
        if (res.getStatusCode() == 200)
          tasks.add(
            new Task(Id = conversationIds.get(conversationId), Status = Constants.GENESYS_TASK_STATUS_COMPLETED)
          );
        else
          System.debug('Failed to Disconnect conversation: ' + res.getStatusCode() + ' ' + res.getBody());
      }
      System.debug('//NGO closed tasks : ' + tasks);
      if (!tasks.isEmpty())
        update tasks;
    } else {
      System.debug('Failed to obtain access token');
    }
  }

  /**
   * @author Noor
   * @date 10/06/2023
   * @description create an interaction in genesys and then create a task in Salesforce with the interaction conversation Id
   * @param requests genesys GenesysRoutingRequest
   */
  @Future(Callout=true)
  public static void createConversation(String requests) {
    List<GenesysRoutingRequest> reqs = (List<GenesysRoutingRequest>) JSON.deserialize(
      requests,
      List<GenesysRoutingRequest>.class
    );
    List<Task> tasks = new List<Task>();
    HttpResponse response = new HttpResponse();
    for (GenesysRoutingRequest req : reqs) {
      Map<String, Object> attributes = new Map<String, Object>();
      attributes.put(Constants.GENESYS_API_ATT_SF_URLPOP, req.attributes.sf_urlpop);
      attributes.put(Constants.GENESYS_API_ATT_PREF_AGENT, req.attributes.pref_Agent);
      attributes.put(Constants.GENESYS_API_ATT_PRIORITE, req.attributes.priorite);
      attributes.put(Constants.GENESYS_API_ATT_TYPE_ACTIVITE, req.attributes.type_activite);
      attributes.put(Constants.GENESYS_API_ATT_FA_SF, req.attributes.fa_sf);
      attributes.put(Constants.GENESYS_API_ATT_COMP, req.attributes.fa_sf);
      attributes.put(Constants.GENESYS_API_ATT_SENS, req.attributes.sens);
      attributes.put(Constants.GENESYS_API_ATT_PREF_AGENT_BKP, req.attributes.pref_Agent_Bkp);
      attributes.put(Constants.GENESYS_API_ATT_AGENT_BACKUP, req.attributes.agent_Backup);
      attributes.put(Constants.GENESYS_API_ATT_CLIENT_PRIORITY, req.attributes.client_Priority);
      attributes.put(Constants.GENESYS_API_ATT_EMAIL_SUBJECT, req.attributes.email_Subject);
      attributes.put(Constants.GENESYS_API_ATT_PREF_EMAIL_DESCRIPTION, req.attributes.email_Description);
      purecloud.Email email = purecloud.SDK.Email.create();
      email.flow = req.flowId;
      email.fromName = req.fromName;
      email.attributes = attributes;
      if (!Test.isRunningTest())
        response = email.create();
      if (response.getStatusCode() == 200) {
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        tasks.add(createStandardTask(req, (String) jsonMap.get('id')));
      }
      System.debug('//NGO Response body ' + response.getBody());
    }
    if (!tasks.isEmpty())
      insert tasks;
  }

  /**
   * @author Noor
   * @date 10/06/2023
   * @description create  a task in Salesforce with the interaction conversation Id
   * @param req  GenesysRoutingRequest
   * @param genConversationId external genesys conversation Id
   * @return task
   */
  public static Task createStandardTask(GenesysRoutingRequest req, String genConversationId) {
    Task t = new Task();
    t.Subject = Constants.GENESYS_TASK_TYPE;
    t.Status = Constants.GENESYS_TASK_STATUS_OPEN;
    if (Utils.getSObjectType(req.attributes.sf_urlpop) == Constants.LEAD)
      t.WhoId = req.attributes.sf_urlpop;
    else
      t.WhatId = req.attributes.sf_urlpop;
    t.Gsys_Call_ConversationId__c = genConversationId;
    t.OwnerId = req.attributes.owner_id;
    return t;
  }

  /**
   * @author Noor
   * @date 10/06/2023
   * @description schedule followup interaction task from Time based flow
   * @param tasks  Follow up task
   * @return List of conversation Interaction Id
   */
  @InvocableMethod
  public static List<GenesysCloud_API.Response> createConversationFollowupTask(List<Task> tasks) {
    System.debug('//NGO createConversation requests' + tasks);
    List<GenesysCloud_API.Response> responses = new List<GenesysCloud_API.Response>();
    HttpResponse response = new HttpResponse();
    Map<Id, User> userMap = Utils.getUserMap();
    for (Task t : tasks) {
      Map<String, Object> attributes = new Map<String, Object>();
      String queueId = userMap?.get(t.OwnerId)?.ER_Queue_CTI__c;
      String keyFlow = Constants.GENESYS_TASK_FLOW_ID_CONFIG + t.ER_Business_Unit__c;
      String flowName = Utils.getGlobalSettingsValueFromKey(keyFlow.toUpperCase());

      if (String.isNotBlank(keyFlow)) {
        purecloud.Email email = purecloud.SDK.Email.create();
        email.flow = flowName;
        attributes.put(Constants.GENESYS_API_ATT_PREF_AGENT, userMap.get(t.OwnerId).Email);
        attributes.put(Constants.GENESYS_API_ATT_FA_SF, queueId);
        attributes.put(Constants.GENESYS_API_ATT_COMP, queueId);
        attributes.put(Constants.GENESYS_API_ATT_SENS, 'Inbound');
        attributes.put(Constants.GENESYS_API_ATT_PREF_AGENT_BKP, '');

        if (t.Priority == Constants.CASE_PRIORITY_HIGH)
          attributes.put(Constants.GENESYS_API_ATT_PRIORITE, Constants.GENESYS_PRIORITY_HIGH);
        else
          attributes.put(Constants.GENESYS_API_ATT_PRIORITE, Constants.GENESYS_PRIORITY_LOW);

        if (t.WhoId != null && Utils.getSObjectType(t.WhoId) == Constants.LEAD) {
          attributes.put(Constants.GENESYS_API_ATT_SF_URLPOP, t.WhoId);
          email.fromName = 'Relance_Inbound';
          attributes.put(Constants.GENESYS_API_ATT_TYPE_ACTIVITE, Constants.LEAD);
        } else {
          attributes.put(Constants.GENESYS_API_ATT_SF_URLPOP, t.WhatId);
          email.fromName = 'Opportunite';
          attributes.put(Constants.GENESYS_API_ATT_TYPE_ACTIVITE, 'Opportunity');
        }
        email.attributes = attributes;
        System.debug('//NGO createConversation email ' + email);
        System.debug('//NGO createConversation attributes ' + attributes);

        if (!Test.isRunningTest())
          response = email.create();

        if (response.getStatusCode() == 200) {
          Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
          responses.add(new GenesysCloud_API.Response(t.Id, (String) jsonMap.get('id')));
        }
      } else {
        responses.add(new GenesysCloud_API.Response(t.Id, 'Flow name not configured'));
      }

      System.debug('//NGO responses : ' + responses);
    }
    return responses;
  }

  /**
   * @author Noor
   * @description Wrapper class that is used to pull data from apex to screen flow.
   */
  global class Response {
    public Response(String id, String call_ConversationId) {
      this.Id = id;
      this.call_ConversationId = call_ConversationId;
    }
    @InvocableVariable(required=true)
    public String Id;
    @InvocableVariable(required=true)
    public String call_ConversationId;
  }
}