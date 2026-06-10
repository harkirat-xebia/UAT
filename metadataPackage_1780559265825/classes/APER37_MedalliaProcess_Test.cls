@IsTest
public class APER37_MedalliaProcess_Test {
  /*@IsTest
  public static void sendInvitationWhenFirstVisitChangedTest() {
    User u = TestDataFactory.newUser('FirstName', 'LastName', 'System Administrator', 'ES');
    u.ER_BypassVR__c = true;
    insert u;

    System.runAs(u) {
      //Create testData
      Account acct = APER36_TestDataFactory_Medallia.getAccount('Medalia Account');
      System.debug('>>>>> ALK - acct : ' + acct);
      Contact con = APER36_TestDataFactory_Medallia.getContactWithAccount('Medallia', 'Contact', acct.Id); //contact with both Client and Merchant link - > should be client
      System.debug('>>>>> ALK - con : ' + con);
      Opportunity oppyClient = APER36_TestDataFactory_Medallia.getOpportunity(
        'ER_Client_Opportunity_RT',
        'Client Opportunity' + Datetime.now().getTime(),
        acct.Id
      );
      System.debug('>>>>> ALK - oppyClient : ' + oppyClient);
      Opportunity oppyMerchant = APER36_TestDataFactory_Medallia.getOpportunity(
        'ER_Merchant_Opportunity',
        'Merchant Opportunity' + Datetime.now().getTime(),
        acct.Id
      );
      OpportunityContactRole ocrClient = APER36_TestDataFactory_Medallia.getOpportunityContactRole(
        oppyClient.Id,
        con.Id
      );
      OpportunityContactRole ocrMerchant = APER36_TestDataFactory_Medallia.getOpportunityContactRole(
        oppyMerchant.Id,
        con.Id
      );
      ER_Financial_Center__c fcClient = APER36_TestDataFactory_Medallia.getFinancialCenterWithContact(
        'Client fc',
        acct.Id,
        'Client',
        con.Id
      );
      ER_Financial_Center__c fcMerchant = APER36_TestDataFactory_Medallia.getFinancialCenterWithContact(
        'Merchant fc',
        acct.Id,
        'Merchant',
        con.Id
      );
      ER_Store__c store = APER36_TestDataFactory_Medallia.getStoreWithContact(
        'Medallia store',
        acct.Id,
        fcMerchant.Id,
        con.Id
      );
      ER_Delivery_Site__c ds = APER36_TestDataFactory_Medallia.getDeliverySite(acct.Id, con.Id);
      ER_Distribution_Point__c dp = APER36_TestDataFactory_Medallia.getDistributionPoint(ds.Id);
      ER_Contact_Role__c cr1 = APER36_TestDataFactory_Medallia.getContactRoleWithFinancialCenter(con.Id, fcClient.Id);
      ER_Contact_Role__c cr2 = APER36_TestDataFactory_Medallia.getContactRoleWithFinancialCenter(con.Id, fcMerchant.Id);
      ER_Contact_Role__c cr3 = APER36_TestDataFactory_Medallia.getContactRoleWithStore(con.Id, store.Id);
      ER_Contact_Role__c cr4 = APER36_TestDataFactory_Medallia.getContactRoleWithDeviverySite(con.Id, ds.Id);
      ER_Contact_Role__c cr5 = APER36_TestDataFactory_Medallia.getContactRoleWithDistributionPoint(con.Id, dp.Id);

      Contact conClient = APER36_TestDataFactory_Medallia.getContactWithAccount('Client', 'Contact', acct.Id); // contact without any link -> should be Client
      Contact conMerchant = APER36_TestDataFactory_Medallia.getContactWithAccount('Merchant', 'Contact', acct.Id); //contact with Merchant link - > should be Merchant
      OpportunityContactRole ocr = APER36_TestDataFactory_Medallia.getOpportunityContactRole(
        oppyMerchant.Id,
        conMerchant.Id
      );

      acct.ER_First_visit__c = Date.today();
      update acct;
    }
  }*/
}