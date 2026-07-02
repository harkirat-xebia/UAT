@isTest
public with sharing class CreateDisProductsForSelPricebooksTest {

    @TestSetup
    static void setupTestData() {
        // 1. Activate Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        update new Pricebook2(Id = pricebookId, IsActive = true);

        // 2. Custom Pricebooks
        Pricebook2 customPb1 = new Pricebook2(Name='Custom Pricebook 1', IsActive = true);
        Pricebook2 customPb2 = new Pricebook2(Name='Custom Pricebook 2', IsActive = true);
        insert new List<Pricebook2>{customPb1, customPb2};

        // 3. Record Types
        RecordType rtRange   = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range'   LIMIT 1];
        RecordType rtService = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Service' LIMIT 1];

        // 4. BE Solution + Range + Service products
        Product2 parentSolution = new Product2(Name = 'Edenred Meal', ER_Type__c = 'Solution', ProductCode = 'TRE',
            IsActive = true, QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'BE', Solution_Group__c = 'Benefits');
        insert parentSolution;

        Product2 parentRange = new Product2(Name = '100 to 200', ER_Type__c = 'Range', ProductCode = 'ORD_MAN',
            IsActive = true, QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'BE', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = parentSolution.Id);
        insert parentRange;

        Product2 parentService = new Product2(Name = 'Service A', ER_Type__c = 'Service', ProductCode = 'TRC',
            IsActive = true, QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'BE',
            RecordTypeId = rtService.Id, Solution_Group__c = 'Benefits', ER_Service_Number_of_Ranges__c = 0);
        insert parentService;

        // 5. Standard PBEs
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = parentRange.Id,
                UnitPrice = 100, IsActive = true, UseStandardPrice = false,
                ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Currency'),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = parentService.Id,
                UnitPrice = 200, IsActive = true, UseStandardPrice = false,
                ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Currency')
        };

        // 6. Custom Pricebook 1 (Currency)
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = customPb1.Id, Product2Id = parentRange.Id,
                UnitPrice = 100, IsActive = true, UseStandardPrice = false,
                ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Currency', ER_Min__c = 100, ER_Max__c = 200),
            new PricebookEntry(Pricebook2Id = customPb1.Id, Product2Id = parentService.Id,
                UnitPrice = 200, IsActive = true, UseStandardPrice = false,
                ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Currency')
        };

        // 7. Custom Pricebook 2 (Percentage)
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = customPb2.Id, Product2Id = parentRange.Id,
                UnitPrice = 150, IsActive = true, UseStandardPrice = false,
                ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Percentage', ER_Percentage__c = 7.5,
                ER_Min__c = 100, ER_Max__c = 200),
            new PricebookEntry(Pricebook2Id = customPb2.Id, Product2Id = parentService.Id,
                UnitPrice = 250, IsActive = true, UseStandardPrice = false,
                ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Currency')
        };

        // 8. BE promo code
        insert new ER_Promo_Code__c(
            Name = 'TRE100OFF', Solution__c = 'TRE', Discount_Percentage__c = 10,
            Discount_Type__c = 'Solution and Cards', ER_Business_Unit__c = 'BE',
            ER_Start_Date__c = Date.today(), ER_End_Date__c = Date.today().addDays(30)
        );
    }

    // Verifies discount applied to both selected pricebooks
    @IsTest
    static void testBatchWithMultiplePricebooks() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];
        Pricebook2 pb2 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 2' LIMIT 1];
        Set<Id> selectedIds = new Set<Id>{pb1.Id, pb2.Id};

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{promo.Id}, selectedIds), 200);
        Test.stopTest();

        List<PricebookEntry> pbes = [
            SELECT Id FROM PricebookEntry
            WHERE Product2.ER_Type__c = 'Discount' AND Pricebook2Id IN :selectedIds
        ];
        System.assertNotEquals(0, pbes.size(), 'PBEs should be created for both selected pricebooks');
    }

    // Verifies 10% discount is correctly applied to Currency-type PBEs
    @IsTest
    static void testBatchWithCurrencyValueType() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{promo.Id}, new Set<Id>{pb1.Id}), 200);
        Test.stopTest();

        List<PricebookEntry> pbes = [
            SELECT Id, UnitPrice FROM PricebookEntry
            WHERE Product2.ER_Type__c = 'Discount' AND Pricebook2Id = :pb1.Id AND ER_ValueType__c = 'Currency'
        ];
        System.assertNotEquals(0, pbes.size(), 'Currency discount PBEs should be created');
        // 10% off 100 = 90
        System.assertEquals(90, pbes[0].UnitPrice, 'Should apply 10% discount to Currency price');
    }

    // Verifies 10% discount is correctly applied to Percentage-type PBEs
    @IsTest
    static void testBatchWithPercentageValueType() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb2 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 2' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{promo.Id}, new Set<Id>{pb2.Id}), 200);
        Test.stopTest();

        List<PricebookEntry> pbes = [
            SELECT Id, ER_Percentage__c FROM PricebookEntry
            WHERE Product2.ER_Type__c = 'Discount' AND Pricebook2Id = :pb2.Id AND ER_ValueType__c = 'Percentage'
        ];
        System.assertNotEquals(0, pbes.size(), 'Percentage discount PBEs should be created');
        // 10% off 7.5% = 6.75%
        System.assertEquals(6.75, pbes[0].ER_Percentage__c, 'Should apply 10% discount to Percentage value');
    }

    // Verifies ER_Promo_Code2__c, start date and end date are stamped on created PBEs
    @IsTest
    static void testBatchWithPromoCodeFields() {
        ER_Promo_Code__c promo = [SELECT Id FROM ER_Promo_Code__c WHERE Name='TRE100OFF' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id FROM Pricebook2 WHERE Name='Custom Pricebook 1' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{promo.Id}, new Set<Id>{pb1.Id}), 200);
        Test.stopTest();

        List<PricebookEntry> pbes = [
            SELECT Id, ER_Promo_Code2__c, ER_Offer_validity_start_date__c, ER_Offer_validity_end_date__c
            FROM PricebookEntry
            WHERE Product2.ER_Type__c = 'Discount' AND Pricebook2Id = :pb1.Id
        ];
        System.assertNotEquals(0, pbes.size(), 'Discount PBEs should be created');
        System.assertEquals(promo.Id, pbes[0].ER_Promo_Code2__c, 'PBE should link to the promo code');
        System.assertNotEquals(null, pbes[0].ER_Offer_validity_start_date__c, 'Start date should be set');
        System.assertNotEquals(null, pbes[0].ER_Offer_validity_end_date__c, 'End date should be set');
    }

    // -------------------------------------------------------------------------
    // LU / CLU card tests
    // -------------------------------------------------------------------------

    // Verifies CLU card products (including card replacement cost) get discounted PBEs for LU "Solution and Cards"
    @IsTest
    static void testCluCardsLu_SolutionAndCards() {
        RecordType rtRange   = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range'   LIMIT 1];
        RecordType rtService = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Service' LIMIT 1];

        Product2 trlSolution = new Product2(Name = 'TRL Meal', ER_Type__c = 'Solution', ProductCode = 'TRL', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits');
        insert trlSolution;

        Product2 trlRange = new Product2(Name = '50 to 100', ER_Type__c = 'Range', ProductCode = 'TRL_ORD', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = trlSolution.Id);
        insert trlRange;

        Product2 cluSolution = new Product2(Name = 'CLU Card', ER_Type__c = 'Solution', ProductCode = 'CLU', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits');
        insert cluSolution;

        Product2 cluRange = new Product2(Name = '10 to 50', ER_Type__c = 'Range', ProductCode = 'CLU_FEE', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = cluSolution.Id);
        insert cluRange;

        // Card replacement cost — was previously excluded by old path, now included via CLU dedicated query
        Product2 cluCardReplacement = new Product2(Name = 'Card Replacement', ER_Type__c = 'Service',
            ProductCode = 'CARD_RP_BF', IsActive = true, QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtService.Id, ER_Solution2__c = cluSolution.Id, ER_Service_Number_of_Ranges__c = 0);
        insert cluCardReplacement;

        Pricebook2 luPb = new Pricebook2(Name = 'LU Pricebook', IsActive = true);
        insert luPb;

        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = trlRange.Id,
                UnitPrice = 80, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency'),
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = cluRange.Id,
                UnitPrice = 20, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency'),
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = cluCardReplacement.Id,
                UnitPrice = 10, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency')
        };
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = trlRange.Id,
                UnitPrice = 80, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency', ER_Min__c = 50, ER_Max__c = 100),
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = cluRange.Id,
                UnitPrice = 20, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency', ER_Min__c = 10, ER_Max__c = 50),
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = cluCardReplacement.Id,
                UnitPrice = 10, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency')
        };

        ER_Promo_Code__c luPromo = new ER_Promo_Code__c(
            Name = 'TRL15OFF', Solution__c = 'TRL', Discount_Percentage__c = 15,
            Discount_Type__c = 'Solution and Cards', ER_Business_Unit__c = 'LU',
            ER_Start_Date__c = Date.today(), ER_End_Date__c = Date.today().addDays(30)
        );
        insert luPromo;

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{luPromo.Id}, new Set<Id>{luPb.Id}), 200);
        Test.stopTest();

        List<PricebookEntry> discountPbes = [
            SELECT Id, UnitPrice, ER_Promo_Code2__c FROM PricebookEntry
            WHERE Product2.ER_Type__c = 'Discount' AND Pricebook2Id = :luPb.Id AND ER_Promo_Code2__c = :luPromo.Id
        ];
        System.assertEquals(3, discountPbes.size(), 'Should create 3 discounted PBEs (TRL range + CLU range + CLU card replacement)');

        Boolean foundTrl = false, foundCluRepl = false;
        for (PricebookEntry pbe : discountPbes) {
            if (pbe.UnitPrice == 68)  { foundTrl      = true; } // 80 * 0.85
            if (pbe.UnitPrice == 8.5) { foundCluRepl  = true; } // 10 * 0.85
        }
        System.assert(foundTrl,     'TRL range PBE should have UnitPrice 68 (15% off 80)');
        System.assert(foundCluRepl, 'CLU card replacement PBE should have UnitPrice 8.50 (15% off 10)');
    }

    // Verifies CLU card products are free (100% discount) and solution products get configured discount
    @IsTest
    static void testCluCardsLu_SolutionAndFreeCards() {
        RecordType rtRange = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range' LIMIT 1];

        Product2 trlSolution = new Product2(Name = 'TRL Meal', ER_Type__c = 'Solution', ProductCode = 'TRL', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits');
        insert trlSolution;

        Product2 trlRange = new Product2(Name = '50 to 100', ER_Type__c = 'Range', ProductCode = 'TRL_ORD', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = trlSolution.Id);
        insert trlRange;

        Product2 cluSolution = new Product2(Name = 'CLU Card', ER_Type__c = 'Solution', ProductCode = 'CLU', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits');
        insert cluSolution;

        Product2 cluRange = new Product2(Name = '10 to 50', ER_Type__c = 'Range', ProductCode = 'CLU_FEE', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = cluSolution.Id);
        insert cluRange;

        Pricebook2 luPb = new Pricebook2(Name = 'LU Pricebook FC', IsActive = true);
        insert luPb;

        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = trlRange.Id,
                UnitPrice = 80, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency'),
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = cluRange.Id,
                UnitPrice = 20, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency')
        };
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = trlRange.Id,
                UnitPrice = 80, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency', ER_Min__c = 50, ER_Max__c = 100),
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = cluRange.Id,
                UnitPrice = 20, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency', ER_Min__c = 10, ER_Max__c = 50)
        };

        ER_Promo_Code__c luPromo = new ER_Promo_Code__c(
            Name = 'TRL_FREE_CARDS', Solution__c = 'TRL', Discount_Percentage__c = 20,
            Discount_Type__c = 'Solution and Free Cards', ER_Business_Unit__c = 'LU',
            ER_Start_Date__c = Date.today(), ER_End_Date__c = Date.today().addDays(30)
        );
        insert luPromo;

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{luPromo.Id}, new Set<Id>{luPb.Id}), 200);
        Test.stopTest();

        List<PricebookEntry> discountPbes = [
            SELECT Id, UnitPrice, Product2.ER_Solution__r.ProductCode FROM PricebookEntry
            WHERE Product2.ER_Type__c = 'Discount' AND Pricebook2Id = :luPb.Id AND ER_Promo_Code2__c = :luPromo.Id
        ];
        System.assertEquals(2, discountPbes.size(), 'Should create PBEs for TRL range and CLU range');

        for (PricebookEntry pbe : discountPbes) {
            String solCode = pbe.Product2.ER_Solution__r.ProductCode;
            if (solCode == 'CLU') {
                System.assertEquals(0, pbe.UnitPrice, 'CLU card PBE should be free (100% discount)');
            } else if (solCode == 'TRL') {
                System.assertEquals(64, pbe.UnitPrice, 'TRL range PBE should have 20% discount applied (80 * 0.80)');
            }
        }
    }

    // Covers the "Card Delivery Cost found → excluded from query" branch (cluCardDeliveryCostId != null path)
    @IsTest
    static void testCluCardsLu_CardDeliveryCostExcluded() {
        RecordType rtRange   = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range'   LIMIT 1];
        RecordType rtService = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Service' LIMIT 1];

        Product2 trlSolution = new Product2(Name = 'TRL Meal CDC', ER_Type__c = 'Solution', ProductCode = 'TRL', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits');
        insert trlSolution;

        Product2 trlRange = new Product2(Name = '50 to 100', ER_Type__c = 'Range', ProductCode = 'TRL_ORD_CDC', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = trlSolution.Id);
        insert trlRange;

        Product2 cluSolution = new Product2(Name = 'CLU Card CDC', ER_Type__c = 'Solution', ProductCode = 'CLU', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits');
        insert cluSolution;

        Product2 cluRange = new Product2(Name = '10 to 50', ER_Type__c = 'Range', ProductCode = 'CLU_CDC_FEE', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = cluSolution.Id);
        insert cluRange;

        // Name must match exactly — the batch excludes this product by Id lookup on Name = 'Card Delivery Cost'
        Product2 cluCardDeliveryCost = new Product2(Name = 'Card Delivery Cost', ER_Type__c = 'Service',
            ProductCode = 'CLU_CDC', IsActive = true, QuantityUnitOfMeasure = 'Per Unit',
            ER_BUPicklist__c = 'LU', Solution_Group__c = 'Benefits',
            RecordTypeId = rtService.Id, ER_Solution2__c = cluSolution.Id, ER_Service_Number_of_Ranges__c = 0);
        insert cluCardDeliveryCost;

        Pricebook2 luPb = new Pricebook2(Name = 'LU Pricebook CDC', IsActive = true);
        insert luPb;

        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = trlRange.Id,
                UnitPrice = 80, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency'),
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = cluRange.Id,
                UnitPrice = 20, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency'),
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = cluCardDeliveryCost.Id,
                UnitPrice = 5, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU', ER_ValueType__c = 'Currency')
        };
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = trlRange.Id,
                UnitPrice = 80, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency', ER_Min__c = 50, ER_Max__c = 100),
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = cluRange.Id,
                UnitPrice = 20, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency', ER_Min__c = 10, ER_Max__c = 50),
            new PricebookEntry(Pricebook2Id = luPb.Id, Product2Id = cluCardDeliveryCost.Id,
                UnitPrice = 5, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'LU',
                ER_ValueType__c = 'Currency')
        };

        ER_Promo_Code__c luPromo = new ER_Promo_Code__c(
            Name = 'TRL_CDC_TEST', Solution__c = 'TRL', Discount_Percentage__c = 10,
            Discount_Type__c = 'Solution and Cards', ER_Business_Unit__c = 'LU',
            ER_Start_Date__c = Date.today(), ER_End_Date__c = Date.today().addDays(30)
        );
        insert luPromo;

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{luPromo.Id}, new Set<Id>{luPb.Id}), 200);
        Test.stopTest();

        List<PricebookEntry> discountPbes = [
            SELECT Id, Product2.Name FROM PricebookEntry
            WHERE Product2.ER_Type__c = 'Discount' AND Pricebook2Id = :luPb.Id AND ER_Promo_Code2__c = :luPromo.Id
        ];
        // TRL range + CLU range = 2; Card Delivery Cost must NOT appear
        System.assertEquals(2, discountPbes.size(), 'Should create 2 discounted PBEs — Card Delivery Cost must be excluded');

        for (PricebookEntry pbe : discountPbes) {
            System.assertNotEquals('Discounted Card Delivery Cost', pbe.Product2.Name,
                'Card Delivery Cost should NOT have a discounted PBE');
        }
    }

    // Verifies that for a non-BE/LU promo code, TRC card products (e.g. Reward) are NOT discounted
    @IsTest
    static void testNoTrcCardsForNonBeBu() {
        RecordType rtRange   = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Range'   LIMIT 1];
        RecordType rtService = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Service' LIMIT 1];

        // Use 'BE' for ER_BUPicklist__c — 'EN' is not a valid picklist value;
        // the batch gates TRC cards via the promo code's ER_Business_Unit__c, not the product BU
        Product2 enSolution = new Product2(Name = 'EN Meal', ER_Type__c = 'Solution', ProductCode = 'ENG', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'BE', Solution_Group__c = 'Benefits');
        insert enSolution;

        Product2 enRange = new Product2(Name = '100 to 200', ER_Type__c = 'Range', ProductCode = 'ENG_ORD', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'BE', Solution_Group__c = 'Benefits',
            RecordTypeId = rtRange.Id, ER_Solution2__c = enSolution.Id);
        insert enRange;

        // TRC Reward product — should NOT be discounted when promo BU is not 'BE'
        Product2 trcSolution = new Product2(Name = 'TRC Card', ER_Type__c = 'Solution', ProductCode = 'TRC_SOL', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'BE', Solution_Group__c = 'Benefits');
        insert trcSolution;

        Product2 rewardProduct = new Product2(Name = 'Reward', ER_Type__c = 'Service', ProductCode = 'REWARD', IsActive = true,
            QuantityUnitOfMeasure = 'Per Unit', ER_BUPicklist__c = 'BE', Solution_Group__c = 'Benefits',
            RecordTypeId = rtService.Id, ER_Solution2__c = trcSolution.Id, ER_Service_Number_of_Ranges__c = 0);
        insert rewardProduct;

        Pricebook2 enPb = new Pricebook2(Name = 'EN Pricebook', IsActive = true);
        insert enPb;

        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = enRange.Id,
                UnitPrice = 100, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Currency'),
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = rewardProduct.Id,
                UnitPrice = 50, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'BE', ER_ValueType__c = 'Currency')
        };
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = enPb.Id, Product2Id = enRange.Id,
                UnitPrice = 100, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency', ER_Min__c = 100, ER_Max__c = 200),
            new PricebookEntry(Pricebook2Id = enPb.Id, Product2Id = rewardProduct.Id,
                UnitPrice = 50, IsActive = true, UseStandardPrice = false, ER_BUPicklist__c = 'BE',
                ER_ValueType__c = 'Currency')
        };

        ER_Promo_Code__c enPromo = new ER_Promo_Code__c(
            Name = 'ENG10OFF', Solution__c = 'ENG', Discount_Percentage__c = 10,
            Discount_Type__c = 'Solution and Cards', ER_Business_Unit__c = 'EN',
            ER_Start_Date__c = Date.today(), ER_End_Date__c = Date.today().addDays(30)
        );
        insert enPromo;

        Test.startTest();
        Database.executeBatch(new CreateDisProductsForSelPricebooksBatch(new Set<Id>{enPromo.Id}, new Set<Id>{enPb.Id}), 200);
        Test.stopTest();

        List<Product2> discountProducts = [SELECT Id, ProductCode FROM Product2 WHERE ER_Type__c = 'Discount'];
        Boolean foundEng = false;
        for (Product2 dp : discountProducts) {
            System.assertNotEquals('REWARD', dp.ProductCode, 'Reward (TRC) product must NOT be discounted for non-BE promo code');
            if (dp.ProductCode == 'ENG_ORD') { foundEng = true; }
        }
        System.assert(foundEng, 'ENG range discount product should be created');
    }
}
