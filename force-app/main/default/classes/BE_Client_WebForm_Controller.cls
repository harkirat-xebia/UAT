/**
 * Creator : Killian Degryse (ABSI)
 * Date : 2018/01/31
 * Controller for Webform Client
 */
public inherited sharing class BE_Client_WebForm_Controller {
    //Added for PBI-697 : Offer light
    public static Map<String, Object> findOpportunity(String key, String product){
        Map<String, Object> result = new Map<String, Object>();
        String searchKey = '%'+key+'%';
        String primaryContactId;
        String invoicingContactId;
        List<Opportunity> opportunities = [SELECT Id, AccountId, BE_Crypto_Key__c, Pricebook2Id,
                                                ER_Estimated_Number_Of_Beneficiaries__c, ER_Face_Value__c,
                                                  ER_Nb_of_Employees__c, BE_Accepted_general_conditions__c,
                                                  BE_Date_Time_accepted_general_conditions__c,Primary_Contact__c, Invoicing_Contact__c,
                                                  BE_General_Condition__c, PriceBook2.Name, StageName, ER_Promo_Code2__r.ER_Description__c, ER_Promo_Code2__r.Description_DE__c, ER_Promo_Code2__r.Description_EN__c, ER_Promo_Code2__r.Description_NL__c,
                                                  CloseDate, CampaignId, ER_Promo_Code2__c, ER_Promo_Code2__r.ER_Promo_Code__c, ER_Promo_Code2__r.Name // Add PromoCode Name for Light Offers (SFR-515)
                                           FROM Opportunity
                                           WHERE BE_Webform_Link__c LIKE :searchKey
                                           AND RecordType.Name LIKE :Label.BE_Client_Opportunity
                                           AND Product_of_Interest__r.ProductCode = :product];

        Opportunity opportunity;
        if(opportunities.size() == 1){
            opportunity = opportunities[0];
            primaryContactId = opportunity.Primary_Contact__c;
            invoicingContactId = opportunity.Invoicing_Contact__c;
            List<String> keyDecrypted = Crypto.decryptWithManagedIV('AES256', EncodingUtil.base64Decode(opportunity.BE_Crypto_Key__c), EncodingUtil.base64Decode(key)).toString().split('-');
            Id opportunityId = keyDecrypted[0];
            List<String> listDate = keyDecrypted[1].split('/');
            Date limitDate = Date.newInstance(Integer.valueOf(listDate[2]), Integer.valueOf(listDate[1]), Integer.valueOf(listDate[0]));
            if(limitDate < System.today())
                throw new AuraHandledException('Label to define (date limit)');
        }
        else
            throw new AuraHandledException('Label to define (404)');

        Account account = [SELECT Id, Name, ER_Legal_Form__c, BillingStreet, BillingPostalCode,
                                  BillingCity, BillingCountry, ER_Enterprise_Number__c, Phone,
                                  ER_Not_subject_to_VAT__c, ER_VAT_Number__c, NumberOfEmployees, ER_Registration_Number__c,
                                  ER_Legal_Name__c, BE_Client_Contract_TRE__c,
                                  BE_Client_Contract_TCE__c, BE_Client_Contract_ECE__c
                           FROM Account
                           WHERE Id = :opportunity.AccountId];

        Contact contact;
        if([SELECT Id, Email FROM Contact WHERE AccountId = :account.Id AND (BE_Operational_Role__c = :Label.Operational_Role_Main_Contact_API OR Id =:primaryContactId)].size() > 0)
            contact = [SELECT Id, Email FROM Contact WHERE AccountId = :account.Id AND (BE_Operational_Role__c = :Label.Operational_Role_Main_Contact_API OR Id =:primaryContactId)][0];
       /*  else if([SELECT ContactId FROM OpportunityContactRole WHERE Role = :Label.BE_Offer_Contact AND OpportunityId = :opportunity.Id].size() > 0){
            Id contactId = [SELECT ContactId FROM OpportunityContactRole WHERE Role = :Label.BE_Offer_Contact AND OpportunityId = :opportunity.Id][0].ContactId;
            contact = [SELECT Id, Email FROM Contact WHERE Id = :contactId];
        } */
        else if([SELECT Id, Email FROM Contact WHERE AccountId = :account.Id].size() > 0)
            contact = [SELECT Id, Email FROM Contact WHERE AccountId = :account.Id][0];
        else
            throw new AuraHandledException('Label to define No Contact linked to account');

        /* ER_Financial_Center__c financialCenter = [SELECT Id, Name, ER_Bank_Account__c, ER_City__c,
                                                         ER_Contact__c, ER_Country__c,
                                                         ER_Payment_Site__c, ER_Street__c, ER_Zip_Code__c
                                                  FROM ER_Financial_Center__c
                                                  WHERE ER_Account_Name__c = :account.Id];
        ER_Delivery_Site__c deliverySite;
        ER_Distribution_Point__c distributionPoint;
        if([SELECT Id FROM ER_Delivery_Site__c WHERE ER_Account_Name__c = :account.Id].size() > 0){
            deliverySite = [SELECT Id, ER_Account_Name__c, ER_Financial_Center__c, Name,
                                   ER_Delivery_Contact__c, ER_Street__c, ER_Zip_Code__c,
                                   ER_City__c, ER_Country__c
                            FROM ER_Delivery_Site__c
                            WHERE ER_Account_Name__c = :account.Id][0];
            distributionPoint = [SELECT Id, Name, ER_Street__c, ER_Zip_Code__c,
                                        ER_City__c, ER_Country__c, ER_Delivery_Site__c
                                 FROM ER_Distribution_Point__c
                                 WHERE ER_Delivery_Site__c = :deliverySite.Id][0];
        } */
        result.put('account', account);
        result.put('opportunity', opportunity);
        result.put('contact', contact);
        /* result.put('financialCenter', financialCenter);
        result.put('deliverySite', deliverySite);
        result.put('distributionPoint', distributionPoint); */
        System.debug('result: ' + result);
        return result;
    }

    public static Map<String, List<Map<String, String>>> getOpportunityProduct(Id opportunityId, String language){
        Map<String, String> otherTranslations = new Map<String, String>();
        for(BE_Miscellaneous_Translation__mdt miscTranslation : [SELECT Label, BE_Label_Translation__c
                                                                 FROM BE_Miscellaneous_Translation__mdt
                                                                 WHERE BE_Language__c = :language]){
            otherTranslations.put(miscTranslation.Label, miscTranslation.BE_Label_Translation__c);
        }

        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();
        List<Map<String, String>> oppoProdMapListed;
        Map<String, String> oppoProdMapped;
        String name;
        String solutionName;
        String parentName;
        String grandParentName;
        String type;
        String promoDescription = '';
        Boolean hasDiscount = false;
        for(OpportunityLineItem oppoProd : [SELECT Id, Product2.ProductCode, Product2Id, ER_Percentage__c, Product2.Name, Product2.ER_Solution2__r.Name, Product2.ER_Solution__r.Name, Product2.ER_Solution__r.ER_Solution__r.Name,
                                                   UnitPrice, Product2.ER_Type__c, Product2.BE_Minimum_Amount__c, Product2.BE_Maximum_Amount__c, Opportunity.ER_Promo_Code2__c, Opportunity.ER_Promo_Code2__r.ER_Description__c, Opportunity.ER_Promo_Code2__r.Description_NL__c, Opportunity.ER_Promo_Code2__r.Description_EN__c
                                            FROM OpportunityLineItem
                                            WHERE OpportunityId = :opportunityId AND ProductCode != :Label.BE_Client_Service_Promocode_P4_Product_Excluded]){
            
            if(language =='fr_BE'){
                promoDescription = oppoProd.Opportunity.ER_Promo_Code2__r.ER_Description__c;
            }else if(language =='nl_BE'){
                promoDescription = oppoProd.Opportunity.ER_Promo_Code2__r.Description_NL__c;
            }else if(language =='en_US'){
                promoDescription = oppoProd.Opportunity.ER_Promo_Code2__r.Description_EN__c;
            }

            Map<String, String> promoDesMap = new Map<String, String>();
            promoDesMap.put('promoDescription', promoDescription);
            List<Map<String, String>> promoDesList = new List<Map<String, String>>();
            promoDesList.add(promoDesMap);
            result.put('promoDescription', promoDesList);
            
            name = oppoProd.Product2.Name;
            solutionName = oppoProd.Product2.ER_Solution2__r.Name;
            parentName = oppoProd.Product2.ER_Solution__r.Name;
            grandParentName = oppoProd.Product2.ER_Solution__r.ER_Solution__r.Name;                                    
            type = oppoProd.Product2.ER_Type__c;
            if(parentName.contains('Delivery') && solutionName == Label.ADDITIONAL_SERVICES_LABEL){
                if(type == 'Range'){
                    oppoProdMapListed = result.get('Delivery');
                    if(oppoProdMapListed == null)
                        oppoProdMapListed = new List<Map<String, String>>();
                    oppoProdMapped = fillUpOppoProdMap(oppoProd, otherTranslations);
                    oppoProdMapListed.add(oppoProdMapped);
                    result.put('Delivery', oppoProdMapListed);
                }
            }
            else if(!(solutionName == Label.ADDITIONAL_SERVICES_LABEL)) {
                // Check if ER_Promo_Code2__c is null or not
                if (type == 'Range') {
                    // ER_Promo_Code2__c is null, use type == 'Range'
                    oppoProdMapListed = result.get('Rate');
                    if(oppoProdMapListed == null)
                        oppoProdMapListed = new List<Map<String, String>>();
                    oppoProdMapped = fillUpOppoProdMap(oppoProd, otherTranslations);
                    oppoProdMapListed.add(oppoProdMapped);
                    result.put('Rate', oppoProdMapListed);
                }
            }
            else if (type == 'Service' && solutionName == Label.ADDITIONAL_SERVICES_LABEL) {
                    // Add Service products when Promo Code is null
                    oppoProdMapListed = result.get('Others');
                    if (oppoProdMapListed == null)
                        oppoProdMapListed = new List<Map<String, String>>();
                    oppoProdMapped = fillUpOppoProdMap(oppoProd, otherTranslations);
                    oppoProdMapListed.add(oppoProdMapped);
                    result.put('Others', oppoProdMapListed);
            }
        }
        return result;
    }
    private static Map<String, String> fillUpOppoProdMap(OpportunityLineItem oppoProd, Map<String, String> otherTranslations){
        Map<String, String> result = new Map<String, String>();

        result.put('Percentage', String.valueOf(oppoProd.ER_Percentage__c));
        String nameLabel = otherTranslations.get(oppoProd.Product2.Name) != null ? otherTranslations.get(oppoProd.Product2.Name)
                                                                                 : oppoProd.Product2.Name;
        String parentNameLabel;
        String grandParentNameLabel;
        String discountedProdParent;
        if(oppoProd.Product2.ER_Solution__c != null){
        parentNameLabel = otherTranslations.get(oppoProd.Product2.ER_Solution__r.Name) != null ? otherTranslations.get(oppoProd.Product2.ER_Solution__r.Name)
                                                                    : oppoProd.Product2.ER_Solution__r.Name;
        grandParentNameLabel = otherTranslations.get(oppoProd.Product2.ER_Solution2__r.Name) != null ? otherTranslations.get(oppoProd.Product2.ER_Solution2__r.Name)
                                                                    : oppoProd.Product2.ER_Solution2__r.Name;
        }
        discountedProdParent = otherTranslations.get(oppoProd.Product2.ER_Solution__r.ER_Solution__r.Name) != null ? otherTranslations.get(oppoProd.Product2.ER_Solution__r.ER_Solution__r.Name)
                                : oppoProd.Product2.ER_Solution__r.ER_Solution__r.Name;
                    
        result.put('Name', nameLabel);
        result.put('ParentName', parentNameLabel);
        
        result.put('SolutionName', grandParentNameLabel);
        //result.put('TotalPrice', String.valueOf(oppoProd.BE_Total_Price__c));
        result.put('Price', String.valueOf(oppoProd.UnitPrice));
        if(String.valueOf(oppoProd.Product2.BE_Minimum_Amount__c) != null){
            result.put('Min', String.valueOf(oppoProd.Product2.BE_Minimum_Amount__c));
        }
        if(String.valueOf(oppoProd.Product2.BE_Maximum_Amount__c) != null){
            result.put('Max', String.valueOf(oppoProd.Product2.BE_Maximum_Amount__c));
        }  
        //result.put('CardLoadingCost', String.valueOf(oppoProd.BE_Card_loading_cost__c));

        return result;
    }
    
    /**
    * This method create a structure to send the information stocked in the PriceBook
    * The first Map separate the billable service by type
    * The List contain all the billable services of these type
    * The second Map separate the fields of the billable service
    * It's needed to authorize the lightning component to applicate a format on the number in the name
    */
    public static Map<String, List<Map<String, String>>> getBillableServices(String promoCode, String product, String language){
        String productCode = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :product].Name__c;
        Map<String, String> otherTranslations = new Map<String, String>();
        for(BE_Miscellaneous_Translation__mdt miscTranslation : [SELECT Label, BE_Label_Translation__c
                                                                 FROM BE_Miscellaneous_Translation__mdt
                                                                 WHERE BE_Language__c = :language]){
            otherTranslations.put(miscTranslation.Label, miscTranslation.BE_Label_Translation__c);
        }

        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();
        List<Map<String, String>> billableServicesList = new List<Map<String, String>>();
        Map<String, String> billableServiceFields = new Map<String, String>();
        //Set<Id> setOfPriceBookId = new Set<Id>();
        Map<String, String> priceBookAndPromoCodeId;
        Integer maxAmount = product == Label.ETR_Product ? 99999 : 25000;
        String nameLabel;
        String parentNameLabel;
        String grandParentNameLabel;

        try{
            priceBookAndPromoCodeId = getPriceBookId(product, promoCode);
        }
        catch(Exception e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException('Error_Message_Promo_Code');
        }
        Boolean hasDiscount = false;
        String promoDescription = '';
        for(ER_Promo_Code__c discount : [Select Id, ER_Promo_Code__c, ER_Description__c, Description_NL__c, Description_EN__c FROM ER_Promo_Code__c WHERE ER_Promo_Code__c =:promoCode]){
            if(language =='fr_BE'){
                promoDescription = discount.ER_Description__c;
            }else if(language =='nl_BE'){
                promoDescription = discount.Description_NL__c;
            }else if(language =='en_US'){
                promoDescription = discount.Description_EN__c;
            }
        }
        for(PriceBookEntry pbe : [SELECT Id, Product2Id, ER_Percentage__c, UnitPrice, Product2.Name,  Product2.ProductCode, Product2.ER_Solution2__r.Name,
                                  ER_Max__c, ER_Min__c, Product2.ER_Type__c, Product2.ER_Solution__r.ER_Solution__r.ER_Solution__r.ProductCode, Product2.Days_per_Month__c ,Product2.Load_Per_Year__c,
                                  Product2.ER_Solution__r.Name, Product2.ER_Solution__r.ER_Solution__r.Name, Product2.ER_Solution__r.ER_Solution__r.ProductCode, ER_Promo_Code2__r.ER_Promo_Code__c, ER_Promo_Code2__r.ER_Description__c, 
                                  ER_Promo_Code2__r.Description_DE__c, ER_Promo_Code2__r.Description_EN__c, ER_Promo_Code2__r.Description_NL__c
                                  FROM PriceBookEntry WHERE PriceBook2Id = :priceBookAndPromoCodeId.get('PriceBookId') 
                                  AND ProductCode != :Label.BE_Client_Service_Promocode_P4_Product_Excluded AND Product2.IsActive = true ORDER BY Product2.ER_Line_Order__c ASC]){
            //setOfPriceBookId.add(pbe.Product2Id);
            billableServiceFields = new Map<String, String>();
            billableServiceFields.put('Percentage', String.valueOf(pbe.ER_Percentage__c));
            billableServiceFields.put('Price', String.valueOf(pbe.UnitPrice));
            billableServiceFields.put('SolutionName', String.valueOf(pbe.Product2.ER_Solution2__r.Name));
            billableServiceFields.put('ProductCode', String.valueOf(pbe.Product2.ProductCode));
            billableServiceFields.put('ProductType', String.valueOf(pbe.Product2.ER_Type__c));
            nameLabel = otherTranslations.get(pbe.Product2.Name) != null ? otherTranslations.get(pbe.Product2.Name)
                                                                         : pbe.Product2.Name;

            if(pbe.Product2.ER_Solution__c != null){
                parentNameLabel = otherTranslations.get(pbe.Product2.ER_Solution__r.Name) != null ? otherTranslations.get(pbe.Product2.ER_Solution__r.Name)
                                                                         : pbe.Product2.ER_Solution__r.Name;
                
                billableServiceFields.put('ParentSolution', String.valueOf(parentNameLabel));
                grandParentNameLabel = otherTranslations.get(pbe.Product2.ER_Solution__r.ER_Solution__r.Name) != null ? otherTranslations.get(pbe.Product2.ER_Solution__r.ER_Solution__r.Name)
                                                                         : pbe.Product2.ER_Solution__r.ER_Solution__r.Name;
                billableServiceFields.put('GrandParentSolutionName', String.valueOf(grandParentNameLabel));
                if(pbe.Product2.ER_Solution__r.ER_Solution__c != null){
                    billableServiceFields.put('GrandParentSolution', String.valueOf(pbe.Product2.ER_Solution__r.ER_Solution__r.Name));
                    billableServiceFields.put('GrandProductCode', String.valueOf(pbe.Product2.ER_Solution__r.ER_Solution__r.ProductCode));
                    if(pbe.Product2.ER_Solution__r.ER_Solution__r.ER_Solution__c != null){
                        billableServiceFields.put('GrandGrandProductCode', String.valueOf(pbe.Product2.ER_Solution__r.ER_Solution__r.ER_Solution__r.ProductCode));
                    }
                }
            }
            billableServiceFields.put('Name', nameLabel);
            billableServiceFields.put('Min', String.valueOf(pbe.ER_Min__c));
            billableServiceFields.put('Max', String.valueOf(pbe.ER_Max__c));
            billableServiceFields.put('PromoCodeValue', String.valueOf(pbe.ER_Promo_Code2__r.ER_Promo_Code__c));
            
            billableServicesList.add(billableServiceFields);
        }

        List<Map<String, String>> listOfMap;
        String name;
        for(Map<String, String> mapOfProd : billableServicesList){
            name = mapOfProd.get('Name');
            if(mapOfProd.containsKey('GrandParentSolution')){
                if(mapOfProd.get('SolutionName') == Label.ADDITIONAL_SERVICES_LABEL){
                    if(mapOfProd.get('ProductType') == 'Range'){
                        listOfMap = result.get('Delivery');
                        if(listOfMap == null)
                            listOfMap = new List<Map<String, String>>();
                        listOfMap.add(mapOfProd);
                        result.put('Delivery', listOfMap);
                    }
                }
                if(mapOfProd.get('GrandProductCode') == productCode){
                     if(mapOfProd.get('ProductType') == 'Range'){
                         listOfMap = result.get('Rate');
                        if(listOfMap == null)
                            listOfMap = new List<Map<String, String>>();
                        listOfMap.add(mapOfProd);
                        result.put('Rate', listOfMap);
                     }
                }
            }
            if(mapOfProd.containsKey('SolutionName')){
                if(mapOfProd.get('SolutionName') == Label.ADDITIONAL_SERVICES_LABEL && !(mapOfProd.get('Name').contains('livraison')) && !(mapOfProd.get('Name').contains('bezorgkosten')) && !(mapOfProd.get('Name').contains('Delivery'))){
                    if(mapOfProd.get('ProductType') == 'Service'){
                        listOfMap = result.get('Others');
                        if(listOfMap == null)
                            listOfMap = new List<Map<String, String>>();
                        listOfMap.add(mapOfProd);
                        result.put('Others', listOfMap);
                    }
                }
            }
        }

        Map<String, String> priceBookMap = new Map<String, String>();
        priceBookMap.put('priceBookId', priceBookAndPromoCodeId.get('PriceBookId'));
        priceBookMap.put('promoDescription', promoDescription);
        List<Map<String, String>> priceBookList = new List<Map<String, String>>();
        priceBookList.add(priceBookMap);
        result.put('priceBookId', priceBookList);

        Map<String, String> promoCodeMap = new Map<String, String>();
        promoCodeMap.put('PromoCodeId', priceBookAndPromoCodeId.get('PromoCodeId'));
        List<Map<String, String>> promoCodeList = new List<Map<String, String>>();
        promoCodeList.add(promoCodeMap);

        Map<String, String> promoDesMap = new Map<String, String>();
        promoDesMap.put('promoDescription', promoDescription);
        List<Map<String, String>> promoDesList = new List<Map<String, String>>();
        promoDesList.add(promoDesMap);
        result.put('promoDescription', promoDesList);

        result.put('PromoCodeId', promoCodeList);
        return result;
    }
    public static Map<String, String> getInfosFromBelfirstCtrl(String enterpriseNumber, String language, Boolean offerLight, String product){
        Map<String, String> result;

        Id accountClientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();
        List<Account> accounts = [SELECT Id, Name, ER_Legal_Form__c, BillingStreet, BillingPostalCode,
                                         BillingCity, BillingCountry, ER_Enterprise_Number__c, Phone,
                                         ER_VAT_Number__c, BE_Client_Contract_TRE__c, BE_Client_Contract_TCE__c,
                                         BE_Client_Contract_ECE__c, Fax, ER_Legal_Name__c, ER_Not_subject_to_VAT__c
                                  FROM Account 
                                  WHERE ER_Enterprise_Number__c = :enterpriseNumber AND RecordTypeId = :accountClientRecordTypeId];

        if(accounts.size() > 0){
            Account account = accounts[0];
            //List<BE_Error_Log__c> errorLogs = [SELECT Id FROM BE_Error_Log__c WHERE BE_Account__c = :account.Id];
            if(account.BE_Client_Contract_TRE__c || account.BE_Client_Contract_TCE__c || account.BE_Client_Contract_ECE__c){
                if(offerLight && !((Label.ETR_Product.equals(product) && account.BE_Client_Contract_TRE__c)
                                 ||(Label.TCE_Product.equals(product) && account.BE_Client_Contract_TCE__c)
                                 ||(Label.ECE_Product.equals(product) && account.BE_Client_Contract_ECE__c))){
                    /*if(errorLogs.size() == 0)*/
                        return setMapFromAccount(account);
                    //throw new AuraHandledException('Account in error'); //Lightning check this message to show the "blocked" page
                }
                if(!offerLight)
                    throw new AuraHandledException('You are already customer'); //Lightning check this message to show the "blocked" page
                else{
                    return setMapFromAccount(account);
                }
            }
        }

        try{
            result = BE_WebForm_Controller_Helper.getInfosFromBelfirstCtrl('BE'+enterpriseNumber, 'BVDID',  language);
        }
        catch(WSBE01_BelfirstException e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }
        return result;
    }

    private static Map<String, String> setMapFromAccount(Account account){
        Map<String, String> result = new Map<String, String>();

        result.put('NAME', account.ER_Legal_Name__c);
        result.put('TYPE', account.ER_Legal_Form__c);
        result.put('ADDRESS', account.BillingStreet);
        result.put('POSTCODE', account.BillingPostalCode);
        result.put('TOWN', account.BillingCity);
        result.put('COUNTRY', account.BillingCountry);
        result.put('BVDID', account.ER_VAT_Number__c);
        result.put('COMPANY_NUMBER', account.ER_Enterprise_Number__c);
        result.put('PHONE', account.Phone);
        result.put('FAX', account.Fax);
        result.put('COMMERCIALNAME', account.Name);
        result.put('SUBJECTTOVAT', String.valueOf(account.ER_Not_subject_to_VAT__c));

        /*result.put('RC', '');
        result.put('LANGEMPL', '');*/

        return result;
    }

    public static Lead saveP1(Decimal numberOfBeneficiaries, Decimal faceValue, String typeOfPosition, String email, String product, String sourceId, String pageLanguage){
        String productCode = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :product].Name__c;
        String productId = [Select Id, ProductCode FROM Product2 WHERE ProductCode =:productCode limit 1].Id;
        Id clientRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Label.BE_Client_Lead).getRecordTypeId();
        Lead lead = new Lead(Salutation = 'Mr.', FirstName = 'Webform Lead - ', LastName = String.valueOfGmt(System.now().addHours(1)), ER_Number_Of_Beneficiaries__c = numberOfBeneficiaries,
                             ER_Face_Value__c = faceValue, LeadSource = 'Websales', ER_Lead_sub_source__c = 'Econtratonline', Business_Role__c = typeOfPosition, Email = email, ER_Solution__c = product,
                             ER_Lead_Type__c = Label.Client, RecordTypeId = clientRecordTypeId, ERBE_Initial_Product_Of_Interest__c = productId);
        try{
            if(String.isNotBlank(pageLanguage) && (pageLanguage == 'fr_BE' || pageLanguage == 'nl_BE' || pageLanguage == 'en_US')){
                lead.ER_Language__c = pageLanguage.substring(0, 2).toUpperCase();
            }
            insert lead;
            // PBI-634: Source/Channel in the URL
            if(String.isNotBlank(sourceId)){
                List<Campaign> lstCamp = [SELECT ID, ER_Source_ID__c FROM Campaign WHERE ER_Source_ID__c = :sourceId];
                if(lstCamp.size() > 0){
                    Campaign camp = lstCamp.get(0);
                    CampaignMember cm = New CampaignMember(CampaignId = camp.Id, LeadId = lead.Id );
                    insert cm;
                }
            }
        }
        catch(DmlException e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }

        return lead;
    }

    public static Lead updateP1(Decimal numberOfBeneficiaries, Decimal faceValue, String typeOfPosition, String email, String product, Lead lead){
        lead.ER_Number_Of_Beneficiaries__c = numberOfBeneficiaries;
        lead.ER_Face_Value__c = faceValue;
        lead.Business_Role__c = typeOfPosition;
        lead.Email = email;
        lead.ER_Solution__c = product;

        try{
            update lead;
        }
        catch(DmlException e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }

        return lead;
    }
 
    public static Map<String, Object> leadConversionP2(String vatNumber, Boolean subjectToVat, String phone, String name, String legalForm,
                                                       String enterpriseNumber, String billingAddress, String billingPostalCode,
                                                       String billingCity, String billingCountry, String product, Lead lead,
                                                       Decimal faceValue, Decimal numberOfBeneficiaries, String legalName, String sourceId, String pageLanguage){
        String productId, businessUnit;
                                                           Decimal sizeLimit = 0;
                                                        billingCity = BE_WebForm_Controller_Helper.getCorrectCity(billingCountry, billingPostalCode, billingCity);
        String productAcr = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :product].Name__c;
        Map<String, Object> result = new Map<String, Object>();
        List<Webform_Client_Settings__mdt> clientSetting = [SELECT DeveloperName, Id, Value__c FROM Webform_Client_Settings__mdt where DeveloperName='SizeLimit'];
                                                           if(!clientSetting.isEmpty()){
                                                               sizeLimit = clientSetting[0].Value__c;
                                                           }                                                   
        String productCode = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :product].Name__c;
        List<Product2> prodList = [Select Id, ProductCode, ER_BUPicklist__c FROM Product2 WHERE ProductCode =:productCode limit 1];
        if(!prodList.isEmpty()){
            productId = prodList[0].Id;
            businessUnit = prodList[0].ER_BUPicklist__c;
        }
        Id accountClientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();
                                                        
        Id opportunityClientRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();
        lead.Company = name.toUpperCase();                                  //Added upperCase for PBI-603 by Killian Degryse
        lead.ER_VAT_Number__c = vatNumber; 
        lead.ER_Legal_Form__c = legalForm;
        lead.Phone = phone;
        lead.Street = billingAddress;
        lead.PostalCode = billingPostalCode;
        lead.City = billingCity;
        lead.Country = billingCountry;
        lead.ER_Legal_Name__c = legalName;
        lead.NumberOfEmployees = Integer.valueOf(numberOfBeneficiaries); 
        lead.ER_Registration_Number__c = enterpriseNumber;   
        lead.ERBE_Initial_Product_Of_Interest__c = productId; 
        lead.ER_BUPicklist__c = businessUnit;                                               
        if(billingCountry == 'BELGIUM'){
             lead.ER_Country_Code__c = 'BE';
             lead.ER_Legal_Country_Code__c = 'BE';                                             
        }else if(billingCountry == 'LUXEMBOURG'){
             lead.ER_Country_Code__c = 'LU';  
             lead.ER_Legal_Country_Code__c = 'LU';                                               
        }                                                   
        Account account;
        Contact contact;
        List<Opportunity> opportunities;
        Opportunity opportunity;
        //Core model alignment
        ER_Financial_Center__c financialCenter;
        ER_Delivery_Site__c deliverySite;
        ER_Distribution_Point__c distributionPoint;
        result.put('existingcustomercontract', false);
        try{
            update lead;

            List<Account> accounts = [SELECT Id, Name, ER_Legal_Form__c, BillingStreet, BillingPostalCode,
                                             BillingCity, BillingCountry, ER_Enterprise_Number__c, Phone,
                                             ER_VAT_Number__c, BE_Client_Contract_TRE__c, BE_Client_Contract_TCE__c,
                                             BE_Client_Contract_ECE__c, OwnerId
                                      FROM Account 
                                      WHERE ER_Registration_Number__c = :enterpriseNumber AND RecordTypeId = :accountClientRecordTypeId];
            if(accounts.size() == 0){
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.AssignmentRuleHeader.useDefaultRule = TRUE;
                Database.update(new List<Lead>{lead},dmo);

                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);

                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
                lc.setConvertedStatus(convertStatus.MasterLabel);

                Database.LeadConvertResult lcr = Database.convertLead(lc);

                account = new Account(Id = lcr.getAccountId(), RecordTypeId = accountClientRecordTypeId);
                /*account.ER_Legal_Form__c = legalForm;
                account.ER_Enterprise_Number__c = enterpriseNumber;
                account.ER_VAT_Number__c = vatNumber;
                account.ER_Not_subject_to_VAT__c = !subjectToVat;
                account.Phone = phone;
                account.BillingStreet = billingAddress;
                account.BillingPostalCode = billingPostalCode;
                account.BillingCity = billingCity;
                account.BillingCountry = billingCountry;
                account.ER_Legal_Name__c = legalName.toUpperCase();                               //Added upperCase for PBI-603 by Killian Degryse
                update account;*/
                
                Id contactClientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.BE_Client_Contact_RT).getRecordTypeId();
                contact = new Contact(Id = lcr.getContactId(), RecordTypeId = contactClientRecordTypeId);
                delete contact;

                opportunity = new Opportunity(Id = lcr.getOpportunityId(), Name = productAcr + ' - ' + name,
                                              RecordTypeId = opportunityClientRecordTypeId, ER_Contract_Expected_Start_Date__c = Date.today(), Commercial_Origin__c = 'Greenfield', Auto_Enrolment_Opportunity__c = true);
                update opportunity;
            }
            else{
                account = accounts[0];
                List<ER_Solution_Line_Item__c> sliList = [SELECT Id, ER_Solution__c, ER_Account__c from ER_Solution_Line_Item__c where ER_Account__c=:account.Id AND ER_Status__c='Active' AND ER_Solution__c=:productId];
                if(!sliList.isEmpty()){
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.AssignmentRuleHeader.useDefaultRule = TRUE;
                    Database.update(new List<Lead>{lead},dmo);
                    result.put('existingcustomercontract', true);
                    return result;
                }
                account.Name = name.toUpperCase();

                opportunities = [SELECT Id, PriceBook2.Name, StageName, CloseDate, CampaignId
                                 FROM Opportunity WHERE AccountId = :account.Id AND StageName = 'Qualification'];
                if(opportunities.size() > 0){
                    opportunity = opportunities[0];
                    opportunity.StageName = 'Closed Lost';
                    opportunity.ER_Lost_Reason__c = 'Duplicates (< 2 weeks)';
                    opportunity.CloseDate = System.today();
                    opportunity.CampaignId = null;
                    opportunity.ER_Contract_Expected_Start_Date__c = Date.today();  
                    opportunity.Commercial_Origin__c = 'Greenfield'; 
                    opportunity.Auto_Enrolment_Opportunity__c = true;
                    update opportunity;
                }

                opportunity = new Opportunity(AccountId = account.Id, Name = productAcr + ' - ' + account.Name, 
                                              StageName = 'Qualification', CloseDate = System.today().addMonths(2),
                                              ER_Face_Value__c = faceValue, ER_Estimated_Number_Of_Beneficiaries__c = numberOfBeneficiaries, ER_Nb_of_Employees__c  = numberOfBeneficiaries, OwnerId = account.OwnerId, 
                                              BE_Edenred_Solution__c = product, RecordTypeId = opportunityClientRecordTypeId, LeadSource = 'Websales', ER_Lead_sub_source__c = 'Econtratonline', Product_of_Interest__c = productId);
                opportunity.ER_BUPicklist__c = businessUnit;    
                if(String.isNotBlank(pageLanguage) && (pageLanguage == 'fr_BE' || pageLanguage == 'nl_BE' || pageLanguage == 'en_US')){
                    opportunity.Preferred_Language__c = pageLanguage.substring(0, 2).toUpperCase();
                }
                opportunity.ER_Contract_Expected_Start_Date__c = Date.today();  
                opportunity.Commercial_Origin__c = 'Greenfield';  
                opportunity.Auto_Enrolment_Opportunity__c = true;                                           
               insert opportunity;
                
                if([SELECT Id FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :account.Id].size() == 0){
                    financialCenter = new ER_Financial_Center__c();
                    financialCenter.ER_Type__c = 'Client';
                    financialCenter.ER_Account_Name__c = account.Id;
                    financialCenter.ER_BUPicklist__c = businessUnit;
                    financialCenter.ER_Invoicing_Site__c = true;
                    financialCenter.ER_Invoicing_Street__c = billingAddress;
                    financialCenter.ER_Invoicing_Zip_Code__c = billingPostalCode;
                    financialCenter.ER_Invoicing_City__c = billingCity;
                    financialCenter.ER_Invoicing_Country__c = billingCountry;
                    insert financialCenter;
                }
            }
            account.ER_Legal_Form__c = legalForm;
            account.ER_Enterprise_Number__c = enterpriseNumber;
            account.ER_VAT_Number__c = vatNumber;
            account.ER_Not_subject_to_VAT__c = !subjectToVat;
            account.Phone = phone;
            account.BillingStreet = billingAddress;
            account.BillingPostalCode = billingPostalCode;
            account.BillingCity = billingCity;
            account.BillingCountry = billingCountry;
            if(billingCountry == 'BELGIUM'){
                account.ER_Country_Code__c = 'BE';
            }else if(billingCountry == 'LUXEMBOURG'){
                account.ER_Country_Code__c = 'LU';
            }
            account.ER_Legal_Name__c = legalName.toUpperCase();
            account.Account_Type__c = Integer.valueOf(numberOfBeneficiaries) > sizeLimit ? 'MM':'SME';    
            account.NumberOfEmployees = Integer.valueOf(numberOfBeneficiaries);  
            update account; 

            lead.Status = 'Qualified';
            update lead;
            // PBI-634: Source/Channel in the URL
            if(String.isNotBlank(sourceId)){

                List<Campaign> lstCamp = [SELECT ID, ER_Source_ID__c FROM Campaign WHERE ER_Source_ID__c = :sourceId];
                if(lstCamp.size()>0){
                    Campaign camp = lstCamp.get(0);
                    opportunity.CampaignId = camp.Id;
                    update opportunity;
                }
            }
            if([SELECT Id FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :account.Id].size() > 0){
                financialCenter = [SELECT Id, Name, ER_Bank_Account__c, ER_City__c, ER_Contact__c, ER_Country__c,
                                          ER_Payment_Site__c, ER_Street__c, ER_Zip_Code__c
                                   FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :account.Id LIMIT 1];
                financialCenter.Name = name.toUpperCase();
                financialCenter.ER_Street__c = billingAddress;
                financialCenter.ER_Zip_Code__c = billingPostalCode;
                financialCenter.ER_City__c = billingCity;
                financialCenter.ER_Country__c = billingCountry;
                if(billingCountry == 'BELGIUM'){
                    financialCenter.ER_Invoicing_Country_Code__c = 'BE';
                    financialCenter.ER_Country_Code__c = 'BE';
                }else if(billingCountry == 'LUXEMBOURG'){
                    financialCenter.ER_Invoicing_Country_Code__c = 'LU';
                    financialCenter.ER_Country_Code__c = 'LU';
                }
                update financialCenter;
            }
            if([SELECT Id FROM ER_Delivery_Site__c WHERE ER_Account_Name__c = :account.Id].size() > 0){
                deliverySite = [SELECT Id, ER_Account_Name__c, ER_Financial_Center__c, Name,
                                       ER_Delivery_Contact__c, ER_Street__c, ER_Zip_Code__c,
                                       ER_City__c, ER_Country__c
                                FROM ER_Delivery_Site__c
                                WHERE ER_Account_Name__c = :account.Id][0];
                if(deliverySite.ER_Financial_Center__c == null){
                    deliverySite.ER_Financial_Center__c = financialCenter.Id;
                    update deliverySite;
                }
                distributionPoint = [SELECT Id, Name, ER_Street__c, ER_Zip_Code__c,
                                            ER_City__c, ER_Country__c, ER_Delivery_Site__c
                                     FROM ER_Distribution_Point__c
                                     WHERE ER_Delivery_Site__c = :deliverySite.Id][0];
            }

            result.put('account', account);
            result.put('opportunity', opportunity);
            result.put('financialCenter', financialCenter);
            result.put('deliverySite', deliverySite);
            result.put('distributionPoint', distributionPoint);
        }
        catch(DmlException e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }
        
        result.put('correctCity', billingCity);

        //PBI-676 Validate Create existing M/C dev from 18.7 (remove blocking when merchant already exist)
        return result;
    }
    
    public static Map<String, Object> updateP2Account(String vatNumber, Boolean subjectToVat, String phone, String enterpriseNumber, 
                                                      String billingAddress, String billingPostalCode,
                                                      String billingCity, String billingCountry, String product,
                                                      Account account, String legalName, String name, String legalForm,
                                                      ER_Financial_Center__c financialCenter){
        billingCity = BE_WebForm_Controller_Helper.getCorrectCity(billingCountry, billingPostalCode, billingCity);
                                                         
        String productAcr = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :product].Name__c;
        
        Map<String, Object> result = new Map<String, Object>();
        Id accountClientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();
        Id opportunityClientRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();

        //Opportunity opportunity;
        try{       
            account.ER_VAT_Number__c = vatNumber;
            account.ER_Not_subject_to_VAT__c = !subjectToVat;
            account.Phone = phone;
            account.BillingStreet = billingAddress;
            account.BillingPostalCode = billingPostalCode;
            account.BillingCity = billingCity;
            account.BillingCountry = billingCountry;
            account.ER_Legal_Name__c = legalName.toUpperCase();                               //Added upperCase for PBI-603 by Killian Degryse
            account.Name = name.toUpperCase();
            account.ER_Legal_Form__c = legalForm;
            account.NumberOfEmployees = account.NumberOfEmployees;
            if(billingCountry == 'BELGIUM'){
                account.ER_Country_Code__c = 'BE';
            }else if(billingCountry == 'LUXEMBOURG'){
                account.ER_Country_Code__c = 'LU';
            }

            update account;

            if(financialCenter == null)
                financialCenter = [SELECT Id, Name, ER_Bank_Account__c, ER_City__c, ER_Contact__c, ER_Country__c,
                                          ER_Payment_Site__c, ER_Street__c, ER_Zip_Code__c
                                   FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :account.Id limit 1];
            financialCenter.Name = name.toUpperCase();
            financialCenter.ER_Street__c = billingAddress;
            financialCenter.ER_Zip_Code__c = billingPostalCode;
            financialCenter.ER_City__c = billingCity;
            financialCenter.ER_Country__c = billingCountry;
            if(billingCountry == 'BELGIUM'){
                financialCenter.ER_Invoicing_Country_Code__c = 'BE';
                financialCenter.ER_Country_Code__c = 'BE';
            }else if(billingCountry == 'LUXEMBOURG'){
                financialCenter.ER_Invoicing_Country_Code__c = 'LU';
                financialCenter.ER_Country_Code__c = 'LU';
            }
            update financialCenter;
        }
        catch(DmlException e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }

        result.put('account', account);
        //result.put('opportunity', opportunity);
        result.put('correctCity', billingCity);
        result.put('financialCenter', financialCenter);

        //PBI-676 Validate Create existing M/C dev from 18.7 (remove blocking when merchant already exist in ordrer to create a client)
        return result;
    }
    
    public static Map<String, Object> saveP3(Decimal numberOfEmployees, Boolean socialSecretary, String socialSecretaryName,
                                             Boolean socialSecretaryInChargeOfOrders, String shippingAddress, 
                                             String shippingNumber, String shippingPostalCode, String shippingCity, 
                                             String shippingCountry, Account account, ER_Financial_Center__c financialCenter,
                                             Id invoicingContactId, Id deliveryContactId, Id opportunityId){
        Map<String, Object> result = new Map<String, Object>();
        ER_Delivery_Site__c deliverySite = new ER_Delivery_Site__c();
        ER_Distribution_Point__c distributionPoint = new ER_Distribution_Point__c();

        Integer numberOfEmployeesTmp = (Integer)numberOfEmployees;
        account.NumberOfEmployees = numberOfEmployeesTmp;
        //account.BE_Social_Secretary__c = socialSecretary ? 'Yes' : 'No';
        account.BE_Social_Secretary_Name__c = socialSecretaryName;
        account.BE_Social_Secretary_orders__c = socialSecretaryInChargeOfOrders;

        financialCenter.ER_Contact__c = invoicingContactId;
        financialCenter.ER_Email__c = [SELECT Email FROM Contact WHERE Id = :invoicingContactId].size() > 0 ? [SELECT Email FROM Contact WHERE Id = :invoicingContactId].Email : null;

        deliverySite.ER_Account_Name__c = account.Id;
        deliverySite.ER_Financial_Center__c = financialCenter.Id;
        deliverySite.Name = financialCenter.Name;
        deliverySite.ER_Delivery_Contact__c = deliveryContactId;
        deliverySite.ER_Street__c = shippingAddress;
        if(shippingNumber != null)
            deliverySite.ER_Street__c += ' ' + shippingNumber;
        deliverySite.ER_Zip_Code__c = shippingPostalCode;
        deliverySite.ER_City__c = shippingCity;
        deliverySite.ER_Country__c = shippingCountry;
        if(shippingCountry == 'BELGIUM'){
            deliverySite.ER_Country_Code__c = 'BE';
        }else if(shippingCountry == 'LUXEMBOURG'){
            deliverySite.ER_Country_Code__c = 'LU';
        }

        distributionPoint.Name = financialCenter.Name;
        distributionPoint.ER_Street__c = deliverySite.ER_Street__c;
        distributionPoint.ER_Zip_Code__c = shippingPostalCode;
        distributionPoint.ER_City__c = shippingCity;
        distributionPoint.ER_Country__c = shippingCountry;
        if(shippingCountry == 'BELGIUM'){
            distributionPoint.ER_Country_Code__c = 'BE';
        }else if(shippingCountry == 'LUXEMBOURG'){
            distributionPoint.ER_Country_Code__c = 'LU';
        }
        Opportunity opp;
        if(String.isNotBlank(opportunityId)){opp = new Opportunity(Id=opportunityId, Social_Secretary_Name__c=socialSecretaryName, ER_Contract_Expected_Start_Date__c = Date.today(), Commercial_Origin__c = 'Greenfield', Auto_Enrolment_Opportunity__c = true);}

        try{
            if(String.isNotBlank(opportunityId)){ update opp;}
            update account;
            update financialCenter;
            insert deliverySite;
            distributionPoint.ER_Delivery_Site__c = deliverySite.Id;
            insert distributionPoint;
        }
        catch(DmlException e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }

        result.put('account', account);
        result.put('financialCenter', financialCenter);
        result.put('deliverySite', deliverySite);
        result.put('distributionPoint', distributionPoint);

        return result;
    }
    
    public static Map<String, Object> updateP3(Boolean socialSecretary, String socialSecretaryName,
                                               Boolean socialSecretaryInChargeOfOrders, String shippingAddress, 
                                               String shippingNumber, String shippingPostalCode, String shippingCity, 
                                               String shippingCountry, Account account, ER_Financial_Center__c financialCenter,
                                               ER_Delivery_Site__c deliverySite, ER_Distribution_Point__c distributionPoint,
                                               Id invoicingContactId, Id deliveryContactId, Id opportunityId){
        Map<String, Object> result = new Map<String, Object>();

        account.BE_Social_Secretary_Name__c = socialSecretaryName;
        account.BE_Social_Secretary_orders__c = socialSecretaryInChargeOfOrders;
        account.NumberOfEmployees = account.NumberOfEmployees;

        financialCenter.ER_Contact__c = invoicingContactId;
        financialCenter.ER_Email__c = [SELECT Email FROM Contact WHERE Id = :invoicingContactId].size() > 0 ?
                                           [SELECT Email FROM Contact WHERE Id = :invoicingContactId].Email : null;

        deliverySite.Name = financialCenter.Name;
        deliverySite.ER_Delivery_Contact__c = deliveryContactId;
        deliverySite.ER_Street__c = shippingAddress;
        if(shippingNumber != null)
            deliverySite.ER_Street__c += ' ' + shippingNumber;
        deliverySite.ER_Zip_Code__c = shippingPostalCode;
        deliverySite.ER_City__c = shippingCity;
        deliverySite.ER_Country__c = shippingCountry;
        if(shippingCountry == 'BELGIUM'){
            deliverySite.ER_Country_Code__c = 'BE';
        }else if(shippingCountry == 'LUXEMBOURG'){
            deliverySite.ER_Country_Code__c = 'LU';
        }

        distributionPoint.Name = financialCenter.Name;
        distributionPoint.ER_Street__c = deliverySite.ER_Street__c;
        distributionPoint.ER_Zip_Code__c = shippingPostalCode;
        distributionPoint.ER_City__c = shippingCity;
        distributionPoint.ER_Country__c = shippingCountry;
        if(shippingCountry == 'BELGIUM'){
            distributionPoint.ER_Country_Code__c = 'BE';
        }else if(shippingCountry == 'LUXEMBOURG'){
            distributionPoint.ER_Country_Code__c = 'LU';
        }
        Opportunity opp;
        if(String.isNotBlank(opportunityId)){
            opp = new Opportunity(Id=opportunityId, Social_Secretary_Name__c=socialSecretaryName);
        }

        try{
            if(String.isNotBlank(opportunityId)){update opp;}
            update account;
            update financialCenter;
            update deliverySite;
            update distributionPoint;
        }
        catch(DmlException e){
            System.debug('Error message' + e.getMessage());
            System.debug('Error line' + e.getLineNumber());
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }

        result.put('account', account);
        result.put('financialCenter', financialCenter);
        result.put('deliverySite', deliverySite);
        result.put('distributionPoint', distributionPoint);

        return result;
    }
    
    public static void createBillableServices(Id priceBookId, Decimal faceValue, Decimal rateZone, Decimal numberOfEmployees,
                                              Decimal numberOfBeneficiaries, Decimal minRate, Decimal maxRate, 
                                              Decimal minDelivery, Decimal maxDelivery, Boolean isByUnit, Boolean offerLight,
                                              Id promoCodeId, Opportunity opportunity, Account account, Id generalConditionId, 
                                              String productCode, String promoCode, Integer loadPerYear, Integer daysPerYear) {

        List<OpportunityLineItem> listOfOppProd = new List<OpportunityLineItem>();
        String resolvedProductCode = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :productCode].Name__c;

        Opportunity opp = [SELECT Id, Pricebook2Id, ER_Nb_of_Employees__c, BE_Accepted_general_conditions__c, 
                                    BE_Date_Time_accepted_general_conditions__c, BE_General_Condition__c, LeadSource, BE_Webform_Link__c
                            FROM Opportunity WHERE Id = :opportunity.Id];

        Account acc = [SELECT Id, NumberOfEmployees FROM Account WHERE Id = :account.Id];

        // Set values for the Opportunity
        opp.ER_Face_Value__c = faceValue;
        opp.ER_Nb_of_Employees__c = numberOfEmployees;
        opp.ER_Estimated_Number_Of_Beneficiaries__c = numberOfBeneficiaries;
        
        if (!offerLight) {        
            if (opp.Pricebook2Id != priceBookId) {
                opp.Pricebook2Id = priceBookId;
                delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id];
            }
            
            opp.ER_Promo_Code2__c = promoCodeId;            
        }
        
        // Update opportunity and account
        opp.BE_Accepted_general_conditions__c = true;
        opp.BE_Date_Time_accepted_general_conditions__c = Datetime.now();
        opp.BE_General_Condition__c = generalConditionId;
        acc.NumberOfEmployees = (Integer)numberOfEmployees;
        
        update opp;
        update acc;

        if(opp.BE_Webform_Link__c == null){
            // Fetch PriceBookEntries in one query
            List<PriceBookEntry> priceBookEntries = [SELECT Id, Product2Id, ER_Percentage__c, UnitPrice, Product2.Name, Product2.ProductCode, 
            ER_Max__c, ER_Min__c, 
            Product2.ER_Type__c, Product2.ER_Solution__r.Name, Product2.ER_Solution__r.ER_Solution__r.Name, 
            Product2.ER_Solution__r.ER_Solution__r.ProductCode, Product2.ER_Solution2__r.Name,
            Product2.ER_Solution__r.ER_Solution__r.ER_Solution__r.ProductCode, ER_Promo_Code2__r.ER_Promo_Code__c, ER_Offer_validity_end_date__c
            FROM PriceBookEntry 
            WHERE PriceBook2Id = :priceBookId AND Product2.IsActive = true
            ORDER BY PriceBook2Id];

            Boolean hasDiscount = false;

            for(PriceBookEntry pbe : priceBookEntries){
                if (pbe.Product2.ER_Type__c == 'Discount' && pbe.Product2.ER_Solution2__r.Name == Label.ADDITIONAL_SERVICES_LABEL && pbe.ER_Promo_Code2__r.ER_Promo_Code__c == promoCode) {
                    hasDiscount = true;
                    break;
                }
            }

            for (PriceBookEntry pbe : priceBookEntries) {
            // Check if product is Additional Service based on parent and grandparent labels
                Boolean isAdditionalService = pbe.Product2.ER_Solution2__r.Name == Label.ADDITIONAL_SERVICES_LABEL;
				
                if(String.isBlank(promoCode) || promoCode == 'Standard'){
                    //Handle Delivery
                    if (isAdditionalService && pbe.Product2.ER_Solution__r != null && pbe.Product2.ER_Solution__r.Name.contains('Delivery') && pbe.Product2.ER_Type__c == 'Range'){
                        Decimal quantity = isByUnit ? 1 : 1;
                        listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                        ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                	}
                    // Handle additional services without delivery
                    if (isAdditionalService && pbe.Product2.ER_Solution__r != null && !pbe.Product2.ER_Solution__r.Name.contains('Delivery') && !(pbe.Product2.Name.contains('Delivery')) && pbe.Product2.ER_Type__c == 'Service') {
                        Decimal quantity = 1;
                        listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                        ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                    }
                }
                else{
                    if (hasDiscount && isAdditionalService && pbe.Product2.ER_Solution__r != null && pbe.Product2.ER_Solution__r.Name.contains('Delivery') && pbe.Product2.ER_Type__c == 'Range'){
                        Decimal quantity = isByUnit ? 1 : 1;
                        listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                        ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                	}
                    // Handle additional services without delivery
                    if (hasDiscount && isAdditionalService && pbe.Product2.ER_Solution__r != null && !pbe.Product2.ER_Solution__r.Name.contains('Delivery') && !(pbe.Product2.Name.contains('Delivery')) && pbe.Product2.ER_Type__c == 'Service') {
                        Decimal quantity = 1;
                        listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                        ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                    }
                    //For Discounted Ranges
                    if (!hasDiscount && isAdditionalService && pbe.Product2.ER_Type__c == 'Range') {
                        Decimal quantity = 1;
                        listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                        ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                        
                    }else if (hasDiscount && isAdditionalService && pbe.Product2.ER_Type__c == 'Discount' && pbe.Product2.ER_Solution__r.ER_Solution__r.Name.contains('Delivery')) {
                        if(pbe.ER_Promo_Code2__r.ER_Promo_Code__c == promoCode){
                            Decimal quantity = 1;
                            listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                            ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                        }
                    }
                    
                    //For Services
                    if (!hasDiscount && isAdditionalService && pbe.Product2.ER_Solution__r != null && !(pbe.Product2.Name.contains('Delivery')) && pbe.Product2.ER_Type__c != 'Discount' && !pbe.Product2.ER_Solution__r.Name.contains('Delivery')) {
                        Decimal quantity = 1;
                        listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                            ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                    }else if (hasDiscount && isAdditionalService && pbe.Product2.ER_Solution__r != null && !(pbe.Product2.Name.contains('Delivery')) && pbe.Product2.ER_Type__c == 'Discount' && !pbe.Product2.ER_Solution__r.Name.contains('Delivery') && !pbe.Product2.ER_Solution__r.ER_Solution__r.Name.contains('Delivery')) {
                        if(pbe.ER_Promo_Code2__r.ER_Promo_Code__c == promoCode){
                            Decimal quantity = 1;
                            listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                                ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = quantity, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                        }
                    }
                }
            }

            // Handle products without promo code and match based on grandparent product code and rate
            if (String.isBlank(promoCode) || promoCode == 'Standard') {
                for (PriceBookEntry pbe : priceBookEntries) {
                    String grandParentProductCode = pbe.Product2.ER_Solution__r.ER_Solution__r.ProductCode;

                    if (grandParentProductCode == resolvedProductCode && (pbe.ER_Min__c == minRate && pbe.ER_Max__c == maxRate)) {
                        Decimal unitPrice = pbe.UnitPrice;
                        listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                                ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = unitPrice, Quantity = 1, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                    }
                }
            }
            // Handle products when a promo code is present
            else {
                for (PriceBookEntry pbe : priceBookEntries) {
                    if(pbe.ER_Promo_Code2__r.ER_Promo_Code__c == promoCode){
                        String grandGrandParentProductCode = (pbe.Product2.ER_Solution__r != null && 
                        pbe.Product2.ER_Solution__r.ER_Solution__r != null && 
                        pbe.Product2.ER_Solution__r.ER_Solution__r.ER_Solution__r != null) ? 
                        pbe.Product2.ER_Solution__r.ER_Solution__r.ER_Solution__r.ProductCode : null;
        
                        String grandParentProductCode = (pbe.Product2.ER_Solution__r != null && 
                        pbe.Product2.ER_Solution__r.ER_Solution__r != null) ? 
                        pbe.Product2.ER_Solution__r.ER_Solution__r.ProductCode : null;
        
                        if (pbe.Product2.ER_Type__c == 'Discount' && grandGrandParentProductCode == resolvedProductCode) {
                            if (pbe.ER_Min__c == minRate && pbe.ER_Max__c == maxRate) {
                                Decimal unitPrice = pbe.UnitPrice;
                                listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                                                    ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = unitPrice, Quantity = 1, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                            }
                        // Add the grandparent product code match products as well
                        if (grandParentProductCode == resolvedProductCode && pbe.ER_Min__c == minRate && pbe.ER_Max__c == maxRate) {
                            listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                                        ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = pbe.UnitPrice, Quantity = 1, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                            }
                        }
                    }else{
                        String grandParentProductCode = pbe.Product2.ER_Solution__r.ER_Solution__r.ProductCode;

                        if (grandParentProductCode == resolvedProductCode && (pbe.ER_Min__c == minRate && pbe.ER_Max__c == maxRate)) {
                            Decimal unitPrice = pbe.UnitPrice;
                            listOfOppProd.add(new OpportunityLineItem(Product2Id = pbe.Product2Id, OpportunityId = opp.Id, 
                                    ER_Percentage__c = pbe.ER_Percentage__c, UnitPrice = unitPrice, Quantity = 1, ER_Offer_validity_end_date__c = pbe.ER_Offer_validity_end_date__c));
                        }
                    }
                }
            }
        // Insert OpportunityLineItems
            if (!listOfOppProd.isEmpty()) {
                insert listOfOppProd;
            }
            
        }

    }

    private static Map<String, String> getPriceBookId(String product, String promoCode){
        Map<String, String> result = new Map<String, String>();
        product = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :product].Name__c;
        String priceBookName;
        Integer count = 0;
        List<PricebookEntry> pc = [SELECT Id, PriceBook2.Name, Product2.ProductCode, ER_Promo_Code2__c, Product2.ER_Solution2__r.ProductCode
                                     FROM PricebookEntry
                                     WHERE ER_Promo_Code2__r.ER_Promo_Code__c = :promoCode AND ER_Offer_validity_start_date__c <= TODAY
                                    AND ER_Offer_validity_end_date__c > TODAY AND PriceBook2.IsStandard = false AND IsActive = true];

        for(PricebookEntry pbe : pc){
            if(pbe.Product2.ER_Solution2__r.ProductCode.contains(product)){
                count++;
            }
        }                            
        if(pc != null && pc.size() > 0 &&  count != 0){  
            priceBookName = pc.get(0).PriceBook2.Name;
        }
        else if('Standard'.equals(promoCode)){
            System.debug('product from param: ' + product);
            priceBookName = [Select Pricebook2.Name FROM PricebookEntry WHERE Product2.ProductCode =: product  AND Pricebook2.Name=: Label.Pricebook_Name_for_Auto_Enrolment AND Pricebook2.IsStandard = false LIMIT 1].Pricebook2.Name;
        }
        else
            throw new AuraHandledException('Error_Message_Server_Error'); //Will be catch in the method which used this method

        Id promoCodeId = pc == null || pc.size() == 0 ? null : pc[0].ER_Promo_Code2__c;
        result.put('PromoCodeId', promoCodeId);
        result.put('PriceBookId', [SELECT Id FROM PriceBook2 WHERE Name = :priceBookName].Id);
        return result;
    }

    //PBI EBEITSFDC-533
