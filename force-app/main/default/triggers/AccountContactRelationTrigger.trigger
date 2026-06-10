/**
 * Created by ATI on 21/08/2023.
 */
 
trigger AccountContactRelationTrigger on AccountContactRelation (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new AccountContactRelationTriggerHandler());
}