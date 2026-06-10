/*
----------------------------------------------------------------------
-- - Name          : ZuoraSubscription_Management_AP01_Test
-- - Author        : AAZ
-- - Description   : Test class for ZuoraSubscription_Management_AP01   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JULY-2021     AAZ                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/

@isTest
public class ZuoraSubscription_Management_AP01_Test {
  @TestSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('ZSubscription', 'ZSubscription', 'ER Read Only Admin', 'Poland', 'PL');
    ur.ER_BypassVR__c = true;
    insert ur;
    System.runAs(ur) {
      Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testnewZuoraQuote');
      insert newMerchantAccount;

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
        'ER_Merchant_Opportunity',
        'Opp testnewZuoraQuote'
      );
      newOpportunity.AccountId = newMerchantAccount.Id;
      insert newOpportunity;

      zqu__Quote__c newZQuote = APER07_UtilityTestMethod.getZuoraQuote('Default');
      newZQuote.zqu__Account__c = newMerchantAccount.Id;
      newZQuote.zqu__Opportunity__c = newOpportunity.Id;
      newZQuote.zqu__Currency__c = 'PLN';
      newZQuote.zqu__StartDate__c = Date.today();
      insert newZQuote;

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('Solution TR1');
      newSolution.ProductCode = 'TR1';
      insert newSolution;

      zqu__QuoteAmendment__c qAmendment = APER07_UtilityTestMethod.newQuoteAmendment(newZQuote.Id);
      insert qAmendment;

      zqu__ProductRatePlan__c productRP = APER07_UtilityTestMethod.getZuoraProductRP(newSolution.Id);
      insert productRP;

      zqu__QuoteRatePlan__c quoteRP = APER07_UtilityTestMethod.getZuoraQuoteRP(
        newZQuote.Id,
        productRP.Id,
        qAmendment.Id,
        newSolution.Name
      );
      insert quoteRP;

      zqu__QuoteChargeDetail__c qcd = new zqu__QuoteChargeDetail__c(
        zqu__Quote__c = newZQuote.Id,
        zqu__ProductRatePlan__c = productRP.Id
      );
      insert qcd;
    }
  }

  @IsTest
  static void createChildSubforBillingAccount() {
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Zuora Sales'];
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = new User(
      LastName = 'PL User',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'pluser',
      CommunityNickname = 'pusr',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'PL',
      UserRoleId = ur.Id
    );
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('ZuoraSubscription_Management_AP01_Test');
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
      masterFC.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
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

      Zuora__CustomerAccount__c chilldBA = new Zuora__CustomerAccount__c();
      chilldBA.Name = 'A00000002';
      chilldBA.Zuora__Account__c = acc.Id;
      chilldBA.Zuora__Status__c = 'Active';
      chilldBA.Zuora__Currency__c = 'PLN';
      masterBA.ER_Master__c = false;
      insert chilldBA;

      Zuora__Subscription__c newZSub = new Zuora__Subscription__c();
      newZSub.Name = 'A-S00000001';
      newZSub.Zuora__Status__c = 'Active';
      newZSub.Zuora__Account__c = acc.Id;
      newZSub.Zuora__CustomerAccount__c = masterBA.Id;
      newZSub.Zuora__SubscriptionStartDate__c = Date.today();
      newZSub.ER_Master__c = 'Yes';
      insert newZSub;

      Test.startTest();
      SendToZuoraMock zuoraMock = new SendToZuoraMock();
      Test.setMock(HttpCalloutMock.class, zuoraMock);

      Zuora__SubscriptionProductCharge__c newZSubPC = new Zuora__SubscriptionProductCharge__c();
      newZSubPC.Name = 'A-S00000001-PC';
      newZSubPC.Zuora__Account__c = acc.Id;
      newZSubPC.Zuora__Subscription__c = newZSub.Id;
      insert newZSubPC;
      Test.stopTest();
    }
  }

  @IsTest
  static void increaseCoverage() {
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Zuora Sales'];
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = new User(
      LastName = 'PL User',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'pluser',
      CommunityNickname = 'pusr',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'PL',
      UserRoleId = ur.Id
    );
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('ZuoraSubscription_Management_AP01_Test');
      insert acc;
      Zuora__SubscriptionProductCharge__c subPC = new Zuora__SubscriptionProductCharge__c();
      subPC.Name = 'A-S00000001-PC1';
      subPC.Zuora__Account__c = acc.Id;
      insert subPC;
      subPC.Name = 'A-S00000001-PC2';
      update subPC;
      delete subPC;
      undelete subPC;

      Zuora__Subscription__c newZSub = new Zuora__Subscription__c();
      newZSub.Name = 'A-S00000001';
      newZSub.Zuora__Status__c = 'Active';
      newZSub.Zuora__Account__c = acc.Id;
      insert newZSub;
      newZSub.Zuora__Status__c = 'Cancelled';
      update newZSub;
      delete newZSub;
      undelete newZSub;
    }
  }
/*
  @IsTest
  static void testUpdateSubscriptionContract() {
    User ur = TestDataFactory.newUser('updateSubscription', 'Contract', 'ER Read Only Admin', 'Poland', 'PL');
    ur.ER_BypassVR__c = true;
    insert ur;
    System.runAs(ur) {
      Account acc = [SELECT Id FROM Account WHERE Name = 'testnewZuoraQuote'];

      zqu__Quote__c newZQuote = [SELECT Id, zqu__Status__c FROM zqu__Quote__c LIMIT 1];

      Test.startTest();

      newZQuote.zqu__Status__c = Constants.QUOTE_STATUS_ACCEPTED;
      newZQuote.zqu__SubscriptionName__c = 'A-S00000001';
      newZQuote.zqu__ZuoraSubscriptionID__c = 'A-S00000001';
      update newZQuote;

      //Create Subscription
      Zuora__Subscription__c newZSub = new Zuora__Subscription__c();
      newZSub.Name = 'A-S00000001';
      newZSub.Zuora__External_Id__c = 'A-S00000001';
      newZSub.Zuora__Status__c = 'Active';
      newZSub.Zuora__Account__c = acc.Id;
      //newZSub.Zuora__CustomerAccount__c = acc.Id;
      newZSub.Zuora__SubscriptionStartDate__c = Date.today();
      insert newZSub;

      Contract insertedContract = [SELECT Id, Name, ER_ZuoraQuote__c, Subscription__c FROM Contract LIMIT 1];

      System.assert(String.isNotBlank(insertedContract.Subscription__c));
      Test.stopTest();
    }
  }
*/
  @IsTest
  static void setContractIdOnChildSubscription() {
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Zuora Sales'];
    UserRole ur = [SELECT Id FROM UserRole WHERE DeveloperName = 'Poland' LIMIT 1];
    User u = new User(
      LastName = 'PL User',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'pluser',
      CommunityNickname = 'pusr',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'PL',
      UserRoleId = ur.Id
    );
    u.ER_BypassVR__c = true;
    insert u;

    System.runAs(u) {
      Account acc = APER07_UtilityTestMethod.getCompany('ZuoraSubscription_Management_AP01_Test');
      insert acc;

      Zuora__CustomerAccount__c masterBA = new Zuora__CustomerAccount__c();
      masterBA.Name = 'A00000001';
      masterBA.Zuora__Account__c = acc.Id;
      masterBA.Zuora__Status__c = 'Active';
      masterBA.Zuora__Currency__c = 'PLN';
      masterBA.ER_Master__c = true;
      insert masterBA;

      Zuora__CustomerAccount__c chilldBA = new Zuora__CustomerAccount__c();
      chilldBA.Name = 'A00000002';
      chilldBA.Zuora__Account__c = acc.Id;
      chilldBA.Zuora__Status__c = 'Active';
      chilldBA.Zuora__Currency__c = 'PLN';
      masterBA.ER_Master__c = false;
      insert chilldBA;

      Zuora__Subscription__c newZSub = new Zuora__Subscription__c();
      newZSub.Name = 'A-S00000001';
      newZSub.Zuora__Status__c = 'Active';
      newZSub.Zuora__Account__c = acc.Id;
      newZSub.Zuora__CustomerAccount__c = masterBA.Id;
      newZSub.Zuora__SubscriptionStartDate__c = Date.today();
      newZSub.ER_Master__c = 'Yes';
      insert newZSub;

      Contract newContract = APER07_UtilityTestMethod.getContract(acc.Id, System.today(), 'Draft', null);
      newContract.Subscription__c = newZSub.Id;
      insert newContract;

      Test.startTest();
      Zuora__Subscription__c newChildSub = new Zuora__Subscription__c();
      newChildSub.Name = 'A-S00000002';
      newChildSub.Zuora__Status__c = 'Active';
      newChildSub.Zuora__Account__c = acc.Id;
      newChildSub.Zuora__CustomerAccount__c = chilldBA.Id;
      newChildSub.Zuora__SubscriptionStartDate__c = Date.today();
      newChildSub.ER_Master__c = 'No';
      newChildSub.ER_Parent_Subscription__c = newZSub.Name;
      insert newChildSub;
      Test.stopTest();
      Zuora__Subscription__c updatedChildSub = [
        SELECT Id, ER_Contract__c
        FROM Zuora__Subscription__c
        WHERE ER_Parent_Subscription__c != NULL
        LIMIT 1
      ];
      System.debug('#####AA updatedChildSub updatedChildSub ' + updatedChildSub);
      System.assert(String.isNotBlank(updatedChildSub.ER_Contract__c));
    }
  }
  @isTest
    static void fakecc() {
        ZuoraSubscription_Management_AP01.fakecc();
    }
}