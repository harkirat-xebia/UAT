/**
 * @author : AAZ
 * @date : 11/07/2021
 * @desc : ER_SendQuoteToZuora
 * @see ER_SendQuoteToZuora
 */

public with sharing class ER_SendQuoteToZuora implements Queueable, Database.AllowsCallouts {
  Map<Id, Contract> mapQuoteContract { get; set; }
  Map<String, Zuora__CustomerAccount__c> mapBAccountsTerms { get; set; }
  Set<String> BANumbers = new Set<String>();

  public ER_SendQuoteToZuora(Map<Id, Contract> mapQContract, Set<String> accountsNumbers) {
    this.mapQuoteContract = mapQContract;
    this.BANumbers = accountsNumbers;
  }

  public void execute(QueueableContext ctxt) {
    List<zqu.zQuoteUtil.ZBillingQuoteCollection> quotes = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>();
    String updateTermResponse;

    String zuoraToken = ZuoraUtils.getZuoraToken();

    String bu = mapQuoteContract.values()[0].ER_BUPicklist__c;

    for (Zuora__CustomerAccount__c ba : ZuoraUtils.retrieveBillingAccounts(this.BANumbers, bu).values()) {
      if (mapBAccountsTerms == null)
        mapBAccountsTerms = new Map<String, Zuora__CustomerAccount__c>();
      mapBAccountsTerms.put(ba.Zuora__AccountNumber__c, ba);
    }

    for (Id contr : this.mapQuoteContract.keySet()) {
      String baId = this.mapQuoteContract.get(contr).ER_ZuoraQuote__r.zqu__Zuora_Account_Number__c;
      updateTermResponse = '';

      System.debug(
        '####### AAZ Quote PaymentTerm__c:' + this.mapQuoteContract.get(contr).ER_ZuoraQuote__r.zqu__PaymentTerm__c
      );
      System.debug('####### AAz Account PaymentTerm__c:' + this.mapBAccountsTerms.get(baId).Zuora__PaymentTerm__c);

      //Update BA Pyment Term in Zuora if BA Payment Term != ZQuote Payment Term
      if (
        String.isNotBlank(this.mapQuoteContract.get(contr).ER_ZuoraQuote__r.zqu__PaymentTerm__c) &&
        this.mapBAccountsTerms.get(baId).Zuora__PaymentTerm__c !=
        this.mapQuoteContract.get(contr).ER_ZuoraQuote__r.zqu__PaymentTerm__c
      ) {
        updateTermResponse = ZuoraUtils.updateZuoraAccountPaymentTerm(
          this.mapQuoteContract.get(contr).ER_ZuoraQuote__r.zqu__PaymentTerm__c,
          this.mapBAccountsTerms.get(baId),
          zuoraToken
        );
      }

      System.debug('####### updateTermResponse:' + updateTermResponse);

      //Prepare the Quote to be sent to Zuora
      zqu.zQuoteUtil.ZBillingQuoteCollection quote = new zqu.zQuoteUtil.ZBillingQuoteCollection();
      quote.sfdcAccountId = this.mapQuoteContract.get(contr).ER_ZuoraQuote__r.zqu__Account__c; //SFDC CRM Account ID
      quote.zAccountId = this.mapQuoteContract.get(contr).ER_ZuoraQuote__r.zqu__ZuoraAccountID__c; //Zuora Billing Account ID

      quote.quoteRequests = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();
      zqu.zQuoteUtil.ZBillingQuoteRequest req = new zqu.zQuoteUtil.ZBillingQuoteRequest();
      req.sfdcQuoteId = this.mapQuoteContract.get(contr).ER_ZuoraQuote__c; //SFDC Quote ID
      quote.quoteRequests.add(req);
      quotes.add(quote);
    }

    System.debug('#######createZuoraSubscription quotes:' + quotes);
    if (!quotes.isEmpty()) {
      List<zqu.zQuoteUtil.ZBillingResult> results = zqu.zQuoteUtil.sendToZBilling(quotes);

      for (zqu.zQuoteUtil.ZBillingResult result : results) {
        System.debug(
          '>>> ALK - ER_SendQuoteToZuora Result: Success = ' +
          result.success +
          ', message = ' +
          result.message
        );
      }
    }
  }
}