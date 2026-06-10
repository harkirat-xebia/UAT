/*
----------------------------------------------------------------------
-- - Name          : APER03_Lead_CreateFinancialCenter_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
					- APER03_Lead_CreateFinancialCenter
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks
-- -----------  ----------- 		--------  	---------------------------------------
-- 17-JUL-2018  AAB    				  1.0      	  Initial version
-- Oct-2022     snica           2.0         Increased code coverage
---------------------------------------------------------------------------------------
*/
@isTest
public class APER03_Lead_CreateFinancialCenter_Test {
  public static List<Lead> createLeadsStandard(Integer numlds, Id recordType, String vatNumber, Boolean isToInsert) {
    List<Lead> leads = new List<Lead>();

    // Retrieve picklist values
    Schema.DescribeFieldResult fieldResult = Lead.Status.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    Case c = new Case();
    insert c;
    for (Integer i = 0; i < numlds; i++) {
      Lead ld = new Lead(
        ER_Store_Name__c = 'my store',
        Salutation = 'Mr.',
        LastName = 'lastname' + i,
        FirstName = 'firstname' + i,
        Status = ple[0].getValue(),
        RecordTypeId = recordType,
        ER_VAT_Number__c = vatNumber,
        Company = 'Edenred',
        Email = 'test@salesforce.com',
        Street = '178, boulevard Gabriel Péri ',
        City = 'Malakoff',
        ER_Terminal__c = 'Yes',
        PostalCode = '92240',
        ER_Language__c = 'EN',
        ER_MID_Clearing__c = '400',
        ER_Sub_MID_Clearing__c = '401',
        ER_Case__c = c.Id
      );
      leads.add(ld);
    }

    if (isToInsert) {
      insert leads;
    }

    return leads;
  }

  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APER03', 'APER03', 'Local Admin', 'CEN');
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      Account newCompany = APER07_UtilityTestMethod.getCompany(Utils.generateUniqueString(Constants.TYPE_STRING, 30));
      insert newCompany;

      Account acc2 = APER07_UtilityTestMethod.getCompany(Utils.generateUniqueString(Constants.TYPE_STRING, 30));
      insert acc2;

      Case c = new Case();
      insert c;

      Lead ld = new Lead();
      ld.ER_Store_Name__c = 'my store';
      ld.Salutation = 'Mr.';
      ld.LastName = 'lastname';
      ld.FirstName = 'firstname';
      ld.Status = 'New';
      ld.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT);
      ld.ER_VAT_Number__c = Utils.generateUniqueString(Constants.TYPE_INTEGER, 10);
      ld.Company = Utils.generateUniqueString(Constants.TYPE_STRING, 30);
      ld.Email = Utils.generateUniqueString(Constants.TYPE_STRING, 10) + '@mailinator.com';
      ld.Street = '178, boulevard Gabriel Péri ';
      ld.City = 'Malakoff';
      ld.ER_Terminal__c = 'Yes';
      ld.PostalCode = '92240';
      ld.ER_Language__c = 'EN';
      ld.ER_Case__c = c.Id;

      insert ld;

      Lead ld2 = new Lead();
      ld2.ER_Store_Name__c = 'my store2';
      ld2.Salutation = 'Mr.2';
      ld2.LastName = 'lastname2';
      ld2.FirstName = 'firstname2';
      ld2.Status = 'New';
      ld2.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT);
      ld2.ER_VAT_Number__c = Utils.generateUniqueString(Constants.TYPE_INTEGER, 10);
      ld2.Company = Utils.generateUniqueString(Constants.TYPE_STRING, 30);
      ld2.Email = Utils.generateUniqueString(Constants.TYPE_STRING, 10) + '@mailinator.com';
      ld2.Street = '172, boulevard Gabriel Péri ';
      ld2.City = 'Malakoff2';
      ld2.PostalCode = '92242';
      ld2.ER_Language__c = 'EN';
      ld2.ER_MID_Clearing__c = '402';
      ld2.ER_Sub_MID_Clearing__c = '402';
      ld2.ER_Case__c = c.Id;
      ld2.IsConverted = true;
      ld2.NumberOfEmployees = 32;
      ld2.ConvertedAccountId = newCompany.Id;
      ld2.ER_SmartER_Context__c = true;

      insert ld2;

      Lead ld3 = new Lead();
      ld3.ER_Store_Name__c = 'my store2';
      ld3.Salutation = 'Mr.2';
      ld3.LastName = 'lastname2';
      ld3.FirstName = 'firstname2';
      ld3.Status = 'New';
      ld3.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_MERCHANT_RT);
      ld3.ER_VAT_Number__c = Utils.generateUniqueString(Constants.TYPE_INTEGER, 10);
      ld3.Company = Utils.generateUniqueString(Constants.TYPE_STRING, 30);
      ld3.Email = Utils.generateUniqueString(Constants.TYPE_STRING, 10) + '@mailinator.com';
      ld3.Street = '172, boulevard Gabriel Péri ';
      ld3.City = 'Malakoff2';
      ld3.ER_Terminal__c = 'Yes';
      ld3.PostalCode = '92242';
      ld3.ER_Language__c = 'EN';
      ld3.ER_MID_Clearing__c = '402';
      ld3.ER_Sub_MID_Clearing__c = '402';
      ld3.ER_Case__c = c.Id;
      ld3.IsConverted = true;
      ld3.NumberOfEmployees = 35;
      ld3.ConvertedAccountId = acc2.Id;

      insert ld3;
    }
  }

  static testMethod void createFinancialCenterTest() {
    List<Lead> leadsList = [
      SELECT
        Id,
        ER_Store_Name__c,
        ER_MCC_Clearing__c,
        ER_MID_AID__c,
        ER_MCC_Authorization__c,
        ER_MID_Authorization__c,
        ER_MID_Clearing__c,
        ER_Sub_MID_Clearing__c,
        ER_Sub_MID_Authorization__c,
        ER_MID__c,
        ER_AID_Clearing__c,
        IsConverted,
        ER_TID_Authorization__c,
        ER_AID_Authorization__c,
        ER_AID__c,
        ER_TID_Clearing__c,
        ER_Terminal__c,
        ER_Country_Code__c,
        ConvertedAccountId,
        ConvertedOpportunityId,
        Description,
        RecordTypeId,
        ConvertedContactId,
        ER_Legal_Street__c,
        ER_Legal_City__c,
        ER_Legal_Country__c,
        ER_Legal_Zip_Code__c,
        ER_Legal_State_Province__c,
        ER_Legal_Country_Code__c,
        ER_BUPicklist__c,
        Street,
        Company,
        City,
        Country,
        State,
        PostalCode,
        OwnerId,
        ER_SmartER_Context__c,
        ER_dd_Trace_Id__c,
        ER_OVT_Code__c,
        ER_OVT_Operator__c
      FROM Lead
    ];
    Test.startTest();
    SmarterAPIMock smarterMock = new SmarterAPIMock();
    Test.setMock(HttpCalloutMock.class, smarterMock);
    APER03_Lead_CreateFinancialCenter.createFinancialCenter(leadsList);
    Test.stopTest();
  }
}