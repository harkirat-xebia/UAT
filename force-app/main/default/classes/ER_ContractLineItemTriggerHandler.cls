/**
 * @author : AAM
 * @date : 02/06/2021
 * @desc : ER_ContractLineItemTriggerHandler
 * @see ER_ContractLineItemTriggerHandler
 */

public with sharing class ER_ContractLineItemTriggerHandler implements ITriggerHandler {
  public static Boolean triggerDisabled = false;

  public Boolean isDisabled() {
    if (UtilsBypass.canTrigger('ER_ContractLineItemTrigger'))
      return triggerDisabled;
    else
      return true;
  }

  public void beforeInsert(List<SObject> newItems) {
  }

  public void afterInsert(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //Fill the creation date in OS in the Contract Line Item level
    APER12_Contract_Management.syncCLIFlags(newItems, oldItems);
  }

  public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
    if (UtilsBypass.canTrigger('TRER09_ER_ContractLineItemBeforeDelete'))
      APER12_Contract_Management.checkDraftParent(oldItems.values());
  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }
}