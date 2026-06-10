@isTest
public class APER09_Task_Management_Test {
  @testSetup
  static void testSetup() {
    User runningUser = [SELECT id, ER_Business_Unit__c, ER_BUText__c FROM User WHERE id = :UserInfo.getUserId()];
    Lead lead = APER07_UtilityTestMethod.getLead(
      Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
    );
    insert lead;
    Case testCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
    testCase.ownerId = runningUser.Id;
    insert testCase;
    Account newMerchantAccount = APER07_UtilityTestMethod.insertAccount(
      'APHU12_Contract_Management_Test',
      'ER_Company_Account_RT'
    );
    PriceBook2 stdPriceBook = APER07_UtilityTestMethod.getpriceBook();
    PriceBook2 newPriceBook = APER07_UtilityTestMethod.getCustomPriceBook('Pricebook');
    insert newPriceBook;
    Product2 newSolution = APER07_UtilityTestMethod.insertProduct2(
      'testSolution',
      runningUser.ER_Business_Unit__c,
      null,
      'Solution',
      null
    );
    Product2 newService = APER07_UtilityTestMethod.insertProduct2(
      'testService',
      runningUser.ER_Business_Unit__c,
      null,
      'service',
      newSolution.Id
    );
    PricebookEntry standardPrice = APER07_UtilityTestMethod.getpriceBookEntry(stdPriceBook.id, newService.id);
    insert standardPrice;
    PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
    insert newPriceBookEntry;
    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(
      'ER_Merchant_Opportunity',
      'APHU12_Contract_Management_Test'
    );
    newOpportunity.AccountId = newMerchantAccount.Id;
    insert newOpportunity;

    OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
      newOpportunity.id,
      newPriceBookEntry.id
    );
    insert newOpportunityProduct;

    Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
      'ER_Merchant_Quote',
      'APHU12_Contract_Management_Test',
      newOpportunity.id,
      newPriceBook.Id
    );
    insert merchantQuote;
    Contract newContract = APER07_UtilityTestMethod.insertContract(
      newMerchantAccount.Id,
      Date.today(),
      Label.LABS_SF_Contract_Status_Draft,
      newPriceBook.Id,
      'ER_Merchant_Contract_RT',
      runningUser.Id
    );
  }

  static testMethod void testCreateTaskForContractWithoutInsert() {
    List<Case> cases = [SELECT Id, ownerId, Subject FROM Case];
    Task taskCase = APER09_Task_Management.CreateTaskForContractWithoutInsert(
      'taskSubject',
      cases[0].ownerId,
      null,
      cases[0].Id,
      null
    );
    System.assertEquals(cases[0].Id, taskCase.WhatId);
    System.assertEquals('taskSubject', taskCase.Subject);
    System.assertEquals(null, taskCase.ActivityDate);
    System.assertEquals(null, taskCase.WhoId);

    List<Contract> contracts = [SELECT Id, name, CreatedById FROM Contract];
    ID contactID = [SELECT Id, name, ContactId FROM Quote LIMIT 1].ContactId;
    Task taskContract = APER09_Task_Management.CreateTaskForContractWithoutInsert(
      Label.LABS_SF_Task_Subject_WelcomeLetter,
      contracts[0].CreatedById,
      Date.today() + 1,
      contracts[0].Id,
      contactID
    );
    system.assertEquals(Label.LABS_SF_Task_Subject_WelcomeLetter, taskContract.Subject);
    System.assertEquals(Date.today() + 1, taskContract.ActivityDate);
    System.assertEquals(contactID, taskContract.WhoId);
    System.assertEquals(contracts[0].CreatedById, taskContract.OwnerId);
    System.assertEquals(contracts[0].Id, taskContract.WhatId);
  }

  static testMethod void testCreateTask() {
    ID caseId = [SELECT Id, ownerId, Subject FROM Case LIMIT 1].Id;
    APER09_Task_Management.CreateTask(
      Label.LAB_SF_Task_UpdateIndividualSuccess,
      Label.LAB_SF_Task_StatusCompleted,
      caseId
    );
    List<Task> tasks = [SELECT Id, Subject, WhatId, Status FROM Task];
    //System.assertEquals(caseId, tasks[0].WhatId);
    //System.assertEquals('Send Quote', tasks[0].Subject);
    //System.assertEquals('Not Started', tasks[0].Status);
  }

  static testMethod void testCreateTaskForLeadUpdate() {
    ID queueID = [SELECT Id FROM Group LIMIT 1].Id;
    ID leadID = [SELECT Id FROM Lead LIMIT 1].Id;
    Task task = APER09_Task_Management.CreateTaskForLeadUpdate(
      Label.LAB_SF_Task_Subject_MID,
      queueID,
      System.today().addDays(5),
      leadID
    );
    System.assertEquals(Label.LAB_SF_Task_Subject_MID, task.Subject);
    System.assertEquals(queueID, task.OwnerId);
    System.assertEquals(System.today().addDays(5), task.ActivityDate);
    System.assertEquals(leadID, task.WhoId);
  }

  static testMethod void testCreateTaskForLeadCreation() {
    List<Case> cases = [SELECT Id, ownerId, Subject FROM Case];
    Task task = APER09_Task_Management.CreateTaskForLeadCreation(
      Label.LAB_SF_Lead_Subject_UpdateAffiliationRequest,
      cases[0].ownerId,
      date.today(),
      cases[0].Id
    );
    System.assertEquals(Label.LAB_SF_Lead_Subject_UpdateAffiliationRequest, task.Subject);
    System.assertEquals(cases[0].ownerId, task.OwnerId);
    System.assertEquals(date.today(), task.ActivityDate);
    System.assertEquals(cases[0].Id, task.WhatId);
  }
}