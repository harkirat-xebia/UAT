/*
----------------------------------------------------------------------
-- - Name          : ZuoraQuote_Management_AP01
-- - Author        : AAZ
-- - Description   : Zuora Quote Management   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- MAY-2021     AAZ                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

public class ZuoraQuote_Management_AP01 {
  /**
   * @author AAZ
   * @date 31/05/2021
   * @description Create a Salesforce contract once a Zuora Quote has been accepted
   * @param oldQuotes
   * @param newQuotes
   */
  public static void createSFContract(Map<Id, SObject> oldQuotes, Map<Id, SObject> newQuotes) {
    Map<Id, zqu__Quote__c> mapQuoteToProcess = new Map<Id, zqu__Quote__c>();
    zqu__Quote__c oldQuote;
    Map<Id, Boolean> mapSmarterContracts = new Map<Id, Boolean>();

    for (zqu__Quote__c newQuote : (List<zqu__Quote__c>) newQuotes.values()) {
      oldQuote = (zqu__Quote__c) oldQuotes.get(newQuote.Id);
      if (
        oldQuote.zqu__Status__c != Constants.QUOTE_STATUS_ACCEPTED &&
        newQuote.zqu__Status__c == Constants.QUOTE_STATUS_ACCEPTED
      )
        mapQuoteToProcess.put(newQuote.Id, newQuote);
    }

    if (!mapQuoteToProcess.isEmpty()) {
      List<Contract> contractsToInsert = new List<Contract>();
      Contract newContract;

      for (zqu__Quote__c quote : [
        SELECT
          Id,
          zqu__Account__c,
          zqu__Currency__c,
          zqu__Opportunity__c,
          zqu__Opportunity__r.ER_SmartER_Context__c,
          zqu__Opportunity__r.RecordType.DeveloperName,
          zqu__StartDate__c,
          zqu__Opportunity__r.ER_BUPicklist__c,
          zqu__Opportunity__r.OwnerId,
          ER_Customer_Signed_Version__c,
          ER_TCs_Signed_Link__c,
          ER_Agreement_DateTime__c,
          zqu__BillToContact__c
        FROM zqu__Quote__c
        WHERE Id IN :mapQuoteToProcess.keySet()
      ]) {
        newContract = new Contract();

        if (quote.zqu__Opportunity__r.RecordType.DeveloperName == Constants.OPPORTUNITY_MERCHANT_RT) {
          newContract.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
            Contract.SObjectType,
            Constants.CONTRACT_MERCHANT_RT
          );
        } else {
          newContract.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
            Contract.SObjectType,
            Constants.CONTRACT_CLIENT_RT
          );
        }
        newContract.ER_OpportunityId__c = quote.zqu__Opportunity__c;
        newContract.AccountId = quote.zqu__Account__c;
        newContract.CurrencyIsoCode = quote.zqu__Currency__c;
        newContract.ER_Contract_Type__c = Constants.CONTRACT_TYPE_OPERATIONAL;
        newContract.StartDate = quote.zqu__StartDate__c;
        newContract.Status = Constants.CONTRACT_STATUS_DRAFT;
        newContract.ER_ZuoraQuote__c = quote.Id;
        newContract.ER_Offline__c = true; //To review: to be managed in a CMDT per BU/Scope
        newContract.ER_BUPicklist__c = quote.zqu__Opportunity__r.ER_BUPicklist__c;
        newContract.OwnerId = quote.zqu__Opportunity__r.OwnerId;
        newContract.ER_Customer_Signed_Version__c = quote.ER_Customer_Signed_Version__c;
        newContract.ER_TCs_Signed_Link__c = quote.ER_TCs_Signed_Link__c;
        newContract.ER_Agreement_DateTime__c = quote.ER_Agreement_DateTime__c;
        newContract.CustomerSignedId = quote.zqu__BillToContact__c;
        mapSmarterContracts.put(
          quote.Id,
          (quote.zqu__Opportunity__r.ER_SmartER_Context__c != null
            ? quote.zqu__Opportunity__r.ER_SmartER_Context__c
            : false)
        );
        contractsToInsert.add(newContract);
      }

      if (!contractsToInsert.isEmpty()) {
        //Database.insert(contractsToInsert, false);
        insert contractsToInsert;

        //Next step create contract line items
        createContractLineItems(mapQuoteToProcess, contractsToInsert);

        //Then create Opp line items
        createOpportunityItems(mapQuoteToProcess);

        //Then create Solution Line Items
        for (Contract c : contractsToInsert) {
          APER20_Account_Management.manageAccountLineItemsForContract(c);
          if (!mapSmarterContracts.get(c.ER_ZuoraQuote__c)) {
            APER30_FinancialCenter_Management.manageFCLIForFinancialCenter(c);
            if (
              c.RecordTypeId ==
              Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_MERCHANT_RT)
            ) {
              APER14_Store_Management.manageSLIFromContractNew(c);
              APER23_Acceptor_Management.manageAcceptorLIFromContract(c);
            } else if (
              c.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_CLIENT_RT)
            ) {
              APER28_DeliverySite_Management.manageDSLIFromContract(c);
              APER29_DistributionPoint_Management.manageDPLIFromContract(c);
            }
          }
        }
      }
    }
  }

  /**
   * @author AAZ
   * @date 31/05/2021
   * @description Create contract line items for zuora Quote's contract
   * @param mapQuotes
   * @param insertedContracts
   */
  public static void createContractLineItems(Map<Id, zqu__Quote__c> mapQuotes, List<Contract> insertedContracts) {
    ER_ContractLineItem__c cLineItem;
    List<ER_ContractLineItem__c> cLineItemsToInsert = new List<ER_ContractLineItem__c>();
    System.debug('>>>>> AAZ - createContractLineItems mapQuotes: ' + mapQuotes);
    Set<SObject> itemsToUpdate = new Set<SObject>();
    Set<Id> ratePlansToExclude = new Set<Id>();
    Map<Id, zqu__QuoteChargeDetail__c> mapRPIdQCD = new Map<Id, zqu__QuoteChargeDetail__c>();

    List<String> excludedAmendmentTypes = Utils.getGlobalSettingsValueFromKey(
        'Zuora_Excluded_amendement_Types_' + UtilsBypass.getCurrentUser().ER_Business_Unit__c
      )
      ?.split(Constants.SEMICOLON);
    excludedAmendmentTypes = (excludedAmendmentTypes != null ? excludedAmendmentTypes : new List<String>());

    Map<Id, Id> mapSolutionPBE = ZuoraUtils.getZuoraPriceBookEntries();

    for (zqu__Quote__c quot : [
      SELECT
        Id,
        zqu__Opportunity__c,
        CurrencyIsoCode,
        (SELECT Id FROM Contracts__r WHERE Id IN :insertedContracts),
        (
          SELECT Id, zqu__ProductRatePlan__c, zqu__AmendmentType__c
          FROM zqu__Quote_Rate_Plans__r
          WHERE zqu__ProductRatePlan__r.zqu__Product__c != NULL AND zqu__QuoteProductName__c != NULL
        ),
        (
          SELECT
            Id,
            zqu__ProductRatePlan__c,
            zqu__ProductRatePlan__r.zqu__Product__c,
            zqu__ProductRatePlan__r.zqu__Product__r.Name
          FROM zqu__QuoteChargeDetails__r
        )
      FROM zqu__Quote__c
      WHERE Id IN :mapQuotes.keySet()
    ]) {
      itemsToUpdate.add(new zqu__Quote__c(Id = quot.Id, ER_Contract__c = quot.Contracts__r[0].Id));
      itemsToUpdate.add(new Opportunity(Id = quot.zqu__Opportunity__c, ContractId = quot.Contracts__r[0].Id));

      for (zqu__QuoteRatePlan__c qp : quot.zqu__Quote_Rate_Plans__r) {
        if (excludedAmendmentTypes.contains(qp.zqu__AmendmentType__c))
          ratePlansToExclude.add(qp.zqu__ProductRatePlan__c);
      }

      for (zqu__QuoteChargeDetail__c qcd : quot.zqu__QuoteChargeDetails__r) {
        if (
          !ratePlansToExclude.contains(qcd.zqu__ProductRatePlan__c) &&
          !mapRPIdQCD.containsKey(qcd.zqu__ProductRatePlan__c)
        )
          mapRPIdQCD.put(qcd.zqu__ProductRatePlan__c, qcd);
      }

      for (zqu__QuoteChargeDetail__c qd : mapRPIdQCD.values()) {
        cLineItem = new ER_ContractLineItem__c();
        cLineItem.Name = qd.zqu__ProductRatePlan__r.zqu__Product__r.Name;
        cLineItem.ER_Contract__c = (!quot.Contracts__r.isEmpty() ? quot.Contracts__r[0].Id : null);
        cLineItem.ER_Product2__c = qd.zqu__ProductRatePlan__r.zqu__Product__c;
        cLineItem.CurrencyIsoCode = quot.CurrencyIsoCode;
        if (mapSolutionPBE.containsKey(qd.zqu__ProductRatePlan__r.zqu__Product__c))
          cLineItem.ER_PricebookEntryId__c = mapSolutionPBE.get(qd.zqu__ProductRatePlan__r.zqu__Product__c);
        cLineItem.ER_UnitPrice__c = 0;
        cLineItem.ER_ListPrice__c = 0;
        cLineItem.ER_Quantity__c = 1;
        cLineItem.ER_Line_Type__c = 'Solution';

        cLineItemsToInsert.add(cLineItem);
      }
    }

    System.debug('>>>>> AAZ - createContractLineItems cLineItemsToInsert: ' + cLineItemsToInsert);
    System.debug('>>>>> AAZ - createContractLineItems itemsToUpdate: ' + itemsToUpdate);

    if (!cLineItemsToInsert.isEmpty())
      Database.insert(cLineItemsToInsert, false);
    if (!itemsToUpdate.isEmpty())
      Database.update(new List<SObject>(itemsToUpdate), false);
  }

  /**
   * @author AAZ
   * @date 14/06/2021
   * @description Copy the zQuote services on the parent opportunity line items, once a Zuora Quote has been accepted
   * @param mapQuotes
   */
  public static void createOpportunityItems(Map<Id, zqu__Quote__c> mapQuotes) {
    List<OpportunityLineItem> oppLineItemsToInsert = new List<OpportunityLineItem>();
    Map<Id, Id> mapSolutionPBE = ZuoraUtils.getZuoraPriceBookEntries();
    Set<Id> ratePlansToExclude = new Set<Id>();
    Map<Id, zqu__QuoteChargeDetail__c> mapRPIdQCD = new Map<Id, zqu__QuoteChargeDetail__c>();

    List<String> excludedAmendmentTypes = Utils.getGlobalSettingsValueFromKey(
        'Zuora_Excluded_amendement_Types_' + UtilsBypass.getCurrentUser().ER_Business_Unit__c
      )
      ?.split(Constants.SEMICOLON);
    excludedAmendmentTypes = (excludedAmendmentTypes != null ? excludedAmendmentTypes : new List<String>());

    List<zqu__Quote__c> quotes = [
      SELECT
        Id,
        zqu__Opportunity__c,
        (
          SELECT Id, zqu__ProductRatePlan__r.zqu__Product__c, zqu__AmendmentType__c
          FROM zqu__Quote_Rate_Plans__r
          WHERE zqu__ProductRatePlan__r.zqu__Product__c != NULL AND zqu__QuoteProductName__c != NULL
        ),
        (
          SELECT
            Id,
            zqu__ProductRatePlan__c,
            zqu__ProductRatePlan__r.zqu__Product__c,
            zqu__ProductRatePlan__r.zqu__Product__r.Name
          FROM zqu__QuoteChargeDetails__r
        )
      FROM zqu__Quote__c
      WHERE Id IN :mapQuotes.keySet()
    ];

    for (zqu__Quote__c q : quotes) {
      for (zqu__QuoteRatePlan__c qp : q.zqu__Quote_Rate_Plans__r) {
        if (excludedAmendmentTypes.contains(qp.zqu__AmendmentType__c))
          ratePlansToExclude.add(qp.zqu__ProductRatePlan__c);
      }

      for (zqu__QuoteChargeDetail__c qcd : q.zqu__QuoteChargeDetails__r) {
        if (
          !ratePlansToExclude.contains(qcd.zqu__ProductRatePlan__c) &&
          !mapRPIdQCD.containsKey(qcd.zqu__ProductRatePlan__c)
        )
          mapRPIdQCD.put(qcd.zqu__ProductRatePlan__c, qcd);
      }

      for (zqu__QuoteChargeDetail__c qd : mapRPIdQCD.values()) {
        if (mapSolutionPBE.containsKey(qd.zqu__ProductRatePlan__r.zqu__Product__c)) {
          OpportunityLineItem item = new OpportunityLineItem();
          item.OpportunityId = q.zqu__Opportunity__c;
          item.UnitPrice = 0;
          item.Quantity = 1;
          item.PricebookEntryId = mapSolutionPBE.get(qd.zqu__ProductRatePlan__r.zqu__Product__c);
          oppLineItemsToInsert.add(item);
        }
      }
    }

    System.debug('>>>>> AAZ - createOpportunityItems oppLineItemsToInsert: ' + oppLineItemsToInsert);
    //if(!oppLineItemsToInsert.isEmpty()) Database.insert(oppLineItemsToInsert, false);
    if (!oppLineItemsToInsert.isEmpty())
      insert oppLineItemsToInsert;
  }

  /**
   * @author Noor
   * @date 16/09/2021
   * @description align Quote Amendment Date on all children quoteAmendment of the Quote
   * @param oldQuotes
   * @param newQuotes
   */
  public static void alignQuoteAmendmentDate(Map<Id, zqu__Quote__c> oldQuotes, Map<Id, zqu__Quote__c> newQuotes) {
    List<zqu__QuoteAmendment__c> amendmentsToUpdate = new List<zqu__QuoteAmendment__c>();
    Set<Id> updatedQuote = new Set<Id>();
    for (zqu__Quote__c zQuote : newQuotes.values()) {
      if (isChangeDate(zQuote, oldQuotes.get(zQuote.Id)))
        updatedQuote.add(zQuote.Id);
    }

    for (zqu__QuoteAmendment__c amend : [
      SELECT
        Id,
        zqu__Quote__r.zqu__StartDate__c,
        zqu__Quote__r.zqu__TermStartDate__c,
        zqu__Quote__r.zqu__Service_Activation_Date__c,
        zqu__Quote__r.zqu__Customer_Acceptance_Date__c
      FROM zqu__QuoteAmendment__c
      WHERE zqu__Quote__c IN :newQuotes.keySet()
    ]) {
      amend.zqu__ContractEffectiveDate__c = amend.zqu__Quote__r.zqu__StartDate__c;
      amend.zqu__TermStartDate__c = amend.zqu__Quote__r.zqu__TermStartDate__c;
      amend.zqu__ServiceActivationDate__c = amend.zqu__Quote__r.zqu__Service_Activation_Date__c;
      amend.zqu__CustomerAcceptanceDate__c = amend.zqu__Quote__r.zqu__Customer_Acceptance_Date__c;
      amendmentsToUpdate.add(amend);
    }
    if (amendmentsToUpdate.size() > 0)
      update amendmentsToUpdate;
  }

  private static Boolean isChangeDate(zqu__Quote__c quote, zqu__Quote__c oldQuote) {
    return quote.zqu__StartDate__c != oldQuote.zqu__StartDate__c ||
      quote.zqu__TermStartDate__c != oldQuote.zqu__TermStartDate__c ||
      quote.zqu__Service_Activation_Date__c != oldQuote.zqu__Service_Activation_Date__c ||
      quote.zqu__Customer_Acceptance_Date__c != oldQuote.zqu__Customer_Acceptance_Date__c;
  }

  /**
   * @author AAZ
   * @date 28/09/2021
   * @description Following the amendment constraint prventing the update of the status in the same transaction. The status update will be run async.
   * @param ids
   */
  @Future
  public static void updateStatutAsync(Set<Id> ids) {
    List<zqu__Quote__c> quotes = new List<zqu__Quote__c>();
    for (Id qId : ids) {
      quotes.add(new zqu__Quote__c(Id = qId, zqu__Status__c = 'Draft'));
    }
    update quotes;
  }

  /**
   * @author Noor
   * @date 13/10/2021
   * @description Block deletion if quote is not in Status draft
   * @param zQuotes list of quote to be deleted
   */
  public static void blockZQuoteDeletion(List<zqu__Quote__c> zQuotes) {
    for (zqu__Quote__c zQuote : zQuotes) {
      if (!zQuote.zqu__Status__c.equalsIgnoreCase('Draft'))
        zQuote.addError(Label.LAB_SF_ZQUOTE_BLOCK_DELETE);
    }
  }

  /**
   * @author Noor
   * @date 13/10/2021
   * @description Check if quote has rate plans when accepting quote
   * @param newQuotes  updated quotes
   * @param oldQuotes old quote values
   */
  public static void checkIfQuoteHasRatePlans(Map<Id, zqu__Quote__c> newQuotes, Map<Id, zqu__Quote__c> oldQuotes) {
    List<zqu__Quote__c> acceptedQuotes = new List<zqu__Quote__c>();
    for (zqu__Quote__c newQuote : newQuotes.values()) {
      if (
        oldQuotes.get(newQuote.Id).zqu__Status__c != Constants.QUOTE_STATUS_ACCEPTED &&
        newQuote.zqu__Status__c == Constants.QUOTE_STATUS_ACCEPTED
      )
        acceptedQuotes.add(newQuote);
    }
    if (!acceptedQuotes.isEmpty()) {
      for (zqu__Quote__c zQuote : [
        SELECT Id, (SELECT Id FROM zqu__Quote_Rate_Plans__r)
        FROM zqu__Quote__c
        WHERE Id IN :acceptedQuotes
      ]) {
        if (zQuote.zqu__Quote_Rate_Plans__r.isEmpty())
          newQuotes.get(zQuote.Id).addError(Label.LAB_SF_ZQUOTE_NO_RATEPLANS);
      }
    }
  }

  /**
   * @author AAZ
   * @date 24/01/2023
   * @description Approve any change on the ZQuote for Payment Term, Mayment Method and Subscription Term
   * @param newItems
   * @param oldItemsMap
   */
  public static void approveChange(List<zqu__Quote__c> newItems, Map<Id, zqu__Quote__c> oldItemsMap) {
    List<zqu__Quote__c> selectedItems = new List<zqu__Quote__c>();
    List<zqu__Quote__c> quotesTobeRecalled = new List<zqu__Quote__c>();

    for (zqu__Quote__c q : newItems) {
      if (q.ER_SmartER_Context__c == true) {
        //Call The Terms or Discount Approval Process
        if (
          (q.zqu__PaymentMethod__c != oldItemsMap.get(q.Id).zqu__PaymentMethod__c ||
          q.zqu__PaymentTerm__c != oldItemsMap.get(q.Id).zqu__PaymentTerm__c ||
          q.zqu__Subscription_Term_Type__c != oldItemsMap.get(q.Id).zqu__Subscription_Term_Type__c) ||
          (q.ER_Has_Discount_Requires_Approval__c &&
          q.ER_Has_Discount_Requires_Approval__c != oldItemsMap.get(q.Id).ER_Has_Discount_Requires_Approval__c)
        )
          selectedItems.add(q);

        //Recall The Approval process once teh discount changes to a value under the threshold
        if (
          !q.ER_Has_Discount_Requires_Approval__c &&
          q.ER_Has_Discount_Requires_Approval__c != oldItemsMap.get(q.Id).ER_Has_Discount_Requires_Approval__c &&
          q.ER_Approval_Status__c == Constants.PENDING &&
          q.ER_Approval_Status__c == oldItemsMap.get(q.Id).ER_Approval_Status__c
        )
          quotesTobeRecalled.add(q);
      }
    }

    if (!selectedItems.isEmpty()) {
      for (zqu__Quote__c q : selectedItems) {
        String approvalComment;
        //submit for approval
        if (
          q.ER_Has_Discount_Requires_Approval__c &&
          q.ER_Has_Discount_Requires_Approval__c != oldItemsMap.get(q.Id).ER_Has_Discount_Requires_Approval__c
        )
          approvalComment = String.format(
            Label.LAB_SF_ZQU_MSG_APPROVAL_DISCOUNT,
            new List<String>{ UserInfo.getName() }
          );
        else
          approvalComment = String.format(Label.LAB_SF_ZQU_MSG_APPROVAL_TERMS, new List<String>{ UserInfo.getName() });
        submitZQuoteForApproval(q.Id, approvalComment);
      }
    }

    if (!quotesTobeRecalled.isEmpty()) {
      for (zqu__Quote__c q : quotesTobeRecalled)
        recallApproval(q.Id, 'The Approval step rolled back after changing the discount value');
    }
  }

  /**
   * @author AAZ
   * @date 24/01/2023
   * @description Submit ZQuote for approval
   * @param quoteId
   * @param approvalMessage
   */
  public static void submitZQuoteForApproval(Id quoteId, String approvalMessage) {
    if (String.isNotBlank(quoteId)) {
      Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
      req.setObjectId(quoteId);
      req.setComments(approvalMessage);
      Approval.process(req);
    }
  }

  /**
   * @author AAZ
   * @date 24/01/2023
   * @description Recall Pending Approval process
   * @param quoteId
   * @param approvalMessage
   */
  public static void recallApproval(Id quoteId, String approvalMessage) {
    if (String.isNotBlank(quoteId)) {
      ProcessInstanceWorkitem[] workItems = [
        SELECT Id
        FROM ProcessInstanceWorkitem
        WHERE ProcessInstance.TargetObjectId = :quoteId AND ProcessInstance.Status = :Constants.PENDING
        ORDER BY CreatedDate DESC
      ];

      Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
      pwr.setAction(Constants.REMOVED);
      pwr.setComments(approvalMessage);
      pwr.setWorkitemId(workItems[0].Id);
      Approval.process(pwr);
    }
  }

  /**
   * @author AAZ
   * @description align the "payment term","payment method","contract duration" on Z-Quote, Opportunity and BA Objects
   * @param newItems
   * @param oldItemsMap
   */
  public static void syncFieldsOppBaZquote(List<zqu__Quote__c> newItems, Map<Id, zqu__Quote__c> oldItemsMap) {
    List<zqu__Quote__c> selectedQuotes = new List<zqu__Quote__c>();
    List<Id> selectedQuoteIds = new List<Id>();
    Map<Id, zqu__Quote__c> mapOppIdsQuotes = new Map<Id, zqu__Quote__c>();
    List<Opportunity> listOppsToUpdate = new List<Opportunity>();

    for (zqu__Quote__c q : newItems) {
      if (
        q.ER_Approval_Status__c != oldItemsMap.get(q.Id).ER_Approval_Status__c &&
        q.ER_Approval_Status__c == Constants.APPROVED &&
        q.zqu__Status__c != Constants.QUOTE_STATUS_ACCEPTED
      ) {
        selectedQuotes.add(q);
        selectedQuoteIds.add(q.Id);
        mapOppIdsQuotes.put(q.zqu__Opportunity__c, q);
      }
    }

    //Update linked Opp
    for (Id oppId : mapOppIdsQuotes.keySet()) {
      listOppsToUpdate.add(
        new Opportunity(
          Id = oppId,
          ER_PaymentTerms__c = mapOppIdsQuotes.get(oppId).zqu__PaymentTerm__c,
          ER_PaymentMethod__c = mapOppIdsQuotes.get(oppId).zqu__PaymentMethod__c,
          ER_Contract_Duration__c = mapOppIdsQuotes.get(oppId).zqu__Subscription_Term_Type__c
        )
      );
    }
    System.debug('>>>>> AAZ syncFieldsOppBaZquote - listOppsToUpdate : ' + listOppsToUpdate);
    if (!listOppsToUpdate.isEmpty())
      update listOppsToUpdate;

    //Update linked Billing account
    /*if(!selectedQuotes.isEmpty()) {//TODO
            Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
            dte.Transaction_Name__c = Constants.MANAGE_ZQUOTE_SYNC_FIELDS;
            dte.Transaction_Content__c = JSON.serializePretty(selectedQuotes);
            EventBus.publish(dte);
        }*/
    System.debug('>>>>> AAZ syncFieldsOppBaZquote - selectedQuotes : ' + selectedQuoteIds);
    if (!selectedQuoteIds.isEmpty())
      updateZuoraAccountsAsync(selectedQuoteIds);
  }

  /**
   * @author AAZ
   * @description called by syncFieldsOppBaZquote()
   * @param qIds
   */
  @Future(Callout=true)
  public static void updateZuoraAccountsAsync(List<Id> qIds) { 
      List<zqu__Quote__c> quotes = [SELECT Id, ER_Business_Unit__c, zqu__ZuoraAccountID__c, zqu__PaymentMethod__c, zqu__PaymentTerm__c, zqu__Opportunity__r.RecordType.DeveloperName FROM zqu__Quote__c WHERE Id IN :qIds];
      System.debug('>>>>> AAZ updateZuoraAccountsAsync - quotes : ' + quotes);
      ZuoraUtils.updateZuoraAccounts(quotes, null);
  }

  /**
   * @author AAZ
   * @date 24/01/2023
   * @description Update ER_Number_Of_High_Discounts on Quote
   * @param newItems
   * @param oldMap
   */
  public static void updateNumberOfHighDiscounts(List<zqu__QuoteRatePlanCharge__c> newItems) {
      Map<Id, zqu__Quote__c> mapQuotes = new Map<Id, zqu__Quote__c>();
      Map<Id, Integer> mapQuoteNbDiscount = new Map<Id, Integer>();
      List<zqu__QuoteRatePlanCharge__c> smarterItems = new List<zqu__QuoteRatePlanCharge__c>();
      Map<Id, String> mapQuoteLevel = new Map<Id, String>();

      for(zqu__QuoteRatePlanCharge__c newItem :[SELECT Id, Name, zqu__Discount__c, ER_Quote__c,
                                                      ER_Quote__r.ER_SmartER_Context__c,
                                                      zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_Percent__c,
                                                      zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_2_Percent__c
                                                  FROM zqu__QuoteRatePlanCharge__c
                                                  WHERE Id IN :newItems
                                                  AND ER_Quote__r.ER_SmartER_Context__c = TRUE]) {
          smarterItems.add(newItem);
      }

      if(!smarterItems.isEmpty()) {
          for(zqu__QuoteRatePlanCharge__c newItem :smarterItems) {
              System.debug('>>>>> AAZ - newItem.Name ' + newItem.Name + ' - newItem.Discount : ' + newItem.zqu__Discount__c);
              if(!mapQuoteNbDiscount.containsKey(newItem.ER_Quote__c)) mapQuoteNbDiscount.put(newItem.ER_Quote__c, 0);
              System.debug('>>>>> AAZ - newItem.zqu__Discount__c > discountThreshold : '
                      + (newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_Percent__c != null
                      && newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_Percent__c > 0
                      && newItem.zqu__Discount__c > newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_Percent__c));

              System.debug('>>>>> AAZ - newItem.zqu__Discount__c > discountThreshold : '
                      + (newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_2_Percent__c != null
                      && newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_2_Percent__c > 0
                      && newItem.zqu__Discount__c > newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_2_Percent__c));

              System.debug('>>>>> AAZ - !mapQuotes.containsKey(newItem.ER_Quote__c) : ' + (!mapQuotes.containsKey(newItem.ER_Quote__c)));

              if(((mapQuoteLevel.containsKey(newItem.ER_Quote__c) && mapQuoteLevel.get(newItem.ER_Quote__c) != 'Level 2')
                      || !mapQuoteLevel.containsKey(newItem.ER_Quote__c))
                      && newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_2_Percent__c != null
                      && newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_2_Percent__c > 0
                      && newItem.zqu__Discount__c > newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_2_Percent__c) {

                  System.debug('>>>>> AAZ - newItem.zqu__Discount__c > discountThreshold2');
                  mapQuotes.put(newItem.ER_Quote__c, new zqu__Quote__c(Id = newItem.ER_Quote__c, ER_Has_Discount_Requires_Approval__c = true, ER_Approval_Level__c = 'Level 2'));
                  mapQuoteNbDiscount.put(newItem.ER_Quote__c, mapQuoteNbDiscount.get(newItem.ER_Quote__c) + 1);
                  mapQuoteLevel.put(newItem.ER_Quote__c, 'Level 2');
              }

              if((!mapQuoteLevel.containsKey(newItem.ER_Quote__c))
                      && newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_Percent__c != null
                      && newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_Percent__c > 0
                      && newItem.zqu__Discount__c > newItem.zqu__ProductRatePlanCharge__r.ER_Approval_Threshold_Percent__c) {
                  System.debug('>>>>> AAZ - newItem.zqu__Discount__c > discountThreshold');
                  mapQuotes.put(newItem.ER_Quote__c, new zqu__Quote__c(Id = newItem.ER_Quote__c, ER_Has_Discount_Requires_Approval__c = true, ER_Approval_Level__c = 'Level 1'));
                  mapQuoteNbDiscount.put(newItem.ER_Quote__c, mapQuoteNbDiscount.get(newItem.ER_Quote__c) + 1);
                  mapQuoteLevel.put(newItem.ER_Quote__c, 'Level 1');
              }

              System.debug('>>>>> AAZ - mapQuoteNbDiscount :' + mapQuoteNbDiscount);
          }

          for(zqu__Quote__c q :[SELECT Id, ER_Has_Discount_Requires_Approval__c FROM zqu__Quote__c WHERE Id IN :mapQuoteNbDiscount.keySet() AND ER_Has_Discount_Requires_Approval__c = TRUE]) {
              System.debug('>>>>> AAZ - soql q : ' + q);
              if(mapQuoteNbDiscount.get(q.Id) == 0) mapQuotes.put(q.Id, new zqu__Quote__c(Id = q.Id, ER_Has_Discount_Requires_Approval__c = false));
          }

          System.debug('>>>>> AAZ - mapQuotes ' + mapQuotes);
          if(!mapQuotes.isEmpty()) {
              for(Id qId :mapQuotes.keySet()) {
                  GenericWithoutSharing.unLockApprovalRecord(qId);
              }
              Database.update(mapQuotes.values(), false);
          }
      }
  }

  /**
   * @author AAZ
   * @description Update the Zuora Approval Status to be used later in the other transaction to unlock the ZQuote record
   * @param quotes
   * @param oldItems
   */
  public static void updateZuoraApprovalStatus(List<zqu__Quote__c> quotes, Map<Id, zqu__Quote__c> oldItems) {
    if (quotes != null && !quotes.isEmpty() && oldItems != null && !oldItems.isEmpty())
      GenericWithoutSharing.updateZuoraApprovalStatus(quotes, oldItems);
  }

  @AuraEnabled
  public static String getTCs(Id recordId) {
    try {
      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      if (
        smarterAT != null &&
        !smarterAT.isEmpty() &&
        smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
        smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
      ) {
        zqu__Quote__c zq = [
          SELECT Id, Name, ER_Business_Unit__c, zqu__BillToContact__r.ER_Language__c
          FROM zqu__Quote__c
          WHERE Id = :recordId
        ];

        if (
          zq.ER_Business_Unit__c == null ||
          zq.zqu__BillToContact__c == null ||
          zq.zqu__BillToContact__r.ER_Language__c == null
        ) {
          return Label.LAB_SF_SMARTER_TCS_NO_BU_ERROR;
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
          'callout:' +
          Constants.SMARTER_NAMED_CREDENTIAL +
          Constants.SLASH +
          Constants.SMARTER_GET_TCs_SERVICE_VERSION +
          Constants.SLASH +
          Constants.SMARTER_GET_TCs_SERVICE_NAME
        );
        req.setMethod(Constants.GET_METHOD);
        req.setHeader(Constants.X_TENANT, zq.ER_Business_Unit__c.toLowerCase());
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/pdf');
        req.setHeader(
          'Authorization',
          smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
          ' ' +
          smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
        );
        req.setHeader('Accept-Language', zq.zqu__BillToContact__r.ER_Language__c.toLowerCase());
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        Http http = new Http();
        HttpResponse resp = http.send(req);

        if (resp.getStatusCode() == 200) {
          Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          Map<String, Object> dataMap = (Map<String, Object>) (mapRespData.get('data'));
          updateZQuoteAndCreateCv(
            zq,
            (String) dataMap.get('version'),
            (String) dataMap.get('fileUrl'),
            (String) dataMap.get('language')
          );
        } else {
          Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          Map<String, Object> dataMap = (Map<String, Object>) (mapRespData.get('meta'));
          return (String) ((Map<String, Object>) (((List<Object>) dataMap.get('messages'))[0])).get('text');
        }
      } else {
        return Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens';
      }
    } catch (Exception ex) {
      System.debug(' >>> HD - Exception caugth ' + ex.getMessage());
      return ex.getMessage();
    }
    return null;
  }

  private static void updateZQuoteAndCreateCv(zqu__Quote__c zQuote, String signedVersion, String TCsUrl, String lang) {
    // Create content version :
    // Chek the version of the T&Cs
    String fileName = lang + '_termsConditionsSaleClient_' + signedVersion;
    String pathOnClient = zQuote.Id + '_' + fileName + '.' + TCsUrl.substringAfterLast('.');
    Map<id, ContentVersion> cvMap = new Map<id, ContentVersion>(
      [SELECT Id, ContentDocumentId FROM ContentVersion WHERE PathOnClient = :pathOnClient]
    );

    if (cvMap.isEmpty()) {
      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      if (
        smarterAT != null &&
        !smarterAT.isEmpty() &&
        smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
        smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
      ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TCsUrl);
        req.setMethod(Constants.GET_METHOD);
        req.setHeader(
          'Authorization',
          smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) + smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
        );
        HttpResponse res = new Http().send(req);

        if (res != null) {
          Blob imageBlob = res.getBodyAsBlob();
          ContentVersion cv = new ContentVersion();
          cv.Title = fileName;
          cv.PathOnClient = pathOnClient;
          cv.IsMajorVersion = true;
          cv.VersionData = imageBlob;
          Database.insert(cv);

          ContentVersion newCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
          ContentDocumentLink cdl = new ContentDocumentLink();
          cdl.LinkedEntityId = zQuote.Id;
          cdl.ContentDocumentId = newCV.ContentDocumentId;
          cdl.ShareType = 'V';
          Database.insert(cdl);
        }
      }

      // Updat the quote
      Database.update(
        new zqu__Quote__c(
          Id = zQuote.Id,
          ER_Customer_Signed_Version__c = signedVersion,
          ER_TCs_Signed_Link__c = TCsUrl
        ),
        false
      );
    }
  }

  /**
   * @author AAZ
   * @date 05/04/2023
   * @description Update the agreement date after accepting the quote
   * @param newItems
   */
  public static void updateTCsAgreementDate(List<zqu__Quote__c> newItems) {
    for (zqu__Quote__c q : newItems) {
      if (
        q.ER_SmartER_Context__c &&
        String.isNotBlank(q.ER_Customer_Signed_Version__c) &&
        q.zqu__Status__c == Constants.ACCEPTED
      )
        q.ER_Agreement_DateTime__c = Datetime.now();
    }
  }

  /**
   * @author AAZ
   * @date 04/05/2023
   * @description Default ZQuote values
   * @param newItems
   */
  public static void zQuoteDefaultingValues(List<zqu__Quote__c> newItems, Map<Id, zqu__Quote__c> oldMapItems) {
    for (zqu__Quote__c q : newItems) {
      if (q.ER_Approval_Status__c == Constants.PENDING && (q.zqu__Status__c == Constants.DRAFT || q.zqu__Status__c == Constants.APPROVED))
        q.zqu__Status__c = Constants.PENDING_APPROVAL;
      else if (q.ER_Approval_Status__c == Constants.APPROVED && q.zqu__Status__c == Constants.PENDING_APPROVAL)
        q.zqu__Status__c = Constants.APPROVED;
      else if (q.ER_Approval_Status__c == Constants.REJECTED && q.zqu__Status__c == Constants.PENDING_APPROVAL)
        q.zqu__Status__c = Constants.DRAFT;
      else if (
        oldMapItems != null &&
        String.isEmpty(q.ER_Approval_Status__c) &&
        q.ER_Approval_Status__c != oldMapItems.get(q.Id).ER_Approval_Status__c
      )
        q.zqu__Status__c = Constants.DRAFT;
    }
  }
}