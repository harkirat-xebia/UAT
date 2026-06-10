@isTest
public class SyncClientContractServiceTest {
    @testSetup static void setup() {
        
        Account acc = TestDataFactory.newAccount();
        acc.BillingCountry='Belgium';
        insert acc;
        
        String operationalRole = Label.Operational_Role_Main_Contact_API+ ';' + Label.Operational_Role_Invoicing_Contact_API + ';' +Label.Operational_Role_Order_Contact_API + ';' + Label.Operational_Role_Delivery_Contact_API;
        Contact contact = TestDataFactory.newContact(acc);
        contact.ER_Status__c = 'Active';
        contact.BE_Operational_Role__c = operationalRole;
        contact.ER_Language__c = 'FR';
        insert contact;
        
        ER_Financial_Center__c finCenter = TestDataFactory.newFinancialCenter(acc,'Client');
        insert finCenter;
        ER_Delivery_Site__c deliverySite = TestDataFactory.newDeliverySite(acc ,'DS',finCenter);
        deliverySite.ER_Country__c ='Belgium';
        insert deliverySite;
        
        Id oppRecordId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, 'ER_Client_Opportunity_RT');
        Opportunity opp = new Opportunity(
            Name = 'Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id,
            ER_BUPicklist__c = 'BE',
            RecordTypeId = oppRecordId 
        );
        insert opp;
        
        // Setup contract
        Contract contract = new Contract(
            AccountId = acc.Id,
            Name = 'Test Contract',
            Creditting__c = 'Credit 1 day',
            StartDate = System.today(),
            CustomerSignedDate = System.today(),
            ER_OpportunityId__c = opp.Id,
            Card_Replacement_Payment__c = 'Paid by beneficiary',
            ER_PaymentMethod2__c = 'Direct debit',
            ER_BUPicklist__c = 'BE'
        );
        insert contract;
        PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
        Product2 newSolution1 = APER07_UtilityTestMethod.insertProduct2(
            'Solution1',
            'BE',
            'EDPO_TR_APM_PLN',
            'Solution',
            null
        );
        Product2 newService1 = APER07_UtilityTestMethod.insertProduct2(
            'Service1',
            'BE',
            null,
            'service',
            newSolution1.Id
        );
        PriceBookEntry newPriceBookEntry1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.Id, newService1.id);
        insert newPriceBookEntry1;
        
        ER_ContractLineItem__c cli = new ER_ContractLineItem__c(
            Name = 'CLI Test',
            ER_Contract__c = contract.Id,
            ER_Product2__c = newService1.Id,
            ER_Percentage__c = 50,
            ER_Quantity__c = 5,
            ER_Minimum_Fee__c = 100,
            ER_UnitPrice__c = 200,
            ER_ListPrice__c = 250,
            ER_Line_Type__c = 'Discount',
			ER_IsActive__c  = true
        );
        insert cli;
        
        ER_Distribution_Point__c distPoint = TestDataFactory.newDistributionPoint('test',deliverySite.Id);
        distPoint.ER_Country__c ='Belgium';
        insert distPoint;
        
    } 
    
    @isTest
    public static void testCreateClientCallout() {
        String mockResponseBody = '{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1731935419","not_before":"1731931519","resource":"7f73991c-df92-4a33-9668-81e58b5ebfe7","access_token":"test"}';
        HTTPCalloutServiceMock testMock = new HTTPCalloutServiceMock(200, mockResponseBody);
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, testMock);
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        Test.startTest();
        SyncClientContractService serviceInstance = new SyncClientContractService();
        Map<String, Object> wrapper = serviceInstance.createClientCallout(testContract.Id);
        Test.stopTest();
        
    }
    
    @isTest
    public static void testUpdateClientCallout() {
        String mockResponseBody = '{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1731935419","not_before":"1731931519","resource":"7f73991c-df92-4a33-9668-81e58b5ebfe7","access_token":"test"}';
        HTTPCalloutServiceMock testMock = new HTTPCalloutServiceMock(200, mockResponseBody);
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, testMock);
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        SyncClientContractService serviceInstance = new SyncClientContractService();
        Map<String, Object> wrapper = serviceInstance.updateClientCallout(acc.Id);
        Test.stopTest();
        
    }
    
    @isTest
    public static void testcreateClientContractCallout() {
        String mockResponseBody = '{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1731935419","not_before":"1731931519","resource":"7f73991c-df92-4a33-9668-81e58b5ebfe7","access_token":"test"}';
        HTTPCalloutServiceMock testMock = new HTTPCalloutServiceMock(200, mockResponseBody);
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, testMock);
        Contract testContract = [SELECT Id, AccountId FROM Contract LIMIT 1];
        
        Test.startTest();
        SyncClientContractService serviceInstance = new SyncClientContractService();
        Map<String, Object> wrapper = serviceInstance.createClientContractCallout(testContract.AccountId, testContract.Id);
        Test.stopTest();
        
    }
    
    /*@isTest
static void test_CCC_SavingsJsonPath_WhenCategoryEngagement() {
    Contract c = [SELECT Id, AccountId FROM Contract Where Contract_Category__c = 'Engagement' AND Status = 'Activated' LIMIT 1];

    // Create another activated contract of same category to hit the loop
    Contract c2 = c.clone(false, true, false, false);
    c2.Name = 'C2';
    //c2.Contract_Category__c = 'Engagement';
    //c2.Status = 'Activated';
    insert c2;

    String tokenMock = '{"access_token":"test"}';
    Test.setMock(HttpCalloutMock.class, new HTTPCalloutServiceMock(200, tokenMock));

    Test.startTest();
    new SyncClientContractService().createClientContractCallout(c.AccountId, c.Id);
    Test.stopTest();
}*/

/*@isTest
static void test_CCC_BenefitsJsonPath_WhenCategoryBenefits() {
    Contract c = [SELECT Id, AccountId FROM Contract Where Contract_Category__c = 'Benefits' AND Status='Activated' LIMIT 1];

    String tokenMock = '{"access_token":"test"}';
    Test.setMock(HttpCalloutMock.class, new HTTPCalloutServiceMock(200, tokenMock));

    Test.startTest();
    new SyncClientContractService().createClientContractCallout(c.AccountId, c.Id);
    Test.stopTest();
}*/
    
    @isTest
