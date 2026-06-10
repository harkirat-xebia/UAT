/**
 * @author Noor
 * @date 25/01/2022.
 * @description APER36_QuoteLineItem_Management
 * @see APER36_QuoteLineItem_Management
 */

 public with sharing class APER36_QuoteLineItem_Management {
  public static Boolean isFirstRun = true;

  /**
   * @author Noor
   * @description get product code on all existing quoteline items and update it on Quote.ER_DocuGen_Solution__c
   * @date 25/01/2022.
   * @param newItems created or deleted quoteline items
   */
  public static void updateSolutionCodeOnQuote(List<QuoteLineItem> newItems) {
    Map<Id, Set<String>> solutionQuoteMap = new Map<Id, Set<String>>();
    List<Id> quoteIds = new List<Id>();
    List<Quote> quotes = new List<Quote>();

      for (QuoteLineItem item : newItems){
          if(item.Account_Type__c != 'SME'){
              quoteIds.add(item.QuoteId);
          }
      }

    for (QuoteLineItem item : [
      SELECT Id, Product2.ER_Solution2__r.ProductCode, QuoteId
      FROM QuoteLineItem
      WHERE QuoteId IN :quoteIds
    ]) {
      if (!solutionQuoteMap.containsKey(item.QuoteId))
        solutionQuoteMap.put(item.QuoteId, getProductCode(item.Product2.ER_Solution2__r.ProductCode));
      else
        solutionQuoteMap.get(item.QuoteId).addAll(getProductCode(item.Product2.ER_Solution2__r.ProductCode));
    }

    for (Id id : solutionQuoteMap.keySet())
      quotes.add(new Quote(Id = id, ER_DocuGen_Solution__c = convertSetToDelimitedString(solutionQuoteMap.get(id))));

    if (!quotes.isEmpty())
      update quotes;
  }

  /**
   * @author Noor
   * @description convert a set of string in a delimited (pipe) values of string
   * @date 25/01/2022.
   * @param stringSet set of string
   *
   * @return a string delimited by |
   */
  private static String convertSetToDelimitedString(Set<String> stringSet) {
    String result;

    if (!stringSet.isEmpty()) {
      result = Constants.DELIMITER_PIPE;
      for (String val : stringSet)
        result += val + Constants.DELIMITER_PIPE;
    }

    return result;
  }

  /**
   * @author Noor
   * @description convert a delimited string to a set of String
   * @date 25/01/2022
   * @param value value delimited by ;
   *
   * @return a set of string
   */
  private static Set<String> getProductCode(String value) {
    Set<String> result = new Set<String>();
    if (String.isNotBlank(value))
      result.addAll(value.split(';'));
    return result;
  }

  /**
   * @author CWAN
   * @description Block Quote Line Item deletion
   * @date 23/02/2022.
   * @param newItems created or deleted quoteline items
   */
  public static void blockQuoteLineItemDeletion(List<QuoteLineItem> newItems) {
    if (!UtilsBypass.getCurrentUser().ER_BypassVR__c) {
      for (QuoteLineItem qli : newItems) {
        qli.addError(Label.LABS_SF_Quote_Line_Item_block_delete);
      }
    }
  }

  /**
   * @author snica
   * @description  populate main solution on the quote with the smallest Line Order
   * @date 24/02/2022.
   * @param newItems
   */
  public static void updateMainSolutionOnQuote(List<QuoteLineItem> newItems) {
    List<Quote> quoteToUpdate = new List<Quote>();
    Map<Id, Id> solutionQuoteMap = new Map<Id, Id>();
    List<Id> quoteIds = new List<Id>();

      for (QuoteLineItem item : newItems){
          if(item.Account_Type__c != 'SME'){
              quoteIds.add(item.QuoteId);
          }
      }

    for (QuoteLineItem item : [
      SELECT Id, Product2.ER_Solution2__c, Product2.ER_Solution2__r.ER_Line_Order__c, QuoteId
      FROM QuoteLineItem
      WHERE QuoteId IN :quoteIds
      ORDER BY Product2.ER_Solution2__r.ER_Line_Order__c ASC
    ]) {
      if (!solutionQuoteMap.containsKey(item.QuoteId))
        solutionQuoteMap.put(item.QuoteId, item.Product2.ER_Solution2__c);
    }

    for (Id quoteId : solutionQuoteMap.keySet())
      quoteToUpdate.add(new Quote(Id = quoteId, ER_Main_Solution__c = solutionQuoteMap.get(quoteId)));

    if (!quoteToUpdate.isEmpty())
      update quoteToUpdate;
  }

  /**
   * @author AAZ
   * @date 27/05/2022
   * @description Get Products Translations
   * @param items
   */
  public static void getProductsNameTranslations(List<QuoteLineItem> items) {
    if (isFirstRun) {
      isFirstRun = false;
      Set<Id> productsIds = new Set<Id>();
      Map<Id, QuoteLineItem> mapServiceQli = new Map<Id, QuoteLineItem>();
      Map<Id, List<QuoteLineItem>> mapSolutionQli = new Map<Id, List<QuoteLineItem>>();
      Map<String, ER_Translation__c> mapTranslations = new Map<String, ER_Translation__c>();
      Map<Id, QuoteLineItem> mapItemsToUpdate = new Map<Id, QuoteLineItem>();

      for (QuoteLineItem qli : [
        SELECT
          Id,
          Quote.ER_DocuGen_Contact_Preferred_Language__c,
          Product2Id,
          Product2.Name,
          Product2.ER_Solution2__c,
          Product2.ER_Solution2__r.Name,
          ER_Service_Translated_Name__c,
          ER_Solution_Translated_Name__c
        FROM QuoteLineItem
        WHERE Id IN :items AND Account_Type__c != 'SME'
      ]) {
        productsIds.add(qli.Product2Id);
        if (qli.Product2.ER_Solution2__c != null)
          productsIds.add(qli.Product2.ER_Solution2__c);
        mapServiceQli.put(qli.Product2Id, qli);
        if (!mapSolutionQli.containsKey(qli.Product2.ER_Solution2__c))
          mapSolutionQli.put(qli.Product2.ER_Solution2__c, new List<QuoteLineItem>());
        mapSolutionQli.get(qli.Product2.ER_Solution2__c).add(qli);
      }

      System.debug('####### AAZ getProductsNameTranslations mapServiceQli : ' + mapServiceQli);
      System.debug('####### AAZ getProductsNameTranslations mapSolutionQli : ' + mapSolutionQli?.values().size());

      for (ER_Translation__c tr : [
        SELECT Id, Field_API_Name__c, Text__c, Text_Area__c, Long_Text_Area__c, Language__c, Product__c
        FROM ER_Translation__c
        WHERE Product__c IN :productsIds AND Field_API_Name__c = :Constants.NAME
      ]) {
        mapTranslations.put(tr.Product__c + tr.Language__c.toUpperCase(), tr);
      }

      System.debug('####### AAZ getProductsNameTranslations mapTranslations : ' + mapTranslations);

      String serviceTranslation = '';
      String solutionTranslation = '';
      for (QuoteLineItem qli : items) {
        for (QuoteLineItem qlse : mapServiceQli.values()) {
          if (qli.Id == qlse.Id) {
            String key =
              qli.Product2Id +
              (String.isNotBlank(qlse.Quote.ER_DocuGen_Contact_Preferred_Language__c)
                ? qlse.Quote.ER_DocuGen_Contact_Preferred_Language__c.toUpperCase()
                : '');

            if (
              mapTranslations.containsKey(key) &&
              mapTranslations.get(key).Language__c.toUpperCase() ==
              qlse.Quote.ER_DocuGen_Contact_Preferred_Language__c.toUpperCase()
            )
              serviceTranslation = (String.isNotBlank(mapTranslations.get(key).Text__c)
                ? mapTranslations.get(key).Text__c
                : (String.isNotBlank(mapTranslations.get(key).Text_Area__c)
                    ? mapTranslations.get(key).Text_Area__c
                    : (String.isNotBlank(mapTranslations.get(key).Long_Text_Area__c)
                        ? mapTranslations.get(key).Long_Text_Area__c
                        : qlse.Product2.Name)));
            else
              serviceTranslation = qlse.Product2.Name;

            mapItemsToUpdate.put(
              qli.Id,
              new QuoteLineItem(Id = qli.Id, ER_Service_Translated_Name__c = serviceTranslation)
            );
            break;
          }
        }

        for (List<QuoteLineItem> qlis : mapSolutionQli.values()) {
          for (QuoteLineItem qlso : qlis) {
            if (qli.Id == qlso.Id) {
              String key =
                qlso.Product2.ER_Solution2__c +
                (String.isNotBlank(qlso.Quote.ER_DocuGen_Contact_Preferred_Language__c)
                  ? qlso.Quote.ER_DocuGen_Contact_Preferred_Language__c.toUpperCase()
                  : '');
              if (
                mapTranslations.containsKey(key) &&
                mapTranslations.get(key).Language__c == qlso.Quote.ER_DocuGen_Contact_Preferred_Language__c
              )
                solutionTranslation = (String.isNotBlank(mapTranslations.get(key).Text__c)
                  ? mapTranslations.get(key).Text__c
                  : (String.isNotBlank(mapTranslations.get(key).Text_Area__c)
                      ? mapTranslations.get(key).Text_Area__c
                      : (String.isNotBlank(mapTranslations.get(key).Long_Text_Area__c)
                          ? mapTranslations.get(key).Long_Text_Area__c
                          : qlso.Product2.ER_Solution2__r.Name)));
              else
                solutionTranslation = qlso.Product2.ER_Solution2__r.Name;

              if (mapItemsToUpdate.containsKey(qli.Id))
                mapItemsToUpdate.get(qli.Id).ER_Solution_Translated_Name__c = solutionTranslation;
              else
                mapItemsToUpdate.put(
                  qli.Id,
                  new QuoteLineItem(Id = qli.Id, ER_Solution_Translated_Name__c = solutionTranslation)
                );
              break;
            }
          }
        }
      }
      System.debug('######### AAZ getProductsNameTranslations :' + mapItemsToUpdate);
      if (mapItemsToUpdate.size() > 0)
        update mapItemsToUpdate.values();
    }
  }
}