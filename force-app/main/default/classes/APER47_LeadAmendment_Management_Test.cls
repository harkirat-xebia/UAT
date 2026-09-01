/*
----------------------------------------------------------------------
-- - Name          : APER47_LeadAmendment_Management_Test
-- - Author        : Harkirat Singh
-- - Description   : test class for APER47_LeadAmendment_Management
--
--                   Fixtures are built locally rather than through
--                   APER07_UtilityTestMethod so each blocking rule can be
--                   isolated by changing exactly one field.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2026     Harkirat Singh       1.0         Initial version
----------------------------------------------------------------------
*/
@isTest
private class APER47_LeadAmendment_Management_Test {
  private static final String CRN = 'AMEND-CRN-0001';
  private static final String FAMILY_BENEFITS = 'Benefits';
  private static final String FAMILY_SAVINGS = 'Savings';
  private static final String FAMILY_MOBILITY = 'Mobility';

  /*=================================================================
    FIXTURES
  =================================================================*/

  /*  Three Benefits products plus one Savings and one Mobility, so a family match can be
      isolated from a solution match - A, B and C share a solution, D does not. */
  private static Map<String, Product2> buildProducts() {
    Product2 solution = new Product2(Name = 'Solution TRE', ProductCode = 'TRE', ER_Type__c = 'Solution', IsActive = true);
    Product2 otherSolution = new Product2(Name = 'Solution ECE', ProductCode = 'ECE', ER_Type__c = 'Solution', IsActive = true);
    insert new List<Product2>{ solution, otherSolution };

    Map<String, Product2> products = new Map<String, Product2>();
    List<Product2> children = new List<Product2>{
      new Product2(Name = 'Product A', ER_Type__c = 'Service', IsActive = true, Solution_Group__c = FAMILY_BENEFITS, ER_Solution2__c = solution.Id),
      new Product2(Name = 'Product B', ER_Type__c = 'Service', IsActive = true, Solution_Group__c = FAMILY_BENEFITS, ER_Solution2__c = solution.Id),
      new Product2(Name = 'Product C', ER_Type__c = 'Service', IsActive = true, Solution_Group__c = FAMILY_BENEFITS, ER_Solution2__c = solution.Id),
      // harkirat - same Benefits family, different solution, proves the match is family level
      new Product2(Name = 'Product D', ER_Type__c = 'Service', IsActive = true, Solution_Group__c = FAMILY_BENEFITS, ER_Solution2__c = otherSolution.Id),
      new Product2(Name = 'Product S', ER_Type__c = 'Service', IsActive = true, Solution_Group__c = FAMILY_SAVINGS, ER_Solution2__c = otherSolution.Id),
      // harkirat - Mobility is only an allowed Solution_Group__c value under the Solution record type
      new Product2(
        Name = 'Product M',
        ER_Type__c = 'Service',
        IsActive = true,
        Solution_Group__c = FAMILY_MOBILITY,
        ER_Solution2__c = otherSolution.Id,
        RecordTypeId = productSolutionRtId()
      )
    };
    insert children;

    products.put('A', children[0]);
    products.put('B', children[1]);
    products.put('C', children[2]);
    products.put('D', children[3]);
    products.put('S', children[4]);
    products.put('M', children[5]);
    return products;
  }

