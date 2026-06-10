@isTest
private class TestGetInfoViaForm {
    static Id accountClientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();

    @testSetup
    static void setupTestData() {
        Account acc = new Account(
            recordtypeid = accountClientRecordTypeId,
            ER_Match_Legal_Address__c = true,
            ER_VAT_Number__c = 'BE0123456789',
            BillingStreet = 'Road Street',
            BillingCity = 'Paris',
            BillingPostalCode = '1095',
            Name = 'Test',
            ER_Country_Code__c = 'BE'
        );
        insert acc;
        
        Contact con = new Contact(
            Salutation = 'Mr.',
            FirstName = 'Head',
            LastName = 'Jane',
            Email = 'headJohn2@example.com',
            ER_Status__c = 'Active',
            AccountId = acc.Id
        );
        insert con;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        insert opp;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, DS_Form_Submitted__c = false);
        insert quote;

        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = con.Id, Role = 'Primary Contact');
        insert ocr;
    }

    static testMethod void testGetContactRolePicklist() {
        List<String> picklist = GetInfoViaForm.getContactRolePicklist();
        System.assertNotEquals(null, picklist);
        System.assert(picklist.size() > 0);
    }

    static testMethod void testGetQuoteAccountDetails_withValidQuoteId() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        GetInfoViaForm.QuoteWrapper wrapper = GetInfoViaForm.getQuoteAccountDetails(q.Id);
        System.assertNotEquals(null, wrapper);
        System.assertEquals(q.Id, wrapper.quote.Id);
    }

    static testMethod void testGetQuoteAccountDetails_withMissingQuoteId() {
        try {
            GetInfoViaForm.getQuoteAccountDetails(null);
            System.assert(false, 'Should have thrown an error for null quoteId');
        } catch (AuraHandledException e) {
            //System.assertEquals('Quote ID is required.', e.getMessage());
        }
    }

    static testMethod void testSubmitClientForm_withAllData() {
        Quote q = [SELECT Id, AccountId FROM Quote LIMIT 1];

        Map<String, Object> fc = new Map<String, Object>{
            'ER_Invoicing_Street__c' => 'Street 1',
            'ER_Invoicing_Zip_Code__c' => '1000',
            'ER_Invoicing_City__c' => 'Brussels',
            'ER_Email__c' => 'finance@example.com'
        };

        Map<String, Object> ds = new Map<String, Object>{
            'ER_Street__c' => 'Delivery Street',
            'ER_Zip_Code__c' => '2000',
            'ER_City__c' => 'Antwerp'
        };

        List<Map<String, Object>> ocrList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'FirstName' => 'Jane',
                'LastName' => 'Smith',
                'Email' => 'jane@example.com',
                'Phone' => '2345678901',
                'Role' => 'Order Contact'
            }
        };

        Test.startTest();
        GetInfoViaForm.submitClientForm(
            q.Id,
            JSON.serialize(ocrList),
            JSON.serialize(fc),
            JSON.serialize(ds),
            'Test feedback'
        );
        Test.stopTest();

        q = [SELECT DS_Feedback__c, DS_Form_Submitted__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals('Test feedback', q.DS_Feedback__c);
        System.assertEquals(true, q.DS_Form_Submitted__c);
    }

    static testMethod void testSubmitClientForm_withMissingQuoteId() {
        try {
            GetInfoViaForm.submitClientForm(null, null, null, null, null);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            //System.assertEquals('Quote ID is required.', e.getMessage());
        }
    }

    /*static testMethod void testSendFormToPrimaryContact_withValidData() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        GetInfoViaForm.sendFormToPrimaryContact(q.Id);
        Test.stopTest();

        q = [SELECT DS_Form_Sent__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(true, q.DS_Form_Sent__c);
    }*/
}