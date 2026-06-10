/*
----------------------------------------------------------------------
-- - Name          : APER12_Contract_Management
-- - Author        : OLA
-- - Description   : Contract Management, This class is used to group all the functionnality linked to the object Contract
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Jan-2019       OLA                 1.0         Initial version.
--  Jan-2020       OLA                 2.0         Add Offline Mode.
--  FEB-2021       VJOY                3.0         Add mapping for range fields(min, max, line type from QLI).
--  FEB-2021       KHAD                4.0         Solution at all level
--  APR-2021       KHAD                5.0         Contract Naming convention
--  SEP-2021       AAM                 6.0         Set ownerId from Quote in createContractFromQuote method (PBI#12394)
---------------------------------------------------------------------------------------
*/
public without sharing class APER12_Contract_Management {
  //Adding new method
  private static Boolean smeEngagementProcessed = false;
  private static Set<Id> processedContractIds;
  public static List<Contract> createContractFromQuote(Map<id, Quote> acceptedQuoteMap) {
    List<Contract> contractToInsert = new List<Contract>();
    Contract newContract;
    Savepoint sp = Database.setSavepoint();
    Map<id, String> oppLeadSources = new Map<id, String>();

    try {
      List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
      Map<String, Contact> roleContactMap = new Map<String, Contact>();
      
      List<Quote> quoteList = [
        SELECT
          Id,
          OpportunityId,
          Opportunity.ER_Contract_Expected_Start_Date__c,
          Opportunity.LeadSource,
          Opportunity.Creditting__c,
          Opportunity.Contract_End_Date__c,
          Opportunity.Primary_Contact__c,
          Opportunity.Invoicing_Contact__c,
          AccountId,
          Pricebook2Id,
          CurrencyIsoCode,
          RecordType.DeveloperName,
          ER_Credit_Limit__c,
          ER_Indexation_Index__c,
          ER_InvoicingFrequency__c,
          ER_PaymentMethod__c,
          ER_PaymentTerms__c,
          Opportunity.ER_Solutions__c,
          ER_ReimbursementTerm__c,
          SK_Credit_Note_Frequency__c,
          SK_Payment_Terms_Voucher__c,
          ER_Contract_Duration__c,
          ER_SEPA_Bank_Account__c,
          ER_Indexation__c,
          ER_Original_Agreement__c,
          ER_Quote_Type__c,
          OwnerId,
          Opportunity.ER_BUPicklist__c,
          ERBE_Reimbursement_Statement_Frequency2__c,
          ERBE_Reimbursement_Statement_Support2__c,
          ERBE_Weekly_Frequence__c,
          ER_Invoicing_payment_delay__c,
          ER_Invoicing_day_of_week__c
        FROM Quote
        WHERE Id IN :acceptedQuoteMap.keySet()
      ];
      ocrList = [SELECT Id, ContactId, Role, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone FROM OpportunityContactRole WHERE OpportunityId = :quoteList[0].OpportunityId];

      for(OpportunityContactRole ocr : ocrList){
          roleContactMap.put(ocr.Role, ocr.Contact);
      }

      for (Quote quote : quoteList) {
        System.debug('APER12_Contract_Management : createContractFromQuote : Account : ' + quote.AccountId);
        oppLeadSources.put(quote.opportunityId, quote.Opportunity.LeadSource);

        newContract = new Contract();
        if (quote.RecordType.DeveloperName == 'ER_Client_Quote') {
          newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
            .get('ER_Client_Contract_RT')
            .getRecordTypeId();
        } else if (quote.RecordType.DeveloperName == 'ER_Merchant_Quote') {
          newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
            .get('ER_Merchant_Contract_RT')
            .getRecordTypeId();
        }
        newContract.ER_QuoteId__c = quote.Id;
        newContract.Creditting__c = quote.Opportunity.Creditting__c;
        newContract.ER_OpportunityId__c = quote.OpportunityId;
        newContract.AccountId = quote.AccountId;
        newContract.Pricebook2Id = quote.Pricebook2Id;
        newContract.OwnerId = quote.OwnerId; // AAM-09.09.2021 : PBI#12394
        newContract.CurrencyIsoCode = quote.CurrencyIsoCode;
        newContract.ER_Credit_Limit2__c = quote.ER_Credit_Limit__c;
        newContract.ER_Indexation_Index2__c = quote.ER_Indexation_Index__c;
        newContract.ER_InvoicingFrequency2__c = quote.ER_InvoicingFrequency__c;
        newContract.ER_PaymentMethod2__c = quote.ER_PaymentMethod__c;
        newContract.ER_PaymentTerms2__c = quote.ER_PaymentTerms__c;
        newContract.ER_ReimbursementTerm2__c = quote.ER_ReimbursementTerm__c;
        newContract.SK_Credit_Note_Frequency2__c = quote.SK_Credit_Note_Frequency__c;
        newContract.SK_Payment_Terms_Voucher2__c = quote.SK_Payment_Terms_Voucher__c;
        newContract.ER_OppIndexation2__c = quote.ER_Indexation__c;
        newContract.ER_Contract_Type__c = quote.ER_Quote_Type__c;
        newContract.ER_Original_Agreement__c = quote.ER_Original_Agreement__c;
        newContract.StartDate = (quote.Opportunity.ER_Contract_Expected_Start_Date__c != null)
          ? quote.Opportunity.ER_Contract_Expected_Start_Date__c
          : Date.today();
        //newContract.StartDate = Date.today();
        newContract.EndDate = quote.Opportunity.Contract_End_Date__c;//Added 28 Aug, 2024
        newContract.Billing_Contact__c = quote.Opportunity.Invoicing_Contact__c;//Added 5 Nov, 2024
        newContract.Primary_Contact__c = quote.Opportunity.Primary_Contact__c;//Added 5 Nov, 2024
        //newContract.ER_TerminationReason__c = 'Not Interested anymore';//Added 28 Aug, 2024
        newContract.ER_BUPicklist__c = quote.Opportunity.ER_BUPicklist__c; // AAM-21.01.2022 : PBI#14291
        newContract.ER_Contract_Duration__c = quote.ER_Contract_Duration__c;
        newContract.ER_Solutions__c = quote.Opportunity.ER_Solutions__c;
        newContract.ERBE_Reimbursement_Statement_Frequency__c = quote.ERBE_Reimbursement_Statement_Frequency2__c;
        newContract.ERBE_Reimbursement_statement_Support__c = quote.ERBE_Reimbursement_Statement_Support2__c;
        newContract.ER_SEPA_Bank_Account__c = quote.ER_SEPA_Bank_Account__c;
        newContract.ERBE_Invoicing_day_of_week__c = quote.ER_Invoicing_day_of_week__c;
        newContract.ERBE_Invoicing_Payment_Delay__c = quote.ER_Invoicing_payment_delay__c;
        newContract.ERBE_Weekly_Frequence__c = quote.ERBE_Weekly_Frequence__c;
        if (!Test.isRunningTest()) {
          newContract.CustomerSignedId = roleContactMap.get('Primary Contact').Id;
        }
        newContract.CustomerSignedDate = System.today();
        contractToInsert.add(newContract);
      }
      if (!contractToInsert.isEmpty()) {
        System.debug('contractToInsert : ' + contractToInsert);
        insert contractToInsert;

        for (Contract cntr : contractToInsert) {
          acceptedQuoteMap.get(cntr.ER_QuoteId__c).ContractId = cntr.Id;
          System.debug('acceptedQuoteMap : ' + acceptedQuoteMap);
        }
        createCLIAndUpdateOpportunity(acceptedQuoteMap);

        if (newContract.ER_Contract_Type__c == Label.LAB_SF_Contact_Operational) {
          APER20_Account_Management.manageAccountLineItemsForContract(newContract);
          APER30_FinancialCenter_Management.manageFCLIForFinancialCenter(newContract);
          if (
            newContract.RecordTypeId ==
            Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
              .get('ER_Merchant_Contract_RT')
              .getRecordTypeId()
          ) {
            APER14_Store_Management.manageSLIFromContractNew(newContract);
            APER23_Acceptor_Management.manageAcceptorLIFromContract(newContract);
          } else if (
            newContract.RecordTypeId ==
            Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
              .get('ER_Client_Contract_RT')
              .getRecordTypeId()
          ) {
            APER28_DeliverySite_Management.manageDSLIFromContract(newContract);
            APER29_DistributionPoint_Management.manageDPLIFromContract(newContract);
          }

          //Activate SLIs for Online Acquisition process
          if (
            oppLeadSources.get(newContract.ER_OpportunityId__c) == Constants.CONTRACTING_WEBFORM &&
            String.isNotBlank(newContract.ER_Solutions__c)
          )
            APER30_AutoEnrollment_Management.activateAutoenrollmentSLIs(
              newContract.AccountId,
              newContract.ER_Solutions__c
            );
        }
      }
    } catch (Exception e) {
      Database.rollback(sp);
    }
    return contractToInsert;
  }
    
    public static void createCLIAndUpdateOpportunity(Map<Id, Quote> acceptedQuoteMap) {
        Map<Id, String> productIdSolutionCodeMap = new Map<Id, String>();
        Map<Id, String> productIdProductCodeMap = new Map<Id, String>();
        Map<Id, String> productTypeMap = new Map<Id, String>();
        Map<String, Date> mapProductEndDate = new Map<String, Date>();
        Map<Id, Map<String, Map<String, Boolean>>> solutionDiscountAppliedMap = new Map<Id, Map<String, Map<String, Boolean>>>();
        Map<Id, List<QuoteLineItem>> qliMap = new Map<Id, List<QuoteLineItem>>();
        Map<Id, Boolean> benefitMap = new Map<Id, Boolean>();
        Map<Id, Id> quoteOppIdMap = new Map<Id, Id>();
        
        //Map<String, Date> endDateByproductCodeMap = new Map<String, Date>();
        Boolean benefitFlag = false;
        Id contractId;
        ER_ContractLineItem__c cli;
        List<ER_ContractLineItem__c> cliToInsert = new List<ER_ContractLineItem__c>(); 
        List<Opportunity> opportunityToUpdate = new List<Opportunity>(); // update contract Id field
        Opportunity opportunityInst;
        
        for (QuoteLineItem qliObj : [SELECT Id, Quote.OpportunityId, Opportunity_Product__c, ListPrice,Discount,UnitPrice,ER_What__c,CurrencyIsoCode,PricebookEntryId,Product2Id,Product2.Name,Quantity,
                ER_Percentage__c,ER_NeedApproval__c,ER_Creation_date_in_OS__c,ER_Card_Operational_System_ID__c,ER_Minimum_Fee__c,ER_Line_Type__c,ER_Max__c,ER_Min__c,
                Quote.Opportunity.ER_Contract_Expected_Start_Date__c,ER_Offer_validity_end_date__c,Product2.RecordTypeId,ER_Duration__c,Product2.RecordType.Name,TECH_ContactStartDate__c,
                ER_Quantity_Unit_of_Measure__c,ER_Price_End_Date__c,Product2.ProductCode,Product2.Solution_Group__c,Product2.ER_Solution2__r.ProductCode,Product2.ER_Type__c,
                ER_Price_Start_Date__c,Quote.OwnerId,Quote.Opportunity.ER_BUPicklist__c,ER_User_Discount__c,ER_Edenred_Margin_TUR__c,ER_Free_to_setup_the_margin__c,ER_MPV__c,
                ER_Cumulative_with_Promotions__c FROM QuoteLineItem WHERE QuoteId IN :acceptedQuoteMap.keySet()
        ]) {
            if(!qliMap.containsKey(qliObj.QuoteId)){
                qliMap.put(qliObj.QuoteId, new List<QuoteLineItem>{qliObj});
            }else{
                qliMap.get(qliObj.QuoteId).add(qliObj);
            }
            if(!benefitMap.containsKey(qliObj.QuoteId)){
                benefitMap.put(qliObj.QuoteId, false);
            }
            if(qliObj.Product2.Solution_Group__c == 'Benefits'){
                benefitMap.put(qliObj.QuoteId, true);
            }
            productIdSolutionCodeMap.put(qliObj.Product2Id, qliObj.Product2.ER_Solution2__r.ProductCode);
            productIdProductCodeMap.put(qliObj.Product2Id, qliObj.Product2.ProductCode);
            productTypeMap.put(qliObj.Product2Id, qliObj.Product2.ER_Type__c);
            quoteOppIdMap.put(qliObj.QuoteId, qliObj.Quote.OpportunityId);
        }
        
        for(Id quoteId : qliMap.keySet()){
            opportunityInst = new Opportunity(
                Id = quoteOppIdMap.get(quoteId),
                ContractId = acceptedQuoteMap.get(quoteId).ContractId
            ); //(from trigger before update) ==> cannot get ContractId from Query Yet!
            
            opportunityToUpdate.add(opportunityInst);
            for(QuoteLineItem qliObj : qliMap.get(quoteId)){
                if(!solutionDiscountAppliedMap.containsKey(quoteId)){
                    solutionDiscountAppliedMap.put(quoteId, new Map<String, Map<String, Boolean>>());
                    solutionDiscountAppliedMap.get(quoteId).put(productIdSolutionCodeMap.get(qliObj.Product2Id), new Map<String, Boolean>());
                    solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(qliObj.Product2Id)).put(productIdProductCodeMap.get(qliObj.Product2Id), false);
                    if(productTypeMap.get(qliObj.Product2Id) == 'Discount'){
                        solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(qliObj.Product2Id)).put(productIdProductCodeMap.get(qliObj.Product2Id), true);
                    }
                }else{
                    if(!solutionDiscountAppliedMap.get(quoteId).containsKey(productIdSolutionCodeMap.get(qliObj.Product2Id))){
                        solutionDiscountAppliedMap.get(quoteId).put(productIdSolutionCodeMap.get(qliObj.Product2Id), new Map<String, Boolean>());
                        solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(qliObj.Product2Id)).put(productIdProductCodeMap.get(qliObj.Product2Id), false);
                        if(productTypeMap.get(qliObj.Product2Id) == 'Discount'){
                            solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(qliObj.Product2Id)).put(productIdProductCodeMap.get(qliObj.Product2Id), true);
                        }
                    }else{
                        if(!solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(qliObj.Product2Id)).containsKey(productIdProductCodeMap.get(qliObj.Product2Id))){
                            solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(qliObj.Product2Id)).put(productIdProductCodeMap.get(qliObj.Product2Id), false);
                        }
                        if(productTypeMap.get(qliObj.Product2Id) == 'Discount'){
                            solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(qliObj.Product2Id)).put(productIdProductCodeMap.get(qliObj.Product2Id), true);
                        }
                    }
                }
            }
        }
        
        for(Id quoteId : qliMap.keySet()){
            for(QuoteLineItem qli : qliMap.get(quoteId)){
                cli = new ER_ContractLineItem__c();
                cli.Name = qli.Product2.Name;
                cli.Opportunity_Product__c = qli.Opportunity_Product__c;
                cli.ER_Contract__c = acceptedQuoteMap.get(quoteId).ContractId;
                cli.ER_Percentage__c = qli.ER_Percentage__c;
                cli.ER_Product2__c = qli.Product2Id;
                cli.ER_PricebookEntryId__c = qli.PricebookEntryId;
                cli.CurrencyIsoCode = qli.CurrencyIsoCode;
                cli.ER_UnitPrice__c = qli.UnitPrice;
                cli.ER_ListPrice__c = qli.ListPrice;
                cli.ER_Quantity__c = qli.Quantity;
                cli.ER_NeedApproval__c = qli.ER_NeedApproval__c;
                cli.ER_Minimum_Fee__c = qli.ER_Minimum_Fee__c;
                cli.ER_Card_Operational_System_ID__c = qli.ER_Card_Operational_System_ID__c;
                cli.ER_Discount__c = qli.Discount;
                cli.ER_What__c = qli.ER_What__c;
                
                cli.ER_Line_Type__c = qli.ER_Line_Type__c;
                cli.ER_Max__c = qli.ER_Max__c;
                cli.ER_Min__c = qli.ER_Min__c;
                
                cli.ER_Offer_validity_end_date__c = qli.ER_Offer_validity_end_date__c;
                cli.ER_Quantity_Unit_of_Measure__c = qli.ER_Quantity_Unit_of_Measure__c;
                Date contractStartDate = (qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c != null
                                          ? qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c
                                          : Date.today());
                
                cli.OwnerId = qli.Quote.OwnerId; // AAM 18.11.21: PBI#13620
                cli.ER_BUPicklist__c = qli.Quote.Opportunity.ER_BUPicklist__c; // AAM 18.11.21: PBI#14291
                
                cli.ER_User_Discount__c = qli.ER_User_Discount__c;
                cli.ER_Edenred_Margin_TUR__c = qli.ER_Edenred_Margin_TUR__c;
                cli.ER_Free_To_Set_Margin__c = qli.ER_Free_to_setup_the_margin__c;
                cli.ER_MPV__c = qli.ER_MPV__c;
                cli.Cumulative_with_Promotions__c = qli.ER_Cumulative_with_promotions__c;
                if(benefitMap.get(quoteId)){
                    if(solutionDiscountAppliedMap.get(quoteId).get(productIdSolutionCodeMap.get(cli.ER_Product2__c)).get(productIdProductCodeMap.get(cli.ER_Product2__c))){
                        if(productTypeMap.get(cli.ER_Product2__c) == 'Discount'){
                            cli.ER_IsActive__c  = true;
                        }else{
                            cli.ER_IsActive__c  = false;
                        }
                    }else{
                        if(productTypeMap.get(cli.ER_Product2__c) != 'Discount'){
                            cli.ER_IsActive__c  = true;
                        }else{
                            cli.ER_IsActive__c  = false;
                        }
                    }
                }else{
                    cli.ER_IsActive__c  = true;
                }
                cliToInsert.add(cli);
            }
        }
        
        if (!cliToInsert.isEmpty()) {
            System.debug('cliToInsert : ' + cliToInsert);
            insert cliToInsert;
        }
        
        if (!opportunityToUpdate.isEmpty()) {
            System.debug('opportunityToUpdate : ' + opportunityToUpdate);
            APER04_Opportunity_Management.updateOpportunityContract(opportunityToUpdate);
        }
    }

  @Future
  public static void deleteContractFromQuote(Set<id> deniedQuoteContractids) {
    List<Contract> contractListToDelete = new List<Contract>();
    Contract contractToDelete = new Contract();

    for (Id contractId : deniedQuoteContractids) {
      contractToDelete = new Contract(Id = contractId);
      contractListToDelete.add(contractToDelete);
    }
    if (!contractListToDelete.isEmpty()) {
      System.debug('contractListToDelete : ' + contractListToDelete);
      delete contractListToDelete;
    }
  }

  @AuraEnabled
  public static List<Contract> getContract(String contractId) {
    return getContract(new List<Id>{ contractId });
  }

  /**
   * @author : HEL
   * @description Get Contracts
   * @param contractIds
   * @return List
   */
  public static List<Contract> getContract(List<Id> contractIds) {
    return [
      SELECT
        Id,
        RecordTypeId,
        ER_Business_Unit__c,
        ER_InvoicingFrequency2__c,
        ER_ReimbursementTerm2__c,
        CustomerSigned.Email,
        CustomerSignedId,
        ERBE_Reimbursement_Statement_Frequency__c,
        Status,
        ER_Indexation__c,
        ER_OppIndexation2__c,
        ER_PaymentTerms2__c,
        ER_PaymentMethod2__c,
        Account.ER_VIP__c,
        Subscription__c,
        ER_ZuoraQuote__c,
        ERBE_Reimbursement_statement_Support__c,
        AccountId,
        Account.Name,
        StartDate,
        EndDate,
        ER_OpportunityId__c,
        ER_OpportunityId__r.ER_IsAmended__c,
        ER_OpportunityId__r.ER_AmendedFromContract__c,
        ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId,
        ContractNumber,
        ER_Creation_date_in_OS__c,
        CustomerSignedDate,
        ER_OpportunityId__r.ER_AmendedFromContract__r.StartDate,
        ER_Contract_Type__c,
        ER_Original_Agreement__c,
        ER_Original_Agreement__r.Status,
        ER_Original_Agreement__r.ER_Contract_Type__c,
        RecordType.DeveloperName,
        ER_OpportunityId__r.ER_SmartER_Context__c,
        ER_BUPicklist__c,
        (
          SELECT
            Id,
            ER_Contract__c,
            Name,
            ER_Solution__c,
            ER_ProductCode__c,
            ER_Creation_date_in_OS__c,
            ER_Product2__c,
            ER_Product2__r.Name
          FROM ER_ContractLineItems__r
        )
      FROM Contract
      WHERE Id IN :contractIds
    ];
  }

  public static Map<Id, ER_ContractLineItem__c> getContractLineItems(String contractId) {
    return new Map<Id, ER_ContractLineItem__c>(
      [
        SELECT
          id,
          Name,
          ER_Business_Unit__c,
          ER_Contract__r.ER_PaymentTerms2__c,
          ER_Contract__r.ER_PaymentMethod2__c,
          ER_Solution__c,
          ER_ProductCode__c,
          ER_Creation_date_in_OS__c,
          ER_Minimum_Fee__c,
          ER_Product2__c,
          ER_Product2__r.ER_Solution__c,
          ER_Contract__r.accountId,
          ER_Product2__r.ER_Do_Not_Synchronize__c
        FROM ER_ContractLineItem__c
        WHERE ER_Contract__c = :contractId
      ]
    );
  }

  public static Map<Id, ER_ContractLineItem__c> getAllActiveContractLineItems(Set<String> companyIds) {
    return new Map<Id, ER_ContractLineItem__c>(
      [
        SELECT
          id,
          Name,
          ER_Contract__r.ER_PaymentTerms2__c,
          ER_Contract__r.ER_PaymentMethod2__c,
          ER_Solution__c,
          ER_ProductCode__c,
          ER_Creation_date_in_OS__c,
          ER_Minimum_Fee__c,
          ER_Product2__c,
          ER_Product2__r.ER_Solution__c,
          ER_Contract__r.accountId
        FROM ER_ContractLineItem__c
        WHERE
          ER_Contract__r.status = :Label.LABS_SF_Contract_Status_Activated
          AND ER_Contract__r.AccountId IN :companyIds
      ]
    );
  }

  /*
      * LASFAR
      * 14/02/2019
      * contractAmendment : 2 cases:
                  1- Clone the opportunity linked to the current contract
                  2- Create new Opportunity from the current contract (contract came from data init)
      */
  @AuraEnabled
  public static Opportunity contractAmendment(String contractId, String opportunityId) {
    return APER04_Opportunity_Management.createOpportunityFromContract(contractId, opportunityId);
  }

  @AuraEnabled
  public static void activateContractController(Contract contract, String opportunityId, Boolean isOfflineBU) {
    if (contract != null) {
      List<Contract> contractToUpdate = new List<Contract>();

      contract.ER_Offline__c = isOfflineBU;
      if (contract.ER_Creation_date_in_OS__c == null)
        contract.ER_Creation_date_in_OS__c = Datetime.now();
      contract.Status = Label.LABS_SF_Contract_Status_Activated;
      contractToUpdate.add(contract);

      if (contract.ER_OpportunityId__c != null && contract.ER_OpportunityId__r.ER_IsAmended__c) {
        String contractId = String.isNotBlank(contract.ER_OpportunityId__r.ER_AmendedFromContract__c)
          ? contract.ER_OpportunityId__r.ER_AmendedFromContract__c
          : contract.ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId;
        Contract terminateContract = new Contract(Id = contractId);
        terminateContract.ER_Offline__c = isOfflineBU;
        terminateContract.ER_TerminationReason__c = Label.LAB_SF_Contract_Amendment;
        //Check if the contract is a zuora contract then assign the new contract start date - 1
        if (Schema.SObjectType.Contract.fields.ER_ZuoraQuote__c.isAccessible() && contract.ER_ZuoraQuote__c != null) {
          terminateContract.Status = Label.LABS_SF_Contract_Status_Pending_Termination;
          if (contract.StartDate == contract.ER_OpportunityId__r.ER_AmendedFromContract__r.StartDate)
            terminateContract.EndDate = contract.StartDate;
          else if (contract.StartDate > contract.ER_OpportunityId__r.ER_AmendedFromContract__r.StartDate)
            terminateContract.EndDate = contract.StartDate.addDays(-1);
        } else {
          terminateContract.Status = Label.LABS_SF_Contract_Status_Terminated;
          terminateContract.ER_Terminated_Date__c = Datetime.now();
          terminateContract.EndDate = Date.today();
        }
        contractToUpdate.add(terminateContract);
      }

      System.debug('## activateContractController update : ' + contractToUpdate);
      update contractToUpdate;

      //ALK - Manage Solution Line Items Asynchronously
      Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
      dte.Transaction_Name__c = Constants.MANAGE_SOLUTION_LINE_ITEMS;
      dte.Transaction_Content__c = JSON.serializePretty(contract);
      EventBus.publish(dte);
    }
  }

  /**
   * @author ALK
   * @date 02/01/2023
   * @description run solution line items management asynchronously
   * @param activatedContact
   */
  public static void manageSolutionLineItems(Contract activatedContact) {
    if (activatedContact != null && activatedContact.ER_Contract_Type__c == Label.LAB_SF_Contact_Operational) {
      //CloseWon the opportunity
      if (String.isNotBlank(activatedContact.ER_OpportunityId__c))
        setOpportunityToCloseWon(activatedContact.ER_OpportunityId__c);

      APER20_Account_Management.manageStatusOnContractActivation(activatedContact.AccountId);
      APER20_Account_Management.manageAccountLineItemsForContract(activatedContact);

      if (!activatedContact.ER_OpportunityId__r.ER_SmartER_Context__c) {
        APER14_Store_Management.manageSLIFromContract(activatedContact.AccountId);
        APER30_FinancialCenter_Management.manageFCLIForFinancialCenter(activatedContact);
        if (
          activatedContact.RecordTypeId ==
          Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_MERCHANT_RT)
        ) {
          APER14_Store_Management.manageSLIFromContractNew(activatedContact);
          APER23_Acceptor_Management.manageAcceptorLIFromContract(activatedContact);
        } else if (
          activatedContact.RecordTypeId ==
          Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_CLIENT_RT)
        ) {
          APER28_DeliverySite_Management.manageDSLIFromContract(activatedContact);
          APER29_DistributionPoint_Management.manageDPLIFromContract(activatedContact);
        }
      }
    }
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param oppId
   */
  private static void setOpportunityToCloseWon(Id oppId) {
    GenericWithoutSharing.setOpportunityToCloseWon(oppId);
  }

  /*
   * LASFAR
   * 27/03/2019
   * terminateContract : For batch process, update status to Terminated when WS status is succeeded.
   * 02/01/2020 : Add Offline Mode.
   */
  public static void terminateContract(Contract contract, Boolean isOfflineBU) {
    contract.Status = Label.LABS_SF_Contract_Status_Terminated;
    contract.ER_Terminated_Date__c = Datetime.now();
    contract.ER_Offline__c = isOfflineBU;
    update contract;
    APER20_Account_Management.manageStatusOnContractTermination(contract.AccountId);
    APER14_Store_Management.manageSLIFromContract(contract.AccountId);
  }

  /**
   * @author ALK
   * @description Terminate Contracts
   * @param contracts
   */
  public static void terminatedContacts(List<Contract> contracts) {
    Set<Id> contactsIds = new Set<Id>();
    Map<Id, Contract> mapAmendedContracts = new Map<Id, Contract>();

    for (Contract c : contracts) {
      c.Status = Label.LABS_SF_Contract_Status_Terminated;
      c.ER_Terminated_Date__c = Datetime.now();
    }

    Database.SaveResult[] results = Database.update(contracts, false);

    for (Database.SaveResult sr : results) {
      if (sr.isSuccess())
        contactsIds.add(sr.getId());
    }

    // Deactivate accounts having no more active contracts
    if (!contactsIds.isEmpty())
      APER20_Account_Management.deactivateAccountsStatusForTerminatedContracts(contactsIds);
  }

  /*
   * LASFAR
   * 14/02/2019
   * deleteCLIFromContract : For each deleted contract delete linked contract line items (no Master detail RelationShip)
   */
  public static void deleteCLIFromContract(Map<id, Contract> contractMap) {
    List<ER_ContractLineItem__c> cliToDelete = new List<ER_ContractLineItem__c>();

    for (Contract contractInst : [
      SELECT Id, (SELECT id FROM ER_ContractLineItems__r)
      FROM Contract
      WHERE id = :contractMap.keyset()
    ]) {
      for (ER_ContractLineItem__c cliInst : contractInst.ER_ContractLineItems__r) {
        cliToDelete.add(cliInst);
      }
    }
    if (!cliToDelete.isEmpty()) {
      System.debug('#cliToDelete Size : ' + cliToDelete.size());
      delete cliToDelete;
    }
  }

  /*
   * KHAD
   * FEB 2021
   * Delete SLI Related to contract.
   */
  public static void deleteSLIFromContract(Map<id, Contract> contractMap) {
    List<ER_Solution_Line_Item__c> SliToDelete = new List<ER_Solution_Line_Item__c>();

    for (Contract contractInst : [
      SELECT Id, (SELECT id FROM Solution_Line_Items__r)
      FROM Contract
      WHERE id = :contractMap.keyset()
    ]) {
      for (ER_Solution_Line_Item__c cliInst : contractInst.Solution_Line_Items__r) {
        SliToDelete.add(cliInst);
      }
    }
    if (!SliToDelete.isEmpty()) {
      System.debug('#SliToDelete Size : ' + SliToDelete.size());
      delete SliToDelete;
    }
  }

  /**
   * @author Noor
   * @date 28/10/2021
   * @description Check if contract product code overlap with another active contract when date is changed
   * @param newItems upatesContract
   * @param oldItems Contract
   * @return List of errors
   */
  public static void validateIfContractDateOverlap(Map<Id, Contract> newItems, Map<Id, Contract> oldItems) {
    List<Id> updatedActivationPeriod = new List<Id>();
    List<String> zuoraDeployedBU = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('ZUORA_DEPLOYED_BUs'));
    List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('Bypass_Active_Contract_Process'));
    List<Id> accountIds = new List<Id>();
    for (Contract myContract : newItems.values()) {
      if (
        !myContract.Status.equalsIgnoreCase('Draft') &&
        zuoraDeployedBU.contains(myContract.ER_Business_Unit__c) &&
        !bus.contains(myContract.ER_Business_Unit__c) &&
        !UtilsBypass.getCurrentUser().ER_BypassVR__c &&
        (myContract.StartDate != oldItems.get(myContract.Id).StartDate ||
        myContract.EndDate != oldItems.get(myContract.Id).EndDate)
      ) {
        updatedActivationPeriod.add(myContract.Id);
        accountIds.add(myContract.AccountId);
      }
    }

    if (!updatedActivationPeriod.isEmpty())
      retrieveExistingSolutionAndCompareDate(updatedActivationPeriod, accountIds, newItems);
  }

  //New method added by harkirat for updating the field, (contract approval process flow)
  public static void markNemoSyncPending( Map<Id, Contract> newContracts, Map<Id, Contract> oldContracts) {
    if (newContracts == null || oldContracts == null) return;

    for (Contract newCon : newContracts.values()) {
        Contract oldCon = oldContracts.get(newCon.Id);
        if (oldCon == null) continue;

        Boolean paymentMethodChanged =
            newCon.ER_PaymentMethod2__c != oldCon.ER_PaymentMethod2__c;

        Boolean paymentTermsChanged =
            newCon.ER_PaymentTerms2__c != oldCon.ER_PaymentTerms2__c;

        // ADDING VALUE ACC TO REQUIREMENT
        if (
            (paymentMethodChanged || paymentTermsChanged)
        ) {
            newCon.NEMO_Sync_Pending__c = true;
            System.debug(
                '### markNemoSyncPending → TRUE for ' + newCon.Id +
                ' | PaymentMethodChanged=' + paymentMethodChanged +
                ' | PaymentTermsChanged=' + paymentTermsChanged
            );
        }
    }
}



  /**
   * @author Noor
   * @date 14/09/2021
   * @description Check if the solution to be added exists already on an active contract having the same type
   * @param updatedActivationPeriod Contract where EndDate or StartDate has changed
   * @param accountIds Account for which the contracts has changed
   * @param newItems Contract object from trigger
   *
   */
  public static void retrieveExistingSolutionAndCompareDate(
    List<Id> updatedActivationPeriod,
    List<Id> accountIds,
    Map<Id, Contract> newItems
  ) {
    List<Contract> contractList = getContract(updatedActivationPeriod);
    Map<Id, Account> merchantList = getExistingSolutionByAccounts(accountIds);
    for (Contract con : contractList) {
      String scope = (con.RecordType.DeveloperName == Constants.CONTRACT_MERCHANT_RT
        ? Constants.MERCHANT
        : Constants.CLIENT);
      checkExistingSolutionsWithUpdatedContract(con, scope, merchantList.get(con.AccountId), newItems);
    }
  }

  /**
   * @author Noor
   * @date 14/09/2021
   * @description Block update of end date by throwing an AddError if date overlap
   * @param contractIns Contract where EndDate or StartDate has changed
   * @param scope
   * @param accountIns Account for which the contracts has changed
   * @param newItems Contract object from trigger
   *
   */
  public static void checkExistingSolutionsWithUpdatedContract(
    Contract contractIns,
    String scope,
    Account accountIns,
    Map<Id, Contract> newItems
  ) {
    Map<String, ER_Solution_Line_Item__c> accountSolutionsMap = new Map<String, ER_Solution_Line_Item__c>();

    for (ER_Solution_Line_Item__c solution : accountIns.Solution_Line_Items__r) {
      Contract newContract = newItems.get(contractIns.Id);
      if (
        String.isNotBlank(solution.ER_Solution__c) &&
        solution.ER_Contract__c != contractIns.Id &&
        String.isNotBlank(solution.ER_Solution__r.BU_External_Reference__c) &&
        Utils.checkDatesBetween2Dates(
          newContract.StartDate,
          newContract.EndDate,
          solution.ER_Contract__r.StartDate,
          solution.ER_Contract__r.EndDate
        ) &&
        solution.ER_Scope__c.contains(scope)
      ) {
        for (String bu_reference : solution.ER_Solution__r.BU_External_Reference__c.split('\\|')) {
          accountSolutionsMap.put(bu_reference, solution);
        }
      }
    }
    System.debug('//NGO accountSolutionsMap' + accountSolutionsMap);

    for (ER_ContractLineItem__c item : contractIns.ER_ContractLineItems__r) {
      System.debug('//NGO item' + item);
      if (String.isNotBlank(item.ER_Solution__c)) {
        for (String contractSolutionCode : item.ER_Solution__c.split('\\|')) {
          //if(accountSolutionsMap.containsKey(contractSolutionCode) AND SAME SCOPE)
          if (accountSolutionsMap.containsKey(contractSolutionCode))
            newItems.get(contractIns.Id)
              .addError(
                Label.LABS_SF_SOLUTION_EXIST_IN_ACTIVE_CONTRACT
                  .replace('{0}', item.ER_Product2__r.Name)
                  .replace('{1}', accountSolutionsMap.get(contractSolutionCode).ER_Contract__r.ContractNumber)
              );
        }
      }
    }
  }

  //Method added by harkirat
    public static void createAcrForContracts(
      Map<Id, SObject> newItems,
      Map<Id, SObject> oldItems
  ) {
      if (newItems == null || newItems.isEmpty()) {
          return;
      }

      // Cast maps
      Map<Id, Contract> newConMap = (Map<Id, Contract>) newItems;
      Map<Id, Contract> oldConMap =
          (oldItems != null ? (Map<Id, Contract>) oldItems : null);

      List<Contract> contractsToProcess = new List<Contract>();
      Set<Id> contactIds = new Set<Id>();
      Set<Id> accountIds = new Set<Id>();

      // 1) Collect contracts where CustomerSignedId actually changed / got set
      for (Contract conNew : newConMap.values()) {
          Contract conOld =
              (oldConMap != null ? oldConMap.get(conNew.Id) : null);

          Boolean custSignedChanged =
              (conOld == null && conNew.CustomerSignedId != null) ||
              (conOld != null && conNew.CustomerSignedId != conOld.CustomerSignedId);

          if (!custSignedChanged) {
              continue;
          }

          if (conNew.AccountId != null && conNew.CustomerSignedId != null) {
              contractsToProcess.add(conNew);
              contactIds.add(conNew.CustomerSignedId);
              accountIds.add(conNew.AccountId);
          }
      }

      if (contractsToProcess.isEmpty()) {
          return;
      }

      // 2) Fetch existing ACRs for these Account + Contact combos
      List<AccountContactRelation> existingAcrs = [
          SELECT Id, AccountId, ContactId
          FROM AccountContactRelation
          WHERE AccountId IN :accountIds
            AND ContactId IN :contactIds
      ];

      Set<String> existingPairs = new Set<String>();
      for (AccountContactRelation acr : existingAcrs) {
          existingPairs.add(
              String.valueOf(acr.AccountId) + '-' + String.valueOf(acr.ContactId)
          );
      }

      // 3) Create missing ACRs
      List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();

      for (Contract con : contractsToProcess) {
          String key = String.valueOf(con.AccountId) + '-' + String.valueOf(con.CustomerSignedId);
          if (!existingPairs.contains(key)) {
              acrsToInsert.add(new AccountContactRelation(
                  AccountId = con.AccountId,
                  ContactId = con.CustomerSignedId
              ));
          }
      }

      if (!acrsToInsert.isEmpty()) {
          insert acrsToInsert;
      }
  }


  public static Map<Id, Account> getExistingSolutionByAccounts(List<Id> accountIds) {
    //Get ER_Account_Line_Item record Type Id
    String Account_Line_ItemRTId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Account_Line_Item'
    );

    return new Map<Id, Account>(
      [
        SELECT
          Id,
          Name,
          ER_BUPicklist__c,
          (
            SELECT
              Id,
              ER_Solution__c,
              ER_Solution__r.BU_External_Reference__c,
              ER_Contract__c,
              ER_Contract__r.ContractNumber,
              ER_Contract__r.EndDate,
              ER_Contract__r.StartDate,
              ER_Scope__c
            FROM Solution_Line_Items__r
            WHERE RecordTypeId = :Account_Line_ItemRTId AND ER_Solution__r.zqu__Category__c = 'Base Products'
          )
        FROM Account
        WHERE Id IN :accountIds
      ]
    );
  }
  /**
   * @author Noor
   * @date 14/09/2021
   * @description Check if the solution to be added exists already on an active contract having the same type
   * @param accountIns Account
   * @param contractIns Contract
   * @return List of errors
   */
  public static List<APHU13_ErrorBeforeEdg> checkExistingSolutionsContractOnAccount(
    Account accountIns,
    Contract contractIns
  ) {
    Map<String, ER_Solution_Line_Item__c> accountSolutionsMap = new Map<String, ER_Solution_Line_Item__c>();
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    for (ER_Solution_Line_Item__c solution : accountIns.Solution_Line_Items__r) {
      if (
        String.isNotBlank(solution.ER_Solution__c) &&
        String.isNotBlank(solution.ER_Solution__r.BU_External_Reference__c)
      ) {
        for (String bu_reference : solution.ER_Solution__r.BU_External_Reference__c.split('\\|')) {
          accountSolutionsMap.put(bu_reference, solution);
        }
      }
    }

    for (ER_ContractLineItem__c item : contractIns.ER_ContractLineItems__r) {
      if (String.isNotBlank(item.ER_Solution__c))
        listError = populateErrorRecord(accountIns.Name, item, accountSolutionsMap);
    }

    return listError;
  }

  public static List<APHU13_ErrorBeforeEdg> populateErrorRecord(
    String accountName,
    ER_ContractLineItem__c item,
    Map<String, ER_Solution_Line_Item__c> accountSolutionsMap
  ) {
    List<APHU13_ErrorBeforeEdg> errors = new List<APHU13_ErrorBeforeEdg>();
    system.debug('//NGO accountSolutionsMap ' + accountSolutionsMap);
    for (String contractSolutionCode : item.ER_Solution__c.split('\\|')) {
      if (accountSolutionsMap.containsKey(contractSolutionCode)) {
        APHU13_ErrorBeforeEdg error = new APHU13_ErrorBeforeEdg();
        error.sObjName = 'Contract';
        error.sName = accountName;
        error.sMessage = Label.LABS_SF_SOLUTION_EXIST_IN_ACTIVE_CONTRACT.replace('{0}', item.ER_Product2__r.Name)
          .replace('{1}', accountSolutionsMap.get(contractSolutionCode).ER_Contract__r.ContractNumber);
        error.sLink = '/lightning/r/Contract/' + accountSolutionsMap.get(contractSolutionCode).ER_Contract__c + '/view';
        error.sSection = 'Existing Solutions';
        errors.add(error);
        break;
      }
    }
    return errors;
  }

  /*
   * LASFAR
   * 02/01/2020
   * isOfflineBU : Check if the BU is Offline and All Contract's products are synchronized.
   */
  @AuraEnabled
  public static Boolean isOfflineBU(Contract contractInst) {
    APER30_AutoEnrollment_Management.syncRecordBU = contractInst.ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    if (isOfflineBU) {
      return isOfflineBU;
    }

    Boolean synchronizableProduct = false;
    Map<Id, ER_ContractLineItem__c> cliMap = getContractLineItems(contractInst.Id);

    for (ER_ContractLineItem__c cli : cliMap.values()) {
      if (!cli.ER_Product2__r.ER_Do_Not_Synchronize__c) {
        synchronizableProduct = true;
      }
    }

    return !synchronizableProduct;
  }

  /*
   * Dragos Avram
   * 03/03/2020
   * getFrameworkContract : get the framework and refferal contract and display in framework contract list LWC.
   */
  @AuraEnabled(cacheable=true)
  public static List<Contract> getFrameworkContract(String accountId) {
    List<Id> parentsId = APER12_Contract_Management.findTopLevelParent(accountId);
    List<Id> partnersAccountId = APER12_Contract_Management.getEligiblePartners(accountId);
    List<Contract> frameworkContract = [
      SELECT
        Id,
        ContractNumber,
        Status,
        ER_Contract_Type__c,
        StartDate,
        Account.Name,
        AccountId,
        (SELECT ER_Contract__c, Name, ER_Solution__c FROM ER_ContractLineItems__r)
      FROM Contract
      WHERE
        (((AccountId IN :parentsId
        OR AccountId = :accountId)
        AND ER_Contract_Type__c = 'Framework agreement')
        OR ((AccountId = :accountId
        OR AccountId IN :partnersAccountId)
        AND ER_Contract_Type__c = 'Referral agreement'))
        AND Status = :System.Label.LABS_SF_Contract_Status_Activated
      ORDER BY CreatedDate DESC
    ];
    return frameworkContract;
  }

  /*
   * Dragos Avram
   * 03/03/2020
   * getEligiblePartners : get the eligible account partners
   */
  public static List<Id> getEligiblePartners(String accountId) {
    List<Id> eligiblePartners = new List<Id>();
    Account accountsWithPartners = [
      SELECT id, (SELECT id, Role, ReversePartnerId, AccountToId FROM PartnersFrom)
      FROM Account
      WHERE Id = :accountId
      LIMIT 1
    ];
    for (Partner partnerObj : accountsWithPartners.PartnersFrom) {
      if (
        partnerObj.Role.equalsIgnoreCase('Trade association') ||
        partnerObj.Role.equalsIgnoreCase('Business partner (Decision maker)') ||
        partnerObj.Role.equalsIgnoreCase('Franchiser') ||
        partnerObj.Role.equalsIgnoreCase('Federation')
      ) {
        eligiblePartners.add(partnerObj.AccountToId);
      }
    }

    return eligiblePartners;
  }
  /*
   * Dragos Avram
   * 03/03/2020
   * findTopLevelParent : itterate through the account Parent=child hierarchy(from bottom to top)
   */
  public static List<Id> findTopLevelParent(String a) {
    Boolean isTopLevelAccount = false;
    account acct = new account();
    List<Id> parentAccount = new List<Id>();
    id currAcctId = a;

    while (!isTopLevelAccount) {
      acct = [SELECT Id, ParentId, ER_Decision_maker__c, Name FROM Account WHERE Id = :currAcctId LIMIT 1];
      if (acct.ParentID != null) {
        currAcctId = acct.ParentID;
        if (acct.ER_Decision_maker__c) {
          parentAccount.add(currAcctId);
        }
      } else {
        isTopLevelAccount = true;
        if (acct.ER_Decision_maker__c) {
          parentAccount.add(currAcctId);
        }
      }
    }
    return parentAccount;
  }
  /**
   * @author ALK
   * @date 06/05/2021
   * @description Enfoce the following name convention {Contract.BU} - {Account.Name} - {Contract.Creation Date } - {sequence 01} - {Original Opportunity Name}
   * @param contracts
   */
  public static void setContractName(List<Contract> contracts) {
    Set<Id> setAccountsIds = new Set<Id>();
    Set<Id> setOpportunityIds = new Set<Id>();
    Map<Id, List<Contract>> mapAccountTempContracts = new Map<Id, List<Contract>>();
    Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>();

    for (Contract c : contracts) {
      setAccountsIds.add(c.AccountId);
      setOpportunityIds.add(c.ER_OpportunityId__c);
      if (!mapAccountTempContracts.containsKey(c.AccountId))
        mapAccountTempContracts.put(c.AccountId, new List<Contract>());
      mapAccountTempContracts.get(c.AccountId).add(c);
    }

    if (!setOpportunityIds.isEmpty())
      mapOpportunity = new Map<Id, Opportunity>(
        [SELECT Id, Name FROM Opportunity WHERE AccountId IN :mapAccountTempContracts.keySet()]
      );

    for (Account a : [
      SELECT
        Id,
        ER_Registration_Number__c,
        Name,
        (SELECT Id, Name, ContractNumber FROM Contracts ORDER BY ContractNumber ASC)
      FROM Account
      WHERE Id IN :setAccountsIds
    ]) {
      if (!a.Contracts.isEmpty()) {
        //Get Max Sequence
        Integer sequence = 0;
        for (Contract c : a.Contracts) {
          Integer currentSequence = (String.isNotBlank(c.Name) &&
            String.valueOf(c.Name.substringAfterLast('-')).isNumeric()
            ? Integer.valueOf(c.Name.substringAfterLast('-'))
            : 0);
          sequence = (sequence < currentSequence ? currentSequence : sequence);
        }

        for (Integer i = 0; i < mapAccountTempContracts.get(a.Id).size(); i++) {
          Contract c = mapAccountTempContracts.get(a.Id)[i];
          String originalOppName = String.isNotBlank(c.ER_OpportunityId__c) &&
            mapOpportunity.containsKey(c.ER_OpportunityId__c)
            ? '-' + Utils.getOriginalNameFromOpportunity(mapOpportunity.get(c.ER_OpportunityId__c).Name)
            : '';
          c.Name =
            c.ER_Business_Unit__c +
            '-' +
            a.Name.left(50) +
            '-' +
            Datetime.now().format('YYYY-MM-dd') +
            '-' +
            (i +
            1 +
            sequence);
        }
      } else {
        for (Integer i = 0; i < mapAccountTempContracts.get(a.Id).size(); i++) {
          Contract c = mapAccountTempContracts.get(a.Id)[i];
          String originalOppName = String.isNotBlank(c.ER_OpportunityId__c) &&
            mapOpportunity.containsKey(c.ER_OpportunityId__c)
            ? '-' + Utils.getOriginalNameFromOpportunity(mapOpportunity.get(c.ER_OpportunityId__c).Name)
            : '';
          c.Name =
            c.ER_Business_Unit__c +
            '-' +
            a.Name.left(50) +
            '-' +
            Datetime.now().format('YYYY-MM-dd') +
            '-' +
            (i + 1);
        }
      }
    }
  }

  /**
   * @author ALK
   * @date 31/05/2021
   * @description Link the new contract to the quote signed (docusign pdf) document.
   * @param newContracts
   */
  public static void linkContractToSignedDocument(Map<id, Contract> newContracts) {
    Map<Id, Contract> mapQuoteContract = new Map<Id, Contract>();
    for (Contract c : [
      SELECT
        Id,
        ER_QuoteId__c,
        ER_QuoteId__r.ER_Is_Docusign_Deployed_BU__c,
        ER_ZuoraQuote__c,
        ER_ZuoraQuote__r.ER_TCs_Signed_Link__c
      FROM Contract
      WHERE Id IN :newContracts.keySet()
    ]) {
      if (c.ER_QuoteId__c != null && c.ER_QuoteId__r.ER_Is_Docusign_Deployed_BU__c) {
        mapQuoteContract.put(c.ER_QuoteId__c, c);
      }
      if (c.ER_ZuoraQuote__c != null && c.ER_ZuoraQuote__r.ER_TCs_Signed_Link__c != null) {
        mapQuoteContract.put(c.ER_ZuoraQuote__c, c);
      }
    }

    if (!mapQuoteContract.isEmpty()) {
      List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
      for (ContentDocumentLink cdl : [
        SELECT
          Id,
          LinkedEntityId,
          ContentDocumentId,
          ShareType,
          Visibility,
          ContentDocument.Title,
          ContentDocument.FileExtension
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :mapQuoteContract.keySet()
      ]) {
        if (cdl.ContentDocument.FileExtension == Constants.PDF) {
          ContentDocumentLink newLink = cdl.clone(false, false, false, false);
          newLink.LinkedEntityId = mapQuoteContract.get(cdl.LinkedEntityId).Id;
          newLinks.add(newLink);
        }
      }

      if (!newLinks.isEmpty())
        Database.insert(newLinks, false);
    }
  }

  /**
   * @AUTHOR AAM
   * @date 02-JUN-2021
   * @description Check if the parent contract is Draft before Deleting contract line Item
   * @param contractLineItemList
   *
   * @return
   */
  public static void checkDraftParent(List<ER_ContractLineItem__c> contractLineItemList) {
    System.debug('###:checkDraftParent Start');

    for (ER_ContractLineItem__c cliInst : contractLineItemList) {
      if (cliInst.ER_Contract_Status__c != Label.LABS_SF_Contract_Status_Draft)
        cliInst.addError(Label.LABS_SF_ER_ContractLineItem_CannotBeDeleted);
    }

    System.debug('###:checkDraftParent End');
  }

  /**
   * @author KHAD
   * @date 02/07/2021
   * @description Update the creation date in ios field for contract line items
   * @param newItems
   * @param oldItems
   */
  public static void syncCLIFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### syncContractLineItems Start');

    Map<Id, ER_ContractLineItem__c> newCLI = (Map<Id, ER_ContractLineItem__c>) newItems;
    Map<Id, ER_ContractLineItem__c> oldCLI = (Map<Id, ER_ContractLineItem__c>) oldItems;

    // Loop through the Account lists and add fill the creation date in OS
    for (ER_ContractLineItem__c cli : newCLI.values()) {
      if (
        cli.ER_Sync_result__c != oldCLI.get(cli.Id).ER_Sync_result__c &&
        (cli.ER_Sync_result__c == 'synchronized' ||
        cli.ER_Sync_result__c == 'pending_synchronization') &&
        cli.ER_Creation_date_in_OS__c == null
      )
        cli.ER_Creation_date_in_OS__c = Datetime.now();
    }

    System.debug('### syncContractLineItems End');
  }

  /**
   * @author AAZ
   * @date 07/07/2021
   * @description Create a subscription after contract activation
   * @param newContracts
   * @param oldContracts
   */
  public static void createZuoraSubscription(Map<Id, Contract> newContracts, Map<Id, Contract> oldContracts) {
    Map<Id, Contract> mapQuoteContract = new Map<Id, Contract>();
    Set<String> bAccounts = new Set<String>();
    List<String> zuoraDeployedBU = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('ZUORA_DEPLOYED_BUs'));
    List<Contract> newItems = new List<Contract>();

    for (Contract c : newContracts.values()) {
      if (zuoraDeployedBU.contains(Constants.ALL) || zuoraDeployedBU.contains(c.ER_BUPicklist__c))
        newItems.add(c);
    }

    if (!newItems.isEmpty()) {
      for (Contract newContr : [
        SELECT
          Id,
          Status,
          ER_ZuoraQuote__c,
          ER_ZuoraQuote__r.zqu__Account__c,
          ER_ZuoraQuote__r.zqu__ZuoraAccountID__c,
          ER_OpportunityId__r.ER_IsAmended__c,
          Subscription__c,
          ER_ZuoraQuote__r.zqu__PaymentTerm__c,
          ER_ZuoraQuote__r.zqu__Zuora_Account_Number__c,
          ER_BUPicklist__c
        FROM Contract
        WHERE ER_ZuoraQuote__c != NULL AND Id IN :newItems
      ]) {
        if (
          newContr.Status != oldContracts.get(newContr.Id).Status &&
          newContr.Status == Constants.ACTIVATED &&
          newContr.ER_ZuoraQuote__r.zqu__Account__c != null &&
          newContr.ER_ZuoraQuote__r.zqu__ZuoraAccountID__c != null
        ) {
          mapQuoteContract.put(newContr.Id, newContr);
          bAccounts.add(newContr.ER_ZuoraQuote__r.zqu__Zuora_Account_Number__c);
        }
      }

      if (!mapQuoteContract.isEmpty())
        System.enqueueJob(new ER_SendQuoteToZuora(mapQuoteContract, bAccounts));
    }
  }

  /**
 * Creates SME Platform Engagement (Opportunity → Quote → Contract)
 * when contract is activated via auto-enrollment with qualifying promo code
 * Created by harkirat
 * @param newMap - New Contract values
 * @param oldMap - Old Contract values
 */
  public static void createSMEPlatformEngagement(Map<Id, Contract> newMap, Map<Id, Contract> oldMap) {
    System.debug('=== CREATE SME PLATFORM ENGAGEMENT - START ===');
    System.debug('Contracts received: ' + newMap.keySet().size());
    // Prevent recursion
    if (processedContractIds == null) {
        processedContractIds = new Set<Id>();
    }
    //1
    Set<Id> contractsToCheck = new Set<Id>();
    for (Id contractId : newMap.keySet()) {
        if (!processedContractIds.contains(contractId)) {
            contractsToCheck.add(contractId);
        }
    }
    
    if (contractsToCheck.isEmpty()) {
        //System.debug('=== ALL CONTRACTS ALREADY PROCESSED - SKIPPING ===');
        return;
    }
    
    //2. Query contracts with all needed details
    Map<Id, Contract> contractsWithDetails = new Map<Id, Contract>([
        SELECT Id, Status, AccountId, Account.Name,
               ER_OpportunityId__c,
               ER_OpportunityId__r.CampaignId,
               ER_OpportunityId__r.Preferred_Language__c,
               ER_OpportunityId__r.ER_Promo_Code2__c,
               ER_OpportunityId__r.ER_Promo_Code2__r.Create_SME_Platform_Engagement__c,
               ER_OpportunityId__r.ER_Promo_Code2__r.ER_Business_Unit__c,
               ER_OpportunityId__r.Name,
               ER_OpportunityId__r.ER_Solutions__c,
               ER_OpportunityId__r.ER_Estimated_Number_Of_Beneficiaries__c,
               ER_OpportunityId__r.OwnerId,
               ER_OpportunityId__r.ER_Won_Reason__c,
               ER_OpportunityId__r.RecordTypeId,
               OwnerId, CreatedBy.Name, StartDate, EndDate, CurrencyIsoCode,
               Primary_Contact__c, Billing_Contact__c, Owner.Name,
               CustomerSignedDate, CustomerSignedId
        FROM Contract
        WHERE Id IN :contractsToCheck
    ]);

    for (Contract c : contractsWithDetails.values()) {
    }

    //3: Check for existing SME contracts (prevents duplicates across transactions)
    Set<Id> contractsWithExistingSME = new Set<Id>();
    List<Contract> existingSMEContracts = [
        SELECT Id, ER_Original_Agreement__c
        FROM Contract
        WHERE ER_Original_Agreement__c IN :contractsToCheck
        AND ER_Original_Agreement__c != null
        LIMIT 5
    ];
    
    for (Contract smeContract : existingSMEContracts) {
        contractsWithExistingSME.add(smeContract.ER_Original_Agreement__c);
    }

    //4: Get all unique AccountIds to check for existing Engagement contracts
    Set<Id> accountIds = new Set<Id>();
    for (Contract c : contractsWithDetails.values()) {
        if (c.AccountId != null) {
            accountIds.add(c.AccountId);
        }
    }
    
    //5: Query to check if any account already has an Engagement contract
    Map<Id, Boolean> accountHasEngagement = new Map<Id, Boolean>();
    for (Id accId : accountIds) {
        accountHasEngagement.put(accId, false); // Default to false
    }

    // Check for existing Engagement contracts on these accounts
    for (Contract existingContract : [
        SELECT Id, AccountId, Contract_Category__c
        FROM Contract
        WHERE AccountId IN :accountIds
        AND Contract_Category__c = 'Engagement'
        AND Status = 'Activated'
        LIMIT 1
    ]) {
        accountHasEngagement.put(existingContract.AccountId, true);
    }
    
    List<Id> qualifyingContractIds = new List<Id>();
    
    //6: Filter qualifying contracts
    for (Id contractId : contractsToCheck) {
        Contract contractWithDetails = contractsWithDetails.get(contractId);
        if (contractWithDetails == null) continue;

        if (contractsWithExistingSME.contains(contractId)) {
            continue;
        }

        Contract oldContract = oldMap.get(contractId);
        Boolean isNewlyActivated = (contractWithDetails.Status == 'Activated' && 
                                   oldContract != null && 
                                   oldContract.Status != 'Activated');
        
        //Boolean isActivated = false;
        /*if (oldMap == null || oldMap.isEmpty()) {
            isActivated = (contractWithDetails.Status == 'Activated');
        } else {
            Contract oldContract = oldMap.get(contractId);
            isActivated = (contractWithDetails.Status == 'Activated' && 
                          oldContract != null && oldContract.Status != 'Activated');
        }*/
        /*if (oldMap != null && !oldMap.isEmpty()) {
            Contract oldContract = oldMap.get(contractId);
            isActivated = (contractWithDetails.Status == 'Activated' && 
                          oldContract != null && 
                          oldContract.Status != 'Activated');
            
            if (!isActivated) {
                System.debug('SKIPPED: Contract not newly activated (Old: ' + 
                           (oldContract != null ? oldContract.Status : 'null') + 
                           ', New: ' + contractWithDetails.Status + ') - ' + contractId);
            }
        } else {
            isActivated = (contractWithDetails.Status == 'Activated');
            
            if (!isActivated) {
                System.debug('SKIPPED: Contract not activated (Status: ' + 
                           contractWithDetails.Status + ') - ' + contractId);
            }
        }*/
        if (!isNewlyActivated) {
            continue;
        }
        
        Boolean hasOpportunity = contractWithDetails.ER_OpportunityId__c != null;
        if (!hasOpportunity) {
            continue;
        }
        Boolean hasPromoCode = contractWithDetails.ER_OpportunityId__r.ER_Promo_Code2__c != null;
        if (!hasPromoCode) {
            continue;
        }
        Boolean shouldCreateEngagement = contractWithDetails.ER_OpportunityId__r.ER_Promo_Code2__r.Create_SME_Platform_Engagement__c == true;
        if (!shouldCreateEngagement) {
            continue;
        }

        // Check if Created by name contains "Guest" (case-insensitive)
        Boolean createdByGuest = false;
        if (contractWithDetails.CreatedBy != null && contractWithDetails.CreatedBy.Name != null) {
            createdByGuest = contractWithDetails.CreatedBy.Name.containsIgnoreCase('Guest');
        }
        if (!createdByGuest) {
            continue;
        }

        // Check if account already has an Engagement contract
        Boolean accountAlreadyHasEngagement = accountHasEngagement.get(contractWithDetails.AccountId) == true;
        if (accountAlreadyHasEngagement) {
            continue;
        }

        // Add both new conditions to the qualification check
        if (isNewlyActivated && hasOpportunity && hasPromoCode && shouldCreateEngagement 
            && createdByGuest && !accountAlreadyHasEngagement) {
            qualifyingContractIds.add(contractId);
            processedContractIds.add(contractId);
        } else {
            if (!createdByGuest) {
            }
            if (accountAlreadyHasEngagement) {
            }
        }
    }

        
        /*if (isActivated && hasOpportunity && hasPromoCode && shouldCreateEngagement) {
            qualifyingContractIds.add(contractId);
            processedContractIds.add(contractId);
        }
    }*/
    
    /*if (qualifyingContractIds.isEmpty()) {
        System.debug('=== NO QUALIFYING CONTRACTS - EXITING ===');
        return;
    }*/
    if (!qualifyingContractIds.isEmpty()) {
        
        try {
            // Create platform event
            SME_Engagement_Request__e event = new SME_Engagement_Request__e();
            event.Contract_Ids__c = String.join(new List<Id>(qualifyingContractIds), ',');
            
            // Publish event
            Database.SaveResult result = EventBus.publish(event);
            
            if (result.isSuccess()) {
            } else {
                for (Database.Error error : result.getErrors()) {
                }
            }
        } catch (Exception e) {
        }
    } else {
    }

    
    //ENQUEUE QUEUEABLE INSTEAD OF CALLING SYNC METHOD
    /*if (!System.isQueueable() && !System.isBatch()) {
        System.enqueueJob(new SMEPlatformEngagementQueueable(qualifyingContractIds));
        System.debug('Enqueued SME Platform creation for ' + qualifyingContractIds.size() + ' contracts');
    } else {
        System.debug('Already in async context - cannot enqueue');
    }*/
  }