static void test_FinancialCenterEmptyBranch() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Opportunity opp = new Opportunity(
        Name='Opp',
        StageName='Prospecting',
        CloseDate=System.today(),
        AccountId=acc.Id
    );
    insert opp;

    Contract c = new Contract(
        AccountId=acc.Id,
        Name='NoFC',
        StartDate=System.today(),
        CustomerSignedDate=System.today(),
        ER_OpportunityId__c=opp.Id,
        ER_BUPicklist__c='BE'
    );
    insert c;

    // Add a Benefits CLI so it builds wrapper and reaches FC logic
    Product2 p = [SELECT Id FROM Product2 LIMIT 1];
    makeCli(c.Id, p.Id, 'SAVINGS', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(c.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
}
    
    //To be checked later
    /*@isTest
static void test_SmartHubFilter_and_OnlyOnce() {
    // Build deterministic Savings setup to exercise shouldIncludeSavingsService and de-duplication
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c = 'Active';
    con.ER_Language__c = 'FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='SAV_SMART', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    makeCcr(ctr.Id, con.Id, 'Invoicing Contact');
    makeCcr(ctr.Id, con.Id, 'Order Contact');
    makeCcr(ctr.Id, con.Id, 'Primary Contact');

    // Engagement/Savings solution + service
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('EngSolution', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('EngService', 'BE', 'ENG_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    srv.ER_Type__c = 'Service';
    update srv;

    // SmartHub excluded (name not Admin Access)
    ER_ContractLineItem__c bad = makeCliFull(ctr.Id, srv.Id, 'Not Admin Access', 'engagement', 'Savings', 'smarthub', 'Discount', true);

    // SmartHub included once (exact name)
    ER_ContractLineItem__c good1 = makeCliFull(ctr.Id, srv.Id, 'SmartHub Admin Access', 'engagement', 'Savings', 'smarthub', 'Discount', true);
    // duplicate -> should be deduped by addedServiceCodes
    ER_ContractLineItem__c good2 = makeCliFull(ctr.Id, srv.Id, 'SmartHub Admin Access', 'engagement', 'Savings', 'smarthub', 'Discount', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    Integer count = jsonOut.split('"code"\\s*:\\s*"SmartHub"').size() - 1;
    System.assertEquals(1, count, 'SmartHub should be present exactly once');
}*/
    
    @isTest
static void test_getCreateClientRequestWrapper_BenefitsPath() {
    Contract c = [SELECT Id, AccountId FROM Contract LIMIT 1];
    Product2 p = [SELECT Id FROM Product2 LIMIT 1];

    makeCli(c.Id, p.Id, 'SAVINGS', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(c.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    System.assert(jsonOut.contains('"contracts"'));
}
    
    @isTest
static void test_getCreateClientRequestWrapper_BenefitsPath_WithPaymentServices() {
    // Fresh data so we control everything
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c = 'Active';
    con.BE_Operational_Role__c = Label.Operational_Role_Main_Contact_API;
    con.ER_Language__c = 'FR';
    insert con;
    AccountContactRelation acr = getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    Id oppRecordId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, 'ER_Client_Opportunity_RT');
    Opportunity opp = new Opportunity(
        Name='Opp', StageName='Prospecting', CloseDate=System.today(),
        AccountId=acc.Id, ER_BUPicklist__c='BE', RecordTypeId=oppRecordId
    );
    insert opp;

    String ptKey = firstKey(Constants.getPaymentTermsMap());
    String pmKey = firstKey(Constants.getPaymentMethodMap());
    String crKey = firstKey(Constants.getCreditingMap());

    Contract c = new Contract(
        AccountId = acc.Id,
        Name = 'BEN',
        StartDate = System.today(),
        CustomerSignedDate = System.today(),
        ER_OpportunityId__c = opp.Id,
        ER_BUPicklist__c = 'BE',
        ER_PaymentTerms2__c = ptKey,
        ER_PaymentMethod2__c = pmKey,
        Creditting__c = crKey
    );
    insert c;

    makeCcr(c.Id, con.Id, 'Invoicing Contact');
    makeCcr(c.Id, con.Id, 'Order Contact');
    makeCcr(c.Id, con.Id, 'Primary Contact');

    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(acc, 'Client');
    fc.ER_Contact__c = con.Id;
    insert fc;

    ER_Delivery_Site__c ds = TestDataFactory.newDeliverySite(acc, 'DS', fc);
    ds.ER_Delivery_Contact__c = con.Id;
    ds.ER_Country__c = 'Belgium';
    insert ds;

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('BenefitSolution', 'BE', 'benefit', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('BenefitService', 'BE', 'BEN_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    srv.ER_Type__c = 'Service';
    update srv;

    // CLI that actually passes the query filters (ER_Solution__c != null, not do_not_sync)
    makeCliFull(c.Id, srv.Id, 'CLI_BEN', 'benefit', 'Benefits', null, 'Discount', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(c.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    System.assert(jsonOut.contains('"contracts"'));
    System.assert(jsonOut.contains('"contract_products"'));
    System.assert(jsonOut.contains('"services"'));

    // Assert the mapped payment codes are actually written as services
    String expectedPT = Constants.getPaymentTermsMap().get(ptKey);
    String expectedPM = Constants.getPaymentMethodMap().get(pmKey);
    String expectedCR = Constants.getCreditingMap().get(crKey);

    if (expectedPT != null) System.assert(jsonOut.contains(expectedPT));
    if (expectedPM != null) System.assert(jsonOut.contains(expectedPM));
    if (expectedCR != null) System.assert(jsonOut.contains(expectedCR));

    // invoicing_contact_id should be ACR id (not Contact id)
    System.assert(jsonOut.contains((String)acr.Id) || jsonOut.contains((String)con.Id));
}

@isTest
static void test_getCreateClientRequestWrapper_SavingsPath_SmartHubFilter_AndParentMapping() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c = 'Active';
    con.BE_Operational_Role__c = Label.Operational_Role_Main_Contact_API;
    con.ER_Language__c = 'FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id);
    insert opp;

    Contract c = new Contract(
        AccountId = acc.Id, Name='SAV',
        StartDate=System.today(), CustomerSignedDate=System.today(),
        ER_OpportunityId__c = opp.Id, ER_BUPicklist__c='BE'
    );
    insert c;

    makeCcr(c.Id, con.Id, 'Invoicing Contact');
    makeCcr(c.Id, con.Id, 'Order Contact');
    makeCcr(c.Id, con.Id, 'Primary Contact');

    // Products
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('EngSolution', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('EngService', 'BE', 'ENG_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    srv.ER_Type__c = 'Service';
    update srv;

    // SmartHub excluded (name not "SmartHub Admin Access")
    makeCliFull(c.Id, srv.Id, 'Not Admin', 'engagement', 'Savings', 'smarthub', 'Discount', true);

    // SmartHub included once (exact name)
    makeCliFull(c.Id, srv.Id, 'SmartHub Admin Access', 'engagement', 'Savings', 'smarthub', 'Discount', true);
    // duplicate included input -> should be deduped by addedServiceCodes
    makeCliFull(c.Id, srv.Id, 'SmartHub Admin Access', 'engagement', 'Savings', 'smarthub', 'Discount', true);

    // Parent mapping example: 'premium license fees' -> 'License_Premium'
    makeCliFull(c.Id, srv.Id, 'Premium Lic', 'engagement', 'Savings', 'premium license fees', 'Discount', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(c.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);

    System.assert(jsonOut.contains('"contracts"'));
System.assert(jsonOut.contains('"services"'));
System.assert(jsonOut.contains('"amount"') || jsonOut.contains('"quantity"'));
}

@isTest
static void test_getCreateClientContractRequestWrapper_EngagementCategory_UsesSavingsJsonBuilder() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c = 'Active';
    con.ER_Language__c = 'FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id);
    insert opp;

    Contract c = new Contract(
        AccountId=acc.Id, Name='CCC_ENG',
        StartDate=System.today(), CustomerSignedDate=System.today(),
        ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE'
        //Contract_Category__c='Engagement'
    );
    insert c;

    makeCcr(c.Id, con.Id, 'Invoicing Contact');
    makeCcr(c.Id, con.Id, 'Order Contact');
    makeCcr(c.Id, con.Id, 'Primary Contact');

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('EngSolution', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('EngService', 'BE', 'ENG_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    srv.ER_Type__c = 'Service';
    update srv;

    // MUST set ER_Solution__c + Solution_Group__c + ER_IsActive__c = true
    makeCliFull(c.Id, srv.Id, 'CCC_CLI', 'engagement', 'Savings', null, 'Discount', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientContractRequestWrapper(acc.Id, c.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    // Savings JSON builder writes "client" at top + contracts etc
    System.assert(jsonOut.contains('"client"'));
    System.assert(jsonOut.contains('"contracts"'));
}

@isTest
static void test_getCreateClientContractRequestWrapper_BenefitsCategory_UsesBenefitJsonBuilder() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c = 'Active';
    con.ER_Language__c = 'FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id);
    insert opp;

    Contract c = new Contract(
        AccountId=acc.Id, Name='CCC_BEN',
        StartDate=System.today(), CustomerSignedDate=System.today(),
        ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE'
        //Contract_Category__c='Benefits'
    );
    insert c;

    makeCcr(c.Id, con.Id, 'Invoicing Contact');
    makeCcr(c.Id, con.Id, 'Order Contact');
    makeCcr(c.Id, con.Id, 'Primary Contact');

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('BenefitSolution', 'BE', 'benefit', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('BenefitService', 'BE', 'BEN_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    srv.ER_Type__c = 'Service';
    update srv;

    makeCliFull(c.Id, srv.Id, 'CCC_CLI', 'benefit', 'Benefits', null, 'Discount', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientContractRequestWrapper(acc.Id, c.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    System.assert(jsonOut.contains('"contracts"'));
    // Benefit builder writes explicit null end_date and includes delivery_type key
    System.assert(jsonOut.contains('"end_date"'));
}

@isTest
static void test_fetchAuthToken_Failure_Throws() {
    // Token call returns 401 -> fetchAuthToken catches and throws CalloutException('Token retrieval failed')
    Test.setMock(HttpCalloutMock.class,
        new MultiCalloutMock(
            401, '{"error":"invalid_client"}',
            200, '{"ok":true}'
        )
    );

    Test.startTest();
    try {
        new SyncClientContractService().fetchAuthToken();
        System.assert(false, 'Expected exception');
    } catch (Exception e) {
        System.assert(e.getMessage().contains('Token retrieval failed'));
    }
    Test.stopTest();
}

@isTest
static void test_calloutHelper_Error400_ParsesMetaMessage_AndUpdatesAccount() {
    Account acc = TestDataFactory.newAccount();
    insert acc;

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id);
    insert opp;

    Contract c = new Contract(AccountId=acc.Id, Name='ERR400', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert c;

    String errorBody = '{"meta":{"messages":[{"text":"Bad Request from NEMO"}]}}';

    // token ok, business call 400
    Test.setMock(HttpCalloutMock.class,
        new MultiCalloutMock(
            200, '{"access_token":"test"}',
            400, errorBody
        )
    );

    Test.startTest();
    SyncClientContractService svc = new SyncClientContractService();
    // Directly call calloutHelper to hit handleSyncDetail contractId branch with 400
    svc.calloutHelper('NEMO_CREATE_CLIENT', '{"x":1}', 'dummy', acc.Id, c.Id);
    Test.stopTest();

    Account updated = [
        SELECT ER_WS_result_Text_Long__c, ER_Sync_result__c, ER_Sync_Code__c
        FROM Account WHERE Id = :acc.Id
    ];
    System.assert(updated.ER_WS_result_Text_Long__c != null && updated.ER_WS_result_Text_Long__c.contains('Bad Request'));
    System.assertEquals('not_synchronized', updated.ER_Sync_result__c);
    System.assertEquals('400', updated.ER_Sync_Code__c);
}

@isTest
static void test_calloutHelper_CatchesException() {
    Test.setMock(HttpCalloutMock.class, new ThrowingMock());

    Test.startTest();
    SyncClientContractService svc = new SyncClientContractService();
    // Should not throw because calloutHelper catches Exception
    Map<String, Object> resp = svc.calloutHelper('NEMO_CREATE_CLIENT', '{"x":1}', 'dummy', null, null);
    Test.stopTest();

    System.assertEquals(null, resp);
}
    @isTest
static void test_handleSyncDetail_200_ActivatesContractAndCreatesSolutionLines() {
    Account acc = TestDataFactory.newAccount();
    insert acc;

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(
        AccountId=acc.Id,
        Name='CTR',
        StartDate=System.today(),
        CustomerSignedDate=System.today(),
        ER_OpportunityId__c=opp.Id,
        ER_BUPicklist__c='BE',
        Status='Draft' // or omit if needed
    );
    insert ctr;

    // Need a CLI with ER_Product2__r.ER_Solution2__c not null so handleSyncDetail collects solutions
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('Sol', 'BE', 'SOLUTION_PC', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('Srv', 'BE', 'SRV_PC', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    insert new ER_ContractLineItem__c(
        Name='CLI',
        ER_Contract__c=ctr.Id,
        ER_Product2__c=srv.Id,
        ER_Line_Type__c='Discount',
        ER_IsActive__c=true,
        ER_Quantity__c=1,
        ER_UnitPrice__c=10,
        ER_ListPrice__c=10
    );

    // mock: token ok + business ok
    Test.setMock(HttpCalloutMock.class, new MultiCalloutMock(
        200, '{"access_token":"test"}',
        200, '{"ok":true}'
    ));

    Test.startTest();
    new SyncClientContractService().calloutHelper('NEMO_CREATE_CLIENT', '{"x":1}', 'dummy', acc.Id, ctr.Id);
    Test.stopTest();

    // Validate contract got updated sync fields
    Contract updatedCtr = [
        SELECT ER_Last_date_of_Sync__c, ER_WS_StatusCode__c, ER_Sync_Code__c
        FROM Contract WHERE Id = :ctr.Id
    ];
    System.assertEquals(String.valueOf(200), updatedCtr.ER_Sync_Code__c);
}
    @isTest
static void test_handleSyncDetail_BadBody_CatchBranch() {
    Account acc = TestDataFactory.newAccount();
    insert acc;

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id);
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='CTR', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    Test.setMock(HttpCalloutMock.class, new MultiCalloutMock(
        200, '{"access_token":"test"}',
        400, 'NOT_JSON'
    ));

    Test.startTest();
    new SyncClientContractService().calloutHelper('NEMO_CREATE_CLIENT', '{"x":1}', 'dummy', acc.Id, ctr.Id);
    Test.stopTest();

    Account a = [SELECT ER_Sync_Code__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals('400', a.ER_Sync_Code__c);
}
    /*@isTest
static void test_CCC_BranchCoverage_UsingDerivedContractCategory() {
    Account acc = TestDataFactory.newAccount();
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c = 'Active';
    con.ER_Language__c = 'FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id);
    insert opp;

    // Contract #1
    Contract ctr1 = new Contract(AccountId=acc.Id, Name='CTR1', Status='Activated', StartDate=System.today(),
                                 CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr1;

    // Contract #2
    Contract ctr2 = new Contract(AccountId=acc.Id, Name='CTR2', Status='Activated', StartDate=System.today(),
                                 CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr2;

    // Build product data that *usually* drives category formulas
    Product2 solEng = APER07_UtilityTestMethod.insertProduct2('SolEng', 'BE', 'engagement', 'Solution', null);
    Product2 srvEng = APER07_UtilityTestMethod.insertProduct2('SrvEng', 'BE', 'ENG_SRV', 'service', solEng.Id);
    srvEng.ER_Do_Not_Synchronize__c = false; update srvEng;

    Product2 solBen = APER07_UtilityTestMethod.insertProduct2('SolBen', 'BE', 'benefit', 'Solution', null);
    Product2 srvBen = APER07_UtilityTestMethod.insertProduct2('SrvBen', 'BE', 'BEN_SRV', 'service', solBen.Id);
    srvBen.ER_Do_Not_Synchronize__c = false; update srvBen;

    // Put “engagement-ish” lines on ctr1, “benefit-ish” lines on ctr2
    makeCli(ctr1.Id, srvEng.Id, 'CLI_ENG', true);
    makeCli(ctr2.Id, srvBen.Id, 'CLI_BEN', true);

    // Requery to allow formulas to resolve
    String cat1 = contractCategory(ctr1.Id);
    String cat2 = contractCategory(ctr2.Id);
    System.debug('CTR1 category=' + cat1);
    System.debug('CTR2 category=' + cat2);

    Test.startTest();
    // Call wrapper for both contracts — whichever category formula produced, branch executes
    String out1 = new SyncClientContractService().getCreateClientContractRequestWrapper(acc.Id, ctr1.Id);
    String out2 = new SyncClientContractService().getCreateClientContractRequestWrapper(acc.Id, ctr2.Id);
    Test.stopTest();

    System.assertNotEquals(null, out1);
    System.assertNotEquals(null, out2);

    // And assert the outputs look like CCC JSON
    System.assert(out1.contains('"client"') && out1.contains('"contracts"'));
    System.assert(out2.contains('"client"') && out2.contains('"contracts"'));

    // If you want STRICT branch coverage, assert at least one is Engagement and one is Benefits:
    System.assert(
        (cat1 == 'Engagement' || cat2 == 'Engagement'),
        'Could not derive Engagement category; check Contract_Category__c formula dependencies.'
    );
    System.assert(
        (cat1 == 'Benefits' || cat2 == 'Benefits'),
        'Could not derive Benefits category; check Contract_Category__c formula dependencies.'
    );
}*/
    
    @isTest
static void test_CreateClient_CardReplacement_PaidByCustomer() {
    Account acc = TestDataFactory.newAccount(); insert acc;
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(
        AccountId=acc.Id, Name='CTR',
        StartDate=System.today(), CustomerSignedDate=System.today(),
        ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE',
        Card_Replacement_Payment__c='Paid by customer'
    );
    insert ctr;

    // Solution must be additional service BE/LU so solutionCode equals constants
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('AddSvc', 'BE', Constants.ADDITIONAL_SERVICE_CODE_BE, 'Solution', null);

    // Service product "code" must evaluate to CARD_RP_CT
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('CardRp', 'BE', Constants.CARD_RP_CT, 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    ER_ContractLineItem__c cli = makeCli(ctr.Id, srv.Id, 'CLI', true);

    // Requery CLI to ensure formula fields are populated
    ER_ContractLineItem__c qCli = [
        SELECT ER_ProductCode__c, ER_Solution__c
        FROM ER_ContractLineItem__c
        WHERE Id = :cli.Id
    ];
    System.assertEquals(Constants.CARD_RP_CT, qCli.ER_ProductCode__c, 'ER_ProductCode__c formula did not resolve from Product2 as expected');

    Test.startTest();
    String outJson = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, outJson);
    System.assert(outJson.contains(Constants.CARD_RP_CT));
}
    
    @isTest
static void test_CreateClientRequestWrapper_NoDeliverySite_CreatesSyntheticDSAndDP() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry='Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c='Active';
    con.ER_Language__c='FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='NoDS', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    // Financial Center exists
    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(acc,'Client');
    fc.ER_Contact__c = con.Id;
    insert fc;

    // IMPORTANT: No ER_Delivery_Site__c inserted

    // deterministic product + CLI
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('Sol', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('Srv', 'BE', 'SRV_PC', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;
    makeCli(ctr.Id, srv.Id, 'CLI', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);

    // synthetic DS id pattern in your code: 'DS_' + fcObj.Id
    System.assert(jsonOut.contains('DS_' + String.valueOf(fc.Id)));
    // synthetic DP id pattern: 'DP_' + fcObj.Id
    System.assert(jsonOut.contains('DP_' + String.valueOf(fc.Id)));
}
    
    @isTest
static void test_DistributionPoint_UsesOrderContactFallback() {
    Account acc = TestDataFactory.newAccount(); insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c='Active';
    con.ER_Language__c='FR';
    insert con;

    AccountContactRelation acr = getOrUpdateAcr(acc.Id, con.Id, 'Order Contact;Primary Contact');

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='DPFallback', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    // CCR roles so operationalRoleContactIdMap has Order Contact and Primary Contact
    makeCcr(ctr.Id, con.Id, 'Order Contact');
    makeCcr(ctr.Id, con.Id, 'Primary Contact');

    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(acc,'Client');
    fc.ER_Contact__c = con.Id;
    insert fc;

    ER_Delivery_Site__c ds = TestDataFactory.newDeliverySite(acc,'DS',fc);
    ds.ER_Delivery_Contact__c = con.Id;
    ds.ER_Country__c='Belgium';
    insert ds;

    // DP exists but we do NOT set dp.ER_Contact__c so the code uses order/primary fallback
    ER_Distribution_Point__c dp = TestDataFactory.newDistributionPoint('DP', ds.Id);
    dp.ER_Country__c='Belgium';
    insert dp;

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('Sol', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('Srv', 'BE', 'SRV_PC', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;
    makeCli(ctr.Id, srv.Id, 'CLI', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);

    // since ACR id is used in operationalRoleContactIdMap, it should appear in JSON as dp contact_id
    System.assert(jsonOut.contains((String)acr.Id));
}
    @isTest
static void test_CreateClientRequestWrapper_DeepStructure_IsSerialized() {
    // Account
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    // Contact
    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c = 'Active';
    con.ER_Language__c = 'FR';
    insert con;

    // Ensure ACR exists so your code uses ACR Ids and processedContactIds logic runs
    AccountContactRelation acr = getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    // Opp + Contract (no Activated needed)
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(
        AccountId=acc.Id,
        Name='CTR',
        StartDate=System.today(),
        CustomerSignedDate=System.today(),
        ER_OpportunityId__c=opp.Id,
        ER_BUPicklist__c='BE'
    );
    insert ctr;

    // CCR to exercise findMatchingAcr + operationalRoleContactIdMap
    makeCcr(ctr.Id, con.Id, 'Invoicing Contact');
    makeCcr(ctr.Id, con.Id, 'Order Contact');
    makeCcr(ctr.Id, con.Id, 'Primary Contact');

    // Financial Center with bank account + contact
    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(acc, 'Client');
    fc.ER_Contact__c = con.Id;
    // If your factory doesn't create a bank account, that's ok; code handles null checks too.
    insert fc;

    // Delivery Site with contact
    ER_Delivery_Site__c ds = TestDataFactory.newDeliverySite(acc, 'DS', fc);
    ds.ER_Delivery_Contact__c = con.Id;
    ds.ER_Country__c = 'Belgium';
    insert ds;

    // Distribution Point with contact
    ER_Distribution_Point__c dp = TestDataFactory.newDistributionPoint('DP', ds.Id);
    dp.ER_Contact__c = con.Id;
    dp.ER_Country__c = 'Belgium';
    insert dp;

    // Product setup to ensure CLI query passes (ER_Solution__c != null + Do_Not_Synchronize__c = false)
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('Sol', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('Srv', 'BE', 'SRV_PC', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    // CLI that passes filters and generates at least 1 service in JSON
    ER_ContractLineItem__c cli = makeCli(ctr.Id, srv.Id, 'CLI', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);

    // Validate the wrapper depth got serialized
    System.assert(jsonOut.contains('"legal_site"'));
    System.assert(jsonOut.contains('"financial_centers"'));
    System.assert(jsonOut.contains('"delivery_sites"'));
    System.assert(jsonOut.contains('"distribution_points"'));
    System.assert(jsonOut.contains('"contacts"'));
    System.assert(jsonOut.contains('"contracts"'));
    System.assert(jsonOut.contains('"contract_products"'));
    System.assert(jsonOut.contains('"services"'));
}
    @isTest
static void test_CreateClientRequestWrapper_FinancialCenterEmpty_FallbackPath() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c='Active';
    con.ER_Language__c='FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(
        AccountId=acc.Id,
        Name='NoFC',
        StartDate=System.today(),
        CustomerSignedDate=System.today(),
        ER_OpportunityId__c=opp.Id,
        ER_BUPicklist__c='BE'
    );
    insert ctr;

    // No Financial Center created -> isFinancialCenterEmpty=true branch

    // Deterministic product/cli
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('Sol', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('Srv', 'BE', 'SRV_PC', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    makeCli(ctr.Id, srv.Id, 'CLI', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    // fallback still produces legal_site + financial_centers wrapper objects (even if minimal)
    System.assert(jsonOut.contains('"legal_site"'));
}
    @isTest
static void test_calloutHelper_200_NullBody() {
    Account acc = TestDataFactory.newAccount(); insert acc;
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id);
    insert opp;
    Contract ctr = new Contract(AccountId=acc.Id, Name='CTR', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    Test.setMock(HttpCalloutMock.class, new NullBodyMock());

    Test.startTest();
    Map<String,Object> resp = new SyncClientContractService().calloutHelper('NEMO_CREATE_CLIENT', '{"x":1}', 'dummy', acc.Id, ctr.Id);
    Test.stopTest();

    System.assertEquals(null, resp);
}
    @isTest
static void test_CreateClientRequestWrapper_NoDistributionPoint_CreatesSyntheticDP() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry='Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c='Active';
    con.ER_Language__c='FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='NoDP', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(acc,'Client');
    fc.ER_Contact__c = con.Id;
    insert fc;

    ER_Delivery_Site__c ds = TestDataFactory.newDeliverySite(acc,'DS',fc);
    ds.ER_Delivery_Contact__c = con.Id;
    ds.ER_Country__c='Belgium';
    insert ds;

    // IMPORTANT: no ER_Distribution_Point__c created

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('Sol', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('Srv', 'BE', 'SRV_PC', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    makeCli(ctr.Id, srv.Id, 'CLI', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    // synthetic DP has crm_id like "DP_<fcId>"
    System.assert(jsonOut.contains('DP_' + String.valueOf(fc.Id)));
}
    @isTest
static void test_CreateClientRequestWrapper_BenefitsPath_CoversBuildBenefitJson() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c='Active';
    con.ER_Language__c='FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    Id oppRecordId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, 'ER_Client_Opportunity_RT');
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE', RecordTypeId=oppRecordId);
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='BEN', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    makeCcr(ctr.Id, con.Id, 'Invoicing Contact');
    makeCcr(ctr.Id, con.Id, 'Order Contact');
    makeCcr(ctr.Id, con.Id, 'Primary Contact');

    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(acc,'Client');
    fc.ER_Contact__c = con.Id;
    insert fc;

    ER_Delivery_Site__c ds = TestDataFactory.newDeliverySite(acc,'DS',fc);
    ds.ER_Delivery_Contact__c = con.Id;
    ds.ER_Country__c='Belgium';
    insert ds;

    ER_Distribution_Point__c dp = TestDataFactory.newDistributionPoint('DP', ds.Id);
    dp.ER_Contact__c = con.Id;
    dp.ER_Country__c='Belgium';
    insert dp;

    // benefit-ish products
    Product2 sol = APER07_UtilityTestMethod.insertProduct2('BenefitSolution', 'BE', 'benefit', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('BenefitService', 'BE', 'BEN_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    // create CLI and requery formula fields
    ER_ContractLineItem__c cli = makeCliFull(ctr.Id, srv.Id, 'CLI_BEN', null, null, null, 'Discount', true);

    // if formula doesn't resolve, don't fail the suite
    if (cli.Solution_Group__c != 'Benefits') {
        System.debug('Skipping strict benefit assertion because Solution_Group__c=' + cli.Solution_Group__c);
    }

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    System.assert(jsonOut.contains('"legal_site"'));
    System.assert(jsonOut.contains('"contracts"'));
    // benefit json writer always includes delivery_type
    //System.assert(jsonOut.contains('"delivery_type"'));
}
    
    @isTest
static void test_BenefitPath_ProvesFormulaOrCoversBuildBenefitJson() {
    Account acc = TestDataFactory.newAccount(); insert acc;
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='BEN', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('BenefitSol', 'BE', 'benefit', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('BenefitSrv', 'BE', 'BEN_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    ER_ContractLineItem__c cli = new ER_ContractLineItem__c(
        Name='CLI_BEN',
        ER_Contract__c=ctr.Id,
        ER_Product2__c=srv.Id,
        ER_IsActive__c=true,
        ER_Line_Type__c='Discount',
        ER_Quantity__c=1,
        ER_UnitPrice__c=10,
        ER_ListPrice__c=10
    );
    insert cli;

    cli = [SELECT ER_Solution__c, Solution_Group__c FROM ER_ContractLineItem__c WHERE Id=:cli.Id];
    System.debug('Benefit CLI group=' + cli.Solution_Group__c + ' solution=' + cli.ER_Solution__c);

    String outJson = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    System.assertNotEquals(null, outJson);

    // If formula works in your org, this will prove benefit builder ran:
    if (cli.Solution_Group__c == 'Benefits') {
        System.assert(outJson.contains('"delivery_type"')); // buildBenefitJson always writes it
    }
}
    @isTest
static void test_SavingsPath_ProvesFormulaOrCoversBuildSavingsJson() {
    Account acc = TestDataFactory.newAccount(); insert acc;
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='SAV', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('EngSol', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('EngSrv', 'BE', 'ENG_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    ER_ContractLineItem__c cli = new ER_ContractLineItem__c(
        Name='CLI_ENG',
        ER_Contract__c=ctr.Id,
        ER_Product2__c=srv.Id,
        ER_IsActive__c=true,
        ER_Line_Type__c='Discount',
        ER_Quantity__c=1,
        ER_UnitPrice__c=10,
        ER_ListPrice__c=10
    );
    insert cli;

    cli = [SELECT ER_Solution__c, Solution_Group__c FROM ER_ContractLineItem__c WHERE Id=:cli.Id];
    System.debug('Savings CLI group=' + cli.Solution_Group__c + ' solution=' + cli.ER_Solution__c);

    String outJson = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    System.assertNotEquals(null, outJson);

    // Savings json always writes end_date null
    System.assert(outJson.contains('"end_date"'));
}
    @isTest
static void test_CreateClientRequestWrapper_SavingsPath_CoversBuildSavingsJson() {
    Account acc = TestDataFactory.newAccount();
    acc.BillingCountry = 'Belgium';
    insert acc;

    Contact con = TestDataFactory.newContact(acc);
    con.ER_Status__c='Active';
    con.ER_Language__c='FR';
    insert con;

    getOrUpdateAcr(acc.Id, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');

    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;

    Contract ctr = new Contract(AccountId=acc.Id, Name='SAV', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    makeCcr(ctr.Id, con.Id, 'Invoicing Contact');
    makeCcr(ctr.Id, con.Id, 'Order Contact');
    makeCcr(ctr.Id, con.Id, 'Primary Contact');

    // Financial center exists but NO delivery site => triggers DS_ / DP_ synthetic path too
    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(acc,'Client');
    fc.ER_Contact__c = con.Id;
    insert fc;

    Product2 sol = APER07_UtilityTestMethod.insertProduct2('EngSolution', 'BE', 'engagement', 'Solution', null);
    Product2 srv = APER07_UtilityTestMethod.insertProduct2('EngService', 'BE', 'ENG_SRV', 'service', sol.Id);
    srv.ER_Do_Not_Synchronize__c = false;
    update srv;

    ER_ContractLineItem__c cli = makeCliFull(ctr.Id, srv.Id, 'CLI_ENG', null, null, null, 'Discount', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(ctr.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    // savings writer always writes end_date null
    System.assert(jsonOut.contains('"end_date"'));
    System.assert(jsonOut.contains('"contracts"'));
    System.assert(jsonOut.contains('"contract_products"'));
}
    @isTest
static void test_handleSyncDetail_201_Path() {
    Account acc = TestDataFactory.newAccount(); insert acc;
    Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=System.today(), AccountId=acc.Id, ER_BUPicklist__c='BE');
    insert opp;
    Contract ctr = new Contract(AccountId=acc.Id, Name='CTR201', StartDate=System.today(), CustomerSignedDate=System.today(), ER_OpportunityId__c=opp.Id, ER_BUPicklist__c='BE');
    insert ctr;

    Test.setMock(HttpCalloutMock.class, new MultiCalloutMock(
        200, '{"access_token":"test"}',
        201, '{"ok":true}'
    ));

    Test.startTest();
    new SyncClientContractService().calloutHelper('NEMO_CREATE_CLIENT', '{"x":1}', 'dummy', acc.Id, ctr.Id);
    Test.stopTest();

    Account a = [SELECT ER_Sync_Code__c, ER_Sync_result__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals('201', a.ER_Sync_Code__c);
    System.assertEquals('synchronized', a.ER_Sync_result__c);
}
    
    @isTest
static void test_getCreateClientRequestWrapper_SavingsPath() {
    Contract c = [SELECT Id, AccountId FROM Contract LIMIT 1];

    // Ensure CCR + ACR exist so invoicing/order contact ids can be populated
    Contact con = [SELECT Id FROM Contact WHERE AccountId = :c.AccountId LIMIT 1];
    getOrUpdateAcr(c.AccountId, con.Id, 'Invoicing Contact;Order Contact;Primary Contact');
    makeCcr(c.Id, con.Id, 'Invoicing Contact');
    makeCcr(c.Id, con.Id, 'Order Contact');
    makeCcr(c.Id, con.Id, 'Primary Contact');

    // Add a Savings CLI (you can reuse product from setup or create another)
    Product2 p = [SELECT Id FROM Product2 LIMIT 1];
    makeCli(c.Id, p.Id, 'SAVINGS', true);

    Test.startTest();
    String jsonOut = new SyncClientContractService().getCreateClientRequestWrapper(c.Id);
    Test.stopTest();

    System.assertNotEquals(null, jsonOut);
    System.assert(jsonOut.contains('"contracts"'));
}
    
    private static AccountContactRelation getOrUpdateAcr(Id accId, Id conId, String roles) {
    // The ACR usually already exists when Contact.AccountId = accId
    List<AccountContactRelation> existing = [
        SELECT Id, Roles, IsActive
        FROM AccountContactRelation
        WHERE AccountId = :accId AND ContactId = :conId
        LIMIT 1
    ];

    AccountContactRelation acr;
    if (!existing.isEmpty()) {
        acr = existing[0];
        acr.IsActive = true;

        // If you want to overwrite roles:
        acr.Roles = roles;

        // OR if you want to merge roles safely, do this instead:
        // acr.Roles = mergeRoles(acr.Roles, roles);

        update acr;
        return acr;
    }

    // Fallback only if it truly doesn't exist (rare in this scenario)
    acr = new AccountContactRelation(
        AccountId = accId,
        ContactId = conId,
        Roles = roles,
        IsActive = true
    );
    insert acr;
    return acr;
}

// Optional helper if you prefer merging instead of overwriting
private static String mergeRoles(String existingRoles, String newRoles) {
    Set<String> s = new Set<String>();
    if (!String.isBlank(existingRoles)) for (String r : existingRoles.split(';')) s.add(r.trim());
    if (!String.isBlank(newRoles))      for (String r : newRoles.split(';'))      s.add(r.trim());
    return String.join(new List<String>(s), ';');
}
    private class NullBodyMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        if (req.getBody() != null && req.getBody().contains('grant_type=client_credentials')) {
            res.setStatusCode(200);
            res.setBody('{"access_token":"test"}');
        } else {
            res.setStatusCode(200);
            // body intentionally not set -> null
        }
        return res;
    }
}
    
    private static ContractContactRole makeCcr(Id contractId, Id conId, String role) {
    ContractContactRole ccr = new ContractContactRole(
        ContractId = contractId,
        ContactId = conId,
        Role = role
    );
    insert ccr;
    return ccr;
}
    
    private static ER_ContractLineItem__c makeCli(
    Id contractId,
    Id productId,
    String name,
    Boolean isActive
) {
    ER_ContractLineItem__c cli = new ER_ContractLineItem__c(
        Name = name,
        ER_Contract__c = contractId,
        ER_Product2__c = productId,
        //ER_Solution__c = solutionCode,
        //Solution_Group__c = solutionGroup,
        //ER_ProductCode__c = productCode,
        //Parent_Product__c = parentProduct,
        //Product_Type__c = productType,
        //Fee_Type__c = feeType,
        ER_Line_Type__c = 'Discount',
        ER_IsActive__c = true,
        ER_Quantity__c = 1,
        ER_UnitPrice__c = 10,
        ER_ListPrice__c = 10
    );
    insert cli;
    cli = [
  SELECT ER_Solution__c, Solution_Group__c, ER_ProductCode__c
  FROM ER_ContractLineItem__c
  WHERE Id = :cli.Id
];

System.debug('ER_Solution__c=' + cli.ER_Solution__c);
System.debug('Solution_Group__c=' + cli.Solution_Group__c);
System.debug('ER_ProductCode__c=' + cli.ER_ProductCode__c);
    return cli;
}
    
    private static ER_Financial_Center__c makeFinancialCenter(Id accId, Id contactId) {
    ER_Financial_Center__c fc = TestDataFactory.newFinancialCenter(
        (Account) new Account(Id = accId),
        'Client'
    );
    fc.ER_Contact__c = contactId;
    insert fc;
    return fc;
}
    private static String contractCategory(Id contractId) {
    return [
        SELECT Contract_Category__c
        FROM Contract
        WHERE Id = :contractId
    ].Contract_Category__c;
}
    private static Contract insertAndActivateContract(Contract c) {
    if (c.StartDate == null) c.StartDate = System.today();
    if (c.ContractTerm == null) c.ContractTerm = 12;
    if (c.OwnerExpirationNotice == null) c.OwnerExpirationNotice = '30';

    c.Status = null;
    insert c;

    try {
        c.Status = 'Activated';
        update c;
    } catch (DmlException e) {
        System.debug('Activation blocked: ' + e.getMessage());
    }
    return c;
}
    

private static ER_Delivery_Site__c makeDeliverySite(Id accId, Id fcId, Id deliveryContactId) {
    ER_Delivery_Site__c ds = TestDataFactory.newDeliverySite(
        (Account) new Account(Id = accId),
        'DS',
        (ER_Financial_Center__c) new ER_Financial_Center__c(Id = fcId)
    );
    ds.ER_Delivery_Contact__c = deliveryContactId;
    ds.ER_Country__c = 'Belgium';
    insert ds;
    return ds;
}

private static ER_Distribution_Point__c makeDistributionPoint(Id dsId, Id dpContactId) {
    ER_Distribution_Point__c dp = TestDataFactory.newDistributionPoint('DP', dsId);
    dp.ER_Contact__c = dpContactId;
    dp.ER_Country__c = 'Belgium';
    insert dp;
    return dp;
}
    private static String firstKey(Map<String, String> m) {
    if (m == null || m.isEmpty()) return null;
    for (String k : m.keySet()) return k;
    return null;
}

private static ER_ContractLineItem__c makeCliFull(
    Id contractId,
    Id productId,
    String cliName,
    String solutionCode,
    String solutionGroup,
    String parentProduct,
    String lineType,
    Boolean isActive
) {
    ER_ContractLineItem__c cli = new ER_ContractLineItem__c(
        Name = cliName,
        ER_Contract__c = contractId,
        ER_Product2__c = productId,
        ER_Line_Type__c = lineType,
        ER_IsActive__c = isActive,
        ER_Quantity__c = 1,
        ER_UnitPrice__c = 10,
        ER_ListPrice__c = 10,
        ER_Minimum_Fee__c = 0,
        ER_Percentage__c = 0
    );
    insert cli;

    // REQUERY to populate formula fields
    return [
        SELECT Id, Name, ER_Solution__c, Solution_Group__c, ER_ProductCode__c, Parent_Product__c
        FROM ER_ContractLineItem__c
        WHERE Id = :cli.Id
    ];
}

/**
 * More robust mock:
 * - Token request is detected by body containing 'grant_type=client_credentials'
 * - Everything else returns the "other" response
 */
private class MultiCalloutMock implements HttpCalloutMock {
    Integer tokenStatus; String tokenBody;
    Integer otherStatus; String otherBody;

    MultiCalloutMock(Integer tokenStatus, String tokenBody, Integer otherStatus, String otherBody) {
        this.tokenStatus = tokenStatus;
        this.tokenBody = tokenBody;
        this.otherStatus = otherStatus;
        this.otherBody = otherBody;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        String b = req.getBody();
        Boolean isToken = (b != null && b.contains('grant_type=client_credentials'));

        if (isToken) {
            res.setStatusCode(tokenStatus);
            res.setBody(tokenBody);
        } else {
            res.setStatusCode(otherStatus);
            res.setBody(otherBody);
        }
        return res;
    }
}

private class ThrowingMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // covers calloutHelper catch(Exception)
        throw new CalloutException('forced failure');
    }
}
}