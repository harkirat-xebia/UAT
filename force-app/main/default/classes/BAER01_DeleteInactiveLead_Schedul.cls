global class BAER01_DeleteInactiveLead_Schedul implements Schedulable {
  global void execute(SchedulableContext SC) {
    BAER01_DeleteInactiveLead myBatch = new BAER01_DeleteInactiveLead();
    Id batchinstanceid = database.executeBatch(myBatch);
  }
}