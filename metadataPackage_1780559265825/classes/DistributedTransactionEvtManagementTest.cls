/**
 * @author: ALK
 * @date: 05/01/2023
 * @desc: DistributedTransactionEvtManagementTest
 * @see: DistributedTransactionEvtManagementTest
 */

@IsTest
private class DistributedTransactionEvtManagementTest {
  @IsTest
  static void testBehavior() {
    Account newMerchantAccount = APER07_UtilityTestMethod.insertAccount(
      'testCompany' + Datetime.now().getTime(),
      'ER_Company_Account_RT'
    );

    Pricebook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();

    Product2 newSolution = APER07_UtilityTestMethod.getsolution('newSoltion' + Datetime.now().getTime());
    insert newSolution;
    Product2 newService = APER07_UtilityTestMethod.getservice('newService' + Datetime.now().getTime(), newSolution.Id);
    insert newService;

    PricebookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.Id, newService.Id);
    insert newPriceBookEntry;

    Opportunity newOpportunity = APER07_UtilityTestMethod.getOpportunity(Constants.OPPORTUNITY_MERCHANT_RT, 'newOpp');
    newOpportunity.AccountId = newMerchantAccount.Id;
    newOpportunity.Pricebook2Id = newPriceBook.Id;
    //Adding new so that the Add to branch ticket does not throw error Controlling field added by baptist
    newOpportunity.Onboarding_Method__c = 'OSS';
    newOpportunity.Impacted_Beneficiaries__c = 'All';
    insert newOpportunity;

    OpportunityLineItem newOpportunityProduct = APER07_UtilityTestMethod.getOpportunityLineItem(
      newOpportunity.Id,
      newPriceBookEntry.Id
    );
    insert newOpportunityProduct;

    Quote merchantQuote = APER07_UtilityTestMethod.getQuote(
      Constants.QUOTE_MERCHANT_RT,
      'newQuote',
      newOpportunity.Id,
      newPriceBook.Id
    );
    merchantQuote.ER_Quote_Type__c = Label.LAB_SF_Contact_Operational;
    insert merchantQuote;

    QuoteLineItem qli = APER07_UtilityTestMethod.getQuoteLineItem(merchantQuote.Id, newPriceBookEntry.Id);
    qli.ER_Line_Type__c = 'Service';
    insert qli;

    Test.startTest();
    merchantQuote.Status = Constants.ACCEPTED;
    update merchantQuote;

    Contract createdContract = [
      SELECT
        Id,
        RecordTypeId,
        ER_Business_Unit__c,
        ER_InvoicingFrequency2__c,
        ER_ReimbursementTerm2__c,
        CustomerSigned.Email,
        CustomerSignedId,
        ERBE_Reimbursement_Statement_Frequency__c,
        Status,
        ER_Indexation__c,
        ER_OppIndexation2__c,
        ER_PaymentTerms2__c,
        ER_PaymentMethod2__c,
        Account.ER_VIP__c,
        Subscription__c,
        ER_ZuoraQuote__c,
        ERBE_Reimbursement_statement_Support__c,
        AccountId,
        Account.Name,
        StartDate,
        EndDate,
        ER_OpportunityId__c,
        ER_OpportunityId__r.ER_IsAmended__c,
        ER_OpportunityId__r.ER_AmendedFromContract__c,
        ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId,
        ContractNumber,
        ER_Creation_date_in_OS__c,
        CustomerSignedDate,
        ER_OpportunityId__r.ER_AmendedFromContract__r.StartDate,
        ER_Contract_Type__c,
        ER_Original_Agreement__c,
        ER_Original_Agreement__r.Status,
        ER_Original_Agreement__r.ER_Contract_Type__c,
        RecordType.DeveloperName,
        ER_OpportunityId__r.ER_SmartER_Context__c,
        (
          SELECT
            Id,
            ER_Contract__c,
            Name,
            ER_Solution__c,
            ER_ProductCode__c,
            ER_Creation_date_in_OS__c,
            ER_Product2__c,
            ER_Product2__r.Name
          FROM ER_ContractLineItems__r
        )
      FROM Contract
      WHERE ER_QuoteId__c = :merchantQuote.Id
    ];

    Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
    dte.Transaction_Name__c = Constants.MANAGE_SOLUTION_LINE_ITEMS;
    dte.Transaction_Content__c = JSON.serializePretty(createdContract);
    EventBus.publish(dte);
    Test.stopTest();
  }
}