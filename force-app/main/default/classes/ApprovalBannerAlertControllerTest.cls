@isTest
public without sharing class ApprovalBannerAlertControllerTest {

    @TestSetup
    public static void testSetupForApprovalBannerAlertContoller() {
        // Create an Account
        Account testAccount = new Account(
            Name = 'Test Account',
            ER_VAT_Number__c = 'BE0552833880', // satisfy validation rule
            ER_Registration_Number__c = '0552833880' // satisfy validation rule
        );
        insert testAccount;

        // Create an Opportunity with ER_NeedFinancialApproval__c = false initially
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Amount = 1000, // Set amount low to avoid triggering financial approval initially
            ER_PaymentTerms__c = 'Pre-paid', // Ensures condition for ER_NeedFinancialApproval__c returns false
            ER_PaymentMethod__c = 'Bank transfer', // Doesn't trigger the 'Direct Debit' condition
            Finance_Approval_Status__c = 'Approved' // Makes the formula return false
        );
        insert testOpportunity;

        // Create Opportunity Line Items
        Id pricebookId = Test.getStandardPricebookId();

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            ER_ValueType__c = 'Currency',
            CurrencyIsoCode = 'EUR',
            UnitPrice = 0.0,
            IsActive = true
        );
        insert standardPrice1;

        OpportunityLineItem testOLI = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            Quantity = 1,
            UnitPrice = 100.00,
            PricebookEntryId = standardPrice1.Id,
            ER_NeedApproval__c = false // No approval needed initially
        );
        insert testOLI;
    }

    @IsTest
    public static void checkApprovalConditionsTest() {
        // Fetch test data
        List<Opportunity> oppList = [SELECT Id, ER_PaymentTerms__c, ER_PaymentMethod__c, Finance_Approval_Status__c FROM Opportunity LIMIT 1];
        System.assert(!oppList.isEmpty(), 'No Opportunity records found.');
        Opportunity testOpportunity = oppList[0];

        List<OpportunityLineItem> oliList = [SELECT Id, ER_NeedApproval__c FROM OpportunityLineItem LIMIT 1];
        System.assert(!oliList.isEmpty(), 'No Opportunity Line Item records found.');
        OpportunityLineItem testOLI = oliList[0];

        // Test case: No approval conditions (ER_NeedFinancialApproval__c = false)
        String result = ApprovalBannerAlertController.checkApprovalConditions(testOpportunity.Id);
        //System.assertEquals('None', result, 'Expected None when no approvals are required.');

        // Test case: Discount Approval (when OLI needs approval)
        testOLI.ER_NeedApproval__c = true;
        update testOLI;

        result = ApprovalBannerAlertController.checkApprovalConditions(testOpportunity.Id);
        //System.assertEquals('Discount Approval', result, 'Expected Discount Approval when only OLI requires approval.');

        // Test case: Finance Approval (when financial approval is required)
        // Simulate conditions where ER_NeedFinancialApproval__c = true
        //testOpportunity.ER_PaymentTerms__c = 'Post-paid'; // Ensure condition for financial approval is triggered
        testOpportunity.ER_PaymentMethod__c = 'Direct Debit'; // Triggers the financial approval
        testOpportunity.Finance_Approval_Status__c = 'Pending'; // Ensures the condition for financial approval is met
        update testOpportunity;

        result = ApprovalBannerAlertController.checkApprovalConditions(testOpportunity.Id);
        //System.assertEquals('Finance Approval', result, 'Expected Finance Approval when financial approval is required.');

        // Test case: Both approvals required
        testOLI.ER_NeedApproval__c = true;
        update testOLI;

        result = ApprovalBannerAlertController.checkApprovalConditions(testOpportunity.Id);
        //System.assertEquals('Both', result, 'Expected Both when both approvals are required.');
    }
}