/**
 * @author Noor
 * @date 25/01/2022.
 * @description QuoteLineItem Trigger
 * @see QuoteLineItemTriggerHandler
 */
trigger QuoteLineItemTrigger on QuoteLineItem(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new QuoteLineItemTriggerHandler());
}