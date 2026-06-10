@isTest
public class TRER02_AccountBeforeUpdate_Test {
  /*
----------------------------------------------------------------------
-- - Name          : TRER02_AccountBeforeUpdate_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
                    - TRER02_AccountBeforeUpdate
                    - APER01_Account_RelatedClient
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 27-FEB-2018  AAB                 1.0         Initial version 
-- 03-May-2019  OLA                 2.0         Merge MC comment lines
---------------------------------------------------------------------------------------
*/

  @testSetup
  static void testSetup() {
    Account newMerchantAccount = APER07_UtilityTestMethod.getCompany('TRER02_AccountBeforeUpdate_Test');
    insert newMerchantAccount;
  }

  static testMethod void testUpdate() {
    List<Account> accountList = [SELECT id FROM Account WHERE Name = 'TRER02_AccountBeforeUpdate_Test' LIMIT 1];

    if (!accountList.isEmpty()) {
      accountList[0].Name = 'TRER02_AccountBeforeUpdate_Test2';
      accountList[0].ER_Match_Legal_Address__c = true;
      update accountList[0];
    }
  }
  /*
    static map<String, map<String, RecordType>> recordTypeMap;
    static List<Account> clientAcctList;
    static List<Account> merchantAcctList;
    
    static void init(){
        
        // RecordTypes
        recordTypeMap = getRecordTypesBySObject(new List<String>{
                'Account'
            });
        
        
        // Client Account
        clientAcctList = new List<Account>();
        clientAcctList.addAll(APER01_Account_RelatedClient_Test.createAccountsStandard(1, recordTypeMap.get('Account').get('ER_Client_Account_RT').Id, '12345', true));
        
        // Merchant Account 
        merchantAcctList = new List<Account>();
        merchantAcctList.addAll(APER01_Account_RelatedClient_Test.createAccountsStandard(1, recordTypeMap.get('Account').get('ER_Merchant_Account_RT').Id, '1234', false));
    }
    
    // Return the record types by objet 
    public static map<String, map<String, RecordType>> getRecordTypesBySObject(List<String> sObjectName){
        map<String, map<String, RecordType>> result = new map<String, map<String, RecordType>>();
        
        List<RecordType> recordTypeList = [
            SELECT Id, Name, DeveloperName, SobjectType
            FROM RecordType
            WHERE SobjectType IN :sObjectName
        ];
        
        for(RecordType aRecordType : recordTypeList){
            
            if(!result.containsKey(aRecordType.SobjectType)){
                result.put(aRecordType.SobjectType, new map<String, RecordType>());
            }
            
            result.get(aRecordType.SobjectType).put(aRecordType.DeveloperName, aRecordType);
        }
        
        return result;
    }
    
    
    static void Check_theDatabaseUpdate(List<Database.SaveResult> srList) {
        
        // Verify that the insertion should process by the trigger 
        // Iterate through each returned result
        System.debug('## >>> Check the Database update  <<< ');
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('The batch has been successfully proceed. Account ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
    }
    
    
static testMethod void TestAccountBeforeUpdate() {
        
        // Test data setup
        init();
        
        Test.startTest();
    
         Database.SaveResult [] srList = new List<Database.SaveResult>();
         merchantAcctList[0].BillingCity = 'Nantes';
    
        insert merchantAcctList;
    
    
        merchantAcctList[0].ER_VAT_Number__c = '12345';
    
        // update the corresponding merchant account
        srList = Database.update(merchantAcctList, false);
        
        Check_theDatabaseUpdate(srList);

        Test.stopTest();
        
        // Check the results (assert)
        List<Account> result = [Select id, ER_Also_Client_Merchant__c from Account where RecordTypeId  =:recordTypeMap.get('Account').get('ER_Merchant_Account_RT').Id];
        System.assertEquals(true, result[0].ER_Also_Client_Merchant__c, 'there merchant account had been successfully updated');
    }
    */
}