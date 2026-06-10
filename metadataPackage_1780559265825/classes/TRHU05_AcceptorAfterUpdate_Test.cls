@isTest
public class TRHU05_AcceptorAfterUpdate_Test {
  /*
----------------------------------------------------------------------
-- - Name          : TRHU05_AcceptorAfterUpdate_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
					- TRHU05_AcceptorAfterUpdate
					- APHU09_SynchronizeAcceptorWS
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 06-JUN-2018  AAB    				1.0      	Initial version 
---------------------------------------------------------------------------------------
*/

  static map<String, map<String, RecordType>> recordTypeMap;
  static List<Account> merchantAcctList;
  static List<ER_Financial_Center__c> financCenterList;
  static List<ER_Bank_Account__c> bankAccList;
  static List<Contact> contactList;
  static List<ER_Store__c> storeList;
  static List<ER_Acceptor__c> acceptorList;

  static void init(Boolean iscomplexMerchant, Boolean isToCreate) {
    /** RecordTypes **/
    recordTypeMap = getRecordTypesBySObject(new List<String>{ 'Account' });

    System.debug('--- Create Account ---');

    /** Merchant Account **/
    merchantAcctList = new List<Account>();
    merchantAcctList.addAll(
      WSHU09_SynchronizeAcceptorWS_Test.createAccountsStandard(
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
    contactList.addAll(WSHU09_SynchronizeAcceptorWS_Test.createcontactsStandard(2, merchantAcctList[0].Id, true));

    /* Update Account */
    System.debug('--- Update Account ---');
    merchantAcctList[0].HU_HQ_Contact__c = contactList[0].Id;
    update merchantAcctList;

    /* Financial center */
    System.debug('--- Create Financial Center ---');
    financCenterList = new List<ER_Financial_Center__c>();
    financCenterList.addAll(
      WSHU09_SynchronizeAcceptorWS_Test.createFinCentersStandard(
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
    bankAccList.addAll(WSHU09_SynchronizeAcceptorWS_Test.createbankAccountsStandard(1, financCenterList[0].Id, true));

    /* Update Account */
    System.debug('--- Update Account ---');
    financCenterList[0].ER_Bank_Account__c = bankAccList[0].Id;
    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    update financCenterList;

    /* Store */
    System.debug('--- Create Store ---');
    storeList = new List<ER_Store__c>();
    storeList.addAll(
      WSHU09_SynchronizeAcceptorWS_Test.createstoresStandard(
        merchantAcctList[0].Id,
        financCenterList,
        contactList[1].Id,
        true
      )
    );

    /* Store */
    System.debug('--- Create associated Acceptor ---');
    acceptorList = new List<ER_Acceptor__c>();
    acceptorList.addAll(WSHU09_SynchronizeAcceptorWS_Test.createacceptorsStandard(storeList, true));
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
        System.debug('The batch has been successfully proceed. Invoice Center ID: ' + sr.getId());
      } else {
        // Operation failed, so get all errors
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Invice Center fields that affected this error: ' + err.getFields());
        }
      }
    }
  }

  static testMethod void TestAcceptorAfterUpdateUpdateAcceptor() {
    // Test data setup
    System.debug('--- init data start (Account, Invoice Center, contact, bankAccount, store and Acceptor)');
    init(false, true);
    System.debug('--- init data end (Account, Invoice Center, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU04_AddAcceptancePointSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    acceptorList[0].ER_Last_date_of_Sync__c = Datetime.now();
    acceptorList[0].ER_Card_Operational_System_ID__c = '99999999999';

    System.debug('--- Test.startTest()');

    Test.startTest();

    Database.SaveResult[] srListCreate = new List<Database.SaveResult>();

    /* update the corresponding acceptor
     * that should trigger the web service call (EDG)
     */
    srListCreate = Database.update(acceptorList, false);

    Check_theDatabaseInsert(srListCreate);

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    //List<ER_Acceptor__c> result = [Select id, HU_Last_date_of_Sync__c from ER_Acceptor__c];
    //System.assertEquals(true, result[0].HU_Last_date_of_Sync__c != null, 'there acceptor had been successfully added');
  }

  static testMethod void TestAcceptorAfterUpdateCreateAcceptor() {
    // Test data setup
    System.debug('--- init data start (Account, Invoice Center, contact, bankAccount, store and Acceptor)');
    init(false, true);
    System.debug('--- init data end (Account, Invoice Center, contact, bankAccount, store and Acceptor)');

    System.debug('--- Define the mock call out');

    // Define the Callout mock based on static resources
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('SRHU04_AddAcceptancePointSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    financCenterList[0].ER_Creation_date_in_OS__c = Datetime.now();

    WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
    update financCenterList;

    /* Store */
    System.debug('--- Create new Store ---');
    List<ER_Store__c> storeListToadd = new List<ER_Store__c>();
    storeListToadd.addAll(
      WSHU09_SynchronizeAcceptorWS_Test.createstoresStandard(
        merchantAcctList[0].Id,
        financCenterList,
        contactList[1].Id,
        true
      )
    );

    System.debug('--- Add an acceptor ---');

    List<ER_Acceptor__c> acceptors = new List<ER_Acceptor__c>();

    acceptors.add(
      new ER_Acceptor__c(
        Name = 'CANDA HOTEL 2',
        ER_Store__c = storeListToadd[0].Id,
        ER_Card_Operational_System_ID__c = '152356789',
        ER_MID_Authorization__c = '12091993'
      )
    );

    System.debug('--- Test.startTest()');

    Test.startTest();

    Database.SaveResult[] srListCreate = new List<Database.SaveResult>();

    /* insert the corresponding acceptor
     * that should trigger the web service call (EDG)
     */
    srListCreate = Database.insert(acceptors, false);

    Check_theDatabaseInsert(srListCreate);

    Test.stopTest();

    System.debug('--- Test.stopTest()');

    // Check the results (assert)
    //List<ER_Acceptor__c> result = [Select id, HU_Last_date_of_Sync__c from ER_Acceptor__c];
    //System.assertEquals(true, result[0].HU_Last_date_of_Sync__c != null, 'there acceptor had been successfully added');
  }
}