/**
* @author: Noor Goolamnabee
* @date : 12/07/2019
* @description : Sync Loop To Smarter via Queueable by batch
*
* -- History
* -- Date        Name        Version  Remarks
* -- -----------  ----------  -------  ---------------------------------------
-- Aug-2023     Noor                1.0         Initial version
*
*/

public with sharing class SyncLoopToSmarter extends AsyncQueueableImplementation implements Database.AllowsCallouts {
  public SyncLoopToSmarter(List<SObject> sObjects, Integer index, Integer batchSize) {
    super(sObjects, index, batchSize);
  }

  public override void processRecordList(List<SObject> processList) {
        if(processList[0].getSObjectType() == ER_Loop__c.getSObjectType()) APER43_LoopManagement.callCreateMerchantLoopStoreGroup((List<ER_Loop__c>) processList);
        if(processList[0].getSObjectType() == ER_Acceptor_to_Loop__c.getSObjectType()) APER22_AcceptorToLoopManagement.bulkifyAcceptorToLoopsSync((List<ER_Acceptor_to_Loop__c>) processList);
  }

  public override void executeNext(List<SObject> sObjects, Integer nextIndex, Integer batchSize) {
    System.debug('//NGO AsyncQueueableImplementation executeNext ' + nextIndex + ' of ' + batchSize);
    System.enqueueJob(new SyncLoopToSmarter(sObjects, nextIndex, batchSize));
  }
}