/*    private static Boolean isMerchantNemo(String enterpriseNumber){
        Id accountMerchantRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Merchant).getRecordTypeId();
        List<Account> accounts = [SELECT Id, ER_Card_Operational_System_ID__c
                                  FROM Account 
                                  WHERE ER_Enterprise_Number__c = :enterpriseNumber 
                                    AND RecordTypeId = :accountMerchantRecordTypeId];

        return accounts.size() > 0 && (accounts[0].ER_Card_Operational_System_ID__c != null); 
    }*/

    //Contact form :
    @AuraEnabled
    public static Contact addContact(String accId, String salutation, String firstName, String lastName, String lang, String phone, String mobilePhone, String funct, String email){
        Contact contact;
        Id contactClientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.BE_Client_Contact_RT).getRecordTypeId();
        List<Contact> contacts = [SELECT Id,Business_Role__c,Phone,MobilePhone,FirstName,LastName FROM Contact WHERE firstName = :firstName AND lastName = : lastName AND Email = :email AND AccountId=:accId];
        //check sur record type id et accountid??
        //que faire si plusieurs contacts?
        if(contacts.size() > 0){  //contact trouvé
            contact = contacts[0];
            if (String.isNotBlank(funct.trim())){
                contact.Business_Role__c = funct;
            }
            if (String.isNotBlank(phone.trim())){
                contact.Phone = phone;
            }
            if (String.isNotBlank(mobilePhone.trim())){
                contact.MobilePhone = mobilePhone;
            }
            try{
                update contact;
            }
            catch(DmlException e){
                System.debug('Error message' + e.getMessage());
                System.debug('Error line' + e.getLineNumber());
                throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
            }
        }else{ // a créer
            contact = new Contact(RecordTypeId = contactClientRecordTypeId,Salutation = salutation,FirstName = firstName,LastName = lastName,ER_Language__c = lang,Phone = phone,MobilePhone = mobilePhone,Business_Role__c = funct, Email = email);
            contact.AccountId=accId;
            //contact.BE_Operational_Role__c = 'Public Relations Contact Person'; //TODO a adapter
            try{
                insert contact;
            }
            catch(DmlException e){
                System.debug('Error message' + e.getMessage());
                System.debug('Error line' + e.getLineNumber());
                throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
            }
        }

        return contact;
    }

    @AuraEnabled
    public static Contact adjustOperationalRoleContact(String respId1, String respId2, String respId3, String respId4, String sourceId){
        Map<Id, Contact> contactToUpdate = new Map<Id, Contact>();

        for(Contact contact : [SELECT ID,BE_Operational_Role__c,Email FROM Contact
                                WHERE Id=:respId1 OR Id = :respId2 OR Id = :respId3
                                OR Id = :respId4]){
            if(contact.Id == respId1){
                contact.BE_Operational_Role__c = BE_Util.addValueToMultiSelect(contact.BE_Operational_Role__c,Label.Operational_Role_Main_Contact_API);
                contactToUpdate.put(respId1, contact);
            }
            if(contact.Id == respId2){
                contact.BE_Operational_Role__c = BE_Util.addValueToMultiSelect(contact.BE_Operational_Role__c,Label.Operational_Role_Invoicing_Contact_API);
                contactToUpdate.put(respId2, contact);
            }
            if(contact.Id == respId3){
                contact.BE_Operational_Role__c = BE_Util.addValueToMultiSelect(contact.BE_Operational_Role__c,Label.Operational_Role_Order_Contact_API);
                contactToUpdate.put(respId3, contact);
            }
            if(contact.Id == respId4){
                contact.BE_Operational_Role__c = BE_Util.addValueToMultiSelect(contact.BE_Operational_Role__c,Label.Operational_Role_Delivery_Contact_API);

                contactToUpdate.put(respId4, contact);
            }
        }
        try{
            Database.update(contactToUpdate.values(),false);
            // PBI-634: Source/Channel in the URL
            if(String.isNotBlank(sourceId)){
                List<Campaign> lstCamp =  [SELECT ID, ER_Source_ID__c FROM Campaign WHERE ER_Source_ID__c = :sourceId];
                if(lstCamp.size() > 0){
                    Campaign camp = lstCamp.get(0);
                    CampaignMember cm = New CampaignMember(CampaignId = camp.Id, ContactId = contactToUpdate.get(respId1).Id);
                    insert cm;
                }
            }

        }
        catch(DmlException e){
            if(!e.getMessage().contains('DUPLICATE_VALUE')){
                throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
            }
        }
        //main contact
       return contactToUpdate.get(respId1);
    }

    @AuraEnabled
    public static void removeContact(String contId){
        try{
            Contact cont = [SELECT ID FROM Contact WHERE Id=:contId];
            delete cont;
        }
        catch(DmlException e){
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }
    }

    @AuraEnabled
    public static Contact updateInfosContact(String contId, String salutation, String firstName, String lastName, String lang, String phone, String mobilePhone, String funct, String email){
        Contact contact;
        try {
             contact = [
                    SELECT Id,Business_Role__c,Phone,MobilePhone,FirstName,LastName
                    FROM Contact
                    WHERE Id = :contId
            ];

            contact.salutation = salutation;
            contact.FirstName = firstName;
            contact.LastName = lastName;
            contact.ER_Language__c = lang;
            contact.Phone = phone;
            contact.MobilePhone = mobilePhone;
            contact.Business_Role__c = funct;
            contact.Email = email;
            update contact;
        }
        catch(Exception e){
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }

        return contact;
    }

    @AuraEnabled
    public static List<Contact> getContacts(Id accountId){
        return [SELECT Id, FirstName, LastName, Salutation, ER_Language__c, Phone, MobilePhone,
                Business_Role__c, Email
                FROM Contact
                WHERE AccountId = :accountId AND ER_Status__c = 'Active'];
    }

    @AuraEnabled
    public static void populateContactsOnOpportunity(String opportunityId, String primaryContactId, String invoicingContactId){
        try{
            Opportunity opp = [SELECT Id, Primary_Contact__c, Invoicing_Contact__c, AccountId FROM Opportunity WHERE Id=:opportunityId];
            Account acc = [SELECT Id, HU_HQ_Contact__c from Account where Id =: opp.AccountId];
            opp.Primary_Contact__c = primaryContactId;
            opp.Invoicing_Contact__c = invoicingContactId;
            acc.HU_HQ_Contact__c = primaryContactId;
            update opp;
            update acc;
        }
        catch(DmlException e){
            throw new AuraHandledException(BE_WebForm_Controller_Helper.getErrorMessageLabel(e.getMessage()));
        }
    }
}