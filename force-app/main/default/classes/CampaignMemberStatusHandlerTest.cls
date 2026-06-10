@isTest
public class CampaignMemberStatusHandlerTest {
    
    /*@isTest
    static void testCreateDefaultStatuses() {
        // Campaign must have "attrition" in name AND Type = 'Attrition'
        Campaign testCampaign = new Campaign(
            Name = 'Test Attrition Campaign',
            IsActive = true,
            Type = 'Attrition'
        );
        
        Test.startTest();
        insert testCampaign;
        Test.stopTest();
        
        // Verify ONLY our custom statuses were created
        List<CampaignMemberStatus> customStatuses = [
            SELECT Id, Label, HasResponded, SortOrder
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
            ORDER BY SortOrder
        ];
        
        System.assertEquals(4, customStatuses.size(), 'Should create 4 custom statuses');
        
        // Verify all statuses (including default ones)
        List<CampaignMemberStatus> allStatuses = [
            SELECT Id, Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
        ];
        
        System.assert(allStatuses.size() >= 4, 'Should have at least 4 custom statuses (plus any default ones)');
        
        // Verify specific custom statuses
        Set<String> statusLabels = new Set<String>();
        for (CampaignMemberStatus cms : customStatuses) {
            statusLabels.add(cms.Label);
        }
        
        System.assert(statusLabels.contains('Email 1 sent'), 'Should contain Email 1 sent');
        System.assert(statusLabels.contains('Email 2 sent'), 'Should contain Email 2 sent');
        System.assert(statusLabels.contains('Email 3 sent'), 'Should contain Email 3 sent');
        System.assert(statusLabels.contains('Attrition process cancelled'), 'Should contain Attrition process cancelled');
        
        // Verify HasResponded flag (all are false based on your code)
        for (CampaignMemberStatus cms : customStatuses) {
            System.assertEquals(false, cms.HasResponded, 'All statuses should not be marked as responded');
        }
    }
    
    @isTest
    static void testNoDuplicateStatuses() {
        Campaign testCampaign = new Campaign(
            Name = 'Test Attrition Campaign',
            IsActive = true,
            Type = 'Attrition'
        );
        insert testCampaign;
        
        // Get count of custom statuses after trigger runs
        Integer initialCustomCount = [
            SELECT COUNT()
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        System.assertEquals(4, initialCustomCount, 'Should have 4 custom statuses initially');
        
        Test.startTest();
        // Try to create statuses again manually
        CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>{ testCampaign });
        Test.stopTest();
        
        // Count should NOT increase (no duplicates)
        Integer finalCustomCount = [
            SELECT COUNT()
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        System.assertEquals(initialCustomCount, finalCustomCount, 'Should not create duplicate custom statuses');
        System.assertEquals(4, finalCustomCount, 'Should still have exactly 4 custom statuses');
    }
    
    @isTest
    static void testBulkCampaignCreation() {
        List<Campaign> campaigns = new List<Campaign>();
        for (Integer i = 0; i < 200; i++) {
            campaigns.add(new Campaign(
                Name = 'Bulk Test Attrition Campaign ' + i,
                IsActive = true,
                Type = 'Attrition'
            ));
        }
        
        Test.startTest();
        insert campaigns;
        Test.stopTest();
        
        // Verify ONLY custom statuses created for all campaigns
        Integer customStatusCount = [
            SELECT COUNT()
            FROM CampaignMemberStatus
            WHERE CampaignId IN :campaigns
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        System.assertEquals(800, customStatusCount, 'Should create 4 custom statuses per campaign (200 * 4)');
        
        // Verify each campaign has exactly 4 custom statuses
        Map<Id, Integer> campaignStatusCount = new Map<Id, Integer>();
        for (CampaignMemberStatus cms : [
            SELECT CampaignId
            FROM CampaignMemberStatus
            WHERE CampaignId IN :campaigns
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ]) {
            if (!campaignStatusCount.containsKey(cms.CampaignId)) {
                campaignStatusCount.put(cms.CampaignId, 0);
            }
            campaignStatusCount.put(cms.CampaignId, campaignStatusCount.get(cms.CampaignId) + 1);
        }
        
        // Each campaign should have exactly 4 custom statuses
        for (Campaign camp : campaigns) {
            Integer count = campaignStatusCount.get(camp.Id);
            System.assertEquals(4, count, 'Campaign ' + camp.Name + ' should have exactly 4 custom statuses');
        }
    }

    @isTest
    static void testNullInputHandling() {
        Test.startTest();
        CampaignMemberStatusHandler.createDefaultStatuses(null);
        CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>());
        Test.stopTest();
        
        // Should not throw any exceptions
        System.assert(true, 'Should handle null/empty input gracefully');
    }
    
    @isTest
    static void testPartialStatusCreation() {
        // Campaign name must contain "attrition" AND Type = 'Attrition'
        Campaign testCampaign = new Campaign(
            Name = 'Test Attrition Campaign',
            IsActive = true,
            Type = 'Attrition'
        );
        insert testCampaign;
        
        // Manually create one of the custom statuses
        CampaignMemberStatus existingStatus = new CampaignMemberStatus(
            CampaignId = testCampaign.Id,
            Label = 'Email 1 sent',
            HasResponded = false,
            SortOrder = 10
        );
        insert existingStatus;
        
        Test.startTest();
        // Try to create all statuses again
        CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>{ testCampaign });
        Test.stopTest();
        
        // Should have all 4 custom statuses now (3 new + 1 existing)
        List<CampaignMemberStatus> customStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        System.assertEquals(4, customStatuses.size(), 'Should have all 4 custom statuses');
        
        Set<String> labels = new Set<String>();
        for (CampaignMemberStatus cms : customStatuses) {
            labels.add(cms.Label);
        }
        
        System.assert(labels.contains('Email 1 sent'), 'Should have Email 1 sent');
        System.assert(labels.contains('Email 2 sent'), 'Should have Email 2 sent');
        System.assert(labels.contains('Email 3 sent'), 'Should have Email 3 sent');
        System.assert(labels.contains('Attrition process cancelled'), 'Should have Attrition process cancelled');
    }
    
    @isTest
    static void testNonAttritionCampaign() {
        // Campaign without "attrition" in name
        Campaign testCampaign = new Campaign(
            Name = 'Regular Marketing Campaign',
            IsActive = true,
            Type = 'Email'
        );
        insert testCampaign;
        
        Test.startTest();
        CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>{ testCampaign });
        Test.stopTest();
        
        // Should NOT have any of the custom statuses
        List<CampaignMemberStatus> customStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        System.assertEquals(0, customStatuses.size(), 'Should not create statuses for non-attrition campaigns');
    }
    
    @isTest
    static void testAttritionNameButWrongType() {
        // Campaign with "attrition" in name but Type != 'Attrition'
        Campaign testCampaign = new Campaign(
            Name = 'Customer Attrition Program',
            IsActive = true,
            Type = 'Email'
        );
        insert testCampaign;
        
        Test.startTest();
        CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>{ testCampaign });
        Test.stopTest();
        
        // Should NOT create statuses (Type must be 'Attrition')
        List<CampaignMemberStatus> customStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        System.assertEquals(0, customStatuses.size(), 'Should not create statuses when Type is not Attrition');
    }
    
    @isTest
    static void testAttritionTypeButNoKeywordInName() {
        // Campaign with Type = 'Attrition' but no "attrition" in name
        Campaign testCampaign = new Campaign(
            Name = 'Customer Retention Program',
            IsActive = true,
            Type = 'Attrition'
        );
        insert testCampaign;
        
        Test.startTest();
        CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>{ testCampaign });
        Test.stopTest();
        
        // Should NOT create statuses (Name must contain "attrition")
        List<CampaignMemberStatus> customStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        
        System.assertEquals(0, customStatuses.size(), 'Should not create statuses when name does not contain attrition');
    }
    */
    @isTest
    static void testAttritionCampaignCaseInsensitive() {
        // Test with different case variations
        List<Campaign> campaigns = new List<Campaign>{
            new Campaign(Name = 'ATTRITION Campaign', IsActive = true, Type = 'Attrition'),
            new Campaign(Name = 'Customer attrition Program', IsActive = true, Type = 'Attrition'),
            new Campaign(Name = 'Attrition Management', IsActive = true, Type = 'Attrition')
        };
        insert campaigns;
        
        Test.startTest();
        CampaignMemberStatusHandler.createDefaultStatuses(campaigns);
        Test.stopTest();
        
        // All three campaigns should have the custom statuses
        for (Campaign camp : campaigns) {
            List<CampaignMemberStatus> customStatuses = [
                SELECT Label
                FROM CampaignMemberStatus
                WHERE CampaignId = :camp.Id
                AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
            ];
            System.assertEquals(4, customStatuses.size(),
                'Campaign "' + camp.Name + '" should have all 4 custom statuses');
        }
    }
    
