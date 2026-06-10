/**
 * @author: ALK
 * @date: 04/01/2023
 * @desc: DistributedTransactionEvtTrigger
 * @see: DistributedTransactionEvtTrigger
 */

trigger DistributedTransactionEvtTrigger on Distributed_Transaction_Event__e(after insert) {
  TriggerDispatcher.run(new DistributedTransactionEvtTriggerHandler());
}