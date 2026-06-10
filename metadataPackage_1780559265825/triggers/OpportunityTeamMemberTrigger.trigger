trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (
    after insert,
    after update,
    after delete,
    after undelete) {
        TriggerDispatcher.run(new OpportunityTeamMemberTriggerHandler());
    }