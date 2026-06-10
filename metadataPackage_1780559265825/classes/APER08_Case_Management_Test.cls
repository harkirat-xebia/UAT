/**
 * @author Oussama LASFAR
 * @date 26/09/2018 (dd/mm/yyyy)
 * @description test class to cover the case trigger before update
 */
@isTest
public class APER08_Case_Management_Test {
  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APER08', 'APER08', 'Local Admin', 'CEN');
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
      newContact.Accountid = newCompany.id;
      insert newContact;

      ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
      newEmployee.ER_Client__c = newCompany.id;
      insert newEmployee;

      Product2 newProduct = APER07_UtilityTestMethod.getProduct('TSC_P');
      insert newProduct;

      Asset newAsset = APER07_UtilityTestMethod.getAsset('2801001840', 'ER_Asset_Record_Type', Label.LAB_SF_ASSET_Type);
      newAsset.ER_Employee__c = newEmployee.id;
      newAsset.AccountId = newCompany.id;
      newAsset.Product2Id = newProduct.id;
      insert newAsset;

      Entitlement ent = new Entitlement();
      ent.Name = 'TestEntitlement';
      ent.AccountId = newCompany.id;
      List<SlaProcess> slaInst = [SELECT Id, name, isactive FROM SlaProcess LIMIT 1];
      if (!slaInst.isEmpty()) {
        ent.SlaProcessId = [SELECT Id, name, isactive FROM SlaProcess LIMIT 1].id;
      }
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
      testCase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('ER_Client_Case_RT')
        .getRecordTypeId();
      insert testCase;
    }

  }

  static testMethod void completeMilestone() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      List<Case> caseinst = [SELECT id, status FROM Case WHERE status = :'New' LIMIT 1];
      if (!caseinst.isEmpty()) {
        caseinst[0].Status = Label.LAB_SF_Case_resolved;
        update caseinst[0];
        caseinst[0].Status = Label.LAB_SF_Case_feedbackSent;
        update caseinst[0];
      }
    }
  }

  static testMethod void getEmployeeCaseOptions() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      List<Case> caseinst = [SELECT id, ER_Employee__c FROM Case LIMIT 1];
      if (!caseinst.isEmpty()) {
        APER08_Case_Management.GetEmployeeCaseOptions(caseinst[0].ER_Employee__c);
      }
    }
  }

  static testMethod void createNewCase() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      List<Asset> assetinst = [SELECT Id FROM Asset LIMIT 1];
      APER08_Case_Management.CreateCase('testReason', 'testDetailedReason', assetinst[0].Id);
    }
  }

  static testMethod void createNewIndividualCase() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      List<Account> accountinst = [SELECT Id FROM Account WHERE FirstName = 'NewIndividualName' LIMIT 1];
      APER08_Case_Management.CreateIndividualCase(accountinst[0].Id);
    }
  }

  static testMethod void UpdateMergedOwner() {
    Case caseinst2 = [SELECT Id FROM Case LIMIT 1];
    system.debug('###caseinst2 without asuser : ' + caseinst2);
    if (caseinst2 != null) {
      caseinst2.status = Constants.MERGED;
      update caseinst2;
    }
  }

  static testMethod void closeAsSpam() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      List<Case> caseinst = [SELECT Id FROM Case LIMIT 1];
      APER08_Case_Management.closeAsSpam(caseinst[0].Id);
      APER08_Case_Management.getListViews();
    }
  }
  // Daniel Sandu Code
  static testMethod void returnCasesWithOpenTasks() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      List<Case> caseinst = [SELECT id, ER_Employee__c FROM Case LIMIT 1];
      Set<Id> caseIds = new Set<Id>();
      caseIds.add(caseinst[0].Id);
      APER08_Case_Management.returnCasesWithOpenTasks(caseIds);
    }
  }
  static testMethod void manageCasesWithOpenTasks() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      List<Case> caseinst = [SELECT id, Status FROM Case LIMIT 1];
      Set<Id> caseIds = new Set<Id>();

      caseinst[0].Status = Label.LAB_SF_Case_resolved;
      update caseinst;

      Map<Id, Case> caseinst2 = new Map<Id, Case>();
      for (Case c : [SELECT id, Status FROM Case LIMIT 1]) {
        caseinst2.put(c.id, c);
        caseIds.add(c.Id);
      }

      List<Case> caseinst3 = APER08_Case_Management.returnCasesWithOpenTasks(caseIds);

      APER08_Case_Management.manageCasesWithOpenTasks(caseinst3, caseinst2);
    }
  }

  static testMethod void CaseMaventaClient() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      /*
      Group MaventaClientQueue = [
        SELECT Id
        FROM Group
        WHERE Type = :Label.LAB_SF_Group_Type_Queue limit 1
      ];
      */
      Account newCompany = APER07_UtilityTestMethod.getCompany('APER08_Case_Management_Test2');
      insert newCompany;
      Contact newContact = [SELECT id FROM Contact WHERE email = 'test@test.com' LIMIT 1];

      Case testCase = new Case();
      testCase.Origin = Label.LABS_SF_Case_Origin_Web;
      testCase.Status = Label.LAB_SF_Case_inProgress;
      testCase.ER_Reason__c = 'ER_Card';
      testCase.ER_CaseReason2__c = 'Balance enquiry';
      testCase.ER_BUPicklist__c = 'FI';
      testCase.AccountId = newCompany.Id;
      testCase.ContactId = newContact.Id;
      testCase.Description = 'Apex Test Case';
      testCase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('ER_Client_Case_RT')
        .getRecordTypeId();
      insert testCase;
      /*
      testCase.OwnerId = MaventaClientQueue.Id;
      update testCase;
      */
    }
  }

  static testMethod void caseFreezeResetMilestoneTest() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      Account newCompany = APER07_UtilityTestMethod.getCompany('APER08_Case_Management_Test3');
      insert newCompany;
      Contact newContact = [SELECT id FROM Contact WHERE email = 'test@test.com' LIMIT 1];

      Case testCase = new Case();
      testCase.Origin = Label.LABS_SF_Case_Origin_Web;
      testCase.Status = 'Pending';
      testCase.ER_Reason__c = 'ER_Card';
      testCase.ER_CaseReason2__c = 'Balance enquiry';
      testCase.ER_BUPicklist__c = 'FI';
      testCase.AccountId = newCompany.Id;
      testCase.ContactId = newContact.Id;
      testCase.Description = 'Apex Test Case';
      testCase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('ER_Merchant_Case_RT')
        .getRecordTypeId();
      insert testCase;
    }
  }

  @IsTest
  static void testSpamCaseES() {
    User ur = TestDataFactory.newUser('APER08Spam', 'APER08Spam', 'System Administrator', 'ES');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;
    System.runAs(ur) {
      Case cs = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs.Subject = 'Warning: could not send message for past 4 hours';
      cs.ER_BUPicklist__c = 'ES';
      cs.Status = 'New';
      cs.Priority = 'Medium';
      cs.Origin = 'Email';

      insert cs;
      List<Case> spam = [SELECT Id, Status FROM Case WHERE Id = :cs.Id];
      System.assertEquals('Spam', spam[0].Status);
    }
  }

  @IsTest
  static void testSpamCaseFI() {
    User ur = TestDataFactory.newUser('APER08Spam', 'APER08Spam', 'System Administrator', 'FI');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;
    System.runAs(ur) {
      Case cs = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs.Subject = 'Warning: could not send message for past 4 hours';
      cs.ER_BUPicklist__c = 'FI';
      cs.SuppliedName = 'New12';
      cs.Priority = 'Medium';
      cs.Origin = 'Email';

      insert cs;
      List<Case> spam = [SELECT Id, Status FROM Case WHERE Id = :cs.Id];
      System.assertEquals('Spam', spam[0].Status);
    }
  }

  @IsTest
  static void createMedalliaCases() {
    Account acct = APER36_TestDataFactory_Medallia.getAccount('Medalia Account');
    Contact con = APER36_TestDataFactory_Medallia.getContactWithAccount('Medallia', 'Contact', acct.Id);
    con.ER_med_pr_customer_type__c = 'Client';
    update con;

    Entitlement ent = new Entitlement();
    ent.Name = 'Test Medallia Entitlement';
    ent.AccountId = acct.id;
    ent.ER_Business_Unit__c = acct.ER_BUPicklist__c;
    List<SlaProcess> slaInst = [SELECT Id, name, isactive FROM SlaProcess LIMIT 1];
    if (!slaInst.isEmpty()) {
      ent.SlaProcessId = [SELECT Id, name, isactive FROM SlaProcess LIMIT 1].id;
    }
    insert ent;

    Case testClientCase = [SELECT id FROM Case WHERE RecordType.DeveloperName = 'ER_Client_Case_RT' LIMIT 1];

    
  }

  static testMethod void populateIndividualFieldBasedOnRTTest() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      Account newIndividual = APER07_UtilityTestMethod.getIndividual('Mr.', 'Test Person Account', 'Test');
      insert newIndividual;

      Case cs = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs.Subject = 'Test populateIndividualFieldBasedOnRTTest';
      cs.ER_BUPicklist__c = 'ES';
      cs.Status = 'New';
      cs.Priority = 'Medium';
      cs.Origin = 'Email';
      insert cs;
    }

    List<Case> caseList = [
      SELECT Id, ER_Individual__c, RecordTypeId, AccountId, ContactId
      FROM Case
      WHERE Subject = 'Test populateIndividualFieldBasedOnRTTest'
    ];

    Test.startTest();
    APER08_Case_Management.populateIndividualFieldBasedOnRT(caseList);
    Test.stopTest();
  }

  static testMethod void populateContactIdTest() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      Account newIndividual = APER07_UtilityTestMethod.getIndividual('Mr.', 'Test Person Account', 'Test');
      insert newIndividual;

      Case cs = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs.Subject = 'Test populateContactId';
      cs.Description = 'Test populateContactId';
      cs.ER_Individual__c = newIndividual.Id;
      cs.ER_BUPicklist__c = 'ES';
      cs.Status = 'New';
      cs.Priority = 'Medium';
      cs.Origin = 'Email';
      insert cs;
    }
  }
  static testMethod void UpdateTimeOpened() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      Case cs = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs.Subject = 'Test Update Time Opened';
      cs.ER_BUPicklist__c = 'ES';
      cs.Status = 'New';
      cs.Priority = 'Medium';
      cs.Origin = 'Email';

      insert cs;
      Case c = [SELECT Id FROM Case WHERE Subject = 'Test Update Time Opened' LIMIT 1];
      c.ER_BUPicklist__c = 'PL';
      update c;
    }
  }

  static testMethod void updateCaseSubject() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER08'];
    u.ER_bypassTrigger__c = true;
    update u;
    System.runAs(u) {
      Id AssetId = [SELECT Id FROM Asset WHERE Name = '2801001840'].Id;
      Case cs = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs.AssetId = AssetId;
      cs.ER_BUPicklist__c = 'ES';
      cs.Status = 'New';
      cs.Priority = 'Medium';
      cs.Origin = 'Email';
      cs.ER_Reason__c = 'ER_Card';
      cs.ER_CaseReason2__c = 'Balance enquiry';

      insert cs;

      Case cs1 = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs1.AssetId = AssetId;
      cs1.ER_BUPicklist__c = 'ES';
      cs1.Status = 'New';
      cs1.Priority = 'Medium';
      cs1.Origin = 'Email';
      cs1.ER_Reason__c = 'ER_Card';

      insert cs1;

      Case cs2 = APER07_UtilityTestMethod.getCase('ER_Merchant_Case_RT');
      cs2.ER_BUPicklist__c = 'ES';
      cs2.Status = 'New';
      cs2.Priority = 'Medium';
      cs2.Origin = 'Email';
      cs2.ER_Reason__c = 'ER_Card2';
      cs2.ER_CaseReason2__c = 'Balance enquiry2';

      insert cs2;
    }
    List<Case> caseList = [SELECT ID, Subject, AssetId, RecordTypeId, ER_Reason__c, ER_CaseReason2__c FROM Case];
    system.debug('stefania in test caseList => ' + caseList);
    Test.startTest();
    APER08_Case_Management.updateCaseSubject(caseList);
    Test.stopTest();
  }

  @IsTest
  static void updateBUEmailWebCasesTest() {
    User u = [SELECT Id, ER_Business_Unit__c FROM User WHERE LastName = 'APER08'];
    System.runAs(u) {
      Test.startTest();
      Case cs = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      cs.Subject = 'Test Update Time Opened';
      cs.Status = 'New';
      cs.Priority = 'Medium';
      cs.Origin = 'Email';

      insert cs;

      Case createdCase = [SELECT Id, ER_BUPicklist__c, OwnerId FROM Case WHERE Id = :cs.Id];
      String ownerPrefix = String.valueOf(createdCase.Id).substring(0, 3);
      System.assert(String.isNotBlank(createdCase.ER_BUPicklist__c), 'BU has not been updated');
      Test.stopTest();
    }
  }

  @IsTest
  static void updateEscalationFI_Tier1() {
    List<String> escalationRolesTier1 = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER1_QUEUE')
      ?.split(Constants.SEMICOLON);
    List<String> escalationRolesTier2 = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER2_ROLES')
      ?.split(Constants.SEMICOLON);
    List<String> escalationQueues = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER2_QUEUE')
      ?.split(Constants.SEMICOLON);

    User ur = TestDataFactory.newUser('APER08', 'APER08', 'System Administrator', 'FI');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      Case tier1 = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      tier1.Status = Constants.CASE_STATUS_ESCALATED;
      tier1.ERFI_Escalation_level__c = Constants.CASE_ESCALATION_LEVEL_TIER2;
      tier1.Subject = 'updateEscalationFI';
      insert tier1;

      //tier1.OwnerId = Utils.getQueueIdByName(escalationRolesTier1[0]);
      //update tier1;

      //tier1 = [SELECT Id, ERFI_Escalation_level__c FROM Case WHERE Id = :tier1.Id];

      //System.assertEquals(Constants.CASE_ESCALATION_LEVEL_TECHNICAL, tier1.ERFI_Escalation_level__c);
      Test.stopTest();
    }
  }

  @IsTest
  static void updateEscalationFI_Tier2() {
    List<String> escalationRolesTier1 = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER1_QUEUE')
      ?.split(Constants.SEMICOLON);
    List<String> escalationRolesTier2 = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER2_ROLES')
      ?.split(Constants.SEMICOLON);
    List<String> escalationQueues = Utils.getGlobalSettingsValueFromKey('CASE_FI_ESCALATION_TIER2_QUEUE')
      ?.split(Constants.SEMICOLON);

    User ur = TestDataFactory.newUser(
      'APER08_tier',
      'APER08_tier',
      'System Administrator',
      escalationRolesTier2[0],
      'FI'
    );
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      User u = [SELECT Id, ER_Business_Unit__c FROM User WHERE LastName = 'APER08'];

      Test.startTest();
      Case tier2 = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      tier2.Status = Constants.CASE_STATUS_ESCALATED;
      tier2.OwnerId = u.Id;
      tier2.Subject = 'updateEscalationFI';
      insert tier2;

      /*
      tier2.OwnerId = Utils.getQueueIdByName(escalationRolesTier1[0]);
      update tier2;

      tier2 = [SELECT Id, ERFI_Escalation_level__c FROM Case WHERE Id = :tier2.Id];

      System.assertEquals(Constants.CASE_ESCALATION_LEVEL_TIER2, tier2.ERFI_Escalation_level__c);
      */
      Test.stopTest();
    }
  }

  @IsTest
  static void updateEscalationCZ() {
    List<String> roles = Utils.getGlobalSettingsValueFromKey('CASE_CZ_ESCALATION_ROLES')?.split(Constants.SEMICOLON);

    User ur = TestDataFactory.newUser('APER08_tier', 'APER08_tier', 'System Administrator', roles[0], 'CZ');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      User u = [SELECT Id, ER_Business_Unit__c FROM User WHERE LastName = 'APER08'];

      Test.startTest();
      Case tier2 = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      tier2.Status = Constants.CASE_STATUS_ESCALATED;
      //tier2.OwnerId = u.Id;
      tier2.hasBeenEscalated__c = false;
      tier2.Subject = 'updateEscalationCZ';
      insert tier2;

      //tier2.OwnerId = Utils.getQueueIdByName(escalationRolesTier1[0]);
      //update tier2;

      tier2 = [SELECT Id, hasBeenEscalated__c FROM Case WHERE Id = :tier2.Id];

      System.assertEquals(true, tier2.hasBeenEscalated__c);
      Test.stopTest();
    }
  }

  @IsTest
  static void testUpdateAccountOnCase() {
    List<String> roles = Utils.getGlobalSettingsValueFromKey('CASE_CZ_ESCALATION_ROLES')?.split(Constants.SEMICOLON);

    User ur = [SELECT Id FROM User WHERE LastName = 'APER08'];

    System.runAs(ur) {
      Account a = APER07_UtilityTestMethod.getCompany('testUpdateAccountOnCase');
      insert a;

      Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'testUpdate', 'AccountOnCase');
      newContact.ER_Do_not_contact__c = true;
      newContact.AccountId = a.Id;
      insert newContact;

      Test.startTest();

      Case c = [SELECT Id FROM Case LIMIT 1];

      c.ContactId = newContact.Id;
      c.AccountId = null;

      update c;

      c = [SELECT Id, AccountId FROM Case WHERE Id = :c.Id];

      System.assertEquals(a.Id, c.AccountId);

      Test.stopTest();
    }
  }

 /* @IsTest
  static void testCaseAutoAssignmentFI() {
    User ur = TestDataFactory.newUser('APER08_tier', 'testCaseAutoAssignmentFI', 'System Administrator', 'FI');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();

      Case c = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      c.Status = Constants.CASE_STATUS_ESCALATED;
      c.SuppliedEmail = Utils.getGlobalSettingsValueFromKey('CASE_FI_AUTO_ASSIGNMENT_SUPPLIED_NAME')
        ?.split(Constants.SEMICOLON)[0];
      c.Subject = 'updateEscalationCZ';
      insert c;

      c = [SELECT Id, OwnerId FROM Case WHERE Id = :c.Id];
      System.assertEquals(c.OwnerId, Utils.getQueueIdByName(Constants.CASE_QUEUE_ERFI_AUTO_ASSIGNMENT));

      Test.stopTest();
    }
  }*/

  @IsTest
  static void testCloseRelatedCase() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER08'];

    System.runAs(ur) {
      Test.startTest();

      List<Case> parent = [SELECT Id, RecordTypeId FROM Case];

      Case c = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      c.Status = Constants.CASE_STATUS_NEW;
      c.Subject = 'testCloseRelatedCase';
      c.ParentId = parent[0].Id;
      c.RecordTypeId = parent[0].RecordTypeId;
      insert c;

      parent[0].Status = 'Closed';
      update parent[0];

      c = [SELECT Id, IsClosed FROM Case WHERE Id = :c.Id];
      System.assertEquals(c.IsClosed, true);

      Test.stopTest();
    }
  }

  @IsTest
  static void testCustomerSegment() {
    User ur = TestDataFactory.newUser('testSegmentClient', 'testSegmentClient', 'System Administrator', 'FI');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();

      //Client segment
      Case c = APER07_UtilityTestMethod.getCase(Constants.CASE_CLIENT_RT);
      c.Status = Constants.CASE_STATUS_NEW;
      c.Subject = 'testCloseRelatedCase';
      c.Origin = Constants.CASE_ORIGIN_EMAIL;
      //c.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERFI_CLIENT);
      insert c;
      c = [SELECT Id, ER_Customer_Segment__c FROM Case WHERE Id = :c.Id];
      //System.assertEquals(Constants.CASE_CUSTOMER_SEGMENT_CLIENT, c.ER_Customer_Segment__c);

      //Merchant segment
      Case c1 = APER07_UtilityTestMethod.getCase(Constants.CASE_MERCHANT_RT);
      c1.Status = Constants.CASE_STATUS_NEW;
      c1.Subject = 'testCloseRelatedCase';
      c1.Origin = Constants.CASE_ORIGIN_EMAIL;
      //c1.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERFI_MERCHANT);
      insert c1;
      c1 = [SELECT Id, ER_Customer_Segment__c FROM Case WHERE Id = :c1.Id];
      //System.assertEquals(Constants.CASE_CUSTOMER_SEGMENT_MERCHANT, c1.ER_Customer_Segment__c);

      //Merchant segment
      Case c2 = APER07_UtilityTestMethod.getCase(Constants.CASE_USER_RT);
      c2.Status = Constants.CASE_STATUS_NEW;
      c2.Subject = 'testCloseRelatedCase';
      c2.Origin = Constants.CASE_ORIGIN_EMAIL;
      //c2.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERFI_BENEFICIARY);
      insert c2;
      c2 = [SELECT Id, ER_Customer_Segment__c FROM Case WHERE Id = :c2.Id];
      //System.assertEquals(Constants.CASE_CUSTOMER_SEGMENT_BENEFICIARY, c2.ER_Customer_Segment__c);

      Test.stopTest();
      //Delicard segment
      Case c3 = APER07_UtilityTestMethod.getCase(Constants.CASE_USER_RT);
      c3.Status = Constants.CASE_STATUS_NEW;
      c3.Subject = 'testCloseRelatedCase';
      c3.Origin = Constants.CASE_ORIGIN_EMAIL;
      //c3.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERFI_DELICARD);
      insert c3;
      c3 = [SELECT Id, ER_Customer_Segment__c FROM Case WHERE Id = :c3.Id];
      //System.assertEquals(Constants.CASE_CUSTOMER_SEGMENT_DELICARD, c3.ER_Customer_Segment__c);

      //Robot failed
      Case c4 = APER07_UtilityTestMethod.getCase(Constants.CASE_USER_RT);
      c4.Status = Constants.CASE_STATUS_NEW;
      c4.Subject = 'testCloseRelatedCase';
      c4.Origin = Constants.CASE_ORIGIN_EMAIL;
      //c4.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERSK_ROBOT_FAILED);
      insert c4;
      c4 = [SELECT Id, ER_Reason__c, ER_CaseReason2__c FROM Case WHERE Id = :c4.Id];
      //System.assertEquals(Constants.CASE_REASON_ORDER_DELIVERY, c4.ER_Reason__c);
      //System.assertEquals(Constants.CASE_DETAILED_REASON_CARD_LOAD, c4.ER_CaseReason2__c);
    }
  }

  @IsTest
  static void testPriorityFI() {
    User ur = TestDataFactory.newUser('testPriorityFI', 'testPriorityFI', 'System Administrator', 'FI');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      Case c = APER07_UtilityTestMethod.getCase(Constants.CASE_CLIENT_RT);
      c.Status = Constants.CASE_STATUS_NEW;
      c.Subject = 'testCloseRelatedCase';
      c.Origin = Constants.CASE_ORIGIN_WEB;
      c.ER_BUPicklist__c = Constants.FI;
      //c.OwnerId = Utils.getQueueIdByName(Constants.CASE_QUEUE_ERFI_CLIENT);
      insert c;
      c = [SELECT Id, Priority FROM Case WHERE Id = :c.Id];
      //System.assertEquals(Constants.CASE_PRIORITY_LOW, c.Priority);
    }
  }

  @IsTest
  static void triggerAutoResponseTest() {
    User ur = TestDataFactory.newUser('FR', 'FR', 'ER Integration', 'FR');
    ur.ER_BypassVR__c = true;
    insert ur;

    System.runAs(ur) {
      Test.startTest();
      Case c = APER07_UtilityTestMethod.getCase(Constants.CASE_CLIENT_RT);
      c.Status = Constants.CASE_STATUS_NEW;
      c.Subject = 'test TriggerAutoResponseRule';
      c.Origin = Constants.CASE_ORIGIN_WEB;
      c.ER_BUPicklist__c = 'FR';
      insert c;
    }
  }

/*
  @IsTest
  static void testGenesysRoutingCaseGR() {
    User ur = TestDataFactory.newUser(
      'testGenesysRoutingCaseGR',
      'testGenesysRoutingCaseGR',
      'System Administrator',
      'GR'
    );
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;
    System.runAs(ur) {
      Case cs = APER07_UtilityTestMethod.getCase(Constants.CASE_CLIENT_RT);
      cs.Subject = 'testGenesysRoutingCaseGR';
      cs.ER_BUPicklist__c = 'GR';
      cs.SuppliedName = 'New12';
      cs.Priority = 'Medium';
      cs.Origin = 'Chat';

      insert cs;

      Group gr = [SELECT Id FROM Group WHERE DeveloperName = :Constants.GENESYS_GR_CHATBOT_QUEUE AND Type = 'Queue'];
      cs.OwnerId = gr.Id;
      update cs;
    }
  }
  */
}