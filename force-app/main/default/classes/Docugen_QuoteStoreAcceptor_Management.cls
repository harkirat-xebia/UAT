/**
 * @author: AAZ
 * @date: 11/03/2022
 * @desc: Docugen_QuoteStoreAcceptor_Management
 * @see: Docugen_QuoteStoreAcceptor_Management
 */

public with sharing class Docugen_QuoteStoreAcceptor_Management {
  /**
   * @author AAZ
   * @date 11/03/2022
   * @description count the distinct number of Stores in ER_Docugen_Quote_Store_Acceptor__c for the related Quotes
   * @param items
   * @param isAfterRemove
   */
  public static void updateQuoteNbOfStores(List<ER_Docugen_Quote_Store_Acceptor__c> items, Boolean isAfterRemove) {
    Set<Id> setQuotes = new Set<Id>();
    Set<Id> setUpdatedQuotes = new Set<Id>();
    List<Quote> quoteListToUpdate = new List<Quote>();
    Set<String> opportunityStatuses = new Set<String>{ Constants.CLOSED_WON, Constants.CLOSED_LOST };

    for (ER_Docugen_Quote_Store_Acceptor__c qsa : items) {
      setQuotes.add(qsa.ER_Quote__c);
    }

    if (setQuotes.isEmpty()) {
      for (AggregateResult ar : [
        SELECT ER_Quote__c, COUNT_DISTINCT(ER_Store__c)
        FROM ER_Docugen_Quote_Store_Acceptor__c
        WHERE
          ER_Store__c != NULL
          AND ER_Quote__c IN :setQuotes
          AND ER_Quote__r.Opportunity.StageName NOT IN :opportunityStatuses
        GROUP BY ER_Quote__c
      ]) {
        quoteListToUpdate.add(
          new Quote(Id = (Id) ar.get('ER_Quote__c'), ER_DocuGen_NbStores_In_QSA__c = (Decimal) ar.get('expr0'))
        );
        setUpdatedQuotes.add((Id) ar.get('ER_Quote__c'));
      }

      if (isAfterRemove) {
        for (Id idQ : setQuotes) {
          if (!setUpdatedQuotes.contains(idQ))
            quoteListToUpdate.add(new Quote(Id = idQ, ER_DocuGen_NbStores_In_QSA__c = 0));
        }
      }

      if (!quoteListToUpdate.isEmpty())
        GenericWithoutSharing.updateQuoteNbOfStores(quoteListToUpdate);
    }
  }
}