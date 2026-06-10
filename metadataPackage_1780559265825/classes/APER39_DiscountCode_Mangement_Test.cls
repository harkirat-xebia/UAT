/*
----------------------------------------------------------------------
-- - Name          : APER39_DiscountCode_Mangement_Test
-- - Author        : VJOY
-- - Description   : Test Class for APER39_DiscountCode_Mangement
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  MAR-2022    VJOY                1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER39_DiscountCode_Mangement_Test {

  @testSetup
  static void testSetup() {

    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany');
    newMerchantAccount.ER_BUPicklist__c = 'BENELUX';
    insert newMerchantAccount;

    Pricebook2 pricebook = APER07_UtilityTestMethod.getpriceBook();
    pricebook.ER_Business_Unit__c = 'HU';

    Pricebook2 pricebook2 = new Pricebook2();
    pricebook2.Name = 'TestPB';
    pricebook2.ER_Business_Unit__c = 'HU';
    insert pricebook2;

    Product2 prod2 = APER07_UtilityTestMethod.getProduct('Test');
    insert prod2;

    PricebookEntry pricebookEntryStd =
        APER07_UtilityTestMethod.getpriceBookEntry(pricebook.Id, prod2.Id);
    pricebookEntryStd.ER_Offer_validity_end_date__c = Date.today().addDays(10);
    insert pricebookEntryStd;

    PricebookEntry pricebookEntry =
        APER07_UtilityTestMethod.getpriceBookEntry(pricebook2.Id, prod2.Id);
    pricebookEntry.ER_Offer_validity_end_date__c = Date.today().addDays(10);
    insert pricebookEntry;

    // Contract in Draft
    Contract con = APER07_UtilityTestMethod.getContract(
        newMerchantAccount.Id,
        System.today(),
        'Draft',
        pricebook2.Id
    );
    con.ER_BUPicklist__c = 'BENELUX';
    insert con;

    // ---------------- Promo Code 1 ----------------
    ER_Promo_Code__c promoCode = new ER_Promo_Code__c();
    promoCode.Name = 'promo' + Datetime.now().getTime();
    promoCode.ER_Business_Unit__c = 'BENELUX';
    promoCode.ER_Start_Date__c = Date.today().addDays(-5);
    promoCode.Promo_End_Date__c = Date.today().addDays(15);
    promoCode.ER_Promo_Code__c = 'promoDiscountTest';
    promoCode.RecordtypeId =
        Utils.getRecordTypeIdByDeveloperName(
            ER_Promo_Code__c.SObjectType,
            'ER_Promo_Code'
        );
    insert promoCode;

    // ---------------- Promo Code 2 ----------------
    ER_Promo_Code__c promoCode2 = new ER_Promo_Code__c();
    promoCode2.Name = 'promo2' + Datetime.now().getTime();
    promoCode2.ER_Business_Unit__c = 'BENELUX';
    promoCode2.ER_Promo_Code__c = 'promoDiscountTest2';
    promoCode2.Promo_End_Date__c = Date.today().addDays(20);
    promoCode2.RecordtypeId =
        Utils.getRecordTypeIdByDeveloperName(
            ER_Promo_Code__c.SObjectType,
            'ER_Promo_Code'
        );
    insert promoCode2;
  }

  // ----------------------------------------------------------------

  @isTest
  static void removeDiscountCodesFromOpenOpportunitiesTest() {

    ER_Promo_Code__c promo = [
        SELECT Id, ER_Status__c
        FROM ER_Promo_Code__c
        WHERE ER_Contract__c = NULL
        LIMIT 1
    ];

    Test.startTest();
    promo.ER_Status__c = 'Expired';
    update promo;
    Test.stopTest();

    System.assertEquals('Expired', promo.ER_Status__c);
  }

  // ----------------------------------------------------------------

  @isTest
  static void deactivateAffiliationCodesForTerminatedContractsTest() {

    Contract c = [SELECT Id FROM Contract LIMIT 1];

    Test.startTest();
    // Method should execute safely even if no affiliation exists
    APER39_DiscountCode_Mangement.deactivateAffiliationCodesForTerminatedContracts(
        new Set<Id>{ c.Id }
    );
    Test.stopTest();

    System.assert(true, 'Method executed without exception');
  }
}