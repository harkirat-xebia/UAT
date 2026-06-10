public with sharing class APER01_Account_RelatedClient {
  /*
----------------------------------------------------------------------
-- - Name          : AP01_Account_RelatedClient
-- - Author        : AAB
-- - Description   : Process the Account merchand related client lookup        
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 27-FEB-2018  AAB    				1.0      	Initial version
-- 03-May-2019  OLA                 2.0         Merge MC comment lines 
---------------------------------------------------------------------------------------
*/
  /*
    public static Boolean alreadyExecutedAccount = false;

    public static void lookForRelatedClientMerchant(List<Account> merchandToUpdate) {
        
        //List<Opportunity> myOppList = [Select id, Indice_du_Devis__c from Opportunity where id In :opportMapToUpdate.keySet()];
        Set<String> vatNumberSet = new Set<String>();  
        Map<String, Id> mapOfClient = new Map<String, Id>();
        Map<String, Id> mapOfMerchant = new Map<String, Id>();
        
       	// Construct the related VAT number set
        for (Account acc : merchandToUpdate) {
            vatNumberSet.add(acc.ER_VAT_Number__c);
        }
        
       */
  // Then request for the related Clients
  /*for (Account clt : [Select id, ER_VAT_Number__c, Type from Account where recordtype.DeveloperName = 'ER_Client_Account_RT' and 
                            ER_VAT_Number__c in :vatNumberSet]) {
            mapOfClient.put(clt.ER_VAT_Number__c, clt.id);
        }*/

  /*for (Account clt : [Select id, ER_VAT_Number__c, Type from Account where (recordtype.DeveloperName = 'ER_Client_Account_RT' 
                            or recordtype.DeveloperName = 'ER_Merchant_Account_RT') and ER_VAT_Number__c in :vatNumberSet]) {
                                if (clt.Type == 'Client') {
                                    mapOfClient.put(clt.ER_VAT_Number__c, clt.id);
                                } 
                                else {
                                    mapOfMerchant.put(clt.ER_VAT_Number__c, clt.id);
                                }
        }
        
        
        
        // Finally update the related merchands/client
        for (Account mc : merchandToUpdate) {
            if (mc.Type == 'Merchant' && mapOfClient.get(mc.ER_VAT_Number__c) != null) {
                
                mc.ER_Client_Merchant__c = mapOfClient.get(mc.ER_VAT_Number__c);
            	mc.ER_Also_Client_Merchant__c = (mapOfClient.get(mc.ER_VAT_Number__c) != null) ? true : false;
            }
            else if (mc.Type == 'Client' && mapOfMerchant.get(mc.ER_VAT_Number__c) != null) {
                
                mc.ER_Client_Merchant__c = mapOfMerchant.get(mc.ER_VAT_Number__c);
            	mc.ER_Also_Client_Merchant__c = (mapOfMerchant.get(mc.ER_VAT_Number__c) != null) ? true : false;
            }
        }

		APER01_Account_RelatedClient.alreadyExecutedAccount = true;        
    }
    */
  /** Return the record types by objet **/
  /*public static map<String, map<String, RecordType>> getRecordTypesBySObject(List<String> sObjectName){
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
    }*/
}