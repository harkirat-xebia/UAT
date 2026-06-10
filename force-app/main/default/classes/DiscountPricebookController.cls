public with sharing class DiscountPricebookController {
    
    /**
     * Get all active pricebooks that have products related to the discount code's solution
     */
    @AuraEnabled
    public static List<PricebookWrapper> getPricebooksForDiscount(Id discountCodeId) {
        System.debug('=== getPricebooksForDiscount START ===');
        System.debug('discountCodeId: ' + discountCodeId);
        
        try {
            // Get discount code details
            ER_Promo_Code__c discount = [
                SELECT Id, Solution__c, ER_Business_Unit__c, Discount_Type__c
                FROM ER_Promo_Code__c
                WHERE Id = :discountCodeId
                LIMIT 1
            ];
            
            System.debug('Discount Solution: ' + discount.Solution__c);
            System.debug('Discount Type: ' + discount.Discount_Type__c);
            System.debug('Business Unit: ' + discount.ER_Business_Unit__c);
            
            // Build solution codes to check
            Set<String> solutionCodes = new Set<String>{ discount.Solution__c };
            
            if (discount.Discount_Type__c == 'Solution and Cards') {
                if (discount.ER_Business_Unit__c == 'BE') {
                    solutionCodes.add(Constants.ADDITIONAL_SERVICE_CODE_BE);
                } else if (discount.ER_Business_Unit__c == 'LU') {
                    solutionCodes.add(Constants.ADDITIONAL_SERVICE_CODE_LU);
                }
            }
            
            System.debug('Solution codes to check: ' + solutionCodes);
            
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
            
            System.debug('Relevant pricebook IDs: ' + relevantPricebookIds);
            
            if (relevantPricebookIds.isEmpty()) {
                System.debug('No pricebooks found');
                return new List<PricebookWrapper>();
            }
            
            // Get full pricebook details
            List<Pricebook2> pricebooks = [
                SELECT Id, Name, Description, IsActive
                FROM Pricebook2
                WHERE Id IN :relevantPricebookIds
                AND IsActive = true
                ORDER BY Name
            ];
            
            System.debug('Pricebooks found: ' + pricebooks.size());
            
            // Convert to wrapper
            List<PricebookWrapper> result = new List<PricebookWrapper>();
            for (Pricebook2 pb : pricebooks) {
                result.add(new PricebookWrapper(pb));
            }
            
            System.debug('=== getPricebooksForDiscount END ===');
            return result;
            
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading pricebooks: ' + e.getMessage());
        }
    }
    
    /**
     * Execute batch to create discounted products for selected pricebooks
     */
    @AuraEnabled
    public static String createDiscountedProductsForPricebooks(Id discountCodeId, List<Id> pricebookIds) {
        System.debug('=== createDiscountedProductsForPricebooks START ===');
        System.debug('discountCodeId: ' + discountCodeId);
        System.debug('pricebookIds: ' + pricebookIds);
        
        try {
            if (pricebookIds == null || pricebookIds.isEmpty()) {
                throw new AuraHandledException('Please select at least one pricebook');
            }
            
            // Execute NEW batch class with selected pricebooks
            Set<Id> discountCodeIds = new Set<Id>{ discountCodeId };
            Set<Id> pricebookIdSet = new Set<Id>(pricebookIds);
            
            CreateDisProductsForSelPricebooksBatch batch = 
                new CreateDisProductsForSelPricebooksBatch(discountCodeIds, pricebookIdSet);
            
            Id batchJobId = Database.executeBatch(batch, 200);
            
            System.debug('Batch job ID: ' + batchJobId);
            System.debug('=== createDiscountedProductsForPricebooks END ===');
            
            return batchJobId;
            
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
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
        
        public PricebookWrapper(Pricebook2 pb) {
            this.Id = pb.Id;
            this.Name = pb.Name;
            this.Description = pb.Description != null ? pb.Description : '';
            this.IsActive = pb.IsActive;
        }
    }
}