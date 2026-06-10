/**
 * @author : AAZ
 * @date : 29/10/2021
 * @desc : ZuoraCreditDebitMemoController
 * @see ZuoraBillingAccountController
 */

public with sharing class ZuoraCreditDebitMemoController {
  @AuraEnabled
  public static String getCreditOrDebitMemoInvoice(String creditMemo, String debitMemo) {
    String pdf;

    if (String.isNotBlank(creditMemo) || String.isNotBlank(debitMemo)) {
      String soql = '';
      List<SObject> sobjList;
      String bu;

      String zuoraToken = ZuoraUtils.getZuoraToken();

      if (String.isNotBlank(creditMemo)) {
        soql = 'SELECT Zuora__BillingAccount__r.Zuora__Account__r.ER_BUPicklist__c FROM Zuora__CreditMemo__c WHERE Zuora__External_Id__c = :creditMemo';
        System.debug('>>>>> ALK - soql : ' + soql);
        sobjList = Database.query(soql);
        bu = ((Zuora__CreditMemo__c) sobjList[0]).Zuora__BillingAccount__r.Zuora__Account__r.ER_BUPicklist__c;
      } else if (String.isNotBlank(debitMemo)) {
        soql = 'SELECT Zuora__BillingAccount__r.Zuora__Account__r.ER_BUPicklist__c FROM Zuora__DebitMemo__c WHERE Zuora__External_Id__c = :debitMemo';
        sobjList = Database.query(soql);
        bu = ((Zuora__DebitMemo__c) sobjList[0]).Zuora__BillingAccount__r.Zuora__Account__r.ER_BUPicklist__c;
      }

      System.debug('>>>>> AAZ - ZuoraBillingAccountController bu: ' + bu);

      pdf = ZuoraUtils.getCreditOrDebitMemoPDF(creditMemo, debitMemo, bu, zuoraToken);
    }

    return pdf;
  }
}