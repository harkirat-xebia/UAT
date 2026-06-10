/*
----------------------------------------------------------------------
-- - Name          : VFCER05_Opportunity_EditPrice
-- - Author        : OLA
-- - Description   : The controller of the page VFER05_Opportunity_EditPrice
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Dec-2018       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

global class VFCER05_Opportunity_EditPrice {

    //public String opportunityId;
    public Map<String,Product2> solutionsByIdMap { get; set; }
    public Opportunity opportunityRecord { get; set; }
    public String priceBookName { get; set; }
    public List<String> opportunityFields;
    public List<Global_Settings__mdt> renderEstimationForBUSettings { get; set; } //Added on 5 September, 2024
    public Set<String> renderIssuedVolumeBUSet {get; set;} //Added on 5 September, 2024

    public VFCER05_Opportunity_EditPrice(ApexPages.StandardController controller) {     
        
        priceBookName = '';
        //opportunityId = ApexPages.currentPage().getParameters().get('id');

        //opportunityRecord = (Opportunity) controller.getRecord();
        opportunityRecord = new Opportunity();

        if(String.isNotBlank(controller.getId())) {
            opportunityFields = new List<String>();
            opportunityFields.add('Pricebook2.name');
            opportunityFields.add('Pricebook2id');
            opportunityFields.add('AccountId');
            opportunityFields.add('ER_IsAmended__c');
            opportunityFields.add('ER_AmendedFromOpportunity__r.ContractId');
            opportunityFields.add('ER_AmendedFromContract__c');
            opportunityFields.add('ER_BUPicklist__c');
            opportunityFields.add('Type');
            opportunityFields.add('ER_Promo_Code2__c');
            opportunityFields.add('ER_Vat__c');
            opportunityFields.add('Min_Approval_Value__c');		
            opportunityFields.add('Max_Discount__c');			
            if(!Test.isRunningTest()) controller.addFields(opportunityFields);

            opportunityRecord = (Opportunity) controller.getRecord();
            //opportunityRecord = [select id, Pricebook2.name, Pricebook2id  from Opportunity where id = : opportunityId];
            if(String.isNotBlank(opportunityRecord.Pricebook2id)) {
                priceBookName = opportunityRecord.Pricebook2.name;
            }
        }
    }

    /**
	* @author Abdallah Timsouani
	* @date 01/08/2023 (dd/mm/yyyy)
	* @description getServices : check if the selected solutions are already in an active contract for the linked account
	* @param solutionMap
	* @param contractType
	* @param opportunityId
	* @param accountId
	*/
    public static void checkExistingContract(Map<String, String> solutionMap, String accountId, String opportunityId, String contractType) {
        String errorMessage;
        List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('Bypass_Active_Contract_Process'));
        String oppRT = [SELECT Id, RecordType.DeveloperName FROM Opportunity WHERE Id = :opportunityId].RecordType.DeveloperName;
        String contractRT = (oppRT == Constants.OPPORTUNITY_MERCHANT_RT ? Constants.CONTRACT_MERCHANT_RT : Constants.CONTRACT_CLIENT_RT);
        Opportunity opp = [Select Id, ER_AmendedFromContract__c FROM Opportunity WHERE Id =:opportunityId];

        for(ER_ContractLineItem__c cli : [
                SELECT Id, ER_Contract__c, ER_Contract__r.ContractNumber, ER_Contract__r.ER_OpportunityId__r.ER_AmendedFromContract__c,ER_Contract__r.ER_OpportunityId__r.Auto_Enrolment_Opportunity__c, ER_Solution__c, ER_Product2__r.ER_Solution__c, ER_Product2__r.ER_Solution__r.Name
                FROM ER_ContractLineItem__c
                WHERE ER_Contract__r.AccountId = :accountId
                AND ER_Contract__r.Status = :Constants.ACTIVATED
                AND ER_Contract__r.ER_BUPicklist__c NOT IN :bus
                AND ER_Contract__r.ER_Contract_Type__c = :contractType
                AND ER_Contract__r.RecordType.DeveloperName = :contractRT
                AND ER_Contract__r.ER_OpportunityId__r.Auto_Enrolment_Opportunity__c = false
        ]) {

            if(solutionMap.containsKey(cli.ER_Solution__c) && String.isNotBlank(cli.ER_Product2__r.ER_Solution__c) && opp.ER_AmendedFromContract__c == null) {
                errorMessage = Label.LABS_SF_Opp_Price_ProductExistInContract;
                errorMessage = errorMessage.replace('{0}', solutionMap.get(cli.ER_Solution__c)).
                        replace('{1}', cli.ER_Solution__c).
                        replace('{2}', '/' + cli.ER_Contract__c).
                        replace('{3}', cli.ER_Contract__r.ContractNumber);

                throw new VisualforceException(errorMessage);
            }

        }
    }

    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description getServices : get services linked to the selected solutions in Phase 1
     * @param accountId
     * @param contractId
     * @param contractType
     * @param aOpportunityId
     * @param isAmendedOpportunity
     * @param priceBook2Id
     * @param productList
     * @return List
    */
    @RemoteAction
    global static List<PricebookEntry> getServices(List<String> productList, String priceBook2Id, String accountId, Boolean isAmendedOpportunity, String contractId, String contractType, String aOpportunityId) {
        List<PricebookEntry> serviceList;

        if(!productList.isEmpty()) {
            Set<String> productIdSet = new Set<String>();//Set of selected solutions
            for(Id productid : productList) {
                productIdSet.add(productid);
            }

            //Opportunity oppRec = [SELECT Id, ER_BUPicklist__c FROM Opportunity WHERE Id = :aOpportunityId LIMIT 1];

            List<PricebookEntry> testServ = [
                    SELECT Id, Name, Product2.ER_Type__c, IsActive, Product2.ER_Solution__c, Pricebook2Id
                    FROM PricebookEntry
                    WHERE Product2.ER_Type__c = 'service'
                    AND Pricebook2Id = :priceBook2Id AND IsActive = TRUE];
            serviceList = [SELECT Id, Name, ER_Configuration__c, UnitPrice, ER_Approval_Trigger_Value__c,
                            ER_Approval_Trigger_Value_Max__c, Product2.Description, Product2.ER_Solution__c,
                            Product2.ER_Solution__r.Name, product2.ER_Solution_Code__c, Pricebook2.ER_Business_Unit__c,
                            ER_Percentage__c, IsActive, CurrencyIsoCode, Product2.ER_Minimum_Fee__c, ProductCode,
                            Product2.ER_Service_Range_Type__c, product2.ER_Service_Number_of_Ranges__c, ER_Price_End_Date__c,
                            Product2.ER_Number_of_Discount_Products__c, ER_Offer_validity_end_date__c, ER_Promo_Code2__c, ER_Duration__c,
                            Product2.RecordType.Name, Product2.ER_What__c, Product2.ProductCode,
                            Product2.ER_Solution__r.ProductCode, ER_Offer_validity_start_date__c, ER_Promo_Code2__r.Name
                    FROM PricebookEntry
                    WHERE Product2.ER_Solution__c IN :productIdSet AND Product2.ER_Type__c = 'service'
                    AND Pricebook2Id = :priceBook2Id AND IsActive = TRUE
                    ORDER BY Product2.ER_Solution__c, Product2.ER_Solution__r.ER_Line_Order__c, Product2.ER_Line_Order__c ASC];

            // Map solution Code and SOlution ID
            Map<String, String> solutionMap = new Map<String, String>();
            for(PricebookEntry pbe : serviceList) {
                if(String.isNotBlank(pbe.Product2.ER_Solution_Code__c)) {
                    solutionMap.put(pbe.Product2.ER_Solution_Code__c, pbe.Product2.ER_Solution__c);
                }
            }

            //Check if there is already a contract linked to the solutions selected
            //OLA Update 02042019 check also the CLI Solution Code
            checkExistingContract(solutionMap, accountId, aOpportunityId, contractType);
        }

        return serviceList;
    }

    /**
    * @author VJoy
    * @date 05/02/2021 (dd/mm/yyyy)
    * @description getRangesByService
    */
    @RemoteAction
    global static String getRangesByServices(List<String> productList, String priceBook2Id, String accountId, Boolean isAmendedOpportunity, String contractId) {

        List<pricebookentry> serviceList;
        List<pricebookentry> product2List;
        Set<Id> rangeProductIdSet = new Set<Id>();

        Map<Id, List<pricebookentry>> solutionMap = new Map<Id, List<pricebookentry>>();
        Id rangeRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Range').getRecordTypeId();


        if(!productList.isEmpty()) {

            Set<String> productIdSet = new Set<String>();//Set of selected solutions
            for(Id productid : productList) {
                productIdSet.add(productid);
            }

            serviceList = [
                    SELECT id, Name, ER_Configuration__c, UnitPrice, ER_Approval_Trigger_Value__c, ER_Approval_Trigger_Value_Max__c, product2.Description, product2.ER_solution__c, product2.ER_solution__r.Name, product2.ER_Solution_Code__c, pricebook2.ER_Business_Unit__c, ER_Percentage__c, isactive, CurrencyIsoCode, product2.ER_Minimum_Fee__c, product2.ER_Service_Range_Type__c, product2.ER_Service_Number_of_Ranges__c, ProductCode, product2.ER_Solution__r.ER_Service_Range_Type__c
                    FROM pricebookentry
                    WHERE product2.ER_solution__c IN :productIdSet AND product2.ER_Type__c = 'service'
                    AND pricebook2Id = :priceBook2Id
                    AND isactive = true
                    AND Product2.ER_Service_Range_Type__c != 'Without Range'
                    ORDER BY product2.ER_solution__r.ER_Line_Order__c, product2.ER_Line_Order__c ASC
            ];


            Set<Id> rangeServiceIdSet = new Set<Id>();
            for(pricebookentry pbe : serviceList) {

                if(pbe.Product2.ER_Service_Number_of_Ranges__c > 0) {
                    rangeServiceIdSet.add(pbe.Product2Id);
                }

            }


            for(Product2 pbe : [
                    SELECT id, Name, Description, ER_Solution_Code__c, ER_Solution__c, ER_Business_Unit__c, isactive, ER_Minimum_Fee__c, ER_Service_Range_Type__c, ER_What__c, ER_Solution__r.ER_Service_Range_Type__c
                    FROM Product2
                    WHERE ER_Solution__r.Id IN :rangeServiceIdSet
                    AND isactive = true
                    ORDER BY ER_Line_Order__c ASC
            ]) {

                rangeProductIdSet.add(pbe.Id);

            }


            product2List = [
                    SELECT id, Name, Product2.Name, ER_Configuration__c, UnitPrice,Product2.ER_Solution2__r.Solution_Group__c,Product2.ER_Solution__r.Product_Tier__c,Product2.ER_Solution2__r.ProductCode, Product2.ER_Solution2__r.Product_Tier__c, Product2.ER_Solution2__c, Product2.ER_Solution2__r.Name, ER_Approval_Trigger_Value__c, ER_Approval_Trigger_Value_Max__c, product2.Description, product2.ER_solution__c, product2.ER_solution__r.Name, product2.ER_Solution_Code__c, Product2.ER_Solution__r.ER_Service_Range_Type__c, pricebook2.ER_Business_Unit__c, ER_Percentage__c, isactive, CurrencyIsoCode, product2.ER_Minimum_Fee__c, ProductCode, product2.ER_Service_Range_Type__c, product2.ER_Service_Number_of_Ranges__c, ER_Max__c, ER_Min__c, Product2.ER_Number_of_Discount_Products__c, ER_Price_End_Date__c, ER_Offer_validity_end_date__c, ER_Promo_Code2__c, ER_Duration__c, Product2.Recordtype.Name, Product2.ER_What__c, ER_Promo_Code2__r.Name
                    FROM pricebookentry
                    WHERE product2Id IN :rangeProductIdSet AND isactive = TRUE AND pricebook2Id = :priceBook2Id
                    ORDER BY ER_Min__c, product2.ER_Line_Order__c ASC
            ];


            for(pricebookentry pbe : product2List) {

                List<pricebookentry> entitiesForKey = solutionMap.get(pbe.product2.ER_solution__c);
                if(entitiesForKey == null) {
                    entitiesForKey = new List<pricebookentry>();
                    solutionMap.put(pbe.product2.ER_solution__c, entitiesForKey);
                }
                entitiesForKey.add(pbe);
            }

        }
        return JSON.serialize(solutionMap);
    }

    /**
    * @author VJoy
    * @date 01/03/2021 (dd/mm/yyyy)
    * @description getdiscountByParents
    */
    @RemoteAction
    global static String getdiscountByParents(List<String> productList, String priceBook2Id, String accountId, Boolean isAmendedOpportunity, String contractId, String aOpportunityId) {

        List<pricebookentry> serviceList;
        List<pricebookentry> serviceListProcessed = new List<pricebookentry>();
        List<pricebookentry> product2List;
        Set<Id> discountProductIdSet = new Set<Id>();

        Map<Id, List<pricebookentry>> solutionMap = new Map<Id, List<pricebookentry>>();
        Id rangeRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Range').getRecordTypeId();
        Id serviceRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id discountRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Discount').getRecordTypeId();

        Opportunity oppRec = [SELECT Id, ER_Promo_Code2__c, ER_Promo_Code2__r.Name, ER_BUPicklist__c FROM Opportunity WHERE Id = :aOpportunityId LIMIT 1];

        if(!productList.isEmpty()) {

            Set<String> productIdSet = new Set<String>();//Set of selected solutions
            System.debug('productList : ' + productList);
            for(Id productid : productList) {
                productIdSet.add(productid);
            }

            System.debug('productIdSet : ' + productIdSet);
            serviceList = [
                    SELECT id, Name, ER_Configuration__c, UnitPrice, ER_Approval_Trigger_Value__c, ER_Approval_Trigger_Value_Max__c, product2.Description, product2.ER_solution__c, product2.ER_solution__r.Name, product2.ER_Solution_Code__c, pricebook2.ER_Business_Unit__c, ER_Percentage__c, isactive, CurrencyIsoCode, product2.ER_Minimum_Fee__c, ProductCode, product2.ER_Service_Range_Type__c, product2.ER_Service_Number_of_Ranges__c, ER_Price_End_Date__c, Product2.ER_Number_of_Discount_Products__c, ER_Offer_validity_end_date__c, ER_Promo_Code2__c, ER_Duration__c, Product2.Recordtype.Name, Product2.ER_What__c, ER_Offer_validity_start_date__c, ER_Promo_Code2__r.Name
                    FROM pricebookentry
                    WHERE (product2.ER_solution__c IN :productIdSet OR product2.ER_solution__r.ER_solution__c IN :productIdSet)
                    AND pricebook2Id = :priceBook2Id
                    AND isActive = TRUE
                    AND (Product2.RecordtypeId = :rangeRecordTypeId OR Product2.RecordtypeId = :serviceRecordTypeId)
                    ORDER BY product2.ER_solution__r.ER_Line_Order__c, product2.ER_Line_Order__c ASC
            ];

            Set<Id> discountServiceRangeIdSet = new Set<Id>();
            for(pricebookentry pbe : serviceList) {
                if(pbe.Product2.ER_Number_of_Discount_Products__c > 0) {
                    discountServiceRangeIdSet.add(pbe.Product2Id);
                    System.debug('Discount Product Id Set' + discountServiceRangeIdSet);
                }
            }


            for(Product2 pbe : [
                    SELECT id, Name, Description, ER_Solution_Code__c, ER_Solution__c, ER_Business_Unit__c, isactive, ER_Minimum_Fee__c, ER_Service_Range_Type__c, ER_What__c
                    FROM Product2
                    WHERE ER_Solution__r.Id IN :discountServiceRangeIdSet
                    AND isactive = true
                    ORDER BY ER_Line_Order__c ASC
            ]) {

                discountProductIdSet.add(pbe.Id);

            }


            product2List = [
                    SELECT Id, Name, Product2.Name, ER_Configuration__c, UnitPrice, ER_Approval_Trigger_Value__c, ER_Approval_Trigger_Value_Max__c, Tech_DisableFieldsPromocode__c, Product2.Description, Product2.ER_Solution__c, Product2.ER_Solution__r.Name, Product2.ER_Solution_Code__c, ER_Offer_validity_start_date__c, Pricebook2.ER_Business_Unit__c, ER_Percentage__c, IsActive, CurrencyIsoCode, Product2.ER_Minimum_Fee__c, ProductCode, ER_Business_Unit__c, Product2.ER_Service_Range_Type__c, Product2.ER_Service_Number_of_Ranges__c, ER_Max__c, ER_Min__c, Product2.ER_Number_of_Discount_Products__c, ER_Price_End_Date__c, ER_Offer_validity_end_date__c, ER_Promo_Code2__c, ER_Duration__c, Product2.RecordType.Name, Product2.ER_What__c, ER_Promo_Code2__r.Name
                    FROM PricebookEntry
                    WHERE Product2Id IN :discountProductIdSet AND IsActive = TRUE
                    AND Pricebook2Id = :priceBook2Id AND Product2.RecordTypeId = :discountRecordTypeId
                    AND (ER_Offer_validity_end_date__c = NULL OR ER_Offer_validity_end_date__c >= TODAY)
                    AND (ER_Promo_Code2__c = NULL OR ER_Promo_Code2__c = :oppRec.ER_Promo_Code2__c)
                    ORDER BY Product2.ER_Line_Order__c ASC
            ];


            System.debug('Discount Product Id' + product2List);
            List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('TemporaryCode_DisableFields_BUs'));
            for(pricebookentry pbe : product2List) {
                if(bus.contains(oppRec.ER_BUPicklist__c)) pbe.Tech_DisableFieldsPromocode__c = 'Disabled';
                List<pricebookentry> entitiesForKey = solutionMap.get(pbe.Product2.ER_Solution__c);
                if(entitiesForKey == null) {
                    entitiesForKey = new List<pricebookentry>();
                    solutionMap.put(pbe.product2.ER_solution__c, entitiesForKey);
                }
                entitiesForKey.add(pbe);
            }

        }
        System.debug('Discount Product Map' + JSON.serialize(solutionMap));

        return JSON.serialize(solutionMap);
    }

    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description getSolutions : get All Opportunity's pricebook solutions
    */
    public List<PricebookEntry> getSolutions {
        get {
            if(opportunityRecord.Id != null) {
                List<PricebookEntry> solutionList = [
                        select id, Name, Pricebook2id, Pricebook2.name, Pricebook2.ER_Business_Unit__c, Product2.id, Product2.Name, Product2.ER_Type__c, isactive, Product2.ProductCode, Product2.ER_solution__r.ProductCode
                        from pricebookentry
                        where Product2.ER_Type__c = 'Solution' and Pricebook2id = :opportunityRecord.pricebook2Id and Pricebook2.isactive = true and isactive = true
                        order by product2.ER_Line_Order__c, Name asc
                ];
                System.debug('###getSolutions : ' + solutionList);
                return solutionList;
            }

            return new List<PricebookEntry>();
        }
        set {
        }
    }

    /**
    * @author Oussama LASFAR
    * @date 15/10/2019 (dd/mm/yyyy)
    * @description getProductDependencies : get Products dependencies
    */
    @RemoteAction
    public static Map<Id, ER_Product_Dependency__c> getProductDependencies(String oppBusinessUnit) {

        Map<Id, ER_Product_Dependency__c> mapProductDependencies = new Map<Id, ER_Product_Dependency__c>([
                SELECT id, ER_Controlling_Product__c, ER_Controlling_Product__r.Name, ER_Controlling_Product__r.ER_Solution__c, ER_Dependent_Product__c, ER_Dependent_Product__r.Name, ER_Dependent_Product__r.ER_Solution__c, ER_Configuration__c
                FROM ER_Product_Dependency__c
                WHERE ER_Controlling_Product__r.ER_Business_Unit__c = :oppBusinessUnit AND ER_Dependent_Product__r.ER_Business_Unit__c = :oppBusinessUnit
                AND ER_Controlling_Product__r.IsActive = true AND ER_Dependent_Product__r.IsActive = true
        ]);

        return mapProductDependencies;
    }

    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description saveOpportunityProducts : save selected opportunity line items and update current opportunity fields : ER_NeedApproval__c & ER_Approved__c
    */
    @RemoteAction
    global static Id saveOpportunityProducts(
    List<OpportunityLineItem> lineItemsToSave, 
    String opportunityId, 
    String additionalDataJson,
    Decimal maxDiscount
    ) {
        String errorMsg = Label.LAB_SF_OPP_DEFAULT_PRICE_VALIDATION;
        Set<Id> setOli = new Set<Id>();
        List<String> busSkipValueCheck = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('OPPORTUNITY_SKIP_VALUE_CHECK_GREATER'));
        Map<Id, String> pbeIdMap = new Map<Id, String>();
        Set<Id> pbeSet = new Set<Id>();
        Set<Id> pbeProductIdSet = new Set<Id>();
    
        Opportunity oppRec = [SELECT Id, ER_BUPicklist__c, Max_Discount__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        
        for (OpportunityLineItem oli : lineItemsToSave) {
            pbeSet.add(oli.PricebookEntryId);
            setOli.add(oli.Id);
        }
        oppRec.Max_Discount__c = maxDiscount;
        update oppRec;
    
    
        for (PricebookEntry pbe : [
            SELECT Id, Product2.Id, Product2.Name, Product2.ER_Solution__r.Name, Product2.ER_Solution__r.ProductCode, Product2.ProductCode
            FROM PricebookEntry
            WHERE Id IN :pbeSet
            AND Pricebook2.Name = :Label.LAB_SF_P2_EKIVITA_PRICEBOOK
        ]) {
            pbeIdMap.put(pbe.Id, pbe.Product2.ProductCode);
        }
        
        for (OpportunityLineItem oli : lineItemsToSave) {
            if (!busSkipValueCheck.contains(oppRec.ER_BUPicklist__c) && !pbeIdMap.containsKey(oli.PricebookEntryId)) {
                /* if (Double.valueOf(oli.ListPrice) < Double.valueOf(oli.ER_Percentage__c)) throw new VisualforceException(errorMsg);
                if (Double.valueOf(oli.ListPrice) < Double.valueOf(oli.UnitPrice)) throw new VisualforceException(errorMsg); */
            }
        }
        
        delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityId AND Id NOT IN :setOli];
    
        upsert lineItemsToSave;
        
        /** Changes made on 09 September 2024 */
    	
        if(additionalDataJson != null) {
            for (PricebookEntry pbe : [
                SELECT Id, Product2.Id, Product2.Name, Product2.ER_Solution__r.Name, Product2.ER_Solution__r.ProductCode, Product2.ProductCode 
                FROM PricebookEntry 
                WHERE Id IN :pbeSet
            ]) {
                pbeProductIdSet.add(pbe.Product2Id);
            }

            List<ProductWrapper> additionalData = (List<ProductWrapper>) JSON.deserialize(additionalDataJson, List<ProductWrapper>.class);

            Set<Id> parentProductsIdSet = new Set<Id>();
            Set<Id> childProductIdsSet = new Set<Id>();
            Map<Id, ProductWrapper> parentProdIdByWrapperMap = new Map<Id, ProductWrapper>();

            // Collect parent product IDs and map the data
            for (ProductWrapper data : additionalData) {
                parentProductsIdSet.add(Id.valueOf(data.Id));
                parentProdIdByWrapperMap.put(Id.valueOf(data.Id), data);
            }

            // Fetch parent products
            Map<Id, Product2> parentProductsByIdMap = new Map<Id, Product2>();
            for (Product2 parentProduct : [
                SELECT Id, Face_Value__c, No_Of_Beneficiaries__c, Load_Per_Year__c, Days_per_Month__c 
                FROM Product2 
                WHERE Id IN :parentProductsIdSet
            ]) {
                parentProductsByIdMap.put(parentProduct.Id, parentProduct);
            }

            // Fetch child products
            Map<Id, Product2> childProductsByIdMap = new Map<Id, Product2>();
            Map<Id, Product2> grandchildProductsByIdMap = new Map<Id, Product2>();

            for (Product2 childProduct : [
                SELECT Id, ER_Solution__c 
                FROM Product2 
                WHERE ER_Solution__c IN :parentProductsIdSet
            ]) {
                if (pbeProductIdSet.contains(childProduct.Id)) {
                    childProductIdsSet.add(childProduct.Id);
                    childProductsByIdMap.put(childProduct.Id, childProduct);
                }
            }

            // Fetch grandchild products
            for (Product2 grandchildProduct : [
                SELECT Id, ER_Solution__c, ER_Solution__r.ER_Solution__c 
                FROM Product2 
                WHERE ER_Solution__r.ER_Solution__c IN :parentProductsIdSet
            ]) {
                if (pbeProductIdSet.contains(grandchildProduct.Id)) {
                    grandchildProductsByIdMap.put(grandchildProduct.Id, grandchildProduct);
                }
            }

            // **New Logic to Handle Grand-Grandchild Products**
            // Fetch grand-grandchild products
            Map<Id, Product2> grandGrandchildProducts = new Map<Id, Product2>();
            for (Product2 grandGrandchildProduct : [
                SELECT Id, ER_Solution__r.ER_Solution__r.ER_Solution__c 
                FROM Product2 
                WHERE ER_Solution__r.ER_Solution__r.ER_Solution__c IN :parentProductsIdSet
            ]) {
                if (pbeProductIdSet.contains(grandGrandchildProduct.Id)) {
                    grandGrandchildProducts.put(grandGrandchildProduct.Id, grandGrandchildProduct);
                }
            }

            // Update OpportunityLineItems
            List<OpportunityLineItem> lineItemsToUpdate = new List<OpportunityLineItem>();

            for (OpportunityLineItem oli : [
                SELECT Id, PricebookEntryId, PricebookEntry.Product2Id, UnitPrice, ListPrice, OpportunityId, Product2.QuantityUnitOfMeasure, Quantity, Product2.Solution_Group__c, Opportunity.ER_Estimated_Number_Of_Beneficiaries__c,
                Product2.ER_Solution__r.ProductCode, Product2.ER_Solution__r.ER_Solution__r.ProductCode
                FROM OpportunityLineItem 
                WHERE OpportunityId = :opportunityId
            ]) {
                OpportunityLineItem updateItem = new OpportunityLineItem(Id = oli.Id);

                // Determine if the product is a child, grandchild, or grand-grandchild
                Product2 product = childProductsByIdMap.get(oli.PricebookEntry.Product2Id) != null
                                ? childProductsByIdMap.get(oli.PricebookEntry.Product2Id)
                                : grandchildProductsByIdMap.get(oli.PricebookEntry.Product2Id) != null
                                ? grandchildProductsByIdMap.get(oli.PricebookEntry.Product2Id)
                                : grandGrandchildProducts.get(oli.PricebookEntry.Product2Id);

                if (product != null) {
                    // Retrieve parent product data based on the hierarchy level
                    ProductWrapper parentProduct = parentProdIdByWrapperMap.get(product.ER_Solution__c);
                    if (parentProduct == null) {
                        parentProduct = parentProdIdByWrapperMap.get(product.ER_Solution__r.ER_Solution__c);
                    }
                    if (parentProduct == null) {
                        parentProduct = parentProdIdByWrapperMap.get(product.ER_Solution__r.ER_Solution__r.ER_Solution__c);
                    }

                    // Update OpportunityLineItem fields if parentProduct is found
                    if (parentProduct != null) {
                        updateItem.ER_Face_Value__c = parentProduct.Face_Value;
                        updateItem.ER_Nb_Beneficiaries__c = parentProduct.No_Of_Beneficiaries;
                        updateItem.ER_Load_Per_Year__c = parentProduct.Load_Per_Year;
                        updateItem.ER_Days_Per_Month__c = parentProduct.Days_per_Month;
                    }
                    if(parentProduct != null && oli.Product2.Solution_Group__c == 'Savings' && (oli.Product2.QuantityUnitOfMeasure == 'Per Unit')){
                        updateItem.UnitPrice = oli.UnitPrice;
                        updateItem.Quantity = parentProduct.No_Of_Beneficiaries;
                    }else if(parentProduct == null && oli.Product2.Solution_Group__c == 'Savings' && (oli.Product2.QuantityUnitOfMeasure == 'Per Unit')){
                        updateItem.UnitPrice = oli.UnitPrice;
                        updateItem.Quantity = oli.Opportunity.ER_Estimated_Number_Of_Beneficiaries__c;
                    }   
                    lineItemsToUpdate.add(updateItem);
                }
            }

            if (!lineItemsToUpdate.isEmpty()) {
                update lineItemsToUpdate;
            }
        }

        
        /** End */
    
        Opportunity currentOpportunity = new Opportunity();
        currentOpportunity.Id = opportunityId;
        currentOpportunity.ER_NeedApproval__c = false;
        currentOpportunity.ER_Approved__c = false;
    
        update currentOpportunity;
    
        return null;
    }


    /**
    * @author Oussama LASFAR
    * @date 27/12/2018 (dd/mm/yyyy)
    * @description getOpportunityProduct : get Products linked to the current Opportunity
    */
    @RemoteAction
    global static Map<String, OpportunityLineItem> getOpportunityProduct(String opportunityId) {

        Map<String, OpportunityLineItem> mapProductOli = new Map<String, OpportunityLineItem>();
        List<OpportunityLineItem> oliList = [
                select id, OpportunityId, Product2Id, Product2.ER_Solution__c, ER_Percentage__c, UnitPrice, ListPrice, Quantity, ER_Minimum_Fee__c, Discount, ER_Line_Type__c, Product2.ER_Solution__r.ER_Solution__c, Product2.ER_Solution__r.ProductCode, Product2.ProductCode, ER_Duration__c, ER_Price_End_Date__c, ER_Price_Start_Date__c, ER_Edenred_Margin_TUR__c, ER_User_Margin__c, ER_Free_To_Set_Margin__c, ER_MPV__c, ER_Cumulative_with_Promotions__c
                from OpportunityLineItem
                where opportunityid = :opportunityId
        ];

        System.debug('###oliList : ' + oliList);

        for(OpportunityLineItem oli : oliList) {
            mapProductOli.put(oli.Product2Id, oli);
        }

        return mapProductOli;
    }

    /**
    * @author Noor
    * @date 02/08/2022 (dd/mm/yyyy)
    * @description getDefaultProductSelection : get default selection based on promo code
    */
    @RemoteAction
    global static Map<String, PricebookEntry> getDefaultProductSelection(String opportunityId) {

        Map<String, PricebookEntry> mapProduct = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : [
                SELECT Id, Product2.ER_Solution2__c
                FROM PricebookEntry
                WHERE ER_Promo_Code2__c IN (SELECT ER_Promo_Code2__c FROM Opportunity WHERE Id = :opportunityId) AND Product2.IsActive = TRUE
        ])
            mapProduct.put(pbe.Product2.ER_Solution2__c, pbe);

        return mapProduct;
    }
    
    /**
	* @author Pranjal Tiwari
	* @date 03/09/2024 (dd/mm/yyyy)
	* @description fetchDefaultValuesForVolume : get field default values for calculation of Issued Volume
	* @param solutionMap
	* @param opportunityId
	*/
    @RemoteAction
        public static Map<String, ProductWrapper> fetchDefaultValuesForVolume(List<String> productList, String opportunityId) {
    Map<String, ProductWrapper> productIdWithWrapperMap = new Map<String, ProductWrapper>();
    String additionalProductLabel = System.Label.ADDITIONAL_SERVICES_LABEL;
    Integer noOfBeneficiaries = 0;
    
    if (productList != null && opportunityId != '') {
        List<Opportunity> oppList = [SELECT Id, ER_Estimated_Number_Of_Beneficiaries__c FROM Opportunity WHERE Id = :opportunityId];
        if (!oppList.isEmpty() && oppList[0].ER_Estimated_Number_Of_Beneficiaries__c != null) {
            noOfBeneficiaries = Integer.valueOf(oppList[0].ER_Estimated_Number_Of_Beneficiaries__c);
        }
        
        // Fetch the Opportunity Line Items
        List<OpportunityLineItem> lineItems = [
            SELECT Id, PricebookEntry.Product2.ER_Solution__c, PricebookEntry.Product2.ER_Solution__r.ER_Solution__c,
                   PricebookEntry.Product2.ER_Solution__r.ER_Solution__r.ER_Solution__c, PricebookEntry.Product2.Name,
                   PricebookEntry.Product2Id, ER_Face_Value__c, ER_Nb_Beneficiaries__c, ER_Load_Per_Year__c, ER_Days_Per_Month__c, ER_Estimated_Value__c,
                   PricebookEntry.Product2.ER_Solution__r.ER_Solution__r.Name, PricebookEntry.Product2.ER_Solution__r.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];
        
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> matchedProductsIdSet = new Set<Id>();
        
        for (String prodId : productList) {
            productIdSet.add(Id.valueOf(prodId));
        }
        
        // Loop through OpportunityLineItems and handle hierarchy up to Grand-Grandchild
        for (OpportunityLineItem lineItem : lineItems) {
            Id product2Id = lineItem.PricebookEntry.Product2Id;
            Id childId = lineItem.PricebookEntry.Product2.ER_Solution__c;
            Id grandchildId = lineItem.PricebookEntry.Product2.ER_Solution__r.ER_Solution__c;
            Id grandGrandchildId = lineItem.PricebookEntry.Product2.ER_Solution__r.ER_Solution__r != null
                                   ? lineItem.PricebookEntry.Product2.ER_Solution__r.ER_Solution__r.ER_Solution__c
                                   : null;

            String childName = lineItem.PricebookEntry.Product2.ER_Solution__r.Name;
            String grandchildName = lineItem.PricebookEntry.Product2.ER_Solution__r.ER_Solution__r != null
                                    ? lineItem.PricebookEntry.Product2.ER_Solution__r.ER_Solution__r.Name
                                    : null;

            // Handle product hierarchy and match product from productList
            if ((productIdSet.contains(childId) || productIdSet.contains(grandchildId) || (grandGrandchildId != null && productIdSet.contains(grandGrandchildId))) &&
                (childName != additionalProductLabel && (grandchildName == null || grandchildName != additionalProductLabel))) {

                matchedProductsIdSet.add(childId);
                matchedProductsIdSet.add(grandchildId);
                matchedProductsIdSet.add(grandGrandchildId);
                
                ProductWrapper productWrapper = new ProductWrapper();
                productWrapper.Id = product2Id;

                if (productIdSet.contains(childId)) {
                    productWrapper.Id = childId;
                } else if (productIdSet.contains(grandchildId)) {
                    productWrapper.Id = grandchildId;
                } else if (grandGrandchildId != null && productIdSet.contains(grandGrandchildId)) {
                    productWrapper.Id = grandGrandchildId;
                }

                // Set product name based on hierarchy
                if (productIdSet.contains(childId)) {
                    productWrapper.Name = childName;
                } else if (productIdSet.contains(grandchildId)) {
                    productWrapper.Name = grandchildName;
                }

                productWrapper.Face_Value = lineItem.ER_Face_Value__c;
                productWrapper.No_Of_Beneficiaries = lineItem.ER_Nb_Beneficiaries__c;
                productWrapper.Load_Per_Year = lineItem.ER_Load_Per_Year__c;
                productWrapper.Days_per_Month = lineItem.ER_Days_Per_Month__c;
                productWrapper.Issued_Volume = lineItem.ER_Estimated_Value__c;

                productIdWithWrapperMap.put(productWrapper.Id, productWrapper);
            }
        }
        
        // Handle remaining products not matched by OpportunityLineItems
        List<Product2> products = [
            SELECT Id, Name, Face_Value__c, No_Of_Beneficiaries__c, Load_Per_Year__c, Issued_Volume__c, Days_per_Month__c 
            FROM Product2 
            WHERE Id IN :productList AND Id NOT IN :matchedProductsIdSet AND Name != :additionalProductLabel
        ];

        for (Product2 product : products) {
            if (!productIdWithWrapperMap.containsKey(product.Name)) {
                ProductWrapper productWrapper = new ProductWrapper();
                productWrapper.Id = product.Id;
                productWrapper.Name = product.Name;
                productWrapper.Face_Value = product.Face_Value__c;
                productWrapper.No_Of_Beneficiaries = noOfBeneficiaries;
                productWrapper.Load_Per_Year = product.Load_Per_Year__c;
                productWrapper.Days_per_Month = product.Days_per_Month__c;
                productWrapper.Issued_Volume = product.Face_Value__c * noOfBeneficiaries * product.Load_Per_Year__c * product.Days_per_Month__c;

                productIdWithWrapperMap.put(product.Id, productWrapper);
            }
        }
    }

    return productIdWithWrapperMap;
}

        public class ProductWrapper {
            public String Id { get; set; }
            public String Name { get; set; }
            public Decimal Face_Value { get; set; }
            public Decimal No_Of_Beneficiaries { get; set; }
            public Decimal Load_Per_Year { get; set; }
            public Decimal Issued_Volume { get; set; }
            public Decimal Days_per_Month { get; set; }
    
    }
    
    /**
	* @author Pranjal Tiwari
	* @date 05/9/2024 (dd/mm/yyyy)
	* @description fetchBUFromMetadata : fetch all the BU available that needs estimation component to be rendered.
	*/
    @RemoteAction
        public static Set<String> fetchBUFromMetadata() {
            String errorMessage;
            Set<String> renderIssuedVolumeBUSet = new Set<String>();
            List<Global_Settings__mdt> renderEstimationForBUSettings = [SELECT MasterLabel, Business_Unit__c, Active__c FROM Global_Settings__mdt WHERE MasterLabel LIKE '%OPPORTUNITY_PRODUCT_ISSUED_VOLUME%' AND Active__c = true];
            for(Global_Settings__mdt gs : renderEstimationForBUSettings){
                renderIssuedVolumeBUSet.add(gs.Business_Unit__c);
            }
            return renderIssuedVolumeBUSet;
        }




    public class VisualforceException extends Exception {
    }
}