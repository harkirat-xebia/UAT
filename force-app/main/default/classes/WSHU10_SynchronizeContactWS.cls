public with sharing class WSHU10_SynchronizeContactWS {
  //public with sharing class WSHU10_SynchronizeContactWS implements Queueable, Database.AllowsCallouts  {
  /*
    ----------------------------------------------------------------------
    -- - Name          : APHU10_SynchronizeContactWS
    -- - Author        : AAB
    -- - Description   : Process the WS callout to EDG for data synchronization 
    -- -                 Here is for the Contact 
    -- Maintenance History:
    --
    -- Date         Name                Version     Remarks 
    -- -----------  -----------         --------    ---------------------------------------
    -- 08-JUN-2018  AAB                 1.0         Initial version
    -- 28-JUN-2018  AAB                 2.0         Change in order to take into account both routes
    --                                              merchant/contact
    --                                              merchant/invoicecenter/contact
    -- 28-SEP-2018  AAB                 3.0         is able to manage one contact references in more than one financial center 

To Do :                                             
    1 : AAB/270918 : Improvement - The contact can be present in different Financial centers - in progress
                     Error : Too many queueble jobs added to queue : 2  --> batch
    2 :
    3 : 
    */

  public static Boolean alreadyExecutedContact = false;

  /* All EDG call out attributes */
  public static final String xp_salesforce_endpoint = System.Label.LAB_SF_EndpointEDG_WS;
  public static final String xp_salesforce_clientId = System.Label.LAB_SF_Client_Id_WS;
  public static final String xp_salesforce_requester = System.Label.LAB_SF_Requester_WS;

  /* All Salesforce attributes */
  public static List<Account> merchantList;
  public static List<ER_Financial_Center__c> invoiceC;
  public static List<Contact> contactList;
  public static List<Contact> contactAddList;
  public static Set<Id> merchantId;
  private String contactID;

  public static Boolean isHQContact = false;
  public static Boolean isInvContact = false;
  private static Boolean isInvContactFromQueue = false;
  private String FinCenter;

  // Contructor needed for data initialization later on
  /*
    public WSHU10_SynchronizeContactWS (String myConatctId, String myMerchantId) {
        System.debug('--- contactsId 1: ' + myConatctId);
        contactID = myConatctId;
        merchantId = new Set <Id>();
        merchantId.add(myMerchantId);
            
        isInvContactFromQueue = true;
        FinCenter = myMerchantId;
        System.debug('--- contactsId 1: ' + contactID + '\n isInvContactFromQueue ' + isInvContactFromQueue);
        System.debug('--- merchantId 1: ' + myMerchantId);
        
    }
    /*
    
    // Execute method that is the method that call the specified enqueue method
    /*
    public void execute(QueueableContext context) {
        Set<Id> myset = new Set<Id>();
        Set<Id> mysetbis = new Set<Id>();
        
        System.debug('---  execute(QueueableContext context)');
        System.debug('---  contactID ' + contactID);
        System.debug('---  merchantId ' + merchantId);
        
        myset.add(contactID);
        mysetbis.add(FinCenter);
        WSHU10_SynchronizeContactWS.alreadyExecutedContact = true;
        System.debug('--- contactsId 2: ' + myset + '\n isInvContactFromQueue ' + isInvContactFromQueue);
        updateContactsFuture(myset, mysetbis, true);
    }
    */

  /*
    @future(callout = true)
    public static void updateContactsFuture(Set <Id> contactId, Set <Id> merchantId, Boolean isFromQueue) {
        updateContacts(contactId, merchantId, isFromQueue);
    }
    */
  /* Prepare the acceptor to be sent to the EDG services
   *
   */
  /*
    public static void updateContacts(Set <Id> contactId, Set <Id> themerchantId, Boolean isFromQueue) {
        
        System.debug('--- There are '+ contactId.size() +  ' contacts triggered, which are' );
        System.debug('--- contactsId : ' + contactId);
        System.debug('--- Is from queue : ' + isFromQueue);
        System.debug('--- The financial center Id : ' + themerchantId);
        System.debug('--- The financial center Id 2: ' + merchantId);
        
        
        // retrieve needeed information -- contact
        contactList = WSHU02_SynchronizeMerchantWS.getContacts(contactId);
        
        System.debug('--- List of contact : ' + contactList);
        
        
        if (!isFromQueue) {
            merchantId = new Set<Id>();
        
            merchantId.add(contactList[0].AccountId);
            merchantList = WSHU02_SynchronizeMerchantWS.getMerchants(merchantId);
            
            System.debug('--- Associated merchant : ' + merchantList);
        } else {
            merchantId = themerchantId;
        }
        
        System.debug('--- my merchant Id set ' + merchantId);

        
        /* can return a list of financial center */
  /*
        invoiceC = WSHU02_SynchronizeMerchantWS.getFinancialCenters(merchantId, ' and ER_Type__c = \'' + Label.LABS_SF_FinancialCenter_Merchant+'\' and ER_Contact__c = ' + '\'' + contactList[0].Id + '\'');
        
        System.debug('--- List of invoice center : ' + invoiceC);
        */
  /* check if the contact is associated as HQ contact or Financial Center contact */
  /*
        if (merchantList != null && merchantList[0].ER_Creation_date_in_OS__c != null 
                &&  merchantList[0].HU_HQ_Contact__c != null 
                    && merchantList[0].HU_HQ_Contact__c == contactList[0].Id) { /* the contact correspond to a HQ contact */
  /*
                System.debug('--- Is a HQ contact : True ' + merchantList[0].HU_HQ_Contact__c);
                isHQContact = true;
        }
        
        Map<String, String> EdgMatrixError = WSHU02_SynchronizeMerchantWS.getEDGMatrices();
        
        HttpResponse res;
        */
  /* Switch case :
   * Is a HQ contact only --> call WS
   * Is one Financial center contact only --> call WS
   * Otherwise (HQ contact + Financial C contact or Financial C contact)
   *          --> call WS for HQ contact
   *          --> loop throught the Financial Center and enqueue with the Financial center ID (to take into consideration then)
   */

  /* check that the merchant is not from TRI */
  /*
        if(isHQContact && merchantList[0].ER_Paper_Operational_System_ID__c == null && merchantList[0].ER_Creation_date_in_OS__c != null) {
            System.debug('--- WSHU10_SynchronizeContactWS.callWSUpdateContact start - HQ & Inv');
            res = WSHU10_SynchronizeContactWS.callWSUpdateContact(contactList[0], null, isHQContact);
            System.debug('--- WSHU10_SynchronizeContactWS.callWSUpdateContact end - HQ & Inv');
            
             // Loop through the Financial center to enqueue the update contact FC
            if (invoiceC != null && invoiceC.size() > 0) {
                for (ER_Financial_Center__c fc : invoiceC) {
                    // Do a new call to the server
                    WSHU10_SynchronizeContactWS updatecontact = new WSHU10_SynchronizeContactWS(contactList[0].Id, fc.Id);
                    
                    // enqueue the job for processing
                    ID jobID = System.enqueueJob(updatecontact);
                }
            }
        } else if (!isFromQueue) {
            
            System.debug('--- Is not from queueu & is Financial Center contact ');
            
            // Loop through the Financial center to enqueue the update contact FC
            if (invoiceC != null && invoiceC.size() > 0) {
                for (ER_Financial_Center__c fc : invoiceC) {
                    // Do a new call to the server
                    WSHU10_SynchronizeContactWS updatecontact = new WSHU10_SynchronizeContactWS(contactList[0].Id, fc.Id);
                    
                    System.debug('--- financial center ' + fc.Id);
                    
                    // enqueue the job for processing
                    ID jobID = System.enqueueJob(updatecontact);
                }
            }
        } else if (isFromQueue  && invoiceC != null && invoiceC.size() == 1 && invoiceC[0].ER_Card_Operational_System_ID__c != null) {
                       
            System.debug('--- WSHU10_SynchronizeContactWS.callWSUpdateContact start - Inv only');
            res = WSHU10_SynchronizeContactWS.callWSUpdateContact(contactList[0], invoiceC[0].Id, false);
            System.debug('--- WSHU10_SynchronizeContactWS.callWSUpdateContact end - Inv only');
        } 
        
        if (res != null) {
            System.debug('--- The status code returned was : ' +
                         res.getStatusCode() + ' ' + res.getStatus() + ' ' + res.getBody());
        
        //AKO
        //System.debug('--- *** Not serialized message from EDG : ' + res.getBody());
        
        List<APHU05_EDGMessageHandler> myResponse = APHU05_EDGMessageHandler.parse(res.getBody()); 
        
        System.debug('--- The final message is : ' + myResponse);

        
        if (myResponse[0].meta.status == 'succeeded') {
            System.debug('--- Is success : ');
            contactList[0].ER_Last_date_of_Sync__c = DateTime.now();
        }
        
        else {
            System.debug('--- Is Error : ');
            //contactList[0].HU_Last_date_of_Sync__c = DateTime.now();
        }
            
        // Update the contacts
        WSHU10_SynchronizeContactWS.alreadyExecutedContact = true;
        update contactList;
        }
    }
    /*  
    
    
    
    // Merchants / Contact 
    // Update merchants / Contacts to WS 
    /*
    public static HttpResponse callWSUpdateContact(Contact aContact, Id InvoiceCID, Boolean isHQContact) {
        String result;
        
        // Current date -- Ok   
        String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));
       

        /* Prepare the data to be sent sObject --> JSON 
         * hashbody -- Ok
         */
  /*
        WSHU03_MerchantTemplateWS.Contacts theContact;
        
        if (isHQContact) {
            //theContact = new WSHU03_MerchantTemplateWS.Contacts(aContact, 'primary contact');
            System.debug('--- isHQContact recup info contact ' + aContact );
            Set <Id> AccId = new Set<Id>();
            AccId.add(aContact.AccountId);
            List<Account> accts = new List<Account>();
            accts = WSHU02_SynchronizeMerchantWS.getMerchants(AccId);
            System.debug('--- isHQContact recup info related account : ' + accts[0] );
            theContact = new WSHU03_MerchantTemplateWS.Contacts(aContact.FirstName, aContact.LastName, aContact.Salutation,
                                                                'primary contact', aContact.Fax, aContact.Email, 
                                                                aContact.Phone, aContact.MobilePhone, 
                                                                accts[0].BillingStreet, accts[0].BillingCity, accts[0].BillingPostalCode);
        }
            
        else {*/
  /* if Invoicing contact, there is a need to include the invoicing address */
  /*
            theContact = new WSHU03_MerchantTemplateWS.Contacts(aContact.FirstName, aContact.LastName, aContact.Salutation,
                                                                'primary contact', aContact.Fax, aContact.Email, 
                                                                aContact.Phone, aContact.MobilePhone, 
                                                                invoiceC[0].ER_Street__c, invoiceC[0].ER_City__c, invoiceC[0].ER_Zip_Code__c);
        }

        String body = JSON.serializePretty(theContact, true);
        String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);
        
        String themerchant = aContact.AccountId;
        String theinvoicecenter = InvoiceCID; 
        
        String hmacToken;
        */
  /**
   * send the acceptor
   */
  /*
        Http h = new Http();
        HttpRequest req;
        String myurl;
        
        if (isHQContact) {
            myurl = '/merchants/ds.merchant.technical_id-' + themerchant + '/contacts/ds.contact.technical_id-' + aContact.Id;
            
        } else {
            
            myurl = '/merchants/ds.merchant.technical_id-' + themerchant 
                                                                        + '/invoice-centers/ds.invoicecenter.technical_id-' + theinvoicecenter
                                                                         + '/contacts/ds.contact.technical_id-' + aContact.Id;

        }
        
        // get the HmacToken to be send
        hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(myurl, afterblobToStringbis, currentDate);
            
        req = APHU06_CryptoTokenGeneration.getHttpRequest(myurl, 'PUT', hmacToken, currentDate, afterblobToStringbis);

        HttpResponse res;
        res = h.send(req);

        return  res;
    }
    */

  @future(callout=true)
  public static void AddUpdateContactsFuture(Set<Id> contactId) {
    AddupdateContacts(contactId);
  }

  public static void AddupdateContacts(Set<Id> contactId) {
    contactAddList = WSHU02_SynchronizeMerchantWS.getContacts(contactId);
    Map<String, String> EdgMatrixError = WSHU02_SynchronizeMerchantWS.getEDGMatrices();

    HttpResponse res;
    res = callWSAddUpdateContact(contactAddList[0]);
    if (res != null) {
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
      APER15_LogMessage_Management.logMessage(
        APER15_LogMessage_Management.LogLevel.Error,
        'WSHU10',
        'AddupdateContacts',
        res.getBody(),
        true
      );

      if (myResponse[0].meta.status == 'succeeded') {
        System.debug('--- Is success : ');
        contactAddList[0].ER_Last_date_of_Sync__c = DateTime.now();
      } else {
        System.debug('--- Is Error : ');
      }

      // Update the contacts
      WSHU10_SynchronizeContactWS.alreadyExecutedContact = true;
      update contactAddList;
    }
  }

  public static HttpResponse callWSAddUpdateContact(Contact aContact) {
    // Current date -- Ok

    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));

    WSHU03_MerchantTemplateWS.Contacts theContact;
    /////////////////

    merchantId = new Set<Id>();
    merchantId.add(aContact.AccountId);
    merchantList = WSHU02_SynchronizeMerchantWS.getMerchants(merchantId);
    invoiceC = WSHU02_SynchronizeMerchantWS.getFinancialCenters(
      merchantId,
      ' and ER_Type__c = \'' +
      Label.LABS_SF_FinancialCenter_Merchant +
      '\' and ER_Contact__c = ' +
      '\'' +
      aContact.Id +
      '\''
    );

    /////////////////
    theContact = new WSHU03_MerchantTemplateWS.Contacts(aContact, aContact.ER_Role__c, merchantList, invoiceC);

    String body = JSON.serializePretty(theContact, true);
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);

    String themerchant = aContact.AccountId;

    String hmacToken;

    Http h = new Http();
    HttpRequest req;
    String myurl;
    myurl = '/merchants/ds.merchant.technical_id-' + themerchant + '/contacts/ds.contact.technical_id-' + aContact.id;

    // get the HmacToken to be send
    hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(myurl, afterblobToStringbis, currentDate);

    req = APHU06_CryptoTokenGeneration.getHttpRequest(myurl, 'PUT', hmacToken, currentDate, afterblobToStringbis);

    HttpResponse res;
    res = h.send(req);

    return res;
  }
}