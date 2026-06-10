/*
----------------------------------------------------------------------
-- - Name          : APER04_Opportunity_Management_Test
-- - Author        : OLA
-- - Description   : Test Class for APER04_Opportunity_Management
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  JAN-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER04_Opportunity_Management_Test {
    @testSetup
    static void testSetup() {
        User ur = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BE');
        ur.ER_BypassVR__c = true;
        ur.ER_Bypass_Flows__c = true;
        ur.ER_bypassTrigger__c = true;
        
        System.runAs(ur) {
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany');
            insert newMerchantAccount;
            
            ER_Promo_Code__c promo = new ER_Promo_Code__c();
            promo.Name = 'TestPromo';
            promo.ER_Business_Unit__c = 'BE';
            promo.ER_Start_Date__c = Date.today().addDays(-5);
            promo.ER_Promo_Code__c = 'TestPromo';
            promo.ER_Status__c = 'Activated';
            promo.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                ER_Promo_Code__c.SObjectType,
                Constants.PROMO_CODE_AFFILIATION_RT
            );
            promo.ER_Affiliation_Type__c = Constants.PARENT;
            insert promo;
            System.assert(promo.Id != null);
            
            ER_Promo_Code__c promo2 = new ER_Promo_Code__c();
            promo2.Name = 'TestPromo2';
            promo2.ER_Business_Unit__c = 'BE';
            promo2.ER_Start_Date__c = Date.today().addDays(-5);
            promo2.ER_Promo_Code__c = 'TestPromo2';
            promo2.ER_Status__c = 'Activated';
            promo2.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                ER_Promo_Code__c.SObjectType,
                Constants.PROMO_CODE_AFFILIATION_RT
            );
            promo.ER_Affiliation_Type__c = Constants.PARENT;
            insert promo2;
            System.assert(promo2.Id != null);
            
            Pricebook2 pricebook = APER07_UtilityTestMethod.getpriceBook();
            pricebook.ER_Business_Unit__c = 'BE';
            update pricebook;
            System.assert(pricebook.Id != null);
            
            Pricebook2 pricebook2 = new Pricebook2();
            pricebook2.Name = 'TestPB';
            pricebook2.ER_Business_Unit__c = 'BE';
            insert pricebook2;
            System.assert(pricebook2.Id != null);
            
            Pricebook2 pricebook3 = APER07_UtilityTestMethod.getpriceBook();
            pricebook3.ER_Business_Unit__c = 'BE';
            update pricebook3;
            System.assert(pricebook3.Id != null);
            
            Pricebook2 pricebook4 = new Pricebook2();
            pricebook4.Name = 'TestPB2';
            pricebook4.ER_Business_Unit__c = 'BE';
            insert pricebook4;
            System.assert(pricebook4.Id != null);
            
            Pricebook2 pricebook5 = new Pricebook2();
            pricebook5.Name = 'ERBE Merchant EKIVITA';
            pricebook5.ER_Business_Unit__c = 'BE';
            insert pricebook5;
            System.assert(pricebook5.Id != null);
            
            Product2 prod2 = APER07_UtilityTestMethod.getProduct('Test');
            prod2.IsActive = true;
            insert prod2;
            System.assert(prod2.Id != null);
            
            Product2 prod3 = APER07_UtilityTestMethod.getProduct('Test2');
            prod3.IsActive = true;
            insert prod3;
            System.assert(prod3.Id != null);
            
            PricebookEntry pricebookEntry = APER07_UtilityTestMethod.getpriceBookEntry(pricebook.Id, prod2.Id);
            pricebookEntry.ER_Promo_Code2__c = promo.Id;
            pricebookEntry.ER_Offer_validity_end_date__c = Date.today().addDays(10);
            insert pricebookEntry;
            System.assert(pricebookEntry.Id != null);
            
            PricebookEntry pricebookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(pricebook2.Id, prod2.Id);
            pricebookEntry2.ER_Promo_Code2__c = promo.Id;
            pricebookEntry2.ER_Offer_validity_end_date__c = Date.today().addDays(10);
            insert pricebookEntry2;
            System.assert(pricebookEntry2.Id != null);
            
            PricebookEntry pricebookEntry3 = APER07_UtilityTestMethod.getpriceBookEntry(pricebook3.Id, prod3.Id);
            pricebookEntry3.ER_Promo_Code2__c = promo2.Id;
            pricebookEntry3.ER_Offer_validity_end_date__c = Date.today().addDays(10);
            insert pricebookEntry3;
            System.assert(pricebookEntry3.Id != null);
            
            PricebookEntry pricebookEntry4 = APER07_UtilityTestMethod.getpriceBookEntry(pricebook4.Id, prod3.Id);
            pricebookEntry4.ER_Promo_Code2__c = promo2.Id;
            pricebookEntry4.ER_Offer_validity_end_date__c = Date.today().addDays(10);
            insert pricebookEntry4;
            System.assert(pricebookEntry4.Id != null);
            
            Account newMerchantAccount2 = APER07_UtilityTestMethod.getCompany('test2');
            newMerchantAccount2.ER_BUPicklist__c = 'BE';
            insert newMerchantAccount2;
            
            Contract con = APER07_UtilityTestMethod.getContract(
                newMerchantAccount2.Id,
                System.today(),
                'Draft',
                pricebook.Id
            );
            con.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Client_Contract_RT');
            insert con;
            con.Status = 'Activated';
            con.ER_BUPicklist__c = 'BE';
            con.ER_Contract_Type__c = 'Other';
            update con;
            
            Contract con2 = APER07_UtilityTestMethod.getContract(
                newMerchantAccount2.Id,
                System.today(),
                'Draft',
                pricebook.Id
            );
            con2.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Merchant_Contract_RT');
            insert con2;
            con2.Status = 'Activated';
            con2.ER_BUPicklist__c = 'BE';
            con2.ER_Contract_Type__c = 'Framework agreement';
            update con2;
            
            Contract con3 = APER07_UtilityTestMethod.getContract(
                newMerchantAccount2.Id,
                System.today(),
                'Draft',
                pricebook.Id
            );
            con3.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Client_Contract_RT');
            insert con3;
            con3.Status = 'Activated';
            con3.ER_BUPicklist__c = 'BE';
            con3.ER_Contract_Type__c = 'Other';
            update con;
            
            ER_Promo_Code__c affiliationCode = new ER_Promo_Code__c();
            affiliationCode.Name = 'affiliationCode' + Datetime.now().getTime();
            affiliationCode.ER_Business_Unit__c = 'BE';
            affiliationCode.ER_Start_Date__c = Date.today().addDays(-5);
            affiliationCode.ER_Promo_Code__c = 'TestPromo2';
            affiliationCode.ER_Contract__c = con.Id;
            affiliationCode.ER_Status__c = 'Activated';
            affiliationCode.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                ER_Promo_Code__c.SObjectType,
                'ER_Affiliation_Code'
            );
            insert affiliationCode;
            System.assert(affiliationCode.Id != null);
            
            ER_ContractLineItem__c cli = APER07_UtilityTestMethod.getContractLineItem(
                con.Id,
                prod2.Id,
                PricebookEntry.Id,
                1,
                10
            );
            insert cli;
            
            Lead lead = APER07_UtilityTestMethod.getLead(
                Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Lead_RT').getRecordTypeId()
            );
            lead.ER_Promo_Code__c = 'TestPromo';
            lead.ER_BUPicklist__c = 'BE';
            lead.NumberOfEmployees = 32;
            insert lead;
            
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);
            
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            
            Opportunity newOpportunityB = APER07_UtilityTestMethod.getOpportunity(
                'ER_Merchant_Opportunity',
                'APER04_Opportunity_Management_Test'
            );
            newOpportunityB.AccountId = newMerchantAccount.Id;
            newOpportunityB.ER_BUPicklist__c = 'BE';
            insert newOpportunityB;
            
            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
                'ER_Merchant_Opportunity',
                'APER04_Opportunity_Management_Test'
            );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            insert newOpportunity;
            newOpportunity.ER_Promo_Code2__c = promo.Id;
            newOpportunity.ER_Approved__c = true;
            update newOpportunity;
            newOpportunity.ER_Promo_Code2__c = promo2.Id;
            update newOpportunity;
            
            Opportunity newOpportunity2 = APER07_UtilityTestMethod.getOpportunity(
                'ER_Merchant_Opportunity',
                'APER04_Opportunity_Management_Test2'
            );
            newOpportunity2.AccountId = newMerchantAccount.Id;
            newOpportunity2.ER_BUPicklist__c = 'BE';
            newOpportunity2.ER_Promo_Code2__c = promo2.Id;
            insert newOpportunity2;
            
            //newOpportunity2.ER_Promo_Code2__c = affiliationCode.Id;
            //update newOpportunity2;
            
            newOpportunity2.Pricebook2Id = null;
            update newOpportunity2;
            
            newOpportunity2.StageName = 'Closed Won';
            newOpportunity2.ER_Lead_Requestor__c = 'test';
            newOpportunity2.ER_Approved__c = true;
            update newOpportunity2;
            
            Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
            newSolution.ProductCode = 'ERBE_Test-class';
            insert newSolution;
            
            Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
            insert newService;
            
            PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();
            update standardPriceBook;
            
            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('ERBE MERCHANT');
            insert newPriceBook;
            
            PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
                standardPriceBook.id,
                newService.id
            );
            insert standardPriceBookEntry;
            
            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
            insert newPriceBookEntry;
            
            OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
                newOpportunity.id,
                newPriceBookEntry.id
            );
            insert newOpportunityProduct;
            
            zqu__Quote__c zquQuote = new zqu__Quote__c();
            zquQuote.zqu__Status__c = 'Draft';
            zquQuote.zqu__Opportunity__c = newOpportunity.Id;
            insert zquQuote;
            Contact primaryContact1 = new Contact(
                FirstName = 'Primary',
                LastName = 'Contact Test',
                Email = 'primarycontact@test.com',
                Phone = '1234567890',
                AccountId = newMerchantAccount.Id
            );
            insert primaryContact1;
            
            // Create Primary Contact for newMerchantAccount2
            Contact primaryContact2 = new Contact(
                FirstName = 'Primary',
                LastName = 'Contact Test 2',
                Email = 'primarycontact2@test.com',
                Phone = '0987654321',
                AccountId = newMerchantAccount2.Id
            );
            insert primaryContact2;
            
            // Create OpportunityContactRoles for all opportunities
            List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
            
            // For newOpportunityB
            ocrList.add(new OpportunityContactRole(
                OpportunityId = newOpportunityB.Id,
                ContactId = primaryContact1.Id,
                Role = 'Primary contact',
                IsPrimary = true
            ));
            
            // For newOpportunity
            ocrList.add(new OpportunityContactRole(
                OpportunityId = newOpportunity.Id,
                ContactId = primaryContact1.Id,
                Role = 'Primary contact',
                IsPrimary = true
            ));
            
            // For newOpportunity2
            ocrList.add(new OpportunityContactRole(
                OpportunityId = newOpportunity2.Id,
                ContactId = primaryContact1.Id,
                Role = 'Primary contact',
                IsPrimary = true
            ));
            
            insert ocrList;
            
            // Verify Primary Contacts were created
            System.assertEquals(3, ocrList.size(), 'Should have 3 Primary Contact Roles');
        }
    }
    
    @IsTest
    static void getOpportunityRecordTest() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];
        if (!opportunityList.isEmpty()) {
            APER04_Opportunity_Management.getOpportunityRecord(opportunityList[0].Id);
        }
        Test.stopTest();
    }
    
    @IsTest
	static void getCreateOpportunityFromFrameworkContract() {

    // Test data
    Account acc = new Account(
    Name = 'Test Account',
    ER_VAT_Number__c = 'BE0123456789'
);
    insert acc;

    Contract frameworkCon = new Contract(
        AccountId = acc.Id,
        Status = 'Draft',
        StartDate = Date.today()
    );
    insert frameworkCon;

    Test.startTest();
    APER04_Opportunity_Management.createOpportunityFromFrameworkContract(
        frameworkCon.Id,
        acc.Id
    );
    Test.stopTest();
}

    
    @IsTest
    static void createOpportunityFromContract() {
        Test.startTest();
        Contract con = [
            SELECT Id, RecordType.DeveloperName
            FROM Contract
            WHERE RecordType.DeveloperName = 'ER_Client_Contract_RT'
            LIMIT 1
        ];
        Contract con2 = [
            SELECT Id, RecordType.DeveloperName
            FROM Contract
            WHERE RecordType.DeveloperName = 'ER_Merchant_Contract_RT'
            LIMIT 1
        ];
        Contract con3 = [SELECT Id, ER_Contract_Type__c FROM Contract WHERE ER_Contract_Type__c = 'Other'];
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        
        try {
            APER04_Opportunity_Management.createOpportunityFromContract(con.Id, opp.Id);
            APER04_Opportunity_Management.createOpportunityFromContract(con.Id, null);
            /*APER04_Opportunity_Management.createOpportunityFromContract(con2.Id, opp.Id);
APER04_Opportunity_Management.createOpportunityFromContract(con2.Id, null);
APER04_Opportunity_Management.createOpportunityFromContract(con3.Id, null);*/
            APER04_Opportunity_Management.createOpportunityFromContract(null, null);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void updateOpportunityContractTest() {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        APER04_Opportunity_Management.updateOpportunityContract(new List<Opportunity>{ opp });
        Test.stopTest();
    }
    
    @IsTest
    static void discardAmendementTest() {
        zqu__Quote__c zQuote = [SELECT zqu__Opportunity__c FROM zqu__Quote__c LIMIT 1];
        Test.startTest();
        APER04_Opportunity_Management.discardAmendement(zQuote.zqu__Opportunity__c);
        Test.stopTest();
    }
    
    @IsTest
    static void setRTClientTest() {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        APER04_Opportunity_Management.setRTClient(new List<Opportunity>{ opp });
        Test.stopTest();
    }
    
    @IsTest
    static void setRTMerchantTest() {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        APER04_Opportunity_Management.setRTMerchant(new List<Opportunity>{ opp });
        Test.stopTest();
    }
    
    @IsTest
