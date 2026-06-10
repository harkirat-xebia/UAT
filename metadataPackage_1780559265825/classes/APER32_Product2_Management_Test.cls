/*
----------------------------------------------------------------------
-- - Name          : APER32_Product2_Management_Test
-- - Author        : AAZ
-- - Description   : Test class for APER32_Product2_Management     
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JUN-2021     AAZ                   1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class APER32_Product2_Management_Test {
  @testSetup
  static void testSetup() {
    String testedBU = 'BE';
    User ur = TestDataFactory.newUser('APER32', 'APER32', 'Local Admin', testedBU);
    ur.ER_BypassVR__c = true;
    insert ur;
    UtilsBypass.reset();

    System.runAs(ur) {
      PriceBook2 standardPricebook = APER07_UtilityTestMethod.getpriceBook();
      standardPricebook.ER_Business_Unit__c = 'BE';
      //update standardPricebook;

      Product2 solution = APER07_UtilityTestMethod.getsolution('APER32_Solution');
      insert solution;

      Product2 serviceProduct = APER07_UtilityTestMethod.getservice('APER32_Service', solution.Id);
      insert serviceProduct;
    }
  }

  @IsTest
  static void testActivateZuoraProducts() {
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
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
      Test.startTest();
      Product2 prod2 = new Product2(
        Name = 'Zuora Product',
        zqu__ZuoraId__c = '8adc9dee78ef34580178f4a8d41436b4',
        ER_Business_Unit__c = 'PL',
        zqu__EffectiveStartDate__c = Date.today(),
        zqu__EffectiveEndDate__c = Date.today().addDays(100)
      );
      insert prod2;

      prod2.zqu__EffectiveEndDate__c = null;
      update prod2;
      Test.stopTest();

      Product2 inertedPdct = [
        SELECT Id, IsActive, CurrencyIsoCode
        FROM Product2
        WHERE zqu__ZuoraId__c = '8adc9dee78ef34580178f4a8d41436b4'
        LIMIT 1
      ];
      System.assertEquals(true, inertedPdct.IsActive);
      System.assertEquals('PLN', inertedPdct.CurrencyIsoCode);

      List<PricebookEntry> inertedPBE = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];
      //System.assertEquals(inertedPdct.Id, inertedPBE.Product2Id);
    }
  }

  @IsTest
  static void testRangeProductCreation() {
    Test.startTest();
    User u = [SELECT Id FROM User WHERE LastName = 'APER32'];

    System.runAs(u) {
      Id recordTypeId = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Range');
      Product2 service = [SELECT Id, ER_Service_Number_of_Ranges__c FROM Product2 WHERE Name = 'APER32_Service'];
      System.assertEquals(service.ER_Service_Number_of_Ranges__c, 0);
      Product2 range = APER07_UtilityTestMethod.getProduct('rangeTest');
      range.RecordTypeId = recordTypeId;
      range.ER_Solution__c = service.Id;
      insert range;

      service = [SELECT Id, ER_Service_Number_of_Ranges__c FROM Product2 WHERE Name = 'APER32_Service'];
      //System.assertEquals(service.ER_Service_Number_of_Ranges__c, 1);
    }

    Test.stopTest();
  }

  @IsTest
  static void testDiscountProductCreation() {
    Test.startTest();
    User u = [SELECT Id FROM User WHERE LastName = 'APER32'];

    System.runAs(u) {
      Id recordTypeId = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Discount');
      Product2 service = [SELECT Id, ER_Service_Number_of_Ranges__c FROM Product2 WHERE Name = 'APER32_Service'];
      Id recordTypeIdRange = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Range');
      Product2 range = APER07_UtilityTestMethod.getProduct('rangeTest');
      range.RecordTypeId = recordTypeIdRange;
      range.ER_Solution__c = service.Id;
      insert range;

      Product2 discount = APER07_UtilityTestMethod.getProduct('discountTest');
      discount.RecordTypeId = recordTypeId;
      discount.ER_Solution__c = range.Id;
      insert discount;

      discount = [
        SELECT Id, ER_Solution2__c, ER_Solution__r.ER_Solution__r.ER_Solution__c
        FROM Product2
        WHERE Id = :discount.Id
      ];

      System.assertEquals(discount.ER_Solution2__c, discount.ER_Solution__r.ER_Solution__r.ER_Solution__c);
    }
    Test.stopTest();
  }

  @IsTest
  static void testGetSolutionId() {
    Test.startTest();
    User u = [SELECT Id FROM User WHERE LastName = 'APER32'];

    System.runAs(u) {
      APER32_Product2_Management.getSolutionId('APER32_Solution');
    }
    Test.stopTest();
  }
}