/**
 * @author ELAK
 * @date 19/11/2021
 * @description for unicity rule on ER_MCC_to_Loop__c records
 */
trigger MccToLoopTrigger on ER_MCC_to_Loop__c(before insert) {
  if (!UtilsBypass.canTrigger('MccToLoopTrigger'))
    return;

  List<ER_MCC_to_Loop__c> mccLoop = [
    SELECT id, ER_Loop__c, ER_MCC__c
    FROM ER_MCC_to_Loop__c
    WHERE ER_Loop__c = :Trigger.new[0].ER_Loop__c AND ER_MCC__c = :Trigger.new[0].ER_MCC__c
  ];
  if (mccLoop != null && !mccLoop.isEmpty()) {
    Trigger.new[0].ER_MCC__c.addError(Label.LAB_SF_MCCToLoop_Unicity_Msg);
  }
}