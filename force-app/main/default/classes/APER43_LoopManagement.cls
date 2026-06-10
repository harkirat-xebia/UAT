/*
----------------------------------------------------------------------
-- - Name          : APER43_LoopManagement
-- - Author        : Noor
-- - Description   : Loop Management, This class is used to group all the functionality linked to the Loop
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- Aug-2023     Noor                1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class APER43_LoopManagement {

    /**
     * @author Noor
     * @date 11/07/2023
     * @description call smarter API CreateMerchantLoopStoreGroup to synchronize loops when ER_Merchant_loop_ID__c is updated
     * @param newItems updated loops
     * @param oldMaps old values from updated Loops
     */
    public static void createMerchantLoopStoreGroup(List<ER_Loop__c> newItems, Map<Id, ER_Loop__c> oldMaps) {

        Set<String> SMARTER_CONTEXT_LIST = new Set<String>{Constants.SMARTER, Constants.SMARTER_LEGACY};
        List<ER_Loop__c> loopToSync = new List<ER_Loop__c>();
        for(ER_Loop__c l : newItems){
            if(SMARTER_CONTEXT_LIST.contains(l.ER_Context__c) && String.isNotBlank(l.ER_Merchant_loop_ID__c)
                    && l.ER_Merchant_loop_ID__c != oldMaps.get(l.Id).ER_Merchant_loop_ID__c) loopToSync.add(l);
        }

        if(!loopToSync.isEmpty()) System.enqueueJob(new SyncLoopToSmarter(loopToSync, 0, 99));
    }

    /**
     * @author Noor
     * @date 11/07/2023
     * @description call smarter API CreateMerchantLoopStoreGroup to synchronize list of loops
     * @param loops  list of Loops that will be synchronized
     */
    public static void callCreateMerchantLoopStoreGroup(List<ER_Loop__c> loops) {
        Map<String, List<Map<String, Object>>> dataMap = retrieveLoopToSync(loops);

        if(!dataMap.isEmpty() && Limits.getCallouts() < Limits.getLimitCallouts()) {
            Map<String, String> smarterAT = Utils.getSmarterAccessToken();
            if(smarterAT != null
                    && !smarterAT.isEmpty()
                    && smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE)
                    && smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)) {

                List<ER_Loop__c> loopToUpdate = new List<ER_Loop__c>();

                for(String key :dataMap.keySet()) {
                    for(Map<String, Object> m : dataMap.get(key) ){
                        loopToUpdate.add(callSmarterClientWS(m, key, smarterAT));
                    }
                }

                if(!loopToUpdate.isEmpty()) updateAsyncLoop(JSON.serialize(loopToUpdate));
            }
        }
    }

    @Future
    public static void updateAsyncLoop(String loopJson) {
        if(loopJson != null) {
            List<ER_Loop__c> loopToUpdate = (List<ER_Loop__c>) JSON.deserialize(loopJson, List<ER_Loop__c>.class);
            Database.update(loopToUpdate, false);
        }
    }

    /**
     * @author Noor
     * @date 21/03/2023
     * @description retrieve loop To Sync to smarter for the loopIds
     * @param loops set of account Ids
     * @return list of loop per BU and per Method to send
     */
    public static Map<String, List<Map<String, Object>>> retrieveLoopToSync(List<ER_Loop__c> loops) {
        Map<String, List<Map<String, Object>>> dataMaps = new Map<String, List<Map<String, Object>>>();

        for(ER_Loop__c l : loops) {
            if(String.isNotBlank(l.ER_BUPicklist__c)) {
                String key = l.ER_BUPicklist__c;
                Map<String, Object> mapData = new Map <String, Object>();
                mapData.put(Constants.SMARTER_LOOP_MERCHANT_NAME_ID, l.ER_Merchant_loop_ID__c);
                mapData.put(Constants.SMARTER_LOOP_STORE_GROUP_ID, l.Id);
                mapData.put(Constants.SMARTER_LOOP_MERCHANT_NAME, l.Name);
                mapData.put(Constants.SMARTER_LOOP_MERCHANT_CODE, l.Id);

                if(dataMaps.containsKey(key)) dataMaps.get(key).add(mapData);
                else dataMaps.put(key, new List<Map<String, Object>> {mapData});
            }
        }

        return dataMaps;
    }

    /**
     * @author Noor
     * @date 11/07/2023
     * @description call webservice by bu and by method (post or patch)
     * @param dataMap
     * @param bu business unit
     * @param smarterAT credential to connect to Webservice
     * @return loop to be updated
     */
    public static ER_Loop__c callSmarterClientWS(Map<String, Object> dataMap, String bu, Map<String, String> smarterAT) {

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        ER_Loop__c erloop = new ER_Loop__c();
        String createStoreGroupService = (dataMap != null && !dataMap.isEmpty()
                                            && dataMap.containsKey(Constants.SMARTER_LOOP_MERCHANT_NAME_ID)
                                            && String.isNotBlank(dataMap.get(Constants.SMARTER_LOOP_MERCHANT_NAME_ID)?.toString())
                                            ? Constants.SLASH
                                            + dataMap.get(Constants.SMARTER_LOOP_MERCHANT_NAME_ID).toString()
                                            + Constants.SMARTER_SYNC_LOOP_MERCHANT_GROUP_SERVICE_NAME : '');

        req.setEndpoint('callout:' + Constants.SMARTER_NAMED_CREDENTIAL
                            + Constants.SLASH + Constants.SMARTER_SYNC_LOOP_SERVICE_VERSION
                            + Constants.SMARTER_SYNC_LOOP_MERCHANT_SERVICE_NAME + createStoreGroupService);

        req.setMethod(Constants.POST_METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('X-Tenant', bu);
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        req.setHeader('Authorization', smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) + ' ' + smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN));

        String payload = JSON.serialize(dataMap);
        System.debug('//NGO - callSmarterClientWS payload: ' + payload);
        req.setBody(payload);
        resp = http.send(req);
        Id storeGroupId = (Id) dataMap.get(Constants.SMARTER_LOOP_STORE_GROUP_ID);
        if(resp.getStatusCode() == 200) {
            System.debug('//NGO - Success resp.getStatusCode(): ' + resp.getBody());
            erloop.Id = storeGroupId;
            String merchantLoopId = (String) dataMap.get(Constants.SMARTER_LOOP_MERCHANT_NAME_ID);
            if(String.isEmpty(merchantLoopId)) {
                merchantLoopId = getResponseMerchantLoopId(resp.getBody());
                erloop.ER_Smarter_1st_Sync_Date__c = Datetime.now();
                erloop.ER_Merchant_loop_ID__c = merchantLoopId;
            } else {
                erloop.ER_Store_Group_ID__c = storeGroupId;
            }
            erloop.ER_Smarter_Last_Sync_Date__c = Datetime.now();
            erloop.ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_SYNCED;
            erloop.ER_Smarter_Sync_Error__c = '';
        } else {
            System.debug('//NGO - Failed response : ' + resp.getBody());
            erloop = new ER_Loop__c(Id = storeGroupId,
                    ER_Smarter_Last_Sync_Date__c = Datetime.now(),
                    ER_Smarter_Sync_Error__c = Utils.getMessageErrorFromSmarter(resp.getBody()),
                    ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_NOT_SYNCED);
        }
        return erloop;
    }

    /**
     * @author AAZ
     * @date 16/08/2023
     * @description Sync Smarter Loops to Legacy
     * @param newItems
     * @param oldMaps
     */
    public static void createSmarterMerchantLoop(List<ER_Loop__c> newItems, Map<Id, ER_Loop__c> oldMaps) {
        List<ER_Loop__c> loopsToSync = new List<ER_Loop__c>();
        Set<String> smarterContextValues = new Set<String>{Constants.SMARTER, Constants.SMARTER_LEGACY};

        for(ER_Loop__c l :newItems) {
            if(smarterContextValues.contains(l.ER_Context__c)
                    && String.isBlank(l.ER_Merchant_loop_ID__c)) loopsToSync.add(l);
        }

        if(!loopsToSync.isEmpty()) System.enqueueJob(new SyncLoopToSmarter(loopsToSync, 0, 99));
    }

    /**
     * @author AAZ
     * @date 16/08/2023
     * @description Get Response Merchant Loop Id
     * @param response
     *
     * @return
     */
    public static String getResponseMerchantLoopId(String response) {
        try {
            Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(response);
            Map<String, Object> meta = (Map<String, Object>) (mapRespData.get('meta'));
            Map<String, Object> data = (Map<String, Object>) (mapRespData.get('data'));

            if(meta.get('status').equals(Constants.SUCCEEDED)) {
                String merchantLoopId = data.get('merchantLoopId').toString();
                System.debug('>>>>> AAZ - merchantLoopId : ' + merchantLoopId);
                return merchantLoopId;
            }
        } catch(Exception e) {
            System.debug('//callSmarterClientWS parsing error ' + e.getMessage());
        }
        return null;
    }
}