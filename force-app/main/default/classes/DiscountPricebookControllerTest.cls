/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : DiscountPricebookControllerTest
* Author          : Harkirat Singh
* Created Date    : May 11, 2026
* Description     : Test class for DiscountPricebookController
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/
@isTest
private class DiscountPricebookControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // 1. Create Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        // 2. Create Custom Pricebooks
        List<Pricebook2> customPricebooks = new List<Pricebook2>{
            new Pricebook2(Name = 'Test Pricebook 1', IsActive = true, Description = 'Test Description 1'),
            new Pricebook2(Name = 'Test Pricebook 2', IsActive = true, Description = 'Test Description 2'),
            new Pricebook2(Name = 'Inactive Pricebook', IsActive = false, Description = 'Inactive')
        };
        insert customPricebooks;
        
        // 3. Get Record Types
        RecordType rtRange = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range' LIMIT 1];
        RecordType rtService = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Service' LIMIT 1];
        
        // 4. Create Solution Product
        Product2 solution = new Product2(
            Name = 'Edenred Meal',
            ER_Type__c = 'Solution',
            ProductCode = 'TRE',
            IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'BE',
            Solution_Group__c = 'Benefits'
        );
        insert solution;
        
        // 5. Create Range Product
        Product2 rangeProduct = new Product2(
            Name = '100 to 200',
            ER_Type__c = 'Range',
            ProductCode = 'TRE-RANGE',
            IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'BE',
            Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id,
            ER_Solution2__c = solution.Id
        );
        insert rangeProduct;
        
        // 6. Create Service Product
        Product2 serviceProduct = new Product2(
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
        insert serviceProduct;
        
        // 7. Create Standard Pricebook Entries
        List<PricebookEntry> stdPBEs = new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = rangeProduct.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency'
            ),
            new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = serviceProduct.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency'
            )
        };
        insert stdPBEs;
        
        // 8. Create Custom Pricebook Entries for Active Pricebooks
        List<PricebookEntry> customPBEs = new List<PricebookEntry>();
        for (Integer i = 0; i < 2; i++) {
            customPBEs.add(new PricebookEntry(
                Pricebook2Id = customPricebooks[i].Id,
                Product2Id = rangeProduct.Id,
                UnitPrice = 100 + (i * 10),
                IsActive = true,
                UseStandardPrice = false,
                ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency'
            ));
            customPBEs.add(new PricebookEntry(
                Pricebook2Id = customPricebooks[i].Id,
                Product2Id = serviceProduct.Id,
                UnitPrice = 200 + (i * 10),
                IsActive = true,
                UseStandardPrice = false,
                ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency'
            ));
        }
        insert customPBEs;
        
        // 9. Create Promo Codes
        List<ER_Promo_Code__c> promoCodes = new List<ER_Promo_Code__c>{
            new ER_Promo_Code__c(
                Name = 'TRE10OFF',
                Solution__c = 'TRE',
                Discount_Percentage__c = 10,
                Discount_Type__c = 'Solution and Cards',
                ER_Business_Unit__c = 'BE',
                ER_Start_Date__c = Date.today(),
                ER_End_Date__c = Date.today().addDays(30)
            ),
            new ER_Promo_Code__c(
                Name = 'TRE20OFF',
                Solution__c = 'TRE',
                Discount_Percentage__c = 20,
                Discount_Type__c = 'Solution and Cards',
                ER_Business_Unit__c = 'LU',
                ER_Start_Date__c = Date.today(),
                ER_End_Date__c = Date.today().addDays(30)
            )
        };
        insert promoCodes;
    }
    
    /**
     * Test getPricebooksForDiscount with valid discount code
     */
    @isTest
    static void testGetPricebooksForDiscountSuccess() {
        // Given
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name = 'TRE10OFF' LIMIT 1];
        
        // When
        Test.startTest();
        List<DiscountPricebookController.PricebookWrapper> result = 
            DiscountPricebookController.getPricebooksForDiscount(promo.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(0, result.size(), 'Should return pricebooks');
        System.assertEquals(2, result.size(), 'Should return 2 active pricebooks');
        
        // Verify wrapper fields are populated
        for (DiscountPricebookController.PricebookWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.Id, 'Pricebook Id should be populated');
            System.assertNotEquals(null, wrapper.Name, 'Pricebook Name should be populated');
            System.assertEquals(true, wrapper.IsActive, 'Pricebook should be active');
        }
    }
    
    /**
     * Test getPricebooksForDiscount with Solution and Cards discount type
     */
    @isTest
    static void testGetPricebooksForDiscountWithSolutionAndCards() {
        // Given
        ER_Promo_Code__c promo = [
            SELECT Id, Discount_Type__c 
            FROM ER_Promo_Code__c 
            WHERE Name = 'TRE10OFF' 
            LIMIT 1
        ];
        
        // Verify discount type
        System.assertEquals('Solution and Cards', promo.Discount_Type__c, 
            'Discount type should be Solution and Cards');
        
        // When
        Test.startTest();
        List<DiscountPricebookController.PricebookWrapper> result = 
            DiscountPricebookController.getPricebooksForDiscount(promo.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(0, result.size(), 
            'Should return pricebooks for Solution and Cards type');
    }
    
    /**
     * Test getPricebooksForDiscount with LU business unit
     */
    @isTest
    static void testGetPricebooksForDiscountWithLUBusinessUnit() {
        // Given
        ER_Promo_Code__c promo = [
            SELECT Id, ER_Business_Unit__c 
            FROM ER_Promo_Code__c 
            WHERE Name = 'TRE20OFF' 
            LIMIT 1
        ];
        
        // Verify business unit
        System.assertEquals('LU', promo.ER_Business_Unit__c, 'Business unit should be LU');
        
        // When
        Test.startTest();
        List<DiscountPricebookController.PricebookWrapper> result = 
            DiscountPricebookController.getPricebooksForDiscount(promo.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    /**
     * Test getPricebooksForDiscount excludes inactive pricebooks
     */
    @isTest
    static void testGetPricebooksExcludesInactive() {
        // Given
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name = 'TRE10OFF' LIMIT 1];
        
        // When
        Test.startTest();
        List<DiscountPricebookController.PricebookWrapper> result = 
            DiscountPricebookController.getPricebooksForDiscount(promo.Id);
        Test.stopTest();
        
        // Then
        for (DiscountPricebookController.PricebookWrapper wrapper : result) {
            System.assertNotEquals('Inactive Pricebook', wrapper.Name, 
                'Should not include inactive pricebook');
        }
    }
    
    /**
     * Test createDiscountedProductsForPricebooks success
     */
    @isTest
    static void testCreateDiscountedProductsSuccess() {
        // Given
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name = 'TRE10OFF' LIMIT 1];
        List<Pricebook2> pricebooks = [
            SELECT Id 
            FROM Pricebook2 
            WHERE IsActive = true AND IsStandard = false
            LIMIT 2
        ];
        
        List<Id> pricebookIds = new List<Id>();
        for (Pricebook2 pb : pricebooks) {
            pricebookIds.add(pb.Id);
        }
        
        // When
        Test.startTest();
        String batchJobId = DiscountPricebookController.createDiscountedProductsForPricebooks(
            promo.Id, 
            pricebookIds
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, batchJobId, 'Batch job ID should not be null');
        System.assert(batchJobId instanceof Id, 'Should return valid batch job ID');
        
        // Verify batch job was created
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE Id = :batchJobId
        ];
        System.assertEquals(1, jobs.size(), 'Batch job should be created');
        System.assertEquals('BatchApex', jobs[0].JobType, 'Should be a batch job');
    }
    
    /**
     * Test createDiscountedProductsForPricebooks with single pricebook
     */
    @isTest
    static void testCreateDiscountedProductsWithSinglePricebook() {
        // Given
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name = 'TRE10OFF' LIMIT 1];
        Pricebook2 pricebook = [
            SELECT Id 
            FROM Pricebook2 
            WHERE Name = 'Test Pricebook 1' 
            LIMIT 1
        ];
        
        List<Id> pricebookIds = new List<Id>{ pricebook.Id };
        
        // When
        Test.startTest();
        String batchJobId = DiscountPricebookController.createDiscountedProductsForPricebooks(
            promo.Id, 
            pricebookIds
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, batchJobId, 'Should create batch job for single pricebook');
    }
    
    /**
     * Test PricebookWrapper constructor
     */
    @isTest
    static void testPricebookWrapperConstructor() {
        // Given
        Pricebook2 pricebook = [
            SELECT Id, Name, Description, IsActive 
            FROM Pricebook2 
            WHERE Name = 'Test Pricebook 1' 
            LIMIT 1
        ];
        
        // When
        Test.startTest();
        DiscountPricebookController.PricebookWrapper wrapper = 
            new DiscountPricebookController.PricebookWrapper(pricebook);
        Test.stopTest();
        
        // Then
        System.assertEquals(pricebook.Id, wrapper.Id, 'Id should match');
        System.assertEquals(pricebook.Name, wrapper.Name, 'Name should match');
        System.assertEquals(pricebook.Description, wrapper.Description, 'Description should match');
        System.assertEquals(pricebook.IsActive, wrapper.IsActive, 'IsActive should match');
    }
    
    /**
     * Test PricebookWrapper with null description
     */
    @isTest
    static void testPricebookWrapperWithNullDescription() {
        // Given - Use actual pricebook and update description to null
        Pricebook2 pricebook = [
            SELECT Id, Name, Description, IsActive 
            FROM Pricebook2 
            WHERE Name = 'Test Pricebook 1' 
            LIMIT 1
        ];
        pricebook.Description = null;
        update pricebook;
        
        // Re-query to get updated record
        pricebook = [
            SELECT Id, Name, Description, IsActive 
            FROM Pricebook2 
            WHERE Id = :pricebook.Id
        ];
        
        // When
        Test.startTest();
        DiscountPricebookController.PricebookWrapper wrapper = 
            new DiscountPricebookController.PricebookWrapper(pricebook);
        Test.stopTest();
        
        // Then
        System.assertEquals('', wrapper.Description, 
            'Description should be empty string when null');
    }
    
    /**
     * Test getPricebooksForDiscount returns ordered results
     */
    @isTest
    static void testGetPricebooksReturnsOrderedResults() {
        // Given
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name = 'TRE10OFF' LIMIT 1];
        
        // When
        Test.startTest();
        List<DiscountPricebookController.PricebookWrapper> result = 
            DiscountPricebookController.getPricebooksForDiscount(promo.Id);
        Test.stopTest();
        
        // Then
        if (result.size() > 1) {
            for (Integer i = 0; i < result.size() - 1; i++) {
                System.assert(
                    result[i].Name <= result[i + 1].Name, 
                    'Results should be ordered by Name'
                );
            }
        }
    }
}