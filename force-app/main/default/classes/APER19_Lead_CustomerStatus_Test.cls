/**
 * @description Tests for APER19_Lead_CustomerStatus.
 */
@IsTest
public class APER19_Lead_CustomerStatus_Test {
  private static final String CRN_EXISTING = 'CRN0000000001';
  private static final String CRN_DRAFT_ONLY = 'CRN0000000002';
  private static final String CRN_UNKNOWN = 'CRN0000000009';

  @TestSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APER19', 'APER19', 'System Administrator', 'ES');
    ur.ER_BypassVR__c = true;
    insert ur;

    System.runAs(ur) {
      Account withActiveContract = APER07_UtilityTestMethod.getCompany('APER19 Existing Customer');
      withActiveContract.ER_Registration_Number__c = CRN_EXISTING;

      Account withDraftContract = APER07_UtilityTestMethod.getCompany('APER19 Draft Only');
      withDraftContract.ER_Registration_Number__c = CRN_DRAFT_ONLY;

      insert new List<Account>{ withActiveContract, withDraftContract };

      Contract activated = APER07_UtilityTestMethod.getContract(
        withActiveContract.Id,
        System.today(),
        Constants.DRAFT,
        null
      );
      Contract draft = APER07_UtilityTestMethod.getContract(withDraftContract.Id, System.today(), Constants.DRAFT, null);
      insert new List<Contract>{ activated, draft };

      // Contract.Status cannot be set to Activated on insert.
      activated.Status = Constants.ACTIVATED;
      update activated;
    }
  }

  private static User getRunningUser() {
    return [SELECT Id FROM User WHERE LastName = 'APER19' LIMIT 1];
  }

  private static Integer leadCounter = 0;

  // getLead() derives its unique values from the current timestamp, which collides inside a loop.
  private static Lead buildLead(String crn) {
    Test.setMock(HttpCalloutMock.class, new GenesysCloudAPIMock());
    Lead l = APER07_UtilityTestMethod.getLead(
      Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT)
    );
    String suffix = String.valueOf(leadCounter++);
    l.LastName += suffix;
    l.Company += suffix;
    l.ER_Store_Name__c += suffix;
    l.ER_VAT_Number__c += suffix;
    l.ER_MID_Clearing__c += suffix;
    l.ER_Sub_MID_Clearing__c += suffix;
    l.Email = 'aper19.lead' + suffix + '@salesforce.com';
    l.ER_Registration_Number__c = crn;
    return l;
  }

  @IsTest
  static void testAccountWithActivatedContractIsExistingCustomer() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead(CRN_EXISTING);

      Test.startTest();
      insert l;
      Test.stopTest();

      Lead inserted = [SELECT customer_status__c, Lead_motion__c FROM Lead WHERE Id = :l.Id];
      Assert.areEqual(
        Constants.LEAD_CUSTOMER_STATUS_EXISTING,
        inserted.customer_status__c,
        'An account holding an activated contract must classify the lead as an existing customer'
      );
      Assert.areEqual(
        Constants.LEAD_MOTION_CROSS_SELLING,
        inserted.Lead_motion__c,
        'A blank motion must be pre-filled with Cross Selling for an existing customer'
      );
    }
  }

  @IsTest
  static void testAccountWithOnlyDraftContractIsProspect() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead(CRN_DRAFT_ONLY);

      Test.startTest();
      insert l;
      Test.stopTest();

      Lead inserted = [SELECT customer_status__c, Lead_motion__c FROM Lead WHERE Id = :l.Id];
      Assert.areEqual(
        Constants.LEAD_CUSTOMER_STATUS_PROSPECT,
        inserted.customer_status__c,
        'A draft contract must not qualify the lead as an existing customer'
      );
      Assert.isNull(inserted.Lead_motion__c, 'Motion must stay blank for a prospect');
    }
  }

  @IsTest
  static void testUnknownRegistrationNumberIsProspect() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead(CRN_UNKNOWN);

      Test.startTest();
      insert l;
      Test.stopTest();

      Lead inserted = [SELECT customer_status__c FROM Lead WHERE Id = :l.Id];
      Assert.areEqual(
        Constants.LEAD_CUSTOMER_STATUS_PROSPECT,
        inserted.customer_status__c,
        'A registration number matching no account must classify the lead as a prospect'
      );
    }
  }

  @IsTest
  static void testBlankRegistrationNumberIsProspect() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead('   ');

      Test.startTest();
      insert l;
      Test.stopTest();

      Lead inserted = [SELECT customer_status__c FROM Lead WHERE Id = :l.Id];
      Assert.areEqual(
        Constants.LEAD_CUSTOMER_STATUS_PROSPECT,
        inserted.customer_status__c,
        'A lead without a registration number must classify as a prospect'
      );
    }
  }

  @IsTest
  static void testRegistrationNumberIsTrimmedBeforeMatching() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead('  ' + CRN_EXISTING + '  ');

      Test.startTest();
      insert l;
      Test.stopTest();

      Lead inserted = [SELECT customer_status__c FROM Lead WHERE Id = :l.Id];
      Assert.areEqual(
        Constants.LEAD_CUSTOMER_STATUS_EXISTING,
        inserted.customer_status__c,
        'Surrounding whitespace must not break the registration number match'
      );
    }
  }

  @IsTest
  static void testManualMotionIsNotOverwritten() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead(CRN_EXISTING);
      l.Lead_motion__c = 'Renegotiation';

      Test.startTest();
      insert l;
      Test.stopTest();

      Lead inserted = [SELECT customer_status__c, Lead_motion__c FROM Lead WHERE Id = :l.Id];
      Assert.areEqual(
        Constants.LEAD_CUSTOMER_STATUS_EXISTING,
        inserted.customer_status__c,
        'Status must still be computed when a motion was chosen manually'
      );
      Assert.areEqual('Renegotiation', inserted.Lead_motion__c, 'A manually chosen motion must be preserved');
    }
  }

  @IsTest
  static void testLeadsSharingRegistrationNumberAreAllClassified() {
    System.runAs(getRunningUser()) {
      List<Lead> leads = new List<Lead>{ buildLead(CRN_EXISTING), buildLead(CRN_EXISTING) };

      Test.startTest();
      insert leads;
      Test.stopTest();

      for (Lead inserted : [SELECT customer_status__c FROM Lead WHERE Id IN :leads]) {
        Assert.areEqual(
          Constants.LEAD_CUSTOMER_STATUS_EXISTING,
          inserted.customer_status__c,
          'Every lead sharing a registration number must be classified'
        );
      }
    }
  }

  @IsTest
  static void testStatusIsRecalculatedWhenRegistrationNumberChanges() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead(CRN_UNKNOWN);
      insert l;

      Test.startTest();
      l.ER_Registration_Number__c = CRN_EXISTING;
      update l;
      Test.stopTest();

      Lead updated = [SELECT customer_status__c, Lead_motion__c FROM Lead WHERE Id = :l.Id];
      Assert.areEqual(
        Constants.LEAD_CUSTOMER_STATUS_EXISTING,
        updated.customer_status__c,
        'Changing the registration number must re-evaluate the customer status'
      );
      Assert.areEqual(
        Constants.LEAD_MOTION_CROSS_SELLING,
        updated.Lead_motion__c,
        'Motion must be pre-filled once the lead resolves to an existing customer'
      );
    }
  }

  @IsTest
  static void testUnrelatedUpdateIssuesNoQuery() {
    System.runAs(getRunningUser()) {
      Lead l = buildLead(CRN_EXISTING);
      insert l;

      List<Lead> leads = [
        SELECT Id, ER_BUPicklist__c, ER_Registration_Number__c, Lead_motion__c, customer_status__c
        FROM Lead
        WHERE Id = :l.Id
      ];
      leads[0].City = 'Brussels';
      Map<Id, SObject> oldItems = new Map<Id, SObject>{ l.Id => l };

      Test.startTest();
      Integer queriesBefore = Limits.getQueries();
      APER19_Lead_CustomerStatus.evaluateCustomerStatusAndMotion(leads, oldItems);
      Assert.areEqual(
        queriesBefore,
        Limits.getQueries(),
        'No query must be issued when the registration number is unchanged'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void testBulkInsertIssuesASingleQuery() {
    System.runAs(getRunningUser()) {
      List<Lead> leads = new List<Lead>();
      for (Integer i = 0; i < 200; i++) {
        leads.add(buildLead(Math.mod(i, 2) == 0 ? CRN_EXISTING : CRN_DRAFT_ONLY));
      }

      UtilsBypass.getCurrentUser();
      Test.startTest();
      Integer queriesBefore = Limits.getQueries();
      APER19_Lead_CustomerStatus.evaluateCustomerStatusAndMotion(leads, null);
      Assert.areEqual(
        queriesBefore + 1,
        Limits.getQueries(),
        'The service must issue exactly one query whatever the batch size'
      );
      Test.stopTest();

      Integer existingCount = 0;
      for (Lead l : leads) {
        if (l.customer_status__c == Constants.LEAD_CUSTOMER_STATUS_EXISTING)
          existingCount++;
      }
      Assert.areEqual(100, existingCount, 'Half of the bulk leads must resolve to an existing customer');
    }
  }
}