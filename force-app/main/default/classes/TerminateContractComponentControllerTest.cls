@isTest
public with sharing class TerminateContractComponentControllerTest {
    @TestSetup
    static void testSetup() {
        // Create and insert test user
        User ur = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'BE');
        ur.ER_BypassVR__c = true;
        ur.ER_bypassTrigger__c = true;
        insert ur;

        System.runAs(ur) {
            // Validation Rule Settings
            ER_Validation_Rules_Settings__c settings = ER_Validation_Rules_Settings__c.getInstance(
                UserInfo.getOrganizationId()
            );
            settings.VRER07_Prevent_Selecting_Std_Pricebook__c = true;
            upsert settings;

            // Create Client Account
            Account newClientAccount = APER07_UtilityTestMethod.insertAccount('clientCompany', 'ER_Company_Account_RT');
            
            // Price Books and Contracts
            PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
            PriceBook2 customPB = APER07_UtilityTestMethod.getCustomPriceBook(Label.LAB_SF_P2_EKIVITA_PRICEBOOK);
            insert customPB;

            Contract frameworkContract = APER07_UtilityTestMethod.insertContract(
                newClientAccount.Id,
                System.today(),
                Label.LABS_SF_Contract_Status_Draft,
                customPB.Id,
                'ER_Client_Contract_RT',
                ur.Id
            );

            // Products and Price Book Entries
            Product2 newSolution = APER07_UtilityTestMethod.getsolution('testSolution');
            insert newSolution;

            Product2 newService = APER07_UtilityTestMethod.getservice('testService', newSolution.id);
            insert newService;

            PriceBookEntry newPriceBookEntry = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.id, newService.id);
            insert newPriceBookEntry;

            // Contract Line Item
            ER_ContractLineItem__c newContractLine = APER07_UtilityTestMethod.getContractLineItem(
                frameworkContract.Id,
                newService.id,
                newPriceBookEntry.Id,
                1,
                1
            );
            insert newContractLine;

            // Client Opportunity and Quote
            Opportunity clientOpp = APER07_UtilityTestMethod.getOpportunity('ER_Client_Opportunity_RT', 'APER12_Client_Test');
            clientOpp.AccountId = newClientAccount.Id;
            clientOpp.Pricebook2Id = newPriceBook.Id;
            clientOpp.ER_AmendedFromContract__c = frameworkContract.Id;
            insert clientOpp;

            OpportunityLineItem clientOli = APER07_UtilityTestMethod.getOpportunityLineItem(
                clientOpp.id,
                newPriceBookEntry.id
            );
            insert clientOli;

            Quote clientQuote = APER07_UtilityTestMethod.getQuote(
                'ER_Client_Quote',
                'APER12_Client_Test',
                clientOpp.id,
                newPriceBook.id
            );
            clientQuote.ER_Quote_Type__c = Label.LAB_SF_Contact_Operational;
            insert clientQuote;

            QuoteLineItem clientQli = APER07_UtilityTestMethod.getQuoteLineItem(clientQuote.id, newPriceBookEntry.id);
            clientQli.ER_Line_Type__c = 'Discount';
            clientQli.ER_Duration__c = 90;
            insert clientQli;
        }
    }
    @isTest
    static void testsetStatusPendingTermination() {
        Test.startTest();
        
        // Retrieve a contract to test
        Contract testContract = [SELECT Id, Account.ER_Card_Client_Operational_System_ID__c FROM Contract LIMIT 1];
        
        // Invoke the activateContract method
        try{
            TerminateContractComponentController.setStatusPendingTermination(testContract.Id);
        } catch(Exception err){
            
        }
        
        Test.stopTest();
    }
    @isTest
    static void testTerminateContract() {
        Test.startTest();
        
        // Retrieve a contract to test
        Contract testContract = [SELECT Id, Account.ER_Card_Client_Operational_System_ID__c FROM Contract LIMIT 1];
        
        // Invoke the activateContract method
        try{
            Map<String, Object> response = TerminateContractComponentController.terminateContract(testContract.Id, 'Not Interested anymore', null, Date.Today());
        } catch(Exception err){
            
        }
        
        Test.stopTest();
    }
    @isTest
    static void testcheckErrors() {
        Test.startTest();
        
        // Retrieve a contract to test
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        // Invoke the updateContractStatus method
        TerminateContractComponentController.checkErrors(testContract.Id);
        
        // Verify the contract status
        Contract updatedContract = [SELECT Status FROM Contract WHERE Id = :testContract.Id];
        
        Test.stopTest();
    }
}