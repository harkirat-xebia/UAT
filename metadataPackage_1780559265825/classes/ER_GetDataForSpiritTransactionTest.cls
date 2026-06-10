/**
 * @author : ALK
 * @date : 09/06/2021
 * @desc : ER_GetDataForSpiritTransactionTest
 * @see ER_GetDataForSpiritTransactionTest
 */

@IsTest
public class ER_GetDataForSpiritTransactionTest {
  @TestSetup
  static void testSetup() {
    Account a = TestDataFactory.newAccount();
    a.ER_BUPicklist__c = 'PL';
    a.ER_Status__c = 'Active';
    a.Name = 'SpiritAccount_';
    insert a;

    Contact c = TestDataFactory.newContact(a);
    c.ER_BUPicklist__c = 'PL';
    insert c;

    ER_Financial_Center__c f = TestDataFactory.newMerchantFC(a);
    //f.ER_Contact__c = c.Id;
    f.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
    insert f;

    ER_Bank_Account__c bankAccount = APER07_UtilityTestMethod.getBankAccount(
      f.Id,
      'ER_SyncStructureWithLegacy_Test',
      'Open',
      'Warsaw',
      'Some street',
      '00000000-00000000-00000000'
    );
    insert bankAccount;

    //getStore(String name, String accountId, String financialCenterId, Date startDate, String street, String city,String zipCode, String country) {
    ER_Store__c s = APER07_UtilityTestMethod.getStore(
      'StoreName' + Datetime.now().getTime(),
      a.Id,
      f.Id,
      Date.today(),
      'Some Street',
      'Warsaw',
      '001',
      'Poland'
    );
    insert s;

    ER_Acceptor__c acc = APER07_UtilityTestMethod.getAcceptor(s.Id);
    acc.ER_MID_Authorization__c = '288994';
    acc.ER_MID_Clearing__c = '288994';
    acc.ER_SubMID_Authorization__c = '';
    acc.ER_Sub_MID_Clearing__c = '';
    acc.ER_Start_Date__c = Date.today().addDays(-30);
    insert acc;

    ER_Acceptor__c acc1 = APER07_UtilityTestMethod.getAcceptor(s.Id);
    acc1.ER_MID_Authorization__c = '288991';
    acc1.ER_SubMID_Authorization__c = '288991SUB';
    acc1.ER_MID_Clearing__c = '';
    acc1.ER_Sub_MID_Clearing__c = '';
    acc.ER_Start_Date__c = Date.today().addDays(-30);
    insert acc1;

    Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
    ba.Name = 'BaName';
    ba.ER_Financial_Center__c = f.Id;
    ba.Zuora__AccountNumber__c = 'A00000161';
    ba.Zuora__Account__c = a.Id;
    ba.SEQUENCE_SET__c = 'AFFILIATE';
    ba.Zuora__Status__c = 'Active';
    ba.CurrencyIsoCode = UtilsBypass.getCurrentUser().CurrencyIsoCode;
    insert ba;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'Opp testnewZuoraQuote'
    );
    newOpportunity.AccountId = a.Id;
    newOpportunity.ER_Contract_Expected_Start_Date__c = Date.today();
    insert newOpportunity;

    zqu__Quote__c newZQuote = APER07_UtilityTestMethod.getZuoraQuote('Default');
    newZQuote.zqu__Account__c = a.Id;
    newZQuote.zqu__Opportunity__c = newOpportunity.Id;
    newZQuote.zqu__Currency__c = UtilsBypass.getCurrentUser().CurrencyIsoCode;
    newZQuote.zqu__StartDate__c = Date.today();
    insert newZQuote;

    Zuora__Subscription__c sub = new Zuora__Subscription__c();
    sub.Zuora__Account__c = a.Id;
    sub.Zuora__CustomerAccount__c = ba.Id;
    sub.Zuora__Version__c = 1;
    sub.Zuora__InvoiceOwner__c = ba.Id;
    sub.Zuora__SubscriptionStartDate__c = Date.today();
    insert sub;

    Pricebook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

    Product2 p = APER07_UtilityTestMethod.getsolution('Zuora_Product');
    p.ProductCode = 'EDPO_TR_APM_PLN';
    p.BU_External_Reference__c = 'EDPO_TR_APM_PLN';
    p.ER_Business_Unit__c = UtilsBypass.getCurrentUser().ER_Business_Unit__c;
    insert p;

    PricebookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.Id, p.Id);
    insert newPriceBookEntry;

    Contract testContract = APER07_UtilityTestMethod.getContract(
      a.Id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id
    );
    testContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
      .get('ER_Merchant_Contract_RT')
      .getRecordTypeId();
    testContract.Subscription__c = sub.Id;
    testContract.ER_ZuoraQuote__c = newZQuote.Id;
    testContract.StartDate = Date.today();
    insert testContract;

    ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(
      testContract.Id,
      p.Id,
      newPriceBookEntry.Id,
      1,
      1
    );
    insert testContractLineItem;

    testContract.Status = Label.LABS_SF_Contract_Status_Activated;
    update testContract;

    Zuora__SubscriptionRatePlan__c srp = new Zuora__SubscriptionRatePlan__c();
    srp.Zuora__Account__c = a.Id;
    srp.Zuora__Subscription__c = sub.Id;
    srp.Zuora__External_Id__c = '8adcfb507a5b3046017a6273a74e0ca5';
    srp.Zuora__OriginalProductRatePlanId__c = '8adcfb507a5b3046017a6273a74e0ca6';
    srp.Zuora__OriginalSubscriptionRatePlanId__c = '8adcfb507a5b3046017a6273a74e0ca5';
    srp.ER_Solution__c = p.Id;
    insert srp;
  }

  @IsTest
  static void doPost() {
    Test.startTest();
    List<Account> createdAccount = [SELECT ER_BUPicklist__c FROM Account WHERE Name = 'SpiritAccount_'];
    List<ER_GetDataForSpiritTransaction.SpiritStructureRequest> requestList = new List<ER_GetDataForSpiritTransaction.SpiritStructureRequest>();
    ER_GetDataForSpiritTransaction.SpiritStructureRequest item1 = new ER_GetDataForSpiritTransaction.SpiritStructureRequest();
    item1.checkinId = 10;
    item1.productCode = 'EDPO_TR_APM_PLN';
    item1.transactionDate = Datetime.now().format('yyyy-MM-dd');
    item1.scheme = 'MC';
    item1.authorizationMID = '288994';
    item1.authorizationAID = '';
    item1.clearingMID = '';
    item1.clearingAID = '';
    item1.authorizationSubMID = '288994';
    item1.clearingSubMID = '';
    item1.bu = (!createdAccount.isEmpty() ? createdAccount[0].ER_BUPicklist__c : 'PL');
    requestList.add(item1);

    ER_GetDataForSpiritTransaction.SpiritStructureRequest item2 = new ER_GetDataForSpiritTransaction.SpiritStructureRequest();
    item2.checkinId = 20;
    item2.productCode = 'EDPO_TR_APM_PLN';
    item2.transactionDate = Datetime.now().format('yyyy-MM-dd');
    item2.scheme = 'MC';
    item2.authorizationMID = '288991';
    item2.authorizationAID = '';
    item2.clearingMID = '';
    item2.clearingAID = '';
    item2.authorizationSubMID = '';
    item2.clearingSubMID = '';
    item2.bu = (!createdAccount.isEmpty() ? createdAccount[0].ER_BUPicklist__c : 'PL');
    requestList.add(item2);

    ER_GetDataForSpiritTransaction.SpiritStructureRequest item3 = new ER_GetDataForSpiritTransaction.SpiritStructureRequest();
    item3.checkinId = 30;
    item3.productCode = 'EDPO_TR_APM_PLN';
    item3.transactionDate = Datetime.now().format('yyyy-MM-dd');
    item3.scheme = 'MC';
    item3.authorizationMID = '288992';
    item3.authorizationAID = '';
    item3.clearingMID = '288992';
    item3.clearingAID = '';
    item3.authorizationSubMID = '288992';
    item3.clearingSubMID = '';
    item3.bu = (!createdAccount.isEmpty() ? createdAccount[0].ER_BUPicklist__c : 'PL');
    requestList.add(item3);

    ER_GetDataForSpiritTransaction.SpiritStructureRequest item4 = new ER_GetDataForSpiritTransaction.SpiritStructureRequest();
    item4.checkinId = 40;
    item4.productCode = 'EDPO_TR_APM_PLN';
    item4.transactionDate = Datetime.now().format('yyyy-MM-dd');
    item4.scheme = 'MC';
    item4.authorizationMID = '288993';
    item4.authorizationAID = '';
    item4.clearingMID = '288993';
    item4.clearingAID = '';
    item4.authorizationSubMID = '288993';
    item4.clearingSubMID = '288993';
    item4.bu = (!createdAccount.isEmpty() ? createdAccount[0].ER_BUPicklist__c : 'PL');
    requestList.add(item4);

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/getDataForSpiritTransaction';
    req.httpMethod = 'POST';
    req.addHeader('Content-Type', 'application/json');
    RestContext.request = req;
    RestContext.response = res;

    List<ER_Acceptor__c> acceptors = [
      SELECT
        Id,
        Name,
        ER_MID_Authorization__c,
        ER_SubMID_Authorization__c,
        ER_MID_Clearing__c,
        ER_Sub_MID_Clearing__c,
        ER_Start_Date__c,
        ER_End_Date__c,
        ER_Business_Unit__c,
        ER_Store__r.Name,
        ER_Store__r.ER_Financial_Center__c
      FROM ER_Acceptor__c
      WHERE ER_MID_Authorization__c = '288994'
    ];
    System.debug('>>>>> ALK - acceptors : ' + acceptors);

    List<ER_GetDataForSpiritTransaction.SpiritStructureResponse> objList = ER_GetDataForSpiritTransaction.doPost(
      requestList
    );
    // System.assert(!objList.isEmpty() && objList.size() == 2, 'Erreur while calling the service');

    Test.stopTest();
  }
}