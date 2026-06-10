/*
----------------------------------------------------------------------
-- - Name          : ER_ZuoraQuoteSelectEntity_Test
-- - Author        : AAZ
-- - Description   : Test class for ER_ZuoraQuoteSelectEntity     
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- MAY-2022     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ER_ZuoraQuoteSelectEntity_Test {
  static testMethod void coverZuoraQuoteSelectBillingAccount() {
    Account acc = APER07_UtilityTestMethod.getCompany('ER_ZuoraQuoteSelectEntity_Test');
    insert acc;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'Opp ER_ZuoraQuoteSelectEntity_Test'
    );
    newOpportunity.AccountId = acc.Id;
    newOpportunity.ER_Reason__c = 'New';
    newOpportunity.ER_Contract_Expected_Start_Date__c = Date.today();
    insert newOpportunity;

    ER_ZuoraQuoteSelectEntity controller = new ER_ZuoraQuoteSelectEntity();

    Test.startTest();
    controller.selectEntityForNewQuote(acc.Id, newOpportunity.Id);
    Test.stopTest();
  }
}