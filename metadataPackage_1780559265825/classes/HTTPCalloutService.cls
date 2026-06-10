/*
----------------------------------------------------------------------
-- - Name          : HTTPCalloutService 
-- - Author        : Snehil Verma
-- - Description   : Http Callout Framework
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Nov-2024     Snehil Verma        1.0         Initial version
---------------------------------------------------------------------------------------
*/
public without sharing class HTTPCalloutService {
    
    Id accountId, contractId;
    HTTPCalloutConfiguration__mdt calloutMetadata;
    String endpointURL, requestMethod, apiRequestBody;
    String requestBody, responseBody = null;
    Blob requestBodyAsBlob;Boolean ilFlag = true;
    Dom.Document requestBodyAsDocument;
    Integer requestTimeout;
    Map<String, String> urlParametersMap;
    Map<String, String> headerParametersMap;
    static final String TYPE_URL_PARAMETERS = 'URL_PARAMETERS';
    static final String TYPE_HEADER_PARAMETERS = 'HEADER_PARAMETERS';
    HTTPRequest request;
    
    /*
    * Getters and Setters - Begin
    */
    public String getEndpointURL() {
        return endpointURL;
    }
    
    public void setEndpointURL(String endpointURL) {
        this.endpointURL = endpointURL;
    }
    
    public void setILFlag(Boolean flag) {
        this.ilFlag = flag;
    }
    
    public String getRequestMethod() {
        return requestMethod;
    }
    
    public void setRequestMethod(String requestMethod) {
        this.requestMethod = requestMethod;
    }
    
    public String getRequestBody() {
        return requestBody;
    }
    
    public void setRequestBody(String requestBody) {
        this.requestBody = requestBody;
    }
    
    public Blob getRequestBodyAsBlob() {
        return requestBodyAsBlob;
    }
    
    public void setRequestBodyAsBlob(Blob requestBodyAsBlob) {
        this.requestBodyAsBlob = requestBodyAsBlob;
    }
    
    public Dom.Document getRequestBodyAsDocument() {
        return requestBodyAsDocument;
    }
    
    public void setRequestBodyAsDocument(Dom.Document requestBodyAsDocument) {
        this.requestBodyAsDocument = requestBodyAsDocument;
    }
    
    public Integer getRequestTimeout() {
        return requestTimeout;
    }
    
    public void setRequestTimeout(Integer requestTimeout) {
        this.requestTimeout = requestTimeout;
    }
    
    public String getHeaderParameter(String key) {
        return headerParametersMap.get(key);
    }
    
    public Map<String, String> getHeaderParameters() {
        return headerParametersMap;
    }
    
    public void setHeaderParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            headerParametersMap.put(key, value);
        }
    }
    
    public void removeHeaderParameter(String key) {
        headerParametersMap.remove(key);
    }
    
    public String getURLParameter(String key) {
        return urlParametersMap.get(key);
    }
    
    public Map<String, String> getURLParameters() {
        return urlParametersMap;
    }
    
    public void setURLParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            urlParametersMap.put(key, value);
        } else if(String.isNotEmpty(key)) {
            urlParametersMap.put(key, value);
        }
    }
    
    public void removeURLParameter(String key) {
        urlParametersMap.remove(key);
    }
    
    public void setAccountId(Id accountId){
        this.accountId = accountId;
    }
    
    public void setContractId(Id contractId){
        this.contractId = contractId;
    }
     
    /*
    * Constructor with Custom Metadata
    */
    public HTTPCalloutService(String customMetadataName, String requestBody) {
        if(String.isNotEmpty(requestBody)){
            apiRequestBody = requestBody;
        }
        
        try {
            calloutMetadata = HTTPCalloutConfiguration__mdt.getInstance(customMetadataName);
            
        } catch (Exception e) {
            System.debug('Err msg'+e.getMessage());
        }
        initialize();
    }
    
    public HTTPCalloutService(String customMetadataName) {
        try {
            calloutMetadata = HTTPCalloutConfiguration__mdt.getInstance(customMetadataName);
            
        } catch (Exception e) {
            System.debug('Err msg'+e.getMessage());
        }
        initialize();
    }
    
    /*
    * Initialization of class variables
    */
    private void initialize() {
        urlParametersMap = new Map<String, String>();
        headerParametersMap = new Map<String, String>();
        if(calloutMetadata != null) {
            endpointURL = calloutMetadata.Endpoint__c;
            requestMethod = calloutMetadata.Method__c;
            requestBody = apiRequestBody;
            requestTimeout = Integer.valueOf(calloutMetadata.Timeout__c);
            setUrlOrHeaderParameters(TYPE_URL_PARAMETERS, calloutMetadata.URLParameters__c);
            setUrlOrHeaderParameters(TYPE_HEADER_PARAMETERS, calloutMetadata.HeaderParameters__c);
        }
    }
    
    /*
    * This method is used to set URL or Header parameters from Custom Metadata
    */
    private void setUrlOrHeaderParameters(String parameterType, String parameterInfo) {
        if(String.isNotEmpty(parameterInfo)) {
            Map<String, String> parametersMap = new Map<String, String>();
            List<String> parameters = parameterInfo.split('\n');
            for(String urlParam : parameters) {
                List<String> keyValuePair = urlParam.trim().split(':');
                if(!keyValuePair.isEmpty()) {
                    if(keyValuePair.size() == 2) {
                        if(String.isNotEmpty(keyValuePair[0]) && String.isNotEmpty(keyValuePair[1])) {
                            parametersMap.put(keyValuePair[0], keyValuePair[1]);
                        }
                    } else if(
                        (keyValuePair.size() == 1) &&
                        (parameterType != TYPE_HEADER_PARAMETERS)
                    ) {
                        if(String.isNotEmpty(keyValuePair[0])) {
                            parametersMap.put(keyValuePair[0], '');
                        }
                    }
                }
            }
            if(parameterType == TYPE_URL_PARAMETERS) {
                urlParametersMap.putAll(parametersMap);
            } else if(parameterType == TYPE_HEADER_PARAMETERS) {
                headerParametersMap.putAll(parametersMap);
            }
        }
    }
    
    /*
    * This method is used to append the URL parameters at the end of URL
    */
    private void appendURLParameters() {
        Set<String> urlParamKeys = urlParametersMap.keySet();
        if(!urlParamKeys.isEmpty()) {
            endpointURL += '?';
            for(String urlParamKey : urlParamKeys) {
                endpointURL += urlParamKey + '=' + urlParametersMap.get(urlParamKey) + '&';
            }
            endpointURL = endpointURL.substringBeforeLast('&');
        }
    }
    
    /*
    * This method is used to set Header parameters using headerParametersMap
    */	
    private void addHeaderParameters() {
        for(String key : headerParametersMap.keySet()) {
            request.setHeader(key, headerParametersMap.get(key));
        }
    }
    
    /*
    * This method is used to form HTTP Request
    */
    private void formHTTPRequest() {
        request = new HTTPRequest();
        addHeaderParameters();
        if(String.isNotEmpty(endpointURL)) {
            endpointURL = endpointURL.substringBefore('?');
            appendURLParameters();
            request.setEndpoint(endpointURL);
        }
        if(String.isNotEmpty(requestMethod)) {
            request.setMethod(requestMethod);
        }
        if(String.isNotEmpty(requestBody)) {
            request.setBody(requestBody);
        } else if((requestBodyAsBlob != null) &&  String.isNotEmpty(requestBodyAsBlob.toString())) {
            request.setBodyAsBlob(requestBodyAsBlob);
        } else if((requestBodyAsDocument != null) && String.isNotEmpty(requestBodyAsDocument.toXmlString())) {
            request.setBodyDocument(requestBodyAsDocument);
        }
        if(requestTimeout!=null) {
            request.setTimeout(requestTimeout);
        }
    }
    
    /*
    * This method forms and returns the HTTP Request without sending (for debugging purposes)
    */
    public HTTPRequest getRequest() {
        formHTTPRequest();
        return request;
    }
    
    /*
    * This method is used to send HTTP Request and return the response
    */
    public HTTPResponse sendRequest() {
        formHTTPRequest();
        Http http = new Http();
        HTTPResponse response = http.send(request);
        System.debug('auth token'+request.getHeader('Authorization'));
        integrationLogsHandler(response);
        return response;
    }
    
    /*
    * This method is used to send HTTP Request received in parameter and return the response
    */
    public HTTPResponse sendRequest(HTTPRequest request) {
        Http http = new Http();
        HTTPResponse response = http.send(request);
        integrationLogsHandler(response);
        return response;
    }
    
    public Integration_Log__c integrationLogsHandler(HTTPResponse response){
        Integer maxLength = 131072;
        responseBody = response.getBody();
        
        Integration_Log__c ilObj = new Integration_Log__c();
        if (requestBody != null){
            if(requestBody.length() > maxLength) {
                ilObj.Request_Body__c = requestBody.substring(0, maxLength);
            }else {
                ilObj.Request_Body__c = requestBody;
            }
        }
        if (responseBody != null){ 
            if(responseBody.length() > maxLength) {
                ilObj.Response_Body__c = responseBody.substring(0, maxLength);
            } else {
                ilObj.Response_Body__c = responseBody; 
            }
        }
        
        ilObj.Status_Message__c = response.getStatus();
        ilObj.Status_Code__c = response.getStatusCode();
        ilObj.Endpoint__c = endpointURL;
        ilObj.Method__c = requestMethod;
        if(contractId != null){
            ilObj.Record_URL__c = URL.getOrgDomainURL().toExternalForm() +'/' + contractId;
        }else{
            if(accountId != null){
                ilObj.Record_URL__c = URL.getOrgDomainURL().toExternalForm() +'/' + accountId;
            }
        }
        ilObj.Org_Domain_URL__c = URL.getOrgDomainURL().toExternalForm() +'/';
        ilObj.Status__c = response.getStatusCode() == 200 ? 'Success' : 'Error';
        if(ilFlag){
            insert ilObj;
        }
        return ilObj;
        
    }
    
}