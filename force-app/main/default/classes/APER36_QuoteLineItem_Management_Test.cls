/**
 * @author Noor
 * @date 25/01/2022.
 * @description APER36_QuoteLineItem_Management_Test
 * @see APER36_QuoteLineItem_Management
 */
@IsTest
private class APER36_QuoteLineItem_Management_Test {
  @testSetup
  static void testSetup() {
    User ur = TestDataFactory.newUser('APER36', 'APER36', 'Local Admin', 'BELUX', 'BE');
    ur.ER_BypassVR__c = true;
    insert ur;
    System.runAs(ur) {
      Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany');
      insert newMerchantAccount;

      PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();
      update standardPriceBook;

      PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('ERBE MERCHANT');
      insert newPriceBook;

      Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER36', 'APER36');
      newContact.ER_Language__c = 'FR';
      insert newContact;

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'ERBE_ER_01;ERBE_ER_02';
      insert newSolution;

      Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
      insert newService;

      PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
        standardPriceBook.id,
        newService.id
      );
      insert standardPriceBookEntry;

      PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
      insert newPriceBookEntry;

      Contract con = APER07_UtilityTestMethod.getContract(
        newMerchantAccount.Id,
        System.today(),
        'Draft',
        newPriceBook.Id
      );
      insert con;

      Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'APER36');
      newOpportunity.AccountId = newMerchantAccount.Id;
      newOpportunity.ContractId = con.Id;
      newOpportunity.Pricebook2Id = newPriceBook.Id;
      insert newOpportunity;

      OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
        newOpportunity.id,
        newPriceBookEntry.id
      );
      insert newOpportunityProduct;

      Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
        'ER_Merchant_Quote',
        'APER36',
        newOpportunity.id,
        newPriceBook.id
      );
      merchantQuote.ContactId = newContact.Id;
      insert merchantQuote;

      QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
      insert qli;
    }
  }

  @IsTest
  static void testBehavior() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER36'];
    System.runAs(u) {
      Quote q = [SELECT Id, ER_DocuGen_Solution__c FROM Quote LIMIT 1];

      System.assertEquals(
        Constants.DELIMITER_PIPE +
        'ERBE_ER_01' +
        Constants.DELIMITER_PIPE +
        'ERBE_ER_02' +
        Constants.DELIMITER_PIPE,
        q.ER_DocuGen_Solution__c
      );

      test.startTest();

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution2');
      newSolution.ProductCode = 'ERBE_ER_04';
      insert newSolution;

      Product2 newService = APER07_UtilityTestMethod.getservice('testService2', newSolution.id);
      insert newService;

      Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE];
      Pricebook2 priceBook = [SELECT Id FROM Pricebook2 WHERE Name = 'ERBE MERCHANT'];

      PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
        standardPriceBook.id,
        newService.id
      );
      insert standardPriceBookEntry;

      PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(priceBook.id, newService.id);
      insert newPriceBookEntry;

      QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(q.id, newPriceBookEntry.id);
      insert qli;

      q = [SELECT Id, ER_DocuGen_Solution__c FROM Quote LIMIT 1];

      System.assert(
        q.ER_DocuGen_Solution__c.contains(Constants.DELIMITER_PIPE + 'ERBE_ER_01' + Constants.DELIMITER_PIPE)
      );
      System.assert(
        q.ER_DocuGen_Solution__c.contains(Constants.DELIMITER_PIPE + 'ERBE_ER_02' + Constants.DELIMITER_PIPE)
      );
      System.assert(
        q.ER_DocuGen_Solution__c.contains(Constants.DELIMITER_PIPE + 'ERBE_ER_04' + Constants.DELIMITER_PIPE)
      );

      delete qli;

      q = [SELECT Id, ER_DocuGen_Solution__c FROM Quote LIMIT 1];

      System.assertEquals(
        Constants.DELIMITER_PIPE +
        'ERBE_ER_01' +
        Constants.DELIMITER_PIPE +
        'ERBE_ER_02' +
        Constants.DELIMITER_PIPE,
        q.ER_DocuGen_Solution__c
      );

      test.stopTest();
    }
  }

  @IsTest
  static void testblockQuoteLineItemDeletion() {
    User ur = [SELECT Id FROM User WHERE LastName = 'APER36'];
    ur.ER_BypassVR__c = false;
    update ur;
    System.runAs(ur) {
      QuoteLineItem qli2 = [SELECT Id FROM QuoteLineItem LIMIT 1];
      System.debug('### CWAN qli2 : ' + qli2);
      Test.startTest();
      try {
        delete qli2;
      } catch (Exception ex) {
        Boolean expectedExceptionThrown = ex.getMessage().contains(Label.LABS_SF_Quote_Line_Item_block_delete)
          ? true
          : false;
        System.assertEquals(expectedExceptionThrown, true);
      }
      Test.stopTest();
    }

  }

  @IsTest
  static void testGetProductsNameTranslations() {
    User u = [SELECT Id FROM User WHERE LastName = 'APER36'];
    System.runAs(u) {
      Quote q = [SELECT Id, ER_DocuGen_Solution__c, ER_DocuGen_Contact_Preferred_Language__c FROM Quote LIMIT 1];

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution2');
      newSolution.ProductCode = 'ERBE_ER_04';
      insert newSolution;

      Product2 newService = APER07_UtilityTestMethod.getservice('testService2', newSolution.id);
      insert newService;

      Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE];
      Pricebook2 priceBook = [SELECT Id FROM Pricebook2 WHERE Name = 'ERBE MERCHANT'];

      PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
        standardPriceBook.id,
        newService.id
      );
      insert standardPriceBookEntry;

      PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(priceBook.id, newService.id);
      insert newPriceBookEntry;

      List<ER_Translation__c> listTrans = new List<ER_Translation__c>();
      ER_Translation__c translation = new ER_Translation__c();
      translation.Field_API_Name__c = 'Name';
      translation.Product__c = newService.Id;
      translation.Language__c = 'fr';
      translation.Text__c = 'translatedText';
      listTrans.add(translation);
      translation = new ER_Translation__c();
      translation.Field_API_Name__c = 'Name';
      translation.Product__c = newSolution.Id;
      translation.Language__c = 'fr';
      translation.Text__c = 'translatedSol';
      listTrans.add(translation);
      insert listTrans;

      test.startTest();
      QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(q.id, newPriceBookEntry.id);
      insert qli;

      test.stopTest();
    }
  }
}