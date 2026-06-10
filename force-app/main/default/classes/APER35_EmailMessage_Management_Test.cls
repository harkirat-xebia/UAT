/*
----------------------------------------------------------------------
-- - Name          : APER35_EmailMessage_Management
-- - Author        : Noor
-- - Description   : Class for all EmailMessage object logic
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 12/10/2021   Noor                1.0         Trigger Handler Rework.
---------------------------------------------------------------------------------------
*/
@IsTest
private class APER35_EmailMessage_Management_Test {
  static testMethod void testSendEmailFromCareCZ() {
    UserRole userRole = [SELECT Name, DeveloperName FROM UserRole WHERE NAME = 'ERCZ - Merchant Telesales'];
    User user = APER07_UtilityTestMethod.getTestUser(userRole.Id);
    Case testCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
    System.runAs(user) {
      EmailMessage EMinst = new EmailMessage(
        FromAddress = Label.LABS_SF_Care_Mailing_List,
        FromName = 'CZ Partner',
        Incoming = false,
        ToAddress = 'test@abc.org',
        Subject = 'Test email',
        TextBody = '23456 ',
        ParentId = testCase.Id
      );
      Test.startTest();
      try {
        insert EMinst;
      } catch (Exception ex) {
        Boolean expectedExceptionThrown = ex.getMessage().contains(Label.LABS_SF_EmailMessage_FromAdressForbidden)
          ? true
          : false;
        System.assertEquals(expectedExceptionThrown, true);
      }
      Test.stopTest();
    }
  }

  static testMethod void testSendEmailFromSalesCZ() {
    UserRole userRole = [SELECT Name, DeveloperName FROM UserRole WHERE Name = 'ERCZ - External Customer Care'];
    User user = APER07_UtilityTestMethod.getTestUser(userRole.Id);
    insert user;
    Case testCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');

    System.runAs(user) {
      EmailMessage newEmail = new EmailMessage(
        FromAddress = Label.LABS_SF_Sales_Mailing_List,
        FromName = 'CZ Partnerske',
        Incoming = false,
        ToAddress = 'test@abc.org',
        Subject = 'Test email',
        TextBody = '23456 ',
        ParentId = testCase.Id
      );
      Test.startTest();
      try {
        insert newEmail;
      } catch (Exception ex) {
        Boolean expectedExceptionThrown = ex.getMessage().contains(Label.LABS_SF_EmailMessage_FromAdressForbidden)
          ? true
          : false;
        System.assertEquals(expectedExceptionThrown, true);
      }
      Test.stopTest();
    }
  }

  static testMethod void testPendingCasesFI() {
    Case testCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
    testCase.ER_BUPicklist__c = 'FI';
    testCase.Status = 'Pending';
    insert testCase;
    EmailMessage newEmail = new EmailMessage(
      FromAddress = 'sisi@email.com',
      FromName = 'sisi',
      Incoming = true,
      ToAddress = 'edunsaaja-fi@edenred.com',
      RelatedToId = testCase.Id,
      Subject = 'Test email',
      TextBody = '23456 ',
      ParentId = testCase.Id
    );
    Test.startTest();
    insert newEmail;
    
    Test.stopTest();
  }

  static testMethod void testRouteEmailMessageToGenesys() {
    User ur = TestDataFactory.newUser('APER18', 'APER18', 'System Administrator', 'GR');
    ur.ER_BypassVR__c = true;
    ur.ER_Queue_CTI__c = '92eb5086-c37e-46b4-b9a8-0423de74ddb4';
    insert ur;

    System.runAs(ur) {
      /*Id queueId = Utils.getQueueIdByName(
        Utils.getGlobalSettingsValueFromKey(Constants.GENESYS_GR_EMAIL_MESSAGE_QUEUE)
      );*/

      Case c = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      c.ER_BUPicklist__c = 'GR';
      c.Status = 'New';
      c.Subject = 'Test';
      c.Description = 'Test';
      //c.OwnerId = queueId;
      insert c;
      Test.startTest();

      EmailMessage emailMsg = new EmailMessage();
      emailMsg.Incoming = true;
      emailMsg.Subject = 'Test email [ref: testRouteEmailMessageToGenesys]';
      emailMsg.TextBody = 'testRouteEmailMessageToGenesys';
      emailMsg.ParentId = c.Id;
      emailMsg.ToAddress = 'ordergruat@edenred.com';
      emailMsg.FromAddress = 'testRouteEmailMessageToGenesys@edenred.com';
      emailMsg.FromName = 'testRouteEmailMessageToGenesys';
      insert emailMsg;

      Test.stopTest();
    }
  }
}