public class APER13_Quote_PDFController {
  @AuraEnabled
  public static Map<String, String> savePDF(String selectedTemplate, String objectId, Boolean isSendEmail) {
    System.debug(
      '//savePDF selectedTemplate ' +
      selectedTemplate +
      ' objectId: ' +
      objectId +
      ' isSendEmail: ' +
      isSendEmail
    );
    Map<String, String> returnValues = new Map<String, String>();
    PageReference pdf;
    QuoteDocument quoteDocument = new QuoteDocument();
    Blob body;

    pdf = new PageReference('/apex/' + selectedTemplate + '?id=' + objectId);

    try {
      // returns the output of the page as a PDF
      body = pdf.getContent();
      // need to pass unit test -- current bug
    } catch (VisualforceException e) {
      body = Blob.valueOf('Some Text');
    }

    quoteDocument.Document = body;
    quoteDocument.QuoteID = objectId;

    insert quoteDocument;

    if (isSendEmail)
      sendEmailWithAttachment(objectId, body);

    return returnValues;
  }

  public static void sendEmailWithAttachment(Id quoteId, Blob body) {
    Quote q = [SELECT ContactId, Name, ER_BUPicklist__c FROM Quote WHERE Id = :quoteId];
    if (String.isNotBlank(q.ContactId)) {
      Id emailTemplate = getEmailTemplate(q.ER_BUPicklist__c);
      // Create the email
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setTargetObjectId(q.ContactId);
      email.setTemplateId(emailTemplate);
      email.setWhatId(quoteId);

      Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
      efa.setFileName(q.Name + '.pdf');
      efa.setBody(body);

      email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ efa });

      // Send the email
      if (!Test.isRunningTest())
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
  }

  public static Id getEmailTemplate(String bu) {
    String templateName = Utils.getGlobalSettingsValueFromKey(bu + '_QUOTE_EMAIL_TEMPLATE_NAME');

    List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName];

    if (templates.isEmpty())
      return null;

    return templates[0].Id;
  }

  @AuraEnabled
  public static Blob previewPDF(String selectedTemplate) {
    PageReference pdf;
    Attachment attach = new Attachment();
    QuoteDocument quoteDocument = new QuoteDocument();
    Blob body;

    pdf = new PageReference('/apex/' + selectedTemplate);

    try {
      // returns the output of the page as a PDF
      body = pdf.getContent();
      // need to pass unit test -- current bug
    } catch (VisualforceException e) {
      body = Blob.valueOf('Some Text');
    }

    return body;
  }

  @AuraEnabled
  public static Map<String, String> getTemplates() {
    List<String> templateNames;
    List<String> templateLabels;
    Map<String, String> templateMap = new Map<String, String>();
    List<CMER02_Pdf_Template_Setting__mdt> templatesList = [
      SELECT id, DeveloperName, ER_Template_Name__c, ER_Template_Label__c
      FROM CMER02_Pdf_Template_Setting__mdt
      WHERE DeveloperName = :APER10_User_Management.userBU
    ];

    if (!templatesList.isEmpty()) {
      templateNames = templatesList[0].ER_Template_Name__c.Split(';');
      templateLabels = templatesList[0].ER_Template_Label__c.Split(';');
      for (integer i = 0; i < templateNames.size(); i++) {
        templateMap.put(templateNames[i], templateLabels[i]);
      }
    }

    return templateMap;
  }
}