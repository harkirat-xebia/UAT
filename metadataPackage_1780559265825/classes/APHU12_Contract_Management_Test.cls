/*
----------------------------------------------------------------------
-- - Name          : APER12_Contract_Management_Test
-- - Author        : OLA
-- - Description   : TEST for Contract Management class
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Feb-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APHU12_Contract_Management_Test {
  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APHU12', 'APHU12', 'Local Admin', 'Spain', 'BE');
    ur.ER_BypassVR__c = true;
    ur.ER_bypassTrigger__c = true;
    ur.ER_Bypass_Triggers__c = 'FinancialCenterTrigger';

    insert ur;
    System.runAs(ur) {
      System.debug('//NGO testSetup user' + [SELECT ER_BUText__c, ER_Business_Unit__c FROM User WHERE Id = :ur.Id]);

      UtilsBypass.reset();
      Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('APHU12_Contract_Management_Test');

      insert newMerchantAccount;
      System.debug(
        '//NGO testSetup account' +
        [SELECT ER_BUPicklist__c, ER_Business_Unit__c FROM Account WHERE Id = :newMerchantAccount.Id]
      );
      PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
      //update newPriceBook;
      String pricebookId = newPriceBook.id;

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'EDPO_TR_APM_PLN|ERPO_GIFT_ATM_PIN|ERPO_GIFT_PLN|ERPO_HOL_NOATM_PLN|ERPO_GIFT_PIN_PLN|ERPO_HOL_RL_PLN|ERPO_GIFT_ATM_NOFEE|EDPO_TR_EL_ANON_PLN|ERPO_GIFT_ATM_FEE|EDPO_TR_FLX_PLN|ERPO_FLX_PIN|EDPO_TR_RL_ANON_PLN|ERPO_CORP_GIFT_PLN|ERPO_ANON_AML_PLN';
      newSolution.BU_External_Reference__c = 'EDPO_TR_APM_PLN|ERPO_GIFT_ATM_PIN|ERPO_GIFT_PLN|ERPO_HOL_NOATM_PLN|ERPO_GIFT_PIN_PLN|ERPO_HOL_RL_PLN|ERPO_GIFT_ATM_NOFEE|EDPO_TR_EL_ANON_PLN|ERPO_GIFT_ATM_FEE|EDPO_TR_FLX_PLN|ERPO_FLX_PIN|EDPO_TR_RL_ANON_PLN|ERPO_CORP_GIFT_PLN|ERPO_ANON_AML_PLN';
      insert newSolution;

      Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
      newService.ProductCode = 'EDPO_TR_APM_PLN';
      newService.BU_External_Reference__c = 'EDPO_TR_APM_PLN';

      insert newService;

      PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
      insert newPriceBookEntry;

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'APHU12_Contract_Management_Test'
      );
      newOpportunity.AccountId = newMerchantAccount.Id;
      newOpportunity.ER_BUPicklist__c = 'BE';
      newOpportunity.ER_PaymentMethod__c = 'Direct Debit';
      newOpportunity.ER_InvoicingFrequency__c = 'Monthly';
      newOpportunity.ER_Contract_Expected_Start_Date__c = Date.Today();
      newOpportunity.Commercial_Origin__c = 'Changement de TVA';
      insert newOpportunity;
      System.debug(
        '//NGO testSetup opp' +
        [SELECT ER_BUPicklist__c, ER_Business_Unit__c FROM Opportunity WHERE Id = :newOpportunity.Id]
      );

      OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
        newOpportunity.id,
        newPriceBookEntry.id
      );
      insert newOpportunityProduct;

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'APER14_Store_Management_Test',
        newMerchantAccount.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      insert testFinancialCenter;

      ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
        'APER14_Store_Management_Test',
        newMerchantAccount.id,
        testFinancialCenter.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      insert testStore;

      Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
        'ER_Merchant_Quote',
        'APHU12_Contract_Management_Test',
        newOpportunity.id,
        pricebookId
      );
      insert merchantQuote;

      QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
      insert qli;

      Contract testContract = APER07_UtilityTestMethod.getContract(
        newMerchantAccount.Id,
        Date.today(),
        Label.LABS_SF_Contract_Status_Draft,
        newPriceBook.Id
      );
      testContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
        .get('ER_Merchant_Contract_RT')
        .getRecordTypeId();
      testContract.ER_Contract_Type__c = Label.LAB_SF_Contact_Operational;

      insert testContract;

      List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
      ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(
        testContract.Id,
        newService.Id,
        newPriceBookEntry.Id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem);
      insert cliListToInsert;

      Contract testContract2 = APER07_UtilityTestMethod.getContract(
        newMerchantAccount.Id,
        Date.today(),
        Label.LABS_SF_Contract_Status_Draft,
        newPriceBook.Id
      );
      testContract2.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
        .get('ER_Merchant_Contract_RT')
        .getRecordTypeId();
      testContract2.ER_Contract_Type__c = Label.LAB_SF_Contact_Operational;
      testContract.ER_OpportunityId__c = newOpportunity.Id;
      insert testContract2;

      List<ER_ContractLineItem__c> cliListToInsert2 = new List<ER_ContractLineItem__c>();
      ER_ContractLineItem__c testContractLineItem2 = APER07_UtilityTestMethod.getContractLineItem(
        testContract2.Id,
        newService.Id,
        newPriceBookEntry.Id,
        1,
        1
      );
      cliListToInsert2.add(testContractLineItem2);

      insert cliListToInsert2;
    }
  }

  static void acceptQuote() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    //System.debug('zzz  profileId: '+ur.profileId);
    //insert ur;
    System.runAs(ur) {
      List<Quote> quoteList = [SELECT id FROM Quote WHERE Name = 'APHU12_Contract_Management_Test' FOR UPDATE];

      if (!quoteList.isEmpty()) {
        Quote quoteInst = quoteList[0];
        quoteInst.Status = Label.LABS_SF_Quote_Status_Accepted;
        update quoteInst;
      }
    }
  }

  static void denyQuote() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;
    System.runAs(ur) {
      List<Quote> quoteList = [SELECT id FROM Quote WHERE Name = 'APHU12_Contract_Management_Test' FOR UPDATE];

      if (!quoteList.isEmpty()) {
        Quote quoteInst = quoteList[0];
        quoteInst.Status = Label.LABS_SF_Quote_Status_Accepted;
        update quoteInst;

        quoteInst.Status = Label.LABS_SF_Quote_Status_Denied;
        update quoteInst;

        Map<id, Quote> acceptedQuoteMap = new Map<id, Quote>();
        acceptedQuoteMap.put(quoteInst.Id, quoteInst);
        // APHU12_Contract_Management.deleteContractFromQuote(quoteInst.Id);
        APHU12_Contract_Management.createCLIAndUpdateOpportunity(acceptedQuoteMap);
      }
    }
  }

  static testMethod void testActivateContractAndAmendment() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;
    System.runAs(ur) {
      APHU12_Contract_Management_Test.acceptQuote();

      List<Contract> contractList = [
        SELECT id
        FROM Contract
        WHERE status = :Label.LABS_SF_Contract_Status_Draft
        LIMIT 1
      ];

      if (!contractList.isEmpty()) {
        contractList = APHU12_Contract_Management.getContract(contractList[0].id);
        if (!contractList.isEmpty()) {
          Test.startTest();
          APHU12_Contract_Management.activateContractController(
            contractList[0],
            contractList[0].ER_OpportunityId__c,
            false
          );
          Opportunity amendedOpportunity = APHU12_Contract_Management.contractAmendment(
            contractList[0].id,
            contractList[0].ER_OpportunityId__c
          );
          if (amendedOpportunity != null) {
            APER04_Opportunity_Management.discardAmendement(amendedOpportunity.Id);
          }

          APHU12_Contract_Management.contractAmendment(contractList[0].id, '');
          contractList = [
            SELECT id, Status, AccountId, ER_OpportunityId__r.ER_IsAmended__c, ER_OpportunityId__r.Name
            FROM Contract
            WHERE status = :Label.LABS_SF_Contract_Status_Activated
            LIMIT 1
          ];
          if (!contractList.isEmpty()) {
            try {
              Map<String, String> mapSolutionsCMOid = new Map<String, String>();
              //APHU12_Contract_Management.saveContractEdgWS(contractList[0], 'Activation');
              APHU12_Contract_Management.isOfflineBU(contractList[0]);
              APHU12_Contract_Management.updateContractLineItemsFromWS(mapSolutionsCMOid, contractList[0], false, '');
              APHU12_Contract_Management.updateContractWsInfos(contractList[0], false, '');
            } catch (Exception e) {
              //
            }
            APHU12_Contract_Management.terminateContract(contractList[0], false);
          }
          Test.stopTest();
          System.debug('#### contractList : ' + contractList);
        }
      }
    }
  }
  static testMethod void deleteCLIFromContract() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;
    System.runAs(ur) {
      APHU12_Contract_Management_Test.acceptQuote();

      Map<id, Contract> contractMap = new Map<id, Contract>(
        [SELECT id FROM Contract WHERE status = :Label.LABS_SF_Contract_Status_Draft LIMIT 1]
      );

      if (!contractMap.isEmpty()) {
        APHU12_Contract_Management.deleteCLIFromContract(contractMap);
      }
    }
  }
  static testMethod void getAccountWS() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;
    System.runAs(ur) {
      List<Account> accountList = [SELECT id FROM Account LIMIT 1];
      if (!accountList.isEmpty()) {
        APHU12_Contract_Management.getAccountWS(accountList[0].Id);
      }
    }
  }

  static testMethod void beforeEdgWS() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;

    System.runAs(ur) {
      Test.startTest();
      ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
        UserInfo.getOrganizationId()
      );
      settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
      upsert settings;

      APHU12_Contract_Management_Test.acceptQuote();
      List<Account> accountList = [SELECT id FROM Account LIMIT 1];

      List<Contract> contractList = [SELECT Id FROM Contract];
      List<Contract> contractListActivate = APHU12_Contract_Management.getContract(contractList[0].id);
      APHU12_Contract_Management.activateContractController(
        contractListActivate[0],
        contractListActivate[0].ER_OpportunityId__c,
        false
      );

      APHU12_Contract_Management.beforeEdgWS(accountList[0].Id, contractList[1].Id);
      Test.stopTest();
    }
  }

  static testMethod void saveEdgWS() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;
    System.runAs(ur) {
      List<Account> accountList = [SELECT id FROM Account LIMIT 1];
      if (!accountList.isEmpty()) {
        try {
          APHU12_Contract_Management.saveEdgWS(accountList[0].Id, null);
        } catch (Exception e) {
          //The rest is covered by an other class
        }
      }
    }
  }

  @IsTest
  static void coverSomeMethodsTest() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;
    System.runAs(ur) {
      Test.startTest();
      List<Quote> quotes = [SELECT Id, OpportunityId FROM Quote WHERE Name = 'APHU12_Contract_Management_Test'];

      List<Contract> contracts = [
        SELECT
          Id,
          RecordTypeId,
          ER_Business_Unit__c,
          ER_InvoicingFrequency2__c,
          ER_ReimbursementTerm2__c,
          CustomerSigned.Email,
          CustomerSignedId,
          Status,
          ER_Indexation__c,
          ER_OppIndexation2__c,
          ER_PaymentTerms2__c,
          ER_PaymentMethod2__c,
          Account.ER_VIP__c,
          Subscription__c,
          ER_ZuoraQuote__c,
          AccountId,
          Account.Name,
          StartDate,
          EndDate,
          RecordType.DeveloperName,
          ER_OpportunityId__c,
          ER_OpportunityId__r.ER_IsAmended__c,
          ER_OpportunityId__r.ER_AmendedFromContract__c,
          ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId,
          ContractNumber,
          ER_Creation_date_in_OS__c,
          CustomerSignedDate,
          ER_OpportunityId__r.ER_AmendedFromContract__r.StartDate,
          ER_Contract_Type__c,
          ER_Original_Agreement__c,
          ER_Original_Agreement__r.Status,
          ER_Original_Agreement__r.ER_Contract_Type__c
        FROM Contract
      ];

      contracts[0].Status = Label.LABS_SF_Contract_Status_Activated;
      update contracts[0];
      contracts[1].Status = Label.LABS_SF_Contract_Status_Activated;
      update contracts[1];

      APHU12_Contract_Management.checkExistingSolutionsContract(contracts[0]);
      APHU12_Contract_Management.checkExistingSolutionsContract(contracts[1]);
      //APHU12_Contract_Management.saveContractEdgWS(contracts[0], 'Activation');
      //APHU12_Contract_Management.saveContractEdgWS(contracts[1], 'Activation');

      Test.stopTest();
    }
  }

  static testMethod void checkExistingSolution() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = false;
    update ur;
    System.runAs(ur) {
      UtilsBypass.reset();
      //Test.startTest();
      ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
        UserInfo.getOrganizationId()
      );
      settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
      upsert settings;
      APHU12_Contract_Management_Test.acceptQuote();
      List<Account> accountList = [SELECT id FROM Account LIMIT 1];
      List<Contract> contractList = [SELECT Id FROM Contract];
      List<Contract> contractListActivate = APHU12_Contract_Management.getContract(contractList[0].id);
      APHU12_Contract_Management.activateContractController(
        contractListActivate[0],
        contractListActivate[0].ER_OpportunityId__c,
        false
      );
      ur.ER_BypassVR__c = false;
      UtilsBypass.setCurrentUserParameter(ur);
      APHU12_Contract_Management.checkExistingSolutionsContractOnAccount(accountList[0].Id, contractList[1].Id);
      //Test.stopTest();
    }
  }

  static testMethod void checkLegalAddress() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;

    System.runAs(ur) {
      Test.startTest();
      ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
        UserInfo.getOrganizationId()
      );
      settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
      upsert settings;

      APHU12_Contract_Management_Test.acceptQuote();
      List<Account> accountList = [SELECT id FROM Account LIMIT 1];

      List<Contract> contractList = [SELECT Id FROM Contract];
      List<Contract> contractListActivate = APHU12_Contract_Management.getContract(contractList[0].id);
      APHU12_Contract_Management.activateContractController(
        contractListActivate[0],
        contractListActivate[0].ER_OpportunityId__c,
        false
      );

      accountList[0].BillingCity = '';
      accountList[0].BillingStreet = '';
      accountList[0].BillingPostalCode = '';
      update accountList[0];
      APHU12_Contract_Management.beforeEdgWS(accountList[0].Id, contractList[1].Id);
      Test.stopTest();
    }
  }

  static testMethod void checkBeforeEdgeWSHU() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;

    System.runAs(ur) {
      Test.startTest();
      ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
        UserInfo.getOrganizationId()
      );
      settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
      upsert settings;

      APHU12_Contract_Management_Test.acceptQuote();
      List<Account> accountList = [SELECT id FROM Account LIMIT 1];
      accountList[0].OwnerId = ur.Id;
      accountList[0].ER_Registration_Number__c = null;
      accountList[0].HU_HQ_Contact__c = null;
      update accountList;

      Contact contactTest = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'Test', 'Test');
      contactTest.AccountId = accountList[0].Id;
      contactTest.Email = '';
      contactTest.ER_Account_Address_Sync__c = Label.LABS_SF_Account_SyncAddressContact;
      insert contactTest;

      List<Contract> contractList = [SELECT Id FROM Contract];
      contractList[0].CustomerSignedId = contactTest.Id;
      update contractList;

      List<Contract> contractListActivate = APHU12_Contract_Management.getContract(contractList[0].id);
      APHU12_Contract_Management.activateContractController(
        contractListActivate[0],
        contractListActivate[0].ER_OpportunityId__c,
        false
      );

      accountList[0].BillingCity = '';
      accountList[0].BillingStreet = '';
      accountList[0].BillingPostalCode = '';
      update accountList[0];
      APHU12_Contract_Management.beforeEdgWS(accountList[0].Id, contractList[1].Id);
      Test.stopTest();
    }
  }

  //snica
  static testMethod void checkStartDateAcceptorTest() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APHU12'];
    ur.ER_BypassVR__c = true;
    update ur;

    System.runAs(ur) {
      List<Account> merchant = [SELECT Id, ER_Aggregator__c, RecordTypeId FROM Account];
      merchant[0].ER_Aggregator__c = true;
      merchant[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('ER_Company_Account_RT')
        .getRecordTypeId();
      update merchant;
      ER_Acceptor__c acceptor = new ER_Acceptor__c();

      acceptor.Name = 'checkStartDateAcceptorTest';
      acceptor.ER_Aggregator__c = merchant[0].Id;
      acceptor.ER_Start_Date__c = null;
      insert acceptor;
      Test.startTest();
      APHU12_Contract_Management.checkStartDateAcceptor(merchant[0]);
      Test.stopTest();
    }
  }

  static testMethod void checkLegalNameAddressHeadOfficeTest() {
    List<Account> merchant = [
      SELECT
        Id,
        Name,
        ER_Legal_Name__c,
        ER_Creation_date_in_OS__c,
        HU_HQ_Contact__c,
        BillingStreet,
        BillingPostalCode,
        BillingCity
      FROM Account
    ];
    merchant[0].BillingCity = '';
    merchant[0].BillingPostalCode = '';
    merchant[0].BillingStreet = '';
    update merchant;

    Test.startTest();
    APHU12_Contract_Management.checkLegalName(merchant[0]);
    APHU12_Contract_Management.checkHeadOfficeContact(merchant[0]);
    APHU12_Contract_Management.checkLegalAddress(merchant[0]);
    Test.stopTest();
  }

  static testMethod void checkStoreContactTest() {
    List<Account> merchant = [SELECT Id, ER_Creation_date_in_OS__c, (SELECT Id, Name, ER_Contact__c FROM Stores__r) FROM Account];

    Test.startTest();
    APHU12_Contract_Management.checkStoreContact(merchant[0]);
    Test.stopTest();
  }

  @IsTest
  static void updateContractWsInfosTest() {
    List<Contract> contractList = [
      SELECT
        AccountId,
        Id,
        ER_Creation_date_in_OS__c,
        ER_TerminationReason__c,
        ER_Termination_date_in_OS__c,
        ER_Terminated_Date__c,
        ER_Last_date_of_Sync__c
      FROM Contract
    ];

    Test.startTest();
    APHU12_Contract_Management.updateContractWsInfos(contractList[0], false, 'Termination');
    Test.stopTest();
  }
}