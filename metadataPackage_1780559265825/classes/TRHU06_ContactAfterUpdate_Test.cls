@isTest
public class TRHU06_ContactAfterUpdate_Test {
  /*
----------------------------------------------------------------------
-- - Name          : TRHU06_ContactAfterUpdate_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
					- TRHU06_ContactAfterUpdate
					- APHU10_SynchronizeContactWS
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 31-JUL-2018  AAB    				1.0      	Initial version 
---------------------------------------------------------------------------------------
*/

  static map<String, map<String, RecordType>> recordTypeMap;
  static List<Account> merchantAcctList;
  static List<ER_Financial_Center__c> financCenterList;
  static List<ER_Bank_Account__c> bankAccList;
  static List<Contact> contactListHQ;
  static List<Contact> contactListInv;

  static List<ER_Store__c> storeList;
  static List<ER_Acceptor__c> acceptorList;

  static void init() {
    /** RecordTypes **/
    recordTypeMap = getRecordTypesBySObject(new List<String>{ 'Account' });

    System.debug('--- Create Account ---');

    /** Merchant Account **/
    merchantAcctList = new List<Account>();
    merchantAcctList.addAll(
      WSHU10_SynchronizeContactWS_Test.createAccountsStandard(
        1,
        recordTypeMap.get('Account').get('ER_Company_Account_RT').Id,
        '12345678-9-12',
        true
      )
    );

    /** Asociated records
     * Bank Account
     * Contacts (Head Quarter/Financial)
     **/

    /* HQ contact /Invoicing contact */
    System.debug('--- Create Contacts ---');
    contactListHQ = new List<Contact>();
    contactListHQ.addAll(WSHU10_SynchronizeContactWS_Test.createcontactsStandard(1, merchantAcctList[0].Id, true));

    contactListInv = new List<Contact>();
    contactListInv.addAll(WSHU10_SynchronizeContactWS_Test.createcontactsStandard(1, merchantAcctList[0].Id, true));

    /* Update Account */
    System.debug('--- Update Account ---');
    merchantAcctList[0].HU_HQ_Contact__c = contactListHQ[0].Id;
    update merchantAcctList;

    /* Financial center */
    System.debug('--- Create Financial Center ---');
    financCenterList = new List<ER_Financial_Center__c>();
    financCenterList.addAll(
      WSHU10_SynchronizeContactWS_Test.createFinCentersStandard(
        1,
        merchantAcctList[0].Id,
        contactListInv[0].Id,
        true,
        Label.LABS_SF_FinancialCenter_Merchant
      )
    );

    /* Bank Account */
    System.debug('--- Create bank Account ---');
    bankAccList = new List<ER_Bank_Account__c>();
    bankAccList.addAll(WSHU10_SynchronizeContactWS_Test.createbankAccountsStandard(1, financCenterList[0].Id, true));

    /* Update Account */
    System.debug('--- Update Account ---');
    financCenterList[0].ER_Bank_Account__c = bankAccList[0].Id;
    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    update financCenterList;

    /* Store */
    System.debug('--- Create Account ---');
    storeList = new List<ER_Store__c>();
    storeList.addAll(
      WSHU10_SynchronizeContactWS_Test.createstoresStandard(
        1,
        merchantAcctList[0].Id,
        financCenterList[0].Id,
        contactListInv[0].Id,
        true
      )
    );

    /* Store */
    System.debug('--- Create associated Acceptor ---');
    acceptorList = new List<ER_Acceptor__c>();
    acceptorList.addAll(WSHU10_SynchronizeContactWS_Test.createacceptorsStandard(1, storeList[0].Id, true));
  }

  /** Return the record types by objet **/
  public static map<String, map<String, RecordType>> getRecordTypesBySObject(List<String> sObjectName) {
    map<String, map<String, RecordType>> result = new Map<String, map<String, RecordType>>();

    List<RecordType> recordTypeList = [
      SELECT Id, Name, DeveloperName, SobjectType
      FROM RecordType
      WHERE SobjectType IN :sObjectName
    ];

    for (RecordType aRecordType : recordTypeList) {
      if (!result.containsKey(aRecordType.SobjectType)) {
        result.put(aRecordType.SobjectType, new Map<String, RecordType>());
      }

      result.get(aRecordType.SobjectType).put(aRecordType.DeveloperName, aRecordType);
    }

    return result;
  }

