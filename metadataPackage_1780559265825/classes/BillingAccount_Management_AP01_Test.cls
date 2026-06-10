/*
----------------------------------------------------------------------
-- - Name          : BillingAccount_Management_AP01_Test
-- - Author        : AAZ
-- - Description   : Test class for BillingAccount Management Class     
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JUNE-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
@isTest
public class BillingAccount_Management_AP01_Test {
  @IsTest
  static void createChildSubforBillingAccount() {
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = TestDataFactory.newUser(
      'FirstName' + Datetime.now().getTime(),
      'LastName' + Datetime.now().getTime(),
      'ER Zuora Sales',
      'PL'
    );
    u.UserRoleId = ur.Id;
    u.ER_Bypass_Flows__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('BillingAccount_Management_AP01_Test');
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
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
      masterFC.ER_Type__c = 'Merchant';
      masterFC.ER_Contact__c = cont.Id;
      masterFC.ER_Master__c = true;
      insert masterFC;

      Zuora__CustomerAccount__c masterBA = new Zuora__CustomerAccount__c();
      masterBA.Name = 'A00000001';
      masterBA.Zuora__Account__c = acc.Id;
      masterBA.Zuora__Status__c = 'Active';
      masterBA.Zuora__Currency__c = 'PLN';
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

      ER_Financial_Center__c childFC = APER07_UtilityTestMethod.getFinancialCenter(
        'fc' + Datetime.now().getTime(),
        acc.Id,
        Label.LABS_SF_FinancialCenter_Client,
        'Some Street',
        'Warsaw',
        '00-002',
        'Poland'
      );
      childFC.ER_Type__c = 'Merchant';
      childFC.ER_Contact__c = cont.Id;
      childFC.ER_Master__c = false;
      insert childFC;

      Test.startTest();
      SendToZuoraMock zuoraMock = new SendToZuoraMock();
      Test.setMock(HttpCalloutMock.class, zuoraMock);

      Zuora__CustomerAccount__c childBa = new Zuora__CustomerAccount__c();
      childBa.Name = 'A00000002';
      childBa.Zuora__Account__c = acc.Id;
      childBa.Zuora__Status__c = 'Active';
      childBa.Zuora__Currency__c = 'PLN';
      childBa.ER_Financial_Center__c = childFC.Id;
      childBa.TECH_Financial_Center__c = childFC.Id;
      insert childBa;
      System.debug('>>>>> AAZ - BillingAccount_Management_AP01_Test childBa: ' + childBa);
      Test.stopTest();
    }
  }

  @IsTest
  static void pushBackLeadConversionIdsTest() {
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
      Account acc = APER07_UtilityTestMethod.getCompany('BillingAccount_Management_AP01_Test');
      insert acc;

      Contact cont = TestDataFactory.newContact(acc);
      cont.ER_Language__c = 'FR';
      insert cont;

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        Constants.OPPORTUNITY_CLIENT_RT,
        'Opp smarter'
      );
      newOpportunity.AccountId = acc.Id;
      newOpportunity.ER_Contract_Expected_Start_Date__c = Date.today();
      newOpportunity.ER_SmartER_Original_Lead_Id__c = '00Q5r000002z68qEAA';
      newOpportunity.ER_Credit_Limit__c = 125;
      insert newOpportunity;

      ER_Financial_Center__c newFC = APER07_UtilityTestMethod.getFinancialCenter(
        'fc' + Datetime.now().getTime(),
        acc.Id,
        Label.LABS_SF_FinancialCenter_Client,
        'Some Street',
        'Paris',
        '00-001',
        'France'
      );
      newFC.ER_Type__c = 'Client';
      //newFC.ER_Contact__c = cont.Id;
      newFC.ER_SmartER_Original_Lead_Id__c = '00Q5r000002z68qEAA';
      newFC.ER_Master__c = false;
      newFC.ER_SmartER_Context__c = true;
      insert newFC;

      Test.startTest();
      SmarterAPIMock smarterMock = new SmarterAPIMock();
      Test.setMock(HttpCalloutMock.class, smarterMock);

      Zuora__CustomerAccount__c newBA = new Zuora__CustomerAccount__c();
      newBA.Name = 'A00000001';
      newBA.Zuora__Account__c = acc.Id;
      newBA.Zuora__Status__c = 'Active';
      newBA.Zuora__Currency__c = 'EUR';
      newBA.ER_Financial_Center__c = newFC.Id;
      newBA.TECH_Financial_Center__c = newFC.Id;
      newBA.ER_Master__c = false;
      insert newBA;
      Test.stopTest();
    }
  }

  @IsTest
  static void increaseCoverage() {
    Account acc = APER07_UtilityTestMethod.getCompany('BillingAccount_Management_AP01_Test');
    insert acc;
    Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
    ba.Name = 'A00000001';
    ba.Zuora__Account__c = acc.Id;
    ba.Zuora__Status__c = 'Active';
    ba.Zuora__Currency__c = 'PLN';
    insert ba;
    ba.Zuora__Currency__c = 'EUR';
    update ba;
    delete ba;
    undelete ba;
  }
}