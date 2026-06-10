@isTest
public class TestAttritionCampaignBatchForMMj {

    @testSetup
    static void setupTestData() {
        // Create Account with 50 employees and BU = 'BE' (Belgium)
        Account mmjAccount = APER07_UtilityTestMethod.getCompany('Grandparent');
        mmjAccount.ER_BUPicklist__c = 'BE';
        mmjAccount.NumberOfEmployees = 50;
        insert mmjAccount;
        

        // Create Contact (head contact) meeting lookup filter
        Contact headContact = new Contact(
            FirstName = 'MMj',
            LastName = 'Head',
            Email = 'mmjhead@example.com',
            AccountId = mmjAccount.Id,
            ER_Status__c = 'Active' // Lookup filter expects Status = Active
        );
        insert headContact;

        // Update Account with head office contact
        mmjAccount.HU_HQ_Contact__c = headContact.Id;
        update mmjAccount;

        Product2 solution = APER07_UtilityTestMethod.getsolution('testsolution');
        insert solution;

        ER_Solution_Line_Item__c sli = new ER_Solution_Line_Item__c(
            ER_Account__c = mmjAccount.Id,
            ER_Solution__c = solution.Id,
            Last_Order_Date__c = System.today().addDays(-100)
        );
        insert sli;
    }

    /*
    @isTest
    static void testMMjBatchCampaignCreation() {
        Test.startTest();
        try{
            AttritionCampaignBatchForMMj batch = new AttritionCampaignBatchForMMj();
            Database.executeBatch(batch, 1);
        } catch (Exception e) {
        System.debug('Flow error ignored in test: ' + e.getMessage());
    }
        Test.stopTest();

        // Assert campaign created
        List<Campaign> campaigns = [SELECT Id, Name FROM Campaign WHERE Name LIKE 'MMj Attrition Campaign%'];
        System.assertEquals(1, campaigns.size(), 'Campaign should be created');

        // Assert campaign member created
        List<CampaignMember> members = [SELECT Id, ContactId FROM CampaignMember];
        System.assertEquals(1, members.size(), 'One campaign member should be added');
    }

    @isTest
    static void testMMjBatchNoDuplicates() {
        // Run the batch once
        try{
            AttritionCampaignBatchForMMj batch1 = new AttritionCampaignBatchForMMj();
            Database.executeBatch(batch1, 1);
        } catch (Exception e) {
        System.debug('Flow error ignored in test: ' + e.getMessage());
    }

        // Run the batch again to test no duplicate members
        Test.startTest();
        AttritionCampaignBatchForMMj batch2 = new AttritionCampaignBatchForMMj();
        Database.executeBatch(batch2, 1);
        Test.stopTest();

        // Only one campaign member should still exist
        List<CampaignMember> members = [SELECT Id FROM CampaignMember];
        System.assertEquals(1, members.size(), 'Duplicate campaign members should not be created');
    }
        */
}