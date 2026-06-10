/**
 * Created by khaddouch on 10/05/2023.
 */

 public with sharing class APER41_BulkContractAmendment_Management implements Queueable, Database.AllowsCallouts {
    private List<ER_Bulk_Contract_Amendment__c> bulkMassAmendmentRecords = new List<ER_Bulk_Contract_Amendment__c>();
    public APER41_BulkContractAmendment_Management(List<ER_Bulk_Contract_Amendment__c> massAmendmentRecords) {
        this.bulkMassAmendmentRecords = massAmendmentRecords;
        System.debug('##### massAmendmentRecords : ' + massAmendmentRecords);
    }

    // Execute method that is the method that call the specified enqueue method
    public void execute(QueueableContext context) {
        System.debug('#####ASYNC context accountIDs : ' + bulkMassAmendmentRecords);
        amendContracts(bulkMassAmendmentRecords);
    }



    public static void fillTechnicalFields(List<ER_Bulk_Contract_Amendment__c> massAmendmentRecords) {
        for (ER_Bulk_Contract_Amendment__c item : massAmendmentRecords) {
            Datetime StartDate= Date.valueOf(item.ER_Contract_Start_Date__c);
            item.ER_Tech_ContractId__c = item.ER_Contract__c;
            item.ER_Tech_Start_Date__c = StartDate.formatGmt('MM/dd/YYYY');
            item.ER_Tech_Service_Reference__c = item.ER_Service_Reference__c;
        }
    }

    public static void amendContracts(List<ER_Bulk_Contract_Amendment__c> MassAmendmentRecords) {
        Set<Id> contractsId = new Set<Id>();
        Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentUpdatePricing = new Map<Id,List<ER_Bulk_Contract_Amendment__c>>();
        Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentUpdateTnC = new Map<Id,List<ER_Bulk_Contract_Amendment__c>>();
        Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentAddService = new Map<Id,List<ER_Bulk_Contract_Amendment__c>>();
        Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentRemoveService = new Map<Id,List<ER_Bulk_Contract_Amendment__c>>();
        for (ER_Bulk_Contract_Amendment__c item : MassAmendmentRecords) {
            contractsId.add(item.ER_Contract__c);
            if(item.ER_Type__c =='UpdatePricing') {
                if (!mapContractMassAmendmentUpdatePricing.containsKey(item.ER_Contract__c)) mapContractMassAmendmentUpdatePricing.put(item.ER_Contract__c, new List<ER_Bulk_Contract_Amendment__c>());
                mapContractMassAmendmentUpdatePricing.get(item.ER_Contract__c).add(item);
            }
            if(item.ER_Type__c =='UpdateT&C') {
                if (!mapContractMassAmendmentUpdateTnC.containsKey(item.ER_Contract__c)) mapContractMassAmendmentUpdateTnC.put(item.ER_Contract__c, new List<ER_Bulk_Contract_Amendment__c>());
                mapContractMassAmendmentUpdateTnC.get(item.ER_Contract__c).add(item);
            }
            if(item.ER_Type__c =='Add Service') {
                if (!mapContractMassAmendmentAddService.containsKey(item.ER_Contract__c)) mapContractMassAmendmentAddService.put(item.ER_Contract__c, new List<ER_Bulk_Contract_Amendment__c>());
                mapContractMassAmendmentAddService.get(item.ER_Contract__c).add(item);
            }
            if(item.ER_Type__c =='Remove Service') {
                if (!mapContractMassAmendmentRemoveService.containsKey(item.ER_Contract__c)) mapContractMassAmendmentRemoveService.put(item.ER_Contract__c, new List<ER_Bulk_Contract_Amendment__c>());
                mapContractMassAmendmentRemoveService.get(item.ER_Contract__c).add(item);
            }
        }
        createOpportunityFromContract(contractsId,mapContractMassAmendmentUpdatePricing,mapContractMassAmendmentUpdateTnC,mapContractMassAmendmentAddService,mapContractMassAmendmentRemoveService);
    }

    public class APER41_BulkContractAmendment_Management_Exception extends Exception {
    }

    public static void createOpportunityFromContract(Set<Id> contractsId, Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentUpdatePricing, Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentUpdateTnC, Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentAddService, Map<Id,List<ER_Bulk_Contract_Amendment__c>> mapContractMassAmendmentRemoveService) {
        Opportunity newOpp;
        OpportunityLineItem oli;
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
        Map<Id, List<OpportunityLineItem>> opportunitiesWithLineItems = new Map<Id, List<OpportunityLineItem>>();
        Map<Id,String> contractWithAmendedOpportunity = new Map<Id,String>();
        Map<String,Decimal> productListPrice = new Map<String,Decimal>();
        List<Contract> contractsToAmend = [
                SELECT Id, OwnerId, RecordType.DeveloperName, AccountId, Account.Name, Pricebook2Id, CurrencyIsoCode, ER_Business_Unit__c, ER_Credit_Limit2__c, ERBE_Reimbursement_Statement_Frequency__c, SK_Payment_Terms_Voucher2__c, ER_PaymentMethod2__c, ER_PaymentTerms2__c, ER_Indexation_Index2__c, ER_OppIndexation2__c, ER_Loads_Per_Year__c, ERBE_Reimbursement_statement_Support__c, SK_Credit_Note_Frequency2__c, ER_ReimbursementTerm2__c, ER_InvoicingFrequency2__c, ER_Contract_Type__c, Subscription__c, ER_SEPA_Bank_Account__c, ERBE_Weekly_Frequence__c, ERBE_Invoicing_Payment_Delay__c, ERBE_Invoicing_day_of_week__c, ER_BUPicklist__c, ER_SmartER_Context__c, (
                        SELECT Id, ER_Contract__c, ER_NeedApproval__c, ER_ListPrice__c, ER_UnitPrice__c, CurrencyIsoCode, ER_PricebookEntryId__c, ER_Quantity__c, ER_Percentage__c, ER_Card_Operational_System_ID__c, ER_Creation_date_in_OS__c, ER_Discount__c, ER_Minimum_Fee__c, ER_Product2__c, ER_Line_Type__c, ER_Max__c, ER_Min__c, ER_Offer_validity_end_date__c, ER_Edenred_Margin_TUR__c, ER_Free_To_Set_Margin__c, ER_MPV__c, Cumulative_with_Promotions__c, ER_BUPicklist__c
                        FROM ER_ContractLineItems__r
                )
                FROM Contract
                WHERE Id IN :contractsId AND ER_Business_Unit__c = 'ES' AND Status ='Activated' ];
        try {
            for(Contract contractInst : contractsToAmend) {
                newOpp = new Opportunity();
                newOpp.ER_External_Id__c = Utils.generateUniqueId();
                newOpp.Name = 'AM';
                newOpp.OwnerId = contractInst.OwnerId;
                newOpp.AccountId = contractInst.AccountId;
                newOpp.ER_AmendedFromContract__c = contractInst.Id;
                newOpp.ER_ReimbursementTerm__c = contractInst.ER_ReimbursementTerm2__c;
                newOpp.SK_Credit_Note_Frequency__c = contractInst.SK_Credit_Note_Frequency2__c;
                newOpp.ER_Indexation__c = contractInst.ER_OppIndexation2__c;
                newOpp.ER_Indexation_Index__c = contractInst.ER_Indexation_Index2__c;
                newOpp.ER_InvoicingFrequency__c = contractInst.ER_InvoicingFrequency2__c;
                newOpp.ER_PaymentMethod__c = contractInst.ER_PaymentMethod2__c;
                newOpp.ER_PaymentTerms__c = contractInst.ER_PaymentTerms2__c;
                if (mapContractMassAmendmentUpdateTnC.containsKey(contractInst.Id)){
                    for(ER_Bulk_Contract_Amendment__c item : mapContractMassAmendmentUpdateTnC.get(contractInst.Id)){
                        if(item.ER_Invoicing_Frequency__c != null) newOpp.ER_InvoicingFrequency__c = item.ER_Invoicing_Frequency__c;
                        if(item.ER_Payment_Method__c != null) newOpp.ER_PaymentMethod__c = item.ER_Payment_Method__c;
                        if(item.ER_Payment_Term__c != null) newOpp.ER_PaymentTerms__c = item.ER_Payment_Term__c;
                    }
                }
                newOpp.SK_Payment_Terms_Voucher__c = contractInst.SK_Payment_Terms_Voucher2__c;
                newOpp.ER_Loads_Per_Year__c = contractInst.ER_Loads_Per_Year__c;
                newOpp.ER_Credit_Limit__c = contractInst.ER_Credit_Limit2__c;
                newOpp.Pricebook2Id = contractInst.Pricebook2Id;
                newOpp.StageName = Label.LABS_SF_Opp_Status_Qualification;
                newOpp.CloseDate = Date.today().addMonths(1);
                newOpp.ERBE_Reimbursement_Statement_Frequency__c = contractInst.ERBE_Reimbursement_Statement_Frequency__c;
                newOpp.ERBE_Reimbursement_Statement_Support__c = contractInst.ERBE_Reimbursement_statement_Support__c;
                if(!String.isBlank(contractInst.ER_Contract_Type__c)) {newOpp.Type = contractInst.ER_Contract_Type__c;}
                else {newOpp.Type = Label.LABS_SF_Opportunity_Type_Operational;}
                newOpp.CurrencyIsoCode = contractInst.CurrencyIsoCode;
                newOpp.ER_SEPA_Bank_Account__c = contractInst.ER_SEPA_Bank_Account__c;
                newOpp.ERBE_Weekly_Frequence__c = contractInst.ERBE_Weekly_Frequence__c;
                newOpp.ERBE_Invoicing_Payment_Delay__c = contractInst.ERBE_Invoicing_Payment_Delay__c;
                newOpp.ERBE_Invoicing_day_of_week__c = contractInst.ERBE_Invoicing_day_of_week__c;
                newOpp.ER_BUPicklist__c = contractInst.ER_BUPicklist__c;
                newOpp.ER_SmartER_Context__c = contractInst.ER_SmartER_Context__c;
                if(contractInst.RecordType.DeveloperName == 'ER_Client_Contract_RT') {newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Client_Opportunity_RT').getRecordTypeId();}
                else if(contractInst.RecordType.DeveloperName == 'ER_Merchant_Contract_RT') {newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Opportunity').getRecordTypeId();}
                System.debug('zzz newOpp: ' + newOpp);
                opportunitiesToInsert.add(newOpp);
                if(!contractWithAmendedOpportunity.containsKey(contractInst.Id)){contractWithAmendedOpportunity.put(contractInst.Id,newOpp.ER_External_Id__c);}
            }
            //if(!opportunitiesToInsert.isEmpty()) Database.insert(opportunitiesToInsert, false);
            if(!opportunitiesToInsert.isEmpty()) insert opportunitiesToInsert;
            System.debug('###opportunitiesToInsert inserted !');
            /*for(Opportunity opp :opportunitiesToInsert){

            }*/
            System.debug('#### contractWithAmendedOpportunity : '+contractWithAmendedOpportunity);
            for(Contract contractInst : contractsToAmend)  {
                //Opportunity linkedOpp = new Opportunity(ER_External_Id__c=contractWithAmendedOpportunity.get(contractInst.Id));
                //System.debug('#### linkedOpp : '+ linkedOpp);
                if (!opportunitiesWithLineItems.containsKey(contractInst.Id)) opportunitiesWithLineItems.put(contractInst.Id, new List<OpportunityLineItem>());
                if(!Schema.SObjectType.Contract.fields.Subscription__c.isAccessible() ||(Schema.SObjectType.Contract.fields.Subscription__c.isAccessible() && contractInst.Subscription__c == null)) {
                    for(ER_ContractLineItem__c cli : contractInst.ER_ContractLineItems__r) {
                        oli = new OpportunityLineItem();
                        oli.Opportunity = new Opportunity(ER_External_Id__c=contractWithAmendedOpportunity.get(contractInst.Id));
                        oli.Product2Id = cli.ER_Product2__c;
                        oli.UnitPrice = cli.ER_UnitPrice__c;
                        oli.ER_Percentage__c = cli.ER_Percentage__c;
                        System.debug('##### oli.Product2Id : '+oli.Product2Id);
                        System.debug('##### cli.ER_Contract__c : '+cli.ER_Contract__c);
                        System.debug('##### contains cli.ER_Contract__c ? : '+mapContractMassAmendmentUpdatePricing.containsKey(cli.ER_Contract__c));
                        if (mapContractMassAmendmentUpdatePricing.containsKey(cli.ER_Contract__c)){
                            for(ER_Bulk_Contract_Amendment__c item : mapContractMassAmendmentUpdatePricing.get(cli.ER_Contract__c)){
                                System.debug('##### IN oli.Product2Id : '+oli.Product2Id);
                                System.debug('##### IN item.ER_Service_Reference__c : '+item.ER_Service_Reference__c);
                                if(oli.Product2Id == item.ER_Service_Reference__c){
                                    System.debug('##### IN item.ER_New_Price__c : '+item.ER_New_Price__c);
                                    if(cli.ER_Percentage__c != null) {oli.ER_Percentage__c = item.ER_New_Price__c;}
                                    else {oli.UnitPrice = item.ER_New_Price__c;}
                                }
                            }
                        }
                        oli.PricebookEntryId = cli.ER_PricebookEntryId__c;
                        oli.Quantity = cli.ER_Quantity__c;
                        oli.ER_NeedApproval__c = cli.ER_NeedApproval__c;
                        oli.ER_Creation_date_in_OS__c = cli.ER_Creation_date_in_OS__c;
                        oli.ER_Card_Operational_System_ID__c = cli.ER_Card_Operational_System_ID__c;
                        oli.ER_Minimum_Fee__c = cli.ER_Minimum_Fee__c;
                        oli.Discount = cli.ER_Discount__c;
                        oli.ER_Line_Type__c = cli.ER_Line_Type__c;
                        oli.ER_Max__c = cli.ER_Max__c;
                        oli.ER_Min__c = cli.ER_Min__c;
                        oli.ER_Offer_validity_end_date__c = cli.ER_Offer_validity_end_date__c;
                        oli.ER_Edenred_Margin_TUR__c = cli.ER_Edenred_Margin_TUR__c;
                        oli.ER_Free_To_Set_Margin__c = cli.ER_Free_To_Set_Margin__c;
                        oli.ER_MPV__c = cli.ER_MPV__c;
                        oli.ER_Cumulative_with_Promotions__c = cli.Cumulative_with_Promotions__c;
                        oli.ER_BUPicklist__c = cli.ER_BUPicklist__c;
                        oliToInsert.add(oli);
                        opportunitiesWithLineItems.get(contractInst.Id).add(oli);
                        productListPrice.put(cli.ER_Product2__c, cli.ER_ListPrice__c);
                    }
                }
            }
            System.debug('>>>>> ALK - oliToInsert : ' + oliToInsert.size());
            //if(!oliToInsert.isEmpty()) Database.insert(oliToInsert, false);
            if(!oliToInsert.isEmpty()) insert oliToInsert;
        } catch(Exception e) {
            System.debug('########AAAAA Exception:' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        if(!opportunitiesToInsert.isEmpty() && !oliToInsert.isEmpty()) createdSyncQuote(opportunitiesToInsert,opportunitiesWithLineItems, oliToInsert, productListPrice);
    }

    public static void createdSyncQuote(List<Opportunity> syncOpportunityList, Map<Id, List<OpportunityLineItem>> opportunitiesWithLineItems, List<OpportunityLineItem> opportunityLineItems,Map<String,Decimal> productListPrice) {
        Set<Id> oppIdset = new Set<Id>();
        Quote newQuote;
        List<Quote> newQuoteList = new List<Quote>();
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        Map<String, OpportunityContactRole> mapOpportunityPrimaryContact = new Map<String, OpportunityContactRole>();
        Map<String,String> quoteOppMap = new Map<String,String>();
        for (Opportunity opp : syncOpportunityList) {
            oppIdset.add(opp.Id);
        }
        List<OpportunityContactRole> ocrList = [
                SELECT OpportunityId, Role, ContactId, IsPrimary, Contact.Email, Contact.Phone
                FROM OpportunityContactRole
                WHERE OpportunityId IN :oppIdset AND IsPrimary = TRUE
        ];

        if (!ocrList.isEmpty()) {
            mapOpportunityPrimaryContact.put(ocrList[0].OpportunityId, ocrList[0]);
        }
        for (Opportunity opp : syncOpportunityList) {
            newQuote = new Quote();
            if (!mapOpportunityPrimaryContact.isEmpty()) {
                newQuote.ContactId = mapOpportunityPrimaryContact.get(opp.Id).ContactId;
                newQuote.Email = mapOpportunityPrimaryContact.get(opp.Id).Contact.Email;
                newQuote.Phone = mapOpportunityPrimaryContact.get(opp.Id).Contact.Phone;
            }
            newQuote.OwnerId = opp.OwnerId;
            newQuote.Name = Datetime.now().format('yyyy-MM-dd') + '-' + opp.Name;
            newQuote.ER_Web_Offer_Token__c = Utils.generateUniqueId();
            newQuote.Opportunity = opp;
            newQuote.OpportunityId = opp.Id;
            newQuote.Pricebook2Id = opp.Pricebook2Id;
            newQuote.ER_SEPA_Bank_Account__c = opp.ER_SEPA_Bank_Account__c;
            newQuote.ER_Quote_Type__c = opp.Type;
            if (opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Opportunity').getRecordTypeId()) {
                newQuote.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Quote').getRecordTypeId();
            } else if (opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Client_Opportunity_RT').getRecordTypeId()) {
                newQuote.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('ER_Client_Quote').getRecordTypeId();
            }
            newQuote.ExpirationDate = Date.today().addMonths(1);
            newQuoteList.add(newQuote);
            quoteOppMap.put(opp.ER_External_Id__c, newQuote.ER_Web_Offer_Token__c);
        }
        if (!newQuoteList.isEmpty()) {
            insert newQuoteList;
        }
        System.debug('####### quoteOppMap : '+quoteOppMap);
        for (OpportunityLineItem oli : opportunityLineItems) {

            System.debug(' ###### oli opportunityID : '+ oli.OpportunityId);
            System.debug(' ###### oli oli.Opportunity.ER_External_Id__c : '+ oli.Opportunity.ER_External_Id__c);
            System.debug(' ###### quoteOppMap.get(oli.OpportunityId) : '+ quoteOppMap.get(oli.Opportunity.ER_External_Id__c));
            QuoteLineItem qli;
            qli = new QuoteLineItem();
            qli.Opportunity_Product__c = oli.Id;
            qli.UnitPrice = oli.UnitPrice;
            qli.ER_Percentage__c = oli.ER_Percentage__c;
            qli.Quote = new Quote(ER_Web_Offer_Token__c = quoteOppMap.get(oli.Opportunity.ER_External_Id__c));
            qli.Quantity = oli.Quantity;
            qli.PricebookEntryId = oli.PricebookEntryId;
            qli.ER_Card_Operational_System_ID__c = oli.ER_Card_Operational_System_ID__c;
            qli.ER_Creation_date_in_OS__c = oli.ER_Creation_date_in_OS__c;
            qli.ER_Minimum_Fee__c = oli.ER_Minimum_Fee__c;
            qli.Discount = oli.Discount;
            qli.ER_BUPicklist__c = oli.ER_BUPicklist__c;
            qli.ER_Line_Type__c = oli.ER_Line_Type__c;
            qli.ER_Max__c = oli.ER_Max__c;
            qli.ER_Min__c = oli.ER_Min__c;
            qli.ER_What__c = oli.ER_What__c;
            qli.ER_Price_End_Date__c = oli.ER_Price_End_Date__c;
            qli.ER_Offer_validity_end_date__c = oli.ER_Offer_validity_end_date__c;
            qli.ER_Duration__c = oli.ER_Duration__c;
            qli.ER_User_Discount__c = oli.ER_User_Margin__c;
            qli.ER_Edenred_Margin_TUR__c = oli.ER_Edenred_Margin_TUR__c;
            qli.ER_Free_to_setup_the_margin__c = oli.ER_Free_To_Set_Margin__c;
            qli.ER_MPV__c = oli.ER_MPV__c;
            qli.ER_Cumulative_with_promotions__c = oli.ER_Cumulative_with_Promotions__c;
            qli.ER_Quantity_Unit_of_Measure__c = oli.ER_Quantity_Unit_of_Measure__c;
            qli.Product2Id = oli.Product2Id;
            qliList.add(qli);
        }
        if (!qliList.isEmpty()) {
            insert qliList;
        }
        if (!newQuoteList.isEmpty() && !qliList.isEmpty()) createContractFromQuote(newQuoteList, qliList, productListPrice);

    }


    public static List<Contract> createContractFromQuote( List<Quote> quotesList, List<QuoteLineItem> quoteLineItems, Map<String,Decimal> productListPrice) {

        List<Contract> contractToInsert = new List<Contract>();
        Contract newContract;
       // Savepoint sp = Database.setSavepoint();
        Map<String,String> contractQuoteMap = new Map<String,String>();
        List<Opportunity> opportunityToUpdate = new List<Opportunity>(); // update contract Id field
        Opportunity opportunityInst;
        try {
            for(Quote quote : quotesList) {
                newContract = new Contract();
                if(quote.RecordType.DeveloperName == 'ER_Client_Quote') {
                    newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId();
                } else if(quote.RecordType.DeveloperName == 'ER_Merchant_Quote') {
                    newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Contract_RT').getRecordTypeId();
                }
                newContract.ER_QuoteId__c = quote.Id;
                newContract.ER_Contract_External_ID__c = Utils.generateUniqueId();
                newContract.ER_OpportunityId__c = quote.OpportunityId;
                newContract.AccountId = quote.Opportunity.AccountId;
                newContract.Pricebook2Id = quote.Pricebook2Id;
                newContract.OwnerId = quote.OwnerId;
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
                newContract.StartDate = (quote.Opportunity.ER_Contract_Expected_Start_Date__c != null) ? quote.Opportunity.ER_Contract_Expected_Start_Date__c : Date.today();
                newContract.ER_BUPicklist__c = quote.Opportunity.ER_BUPicklist__c;
                newContract.ER_Contract_Duration__c = quote.ER_Contract_Duration__c;
                newContract.ER_Solutions__c = quote.Opportunity.ER_Solutions__c;
                newContract.ERBE_Reimbursement_Statement_Frequency__c = quote.ERBE_Reimbursement_Statement_Frequency2__c;
                newContract.ERBE_Reimbursement_statement_Support__c = quote.ERBE_Reimbursement_Statement_Support2__c;
                newContract.ER_SEPA_Bank_Account__c = quote.ER_SEPA_Bank_Account__c;
                newContract.ERBE_Invoicing_day_of_week__c = quote.ER_Invoicing_day_of_week__c;
                newContract.ERBE_Invoicing_Payment_Delay__c = quote.ER_Invoicing_payment_delay__c;
                newContract.ERBE_Weekly_Frequence__c = quote.ERBE_Weekly_Frequence__c;
                contractQuoteMap.put(quote.ER_Web_Offer_Token__c,newContract.ER_Contract_External_ID__c);
                contractToInsert.add(newContract);
                opportunityInst = new Opportunity(Id = quote.OpportunityId, Contract = new Contract(ER_Contract_External_ID__c = newContract.ER_Contract_External_ID__c));//(from trigger before update) ==> cannot get ContractId from Query Yet!

                opportunityToUpdate.add(opportunityInst);
            }
            if(!contractToInsert.isEmpty()) {
                System.debug('contractToInsert : ' + contractToInsert);
                insert contractToInsert;
            }

              //  APER12_Contract_Management.createCLIAndUpdateOpportunity(acceptedQuoteMap);



            /////////// APER12 contract create cli and update opportunity

            Map<String, Date> mapProductEndDate = new Map<String, Date>();

            //Map<String, Date> endDateByproductCodeMap = new Map<String, Date>();

            ER_ContractLineItem__c cli;
            List<ER_ContractLineItem__c> cliToInsert = new List<ER_ContractLineItem__c>();



                //Calculate Service Start Date
                for(QuoteLineItem qli : quoteLineItems) {

                    if(qli.ER_Line_Type__c == 'Discount') {
                        if(qli.ER_Price_End_Date__c != null) mapProductEndDate.put(qli.Product2.ProductCode, qli.ER_Price_End_Date__c);
                        else if(qli.ER_Duration__c != null) {
                            Date contractStartDate = (qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c != null ? qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c : Date.today());
                            mapProductEndDate.put(qli.Product2.ProductCode, contractStartDate?.addDays(Integer.valueOf(qli.ER_Duration__c)));
                        }
                    }
                }

                for(QuoteLineItem qli : quoteLineItems) {

                    cli = new ER_ContractLineItem__c();
                    cli.Name = qli.Product2.Name;
                    cli.ER_Contract__r = new Contract(ER_Contract_External_ID__c = contractQuoteMap.get(qli.Quote.ER_Web_Offer_Token__c));//(from trigger before update) ==> cannot get ContractId from Query Yet!
                    cli.ER_Percentage__c = qli.ER_Percentage__c;
                    cli.ER_Product2__c = qli.Product2Id;
                    cli.ER_PricebookEntryId__c = qli.PricebookEntryId;
                    cli.CurrencyIsoCode = qli.CurrencyIsoCode;
                    cli.ER_UnitPrice__c = qli.UnitPrice;
                    cli.ER_ListPrice__c = productListPrice.get(qli.Product2Id);
                    cli.ER_Quantity__c = qli.Quantity;
                    cli.ER_NeedApproval__c = qli.ER_NeedApproval__c;
                    cli.ER_Minimum_Fee__c = qli.ER_Minimum_Fee__c;
                    cli.ER_Card_Operational_System_ID__c = qli.ER_Card_Operational_System_ID__c;
                    //cli.ER_Creation_date_in_OS__c = qli.ER_Creation_date_in_OS__c;
                    cli.ER_Discount__c = qli.Discount;
                    cli.ER_What__c = qli.ER_What__c;

                    //FEB 2021 VJOY - Added mapping for range products
                    cli.ER_Line_Type__c = qli.ER_Line_Type__c;
                    cli.ER_Max__c = qli.ER_Max__c;
                    cli.ER_Min__c = qli.ER_Min__c;

                    /*PBI 7485: VJOY 2021*/
                    cli.ER_Offer_validity_end_date__c = qli.ER_Offer_validity_end_date__c;
                    cli.ER_Quantity_Unit_of_Measure__c = qli.ER_Quantity_Unit_of_Measure__c;
                    Date contractStartDate = (qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c != null ? qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c : Date.today());

                    if(cli.ER_Line_Type__c == 'Discount') cli.ER_Price_End_Date__c = mapProductEndDate.get(qli.Product2.ProductCode);
                    else if(cli.ER_Line_Type__c == 'Service') cli.ER_Price_Start_Date__c = mapProductEndDate.get(qli.Product2.ProductCode)?.addDays(1);
                    else cli.ER_Price_End_Date__c = null;

                    //cli.OwnerId = qli.Quote.OwnerId;  // AAM 18.11.21: PBI#13620
                    cli.ER_BUPicklist__c = qli.ER_BUPicklist__c;  // AAM 18.11.21: PBI#14291

                    /*PBI14186 VJOY JAN 2022*/
                    cli.ER_User_Discount__c = qli.ER_User_Discount__c;
                    cli.ER_Edenred_Margin_TUR__c = qli.ER_Edenred_Margin_TUR__c;
                    cli.ER_Free_To_Set_Margin__c = qli.ER_Free_to_setup_the_margin__c;
                    cli.ER_MPV__c = qli.ER_MPV__c;
                    cli.Cumulative_with_Promotions__c = qli.ER_Cumulative_with_promotions__c;
                    cliToInsert.add(cli);
                }

            if(!cliToInsert.isEmpty()) {
                System.debug('cliToInsert : ' + cliToInsert);
                insert cliToInsert;
            }
            if(!opportunityToUpdate.isEmpty()) {

                System.debug('opportunityToUpdate : ' + opportunityToUpdate);
                APER04_Opportunity_Management.updateOpportunityContract(opportunityToUpdate);
                updateBulkMassAmendmentRecords(opportunityToUpdate);
            }

            ///////////
                /*if(newContract.ER_Contract_Type__c == Label.LAB_SF_Contact_Operational) {
                    APER20_Account_Management.manageAccountLineItemsForContract(newContract);
                    APER30_FinancialCenter_Management.manageFCLIForFinancialCenter(newContract);
                    if(newContract.RecordTypeId == Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Contract_RT').getRecordTypeId()) {
                        APER14_Store_Management.manageSLIFromContractNew(newContract);
                        APER23_Acceptor_Management.manageAcceptorLIFromContract(newContract);
                    } else if(newContract.RecordTypeId == Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId()) {
                        APER28_DeliverySite_Management.manageDSLIFromContract(newContract);
                        APER29_DistributionPoint_Management.manageDPLIFromContract(newContract);
                    }
                } */

        } catch(Exception e) {
           // Database.rollback(sp);
        }
        return contractToInsert;
    }

    public static void updateBulkMassAmendmentRecords(List<Opportunity> opportunities){
        List<Opportunity> oppList = [SELECT Id, ContractId, ER_AmendedFromContract__c FROM Opportunity WHERE Id IN :opportunities];
        List<ER_Bulk_Contract_Amendment__c> bulkContractAmendmentToUpdate = new List<ER_Bulk_Contract_Amendment__c>();
        for (ER_Bulk_Contract_Amendment__c bulkContractAmendment : [SELECT Id,ER_Contract__c, ER_Contract_Start_Date__c FROM ER_Bulk_Contract_Amendment__c WHERE ER_Contract_Start_Date__c = TODAY]){
            for (Opportunity opp :oppList){
                if(bulkContractAmendment.ER_Contract__c == opp.ER_AmendedFromContract__c) {
                    bulkContractAmendment.ER_Amended_Contract__c = opp.ContractId;
                    bulkContractAmendmentToUpdate.add(bulkContractAmendment);
                }
            }
        }
        if(!bulkContractAmendmentToUpdate.isEmpty()) update bulkContractAmendmentToUpdate;

        //ER_Bulk_Contract_Amendment__c

    }
}