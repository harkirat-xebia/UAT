/*
----------------------------------------------------------------------
-- - Name          : ZuoraSubscription_CancellationBatch_Test
-- - Author        : AAZ
-- - Description   : Test class for ZuoraSubscription_CancellationBatch      
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JULY-2021     AAZ                  1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ZuoraSubscription_CancellationBatch_Test {
  @IsTest
  static void testBatch() {
    Account acc = APER07_UtilityTestMethod.getCompany('ZuoraSubscription_CancellationBatch_Test');
    acc.ER_BUPicklist__c = 'PL';
    insert acc;

    Contact cont = TestDataFactory.newContact(acc);
    insert cont;

    Zuora__CustomerAccount__c newBA = new Zuora__CustomerAccount__c();
    newBA.Name = 'A00000001';
    newBA.Zuora__Account__c = acc.Id;
    newBA.Zuora__Status__c = 'Active';
    newBA.Zuora__Currency__c = 'PLN';
    insert newBA;

    Zuora__Subscription__c newZSub = new Zuora__Subscription__c();
    newZSub.Name = 'A-S00000001';
    newZSub.Zuora__Status__c = 'Active';
    newZSub.Zuora__Account__c = acc.Id;
    newZSub.Zuora__CustomerAccount__c = newBA.Id;
    newZSub.Zuora__SubscriptionStartDate__c = Date.today();
    newZSub.Zuora__SubscriptionEndDate__c = Date.today();
    insert newZSub;

    Test.startTest();
    //String CRON_EXP  = '0 0 23 * * ?';
    SendToZuoraMock zuoraMock = new SendToZuoraMock();
    Test.setMock(HttpCalloutMock.class, zuoraMock);
    String jobId = ZSub_CancellationBatch_Scheduler.scheduleJob();
    System.assert(String.isNotBlank(jobId), 'Job neot scheduled');
    //system.schedule('Cancel Subs Schedule', CRON_EXP, new ZSub_CancellationBatch_Scheduler());
    Test.stopTest();
  }
}