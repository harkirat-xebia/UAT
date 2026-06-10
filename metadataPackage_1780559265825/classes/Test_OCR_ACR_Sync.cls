@isTest
public class Test_OCR_ACR_Sync {
    static Id accountClientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();

    @testSetup
    static void setupData() {
        Account acc1 = new Account(
            recordtypeid = accountClientRecordTypeId,
            ER_Match_Legal_Address__c = true,
            ER_VAT_Number__c = 'BE0123456789',
            BillingStreet = 'Road Street',
            BillingCity = 'Paris',
            BillingPostalCode = '1095',
            Name = 'Test',
            ER_Country_Code__c = 'BE'
        );
        insert acc1;

        Contact contact1 = new Contact(
            Salutation = 'Mr.',
            FirstName = 'Head',
            LastName = 'John',
            Email = 'headJohn@example.com',
            ER_Status__c = 'Active',
            AccountId = acc1.Id
        );
        insert contact1;

        Contact contact2 = new Contact(
            Salutation = 'Mr.',
            FirstName = 'Head',
            LastName = 'Jane',
            Email = 'headJohn2@example.com',
            ER_Status__c = 'Active',
            AccountId = acc1.Id
        );
        insert contact2;

        Opportunity opp1 = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'TestOpp1');
        opp1.Name = 'Test Opp1';
        opp1.AccountId = acc1.Id;
        opp1.Primary_Contact__c = contact1.Id;
        opp1.Invoicing_Contact__c = contact2.Id;
        insert opp1;

        Opportunity opp2 = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'TestOpp2');
        opp2.Name = 'Test Opp2';
        opp2.AccountId = acc1.Id;
        opp2.Primary_Contact__c = contact2.Id;
        insert opp2;
    }

    @isTest
    static void test_OCR_ACR_Creation_Update_Delete() {
        List<Opportunity> oppLst = [SELECT Id, AccountId, Primary_Contact__c, Invoicing_Contact__c FROM Opportunity];
        Contact contact1 = [SELECT Id FROM Contact WHERE LastName = 'John'];
        Contact contact2 = [SELECT Id FROM Contact WHERE LastName = 'Jane'];

        Test.startTest();

        // Clear existing contact role fields to avoid validation errors
        for (Opportunity opp : oppLst) {
            opp.Primary_Contact__c = null;
            opp.Invoicing_Contact__c = null;
        }
        update oppLst;

        // Create OCRs
        OpportunityContactRole ocr1 = new OpportunityContactRole(
            OpportunityId = oppLst[0].Id,
            ContactId = contact1.Id,
            Role = 'Primary Contact'
        );

        OpportunityContactRole ocr2 = new OpportunityContactRole(
            OpportunityId = oppLst[1].Id,
            ContactId = contact2.Id,
            Role = 'Invoicing Contact'
        );

        insert new List<OpportunityContactRole>{ ocr1, ocr2 };

        // Delete one OCR
        delete ocr2;

        // Validate updated ACR
        AccountContactRelation updatedAcr = [
            SELECT Id, ContactId, Roles FROM AccountContactRelation WHERE ContactId = :contact2.Id LIMIT 1
        ];
        //System.assert(!updatedAcr.Roles.contains('Invoicing Contact'), 'Role should be removed after OCR deletion');

        Test.stopTest();
    }
}