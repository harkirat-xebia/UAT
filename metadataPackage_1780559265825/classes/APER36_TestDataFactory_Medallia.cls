/**
 * @author : Bogdan Vircolici
 * @date : 10/01/2022
 * @desc : TestDataFactory class for Medallia
 * @see TestDataFactory_Medallia
 */
@isTest
public class APER36_TestDataFactory_Medallia {
  //provide a single account
  public static Account getAccount(String name) {
    Account a = new Account(
      ER_Match_Legal_Address__c = true,
      ER_VAT_Number__c = '123',
      ER_Registration_Number__c = '12312312312',
      ER_Other_Fiscal_ID__c = 'dasdsa123',
      Name = name,
      ER_Status__c = 'Active',
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('ER_Company_Account_RT')
        .getRecordTypeId()
    );
    insert a;
    return a;
  }

  public static Contact getContactWithAccount(String firstName, String lastName, Id accountId) {
    Contact c = new Contact(
      FirstName = firstName,
      LastName = lastName,
      Email = 'test.medallia@sf.com',
      AccountId = accountId,
      ER_Status__c = 'Active',
      ER_Language__c = 'EN'
    );
    insert c;
    return c;
  }

  public static Opportunity getOpportunity(String recordType, String name, Id accId) {
    Opportunity o = new Opportunity(
      Name = name,
      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get(recordType)
        .getRecordTypeId(),
      StageName = Label.LABS_SF_Opp_Status_Qualification,
      CloseDate = Date.today().addMonths(1),
      AccountId = accId
    );
    insert o;
    return o;
  }

  public static OpportunityContactRole getOpportunityContactRole(Id opportunityId, Id contactId) {
    OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = opportunityId, ContactId = contactId);
    insert ocr;
    return ocr;
  }

  public static ER_Financial_Center__c getFinancialCenterWithContact(
    String name,
    String accountId,
    String fcType,
    Id contactId
  ) {
    ER_Financial_Center__c fc = new ER_Financial_Center__c(
      Name = name,
      ER_Account_Name__c = accountId,
      ER_Type__c = fcType,
      ER_Invoicing_Site__c = true,
      ER_Contact__c = contactId
    );
    insert fc;
    return fc;
  }

  public static ER_Store__c getStoreWithContact(String name, String accountId, String financialCenterId, Id contactId) {
    ER_Store__c s = new ER_Store__c(
      Name = name,
      ER_Merchant__c = accountId,
      ER_Financial_Center__c = financialCenterId,
      ER_Contact__c = contactId,
      ER_Street__c = 'test street'
    );
    insert s;
    return s;
  }

  public static ER_Delivery_Site__c getDeliverySite(Id accountId, Id contactId) {
    ER_Delivery_Site__c ds = new ER_Delivery_Site__c(
      ER_Account_Name__c = accountId,
      ER_Delivery_Contact__c = contactId
    );
    insert ds;
    return ds;
  }

  public static ER_Distribution_Point__c getDistributionPoint(Id deliverySiteId) {
    ER_Distribution_Point__c dp = new ER_Distribution_Point__c(ER_Delivery_Site__c = deliverySiteId);
    insert dp;
    return dp;
  }

  public static ER_Contact_Role__c getContactRoleWithFinancialCenter(Id contactId, Id financialId) {
    ER_Contact_Role__c cr = new ER_Contact_Role__c(ER_Financial_Center__c = financialId, ER_Contact__c = contactId);
    insert cr;
    return cr;
  }

  public static ER_Contact_Role__c getContactRoleWithStore(Id contactId, Id storeId) {
    ER_Contact_Role__c cr = new ER_Contact_Role__c(ER_Store__c = storeId, ER_Contact__c = contactId);
    insert cr;
    return cr;
  }

  public static ER_Contact_Role__c getContactRoleWithDeviverySite(Id contactId, Id deliverySiteId) {
    ER_Contact_Role__c cr = new ER_Contact_Role__c(ER_Delivery_Site__c = deliverySiteId, ER_Contact__c = contactId);
    insert cr;
    return cr;
  }

  public static ER_Contact_Role__c getContactRoleWithDistributionPoint(Id contactId, Id distributionPointId) {
    ER_Contact_Role__c cr = new ER_Contact_Role__c(
      ER_Distribution_Point__c = distributionPointId,
      ER_Contact__c = contactId
    );
    insert cr;
    return cr;
  }

  public static User newUser(String firstName, String lastName, String profileName, String businessUnit) {
    Profile p = [SELECT Id, Name FROM Profile WHERE Name = :profileName];

    String localSidKey = Constants.USER_COUNTRY_PARAMS_MAP.get(businessUnit).get('locale');
    String languageLocaleKey = Constants.USER_COUNTRY_PARAMS_MAP.get(businessUnit).get('language');
    String timeZoneSidKey = Constants.USER_COUNTRY_PARAMS_MAP.get(businessUnit).get('timeZone');
    String bu = Constants.USER_COUNTRY_PARAMS_MAP.get(businessUnit).get('bu');
    String currencyCode = Constants.USER_COUNTRY_PARAMS_MAP.get(businessUnit).get('currency');
    if (String.isBlank(currencyCode))
      currencyCode = 'EUR';

    return new User(
      FirstName = firstName + Datetime.now().getTime(),
      LastName = lastName,
      Email = firstName + '.' + lastName + Datetime.now().getTime() + '@edenred.com',
      Alias = String.valueOf(Datetime.now().getTime()).right(8),
      Username = firstName + '.' + lastName + Datetime.now().getTime() + '@edenred.com.test',
      Country = bu,
      ER_Business_Unit__c = bu,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = languageLocaleKey,
      LocaleSidKey = localSidKey,
      IsActive = true,
      ProfileId = p.Id,
      TimeZoneSidKey = timeZoneSidKey,
      CurrencyIsoCode = currencyCode
    );
  }
}