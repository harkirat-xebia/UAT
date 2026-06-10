/**
 * Created by noorgoolamnabee on 10/01/2023.
 */

@IsTest
private class ClientOrderControllerTest {
  @IsTest
  static void testOrderBehavior() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account acc = APER07_UtilityTestMethod.getCompany('testAccountFR');
      acc.SmartER_Customer_Id__c = '123446';
      insert acc;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new ClientOrderServiceOrderMock(Constants.ACCOUNT));
      ClientOrderController.getOrders(acc.Id, 0, 20);

      Test.stopTest();
    }
  }

  @IsTest
     static void testRetryOrder() {

         User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
         runningUser.ER_BypassVR__c = true;
         runningUser.ER_Bypass_Flows__c = true;
         runningUser.ER_bypassTrigger__c = true;

         System.runAs(runningUser) {
             Account acc = APER07_UtilityTestMethod.getCompany('testAccountFR');
             acc.SmartER_Customer_Id__c = '123446';
             insert acc;

             Test.startTest();

             Test.setMock(HttpCalloutMock.class, new ClientOrderServiceOrderMock('Load'));
             ClientOrderController.retryOrder('1234',acc.Id);

             Test.stopTest();
             
             list<Task> createdTask = [SELECT Id, Subject FROM Task WHERE WhatId =:acc.Id]; 
             System.assertEquals(createdTask.size(), 1);
             System.assertEquals(createdTask[0].Subject, Label.LAB_SF_CL_ORDER_RE_SUBMISSION_SUBJECT);

         }
     }
 
     
  @IsTest
  static void testOrderLoad() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account acc = APER07_UtilityTestMethod.getCompany('testAccountFR');
      acc.SmartER_Customer_Id__c = '123446';
      insert acc;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new ClientOrderServiceOrderMock('Load'));
      ClientOrderController.getOrderLoad('1234', 'order-id', 0, 20);

      Test.stopTest();
    }
  }

  @IsTest
  static void testOrderlineBehavior() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account acc = APER07_UtilityTestMethod.getCompany('testAccountFR');
      acc.SmartER_Customer_Id__c = '123446';
      insert acc;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new ClientOrderServiceOrderLineMock());
      ClientOrderController.getOrderItemLines(acc.Id, '12345', 0, 20);
      Test.stopTest();
    }
  }

  @IsTest
  static void testCancelBehavior() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account acc = APER07_UtilityTestMethod.getCompany('testAccountFR');
      acc.SmartER_Customer_Id__c = '123446';
      insert acc;
      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new ClientOrderServiceOrderMock(Constants.SMARTER_CANCEL_ORDER));
      ClientOrderController.cancelOrders(String.valueOf(acc.Id), '12345', '12345');
      Test.stopTest();
    }
  }

  @IsTest
  static void testOrderEmployeeBehavior() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      ER_Employee__c emp = APER07_UtilityTestMethod.getEmployee();
      emp.ER_SmartER_Employee_Id__c = '123446';
      insert emp;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new ClientOrderServiceOrderMock(Constants.EMPLOYEE));
      ClientOrderController.getEmployeeOrders(emp.Id, 0, 20);

      Test.stopTest();
    }
  }

  @IsTest
  static void testOrderProcessingEventBehavior() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      ER_Employee__c emp = APER07_UtilityTestMethod.getEmployee();
      emp.ER_SmartER_Employee_Id__c = '123446';
      insert emp;

      Test.startTest();

      Test.setMock(
        HttpCalloutMock.class,
        new ClientOrderServiceOrderMock(Constants.SMARTER_WEBSERVICE_PROCESSING_EVENTS)
      );
      ClientOrderController.getOrderProcessingEvents('57123', 'ER0001', 'A001', 0, 20);

      Test.stopTest();
    }
  }

  @IsTest
  static void testgetEdenredCodes() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      ER_Employee__c emp = APER07_UtilityTestMethod.getEmployee();
      emp.ER_SmartER_Employee_Id__c = '63c8e5fe8e33196d093b5c13';
      insert emp;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new SmarterAPIMock());
      ClientOrderController.getEdenredCodes(emp.Id);

      Test.stopTest();
    }
  }

  @IsTest
  static void testgetEdenredCodes_KO() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Test.startTest();
      try {
        ClientOrderController.getEdenredCodes(null);
      } catch (Exception e) {
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void testsendEdnredCode() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      ER_Employee__c emp = APER07_UtilityTestMethod.getEmployee();
      emp.ER_SmartER_Employee_Id__c = '63c8e5fe8e33196d093b5c13';
      insert emp;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new SmarterAPIMock());
      ClientOrderController.sendEdnredCode('2129', emp.Id);

      Test.stopTest();
    }
  }

  @IsTest
  static void testsendEdnredCode_KO() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Test.startTest();
      try {
        ClientOrderController.sendEdnredCode('', null);
      } catch (Exception e) {
      }
      Test.stopTest();
    }
  }
}