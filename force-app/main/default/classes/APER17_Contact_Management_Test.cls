/*
----------------------------------------------------------------------
-- - Name          : APER17_Contact_Management_Test
-- - Author        : OLA
-- - Description   : TEST for Contact Management class
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER17_Contact_Management_Test {
  @testSetup
static void testSetup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('APER17_Contact_Management_Test');
    newMerchantAccount.Name = 'APER17_Contact_Management_Test';
    insert newMerchantAccount;

    Contact contactTest = APER07_UtilityTestMethod.getContact(
      'ER_Contact_RT',
      'Test',
      'APER17_Contact_Management_Test'
    );
    contactTest.AccountId = newMerchantAccount.Id;
    contactTest.Email = 'APER17_Contact_Management_Test@edenred.com';
    contactTest.Salutation = 'Mr.';   // FIX: required by validation rule
    contactTest.ER_Account_Address_Sync__c = Label.LABS_SF_Account_SyncAddressContact;

    insert contactTest;
}


  static testMethod void syncAddressFromAccount() {
    List<Account> accList = [SELECT id FROM Account WHERE Name = 'APER17_Contact_Management_Test'];
    if (!accList.isEmpty()) {
      accList[0].BillingStreet = 'APER17_Contact_Management Street';
      update accList[0];
    }
  }

  @IsTest
  static void syncContactsToSmartERTest() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ER_INTEGRATION,
      'FR'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('syncContactsToSmartERTest');
      acc.SmartER_Customer_Id__c = '12345678';
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
      cont.ER_Language__c = 'FR';
      insert cont;

      System.debug('######## syncContactsToSmartERTest after insert:' + cont);

      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      Test.setMock(HttpCalloutMock.class, smarterMock);
      cont.Email = 'newemail@gmail.com';
      cont.ER_To_sync_with_smarter__c = true;
      update cont;
      System.debug('######## syncContactsToSmartERTest after update:' + cont);
      Test.stopTest();
    }
  }

  @IsTest
  static void syncContactsToSmartERTestFail() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ER_INTEGRATION,
      'FR'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('syncContactsToSmartERTest');
      acc.SmartER_Customer_Id__c = '12345678';
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
      cont.ER_Language__c = 'FR';
      insert cont;

      System.debug('######## syncContactsToSmartERTest after insert:' + cont);

      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      SmarterAPIMock.serviceToFail = Constants.SMARTER_CONTACTS_SERVICE_NAME;
      Test.setMock(HttpCalloutMock.class, smarterMock);
      cont.Email = 'newemail@gmail.com';
      cont.ER_To_sync_with_smarter__c = true;
      update cont;
      System.debug('######## syncContactsToSmartERTest after update:' + cont);
      Test.stopTest();
    }
  }

  @IsTest
  static void sendContactOnboardingNotificationTest() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ZUORA_SALES,
      'FR'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('syncContactsToSmartERTest');
      acc.SmartER_Customer_Id__c = Utils.generateUniqueString(Constants.TYPE_STRING, 10);
      acc.ER_Smarter_1st_Sync_Date__c = Datetime.now();
      acc.ER_Smarter_Last_Sync_Date__c = Datetime.now();
      acc.ER_Smarter_Sync_Status__c = 'Synchronized';
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
      cont.ER_Language__c = 'FR';
      cont.ER_SmartER_Context__c = true;
      cont.ER_To_sync_with_smarter__c = true;
      insert cont;

      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      Test.setMock(HttpCalloutMock.class, smarterMock);
      String message = APER17_Contact_Management.sendContactOnboardingNotification(cont.Id);
      Assert.isNull(message, 'The callout failed');
      Test.stopTest();
    }
  }

  @IsTest
  static void sendContactOnboardingNotificationFailureTest() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ZUORA_SALES,
      'FR'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('syncContactsToSmartERTest');
      acc.SmartER_Customer_Id__c = Utils.generateUniqueString(Constants.TYPE_STRING, 10);
      acc.ER_Smarter_1st_Sync_Date__c = Datetime.now();
      acc.ER_Smarter_Last_Sync_Date__c = Datetime.now();
      acc.ER_Smarter_Sync_Status__c = 'Synchronized';
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
      cont.ER_Language__c = 'FR';
      cont.ER_SmartER_Context__c = true;
      cont.ER_To_sync_with_smarter__c = true;
      insert cont;

      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      SmarterAPIMock.serviceToFail = Constants.SMARTER_SEND_ONBOARDING_SERVICE_NAME;
      Test.setMock(HttpCalloutMock.class, smarterMock);
      String message = APER17_Contact_Management.sendContactOnboardingNotification(cont.Id);
      Assert.isNotNull(message, 'The callout was done successfully');
      Test.stopTest();
    }
  }
    
    //Added by harkirat
    /*@IsTest
static void testDoSyncContactsToSmartERSynchronous_Success() {
    // Use integration profile user like your other tests
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ER_INTEGRATION,
      'FR'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
        // Account with SmartER id
        Account acc = APER07_UtilityTestMethod.getCompany('testDoSyncContactsToSmartER');
        acc.SmartER_Customer_Id__c = '12345678';
        insert acc;

        // Contact to sync
        Contact cont = TestDataFactory.newContact(acc);
        cont.ER_Language__c = 'FR';
        cont.ER_BUPicklist__c = 'BE';
        cont.ER_To_sync_with_smarter__c = true;
        cont.ER_dd_Trace_Id__c = 'trace-123';
        insert cont;

        // Create AccountContactRelation (no IsDirect field!)
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = acc.Id,
            ContactId = cont.Id,
            Roles     = 'Decision Maker'
        );
        insert acr;

        Test.startTest();
        SmarterAPIMock smarterMock = new SmarterAPIMock();
        Test.setMock(HttpCalloutMock.class, smarterMock);

        // Directly call the method you want to cover
        APER17_Contact_Management.doSyncContactsToSmartERSynchronous(new Set<Id>{ cont.Id });

        Test.stopTest();

        // Assert that sync fields were properly updated
        Contact updated = [
          SELECT ER_Smarter_1st_Sync_Date__c,
                 ER_Smarter_Last_Sync_Date__c,
                 ER_Smarter_Sync_Status__c,
                 ER_Smarter_Sync_Error__c
          FROM Contact
          WHERE Id = :cont.Id
        ];

        System.assertEquals(
          Constants.SYNCHRONIZED_STATUS,
          updated.ER_Smarter_Sync_Status__c,
          'Contact should be synchronized after SmartER sync.'
        );
        System.assertNotEquals(null, updated.ER_Smarter_1st_Sync_Date__c, '1st sync date must be set.');
        System.assertNotEquals(null, updated.ER_Smarter_Last_Sync_Date__c, 'Last sync date must be set.');
        System.assertEquals(null, updated.ER_Smarter_Sync_Error__c, 'Error should be cleared on success.');
    }
}
*/
    
    @IsTest
