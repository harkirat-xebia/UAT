/**
 * @author : AAZ
 * @date : 14/08/2022
 * @desc : ER_ZuoraQuoteAPI
 * @see ER_ZuoraQuoteAPI
 * @example
 * {
    "records": [
        {
            "billingAccountNumber": "AFR00017712",
            "opportunityId": "0065r000005sZQUAA2",
            "dropStep": "Step 1",
			"customerSignedVersion": "20230116",
			"agreementDateTime": "2023-01-10T13:45:56.000Z",
			"tcsSignedLink": "https://er-europe--devonefce.sandbox.my.salesforce.com/sfc/p/5r0000004cxL/a/5r0000008uCQ/gmYmHJCiFYtecQ1AWqYdSKja7aVJ4iT5i2g7BenA9Jw"
            "ratePlans": [
                {
                    "ratePlanId": "8adcd67f8050997a01805fd3c69b1c5f"
                },
                {
                	"ratePlanId": "8adc8323805085bf018065dd045e4edf"
                }
            ]
        }
    ]
  }
*/

@RestResource(UrlMapping='/createSmartERSubscription/*')
global with sharing class ER_ZuoraQuoteAPI {
  @HttpPost
  global static ZuoraAPIResponse doPost(List<Record> records) {
    Set<Id> setOpportunities = new Set<Id>();
    Set<String> setBillingAccounts = new Set<String>();
    Set<String> setPrRatePlanIds = new Set<String>();
    String bu;

    //Return limit error
    if (records.size() > 10)
      return new ZuoraAPIResponse(
        false,
        Constants.STATUS_CODE_BADREQUEST,
        new List<Map<String, String>>{
          new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_API_LIMIT_10 }
        }
      );

    for (Record rec : records) {
      //Return required field error
      if (String.isBlank(rec.billingAccountNumber))
        return new ZuoraAPIResponse(
          false,
          Constants.STATUS_CODE_BADREQUEST,
          new List<Map<String, String>>{
            new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_BA_MISSINIG }
          }
        );

      if (String.isBlank(rec.opportunityId))
        return new ZuoraAPIResponse(
          false,
          Constants.STATUS_CODE_BADREQUEST,
          new List<Map<String, String>>{
            new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_OPP_MISSING }
          }
        );

      if (String.isNotBlank(rec.opportunityId) && !Utils.isValidSalesforceId(rec.opportunityId))
        return new ZuoraAPIResponse(
          false,
          Constants.STATUS_CODE_BADREQUEST,
          new List<Map<String, String>>{
            new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_ID_VALIDATION }
          }
        );

      if (String.isBlank(rec.customerSignedVersion))
        return new ZuoraAPIResponse(
          false,
          Constants.STATUS_CODE_BADREQUEST,
          new List<Map<String, String>>{
            new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_CSV_MISSING }
          }
        );

      if (String.isBlank(rec.agreementDateTime))
        return new ZuoraAPIResponse(
          false,
          Constants.STATUS_CODE_BADREQUEST,
          new List<Map<String, String>>{
            new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_ADT_MISSING }
          }
        );

      if (String.isNotBlank(rec.agreementDateTime) && !Utils.dateTimeIsoMatcher(rec.agreementDateTime))
        return new ZuoraAPIResponse(
          false,
          Constants.STATUS_CODE_BADREQUEST,
          new List<Map<String, String>>{
            new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_DATETIME_VALIDATION }
          }
        );

      if (String.isNotBlank(rec.opportunityId))
        setOpportunities.add(rec.opportunityId);
      if (String.isNotBlank(rec.billingAccountNumber))
        setBillingAccounts.add(rec.billingAccountNumber);

      System.debug('###### AA ER_ZuoraQuoteAPI ratePlans:' + rec.ratePlans);
      for (ProductRateplan prp : rec.ratePlans) {
        //Return required field error
        if (String.isBlank(prp.ratePlanId))
          return new ZuoraAPIResponse(
            false,
            Constants.STATUS_CODE_BADREQUEST,
            new List<Map<String, String>>{
              new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_RATEPLAN_MISSINIG }
            }
          );

        setPrRatePlanIds.add(prp.ratePlanId);
      }
    }

    //**Get Opportunities details
    Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>(
      [
        SELECT
          Id,
          Name,
          ER_Contract_Expected_Start_Date__c,
          AccountId,
          CurrencyIsoCode,
          Account.ER_Registration_Number__c,
          Account.Name,
          ER_BUPicklist__c,
          ER_PaymentMethod__c,
          (SELECT Id, zqu__Number__c, Name FROM zqu__Quotes__r ORDER BY zqu__Number__c DESC)
        FROM Opportunity
        WHERE Id IN :setOpportunities
      ]
    );
    if (!mapOpps.isEmpty())
      bu = mapOpps.values()[0].ER_BUPicklist__c;

    //Return Data check error
    if (mapOpps.size() < setOpportunities.size())
      return new ZuoraAPIResponse(
        false,
        Constants.STATUS_CODE_NOTFOUND,
        new List<Map<String, String>>{
          new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_OPP_NOT_FOUND }
        }
      );

    //**Get BillingAccount details from Zuora
    Map<String, Zuora__CustomerAccount__c> mapBAs = new Map<String, Zuora__CustomerAccount__c>();
    if (setBillingAccounts.size() > 0) {
      mapBAs = ZuoraUtils.retrieveBillingAccounts(setBillingAccounts, bu);
    }

    //Return Data check error
    if (mapBAs.size() < setBillingAccounts.size()) {
      return new ZuoraAPIResponse(
        false,
        Constants.STATUS_CODE_NOTFOUND,
        new List<Map<String, String>>{
          new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_BA_NOT_FOUND }
        }
      );
    }

    //**Get Product Rate Plans details
    Map<String, zqu__ProductRatePlan__c> mapPrRatePlansAndCharges = new Map<String, zqu__ProductRatePlan__c>();
    for (zqu__ProductRatePlan__c rp : [
      SELECT Id, Name, zqu__ZuoraId__c, zqu__Product__c
      FROM zqu__ProductRatePlan__c
      WHERE zqu__ZuoraId__c IN :setPrRatePlanIds
    ]) {
      mapPrRatePlansAndCharges.put(rp.zqu__ZuoraId__c, rp);
    }

    //Return Data check error
    if (mapPrRatePlansAndCharges.size() < setPrRatePlanIds.size())
      return new ZuoraAPIResponse(
        false,
        Constants.STATUS_CODE_NOTFOUND,
        new List<Map<String, String>>{
          new Map<String, String>{ Constants.MESSAGE => System.Label.LAB_SF_SMARTER_RATEPLAN_NOT_FOUND }
        }
      );

    System.debug('###### AAZ ER_ZuoraQuoteAPI :' + records);
    System.debug('###### AAZ ER_ZuoraQuoteAPI mapOpportunities:' + mapOpps);
    System.debug('###### AAZ ER_ZuoraQuoteAPI mapBillingAccounts:' + mapBAs);
    System.debug('###### AAZ ER_ZuoraQuoteAPI mapPrRatePlansAndCharges:' + mapPrRatePlansAndCharges);

    System.enqueueJob(new ER_CreateSmartERSubscription(records, mapOpps, mapBAs, mapPrRatePlansAndCharges));

    return new ZuoraAPIResponse(true, Constants.STATUS_CODE_OK, new List<Map<String, String>>());
  }

  global class Record {
    public String opportunityId { get; set; }
    public String billingAccountNumber { get; set; }
    public String dropStep { get; set; }
    public String customerSignedVersion { get; set; }
    public String agreementDateTime { get; set; }
    public String tcsSignedLink { get; set; }
    public List<ProductRateplan> ratePlans { get; set; }
  }

  global class ProductRateplan {
    public String ratePlanId { get; set; }
  }

  global class ZuoraAPIResponse {
    public Boolean success { get; set; }
    public Integer httpStatusCode { get; set; }
    public List<Map<String, String>> errors { get; set; }

    public ZuoraAPIResponse(Boolean suc, Integer code, List<Map<String, String>> err) {
      this.success = suc;
      this.httpStatusCode = code;
      this.errors = err;
    }
  }
}