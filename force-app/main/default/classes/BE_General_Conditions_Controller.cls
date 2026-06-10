/**
 * @description       : 
 * @author            : AAM
 * @group             : 
 * @last modified on  : 15-10-2021
 * @last modified by  : AAM
**/
public inherited sharing class BE_General_Conditions_Controller {

    private static Integer MAX_SIZE = 255;//max size for text field

    public static BE_General_Condition__c getGeneralCondition(String language, String product, Id opportunityId, String stakeholderType){
        return [SELECT Id, BE_Body__c FROM BE_General_Condition__c WHERE BE_Edenred_Solution__c =: product AND BE_Type__c =: stakeholderType AND BE_Language__c =: language AND BE_Active__c = true LIMIT 1];
    }

    public static String submitAgreedToGeneralConditions(Boolean agreedToGeneralConditions, Boolean prepaymentAccepted,
                                                         Id opportunityId, Id accountId, String stakeholderType,
                                                         String productName, String emailAddress, String formLanguage){
        //BE_EDG_Webservice edgWS = new BE_EDG_Webservice(accountId);

        Account acc;
        ER_Financial_Center__c fc = null;
        try{
            Opportunity o = [SELECT Id, Pricebook2.Name, Pricebook2.ER_Card_Operational_System_ID__c,
                                    ER_Nb_of_Employees__c, ER_Estimated_Number_Of_Beneficiaries__c 
                             FROM Opportunity WHERE Id =: opportunityId LIMIT 1];

            String nameProduct='';
            if(o != null){
                // faire les appels EDG (test sur stakeholdertype)
                acc = [SELECT Id, ER_WS_result_Text_Long__c, ER_External_Reference__c, BE_Client_Contract_TRE__c,
                              BE_Client_Contract_TCE__c, BE_Client_Contract_ECE__c
                       FROM Account WHERE Id=:accountId];
                fc = [
                        SELECT ID,ER_Creation_date_in_OS__c, ER_WS_result_Text__c
                        FROM ER_Financial_Center__c
                        WHERE ER_Account_Name__c=:acc.Id
                ].get(0);

                /*if(stakeholderType =='Merchant'){

                    List<ER_Acceptor__c> lstAccptToUpdate = new List<ER_Acceptor__c>();

                    List<List<BE_Structure_EDG.Identifier>> identifiers = new List<List<BE_Structure_EDG.Identifier>>();
                    Map <String,String> mapIdNemo = new Map <String,String>();

                    nameProduct = o.Pricebook2.Name.substring(0,3);

                    if(String.isBlank(acc.ER_External_Reference__c)) {
                        mapIdNemo = edgWS.createMerchant(accountId, prepaymentAccepted, identifiers);
                    }
                    else{ //merchant existe déjà
                        String searchText = Label.Operational_Role_Main_Contact_API;
                        Contact mainContact = [SELECT Id, ER_Card_Operational_System_ID__c, BE_Operational_Role__c, ER_Language__c
                                               FROM Contact 
                                               WHERE AccountId = :acc.Id AND ER_Card_Operational_System_ID__c != NULL
                                                     AND BE_Operational_Role__c INCLUDES ( :searchText) LIMIT 1];
                        mapIdNemo.put(Label.Operational_Role_Main_Contact_API, mainContact.ER_Card_Operational_System_ID__c);
                        mapIdNemo.put('stakeholder_id', acc.ER_External_Reference__c);

                        //PBI-585 : update store
                        edgWS.updateStore();
                        lstAccptToUpdate = edgWS.addAcceptor();
                    }

                    try{
                        String method;
                        if(acc.BE_Client_Contract_TRE__c && 'TRE'.equals(productName)
                           || acc.BE_Client_Contract_TCE__c && 'TCE'.equals(productName)
                           || acc.BE_Client_Contract_ECE__c && 'ECE'.equals(productName)) //Merchant -> Client (|| acc.BE_Client_Contract_CVE__c && 'CVE'.equals(productName) removed)
                            method = 'PUT';
                        else
                            method = 'POST';
                        edgWS.createContractMerchant(accountId, o, method, mapIdNemo, identifiers);
                    }
                    catch(Exception ex){
                      //  throw new AuraHandledException('Error_Message_Server_Error');
                        return 'error';
                    }
                    finally{
                        if(String.isBlank(acc.ER_External_Reference__c)){
                            //PBI-573 : Card operational system ID not stored in Acceptor
                            edgWS.updateReferenceAcceptor(accountId);
                            edgWS.updateMerchantReferenceNemo(accountId, mapIdNemo, identifiers);
                        }
                        else{
                            update lstAccptToUpdate;
                        }
                    }
                }
                else*/
                if(stakeholderType == 'Customer'){
                    nameProduct=o.Pricebook2.Name.substring(3,6);
                    Map<String, String> mapIdNemo;
                    if(String.isBlank(acc.ER_External_Reference__c)){
                        //mapIdNemo = edgWS.createClient(accountId, prepaymentAccepted);
                    }else{
                        mapIdNemo = new Map<String, String>();
                        for(Contact contact : [SELECT Id, BE_Operational_Role__c, ER_Card_Operational_System_ID__c FROM Contact
                                               WHERE AccountId = :acc.Id]){
                            if(contact.BE_Operational_Role__c != null){
                                if(contact.BE_Operational_Role__c.contains(Label.Operational_Role_Main_Contact_API))
                                    mapIdNemo.put(Label.Operational_Role_Main_Contact_API, contact.ER_Card_Operational_System_ID__c);
                                if(contact.BE_Operational_Role__c.contains(Label.Operational_Role_Delivery_Contact_API))
                                    mapIdNemo.put(Label.Operational_Role_Delivery_Contact_API, contact.ER_Card_Operational_System_ID__c);
                                if(contact.BE_Operational_Role__c.contains(Label.Operational_Role_Invoicing_Contact_API))
                                    mapIdNemo.put(Label.Operational_Role_Invoicing_Contact_API, contact.ER_Card_Operational_System_ID__c);
                                if(contact.BE_Operational_Role__c.contains(Label.Operational_Role_Order_Contact_API))
                                    mapIdNemo.put(Label.Operational_Role_Order_Contact_API, contact.ER_Card_Operational_System_ID__c);
                            }
                        }
                        mapIdNemo.put('stakeholder_id', acc.ER_External_Reference__c);
                    }
                    //edgWS.createContractClient(accountId, o, mapIdNemo);

                    /*if(String.isBlank(acc.ER_External_Reference__c))
                        edgWS.updateCustomerReferenceNemo(accountId, mapIdNemo);
                    
                    edgWS.manageErrorLogSAS(accountId);*/
                }

                updateOppo(opportunityId, agreedToGeneralConditions, prepaymentAccepted); //update ne peut se faire qu'après les appels au web-service

                updateAccount(accountId, stakeholderType, nameProduct, o);//confirm contract created

                /*if([SELECT Id FROM ER_Store__c WHERE ER_Merchant__c = :accountId].size() <= 1)*/
                    sendContractViaEmail(opportunityId, accountId, emailAddress, opportunityId, stakeholderType, productName, null, formLanguage);
            }
            else{
                throw new AuraHandledException('Error_Message_Opportunity_not_found');
            }
        }
        catch(Exception ex) {
            System.debug('ex=' + ex.getMessage() + ' ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            return 'error';
          //  throw new AuraHandledException('Error_Message_Server_Error');
        }

        return 'success';
    }

    private static void updateOppo(String Id, Boolean agreed, Boolean prepayment){
        Opportunity o = [SELECT Id,ER_PaymentMethod__c, ER_Won_Reason__c, BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,
                StageName
        FROM Opportunity WHERE Id =: Id LIMIT 1];

        //delete update general condition for PBI-618 : Register that the prospect submitted/agreed cgv before EDG CALL

        //o.StageName = 'Closed Won';
        //o.ER_Won_Reason__c = 'Auto-Enrollment';
        if (prepayment){ o.ER_PaymentMethod__c = 'Prepayment'; }
        update o;
    }

    private static void updateAccount(String accountId,String stakeholderType , String nameProduct, Opportunity opportunity){
        Account acc = [SELECT Id, ER_WS_result_Text_Long__c, BE_Client_Contract_ECE__c, BE_Client_Contract_TCE__c, BE_Client_Contract_TRE__c
                       FROM Account WHERE Id = :accountId]; //Merchant -> Client

        /*if(stakeholderType == 'Merchant'){ //Merchant -> Client
            if(nameProduct == 'TRE'){
                acc.BE_Client_Contract_TRE__c = true;
            }
            else if(nameProduct == 'ECE'){
                acc.BE_Client_Contract_ECE__c = true;
            }
            else if(nameProduct == 'TCE'){
                acc.BE_Client_Contract_TCE__c = true;
            }
            else if(nameProduct == 'CVE'){
                //acc.BE_Client_Contract_CVE__c = true;
            }

            //if(opportunity.BE_Additional_Services__c != null && opportunity.BE_Additional_Services__c.contains('MyOrder'))
                //acc.BE_Merchant_Contract_MyOrder__c = true;//commented
        }
        else*/ 
        if (stakeholderType == 'Customer'){
            if(nameProduct == 'TRE'){
                acc.BE_Client_Contract_TRE__c = true;
            }
            else if(nameProduct == 'ECE'){
                acc.BE_Client_Contract_ECE__c = true;
            }
            else if(nameProduct == 'TCE'){
                acc.BE_Client_Contract_TCE__c = true;
            }
        }
        Database.update(acc, false);
    }

    public static String createQuote(String opportunityId){
        Quote newQuote;
        Boolean opportunityNeedApproval = false;
        Boolean oppNeedFinancialApproval = false;
        List<opportunityLineItem> oppProductList;
        List<quoteLineItem> qliList = new List<quoteLineItem>();
        Opportunity currentOpportunity = new Opportunity();
        QuoteLineItem qli;
        List<OpportunityContactRole> ocrList;

        List<Quote> recentQuote = [SELECT Id, Status  FROM Quote WHERE Status = 'Offer Presented' AND OpportunityId =: opportunityId ORDER By CreatedDate DESC];

        //get the list of the opportunity Product
        oppProductList = [
                SELECT id, Name, UnitPrice, Discount, ER_Percentage__c, Quantity,
                        Product2.ER_Solution_Type__c, Product2.ER_Type__c, Opportunity.RecordType.DeveloperName,
                        Opportunity.Name, Opportunity.OwnerId, PricebookEntryId, Opportunity.pricebook2Id,
                        PricebookEntry.Name, Product2.Description, Product2.ER_Solution__r.Name, Opportunity.Type,
                        Product2.ER_solution__r.ER_Type__c, Product2.ER_solution__r.ER_Solution_Type__c, ListPrice,
                        CurrencyIsoCode, ER_Card_Operational_System_ID__c, ER_Creation_date_in_OS__c, Opportunity.ER_SEPA_Bank_Account__c,
                        Opportunity.ER_PaymentTerms__c, Opportunity.ER_InvoicingFrequency__c, Opportunity.ER_PaymentMethod__c,
                        Opportunity.ER_ReimbursementTerm__c, Opportunity.ER_Business_Unit__c, ER_Minimum_Fee__c, Opportunity.ER_BUPicklist__c,
                        Opportunity.ER_NeedFinancialApproval__c, ER_Line_Type__c, ER_Max__c, ER_Min__c, ER_BUPicklist__c,
                        ER_Price_End_Date__c, ER_Offer_validity_end_date__c, ER_Duration__c, ER_What__c, Opportunity.ER_Original_Agreement__c,
            			Opportunity.ER_BU_Picklist__c, Product2.Name, Opportunity.ER_VAT__c, Product2.ER_Solution__r.ProductCode, Product2.ProductCode,
						Opportunity.ERBE_Invoicing_Support__c, Opportunity.ER_Validity_channel__c, Opportunity.ER_Validity_Period__c, Opportunity.Pricebook2.ER_MDMId__c,
                        ER_Edenred_Margin_TUR__c, ER_User_Margin__c, ER_Free_To_Set_Margin__c, ER_MPV__c, ER_Cumulative_with_Promotions__c, ER_Price_Start_Date__c,Opportunity.ER_Need_Financial_Approval_2__c, Opportunity.Primary_Contact__c, Opportunity.Primary_Contact__r.Email, Opportunity.Primary_Contact__r.Phone 
                FROM opportunityLineItem
                WHERE opportunityId = :opportunityId
                ORDER BY product2.ER_solution__r.ER_Line_Order__c, product2.ER_Line_Order__c
        ];
 
        System.debug('>>> SaveAsQuote - oppProductList size ' + oppProductList.size());
        
        if(!oppProductList.isEmpty()) {

            Savepoint sp = Database.setSavepoint();

            newQuote = new Quote();
            if(!recentQuote.isEmpty()){
                newQuote.Id = recentQuote[0].Id;
            }else{
                newQuote.Id = null;
            }
            newQuote.ContactId = oppProductList[0].Opportunity.Primary_Contact__c;
            newQuote.Email = oppProductList[0].Opportunity.Primary_Contact__r.Email;
            newQuote.Phone = oppProductList[0].Opportunity.Primary_Contact__r.Phone;
            newQuote.OwnerId = oppProductList[0].Opportunity.ownerId;
            newQuote.OpportunityId = opportunityId;
            newQuote.ER_Quote_Type__c = oppProductList[0].Opportunity.Type;
            newQuote.pricebook2Id = oppProductList[0].Opportunity.pricebook2Id;
            newQuote.ER_Original_Agreement__c = oppProductList[0].Opportunity.ER_Original_Agreement__c;
            newQuote.ER_SEPA_Bank_Account__c = oppProductList[0].Opportunity.ER_SEPA_Bank_Account__c;
            if(oppProductList[0].Opportunity.RecordType.DeveloperName == 'ER_Client_Opportunity_RT') {
                newQuote.recordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('ER_Client_Quote').getRecordTypeId();
            }
            newQuote.expirationDate = Date.today().addMonths(1);
            newQuote.ERBE_Invoicing_Support__c = oppProductList[0].Opportunity.ERBE_Invoicing_Support__c;
            newQuote.ER_BUPicklist__c = oppProductList[0].Opportunity.ER_BUPicklist__c;
            upsert newQuote;

            if(recentQuote.isEmpty()){
                for(opportunityLineItem oli : oppProductList) {

                    qli = new QuoteLineItem();
                    qli.QuoteId = newQuote.id;
                    qli.Opportunity_Product__c = oli.Id;
                    qli.UnitPrice = oli.UnitPrice;
                    qli.ER_Percentage__c = oli.ER_Percentage__c;
                    qli.Quantity = oli.Quantity;
                    qli.PricebookEntryId = oli.PricebookEntryId;
                    qli.ER_Card_Operational_System_ID__c = oli.ER_Card_Operational_System_ID__c;
                    qli.ER_Creation_date_in_OS__c = oli.ER_Creation_date_in_OS__c;
                    qli.ER_Minimum_Fee__c = oli.ER_Minimum_Fee__c;
                    qli.Discount = oli.Discount;
                    qli.ER_Line_Type__c = oli.ER_Line_Type__c;
                    qli.ER_Max__c = oli.ER_Max__c;
                    qli.ER_Min__c = oli.ER_Min__c;
                    qli.ER_What__c = oli.ER_What__c;
                    qli.ER_BUPicklist__c = oli.ER_BUPicklist__c;
                    qli.ER_Price_End_Date__c = oli.ER_Price_End_Date__c;
                    qli.ER_Price_Start_Date__c = oli.ER_Price_Start_Date__c;
                    qli.ER_Offer_validity_end_date__c = oli.ER_Offer_validity_end_date__c;
                    qli.ER_Duration__c = oli.ER_Duration__c;
                    qli.ER_User_Discount__c = oli.ER_User_Margin__c;
                    qli.ER_Edenred_Margin_TUR__c = oli.ER_Edenred_Margin_TUR__c;
                    qli.ER_Free_to_setup_the_margin__c = oli.ER_Free_To_Set_Margin__c;
                    qli.ER_MPV__c = oli.ER_MPV__c;
                    qli.ER_Cumulative_with_Promotions__c = oli.ER_Cumulative_with_promotions__c;    
                    qli.OpportunityLineItemId = oli.Id;          
                    qliList.add(qli);
                    
                }
                insert qliList;
            }
            
            currentOpportunity.id = opportunityId;
            currentOpportunity.StageName = Label.LABS_SF_Opp_Status_Proposal;
            
            update currentOpportunity;   
            
            newQuote.Status = Label.LABS_SF_Quote_Status_Accepted;
            update newQuote;
            
        }
        return String.valueOf(newQuote.Id);
    }
    
    public static void createContract(String quoteId){
        
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        Map<String, Date> mapProductEndDate = new Map<String, Date>();
        List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
        Map<String, Map<String, Boolean>> solutionDiscountAppliedMap = new Map<String, Map<String, Boolean>>();
        
        Quote quote = [SELECT Id, OpportunityId, Opportunity.ER_Contract_Expected_Start_Date__c, Opportunity.LeadSource, Opportunity.Contract_End_Date__c,Opportunity.Primary_Contact__c, Opportunity.Invoicing_Contact__c, AccountId,
                       Pricebook2Id, CurrencyIsoCode, RecordType.DeveloperName, ER_Credit_Limit__c, ER_Indexation_Index__c, ER_InvoicingFrequency__c,
                       ER_PaymentMethod__c, ER_PaymentTerms__c, Opportunity.ER_Solutions__c, ER_ReimbursementTerm__c, SK_Credit_Note_Frequency__c, SK_Payment_Terms_Voucher__c,
                       ER_Contract_Duration__c, ER_SEPA_Bank_Account__c, ER_Indexation__c, ER_Original_Agreement__c, ER_Quote_Type__c, OwnerId, Opportunity.ER_BUPicklist__c,
                       ERBE_Reimbursement_Statement_Frequency2__c, Opportunity.Creditting__c, ERBE_Reimbursement_Statement_Support2__c, ERBE_Weekly_Frequence__c, ER_Invoicing_payment_delay__c, ER_Invoicing_day_of_week__c FROM Quote WHERE Id=: quoteId];
        
        qliList = [SELECT Id, ListPrice, Discount, Opportunity_Product__c, UnitPrice, ER_What__c, CurrencyIsoCode, PricebookEntryId, Product2Id, Product2.Name, Quantity, ER_Percentage__c, ER_NeedApproval__c, Product2.ER_Solution2__r.ProductCode, 
            ER_Creation_date_in_OS__c, ER_Card_Operational_System_ID__c, ER_Minimum_Fee__c, ER_Line_Type__c, ER_Max__c, ER_Min__c, Quote.Opportunity.ER_Contract_Expected_Start_Date__c, ER_Offer_validity_end_date__c,
            Product2.RecordTypeId, ER_Duration__c, Product2.RecordType.Name, TECH_ContactStartDate__c, ER_Quantity_Unit_of_Measure__c, ER_Price_End_Date__c, Product2.ProductCode, Product2.ER_Type__c, 
            ER_Price_Start_Date__c, Quote.OwnerId, Quote.Opportunity.ER_BUPicklist__c, ER_User_Discount__c, ER_Edenred_Margin_TUR__c, ER_Free_to_setup_the_margin__c,
            ER_MPV__c, ER_Cumulative_with_Promotions__c FROM QuoteLineItem where QuoteId =:quoteId];
                           
        Contract newContract = new Contract();
        if (quote.RecordType.DeveloperName == 'ER_Client_Quote') {
            newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId();
        }
        newContract.ER_QuoteId__c = quote.Id;
        newContract.ER_OpportunityId__c = quote.OpportunityId;
        newContract.AccountId = quote.AccountId;
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
        newContract.StartDate = (quote.Opportunity.ER_Contract_Expected_Start_Date__c != null)
            ? quote.Opportunity.ER_Contract_Expected_Start_Date__c
            : Date.today();
        newContract.EndDate = quote.Opportunity.Contract_End_Date__c;
        newContract.Primary_Contact__c = quote.Opportunity.Primary_Contact__c;
        newContract.Billing_Contact__c = quote.Opportunity.Invoicing_Contact__c;
        newContract.Creditting__c = quote.Opportunity.Creditting__c;//Added 23 Nov, 2024
        newContract.ER_TerminationReason__c = 'Not Interested anymore';
        newContract.ER_BUPicklist__c = quote.Opportunity.ER_BUPicklist__c; 
        newContract.ER_Contract_Duration__c = quote.ER_Contract_Duration__c;
        newContract.ER_Solutions__c = quote.Opportunity.ER_Solutions__c;
        newContract.ERBE_Reimbursement_Statement_Frequency__c = quote.ERBE_Reimbursement_Statement_Frequency2__c;
        newContract.ERBE_Reimbursement_statement_Support__c = quote.ERBE_Reimbursement_Statement_Support2__c;
        newContract.ER_SEPA_Bank_Account__c = quote.ER_SEPA_Bank_Account__c;
        newContract.ERBE_Invoicing_day_of_week__c = quote.ER_Invoicing_day_of_week__c;
        newContract.ERBE_Invoicing_Payment_Delay__c = quote.ER_Invoicing_payment_delay__c;
        newContract.ERBE_Weekly_Frequence__c = quote.ERBE_Weekly_Frequence__c;
        newContract.CustomerSignedId = quote.Opportunity.Primary_Contact__c;
        newContract.CustomerSignedDate = System.today();
        insert newContract;
        
        Opportunity opp = new Opportunity(Id = newContract.ER_OpportunityId__c,ContractId = newContract.Id);
        update opp;

        Quote quoteObj = new Quote(Id = quoteId,ContractId = newContract.Id);
        update quoteObj;
        
        for (QuoteLineItem qli : qliList) {
            if (qli.ER_Line_Type__c == 'Discount') {
                if (qli.ER_Price_End_Date__c != null)
                    mapProductEndDate.put(qli.Product2.ProductCode, qli.ER_Price_End_Date__c);
                else if (qli.ER_Duration__c != null) {
                    Date contractStartDate = (qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c != null
                                              ? qli.Quote.Opportunity.ER_Contract_Expected_Start_Date__c
                                              : Date.today());
                    mapProductEndDate.put(
                        qli.Product2.ProductCode,
                        contractStartDate?.addDays(Integer.valueOf(qli.ER_Duration__c))
                    );
                }
            }
            if(!solutionDiscountAppliedMap.containsKey(qli.Product2.ER_Solution2__r.ProductCode)){
                solutionDiscountAppliedMap.put(qli.Product2.ER_Solution2__r.ProductCode, new Map<String, Boolean>());
                solutionDiscountAppliedMap.get(qli.Product2.ER_Solution2__r.ProductCode).put(qli.Product2.ProductCode, false);
                if(qli.Product2.ER_Type__c == 'Discount'){
                    solutionDiscountAppliedMap.get(qli.Product2.ER_Solution2__r.ProductCode).put(qli.Product2.ProductCode, true);
                }
            }else{
                if(!solutionDiscountAppliedMap.get(qli.Product2.ER_Solution2__r.ProductCode).containsKey(qli.Product2.ProductCode)){
                    solutionDiscountAppliedMap.get(qli.Product2.ER_Solution2__r.ProductCode).put(qli.Product2.ProductCode, false);
                }
                if(qli.Product2.ER_Type__c == 'Discount'){
                    solutionDiscountAppliedMap.get(qli.Product2.ER_Solution2__r.ProductCode).put(qli.Product2.ProductCode, true);
                }
            }

        }
        
        for(QuoteLineItem qli :  qliList){
            ER_ContractLineItem__c cli = new ER_ContractLineItem__c();
            cli.Name = qli.Product2.Name;
            cli.Opportunity_Product__c = qli.Opportunity_Product__c;
            cli.ER_Contract__c = newContract.Id;
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
            /*
            if (cli.ER_Line_Type__c == 'Discount')
                cli.ER_Price_End_Date__c = mapProductEndDate.get(qli.Product2.ProductCode);
            else if (cli.ER_Line_Type__c == 'Service')
                cli.ER_Price_Start_Date__c = mapProductEndDate.get(qli.Product2.ProductCode)?.addDays(1);
            else
                cli.ER_Price_End_Date__c = null;
			*/            
            cli.OwnerId = qli.Quote.OwnerId; 
            cli.ER_BUPicklist__c = qli.Quote.Opportunity.ER_BUPicklist__c; 
            
            cli.ER_User_Discount__c = qli.ER_User_Discount__c;
            cli.ER_Edenred_Margin_TUR__c = qli.ER_Edenred_Margin_TUR__c;
            cli.ER_Free_To_Set_Margin__c = qli.ER_Free_to_setup_the_margin__c;
            cli.ER_MPV__c = qli.ER_MPV__c;
            cli.Cumulative_with_Promotions__c = qli.ER_Cumulative_with_promotions__c;
            cli.ER_IsActive__c = true;
            if(solutionDiscountAppliedMap.get(qli.Product2.ER_Solution2__r.ProductCode).get(qli.Product2.ProductCode)){
                if(qli.Product2.ER_Type__c == 'Discount'){
                    cli.ER_IsActive__c  = true;
                }else{
                    cli.ER_IsActive__c  = false;
                }
            }else{
                if(qli.Product2.ER_Type__c != 'Discount'){
                    cli.ER_IsActive__c  = true;
                }else{
                    cli.ER_IsActive__c  = false;
                }
            }
            cliList.add(cli);
        }
        
        if(!cliList.isEmpty()){
            insert cliList;
        }
        
        if(newContract.ER_Contract_Type__c == Label.LAB_SF_Contact_Operational){
            GenericWithoutSharing.manageAccountLineItemsForContract(newContract);
            GenericWithoutSharing.manageFCLIForFinancialCenter(newContract);
            if (newContract.RecordTypeId == Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId()) {
                GenericWithoutSharing.manageDSLIFromContract(newContract);
                GenericWithoutSharing.manageDPLIFromContract(newContract);
            }
        }

        syncContract(newContract.Id);
        
    }

    @future(callout=true)
    public static void syncContract(String contractId){
        Contract contractObj = [SELECT Id, AccountId, Account.ER_Card_Client_Operational_System_ID__c from Contract where Id=:contractId];
        SyncClientContractService service = new SyncClientContractService();
        if(contractObj.Account.ER_Card_Client_Operational_System_ID__c != null){
            service.createClientContractCallout(contractObj.AccountId, contractObj.Id);
        }else{
            service.createClientCallout(contractObj.Id);
        }
    }

    public static void sendContractViaEmail(String contractId, Id accountId, String emailAddress, Id opportunityId, String stakeholderType, String productName, String additionalServices, String pageLanguage) {
        //Imalka : Send email with PDF attchement (2018-07-10)
        PageReference pdf;
        String product_fullname, pgLang, stakeholderTypePDF;

		stakeholderTypePDF = (stakeholderType == 'Customer') ? 'Client' : 'Merchant';
        if(pageLanguage.toLowerCase().equals('en_us')) pageLanguage='fr_be'; //by default
		pgLang = (pageLanguage.toLowerCase().equals('fr_be')) ? 'FR' : 'NL';
		pdf = new PageReference('/apex/PDF_BE_' +  productName + '_' + stakeholderTypePDF + '_Contract_' + pgLang);
		pdf.getParameters().put('language',pgLang);
		pdf.getParameters().put('productAcr', productName);
		
		switch on productName {
			when 'CVE' {	// CVE product
				product_fullname = (pgLang == 'FR') ? 'Chèque Consommation' : 'Consumptiecheque';
				pdf.getParameters().put('product_fullname',BE_ContractEmailGenerator.PRODUCT_CVE_DETAIL);
        }
			when 'ECE' {	// ECE product
				product_fullname = (pgLang == 'FR') ? 'Ticket Ecochèque' : 'Ticket EcoCheque';
                    pdf.getParameters().put('product_fullname',BE_ContractEmailGenerator.PRODUCT_ECE_DETAIL);
                }
			when 'TCE' {	// TCE product
                    product_fullname = 'Ticket Compliments';
                    pdf.getParameters().put('product_fullname',BE_ContractEmailGenerator.PRODUCT_TCE_DETAIL);
            }
			when 'TRE' {	// TRE product
                    product_fullname = 'Ticket Restaurant';
                    pdf.getParameters().put('product_fullname',BE_ContractEmailGenerator.PRODUCT_TRE_DETAIL);
            }
        }

        pdf.getParameters().put('local',pageLanguage);
        BE_ContractEmailGenerator.sendEmailWithECPDFAttachement(contractId, emailAddress, accountId, opportunityId, pdf,stakeholderType,product_fullname, pageLanguage.toLowerCase());
    }
}