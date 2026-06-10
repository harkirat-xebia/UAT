/*
----------------------------------------------------------------------
-- - Name          : TRER06_EmailMessageAfterInsert_test
-- - Author        : ELA
-- - Description   : Test class related to the Apex classes cited below
					- TRER06_EmailMessageAfterInsert
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks
-- -----------  ----------- 		--------  	---------------------------------------
-- 26-APR-2021  ELA    				1.0      	Initial version
---------------------------------------------------------------------------------------
*/
@IsTest
public class TRER06_EmailMessageAfterInsert_test {
  /*static testMethod void testSendEmailFromCareCZ() {
        UserRole userRole = [SELECT Name, DeveloperName FROM UserRole WHERE NAME = 'ERCZ - Merchant Telesales'];
        User user = APER07_UtilityTestMethod.getTestUser(userRole.Id);
        Case testCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
        System.RunAs(user) {
            EmailMessage EMinst = new EmailMessage(FromAddress = Label.LABS_SF_Care_Mailing_List, FromName = 'CZ Partner', Incoming = false,
                    ToAddress= 'test@abc.org',
                    Subject = 'Test email', TextBody = '23456 ', ParentId = testCase.Id);
            Test.startTest();
            try{
                insert EMinst;
            } Catch (Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(Label.LABS_SF_EmailMessage_FromAdressForbidden) ? true : false;
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

        System.RunAs(user) {
            EmailMessage newEmail = new EmailMessage(FromAddress = Label.LABS_SF_Sales_Mailing_List,FromName = 'CZ Partnerske', Incoming = false,
                    ToAddress= 'test@abc.org',
                    Subject = 'Test email', TextBody = '23456 ', ParentId = testCase.Id);
            Test.startTest();
            try{
                insert newEmail;
            } catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(Label.LABS_SF_EmailMessage_FromAdressForbidden) ? true : false;
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
        EmailMessage newEmail = new EmailMessage(FromAddress = 'sisi@email.com',FromName = 'sisi', Incoming = true,
        ToAddress= 'edunsaaja-fi@edenred.com',
        RelatedToId = testCase.Id, Subject = 'Test email', TextBody = '23456 ', ParentId = testCase.Id);
        Test.startTest();
        insert newEmail;
            List<Case> testCaseEmail = [SELECT ID, status, ownerId, owner.type, owner.name FROM Case where Id= :newemail.RelatedToId limit 1];
            List<Group> ERFIQueue = [select Id, name, type FROM Group where Id = :testCaseEmail.get(0).ownerId limit 1];
            System.assertEquals(Label.LAB_SF_Case_inProgress, testCaseEmail.get(0).Status);
            System.assertEquals(ERFIQueue.get(0).name, 'ERFI Beneficiary');
            System.assertEquals(ERFIQueue.get(0).type, 'Queue');
        Test.stopTest();
    }*/
}