/**
 * @author: ALK
 * @date: 22/08/2023
 * @desc: SyncAccountContactRelationToSmarter
 * @see: SyncAccountContactRelationToSmarter
 */

public with sharing class SyncAccountContactRelationToSmarter extends AsyncQueueableImplementation implements Database.AllowsCallouts {
    public SyncAccountContactRelationToSmarter(List<SObject> sObjects, Integer index, Integer batchSize) {
        super(sObjects, index, batchSize);
    }

    public override void processRecordList(List<SObject> processList) {
        if(processList[0].getSObjectType() == AccountContactRelation.getSObjectType()) APER44_AccountContactRelationManagement.doSync((List<AccountContactRelation>) processList);
    }

    public override void executeNext(List<SObject> sObjects, Integer nextIndex, Integer batchSize) {
        System.enqueueJob(new SyncAccountContactRelationToSmarter(sObjects, nextIndex, batchSize));
    }

}