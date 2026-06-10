trigger CampaignMemberStatusTrigger on Campaign (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        CampaignMemberStatusHandler.createDefaultStatuses(Trigger.new);
    }
}