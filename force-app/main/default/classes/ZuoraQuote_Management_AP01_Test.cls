/*
----------------------------------------------------------------------
-- - Name          : ZuoraQuote_Management_AP01_Test
-- - Author        : AAZ
-- - Description   : Test class for Financial Center Management.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JUNE-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
@isTest
public class ZuoraQuote_Management_AP01_Test {
  @TestSetup
  static void testSetup() {
    User man = TestDataFactory.newUser('manager', 'manager', 'System Administrator', 'FR');
    man.ER_BypassVR__c = true;
    insert man;

    User ur = TestDataFactory.newUser('user', 'user', 'Local Admin', 'FR');
    ur.ER_BypassVR__c = true;
    ur.ManagerId = man.Id;
    insert ur;

    System.runAs(ur) {
      Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testnewZuoraQuote');
      newMerchantAccount.ER_SmartER_Context__c = true;
      insert newMerchantAccount;

      Contact ctc = new Contact();
      ctc.MailingCountry = 'Poland';
      ctc.AccountId = newMerchantAccount.Id;
      ctc.LastName = 'bilTto';
      ctc.FirstName = 'contact';
      ctc.Email = 'bilTto.contact@zuora.com';
      ctc.ER_Language__c = 'FR';
      insert ctc;

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'Opp testnewZuoraQuote'
      );
      newOpportunity.AccountId = newMerchantAccount.Id;
      //Adding new so that the Add to branch ticket does not throw error Controlling field added by baptist
      newOpportunity.Onboarding_Method__c = 'OSS';
      newOpportunity.Impacted_Beneficiaries__c = 'All';
      //newOpportunity.ER_SmartER_Context__c = true;
      insert newOpportunity;

      Opportunity newOpportunity1 = APER07_UtilityTestMethod.getOpportunity(
        'ER_Client_Opportunity_RT',
        'Opp testnewZuoraQuote'
      );
      newOpportunity1.AccountId = newMerchantAccount.Id;
      newOpportunity1.ER_SmartER_Context__c = true;
      insert newOpportunity1;

      zqu__Quote__c newZQuote = APER07_UtilityTestMethod.getZuoraQuote('Default');
      newZQuote.zqu__Account__c = newMerchantAccount.Id;
      newZQuote.zqu__Opportunity__c = newOpportunity.Id;
      newZQuote.zqu__Currency__c = 'PLN';
      newZQuote.zqu__StartDate__c = Date.today();
      newZQuote.zqu__BillToContact__c = ctc.Id;
      newZQuote.ER_Business_Unit__c = 'PL';
      //DKB : COUL-4291
      newZQuote.zqu__ZuoraAccountID__c = newMerchantAccount.Id;
      //DKB: COUL-4291
      insert newZQuote;

      zqu__Quote__c newZQuote1 = APER07_UtilityTestMethod.getZuoraQuote('Default');
      newZQuote1.zqu__Account__c = newMerchantAccount.Id;
      newZQuote1.zqu__Opportunity__c = newOpportunity1.Id;
      newZQuote1.zqu__Currency__c = 'EUR';
      newZQuote1.zqu__StartDate__c = Date.today();
      newZQuote1.zqu__BillToContact__c = ctc.Id;
      newZQuote1.ER_Business_Unit__c = 'FR';
      //DKB : COUL-4291
      newZQuote1.zqu__ZuoraAccountID__c = newMerchantAccount.Id;
      //DKB: COUL-4291
      insert newZQuote1;
      id firstid = newZQuote1.id;
      newZQuote1.id = null;
      insert newZQuote1;

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('Solution TR1');
      newSolution.ProductCode = 'TR1';
      insert newSolution;

      zqu__QuoteAmendment__c qAmendment = APER07_UtilityTestMethod.newQuoteAmendment(newZQuote.Id);
      insert qAmendment;

      zqu__ProductRatePlan__c productRP = APER07_UtilityTestMethod.getZuoraProductRP(newSolution.Id);
      insert productRP;

      zqu__QuoteRatePlan__c quoteRP = APER07_UtilityTestMethod.getZuoraQuoteRP(
        newZQuote.Id,
        productRP.Id,
        qAmendment.Id,
        newSolution.Name
      );
      insert quoteRP;

      zqu__QuoteRatePlan__c quoteRP1 = APER07_UtilityTestMethod.getZuoraQuoteRP(
        firstid,
        productRP.Id,
        qAmendment.Id,
        newSolution.Name
      );
      insert quoteRP1;

      zqu__QuoteChargeDetail__c qcd = new zqu__QuoteChargeDetail__c(
        zqu__Quote__c = newZQuote.Id,
        zqu__ProductRatePlan__c = productRP.Id
      );
      insert qcd;

      zqu__QuoteRatePlanCharge__c qrpch = new zqu__QuoteRatePlanCharge__c();
      qrpch.ER_Quote__c = newZQuote.Id;
      qrpch.zqu__QuoteRatePlan__c = quoteRP.Id;
      insert qrpch;

      zqu__QuoteRatePlanCharge__c qrpch1 = new zqu__QuoteRatePlanCharge__c();
      qrpch1.ER_Quote__c = firstid;
      qrpch1.zqu__QuoteRatePlan__c = quoteRP1.Id;
      insert qrpch1;
    }
  }

  @IsTest
  static void testCreateSFContract() {
    zqu__Quote__c newZQuote = [SELECT Id, zqu__Status__c FROM zqu__Quote__c LIMIT 1];

    Test.startTest();
    newZQuote.zqu__Status__c = Constants.QUOTE_STATUS_ACCEPTED;
    update newZQuote;

    Contract insertedContract = [SELECT Id, Name, ER_ZuoraQuote__c FROM Contract LIMIT 1];
    System.debug('>>>>> AAZ - testCreateSFContract:' + insertedContract);
    System.assertEquals(insertedContract.ER_ZuoraQuote__c, newZQuote.Id);
    Test.stopTest();
  }

  @IsTest
  static void testupdateNumberOfHighDiscounts() {
    zqu__QuoteRatePlanCharge__c newZQRPC = [
      SELECT Id, zqu__Discount__c, ER_Quote__c
      FROM zqu__QuoteRatePlanCharge__c
      WHERE ER_Quote__r.ER_Business_Unit__c = 'FR'
      LIMIT 1
    ];

    Test.startTest();
    newZQRPC.zqu__Discount__c = 20;
    update newZQRPC;

    zqu__Quote__c linkedZQuote = [
      SELECT Id, ER_Has_Discount_Requires_Approval__c
      FROM zqu__Quote__c
      WHERE ER_Business_Unit__c = 'FR'
      LIMIT 1
    ];
    //System.assertEquals(linkedZQuote.ER_Has_Discount_Requires_Approval__c, true);

    ZuoraQuote_Management_AP01.submitZQuoteForApproval(linkedZQuote.Id, 'Some comment');
    ZuoraQuote_Management_AP01.recallApproval(linkedZQuote.Id, 'Some comment');
    ZuoraQuote_Management_AP01.updateZuoraAccountsAsync(new List<Id>{ linkedZQuote.Id });
    Test.stopTest();
  }

  @IsTest
  static void testupdateZuoraApprovalStatus() {
    User ur = [
      SELECT Id, ManagerId, Manager.Name, FirstName, LastName, IsActive
      FROM User
      WHERE LastName LIKE 'user%' AND ER_Business_Unit__c = 'FR'
      LIMIT 1
    ];
    System.debug(
      '>>>>> ALK - FirstName : ' +
      ur.FirstName +
      ' - LastName : ' +
      ur.LastName +
      ' Maanger - ' +
      ur.Manager.Name
    );

    System.runAs(ur) {
      zqu__Quote__c zQuote = [
        SELECT Id, Owner.Name, zqu__Status__c
        FROM zqu__Quote__c
        WHERE ER_Business_Unit__c = 'FR'
        LIMIT 1
      ];
      System.debug('>>>>> ALK - zQuote Owner.Name ' + zQuote.Owner.Name);

      Test.startTest();
      zQuote.ER_Has_Discount_Requires_Approval__c = true;
      update zQuote;
      Test.stopTest();
    }
  }

  @IsTest
  static void increaseCoverage() {
    zqu__Quote__c newZQuote = [
      SELECT Id, zqu__Status__c, ER_Agreement_DateTime__c, ER_Customer_Signed_Version__c, ER_SmartER_Context__c
      FROM zqu__Quote__c
      LIMIT 1
    ];
    zqu__QuoteRatePlanCharge__c newZQRPC = [SELECT Id FROM zqu__QuoteRatePlanCharge__c LIMIT 1];

    Test.startTest();
    ZuoraQuote_Management_AP01.updateTCsAgreementDate(new List<zqu__Quote__c>{ newZQuote });
    delete newZQuote;
    undelete newZQuote;

    delete newZQRPC;
    undelete newZQRPC;
    Test.stopTest();
  }

  @IsTest
  static void testGetTCs_OK() {
    Test.startTest();
    zqu__Quote__c newZQuote = [SELECT Id FROM zqu__Quote__c WHERE ER_Business_Unit__c = 'FR' LIMIT 1];

    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);

    System.assertEquals(null, ZuoraQuote_Management_AP01.getTCs(newZQuote.Id));
    newZQuote = [
      SELECT Id, ER_Customer_Signed_Version__c, ER_TCs_Signed_Link__c, ER_Agreement_DateTime__c, zqu__Status__c
      FROM zqu__Quote__c
      WHERE Id = :newZQuote.Id
    ];

    System.assertEquals('20220130', newZQuote.ER_Customer_Signed_Version__c);
    System.assertEquals('https://assets.ctfassets.net/emupgefw7b1n/5rr/TCs.pdf', newZQuote.ER_TCs_Signed_Link__c);
    //Datetime agreeTime = newZQuote.ER_Agreement_DateTime__c;
    //System.assertEquals(agreeTime.date(), Date.today());

    // Check document link creation
    List<ContentDocumentLink> cdLinks = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :newZQuote.Id
    ];
    System.assertEquals(1, cdLinks.size());

    String pathOnClt = newZQuote.id + '_' + 'fr_termsConditionsSaleClient_20220130.pdf';
    System.assertEquals(1, [SELECT Id FROM ContentVersion WHERE PathOnClient = :pathOnClt].size());

    Test.stopTest();
    // Cover generation on an other quote
    zqu__Quote__c newZQuote_2 = [
      SELECT Id
      FROM zqu__Quote__c
      WHERE ER_Business_Unit__c = 'FR' AND id != :newZQuote.id
      LIMIT 1
    ];
    System.assertEquals(null, ZuoraQuote_Management_AP01.getTCs(newZQuote_2.Id));
    newZQuote_2 = [
      SELECT Id, ER_Customer_Signed_Version__c, ER_TCs_Signed_Link__c, ER_Agreement_DateTime__c, zqu__Status__c
      FROM zqu__Quote__c
      WHERE Id = :newZQuote_2.Id
    ];

    System.assertEquals('20220130', newZQuote_2.ER_Customer_Signed_Version__c);
    System.assertEquals('https://assets.ctfassets.net/emupgefw7b1n/5rr/TCs.pdf', newZQuote_2.ER_TCs_Signed_Link__c);
    //Datetime agreeTime_2 = newZQuote_2.ER_Agreement_DateTime__c;
    //System.assertEquals(agreeTime_2.date(), Date.today());

    // Check document link creation
    List<ContentDocumentLink> cdLinks_2 = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :newZQuote_2.Id
    ];
    Set<id> contentDocs = new Set<Id>();
    for (ContentDocumentLink docLink : cdLinks_2) {
      contentDocs.add(docLink.ContentDocumentId);
    }
    // Check if the content document is different between newZquote and newZquote_2
    for (ContentDocumentLink docLink : cdLinks) {
      System.assertEquals(false, contentDocs.contains(docLink.ContentDocumentId));
    }

    // check the contract generation :
    newZQuote.zqu__Status__c = Constants.QUOTE_STATUS_ACCEPTED;
    update newZQuote;

    Contract createdCtr = [SELECT id FROM Contract ORDER BY createddate DESC LIMIT 1];
    System.assertEquals(
      1,
      [
          SELECT Id
          FROM ContentDocumentLink
          WHERE ContentDocumentId = :cdLinks[0].ContentDocumentId AND LinkedEntityId = :createdCtr.id
        ]
        .size()
    );
  }

  @IsTest
  static void testGetTCs_KO() {
    Test.startTest();
    zqu__Quote__c newZQuote = [SELECT Id FROM zqu__Quote__c LIMIT 1];

    SmarterAPIMock smarterMock = new SmarterAPIMock();
    SmarterAPIMock.serviceToFail = Constants.SMARTER_GET_TCs_SERVICE_NAME;
    Test.setMock(HttpCalloutMock.class, smarterMock);

    System.assertEquals('ASSERT ERROR MESSAGE', ZuoraQuote_Management_AP01.getTCs(newZQuote.Id));
    Test.stopTest();
  }
}