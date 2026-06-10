/**
 * @author : AAZ
 * @date : 21/04/2021
 * @desc : ER_ZuoraQuoteSelectEntity
 * @see ER_ZuoraQuoteSelectEntity
 */
global without sharing class ER_ZuoraQuoteSelectEntity implements zqu.SelectEntityComponentOptions.ISelectEntityPlugin {
  global zqu.SelectEntityComponentOptions.SelectEntityPluginResponse selectEntityForNewQuote(
    String accountId,
    String opportunityId
  ) {
    Opportunity opp = [
      SELECT Id, ER_Smarter_Context__c, ER_BUPicklist__c
      FROM Opportunity
      WHERE Id = :opportunityId
      LIMIT 1
    ];

    //Get EntityId from Settings
    String sfEntityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + opp.ER_BUPicklist__c);

    //Query Zuora Entities Object
    ID entityIdtoSelect = [SELECT Id FROM zqu__BillingEntity__c WHERE zqu__EntityID__c = :sfEntityId]?.Id;

    zqu.SelectEntityComponentOptions.SelectEntityPluginResponse resp = new zqu.SelectEntityComponentOptions.SelectEntityPluginResponse();

    //Pre-Select the right entity Id on the ZQuote creation page
    resp.selectedId = entityIdtoSelect;
    resp.autoSubmit = true;

    return resp;
  }
}