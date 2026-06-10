/**
 * Created by Saad on 27/06/2023.
 */

@IsTest
private class ManageFinancialCenterTest {
  @testSetup
  static void testSetup() {
    Account newMerchantAccount = TestDataFactory.newAccount();
    newMerchantAccount.Name = 'test';
    newMerchantAccount.ER_Registration_Number__c = '2629495-9';
    insert newMerchantAccount;

    ER_Financial_Center__c testFinancialCenter = TestDataFactory.newFinancialCenter(
      newMerchantAccount,
      Label.LABS_SF_FinancialCenter_Client
    );
    testFinancialCenter.ERFI_OVT_Code__c = 'test';
    testFinancialCenter.ERFI_OVT_Operator__c = 'test';
    testFinancialCenter.Name = 'test';
    testFinancialCenter.ER_Type__c = 'Merchant';
    testFinancialCenter.ER_Invoicing_Country_Code__c = 'FR';
    testFinancialCenter.ER_Invoicing_Country__c = 'France';
    insert testFinancialCenter;

    Contact contactTest = TestDataFactory.newContact(newMerchantAccount);
    contactTest.ER_Account_Address_Sync__c = LAbel.LABS_SF_Account_SyncAddressContact;
    insert contactTest;

    User runningUser = [SELECT id, ER_Business_Unit__c FROM User WHERE id = :UserInfo.getUserId()];
    Account clientAccount = APER07_UtilityTestMethod.getCompany('test');
    clientAccount.ER_Registration_Number__c = '0000112-1';
    insert clientAccount;

    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

    List<Product2> solutionListToInsert = new List<Product2>();
    List<Product2> serviceListToInsert = new List<Product2>();
    List<PriceBookEntry> pbeListToInsert = new List<PriceBookEntry>();
    List<ER_ContractLineItem__c> cliListToInsert = new List<ER_ContractLineItem__c>();
    List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
    List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
    newSolution.ProductCode = 'testSolution';
    newSolution.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    solutionListToInsert.add(newSolution);

    Product2 newSolution4 = APER07_UtilityTestMethod.getsolution('testSolution2');
    newSolution4.ProductCode = 'testSolution2';
    newSolution4.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    solutionListToInsert.add(newSolution4);

    insert solutionListToInsert;

    Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
    newService.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    serviceListToInsert.add(newService);

    Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice2', newSolution4.id);
    newService2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    serviceListToInsert.add(newService2);

    insert serviceListToInsert;

    PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
    pbeListToInsert.add(newPriceBookEntry);

    PriceBookEntry newPriceBookEntry2 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService2.id);
    pbeListToInsert.add(newPriceBookEntry2);

    insert pbeListToInsert;

    Contract testContract = APER07_UtilityTestMethod.getContract(
      clientAccount.id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id
    );
    testContract.recordtypeid = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
      .get('ER_Client_Contract_RT')
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

    ER_ContractLineItem__c testContractLineItem2 = APER07_UtilityTestMethod.getContractLineItem(
      testContract.id,
      newService2.id,
      newPriceBookEntry2.id,
      1,
      1
    );
    cliListToInsert.add(testContractLineItem2);

    insert cliListToInsert;

    testContract.status = Label.LABS_SF_Contract_Status_Activated;
    //update testContract;

    ER_Solution_Line_Item__c testAccountLineItem = APER07_UtilityTestMethod.getAccountLineItem(
      clientAccount.Id,
      testContract.Id,
      newSolution.Id
    );
    testAccountLineItem.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
    aliListToInsert.add(testAccountLineItem);

    ER_Solution_Line_Item__c testAccountLineItem2 = APER07_UtilityTestMethod.getAccountLineItem(
      clientAccount.Id,
      testContract.Id,
      newSolution4.Id
    );
    testAccountLineItem2.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;
    aliListToInsert.add(testAccountLineItem2);

    insert aliListToInsert;

