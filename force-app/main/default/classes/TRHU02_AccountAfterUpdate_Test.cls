@isTest
public class TRHU02_AccountAfterUpdate_Test {
  /*
----------------------------------------------------------------------
-- - Name          : TRHU02_AccountAfterUpdate_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
					- TRHU02_AccountAfterUpdate
					- APHU02_SynchronizeMerchantWS
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 05-MAR-2018  AAB    				1.0      	Initial version 
---------------------------------------------------------------------------------------
*/

  static map<String, map<String, RecordType>> recordTypeMap;
  static List<Account> merchantAcctList;
  static List<ER_Financial_Center__c> financCenterList;
  static List<ER_Bank_Account__c> bankAccList;
  static List<Contact> contactList;
  static List<ER_Store__c> storeList;
  static List<ER_Acceptor__c> acceptorList;

  static void init() {
    /** RecordTypes **/
    recordTypeMap = getRecordTypesBySObject(new List<String>{ 'Account' });

    System.debug('--- Create Account ---');

    APER05_DoNotRunTrigger donotRunTrigger = new APER05_DoNotRunTrigger();
    donotRunTrigger.setDoNotRunTrigger();

    /** Merchant Account **/
    merchantAcctList = new List<Account>();
    merchantAcctList.addAll(
      WSHU02_SynchronizeMerchantWS_Test.createAccountsStandard(
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
    contactList = new List<Contact>();
    contactList.addAll(WSHU02_SynchronizeMerchantWS_Test.createcontactsStandard(2, merchantAcctList[0].Id, true));

    /* Update Account */
    System.debug('--- Update Account ---');
    merchantAcctList[0].HU_HQ_Contact__c = contactList[0].Id;
    update merchantAcctList;

    /* Financial center */
    System.debug('--- Create Financial Center ---');
    financCenterList = new List<ER_Financial_Center__c>();
    financCenterList.addAll(
      WSHU02_SynchronizeMerchantWS_Test.createFinCentersStandard(
        1,
        merchantAcctList[0].Id,
        contactList[1].Id,
        true,
        Label.LABS_SF_FinancialCenter_Merchant
      )
    );

    /* Bank Account */
    System.debug('--- Create bank Account ---');
    bankAccList = new List<ER_Bank_Account__c>();
    bankAccList.addAll(WSHU02_SynchronizeMerchantWS_Test.createbankAccountsStandard(1, financCenterList[0].Id, true));

    /* Update Account */
    System.debug('--- Update Account ---');
    financCenterList[0].ER_Bank_Account__c = bankAccList[0].Id;
    update financCenterList;

    /* Store */
    System.debug('--- Create Account ---');
    storeList = new List<ER_Store__c>();
    storeList.addAll(
      WSHU02_SynchronizeMerchantWS_Test.createstoresStandard(
        1,
        merchantAcctList[0].Id,
        financCenterList[0].Id,
        contactList[1].Id,
        true
      )
    );

    /* Store */
    System.debug('--- Create associated Acceptor ---');
    acceptorList = new List<ER_Acceptor__c>();
    acceptorList.addAll(WSHU02_SynchronizeMerchantWS_Test.createacceptorsStandard(1, storeList[0].Id, true));
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

  static testMethod void TestAccountAfterUpdateCreateMerchant() {
    // Test data setup
    System.debug('--- init data start (Account, contact, bankAccount, store and Acceptor)');
    init();
    System.debug('--- init data end (Account, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU01_CreateMerchantSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    System.debug('--- Test.startTest()');

    Test.startTest();

    System.debug('--- Call WSHU02_SynchronizeMerchantWS.addMerchantsAura');

    WSHU02_SynchronizeMerchantWS.addMerchantsAura(merchantAcctList[0].Id, null);

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    List<Account> result = [
      SELECT id, ER_Creation_date_in_OS__c
      FROM Account
      WHERE RecordTypeId = :recordTypeMap.get('Account').get('ER_Company_Account_RT').Id
    ];
    System.assertEquals(
      true,
      result[0].ER_Creation_date_in_OS__c != null,
      'there merchant account had been successfully updated'
    );
  }

  static testMethod void TestAccountAfterUpdateUpdateMerchant() {
    // Test data setup
    System.debug('--- init data start (Account, contact, bankAccount, store and Acceptor)');
    init();
    System.debug('--- init data end (Account, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU02_UpdateMerchantSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    System.debug('--- Test.startTest()');

    Test.startTest();

    System.debug('--- Update merchant');

    Database.SaveResult[] srListCreate = new List<Database.SaveResult>();

    merchantAcctList[0].ER_Status__c = 'Active';
    merchantAcctList[0].ER_Creation_date_in_OS__c = Datetime.now();
    merchantAcctList[0].HU_HQ_Contact__c = contactList[1].Id;

    /* update the corresponding merchant account
     * that should trigger the web service call (EDG)
     * in order to update the merchant
     */

    srListCreate = Database.update(merchantAcctList, false);

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    List<Account> result = [
      SELECT id, ER_Creation_date_in_OS__c
      FROM Account
      WHERE RecordTypeId = :recordTypeMap.get('Account').get('ER_Company_Account_RT').Id
    ];
    System.assertEquals(
      true,
      result[0].ER_Creation_date_in_OS__c != null,
      'there merchant account had been successfully updated'
    );
  }
}