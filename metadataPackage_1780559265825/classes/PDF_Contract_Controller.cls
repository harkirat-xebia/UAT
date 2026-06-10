public without sharing class PDF_Contract_Controller {
    public class Info {
        public String Name { get; set; }
        public String Percentage { get; set; }
        public String Price { get; set; }
        public String CardLoadingCost { get; set; }
        public String ParentSolution { get; set; }
        public String Min { get; set; }
        public String Max { get; set; }
        public Decimal MinInt { get; set; }
        public Decimal MaxInt { get; set; }
        public String SolutionName { get; set; }
        public String NbOfBenef { get; set; }
        public String FaceValue { get; set; }
    }
    public class Acceptor {
        public String Terminal_Provider { get; set; }
        public String Terminal_Model { get; set; }
        public String TID_Authorization { get; set; }
        public String Cash_Register_Provider { get; set; }
        public String Cash_Register { get; set; }
    }
    public String appendixHtml { get; set; }
    public Account mainAccount {get; set;}
    public Contact contact1 {get; set;}
    public Contact contact2 {get; set;}
    public Contact contact3 {get; set;}
    public Contact contact4 {get; set;}
    public Contact contact5 {get; set;}

    public Opportunity mainOpportunity {get; set;}

    public ER_Financial_Center__c financialCenter { get; set; }

    public String userLanguage {get; set;}
    public Static String language { get; set; }
    public Static String productCode {get; set;}
    public Static String productName {get; set;}
    public Static String local { get; set; }
    public  Map<String, String> mapSalutationLanguage { get; set; }
    public String enterpriseNumber {get; set;}
    public String businessUnit {get; set;}
    public String vatNumber {get; set;}
    public String accName {get; set;}
    public String legalForm {get; set;}
    public Boolean isSubjectToVAT {get; set;}
    public String relName {get; set;}
    public String billingStreet {get; set;}
    public String billingPostalCode {get; set;}
    public String billingCity {get; set;}
    public String billingCountry {get; set;}
    public String socialSecretaryName {get; set;}
    public String socialSecretaryOrders {get; set;}
    public String shippingAddressEqualsHeadquarters {get; set;}
    public String shippingStreet {get; set;}
    public String shippingPostalCode {get; set;}
    public String shippingCity {get; set;}
    public String shippingCountry {get; set;}
    public String erCommercialName {get; set;}
    public String contractStartDate {get; set;}

    public String main_salutation {get; set;}
    public String main_lastName {get; set;}
    public String main_firstName {get; set;}
    public String main_fullName {get; set;}
    public String main_phone {get; set;}
    public String main_mobilePhone {get; set;}
    public String main_fax {get; set;}
    public String main_language {get; set;}
    public String main_email {get; set;}
    public String main_businessRole {get; set;}

    public String invoice_salutation {get; set;}
    public String invoice_lastName {get; set;}
    public String invoice_firstName {get; set;}
    public String invoice_phone {get; set;}
    public String invoice_mobilePhone {get; set;}
    public String invoice_language {get; set;}
    public String invoice_email {get; set;}

    public String order_salutation {get; set;}
    public String order_lastName {get; set;}
    public String order_firstName {get; set;}
    public String order_phone {get; set;}
    public String order_mobilePhone {get; set;}
    public String order_language {get; set;}
    public String order_email {get; set;}

    public String delivery_salutation {get; set;}
    public String delivery_lastName {get; set;}
    public String delivery_firstName {get; set;}
    public String delivery_phone {get; set;}
    public String delivery_mobilePhone {get; set;}
    public String delivery_language {get; set;}
    public String delivery_email {get; set;}

    public String iban {get; set;}
    public String bic {get; set;}
    public String ibanInvoice {get; set;}
    public String bicInvoice {get; set;}

    public String entryFee {get; set;}
    public String participationPercent {get; set;}
    public String licenceFee {get; set;}
    public String faceValue {get; set;}
    public String participationPercentClient {get; set;}
    public String accountCreationCost {get; set;}
    public String cardCost {get; set;}
    public String paymentMethod {get; set;}
    public String dateAcceptedGeneralConditions {get; set;}
    public String timeAcceptedGeneralConditions {get; set;}
    public String cardReplacement {get; set;}
    public Decimal estimatedVolume { get; set; }
    public String cardRenewable {get; set;}

    public String promoCode {get; set;}
    public String promoId {get; set;}
    public String pricebookId {get; set;}
    public String promoDescription {get; set;}
    public String promoCodeLowerCase {get; set;}
    public Integer numberEmployees {get; set;}
    public Integer numberBeneficiaries {get; set;}
    public Decimal loadPerYear {get; set;}
    public Decimal daysPerYear {get; set;}
    public Boolean isOppFromWebform { get; set; }

    public List<Info> rates { get; set; }
    public List<Info> deliveries { get; set; }
    public List<Info> myOrderProducts {get; set;}
    public List<Acceptor> acceptors { get; set; }

    public String store_name { get; set; }
    public String store_franchised { get; set; }
    public String store_brand_of_Franchise { get; set; }
    public String store_street { get; set; }
    public String store_zipcode { get; set; }
    public String store_city { get; set; }
    public String store_segmant { get; set; }
    public String store_sub_segmant { get; set; }

    private static final String MAIN_CONTACT_ROLE = 'Main Contact Person';
    private static final String INVOICE_CONTACT_ROLE = 'Invoicing Contact Person';
    private static final String ORDER_CONTACT_ROLE = 'Order Contact Person';
    private static final String DELIVERY_CONTACT_ROLE = 'Delivery Contact Person';
    private static final String ENTRY_FEE = 'Entrance';
    private static final String PARTICIPATION = 'Participation';
    private static final String LICENCE = 'Licence';
    //Tree view variables
    public List<BE_NodeCategory> tree{get; set;}
    private Map<Id, BE_Category__c> categoryById;
    private Map<Id, Id> parentByChild;

    public PDF_Contract_Controller() {

        userLanguage = UserInfo.getLanguage();
        language = ApexPages.currentPage().getParameters().get('language');
        local = ApexPages.currentPage().getParameters().get('local');
        productCode = ApexPages.currentPage().getParameters().get('productCode');
        productName = ApexPages.currentPage().getParameters().get('productName');
        estimatedVolume = Decimal.valueOf(ApexPages.currentPage().getParameters().get('estimatedVolume'));

        mapSalutationLanguage = BE_WebForm_Controller_Helper.getPickListValues('Contact','Salutation',false,local);
        this.preparePageContent(ApexPages.currentPage().getParameters().get('aid'), ApexPages.currentPage().getParameters().get('oid'));

        if(String.isBlank(entryFee)) {
            entryFee = '0.0';
        }
        if(String.isBlank(participationPercent)) {
            participationPercent = '0.0%';
        }
        if(String.isBlank(licenceFee)) {
            licenceFee = '0.0';
        }

        userLanguage = ApexPages.currentPage().getParameters().get('plang');
    }
    private void preparePageContent(String accountIdString, String opportunityIdString) {
        try {
            rates = new List<Info>();
            deliveries = new List<Info>();
            acceptors = new List<Acceptor>();

            Id accountId = Id.valueOf(accountIdString);
            Id opportunityId = Id.valueOf(opportunityIdString);
            mainAccount = getAccountFields(accountId);
            contact1 = getMainContactFields(opportunityId);
            contact3 = getInvoiceContactFields(opportunityId);
            contact4 = getOrderContactFields(opportunityId);
            contact5 = getDeliveryContactFields(opportunityId);

            financialCenter = getFinancialCenter(accountId);
            getDeliveySiteFields(financialCenter.Id);

            mainOpportunity = setOpportunityProductFields(opportunityId);
            getInfosBillableService(opportunityId);
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    //Get account field values
    private Account getAccountFields(Id accountId) {
        try {
            Account mainAccount = [SELECT ER_Enterprise_Number__c,ER_VAT_Number__c, Name, ER_Legal_Form__c, ER_Not_subject_to_VAT__c, ER_BUPicklist__c,
                    ER_Group_Subsidiary_relationship__r.Name, BillingStreet, BillingPostalCode,
                    BE_Social_Secretary_Name__c, BillingCity, BE_Social_Secretary_orders__c, BillingCountry,
                    ShippingStreet, ShippingPostalCode, Parent.Name, ER_Registration_Number__c,
                    ShippingCity, ER_Legal_Name__c, ShippingCountry
            FROM Account WHERE Id =: accountId];
            enterpriseNumber = mainAccount.ER_Registration_Number__c == null ? mainAccount.ER_Enterprise_Number__c : mainAccount.ER_Registration_Number__c;
            businessUnit = mainAccount.ER_BUPicklist__c;
            String pdfLang = ApexPages.currentPage().getParameters().get('language');
            if (businessUnit != 'BE') {
                if(pdfLang == 'FR'){
                    appendixHtml = getResourceHtml('Appendix1_Lux_HTML_FR');
                }else if(pdfLang == 'DE'){
                    appendixHtml = getResourceHtml('Appendix1_Lux_HTML_DE');
                }else{
                    appendixHtml = getResourceHtml('Appendix1_Lux_HTML');
                }
            }else{
                if(pdfLang == 'FR'){
                    appendixHtml = getResourceHtml('Appendix1_BE_HTML_FR');
                }else if(pdfLang == 'NL'){
                    appendixHtml = getResourceHtml('Appendix1_BE_HTML_NL');
                }else{
                    appendixHtml = getResourceHtml('Appendix1_BE_HTML');
                }
            }
            vatNumber = mainAccount.ER_VAT_Number__c;
            accName = mainAccount.ER_Legal_Name__c;
            legalForm = mainAccount.ER_Legal_Form__c;
            isSubjectToVAT = !mainAccount.ER_Not_subject_to_VAT__c;
            relName = mainAccount.Parent.Name;
            billingStreet = mainAccount.BillingStreet;
            billingPostalCode = mainAccount.BillingPostalCode;
            billingCity = mainAccount.BillingCity;
            billingCountry = mainAccount.BillingCountry;
            socialSecretaryOrders = (mainAccount.BE_Social_Secretary_orders__c) ? Label.Yes : Label.No ;
            shippingStreet = mainAccount.ShippingStreet;
            shippingPostalCode = mainAccount.ShippingPostalCode;
            shippingCity = mainAccount.ShippingCity;
            shippingCountry = mainAccount.ShippingCountry;
            erCommercialName = mainAccount.ER_Legal_Name__c;
            return mainAccount;
        } catch(Exception ex) {
            System.debug('Error while retrieving account : ' + ex.getMessage());
        }
        return new Account();
    }

    //Get main contact fields
    private Contact getMainContactFields(Id opportunityId) {
        try {
            List<OpportunityContactRole> ocrList = [
                SELECT ContactId, Role, Contact.Salutation, Contact.LastName, Contact.FirstName,
                       Contact.Phone, Contact.MobilePhone, Contact.Fax, Contact.ER_Language__c, Contact.Email, Contact.Business_Role__c, Contact.Title
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                AND Role = 'Primary Contact'
                LIMIT 1
            ];
    
            if (!ocrList.isEmpty() && ocrList[0].Contact != null) {
                Contact mainContact = ocrList[0].Contact;
    
                main_salutation = (mapSalutationLanguage != null && mapSalutationLanguage.containsKey(mainContact.Salutation)) 
                    ? mapSalutationLanguage.get(mainContact.Salutation) 
                    : mainContact.Salutation;
    
                main_lastName = mainContact.LastName;
                main_firstName = mainContact.FirstName;
                main_fullName = main_firstName + ' ' + main_lastName;
                main_phone =  mainContact.Phone.contains('undefined') ? '' : mainContact.Phone;
                main_mobilePhone = mainContact.MobilePhone.contains('undefined') ? '' : mainContact.MobilePhone;
                main_fax = mainContact.Fax;
                main_language = mainContact.ER_Language__c;
                main_email = mainContact.Email;
                main_businessRole = mainContact.Title;
    
                return mainContact;
            }
        } catch(Exception ex) {
            System.debug('Error while retrieving main contact: ' + ex.getMessage());
        }
        return new Contact();
    }
    
    private Contact getInvoiceContactFields(Id opportunityId) {
        try {
            OpportunityContactRole ocr = [
                SELECT ContactId, Role, Contact.Salutation, Contact.LastName, Contact.FirstName,
                       Contact.Phone, Contact.MobilePhone, Contact.Fax, Contact.ER_Language__c, Contact.Email
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                AND Role = 'Invoicing Contact'
                LIMIT 1
            ];
    
            if (ocr.Contact != null) {
                Contact invoiceContact = ocr.Contact;
                invoice_salutation = (mapSalutationLanguage != null && mapSalutationLanguage.containsKey(invoiceContact.Salutation)) 
                    ? mapSalutationLanguage.get(invoiceContact.Salutation) 
                    : invoiceContact.Salutation;
                invoice_lastName = invoiceContact.LastName;
                invoice_firstName = invoiceContact.FirstName;
                invoice_phone = invoiceContact.Phone.contains('undefined') ? '' : invoiceContact.Phone;
                invoice_mobilePhone = invoiceContact.MobilePhone.contains('undefined') ? '' : invoiceContact.MobilePhone;
                invoice_language = invoiceContact.ER_Language__c;
                invoice_email = invoiceContact.Email;
    
                return invoiceContact;
            }
        } catch (Exception ex) {
            System.debug('Error while retrieving invoice contact: ' + ex.getMessage());
        }
        return new Contact();
    }

    private Contact getOrderContactFields(Id opportunityId) {
        try {
            OpportunityContactRole ocr = [
                SELECT ContactId, Role, Contact.Salutation, Contact.LastName, Contact.FirstName,
                       Contact.Phone, Contact.MobilePhone, Contact.Fax, Contact.ER_Language__c, Contact.Email
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                AND Role = 'Order Contact'
                LIMIT 1
            ];
    
            if (ocr.Contact != null) {
                Contact orderContact = ocr.Contact;
                order_salutation = (mapSalutationLanguage != null && mapSalutationLanguage.containsKey(orderContact.Salutation)) 
                    ? mapSalutationLanguage.get(orderContact.Salutation) 
                    : orderContact.Salutation;
                order_lastName = orderContact.LastName;
                order_firstName = orderContact.FirstName;
                order_phone =  orderContact.Phone.contains('undefined') ? '' : orderContact.Phone;
                order_mobilePhone = orderContact.MobilePhone.contains('undefined') ? '' : orderContact.MobilePhone;
                order_language = orderContact.ER_Language__c;
                order_email = orderContact.Email;
    
                return orderContact;
            }
        } catch (Exception ex) {
            System.debug('Error while retrieving order contact: ' + ex.getMessage());
        }
        return new Contact();
    }

    private Contact getDeliveryContactFields(Id opportunityId) {
        try {
            OpportunityContactRole ocr = [
                SELECT ContactId, Role, Contact.Salutation, Contact.LastName, Contact.FirstName,
                       Contact.Phone, Contact.MobilePhone, Contact.Fax, Contact.ER_Language__c, Contact.Email
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                AND Role = 'Delivering Contact'
                LIMIT 1
            ];
    
            if (ocr.Contact != null) {
                Contact deliveryContact = ocr.Contact;
                delivery_salutation = (mapSalutationLanguage != null && mapSalutationLanguage.containsKey(deliveryContact.Salutation)) 
                    ? mapSalutationLanguage.get(deliveryContact.Salutation) 
                    : deliveryContact.Salutation;
                delivery_lastName = deliveryContact.LastName;
                delivery_firstName = deliveryContact.FirstName;
                delivery_phone =  deliveryContact.Phone.contains('undefined') ? '' : deliveryContact.Phone;
                delivery_mobilePhone = deliveryContact.MobilePhone.contains('undefined') ? '' : deliveryContact.MobilePhone;
                delivery_language = deliveryContact.ER_Language__c;
                delivery_email = deliveryContact.Email;
    
                return deliveryContact;
            }
        } catch (Exception ex) {
            System.debug('Error while retrieving delivery contact: ' + ex.getMessage());
        }
        return new Contact();
    }

    private ER_Financial_Center__c getFinancialCenter(Id accountId){
        List<ER_Financial_Center__c> lstFc = [
                SELECT ID,Name,ER_Account_Name__c,ER_Bank_Account__c,
                        ER_Card_Operational_System_ID__c,ER_City__c,ER_Contact__c
                        ,ER_Country__c,ER_Creation_date_in_OS__c,ER_Paper_Operational_System_ID__c,ER_Street__c,ER_Zip_Code__c
                FROM ER_Financial_Center__c
                WHERE ER_Account_Name__c=:accountId
                order by CreatedDate desc
        ];
        return lstFc[0];

    }
    private ER_Delivery_Site__c getDeliveySiteFields(Id idFc){
        
        System.debug('Delivery Site Start: ' + idFc);

        List<ER_Delivery_Site__c> lstDs = [SELECT ID,Name,ER_Account_Name__c,ER_Card_Operational_System_ID__c,ER_Financial_Center__c,
                ER_City__c,ER_Country__c,ER_Delivery_Contact__c,ER_Street__c,ER_Zip_Code__c
        FROM ER_Delivery_Site__c where ER_Financial_Center__c = :idFc order by CreatedDate desc];

        if(lstDs.size() >0 ){
            ER_Delivery_Site__c ds= lstDs.get(0);
            shippingCity = ds.ER_City__c;
            shippingPostalCode = ds.ER_Zip_Code__c;
            shippingStreet = ds.ER_Street__c;
            System.debug('Delivery Site If: ' + idFc);
            return ds;
        }
        System.debug('Delivery Site End: ' + idFc);
        return null;
    }

    private Opportunity setOpportunityProductFields(Id opportunityId) {
        try {
            System.debug('Fetching Opportunity with Id: ' + opportunityId);
            Opportunity opp = [SELECT Id, ER_Promo_Code2__r.ER_Promo_Code__c, ER_Nb_of_Employees__c, ER_Estimated_Number_Of_Beneficiaries__c,
                ER_Face_Value__c, ER_PaymentMethod__c, BE_Date_Time_accepted_general_conditions__c,
                (SELECT Name, UnitPrice, TotalPrice, ER_Percentage__c 
                 FROM OpportunityLineItems 
                 WHERE Product2.ER_Type__c != 'Discount')
                FROM Opportunity WHERE Id = :opportunityId];
    
            System.debug('Opportunity retrieved: ' + opp);
            promoCode = opp.ER_Promo_Code2__r.ER_Promo_Code__c;
            paymentMethod = opp.ER_PaymentMethod__c;
            dateAcceptedGeneralConditions = Datetime.now().format('dd/MM/yyyy');
            timeAcceptedGeneralConditions = Datetime.now().format('HH:mm');
            numberBeneficiaries = Integer.valueOf(opp.ER_Estimated_Number_Of_Beneficiaries__c);
            numberEmployees = Integer.valueOf(opp.ER_Nb_of_Employees__c);
    
            for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                System.debug('Processing OLI: ' + oli.Name + ' | UnitPrice: ' + oli.UnitPrice + ' | ER_Percentage__c: ' + oli.ER_Percentage__c);
    
                if (oli.Name.contains(ENTRY_FEE) && oli.UnitPrice != null) {
                    entryFee = String.valueOf(oli.UnitPrice);
                    System.debug('ENTRY_FEE found: ' + entryFee);
                }
    
                if (oli.Name.contains(LICENCE) && oli.UnitPrice != null) {
                    licenceFee = String.valueOf(oli.UnitPrice);
                    System.debug('LICENCE found: ' + licenceFee);
                }
    
                if (oli.Name.contains(PARTICIPATION) && oli.ER_Percentage__c != null) {
                    participationPercent = String.valueOf(oli.ER_Percentage__c);
                    System.debug('PARTICIPATION found: ' + participationPercent);
                }
    
                if (oli.Name.contains('Account Creation') && oli.UnitPrice != null) {
                    accountCreationCost = String.valueOf(oli.UnitPrice);
                    System.debug('Account Creation Cost: ' + accountCreationCost);
                }
    
                if (oli.Name.contains('Card Cost') && oli.UnitPrice != null) {
                    cardCost = String.valueOf(oli.UnitPrice);
                    System.debug('Card Cost: ' + cardCost);
                }
    
                if (oli.Name.contains('Card Replacement') && oli.UnitPrice != null) {
                    cardReplacement = String.valueOf(oli.UnitPrice);
                    System.debug('Card Replacement: ' + cardReplacement);
                }
    
                if (oli.Name.contains('Card Renewable') && oli.UnitPrice != null) {
                    cardRenewable = String.valueOf(oli.UnitPrice);
                    System.debug('Card Renewable: ' + cardRenewable);
                }
            }
    
            return opp;
        } catch (Exception ex) {
            System.debug('❌ Error while retrieving opportunity products: ' + ex.getMessage());
            return new Opportunity();
        }
    }

    private void getInfosBillableService(Id opportunityId) {
        try {
            System.debug('Fetching Opportunity data for Id: ' + opportunityId);
            String languageKey = '';
            Map<String, Object> infos = new Map<String, Object>();
    
            Opportunity opp = [
                SELECT Id, ER_Promo_Code2__c, RecordTypeId, RecordType.Name, ER_Contract_Expected_Start_Date__c,
                       ER_Promo_Code2__r.ER_Promo_Code__c, ER_Promo_Code2__r.ER_Description__c,
                       ER_Promo_Code2__r.Description_EN__c, ER_Promo_Code2__r.Description_NL__c,
                       BE_Webform_Link__c, Pricebook2Id
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
    
            System.debug('Opportunity retrieved: ' + opp);
            promoId = opp.ER_Promo_Code2__c;
            pricebookId = opp.Pricebook2Id;
            promoCode = (promoId != null) ? opp.ER_Promo_Code2__r.ER_Promo_Code__c : 'Standard';
            promoCodeLowerCase = promoCode.toLowerCase();
            Date d = opp.ER_Contract_Expected_Start_Date__c;
            String contractStartDate;

            if (d != null) {
                String day   = String.valueOf(d.day()).leftPad(2, '0');
                String month = String.valueOf(d.month()).leftPad(2, '0');
                String year  = String.valueOf(d.year());

                contractStartDate = day + '/' + month + '/' + year;
            }
    
            String langParam = ApexPages.currentPage().getParameters().get('language');
            System.debug('Language parameter from page: ' + langParam);
    
            if (langParam == 'FR') {
                languageKey = 'fr_BE';
                promoDescription = opp.ER_Promo_Code2__r.ER_Description__c;
            } else if (langParam == 'NL') {
                languageKey = 'nl_BE';
                promoDescription = opp.ER_Promo_Code2__r.Description_NL__c;
            } else if (langParam == 'EN') {
                languageKey = 'en_US';
                promoDescription = opp.ER_Promo_Code2__r.Description_EN__c;
            }
    
            System.debug('Language key: ' + languageKey + ', Promo Description: ' + promoDescription);
    
            if (Label.BE_Client_Opportunity.equals(opp.RecordType.Name)) {
                if (opp.BE_Webform_Link__c != null) {
                    isOppFromWebform = true;
                    System.debug('Opportunity not from Webform. Calling Apex service...');
                    String rawJson = JSON.serialize(clientAutoEnrollmentComponentController.fetchBillableServicesFromOpp(
                        opportunityId, promoId, languageKey
                    ));
                    System.debug('Raw JSON from fetchBillableServices: ' + rawJson);
                    infos = (Map<String, Object>) JSON.deserializeUntyped(rawJson);
                } else {
                    isOppFromWebform = false;
                    System.debug('Opportunity not from Webform. Calling Apex service...');
                    String rawJson = JSON.serialize(clientAutoEnrollmentComponentController.fetchBillableServicesFromOpp(
                        opportunityId, promoId, languageKey
                    ));
                    /* String rawJson = JSON.serialize(clientAutoEnrollmentComponentController.fetchBillableServices(
                        productCode, promoId, pricebookId, estimatedVolume, languageKey
                    )); */
                    System.debug('Raw JSON from fetchBillableServices: ' + rawJson);
                    infos = (Map<String, Object>) JSON.deserializeUntyped(rawJson);
                }
    
                if (infos.containsKey('Service')) {
                    List<Object> serviceList = (List<Object>) infos.get('Service');
                    System.debug('Parsing Service list of size: ' + serviceList.size());
    
                    for (Object obj : serviceList) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        Info rateObj = new Info();
                        rateObj.Name = (String) item.get('productName');
                        rateObj.Percentage = String.valueOf(item.get('percentage'));
                        rateObj.Price = String.valueOf(item.get('unitPrice'));
                        rateObj.Min = item.get('minValue') != null ? String.valueOf(item.get('minValue')) : null;
                        rateObj.MinInt = (Decimal) item.get('minValue');
                        rateObj.Max = item.get('maxValue') != null ? String.valueOf(item.get('maxValue')) : null;
                        rateObj.MaxInt = (Decimal) item.get('maxValue');
                        rateObj.ParentSolution = String.valueOf(item.get('parentProductName'));
                        rateObj.SolutionName = String.valueOf(item.get('solutionName'));
                        rateObj.NbOfBenef = String.valueOf(item.get('nbOfBeneficiaries'));
                        rateObj.FaceValue = String.valueOf(item.get('faceValue'));

                        System.debug('Parsed Service rate: ' + rateObj);
                        rates.add(rateObj);
                    }
                }
    
                if (infos.containsKey('Delivery')) {
                    List<Object> deliveryList = (List<Object>) infos.get('Delivery');
                    System.debug('Parsing Delivery list of size: ' + deliveryList.size());
    
                    for (Object obj : deliveryList) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        Info deliveryObj = new Info();
                        deliveryObj.Name = (String) item.get('productName');
                        if (deliveryObj.Name != null && deliveryObj.Name.contains('cards')) {
                            if (langParam == 'FR') {
                                deliveryObj.Name = deliveryObj.Name.replace('cards', 'cartes');
                            } else if (langParam == 'NL') {
                                deliveryObj.Name = deliveryObj.Name.replace('cards', 'kaarten');
                            } else if (langParam == 'DE') {
                                deliveryObj.Name = deliveryObj.Name.replace('cards', 'karten');
                            }
                        }
                        deliveryObj.CardLoadingCost = (String) item.get('deliveryUnit');
                        deliveryObj.Percentage = String.valueOf(item.get('percentage'));
                        deliveryObj.Price = String.valueOf(item.get('unitPrice'));
                        deliveryObj.Min = item.get('minValue') != null ? String.valueOf(((Decimal)item.get('minValue')).intValue()) : null;
                        deliveryObj.Max = item.get('maxValue') != null ? String.valueOf(((Decimal)item.get('maxValue')).intValue()) : null;
                        System.debug('Parsed Delivery rate: ' + deliveryObj);
                        deliveries.add(deliveryObj);
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('❌ Error while retrieving billable service info: ' + ex.getMessage());
        }
    }
    
    
    @RemoteAction
    public static void isDutch(){
        System.debug('calling isDutch');
        language='NL';
        local='nl_BE';

    }
    private void initMapsCategories(){
        categoryById = new Map<Id, BE_Category__c>();
        parentByChild = new Map<Id, Id>();
        Set<Id> categories;
        for(BE_Category__c cat : [SELECT Id, BE_Parent_Category__c, BE_Label_FR__c, BE_Label_NL__c FROM BE_Category__c]){
            categoryById.put(cat.Id, cat);
            parentByChild.put(cat.Id, cat.BE_Parent_Category__c);
        }
    }

    //First run, add all in the list
    private List<BE_NodeCategory> initNodeCategory(List<List<Id>> preTree, String language){
        List<BE_NodeCategory> result = new List<BE_NodeCategory>();

        List<BE_NodeCategory> ncList;
        BE_NodeCategory nc, precNC;
        String name, index;
        Boolean isFound;
        for(List<Id> l : preTree){
            isFound = false;
            for(Id id : l){
                ncList = new List<BE_NodeCategory>();
                if(nc != null)
                    ncList.add(nc);
                name = language == 'fr' ? categoryById.get(id).BE_Label_FR__c : categoryById.get(id).BE_Label_NL__c;
                nc = new BE_NodeCategory(name, ncList);
                if(precNC != null){
                    for(BE_NodeCategory ncX : result)
                        if(ncX.addInNode(name, precNC)){
                            isFound = true;
                            break;
                        }
                }
                if(isFound){
                    break;
                }
                precNC = nc;
            }
            if(!isFound)
                result.add(nc);
            isFound = false;
            nc = null;
        }
        return result;
    }

    private String existInNodeCategory(String name, List<BE_NodeCategory> ncList, Integer index){
        if(ncList == null)
            return null;
        else{
            BE_NodeCategory nc;
            for(Integer i = 0; i < ncList.size(); ++i){
                nc = ncList[i];
                if(nc.name.equals(name))
                    return index+':'+i;
                else
                        return existInNodeCategory(name, nc.children, index+1);
            }
            return null;
        }
    }

    private String getResourceHtml(String name) {
        StaticResource res = [
            SELECT Body FROM StaticResource WHERE Name = :name LIMIT 1
        ];
        return res.Body.toString();
    }
}