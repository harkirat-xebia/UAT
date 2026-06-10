/**
 * @author : AAZ
 * @date : 11/09/2022
 * @desc : ER_ZuoraQuoteAPI_Test
 * @see ER_ZuoraQuoteAPI_Test
 */

@IsTest
public class ER_ZuoraQuoteAPI_Test {
  @IsTest
  static void doPost() {
    Account acc = TestDataFactory.newAccount();
    acc.ER_BUPicklist__c = 'FR';
    acc.ER_Status__c = 'Active';
    acc.Name = 'Smart Account';
    insert acc;

    Contact c = TestDataFactory.newContact(acc);
    insert c;

    ER_Financial_Center__c f = TestDataFactory.newClientFC(acc);
    //f.ER_Contact__c = c.Id;
    f.ER_Type__c = Label.LABS_SF_FinancialCenter_Client;
    f.ER_BUPicklist__c = 'FR';
    insert f;

    Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c();
    ba.Name = 'BaName';
    ba.ER_Financial_Center__c = f.Id;
    ba.Zuora__AccountNumber__c = 'A00000100';
    ba.Zuora__Account__c = acc.Id;
    ba.SEQUENCE_SET__c = 'CUSTOMER';
    ba.Zuora__Status__c = 'Active';
    ba.CurrencyIsoCode = 'EUR';
    ba.TECH_Financial_Center__c = f.Id;
    insert ba;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Client_Opportunity_RT',
      'Opp ER_ZuoraQuoteAPI_Test'
    );
    newOpportunity.AccountId = acc.Id;
    newOpportunity.ER_Contract_Expected_Start_Date__c = Date.today();
    newOpportunity.ER_BUPicklist__c = 'BE';
    insert newOpportunity;

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('TR SMARTER');
    newSolution.ProductCode = 'TR SMART';
    newSolution.zqu__EffectiveStartDate__c = Date.today();
    newSolution.zqu__EffectiveEndDate__c = Date.today().addYears(1);
    newSolution.ER_BUPicklist__c = 'FR';
    insert newSolution;

    zqu__ProductRatePlan__c productRP = APER07_UtilityTestMethod.getZuoraProductRP(newSolution.Id);
    productRP.zqu__ZuoraId__c = '8adcd67f8050997a01805fd3c69b1c5f';
    productRP.zqu__EffectiveStartDate__c = Date.today();
    productRP.zqu__EffectiveEndDate__c = Date.today().addYears(1);
    insert productRP;

    zqu__BillingEntity__c entity = new zqu__BillingEntity__c();
    entity.zqu__EntityID__c = '8adce4216dafd3bc016dafe8e470079b';
    entity.zqu__EntityName__c = 'SmartER France';
    insert entity;

    List<ER_ZuoraQuoteAPI.Record> records = new List<ER_ZuoraQuoteAPI.Record>();

    Test.startTest();
    SendToZuoraMock zuoraMock = new SendToZuoraMock();
    SendToZuoraMock.fcId = f.Id;
    Test.setMock(HttpCalloutMock.class, zuoraMock);

    ER_ZuoraQuoteAPI.Record rec = new ER_ZuoraQuoteAPI.Record();
    rec.opportunityId = newOpportunity.Id;
    rec.billingAccountNumber = ba.Zuora__AccountNumber__c;
    rec.dropStep = 'Step 1';
    rec.customerSignedVersion = '20230116';
    rec.agreementDateTime = '2023-01-10T13:45:56.000Z';
    rec.tcsSignedLink = 'https://er-europe--devonefce.sandbox.my.salesforce.com/sfc';

    ER_ZuoraQuoteAPI.ProductRateplan PRP = new ER_ZuoraQuoteAPI.ProductRateplan();
    PRP.ratePlanId = productRP.zqu__ZuoraId__c;
    rec.ratePlans = new List<ER_ZuoraQuoteAPI.ProductRateplan>{ PRP };

    records.add(rec);
    ER_ZuoraQuoteAPI.ZuoraAPIResponse resp = ER_ZuoraQuoteAPI.doPost(records);

    Test.stopTest();
  }
}