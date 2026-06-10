@isTest
public class AttritionCampaignBatchTest {
	
    @testSetup static void testSetup(){
        Account accObj = new Account(Name='Test Account', NumberOfEmployees = 22);
        insert accObj;
        
        Contact conObj = new Contact(LastName='Test Contact');
        conObj.AccountId = accObj.Id;
        insert conObj;
        
        accObj.HU_HQ_Contact__c = conObj.Id;
        update accObj;
        
        Product2 prodObj = new Product2();
        prodObj.Name = 'TEST SOLUTION';
        prodObj.ER_BUPicklist__c = 'BE';
        insert prodObj;
        
         Contract contract = new Contract(
          AccountId = accObj.Id,
          StartDate = Date.Today(),
          Status = 'Draft'
        );
        insert contract;
        
        ER_Solution_Line_Item__c sliObj = new ER_Solution_Line_Item__c();
        sliObj.ER_Account__c = accObj.Id;
        sliObj.ER_Solution__c = prodObj.Id;
        sliObj.Last_Order_Date__c = System.today().addDays(-90);
        sliObj.ER_Contract__c = contract.Id;
        insert sliObj;
       
        
    }
    
    @isTest static void testBatch(){
        Test.startTest();
        Database.executeBatch(new AttritionCampaignBatch(), 200);
        String sch ='0 48 * * * ?'; 
		System.schedule('Attrition Schedule', sch, new AttritionCampaignBatchScheduler());
        Test.stopTest();
    }
    
    @isTest static void testBatchWithExistingCampaign(){
        Test.startTest();
        Database.executeBatch(new AttritionCampaignBatch(), 200);
        Test.stopTest();
    }
}