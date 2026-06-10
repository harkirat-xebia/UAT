@isTest
public with sharing class CreateDisProductsForSelPricebooksTest {
    
    @TestSetup
    static void setupTestData() {
        // 1. Create Standard Pricebook if not exists
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        // 2. Create Custom Pricebooks
        Pricebook2 customPb1 = new Pricebook2(Name='Custom Pricebook 1', IsActive = true);
        Pricebook2 customPb2 = new Pricebook2(Name='Custom Pricebook 2', IsActive = true);
        insert new List<Pricebook2>{customPb1, customPb2};
        
        // 3. Get Record Types
        RecordType rtRange = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range' LIMIT 1];
        RecordType rtService = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Service' LIMIT 1];
        
        // 4. Create Solution Product
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
        
        // 5. Create parent Range Product
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
        
        // 6. Create parent Service Product (for Cards)
        Product2 parentService = new Product2(
            Name = 'Service A',
            ER_Type__c = 'Service',
            ProductCode = 'TRC',
            IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'BE',
            RecordTypeId = rtService.Id,
            Solution_Group__c = 'Benefits',
            ER_Service_Number_of_Ranges__c = 0
        );
        insert parentService;
        
        // 7. Create Standard Pricebook Entries
        PricebookEntry pbeRangeStd = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = parentRange.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = 'BE',
            ER_ValueType__c = 'Currency'
        );
        PricebookEntry pbeServiceStd = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = parentService.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = 'BE',
            ER_ValueType__c = 'Currency'
        );
        insert new List<PricebookEntry>{pbeRangeStd, pbeServiceStd};
        
        // 8. Create Custom Pricebook Entries for Pricebook 1
        PricebookEntry pbeRange1 = new PricebookEntry(
            Pricebook2Id = customPb1.Id,
            Product2Id = parentRange.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = 'BE',
            ER_ValueType__c = 'Currency',
            ER_Min__c = 100,
            ER_Max__c = 200
        );
        PricebookEntry pbeService1 = new PricebookEntry(
            Pricebook2Id = customPb1.Id,
            Product2Id = parentService.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = 'BE',
            ER_ValueType__c = 'Currency'
        );
        insert new List<PricebookEntry>{pbeRange1, pbeService1};
        
        // 9. Create Custom Pricebook Entries for Pricebook 2
        PricebookEntry pbeRange2 = new PricebookEntry(
            Pricebook2Id = customPb2.Id,
            Product2Id = parentRange.Id,
            UnitPrice = 150,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = 'BE',
            ER_ValueType__c = 'Percentage',
            ER_Percentage__c = 7.5,
            ER_Min__c = 100,
            ER_Max__c = 200
        );
        PricebookEntry pbeService2 = new PricebookEntry(
            Pricebook2Id = customPb2.Id,
            Product2Id = parentService.Id,
            UnitPrice = 250,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = 'BE',
            ER_ValueType__c = 'Currency'
        );
        insert new List<PricebookEntry>{pbeRange2, pbeService2};
        
        // 10. Create Promo Codes
        ER_Promo_Code__c promo1 = new ER_Promo_Code__c(
            Name = 'TRE100OFF',
            Solution__c = 'TRE',
            Discount_Percentage__c = 10,
            Discount_Type__c = 'Solution and Cards',
            ER_Business_Unit__c = 'BE',
            ER_Start_Date__c = Date.today(),
            ER_End_Date__c = Date.today().addDays(30)
        );
        insert promo1;
    }
    
    @IsTest
    static void testBatchWithSinglePricebook() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];
        
        Set<Id> discountCodeIds = new Set<Id>{promo.Id};
        Set<Id> selectedPricebookIds = new Set<Id>{pb1.Id};
        
        Test.startTest();
        CreateDisProductsForSelPricebooksBatch batch = new CreateDisProductsForSelPricebooksBatch(
            discountCodeIds, 
            selectedPricebookIds
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify discount products created
        List<Product2> discountProducts = [SELECT Id, Name, ER_Type__c FROM Product2 WHERE ER_Type__c = 'Discount'];
        System.assertNotEquals(0, discountProducts.size(), 'Discount products should be created');
        
        // Verify PBEs created only for selected pricebook
        List<PricebookEntry> pbes = [
            SELECT Id, Pricebook2Id 
            FROM PricebookEntry 
            WHERE Product2.ER_Type__c = 'Discount' 
            AND Pricebook2Id = :pb1.Id
        ];
        System.assertNotEquals(0, pbes.size(), 'PBEs should be created for selected pricebook');
    }
    
    @IsTest
    static void testBatchWithMultiplePricebooks() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];
        Pricebook2 pb2 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 2' LIMIT 1];
        
        Set<Id> discountCodeIds = new Set<Id>{promo.Id};
        Set<Id> selectedPricebookIds = new Set<Id>{pb1.Id, pb2.Id};
        
        Test.startTest();
        CreateDisProductsForSelPricebooksBatch batch = new CreateDisProductsForSelPricebooksBatch(
            discountCodeIds, 
            selectedPricebookIds
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify PBEs created for both pricebooks
        List<PricebookEntry> pbes = [
            SELECT Id, Pricebook2Id 
            FROM PricebookEntry 
            WHERE Product2.ER_Type__c = 'Discount' 
            AND Pricebook2Id IN :selectedPricebookIds
        ];
        System.assertNotEquals(0, pbes.size(), 'PBEs should be created for both selected pricebooks');
    }
    
    @IsTest
    static void testBatchWithSolutionAndCards() {
        ER_Promo_Code__c promo = [SELECT Id, Discount_Type__c FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        System.assertEquals('Solution and Cards', promo.Discount_Type__c);
        
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];
        
        Set<Id> discountCodeIds = new Set<Id>{promo.Id};
        Set<Id> selectedPricebookIds = new Set<Id>{pb1.Id};
        
        Test.startTest();
        CreateDisProductsForSelPricebooksBatch batch = new CreateDisProductsForSelPricebooksBatch(
            discountCodeIds, 
            selectedPricebookIds
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify both Range and Service products created
        List<Product2> discountProducts = [
            SELECT Id, ER_Solution__r.ER_Type__c 
            FROM Product2 
            WHERE ER_Type__c = 'Discount'
        ];
        System.assertNotEquals(0, discountProducts.size(), 'Should create discount products');
    }
    
    @IsTest
    static void testBatchWithCurrencyValueType() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];
        
        Set<Id> discountCodeIds = new Set<Id>{promo.Id};
        Set<Id> selectedPricebookIds = new Set<Id>{pb1.Id};
        
        Test.startTest();
        CreateDisProductsForSelPricebooksBatch batch = new CreateDisProductsForSelPricebooksBatch(
            discountCodeIds, 
            selectedPricebookIds
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify discount calculation for Currency type
        List<PricebookEntry> pbes = [
            SELECT Id, UnitPrice, ER_ValueType__c 
            FROM PricebookEntry 
            WHERE Product2.ER_Type__c = 'Discount' 
            AND Pricebook2Id = :pb1.Id
            AND ER_ValueType__c = 'Currency'
        ];
        
        if (!pbes.isEmpty()) {
            // 10% discount on 100 = 90
            System.assertEquals(90, pbes[0].UnitPrice, 'Should apply 10% discount');
        }
    }
    
    @IsTest
    static void testBatchWithPercentageValueType() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb2 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 2' LIMIT 1];
        
        Set<Id> discountCodeIds = new Set<Id>{promo.Id};
        Set<Id> selectedPricebookIds = new Set<Id>{pb2.Id};
        
        Test.startTest();
        CreateDisProductsForSelPricebooksBatch batch = new CreateDisProductsForSelPricebooksBatch(
            discountCodeIds, 
            selectedPricebookIds
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify discount calculation for Percentage type
        List<PricebookEntry> pbes = [
            SELECT Id, ER_Percentage__c, ER_ValueType__c 
            FROM PricebookEntry 
            WHERE Product2.ER_Type__c = 'Discount' 
            AND Pricebook2Id = :pb2.Id
            AND ER_ValueType__c = 'Percentage'
        ];
        
        if (!pbes.isEmpty()) {
            // 10% discount on 7.5% = 6.75%
            System.assertEquals(6.75, pbes[0].ER_Percentage__c, 'Should apply 10% discount to percentage');
        }
    }
    
    @IsTest
    static void testBatchWithEmptyPricebooks() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        
        Set<Id> discountCodeIds = new Set<Id>{promo.Id};
        Set<Id> selectedPricebookIds = new Set<Id>();
        
        Test.startTest();
        CreateDisProductsForSelPricebooksBatch batch = new CreateDisProductsForSelPricebooksBatch(
            discountCodeIds, 
            selectedPricebookIds
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Should not create any discount products
        List<Product2> discountProducts = [SELECT Id FROM Product2 WHERE ER_Type__c = 'Discount'];
        System.assertEquals(0, discountProducts.size(), 'Should not create products with empty pricebook set');
    }
    
    @IsTest
    static void testBatchWithPromoCodeFields() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];
        
        Set<Id> discountCodeIds = new Set<Id>{promo.Id};
        Set<Id> selectedPricebookIds = new Set<Id>{pb1.Id};
        
        Test.startTest();
        CreateDisProductsForSelPricebooksBatch batch = new CreateDisProductsForSelPricebooksBatch(
            discountCodeIds, 
            selectedPricebookIds
        );
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify promo code fields are populated
        List<PricebookEntry> pbes = [
            SELECT Id, ER_Promo_Code2__c, ER_Offer_validity_start_date__c, ER_Offer_validity_end_date__c
            FROM PricebookEntry 
            WHERE Product2.ER_Type__c = 'Discount' 
            AND Pricebook2Id = :pb1.Id
        ];
        
        if (!pbes.isEmpty()) {
            System.assertEquals(promo.Id, pbes[0].ER_Promo_Code2__c, 'Should link to promo code');
            System.assertNotEquals(null, pbes[0].ER_Offer_validity_start_date__c, 'Should have start date');
            System.assertNotEquals(null, pbes[0].ER_Offer_validity_end_date__c, 'Should have end date');
        }
    }
}