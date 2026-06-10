/**
 * Created by ELAK on 10/02/2022.
 */

public with sharing class APER38_AccountToLoopManagement {
  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Check if we already have an existing Account To Loop with the same AccountId and Same Loop
   * @param newItems
   */
  public static void checkDuplicateAcctToLoop(List<ER_Account_to_Loop__c> newItems) {
    Map<Id, List<ER_Account_to_Loop__c>> mapAccountATP = new Map<Id, List<ER_Account_to_Loop__c>>();

    for (ER_Account_to_Loop__c atl : newItems) {
      if (!mapAccountATP.containsKey(atl.ER_Account__c))
        mapAccountATP.put(atl.ER_Account__c, new List<ER_Account_to_Loop__c>());
      mapAccountATP.get(atl.ER_Account__c).add(atl);
    }

    for (ER_Account_to_Loop__c atl : [
      SELECT Id, Name, ER_Account__c, ER_Loop__c, ER_Behaviour__c, ER_Business_Unit__c
      FROM ER_Account_to_Loop__c
      WHERE ER_Account__c IN :mapAccountATP.keySet()
      LIMIT 50000
    ]) {
      for (ER_Account_to_Loop__c newATP : mapAccountATP.get(atl.ER_Account__c)) {
        if (newATP.ER_Account__c == atl.ER_Account__c && newATP.ER_Loop__c == atl.ER_Loop__c && atl.Id != newATP.Id)
          newATP.addError(Label.LABS_SF_Duplicate_Value + ' ' + atl.Id);
      }
    }
  }
}