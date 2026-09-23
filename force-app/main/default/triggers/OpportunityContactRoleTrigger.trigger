trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert, after insert, after update, after delete) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
	    //OpportunityManagementWithoutSharing.syncOpportunityFieldsFromOCR(Trigger.new);
        OpportunityManagementWithoutSharing.syncPrimaryContactFromOCR(Trigger.new, Trigger.old);
     	OpportunityManagementWithoutSharing.syncACRFromOCR(Trigger.new, new List<OpportunityContactRole>());
    }
    
    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityManagementWithoutSharing.preventDuplicateRoles(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isDelete) {
        OpportunityManagementWithoutSharing.syncPrimaryContactFromOCR(new List<OpportunityContactRole>(), Trigger.old);
        OpportunityManagementWithoutSharing.syncACRFromOCR(new List<OpportunityContactRole>(), Trigger.old);
        //OpportunityManagementWithoutSharing.clearOpportunityFieldsOnOCRDelete(Trigger.old);
    }
}