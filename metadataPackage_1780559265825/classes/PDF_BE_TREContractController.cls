/************************************************************************
 * Description      : PDF_BE_TRE_Client_Contract_FR/NL page controller
 * @author          : Imalka Hemachandra
 * @since           : 31 July 2018
 * Copyright 2018 ABSI. All rights reserved.
 ************************************************************************/
public class PDF_BE_TREContractController {

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
    }
    public class Acceptor {
        public String Terminal_Provider { get; set; }
        public String Terminal_Model { get; set; }
        public String TID_Authorization { get; set; }
        public String Cash_Register_Provider { get; set; }
        public String Cash_Register { get; set; }
    }

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
    public Static String productAcr {get; set;}
    public Static String product_fullname {get; set;}
    public Static String local { get; set; }
    public  Map<String, String> mapSalutationLanguage { get; set; }
    public String enterpriseNumber {get; set;}
    public String accName {get; set;}
    public String legalForm {get; set;}
    public Boolean isSubjectToVAT {get; set;}
    public String relName {get; set;}
    public String billingStreet {get; set;}
    public String billingPostalCode {get; set;}
    public String billingCity {get; set;}
    public String socialSecretaryName {get; set;}
    public String socialSecretaryOrders {get; set;}
    public String shippingAddressEqualsHeadquarters {get; set;}
    public String shippingStreet {get; set;}
    public String shippingPostalCode {get; set;}
    public String shippingCity {get; set;}
    public String erCommercialName {get; set;}

    public String main_salutation {get; set;}
    public String main_lastName {get; set;}
    public String main_firstName {get; set;}
    public String main_phone {get; set;}
    public String main_mobilePhone {get; set;}
    public String main_fax {get; set;}
    public String main_language {get; set;}
    public String main_email {get; set;}

    public String refund_salutation {get; set;}
    public String refund_lastName {get; set;}
    public String refund_firstName {get; set;}
    public String refund_phone {get; set;}
    public String refund_mobilePhone {get; set;}
    public String refund_fax {get; set;}
    public String refund_language {get; set;}
    public String refund_email {get; set;}

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
    public Decimal rateZone { get; set; }
    public String cardRenewable {get; set;}

    public String promoCode {get; set;}
    public String promoDescription {get; set;}
    // Added for 2249 to campare promocode lower cases
    public String promoCodeLowerCase {get; set;}
    public String sme_Campaign_PromocodeLowerCase {get; set;}
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
    private static final String REFUND_CONTACT_ROLE = 'Refund Contact Person';
    private static final String INVOICE_CONTACT_ROLE = 'Invoicing Contact Person';
    private static final String ORDER_CONTACT_ROLE = 'Order Contact Person';
    private static final String DELIVERY_CONTACT_ROLE = 'Delivery Contact Person';
    //private static final String PRODUCT_FULLNAME = 'Electronic Ticket Restaurant';
    private static final String ENTRY_FEE = 'Entrance';
    private static final String PARTICIPATION = 'Participation';
    private static final String LICENCE = 'Licence';
    //Tree view variables
    public List<BE_NodeCategory> tree{get; set;}
    private Map<Id, BE_Category__c> categoryById;
    private Map<Id, Id> parentByChild;

    public PDF_BE_TREContractController() {
        //set current user language
        userLanguage = UserInfo.getLanguage();
        language = ApexPages.currentPage().getParameters().get('language');
        local = ApexPages.currentPage().getParameters().get('local');
        productAcr = ApexPages.currentPage().getParameters().get('productAcr');
        
        product_fullname = [SELECT Full_Name__c FROM BE_Product_Name_Mapping__mdt WHERE Name__c = :productAcr].Full_Name__c;
        // Fetch all required details using the getCompleteProductName method
        Product2 productDetails = BE_Client_WebForm_Without_Sharing_Ctrl.fetchProductDetails(productAcr);

        loadPerYear = productDetails.Load_Per_Year__c;
        daysPerYear = productDetails.Days_per_Month__c;

        System.debug('language=' + language);
        mapSalutationLanguage = BE_WebForm_Controller_Helper.getPickListValues('Contact','Salutation',false,local);
        
        sme_Campaign_PromocodeLowerCase = Label.SME_Campaign_Promocode.tolowercase();

        //get account id from page parameters
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
        //set current user language
        userLanguage = ApexPages.currentPage().getParameters().get('plang');
    }

    //Prepare pdf content
    private void preparePageContent(String accountIdString, String opportunityIdString) {
        try {
            rates = new List<Info>();
            deliveries = new List<Info>();
            acceptors = new List<Acceptor>();

            Id accountId = Id.valueOf(accountIdString);
            Id opportunityId = Id.valueOf(opportunityIdString);
            mainAccount = getAccountFields(accountId);
            contact1 = getMainContactFields(accountId);
            contact2 = getRefundContactFields(accountId);
            contact3 = getInvoiceContactFields(accountId);
            contact4 = getOrderContactFields(accountId);
            contact5 = getDeliveryContactFields(accountId);

            financialCenter = getFinancialCenter(accountId);
            setBankAccountFields(financialCenter.Id);
            getDeliveySiteFields(financialCenter.Id);

            mainOpportunity = setOpportunityProductFields(opportunityId);
            getInfosBillableService(opportunityId);
            loadStoreDetails(accountId);
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    //Get account field values
    private Account getAccountFields(Id accountId) {
        try {
            Account mainAccount = [SELECT ER_Enterprise_Number__c,ER_VAT_Number__c, Name, ER_Legal_Form__c, ER_Not_subject_to_VAT__c,
                    ER_Group_Subsidiary_relationship__r.Name, BillingStreet, BillingPostalCode,
                    BE_Social_Secretary_Name__c, BillingCity, BE_Social_Secretary_orders__c,
                    ShippingStreet, ShippingPostalCode,
                    ShippingCity, ER_Legal_Name__c
            FROM Account WHERE Id =: accountId];
            enterpriseNumber = mainAccount.ER_VAT_Number__c;
            accName = mainAccount.ER_Legal_Name__c;
            legalForm = mainAccount.ER_Legal_Form__c;
            isSubjectToVAT = !mainAccount.ER_Not_subject_to_VAT__c;
            relName = mainAccount.ER_Group_Subsidiary_relationship__r.Name;
            billingStreet = mainAccount.BillingStreet;
            billingPostalCode = mainAccount.BillingPostalCode;
            billingCity = mainAccount.BillingCity;
            //socialSecretaryName = (mainAccount.BE_Social_Secretary__c == 'Yes') ? Label.Yes : Label.No ;
            socialSecretaryOrders = (mainAccount.BE_Social_Secretary_orders__c) ? Label.Yes : Label.No ;
            //shippingAddressEqualsHeadquarters = (mainAccount.BE_Shipping_address_equals_headquarters__c) ? Label.Yes : Label.No ;
            shippingStreet = mainAccount.ShippingStreet;
            shippingPostalCode = mainAccount.ShippingPostalCode;
            shippingCity = mainAccount.ShippingCity;
            erCommercialName = mainAccount.ER_Legal_Name__c;
            return mainAccount;
        } catch(Exception ex) {
            System.debug('Error while retrieving account : ' + ex.getMessage());
        }
        return new Account();
    }

    //Get main contact fields
    private Contact getMainContactFields(Id accountId) {
        try {
            Contact mainContact = [SELECT Salutation, LastName, FirstName, Phone, MobilePhone, Fax, ER_Language__c, Email
            FROM Contact WHERE AccountId =: accountId
            AND BE_Operational_Role__c includes (:MAIN_CONTACT_ROLE) LIMIT 1];
            main_salutation = (mapSalutationLanguage !=null && mapSalutationLanguage.containsKey(mainContact.Salutation)) ? mapSalutationLanguage.get(mainContact.Salutation) :  mainContact.Salutation ;
            main_lastName = mainContact.LastName ;
            main_firstName = mainContact.FirstName ;
            main_phone = mainContact.Phone ;
            main_mobilePhone = mainContact.MobilePhone ;
            main_fax = mainContact.Fax ;
            main_language = mainContact.ER_Language__c ;
            main_email = mainContact.Email ;
            return mainContact;
        } catch(Exception ex) {
            System.debug('Error while retrieving main contact : ' + ex.getMessage());
        }
        return new Contact();
    }

    //Get refund contact fields
    private Contact getRefundContactFields(Id accountId) {
        try {
            Contact refundContact = [SELECT Salutation, LastName, FirstName, Phone, MobilePhone, Fax, ER_Language__c, Email
            FROM Contact WHERE AccountId =: accountId
            AND BE_Operational_Role__c includes (:REFUND_CONTACT_ROLE) LIMIT 1];
            refund_salutation = (mapSalutationLanguage !=null && mapSalutationLanguage.containsKey(refundContact.Salutation)) ? mapSalutationLanguage.get(refundContact.Salutation) :  refundContact.Salutation ;
            refund_lastName = refundContact.LastName ;
            refund_firstName = refundContact.FirstName ;
            refund_phone = refundContact.Phone ;
            refund_mobilePhone = refundContact.MobilePhone ;
            refund_fax = refundContact.Fax ;
            refund_language = refundContact.ER_Language__c ;
            refund_email = refundContact.Email ;
            return refundContact;
        } catch(Exception ex) {
            System.debug('Error while retrieving refundContact contact : ' + ex.getMessage());
        }
        return new Contact();
    }

    //Get invoice contact fields
    private Contact getInvoiceContactFields(Id accountId) {
        try {
            Contact invoiceContact = [SELECT Salutation, LastName, FirstName, Phone, MobilePhone, Fax, ER_Language__c, Email
            FROM Contact WHERE AccountId =: accountId
            AND BE_Operational_Role__c includes (:INVOICE_CONTACT_ROLE) LIMIT 1];
            invoice_salutation = (mapSalutationLanguage !=null && mapSalutationLanguage.containsKey(invoiceContact.Salutation)) ? mapSalutationLanguage.get(invoiceContact.Salutation) :  invoiceContact.Salutation ;
            invoice_lastName = invoiceContact.LastName ;
            invoice_firstName = invoiceContact.FirstName ;
            invoice_phone = invoiceContact.Phone ;
            invoice_mobilePhone = invoiceContact.MobilePhone ;
            invoice_language = invoiceContact.ER_Language__c ;
            invoice_email = invoiceContact.Email ;
            return invoiceContact;
        } catch(Exception ex) {
            System.debug('Error while retrieving invoiceContact contact : ' + ex.getMessage());
        }
        return new Contact();
    }

    //Get order contact fields
    private Contact getOrderContactFields(Id accountId) {
        try {
            Contact orderContact = [SELECT Salutation, LastName, FirstName, Phone, MobilePhone, Fax, ER_Language__c, Email
            FROM Contact WHERE AccountId =: accountId
            AND BE_Operational_Role__c includes (:ORDER_CONTACT_ROLE) LIMIT 1];
            order_salutation = (mapSalutationLanguage !=null && mapSalutationLanguage.containsKey(orderContact.Salutation)) ? mapSalutationLanguage.get(orderContact.Salutation) :  orderContact.Salutation ;
            order_lastName = orderContact.LastName ;
            order_firstName = orderContact.FirstName ;
            order_phone = orderContact.Phone ;
            order_mobilePhone = orderContact.MobilePhone ;
            order_language = orderContact.ER_Language__c ;
            order_email = orderContact.Email ;
            return orderContact;
        } catch(Exception ex) {
            System.debug('Error while retrieving orderContact contact : ' + ex.getMessage());
        }
        return new Contact();
    }

    //Get delivery contact fields
    private Contact getDeliveryContactFields(Id accountId) {
        try {
            Contact deliveryContact = [SELECT Salutation, LastName, FirstName, Phone, MobilePhone, Fax, ER_Language__c, Email
            FROM Contact WHERE AccountId =: accountId
            AND BE_Operational_Role__c includes (:DELIVERY_CONTACT_ROLE) LIMIT 1];
            delivery_salutation = (mapSalutationLanguage !=null && mapSalutationLanguage.containsKey(deliveryContact.Salutation)) ? mapSalutationLanguage.get(deliveryContact.Salutation) :  deliveryContact.Salutation ;
            delivery_lastName = deliveryContact.LastName ;
            delivery_firstName = deliveryContact.FirstName ;
            delivery_phone = deliveryContact.Phone ;
            delivery_mobilePhone = deliveryContact.MobilePhone ;
            delivery_language = deliveryContact.ER_Language__c ;
            delivery_email = deliveryContact.Email ;
            return deliveryContact;
        } catch(Exception ex) {
            System.debug('Error while retrieving deliveryContact contact : ' + ex.getMessage());
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
    private  ER_Delivery_Site__c getDeliveySiteFields(Id idFc){
        List<ER_Delivery_Site__c> lstDs = [SELECT ID,Name,ER_Account_Name__c,ER_Card_Operational_System_ID__c,ER_Financial_Center__c,
                ER_City__c,ER_Country__c,ER_Delivery_Contact__c,ER_Street__c,ER_Zip_Code__c
        FROM ER_Delivery_Site__c where ER_Financial_Center__c = :idFc order by CreatedDate desc];

        if(lstDs.size() >0 ){
            ER_Delivery_Site__c ds= lstDs.get(0);
            shippingCity = ds.ER_City__c;
            shippingPostalCode = ds.ER_Zip_Code__c;
            shippingStreet = ds.ER_Street__c;
            return ds;
        }
        return null;
    }


    //Get bank account fields
    private void setBankAccountFields(Id idFc) {
        try {
            List<BE_FCtoBankAccount__c> listOfFcToBa = [SELECT Id, BE_Bank_Account__c, BE_Type__c FROM BE_FCtoBankAccount__c
                                                        WHERE BE_Financial_Center__c = :idFc];
            Set<Id> bankAccountIds = new Set<Id>();
            Set<Id> invoiceBankAccountIds = new Set<Id>();
            for(BE_FCtoBankAccount__c fcToBa : listOfFcToBa){
                if(fcToBa.BE_Type__c.contains('Refund'))
                    bankAccountIds.add(fcToBa.BE_Bank_Account__c);
                if(fcToBA.BE_Type__c.contains('Invoicing'))
                    invoiceBankAccountIds.add(fcToBa.BE_Bank_Account__c);
            }

            if(bankAccountIds.size() > 0 ){
                List<ER_Bank_Account__c> lstAccBankAccount = [
                        SELECT ER_IBAN__c, ER_BIC__c
                        FROM ER_Bank_Account__c
                        WHERE Id IN :bankAccountIds
                        LIMIT 1
                ];
                if(lstAccBankAccount.size() > 0 ){
                    ER_Bank_Account__c accBankAccount = lstAccBankAccount.get(0);
                    iban = accBankAccount.ER_IBAN__c;
                    bic = accBankAccount.ER_BIC__c;
                }
            }

            if(invoiceBankAccountIds.size() > 0 ){
                List<ER_Bank_Account__c> lstAccBankAccount = [
                        SELECT ER_IBAN__c, ER_BIC__c
                        FROM ER_Bank_Account__c
                        WHERE Id IN :invoiceBankAccountIds
                        LIMIT 1
                ];
                if(lstAccBankAccount.size() > 0 ){
                    ER_Bank_Account__c accBankAccount = lstAccBankAccount.get(0);
                    ibanInvoice = accBankAccount.ER_IBAN__c;
                    bicInvoice = accBankAccount.ER_BIC__c;
                }
            }
        } catch(Exception ex) {
            System.debug('Error while retrieving bank account : ' + ex.getMessage());
        }
    }

    //Get store fields
    private void loadStoreDetails(Id accountId) {
        try {
            List<ER_Store__c> lstErStore = [SELECT Id, name, ER_Street__c, ER_Zip_Code__c,
                                   ER_City__c, ERBE_Segment__c, ERBE_Sub_Segment__c
                                   FROM ER_Store__c
                                   WHERE ER_Merchant__c =: accountId LIMIT 1];

            if(lstErStore.size() > 0 ) {
                ER_Store__c erStore = lstErStore.get(0);
                store_name = erStore.name;
                //store_franchised = (erStore.BE_Franchised__c == 'Yes') ? Label.Yes : Label.No ;
                //store_brand_of_Franchise = erStore.BE_Brand_of_Franchise__c;
                store_street = erStore.ER_Street__c;
                store_zipcode = erStore.ER_Zip_Code__c;
                store_city = erStore.ER_City__c;
                store_segmant = erStore.ERBE_Segment__c;
                store_sub_segmant = erStore.ERBE_Sub_Segment__c;

                for(ER_Acceptor__c acc : [SELECT BE_Terminal_Provider__c, ER_Acceptor_Model__c, ER_TID_Authorization__c,
                                          ER_Cash_Register_Provider__c, ER_IS_Acceptor_Linked_To_Cash_Register__c
                                          FROM ER_Acceptor__c WHERE ER_Store__c =: erStore.Id]) {
                    Acceptor acceptor = new Acceptor();
                    acceptor.Terminal_Provider = acc.BE_Terminal_Provider__c;
                    acceptor.Terminal_Model = acc.ER_Acceptor_Model__c;
                    acceptor.TID_Authorization = acc.ER_TID_Authorization__c;
                    acceptor.Cash_Register_Provider = acc.ER_Cash_Register_Provider__c;
                    acceptor.Cash_Register = acc.ER_IS_Acceptor_Linked_To_Cash_Register__c;
                    acceptors.add(acceptor);
                }

                //------------ Initiate Tree View ----------------------------------------------------------------------
                //Init the map to found the children of a categories
                initMapsCategories();
                //Call the interesting methodlanguage
                if(String.isBlank(language)) {
                    language = 'fr';
                }
                tree = initTree(erStore.Id, language);
                //------------ End of Tree View initiation -------------------------------------------------------------
            }
        } catch(Exception ex) {
            System.debug('Error while retrieving bank account : ' + ex.getMessage());
        }

    }

    //Get bank account fields
    private Opportunity setOpportunityProductFields(Id opportunityId) {
        try {
            Opportunity opp = [SELECT Id, ER_Promo_Code2__r.ER_Promo_Code__c, ER_Nb_of_Employees__c, ER_Estimated_Number_Of_Beneficiaries__c,
                ER_Face_Value__c, ER_PaymentMethod__c, BE_Date_Time_accepted_general_conditions__c,
            (SELECT Name, UnitPrice,TotalPrice, ER_Percentage__c FROM OpportunityLineItems WHERE Product2.ER_Type__c != 'Discount')
            FROM Opportunity WHERE Id =: opportunityId];
            promoCode = opp.ER_Promo_Code2__r.ER_Promo_Code__c;
            paymentMethod = opp.ER_PaymentMethod__c;

            dateAcceptedGeneralConditions = Datetime.now().format('dd/MM/yyyy');

            timeAcceptedGeneralConditions = Datetime.now().format('HH:mm');
            // not use BE_Date_Time_accepted_general_conditions__c from oppo because it's not yet updated

            if(opp.ER_Face_Value__c != null) {
                faceValue = String.valueOf(opp.ER_Face_Value__c);
            }

            if(opp.ER_Nb_of_Employees__c != null) {
                numberEmployees = Integer.valueOf(opp.ER_Nb_of_Employees__c);
            }

            if(opp.ER_Estimated_Number_Of_Beneficiaries__c != null) {
                numberBeneficiaries = Integer.valueOf(opp.ER_Estimated_Number_Of_Beneficiaries__c);
            }
            rateZone = opp.ER_Estimated_Number_Of_Beneficiaries__c*opp.ER_Face_Value__c*daysPerYear*loadPerYear;
            //rateZone *= 220;

            for(OpportunityLineItem oli : opp.OpportunityLineItems) {
                if(oli.Name.contains(ENTRY_FEE) && oli.UnitPrice != null) {
                    entryFee = String.valueOf(oli.UnitPrice);
                }

                if(oli.Name.contains(LICENCE) && oli.UnitPrice != null) {
                    licenceFee = String.valueOf(oli.UnitPrice);
                }

                if(oli.Name.contains(PARTICIPATION) && oli.ER_Percentage__c != null) {
                    participationPercent = String.valueOf(oli.ER_Percentage__c);
                }
                //client TRE
                if(oli.Name.contains('-') && oli.ER_Percentage__c != null) {
                    participationPercentClient = String.valueOf(oli.ER_Percentage__c);
                }

                if(oli.Name.contains('Account Creation') && oli.UnitPrice != null) {
                    accountCreationCost = String.valueOf(oli.UnitPrice);
                }

                if(oli.Name.contains('Card Cost') && oli.UnitPrice != null) {
                    cardCost = String.valueOf(oli.UnitPrice);
                }

                if(oli.Name.contains('Card Replacement') && oli.UnitPrice != null) {
                    cardReplacement = String.valueOf(oli.UnitPrice);
                }
                if(oli.Name.contains('Card Renewable') && oli.UnitPrice != null){
                    cardRenewable = String.valueOf(oli.UnitPrice);
                }
            }

            return opp;
        } catch(Exception ex) {
            System.debug('Error while retrieving opportunity products : ' + ex.getMessage());
            return new Opportunity();
        }
    }

    private void getInfosBillableService(Id opportunityId) {
        try {
            String languageKey = '';
            Map<String, List<Map<String, String>>> infos = new Map<String, List<Map<String, String>>>();
            Opportunity opp=  [SELECT Id,ER_Estimated_Number_Of_Beneficiaries__c,ER_Face_Value__c, ER_Promo_Code2__c, RecordTypeId, RecordType.Name,
                                ER_Promo_Code2__r.Name, ER_Promo_Code2__r.ER_Promo_Code__c, ER_Promo_Code2__r.ER_Description__c, ER_Promo_Code2__r.Description_DE__c, 
                                ER_Promo_Code2__r.Description_EN__c, ER_Promo_Code2__r.Description_NL__c, BE_Webform_Link__c
                                FROM Opportunity
                                WHERE Id = :opportunityId];

            promoCode = (opp.ER_Promo_Code2__c != null) ?  opp.ER_Promo_Code2__r.ER_Promo_Code__c : 'Standard';
            promoCodeLowerCase = promoCode.toLowerCase();
            if(promoCode != 'Standard'){
                if(ApexPages.currentPage().getParameters().get('language') =='FR'){
                    promoDescription = opp.ER_Promo_Code2__r.ER_Description__c;
                }else if(ApexPages.currentPage().getParameters().get('language') =='NL'){
                    promoDescription = opp.ER_Promo_Code2__r.Description_NL__c;
                }else if(ApexPages.currentPage().getParameters().get('language') =='EN'){
                    promoDescription = opp.ER_Promo_Code2__r.Description_EN__c;
                }
            }
            if(ApexPages.currentPage().getParameters().get('language') =='FR'){
                languageKey = 'fr_BE';
            }else if(ApexPages.currentPage().getParameters().get('language') =='NL'){
                languageKey = 'nl_BE';
            }else if(ApexPages.currentPage().getParameters().get('language') =='EN'){
                languageKey = 'en_US';
            }
            if(Label.BE_Client_Opportunity.equals(opp.RecordType.Name)){
                
                if(opp.BE_Webform_Link__c != null){
                    isOppFromWebform = true;
                    infos= BE_Client_WebForm_Controller.getOpportunityProduct(opp.Id, languageKey);
                }else{
                    isOppFromWebform = false;
                    infos= BE_Client_WebForm_Controller.getBillableServices(promoCode,product_fullname,local);
                }
                System.debug('infos: ' + infos);
                for( Map<String, String> oneRate : infos.get('Rate')){
                    Info rateObj = new Info();
                    rateObj.Name=oneRate.get('Name');
                    //rateObj.CardLoadingCost = oneRate.get('CardLoadingCost');
                    rateObj.Percentage= oneRate.get('Percentage');
                    rateObj.Price = oneRate.get('Price');
                    rateObj.Min=oneRate.get('Min');
                    rateObj.MinInt = (rateObj.Min != null) ? Decimal.valueOf(rateObj.Min) : null;
                    rateObj.Max=oneRate.get('Max');
                    rateObj.MaxInt = (rateObj.Max != null) ? Decimal.valueOf(rateObj.Max) : null;
                    if(opp.BE_Webform_Link__c != null){
                        rateObj.ParentSolution = oneRate.get('SolutionName');
                    }else{
                        rateObj.ParentSolution = oneRate.get('ParentSolution');
                    }
                    rates.add(rateObj);
                }

                for( Map<String, String> oneDelivery : infos.get('Delivery')){

                    Info rateObj = new Info();
                    if(oneDelivery != null) {
                        rateObj.Name= oneDelivery.get('Name');
                        rateObj.CardLoadingCost = oneDelivery.get('CardLoadingCost');
                        rateObj.Percentage= oneDelivery.get('Percentage');
                        rateObj.Price = oneDelivery.get('Price');
                        rateObj.Min = String.valueOf((Integer)Decimal.valueOf(oneDelivery.get('Min')));
                        if(oneDelivery.get('Max')!=null)
                            rateObj.Max = String.valueOf((Integer)Decimal.valueOf(oneDelivery.get('Max')));
                        else
                                rateObj.Max = null;
                    }

                    deliveries.add(rateObj);
                }
            }
            else{
                /*Map<String, List<Map<String, String>>> oppoProds = BE_Merchant_Webform_Controller.getOpportunityProduct(opportunityId, local);
                myOrderProducts = new List<Info>();
                Info info;
                for(Map<String, String> mapOfOppoProd : oppoProds.get('MyOrder')){
                    info = new Info();
                    info.Name = mapOfOppoProd.get('Name');
                    info.Price = mapOfOppoProd.get('Price');
                    info.Percentage = mapOfOppoProd.get('Percentage');
                    myOrderProducts.add(info);
                }*/
            }
        } catch (Exception ex) {
            System.debug('Error while retrieving rates : ' + ex.getMessage());
        }


    }
    @RemoteAction
    public static void isDutch(){
        System.debug('calling isDutch');
        language='NL';
        local='nl_BE';

    }

    //--------------- Helper methods for the Tree View -----------------------------------------------------------------
    //Init the map which stock all the categories
    //Init the map which stock a category linked to its parent.
    private void initMapsCategories(){
        categoryById = new Map<Id, BE_Category__c>();
        parentByChild = new Map<Id, Id>();
        Set<Id> categories;
        for(BE_Category__c cat : [SELECT Id, BE_Parent_Category__c, BE_Label_FR__c, BE_Label_NL__c FROM BE_Category__c]){
            categoryById.put(cat.Id, cat);
            parentByChild.put(cat.Id, cat.BE_Parent_Category__c);
        }
    }

    private List<BE_NodeCategory> initTree(Id storeId, String language){
        List<BE_NodeCategory> result = new List<BE_NodeCategory>();
        //Get the category ids linked to the store
        Set<Id> categoryIds = new Set<Id>();
        for(BE_Store_Categorization__c scat : [SELECT Id, BE_Category__c FROM BE_Store_Categorization__c WHERE BE_Store__c = :storeId AND BE_Category__r.BE_Product__c = :productAcr]){
            categoryIds.add(scat.BE_Category__c);
        }

        List<List<Id>> preTree = new List<List<Id>>();
        List<Id> currentCategories;
        Id catId;
        for(Id id : categoryIds){
            //Reset the set
            currentCategories = new List<Id>();
            //Add the first Id in the set
            currentCategories.add(id);
            //Get the parent id
            catId = parentByChild.get(id);
            //if the current id have a parent, continue to implement the set
            while(catId != null){
                currentCategories.add(catId);
                catId = parentByChild.get(catId);
            }
            preTree.add(currentCategories);
        }
        result = initNodeCategory(preTree, language);
        return result;
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
    //--------------- End of Tree View Logic -----------------------------------------------------------------
}