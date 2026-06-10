@isTest
public class TRHU01_FinancialCenterAfterUpdate_Test {
  /*
----------------------------------------------------------------------
-- - Name          : TRHU01_FinancialCenterAfterUpdate_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
                    - TRHU01_FinancialCenterAfterUpdate
                    - WSHU07_SynchronizeInvoiceWS
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 05-MAR-2018  AAB                 1.0         Initial version 
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

    APER05_DoNotRunTrigger donotRunTrigger = new APER05_DoNotRunTrigger();
    donotRunTrigger.setDoNotRunTrigger();

    System.debug('--- Create Account ---');

    /** Merchant Account **/
    merchantAcctList = new List<Account>();
    merchantAcctList.addAll(
      APHU15_UtilityTestMethod.createAccountsStandard(
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
    contactList.addAll(APHU15_UtilityTestMethod.createcontactsStandard(2, merchantAcctList[0].Id, true));

    /* Update Account */
    System.debug('--- Update Account ---');
    merchantAcctList[0].HU_HQ_Contact__c = contactList[0].Id;
    update merchantAcctList;

    /* Financial center */
    System.debug('--- Create Financial Center ---');
    financCenterList = new List<ER_Financial_Center__c>();
    financCenterList.addAll(
      APHU15_UtilityTestMethod.createFinCentersStandard(
        1,
        merchantAcctList[0].Id,
        contactList[1].Id,
        true,
        Label.LABS_SF_FinancialCenter_Merchant
      )
    );
    financCenterList.addAll(
      APHU15_UtilityTestMethod.createFinCentersStandard(1, null, null, true, Label.LABS_SF_FinancialCenter_Merchant)
    );

    /* Bank Account */
    System.debug('--- Create bank Account ---');
    bankAccList = new List<ER_Bank_Account__c>();
    bankAccList.addAll(APHU15_UtilityTestMethod.createbankAccountsStandard(1, financCenterList[0].Id, true));
    bankAccList.addAll(APHU15_UtilityTestMethod.createbankAccountsStandard(1, financCenterList[1].Id, true));

    /* Update Financial center */
    System.debug('--- Update Financial center ---');
    financCenterList[0].ER_Bank_Account__c = bankAccList[0].Id;
    financCenterList[1].ER_Bank_Account__c = bankAccList[1].Id;

    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    update financCenterList;

    /* Store */
    System.debug('--- Create Store ---');
    storeList = new List<ER_Store__c>();
    storeList.addAll(
      APHU15_UtilityTestMethod.createstoresStandard(merchantAcctList[0].Id, financCenterList, contactList[1].Id, true)
    );

    /* Store */
    System.debug('--- Create associated Acceptor ---');
    acceptorList = new List<ER_Acceptor__c>();
    acceptorList.addAll(APHU15_UtilityTestMethod.createacceptorsStandard(storeList, true));
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

  static testMethod void TestFinancialCenterAfterUpdateCreateMerchant() {
    // Test data setup
    System.debug('--- init data start (Account, contact, bankAccount, store and Acceptor)');
    init();
    System.debug('--- init data end (Account, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU03_CreateFinancialCenterSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    merchantAcctList[0].ER_Creation_date_in_OS__c = Datetime.now();

    WSHU02_SynchronizeMerchantWS.alreadyExecutedAccount = true;
    update merchantAcctList;

    financCenterList[1].ER_Account_Name__c = merchantAcctList[0].Id;
    //financCenterList[1].ER_Contact__c = contactList[1].Id;

    System.debug('--- Test.startTest()');

    Test.startTest();

    System.debug('--- Send the new Financial center to CMO on update');
    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = false;
    update financCenterList[1];

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

  static testMethod void TestFinancialCenterAfterUpdateUpdateMerchant() {
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

    merchantAcctList[0].ER_Creation_date_in_OS__c = Datetime.now();

    WSHU02_SynchronizeMerchantWS.alreadyExecutedAccount = true;
    update merchantAcctList;

    financCenterList[0].ER_Creation_date_in_OS__c = Datetime.now();
    financCenterList[0].ER_Card_Operational_System_ID__c = '12091993';

    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    update financCenterList[0];

    System.debug('--- Test.startTest()');

    Test.startTest();

    System.debug('--- Update merchant');

    Database.SaveResult[] srListCreate = new List<Database.SaveResult>();

    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = false;

    APER05_DoNotRunTrigger donotRunTrigger = new APER05_DoNotRunTrigger();

    financCenterList[0].ER_Street__c = '78 bld Gabriel Péri';
    financCenterList[0].ER_Contact__c = contactList[0].Id;

    update financCenterList[0];

    /* update the corresponding merchant account
     * that should trigger the web service call (EDG)
     * in order to update the merchant
     */

    /*srListCreate = Database.update(financCenterList, false);*/

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    //List<Account> result = [Select id, HU_Creation_date_in_OS__c from Account where RecordTypeId  =:recordTypeMap.get('Account').get('HU_Merchant_Account_RT').Id];
    //System.assertEquals(true, result[0].HU_Creation_date_in_OS__c != null, 'there merchant account had been successfully updated');
  }
}