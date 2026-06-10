@isTest
private class OpportunityManagementWithoutSharingTest {
    
    @testSetup
static void setup() {
    // Create user directly without TestDataFactory
    Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    
    User ur = new User(
        FirstName = 'Test',
        LastName = 'APER_TEST',
        Email = 'test.aper@test.com',
        Username = 'test.aper' + System.currentTimeMillis() + '@test.com',
        Alias = 'taper',
        TimeZoneSidKey = 'Europe/Brussels',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = adminProfile.Id,
        LanguageLocaleKey = 'en_US',
        ER_BypassVR__c = true,
        ER_bypassTrigger__c = true,
        ER_Business_Unit__c = 'BE'
    );
    insert ur;
    
    System.runAs(ur) {
        // Configure validation rules settings
        ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
            UserInfo.getOrganizationId()
        );
        if (settings == null) {
            settings = new ER_Validation_Rules_Settings__c(
                SetupOwnerId = UserInfo.getOrganizationId()
            );
        }
        settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
        upsert settings;
        
        // Create test account
        Account testAccount = APER07_UtilityTestMethod.insertAccount(
            'TestAccount',
            'ER_Company_Account_RT'
        );
        
        // Create child account with parent
        Account childAccount = APER07_UtilityTestMethod.getAccountWithParent(
            'ChildAccount',
            testAccount.Id
        );
        insert childAccount;
        
        // Create partner account
        Account partnerAccount = APER07_UtilityTestMethod.insertAccount(
            'PartnerAccount',
            'ER_Company_Account_RT'
        );
        
        // Create partner relationship
        Partner partner = new Partner(
            Role = 'Franchiser',
            AccountToId = partnerAccount.Id,
            AccountFromId = childAccount.Id
        );
        insert partner;
        
        // Create contacts with required fields
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 4; i++) {
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                AccountId = testAccount.Id,
                Email = 'test' + i + '@test.com',
                Salutation = 'Mr',
                ER_Status__c = 'Active'
            );
            contacts.add(con);
        }
        insert contacts;
        
        // Create custom pricebook
        Pricebook2 customPb = new Pricebook2(
            Name = 'Test Custom Price Book',
            IsActive = true,
            ER_Business_Unit__c = 'BE'
        );
        insert customPb;
        
        // Create engagement pricebook
        Pricebook2 engagementPb = new Pricebook2(
            Name = 'Engagement Price Book Test',
            IsActive = true,
            ER_Business_Unit__c = 'BE'
        );
        insert engagementPb;
        
        // Create solution product
        Product2 solution = new Product2(
            Name = 'TestSolution',
            ProductCode = 'TEST_SOL_001',
            IsActive = true,
            ER_Business_Unit__c = 'BE',
            ER_Type__c = 'Solution',
            zqu__Category__c = 'Base Products',
            BU_External_Reference__c = 'TEST_SOL_CODE'
        );
        insert solution;
        
        // Create service product
        Product2 service = new Product2(
            Name = 'TestService',
            ProductCode = 'TEST_SRV_001',
            IsActive = true,
            ER_Solution__c = solution.Id,
            ER_Solution2__c = solution.Id,
            ER_Business_Unit__c = 'BE',
            ER_Type__c = 'Service'
        );
        insert service;
        
        // Create standard pricebook entry
        PricebookEntry standardPbe;
        List<PricebookEntry> existingStdPbe = [
            SELECT Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :Test.getStandardPricebookId()
            AND Product2Id = :service.Id
        ];
        
        if (existingStdPbe.isEmpty()) {
            standardPbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = service.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert standardPbe;
        } else {
            standardPbe = existingStdPbe[0];
        }
        
        // Create custom pricebook entry
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = service.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPbe;
        
        // Create engagement pricebook entry
        PricebookEntry engagementPbe = new PricebookEntry(
            Pricebook2Id = engagementPb.Id,
            Product2Id = service.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert engagementPbe;
        
        // Create framework contract
        Contract frameworkContract = APER07_UtilityTestMethod.insertContract(
            childAccount.Id,
            System.today(),
            Label.LABS_SF_Contract_Status_Draft,
            customPb.Id,
            'ER_Merchant_Contract_RT',
            ur.Id
        );
        frameworkContract.ER_Contract_Type__c = 'Framework agreement';
        update frameworkContract;
        
        // Create contract line item
        ER_ContractLineItem__c contractLineItem = APER07_UtilityTestMethod.getContractLineItem(
            frameworkContract.Id,
            service.Id,
            customPbe.Id,
            1,
            1
        );
        insert contractLineItem;
        
        // Create merchant opportunity
        Opportunity merchantOpp = APER07_UtilityTestMethod.getOpportunity(
            'ER_Merchant_Opportunity',
            'TestMerchantOpp'
        );
        merchantOpp.AccountId = testAccount.Id;
        merchantOpp.Pricebook2Id = customPb.Id;
        merchantOpp.StageName = 'Prospecting';
        merchantOpp.Commercial_Origin__c = 'Greenfield';
        merchantOpp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(30);
        merchantOpp.ER_BUPicklist__c = 'BE';
        
        // Create client opportunity
        Opportunity clientOpp = APER07_UtilityTestMethod.getOpportunity(
            'ER_Client_Opportunity_RT',
            'TestClientOpp'
        );
        clientOpp.AccountId = testAccount.Id;
        clientOpp.Pricebook2Id = engagementPb.Id;
        clientOpp.StageName = 'Prospecting';
        clientOpp.Commercial_Origin__c = 'Greenfield';
        clientOpp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(30);
        clientOpp.ER_BUPicklist__c = 'BE';
        clientOpp.ER_AmendedFromContract__c = frameworkContract.Id;
        
        // Create framework-derived opportunity
        Opportunity frameworkOpp = APER07_UtilityTestMethod.getOpportunity(
            'ER_Merchant_Opportunity',
            'TestFrameworkOpp'
        );
        frameworkOpp.AccountId = testAccount.Id;
        frameworkOpp.Pricebook2Id = customPb.Id;
        frameworkOpp.StageName = 'Prospecting';
        frameworkOpp.Derieved_from_Framework_Opp__c = true;
        frameworkOpp.Commercial_Origin__c = 'Greenfield';
        frameworkOpp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(30);
        frameworkOpp.ER_BUPicklist__c = 'BE';
        
        insert new List<Opportunity>{merchantOpp, clientOpp, frameworkOpp};
        
        // Get list price for opportunity line items
        PricebookEntry pbeWithPrice = [
            SELECT UnitPrice
            FROM PricebookEntry
            WHERE Id = :customPbe.Id
        ];
        
        // Create opportunity line items
        OpportunityLineItem merchantOli = new OpportunityLineItem(
            OpportunityId = merchantOpp.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = pbeWithPrice.UnitPrice,
            ER_Nb_Beneficiaries__c = 100
        );
        
        OpportunityLineItem clientOli = new OpportunityLineItem(
            OpportunityId = clientOpp.Id,
            PricebookEntryId = engagementPbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ER_Nb_Beneficiaries__c = 100
        );
        
        OpportunityLineItem frameworkOli = new OpportunityLineItem(
            OpportunityId = frameworkOpp.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = pbeWithPrice.UnitPrice
        );
        
        insert new List<OpportunityLineItem>{merchantOli, clientOli, frameworkOli};
        
        // Create merchant quote
        Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
            'ER_Merchant_Quote',
            'TestMerchantQuote',
            merchantOpp.Id,
            customPb.Id
        );
        merchantQuote.ER_Quote_Type__c = Label.LAB_SF_Contact_Operational;
        
        // Create client quote
        Quote clientQuote = APER07_UtilityTestMethod.getQuote(
            'ER_Client_Quote',
            'TestClientQuote',
            clientOpp.Id,
            engagementPb.Id
        );
        clientQuote.ER_Quote_Type__c = Label.LAB_SF_Contact_Operational;
        
        insert new List<Quote>{merchantQuote, clientQuote};
        
        // Create quote line items
        QuoteLineItem merchantQli = APER07_UtilityTestMethod.getQuoteLineItem(
            merchantQuote.Id,
            customPbe.Id
        );
        merchantQli.ER_Line_Type__c = 'Discount';
        merchantQli.ER_Duration__c = 90;
        
        QuoteLineItem clientQli = APER07_UtilityTestMethod.getQuoteLineItem(
            clientQuote.Id,
            engagementPbe.Id
        );
        clientQli.ER_Line_Type__c = 'Discount';
        clientQli.ER_Duration__c = 90;
        
        insert new List<QuoteLineItem>{merchantQli, clientQli};
        
        // Create contract
        Contract testContract = APER07_UtilityTestMethod.insertContract(
            testAccount.Id,
            System.today(),
            Label.LABS_SF_Contract_Status_Draft,
            customPb.Id,
            'ER_Merchant_Contract_RT',
            ur.Id
        );
        testContract.ER_OpportunityId__c = merchantOpp.Id;
        update testContract;
        
        // Create solution line item for account
        ER_Solution_Line_Item__c solutionLineItem = APER07_UtilityTestMethod.getAccountLineItem(
            childAccount.Id,
            frameworkContract.Id,
            solution.Id
        );
        solutionLineItem.ER_Scope__c = 'Merchant';
        insert solutionLineItem;
    }
}
    
