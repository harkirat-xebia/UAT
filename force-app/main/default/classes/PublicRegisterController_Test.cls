/**
 * Created by noorgoolamnabee on 23/12/2022.
 */

@IsTest
private class PublicRegisterController_Test {
  @IsTest
  static void testAccountFR() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account acc = APER07_UtilityTestMethod.getCompany('testAccountFR');
      acc.ER_Registration_Number__c = '123446';
      insert acc;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new PublicRegister_FR_WS_Mock());
      PublicRegisterController.getData(acc.Id);

      Test.stopTest();
    }
  }

  @IsTest
  static void testAccountFI() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FI');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account acc = APER07_UtilityTestMethod.getCompany('testAccountFI');
      acc.ER_Registration_Number__c = '123446';
      insert acc;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new PublicRegister_FI_WS_Mock());
      PublicRegisterController.getData(acc.Id);

      Test.stopTest();
    }
  }

  @IsTest
  static void testLeadFR() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Lead ld = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
      );
      ld.ER_Registration_Number__c = '123446';
      ld.ER_BUPicklist__c = 'FR';
      insert ld;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new PublicRegister_FR_WS_Mock());
      PublicRegisterController.getData(ld.Id);

      Test.stopTest();
    }
  }

  @IsTest
  static void testLeadFI() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FI');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Lead ld = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
      );
      ld.ER_Registration_Number__c = '123446';
      ld.ER_BUPicklist__c = 'FI';
      insert ld;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new PublicRegister_FI_WS_Mock());
      PublicRegisterController.getData(ld.Id);

      Test.stopTest();
    }
  }

  @IsTest
  static void testLeadGR() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'GR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Lead ld = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
      );
      ld.ER_Registration_Number__c = '123446';
      ld.ER_Legal_Status__c = 'Active';
      ld.ER_BUPicklist__c = 'GR';
      insert ld;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new PublicRegister_WS_Mock());
      PublicRegisterController.getData(ld.Id);

      Test.stopTest();
    }
  }
}