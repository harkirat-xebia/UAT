/**
 * @author : AAZ
 * @date : 18/05/2021
 * @desc : ER_CreateChildSubforBillingAccount
 * @see ER_CreateChildSubforBillingAccount
 */

public class ER_CreateChildSubforBillingAccount implements Queueable, Database.AllowsCallouts {
  Map<Id, List<Zuora__CustomerAccount__c>> mapAccountIdBillingAccounts { get; set; }
  Map<Id, List<Zuora__Subscription__c>> mapAccountIdMasterSubscriptions { get; set; }

  public ER_CreateChildSubforBillingAccount(
    Map<Id, List<Zuora__CustomerAccount__c>> mapBillingAccounts,
    Map<Id, List<Zuora__Subscription__c>> mapMasterSubscriptions
  ) {
    this.mapAccountIdBillingAccounts = mapBillingAccounts;
    this.mapAccountIdMasterSubscriptions = mapMasterSubscriptions;
  }

  public void execute(QueueableContext ctxt) {
    String zuoraToken = ZuoraUtils.getZuoraToken();
    BillingAccount_Management_AP01.createChildSubcriptions(
      this.mapAccountIdBillingAccounts,
      this.mapAccountIdMasterSubscriptions,
      zuoraToken
    );
  }
}