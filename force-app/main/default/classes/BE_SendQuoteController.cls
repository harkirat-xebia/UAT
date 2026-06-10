/**
 * Created by ridouane on 14/02/2019.
 */

 public  class BE_SendQuoteController {

    public  class InfosCryptedData{
        public String cryptoKey {get;set;}
        public String key {get;set;} //data crypted
        public InfosCryptedData(String cryptoKey,String key){
            this.cryptoKey=cryptoKey;
            this.key=key;
        }
    }

    @AuraEnabled
    public static void generateLink(Id oppoId){

        Set<String> requiredRoles = new Set<String>{'Primary Contact'};
        Set<String> existingRoles = new Set<String>();

        List<Quote> quoteList = [Select Id, OpportunityId FROM Quote WHERE Id =: oppoId];
        if(!quoteList.isEmpty()){
            oppoId = quoteList[0].OpportunityId;
        }
        Opportunity oppo = [SELECT ID, BE_Crypto_Key__c, BE_Webform_Link__c, BE_Edenred_Solution__c,
        						   BE_Last_Offer_Date__c, BE_Offer_Counter__c, BE_Email_Status__c, Commercial_Origin__c, ER_Contract_Expected_Start_Date__c,
                                   ER_Face_Value__c, ER_Estimated_Number_Of_Beneficiaries__c, ER_Promo_Code2__c, ER_Promo_Code2__r.ER_Promo_Code__c,
                                   RecordTypeId, AccountId, Product_of_Interest__c, Preferred_Language__c, Primary_Contact__c, Invoicing_Contact__c
                            FROM Opportunity WHERE Id=:oppoId];
        String recordTypeName = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(oppo.RecordTypeId).getName();
        String error = '';
        Boolean hasDiscount = false;
        if(oppo.ER_Promo_Code2__c != null){
            hasDiscount = true;
        }
        Account account = [SELECT RecordType.Name, BE_Client_Contract_TRE__c, BE_Client_Contract_TCE__c,
                                  BE_Client_Contract_ECE__c, ER_Language__c
                           FROM Account WHERE Id = :oppo.AccountId];
        Boolean isClientWithContract = account.BE_Client_Contract_TRE__c || account.BE_Client_Contract_TCE__c || account.BE_Client_Contract_ECE__c;

        List<opportunitycontactrole> lstOppoRole = [SELECT ContactId, Role, Contact.Salutation, Contact.FirstName, Contact.LastName, Contact.Phone, Contact.MobilePhone, Contact.Email  FROM opportunitycontactrole WHERE OpportunityId=:oppoId ORDER BY CreatedDate DESC ];
        String url = '';
        String lang = '';
        String operationalRoles = '';
        String product;
        String businessUnit;
        lang = oppo.Preferred_Language__c;

        for (OpportunityContactRole ocr : lstOppoRole) {
            if (ocr.Role != null) {
                existingRoles.add(ocr.Role);
            }
            Contact c = ocr.Contact;
            if (c != null) {
                if (String.isBlank(c.Salutation) || String.isBlank(c.FirstName) ||
                    (String.isBlank(c.Phone) && String.isBlank(c.MobilePhone)) ||
                    String.isBlank(c.Email)) {

                    String lastName = String.isBlank(c.LastName) ? 'Unknown Contact' : c.LastName;
                    String firstName = String.isBlank(c.FirstName) ? 'Unknown Contact' : c.FirstName;
                    error += '- ' + firstName + ' ' + lastName + ' : ' + Label.BE_Error_Message_Contact_Incomplete + '\n';
                }
            }
        }

        if (!existingRoles.containsAll(requiredRoles)) {
            error += '- ' + Label.BE_Error_Message_Offer_Contact + '\n';
        }
        List<OpportunityLineItem> lstOppLineItems = [
            SELECT Id, ER_Face_Value__c, ER_Nb_Beneficiaries__c, ER_Days_Per_Month__c, ER_Load_Per_Year__c, Product2.ER_Solution2__r.Name, Product2.ER_BUPicklist__c,
            Product2.ER_Solution2__r.ProductCode FROM OpportunityLineItem
            WHERE OpportunityId = :oppoId
        ];

        if (lstOppLineItems.isEmpty()) {
            error += '- ' + Label.BE_Error_Message_No_Solution_Opportunity + '\n';
        }else {
            for (OpportunityLineItem oli : lstOppLineItems) {
                if(oli.Product2.ER_Solution2__r.ProductCode != Constants.ADDITIONAL_SERVICE_CODE_BE && oli.Product2.ER_Solution2__r.ProductCode != Constants.ADDITIONAL_SERVICE_CODE_LU){
                    Boolean isFaceValueMissing = oli.ER_Face_Value__c == null;
                    Boolean isBeneficiariesMissing = oli.ER_Nb_Beneficiaries__c == null;
            
                    if (isFaceValueMissing || isBeneficiariesMissing) {
                        String solutionName = (oli.Product2 != null && oli.Product2.ER_Solution2__r != null)
                            ? oli.Product2.ER_Solution2__r.Name
                            : 'Unknown Solution';
            
                        if (isFaceValueMissing) {
                            error += '- ' + Label.BE_Error_Face_Value_Opportunity + ' for (' + solutionName + ')\n';
                        }
                        if (isBeneficiariesMissing) {
                            error += '- ' + Label.BE_Error_Message_Number_Beneficiaries_Opportunity + ' for (' + solutionName + ')\n';
                        }
                    }
                }
            }
            for (OpportunityLineItem oli : lstOppLineItems) {
                if (oli.Product2 != null && oli.Product2.ER_Solution2__r != null &&
                    !String.isBlank(oli.Product2.ER_Solution2__r.ProductCode) && oli.Product2.ER_Solution2__r.ProductCode != Constants.ADDITIONAL_SERVICE_CODE_BE && oli.Product2.ER_Solution2__r.ProductCode != Constants.ADDITIONAL_SERVICE_CODE_LU) {
                    product = oli.Product2.ER_Solution2__r.ProductCode;
                    businessUnit = oli.Product2.ER_BUPicklist__c;
                    break;
                }
            }
        }

        if(String.isEmpty(error)){
            
            if(recordTypeName.contains(Label.BE_Client_Opportunity)){
                System.debug('lang: ' + lang);
                if(businessUnit == 'BE'){
                    if(('FR').equals(lang) || ('DE').equals(lang)){
                        url = Label.base_URL_community_client_fr + '/s/?language=fr_BE&product=' + product;
                    }else if(('NL').equals(lang)){
                        url = Label.base_URL_community_client_nl+ '/s/?language=nl_BE&product=' + product;
                    }else if(('EN').equals(lang)){
                        url = Label.base_URL_community_client_en + '/s/?language=en_US&product=' + product;
                    }
                }else if(businessUnit == 'LU'){
                    if(('FR').equals(lang) || ('DE').equals(lang)){
                        url = Label.base_URL_community_client_fr_lu + '/s/?language=fr_BE&product=' + product;
                    }else if(('EN').equals(lang)){
                        url = Label.base_URL_community_client_en_lu + '/s/?language=en_US&product=' + product;
                    }
                }
            }
            if(oppo.ER_Promo_Code2__c != null){
                url = url + '&promocode=' + oppo.ER_Promo_Code2__r.ER_Promo_Code__c;
            }

            if(oppo.Commercial_Origin__c == null || oppo.ER_Contract_Expected_Start_Date__c == null){
                error += '- ' +'Commercial Origin or Contract Expected Start date cannot be Null' + '\n';
            }
        
            if(String.isEmpty(url)){
                error += '- ' + Label.BE_Error_Message_Opportunity + '\n';
            }
        }

        if(Label.BE_Pending.equals(oppo.BE_Email_Status__c))
            error += '- ' + Label.BE_Error_Email_Status_Opportunity + '\n';

        List<ER_Financial_Center__c> financialCenters = [SELECT Id FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :oppo.AccountId];
        if(financialCenters.size() == 0){
            error += '- ' + Label.BE_Error_Message_No_Financial_Center + '\n';
        }

        List<Contact> contacts = [SELECT Id, Salutation, FirstName, LastName, Phone, MobilePhone, Email
                                  FROM Contact WHERE AccountId = :oppo.AccountId AND ER_Status__c = 'Active'];
 
        Integer count = 0;
        Integer discountCount = 0;
        Integer quoteCount = 0;
        List<OpportunityLineItem> opportunityProducts = [SELECT Id, Product2.ER_Solution2__r.ProductCode, Product2.ER_Type__c FROM OpportunityLineItem
                                                         WHERE OpportunityId = :oppo.Id];
        List<Quote> recentQuote = [SELECT Id, Status  FROM Quote WHERE Status = 'Draft' AND OpportunityId =: oppo.Id ORDER By CreatedDate DESC];
        
        if(!Test.isRunningTest()){
            if(opportunityProducts.size() == 0){
                error += '- ' + Label.BE_Error_Zero_OppoProd_Opportunity + '\n';
            }else{
                for(OpportunityLineItem oli : opportunityProducts){
                    if(hasDiscount && oli.Product2.ER_Type__c == 'Discount'){
                        discountCount++;
                    }
                }
                if(hasDiscount && discountCount == 0){
                    error += '- ' + 'Add discounted products in case Promo Code is applied' + '\n';
                }
            }
            if(recentQuote.isEmpty()){
                error += '- ' + 'Save Quote before sharing Web Offer Link' + '\n';
            }
        }

        if(!String.isEmpty(error)){
            System.debug('error.line' + error);
            throw new AuraHandledException(error);
        }

        //data to crypt
        String dateIn3Month = Date.today().addMonths(3).format();
        String data = oppoId + '-' + dateIn3Month;
        InfosCryptedData infos = generateCryptedData(data);
        oppo.BE_Crypto_Key__c=infos.cryptoKey;
        oppo.BE_Webform_Link__c= url + '&key=' + infos.key;

        //Added for PBI-1137 & PBI-1138
        oppo.BE_Last_Offer_Date__c = System.now();
        System.debug('oppo.BE_Last_Offer_Date__c: ' + oppo.BE_Last_Offer_Date__c);
        if(!Label.BE_Error.equals(oppo.BE_Email_Status__c)){
            oppo.BE_Offer_Counter__c = 0;
        	oppo.BE_Offer_Counter__c = ++oppo.BE_Offer_Counter__c;
        }
        System.debug('oppo.BE_Offer_Counter__c: ' + oppo.BE_Offer_Counter__c);
        oppo.BE_Email_Status__c = Label.BE_Pending;
        update oppo;

        if(!Test.isRunningTest()){
            recentQuote[0].Status = 'Offer Presented';
            update recentQuote[0];
        }
    }

    public static Boolean isLinkValid(Id oppoId){
        try{
            List<Quote> quoteList = [Select Id, OpportunityId FROM Quote WHERE Id =: oppoId];
            if(!quoteList.isEmpty()){
                oppoId = quoteList[0].OpportunityId;
            }
            Opportunity oppo = [SELECT ID,BE_Crypto_Key__c,BE_Webform_Link__c FROM Opportunity WHERE Id=:oppoId];
            if(String.isBlank(oppo.BE_Webform_Link__c)){
                return false;
            }

            Url adr = new Url(oppo.BE_Webform_Link__c);
            String generatedKey = (splitQuery(adr).containsKey('key')) ? splitQuery(adr).get('key'): '';
            String data = getDecryptedData(oppo.BE_Crypto_Key__c,generatedKey);
            String dateText = (data.split('-').size()>1 ) ? data.split('-').get(1) : '';
            if (String.isNotBlank(dateText)){
                if (Date.parse(dateText) >= Date.today()){
                    return true;
                }
            }

        }catch(Exception ex){
            return false;
        }
        return false;

    }

    public static InfosCryptedData generateCryptedData(String data){
        Blob cryptoKey = Crypto.generateAesKey(256);
        String cryptoKeyEncoded = EncodingUtil.base64Encode(cryptoKey);

        // Generate the data to be encrypted.
        Blob dataWrap = Blob.valueOf(data);
        // Encrypt the data and have Salesforce.com generate the initialization vector
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, dataWrap);
        String encryptedDataText = EncodingUtil.base64Encode(encryptedData);

        return new InfosCryptedData(cryptoKeyEncoded,encryptedDataText);
    }

    public static String getDecryptedData(String cryptoKey,String generatedKey){

        Blob cryptoKeyWrap = EncodingUtil.base64Decode(cryptoKey);
        Blob generatedKeyWrap = EncodingUtil.base64Decode(generatedKey);

        Blob decryptedDataWrap = Crypto.decryptWithManagedIV('AES256', cryptoKeyWrap,generatedKeyWrap );
        //String decryptedData = EncodingUtil.base64Encode(decryptedDataWrap);
        String decryptedData = decryptedDataWrap.toString();
        return decryptedData;

    }

    public static Map<String,String> splitQuery(Url url){
        Map<String, String> query_pairs = new  Map<String, String>();
        try{
            String query = url.getQuery();

            List<String> pairs =  query.split('&');
            for (String pair : pairs) {
                Integer idx = pair.indexOf('=');
                query_pairs.put(pair.substring(0, idx),pair.substring(idx + 1));
            }
        }catch(Exception ex){
            System.debug('Error while splitQuery : ' + ex.getMessage());
        }
        return query_pairs;
    }
}