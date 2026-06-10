@IsTest
public class QuotePDFControllerTest {

    @testSetup
    static void setupData() {
        // Create Contact
        Contact c = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Salutation = 'Mr.',
            ER_Language__c = 'FR',
            Email = 'john@example.com'
        );
        insert c;

        // Create Account with HQ Contact
        Account acc = new Account(
            Name = 'Test Account',
            HU_HQ_Contact__c = c.Id,
            ER_BUPicklist__c = 'BE'
        );
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        // Create Quote
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        // Create Products
        Product2 prod1 = new Product2(Name = 'Main Product', ProductCode = 'SOL1', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Delivery Cost Product', ProductCode = 'BPO_BULK_3', IsActive = true);
        insert new List<Product2>{ prod1, prod2 };

        // Create Pricebook Entries
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod2.Id,
            UnitPrice = 10,
            IsActive = true
        );
        insert new List<PricebookEntry>{ pbe1, pbe2 };

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = prod1.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = prod2.Id,
            PricebookEntryId = pbe2.Id,
            Quantity = 1,
            UnitPrice = 10
        );
        insert new List<QuoteLineItem>{ qli1, qli2 };

    }

    @IsTest
    static void testControllerConstructorAndMethods() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(q);

        Test.startTest();
        QuotePDFController controller = new QuotePDFController(sc);
        controller.getHasOneOffFees();
        QuotePDFController.getLanguageForQuote(q.Id);
        QuotePDFController.getEmailTemplateBody('FR');
        QuotePDFController.getEmailTemplateBody('NL');
        QuotePDFController.getEmailTemplateBody('EN');
        Test.stopTest();
    }

    @IsTest
    static void testSendCustomEmailWithPdf() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        try{
            QuotePDFController.sendCustomEmailWithPdf(q.Id);
        }catch (Exception e){
            
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testEmptyConstructorPath() {
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(new Quote());
        QuotePDFController controller = new QuotePDFController(sc);
        controller.getHasOneOffFees();
        Test.stopTest();
    }
}