    ER_Solution_Line_Item__c testFinancialCenterLineItem = APER07_UtilityTestMethod.getFinancialCenterLineItem(
      testFinancialCenter.Id,
      testContract.Id,
      testAccountLineItem.id,
      newSolution.Id
    );
    fcliListToInsert.add(testFinancialCenterLineItem);

    ER_Solution_Line_Item__c testFinancialCenterLineItem2 = APER07_UtilityTestMethod.getFinancialCenterLineItem(
      testFinancialCenter.Id,
      testContract.Id,
      testAccountLineItem2.id,
      newSolution4.Id
    );
    fcliListToInsert.add(testFinancialCenterLineItem2);

    insert fcliListToInsert;

    List<Contact> contactList = new List<Contact>();

    Contact c = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test1', 'test1');
    c.AccountId = clientAccount.Id;
    Contact c1 = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test2', 'test2');
    c1.AccountId = clientAccount.Id;
    contactList.add(c);
    contactList.add(c1);
    insert contactList;
  }

  @IsTest
  static void testGetInfosBehavior() {
    List<ER_Financial_Center__c> financialCenters = [SELECT Id FROM ER_Financial_Center__c];
    Test.startTest();
    Map<String, String> infoMap = ManageFinancialCenter.getFinancialCenterInfos(financialCenters.get(0).Id);
    Test.stopTest();
    System.assertEquals(false, infoMap.isEmpty());
  }

  @IsTest
    static void testUpdateBehavior()
    {
        List<ER_Financial_Center__c> financialCenters = [SELECT Id, ER_Account_Name__r.Id, ER_Account_Name__r.Name, ER_Account_Name__r.BillingCity,
                                                            ER_Account_Name__r.BillingPostalCode, ER_Account_Name__r.BillingStreet, ER_Account_Name__r.Phone,
                                                            ER_Account_Name__r.BillingCountry, ER_Contact__r.FirstName,
                                                            ER_Contact__r.LastName, ER_Contact__r.Email,
                                                            ER_Contact__r.Phone, ER_Contact__r.MobilePhone,
                                                            ER_Account_Name__r.ER_Legal_Name__c, ER_Preferred_Invoicing_Method__c, ER_Bank_Account__r.ER_IBAN__c,
                                                            ER_Bank_Account__r.ER_BIC__c, ER_Invoicing_Street__c, ER_Invoicing_Zip_Code__c,
                                                            ER_Invoicing_City__c, ER_Invoicing_Country__c, ER_Contact__c, ER_Invoicing_Country_Code__c FROM ER_Financial_Center__c];
    Test.startTest();
    Map<String, String> infoMap = new Map<String, String>();
    infoMap.put('accountId', financialCenters.get(0).ER_Account_Name__c);
    infoMap.put('company', financialCenters.get(0).ER_Account_Name__r.Name);
    infoMap.put('phone', financialCenters.get(0).ER_Account_Name__r.Phone);
    infoMap.put('address', financialCenters.get(0).ER_Invoicing_Street__c);
    infoMap.put('postalCode', financialCenters.get(0).ER_Invoicing_Zip_Code__c);
    infoMap.put('city', financialCenters.get(0).ER_Invoicing_City__c);
    infoMap.put('country', financialCenters.get(0).ER_Invoicing_Country__c);
    infoMap.put('refundCountry', financialCenters.get(0).ER_Account_Name__r.BillingCountry);
    infoMap.put('firstName', 'financialCestName');
    infoMap.put('lastName', 'financialCenName');
    infoMap.put('email', 'test@test.fr');
    infoMap.put('contactPhone', financialCenters.get(0).ER_Contact__r.Phone);
    infoMap.put('mobile', financialCenters.get(0).ER_Contact__r.MobilePhone);
    infoMap.put('legalName', 'financiName__c');
    infoMap.put('iban', financialCenters.get(0).ER_Bank_Account__r.ER_IBAN__c);
    infoMap.put('bic', financialCenters.get(0).ER_Bank_Account__r.ER_BIC__c);
    infoMap.put('invoicingMethod', financialCenters.get(0).ER_Preferred_Invoicing_Method__c);
    ManageFinancialCenter.updateFinancialCenter(true, true, JSON.serialize(infoMap), financialCenters.get(0).Id);
    Test.stopTest();
    System.assertEquals(false, infoMap.isEmpty());
  }

  @IsTest
  static void testCreateBehavior() {
    Account anAccount = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    Map<String, String> infoMap = new Map<String, String>();
    infoMap.put('accountId', anAccount.Id);
    infoMap.put('company', 'test');
    infoMap.put('phone', 'test');
    infoMap.put('address', 'test');
    infoMap.put('postalCode', 'test');
    infoMap.put('city', 'test');
    infoMap.put('country', 'test');
    infoMap.put('refundCountry', 'test');
    infoMap.put('firstName', 'financialCestName');
    infoMap.put('lastName', 'financialCenName');
    infoMap.put('email', 'test@test.fr');
    infoMap.put('contactPhone', 'test');
    infoMap.put('mobile', 'test');
    infoMap.put('legalName', 'financiName__c');
    infoMap.put('iban', '00000000-00000000-00000000');
    infoMap.put('bic', '12345678901');
    infoMap.put('invoicingMethod', 'Paper');
    infoMap.put('enterpriseNb', '2629495-9');
    infoMap.put('bu', 'FI');
    ManageFinancialCenter.createFinancialCenter(JSON.serialize(infoMap), 'M');
    Test.stopTest();

    List<ER_Financial_Center__c> fc = [SELECT Id FROM ER_Financial_Center__c WHERE ER_Account_Name__c = :anAccount.Id];
    System.assertEquals(2, fc.size());
  }

  @IsTest
  static void testGetFinancialCenter() {
    ER_Financial_Center__c fc = [
      SELECT Id, ER_Account_Name__r.ER_Registration_Number__c
      FROM ER_Financial_Center__c
      LIMIT 1
    ];

    Test.startTest();
    List<Map<String, String>> result = ManageFinancialCenter.getFinCentersInfosByCRN(
      fc.ER_Account_Name__r.ER_Registration_Number__c,
      'M'
    );
    Test.stopTest();

    System.assertEquals(true, result.size() > 0);
  }

  @IsTest
  static void testGetFinancialCenterStores() {
    ER_Financial_Center__c testFinancialCenter = TestDataFactory.newFinancialCenter(
      [SELECT id FROM Account][0],
      Label.LABS_SF_FinancialCenter_Client
    );
    testFinancialCenter.ERFI_OVT_Code__c = 'test01';
    testFinancialCenter.ERFI_OVT_Operator__c = 'test01';
    testFinancialCenter.Name = 'test01';
    testFinancialCenter.ER_Type__c = 'Merchant';
    insert testFinancialCenter;

    List<ER_Financial_Center__c> fc = [
      SELECT Id, ER_Account_Name__c, ER_Account_Name__r.ER_Registration_Number__c
      FROM ER_Financial_Center__c
      LIMIT 2
    ];

    insert new ER_Store__c(
      Name = 'CANDA HOTEL',
      ER_Merchant__c = fc[0].ER_Account_Name__c,
      ER_Financial_Center__c = fc[0].Id,
      ER_Street__c = 'Test Street',
      ER_City__c = 'BUDAPEST',
      ER_Zip_Code__c = '1095'
    );

    insert new ER_Store__c(
      Name = 'CANDA HOTEL',
      ER_Merchant__c = fc[1].ER_Account_Name__c,
      ER_Financial_Center__c = fc[1].Id,
      ER_Street__c = 'Test Street',
      ER_City__c = 'BUDAPEST',
      ER_Zip_Code__c = '1095'
    );

    Test.startTest();
    List<Map<String, Object>> result = ManageFinancialCenter.getFcStoresInfos(fc[0].id, 'fi');
    Test.stopTest();

    System.assertEquals(1, result.size());
  }
}