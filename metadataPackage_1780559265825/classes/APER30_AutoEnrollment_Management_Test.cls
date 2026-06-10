/**
 * @description       :
 * @author            : AAM
 * @group             :
 * @last modified on  : 07-07-2023
 * @last modified by  : Hassan DAKHCHA
 * Modifications Log
 * Ver   Date         Author    Modification
 * 1.0   05-17-2021   AAM       Initial Version
 **/

@isTest
public without sharing class APER30_AutoEnrollment_Management_Test {
  //TODO asserts, negative tests
/*
  @isTest
  static void testAutoEnrollment() {
    // TODO to be splitted? and renamed
    String merchantInfosJSON = '{"enterpriseNb":"0451710489","storesList":[],"finCentersList":[],"isReadOnly":"false","company":"PRUNELLI","phone":"+32 2 212 11 99","legalForm":"Société privée à responsabilité limitée","legalName":"","address":"Rue du palais 645","postalCode":"1190","city":"BRUXELLES","country":"BELGIUM","countryCode":"BE"}';

    SendToZuoraMock mock = new SendToZuoraMock();
    Test.setMock(HttpCalloutMock.class, mock);

    TestDataFactory.insertProducts('Ticket Restaurant Électronique', 'ERBE_TRE-M', 'BENELUX', 'M', 'ERBE Merchant');
    TestDataFactory.insertPromoCode('TestPromo', 'BENELUX');
    TestDataFactory.insertTermsAndConditions('BE', 'FR', 'ERBE_TRE-M', 'M');
    TestDataFactory.insertPDFContract('BE', 'FR', 'ERBE_TRE-M', 'M');

    String solutionId = [
      SELECT Id
      FROM Product2
      WHERE
        BU_External_Reference__c = 'ERBE_TRE-M'
        AND ER_BUPicklist__c = 'BENELUX'
        AND ER_MUC__c = 'M'
        AND ER_Type__c = 'Solution'
        AND IsActive = TRUE
    ][0]
    .Id;

    String storeCatId = TestDataFactory.insertStoreCategory(solutionId, 'FR', 'BENELUX');

    User userAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE][0];
    Lead ld;

    System.runAs(userAdmin) {
      User userBE = TestDataFactory.newUser('Michel', 'Dupont', 'Local Admin', 'BENELUX');
      userBE.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'BELUX'][0].Id;
      insert userBE;
    }

    User userGuest = [SELECT Id, Name FROM User WHERE Profile.Name = 'Edenred portal Profile'][0];
    String curUserId = UserInfo.getUserId();
    String leadId;

    // Create other lead to fully cover getLeadOwnerId method
    ID merchantLeadRecTypId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT');
    Lead lead1 = APER07_UtilityTestMethod.getLead(merchantLeadRecTypId);
    lead1.ER_External_Reference__c = 'BE001221222';
    lead1.ER_Lead_Channel__c = 'Merchant';
    lead1.ER_Lead_Type__c = System.label.LAB_SF_Lead_Type_Merchant;
    lead1.OwnerId = userAdmin.Id;
    insert lead1;

    ContentVersion samplePDF = new ContentVersion(
      Title = 'Merchant Contract TRE FR',
      PathOnClient = 'Edenred Contract.pdf',
      VersionData = Blob.valueof('test'),
      origin = 'H',
      IsMajorVersion = false
    );
    insert samplePDF;

    System.runAs(userGuest) {
      // Get infos from Belfirst
      GenericWithoutSharing.getEnterpriseInfos('0123456789', 'BE', 'FR', '', 'alain.michel@prunelli.be');

      // Lead creation
      TestDataFactory.insertCampaign('BE Campaign test', '00000', 'BENELUX');
      Map<String, String> result = APER30_AutoEnrollment_Management.upsertLead(merchantInfosJSON, '00000');
      leadId = result.get('leadId');
      System.debug('>>>> APER30 testAutoEnrollment - leadId: ' + leadId);

      // Check lead after insert
      GenericWithoutSharing.getEnterpriseInfos('0451710489', 'BE', 'FR', '', 'alain.michel@prunelli.be');

      // Lead update after contact infos collect
      merchantInfosJSON =
        '{"enterpriseNb":"0451710489","storesList":[],"finCentersList":[],"isReadOnly":"false","company":"PRUNELLI","phone":"+32 2 212 11 98","legalForm":"Société privée à responsabilité limitée","legalName":"MARELLI","address":"Rue Bollinckx 241-3","postalCode":"1190","city":"BRUXELLES","country":"BELGIUM","countryCode":"BE","leadId":"' +
        leadId +
        '","salutation":"Mr.","hasVATCode":true,"enterpriseVATCode":"BE0451710489","firstName":"Alain","lastName":"Michel","lang":"FR","contactPhone":"+32 2 414 89 77","email":"alain.michel@prunelli.be","fax":"+32 2 212 11 66","mobile":"+32 6 313 26 03"}';
      APER30_AutoEnrollment_Management.upsertLead(merchantInfosJSON, '');
      Test.getEventBus().deliver();

      // Check lead after update (with contact infos)
      GenericWithoutSharing.getEnterpriseInfos('0451710489', 'BE', 'FR', '', 'alain.michel@prunelli.be');

      // Lead conversion
      String leadIdParamJSON = '{"leadId": "' + leadId + '"}';

      APER30_AutoEnrollment_Management.doApexEvent('convertLead', merchantInfosJSON);
      Test.getEventBus().deliver();

      // Check account after lead conversion
      GenericWithoutSharing.getEnterpriseInfos('0451710489', 'BE', 'FR', '', 'alain.michel@prunelli.be');
    }

    // Test.startTest();
    // // To avoid MIXED_DML_OPERATION
    // Test.stopTest();

    // Update opportunity (set the right pricebook)
    System.debug('>>>> APER30 testAutoEnrollment - start updateOpportunity ');
    APER30_AutoEnrollment_Management.doApexEvent('updateOpportunity', leadId + '|TestPromo|ERBE_TRE-M|M'); // Test promo code case
    Test.getEventBus().deliver();
    APER30_AutoEnrollment_Management.doApexEvent('updateOpportunity', leadId + '||ERBE_TRE-M|M');
    Test.getEventBus().deliver();
    System.debug('>>>> APER30 testAutoEnrollment - after updateOpportunity ');

    // Create financial centers
    String finCenterJSON = '[{"name":"Centre financier 1","contact":"Jean-Claude Dupont","fullAddress":"Prolongement de la maison 33, 4040 HERSTAL","iban":"BE52812615696709","bic":"AXABBE22","bankName":"AXA Bank Belgium","ibanBilling":"BE56456884597688","bicBilling":"KREDBEBB","bankNameBilling":"KBC Bank","countryCode":"BE","refundSalutation":"Mr.","refundFirstName":"Jean-Claude","refundLastName":"Dupont","refundLang":"EN","refundContactPhone":"0476963945","refundEmail":"jcd@prunelli.be","refundAddress":"Prolongement de la maison 33","refundPostalCode":"4040","refundCity":"HERSTAL","refundCountry":"BELGIUM","finCenterId":1}]';
    String finCenterParam = leadId + '|' + finCenterJSON;
    APER30_AutoEnrollment_Management.doApexEvent('createFinCenters', finCenterParam);
    Test.getEventBus().deliver();

    String accountId = [SELECT ConvertedAccountId FROM Lead WHERE Id = :leadId][0].ConvertedAccountId;
    for (ER_Financial_Center__c fc : [
      SELECT Id, Name, ER_Contact__c, ER_Bank_Account__c, ER_Street__c, ER_City__c, ER_Zip_Code__c, ER_Country__c
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c = :accountId AND ER_Type__c = 'Merchant'
    ])
      System.debug(
        '>>>> APER30 testAutoEnrollment -- ER_Bank_Account__c - ER_Contact__c: ' +
          fc.ER_Bank_Account__c +
          ' - ' +
          fc.ER_Contact__c
      );

    // Create stores
    String storeJSON =
      '[ { "name": "Store1", "fullAddress": "Prolongement de la maison 33, 4040 HERSTAL", "websiteDisplay": " ", "address": "Prolongement de la maison 33", "postalCode": "4040", "city": "HERSTAL", "country": "BELGIUM", "countryCode": "BE", "isFranchisee": "Yes", "sector": "Local Store TRE", "showFranchiseeField": true, "franchiseeBrand": "Ald", "mid": "0123456", "finCenterId": 1, "storeId": 1, "terminalsList": [], "terminalInfos": {}, "picklistGroup": { "terminalProvider": [ { "key": "...", "value": "", "hidden": true }, { "key": "Adyen", "value": "Adyen" }, { "key": "Atos-Worldline", "value": "Atos-Worldline" }, { "key": "Bepax-Paynation", "value": "Bepax-Paynation" }, { "key": "Bevo", "value": "Bevo" }, { "key": "CCV", "value": "CCV" }, { "key": "Chess", "value": "Chess" }, { "key": "Easy Payments", "value": "Easy Payments" }, { "key": "European merchant services", "value": "European merchant services" }, { "key": "Hypercom/BS Cards", "value": "Hypercom/BS Cards" }, { "key": "Ingenico Payment Services", "value": "Ingenico Payment Services" }, { "key": "Keyware", "value": "Keyware" }, { "key": "Loyaltek", "value": "Loyaltek" }, { "key": "N-TS", "value": "N-TS" }, { "key": "Payleven", "value": "Payleven" }, { "key": "Payworld", "value": "Payworld" }, { "key": "Sepay", "value": "Sepay" }, { "key": "SIX - Carrefour", "value": "SIX - Carrefour" }, { "key": "Six Payments", "value": "Six Payments" }, { "key": "Six Payments - BNP", "value": "Six Payments - BNP" }, { "key": "SUM UP", "value": "SUM UP" }, { "key": "EMS", "value": "EMS" }, { "key": "VivaWallet", "value": "VivaWallet" }, { "key": "GlobalPay", "value": "GlobalPay" }, { "key": "Mypos", "value": "Mypos" }, { "key": "Nayax", "value": "Nayax" }, { "key": "Xafaw", "value": "Xafaw" }, { "key": "Dover Fueling Solutions", "value": "Dover Fueling Solutions" } ], "terminalModel": [], "isLinkedToCashReg": [ { "key": "", "value": "", "selected": false, "hidden": true }, { "key": "Yes", "value": "Oui", "selected": false, "hidden": false }, { "key": "No", "value": "Non", "selected": false, "hidden": false } ] }, "storeContactSalutation": "Mr.", "storeContactFirstName": "Louis", "storeContactLastName": "Ferray", "storeContactEmail": "louis.ferray@mail.com", "storeContactLanguage": "FR", "rowIndex": 0, "chosenCategories":[{"id":"' +
      storeCatId +
      '","isMain":"true","isChecked":"true"}] } ]';
    String storeParam = leadId + '|' + storeJSON;
    APER30_AutoEnrollment_Management.doApexEvent('createStores', storeParam);
    Test.getEventBus().deliver();

    // String accountId = [SELECT ConvertedAccountId FROM Lead WHERE Id  = :leadId][0].ConvertedAccountId;
    System.debug('>>>>  APER30 testAutoEnrollment -- accountId: ' + accountId);
    GenericWithoutSharing.getFinCentersInfos(accountId);

    GenericWithoutSharing.getStoresInfos(accountId, 'fr_BE');
    GenericWithoutSharing.getCategories('BE', 'ERBE_TRE-M', null);

    // Create terminals
    storeJSON =
      '[{"name":"Store1","fullAddress":"Prolongement de la maison 33, 4040 HERSTAL","websiteDisplay":" ","address":"Prolongement de la maison 33","postalCode":"4040","city":"HERSTAL","countryCode":"BE","isFranchisee":"No","sector":"Local Store TRE","showFranchiseeField":false, "hasOnlineStore": "true", "hasAgregator": "true", "mid": "0123456","finCenterId":1,"storeId":1,"terminalsList":[{"terminalProvider":"Atos-Worldline","terminalModel":"CZAM/XENTA-M1","terminalModelDisplayValue":"CZAM/XENTA-M1","tid":"01234587","cashRegisterProvider":"Ingenico","isLinkedToCashReg":"Yes","isLinkedToCashRegDisplayValue":"Oui", "mid2": "0123456", "isMastercardOnly": "false", "terminalId":1,"storeId":1,"rowIndex":0}],"terminalInfos":{"terminalProvider":"Atos-Worldline","terminalModel":"CZAM/XENTA-M1","terminalModelDisplayValue":"CZAM/XENTA-M1","tid":"01245879","cashRegisterProvider":"Ingenico","isLinkedToCashReg":"Yes","isLinkedToCashRegDisplayValue":"Oui", "isMastercardOnly": "false", "terminalId":1,"storeId":1,"rowIndex":0},"picklistGroup":{"terminalProvider":[{"key":"...","value":"","hidden":true,"selected":false},{"key":"Adyen","value":"Adyen","selected":false},{"key":"Atos-Worldline","value":"Atos-Worldline","selected":true},{"key":"Bepax-Paynation","value":"Bepax-Paynation","selected":false},{"key":"Bevo","value":"Bevo","selected":false},{"key":"CCV","value":"CCV","selected":false},{"key":"Chess","value":"Chess","selected":false},{"key":"Easy Payments","value":"Easy Payments","selected":false},{"key":"European merchant services","value":"European merchant services","selected":false},{"key":"Hypercom/BS Cards","value":"Hypercom/BS Cards","selected":false},{"key":"Ingenico Payment Services","value":"Ingenico Payment Services","selected":false},{"key":"Keyware","value":"Keyware","selected":false},{"key":"Loyaltek","value":"Loyaltek","selected":false},{"key":"N-TS","value":"N-TS","selected":false},{"key":"Payleven","value":"Payleven","selected":false},{"key":"Payworld","value":"Payworld","selected":false},{"key":"Sepay","value":"Sepay","selected":false},{"key":"SIX - Carrefour","value":"SIX - Carrefour","selected":false},{"key":"Six Payments","value":"Six Payments","selected":false},{"key":"Six Payments - BNP","value":"Six Payments - BNP","selected":false},{"key":"SUM UP","value":"SUM UP","selected":false},{"key":"EMS","value":"EMS","selected":false},{"key":"VivaWallet","value":"VivaWallet","selected":false},{"key":"GlobalPay","value":"GlobalPay","selected":false},{"key":"Mypos","value":"Mypos","selected":false},{"key":"Nayax","value":"Nayax","selected":false},{"key":"Xafaw","value":"Xafaw","selected":false},{"key":"Dover Fueling Solutions","value":"Dover Fueling Solutions","selected":false}],"terminalModel":[{"key":"...","value":"","hidden":true,"selected":false},{"key":"CZAM/XENTA-M1","value":"CZAM/XENTA-M1","selected":false},{"key":"CZAM/XENTA-M2","value":"CZAM/XENTA-M2","selected":false},{"key":"CZAM/XENTA-M1","value":"CZAM/XENTA-M1","selected":true},{"key":"XENTEO","value":"XENTEO","selected":false},{"key":"XENTIM","value":"XENTIM","selected":false},{"key":"XENTISSIMO","value":"XENTISSIMO","selected":false},{"key":"YOMANI PTI","value":"YOMANI PTI","selected":false},{"key":"YOMANI Retail M1","value":"YOMANI Retail M1","selected":false},{"key":"YOMANI Retail M2","value":"YOMANI Retail M2","selected":false},{"key":"YOMOVA","value":"YOMOVA","selected":false},{"key":"YONEO","value":"YONEO","selected":false},{"key":"YOXIMO","value":"YOXIMO","selected":false},{"key":"Other","value":"Autre","selected":false}],"isLinkedToCashReg":[{"key":"","value":"","selected":false,"hidden":true},{"key":"Yes","value":"Oui","selected":true,"hidden":false},{"key":"No","value":"Non","selected":false,"hidden":false}]},"rowIndex":0,"showContent":true,"hasTerminal":true, "chosenCategories":[{"id":"' +
      storeCatId +
      '","isMain":"true","isChecked":"true"}] } ]';
    storeParam = leadId + '|' + storeJSON;
    APER30_AutoEnrollment_Management.doApexEvent('createTerminals', storeParam);
    Test.getEventBus().deliver();

    GenericWithoutSharing.checkExistingAcceptor('tid', '0123456');

    //TODO
    String opportunityParamsJSON =
      '{"leadId": "' +
      leadId +
      '", "country": "BE", "contactEmail": "alain.michel@prunelli.be", "lang": "FR", "solution": "ERBE_TRE-M", "promoCode": "", "scope": "M", "versionId": "1"}';
    APER30_AutoEnrollment_Management.doApexEvent('closeOpportunity', opportunityParamsJSON);
    Test.getEventBus().deliver();

    Opportunity opp = [
      SELECT Id, AccountId, ER_BUPicklist__c, ContractId
      FROM Opportunity
      WHERE AccountId = :accountId
    ][0];

    // Create users (after contract creation)
    String usersJSON =
      '[{"userSFId": "", "contractNb": "", "userSalutation": "Mr.", "userFirstName": "John", "userLastName": "Smith", "userEmail": "john.smith@test.com", "userLanguage": "FR", "contractId": "' +
      opp.ContractId +
      '"}]';
    String createUserParams = accountId + '|' + usersJSON;
    APER30_AutoEnrollment_Management.doApexEvent('createUsers', createUserParams);
    Test.getEventBus().deliver();

    // Contract activation
    String oppSerial = JSON.serialize(opp);
    String activateContractParams =
      opp.ContractId +
      '|' +
      oppSerial +
      '|FR|ERBE_TRE-M|M|alain.michel@prunelli.be|Ticket Restaurant Digital|sales@mail.com';
    APER30_AutoEnrollment_Management.doApexEvent('activateContract', activateContractParams);
    Test.getEventBus().deliver();

    PageReference pdf = Page.AutoEnrollmentPDFContract;
    pdf.getParameters().put('solutionCode', 'ERBE_TRE-M');
    pdf.getParameters().put('accId', accountId);
    pdf.getParameters().put('oppId', opp.Id);
    pdf.getParameters().put('lang', 'FR');
    pdf.getParameters().put('scope', 'M');
    Test.setCurrentPage(pdf);

    APER30_PDFContractController pdfController = new APER30_PDFContractController();

    // Test.stopTest();
    // }

    System.debug('>>>>  APER30 testAutoEnrollment visible prods ' + [SELECT Id FROM Product2].size());
    System.debug('>>>>  APER30 testAutoEnrollment *** END *** ');
  }
*/
  @isTest
  static void testGetDatas() {
    TestDataFactory.insertProducts('Ticket Restaurant Électronique', 'ERBE_TRE-M', 'BENELUX', 'M', 'ERBE Merchant');
    TestDataFactory.insertTermsAndConditions('BE', 'FR', 'TRE', 'M');
    TestDataFactory.insertPDFContract('BE', 'FR', 'TRE', 'M');
    TestDataFactory.insertPromoCode('TestPromo', 'BENELUX');

    Test.setMock(HttpCalloutMock.class, new APER30_AutoEnrollment_Management_Test.GetBIC_Mock());

    Test.startTest();
    APER30_AutoEnrollment_Management.getLabels('BE', 'M');
    APER30_AutoEnrollment_Management.getPicklistInfos('BE', 'FR', 'M');
    GenericWithoutSharing.getFinancialConditions('BE', 'ERBE_TRE-M', '', 'M', '', 'FR');
    GenericWithoutSharing.getFinancialConditions('BE', 'ERBE_TRE-M', 'TestPromo', 'M', '', 'FR'); // Promo code case
    APER30_AutoEnrollment_Management.getBIC('BE52812615696709');
    APER30_AutoEnrollment_Management.getAcceptorModels();
    APER30_AutoEnrollment_Management.checkCity('BE', 'BRUSSELS', '1000');
    APER30_AutoEnrollment_Management.checkCity('BE', 'Paris', '9999'); // false case
    APER30_AutoEnrollment_Management.getTermsAndConditions('BE', 'FR', 'ERBE_TRE-M', 'M');

    // getEnterpriseInfos
    Test.stopTest();
  }

  @isTest
  static void testGuestEventTriggerHandler() {
    GuestEventTriggerHandler geth = new GuestEventTriggerHandler();

    geth.beforeInsert(new List<SObject>());
    geth.beforeUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
    geth.afterUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
    geth.beforeDelete(new Map<Id, SObject>());
    geth.afterDelete(new Map<Id, SObject>());
    geth.afterUndelete(new Map<Id, SObject>());

    User curUser = UtilsBypass.getCurrentUser();
    curUser.ER_Bypass_Triggers__c = 'GuestEventTriggerHandler';
    update curUser;

    geth.isDisabled();
  }

  @isTest
  static void testWebOffer() {
    TestDataFactory.insertProducts('Ticket Restaurant Électronique', 'ERBE_TRE-M', 'BENELUX', 'M', 'ERBE Merchant');

    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('testCompany', 'BENELUX');
    newMerchantAccount.ER_Registration_Number__c = '0123456789';
    newMerchantAccount.NumberOfEmployees = 22;
    insert newMerchantAccount;

    PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();
    update standardPriceBook;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('ERBE MERCHANT');
    insert newPriceBook;

    Contact newContact = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'APER11', 'APER11');
    newContact.ER_Language__c = 'FR';
    newContact.AccountId = newMerchantAccount.Id;
    insert newContact;

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    newSolution.ProductCode = 'ERBE_Test-class';
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

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'APER11_Quote_Management_Test'
    );
    newOpportunity.AccountId = newMerchantAccount.Id;
    newOpportunity.ContractId = con.Id;
    newOpportunity.Pricebook2Id = newPriceBook.Id;
    newOpportunity.LeadSource = 'Webform';
    newOpportunity.ER_BUPicklist__c = 'BE';
    insert newOpportunity;

    OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
      newOpportunity.id,
      newPriceBookEntry.id
    );
    insert newOpportunityProduct;

    Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
      'ER_Merchant_Quote',
      'APER11_Quote_Management_Test',
      newOpportunity.id,
      newPriceBook.id
    );
    merchantQuote.ContactId = newContact.Id;
    merchantQuote.ER_Web_Offer_Token__c = 'b3cde330-c94e-04fe-d04c-68fd590c38b9';
    merchantQuote.ER_Main_Solution__c = APER32_Product2_Management.getSolutionId('ERBE_TRE-M');
    merchantQuote.ER_Contact_Language__c = 'FR';
    insert merchantQuote;

    merchantQuote = [
      SELECT
        Id,
        ContactId,
        ContractId,
        Contract.ContractNumber,
        ER_Web_Offer_Token__c,
        ER_Contact_Language__c,
        ER_Main_Solution__c,
        ER_Main_Solution__r.ProductCode
      FROM Quote
      WHERE Id = :merchantQuote.Id
    ][0];

    QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.id, newPriceBookEntry.id);
    insert qli;

    Test.startTest();

    String merchantInfosJSON =
      '{ "Draft": "true", "isReadOnly": "false", "existingAccount": "true", "accountId": "' +
      newMerchantAccount.Id +
      '", "leadId": "", "enterpriseNb":"0123456789", "company": "testCompany", "phone": "+32 654654 8974", "legalName": "testCompany", "address": "Avenue Reine Elisabeth 2372323", "postalCode": "5000", "city": "BEEZ", "country": "BELGIUM", "refundCountry": "BELGIUM", "hasVATCode": "true", "enterpriseVATCode": "BE0123456789", "countryCode": "BE", "enterpriseNb": "0123456789", "solutionName": "Ticket Restaurant Électronique", "solutionCode": "ERBE_TRE-M", "contactId": "' +
      newContact.Id +
      '", "salutation": "Mr.", "firstName": "Karl", "lastName": "Smith", "email": "karl@smith.com", "contactPhone": "+32 654654 8974", "lang": "FR", "keyId": "b3cde330-c94e-04fe-d04c-68fd590c38b9", "mobile": "32132131" }';

    GenericWithoutSharing.getEnterpriseInfos('0123456789', 'BE', 'FR', 'b3cde330-c94e-04fe-d04c-68fd590c38b9', null);
    GenericWithoutSharing.updateAccount(merchantInfosJSON);

    // Contracting step
    String opportunityParamsJSON =
      '{"accountId": "' +
      newMerchantAccount.Id +
      '", "country": "BE", "contactEmail": "alain.michel@prunelli.be", "lang": "FR", "solution": "ERBE_TRE-M", "promoCode": "", "scope": "M", "versionId": "1", "isWebOffer": "true", "uniqueKeyId": "b3cde330-c94e-04fe-d04c-68fd590c38b9"}';

    APER30_AutoEnrollment_Management.doApexEvent('closeOpportunity', opportunityParamsJSON);
    Test.getEventBus().deliver();

    // Onboarding step
    opportunityParamsJSON =
      '{"accountId": "' +
      newMerchantAccount.Id +
      '", "country": "BE", "contactEmail": "alain.michel@prunelli.be", "lang": "FR", "solution": "ERBE_TRE-M", "promoCode": "", "scope": "M", "versionId": "1", "isWebOffer": "true", "uniqueKeyId": "b3cde330-c94e-04fe-d04c-68fd590c38b9", "contractId": "' +
      newOpportunity.ContractId +
      '"}';
    APER30_AutoEnrollment_Management.doApexEvent('closeOpportunity', opportunityParamsJSON);
    Test.getEventBus().deliver();

    Test.stopTest();
  }

  public class GetBIC_Mock implements HttpCalloutMock {
    //Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      String testBody = '{ "valid": true, "messages": [], "iban": "BE52812615696709", "bankData": { "bankCode": "812", "name": "AXA Bank Belgium", "bic": "AXABBE22" } }';
      // Create a fake response
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json;charset=UTF-8');
      response.setBody(testBody);
      response.setStatusCode(200);
      return response;
    }
  }

  @isTest
  static void testSetBankAccountInfos() {
    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER31_BankAccount_Management_Test', 'BENELUX');
    insert merchantAccount;

    ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
      'APER31_BankAccount_Management_Test',
      merchantAccount.id,
      Label.LABS_SF_FinancialCenter_Merchant,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
    insert testFinancialCenter;

    ER_Bank_Account__c bankAccount = APER07_UtilityTestMethod.getBankAccount(
      testFinancialCenter.Id,
      'APER31_BankAccount_Management_Test',
      'Open',
      'Paris',
      'Paris street',
      'BE52812615696709'
    );
    insert bankAccount;
    bankAccount.Name = 'APER31_BankAccount_Management_Test1';
    update bankAccount;

    Test.startTest();
    List<ER_Bank_Account__c> bankAccounts = [SELECT Id, ER_IBAN__c FROM ER_Bank_Account__c];
    for (ER_Bank_Account__c ba : bankAccounts)
      ba.ER_IBAN__c = 'BE52812615696709';
    update bankAccounts;
    Test.stopTest();
  }

  @isTest
  static void autoEnrollmentSLITest() {
    User ur = TestDataFactory.newUser('autoEnrollmentSLITest', 'check', 'Local Admin', 'Finland', 'FI');
    insert ur;
    ur = [SELECT Name FROM USER WHERE id = :ur.id];
    System.debug('>>> USER ' + ur.name);
    System.runAs(ur) {
      Account acc = APER07_UtilityTestMethod.getCompany('autoEnrollmentConvertClientLead');
      acc.ER_Registration_Number__c = '2293911-5';
      insert acc;
      PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

      List<ER_Financial_Center__c> fcListToInsert = new List<ER_Financial_Center__c>();
      List<Product2> solutionListToInsert = new List<Product2>();
      List<Product2> serviceListToInsert = new List<Product2>();
      List<PriceBookEntry> pbeListToInsert = new List<PriceBookEntry>();
      List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
      List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
      List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();

      ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
        'APER30_FinancialCenter_Management_TEST',
        acc.id,
        Label.LABS_SF_FinancialCenter_Merchant,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      testFinancialCenter.ER_Preferred_Invoicing_Method__c = 'E-invoice';
      testFinancialCenter.ERFI_OVT_Code__c = 'DESRF';
      testFinancialCenter.ERFI_OVT_Operator__c = 'OVTEFG';
      testFinancialCenter.ER_Type__c = 'Client';
      fcListToInsert.add(testFinancialCenter);
      ER_Financial_Center__c testFinancialCenter2 = APER07_UtilityTestMethod.getFinancialCenter(
        'APER30_FinancialCenter_Management_TEST_TEST2',
        acc.id,
        Label.LABS_SF_FinancialCenter_Client,
        'Test',
        'Test',
        'Test',
        'Test'
      );
      testFinancialCenter2.ER_Type__c = Label.LABS_SF_FinancialCenter_Merchant;
      testFinancialCenter2.ER_Preferred_Invoicing_Method__c = 'E-invoice';
      testFinancialCenter2.ER_Type__c = 'Client';
      testFinancialCenter2.ERFI_OVT_Code__c = 'DESRF';
      testFinancialCenter2.ERFI_OVT_Operator__c = 'OVTEFG';
      fcListToInsert.add(testFinancialCenter2);
      insert fcListToInsert;

      Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
      newSolution.ProductCode = 'testSolution';
      solutionListToInsert.add(newSolution);
      Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
      newSolution2.ProductCode = 'testSolution2';
      solutionListToInsert.add(newSolution2);
      insert solutionListToInsert;

      Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
      serviceListToInsert.add(newService);
      Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice3', newSolution2.id);
      serviceListToInsert.add(newService2);
      insert serviceListToInsert;

      PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
      newPriceBookEntry.ER_Percentage__c = null;
      pbeListToInsert.add(newPriceBookEntry);
      PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
      newPriceBookEntry2.ER_Percentage__c = null;
      pbeListToInsert.add(newPriceBookEntry2);
      insert pbeListToInsert;

      Contract testContract = APER07_UtilityTestMethod.getContract(
        acc.id,
        Date.today(),
        Label.LABS_SF_Contract_Status_Draft,
        newPriceBook.Id
      );
      testContract.ER_Offline__c = true;
      testContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
        .get('ER_Merchant_Contract_RT')
        .getRecordTypeId();
      insert testContract;

      ER_ContractLineItem__c testContractLineItem = APER07_UtilityTestMethod.getContractLineItem(
        testContract.id,
        newService.id,
        newPriceBookEntry.id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem);
      ER_ContractLineItem__c testContractLineItem3 = APER07_UtilityTestMethod.getContractLineItem(
        testContract.id,
        newService2.id,
        newPriceBookEntry2.id,
        1,
        1
      );
      cliListToInsert.add(testContractLineItem3);
      insert cliListToInsert;

      testContract.status = Label.LABS_SF_Contract_Status_Activated;
      update testContract;

      ER_Solution_Line_Item__c testAccountLineItem = APER07_UtilityTestMethod.getAccountLineItem(
        acc.Id,
        testContract.Id,
        newSolution.Id
      );
      testAccountLineItem.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
      aliListToInsert.add(testAccountLineItem);
      ER_Solution_Line_Item__c testAccountLineItem2 = APER07_UtilityTestMethod.getAccountLineItem(
        acc.Id,
        testContract.Id,
        newSolution2.Id
      );
      testAccountLineItem2.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
      aliListToInsert.add(testAccountLineItem2);
      insert aliListToInsert;

      ER_Solution_Line_Item__c testFinancialCenterLineItem = APER07_UtilityTestMethod.getFinancialCenterLineItem(
        testFinancialCenter.id,
        testContract.Id,
        testAccountLineItem.id,
        newSolution.id
      );
      fcliListToInsert.add(testFinancialCenterLineItem);
      ER_Solution_Line_Item__c testFinancialCenterLineItem2 = APER07_UtilityTestMethod.getFinancialCenterLineItem(
        testFinancialCenter.id,
        testContract.Id,
        testAccountLineItem2.id,
        newSolution2.id
      );
      fcliListToInsert.add(testFinancialCenterLineItem2);
      insert fcliListToInsert;

      List<ER_Solution_Line_Item__c> slis = [SELECT id, ER_BUPicklist__c, ER_Status__c FROM ER_Solution_Line_Item__c];
      System.debug(slis);

      System.assertEquals(4, slis.size());
      for (ER_Solution_Line_Item__c sli : slis) {
        System.assertEquals(Constants.ACTIVE, sli.ER_Status__c);
      }
    }
  }

  @isTest
    static void fakecc() {
        APER30_AutoEnrollment_Management.fakecc();
    }
}