static void testUpdateSmarterContactsSyncFields_ErrorResponse() {
    Account acc = APER07_UtilityTestMethod.getCompany('updateSmarterErrorAcc');
    insert acc;

    Contact c = TestDataFactory.newContact(acc);
    insert c;

    Map<String, Object> payloadItem = new Map<String, Object>();
    payloadItem.put(Constants.SMARTER_CONTACT_ONEFORCE_ID, c.Id);
    List<Object> payloadList = new List<Object>{ payloadItem };

    // Build error-like response body based on method 2 expectations
    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(400);
    resp.setBody('{"meta":{"messages":[{"code":"ERR01","text":"Something went wrong","traceId":"trace-xyz"}]}}');

    List<Contact> contactsToUpdate = APER17_Contact_Management.updateSmarterContactsSyncFields(
      payloadList,
      Constants.PATCH_METHOD,
      resp
    );

    System.assertEquals(1, contactsToUpdate.size(), 'One contact should be returned on error as well.');
    Contact result = contactsToUpdate[0];

    System.assertEquals(c.Id, result.Id);
    System.assertNotEquals(null, result.ER_Smarter_Last_Sync_Date__c);
    System.assertEquals(Constants.NOT_SYNCHRONIZED_STATUS, result.ER_Smarter_Sync_Status__c);
    System.assertNotEquals(null, result.ER_Smarter_Sync_Error__c);
    System.assert(result.ER_Smarter_Sync_Error__c.contains('ERR01'), 'Error string should contain error code.');
}
    
    @IsTest
static void testHasContactChanged_NullValues() {
    Contact base = new Contact(
      FirstName = 'John',
      LastName  = 'Doe',
      Phone     = '1111',
      Email     = 'a@a.com',
      ER_Language__c = 'EN',
      ER_To_sync_with_smarter__c = true
    );

    Boolean res1 = APER17_Contact_Management.hasContactChanged(null, base);
    System.assertEquals(false, res1, 'Null newValue should return false.');

    Boolean res2 = APER17_Contact_Management.hasContactChanged(base, null);
    System.assertEquals(false, res2, 'Null oldValue should return false.');
}

    
    @IsTest
static void testDoSyncContactsToSmartERSynchronous_EmptyIds() {
    Test.startTest();
    // Should simply exit without any exception or callout
    APER17_Contact_Management.doSyncContactsToSmartERSynchronous(new Set<Id>());
    Test.stopTest();
}

    
    @IsTest
