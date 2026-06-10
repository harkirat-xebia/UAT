public class AttritionCampaignBatchForMMj implements Database.Batchable<sObject>,Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date lastOrderDatePast90Days = System.today().addDays(-90);

        String query = 'SELECT ER_Account__c, Id, Last_Order_Date__c, ER_Account__r.ER_BUPicklist__c, ' +
                       'ER_Account__r.HU_HQ_Contact__c, ER_Account__r.NumberOfEmployees ' +
                       'FROM ER_Solution_Line_Item__c ' +
                       'WHERE ER_Account__r.HU_HQ_Contact__c != null ' +
                       'AND ER_Solution__c != null ' +
                       'AND ER_Solution__r.Exclude_from_Attrition_Campaign__c = FALSE ' +
                       'AND Last_Order_Date__c <= :lastOrderDatePast90Days ' +
                       'AND ER_Account__r.ER_BUPicklist__c = \'BE\' ' +
                       'AND ER_Account__r.NumberOfEmployees >= 30 ' +
                       'AND ER_Account__r.NumberOfEmployees <= 100';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<ER_Solution_Line_Item__c> scope) {
        Date todayDate = System.today();
        Campaign campaignObj;
        Set<Id> contactIdSet = new Set<Id>();
        List<CampaignMember> cmList = new List<CampaignMember>();

        String quarter = 'Q' + ((todayDate.month() - 1) / 3 + 1) + '-' + todayDate.year();
        Integer quarterStartMonth = ((todayDate.month() - 1) / 3) * 3 + 1;
        Date quarterStartDate = Date.newInstance(todayDate.year(), quarterStartMonth, 1);
        Integer quarterEndMonth = ((todayDate.month() - 1) / 3) * 3 + 3;
        Integer lastDay = Date.daysInMonth(todayDate.year(), quarterEndMonth);
        Date quarterEndDate = Date.newInstance(todayDate.year(), quarterEndMonth, lastDay);

        List<Campaign> existingCampaigns = [
            SELECT Id FROM Campaign
            WHERE Type = 'Attrition'
            AND IsActive = true
            AND StartDate = :quarterStartDate
            AND EndDate = :quarterEndDate
            AND Name LIKE 'MMj Attrition Campaign%'
            LIMIT 1
        ];

        for (ER_Solution_Line_Item__c sli : scope) {
            if (sli.ER_Account__r.HU_HQ_Contact__c != null) {
                contactIdSet.add(sli.ER_Account__r.HU_HQ_Contact__c);
            }
        }

        if (existingCampaigns.isEmpty()) {
            campaignObj = new Campaign();
            campaignObj.Type = 'Attrition';
            campaignObj.IsActive = true;
            campaignObj.StartDate = quarterStartDate;
            campaignObj.EndDate = quarterEndDate;
            campaignObj.Name = 'MMj Attrition Campaign ' + quarter;
            insert campaignObj;
        } else {
            campaignObj = existingCampaigns[0];
            for (CampaignMember existingCM : [
                SELECT Id, ContactId FROM CampaignMember
                WHERE CampaignId = :campaignObj.Id AND ContactId IN :contactIdSet
            ]) {
                contactIdSet.remove(existingCM.ContactId);
            }
        }

        for (Id contactId : contactIdSet) {
            cmList.add(new CampaignMember(CampaignId = campaignObj.Id, ContactId = contactId));
        }

        if (!cmList.isEmpty()) {
            insert cmList;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('MMj Attrition Campaign Batch Finished. Job ID: ' + bc.getJobId());
    }
    
     public void execute(SchedulableContext sc) {
        Database.executeBatch(new AttritionCampaignBatchForMMj());
    }
}