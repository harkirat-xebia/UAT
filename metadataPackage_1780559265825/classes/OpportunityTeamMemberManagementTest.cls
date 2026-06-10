/*
----------------------------------------------------------------------
-- - Name          : OpportunityTeamMemberManagementTest
-- - Author        : SNEHIL VERMA
-- - Description   : Test Class for OpportunityTeamMemberManagement
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  DEC-2024       SNEHIL             1.0         Initial version
---------------------------------------------------------------------------------------
*/
@isTest
public class OpportunityTeamMemberManagementTest {
	@testSetup
	static void testSetup() {
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity oppObj1 = new Opportunity();
        oppObj1.Name = 'New Opportunity';
        oppObj1.StageName = 'Qualification';
        oppObj1.CloseDate = System.today().addDays(10);
        oppList.add(oppObj1);
        
        Opportunity oppObj2 = new Opportunity();
        oppObj2.Name = 'New Opportunity1';
        oppObj2.StageName = 'Qualification';
        oppObj2.CloseDate = System.today().addDays(10);
        oppList.add(oppObj2);
        
        insert oppList;
    }
    
    @IsTest
    static void visibilityTest() {
        
        List<Opportunity> oppList = [SELECT Id from Opportunity limit 2];
        
        OpportunityTeamMember otmObj = new OpportunityTeamMember();
        otmObj.OpportunityId = oppList[0].Id;
        otmObj.UserId = UserInfo.getUserId();
        insert otmObj;
        
        otmObj.OpportunityAccessLevel = 'Read';
        update otmObj;
        
        delete otmObj;
        
    }
}