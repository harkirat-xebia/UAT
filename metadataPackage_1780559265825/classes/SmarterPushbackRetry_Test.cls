/**
 * @author: AAZ
 * @date: 03/08/2023
 * @desc: Test class for SmarterPushbackRetry
 * @see: SmarterPushbackRetry
 */
@IsTest
public class SmarterPushbackRetry_Test {
    
    @IsTest
    static void doPost() {
        
        Account newClient = APER07_UtilityTestMethod.getCompany('newFrCompany' + Datetime.now().getTime());
        insert newClient;
        
        Lead ld1 = new Lead();
        ld1.ER_Store_Name__c = 'my store2';
        ld1.Salutation = 'Mr.2';
        ld1.LastName = 'lastname2';
        ld1.FirstName = 'firstname2';
        ld1.Status = 'New';
        ld1.RecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT);
        ld1.ER_VAT_Number__c = Utils.generateUniqueString(Constants.TYPE_INTEGER, 10);
        ld1.Company = Utils.generateUniqueString(Constants.TYPE_STRING, 30);
        ld1.Email = Utils.generateUniqueString(Constants.TYPE_STRING, 10) + '@mailinator.com';
        ld1.Street = '172, boulevard Gabriel Péri ';
        ld1.City = 'Malakoff2';
        ld1.PostalCode = '92242';
        ld1.ER_Language__c = 'EN';
        ld1.ER_MID_Clearing__c = '402';
        ld1.ER_Sub_MID_Clearing__c = '402';
        ld1.IsConverted = true;
        ld1.ConvertedAccountId = newClient.Id;
        ld1.ER_SmartER_Context__c = true; 
        ld1.NumberOfEmployees = 35;
        insert ld1;
        
        List<SmarterPushbackRetry.SmarterPushbackRetryRequest> records = new List<SmarterPushbackRetry.SmarterPushbackRetryRequest>();
        SmarterPushbackRetry.SmarterPushbackRetryRequest rec = new SmarterPushbackRetry.SmarterPushbackRetryRequest();
        rec.oneforceLeadId = ld1.Id;
        records.add(rec);
        
        Test.startTest();
        	SmarterAPIMock smarterMock = new SmarterAPIMock();
            Test.setMock(HttpCalloutMock.class, smarterMock);
        
        	SmarterPushbackRetry.SmarterPushbackRetryResponse response = SmarterPushbackRetry.doPost(records);
        	System.debug('>>>>> AAZ - response : ' + response);
        
        	System.AssertEquals(200, response.statusCode);
        Test.stopTest();
    }

}