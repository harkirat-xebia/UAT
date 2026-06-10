/*
----------------------------------------------------------------------
-- - Name          : ER_ZuoraQuoteSelectBillingAccount_Test
-- - Author        : AAZ
-- - Description   : Test class for ER_ZuoraQuoteSelectBillingAccount     
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JULY-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ER_ZuoraQuoteSelectBillingAccount_Test {
  static testMethod void coverZuoraQuoteSelectBillingAccount() {
    Account acc = APER07_UtilityTestMethod.getCompany('BillingAccount_Management_AP01_Test');
    insert acc;

    Contact cont = TestDataFactory.newContact(acc);
    insert cont;

    Pricebook2 newPricebook = APER07_UtilityTestMethod.getpriceBook();

    Contract newContract = APER07_UtilityTestMethod.getContract(acc.Id, System.today(), 'Draft', newPricebook.Id);
    insert newContract;

    ER_Financial_Center__c newFC = APER07_UtilityTestMethod.getFinancialCenter(
      'fc' + Datetime.now().getTime(),
      acc.Id,
      Label.LABS_SF_FinancialCenter_Client,
      'Some Street',
      'Warsaw',
      '00-001',
      'Poland'
    );
    newFC.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
    insert newFC;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'Opp ER_ZuoraQuoteSelectBillingAccount_Test'
    );
    newOpportunity.AccountId = acc.Id;
    newOpportunity.ER_Reason__c = 'New';
    newOpportunity.ER_Contract_Expected_Start_Date__c = Date.today();
    newOpportunity.ER_AmendedFromContract__c = newContract.Id; //'8005r000000JFJ1AAO';
    insert newOpportunity;

    Zuora__CustomerAccount__c newBA = new Zuora__CustomerAccount__c();
    newBA.Name = 'A00000001';
    newBA.Zuora__Account__c = acc.Id;
    newBA.Zuora__Status__c = 'Active';
    newBA.ER_Financial_Center__c = newFC.Id;
    insert newBA;

    Zuora__Subscription__c newZSub = new Zuora__Subscription__c();
    newZSub.Name = 'A-S00000001';
    newZSub.Zuora__Status__c = 'Active';
    newZSub.Zuora__Account__c = acc.Id;
    newZSub.Zuora__CustomerAccount__c = newBA.Id;
    newZSub.Zuora__SubscriptionStartDate__c = Date.today();
    insert newZSub;

    ER_ZuoraQuoteSelectBillingAccount controller = new ER_ZuoraQuoteSelectBillingAccount();
    zqu.JSRemoteController.BillingAccountObjects accountObjs = new zqu.JSRemoteController.BillingAccountObjects();
    accountObjs.sfdcAccountId = acc.Id;
    accountObjs.opportunityId = newOpportunity.Id;
    accountObjs.billingAccountTypes = new List<String>{ 'new', 'existing' };

    zqu.JSRemoteController.QuoteTypeObjects quoteTypeObjs = new zqu.JSRemoteController.QuoteTypeObjects();
    quoteTypeObjs.quoteTypes = new List<String>{ 'new', 'amend' };
    quoteTypeObjs.opportunityId = newOpportunity.Id;

    zqu.JSRemoteController.SubscriptionObjects subTypeObjs = new zqu.JSRemoteController.SubscriptionObjects();
    subTypeObjs.opportunityId = newOpportunity.Id;

    Test.startTest();
    controller.getAvailableBillingAccounts(accountObjs);
    controller.getAvailableQuoteTypes(quoteTypeObjs);
    controller.getAvailableSubscriptions(subTypeObjs);
    Test.stopTest();
  }
}