@RestResource(urlMapping='/nemo/v1/contract-amendments')
global without sharing class NEMO_ContractAmendmentRest {

    global class RequestDTO {
        public String requestId;
        public String contractId;
        public String opportunityId;
        public List<NEMO_ContractAmendmentTypes.ChangeDTO> changes;
    }

    /*global class ChangeDTO {
        public String action; // "UPDATE" (default) or "ADD"
        public MatchDTO match;
        public UpdatesDTO updates;
    }*/

    /*global class MatchDTO {
        public String cliId;      // ER_ContractLineItem__c Id (optional)
        public String product2Id; // Product2 Id (optional)
        public String productCode; // optional if you want to implement mapping
    }*/

    /*global class UpdatesDTO {
        public Decimal quantity;
        public Decimal unitPrice;
        public Decimal discount;
        public Decimal percentage;
        public Decimal min;
        public Decimal max;
        public String lineType;
        public Date offerValidityEndDate;
        public Decimal mpv;
        public Decimal edenredMarginTur;
        public Boolean freeToSetMargin;
        public Boolean cumulativeWithPromotions;
    }*/

    global class ResponseDTO {
        public String status; // SUCCESS | ERROR
        public String requestId;

        public String amendedFromContractId;
        public String amendmentOpportunityId;

        public List<String> updatedLineItemIds = new List<String>();
        public List<String> createdLineItemIds = new List<String>();

        public String errorCode;
        public String message;
        public Map<String, Object> details;
    }

    @HttpPost
global static void amend() {
    ResponseDTO resp = new ResponseDTO();
    Integration_Log__c il;

    try {
        // 1) Access control
        if (!FeatureManagement.checkPermission('NEMO_AMEND_API')) {
            sendJson(403, error(resp, 'PERMISSION_DENIED', 'Missing permission: NEMO_AMEND_API', null));
            return;
        }

        // 2) Parse request
        String raw = (RestContext.request.requestBody == null) ? null : RestContext.request.requestBody.toString();
        if (String.isBlank(raw)) {
            sendJson(400, error(resp, 'INVALID_REQUEST', 'Empty body', null));
            return;
        }

        RequestDTO dto;
        try {
            dto = (RequestDTO) JSON.deserialize(raw, RequestDTO.class);
        } catch (Exception parseEx) {
            sendJson(400, error(resp, 'INVALID_REQUEST', 'Invalid JSON: ' + parseEx.getMessage(), null));
            return;
        }

        // 3) Validate required fields
        if (dto == null) {
            sendJson(400, error(resp, 'INVALID_REQUEST', 'Request is null after parsing', null));
            return;
        }
        if (String.isBlank(dto.requestId)) {
            sendJson(400, error(resp, 'INVALID_REQUEST', 'requestId is required', null));
            return;
        }
        if (String.isBlank(dto.contractId)) {
            sendJson(400, error(resp, 'INVALID_REQUEST', 'contractId is required', null));
            return;
        }
        //Adding new
        resp.requestId = dto.requestId;
		resp.amendedFromContractId = dto.contractId;
        // 3c) Idempotency: if requestId already processed successfully, return stored response
        List<Integration_Log__c> existingLogs = [
            SELECT Id, Status__c, Response_Body__c
            FROM Integration_Log__c
            WHERE Correlation_Id__c = :dto.requestId
            LIMIT 1
        ];
        
        if (!existingLogs.isEmpty() && existingLogs[0].Status__c == 'Success' && String.isNotBlank(existingLogs[0].Response_Body__c)) {
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(existingLogs[0].Response_Body__c);
            return;
        }
        //Adding new
        /*if (!existingLogs.isEmpty() && existingLogs[0].Status__c != 'Success') {
            ResponseDTO err = error(resp, 'DUPLICATE_REQUEST_ID',
                'requestId already exists but previous attempt did not succeed. Use a new requestId or check logs.', null);
            sendJson(409, err);
            return;
        }*/
        if (!existingLogs.isEmpty() && existingLogs[0].Status__c != 'Success') {
            ResponseDTO err = error(
                resp,
                'DUPLICATE_REQUEST_ID',
                'requestId already exists but previous attempt did not succeed. Use a new requestId or check logs.',
                new Map<String, Object>{ 'requestId' => dto.requestId }
            );
        
            // Update the existing Integration Log for auditability
            try {
                Integration_Log__c existing = existingLogs[0];
                existing.Status_Code__c = 409;
                existing.Status_Message__c = 'DUPLICATE_REQUEST_ID';
                existing.Response_Body__c = JSON.serialize(err);
                update existing;
            } catch (Exception ignore) {
                // Don't block the API response if logging update fails
            }
        
            sendJson(409, err);
            return;
        }
        
        // Create and INSERT Integration Log early so failures are auditable
            il = new Integration_Log__c();
            il.Correlation_Id__c = dto.requestId;
            il.Endpoint__c = getThisEndpointUrl();
            il.Method__c = 'POST';
            il.Org_Domain_URL__c = URL.getOrgDomainUrl().toExternalForm() + '/';
            il.Record_URL__c = URL.getOrgDomainUrl().toExternalForm() + '/' + dto.contractId;
            il.Request_Body__c = raw;
            
            // Since Status__c has only Success/Error, start as Error + STARTED, overwrite on success
            il.Status__c = 'Error';
            il.Status_Code__c = 0;
            il.Status_Message__c = 'STARTED';
            
            insert il;
            
            // Now continue validations
            try {
                if (!isContractActive((Id)dto.contractId)) {
                    ResponseDTO err = error(resp, 'CONTRACT_NOT_ACTIVE',
                        'Contract must be Activated to amend.', new Map<String, Object>{ 'contractId' => dto.contractId });
            
                    il.Status__c = 'Error';
                    il.Status_Code__c = 400;
                    il.Status_Message__c = 'CONTRACT_NOT_ACTIVE';
                    il.Response_Body__c = JSON.serialize(err);
                    update il;
            
                    sendJson(400, err);
                    return;
                }
            } catch (QueryException qe) {
                ResponseDTO err = error(resp, 'CONTRACT_NOT_FOUND',
                    'Contract not found.', new Map<String, Object>{ 'contractId' => dto.contractId });
            
                il.Status__c = 'Error';
                il.Status_Code__c = 404;
                il.Status_Message__c = 'CONTRACT_NOT_FOUND';
                il.Response_Body__c = JSON.serialize(err);
                update il;
            
                sendJson(404, err);
                return;
            }
            
            if (dto.changes == null || dto.changes.isEmpty()) {
                ResponseDTO err = error(resp, 'INVALID_REQUEST', 'changes[] is required', null);
            
                il.Status__c = 'Error';
                il.Status_Code__c = 400;
                il.Status_Message__c = 'INVALID_REQUEST';
                il.Response_Body__c = JSON.serialize(err);
                update il;
            
                sendJson(400, err);
                return;
            }

        // 4) (Optional) Idempotency check goes here if you have Integration_Request__c
        // If found: sendJson(200, previousResp); return;

        // 5) Execute existing amendment logic (same as UI button)
        Opportunity newOpp;
        
        //New code for integration logs
        // 3d) Create Integration Log (auditable)
        /*
        il.Correlation_Id__c = dto.requestId;
        il.Endpoint__c = getThisEndpointUrl(); // or hardcode URL.getOrgDomainUrl() + '/services/apexrest/...'
        il.Method__c = 'POST';
        il.Org_Domain_URL__c = URL.getOrgDomainUrl().toExternalForm() + '/';
        il.Record_URL__c = URL.getOrgDomainUrl().toExternalForm() + '/' + dto.contractId;
        il.Request_Body__c = raw;
        
        // If you have "In Progress" in Status__c picklist, use it; otherwise use a valid value and update later
        //il.Status__c = 'In Progress';
        il.Status__c = 'Error'; //will be overwritten to Success later
        il.Status_Code__c = 0;
        il.Status_Message__c = 'STARTED';
		*/
        try {
            //newOpp = APER04_Opportunity_Management.createOpportunityFromContract(dto.contractId, dto.opportunityId);
            newOpp = APER04_Opportunity_Management.createOpportunityFromContract_Rest(dto.contractId, dto.opportunityId);
        } catch (Exception amendEx) {
            ResponseDTO err = error(resp, 'AMENDMENT_FAILED', amendEx.getMessage(), new Map<String, Object>{
                'contractId' => dto.contractId,
                'opportunityId' => dto.opportunityId
            });
            il.Status__c = 'Error';
            il.Status_Code__c = 400;
            il.Status_Message__c = 'AMENDMENT_FAILED';
            il.Response_Body__c = JSON.serialize(err);
            update il;
            
            sendJson(400, err);
            return;
        }

        if (newOpp == null || newOpp.Id == null) {
    ResponseDTO err = error(resp, 'AMENDMENT_FAILED', 'Amendment Opportunity was not created.', new Map<String, Object>{
        'contractId' => dto.contractId,
        'opportunityId' => dto.opportunityId
    });
    il.Status__c = 'Error';
    il.Status_Code__c = 500;
    il.Status_Message__c = 'AMENDMENT_FAILED';
    il.Response_Body__c = JSON.serialize(err);
    update il;

    sendJson(500, err);
    return;
}

        resp.amendmentOpportunityId = newOpp.Id;

        // 6) Apply line changes to the new opportunity
        NEMO_ContractAmendmentTypes.ApplyResult ar;
        try {
            ar = NEMO_ContractAmendmentService.applyLineChanges(dto.contractId, newOpp.Id, dto.changes);
        } catch (Exception lineEx) {
            ResponseDTO err = error(resp, 'LINE_UPDATE_FAILED', lineEx.getMessage(), new Map<String, Object>{
                'amendmentOpportunityId' => newOpp.Id
            });
            il.Status__c = 'Error';
            il.Status_Code__c = 400;
            il.Status_Message__c = 'LINE_UPDATE_FAILED';
            il.Response_Body__c = JSON.serialize(err);
            update il;
        
            sendJson(400, err);
            return;
        }

        if (ar != null) {
            if (ar.updatedLineItemIds != null) resp.updatedLineItemIds.addAll(ar.updatedLineItemIds);
            if (ar.createdLineItemIds != null) resp.createdLineItemIds.addAll(ar.createdLineItemIds);
        }

        // 7) Success
        resp.status = 'SUCCESS';
        resp.message = 'Amendment opportunity created and line changes applied.';
        
        //For IL
        // Update integration log on success
        il.Status__c = 'Success';
        il.Status_Code__c = 200;
        il.Status_Message__c = 'OK';
        il.Response_Body__c = JSON.serialize(resp);
        il.Record_URL__c = URL.getOrgDomainUrl().toExternalForm() + '/' + resp.amendmentOpportunityId;
        update il;
        sendJson(200, resp);
        return;

    } catch (Exception e) {
    ResponseDTO err = error(resp, 'UNHANDLED_EXCEPTION', e.getMessage(), null);

    if (il != null && il.Id != null) {
        il.Status__c = 'Error';
        il.Status_Code__c = 500;
        il.Status_Message__c = 'UNHANDLED_EXCEPTION';
        il.Response_Body__c = JSON.serialize(err);
        update il;
    }

    sendJson(500, err);
    return;
}
}

    private static void sendJson(Integer statusCode, ResponseDTO resp) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
    }
    private static Boolean isContractActive(Id contractId) {
    Contract c = [SELECT Id, Status FROM Contract WHERE Id = :contractId LIMIT 1];
    return c.Status == Label.LABS_SF_Contract_Status_Activated;
}
    private static String getThisEndpointUrl() {
        return URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/nemo/v1/contract-amendments';
    }

    private static ResponseDTO error(ResponseDTO resp, String code, String msg, Map<String, Object> details) {
        resp.status = 'ERROR';
        resp.errorCode = code;
        resp.message = msg;
        resp.details = details;
        return resp;
    }
}