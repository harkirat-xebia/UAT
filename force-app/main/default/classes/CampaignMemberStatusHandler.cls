public class CampaignMemberStatusHandler {
    
    // Constants for maintainability
    private static final String EMAIL_1_SENT = 'Email 1 sent';
    private static final String EMAIL_2_SENT = 'Email 2 sent';
    private static final String EMAIL_3_SENT = 'Email 3 sent';
    private static final String ATTRITION_CANCELLED = 'Attrition process cancelled';
    private static final String ATTRITION_KEYWORD = 'attrition';
    
    public static void createDefaultStatuses(List<Campaign> campaigns) {
        
        if (campaigns == null || campaigns.isEmpty()) {
            return;
        }
        
        // Filter campaigns that contain "attrition" in their name 
        List<Campaign> attritionCampaigns = new List<Campaign>();
        for (Campaign camp : campaigns) {
            // Checking both Name contains "attrition" AND Type equals "Attrition"
            if (camp.Name != null && 
                camp.Name.toLowerCase().contains(ATTRITION_KEYWORD) &&
                camp.Type != null &&
                camp.Type.equalsIgnoreCase('Attrition')) {
                attritionCampaigns.add(camp);
            }
        }
        
        // If no attrition campaigns found, exit early
        if (attritionCampaigns.isEmpty()) {
            System.debug('No campaigns with "attrition" in name found. Skipping status creation.');
            return;
        }
        
        // Get existing statuses to avoid duplicates and calculate correct sort order
        Map<Id, Map<String, CampaignMemberStatus>> existingStatusesMap = getExistingStatuses(attritionCampaigns);
        
        List<CampaignMemberStatus> statusesToInsert = new List<CampaignMemberStatus>();
        
        for (Campaign camp : attritionCampaigns) {
            
            // Get existing statuses for this campaign
            Map<String, CampaignMemberStatus> existingStatuses = existingStatusesMap.get(camp.Id);
            if (existingStatuses == null) {
                existingStatuses = new Map<String, CampaignMemberStatus>();
            }
            
            // Calculate the next available sort order dynamically
            Integer sortOrder = calculateNextSortOrder(existingStatuses);
            
            // Only add statuses that don't already exist
            if (!existingStatuses.containsKey(EMAIL_1_SENT)) {
                statusesToInsert.add(createStatus(camp.Id, EMAIL_1_SENT, false, sortOrder++));
            }
            
            if (!existingStatuses.containsKey(EMAIL_2_SENT)) {
                statusesToInsert.add(createStatus(camp.Id, EMAIL_2_SENT, false, sortOrder++));
            }
            
            if (!existingStatuses.containsKey(EMAIL_3_SENT)) {
                statusesToInsert.add(createStatus(camp.Id, EMAIL_3_SENT, false, sortOrder++));
            }
            
            if (!existingStatuses.containsKey(ATTRITION_CANCELLED)) {
                statusesToInsert.add(createStatus(camp.Id, ATTRITION_CANCELLED, false, sortOrder++));
            }
        }
        
        // Insert with partial success handling
        if (!statusesToInsert.isEmpty()) {
            insertStatuses(statusesToInsert);
        }
    }
    
    /**
     * Get existing Campaign Member Statuses for given campaigns
     */
    private static Map<Id, Map<String, CampaignMemberStatus>> getExistingStatuses(List<Campaign> campaigns) {
        
        Map<Id, Map<String, CampaignMemberStatus>> statusMap = new Map<Id, Map<String, CampaignMemberStatus>>();
        
        for (CampaignMemberStatus cms : [
            SELECT Id, CampaignId, Label, SortOrder, HasResponded
            FROM CampaignMemberStatus
            WHERE CampaignId IN :campaigns
        ]) {
            if (!statusMap.containsKey(cms.CampaignId)) {
                statusMap.put(cms.CampaignId, new Map<String, CampaignMemberStatus>());
            }
            statusMap.get(cms.CampaignId).put(cms.Label, cms);
        }
        
        return statusMap;
    }
    
    /**
     * Calculate the next available sort order based on existing statuses
     */
    private static Integer calculateNextSortOrder(Map<String, CampaignMemberStatus> existingStatuses) {
        
        Integer maxSortOrder = 0;
        
        for (CampaignMemberStatus cms : existingStatuses.values()) {
            if (cms.SortOrder != null && cms.SortOrder > maxSortOrder) {
                maxSortOrder = cms.SortOrder;
            }
        }
        return maxSortOrder + 1;
    }
    
    /**
     * Create a Campaign Member Status record
     */
    private static CampaignMemberStatus createStatus(Id campaignId, String label, Boolean hasResponded, Integer sortOrder) {
        return new CampaignMemberStatus(
            CampaignId = campaignId,
            Label = label,
            HasResponded = hasResponded,
            SortOrder = sortOrder
        );
    }
    
    /**
     * Insert statuses with proper error handling
     */
    private static void insertStatuses(List<CampaignMemberStatus> statusesToInsert) {
        
        // Use Database.insert with allOrNone=false for partial success
        Database.SaveResult[] results = Database.insert(statusesToInsert, false);
        
        // Track results
        Integer successCount = 0;
        Integer failCount = 0;
        List<String> errorMessages = new List<String>();
        
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successCount++;
            } else {
                failCount++;
                
                // Collect error details
                for (Database.Error err : results[i].getErrors()) {
                    String errorMsg = 'Failed to create status "' + statusesToInsert[i].Label + 
                                    '" for Campaign ' + statusesToInsert[i].CampaignId + 
                                    ': ' + err.getMessage();
                    errorMessages.add(errorMsg);
                    System.debug('ERROR: ' + errorMsg);
                }
            }
        }
    }
}