@isTest
public class GenericWithoutSharingTest {
    
    @testSetup
  static void testSetup() {
    

      Account accountObj = APER07_UtilityTestMethod.getCompany('test account');
      accountObj.ER_Registration_Number__c = '00000001-1-02';
      insert accountObj;
      
      ER_Financial_Center__c fc = APER07_UtilityTestMethod.getFinancialCenter('test',accountObj.Id,'Merchant','test','test','test','test');
      insert fc;
      
      ER_Bank_Account__c ba = APER07_UtilityTestMethod.getBankAccount(fc.Id, 'test','Open','test','test','test');
      insert ba;
      
      ER_Store__c store = APER07_UtilityTestMethod.getStore('test',accountObj.Id, fc.Id, System.today(), 'test','test','test','test');
      insert store;
      
      ER_Acceptor__c accep = APER07_UtilityTestMethod.getAcceptor(store.Id,'test','10000000000','10000000000');
      insert accep;
      
      String json = '{"leadId": "","countryCode": "BE","solution": "TRE","enterpriseNb": "","fiscalId": "","country": "BE","company": "Test","scope": "","enterpriseVATCode": "01234567","legalName": "Test","address": "Test","postalCode": "123456","city": "BE","salutation": "Mr","firstName": "Test","lastName": "Test","lang": "FR","phone": "8525414745","mobile": "9696969696","role": "","email": "test@test.com","fax": "","ovtCode": "","ovtOperator": ""}';
      try{
      	GenericWithoutSharing.upsertLead(json,'123');
      }catch(Exception ex){
          
      }

  }
    
    @IsTest
    static void getCompanyInfos() {
        Test.startTest();
        
        GenericWithoutSharing.getCompanyInfos('00000001-1-02');
        Test.stopTest();
    }
    
    @IsTest
    static void getFinCentersInfosByCRN() {
        Test.startTest();
            GenericWithoutSharing.getFinCentersInfosByCRN('00000001-1-02');
        Test.stopTest();
    }
    
    @IsTest
    static void getStoresInfos() {
                List<Account> acc = [SELECT Id from Account limit 1];

        Test.startTest();
        if(!acc.isEmpty()){
            GenericWithoutSharing.getStoresInfos(acc[0].Id, 'test');
            GenericWithoutSharing.checkExistingAcceptor('mid','10000000000','10000000000');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void checkStoreNameDuplicate() {
		List<ER_Store__c> store = [SELECT Id from ER_Store__c limit 1];
        Test.startTest();
        GenericWithoutSharing.checkStoreNameDuplicate('test','BE');
        GenericWithoutSharing.getAccountIdFromCRN('00000001-1-02');
        if(!store.isEmpty()){
            GenericWithoutSharing.createStore(store[0].Id,'test','test');
            GenericWithoutSharing.getStoreRecord(store[0].Id);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void updateAccount() {
		Lead leadObj = [SELECT Id from Lead LIMIT 1];
        Account acc = [SELECT Id from Account LIMIT 1];
		String json = '{"countryCode": "BE","accountId": "' + acc.Id + '","leadId": "' + leadObj.Id + '","contactId": null,"salutation": "Mr","firstName": "Test","lastName": "Test","mobile": "9696969696","email": "test@test.com","contactPhone": "","fax": "","lang": "FR","role":"","company":"Test","phone":"9696969696","legalName":"Test","address":"test","postalCode":"123456","fiscalId":"","country":"BE","city":"Test"}';
        Test.startTest();
        	GenericWithoutSharing.updateAccount(json);
       
        Test.stopTest();
    }

}