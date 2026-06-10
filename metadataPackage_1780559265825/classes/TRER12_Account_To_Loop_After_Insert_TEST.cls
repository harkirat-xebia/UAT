@isTest
public class TRER12_Account_To_Loop_After_Insert_TEST {
  static map<String, map<String, RecordType>> recordTypeMap;
  static List<Account> merchantAcctList;
  static List<ER_Financial_Center__c> financCenterList;
  static List<ER_Bank_Account__c> bankAccList;
  static List<Contact> contactList;
  static List<ER_Store__c> storeList;
  static List<ER_Acceptor__c> acceptorList;
  static List<ER_Loop__c> LoopList;

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

  @IsTest
  static void TestAddNewAccountToLoop() {
    User ur = TestDataFactory.newUser('FR', 'FR', 'ER Integration', 'FR');
    ur.ER_BypassVR__c = true;
    insert ur;
    {
      init();
      Test.startTest();
      ER_Loop__c looptst = new ER_Loop__c(Name = 'Test loop', ER_External_Reference__c = 'EXT-REF_test');
      insert looptst;
      ER_Account_to_Loop__c newAccountToLoop = new ER_Account_to_Loop__c(
        ER_Behaviour__c = 'DECLINE',
        ER_Loop__c = looptst.id,
        ER_Account__c = merchantAcctList[0].Id
      );
      insert newAccountToLoop;
      ER_Loop__c looptst2 = new ER_Loop__c(Name = 'Test loop2', ER_External_Reference__c = 'EXT-REF_test2');
      insert looptst2;
      ER_Account_to_Loop__c newAccountToLoop2 = new ER_Account_to_Loop__c(
        ER_Behaviour__c = 'DECLINE',
        ER_Loop__c = looptst2.id,
        ER_Account__c = merchantAcctList[0].Id
      );
      insert newAccountToLoop2;
      newAccountToLoop2.ER_Behaviour__c = 'ACCEPT';
      update newAccountToLoop2;
      ER_Store__c store = new ER_Store__c(
        Name = 'CANDA HOTEL',
        ER_Merchant__c = merchantAcctList[0].Id,
        ER_Financial_Center__c = financCenterList[0].Id,
        ER_Contact__c = contactList[0].Id,
        ER_Street__c = 'Test Street',
        ER_City__c = 'BUDAPEST',
        ER_Zip_Code__c = '1095'
      );
      insert store;
      ER_Acceptor__c acceptor = new ER_Acceptor__c(
        Name = 'CANDA HOTEL',
        ER_Store__c = store.Id,
        ER_MID_Authorization__c = '12341993'
      );
      insert acceptor;
      Test.stopTest();
    }
  }
}