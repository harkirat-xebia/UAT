@IsTest
public with sharing class APBE01_LeadBelfirst_Test {

    @testSetup
    static void testSetup() {
        User u = TestDataFactory.newUser('APBE01', 'BelfirstTest', 'Local Admin', 'BE');
        u.ER_BypassVR__c = true;
        u.ER_Bypass_Duplication_Rule__c = true;
        insert u;
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE LastName = 'BelfirstTest' AND IsActive = true LIMIT 1];
    }

    private static Lead makeLead() {
        return new Lead(
            LastName     = 'Belfirst Test',
            FirstName    = 'Test',
            Company      = 'Test Company SA',
            Email        = 'belfirst' + Datetime.now().getTime() + '@mailinator.com',
            City         = 'Brussels',
            PostalCode   = '1000',
            ER_Language__c   = 'FR',
            ER_BUPicklist__c = 'BE',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                               .get('ER_Client_Lead_RT').getRecordTypeId()
        );
    }

    // ─── Multi-callout mock: handles all 5 SOAP operations in sequence ────────
    private class BelfirstSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml; charset=utf-8');
            String body = req.getBody();
            if      (body.contains('<web:Open>'))          res.setBody(loginBody());
            else if (body.contains('<web:SetLanguage>'))   res.setBody(setLanguageBody());
            else if (body.contains('<web:FindByBVDId>') || body.contains('<web:Find>')) res.setBody(findBody());
            else if (body.contains('<web:GetListData>'))   res.setBody(listDataBody());
            else                                           res.setBody(closeBody());
            return res;
        }
    }

    // Returns SelectionCount = 0 so WSBE01_BelfirstException is thrown
    private class BelfirstNotFoundMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml; charset=utf-8');
            String body = req.getBody();
            if      (body.contains('<web:Open>'))          res.setBody(loginBody());
            else if (body.contains('<web:FindByBVDId>') || body.contains('<web:Find>')) res.setBody(notFoundBody());
            else                                           res.setBody(closeBody());
            return res;
        }
    }


    // ─── isEligible unit tests (pure in-memory, no DML) ──────────────────────

    @IsTest
    static void isEligible_BELead_returnsTrue() {
        Lead lead = new Lead(LastName = 'Test', ER_BUPicklist__c = 'BE', ER_Registration_Number__c = '0663563934');
        System.assertEquals(true, APBE01_LeadBelfirst.isEligible(lead));
    }

    @IsTest
    static void isEligible_LULead_returnsTrue() {
        Lead lead = new Lead(LastName = 'Test', ER_BUPicklist__c = 'LU', ER_Registration_Number__c = 'B123456');
        System.assertEquals(true, APBE01_LeadBelfirst.isEligible(lead));
    }

    @IsTest
    static void isEligible_unsupportedBU_returnsFalse() {
        Lead lead = new Lead(LastName = 'Test', ER_BUPicklist__c = 'FR', ER_Registration_Number__c = '12345');
        System.assertEquals(false, APBE01_LeadBelfirst.isEligible(lead));
    }

    @IsTest
    static void isEligible_blankRegNumber_returnsFalse() {
        Lead lead = new Lead(LastName = 'Test', ER_BUPicklist__c = 'BE');
        System.assertEquals(false, APBE01_LeadBelfirst.isEligible(lead));
    }

    @IsTest
    static void isEligible_allLegalFieldsFilled_returnsFalse() {
        Lead lead = new Lead(
            LastName = 'Test',
            ER_BUPicklist__c = 'BE',
            ER_Registration_Number__c = '0663563934',
            ER_Legal_Name__c = 'Company',
            Street = 'Street 1',
            PostalCode = '1000',
            City = 'Brussels'
        );
        System.assertEquals(false, APBE01_LeadBelfirst.isEligible(lead));
    }

    @IsTest
    static void isEligible_autoEnrollmentSubSource_returnsFalse() {
        Lead lead = new Lead(
            LastName = 'Test',
            ER_BUPicklist__c = 'BE',
            ER_Registration_Number__c = '0663563934',
            ER_Lead_sub_source__c = 'Econtratonline'
        );
        System.assertEquals(false, APBE01_LeadBelfirst.isEligible(lead));
    }


    // ─── autoPopulateIfEmpty tests ────────────────────────────────────────────

    @IsTest
    static void autoPopulateIfEmpty_fillsBlankFields() {
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0663563934';
        System.runAs(testUser) { insert lead; }

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        APBE01_LeadBelfirst.autoPopulateIfEmpty(new Set<Id>{ lead.Id });
        Test.stopTest();

        Lead result = [SELECT ER_Legal_Name__c, Street, PostalCode,
                              City, Country, ER_Legal_Form__c, ER_VAT_Number__c
                       FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, result.ER_Legal_Name__c, 'Legal name should be populated');
        System.assertNotEquals(null, result.Street,            'Street should be populated');
        System.assertNotEquals(null, result.PostalCode,        'Zip code should be populated');
        System.assertNotEquals(null, result.City,              'City should be populated');
        System.assertNotEquals(null, result.Country,           'Country should be populated');
        System.assertNotEquals(null, result.ER_Legal_Form__c,  'Legal form should be populated');
        System.assertNotEquals(null, result.ER_VAT_Number__c,  'VAT number should be populated from BVDID');
    }

    @IsTest
    static void autoPopulateIfEmpty_doesNotOverwriteExistingFields() {
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0663563934';
        lead.ER_Legal_Name__c = 'Pre-existing Name';
        System.runAs(testUser) { insert lead; }

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        APBE01_LeadBelfirst.autoPopulateIfEmpty(new Set<Id>{ lead.Id });
        Test.stopTest();

        Lead result = [SELECT ER_Legal_Name__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Pre-existing Name', result.ER_Legal_Name__c, 'Pre-existing field must not be overwritten');
    }

    @IsTest
    static void autoPopulateIfEmpty_companyNotFound_noUpdate() {
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0000000000';
        System.runAs(testUser) { insert lead; }

        Test.setMock(HttpCalloutMock.class, new BelfirstNotFoundMock());
        Test.startTest();
        APBE01_LeadBelfirst.autoPopulateIfEmpty(new Set<Id>{ lead.Id });
        Test.stopTest();

        Lead result = [SELECT ER_Legal_Name__c, Street FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, result.ER_Legal_Name__c, 'No data should be written when company not found');
        System.assertEquals(null, result.Street,            'No data should be written when company not found');
    }

    @IsTest
    static void autoPopulateIfEmpty_autoEnrollmentLead_soqlFiltersItOut() {
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0663563934';
        lead.ER_Lead_sub_source__c = 'Econtratonline';
        System.runAs(testUser) { insert lead; }

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        APBE01_LeadBelfirst.autoPopulateIfEmpty(new Set<Id>{ lead.Id });
        Test.stopTest();

        Lead result = [SELECT ER_Legal_Name__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, result.ER_Legal_Name__c, 'Auto-enrollment lead must not be enriched');
    }

    @IsTest
    static void autoPopulateIfEmpty_employeeNd_notPopulated() {
        // BelfirstSuccessMock returns 'n.d.' for EMPLOYEE; sanitize() converts it to null
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0663563934';
        System.runAs(testUser) { insert lead; }

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        APBE01_LeadBelfirst.autoPopulateIfEmpty(new Set<Id>{ lead.Id });
        Test.stopTest();

        Lead result = [SELECT NumberOfEmployees FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, result.NumberOfEmployees, 'NumberOfEmployees must stay null when Belfirst returns n.d.');
    }


    // ─── Trigger integration tests ────────────────────────────────────────────

    @IsTest
    static void trigger_afterInsert_eligible_populatesFields() {
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0663563934';

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        System.runAs(testUser) { insert lead; }
        Test.stopTest();

        Lead result = [SELECT ER_Legal_Name__c, Street FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, result.ER_Legal_Name__c, 'afterInsert should trigger Belfirst enrichment');
        System.assertNotEquals(null, result.Street,            'afterInsert should trigger Belfirst enrichment');
    }

    @IsTest
    static void trigger_afterUpdate_regNumSet_populatesFields() {
        // afterUpdate fires only on blank → non-blank; insert without reg number first
        User testUser = getTestUser();
        Lead lead = makeLead(); // no ER_Registration_Number__c → isEligible false → no future
        System.runAs(testUser) { insert lead; }

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        lead.ER_Registration_Number__c = '0663563934'; // blank → non-blank triggers the future
        System.runAs(testUser) { update lead; }
        Test.stopTest();

        Lead result = [SELECT ER_Legal_Name__c, Street FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, result.ER_Legal_Name__c, 'Setting reg number for the first time should trigger enrichment');
        System.assertNotEquals(null, result.Street,            'Setting reg number for the first time should trigger enrichment');
    }

    @IsTest
    static void trigger_afterUpdate_regNumUnchanged_noEnrichment() {
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0663563934';
        // Pre-fill all 4 legal fields so isEligible = false → no future enqueued on insert.
        // If Belfirst were ever called (it should not be), the mock returns 'Rue Test 10',
        // which would differ from 'Original Street' and fail the assertion below.
        lead.ER_Legal_Name__c = 'Original Name';
        lead.Street           = 'Original Street';
        lead.PostalCode       = '0000';
        lead.City             = 'Original City';
        System.runAs(testUser) { insert lead; }

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        lead.LastName = 'Updated Name'; // reg number unchanged → regNumJustSet = false → no future
        System.runAs(testUser) { update lead; }
        Test.stopTest();

        Lead result = [SELECT Street FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Original Street', result.Street, 'Address fields must not change when reg number is unchanged');
    }

    @IsTest
    static void trigger_afterInsert_autoEnrollmentLead_notEnriched() {
        User testUser = getTestUser();
        Lead lead = makeLead();
        lead.ER_Registration_Number__c = '0663563934';
        lead.ER_Lead_sub_source__c = 'Econtratonline';

        Test.setMock(HttpCalloutMock.class, new BelfirstSuccessMock());
        Test.startTest();
        System.runAs(testUser) { insert lead; }
        Test.stopTest();

        Lead result = [SELECT ER_Legal_Name__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, result.ER_Legal_Name__c, 'Auto-enrollment lead must not be enriched by trigger');
    }


    // ─── SOAP response helpers ────────────────────────────────────────────────

    private static String loginBody() {
        return '<?xml version="1.0" encoding="utf-8"?>'
             + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>'
             + '<OpenResponse xmlns="http://bvdep.com/webservices/"><OpenResult>TESTSESSION123</OpenResult></OpenResponse>'
             + '</soap:Body></soap:Envelope>';
    }

    private static String setLanguageBody() {
        return '<?xml version="1.0" encoding="utf-8"?>'
             + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>'
             + '<SetLanguageResponse xmlns="http://bvdep.com/webservices/"><SetLanguageResult>true</SetLanguageResult></SetLanguageResponse>'
             + '</soap:Body></soap:Envelope>';
    }

    private static String findBody() {
        return '<?xml version="1.0" encoding="utf-8"?>'
             + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>'
             + '<FindByBVDIdResponse xmlns="http://bvdep.com/webservices/"><FindByBVDIdResult>'
             + '<Token>42</Token><SelectionCount>1</SelectionCount>'
             + '</FindByBVDIdResult></FindByBVDIdResponse>'
             + '</soap:Body></soap:Envelope>';
    }

    private static String notFoundBody() {
        return '<?xml version="1.0" encoding="utf-8"?>'
             + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>'
             + '<FindByBVDIdResponse xmlns="http://bvdep.com/webservices/"><FindByBVDIdResult>'
             + '<Token>0</Token><SelectionCount>0</SelectionCount>'
             + '</FindByBVDIdResult></FindByBVDIdResponse>'
             + '</soap:Body></soap:Envelope>';
    }

    private static String listDataBody() {
        // Content inside GetListDataResult is parsed by XmlStreamReader after splitting on the tag.
        // item attribute at index 0 is 'field' — that becomes the map key in getListData().
        String innerXml =
              '<?xml version="1.0" encoding="utf-16"?>'
            + '<queryResults xmlns="http://www.bvdep.com/schemas/RemoteAccessDataResults.xsd">'
            + '<record id="BE0663563934">'
            + '<item field="NAME"     alias="NAME"     valueType="AccountValue" resultType="String"       fieldType="String">TEST COMPANY SA</item>'
            + '<item field="BVDID"    alias="BVDID"    valueType="AccountValue" resultType="String"       fieldType="String">BE0663563934</item>'
            + '<item field="ADDRESS"  alias="ADDRESS"  valueType="AccountValue" resultType="String"       fieldType="String">Rue Test 10</item>'
            + '<item field="POSTCODE" alias="POSTCODE" valueType="AccountValue" resultType="String"       fieldType="String">1000</item>'
            + '<item field="TOWN"     alias="TOWN"     valueType="AccountValue" resultType="String"       fieldType="String">Brussels</item>'
            + '<item field="COUNTRY"  alias="COUNTRY"  valueType="AccountValue" resultType="String"       fieldType="String">BELGIUM</item>'
            + '<item field="TYPE"     alias="TYPE"     valueType="AccountValue" resultType="String"       fieldType="String">SA/NV</item>'
            + '<item field="EMPLOYEE" alias="EMPLOYEE" valueType="AccountValue" resultType="NotAvailable" fieldType="Value">n.d.</item>'
            + '<item field="PHONE"    alias="PHONE"    valueType="AccountValue" resultType="NotAvailable" fieldType="String"></item>'
            + '<item field="LVAT"     alias="LVAT"     valueType="AccountValue" resultType="NotAvailable" fieldType="String"></item>'
            + '</record>'
            + '</queryResults>';

        return '<?xml version="1.0" encoding="utf-8"?>'
             + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>'
             + '<GetListDataResponse xmlns="http://bvdep.com/webservices/">'
             + '<GetListDataResult>' + innerXml + '</GetListDataResult>'
             + '</GetListDataResponse>'
             + '</soap:Body></soap:Envelope>';
    }

    private static String closeBody() {
        return '<?xml version="1.0" encoding="utf-8"?>'
             + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>'
             + '<CloseResponse xmlns="http://bvdep.com/webservices/"><CloseResult>true</CloseResult></CloseResponse>'
             + '</soap:Body></soap:Envelope>';
    }
}
