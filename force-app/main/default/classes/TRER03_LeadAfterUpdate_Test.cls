@isTest
public class TRER03_LeadAfterUpdate_Test {
  /*
----------------------------------------------------------------------
-- - Name          : TRER03_LeadAfterUpdate_Test
-- - Author        : AAB
-- - Description   : Test class related to the Apex classes cited below
					- TRER03_LeadAfterUpdate
					- APER03_Lead_CreateFinancialCenter
-- Maintenance History:
--
-- Date         Name  				Version  	Remarks 
-- -----------  ----------- 		--------  	---------------------------------------
-- 17-JUL-2018  AAB    				1.0      	Initial version 
---------------------------------------------------------------------------------------
*/

  /** static map<String, map<String, RecordType>> recordTypeMap;
    static List<Lead> merchantLeadList;
    static List<Account> merchantAcctList;
    
    static void init(){

        recordTypeMap = getRecordTypesBySObject(new List<String>{
                'Lead'
            });
        

        Case c = new Case();
        merchantLeadList = new List<Lead>();
        merchantLeadList.addAll(APER03_Lead_CreateFinancialCenter_Test.createLeadsStandard(1, recordTypeMap.get('Lead').get('ER_Merchant_Lead_RT').Id, '123456789', true));
		
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'Client Sales'];
        User u = new User(LastName = 'ClientSales', Username = 'test@clientsales.com', Email = 'test@clientsales.com', Alias = 'cli', CommunityNickname = 'cli',
                          TimeZoneSidKey = 'Europe/Paris', LocaleSidKey = 'es', EmailEncodingKey = 'UTF-8', ProfileId = p.Id,
                          LanguageLocaleKey = 'es', ER_Business_Unit__c = 'ES');
        insert u;
        System.runAs(u){
            Lead ld = new Lead(
                ER_Store_Name__c = 'Store',
				Salutation = 'Mr.',
                LastName ='last',
                FirstName ='first',
            	RecordTypeId = recordTypeMap.get('Lead').get('ER_Merchant_Lead_RT').Id,
            	ER_VAT_Number__c = '234567891',
                Company = 'Edenred ticket',
                Email = 'test@salesforce.com',
                Street = '178, boulevard Gabriel Péri ',
            	City = 'Malakoff',
                ER_Terminal__c = 'Yes',
                PostalCode = '92240',
                ER_Language__c = 'EN',
                ER_MID_Clearing__c = '500',
                ER_Sub_MID_Clearing__c = '501',
            	ER_Sub_MID_Authorization__c = '3',
            	ER_MID_Authorization__c = '4');
            insert ld;
        }
	}

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
    
    
    static testMethod void TestLeadAfterUpdate() {
            
            // Test data setup
            init();
        
            Test.startTest();
        
        	Database.LeadConvert lc = new database.LeadConvert();
        	lc.setLeadId(merchantLeadList[0].Id);
        
        	LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);
        
			Database.LeadConvertResult lcr = Database.convertLead(lc);
    
            Test.stopTest();
            
            // Check the results (assert)
            System.assert(lcr.isSuccess());
        
        	List<ER_Financial_Center__c> result = [Select id from ER_Financial_Center__c];
            System.assertEquals(1, result.size(), 'the related financial center had been successfully created');
        
        	List<ER_Store__c> result1 = [Select id, ER_Financial_Center__c from ER_Store__c];
            System.assertEquals(1, result1.size(), 'the related store had been successfully created');
        }
    
    static testMethod void testUnmatchTransactionAfterUpdate(){

         recordTypeMap = getRecordTypesBySObject(new List<String>{
                'Lead'
            });
        Test.startTest();
        Account a = APER07_UtilityTestMethod.getCompany('Test');
        insert a;
        ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter('Test',a.id,'Merchant','Test','Test','3000','Spain');
        insert fc;

        ER_Store__c store = APER07_UtilityTestMethod.getStore('TEST', a.Id,fc.Id,System.today(),'test','test','test','test');
        insert store;

        ER_Acceptor__c acceptor = APER07_UtilityTestMethod.getAcceptor(store.Id);
        insert acceptor;
        
        Lead ld = APER07_UtilityTestMethod.getLead(recordTypeMap.get('Lead').get('ER_Merchant_Lead_RT').Id);
        insert ld;

       
        ld.ER_MID_Clearing__c = '220';
        update ld;
        
        ld.ER_Sub_MID_Clearing__c = '221';
        update ld;
        
        ld.Status = Label.LABS_SF_Status_Lead_Excluded;
        ld.ER_Rejected_Reason__c = Label.LAB_SF_Lead_Rejected_Interest;
        update ld;
        Test.stopTest();
    }
    */
}