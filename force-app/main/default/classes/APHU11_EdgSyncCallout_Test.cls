/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 08-17-2023
 * @last modified by  : Malha AMEUR
**/
@isTest
public class APHU11_EdgSyncCallout_Test {
  public static final Integer iNumCnt = 1;
  public static final Integer iNumFC = 1;
  public static List<ER_Financial_Center__c> financialList;
  public static List<ER_Store__c> storeList;
  public static List<ER_Acceptor__c> acceptorList;

  @istest
  public static void TestErrorsBeforeEDG() {
    User ur = TestDataFactory.newUser('APHU12', 'APHU12', 'Local Admin', 'Czech_Republic', 'BE');
    ur.ER_BypassVR__c = true;
    ur.ER_bypassTrigger__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      Account a = createAccountsStandard();
      insert a;
      List<Contact> listCnt = createcontactsStandard(iNumCnt, a.Id, null);
      Set<Id> lstAccId = new Set<Id>();
      Set<Id> lstContractId = new Set<Id>();
      lstAccId.add(a.Id);
      Set<Id> cntId = new Set<Id>{ listCnt[0].Id };

      //With null HO Contact
      APHU14_ResponseBeforeEdg myResponse1 = APHU11_EdgSyncCallout.beforeEdg(lstAccId, lstContractId, true);
      List<ER_Financial_Center__c> listFC = createFinCentersStandard(
        iNumFC,
        a.Id,
        listcnt[0].Id,
        null,
        Label.LABS_SF_FinancialCenter_Merchant
      );
      List<ER_Bank_Account__c> listBank = createbankAccountsStandard(1, listFC[0].id, null);
      List<ER_Financial_Center__c> listFCwithBank = createFinCentersStandard(
        iNumFC,
        a.Id,
        listcnt[0].Id,
        listBank[0].Id,
        Label.LABS_SF_FinancialCenter_Merchant
      );
      Set<Id> listFinId = new Set<Id>();
      listFinId.add(listFCwithBank[0].Id);
      financialList = APHU11_EdgSyncCallout.getFinancialCenters(
        listFinId,
        ' and ER_Type__c = \'' +
        Label.LABS_SF_FinancialCenter_Merchant +
        '\''
      );
      List<ER_Store__c> listStr = createstoresStandard(1, a.Id, listFC[0].Id, listCnt[0].Id);
      Set<Id> listStrId = new Set<Id>();
      listStrId.add(listStr[0].Id);

      storeList = APHU11_EdgSyncCallout.getStores(listStrId);

      //Attach Contact Head Office
      UpdateHQContact(lstAccId, cntId);
      APHU11_EdgSyncCallout.beforeEdg(lstAccId, lstContractId, true);
      APHU11_EdgSyncCallout.beforeEdgWS(a.Id, null);
      Test.stopTest();
    }
  }

  @istest
  public static void TestBeforeEDGBenelux() {
    User ur = TestDataFactory.newUser('APHU11', 'APHU11', 'Local Admin', 'BELUX', 'BE');
    ur.ER_BypassVR__c = true;
    ur.ER_bypassTrigger__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      Account a = createAccountsStandard();
      a.ER_BUPicklist__c = 'BE';
      insert a;

      List<Contact> listCnt = createcontactsStandard(1, a.Id, null);

      List<ER_Financial_Center__c> listFC = createFinCentersStandard(
        1,
        a.Id,
        listcnt[0].Id,
        null,
        Label.LABS_SF_FinancialCenter_Merchant
      );
      List<ER_Bank_Account__c> listBanks = createbankAccountsStandard(1, listFC[0].id, null);
      List<ER_Financial_Center__c> listFCsWithBank = createFinCentersStandard(
        1,
        a.Id,
        listcnt[0].Id,
        listBanks[0].Id,
        Label.LABS_SF_FinancialCenter_Merchant
      );

      PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'APHU11');
      newOpportunity.AccountId = a.Id;
      newOpportunity.Pricebook2Id = newPriceBook.Id;
      newOpportunity.ER_BUPicklist__c = 'BE';
      newOpportunity.ER_PaymentMethod__c = 'Direct Debit';
      //Adding new so that the Add to branch ticket does not throw error Controlling field added by baptist
      newOpportunity.Onboarding_Method__c = 'OSS';
      newOpportunity.Impacted_Beneficiaries__c = 'All';
      newOpportunity.ER_SEPA_Bank_Account__c = listBanks[0].Id;
      insert newOpportunity;

      Contract c = APER07_UtilityTestMethod.getContract(
        a.Id,
        Date.today(),
        Label.LABS_SF_Contract_Status_Draft,
        newPriceBook.Id
      );
      c.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Merchant_Contract_RT');
      c.ER_Contract_Type__c = Label.LAB_SF_Contact_Operational;
      c.ER_OpportunityId__c = newOpportunity.Id;
      insert c;

      APHU11_EdgSyncCallout.beforeEdg(new Set<Id>{ a.Id }, new Set<Id>{ c.Id }, true);

      Test.stopTest();
    }
  }

  @istest
    public static void TestBeforeEDGFI() {
        User ur = TestDataFactory.newUser('APHU11', 'APHU11', 'Local Admin', 'Finland', 'BE');
        ur.ER_BypassVR__c = true;
        ur.ER_bypassTrigger__c = true;
        insert ur;

        System.runAs(ur) {
            Test.startTest();
            Account a = createAccountsStandard();
            a.ER_BUPicklist__c = 'BE';
            insert a;

            List<Contact> listCnt = createcontactsStandard(1, a.Id, null);

      List<ER_Financial_Center__c> listFC = createFinCentersStandard(
        1,
        a.Id,
        listcnt[0].Id,
        null,
        Label.LABS_SF_FinancialCenter_Merchant
      );
            List<ER_Bank_Account__c> listBanks = createbankAccountsStandard(1, listFC[0].id, null);
      List<ER_Financial_Center__c> listFCsWithBank = createFinCentersStandard(
        1,
        a.Id,
        listcnt[0].Id,
        listBanks[0].Id,
        Label.LABS_SF_FinancialCenter_Merchant
      );

            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

            Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'APHU11');
            newOpportunity.AccountId = a.Id;
            newOpportunity.Pricebook2Id = newPriceBook.Id;
            newOpportunity.ER_BUPicklist__c = 'BE';
            newOpportunity.ER_PaymentMethod__c = 'Direct Debit';
            //Adding new so that the Add to branch ticket does not throw error Controlling field added by baptist
            newOpportunity.Onboarding_Method__c = 'OSS';
            newOpportunity.Impacted_Beneficiaries__c = 'All';
            insert newOpportunity;

      Contract c = APER07_UtilityTestMethod.getContract(
        a.Id,
        Date.today(),
        Label.LABS_SF_Contract_Status_Draft,
        newPriceBook.Id
      );
            c.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, 'ER_Merchant_Contract_RT');
            c.ER_Contract_Type__c = Label.LAB_SF_Contact_Operational;
            c.ER_OpportunityId__c = newOpportunity.Id;
            insert c;

      APHU11_EdgSyncCallout.beforeEdg(new Set<Id>{ a.Id }, new Set<Id>{ c.Id }, true);

            a.ER_Merchant_Master_FinancialCenter__c = listFC[0].Id;
            update a;

            APHU11_EdgSyncCallout.beforeEdg(new Set<Id>{a.Id}, new Set<Id>{c.Id}, true);

        }
    }


  @istest
  public static void TestExistingInEDG() {
    User ur = TestDataFactory.newUser('APHU12', 'APHU12', 'Local Admin', 'Czech_Republic', 'BE');
    ur.ER_BypassVR__c = true;
    ur.ER_bypassTrigger__c = true;
    insert ur;
    System.runAs(ur) {
      Test.startTest();

      Date myDate = Date.newInstance(2018, 2, 17);
      Account a = createAccountsStandard();
      a.ER_Creation_date_in_OS__c = myDate;
      insert a;
      Set<Id> lstContractId = new Set<Id>();
      Set<Id> lstAccId = new Set<Id>();
      lstAccId.add(a.Id);
      APHU11_EdgSyncCallout.beforeEdg(lstAccId, lstContractId, true);
      Test.stopTest();
    }
  }

  @istest
  public static void TestGoodForEDG() {
    User ur = TestDataFactory.newUser('APHU12', 'APHU12', 'Local Admin', 'Czech_Republic', 'BE');
    ur.ER_BypassVR__c = true;
    ur.ER_bypassTrigger__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      Account a = createAccountsStandard();
      a.ER_VAT_Number__c = '11111111-1-11';
      a.BillingStreet = 'Soroksári út 132.';
      a.BillingPostalCode = '1035';
      a.BillingCity = 'BUDAPEST';
      insert a;

      Account newAccount = APHU11_EdgSyncCallout.getAccountWS(a.Id);
      List<Contact> listCnt = createcontactsStandard(iNumCnt, a.Id, 'Mr.');
      APHU11_EdgSyncCallout myCallout = new APHU11_EdgSyncCallout(a.Id);

      Set<Id> lstAccId = new Set<Id>();
      lstAccId.add(a.Id);
      Set<Id> cntId = new Set<Id>();
      cntId.add(listCnt[0].Id);
      List<ER_Financial_Center__c> listFC = createFinCentersStandard(
        iNumFC,
        a.Id,
        listcnt[0].Id,
        null,
        Label.LABS_SF_FinancialCenter_Merchant
      );
      List<ER_Bank_Account__c> listBank = createbankAccountsStandard(1, listFC[0].id, '30001019-01000006-70670320');
      listFC[0].ER_Bank_Account__c = listBank[0].Id;
      listFC[0].ER_Contact__c = listCnt[0].Id;
      WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
      update listFC;

      List<ER_Store__c> listStr = createstoresStandard(1, a.Id, listFC[0].Id, listCnt[0].Id);

      Set<Id> listStrId = new Set<Id>();
      listStrId.add(listStr[0].Id);

      storeList = APHU11_EdgSyncCallout.getStores(listStrId);

      //Attach Contact Head Office
      UpdateHQContact(lstAccId, cntId);

      WSHU09_SynchronizeAcceptorWS.alreadyExecutedAcceptor = true;
      List<ER_Acceptor__c> listAcp = createacceptorsStandard(1, listStr[0].Id, true);

      Set<Id> listAcpId = new Set<Id>();
      listAcpId.add(listAcp[0].Id);

      acceptorList = APHU11_EdgSyncCallout.getAcceptors(listAcpId);
      Test.stopTest();
    }
  }

  public static Account createAccountsStandard() {
    Account a = new Account(
      Name = 'APHU11_EdgSyncCallout_Test',
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('ER_Company_Account_RT')
        .getRecordTypeId(),
      ER_Status__c = 'Prospect'
    );
    WSHU02_SynchronizeMerchantWS.alreadyExecutedAccount = true;
    return a;
  }

  public static List<Contact> createcontactsStandard(Integer numContacts, Id accId, String sSalutation) {
    List<Contact> contacts = new List<Contact>();

    for (Integer i = 0; i < numContacts; i++) {
      Contact ct = new Contact(
        Salutation = sSalutation,
        FirstName = 'firstname' + i,
        LastName = 'test' + i,
        AccountId = accId,
        Phone = '+36-1-111-1111',
        Fax = '+36-1-111-1111',
        Email = 'test' + i + '@canadahotel.hu',
        MailingStreet = 'Test Street' + i,
        MailingCity = 'BUDAPEST',
        MailingPostalCode = '1095'
      );
      contacts.add(ct);
    }

    WSHU10_SynchronizeContactWS.alreadyExecutedContact = true;
    insert contacts;

    return contacts;
  }

  public static List<ER_Financial_Center__c> createFinCentersStandard(
    Integer numFcenters,
    Id accId,
    Id contactId,
    Id bankId,
    String fcType
  ) {
    List<ER_Financial_Center__c> finCenters = new List<ER_Financial_Center__c>();

    for (Integer i = 0; i < numFcenters; i++) {
      ER_Financial_Center__c fc = new ER_Financial_Center__c(
        Name = 'CANADA HOTEL KFT.' + DateTime.now().getTime() + i,
        ER_Invoicing_Site__c = true,
        ER_Account_Name__c = accId,
        ER_Email__c = 'levi.mali@programming-pool.com',
        ER_Street__c = 'Aradi u. 62.',
        ER_City__c = 'Budaörs',
        ER_Zip_Code__c = '2040',
        ER_Country__c = 'HUN',
        ER_Type__c = fcType
      );
      fc.ER_Bank_Account__c = bankId;
      finCenters.add(fc);
    }

    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    insert finCenters;

    return finCenters;
  }

  public static List<ER_Acceptor__c> createacceptorsStandard(Integer nbAcceptors, Id storeId, Boolean isToInsert) {
    List<ER_Acceptor__c> acceptors = new List<ER_Acceptor__c>();

    for (Integer i = 0; i < nbAcceptors; i++) {
      ER_Acceptor__c acceptor = new ER_Acceptor__c(
        Name = 'CANDA HOTEL' + i,
        ER_Store__c = storeId,
        ER_Card_Operational_System_ID__c = '15235',
        ER_Acceptor_Scheme__c = 'MasterCard'
      );
      acceptors.add(acceptor);
    }

    if (isToInsert) {
      WSHU09_SynchronizeAcceptorWS.alreadyExecutedAcceptor = true;
      insert acceptors;
    }

    return acceptors;
  }

  public static List<ER_Store__c> createstoresStandard(Integer numStores, Id accId, Id FinCenterId, Id contId) {
    List<ER_Store__c> stores = new List<ER_Store__c>();

    for (Integer i = 0; i < numStores; i++) {
      ER_Store__c store = new ER_Store__c(
        Name = 'CANDA HOTEL' + i,
        ER_Merchant__c = accId,
        ER_Financial_Center__c = FinCenterId,
        ER_Contact__c = contId,
        ER_Street__c = 'Test Street' + i,
        ER_City__c = 'BUDAPEST',
        ER_Zip_Code__c = '1095'
      );
      stores.add(store);
    }

    insert stores;

    return stores;
  }

  public static List<ER_Bank_Account__c> createbankAccountsStandard(
    Integer numBankAccts,
    Id finCenterId,
    String sIban
  ) {
    List<ER_Bank_Account__c> bankAccts = new List<ER_Bank_Account__c>();

    for (Integer i = 0; i < numBankAccts; i++) {
      ER_Bank_Account__c bankAcc = new ER_Bank_Account__c(
        Name = 'BNP' + i,
        ER_Financial_Center__c = finCenterId,
        ER_Bank_Account_Status__c = 'Open',
        ER_Bank_City__c = 'Paris',
        ER_Bank_Account_Number_Prefix__c = 'FR',
        ER_Bank_Account_Number__c = '14',
        ER_IBAN__c = sIban,
        ER_SEPA_active__c = true,
        ER_SEPA_start_date__c = null
      );
      bankAccts.add(bankAcc);
    }

    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    insert bankAccts;

    return bankAccts;
  }

  public static List<Account> UpdateHQContact(Set<Id> sAccIdList, Set<Id> sCntIdList) {
    List<Account> myAcc = [SELECT HU_HQ_Contact__c FROM Account WHERE Id IN :sAccIdList];
    List<Contact> myCnt = [SELECT Id FROM Contact WHERE Id IN :sCntIdList];

    if (myAcc.Size() == 1) {
      if (myCnt.Size() == 1) {
        myAcc[0].HU_HQ_Contact__c = myCnt[0].Id;
        update myAcc;
      }
    }
    return myAcc;
  }
}