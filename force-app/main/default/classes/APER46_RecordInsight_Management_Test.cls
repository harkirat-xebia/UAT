/*
----------------------------------------------------------------------
-- - Name          : APER46_RecordInsight_Management_Test
-- - Author        : Harkirat Singh
-- - Description   : test class for APER46_RecordInsight_Management
--
--                   Custom metadata rows cannot be inserted by DML, so these
--                   tests build them in memory and assign the configOverride
--                   seam. testLiveConfigPathDoesNotThrow deliberately leaves the
--                   seam unset so the real SOQL in loadConfig() is still covered.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2026     Harkirat Singh       1.0         Initial version
----------------------------------------------------------------------
*/
@isTest
private class APER46_RecordInsight_Management_Test {
  private static final String CRN = 'TEST-CRN-0001';

  /*=================================================================
    FIXTURES
  =================================================================*/

  private static Lead buildLead(String email, String registrationNumber) {
    Lead lead = new Lead();
    lead.Salutation = 'Mr.';
    lead.FirstName = 'Insight';
    lead.LastName = 'Test';
    lead.Company = 'ER Insight Test';
    lead.Email = email;
    lead.ER_Registration_Number__c = registrationNumber;
    return lead;
  }

  private static Account buildAccount(String name, String registrationNumber) {
    return new Account(Name = name, ER_Registration_Number__c = registrationNumber);
  }

  private static CMER04_Record_Insight_Config__mdt fieldCheck(
    String developerName,
    String fieldApiName,
    String category
  ) {
    return new CMER04_Record_Insight_Config__mdt(
      DeveloperName = developerName,
      ER_Object_API_Name__c = 'Lead',
      ER_Insight_Type__c = 'Field_Check',
      ER_Field_API_Name__c = fieldApiName,
      ER_Category__c = category,
      ER_Active__c = true
    );
  }

  private static CMER04_Record_Insight_Config__mdt lookup(String developerName, String lookupObject) {
    return new CMER04_Record_Insight_Config__mdt(
      DeveloperName = developerName,
      ER_Object_API_Name__c = 'Lead',
      ER_Insight_Type__c = 'Duplicate_Lookup',
      ER_Field_API_Name__c = 'ER_Registration_Number__c',
      ER_Lookup_Object__c = lookupObject,
      ER_Lookup_Field__c = 'ER_Registration_Number__c',
      ER_Lookup_Display_Field__c = 'Name',
      ER_Action_Label__c = 'Account Found',
      ER_Category__c = 'Warning',
      ER_Active__c = true
    );
  }

  private static CMER04_Record_Insight_Config__mdt contactRoleCheck(String developerName, String roleValue) {
    return new CMER04_Record_Insight_Config__mdt(
      DeveloperName = developerName,
      ER_Object_API_Name__c = 'Opportunity',
      ER_Insight_Type__c = 'Related_Record_Check',
      ER_Lookup_Object__c = 'OpportunityContactRole',
      ER_Lookup_Field__c = 'OpportunityId',
      ER_Filter_Field__c = String.isBlank(roleValue) ? null : 'Role',
      ER_Filter_Value__c = roleValue,
      ER_Category__c = 'Required',
      ER_Message__c = 'Assign a Primary Contact role before creating a quote',
      ER_Active__c = true
    );
  }

  private static Opportunity buildOpportunity() {
    return new Opportunity(
      Name = 'Insight Test Opp',
      StageName = 'Qualification',
      CloseDate = Date.today().addDays(30)
    );
  }

  private static CMER04_Record_Insight_Config__mdt message(String developerName, String category, String text) {
    return new CMER04_Record_Insight_Config__mdt(
      DeveloperName = developerName,
      ER_Object_API_Name__c = 'Lead',
      ER_Insight_Type__c = 'Field_Check',
      ER_Category__c = category,
      ER_Message__c = text,
      ER_Active__c = true
    );
  }

  /*=================================================================
    FIELD CHECK
  =================================================================*/