/**
 * Sync method to create SME Platform engagement records
 * Bulkified to handle multiple contracts efficiently
 * Created by: Harkirat
 */
public static List<Id> createSMEPlatformEngagementSync(List<Id> contractIds, Map<Id, Contract> contractsWithDetails) {    
    try {
        // Build list of contracts from the map
        List<Contract> contracts = new List<Contract>();
        for (Id contractId : contractIds) {
            Contract c = contractsWithDetails.get(contractId);
            if (c != null) {
                contracts.add(c);
            }
        }
        
        if (contracts.isEmpty()) {
            return new List<Id>();
        }
        
        // Get Business Unit (assuming all contracts have same BU for this batch)
        String businessUnit = contracts[0].ER_OpportunityId__r.ER_Promo_Code2__r.ER_Business_Unit__c;
        
        // ========== QUERY ALL REQUIRED DATA UPFRONT ==========

        //Additional query
        Account mainPlatformAccount = getMainPlatformAccount(businessUnit);
        if (mainPlatformAccount == null) {
            return new List<Id>();
        }

        // Get the Main Platform Contract details
        Contract mainPlatformContract = null;
        if (mainPlatformAccount.Contracts != null && !mainPlatformAccount.Contracts.isEmpty()) {
            mainPlatformContract = mainPlatformAccount.Contracts[0];
        } else {
            return new List<Id>();
        }
        
        // QUERY 1: Get Engagement Pricebook
        Id engagementPricebookId = getEngagementPricebookId(businessUnit);
        if (engagementPricebookId == null) {
            return new List<Id>();
        }
        
        // QUERY 2: Get SME Platform Products
        List<Product2> smePlatformProducts = getSMEPlatformProducts(businessUnit);
        if (smePlatformProducts.isEmpty()) {
            return new List<Id>();
        }

        //Build Solutions string from ProductCodes
        Set<String> solutionSet = new Set<String>();
        for (Product2 product : smePlatformProducts) {
            if (product.ER_Solution2__r != null && String.isNotBlank(product.ER_Solution2__r.ProductCode)) {
                solutionSet.add(product.ER_Solution2__r.ProductCode);
            }
        }
        String solutionsValue = String.join(new List<String>(solutionSet), '/');
        
        // QUERY 3: Get PricebookEntries for all products (BULKIFIED)
        Map<Id, PricebookEntry> productToPbeMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id, UnitPrice, ER_Percentage__c
            FROM PricebookEntry
            WHERE Product2Id IN :smePlatformProducts
            AND Pricebook2Id = :engagementPricebookId
            AND IsActive = true
        ]) {
            productToPbeMap.put(pbe.Product2Id, pbe);
        }

        // QUERY 4: Get ONLY Primary Contact and Invoicing Contact OCRs (OPTIMIZED)
        Set<Id> primaryOppIds = new Set<Id>();
        for (Contract c : contracts) {
            if (c.ER_OpportunityId__c != null) {
                primaryOppIds.add(c.ER_OpportunityId__c);
            }
        }

        Map<Id, List<OpportunityContactRole>> primaryOppToOCRs = new Map<Id, List<OpportunityContactRole>>();
        if (!primaryOppIds.isEmpty()) {
            for (OpportunityContactRole ocr : [
                SELECT Id, OpportunityId, ContactId, Role, IsPrimary
                FROM OpportunityContactRole
                WHERE OpportunityId IN :primaryOppIds
                AND Role IN ('Primary Contact', 'Invoicing Contact') 
            ]) {
                if (!primaryOppToOCRs.containsKey(ocr.OpportunityId)) {
                    primaryOppToOCRs.put(ocr.OpportunityId, new List<OpportunityContactRole>());
                }
                primaryOppToOCRs.get(ocr.OpportunityId).add(ocr);
            }
        }
        
        // Get RecordType IDs once (no SOQL - uses describe)
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('ER_Client_Opportunity_RT')?.getRecordTypeId();
        Id quoteRecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
            .get('ER_Client_Quote')?.getRecordTypeId();
        Id contractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
            .get('ER_Client_Contract_RT')?.getRecordTypeId();
        
        // STEP 1 CREATE OPPORTUNITIES 
        List<Opportunity> newOpportunities = new List<Opportunity>();
        
        for (Contract primaryContract : contracts) {
            Opportunity smeOpp = new Opportunity();
            smeOpp.Name = 'SME Platform - ' + primaryContract.Account.Name;
            //adding sme account instead of the 
            smeOpp.AccountId = primaryContract.AccountId;
            smeOpp.StageName = 'Qualification';
            smeOpp.ER_Won_Reason__c = primaryContract.ER_OpportunityId__r.ER_Won_Reason__c;
            smeOpp.CloseDate = Date.today().addDays(30);
            smeOpp.RecordTypeId = primaryContract.ER_OpportunityId__r.RecordTypeId;
            smeOpp.OwnerId = primaryContract.OwnerId;
            smeOpp.Pricebook2Id = engagementPricebookId;
            smeOpp.CampaignId = primaryContract.ER_OpportunityId__r.CampaignId;
            smeOpp.ER_Promo_Code2__c = primaryContract.ER_OpportunityId__r.ER_Promo_Code2__c;
            smeOpp.LeadSource = 'Websales';
            smeOpp.ER_Lead_sub_source__c = 'Econtratonline';
            smeOpp.ER_Solutions__c = solutionsValue;
            smeOpp.Preferred_Language__c = primaryContract.ER_OpportunityId__r.Preferred_Language__c;
            smeOpp.ER_Estimated_Number_Of_Beneficiaries__c = primaryContract.ER_OpportunityId__r.ER_Estimated_Number_Of_Beneficiaries__c;
            smeOpp.ER_Contract_Expected_Start_Date__c = primaryContract.StartDate;
            smeOpp.Contract_End_Date__c = primaryContract.EndDate;
            smeOpp.Type = 'Operational';
            smeOpp.Commercial_Origin__c = 'Greenfield';
            smeOpp.ER_Reason__c = 'New';      
            smeOpp.Onboarding_Method__c = 'OSS';
            //smeOpp.Impacted_Beneficiaries__c = 'TRE Only';
            smeOpp.ER_InvoicingFrequency__c = 'Yearly';  
            smeOpp.Start_Date__c = primaryContract.StartDate;
            smeOpp.Auto_Enrolment_Opportunity__c = true;
            smeOpp.ER_BUPicklist__c = businessUnit;
            smeOpp.ER_Original_Agreement__c = primaryContract.Id;

            // NEW: Set Main Platform Account
            smeOpp.Main_Platform__c = mainPlatformAccount.Id;
            
            // NEW: Set fields from Main Platform Contract
            smeOpp.Program_Name__c = mainPlatformContract.ER_Program_Name__c;
            //smeOpp.ER_Start_Date__c = mainPlatformContract.ER_Start_Date__c;
            smeOpp.Impacted_Beneficiaries__c = mainPlatformContract.ER_Impacted_Beneficiaries__c;
            
            // NEW: Set Customer Domain Reference from Main Platform Account
            smeOpp.Customer_Domain_Reference__c = mainPlatformAccount.Customer_Domain_Reference__c;
            
            
            newOpportunities.add(smeOpp);
        }
        
        insert newOpportunities;
        //System.debug(' Created ' + newOpportunities.size() + ' opportunities');
        
        // STEP 2 CREATE OPPORTUNITY CONTACT ROLES 
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        
        for (Integer i = 0; i < contracts.size(); i++) {
            Contract primaryContract = contracts[i];
            Opportunity smeOpp = newOpportunities[i];
            
            List<OpportunityContactRole> primaryOCRs = primaryOppToOCRs.get(primaryContract.ER_OpportunityId__c);
            
            if (primaryOCRs != null && !primaryOCRs.isEmpty()) {
                // Copy OCRs from primary opportunity
                for (OpportunityContactRole primaryOCR : primaryOCRs) {
                    OpportunityContactRole newOCR = new OpportunityContactRole();
                    newOCR.OpportunityId = smeOpp.Id;
                    newOCR.ContactId = primaryOCR.ContactId;
                    newOCR.Role = primaryOCR.Role;
                    newOCR.IsPrimary = primaryOCR.IsPrimary;
                    ocrList.add(newOCR);
                }
            } else {
                // Fallback: Create from contract fields
                if (primaryContract.Primary_Contact__c != null) {
                    ocrList.add(new OpportunityContactRole(
                        OpportunityId = smeOpp.Id,
                        ContactId = primaryContract.Primary_Contact__c,
                        Role = 'Primary Contact',
                        IsPrimary = true
                    ));
                }
                
                if (primaryContract.Billing_Contact__c != null && 
                    primaryContract.Billing_Contact__c != primaryContract.Primary_Contact__c) {
                    ocrList.add(new OpportunityContactRole(
                        OpportunityId = smeOpp.Id,
                        ContactId = primaryContract.Billing_Contact__c,
                        Role = 'Invoicing Contact',
                        IsPrimary = false
                    ));
                }
            }
        }
        
        if (!ocrList.isEmpty()) {
            insert ocrList;
        }
        
        // STEP 3 CREATE OPPORTUNITY LINE ITEMS 
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
        for (Opportunity smeOpp : newOpportunities) {
          for (Product2 product : smePlatformProducts) {
              PricebookEntry pbe = productToPbeMap.get(product.Id);
              
              if (pbe != null) {
                  OpportunityLineItem oli = new OpportunityLineItem();
                  oli.OpportunityId = smeOpp.Id;
                  oli.Product2Id = product.Id;      
                  oli.PricebookEntryId = pbe.Id;
                  
                  // Check if it's ONLY "License Fees" (not Implementation License Fees)
                  Boolean isLicenseFees = product.ER_Solution__r != null && 
                                        product.ER_Solution__r.Name != null && 
                                        product.ER_Solution__r.Name.containsIgnoreCase('License Fees') &&
                                        !product.ER_Solution__r.Name.containsIgnoreCase('Freemium');   
                  if (isLicenseFees) {
                      oli.Quantity = smeOpp.ER_Estimated_Number_Of_Beneficiaries__c != null ? 
                                    smeOpp.ER_Estimated_Number_Of_Beneficiaries__c : 1;
                      oli.ER_Nb_Beneficiaries__c = smeOpp.ER_Estimated_Number_Of_Beneficiaries__c;
                  } else {
                      oli.Quantity = 1;
                  }
                  
                  oli.UnitPrice = 0;
                  oli.ER_Percentage__c = pbe.ER_Percentage__c;
                  oli.ER_BUPicklist__c = businessUnit;
                  
                  oliList.add(oli);
              } else {
                  //System.debug('No PricebookEntry found for product: ' + product.Name);
              }
          }
      }  
        if (!oliList.isEmpty()) {
            insert oliList;
            //System.debug('Created ' + oliList.size() + ' Opportunity Line Items');
        } else {
            //System.debug('No Opportunity Line Items to create');
        }
        
        // ========== STEP 4: CREATE QUOTES ==========
        List<Quote> quotes = new List<Quote>();
        
        for (Integer i = 0; i < newOpportunities.size(); i++) {
            Opportunity smeOpp = newOpportunities[i];
            Contract primaryContract = contracts[i];
            
            Quote newQuote = new Quote();
            newQuote.Name = 'SME Platform Quote - ' + primaryContract.Account.Name;
            newQuote.OpportunityId = smeOpp.Id;
            newQuote.Pricebook2Id = engagementPricebookId;
            newQuote.ContactId = primaryContract.Primary_Contact__c;
            newQuote.Status = 'Accepted';
            newQuote.ExpirationDate = Date.today().addMonths(1);
            newQuote.ER_Quote_Type__c = 'Operational';
            newQuote.ER_BUPicklist__c = businessUnit;
            newQuote.RecordTypeId = quoteRecordTypeId;
            
            quotes.add(newQuote);
        }
        
        insert quotes;
        //System.debug('Created ' + quotes.size() + ' quotes');
        
        // STEP 5 CREATE QUOTE LINE ITEMS (BULKIFIED) 
        
        // QUERY 5: Get all OLIs for the new opportunities (BULKIFIED)
        Set<Id> oppIds = new Set<Id>();
        for (Quote q : quotes) {
            oppIds.add(q.OpportunityId);
        }
        
        Map<Id, List<OpportunityLineItem>> oppToOLIs = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT Id, OpportunityId, Product2Id, PricebookEntryId, Quantity, UnitPrice, ER_Percentage__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ]) {
            if (!oppToOLIs.containsKey(oli.OpportunityId)) {
                oppToOLIs.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oppToOLIs.get(oli.OpportunityId).add(oli);
        }
        
        //Create Quote line items
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        
        for (Quote quote : quotes) {
            List<OpportunityLineItem> relatedOlis = oppToOLIs.get(quote.OpportunityId);
            
            if (relatedOlis != null) {
                for (OpportunityLineItem oli : relatedOlis) {
                    QuoteLineItem qli = new QuoteLineItem();
                    qli.QuoteId = quote.Id;
                    qli.Opportunity_Product__c = oli.Id;
                    //qli.Parent_Product__c = oli.Parent_Product__c;
                    qli.Product2Id = oli.Product2Id;
                    qli.PricebookEntryId = oli.PricebookEntryId;
                    qli.Quantity = oli.Quantity;
                    qli.UnitPrice = oli.UnitPrice;
                    qli.ER_Percentage__c = oli.ER_Percentage__c;
                    qli.OpportunityLineItemId = oli.Id;
                    
                    qliList.add(qli);
                }
            }
        }
        
        if (!qliList.isEmpty()) {
            insert qliList;
        }
        
        // STEP 6: UPDATE OPPORTUNITIES TO PROPOSAL STAGE 
        for (Opportunity opp : newOpportunities) {
            opp.StageName = 'Proposal';
        }
        update newOpportunities;
        //System.debug('Updated ' + newOpportunities.size() + ' opportunities to Proposal stage');
        
        // STEP 7: CREATE CONTRACTS 
        List<Contract> smeContracts = new List<Contract>();
        
        for (Integer i = 0; i < quotes.size(); i++) {
            Quote quote = quotes[i];
            Contract primaryContract = contracts[i];
            
            Contract smeContract = new Contract();
            smeContract.AccountId = primaryContract.AccountId;
            smeContract.ER_QuoteId__c = quote.Id;
            smeContract.ER_OpportunityId__c = quote.OpportunityId;
            smeContract.Pricebook2Id = quote.Pricebook2Id;
            smeContract.StartDate = primaryContract.StartDate;
            smeContract.EndDate = primaryContract.EndDate;
            smeContract.Status = 'Draft';
            smeContract.ER_Solutions__c = solutionsValue;
            //smeContract.ER_Solutions__c = 'Draft';
            smeContract.ER_Contract_Type__c = 'Operational';
            smeContract.Primary_Contact__c = primaryContract.Primary_Contact__c;
            smeContract.Billing_Contact__c = primaryContract.Billing_Contact__c;
            smeContract.ER_Original_Agreement__c = primaryContract.Id;
            smeContract.ER_BUPicklist__c = businessUnit;
            smeContract.ER_Start_Date__c = primaryContract.StartDate;
            smeContract.CustomerSignedDate = primaryContract.CustomerSignedDate;
            smeContract.CustomerSignedId = primaryContract.CustomerSignedId;
            smeContract.RecordTypeId = contractRecordTypeId;
            // NEW: Set Main Platform Account
            smeContract.Main_Platform__c = mainPlatformAccount.Id;
            
            // NEW: Set fields from Main Platform Contract
            smeContract.ER_Program_Name__c = mainPlatformContract.ER_Program_Name__c;
            //smeContract.ER_Start_Date__c = mainPlatformContract.ER_Start_Date__c;
            smeContract.ER_Impacted_Beneficiaries__c = mainPlatformContract.ER_Impacted_Beneficiaries__c;
            
            // NEW: Set Customer Domain Reference from Main Platform Account
            smeContract.Customer_Domain_Reference__c = mainPlatformAccount.Customer_Domain_Reference__c;
            
            smeContracts.add(smeContract);
        }
        
        insert smeContracts;
        
        // QUERY 6: Get all QLIs for the quotes (BULKIFIED)
        Set<Id> quoteIds = new Set<Id>();
        for (Quote q : quotes) {
            quoteIds.add(q.Id);
        }
        
        Map<Id, List<QuoteLineItem>> quoteToQLIs = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem qli : [
            SELECT Id, QuoteId, Product2Id, Product2.Name, PricebookEntryId, Quantity, 
                   UnitPrice, ER_Percentage__c, ListPrice, CurrencyIsoCode, Opportunity_Product__c
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ]) {
            if (!quoteToQLIs.containsKey(qli.QuoteId)) {
                quoteToQLIs.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteToQLIs.get(qli.QuoteId).add(qli);
        }

        //Create Contract Line Items
        List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
        
        for (Integer i = 0; i < smeContracts.size(); i++) {
            Contract smeContract = smeContracts[i];
            Quote quote = quotes[i];
            
            List<QuoteLineItem> relatedQlis = quoteToQLIs.get(quote.Id);
            
            if (relatedQlis != null) {
                for (QuoteLineItem qli : relatedQlis) {
                    ER_ContractLineItem__c cli = new ER_ContractLineItem__c();
                    cli.ER_Contract__c = smeContract.Id;
                    cli.ER_Product2__c = qli.Product2Id;
                    cli.Opportunity_Product__c = qli.Opportunity_Product__c;
                    //cli.Parent_Product__c = qli.Parent_Product__c;
                    cli.Name = qli.Product2.Name;
                    cli.ER_PricebookEntryId__c = qli.PricebookEntryId;
                    cli.ER_Quantity__c = qli.Quantity;
                    cli.ER_UnitPrice__c = qli.UnitPrice;
                    cli.ER_Percentage__c = qli.ER_Percentage__c;
                    cli.ER_ListPrice__c = qli.ListPrice;
                    cli.CurrencyIsoCode = qli.CurrencyIsoCode;
                    cli.ER_IsActive__c = true;
                    cli.ER_BUPicklist__c = businessUnit;
                    
                    cliList.add(cli);
                }
            }
        }
        
        if (!cliList.isEmpty()) {
            insert cliList;
            //System.debug('Created ' + cliList.size() + ' Contract Line Items');
        }

        //  STEP 9: QUEUE OPPORTUNITY & QUOTE UPDATES
            List<Id> smeContractIds = new List<Id>();
            for (Contract c : smeContracts) {
                smeContractIds.add(c.Id);
            }
            return smeContractIds;
            
        } catch (Exception e) {
        System.debug('ERROR in createSMEPlatformEngagementSync');
        System.debug('Error Message: ' + e.getMessage());
        throw e;
      }
    }

