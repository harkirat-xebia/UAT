/*
----------------------------------------------------------------------
-- - Name          : VFCER04_Opportunity_Product
-- - Author        : OLA
-- - Description   : The controller of the page VFER04_Opportunity_Product
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Dec-2018       OLA                 1.0         Initial version
--  MAY-2019       SDR                 1.1         SaveAsQuote method Update to match the CZ Requirement
--  FEB-2021       VJOY                2.0         Add mapping for discount and promo code
---------------------------------------------------------------------------------------
*/

global class VFCER04_Opportunity_Product {

    public String opportunityId { get; set; }
    public Opportunity opportunityRecord { get; set; }
    public List<String> opportunityFields;
    public Boolean pendingApproval { get; set; }
    public Boolean approved { get; set; }
    public Boolean derievedFromFrameworkContract { get; set; } //Added 27 Aug, 2024
    public Boolean hasAcceptedQuote { get; set; }
    public List<ProcessInstanceWorkitem> approvalProcessList { get; set; }
    public List<Quote> currentOpportunityQuoteList;
    public Quote acceptedQuote { get; set; }
    public List<Global_Settings__mdt> renderEstimationForBUSettings { get; set; } //Added on 6 September, 2024
    public Set<String> renderIssuedVolumeBUSet {get; set;} //Added on 6 September, 2024

    public VFCER04_Opportunity_Product(ApexPages.StandardController controller) {

        opportunityId = controller.getId();
        opportunityFields = new List<String>();
        opportunityFields.add('ER_Approved__c');
        opportunityFields.add('ER_NeedApproval__c');
        opportunityFields.add('HasOpportunityLineItem');
        opportunityFields.add('Derieved_from_Framework_Opp__c'); //Added 27 Aug, 2024
        opportunityFields.add('ER_BUPicklist__c'); //Added 6 Sep, 2024

        if(!Test.isRunningTest()) controller.addFields(opportunityFields);

        opportunityRecord = (Opportunity) controller.getRecord();
        approved = opportunityRecord.ER_Approved__c;
        derievedFromFrameworkContract = opportunityRecord.Derieved_from_Framework_Opp__c; //Added 27 Aug, 2024
        approvalProcessList = [
                select id, ProcessInstance.Status, ProcessInstance.TargetObjectId
                from ProcessInstanceWorkitem
                where ProcessInstance.TargetObjectId = :opportunityId
        ];
        currentOpportunityQuoteList = [
                select id, QuoteNumber, Status
                from Quote
                where opportunityId = :opportunityId and (Status != 'Draft' AND Status != 'Denied')
                order by createdDate desc
        ];
        if(!currentOpportunityQuoteList.isEmpty()) {
            acceptedQuote = currentOpportunityQuoteList[0];
            hasAcceptedQuote = true;
        }
        if(!approvalProcessList.isEmpty()) {
            pendingApproval = true;
        }
        /** Changes made on 09 September 2024 by Pranjal Tiwari */
        renderIssuedVolumeBUSet = new Set<String>();
        renderEstimationForBUSettings = [SELECT MasterLabel, Business_Unit__c, Active__c FROM Global_Settings__mdt WHERE MasterLabel LIKE '%OPPORTUNITY_PRODUCT_ISSUED_VOLUME%' AND Active__c = true];
            for(Global_Settings__mdt gs : renderEstimationForBUSettings){
                renderIssuedVolumeBUSet.add(gs.Business_Unit__c);
            }
        /** End */
    }

    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description editPrice : redirect to VFER05_Opportunity_EditPrice Page.
    */
    public PageReference editPrice() {

        PageReference pageRef = new PageReference('/apex/VFER05_Opportunity_EditPrice?id=' + opportunityId);
        pageRef.setRedirect(true);
        return pageRef;
    }

    /**
    * @author Noor
    * @date 01/06/2022 (dd/mm/yyyy)
    * @description estimate : redirect to VFER14_Opportunity_Estimate Page.
    */
    public PageReference calculateEstimate() {

        PageReference pageRef = new PageReference('/apex/VFER14_Opportunity_Estimate?id=' + opportunityId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    /**
     * @author Oussama LASFAR
     * @date 27/12/2018 (dd/mm/yyyy)
     * @description getOpportunityProducts : display all the opportunity Products grouped by solutions.
     * @param opportunityId
     * @return List<opportunityLineItem>
    */
    @RemoteAction
    global static List<OpportunityLineItem> getOpportunityProducts(String opportunityId) {

        List<OpportunityLineItem> oppProductList;
        oppProductList = [SELECT Id, Name, UnitPrice, ER_Percentage__c, ER_NeedApproval__c, PricebookEntry.Name, Product2.ER_Solution2__c, Product2.ER_Solution2__r.Name,
                        Product2.Description, Product2.ER_Solution__r.Name, ListPrice, CurrencyIsoCode, Product2.ER_Type__c, Product2.ER_Solution2__r.ER_Type__c,
                        ER_Price_End_Date__c, ER_Offer_validity_end_date__c, Product2.ER_Solution__r.ER_Type__c,
                        Opportunity.ER_NeedApproval__c, Opportunity.ER_Approved__c, ER_Minimum_Fee__c, Discount,
                        Opportunity.ER_Business_Unit__c, PricebookEntry.ER_Min__c, PricebookEntry.ER_Max__c, ER_BUPicklist__c,
                        PricebookEntry.ER_Offer_validity_end_date__c, PricebookEntry.ER_Price_End_Date__c, ER_What__c, ER_Duration__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
                ORDER BY Product2.ER_Solution2__r.ER_Line_Order__c,Product2.ER_Line_Order__c ASC
        ];
        for(OpportunityLineItem oppLine: oppProductList){
            
		System.debug('IMTest: ' + oppLine);
        }
        return oppProductList;
    }

    /**
    * @author Dragos Avram
     * @date 16/04/2021 (dd/mm/yyyy)
    * @description checkExistingContract : on save quote check if the solution exist already in another opperational contract
     * @param accountId, oppProductList
     * @return void
    */

    /*public static void checkExistingContract(String accountId, List<OpportunityLineItem> oppProductList){
        String errorString;
        Map<String,Contract> solutionMap = new  Map<String, Contract>();
        List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('Bypass_Active_Contract_Process'));

        for (Contract con : [Select id, contractNumber, (Select id, ER_solution__c, ER_ProductCode__c, ER_Contract__r.ContractNumber,ER_Product2__r.ER_solution__c, ER_Product2__r.ER_solution__r.Name From ER_contractLineitems__r )
        From Contract
        Where AccountId = : accountId and Status = 'Activated'  AND ER_Contract_Type__c =: oppProductList[0].Opportunity.Type AND ER_Business_Unit__c NOT IN :bus]) {
            for(ER_ContractLineItem__c cli : con.ER_ContractLineItems__r){
                if (!solutionMap.containsKey(cli.ER_ProductCode__c) && String.isNotBlank(cli.ER_Product2__r.ER_solution__c)) {
                    solutionMap.put(cli.ER_ProductCode__c, con);
                }
            }

        }
        for(OpportunityLineItem oli : oppProductList){
            if(solutionMap.containsKey(oli.ProductCode)){
               errorString = Label.LABS_SF_Opp_Price_ProductExistInContract;
                errorString = errorString.replace('{0}', oli.ProductCode).replace('{1}', oli.ProductCode).replace('{2}', '/' + solutionMap.get(oli.ProductCode).Id).replace('{3}', solutionMap.get(oli.ProductCode).ContractNumber);
               throw new VisualforceException(errorString);

            }
        }

    }*/

    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description saveAsQuote :
    * If an opportunity products need approval: launch automatically an approval process
    * else create quote and clone all the opportunity products + change opportunity stage to proposal
     * @param opportunityId
     * @return Quote
    */
    @RemoteAction
    global static Quote saveAsQuote(String opportunityId) {

        Boolean opportunityNeedApproval = false;
        Boolean oliIsCardOrPaper = false;
        Boolean oppNeedFinancialApproval = false;

        List<opportunityLineItem> oppProductList;
        List<quoteLineItem> qliList = new List<quoteLineItem>();
        Opportunity currentOpportunity = new Opportunity();
        QuoteLineItem qli;
        List<OpportunityContactRole> ocrList;
        Set<Id> excludedOpportunities = new Set<Id>();
        //set<string> reimbursementTerms = new Set<String>{'3 days', '4 days', '5 days'};
        //Id merchantRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Opportunity').getRecordTypeId();

        // Validation added by harkirat on 14/4/26
        Opportunity opp = [
                SELECT Id, Commercial_Origin__c, ER_Contract_Expected_Start_Date__c, 
                    ER_NeedApproval__c, ER_BUPicklist__c, ER_NeedFinancialApproval__c,
                    Finance_Approval_Status__c, ER_Need_Financial_Approval_2__c, Pricebook2Id, Pricebook2.Name
                FROM Opportunity 
                WHERE Id = :opportunityId
            ];

        if (String.isBlank(opp.Commercial_Origin__c) || opp.ER_Contract_Expected_Start_Date__c == null) {
        throw new VisualforceException('Please fill in Commercial Origin and Contract Expected Start Date before creating a quote.');
    }
    // validation ends
    
        
    // New validation for Engagement opportunities - CSM assignment check
    //Commenting as business doesn't need this anymore
    /*if (opp.Pricebook2Id != null && 
        opp.Pricebook2.Name != null && 
        opp.Pricebook2.Name.containsIgnoreCase('Engagement')) {
        
        // Query for Customer Succes Engagement team member with Edit access
        List<OpportunityTeamMember> csmTeamMembers = [
            SELECT Id, UserId, TeamMemberRole, OpportunityAccessLevel
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opportunityId
            AND TeamMemberRole = 'Customer Succes Engagement'
            AND OpportunityAccessLevel = 'Edit'
            LIMIT 1
        ];  
        
        // If no CSM with Edit access is found, throw an error
        if (csmTeamMembers.isEmpty()) {
            throw new VisualforceException('A Customer Success Engagement team member with Edit access must be assigned to this Engagement opportunity before creating a quote.');
        }
    }*/
        //new validation ends

        //get the list of the opportunity Product
        oppProductList = [
                SELECT id, Name, UnitPrice, Discount, ER_Percentage__c, Quantity, ER_NeedApproval__c, Has_Auto_Discount__c, Opportunity.Derieved_from_Framework_Opp__c ,
                        Product2.ER_Solution_Type__c, Product2.ER_Type__c, Opportunity.RecordType.DeveloperName, Opportunity.Finance_Approval_Status__c,
                        Opportunity.Name, Opportunity.OwnerId, PricebookEntryId, Opportunity.pricebook2Id,
                        PricebookEntry.Name, Product2.Description, Product2.ER_Solution__r.Name, Opportunity.Type,
                        Product2.ER_solution__r.ER_Type__c, Product2.ER_solution__r.ER_Solution_Type__c, ListPrice,
                        CurrencyIsoCode, ER_Card_Operational_System_ID__c, ER_Creation_date_in_OS__c, Opportunity.ER_SEPA_Bank_Account__c,
                        Opportunity.ER_PaymentTerms__c, Opportunity.ER_InvoicingFrequency__c, Opportunity.ER_PaymentMethod__c,
                        Opportunity.ER_ReimbursementTerm__c, Opportunity.ER_Business_Unit__c, ER_Minimum_Fee__c, Opportunity.ER_BUPicklist__c,
                        Opportunity.ER_NeedFinancialApproval__c, Opportunity.Primary_Contact__c, ER_Line_Type__c, ER_Max__c, ER_Min__c, ER_BUPicklist__c,
                        ER_Price_End_Date__c, ER_Offer_validity_end_date__c, ER_Duration__c, ER_What__c, Opportunity.ER_Original_Agreement__c,
            			Opportunity.ER_BU_Picklist__c, Product2.Name, Opportunity.ER_VAT__c, Product2.ER_Solution__r.ProductCode, Product2.ProductCode,
						Opportunity.ERBE_Invoicing_Support__c, Opportunity.ER_Validity_channel__c, Opportunity.ER_Validity_Period__c, Opportunity.Pricebook2.ER_MDMId__c,
                        ER_Edenred_Margin_TUR__c, ER_User_Margin__c, ER_Free_To_Set_Margin__c, ER_MPV__c, ER_Cumulative_with_Promotions__c, ER_Price_Start_Date__c,Opportunity.ER_Need_Financial_Approval_2__c
                FROM opportunityLineItem
                WHERE opportunityId = :opportunityId
                ORDER BY product2.ER_solution__r.ER_Line_Order__c, product2.ER_Line_Order__c
        ];

        ocrList = [
                SELECT OpportunityId, role, contactId,
                        isprimary, contact.Email, contact.Phone
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId AND isprimary = true
        ];

        System.debug('>>> SaveAsQuote - oppProductList size ' + oppProductList.size());
        
        if(!oppProductList.isEmpty()) {

            //Initialise de Quote
            Savepoint sp = Database.setSavepoint();

            Quote newQuote = new Quote();
            if(!ocrList.isEmpty()) {
                newQuote.ContactId = ocrList[0].ContactId;
                newQuote.Email = ocrList[0].contact.Email;
                newQuote.Phone = ocrList[0].contact.Phone;
            }
            //ALK - 10/03/2021 - This will be replaced by the new naming convention (devops : 10621)
            //newQuote.Name = Datetime.now().format('yyyy-MM-dd') + '-' + oppProductList[0].Opportunity.name;
            newQuote.OwnerId = oppProductList[0].Opportunity.ownerId;
            newQuote.OpportunityId = opportunityId;
            newQuote.ER_Quote_Type__c = oppProductList[0].Opportunity.Type;
            newQuote.pricebook2Id = oppProductList[0].Opportunity.pricebook2Id;
            newQuote.ER_Original_Agreement__c = oppProductList[0].Opportunity.ER_Original_Agreement__c;
            newQuote.ER_SEPA_Bank_Account__c = oppProductList[0].Opportunity.ER_SEPA_Bank_Account__c;
            if(oppProductList[0].Opportunity.RecordType.DeveloperName == 'ER_Merchant_Opportunity') {
                newQuote.recordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Quote').getRecordTypeId();
            } else if(oppProductList[0].Opportunity.RecordType.DeveloperName == 'ER_Client_Opportunity_RT') {
                newQuote.recordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('ER_Client_Quote').getRecordTypeId();
            }
            newQuote.expirationDate = Date.today().addMonths(1);
            
			/*PBI 13389 VJOY*/
            newQuote.ERBE_Invoicing_Support__c = oppProductList[0].Opportunity.ERBE_Invoicing_Support__c;

            /*Added Snehil 26/11/24 */
            newQuote.ContactId = oppProductList[0].Opportunity.Primary_Contact__c;
            newQuote.ER_BUPicklist__c = oppProductList[0].Opportunity.ER_BUPicklist__c;

            System.debug('newQuote:: ' + newQuote);
            insert newQuote;

            for(opportunityLineItem oli : oppProductList) {
                if (oli.Has_Auto_Discount__c) {
                    excludedOpportunities.add(oli.OpportunityId);
                }
            }

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
                /*PBI 7485: VJOY 2021*/
                qli.ER_Price_End_Date__c = oli.ER_Price_End_Date__c;
                qli.ER_Price_Start_Date__c = oli.ER_Price_Start_Date__c;

                qli.ER_Offer_validity_end_date__c = oli.ER_Offer_validity_end_date__c;
                qli.ER_Duration__c = oli.ER_Duration__c;

                /*PBI14186 VJOY JAN 2022*/
				qli.ER_User_Discount__c = oli.ER_User_Margin__c;
                qli.ER_Edenred_Margin_TUR__c = oli.ER_Edenred_Margin_TUR__c;
                qli.ER_Free_to_setup_the_margin__c = oli.ER_Free_To_Set_Margin__c;
				qli.ER_MPV__c = oli.ER_MPV__c;
                qli.ER_Cumulative_with_Promotions__c = oli.ER_Cumulative_with_promotions__c;

                /*Added Snehil 21-11-2024*/
                qli.OpportunityLineItemId = oli.Id;
                              
                qliList.add(qli);

                if(oli.ER_NeedApproval__c && !excludedOpportunities.contains(oli.OpportunityId) && !oli.opportunity.Derieved_from_Framework_Opp__c) {

                    opportunityNeedApproval = true;
                    break;
                }

                if(oli.Opportunity.ER_Business_Unit__c == 'CZ' && oli.Product2.ER_solution__r.ER_Type__c == Label.LABS_SF_Product_Type_Solution && oli.Opportunity.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Opportunity').getRecordTypeId() && (oli.Product2.ER_solution__r.ER_Solution_Type__c == Label.LABS_SF_Product_Card_Solution_Type && (oli.Opportunity.ER_PaymentTerms__c == null || oli.Opportunity.ER_InvoicingFrequency__c == null || oli.Opportunity.ER_PaymentMethod__c == null)) || (oli.Opportunity.ER_Business_Unit__c == 'CZ' && oli.Product2.ER_solution__r.ER_Solution_Type__c == Label.LABS_SF_Product_PaperVoucher_Solution_Type && oli.Opportunity.ER_ReimbursementTerm__c == null)) {
                    oliIsCardOrPaper = true;
                    System.debug('Boolean Part');
                    break;
                }

                if(oli.Product2.ER_Solution__r.ProductCode == Label.LAB_SF_P2_VOUCHER_CODE && (oli.Opportunity.ER_Validity_channel__c == null || oli.Opportunity.ER_Validity_Period__c == null)) {
                    Database.rollback(sp);
                    throw new VisualforceException(Label.LAB_SF_OPP_EKIVITA_VALIDITY_ERR_MSG);
                }
                
                if(oli.Product2.ER_Solution__r.ProductCode == Label.LAB_SF_P2_OOP && oli.Opportunity.ER_VAT__c == null) {
                    Database.rollback(sp);
                    throw new VisualforceException(Label.LABS_SF_OPP_OOP_VAR_ERR);    
                }
                                
            }

            if(oliIsCardOrPaper) {

                Database.rollback(sp);
                throw new VisualforceException(Label.LABS_SF_Opp_Financial_Conditions_Error_Msg);//this value will be cought in vfp side. no need to use a custom label

            }
            //BUG-10623: launch both financial and commercial approval processes in same place while clicking on "save As Quote"
            Opportunity currentOpp = oppProductList[0].Opportunity;
             /*
            if ((currentOpp.ER_PaymentTerms__c != Label.LABS_SF_ER_PaymentTerms || reimbursementTerms.contains(currentOpp.ER_ReimbursementTerm__c))
                    && currentOpp.RecordTypeId == merchantRecordTypeId && currentOpp.ER_BU_Picklist__c == 'CZ'
                    &&  currentOpp.ER_ReimbursementTerm__c != null && currentOpp.ER_PaymentTerms__c != null) {
                oppNeedFinancialApproval = true;
            } */
            if(currentOpp.ER_NeedFinancialApproval__c && currentOpp.Finance_Approval_Status__c !='Approved'){
                    oppNeedFinancialApproval = true;
             }
                                        
            if(opportunityNeedApproval) {
                System.debug('IML: Se necesita aprobación');
                Database.rollback(sp);
                throw new VisualforceException('Need Approval');//this value will be cought in vfp side. no need to use a custom label
            } else if(oppNeedFinancialApproval && !Test.isRunningTest()) {
                Database.rollback(sp);
                throw new VisualforceException('Need Financial Approval');
            }else {

                insert qliList;

                currentOpportunity.id = opportunityId;
                currentOpportunity.StageName = Label.LABS_SF_Opp_Status_Proposal;

                update currentOpportunity;

                return newQuote;
            }
        }

        return null;
    }

    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description updateOpportunity : if at least one of the opportunity products need approval, then change the ER_NeedApproval__c field value to true.
     * @param approvalComment
     * @param needApproval
     * @param opportunityId
     * @return Boolean
    */
    @RemoteAction
    global static Boolean updateOpportunity(String opportunityId, String approvalComment, Boolean needApproval) {
        if (needApproval) {
            Boolean hasPrimaryContact = [
                SELECT COUNT()
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                AND Role = 'Primary contact'
            ] > 0;
    
            Opportunity opp = new Opportunity(Id = opportunityId, ER_NeedApproval__c = true);
    
            if (!hasPrimaryContact) {
                Database.update(opp, true); 
            } else {
                Database.update(opp, false);
            }
        }
        return submitForApproval(opportunityId, approvalComment);
    }
    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description submitForApproval : launch approval process Merchant_sales_approval.
     * @param opportunityId
     * @param approvalComment
     * @return Boolean
    */
    @RemoteAction
    global static Boolean submitForApproval(String opportunityId, String approvalComment) {

        Opportunity opp = [SELECT Id, ER_BUPicklist__c, ER_NeedApproval__c, ER_Need_Financial_Approval_2__c, Finance_Approval_Status__c, ER_NeedFinancialApproval__c FROM Opportunity WHERE Id = :OpportunityId];

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(approvalComment);
        req1.setObjectId(opportunityId);

        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId());
        system.debug('####KHAD opp.ER_NeedApproval__c : '+opp.ER_NeedApproval__c);
        system.debug('####KHAD opp.ER_BUPicklist__c : '+opp.ER_BUPicklist__c);
        if(opp.ER_BUPicklist__c == 'CZ') {

            //req1.setProcessDefinitionNameOrId('ER_CZ_Opportunity_Approval_Process');

        } else if(opp.ER_BUPicklist__c == 'SK') {
            system.debug('ersk approval');
            //req1.setProcessDefinitionNameOrId('ER_SK_Opportunity_Approval_Process');

        }else if(opp.ER_BUPicklist__c == 'FI') {
            system.debug('erfi approval');
            //req1.setProcessDefinitionNameOrId('ER_FI_Opportunity_Approval_Process');

        }else if(opp.ER_BUPicklist__c=='GR') {
            system.debug('ergr approval');
            //req1.setProcessDefinitionNameOrId('ER_GR_Opportunity_Approval_Process');

        }else if(opp.ER_NeedFinancialApproval__c) {
            req1.setProcessDefinitionNameOrId('ER_Opp_Finance_approval_process');

        } else {
            system.debug('standard approval');
            req1.setProcessDefinitionNameOrId('Benefits_Reduction_fee_Approval');

        }

        //req1.setSkipEntryCriteria(true);
        if(!Test.isRunningTest()) {
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            if(result.isSuccess()) {
                System.debug('Submitted for approval successfully: ' + result.isSuccess());
                return true;
            } else {
                System.debug('Submitted for approval error : ' + result.getErrors());
            }
        }
        return false;
    }

    public class VisualforceException extends Exception {
    }
}