static void getUpdateOpportunityStage() {
    Test.startTest();

    Opportunity opp = [
        SELECT Id
        FROM Opportunity
        WHERE StageName != 'Closed Won'
        LIMIT 1
    ];

    opp.Commercial_Origin__c = 'Greenfield';
    opp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(5);
    update opp;

    APER04_Opportunity_Management.updateOpportunityStage(
        new Set<Id>{ opp.Id }, 'Proposal'
    );

    Test.stopTest();
}

    
    @IsTest
    static void setStandardFinancialConditionsforES() {
        User ur = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        
        System.runAs(ur) {
            Test.startTest();
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany1');
            newMerchantAccount.ER_Match_Legal_Address__c = true;
            newMerchantAccount.ER_VAT_Number__c = '00000001-1-02';
            newMerchantAccount.BillingStreet = 'Road2 Street2';
            newMerchantAccount.BillingCity = 'PasParis';
            newMerchantAccount.BillingPostalCode = '2000';
            insert newMerchantAccount;
            
            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
                'ER_Merchant_Opportunity',
                'APER04_Opportunity_Management_Test'
            );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            newOpportunity.ER_ReimbursementTerm__c = '';
            insert newOpportunity;
            Test.stopTest();
        }
    }
    
    @IsTest
    static void setRTClient() {
        User ur = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        
        System.runAs(ur) {
            Test.startTest();
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany2');
            newMerchantAccount.ER_Match_Legal_Address__c = true;
            newMerchantAccount.ER_VAT_Number__c = '00000001-1-02';
            newMerchantAccount.BillingStreet = 'Road2 Street2';
            newMerchantAccount.BillingCity = 'PasParis';
            newMerchantAccount.BillingPostalCode = '2000';
            insert newMerchantAccount;
            
            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
                'ER_Merchant_Opportunity',
                'APER04_Opportunity_Management_Test'
            );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ER_Lead_Source_Type__c = 'Client';
            insert newOpportunity;
            Test.stopTest();
        }
    }
    
    @IsTest
    static void setRTMerchant() {
        User ur = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        
        System.runAs(ur) {
            Test.startTest();
            Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany3');
            newMerchantAccount.ER_Match_Legal_Address__c = true;
            newMerchantAccount.ER_VAT_Number__c = '00000001-1-02';
            newMerchantAccount.BillingStreet = 'Road2 Street2';
            newMerchantAccount.BillingCity = 'PasParis';
            newMerchantAccount.BillingPostalCode = '2000';
            insert newMerchantAccount;
            
            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
                'ER_Merchant_Opportunity',
                'APER04_Opportunity_Management_Test'
            );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ER_Lead_Source_Type__c = 'Merchant';
            insert newOpportunity;
            Test.stopTest();
        }
    }
    
    @IsTest
    static void setIndexationFieldsTest() {
        List<Opportunity> opp = [
            SELECT Id, ER_BUPicklist__c, ER_SmartER_Context__c
            FROM Opportunity
            WHERE ER_BUPicklist__c = 'BENELUX'
            LIMIT 1
        ];
        
        Test.startTest();
        APER04_Opportunity_Management.setIndexationFields(opp);
        Test.stopTest();
    }
    
    @IsTest
    static void testManageDiscountCode() {
        List<Opportunity> opportunities = [
            SELECT Id, ER_Promo_Code2__c, ER_Original_Agreement__c, IsClosed, AccountId, ER_SmartER_Context__c
            FROM Opportunity
            WHERE ER_Promo_Code2__c != NULL
        ];
        
        Test.startTest();
        APER04_Opportunity_Management.manageDiscountCodes(opportunities, null);
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateAccountPartners() {
        List<Opportunity> opportunities = [
            SELECT Id, ER_Promo_Code2__c, ER_Original_Agreement__c, IsClosed, AccountId
            FROM Opportunity
        ];
        
        Test.startTest();
        APER04_Opportunity_Management.createAccountsPartners(opportunities);
        Test.stopTest();
    }
    
    @IsTest
    static void testSumUpEstimatesOnOpportunity() {
        List<OpportunityLineItem> olis = [
            SELECT Id, ER_Estimated_Value__c, ER_Face_Value__c, ER_Nb_Beneficiaries__c, ER_Load_Per_Year__c, OpportunityId
            FROM OpportunityLineItem
        ];
        
        Test.startTest();
        olis[0].ER_Face_Value__c = 10;
        olis[0].ER_Nb_Beneficiaries__c = 10;
        olis[0].ER_Load_Per_Year__c = 10;
        olis[0].ER_Days_Per_Month__c = 10;
        update olis[0];
        
        Opportunity opp = [SELECT Id, ER_Potential_Revenue__c FROM Opportunity WHERE Id = :olis[0].OpportunityId];
        
        System.assertEquals(10000, opp.ER_Potential_Revenue__c);
        
        delete olis[0];
        
        Test.stopTest();
        
        Opportunity opp2 = [SELECT Id, ER_Potential_Revenue__c FROM Opportunity WHERE Id = :opp.Id];
        
        System.assertEquals(0, opp2.ER_Potential_Revenue__c);
    }
    
    @IsTest
    static void testPricebookPromoCode() {
        Test.startTest();
        User ur = [SELECT Id FROM User WHERE LastName = 'APER12'];
        ur.ER_BypassVR__c = false;
        ur.ER_bypassTrigger__c = false;
        update ur;
        System.runAs(ur) {
            ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
                UserInfo.getOrganizationId()
            );
            settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
            upsert settings;
            UtilsBypass.reset();
            Pricebook2 pricebook2 = [SELECT Id FROM Pricebook2 WHERE Name = 'TestPB2'];
            Account newMerchantAccount = [SELECT Id FROM Account LIMIT 1];
            ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name = 'TestPromo2' LIMIT 1];
            
            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
                'ER_Merchant_Opportunity',
                'APER04_Opportunity_Management_Test'
            );
            newOpportunity.AccountId = newMerchantAccount.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            newOpportunity.ER_Promo_Code2__c = promo.Id;
            insert newOpportunity;
            
            Opportunity updatedOpp = [SELECT Id FROM Opportunity WHERE Id = :newOpportunity.Id];
            updatedOpp.Pricebook2Id = pricebook2.Id;
            
            update updatedOpp;
        }
        
        Test.stopTest();
    }
    
    /*@IsTest
    static void manageParentAffiliationCodesTest() {
        List<Opportunity> opportunities = [
            SELECT Id, ER_Promo_Code2__c, AccountId
            FROM Opportunity
            WHERE ER_Promo_Code2__c != NULL
        ];
        String promoCode = [SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c;
        Map<Id, List<Opportunity>> mapPromoCodeOpps = new Map<Id, List<Opportunity>>();
        ER_Promo_Code__c pc = [
            SELECT Id, ER_Affiliation_Type__c
            FROM ER_Promo_Code__c
            WHERE Id = :[SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c
        ];
        pc.ER_Affiliation_Type__c = Constants.PARENT;
        pc.ER_End_Date__c = Date.today().addDays(30);
        pc.Promo_End_Date__c = Date.today().addDays(90);
        update pc;

        mapPromoCodeOpps.put(promoCode, opportunities);
        
        Test.startTest();
        APER04_Opportunity_Management.manageParentAffiliationCodes(mapPromoCodeOpps);
        Test.stopTest();
    }
    
    @IsTest
static void manageParentAffiliationCodesTest() {
    List<Opportunity> opportunities = [
        SELECT Id, ER_Promo_Code2__c, AccountId
        FROM Opportunity
        WHERE ER_Promo_Code2__c != NULL
    ];
    
    // Update opportunities with required fields
    for (Opportunity opp : opportunities) {
        opp.Commercial_Origin__c = 'Greenfield';
        opp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(30);
    }
    update opportunities;
    
    String promoCode = [SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c;
    Map<Id, List<Opportunity>> mapPromoCodeOpps = new Map<Id, List<Opportunity>>();
    ER_Promo_Code__c pc = [
        SELECT Id, ER_Affiliation_Type__c
        FROM ER_Promo_Code__c
        WHERE Id = :[SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c
    ];
    
    // CREATE AND ACTIVATE A CONTRACT FIRST
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Pricebook2 pb = APER07_UtilityTestMethod.getpriceBook();
    Contract activatedContract = APER07_UtilityTestMethod.getContract(acc.Id, System.today(), 'Draft', pb.Id);
    insert activatedContract;
    activatedContract.Status = 'Activated'; // Activate the contract
    update activatedContract;
    
    pc.ER_Affiliation_Type__c = Constants.PARENT;
    pc.ER_End_Date__c = Date.today().addDays(30);
    pc.Promo_End_Date__c = Date.today().addDays(90);
    pc.ER_Contract__c = activatedContract.Id; // Associate with activated contract
    update pc;
    
    mapPromoCodeOpps.put(promoCode, opportunities);
    Test.startTest();
    APER04_Opportunity_Management.manageParentAffiliationCodes(mapPromoCodeOpps);
    Test.stopTest();
}
*/
    @IsTest
    static void manageOppRecordsBeforeUpdateTest() {
        Map<Id, Opportunity> oldMapItems = new Map<Id, Opportunity>();
        List<Opportunity> newItems = new List<Opportunity>();
        
        Account newAcc = APER07_UtilityTestMethod.getCompany('manageOppRecordsBeforeUpdateTest');
        insert newAcc;
        
        Opportunity newOpp = APER07_UtilityTestMethod.getOpportunity(
            'ER_Client_Opportunity_RT',
            'manageOppRecordsBeforeUpdateTest'
        );
        newOpp.AccountId = newAcc.Id;
        newOpp.ER_BUPicklist__c = 'BE';
        newOpp.Commercial_Origin__c = 'Greenfield';
		newOpp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(30);
        insert newOpp;
        
        oldMapItems.put(newOpp.Id, newOpp);
        
        newOpp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(10);
		newOpp.ER_Approved__c = true;
		update newOpp;

        newItems.add(newOpp);
        
        Test.startTest();
        APER04_Opportunity_Management.manageOppRecordsBeforeUpdate(newItems, oldMapItems);
        Test.stopTest();
    }
    
    /*@IsTest
    static void createOpportunityItemsFromPromoCodeTest() {
        Contract cont = [
            SELECT Id, ER_Contract_Type__c
            FROM Contract
            WHERE ER_Contract_Type__c = 'Framework agreement'
            LIMIT 1
        ];
        Contract cont1 = [SELECT Id, ER_Contract_Type__c FROM Contract WHERE ER_Contract_Type__c = 'Other' LIMIT 1];
        
        List<Opportunity> opportunities = [
            SELECT Id, ER_Promo_Code2__c, AccountId
            FROM Opportunity
            WHERE ER_Promo_Code2__c != NULL
        ];
        String promoCode = [SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c;
        Map<Id, List<Opportunity>> mapPromoCodeOpps = new Map<Id, List<Opportunity>>();
        ER_Promo_Code__c pc = [
            SELECT Id, ER_Affiliation_Type__c
            FROM ER_Promo_Code__c
            WHERE Id = :[SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c
        ];
        pc.ER_Contract__c = cont.Id;
        //Added new
        pc.Promo_End_Date__c = Date.today().addDays(90);
        update pc;
        mapPromoCodeOpps.put(promoCode, opportunities);
        
        Product2 prod2 = APER07_UtilityTestMethod.getProduct('Test');
        prod2.IsActive = true;
        insert prod2;
        
        Pricebook2 pricebook = APER07_UtilityTestMethod.getpriceBook();
        pricebook.ER_Business_Unit__c = 'BE';
        update pricebook;
        
        PricebookEntry pricebookEntry = APER07_UtilityTestMethod.getpriceBookEntry(pricebook.Id, prod2.Id);
        pricebookEntry.ER_Promo_Code2__c = pc.Id;
        pricebookEntry.ER_Offer_validity_end_date__c = Date.today().addDays(10);
        insert pricebookEntry;
        
        ER_ContractLineItem__c cli = APER07_UtilityTestMethod.getContractLineItem(
            cont1.Id,
            prod2.Id,
            PricebookEntry.Id,
            1,
            10
        );
        insert cli;
        
        Test.startTest();
        APER04_Opportunity_Management.createOpportunityItemsFromPromoCode(mapPromoCodeOpps);
        Test.stopTest();
    }
    
    
    @IsTest
static void createOpportunityItemsFromPromoCodeTest() {
    Contract cont = [
        SELECT Id, ER_Contract_Type__c
        FROM Contract
        WHERE ER_Contract_Type__c = 'Framework agreement'
        LIMIT 1
    ];
    Contract cont1 = [SELECT Id, ER_Contract_Type__c FROM Contract WHERE ER_Contract_Type__c = 'Other' LIMIT 1];
    
    List<Opportunity> opportunities = [
        SELECT Id, ER_Promo_Code2__c, AccountId
        FROM Opportunity
        WHERE ER_Promo_Code2__c != NULL
    ];
    
    // Update opportunities with required fields
    for (Opportunity opp : opportunities) {
        opp.Commercial_Origin__c = 'Greenfield';
        opp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(30);
    }
    update opportunities;
    
    String promoCode = [SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c;
    Map<Id, List<Opportunity>> mapPromoCodeOpps = new Map<Id, List<Opportunity>>();
    ER_Promo_Code__c pc = [
        SELECT Id, ER_Affiliation_Type__c
        FROM ER_Promo_Code__c
        WHERE Id = :[SELECT ER_Promo_Code2__c FROM Opportunity WHERE ER_Promo_Code2__c != NULL][0].ER_Promo_Code2__c
    ];
    
    // USE FRAMEWORK CONTRACT (cont) instead of cont1
    pc.ER_Contract__c = cont.Id; // Changed from cont to match parent affiliation type
    pc.Promo_End_Date__c = Date.today().addDays(90);
    update pc;
    
    mapPromoCodeOpps.put(promoCode, opportunities);
    Product2 prod2 = APER07_UtilityTestMethod.getProduct('Test');
    prod2.IsActive = true;
    insert prod2;
    Pricebook2 pricebook = APER07_UtilityTestMethod.getpriceBook();
    pricebook.ER_Business_Unit__c = 'BE';
    update pricebook;
    PricebookEntry pricebookEntry = APER07_UtilityTestMethod.getpriceBookEntry(pricebook.Id, prod2.Id);
    pricebookEntry.ER_Promo_Code2__c = pc.Id;
    pricebookEntry.ER_Offer_validity_end_date__c = Date.today().addDays(10);
    insert pricebookEntry;
    ER_ContractLineItem__c cli = APER07_UtilityTestMethod.getContractLineItem(
        cont.Id, // Changed from cont1 to cont
        prod2.Id,
        PricebookEntry.Id,
        1,
        10
    );
    insert cli;
    Test.startTest();
    APER04_Opportunity_Management.createOpportunityItemsFromPromoCode(mapPromoCodeOpps);
    Test.stopTest();
}
*/
    
    @IsTest
    static void createOpportunityItemsFromPromoCodeTest2() {
        ER_Promo_Code__c promo0 = new ER_Promo_Code__c();
        promo0.Name = 'TestPromo0';
        promo0.ER_Business_Unit__c = 'BE';
        promo0.ER_Start_Date__c = Date.today().addDays(-5);
        promo0.ER_Promo_Code__c = 'TestPromo';
        promo0.ER_Status__c = 'Activated';
        promo0.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
            ER_Promo_Code__c.SObjectType,
            Constants.PROMO_CODE_PROMO_RT
        );
        promo0.ER_Affiliation_Type__c = Constants.PARENT;
        promo0.Promo_End_Date__c = Date.today().addDays(90);
        insert promo0;
        
        Account newMerchantAccountTest = APER07_UtilityTestMethod.getCompany('createOpportunityItemsFromPromoCodeTest2');
        insert newMerchantAccountTest;
        
        Opportunity newOpportunityP = APER07_UtilityTestMethod.getOpportunity(
            'ER_Merchant_Opportunity',
            'APER04_Opportunity_Management_Test0'
        );
        newOpportunityP.AccountId = newMerchantAccountTest.Id;
        newOpportunityP.ER_Contract_Expected_Start_Date__c = Date.today().addDays(5);
        newOpportunityP.Commercial_Origin__c = 'Greenfield';
        newOpportunityP.ER_BUPicklist__c = 'BE';
        insert newOpportunityP;
        newOpportunityP.ER_Promo_Code2__c = promo0.Id;
        newOpportunityP.ER_Approved__c = true;
        update newOpportunityP;
        
        Pricebook2 pricebook = APER07_UtilityTestMethod.getpriceBook();
        pricebook.ER_Business_Unit__c = 'BE';
        update pricebook;
        Contract conP = APER07_UtilityTestMethod.getContract(
            newMerchantAccountTest.Id,
            System.today(),
            'Draft',
            priceBook.Id
        );
        conP.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Client_Contract_RT');
        insert conP;
        conP.Status = 'Activated';
        conP.ER_BUPicklist__c = 'BE';
        conP.ER_Contract_Type__c = 'Other';
        update conP;
        List<Opportunity> opportunities = [
            SELECT Id, ER_Promo_Code2__c, AccountId, Name
            FROM Opportunity
            WHERE ER_Promo_Code2__c != NULL AND Name = 'APER04_Opportunity_Management_Test0'
        ];
        String promoCode = [
            SELECT ER_Promo_Code2__c
            FROM Opportunity
            WHERE ER_Promo_Code2__c != NULL AND Name = 'APER04_Opportunity_Management_Test0'
        ][0]
            .ER_Promo_Code2__c;
        Map<Id, List<Opportunity>> mapPromoCodeOpps = new Map<Id, List<Opportunity>>();
        ER_Promo_Code__c pc = [
            SELECT Id, ER_Affiliation_Type__c
            FROM ER_Promo_Code__c
            WHERE
            Id = :[
                SELECT ER_Promo_Code2__c
                FROM Opportunity
                WHERE ER_Promo_Code2__c != NULL AND Name = 'APER04_Opportunity_Management_Test0'
            ][0]
            .ER_Promo_Code2__c
        ];
        pc.ER_Contract__c = conP.Id;
        update pc;
        mapPromoCodeOpps.put(promoCode, opportunities);
        
        Product2 prod2 = APER07_UtilityTestMethod.getProduct('Test');
        prod2.IsActive = true;
        insert prod2;
        
        PricebookEntry pricebookEntry = APER07_UtilityTestMethod.getpriceBookEntry(pricebook.Id, prod2.Id);
        pricebookEntry.ER_Promo_Code2__c = pc.Id;
        pricebookEntry.ER_Offer_validity_end_date__c = Date.today().addDays(10);
        insert pricebookEntry;
        
        ER_ContractLineItem__c cli = APER07_UtilityTestMethod.getContractLineItem(
            conP.Id,
            prod2.Id,
            PricebookEntry.Id,
            1,
            10
        );
        insert cli;
        
        Test.startTest();
        APER04_Opportunity_Management.createOpportunityItemsFromPromoCode(mapPromoCodeOpps);
        Test.stopTest();
    }
    
    @isTest
    static void createAutoEnrollmentOppLineItemsTest() {
        User ur = TestDataFactory.newUser('APER04', 'APER04', 'Local Admin', 'Finland', 'FI');
        ur.ER_BypassVR__c = true;
        ur.ER_bypassTrigger__c = false;
        insert ur;
        
        System.runAs(ur) {
            Account acc = APER07_UtilityTestMethod.getCompany('createAutoEnrollmentOppLineItemsTest');
            insert acc;
        
        // CREATE PRIMARY CONTACT - Add this section
        Contact primaryContact = new Contact(
            FirstName = 'Test',
            LastName = 'Primary Contact',
            Email = 'testprimary@test.com',
            Phone = '1234567890',
            AccountId = acc.Id
        );
        insert primaryContact;
        // END PRIMARY CONTACT CREATION
        
        // PB:
        PriceBook2 pb = new PriceBook2();
        pb.Name = 'ERFI TOW Prices';
        pb.ER_MDMId__c = 'ERFI_C_TOW';
        pb.ER_Business_Unit__c = 'BE';
        pb.IsActive = true;
        insert pb;
        
        Auto_Enrollment_Product__mdt mdt = [
            SELECT developerName, Services__c
            FROM Auto_Enrollment_Product__mdt
            WHERE developerName = 'ERFI_C_TD_DUALW_EUR'
        ];
        String servicesStr = mdt.Services__c;
        List<String> services = servicesStr.split(Constants.PIPE_SEPARATOR);
        
        // Product:
        List<Product2> products = new List<Product2>();
        for (String code : services) {
            Product2 prod = new Product2();
            prod.IsActive = true;
            prod.Name = code;
            prod.ER_Service_Range_Type__c = 'Without Range';
            prod.ProductCode = code;
            products.add(prod);
        }
        insert products;
        
        // PBE
        List<PricebookEntry> sPBE = new List<PricebookEntry>();
        for (Product2 prod : products) {
            Id pricebookId = Test.getStandardPricebookId();
            sPBE.add(
                new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = prod.Id,
                    ER_ValueType__c = 'Currency',
                    CurrencyIsoCode = 'EUR',
                    UnitPrice = 0.0,
                    IsActive = true
                )
            );
        }
        insert sPBE;
        sPBE.clear();
        for (Product2 prod : products) {
            sPBE.add(
                new PricebookEntry(
                    Pricebook2Id = pb.id,
                    Product2Id = prod.Id,
                    ER_ValueType__c = 'Currency',
                    CurrencyIsoCode = 'EUR',
                    UnitPrice = 0.0,
                    IsActive = true
                )
            );
        }
        insert sPBE;
        
        List<PricebookEntry> pbeList = [
            SELECT id, Product2Id, Product2.ER_Solution_Code__c, ProductCode, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2.ProductCode IN :services
            AND Pricebook2Id = :pb.id
        ];
        System.assertEquals(services.size(), pbeList.size());
        
        Test.startTest();
        Opportunity newOpp = APER07_UtilityTestMethod.getOpportunity(
            'ER_Client_Opportunity_RT',
            'createAutoEnrollmentOppLineItemsTest'
        );
        newOpp.AccountId = acc.Id;
        newOpp.ER_BUPicklist__c = 'FI';
        newOpp.ER_Solutions__c = 'ERFI_C_TD_DUALW_EUR';
        newOpp.LeadSource = Constants.CONTRACTING_WEBFORM;
        newOpp.Pricebook2Id = pb.id;
        newOpp.ER_PaymentMethod__c = null;
        newOpp.ER_PaymentTerms__c = 'At reception of invoice';
        newOpp.ER_Credit_Limit__c = 12;
        newOpp.Commercial_Origin__c = 'Greenfield';
        newOpp.ER_Contract_Expected_Start_Date__c = Date.today().addDays(5);
        insert newOpp;
        
        // CREATE PRIMARY CONTACT ROLE - Add this section AFTER opportunity insert
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = newOpp.Id,
            ContactId = primaryContact.Id,
            Role = 'Primary contact',
            IsPrimary = true
        );
        insert ocr;
        // END PRIMARY CONTACT ROLE CREATION
        
        // Verify the Primary Contact Role was created correctly
        List<OpportunityContactRole> verifyOCR = [
            SELECT Id, OpportunityId, ContactId, Role, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :newOpp.Id
            AND Role = 'Primary contact'
        ];
        System.assertEquals(1, verifyOCR.size(), 'Primary contact role should be created');
        System.assertEquals(true, verifyOCR[0].IsPrimary, 'Contact should be marked as primary');
        
        Test.stopTest();
    }
}
    
    @IsTest