  @isTest
  static void testRequiredFieldFilled() {
    Lead lead = buildLead('insight.test@example.com', null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      fieldCheck('Lead_Email', 'Email', 'Required')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals('Lead', result.objectApiName, 'Object should be resolved from the record Id');
    System.assertEquals(true, result.hasConfig, 'Config was supplied so hasConfig should be true');
    System.assertEquals(1, result.fields.size(), 'One field row expected');
    System.assertEquals(true, result.fields[0].isFilled, 'Email is populated so the row should be filled');
    System.assertEquals('Ok', result.fields[0].status, 'A populated field is Ok');
    System.assertEquals(0, result.missingRequiredCount, 'Nothing is missing');
    System.assertEquals('Email', result.fields[0].label, 'Label should come from the describe, not the API name');
    System.assertEquals('insight.test@example.com', result.fields[0].displayValue, 'Value should be returned');
  }

  @isTest
  static void testRequiredFieldEmptyIsFlagged() {
    Lead lead = buildLead(null, null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      fieldCheck('Lead_Email', 'Email', 'Required')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'One field row expected');
    System.assertEquals(false, result.fields[0].isFilled, 'Email is blank so the row should not be filled');
    System.assertEquals('Missing', result.fields[0].status, 'A blank field is Missing');
    System.assertEquals(1, result.missingRequiredCount, 'The blank required field should be counted');
  }

  @isTest
  static void testRecommendedCategory() {
    Lead lead = buildLead('recommended@example.com', null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      fieldCheck('Lead_Phone', 'Phone', 'Recommended')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'One field row expected');
    System.assertEquals('Recommended', result.fields[0].category, 'Category should be carried through');
    System.assertEquals(0, result.missingRequiredCount, 'A blank Recommended field is not counted as missing');
  }

  @isTest
  static void testWarningAndInfoGoToMessages() {
    Lead lead = buildLead('messages@example.com', null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      message('Lead_Warning', 'Warning', 'Check the billing address before converting'),
      message('Lead_Info', 'Info', 'Leads are archived after 90 days'),
      fieldCheck('Lead_Email', 'Email', 'Required')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(2, result.messages.size(), 'Both text rows belong in messages');
    System.assertEquals(1, result.fields.size(), 'Only the field row belongs in fields');
    System.assertEquals(
      'Check the billing address before converting',
      result.messages[0].message,
      'Message text should be preserved'
    );
    System.assertEquals('Warning', result.messages[0].category, 'Message category should be preserved');
  }

  /*=================================================================
    BAD CONFIGURATION MUST NEVER BREAK THE PAGE
  =================================================================*/

  @isTest
  static void testUnknownFieldSkippedNotFatal() {
    Lead lead = buildLead('unknown@example.com', null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      fieldCheck('Lead_Bogus', 'Zzz_Does_Not_Exist__c', 'Required'),
      fieldCheck('Lead_Email', 'Email', 'Required')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'The unknown field is skipped and the valid row still renders');
    System.assertEquals('Email', result.fields[0].label, 'The surviving row should be the valid one');
  }

  @isTest
  static void testInjectionShapedNameRejected() {
    Lead lead = buildLead('injection@example.com', null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      fieldCheck('Lead_Injection', 'Email FROM Lead WHERE Id != \'x', 'Required'),
      fieldCheck('Lead_Email', 'Email', 'Required')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'The injection-shaped name should be rejected by the shape gate');
  }

  @isTest
  static void testUnknownLookupObjectSkipped() {
    // Bypasses LeadTrigger: a populated CRN otherwise enqueues APBE01_LeadBelfirst's
    // future callout, which fires for real at Test.stopTest() with no mock set.
    UtilsBypass.setBypassedTriggersByApex(new Set<String>{ 'LeadTrigger' });
    Lead lead = buildLead('badlookup@example.com', CRN);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      lookup('Lead_Bad_Lookup', 'Zzz_Not_An_Object__c')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(0, result.fields.size(), 'An unresolvable lookup object should be skipped, not fatal');
  }

  /*=================================================================
    DUPLICATE LOOKUP
  =================================================================*/

  @isTest
  static void testDuplicateLookupFindsMatch() {
    Account existing = buildAccount('Existing Client SA', CRN);
    insert existing;

    // Bypasses LeadTrigger: a populated CRN otherwise enqueues APBE01_LeadBelfirst's
    // future callout, which fires for real at Test.stopTest() with no mock set.
    UtilsBypass.setBypassedTriggersByApex(new Set<String>{ 'LeadTrigger' });
    Lead lead = buildLead('dup@example.com', CRN);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      lookup('Lead_CRN_Account', 'Account')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'One lookup row expected');
    System.assertEquals(1, result.fields[0].matches.size(), 'The Account sharing the CRN should be found');
    System.assertEquals(existing.Id, result.fields[0].matches[0].recordId, 'The match should be the seeded Account');
    System.assertEquals('Existing Client SA', result.fields[0].matches[0].displayLabel, 'Display field should be Name');
    System.assertEquals(false, result.fields[0].isFilled, 'A duplicate found means the row is not clean');
    System.assertEquals(
      'Attention',
      result.fields[0].status,
      'A duplicate is Attention, not Missing - there is no gap to fill'
    );
    System.assertEquals('Account Found', result.fields[0].actionLabel, 'Action label should come from config');
  }

  /*@isTest
  static void testDuplicateLookupNoMatch() {
    // Bypasses LeadTrigger: a populated CRN otherwise enqueues APBE01_LeadBelfirst's
    // future callout, which fires for real at Test.stopTest() with no mock set.
    UtilsBypass.setBypassedTriggersByApex(new Set<String>{ 'LeadTrigger' });
    Lead lead = buildLead('nodup@example.com', 'CRN-WITH-NO-MATCH');
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      lookup('Lead_CRN_Account', 'Account')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'The row still renders so the user sees the check ran');
    System.assertEquals(0, result.fields[0].matches.size(), 'No Account shares this CRN');
    System.assertEquals(true, result.fields[0].isFilled, 'No duplicate means the row is clean');
    System.assertEquals('Ok', result.fields[0].status, 'No duplicate is Ok');
  }*/

  @isTest
  static void testDuplicateLookupMultipleMatches() {
    insert new List<Account>{ buildAccount('First Match SA', CRN), buildAccount('Second Match SA', CRN) };

    // Bypasses LeadTrigger: a populated CRN otherwise enqueues APBE01_LeadBelfirst's
    // future callout, which fires for real at Test.stopTest() with no mock set.
    UtilsBypass.setBypassedTriggersByApex(new Set<String>{ 'LeadTrigger' });
    Lead lead = buildLead('multi@example.com', CRN);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      lookup('Lead_CRN_Account', 'Account')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(2, result.fields[0].matches.size(), 'Both Accounts sharing the CRN should be returned');
  }

  @isTest
  static void testDuplicateLookupBlankSourceSkipped() {
    insert buildAccount('Should Not Be Found SA', CRN);

    Lead lead = buildLead('blank@example.com', null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      lookup('Lead_CRN_Account', 'Account')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(0, result.fields.size(), 'With no value to match on there is nothing to report');
  }

  /*=================================================================
    RELATED RECORD CHECK

    Polarity is the inverse of Duplicate_Lookup above: here a match is what we WANT,
    so zero children is the problem. These are the regression guard for that.
  =================================================================*/

  @isTest
  static void testRelatedRecordMissingWhenNoChildren() {
    Opportunity opp = buildOpportunity();
    insert opp;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      contactRoleCheck('Opportunity_Primary_Contact_Role', 'Primary Contact')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(opp.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'The row renders even with no children');
    System.assertEquals('Missing', result.fields[0].status, 'No contact role means the requirement is unmet');
    System.assertEquals(false, result.fields[0].isFilled, 'isFilled should agree with status');
    System.assertEquals(1, result.missingRequiredCount, 'A missing required related record should be counted');
  }

  @isTest
  static void testRelatedRecordOkWhenChildExists() {
    Opportunity opp = buildOpportunity();
    insert opp;

    Contact contact = new Contact(FirstName = 'Insight', LastName = 'Role Test');
    insert contact;
    insert new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contact.Id, Role = 'Primary Contact');

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      contactRoleCheck('Opportunity_Primary_Contact_Role', 'Primary Contact')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(opp.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'One related row expected');
    System.assertEquals('Ok', result.fields[0].status, 'A matching contact role satisfies the requirement');
    System.assertEquals(true, result.fields[0].isFilled, 'isFilled should agree with status');
    System.assertEquals(0, result.missingRequiredCount, 'Nothing is missing');
  }

  /*  The filter is the whole point: any contact role must not satisfy a Primary Contact row. */
  @isTest
  static void testRelatedRecordFilterNarrowsCorrectly() {
    Opportunity opp = buildOpportunity();
    insert opp;

    Contact contact = new Contact(FirstName = 'Wrong', LastName = 'Role Test');
    insert contact;
    insert new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contact.Id, Role = 'Delivering Contact');

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      contactRoleCheck('Opportunity_Primary_Contact_Role', 'Primary Contact')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(opp.Id);
    Test.stopTest();

    System.assertEquals('Missing', result.fields[0].status, 'A Delivering Contact must not satisfy a Primary Contact row');
  }

