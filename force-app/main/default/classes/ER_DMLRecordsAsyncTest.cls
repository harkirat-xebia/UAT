/**
 * Created by ELAK on 23/12/2021.
 */

@isTest
public with sharing class ER_DMLRecordsAsyncTest {
  @testSetup
  static void setup() {
    List<ER_Store__c> stores = new List<ER_Store__c>();
    List<ER_Contact_Role__c> roles = new List<ER_Contact_Role__c>();

    Account AccTst = APER07_UtilityTestMethod.insertAccount('Test Account', 'ER_Company_Account_RT');
    Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test', 'test');
    newContact.AccountId = AccTst.Id;
    insert newContact;
    ER_Financial_Center__c fc = APER07_UtilityTestMethod.insertFinancialCenter(
      'Test FC',
      AccTst.Id,
      'Aradi u. 62.',
      'Budaörs',
      '2040',
      'HUN',
      Label.LABS_SF_FinancialCenter_Merchant,
      newContact.Id,
      'CZ'
    );

    for (Integer i = 0; i < 110; i++) {
      //add new roles
      ER_Contact_Role__c ctRole = APER07_UtilityTestMethod.getContactRole(
        newContact.id,
        fc.id,
        'ER_CR_Financial_Center_Merchant',
        false
      );
      roles.add(ctRole);

      //add new stores
      ER_Store__C store = APER07_UtilityTestMethod.getStore(
        'Test Store' + i,
        AccTst.id,
        fc.id,
        Date.today(),
        'Test',
        'Test',
        'Test',
        'Test'
      );
      stores.add(store);
    }
    insert roles;
    insert stores;
  }

  static testMethod void testList() {
    List<ER_Store__c> stores = new List<ER_Store__c>();
    List<ER_Contact_Role__c> roles = new List<ER_Contact_Role__c>();
    List<ER_StoreCategory__c> storeCategories = new List<ER_StoreCategory__c>();
    List<ER_Acceptor__c> acceptors = new List<ER_Acceptor__c>();
    List<ER_Solution_Line_Item__c> solutionsItems = new List<ER_Solution_Line_Item__c>();
    ER_Store_to_Loop__c NewStoreToLoop;
    List<ER_Store_to_Loop__c> storeToLoopList = new List<ER_Store_to_Loop__c>();
    ER_Loop__c testLoop = new ER_Loop__c(Name = 'Test loop', ER_External_Reference__c = 'EXT-REF_TEST');
    insert testLoop;

    for (ER_Store__C store : [SELECT Id, ER_Sync_result__c FROM ER_Store__C]) {
      store.ER_Sync_result__c = 'synchronized';
      NewStoreToLoop = new ER_Store_to_Loop__c(
        ER_Loop__c = testLoop.Id,
        ER_Store__c = store.id,
        ER_Behaviour__c = 'ACCEPT'
      );
      storeToLoopList.add(NewStoreToLoop);
      stores.add(store);
    }

    //Roles
    for (ER_Contact_Role__c role : [SELECT Id, ER_Sync_result__c FROM ER_Contact_Role__c]) {
      role.ER_Sync_result__c = 'synchronized';
      roles.add(role);
    }
    ER_DMLRecordsAsync aSynCall = new ER_DMLRecordsAsync(
      solutionsItems,
      stores,
      storeCategories,
      acceptors,
      roles,
      'UPDATE'
    );
    ER_DMLRecordsAsync storeUpdater = new ER_DMLRecordsAsync(stores, 'UPDATE');
    ER_DMLRecordsAsync roleUpdater = new ER_DMLRecordsAsync(roles, 'UPDATE');
    ER_DMLRecordsAsync storeToLoopInsert = new ER_DMLRecordsAsync(storeToLoopList, Constants.INSERT_DML);

    Test.startTest();
    System.enqueueJob(storeUpdater);
    System.enqueueJob(roleUpdater);
    System.enqueueJob(aSynCall);
    System.enqueueJob(storeToLoopInsert);
    Test.stopTest();
    //System.enqueueJob(new ER_DMLRecordsAsync(null, stores, null, null, null));
    //System.enqueueJob(new ER_DMLRecordsAsync(null, null, null, null, roles));

    System.assertEquals(110, [SELECT COUNT() FROM ER_Store__c WHERE ER_Sync_result__c = 'synchronized']);
    //System.assertEquals(111, [SELECT COUNT() FROM ER_Contact_Role__c WHERE ER_Sync_result__c = 'synchronized']);
  }
}