/**
 * @author : AAZ
 * @date : 12/07/2021
 * @desc : ER_ZuoraQuoteSelectBillingAccount
 * @see ER_ZuoraQuoteSelectBillingAccount
 */

global class ER_ZuoraQuoteSelectBillingAccount implements zqu.SelectBillingAccountComponentOptions.ICustomizeBillingAccountPlugin {
  global zqu.JSRemoteController.BillingAccountObjects getAvailableBillingAccounts(
    zqu.JSRemoteController.BillingAccountObjects accountObjs
  ) {
    String OpportunityType;
    System.debug(
      '>>>>> AAZ - ER_ZuoraQuoteSelectBillingAccount getAvailableBillingAccounts accountObjs : ' + accountObjs
    );
    if (String.isNotBlank(accountObjs.opportunityId)) {
      Opportunity opp = [SELECT Id, RecordType.Name FROM Opportunity WHERE Id = :accountObjs.opportunityId LIMIT 1];
      if (opp != null) {
        OpportunityType = opp.RecordType.Name;
      }
    }

    // Remove the 'new' account type
    // to disallow new account creation
    accountObjs.billingAccountTypes.remove(0);

    // Set the default selected billing account type
    accountObjs.defaultBillingAccountType = 'existing';

    //Keep only the Master BAccount
    Map<String, Zuora__CustomerAccount__c> mapBA = new Map<String, Zuora__CustomerAccount__c>();
    for (Zuora__CustomerAccount__c obj : [
      SELECT
        Id,
        Zuora__AccountNumber__c,
        Zuora__Account__c,
        Zuora__Zuora_Id__c,
        ER_Financial_Center__r.ER_Master__c,
        ER_Financial_Center__r.ER_Type__c
      FROM Zuora__CustomerAccount__c
      WHERE Zuora__Account__c = :accountObjs.sfdcAccountId
    ]) {
      mapBA.put(obj.Zuora__AccountNumber__c, obj);
    }

    if (!Test.isRunningTest()) {
      System.debug(
        '>>>>> ALK - accountObjs.billingAccounts.dataObjects.size() : ' + accountObjs.billingAccounts.dataObjects.size()
      );
      for (Integer i = accountObjs.billingAccounts.dataObjects.size() - 1; i >= 0; i--) {
        System.debug(
          LoggingLevel.DEBUG,
          '>>>>> ALK - (String)accountObjs.billingAccounts.dataObjects.get(i).get(AccountNumber) : ' +
          (String) accountObjs.billingAccounts.dataObjects.get(i).get('AccountNumber')
        );
        System.debug(
          LoggingLevel.DEBUG,
          '>>>>> ALK - mapBA.get((String)accountObjs.billingAccounts.dataObjects.get(i).get(\'AccountNumber\')) : ' +
          mapBA.get((String) accountObjs.billingAccounts.dataObjects.get(i).get('AccountNumber'))
        );

        if (
          mapBA.containsKey((String) accountObjs.billingAccounts.dataObjects.get(i).get('AccountNumber')) &&
          (mapBA.get((String) accountObjs.billingAccounts.dataObjects.get(i).get('AccountNumber'))
            .ER_Financial_Center__r.ER_Master__c == false ||
          (String.isNotBlank(OpportunityType) &&
          !OpportunityType.containsIgnoreCase(
            mapBA.get((String) accountObjs.billingAccounts.dataObjects.get(i).get('AccountNumber'))
              .ER_Financial_Center__r.ER_Type__c
          )))
        ) {
          accountObjs.billingAccounts.dataObjects.remove(i);
        }
      }
    }

    return accountObjs;
  }

  global zqu.JSRemoteController.QuoteTypeObjects getAvailableQuoteTypes(
    zqu.JSRemoteController.QuoteTypeObjects quoteTypeObjs
  ) {
    System.debug(
      '>>>>> AAZ - ER_ZuoraQuoteSelectBillingAccount getAvailableQuoteTypes quoteTypeObjs : ' + quoteTypeObjs
    );
    Opportunity opp = [SELECT Id, ER_AmendedFromContract__c FROM Opportunity WHERE Id = :quoteTypeObjs.opportunityId];

    if (String.IsNotBlank(opp.ER_AmendedFromContract__c)) {
      // Remove the 'new' quote type
      quoteTypeObjs.quoteTypes.remove(0);

      // Set the default quote type to 'amend'
      quoteTypeObjs.defaultQuoteType = 'amend';
    }
    return quoteTypeObjs;
  }

  global zqu.JSRemoteController.SubscriptionObjects getAvailableSubscriptions(
    zqu.JSRemoteController.SubscriptionObjects subscriptionObjs
  ) {
    System.debug(
      '>>>>> AAZ - ER_ZuoraQuoteSelectBillingAccount getAvailableSubscriptions subscriptionObjs : ' + subscriptionObjs
    );

    Opportunity opp = [
      SELECT Id, ER_AmendedFromContract__c, ER_AmendedFromContract__r.Subscription__r.Name
      FROM Opportunity
      WHERE Id = :subscriptionObjs.opportunityId
    ];

    if (!Test.isRunningTest() && String.IsNotBlank(opp.ER_AmendedFromContract__c)) {
      for (Integer i = subscriptionObjs.subscriptions.dataObjects.size() - 1; i >= 0; i--) {
        //System.debug('>>>>> AAZ - ER_ZuoraQuoteSelectBillingAccount Sub : ' + (string)subscriptionObjs.subscriptions.dataObjects.get(i).get('Name'));

        if (
          (string) subscriptionObjs.subscriptions.dataObjects.get(i).get('Name') !=
          opp.ER_AmendedFromContract__r.Subscription__r.Name
        ) {
          subscriptionObjs.subscriptions.dataObjects.remove(i);
        }
      }
    }

    return subscriptionObjs;
  }
}