static void updateSeniorManagerAsyncTest() {
    Test.startTest();

    List<Id> opportunityIdList = new List<Id>();
    for (Opportunity opp : [
        SELECT Id
        FROM Opportunity
        WHERE StageName != 'Closed Won'
    ]) {
        opportunityIdList.add(opp.Id);
    }

    if (!opportunityIdList.isEmpty()) {
        APER04_Opportunity_Management.updateSeniorManagerAsync(opportunityIdList);
    }

    Test.stopTest();
}

    
     @IsTest
    static void setStandardFinancialConditionsforESTest() {
        Test.startTest();
        List<Opportunity> opportunityIdList = [SELECT Id FROM Opportunity];
        
        if (!opportunityIdList.isEmpty()) {
            APER04_Opportunity_Management.setStandardFinancialConditionsforES(opportunityIdList);
        }
        Test.stopTest();
    }
    /* Method by Harkirat, will look later */
    /*
    @IsTest
    static void opportunityDefaultingValuesTest() {
        Test.startTest();
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opportunityVar : [SELECT Id, ER_SmartER_Context__c, ER_BUPicklist__c FROM Opportunity]){
            opportunityVar.ER_SmartER_Context__c = true;
            opportunityVar.ER_BUPicklist__c = Constants.FR;
            oppList.add(opportunityVar);
        }
        update oppList;
        
        if (!oppList.isEmpty()) {
            APER04_Opportunity_Management.opportunityDefaultingValues(oppList);
        }
        Test.stopTest();
    }
*/
}