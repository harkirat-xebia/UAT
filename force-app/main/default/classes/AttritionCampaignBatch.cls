/*
--------------------------------------------------------------------------------------
-- Name          : AttritionCampaignBatch 
-- Author        : Snehil Verma
-- Updated By    : ChatGPT (Refactor & Segmentation Enhancement)
-- Description   : Batch class for Attrition Campaigns segmented by Business Unit and
--                 Number of Employees with dynamic inactivity thresholds.
--
-- Date          Name                Version     Remarks
-- -----------   ------------------  --------    ---------------------------------------
-- Nov-2024      Snehil Verma        1.0         Initial version
-- Oct-2025      Pranjal Tiwari      2.0         Added segmentation and thresholds
-- Jan-2026     Harkirat Singh       3.0         Added Segmentation and thresholds for LUX, earlier it was for BE only
-- March 2026   Harkirat             4.0         Adding Lead Status and Sub Status
--------------------------------------------------------------------------------------
*/

public class AttritionCampaignBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch all relevant solution line items for BE & LU
        String query = 'SELECT Id, ER_Account__c, ER_Contract__c, Last_Order_Date__c, ' +
                       'ER_Account__r.NumberOfEmployees, ' +
                       'ER_Solution__r.ER_BUPicklist__c, ' +
                       'ER_Solution__r.Exclude_from_Attrition_Campaign__c ' +
                       'FROM ER_Solution_Line_Item__c ' +
                       'WHERE ER_Solution__r.ER_BUPicklist__c IN (\'BE\', \'LU\') ' +
                       'AND ER_Solution__r.Exclude_from_Attrition_Campaign__c = FALSE ' +
                       'AND ER_Contract__c != null ' +
                       'AND ER_Contract__r.Status = \'Activated\' ' +
                       'AND ER_Account__r.NumberOfEmployees != null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<ER_Solution_Line_Item__c> scope) {
        Date todayDate = System.today();

        String quarter = 'Q' + ((todayDate.month() - 1) / 3 + 1) + '-' + todayDate.year();
        Integer qStartMonth = ((todayDate.month() - 1) / 3) * 3 + 1;
        Date qStartDate = Date.newInstance(todayDate.year(), qStartMonth, 1);
        Integer qEndMonth = ((todayDate.month() - 1) / 3) * 3 + 3;
        Date qEndDate = Date.newInstance(todayDate.year(), qEndMonth, Date.daysInMonth(todayDate.year(), qEndMonth));

        // --- Parent Campaigns ---
        Map<String, Campaign> parentCampaignMap = new Map<String, Campaign>();
        for (Campaign pc : [
            SELECT Id, Name
            FROM Campaign
            WHERE ParentId = null AND Type = 'Attrition' AND IsActive = true
        ]) {
            String n = pc.Name.toLowerCase();
            //if (n.contains('mmj')) parentCampaignMap.put('MMj', pc);
            //else if (n.contains('sme')) parentCampaignMap.put('SME', pc);
            if (n.contains('mmj') && !n.contains('lux')) parentCampaignMap.put('MMj', pc);
            else if (n.contains('sme') && !n.contains('lux')) parentCampaignMap.put('SME', pc);
            else if (n.contains('tpe')) parentCampaignMap.put('TPE', pc);
            //removing this line and adding 2 new mapped mmj and sme
            //else if (n.contains('lux')) parentCampaignMap.put('LUX', pc);
            else if (n.contains('lux mmj')) parentCampaignMap.put('LUX_MMJ', pc);
            else if (n.contains('lux sme')) parentCampaignMap.put('LUX_SME', pc);

        }

        Map<String, Integer> thresholds = new Map<String, Integer>{
            'MMj' => 120, 'SME' => 45, 'TPE' => 90, 'LUX_MMJ' => 60, 'LUX_SME' => 70
        };

        Map<String, Set<Id>> segmentToContactIds = new Map<String, Set<Id>>{
            'MMj' => new Set<Id>(),
            'SME' => new Set<Id>(),
            'TPE' => new Set<Id>(),
            //removed and added 2 new 
            //'LUX' => new Set<Id>()
            'LUX_MMJ' => new Set<Id>(),
            'LUX_SME' => new Set<Id>()
        };

        Set<Id> contractIds = new Set<Id>();
        for (ER_Solution_Line_Item__c sli : scope) {
            if (sli.ER_Contract__c != null) contractIds.add(sli.ER_Contract__c);
        }

        Map<Id, Id> contractToPrimaryContact = new Map<Id, Id>();
        for (ContractContactRole ccr : [
            SELECT ContractId, ContactId
            FROM ContractContactRole
            WHERE ContractId IN :contractIds AND Role = 'Primary Contact'
        ]) {
            contractToPrimaryContact.put(ccr.ContractId, ccr.ContactId);
        }

        // --- NEW: Fetch last Attrition Campaign entry per contact ---

        Set<Id> candidateContactIds = new Set<Id>();
        candidateContactIds.addAll(contractToPrimaryContact.values());

        Map<Id, Datetime> contactToLastAttritionDate = new Map<Id, Datetime>();

        if (!candidateContactIds.isEmpty()) {
            for (CampaignMember cm : [
                SELECT ContactId, CreatedDate
                FROM CampaignMember
                WHERE ContactId IN :candidateContactIds
                AND Campaign.Type = 'Attrition'
                AND Campaign.IsActive = true
                ORDER BY CreatedDate DESC
            ]) {
                // Keep only the latest Attrition entry per contact
                if (!contactToLastAttritionDate.containsKey(cm.ContactId)) {
                    contactToLastAttritionDate.put(cm.ContactId, cm.CreatedDate);
                }
            }
        }


        for (ER_Solution_Line_Item__c sli : scope) {
            String segment;
            String bu = sli.ER_Solution__r.ER_BUPicklist__c;
            Integer emp = sli.ER_Account__r.NumberOfEmployees;

            if (bu == 'BE') {
                if (emp >= 30 && emp <= 99) segment = 'MMj';
                else if (emp >= 6 && emp <= 29) segment = 'SME';
                else if (emp >= 0 && emp <= 5) segment = 'TPE';
                else continue;
            } else if (bu == 'LU') {
                segment = (emp >= 30) ? 'LUX_MMJ' : 'LUX_SME';
            } else continue;

            Integer threshold = thresholds.get(segment);
            if (sli.Last_Order_Date__c != null && sli.Last_Order_Date__c <= System.today().addDays(-threshold)) {
                Id contactId = contractToPrimaryContact.get(sli.ER_Contract__c);
                if (contactId != null) {

            Datetime lastAttritionDate = contactToLastAttritionDate.get(contactId);

            // Allow if contact never entered attrition
            if (lastAttritionDate == null) {
                segmentToContactIds.get(segment).add(contactId);
            }
            // Allow reset only if new order happened after last attrition
            else if (sli.Last_Order_Date__c > lastAttritionDate.date()) {
                segmentToContactIds.get(segment).add(contactId);
            }
            // Else: contact already in attrition → DO NOT add again
        }

            }
        }

        // --- Check or create child campaigns ---
        Map<String, Campaign> segmentToCampaign = new Map<String, Campaign>();
        List<Campaign> campaignsToInsert = new List<Campaign>();

        //New 
        Map<String, String> segmentToDisplayName = new Map<String, String>{
            'MMj' => 'MMj',
            'SME' => 'SME',
            'TPE' => 'TPE',
            'LUX_MMJ' => 'LUX MMj',
            'LUX_SME' => 'LUX SME'
        };

        //New code
        // Collect required campaign names
        Set<String> campaignNames = new Set<String>();
        for (String segment : segmentToContactIds.keySet()) {
            if (!segmentToContactIds.get(segment).isEmpty()) {
                campaignNames.add(
                    'Attrition ' + segmentToDisplayName.get(segment) + ' ' + quarter
                );
            }
        }

        // Fetch existing campaigns 
        Map<String, Campaign> existingCampaignMap = new Map<String, Campaign>();
        if (!campaignNames.isEmpty()) {
            for (Campaign c : [
                SELECT Id, Name
                FROM Campaign
                WHERE Name IN :campaignNames
            ]) {
                existingCampaignMap.put(c.Name, c);
            }
        }
        //Create missing campaigns
        for (String segment : segmentToContactIds.keySet()) {
            if (segmentToContactIds.get(segment).isEmpty()) continue;

            String campaignName = 'Attrition ' + segmentToDisplayName.get(segment) + ' ' + quarter;

            /*List<Campaign> existing = [
                SELECT Id FROM Campaign
                WHERE Name = :('Attrition ' + segment + ' ' + quarter)
                LIMIT 1
            ];*/

            //if (existing.isEmpty()) {
            if (existingCampaignMap.containsKey(campaignName)) {
                segmentToCampaign.put(segment, existingCampaignMap.get(campaignName));
            } else {
                Campaign c = new Campaign(
                    //Name = 'Attrition ' + segment + ' ' + quarter,
                    Name = campaignName,
                    Type = 'Attrition',
                    IsActive = true,
                    StartDate = qStartDate,
                    EndDate = qEndDate,
                    //Adding new as per ticket 2384
                    Lead_Source__c = 'Emailing',
                    Lead_sub_source__c = 'Automated email',
                    ER_BUPicklist__c = (segment == 'LUX_MMJ' || segment == 'LUX_SME') ? 'LU' : 'BE',
                    ParentId = parentCampaignMap.containsKey(segment) ? parentCampaignMap.get(segment).Id : null
                );
                campaignsToInsert.add(c);
                segmentToCampaign.put(segment, c);
            }
        }
        
        // Inserting New
        if (!campaignsToInsert.isEmpty()) insert campaignsToInsert;

        List<CampaignMember> cmToInsert = new List<CampaignMember>();
        for (String segment : segmentToContactIds.keySet()) {
            Set<Id> contactIds = segmentToContactIds.get(segment);
            if (contactIds.isEmpty()) continue;
            Campaign c = segmentToCampaign.get(segment);
            if (c == null) continue;

            // Remove existing members
            for (CampaignMember cm : [
                SELECT ContactId FROM CampaignMember
                WHERE CampaignId = :c.Id AND ContactId IN :contactIds
            ]) {
                contactIds.remove(cm.ContactId);
            }

            for (Id cid : contactIds) {
                cmToInsert.add(new CampaignMember(CampaignId = c.Id, ContactId = cid));
            }
        }

        if (!cmToInsert.isEmpty()) insert cmToInsert;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('AttritionCampaignBatch finished. Job Id: ' + bc.getJobId());
    }
}