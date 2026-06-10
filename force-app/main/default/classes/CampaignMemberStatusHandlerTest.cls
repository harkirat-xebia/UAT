@isTest
public class CampaignMemberStatusHandlerTest {
    
    @isTest
    static void testCreateDefaultStatuses() {
        
        // Create test campaign
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign',
            IsActive = true,
            Type = 'Email'
        );
        
        Test.startTest();
        insert testCampaign;
        Test.stopTest();
        
        // Query the created statuses
        List<CampaignMemberStatus> statuses = [
            SELECT Id, Label, HasResponded, CampaignId, SortOrder
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            ORDER BY SortOrder
        ];
        
        // Verify statuses were created (4 custom + default statuses)
        System.assert(statuses.size() >= 4, 'Expected at least 4 custom statuses');
        
        // Verify specific statuses exist
        Set<String> statusLabels = new Set<String>();
        for (CampaignMemberStatus status : statuses) {
            statusLabels.add(status.Label);
        }
        
        System.assert(statusLabels.contains('Email 1 sent'), 'Email 1 sent status not found');
        System.assert(statusLabels.contains('Email 2 sent'), 'Email 2 sent status not found');
        System.assert(statusLabels.contains('Email 3 sent'), 'Email 3 sent status not found');
        System.assert(statusLabels.contains('Attrition process cancelled'), 'Attrition process cancelled status not found');
    }
    
    @isTest
    static void testBulkCampaignCreation() {
        
        List<Campaign> campaigns = new List<Campaign>();
        
        for (Integer i = 0; i < 200; i++) {
            campaigns.add(new Campaign(
                Name = 'Bulk Test Campaign ' + i,
                IsActive = true,
                Type = 'Email'
            ));
        }
        
        Test.startTest();
        insert campaigns;
        Test.stopTest();
        
        // Verify statuses created for all campaigns
        List<CampaignMemberStatus> allStatuses = [
            SELECT Id, CampaignId, Label
            FROM CampaignMemberStatus
            WHERE CampaignId IN :campaigns
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        // Should have 4 statuses per campaign
        System.assertEquals(800, allStatuses.size(), 'Expected 4 statuses per campaign');
    }
}