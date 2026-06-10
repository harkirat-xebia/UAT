@isTest
public with sharing class BAER02_SetInactiveAcceptor_Test {
  private static final String CRON_EXP = '0 0 0 ? * * *';
  private static final String ACTIVE_STATUS = Label.LAB_SF_Acceptor_Active;
  private static final String TEST_NAME = 'BAER02_SetInactiveAcceptor_Test';

  @TestSetup
  static void prepareData() {
    Account merchantAccount = APER07_UtilityTestMethod.getCompany(TEST_NAME);
    merchantAccount.ER_Registration_Number__c = '1234567890';
    insert merchantAccount;

    ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
      TEST_NAME,
      merchantAccount.id,
      Label.LABS_SF_FinancialCenter_Merchant,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testFinancialCenter.ER_Invoicing_Site__c = true;
    insert testFinancialCenter;

    ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
      TEST_NAME,
      merchantAccount.id,
      testFinancialCenter.id,
      Date.today(),
      'Test',
      'Test',
      'Test',
      'Test'
    );
    insert testStore;

    ER_Acceptor__c testAcceptor1 = new ER_Acceptor__c(
      Name = 'TEST Hotel1',
      ER_Store__c = testStore.Id,
      ER_MID_Authorization__c = '12341993',
      ER_End_Date__c = Date.today(),
      ER_Status__c = 'Active'
    );
    ER_Acceptor__c testAcceptor2 = new ER_Acceptor__c(
      Name = 'TEST Hotel2',
      ER_Store__c = testStore.Id,
      ER_MID_Authorization__c = '12341993',
      ER_End_Date__c = Date.today() - 10
    );
    insert new List<ER_Acceptor__c>{ testAcceptor1, testAcceptor2 };
  }

  @IsTest
  static void testScheduler() {
    Test.startTest();
    Id jobId = System.schedule('Test Scheduler', CRON_EXP, new BAER02_SetInactiveAcceptor());
    Test.stopTest();

    List<CronTrigger> ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

    system.assert(ct.size() == 1);
  }

  @IsTest
  static void testBatch() {
    Test.startTest();
    List<ER_Acceptor__c> oldList = [SELECT Id FROM ER_Acceptor__c WHERE ER_Status__c = :ACTIVE_STATUS];
    Database.executeBatch(new BAER02_SetInactiveAcceptor());
    Test.stopTest();

    List<ER_Acceptor__c> newList = [SELECT Id FROM ER_Acceptor__c WHERE ER_Status__c = :ACTIVE_STATUS];
    system.assert(oldList.size() > newList.size());
  }
}