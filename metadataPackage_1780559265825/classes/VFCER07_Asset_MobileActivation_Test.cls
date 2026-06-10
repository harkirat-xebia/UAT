/**
 * @author Nicolae Ciausu
 * @date 30/12/2019 (dd/mm/yyyy)
 * @description This class contains unit tests for validating the behavior of VFCER07_Asset_MobileActivation
 */

@isTest
public class VFCER07_Asset_MobileActivation_Test {
  static VFCER07_Asset_MobileActivation controller;
  public static String secretQAMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": []' +
    '},' +
    '"data": ' +
    '{' +
    '"secret_question": "cat name",' +
    '"secret_answer": "Tommy"' +
    '}' +
    '}';

  public static String panNumberMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": []' +
    '},' +
    '"data":' +
    '{' +
    '"issue_date": "2012-08-11T00:01:00Z",' +
    '"pan": "629914*********2052",' +
    '"activation_date": "2015-03-17T12:00:00Z",' +
    '"status": "active",' +
    '"expiration_date": "2019-03-16T12:00:00Z",' +
    '"cardholder_name": "Sophie Moutier",' +
    '"acceptance_profile": "AP_TR",' +
    '"employer_name": "Fake employer",' +
    '"order_ref": "9120"' +
    '}' +
    '}';

  @testSetup
  static void testSetup() {
    Account newCompany = APER07_UtilityTestMethod.getCompany('VFCER07_Asset_MobileActivation_Test');
    newCompany.ER_Card_Operational_System_ID__c = 'ES_Individual_11';
    insert newCompany;

    ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
    newEmployee.ER_Client__c = newCompany.id;
    insert newEmployee;

    Product2 newProduct = APER07_UtilityTestMethod.getProduct('TSC_P');
    insert newProduct;

    Asset newAsset = APER07_UtilityTestMethod.getAsset('2801001840', 'ER_Asset_Record_Type', 'ER_Mono-Wallet');
    newAsset.ER_Employee__c = newEmployee.id;
    newAsset.AccountId = newCompany.id;
    newAsset.Product2Id = newProduct.id;
    newAsset.ER_Card_Operational_System_ID__c = 'ES_Individual_25';
    insert newAsset;

    Case newCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
    newCase.AssetId = newAsset.id;
    insert newCase;
  }

  static testMethod void getrequetesOptions() {
    Asset assetinst = [
      SELECT
        id,
        ER_Block_Card_Reason__c,
        ER_Employee__c,
        ER_Product_Class__c,
        ER_Asset_Type__c,
        ER_Edenred_Solution__c,
        Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER07_Asset_MobileActivation(sc);

    Test.StartTest();
    controller.getrequetesOptions();
    Test.StopTest();
  }

  static testMethod void getSecretQuestion() {
    Asset assetinst = [
      SELECT
        id,
        ER_Employee__c,
        ER_Product_Class__c,
        ER_Asset_Type__c,
        ER_Edenred_Solution__c,
        Name,
        Account.ER_Portal_username__c,
        ER_Card_Operational_System_ID__c
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER07_Asset_MobileActivation(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new SecretQuestionWSMockImpl(401));
    controller.getSecretQuestion();
    Test.setMock(HttpCalloutMock.class, new SecretQuestionWSMockImpl(200));
    controller.getSecretQuestion();
    Test.setMock(HttpCalloutMock.class, new SecretQuestionWSMockImpl(400));
    controller.getSecretQuestion();
    Test.StopTest();
  }

  static testMethod void getPanNumber() {
    Asset assetinst = [
      SELECT id, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER07_Asset_MobileActivation(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new PanNumberWSMockImpl(401));
    controller.getPanNumber();
    Test.setMock(HttpCalloutMock.class, new PanNumberWSMockImpl(200));
    controller.getPanNumber();
    Test.setMock(HttpCalloutMock.class, new PanNumberWSMockImpl(400));
    controller.getPanNumber();
    Test.StopTest();
  }

  static testMethod void linkCase() {
    Asset assetinst = [
      SELECT
        id,
        ER_Block_Card_Reason__c,
        ER_Employee__c,
        ER_Product_Class__c,
        ER_Asset_Type__c,
        ER_Edenred_Solution__c,
        Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER07_Asset_MobileActivation(sc);

    Case caseinst = [SELECT id FROM Case LIMIT 1];

    Test.StartTest();
    controller.linkCase(); //Test Exception
    controller.selectedCase = caseinst.id;
    controller.wsCalledAtLeastOnce = true;
    controller.wsSuccess = true;
    controller.linkCase();
    Test.StopTest();
  }

  static testMethod void createNewCase() {
    Asset assetinst = [
      SELECT
        id,
        ER_Block_Card_Reason__c,
        ER_Employee__c,
        ER_Product_Class__c,
        ER_Asset_Type__c,
        ER_Edenred_Solution__c,
        Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER07_Asset_MobileActivation(sc);

    Test.StartTest();
    controller.createNewCase(); //Test Exception
    controller.wsCalledAtLeastOnce = true;
    controller.createNewCase();
    Test.StopTest();
  }

  public class SecretQuestionWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public SecretQuestionWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');

      String secretQAOK = secretQAMock;

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
        res.setBody(secretQAOK);
      } else if (statusCode == 400) {
        res.setBody(wsMalformedJsonKO);
      } else {
        res.setBody(wsKO);
      }

      res.setStatusCode(statusCode);
      return res;
    }
  }

  public class PanNumberWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public PanNumberWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');

      String secretPanOK = panNumberMock;

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
        res.setBody(secretPanOK);
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