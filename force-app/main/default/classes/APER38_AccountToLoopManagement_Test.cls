/**
 * Created by ELAK on 28/02/2022.
 */
@isTest
public with sharing class APER38_AccountToLoopManagement_Test {
  @IsTest
  static void checkDuplicateAcctToLoopTest() {
    Test.startTest();
    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER24_Test');
    insert merchantAccount;
    //Loops
    List<ER_Loop__c> loops = new List<ER_Loop__c>();
    List<ER_Account_to_Loop__c> acctToLoops = new List<ER_Account_to_Loop__c>();

    for (Integer i = 0; i < 3; i++) {
      ER_Loop__c looptst = new ER_Loop__c(Name = 'Test loop' + i, ER_External_Reference__c = 'EXT-REF_test' + i);
      loops.add(looptst);
    }
    insert loops;

    for (ER_Loop__c testLoop : loops) {
      ER_Account_to_Loop__c newAccountToLoop = new ER_Account_to_Loop__c(
        ER_Behaviour__c = 'ACCEPT',
        ER_Loop__c = testLoop.Id,
        ER_Account__c = merchantAccount.Id
      );
      acctToLoops.add(newAccountToLoop);
    }
    insert acctToLoops;

    ER_Account_to_Loop__c duplicateATL = new ER_Account_to_Loop__c(
      ER_Behaviour__c = 'DECLINE',
      ER_Loop__c = loops[1].Id,
      ER_Account__c = merchantAccount.Id
    );
    try {
      insert duplicateATL;
    } catch (DmlException e) {
      System.debug('>>>>> ALK - Exception message : ' + e.getMessage());
      System.assertEquals(e.getMessage().contains(Label.LABS_SF_Duplicate_Value), true);
    }

    ER_Account_to_Loop__c newATL = acctToLoops[0];
    newATL.ER_Behaviour__c = 'DECLINE';
    update newATL;
    Test.stopTest();
  }
}