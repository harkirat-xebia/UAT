public class WSCZ01_SynchronizeStoreWS {
  /*
----------------------------------------------------------------------
-- - Name          : APHU09_SynchronizeAcceptorWS
-- - Author        : AAB
-- - Description   : Process the WS callout to EDG for data synchronization 
-- -                 Here is for the Acceptor 
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 16-MAI-2018  AAB                 1.0         Initial version
---------------------------------------------------------------------------------------
To Do : 
1 : 011018/AAB: scenarize the whole process - Done                                          
2 : 011018/AAB: check that you retrieve the right information from Salesforce - Done                                        
3 : 011018/AAB: make sure that the data is not from TRI - in progress                                           
4 :
*/

  public static Boolean alreadyExecutedAcceptor = false;

  public static final String xp_salesforce_endpoint = System.Label.LAB_SF_EndpointEDG_WS;
  public static final String xp_salesforce_clientId = System.Label.LAB_SF_Client_Id_WS;
  public static final String xp_salesforce_requester = System.Label.LAB_SF_Requester_WS;

  public static ER_Store__c store = new ER_Store__c();

  /*@future(callout = true)
public static void addAcceptorsFuture(Set <Id> acceptorId) {
addAcceptors(acceptorId);
}*/

  @future(callout=true)
  public static void updateAddStoreFuture(ID storeId) {
    updateAddStore(storeId);
  }

  /* Prepare the acceptor to be sent to the EDG services
   *
   */
  public static String updateAddStore(ID storeId) {
    store = [
      SELECT
        Id,
        ER_WS_result_Text__c,
        ER_Sync_result__c,
        ER_Website_URL__c,
        ER_Business_Unit__c,
        ER_Status__c,
        ER_Merchant__c,
        ER_Latitude_Longitude__Latitude__s,
        ER_Latitude_Longitude__Longitude__s,
        Name,
        ER_Contact__c,
        ER_Street__c,
        ER_City__c,
        ER_Zip_Code__c,
        ER_Creation_Date_In_OS__c,
        ER_Financial_Center__c,
        ER_Financial_Center__r.ER_Account_Name__c,
        ER_Financial_Center__r.ER_Creation_date_in_OS__c,
        ER_Last_Date_Of_Sync__c,
        ER_Contact__r.Fax,
        CZ_Store_reference__c,
        ER_Contact__r.Email,
        ER_Contact__r.Phone,
        ER_Contact__r.MobilePhone,
        ER_Contact__r.FirstName,
        ER_Contact__r.LastName,
        ER_Contact__r.Salutation,
        CreatedDate,
        ER_Brand__c,
        ER_E_Shop__c,
        ER_Contact__r.MailingStreet,
        ER_Contact__r.MailingCity,
        ER_Contact__r.MailingPostalCode,
        ER_Contact__r.MailingCountry,
        ER_Contact__r.MailingLatitude,
        ER_Description__c,
        ER_Do_not_publish__c,
        ER_Contact__r.MailingLongitude,
        ER_Contact__r.ER_BUPicklist__c,
        ER_Contact__r.CZ_AcademicTitle__c,
        (
          SELECT
            id,
            Name,
            ER_MID_Authorization__c,
            ER_AID_Authorization__c,
            ER_MCC_Authorization__c,
            ER_TID_Authorization__c,
            ER_TID_Clearing__c,
            ER_MID_Clearing__c,
            ER_AID_Clearing__c,
            ER_MCC_Clearing__c,
            ER_Card_Operational_System_ID__c,
            ER_Business_Unit__c
          FROM Acceptors__r
        )
      FROM ER_Store__c
      WHERE Id = :storeId
    ];

    Map<String, String> EdgMatrixError = WSHU02_SynchronizeMerchantWS.getEDGMatrices();

    System.debug('--- Which is related to the following financial center ? ' + store.ER_Financial_Center__c);

    ER_Financial_Center__c theInvC = [
      SELECT
        id,
        ER_Creation_date_in_OS__c,
        ER_Account_Name__c,
        ER_Paper_Operational_System_ID__c,
        ER_Card_Operational_System_ID__c
      FROM ER_Financial_Center__c
      WHERE id = :store.ER_Financial_Center__c
    ];

    String themerchant = store.ER_Financial_Center__r.ER_Account_Name__c;

    System.debug('--- The financial center ? ' + theInvC);

    HttpResponse res;

    System.debug('--- WSCZ01_SynchronizeStoreWS.callWSAddStore start ');
    if (
      store.ER_Creation_Date_In_OS__c == null &&
      theInvC.ER_Creation_date_in_OS__c != null &&
      store.CreatedDate >= theInvC.ER_Creation_date_in_OS__c
    ) {
      res = WSCZ01_SynchronizeStoreWS.callWSAddStore(store, themerchant, false); // creation
    } else {
      if (
        theInvC.ER_Creation_date_in_OS__c != null &&
        (store.CreatedDate < theInvC.ER_Creation_date_in_OS__c ||
        store.ER_Creation_date_in_OS__c != null)
      ) {
        res = WSCZ01_SynchronizeStoreWS.callWSAddStore(store, themerchant, true); // update
      } else {
        return null;
      }
    }
    System.debug('--- WSCZ01_SynchronizeStoreWS.callWSAddStore end ');

    System.debug(
      '--- The status code returned was : ' +
      res.getStatusCode() +
      ' ' +
      res.getStatus() +
      ' ' +
      res.getBody()
    );

    List<APHU05_EDGMessageHandler> myResponse = APHU05_EDGMessageHandler.parse(res.getBody());

    System.debug('--- The final message is : ' + myResponse);

    if (myResponse[0].meta.status == 'succeeded') {
      System.debug('--- Is success : ');
      store.ER_Creation_Date_In_OS__c = DateTime.now();
      store.ER_Last_Date_Of_Sync__c = DateTime.now();
      System.debug('--- ER_Creation_Date_In_OS__c Updated : ');
      store.ER_Sync_result__c = '1';
      store.ER_WS_result_Text__c = '';
      if (myResponse[0].data != null) {
        for (APHU05_EDGMessageHandler.data resp : myResponse[0].Data) {
          for (APHU05_EDGMessageHandler.Identifiers ident : resp.identifiers) {
            if (ident.authority == 'rs.store.technical_id') {
              store.ER_Card_Operational_System_ID__c = ident.reference;
            }
          }
        }

        //store.ER_WS_result_Text__c = 'Succeeded';
      }
    } else {
      System.debug('--- Is Error : ');
      String message = '';
      store.ER_Sync_result__c = '2';
      for (APHU05_EDGMessageHandler.Messages er : myResponse[0].meta.messages) {
        message += er.code + ' ';
      }
      //acceptors[0].ER_Last_date_of_Sync__c = DateTime.now();
      store.ER_WS_result_Text__c = message;
    }

    // Update the related account
    WSCZ01_SynchronizeStoreWS.alreadyExecutedAcceptor = true;
    System.debug('Stoooore :' + store);
    update store;
    System.debug('Stoooore Updated:' + store);
    return null;
  }

  public static HttpResponse callWSAddStore(ER_Store__c aStore, String aMerchant, Boolean isupdate) {
    String result;

    // Current date -- Ok
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));
    List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
    List<ER_Store_Line_Item__c> StrList = new List<ER_Store_Line_Item__c>();
    if (!isupdate) {
      cliList = [
        SELECT
          id,
          ER_IsActive__c,
          Name,
          ER_ProductCode__c,
          ER_Solution__c,
          ER_Product2__r.ER_Do_Not_Synchronize__c,
          ER_UnitPrice__c,
          ER_Percentage__c,
          ER_End_Date__c,
          ER_Minimum_Fee__c
        FROM ER_ContractLineItem__c
        WHERE
          ER_Contract__c IN (
            SELECT id
            FROM Contract
            WHERE AccountId = :aStore.ER_Merchant__c AND status = :Label.LABS_SF_Contract_Status_Activated
          )
      ];
    } else {
      StrList = [
        SELECT id, ER_Solution__c, ER_Solution__r.ProductCode, ER_Status__c
        FROM ER_Store_Line_Item__c
        WHERE ER_Store__c = :aStore.id AND ER_Status__c = :Label.LABS_SF_StoreLineItem_Accept
      ];
    }
    WSHU03_MerchantTemplateWS.Stores theStore = new WSHU03_MerchantTemplateWS.Stores(aStore, cliList, StrList);
    String body = JSON.serializePretty(theStore, true);
    System.debug('BODYYY' + body);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);
    String hmacToken;
    HttpRequest req;

    if (store.ER_Business_Unit__c == 'CZ') {
      if (isupdate) {
        hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(
          '/merchants/ds.merchant.technical_id-' +
          aMerchant +
          '/stores/ds.store.technical_id-' +
          aStore.id,
          afterblobToStringbis,
          currentDate
        );

        req = APHU06_CryptoTokenGeneration.getHttpRequest(
          '/merchants/ds.merchant.technical_id-' +
          aMerchant +
          '/stores/ds.store.technical_id-' +
          aStore.id,
          'PUT',
          hmacToken,
          currentDate,
          afterblobToStringbis
        );
      } else {
        hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(
          '/merchants/ds.merchant.technical_id-' +
          aMerchant +
          '/stores',
          afterblobToStringbis,
          currentDate
        );

        req = APHU06_CryptoTokenGeneration.getHttpRequest(
          '/merchants/ds.merchant.technical_id-' +
          aMerchant +
          '/stores',
          'POST',
          hmacToken,
          currentDate,
          afterblobToStringbis
        );
      }
    }
    Http h = new Http();
    HttpResponse res;
    res = h.send(req);
    return res;
  }
}