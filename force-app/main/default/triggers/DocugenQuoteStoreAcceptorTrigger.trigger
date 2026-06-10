/**
 * @author: AAZ
 * @date: 11/03/2022
 * @desc: DocugenQuoteStoreAcceptorTrigger
 * @see: DocugenQuoteStoreAcceptorTrigger
 */

trigger DocugenQuoteStoreAcceptorTrigger on ER_Docugen_Quote_Store_Acceptor__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerDispatcher.run(new DocugenQuoteStoreAcceptorTriggerHandler());
}