@isTest
private class GenesysCloud_API_Test {
  @isTest
  static void testDisconnect() {
    // Call the scheduleGenesysCallback method
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GenesysCloudAPIMock());
    Lead ld = APER07_UtilityTestMethod.getLead(
      Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT')
    );
    Task t = new Task(
      Subject = Constants.GENESYS_TASK_TYPE,
      Gsys_Call_ConversationId__c = 'd537ebe2-6503-47aa-9954-402d05acf371',
      WhoId = ld.Id
    );
    insert t;
    GenesysCloud_API.disconnectConversation(new Map<String, String>{ t.Gsys_Call_ConversationId__c => t.Id });
    Test.stopTest();
  }

  @IsTest
  static void testGenesysSync() {
    User ur = TestDataFactory.newUser('APER18', 'APER18', 'Local Admin', 'FR');
    ur.ER_BypassVR__c = true;
    ur.ER_Queue_CTI__c = '92eb5086-c37e-46b4-b9a8-0423de74ddb4';
    insert ur;

    System.runAs(ur) {
      purecloud__PureCloud_Entity__c a = APER07_UtilityTestMethod.newGenesysEmailFlow(
        'ERF_Distrib_Lead_Opportunite_SME'
      );
      insert a;
      Lead ld = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Client_Lead_RT')
      );

      insert ld;
      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new GenesysCloudAPIMock());
      Task t = new Task(
        Subject = Constants.GENESYS_TASK_TYPE,
        Gsys_Salesforce_WrapUpCode__c = 'Relance',
        WhoId = ld.Id
      );
      insert t;

      Map<Id, User> userMap = Utils.getUserMap();
      String queueId = APER42_TaskManagement.getQueue(userMap, t.OwnerId);
      String keyFlow = Constants.GENESYS_TASK_FLOW_ID_CONFIG + t.ER_Business_Unit__c;
      String flowName = Utils.getGlobalSettingsValueFromKey(keyFlow.toUpperCase());
      t = [SELECT Id, CreatedDate, OwnerId, WhatId, WhoId FROM Task WHERE Id = :t.Id];

      List<GenesysRoutingRequest> reqs = new List<GenesysRoutingRequest>{
        APER18_Lead_Management.createLeadGenesysRoutingRequest(flowName, queueId, ld)
      };
      GenesysCloud_API.createConversation(JSON.serializePretty(reqs));
      GenesysCloud_API.createStandardTask(reqs[0], '89w4573');
      Test.stopTest();
    }
  }
}