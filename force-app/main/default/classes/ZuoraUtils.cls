/**
 * @author : AAZ
 * @date : 28/06/2021
 * @desc : ZuoraUtils
 * @see ZuoraUtils
 */

public with sharing class ZuoraUtils {
  /**
   * @author AAZ
   * @date 28/06/2021
   * @description Get Zuora OAuth Token
   *
   * @return String
   */
  public static String getZuoraToken() {
    String clientId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_CLIENTID);
    String clientSecret = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_CLIENTSECRET);
    String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);
    String oAuthToken;

    if (String.isNotBlank(clientId) && String.isNotBlank(clientSecret) && String.isNotBlank(endpoint)) {
      HttpRequest req = new HttpRequest();
      Http http = new Http();
      HttpResponse resp;

      try {
        req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_OAUTH);
        req.setMethod(Constants.POST_METHOD);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String payload =
          'grant_type=client_credentials&client_id=' +
          EncodingUtil.urlEncode(clientId, 'UTF-8') +
          '&client_secret=' +
          EncodingUtil.urlEncode(clientSecret, 'UTF-8');
        req.setBody(payload);

        resp = http.send(req);
        if (resp.getStatusCode() == 200) {
          Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          //System.debug('>>>>> AAZ - mapRespData : ' + mapRespData);
          oAuthToken = mapRespData.get(Constants.ZUORA_RESPONSE_ACCESS_TOKEN).toString();
        }
      } catch (CalloutException ce) {
        System.debug('>>>>> AAZ - getZuoraToken CalloutException : ' + ce.getMessage());
      }
    }

    return oAuthToken;
  }

  /**
   * @author AAZ
   * @date 25/06/2021
   * @description update Zuora Customer Account after an update in SF
   * @param listObjToSync
   * @param token
   */
  public static void updateZuoraAccounts(List<Sobject> listObjToSync, String token) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);

    try {
        for(Sobject obj :listObjToSync){
            ER_Financial_Center__c updatedFC;
            Zuora__CustomerAccount__c updatedAcc;
            zqu__Quote__c updatedZQ;
            String entityId;
            String BillAccNumber;
            Map<String, Object> billingAccount = new Map <String, Object>();

            //If this Method is Called from FinancialCenter Trigger
            if(obj instanceof ER_Financial_Center__c) {
                updatedFC = (ER_Financial_Center__c) obj;
                entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + updatedFC.ER_Business_Unit__c);
                BillAccNumber =  updatedFC.Billing_Accounts__r[0].Zuora__AccountNumber__c;
                req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACCOUNT + BillAccNumber);
                
                List<String> additionalEmailAddresses = new List<String>();
                if(String.isNotBlank(updatedFC.ER_Email__c)) additionalEmailAddresses.add((String.isNotBlank(updatedFC.ER_Email__c) ? updatedFC.ER_Email__c : ''));
                if(String.isNotBlank(updatedFC.ER_Secondary_Email__c)) additionalEmailAddresses.add((String.isNotBlank(updatedFC.ER_Secondary_Email__c) ? updatedFC.ER_Secondary_Email__c : ''));

                String sequenceSetId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_SEQUENCESET + updatedFC.ER_Type__c.toUpperCase() + '_' + updatedFC.ER_Business_Unit__c);
                billingAccount.put('sequenceSetId', sequenceSetId);
                billingAccount.put('SEQUENCE_SET__c', (updatedFC.ER_Type__c == Constants.FC_MERCHANT_TYPE ? Constants.SEQUENCE_AFFILIATE : Constants.SEQUENCE_CUSTOMER));
                billingAccount.put('IBAN__c', updatedFC.ER_Bank_Account__r.ER_IBAN__c);
                billingAccount.put('name', updatedFC.Name);
                billingAccount.put('salesRep', updatedFC.Owner.Name);
                billingAccount.put('additionalEmailAddresses', additionalEmailAddresses);
                billingAccount.put('ER_Customer_Number__c', updatedFC.ER_Account_Name__r.ER_Customer_Number__c);
                billingAccount.put('ER_Registration_Number__c', updatedFC.ER_Account_Name__r.ER_Registration_Number__c);

                Map<String, Object> billingToContact = new Map <String, Object>();
                billingToContact.put('CRM_CONTACT_ID__c', updatedFC.ER_Contact__c);
                billingToContact.put('firstName', updatedFC.ER_Contact__r.FirstName);
                billingToContact.put('lastName', updatedFC.ER_Contact__r.LastName);
                billingToContact.put('workEmail', updatedFC.ER_Contact__r.Email);
                billingToContact.put('address1', updatedFC.ER_Invoicing_Street__c);
                billingToContact.put('city', updatedFC.ER_Invoicing_City__c);
                billingToContact.put('state', updatedFC.ER_Invoicing_Region_State__c);
                billingToContact.put('zipCode', updatedFC.ER_Invoicing_Zip_Code__c);
                billingToContact.put('country', updatedFC.ER_Invoicing_Country_Code__c);
                billingToContact.put('COUNTRY_NAME__c', updatedFC.ER_Invoicing_Country__c);
                billingToContact.put('fax', String.isNotBlank(updatedFC.ER_Contact__r.Fax) ? updatedFC.ER_Contact__r.Fax : '');
                billingToContact.put('workPhone', updatedFC.ER_Contact__r.Phone);
                billingAccount.put('billToContact', billingToContact);

                Map<String, Object> soldToContact = new Map <String, Object>();
                soldToContact.put('CRM_CONTACT_ID__c', updatedFC.ER_Contact__c);
                soldToContact.put('firstName', updatedFC.ER_Contact__r.FirstName);
                soldToContact.put('lastName', updatedFC.ER_Contact__r.LastName);
                soldToContact.put('workEmail', updatedFC.ER_Contact__r.Email);
                soldToContact.put('address1', updatedFC.ER_Invoicing_Street__c);
                soldToContact.put('city', updatedFC.ER_Invoicing_City__c);
                soldToContact.put('state', updatedFC.ER_Invoicing_Region_State__c);
                soldToContact.put('zipCode', updatedFC.ER_Invoicing_Zip_Code__c);
                soldToContact.put('country', updatedFC.ER_Invoicing_Country_Code__c);
                soldToContact.put('COUNTRY_NAME__c', updatedFC.ER_Invoicing_Country__c);
                soldToContact.put('fax', String.isNotBlank(updatedFC.ER_Contact__r.Fax) ? updatedFC.ER_Contact__r.Fax : '');
                soldToContact.put('workPhone', updatedFC.ER_Contact__r.Phone);
                billingAccount.put('soldToContact', soldToContact);
            }

            //If this Method is Called from SF Account Trigger or Bank Account Trigger
            if(obj instanceof Zuora__CustomerAccount__c) {
                updatedAcc = (Zuora__CustomerAccount__c) obj;
                entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + updatedAcc.Zuora__Account__r.ER_BUPicklist__c);
                BillAccNumber =  updatedAcc.Zuora__Zuora_Id__c;
                req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACCOUNT + BillAccNumber);

                billingAccount.put('LEGAL_NAME__c', (String.isNotBlank(updatedAcc.Zuora__Account__r.ER_Legal_Name__c) ? updatedAcc.Zuora__Account__r.ER_Legal_Name__c : updatedAcc.Zuora__Account__r.Name));
                billingAccount.put('IBAN__c', (String.isNotBlank(updatedAcc.ER_Financial_Center__r.ER_Bank_Account__r.ER_IBAN__c) ? updatedAcc.ER_Financial_Center__r.ER_Bank_Account__r.ER_IBAN__c : ''));
                
                //Populate the Tax Info
                Map<String, Object> taxInfo = new Map <String, Object>();
                taxInfo.put('VATId', (String.isNotBlank(updatedAcc.Zuora__Account__r.ER_VAT_Number__c) ? updatedAcc.Zuora__Account__r.ER_VAT_Number__c : ''));
                taxInfo.put('exemptStatus', (updatedAcc.Zuora__Account__r.ER_Not_subject_to_VAT__c ? Constants.YES : Constants.NO));
                taxInfo.put('exemptEntityUseCode', (updatedAcc.Zuora__Account__r.ER_Not_subject_to_VAT__c ? Constants.ZUORA_EXEMPT_NOVAT : ''));
                billingAccount.put('taxInfo', taxInfo);
                                   
                if(updatedAcc.ER_Financial_Center__r.ER_SmartER_Context__c) {
                    billingAccount.put('ER_BillingStreet__c', String.isNotBlank(updatedAcc.Zuora__Account__r.BillingStreet) ? updatedAcc.Zuora__Account__r.BillingStreet : '');
                    billingAccount.put('ER_BillingCity__c', String.isNotBlank(updatedAcc.Zuora__Account__r.BillingCity) ? updatedAcc.Zuora__Account__r.BillingCity : '');
                    billingAccount.put('ER_BillingPostalCode__c', String.isNotBlank(updatedAcc.Zuora__Account__r.BillingPostalCode) ? updatedAcc.Zuora__Account__r.BillingPostalCode : '');
                    billingAccount.put('ER_BillingState__c', String.isNotBlank(updatedAcc.Zuora__Account__r.BillingState) ? updatedAcc.Zuora__Account__r.BillingState : '');
                    billingAccount.put('ER_BillingCountry__c', String.isNotBlank(updatedAcc.Zuora__Account__r.BillingCountry) ? updatedAcc.Zuora__Account__r.BillingCountry : '');
                    billingAccount.put('ER_Country_Code__c', String.isNotBlank(updatedAcc.Zuora__Account__r.ER_Country_Code__c) ? updatedAcc.Zuora__Account__r.ER_Country_Code__c : '');
                }
            }
            
            //If this Method is Called from zQuote trigger
            if(obj instanceof zqu__Quote__c) {
                System.debug('>>>>> AAZ updateZuoraAccounts - zqu__Quote__c : ' + obj);
                updatedZQ = (zqu__Quote__c) obj;
                entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + updatedZQ.ER_Business_Unit__c);
                BillAccNumber =  updatedZQ.zqu__ZuoraAccountID__c;
                req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACCOUNT + BillAccNumber);
                
                 String paymentMethod;
                //Get Payment method Id
                String scope = (updatedZQ.zqu__Opportunity__r.RecordType.DeveloperName == Constants.OPPORTUNITY_MERCHANT_RT ? Constants.MERCHANT_UNDERSCORE : Constants.CLIENT_UNDERSCORE);
                if(updatedZQ.zqu__PaymentMethod__c == 'Wire Transfer') paymentMethod = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_PAYMENTMETHOD_WIRETRANSFER + scope + updatedZQ.ER_Business_Unit__c);
                if(updatedZQ.zqu__PaymentMethod__c == 'Credit Card') paymentMethod = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_PAYMENTMETHOD_CREDITCARD +  scope + updatedZQ.ER_Business_Unit__c);
                if(updatedZQ.zqu__PaymentMethod__c == 'Bank Transfer') paymentMethod = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_PAYMENTMETHOD_BANKTRANSFER +  scope + updatedZQ.ER_Business_Unit__c);
                if(updatedZQ.zqu__PaymentMethod__c == 'Other') paymentMethod = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_PAYMENTMETHOD_OTHER +  scope + updatedZQ.ER_Business_Unit__c);
                
                billingAccount.put('paymentTerm', updatedZQ.zqu__PaymentTerm__c);
                billingAccount.put('defaultPaymentMethodId', paymentMethod);
                System.debug('>>>>> AAZ updateZuoraAccounts - billingAccount : ' + billingAccount);
            }

            if(Limits.getCallouts() < Limits.getLimitCallouts() && entityId != null) {
                System.debug('>>>>> AAZ updateZuoraAccounts - entityId : ' + entityId);
                req.setHeader('entityId', entityId);
                req.setMethod(Constants.PUT_METHOD);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Accept', 'application/json');
                req.setHeader('Authorization', 'bearer ' + token);

                String payload = JSON.serialize(billingAccount);
                System.debug('>>>>> AAZ updateZuoraAccounts - payload : ' + payload);
                req.setBody(payload);
                Zuora.zApi zApiInstance = new Zuora.zApi();
                
                if(!Test.isRunningTest()) resp = zApiInstance.sendRequest(req);
                else resp = SendToZuoraMock.respond(req);

                if(resp.getStatusCode() == 200) {
                    Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                    System.debug('>>>>> AAZ updateZuoraAccounts - mapRespData : ' + mapRespData);
                }
            }
        }
    } catch(CalloutException ex) {
        System.debug('>>>>> AAZ - updateZuoraAccounts CalloutException : ' + ex.getMessage());
    }
}

  /**
   * @author AAZ
   * @date 28/09/2021
   * @description get ALl Zuora Pricebook entries
   * @return
   */
  public static Map<Id, Id> getZuoraPriceBookEntries() {
    Map<Id, Id> mapSolutionPBE = new Map<Id, Id>();
    for (PricebookEntry p : [
      SELECT Id, Pricebook2Id, Product2Id, Product2.Name
      FROM PricebookEntry
      WHERE Pricebook2.Name = :Constants.STANDARD_PRICE_BOOK AND IsActive = TRUE AND Product2.zqu__ZuoraId__c != NULL
    ]) {
      mapSolutionPBE.put(p.Product2Id, p.Id);
    }

    return mapSolutionPBE;
  }

  /**
   * @author AAZ
   * @description update PaymentTerm for the Zuora Customer Account
   * @param newPaymentTerm
   * @param ba
   * @param zuoraToken
   *
   * @return
   */
  public static String updateZuoraAccountPaymentTerm(
    String newPaymentTerm,
    Zuora__CustomerAccount__c ba,
    String zuoraToken
  ) {
    ER_Financial_Center__c fc = null;
    if (ba != null && ba.ER_Financial_Center__c != null) {
      fc = [SELECT Id, ER_BUPicklist__c FROM ER_Financial_Center__c WHERE Id = :ba.ER_Financial_Center__c];
      updateZuoraAccountPaymentTerm(newPaymentTerm, ba.Zuora__AccountNumber__c, fc.ER_BUPicklist__c, zuoraToken);
    }

    return null;
  }

  /**
   * @author AAZ
   * @date 21/10/2021
   * @description update PaymentTerm for the Zuora Customer Account
   * @param newPaymentTerm
   * @param BillAccNumber
   * @param BU
   * @param zuoraToken
   * @return String
   */
  public static String updateZuoraAccountPaymentTerm(
    String newPaymentTerm,
    String BillAccNumber,
    String BU,
    String zuoraToken
  ) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    Map<String, Object> billingAccount = new Map<String, Object>();

    System.debug('>>>>> AAZ updateZuoraAccountPaymentTerm - BillAccNumber : ' + BillAccNumber);

    try {
      BU = (String.isBlank(BU) ? UtilsBypass.getCurrentUser().ER_Business_Unit__c : BU);
      String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);
      String entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + BU);

      billingAccount.put('paymentTerm', newPaymentTerm);

      if (entityId != null) {
        req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACCOUNT + BillAccNumber);

        req.setHeader('entityId', entityId);
        req.setMethod(Constants.PUT_METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'bearer ' + zuoraToken);

        String payload = JSON.serialize(billingAccount);
        System.debug('>>>>> AAZ updateZuoraAccountPaymentTerm - payload : ' + payload);
        req.setBody(payload);
        Zuora.zApi zApiInstance = new Zuora.zApi();

        if (!Test.isRunningTest())
          resp = zApiInstance.sendRequest(req);
        else
          resp = SendToZuoraMock.respond(req);

        if (resp.getStatusCode() == 200) {
          Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          System.debug('>>>>> AAZ updateZuoraAccountPaymentTerm - mapRespData : ' + mapRespData);

          if (mapRespData.get('success') == false) {
            throw new CalloutException(Label.LAB_SF_BILLING_ACCOUNT_UUPDATE_ERROR);
          }
        } else {
          throw new CalloutException(Label.LAB_SF_BILLING_ACCOUNT_UUPDATE_ERROR);
        }
      }
    } catch (Exception ex) {
      System.debug('>>>>> AAZ - updateZuoraAccountPaymentTerm Exception : ' + ex.getMessage());
      return ex.getMessage();
    }

    return 'SUCCESS';
  }

  /**
   * @author AAZ
   * @date 28/10/2021
   * @description get Credit Or Debit Memo PDF
   * @param creditMemo
   * @param debitMemo
   * @param BU
   * @param zuoraToken
   * @return Blob
   */
  public static String getCreditOrDebitMemoPDF(String creditMemo, String debitMemo, String BU, String zuoraToken) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    String body;

    System.debug('>>>>> AAZ getCreditOrDebitMemoPDF - creditMemo : ' + creditMemo);

    try {
      BU = (String.isBlank(BU) ? UtilsBypass.getCurrentUser().ER_Business_Unit__c : BU);
      String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);
      String entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + BU);

      if (entityId != null) {
        if (String.isNotBlank(creditMemo))
          req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_CREDITMEMOS + creditMemo);
        else if (String.isNotBlank(debitMemo))
          req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_DEBITMEMOS + debitMemo);

        req.setHeader('entityId', entityId);
        req.setMethod(Constants.GET_METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'bearer ' + zuoraToken);

        Zuora.zApi zApiInstance = new Zuora.zApi();

        if (!Test.isRunningTest())
          resp = zApiInstance.sendRequest(req);
        else
          resp = SendToZuoraMock.respond(req);

        if (resp.getStatusCode() == 200) {
          Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          System.debug(
            '>>>>> AAZ getCreditOrDebitMemoPDF - mapRespData : ' + mapRespData.get(Constants.ZUORA_RESPONSE_PDF_FILEID)
          );

          if (mapRespData.get(Constants.ZUORA_RESPONSE_PDF_FILEID) != null) {
            body = getFile((String) mapRespData.get(Constants.ZUORA_RESPONSE_PDF_FILEID), BU, zuoraToken);
            System.debug('>>>>> AAZ getFile - BLOB : ' + body);
          }
        } else {
          throw new CalloutException(resp.getBody());
        }
      }
    } catch (Exception ex) {
      System.debug('>>>>> AAZ - getCreditOrDebitMemoPDF Exception : ' + ex.getMessage());
      return null;
    }

    return body;
  }

  /**
   * @author AAZ
   * @date 28/10/2021
   * @description get File by Id
   * @param fileId
   * @param BU
   * @param zuoraToken
   * @return Blob
   */
  public static String getFile(String fileId, String BU, String zuoraToken) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    String body;

    System.debug('>>>>> AAZ getFile - fileId : ' + fileId);

    try {
      BU = (String.isBlank(BU) ? UtilsBypass.getCurrentUser().ER_Business_Unit__c : BU);
      String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);
      String entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + BU);

      if (entityId != null) {
        req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_FILES + fileId);

        req.setHeader('entityId', entityId);
        req.setMethod(Constants.GET_METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'bearer ' + zuoraToken);

        Zuora.zApi zApiInstance = new Zuora.zApi();

        if (!Test.isRunningTest())
          resp = zApiInstance.sendRequest(req);
        else
          resp = SendToZuoraMock.respond(req);

        if (resp.getStatusCode() == 200) {
          //body = resp.getBodyAsBlob();
          body = EncodingUtil.base64Encode(resp.getBodyAsBlob());
        } else {
          throw new CalloutException(resp.getBody());
        }
      }
    } catch (Exception ex) {
      System.debug('>>>>> AAZ - getFile Exception : ' + ex.getMessage());
      return null;
    }

    return body;
  }

  /**
   * @author AAZ
   * @date 23/08/2022
   * @description generate Zuora Quote default name
   *
   * @return String
   */
  public static String getZuoraQuoteName(Opportunity opp) {
    String quoteDefaultName;
    if (!opp.zqu__Quotes__r.isEmpty()) {
      zqu__Quote__c q = opp.zqu__Quotes__r[0];
      Integer lastSequenceNumber = (String.isNotBlank(q.Name) &&
        String.valueOf(q.Name.substringAfterLast('-')).isNumeric()
        ? Integer.valueOf(q.Name.substringAfterLast('-'))
        : 0);
      quoteDefaultName =
        opp.ER_BUPicklist__c +
        '-' +
        (String.isNotBlank(opp.Account.ER_Registration_Number__c)
          ? opp.Account.ER_Registration_Number__c
          : opp.Account.Name) +
        '-' +
        Datetime.now().format('yyyy-MM-dd') +
        '-' +
        (lastSequenceNumber + 1);
    } else {
      quoteDefaultName =
        opp.ER_BUPicklist__c +
        '-' +
        (String.isNotBlank(opp.Account.ER_Registration_Number__c)
          ? opp.Account.ER_Registration_Number__c
          : opp.Account.Name) +
        '-' +
        Datetime.now().format('yyyy-MM-dd') +
        '-' +
        1;
    }

    return quoteDefaultName;
  }

  /**
   * @author AAZ
   * @description Get Invoice / Proforma PDF
   * @param invoiceNumber
   * @param invoiceType
   * @param bu
   * @param proformaVersion
   *
   * @return
   */
  public static String getInvoicePDF(String invoiceNumber, String invoiceType, String bu, String proformaVersion) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    String body;

    System.debug('>>>>> AAZ - ZuoraUtils getInvoicePDF invoiceId : ' + invoiceNumber);
    System.debug('>>>>> AAZ - ZuoraUtils getInvoicePDF invoiceType : ' + invoiceType);
    System.debug('>>>>> AAZ - ZuoraUtils getInvoicePDF bu : ' + bu);

    try {
      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      String tokenType = smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE);
      String accessToken = smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN);

      if (tokenType != null && accessToken != null) {
        req.setEndpoint(
          'callout:' +
          Constants.SMARTER_NAMED_CREDENTIAL +
          Constants.SLASH +
          Constants.SMARTER_PROFORMA_SERVICE_VERSION +
          Constants.SLASH +
          Constants.SMARTER_PROFORMA_SERVICE_NAME +
          Constants.SLASH +
          (invoiceType == Constants.PROFORMA ? proformaVersion : invoiceNumber)
        );
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        req.setMethod(Constants.GET_METHOD);
        req.setHeader('X-Tenant', bu);
        req.setHeader('Authorization', tokenType + ' ' + accessToken);

        resp = http.send(req);

        if (resp.getStatusCode() == 200) {
          System.debug('>>>>> AAZ - Success resp.getStatusCode(): ' + resp.getStatusCode());
          body = EncodingUtil.base64Encode(resp.getBodyAsBlob());
        } else {
          //throw new AuraHandledException(resp.getBody());
          System.debug('>>>>> AAZ - status code : ' + resp.getStatusCode());
          System.debug('>>>>> AAZ - resp body : ' + resp.getBody());
        }
      }
    } catch (AuraHandledException ahe) {
      System.debug('>>>>> ALK - ahe : ' + ahe);
    } catch (Exception e) {
      System.debug('>>>>> AAZ - getFile Exception : ' + e.getMessage());
      return body;
    }

    return body;
  }

  /**
   * @author AAZ
   * @description Retrive Billing Accounts from BA Numbers
   * @param billingsAccounts
   * @param bu
   *
   * @return
   */
  public static Map<String, Zuora__CustomerAccount__c> retrieveBillingAccounts(
    Set<String> billingsAccounts,
    String bu
  ) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    Map<String, Zuora__CustomerAccount__c> retrievedAccounts = new Map<String, Zuora__CustomerAccount__c>();

    try {
      String zuoraToken = ZuoraUtils.getZuoraToken();
      String entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + bu); //TODO
      String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);

      String whereClause = '';
      for (String accName : billingsAccounts) {
        if (whereClause.length() > 0)
          whereClause += ' OR ';
        whereClause += 'AccountNumber = \'' + accName + '\'';
      }

      System.debug(
        '>>>>> AAZ - soql : ' +
        'SELECT Id, AccountNumber, PaymentTerm, DefaultPaymentMethodId, BillToId, SoldToId, TECH_Financial_Center__c FROM Account WHERE ' +
        whereClause
      );
      req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACTION_QUERY);
      req.setMethod(Constants.POST_METHOD);
      req.setHeader('Content-Type', 'application/json');
      req.setHeader('entityId', entityId);
      req.setHeader('Authorization', 'bearer ' + zuoraToken);

      String payload =
        '{"queryString": "SELECT Id, AccountNumber, PaymentTerm, DefaultPaymentMethodId, TECH_Financial_Center__c FROM Account WHERE ' +
        whereClause +
        '"}';
      req.setBody(payload);

      resp = http.send(req);
      if (resp.getStatusCode() == 200) {
        Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
        System.debug('>>>>> AAZ - mapRespData : ' + mapRespData.get('records'));

        for (Object ob : (List<Object>) mapRespData.get('records')) {
          Map<String, Object> mapObj = (Map<String, Object>) ob;
          String baNumber = (String) mapObj.get('AccountNumber');
          String baId = (String) mapObj.get('Id');
          String baPaymentTerm = (String) mapObj.get('PaymentTerm');
          String baFinancialCenter = (String) mapObj.get('TECH_Financial_Center__c');
          if (String.isNotBlank(baNumber)) {
            retrievedAccounts.put(
              baNumber,
              new Zuora__CustomerAccount__c(
                Zuora__AccountNumber__c = baNumber,
                Zuora__Zuora_Id__c = baId,
                Zuora__PaymentTerm__c = (String.isNotBlank(baPaymentTerm) ? baPaymentTerm : ''),
                ER_Financial_Center__c = baFinancialCenter
              )
            );
          }
        }

        return retrievedAccounts;
      }
    } catch (CalloutException ce) {
      System.debug('>>>>> AAZ - CalloutException : ' + ce.getMessage());
    }

    return null;
  }

  /**
   * @author AAZ
   * @date 18/04/2023
   * @description Get Billing Account By Number
   * @param baNumber
   * @param bu
   *
   * @return
   */
  public static Zuora__CustomerAccount__c getBillingAccountByNumber(String baNumber, String bu) {
    List<Zuora__CustomerAccount__c> accounts = [
      SELECT
        Zuora__AccountNumber__c,
        Zuora__Zuora_Id__c,
        Zuora__PaymentTerm__c,
        Zuora__DefaultPaymentMethod__c,
        ER_Financial_Center__c
      FROM Zuora__CustomerAccount__c
      WHERE Zuora__AccountNumber__c = :baNumber
    ];

    if (!accounts.isEmpty())
      return accounts[0];
    return retrieveBillingAccountByNumber(baNumber, bu);
  }

  /**
   * @author AAZ
   * @date 18/04/2023
   * @description Get retrieve Account By Number
   * @param baNumber
   * @param bu
   *
   * @return
   */
  public static Zuora__CustomerAccount__c retrieveBillingAccountByNumber(String baNumber, String bu) {
    Map<String, Zuora__CustomerAccount__c> mapBillingAccounts = retrieveBillingAccounts(
      new Set<String>{ baNumber },
      bu
    );
    if (!mapBillingAccounts.isEmpty())
      return mapBillingAccounts.get(baNumber);
    return null;
  }

  /**
     * @author AAZ
     * @date 01/09/2023
     * @description update a Zuora Customer Account
     * @param account
     * @param zuoraToken
     * @return String
     */
    public static String updateZuoraAccount(ZuoraUtils.ZuoraCustomerWrapper account, String zuoraToken) {
      HttpRequest req = new HttpRequest();
      Http http = new Http();
      HttpResponse resp;
      Map<String, Object> billingAccount = new Map <String, Object>();

      System.debug('>>>>> AAZ updateZuoraAccount - account : ' + account);

      try {
          String BU = (String.isBlank(account.BusinessUnit) ? UtilsBypass.getCurrentUser().ER_Business_Unit__c : account.BusinessUnit);
          String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);
          String entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + BU);
    
          if(String.IsNotBlank(account.PaymentTerm))
            billingAccount.put('paymentTerm', account.PaymentTerm);
          if(String.IsNotBlank(account.PaymentMethodId))
            billingAccount.put('defaultPaymentMethodId', account.PaymentMethodId);

          if(entityId != null) {
              req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACCOUNT + account.BillAccNumber);

              req.setHeader('entityId', entityId);
              req.setMethod(Constants.PUT_METHOD);
              req.setHeader('Content-Type','application/json');
              req.setHeader('Accept', 'application/json');
              req.setHeader('Authorization','bearer ' + zuoraToken);

              String payload = JSON.serialize(billingAccount);
              System.debug('>>>>> AAZ updateZuoraAccount - payload : ' + payload);
              req.setBody(payload);
              Zuora.zApi zApiInstance = new Zuora.zApi();

              if(!Test.isRunningTest()) resp = zApiInstance.sendRequest(req);
              else resp = SendToZuoraMock.respond(req);

              if(resp.getStatusCode() == 200) {
                  Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                  System.debug('>>>>> AAZ updateZuoraAccount - mapRespData : ' + mapRespData);

                  if(mapRespData.get('success') == false) {
                      throw new CalloutException(Label.LAB_SF_BILLING_ACCOUNT_UUPDATE_ERROR);
                  }

              } else {
                  throw new CalloutException(Label.LAB_SF_BILLING_ACCOUNT_UUPDATE_ERROR);
              }
          }

      } catch(Exception ex) {
          System.debug('>>>>> AAZ - updateZuoraAccount Exception : ' + ex.getMessage());
          return ex.getMessage();
      }

      return 'SUCCESS';
  }
  
  public with sharing class ZuoraCustomerWrapper {
      public String BillAccNumber {get; set;}
      public String PaymentTerm {get; set;}
      public String PaymentMethodId {get; set;}
      public String BusinessUnit {get; set;}
  }
}