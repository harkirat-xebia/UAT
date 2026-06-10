public with sharing class WSHU02_SynchronizeMerchantWS implements Queueable {
  /*
    ----------------------------------------------------------------------
    -- - Name          : WSHU02_SynchronizeMerchantWS
    -- - Author        : AAB
    -- - Description   : Process the WS callout to EDG for data synchronization
                         - Merchant creation/update
    -- Maintenance History:
    --
    -- Date         Name                Version     Remarks 
    -- -----------  -----------         --------    ---------------------------------------
    -- 28-FEB-2018  AAB                 1.0         Initial version
    -- 18-MAI-2018  AAB                 2.0         Add the update part
    -- 23-MAI-2018  AAB                 2.1         Integration test successfull
    -- 19-NOV-2018  AAB                 2.5         Change the response catch up from authority order to authority name 
    ---------------------------------------------------------------------------------------
To Do : 
                                                                                        
    1 : 270918/AAB : Optimisation - check that all Error message can be cached by the process -- in progress
                     including BAD REQUEST
                     Return JSON message to fetch with the standard of mobile and web development
    2 : 011018/AAB : changes the different credentials from Label to custom setting
    3 : 
    */

  public static Boolean alreadyExecutedAccount = false;
  public static Boolean alreadyExecutedFinancialCenter = false;
  public static Boolean isToUpdate = false;

  /*  All EDG call out attributes */
  /*public static final String xp_salesforce_endpoint = System.Label.LAB_SF_EndpointEDG_WS;
    public static final String xp_salesforce_clientId = System.Label.LAB_SF_Client_Id_WS;
    public static final String xp_salesforce_requester = System.Label.LAB_SF_Requester_WS;*/

  /* All Salesforce attributes */
  public static List<Account> merchantList;
  public static List<ER_Financial_Center__c> financialC;
  public static List<ER_Store__c> storeList;
  public static List<Contact> contactList;

  public static List<wrapFinancialCenter> financialCW;
  public static String merchantID;
  public static String contractID;
  public static List<String> responseToshow = new List<String>();

  // Contructor needed for data initialization for the queuing
  public WSHU02_SynchronizeMerchantWS(String myId, id ContratID) {
    merchantID = myId;
    contractID = ContratID;
  }

  // Execute method that is the method that call the specified enqueue method
  public void execute(QueueableContext context) {
    Set<Id> myset = new Set<Id>();
    myset.add(merchantID);
    WSHU02_SynchronizeMerchantWS.addMerchantsFuture(myset, ContractID);
  }

  @future(callout=true)
  public static void addMerchantsFuture(Set<Id> merchantId, ID contractId) {
    addUpdateMerchants(merchantId, false, contractId);
  }

  @future(callout=true)
  public static void updateMerchantsFuture(Set<Id> merchantId, ID contractId) {
    addUpdateMerchants(merchantId, false, contractId);
  }

  @AuraEnabled
  public static String[] addMerchantsAura(Id merchantId, ID contractId) {
    Set<Id> listofMerchant = new Set<Id>();
    listofMerchant.add(merchantId);

    System.debug('--- listofMerchant : ' + listofMerchant);
    return addUpdateMerchants(listofMerchant, true, contractId);
  }

  /* Prepare the merchant (Account) to be sent to the EDG services
   * and related records (financial center(s), store(s), etc.)
   */
  public static String[] addUpdateMerchants(Set<Id> merchantId, Boolean fromAura, ID contractId) {
    System.debug('--- There are ' + merchantId.size() + ' merchants triggered, which are');
    System.debug('--- merchantIds : ' + merchantId);

    // retrieve needed information from Salesforce
    merchantList = WSHU02_SynchronizeMerchantWS.getMerchants(merchantId);

    isToUpdate = merchantList[0].ER_Creation_date_in_OS__c != null;
    System.debug(
      '--- The merchant had been already created into the OS : ' + (merchantList[0].ER_Creation_date_in_OS__c != null)
    );

    // Check if it is a call is for a creation or an update
    if (isToUpdate == false && fromAura == true) {
      contactList = new List<Contact>();
      System.debug('1');
      // additional process
      /* get the financial center(s) and related stores/acceptors */
      financialC = WSHU02_SynchronizeMerchantWS.getFinancialCenters(
        merchantId,
        ' and ER_Type__c = \'' +
        Label.LABS_SF_FinancialCenter_Merchant +
        '\''
      ); /* is null for simple */
      Set<Id> myFinCIds = new Set<Id>();

      System.debug('--- The number of Financial center related to the merchant (At least one) : ' + financialC.size());

      /* Contruct the Financial center wrapper containing
       * Financial center information
       * Contact Information
       * Store information (Optional)
       */
      financialCW = new List<wrapFinancialCenter>();

      // For hungary merchant, the Head quarter contact is on the merchant entity
      //
      System.debug('--- The HQ contact exists (should be true) : ' + (merchantList[0].HU_HQ_Contact__c != null));

      if (merchantList[0].HU_HQ_Contact__c != null) {
        contactList.add(
          new Contact(
            Email = merchantList[0].HU_HQ_Contact__r.Email,
            Phone = merchantList[0].HU_HQ_Contact__r.Phone,
            MobilePhone = merchantList[0].HU_HQ_Contact__r.MobilePhone,
            Fax = merchantList[0].HU_HQ_Contact__r.Fax,
            FirstName = merchantList[0].HU_HQ_Contact__r.FirstName,
            LastName = merchantList[0].HU_HQ_Contact__r.LastName,
            Salutation = merchantList[0].HU_HQ_Contact__r.Salutation,
            MailingStreet = merchantList[0].HU_HQ_Contact__r.MailingStreet,
            MailingCity = merchantList[0].HU_HQ_Contact__r.MailingCity,
            MailingPostalCode = merchantList[0].HU_HQ_Contact__r.MailingPostalCode,
            MailingCountry = merchantList[0].HU_HQ_Contact__r.MailingCountry,
            MailingLatitude = merchantList[0].HU_HQ_Contact__r.MailingLatitude,
            MailingLongitude = merchantList[0].HU_HQ_Contact__r.MailingLongitude,
            Id = merchantList[0].HU_HQ_Contact__c
          )
        );
      }

      // Set the Financial center id(s) (to retrieve the related stores)
      for (ER_Financial_Center__c financialCe : financialC) {
        myFinCIds.add(financialCe.Id);
      }

      // Get the stores that are related to the invoice centers
      storeList = WSHU02_SynchronizeMerchantWS.getStores(myFinCIds);

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

        financialCW.add(new wrapFinancialCenter(Ic, mystoreList.size() > 0 ? mystoreList : null));
      }

      System.debug('--- Final Financial center Wrapper : ' + financialCW);
    }

    /* Wrapper class merchant
     * Account
     * Contact
     * ER_Financial_Center__c
     * ER_Store__c
     * ER_Acceptor__c
     * ER_Bank_Account__c
     */

    if (isToUpdate) {
      financialC = WSHU02_SynchronizeMerchantWS.getFinancialCenters(
        merchantId,
        ' and ER_Type__c = \'' +
        Label.LABS_SF_FinancialCenter_Merchant +
        '\' '
      );
    }

    Boolean hasMultipleIC = financialC.size() > 1 ? true : false;

    WSHU02_SynchronizeMerchantWS.wrapMerchant wMerchant = new WSHU02_SynchronizeMerchantWS.wrapMerchant(
      merchantList[0],
      isToUpdate ? null : contactList[0],
      isToUpdate ? null : financialCW,
      hasMultipleIC
    );

    System.debug('--- merchant wrapper : ' + wMerchant);

    Map<String, String> EdgMatrixError = WSHU02_SynchronizeMerchantWS.getEDGMatrices();

    // Loop through the list off merchant and call the API (EDG)
    //for (Account aMerchant: merchantList) {
    HttpResponse res;

    if (!isToUpdate) {
      System.debug('--- WSHU02_SynchronizeMerchantWS.callWSAddMerchant start ');
      system.debug('wMerchant format : ' + wMerchant);
      res = WSHU02_SynchronizeMerchantWS.callWSAddMerchant(wMerchant, contractId);
      System.debug('--- WSHU02_SynchronizeMerchantWS.callWSAddMerchant end ');
    } else {
      System.debug('--- WSHU02_SynchronizeMerchantWS.callWSUpdateMerchant start ');
      res = WSHU02_SynchronizeMerchantWS.callWSUpdateMerchant(wMerchant, contractId);
      System.debug('--- WSHU02_SynchronizeMerchantWS.callWSUpdateMerchant end ');
    }

    System.debug(
      '--- The status code returned was : ' +
      res.getStatusCode() +
      ' ' +
      res.getStatus() +
      ' ' +
      res.getBody()
    );

    /* Timeout, no response from the server */
    if (res.getStatusCode() == 500) {
      // response to the user
      responseToshow.add('failed');
      responseToshow.add('Something wrong on the server! Please contact the administrator to report the issue.');
      return responseToshow;
    }

    /* Parse the server response */
    List<APHU05_EDGMessageHandler> myResponse;

    try {
      myResponse = APHU05_EDGMessageHandler.parse(res.getBody());
    } catch (Exception e) {
      /* Can't parse the server response */
      // response to the user
      System.debug('--- Error message : ' + e.getMessage());
      responseToshow.add('failed');
      responseToshow.add('Unable to parse the server message.');
      return responseToshow;
    }

    String status = myResponse[0].meta.status;

    System.debug('--- The final message is : ' + myResponse);

    /* if creation update the Card Operational System field */
    //OLA 07112019: check if Data exist in the response before iteration.
    if (!isToUpdate && myResponse[0].Data != null) {
      List<ER_Financial_Center__c> icList = new List<ER_Financial_Center__c>();

      System.debug('--- Response on merchant creation ');
      system.debug('myResponse[0].Data : ' + myResponse[0].Data);

      //ER_Financial_Center__c fcToupdate = new ER_Financial_Center__c();
      Map<String, String> mapSolutionsCMOid = new Map<String, String>();
      /* Loop through the success message */
      for (APHU05_EDGMessageHandler.data resp : myResponse[0].Data) {
        system.debug('KHAAAAAAAD1');
        system.debug('KHAAAAAAAD2 : ' + resp.contractsProducts);
        if (resp.identifiers != null) {
          ER_Financial_Center__c fcToupdate = new ER_Financial_Center__c();
          system.debug('KHAAAAAAAD2');
          system.debug('KHAAAAAAAD2 : ' + resp.identifiers);
          // Loop through the reference to catch the merchant id and Card Operational System ID
          /**/
          for (APHU05_EDGMessageHandler.Identifiers ident : resp.identifiers) {
            system.debug('KHAAAAAAAD2.1');
            /*  if (ident.authority == 'External.Affiliate.ASRetailerUID' && financialC[0].ER_Business_Unit__c =='HU' ) { // For the merchant ID
                        // Add the merchant id
                        fcToupdate.Id = (Test.isRunningTest() ? financialC[0].Id : ident.reference);
                        system.debug('KHAAAAAAAD2.2');
                    }
                    else if (ident.authority == 'CMO.Affiliate.TechnicalID' && financialC[0].ER_Business_Unit__c =='HU') {
                        // Add the card operational System
                        fcToupdate.ER_Card_Operational_System_ID__c = ident.reference;
                        system.debug('KHAAAAAAAD2.3');
                    }
                    else */ if (
              ident.authority == 'rs.financial_center.technical_id' /*&& financialC[0].ER_Business_Unit__c ='CZ'*/
            ) {
              // Add the card operational System
              System.debug('--- rs.financial_center.technical_id ' + ident.reference);
              fcToupdate.ER_Card_Operational_System_ID__c = ident.reference;
            } else if (
              ident.authority == 'ds.invoicecenter.technical_id' /* && financialC[0].ER_Business_Unit__c =='CZ'*/
            ) {
              fcToupdate.Id = (Test.isRunningTest() ? financialC[0].Id : ident.reference);
              system.debug('cz temp fix ?');
            }
          }
          system.debug('KHAAAAAAAD3');
          fcToupdate.ER_Creation_date_in_OS__c = DateTime.now();
          fcToupdate.ER_Last_Synchronization_Date__c = DateTime.now();
          fcToupdate.ER_Sync_result__c = 'synchronized';
          fcToupdate.ER_WS_result_Text__c = 'Succeeded';
          /**/

          System.debug('--- My Financial Center ' + fcToupdate);

          icList.add(fcToupdate);
          System.debug('--- My icList ' + icList);
          wMerchant.merchant.ER_WS_result_Text_Long__c = 'Succeeded';
          System.debug('--- My icList after ');
          /* To comment begin - To delete */
          /*icList.add(new ER_Financial_Center__c(
                    Id = (Test.isRunningTest() ? financialC[0].Id : resp.identifiers[0].reference.substring(19, 37)), 
                    ER_Creation_date_in_OS__c = DateTime.now(),
                    ER_Last_Synchronization_Date__c = DateTime.now(),
                    ER_Sync_result__c = '1',
                    ER_WS_result_Text_Long__c = 'Succeeded',
                    ER_Card_Operational_System_ID__c = resp.identifiers.size() > 3 ? resp.identifiers[3].reference : resp.identifiers[2].reference));*/
          /* To comment end */

          /* update the accounnt */
          wMerchant.merchant.ER_Creation_date_in_OS__c = DateTime.now();
          wMerchant.merchant.ER_Last_date_of_Sync__c = DateTime.now();
          wMerchant.merchant.ER_WS_result_Text_Long__c = status;
          wMerchant.merchant.ER_Status__c = 'Active';
          system.debug(
            'KHAD resp  wMerchant.merchant.ER_WS_result_Text_Long__c : ' + wMerchant.merchant.ER_WS_result_Text_Long__c
          );
        }

        if (resp.contractsProducts != null) {
          for (APHU05_EDGMessageHandler.contractsProducts contProduct : resp.contractsProducts) {
            if (contProduct.product != null && String.isNotBlank(contProduct.product.product_ref)) {
              if (!mapSolutionsCMOid.containsKey(contProduct.product.product_ref)) {
                if (contProduct.refs != null && String.isNotBlank(contProduct.refs.reference)) {
                  mapSolutionsCMOid.put(contProduct.product.product_ref, contProduct.refs.reference);
                } else {
                  mapSolutionsCMOid.put(contProduct.product.product_ref, '');
                }
              }
            }
          }
        }
      }
      system.debug('KHAD resp before myset : ');
      Set<Id> myset = new Set<Id>();
      system.debug('KHAD resp : ' + myset);
      system.debug('KHAD resp meta.messages : ' + myResponse[0].Meta.Messages);
      /* Loop through message errors */
      for (APHU05_EDGMessageHandler.Messages msg : myResponse[0].Meta.Messages) {
        system.debug('Khad resp msg : ' + msg);
        system.debug('Khad resp wmerchant : ' + wMerchant);
        system.debug('Khad msg.ref: ' + msg.ref);
        if (myset.size() == 0 && !myset.contains(msg.ref)) {
          myset.add(msg.ref);

          wMerchant.merchant.ER_WS_result_Text_Long__c = status;
          if (msg.ref != null) {
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
      }
      system.debug('KHAD resp 3 : ' + myset);

      wMerchant.merchant.ER_Sync_result__c = (status == 'succeeded') ? 'synchronized' : 'not_synchronized';
      //wMerchant.merchant.ER_WS_result_Text_Long__c = EdgMatrixError.get(resp.meta.messages[0].description);

      /*if (res.getStatusCode() == 500) {
                // Do a new call to the server
                APHU02_SynchronizeMerchantWS createmerchant = new APHU02_SynchronizeMerchantWS(wMerchant.merchant.id);
                
                // enqueue the job for processing
                ID jobID = System.enqueueJob(createmerchant);
            }*/
      system.debug('Khad resp alreadyex');
      WSHU02_SynchronizeMerchantWS.alreadyExecutedAccount = true;
      WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter = true;

      APER05_DoNotRunTrigger bypassTrigger = new APER05_DoNotRunTrigger();
      bypassTrigger.setDoNotRunTrigger();

      System.debug('-- my list of invoice center to update ' + icList);

      update wMerchant.merchant;
      if (!icList.isempty() && !Test.isRunningTest()) {
        update icList;
      }
      //Update contract
      List<Contract> contractInst = APER12_Contract_Management.getContract(contractId);
      System.debug('-- mapSolutionsCMOid ' + mapSolutionsCMOid);
      System.debug('contractInst[0] : ' + contractInst.isEmpty());
      if (!mapSolutionsCMOid.isEmpty() && !contractInst.isEmpty()) {
        if (status == 'warning') {
          contractInst[0].ER_WS_StatusCode__c = '3';
          contractInst[0].ER_WS_Message_Long__c = myResponse[0].meta.messages[0].description;
          APHU12_Contract_Management.updateContractLineItemsFromWS(
            mapSolutionsCMOid,
            contractInst[0],
            true,
            'Activation'
          );
        } else {
          contractInst[0].ER_WS_StatusCode__c = '1';
          contractInst[0].ER_WS_Message_Long__c = status;
          APHU12_Contract_Management.updateContractLineItemsFromWS(
            mapSolutionsCMOid,
            contractInst[0],
            false,
            'Activation'
          );
        }
      } else {
        if (!Test.isRunningTest() && status != 'succeeded') {
          contractInst[0].ER_WS_StatusCode__c = '2';
          contractInst[0].ER_WS_Message_Long__c = myResponse[0].meta.messages[0].description;
          //contractInst.ER_Last_date_of_Sync__c = Datetime.now();
          update contractInst[0];
        }
        if (!Test.isRunningTest() && status == 'succeeded' && myResponse[0].Data != null) {
          contractInst[0].Status = Label.LABS_SF_Contract_Status_Activated;
          contractInst[0].ER_Creation_date_in_OS__c = Datetime.now();
          contractInst[0].ER_Offline__c = false;
          update contractInst[0];
        }
      }
    } else {
      /* if update / Success / Failure */
      if (myResponse[0].meta.status == 'succeeded') {
        wMerchant.merchant.ER_Sync_result__c = 'synchronized';
        wMerchant.merchant.ER_Last_date_of_Sync__c = DateTime.now();
        wMerchant.merchant.ER_WS_result_Text_Long__c = status;
      } else {
        wMerchant.merchant.ER_Sync_result__c = 'not_synchronized';
        wMerchant.merchant.ER_Last_date_of_Sync__c = DateTime.now();
        wMerchant.merchant.ER_WS_result_Text_Long__c = myResponse[0].meta.messages[0].description;
      }

      // Update the related account
      WSHU02_SynchronizeMerchantWS.alreadyExecutedAccount = true;
      update merchantList;
    }

    // response to the user
    responseToshow.add(myResponse[0].meta.status);

    responseToshow.add(
      myResponse[0].meta.messages.size() > 0 ? myResponse[0].meta.messages[0].code : myResponse[0].meta.status
    );

    return responseToshow;

    /*if (wMerchant.merchant.Sync_result__c == '1') {
            // Define the contract callout class
            APHU04_SynchronizeContractWS updateJob = new APHU04_SynchronizeContractWS(merchantList[0].id);
            // enqueue the job for processing
            ID jobID = System.enqueueJob(updateJob);
        }*/
  }

  // Merchants
  // Add merchants to WS
  public static HttpResponse callWSAddMerchant(wrapMerchant aMerchant, ID contractId) {
    String result;

    // Current date -- Ok
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));

    /* Prepare the data to be sent sObject --> JSON
     * hashbody -- Ok
     */
    WSHU03_MerchantTemplateWS.sAccount theMerchant = new WSHU03_MerchantTemplateWS.sAccount(
      aMerchant,
      true,
      contractId
    );
    String body = JSON.serializePretty(theMerchant, true);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);

    // get the HmacToken to be send
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacToken('/merchants', afterblobToStringbis, currentDate);

    /**
     * send the merchant
     */
    Http h = new Http();

    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequest(
      '/merchants',
      'POST',
      hmacToken,
      currentDate,
      afterblobToStringbis
    );

    HttpResponse res;
    res = h.send(req);

    return res;

    /*if (!Test.isRunningTest()) {
            res = h.send(req);
        }*/
  }

  // Merchants
  // Add merchants to WS
  public static HttpResponse callWSUpdateMerchant(wrapMerchant aMerchant, ID contractId) {
    String result;

    // Current date -- Ok
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));

    /* Prepare the data to be sent sObject --> JSON
     * hashbody -- Ok
     */
    WSHU03_MerchantTemplateWS.sAccount theMerchant = new WSHU03_MerchantTemplateWS.sAccount(
      aMerchant,
      false,
      contractId
    );

    String body = JSON.serializePretty(theMerchant, true);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);

    String themerchantId = aMerchant.merchant.id;

    // get the HmacToken to be send
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(
      '/merchants/ds.merchant.technical_id' +
      '-' +
      themerchantId /*.substring(10, 18)*/,
      afterblobToStringbis,
      currentDate
    );

    /**
     * send the merchant
     */
    Http h = new Http();

    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequest(
      '/merchants/ds.merchant.technical_id' +
      '-' +
      themerchantId,
      'PUT',
      hmacToken,
      currentDate,
      afterblobToStringbis
    );

    HttpResponse res;
    res = h.send(req);

    return res;
  }

  public static Map<String, String> getEDGMatrices() {
    Map<String, String> EdgMatrixError = new Map<String, String>();

    for (ER_EDG_Error_Matrix__mdt mt : [
      SELECT Id, MasterLabel, DeveloperName, toLabel(ER_Functional_Error__c)
      FROM ER_EDG_Error_Matrix__mdt
    ]) {
      EdgMatrixError.put(mt.MasterLabel, mt.ER_Functional_Error__c);
    }

    return EdgMatrixError;
  }

  // retrieve account list
  public static List<Account> getMerchants(Set<Id> merchantIdList) {
    String soql =
      'SELECT Id,ER_BUPicklist__c,ER_Registration_Number__c, Name, ER_Card_Operational_System_ID__c, ER_Paper_Operational_System_ID__c, ' +
      'Industry, ER_VAT_Number__c, CreatedDate, CreatedById, CreatedBy.email,OwnerId, owner.Email, ER_Status__c, ER_Insolvency_Executed_Account__c, ' +
      /* HQ contact information */
      'HU_HQ_Contact__c, ' +
      'HU_HQ_Contact__r.Email, HU_HQ_Contact__r.Phone, HU_HQ_Contact__r.MobilePhone, HU_HQ_Contact__r.Fax, ' +
      'HU_HQ_Contact__r.FirstName,HU_HQ_Contact__r.ER_BUPicklist__c,HU_HQ_Contact__r.CZ_AcademicTitle__c, HU_HQ_Contact__r.LastName, HU_HQ_Contact__r.Salutation, ' +
      'HU_HQ_Contact__r.MailingStreet, HU_HQ_Contact__r.MailingCity, HU_HQ_Contact__r.MailingPostalCode, ' +
      'HU_HQ_Contact__r.MailingCountry, HU_HQ_Contact__r.MailingLatitude, HU_HQ_Contact__r.MailingLongitude, ' +
      'ER_Creation_date_in_OS__c, ER_Last_date_of_Sync__c, ' +
      'BillingStreet, BillingCity, BillingPostalCode, ' +
      'BillingCountry, BillingLatitude, BillingLongitude ' +
      'FROM Account ' +
      'WHERE Id IN: merchantIdList';

    return Database.query(soql);
  }

  // retrieve contact list
  public static List<Contact> getContacts(Set<Id> contactsIdList) {
    String soql =
      'SELECT Id,CZ_AcademicTitle__c,  AccountId, Salutation, ER_Role__c, ER_BUPicklist__c,' +
      'Email, Phone, MobilePhone, ' +
      'Fax, FirstName, ' +
      'LastName, Title, Department, ' +
      'MailingStreet, MailingCity, MailingPostalCode, ' +
      'MailingCountry, MailingLatitude, MailingLongitude ' +
      'FROM Contact ' +
      'WHERE Id IN: contactsIdList';

    return Database.query(soql);
  }

  // retrieve Store list
  public static List<ER_Store__c> getStores(Set<Id> merchantIdList) {
    string firstelement = (new List<Id>(merchantIdList))[0];
    String mycondition = (firstelement.startsWithIgnoreCase('001')) ? 'ER_Merchant__c' : 'ER_Financial_Center__c';

    String soql =
      'SELECT Id,ER_Website_URL__c,ER_Brand__c,ER_Contact__r.ER_Role__c,CZ_Store_reference__c,CreatedDate,ER_E_Shop__c,ER_Do_not_publish__c,ER_Description__c,ER_Business_Unit__c, ER_Merchant__c, Name, ' +
      'ER_Contact__c, ER_Street__c, ER_City__c, ER_Creation_Date_In_OS__c,ER_Latitude_Longitude__Latitude__s,ER_Latitude_Longitude__Longitude__s,' +
      'ER_Zip_Code__c, ER_Financial_Center__c,ER_Financial_Center__r.ER_Creation_date_in_OS__c, ER_Contact__r.Fax, ' +
      'ER_Contact__r.Email, ER_Contact__r.Phone, ER_Contact__r.MobilePhone, ' +
      'ER_Contact__r.FirstName,ER_Contact__r.ER_BUPicklist__c,ER_Contact__r.CZ_AcademicTitle__c, ER_Contact__r.LastName, ER_Contact__r.Salutation, ' +
      'ER_Contact__r.MailingStreet, ER_Contact__r.MailingCity, ER_Contact__r.MailingPostalCode,ER_Status__c, ' +
      'ER_Contact__r.MailingCountry, ER_Contact__r.MailingLatitude, ER_Contact__r.MailingLongitude, ' +
      '( ' +
      'SELECT id, Name, ER_MID_Authorization__c , ER_AID_Authorization__c , ER_MCC_Authorization__c , ER_TID_Authorization__c, ' +
      'ER_TID_Clearing__c, ER_MID_Clearing__c , ER_AID_Clearing__c , ER_MCC_Clearing__c , ER_Card_Operational_System_ID__c, ER_Business_Unit__c,ER_Store__r.ER_Financial_Center__c ' +
      'FROM Acceptors__r) ' +
      'FROM ER_Store__c ' +
      'WHERE ' +
      mycondition +
      ' IN: merchantIdList';

    return Database.query(soql);
  }

  // retrieve acceptor list
  public static List<ER_Acceptor__c> getAcceptors(Set<Id> accpId) {
    return [
      SELECT
        id,
        Name,
        ER_MID_Authorization__c,
        ER_AID_Authorization__c,
        ER_MCC_Authorization__c,
        ER_TID_Authorization__c,
        ER_TID_Clearing__c,
        ER_Card_Operational_System_ID__c,
        ER_MID_Clearing__c,
        ER_AID_Clearing__c,
        ER_MCC_Clearing__c,
        ER_Store__r.ER_Financial_Center__c,
        ER_Store__r.ER_Merchant__c,
        ER_Store__r.ER_Creation_Date_In_OS__c,
        ER_Business_Unit__c,
        ER_Last_date_of_Sync__c,
        CreatedDate
      FROM ER_Acceptor__c
      WHERE Id IN :accpId
    ];
  }

  // retrieve Financial Center list
  public static List<ER_Financial_Center__c> getFinancialCenters(Set<Id> merchantIdList, String additionalCondition) {
    // Convert Set<Id> to Set<String>
    String themerchantId = ((List<String>) new List<Id>(merchantIdList))[0];

    String soql =
      'SELECT Id,ER_Business_Unit__c, ER_Account_Name__c, Name,ER_Email__c,ER_Secondary_Email__c, ' +
      'ER_Bank_Account__c, ER_Contact__c, ER_Street__c, ER_Type__c,' +
      'ER_City__c, ER_Zip_Code__c, ER_Contact__r.Fax,CreatedDate, ' +
      'ER_Card_Operational_System_ID__c, ER_Creation_date_in_OS__c, ER_Account_Name__r.ER_Creation_date_in_OS__c, ' +
      'ER_Paper_Operational_System_ID__c, ER_Account_Name__r.Name, ' +
      /* and referenced Bank Account*/
      'ER_Contact__r.FirstName,ER_Contact__r.ER_Role__c, ER_Contact__r.LastName,ER_Contact__r.CreatedDate, ' +
      'ER_Contact__r.Salutation, ER_Contact__r.Email, ' +
      'ER_Contact__r.Phone,ER_Contact__r.ER_BUPicklist__c,ER_Contact__r.CZ_AcademicTitle__c, ER_Contact__r.MobilePhone, ' +
      'ER_Contact__r.MailingStreet, ER_Contact__r.MailingCity, ER_Contact__r.MailingPostalCode, ' +
      'ER_Contact__r.MailingCountry, ER_Contact__r.MailingLatitude, ER_Contact__r.MailingLongitude, ' +
      /* and referenced Bank Account*/
      'ER_Bank_Account__r.Name, ER_Bank_Account__r.ER_Bank_Name__c, ' +
      'ER_Bank_Account__r.ER_Bank_Account_Number__c, ER_Bank_Account__r.ER_IBAN__c, ' +
      'ER_Bank_Account__r.ER_Bank_Account_Number_Prefix__c,ER_Bank_Account__r.CZ_Variable_symbol__c,ER_Bank_Account__r.CZ_Specific_symbol__c ' +
      'FROM ER_Financial_Center__c ' +
      'WHERE ';

    /* if an account id or an invoice center id */
    if (themerchantId.startsWithIgnoreCase('001')) {
      /* account id */
      soql += 'ER_Account_Name__c IN: merchantIdList';
    } else {
      soql += 'Id IN: merchantIdList';
    }

    soql += additionalCondition;

    System.debug('--- Invoice center request : ' + soql);

    System.debug('--- Invoice center request : ' + merchantIdList);

    return (List<ER_Financial_Center__c>) Database.query(soql);
  }

  // This is our wrapper/container class. In this example a wrapper class contains financial center records and related
  public class wrapFinancialCenter {
    public ER_Financial_Center__c financialCenter { get; set; }
    public List<ER_Store__c> stores { get; set; }
    public Contact contact_inv { get; set; }
    public ER_Bank_Account__c bankAccount { get; set; }

    public wrapFinancialCenter(ER_Financial_Center__c fc, List<ER_Store__c> stores) {
      this.financialCenter = fc;
      this.stores = new List<ER_Store__c>(stores);

      // if there is a bank account on the invoice center
      System.debug(
        '--- Is there any bank account referred to the financial center (always true) ' +
        fc.Id +
        ' ? ' +
        (fc.ER_Bank_Account__c != null)
      );
      System.debug(
        '--- Is there any contact referred to the financial center (always true ) ' +
        fc.Id +
        ' ? ' +
        (fc.ER_Contact__c != null)
      );

      this.bankAccount = (fc.ER_Bank_Account__c != null)
        ? new ER_Bank_Account__c(
            Id = fc.ER_Bank_Account__c,
            Name = fc.ER_Bank_Account__r.Name,
            ER_Bank_Name__c = fc.ER_Bank_Account__r.ER_Bank_Name__c,
            ER_Bank_Account_Number__c = fc.ER_Bank_Account__r.ER_Bank_Account_Number__c,
            ER_IBAN__c = fc.ER_Bank_Account__r.ER_IBAN__c,
            CZ_Variable_symbol__c = fc.ER_Bank_Account__r.CZ_Variable_symbol__c,
            CZ_Specific_symbol__c = fc.ER_Bank_Account__r.CZ_Specific_symbol__c,
            ER_Bank_Account_Number_Prefix__c = fc.ER_Bank_Account__r.ER_Bank_Account_Number_Prefix__c
          )
        : null;

      System.debug('--- The associated bank account is ' + bankAccount);

      if (fc.ER_Contact__c != null) {
        this.contact_inv = new Contact(
          Fax = fc.ER_Contact__r.Fax,
          FirstName = fc.ER_Contact__r.FirstName,
          LastName = fc.ER_Contact__r.LastName,
          Salutation = fc.ER_Contact__r.Salutation,
          Email = fc.ER_Contact__r.Email,
          ER_BUPicklist__c = fc.ER_Contact__r.ER_BUPicklist__c,
          Phone = fc.ER_Contact__r.Phone,
          MobilePhone = fc.ER_Contact__r.MobilePhone,
          ER_Role__c = fc.ER_Contact__r.ER_Role__c,
          CZ_AcademicTitle__c = fc.ER_Contact__r.CZ_AcademicTitle__c,
          MailingStreet = fc.ER_Contact__r.MailingStreet,
          MailingCity = fc.ER_Contact__r.MailingCity,
          MailingPostalCode = fc.ER_Contact__r.MailingPostalCode,
          Id = fc.ER_Contact__r.Id,
          MailingCountry = fc.ER_Contact__r.MailingCountry,
          MailingLatitude = fc.ER_Contact__r.MailingLatitude,
          MailingLongitude = fc.ER_Contact__r.MailingLongitude,
          CreatedDate = fc.ER_contact__r.CreatedDate
        );
      }

      System.debug('--- The associated contact is ' + contact_inv);
    }
  }

  // This is our wrapper/container class. In this example a wrapper class contains merchant records and related
  public class wrapMerchant {
    public Account merchant { get; set; }
    public Contact contact_hq { get; set; }
    public Boolean multipleInvoiceCenter { get; set; }

    // Financial center wrapper in order to include the stores and contact in it
    public List<wrapFinancialCenter> financialCenterW { get; set; }

    public wrapMerchant(Account m, Contact ct_hq, List<wrapFinancialCenter> fc, Boolean multipleIC) {
      this.merchant = m;
      this.contact_hq = ct_hq;
      this.multipleInvoiceCenter = multipleIC;

      this.financialCenterW = fc;
    }

    public wrapMerchant(Account m, Contact ct_hq) {
      this.merchant = m;
      this.contact_hq = ct_hq;
    }
  }
}