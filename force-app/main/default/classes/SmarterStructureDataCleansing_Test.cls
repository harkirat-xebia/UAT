@isTest
public class SmarterStructureDataCleansing_Test {
  @IsTest
  static void doPost() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'France' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      Constants.PROFILE_ER_INTEGRATION,
      'FR'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('SmarterStructureDataCleansing_Test');
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
      cont.ER_Language__c = 'FR';
      insert cont;

      ER_Financial_Center__c masterFC = APER07_UtilityTestMethod.getFinancialCenter(
        'fc' + Datetime.now().getTime(),
        acc.Id,
        Label.LABS_SF_FinancialCenter_Client,
        'Some Street',
        'Warsaw',
        '00-001',
        'Poland'
      );
      masterFC.ER_Type__c = 'Client';
      //masterFC.ER_Contact__c = cont.Id;
      masterFC.ER_Master__c = true;
      insert masterFC;

      Zuora__CustomerAccount__c masterBA = new Zuora__CustomerAccount__c();
      masterBA.Name = 'A00000001';
      masterBA.Zuora__Account__c = acc.Id;
      masterBA.Zuora__Status__c = 'Active';
      masterBA.Zuora__Currency__c = 'EUR';
      masterBA.ER_Financial_Center__c = masterFC.Id;
      masterBA.TECH_Financial_Center__c = masterFC.Id;
      masterBA.ER_Master__c = true;
      insert masterBA;

      Zuora__Subscription__c newZSub = new Zuora__Subscription__c();
      newZSub.Name = 'A-S00000001';
      newZSub.Zuora__Status__c = 'Active';
      newZSub.Zuora__Account__c = acc.Id;
      newZSub.Zuora__CustomerAccount__c = masterBA.Id;
      newZSub.Zuora__SubscriptionStartDate__c = Date.today();
      insert newZSub;

      Product2 p = APER07_UtilityTestMethod.getsolution('Zuora_Product');
      p.ProductCode = 'EDPO_TR_APM_PLN11';
      p.BU_External_Reference__c = 'EDPO_TR_APM_PLN11';
      p.ER_Business_Unit__c = 'PL';
      p.zqu__Category__c = 'Base Products';
      insert p;

      Zuora__SubscriptionRatePlan__c srp = new Zuora__SubscriptionRatePlan__c();
      srp.Zuora__Account__c = acc.Id;
      srp.Zuora__Subscription__c = newZSub.Id;
      srp.Zuora__External_Id__c = '8adcfb507a5b3046017a6273a74e0ca5x';
      srp.Zuora__OriginalProductRatePlanId__c = '8adcfb507a5b3046017a6273a74e0ca6x';
      srp.Zuora__OriginalSubscriptionRatePlanId__c = '8adcfb507a5b3046017a6273a74e0ca5x';
      srp.ER_Solution__c = p.Id;
      insert srp;

      Zuora__SubscriptionProductCharge__c newZSubPC = new Zuora__SubscriptionProductCharge__c();
      newZSubPC.Name = 'A-S00000001-PC';
      newZSubPC.Zuora__Account__c = acc.Id;
      newZSubPC.Zuora__Subscription__c = newZSub.Id;
      newZSubPC.Zuora__Type__c = 'Usage';
      insert newZSubPC;

      Test.startTest();
      SmarterStructureDataCleansing.SmarterStructureRequest data = new SmarterStructureDataCleansing.SmarterStructureRequest();
      data.oneforceAccountId = acc.Id;

      SmarterStructureDataCleansing.SmarterStructureResponse resp = SmarterStructureDataCleansing.doPost(
        new List<SmarterStructureDataCleansing.SmarterStructureRequest>{ data }
      );
      Test.stopTest();
    }
  }
}