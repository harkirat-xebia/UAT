@isTest
public class APER11_FrameworkAgreement_Test {

    @testSetup
    static void testSetup() {
        User u = TestDataFactory.newUser('FATest', 'User', 'Local Admin', 'BELUX', 'BE');
        u.ER_BypassVR__c = true;
        u.ER_bypassTrigger__c = true;
        u.ER_Bypass_Flows__c = true;
        insert u;
        UtilsBypass.reset();

        System.runAs(u) {
            // Parent account
            Account parent = APER07_UtilityTestMethod.getCompany('FA_Parent');
            insert parent;

            // Two direct children
            Account child1 = APER07_UtilityTestMethod.getAccountWithParent('FA_Child1', parent.Id);
            child1.ER_Enterprise_Number__c = 'BE0001';
            Account child2 = APER07_UtilityTestMethod.getAccountWithParent('FA_Child2', parent.Id);
            child2.ER_Enterprise_Number__c = 'BE0002';
            insert new List<Account>{ child1, child2 };

            // Grandchild under child1 (multi-level test)
            Account grandchild = APER07_UtilityTestMethod.getAccountWithParent('FA_Grandchild', child1.Id);
            grandchild.ER_Enterprise_Number__c = 'BE0003';
            insert grandchild;

            // Non-framework opportunity (linked to parent account)
            Opportunity stdOpp = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'FA_StdOpp');
            stdOpp.AccountId = parent.Id;
            insert stdOpp;

            // Framework Agreement opportunity
            Opportunity faOpp = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'FA_FrameworkOpp');
            faOpp.AccountId = parent.Id;
            faOpp.Type = 'Framework agreement';
            faOpp.Contract_End_Date__c = Date.today().addYears(1);
            insert faOpp;

            // PriceBook for quote creation
            PriceBook2 pb = APER07_UtilityTestMethod.getCustomPriceBook('FA_PriceBook');
            insert pb;

            // Quote on standard opp (for non-framework scenario)
            Quote stdQuote = APER07_UtilityTestMethod.getQuote('ER_Merchant_Quote', 'FA_StdQuote', stdOpp.Id, pb.Id);
            insert stdQuote;

