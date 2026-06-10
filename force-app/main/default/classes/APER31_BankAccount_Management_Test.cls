/**
 * Created by davram on 3/17/2021.
 */

@isTest
public without sharing class APER31_BankAccount_Management_Test {
  @testSetup
  public static void testSetup() {
    User ur = TestDataFactory.newUser('APER31', 'APER31', 'Local Admin', 'BELUX', 'PL');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Flows__c = true;
    ur.ER_bypassTrigger__c = true;

    System.runAs(ur) {
      Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER31_BankAccount_Management_Test');
      insert merchantAccount;

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'APER31_BankAccount_Management_Test',
        merchantAccount.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      insert testFinancialCenter;

      ER_Bank_Account__c bankAccount = APER07_UtilityTestMethod.getBankAccount(
        testFinancialCenter.Id,
        'APER31_BankAccount_Management_Test',
        'Open',
        'Paris',
        'Paris street',
        '00000000-00000000-00000000'
      );
      insert bankAccount;
      bankAccount.Name = 'APER31_BankAccount_Management_Test1';
      update bankAccount;
    }
  }

  @IsTest
  static void allowOnlyOneActiveSepaPerFCTest() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER31'];
    u.ER_BypassVR__c = false;
    update u;
    System.runAs(u) {
      List<ER_Bank_Account__c> bankAccounts = [
        SELECT Id, ER_SEPA_active__c, ER_Financial_Center__c, ER_BUPicklist__c, ER_Bank_Account_Status__c
        FROM ER_Bank_Account__c
      ];
      bankAccounts[0].ER_SEPA_active__c = true;
      bankAccounts[0].ER_BUPicklist__c = Constants.BENELUX;

      Test.startTest();
      APER31_BankAccount_Management.allowOnlyOneActiveSepaPerFC(bankAccounts);
      Test.stopTest();
    }
  }

  @IsTest
  static void getSaveFinancialCenterEDGWs() {
    List<ER_Bank_Account__c> bankAccounts = [
      SELECT Id, ER_Last_date_of_Sync__c, ER_Financial_Center__c, ER_BUPicklist__c
      FROM ER_Bank_Account__c
    ];
    Map<Id, ER_Bank_Account__c> baMap = new Map<Id, ER_Bank_Account__c>();
    for (ER_Bank_Account__c sc : bankAccounts) {
      baMap.put(sc.Id, sc);
    }
    Test.startTest();
    APER31_BankAccount_Management.syncBankAccounts(bankAccounts, baMap);
    Test.stopTest();
  }

  @isTest
  static void testSetBankAccountInfos() {
    List<ER_Bank_Account__c> bankAccounts = [SELECT Id, ER_IBAN__c FROM ER_Bank_Account__c];
    Test.startTest();
    for (ER_Bank_Account__c ba : bankAccounts) {
      ba.ER_IBAN__c = 'BE52812615696709';
      ba.ER_SEPA_active__c = false;
    }
    update bankAccounts;
    Test.stopTest();
  }
}