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

    @IsTest
    static void setOpportunityToCloseWon_preservesAutoEnrollmentWonReason() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'Test AutoEnroll Opp');
        opp.AccountId = acc.Id;
        opp.ER_Won_Reason__c = 'Auto-Enrollment';
        insert opp;

        Test.startTest();
        GenericWithoutSharing.setOpportunityToCloseWon(opp.Id);
        Test.stopTest();

        Opportunity result = [SELECT StageName, ER_Won_Reason__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Label.LABS_SF_Opp_Status_ClosedWon, result.StageName, 'Stage should be Closed Won');
        System.assertEquals('Auto-Enrollment', result.ER_Won_Reason__c, 'Won Reason should be preserved, not overwritten with Other');
    }

    @IsTest
    static void setOpportunityToCloseWon_defaultsToOtherWhenWonReasonIsBlank() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = APER07_UtilityTestMethod.getOpportunity('ER_Merchant_Opportunity', 'Test Blank Won Reason Opp');
        opp.AccountId = acc.Id;
        insert opp;

        Test.startTest();
        GenericWithoutSharing.setOpportunityToCloseWon(opp.Id);
        Test.stopTest();

        Opportunity result = [SELECT StageName, ER_Won_Reason__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Label.LABS_SF_Opp_Status_ClosedWon, result.StageName, 'Stage should be Closed Won');
        System.assertEquals('Other', result.ER_Won_Reason__c, 'Won Reason should default to Other when blank');
    }

    /*@IsTest
    static void manageStatusOnContractActivation_setsAccountActive() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericWithoutSharing.manageStatusOnContractActivation(acc.Id);
        Test.stopTest();

        Account result = [SELECT ER_Status__c, ER_Inactive_Reason__c, ER_Inactive_date__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(Label.LABS_SF_Account_Status_Active, result.ER_Status__c, 'Account status should be Active');
        System.assertEquals('', result.ER_Inactive_Reason__c, 'Inactive reason should be cleared');
        System.assertEquals(null, result.ER_Inactive_date__c, 'Inactive date should be cleared');
    }*/

    @IsTest
    static void getFinCentersInfosByAccountId_returnsResults() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Map<String, String>> result = GenericWithoutSharing.getFinCentersInfos(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one financial center');
        System.assertEquals('test', result[0].get('name'), 'Financial center name should match');
    }

    @IsTest
    static void getCompanyInfos_returnsNullForBlankCRN() {
        Test.startTest();
        Map<String, String> result = GenericWithoutSharing.getCompanyInfos('');
        Test.stopTest();

        System.assertEquals(null, result, 'Blank CRN should return null');
    }

    @IsTest
    static void getFinCentersInfosByCRN_returnsNullForBlankCRN() {
        Test.startTest();
        List<Map<String, String>> result = GenericWithoutSharing.getFinCentersInfosByCRN('');
        Test.stopTest();

        System.assertEquals(null, result, 'Blank CRN should return null');
    }

    @IsTest
    static void checkExistingAcceptor_tidLookup() {
        Test.startTest();
        Boolean result = GenericWithoutSharing.checkExistingAcceptor('tid', '99999999');
        Test.stopTest();

        System.assertEquals(true, result, 'Non-existent TID should return true (no duplicate)');
    }

}