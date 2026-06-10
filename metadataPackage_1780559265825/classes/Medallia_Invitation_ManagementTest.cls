/**
 * @author: ALK
 * @date: 17/03/2022
 * @desc: Medallia_Invitation_ManagementTest
 * @see: Medallia_Invitation_ManagementTest
 */

@IsTest
private class Medallia_Invitation_ManagementTest {
  /*@IsTest
  static void updateAccountLastInvite() {
    User ur = TestDataFactory.newUser(
      'User' + String.valueOf(Datetime.now().getTime()),
      'User' + String.valueOf(Datetime.now().getTime()),
      'Local Admin',
      'CEN'
    );
    ur.ER_BypassVR__c = true;
    ur.ER_Bypass_Duplication_Rule__c = true;
    insert ur;

    System.runAs(ur) {
      Account newCompany = APER07_UtilityTestMethod.getCompany('APER08_Case_Management_Test');
      insert newCompany;

      Account newIndividual = APER07_UtilityTestMethod.getIndividual('Mr.', 'NewIndividualName', 'Test');
      newIndividual.ER_Do_not_contact__pc = true;
      insert newIndividual;

      Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test', 'Case');
      newContact.ER_Do_not_contact__c = true;
      insert newContact;

      Test.startTest();
      List<medallia_xm__Invitation__c> invitationsList = new List<medallia_xm__Invitation__c>();
      invitationsList.add(
        new medallia_xm__Invitation__c(
          medallia_xm__Status__c = Constants.RECEIVED,
          medallia_xm__Medallia_Service__c = Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_PULSE_SURVEY),
          medallia_xm__Account__c = newCompany.Id
        )
      );
      invitationsList.add(
        new medallia_xm__Invitation__c(
          medallia_xm__Status__c = Constants.RECEIVED,
          medallia_xm__Medallia_Service__c = Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_PULSE_SURVEY),
          medallia_xm__Account__c = newCompany.Id,
          medallia_xm__Contact__c = newContact.Id
        )
      );
      insert invitationsList;
      Test.stopTest();
    }
  }*/
}