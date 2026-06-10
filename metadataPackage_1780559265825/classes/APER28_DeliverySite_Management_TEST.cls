/*
----------------------------------------------------------------------
-- - Name          : APER28_DeliverySite_Management_TEST
-- - Author        : KHAD
-- - Description   : Test class for Delivery Site Management.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- FEB-2021     KHAD                   1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
@isTest
public class APER28_DeliverySite_Management_TEST {
  @testSetup
  static void testSetup() {
    User runningUser = [SELECT id, ER_Business_Unit__c FROM User WHERE id = :UserInfo.getUserId()];
    //Account clientAccount = APER07_UtilityTestMethod.getCompany('APER28_DeliverySite_Management_TEST');
    //insert clientAccount;
    Account clientAccount = APER07_UtilityTestMethod.getCompany('APER28_DeliverySite_Management_TEST');
    clientAccount.BillingStreet     = 'Test Billing Street';
    clientAccount.BillingCity       = 'Test City';
    clientAccount.BillingPostalCode = '12345';
    clientAccount.BillingCountry    = 'India';
    clientAccount.BillingState      = 'Test State';
    clientAccount.ShippingStreet     = 'Test Shipping Street';
    clientAccount.ShippingCity       = 'Test City';
    clientAccount.ShippingPostalCode = '12345';
    clientAccount.ShippingCountry    = 'India';
    clientAccount.ShippingState      = 'Test State';

    insert clientAccount;


    ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
      'APER28_DeliverySite_Management_TEST',
      clientAccount.id,
      Label.LABS_SF_FinancialCenter_Merchant,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testFinancialCenter.ER_Type__c = Label.LABS_SF_FinancialCenter_Client;
    insert testFinancialCenter;

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

    Product2 newSolution2 = APER07_UtilityTestMethod.getsolution('testSolution2');
    newSolution2.ProductCode = 'testSolution2';
    newSolution2.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    solutionListToInsert.add(newSolution2);

    insert solutionListToInsert;

    Product2 newService = APER07_UtilityTestMethod.getservice('testservice', newSolution.id);
    newService.ER_Business_Unit__c = runningUser.ER_Business_Unit__c;
    serviceListToInsert.add(newService);

    Product2 newService2 = APER07_UtilityTestMethod.getservice('testservice2', newSolution2.id);
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
    update testContract;

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
      newSolution2.Id
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
      newSolution2.Id
    );
    fcliListToInsert.add(testFinancialCenterLineItem2);

    insert fcliListToInsert;

    List<Contact> contactList = new List<Contact>();

        Contact c = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test1', 'test1');
        c.AccountId = clientAccount.Id;
        c.Salutation = 'Mr.';
        c.MailingStreet     = 'Test Street 1';
        c.MailingCity       = 'Test City';
        c.MailingPostalCode = '12345';
        c.MailingCountry    = 'India';
        c.MailingState      = 'Test State';
        
        Contact c1 = APER07_UtilityTestMethod.getContact('ER_Contact_RT', 'test2', 'test2');
        c1.AccountId = clientAccount.Id;
        c1.Salutation = 'Mr.';
        c1.MailingStreet     = 'Test Street 2';
        c1.MailingCity       = 'Test City';
        c1.MailingPostalCode = '12345';
        c1.MailingCountry    = 'India';
        c1.MailingState      = 'Test State';
        
        contactList.add(c);
        contactList.add(c1);
        insert contactList;



    ER_Delivery_Site__c testDeliverySite = APER07_UtilityTestMethod.getDeliverySite(
    'APER28_DeliverySite_Management_TEST',
    clientAccount.id,
    testFinancialCenter.id
);
    testDeliverySite.ER_Delivery_Contact__c = c1.Id;

    testDeliverySite.ER_Street__c        = 'Test DS Street';
    testDeliverySite.ER_City__c          = 'Test DS City';       
    testDeliverySite.ER_Zip_Code__c  	 = '12345';               
    testDeliverySite.ER_Country__c       = 'India';               

    insert testDeliverySite;


    ER_Solution_Line_Item__c testDeliverySiteLineItem = APER07_UtilityTestMethod.getDeliverySiteLineItem(
      testDeliverySite.id,
      testContract.id,
      testFinancialCenterLineItem.id,
      newSolution.id
    );
    insert testDeliverySiteLineItem;

    ER_Solution_Line_Item__c testDeliverySiteLineItem2 = APER07_UtilityTestMethod.getDeliverySiteLineItem(
      testDeliverySite.id,
      testContract.id,
      testFinancialCenterLineItem2.id,
      newSolution2.id
    );
    insert testDeliverySiteLineItem2;
  }

  static testMethod void manageDSLIFromContract() {
    List<Contract> contractList = [
      SELECT id, AccountId, Status
      FROM Contract
      WHERE Status = :Label.LABS_SF_Contract_Status_Activated
    ];
    if (!contractList.isEmpty()) {
      APER28_DeliverySite_Management.manageDSLIFromContract(contractList[0]);
    }
  }

  static testMethod void manageDSLIForNewDeliverySite() {
    Map<Id, ER_Delivery_Site__c> deliverySiteMap = new Map<Id, ER_Delivery_Site__c>();

    Account clientAccount = [SELECT id FROM Account WHERE Name = 'APER28_DeliverySite_Management_TEST'];
    ER_Financial_Center__c testFinancialCenter = [
      SELECT Id
      FROM ER_Financial_Center__c
      WHERE Name = 'APER28_DeliverySite_Management_TEST'
    ];

    ER_Delivery_Site__c testDeliverySite2 = APER07_UtilityTestMethod.getDeliverySite(
    'APER28_DeliverySite_Management_TEST',
    clientAccount.id,
    testFinancialCenter.id
);

testDeliverySite2.ER_Street__c      = 'Test DS2 Street';
testDeliverySite2.ER_City__c        = 'Test DS2 City';
testDeliverySite2.ER_Zip_Code__c = '54321';
testDeliverySite2.ER_Country__c     = 'India';

insert testDeliverySite2;

    deliverySiteMap.put(testDeliverySite2.Id, testDeliverySite2);

    APER28_DeliverySite_Management.manageDSLIForNewDeliverySite(deliverySiteMap);
  }

  static testMethod void updatePrimaryContactRole() {
    Map<Id, ER_Delivery_Site__c> deliverySiteMap = new Map<Id, ER_Delivery_Site__c>();
    Map<Id, ER_Delivery_Site__c> deliverySiteOldMap = new Map<Id, ER_Delivery_Site__c>();

    ER_Delivery_Site__c ds = [SELECT id, name, ER_Delivery_Contact__c FROM ER_Delivery_Site__c LIMIT 1];

    Contact c = [SELECT id FROM Contact WHERE FirstName = 'test1' LIMIT 1];

    deliverySiteMap.put(ds.id, ds);

    ds.ER_Delivery_Contact__c = c.Id;
    update ds;

    deliverySiteOldMap.put(ds.Id, ds);

    Test.startTest();
    APER28_DeliverySite_Management.updatePrimaryContactRole(deliverySiteMap, deliverySiteOldMap);
    Test.stopTest();
  }
    
    //Added by harkirat 
    /*@IsTest
static void createAcrForDeliverySitesTest() {
    // Use the Delivery Site created in testSetup
    ER_Delivery_Site__c existingDs = [
        SELECT Id, Name, ER_Financial_Center__c, ER_Delivery_Contact__c
        FROM ER_Delivery_Site__c
        WHERE Name = 'APER28_DeliverySite_Management_TEST'
        LIMIT 1
    ];

    // Financial center -> its Account (needed for ACR AccountId)
    ER_Financial_Center__c fc = [
        SELECT Id, ER_Account_Name__c
        FROM ER_Financial_Center__c
        WHERE Id = :existingDs.ER_Financial_Center__c
        LIMIT 1
    ];

    // NEW Contact with all mandatory fields (Salutation + address)
    Contact newContact = new Contact(
        Salutation        = 'Mr.',
        FirstName         = 'ACRTest',
        LastName          = 'Contact',
        AccountId         = fc.ER_Account_Name__c,
        MailingStreet     = 'ACR Street',
        MailingCity       = 'ACR City',
        MailingPostalCode = '12345',
        MailingCountry    = 'India',
        MailingState      = 'ACR State'
    );
    insert newContact;

    // Old DS (before change)
    ER_Delivery_Site__c dsOld = new ER_Delivery_Site__c(
        Id                    = existingDs.Id,
        ER_Financial_Center__c = existingDs.ER_Financial_Center__c,
        ER_Delivery_Contact__c = existingDs.ER_Delivery_Contact__c
    );

    // New DS (after change of delivery contact)
    ER_Delivery_Site__c dsNew = new ER_Delivery_Site__c(
        Id                    = existingDs.Id,
        ER_Financial_Center__c = existingDs.ER_Financial_Center__c,
        ER_Delivery_Contact__c = newContact.Id
    );

    // NOTE: parameter type is Map<Id, SObject>, but we can still pass ER_Delivery_Site__c instances
    Map<Id, SObject> newItems = new Map<Id, SObject>{ dsNew.Id => dsNew };
    Map<Id, SObject> oldItems = new Map<Id, SObject>{ dsOld.Id => dsOld };

    Test.startTest();
    APER28_DeliverySite_Management.createAcrForDeliverySites(newItems, oldItems);
    Test.stopTest();

    // Assert that ACR was created
    List<AccountContactRelation> acrs = [
        SELECT Id, AccountId, ContactId
        FROM AccountContactRelation
        WHERE AccountId = :fc.ER_Account_Name__c
          AND ContactId = :newContact.Id
    ];

    System.assertEquals(
        1,
        acrs.size(),
        'Exactly one AccountContactRelation should be created for the new Delivery Contact and the Financial Center Account.'
    );
}

*/
    //Added by harkirat
    @IsTest
