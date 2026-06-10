@isTest
public with sharing class CreateDiscountedProductsBatchTest {
    @TestSetup
    static void setupTestData() {
        // 1. Create Standard Pricebook if not exists
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        // 2. Create a Custom Pricebook
        Pricebook2 customPb = new Pricebook2(Name='Custom Pricebook', IsActive = true);
        insert customPb;

        // 3. Create parent Products (Range)
        RecordType rtRange = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range' LIMIT 1];
        Product2 parentSolution = new Product2(
            Name = 'Edenred Meal',
            ER_Type__c = 'Solution',
            ProductCode = 'TRE',
            IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'BE',
            Solution_Group__c = 'Benefits'
        );
        insert parentSolution;
        
        Product2 parentRange = new Product2(
            Name = '100 to 200',
            ER_Type__c = 'Range',
            ProductCode = 'ORD_MAN',
            IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'BE',
            Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id,
            ER_Solution2__c = parentSolution.Id
        );
        insert parentRange;

        // 4. Create parent Products (Service)
        RecordType rtService = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Service' LIMIT 1];
        Product2 parentService = new Product2(
            Name = 'Service A',
            ER_Type__c = 'Service',
            ProductCode = 'TRC',
            IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'BE',
            RecordTypeId = rtService.Id,
            Solution_Group__c = 'Benefits'
        );
        insert parentService;

        // 5. Create Pricebook Entries for both products
        PricebookEntry pbeRangeStd = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = parentRange.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = parentRange.ER_BUPicklist__c,
            ER_ValueType__c = 'Currency'
        );
        PricebookEntry pbeServiceStd = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = parentService.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = parentService.ER_BUPicklist__c,
            ER_ValueType__c = 'Currency'
        );
        insert new List<PricebookEntry>{pbeRangeStd, pbeServiceStd};
        PricebookEntry pbeRange = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = parentRange.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = parentRange.ER_BUPicklist__c,
            ER_ValueType__c = 'Currency'
        );
        PricebookEntry pbeService = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = parentService.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = parentService.ER_BUPicklist__c,
            ER_ValueType__c = 'Currency'
        );
        insert new List<PricebookEntry>{pbeRange, pbeService};

        // 6. Create a sample Promo Code (Solution Only)
        ER_Promo_Code__c promo = new ER_Promo_Code__c(
            Name = 'TRE100OFF',
            Solution__c = 'TRE',
            Discount_Percentage__c = 100,
            Discount_Type__c = 'Solution and Cards',
            ER_Business_Unit__c = 'BE',
            ER_Start_Date__c = Date.today(),
            ER_End_Date__c = Date.today().addDays(30)
        );
        insert promo;
    }

    @IsTest
    static void testBatchDiscountCreation() {

        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];

        // Execute the batch
        Test.startTest();
        CreateDiscountedProductsBatch batch = new CreateDiscountedProductsBatch(new Set<Id>{promo.Id});
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }
}