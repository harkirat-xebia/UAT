/**
 * Created by noorgoolamnabee on 26/05/2023.
 */

@IsTest
private class APER42_TaskManagement_Test {
    private static User makeUserWithQueue(Boolean withQueue) {
        User u = TestDataFactory.newUser(
            'APER42' + Datetime.now().getTime(),
            'APER42' + Datetime.now().getTime(),
            'Local Admin',
            'France',
            'FR'
        );
        u.ER_BypassVR__c = true;
        if (withQueue) u.ER_Queue_CTI__c = 'QUEUE-TEST-ID';
        insert u;
        return u;
    }

    private static Lead makeLead() {
        Lead ld = APER07_UtilityTestMethod.getLead(
            Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT')
        );
        insert ld;
        return ld;
    }

    @IsTest
    static void testPreventTaskDeletion() {
        List<Task> tasks = new List<Task>{
            new Task(Subject = Constants.GENESYS_TASK_TYPE, Status = 'Open', Priority = 'Normal'),
            new Task(Subject = 'Other', Status = 'Open', Priority = 'Normal')
        };
        insert tasks;

        Test.startTest();
        Database.DeleteResult[] results = Database.delete(tasks, false);
        Test.stopTest();

        Boolean sawError = false;
        for (Database.DeleteResult dr : results) {
            if (!dr.isSuccess()) {
                sawError = true;
                System.assertEquals(tasks[0].Id, dr.getId());
                System.assertEquals(Label.LAB_SF_TASK_DELETION_ERROR, dr.getErrors()[0].getMessage());
            }
        }
        System.assert(sawError, 'Expected at least one delete error for Genesys task');
    }

    @IsTest
    static void testIsFollowUpTask_trueAndFalse() {
        Task oldT = new Task(CallDisposition = 'OLD');
        Task newT1 = new Task(Id = '00T000000000001AAA', CallDisposition = Constants.GENESYS_TASK_FOLLOW_UP_CODE[0]);
        Task newT2 = new Task(Id = '00T000000000002AAA', CallDisposition = Constants.GENESYS_TASK_FOLLOW_UP_CODE[0]);

        Map<Id, Task> oldMap = new Map<Id, Task>{
            newT1.Id => new Task(CallDisposition = 'DIFFERENT'),
            newT2.Id => new Task(CallDisposition = Constants.GENESYS_TASK_FOLLOW_UP_CODE[0])
        };

        System.assertEquals(true, APER42_TaskManagement.isFollowUpTask(newT1, oldMap));
        System.assertEquals(false, APER42_TaskManagement.isFollowUpTask(newT2, oldMap));
    }

    @IsTest
    static void testGetQueue_returnsValueAndNull() {
        User uWith = makeUserWithQueue(true);
        User uWithout = makeUserWithQueue(false);

        Map<Id, User> userMap = new Map<Id, User>{
            uWith.Id => uWith,
            uWithout.Id => uWithout
        };

        System.assertEquals('QUEUE-TEST-ID', APER42_TaskManagement.getQueue(userMap, uWith.Id));
        System.assertEquals(null, APER42_TaskManagement.getQueue(userMap, uWithout.Id));
        System.assertEquals(null, APER42_TaskManagement.getQueue(userMap, UserInfo.getUserId()));
    }

    @IsTest
    static void testCalculatePriorityAndSchedule_lead_high_and_normal() {
        User u = makeUserWithQueue(true);

        System.runAs(u) {
            Lead ld = makeLead();

            Task parent = new Task(
                Subject = Constants.GENESYS_TASK_TYPE,
                Status = 'Open',
                Priority = 'Normal',
                WhoId = ld.Id,
                OwnerId = u.Id
            );
            insert parent;

            Task followA = new Task();
            APER42_TaskManagement.calculatePriorityAndSchedule(parent, followA, new Map<Id, Task>());
            System.assertEquals(Constants.CASE_PRIORITY_HIGH, followA.Priority);
            System.assertNotEquals(null, followA.Gsys_Planned_Date__c);
            System.assertEquals(followA.Gsys_Planned_Date__c.date(), followA.ActivityDate);
            System.assertEquals(true, followA.IsReminderSet);

            Map<Id, Task> existing = new Map<Id, Task>{
                ld.Id => new Task(Id = '00T000000000009AAA')
            };
            Task followB = new Task();
            APER42_TaskManagement.calculatePriorityAndSchedule(parent, followB, existing);
            System.assertEquals(Constants.NORMAL, followB.Priority);
            System.assertEquals(true, followB.IsReminderSet);
        }
    }

    @IsTest
    static void testCalculatePriorityAndSchedule_nonLead_normal() {
        User u = makeUserWithQueue(true);

        System.runAs(u) {
            Task parent = new Task(
                Subject = Constants.GENESYS_TASK_TYPE,
                Status = 'Open',
                Priority = 'Normal',
                OwnerId = u.Id
            );
            insert parent;

            Task follow = new Task();
            APER42_TaskManagement.calculatePriorityAndSchedule(parent, follow, new Map<Id, Task>());
            System.assertEquals(Constants.NORMAL, follow.Priority);
            System.assertEquals(true, follow.IsReminderSet);
            System.assertNotEquals(null, follow.Gsys_Planned_Date__c);
        }
    }

