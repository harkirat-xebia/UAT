@isTest
public class VFCER06_Asset_UnblockCard_Test {
  static VFCER06_Asset_UnblockCard controller;
  public static String unblockCardMock =
    '{' +
    '"meta": {' +
    '"status": "succeeded",' +
    '"messages": [' +
    '{' +
    '"code": "OK",' +
    '"message": "SUCCESS"' +
    '}' +
    ']' +
    '},' +
    '"data": {' +
    '"status": "active"' +
    '}' +
    '}';

  @testSetup
  static void testSetup() {
    Account newCompany = APER07_UtilityTestMethod.getCompany('UnblockCard_Test_Company');
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
    newAsset.Status = Label.LAB_SF_ASSET_Temp_Blocked;
    newAsset.ER_Block_Card_Reason__c = Label.LAB_SF_ASSET_Temp_Blocked;
    insert newAsset;

    Case newCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
    newCase.AssetId = newAsset.id;
    insert newCase;
  }

  static testMethod void getrequetesOptions() {
    Asset assetinst = [
      SELECT id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER06_Asset_UnblockCard(sc);

    Test.StartTest();
    controller.getrequetesOptions();
    Test.StopTest();
  }

  static testMethod void UnblockCard() {
    Asset assetinst = [
      SELECT id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    assetinst.ER_Block_Card_Reason__c = 'Lost';
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER06_Asset_UnblockCard(sc);

    Test.StartTest();
    Test.setMock(HttpCalloutMock.class, new UblockCardWSMockImpl(401));
    controller.UnblockCard();
    Test.setMock(HttpCalloutMock.class, new UblockCardWSMockImpl(200));
    controller.UnblockCard();
    Test.setMock(HttpCalloutMock.class, new UblockCardWSMockImpl(400));
    controller.UnblockCard();
    Test.StopTest();
  }

  static testMethod void linkCase() {
    Asset assetinst = [
      SELECT id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER06_Asset_UnblockCard(sc);

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
      SELECT id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
    controller = new VFCER06_Asset_UnblockCard(sc);

    Test.StartTest();
    controller.createNewCase(); //Test Exception
    controller.wsCalledAtLeastOnce = true;
    controller.createNewCase();
    Test.StopTest();
  }

  static testMethod void updateAsset() {
    Asset assetinst = [
      SELECT id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, Name
      FROM Asset
      WHERE name = '2801001840'
    ];
    Test.StartTest();
    VFCER06_Asset_UnblockCard.updateAsset(assetinst.Id, '', Label.LAB_SF_ASSET_Status_Active);
    Test.StopTest();
  }

  public class UblockCardWSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public UblockCardWSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');

      String UnblockCardOK = unblockCardMock;

      String wsKO =
        '{' +
        '"meta": {' +
        '"status": "failed",' +
        '"messages": [' +
        '{' +
        '"code": "CARD_NOT_BLOCKED",' +
        '"level": "error",' +
        '"text": "CANNOT RESUME(Card not blocked or already blocked)"' +
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
        '"code": "CARD_NOT_BLOCKED",' +
        '"level": "error",' +
        '"text": "CANNOT RESUME(Card not blocked or already blocked)"' +
        '}' +
        ']' +
        '}' +
        '}';

      System.debug('####TEST req.getEndpoint() : ' + req.getEndpoint());

      if (statusCode == 200) {
        res.setBody(UnblockCardOK);
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