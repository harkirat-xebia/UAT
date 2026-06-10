/**
 * @author: ALK
 * @date: 14/04/2023
 * @desc: SmarterStructureDataCleansing
 * @see: SmarterStructureDataCleansing
 */

@RestResource(UrlMapping='/smarterStructureDataCleansing/*')
global with sharing class SmarterStructureDataCleansing {
  @HttpPost
  global static SmarterStructureDataCleansing.SmarterStructureResponse doPost(
    List<SmarterStructureDataCleansing.SmarterStructureRequest> data
  ) {
    try {
      Set<Id> accountsIds = new Set<Id>();
      System.debug('>>>>> ALK - data : ' + data);
      System.debug('>>>>> ALK - data.size : ' + data.size());
      if (!data.isEmpty()) {
        if (data.size() <= 200) {
          for (SmarterStructureDataCleansing.SmarterStructureRequest d : data) {
            if (String.isNotBlank(d.oneforceAccountId))
              accountsIds.add(d.oneforceAccountId);
            else
              return buildResponsePayload(false, 400, 'Required fields are missing: [oneforceAccountId]');
          }

          deleteStructure(accountsIds);
        } else
          return buildResponsePayload(false, 400, 'Max batch size limit exceeded [200 records per transaction]');
      } else
        return buildResponsePayload(false, 400, 'Required fields are missing: [oneforceAccountId]');
    } catch (Exception e) {
      return buildResponsePayload(false, 400, e.getMessage());
    }

    return buildResponsePayload(true, 200, 'The structure has been deleted successfully');
  }

  public static void deleteStructure(Set<Id> accounts) {
    UtilsBypass.setBypassAllVR(UserInfo.getUserId(), true);
    Set<String> classesToBeBypassed = new Set<String>{
      'ER_ContractLineItemTrigger',
      'ContractTrigger',
      'ZuoraQuoteTrigger',
      'ZuoraSubscriptionChargesTrigger',
      'ZuoraSubscriptionTrigger',
      'SolutionLineItemTriggerHandler',
      'ZuoraQuoteRatePlanChargeTrigger',
      'ZuoraQuoteTrigger',
      'OpportunityTriggerHandler',
      'OpportunityLineItemTrigger',
      'BillingAccountTrigger2',
      'FinancialCenterTrigger',
      'ContactTriggerHandler',
      'AccountTriggerHandler',
      'LeadTrigger'
    };
    UtilsBypass.setBypassedTriggersByApex(classesToBeBypassed);

    try {
      List<String> smarterBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
        ?.split(Constants.SEMICOLON);

      // Subscription Rate Plan Charge Tiers
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Zuora__SubscriptionRatePlanChargeTier__c> subTires = [
        SELECT Id
        FROM Zuora__SubscriptionRatePlanChargeTier__c
        WHERE
          (Zuora__SubscriptionProductCharge__r.Zuora__Subscription__r.Zuora__Account__r.ER_SmartER_Context__c = TRUE
          OR Zuora__SubscriptionProductCharge__r.Zuora__Subscription__r.Zuora__Account__r.ER_BUPicklist__c IN :smarterBUs)
          AND Zuora__SubscriptionProductCharge__r.Zuora__Subscription__r.Zuora__Account__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + subTires.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(subTires);

      //Subscription Product Charges
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Zuora__SubscriptionProductCharge__c> subCharges = [
        SELECT Id
        FROM Zuora__SubscriptionProductCharge__c
        WHERE
          (Zuora__Subscription__r.Zuora__Account__r.ER_SmartER_Context__c = TRUE
          OR Zuora__Subscription__r.Zuora__Account__r.ER_BUPicklist__c IN :smarterBUs)
          AND Zuora__Subscription__r.Zuora__Account__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + subCharges.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(subCharges);

      //Subscription Rate Plans
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Zuora__SubscriptionRatePlan__c> subRatePlans = [
        SELECT Id
        FROM Zuora__SubscriptionRatePlan__c
        WHERE
          (Zuora__Subscription__r.Zuora__Account__r.ER_SmartER_Context__c = TRUE
          OR Zuora__Subscription__r.Zuora__Account__r.ER_BUPicklist__c IN :smarterBUs)
          AND Zuora__Subscription__r.Zuora__Account__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + subRatePlans.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(subRatePlans);

      //Subscriptions
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Zuora__Subscription__c> subs = [
        SELECT Id
        FROM Zuora__Subscription__c
        WHERE
          (Zuora__Account__r.ER_SmartER_Context__c = TRUE
          OR Zuora__Account__r.ER_BUPicklist__c IN :smarterBUs)
          AND Zuora__Account__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + subs.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(subs);

      //Contract Line Items
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<ER_ContractLineItem__c> contractLineItems = [
        SELECT Id
        FROM ER_ContractLineItem__c
        WHERE
          (ER_Contract__r.ER_SmartER_Context__c = TRUE
          OR ER_Contract__r.ER_BUPicklist__c IN :smarterBUs)
          AND ER_Contract__r.AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + contractLineItems.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(contractLineItems);

      //Contracts
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Contract> contracts = [
        SELECT Id
        FROM Contract
        WHERE (ER_SmartER_Context__c = TRUE OR ER_BUPicklist__c IN :smarterBUs) AND AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + contracts.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(contracts);

      //Distribution Point Line Items
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<ER_Solution_Line_Item__c> dpslis = [
        SELECT Id
        FROM ER_Solution_Line_Item__c
        WHERE
          ER_Distribution_Point__c != NULL
          AND (ER_Distribution_Point__r.ER_BUPicklist__c IN :smarterBUs
          OR ER_Distribution_Point__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_SmartER_Context__c = TRUE)
          AND ER_Distribution_Point__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + dpslis.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(dpslis);

      //Delivery Site Line Items
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<ER_Solution_Line_Item__c> dsslis = [
        SELECT Id
        FROM ER_Solution_Line_Item__c
        WHERE
          ER_Delivery_Site__c != NULL
          AND (ER_Delivery_Site__r.ER_BUPicklist__c IN :smarterBUs
          OR ER_Delivery_Site__r.ER_Financial_Center__r.ER_SmartER_Context__c = TRUE)
          AND ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + dsslis.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(dsslis);

      //Financial Center Line Items
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<ER_Solution_Line_Item__c> fcli = [
        SELECT Id
        FROM ER_Solution_Line_Item__c
        WHERE
          ER_Financial_Center__c != NULL
          AND (ER_Financial_Center__r.ER_BUPicklist__c IN :smarterBUs
          OR ER_Financial_Center__r.ER_SmartER_Context__c = TRUE)
          AND ER_Financial_Center__r.ER_Account_Name__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + fcli.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(fcli);

      //Account Line Items
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<ER_Solution_Line_Item__c> alis = [
        SELECT Id
        FROM ER_Solution_Line_Item__c
        WHERE ER_Account__c != NULL AND ER_Account__r.ER_BUPicklist__c IN :smarterBUs AND ER_Account__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + alis.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(alis);

      //Quote Rate Plan Charges
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<zqu__QuoteRatePlanCharge__c> ratePlanCharges = [
        SELECT Id
        FROM zqu__QuoteRatePlanCharge__c
        WHERE
          (ER_Quote__r.ER_SmartER_Context__c = TRUE
          OR ER_Quote__r.zqu__Opportunity__r.ER_BUPicklist__c IN :smarterBUs)
          AND ER_Quote__r.zqu__Opportunity__r.AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + ratePlanCharges.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(ratePlanCharges);

      //Quote Charge Details
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<zqu__QuoteChargeDetail__c> quoteChargeDetails = [
        SELECT Id
        FROM zqu__QuoteChargeDetail__c
        WHERE
          (zqu__Quote__r.ER_SmartER_Context__c = TRUE
          OR zqu__Quote__r.zqu__Opportunity__r.ER_BUPicklist__c IN :smarterBUs)
          AND zqu__Quote__r.zqu__Opportunity__r.AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + quoteChargeDetails.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(quoteChargeDetails);

      //Quote Rate Plans
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<zqu__QuoteRatePlan__c> quoteRatePlans = [
        SELECT Id
        FROM zqu__QuoteRatePlan__c
        WHERE
          (zqu__Quote__r.ER_SmartER_Context__c = TRUE
          OR zqu__Quote__r.zqu__Opportunity__r.ER_BUPicklist__c IN :smarterBUs)
          AND zqu__Quote__r.zqu__Opportunity__r.AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + quoteRatePlans.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(quoteRatePlans);

      //Quote Amendments
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<zqu__QuoteAmendment__c> quoteAmendments = [
        SELECT Id
        FROM zqu__QuoteAmendment__c
        WHERE
          (zqu__Quote__r.ER_SmartER_Context__c = TRUE
          OR zqu__Quote__r.zqu__Opportunity__r.ER_BUPicklist__c IN :smarterBUs)
          AND zqu__Quote__r.zqu__Opportunity__r.AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + quoteAmendments.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(quoteAmendments);

      //Quotes
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<zqu__Quote__c> quotes = [
        SELECT Id
        FROM zqu__Quote__c
        WHERE
          (ER_SmartER_Context__c = TRUE
          OR zqu__Opportunity__r.ER_BUPicklist__c IN :smarterBUs)
          AND zqu__Opportunity__r.AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + quotes.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(quotes);

      //Opportunity Line Items
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<OpportunityLineItem> qlis = [
        SELECT Id
        FROM OpportunityLineItem
        WHERE Opportunity.ER_SmartER_Context__c = TRUE AND Opportunity.AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + qlis.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(qlis);

      //Opportunities
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Opportunity> opps = [
        SELECT Id
        FROM Opportunity
        WHERE ER_SmartER_Context__c = TRUE AND AccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + opps.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(opps);

      //Billing Accounts
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Zuora__CustomerAccount__c> billingAccounts = [
        SELECT Id
        FROM Zuora__CustomerAccount__c
        WHERE
          (Zuora__Account__r.ER_SmartER_Context__c = TRUE
          OR Zuora__Account__r.ER_BUPicklist__c IN :smarterBUs)
          AND Zuora__Account__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + billingAccounts.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(billingAccounts);

      //Financial Centers
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<ER_Financial_Center__c> financialCenters = [
        SELECT Id
        FROM ER_Financial_Center__c
        WHERE (ER_SmartER_Context__c = TRUE OR ER_BUPicklist__c IN :smarterBUs) AND ER_Account_Name__c IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + financialCenters.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(financialCenters);

      //Cases
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Case> cases = [SELECT Id FROM Case WHERE AccountId IN :accounts OR Contact.AccountId IN :accounts];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + cases.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(cases);

      //Contacts
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Contact> contacts = [
        SELECT Id
        FROM Contact
        WHERE
          (ER_SmartER_Context__c = TRUE
          OR ER_BUPicklist__c IN :smarterBUs)
          AND AccountId IN :accounts
          AND Account.IsPersonAccount = FALSE
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + contacts.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(contacts);

      //GET Edenred+ Users
      Set<Id> edenredPlusUsers = new Set<Id>();
      List<ER_Employee__c> employees = new List<ER_Employee__c>();
      for (ER_Employee__c e : [
        SELECT Id, User_EdenredPlus__c
        FROM ER_Employee__c
        WHERE ER_BUPicklist__c IN :smarterBUs AND ER_Client__c IN :accounts
      ]) {
        employees.add(e);
        edenredPlusUsers.add(e.User_EdenredPlus__c);
      }

      if (!edenredPlusUsers.isEmpty()) {
        //Employees
        System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
        System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
        System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
        System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
        if (
          Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
          (Limits.getDmlRows() + employees.size()) < Limits.getLimitDmlRows()
        )
          Database.delete(employees);

        List<Asset> issuerAccounts = [
          SELECT Id
          FROM Asset
          WHERE
            RecordType.DeveloperName = 'Issuer_Account'
            AND ER_BUPicklist__c IN :smarterBUs
            AND EdenredPlus__c IN :edenredPlusUsers
        ];

        if (!issuerAccounts.isEmpty()) {
          //Cards
          System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
          System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
          System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
          System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
          List<Asset> cards = [
            SELECT Id
            FROM Asset
            WHERE
              RecordType.DeveloperName = 'Edenred_plus'
              AND ER_BUPicklist__c IN :smarterBUs
              AND ER_Issuer_Account__c IN :issuerAccounts
          ];
          if (
            Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
            (Limits.getDmlRows() + cards.size()) < Limits.getLimitDmlRows()
          )
            Database.delete(cards);

          //Issuer Accounts
          System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
          System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
          System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
          System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
          if (
            Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
            (Limits.getDmlRows() + issuerAccounts.size()) < Limits.getLimitDmlRows()
          )
            Database.delete(issuerAccounts);
        }

        //User Accounts
        System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
        System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
        System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
        System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
        List<ER_User_Account__c> userAccounts = [
          SELECT Id
          FROM ER_User_Account__c
          WHERE EdenredPlus__c IN :edenredPlusUsers AND ER_BUPicklist__c IN :smarterBUs
        ];
        if (
          Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
          (Limits.getDmlRows() + userAccounts.size()) < Limits.getLimitDmlRows()
        )
          Database.delete(userAccounts);

        //Edenred+ Users
        System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
        System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
        System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
        System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
        List<Account> edenredUsers = [
          SELECT Id
          FROM Account
          WHERE Id IN :edenredPlusUsers AND RecordType.DeveloperName = 'EdenredPlus' AND ER_BUPicklist__c IN :smarterBUs
        ];
        if (
          Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
          (Limits.getDmlRows() + edenredUsers.size()) < Limits.getLimitDmlRows()
        )
          Database.delete(edenredUsers);
      }

      //Accounts
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Account> businessAccounts = [
        SELECT Id
        FROM Account
        WHERE (ER_BUPicklist__c IN :smarterBUs OR ER_SmartER_Context__c = TRUE) AND Id IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + businessAccounts.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(businessAccounts);

      //Leads
      System.debug('>>>>> ALK - Limits.getDmlStatements() : ' + Limits.getDmlStatements());
      System.debug('>>>>> ALK - Limits.getLimitDmlStatements() : ' + Limits.getLimitDmlStatements());
      System.debug('>>>>> ALK - Limits.getDmlRows() : ' + Limits.getDmlRows());
      System.debug('>>>>> ALK - Limits.getLimitDmlRows() : ' + Limits.getLimitDmlRows());
      List<Lead> leads = [
        SELECT Id
        FROM Lead
        WHERE (ER_BUPicklist__c IN :smarterBUs OR ER_SmartER_Context__c = TRUE) AND ConvertedAccountId IN :accounts
      ];
      if (
        Limits.getDmlStatements() < Limits.getLimitDmlStatements() &&
        (Limits.getDmlRows() + leads.size()) < Limits.getLimitDmlRows()
      )
        Database.delete(leads);

      UtilsBypass.setBypassAllVR(UserInfo.getUserId(), false);
    } catch (DmlException de) {
      System.debug('>>>>> ALK - DmlException - Cause : ' + de.getCause() + ' - Message : ' + de.getMessage());
      UtilsBypass.setBypassAllVR(UserInfo.getUserId(), false);
    } catch (Exception e) {
      System.debug('>>>>> ALK - DmlException - Cause : ' + e.getCause() + ' - Message : ' + e.getMessage());
      UtilsBypass.setBypassAllVR(UserInfo.getUserId(), false);
    }
  }

  public static SmarterStructureDataCleansing.SmarterStructureResponse buildResponsePayload(
    Boolean isSucess,
    Integer statusCode,
    String msg
  ) {
    return new SmarterStructureDataCleansing.SmarterStructureResponse(isSucess, statusCode, msg);
  }

  global class SmarterStructureResponse {
    public Integer statusCode { get; set; }
    public Boolean success { get; set; }
    //public String oneforceAccountId {get; set;}
    public String message { get; set; }

    public SmarterStructureResponse(Boolean success, Integer statusCode, String message) {
      this.success = success;
      //this.oneforceAccountId = oneforceAccountId;
      this.statusCode = statusCode;
      this.message = message;
    }
  }

  global class SmarterStructureRequest {
    public String oneforceAccountId { get; set; }
  }
}