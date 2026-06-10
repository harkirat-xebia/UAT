public class CampaignMemberStatusHandler {
    
    public static void createDefaultStatuses(List<Campaign> campaigns) {
        
        List<CampaignMemberStatus> statusesToInsert = new List<CampaignMemberStatus>();
        
        for (Campaign camp : campaigns) {
            
            // Get the highest sort order for existing statuses
            Integer sortOrder = 3; // Start after default statuses (Sent, Responded, etc.)
            
            // Email 1 sent (Not Responded)
            statusesToInsert.add(new CampaignMemberStatus(
                CampaignId = camp.Id,
                Label = 'Email 1 sent',
                HasResponded = false,
                SortOrder = sortOrder++
            ));
            
            // Email 2 sent (Not Responded)
            statusesToInsert.add(new CampaignMemberStatus(
                CampaignId = camp.Id,
                Label = 'Email 2 sent',
                HasResponded = false,
                SortOrder = sortOrder++
            ));
            
            // Email 3 sent (Not Responded)
            statusesToInsert.add(new CampaignMemberStatus(
                CampaignId = camp.Id,
                Label = 'Email 3 sent',
                HasResponded = false,
                SortOrder = sortOrder++
            ));
            
            // Attrition process cancelled (Responded)
            statusesToInsert.add(new CampaignMemberStatus(
                CampaignId = camp.Id,
                Label = 'Attrition process cancelled',
                HasResponded = true, // Assuming this is a positive response
                SortOrder = sortOrder++
            ));
        }
        
        if (!statusesToInsert.isEmpty()) {
            try {
                insert statusesToInsert;
            } catch (DmlException e) {
                System.debug('Error creating Campaign Member Statuses: ' + e.getMessage());
                // Handle error appropriately
            }
        }
    }
}