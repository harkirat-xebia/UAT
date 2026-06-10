@isTest
public class APER02_Lead_InactiveLead_Test {
  /* TO BE DELETED TEST COVERED BY BAER01_DeleteInactiveLead_Test
----------------------------------------------------------------------
-- - Name          : APER02_Lead_InactiveLead_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
					- APER02_Lead_InactiveLead
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 12-FAPR-2018  AAB    				1.0      	Initial version 
---------------------------------------------------------------------------------------

     public static List<Lead> createLeadsStandard(Integer numleads, Boolean isToInsert) {
        List<Lead> lds = new List<Lead>();
        
         // Retrieve picklist values
        Schema.DescribeFieldResult fieldResult =
 				Lead.Status.getDescribe();
   		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
         
         
        for(Integer i=0;i<numleads;i++) {
            Lead ld = new Lead(
                LastName='TestLead' + i,
                Status = ple[0].getValue(),
                Company = 'Edenred' + i
            	);
            lds.add(ld);
        }
         
         if (isToInsert) {
             insert lds;
         } 

        return lds;
    }

 */
}