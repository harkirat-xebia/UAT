@isTest
public class TestUpdateGroupEmployeeCountBatch {
    @testSetup
    static void setupData() {
        Account grandParent = APER07_UtilityTestMethod.getCompany('Grandparent');
        grandParent.ER_Decision_maker__c = true;
        grandParent.NumberOfEmployees = 10;
        insert grandParent;

        Account parentRec = APER07_UtilityTestMethod.getCompany('Parent');
        parentRec.ParentId = grandParent.Id;
        parentRec.NumberOfEmployees = 20;
        insert parentRec;
        
        Account child = APER07_UtilityTestMethod.getCompany('Child');
        child.ParentId = parentRec.Id;
        child.NumberOfEmployees = 30;
        insert child;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        UpdateGroupEmployeeCountBatch batch = new UpdateGroupEmployeeCountBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Account updatedGrandParent = [
            SELECT Id, Total_Group_Employees__c
            FROM Account
            WHERE Name = 'Grandparent'
            LIMIT 1
        ];

        System.assertEquals(60, updatedGrandParent.Total_Group_Employees__c, 
            'Total_Group_Employees__c should reflect sum of NumberOfEmployees across the account hierarchy');
    }
}