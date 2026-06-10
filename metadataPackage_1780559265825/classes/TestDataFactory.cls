/**
 * @author : ALK
 * @date : 26/04/2021
 * @desc : TestDataFactory
 * @see TestDataFactory
 */

 @isTest
 public without sharing class TestDataFactory {
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
       CurrencyIsoCode = currencyCode,
       ER_BypassVR__c = true
     );
   }
 
   public static User newUser(
     String firstName,
     String lastName,
     String profileName,
     String roleName,
     String businessUnit
   ) {
     UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = :roleName LIMIT 1];
     User newUser = newUser(firstName, lastName, profileName, businessUnit);
     newUser.UserRoleId = ur.Id;
     return newUser;
   }
 
   public static Map<String, String> getBelfirstInfosTestDatas() {
     return new Map<String, String>{
       'NAME' => 'PRUNELLI',
       'PHONE' => '+32 213 345 698',
       'TYPE' => 'Société privée à responsabilité limitée',
       'ADDRESS' => 'Energielaan 3C',
       'POSTCODE' => '1000',
       'TOWN' => 'BRUSSELS',
       'COUNTRY' => 'BELGIUM',
       'BVDID' => 'BE0679589027'
     };
   }
 
   public static Campaign newCampaign(String campaignName, String sourceId, String businessUnit) {
     Campaign cmp = new Campaign();
     cmp.Name = campaignName;
     cmp.ER_Business_Unit__c = businessUnit;
     cmp.ER_Source_ID__c = sourceId;
     cmp.IsActive = true;
     cmp.StartDate = System.Today();
     cmp.EndDate = System.Today() + 10;
     cmp.Status = 'In Progress';
 
     return cmp;
   }
 
   public static void insertCampaign(String campaignName, String sourceId, String businessUnit) {
     Campaign cmp = newCampaign(campaignName, sourceId, businessUnit);
     insert cmp;
   }
 
   public static void insertProducts(String solutionName, String solutionCode, String businessUnit, String scopeCode) {
     insertProducts(solutionName, solutionCode, businessUnit, scopeCode, businessUnit + ' Pricebook');
   }
 
   public static void insertProducts(
     String solutionName,
     String solutionCode,
     String businessUnit,
     String scopeCode,
     String pricebookName
   ) {
     // Create products (Solution & attached services)
     String solutionRecTyp = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Solution');
     String serviceRecTyp = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Service');
 
     Product2 solutionProd = new Product2(
       BU_External_Reference__c = solutionCode,
       ER_Business_Unit__c = businessUnit,
       ER_BUPicklist__c = businessUnit,
       ER_MUC__c = scopeCode,
       ER_Type__c = 'Solution',
       IsActive = true,
       Name = solutionName,
       ProductCode = solutionCode,
       RecordTypeId = solutionRecTyp
     );
     insert solutionProd;
 
     Product2 serviceProd1 = new Product2(
       Name = 'Participation',
       ProductCode = solutionCode + '_001',
       ER_Business_Unit__c = businessUnit,
       ER_BUPicklist__c = businessUnit,
       ER_MUC__c = scopeCode,
       ER_Type__c = 'Service',
       QuantityUnitOfMeasure = 'Per Unit',
       RecordTypeId = serviceRecTyp,
       ER_Solution__c = solutionProd.Id
     );
     Product2 serviceProd2 = new Product2(
       Name = 'Entrance Fee',
       ProductCode = solutionCode + '_002',
       ER_Business_Unit__c = businessUnit,
       ER_BUPicklist__c = businessUnit,
       ER_MUC__c = scopeCode,
       ER_Type__c = 'Service',
       QuantityUnitOfMeasure = 'Per Unit',
       ER_Solution__c = solutionProd.Id
     );
     Product2 serviceProd3 = new Product2(
       Name = 'Licence',
       ProductCode = solutionCode + '_003',
       ER_Business_Unit__c = businessUnit,
       ER_BUPicklist__c = businessUnit,
       ER_MUC__c = scopeCode,
       ER_Type__c = 'Service',
       QuantityUnitOfMeasure = 'Per Unit',
       ER_Solution__c = solutionProd.Id
     );
 
     insert new List<Product2>{ serviceProd1, serviceProd2, serviceProd3 };
 
     // Create pricebook entries in standard pricebook
     Id pricebookId = Test.getStandardPricebookId();
 
     PricebookEntry standardPrice1 = new PricebookEntry(
       Pricebook2Id = pricebookId,
       Product2Id = solutionProd.Id,
       ER_ValueType__c = 'Currency',
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
     PricebookEntry standardPrice2 = new PricebookEntry(
       Pricebook2Id = pricebookId,
       Product2Id = serviceProd1.Id,
       ER_ValueType__c = 'Percentage',
       ER_Percentage__c = 15.0,
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
     PricebookEntry standardPrice3 = new PricebookEntry(
       Pricebook2Id = pricebookId,
       Product2Id = serviceProd2.Id,
       ER_ValueType__c = 'Currency',
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
     PricebookEntry standardPrice4 = new PricebookEntry(
       Pricebook2Id = pricebookId,
       Product2Id = serviceProd3.Id,
       ER_ValueType__c = 'Currency',
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
 
     // Create pricebook entries in custom pricebook
     Pricebook2 customPB = new Pricebook2(
       Name = pricebookName,
       isActive = true,
       ER_Business_Unit__c = businessUnit,
       ER_BUPicklist__c = businessUnit
     );
     insert customPB;
 
     PricebookEntry standardPrice5 = new PricebookEntry(
       Pricebook2Id = customPB.Id,
       Product2Id = solutionProd.Id,
       ER_ValueType__c = 'Currency',
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
     PricebookEntry standardPrice6 = new PricebookEntry(
       Pricebook2Id = customPB.Id,
       Product2Id = serviceProd1.Id,
       ER_ValueType__c = 'Percentage',
       ER_Percentage__c = 15.0,
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
     PricebookEntry standardPrice7 = new PricebookEntry(
       Pricebook2Id = customPB.Id,
       Product2Id = serviceProd2.Id,
       ER_ValueType__c = 'Currency',
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
     PricebookEntry standardPrice8 = new PricebookEntry(
       Pricebook2Id = customPB.Id,
       Product2Id = serviceProd3.Id,
       ER_ValueType__c = 'Currency',
       CurrencyIsoCode = 'EUR',
       UnitPrice = 0.0,
       IsActive = true
     );
 
     insert new List<PricebookEntry>{
       standardPrice1,
       standardPrice2,
       standardPrice3,
       standardPrice4,
       standardPrice5,
       standardPrice6,
       standardPrice7,
       standardPrice8
     };
   }
 
   public static void insertTermsAndConditions(String country, String lang, String solution, String scope) {
     String docTitle = country + '-' + lang + '-' + solution + '-' + scope + ' Terms and conditions';
     String urlName = country + '-' + lang + '-' + solution.replace('_', '-') + '-' + scope + '-Terms-and-conditions';
 
     insertKnowledgeArticle(docTitle, urlName, 'Test');
   }
 
   public static void insertPDFContract(String country, String lang, String solution, String scope) {
     String docTitle = country + '-' + lang + '-' + solution + '-' + scope + ' Contract PDF';
     String urlName = country + '-' + lang + '-' + solution.replace('_', '-') + '-' + scope + '-Contract-PDF';
 
     insertKnowledgeArticle(docTitle, urlName, 'Test');
   }
 
   public static void insertKnowledgeArticle(String docTitle, String urlName, String articleBody) {
     /*System.debug('>>> insertKnowledgeArticle --  docTitle: ' + docTitle);
     System.debug('>>> insertKnowledgeArticle --  urlName: ' + urlName);
     Knowledge__kav tcArticle = new Knowledge__kav(ER_Article_Body__c = articleBody, Title = docTitle, UrlName = urlName);
     insert tcArticle;
     Knowledge__kav tcArticleCreated = [
       SELECT Id, Title, KnowledgeArticleId
       FROM Knowledge__kav
       WHERE Id = :tcArticle.Id
     ];
     KbManagement.PublishingService.publishArticle(tcArticleCreated.KnowledgeArticleId, true);*/
   }
 
   /**
    * @author ALK
    * @description New Account for test classes
    * @return
    */
   public static Account newAccount() {
     Id rtId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, 'ER_Company_Account_RT');
     return new Account(
       Name = 'Account' + Datetime.now().getTime(),
       RecordTypeId = rtId,
       ER_Match_Legal_Address__c = true,
       ER_VAT_Number__c = '00000001-1-01'
     );
   }
 
   /**
    * @author ALK
    * @description New Contact for test classes
    * @param acc
    *
    * @return
    */
   public static Contact newContact(Account acc) {
     Id rtId = Utils.getRecordTypeIdByDeveloperName(Contact.SObjectType, 'ER_Contact_RT');
     return new Contact(
       Salutation='Mr',
       FirstName = 'FirstName' + Datetime.now().getTime(),
       LastName = 'LastName' + Datetime.now().getTime(),
       RecordTypeId = rtId,
       Email = 'Firstname' + Datetime.now().getTime() + '@mailinator.com.test',
       AccountId = acc.Id
     );
   }
 
   /**
    * @author ALK
    * @description new Financial Center
    * @param acc
    * @param type
    *
    * @return
    */
   public static ER_Financial_Center__c newFinancialCenter(Account acc, String type) {
     return new ER_Financial_Center__c(
       Name = 'FC' + Datetime.now().getTime(),
       ER_Account_Name__c = acc.Id,
       ER_Type__c = type,
       ER_Street__c = 'Some Street',
       ER_City__c = 'someCity',
       ER_Zip_Code__c = '12345',
       ER_Country__c = 'someCountry',
       ER_Payment_Site__c = true
     );
   }
 
   /**
    * @author ALK
    * @description new Merchant FC
    * @param acc
    *
    * @return
    */
   public static ER_Financial_Center__c newMerchantFC(Account acc) {
     return newFinancialCenter(acc, 'Merchant');
   }
 
   /**
    * @author ALK
    * @description new Client FC
    * @param acc
    *
    * @return
    */
   public static ER_Financial_Center__c newClientFC(Account acc) {
     return newFinancialCenter(acc, 'Client');
   }
 
   /**
    * @author VJO
    * @description new ER_Delivery_Site__c
    * @param acc, fc, name
    * @param type
    *
    * @return
    */
   public static ER_Delivery_Site__c newDeliverySite(Account acc, String name, ER_Financial_Center__c fc) {
     return new ER_Delivery_Site__c(Name = name, ER_Account_Name__c = acc.Id, ER_Financial_Center__c = fc.Id);
   }
 
   /**
    * @author VJO
    * @description new ER_Distribution_Point__c
    * @param ds, name
    * @param type
    *
    * @return
    */
   public static ER_Distribution_Point__c newDistributionPoint(String name, String deliverySiteId) {
     return new ER_Distribution_Point__c(Name = name, ER_Delivery_Site__c = deliverySiteId);
   }
 
   /**
    * @author VJO
    * @description new ER_Contact_Role__c
    * @param contact, parentid, recordtype, primary
    * @param type
    *
    * @return
    */
   public static ER_Contact_Role__c newContactRole(String contactId, Id parentID, String recordType, Boolean isPrimary) {
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
 
   /**
    * @author AAM
    * @description Create store categories for test classes
    * @return
    */
   public static String insertStoreCategory(String solutionId, String lang, String businessUnit) {
     ER_DependentValue__c depVal = new ER_DependentValue__c(
       ER_Business_Unit__c = businessUnit,
       ER_Status__c = 'Active',
       Name = 'Dummy category',
       Solution_and_Service__c = solutionId
     );
     insert depVal;
 
     insert new ER_Translation__c(
       Field_API_Name__c = 'ER_StoreCategory__c',
       Language__c = lang,
       Dependent_Value__c = depVal.Id,
       Text__c = 'Dummy Label'
     );
     return depVal.Id;
   }
   
   /**
    * @author AAM
    * @description Create promo code for test classes
    * @return
    */
   public static void insertPromoCode(String name, String buCode) {
     ER_Promo_Code__c promo = new ER_Promo_Code__c();
     promo.Name = name;
     promo.ER_Business_Unit__c = buCode;
     promo.ER_Start_Date__c = Date.today().addDays(-5);
     promo.ER_Promo_Code__c = name;
     promo.ER_Status__c = 'Activated';
     promo.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
       ER_Promo_Code__c.SObjectType,
       Constants.PROMO_CODE_PROMO_RT
     );
     insert promo;
   }
 }