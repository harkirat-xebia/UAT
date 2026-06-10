@IsTest
public class APER30_PDFContractControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingPostalCode = '12345',
            BillingCity = 'Test City',
            BillingCountry = 'Belgium',
            ER_BUPicklist__c = 'BE',
            ER_Country_Code__c = 'BE',
            ER_Legal_Name__c = 'Test Legal Name',
            ER_Legal_Form__c = 'LLC',
            ER_Registration_Number__c = '1234567890',
            ER_VAT_Number__c = 'US123456789',
            HU_HQ_Contact__c = null, // Assuming no related Contact yet
            Phone = '123-456-7890',
            ER_Other_Fiscal_ID__c = 'FID123'
        );
        insert acc;

        // Create Contact linked to the Account
        Contact cnt = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Salutation = 'Mr.',
            MobilePhone = '987-654-3210',
            Phone = '123-456-7890',
            Email = 'johndoe@example.com',
            ER_Language__c = 'EN',
            AccountId = acc.Id
        );
        insert cnt;

        // Update Account with Contact reference
        acc.HU_HQ_Contact__c = cnt.Id;
        update acc;

        // Create Opportunity and Quote related to the Account
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            AccountId = acc.Id
        );
        insert opp;

        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert quote;

        // Create Quote Line Item
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            Quantity = 1
        );
        insert qli;
    }
    
    @IsTest
    static void testAPER30_PDFContractController() {
        // Set parameters for the controller
        Test.startTest();
        ApexPages.currentPage().getParameters().put('accId', [SELECT Id FROM Account LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('lang', 'EN');
        ApexPages.currentPage().getParameters().put('oppId', [SELECT Id FROM Opportunity LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('scope', 'TestScope');
        ApexPages.currentPage().getParameters().put('solutionCode', 'TestSolutionCode');
        
        // Instantiate the controller
        APER30_PDFContractController controller = new APER30_PDFContractController();
        Test.stopTest();
    }
}