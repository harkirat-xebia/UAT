/**
 * @author Oussama LASFAR
 * @date 26/09/2018 (dd/mm/yyyy)
 * @description This class allows users to Cases from case list view.
 *              This class assign accepted cases to the current user + change the status of the first Case to 'In progress' and open it in a new tab
 */
@isTest
private class VFCER02_Case_Accept_Test {
  @testSetup
  static void testSetup() {
    Case testCase = new Case();
    testCase.Status = Label.LAB_SF_Case_inProgress;
    testCase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('ER_User_Case_RT')
      .getRecordTypeId();
    insert testCase;
  }
  static testMethod void testRedirect() {
    List<Case> caseinst = [SELECT id FROM Case WHERE recordtype.DeveloperName = 'ER_User_Case_RT' LIMIT 1];
    ApexPages.StandardSetController sc = new ApexPages.StandardSetController(caseinst);
    sc.setSelected(caseinst);
    VFCER02_Case_Accept controller = new VFCER02_Case_Accept(sc);
    Test.StartTest();
    controller.Redirect();
    Test.StopTest();
  }
}