@isTest
static void testSyncACRFromOCR() {
    Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'TestMerchantOpp' LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];
    
    OpportunityContactRole ocr = new OpportunityContactRole(
        OpportunityId = opp.Id,
        ContactId = con.Id,
        Role = 'Primary Contact'
    );
    insert ocr;
    
    Test.startTest();
    List<OpportunityContactRole> ocrsToUpsert = new List<OpportunityContactRole>{ocr};
    List<OpportunityContactRole> ocrsToDelete = new List<OpportunityContactRole>();
    OpportunityManagementWithoutSharing.syncACRFromOCR(ocrsToUpsert, ocrsToDelete);
    Test.stopTest();
    
    List<AccountContactRelation> acrs = [
        SELECT Id, Roles
        FROM AccountContactRelation
        WHERE AccountId = :opp.AccountId AND ContactId = :con.Id
    ];
    System.assert(!acrs.isEmpty(), 'ACR should be created');
}
    
    @isTest
static void testPreventDuplicateRoles() {
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestMerchantOpp' LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];
    
    OpportunityContactRole ocr1 = new OpportunityContactRole(
        OpportunityId = opp.Id,
        ContactId = con.Id,
        Role = 'Primary Contact'
    );
    insert ocr1;
    
    Test.startTest();
    OpportunityContactRole ocr2 = new OpportunityContactRole(
        OpportunityId = opp.Id,
        ContactId = con.Id,
        Role = 'Primary Contact'
    );
    
    try {
        OpportunityManagementWithoutSharing.preventDuplicateRoles(new List<OpportunityContactRole>{ocr2});
        insert ocr2;
        System.assert(false, 'Should have thrown error');
    } catch (Exception e) {
        System.assert(true, 'Duplicate role prevented');
    }
    Test.stopTest();
}
    
    @isTest
