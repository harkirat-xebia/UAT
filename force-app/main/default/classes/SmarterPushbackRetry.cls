/**
 * @author: AAZ
 * @date: 28/07/2023
 * @desc: SmarterPushbackRetry
 * @see: SmarterPushbackRetry
 */

@RestResource(UrlMapping='/smarterPushBackRetry/*')
global with sharing class SmarterPushbackRetry {

    @HttpPost
    global static SmarterPushbackRetry.SmarterPushbackRetryResponse doPost(List<SmarterPushbackRetry.SmarterPushbackRetryRequest> data) {
        final Integer MAX_RECORDS = 100;
        final String SUCCESS_MSG = 'The pushback Ids retry has been ran successfully';
        final String REQUIRED_FIELDS_MISSING_MSG = 'Required fields are missing: [oneforceLeadId]';
        final String INVALID_LEAD_ID_MSG = 'Invalid [oneforceLeadId] : ';
        final String BATCH_SIZE_LIMIT_MSG = 'Max batch size limit exceeded [' + MAX_RECORDS + ' records per transaction]';
        try {
            Set<Id> leadsIds = new Set<Id>();
            System.debug('>>>>> AAZ - data : ' + data);
            System.debug('>>>>> AAZ - data.size : ' + data.size());
            if(!data.isEmpty()) {
                if(data.size() <= MAX_RECORDS) {
                    for(SmarterPushbackRetry.SmarterPushbackRetryRequest d :data) {
                        if(String.isNotBlank(d.oneforceLeadId)) {
                            if(Utils.isValidSalesforceId(d.oneforceLeadId, Lead.class)) leadsIds.add(d.oneforceLeadId);
                            else return buildResponsePayload(false, 400, INVALID_LEAD_ID_MSG + d.oneforceLeadId);
                        } else return buildResponsePayload(false, 400, REQUIRED_FIELDS_MISSING_MSG);
                    }

                    //Process Pushback Ids retry
                    if(!leadsIds.isEmpty()) processRetry(leadsIds);

                } else return buildResponsePayload(false, 400, BATCH_SIZE_LIMIT_MSG);

            } else return buildResponsePayload(false, 400, REQUIRED_FIELDS_MISSING_MSG);

        } catch(Exception e) {
            return buildResponsePayload(false, 400, e.getMessage());
        }

        return buildResponsePayload(true, 200, SUCCESS_MSG);
    }

    public static void processRetry(Set<Id> leadsIds) {
        List<Lead> allLeads = new List<Lead>();
        Map<Id, Lead> convertedLeads = new Map<Id, Lead>();
        List<Lead> leadsToBeConverted = new List<Lead>();
        Map<Id, Id> mapLeadsIdsFCs = new Map<Id, Id>();
        List<ER_Financial_Center__c> fcsToBeCreated = new List<ER_Financial_Center__c>();

        for(Lead l :[SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ER_To_Be_Converted__c,
                        ER_BUPicklist__c, ER_Lead_Type__c, ER_Legal_Street__c, Street, ER_Legal_City__c, City,
                        ER_Legal_Zip_Code__c, PostalCode, ER_Legal_State_Province__c, State, ER_Legal_Country__c,
                        Country, ER_Legal_Country_Code__c, OwnerId, ER_dd_Trace_Id__c, Email, RecordTypeId,
                        ER_Registration_Number__c, ConvertedOpportunityId, ER_SmartER_Context__c, Company
                    FROM Lead WHERE Id IN :leadsIds]) {
            allLeads.add(l);
            if(l.IsConverted) convertedLeads.put(l.Id, l);
            else {
                l.ER_To_Be_Converted__c = true;
                leadsToBeConverted.add(l);
            }
        }

        System.debug('>>>>> AAZ - convertedLeads : ' + convertedLeads);
        if(!convertedLeads.isEmpty()) {
            for(ER_Financial_Center__c fc :[SELECT Id, ER_SmartER_Original_Lead_Id__c
                                            FROM ER_Financial_Center__c
                                            WHERE ER_SmartER_Original_Lead_Id__c IN :convertedLeads.keySet()]) {
                mapLeadsIdsFCs.put(fc.ER_SmartER_Original_Lead_Id__c, fc.Id);
            }
        }

        List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey(Constants.FC_DEFAULT_PAYMENTSITE));
        for(Lead l :allLeads) {
            if(!mapLeadsIdsFCs.containsKey(l.Id)) {
                Boolean isPaymentSite = (bus.contains(l.ER_BUPicklist__c) && l.ER_Lead_Type__c == System.Label.LAB_SF_Lead_Type_Merchant);
                String financialCenterType = (l.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_MERCHANT_RT) ? Label.LABS_SF_FinancialCenter_Merchant : Label.LABS_SF_FinancialCenter_Client);
                ER_Financial_Center__c fc = new ER_Financial_Center__c(Name = l.Company?.left(80),
                        ER_Account_Name__c = l.ConvertedAccountId,
                        ER_Street__c = (String.isNotBlank(l.ER_Legal_Street__c) ? l.ER_Legal_Street__c : l.Street),
                        ER_City__c = (String.isNotBlank(l.ER_Legal_City__c) ? l.ER_Legal_City__c : l.City),
                        ER_Zip_Code__c = (String.isNotBlank(l.ER_Legal_Zip_Code__c) ? l.ER_Legal_Zip_Code__c : l.PostalCode),
                        ER_State_Province__c = (String.isNotBlank(l.ER_Legal_State_Province__c) ? l.ER_Legal_State_Province__c : l.State),
                        ER_Country__c = (String.isNotBlank(l.ER_Legal_Country__c) ? l.ER_Legal_Country__c : l.Country),
                        ER_Country_Code__c = l.ER_Legal_Country_Code__c,
                        ER_Invoicing_Site__c = !isPaymentSite,
                        ER_Invoicing_Street__c = (String.isNotBlank(l.ER_Legal_Street__c) ? l.ER_Legal_Street__c : l.Street),
                        ER_Invoicing_City__c = (String.isNotBlank(l.ER_Legal_City__c) ? l.ER_Legal_City__c : l.City),
                        ER_Invoicing_Zip_Code__c = (String.isNotBlank(l.ER_Legal_Zip_Code__c) ? l.ER_Legal_Zip_Code__c : l.PostalCode),
                        ER_Invoicing_Country__c = (String.isNotBlank(l.ER_Legal_Country__c) ? l.ER_Legal_Country__c : l.Country),
                        ER_Invoicing_Country_Code__c = l.ER_Legal_Country_Code__c,
                        ER_Invoicing_Region_State__c = (String.isNotBlank(l.ER_Legal_State_Province__c) ? l.ER_Legal_State_Province__c : l.State),
                        ER_SmartER_Context__c = l.ER_SmartER_Context__c,
                        ER_Contact__c = (l.ER_SmartER_Context__c ? l.ConvertedContactId : null),
                        ER_SmartER_Original_Lead_Id__c = l.Id,
                        ER_Payment_Site__c = isPaymentSite,
                        ER_BUPicklist__c = l.ER_BUPicklist__c,
                        OwnerId = (l.ER_SmartER_Context__c && String.valueOf(l.OwnerId).left(3) == Constants.USER_OBJECT_PREFIX ? l.OwnerId : UserInfo.getUserId()),
                        ER_Type__c = financialCenterType,
                        ER_dd_Trace_Id__c = (l.ER_SmartER_Context__c ? l.ER_dd_Trace_Id__c : null));
                fcsToBeCreated.add(fc);
            }
        }

        System.debug('>>>>> AAZ - mapLeadsIdsFCs : ' + mapLeadsIdsFCs);
        System.debug('>>>>> AAZ - fcsToBeCreated : ' + fcsToBeCreated);
        System.debug('>>>>> AAZ - leadsToBeConverted : ' + leadsToBeConverted);
        if(!mapLeadsIdsFCs.isEmpty()) APER30_FinancialCenter_Management.pushBackLeadConversionIds(new Set<Id>(mapLeadsIdsFCs.values()));
        if(!leadsToBeConverted.isEmpty()) APER18_Lead_Management.convertLeads(leadsToBeConverted);
        if(!fcsToBeCreated.isEmpty()) Database.insert(fcsToBeCreated, false);
    }

    public static SmarterPushbackRetry.SmarterPushbackRetryResponse buildResponsePayload(Boolean isSucess, Integer statusCode, String msg) {
        return new SmarterPushbackRetry.SmarterPushbackRetryResponse(isSucess, statusCode, msg);
    }

    global class SmarterPushbackRetryResponse {
        public Integer statusCode {get; set;}
        public Boolean success {get; set;}
        public String message {get; set;}

        public SmarterPushbackRetryResponse(Boolean success, Integer statusCode, String message) {
            this.success = success;
            this.statusCode = statusCode;
            this.message = message;
        }
    }

    global class SmarterPushbackRetryRequest {
        public String oneforceLeadId {get; set;}
    }

}