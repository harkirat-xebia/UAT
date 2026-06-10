/*
----------------------------------------------------------------------
-- - Name          : ZuoraBillingAccountController_Test
-- - Author        : AAZ
-- - Description   : Test class for ZuoraBillingAccountController   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- OCT-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ZuoraBillingAccountController_Test {
  @TestSetup
  static void testSetup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testUpdateBA');
    newMerchantAccount.ER_BUPicklist__c = 'PL';
    insert newMerchantAccount;

    Contact c = TestDataFactory.newContact(newMerchantAccount);
    insert c;

    Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
    ba.Name = 'BaName';
    ba.Zuora__AccountNumber__c = 'A00000111';
    ba.Zuora__Account__c = newMerchantAccount.Id;
    ba.SEQUENCE_SET__c = 'AFFILIATE';
    ba.Zuora__Status__c = 'Active';
    ba.CurrencyIsoCode = 'PLN';
    insert ba;
  }

  @IsTest
  static void getListPaymentTerms() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'PL'
    );

    System.runAs(u) {
      Test.startTest();
      Map<String, String> mapItems = ZuoraBillingAccountController.getListPaymentTerms();
      system.debug('####mapItems:' + mapItems);
      System.assertNotEquals(mapItems.size(), 0);
      Test.stopTest();
    }
  }

  @IsTest
  static void updatePaymentTerm() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'PL'
    );

    //System.runAs(u) {
    Test.startTest();
    SendToZuoraMock zuoraMock = new SendToZuoraMock();
    Test.setMock(HttpCalloutMock.class, zuoraMock);

    ZuoraBillingAccountController.updatePaymentTerm('10 days after invoice issuance', 'A00000111');
    Test.stopTest();
    //}
  }
}