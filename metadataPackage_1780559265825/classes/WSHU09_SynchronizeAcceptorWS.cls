public with sharing class WSHU09_SynchronizeAcceptorWS {
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

  public static List<ER_Acceptor__c> acceptors;

  /*@future(callout = true)
public static void addAcceptorsFuture(Set <Id> acceptorId) {
addAcceptors(acceptorId);
}*/

  @future(callout=true)
  public static void updateAddAcceptorsFuture(Set<Id> acceptorId) {
    System.debug(' *DA update Acceptor future ' + acceptorId);
    updateAddAcceptors(acceptorId);
  }

  /* Prepare the acceptor to be sent to the EDG services
   *
   */
  public static String updateAddAcceptors(Set<Id> acceptorId) {
    System.debug('--- There are ' + acceptorId.size() + ' acceptors triggered, which are');
    System.debug('--- acceptancepointId : ' + acceptorId);

    // retrieve needeed information -- acceptance point
    acceptors = WSHU02_SynchronizeMerchantWS.getAcceptors(acceptorId);

    System.debug('--- List of acceptor : ' + acceptors);

    Map<String, String> EdgMatrixError = WSHU02_SynchronizeMerchantWS.getEDGMatrices();

    String thestore = acceptors[0].ER_Store__c;

    System.debug('--- Is related to the Folowing Store ? ' + thestore);

    String theFinancialCenter = acceptors[0].ER_Store__r.ER_Financial_Center__c;

    System.debug('--- Which is related to the following financial center ? ' + theFinancialCenter);

    String theacceptor = acceptors[0].ER_MID_Authorization__c;

    List<ER_Financial_Center__c> theInvC = [
      SELECT
        id,
        ER_Creation_date_in_OS__c,
        ER_Account_Name__c,
        ER_Paper_Operational_System_ID__c,
        ER_Card_Operational_System_ID__c
      FROM ER_Financial_Center__c
      WHERE id = :acceptors[0].ER_Store__r.ER_Financial_Center__c
    ];

    String themerchant = theInvC[0].ER_Account_Name__c;
    System.debug('--- The financial center ? ' + theInvC);

    HttpResponse res;
    if (acceptors[0].ER_Business_Unit__c == 'HU') {
      if (
        theInvC != null &&
        theInvC.size() > 0 &&
        theInvC[0].ER_Paper_Operational_System_ID__c != null &&
        theInvC[0].ER_Card_Operational_System_ID__c == null
      ) {
        System.debug('Hu is null?');
        return null;
      } else if (
        (acceptors[0].ER_Last_date_of_Sync__c == null) &&
        (acceptors[0].CreatedDate >= theInvC[0].ER_Creation_date_in_OS__c)
      ) {
        /* Add the acceptance */
        /* Add */
        System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSAddAcceptor start ');
        res = WSHU09_SynchronizeAcceptorWS.callWSAddAcceptor(acceptors[0], themerchant, true);
        System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSAddAcceptor end ');
      } else {
        /* Update the acceptance */
        if (theInvC[0].ER_Card_Operational_System_ID__c != null) {
          System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSUpdateAcceptor start ');
          res = WSHU09_SynchronizeAcceptorWS.callWSUpdateAcceptor(acceptors[0], themerchant, false);
          System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSUpdateAcceptor end ');
        } else {
          System.debug('Hu is null last else?');
          return null;
        }
      }
    } else if (acceptors[0].ER_Business_Unit__c == 'CZ') {
      if (
        (acceptors[0].ER_Last_date_of_Sync__c == null) &&
        (acceptors[0].CreatedDate >= theInvC[0].ER_Creation_date_in_OS__c) &&
        theInvC[0].ER_Card_Operational_System_ID__c != null
      ) {
        System.debug('CZ is null if');
        System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSAddAcceptor start ');
        res = WSHU09_SynchronizeAcceptorWS.callWSAddAcceptor(acceptors[0], themerchant, true);
        System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSAddAcceptor end ');
      } else {
        if (
          theInvC[0].ER_Card_Operational_System_ID__c != null &&
          ((acceptors[0].CreatedDate < theInvC[0].ER_Creation_date_in_OS__c) ||
          acceptors[0].ER_Last_date_of_Sync__c != null)
        ) {
          System.debug('CZ is null first else');
          System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSUpdateAcceptor start ');
          res = WSHU09_SynchronizeAcceptorWS.callWSUpdateAcceptor(acceptors[0], themerchant, false);
          System.debug('--- WSHU09_SynchronizeAcceptorWS.callWSUpdateAcceptor end ');
        } else {
          System.debug('CZ is null last else');
          return null;
        }
      }
    }
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
      acceptors[0].ER_Sync_result__c = '1';
      acceptors[0].ER_Last_date_of_Sync__c = DateTime.now();
      if (myResponse[0].data != null) {
        for (APHU05_EDGMessageHandler.data resp : myResponse[0].Data) {
          for (APHU05_EDGMessageHandler.Identifiers ident : resp.identifiers) {
            if (ident.authority == 'rs.acceptor.technical_id') {
              acceptors[0].ER_Card_Operational_System_ID__c = ident.reference;
            }
          }
        }
      }
    } else {
      System.debug('--- Is Error : ' + myResponse[0]);
      acceptors[0].ER_Sync_result__c = '2';
      String message = '';
      for (APHU05_EDGMessageHandler.Messages err : myResponse[0].meta.messages) {
        message += err.code + ' ';
      }
      //acceptors[0].ER_Last_date_of_Sync__c = DateTime.now();
      acceptors[0].ER_WS_result_Text__c = message;
    }
    // Update the related account
    WSHU09_SynchronizeAcceptorWS.alreadyExecutedAcceptor = true;
    update acceptors;
    return null;
  }

  // Merchants / Acceptance Points
  // Add merchants / Acceptance Points to WS
  public static HttpResponse callWSAddAcceptor(ER_Acceptor__c anAcceptor, String aMerchant, Boolean isComplex) {
    String result;

    // Current date -- Ok
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));

    /* Prepare the data to be sent sObject --> JSON
     * hashbody -- Ok
     */
    WSHU03_MerchantTemplateWS.Acceptance_point theAcceptancePoint = new WSHU03_MerchantTemplateWS.Acceptance_point(
      anAcceptor,
      false
    );

    String body = JSON.serializePretty(theAcceptancePoint, true);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);

    String theInvoiceCenter = anAcceptor.ER_Store__r.ER_Financial_Center__c;

    String themerchant = anAcceptor.ER_Store__r.ER_Merchant__c;

    String thestore = anAcceptor.ER_Store__c;
    //mid auth needs to be skipped for acceptor
    String theacceptor = anAcceptor.ER_MID_Authorization__c;
    String hmacToken;
    HttpRequest req;

    //if(anAcceptor.ER_Business_Unit__c == 'HU'){

    // get the HmacToken to be send
    // hmacToken = APHU06_CryptoTokenGeneration.getHmacToken('/merchants/ds.merchant.technical_id-' + aMerchant/*.substring(10, 18)*/
    //                                                     + '/invoice-centers/ds.invoicecenter.technical_id-' + theInvoiceCenter/*.substring(10, 18)*/
    //                                                   + '/stores/ds.store.technical_id-' + thestore/*.substring(10, 18)*/
    //                                                 + '/acceptance-points', afterblobToStringbis, currentDate);

    //req = APHU06_CryptoTokenGeneration.getHttpRequest('/merchants/ds.merchant.technical_id-' + aMerchant/*.substring(10, 18)*/
    //                                                + '/invoice-centers/ds.invoicecenter.technical_id-' + theInvoiceCenter/*.substring(10, 18)*/
    //                                              + '/stores/ds.store.technical_id-' + thestore/*.substring(10, 18)*/
    //                                            + '/acceptance-points', 'POST', hmacToken, currentDate, afterblobToStringbis);
    //} else if(anAcceptor.ER_Business_Unit__c == 'CZ'){

    // get the HmacToken to be send
    hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(
      '/merchants/ds.merchant.technical_id-' +
      aMerchant /*.substring(10, 18)*/ +
      '/stores/ds.store.technical_id-' +
      thestore /*.substring(10, 18)*/ +
      '/acceptance-points',
      afterblobToStringbis,
      currentDate
    );

    req = APHU06_CryptoTokenGeneration.getHttpRequest(
      '/merchants/ds.merchant.technical_id-' +
      aMerchant /*.substring(10, 18)*/ +
      '/stores/ds.store.technical_id-' +
      thestore /*.substring(10, 18)*/ +
      '/acceptance-points',
      'POST',
      hmacToken,
      currentDate,
      afterblobToStringbis
    );
    //}

    /**
     * send the acceptor
     */
    Http h = new Http();

    HttpResponse res;
    res = h.send(req);

    return res;
  }

  // Merchants / Acceptance Points
  // Add merchants / Acceptance Points to WS
  public static HttpResponse callWSUpdateAcceptor(ER_Acceptor__c anAcceptor, String aMerchant, Boolean isComplex) {
    String result;

    // Current date -- Ok
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));

    /* Prepare the data to be sent sObject --> JSON
     * hashbody -- Ok
     */
    WSHU03_MerchantTemplateWS.Acceptance_point theAcceptancePoint = new WSHU03_MerchantTemplateWS.Acceptance_point(
      anAcceptor,
      true
    );

    String body = JSON.serializePretty(theAcceptancePoint, true);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);

    String theInvoiceCenter = anAcceptor.ER_Store__r.ER_Financial_Center__c;
    String themerchant = anAcceptor.ER_Store__r.ER_Merchant__c;

    String thestore = anAcceptor.ER_Store__c;
    String theacceptor = anAcceptor.id;
    /*if(anAcceptor.ER_Business_Unit__c == 'HU')
        {    
         theacceptor = anAcceptor.ER_MID_Authorization__c;        
        } */
    // get the HmacToken to be send
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(
      '/merchants/ds.merchant.technical_id-' +
      aMerchant /*.substring(10, 18)*/ +
      '/stores/ds.store.technical_id-' +
      thestore /*.substring(10, 18)*/ +
      '/acceptance-points/ds.acceptancepoint.technical_id-' +
      theacceptor,
      afterblobToStringbis,
      currentDate
    );

    /**
     * send the acceptor
     */
    Http h = new Http();
    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequest(
      '/merchants/ds.merchant.technical_id-' +
      aMerchant /*.substring(10, 18)*/ +
      '/stores/ds.store.technical_id-' +
      thestore /*.substring(10, 18)*/ +
      '/acceptance-points/ds.acceptancepoint.technical_id-' +
      theacceptor,
      'PUT',
      hmacToken,
      currentDate,
      afterblobToStringbis
    );

    HttpResponse res;
    res = h.send(req);

    return res;
  }
}