    @isTest
    static void testMixedCampaigns() {
        // Mix of attrition and non-attrition campaigns
        List<Campaign> campaigns = new List<Campaign>{
            new Campaign(Name = 'Attrition Campaign 1', IsActive = true, Type = 'Attrition'),
            new Campaign(Name = 'Regular Campaign', IsActive = true, Type = 'Email'),
            new Campaign(Name = 'Customer Attrition', IsActive = true, Type = 'Attrition'),
            new Campaign(Name = 'Promotional Campaign', IsActive = true, Type = 'Email'),
            new Campaign(Name = 'Attrition Test', IsActive = true, Type = 'Email') // Has keyword but wrong type
        };
        insert campaigns;
        
        Test.startTest();
        CampaignMemberStatusHandler.createDefaultStatuses(campaigns);
        Test.stopTest();
        
        // Check attrition campaigns have statuses
        List<CampaignMemberStatus> attritionStatuses1 = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :campaigns[0].Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        System.assertEquals(4, attritionStatuses1.size(), 'Attrition Campaign 1 should have 4 statuses');
        
        List<CampaignMemberStatus> attritionStatuses2 = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :campaigns[2].Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        System.assertEquals(4, attritionStatuses2.size(), 'Customer Attrition should have 4 statuses');
        
        // Check non-attrition campaigns don't have statuses
        List<CampaignMemberStatus> regularStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :campaigns[1].Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        System.assertEquals(0, regularStatuses.size(), 'Regular Campaign should have 0 custom statuses');
        
        List<CampaignMemberStatus> promoStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :campaigns[3].Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        System.assertEquals(0, promoStatuses.size(), 'Promotional Campaign should have 0 custom statuses');
        
        List<CampaignMemberStatus> wrongTypeStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :campaigns[4].Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        System.assertEquals(0, wrongTypeStatuses.size(), 'Campaign with attrition name but wrong type should have 0 custom statuses');
    }
    