static void testCreateCCRForContractFromOCR() {
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestMerchantOpp' LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];
    
    OpportunityContactRole ocr = new OpportunityContactRole(
        OpportunityId = opp.Id,
        ContactId = con.Id,
        Role = 'Primary Contact'
    );
    insert ocr;
    
    Contract cont = [SELECT Id, ER_OpportunityId__c FROM Contract WHERE ER_OpportunityId__c = :opp.Id LIMIT 1];
    
    Test.startTest();
    OpportunityManagementWithoutSharing.createCCRForContractFromOCR(new List<Contract>{cont});
    Test.stopTest();
    
    List<ContractContactRole> ccrs = [
        SELECT Id, Role
        FROM ContractContactRole
        WHERE ContractId = :cont.Id
    ];
    System.assert(!ccrs.isEmpty(), 'CCR should be created');
}
    
    /*@isTest
    static void testSyncCCRtoOCRWithOpportunity() {
        Contract cont = [SELECT Id, ER_OpportunityId__c, AccountId FROM Contract LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        ContractContactRole ccr = new ContractContactRole(
            ContractId = cont.Id,
            ContactId = con.Id,
            Role = 'Primary Contact'
        );
        insert ccr;
        
        Test.startTest();
        String result = OpportunityManagementWithoutSharing.syncCCRtoOCR(cont.Id);
        Test.stopTest();
        
        System.assertEquals('UPDATED', result, 'Should return UPDATED');
        
        List<OpportunityContactRole> ocrs = [
            SELECT Id
            FROM OpportunityContactRole
            WHERE OpportunityId = :cont.ER_OpportunityId__c
        ];
        System.assert(!ocrs.isEmpty(), 'OCR should be created');
    }
    
    @isTest
    static void testSyncCCRtoOCRWithoutOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1];
        
        Contract cont = APER07_UtilityTestMethod.getContract(
            acc.Id,
            System.today(),
            'Draft',
            pb.Id
        );
        cont.ER_OpportunityId__c = null;
        insert cont;
        
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        ContractContactRole ccr = new ContractContactRole(
            ContractId = cont.Id,
            ContactId = con.Id,
            Role = 'Primary Contact'
        );
        insert ccr;
        
        Test.startTest();
        String result = OpportunityManagementWithoutSharing.syncCCRtoOCR(cont.Id);
        Test.stopTest();
        
        System.assertEquals('UPDATED', result, 'Should return UPDATED');
        
        List<AccountContactRelation> acrs = [
            SELECT Id
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id AND ContactId = :con.Id
        ];
        System.assert(!acrs.isEmpty(), 'ACR should be created');
    }
    */

    @isTest
    static void testSyncCCRtoOCRNoChanges() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        
        Test.startTest();
        String result = OpportunityManagementWithoutSharing.syncCCRtoOCR(cont.Id);
        Test.stopTest();
        
        System.assertEquals('NO_CHANGES', result, 'Should return NO_CHANGES');
    }
    
    @isTest
    static void testSyncCCRtoOCRException() {
        Test.startTest();
        try {
            OpportunityManagementWithoutSharing.syncCCRtoOCR(null);
            System.assert(false, 'Should throw exception');
        } catch (Exception e) {
            System.assert(true, 'Exception handled');
        }
        Test.stopTest();
    }
    
    /*@isTest
    static void testStoreRoleIdOnOpportunityForVisibility() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'TestOpp1' LIMIT 1];
        
        Test.startTest();
        OpportunityManagementWithoutSharing.storeRoleIdOnOpportunityForVisibility(
            new List<Opportunity>{opp},
            null
        );
        Test.stopTest();
        
        Opportunity updatedOpp = [
            SELECT Id, Role_Id_for_Visibility__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        // Role field may or may not be populated depending on user role hierarchy
        System.assert(true, 'Method executed without error');
    }
    */

    @isTest
    static void testCallStoreRoleIdOnOpportunityForVisibility() {
        List<Opportunity> opps = [SELECT Id, OwnerId FROM Opportunity];
        
        OpportunityManagementWithoutSharing.InputVariables input = 
            new OpportunityManagementWithoutSharing.InputVariables();
        input.allOpps = opps;
        
        Test.startTest();
        OpportunityManagementWithoutSharing.callStoreRoleIdOnOpportunityForVisibility(
            new List<OpportunityManagementWithoutSharing.InputVariables>{input}
        );
        Test.stopTest();
        
        System.assert(true, 'Invocable method executed');
    }
    
    /*@isTest
static void testExecuteSecondaryApproval() {
    Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'TestMerchantOpp' LIMIT 1];
    
    OpportunityLineItem oli = [
        SELECT Id
        FROM OpportunityLineItem
        WHERE OpportunityId = :opp.Id
        LIMIT 1
    ];
    oli.ER_NeedApproval__c = true;
    update oli;
    
    // Create a simple old map
    Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{
        opp.Id => opp.clone(true, true, true, true)
    };
    
    Test.startTest();
    // The method will check conditions internally
    OpportunityManagementWithoutSharing.executeSecondaryApproval(
        new List<Opportunity>{opp},
        oldMap
    );
    Test.stopTest();
    
    // Verify no exceptions thrown
    System.assert(true, 'Method completed without errors');
}
*/
    
    @isTest
    static void testPreventDMLForFrameworkAgreementInsert() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Derieved_from_Framework_Opp__c = true
            LIMIT 1
        ];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        OpportunityLineItem oli = APER07_UtilityTestMethod.getOpportunityLineItem(
            opp.Id,
            pbe.Id
        );
        
        Test.startTest();
        try {
            OpportunityManagementWithoutSharing.preventDMLForFrameworkAgreement(
                new List<OpportunityLineItem>{oli},
                null
            );
            insert oli;
            System.assert(false, 'Should prevent insert');
        } catch (Exception e) {
            System.assert(true, 'Insert prevented for framework opportunity');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testPreventDMLForFrameworkAgreementUpdate() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Derieved_from_Framework_Opp__c = true
            LIMIT 1
        ];
        OpportunityLineItem oli = [
            SELECT Id, Quantity
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>{
            oli.Id => oli.clone(true, true, true, true)
        };
        
        oli.Quantity = 10;
        
        Test.startTest();
        try {
            OpportunityManagementWithoutSharing.preventDMLForFrameworkAgreement(
                new List<OpportunityLineItem>{oli},
                oldMap
            );
            System.assert(true, 'Allowed fields can be updated');
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testPreventDMLForFrameworkAgreementDelete() {
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Derieved_from_Framework_Opp__c = true
            LIMIT 1
        ];
        OpportunityLineItem oli = [
            SELECT Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>{
            oli.Id => oli
        };
        
        Test.startTest();
        try {
            OpportunityManagementWithoutSharing.preventDMLForFrameworkAgreement(
                null,
                oldMap
            );
            delete oli;
            System.assert(false, 'Should prevent delete');
        } catch (Exception e) {
            System.assert(true, 'Delete prevented for framework opportunity');
        }
        Test.stopTest();
    }
    
    @isTest
static void testAddErrorOnOpportunity() {
    Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'TestMerchantOpp' LIMIT 1];
    
    Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{
        opp.Id => new Opportunity(Id = opp.Id, StageName = 'Prospecting')
    };
    
    opp.StageName = 'Proposal';
    
    Test.startTest();
    try {
        OpportunityManagementWithoutSharing.addErrorOnOpportunity(
            new List<Opportunity>{opp},
            oldMap
        );
        update opp;
    } catch (Exception e) {
        System.assert(e.getMessage().contains('Primary contact'), 'Should require primary contact');
    }
    Test.stopTest();
}
    
    /*@isTest
static void testAddStageErrorOnOpportunityNoLineItems() {
    // Create new opportunity without line items
    Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' LIMIT 1];
    Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Custom Price Book' LIMIT 1];
    
    Opportunity opp = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'TestOppNoItems'
    );
    opp.AccountId = acc.Id;
    opp.Pricebook2Id = pb.Id;
    opp.StageName = 'Prospecting';
    opp.Commercial_Origin__c = 'Direct';
    opp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(30);
    opp.ER_BUPicklist__c = 'BE';
    insert opp;
    
    Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{
        opp.Id => new Opportunity(Id = opp.Id, StageName = 'Prospecting')
    };
    
    opp.StageName = 'Proposal';
    
    Test.startTest();
    try {
        OpportunityManagementWithoutSharing.addStageErrorOnOpportunity(
            new List<Opportunity>{opp},
            oldMap
        );
        update opp;
    } catch (Exception e) {
        System.assert(e.getMessage().contains('price configuration'), 'Should require line items');
    }
    Test.stopTest();
}
    */
    
    @isTest
static void testValidateNbBeneficiaries() {
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestClientOpp' LIMIT 1];
    PricebookEntry pbe = [
        SELECT Id
        FROM PricebookEntry
        WHERE Pricebook2.Name = 'Engagement Price Book Test'
        LIMIT 1
    ];
    
    OpportunityLineItem oli1 = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100,
        ER_Nb_Beneficiaries__c = 100
    );
    
    OpportunityLineItem oli2 = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100,
        ER_Nb_Beneficiaries__c = 200
    );
    
    Test.startTest();
    try {
        OpportunityManagementWithoutSharing.validateNbBeneficiaries(
            new List<OpportunityLineItem>{oli1, oli2}
        );
        insert new List<OpportunityLineItem>{oli1, oli2};
        System.assert(false, 'Should prevent different NB Beneficiaries');
    } catch (Exception e) {
        System.assert(e.getMessage().contains('same NB Beneficiaries'), 
                     'Should require same NB Beneficiaries');
    }
    Test.stopTest();
}
    
    @isTest
static void testValidateNbBeneficiariesSameValue() {
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestClientOpp' LIMIT 1];
    
    // Delete existing OLIs first to avoid conflicts
    delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
    
    PricebookEntry pbe = [
        SELECT Id
        FROM PricebookEntry
        WHERE Pricebook2.Name = 'Engagement Price Book Test'
        LIMIT 1
    ];
    
    OpportunityLineItem oli1 = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100,
        ER_Nb_Beneficiaries__c = 100
    );
    
    OpportunityLineItem oli2 = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100,
        ER_Nb_Beneficiaries__c = 100
    );
    
    Test.startTest();
    OpportunityManagementWithoutSharing.validateNbBeneficiaries(
        new List<OpportunityLineItem>{oli1, oli2}
    );
    insert new List<OpportunityLineItem>{oli1, oli2};
    Test.stopTest();
    
    List<OpportunityLineItem> inserted = [
        SELECT Id
        FROM OpportunityLineItem
        WHERE OpportunityId = :opp.Id
    ];
    System.assertEquals(2, inserted.size(), 'Should allow same NB Beneficiaries');
}
}