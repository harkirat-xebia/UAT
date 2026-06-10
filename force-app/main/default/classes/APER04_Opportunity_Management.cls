/*
----------------------------------------------------------------------
-- - Name          : APER04_Opportunity_Management
-- - Author        : OLA
-- - Description   : User Management, This class is used to group all the functionnality linked to the object Opportunity()
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  JAN-2019    OLA                 1.0         Initial version
--  APR-2021	KHAD				2.0			Add Opp naming convention
---------------------------------------------------------------------------------------
*/
public class APER04_Opportunity_Management {
    public static void updateOpportunityStage(Set<Id> opportunityIds, String stageName) {
        List<Opportunity> opportunityListToUpdate = new List<Opportunity>();
        Opportunity opportunityToUpdate = new Opportunity();
  
      for (Id opportunityId : opportunityIds) {
            opportunityToUpdate = new Opportunity(Id = opportunityId);
            opportunityToUpdate.StageName = stageName;
            opportunityListToUpdate.add(opportunityToUpdate);
        }
      if (!opportunityListToUpdate.isEmpty()) {
            update opportunityListToUpdate;
        }
    }
  
    /**
     * @description update opportunty contract
     * @param opportunityList
     */
    public static void updateOpportunityContract(List<Opportunity> opportunityList) {
        update opportunityList;
    }
  
    /**
     * @description get Opportunty record by Id
     * @param opportunityId
     *
     * @return
     */
    @AuraEnabled
    public static List<Opportunity> getOpportunityRecord(String opportunityId) {
        return [
                SELECT
          Id,
          Name,
          AccountId,
          StageName,
          CloseDate,
          Pricebook2Id,
          CurrencyIsoCode,
          ER_IsAmended__c,
          ER_InvoicingFrequency__c,
          ER_PaymentTerms__c,
          ER_PaymentMethod__c,
          ER_ReimbursementTerm__c,
          ER_Reason__c
                FROM Opportunity
                WHERE Id = :opportunityId
        ];
    }
  
    /**
     * @author ALK
     * @description discard amendment
     * @param opportunityId
     */
    @AuraEnabled
    public static void discardAmendement(String opportunityId) {
        List<SObject> objectToDelete = new List<SObject>();
        //Check if opportunity has quote which is not in draft
      for (zqu__Quote__c zQuote : [
                SELECT Id, zqu__Status__c
                FROM zqu__Quote__c
                WHERE zqu__Opportunity__c = :opportunityId
        ]) {
            //if quote is not in draft display error message else delete them
        if (!zQuote.zqu__Status__c.equalsIgnoreCase('Draft'))
                throw new AuraHandledException(Label.LAB_SF_DISCARD_OPP_ERROR);
            objectToDelete.add(zQuote);
        }
        objectToDelete.add(new Opportunity(Id = opportunityId));
  
        delete objectToDelete;
    }
  
