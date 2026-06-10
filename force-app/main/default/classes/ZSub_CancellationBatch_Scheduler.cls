/**
 * @author : AAZ
 * @date : 15/07/2021
 * @desc : Scheduler for the batch ZuoraSubscription_CancellationBatch
 * @see ZSub_CancellationBatch_Scheduler
 */

global class ZSub_CancellationBatch_Scheduler implements Schedulable {
  public static String CRON_EXP = '0 0 1 * * ? *';
  public static String query;
  public static String jobName = 'ZSub_CancellationBatch_Scheduler';

  global void execute(SchedulableContext SC) {
    if (String.isBlank(query)) {
      query =
        'SELECT Id, Name, Zuora__Account__r.ER_BUPicklist__c, Zuora__SubscriptionEndDate__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c FROM Zuora__Subscription__c ' +
        'WHERE Zuora__SubscriptionEndDate__c <= TODAY AND Zuora__Status__c = \'Active\' ';
    }

    ZuoraSubscription_CancellationBatch myBatch = new ZuoraSubscription_CancellationBatch(query);
    Database.executeBatch(myBatch, 90);
  }

  global static String scheduleJob() {
    return scheduleJob(jobName);
  }

  global static String scheduleJob(String jobNameString) {
    ZSub_CancellationBatch_Scheduler scheduler = new ZSub_CancellationBatch_Scheduler();
    return System.schedule(jobNameString, CRON_EXP, scheduler);
  }
}