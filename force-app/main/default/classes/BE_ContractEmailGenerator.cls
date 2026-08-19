/**********************************************************************************************
 * Description      : Generate PDF contracts relevant to the products and send them via emails
 * @author          : Imalka Hemachandra
 * @since           : 10 July 2018
 * Copyright 2018 ABSI. All rights reserved.
 *********************************************************************************************/
public without sharing class BE_ContractEmailGenerator {
    public static final String MERCHANT_STAKEHOLDER = 'Merchant';
    public static final String CUSTOMER_STAKEHOLDER = 'Customer';
    public static final String PRODUCT_CVE = 'CVE';	// AAM-16/08/2021: PBI#11381
    public static final String PRODUCT_ECE = 'ECE';
    public static final String PRODUCT_TCE = 'TCE';
    public static final String PRODUCT_TRE = 'TRE';
    public static final String PRODUCT_CVE_DETAIL = 'Electronic Cheque Consommation'; 	// AAM-16/08/2021: PBI#11381
    public static final String PRODUCT_ECE_DETAIL = 'Electronic Cheque ECO';
    public static final String PRODUCT_TCE_DETAIL = 'Electronic Ticket Compliment';
    public static final String PRODUCT_TRE_DETAIL = 'Electronic Ticket Restaurant';

    public static void sendEmailWithECPDFAttachement(String contractId, String emailAddress, Id accountId, Id opportunityId, PageReference pdf,String stakeholderType,String product_fullname, String language, String businessUnit) {
        try {
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            pdf.getParameters().put('aid',(String)accountId);
            pdf.getParameters().put('oid',(String)opportunityId);

            //Prepare email body content using the email template
            EmailTemplate et;
            String normalizedLang = language != null ? language.toUpperCase() : '';
            if (normalizedLang.startsWith('LU_')) {
                normalizedLang = normalizedLang.substring(3);
            }
            Boolean isLU = businessUnit == 'LU';
            if (stakeholderType.equals(BE_ContractEmailGenerator.CUSTOMER_STAKEHOLDER)) {
                if (isLU) {
                    et = (normalizedLang == 'EN')
                        ? [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Client_LU_EN']
                        : [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Client_LU_FR'];
                } else if (normalizedLang == 'NL' || normalizedLang == 'NL_BE') {
                    et = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Client_NL'];
                } else if (normalizedLang == 'EN') {
                    et = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Client_EN'];
                } else {
                    et = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Client_FR'];
                }
            } else if (stakeholderType.equals(BE_ContractEmailGenerator.MERCHANT_STAKEHOLDER)) {
                if (isLU) {
                    et = (normalizedLang == 'EN')
                        ? [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Merchant_LU_EN']
                        : [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Merchant_LU_FR'];
                } else if (normalizedLang == 'NL' || normalizedLang == 'NL_BE') {
                    et = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Merchant_NL'];
                } else if (normalizedLang == 'EN') {
                    et = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Merchant_EN'];
                } else {
                    et = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Webform_Contract_Merchant_FR'];
                }
            }

            if(et != null) {
                String subject = et.Subject;
                String htmlBody = (et.HtmlValue!=null) ? et.HtmlValue : '';
                String plainBody = (et.Body !=null) ? et.Body : '' ;
                subject = subject.replace('{Product}', product_fullname);
                htmlBody = htmlBody.replace('{Product}', product_fullname);
                plainBody = plainBody.replace('{Product}', product_fullname);

                // Sets the paramaters of the email
                email.setSubject(subject);
                email.setHtmlBody(htmlBody);
                email.setPlainTextBody(plainBody);

                String[] toAddresses = emailAddress.split(':', 0);
                email.setToAddresses( toAddresses );

                OrgWideEmailAddress[] owea = [select Id, Address from OrgWideEmailAddress where DisplayName = 'Edenred']; 
                if ( owea.size() > 0 ) {
                    email.setOrgWideEmailAddressId(owea.get(0).Id);
                }

                // Create the email attachment
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName('Edenred contract.pdf'); //TODO: replace with custom labels
                // Take the PDF content
                Blob b;
                if(Test.isRunningTest()) {
                    b = blob.valueOf('Unit.Test');
                } else {
                    //Fix internal salesforce.com Error (temporary error from Salesforce issues #3819)
                    b = pdf.getContent();
                }
                //Fix internal salesforce.com Error (temporary error from Salesforce issues #3819)
                efa.setBody(b);

                //Added for PBI-578 by Killian Degryse
                //Fix internal salesforce.com Error (temporary error from Salesforce issues #3819)
                BE_Util.addAttachmentOnSObject(b, contractId, 'Edenred contract.pdf');

                //Fix internal salesforce.com Error (temporary error from Salesforce issues #3819)
                email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                // Sends the email
                //Fix internal salesforce.com Error (temporary error from Salesforce issues #3819)
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                System.debug('######## Messaging.SendEmailResult : ' + r);
            }
        } catch(Exception ex) {
            System.debug('Error while sending email : ' + ex.getMessage());
        }
    }
}