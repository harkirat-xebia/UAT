@IsTest
private class NEMO_ContractAmendmentServiceTest {
    
    private static User createBypassUser() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    User u = new User(
        ProfileId = p.Id,
        Username = 'bypass' + System.currentTimeMillis() + '@test.com',
        Email = 'bypass@test.com',
        LastName = 'Bypass',
        Alias = 'bypas',
        TimeZoneSidKey = 'Europe/Brussels',
        LocaleSidKey = 'en_US',
        ER_Business_Unit__c = 'BE',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );

    // set bypass flag (dynamic put avoids compile issues if field is hidden)
    u.put('ER_BypassVR__c', true);

    insert u;
    return u;
}

    private class TestData {
        Account acc;
        Contract con;
        Opportunity opp;

        Product2 prod1;
        Product2 prod2;
        Product2 prodNoPbe;

        PricebookEntry pbe1;
        PricebookEntry pbe2;

        ER_ContractLineItem__c cli1;

        OpportunityLineItem oliProd1; // existing line to update
    }

    private static TestData buildBaseData() {
        TestData td = new TestData();

        // Account
        td.acc = new Account(
            Name = 'TestAccount',
            ER_VAT_Number__c = 'BE0123456789'
        );
        insert td.acc;

        // Contract (service only needs Id, but CLI mapping checks ER_Contract__c = contractId)
        td.con = new Contract(
            AccountId = td.acc.Id,
            ER_Customer_Domain__c = 'testAccount',
            StartDate = Date.today()
            
            // Add Status if your org requires it
        );
        insert td.con;

        // Standard Pricebook
        Id stdPbId = Test.getStandardPricebookId();

        // Products
        td.prod1 = new Product2(Name = 'Prod-1', IsActive = true);
        td.prod2 = new Product2(Name = 'Prod-2', IsActive = true);
        td.prodNoPbe = new Product2(Name = 'Prod-NoPBE', IsActive = true);
        insert new List<Product2>{ td.prod1, td.prod2, td.prodNoPbe };

        // Pricebook Entries for prod1 + prod2 only
        td.pbe1 = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = td.prod1.Id,
            UnitPrice    = 10,
            IsActive     = true,
            UseStandardPrice = false
        );
        td.pbe2 = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = td.prod2.Id,
            UnitPrice    = 20,
            IsActive     = true,
            UseStandardPrice = false
        );
        insert new List<PricebookEntry>{ td.pbe1, td.pbe2 };

        // Opportunity (represents the amendment Opportunity)
        td.opp = new Opportunity(
            Name = 'AM',
            AccountId = td.acc.Id,
            StageName = 'Prospecting',
            Customer_Domain__c = 'testAccount',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = stdPbId
        );
        insert td.opp;

        // Existing OLI for prod1 (so UPDATE path hits)
        td.oliProd1 = new OpportunityLineItem(
            OpportunityId = td.opp.Id,
            PricebookEntryId = td.pbe1.Id,
            Quantity = 1,
            UnitPrice = 10
        );
        insert td.oliProd1;

        // Contract Line Item for prod1 (so match.cliId -> product2 mapping works)
        td.cli1 = new ER_ContractLineItem__c(
            Name = 'CLI-1',
            ER_Quantity__c = 1,
            ER_UnitPrice__c = 3,
            ER_Contract__c = td.con.Id,
            ER_Product2__c = td.prod1.Id
        );
        insert td.cli1;

        return td;
    }

    @IsTest
    static void test_UpdateExistingOpportunityProduct_ByCliId() {
        User bypassUser = createBypassUser();
        System.runAs(bypassUser) {
        TestData td = buildBaseData();

        // Build change: UPDATE using cliId
        NEMO_ContractAmendmentTypes.ChangeDTO ch = new NEMO_ContractAmendmentTypes.ChangeDTO();
        ch.action = 'UPDATE';
        ch.match = new NEMO_ContractAmendmentTypes.MatchDTO();
        ch.match.cliId = (String)td.cli1.Id;

        ch.updates = new NEMO_ContractAmendmentTypes.UpdatesDTO();
        ch.updates.quantity = 5;
        ch.updates.unitPrice = 12;
        ch.updates.mpv = true; // checkbox in your org

        Test.startTest();
        NEMO_ContractAmendmentTypes.ApplyResult res =
            NEMO_ContractAmendmentService.applyLineChanges(td.con.Id, td.opp.Id, new List<NEMO_ContractAmendmentTypes.ChangeDTO>{ ch });
        Test.stopTest();

        System.assertEquals(1, res.updatedLineItemIds.size(), 'Expected 1 updated OLI');
        System.assertEquals(0, res.createdLineItemIds.size(), 'Expected no inserts');

        // Verify OLI updated
        OpportunityLineItem oli = [
            SELECT Id, Quantity, UnitPrice, ER_MPV__c
            FROM OpportunityLineItem
            WHERE Id = :td.oliProd1.Id
            LIMIT 1
        ];
        System.assertEquals(5, oli.Quantity);
        System.assertEquals(12, oli.UnitPrice);
        System.assertEquals(true, oli.ER_MPV__c);
    }
    }

    @IsTest
    static void test_AddNewOpportunityProduct_ByProduct2Id() {
        User bypassUser = createBypassUser();

    System.runAs(bypassUser) {
        TestData td = buildBaseData();

        // Build change: ADD using product2Id (prod2 has no existing OLI)
        NEMO_ContractAmendmentTypes.ChangeDTO ch = new NEMO_ContractAmendmentTypes.ChangeDTO();
        ch.action = 'ADD';
        ch.match = new NEMO_ContractAmendmentTypes.MatchDTO();
        ch.match.product2Id = (String)td.prod2.Id;

        ch.updates = new NEMO_ContractAmendmentTypes.UpdatesDTO();
        ch.updates.quantity = 3;
        ch.updates.unitPrice = 22;

        Test.startTest();
        NEMO_ContractAmendmentTypes.ApplyResult res =
            NEMO_ContractAmendmentService.applyLineChanges(td.con.Id, td.opp.Id, new List<NEMO_ContractAmendmentTypes.ChangeDTO>{ ch });
        Test.stopTest();

        System.assertEquals(0, res.updatedLineItemIds.size(), 'Expected no updates');
        System.assertEquals(1, res.createdLineItemIds.size(), 'Expected 1 insert');

        // Verify a new OLI exists for prod2
        OpportunityLineItem oli2 = [
            SELECT Id, Product2Id, Quantity, UnitPrice
            FROM OpportunityLineItem
            WHERE OpportunityId = :td.opp.Id
              AND Product2Id = :td.prod2.Id
            LIMIT 1
        ];
        System.assertEquals(3, oli2.Quantity);
        System.assertEquals(22, oli2.UnitPrice);
    }
    }

    /*@IsTest
    static void test_AddFails_WhenNoPricebookEntry() {
        User bypassUser = createBypassUser();

    System.runAs(bypassUser) {
        TestData td = buildBaseData();

        // Build change: ADD product with no PricebookEntry
        NEMO_ContractAmendmentTypes.ChangeDTO ch = new NEMO_ContractAmendmentTypes.ChangeDTO();
        ch.action = 'ADD';
        ch.match = new NEMO_ContractAmendmentTypes.MatchDTO();
        ch.match.product2Id = (String)td.prodNoPbe.Id;

        ch.updates = new NEMO_ContractAmendmentTypes.UpdatesDTO();
        ch.updates.quantity = 1;
        ch.updates.unitPrice = 5;

        Test.startTest();
        try {
            NEMO_ContractAmendmentService.applyLineChanges(td.con.Id, td.opp.Id, new List<NEMO_ContractAmendmentTypes.ChangeDTO>{ ch });
            System.assert(false, 'Expected exception due to missing PricebookEntry');
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('No active PricebookEntry found'),
                'Expected missing PBE error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    }*/
}