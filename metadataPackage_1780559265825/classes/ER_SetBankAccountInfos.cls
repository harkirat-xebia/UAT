/**
 * @author : AAM
 * @date : 07/04/2022
 * @desc : Set BIC and Bank name when Iban is filled
 */

public with sharing class ER_SetBankAccountInfos implements Queueable, Database.AllowsCallouts {
  public List<ER_Bank_Account__c> baList { get; set; }

  public ER_SetBankAccountInfos(List<ER_Bank_Account__c> baList) {
    this.baList = baList;
  }

  public void execute(QueueableContext ctxt) {
    System.debug('>>> ER_SetBankAccountInfos - Start. baList size: ' + baList.size());
    List<ER_Bank_Account__c> baUpdList = new List<ER_Bank_Account__c>();

    for (ER_Bank_Account__c ba : baList) {
      if (!String.isBlank(ba.ER_IBAN__c)) {
        String resultJSON = APER30_AutoEnrollment_Management.getBIC(ba.ER_IBAN__c);
        Map<String, Object> baInfos = (Map<String, Object>) JSON.deserializeUntyped(resultJSON);
        if (String.valueOf(baInfos.get('valid')) == 'true') {
          System.debug('>>> ER_SetBankAccountInfos - bankData: ' + String.valueOf(baInfos.get('bankData')));
          Map<String, Object> bankData = (Map<String, Object>) baInfos.get('bankData');
          if (ba.ER_BIC__c != String.valueOf(bankData.get('bic'))) {
            ba.ER_BIC__c = String.valueOf(bankData.get('bic'));
            ba.ER_Bank_Name__c = String.valueOf(bankData.get('name'));
            System.debug(
              '>>> ER_SetBankAccountInfos - IBAN: ' +
              ba.ER_IBAN__c +
              ' ---> BIC: ' +
              ba.ER_BIC__c +
              ' Bank Name: ' +
              ba.ER_Bank_Name__c
            );
            baUpdList.add(ba);
          }
        }
      }
    }
    System.debug('>>> ER_SetBankAccountInfos - Nb updates ' + baUpdList.size());
    if (!baUpdList.isEmpty())
      update baUpdList;
  }
}