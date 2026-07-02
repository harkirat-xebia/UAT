public with sharing class DiscountPricebookController {

    /**
     * Get all active pricebooks that have products related to the discount code's solution.
     * Each pricebook wrapper includes a hasExistingPBE flag so the LWC can show which
     * pricebooks already have discount entries (created by the trigger auto-batch or a
     * previous manual run) and disable those checkboxes individually.
     */
    @AuraEnabled
    public static List<PricebookWrapper> getPricebooksForDiscount(Id discountCodeId) {
        System.debug('discountCodeId: ' + discountCodeId);

        try {
            // Get discount code details
            ER_Promo_Code__c discount = [
                SELECT Id, Solution__c, ER_Business_Unit__c, Discount_Type__c
                FROM ER_Promo_Code__c
                WHERE Id = :discountCodeId
                LIMIT 1
            ];

            // Build solution codes to check — include card solution for both
            // "Solution and Cards" and "Solution and Free Cards" discount types
            Set<String> solutionCodes = new Set<String>{ discount.Solution__c };

            if (discount.Discount_Type__c == 'Solution and Cards' || discount.Discount_Type__c == 'Solution and Free Cards') {
                if (discount.ER_Business_Unit__c == 'BE') {
                    solutionCodes.add(Constants.ADDITIONAL_SERVICE_CODE_BE);
                } else if (discount.ER_Business_Unit__c == 'LU') {
                    solutionCodes.add(Constants.ADDITIONAL_SERVICE_CODE_LU);
                }
            }

            // Get all active pricebooks that have products for these solutions
            Set<Id> relevantPricebookIds = new Set<Id>();

            for (PricebookEntry pbe : [
                SELECT Pricebook2Id
                FROM PricebookEntry
                WHERE Product2.ER_Solution2__r.ProductCode IN :solutionCodes
                AND Pricebook2.IsActive = true
                AND Pricebook2.IsStandard = false
                AND IsActive = true
            ]) {
                relevantPricebookIds.add(pbe.Pricebook2Id);
            }

            if (relevantPricebookIds.isEmpty()) {
                return new List<PricebookWrapper>();
            }

            // Determine which of these pricebooks already have discount PBEs for this promo code.
            // This covers both auto-created PBEs (from DiscountCodeTriggerHandler) and
            // previously manually-run selections via this LWC.
            Set<Id> pricebooksWithExistingPBEs = new Set<Id>();
            for (AggregateResult ar : [
                SELECT Pricebook2Id pb
                FROM PricebookEntry
                WHERE ER_Promo_Code2__c = :discountCodeId
                AND Pricebook2Id IN :relevantPricebookIds
                AND IsActive = true
                GROUP BY Pricebook2Id
            ]) {
                pricebooksWithExistingPBEs.add((Id) ar.get('pb'));
            }

            // Get full pricebook details
            List<Pricebook2> pricebooks = [
                SELECT Id, Name, Description, IsActive
                FROM Pricebook2
                WHERE Id IN :relevantPricebookIds
                AND IsActive = true
                ORDER BY Name
            ];

            // Convert to wrapper — stamp hasExistingPBE per pricebook
            List<PricebookWrapper> result = new List<PricebookWrapper>();
            for (Pricebook2 pb : pricebooks) {
                PricebookWrapper wrapper = new PricebookWrapper(pb);
                wrapper.hasExistingPBE = pricebooksWithExistingPBEs.contains(pb.Id);
                result.add(wrapper);
            }

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error loading pricebooks: ' + e.getMessage());
        }
    }

    /**
     * Execute batch to create discounted products for selected pricebooks
     */
    @AuraEnabled
    public static String createDiscountedProductsForPricebooks(Id discountCodeId, List<Id> pricebookIds) {

        try {
            if (pricebookIds == null || pricebookIds.isEmpty()) {
                throw new AuraHandledException('Please select at least one pricebook');
            }

            // Execute batch with selected pricebooks
            Set<Id> discountCodeIds = new Set<Id>{ discountCodeId };
            Set<Id> pricebookIdSet = new Set<Id>(pricebookIds);

            CreateDisProductsForSelPricebooksBatch batch =
                new CreateDisProductsForSelPricebooksBatch(discountCodeIds, pricebookIdSet);

            Id batchJobId = Database.executeBatch(batch, 200);

            return batchJobId;

        } catch (Exception e) {
            throw new AuraHandledException('Error starting batch: ' + e.getMessage());
        }
    }

    /**
     * Wrapper class for pricebook data
     */
    public class PricebookWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String Description { get; set; }
        @AuraEnabled public Boolean IsActive { get; set; }
        @AuraEnabled public Boolean hasExistingPBE { get; set; }

        public PricebookWrapper(Pricebook2 pb) {
            this.Id = pb.Id;
            this.Name = pb.Name;
            this.Description = pb.Description != null ? pb.Description : '';
            this.IsActive = pb.IsActive;
            this.hasExistingPBE = false;
        }
    }
}
