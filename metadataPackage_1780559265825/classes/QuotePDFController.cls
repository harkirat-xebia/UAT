public with sharing class QuotePDFController {
    public List<QuoteLineItem> quoteLineItems { get; set; }
    public List<QLIGroup> groupedQLIs { get; set; }
    public List<QuoteLineItem> deliveryCostQLIs { get; set; }
    public Quote currentQuote { get; set; }
    public String toName { get; set; }

    public class QLIGroup {
        public String groupName { get; set; }
        public List<QuoteLineItem> items { get; set; }

        public QLIGroup(String groupName) {
            this.groupName = groupName;
            this.items = new List<QuoteLineItem>();
        }
    }

    public QuotePDFController(ApexPages.StandardController controller) {
        Id quoteId = controller.getId();
        quoteLineItems = new List<QuoteLineItem>();
        toName = 'Madam/Sir';
        groupedQLIs = new List<QLIGroup>();
        deliveryCostQLIs = new List<QuoteLineItem>();

        if (quoteId != null) {
            currentQuote = fetchQuote(quoteId);
            if (String.isNotBlank(currentQuote.Account.HU_HQ_Contact__r.Name)) {
                String salutation = currentQuote.Account.HU_HQ_Contact__r.Salutation;
                String translatedSalutation = salutation;
                
                if (currentQuote.Account.HU_HQ_Contact__r.ER_Language__c == 'FR') {
                    if (salutation == 'Mr.') {
                        translatedSalutation = 'Cher';
                    } else if (salutation == 'Ms.' || salutation == 'Mrs.') {
                        translatedSalutation = 'Chère';
                    }
                }else if (currentQuote.Account.HU_HQ_Contact__r.ER_Language__c == 'NL') {
                    if (salutation == 'Mr.') {
                        translatedSalutation = 'heer';
                    } else if (salutation == 'Ms.' || salutation == 'Mrs.') {
                        translatedSalutation = 'mevrouw';
                    }
                }
                
                toName = translatedSalutation + ' ' + currentQuote.Account.HU_HQ_Contact__r.Name;
            }


            quoteLineItems = [
                SELECT Id, Nb_of_Beneficiaries__c, Face_Value__c, ER_Solution__c,
                       ER_Line_Type__c, Service_Docusign__c, Percentage__c,
                       Product2.Name, Product2.ProductCode, Total_Amount__c
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId AND product2.ER_type__c != 'Discount' AND Product2.Name != 'Individual Delivery Cost'
                ORDER BY product2.ER_Line_Order__c ASC
            ];

            Map<String, QLIGroup> tempMap = new Map<String, QLIGroup>();
            for (QuoteLineItem qli : quoteLineItems) {
                if (qli.Product2.ProductCode == 'BPO_BULK_3' || qli.Product2.ProductCode == 'POST_3' || qli.Product2.ProductCode == 'MPM_BULK_3') {
                    deliveryCostQLIs.add(qli);
                    continue;
                }

                String key = qli.ER_Solution__c != null ? qli.ER_Solution__c : 'Uncategorized';
                if (!tempMap.containsKey(key)) {
                    tempMap.put(key, new QLIGroup(key));
                }
                tempMap.get(key).items.add(qli);
            }

            groupedQLIs.addAll(tempMap.values());
        }
    }

    private static Quote fetchQuote(Id quoteId) {
        return [
            SELECT Id, OwnerId, Account.Owner.Name, Account.HU_HQ_Contact__r.Email,
                   Account.HU_HQ_Contact__r.Salutation, Account.HU_HQ_Contact__r.Name,
                   Account.HU_HQ_Contact__r.ER_Language__c, Status, Opportunity.Owner.Email
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
    }

    public Boolean getHasOneOffFees() {
        Boolean hasDeliveryCosts = deliveryCostQLIs != null && !deliveryCostQLIs.isEmpty();
        Boolean hasAdditionalServices = false;

        if (groupedQLIs != null) {
            for (QLIGroup groupRec : groupedQLIs) {
                if (groupRec.groupName == 'Additional Services' && groupRec.items != null && !groupRec.items.isEmpty()) {
                    hasAdditionalServices = true;
                    break;
                }
            }
        }

        return hasDeliveryCosts || hasAdditionalServices;
    }

    @AuraEnabled(cacheable=true)
    public static String getLanguageForQuote(Id quoteId) {
        return [
            SELECT Account.HU_HQ_Contact__r.ER_Language__c FROM Quote WHERE Id = :quoteId LIMIT 1
        ].Account.HU_HQ_Contact__r.ER_Language__c;
    }

    @AuraEnabled(cacheable=true)
    public static String getEmailTemplateBody(String languageCode) {
        String templateName = languageCode == 'FR' ? 'Edenred_Offer_FR_Quote_with_PDF' :
                              languageCode == 'NL' ? 'Edenred_Offer_NL_Quote_with_PDF' :
                              'Edenred_Offer_EN_Quote_with_PDF';

        EmailTemplate template = [
            SELECT Body FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1
        ];

        return template.Body;
    }

    @AuraEnabled
    public static void sendCustomEmailWithPdf(Id quoteId) {
        Quote rec = fetchQuote(quoteId);
        
        PageReference pdfPage = 
        rec.Account.HU_HQ_Contact__r.ER_Language__c == 'FR' ? Page.MMSalesFRForm :
        rec.Account.HU_HQ_Contact__r.ER_Language__c == 'NL' ? Page.MMSalesNLForm :
        Page.MMSalesENForm;
        
        pdfPage.getParameters().put('id', quoteId);
        
        Blob pdfBlob;
        try {
            pdfBlob = pdfPage.getContentAsPDF();
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
        }
        
        String fileName = 'OfferProposal_' + quoteId + '.pdf';
        
        ContentVersion version = new ContentVersion();
        version.Title = fileName;
        version.PathOnClient = fileName;
        version.VersionData = pdfBlob;
        version.Origin = 'H';
        insert version;
        
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId;
        
        Boolean alreadyLinked = [
            SELECT COUNT() 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :contentDocumentId 
            AND LinkedEntityId = :quoteId
        ] > 0;
        
        if (!alreadyLinked) {
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = contentDocumentId;
            link.LinkedEntityId = quoteId;
            link.ShareType = 'V';
            link.Visibility = 'AllUsers';
            insert link;
        }
        
        /*Quote rec = fetchQuote(quoteId);
        System.debug('at here to download');
        
        PageReference pdfPage = 
        rec.Account.HU_HQ_Contact__r.ER_Language__c == 'FR' ? Page.MMSalesFRForm :
        rec.Account.HU_HQ_Contact__r.ER_Language__c == 'NL' ? Page.MMSalesNLForm :
        Page.MMSalesENForm;
        
        pdfPage.getParameters().put('id', quoteId);
        Blob pdfBlob;
        
        try {
        pdfBlob = pdfPage.getContentAsPDF();
        } catch (Exception e) {
        throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
        }
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('OfferProposal.pdf');
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(rec.Account.HU_HQ_Contact__r.Id);
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSaveAsActivity(true);
        email.setBccAddresses(new String[] { rec.Opportunity.Owner.Email });
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
        ContentVersion version = new ContentVersion();
        version.Title = 'Quote_' + rec.Id + '_Document';
        version.PathOnClient = 'QuoteDocument.pdf';
        version.VersionData = pdfBlob;
        insert version;
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = [
        SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id
        ].ContentDocumentId;
        link.LinkedEntityId = rec.Id;
        link.ShareType = 'V';
        link.Visibility = 'AllUsers';
        insert link;
        
        rec.Status = 'Offer presented';
        update rec;*/
    }
}