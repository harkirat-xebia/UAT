/**
 * @author ELAK
 * @date 19/11/2021
 * @description a test class for trigger MccToLoopTrigger
 */
@isTest
public class MccToLoopTrigger_Test {
  static testMethod void testInsert() {
    ER_MCC__C mcc1 = new ER_MCC__C(name = 'MCC 1', ER_MCC_Authorization__c = '1213');
    insert mcc1;
    ER_Loop__C loop1 = new ER_Loop__C(name = 'Loop 1');
    insert loop1;
    ER_MCC_to_Loop__c mccToLoop1 = new ER_MCC_to_Loop__c(ER_Loop__c = loop1.Id, ER_MCC__c = mcc1.Id);
    insert mccToLoop1;
    ER_MCC_to_Loop__c mccToLoop2 = new ER_MCC_to_Loop__c(ER_Loop__c = loop1.Id, ER_MCC__c = mcc1.Id);
    Test.startTest();
    try {
      insert mccToLoop2;
    } catch (Exception ex) {
      Boolean expectedExceptionThrown = ex.getMessage().contains(Label.LAB_SF_MCCToLoop_Unicity_Msg) ? true : false;
      System.assertEquals(expectedExceptionThrown, true);
    }
    Test.stopTest();
  }
}