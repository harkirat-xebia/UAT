public with sharing class WSHU07_SynchronizeFinancialWS {
  /*
    ----------------------------------------------------------------------
    -- - Name          : WSHU07_SynchronizeFinancialWS
    -- - Author        : AAB
    -- - Description   : Process the WS callout to EDG for data synchronization 
    -- -                 Here is for the Financial center 
    -- Maintenance History:
    --
    -- Date         Name                Version     Remarks 
    -- -----------  -----------         --------    ---------------------------------------
    -- 16-MAI-2018  AAB                 1.0         Initial version
    -- 19-NOV-2018  AAB                 2.5         Change the response catch up from authority order to authority name 
    ---------------------------------------------------------------------------------------
To Do :                 
    1 : 011018/AAB: check that you retrieve the right information from Salesforce - Done                                            
    2 : 011018/AAB: key code need to be 99 absolutely, why is that (Mapping error, get the value into Bank in CMO) - Corrected
    3 : 011018/AAB: check that the merchant had been correctly created., no call to edg if not
    4 : 
    */

  public static Boolean alreadyExecutedFinancialCenter = false;
  public static Boolean isToUpdate = false;

  /*  All EDG call out attributes */
  /*public static final String xp_salesforce_endpoint = System.Label.LAB_SF_EndpointEDG_WS;
    public static final String xp_salesforce_clientId = System.Label.LAB_SF_Client_Id_WS;
    public static final String xp_salesforce_requester = System.Label.LAB_SF_Requester_WS;*/

  /* All Salesforce attributes */
  public static List<ER_Financial_Center__c> financialC;
  public static List<ER_Store__c> storeList;
  public static List<ER_Bank_Account__c> bankAccountlist;
  public static List<Contact> contactList;

  public static List<WSHU02_SynchronizeMerchantWS.wrapFinancialCenter> financialCW;
  public static String merchantID;
  public static List<String> responseToshow = new List<String>();

  @future(callout=true)
  public static void addupdateFinancialCentersFuture(Set<Id> merchantId) {
    addUpdateFinancialCenters(merchantId, false);
  }

  /* Prepare the merchant (Account/Financial Center) to be sent to the EDG services
   *
   */
  public static String[] addUpdateFinancialCenters(Set<Id> merchantId, Boolean fromAura) {
    System.debug('--- There are ' + merchantId.size() + ' merchants (Financial center) triggered, which are');
    System.debug('--- merchantIds : ' + merchantId);

    // retrieve needeed information -- financial center
    //financialC = WSHU02_SynchronizeMerchantWS.getFinancialCenters(merchantId,' and ER_Type__c = \'' + Label.LABS_SF_FinancialCenter_Merchant+'\'');
    financialC = WSHU02_SynchronizeMerchantWS.getFinancialCenters(merchantId, '');
    /* check that the related account (merchant) had been created properly */
    //if (financialC[0].ER_Account_Name__c == null || financialC[0].ER_Account_Name__r.ER_Creation_date_in_OS__c == null) {
    if (
      financialC[0].ER_Account_Name__c == null ||
      financialC[0].ER_Account_Name__r.ER_Creation_date_in_OS__c == null ||
      (financialC[0].ER_Business_Unit__c == 'HU' &&
      financialC[0].ER_Type__c != Label.LABS_SF_FinancialCenter_Merchant)
    ) {
      return null;
    }

    System.debug('--- The number of Financial center related (At least one) : ' + financialC.size());

    Set<Id> myFinCIds = new Set<Id>();

    System.debug(
      '--- financialC[0].ER_Creation_date_in_OS__c == null : ' + (financialC[0].ER_Creation_date_in_OS__c == null)
    );
    System.debug(
      '--- financialC[0].ER_Card_Operational_System_ID__c == null : ' +
      (financialC[0].ER_Card_Operational_System_ID__c == null)
    );

    isToUpdate = (!(financialC[0].ER_Creation_date_in_OS__c == null ||
    financialC[0].ER_Card_Operational_System_ID__c == null));
    System.debug('--- The Financial center (merchant) had been already created into the OS : ' + isToUpdate);

    /* Contruct the Financial center wrapper containing
     * Financial center information
     * Contact Information
     * Store information
     */
    financialCW = new List<WSHU02_SynchronizeMerchantWS.wrapFinancialCenter>();

    if (!isToUpdate) {
      // Set the financial center id(s) (to retrieve the related stores)
      for (ER_Financial_Center__c finCe : financialC) {
        myFinCIds.add(finCe.Id);
      }

      // retrieve the related stores
      storeList = WSHU02_SynchronizeMerchantWS.getStores(myFinCIds);

      System.debug('--- The number of Stores related to the Financial center (can be 0) : ' + storeList.size());

      System.debug('--- List of Financial center : ' + financialC);
      System.debug('--- List of related store : ' + storeList);

      System.debug('--- Affect the right store to the right invoice center : ');

      /* affect the right store to the right invoice center */
      for (ER_Financial_Center__c Ic : financialC) {
        List<ER_Store__c> mystoreList = new List<ER_Store__c>();

        for (ER_Store__c st : storeList) {
          if (st.ER_Financial_Center__c != null && st.ER_Financial_Center__c == Ic.Id) {
            mystoreList.add(st);
          }
        }

        System.debug('--- The following Financial center : ' + Ic.Id + ' is associated to the following stores');
        System.debug(
          '--- List of stores' + ((mystoreList.size() > 0) ? ' Here ' + mystoreList : ', there is no associated stores')
        );

        financialCW.add(
          new WSHU02_SynchronizeMerchantWS.wrapFinancialCenter(Ic, mystoreList.size() > 0 ? mystoreList : null)
        );
      }

      System.debug('--- Final Financial center Wrapper : ' + financialCW);
    } else if (isToUpdate) {
      financialCW.add(new WSHU02_SynchronizeMerchantWS.wrapFinancialCenter(financialC[0], null));
    }

    Map<String, String> EdgMatrixError = WSHU02_SynchronizeMerchantWS.getEDGMatrices();

    HttpResponse res;

    if (!isToUpdate) {
      /* is to create */
      System.debug('--- WSHU07_SynchronizeFinancialWS.callWSAddFinancialCenter start ');
      res = WSHU07_SynchronizeFinancialWS.callWSAddFinancialCenter(financialCW[0]);
      System.debug('--- WSHU07_SynchronizeFinancialWS.callWSAddFinancialCenter end ');
    } else {
      /* is to update */
      System.debug('--- WSHU07_SynchronizeFinancialWS.callWSUpdateFinancialCenter start ');
      res = WSHU07_SynchronizeFinancialWS.callWSUpdateFinancialCenter(financialCW[0]);
      System.debug('--- WSHU07_SynchronizeFinancialWS.callWSUpdateFinancialCenter end ');
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
    String status = myResponse[0].meta.status;

    System.debug('--- The final message is : ' + myResponse);

    /* if creation update the Card Operational System field */
    if (!isToUpdate) {
      List<ER_Financial_Center__c> icList = new List<ER_Financial_Center__c>();

      System.debug('--- Response on merchant creation ');

      if (myResponse == null || myResponse.size() < 1) {
        return null;
      }
      /* Loop through the success message */
      for (APHU05_EDGMessageHandler.data resp : myResponse[0].Data) {
        ER_Financial_Center__c fcToupdate = new ER_Financial_Center__c();

        // Loop through the reference to catch the merchant id and Card Operational System ID
        /**/ for (APHU05_EDGMessageHandler.Identifiers ident : resp.identifiers) {
          /* if (ident.authority == 'os-paper.merchant.technical_id' && financialC[0].ER_Business_Unit__c=='HU') { // For the merchant ID
                        // Add the merchant id
                        System.debug('--- The os-paper.merchant.technical_id ' + ident.reference);
                        fcToupdate.Id = (Test.isRunningTest() ? financialC[0].Id : ident.reference);
                    }
                    else if (ident.authority == 'os-card.merchant.technical_id' && financialC[0].ER_Business_Unit__c=='HU') {
                        // Add the card operational System
                        System.debug('--- os-card.merchant.technical_id ' + ident.reference);
                        fcToupdate.ER_Card_Operational_System_ID__c = ident.reference;
                    }
                    else*/ if (
            ident.authority == 'ds.invoicecenter.technical_id' /*&& financialC[0].ER_Business_Unit__c=='CZ'*/
          ) {
            // Add the card operational System
            System.debug('--- ds.invoicecenter.technical_id ' + ident.reference);
            fcToupdate.Id = ident.reference;
            if (Test.isRunningTest()) {
              fcToupdate.Id = financialC[0].Id;
            }
          } else if (
            ident.authority == 'rs.financial_center.technical_id' /*&& financialC[0].ER_Business_Unit__c=='CZ'*/
          ) {
            // Add the card operational System
            System.debug('--- rs.financial_center.technical_id ' + ident.reference);
            fcToupdate.ER_Card_Operational_System_ID__c = ident.reference;
          }
        }

        fcToupdate.ER_Creation_date_in_OS__c = DateTime.now();
        fcToupdate.ER_Last_Synchronization_Date__c = DateTime.now();
        fcToupdate.ER_Sync_result__c = 'synchronized';
        fcToupdate.ER_WS_result_Text__c = 'Succeeded';
        /**/

        System.debug('--- My Financial Center ' + fcToupdate);

        icList.add(fcToupdate); /*),*/

        /*icList.add(new ER_Financial_Center__c(
         Id = (Test.isRunningTest() ? financialC[0].Id : resp.identifiers[0].reference/*.substring(19, 37)*/
        /*ER_Creation_date_in_OS__c = DateTime.now(),
                    ER_Last_Synchronization_Date__c = DateTime.now(),
                    ER_Sync_result__c = '1',
                    ER_WS_result_Text__c = 'Succeeded',
                    ER_Card_Operational_System_ID__c = resp.identifiers[3].reference));*/
      }

      if (icList.size() == 0) {
        /* Loop through message errors */
        for (APHU05_EDGMessageHandler.Messages msg : myResponse[0].Meta.Messages) {
          icList.add(
            new ER_Financial_Center__c(
              Id = (Test.isRunningTest() ? financialC[0].Id : msg.ref),
              ER_Creation_date_in_OS__c = DateTime.now(),
              ER_Last_Synchronization_Date__c = DateTime.now(),
              ER_Sync_result__c = 'not_synchronized',
              ER_WS_result_Text__c = msg.description
            )
          );
        }
      }

      WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
      update icList;
    } else if (isToUpdate && status == 'succeeded') {
      /* if update / Success / Failure */
      /*financialC[0].ER_Last_Synchronization_Date__c = DateTime.now();
                financialC[0].ER_Sync_result__c = '1';
                financialC[0].ER_WS_result_Text__c = 'Succeeded';*/

      List<ER_Financial_Center__c> icList = new List<ER_Financial_Center__c>();
      icList.add(
        new ER_Financial_Center__c(
          Id = financialC[0].Id,
          ER_Last_Synchronization_Date__c = DateTime.now(),
          ER_Sync_result__c = 'synchronized',
          ER_WS_result_Text__c = 'Succeeded'
        )
      );

      WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
      update icList;
    } else {
      List<ER_Financial_Center__c> icList = new List<ER_Financial_Center__c>();
      icList.add(
        new ER_Financial_Center__c(
          Id = financialC[0].Id,
          ER_Last_Synchronization_Date__c = DateTime.now(),
          ER_Sync_result__c = 'not_synchronized',
          ER_WS_result_Text__c = myResponse[0].meta.messages[0].description
        )
      );

      WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;
      update icList;
    }
    return null;
  }

  // Merchants / Financial centers
  // Add merchants /Financial centers to WS
  public static HttpResponse callWSAddFinancialCenter(WSHU02_SynchronizeMerchantWS.wrapFinancialCenter aMerchant) {
    String result;

    // Current date -- Ok
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));

    /* Prepare the data to be sent sObject --> JSON
     * hashbody -- Ok
     */
    WSHU03_MerchantTemplateWS.Invoice_centers theMerchant = new WSHU03_MerchantTemplateWS.Invoice_centers(
      aMerchant.financialCenter,
      aMerchant.contact_inv,
      aMerchant.stores,
      aMerchant.bankAccount,
      false,
      true,
      null
    );

    String body = JSON.serializePretty(theMerchant, true);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);

    string mymerchantId = aMerchant.financialCenter.ER_Account_Name__c;

    // get the HmacToken to be send
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(
      '/merchants/ds.merchant.technical_id-' +
      mymerchantid +
      '/invoice-centers',
      afterblobToStringbis,
      currentDate
    );

    /**
     * send the merchant
     */
    Http h = new Http();

    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequest(
      '/merchants/ds.merchant.technical_id-' +
      mymerchantid +
      '/invoice-centers',
      'POST',
      hmacToken,
      currentDate,
      afterblobToStringbis
    );

    HttpResponse res;
    res = h.send(req);

    return res;
  }

  // Merchants
  // Add merchants to WS
  public static HttpResponse callWSUpdateFinancialCenter(WSHU02_SynchronizeMerchantWS.wrapFinancialCenter aMerchant) {
    String result;

    // Current date -- Ok
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));

    /* Prepare the data to be sent sObject --> JSON
     * hashbody -- Ok
     */
    WSHU03_MerchantTemplateWS.Invoice_centers theMerchant = new WSHU03_MerchantTemplateWS.Invoice_centers(
      aMerchant.financialCenter,
      aMerchant.contact_inv,
      aMerchant.stores,
      aMerchant.bankAccount,
      false,
      false,
      null
    );

    String body = JSON.serializePretty(theMerchant, true);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);

    String mymerchantid = aMerchant.financialCenter.ER_Account_Name__c;
    String myinvoiceCenterid = aMerchant.financialCenter.Id;

    // get the HmacToken to be send
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(
      '/merchants/ds.merchant.technical_id-' +
      mymerchantid +
      '/invoice-centers/ds.invoicecenter.technical_id-' +
      myinvoiceCenterid,
      afterblobToStringbis,
      currentDate
    );

    /**
     * send the merchant
     */
    Http h = new Http();

    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequest(
      '/merchants/ds.merchant.technical_id-' +
      mymerchantid +
      '/invoice-centers/ds.invoicecenter.technical_id-' +
      myinvoiceCenterid,
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