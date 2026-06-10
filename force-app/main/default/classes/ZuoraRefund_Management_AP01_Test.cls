/*
----------------------------------------------------------------------
-- - Name          : ZuoraRefund_Management_AP01_Test
-- - Author        : AAZ
-- - Description   : Test class for ZuoraRefund_Management_AP01   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- NOV-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ZuoraRefund_Management_AP01_Test {
  @TestSetup
  static void testSetup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testDeleteRefund');
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

    Zuora__Refund__c refund = new Zuora__Refund__c();
    refund.Name = 'AFF-R-2021-0000001';
    refund.Zuora__BillingAccount__c = ba.Id;
    refund.Zuora__Amount__c = 7;
    insert refund;
  }

  @IsTest
  static void testUpdateRefund() {
    Test.startTest();

    Zuora__Refund__c refund = [SELECT ER_Post_Process__c FROM Zuora__Refund__c LIMIT 1];
    refund.ER_Post_Process__c = 'Delete';
    update refund;

    List<Zuora__Refund__c> refunds = [SELECT Id FROM Zuora__Refund__c LIMIT 1];
    System.assertEquals(0, refunds.size());

    Test.stopTest();
  }
}