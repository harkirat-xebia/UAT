/**
 * Created by noorg on 30/06/2021.
 */

@IsTest
private class WSER11_PL_PublicRegister_TEST {
  @TestSetup
  static void testSetup() {
    User runningUser = [SELECT id, ER_Business_Unit__c FROM User WHERE id = :UserInfo.getUserId()];
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'PL'
    );
    u.UserRoleId = ur.Id;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('WSER11_PL_PublicRegister_TEST');
      acc.ER_Registration_Number__c = '12345678';
      acc.ER_Country_Code__c = 'PL';
      insert acc;
    }
  }
  @IsTest
  static void testBehavior() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'ERPL_Customer_Care_Manager' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'Merchant Sales',
      'PL'
    );
    u.UserRoleId = ur.Id;
    Account acc = [SELECT Id, ER_Registration_Number__c FROM Account WHERE Name = 'WSER11_PL_PublicRegister_TEST'];

    System.runAs(u) {
      Test.startTest();

      //Set mock send to ERP
      WSER11_PL_PublicRegister_Mock erpMock = new WSER11_PL_PublicRegister_Mock();

      Test.setMock(HttpCalloutMock.class, erpMock);
      String identification = APCZ04_AresByIdController.getPLWSIdentification(acc.ER_Registration_Number__c);
      APCZ04_AresByIdController.getPLWSResult(identification);
      Test.stopTest();
    }
  }
}