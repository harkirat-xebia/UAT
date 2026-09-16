@IsTest
private class ContractTriggerHandlerTest {
  @IsTest
  static void clearsTerminationFieldsWhenPendingTerminationIsReactivated() {
    Id contractId = Test.getStandardPricebookId();
    Contract oldContract = new Contract(Id = contractId, Status = Constants.PENDING_TERMINATION);
    Contract newContract = new Contract(
      Id = contractId,
      Status = 'Activated',
      ER_TerminationReason__c = 'Costs',
      Termination_Sub_Reason__c = 'Monizze',
      ER_Terminated_Date__c = System.now(),
      EndDate = Date.today().addDays(30)
    );

    APER12_Contract_Management.handleStatusTransitions(
      new Map<Id, Contract>{contractId => newContract},
      new Map<Id, Contract>{contractId => oldContract}
    );

    System.assertEquals(null, newContract.ER_TerminationReason__c, 'Termination Reason must be cleared.');
  System.assertEquals(null, newContract.Termination_Sub_Reason__c, 'Termination Sub-Reason must be cleared.');
    System.assertEquals(null, newContract.ER_Terminated_Date__c, 'Terminated Date must be cleared.');
    System.assertEquals(null, newContract.EndDate, 'Contract End Date must be cleared.');
  }

  @IsTest
  static void requiresTerminationDetailsWhenActivatedContractIsPendingTermination() {
    Id contractId = Test.getStandardPricebookId();
    Contract oldContract = new Contract(Id = contractId, Status = 'Activated');
    Contract newContract = new Contract(Id = contractId, Status = Constants.PENDING_TERMINATION);

    APER12_Contract_Management.handleStatusTransitions(
      new Map<Id, Contract>{contractId => newContract},
      new Map<Id, Contract>{contractId => oldContract}
    );

    System.assert(newContract.hasErrors(), 'The transition must require termination details.');
    System.assertEquals(
      'Termination Reason and Contract End Date are required when changing a contract to Pending Termination.',
      newContract.getErrors()[0].getMessage(),
      'The validation message must identify both required fields.'
    );
  }

  @IsTest
  static void permitsPendingTerminationWhenTerminationDetailsArePresent() {
    Id contractId = Test.getStandardPricebookId();
    Contract oldContract = new Contract(Id = contractId, Status = 'Activated');
    Contract newContract = new Contract(
      Id = contractId,
      Status = Constants.PENDING_TERMINATION,
      ER_TerminationReason__c = 'Costs',
      EndDate = Date.today().addDays(30)
    );

    APER12_Contract_Management.handleStatusTransitions(
      new Map<Id, Contract>{contractId => newContract},
      new Map<Id, Contract>{contractId => oldContract}
    );

    System.assertEquals(false, newContract.hasErrors(), 'The transition must succeed when both fields are supplied.');
  }
}