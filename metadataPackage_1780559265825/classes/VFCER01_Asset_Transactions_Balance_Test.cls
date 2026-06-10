/**
 * @author Oussama LASFAR
 * @date 28/09/2018 (dd/mm/yyyy)
 * @description This class contains unit tests for validating the behavior of VFCER01_Asset_Transactions_Balance
 */

@isTest
public class VFCER01_Asset_Transactions_Balance_Test {
  static VFCER01_Asset_Transactions_Balance controller;
  public static String balanceMock =
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
  public static String cardDetailMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": []' +
    '},' +
    '"data": {' +
    '"issue_date": "2018-08-26T00:03:51.61",' +
    '"pan": "629914*********2052",' +
    '"expiration_date": "2021-08-31T00:00:00",' +
    '"acceptance_profile": "AP_TR",' +
    '"employer_ref": "1362",' +
    '"employer_name": "App Container TR Card",' +
    '"cardholder_name": "THIRIET John",' +
    '"status": "active",' +
    '"order_ref": "9242"' +
    '}' +
    '}';
  public static String operationsMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": []' +
    '},' +
    '"data": [' +
    '{' +
    '"csn": "2801001840",' +
    '"operation_ref": "18052002465131845",' +
    '"type": "topup",' +
    '"amount": "140000",' +
    //'"date": "2019-10-30T14:52:22.000Z",' +
    '"opDate": "2019-10-30T14:52:22.000Z",' +
    '"currency": "EUR",' +
    '"outlet_name": "Earth",' +
    '"outlet_ref": null,' +
    '"status": "success",' +
    '"status_details": "TRS0001",' +
    '"cleared_status": "cleared",' +
    '"wallet_service_provider": "Apple Pay",' +
    '"device_type": "Phone",' +
    '"device_name": "IPhone XS",' +
    '"MID_auth": "1422IU",' +
    '"MID_cleared": "1422IU",' +
    '"product_code": "TSC_D",' +
    '"product_balance_code": "ETR1",' +
    '"auth_sub_mid": "1134",' +
    '"clear_sub_mid": "1121"' +
    '},' +
    '{' +
    '"csn": "2801001840",' +
    '"operation_ref": "18052002465131845",' +
    '"type": "redemption",' +
    '"amount": "-1200",' +
    //'"date": "2019-11-14T15:01:24.000Z",' +
    '"opDate": "2019-11-14T15:01:24.000Z",' +
    '"currency": "EUR",' +
    '"outlet_name": "Earth",' +
    '"outlet_ref": null,' +
    '"status": "success",' +
    '"status_details": "TRS0001",' +
    '"product_code": "TSC_P",' +
    '"product_balance_code": "ETR2",' +
    '"auth_sub_mid": "1234",' +
    '"clear_sub_mid": "1221"' +
    '},' +
    '{' +
    '"csn": "2801001840",' +
    '"operation_ref": "18052002465131845",' +
    '"type": "redemption",' +
    '"amount": -1900,' +
    //'"date": "2019-11-14T15:01:24.000Z",' +
    '"opDate": "2019-12-30T15:01:24.000Z",' +
    '"currency": "EUR",' +
    '"outlet_name": "Earth",' +
    '"outlet_ref": null,' +
    '"status": "success",' +
    '"status_details": "TRS0001",' +
    '"product_code": "TSC_P",' +
    '"product_balance_code": "ETR3",' +
    '"auth_sub_mid": "1334",' +
    '"clear_sub_mid": "1321"' +
    '},' +
    '{' +
    '"csn": "2801001840",' +
    '"operation_ref": "18052002465131845",' +
    '"type": "redemption",' +
    '"amount": -1000,' +
    //'"date": "2019-11-14T15:01:24.000Z",' +
    '"opDate": "2019-12-30T20:01:24.000Z",' +
    '"currency": "EUR",' +
    '"outlet_name": "Earth",' +
    '"outlet_ref": null,' +
    '"status": "failed",' +
    '"status_details": "TRS0122",' +
    '"product_code": "TSC_P",' +
    '"product_balance_code": "ETR4",' +
    '"auth_sub_mid": "1434",' +
    '"clear_sub_mid": "1421"' +
    '}' +
    ']' +
    '}';
  @testSetup
  static void testSetup() {
    Account newCompany = APER07_UtilityTestMethod.getCompany('VFCER01_Asset_Transactions_Balance_Test');
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
    controller = new VFCER01_Asset_Transactions_Balance(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
    controller.getTransactionList();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
    controller.getTransactionList();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
    controller.getTransactionList();
    controller.daterFilters = '2022-01-01-2022-01-02';
    controller.getTransactionList();
    Test.StopTest();
  }
  static testMethod void getBalance() {
    Asset assetinst = [
      SELECT id, ER_Asset_Type__c, Name, Status, ER_Product_Class__c
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    ApexPages.currentPage().getParameters().put('id', assetinst.Id);
    controller = new VFCER01_Asset_Transactions_Balance(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
    controller.getBalance();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
    controller.getBalance();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
    controller.getBalance();
    Test.StopTest();
  }
  static testMethod void getCard() {
    Asset assetinst = [
      SELECT id, ER_Asset_Type__c, Name, Status, ER_Product_Class__c
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    ApexPages.currentPage().getParameters().put('id', assetinst.Id);
    controller = new VFCER01_Asset_Transactions_Balance(sc);
    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
    controller.getCard();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
    controller.getCard();
    Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
    controller.getCard();
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
      String balanceOK = balanceMock;
      String operationOK = operationsMock;
      String cardOK = cardDetailMock;
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
        if (req.getEndpoint().contains('balance')) {
          res.setBody(balanceOK);
        } else if (req.getEndpoint().contains('operation')) {
          res.setBody(operationOK);
        } else {
          res.setBody(cardOK);
        }
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