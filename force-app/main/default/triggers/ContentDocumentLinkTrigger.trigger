/**
 * @author : Snehil
 * @date : 29/11/2024
 * @desc : ContentDocumentLinkTrigger
 * @see ContentDocumentLinkTrigger
 */
trigger ContentDocumentLinkTrigger on ContentDocumentLink (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete) {
    TriggerDispatcher.run(new ContentDocumentLinkTriggerHandler());
}