            // Quote on framework opp
            Quote faQuote = APER07_UtilityTestMethod.getQuote('ER_Merchant_Quote', 'FA_FAQuote', faOpp.Id, pb.Id);
            insert faQuote;
        }
    }

    @isTest
    static void testSetFrameworkFlag_frameworkOpp_setsFlag() {
        Opportunity faOpp = [SELECT Id FROM Opportunity WHERE Name = 'FA_FrameworkOpp' LIMIT 1];

        Quote q = new Quote(
            Name = 'TestFlagQuote',
            OpportunityId = faOpp.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addMonths(1)
        );

        Test.startTest();
        APER11_FrameworkAgreement_Management.setFrameworkFlag(new List<Quote>{ q });
        Test.stopTest();

        System.assertEquals(true, q.Is_Framework_Agreement__c, 'Quote linked to Framework Agreement opp should be flagged');
    }

    @isTest
    static void testSetFrameworkFlag_standardOpp_doesNotSetFlag() {
        Opportunity stdOpp = [SELECT Id FROM Opportunity WHERE Name = 'FA_StdOpp' LIMIT 1];

        Quote q = new Quote(
            Name = 'TestNonFlagQuote',
            OpportunityId = stdOpp.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addMonths(1)
        );

        Test.startTest();
        APER11_FrameworkAgreement_Management.setFrameworkFlag(new List<Quote>{ q });
        Test.stopTest();

        System.assertEquals(false, q.Is_Framework_Agreement__c, 'Quote on a standard opp should not be flagged');
    }

    @isTest
    static void testCreateFrameworkScopeRecords_childAccounts_createsTwoScopes() {
        Quote faQuote = [SELECT Id, OpportunityId, Is_Framework_Agreement__c FROM Quote WHERE Name = 'FA_FAQuote' LIMIT 1];
        faQuote.Is_Framework_Agreement__c = true;  // set in memory — simulates afterInsert state

        Test.startTest();
        APER11_FrameworkAgreement_Management.createFrameworkScopeRecords(new List<Quote>{ faQuote });
        Test.stopTest();

        List<Framework_Scope__c> scopes = [SELECT Id, Entity_Name__c, Included__c FROM Framework_Scope__c WHERE Quote__c = :faQuote.Id];
        // FA_Child1, FA_Child2, FA_Grandchild = 3 total (BFS goes multi-level)
        System.assertEquals(3, scopes.size(), 'Should create one scope record per descendant account');
        for (Framework_Scope__c s : scopes) {
            System.assertEquals(false, s.Included__c, 'All scope records should default to Included__c = false');
        }
    }

    @isTest
    static void testCreateFrameworkScopeRecords_noChildAccounts_noScopes() {
        // Use the parent account but in a new opp/quote where parent has no children visible (won't be, children exist)
        // Create a standalone account with no children
        User u = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName LIKE 'FATest%' LIMIT 1];
        Account standalone;
        System.runAs(u) {
            standalone = APER07_UtilityTestMethod.getCompany('FA_Standalone');
            insert standalone;

            Opportunity soOpp = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'FA_StandaloneOpp');
            soOpp.AccountId = standalone.Id;
            insert soOpp;

            PriceBook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'FA_PriceBook' LIMIT 1];
            Quote soQuote = APER07_UtilityTestMethod.getQuote('ER_Merchant_Quote', 'FA_StandaloneQuote', soOpp.Id, pb.Id);
            insert soQuote;
        }

        Quote soQ = [SELECT Id, OpportunityId FROM Quote WHERE Name = 'FA_StandaloneQuote' LIMIT 1];
        soQ.Is_Framework_Agreement__c = true;

        Test.startTest();
        APER11_FrameworkAgreement_Management.createFrameworkScopeRecords(new List<Quote>{ soQ });
        Test.stopTest();

        List<Framework_Scope__c> scopes = [SELECT Id FROM Framework_Scope__c WHERE Quote__c = :soQ.Id];
        System.assertEquals(0, scopes.size(), 'Account with no children should produce no scope records');
    }

    /*@isTest
    static void testCreateFrameworkScopeRecords_nonFrameworkQuote_noScopes() {
        Quote stdQ = [SELECT Id, OpportunityId FROM Quote WHERE Name = 'FA_StdQuote' LIMIT 1];
        // Is_Framework_Agreement__c is false by default

        Test.startTest();
        APER11_FrameworkAgreement_Management.createFrameworkScopeRecords(new List<Quote>{ stdQ });
        Test.stopTest();

        List<Framework_Scope__c> scopes = [SELECT Id FROM Framework_Scope__c WHERE Quote__c = :stdQ.Id];
        System.assertEquals(0, scopes.size(), 'Non-framework quote should produce no scope records');
    }
*/

    /*@isTest
    static void testScopeRecords_entityFieldsPopulated() {
        Quote faQuote = [SELECT Id, OpportunityId FROM Quote WHERE Name = 'FA_FAQuote' LIMIT 1];
        faQuote.Is_Framework_Agreement__c = true;

        Test.startTest();
        APER11_FrameworkAgreement_Management.createFrameworkScopeRecords(new List<Quote>{ faQuote });
        Test.stopTest();

        Map<String, Framework_Scope__c> byName = new Map<String, Framework_Scope__c>();
        for (Framework_Scope__c s : [SELECT Id, Entity_Name__c, Entity_Legal_Registration_Number__c, Account__c
                                      FROM Framework_Scope__c WHERE Quote__c = :faQuote.Id]) {
            byName.put(s.Entity_Name__c, s);
        }

        System.assert(byName.containsKey('FA_Child1'), 'FA_Child1 scope record should exist');
        System.assertEquals('BE0001', byName.get('FA_Child1').Entity_Legal_Registration_Number__c);
        System.assert(byName.containsKey('FA_Child2'), 'FA_Child2 scope record should exist');
        System.assertEquals('BE0002', byName.get('FA_Child2').Entity_Legal_Registration_Number__c);
        System.assert(byName.containsKey('FA_Grandchild'), 'FA_Grandchild scope record should exist (multi-level BFS)');
        System.assertEquals('BE0003', byName.get('FA_Grandchild').Entity_Legal_Registration_Number__c);
    }
*/
}
