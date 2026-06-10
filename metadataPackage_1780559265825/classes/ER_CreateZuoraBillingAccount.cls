/**
 * @author : AAZ
 * @date : 29/04/2021
 * @desc : ER_CreateZuoraBillingAccount
 * @see ER_CreateZuoraBillingAccount
 */

public with sharing class ER_CreateZuoraBillingAccount implements Queueable, Database.AllowsCallouts {
  public Map<String, List<ER_Financial_Center__c>> mapFinancialCentersByBU { get; set; }
  public List<sObject> listObjToSync { get; set; }

  public ER_CreateZuoraBillingAccount(
    Map<String, List<ER_Financial_Center__c>> fcsToCreate,
    List<sObject> objsToUpdat
  ) {
    this.mapFinancialCentersByBU = fcsToCreate;
    this.listObjToSync = objsToUpdat;
  }

  public void execute(QueueableContext ctxt) {
    String zuoraToken = ZuoraUtils.getZuoraToken();

    if (this.mapFinancialCentersByBU != null && !this.mapFinancialCentersByBU.isEmpty())
      APER30_FinancialCenter_Management.createZuoraCustomerAccount(this.mapFinancialCentersByBU, zuoraToken);
    else if (this.listObjToSync != null && !this.listObjToSync.isEmpty())
      ZuoraUtils.updateZuoraAccounts(this.listObjToSync, zuoraToken);
  }
}