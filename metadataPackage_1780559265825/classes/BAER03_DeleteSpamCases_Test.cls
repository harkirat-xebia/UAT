/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 07-21-2023
 * @last modified by  : Malha AMEUR
**/
@isTest 
public with sharing class BAER03_DeleteSpamCases_Test {
    @testSetup
    static void testSetup() {
        Account newCompany = APER07_UtilityTestMethod.getCompany('APER08_Case_Management_Test');
        insert newCompany; 
        
        Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test', 'Case');
        newContact.AccountId = newCompany.Id;
        insert newContact;
        
        ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
        newEmployee.ER_Client__c = newCompany.id;
        insert newEmployee;
        
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
        
        testCase.status = 'Spam';
        update testCase;
    }
    
    @IsTest 
  static void testScheduler() {
        test.startTest();
        BAER03_DeleteSpamCases_Schedul obj = new BAER03_DeleteSpamCases_Schedul();   
        String chron = '0 0 23 * * ?';        
        String jobid = System.schedule('testScheduledApex', chron, obj);
        
        String soqlDyn = 'SELECT Id, Status, ClosedDate FROM Case';
        
        BAER03_DeleteSpamCases job = new BAER03_DeleteSpamCases(soqlDyn);
    Database.executeBatch(job, 1);
        test.stopTest();
        List<Case> cases = [SELECT Id FROM Case WHERE status = 'Spam' limit 1];
        System.assertEquals(cases.size(), 0, 'Spam cases must be deleted');  
    }   
}