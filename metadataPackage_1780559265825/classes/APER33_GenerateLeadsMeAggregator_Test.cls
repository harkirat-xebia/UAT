/*
----------------------------------------------------------------------
-- - Name          : APER33_GenerateLeadsMeAggregator_Test
-- - Author        : snica
-- - Description   : Test class for APER33_GenerateLeadsMeAggregator.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- Oct-2022     snica               1.0         Initial version
---------------------------------------------------------------------------------------
*/
@IsTest
private class APER33_GenerateLeadsMeAggregator_Test {
  @IsTest
  static void testBehavior() {
    User ur = TestDataFactory.newUser('APER18', 'APER18', 'Local Admin', 'BENELUX');

    System.runAs(ur) {
      Account newMerchantAggAccount = APER07_UtilityTestMethod.insertAccount(
        'merchant' + Datetime.now().getTime(),
        Constants.ACCOUNT_COMPANY_RT
      );
      Account newAggAccount = APER07_UtilityTestMethod.insertAccount(
        'aggAccount' + +Datetime.now().getTime(),
        Constants.ACCOUNT_AGGREGATOR_MERCHANT_RT
      );
      AccountPartner partner1 = APER07_UtilityTestMethod.newAccountPartner(
        'AggregatorMerchant',
        newMerchantAggAccount.Id,
        newAggAccount.Id
      );
      insert partner1;

      AccountPartner partner2 = APER07_UtilityTestMethod.newAccountPartner(
        Constants.PARTNER_ROLE_AGGREGATOR,
        newAggAccount.Id,
        newMerchantAggAccount.Id
      );
      insert partner2;

      Product2 p = APER07_UtilityTestMethod.insertProduct2(
        'testSolution',
        ur.ER_Business_Unit__c,
        'testSolution',
        'Solution',
        null
      );

      Test.startTest();
      List<Account> accounts = [
        SELECT
          Id,
          Description,
          Name,
          ER_Legal_Name__c,
          BillingCity,
          BillingCountry,
          BillingPostalCode,
          ER_Registration_Number__c,
          BillingStreet,
          ER_VAT_Number__c,
          BillingState,
          ER_BUPicklist__c
        FROM Account
        WHERE
          RecordTypeId = :Utils.getRecordTypeIdByDeveloperName(
            Account.SObjectType,
            Constants.ACCOUNT_AGGREGATOR_MERCHANT_RT
          )
          AND Id = :newMerchantAggAccount.Id
        LIMIT 10000
      ];
      APER33_GenerateLeadsMeAggregator.generateAggregatorLeads(newMerchantAggAccount.Id);
      List<Lead> leads = [
        SELECT Id
        FROM Lead
        WHERE LeadSource = :Constants.PARTNER_ROLE_AGGREGATOR AND FirstName = :Constants.PARTNER_ROLE_AGGREGATOR
      ];
      Test.stopTest();
    }

  }
}