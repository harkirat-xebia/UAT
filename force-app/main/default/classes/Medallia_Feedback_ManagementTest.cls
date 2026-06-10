@IsTest
private class Medallia_Feedback_ManagementTest {
  /*@testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APER08', 'APER08', 'ER Integration', 'CEN');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      Account newCompany = APER07_UtilityTestMethod.getCompany('APER08_Case_Management_Test');
      insert newCompany;

      Account newIndividual = APER07_UtilityTestMethod.getIndividual('Mr.', 'NewIndividualName', 'Test');
      newIndividual.ER_Do_not_contact__pc = true;
      insert newIndividual;

      Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test', 'Case');
      newContact.ER_Do_not_contact__c = true;
      insert newContact;

      ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
      newEmployee.ER_Client__c = newCompany.Id;
      insert newEmployee;

      Product2 newProduct = APER07_UtilityTestMethod.getProduct('TSC_P');
      insert newProduct;

      Asset newAsset = APER07_UtilityTestMethod.getAsset('2801001840', 'ER_Asset_Record_Type', Label.LAB_SF_ASSET_Type);
      newAsset.ER_Employee__c = newEmployee.Id;
      newAsset.AccountId = newCompany.Id;
      newAsset.Product2Id = newProduct.Id;
      insert newAsset;

      Entitlement ent = new Entitlement();
      ent.Name = 'TestEntitlement';
      ent.AccountId = newCompany.Id;
      List<SlaProcess> slaInst = [SELECT Id, Name, IsActive FROM SlaProcess LIMIT 1];
      if (!slaInst.isEmpty())
        ent.SlaProcessId = [SELECT Id, Name, IsActive FROM SlaProcess LIMIT 1].Id;
      insert ent;

      Case testCase = new Case();
      testCase.Origin = Label.LABS_SF_Case_Origin_Web;
      testCase.Status = Label.LAB_SF_Case_inProgress;
      testCase.ER_Reason__c = 'ER_Card';
      testCase.ER_CaseReason2__c = 'Balance enquiry';
      testCase.ER_BUPicklist__c = 'ES';
      testCase.ER_Card_Number__c = '2801001840';
      testCase.ER_Employee__c = newEmployee.Id;
      testCase.AccountId = newCompany.Id;
      testCase.ContactId = newContact.Id;
      testCase.Description = 'Apex Test Case';
      testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('ER_Client_Case_RT')
        .getRecordTypeId();
      insert testCase;
    }

  }

  @IsTest
  static void testcreateMedalliaCases() {
    Account acct = APER36_TestDataFactory_Medallia.getAccount('Medalia Account');
    Contact con = APER36_TestDataFactory_Medallia.getContactWithAccount('Medallia', 'Contact', acct.Id);
    con.ER_med_pr_customer_type__c = 'Client';
    update con;

    Entitlement ent = new Entitlement();
    ent.Name = 'Test Medallia Entitlement';
    ent.AccountId = acct.Id;
    ent.ER_Business_Unit__c = acct.ER_BUPicklist__c;
    List<SlaProcess> slaInst = [SELECT Id, Name, IsActive FROM SlaProcess LIMIT 1];
    if (!slaInst.isEmpty()) {
      ent.SlaProcessId = [SELECT Id, Name, IsActive FROM SlaProcess LIMIT 1].Id;
    }
    insert ent;

    Case testClientCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'ER_Client_Case_RT' LIMIT 1];

    List<medallia_xm__Invitation__c> invitationsList = new List<medallia_xm__Invitation__c>();
    List<medallia_xm__Medallia_Feedback_Header__c> fHeaderList = new List<medallia_xm__Medallia_Feedback_Header__c>();
    List<medallia_xm__Medallia_Feedback__c> feedbacksList = new List<medallia_xm__Medallia_Feedback__c>();

    medallia_xm__Invitation__c mInvitation1 = new medallia_xm__Invitation__c(
      medallia_xm__Medallia_Service__c = Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_CASE_CLOSED_SURVEY),
      medallia_xm__Account__c = acct.Id
    );
    invitationsList.add(mInvitation1);
    medallia_xm__Invitation__c mInvitation2 = new medallia_xm__Invitation__c(
      medallia_xm__Medallia_Service__c = Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_PULSE_SURVEY),
      medallia_xm__Account__c = acct.Id,
      medallia_xm__Contact__c = con.Id
    );
    invitationsList.add(mInvitation2);

    insert invitationsList;

    medallia_xm__Medallia_Feedback_Header__c mFeedbackHeader1 = new medallia_xm__Medallia_Feedback_Header__c(
      medallia_xm__Account__c = acct.Id
    );
    fHeaderList.add(mFeedbackHeader1);
    medallia_xm__Medallia_Feedback_Header__c mFeedbackHeader2 = new medallia_xm__Medallia_Feedback_Header__c(
      medallia_xm__Account__c = acct.Id
    );
    fHeaderList.add(mFeedbackHeader2);
    insert fHeaderList;

    medallia_xm__Medallia_Feedback__c mFeedback1 = new medallia_xm__Medallia_Feedback__c(
      medallia_xm__Medallia_Feedback_Header__c = fHeaderList[0].Id,
      Name = 'Test Response 1',
      medallia_xm__Contact_Id__c = con.Id,
      medallia_xm__Alert_Yn_Flag__c = 'Yes',
      medallia_xm__Account_Id__c = acct.Id,
      medallia_xm__Alert_Type__c = 'Mid Detractor',
      medallia_xm__Invitation__c = invitationsList[0].Id,
      medallia_xm__Original_case_Number__c = testClientCase.Id
    );
    feedbacksList.add(mFeedback1);

    medallia_xm__Medallia_Feedback__c mFeedback2 = new medallia_xm__Medallia_Feedback__c(
      medallia_xm__Medallia_Feedback_Header__c = fHeaderList[1].Id,
      Name = 'Test Response 2',
      medallia_xm__Contact_Id__c = con.Id,
      medallia_xm__Alert_Yn_Flag__c = 'Yes',
      medallia_xm__Account_Id__c = acct.Id,
      medallia_xm__Alert_Type__c = 'Extreme Detractor',
      medallia_xm__Invitation__c = invitationsList[1].Id
    );
    feedbacksList.add(mFeedback2);

    insert feedbacksList;
  }

  @IsTest
  static void testFillInIndividualLookup() {
    List<User> ur = [
      SELECT Id
      FROM User
      WHERE
        FirstName LIKE 'APER08%'
        AND LastName LIKE 'APER08%'
        AND ER_Business_Unit__c = 'CEN'
        AND Profile.Name = 'ER Integration'
      LIMIT 1
    ];

    System.runAs(ur[0]) {
      //Account acc = APER07_UtilityTestMethod.getCompany('Account' + String.valueOf(Datetime.now().getTime()));
      //insert acc;

      Account newIndividual = APER07_UtilityTestMethod.getIndividual(
        'Mr.',
        'FirstName' + String.valueOf(Datetime.now().getTime()),
        'LastName' + String.valueOf(Datetime.now().getTime())
      );
      newIndividual.ER_Do_not_contact__pc = true;
      insert newIndividual;

      List<Contact> contacts = [SELECT Id FROM Contact WHERE IsPersonAccount = TRUE AND AccountId = :newIndividual.Id];
      System.assert(!contacts.isEmpty(), 'No Person Account found');

      Case testClientCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'ER_Client_Case_RT' LIMIT 1];

      Test.startTest();
      medallia_xm__Medallia_Feedback_Header__c fh = new medallia_xm__Medallia_Feedback_Header__c(
        medallia_xm__Account__c = newIndividual.Id
      );

      medallia_xm__Invitation__c invit = new medallia_xm__Invitation__c(
        medallia_xm__Medallia_Service__c = Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_CASE_CLOSED_SURVEY),
        medallia_xm__Account__c = newIndividual.Id
      );
      insert invit;

      medallia_xm__Medallia_Feedback__c fb = new medallia_xm__Medallia_Feedback__c(
        medallia_xm__Medallia_Feedback_Header__c = fh.Id,
        Name = 'Response' + String.valueOf(Datetime.now().getTime()),
        medallia_xm__Contact_Id__c = contacts[0].Id,
        medallia_xm__Alert_Yn_Flag__c = 'Yes',
        medallia_xm__Account_Id__c = newIndividual.Id,
        medallia_xm__Alert_Type__c = 'Mid Detractor',
        medallia_xm__Invitation__c = invit.Id,
        medallia_xm__Original_case_Number__c = testClientCase.Id
      );
      insert fb;

      medallia_xm__Medallia_Feedback__c insertedFeedback = [
        SELECT Id, ER_Individual_Id__c
        FROM medallia_xm__Medallia_Feedback__c
        WHERE Id = :fb.Id
      ];
      System.assert(insertedFeedback.ER_Individual_Id__c != null, 'The individual lookup is empty');
      Test.stopTest();
    }
  }*/
}