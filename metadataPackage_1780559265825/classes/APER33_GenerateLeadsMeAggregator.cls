public class APER33_GenerateLeadsMeAggregator {
  @AuraEnabled
  public static void generateAggregatorLeads(Id aAccountId) {
    Set<Id> aggMerchantIds = new Set<Id>();
    Id aggregatorMerchantRTId = Utils.getRecordTypeIdByDeveloperName(
      Account.SObjectType,
      Constants.ACCOUNT_AGGREGATOR_MERCHANT_RT
    );

    for (AccountPartner ap : [
      SELECT Id, AccountFromId, AccountToId
      FROM AccountPartner
      WHERE AccountToId = :aAccountId AND Role = :Constants.PARTNER_ROLE_AGGREGATOR
    ]) {
      aggMerchantIds.add(ap.AccountFromId);
    }

    List<Account> accList = [
      SELECT
        Id,
        Description,
        Name,
        ER_Legal_Name__c,
        BillingCity,
        BillingCountry,
        BillingPostalCode,
        ER_Registration_Number__c,
        BillingStreet,
        ER_VAT_Number__c,
        BillingState,
        ER_BUPicklist__c
      FROM Account
      WHERE RecordTypeId = :aggregatorMerchantRTId AND Id IN :aggMerchantIds
      LIMIT 10000
    ];

    if (!accList.isEmpty())
      APER20_Account_Management.processAggregatorAccounts(accList);
  }
}