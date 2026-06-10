@isTest
public class HTTPCalloutServiceTest { 
    /*
* Initializing constants
*/
    private static final String CUSTOM_METADATA_NAME = 'NEMO_CREATE_CLIENT';
    private static final String ENDPOINT = 'https://www.test.com';
    private static final String METHOD = 'POST';
    private static final String REQUEST_BODY = '{"input":"Test Input"}';
    private static final String REQUEST_BODY_XML = '<input>Test Input</input>';
    private static final String RESPONSE_BODY = '{"output":"Test Output"}';
    private static final Integer RESPONSE_SUCCESS = 200;
    private static final Integer TIMEOUT = 120000;
    private static final Boolean ISCOMPRESSED = true;
    private static final String KEY1 = 'key1';
    private static final String KEY2 = 'key2';
    private static final String VALUE1 = 'value1';
    private static final String VALUE2 = 'value2';
    private static final String CERTIFICATE = 'Test Certificate';
    
    @testSetup static void setup() {
       
        Account acc = TestDataFactory.newAccount();
        insert acc;
        acc.BillingCountry='Belgium';
        update acc;
        String Operational_Role = Label.Operational_Role_Main_Contact_API+ ';' + Label.Operational_Role_Invoicing_Contact_API + ';' +Label.Operational_Role_Order_Contact_API + ';' + Label.Operational_Role_Delivery_Contact_API;
        Contact contact = TestDataFactory.newContact(acc);
        insert contact;
        contact.ER_Status__c = 'Active';
        contact.BE_Operational_Role__c = Operational_Role;
        contact.ER_Language__c = 'FR';
       
        update contact;
        ER_Financial_Center__c finCenter = TestDataFactory.newFinancialCenter(acc,'Client');
        insert finCenter;
        ER_Delivery_Site__c deliverySite = TestDataFactory.newDeliverySite(acc ,'Xebia',finCenter);
        insert deliverySite;
        deliverySite.ER_Country__c ='Belgium';
        update deliverySite;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        // Setup contract
        Contract contract = new Contract(
            AccountId = acc.Id,
            Name = 'Test Contract',
            Creditting__c = 'Credit 1 day',
            StartDate = System.today(),
            CustomerSignedDate = System.today(),
            ER_OpportunityId__c = opp.Id,
            Card_Replacement_Payment__c = 'Paid by beneficiary',
            ER_PaymentMethod2__c = 'Direct debit'
           // ER_BUPicklist__c = 'Belgium',
           // ER_InvoicingFrequency2__c = 'Pre order',
            //ER_Indexation_Index2__c = 'Consumer price index',
            //ER_PaymentTerms2__c = 'At reception of invoice'
        );
        insert contract;
        PriceBook2 newPriceBook = APER07_UtilityTestMethod.getpriceBook();
        Product2 newSolution1 = APER07_UtilityTestMethod.insertProduct2(
        'testSolution1',
        'BE',
        'EDPO_TR_APM_PLN',
        'Solution',
        null
      );
      Product2 newService1 = APER07_UtilityTestMethod.insertProduct2(
        'testService1',
        'BE',
        null,
        'service',
        newSolution1.Id
      );
      PriceBookEntry newPriceBookEntry1 = APER07_UtilityTestMethod.getpriceBookEntry(newPriceBook.Id, newService1.id);
      insert newPriceBookEntry1;
                
        ER_ContractLineItem__c cli = new ER_ContractLineItem__c(
            Name = 'CLI Test',
            ER_Contract__c = contract.Id,
            ER_Product2__c = newService1.Id,
            ER_Percentage__c = 50,
            ER_Quantity__c = 5,
            ER_Minimum_Fee__c = 100,
            ER_UnitPrice__c = 200,
            ER_ListPrice__c = 250,
            ER_Line_Type__c = 'Discount'
        );
        insert cli;
        
        ER_Distribution_Point__c distPoint = TestDataFactory.newDistributionPoint('test',deliverySite.Id);
        insert distPoint;
        distPoint.ER_Country__c ='Belgium';
        update distPoint;
        
    } 
    
    // Mock class for HTTP callout
    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Success"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testSendRequestSuccess() {
        // Set up the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        // Create an instance of HTTPCalloutService
        String metadataName = 'NEMO_CREATE_CLIENT';
        String requestBody = '{"key": "value"}';
        HTTPCalloutService service = new HTTPCalloutService(metadataName, requestBody);
        
        // Set additional parameters
        service.setEndpointURL('https://example.com/api');
        service.setRequestMethod('POST');
        service.setHeaderParameter('Authorization', 'Bearer test_token');
        service.setRequestTimeout(5000);
        
