@isTest
public class ER_RecordInfoOnApprovalControllerTest {

    @isTest
    static void testGetOpportunityDataFromWorkItem() {
        ER_Promo_Code__c promo = new ER_Promo_Code__c(
            Name = 'TestPromo',
            ER_Business_Unit__c = 'BE',
            ER_Start_Date__c = Date.today().addDays(-5),
            ER_End_Date__c = Date.today().addDays(55),
            ER_Promo_Code__c = 'TestPromo',
            RecordTypeId = Utils.getRecordTypeIdByDeveloperName(
                ER_Promo_Code__c.SObjectType,
                Constants.PROMO_CODE_PROMO_RT
            ),
            ER_Affiliation_Type__c = Constants.PARENT,
            Promo_End_Date__c = Date.today()
        );
        insert promo;

        Product2 prod = APER07_UtilityTestMethod.getProduct('Test');
        prod.IsActive = true;
        insert prod;

        PriceBook2 standardPriceBook = APER07_UtilityTestMethod.getpriceBook();

        Pricebook2 pricebook2 = APER07_UtilityTestMethod.getCustomPriceBook('TestPB');
        insert pricebook2;

        PriceBookEntry standardPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
            standardPriceBook.id,
            prod.id
        );
        standardPriceBookEntry.ER_Promo_Code2__c = promo.Id;
        standardPriceBookEntry.ER_Offer_validity_end_date__c = Date.today().addDays(10);
        insert standardPriceBookEntry;

        PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(
            pricebook2.id,
            prod.id
        );
        newPriceBookEntry.ER_Promo_Code2__c = promo.Id;
        newPriceBookEntry.ER_Offer_validity_end_date__c = Date.today().addDays(10);
        insert newPriceBookEntry;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000,
            Pricebook2Id = pricebook2.Id,
            ER_NeedApproval__c = true,
            Max_Discount__c = 25
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = newPriceBookEntry.Id,
            Total_Amount__c = 100,
            ER_Face_Value__c = 10,
            ER_Days_Per_Month__c = 20,
            ER_Load_Per_Year__c = 12,
            ER_Nb_Beneficiaries__c = 100
            
        );
        insert oli;

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(opp.Id);
        req.setSubmitterId(UserInfo.getUserId());
        req.setComments('Submitting for approval');
        req.setNextApproverIds(new Id[] { UserInfo.getUserId() });

        Test.startTest();
        Approval.ProcessResult result = Approval.process(req);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Approval submission failed');
        Id workItemId = result.getInstanceId();
        System.assertNotEquals(null, workItemId, 'WorkItem ID should not be null');
        System.debug('testtt Status '+result.getInstanceStatus());
        
       ProcessInstance a =  [SELECT Id, TargetObjectId FROM ProcessInstance where ID =:workItemId];
        System.debug('testtt a '+a);
        
        // Query the WorkItem using the ProcessInstanceId
        ProcessInstanceWorkitem workItem = [
            SELECT Id, ActorId, ProcessInstanceId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstanceId = :workItemId
            LIMIT 1
        ];

        String url = ApprovalLinkController.generateApprovalURL(opp.Id);
        Map<String, Object> resultMap = ER_RecordInfoOnApprovalController.getOpportunityDataFromWorkItem(workItem.Id);

        System.assert(resultMap.containsKey('opportunity'), 'Result must contain opportunity');
        System.assert(resultMap.containsKey('lineItems'), 'Result must contain line items');

        Opportunity returnedOpp = (Opportunity)resultMap.get('opportunity');
        List<OpportunityLineItem> returnedItems = (List<OpportunityLineItem>)resultMap.get('lineItems');

        System.assertEquals(opp.Id, returnedOpp.Id, 'Opportunity ID should match');
        System.assertEquals(1, returnedItems.size(), 'Should return one opportunity line item');
    }
}