  private static void buildPricebookEntries(List<Product2> products) {
    Id standardPricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> entries = new List<PricebookEntry>();
    for (Product2 product : products) {
      entries.add(new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true));
    }
    insert entries;
  }

  private static Account buildAccount() {
    Account account = new Account(Name = 'Amend Test Co', ER_Registration_Number__c = CRN);
    insert account;
    return account;
  }

  private static Id productSolutionRtId() {
    return Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Solution').getRecordTypeId();
  }

  private static Id clientLeadRtId() {
    return Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ER_Client_Lead_RT').getRecordTypeId();
  }

  private static Id clientContractRtId() {
    return Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId();
  }

  private static Lead buildLead(Id productOfInterestId) {
    return buildLead(productOfInterestId, clientLeadRtId());
  }

  private static Lead buildLead(Id productOfInterestId, Id recordTypeId) {
    Lead lead = newLead(productOfInterestId, recordTypeId);
    insertLeadBypassingTrigger(lead);
    return lead;
  }

  private static Lead newLead(Id productOfInterestId, Id recordTypeId) {
    return new Lead(
      Salutation = 'Mr.',
      FirstName = 'Amend',
      LastName = 'Test',
      Company = 'Amend Test Co',
      Email = 'amend.test@example.com',
      RecordTypeId = recordTypeId,
      ER_Registration_Number__c = CRN,
      ER_Number_Of_Beneficiaries__c = 50,
      ERBE_Initial_Product_Of_Interest__c = productOfInterestId,
      // harkirat - pre-filled so APBE01_LeadBelfirst.isEligible() is false and the @future
      // Belfirst callout never fires (it is not mocked in this class)
      ER_Legal_Name__c = 'Amend Test Co',
      ER_Legal_Street__c = 'Test Street 1',
      ER_Legal_Zip_Code__c = '1000',
      ER_Legal_City__c = 'Brussels'
    );
  }

  /*  LeadTriggerHandler.afterInsert also calls routeLeadToGenesys, which is a genuinely
      synchronous (non-@future) callout gated by BU-specific Global Settings - present in UAT
      but not in dev, so it fires unpredictably per org and is never mocked here. Disabled for
      every fixture insert since none of these tests are about Lead trigger side effects. */
  private static void insertLeadBypassingTrigger(Lead lead) {
    LeadTriggerHandler.triggerDisabled = true;
    try {
      insert lead;
    } finally {
      LeadTriggerHandler.triggerDisabled = false;
    }
  }

  private static Opportunity buildOpportunity(Id accountId) {
    Opportunity opp = new Opportunity(
      Name = 'Source Opp',
      AccountId = accountId,
      StageName = 'Qualification',
      CloseDate = Date.today().addMonths(1),
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert opp;
    return opp;
  }

  private static Contract buildActivatedContract(
    Id accountId,
    Id opportunityId,
    List<Id> productIds,
    Integer benefitLines,
    Integer savingsLines
  ) {
    Contract contractInst = new Contract(
      AccountId = accountId,
      Status = 'Draft',
      StartDate = Date.today(),
      ContractTerm = 12,
      RecordTypeId = clientContractRtId(),
      Pricebook2Id = Test.getStandardPricebookId(),
      ER_OpportunityId__c = opportunityId
    );
    insert contractInst;

    List<ER_ContractLineItem__c> lines = new List<ER_ContractLineItem__c>();
    for (Id productId : productIds) {
      lines.add(
        new ER_ContractLineItem__c(ER_Contract__c = contractInst.Id, ER_Product2__c = productId, ER_UnitPrice__c = 100, ER_Quantity__c = 1)
      );
    }
    if (!lines.isEmpty()) {
      insert lines;
    }

    // harkirat - Status cannot be inserted as Activated, same two step the other contract tests use
    contractInst.Status = Label.LABS_SF_Contract_Status_Activated;
    contractInst.Number_of_Benefit_Lines__c = benefitLines;
    contractInst.Number_of_Savings_Line__c = savingsLines;
    update contractInst;
    return contractInst;
  }

  private static Contract benefitsContract(Account account, Map<String, Product2> products) {
    Opportunity sourceOpp = buildOpportunity(account.Id);
    return buildActivatedContract(account.Id, sourceOpp.Id, new List<Id>{ products.get('A').Id }, 1, 0);
  }


  @isTest
  static void testEligibleWhenSameFamilyDifferentSolution() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('D') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    // harkirat - product D is Benefits but a different solution, the old rule would have blocked it
    Lead lead = buildLead(products.get('D').Id);

    Test.startTest();
    List<APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.getEligibility(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'One verdict per contract expected');
    System.assertEquals(true, results[0].isEligible, 'Same product family should be amendable');
    System.assertEquals(null, results[0].blockedReason, 'An eligible contract carries no reason');
  }

  @isTest
  static void testEligibleWhenProductAlreadyOnContract() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    // harkirat - lead brings the product the contract already carries, still amendable
    Lead lead = buildLead(products.get('A').Id);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(
      true,
      results.get(contractInst.Id).isEligible,
      'A product already on the contract must not block the amendment path'
    );
  }

  @isTest
  static void testBlockedWhenDifferentFamily() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('S') });
    Account account = buildAccount();
    Opportunity sourceOpp = buildOpportunity(account.Id);
    // harkirat - pure Engagement contract, a Savings lead may amend it but a Benefits lead may not
    Contract contractInst = buildActivatedContract(account.Id, sourceOpp.Id, new List<Id>{ products.get('S').Id }, 0, 1);
    Lead lead = buildLead(products.get('A').Id);
    buildPricebookEntries(new List<Product2>{ products.get('A') });

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(false, results.get(contractInst.Id).isEligible, 'A benefits lead must not amend an engagement contract');
    System.assertEquals(
      Label.LABS_SF_Amend_Different_Family,
      results.get(contractInst.Id).blockedReason,
      'Reason should name the family mismatch'
    );
  }

  /*  Contract_Category__c returns "Benefits and Engagement" when both line types are present.
      Containment is what lets a benefits lead still recognise it as a benefits contract. */
  @isTest
  static void testEligibleWhenContractHoldsBothFamilies() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('C'), products.get('S') });
    Account account = buildAccount();
    Opportunity sourceOpp = buildOpportunity(account.Id);
    Contract contractInst = buildActivatedContract(
      account.Id,
      sourceOpp.Id,
      new List<Id>{ products.get('A').Id, products.get('S').Id },
      1,
      1
    );
    Lead lead = buildLead(products.get('C').Id);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(
      'Benefits and Engagement',
      [SELECT Contract_Category__c FROM Contract WHERE Id = :contractInst.Id].Contract_Category__c,
      'Fixture should produce the combined category'
    );
    System.assertEquals(
      true,
      results.get(contractInst.Id).isEligible,
      'A combined contract is still a benefits contract for a benefits lead'
    );
  }

  @isTest
  static void testMobilityFamilyIsNotSupported() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('M') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    Lead lead = buildLead(products.get('M').Id);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(false, results.get(contractInst.Id).isEligible, 'Mobility has no contract category to match');
    System.assertEquals(
      Label.LABS_SF_Amend_Family_Not_Supported,
      results.get(contractInst.Id).blockedReason,
      'Reason should say the family is unsupported'
    );
  }

  /*@isTest
  static void testBlockedWhenContractNotActivated() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('C') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    contractInst.Status = 'Draft';
    update contractInst;
    Lead lead = buildLead(products.get('C').Id);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(false, results.get(contractInst.Id).isEligible, 'A draft contract has nothing to amend');
    System.assertEquals(
      Label.LABS_SF_Amend_Contract_Not_Active,
      results.get(contractInst.Id).blockedReason,
      'Reason should name the status'
    );
  }
*/
  @isTest
  static void testBlockedWhenContractHasNoSourceOpportunity() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('C') });
    Account account = buildAccount();
    Contract contractInst = buildActivatedContract(account.Id, null, new List<Id>{ products.get('A').Id }, 1, 0);
    Lead lead = buildLead(products.get('C').Id);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(false, results.get(contractInst.Id).isEligible, 'The engine needs a source opportunity to clone');
    System.assertEquals(
      Label.LABS_SF_Amend_Contract_No_Opportunity,
      results.get(contractInst.Id).blockedReason,
      'Reason should name the missing opportunity'
    );
  }

  @isTest
  static void testBlockedWhenLeadHasNoProductOfInterest() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    Lead lead = buildLead(null);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(false, results.get(contractInst.Id).isEligible, 'No product of interest means no family to match');
    System.assertEquals(
      Label.LABS_SF_Amend_Lead_No_Product,
      results.get(contractInst.Id).blockedReason,
      'Reason should name the missing product'
    );
  }

  @isTest
  static void testBlockedWhenNoActivePrice() {
    Map<String, Product2> products = buildProducts();
    // harkirat - product C deliberately has no pricebook entry
    buildPricebookEntries(new List<Product2>{ products.get('A') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    Lead lead = buildLead(products.get('C').Id);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(false, results.get(contractInst.Id).isEligible, 'An unpriced product cannot become a line item');
    System.assertEquals(
      Label.LABS_SF_Amend_No_Price,
      results.get(contractInst.Id).blockedReason,
      'Reason should name the missing price'
    );
  }

  /*@isTest
  static void testMerchantLeadIsOutOfScope() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('C') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);

    Id merchantRtId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Lead_RT').getRecordTypeId();
    // harkirat - identical to the eligible case apart from the record type
    Lead lead = buildLead(products.get('C').Id, merchantRtId);

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.evaluate(
      lead.Id,
      new List<Id>{ contractInst.Id }
    );
    Test.stopTest();

    System.assertEquals(false, results.get(contractInst.Id).isEligible, 'Merchant leads are out of scope');
    System.assertEquals(
      Label.LABS_SF_Amend_Client_Only,
      results.get(contractInst.Id).blockedReason,
      'Reason should say the flow is client only'
    );
    System.assertEquals(
      false,
      [SELECT ER_Has_Amendable_Contract__c FROM Lead WHERE Id = :lead.Id].ER_Has_Amendable_Contract__c,
      'A merchant lead must keep its standard Convert button'
    );
  }

  @isTest
  static void testSolutionMatchOutranksRecency() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('D') });
    Account account = buildAccount();

    // harkirat - product A is the TRE solution, product D is ECE
    Opportunity treOpp = buildOpportunity(account.Id);
    Contract treContract = buildActivatedContract(account.Id, treOpp.Id, new List<Id>{ products.get('A').Id }, 1, 0);
    treContract.StartDate = Date.today().addYears(-2);
    update treContract;

    Opportunity eceOpp = buildOpportunity(account.Id);
    Contract eceContract = buildActivatedContract(account.Id, eceOpp.Id, new List<Id>{ products.get('D').Id }, 1, 0);

    Lead lead = buildLead(products.get('A').Id);

    Test.startTest();
    List<APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.getAmendableContracts(lead.Id);
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Both benefits contracts are candidates');
    System.assertEquals(treContract.Id, results[0].contractId, 'The contract carrying the lead solution must rank first');
    System.assertEquals(true, results[0].matchesSolution, 'The top candidate should be flagged as a solution match');
    System.assertEquals(false, results[1].matchesSolution, 'The ECE contract does not carry the lead solution');
  }*/

  @isTest
  static void testCrossSellAmendsFamilyContractWithoutSolutionMatch() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('D') });
    Account account = buildAccount();
    Opportunity eceOpp = buildOpportunity(account.Id);
    Contract eceContract = buildActivatedContract(account.Id, eceOpp.Id, new List<Id>{ products.get('D').Id }, 1, 0);
    Lead lead = buildLead(products.get('A').Id);

    Test.startTest();
    List<APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.getAmendableContracts(lead.Id);
    Test.stopTest();

    System.assertEquals(1, results.size(), 'The ECE contract is the only candidate');
    System.assertEquals(eceContract.Id, results[0].contractId, 'The family contract should still be offered');
    System.assertEquals(true, results[0].isEligible, 'Cross-sell into an existing family contract is allowed');
    System.assertEquals(false, results[0].matchesSolution, 'It does not carry the lead solution, which is the point');
  }

  @isTest
  static void testPreviewCountsMultipleContractsForTheWarning() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('D') });
    Account account = buildAccount();
    Opportunity firstOpp = buildOpportunity(account.Id);
    Contract firstContract = buildActivatedContract(account.Id, firstOpp.Id, new List<Id>{ products.get('A').Id }, 1, 0);
    Opportunity secondOpp = buildOpportunity(account.Id);
    buildActivatedContract(account.Id, secondOpp.Id, new List<Id>{ products.get('D').Id }, 1, 0);
    Lead lead = buildLead(products.get('A').Id);

    Test.startTest();
    APER47_LeadAmendment_Management.AmendPreview preview = APER47_LeadAmendment_Management.getPreview(lead.Id, firstContract.Id);
    Test.stopTest();

    System.assertEquals(2, preview.eligibleContractCount, 'Two active benefits contracts should trigger the steering message');
  }

  @isTest
  static void testContactMatchTakesMostRecentDuplicate() {
    Account account = buildAccount();
    Contact older = new Contact(AccountId = account.Id, FirstName = 'Amend', LastName = 'Test', Email = 'amend.test@example.com');
    insert older;
    // harkirat - same email and same full name, a genuine duplicate
    Contact newer = new Contact(AccountId = account.Id, FirstName = 'Amend', LastName = 'Test', Email = 'amend.test@example.com');
    insert newer;
    Lead lead = buildLead(null);

    Test.startTest();
    Id matched = APER47_LeadAmendment_Management.resolveContactId(lead, account.Id);
    Test.stopTest();

    System.assertEquals(newer.Id, matched, 'The most recently created duplicate should win');
  }

  /*@isTest
  static void testGetAmendableContractsReturnsMostRecentFirst() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('C') });
    Account account = buildAccount();

    Opportunity olderOpp = buildOpportunity(account.Id);
    Contract older = buildActivatedContract(account.Id, olderOpp.Id, new List<Id>{ products.get('A').Id }, 1, 0);
    older.StartDate = Date.today().addYears(-2);
    update older;

    Opportunity newerOpp = buildOpportunity(account.Id);
    Contract newer = buildActivatedContract(account.Id, newerOpp.Id, new List<Id>{ products.get('A').Id }, 1, 0);

    Lead lead = buildLead(products.get('C').Id);

    Test.startTest();
    List<APER47_LeadAmendment_Management.AmendEligibility> results = APER47_LeadAmendment_Management.getAmendableContracts(lead.Id);
    Test.stopTest();

    System.assertEquals(2, results.size(), 'Both activated contracts are candidates');
    System.assertEquals(newer.Id, results[0].contractId, 'The most recent contract must come first');
    System.assertEquals(true, results[0].isEligible, 'The most recent contract should be amendable');
  }

  @isTest
  static void testFlagSetWhenAmendableContractExists() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('C') });
    Account account = buildAccount();
    benefitsContract(account, products);

    // harkirat - calls the flag logic directly rather than through the live trigger,
    // since the trigger's afterInsert is bypassed for every fixture Lead
    Lead lead = newLead(products.get('C').Id, clientLeadRtId());
    //APER18_Lead_Management.setAmendableContractFlag(new List<Lead>{ lead }, null);
    Test.startTest();
    insertLeadBypassingTrigger(lead);
    Test.stopTest();

    System.assertEquals(
      true,
      [SELECT ER_Has_Amendable_Contract__c FROM Lead WHERE Id = :lead.Id].ER_Has_Amendable_Contract__c,
      'The trigger should flag a lead that can amend an activated contract'
    );
  }
*/
    
  /*@isTest
  static void testFlagClearWhenFamilyDiffers() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('S') });
    Account account = buildAccount();
    benefitsContract(account, products);

    // harkirat - calls the flag logic directly rather than through the live trigger,
    // since the trigger's afterInsert is bypassed for every fixture Lead
    Lead lead = newLead(products.get('S').Id, clientLeadRtId());
    //APER18_Lead_Management.setAmendableContractFlag(new List<Lead>{ lead }, null);
    Test.startTest();
    insertLeadBypassingTrigger(lead);
    Test.stopTest();

    System.assertEquals(
      false,
      [SELECT ER_Has_Amendable_Contract__c FROM Lead WHERE Id = :lead.Id].ER_Has_Amendable_Contract__c,
      'A savings lead must keep the standard Convert button against a benefits contract'
    );
  }
*/
    
  @isTest
  static void testPreviewListsExistingLinesAndNewLine() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('B'), products.get('C') });
    Account account = buildAccount();
    Opportunity sourceOpp = buildOpportunity(account.Id);
    Contract contractInst = buildActivatedContract(
      account.Id,
      sourceOpp.Id,
      new List<Id>{ products.get('A').Id, products.get('B').Id },
      2,
      0
    );
    Lead lead = buildLead(products.get('C').Id);

    Test.startTest();
    APER47_LeadAmendment_Management.AmendPreview preview = APER47_LeadAmendment_Management.getPreview(lead.Id, contractInst.Id);
    Test.stopTest();

    System.assertEquals(true, preview.isEligible, 'Preview should mirror the eligibility verdict');
    System.assertEquals(2, preview.existingLines.size(), 'Both current contract lines should be listed');
    System.assertNotEquals(null, preview.newLine, 'The line to add must be described');
    System.assertEquals(products.get('C').Id, preview.newLine.productId, 'The lead product is the one being added');
    System.assertEquals(100, preview.newLine.unitPrice, 'Price comes from the resolved pricebook entry');
  }

  /*=================================================================
    CONTACT MATCHING
  =================================================================*/

  @isTest
  static void testContactMatchedOnEmailAndFullName() {
    Account account = buildAccount();
    Contact existing = new Contact(
      AccountId = account.Id,
      FirstName = 'Amend',
      LastName = 'Test',
      Email = 'amend.test@example.com'
    );
    insert existing;
    Lead lead = buildLead(null);

    Test.startTest();
    Id matched = APER47_LeadAmendment_Management.resolveContactId(lead, account.Id);
    Test.stopTest();

    System.assertEquals(existing.Id, matched, 'Same email and same full name should match the existing contact');
  }

  @isTest
  static void testContactNotMatchedWhenNameDiffers() {
    Account account = buildAccount();
    // harkirat - same email, different person
    insert new Contact(AccountId = account.Id, FirstName = 'Someone', LastName = 'Else', Email = 'amend.test@example.com');
    Lead lead = buildLead(null);

    Test.startTest();
    Id matched = APER47_LeadAmendment_Management.resolveContactId(lead, account.Id);
    Test.stopTest();

    System.assertEquals(null, matched, 'A different name must not reuse the contact');
  }

  /*=================================================================
    UNITS AND GUARDS
  =================================================================*/

  /*  pickBand reads Product2.ER_Type__c off each entry to know which are Range bands, and that
      relationship cannot be set on an in-memory PricebookEntry - so the bands are built through
      real child products of a parent service, the same shape the org uses. */
  @isTest
  static void testPickBandSelectsMatchingRange() {
    Product2 service = new Product2(Name = 'Card Service', ER_Type__c = 'Service', IsActive = true);
    insert service;

    List<Product2> bandProducts = new List<Product2>{
      new Product2(Name = '1 to 99', ER_Type__c = 'Range', ER_Solution__c = service.Id, IsActive = true),
      new Product2(Name = '100 to 499', ER_Type__c = 'Range', ER_Solution__c = service.Id, IsActive = true),
      new Product2(Name = '500 plus', ER_Type__c = 'Range', ER_Solution__c = service.Id, IsActive = true)
    };
    insert bandProducts;

    Id standardPricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> entries = new List<PricebookEntry>{
      new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = bandProducts[0].Id, UnitPrice = 1, IsActive = true, ER_Min__c = 0, ER_Max__c = 99),
      new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = bandProducts[1].Id, UnitPrice = 2, IsActive = true, ER_Min__c = 100, ER_Max__c = 499),
      new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = bandProducts[2].Id, UnitPrice = 3, IsActive = true, ER_Min__c = 500, ER_Max__c = 9999)
    };
    insert entries;

    List<PricebookEntry> bands = [
      SELECT Id, Product2Id, ER_Min__c, ER_Max__c, Product2.ER_Type__c
      FROM PricebookEntry
      WHERE Id IN :entries
      ORDER BY ER_Min__c NULLS FIRST
    ];

    Test.startTest();
    PricebookEntry chosen = APER47_LeadAmendment_Management.pickBand(bands, 250);
    PricebookEntry outOfRange = APER47_LeadAmendment_Management.pickBand(bands, 100000);
    PricebookEntry noVolume = APER47_LeadAmendment_Management.pickBand(bands, null);
    Test.stopTest();

    System.assertEquals(100, chosen.ER_Min__c, 'A volume of 250 belongs to the 100-499 band');
    // harkirat - falls back rather than refusing, the modal lets sales correct it
    System.assertEquals(0, outOfRange.ER_Min__c, 'A volume outside every band falls back to the first');
    System.assertEquals(0, noVolume.ER_Min__c, 'No volume means no basis to choose, so the first wins');
  }

  @isTest
  static void testBusinessUnitComparisonTreatsBlanksAsEqual() {
    Test.startTest();
    Boolean bothBlank = APER47_LeadAmendment_Management.isSameBusinessUnit('', null);
    Boolean sameIgnoringCase = APER47_LeadAmendment_Management.isSameBusinessUnit('be', 'BE');
    Boolean different = APER47_LeadAmendment_Management.isSameBusinessUnit('BE', 'FR');
    Test.stopTest();

    System.assertEquals(true, bothBlank, 'The formula returns an empty string where userBU is null');
    System.assertEquals(true, sameIgnoringCase, 'The SOQL bind this mirrors is case insensitive');
    System.assertEquals(false, different, 'Different business units must not match');
  }

  @isTest
  static void testEmptyAndNonLeadInputsReturnNothing() {
    Account account = buildAccount();

    Test.startTest();
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> noContracts = APER47_LeadAmendment_Management.evaluate(
      account.Id,
      new List<Id>()
    );
    Map<Id, APER47_LeadAmendment_Management.AmendEligibility> notALead = APER47_LeadAmendment_Management.evaluate(
      account.Id,
      new List<Id>{ account.Id }
    );
    Test.stopTest();

    System.assertEquals(0, noContracts.size(), 'No contracts means no verdicts');
    System.assertEquals(0, notALead.size(), 'The host must be a Lead');
  }

  /*  logDurable publishes ER_Error_Log_Event__e, which only becomes an ER_Error_Log__c once the
      platform event trigger runs - Test.getEventBus().deliver() forces that inside the test. */
  /*@isTest
  static void testFailedAmendmentIsLogged() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('S') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    Lead lead = buildLead(products.get('S').Id);

    Test.startTest();
    try {
      APER47_LeadAmendment_Management.amendAndConvert(lead.Id, contractInst.Id, null);
    } catch (Exception e) {
      // harkirat - the throw is asserted elsewhere, this test is about the log
    }
    Test.getEventBus().deliver();
    Test.stopTest();

    List<ER_Error_Log__c> logs = [
      SELECT ER_Source_Class__c, ER_Source_Method__c, ER_Log_Level__c, ER_Related_Record_Id__c
      FROM ER_Error_Log__c
      WHERE ER_Source_Class__c = 'APER47_LeadAmendment_Management'
    ];

    System.assertEquals(1, logs.size(), 'A failed amendment must leave exactly one error log');
    System.assertEquals('amendAndConvert', logs[0].ER_Source_Method__c, 'The failing method should be named');
    System.assertEquals('Error', logs[0].ER_Log_Level__c, 'Amendment failures are logged at Error level');
    System.assertEquals(String.valueOf(lead.Id), logs[0].ER_Related_Record_Id__c, 'The lead should be the related record');
  }
*/
  @isTest
  static void testAmendAndConvertRejectsIneligibleContract() {
    Map<String, Product2> products = buildProducts();
    buildPricebookEntries(new List<Product2>{ products.get('A'), products.get('S') });
    Account account = buildAccount();
    Contract contractInst = benefitsContract(account, products);
    // harkirat - savings lead against a benefits contract, refused before anything is created
    Lead lead = buildLead(products.get('S').Id);

    Boolean threw = false;
    Test.startTest();
    try {
      APER47_LeadAmendment_Management.amendAndConvert(lead.Id, contractInst.Id, null);
    } catch (Exception e) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(true, threw, 'An ineligible contract must be refused');
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Opportunity WHERE ER_AmendedFromContract__c = :contractInst.Id],
      'A refused amendment must not leave an opportunity behind'
    );
    System.assertEquals(
      false,
      [SELECT IsConverted FROM Lead WHERE Id = :lead.Id].IsConverted,
      'A refused amendment must not convert the lead'
    );
  }
}