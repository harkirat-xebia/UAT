/*
----------------------------------------------------------------------
-- - Name          : BAER03_DeleteSpamCases_Schedul_Test
-- - Author        : snica
-- - Description   : Test class for BAER03_DeleteSpamCases_Schedul
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Oct-2022    snica               1.0         Initial version
---------------------------------------------------------------------------------------
*/

@isTest
public class BAER03_DeleteSpamCases_Schedul_Test {
  static testMethod void testScheduledJob() {
    Case testCase = new Case();
    testCase.Origin = Label.LABS_SF_Case_Origin_Web;
    testCase.Status = Label.LAB_SF_Case_inProgress;
    testCase.ER_Reason__c = 'ER_Card';
    testCase.ER_CaseReason2__c = 'Balance enquiry';
    testCase.ER_BUPicklist__c = 'ES';
    testCase.ER_Card_Number__c = '2801001840';
    testCase.Description = 'Apex Test Case';
    testCase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('ER_Client_Case_RT')
      .getRecordTypeId();
    insert testCase;

    Case testCase1 = new Case();
    testCase1.Origin = Label.LABS_SF_Case_Origin_Web;
    testCase1.Status = 'Spam';
    testCase1.ER_Reason__c = 'ER_Card1';
    testCase1.ER_CaseReason2__c = 'Balance enquiry1';
    testCase1.ER_BUPicklist__c = 'ES';
    testCase1.ER_Card_Number__c = '2801001840';
    testCase1.Description = 'Apex Test Case1';
    testCase1.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('ER_Client_Case_RT')
      .getRecordTypeId();
    insert testCase1;

    Test.startTest();
    system.schedule('testschedule', '0 24 * * * ?', new BAER03_DeleteSpamCases_Schedul());
    Test.stopTest();
  }
}