/**
 * Helper method to get Engagement Pricebook ID
 * Created by harkirat
 * @param businessUnit - BE or LU
 * @return Pricebook2 Id or null if not found
 */
@TestVisible
public static Id getEngagementPricebookId(String businessUnit) {
    
    List<Pricebook2> pricebooks = [
        SELECT Id, Name
        FROM Pricebook2
        WHERE Name LIKE '%engagement%'
        AND IsActive = TRUE
        AND (ER_BUPicklist__c = :businessUnit OR ER_BUPicklist__c = null)
        ORDER BY Name
        LIMIT 1
    ];
    
    return pricebooks.isEmpty() ? null : pricebooks[0].Id;
}

// NEW HELPER METHOD: Get Main Platform Account with Contract
    private static Account getMainPlatformAccount(String businessUnit) {
        List<Account> accounts = [
            SELECT Id, Name, Customer_Domain_Reference__c,
                  (SELECT Id, ER_Program_Name__c, ER_Impacted_Beneficiaries__c, ER_Start_Date__c
                    FROM Contracts 
                    WHERE ER_BUPicklist__c = :businessUnit
                    LIMIT 1)
            FROM Account
            WHERE Main_Platform__c = true
            AND ER_BUPicklist__c = :businessUnit
            LIMIT 1
        ];
        
        return accounts.isEmpty() ? null : accounts[0];
    }

