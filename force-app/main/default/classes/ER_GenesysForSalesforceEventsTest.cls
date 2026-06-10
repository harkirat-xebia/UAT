/**
 * @author: ALK
 * @date: 22/06/2022
 * @desc: ER_GenesysForSalesforceEventsTest
 * @see: ER_GenesysForSalesforceEventsTest
 */

@IsTest
private class ER_GenesysForSalesforceEventsTest {
  @IsTest
  static void changeRecordOwnerTest() {
    User ur = TestDataFactory.newUser('firstName', 'lastName', 'Local Admin', 'ES');

    System.runAs(ur) {
      Lead l = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
      );
      insert l;

      Case c = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
      c.Subject = 'Some subject';
      c.ER_BUPicklist__c = 'ES';
      c.Status = 'New';
      c.Priority = 'Medium';
      c.Origin = 'Email';
      insert c;

      Test.startTest();
      //ALK - Lead Test
      String retLeadOwner = ER_GenesysForSalesforceEvents.changeRecordOwner(l.Id);
      System.assert(retLeadOwner == null, 'Something went wrong - lead owner update fails');

      //ALK - Case Test
      ER_GenesysForSalesforceEvents.changeRecordOwner(c.Id);
      System.assert(retLeadOwner == null, 'Something went wrong - case owner update fails');

      Test.stopTest();
    }
  }
}