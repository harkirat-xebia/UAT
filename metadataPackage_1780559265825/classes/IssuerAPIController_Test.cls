/*
----------------------------------------------------------------------
-- - Name          : IssuerAPIController_Test
-- - Author        : AAZ
-- - Description   : Test class for IssuerAPIController   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JAN-2023     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class IssuerAPIController_Test {
  @testSetup
  static void testSetup() {
    ER_Product_Class__c pc = new ER_Product_Class__c(
      ER_ProductClassCode__c = 'SRN_ERFR_MB1_EUR_1',
      ER_BUPicklist__c = 'FR',
      ER_ProductClassFamilyId__c = 1,
      ER_ProductFamilyName__c = 'Meal'
    );
    insert pc;

    Product2 benefit = new Product2();
    benefit.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Benefit');
    benefit.Name = 'Ticket Restaurant';
    benefit.ProductCode = 'MEAL';
    benefit.ER_Product_class__c = pc.Id;
    benefit.ER_BenefitId__c = 1;
    benefit.ER_BUPicklist__c = 'FR';
    benefit.IsActive = true;
    benefit.ER_Wallet__c = 'walletOne';
    insert benefit;

    Asset ia = new Asset();
    ia.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Asset.SObjectType, 'Issuer_Account');
    ia.Name = '91600100001418';
    ia.Issuer_Account_code__c = '91600100001418';
    ia.Status = 'Active';
    ia.ER_BUPicklist__c = 'FR';
    insert ia;
  }

  @IsTest
  static void getAccountBalance() {
    Test.startTest();

    Asset ia = [SELECT Id FROM Asset LIMIT 1];

    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);

    String json = IssuerAPIController.getBalance(ia.Id);
    //System.assertNotEquals(null, json);
    Test.stopTest();
  }

  @IsTest
  static void getAccountBalance_WithException() {
    Test.startTest();

    Asset ia = new Asset();
    ia.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Asset.SObjectType, 'Issuer_Account');
    ia.Name = '91600100001418';
    insert ia;

    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);
    try {
      String json = IssuerAPIController.getBalance(ia.Id);
    } catch (Exception ex) {
    }

    Test.stopTest();
  }

  @IsTest
  static void getIssuerAccountTransactions() {
    Test.startTest();

    Asset ia = [SELECT Id FROM Asset LIMIT 1];

    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);

    String json = IssuerAPIController.getTransactions(ia.Id, null, null);
    //System.assertNotEquals(null, json);
    Test.stopTest();
  }
}