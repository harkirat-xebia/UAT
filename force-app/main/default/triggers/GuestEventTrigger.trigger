/**
 * @author : AAM
 * @date : 29/03/2021
 * @desc : GuestEventTrigger
 * @see GuestEventTrigger
 */

trigger GuestEventTrigger on Guest_Event__e(after insert) {
  TriggerDispatcher.run(new GuestEventTriggerHandler());
}