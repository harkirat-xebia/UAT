/**
 * Created by khaddouch on 03/06/2021.
 * @description
 */

public with sharing class ER_SyncStructureWS implements Queueable, Database.AllowsCallouts {
  // Contructor needed for data initialization for the queuing
  private Set<Id> accountIDs;
  private Set<Id> contractIDs;
  private Set<Id> ModifiedElements;
  private String method;
  private String action;
  private Map<Id, String> accountsInputScope;
  public static List<String> responseToShow = new List<String>();
  public static List<String> responseFailedToShow = new List<String>();
  public static Boolean alreadyExecutedSync = false;

  public ER_SyncStructureWS(Set<Id> accountId, Set<Id> contractId, String methodParam, Set<Id> ModifiedElements) {
    this.accountIDs = accountId;
    System.debug('#####ASYNC accountIDs : ' + accountIDs);
    this.contractIDs = contractId;
    System.debug('#####ASYNC contractIDs : ' + contractIDs);
    this.method = methodParam;
    System.debug('#####ASYNC method : ' + method);
    this.action = 'UpdateStructure';
    this.ModifiedElements = ModifiedElements;
    System.debug('#####ASYNC ModifiedElements : ' + ModifiedElements);
  }

  public ER_SyncStructureWS(
    Set<Id> accountId,
    Set<Id> contractId,
    String methodParam,
    Set<Id> ModifiedElements,
    Map<Id, String> accountsInputScope
  ) {
    this.accountIDs = accountId;
    System.debug('#####ASYNC accountIDs : ' + accountIDs);
    this.contractIDs = contractId;
    System.debug('#####ASYNC contractIDs : ' + contractIDs);
    this.method = methodParam;
    System.debug('#####ASYNC method : ' + method);
    this.action = 'UpdateStructure';
    this.ModifiedElements = ModifiedElements;
    System.debug('#####ASYNC ModifiedElements : ' + ModifiedElements);
    this.accountsInputScope = accountsInputScope;
  }
  // Execute method that is the method that call the specified enqueue method
  public void execute(QueueableContext context) {
    System.debug('#####ASYNC context accountIDs : ' + accountIDs);
    System.debug('#####ASYNC context contractIDs : ' + contractIDs);
    System.debug('#####ASYNC context method : ' + method);
    System.debug('#####ASYNC ModifiedElements : ' + ModifiedElements);
    System.debug('#####ASYNC accountsInputScope : ' + accountsInputScope);

    if (
      UserInfo.getUserType() == Constants.AUTOMATED_PROCESS &&
      String.isBlank(APER30_AutoEnrollment_Management.syncRecordBU)
    ) {
      if (!accountIDs.isEmpty())
        APER30_AutoEnrollment_Management.syncRecordBU = [
          SELECT ER_BUPicklist__c
          FROM Account
          WHERE Id IN :accountIDs
        ][0]
        .ER_BUPicklist__c;
      else if (!contractIDs.isEmpty())
        APER30_AutoEnrollment_Management.syncRecordBU = [
          SELECT ER_BUPicklist__c
          FROM Contract
          WHERE Id IN :contractIDs
        ][0]
        .ER_BUPicklist__c;
    }

    createStructureWS(accountIDs, contractIDs, method, action, ModifiedElements, accountsInputScope);
  }

  public static String[] createStructureWS(
    Set<Id> merchantId,
    Set<Id> contractId,
    String method,
    String action,
    Set<Id> ModifiedElements
  ) {
    return responseToShow;
  }

  /**
   * @author AAM
   * @param merchantId
   * @param contractId
   * @param method
   * @param action
   * @param ModifiedElements
   * @param accountsInputScope
   *
   * @return
   */
  public static String[] createStructureWS(
    Set<Id> merchantId,
    Set<Id> contractId,
    String method,
    String action,
    Set<Id> ModifiedElements,
    Map<Id, String> accountsInputScope
  ) {
    HttpResponse res;
    res = ER_SyncStructureWS.syncAccountWS(
      merchantId,
      contractId,
      method,
      action,
      ModifiedElements,
      accountsInputScope
    );
    System.debug('###KHAD res  :' + res);
    System.debug(
      '###KHAD The status code returned was : ' +
      res.getStatusCode() +
      ' ' +
      res.getStatus() +
      ' ' +
      res.getBody()
    );
    // Read the sync response and update the objects
    try {
      ER_SyncStructureWS.alreadyExecutedSync = true;
      ER_SyncStructureWithLegacy.operateLegacyResponse(res.getBody());
    } catch (Exception e) {
      /* Can't parse the server response */
      // response to the user
      System.debug('--- Error message : ' + e.getMessage());
      //responseToShow.add('failed');
      //responseToShow.add('Unable to parse the server message.');
      responseToShow.add(Label.LABS_SF_Contract_Activation_Unable_To_Parse);
      responseToShow.add(e.getMessage());
      return responseToShow;
    }
    // check if the response in a success then call the following method if the contract id is filled(post merchant + post contract + close contract use cases + Put contract also if available)
    Map<String, Object> obj = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    Map<String, Object> meta = (Map<String, Object>) obj.get('meta');
    Map<String, Object> data = (Map<String, Object>) obj.get('data');
    Boolean contactSyncOK = false;
    Boolean contactActivationError = false;
    System.debug('KHAD status request : ' + meta.get('status'));
    System.debug('KHAD status request action : ' + action);
    if (meta.get('status') == 'succeeded' && (action == 'Activation' || action == 'Termination')) {
      List<Id> contractsIds = new List<Id>();
      contractsIds.addAll(contractId);
      List<Contract> contractList = APER12_Contract_Management.getContract(contractsIds);
      if (data != null) {
        List<Object> synchronizationResults = (List<Object>) data.get('synchronization_results');
        for (Object o : synchronizationResults) {
          Map<String, Object> results = (Map<String, Object>) o;
          Map<String, Object> attributes = (Map<String, Object>) results.get('attributes');
          Map<String, Object> syncResult = (Map<String, Object>) results.get('synchronization_result');
          if (attributes != null && syncResult != null) {
            String objectType = (String) attributes.get('type');
            if (objectType == 'contract') {
              System.debug('####KHAD objectType : ' + objectType);
              System.debug('####KHAD record_id : ' + attributes.get('record_id'));
              System.debug('####KHAD sync status : ' + syncResult.get('status'));
              System.debug('####KHAD contractList[0].Id : ' + contractList[0].Id);
              if (
                attributes.get('record_id') == contractList[0].Id &&
                (syncResult.get('status') == 'synchronized' ||
                syncResult.get('status') == 'pending_synchronization')
              ) {
                contactSyncOK = true;
              } else if (
                attributes.get('record_id') == contractList[0].Id &&
                syncResult.get('status') == 'not_synchronized'
              ) {
                //responseFailedToShow.add('failed');
                responseFailedToShow.add((String) syncResult.get('message'));
                contactActivationError = true;
              } else {
                contactActivationError = true;
              }
            }
          }
        }
      }
      System.debug('####KHAD action : ' + action);
      System.debug('####KHAD  contactSyncOK : ' + contactSyncOK);
      if (action == 'Activation' && contactSyncOK) {
        // Call the same function as in the offline mode
        APER12_Contract_Management.activateContractController(
          contractList[0],
          contractList[0].ER_OpportunityId__c,
          false
        );
      } else if (action == 'Termination' && contactSyncOK) {
        contractList[0].Status = Label.LABS_SF_Contract_Status_Terminated;
        contractList[0].ER_Terminated_Date__c = Datetime.now();
        contractList[0].ER_Offline__c = false;
        update contractList[0];
        APER20_Account_Management.manageStatusOnContractTermination(contractList[0].AccountId);
      }
    }
    if (contactActivationError && responseFailedToShow.isEmpty()) {
      responseFailedToShow.add('failed');
      responseFailedToShow.add('Something wrong on the server! Please contact the administrator to report the issue.');
    }
    //Error to display in case of the contract management !
    //if (contactActivationError) return responseToShow;
    if (contactActivationError && !contactSyncOK)
      return responseFailedToShow;

    if (res.getStatusCode() == 500) {
      // response to the user
      responseToShow.add('failed');
      responseToShow.add('Something wrong on the server! Please contact the administrator to report the issue.');
      return responseToShow;
    }
    //responseToShow.add(meta.get('status').toString());
    //
    String message = null;
    String code = null;

    if (meta != null) {
      List<Object> messagesResult = (List<Object>) meta.get('messages');
      for (Object o : messagesResult) {
        Map<String, Object> results = (Map<String, Object>) o;
        message = results.get('text').toString();
        //message = message + results.get('text');
        //message = results.get('text');
        code = message + results.get('code');
      }
    }

    responseToShow.add(
      message != null
        ? message //message);
        : meta.get('status').toString()
    );
    //

    System.debug('######### responseToShow : ' + responseToShow);
    return responseToShow;
  }

  public static HttpResponse syncAccountWS(
    Set<Id> merchantId,
    Set<Id> contractId,
    String method,
    String action,
    Set<Id> ModifiedElements
  ) {
    HttpResponse res;
    return res;
  }

  public static HttpResponse syncAccountWS(
    Set<Id> merchantId,
    Set<Id> contractId,
    String method,
    String action,
    Set<Id> ModifiedElements,
    Map<Id, String> accountsInputScope
  ) {
    String currentDate = String.valueOf((datetime.now().getTime()) / 1000);
    string structure = ER_SyncStructureWithLegacy.syncContract(
      merchantId,
      contractId,
      action,
      ModifiedElements,
      accountsInputScope
    );
    //endpoint POST -> /accounts ---- PUT -> /accounts/account_id
    String endpoint = '/accounts';
    System.debug('######KHAD6666');

    if (method == 'PUT') {
      String accountId = new List<Id>(merchantId).get(0);
      endpoint = '/accounts/' + accountId;
    }

    // get the HmacToken to be send
    String nonce = String.valueOf(Crypto.getRandomLong());
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacTokenV3(endpoint, structure, nonce, currentDate, method);

    /**
     * send the structure
     */
    Http h = new Http();

    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequestV3(
      endpoint,
      method,
      hmacToken,
      currentDate,
      nonce,
      structure
    );
    HttpResponse res;
    res = h.send(req);

    return res;
  }
}