    /*
     * LASFAR
     * 14/02/2019
     * createOpportunityFromContract : Create new Opportunity from the current contract (contract came from data init)
     */
    public static Opportunity createOpportunityFromContract(String contractId, String opportunityId) {
    Opportunity newOpp;
    OpportunityLineItem oli;
    List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
    Boolean userCanAmend = false;

    try {
        //New updated query by harkirat for the bug zahira raised, ticket - 2331
        List<ER_ContractLineItem__c> contractLineItems = [SELECT Id, ER_Product2__c, Opportunity_Product__c, ER_Product2__r.No_Of_Beneficiaries__c, ER_Product2__r.Load_Per_Year__c, ER_Product2__r.Days_per_Month__c, ER_Product2__r.Face_Value__c, Opportunity_Product__r.ER_Nb_Beneficiaries__c, Opportunity_Product__r.ER_Load_Per_Year__c, Opportunity_Product__r.ER_Days_Per_Month__c, Opportunity_Product__r.ER_Face_Value__c FROM ER_ContractLineItem__c WHERE ER_Contract__c = :contractId ];
        Map<Id, Map<String, Object>> dataMap = fetchOpportunityLineItemData(contractLineItems, opportunityId);

        // Preload OCRs (if cloning is needed)
        List<OpportunityContactRole> existingOCRs = new List<OpportunityContactRole>();
        if (String.isNotBlank(opportunityId)) {
            existingOCRs = [
                SELECT ContactId, Role, IsPrimary
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
            ];
        }

        List<OpportunityContactRole> newOCRs = new List<OpportunityContactRole>();

        // Fetch contract and line items
        List<Contract> contracts = [
            SELECT
                Id,
                RecordType.DeveloperName,
                AccountId,
                Account.NumberOfEmployees,
                Account.Name,
                ER_OpportunityId__r.ER_Estimated_Number_Of_Beneficiaries__c,
                Pricebook2Id,
                CurrencyIsoCode,
                ER_Business_Unit__c,
                ER_Credit_Limit2__c,
                ERBE_Reimbursement_Statement_Frequency__c,
                SK_Payment_Terms_Voucher2__c,
                ER_PaymentMethod2__c,
                ER_PaymentTerms2__c,
                ER_Indexation_Index2__c,
                ER_OppIndexation2__c,
                ER_Loads_Per_Year__c,
                ERBE_Reimbursement_statement_Support__c,
                SK_Credit_Note_Frequency2__c,
                ER_ReimbursementTerm2__c,
                ER_InvoicingFrequency2__c,
                ER_Contract_Type__c,
                Creditting__c,
                Subscription__c,
                ER_SEPA_Bank_Account__c,
                ERBE_Weekly_Frequence__c,
                ERBE_Invoicing_Payment_Delay__c,
                ERBE_Invoicing_day_of_week__c,
                ER_BUPicklist__c,
                ER_SmartER_Context__c,
                Billing_Contact__c,
                Primary_Contact__c,
                ER_OpportunityId__r.Product_of_Interest__c,
                (
                    SELECT
                        Id,
                        ER_NeedApproval__c,
                        ER_ListPrice__c,
                        ER_UnitPrice__c,
                        CurrencyIsoCode,
                        ER_PricebookEntryId__c,
                        ER_Quantity__c,
                        ER_Percentage__c,
                        ER_Card_Operational_System_ID__c,
                        ER_Creation_date_in_OS__c,
                        ER_Discount__c,
                        ER_Minimum_Fee__c,
                        ER_Product2__c,
                        ER_Line_Type__c,
                        ER_Max__c,
                        ER_Min__c,
                        ER_Offer_validity_end_date__c,
                        ER_Edenred_Margin_TUR__c,
                        ER_Free_To_Set_Margin__c,
                        ER_MPV__c,
                        Cumulative_with_Promotions__c,
                        ER_BUPicklist__c,
                        ER_Product2__r.Name, 
                        Opportunity_Product__c,
                        ER_Product2__r.No_Of_Beneficiaries__c,
                        ER_Product2__r.Load_Per_Year__c,
                        ER_Product2__r.Days_per_Month__c,
                        ER_Product2__r.Face_Value__c,
                        Opportunity_Product__r.ER_Nb_Beneficiaries__c,
                        Opportunity_Product__r.ER_Load_Per_Year__c,
                        Opportunity_Product__r.ER_Days_Per_Month__c,
                        Opportunity_Product__r.ER_Face_Value__c
                    FROM ER_ContractLineItems__r WHERE ER_Product2__r.ER_Type__c != 'Discount'
                )
            FROM Contract
            WHERE Id = :contractId AND ER_Business_Unit__c = :APER10_User_Management.userBU
        ];

        for (Contract contractInst : contracts) {
            userCanAmend = true;

            if (String.isNotBlank(opportunityId)) {
                List<Opportunity> linkedOpportunity = APER04_Opportunity_Management.getOpportunityRecord(opportunityId);
                if (!linkedOpportunity.isEmpty()) {
                    newOpp = linkedOpportunity[0].clone(false, true, false, false);
                    newOpp.Name = 'AM';
                    newOpp.StageName = Label.LABS_SF_Opp_Status_Qualification;
                    newOpp.CloseDate = Date.today().addMonths(1);
                    newOpp.ER_AmendedFromContract__c = contractInst.Id;
                    newOpp.ER_InvoicingFrequency__c = contractInst.ER_InvoicingFrequency2__c;
                    newOpp.ER_ReimbursementTerm__c = contractInst.ER_ReimbursementTerm2__c;
                    newOpp.SK_Credit_Note_Frequency__c = contractInst.SK_Credit_Note_Frequency2__c;
                    newOpp.Creditting__c = contractInst.Creditting__c;
                    newOpp.ER_Indexation__c = contractInst.ER_OppIndexation2__c;
                    newOpp.ER_Indexation_Index__c = contractInst.ER_Indexation_Index2__c;
                    newOpp.ER_PaymentTerms__c = contractInst.ER_PaymentTerms2__c;
                    newOpp.ER_PaymentMethod__c = contractInst.ER_PaymentMethod2__c;
                    newOpp.ER_Loads_Per_Year__c = contractInst.ER_Loads_Per_Year__c;
                    newOpp.Primary_Contact__c = contractInst.Primary_Contact__c;
                    newOpp.Invoicing_Contact__c = contractInst.Billing_Contact__c;
                    newOpp.Product_of_Interest__c = contractInst.ER_OpportunityId__r.Product_of_Interest__c;
                    newOpp.ER_Estimated_Number_Of_Beneficiaries__c = contractInst.ER_OpportunityId__r.ER_Estimated_Number_Of_Beneficiaries__c;
                    newOpp.Type = String.isNotBlank(contractInst.ER_Contract_Type__c) ? contractInst.ER_Contract_Type__c : Label.LABS_SF_Opportunity_Type_Operational;
                    newOpp.SK_Payment_Terms_Voucher__c = contractInst.SK_Payment_Terms_Voucher2__c;
                    newOpp.ER_Credit_Limit__c = contractInst.ER_Credit_Limit2__c;
                    newOpp.ER_SEPA_Bank_Account__c = contractInst.ER_SEPA_Bank_Account__c;
                    newOpp.ERBE_Weekly_Frequence__c = contractInst.ERBE_Weekly_Frequence__c;
                    newOpp.ERBE_Invoicing_Payment_Delay__c = contractInst.ERBE_Invoicing_Payment_Delay__c;
                    newOpp.ERBE_Invoicing_day_of_week__c = contractInst.ERBE_Invoicing_day_of_week__c;
                    newOpp.ER_BUPicklist__c = contractInst.ER_BUPicklist__c;
                    newOpp.ER_SmartER_Context__c = contractInst.ER_SmartER_Context__c;
                }
            }

            if (newOpp == null) {
                newOpp = new Opportunity();
                newOpp.Name = 'AM';
                newOpp.AccountId = contractInst.AccountId;
                newOpp.ER_AmendedFromContract__c = contractInst.Id;
                newOpp.ER_InvoicingFrequency__c = contractInst.ER_InvoicingFrequency2__c;
                newOpp.ER_ReimbursementTerm__c = contractInst.ER_ReimbursementTerm2__c;
                newOpp.SK_Credit_Note_Frequency__c = contractInst.SK_Credit_Note_Frequency2__c;
                newOpp.ER_Indexation__c = contractInst.ER_OppIndexation2__c;
                newOpp.ER_Indexation_Index__c = contractInst.ER_Indexation_Index2__c;
                newOpp.Creditting__c = contractInst.Creditting__c;
                newOpp.ER_PaymentTerms__c = contractInst.ER_PaymentTerms2__c;
                newOpp.ER_PaymentMethod__c = contractInst.ER_PaymentMethod2__c;
                newOpp.SK_Payment_Terms_Voucher__c = contractInst.SK_Payment_Terms_Voucher2__c;
                newOpp.ER_Loads_Per_Year__c = contractInst.ER_Loads_Per_Year__c;
                newOpp.ER_Credit_Limit__c = contractInst.ER_Credit_Limit2__c;
                newOpp.Pricebook2Id = contractInst.Pricebook2Id;
                newOpp.StageName = Label.LABS_SF_Opp_Status_Qualification;
                newOpp.CloseDate = Date.today().addMonths(1);
                newOpp.ERBE_Reimbursement_Statement_Frequency__c = contractInst.ERBE_Reimbursement_Statement_Frequency__c;
                newOpp.ERBE_Reimbursement_Statement_Support__c = contractInst.ERBE_Reimbursement_statement_Support__c;
                newOpp.Primary_Contact__c = contractInst.Primary_Contact__c;
                newOpp.Invoicing_Contact__c = contractInst.Billing_Contact__c;
                newOpp.ER_Nb_of_Employees__c = contractInst.Account.NumberOfEmployees;
                newOpp.Type = String.isNotBlank(contractInst.ER_Contract_Type__c) ? contractInst.ER_Contract_Type__c : Label.LABS_SF_Opportunity_Type_Operational;
                newOpp.CurrencyIsoCode = contractInst.CurrencyIsoCode;
                newOpp.ER_SEPA_Bank_Account__c = contractInst.ER_SEPA_Bank_Account__c;
                newOpp.ERBE_Weekly_Frequence__c = contractInst.ERBE_Weekly_Frequence__c;
                newOpp.ERBE_Invoicing_Payment_Delay__c = contractInst.ERBE_Invoicing_Payment_Delay__c;
                newOpp.ERBE_Invoicing_day_of_week__c = contractInst.ERBE_Invoicing_day_of_week__c;
                newOpp.ER_BUPicklist__c = contractInst.ER_BUPicklist__c;
                newOpp.ER_SmartER_Context__c = contractInst.ER_SmartER_Context__c;
            }

            if (contractInst.RecordType.DeveloperName == 'ER_Client_Contract_RT') {
                newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Client_Opportunity_RT').getRecordTypeId();
            } else if (contractInst.RecordType.DeveloperName == 'ER_Merchant_Contract_RT') {
                newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Opportunity').getRecordTypeId();
            }
            newOpp.Primary_Contact__c = NULL;
            newOpp.Invoicing_Contact__c = NULL;

            insert newOpp;

            // Clone OCRs from original Opportunity
            for (OpportunityContactRole ocr : existingOCRs) {
                OpportunityContactRole newOCR = new OpportunityContactRole();
                newOCR.OpportunityId = newOpp.Id;
                newOCR.ContactId = ocr.ContactId;
                newOCR.Role = ocr.Role;
                newOCR.IsPrimary = ocr.IsPrimary;
                newOCRs.add(newOCR);
            }

            if (
                !Schema.SObjectType.Contract.fields.Subscription__c.isAccessible() ||
                (Schema.SObjectType.Contract.fields.Subscription__c.isAccessible() && contractInst.Subscription__c == null)
            ) {
                for (ER_ContractLineItem__c cli : contractInst.ER_ContractLineItems__r) {
                    oli = new OpportunityLineItem();

                    oli.OpportunityId = newOpp.Id;
                    oli.UnitPrice = cli.ER_UnitPrice__c;
                    oli.PricebookEntryId = cli.ER_PricebookEntryId__c;
                    oli.Quantity = cli.ER_Quantity__c;
                    oli.ER_Percentage__c = cli.ER_Percentage__c;
                    oli.ER_NeedApproval__c = cli.ER_NeedApproval__c;
                    oli.ER_Card_Operational_System_ID__c = cli.ER_Card_Operational_System_ID__c;
                    oli.ER_Minimum_Fee__c = cli.ER_Minimum_Fee__c;
                    oli.Discount = cli.ER_Discount__c;
                    oli.Product2Id = cli.ER_Product2__c;
                    oli.ER_Line_Type__c = cli.ER_Line_Type__c;
                    oli.ER_Max__c = cli.ER_Max__c;
                    oli.ER_Min__c = cli.ER_Min__c;
                    oli.ER_Offer_validity_end_date__c = cli.ER_Offer_validity_end_date__c;
                    oli.ER_Edenred_Margin_TUR__c = cli.ER_Edenred_Margin_TUR__c;
                    oli.ER_Free_To_Set_Margin__c = cli.ER_Free_To_Set_Margin__c;
                    oli.ER_MPV__c = cli.ER_MPV__c;
                    oli.ER_Cumulative_with_Promotions__c = cli.Cumulative_with_Promotions__c;
                    oli.ER_BUPicklist__c = cli.ER_BUPicklist__c;

                    /*if (dataMap.containsKey(cli.Id)) {
                        Map<String, Object> oliData = dataMap.get(cli.Id);
                        oli.ER_Nb_Beneficiaries__c = (Decimal) oliData.get('ER_Nb_Beneficiaries__c');
                        oli.ER_Load_Per_Year__c = (Decimal) oliData.get('ER_Load_Per_Year__c');
                        oli.ER_Days_Per_Month__c = (Decimal) oliData.get('ER_Days_Per_Month__c');
                        oli.ER_Face_Value__c = (Decimal) oliData.get('ER_Face_Value__c');
                    }*/
                    //Adding new logic acc to zahira bug
                    Decimal zero = 0;
                    if (cli.Opportunity_Product__c != null) {
                        oli.ER_Nb_Beneficiaries__c = cli.Opportunity_Product__r.ER_Nb_Beneficiaries__c != null
                            ? cli.Opportunity_Product__r.ER_Nb_Beneficiaries__c : zero;
                    
                        oli.ER_Load_Per_Year__c = cli.Opportunity_Product__r.ER_Load_Per_Year__c != null
                            ? cli.Opportunity_Product__r.ER_Load_Per_Year__c : zero;
                    
                        oli.ER_Days_Per_Month__c = cli.Opportunity_Product__r.ER_Days_Per_Month__c != null
                            ? cli.Opportunity_Product__r.ER_Days_Per_Month__c : zero;
                    
                        oli.ER_Face_Value__c = cli.Opportunity_Product__r.ER_Face_Value__c != null
                            ? cli.Opportunity_Product__r.ER_Face_Value__c : zero;
                    
                    } else if (cli.ER_Product2__c != null) {
                        oli.ER_Nb_Beneficiaries__c = cli.ER_Product2__r.No_Of_Beneficiaries__c != null
                            ? cli.ER_Product2__r.No_Of_Beneficiaries__c : zero;
                    
                        oli.ER_Load_Per_Year__c = cli.ER_Product2__r.Load_Per_Year__c != null
                            ? cli.ER_Product2__r.Load_Per_Year__c : zero;
                    
                        oli.ER_Days_Per_Month__c = cli.ER_Product2__r.Days_per_Month__c != null
                            ? cli.ER_Product2__r.Days_per_Month__c : zero;
                    
                        oli.ER_Face_Value__c = cli.ER_Product2__r.Face_Value__c != null
                            ? cli.ER_Product2__r.Face_Value__c : zero;
                    }

                    oliToInsert.add(oli);
                }
            }
        }

        // Final DMLs
        System.debug('>>>>> ALK - oliToInsert : ' + oliToInsert.size());
        if (!oliToInsert.isEmpty()) {
                System.debug('oliToInsert : ' + oliToInsert);
            Database.insert(oliToInsert, false);
        } if (!newOCRs.isEmpty()) {
            insert newOCRs;
        }else if (!userCanAmend) {
                System.debug('User cannot Amend ! ');
            throw new APER04_Opportunity_Exception(Label.LABS_SF_AvoidAmendement);
        }

    } catch (Exception e) {
    System.debug('Exception in createOpportunityFromContract: ' + e.getMessage());
    throw new AuraHandledException(e.getMessage());
}

    return newOpp;
}

//New method added by harkirat for Rest api
public static Opportunity createOpportunityFromContract_Rest(String contractId, String opportunityId) {
    try {
        return createOpportunityFromContract(contractId, opportunityId);
    } catch (AuraHandledException ahe) {
        // Convert AuraHandledException to a normal exception for REST
        throw new APER04_Opportunity_Exception(ahe.getMessage());
    }
}

  
    /*
     *Dragos Avram
     * 3/3/2021
     * createOpportunityFromFrameworkContract: Create a new opporutnity form a refferal contract
     */
    @AuraEnabled
    public static Opportunity createOpportunityFromFrameworkContract(String contractId, String currentAccount) {
        Opportunity newOpp = new Opportunity();
        OpportunityLineItem oli;
        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
        try {
            Contract frameworkContract = [
                    SELECT
            Id,
            Name,
            ContractNumber,
            EndDate,
            Pricebook2Id,
            CurrencyIsoCode,
            ER_InvoicingFrequency2__c,
            ER_ReimbursementTerm2__c,
            ER_Indexation__c,
            ER_PaymentTerms2__c,
            ER_PaymentMethod2__c,
            ER_Business_Unit__c,
            RecordType.DeveloperName,
            ER_Indexation_Index2__c,
            ER_Credit_Limit2__c,
            ER_Original_Agreement__c,
            ER_OppIndexation2__c,
            (
                            SELECT
                Id,
                ER_NeedApproval__c,
                ER_Solution__c,
                ER_ListPrice__c,
                ER_UnitPrice__c,
                CurrencyIsoCode,
                ER_PricebookEntryId__c,
                ER_Quantity__c,
                ER_Percentage__c,
                ER_Card_Operational_System_ID__c,
                ER_Creation_date_in_OS__c,
                ER_Discount__c,
                Opportunity_Product__c,
                Opportunity_Product__r.ER_Face_Value__c,
                Opportunity_Product__r.ER_Days_Per_Month__c,
                Opportunity_Product__r.ER_Nb_Beneficiaries__c,
                Opportunity_Product__r.ER_Load_Per_Year__c,
                Opportunity_Product__r.ER_Min__c,
                Opportunity_Product__r.ER_Max__c,
                Opportunity_Product__r.ER_Minimum_Fee__c,
                Opportunity_Product__r.ER_NeedApproval__c,
                Opportunity_Product__r.ER_Line_Type__c,
                ER_Minimum_Fee__c
                            FROM ER_ContractLineItems__r
                    )
                    FROM Contract
                    WHERE Id = :contractId
            ];
  
            newOpp.AccountId = currentAccount;
            //newOpp.Name = 'Copy of ' + frameworkContract.ContractNumber;
            newOpp.Pricebook2Id = frameworkContract.Pricebook2Id;
            newOpp.CurrencyIsoCode = frameworkContract.CurrencyIsoCode;
            newOpp.ER_Reason__c = Label.LABS_SF_Opp_Reason_New;
            newOpp.StageName = Label.LABS_SF_Opp_Status_Qualification;
            newOpp.CloseDate = Date.today().addMonths(1);
            newOpp.ER_InvoicingFrequency__c = frameworkContract.ER_InvoicingFrequency2__c;
            newOpp.ER_ReimbursementTerm__c = frameworkContract.ER_ReimbursementTerm2__c;
            newOpp.ER_Indexation__c = frameworkContract.ER_OppIndexation2__c;
            newOpp.ER_PaymentTerms__c = frameworkContract.ER_PaymentTerms2__c;
            newOpp.ER_PaymentMethod__c = frameworkContract.ER_PaymentMethod2__c;
            newOpp.ER_BUPicklist__c = frameworkContract.ER_Business_Unit__c;
            newOpp.ER_Indexation_Index__c = frameworkContract.ER_Indexation_Index2__c;
            newOpp.ER_Credit_Limit__c = frameworkContract.ER_Credit_Limit2__c;
            newOpp.Type = Label.LABS_SF_Opportunity_Type_Operational;
            newOpp.ER_Original_Agreement__c = frameworkContract.Id;
            newOpp.Contract_End_Date__c = frameworkContract.EndDate;
        if (frameworkContract.RecordType.DeveloperName == 'ER_Client_Contract_RT') {
                newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                        .get('ER_Client_Opportunity_RT')
                        .getRecordTypeId();
        } else if (frameworkContract.RecordType.DeveloperName == 'ER_Merchant_Contract_RT') {
                newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                        .get('ER_Merchant_Opportunity')
                        .getRecordTypeId();
            }
            insert newOpp;
  
        for (ER_ContractLineItem__c cli : frameworkContract.ER_ContractLineItems__r) {
                oli = new OpportunityLineItem();
                oli.OpportunityId = newOpp.Id;
                oli.UnitPrice = cli.ER_UnitPrice__c;
                oli.PricebookEntryId = cli.ER_PricebookEntryId__c;
                oli.Quantity = cli.ER_Quantity__c;
                oli.Discount = cli.ER_Discount__c;
                oli.ER_Minimum_Fee__c = oli.ER_Percentage__c = cli.ER_Percentage__c;
                oli.ER_NeedApproval__c = cli.ER_NeedApproval__c;
                oli.ER_Creation_date_in_OS__c = cli.ER_Creation_date_in_OS__c;
                oli.ER_Card_Operational_System_ID__c = cli.ER_Card_Operational_System_ID__c;
                oli.ER_Face_Value__c = cli.Opportunity_Product__r.ER_Face_Value__c;
                oli.ER_Days_Per_Month__c = cli.Opportunity_Product__r.ER_Days_Per_Month__c;
                oli.ER_Nb_Beneficiaries__c = cli.Opportunity_Product__r.ER_Nb_Beneficiaries__c;
                oli.ER_Load_Per_Year__c = cli.Opportunity_Product__r.ER_Load_Per_Year__c;
                oli.ER_Min__c = cli.Opportunity_Product__r.ER_Min__c;
                oli.ER_Max__c = cli.Opportunity_Product__r.ER_Max__c;
                oli.ER_Minimum_Fee__c = cli.Opportunity_Product__r.ER_Minimum_Fee__c;
                oli.ER_NeedApproval__c = cli.Opportunity_Product__r.ER_NeedApproval__c;
                oli.ER_Line_Type__c = cli.Opportunity_Product__r.ER_Line_Type__c;

                oliToInsert.add(oli);
            }
        if (!oliToInsert.isEmpty()) {
                System.debug('oliToInsert : ' + oliToInsert);
                //Database.insert(oliToInsert, false);
                insert oliToInsert;
                newOpp.Derieved_from_Framework_Opp__c = true; //Added 28 March, 2025
                update newOpp;
            }
      } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return newOpp;
    }
  
    /**
     * ELAK: externalize opportunity before insert implementation
     * @param newOpps
     */
    public static void manageOppRecordsBeforeInsert(List<Opportunity> newOpps) {
        System.debug('###manageOppRecordsBeforeInsert Start');
        Id oppMerchantRTId = Utils.getRecordTypeIdByDeveloperName(
                Opportunity.SObjectType,
                Constants.OPPORTUNITY_MERCHANT_RT
        );
        Id oppClientRTId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, Constants.OPPORTUNITY_CLIENT_RT);
        List<Opportunity> oppESList = new List<Opportunity>();
        List<Opportunity> oppClientList = new List<Opportunity>();
        List<Opportunity> oppMerchantList = new List<Opportunity>();
  
      for (Opportunity opp : newOpps) {
        if (opp.ER_BUPicklist__c == Constants.ES && opp.RecordTypeId == oppMerchantRTId)
                oppESList.add(opp);
        if (opp.ER_Lead_Source_Type__c == Constants.CLIENT && opp.RecordTypeId != oppClientRTId)
                oppClientList.add(opp);
        if (opp.ER_Lead_Source_Type__c == Constants.MERCHANT && opp.RecordTypeId != oppMerchantRTId)
                oppMerchantList.add(opp);
        }
  
