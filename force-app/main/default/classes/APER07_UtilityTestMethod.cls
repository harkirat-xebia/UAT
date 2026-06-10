/*
----------------------------------------------------------------------
-- - Name          : APER07_UtilityTestMethod
-- - Author        : OLA
-- - Description   : utility class to insert data
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  JAN-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER07_UtilityTestMethod {
  /*************************************
   *               Asset
   **************************************/

  //provide a single Asset
  public static Asset getAsset(String name, String recordTypeDeveloperName, String assetType) {
    return new Asset(
      Name = name,
      Status = Label.LAB_SF_ASSET_Status_Active,
      recordtypeid = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName()
        .get(recordTypeDeveloperName)
        .getRecordTypeId(),
      ER_Asset_Type__c = assetType
    );
  }

  /*************************************
   *               Case
   **************************************/

  //provide a single Case
  public static Case getCase(String recordTypeDeveloperName) {
    return new Case(
      recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get(recordTypeDeveloperName)
        .getRecordTypeId()
    );
  }

  /*************************************
   *           ER_Employee__c
   **************************************/

  //provide a single Employee
  public static ER_Employee__c getEmployee() {
    return new ER_Employee__c(name = 'testEmployee', ER_Professional_Email__c = 'test@test.com');
  }

  /*************************************
   *           INDIVIDUAL
   **************************************/

  //provide a single Individual
  public static Account getIndividual(String salutation, String firstName, String lastName) {
    return new Account(
      Salutation = salutation,
      FirstName = firstName,
      LastName = lastName,
      ER_Not_subject_to_VAT__c = true,
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('ER_Individual_Account_RT')
        .getRecordTypeId()
    );
  }

  /*************************************
   *               Account
   **************************************/

  //provide a single Company
  public static Account getCompany(String name) {
    return new Account(
      recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('ER_Company_Account_RT')
        .getRecordTypeId(),
      ER_Match_Legal_Address__c = true,
      ER_VAT_Number__c = '00000001-1-01',
      BillingStreet = 'Road Street',
      BillingCity = 'Paris',
      BillingPostalCode = '1095',
      Name = name,
      ER_Country_Code__c = 'BE'
    );
  }

  //provide a single Company with specific business unit
  public static Account getCompany(String name, String buName) {
    Account acc = getCompany(name);
    acc.ER_BUPicklist__c = buName;
    return acc;
  }
  /*************************************
   *               Account
   **************************************/

  //provide a single Company
  public static Account getAccountWithParent(String name, String parentId) {
    return new Account(
      recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('ER_Company_Account_RT')
        .getRecordTypeId(),
      ER_Match_Legal_Address__c = true,
      ER_VAT_Number__c = '00000001-1-02',
      Name = name,
      ParentId = parentId,
      ER_Decision_maker__c = true
    );
  }
  /*************************************
   *        Account Line Item
   **************************************/

  //provide a single Company
  public static ER_Solution_Line_Item__c getAccountLineItem(String accountId, String contractId, String solutionId) {
    return new ER_Solution_Line_Item__c(
      ER_Account__c = accountId,
      ER_Contract__c = contractId,
      ER_Solution__c = solutionId,
      RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('ER_Account_Line_Item')
        .getRecordTypeId()
    );
  }

  /*************************************
   *               Contact
   **************************************/

  public static Contact getContact(String recordType, String firstName, String lastName) {
    return new Contact(
      FirstName = firstName,
      LastName = lastName,
      Email = 'test@test.com',
      recordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId()
    );
  }

  /*************************************
   *               Contact Role
   **************************************/

  public static ER_Contact_Role__c getContactRole(String contactId, Id parentID, String recordType, Boolean isPrimary) {
    String objectName = parentID.getSobjectType().getDescribe().getName();

    ER_Contact_Role__c cr = new ER_Contact_Role__c(
      ER_Contact__c = contactId,
      ER_Primary__c = isPrimary,
      recordtypeId = Schema.SObjectType.ER_Contact_Role__c.getRecordTypeInfosByDeveloperName()
        .get(recordType)
        .getRecordTypeId()
    );
    if (objectName.equalsIgnoreCase('ER_Financial_Center__c')) {
      cr.ER_Financial_Center__c = parentID;
    } else if (objectName.equalsIgnoreCase('ER_Store__c')) {
      cr.ER_Store__c = parentID;
    } else if (objectName.equalsIgnoreCase('ER_Delivery_Site__c')) {
      cr.ER_Delivery_Site__c = parentID;
    } else if (objectName.equalsIgnoreCase('ER_Distribution_Point__c')) {
      cr.ER_Distribution_Point__c = parentID;
    }
    return cr;
  }

  /*************************************
   *               Financial Center
   **************************************/

  public static ER_Financial_Center__c getFinancialCenter(
    String name,
    String accountId,
    String fcType,
    String street,
    String city,
    String zipCode,
    String country
  ) {
    return new ER_Financial_Center__c(
      Name = name,
      ER_Account_Name__c = accountId,
      ER_Type__c = fcType,
      ER_Street__c = street,
      ER_City__c = city,
      ER_Zip_Code__c = zipCode,
      ER_Country__c = country,
      ER_Payment_Site__c = true
    );
  }
  /*************************************
   *               Financial Center Line Item
   **************************************/

  public static ER_Solution_Line_Item__c getFinancialCenterLineItem(
    String financialCenterId,
    String contractId,
    String AccountLineItemId,
    String solutionId
  ) {
    return new ER_Solution_Line_Item__c(
      ER_Financial_Center__c = financialCenterId,
      ER_Contract__c = contractId,
      ER_Parent_Line_Item__c = AccountLineItemId,
      ER_Solution__c = solutionId,
      RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('ER_Financial_Center_Line_Item')
        .getRecordTypeId()
    );
  }

  /*************************************
   *               Bank Account
   **************************************/

  public static ER_Bank_Account__c getBankAccount(
    String finCenterId,
    String name,
    String status,
    String city,
    String street,
    String iban
  ) {
    return new ER_Bank_Account__c(
      Name = name,
      ER_Financial_Center__c = finCenterId,
      ER_Bank_Account_Status__c = status,
      ER_Bank_City__c = city,
      ER_IBAN__c = iban
    );
  }

  /*************************************
   *               Store
   **************************************/

  public static ER_Store__c getStore(
    String name,
    String accountId,
    String financialCenterId,
    Date startDate,
    String street,
    String city,
    String zipCode,
    String country
  ) {
    return new ER_Store__c(
      Name = name,
      ER_Merchant__c = accountId,
      ER_Financial_Center__c = financialCenterId,
      ER_Start_date__c = startDate,
      ER_Street__c = street,
      ER_City__c = city,
      ER_Zip_Code__c = zipCode,
      ER_Country__c = country
    );
  }

  /*************************************
   *               Store Line Item
   **************************************/

  public static ER_Store_Line_Item__c getStoreLineItem(String storeId, String status, String solutionId) {
    return new ER_Store_Line_Item__c(ER_Store__c = storeId, ER_Status__c = status, ER_Solution__c = solutionId);
  }
  /*************************************
   *               Store Line Item New
   **************************************/

  public static ER_Solution_Line_Item__c getStoreLineItemNew(
    String storeId,
    String contractId,
    String FinancialCentertId,
    String solutionId
  ) {
    return new ER_Solution_Line_Item__c(
      ER_Store__c = storeId,
      ER_Contract__c = contractId,
      ER_Solution__c = solutionId,
      ER_Parent_Line_Item__c = FinancialCentertId,
      RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('ER_Store_Line_Item')
        .getRecordTypeId()
    );
  }

  /*************************************
   *               Acceptor
   **************************************/
  public static ER_Acceptor__c getAcceptor(String storeId, String Name, String TID, String MID) {
    return new ER_Acceptor__c(
      ER_Store__c = storeId,
      ER_MID_Authorization__c = MID,
      ER_TID_Authorization__c = TID,
      Name = Name,
      ER_Start_Date__c = Date.today(),
      ER_End_Date__c = Date.today().addMonths(1)
    );
  }

  /*************************************
   *               Product
   **************************************/

  //provide a single Client
  public static Product2 getProduct(String codeEDG) {
    return new Product2(Name = 'testProduct', ER_EDG_Product_Ref__c = codeEDG);
  }

  /*************************************
   *               Opportunity
   **************************************/

  public static Opportunity getOpportunity(String recordType, String name) {
    return new Opportunity(
      Name = name,
      ER_BUPicklist__c = 'BE',
      recordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get(recordType)
        .getRecordTypeId(),
      StageName = Label.LABS_SF_Opp_Status_Qualification,
      CloseDate = Date.today().addMonths(1)
    );
  }

  /*************************************
   *        Opportunity Line Item
   **************************************/

  public static OpportunityLineItem getOpportunityLineItem(String opportunityId, String pricebookEntryId) {
    return new OpportunityLineItem(
      opportunityId = opportunityId,
      pricebookEntryId = pricebookEntryId,
      UnitPrice = 1,
      ER_Percentage__c = 2,
      Quantity = 1
    );
  }

  /*************************************
   *               Quote
   **************************************/

  public static Quote getQuote(String recordType, String name, String opportunityId, String priceBookId) {
    return new Quote(
      Name = name,
      OpportunityId = opportunityId,
      Pricebook2Id = priceBookId,
      recordtypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId(),
      Status = Label.LABS_SF_Quote_Status_Draft,
      ExpirationDate = Date.today().addMonths(1)
    );
  }

  /*************************************
   *        Quote Line Item
   **************************************/

  public static QuoteLineItem getQuoteLineItem(String quoteId, String pricebookEntryId) {
    return new QuoteLineItem(
      QuoteId = quoteId,
      pricebookEntryId = pricebookEntryId,
      UnitPrice = 1,
      ER_Percentage__c = 2,
      discount = 1,
      Quantity = 1
    );
  }

  /*************************************
   *         Service (Product2)
   **************************************/

  public static Product2 getservice(String name, String solutionId) {
    return new Product2(Name = name, ER_Type__c = 'service', ER_Solution__c = solutionId, IsActive = true);
  }

  /*************************************
   *         Solution (Product2)
   **************************************/

  public static Product2 getsolution(String name) {
    return new Product2(Name = name, ER_Type__c = 'Solution', IsActive = true);
  }

  /*************************************
   *         PriceBook
   **************************************/

  public static PriceBook2 getpriceBook() {
    return new PriceBook2(
      Id = Test.getStandardPricebookId(),
      ER_Business_Unit__c = APER10_User_Management.userBU,
      IsActive = true
    );
  }

  public static PriceBook2 getCustomPriceBook(String priceBookName) {
    System.debug('APER10_User_Management.userBU: ' + APER10_User_Management.userBU);
    return new PriceBook2(Name = priceBookName, ER_Business_Unit__c = APER10_User_Management.userBU, IsActive = true);
  }

  /*************************************
   *         PriceBookEntry
   **************************************/

  public static PriceBookEntry getpriceBookEntry(String priceBookId, String productId) {
    return new PriceBookEntry(
      Pricebook2Id = priceBookId,
      Product2Id = productId,
      UnitPrice = 1,
      //ER_Percentage__c = 1,
      IsActive = true,
      ER_ValueType__c = Label.LABS_SF_Opp_Product_Currency
    );
  }

  /*************************************
   *               Contact
   **************************************/

  public static Contract getContract(String accountId, Date startDate, String status, String priceBookId) {
    return new Contract(AccountId = accountId, StartDate = startDate, Status = status, PriceBook2Id = priceBookId);
  }

  /*************************************
   *           Contract Line Item
   **************************************/
  public static ER_ContractLineItem__c getContractLineItem(
    String contractId,
    String product2Id,
    String priceBookEntryId,
    Integer quantity,
    Decimal unitPrice
  ) {
    return new ER_ContractLineItem__c(
      ER_Contract__c = contractId,
      ER_Product2__c = product2Id,
      ER_PricebookEntryId__c = priceBookEntryId,
      ER_Quantity__c = quantity,
      ER_UnitPrice__c = unitPrice
    );
  }

  /*************************************
   *               Delivery Site
   **************************************/

  public static ER_Delivery_Site__c getDeliverySite(String name, String accountId, String financialCenterId) {
    return new ER_Delivery_Site__c(
      Name = name,
      ER_Account_Name__c = accountId,
      ER_Financial_Center__c = financialCenterId
    );
  }
  /*************************************
   *       Delivery Site Line Item
   **************************************/

  public static ER_Solution_Line_Item__c getDeliverySiteLineItem(
    String deliverySiteId,
    String contractId,
    String FinancialCenterLineItemId,
    String solutionId
  ) {
    return new ER_Solution_Line_Item__c(
      ER_Delivery_Site__c = deliverySiteId,
      ER_Contract__c = contractId,
      ER_Solution__c = solutionId,
      ER_Parent_Line_Item__c = FinancialCenterLineItemId,
      RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('ER_Delivery_Site_Line_Item')
        .getRecordTypeId()
    );
  }

  /*************************************
   *      Distribution Point
   **************************************/

  public static ER_Distribution_Point__c getDistributionPoint(String name, String deliverySiteId) {
    return new ER_Distribution_Point__c(Name = name, ER_Delivery_Site__c = deliverySiteId);
  }
  /*************************************
   *      Distribution Point Line Item
   **************************************/

  public static ER_Solution_Line_Item__c getDistributionPointLineItem(
    String distributionPointId,
    String contractId,
    String deliverySiteLineItemId,
    String solutionId
  ) {
    return new ER_Solution_Line_Item__c(
      ER_Distribution_Point__c = distributionPointId,
      ER_Contract__c = contractId,
      ER_Parent_Line_Item__c = deliverySiteLineItemId,
      ER_Solution__c = solutionId,
      RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('ER_Distribution_Point_Line_Item')
        .getRecordTypeId()
    );
  }

  /*************************************
   *           Lead
   **************************************/
  public static Lead getLead(Id recordTypeId) {
    String uniqueName = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');

    Lead lead = new Lead(
      ER_Store_Name__c = uniqueName,
      Salutation = 'Mr.',
      LastName = uniqueName,
      FirstName = uniqueName,
      RecordTypeId = recordTypeId,
      ER_VAT_Number__c = uniqueName,
      Company = uniqueName,
      Email = uniqueName + '@salesforce.com',
      Street = uniqueName,
      City = 'Malakoff',
      ER_Terminal__c = 'Yes',
      PostalCode = '92240',
      ER_Language__c = 'EN',
      ER_BUPicklist__c = 'BE',
      ER_MID_Clearing__c = uniqueName,
      ER_Sub_MID_Clearing__c = uniqueName
    );
    return lead;
  }
  /*************************************
   *           Acceptor
   **************************************/
  public static ER_Acceptor__c getAcceptor(String storeid) {
    ER_Acceptor__c acceptor = new ER_Acceptor__c(
      ER_MID_Clearing__c = '100',
      ER_MID__c = '1',
      ER_SubMID_Authorization__c = '2',
      ER_Sub_MID_Clearing__c = '101',
      ER_MID_Authorization__c = '10000000000',
      ER_Store__c = storeid,
      ER_Start_Date__c = Date.today()
    );
    return acceptor;
  }
  /*************************************
   *               Acceptor Line Item
   **************************************/

  public static ER_Solution_Line_Item__c getAcceptorLineItem(
    String acceptorId,
    String contractId,
    String storeLineItemId,
    String solutionId
  ) {
    return new ER_Solution_Line_Item__c(
      ER_Acceptor__c = acceptorId,
      ER_Contract__c = contractId,
      ER_Parent_Line_Item__c = storeLineItemId,
      ER_Solution__c = solutionId,
      RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
        .get('ER_Acceptor_Line_Item')
        .getRecordTypeId()
    );
  }
  /*************************************
   *               user by RoleId
   **************************************/
  public static User getTestUser(String roleId) {
    Profile p = [SELECT Id, name FROM Profile WHERE name = 'Local Admin'];
    String orgId = UserInfo.getOrganizationId();
    String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
    String uniqueName = orgId + dateString;
    return new User(
      LastName = 'TestName',
      Username = uniqueName + '@test' + orgId + '.org',
      Email = 'test@customercare.com',
      Alias = 'ext',
      CommunityNickname = 'ext',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'cs_CZ',
      EmailEncodingKey = 'UTF-8',
      UserRoleId = roleId,
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Local Admin']
      .Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'CZ'
    );
  }

  /*************************************
   *               Zuora Quotes
   **************************************/
  public static zqu__Quote__c getZuoraQuote(String recordType) {
    return new zqu__Quote__c(
      recordtypeId = Schema.SObjectType.zqu__Quote__c.getRecordTypeInfosByDeveloperName()
        .get(recordType)
        .getRecordTypeId(),
      zqu__Status__c = 'New',
      zqu__SubscriptionType__c = 'New Subscription',
      zqu__Subscription_Term_Type__c = 'Evergreen'
    );
  }

  public static zqu__QuoteRatePlan__c getZuoraQuoteRP(
    String QuoteId,
    String ProductRPId,
    String qAmendmentId,
    String sProductName
  ) {
    return new zqu__QuoteRatePlan__c(
      zqu__Quote__c = QuoteId,
      zqu__ProductRatePlan__c = ProductRPId,
      zqu__QuoteAmendment__c = qAmendmentId,
      zqu__AmendmentType__c = 'NewProduct',
      zqu__QuoteProductName__c = sProductName
    );
  }

  public static zqu__ProductRatePlan__c getZuoraProductRP(String ProductId) {
    return new zqu__ProductRatePlan__c(zqu__Product__c = ProductId);
  }

  public static zqu__QuoteAmendment__c newQuoteAmendment(String quoteId) {
    return new zqu__QuoteAmendment__c(zqu__Quote__c = quoteId, zqu__Type__c = 'NewProduct', zqu__TotalAmount__c = 1);
  }

  public static Account insertAccount(String name, String recordType) {
    Account account = new Account(
      recordtypeid = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, recordType),
      ER_Match_Legal_Address__c = true,
      ER_VAT_Number__c = '00000001-1-01',
      Name = name,
      ER_Lead_Source_Type__c = 'Merchant',
      ER_Legal_Name__c = 'Test1',
      Description = 'testSolution;'
    );
    insert account;
    return account;
  }

  public static Contract insertContract(
    String accountId,
    Date startDate,
    String status,
    String priceBookId,
    String recordtype,
    Id ownerId
  ) {
    Contract contract = new Contract(
      AccountId = accountId,
      StartDate = startDate,
      Status = status,
      PriceBook2Id = priceBookId,
      ownerId = ownerId,
      recordtypeid = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, recordtype)
    );
    insert contract;
    return contract;
  }

  public static void insertZuoraCustomerAccount(
    String name,
    Id fcId,
    String acctNbr,
    Id acctId,
    String sequenceSet,
    String zuoraStatus,
    String currencyCode
  ) {
    insert new Zuora__CustomerAccount__c(
      Name = name,
      ER_Financial_Center__c = fcId,
      Zuora__AccountNumber__c = acctNbr,
      Zuora__Account__c = acctId,
      SEQUENCE_SET__c = sequenceSet,
      Zuora__Status__c = zuoraStatus,
      CurrencyIsoCode = currencyCode
    );
  }

  public static ER_Financial_Center__c insertFinancialCenter(
    String name,
    String accountId,
    String street,
    String city,
    String zipCode,
    String country,
    String type,
    Id contactId,
    String countryCode
  ) {
    ER_Financial_Center__c fc = new ER_Financial_Center__c(
      Name = name,
      ER_Account_Name__c = accountId,
      ER_Street__c = street,
      ER_City__c = city,
      ER_Zip_Code__c = zipCode,
      ER_Country__c = country,
      ER_Payment_Site__c = true,
      ER_Type__c = type,
      ER_Contact__c = contactId,
      ER_Country_Code__c = countryCode
    );
    insert fc;
    return fc;
  }

  public static AccountPartner newAccountPartner(String role, Id acctFrom, Id acctTo) {
    return new AccountPartner(role = role, AccountFromId = acctFrom, AccountToId = acctTo);
  }

  public static Product2 insertProduct2(String name, String BU, String productCode, String type, Id solutionId) {
    Product2 prod = new Product2(
      Name = name,
      ER_Type__c = type,
      ER_Solution__c = solutionId,
      IsActive = true,
      ProductCode = productCode,
      ER_Business_Unit__c = BU
    );
    insert prod;
    return prod;
  }

  public static purecloud__PureCloud_Entity__c newGenesysEmailFlow(String flowName) {
    purecloud__PureCloud_Entity__c sobj = new purecloud__PureCloud_Entity__c(
      Name = 'a305r000000FMrO', // Genesys Cloud Entity Name
      purecloud__PureCloud_ID__c = 'ca7a2c1a-4a9b-41cb-9c02-9b2b38dc03a1', // Genesys Cloud ID
      purecloud__Type__c = 'Email Flow', // Type
      purecloud__PureCloud_Name__c = flowName, // Genesys Cloud Name
      purecloud__PureCloud_Division_ID__c = '17a267b6-cc56-4244-9e5f-29e59475d976', // Genesys Cloud Division ID
      purecloud__PureCloud_Division_Name__c = 'ERF_SME' // Genesys Cloud Division Name
    );
    return sobj;
  }
}