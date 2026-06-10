public class CreateDiscountedProductsBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<Id> discountCodeIds;
    private static final String DISCOUNT_PRODUCT_RECORDTYPE_DEVELOPERNAME = 'Discount';
    private Id discountRecordTypeId;

    public CreateDiscountedProductsBatch(Set<Id> discountCodeIds) {
        this.discountCodeIds = discountCodeIds;
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = :DISCOUNT_PRODUCT_RECORDTYPE_DEVELOPERNAME LIMIT 1];
        discountRecordTypeId = rt != null ? rt.Id : null;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Solution__c, Discount_Percentage__c, Discount_Type__c, ER_Business_Unit__c, ER_End_Date__c, ER_Start_Date__c
            FROM ER_Promo_Code__c
            WHERE Id IN :discountCodeIds
        ]);
    }
    public void execute(Database.BatchableContext bc, List<ER_Promo_Code__c> discountCodes) {
        if (discountCodes.isEmpty()) return;

        Map<String, List<ER_Promo_Code__c>> solCodeToDiscounts = new Map<String, List<ER_Promo_Code__c>>();
        Map<String, List<ER_Promo_Code__c>> serviceCodeToDiscounts = new Map<String, List<ER_Promo_Code__c>>();
        for (ER_Promo_Code__c dc : discountCodes) {
            String solCode = dc.Solution__c != null ? dc.Solution__c : null;
            if (solCode != null) {
                if (!solCodeToDiscounts.containsKey(solCode)) solCodeToDiscounts.put(solCode, new List<ER_Promo_Code__c>());
                solCodeToDiscounts.get(solCode).add(dc);
                
                if (dc.Discount_Type__c == 'Solution and Cards') {
                    String additionalServiceCode;
                    if (dc.ER_Business_Unit__c == 'BE') {
                        additionalServiceCode = Constants.ADDITIONAL_SERVICE_CODE_BE;
                    } else if (dc.ER_Business_Unit__c == 'LU') {
                        additionalServiceCode = Constants.ADDITIONAL_SERVICE_CODE_LU;
                    }
                    if (additionalServiceCode != null) {
                        if (!serviceCodeToDiscounts.containsKey(additionalServiceCode)) {
                            serviceCodeToDiscounts.put(additionalServiceCode, new List<ER_Promo_Code__c>());
                        }
                        serviceCodeToDiscounts.get(additionalServiceCode).add(dc);
                        if (!solCodeToDiscounts.containsKey(additionalServiceCode)) {
                            solCodeToDiscounts.put(additionalServiceCode, new List<ER_Promo_Code__c>());
                        }
                        solCodeToDiscounts.get(additionalServiceCode).add(dc);
                    }
                } else if(solCode == Constants.ADDITIONAL_SERVICE_CODE_BE || solCode == Constants.ADDITIONAL_SERVICE_CODE_LU){
                    if (!serviceCodeToDiscounts.containsKey(solCode)) serviceCodeToDiscounts.put(solCode, new List<ER_Promo_Code__c>());
                    serviceCodeToDiscounts.get(solCode).add(dc);
                }

            }
        }
        if (solCodeToDiscounts.isEmpty()) return;

        // 1) Fetch Parent Ranges

        List<Product2> parentProducts = [
            SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                   ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c, Solution_Group__c,QuantityUnitOfMeasure
            FROM Product2
            WHERE ER_Type__c = 'Range'
              AND ER_Solution2__r.ProductCode IN :solCodeToDiscounts.keySet()
              AND IsActive = true
        ];
        if (parentProducts.isEmpty()) return;

        List<Product2> parentServiceProducts = [
            SELECT Id, Name, ER_Type__c, IsActive, BE_Maximum_Amount__c, BE_Minimum_Amount__c,
                   ProductCode, ER_Solution2__r.ProductCode, ER_BUPicklist__c, Solution_Group__c, QuantityUnitOfMeasure
            FROM Product2
            WHERE ER_Type__c = 'Service'
            AND ProductCode != 'CARD_RP_BF'
            AND ProductCode != NULL
            AND ER_Solution2__r.ProductCode IN :serviceCodeToDiscounts.keySet()
            AND IsActive = true
        ];

        if(!parentServiceProducts.isEmpty()){
            parentProducts.addAll(parentServiceProducts);
        }


        // 2) Fetch all PricebookEntries for those parents
        List<PricebookEntry> parentPBEs = [
            SELECT Id, Product2Id, Pricebook2Id, UnitPrice, ER_Percentage__c, IsActive,
                   UseStandardPrice, CurrencyIsoCode, ER_BUPicklist__c, ER_Max__c, ER_Min__c, ER_ValueType__c
            FROM PricebookEntry
            WHERE Product2Id IN :parentProducts AND Pricebook2.IsStandard = FALSE
        ];

        List<PricebookEntry> parentServicePBEs = [
            SELECT Id, Product2Id, Pricebook2Id, UnitPrice, ER_Percentage__c, IsActive,
                   UseStandardPrice, CurrencyIsoCode, ER_BUPicklist__c, ER_Max__c, ER_Min__c, ER_ValueType__c
            FROM PricebookEntry
            WHERE Product2Id IN :parentServiceProducts AND Pricebook2.IsStandard = FALSE
        ];

        if(!parentServicePBEs.isEmpty()){
            parentPBEs.addAll(parentServicePBEs);
        }

        Map<Id, List<PricebookEntry>> parentPBEMap = new Map<Id, List<PricebookEntry>>();
        Set<Id> parentPricebookIds = new Set<Id>();
        for (PricebookEntry p : parentPBEs) {
            if (!parentPBEMap.containsKey(p.Product2Id)) parentPBEMap.put(p.Product2Id, new List<PricebookEntry>());
            parentPBEMap.get(p.Product2Id).add(p);
            parentPricebookIds.add(p.Pricebook2Id);
        }

        // Standard pricebook id dynamically
        Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (stdPb == null) {
            System.debug('Standard pricebook not found - aborting batch.');
            return;
        }
        Id standardPricebookId = stdPb.Id;

        //Create Discounted Ranges
        List<Product2> productsToInsert = new List<Product2>();
        Map<Id, Id> parentToDiscountedMap = new Map<Id, Id>();
        List<String> preservedParentOrderKeys = new List<String>();
        Integer lineOrder = 0;

        for (Product2 parent : parentProducts) {
            Decimal minAmount;
            Decimal maxAmount;
            if(parent.ER_Type__c == 'Range'){
                if (parent.Name != null && parent.Name.contains(' to ')) {
                    String[] parts = parent.Name.split(' to ');
                    try {
                        minAmount = parts.size() > 0 ? Decimal.valueOf(parts[0].trim()) : null;
                        maxAmount = parts.size() > 1 ? Decimal.valueOf(parts[1].trim()) : null;
                    } catch (Exception e) {
                        minAmount = null; maxAmount = null;
                    }
                } else if (parent.Name != null && parent.Name.startsWith('>')) {
                    try {
                        minAmount = Decimal.valueOf(parent.Name.replace('>', '').trim());
                    } catch (Exception e) { minAmount = null; }
                    maxAmount = null;
                } else {
                    minAmount = null; maxAmount = null;
                }
            }else{
                minAmount = null; maxAmount = null;
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

        if (productsToInsert.isEmpty()) return;
        insert productsToInsert;

        for (Integer i=0; i<preservedParentOrderKeys.size(); i++) {
            if (i < productsToInsert.size()) {
                parentToDiscountedMap.put(preservedParentOrderKeys[i], productsToInsert[i].Id);
            }
        }

        // Build list of all pricebook ids we will possibly create entries for (standard + parent pb ids)
        Set<Id> allRelevantPricebookIds = new Set<Id>(parentPricebookIds);
        allRelevantPricebookIds.add(standardPricebookId);

        List<PricebookEntry> standardPbesToInsert = new List<PricebookEntry>();
        List<PricebookEntry> customPbesToInsert = new List<PricebookEntry>();
        Map<String, PricebookEntry> existingPBEMap = new Map<String, PricebookEntry>();

        for (Product2 parent : parentProducts) {
            Id discountedProductId = parentToDiscountedMap.get(parent.Id);
            if (discountedProductId == null) continue;

            List<PricebookEntry> pbEntries = parentPBEMap.get(parent.Id);
            if (pbEntries == null || pbEntries.isEmpty()) continue;

            for(ER_Promo_Code__c discount : solCodeToDiscounts.get(parent.ER_Solution2__r.ProductCode)){

                Decimal discountPercent = discount != null && discount.Discount_Percentage__c != null
                                       ? discount.Discount_Percentage__c
                                       : 0;
                Date promoStartDate = discount.ER_Start_Date__c;
                Date promoEndDate = discount.ER_End_Date__c;
                Id promoId = discount.Id;

                for (PricebookEntry parentPBE : pbEntries) {
                    // 1) Standard pricebook entry for discounted product
                    String stdKey = discountedProductId + '_' + standardPricebookId;
                    if (!existingPBEMap.containsKey(stdKey)) {
                        PricebookEntry stdEntry = new PricebookEntry(
                            Product2Id = discountedProductId,
                            Pricebook2Id = standardPricebookId,
                            UnitPrice = 0,
                            IsActive = parentPBE.IsActive,
                            UseStandardPrice = false,
                            ER_BUPicklist__c = parentPBE.ER_BUPicklist__c,
                            ER_Max__c = parentPBE.ER_Max__c,
                            ER_Min__c = parentPBE.ER_Min__c,
                            ER_Percentage__c = parentPBE.ER_Percentage__c,
                            ER_ValueType__c = parentPBE.ER_ValueType__c
                        );
                        standardPbesToInsert.add(stdEntry);
                        existingPBEMap.put(stdKey, stdEntry);
                    }

                    // 2) Custom pricebook (same pricebook as parent) entry for discounted product
                    String customKey = discountedProductId + '_' + parentPBE.Pricebook2Id;
                    if (!existingPBEMap.containsKey(customKey)) {
                        Decimal customDiscountedPrice;
                        if (parentPBE.UnitPrice != null) {
                            if (parentPBE.ER_ValueType__c == 'Percentage') {
                                customDiscountedPrice = parentPBE.ER_Percentage__c != null
                                                        ? (parentPBE.ER_Percentage__c * (1 - (discountPercent / 100))).setScale(2, RoundingMode.HALF_UP)
                                                        : null;
                            } else if (parentPBE.ER_ValueType__c == 'Currency') {
                                customDiscountedPrice = parentPBE.UnitPrice != null
                                                        ? (parentPBE.UnitPrice * (1 - (discountPercent / 100))).setScale(2, RoundingMode.HALF_UP)
                                                        : null;
                            }
                        } else {
                            customDiscountedPrice = null;
                        }
                        PricebookEntry customEntry = new PricebookEntry(
                            Product2Id = discountedProductId,
                            Pricebook2Id = parentPBE.Pricebook2Id,
                            UnitPrice = parentPBE.ER_ValueType__c == 'Percentage' ? 0 : customDiscountedPrice,
                            IsActive = parentPBE.IsActive,
                            UseStandardPrice = false,
                            ER_BUPicklist__c = parentPBE.ER_BUPicklist__c,
                            ER_Max__c = parentPBE.ER_Max__c,
                            ER_Min__c = parentPBE.ER_Min__c,
                            ER_Percentage__c = parentPBE.ER_ValueType__c == 'Percentage' ? customDiscountedPrice : null,
                            ER_ValueType__c = parentPBE.ER_ValueType__c,
                            ER_Offer_validity_start_date__c = promoStartDate,
                            ER_Offer_validity_end_date__c = promoEndDate,
                            ER_Promo_Code2__c = promoId
                        );
                        customPbesToInsert.add(customEntry);
                        existingPBEMap.put(customKey, customEntry);
                    }
                }
            }
        }
        if (!standardPbesToInsert.isEmpty()) {
            insert standardPbesToInsert;
            if (!customPbesToInsert.isEmpty()) {
                insert customPbesToInsert;
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
    }
}