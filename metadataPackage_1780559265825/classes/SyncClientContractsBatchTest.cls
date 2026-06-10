@isTest
private class SyncClientContractsBatchTest {
    @testSetup
    static void setup() {
        User ur = TestDataFactory.newUser('APHU12', 'APHU12', 'Local Admin', 'Czech_Republic', 'BE');
        ur.ER_BypassVR__c = true;
        ur.ER_bypassTrigger__c = true;
        insert ur;
    
        System.runAs(ur) {
        
            Account accObj = new Account(Name='Test Account', ER_Card_Client_Operational_System_ID__c='3333');
            insert accObj;
            
            Contact conObj = new Contact(LastName='Test Contact');
            conObj.AccountId = accObj.Id;
            insert conObj;
            
            accObj.HU_HQ_Contact__c = conObj.Id;
            update accObj;
            
            Product2 prodObj = new Product2();
            prodObj.Name = 'TEST SOLUTION';
            prodObj.ER_Type__c = 'Discount';
            prodObj.Solution_Group__c = 'Benefits';
            insert prodObj;
            
            Contract con = new Contract();
            con.AccountId = accobj.Id;
            con.Offer_Validity_End_Date__c = System.today().addDays(-1);
            insert con;
            
            ER_ContractLineItem__c cli = new ER_ContractLineItem__c(
                Name = 'CLI Test',
                ER_Contract__c = con.Id,
                ER_Product2__c = prodObj.Id,
                ER_Percentage__c = 50,
                ER_Quantity__c = 5,
                ER_Minimum_Fee__c = 100,
                ER_UnitPrice__c = 200,
                ER_ListPrice__c = 250,
                ER_Line_Type__c = 'Discount'
            );
            insert cli;
        }
        

    }
    
    @isTest
    static void testSyncClientContractsBatch() {
        String mockResponseBody = '{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1731935419","not_before":"1731931519","resource":"7f73991c-df92-4a33-9668-81e58b5ebfe7","access_token":"test"}';
        HTTPCalloutServiceMock testMock = new HTTPCalloutServiceMock(200, mockResponseBody);
        
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
        Database.executeBatch(new SyncClientContractsBatch(), 200);
        String sch ='0 48 * * * ?'; 
		System.schedule('SCE Batch Schedule', sch, new SyncClientContractsScheduler());
        Test.stopTest();
        
    }
}