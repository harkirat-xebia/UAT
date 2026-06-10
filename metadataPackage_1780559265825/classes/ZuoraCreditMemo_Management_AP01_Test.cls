/*
----------------------------------------------------------------------
-- - Name          : ZuoraCreditMemo_Management_AP01_Test
-- - Author        : AAZ
-- - Description   : Test class for ZuoraCreditMemo_Management_AP01   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- NOV-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ZuoraCreditMemo_Management_AP01_Test {
  @TestSetup
  static void testSetup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testDeleteCM');
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
  static void testUpdateCreditMemo() {
    Test.startTest();

    Zuora__CreditMemo__c cm = [SELECT ER_Post_Process__c FROM Zuora__CreditMemo__c LIMIT 1];
    cm.ER_Post_Process__c = 'Delete';
    update cm;

    List<Zuora__CreditMemo__c> cms = [SELECT Id FROM Zuora__CreditMemo__c LIMIT 1];
    System.assertEquals(0, cms.size());

    Test.stopTest();
  }
}