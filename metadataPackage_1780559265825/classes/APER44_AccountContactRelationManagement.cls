/**
 * Created by ATI on 21/08/2023.
 */

public with sharing class APER44_AccountContactRelationManagement {

    /**
     * @author ATI 
     * @date 21/08/23
     * @description Sync Account Contact Relationship records when Context is Smarter and never synced
     * @param items : AccountContactRelation records
     */
    public static void syncAccountContactRelationship(List<AccountContactRelation> items) {
        List<AccountContactRelation> relationsToBeSynced = new List<AccountContactRelation>();

        for(AccountContactRelation acr :[SELECT Id, AccountId, Account.SmartER_Customer_Id__c, Account.ER_BUPicklist__c,
                                                ContactId, Contact.ER_Smarter_1st_Sync_Date__c, IsDirect,
                                                ER_Smarter_1st_Sync_Date__c, ER_Smarter_Sync_Status__c,
                                                ER_Smarter_Last_Sync_Date__c, ER_Smarter_Sync_Error__c, Roles,
                                                CreatedBy.Profile.Name, IsActive
                                            FROM AccountContactRelation
                                            WHERE Id IN :items
                                            AND Account.ER_SmartER_Context__c = TRUE
                                            AND Contact.ER_SmartER_Context__c = TRUE
                                            AND Account.SmartER_Customer_Id__c != NULL
                                            AND Contact.ER_Smarter_1st_Sync_Date__c != NULL
                                            AND Roles != NULL]) {

            relationsToBeSynced.add(acr);
        }

        System.debug('>>>>> ALK - relationsToBeSynced : ' + relationsToBeSynced);
        if(!relationsToBeSynced.isEmpty()) System.enqueueJob(new SyncAccountContactRelationToSmarter(relationsToBeSynced, 0, 99));
    }

    /**
     * @author ATI 
     * @date 21/08/23
     * @description Sync Account Contact Relationship with distingue method when isactive and roles is updated.
     * @param items : AccountContactRelation records
     * @param oldItems : AccountContactRelation records on update context
     */
    public static void patchAccountContactRelationship(List<AccountContactRelation> items, Map<Id, AccountContactRelation> oldItems) {
        List<AccountContactRelation> relationsToPost = new List<AccountContactRelation>();
        List<AccountContactRelation> relationsToPatch = new List<AccountContactRelation>();
        for(AccountContactRelation acr :items) {
            if(acr.ER_Smarter_1st_Sync_Date__c == null) relationsToPost.add(acr);
            else if(acr.IsActive != oldItems.get(acr.Id).IsActive || acr.Roles != oldItems.get(acr.Id).Roles) relationsToPatch.add(acr);
        }

        if(!relationsToPost.isEmpty()) 
            syncAccountContactRelationship(relationsToPost);
        if(!relationsToPatch.isEmpty()) 
            syncAccountContactRelationship(relationsToPatch);
    }

    /**
     * @author ATI
     * @date 21/08/23
     * @description  Prepare Connection data and payload  
     * @param items AccountContactRelationship records to sync
     */
    public static void doSync(List<AccountContactRelation> items) {
        if(items != null && !items.isEmpty()) {
            String method = (items[0].ER_Smarter_1st_Sync_Date__c == null ? Constants.POST_METHOD : Constants.PATCH_METHOD);
            Map<String, List<Map<String, Object>>> dataMap = retrieveDataToSync(items);
            System.debug('>>>>> ALK - dataMap : ' + dataMap);

            if(!dataMap.isEmpty() && Limits.getCallouts() < Limits.getLimitCallouts()) {
                Map<String, String> smarterAT = Utils.getSmarterAccessToken();
                if(smarterAT != null
                        && !smarterAT.isEmpty()
                        && smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE)
                        && smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)) {

                    List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();

                    for(String key :dataMap.keySet()) {
                        List<Map<String, Object>> data = dataMap.get(key);
                        if(data != null && !data.isEmpty()) {
                            acrsToUpdate.addAll(callSmarterClientWS(data, key, smarterAT, method));
                        }
                    }

                    if(!acrsToUpdate.isEmpty()) updateAsyncRelations(JSON.serialize(acrsToUpdate));
                }
            }
        }
    }

    /**
     * @author ATI
     * @date 21/08/23
     * @description  save response on records
     * @param acrsToUpdateJson records to update after sync
     */
    @Future
    public static void updateAsyncRelations(String acrsToUpdateJson) {
        System.debug('>>>>> ALK - acrsToUpdateJson : ' + acrsToUpdateJson);
        if(acrsToUpdateJson != null) {
            List<AccountContactRelation> acrsToUpdate = (List<AccountContactRelation>) JSON.deserialize(acrsToUpdateJson, List<AccountContactRelation>.class);
            System.debug('>>>>> ALK - loopToUpdate : ' + acrsToUpdate);
            Database.update(acrsToUpdate, false);
        }
    }

    /**
     * @author ATI
     * @date 21/08/23
     * @description  prepare Callout payload
     * @param items : records to sync
     * @return  dataMaps : payload object key value as Map<String, List<Map<String, Object>>>
     */
    public static Map<String, List<Map<String, Object>>> retrieveDataToSync(List<AccountContactRelation> items) {
        Map<String, List<Map<String, Object>>> dataMaps = new Map<String, List<Map<String, Object>>>();

        for(AccountContactRelation item : items) {
            if(String.isNotBlank(item.Account.ER_BUPicklist__c)) {
                String key = item.Account.ER_BUPicklist__c;
                Map<String, Object> mapData = new Map <String, Object>();
                mapData.put(Constants.SMARTER_ACCOUNT_REF_ID, item.AccountId);
                mapData.put(Constants.SMARTER_CONTACT_ONEFORCE_ID, item.ContactId);
                mapData.put(Constants.SMARTER_ACCOUNT_CONTACT_RELATIONS_ID, item.Id);
                mapData.put(Constants.SMARTER_ACCOUNT_CONTACT_IS_DIRECT_RELATION, item.IsDirect);
                mapData.put(Constants.SMARTER_CLIENT_REF_CLIENT_ID, item.Account.SmartER_Customer_Id__c);
                mapData.put(Constants.SMARTER_ACCOUNT_CONTACT_ROLES, item.Roles == Constants.SMARTER_ACCOUNT_CONTACT_ROLES_ADMINISTRATOR ? Constants.SMARTER_ACCOUNT_CONTACT_ROLES_ADMIN : item.Roles );
                mapData.put(Constants.SMARTER_ACCOUNT_CONTACT_EVENT_TYPE, (item.CreatedBy.Profile.Name == Constants.PROFILE_ER_INTEGRATION ? Constants.SMARTER_ACCOUNT_CONTACT_EVENT_TYPE_ONLINE : Constants.SMARTER_ACCOUNT_CONTACT_EVENT_TYPE_OFFLINE));
                mapData.put(Constants.SMARTER_CLIENT_REF_STATUS, (item.IsActive ? Constants.ACTIVE_LOWERCASE : Constants.INACTIVE_LOWERCASE));

                if(!dataMaps.containsKey(key)) dataMaps.put(key, new List<Map<String, Object>>());
                dataMaps.get(key).add(mapData);
            }
        }

        return dataMaps;
    }

    /**
     * @author ATI
     * @date 21/08/23
     * @param dataMap 
     * @param bu
     * @param smarterAT
     * @param method
     * @description : perform callout & and manage response
     * @return AccountContactRelation records with response
     */
    public static List<AccountContactRelation> callSmarterClientWS(List<Map<String, Object>> dataMap, String bu, Map<String, String> smarterAT, String method) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        List<AccountContactRelation> relations = new List<AccountContactRelation>();

        req.setEndpoint('callout:' + Constants.SMARTER_NAMED_CREDENTIAL
                + Constants.SLASH + Constants.SMARTER_SYNC_ACCOUNT_CONTACT_RELATIONS_SERVICE_VERSION + Constants.SLASH
                + Constants.SMARTER_SYNC_ACCOUNT_CONTACT_RELATIONS_SERVICE_NAME);

        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('X-Tenant', bu);
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        req.setHeader('Authorization', smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) + ' ' + smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN));

        String payload = JSON.serialize(dataMap);
        System.debug('>>>>> ALK - callSmarterClientWS payload: ' + payload);
        req.setBody(payload);
        resp = http.send(req);
        System.debug('>>>>> ALK - resp.getStatusCode() : ' + resp.getStatusCode());

        if(resp.getStatusCode() == 204 || resp.getStatusCode() == 200) {

            for(Map<String, Object> d :dataMap) {
                AccountContactRelation acr = new AccountContactRelation();
                acr.Id = (Id) d.get(Constants.SMARTER_ACCOUNT_CONTACT_RELATIONS_ID);
                acr.ER_Smarter_1st_Sync_Date__c = Datetime.now();
                acr.ER_Smarter_Last_Sync_Date__c = Datetime.now();
                acr.ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_SYNCED;
                acr.ER_Smarter_Sync_Error__c = '';
                relations.add(acr);
            }

        } else {
            for(Map<String, Object> d :dataMap) {
                AccountContactRelation acr = new AccountContactRelation();
                acr.Id = (Id) d.get(Constants.SMARTER_ACCOUNT_CONTACT_RELATIONS_ID);
                acr.ER_Smarter_Last_Sync_Date__c = Datetime.now();
                acr.ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_NOT_SYNCED;
                acr.ER_Smarter_Sync_Error__c = getMessageErrorFromSmarter(resp.getBody());
                relations.add(acr);
            }
        }

        return relations;
    }

    /**
     * @param response
     *
     * @return
     */
    public static String getMessageErrorFromSmarter(String response) {
        try {
            Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(response);
            Map<String, Object> dataMeta = (Map<String, Object>) (mapRespData.get('meta'));

            if(dataMeta.get('status').equals('Failed')) {
                List<Object> messages = (List<Object>) dataMeta.get('messages');

                if(!messages.isEmpty()) {
                    Map<String, Object> messageMap = (Map<String, Object>) messages[0];
                    return ((String) messageMap.get('text')).remove('\'');
                }
            }
        } catch(Exception e) {
            System.debug('//callSmarterClientWS parsing error ' + e.getMessage());
        }

        return '';
    }
    
}