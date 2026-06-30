@isTest
public class QuoteExpirationBatch_Test {

    @testSetup
    static void testSetup() {
        User u = TestDataFactory.newUser('QEB', 'QEBTest', 'Local Admin', 'BE');
        u.ER_BypassVR__c = true;
        insert u;

        System.runAs(u) {
            Account acc = APER07_UtilityTestMethod.getCompany('QEB Test Account');
            insert acc;

            Opportunity opp = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'QEB Test Opp');
            opp.AccountId = acc.Id;
            insert opp;

            // Expired — should be denied by batch
            Quote expiredQuote = new Quote(
                Name        = 'QEB Expired Quote',
                OpportunityId = opp.Id,
                ExpirationDate = Date.today().addDays(-1),
                Status      = Label.LABS_SF_Quote_Status_Draft
            );
            insert expiredQuote;

            // Not expired — should NOT be touched by batch
            Quote activeQuote = new Quote(
                Name        = 'QEB Active Quote',
                OpportunityId = opp.Id,
                ExpirationDate = Date.today().addDays(30),
                Status      = Label.LABS_SF_Quote_Status_Draft
            );
            insert activeQuote;
        }
    }

    @isTest
    static void batchDeniesExpiredDraftQuotes() {
        Test.startTest();
        Database.executeBatch(new QuoteExpirationBatch(), 200);
        Test.stopTest();

        Quote expired = [SELECT Status FROM Quote WHERE Name = 'QEB Expired Quote' LIMIT 1];
        System.assertEquals(Label.LABS_SF_Quote_Status_Denied, expired.Status, 'Expired draft quote should be denied');

        Quote active = [SELECT Status FROM Quote WHERE Name = 'QEB Active Quote' LIMIT 1];
        System.assertNotEquals(Label.LABS_SF_Quote_Status_Denied, active.Status, 'Non-expired quote should not be denied');
    }

    @isTest
    static void schedulerFiresBatch() {
        Test.startTest();
        String jobId = System.schedule('QEB Test Job', '0 0 1 * * ?', new QuoteExpirationScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduler should return a valid job ID');
    }
}
