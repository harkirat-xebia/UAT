@isTest
public with sharing class clientAutoEnrollmentControllerTest {

    static Id accountClientRecordTypeId     = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();
    static Id opportunityClientRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
                                              .get(Label.BE_Client_Opportunity).getRecordTypeId();
    static Id contactClientRecordTypeId     = Schema.SObjectType.Contact.getRecordTypeInfosByName()
                                              .get(Label.BE_Client_Contact_RT).getRecordTypeId();

    static String productCode  = 'TRE';
    static String productName  = 'Edenred Meal';
    static String businessUnit = 'BE';
    static String language     = 'fr_BE';

    @testSetup
    static void dataSetup() {

        User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'PL');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_Bypass_Flows__c = true;
        runningUser.ER_bypassTrigger__c = true;

        System.runAs(runningUser) {
            BE_TEST_Helper.insertPriceBook();

            Account acct = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);
            acct.ER_Registration_Number__c = '0123456789';
            update acct;

            Opportunity opp = new Opportunity(Name = 'Test-' + productName + '-' + 'ABSI 1', StageName = 'Qualification',
                                            CloseDate = System.today(), ER_BUPicklist__c = 'BE', ER_Contract_Expected_Start_Date__c = Date.today(), Commercial_Origin__c = 'Greenfield',
                                            AccountId = acct.Id, RecordTypeId = opportunityClientRecordTypeId);
            insert opp;
            opp.BE_Webform_Link__c = 'testURL&key=xyz';
            update opp;
            
            Pricebook2 pb2 = [SELECT Id FROM Pricebook2 WHERE Name = 'BE TRE - Standard' LIMIT 1];
            opp.Pricebook2Id = pb2.Id;
            update opp;
            
            Product2 prod = [SELECT Id, ProductCode FROM Product2 WHERE Name = 'Card Delivery 1 - 3' LIMIT 1];
            BE_TEST_Helper.createOLI(opp, pb2, prod, prod.Id, 25, null);

            Contact primary    = BE_TEST_Helper.createContact(acct.Id, contactClientRecordTypeId, 'Main Contact Person');
            Contact invoicing  = BE_TEST_Helper.createContact(acct.Id, contactClientRecordTypeId, 'Invoicing Contact Person');
            Contact order      = BE_TEST_Helper.createContact(acct.Id, contactClientRecordTypeId, 'Order Contact Person');
            Contact delivering = BE_TEST_Helper.createContact(acct.Id, contactClientRecordTypeId, 'Delivery Contact Person');

            BE_TEST_Helper.createOCR(primary.Id,    opp.Id, 'Primary Contact');
            BE_TEST_Helper.createOCR(invoicing.Id,  opp.Id, 'Invoicing Contact');
            BE_TEST_Helper.createOCR(order.Id,      opp.Id, 'Order Contact');
            BE_TEST_Helper.createOCR(delivering.Id, opp.Id, 'Delivering Contact');

            ER_Financial_Center__c fc  = BE_TEST_Helper.createFinancialCenter(acct.Id, 'ABSI 1 FC', true);
            ER_Delivery_Site__c    dsl = BE_TEST_Helper.createDeliverySite(acct.Id, fc.Id, 'ABSI 1 DS');
            BE_TEST_Helper.createDistributionPoint(dsl.Id, 'ABSI 1 DP');
        }
    }

    class GenericMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @isTest static void testSimpleAndFetchMethods() {
        Test.setMock(HttpCalloutMock.class, new GenericMock());

        Account acct = [SELECT Id, ER_Registration_Number__c FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];

        Test.startTest();
        clientAutoEnrollmentComponentController.getMaxBeneficiaryCount();
        clientAutoEnrollmentComponentController.getSettingsAttributes();
        clientAutoEnrollmentComponentController.getSMESizeLimit();
        clientAutoEnrollmentComponentController.fetchProductsFromProductCode(productCode, language);
        clientAutoEnrollmentComponentController.fetchMultiProductsFromOpportunity(opp.Id, language);
        Test.stopTest();
    }

    @isTest static void testPromoPricebookAndActiveProducts() {
        Test.setMock(HttpCalloutMock.class, new GenericMock());

        Account acct = [SELECT Id, ER_Registration_Number__c FROM Account LIMIT 1];
        Product2 prod = [SELECT Id, ProductCode, Name FROM Product2 WHERE ProductCode = :productCode LIMIT 1];

        Test.startTest();
        clientAutoEnrollmentComponentController.fetchPromoCodeDetails('PROMOSME', businessUnit, language, prod.Id);
        clientAutoEnrollmentComponentController.fetchPricebookAndPromoId(productCode, 'PROMOSME', businessUnit);
        clientAutoEnrollmentComponentController.fetchActiveProducts(acct.ER_Registration_Number__c, language, businessUnit);
        Test.stopTest();
    }

    @isTest static void testLeadCreationAndValidation() {
        Test.setMock(HttpCalloutMock.class, new GenericMock());

        Product2 solution = new Product2();
        solution.productCode = 'TRE';
        solution.ER_Type__c = 'Solution';
        solution.name = 'Edenred Meal';
        solution.ER_Business_Unit__c = 'BE';
        solution.isActive = true;
        insert solution;
        
        Account acct = [SELECT Id, ER_Registration_Number__c FROM Account LIMIT 1];

        Test.startTest();
        String newLeadId = clientAutoEnrollmentComponentController.createLead(
            null, 'Mr.', 'Test', 'User', 'FR', null, 'user@test.com',
            '0123456789', '0412345678', true, 12, solution.Id, null, 'BE', null
        );

         try {
            Product2 prod = [SELECT Id, ProductCode, Name FROM Product2 WHERE ProductCode = :productCode LIMIT 1];
            clientAutoEnrollmentComponentController.validateAndConvertLead(
                'BE0123456789', false, '0123456789', 'Comm Name', 'BV', 12, acct.ER_Registration_Number__c,
                null, 'Main Str.', '1000', businessUnit, productCode, 'Brussels',
                'BELGIUM', solution.Id, solution.Name, newLeadId, 'Legal Name', null, language, 'Test', 'Sales', null
            );
        } catch (Exception ignore) {}
        Test.stopTest();
    }

    @isTest static void testContactUpsertAndAccountUpdate() {
        Test.setMock(HttpCalloutMock.class, new GenericMock());

        Account acct = [SELECT Id, ER_Registration_Number__c FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact pri = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        clientAutoEnrollmentComponentController.fetchContactFromAccount(
            acct.ER_Registration_Number__c, opp.Id, pri.Id
        );

        Map<String, Contact> tempMap = new Map<String, Contact>{
            'c1' => new Contact(FirstName='Tmp', LastName='Contact', Email='tmp@test.com', Phone='021234567')
        };
        clientAutoEnrollmentComponentController.upsertContactsAndRoles(
            opp.Id, tempMap, 'c1', null, null, null, false, null
        );

        clientAutoEnrollmentComponentController.updateAccountData(
            50, 'Ship Name', 'Ship Street', '1000', 'Ship City', 'BELGIUM',
            false, false, acct.ER_Registration_Number__c, 30, null, opp.Id
        );
        clientAutoEnrollmentComponentController.updateAccount(
            acct.Id, 'BE1234567890', true, 'TEST', 'TEST', 'TEST', '1000', 'TEST', 'BELGIUM', null
        );
        Test.stopTest();
    }

    @isTest static void testBillableServicesAndContractFlow() {
        Test.setMock(HttpCalloutMock.class, new GenericMock());

        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];

        Test.startTest();
        clientAutoEnrollmentComponentController.fetchBillableServices(
            productCode, null, opp.Pricebook2Id, 200, language
        );
        clientAutoEnrollmentComponentController.fetchBillableServicesFromOpp(
            opp.Id, null, language
        );

        try {
            clientAutoEnrollmentComponentController.createServicesAndContract(
                null, opp.Pricebook2Id, null, 30, 10, 30, 365, 200,
                opp.Id, businessUnit, '[]'
            );
        } catch (Exception ignore) {}

        String quoteId;
            
        try {
            quoteId = clientAutoEnrollmentComponentController.createQuote(opp.Id);
            
        } catch (Exception ignore) {}

        if (quoteId != null) {
            try {
                clientAutoEnrollmentComponentController.createContract(quoteId);
            } catch (Exception ignore) {}
        }
        Test.stopTest();
    }

    @isTest static void testGeneralConditionsAndWebKeyAndPicklist() {
        Test.setMock(HttpCalloutMock.class, new GenericMock());

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acct = [SELECT Id FROM Account LIMIT 1];
        opp.AccountId = acct.Id;
        update opp;
        Product2 prod = [SELECT Id, Name FROM Product2 WHERE ProductCode = :productCode LIMIT 1];

        Test.startTest();
        try {
            clientAutoEnrollmentComponentController.submitAgreedToGeneralConditions(
                opp.Id, true, true, true,true, true, opp.Id, acct.Id, 'Customer',
                prod.Name, productCode, 'cust@test.com', language, 250
            );
        } catch (Exception ignore) {}

        try {
            clientAutoEnrollmentComponentController.fetchDataFromOpportunity('xyz');
        } catch (Exception ignore) {}

        clientAutoEnrollmentComponentController.getPickListValues(
            'Lead', 'Status', false, language, 'LU'
        );
        Test.stopTest();
    }
}