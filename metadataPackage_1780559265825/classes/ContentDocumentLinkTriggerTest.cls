@isTest
public class ContentDocumentLinkTriggerTest {
    
    @testSetup static void setup() {
        Id rtId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, 'ER_Company_Account_RT');
        Account newAccount = new Account( Name = 'Account' + Datetime.now().getTime(),
                                         RecordTypeId = rtId,
                                         ER_Match_Legal_Address__c = true,
                                         ER_VAT_Number__c = '00000001-1-01');
        insert newAccount;
        
        Id contRecordId = Utils.getRecordTypeIdByDeveloperName(Contact.SObjectType, 'ER_Contact_RT');
        Contact newCon = new Contact(
            FirstName = 'FirstName' + Datetime.now().getTime(),
            LastName = 'LastName' + Datetime.now().getTime(),
            RecordTypeId = contRecordId,
            Email = 'Firstname' + Datetime.now().getTime() + '@mailinator.com.test',
            AccountId = newAccount.Id
        );
        insert newCon;
        
        Id oppRecordId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, 'ER_Client_Opportunity_RT');
        Opportunity newOpportunity = new Opportunity(
            Name = 'Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            ER_BUPicklist__c = 'BE',
            AccountId = newAccount.Id,
            RecordTypeId = oppRecordId    
        );
        insert newOpportunity;
        
        Quote newQuote = new Quote(
            Name = 'Quote',
            OpportunityId = newOpportunity.Id
        );
        insert newQuote;
    }
    
    @isTest
    static void testTriggerForQuoteDocumentLink() {
       Quote newQuote = [Select id from Quote Limit 1];
       Opportunity newOpportunity = [Select id from Opportunity Limit 1];
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Document',
            VersionData = Blob.valueOf('Data'),
            PathOnClient = 'newDocument.pdf'
        );
        insert contentVersion;
        ContentVersion insertedContentVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
        ];
        
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Id = :insertedContentVersion.ContentDocumentId];
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
       
        ContentDocumentLink contentDocLink = new ContentDocumentLink(
            LinkedEntityId = newQuote.Id,
            ContentDocumentId = contentDocument.Id,
            ShareType = 'I',
            Visibility = 'InternalUsers'
        );
        cdlList.add(contentDocLink);
        insert cdlList; 
 
        List<ContentDocumentLink> oppDocumentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility 
                                                      FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId = :newOpportunity.Id];
        
         ContentDocumentLink contentDocLinkObj = new ContentDocumentLink(
            Id = cdlList[0].Id,
            ShareType = 'V'        
        );
        update contentDocLinkObj;
        delete contentDocLinkObj;
    }
    
}