        // Send the request
         Test.startTest();
        HTTPResponse response = service.sendRequest();
         Test.stopTest();
        
        // Assertions
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals('{"message": "Success"}', response.getBody(), 'Response body should match the mock response');
    }
    
    @isTest
    static void testSendRequestWithParameterSuccess() {
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        // Define metadata and request body
        String metadataName = 'NEMO_CREATE_CLIENT';
        String requestBody = '{"key": "value"}';
        
        // Create an instance of HTTPCalloutService
        HTTPCalloutService service = new HTTPCalloutService(metadataName, requestBody);
        
        // Set additional parameters
        service.setEndpointURL('https://example.com/api');
        service.setRequestMethod('POST');
        service.setHeaderParameter('Authorization', 'Bearer test_token');
        service.setRequestTimeout(5000);
        
        // Create the HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://example.com/api');
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer mock_token');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000);
        request.setBody('{"key": "value"}');
        
        // Call the sendRequest method and store the response
        Test.startTest();
        HttpResponse response = service.sendRequest(request);
        Test.stopTest();
        
        // Validate the response
        System.assertEquals(200, response.getStatusCode(), 'Response status code should be 200');
        System.assertEquals('{"message": "Success"}', response.getBody(), 'Response body should match the mock response');
    }
    
    
    @isTest
    static void testIntegrationLogInsertion() {
        // Set up the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        // Create an instance of HTTPCalloutService
        String metadataName = 'NEMO_CREATE_CLIENT';
        String requestBody = '{"key": "value"}';
        HTTPCalloutService service = new HTTPCalloutService(metadataName, requestBody);
        
        // Set additional parameters
        service.setEndpointURL('https://example.com/api');
        service.setRequestMethod('POST');
        service.setHeaderParameter('Authorization', 'Bearer test_token');
        service.setRequestTimeout(5000);
       
         Test.startTest();
        service.sendRequest();
         Test.stopTest();
        
    }
    
    @isTest
    static void testGetRequestMethod() {
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        // Create an instance of HTTPCalloutService with metadata only
        String metadataName = 'NEMO_CREATE_CLIENT';
        HTTPCalloutService service = new HTTPCalloutService(metadataName,testContract.Id);
        
        // Set and retrieve request method
        service.setRequestMethod('GET');
        
        // Assertions
        System.assertEquals('GET', service.getRequestMethod(), 'Request method should be GET');
    }
    
    @isTest
    static void testUrlParameters() {
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        HTTPCalloutService service = new HTTPCalloutService('NEMO_CREATE_CLIENT',testContract.Id);
        
        // Set URL parameters
        service.setURLParameter('param1', 'value1');
        service.setURLParameter('param2', 'value2');
        
        // Check that parameters were set correctly
        System.assertEquals('value1', service.getURLParameter('param1'), 'URL parameter param1 should be value1');
        System.assertEquals('value2', service.getURLParameter('param2'), 'URL parameter param2 should be value2');
    }
    
    @isTest
    static void testHeaderParameters() {
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        HTTPCalloutService service = new HTTPCalloutService('NEMO_CREATE_CLIENT',testContract.Id);
        
        // Set Header parameters
        service.setHeaderParameter('Content-Type', 'application/json');
        service.setHeaderParameter('Authorization', 'Bearer test_token');
        
        // Check that header parameters were set correctly
        System.assertEquals('application/json', service.getHeaderParameter('Content-Type'), 'Content-Type should be application/json');
        System.assertEquals('Bearer test_token', service.getHeaderParameter('Authorization'), 'Authorization header should be correct');
    }
    
    @isTest
    static void testGetRequestBody() {
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        // Arrange: Define test data
        String metadataName = 'NEMO_CREATE_CLIENT';
        String requestBody = '{"key": "value"}';
        Blob requestBodyBlob = Blob.valueOf(requestBody);
        // Create an instance of the HTTPCalloutService class
        HTTPCalloutService service = new HTTPCalloutService(metadataName, requestBody);
        
        // Act: Call the getRequestBody method
        String actualRequestBody = service.getRequestBody();
        service.setRequestBody(requestBody);
        service.getRequestBodyAsBlob();
        service.setRequestBodyAsBlob(requestBodyBlob);
        service.getRequestBodyAsDocument();
        service.getRequestTimeout();
        service.setRequestTimeout(1000);
        service.getHeaderParameter('test');
        service.getHeaderParameters();
        service.setILFlag(true);
        service.removeHeaderParameter('test');
        service.getURLParameters();
        service.removeURLParameter('test');
        // Assert: Verify the request body is returned as expected
        System.assertEquals(requestBody, actualRequestBody, 'The request body should match the initialized value.');
    }
    
    
    
}