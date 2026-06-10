/**
 * @author Nicolae Ciausu
 * @date 30/12/2019 (dd/mm/yyyy)
 * @description This class contains unit tests for validating the behavior of VFCER08_Asset_SpendingProfile
 */

@isTest
public class VFCER08_Asset_SpendingProfile_Test {
  static VFCER08_Asset_SpendingProfile controller;
  public static String spendingProfileMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": []' +
    '},' +
    '"data": [' +
    '{' +
    '"transactionValueLimit": "11 EUR",' +
    '"transactionCountLimit": "1 day",' +
    '"spendingCategoryRules": [{"balance":"Main",' +
    '"decision":"Exclusive",' +
    '"category":"Travel"},' +
    '{"balance":"Main",' +
    '"decision":"Inclusive",' +
    '"category":"Food"}' +
    '],' +
    '"timeRulesLimits": [{"day":"Monday",' +
    '"decision":"Inclusive",' +
    '"slotSpendLimit":"50 EUR",' +
    '"startTime":"07:00",' +
    '"endTime":"23:30"},' +
    '{"day":"Tuesday",' +
    '"decision":"Inclusive",' +
    '"slotSpendLimit":"50 EUR",' +
    '"startTime":"07:10",' +
    '"endTime":"23:30"},' +
    '{"day":"Wednesday",' +
    '"decision":"Inclusive",' +
    '"slotSpendLimit":"50 EUR",' +
    '"startTime":"07:20",' +
    '"endTime":"23:30"},' +
    '{"day":"Thursday",' +
    '"decision":"Inclusive",' +
    '"slotSpendLimit":"50 EUR",' +
    '"startTime":"07:30",' +
    '"endTime":"23:30"},' +
    '{"day":"Friday",' +
    '"decision":"Inclusive",' +
    '"slotSpendLimit":"50 EUR",' +
    '"startTime":"07:40",' +
    '"endTime":"23:30"},' +
    '{"day":"Saturday",' +
    '"decision":"Exclusive",' +
    '"slotSpendLimit":"50 EUR",' +
    '"startTime":"07:50",' +
    '"endTime":"23:30"},' +
    '{"day":"Sunday",' +
    '"decision":"Exclusive",' +
    '"slotSpendLimit":"40 EUR",' +
    '"startTime":"08:00",' +
    '"endTime":"22:30"}]' +
    '}' +
    ']' +
    '}';

  @testSetup
  static void testSetup() {
    Account newCompany = APER07_UtilityTestMethod.getCompany('VFCER08_Asset_SpendingProfile_Test');
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

  static testMethod void getSpendingProfileList() {
    Asset assetinst = [
      SELECT id, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, Name, Account.ER_Portal_username__c
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER08_Asset_SpendingProfile(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new SpendingProfileWSMockImpl(401));
    controller.getSpendingProfileList();
    Test.setMock(HttpCalloutMock.class, new SpendingProfileWSMockImpl(200));
    controller.getSpendingProfileList();
    Test.setMock(HttpCalloutMock.class, new SpendingProfileWSMockImpl(400));
    controller.getSpendingProfileList();
    Test.StopTest();
  }

  public class SpendingProfileWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public SpendingProfileWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');

      String spendingProfileMock = spendingProfileMock;

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
        res.setBody(spendingProfileMock);
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