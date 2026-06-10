/**
 * Created by noorg on 04/08/2021.
 */

@IsTest
private class APER34_Event_Management_TEST {
  @IsTest
  static void testBehavior() {
    UserRole urole = [SELECT Id FROM UserRole WHERE DeveloperName = 'ERPL_Customer_Care_Manager' LIMIT 1];
    User usr = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'ES'
    );
    usr.UserRoleId = urole.Id;
    insert usr;

    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Spain' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'ES'
    );
    u.UserRoleId = ur.Id;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('APER31_BankAccount_Management_Test');
      insert acc;

      Event evt = new Event();
      evt.WhatId = acc.Id;
      evt.StartDateTime = System.now();
      evt.EndDateTime = System.now().addHours(1);
      evt.ER_Channel__c = 'Call';
      evt.Subject = 'APER34_Event_Management_TEST';
      insert evt;

      Test.startTest();
      List<Event> events = [SELECT Id, Subject FROM Event];
      events[0].ER_Channel__c = 'Other';
      events[0].OwnerId = usr.Id;
      update events[0];
      Test.stopTest();
    }
  }
}