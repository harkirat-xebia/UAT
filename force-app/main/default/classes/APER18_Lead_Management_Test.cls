/**
 * Created by noorgoolamnabee on 14/12/2021.
 */

@IsTest
public class APER18_Lead_Management_Test {
  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APER18', 'APER18', 'Local Admin', 'ES');
    ur.ER_BypassVR__c = true;
    insert ur;

    System.runAs(ur) {
      Account a = APER07_UtilityTestMethod.getCompany('Test');
      insert a;
      ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter(
        'Test',
        a.id,
        'Merchant',
        'Test',
        'Test',
        '3000',
        'Spain'
      );
      insert fc;

      ER_Store__c store = APER07_UtilityTestMethod.getStore(
        'TEST',
        a.Id,
        fc.Id,
        System.today(),
        'test',
        'test',
        'test',
        'test'
      );
      insert store;

      ER_Acceptor__c acceptor = APER07_UtilityTestMethod.getAcceptor(store.Id);
      insert acceptor;

      ER_Promo_Code__c promo = new ER_Promo_Code__c();
      promo.Name = 'TestPromo';
      promo.ER_Business_Unit__c = 'BE';
      promo.ER_Start_Date__c = Date.today().addDays(-5);
      promo.ER_Promo_Code__c = 'TestPromo';
      promo.ER_Status__c = 'Activated';
      insert promo;

      Lead ld = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
      );
      ld.ER_Promo_Code__c = 'TestPromo';
      ld.ER_Employee_Size_Range__c = '12 - 30';
      insert ld;
    }
  }

  @IsTest
  static void testConvertedLead() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER18'];
    System.runAs(u) {
      Test.startTest();

      Lead ld = [SELECT Id FROM Lead LIMIT 1];

      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(ld.Id);

      LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
      lc.setConvertedStatus(convertStatus.MasterLabel);

      Database.LeadConvertResult lcr = Database.convertLead(lc);

      Test.stopTest();

      // Check the results (assert)
      System.assert(lcr.isSuccess());

      Lead convertedLead = [SELECT Id, ConvertedAccountId FROM Lead LIMIT 1];

      List<ER_Financial_Center__c> result = [
        SELECT Id
        FROM ER_Financial_Center__c
        WHERE ER_Account_Name__c = :convertedLead.ConvertedAccountId
      ];
      System.assertEquals(1, result.size(), 'the related financial center had been successfully created');

      List<ER_Store__c> result1 = [
        SELECT Id, ER_Financial_Center__c
        FROM ER_Store__c
        WHERE ER_Merchant__c = :convertedLead.ConvertedAccountId
      ];
      System.assertEquals(1, result1.size(), 'the related store had been successfully created');
    }
  }

  static testMethod void testUnmatchTransactionAfterUpdate() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER18'];
    System.runAs(u) {
      Test.startTest();

      Lead ld = [SELECT Id FROM Lead LIMIT 1];

      ld.ER_MID_Clearing__c = '220';
      update ld;

      ld.ER_Sub_MID_Clearing__c = '221';
      update ld;

      ld.Status = Label.LABS_SF_Status_Lead_Excluded;
      ld.ER_Rejected_Reason__c = Label.LAB_SF_Lead_Rejected_Interest;
      update ld;
      Test.stopTest();
    }
  }

  static testMethod void testEmployeeRange() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER18'];
    u.ER_Bypass_Duplication_Rule__c = true;
    update u;
    System.runAs(u) {
      Test.startTest();

      Lead ld = [SELECT Id, NumberOfEmployees FROM Lead WHERE ER_Employee_Size_Range__c != ''];
      System.assert(ld.NumberOfEmployees == 12);

      ld.ER_Employee_Size_Range__c = 'Unit�s non employeuses';
      ld.NumberOfEmployees = null;
      update ld;
      Lead updatedLead = [SELECT Id, NumberOfEmployees FROM Lead WHERE Id =: ld.Id];
      System.assert(updatedLead.NumberOfEmployees == null);

      ld.ER_Employee_Size_Range__c = '12 - 30';
      ld.NumberOfEmployees = 45;
      update ld;
      updatedLead = [SELECT Id, NumberOfEmployees FROM Lead WHERE Id =: ld.Id];
      System.assert(updatedLead.NumberOfEmployees == 45);

      Test.stopTest();
    }
  }

  static testMethod void testAssignementRule() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER18'];
    System.runAs(u) {
      Test.startTest();

      Lead ld = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
      );
      ld.ER_Promo_Code__c = 'TestPromo';
      ld.LeadSource = Label.LAB_SF_Lead_Source_Unmatched;
      ld.ER_Lead_Channel__c = Label.LAB_SF_Lead_Channel_Auto;
      ld.ER_BUPicklist__c = 'BE';

      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;

      Database.insert(ld, dml);
      Test.stopTest();
    }
  }

  @IsTest
  static void testConvertedClientLead() {
    Test.setMock(HttpCalloutMock.class, new SmarterAPIMock());
    Test.startTest();
    Lead ld = APER07_UtilityTestMethod.getLead(
      Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT')
    );
    ld.City = 'Paris';
    ld.NumberOfEmployees = 65;
    ld.ER_Registration_Number__c = '32773318400516';
    ld.LeadSource = 'Websales';
    ld.ER_Lead_sub_source__c = 'Econtratonline';
    ld.ER_Legal_Name__c = 'Legal Name';
    ld.ER_Legal_Street__c = 'Legal Street';
    ld.ER_Legal_Zip_Code__c = '75017';
    ld.ER_Legal_City__c = 'Paris';
    insert ld;
    Database.LeadConvert lc = new database.LeadConvert();
    lc.setLeadId(ld.Id);

    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
    lc.setConvertedStatus(convertStatus.MasterLabel);

    Database.LeadConvertResult lcr = Database.convertLead(lc);
    Test.stopTest();
  }

  @IsTest
  static void convertLeads() {
    User u = TestDataFactory.newUser('FirstName', 'LastName', 'ER Zuora Sales', 'FR');
    System.runAs(u) {
      String emailAddress = Datetime.now().getTime() + '@edenred' + Datetime.now().getTime() + '.com';
      String crn = '32773318400516';
      Lead l = new Lead();
      l.ER_To_Be_Converted__c = true;
      l.ER_SmartER_Context__c = true;
      l.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT');
      l.Salutation = 'Mr.';
      l.LastName = 'SmartLN' + Datetime.now().getTime();
      l.FirstName = 'SmartFN' + Datetime.now().getTime();
      l.ER_Registration_Number__c = crn;
      l.Company = 'Smart ' + Datetime.now().getTime();
      l.Email = emailAddress;
      l.Street = 'rue de smart';
      l.City = 'Paris';
      l.PostalCode = '75017';
      l.ER_Country_Code__c = 'FR';
      l.Country = 'France';
      l.ER_Language__c = 'FR';
      l.ER_BUPicklist__c = 'BE';
      l.ER_VAT_Number__c = 'FR95327733184';
      l.NumberOfEmployees = 32;
      l.ER_Legal_Name__c = 'Legal Name';
      l.ER_Legal_Street__c = 'rue de smart';
      l.ER_Legal_Zip_Code__c = '75017';
      l.ER_Legal_City__c = 'Paris';
      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      Test.setMock(HttpCalloutMock.class, smarterMock);

      insert l;
      Test.stopTest();
    }
  }

  @IsTest
  static void checkExistingLeads() {
    User u = TestDataFactory.newUser('FirstName', 'LastName', 'ER Zuora Sales', 'FR');

    System.runAs(u) {
      List<Lead> leads = new List<Lead>();
      String emailAddress = Datetime.now().getTime() + '@edenred' + Datetime.now().getTime() + '.com';
      String crn = '32773318400516';
      Lead l = new Lead();
      l.ER_SmartER_Context__c = false;
      l.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT');
      l.Salutation = 'Mr.';
      l.LastName = 'SmartLN' + Datetime.now().getTime();
      l.FirstName = 'SmartFN' + Datetime.now().getTime();
      l.ER_Registration_Number__c = crn;
      l.Company = 'Smart ' + Datetime.now().getTime();
      l.Email = emailAddress;
      l.Street = 'rue de smart';
      l.City = 'Paris';
      l.PostalCode = '75017';
      l.ER_Language__c = 'FR';
      l.ER_BUPicklist__c = 'BE';
      l.ER_VAT_Number__c = 'FR95327733184';
      l.ER_Legal_Name__c = 'Legal Name';
      l.ER_Legal_Street__c = 'rue de smart';
      l.ER_Legal_Zip_Code__c = '75017';
      l.ER_Legal_City__c = 'Paris';
      //leads.add(l);
      insert l;

      Lead l1 = new Lead();
      l1.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT');
      l1.ER_SmartER_Context__c = true;
      l1.ER_VAT_Number__c = 'FR95327733184';
      l1.Salutation = 'Mr.';
      l1.LastName = 'other name' + Datetime.now().getTime();
      l1.FirstName = 'other name' + Datetime.now().getTime();
      l1.Company = 'other company  ' + Datetime.now().getTime();
      l1.Email = emailAddress;
      l1.Street = 'Rue de street';
      l1.City = 'Paris';
      l1.PostalCode = '75009';
      l1.ER_Language__c = 'FR';
      l1.ER_BUPicklist__c = 'BE';
      l1.ER_Registration_Number__c = crn;
      l1.ER_Legal_Name__c = 'Legal Name';
      l1.ER_Legal_Street__c = 'Rue de street';
      l1.ER_Legal_Zip_Code__c = '75009';
      l1.ER_Legal_City__c = 'Paris';
      leads.add(l1);
      insert leads;

      Lead l2 = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT')
      );
      l2.ER_SmartER_Context__c = true;
      l2.Salutation = 'Mr.';
      l2.LastName = 'some name' + Datetime.now().getTime();
      l2.FirstName = 'some name' + Datetime.now().getTime();
      l2.Company = 'company ' + Datetime.now().getTime();
      l2.Email = emailAddress;
      l2.ER_Registration_Number__c = crn;
      l2.Street = 'Rue de Paris';
      l2.City = 'Paris';
      l2.PostalCode = '75002';
      l2.ER_Language__c = 'FR';
      l2.ER_BUPicklist__c = 'BE';
      l2.ER_VAT_Number__c = 'FR95327733184';
      l2.ER_Legal_Name__c = 'Legal Name';
      l2.ER_Legal_Street__c = 'Rue de Paris';
      l2.ER_Legal_Zip_Code__c = '75002';
      l2.ER_Legal_City__c = 'Paris';
      insert l2;
    }
  }

  @IsTest
  static void linkLeadToExistingContact() {
    User u = TestDataFactory.newUser('FirstName', 'LastName', 'ER Zuora Sales', 'FR');

    System.runAs(u) {
      String emailAddress = Datetime.now().getTime() + '@edenred.com';
      String crn = '32773318400516';
      String vat = 'FR95327733184';

      Account a = APER07_UtilityTestMethod.getCompany('Smart' + crn);
      a.ER_Match_Legal_Address__c = true;
      a.ER_VAT_Number__c = vat;
      a.ER_Registration_Number__c = crn;
      a.BillingStreet = 'Road Street';
      a.BillingCity = 'Paris';
      a.BillingPostalCode = '1095';
      a.ER_Country_Code__c = 'FR';
      a.ER_BUPicklist__c = 'BE';
      a.ER_VAT_Number__c = vat;
      insert a;

      Contact c = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'FirstName', 'LastName');
      c.FirstName = 'FirstName' + Datetime.now().getTime();
      c.LastName = 'LastName' + Datetime.now().getTime();
      c.ER_BUPicklist__c = 'BE';
      c.AccountId = a.Id;
      c.Email = emailAddress;
      insert c;

      List<Lead> leads = new List<Lead>();
      Lead l = new Lead();
      l.ER_SmartER_Context__c = true;
      l.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT');
      l.Salutation = 'Mr.';
      l.LastName = 'SmartLN' + Datetime.now().getTime();
      l.FirstName = 'SmartFN' + Datetime.now().getTime();
      l.ER_Registration_Number__c = crn;
      l.Company = 'Smart ' + Datetime.now().getTime();
      l.Email = emailAddress;
      l.Street = 'rue de smart';
      l.City = 'Paris';
      l.PostalCode = '75017';
      l.ER_Language__c = 'FR';
      l.ER_BUPicklist__c = 'BE';
      l.ER_VAT_Number__c = vat;
      l.ER_Legal_Name__c = 'Legal Name';
      l.ER_Legal_Street__c = 'rue de smart';
      l.ER_Legal_Zip_Code__c = '75017';
      l.ER_Legal_City__c = 'Paris';
      leads.add(l);
      //Coverage Increase
      Lead ld2 = new Lead();
      ld2.ER_SmartER_Context__c = false;
      ld2.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT');
      ld2.Salutation = 'Mr.';
      ld2.LastName = 'SmartLN' + Datetime.now().getTime();
      ld2.FirstName = 'SmartFN' + Datetime.now().getTime();
      ld2.ER_Registration_Number__c = crn;
      ld2.Company = 'Smart ' + Datetime.now().getTime();
      ld2.Email = emailAddress;
      ld2.Street = 'rue de smart';
      ld2.City = 'Paris';
      ld2.PostalCode = '75017';
      ld2.ER_Language__c = 'FR';
      ld2.ER_BUPicklist__c = 'BE';
      ld2.ER_VAT_Number__c = vat;
      ld2.ER_Legal_Name__c = 'Legal Name';
      ld2.ER_Legal_Street__c = 'rue de smart';
      ld2.ER_Legal_Zip_Code__c = '75017';
      ld2.ER_Legal_City__c = 'Paris';
      leads.add(ld2);
      //Coverage Increase
      Test.setMock(HttpCalloutMock.class, new SmarterAPIMock());
      insert leads;

      Test.startTest();
      APER18_Lead_Management.linkLeadToExistingContact(leads);
      Test.stopTest();
    }
  }
    
    @IsTest
    static void updateAutoenrollmentExtIdTest() {
        Lead newLead = APER07_UtilityTestMethod.getLead(Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT'));
        List<Lead> leadsList = new List<Lead>{newLead};
        Test.startTest();
        APER18_Lead_Management.isValidCRN(newLead);
        APER18_Lead_Management.isValidPostalCode(newLead);
        APER18_Lead_Management.updateAutoenrollmentExtId(leadsList);
        Test.stopTest();
    }
    
    @IsTest
    static void checkMerchantLeadCreation(){
        //Coverage
        User ur = TestDataFactory.newUser('APER082', 'APER018', 'Client Sales', 'ES');
        ur.ER_BypassVR__c = true;
        insert ur;
        System.runAs(ur) {
            Test.startTest();
            Lead ld = APER07_UtilityTestMethod.getLead(
                Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
            );
            Database.insert(ld, true);
            Test.stopTest();
        }
        //Coverage
    }
    
    @IsTest
    static void convertLeadsMerchant() {
        User u = TestDataFactory.newUser('FirstName', 'LastName', 'ER Zuora Sales', 'FR');
        System.runAs(u) {
            String emailAddress = Datetime.now().getTime() + '@edenred' + Datetime.now().getTime() + '.com';
            String crn = '32773318400516';
            Lead l = new Lead();
            l.ER_To_Be_Converted__c = true;
            l.ER_SmartER_Context__c = true;
            l.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT');
            l.Salutation = 'Mr.';
            l.LastName = 'SmartLN' + Datetime.now().getTime();
            l.FirstName = 'SmartFN' + Datetime.now().getTime();
            l.ER_Registration_Number__c = crn;
            l.Company = 'Smart ' + Datetime.now().getTime();
            l.Email = emailAddress;
            l.Street = 'rue de smart';
            l.City = 'Paris';
            l.PostalCode = '75017';
            l.ER_Country_Code__c = 'FR';
            l.Country = 'France';
            l.ER_Language__c = 'FR';
            l.ER_BUPicklist__c = 'BE';
            l.ER_VAT_Number__c = 'FR95327733184';
            l.NumberOfEmployees = 35;
            l.ER_Legal_Name__c = 'Legal Name';
            l.ER_Legal_Street__c = 'rue de smart';
            l.ER_Legal_Zip_Code__c = '75017';
            l.ER_Legal_City__c = 'Paris';
            Test.startTest();
            SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
            
            insert l;
            
            APER18_Lead_Management.checkExistingSmartERStructure(new list<lead>{l});
            
            Test.stopTest();
        }
    }

    static testMethod void checkOtherRating() {
      User u = [SELECT Id FROM User WHERE LastName = 'APER18'];
      List<Lead> leadsToInsert = new List<Lead>();
      System.runAs(u) {
        Test.startTest();
        Lead ld = APER07_UtilityTestMethod.getLead(Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT'));
        ld.LeadSource = 'Webform';  // Hot
        leadsToInsert.add(ld);
        Lead ld2 = APER07_UtilityTestMethod.getLead(Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType,'ER_Merchant_Lead_RT'));
        ld2.LeadSource = 'Social';  // Cold
        leadsToInsert.add(ld2);
        Database.insert(leadsToInsert, true);
        Test.stopTest();
      }
    }
}