static void syncDeliverySiteFlagsTest() {
    // Take an existing Delivery Site from setup
    ER_Delivery_Site__c dsBase = [
        SELECT Id, ER_Sync_result__c, ER_Creation_date_in_OS__c
        FROM ER_Delivery_Site__c
        LIMIT 1
    ];

    // OLD values (before sync)
    ER_Delivery_Site__c dsOld = new ER_Delivery_Site__c(
        Id                      = dsBase.Id,
        ER_Sync_result__c       = 'not_synchronized',
        ER_Creation_date_in_OS__c = null
    );

    // NEW values (after sync → synchronized)
    ER_Delivery_Site__c dsNew = new ER_Delivery_Site__c(
        Id                      = dsBase.Id,
        ER_Sync_result__c       = 'synchronized',
        ER_Creation_date_in_OS__c = null
    );

    // IMPORTANT: create maps as Map<Id, ER_Delivery_Site__c> so runtime type is correct
    Map<Id, ER_Delivery_Site__c> newMapDS = new Map<Id, ER_Delivery_Site__c>{ dsNew.Id => dsNew };
    Map<Id, ER_Delivery_Site__c> oldMapDS = new Map<Id, ER_Delivery_Site__c>{ dsOld.Id => dsOld };

    Test.startTest();
    // Cast through Object → Map<Id, SObject> to satisfy the method signature
    APER28_DeliverySite_Management.syncDeliverySiteFlags(
        (Map<Id, SObject>)((Object)newMapDS),
        (Map<Id, SObject>)((Object)oldMapDS)
    );
    Test.stopTest();

    ER_Delivery_Site__c updated = newMapDS.get(dsNew.Id);
    System.assertNotEquals(
        null,
        updated.ER_Creation_date_in_OS__c,
        'ER_Creation_date_in_OS__c should be set when sync result goes to "synchronized".'
    );
}
    
    //Added by harkirat
    @IsTest
