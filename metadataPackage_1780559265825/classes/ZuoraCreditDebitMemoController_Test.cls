/*
----------------------------------------------------------------------
-- - Name          : ZuoraCreditDebitMemoController_Test
-- - Author        : AAZ
-- - Description   : Test class for ZuoraCreditDebitMemoController   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- OCT-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ZuoraCreditDebitMemoController_Test {
  @TestSetup
  static void testSetup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testUpdateBA');
    newMerchantAccount.ER_BUPicklist__c = 'PL';
    insert newMerchantAccount;

    Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
    ba.Name = 'BaName';
    ba.Zuora__AccountNumber__c = 'A00000111';
    ba.Zuora__Account__c = newMerchantAccount.Id;
    ba.SEQUENCE_SET__c = 'AFFILIATE';
    ba.Zuora__Status__c = 'Active';
    ba.CurrencyIsoCode = 'PLN';
    insert ba;

    Zuora__DebitMemo__c debM = new Zuora__DebitMemo__c();
    debM.Zuora__External_Id__c = 'd123XXXXXXX';
    debM.Zuora__BillingAccount__c = ba.Id;
    debM.Zuora__Balance__c = 20;
    debM.Zuora__DiscountAmount__c = 10;
    debM.Zuora__TaxAmount__c = 5;
    debM.Zuora__TotalAmountWithoutTax__c = 15;
    debM.Zuora__TotalAmount__c = 20;
    debM.Zuora__TotalTaxExemptAmount__c = 15;
    insert debM;

    Zuora__CreditMemo__c credM = new Zuora__CreditMemo__c();
    credM.Zuora__External_Id__c = 'c123XXXXXXX';
    credM.Zuora__BillingAccount__c = ba.Id;
    credM.Zuora__AppliedAmount__c = 15;
    credM.Zuora__Balance__c = 15;
    credM.Zuora__DiscountAmount__c = 10;
    credM.Zuora__MemoDate__c = Date.today();
    credM.Zuora__RefundAmount__c = 5;
    credM.Zuora__TaxAmount__c = 10;
    credM.Zuora__TotalAmountWithoutTax__c = 5;
    credM.Zuora__TotalAmount__c = 15;
    credM.Zuora__TotalTaxExemptAmount__c = 5;
    insert credM;
  }

  @IsTest
  static void getCreditMemoInvoice() {
    Test.startTest();
    SendToZuoraMock zuoraMock = new SendToZuoraMock();
    Test.setMock(HttpCalloutMock.class, zuoraMock);

    Zuora__CreditMemo__c cm = [SELECT Zuora__External_Id__c FROM Zuora__CreditMemo__c LIMIT 1];

    String file = ZuoraCreditDebitMemoController.getCreditOrDebitMemoInvoice(cm.Zuora__External_Id__c, '');
    System.debug('>>>>> AAZ getFile - file : ' + file);

    System.assertNotEquals(null, file);
    Test.stopTest();
  }

  @IsTest
  static void getDebitMemoInvoice() {
    Test.startTest();
    SendToZuoraMock zuoraMock = new SendToZuoraMock();
    Test.setMock(HttpCalloutMock.class, zuoraMock);

    Zuora__DebitMemo__c dm = [SELECT Zuora__External_Id__c FROM Zuora__DebitMemo__c LIMIT 1];

    String file = ZuoraCreditDebitMemoController.getCreditOrDebitMemoInvoice('', dm.Zuora__External_Id__c);

    System.assertNotEquals(null, file);
    Test.stopTest();
  }
}