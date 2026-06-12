public without sharing class clientAutoEnrollmentComponentController {

    public class ProductInfoWrapper {
        @AuraEnabled public Product2 product;
        @AuraEnabled public String translatedName;
    
        public ProductInfoWrapper(Product2 product, String translatedName) {
            this.product = product;
            this.translatedName = translatedName;
        }
    }

    public class OpportunityLineItemInfoWrapper {
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal faceValue;
        @AuraEnabled public Decimal loadPerYear;
        @AuraEnabled public Decimal daysPerMonth;
        @AuraEnabled public Decimal estimatedValue;
        @AuraEnabled public Decimal nbOfBeneficiaries;
        @AuraEnabled public String translatedName;
    
        public OpportunityLineItemInfoWrapper(String productCode, Decimal faceValue, Decimal loadPerYear, Decimal daysPerMonth, Decimal estimatedValue, Decimal nbOfBeneficiaries, String translatedName) {
            this.productCode = productCode;
            this.faceValue = faceValue;
            this.loadPerYear = loadPerYear;
            this.daysPerMonth = daysPerMonth;
            this.estimatedValue = estimatedValue;
            this.nbOfBeneficiaries = nbOfBeneficiaries;
            this.translatedName = translatedName;
        }
    }

    @AuraEnabled
    public static Map<String, OpportunityLineItemInfoWrapper> fetchMultiProductsFromOpportunity(Id opportunityId, String language) {
        Set<String> excludedCodes = new Set<String>{
            Constants.ADDITIONAL_SERVICE_CODE_BE,
            Constants.ADDITIONAL_SERVICE_CODE_LU
        };
        Map<String, Product2> codeToProductMap = new Map<String, Product2>();
    
        // Step 1: Fetch product codes from OLI
        List<OpportunityLineItem> oliList = [
            SELECT Product2.ER_Solution2__r.ProductCode,  ER_Face_Value__c, ER_Nb_Beneficiaries__c, ER_Load_Per_Year__c,
            ER_Days_Per_Month__c, ER_Estimated_Value__c, Product2.ER_Solution2__r.Name
            FROM OpportunityLineItem 
            WHERE OpportunityId = :opportunityId
                  AND Product2.ER_Solution2__r.ProductCode != null ORDER BY Product2.ER_Solution2__r.ER_Line_Order__c, Product2.ER_Line_Order__c  ASC
        ];
    
        // Step 2: Fetch translations
        Map<String, String> translationMap = new Map<String, String>();
        for (BE_Miscellaneous_Translation__mdt trans : [
            SELECT Label, BE_Label_Translation__c
            FROM BE_Miscellaneous_Translation__mdt
            WHERE BE_Language__c = :language
        ]) {
            translationMap.put(trans.Label, trans.BE_Label_Translation__c);
        }
    
        // Step 3: Build result
        Map<String, OpportunityLineItemInfoWrapper> result = new Map<String, OpportunityLineItemInfoWrapper>();
        for (OpportunityLineItem oli : oliList) {
            String code = oli.Product2.ER_Solution2__r.ProductCode;
            if (!excludedCodes.contains(code) && !result.containsKey(code)) {
                String translated = translationMap.containsKey(oli.Product2.ER_Solution2__r.Name) ? translationMap.get(oli.Product2.ER_Solution2__r.Name) : oli.Product2.ER_Solution2__r.Name;
    
                result.put(code, new OpportunityLineItemInfoWrapper(
                    code,
                    oli.ER_Face_Value__c,
                    oli.ER_Load_Per_Year__c,
                    oli.ER_Days_Per_Month__c,
                    oli.ER_Estimated_Value__c,
                    oli.ER_Nb_Beneficiaries__c,
                    translated
                ));
            }
        }
    
        return result;
    }
    
    //Method added by harkirat
    @AuraEnabled
    public static void updateMarketingPreference(Id contactId, Boolean marketingOptIn) {

        if (contactId == null) {
            return;
        }

        Contact c = new Contact(
            Id = contactId,
            Email_Opt_In__c = marketingOptIn,
            HasOptedOutOfEmail = !marketingOptIn
        );

        update c;
    }


    @AuraEnabled
    public static ProductInfoWrapper fetchProductsFromProductCode(String productCode, String language) {
        Product2 product = [SELECT Id, ER_BUPicklist__c, Load_Per_Year__c, Days_per_Month__c, Face_Value__c, Name, ER_Type__c, IsActive, ProductCode
                            FROM Product2 
                            WHERE ProductCode = :productCode 
                            AND IsActive = true
                            LIMIT 1];
    
        Map<String, String> otherTranslations = new Map<String, String>();
        for (BE_Miscellaneous_Translation__mdt miscTranslation : [
            SELECT Label, BE_Label_Translation__c 
            FROM BE_Miscellaneous_Translation__mdt 
            WHERE BE_Language__c = :language
        ]) {
            otherTranslations.put(miscTranslation.Label, miscTranslation.BE_Label_Translation__c);
        }
    
        String translatedName = otherTranslations.get(product.Name) != null ? otherTranslations.get(product.Name) : product.Name;
    
        return new ProductInfoWrapper(product, translatedName);
    }
    

    @AuraEnabled
    public static PromoCodeDetailsWrapper fetchPromoCodeDetails(String promoCode, String businessUnit, String language, String productId){
        PromoCodeDetailsWrapper promoWrap = new PromoCodeDetailsWrapper();
        for(ER_Promo_Code__c promo : [
            SELECT Id, Name, ER_Promo_Code__c, Description_DE__c, Description_EN__c, Description_Marketting_FR__c, Description_Marketting_EN__c, Description_Marketting_NL__c, Description_Marketting_DE__c, 
                ER_Description__c, Description_NL__c, ER_Business_Unit__c, (Select Id FROM Price_Book_Entries__r WHERE Product2.ER_Solution2__c =:productId AND ER_Promo_Code2__r.ER_Promo_Code__c =: promoCode)
            FROM ER_Promo_Code__c 
            WHERE ER_Promo_Code__c = :promoCode 
            AND ER_Business_Unit__c = :businessUnit 
            LIMIT 1
        ]) {
            if(promo.Price_Book_Entries__r.size() > 0) {
                promoWrap.promoId = promo.Id;
                promoWrap.name = promo.Name;
                promoWrap.promoCode = promo.ER_Promo_Code__c;
                if(language == 'fr_BE'){
                    promoWrap.markettingDescription = promo.Description_Marketting_FR__c;
                    promoWrap.description = promo.ER_Description__c;
                }else if(language == 'nl_BE'){
                    promoWrap.markettingDescription = promo.Description_Marketting_NL__c;
                    promoWrap.description = promo.Description_NL__c;
                }else if(language == 'de_BE'){
                    promoWrap.markettingDescription = promo.Description_Marketting_DE__c;
                    promoWrap.description = promo.Description_DE__c;
                }else{
                    promoWrap.markettingDescription = promo.Description_Marketting_EN__c;
                    promoWrap.description = promo.Description_EN__c;
                } 
                promoWrap.businessUnit = promo.ER_Business_Unit__c;
            }
        }
        return promoWrap;
    }

    public class PromoCodeDetailsWrapper {
        @AuraEnabled public Id promoId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String promoCode { get; set; }
        @AuraEnabled public String markettingDescription { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String businessUnit { get; set; }
    }

    @AuraEnabled
    public static string createLead(Id leadId, String salutation, String firstName, String lastName, String language, String role, String email, String phone, String mobile, Boolean optin, Integer numberOfBeneficiaries, String productId, String sourceId, String businessUnit, String promoId){
        try {
            Id clientRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Label.BE_Client_Lead).getRecordTypeId();
            Lead newLead = new Lead();
            if(leadId != null){
                newLead.Id = leadId;
            }
            newLead.Salutation = salutation;
            newLead.FirstName = firstName;
            newLead.LastName = lastName;
            newLead.ER_Language__c = language;
            newLead.Business_Role__c = role;
            newLead.Email = email;
            newLead.Phone = phone;
            newLead.MobilePhone = mobile;
            newLead.ER_Number_Of_Beneficiaries__c = numberOfBeneficiaries;
            newLead.ER_Commercial_Consent__c = optin;
            newLead.RecordTypeId = clientRecordTypeId;
            newLead.ERBE_Initial_Product_Of_Interest__c = productId;
            newLead.ER_Lead_Type__c = Label.Client;
            newLead.LeadSource = 'Websales';
            newLead.ER_Lead_sub_source__c = 'Econtratonline';
            newLead.ER_BUPicklist__c = businessUnit;
            newLead.Discount_Code__c = promoId;
            upsert newLead;
            
            if(String.isNotBlank(sourceId)){
                List<Campaign> lstCamp = [SELECT ID, ER_Source_ID__c FROM Campaign WHERE ER_Source_ID__c = :sourceId];
                if(lstCamp.size() > 0){
                    Campaign camp = lstCamp.get(0);
                    CampaignMember cm = New CampaignMember(CampaignId = camp.Id, LeadId = newLead.Id );
                    insert cm;
                }
            }

            return newLead.Id;  
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> getInfoFromBelfirst(String enterpriseNumber, String language, String businessUnit){
        Map<String, String> result;
        try {
            String idType = businessUnit == 'BE' ? 'BVDID' : 'RCSID';
            String id = businessUnit == 'BE' ? 'BE' + enterpriseNumber : enterpriseNumber;
            result = BE_WebForm_Controller_Helper.getInfosFromBelfirstCtrl(id, idType, language);
            /* result = new Map<String, String>{
                'error' => 'An error occurred while fetching data',
                'details' => 'Disabled for Testing'
            }; */
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //New method added by harkirat to fetch the contract status to hide the products
    @AuraEnabled(cacheable=true)
        public static String getActiveContractStatus(String enterpriseNumber) {
        Contract c = [
            SELECT Status 
            FROM Contract 
            WHERE Account.ER_Registration_Number__c = :enterpriseNumber
            AND Status = 'Activated'
            LIMIT 1
        ];

        return c != null ? c.Status : 'Inactive';
    }


    @AuraEnabled
    public static Map<String, Object> validateAndConvertLead(String vatNumber, Boolean subjectToVat, String phone, String commercialName, String legalForm, Integer numberOfBeneficiaries,
                                                            String enterpriseNumber, String registrationNumber, String billingAddress, String billingPostalCode, String businessUnit, String productCode,
                                                            String billingCity, String billingCountry, String productId, String productName, String leadId, String legalName, String sourceId, String pageLanguage, String jobTitle, String department, String subDepartment){
        Map<String, Object> result = new Map<String, Object>();
        Decimal sizeLimit = 0;
        Lead existingLead;
        Account account;
        Contact contact;
        List<Opportunity> opportunities;
        Opportunity opportunity;
        ER_Financial_Center__c financialCenter;
        ER_Delivery_Site__c deliverySite;
        ER_Distribution_Point__c distributionPoint;

        result.put('existingcustomercontract', false);                                                       

        billingCity = BE_WebForm_Controller_Helper.getCorrectCity(billingCountry, billingPostalCode, billingCity);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        List<Webform_Client_Settings__mdt> clientSetting = [SELECT DeveloperName, Id, Value__c FROM Webform_Client_Settings__mdt where DeveloperName='SizeLimit'];
                                                           if(!clientSetting.isEmpty()){
                                                               sizeLimit = clientSetting[0].Value__c;
                                                           }
        Id accountClientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();
        Id opportunityClientRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();
        Id contactClientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.BE_Client_Contact_RT).getRecordTypeId();
        
        existingLead = [SELECT Id, Company, ER_VAT_Number__c, ER_Not_Subject_to_VAT__c, ER_Legal_Form__c, Phone, Street, PostalCode, Salutation,
                            City, Country, ER_Legal_Name__c, NumberOfEmployees, ER_Registration_Number__c,
                            RCS_Number__c,
                            ERBE_Initial_Product_Of_Interest__c, ER_BUPicklist__c, LeadSource, ER_Lead_sub_source__c,
                            ER_Country_Code__c, ER_Legal_Country_Code__c, FirstName, LastName, Email, Business_Role__c, ER_Language__c, MobilePhone
                        FROM Lead
                        WHERE Id = :leadId
                    ];

        if(leadId != null){
            existingLead.Company = commercialName.toUpperCase();
            existingLead.ER_VAT_Number__c = vatNumber; 
            existingLead.ER_Legal_Form__c = legalForm;
            existingLead.Phone = phone;
            existingLead.Street = billingAddress;
            existingLead.PostalCode = billingPostalCode;
            existingLead.City = billingCity;
            existingLead.Country = billingCountry;
            existingLead.ER_Legal_Name__c = legalName;
            existingLead.NumberOfEmployees = Integer.valueOf(numberOfBeneficiaries); 
            existingLead.ER_Registration_Number__c = enterpriseNumber;
            if (businessUnit == 'LU') {
                existingLead.RCS_Number__c = registrationNumber;
            }
            existingLead.ERBE_Initial_Product_Of_Interest__c = productId;
            existingLead.ER_BUPicklist__c = businessUnit;  
            existingLead.ER_Not_Subject_to_VAT__c = subjectToVat;                                             
            if(billingCountry == 'BELGIUM'){
                existingLead.ER_Country_Code__c = 'BE';
                existingLead.ER_Legal_Country_Code__c = 'BE';                                             
            }else if(billingCountry == 'LUXEMBOURG'){
                existingLead.ER_Country_Code__c = 'LU';  
                existingLead.ER_Legal_Country_Code__c = 'LU';                                               
            }                          
        }
                    
        try {
            update existingLead;

            List<Account> accounts = [SELECT Id, Name, ER_Legal_Form__c, BillingStreet, BillingPostalCode,
                                             BillingCity, BillingCountry, ER_Enterprise_Number__c, Phone, HU_HQ_Contact__c,
                                             ER_VAT_Number__c, OwnerId, Account_Type__c, ER_Legal_Name__c, NumberOfEmployees
                                      FROM Account 
                                      WHERE ER_Registration_Number__c = :enterpriseNumber AND RecordTypeId = :accountClientRecordTypeId];
            
            if(accounts.isEmpty()){
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.AssignmentRuleHeader.useDefaultRule = TRUE;
                Database.update(new List<Lead>{existingLead},dmo);

                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(existingLead.Id);

                lc.setConvertedStatus(convertStatus.MasterLabel);

                lc.setDoNotCreateOpportunity(false);
                Database.LeadConvertResult lcr = Database.convertLead(lc);

                
                account = new Account(Id = lcr.getAccountId(), RecordTypeId = accountClientRecordTypeId, HU_HQ_Contact__c = lcr.getContactId());
                update account;

                opportunity = new Opportunity(Id = lcr.getOpportunityId(), Name = productCode + ' - ' + commercialName,
                                              RecordTypeId = opportunityClientRecordTypeId, ER_Contract_Expected_Start_Date__c = Date.today(), Commercial_Origin__c = 'Greenfield', Auto_Enrolment_Opportunity__c = true);
                update opportunity;

                contact = new contact(Id = lcr.getContactId(), RecordTypeId = contactClientRecordTypeId,Title = jobTitle, ER_Department_Family__c = department, ER_SubDepartment_Family__c = subDepartment);
                update contact;    

                result.put('account', account);
                result.put('opportunity', opportunity);
                result.put('contact', contact);
            }else{
                account = accounts[0];
                //Need logic to fetch existing primary account ID from OCR
                List<ER_Solution_Line_Item__c> activeSolutionList = [Select Id, ER_Solution__c, ER_Solution__r.ProductCode, ER_Status__c FROM ER_Solution_Line_Item__c WHERE ER_Status__c = 'Active' AND ER_Solution__c=: productId AND ER_Account__c=:accounts[0].Id];

                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(existingLead.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);

                List<ER_Financial_Center__c> financialCenterList = [
                    SELECT Id, Name, ER_Bank_Account__c, ER_City__c, ER_Contact__c, ER_Country__c,
                        ER_Payment_Site__c, ER_Street__c, ER_Zip_Code__c
                    FROM ER_Financial_Center__c
                    WHERE ER_Account_Name__c = :account.Id
                    LIMIT 1
                ];

                if (financialCenterList.isEmpty()) {
                    financialCenter = new ER_Financial_Center__c();
                    financialCenter.ER_Type__c = 'Client';
                    financialCenter.ER_Account_Name__c = account.Id;
                    financialCenter.ER_BUPicklist__c = businessUnit;
                    financialCenter.ER_Invoicing_Site__c = true;
                    financialCenter.ER_Invoicing_Street__c = billingAddress;
                    financialCenter.ER_Invoicing_Zip_Code__c = billingPostalCode;
                    financialCenter.ER_Invoicing_City__c = billingCity;
                    financialCenter.ER_Invoicing_Country__c = billingCountry;
                    if(activeSolutionList.isEmpty()){
                        insert financialCenter;
                    }
                } else {
                    financialCenterList[0].Name = commercialName.toUpperCase();
                    financialCenterList[0].ER_Street__c = billingAddress;
                    financialCenterList[0].ER_Zip_Code__c = billingPostalCode;
                    financialCenterList[0].ER_City__c = billingCity;
                    financialCenterList[0].ER_Country__c = billingCountry;

                    if (billingCountry == 'BELGIUM') {
                        financialCenterList[0].ER_Invoicing_Country_Code__c = 'BE';
                        financialCenterList[0].ER_Country_Code__c = 'BE';
                    } else if (billingCountry == 'LUXEMBOURG') {
                        financialCenterList[0].ER_Invoicing_Country_Code__c = 'LU';
                        financialCenterList[0].ER_Country_Code__c = 'LU';
                    }
                    if(activeSolutionList.isEmpty()){
                        update financialCenterList[0];
                    }
                }


                account.ER_Legal_Form__c = legalForm;
                account.ER_Enterprise_Number__c = enterpriseNumber;
                account.ER_Registration_Number__c = enterpriseNumber;
                if (businessUnit == 'LU') {
                    account.RCS_Number__c = registrationNumber;
                }
                account.ER_VAT_Number__c = vatNumber;
                account.ER_Not_subject_to_VAT__c = subjectToVat;
                account.Phone = phone;
                account.BillingStreet = billingAddress;
                account.BillingPostalCode = billingPostalCode;
                account.BillingCity = billingCity;
                account.BillingCountry = billingCountry;
                account.Name = commercialName.toUpperCase();
                if(billingCountry == 'BELGIUM'){
                    account.ER_Country_Code__c = 'BE';
                }else if(billingCountry == 'LUXEMBOURG'){
                    account.ER_Country_Code__c = 'LU';
                }
                account.ER_Legal_Name__c = legalName.toUpperCase();
                account.Account_Type__c = Integer.valueOf(numberOfBeneficiaries) > sizeLimit ? 'MM':'SME';    
                account.NumberOfEmployees = Integer.valueOf(numberOfBeneficiaries);  
                if(activeSolutionList.isEmpty()){
                    update account;
                }

                List<Contact> matchingContacts = [
                    SELECT Id, FirstName, LastName, Phone, Email, Business_Role__c, ER_Language__c, MobilePhone
                    FROM Contact
                    WHERE Email = :existingLead.Email AND AccountId =: account.Id
                    AND (
                            FirstName LIKE :('%' + existingLead.FirstName + '%') AND
                            LastName LIKE :('%' + existingLead.LastName + '%')
                    )
                    LIMIT 1
                ];
                if (!matchingContacts.isEmpty()) {
                    contact = matchingContacts[0];
                    contact.Salutation = existingLead.Salutation;
                    contact.Phone = existingLead.Phone;
                    contact.Business_Role__c = existingLead.Business_Role__c;
                    contact.MobilePhone = existingLead.MobilePhone;
                    contact.ER_Language__c = existingLead.ER_Language__c;
                    contact.Title = jobTitle;
                    contact.ER_Department_Family__c = department;
                    contact.ER_SubDepartment_Family__c = subDepartment;
                    if(activeSolutionList.isEmpty()){
                        update contact;
                    }
                    result.put('contact', contact);
                } else {
                    
                    contact = new Contact(
                        Salutation = existingLead.Salutation,
                        FirstName = existingLead.FirstName,
                        LastName = existingLead.LastName,
                        Email = existingLead.Email,
                        Phone = existingLead.Phone,
                        Business_Role__c = existingLead.Business_Role__c,
                        MobilePhone = existingLead.MobilePhone,
                        ER_Language__c = existingLead.ER_Language__c,
                        AccountId = account.Id,
                        RecordTypeId = contactClientRecordTypeId,
                        Title = jobTitle,
                        ER_Department_Family__c = department,
                        ER_SubDepartment_Family__c = subDepartment
                    );
                    if(activeSolutionList.isEmpty()){
                        insert contact;
                    }
                    result.put('contact', contact);
                }

                if (account.HU_HQ_Contact__c == null) {
                    account.HU_HQ_Contact__c = contact.Id;
                    if(activeSolutionList.isEmpty()){
                        update account;
                    }
                }

                List<ER_Delivery_Site__c> deliverySites = [
                    SELECT Id, ER_Account_Name__c, ER_Financial_Center__c, Name,
                           ER_Delivery_Contact__c, ER_Street__c, ER_Zip_Code__c,
                           ER_City__c, ER_Country__c
                    FROM ER_Delivery_Site__c
                    WHERE ER_Account_Name__c = :account.Id
                    LIMIT 1
                ];
                
                if (!deliverySites.isEmpty()) {
                    deliverySite = deliverySites[0];
                
                    if (deliverySite.ER_Financial_Center__c == null) {
                        if(activeSolutionList.isEmpty()){
                            deliverySite.ER_Financial_Center__c = financialCenter.Id;
                            update deliverySite;
                        }
                    }
                
                    List<ER_Distribution_Point__c> distributionPoints = [
                        SELECT Id, Name, ER_Street__c, ER_Zip_Code__c,
                               ER_City__c, ER_Country__c, ER_Delivery_Site__c
                        FROM ER_Distribution_Point__c
                        WHERE ER_Delivery_Site__c = :deliverySite.Id
                        LIMIT 1
                    ];
                
                    if (!distributionPoints.isEmpty()) {
                        distributionPoint = distributionPoints[0];
                    }
                }
    
                result.put('account', account);
                if(financialCenterList.isEmpty()){
                    result.put('financialCenter', financialCenter);
                }else{
                    result.put('financialCenter', financialCenterList[0]);
                }
                
                result.put('deliverySite', deliverySite);
                result.put('distributionPoint', distributionPoint);

                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.AssignmentRuleHeader.useDefaultRule = TRUE;
                Database.update(new List<Lead>{existingLead},dmo);

                if(!activeSolutionList.isEmpty()){

                    /* lc.setAccountId(account.Id);
                    lc.setContactId(contact.Id);
                    lc.setDoNotCreateOpportunity(true);
                    Database.LeadConvertResult lcr = Database.convertLead(lc); */
                    
                    existingLead.Status = 'Rejected';
                    existingLead.ER_Rejected_Reason__c = 'Duplicates (< 2 weeks)';
                    update existingLead;

                    result.put('existingcustomercontract', true);
                    return result;

                }else{
                    opportunities = [SELECT Id, PriceBook2.Name, StageName, CloseDate, CampaignId
                                 FROM Opportunity WHERE AccountId = :account.Id AND StageName = 'Qualification' AND Auto_Enrolment_Opportunity__c = true];
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

                    lc.setAccountId(account.Id);
                    lc.setContactId(contact.Id);
                    lc.setDoNotCreateOpportunity(false);
                    Database.LeadConvertResult lcr = Database.convertLead(lc);

                    opportunity = new Opportunity(Id = lcr.getOpportunityId(), Name = productCode + ' - ' + commercialName,
                                              RecordTypeId = opportunityClientRecordTypeId, ER_Contract_Expected_Start_Date__c = Date.today(), Commercial_Origin__c = 'Greenfield', Auto_Enrolment_Opportunity__c = true);
                    update opportunity;

                    result.put('opportunity', opportunity);
                }

            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Added by harkirat
    @AuraEnabled(cacheable=true)
    public static Boolean hasActiveContract(String enterpriseNumber) {
        if (String.isBlank(enterpriseNumber)) {
            return false;
        }
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE ER_Registration_Number__c = :enterpriseNumber
            LIMIT 1
        ];
        if (accounts.isEmpty()) {
            return false;
        }

        Id accId = accounts[0].Id;
        Integer cnt = [
            SELECT COUNT()
            FROM Contract
            WHERE AccountId = :accId
            AND Status = 'Activated'
        ];

        return cnt > 0;
    }


    @AuraEnabled(cacheable=true)
    public static Decimal getMaxBeneficiaryCount() {
        Webform_Client_Settings__mdt record = [
            SELECT value__c FROM Webform_Client_Settings__mdt 
            WHERE DeveloperName = 'Max_Beneficiary_Count' LIMIT 1
        ];
        return record.value__c;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getSettingsAttributes(){
        Map<String, String> result = new Map<String, String>();

        for(Webform_Client_Settings__mdt wcs : [SELECT MasterLabel, Value__c FROM Webform_Client_Settings__mdt]){
            result.put(wcs.MasterLabel, String.valueOf(wcs.Value__c));
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getSMESizeLimit() {
        Webform_Client_Settings__mdt record = [
            SELECT value__c FROM Webform_Client_Settings__mdt 
            WHERE DeveloperName = 'SizeLimit' LIMIT 1
        ];
        return record.value__c;
    }

    @AuraEnabled
    public static List<ProductWrapper> fetchActiveProducts(String enterpriseNumber, String language, String businessUnit){
        try {
            
            Map<String, String> otherTranslations = new Map<String, String>();
            Map<String, String> enrollmentValueMap = new Map<String, String>();
            Set<String> productCodes = new Set<String>();

            for(BE_Miscellaneous_Translation__mdt miscTranslation : [SELECT Label, BE_Label_Translation__c
                                                                    FROM BE_Miscellaneous_Translation__mdt
                                                                    WHERE BE_Language__c = :language]){
                otherTranslations.put(miscTranslation.Label, miscTranslation.BE_Label_Translation__c);
            }
            List<ProductWrapper> results = new List<ProductWrapper>();
            Set<Id> activeSolutionSet = new Set<Id>();
            List<ER_Solution_Line_Item__c> activeSolutionList = [Select Id, ER_Solution__c, ER_Solution__r.ProductCode, ER_Status__c FROM ER_Solution_Line_Item__c WHERE ER_Status__c = 'Active' AND ER_Account__r.ER_Registration_Number__c=:enterpriseNumber];
            List<Product2> solutionListForBU = [Select Id, Name, productCode FROM Product2 WHERE ER_Type__c = 'Solution' AND ER_BUPicklist__c =: businessUnit AND IsActive = true AND Solution_Group__c ='Benefits' AND (ProductCode !=: Constants.ADDITIONAL_SERVICE_CODE_BE AND ProductCode !=: Constants.ADDITIONAL_SERVICE_CODE_LU) ORDER BY ER_Line_Order__c ASC];

            if(!activeSolutionList.isEmpty()){
                for(ER_Solution_Line_Item__c sli: activeSolutionList) {
                    activeSolutionSet.add(sli.ER_Solution__c);
                }
            }

            for (Product2 product : solutionListForBU) {
                if (String.isNotBlank(product.ProductCode)) {
                    productCodes.add(product.ProductCode);
                }
            }

            if (!productCodes.isEmpty()) {
                for (Auto_Enrollment__mdt meta : [
                    SELECT MasterLabel, Value__c
                    FROM Auto_Enrollment__mdt
                    WHERE MasterLabel IN :productCodes
                ]) {
                    enrollmentValueMap.put(meta.MasterLabel, meta.Value__c);
                }
            }

            if(!solutionListForBU.isEmpty()){
                for(Product2 product: solutionListForBU){
                    String productName = otherTranslations.get(product.Name) != null ? otherTranslations.get(product.Name)
                    : product.Name;
                    Boolean isActive = activeSolutionSet.contains(product.Id);
                    String productBrand = enrollmentValueMap.get(product.ProductCode) != null ? enrollmentValueMap.get(product.ProductCode)
                    : '';
                    results.add(new ProductWrapper(product.Id, productName, productBrand, product.ProductCode, isActive));

                }
            }
            System.debug('Final ProductWrapper List: ' + results);
            return results;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ProductWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String ProductBrand;
        @AuraEnabled public String ProductCode;
        @AuraEnabled public Boolean IsActive;

        public ProductWrapper(String id, String name, String productBrand, String productCode, Boolean isActive) {
            this.Id = id;
            this.Name = name;
            this.ProductBrand = productBrand;
            this.ProductCode = productCode;
            this.IsActive = isActive;
        }
    }
    @AuraEnabled
    public static Map<String, Contact> fetchContactFromAccount(String enterPriseNumber, String opportunityId, String primaryContactId){
        try {
            Map<String, Contact> result = new Map<String, Contact>();
            Set<Id> opportunityContactIdSet = new Set<Id>();
            Map<Id, String> contactIdToRoleMap = new Map<Id, String>();

            Contact primaryContact = [
                        SELECT Id, Salutation, FirstName, LastName, ER_Language__c, Email, Phone, MobilePhone, Business_Role__c, Title, ER_Department_Family__c, ER_SubDepartment_Family__c
                        FROM Contact 
                        WHERE Id = :primaryContactId
                    ];
            result.put('Primary Contact', primaryContact);

            if (opportunityId != null) {
                List<OpportunityContactRole> ocrList = [
                    SELECT ContactId, Role 
                    FROM OpportunityContactRole 
                    WHERE OpportunityId = :opportunityId
                    AND ContactId != null
                    AND Role != null
                ];
            
                Set<Id> contactIds = new Set<Id>();
                for (OpportunityContactRole ocr : ocrList) {
                    contactIds.add(ocr.ContactId);
                }
            
                Map<Id, Contact> contactMap = new Map<Id, Contact>(
                    [SELECT Id, Salutation, FirstName, LastName, ER_Language__c, Email, Phone, MobilePhone, Business_Role__c, Title, ER_Department_Family__c, ER_SubDepartment_Family__c
                     FROM Contact 
                     WHERE Id IN :contactIds]
                );
            
                for (OpportunityContactRole ocr : ocrList) {
                    Contact contact = contactMap.get(ocr.ContactId);
                    if (contact != null) {
                        result.put(ocr.Role, contact);
                    }
                }
            }
            if (!opportunityContactIdSet.isEmpty()) {
                for (Contact con : [
                    SELECT Id, Salutation, FirstName, LastName, ER_Language__c, Email, Phone, MobilePhone, Business_Role__c, Title, ER_Department_Family__c, ER_SubDepartment_Family__c
                    FROM Contact 
                    WHERE Id IN :opportunityContactIdSet
                ]) {
                    String role = contactIdToRoleMap.get(con.Id);
                    if (role != null) {
                        result.put(role, con);
                    }
                }
            }
            return result;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Id> upsertContactsAndRoles(
        Id opportunityId,
        Map<String, Contact> mapOfContacts,
        String primaryContactId,
        String billingContactId,
        String orderContactId,
        String deliveryContactId,
        Boolean secretaryHandlingOrders,
        String secretaryName
    ) {
        try{
            Map<String, Id> resultMap = new Map<String, Id>();

            if (mapOfContacts == null || mapOfContacts.isEmpty()) return resultMap;
            
            Opportunity opp = [
                SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityId LIMIT 1
            ];
            Id accountId = opp.AccountId;

            if (accountId == null) {
                throw new AuraHandledException('Opportunity has no related Account.');
            }

            // Step 1: Prepare
            Set<String> emails = new Set<String>();
            Map<String, Contact> tempKeyToContact = new Map<String, Contact>();
            Map<String, List<String>> emailToTempKeys = new Map<String, List<String>>();
            Map<String, List<String>> nameComboToTempKeys = new Map<String, List<String>>();
            Set<Id> updateContactIds = new Set<Id>();

            for (String key : mapOfContacts.keySet()) {
                Contact c = mapOfContacts.get(key);
                tempKeyToContact.put(key, c);

                if (c.Email != null) {
                    String emailLower = c.Email.toLowerCase();
                    emails.add(emailLower);
                    if (!emailToTempKeys.containsKey(emailLower)) emailToTempKeys.put(emailLower, new List<String>());
                    emailToTempKeys.get(emailLower).add(key);
                }

                if (c.FirstName != null && c.LastName != null) {
                    String combo = (c.FirstName + ' ' + c.LastName).toLowerCase();
                    if (!nameComboToTempKeys.containsKey(combo)) nameComboToTempKeys.put(combo, new List<String>());
                    nameComboToTempKeys.get(combo).add(key);
                }
            }

            // Step 2: Query existing contacts
            List<Contact> existingContacts = new List<Contact>();
            if (!emails.isEmpty()) {
                existingContacts = [
                    SELECT Id, Email, FirstName, LastName, Phone, MobilePhone, ER_Language__c, Business_Role__c, Salutation, Title, ER_Department_Family__c, ER_SubDepartment_Family__c
                    FROM Contact
                    WHERE Email IN :emails
                ];
            }

            Map<String, Id> tempKeyToRealId = new Map<String, Id>();
            List<Contact> contactsToInsert = new List<Contact>();
            List<Contact> contactsToUpdate = new List<Contact>();

            // Step 3: Match & prepare
            for (String key : tempKeyToContact.keySet()) {
                Contact incoming = tempKeyToContact.get(key);
                Contact matched = null;

                // Match by Email
                for (Contact existing : existingContacts) {
                    if (existing.Email != null && incoming.Email != null && existing.Email.equalsIgnoreCase(incoming.Email)) {
                        matched = existing;
                        break;
                    }
                }

                // If still not matched, try matching fuzzy FirstName + LastName
                if (matched == null) {
                    List<Contact> fuzzyMatches = [
                        SELECT Id, Email, FirstName, LastName, Phone, MobilePhone, ER_Language__c, Business_Role__c, Salutation
                        FROM Contact
                        WHERE AccountId = :accountId
                        AND (
                            FirstName LIKE :('%' + incoming.FirstName + '%') AND
                            LastName LIKE :('%' + incoming.LastName + '%')
                        )
                        LIMIT 1
                    ];

                    if (!fuzzyMatches.isEmpty()) {
                        matched = fuzzyMatches[0];
                    }
                }

                if (matched != null) {
                    // Update existing contact fields except name and email
                    if (incoming.Salutation != null) matched.Salutation = incoming.Salutation;
                    if (incoming.Phone != null) matched.Phone = incoming.Phone;
                    if (incoming.MobilePhone != null) matched.MobilePhone = incoming.MobilePhone;
                    if (incoming.ER_Language__c != null) matched.ER_Language__c = incoming.ER_Language__c;
                    if (incoming.Business_Role__c != null) matched.Business_Role__c = incoming.Business_Role__c;
                    if (incoming.Title != null) matched.Title = incoming.Title;
                    if (incoming.ER_Department_Family__c != null) matched.ER_Department_Family__c = incoming.ER_Department_Family__c;
                    if (incoming.ER_SubDepartment_Family__c != null) matched.ER_SubDepartment_Family__c = incoming.ER_SubDepartment_Family__c;

                    if (!updateContactIds.contains(matched.Id)) {
                        contactsToUpdate.add(matched);
                        updateContactIds.add(matched.Id);
                    }
                
                    tempKeyToRealId.put(key, matched.Id);
                } else {
                    // Insert new
                    Contact newCon = new Contact(
                        FirstName = incoming.FirstName,
                        LastName = incoming.LastName,
                        Email = incoming.Email,
                        Phone = incoming.Phone,
                        MobilePhone = incoming.MobilePhone,
                        ER_Language__c = incoming.ER_Language__c,
                        Business_Role__c = incoming.Business_Role__c,
                        Salutation = incoming.Salutation,
                        AccountId = accountId,
                        title = incoming.title,
                        ER_Department_Family__c = incoming.ER_Department_Family__c,
                        ER_SubDepartment_Family__c = incoming.ER_SubDepartment_Family__c
                    );
                    contactsToInsert.add(newCon);
                    tempKeyToRealId.put(key, null); // temp
                }
            }

            // Step 4: Insert New
            if (!contactsToInsert.isEmpty()) {
                Database.insert(contactsToInsert, false);
                Integer idx = 0;
                for (String key : tempKeyToRealId.keySet()) {
                    if (tempKeyToRealId.get(key) == null && idx < contactsToInsert.size()) {
                        tempKeyToRealId.put(key, contactsToInsert[idx++].Id);
                    }
                }
            }

            // Step 5: Update
            if (!contactsToUpdate.isEmpty()) {
                Database.update(contactsToUpdate, false);
            }

            // Step 6: Map temp contact ids
            Id primaryId = tempKeyToRealId.containsKey(primaryContactId) ? tempKeyToRealId.get(primaryContactId) : primaryContactId;
            Id billingId = tempKeyToRealId.containsKey(billingContactId) ? tempKeyToRealId.get(billingContactId) : billingContactId;
            Id orderId = tempKeyToRealId.containsKey(orderContactId) ? tempKeyToRealId.get(orderContactId) : orderContactId;
            Id deliveryId = tempKeyToRealId.containsKey(deliveryContactId) ? tempKeyToRealId.get(deliveryContactId) : deliveryContactId;

            // Step 7: Delete old OCRs
            List<OpportunityContactRole> oldOCRs = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opportunityId];
            if (!oldOCRs.isEmpty()) {
                delete oldOCRs;
            }

            // Step 8: Create new OCRs
            List<OpportunityContactRole> newOCRs = new List<OpportunityContactRole>();

            if (primaryId != null) {
                newOCRs.add(new OpportunityContactRole(OpportunityId = opportunityId, ContactId = primaryId, Role = 'Primary Contact'));
                resultMap.put('Primary Contact', primaryId);
            }
            if (billingId != null) {
                newOCRs.add(new OpportunityContactRole(OpportunityId = opportunityId, ContactId = billingId, Role = 'Invoicing Contact'));
                resultMap.put('Invoicing Contact', billingId);
            }
            if (orderId != null) {
                newOCRs.add(new OpportunityContactRole(OpportunityId = opportunityId, ContactId = orderId, Role = 'Order Contact'));
                resultMap.put('Order Contact', orderId);
            }
            if (deliveryId != null) {
                newOCRs.add(new OpportunityContactRole(OpportunityId = opportunityId, ContactId = deliveryId, Role = 'Delivering Contact'));
                resultMap.put('Delivering Contact', deliveryId);
            }

            if (!newOCRs.isEmpty()) {
                insert newOCRs;
            }
            Account accountToUpdate = new account();
            accountToUpdate.Id = accountId;
            accountToUpdate.BE_Social_Secretary_Name__c = secretaryName;
            accountToUpdate.ERBE_Social_secretary_needed_for_Orders__c = secretaryHandlingOrders;
            update accountToUpdate;

            return resultMap;
        }catch(Exception e){
            System.debug('Line Number: ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());

        }
    }

    @AuraEnabled
    public static void updateAccountData(
        Integer noOfEmployees,
        String shippingName,
        String shippingStreet,
        String shippingPostalCode,
        String shippingCity,
        String shippingCountry,
        Boolean isEmployeeSameAsBenef,
        Boolean isBillingSameAsShipping,
        String enterpriseNumber,
        Integer noOfBeneficiaries,
        Map<String, Id> opportunityContactRolesMap,
        String opportunityId
    ){
        if (String.isEmpty(enterpriseNumber)) {
            throw new AuraHandledException('Invalid parameters.');
        }

        List<Account> accounts = [
            SELECT Id, Name, NumberOfEmployees, HU_HQ_Contact__c, ER_Registration_Number__c
            FROM Account
            WHERE ER_Registration_Number__c = :enterpriseNumber
            LIMIT 1
        ];

        if (accounts.isEmpty()) {
            throw new AuraHandledException('Account not found for given enterprise number.');
        }

        Account acc = accounts[0];

        acc.NumberOfEmployees = isEmployeeSameAsBenef ? noOfBeneficiaries : noOfEmployees;
        if (opportunityContactRolesMap != null && opportunityContactRolesMap.containsKey('Primary Contact')) {
            acc.HU_HQ_Contact__c = opportunityContactRolesMap.get('Primary Contact');
        }

        update acc;

        if (!String.isEmpty(opportunityId)) {
            Opportunity oppToUpdate = [
                SELECT Id, ER_Estimated_Number_Of_Beneficiaries__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            oppToUpdate.ER_Estimated_Number_Of_Beneficiaries__c = noOfBeneficiaries;
            update oppToUpdate;
        }

        // Fetch Financial Center
        ER_Financial_Center__c financialCenter = [
            SELECT Id, Name, ER_Contact__c, ER_Invoicing_Street__c, ER_Invoicing_Zip_Code__c, ER_Invoicing_City__c, ER_Invoicing_Country__c, ER_Country_Code__c
            FROM ER_Financial_Center__c
            WHERE ER_Account_Name__c = :acc.Id
            LIMIT 1
        ];

        if (opportunityContactRolesMap != null && opportunityContactRolesMap.containsKey('Invoicing Contact')) {
            financialCenter.ER_Contact__c = opportunityContactRolesMap.get('Invoicing Contact');
            update financialCenter;
        }

        // Fetch Delivery Site

        String street = isBillingSameAsShipping ? financialCenter.ER_Invoicing_Street__c : shippingStreet;
        String zip = isBillingSameAsShipping ? financialCenter.ER_Invoicing_Zip_Code__c : shippingPostalCode;
        String city = isBillingSameAsShipping ? financialCenter.ER_Invoicing_City__c : shippingCity;
        String country = isBillingSameAsShipping ? financialCenter.ER_Invoicing_Country__c : shippingCountry;

        List<ER_Delivery_Site__c> deliverySites = [
            SELECT Id, Name, ER_Account_Name__c, ER_Financial_Center__c, ER_Delivery_Contact__c, ER_Street__c, ER_Zip_Code__c, ER_City__c, ER_Country__c, ER_Country_Code__c
            FROM ER_Delivery_Site__c
            WHERE (ER_Account_Name__c = :acc.Id OR ER_Financial_Center__c = :financialCenter.Id) 
            AND ER_Street__c = :street
            AND ER_Zip_Code__c = :zip
            AND ER_City__c = :city
            AND ER_Country__c = :country
            LIMIT 1
        ];

        ER_Delivery_Site__c deliverySite;
        if (!deliverySites.isEmpty()) {
            deliverySite = deliverySites[0];
        } else {
            deliverySite = new ER_Delivery_Site__c();
            deliverySite.ER_Account_Name__c = acc.Id;
        }

        if (deliverySite.ER_Financial_Center__c == null) {
            deliverySite.ER_Financial_Center__c = financialCenter.Id;
        }

        String countryCode = (country != null && country.length() >= 2) 
        ? country.trim().substring(0, 2).toUpperCase() 
        : null;
        // Assign delivery site fields
        deliverySite.Name = isBillingSameAsShipping ? financialCenter.Name : shippingName;
        deliverySite.Name = isBillingSameAsShipping ? financialCenter.Name : shippingName;
        deliverySite.ER_Street__c = street;
        deliverySite.ER_Zip_Code__c = zip;
        deliverySite.ER_City__c = city;
        deliverySite.ER_Country__c = country;
        deliverySite.ER_Country_Code__c = isBillingSameAsShipping ? financialCenter.ER_Country_Code__c : countryCode;


        if (opportunityContactRolesMap != null && opportunityContactRolesMap.containsKey('Delivering Contact')) {
            deliverySite.ER_Delivery_Contact__c = opportunityContactRolesMap.get('Delivering Contact');
        }

        upsert deliverySite;

        // Fetch Distribution Point
        List<ER_Distribution_Point__c> distributionPoints = [
            SELECT Id, Name, ER_Street__c, ER_Zip_Code__c, ER_City__c, ER_Country__c, ER_Delivery_Site__c, ER_Country_Code__c
            FROM ER_Distribution_Point__c
            WHERE ER_Delivery_Site__c = :deliverySite.Id
            LIMIT 1
        ];

        ER_Distribution_Point__c distributionPoint;
        if (!distributionPoints.isEmpty()) {
            distributionPoint = distributionPoints[0];
        } else {
            distributionPoint = new ER_Distribution_Point__c();
            distributionPoint.ER_Delivery_Site__c = deliverySite.Id;
        }

        // Assign distribution point fields
        distributionPoint.Name = deliverySite.Name;
        distributionPoint.ER_Street__c = deliverySite.ER_Street__c;
        distributionPoint.ER_Zip_Code__c = deliverySite.ER_Zip_Code__c;
        distributionPoint.ER_City__c = deliverySite.ER_City__c;
        distributionPoint.ER_Country__c = deliverySite.ER_Country__c;
        distributionPoint.ER_Country_Code__c = deliverySite.ER_Country_Code__c;
        upsert distributionPoint;
    }

    public class BillableServiceWrapper{
        @AuraEnabled public String productName;
        @AuraEnabled public String parentProductName;
        @AuraEnabled public String solutionName;
        @AuraEnabled public Decimal percentage;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal discountedPercentage;
        @AuraEnabled public Decimal discountedUnitPrice;
        @AuraEnabled public Decimal minValue;
        @AuraEnabled public Decimal maxValue;
        @AuraEnabled public String productId;
        @AuraEnabled public String parentProductId;
        @AuraEnabled public String solutionId;
        @AuraEnabled public String productType;
        @AuraEnabled public String parentProductType;
        @AuraEnabled public Boolean isDiscountedItem;
        @AuraEnabled public String deliveryUnit;
        @AuraEnabled public String pricebookEntryId;
        @AuraEnabled public String productBrand;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal nbOfBeneficiaries;
        @AuraEnabled public Decimal faceValue;
        @AuraEnabled public String promoDescription;
        //Adding new code
        @AuraEnabled public String helpText;
    }

    @AuraEnabled
    public static Map<String, List<Object>> fetchBillableServices(String productCode, String promoCodeId, String pricebookId, Decimal estimatedVolume, String language){
        try {
            Map<String, List<Object>> result = new Map<String, List<Object>>();
            Map<String, String> otherTranslations = new Map<String, String>();
            Map<String, BillableServiceWrapper> allProductsById = new Map<String, BillableServiceWrapper>();


            for (BE_Miscellaneous_Translation__mdt miscTranslation : [
                SELECT Label, BE_Label_Translation__c 
                FROM BE_Miscellaneous_Translation__mdt 
                WHERE BE_Language__c = :language
            ]) {
                otherTranslations.put(miscTranslation.Label, miscTranslation.BE_Label_Translation__c);  
            }

            for(PricebookEntry pbe : [Select Id, Product2.Name, Product2.ER_Solution2__r.ProductCode, ER_Percentage__c, Product2.ER_Type__c, Product2.ER_Solution2__c, product2.BU_External_Reference__c,
                                    Product2.ER_Solution__c, Product2.ER_Solution__r.Name, Product2.ER_Solution2__r.Name, product2.ER_Service_Number_of_Ranges__c,  Product2Id, Product2.ER_Solution__r.ER_Type__c,
                                    UnitPrice, ER_Min__c, ER_Max__c, ER_Promo_Code2__c, ER_Promo_Code2__r.ER_Description__c,ER_Promo_Code2__r.Description_NL__c, ER_Promo_Code2__r.Description_DE__c, ER_Promo_Code2__r.Description_EN__c, Product2.Help_Text_EN__c, Product2.Help_Text_FR__c, 
                                    Product2.Help_Text_NL__c
                                    FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2.IsActive = true AND IsActive = true ORDER BY Product2.ER_Solution2__r.ER_Line_Order__c, Product2.ER_Line_Order__c ASC]){
                
                
                BillableServiceWrapper serviceWrapper = new BillableServiceWrapper();
                serviceWrapper.productName = otherTranslations.get(pbe.Product2.Name) != null ? otherTranslations.get(pbe.Product2.Name) : pbe.Product2.Name;
                serviceWrapper.parentProductName = otherTranslations.get(pbe.Product2.ER_Solution__r.Name) != null ? otherTranslations.get(pbe.Product2.ER_Solution__r.Name) : pbe.Product2.ER_Solution__r.Name;
                serviceWrapper.solutionName = otherTranslations.get(pbe.Product2.ER_Solution2__r.Name) != null ? otherTranslations.get(pbe.Product2.ER_Solution2__r.Name) : pbe.Product2.ER_Solution2__r.Name;
                serviceWrapper.percentage = pbe.ER_Percentage__c;
                serviceWrapper.unitPrice = pbe.UnitPrice;
                serviceWrapper.minValue = pbe.ER_Min__c;
                serviceWrapper.maxValue = pbe.ER_Max__c;
                serviceWrapper.productId = pbe.Product2Id;
                serviceWrapper.parentProductId = pbe.Product2.ER_Solution__c;
                serviceWrapper.solutionId = pbe.Product2.ER_Solution2__c;
                serviceWrapper.productType = pbe.Product2.ER_Type__c;
                serviceWrapper.parentProductType = pbe.Product2.ER_Solution__r.ER_Type__c;
                serviceWrapper.isDiscountedItem = false;
                serviceWrapper.pricebookEntryId = pbe.Id;
                serviceWrapper.productCode = pbe.Product2.ER_Solution2__r.ProductCode;
                serviceWrapper.deliveryUnit = otherTranslations.get(pbe.Product2.BU_External_Reference__c) != null ? otherTranslations.get(pbe.Product2.BU_External_Reference__c) : pbe.Product2.BU_External_Reference__c;
                // NEW: Set help text based on language
                serviceWrapper.helpText = getHelpTextForLanguage(pbe.Product2, language);
                if(language == 'fr_BE'){
                    serviceWrapper.promoDescription = pbe.ER_Promo_Code2__r.ER_Description__c;
                }else if(language == 'nl_BE'){
                    serviceWrapper.promoDescription = pbe.ER_Promo_Code2__r.Description_NL__c;
                }else if(language == 'de_BE'){
                    serviceWrapper.promoDescription = pbe.ER_Promo_Code2__r.Description_DE__c;
                }else{
                    serviceWrapper.promoDescription = pbe.ER_Promo_Code2__r.Description_EN__c;
                }                        
                allProductsById.put(serviceWrapper.productId, serviceWrapper);
                        
                if(pbe.Product2.ER_Type__c == 'Range' && (pbe.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_BE || pbe.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_LU)){
                    if(result.containsKey('Delivery')){
                        result.get('Delivery').add(serviceWrapper);
                    }else{
                        result.put('Delivery', new List<Object>{serviceWrapper});
                    }
                }else if(pbe.Product2.ER_Type__c == 'Service' && pbe.Product2.ER_Service_Number_of_Ranges__c == 0 && (pbe.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_BE || pbe.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_LU)){
                    if(result.containsKey('Card')){
                        result.get('Card').add(serviceWrapper);
                    }else{
                        result.put('Card', new List<Object>{serviceWrapper});
                    }
                }else if(pbe.Product2.ER_Type__c == 'Range' && pbe.Product2.ER_Solution2__r.ProductCode == productCode && (estimatedVolume >= pbe.ER_Min__c  && estimatedVolume <= pbe.ER_Max__c)){
                    if(result.containsKey('Service')){
                        result.get('Service').add(serviceWrapper);
                    }else{
                        result.put('Service', new List<Object>{serviceWrapper});
                    }
                }else if(promoCodeId != null && pbe.Product2.ER_Type__c == 'Discount' && pbe.ER_Promo_Code2__c == promoCodeId &&
                (
                    pbe.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_BE ||
                    pbe.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_LU ||
                    (estimatedVolume >= pbe.ER_Min__c && estimatedVolume <= pbe.ER_Max__c)
                )){
                    if(result.containsKey('Discount')){
                        result.get('Discount').add(serviceWrapper);
                    }else{
                        result.put('Discount', new List<Object>{serviceWrapper});
                    }
                }
            }

            if (result.containsKey('Discount')) {
                for (Object discountObj : result.get('Discount')) {
                    BillableServiceWrapper discount = (BillableServiceWrapper) discountObj;
                    BillableServiceWrapper match = allProductsById.get(discount.parentProductId);
            
                    if (match != null) {
                        match.discountedUnitPrice = discount.unitPrice;
                        match.discountedPercentage = discount.percentage;
                        match.isDiscountedItem = true;
                    }
                }
            }

            if (result.containsKey('Service')) {
                // Step 1: Extract product codes from Service list
                Set<String> productCodes = new Set<String>();
                for (Object rangeObj : result.get('Service')) {
                    BillableServiceWrapper range = (BillableServiceWrapper) rangeObj;
                    productCodes.add(range.productCode);
                }
            
                // Step 2: Query Auto_Enrollment__mdt
                Map<String, String> enrollmentValueMap = new Map<String, String>();
                if (!productCodes.isEmpty()) {
                    for (Auto_Enrollment__mdt meta : [
                        SELECT MasterLabel, Value__c
                        FROM Auto_Enrollment__mdt
                        WHERE MasterLabel IN :productCodes
                    ]) {
                        enrollmentValueMap.put(meta.MasterLabel, meta.Value__c);
                    }
                }
            
                // Step 3: Set productBrand on Service wrappers
                for (Object rangeObj : result.get('Service')) {
                    BillableServiceWrapper range = (BillableServiceWrapper) rangeObj;
                    range.productBrand = enrollmentValueMap.containsKey(range.productCode)
                        ? enrollmentValueMap.get(range.productCode)
                        : '';
                }
            }
            
            

            return result;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, List<Object>> fetchBillableServicesFromOpp(String opportunityId, String promoCodeId, String language){
        try {
            Map<String, List<Object>> result = new Map<String, List<Object>>();
            Map<String, String> otherTranslations = new Map<String, String>();
            Map<String, BillableServiceWrapper> allProductsById = new Map<String, BillableServiceWrapper>();


            for (BE_Miscellaneous_Translation__mdt miscTranslation : [
                SELECT Label, BE_Label_Translation__c 
                FROM BE_Miscellaneous_Translation__mdt 
                WHERE BE_Language__c = :language
            ]) {
                otherTranslations.put(miscTranslation.Label, miscTranslation.BE_Label_Translation__c);  
            }

            for(OpportunityLineItem oli : [Select Id, Product2.Name, Product2.ER_Solution2__r.ProductCode, ER_Percentage__c, Product2.ER_Type__c, Product2.ER_Solution2__c, product2.BU_External_Reference__c,
                                    Product2.ER_Solution__c, Product2.ER_Solution__r.Name, Product2.ER_Solution2__r.Name, product2.ER_Service_Number_of_Ranges__c,  Product2Id, Product2.ER_Solution__r.ER_Type__c,
                                    ER_Face_Value__c, ER_Nb_Beneficiaries__c, Opportunity.ER_Promo_Code2__r.ER_Description__c,Opportunity.ER_Promo_Code2__r.Description_NL__c, Opportunity.ER_Promo_Code2__r.Description_DE__c, Opportunity.ER_Promo_Code2__r.Description_EN__c,
                                    UnitPrice, ER_Min__c, ER_Max__c, Opportunity.ER_Promo_Code2__c, Product2.Help_Text_EN__c, Product2.Help_Text_FR__c, 
                                    Product2.Help_Text_NL__c FROM OpportunityLineItem WHERE OpportunityId = :opportunityId AND Product2.IsActive = true
                                    ORDER BY Product2.ER_Solution2__r.ER_Line_Order__c, Product2.ER_Line_Order__c ASC]){
                
                
                BillableServiceWrapper serviceWrapper = new BillableServiceWrapper();
                serviceWrapper.productName = otherTranslations.get(oli.Product2.Name) != null ? otherTranslations.get(oli.Product2.Name) : oli.Product2.Name;
                serviceWrapper.parentProductName = otherTranslations.get(oli.Product2.ER_Solution__r.Name) != null ? otherTranslations.get(oli.Product2.ER_Solution__r.Name) : oli.Product2.ER_Solution__r.Name;
                serviceWrapper.solutionName = otherTranslations.get(oli.Product2.ER_Solution2__r.Name) != null ? otherTranslations.get(oli.Product2.ER_Solution2__r.Name) : oli.Product2.ER_Solution2__r.Name;
                serviceWrapper.percentage = oli.ER_Percentage__c;
                serviceWrapper.unitPrice = oli.UnitPrice;
                serviceWrapper.minValue = oli.ER_Min__c != null ? oli.ER_Min__c : Decimal.valueOf(0);
                serviceWrapper.maxValue = oli.ER_Max__c;
                serviceWrapper.productId = oli.Product2Id;
                serviceWrapper.parentProductId = oli.Product2.ER_Solution__c;
                serviceWrapper.solutionId = oli.Product2.ER_Solution2__c;
                serviceWrapper.productType = oli.Product2.ER_Type__c;
                serviceWrapper.parentProductType = oli.Product2.ER_Solution__r.ER_Type__c;
                serviceWrapper.isDiscountedItem = false;
                serviceWrapper.pricebookEntryId = oli.Id;
                serviceWrapper.productCode = oli.Product2.ER_Solution2__r.ProductCode;
                serviceWrapper.deliveryUnit = otherTranslations.get(oli.Product2.BU_External_Reference__c) != null ? otherTranslations.get(oli.Product2.BU_External_Reference__c) : oli.Product2.BU_External_Reference__c;
                serviceWrapper.nbOfBeneficiaries = oli.ER_Nb_Beneficiaries__c;
                serviceWrapper.faceValue = oli.ER_Face_Value__c;
                // NEW: Set help text based on language
                serviceWrapper.helpText = getHelpTextForLanguage(oli.Product2, language);

                if(language == 'fr_BE'){
                    serviceWrapper.promoDescription = oli.Opportunity.ER_Promo_Code2__r.ER_Description__c;
                }else if(language == 'nl_BE'){
                    serviceWrapper.promoDescription = oli.Opportunity.ER_Promo_Code2__r.Description_NL__c;
                }else if(language == 'de_BE'){
                    serviceWrapper.promoDescription = oli.Opportunity.ER_Promo_Code2__r.Description_DE__c;
                }else{
                    serviceWrapper.promoDescription = oli.Opportunity.ER_Promo_Code2__r.Description_EN__c;
                }       

                allProductsById.put(serviceWrapper.productId, serviceWrapper);
                        
                if(oli.Product2.ER_Type__c == 'Range' && (oli.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_BE || oli.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_LU)){
                    if(result.containsKey('Delivery')){
                        result.get('Delivery').add(serviceWrapper);
                    }else{
                        result.put('Delivery', new List<Object>{serviceWrapper});
                    }
                }else if(oli.Product2.ER_Type__c == 'Service' && oli.Product2.ER_Service_Number_of_Ranges__c == 0 && (oli.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_BE || oli.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_LU)){
                    if(result.containsKey('Card')){
                        result.get('Card').add(serviceWrapper);
                    }else{
                        result.put('Card', new List<Object>{serviceWrapper});
                    }
                }else if(oli.Product2.ER_Type__c == 'Range' && !(oli.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_BE || oli.Product2.ER_Solution2__r.ProductCode == Constants.ADDITIONAL_SERVICE_CODE_LU)){
                    if(result.containsKey('Service')){
                        result.get('Service').add(serviceWrapper);
                    }else{
                        result.put('Service', new List<Object>{serviceWrapper});
                    }
                }else if(promoCodeId != null && oli.Product2.ER_Type__c == 'Discount'){
                    if(result.containsKey('Discount')){
                        result.get('Discount').add(serviceWrapper);
                    }else{
                        result.put('Discount', new List<Object>{serviceWrapper});
                    }
                }
            }

            if (result.containsKey('Discount')) {
                for (Object discountObj : result.get('Discount')) {
                    BillableServiceWrapper discount = (BillableServiceWrapper) discountObj;
                    BillableServiceWrapper match = allProductsById.get(discount.parentProductId);
            
                    if (match != null) {
                        match.discountedUnitPrice = discount.unitPrice;
                        match.discountedPercentage = discount.percentage;
                        match.isDiscountedItem = true;
                    }
                }
            }

            if (result.containsKey('Service')) {
                // Step 1: Extract product codes from Service list
                Set<String> productCodes = new Set<String>();
                for (Object rangeObj : result.get('Service')) {
                    BillableServiceWrapper range = (BillableServiceWrapper) rangeObj;
                    productCodes.add(range.productCode);
                }
            
                // Step 2: Query Auto_Enrollment__mdt
                Map<String, String> enrollmentValueMap = new Map<String, String>();
                if (!productCodes.isEmpty()) {
                    for (Auto_Enrollment__mdt meta : [
                        SELECT MasterLabel, Value__c
                        FROM Auto_Enrollment__mdt
                        WHERE MasterLabel IN :productCodes
                    ]) {
                        enrollmentValueMap.put(meta.MasterLabel, meta.Value__c);
                    }
                }
            
                // Step 3: Set productBrand on Service wrappers
                for (Object rangeObj : result.get('Service')) {
                    BillableServiceWrapper range = (BillableServiceWrapper) rangeObj;
                    range.productBrand = enrollmentValueMap.containsKey(range.productCode)
                        ? enrollmentValueMap.get(range.productCode)
                        : '';
                }
            }
            
            

            return result;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> fetchPricebookAndPromoId(String productCode, String promoCode, String businessUnit) {
        try {
            Map<String, String> result = new Map<String, String>();
            Date today = Date.today();

            List<PricebookEntry> baseEntries = [
                SELECT Id, Pricebook2Id, Pricebook2.For_Autoenrollment__c 
                FROM PricebookEntry 
                WHERE Product2.ER_Solution2__r.ProductCode = :productCode
                AND Pricebook2.IsActive = true 
                AND IsActive = true 
                AND ER_BUPicklist__c = :businessUnit
                AND Pricebook2.IsStandard = false
                AND Pricebook2.For_Autoenrollment__c = true
                LIMIT 1
            ];

            if (!baseEntries.isEmpty()) {
                result.put('pricebookId', baseEntries[0].Pricebook2Id);
            }

            if (promoCode != null) {
                List<PricebookEntry> promoEntries = [
                    SELECT ER_Promo_Code2__c, Pricebook2Id 
                    FROM PricebookEntry 
                    WHERE Product2.ER_Solution2__r.ProductCode = :productCode
                    AND Pricebook2.IsActive = true 
                    AND IsActive = true 
                    AND ER_BUPicklist__c = :businessUnit 
                    AND ER_Promo_Code2__r.ER_Promo_Code__c = :promoCode
                    AND ER_Promo_Code2__r.ER_Start_Date__c <= :today
                    AND ER_Promo_Code2__r.ER_End_Date__c >= :today
                    AND Pricebook2.IsStandard = false
                    LIMIT 1
                ];

                if (!promoEntries.isEmpty()) {
                    result.put('pricebookId', promoEntries[0].Pricebook2Id);
                    result.put('promoId', promoEntries[0].ER_Promo_Code2__c);
                }
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static BE_General_Condition__c getGeneralCondition(String language, String productCode, String businessUnit){
        return [SELECT Id, BE_Body__c FROM BE_General_Condition__c WHERE BE_Language__c =: language AND BE_Active__c = true AND Business_Unit__c =: businessUnit AND Edenred_Solution__c =:productCode LIMIT 1];
    }
    
    @AuraEnabled
    public static String createServicesAndContract(String promoId, String pricebookId, String generalConditionId, 
            Decimal noOfBeneficiaries, Decimal faceValue, Decimal daysPerMonth, Decimal loadPerYear, 
            Decimal estimatedVolume, String opportunityId, String businessUnit, String productList){
        try {
            List<BillableServiceWrapper> productListJSON = (List<BillableServiceWrapper>) JSON.deserialize(productList, List<BillableServiceWrapper>.class);
            List<OpportunityLineItem> listOfOppProd = new List<OpportunityLineItem>();

            Opportunity opp = [SELECT Id, Pricebook2Id, BE_Accepted_general_conditions__c, 
                                    BE_Date_Time_accepted_general_conditions__c, BE_General_Condition__c, LeadSource, BE_Webform_Link__c
                            FROM Opportunity WHERE Id = :opportunityId];
                            
            opp.BE_Accepted_general_conditions__c = true;
            opp.BE_Date_Time_accepted_general_conditions__c = Datetime.now();
            opp.BE_General_Condition__c = generalConditionId;
            opp.Pricebook2Id = pricebookId;
            if(promoId != null){
                opp.ER_Promo_Code2__c = promoId;
            }

            update opp;

            if(opp.BE_Webform_Link__c == null){
                Decimal quantity = 1;
                System.debug('productList: ' + productListJSON);
                for(BillableServiceWrapper oli : productListJSON){
                    listOfOppProd.add(new OpportunityLineItem(Product2Id = oli.productId, OpportunityId = opp.Id, 
                    ER_Percentage__c = oli.percentage, UnitPrice = oli.unitPrice, Quantity = quantity, ER_Face_Value__c = faceValue, 
                    ER_Load_Per_Year__c = loadPerYear, ER_Days_Per_Month__c = daysPerMonth, ER_Nb_Beneficiaries__c = noOfBeneficiaries,
                    ER_BUPicklist__c = businessUnit, ER_Min__c = oli.minValue, ER_Max__c = oli.maxValue, Solution__c = oli.solutionId));
                }

                if (!listOfOppProd.isEmpty()) {
                    insert listOfOppProd;
                }
            }
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String createQuote(String opportunityId){
        try{
            Quote newQuote;
            Boolean opportunityNeedApproval = false;
            Boolean oppNeedFinancialApproval = false;
            List<opportunityLineItem> oppProductList;
            List<quoteLineItem> qliList = new List<quoteLineItem>();
            Opportunity currentOpportunity = new Opportunity();
            Map<String, Contact> roleContactMap = new Map<String, Contact>();
            QuoteLineItem qli;
            List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();


            List<Quote> recentQuote = [SELECT Id, Status  FROM Quote WHERE Status = 'Offer Presented' AND OpportunityId =: opportunityId ORDER By CreatedDate DESC];

            ocrList = [SELECT Id, ContactId, Role, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone FROM OpportunityContactRole WHERE OpportunityId = :opportunityId];

            for(OpportunityContactRole ocr : ocrList){
                roleContactMap.put(ocr.Role, ocr.Contact);
            }

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

            if(!oppProductList.isEmpty()) {

                Savepoint sp = Database.setSavepoint();
                newQuote = new Quote();
                if(!recentQuote.isEmpty()){
                    newQuote.Id = recentQuote[0].Id;
                }else{
                    newQuote.Id = null;
                }
                newQuote.ContactId = roleContactMap.get('Primary Contact').Id;
                newQuote.Email = roleContactMap.get('Primary Contact').Email;
                newQuote.Phone = roleContactMap.get('Primary Contact').Phone;
                //Commenting as it is throwing error 
                //newQuote.OwnerId = oppProductList[0].Opportunity.ownerId;
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

        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String createContract(String quoteId){
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        Map<String, Date> mapProductEndDate = new Map<String, Date>();
        List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
        Map<String, Map<String, Boolean>> solutionDiscountAppliedMap = new Map<String, Map<String, Boolean>>();
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        Map<String, Contact> roleContactMap = new Map<String, Contact>();


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
        
        ocrList = [SELECT Id, ContactId, Role, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone FROM OpportunityContactRole WHERE OpportunityId = :quote.OpportunityId];

        for(OpportunityContactRole ocr : ocrList){
            roleContactMap.put(ocr.Role, ocr.Contact);
        }

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
        newContract.Primary_Contact__c = roleContactMap.get('Primary Contact').Id;
        newContract.Billing_Contact__c = roleContactMap.get('Invoicing Contact').Id;
        newContract.Creditting__c = quote.Opportunity.Creditting__c;
        newContract.ER_BUPicklist__c = quote.Opportunity.ER_BUPicklist__c; 
        newContract.ER_Contract_Duration__c = quote.ER_Contract_Duration__c;
        newContract.ER_Solutions__c = quote.Opportunity.ER_Solutions__c;
        newContract.ERBE_Reimbursement_Statement_Frequency__c = quote.ERBE_Reimbursement_Statement_Frequency2__c;
        newContract.ERBE_Reimbursement_statement_Support__c = quote.ERBE_Reimbursement_Statement_Support2__c;
        newContract.ER_SEPA_Bank_Account__c = quote.ER_SEPA_Bank_Account__c;
        newContract.ERBE_Invoicing_day_of_week__c = quote.ER_Invoicing_day_of_week__c;
        newContract.ERBE_Invoicing_Payment_Delay__c = quote.ER_Invoicing_payment_delay__c;
        newContract.ERBE_Weekly_Frequence__c = quote.ERBE_Weekly_Frequence__c;
        newContract.CustomerSignedId = roleContactMap.get('Primary Contact').Id;
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

        return String.valueOf(newContract.Id);
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

    @AuraEnabled
    public static String submitAgreedToGeneralConditions(String contractId, Boolean agreedToGeneralConditions, Boolean prepaymentAccepted, Boolean markettingAccepted, Boolean businessAccepted, Boolean legalAccepted,
                                                         Id opportunityId, Id accountId, String stakeholderType,
                                                         String productName, String productCode,  String emailAddress, String formLanguage, Decimal estimatedVolume){

        Account acc;

        try{
            Opportunity o = [SELECT Id, Pricebook2.Name, Pricebook2.ER_Card_Operational_System_ID__c,
                                    ER_Nb_of_Employees__c, ER_Estimated_Number_Of_Beneficiaries__c 
                             FROM Opportunity WHERE Id =: opportunityId LIMIT 1];

            String nameProduct= productCode;
            if(o != null){

                updateOppo(opportunityId, agreedToGeneralConditions, prepaymentAccepted); 
                updateAccount(accountId, stakeholderType, nameProduct);
                sendContractViaEmail(contractId, accountId, emailAddress, opportunityId, stakeholderType, productName, formLanguage, productCode, estimatedVolume);

            }
            else{
                throw new AuraHandledException('Error_Message_Opportunity_not_found');
            }
        }
        catch(Exception ex) {
            System.debug('ex=' + ex.getMessage() + ' ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            return 'error';
        }

        return 'success';
    }

    private static void updateAccount(String accountId,String stakeholderType , String nameProduct){
        Account acc = [SELECT Id, ER_WS_result_Text_Long__c, BE_Client_Contract_ECE__c, BE_Client_Contract_TCE__c, BE_Client_Contract_TRE__c
                       FROM Account WHERE Id = :accountId];

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

    /**
    * Returns the appropriate help text based on language
    * Assumes you have fields: Help_Text_EN__c, Help_Text_FR__c, Help_Text_NL__c, on Product2
    */
    private static String getHelpTextForLanguage(Product2 product, String language) {
        if (product == null) return null;
        
        // Map language codes to field names
        if (language == 'en_US' || language == 'en_GB' || language == 'en_BE' || language == 'en_LU') {
            return product.Help_Text_EN__c;
        } else if (language == 'fr_BE' || language == 'fr_LU') {
            return product.Help_Text_FR__c;
        } else if (language == 'nl_BE') {
            return product.Help_Text_NL__c;
        } 
        
        // Default to English if language not matched
        return product.Help_Text_FR__c;
    }

    private static void updateOppo(String Id, Boolean agreed, Boolean prepayment){
        Opportunity o = [SELECT Id,ER_PaymentMethod__c, ER_Won_Reason__c, BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,
                StageName
        FROM Opportunity WHERE Id =: Id LIMIT 1];

        if (prepayment){ o.ER_PaymentMethod__c = o.ER_PaymentMethod__c != NULL ? o.ER_PaymentMethod__c : 'Bank transfer'; }
        update o;
    }

    public static void sendContractViaEmail(String contractId, Id accountId, String emailAddress, Id opportunityId, String stakeholderType, String productName, String pageLanguage, String productCode, Decimal estimatedVolume) {
        
        // String pgLang = (pageLanguage.toLowerCase() == 'nl_be') ? 'NL' : 'FR';
        // String local = (pgLang == 'NL') ? 'nl_BE' : 'fr_BE';

        // String pdfPageName;
        //Updated logic by harkirat to send the multiple pdf contracts

        String lang = (pageLanguage == null) ? '' : pageLanguage.toLowerCase();
 
        String pgLang =
            (lang == 'nl_be') ? 'NL' :
            (lang == 'fr_be') ? 'FR' :
            (lang == 'de_be' || lang == 'de') ? 'DE' :
            (lang == 'en_us') ? 'EN' :
            'FR';
 
        String local =
            (pgLang == 'NL') ? 'nl_BE' :
            (pgLang == 'FR') ? 'fr_BE' :
            (pgLang == 'DE') ? 'de_BE' :
            'en_US';
        String pdfPageName;

        if (pgLang == 'NL') {
            pdfPageName = 'PDF_Client_NL_AutoEnrollment';
        } else if (pgLang == 'FR') {
            pdfPageName = 'PDF_Client_FR_AutoEnrollment';
        } else if (pgLang == 'EN') {
            pdfPageName = 'PDF_Client_EN_AutoEnrollment';
        } else if (pgLang == 'DE') {
            pdfPageName = 'PDF_Client_DE_AutoEnrollment';
        } else {
            pdfPageName = 'PDF_Client_FR_AutoEnrollment';
        }

        PageReference pdf = new PageReference('/apex/' + pdfPageName);

        pdf.getParameters().put('aid', String.valueOf(accountId));
        pdf.getParameters().put('oid', String.valueOf(opportunityId));
        pdf.getParameters().put('language', pgLang);
        pdf.getParameters().put('local', local);
        pdf.getParameters().put('productCode', productCode);
        pdf.getParameters().put('productName', productName);
        pdf.getParameters().put('estimatedVolume', String.valueOf(estimatedVolume));
        pdf.getParameters().put('plang', pgLang);
		
		BE_ContractEmailGenerator.sendEmailWithECPDFAttachement(
            contractId, emailAddress, accountId, opportunityId, pdf,
            stakeholderType, productName, local
        );
    }

    @AuraEnabled
    public static Map<String, Object> fetchDataFromOpportunity(String key){
        Map<String, Object> result = new Map<String, Object>();
        System.debug('key: '+ key);
        String searchKey = '%'+key+'%';
        System.debug('searchKey: '+ searchKey);
        List<Opportunity> opportunities = [SELECT Id, AccountId, BE_Crypto_Key__c, ER_Estimated_Number_Of_Beneficiaries__c,
                                            ER_Promo_Code2__r.ER_Promo_Code__c, ER_Promo_Code2__r.ER_Description__c, ER_Promo_Code2__r.Description_NL__c, ER_Promo_Code2__r.Description_DE__c, ER_Promo_Code2__r.Description_EN__c
                                           FROM Opportunity
                                           WHERE BE_Webform_Link__c LIKE :searchKey
                                           AND RecordType.Name LIKE :Label.BE_Client_Opportunity];
        
        Opportunity opportunity;
        System.debug('opportunities: '+ opportunities);
        if(opportunities.size() == 1){
            opportunity = opportunities[0];
            List<String> keyDecrypted = Crypto.decryptWithManagedIV('AES256', EncodingUtil.base64Decode(opportunity.BE_Crypto_Key__c), EncodingUtil.base64Decode(key)).toString().split('-');
            if (!Test.isRunningTest()) {
                Id opportunityId = keyDecrypted[0];
                List<String> listDate = keyDecrypted[1].split('/');
                Date limitDate = Date.newInstance(Integer.valueOf(listDate[2]), Integer.valueOf(listDate[1]), Integer.valueOf(listDate[0]));
                if(limitDate < System.today()){
                    //throw new AuraHandledException('Opportunity outside Date Range');
                }
            }
        }else{
            throw new AuraHandledException('Opportunity not found!');
        }

        Account account = [SELECT Id, Name, ER_Legal_Form__c, BillingStreet, BillingPostalCode,
                                  BillingCity, BillingCountry, ER_Enterprise_Number__c, Phone,
                                  ER_Not_subject_to_VAT__c, ER_VAT_Number__c, NumberOfEmployees, ER_Registration_Number__c,
                                  RCS_Number__c,
                                  ER_Legal_Name__c, BE_Client_Contract_TRE__c, HU_HQ_Contact__c, BE_Social_Secretary_Name__c,
                                  BE_Client_Contract_TCE__c, BE_Client_Contract_ECE__c, ERBE_Social_secretary_needed_for_Orders__c
                           FROM Account
                           WHERE Id = :opportunity.AccountId];
        
        Contact primaryContact;
        Contact billingContact;
        Contact orderContact;
        Contact deliveryContact;

        List<OpportunityContactRole> ocrList = [
        SELECT ContactId, Role, Contact.Salutation, Contact.LastName, Contact.FirstName,
                Contact.Phone, Contact.MobilePhone, Contact.Fax, Contact.ER_Language__c, Contact.Email, Contact.Business_Role__c
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunity.Id
        ];
        
        for(OpportunityContactRole ocr : ocrList){
            if(ocr.role == 'Primary Contact'){
                primaryContact = ocr.Contact;
            }else if(ocr.role == 'Invoicing Contact'){
                billingContact = ocr.Contact;
            }else if(ocr.role == 'Order Contact'){
                orderContact = ocr.Contact;
            }else if(ocr.role == 'Delivering Contact'){
                deliveryContact = ocr.Contact;
            }
        }

        result.put('account', account);
        result.put('opportunity', opportunity);
        result.put('primaryContact', primaryContact);
        result.put('billingContact', billingContact);
        result.put('orderContact', orderContact);
        result.put('deliveryContact', deliveryContact);

        return result;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPickListValues(String objectApiName, String fieldApiName, Boolean required, String language, String businessUnit){
        Map<String, String> picklistTranslations = new Map<String, String>();
        for(BE_Picklist_Value_Translation__mdt pvt : [SELECT Label, BE_Label_Translation__c
                                                      FROM BE_Picklist_Value_Translation__mdt 
                                                      WHERE BE_Language__c = :language]){
            picklistTranslations.put(pvt.Label, pvt.BE_Label_Translation__c);
        }
		System.debug('objectApiName'+objectApiName);
        Map<String, String> pickListValues = new Map<String, String>();
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        String value, valueTranslated;
        if(!required)
            /* pickListValues.put('', ''); */
        for(Schema.PicklistEntry pickListVal : ple){
            if(pickListVal.isActive()){
                value = pickListVal.getValue();
                if(objectApiName == 'Lead' && fieldApiName == 'ER_Language__c') {
                    if(businessUnit == 'LU' && value == 'NL') {
                        continue;
                    }
                }
                valueTranslated = picklistTranslations.get(value);
                if(valueTranslated != null)
                    pickListValues.put(value, valueTranslated);
                else
                    pickListValues.put(value, value);
            }
        }

        return pickListValues;
    }

    @AuraEnabled
    public static void updateAccount(
        Id accountId,
        String vatNumber,
        Boolean subjectToVat,
        String commercialName,
        String legalName,
        String billingAddress,
        String billingPostalCode,
        String billingCity,
        String billingCountry,
        String registrationNumber
    ) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required.');
        }

        Account acc = new Account(
            Id = accountId,
            ER_VAT_Number__c = vatNumber,
            ER_Not_subject_to_VAT__c = subjectToVat,
            Name = commercialName != null ? commercialName.toUpperCase() : null,
            ER_Legal_Name__c = legalName != null ? legalName.toUpperCase() : null,
            BillingStreet = billingAddress,
            BillingPostalCode = billingPostalCode,
            BillingCity = billingCity,
            BillingCountry = billingCountry
        );
        if (String.isNotBlank(registrationNumber)) {
            acc.RCS_Number__c = registrationNumber;
        }
        update acc;
    }
}