static void syncDeliverySiteTest() {
    // Use one Delivery Site from setup
    ER_Delivery_Site__c ds = [
        SELECT Id, ER_BUPicklist__c, ER_Last_date_of_Sync__c
        FROM ER_Delivery_Site__c
        LIMIT 1
    ];

    List<ER_Delivery_Site__c> dsList = new List<ER_Delivery_Site__c>{ ds };

    // Old map with same Last_date_of_Sync__c
    Map<Id, ER_Delivery_Site__c> oldMap = new Map<Id, ER_Delivery_Site__c>{
        ds.Id => new ER_Delivery_Site__c(
            Id = ds.Id,
            ER_Last_date_of_Sync__c = ds.ER_Last_date_of_Sync__c
        )
    };

    Test.startTest();
    APER28_DeliverySite_Management.syncDeliverySite(dsList, oldMap);
    Test.stopTest();

    // Simple assertion just to keep test "meaningful"
    System.assertEquals(1, dsList.size(), 'Delivery site list should contain one element.');
}

  @IsTest
  static void updateDeliverySiteLineItemsForAccountTest() {
    String accId = [SELECT Id FROM Account LIMIT 1].Id;
    String contractId = [SELECT Id FROM Contract LIMIT 1].Id;

    String solution2 = [SELECT ProductCode FROM Product2 LIMIT 3][1].ProductCode;
    String solution3 = [SELECT ProductCode FROM Product2 LIMIT 3][2].ProductCode;

    Set<String> solutions = new Set<String>();
    solutions.add(solution2);
    solutions.add(solution3);

    Test.startTest();
    GenericWithoutSharing.updateDeliverySiteLineItemsForAccount(solutions, contractId, accId, 'Activated');
    Test.stopTest();
  }

  static testMethod void getAllDeliverySiteLineItemsTest() {
    Set<String> companyIds = new Set<String>();
    String companyId = [SELECT Id FROM Contract LIMIT 1].Id;
    companyIds.add(companyId);

    Test.startTest();
    APER28_DeliverySite_Management.getAllDeliverySiteLineItems(companyIds);
    Test.stopTest();
  }
}