/**
 * @author Nicolae Ciausu
 * @date 06/04/2020 (dd/mm/yyyy)
 * @description This class contains unit tests for validating the behavior of VFCER10_Asset_GetLoads
 */

@isTest
public class VFCER10_Asset_GetLoads_Test {
  static VFCER10_Asset_GetLoads controller;
  public static String loadsMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": []' +
    '},' +
    '"data": [' +
    '{' +
    '"product_code": "MAIN",' +
    '"remaining_amount": 20000,' +
    '"cleared_amount": 20000,' +
    '"reserved_amount": 0,' +
    '"currency": "EUR",' +
    '"status": "Active",' +
    '"loads":[' +
    '{' +
    '"load_ref":"200306000510336131",' +
    '"loaded_amount":"20000",' +
    '"remaining_amount":"20000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336132",' +
    '"loaded_amount":"12000",' +
    '"remaining_amount":"11000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336133",' +
    '"loaded_amount":"52000",' +
    '"remaining_amount":"23000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2021-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2022-03-11T23:10:22.000Z",' +
    '"authorization_expiration_date":"2022-04-05T23:03:04.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2011-03-06T00:05:11.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336134",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336135",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336136",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336137",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336138",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336139",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336140",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336140",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336142",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336143",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336144",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336145",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336146",' +
    '"loaded_amount":"10000",' +
    '"remaining_amount":"10000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-09-12T23:00:00.000Z",' +
    '"authorization_expiration_date":"2021-09-05T23:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '},' +
    '{' +
    '"load_ref":"200306000510336147",' +
    '"loaded_amount":"30000",' +
    '"remaining_amount":"30000",' +
    '"cleared_amount":"0",' +
    '"start_date":"2020-03-06T00:05:10.000Z",' +
    '"clearing_expiration_date":"2021-03-13T00:00:00.000Z",' +
    '"authorization_expiration_date":"2021-03-06T00:00:00.000Z",' +
    '"currency":"EUR",' +
    '"creation_date":"2020-03-06T00:05:10.000Z",' +
    '"status":"active"' +
    '}' +
    ']' +
    '}' +
    ']' +
    '}';

  @testSetup
  static void testSetup() {
    Account newCompany = APER07_UtilityTestMethod.getCompany('VFCER10_Asset_GetLoads_Test');
    insert newCompany;

    ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
    newEmployee.ER_Client__c = newCompany.id;
    insert newEmployee;

    Product2 newProduct = APER07_UtilityTestMethod.getProduct('TSC_P');
    insert newProduct;

    Asset newAsset = APER07_UtilityTestMethod.getAsset('2801001840', 'ER_Asset_Record_Type', Label.LAB_SF_ASSET_Type);
    newAsset.ER_Employee__c = newEmployee.id;
    newAsset.AccountId = newCompany.id;
    newAsset.Product2Id = newProduct.id;
    newAsset.Status = Label.LAB_SF_ASSET_Blocked;
    insert newAsset;
  }

  static testMethod void getTransactionList() {
    Asset assetinst = [SELECT id, ER_Asset_Type__c, ER_Product_Class__c, Name FROM Asset WHERE name = '2801001840'];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    ApexPages.currentPage().getParameters().put('id', assetinst.Id);
    controller = new VFCER10_Asset_GetLoads(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
    controller.getLoadsList();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
    controller.getLoadsList();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
    controller.getLoadsList();
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
      String loadsOK = loadsMock;
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

      if (statusCode == 200) {
        res.setBody(loadsOK);
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