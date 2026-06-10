/**
 * @author : ALK
 * @date : 01/03/2021
 * @desc : TriggerDispatcher
 * @see TriggerDispatcher
 */

public with sharing class TriggerDispatcher {
  /*
        ALK - Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
        This method will fire the appropriate methods on the handler depending on the trigger context.
    */
  public static void run(ITriggerHandler handler) {
    //ALK - Check to see if the trigger has been disabled. If it has, return
    if (handler.isDisabled())
      return;

    //ALK - Detect the current trigger context and fire the relevant methods on the trigger handler:
    switch on Trigger.operationType {
      when BEFORE_INSERT {
        handler.beforeInsert(Trigger.new);
      }
      when AFTER_INSERT {
        handler.afterInsert(Trigger.newMap, Trigger.oldMap);
      }
      when BEFORE_UPDATE {
        handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
      }
      when AFTER_UPDATE {
        handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
      }
      when BEFORE_DELETE {
        handler.beforeDelete(Trigger.oldMap);
      }
      when AFTER_DELETE {
        handler.afterDelete(Trigger.oldMap);
      }
      when else {
        handler.afterUndelete(Trigger.oldMap);
      }
    }
  }
}