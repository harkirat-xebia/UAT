/**
 * @author : ALK
 * @date : 18/05/2021
 * @desc : BillingAccountTriggerHandler
 * @see BillingAccountTriggerHandler
 */

public with sharing class BillingAccountTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('BillingAccountTrigger2')) {
      return triggerDisabled;
    } else {
      return true;
    }
  }

  public void beforeInsert(List<SObject> newItems) {
    //AAZ - Assign a Financial Center to Billing Account
    BillingAccount_Management_AP01.linkABillingAccountToFC(Trigger.new);

    //AAZ - Fill in the Bill To / Sold To lookups
    BillingAccount_Management_AP01.linkContactToBA(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Create child Subscriptions
    BillingAccount_Management_AP01.createChildSubforBillingAccount(Trigger.new);

    //AAZ - Reset Zuora lock time field on FinancialCenter
    BillingAccount_Management_AP01.resetZuoraLockTimeFC(Trigger.new);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //AAZ - Fill in the Bill To / Sold To lookups
    BillingAccount_Management_AP01.linkContactToBA(Trigger.new);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}