/**
 * Created by khaddouch on 10/05/2023.
 */

trigger BulkContractAmendmentTrigger on ER_Bulk_Contract_Amendment__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new BulkContractAmendmentTriggerHandler());
}