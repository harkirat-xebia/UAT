/**
 * @author : AAZ
 * @date : 11/07/2021
 * @desc : Check all ended subscriptions (End Date <= TODAY) and run the cancellation process in Zuora
 * @see ZuoraSubscription_CancellationBatch
 */

global class ZuoraSubscription_CancellationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
  String query;

  global ZuoraSubscription_CancellationBatch(String q) {
    this.query = q;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(this.query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    Zuora__Subscription__c sub;
    Map<String, Object> subToCancel;
    String zuoraToken = ZuoraUtils.getZuoraToken();

    try {
      String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);
      System.debug('>>>>> AAZ - ZuoraSubscription_CancellationBatch scope : ' + scope);

      Map<String, Object> newOrder;
      List<Map<String, Object>> subscriptions;
      Map<String, Object> subscription;
      List<Map<String, Object>> orderActions;
      Map<String, Object> orderAction;
      List<Map<String, Object>> triggerDates;
      Map<String, Object> triggerDate;
      Map<String, Object> cancelSubscription;

      for (sObject sc : scope) {
        sub = (Zuora__Subscription__c) sc;

        //Get EntityId
        String entityId = Utils.getGlobalSettingsValueFromKey(
          Constants.ZUORA_ENTITYID + sub.Zuora__Account__r.ER_BUPicklist__c
        );

        newOrder = new Map<String, Object>();
        subscriptions = new List<Map<String, Object>>();
        subscription = new Map<String, Object>();
        orderActions = new List<Map<String, Object>>();
        orderAction = new Map<String, Object>();
        triggerDates = new List<Map<String, Object>>();
        triggerDate = new Map<String, Object>();
        cancelSubscription = new Map<String, Object>();

        cancelSubscription.put('cancellationPolicy', 'SpecificDate');
        cancelSubscription.put('cancellationEffectiveDate', sub.Zuora__SubscriptionEndDate__c);

        triggerDate.put('name', 'ContractEffective');
        triggerDate.put('triggerDate', sub.Zuora__SubscriptionEndDate__c);
        triggerDates.add(triggerDate);

        orderAction.put('type', 'CancelSubscription');
        orderAction.put('triggerDates', triggerDates);
        orderAction.put('cancelSubscription', cancelSubscription);
        orderActions.add(orderAction);

        subscription.put('subscriptionNumber', sub.Name);
        subscription.put('orderActions', orderActions);
        subscriptions.add(subscription);

        newOrder.put('orderDate', Datetime.now().format('yyyy-MM-dd'));
        newOrder.put('existingAccountNumber', sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c);
        newOrder.put('subscriptions', subscriptions);

        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HttpResponse resp;

        req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ORDERS);
        req.setMethod(Constants.POST_METHOD);
        req.setHeader('entityId', entityId);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'bearer ' + zuoraToken);

        String payload = JSON.serialize(newOrder);
        req.setBody(payload);

        Zuora.zApi zApiInstance = new Zuora.zApi();

        if (!Test.isRunningTest())
          resp = zApiInstance.sendRequest(req);
        else
          resp = SendToZuoraMock.respond(req);

        if (resp.getStatusCode() == 200) {
          string mapRespData = resp.getBody();
          System.debug('>>>>> AAZ - ZuoraSubscription_CancellationBatch ' + sub.Name + ' Success : ' + mapRespData);
        } else {
          System.debug('>>>>> AAZ - ZuoraSubscription_CancellationBatch ' + sub.Name + ' Failed : ' + resp.getBody());
        }
      }
    } catch (CalloutException ex) {
      System.debug('>>>>> AAZ - ZuoraSubscription_CancellationBatch CalloutException : ' + ex.getMessage());
    }
  }

  global void finish(Database.BatchableContext BC) {
  }
}