        //Set Opp Name
        setOppName(newOpps);
  
      if (!oppESList.isEmpty())
            setStandardFinancialConditionsforES(oppESList);
      if (!oppClientList.isEmpty())
            setRTClient(oppClientList);
      if (!oppMerchantList.isEmpty())
            setRTMerchant(oppMerchantList);
        System.debug('###manageOppRecordsBeforeInsert End');
    }
  
    /**
     * @param newOpps
     * @param oldOppMap
     */
    public static void manageOppRecordsBeforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        System.debug('###manageOppRecordsBeforeUpdate Start');

        if (TriggerControl.oppStageUpdateFromQuote) {
            System.debug('### Skipping manageOppRecordsBeforeUpdate because update came from Quote');
            return;
        }
        List<Opportunity> syncOpportunityList = new List<Opportunity>();
    
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            oppIds.add(opp.Id);
        }
    
        Map<Id, List<OpportunityLineItem>> oliMap = new Map<Id, List<OpportunityLineItem>>();
        if (!Test.isRunningTest()) {
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, ER_NeedApproval__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ]) {
            if (!oliMap.containsKey(oli.OpportunityId)) {
                oliMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oliMap.get(oli.OpportunityId).add(oli);
        }
        }
    
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldOppMap.get(opp.Id);
    
            Boolean financeApprovalChangedToApproved = 
                opp.Finance_Approval_Status__c == 'Approved' &&
                oldOpp.Finance_Approval_Status__c != 'Approved';
    
            Boolean noLineItemNeedsApproval = true;
            if (oliMap.containsKey(opp.Id)) {
                for (OpportunityLineItem oli : oliMap.get(opp.Id)) {
                    if (oli.ER_NeedApproval__c) {
                        noLineItemNeedsApproval = false;
                        break;
                    }
                }
            }
    
            if (
                opp.StageName != Label.LABS_SF_Opp_Status_Negotiation && 
                (
                    (opp.ER_Approved__c && opp.ER_Approved__c != oldOpp.ER_Approved__c) ||
                    (financeApprovalChangedToApproved && noLineItemNeedsApproval)
                )
            ) {
                opp.StageName = Label.LABS_SF_Opp_Status_Proposal;
                syncOpportunityList.add(opp);
            }
        }
    
        if (!syncOpportunityList.isEmpty()) {
            OpportunityManagementWithoutSharing.createdSyncQuote(syncOpportunityList);
        }
    
        System.debug('###manageOppRecordsBeforeUpdate End');
    }    
  
    /**
     * @author ALK
     * @date 24/02/2022
     * @description Create Opportunity line items from Affiliation Code or Promo Code
     * @param newItems
     * @param oldOppMap
     */
    public static void manageDiscountCodes(List<Opportunity> newItems, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppsSet = new Set<Id>();
        Set<Id> AccountsIdsSet = new Set<Id>();
        List<Opportunity> oppsTobeUpdated = new List<Opportunity>();
        Map<Id, List<Opportunity>> mapPromoCodeOpps = new Map<Id, List<Opportunity>>();
  
      for (Opportunity opp : newItems) {
        if (
                    !opp.ER_SmartER_Context__c &&
                            !opp.IsClosed &&
                            opp.ER_Promo_Code2__c != oldOppMap?.get(opp.Id)?.ER_Promo_Code2__c
            ) {
                oppsSet.add(opp.Id);
                AccountsIdsSet.add(opp.AccountId);
  
          if (opp.ER_Promo_Code2__c != null) {
            if (!mapPromoCodeOpps.containsKey(opp.ER_Promo_Code2__c))
                        mapPromoCodeOpps.put(opp.ER_Promo_Code2__c, new List<Opportunity>());
                    mapPromoCodeOpps.get(opp.ER_Promo_Code2__c).add(opp);
                }
            }
        }
  
      if (!oppsSet.isEmpty()) {
            //Opportunity Line Items to be deleted
            delete ([SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN :oppsSet]);
  
            //empty the pricebook on all updated opps
        for (Id oppId : oppsSet) {
                Opportunity o = new Opportunity();
                o.Id = oppId;
                o.ER_Original_Agreement__c = null;
                o.Pricebook2Id = null;
                oppsTobeUpdated.add(o);
            }
  
        if (!oppsTobeUpdated.isEmpty())
                update oppsTobeUpdated;
        }
  
        //Create new opportunity line items
      if (!mapPromoCodeOpps.isEmpty())
            createOpportunityItemsFromPromoCode(mapPromoCodeOpps);
    }
  
    /**
     * @author ALK
     * @date 24/02/2022
     * @description Create Opportunity line items from the opportunity linked promo code (or Affiliation Code)
     * @param mapPromoCodeOpps
     */
    public static void createOpportunityItemsFromPromoCode(Map<Id, List<Opportunity>> mapPromoCodeOpps) {
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        Map<Id, List<Opportunity>> mapContractOpportunity = new Map<Id, List<Opportunity>>();
        Map<Id, List<Opportunity>> mapPromoCodeOpportunity = new Map<Id, List<Opportunity>>();
        Map<Id, List<Opportunity>> mapPromoCodeParentLink = new Map<Id, List<Opportunity>>();
        Map<Id, Opportunity> opportunitiesToUpdate = new Map<Id, Opportunity>();
        List<Opportunity> opportunities = new List<Opportunity>();
        //Set<Id> opportunityParentProductIdSet = new Set<Id>();
        //Set<Id> pricebookIdSet = new Set<Id>();
        //Set<Id> oppIdsSet = new Set<Id>();
        //Map<Id, Date> mapServiceChildEndDate = new Map<Id, Date>();
  
        Id affiliationCodeRT = Utils.getRecordTypeIdByDeveloperName(
                ER_Promo_Code__c.SObjectType,
                Constants.PROMO_CODE_AFFILIATION_RT
        );
        Id promoCodeRT = Utils.getRecordTypeIdByDeveloperName(ER_Promo_Code__c.SObjectType, Constants.PROMO_CODE_PROMO_RT);
  
        //Get ALl promo codes
      for (ER_Promo_Code__c pc : [
                SELECT Id, ER_Contract__c, ER_Affiliation_Type__c, RecordTypeId, ER_Contract__r.ER_Contract_Type__c
                FROM ER_Promo_Code__c
                WHERE ER_Status__c = :Constants.ACTIVATED AND Id IN :mapPromoCodeOpps.keySet()
        ]) {
        for (Opportunity opp : mapPromoCodeOpps.get(pc.Id)) {
          if (pc.RecordTypeId == affiliationCodeRT) {
            if (pc.ER_Contract__c != null) {
              if (!mapContractOpportunity.containsKey(pc.ER_Contract__c))
                            mapContractOpportunity.put(pc.ER_Contract__c, new List<Opportunity>());
                        mapContractOpportunity.get(pc.ER_Contract__c).add(opp);
              if (pc.ER_Contract__r.ER_Contract_Type__c == 'Referral agreement') {
                            opportunities.add(opp);
              } else if (pc.ER_Contract__r.ER_Contract_Type__c == 'Framework agreement') {
                if (!mapPromoCodeParentLink.containsKey(pc.Id))
                                mapPromoCodeParentLink.put(pc.Id, new List<Opportunity>());
                            mapPromoCodeParentLink.get(pc.Id).add(opp);
                        }
                    }
          } else if (pc.RecordTypeId == promoCodeRT) {
            if (!mapPromoCodeOpportunity.containsKey(pc.Id))
                        mapPromoCodeOpportunity.put(pc.Id, new List<Opportunity>());
                    mapPromoCodeOpportunity.get(pc.Id).add(opp);
                }
            }
        }
  
        //Oli from Affiliation Code
      if (!mapContractOpportunity.keySet().isEmpty()) {
        for (ER_ContractLineItem__c cli : [
                    SELECT
            Id,
            ER_Contract__c,
            ER_PricebookEntryId__c,
            ER_UnitPrice__c,
            ER_ListPrice__c,
            ER_Percentage__c,
            ER_Contract__r.ER_BUPicklist__c,
            ER_Min__c,
            ER_Max__c,
            ER_Price_Start_Date__c,
            ER_Price_End_Date__c,
            ER_Offer_validity_end_date__c,
            ER_Contract__r.CurrencyIsoCode,
            ER_Line_Type__c,
            ER_Contract__r.Pricebook2Id,
            ER_Contract__r.ER_InvoicingFrequency2__c,
            ER_Contract__r.ER_ReimbursementTerm2__c,
            ER_NeedApproval__c,
            ER_Contract__r.ER_OppIndexation2__c,
            ER_Contract__r.ER_PaymentTerms2__c,
            ER_Contract__r.ER_PaymentMethod2__c,
            ER_Contract__r.ER_Business_Unit__c,
            ER_Contract__r.ER_Indexation_Index2__c,
            ER_Contract__r.ER_Credit_Limit2__c,
            ER_Contract__r.RecordTypeId,
            ER_Quantity__c,
            ER_Discount__c,
            ER_Minimum_Fee__c
                    FROM ER_ContractLineItem__c
                    WHERE ER_Contract__c IN :mapContractOpportunity.keySet()
            ]) {
          for (Opportunity opp : mapContractOpportunity.get(cli.ER_Contract__c)) {
                    //Update Opportunity Financial Conditions
            if (!opportunitiesToUpdate.containsKey(opp.Id)) {
                        Opportunity o = new Opportunity();
                        o.Id = opp.Id;
                        o.Pricebook2Id = cli.ER_Contract__r.Pricebook2Id;
                        o.CurrencyIsoCode = cli.ER_Contract__r.CurrencyIsoCode;
                        o.ER_Reason__c = Constants.NEW_STATUS;
                        o.StageName = Label.LABS_SF_Opp_Status_Qualification;
                        o.CloseDate = Date.today().addMonths(1);
                        o.ER_InvoicingFrequency__c = cli.ER_Contract__r.ER_InvoicingFrequency2__c;
                        o.ER_ReimbursementTerm__c = cli.ER_Contract__r.ER_ReimbursementTerm2__c;
                        o.ER_Indexation__c = cli.ER_Contract__r.ER_OppIndexation2__c;
                        o.ER_PaymentTerms__c = cli.ER_Contract__r.ER_PaymentTerms2__c;
                        o.ER_PaymentMethod__c = cli.ER_Contract__r.ER_PaymentMethod2__c;
                        o.ER_BUPicklist__c = cli.ER_Contract__r.ER_BUPicklist__c;
                        o.ER_Indexation_Index__c = cli.ER_Contract__r.ER_Indexation_Index2__c;
                        o.ER_Credit_Limit__c = cli.ER_Contract__r.ER_Credit_Limit2__c;
                        o.Type = Label.LABS_SF_Opportunity_Type_Operational;
                        o.ER_Original_Agreement__c = cli.ER_Contract__c;
              if (
                                cli.ER_Contract__r.RecordTypeId ==
                                        Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_MERCHANT_RT)
                        )
                            o.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                                    Opportunity.SObjectType,
                                    Constants.OPPORTUNITY_MERCHANT_RT
                            );
              else if (
                                cli.ER_Contract__r.RecordTypeId ==
                                        Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_CLIENT_RT)
                        )
                            o.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                                    Opportunity.SObjectType,
                                    Constants.OPPORTUNITY_CLIENT_RT
                            );
  
                        opportunitiesToUpdate.put(opp.Id, o);
                    }
  
                    //Create OLI
                    OpportunityLineItem oli = new OpportunityLineItem();
                    oli.OpportunityId = opp.Id;
                    oli.UnitPrice = (cli.ER_Percentage__c != null ? cli.ER_Percentage__c : cli.ER_UnitPrice__c);
                    oli.PricebookEntryId = cli.ER_PricebookEntryId__c;
                    oli.Quantity = cli.ER_Quantity__c;
                    oli.Discount = cli.ER_Discount__c;
                    oli.ER_Minimum_Fee__c = cli.ER_Minimum_Fee__c;
                    oli.ER_NeedApproval__c = cli.ER_NeedApproval__c;
                    oli.ER_BUPicklist__c = cli.ER_Contract__r.ER_BUPicklist__c;
                    oli.ER_Percentage__c = (cli.ER_Percentage__c != null ? cli.ER_Percentage__c : null);
                    oli.ER_Line_Type__c = cli.ER_Line_Type__c;
                    oli.ER_Offer_validity_end_date__c = cli.ER_Offer_validity_end_date__c;
                    oli.ER_Max__c = cli.ER_Max__c;
                    oli.ER_Min__c = cli.ER_Min__c;
                    oli.ER_Price_Start_Date__c = cli.ER_Price_Start_Date__c;
                    oli.ER_Price_End_Date__c = cli.ER_Price_End_Date__c;
                    opportunityLineItems.add(oli);
                }
            }
        }
  
        //OLI from Promo Code
      if (!mapPromoCodeOpportunity.keySet().isEmpty()) {
            Map<Id, Integer> mapCountPCPB = new Map<Id, Integer>();
        for (AggregateResult ar : [
                    SELECT COUNT_DISTINCT(Pricebook2Id) cpt, ER_Promo_Code2__c
                    FROM PricebookEntry
                    WHERE ER_Promo_Code2__c IN :mapPromoCodeOpportunity.keySet()
                    GROUP BY ER_Promo_Code2__c
            ]) {
                mapCountPCPB.put((Id) ar.get('ER_Promo_Code2__c'), (Integer) ar.get('cpt'));
            }
            System.debug(LoggingLevel.DEBUG, 'mapCountPCPB ' + mapCountPCPB.size());
  
        for (PricebookEntry pbe : [
                    SELECT
            Id,
            UnitPrice,
            ER_Percentage__c,
            ER_Promo_Code2__c,
            ER_Offer_validity_end_date__c,
            ER_Price_End_Date__c,
            Product2.ER_Type__c,
            ER_Min__c,
            ER_Max__c,
            ER_Duration__c,
            Pricebook2Id,
            ER_Offer_validity_start_date__c,
            CurrencyIsoCode,
            Product2.ER_Solution__c,
            Product2.ER_Solution__r.ER_Service_Range_Type__c
                    FROM PricebookEntry
                    WHERE ER_Promo_Code2__c IN :mapPromoCodeOpportunity.keySet() AND Product2.IsActive = TRUE
            ]) {
                System.debug(LoggingLevel.DEBUG, 'pbe ' + pbe.ER_Promo_Code2__c);
  
          for (Opportunity opp : mapPromoCodeOpportunity.get(pbe.ER_Promo_Code2__c)) {
                    System.debug(LoggingLevel.DEBUG, 'opp ' + opp.Id);
  
            if (mapCountPCPB.containsKey(pbe.ER_Promo_Code2__c) && mapCountPCPB.get(pbe.ER_Promo_Code2__c) == 1) {
                        //Update the opp with the pricebook
              if (!opportunitiesToUpdate.containsKey(opp.Id)) {
                            Opportunity o = new Opportunity();
                            o.Id = opp.Id;
                            o.Pricebook2Id = pbe.Pricebook2Id;
                            o.CurrencyIsoCode = pbe.CurrencyIsoCode;
                            o.CloseDate = Date.today().addMonths(1);
                            o.Type = Label.LABS_SF_Opportunity_Type_Operational;
                            opportunitiesToUpdate.put(opp.Id, o);
                        }
  
                        /*Create OLI
                                    OpportunityLineItem oli = new OpportunityLineItem();
                                    oli.OpportunityId = opp.Id;
                                    oli.UnitPrice = pbe.UnitPrice;
                                    oli.PricebookEntryId = pbe.Id;
                                    oli.Quantity = 1;
                                    oli.ER_BUPicklist__c = opp.ER_BUPicklist__c;
                                    oli.ER_Percentage__c = (pbe.ER_Percentage__c != null ? pbe.ER_Percentage__c : null);
                                    if(pbe.Product2.ER_Type__c == Constants.RANGE) {
                                        if(pbe.Product2.ER_Solution__r.ER_Service_Range_Type__c == Constants.RANGE_WITH_FIX_PRICE) oli.ER_Line_Type__c = Constants.FIX_RANGE;
                                        else oli.ER_Line_Type__c = Constants.VARIABLE_RANGE_VOLUME_PRICING;
                                    } else oli.ER_Line_Type__c = pbe.Product2.ER_Type__c;
                                    oli.ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c;
                                    oli.ER_Max__c = pbe.ER_Max__c;
                                    oli.ER_Min__c = pbe.ER_Min__c;
                                    oli.ER_Price_Start_Date__c = pbe.ER_Offer_validity_start_date__c;
                                    oli.ER_Price_End_Date__c = pbe.ER_Price_End_Date__c;
                                    oli.ER_Duration__c = pbe.ER_Duration__c;
                                    opportunityLineItems.add(oli);
  
                                    if(pbe.ER_Price_End_Date__c != null) mapServiceChildEndDate.put(pbe.Product2.ER_Solution__c, pbe.ER_Price_End_Date__c.addDays(1));
                                    else if(pbe.ER_Duration__c != null) mapServiceChildEndDate.put(pbe.Product2.ER_Solution__c, pbe.ER_Offer_validity_start_date__c.addDays(Integer.valueOf(pbe.ER_Duration__c)));
                                    opportunityParentProductIdSet.add(pbe.Product2.ER_Solution__c);
                                    pricebookIdSet.add(pbe.Pricebook2Id);
                                    oppIdsSet.add(opp.Id);*/
                    }
                    //} else if(!UtilsBypass.getCurrentUser().ER_BypassVR__c) opp.addError(Label.LAB_SF_OPP_PROMOCODE_ERROR);
                }
            }
  
            /*if(!opportunityParentProductIdSet.isEmpty()){
  
                      for(PricebookEntry pbe :[SELECT Id, Name, UnitPrice, ER_Promo_Code2__c, Product2Id, Product2.ER_Type__c, ER_Percentage__c, Product2.ER_Solution__r.ER_Service_Range_Type__c
                                                  FROM PricebookEntry
                                                  WHERE Product2Id IN :opportunityParentProductIdSet
                                                  AND Pricebook2Id IN :pricebookIdSet
                                                  AND Product2.IsActive = TRUE]) {
  
                          for(Id oppId :oppIdsSet) {
                              OpportunityLineItem oppLineToCreate = new OpportunityLineItem();
                              oppLineToCreate.PricebookEntryId = pbe.Id;
                              oppLineToCreate.UnitPrice = pbe.UnitPrice;
                              if(pbe.ER_Percentage__c != null) {
                                  oppLineToCreate.ER_Percentage__c = pbe.ER_Percentage__c;
                                  oppLineToCreate.UnitPrice = pbe.ER_Percentage__c;
                              }
                              oppLineToCreate.ER_Price_Start_Date__c = mapServiceChildEndDate.get(pbe.Product2Id);
                              oppLineToCreate.OpportunityId = oppId;
                              if(pbe.Product2.ER_Type__c == Constants.RANGE) {
                                  if(pbe.Product2.ER_Solution__r.ER_Service_Range_Type__c == Constants.RANGE_WITH_FIX_PRICE) oppLineToCreate.ER_Line_Type__c = Constants.FIX_RANGE;
                                  else oppLineToCreate.ER_Line_Type__c = Constants.VARIABLE_RANGE_VOLUME_PRICING;
                              } else oppLineToCreate.ER_Line_Type__c = pbe.Product2.ER_Type__c;
                              opportunityLineItems.add(oppLineToCreate);
                          }
                      }
                  }*/
        }
  
      if (!opportunitiesToUpdate.isEmpty())
            update opportunitiesToUpdate.values();
      if (!opportunityLineItems.isEmpty())
            insert opportunityLineItems;
  
      if (!mapContractOpportunity.keySet().isEmpty()) {
            //Manage Parents Affiliation Type for AffliationCode
            manageParentAffiliationCodes(mapPromoCodeParentLink);
  
            //Create Account Partners based on the opportunity linked framework contract
            createAccountsPartners(opportunities);
        }
    }
  
    /**
     * @author VJOY
     * @date 15/03/2022
     * @description Add the parent account on the opportunity account's
     * @param mapPromoCodeOpps
     */
    public static void manageParentAffiliationCodes(Map<Id, List<Opportunity>> mapPromoCodeOpps) {
        List<Account> accToUpdateList = new List<Account>();
        Map<Id, Account> mapAccountsToBeUpdated = new Map<Id, Account>();
        Id affiliationCodeRT = Utils.getRecordTypeIdByDeveloperName(
                ER_Promo_Code__c.SObjectType,
                Constants.PROMO_CODE_AFFILIATION_RT
        );
  
      for (ER_Promo_Code__c pc : [
                SELECT Id, ER_Contract__c, ER_Affiliation_Type__c, ER_Contract__r.AccountId
                FROM ER_Promo_Code__c
                WHERE
                        ER_Status__c = :Constants.ACTIVATED
                        AND Id IN :mapPromoCodeOpps.keySet()
                        AND RecordTypeId = :affiliationCodeRT
        ]) {
        for (Opportunity opp : mapPromoCodeOpps.get(pc.Id)) {
          if (pc.ER_Affiliation_Type__c == Constants.PARENT) {
                    mapAccountsToBeUpdated.put(
                            opp.AccountId,
                            new Account(Id = opp.AccountId, ParentId = pc.ER_Contract__r.AccountId)
                    );
                }
            }
        }
  
      if (!mapAccountsToBeUpdated.isEmpty())
            update mapAccountsToBeUpdated.values();
    }
  
    public class APER04_Opportunity_Exception extends Exception {
    }
  
    /**
     * @description set Standard Financial Conditions for ES
     * @param oppESList
     */
    public static void setStandardFinancialConditionsforES(List<Opportunity> oppESList) {
      for (Opportunity opp : oppESList) {
            try {
          if (opp.ER_InvoicingFrequency__c == null) {
                    opp.ER_InvoicingFrequency__c = 'Monthly';
                }
          if (opp.ER_PaymentTerms__c == null) {
                    opp.ER_PaymentTerms__c = '15 days after invoice issuance';
                }
          if (opp.ER_ReimbursementTerm__c == null) {
                    opp.ER_ReimbursementTerm__c = '7 days';
                }
          if (opp.ER_PaymentMethod__c == null) {
                    opp.ER_PaymentMethod__c = 'Bank transfer';
                }
        } catch (Exception e) {
                System.debug('Financial conditions not set');
            }
        }
    }
  
    /**
     * @description setRTClient
     * @param oppList
     */
    public static void setRTClient(List<Opportunity> oppList) {
      for (Opportunity opp : oppList)
            opp.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, Constants.OPPORTUNITY_CLIENT_RT);
    }
  
    /**
     * @description setRTClient
     * @param oppList
     */
    public static void setRTMerchant(List<Opportunity> oppList) {
      for (Opportunity opp : oppList)
            opp.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                    Opportunity.SObjectType,
                    Constants.OPPORTUNITY_MERCHANT_RT
            );
    }
  
    /**
     * @author KHAD
     * @date 06/05/2021
     * @description Enforce the following naming convention {Opportunity.BU} - {Account.Name} - {Opportunity.Creation Date } - {sequence 01} - {Original opportunity name}
     * @param opportunities
     */
    public static void setOppName(List<Opportunity> opportunities) {
        Set<Id> setAccountsIds = new Set<Id>();
        Map<Id, List<Opportunity>> mapAccountTempOpportunities = new Map<Id, List<Opportunity>>();
  
      for (Opportunity o : opportunities) {
            setAccountsIds.add(o.AccountId);
        if (!mapAccountTempOpportunities.containsKey(o.AccountId))
                mapAccountTempOpportunities.put(o.AccountId, new List<Opportunity>());
            mapAccountTempOpportunities.get(o.AccountId).add(o);
        }
  
      for (Account a : [
                SELECT
          Id,
          ER_Registration_Number__c,
          Name,
          (SELECT Id, Name FROM Opportunities ORDER BY CreatedDate DESC, Name ASC)
                FROM Account
                WHERE Id IN :setAccountsIds
        ]) {
        if (!a.Opportunities.isEmpty()) {
                //Get Max Sequence
                Integer sequence = 0;
          for (Opportunity o : a.Opportunities) {
                    Integer currentSequence = (String.valueOf(o.Name.substringAfterLast('-')).isNumeric()
                            ? Integer.valueOf(o.Name.substringAfterLast('-'))
                            : 0);
                    sequence = (sequence < currentSequence ? currentSequence : sequence);
                }
  
          for (Integer i = 0; i < mapAccountTempOpportunities.get(a.Id).size(); i++) {
                    Opportunity opp = mapAccountTempOpportunities.get(a.Id)[i];
                    opp.Name = buildOppName(opp, a, (i + 1 + sequence));
                }
            } else {
          for (Integer i = 0; i < mapAccountTempOpportunities.get(a.Id).size(); i++) {
                    Opportunity opp = mapAccountTempOpportunities.get(a.Id)[i];
                    opp.Name = buildOppName(opp, a, (i + 1));
                }
            }
        }
    }
  
    /**
     * @param opp
     * @param a
     * @param sequence
     *
     * @return Create opportunity then truncate name
     */
    @testVisible
    private static String buildOppName(Opportunity opp, Account a, Integer sequence) {
        String opportunityName =
                opp.ER_BUPicklist__c +
                        '-' +
                        (String.isNotBlank(a.Name) ? a.Name.left(35) : '') +
                        '-' +
                        Datetime.now().format('YYYY-MM-dd') +
                        '-' +
                        sequence +
                        '-';
      if (String.isNotBlank(opp.Name))
            opportunityName += Utils.updateNameIfOpportunityFromLead(opp.Name);
  
        return opportunityName.left(80);
    }
  
    /**
     * @author ALK
     * @date 03/06/2021
     * @description Check if the solution to be added exists already on an active contract having the same type
     * @param items 
     */
    public static void checkExistingSolutionInActiveContract(List<OpportunityLineItem> items) {
      if(UtilsBypass.canTrigger('checkExistingSolutionInActiveContract') && !items.isEmpty()) {
          Map<Id, List<OpportunityLineItem>> mapOppsOLi = new Map<Id, List<OpportunityLineItem>>();
          Map<Id, List<Opportunity>> mapAccountsOpps = new Map<Id, List<Opportunity>>();
          Map<String, String> mapOLISolution = new Map<String, String>();
          Map<Id, List<OpportunityLineItem>> mapProductsOli = new Map<Id, List<OpportunityLineItem>>();
          List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('Bypass_Active_Contract_Process'));
          
          for(OpportunityLineItem oli : items) {
              if(!mapOppsOLi.containsKey(oli.OpportunityId)) {
                  mapOppsOLi.put(oli.OpportunityId, new List<OpportunityLineItem>());
              }
              mapOppsOLi.get(oli.OpportunityId).add(oli);
  
              if(!mapProductsOli.containsKey(oli.Product2Id)) {
                  mapProductsOli.put(oli.Product2Id, new List<OpportunityLineItem>());
              }
              mapProductsOli.get(oli.Product2Id).add(oli);
          }
  
          for(Product2 p : [
              SELECT Id, Name, ER_Solution2__r.ProductCode
              FROM Product2
              WHERE Id IN :mapProductsOli.keySet()
          ]) {
              for(OpportunityLineItem oli : mapProductsOli.get(p.Id)) {
                  mapOLISolution.put(oli.OpportunityId + '_' + oli.Product2Id, p.ER_Solution2__r.ProductCode);
              }
          }
          
  
          for(Opportunity o : [
              SELECT Id, AccountId, Type, ER_AmendedFromContract__c, RecordType.DeveloperName, Auto_Enrolment_Opportunity__c, Derieved_from_Framework_Opp__c
              FROM Opportunity
              WHERE Id IN :mapOppsOLi.keySet()
          ]) {
              if(!mapAccountsOpps.containsKey(o.AccountId)) {
                  mapAccountsOpps.put(o.AccountId, new List<Opportunity>());
              }
              mapAccountsOpps.get(o.AccountId).add(o);
          }
  
          for(ER_ContractLineItem__c c : [
              SELECT Id, ER_Contract__c, ER_Contract__r.RecordType.DeveloperName,
                     ER_Contract__r.AccountId, ER_Solution__c,
                     ER_Contract__r.ER_Contract_Type__c, ER_Contract__r.ContractNumber
              FROM ER_ContractLineItem__c
              WHERE ER_Contract__r.AccountId IN :mapAccountsOpps.keySet()
              AND ER_Contract__r.Status = :Label.LABS_SF_Contract_Status_Activated
              AND ER_Business_Unit__c NOT IN :bus
              AND ER_Contract__r.ER_Contract_Type__c = :Constants.CONTRACT_TYPE_OPERATIONAL
          ]) {
             
  
              for(Opportunity o : mapAccountsOpps.get(c.ER_Contract__r.AccountId)) {
                  String rtType = (o.RecordType.DeveloperName == Constants.OPPORTUNITY_MERCHANT_RT
                                   ? Constants.CONTRACT_MERCHANT_RT 
                                   : Constants.CONTRACT_CLIENT_RT);
  
                  for(OpportunityLineItem oli : mapOppsOLi.get(o.Id)) {
                      String solution = mapOLISolution.get(oli.OpportunityId + '_' + oli.Product2Id);
  
                      if(!UtilsBypass.getCurrentUser().ER_BypassVR__c
                         && o.ER_AmendedFromContract__c == null
                         && o.Derieved_from_Framework_Opp__c == false
                         && o.Type == c.ER_Contract__r.ER_Contract_Type__c
                         && c.ER_Solution__c == solution
                         && c.ER_Contract__r.RecordType.DeveloperName == rtType
                         && !o.Auto_Enrolment_Opportunity__c
                         ) {
                          String errorMessage = Label.LABS_SF_SOLUTION_EXIST_IN_ACTIVE_CONTRACT;
                          errorMessage = errorMessage.replace('{0}', c.ER_Solution__c)
                                                     .replace('{1}', c.ER_Contract__r.ContractNumber);
                          oli.addError(errorMessage);
                      }
                  }
              }
          }
      } else {
      }
  }
  
  
  
    /**
     * @author Noor
     * @date 29/07/2021
     * @description Update lookup field Solution on Opportunity Line item each time it is created.
     * @param opportunityLineItems new created opportunity line item
     */
    public static void updateSolutionOnOppLineItem(List<OpportunityLineItem> opportunityLineItems) {
      if (UtilsBypass.canTrigger('updateSolutionOnOppLineItem')) {
            Set<Id> productIds = new Set<Id>();
  
        for (OpportunityLineItem item : opportunityLineItems)
                productIds.add(item.Product2Id);
  
            Map<Id, Product2> mapItems = new Map<Id, Product2>(
                    [SELECT Id, ER_Solution2__c FROM Product2 WHERE ER_Solution2__c != NULL AND Id IN :productIds]
            );
  
        for (OpportunityLineItem item : opportunityLineItems) {
          if (mapItems.containsKey(item.Product2Id))
                    item.Solution__c = mapItems.get(item.Product2Id).ER_Solution2__c;
            }
        }
    }
  
    /**
     * @author SNICA
     * @date 26/01/2022
     * @description The indexation checkbox should be check automatically for benelux opportunities
     * @param oppList
     */
    public static void setIndexationFields(List<Opportunity> oppList) {
      for (Opportunity opp : oppList) {
        if (!opp.ER_SmartER_Context__c && opp.ER_BUPicklist__c == Constants.BENELUX) {
                opp.ER_Indexation__c = true;
                opp.ER_Indexation_Index__c = Constants.AGORIA_PRICE_INDEX;
            }
        }
    }
  
    /**
     * @author VJO
     * @date 19/02/2022
     * @description
     *
     */
    public static void checkVatMpvError(List<Opportunity> newItems) {
        System.debug('checkVatMpvError >> Starting ' + newItems);
  
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, List<OpportunityLineItem>> oppLineItemByOppIdMap = new Map<Id, List<OpportunityLineItem>>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
  
      for (Opportunity o : newItems) {
        if (!o.ER_SmartER_Context__c && o.ER_BU_Picklist__c == Constants.BENELUX && o.LeadSource != 'Auto Enrollment')
                oppIdSet.add(o.Id);
        }
  
        System.debug('checkVatMpvError >> oppIdSet ' + oppIdSet);
  
      if (!oppIdSet.isEmpty()) {
        for (OpportunityLineItem oli : [
                    SELECT Id, OpportunityId, Product2.ER_Solution2__r.ProductCode, ER_MPV__c
                    FROM OpportunityLineItem
                    WHERE OpportunityId IN :oppIdSet AND Product2.ER_Solution2__r.ProductCode = :Label.LAB_SF_P2_VOUCHER_CODE
            ]) {
                oliList.add(oli);
          if (!oppLineItemByOppIdMap.containsKey(oli.OpportunityId))
                    oppLineItemByOppIdMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
                oppLineItemByOppIdMap.get(oli.OpportunityId).add(oli);
            }
  
            System.debug('checkVatMpvError >> oppLineItemByOppIdMap ' + oppLineItemByOppIdMap);
  
        for (Opportunity o : newItems) {
          if (oppLineItemByOppIdMap.containsKey(o.Id)) {
            for (OpportunityLineItem oli : oppLineItemByOppIdMap.get(o.Id)) {
              if (o.ER_VAT__c == null) {
                if (!oli.ER_MPV__c)
                                o.addError(
                                        'MPV has not been checked on the solution ' +
                                                oli.Product2.ER_Solution2__r.ProductCode +
                                                '. VAT should not be empty.'
                                );
                        } else {
                if (oli.ER_MPV__c)
                                o.addError(
                                        'MPV has been checked on the solution ' +
                                                oli.Product2.ER_Solution2__r.ProductCode +
                                                '. VAT should be empty.'
                                );
                        }
                    }
                }
            }
        }
    }
  
    /**
     * @author ALK
     * @date 25/02/2022
     * @description Create Account Partners based on the opportunity linked framework contract
     * @param opportunities
     */
    public static void createAccountsPartners(List<Opportunity> opportunities) {
        Map<Id, Id> opportunitiesContractsMap = new Map<Id, Id>();
        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>(opportunities);
        Map<Id, Id> agreementContractsAccountsMap = new Map<Id, Id>();
        Set<String> existingAccountPartnersSet = new Set<String>();
        List<AccountPartner> partners = new List<AccountPartner>();
        Map<Id, String> mapOpportunityAffType = new Map<Id, String>();
  
        //for(Opportunity o :opportunities) {
      for (Opportunity o : [
                SELECT Id, ER_Original_Agreement__c, ER_Promo_Code2__r.ER_Affiliation_Type__c
                FROM Opportunity
                WHERE Id IN :opportunitiesMap.keySet()
        ]) {
        if (o.ER_Original_Agreement__c != null && String.isNotBlank(o.ER_Promo_Code2__r.ER_Affiliation_Type__c)) {
                opportunitiesContractsMap.put(o.Id, o.ER_Original_Agreement__c);
                mapOpportunityAffType.put(o.Id, o.ER_Promo_Code2__r.ER_Affiliation_Type__c);
            }
        }
  
      for (Contract c : [
                SELECT Id, AccountId, ER_Contract_Type__c
                FROM Contract
                WHERE Id IN :opportunitiesContractsMap.values() AND Status = :Constants.ACTIVATED
        ]) {
            agreementContractsAccountsMap.put(c.Id, c.AccountId);
        }
  
      if (!agreementContractsAccountsMap.isEmpty()) {
        for (AccountPartner ap : [
                    SELECT Id, AccountFromId, AccountToId, Role
                    FROM AccountPartner
                    WHERE AccountFromId IN :agreementContractsAccountsMap.values() AND Role = :Constants.FEDERATION_MEMBER
            ]) {
                existingAccountPartnersSet.add(ap.AccountFromId + '_' + ap.AccountToId + '_' + ap.Role);
            }
  
        for (Id oppId : opportunitiesContractsMap.keySet()) {
                Id agreementContractId = opportunitiesContractsMap.get(oppId);
                Id agreementAccountId = (agreementContractId != null
                        ? agreementContractsAccountsMap.get(agreementContractId)
                        : null);
                Id childAccountId = opportunitiesMap.get(oppId).AccountId;
  
                String partnerRole = (mapOpportunityAffType.get(oppId) == Constants.FEDERATION
                        ? Constants.FEDERATION_MEMBER
                        : Constants.FRANCHISEE);
          if (!existingAccountPartnersSet.contains(agreementAccountId + '_' + childAccountId + '_' + partnerRole)) {
                    partners.add(
                            new AccountPartner(AccountFromId = agreementAccountId, AccountToId = childAccountId, Role = partnerRole)
                    );
                }
            }
  
        if (!partners.isEmpty() && !Test.isRunningTest())
                insert partners;
        }
    }
  
    /**
     * @author SNICA
     * @date 08/03/2022
     * @description 15039 - Calculate the opportunity solutions
     * @param newItems
     * @param oldItems
     */
    public static void calculateOpportunitySolutions(
            List<OpportunityLineItem> newItems,
            Map<Id, OpportunityLineItem> oldItems
    ) {
        Map<Id, String> mapOppsSolutions = new Map<Id, String>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<OpportunityLineItem> items = (newItems != null && !newItems.isEmpty()
                ? newItems
                : (oldItems != null && !oldItems.isEmpty() ? oldItems.values() : null));
  
        if (items != null) {
            for (OpportunityLineItem oli : items) {
                    mapOppsSolutions.put(oli.OpportunityId, '');
            }
  
        for (OpportunityLineItem oli : [
                    SELECT Id, Product2.ER_Solution2__r.ProductCode, OpportunityId
                    FROM OpportunityLineItem
                    WHERE OpportunityId IN :mapOppsSolutions.keySet()
            ]) {
          if (String.isNotBlank(oli.Product2.ER_Solution2__r?.ProductCode)) {
                    String solutionCode = oli.Product2.ER_Solution2__r.ProductCode;
            if (mapOppsSolutions.get(oli.OpportunityId) == null || mapOppsSolutions.get(oli.OpportunityId) == '')
                        mapOppsSolutions.put(oli.OpportunityId, solutionCode);
            else if (!mapOppsSolutions.get(oli.OpportunityId).contains(solutionCode))
                        mapOppsSolutions.put(
                                oli.OpportunityId,
                                mapOppsSolutions.get(oli.OpportunityId) + ' / ' + oli.Product2.ER_Solution2__r.ProductCode
                        );
                }
            }
  
        for (Id oppId : mapOppsSolutions.keySet()) {
                opportunitiesToUpdate.add(new Opportunity(Id = oppId, ER_Solutions__c = mapOppsSolutions.get(oppId)));
            }
  
        if (!opportunitiesToUpdate.isEmpty())
                update opportunitiesToUpdate;
        }
    }
    /**
     * @authorCWAN
     * @date 19/04/2022
     * @DESCRIPTION Calculate Approval Steps
     */
    public static void calculateApprovalSteps(Map<Id, Opportunity> newItems, Map<Id, Opportunity> oldOppMap) {
        Set<Id> OppQuery = new Set<Id>();
        Id oppClientRT = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, Constants.OPPORTUNITY_CLIENT_RT);
  
      for (Opportunity opp : newItems.values()) {
        if (
                    !opp.ER_SmartER_Context__c &&
                            opp.ER_NeedApproval__c &&
                            opp.ER_NeedApproval__c != oldOppMap.get(opp.Id).ER_NeedApproval__c
            )
                OppQuery.add(opp.Id);
        }
  
      if (!OppQuery.isEmpty()) {
        for (Opportunity opp : [
                    SELECT Id, ER_BUPicklist__c, ER_NeedApproval__c, RecordTypeId, Pricebook2.Name
                    FROM Opportunity
                    WHERE Id IN :OppQuery
            ]) {
          if (
                        opp.ER_BUPicklist__c == Constants.ES &&
                                opp.RecordTypeId == oppClientRT &&
                                opp.Pricebook2.Name == 'ERES_C_BENEFITS_TS_2022Q1' &&
                                newItems.get(opp.Id).ER_NeedApproval__c
                )
                    newItems.get(opp.Id).ER_Approval_Step__c = '1';
  
          if (
                        opp.ER_BUPicklist__c == Constants.ES &&
                                opp.RecordTypeId == oppClientRT &&
                                (opp.Pricebook2.Name == 'ERES_C_BENEFITS_2022Q1' ||
                                        opp.Pricebook2.Name == 'ERES_C_BENEFITS_FLX_2022Q1' ||
                                        opp.Pricebook2.Name == 'ERES_C_INCENTIVES_2022Q1') &&
                                newItems.get(opp.Id).ER_NeedApproval__c
                )
                    newItems.get(opp.Id).ER_Approval_Step__c = '2';
          else if (
                        opp.ER_BUPicklist__c == 'ES' &&
                                opp.RecordTypeId == oppClientRT &&
                                (opp.Pricebook2.Name == 'ERES_C_BENEFITS_FLXKAM_2022Q1' ||
                                        opp.Pricebook2.Name == 'ERES_C_INCENTIVES_KAM_2022Q1') &&
                                newItems.get(opp.Id).ER_NeedApproval__c
                )
                    newItems.get(opp.Id).ER_Approval_Step__c = '3';
            }
        }
    }
  
    /**
     * @author CWAN
     * @date 05/05/2022
     * @description Check if oppty Need Financial Approver
     * @param newOpps
     */
    public static void checkNeedFinancialApprover(List<Opportunity> newOpps) {
        Id oppClientRecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                Opportunity.SObjectType,
                Constants.OPPORTUNITY_CLIENT_RT
        );
        Id merchantRecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                Opportunity.SObjectType,
                Constants.OPPORTUNITY_MERCHANT_RT
        );
      Set<String> reimbursementTerms = new Set<String>{ '3 days', '4 days', '5 days' };
  
      for (Opportunity opp : newOpps) {
        if (
                    (opp.ER_BUPicklist__c == Constants.ES &&
                            opp.RecordTypeId == oppClientRecordTypeId &&
                            (opp.ER_PaymentTerms__c != Constants.OPP_PAYMENT_TERM_PRE_PAID ||
                                    opp.ER_PaymentMethod__c != Constants.OPP_PAYMENT_METHOD_BANK_TRANSFER)) ||
                            (opp.ER_BUPicklist__c == Constants.SK &&
                                    (opp.ER_Credit_Limit__c > 0 ||
                                            (opp.SK_Payment_Terms_Voucher__c != '1' && !String.isEmpty(opp.SK_Payment_Terms_Voucher__c)) ||
                                            !String.isEmpty(opp.SK_Credit_Note_Frequency__c))) ||
                            ((opp.ER_PaymentTerms__c != Label.LABS_SF_ER_PaymentTerms ||
                                    reimbursementTerms.contains(opp.ER_ReimbursementTerm__c)) &&
                                    opp.RecordTypeId == merchantRecordTypeId &&
                                    opp.ER_BUPicklist__c == 'CZ' &&
                                    opp.ER_ReimbursementTerm__c != null &&
                                    opp.ER_PaymentTerms__c != null)
            ) {
                opp.ER_Need_Financial_Approval_2__c = true;
        } else if (opp.ER_BUPicklist__c == 'FI' && opp.ER_PaymentTerms__c?.indexOf(' days after invoice issuance') > 0) {
                Integer numberOfDays;
                numberOfDays = Integer.valueOf(opp.ER_PaymentTerms__c.remove(' days after invoice issuance'));
                system.debug('########1 numberOfDays : ' + numberOfDays);
                system.debug('########1 condition ? : ' + (numberOfDays > 14));
          if (numberOfDays > 14)
                    opp.ER_Need_Financial_Approval_2__c = true;
                else
                        opp.ER_Need_Financial_Approval_2__c = false;
        } else if (
                    opp.ER_BUPicklist__c == 'GR' && (opp.ER_PaymentTerms__c != null || opp.RecordTypeId == merchantRecordTypeId)
            )
                opp.ER_Need_Financial_Approval_2__c = true;
            else {
                opp.ER_Need_Financial_Approval_2__c = false;
            }
        }
    }
  
    /**
     * @author Noor
     * @date 02/06/2022
     * @description sum up estimate on Opportunity
     * @param items
     */
    public static void sumUpEstimatesOnOpportunityWhenChange(
            List<OpportunityLineItem> items,
            Map<Id, OpportunityLineItem> oldItems
    ) {
        List<Id> opportunityIds = new List<Id>();
  
      for (OpportunityLineItem oli : items) {
        if (oldItems == null && oli.ER_Estimated_Value__c > 0)
                opportunityIds.add(oli.OpportunityId); //When OLI is removed
        else if (oldItems != null && oli.ER_Estimated_Value__c != oldItems.get(oli.Id).ER_Estimated_Value__c)
                opportunityIds.add(oli.OpportunityId);
        }
  
      if (!opportunityIds.isEmpty())
            sumUpEstimatesOnOpportunity(opportunityIds);
    }
  
    /**
     * @author Noor
     * @date 02/06/2022
     * @description sum up estimate on Opportunity
     * @param items
     */
    public static void sumUpEstimatesOnOpportunity(List<Id> opportunityIds) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Map<Id, Map<Id, OpportunityLineItem>> oppMapPerSolnMap = new Map<Id, Map<Id, OpportunityLineItem>>();
        Map<Id, OpportunityLineItem> oliMapPerSoln;
  
      for (Opportunity o : [
                SELECT Id, (SELECT Id, Solution__c, ER_Estimated_Value__c FROM OpportunityLineItems)
                FROM Opportunity
                WHERE Id IN :opportunityIds
        ]) {
            oliMapPerSoln = new Map<Id, OpportunityLineItem>();
  
        for (OpportunityLineItem oli : o.OpportunityLineItems)
                oliMapPerSoln.put(oli.Solution__c, oli);
  
            oppMapPerSolnMap.put(o.Id, oliMapPerSoln);
        }
  
      for (Id oppId : oppMapPerSolnMap.keySet()) {
            Decimal potentialRevenue = 0;
  
        for (OpportunityLineItem oli : oppMapPerSolnMap.get(oppId).values())
                potentialRevenue += oli.ER_Estimated_Value__c;
  
            opportunitiesToUpdate.add(new Opportunity(Id = oppId, ER_Potential_Revenue__c = potentialRevenue));
        }
  
      if (!opportunitiesToUpdate.isEmpty())
            update opportunitiesToUpdate;
    }
  
    /**
     * @author Noor
     * @date 03/08/2022
     * @description Validate price book association based on promo code
     * @param newItems updated opportunities
     * @param oldMap old opportunities
     */
    public static void validatePriceBookBasedOnPromoCode(Map<Id, Opportunity> newItems, Map<Id, Opportunity> oldMap) {
        Map<Id, Id> oppMapPromoCode = new Map<Id, Id>();
        //Preselect opportunities that meet the condition the check for recordType promo code will be done after the query
      for (Opportunity opp : newItems.values()) {
        if (
                    !opp.ER_SmartER_Context__c &&
                            String.isNotBlank(opp.ER_Promo_Code2__c) &&
                            String.isNotBlank(opp.Pricebook2Id) &&
                            opp.Pricebook2Id != oldMap.get(opp.Id).Pricebook2Id
            )
                oppMapPromoCode.put(opp.Id, opp.ER_Promo_Code2__c);
        }
        //retrieve PricebookEntries By PromoCode to validate if pricebook match
      if (!oppMapPromoCode.isEmpty() && !UtilsBypass.getCurrentUser().ER_BypassVR__c)
            retrievePricebookEntriesByPromoCode(oppMapPromoCode, newItems);
    }
  
    /**
     * @author Noor
     * @date 03/08/2022
     * @description retrieve PricebookEntries By PromoCode to validate if pricebook match
     * @param oppMapPromoCode opportunity by promo code
     * @param newItems updated opportunities
     */
    public static void retrievePricebookEntriesByPromoCode(Map<Id, Id> oppMapPromoCode, Map<Id, Opportunity> newItems) {
        Map<Id, List<Id>> promoCodeMapPriceBook = new Map<Id, List<Id>>();
        Map<Id, List<String>> promoCodeMapPriceBookName = new Map<Id, List<String>>();
        Map<Id, String> promoCodeRecordType = new Map<Id, String>();
  
        //Query pricebookentry by promo code
      for (PricebookEntry pbe : [
                SELECT Id, ER_Promo_Code2__c, ER_Promo_Code2__r.RecordType.DeveloperName, Pricebook2Id, Pricebook2.Name
                FROM PricebookEntry
                WHERE ER_Promo_Code2__c IN :oppMapPromoCode.values() AND Product2.IsActive = TRUE
        ]) {
            promoCodeRecordType.put(pbe.ER_Promo_Code2__c, pbe.ER_Promo_Code2__r.RecordType.DeveloperName);
  
        if (promoCodeMapPriceBook.containsKey(pbe.ER_Promo_Code2__c)) {
                promoCodeMapPriceBook.get(pbe.ER_Promo_Code2__c).add(pbe.Pricebook2Id);
          if (!promoCodeMapPriceBookName.get(pbe.ER_Promo_Code2__c).contains(pbe.Pricebook2.Name))
                    promoCodeMapPriceBookName.get(pbe.ER_Promo_Code2__c).add(pbe.Pricebook2.Name);
            } else {
          promoCodeMapPriceBook.put(pbe.ER_Promo_Code2__c, new List<Id>{ pbe.Pricebook2Id });
          promoCodeMapPriceBookName.put(pbe.ER_Promo_Code2__c, new List<String>{ pbe.Pricebook2.Name });
            }
        }
        addErrorIfPriceBookNotMatch(
                newItems,
                oppMapPromoCode,
                promoCodeMapPriceBook,
                promoCodeMapPriceBookName,
                promoCodeRecordType
        );
    }
  
    /**
     * @author Noor
     * @date 03/08/2022
     * @description add Error If PriceBook in opportunity not Match with the price book associated to the promo code
     * @param newItems updated opportunities
     * @param oppMapPromoCode promo code per opportunity
     * @param promoCodeMapPriceBook promoCode per price book
     * @param promoCodeMapPriceBookName promoCode per price book name - used to display in error msg
     * @param promoCodeRecordType promoCode with recordType - validation to be done only for @see Constants.PROMO_CODE_PROMO_RT
     */
    public static void addErrorIfPriceBookNotMatch(
            Map<Id, Opportunity> newItems,
            Map<Id, Id> oppMapPromoCode,
            Map<Id, List<Id>> promoCodeMapPriceBook,
            Map<Id, List<String>> promoCodeMapPriceBookName,
            Map<Id, String> promoCodeRecordType
    ) {
        String PB_DELIMITER = ' ,';
      for (Id oppId : oppMapPromoCode.keySet()) {
            String promo_code = newItems.get(oppId).ER_Promo_Code2__c;
        if (
                    promoCodeRecordType.containsKey(promo_code) &&
                            promoCodeRecordType.get(promo_code).equals(Constants.PROMO_CODE_PROMO_RT)
            ) {
          if (
                        promoCodeMapPriceBook.containsKey(promo_code) &&
                                !promoCodeMapPriceBook.get(promo_code).contains(newItems.get(oppId).Pricebook2Id)
                ) {
                    String errorMsg = Label.LAB_SF_OPP_PRICEBOOK_ERROR_1;
            for (String pricebookName : promoCodeMapPriceBookName.get(promo_code))
                        errorMsg += pricebookName + PB_DELIMITER;
                    errorMsg = errorMsg.removeEnd(PB_DELIMITER);
  
                    newItems.get(oppId).addError('Pricebook2Id', errorMsg);
          } else if (!promoCodeMapPriceBook.containsKey(promo_code)) {
                    //if no pricebook at all is associate with the promo code
                    newItems.get(oppId).addError('Pricebook2Id', Label.LAB_SF_OPP_PRICEBOOK_ERROR_2);
                }
            }
        }
    }
  
    /**
     * @author AAZ
     * @date 10/01/2023
     * @description This method is used to default values for new created opportunities
     * @param newItems
     */
    public static void opportunityDefaultingValues(List<Opportunity> newItems) {
      for (Opportunity o : newItems) {
        if (o.ER_SmartER_Context__c && o.ER_BUPicklist__c == Constants.FR) {
                //Defaulting Payment Term and Payment Methods
          if (String.isBlank(o.ER_PaymentTerms__c) && String.isBlank(o.ER_PaymentMethod__c)) {
                    o.ER_PaymentTerms__c = Constants.AT_RECEPTION_OF_INVOICE;
                    o.ER_PaymentMethod__c = Constants.WIRE_TRANSFER;
                }
                //Defaulting Estimated Number Of Beneficiaries and Revenue
          if (o.ER_Estimated_Number_Of_Beneficiaries__c == null)
                    o.ER_Estimated_Number_Of_Beneficiaries__c = 0;
          if (o.ER_Estimated_Revenue__c == null)
                    o.ER_Estimated_Revenue__c = 0;
            }
        }
    }
  
    /**
     * @author SNICA
     * @date 07/03/2024
     * @description The indexation checkbox should be check automatically for FI opportunities(with ER_Indexation_Index__c = 'Customer price index')
     * @param oppList
     */
    public static void updateIndexationField(List<Opportunity> oppList) {
      for (Opportunity opp : oppList) {
        if (
                    UtilsBypass.getCurrentUser().ER_Business_Unit__c == Constants.FI &&
                            opp.ER_Indexation_Index__c == Constants.CONSUMER_PRICE_INDEX
            ) {
                opp.ER_Indexation__c = true;
        } else if (
                    UtilsBypass.getCurrentUser().ER_Business_Unit__c == Constants.FI &&
                            opp.ER_Indexation_Index__c != Constants.CONSUMER_PRICE_INDEX
            ) {
                opp.ER_Indexation__c = false;
            }
        }
    }
  
    /**
     * @author ALK
     * @date 28/06/2022
     * @description SmartER Set SmartER context on the Opportunity
     * @param newItems
     */
    public static void setOppAsSmartERContext(List<Opportunity> newItems) {
        List<String> smartERDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
                ?.split(Constants.SEMICOLON);
  
      for (Opportunity o : newItems) {
        if (
                    smartERDeployedBUs != null &&
                            (smartERDeployedBUs.contains(o.ER_BUPicklist__c) || smartERDeployedBUs.contains(Constants.ALL)) &&
                            !o.ER_SmartER_Context__c
            ) {
                o.ER_SmartER_Context__c = true;
            }
        }
    }
  
    /**
     * @description : creates servies under inserted opportunities (COUL-2505)
     * @author Hassan DAKHCHA | 04-25-2023
     * @param newOppList : inserted opportunities
     **/
    private static void createAutoenrollmentOpportunityLineItems(List<Opportunity> newOppList) {
        try {
            Map<String, List<Opportunity>> mapBUOpportunities = new Map<String, List<Opportunity>>();
            Set<Id> pricebookIds = new Set<Id>();
            Set<String> solutions = new Set<String>();
            Set<String> countryCodes = new Set<String>();
            Map<String, List<String>> solutionsServicesMap = new Map<String, List<String>>();
            Map<String, List<Opportunity>> oppSolutionMap = new Map<String, List<Opportunity>>();
  
        for (Opportunity o : newOppList) {
          if (o.Pricebook2Id != null)
                    pricebookIds.add(o.Pricebook2Id);
  
                List<String> oppSolutions;
          if (String.isNotBlank(o.ER_Solutions__c)) {
                    oppSolutions = o.ER_Solutions__c.split(Constants.PIPE_SEPARATOR);
                    solutions.addAll(oppSolutions);
                    // if(String.isNotBlank(o.ER_Benefits__c)) solutions.addAll(o.Benefits__c.split(Constants.PIPE_SEPARATOR)); // NOT ADDED FOR NOW
            if (String.isNotBlank(o.ER_CardType__c)) {
                        oppSolutions.addAll(o.ER_CardType__c.split(Constants.PIPE_SEPARATOR));
                        solutions.addAll(o.ER_CardType__c.split(Constants.PIPE_SEPARATOR));
                    }
            if (String.isNotBlank(o.ER_AdditionalProducts__c)) {
                        oppSolutions.addAll(o.ER_AdditionalProducts__c.split(Constants.COMMA));
                        solutions.addAll(o.ER_AdditionalProducts__c.split(Constants.COMMA));
                    }
                }
  
          if (String.isNotBlank(o.ER_BUPicklist__c))
                    countryCodes.add(o.ER_BUPicklist__c);
  
                // gather opportunities by solutions
          for (String sol : oppSolutions) {
                    List<Opportunity> oppList = oppSolutionMap.get(sol);
            if (oppList == null) {
                        oppList = new List<Opportunity>();
                        oppSolutionMap.put(sol, oppList);
                    }
                    oppList.add(o);
                }
            }
  
        if (!pricebookIds.isEmpty() && !solutions.isEmpty()) {
          for (Auto_Enrollment_Product__mdt elem : [
                        SELECT DeveloperName, Services__c, UseWith__c
                        FROM Auto_Enrollment_Product__mdt
                        WHERE DeveloperName IN :solutions
                ]) {
            if (
                            !solutionsServicesMap.containsKey(elem.DeveloperName) &&
                                    elem.Services__c != null &&
                                    (elem.useWith__c == null || solutions.contains(elem.useWith__c))
                    ) {
                        solutionsServicesMap.put(elem.DeveloperName, elem.Services__c.split(Constants.PIPE_SEPARATOR));
                        System.debug(
                                '>>>> HDA added sol/service = ' +
                                        elem.DeveloperName +
                                        ' / ' +
                                        elem.Services__c.split(Constants.PIPE_SEPARATOR)
                        );
                    }
                }
  
                // No solutions
          if (solutionsServicesMap.isEmpty() || oppSolutionMap.isEmpty()) {
                    return;
                }
  
                Set<String> pCodes = new Set<String>();
          for (String sol : solutionsServicesMap.keySet()) {
                    pCodes.addAll(solutionsServicesMap.get(sol));
                }
  
                List<PricebookEntry> pbeList = [
                        SELECT
              id,
              Product2Id,
              Product2.ER_Solution_Code__c,
              ProductCode,
              Pricebook2Id,
              ER_Percentage__c,
              Product2.ER_Type__c,
              Product2.ER_Solution__r.ER_Service_Range_Type__c,
              ER_Offer_validity_end_date__c,
              ER_Max__c,
              ER_Min__c,
              ER_Offer_validity_start_date__c,
              ER_Price_End_Date__c,
              ER_Duration__c,
              Product2.ER_Service_Range_Type__c
                        FROM PricebookEntry
                        WHERE Product2.ProductCode IN :pCodes AND Pricebook2Id IN :pricebookIds
                ];
  
          if (pbeList.isEmpty()) {
                    return;
                }
  
                // Services / Ranges => pbPBeEnteries = Map<Pricebook, Map<Solution, List<Service,Ranges>>>
                Map<id, Map<String, List<PricebookEntry>>> pbPBeEntries = new Map<id, Map<String, List<PricebookEntry>>>();
          for (PricebookEntry pbe : pbeList) {
                    // skip Solution with ranges
            if (
                            pbe.Product2.ER_Type__c == Constants.SERVICE &&
                                    (pbe.Product2.ER_Service_Range_Type__c == constants.RANGE_WITH_VARIABLE_PRICE_VOLUME_PRICING ||
                                            pbe.Product2.ER_Service_Range_Type__c == Constants.RANGE_WITH_FIX_PRICE)
                    ) {
                        continue;
                    }
                    // TODO Choose which Range to use for Ranges with FIX PRICE
                    Map<String, List<PricebookEntry>> pbeMap = pbPBeEntries.get(pbe.Pricebook2Id);
            if (pbeMap == null) {
                        pbeMap = new Map<String, List<PricebookEntry>>();
                        pbPBeEntries.put(pbe.Pricebook2Id, pbeMap);
                    }
                    List<PricebookEntry> pbeListToAdd = pbeMap.get(pbe.ProductCode);
            if (pbeListToAdd == null) {
                        pbeListToAdd = new List<PricebookEntry>();
                        pbeMap.put(pbe.ProductCode, pbeListToAdd);
                    }
                    pbeListToAdd.add(pbe);
                }
                System.debug('>>>> HDA pbPBeEnteries = ' + pbPBeEntries);
  
                // For each solution we have the opportunities to process :
                List<OpportunityLineItem> olies = new List<OpportunityLineItem>();
                Map<Id, Set<String>> alreadyAddedServicesMap = new Map<Id, Set<String>>();
          for (String sol : oppSolutionMap.keySet()) {
                    System.debug('>>>> HDA iter sol = ' + sol);
            for (Opportunity opp : oppSolutionMap.get(sol)) {
                        Map<String, List<PricebookEntry>> pbeMap = pbPBeEntries.get(opp.Pricebook2Id);
                        List<String> services = solutionsServicesMap.get(sol);
              if (services != null) {
                for (String service : services) {
                                Set<String> addedServices = alreadyAddedServicesMap.get(opp.id);
                  if (addedServices == null) {
                                    addedServices = new Set<String>();
                                    alreadyAddedServicesMap.put(opp.id, addedServices);
                  } else if (addedServices.contains(service)) {
                                    continue; // do not add twice the same service
                                }
  
                                System.debug('>>>> HDA iter service = ' + service);
                                List<PricebookEntry> rangePBE = pbeMap.get(service);
                                System.debug('>>>> HDA iter rangePBE = ' + rangePBE);
                  if (rangePBE != null) {
                    for (PricebookEntry rPbe : rangePBE) {
                                        System.debug('>>>> HDA allocateOLI pbe = ' + rPbe);
                                        olies.add(allocateOLI(opp, rPbe));
                                        addedServices.add(service);
                                    }
                                }
                            }
                        }
                    }
                }
          if (!olies.isEmpty()) {
                    Database.insert(olies, false);
                }
            }
      } catch (Exception e) {
            system.debug(' >>> HDA createAutoenrollmentOpportunityLineItems Exception :' + e.getMessage());
        }
    }
  
    /**
     * @description allocateOLI
     * @author Hassan DAKHCHA | 06-16-2023
     * @param opp
     * @param pbe
     * @return OpportunityLineItem
     **/
    private static OpportunityLineItem allocateOLI(Opportunity opp, PricebookEntry pbe) {
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.opportunityId = opp.id;
        oli.PricebookEntryId = pbe.id;
        oli.ER_BUPicklist__c = opp.ER_BUPicklist__c;
        oli.ER_Percentage__c = (pbe.ER_Percentage__c != null ? pbe.ER_Percentage__c : null);
      if (pbe.Product2.ER_Type__c == Constants.RANGE) {
        if (pbe.Product2.ER_Solution__r.ER_Service_Range_Type__c == Constants.RANGE_WITH_FIX_PRICE)
                oli.ER_Line_Type__c = Constants.FIX_RANGE;
            else
                    oli.ER_Line_Type__c = Constants.VARIABLE_RANGE_VOLUME_PRICING;
        } else
                oli.ER_Line_Type__c = pbe.Product2.ER_Type__c;
        oli.ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c;
        oli.ER_Max__c = pbe.ER_Max__c;
        oli.ER_Min__c = pbe.ER_Min__c;
        oli.ER_Price_Start_Date__c = pbe.ER_Offer_validity_start_date__c;
        oli.ER_Price_End_Date__c = pbe.ER_Price_End_Date__c;
        oli.ER_Duration__c = pbe.ER_Duration__c;
        return oli;
    }
  
    /**
     * @description : Default autoenrollment opportunities values
     * @author Hassan DAKHCHA | 05-24-2023
     * @param opportunities
     **/
    public static void autoenrollmentDefaultingValues(List<Opportunity> opportunities) {
        Set<String> autoenrollmentBUs = new Set<String>();
        autoenrollmentBUs.addAll(
                Auto_Enrollment__mdt.getInstance(Constants.AUTO_ENROLLMENT_BU_LIST).value__c.split(Constants.PIPE_SEPARATOR)
        );
      for (Opportunity o : opportunities) {
        if (
                    autoenrollmentBUs.contains(o.ER_BUPicklist__c) &&
                            o.LeadSource == Constants.CONTRACTING_WEBFORM &&
                            o.ER_Reason__c != Constants.CROSS_SELLING_REASON
            ) {
                o.StageName = Constants.PROPOSAL;
                o.ER_PaymentTerms__c = Constants.OPP_PAYMENT_TERM_PRE_PAID;
                o.Type = Constants.CONTRACT_TYPE_OPERATIONAL;
                o.ER_Reason__c = Constants.NEW_STATUS;
                o.ER_Contract_Duration__c = Constants.ZUORA_TERM_TYPE_EVERGREEN;
                o.ER_Expiration_Notice_Period__c = null;
            }
        }
    }
  
    /**
     * @description : to set pricebook on the opportunity before update when ER_Solutions__c are set on the opportunity
     * @author Hassan DAKHCHA | 06-14-2023
     * @param opportunities
     * @param oldItems
     **/
    public static void autoenrollmentSetPriceBook(List<Opportunity> opportunities, Map<id, Opportunity> oldItems) {
        Set<String> autoenrollmentBUs = new Set<String>();
        autoenrollmentBUs.addAll(
                Auto_Enrollment__mdt.getInstance(Constants.AUTO_ENROLLMENT_BU_LIST).value__c.split(Constants.PIPE_SEPARATOR)
        );
  
        List<Opportunity> oppToProcess = new List<Opportunity>();
        Set<String> solutions = new Set<String>();
      for (Opportunity o : opportunities) {
            System.debug('>>>>> HDA - autoenrollmentSetPriceBook BUs  ' + autoenrollmentBUs);
            System.debug('>>>>> HDA - autoenrollmentSetPriceBook opp BU  ' + o.ER_BUPicklist__c);
            System.debug('>>>>> HDA - autoenrollmentSetPriceBook SOLUTION  ' + o.ER_Solutions__c);
            System.debug('>>>>> HDA - autoenrollmentSetPriceBook old Sol  ' + oldItems.get(o.id).ER_Solutions__c);
  
        if (
                    autoenrollmentBUs.contains(o.ER_BUPicklist__c) &&
                            o.LeadSource == Constants.CONTRACTING_WEBFORM &&
                            o.ER_Solutions__c != null &&
                            oldItems.get(o.id).ER_Solutions__c != o.ER_Solutions__c &&
                            o.ER_Reason__c != Constants.CROSS_SELLING_REASON
            ) {
                solutions.addAll(o.ER_Solutions__c.deleteWhitespace().split(Constants.SLASH));
          if (String.isNotBlank(o.ER_Benefits__c))
                    solutions.addAll(o.ER_Benefits__c.split(Constants.PIPE_SEPARATOR));
          if (String.isNotBlank(o.ER_CardType__c))
                    solutions.addAll(o.ER_CardType__c.split(Constants.PIPE_SEPARATOR));
                oppToProcess.add(o);
            }
        }
        System.debug('>>>>> HDA - autoenrollmentSetPriceBook solutions  ' + solutions);
  
      if (!solutions.isEmpty()) {
            Map<String, Auto_Enrollment_Product__mdt> mapProductMdt = new Map<String, Auto_Enrollment_Product__mdt>();
            Set<String> priceBookNames = new Set<String>();
        for (Auto_Enrollment_Product__mdt mdt : [
                    SELECT DeveloperName, Pricebook__c, Nbr_Employee_cond__c, Type__c, Name__c, useWith__c
                    FROM Auto_Enrollment_Product__mdt
                    WHERE developerName IN :solutions
            ]) {
          if (String.isNotBlank(mdt.Pricebook__c)) {
                    mapProductMdt.put(mdt.developerName, mdt);
                    priceBookNames.add(mdt.Pricebook__c);
                }
            }
  
            System.debug('>>>>> ALK - mapProductMdt : ' + mapProductMdt);
            Map<String, Id> mapSolPBIds = new Map<String, Id>();
  
        if (!mapProductMdt.isEmpty()) {
          for (Pricebook2 pb : [
                        SELECT Id, ER_BUPicklist__c, ER_MDMId__c
                        FROM Pricebook2
                        WHERE ER_MDMId__c IN :priceBookNames
                ]) {
            if (String.isNotBlank(pb.ER_MDMId__c))
                        mapSolPBIds.put(pb.ER_MDMId__c, pb.Id);
                }
                System.debug('>>>>> ALK - mapSolPBIds : ' + mapSolPBIds);
          if (!mapSolPBIds.isEmpty()) {
            for (Opportunity o : oppToProcess) {
                        System.debug(
                                '>>>>> ALK - o.Er_Benefits__c : ' + o.Er_Benefits__c + ' o.ER_CardType__c : ' + o.ER_CardType__c
                        );
              if (
                                mapProductMdt.containsKey(o.ER_Solutions__c) &&
                                        mapSolPBIds.containsKey(mapProductMdt.get(o.ER_Solutions__c).Pricebook__c)
                        ) {
                if (
                                    String.isNotBlank(o.Er_Benefits__c) &&
                                            String.isNotBlank(o.ER_CardType__c) &&
                                            mapProductMdt.containsKey(o.ER_Benefits__c) &&
                                            mapProductMdt.containsKey(o.ER_CardType__c) &&
                                            mapSolPBIds.containsKey(mapProductMdt.get(o.ER_Benefits__c).Pricebook__c) &&
                                            (mapProductMdt.get(o.ER_Benefits__c).Nbr_Employee_cond__c == null ||
                                                    o.ER_Nb_of_Employees__c < mapProductMdt.get(o.ER_Benefits__c).Nbr_Employee_cond__c) &&
                                            o.ER_Benefits__c == mapProductMdt.get(o.ER_Benefits__c).developerName &&
                                            mapProductMdt.get(o.ER_Benefits__c).Type__c == Constants.BENEFIT_TYPE &&
                                            (mapProductMdt.get(o.ER_Benefits__c).UseWith__c == null ||
                                                    mapProductMdt.get(o.ER_Benefits__c).UseWith__c.contains(o.ER_Solutions__c)) &&
                                            o.ER_CardType__c == mapProductMdt.get(o.ER_CardType__c).developerName &&
                                            mapProductMdt.get(o.ER_CardType__c).Type__c == Constants.CARD_TYPE &&
                                            (mapProductMdt.get(o.ER_CardType__c).UseWith__c == null ||
                                                    mapProductMdt.get(o.ER_CardType__c).UseWith__c.contains(o.ER_Solutions__c))
                            )
                                o.Pricebook2Id = mapSolPBIds.get(mapProductMdt.get(o.ER_CardType__c).Pricebook__c);
                            else
                                    o.Pricebook2Id = mapSolPBIds.get(mapProductMdt.get(o.ER_Solutions__c).Pricebook__c);
                            System.debug('>>>>> HDA - autoenrollmentSetPriceBook  o.Pricebook2Id  ' + o.Pricebook2Id);
                        }
                    }
                }
            }
        }
    }
  
    /**
     * @description
     * @author Hassan DAKHCHA | 05-24-2023
     * @param opportunities
     * @param oldItems
     **/
    public static void generateOpportunityLineItem(List<Opportunity> opportunities, Map<Id, Opportunity> oldItems) {
        Set<String> autoenrollmentBUs = new Set<String>();
      autoenrollmentBUs.addAll(
        Auto_Enrollment__mdt.getInstance(Constants.AUTO_ENROLLMENT_BU_LIST).value__c.split(Constants.PIPE_SEPARATOR)
      );
        List<Opportunity> electedOpps = new List<Opportunity>();
  
      for (Opportunity o : opportunities) {
        if (
          !autoenrollmentBUs.contains(o.ER_BUPicklist__c) ||
          (o.LeadSource != Constants.AUTO_ENROLLMENT &&
          o.LeadSource != Constants.CONTRACTING_WEBFORM) ||
          o.ER_Solutions__c == null ||
          o.ER_BUPicklist__c == null ||
          o.ER_BUPicklist__c == Constants.BENELUX ||
          o.Pricebook2Id == null ||
          o.ER_Reason__c == Constants.CROSS_SELLING_REASON
        ) {
                continue;
            }
  
        if (
          (String.isNotBlank(o.ER_Solutions__c) && oldItems == null) ||
          (oldItems != null &&
          String.isNotBlank(o.ER_Solutions__c) &&
          o.ER_Solutions__c != oldItems.get(o.Id).ER_Solutions__c &&
          oldItems.get(o.Id).ER_Solutions__c == null)
        ) {
                electedOpps.add(o);
            }
        }
  
      if (!electedOpps.isEmpty()) {
            createAutoenrollmentOpportunityLineItems(electedOpps);
            Quote updatedQuote = VFCER04_Opportunity_Product.saveAsQuote(electedOpps[0].Id);
            Id oppRTId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, Constants.OPPORTUNITY_CLIENT_RT);
            if(updatedQuote != null) {
                Database.update(new Quote(Id = updatedQuote.Id, Status = Constants.ACCEPTED), false);
  
                if(electedOpps[0].RecordTypeId == oppRTId) activateOAClientContract(electedOpps[0].Id);
                else Database.update(new Opportunity(Id = electedOpps[0].Id, StageName = Label.LABS_SF_Opp_Status_Negotiation));
  
                try {
                    List<Opportunity> opportunity = [SELECT Account.HU_HQ_Contact__c, Account.HU_HQ_Contact__r.FirstName,
                            Account.HU_HQ_Contact__r.LastName, Account.HU_HQ_Contact__r.Email,
                            Account.HU_HQ_Contact__r.ER_Language__c,
                            Account.HU_HQ_Contact__r.ER_Onboarding_Contract__c, ContractId
                            FROM Opportunity
                            WHERE Id = :electedOpps[0].Id];
  
                    Contact aContact = new Contact(
                            Id = opportunity[0].Account.HU_HQ_Contact__c,
                            FirstName = opportunity[0].Account.HU_HQ_Contact__r.FirstName,
                            LastName = opportunity[0].Account.HU_HQ_Contact__r.LastName,
                            Email = opportunity[0].Account.HU_HQ_Contact__r.Email,
                            ER_Language__c = opportunity[0].Account.HU_HQ_Contact__r.ER_Language__c,
                            ER_Onboarding_Contract__c = opportunity[0].ContractId
                    );
                    if(electedOpps[0].RecordTypeId != oppRTId) APER30_AutoEnrollment_Management.sendWelcomeEmailUsers(new List<Contact> {aContact});
                } catch(Exception e) {
                    System.debug(' >>> Email Exception:' + e.getMessage());
                }
            }
        }
    }
  
    @Future(Callout=true)
    public static void activateOAClientContract(Id opportunityId) {
        if(String.isNotBlank(opportunityId)) {
            Opportunity opp = [SELECT Id, ContractId, ER_BUPicklist__c, AccountId FROM Opportunity WHERE Id = :opportunityId];
            APER30_AutoEnrollment_Management.syncRecordBU = opp.ER_BUPicklist__c;
            APER30_FinancialCenter_Management.Bypass_FI_VR_OPT = false;
            List <String> syncResultList = APHU12_Contract_Management.saveContractEdgWSV3(opp.AccountId, opp.ContractId, 'Activation');
            if (syncResultList!=null && !syncResultList.isEmpty()){
                System.debug(LoggingLevel.DEBUG,'>>>>> ALK - syncResultList ' + syncResultList);
                System.debug(LoggingLevel.DEBUG,'>>>>> ALK - syncResultList[0] ' + syncResultList[0]);
                System.debug(LoggingLevel.DEBUG,'>>>>> ALK - syncResultList[0] == \'succeeded\' ' + (syncResultList[0] == 'succeeded'));
                if(syncResultList[0] == 'succeeded') {
                    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
                    List <Contract> contracts = APER12_Contract_Management.getContract(new List <String> {opp.ContractId});
                    APER12_Contract_Management.activateContractController(contracts[0], null, isOfflineBU);
                    Database.update(new Opportunity(Id = opp.Id, ER_Won_Reason__c = 'Auto-Enrollment', StageName = Label.LABS_SF_Opp_Status_ClosedWon));
                }
            }
           
        }
    }
      /**
       * @description This method fetches and maps Opportunity Line Item data to corresponding Contract Line Items 
       *              based on a common product identifier. It retrieves specific fields from Opportunity Line Items
       *              and organizes them into a structured map for further processing.
       * @author Pranjal Tiwari | 01-20-2025
       * @param opportunityId The ID of the Opportunity to which the Opportunity Line Items belong.
       * @param contractLineItems A list of ER_ContractLineItem__c records containing the products to match.
       * @return A map where the key is the ID of the Contract Line Item, and the value is another map containing 
       *         the required Opportunity Line Item field values.
       **/
      public static Map<Id, Map<String, Object>> fetchOpportunityLineItemData(List<ER_ContractLineItem__c> contractLineItems, String opportunityId) {
          // Map to store the results
          Map<Id, Map<String, Object>> resultMap = new Map<Id, Map<String, Object>>();
  
          // Collect unique ER_Product2__c values from contract line items
          Set<Id> productIds = new Set<Id>();
          for (ER_ContractLineItem__c cli : contractLineItems) {
              if (cli.ER_Product2__c != null) {
                  productIds.add(cli.ER_Product2__c);
              }
          }
  
          // Query Opportunity Line Items matching the Product2Id
          // Query OpportunityLineItems and use Product2Id as the key
          Map<Id, OpportunityLineItem> productToOliMap = new Map<Id, OpportunityLineItem>();
          if (!Test.isRunningTest()) {
          for (OpportunityLineItem oli : [
              SELECT Id, Product2Id, ER_Nb_Beneficiaries__c, ER_Load_Per_Year__c, 
                  ER_Days_Per_Month__c, ER_Face_Value__c, Opportunity.ER_Estimated_Number_Of_Beneficiaries__c
              FROM OpportunityLineItem
              WHERE Product2Id IN :productIds AND OpportunityId = :opportunityId
          ]) {
              productToOliMap.put(oli.Product2Id, oli);
            }
          }
  
          // Map Opportunity Line Item data to the corresponding Contract Line Item
          for (ER_ContractLineItem__c cli : contractLineItems) {
              if (cli.ER_Product2__c != null && productToOliMap.containsKey(cli.ER_Product2__c)) {
                  OpportunityLineItem oli = productToOliMap.get(cli.ER_Product2__c);
                  // Store required fields in a map
                  Map<String, Object> fieldValues = new Map<String, Object>{
                      'ER_Nb_Beneficiaries__c' => oli.Opportunity.ER_Estimated_Number_Of_Beneficiaries__c,
                      'ER_Load_Per_Year__c' => oli.ER_Load_Per_Year__c,
                      'ER_Days_Per_Month__c' => oli.ER_Days_Per_Month__c,
                      'ER_Face_Value__c' => oli.ER_Face_Value__c
                  };
  
                  // Add to the result map
                  resultMap.put(cli.Id, fieldValues);
              }
          }
  
          return resultMap;
      }

      @InvocableMethod(label='Update Opportunity Senior Manager' description='Updates Senior Manager on Opportunity' category='Opportunity')
        public static void callUpdateSeniorManagers(List<InputVariables> inputWrapperList) {
            if (inputWrapperList == null || inputWrapperList.isEmpty()) return;

            List<Opportunity> oppList = inputWrapperList[0].allOpps;
            if (oppList != null && !oppList.isEmpty()) {
                List<Id> oppIds = new List<Id>();
                for (Opportunity o : oppList) {
                    oppIds.add(o.Id);
                }
                updateSeniorManagerAsync(oppIds);
            }
        }

        public class InputVariables {
            @InvocableVariable
            public List<Opportunity> allOpps;
        }
        @future
        public static void updateSeniorManagerAsync(List<Id> opportunityIds) {

            if (opportunityIds == null || opportunityIds.isEmpty()) return;

            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :opportunityIds]
            );

            Set<Id> ownerIds = new Set<Id>();
            for (Opportunity opp : oppMap.values()) {
                if (opp.OwnerId != null && String.valueOf(opp.OwnerId).startsWith('005')) {
                    ownerIds.add(opp.OwnerId);
                }
            }

            Map<Id, User> userMap = new Map<Id, User>(
                [SELECT Id, ManagerId FROM User WHERE Id IN :ownerIds]
            );

            Set<Id> managerIds = new Set<Id>();
            for (User u : userMap.values()) {
                if (u.ManagerId != null) {
                    managerIds.add(u.ManagerId);
                }
            }

            Map<Id, User> managerMap = new Map<Id, User>(
                [SELECT Id, ManagerId FROM User WHERE Id IN :managerIds]
            );

            List<Opportunity> updates = new List<Opportunity>();
            for (Opportunity opp : oppMap.values()) {
                Id seniorManagerId;

                User owner = userMap.get(opp.OwnerId);
                if (owner != null) {
                    User manager = managerMap.get(owner.ManagerId);
                    if (manager != null && manager.ManagerId != null) {
                        seniorManagerId = manager.ManagerId;
                    } else if (owner.ManagerId != null) {
                        seniorManagerId = owner.ManagerId;
                    } else {
                        seniorManagerId = opp.OwnerId;
                    }
                } else {
                    seniorManagerId = opp.OwnerId;
                }

                Opportunity o = new Opportunity(Id = opp.Id);
                o.Senior_Manager__c = seniorManagerId;
                updates.add(o);
            }

            if (!updates.isEmpty()) {
                update updates;
            }
        }
  }