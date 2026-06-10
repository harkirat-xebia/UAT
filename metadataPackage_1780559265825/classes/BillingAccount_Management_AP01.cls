/*
----------------------------------------------------------------------
-- - Name          : BillingAccount_Management_AP01
-- - Author        : AAZ
-- - Description   : Zuora Billing Account Management   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- MAY-2021     AAZ                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

public class BillingAccount_Management_AP01 {
  /**
   * @author AAZ
   * @date 18/05/2021
   * @description Create a child Subscription based on a master one, for a child BA
   * @param newbillingAccounts
   */
  public static void createChildSubforBillingAccount(List<Zuora__CustomerAccount__c> newbillingAccounts) {
    System.debug(
      '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubforBillingAccount newbillingAccounts : ' +
      newbillingAccounts
    );
    //if(UtilsBypass.canTrigger('createChildSubscription')) {
    Map<Id, Zuora__CustomerAccount__c> billingAccountsMap = new Map<Id, Zuora__CustomerAccount__c>(newbillingAccounts);
    Map<Id, List<Zuora__CustomerAccount__c>> mapAccountIdBillingAccounts = new Map<Id, List<Zuora__CustomerAccount__c>>();

    for (Zuora__CustomerAccount__c ba : [
      SELECT
        Id,
        Zuora__Account__c,
        ER_Master__c,
        ER_Financial_Center__r.ER_Type__c,
        Zuora__AccountNumber__c,
        ER_Financial_Center__r.ER_Business_Unit__c,
        ER_Financial_Center__r.ER_BUPicklist__c
      FROM Zuora__CustomerAccount__c
      WHERE Id IN :billingAccountsMap.keySet() AND ER_Master__c = FALSE
    ]) {
      System.debug(
        '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubforBillingAccount ba.ER_Master__c : ' +
        ba.ER_Master__c
      );

      if (!mapAccountIdBillingAccounts.containsKey(ba.Zuora__Account__c))
        mapAccountIdBillingAccounts.put(ba.Zuora__Account__c, new List<Zuora__CustomerAccount__c>());
      mapAccountIdBillingAccounts.get(ba.Zuora__Account__c).add(ba);
    }
    System.debug(
      '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubforBillingAccount mapAccountIdBillingAccounts : ' +
      mapAccountIdBillingAccounts
    );

    if (!mapAccountIdBillingAccounts.isEmpty()) {
      Map<Id, List<Zuora__Subscription__c>> mapAccountIdMasterSubscriptions = new Map<Id, List<Zuora__Subscription__c>>();

      for (Zuora__Subscription__c sub : [
        SELECT
          Id,
          Zuora__Account__c,
          Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
          Zuora__Status__c,
          Zuora__CustomerAccount__r.ER_Financial_Center__r.ER_Type__c,
          Zuora__TermSettingType__c,
          Zuora__SubscriptionEndDate__c,
          Zuora__InitialTermPeriodType__c,
          Zuora__SubscriptionStartDate__c,
          Zuora__ContractEffectiveDate__c,
          Zuora__ContractAcceptanceDate__c,
          Zuora__ServiceActivationDate__c,
          Name,
          (
            SELECT
              Zuora__External_Id__c,
              ER_Solution__c,
              ER_Solution__r.zqu__Category__c,
              Zuora__OriginalProductRatePlanId__c
            FROM Zuora__Subscription_Rate_Plans__r
            WHERE ER_Solution__r.zqu__Category__c = :Constants.SOLUTION_BASE_PRODUCTS
          )
        FROM Zuora__Subscription__c
        WHERE
          Zuora__Account__c IN :mapAccountIdBillingAccounts.keySet()
          AND Zuora__Status__c = 'Active'
          AND Zuora__CustomerAccount__r.ER_Master__c = TRUE
      ]) {
        if (!mapAccountIdMasterSubscriptions.containsKey(sub.Zuora__Account__c))
          mapAccountIdMasterSubscriptions.put(sub.Zuora__Account__c, new List<Zuora__Subscription__c>());
        mapAccountIdMasterSubscriptions.get(sub.Zuora__Account__c).add(sub);
      }

      System.debug(
        '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubforBillingAccount mapAccountIdMasterSubscriptions : ' +
        mapAccountIdMasterSubscriptions
      );

      if (!mapAccountIdMasterSubscriptions.isEmpty()) {
        System.enqueueJob(
          new ER_CreateChildSubforBillingAccount(mapAccountIdBillingAccounts, mapAccountIdMasterSubscriptions)
        );
      }
    }
    //}
  }

  /**
   * @author AAZ
   * @date 18/05/2021
   * @description create child Subscriptions for child Accounts
   * @param mapBillingAccounts
   * @param mapMasterSubscriptions
   * @param token
   */
  public static void createChildSubcriptions(
    Map<Id, List<Zuora__CustomerAccount__c>> mapBillingAccounts,
    Map<Id, List<Zuora__Subscription__c>> mapMasterSubscriptions,
    String token
  ) {
    HttpRequest req = new HttpRequest();
    HttpResponse resp;
    String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);

    try {
      for (String accId : mapBillingAccounts.keySet()) {
        List<Zuora__CustomerAccount__c> billAccounts = mapBillingAccounts.get(accId);
        List<Zuora__Subscription__c> masterSubs = mapMasterSubscriptions.get(accId);

        for (Zuora__CustomerAccount__c bAcc : billAccounts) {
          //Get EntityId
          String entityId = Utils.getGlobalSettingsValueFromKey(
            Constants.ZUORA_ENTITYID + bAcc.ER_Financial_Center__r.ER_BUPicklist__c
          );
          if (String.isNotBlank(entityId)) {
            for (Zuora__Subscription__c sb : masterSubs) {
              System.debug(
                '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubforBillingAccount Sub FC Type: ' +
                sb.Zuora__CustomerAccount__r.ER_Financial_Center__r.ER_Type__c
              );
              System.debug(
                '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubforBillingAccount Sub Zuora__Subscription_Rate_Plans__r: ' +
                sb.Zuora__Subscription_Rate_Plans__r
              );

              if (
                sb.Zuora__CustomerAccount__r.ER_Financial_Center__r.ER_Type__c ==
                bAcc.ER_Financial_Center__r.ER_Type__c && !sb.Zuora__Subscription_Rate_Plans__r.isEmpty()
              ) {
                Integer initialTermInDays = 0;
                if (sb.Zuora__SubscriptionEndDate__c != null)
                  initialTermInDays = sb.Zuora__SubscriptionStartDate__c.daysBetween(sb.Zuora__SubscriptionEndDate__c);

                Map<String, Object> newOrder = new Map<String, Object>();
                List<Map<String, Object>> subscriptions = new List<Map<String, Object>>();
                Map<String, Object> subscription;
                List<Map<String, Object>> orderActions;
                Map<String, Object> orderAction;
                List<Map<String, Object>> subscribeToRatePlans;
                List<Map<String, Object>> chargeOverrides;
                Map<String, Object> subscribPlan;
                Map<String, Object> chargeOverride;
                List<Map<String, Object>> triggerDates;
                Map<String, Object> triggerDate;
                Map<String, Object> terms;
                Map<String, Object> initialterm;
                Map<String, Object> createSubscription;
                Map<String, Object> customField;

                //Populate needed fields
                newOrder.put('orderDate', Datetime.now().format('yyyy-MM-dd'));
                newOrder.put('existingAccountNumber', bAcc.Zuora__AccountNumber__c);

                subscription = new Map<String, Object>();
                orderActions = new List<Map<String, Object>>();
                orderAction = new Map<String, Object>();
                subscribeToRatePlans = new List<Map<String, Object>>();
                terms = new Map<String, Object>();
                initialterm = new Map<String, Object>();
                triggerDates = new List<Map<String, Object>>();
                triggerDate = new Map<String, Object>();
                createSubscription = new Map<String, Object>();
                customField = new Map<String, Object>();

                for (Zuora__SubscriptionRatePlan__c srp : sb.Zuora__Subscription_Rate_Plans__r) {
                  subscribPlan = new Map<String, Object>();
                  subscribPlan.put('productRatePlanId', srp.Zuora__OriginalProductRatePlanId__c);

                  chargeOverrides = getRatePlanCharges(srp.Zuora__External_Id__c, entityId, token, endpoint);
                  subscribPlan.put('chargeOverrides', chargeOverrides);
                  subscribeToRatePlans.add(subscribPlan);
                }

                createSubscription.put('subscribeToRatePlans', subscribeToRatePlans);

                //Initialterm
                initialterm.put('termType', sb.Zuora__TermSettingType__c);
                /*if(String.isNotBlank(sb.Zuora__InitialTermPeriodType__c))
                                        initialterm.put('periodType', sb.Zuora__InitialTermPeriodType__c);
                                    if(sb.Zuora__SubscriptionEndDate__c != null)
                                        initialterm.put('period', initialTermInDays);*/
                initialterm.put('startDate', sb.Zuora__SubscriptionStartDate__c);
                terms.put('initialTerm', initialterm);

                //terms.put('autoRenew', true);
                //terms.put('renewalSetting', 'RENEW_TO_EVERGREEN');
                createSubscription.put('terms', terms);

                triggerDate.put('name', 'ContractEffective');
                triggerDate.put('triggerDate', sb.Zuora__ContractEffectiveDate__c);
                triggerDates.add(triggerDate);
                triggerDate = new Map<String, Object>();
                triggerDate.put('name', 'ServiceActivation');
                triggerDate.put('triggerDate', sb.Zuora__ServiceActivationDate__c);
                triggerDates.add(triggerDate);
                triggerDate = new Map<String, Object>();
                triggerDate.put('name', 'CustomerAcceptance');
                triggerDate.put('triggerDate', sb.Zuora__ContractAcceptanceDate__c);
                triggerDates.add(triggerDate);

                orderAction.put('triggerDates', triggerDates);
                orderAction.put('type', 'CreateSubscription');
                orderAction.put('createSubscription', createSubscription);
                orderActions.add(orderAction);

                customField.put('ER_Parent_Subscription__c', sb.Name);
                customField.put('ER_Master__c', 'No');

                subscription.put('orderActions', orderActions);
                subscription.put('customFields', customField);
                subscriptions.add(subscription);

                newOrder.put('subscriptions', subscriptions);

                if (Limits.getCallouts() < Limits.getLimitCallouts()) {
                  req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ORDERS);
                  req.setMethod(Constants.POST_METHOD);
                  req.setHeader('entityId', entityId);
                  req.setHeader('Content-Type', 'application/json');
                  req.setHeader('Accept', 'application/json');
                  req.setHeader('Authorization', 'bearer ' + token);

                  String payload = JSON.serialize(newOrder);
                  System.debug('>>>>> AAZ - entityId entityId : ' + entityId);
                  System.debug('>>>>> AAZ - createChildSubcriptions payload : ' + payload);
                  req.setBody(payload);
                  Zuora.zApi zApiInstance = new Zuora.zApi();

                  if (!Test.isRunningTest())
                    resp = zApiInstance.sendRequest(req);
                  else
                    resp = SendToZuoraMock.respond(req);

                  if (resp.getStatusCode() == 200) {
                    Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                    System.debug(
                      '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubcriptions mapRespData : ' + mapRespData
                    );
                  }
                }
              }
            }
          }
        }
      }
    } catch (CalloutException ce) {
      System.debug(
        '>>>>> AAZ - BillingAccount_Management_AP01 createChildSubcriptions CalloutException : ' + ce.getMessage()
      );
    }
  }

  /**
   * @author AAZ
   * @date 18/05/2021
   * @description Assign the parent Financial Center to Billing Account
   * @param accounts
   */
  public static void linkABillingAccountToFC(List<Zuora__CustomerAccount__c> accounts) {
    Map<Id, Zuora__CustomerAccount__c> mapFCBA = new Map<Id, Zuora__CustomerAccount__c>();

    for (Zuora__CustomerAccount__c a : accounts) {
      if (String.isNotBlank(a.TECH_Financial_Center__c))
        mapFCBA.put(a.TECH_Financial_Center__c, a);
    }

    for (ER_Financial_Center__c fc : [
      SELECT Id, ER_Master__c
      FROM ER_Financial_Center__c
      WHERE Id IN :mapFCBA.keySet()
    ]) {
      Zuora__CustomerAccount__c ba = mapFCBA.get(fc.Id);
      ba.ER_Master__c = fc.ER_Master__c;
      ba.ER_Financial_Center__c = fc.Id;
    }
  }

  /**
   * @author AAZ
   * @date 18/05/2021
   * @description Fill in the Bill To / Sold To lookups
   * @param accounts
   */
  public static void linkContactToBA(List<Zuora__CustomerAccount__c> accounts) {
    Map<String, Zuora__CustomerAccount__c> mapAccounts = new Map<String, Zuora__CustomerAccount__c>();
    Map<Id, List<String>> mapFCAccounts = new Map<Id, List<String>>();

    for (Zuora__CustomerAccount__c a : accounts) {
      String uuid = Utils.generateUniqueId();
      mapAccounts.put(uuid, a);

      if (a.ER_Financial_Center__c != null) {
        if (!mapFCAccounts.containsKey(a.ER_Financial_Center__c))
          mapFCAccounts.put(a.ER_Financial_Center__c, new List<String>());
        mapFCAccounts.get(a.ER_Financial_Center__c).add(uuid);
      }
    }

    for (ER_Financial_Center__c fc : [
      SELECT Id, ER_Contact__c
      FROM ER_Financial_Center__c
      WHERE Id IN :mapFCAccounts.keySet()
    ]) {
      for (String s : mapFCAccounts.get(fc.Id)) {
        if (mapAccounts.containsKey(s)) {
          mapAccounts.get(s).ER_Bill_To_Contact__c = fc.ER_Contact__c;
          mapAccounts.get(s).ER_Sold_To_Contact__c = fc.ER_Contact__c;
        }
      }
    }
  }

  /**
   * @author AAZ
   * @date
   * @description get charges from Zuora for a given rate plan
   * @param planId
   * @param entityId
   * @param zuoraToken
   * @param endpoint
   * @return
   */
  public static List<Map<String, Object>> getRatePlanCharges(
    String planId,
    String entityId,
    String zuoraToken,
    String endpoint
  ) {
    HttpRequest req = new HttpRequest();
    HttpResponse resp;
    Map<String, Object> chargeOverride;
    List<Map<String, Object>> chargeOverrides = new List<Map<String, Object>>();

    req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_RATEPLANS + planId);
    req.setMethod(Constants.GET_METHOD);
    req.setHeader('entityId', entityId);
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setHeader('Authorization', 'bearer ' + zuoraToken);

    Zuora.zApi zApiInstance = new Zuora.zApi();

    if (!Test.isRunningTest())
      resp = zApiInstance.sendRequest(req);
    else
      resp = SendToZuoraMock.respond(req);

    if (resp.getStatusCode() == 200) {
      Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
      System.debug('>>>>> AAZ - BillingAccount_Management_AP01 getRatePlanCharges mapRespData : ' + mapRespData);

      //object ooo = mapRespData.get('order');
      Map<String, Object> orderMap = (Map<String, Object>) mapRespData.get('order');
      if (orderMap != null) {
        for (Object orderActionMap : (List<Object>) orderMap.get('orderActions')) {
          Map<String, Object> orderActions = (Map<String, Object>) orderActionMap;
          Map<String, Object> addProductMap = (Map<String, Object>) orderActions.get('addProduct');

          for (Object chargeMap : (List<Object>) addProductMap.get('chargeOverrides')) {
            Map<String, Object> charges = (Map<String, Object>) chargeMap;
            Map<String, Object> pricingMap = (Map<String, Object>) charges.get('pricing');

            for (String key : pricingMap.keySet()) {
              //if(key.startsWith('usage')) {
              if (key == 'usagePerUnit') {
                Map<String, Object> usagePerUnitMap = (Map<String, Object>) pricingMap.get('usagePerUnit');
                usagePerUnitMap.remove('listPriceBase');
              }
              chargeOverride = new Map<String, Object>();
              chargeOverride.put('productRatePlanChargeId', charges.get('productRateplanChargeId'));
              chargeOverride.put('pricing', pricingMap);
              chargeOverrides.add(chargeOverride);
              //}
            }
          }
        }
        System.debug('>>>>> AAZ - getRatePlanCharges chargeOverrides: ' + chargeOverrides);
      }
    }

    return chargeOverrides;
  }

  /**
   * @author AAZ
   * @date 18/02/2022
   * @description Reset Zuora lock time field on FinancialCenters
   * @param accounts
   */
  public static void resetZuoraLockTimeFC(List<Zuora__CustomerAccount__c> accounts) {
    List<Id> listFCIds = new List<Id>();
    List<ER_Financial_Center__c> listFCtoUpdate = new List<ER_Financial_Center__c>();

    for (Zuora__CustomerAccount__c a : accounts) {
      listFCIds.add(a.TECH_Financial_Center__c);
    }

    System.debug('##### AA resetZuoraLockTimeFC resetZuoraLockTimeFC:' + listFCIds);

    for (ER_Financial_Center__c fc : [
      SELECT Id, ER_Zuora_Lock_Time__c, ER_Last_Lock_Date__c
      FROM ER_Financial_Center__c
      WHERE Id IN :listFCIds
    ]) {
      System.debug('##### AA resetZuoraLockTimeFC fc:' + fc);
      listFCtoUpdate.add(
        new ER_Financial_Center__c(Id = fc.Id, ER_Zuora_Lock_Time__c = null, ER_Last_Lock_Date__c = null)
      );
    }

    Database.update(listFCtoUpdate, false);
  }
}