  /*  Blank filter field means "any child counts". */
  @isTest
  static void testRelatedRecordWithoutFilterCountsAnyChild() {
    Opportunity opp = buildOpportunity();
    insert opp;

    Contact contact = new Contact(FirstName = 'Any', LastName = 'Role Test');
    insert contact;
    insert new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contact.Id, Role = 'Delivering Contact');

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      contactRoleCheck('Opportunity_Any_Contact_Role', null)
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(opp.Id);
    Test.stopTest();

    System.assertEquals('Ok', result.fields[0].status, 'With no filter, any child record satisfies the row');
  }

  @isTest
  static void testRelatedRecordBadConfigSkippedNotFatal() {
    Opportunity opp = buildOpportunity();
    insert opp;

    CMER04_Record_Insight_Config__mdt badObject = contactRoleCheck('Bad_Object', 'Primary Contact');
    badObject.ER_Lookup_Object__c = 'Zzz_Not_An_Object__c';

    CMER04_Record_Insight_Config__mdt badFilter = contactRoleCheck('Bad_Filter', 'Primary Contact');
    badFilter.ER_Filter_Field__c = 'Zzz_Not_A_Field__c';

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      badObject,
      badFilter
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(opp.Id);
    Test.stopTest();

    System.assertEquals(0, result.fields.size(), 'Unresolvable lookup object or filter field is skipped, not fatal');
  }

  /*  A related row has a blank Field API Name AND a Message, which is exactly the shape
      of a message row. It must be classified by insight type, not by which fields are blank. */
  @isTest
  static void testRelatedRecordNotMistakenForMessageRow() {
    Opportunity opp = buildOpportunity();
    insert opp;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      contactRoleCheck('Opportunity_Primary_Contact_Role', 'Primary Contact')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(opp.Id);
    Test.stopTest();

    System.assertEquals(0, result.messages.size(), 'A related record check is not a message row');
    System.assertEquals(1, result.fields.size(), 'It belongs in fields');
  }

  /*=================================================================
    HELPERS AND EDGE CASES
  =================================================================*/

  @isTest
  static void testFilledSemantics() {
    System.assertEquals(false, APER46_RecordInsight_Management.isFilled(null), 'null is not filled');
    System.assertEquals(false, APER46_RecordInsight_Management.isFilled(''), 'empty string is not filled');
    System.assertEquals(false, APER46_RecordInsight_Management.isFilled('   '), 'whitespace only is not filled');
    System.assertEquals(false, APER46_RecordInsight_Management.isFilled(false), 'an unticked checkbox is not filled');
    System.assertEquals(true, APER46_RecordInsight_Management.isFilled(true), 'a ticked checkbox is filled');
    System.assertEquals(true, APER46_RecordInsight_Management.isFilled(0), 'zero is a legitimate value');
    System.assertEquals(true, APER46_RecordInsight_Management.isFilled('text'), 'text is filled');
    System.assertEquals(true, APER46_RecordInsight_Management.isFilled(Date.today()), 'a date is filled');
  }

  @isTest
  static void testDedupeRemovesRepeatedRows() {
    Lead lead = buildLead('dedupe@example.com', null);
    insert lead;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>{
      fieldCheck('Lead_Email_A', 'Email', 'Required'),
      fieldCheck('Lead_Email_B', 'Email', 'Required')
    };

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertEquals(1, result.fields.size(), 'Duplicate configuration rows should render the field only once');
  }

  @isTest
  static void testNullRecordId() {
    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(null);
    Test.stopTest();

    System.assertNotEquals(null, result, 'A null Id should still return a usable result');
    System.assertEquals(false, result.hasConfig, 'No config can be resolved without a record');
    System.assertEquals(0, result.fields.size(), 'No field rows expected');
    System.assertEquals(0, result.messages.size(), 'No messages expected');
  }

  @isTest
  static void testNoConfigForObject() {
    Account account = buildAccount('No Config SA', 'CRN-NO-CONFIG');
    insert account;

    APER46_RecordInsight_Management.configOverride = new List<CMER04_Record_Insight_Config__mdt>();

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(account.Id);
    Test.stopTest();

    System.assertEquals(false, result.hasConfig, 'An object with no configuration renders nothing');
  }

  /*  Leaves the seam unset on purpose so the real SOQL in loadConfig() is executed.
      Asserts only that it does not throw - the org's own configuration decides the rest. */
  @isTest
  static void testLiveConfigPathDoesNotThrow() {
    Lead lead = buildLead('live@example.com', null);
    insert lead;

    Test.startTest();
    APER46_RecordInsight_Management.InsightResult result = APER46_RecordInsight_Management.getInsights(lead.Id);
    Test.stopTest();

    System.assertNotEquals(null, result, 'The live configuration path should return a result');
    System.assertEquals('Lead', result.objectApiName, 'Object should still resolve from the record Id');
  }
}