/**
 * Helper method to get SME Platform products based on business unit
 * Fetches products with 'wellbeing' or 'Freemium' in name from engagement pricebook
 * Created by harkirat
 * @param businessUnit - BE or LU
 * @return List of Product2 records for SME Platform
 */

@TestVisible
public static List<Product2> getSMEPlatformProducts(String businessUnit) {
    return [
        SELECT Id, Name, ProductCode, ER_Type__c, ER_BUPicklist__c, ER_Line_Order__c, ER_Solution2__c, ER_Solution2__r.ProductCode, ER_Solution2__r.Name, ER_Solution__r.Name
        FROM Product2
        WHERE IsActive = true
        AND ER_BUPicklist__c = :businessUnit
        AND For_SME_Platform__c = true
        AND Id IN (
            SELECT Product2Id
            FROM PricebookEntry
            WHERE IsActive = true
            AND Pricebook2.IsActive = true
            AND Pricebook2.Name LIKE '%engagement%'
        )
        ORDER BY ER_Line_Order__c NULLS LAST, Name
    ];
}

  /**
   * @author VJOY
   * @date 02/09/2021
   * @description Activate Account if Contract has been activated
   * @param newContracts
   * @param oldContracts
   */
  public static void activateAccount(Map<Id, Contract> newContracts, Map<Id, Contract> oldContracts) {
    Set<Id> accounts = new Set<Id>();
    List<Account> accountsToBeUpdated = new List<Account>();

    for (Contract c : newContracts.values()) {
      if (c.Status == Label.LABS_SF_Contract_Status_Activated && c.Status != oldContracts.get(c.Id).Status) {
        accounts.add(c.AccountId);
      }
    }

    if (!accounts.isEmpty()) {
      for (Account a : [
        SELECT Id, ER_Status__c
        FROM Account
        WHERE Id IN :accounts AND ER_Status__c != :Label.LABS_SF_Account_Status_Active
      ]) {
        a.ER_Status__c = Label.LABS_SF_Account_Status_Active;
        accountsToBeUpdated.add(a);
      }

      if (!accountsToBeUpdated.isEmpty())
        Database.update(accountsToBeUpdated, false);
    }
  }
  /**
   * @author Noor
   * @date 24/03/2023
   * @description Sync Account to Smarter when contract is activated
   * @param newContracts updated contract
   * @param oldContracts old contract
   */
  public static void syncAccountToSmarter(Map<Id, Contract> newContracts, Map<Id, Contract> oldContracts) {
    Set<Id> accountSet = new Set<Id>();
    for (Contract c : newContracts.values()) {
      if (c.Status == Label.LABS_SF_Contract_Status_Activated && c.Status != oldContracts.get(c.Id).Status)
        accountSet.add(c.AccountId);
    }
    if (!accountSet.isEmpty())
      APER20_Account_Management.runSyncClientToSmarter(accountSet);
  }

  /**
 * @author HARKIRAT
 * @date 20/01/2026
 * @description Sync Contract to NEMO when payment / delivery / crediting fields change
 */
