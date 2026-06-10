/*
----------------------------------------------------------------------
-- - Name          : BAER01_DeleteInactiveLead_Test
-- - Author        : AAB
-- - Description   : Test class related to the batch cited below
                    - BAER01_DeleteInactiveLead
                    -
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks
-- -----------  ----------- 		--------  	---------------------------------------
-- 12-APR-2018  AAB    				1.0      	Initial version
---------------------------------------------------------------------------------------
*/
@IsTest
public class BAER01_DeleteInactiveLead_Test {
  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('BAER01', 'BAER01', 'Local Admin', 'BELUX', 'BENELUX');
    ur.ER_BypassVR__c = true;
    insert ur;
    System.runAs(ur) {
      List<Lead> listLeads = new List<Lead>();

      for (Integer i = 0; i < 3; i++) {
        Lead myLead = APER07_UtilityTestMethod.getLead(
          Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
        );
        listLeads.add(myLead);
      }
      insert listLeads;
    }
  }

  static testMethod void TestBAER01_DeleteInactiveLead() {
    User ur = [SELECT Id FROM User WHERE LastName = 'BAER01'];

    System.runAs(ur) {
      List<Lead> ldList = [SELECT Id FROM Lead];

      Datetime inactiveDate = Datetime.now().addMonths(-6);
      Test.setCreatedDate(ldList[0].Id, inactiveDate);

      // set the status to rejected
      ldList[1].Status = 'Rejected';
      ldList[1].ER_Rejected_Reason__c = Label.LAB_SF_Lead_Rejected_Interest;
      update ldList;

      Test.startTest();
      System.debug('## >>> Perform test  <<< ');

      BAER01_DeleteInactiveLead_Schedul sh1 = new BAER01_DeleteInactiveLead_Schedul();
      String sch = '0  00 1 3 * ?';
      system.schedule('Test', sch, sh1);

      // Call the batch
      BAER01_DeleteInactiveLead myBatch = new BAER01_DeleteInactiveLead();
      Database.executeBatch(myBatch);

      System.debug('## >>> Perform test  <<< ');

      Test.stopTest();

      // Check the results (assert)
      List<Lead> result = [SELECT id FROM Lead];
      System.assertEquals(2, result.size(), 'One of the lead has been deleted by the batch.');
    }
  }
}