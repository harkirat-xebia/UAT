/**
 * @author : AAZ
 * @date : 21/10/2021
 * @desc : ZuoraBillingAccountController
 * @see ZuoraBillingAccountController
 */

public with sharing class ZuoraBillingAccountController {
  @AuraEnabled(Cacheable=true)
  public static Map<String, String> getListPaymentTerms() {
    return Utils.getPicklistValues('zqu__Quote__c', 'zqu__PaymentTerm__c');
  }

  @AuraEnabled
  public static String updatePaymentTerm(String newPaymentTerm, String billAccNumber) {
    System.debug('>>>>> ALK - newPaymentTerm : ' + newPaymentTerm);
    System.debug('>>>>> ALK - billAccNumber : ' + billAccNumber);

    List<Zuora__CustomerAccount__c> currentBA = [
      SELECT Zuora__Account__r.ER_BUPicklist__c
      FROM Zuora__CustomerAccount__c
      WHERE Zuora__AccountNumber__c = :billAccNumber
    ];

    System.debug('>>>>> AAZ - ZuoraBillingAccountController : ' + currentBA);
    String zuoraToken = ZuoraUtils.getZuoraToken();

    return ZuoraUtils.updateZuoraAccountPaymentTerm(
      newPaymentTerm,
      billAccNumber,
      currentBA[0].Zuora__Account__r.ER_BUPicklist__c,
      zuoraToken
    );
  }
}