    /*@isTest
    static void testCampaignWithNullName() {
        // Campaign with null name should be handled gracefully
        Campaign testCampaign = new Campaign(
            IsActive = true,
            Type = 'Attrition'
        );
        
        try {
            insert testCampaign;
            Test.startTest();
            CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>{ testCampaign });
            Test.stopTest();
            
            // Should not create any statuses
            List<CampaignMemberStatus> customStatuses = [
                SELECT Label
                FROM CampaignMemberStatus
                WHERE CampaignId = :testCampaign.Id
                AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
            ];
            System.assertEquals(0, customStatuses.size(), 'Should not create statuses for null name');
        } catch (Exception e) {
            // If Campaign requires Name, this test will catch that
            System.assert(true, 'Campaign Name may be required field');
        }
    }
    
    @isTest
    static void testCampaignWithNullType() {
        // Campaign with null Type should be handled gracefully
        Campaign testCampaign = new Campaign(
            Name = 'Test Attrition Campaign',
            IsActive = true,
            Type = null
        );
        
        insert testCampaign;
        
        Test.startTest();
        CampaignMemberStatusHandler.createDefaultStatuses(new List<Campaign>{ testCampaign });
        Test.stopTest();
        
        // Should not create any statuses (Type is null)
        List<CampaignMemberStatus> customStatuses = [
            SELECT Label
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            AND Label IN ('Email 1 sent', 'Email 2 sent', 'Email 3 sent', 'Attrition process cancelled')
        ];
        System.assertEquals(0, customStatuses.size(), 'Should not create statuses for null Type');
    }
	*/
    
}