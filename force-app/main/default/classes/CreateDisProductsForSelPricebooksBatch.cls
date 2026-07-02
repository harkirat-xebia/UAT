/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : CreateDisProductsForSelPricebooksBatch
 * Author          : Harkirat Singh
 * Created Date    : May 8, 2026
 * Last Modified On: June 30, 2026
 * Description     : This class creates pbe for the discount code for the selected pricebook in the lwc component
 *
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  May 8, 2026   │ Harkirat Singh │ Initial version
 *  May 12, 2026  │ Harkirat Singh │ Added support for Solution and Cards, Solution and Free Cards
 *  Jun 30, 2026  │ Harkirat Singh │ Fixed TRC to BE-only; added CLU card handling for LU to cover
 *                │                │ card replacement and free-card scenarios; removed duplicate
 *                │                │ additionalServiceCode path that caused TRC/CLU double-processing
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public class CreateDisProductsForSelPricebooksBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<Id> discountCodeIds;
    private Set<Id> selectedPricebookIds;
    private static final String DISCOUNT_PRODUCT_RECORDTYPE_DEVELOPERNAME = 'Discount';
    private static final String TRC_SOLUTION_CODE = 'TRC';
    private static final String CLU_SOLUTION_CODE = 'CLU';
    private Id discountRecordTypeId;

    public CreateDisProductsForSelPricebooksBatch(Set<Id> discountCodeIds, Set<Id> selectedPricebookIds) {
        this.discountCodeIds = discountCodeIds;
        this.selectedPricebookIds = selectedPricebookIds;

        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = :DISCOUNT_PRODUCT_RECORDTYPE_DEVELOPERNAME LIMIT 1];
        discountRecordTypeId = rt != null ? rt.Id : null;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Solution__c, Discount_Percentage__c, Discount_Type__c,
                   ER_Business_Unit__c, ER_End_Date__c, ER_Start_Date__c
            FROM ER_Promo_Code__c
            WHERE Id IN :discountCodeIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ER_Promo_Code__c> discountCodes) {
        System.debug('=== BATCH EXECUTE START ===');
        System.debug('Processing ' + discountCodes.size() + ' discount codes');
        System.debug('Selected Pricebooks: ' + selectedPricebookIds);
        System.debug('Discount Codes: ' + discountCodes);
        if (discountCodes.isEmpty()) {
            System.debug('No discount codes to process');
            return;
        }

        // Build solution code maps
        Map<String, List<ER_Promo_Code__c>> solCodeToDiscounts = new Map<String, List<ER_Promo_Code__c>>();
        Map<String, List<ER_Promo_Code__c>> serviceCodeToDiscounts = new Map<String, List<ER_Promo_Code__c>>();
        Set<String> trcSolutionCodes = new Set<String>();
        Set<String> cluSolutionCodes = new Set<String>();

        System.debug('=== BUILDING SOLUTION CODE MAPS ===');
        for (ER_Promo_Code__c dc : discountCodes) {
            String solCode = dc.Solution__c;
            if (String.isNotBlank(solCode)) {
                if (!solCodeToDiscounts.containsKey(solCode)) {
                    solCodeToDiscounts.put(solCode, new List<ER_Promo_Code__c>());
                }
                solCodeToDiscounts.get(solCode).add(dc);

                // Add card solution codes per BU — TRC for BE, CLU for LU.
                // Restricting to BE prevents TRC products (e.g. Reward) from being
                // discounted when a non-BE promo code is used.
                if (dc.Discount_Type__c == 'Solution and Cards' || dc.Discount_Type__c == 'Solution and Free Cards') {
                    if (dc.ER_Business_Unit__c == 'BE') {
                        trcSolutionCodes.add(TRC_SOLUTION_CODE);
                    } else if (dc.ER_Business_Unit__c == 'LU') {
                        cluSolutionCodes.add(CLU_SOLUTION_CODE);
                    }
                } else if (solCode == Constants.ADDITIONAL_SERVICE_CODE_BE || solCode == Constants.ADDITIONAL_SERVICE_CODE_LU) {
                    if (!serviceCodeToDiscounts.containsKey(solCode)) {
                        serviceCodeToDiscounts.put(solCode, new List<ER_Promo_Code__c>());
                    }
                    serviceCodeToDiscounts.get(solCode).add(dc);
                    System.debug('Added service code from solution: ' + solCode);
                }
            }
        }
        System.debug('solCodeToDiscounts size: ' + solCodeToDiscounts.size());
        System.debug('solCodeToDiscounts keys: ' + solCodeToDiscounts.keySet());
        System.debug('serviceCodeToDiscounts size: ' + serviceCodeToDiscounts.size());
        System.debug('trcSolutionCodes: ' + trcSolutionCodes);
        System.debug('cluSolutionCodes: ' + cluSolutionCodes);

        if (solCodeToDiscounts.isEmpty()) {
            System.debug('solCodeToDiscounts is EMPTY - EXITING');
            return;
        }

        // Fetch parent Range products
        System.debug('=== QUERYING PARENT PRODUCTS ===');
        System.debug('Query filter: ER_Solution2__r.ProductCode IN ' + solCodeToDiscounts.keySet());
        List<Product2> parentProducts = [
            SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                   ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c,
                   Solution_Group__c, QuantityUnitOfMeasure
            FROM Product2
            WHERE ER_Type__c = 'Range'
              AND ER_Solution2__r.ProductCode IN :solCodeToDiscounts.keySet()
              AND IsActive = true
        ];
        System.debug('Found ' + parentProducts.size() + ' parent Range products');

        // Fetch parent Service products
        List<Product2> parentServiceProducts = [
            SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                   ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c,
                   Solution_Group__c, QuantityUnitOfMeasure, ER_Service_Number_of_Ranges__c
            FROM Product2
            WHERE ER_Type__c = 'Service'
              AND ProductCode != 'CARD_RP_BF'
              AND ProductCode != NULL
              AND ER_Solution2__r.ProductCode IN :serviceCodeToDiscounts.keySet()
              AND IsActive = true
              AND ER_Service_Number_of_Ranges__c = 0
        ];

        System.debug('Found ' + parentServiceProducts.size() + ' service products');

        if (!parentServiceProducts.isEmpty()) {
            parentProducts.addAll(parentServiceProducts);
        }

        // Fetch TRC card products for BE promo codes (Range + Service, excluding Card Delivery Cost)
        List<Product2> trcCardProducts = new List<Product2>();
        if (!trcSolutionCodes.isEmpty()) {
            List<Product2> cardDeliveryCostList = [
                SELECT Id
                FROM Product2
                WHERE Name = 'Card Delivery Cost'
                AND ER_Type__c = 'Service'
                AND ER_Solution2__r.ProductCode = :TRC_SOLUTION_CODE
                LIMIT 1
            ];
            Id cardDeliveryCostId = !cardDeliveryCostList.isEmpty() ? cardDeliveryCostList[0].Id : null;

            System.debug('Card Delivery Cost ID to exclude: ' + cardDeliveryCostId);
            if (cardDeliveryCostId != null) {
                trcCardProducts = [
                    SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                        ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c,
                        Solution_Group__c, QuantityUnitOfMeasure
                    FROM Product2
                    WHERE ER_Solution2__r.ProductCode = :TRC_SOLUTION_CODE
                    AND IsActive = true
                    AND (ER_Type__c = 'Range' OR ER_Type__c = 'Service')
                    AND Id != :cardDeliveryCostId
                ];
            } else {
                trcCardProducts = [
                    SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                        ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c,
                        Solution_Group__c, QuantityUnitOfMeasure
                    FROM Product2
                    WHERE ER_Solution2__r.ProductCode = :TRC_SOLUTION_CODE
                    AND IsActive = true
                    AND (ER_Type__c = 'Range' OR ER_Type__c = 'Service')
                ];
            }
            System.debug('Found ' + trcCardProducts.size() + ' TRC card products (excluding Card Delivery Cost)');
        }

        // Fetch CLU card products for LU promo codes (Range + Service, excluding Card Delivery Cost).
        // Using the same dedicated query pattern as TRC ensures card replacement cost
        // (whether Range or Service, regardless of CARD_RP_BF product code) is included.
        List<Product2> cluCardProducts = new List<Product2>();
        if (!cluSolutionCodes.isEmpty()) {
            List<Product2> cluCardDeliveryCostList = [
                SELECT Id
                FROM Product2
                WHERE Name = 'Card Delivery Cost'
                AND ER_Type__c = 'Service'
                AND ER_Solution2__r.ProductCode = :CLU_SOLUTION_CODE
                LIMIT 1
            ];
            Id cluCardDeliveryCostId = !cluCardDeliveryCostList.isEmpty() ? cluCardDeliveryCostList[0].Id : null;

            System.debug('CLU Card Delivery Cost ID to exclude: ' + cluCardDeliveryCostId);
            if (cluCardDeliveryCostId != null) {
                cluCardProducts = [
                    SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                        ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c,
                        Solution_Group__c, QuantityUnitOfMeasure
                    FROM Product2
                    WHERE ER_Solution2__r.ProductCode = :CLU_SOLUTION_CODE
                    AND IsActive = true
                    AND (ER_Type__c = 'Range' OR ER_Type__c = 'Service')
                    AND Id != :cluCardDeliveryCostId
                ];
            } else {
                cluCardProducts = [
                    SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                        ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c,
                        Solution_Group__c, QuantityUnitOfMeasure
                    FROM Product2
                    WHERE ER_Solution2__r.ProductCode = :CLU_SOLUTION_CODE
                    AND IsActive = true
                    AND (ER_Type__c = 'Range' OR ER_Type__c = 'Service')
                ];
            }
            System.debug('Found ' + cluCardProducts.size() + ' CLU card products (excluding Card Delivery Cost)');
        }

        if (parentProducts.isEmpty() && trcCardProducts.isEmpty() && cluCardProducts.isEmpty()) {
            System.debug('No parent products found');
            return;
        }

        // Fetch PricebookEntries for solution products - ONLY FOR SELECTED PRICEBOOKS
        List<PricebookEntry> parentPBEs = [
            SELECT Id, Product2Id, Pricebook2Id, UnitPrice, ER_Percentage__c, IsActive,
                   UseStandardPrice, CurrencyIsoCode, ER_BUPicklist__c, ER_Max__c,
                   ER_Min__c, ER_ValueType__c, Pricebook2.IsActive
            FROM PricebookEntry
            WHERE Product2Id IN :parentProducts
            AND Pricebook2.IsActive = TRUE
            AND (Pricebook2.IsStandard = TRUE OR Pricebook2Id IN :selectedPricebookIds)
            AND IsActive = TRUE
        ];

        System.debug('Found ' + parentPBEs.size() + ' pricebook entries for selected pricebooks');

        // Fetch PricebookEntries for TRC card products
        List<PricebookEntry> trcCardPBEs = new List<PricebookEntry>();
        if (!trcCardProducts.isEmpty()) {
            trcCardPBEs = [
                SELECT Id, Product2Id, Pricebook2Id, UnitPrice, ER_Percentage__c, IsActive,
                       UseStandardPrice, CurrencyIsoCode, ER_BUPicklist__c, ER_Max__c,
                       ER_Min__c, ER_ValueType__c, Pricebook2.IsActive
                FROM PricebookEntry
                WHERE Product2Id IN :trcCardProducts
                  AND (Pricebook2.IsStandard = TRUE OR Pricebook2Id IN :selectedPricebookIds)
                  AND Pricebook2.IsActive = TRUE
                  AND IsActive = TRUE
            ];

            System.debug('Found ' + trcCardPBEs.size() + ' TRC card pricebook entries');
        }

        // Fetch PricebookEntries for CLU card products
        List<PricebookEntry> cluCardPBEs = new List<PricebookEntry>();
        if (!cluCardProducts.isEmpty()) {
            cluCardPBEs = [
                SELECT Id, Product2Id, Pricebook2Id, UnitPrice, ER_Percentage__c, IsActive,
                       UseStandardPrice, CurrencyIsoCode, ER_BUPicklist__c, ER_Max__c,
                       ER_Min__c, ER_ValueType__c, Pricebook2.IsActive
                FROM PricebookEntry
                WHERE Product2Id IN :cluCardProducts
                  AND (Pricebook2.IsStandard = TRUE OR Pricebook2Id IN :selectedPricebookIds)
                  AND Pricebook2.IsActive = TRUE
                  AND IsActive = TRUE
            ];

            System.debug('Found ' + cluCardPBEs.size() + ' CLU card pricebook entries');
        }

        if (parentPBEs.isEmpty() && trcCardPBEs.isEmpty() && cluCardPBEs.isEmpty()) {
            System.debug('No pricebook entries found for selected pricebooks');
            return;
        }

        // Map PBEs by Product
        Map<Id, List<PricebookEntry>> parentPBEMap = new Map<Id, List<PricebookEntry>>();
        Set<Id> parentPricebookIds = new Set<Id>();

        for (PricebookEntry pbe : parentPBEs) {
            if (!parentPBEMap.containsKey(pbe.Product2Id)) {
                parentPBEMap.put(pbe.Product2Id, new List<PricebookEntry>());
            }
            parentPBEMap.get(pbe.Product2Id).add(pbe);
            parentPricebookIds.add(pbe.Pricebook2Id);
        }

        // Map TRC card PBEs by Product
        Map<Id, List<PricebookEntry>> trcCardPBEMap = new Map<Id, List<PricebookEntry>>();
        for (PricebookEntry pbe : trcCardPBEs) {
            if (!trcCardPBEMap.containsKey(pbe.Product2Id)) {
                trcCardPBEMap.put(pbe.Product2Id, new List<PricebookEntry>());
            }
            trcCardPBEMap.get(pbe.Product2Id).add(pbe);
            parentPricebookIds.add(pbe.Pricebook2Id);
        }

        // Map CLU card PBEs by Product
        Map<Id, List<PricebookEntry>> cluCardPBEMap = new Map<Id, List<PricebookEntry>>();
        for (PricebookEntry pbe : cluCardPBEs) {
            if (!cluCardPBEMap.containsKey(pbe.Product2Id)) {
                cluCardPBEMap.put(pbe.Product2Id, new List<PricebookEntry>());
            }
            cluCardPBEMap.get(pbe.Product2Id).add(pbe);
            parentPricebookIds.add(pbe.Pricebook2Id);
        }

        // Get standard pricebook
        Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (stdPb == null) {
            return;
        }
        Id standardPricebookId = stdPb.Id;
        boolean isStandardPricebookSelected = selectedPricebookIds.contains(standardPricebookId);

        // Create discounted products for solution products
        List<Product2> productsToInsert = new List<Product2>();
        Map<Id, Id> parentToDiscountedMap = new Map<Id, Id>();
        List<String> preservedParentOrderKeys = new List<String>();
        Integer lineOrder = 0;

        for (Product2 parent : parentProducts) {
            if (!parentPBEMap.containsKey(parent.Id)) {
                continue;
            }

            Decimal minAmount;
            Decimal maxAmount;

            if (parent.ER_Type__c == 'Range') {
                if (parent.Name != null && parent.Name.contains(' to ')) {
                    String[] parts = parent.Name.split(' to ');
                    try {
                        minAmount = parts.size() > 0 ? Decimal.valueOf(parts[0].trim()) : null;
                        maxAmount = parts.size() > 1 ? Decimal.valueOf(parts[1].trim()) : null;
                    } catch (Exception e) {
                        minAmount = null;
                        maxAmount = null;
                    }
                } else if (parent.Name != null && parent.Name.startsWith('>')) {
                    try {
                        minAmount = Decimal.valueOf(parent.Name.replace('>', '').trim());
                    } catch (Exception e) {
                        minAmount = null;
                    }
                    maxAmount = null;
                } else {
                    minAmount = null;
                    maxAmount = null;
                }
            } else {
                minAmount = null;
                maxAmount = null;
            }

            Product2 discounted = new Product2(
                Name = 'Discounted ' + (parent.Name == null ? '' : parent.Name),
                ER_Type__c = 'Discount',
                BE_Maximum_Amount__c = maxAmount,
                BE_Minimum_Amount__c = minAmount,
                ER_Line_Order__c = lineOrder++,
                Solution_Group__c = parent.Solution_Group__c,
                IsActive = true,
                ProductCode = parent.ProductCode,
                RecordTypeId = discountRecordTypeId,
                ER_Solution__c = parent.Id,
                QuantityUnitOfMeasure = parent.QuantityUnitOfMeasure,
                ER_BUPicklist__c = parent.ER_BUPicklist__c
            );

            productsToInsert.add(discounted);
            preservedParentOrderKeys.add(parent.Id);
        }

        // Create discounted products for TRC card products
        Map<Id, Id> trcCardToDiscountedMap = new Map<Id, Id>();
        List<String> preservedTrcCardOrderKeys = new List<String>();

        for (Product2 trcCard : trcCardProducts) {
            if (!trcCardPBEMap.containsKey(trcCard.Id)) {
                continue;
            }

            Decimal minAmount;
            Decimal maxAmount;

            if (trcCard.ER_Type__c == 'Range') {
                if (trcCard.Name != null && trcCard.Name.contains(' to ')) {
                    String[] parts = trcCard.Name.split(' to ');
                    try {
                        minAmount = parts.size() > 0 ? Decimal.valueOf(parts[0].trim()) : null;
                        maxAmount = parts.size() > 1 ? Decimal.valueOf(parts[1].trim()) : null;
                    } catch (Exception e) {
                        minAmount = null;
                        maxAmount = null;
                    }
                } else if (trcCard.Name != null && trcCard.Name.startsWith('>')) {
                    try {
                        minAmount = Decimal.valueOf(trcCard.Name.replace('>', '').trim());
                    } catch (Exception e) {
                        minAmount = null;
                    }
                    maxAmount = null;
                } else {
                    minAmount = null;
                    maxAmount = null;
                }
            } else {
                minAmount = null;
                maxAmount = null;
            }

            Product2 discounted = new Product2(
                Name = 'Discounted ' + (trcCard.Name == null ? '' : trcCard.Name),
                ER_Type__c = 'Discount',
                BE_Maximum_Amount__c = maxAmount,
                BE_Minimum_Amount__c = minAmount,
                ER_Line_Order__c = lineOrder++,
                Solution_Group__c = trcCard.Solution_Group__c,
                IsActive = true,
                ProductCode = trcCard.ProductCode,
                RecordTypeId = discountRecordTypeId,
                ER_Solution__c = trcCard.Id,
                QuantityUnitOfMeasure = trcCard.QuantityUnitOfMeasure,
                ER_BUPicklist__c = trcCard.ER_BUPicklist__c
            );

            productsToInsert.add(discounted);
            preservedTrcCardOrderKeys.add(trcCard.Id);
        }

        // Create discounted products for CLU card products
        Map<Id, Id> cluCardToDiscountedMap = new Map<Id, Id>();
        List<String> preservedCluCardOrderKeys = new List<String>();

        for (Product2 cluCard : cluCardProducts) {
            if (!cluCardPBEMap.containsKey(cluCard.Id)) {
                continue;
            }

            Decimal minAmount;
            Decimal maxAmount;

            if (cluCard.ER_Type__c == 'Range') {
                if (cluCard.Name != null && cluCard.Name.contains(' to ')) {
                    String[] parts = cluCard.Name.split(' to ');
                    try {
                        minAmount = parts.size() > 0 ? Decimal.valueOf(parts[0].trim()) : null;
                        maxAmount = parts.size() > 1 ? Decimal.valueOf(parts[1].trim()) : null;
                    } catch (Exception e) {
                        minAmount = null;
                        maxAmount = null;
                    }
                } else if (cluCard.Name != null && cluCard.Name.startsWith('>')) {
                    try {
                        minAmount = Decimal.valueOf(cluCard.Name.replace('>', '').trim());
                    } catch (Exception e) {
                        minAmount = null;
                    }
                    maxAmount = null;
                } else {
                    minAmount = null;
                    maxAmount = null;
                }
            } else {
                minAmount = null;
                maxAmount = null;
            }

            Product2 discounted = new Product2(
                Name = 'Discounted ' + (cluCard.Name == null ? '' : cluCard.Name),
                ER_Type__c = 'Discount',
                BE_Maximum_Amount__c = maxAmount,
                BE_Minimum_Amount__c = minAmount,
                ER_Line_Order__c = lineOrder++,
                Solution_Group__c = cluCard.Solution_Group__c,
                IsActive = true,
                ProductCode = cluCard.ProductCode,
                RecordTypeId = discountRecordTypeId,
                ER_Solution__c = cluCard.Id,
                QuantityUnitOfMeasure = cluCard.QuantityUnitOfMeasure,
                ER_BUPicklist__c = cluCard.ER_BUPicklist__c
            );

            productsToInsert.add(discounted);
            preservedCluCardOrderKeys.add(cluCard.Id);
        }

        if (productsToInsert.isEmpty()) {
            return;
        }

        insert productsToInsert;

        // Map parent to discounted product for solution products
        for (Integer i = 0; i < preservedParentOrderKeys.size(); i++) {
            if (i < productsToInsert.size()) {
                parentToDiscountedMap.put(preservedParentOrderKeys[i], productsToInsert[i].Id);
            }
        }

        // Map TRC card to discounted product
        Integer trcStartIndex = preservedParentOrderKeys.size();
        for (Integer i = 0; i < preservedTrcCardOrderKeys.size(); i++) {
            if ((trcStartIndex + i) < productsToInsert.size()) {
                trcCardToDiscountedMap.put(preservedTrcCardOrderKeys[i], productsToInsert[trcStartIndex + i].Id);
            }
        }

        // Map CLU card to discounted product
        Integer cluStartIndex = preservedParentOrderKeys.size() + preservedTrcCardOrderKeys.size();
        for (Integer i = 0; i < preservedCluCardOrderKeys.size(); i++) {
            if ((cluStartIndex + i) < productsToInsert.size()) {
                cluCardToDiscountedMap.put(preservedCluCardOrderKeys[i], productsToInsert[cluStartIndex + i].Id);
            }
        }

        // Create PricebookEntries
        List<PricebookEntry> standardPbesToInsert = new List<PricebookEntry>();
        List<PricebookEntry> customPbesToInsert = new List<PricebookEntry>();
        Map<String, PricebookEntry> existingPBEMap = new Map<String, PricebookEntry>();

        // Build a map of parent product to its discount codes
        Map<Id, List<ER_Promo_Code__c>> parentToDiscountsMap = new Map<Id, List<ER_Promo_Code__c>>();

        // Map solution products to their discounts
        for (Product2 parent : parentProducts) {
            if (parentToDiscountedMap.containsKey(parent.Id) && solCodeToDiscounts.containsKey(parent.ER_Solution2__r.ProductCode)) {
                parentToDiscountsMap.put(parent.Id, solCodeToDiscounts.get(parent.ER_Solution2__r.ProductCode));
            }
        }

        // Map TRC products to their discounts
        for (Product2 trcCard : trcCardProducts) {
            if (trcCardToDiscountedMap.containsKey(trcCard.Id)) {
                List<ER_Promo_Code__c> applicableDiscounts = new List<ER_Promo_Code__c>();
                for (ER_Promo_Code__c discount : discountCodes) {
                    if (discount.Discount_Type__c == 'Solution and Cards' || discount.Discount_Type__c == 'Solution and Free Cards') {
                        applicableDiscounts.add(discount);
                    }
                }
                if (!applicableDiscounts.isEmpty()) {
                    parentToDiscountsMap.put(trcCard.Id, applicableDiscounts);
                }
            }
        }

        // Map CLU products to their discounts
        for (Product2 cluCard : cluCardProducts) {
            if (cluCardToDiscountedMap.containsKey(cluCard.Id)) {
                List<ER_Promo_Code__c> applicableDiscounts = new List<ER_Promo_Code__c>();
                for (ER_Promo_Code__c discount : discountCodes) {
                    if (discount.Discount_Type__c == 'Solution and Cards' || discount.Discount_Type__c == 'Solution and Free Cards') {
                        applicableDiscounts.add(discount);
                    }
                }
                if (!applicableDiscounts.isEmpty()) {
                    parentToDiscountsMap.put(cluCard.Id, applicableDiscounts);
                }
            }
        }

        // Process all products (solution + TRC + CLU) in a single loop
        for (Id parentProductId : parentToDiscountsMap.keySet()) {
            Id discountedProductId = parentToDiscountedMap.containsKey(parentProductId)
                ? parentToDiscountedMap.get(parentProductId)
                : (trcCardToDiscountedMap.containsKey(parentProductId)
                    ? trcCardToDiscountedMap.get(parentProductId)
                    : cluCardToDiscountedMap.get(parentProductId));

            if (discountedProductId == null) continue;

            List<PricebookEntry> pbEntries = parentPBEMap.containsKey(parentProductId)
                ? parentPBEMap.get(parentProductId)
                : (trcCardPBEMap.containsKey(parentProductId)
                    ? trcCardPBEMap.get(parentProductId)
                    : cluCardPBEMap.get(parentProductId));

            if (pbEntries == null || pbEntries.isEmpty()) continue;

            List<ER_Promo_Code__c> applicableDiscounts = parentToDiscountsMap.get(parentProductId);
            Boolean isTrcCard = trcCardPBEMap.containsKey(parentProductId);
            Boolean isCluCard = cluCardPBEMap.containsKey(parentProductId);

            for (ER_Promo_Code__c discount : applicableDiscounts) {
                Decimal discountPercent = calculateDiscountPercent(discount, isTrcCard, isCluCard);

                Date promoStartDate = discount.ER_Start_Date__c;
                Date promoEndDate = discount.ER_End_Date__c;
                Id promoId = discount.Id;

                for (PricebookEntry parentPBE : pbEntries) {
                    String pbeKey = discountedProductId + '_' + parentPBE.Pricebook2Id + '_' + promoId;

                    if (existingPBEMap.containsKey(pbeKey)) continue;

                    PricebookEntry pbeEntry = createDiscountPBE(
                        discountedProductId,
                        parentPBE,
                        discountPercent,
                        promoStartDate,
                        promoEndDate,
                        promoId,
                        standardPricebookId
                    );
                    if (parentPBE.Pricebook2Id == standardPricebookId) {
                        standardPbesToInsert.add(pbeEntry);
                    } else {
                        customPbesToInsert.add(pbeEntry);
                    }
                    existingPBEMap.put(pbeKey, pbeEntry);
                }
            }
        }

        // Insert standard entries FIRST
        System.debug('Inserting ' + standardPbesToInsert.size() + ' standard PBEs');
        if (!standardPbesToInsert.isEmpty()) {
            insert standardPbesToInsert;
            System.debug('Successfully inserted standard PBEs');
        }
        // Insert custom entries AFTER standard entries exist
        System.debug('Inserting ' + customPbesToInsert.size() + ' custom PBEs');
        if (!customPbesToInsert.isEmpty()) {
            insert customPbesToInsert;
            System.debug('Successfully inserted custom PBEs');
        }
    }

    private Decimal calculateDiscountPercent(ER_Promo_Code__c discount, Boolean isTrcCard, Boolean isCluCard) {
        // For "Solution and Free Cards", TRC and CLU card products get 100% discount (free)
        if (discount.Discount_Type__c == 'Solution and Free Cards' && (isTrcCard || isCluCard)) {
            return 100;
        }

        // For all other cases use the configured discount percentage
        return discount.Discount_Percentage__c != null ? discount.Discount_Percentage__c : 0;
    }

    private PricebookEntry createDiscountPBE(
        Id discountedProductId,
        PricebookEntry parentPBE,
        Decimal discountPercent,
        Date promoStartDate,
        Date promoEndDate,
        Id promoId,
        Id standardPricebookId
    ) {
        Decimal discountedPrice = 0;

        if (parentPBE.ER_ValueType__c == 'Percentage') {
            discountedPrice = parentPBE.ER_Percentage__c != null
                ? (parentPBE.ER_Percentage__c * (1 - (discountPercent / 100))).setScale(2, RoundingMode.HALF_UP)
                : 0;
        } else if (parentPBE.ER_ValueType__c == 'Currency') {
            discountedPrice = parentPBE.UnitPrice != null
                ? (parentPBE.UnitPrice * (1 - (discountPercent / 100))).setScale(2, RoundingMode.HALF_UP)
                : 0;
        }

        return new PricebookEntry(
            Product2Id = discountedProductId,
            Pricebook2Id = parentPBE.Pricebook2Id,
            UnitPrice = parentPBE.ER_ValueType__c == 'Percentage' ? 0 : discountedPrice,
            IsActive = true,
            UseStandardPrice = false,
            ER_BUPicklist__c = parentPBE.ER_BUPicklist__c,
            ER_Max__c = parentPBE.ER_Max__c,
            ER_Min__c = parentPBE.ER_Min__c,
            ER_Percentage__c = parentPBE.ER_ValueType__c == 'Percentage' ? discountedPrice : null,
            ER_ValueType__c = parentPBE.ER_ValueType__c,
            ER_Offer_validity_start_date__c = promoStartDate,
            ER_Offer_validity_end_date__c = promoEndDate,
            ER_Promo_Code2__c = promoId
        );
    }

    public void finish(Database.BatchableContext bc) {
    }
}