static void testUpdateSmarterContactsSyncFields_SuccessPost() {
    // Create a contact whose Id we will put in the payload
    Account acc = APER07_UtilityTestMethod.getCompany('updateSmarterSuccessAcc');
    insert acc;

    Contact c = TestDataFactory.newContact(acc);
    insert c;

    // Build payload list as method 1 would do
    Map<String, Object> payloadItem = new Map<String, Object>();
    payloadItem.put(Constants.SMARTER_CONTACT_ONEFORCE_ID, c.Id);
    List<Object> payloadList = new List<Object>{ payloadItem };

    // Mock successful HttpResponse
    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(204);
    // body not needed for success branch

    List<Contact> contactsToUpdate = APER17_Contact_Management.updateSmarterContactsSyncFields(
      payloadList,
      Constants.POST_METHOD,
      resp
    );

    System.assertEquals(1, contactsToUpdate.size(), 'One contact should be returned.');
    Contact result = contactsToUpdate[0];

    System.assertEquals(c.Id, result.Id);
    System.assertNotEquals(null, result.ER_Smarter_1st_Sync_Date__c);
    System.assertNotEquals(null, result.ER_Smarter_Last_Sync_Date__c);
    System.assertEquals(Constants.SYNCHRONIZED_STATUS, result.ER_Smarter_Sync_Status__c);
    System.assertEquals(null, result.ER_Smarter_Sync_Error__c);
}

    
    

  @IsTest
  static void requestAccessToSmarterApp() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ZUORA_SALES,
      'FR'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('syncContactsToSmartERTest');
      acc.SmartER_Customer_Id__c = Utils.generateUniqueString(Constants.TYPE_STRING, 10);
      acc.ER_Smarter_1st_Sync_Date__c = Datetime.now();
      acc.ER_Smarter_Last_Sync_Date__c = Datetime.now();
      acc.ER_Smarter_Sync_Status__c = 'Synchronized';
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
      cont.ER_Language__c = 'FR';
      cont.ER_SmartER_Context__c = true;
      cont.ER_To_sync_with_smarter__c = true;
      insert cont;

      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      SmarterAPIMock.serviceToFail = Constants.SMARTER_CONTACTS_SERVICE_NAME;
      Test.setMock(HttpCalloutMock.class, smarterMock);
      String message = APER17_Contact_Management.requestAccessToSmarterApp(cont.Id);
      System.debug('>>>>> AAZ requestAccessToSmarterApp - message : ' + message);
      Assert.isNull(message, 'The smarter App access done successfully');
      Test.stopTest();
    }
  }
    
    /* Test method added by harkirat to increase coverage */
/*  To be checked later
@IsTest
static void testPublishContactsToBeSyncedWithSmarter() {
  // Create an account + contact to publish
  Account acc = APER07_UtilityTestMethod.getCompany('PublishTestAccount');
  insert acc;

  Contact cont = TestDataFactory.newContact(acc);
  insert cont;

  // Build a set of ids and call the publisher
  Set<Id> ids = new Set<Id>{ cont.Id };

  Test.startTest();
  APER17_Contact_Management.publishContactsToBeSyncedWithSmarter(ids);
  Test.stopTest();

  System.assert(!ids.isEmpty(), 'IDs set should not be empty after setup.');
}
*/ 
@IsTest
static void testHasContactChangedDirect() {
  Contact oldC = new Contact(FirstName = 'John', LastName = 'Doe', Phone = '1111', Email = 'a@a.com', ER_Language__c = 'EN', ER_To_sync_with_smarter__c = true);
  Contact newC = new Contact(FirstName = 'John', LastName = 'Doe', Phone = '2222', Email = 'a@a.com', ER_Language__c = 'EN', ER_To_sync_with_smarter__c = true);

  // changed phone -> should be true
  Boolean changed = APER17_Contact_Management.hasContactChanged(newC, oldC);
  System.assertEquals(true, changed, 'hasContactChanged should return true when an attribute changed.');

  // identical -> should be false
  Contact newC2 = new Contact(FirstName = 'John', LastName = 'Doe', Phone = '1111', Email = 'a@a.com', ER_Language__c = 'EN', ER_To_sync_with_smarter__c = true);
  Boolean changed2 = APER17_Contact_Management.hasContactChanged(newC2, oldC);
  System.assertEquals(false, changed2, 'hasContactChanged should return false when attributes are identical.');

  // ER_To_sync_with_smarter__c false -> should be false even if fields differ
  Contact newC3 = new Contact(FirstName = 'Johnny', LastName = 'Doe', Phone = '9999', Email = 'b@b.com', ER_Language__c = 'FR', ER_To_sync_with_smarter__c = false);
  Boolean changed3 = APER17_Contact_Management.hasContactChanged(newC3, oldC);
  System.assertEquals(false, changed3, 'If ER_To_sync_with_smarter__c is false the method should return false.');
}
/* Test method added by harkirat to increase coverage ends*/
}