public static void syncContractToNemo(
    Map<Id, Contract> newContracts,
    Map<Id, Contract> oldContracts
) {
    System.debug('### syncContractToNemo CALLED');  
    if (newContracts == null || oldContracts == null) {
        return;
    }

    Set<Id> contractsToSync = new Set<Id>();

    for (Contract newCon : newContracts.values()) {
        Contract oldCon = oldContracts.get(newCon.Id);
        if (oldCon == null) continue;
        System.debug(
            '### LOOP ' + newCon.Id +
            ' | Pending=' + newCon.NEMO_Sync_Pending__c +
            ' | NewStatus=' + newCon.Approval_Status__c +
            ' | OldStatus=' + oldCon.Approval_Status__c
        );

        Boolean paymentMethodChanged =
            newCon.ER_PaymentMethod2__c != oldCon.ER_PaymentMethod2__c;

        Boolean paymentTermsChanged =
            newCon.ER_PaymentTerms2__c != oldCon.ER_PaymentTerms2__c;

        Boolean deliveryTypeChanged =
            newCon.ER_Delivery_Type__c != oldCon.ER_Delivery_Type__c;

        Boolean creditingChanged =
            newCon.Creditting__c != oldCon.Creditting__c;

        // RULE 1: Immediate sync fields
        if (deliveryTypeChanged || creditingChanged) {
            contractsToSync.add(newCon.Id);
            continue;
        }

        // RULE 2: Approval-dependent fields
        if (
            newCon.NEMO_Sync_Pending__c == true &&
            newCon.Approval_Status__c == 'Approved' &&
            oldCon.Approval_Status__c != 'Approved'
        ) {
            contractsToSync.add(newCon.Id);
            System.debug('### Approval sync for ' + newCon.Id);
        }
    }
     System.debug('### contractsToSync size = ' + contractsToSync.size());

    if (!contractsToSync.isEmpty()) {
        System.enqueueJob(new ContractNemoSyncQueueable(contractsToSync));
        System.debug('### contractsToSync size2 = ' + contractsToSync.size());
    }

}


  /**
   * @author AAZ
   * @date 12/07/2021
   * @description end a subscription after contract termination
   * @param newContracts
   * @param oldContracts
   */
  public static void endZuoraSubscription(Map<Id, Contract> newContracts, Map<Id, Contract> oldContracts) {
    List<Zuora__Subscription__c> listSubsToUpdate = new List<Zuora__Subscription__c>();

    for (Contract newContr : [
      SELECT Id, Status, Subscription__c, EndDate, ER_TerminationReason__c, (SELECT Id FROM Subscriptions__r)
      FROM Contract
      WHERE Subscription__c != NULL AND Id IN :newContracts.keySet()
    ]) {
      Contract oldContr = oldContracts.get(newContr.Id);

      if (newContr.Status != oldContr.Status && newContr.Status == 'Terminated') {
        listSubsToUpdate.add(
          new Zuora__Subscription__c(
            Id = newContr.Subscription__c,
            Zuora__SubscriptionEndDate__c = newContr.EndDate.addDays(1)
          )
        );

        for (Zuora__Subscription__c childSub : newContr.Subscriptions__r) {
          listSubsToUpdate.add(
            new Zuora__Subscription__c(Id = childSub.Id, Zuora__SubscriptionEndDate__c = newContr.EndDate.addDays(1))
          );
        }
      }
    }

    if (!listSubsToUpdate.isEmpty())
      Database.update(listSubsToUpdate, false);
  }

  /**
   * @author ELAK
   * @date 25/03/2022
   * @description Contract Trigger Framework
   * @param contractMap
   */
  public static void processContractBeforeDelete(Map<Id, Contract> contractMap) {
    for (Contract contractInst : contractMap.values()) {
      if (contractInst.Status != Constants.DRAFT) {
        contractInst.addError(Label.LABS_SF_Contract_CannotBeDeleted);
      }
    }
    deleteCLIFromContract(contractMap);
    deleteSLIFromContract(contractMap); // delete Solution line items
  }

  /**
   * @author ALK
   * @date 28/03/2022
   * @description Contract Trigger Framework rework
   * @param newItems
   * @param oldItems
   */
  public static void createTasksAfterUpdate(Map<Id, Contract> newItems, Map<Id, Contract> oldItems) {
    List<Task> taskList = new List<Task>();
    Set<Id> quoteIds = new Set<Id>();
    List<String> excludedBUs = Utils.getGlobalSettingsValueFromKey(Constants.CREATE_TASK_FOR_CONTRACT_EXCLUDED_BUS)
      ?.split(Constants.SEMICOLON);
    Id ContractMerchantRT = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_MERCHANT_RT);

    for (Contract c : newItems.values()) {
      if (
        c.RecordTypeId == ContractMerchantRT &&
        c.Status != oldItems.get(c.Id)?.Status &&
        c.Status == Constants.ACTIVATED &&
        UserInfo.getUserType() != Constants.AUTOMATED_PROCESS &&
        excludedBUs != null &&
        (!excludedBUs.contains(c.ER_BUPicklist__c) && !excludedBUs.contains(Constants.ALL))
      ) {
        quoteIds.add(c.ER_QuoteId__c);
      }
    }

    if (!quoteIds.isEmpty()) {
      for (Quote q : [
        SELECT Id, ContractId, Account.Name, Status, ER_BUPicklist__c, ContactId, Contract.CreatedById
        FROM Quote
        WHERE Id IN :quoteIds AND ContactId != NULL
      ]) {
        String subject = Label.LABS_SF_Task_Subject_WelcomeLetter + ' ' + q.Account.Name;
        taskList.add(
          APER09_Task_Management.CreateTaskForContractWithoutInsert(
            subject,
            q.Contract.CreatedById,
            Date.today() + 1,
            q.ContractId,
            q.ContactId
          )
        );

        if (!taskList.isEmpty())
          Database.insert(taskList, false);
      }
    }
  }

  /**
   * @author AAZ
   * @date 29/08/2022
   * @description Activate Smarter Contract: if the created contract is linked to smartER Opportunity and the opportunity has been created by an ER Integration profile
   * @param newContracts
   */
  public static void activateContract(List<Contract> newContracts) {
    List<Contract> smarterContracts = new List<Contract>();
    Set<String> ranges = new Set<String>{
      '1-2',
      '3-5',
      '6-9',
      '10-19',
      '20-49',
      '50-99',
      '1 - 2',
      '3 - 5',
      '6 - 9',
      '10 - 19',
      '20 - 49',
      '50 - 99',
      '1 -2',
      '3 -5',
      '6 -9',
      '10 -19',
      '20 -49',
      '50 -99',
      '1- 2',
      '3- 5',
      '6- 9',
      '10- 19',
      '20- 49',
      '50- 99'
    };
    Map<Id, Contract> mapContracts = new Map<Id, Contract>(newContracts);
    Map<Id, Contract> contracts = new Map<Id, Contract>(
      APER12_Contract_Management.getContract(new List<Id>(mapContracts.keySet()))
    );

    for (Contract c : newContracts) {
      if (c.ER_SmartER_Context__c == true && c.ER_BUPicklist__c == Constants.FR)
        smarterContracts.add(c);
    }

    if (!smarterContracts.isEmpty()) {
      for (Contract c : [
        SELECT Id
        FROM Contract
        WHERE
          Id IN :smarterContracts
          AND ER_SmartER_Context__c = TRUE
          AND Status = :Constants.CONTRACT_STATUS_DRAFT
          AND (ER_ZuoraQuote__r.CreatedBy.Profile.Name = :Constants.PROFILE_ER_INTEGRATION
          OR (ER_BUPicklist__c = 'FR'
          AND Account.ER_Employee_Size_Range__c IN :ranges))
      ]) {
        APER12_Contract_Management.activateContractController(
          contracts.get(c.Id),
          contracts.get(c.Id).ER_OpportunityId__c,
          true
        );
      }
    }
  }

  /**
   * @author CWA
   * @date 22/09/2022
   * @description Contract Task Creation
   */
  public static void contractTaskCreation(List<Contract> newContracts) {
    List<Task> taskList = new List<Task>();
    List<Contract> newItems = new List<Contract>();

    for (Contract c : newContracts) {
      if (!c.ER_SmartER_Context__c)
        newItems.add(c);
    }

    if (!newItems.isEmpty()) {
      for (Contract c : [
        SELECT
          Id,
          ER_OpportunityId__r.OwnerId,
          ER_OpportunityId__r.LeadSource,
          ER_OpportunityId__r.TECH_IsWeboffer__c,
          ER_OpportunityId__r.Description,
          Status
        FROM Contract
        WHERE Id IN :newItems AND ER_SmartER_Context__c = FALSE
      ]) {
        if (
          c.ER_OpportunityId__c != null &&
          c.Status == Constants.DRAFT &&
          c.ER_OpportunityId__r.LeadSource != Constants.AUTO_ENROLLMENT &&
          c.ER_OpportunityId__r.TECH_IsWeboffer__c == false
        ) {
          //Create Won Reason task on Opportunity
          Task newTask = new Task();
          newTask.ActivityDate = Date.today();
          newTask.Description = Label.TASK_OPP_WON_REASON_DESCRIPTION;
          newTask.OwnerId = c.ER_OpportunityId__r.OwnerId;
          newTask.Priority = Constants.NORMAL;
          newTask.Status = Constants.OPEN;
          newTask.Subject = Label.TASK_OPP_WON_REASON_SUBJECT;
          newTask.WhatId = c.ER_OpportunityId__r.Id;
          taskList.add(newTask);
        }
      }

      if (!taskList.isEmpty())
        Database.insert(taskList, false);
    }
  }

  /**
   * @author AAZ
   * @date 19/12/2022
   * @description Tick Contacts to be synced with Smarter
   * @param newContracts
   * @param oldContractsMap
   */
  //All contacts + financial centers flagged as to be synced with Smarter under the account linked to the activated contract (with SmartER Context) and created by Profile != IntegrationUser
  //=> To be Synced and The API is also Called  (via trigger)
  public static void markObjectsToBeSyncedWithSmarter(List<Contract> newContracts, Map<Id, Contract> oldContractsMap) {
    List<Id> accountIds = new List<Id>();
    List<Contact> contactsToUpdate = new List<Contact>();
    List<ER_Financial_Center__c> financialCentersToUpdate = new List<ER_Financial_Center__c>();
    List<Contract> newItems = new List<Contract>();

    for (Contract ctr : newContracts) {
      if (ctr.ER_SmartER_Context__c)
        newItems.add(ctr);
    }

    if (!newItems.isEmpty()) {
      for (Contract ctr : [
        SELECT Id, Status, AccountId, ER_ZuoraQuote__r.zqu__BillToContact__c
        FROM Contract
        WHERE
          Id IN :newItems
          AND ER_SmartER_Context__c = TRUE
          AND CreatedBy.Profile.Name != :Constants.PROFILE_ER_INTEGRATION
      ]) {
        if (
          oldContractsMap != null &&
          ctr.Status != oldContractsMap.get(ctr.Id).Status &&
          ctr.Status == Constants.ACTIVATED
        ) {
          accountIds.add(ctr.AccountId);
          if (ctr.ER_ZuoraQuote__r.zqu__BillToContact__c != null)
            contactsToUpdate.add(
              new Contact(Id = ctr.ER_ZuoraQuote__r.zqu__BillToContact__c, ER_To_sync_with_smarter__c = true)
            );
        }
      }

      for (ER_Financial_Center__c fc : [
        SELECT Id, ER_To_sync_with_smarter__c
        FROM ER_Financial_Center__c
        WHERE ER_Account_Name__c IN :accountIds AND ER_SmartER_Context__c = TRUE AND ER_To_sync_with_smarter__c = FALSE
      ]) {
        fc.ER_To_sync_with_smarter__c = true;
        financialCentersToUpdate.add(fc);
      }

      if (!contactsToUpdate.isEmpty())
        Database.update(contactsToUpdate, false);
      if (!financialCentersToUpdate.isEmpty())
        Database.update(financialCentersToUpdate, false);
    }
  }

  /**
   * @author AAZ
   * @date 17/01/2023
   * @description map some ZQuote fields to the linked Contract
   * @param newContracts
   */
  public static void mapFieldsFromZQuote(List<Contract> newContracts) {
    List<Contract> contractsToBeUpdated = new List<Contract>();
    for (Contract c : [
      SELECT
        Id,
        ER_ZuoraQuote__c,
        ER_ZuoraQuote__r.ER_Customer_Signed_Version__c,
        ER_ZuoraQuote__r.ER_TCs_Signed_Link__c,
        ER_ZuoraQuote__r.ER_Agreement_DateTime__c,
        ER_Customer_Signed_Version__c,
        ER_TCs_Signed_Link__c,
        ER_Agreement_DateTime__c
      FROM Contract
      WHERE
        Id IN :newContracts
        AND ER_SmartER_Context__c = TRUE
        AND ER_ZuoraQuote__c != NULL
        AND ER_ZuoraQuote__r.ER_Customer_Signed_Version__c != NULL
        AND ER_ZuoraQuote__r.ER_Agreement_DateTime__c != NULL
        AND ER_SmartER_Context__c = TRUE
    ]) {
      c.ER_Customer_Signed_Version__c = c.ER_ZuoraQuote__r.ER_Customer_Signed_Version__c;
      c.ER_Agreement_DateTime__c = c.ER_ZuoraQuote__r.ER_Agreement_DateTime__c;
      c.ER_TCs_Signed_Link__c = c.ER_ZuoraQuote__r.ER_TCs_Signed_Link__c;
      contractsToBeUpdated.add(c);
    }

    if (!contractsToBeUpdated.isEmpty())
      Database.update(contractsToBeUpdated, false);
  }
  @AuraEnabled(cacheable=true)
  public static Map<Id, Boolean> shouldShowApplyButtonPerContract(Id accountId) {

      Map<Id, Boolean> result = new Map<Id, Boolean>();
      if (accountId == null) {
          System.debug('>>> AccountId was NULL. Returning empty.');
          return result;
      }

      // 1) Fetch account
      Account acc = [
          SELECT Id, ParentId
          FROM Account
          WHERE Id = :accountId
          LIMIT 1
      ];
      Boolean isParent = (acc.ParentId == null);

      // 2) Fetch UI contracts
      List<Id> parentIds  = APER12_Contract_Management.findTopLevelParent(accountId);
      List<Id> partnerIds = APER12_Contract_Management.getEligiblePartners(accountId);

      List<Contract> uiContracts = [
          SELECT Id, ER_Contract_Type__c, Status, AccountId, Contract_Category__c
          FROM Contract
          WHERE
          (
              ((AccountId IN :parentIds OR AccountId = :accountId)
              AND ER_Contract_Type__c = 'Framework agreement')
          )
          OR
          (
              ((AccountId = :accountId OR AccountId IN :partnerIds)
              AND ER_Contract_Type__c = 'Referral agreement')
          )
      ];
      Set<id> uiContractIdSet = new Set<Id>();
      for(Contract ui :uiContracts){
        uiContractIdSet.add(ui.Id);
      }

      // If parent: hide all UI contracts
      if (isParent) {
          for (Contract c : uiContracts) {
              result.put(c.Id, false);
          }
          return result;
      }

      // 3) Fetch derived opportunities
      Set<String> trackedFamilies = new Set<String>{ 'Engagement', 'Benefits' };
      Set<String> usedFamilies = new Set<String>();

      //Only check for ACTIVATED contracts, not just Closed Won opportunities
    List<Contract> activatedContracts = [
        SELECT Id,
               Contract_Category__c,
               ER_OpportunityId__r.product_family_based_on_solution__c
          FROM Contract
          WHERE AccountId = :accountId
            AND Status = 'Activated' 
            AND ER_OpportunityId__c != null
            AND ER_OpportunityId__r.Derieved_from_Framework_Opp__c = true
            AND ER_OpportunityId__r.product_family_based_on_solution__c IN :trackedFamilies
      ];
      
      for (Contract c : activatedContracts) {
          String fam = c.ER_OpportunityId__r.product_family_based_on_solution__c;
          if (fam != null) {
              usedFamilies.add(fam);
          }
      }

      // 4) Determine button visibility
      for (Contract c : uiContracts) {
          if (c.Contract_Category__c != null
              && usedFamilies.contains(c.Contract_Category__c)) {
              result.put(c.Id, false);
          } else {
              result.put(c.Id, true);
          }
      }
      return result;
  }
}