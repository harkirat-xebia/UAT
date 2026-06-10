@isTest
public class APER01_Account_RelatedClient_Test {
  /*
----------------------------------------------------------------------
-- - Name          : AP01_Account_RelatedClient_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
					- AP01_Account_RelatedClient
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 27-FEB-2018  AAB    				1.0      	Initial version 
-- 03-May-2019  OLA                 2.0         Merge MC comment lines 
---------------------------------------------------------------------------------------
*/
  /*
     public static List<Account> createAccountsStandard(Integer numAccts, Id recordType, String vatNumber, Boolean isToInsert) {
        List<Account> accts = new List<Account>();
        
        for(Integer i=0;i<numAccts;i++) {
            Account a = new Account(
                Name='TestAccount' + i,
            	RecordTypeId = recordType,
            	ER_VAT_Number__c = vatNumber,
            	BillingCity = 'Paris',
                ER_Match_Legal_Address__c = true
            	);
            accts.add(a);
        }
         
         if (isToInsert) {
             insert accts;
         } 

        return accts;
    }
    */
}