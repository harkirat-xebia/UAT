public class APER22_AcceptorToLoopManagement {
  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Run Acceptor to Loops creation
   * @param storesToLoop
   */
  public static void runAcceptorToLoopCreation(List<ER_Store_to_Loop__c> storesToLoop) {
    System.debug('>>>>> ALK - runAcceptorToLoopCreation storesToLoop.size : ' + storesToLoop.size());
    Map<Id, ER_Store_to_Loop__c> mapStoresToLoop = new Map<Id, ER_Store_to_Loop__c>(storesToLoop);
    Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
    dte.Transaction_Name__c = Constants.RUN_ACCEPTOR_TO_LOOP_CREATION;
    System.debug(
      '>>>>> ALK - JSON.serializePretty(mapStoresToLoop) length : ' +
      JSON.serializePretty(mapStoresToLoop.keySet()).length()
    );
    dte.Transaction_Content__c = JSON.serializePretty(mapStoresToLoop.keySet());
    EventBus.publish(dte);
  }

  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Run Acceptor to Loops update
   * @param storesToLoop
   */
  public static void runAcceptorToLoopUpdate(List<ER_Store_to_Loop__c> storesToLoop) {
    System.debug('>>>>> ALK - runAcceptorToLoopUpdate storesToLoop.size : ' + storesToLoop.size());
    Map<Id, ER_Store_to_Loop__c> mapStoresToLoop = new Map<Id, ER_Store_to_Loop__c>(storesToLoop);
    Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
    dte.Transaction_Name__c = Constants.RUN_ACCEPTOR_TO_LOOP_UPDATE;
    System.debug(
      '>>>>> ALK - JSON.serializePretty(mapStoresToLoop) length : ' +
      JSON.serializePretty(mapStoresToLoop.keySet()).length()
    );
    dte.Transaction_Content__c = JSON.serializePretty(mapStoresToLoop.keySet());
    EventBus.publish(dte);
  }

  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Create Acceptor to Loops based on the new created Store To Loop
   * @param storesToLoop
   */
  public static void createAcceptorToLoop(Set<Id> storesToLoop) {
    System.debug('>>>>> ALK - createAcceptorToLoop storesToLoop.size : ' + storesToLoop.size());
    List<ER_Acceptor_to_Loop__c> acceptorToLoops = new List<ER_Acceptor_to_Loop__c>();
    Map<Id, List<ER_Store_to_Loop__c>> mapStoreSTL = new Map<Id, List<ER_Store_to_Loop__c>>();

    System.debug('>>>>> ALK - storesToLoop : ' + storesToLoop);
    for (ER_Store_to_Loop__c stl : [
      SELECT Id, ER_Store__c, ER_Behaviour__c, ER_Loop__c, ER_BUPicklist__c, CurrencyIsoCode
      FROM ER_Store_to_Loop__c
      WHERE Id IN :storesToLoop
    ]) {
      if (!mapStoreSTL.containsKey(stl.ER_Store__c))
        mapStoreSTL.put(stl.ER_Store__c, new List<ER_Store_to_Loop__c>());
      mapStoreSTL.get(stl.ER_Store__c).add(stl);
    }

    System.debug('>>>>> ALK - mapStoreSTL : ' + mapStoreSTL.size());
    for (ER_Acceptor__c a : [
      SELECT Id, ER_Store__c, ER_BUPicklist__c
      FROM ER_Acceptor__c
      WHERE ER_Store__c IN :mapStoreSTL.keySet()
    ]) {
      for (ER_Store_to_Loop__c stl : mapStoreSTL.get(a.ER_Store__c)) {
        acceptorToLoops.add(
          new ER_Acceptor_to_Loop__c(
            ER_Acceptor__c = a.Id,
            ER_Loop__c = stl.ER_Loop__c,
            ER_Behaviour__c = stl.ER_Behaviour__c,
            ER_BUPicklist__c = a.ER_BUPicklist__c,
            CurrencyIsoCode = stl.CurrencyIsoCode
          )
        );
      }
    }

    System.debug('>>>>> ALK - acceptorToLoops : ' + acceptorToLoops.size());
    if (!acceptorToLoops.isEmpty())
      Database.insert(acceptorToLoops, false);
  }

  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Create Acceptor to Loops based on the new created Store To Loop
   * @param storesToLoop
   */
  public static void updateAcceptorToLoop(Set<Id> storesToLoop) {
    System.debug('>>>>> ALK - updateAcceptorToLoop storesToLoop.size : ' + storesToLoop.size());
    List<ER_Acceptor_to_Loop__c> acceptorToLoops = new List<ER_Acceptor_to_Loop__c>();
    Map<Id, List<ER_Store_to_Loop__c>> mapStoreSTL = new Map<Id, List<ER_Store_to_Loop__c>>();

    System.debug('>>>>> ALK - storesToLoop : ' + storesToLoop);
    for (ER_Store_to_Loop__c stl : [
      SELECT Id, ER_Store__c, ER_Behaviour__c, ER_Loop__c, ER_BUPicklist__c
      FROM ER_Store_to_Loop__c
      WHERE Id IN :storesToLoop
    ]) {
      if (!mapStoreSTL.containsKey(stl.ER_Store__c))
        mapStoreSTL.put(stl.ER_Store__c, new List<ER_Store_to_Loop__c>());
      mapStoreSTL.get(stl.ER_Store__c).add(stl);
    }
    System.debug('>>>>> ALK - mapStoreSTL : ' + mapStoreSTL.size());

    for (ER_Acceptor_to_Loop__c atl : [
      SELECT Id, ER_Acceptor__c, ER_Acceptor__r.ER_Store__c, ER_Loop__c, ER_Behaviour__c
      FROM ER_Acceptor_to_Loop__c
      WHERE ER_Acceptor__r.ER_Store__c IN :mapStoreSTL.keySet()
    ]) {
      for (ER_Store_to_Loop__c stl : mapStoreSTL.get(atl.ER_Acceptor__r.ER_Store__c)) {
        if (stl.ER_Loop__c == atl.ER_Loop__c)
          acceptorToLoops.add(new ER_Acceptor_to_Loop__c(Id = atl.Id, ER_Behaviour__c = stl.ER_Behaviour__c));
      }
    }

    System.debug('>>>>> ALK - acceptorToLoops : ' + acceptorToLoops.size());
    if (!acceptorToLoops.isEmpty())
      Database.update(acceptorToLoops, false);
  }

  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Check if we have an existing Acceptor To Loop with the same Acceptor and same Loop
   * @param newItems
   */
  public static void CheckAcceptorToLoop(List<ER_Acceptor_to_Loop__c> newItems) {
    if (UtilsBypass.canTrigger('CheckAcceptorToLoop')) {
      Map<Id, List<ER_Acceptor_to_Loop__c>> mapAcceptorATL = new Map<Id, List<ER_Acceptor_to_Loop__c>>();

      for (ER_Acceptor_to_Loop__c atl : newItems) {
        if (!mapAcceptorATL.containsKey(atl.ER_Acceptor__c))
          mapAcceptorATL.put(atl.ER_Acceptor__c, new List<ER_Acceptor_to_Loop__c>());
        mapAcceptorATL.get(atl.ER_Acceptor__c).add(atl);
      }

      for (ER_Acceptor_to_Loop__c atl : [
        SELECT Id, Name, ER_Acceptor__c, ER_Loop__c, ER_Behaviour__c, ER_Business_Unit__c
        FROM ER_Acceptor_to_Loop__c
        WHERE ER_Acceptor__c IN :mapAcceptorATL.keySet()
        LIMIT 50000
      ]) {
        for (ER_Acceptor_to_Loop__c newATL : mapAcceptorATL.get(atl.ER_Acceptor__c)) {
          if (atl.ER_Acceptor__c == newATL.ER_Acceptor__c && atl.ER_Loop__c == newATL.ER_Loop__c && atl.Id != newATL.Id)
            newATL.addError(Label.LABS_SF_Duplicate_Value + ' ' + atl.Id);
        }
      }
    }
  }

  public static void CreatenewAcceptorToLoopOnAcceptorInsert(List<ER_Acceptor__c> NewAcceptorsList) {
    if (UtilsBypass.canTrigger('CreatenewAcceptorToLoopOnAcceptorInsert')) {
      Set<Id> StoreSet = new Set<Id>();
      Map<id, List<ER_Acceptor__c>> StoreToAcceptorListMap = new Map<id, List<ER_Acceptor__c>>();
      List<ER_Acceptor__c> AcceptorList;
      for (ER_Acceptor__c accPoint : NewAcceptorsList) {
        StoreSet.add(accPoint.ER_Store__c);

        AcceptorList = new List<ER_Acceptor__c>();
        AcceptorList.add(accPoint);
        if (StoreToAcceptorListMap.containsKey(accPoint.ER_Store__c)) {
          AcceptorList.addAll(StoreToAcceptorListMap.get(accPoint.ER_Store__c));
        }
        StoreToAcceptorListMap.put(accPoint.ER_Store__c, AcceptorList);
      }
      List<ER_Store_to_Loop__c> StoreToLoops = [
        SELECT Id, Name, ER_Store__c, ER_Loop__c, ER_Behaviour__c, ER_Business_Unit__c
        FROM ER_Store_to_Loop__c
        WHERE ER_Store__c IN :StoreSet
      ];
      List<ER_Acceptor__c> AcceptorListLoopToAdd;
      List<ER_Acceptor_to_Loop__c> AcceptorToLoopToInsert = new List<ER_Acceptor_to_Loop__c>();
      ER_Acceptor_to_Loop__c NewAcceptorToLoop;
      for (ER_Store_to_Loop__c strtoloop : StoreToLoops) {
        AcceptorListLoopToAdd = StoreToAcceptorListMap.get(strtoloop.ER_Store__c);
        for (ER_Acceptor__c AcceptorToAddLoopto : AcceptorListLoopToAdd) {
          NewAcceptorToLoop = new ER_Acceptor_to_Loop__c(
            ER_Acceptor__c = AcceptorToAddLoopto.id,
            ER_Behaviour__c = strtoloop.ER_Behaviour__c,
            ER_Loop__c = strtoloop.ER_Loop__c
          );
          AcceptorToLoopToInsert.add(NewAcceptorToLoop);
        }
      }

      if (!AcceptorToLoopToInsert.isEmpty()) {
        insert AcceptorToLoopToInsert;
      }


        }
    }

    /**
     * @author : DKB
     * @date : 14/08/2023
     * @description : Called by the Acceptor to Loop Trigger when records are created or updated. A queueable is called for Bulkification of records.
     * @param newItems : Newly Created or Updated Acceptor to Loops
     */
    public static void handleAcceptorToLoopsSync(List<ER_Acceptor_to_Loop__c> newItems) {
        List<String> smarterBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)?.split(Constants.SEMICOLON);
        Set<String> contextValues = new Set<String>{Constants.SMARTER, Constants.SMARTER_LEGACY};
        List<ER_Acceptor_to_Loop__c> smarterATL = new List<ER_Acceptor_to_Loop__c>();
        List<ER_Acceptor_to_Loop__c> atlToSync = new List<ER_Acceptor_to_Loop__c>();

        for(ER_Acceptor_to_Loop__c atl :newItems) {
            if(atl.ER_Smarter_1st_Sync_Date__c == null
                    && smarterBUs != null
                    && (smarterBUs.contains(atl.ER_BUPicklist__c) || smarterBUs.contains(Constants.ALL))) smarterATL.add(atl);
        }

        if(!smarterATL.isEmpty()) {
            for(ER_Acceptor_to_Loop__c atl :[SELECT Id, Name, ER_Acceptor__c, ER_Behaviour__c, ER_Loop__r.ER_Context__c,
                                             ER_Loop__r.ER_Store_Group_ID__c, ER_Acceptor__r.ER_MID_Authorization__c,
                                             ER_Acceptor__r.ER_MID_Clearing__c, ER_Acceptor__r.ER_SubMID_Authorization__c,
                                             ER_Acceptor__r.ER_Sub_MID_Clearing__c, ER_Loop__r.ER_Merchant_loop_ID__c, ER_BUPicklist__c
                                             FROM ER_Acceptor_to_Loop__c
                                             WHERE Id IN :smarterATL
                                             AND ER_Loop__r.ER_Context__c IN :contextValues]) {
                if(String.isNotBlank(atl.ER_Loop__r.ER_Store_Group_ID__c)
                        && String.isNotBlank(atl.ER_Loop__r.ER_Merchant_loop_ID__c)) atlToSync.add(atl);
            }

            if(!atlToSync.isEmpty()) {
                System.enqueueJob(new SyncLoopToSmarter(atlToSync, 0, 99));
            }
    }
  }
    
    public class storeInformation{
        public String storeId;
        public String name;
        public String storeGroupId;
        public String acceptanceBehavior;
        public List<midInformation> merchantIdentifiers;
    }
    
    public class midInformation {
        public String authorizationMID;
        public String clearingMID;
        public String authorizationSubMID;
        public String clearingSubMID;
    }
    
    /**
     * @author : DKB
     * @date : 18/07/2023
     * @description :
     * @param acceptorToLoops
     */
    public static void bulkifyAcceptorToLoopsSync(List<ER_Acceptor_to_Loop__c> acceptorToLoops) {
        if(Limits.getCallouts() < Limits.getLimitCallouts()){
            Map<String, String> smarterAT = Utils.getSmarterAccessToken();
            
            if(smarterAT != null && 
               !smarterAT.isEmpty() && 
               smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) && 
               smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)) {
                   
                   List<ER_Acceptor_to_Loop__c> accptrToLoopsToUpdate = new List<ER_Acceptor_to_Loop__c>();
                   
                   for(ER_Acceptor_to_Loop__c eachATL : acceptorToLoops){
                       storeInformation store = new storeInformation();
                       store.storeId = eachATL.ER_Acceptor__c;
                       store.name= eachATL.Name;
                       store.storeGroupId = eachATL.ER_Loop__r.ER_Store_Group_ID__c;
                       store.acceptanceBehavior = eachATL.ER_Behaviour__c;
                       midInformation midInfo = new midInformation();
                       midInfo.authorizationMID = eachATL.ER_Acceptor__r.ER_MID_Authorization__c;
                       midInfo.clearingMID = eachATL.ER_Acceptor__r.ER_MID_Clearing__c;
                       midInfo.authorizationSubMID = eachATL.ER_Acceptor__r.ER_SubMID_Authorization__c;
                       midInfo.authorizationSubMID = eachATL.ER_Acceptor__r.ER_Sub_MID_Clearing__c;
                       store.merchantIdentifiers = new List<midInformation>{midInfo};
                       accptrToLoopsToUpdate.add(syncToSmarterALT(store, eachATL, smarterAT));
                   }
                   
                    if(!accptrToLoopsToUpdate.isEmpty()) Database.update(accptrToLoopsToUpdate, false);
               }
        }
    }
    

    /**
     * @author DKB
     * @date 14/08/2023
     * @description : Sync to smarter all smarter acceptor to loops
     * @param smarterAT
     * @param altTosend
     * @param storeToSen
     * @return
     */
    public static ER_Acceptor_to_Loop__c syncToSmarterALT(storeInformation storeToSen, ER_Acceptor_to_Loop__c altTosend, Map<String, String> smarterAT) {
        try {
            if(altTosend != NULL){
                
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                HttpResponse resp = new HttpResponse();
                
                req.setEndpoint('callout:' + Constants.SMARTER_NAMED_CREDENTIAL + Constants.SLASH + Constants.SMARTER_SYNC_LOOP_SERVICE_VERSION+Constants.SMARTER_SYNC_LOOP_MERCHANT_SERVICE_NAME
                                + Constants.SLASH + altTosend.ER_Loop__r.ER_Merchant_loop_ID__c + Constants.SMARTER_SYNC_LOOP_STORES_NAME);
                req.setMethod(Constants.POST_METHOD);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Accept', 'application/json');
                req.setHeader('X-Tenant', altTosend.ER_BUPicklist__c);
                req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
                req.setHeader('Authorization', smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) + ' ' + smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN));
                req.setBody(String.valueOf(JSON.serialize(storeToSen)));
                
                resp = http.send(req);
                
                if(resp.getStatusCode() == 200) {
                    System.debug('//DKB - Success resp.getStatusCode(): ' + resp.getBody());
                    altTosend.ER_Smarter_1st_Sync_Date__c = Datetime.now();
                    altTosend.ER_Smarter_Last_Sync_Date__c = Datetime.now();
                    altTosend.ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_SYNCED;
                    altTosend.ER_Smarter_Sync_Error__c = '';
                } else {
                    System.debug('//DKB - Failed response : ' + resp.getBody());
                    altTosend.ER_Smarter_Last_Sync_Date__c = Datetime.now();
                    altTosend.ER_Smarter_Sync_Error__c = Utils.getMessageErrorFromSmarter(resp.getBody());
                    altTosend.ER_Smarter_Sync_Status__c = Constants.SMARTER_SYNC_STATUS_NOT_SYNCED;
                }
            } else {
                System.debug('syncToSmarterAsync : altTosend is NULL !');
            }
        } catch(Exception exceptionOccured) {
            System.debug('AsyncToSmarterAsync : Type : ' + exceptionOccured.getTypeName());
            System.debug('AsyncToSmarterAsync : Message : ' + exceptionOccured.getMessage());
            System.debug('AsyncToSmarterAsync : Line Number : ' + exceptionOccured.getLineNumber());
        }
        return altTosend;
}
}