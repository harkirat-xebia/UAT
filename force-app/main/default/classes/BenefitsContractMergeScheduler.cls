/**
 * @description Schedules BenefitsContractMergeBatch. Runs live over every eligible account; the batch
 *              is idempotent, so accounts already merged are re-read and skipped without new DML.
 *
 *   System.schedule('Benefits Contract Merge', '0 0 2 ? * SAT', new BenefitsContractMergeScheduler());
 */
public with sharing class BenefitsContractMergeScheduler implements Schedulable {
  /** Accounts per execute() transaction. Keeps the line item query and DML well inside governor limits. */
  private static final Integer SCOPE_SIZE = 10;

  /**
   * @description Starts the merge batch over every eligible account.
   * @param context Scheduler context.
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new BenefitsContractMergeBatch(null, false), SCOPE_SIZE);
  }
}