  static void Check_theDatabaseInsert(List<Database.SaveResult> srList) {
    // Verify that the insertion should process by the trigger
    // Iterate through each returned result
    System.debug('## >>> Check the Database insert  <<< ');
    for (Database.SaveResult sr : srList) {
      if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('The batch has been successfully proceed. Account ID: ' + sr.getId());
      } else {
        // Operation failed, so get all errors
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Account fields that affected this error: ' + err.getFields());
        }
      }
    }
  }

  static testMethod void TestContactAfterUpdateUpdateHQContact() {
    // Test data setup
    System.debug('--- init data start (Account, contact, bankAccount, store and Acceptor)');
    init();
    System.debug('--- init data end (Account, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU05_UpdateContactSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    merchantAcctList[0].ER_Creation_date_in_OS__c = Datetime.now();
    update merchantAcctList;

    System.debug('--- Test.startTest()');

    Test.startTest();

    System.debug('--- Update contact Head quarter ');

    Database.SaveResult[] srListCreate = new List<Database.SaveResult>();

    contactListHQ[0].LastName = 'new lastname';

    /* update the corresponding merchant account
     * that should trigger the web service call (EDG)
     * in order to update the merchant
     */
    WSHU10_SynchronizeContactWS.alreadyExecutedContact = false;
    srListCreate = Database.update(contactListHQ, false);

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    //List<Account> result = [Select id, HU_Creation_date_in_OS__c from Account where RecordTypeId  =:recordTypeMap.get('Account').get('HU_Merchant_Account_RT').Id];
    //System.assertEquals(true, result[0].HU_Creation_date_in_OS__c != null, 'there merchant account had been successfully updated');
  }

  static testMethod void TestContactAfterUpdateUpdateInvoiceContact() {
    // Test data setup
    System.debug('--- init data start (Account, contact, bankAccount, store and Acceptor)');
    init();
    System.debug('--- init data end (Account, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU05_UpdateContactSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    merchantAcctList[0].ER_Creation_date_in_OS__c = Datetime.now();
    WSHU02_SynchronizeMerchantWS.alreadyExecutedAccount = true;
    update merchantAcctList;

    financCenterList[0].ER_Card_Operational_System_ID__c = '123456789';
    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    update financCenterList;

    System.debug('--- Test.startTest()');

    Test.startTest();

    System.debug('--- Update contact Head quarter ');

    Database.SaveResult[] srListCreate = new List<Database.SaveResult>();

    contactListInv[0].LastName = 'new lastname';

    /* update the corresponding merchant account
     * that should trigger the web service call (EDG)
     * in order to update the merchant
     */
    WSHU10_SynchronizeContactWS.alreadyExecutedContact = false;
    srListCreate = Database.update(contactListInv, false);

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    //List<Account> result = [Select id, HU_Creation_date_in_OS__c from Account where RecordTypeId  =:recordTypeMap.get('Account').get('HU_Merchant_Account_RT').Id];
    //System.assertEquals(true, result[0].HU_Creation_date_in_OS__c != null, 'there merchant account had been successfully updated');
  }

  static testMethod void TestContactAfterUpdateUpdateBothContact() {
    // Test data setup
    System.debug('--- init data start (Account, contact, bankAccount, store and Acceptor)');
    init();
    System.debug('--- init data end (Account, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU05_UpdateContactSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    merchantAcctList[0].ER_Creation_date_in_OS__c = Datetime.now();
    merchantAcctList[0].HU_HQ_Contact__c = contactListInv[0].Id;
    update merchantAcctList;

    financCenterList[0].ER_Card_Operational_System_ID__c = '123456789';
    update financCenterList;

    System.debug('--- Test.startTest()');

    Test.startTest();

    System.debug('--- Update contact Head quarter ');

    Database.SaveResult[] srListCreate = new List<Database.SaveResult>();

    contactListInv[0].LastName = 'new lastname';

    /* update the corresponding merchant account
     * that should trigger the web service call (EDG)
     * in order to update the merchant
     */

    srListCreate = Database.update(contactListInv, false);

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    //List<Account> result = [Select id, HU_Creation_date_in_OS__c from Account where RecordTypeId  =:recordTypeMap.get('Account').get('HU_Merchant_Account_RT').Id];
    //System.assertEquals(true, result[0].HU_Creation_date_in_OS__c != null, 'there merchant account had been successfully updated');
  }
}