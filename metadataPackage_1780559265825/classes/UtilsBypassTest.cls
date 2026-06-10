/**
 * @author : ALK
 * @date : 23/07/2021
 * @desc : UtilsBypassTest
 * @see UtilsBypassTest
 */

@IsTest
private class UtilsBypassTest {
  @IsTest
  static void testBehavior() {
    Test.startTest();
    User u = UtilsBypass.getCurrentUser();
    System.assert(u != null, 'no user returned');

    Boolean isBypassing = UtilsBypass.getBypassVR();
    UtilsBypass.canTrigger('AccountTriggerHandler');
    UtilsBypass.reset();
    UtilsBypass.setBypassedTriggersByApex(new Set<String>{ 'AccountTriggerHandler' });
    UtilsBypass.setCurrentUserParameter(new User(Id = UserInfo.getUserId()));
    UtilsBypass.setBypassAllVR(UserInfo.getUserId(), false);

    Test.stopTest();
  }
}