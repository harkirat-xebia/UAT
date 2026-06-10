/**
 * @author Oussama LASFAR
 * @date 05/11/2018 (dd/mm/yyyy)
 * @description This class contains unit tests for validating the behavior of VFCER02_Asset_PinReset
 */

@isTest
public class VFCER02_Asset_PinReset_Test {
  static VFCER02_Asset_PinReset controller;
  public static String pinResetMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": []' +
    '},' +
    '"data": [' +
    '{' +
    '"reset_code": "5829"' +
    '}' +
    ']' +
    '}';

  @testSetup
  static void testSetup() {
    Account newCompany = APER07_UtilityTestMethod.getCompany('VFCER02_Asset_PinReset_Test');
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
    insert newAsset;

    Case newCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
    newCase.AssetId = newAsset.id;
    insert newCase;
  }

  static testMethod void getrequetesOptions() {
    Asset assetinst = [
      SELECT id, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER02_Asset_PinReset(sc);
    Test.StartTest();
    controller.getrequetesOptions();
    Test.StopTest();
  }

  static testMethod void getPinCode() {
    Asset assetinst = [
      SELECT id, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER02_Asset_PinReset(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
    controller.getPinCode();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
    controller.getPinCode();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
    controller.getPinCode();
    Test.StopTest();
  }

  static testMethod void linkCase() {
    Asset assetinst = [
      SELECT id, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER02_Asset_PinReset(sc);

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
      SELECT id, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER02_Asset_PinReset(sc);

    Test.StartTest();
    controller.createNewCase(); //Test Exception
    controller.wsCalledAtLeastOnce = true;
    controller.createNewCase();
    Test.StopTest();
  }

  public class CardWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public CardWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');

      String PinResetOK = pinResetMock;

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
        res.setBody(PinResetOK);
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