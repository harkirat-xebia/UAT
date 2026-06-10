public without sharing class GetInfoViaForm {
    private static final String KEY = '12345678901234567890123456789012'; // 32-char key (256-bit)
    private static final String IV = '1234567890123456'; // 16-char IV (128-bit)

    @AuraEnabled(cacheable=true)
    public static List<String> getContactRolePicklist() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = OpportunityContactRole.Role.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getLabel());
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static QuoteWrapper getQuoteAccountDetails(String quoteId) {
        if (String.isNotBlank(quoteId)) {
            quoteId = decryptQuoteRef(quoteId);
        }else{
            throw new AuraHandledException('Quote ID is required.');
        }
        

        Quote q = [
            SELECT Id, Name, OpportunityId, AccountId, Opportunity.Preferred_Language__c ,DS_Feedback__c,DS_Form_Submitted__c,
                Account.Name, Account.ER_Legal_Form__c, Account.ER_Registration_Number__c,
                Account.BillingStreet, Account.BillingPostalCode,
                Account.BillingCity, Account.ERBE_Joint_Commissions__c, Account.Federation__c,
                Account.Client_Type_formula__c, Account.ERBE_Has_a_Social_secretary__c,
                Account.BE_Social_Secretary_Name__c, Account.BE_Social_Secretary_orders__c,
                Account.ER_Not_subject_to_VAT__c
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];

        List<OpportunityContactRole> ocrs = (q.OpportunityId != null) ? [
            SELECT Id, Role, ContactId,
                Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone,Contact.Salutation, Contact.ER_Language__c
            FROM OpportunityContactRole
            WHERE OpportunityId = :q.OpportunityId
        ] : new List<OpportunityContactRole>();

        ER_Financial_Center__c fc = null;
        ER_Delivery_Site__c dp = null;

        if (q.AccountId != null) {
            List<ER_Financial_Center__c> fcList = [
                SELECT Id, ER_Invoicing_Street__c, ER_Invoicing_Zip_Code__c,
                    ER_Invoicing_City__c, ER_Email__c,ER_Invoicing_Country__c
                FROM ER_Financial_Center__c
                WHERE ER_Account_Name__c = :q.AccountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!fcList.isEmpty()) {
                fc = fcList[0];
            }

            List<ER_Delivery_Site__c> dpList = [
                SELECT Id, ER_Street__c, ER_Zip_Code__c, ER_City__c,ER_Country__c
                FROM ER_Delivery_Site__c
                WHERE ER_Account_Name__c = :q.AccountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!dpList.isEmpty()) {
                dp = dpList[0];
            }
        }

        return new QuoteWrapper(q, ocrs, fc, dp);
    }
    
    public static String decryptQuoteRef(String ref) {
        if (Test.isRunningTest()) {
            return ref;
        }
        
        Blob key = Blob.valueOf(KEY);
        Blob iv = Blob.valueOf(IV);
        
        String decodedUrl = EncodingUtil.urlDecode(ref, 'UTF-8');
        
        decodedUrl = decodedUrl.replace(' ', '+');
        
        Blob decoded = EncodingUtil.base64Decode(decodedUrl);
        
        Blob decrypted = Crypto.decrypt('AES256', key, iv, decoded);
        return decrypted.toString();
    }

    public class QuoteWrapper {
        @AuraEnabled public Quote quote;
        @AuraEnabled public Account account;
        @AuraEnabled public List<OpportunityContactRole> ocrList;
        @AuraEnabled public ER_Financial_Center__c financialCenter;
        @AuraEnabled public ER_Delivery_Site__c deliverySite;
        @AuraEnabled public String quoteFeedback;
        @AuraEnabled public Boolean isFormSubmitted;

        public QuoteWrapper(Quote q, List<OpportunityContactRole> ocrList, ER_Financial_Center__c fc, ER_Delivery_Site__c dp) {
            this.quote = q;
            this.account = q.Account;
            this.ocrList = ocrList;
            this.financialCenter = fc;
            this.deliverySite = dp;
            this.quoteFeedback = q.DS_Feedback__c;
            this.isFormSubmitted = q.DS_Form_Submitted__c;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getContactRolePicklists() {
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();
        
        Schema.DescribeFieldResult salutationField = Contact.Salutation.getDescribe();
        Schema.DescribeFieldResult languageField = Contact.ER_Language__c.getDescribe();
        
        List<String> salutations = new List<String>();
        List<String> languages = new List<String>();
        
        for (Schema.PicklistEntry entry : salutationField.getPicklistValues()) {
            if (entry.isActive()) salutations.add(entry.getLabel());
        }
        
        for (Schema.PicklistEntry entry : languageField.getPicklistValues()) {
            if (entry.isActive()) languages.add(entry.getLabel());
        }
        
        picklistMap.put('Salutation', salutations);
        picklistMap.put('ER_Language__c', languages);
        
        return picklistMap;
    }


    @AuraEnabled
    public static void submitClientForm(String quoteId, String ocrListJson, String financialCenterJson, String deliverySiteJson, String quoteFeedback) {
        if (String.isNotBlank(quoteId)) {
            quoteId = decryptQuoteRef(quoteId);
        }else{
            throw new AuraHandledException('Quote ID is required.');
        }

        Quote q = [
            SELECT Id, OpportunityId, AccountId, DS_Feedback__c, Account.Name, ContactId
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];

        if (String.isNotBlank(quoteFeedback)) {
            q.DS_Feedback__c = quoteFeedback;
        }
        
        if (String.isNotBlank(ocrListJson) && q.OpportunityId != null) {
            List<Object> ocrList = (List<Object>) JSON.deserializeUntyped(ocrListJson);
            List<OpportunityContactRole> ocrsToInsert = new List<OpportunityContactRole>();

            for (Object o : ocrList) {
                Map<String, Object> ocrMap = (Map<String, Object>) o;
                String email = (String) ocrMap.get('Email');
                String phone = (String) ocrMap.get('Phone');
                String firstName = (String) ocrMap.get('FirstName');
                String lastName = (String) ocrMap.get('LastName');
                String salutation = (String) ocrMap.get('Salutation');
                String lang = (String) ocrMap.get('ER_Language__c');
                String role = (String) ocrMap.get('Role');

                if (String.isBlank(email) && String.isBlank(phone) && String.isBlank(firstName) && String.isBlank(lastName)) {
                    continue;
                }

                Contact matched = null;
                if (String.isNotBlank(email) || String.isNotBlank(phone)) {
                    List<Contact> existing = [
                        SELECT Id FROM Contact WHERE Email = :email AND Phone = :phone LIMIT 1
                    ];
                    if (!existing.isEmpty()) {
                        matched = existing[0];
                    }
                }

                Contact c = matched != null ? matched : new Contact(
                    FirstName = firstName,
                    Salutation = salutation,
                    LastName = lastName,
                    Email = email,
                    Phone = phone,
                    AccountId = q.AccountId,
                    ER_Language__c = lang                    
                );
                if (matched == null) {
                    insert c;
                }

                OpportunityContactRole newOCR = new OpportunityContactRole(
                    OpportunityId = q.OpportunityId,
                    ContactId = c.Id,
                    Role = role
                );
                ocrsToInsert.add(newOCR);
            }

            if (!ocrsToInsert.isEmpty()) {
                INSERT ocrsToInsert;
            }
        }
        q.DS_Form_Submitted__c = true;
        UPDATE q;
        
        List<OpportunityContactRole> ocrs = (q.OpportunityId != null) ? [
            SELECT Id, Role, ContactId FROM OpportunityContactRole
            WHERE OpportunityId = :q.OpportunityId AND Role = 'Delivering Contact'
        ] : new List<OpportunityContactRole>();

        if (String.isNotBlank(financialCenterJson)) {
            List<ER_Financial_Center__c> existing = [
                SELECT Id FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :q.AccountId
            ];
            if (existing.isEmpty()) {
                Map<String, Object> fcMap = (Map<String, Object>) JSON.deserializeUntyped(financialCenterJson);
                ER_Financial_Center__c fc = new ER_Financial_Center__c(
                    Name = q.Account.Name,
                    ER_Contact__c = ocrs.size() > 0 ? ocrs[0].ContactId: null,
                    ER_Type__c = 'Client',
                    ER_Invoicing_Site__c = true,
                    ER_Account_Name__c = q.AccountId,
                    ER_Invoicing_Street__c = (String)fcMap.get('ER_Invoicing_Street__c'),
                    ER_Invoicing_Zip_Code__c = (String)fcMap.get('ER_Invoicing_Zip_Code__c'),
                    ER_Invoicing_City__c = (String)fcMap.get('ER_Invoicing_City__c'),
                    ER_Email__c = (String)fcMap.get('ER_Email__c'),
                    ER_Invoicing_Country__c = (String)fcMap.get('ER_Invoicing_Country__c')
                );
                insert fc;
                List<ER_Delivery_Site__c> deliverySiteToUpdate = new List<ER_Delivery_Site__c>();
                List<ER_Delivery_Site__c> existingDeliverySite = [
                    SELECT Id FROM ER_Delivery_Site__c WHERE ER_Account_Name__c = :q.AccountId
                ];
                if(!existingDeliverySite.isEmpty()){
                    for(ER_Delivery_Site__c ds : existingDeliverySite){
                        ds.ER_Financial_Center__c = fc.Id;
                        deliverySiteToUpdate.add(ds);
                    } 
                    if(!deliverySiteToUpdate.isEmpty()){
                        update deliverySiteToUpdate;
                    }
                }
            }
            
        }

        if (String.isNotBlank(deliverySiteJson)) {
            List<ER_Delivery_Site__c> existing = [
                SELECT Id FROM ER_Delivery_Site__c WHERE ER_Account_Name__c = :q.AccountId
            ];
            List<ER_Financial_Center__c> existingFinCenter = [
                SELECT Id FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :q.AccountId
            ];
            if (existing.isEmpty()) {
                Map<String, Object> dpMap = (Map<String, Object>) JSON.deserializeUntyped(deliverySiteJson);
                ER_Delivery_Site__c dp = new ER_Delivery_Site__c(
                    Name = q.Account.Name,
                    ER_Financial_Center__c = existingFinCenter[0].Id,
                    ER_Delivery_Contact__c = ocrs.size() > 0 ? ocrs[0].ContactId: null,
                    ER_Account_Name__c = q.AccountId,
                    ER_Street__c = (String)dpMap.get('ER_Street__c'),
                    ER_Zip_Code__c = (String)dpMap.get('ER_Zip_Code__c'),
                    ER_City__c = (String)dpMap.get('ER_City__c'),
                    ER_Country__c = (String)dpMap.get('ER_Country__c')
                );
                insert dp;
            }
        }

        
    }

    /*@AuraEnabled
    public static void sendFormToPrimaryContact(Id quoteId) {
        if (String.isBlank(quoteId)) {
            throw new AuraHandledException('Quote ID is required.');
        }
        
        Quote q = [
            SELECT Id, OpportunityId, Account.Name, AccountId, DS_Form_Sent__c, Opportunity.Preferred_Language__c
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        
        if (q.OpportunityId == null) {
            throw new AuraHandledException('No Opportunity linked to this Quote.');
        }
        
        OpportunityContactRole primaryOCR = [
            SELECT ContactId, Contact.Email, Contact.FirstName
            FROM OpportunityContactRole
            WHERE OpportunityId = :q.OpportunityId AND Role = 'Primary Contact'
            LIMIT 1
        ];
        
        if (primaryOCR == null || String.isBlank(primaryOCR.Contact.Email)) {
            throw new AuraHandledException('No Primary Contact with email found.');
        }
        
        String lang = q.Opportunity.Preferred_Language__c;
        String templateName = lang == 'FR' ? 'Edenred_Offer_FR_Quote_with_PDF' :
                              lang == 'NL' ? 'Edenred_Offer_NL_Quote_with_PDF' :
                              'Edenred_Offer_EN_Quote_with_PDF';
        Id templateId;
        
        if (lang == 'FR') {
            templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Client_Info_FR' LIMIT 1].Id;
        } else if (lang == 'NL') {
            templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Client_Info_NL' LIMIT 1].Id;
        } else {
            templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Client_Info_EN' LIMIT 1].Id;
        }
        
        String formLink = Label.Site_Base_URL + 'customerinfo?quoteId=' + quoteId;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(primaryOCR.ContactId);
        mail.setWhatId(q.Id);
        mail.setSaveAsActivity(false);
        mail.setBccSender(false);
                
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        q.DS_Form_Sent__c = true;
        UPDATE q;
    }*/
}