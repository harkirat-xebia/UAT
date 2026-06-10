/**
 * @author : AAZ
 * @date : 26/08/2022
 * @desc : ER_CreateSmartERSubscription
 * @see ER_CreateSmartERSubscription
 */

public with sharing class ER_CreateSmartERSubscription implements Queueable, Database.AllowsCallouts {
  public List<ER_ZuoraQuoteAPI.Record> records { get; set; }
  public Map<Id, Opportunity> opps { get; set; }
  public Map<String, Zuora__CustomerAccount__c> bas { get; set; }
  public Map<String, zqu__ProductRatePlan__c> prRatePlansAndCharges { get; set; }
  public final static Integer MAX_LENGTH = 80;
  Set<String> fcIds { get; set; }

  public ER_CreateSmartERSubscription(
    List<ER_ZuoraQuoteAPI.Record> items,
    Map<Id, Opportunity> mapOpps,
    Map<String, Zuora__CustomerAccount__c> mapBAs,
    Map<String, zqu__ProductRatePlan__c> mapPrRatePlansAndCharges
  ) {
    this.records = items;
    this.opps = mapOpps;
    this.bas = mapBAs;
    this.prRatePlansAndCharges = mapPrRatePlansAndCharges;
  }

  public void execute(QueueableContext ctxt) {
    List<zqu__Quote__c> quotes = new List<zqu__Quote__c>();
    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    Map<String, ER_ZuoraQuoteAPI.Record> mapOppRecords = new Map<String, ER_ZuoraQuoteAPI.Record>();

    //Get Financial Centers per BA
    Map<Id, Zuora__CustomerAccount__c> mapFCBA = new Map<Id, Zuora__CustomerAccount__c>();
    for (Zuora__CustomerAccount__c ba : this.bas.values()) {
      mapFCBA.put(ba.ER_Financial_Center__c, ba);
    }

    Map<Id, ER_Financial_Center__c> fcs = new Map<Id, ER_Financial_Center__c>(
      [SELECT Id, ER_Contact__c, ER_BUPicklist__c FROM ER_Financial_Center__c WHERE Id IN :mapFCBA.keySet()]
    );

    if (fcs != null && !fcs.isEmpty()) {
      String entityName = Utils.getGlobalSettingsValueFromKey(
        Constants.ZUORA_ENTITY_NAME + fcs.values()[0].ER_BUPicklist__c
      );
      zqu__BillingEntity__c zEntity = [
        SELECT Id, zqu__EntityID__c, zqu__EntityName__c
        FROM zqu__BillingEntity__c
        WHERE zqu__EntityName__c = :entityName
        LIMIT 1
      ];

      //****Build the Quote Objects
      for (ER_ZuoraQuoteAPI.Record rec : records) {
        mapOppRecords.put(rec.opportunityId, rec);
        Opportunity opp = opps.get(rec.opportunityId);
        Zuora__CustomerAccount__c ba = bas.get(rec.billingAccountNumber);

        //Dates calculation
        Date startDate = Date.today();
        if (opp.ER_Contract_Expected_Start_Date__c != null) {
          startDate = opp.ER_Contract_Expected_Start_Date__c;
        }
        Integer startDateYear = startDate.year();
        Date firstDayOfYear = Date.newInstance(startDateYear, 1, 1);

        //****New Quote
        zqu__Quote__c newQuote = new zqu__Quote__c();
        newQuote.Name = ZuoraUtils.getZuoraQuoteName(opp);
        newQuote.zqu__Amendment_Name__c = ('AM-' + opp.Name).left(MAX_LENGTH);
        newQuote.zqu__Opportunity__c = opp.Id;
        newQuote.zqu__BillToContact__c = fcs.containsKey(ba.ER_Financial_Center__c)
          ? fcs.get(ba.ER_Financial_Center__c).ER_Contact__c
          : null;
        newQuote.zqu__SoldToContact__c = fcs.containsKey(ba.ER_Financial_Center__c)
          ? fcs.get(ba.ER_Financial_Center__c).ER_Contact__c
          : null;
        newQuote.zqu__Currency__c = opp.CurrencyIsoCode;
        if (startDate.day() == 1) {
          newQuote.zqu__Customer_Acceptance_Date__c = startDate;
          newQuote.zqu__Service_Activation_Date__c = startDate;
        } else {
          if (startDate.month() == 12)
            startDateYear = startDateYear + 1;
          newQuote.zqu__Customer_Acceptance_Date__c = Date.newInstance(
            startDateYear,
            startDate.addMonths(1).month(),
            1
          );
          newQuote.zqu__Service_Activation_Date__c = Date.newInstance(startDateYear, startDate.addMonths(1).month(), 1);
        }
        newQuote.zqu__StartDate__c = startDate;
        newQuote.zqu__TermStartDate__c = firstDayOfYear;
        newQuote.zqu__PaymentTerm__c = ba.Zuora__PaymentTerm__c;
        newQuote.zqu__Zuora_Account_Number__c = ba.Zuora__AccountNumber__c;
        newQuote.zqu__ZuoraAccountID__c = ba.Zuora__Zuora_Id__c;
        newQuote.zqu__BillingEntity__c = zEntity.Id;
        newQuote.zqu__ZuoraEntityId__c = zEntity.zqu__EntityID__c;
        newQuote.ER_Business_Unit__c = opp.ER_BUPicklist__c;
        newQuote.zqu__Account__c = opp.AccountId;
        newQuote.zqu__Status__c = Constants.DRAFT;
        newQuote.zqu__ValidUntil__c = Date.today().addDays(30);
        newQuote.zqu__Subscription_Term_Type__c = Constants.ZUORA_TERM_TYPE_EVERGREEN;
        newQuote.zqu__QuoteBusinessType__c = Constants.NEW_STATUS;
        newQuote.zqu__SubscriptionType__c = Constants.ZUORA_NEW_SUBSCRIPTION;
        newQuote.zqu__BillCycleDay__c = '1';
        newQuote.zqu__BillingBatch__c = Constants.ZUORA_BILLING_BATCH1;
        newQuote.zqu__BillingMethod__c = Constants.ZUORA_BILLING_METHOD_EMAIL;
        newQuote.zqu__Calculate_Quote_Metrics_Through__c = '1';
        newQuote.zqu__InvoiceProcessingOption__c = Constants.ZUORA_INVOICE_PROCESSING_SUBSCRIPTION;
        newQuote.zqu__PaymentMethod__c = opp.ER_PaymentMethod__c;
        //newQuote.zqu__InvoiceTemplate__c = null;
        //newQuote.zqu__CommunicationProfile__c = null;
        newQuote.ER_Customer_Signed_Version__c = rec.customerSignedVersion;

        String agreementDatetime = rec.agreementDateTime.replace('T', ' ');
        newQuote.ER_Agreement_DateTime__c = Datetime.valueOf(agreementDatetime);
        newQuote.ER_TCs_Signed_Link__c = rec.tcsSignedLink;
        quotes.add(newQuote);
      }
    }

    //Insert the Quote records
    Set<Id> insertedQuoteIds = new Set<Id>();
    Map<Id, List<String>> mapfailedOppsErrors = new Map<Id, List<String>>();
    if (!quotes.isEmpty()) {
      Database.SaveResult[] lstResults = Database.insert(quotes, false);

      for (Integer i = 0; i < lstResults.size(); i++) {
        if (lstResults[i].isSuccess()) {
          insertedQuoteIds.add(lstResults[i].getId());
        } else {
          List<String> lstMessages = new List<String>();
          for (Database.Error err : lstResults[i].getErrors()) {
            lstMessages.add(err.getMessage());
            System.debug('#####AA ER_CreateSmartERSubscription Database.Error:' + err.getMessage());
          }
          mapfailedOppsErrors.put(quotes[i].zqu__Opportunity__c, lstMessages);
        }
      }
      System.debug('#####AA ER_CreateSmartERSubscription insertedQuoteIds: ' + insertedQuoteIds);
    }

    //Add Quote childs
    List<zqu__Quote__c> listQuotesToAccept = new List<zqu__Quote__c>();
    for (Id quotId : insertedQuoteIds) {
      //Get an existing quote instance by Id
      zqu.Quote instanceQuote = zqu.Quote.getInstance(quotId);
      zqu__Quote__c quoteSObject = instanceQuote.getSObject();

      List<zqu.Product> quoteProducts = new List<zqu.Product>();
      zqu.Product zp;

      List<ER_ZuoraQuoteAPI.ProductRateplan> listPRP = mapOppRecords.get(quoteSObject.zqu__Opportunity__c).ratePlans;
      System.debug('#####AA ER_CreateSmartERSubscription - listPRP:' + listPRP);

      //Extract the ProductId linked to the Quote
      ER_ZuoraQuoteAPI.ProductRateplan firstRpRec = listPRP[0];
      zqu__ProductRatePlan__c prpData = prRatePlansAndCharges.get(firstRpRec.ratePlanId);
      zp = zqu.Product.loadProduct(prpData.zqu__Product__c);

      //Get all RatePlan Ids
      List<String> listRpIds = new List<String>();
      for (ER_ZuoraQuoteAPI.ProductRateplan prp : listPRP) {
        listRpIds.add(prp.ratePlanId);
      }

      //Remove the extra RatePlans from the zProduct
      for (Integer i = zp.productRatePlans.size() - 1; i >= 0; i--) {
        if (!listRpIds.contains(zp.productRatePlans.get(i).sfdcProductRatePlan.zqu__ZuoraId__c))
          zp.productRatePlans.remove(i);
      }
      System.debug('#####AA ER_CreateSmartERSubscription - remaining zp.productRatePlans:' + zp.productRatePlans);

      //Commit the Products/RP to the Database
      if (!Test.isRunningTest()) {
        quoteProducts.add(zp);
        instanceQuote.addQuoteProducts(quoteProducts);
        instanceQuote.save();

        //Move the Quote Status to Accepted
        listQuotesToAccept.add(new zqu__Quote__c(Id = quotId, zqu__Status__c = Constants.ACCEPTED));
      }

      //To Update the Opportunity.ER_SmartER_Drop_Case_Step__c
      ER_ZuoraQuoteAPI.Record currentRec = mapOppRecords.get(quoteSObject.zqu__Opportunity__c);
      if (String.IsNotBlank(currentRec.dropStep))
        oppsToUpdate.add(
          new Opportunity(Id = currentRec.opportunityId, ER_SmartER_Drop_Case_Step__c = currentRec.dropStep)
        );
    }

    //Update Opportunities
    if (!oppsToUpdate.isEmpty()) {
      System.debug('#####AA ER_CreateSmartERSubscription - oppsToUpdate:' + oppsToUpdate);
      Database.SaveResult[] results = Database.update(oppsToUpdate, false);

      for (Database.SaveResult sr : results) {
        if (!sr.isSuccess()) {
          for (Database.Error err : sr.getErrors()) {
            System.debug('#####AA ER_CreateSmartERSubscription Update Opportunities - DML Errors:');
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug(
              '#####AA ER_CreateSmartERSubscription Update Opportunities - Fields that affected this error: ' +
              err.getFields()
            );
          }
        }
      }
    }

    //Update Quote records
    if (!listQuotesToAccept.isEmpty()) {
      System.debug('#####AA ER_CreateSmartERSubscription - listQuotesToAccept:' + listQuotesToAccept);
      Database.SaveResult[] results = Database.update(listQuotesToAccept, false);

      for (Database.SaveResult sr : results) {
        if (!sr.isSuccess()) {
          for (Database.Error err : sr.getErrors()) {
            System.debug('#####AA ER_CreateSmartERSubscription Accept Quotes - DML Errors:');
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug(
              '#####AA ER_CreateSmartERSubscription Accept Quotes - Fields that affected this error: ' + err.getFields()
            );
          }
        }
      }
    }

    //Manage Failed Quotes
    // TODO: All failing zquote should be track asyn in the log object (the method should be created in Utils class)
    if (!mapfailedOppsErrors.isEmpty()) {
      System.debug('#####AA ER_CreateSmartERSubscription mapfailedOppsErrors: ' + mapfailedOppsErrors);
      //Utils.logMessage
    }
  }
}