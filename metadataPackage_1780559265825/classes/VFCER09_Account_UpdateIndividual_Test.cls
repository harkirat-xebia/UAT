@isTest
public class VFCER09_Account_UpdateIndividual_Test {
  static VFCER09_Account_UpdateIndividual controller;

  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('VFCER09', 'VFCER09', 'Local Admin', 'BELUX', 'BENELUX');
    ur.ER_BypassVR__c = true;
    insert ur;
    system.debug('user => ' + ur);
    System.runAs(ur) {
      Account newCompany = APER07_UtilityTestMethod.getCompany('VFCER09_Account_UpdateIndividual_Test');
      newCompany.ER_Card_Operational_System_ID__c = 'ES_Individual_11';
      insert newCompany;

      Account newIndividual = APER07_UtilityTestMethod.getIndividual(
        'Mr',
        'test',
        'VFCER09_Account_UpdateIndividual_Test'
      );
      newIndividual.ER_Card_Operational_System_ID__c = 'ES_Individual_35';
      insert newIndividual;

      ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
      newEmployee.ER_Client__c = newCompany.id;
      newEmployee.ER_Individual__c = newIndividual.id;
      insert newEmployee;

      Product2 newProduct = APER07_UtilityTestMethod.getProduct('TSC_P');
      insert newProduct;

      Asset newAsset = APER07_UtilityTestMethod.getAsset('2801001840', 'ER_Asset_Record_Type', 'ER_Mono-Wallet');
      newAsset.ER_Employee__c = newEmployee.id;
      newAsset.AccountId = newCompany.id;
      newAsset.ER_Individual__c = newIndividual.id;
      newAsset.Product2Id = newProduct.id;
      insert newAsset;

      Case newCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      newCase.AssetId = newAsset.id;
      insert newCase;
    }
  }

  static testMethod void createNewCase() {
    User ur = [SELECT Id FROM User WHERE LastName = 'VFCER09'];

    System.runAs(ur) {
      Account individualInst = [
        SELECT
          id,
          Name,
          PersonEmail,
          PersonBirthdate,
          ER_Portal_username__c,
          ER_National_ID_Number__c,
          PersonMailingStreet,
          PersonMailingCity,
          PersonMailingCountry,
          PersonMailingPostalCode,
          ER_Card_Operational_System_ID__c
        FROM Account
        WHERE ispersonAccount = TRUE AND RecordType.developerName = 'ER_Individual_Account_RT'
        LIMIT 1
      ];
      ApexPages.StandardController sc = new ApexPages.StandardController(individualInst);
      controller = new VFCER09_Account_UpdateIndividual(sc);
      controller.wsCalledAtLeastOnce = true;
      Test.startTest();
      controller.createNewCase();
      Test.stopTest();
    }

  }

  static testMethod void getSecretQuestion() {
    User ur = [SELECT Id FROM User WHERE LastName = 'VFCER09'];

    System.runAs(ur) {
      Account individualInst = [
        SELECT
          id,
          Name,
          PersonEmail,
          PersonBirthdate,
          ER_Portal_username__c,
          ER_National_ID_Number__c,
          PersonMailingStreet,
          PersonMailingCity,
          PersonMailingCountry,
          PersonMailingPostalCode,
          ER_Card_Operational_System_ID__c
        FROM Account
        WHERE ispersonAccount = TRUE AND RecordType.developerName = 'ER_Individual_Account_RT'
        LIMIT 1
      ];
      ApexPages.StandardController sc = new ApexPages.StandardController(individualInst);
      controller = new VFCER09_Account_UpdateIndividual(sc);
      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(401));
      controller.getSecretQuestion();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(200));
      controller.getSecretQuestion();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(400));
      controller.getSecretQuestion();
      Test.stopTest();
    }
  }

  static testMethod void sendIndividualInfo() {
    User ur = [SELECT Id FROM User WHERE LastName = 'VFCER09'];

    System.runAs(ur) {
      Account individualInst = [
        SELECT
          id,
          Name,
          PersonEmail,
          PersonBirthdate,
          ER_Portal_username__c,
          ER_National_ID_Number__c,
          PersonMailingStreet,
          PersonMailingCity,
          PersonMailingCountry,
          PersonMailingPostalCode,
          ER_Card_Operational_System_ID__c
        FROM Account
        WHERE ispersonAccount = TRUE AND RecordType.developerName = 'ER_Individual_Account_RT'
        LIMIT 1
      ];
      ApexPages.StandardController sc = new ApexPages.StandardController(individualInst);
      controller = new VFCER09_Account_UpdateIndividual(sc);
      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(401));
      controller.sendIndividualInfo();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(200));
      controller.sendIndividualInfo();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(400));
      controller.sendIndividualInfo();
      Test.stopTest();
    }
  }

  static testMethod void getIndividualInfo() {
    User ur = [SELECT Id FROM User WHERE LastName = 'VFCER09'];

    System.runAs(ur) {
      Account individualInst = [
        SELECT
          id,
          Name,
          PersonEmail,
          PersonBirthdate,
          ER_Portal_username__c,
          ER_National_ID_Number__c,
          PersonMailingStreet,
          PersonMailingCity,
          PersonMailingCountry,
          PersonMailingPostalCode,
          ER_Card_Operational_System_ID__c
        FROM Account
        WHERE ispersonAccount = TRUE AND RecordType.developerName = 'ER_Individual_Account_RT'
        LIMIT 1
      ];
      ApexPages.StandardController sc = new ApexPages.StandardController(individualInst);
      controller = new VFCER09_Account_UpdateIndividual(sc);
      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(401));
      controller.getIndividualInfo();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(200));
      controller.getIndividualInfo();
      Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(400));
      controller.getIndividualInfo();
      Test.stopTest();
    }
  }
}