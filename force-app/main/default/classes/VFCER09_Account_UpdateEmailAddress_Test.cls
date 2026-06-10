@isTest
public class VFCER09_Account_UpdateEmailAddress_Test {
  static VFCER09_Account_UpdateEmailAddress controller;
  public static String updateEmailMock = '{' + '"meta": {' + '"status": "succeeded",' + '"messages": []' + '}' + '}';

  @testSetup
  static void testSetup() {
    Account newCompany = APER07_UtilityTestMethod.getCompany('VFCER09_Account_UpdateEmailAddress_Test');
    newCompany.ER_Card_Operational_System_ID__c = 'ES_Individual_11';
    insert newCompany;

    Account newIndividual = APER07_UtilityTestMethod.getIndividual(
      'Mr',
      'test',
      'VFCER09_Account_UpdateEmailAddress_Test'
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

  static testMethod void getSecretQuestion() {
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
    controller = new VFCER09_Account_UpdateEmailAddress(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(401));
    controller.getSecretQuestion();
    Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(200));
    controller.getSecretQuestion();
    Test.setMock(HttpCalloutMock.class, new VFCER07_Asset_MobileActivation_Test.SecretQuestionWSMockImpl(400));
    controller.getSecretQuestion();
    Test.StopTest();
  }

  static testMethod void sendNewEmailAddress() {
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
    controller = new VFCER09_Account_UpdateEmailAddress(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new UpdateEmailAddressWSMockImpl(401));
    controller.sendNewEmailAddress();
    Test.setMock(HttpCalloutMock.class, new UpdateEmailAddressWSMockImpl(200));
    controller.sendNewEmailAddress();
    Test.setMock(HttpCalloutMock.class, new UpdateEmailAddressWSMockImpl(400));
    controller.sendNewEmailAddress();
    Test.StopTest();
  }

  static testMethod void createNewCase() {
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
    controller = new VFCER09_Account_UpdateEmailAddress(sc);

    Test.StartTest();
    controller.createNewCase(); //Test Exception
    controller.wsCalledAtLeastOnce = true;
    controller.createNewCase();
    Test.StopTest();
  }

  public class UpdateEmailAddressWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public UpdateEmailAddressWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');

      String updateEmailMock = updateEmailMock;

      String wsKO =
        '{' +
        '"meta": {' +
        '"status": "failed",' +
        '"messages": [' +
        '{' +
        '"code": "BAD_REQUEST",' +
        '"level": "error",' +
        '"text": "Unable to process your request, please check its validity."' +
        '},' +
        '{' +
        '"code": "AUTHENTICATION_FAILED",' +
        '"level": "error",' +
        '"text": "Incorrect or expired token."' +
        '}' +
        ']' +
        '}' +
        '}';

      String wsMalformedJsonKO =
        '{' +
        '"meta": {' +
        '"status": "failed",' +
        '"messages": [' +
        '{' +
        '"code": "BAD_REQUEST",' +
        '"level": "error",' +
        '"text": "Unable to process your request, please check its validity."' +
        '},' +
        '{' +
        '"code": "AUTHENTICATION_FAILED",' +
        '"level": "error",' +
        '"text": "Incorrect or expired token."' +
        '}' +
        ']' +
        '}';

      System.debug('####TEST req.getEndpoint() : ' + req.getEndpoint());

      if (statusCode == 200) {
        res.setBody(updateEmailMock);
      } else if (statusCode == 400) {
        res.setBody(wsMalformedJsonKO);
      } else {
        res.setBody(wsKO);
      }

      res.setStatusCode(statusCode);
      return res;
    }
  }
}