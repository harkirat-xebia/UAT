@IsTest
public with sharing class APBE01_LeadBelfirst_Test {
  @isTest
  static void insertLead() {
    Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'System Administrator'];
    User u = new User(
      LastName = 'Selligent',
      Username = '1test@selligent.com',
      Email = '1test@selligent.com',
      Alias = 'sel',
      CommunityNickname = 'sel1test',
      TimeZoneSidKey = 'Europe/Brussels',
      LocaleSidKey = 'fr_BE',
      EmailEncodingKey = 'UTF-8',
      ProfileId = p.Id,
      LanguageLocaleKey = 'fr',
      ER_Business_Unit__c = 'BENELUX'
    );
    insert u;

    Id leadClientRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName()
      .get('Merchant Lead')
      .getRecordTypeId();
    Lead lead = new Lead();

    lead.LastName = 'NoTestSelligent';
    lead.ER_Enterprise_Number__c = '0436650646';
    lead.RecordTypeId = leadClientRecordTypeId;
    lead.ER_Store_Name__c = 'storeName';
    lead.ER_VAT_Number__c = 'GB773831408';

    insert lead;

    System.runAs(u) {
      Lead lead2 = new Lead();

      lead2.LastName = 'TestSelligent';
      lead2.ER_Enterprise_Number__c = '0436650646';
      lead2.RecordTypeId = leadClientRecordTypeId;
      lead2.ER_Store_Name__c = 'storeName';
      lead2.ER_VAT_Number__c = 'GB773831408';
      insert lead2;

      Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test.WSBE01_Belfirst_Test_CalloutLogin_Mock());
      Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test.WSBE01_Belfirst_Test_CalloutInfos_Mock());
      Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test.WSBE01_Belfirst_Test_CalloutData_Mock());
      APBE01_LeadBelfirst w = new APBE01_LeadBelfirst();

      // Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test.WSBE01_Belfirst_Test_CalloutLogin_Mock());
      // WSBE01_Belfirst w = new WSBE01_Belfirst();
      // Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test.WSBE01_Belfirst_Test_CalloutInfos_Mock());
      // w.setLanguage('fr_BE');
      // w.findByBVDId('BE0663563934');
      // Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test.WSBE01_Belfirst_Test_CalloutData_Mock());
      // Map<String, String> infos = w.getListData();
      // w.closeConnection();

      //                BE_Belfirst_WebserviceTest.initMock('BelfirstMock');
    }
  }
}