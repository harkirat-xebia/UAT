/**
 * @author : Dragos Avram
 * @date : 3/17/2021
 * @desc : BankAccountTriggerHandler
 * @see BankAccountTriggerHandler
 */

public with sharing class BankAccountTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('BankAccountTriggerHandler'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER31_BankAccount_Management.updateLastModifiedDateFunctionalUser(Trigger.new);
    //snica
    APER31_BankAccount_Management.allowOnlyOneActiveSepaPerFC(Trigger.new);
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //ALK - Sync Bank Accounts with EDG v3
    APER31_BankAccount_Management.syncBankAccounts(Trigger.new, null);

    //AAM - Set Bic and bank name
    APER31_BankAccount_Management.setBankAccountInfos(Trigger.new, (Map<Id, ER_Bank_Account__c>) Trigger.oldMap);
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Fill the creation date in OS in the Store level
    APER31_BankAccount_Management.syncBankAccountFlags(newItems, oldItems);

    //AAZ - Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
    APER31_BankAccount_Management.updateLastModifiedDateFunctionalUser(Trigger.new);

    //snica
    APER31_BankAccount_Management.allowOnlyOneActiveSepaPerFC(Trigger.new);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //APER31_BankAccount_Management.saveFinancialCenterEDGWs(trigger.new);

    //ALK - Sync Bank Accounts with EDG v3
    APER31_BankAccount_Management.syncBankAccounts(Trigger.new, (Map<Id, ER_Bank_Account__c>) oldItems);

    //Noor - Sync Financial // KHAD remove V2 call
    //if(UtilsBypass.canTrigger('synchronizeFinancials')) APER31_BankAccount_Management.synchronizeFinancials(Trigger.new);

    //AAM - Set Bic and bank name
    APER31_BankAccount_Management.setBankAccountInfos(Trigger.new, (Map<Id, ER_Bank_Account__c>) Trigger.oldMap);

    //AAZ - Update the related Billing Accounts after an IBAN has changed
    APER31_BankAccount_Management.updateZuoraBillingAccounts(Trigger.new, (Map<Id, ER_Bank_Account__c>) Trigger.oldMap);
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}