    @IsTest
    static void testCreateFollowUpTaskManually_setsFields_andDates() {
        User u = makeUserWithQueue(true);

        System.runAs(u) {
            Lead ld = makeLead();
            Task existingFU = new Task(
                Subject = Constants.GENESYS_TASK_FOLLOW_UP_SUBJECT,
                Status = Constants.GENESYS_TASK_STATUS_OPEN,
                Priority = 'Normal',
                OwnerId = u.Id,
                WhoId = ld.Id,
                Gsys_Activity_Type__c = Constants.GENESYS_TASK_FOLLOW_UP_TYPE
            );
            insert existingFU;

            Datetime planned = Datetime.now().addDays(3);

            Task t = new Task(
                Subject = 'Manual',
                Status = 'Open',
                Priority = 'Normal',
                OwnerId = u.Id,
                WhoId = ld.Id,
                Gsys_Reason_For_Follow_up__c = Constants.GENESYS_TASK_FOLLOW_UP_REASON_CODE[0],
                Gsys_Activity_Type__c = 'SomethingElse',
                Gsys_Planned_Date__c = planned
            );

            List<Task> items = new List<Task>{ t };

            APER42_TaskManagement.createFollowUpTaskManually(items);

            System.assertEquals(Constants.GENESYS_TASK_FOLLOW_UP_TYPE, t.Gsys_Activity_Type__c);
            System.assertEquals('QUEUE-TEST-ID', t.Gsys_Call_QueueName__c);
            System.assertEquals(planned.date(), t.ActivityDate);
            System.assertEquals(planned, t.ReminderDateTime);
            System.assertEquals(true, t.IsReminderSet);
            System.assertEquals(Constants.NORMAL, t.Priority);
        }
    }

    @IsTest
    static void testGetExistingTaskOnLead_returnsMap() {
        User u = makeUserWithQueue(true);

        System.runAs(u) {
            Lead ld = makeLead();

            Task existingFU = new Task(
                Subject = Constants.GENESYS_TASK_FOLLOW_UP_SUBJECT,
                Status = Constants.GENESYS_TASK_STATUS_OPEN,
                Priority = 'Normal',
                OwnerId = u.Id,
                WhoId = ld.Id,
                Gsys_Activity_Type__c = Constants.GENESYS_TASK_FOLLOW_UP_TYPE
            );
            insert existingFU;

            Task manualCandidate = new Task(
                Subject = 'Manual',
                Status = 'Open',
                Priority = 'Normal',
                OwnerId = u.Id,
                WhoId = ld.Id,
                Gsys_Reason_For_Follow_up__c = Constants.GENESYS_TASK_FOLLOW_UP_REASON_CODE[0],
                Gsys_Activity_Type__c = 'SomethingElse'
            );

            Map<Id, Task> res = APER42_TaskManagement.getExistingTaskOnLead(new List<Task>{ manualCandidate });
            System.assert(res.containsKey(ld.Id), 'Expected existing follow-up in map');
        }
    }
    
    @IsTest
static void testCreateTask_and_MapWrapCode_Coverage() {
    User u = TestDataFactory.newUser('APER42' + Datetime.now().getTime(), 'APER42', 'Local Admin', 'France', 'FR');
    u.ER_BypassVR__c = true;
    u.ER_Queue_CTI__c = 'QUEUE-TEST-ID';
    insert u;

    System.runAs(u) {
        Lead ld = APER07_UtilityTestMethod.getLead(
            Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT')
        );
        insert ld;

        Task parent = new Task(
            Subject = Constants.GENESYS_TASK_TYPE,
            Status = 'Open',
            Priority = 'Normal',
            OwnerId = u.Id,
            WhoId = ld.Id,
            Gsys_Salesforce_WrapUpCode__c = 'Relance' 
        );
        insert parent;

        Map<Id, Task> existing = new Map<Id, Task>();
        String queueId = APER42_TaskManagement.getQueue(new Map<Id,User>{u.Id => u}, u.Id);

        Test.startTest();
        Task follow = APER42_TaskManagement.createTask(parent, existing, queueId);
        Test.stopTest();

        System.assertEquals(Constants.GENESYS_TASK_FOLLOW_UP_SUBJECT, follow.Subject);
        System.assertEquals(Constants.GENESYS_TASK_FOLLOW_UP_TYPE, follow.Gsys_Activity_Type__c);
        System.assertEquals(queueId, follow.Gsys_Call_QueueName__c);
        System.assertEquals(parent.WhoId, follow.WhoId);
        System.assertEquals(parent.OwnerId, follow.OwnerId);

    }
}

    @IsTest
    static void testUpdateTaskDate_whenPlannedChanges_updatesDueReminder() {
        Task tOld = new Task(
            Id = '00T000000000010AAA',
            Gsys_Planned_Date__c = Datetime.now().addDays(1)
        );
        Task tNew = new Task(
            Id = tOld.Id,
            Gsys_Planned_Date__c = Datetime.now().addDays(5)
        );

        Map<Id, Task> oldMap = new Map<Id, Task>{ tOld.Id => tOld };
        Map<Id, Task> newMap = new Map<Id, Task>{ tNew.Id => tNew };

        APER42_TaskManagement.updateTaskDate(newMap, oldMap);

        Task updated = newMap.get(tOld.Id);
        System.assertEquals(updated.Gsys_Planned_Date__c.date(), updated.ActivityDate);
        System.assertEquals(updated.Gsys_Planned_Date__c, updated.ReminderDateTime);
        System.assertEquals(true, updated.IsReminderSet);
    }
}