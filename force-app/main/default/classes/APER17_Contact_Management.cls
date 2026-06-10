/**
 * @description       :
 * @author            : AAM
 * @group             :
 * @last modified on  : 17-07-2023
 * @last modified by  : AAM
 **/
public class APER17_Contact_Management {
  /*
----------------------------------------------------------------------
-- - Name          : APER17_Contact_Management
-- - Author        : OLA
-- - Description   : Contact Management, This class is used to group all the functionnality linked to the object Contact
--
-- Date         Name                Version     				Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2019       OLA                1.0         			Initial version
---------------------------------------------------------------------------------------
*/

  public static void syncAddressFromAccount(Map<Id, Account> accountMap) {
    List<Contact> contactToUpdate = new List<Contact>();
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.duplicateRuleHeader.allowSave = true;
    dml.duplicateRuleHeader.runAsCurrentUser = true;

    for (Contact cont : [
      SELECT Id, AccountId
      FROM Contact
      WHERE
        AccountId IN :accountMap.keySet()
        AND ER_Account_Address_Sync__c = :Label.LABS_SF_Account_SyncAddressContact
        AND ER_Status__c != :Label.LAB_SF_Contact_Inactive
    ]) {
      cont.MailingStreet = accountMap.get(cont.AccountId).BillingStreet;
      cont.MailingPostalCode = accountMap.get(cont.AccountId).BillingPostalCode;
      cont.MailingCity = accountMap.get(cont.AccountId).BillingCity;
      cont.MailingCountry = accountMap.get(cont.AccountId).BillingCountry;
      cont.MailingPostalCode = accountMap.get(cont.AccountId).BillingPostalCode;
      cont.ER_Country_Code__c = accountMap.get(cont.AccountId).ER_Country_Code__c;
      contactToUpdate.add(cont);
    }

    if (!contactToUpdate.isEmpty())
      Database.update(contactToUpdate, dml);
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Sync Contacts to EDG v3
   * @param contacts
   */
  public static void syncContacts(List<Contact> contacts, Map<Id, Contact> oldContact) {
    /* Set<Id> accounts = new Set<Id>();
    Set<Id> accountsToSync = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();

    if (!contacts.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = contacts[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    System.debug('Aper17_ER_SyncStructureWS.alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync);
    if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
      for (Contact c : contacts) {
        ModifiedElements.add(c.Id);
        if (
          !c.ER_SmartER_Context__c &&
          c.AccountId != null &&
          ((oldContact == null || oldContact.isEmpty()) ||
          (oldContact != null &&
          c.ER_Last_date_of_Sync__c == oldContact.get(c.Id).ER_Last_date_of_Sync__c))
        )
          accounts.add(c.AccountId);
      }

      if (!accounts.isEmpty()) {
        for (Account a : [SELECT Id FROM Account WHERE Id IN :accounts AND ER_Creation_date_in_OS__c != NULL])
          accountsToSync.add(a.Id);

        if (!accountsToSync.isEmpty())
          System.enqueueJob(new ER_SyncStructureWS(accountsToSync, null, 'PUT', ModifiedElements, accountsInputScope));
      }
    } */
  }

  /**
   * @author KHAD
   * @date 08/06/2021
   * @description Update the creation date in ios field for contact v3
   * @param newItems
   * @param oldItems
   */
  public static void syncContactFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### syncContactFlags Start');
    Map<Id, Contact> newContactMap = (Map<Id, Contact>) newItems;
    Map<Id, Contact> oldContactMap = (Map<Id, Contact>) oldItems;

    // Loop through the Acceptor lists and add fill the creation date in OS
    for (Contact c : newContactMap.values()) {
      if (
        !c.ER_SmartER_Context__c &&
        c.ER_Sync_result__c != oldContactMap.get(c.Id).ER_Sync_result__c &&
        (c.ER_Sync_result__c == 'synchronized' ||
        c.ER_Sync_result__c == 'pending_synchronization') &&
        c.ER_Creation_date_in_OS__c == null
      )
        c.ER_Creation_date_in_OS__c = Datetime.now();
    }

    System.debug('### syncContactFlags End');
  }

  /**
   * @author AAZ
   * @date 29/06/2021
   * @description update Zuora Customer Account after an update on Contact
   * @param newContacts
   * @param oldContacts
   */
  public static void updateZuoraBillingAccount(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
    List<String> changedFields = new List<String>();
    Set<Id> setContactsWithEmailChanged = new Set<Id>();
    List<ER_Financial_Center__c> listFcToSync = new List<ER_Financial_Center__c>();
    List<String> zuoraDeployedBU = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU)
      ?.split(Constants.SEMICOLON);
    List<Contact> contacts = new List<Contact>();

    for (Contact c : newContacts) {
      if (
        String.isNotBlank(c.ER_BUPicklist__c) &&
        zuoraDeployedBU != null &&
        zuoraDeployedBU.contains(c.ER_BUPicklist__c)
      )
        contacts.add(c);
    }

    if (!contacts.isEmpty()) {
      for (Contact newCont : newContacts) {
        changedFields = Utils.splitValues(
          Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_CONTACT_CHANGEDFIELDS + newCont.ER_Business_Unit__c)
        );
        Contact oldCont = oldContacts.get(newCont.Id);

        for (String fld : changedFields) {
          if (newCont.get(fld) != oldCont.get(fld)) {
            setContactsWithEmailChanged.add(newCont.Id);
            break;
          }
        }
      }

      for (ER_Financial_Center__c fc : [
        SELECT
          Id,
          Name,
          ER_Type__c,
          ER_Business_Unit__c,
          ER_Contact__c,
          ER_Contact__r.FirstName,
          ER_Contact__r.LastName,
          ER_Contact__r.Email,
          ER_Contact__r.Fax,
          ER_Contact__r.Phone,
          ER_Bank_Account__r.ER_IBAN__c,
          OwnerId,
          Owner.Name,
          ER_Email__c,
          ER_Secondary_Email__c,
          ER_Invoicing_Street__c,
          ER_Invoicing_Zip_Code__c,
          ER_Invoicing_City__c,
          ER_Account_Name__r.ER_Registration_Number__c,
          ER_Invoicing_Country__c,
          ER_Invoicing_Country_Code__c,
          ER_Account_Name__r.ER_Customer_Number__c,
          ER_Invoicing_Region_State__c,
          (SELECT Id, Zuora__AccountNumber__c FROM Billing_Accounts__r)
        FROM ER_Financial_Center__c
        WHERE ER_Contact__c IN :setContactsWithEmailChanged
      ]) {
        if (!fc.Billing_Accounts__r.isEmpty())
          listFcToSync.add(fc);
      }

      if (!listFcToSync.isEmpty())
        System.enqueueJob(new ER_CreateZuoraBillingAccount(null, listFcToSync));
    }
  }

  /**
   * @author AAZ
   * @date 29/11/2021
   * @description Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
   * @param newItems
   */
  public static void updateLastModifiedDateFunctionalUser(List<Contact> newItems) {
    ER_Validation_Rules_Settings__c profileSetting = ER_Validation_Rules_Settings__c.getInstance(
      UserInfo.getProfileId()
    );
    ER_Validation_Rules_Settings__c userSetting = ER_Validation_Rules_Settings__c.getInstance(UserInfo.getUserId());

    for (Contact c : newItems) {
      if (
        !profileSetting.ER_Last_Modified_Date_Functional_User__c &&
        !userSetting.ER_Last_Modified_Date_Functional_User__c
      )
        c.ER_Last_Modified_Date_Functional_User__c = Datetime.now();
    }
  }

  /**
   * @author KHAD
   * @date 01/02/2022
   * @block the desactivation of a primary contact
   * @param newContactMap
   * @param oldContactMap
   */
  public static void BlockPrimaryContactDeactivation(Map<Id, SObject> newContactMap, Map<Id, SObject> oldContactMap) {
    List<Contact> ContactToBlock = new List<Contact>();
    Map<Id, Contact> newItems = (Map<Id, Contact>) newContactMap;
    Map<Id, Contact> oldItems = (Map<Id, Contact>) oldContactMap;
    List<Contact> contacts = new List<Contact>();

    for (Contact c : newItems.values()) {
      if (!c.ER_SmartER_Context__c)
        contacts.add(c);
    }

    if (!contacts.isEmpty()) {
      for (ER_Contact_Role__c ctr : [
        SELECT Id, ER_Contact__c
        FROM ER_Contact_Role__c
        WHERE ER_Primary__c = TRUE AND ER_Contact__c IN :contacts
      ]) {
        if (!ContactToBlock.contains(newItems.get(ctr.ER_Contact__c))) {
          if (
            !UtilsBypass.getCurrentUser().ER_BypassVR__c &&
            oldItems.get(ctr.ER_Contact__c).ER_Status__c != newItems.get(ctr.ER_Contact__c).ER_Status__c &&
            newItems.get(ctr.ER_Contact__c).ER_Status__c == Constants.INACTIVE
          ) {
            newItems.get(ctr.ER_Contact__c).addError(Label.LABS_SF_PK_Contact_Deactivation);
            ContactToBlock.add(newItems.get(ctr.ER_Contact__c));
          }
        }
      }
    }
  }

  /**
   * @author Noor
   * @description Initialize contact field
   *              Update Country Code with legal country code
   * @param newItems
   */
  public static void initializeFields(List<Contact> newItems) {
    for (Contact con : newItems) {
      if (!con.ER_SmartER_Context__c && String.isBlank(con.ER_Country_Code__c))
        con.ER_Country_Code__c = con.ER_Legal_Country_Code__c;
    }
  }

  /**
   * @author AAZ
   * @date 31/05/2022
   * @description Get Products Translations
   * @see APER36_QuoteLineItem_Management
   * @param newItems
   * @param oldItems
   */
  public static void getProductsNameTranslations(List<Contact> newItems, Map<Id, Contact> oldItems) {
    List<Id> listToProcess = new List<Id>();
    List<String> bypassedStatuses = new List<String>{ Constants.ACCEPTED, Constants.DENIED };

    for (Contact ct : newItems) {
      if (
        !ct.ER_SmartER_Context__c &&
        String.isNotBlank(ct.ER_Language__c) &&
        ct.ER_Language__c != oldItems.get(ct.Id).ER_Language__c
      )
        listToProcess.add(ct.Id);
    }

    if (listToProcess.size() > 0) {
      Map<Id, Quote> quotesMap = new Map<Id, Quote>(
        [SELECT Id FROM Quote WHERE ContactId IN :listToProcess AND Status NOT IN :bypassedStatuses]
      );

      APER36_QuoteLineItem_Management.getProductsNameTranslations(
        [
          SELECT
            Id,
            Quote.ER_DocuGen_Contact_Preferred_Language__c,
            Product2Id,
            Product2.Name,
            Product2.ER_Solution2__c,
            Product2.ER_Solution2__r.Name,
            ER_Service_Translated_Name__c,
            ER_Solution_Translated_Name__c
          FROM QuoteLineItem
          WHERE QuoteId IN :quotesMap.keySet()
        ]
      );
    }
  }

  /**
   * @author AAZ
   * @date 28/06/2022
   * @description SmartER Set SmartER context on the contact
   * @param newItems
   */
  public static void setContactAsSmartERContext(List<Contact> newItems) {
    List<String> smartERDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
      ?.split(Constants.SEMICOLON);

    for (Contact c : newItems) {
      if (
        smartERDeployedBUs != null &&
        (smartERDeployedBUs.contains(c.ER_BUPicklist__c) || smartERDeployedBUs.contains(Constants.ALL)) &&
        !c.ER_SmartER_Context__c
      ) {
        c.ER_SmartER_Context__c = false;
      }
    }
  }

  /**
   * @author CWA
   * @date 16/09/2022
   * @description Update ER_Inactive_date__c following the contact Status
   */
  public static void updateInactiveDate(List<Contact> newItems, Map<Id, SObject> oldItems) {
    Map<Id, Contact> oldContactMap = (Map<Id, Contact>) oldItems;

    for (Contact c : newItems) {
      if (c.ER_Status__c != oldContactMap?.get(c.Id).ER_Status__c && c.ER_Status__c == Constants.INACTIVE)
        c.ER_Inactive_date__c = Date.today();
      else
        c.ER_Inactive_date__c = null;
    }
  }

  /**
   * @author AAZ
   * @date 21/12/2022
   * @description Sync smarter Contacts to SmartER Client Ref
   * @param contactsIds
   */
  @Future(Callout=true)
  public static void doSyncContactsToSmartER(Set<Id> contactsIds) {
    System.debug('>>>>> ALK - contactsIds : ' + contactsIds);
    if (!contactsIds.isEmpty()) {
      doSyncContactsToSmartERSynchronous(contactsIds);
    }
  }

  /**
   * @author AAZ
   * @date 21/12/2022
   * @description Sync smarter Contacts to SmartER Client Ref
   * @param contactsIds
   */
  public static void doSyncContactsToSmartERSynchronous(Set<Id> contactsIds) {
        System.debug('>>>>> ALK - contactsIds : ' + contactsIds);
        if(!contactsIds.isEmpty()) {
            Map<String, String> smarterAT = Utils.getSmarterAccessToken();
            String tokenType = smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE);
            String accessToken = smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN);
            System.debug('>>>>> ALK - tokenType ' + tokenType + ' - accessToken : ' + accessToken);

            if(tokenType != null && accessToken != null) {
                HttpRequest req = new HttpRequest();
                Http http = new Http();
                HttpResponse resp = new HttpResponse();
                List<Contact> contactsToUpdate = new List<Contact>();
                String ddTraceId;

                Map<String, Map<String, List<Object>>> mapMethodBUPayLoads = new Map<String, Map<String, List<Object>>> {
                        Constants.POST_METHOD => new Map<String, List<Object>>(),
                        Constants.PATCH_METHOD => new Map<String, List<Object>>()
                };

                List<Contact> contacts = getContactsToBeSyncedToSmarter(contactsIds);
                System.debug('>>>>> ALK - contacts : ' + contacts);

                if(contacts != null && !contacts.isEmpty()) {
                    for(Contact c : contacts) {
                        if(String.isNotBlank(c.ER_BUPicklist__c)) {
                            String method = c.ER_Smarter_1st_Sync_Date__c == null ? Constants.POST_METHOD : Constants.PATCH_METHOD;
                            Map<String, List<Object>> mapBUPayload = mapMethodBUPayLoads.get(method);
                            List<Object> buPayLoad = (mapBUPayload.containsKey(c.ER_BUPicklist__c) ? mapBUPayload.get(c.ER_BUPicklist__c) : new List<Object>());
                            Map<String, Object> mapObj = new Map <String, Object>();
                            if(ddTraceId == null && String.isNotBlank(c.ER_dd_Trace_Id__c)) ddTraceId = c.ER_dd_Trace_Id__c;

                            if(!c.AccountContactRelations.isEmpty()) {
                                List<Object> relationships = new List <Object>();
                                Map<String, Object> relationshipItem = new Map <String, Object>();
                                for(AccountContactRelation acr :c.AccountContactRelations) {
                                    relationshipItem.put('Roles', acr.Roles);
                                    relationshipItem.put('eventType', (acr.CreatedBy.Profile.Name == Constants.PROFILE_ER_INTEGRATION ? 'Online' : 'Offline'));
                                    relationshipItem.put('isDirectRelationship', acr.IsDirect);
                                    relationshipItem.put('clientId', acr.Account.SmartER_Customer_Id__c);
                                    relationshipItem.put('contactAccountRelationshipId', acr.Id);
                                    relationships.add(relationshipItem);
                                }
                                mapObj.put('ContactAccountRelationships', relationships);
                            }

                            mapObj.put(Constants.SMARTER_CLIENT_REF_LANGUAGE, (String.isNotBlank(c.ER_Language__c) ? c.ER_Language__c : ''));
                            mapObj.put(Constants.SMARTER_CLIENT_REF_PHONE, c.Phone);
                            mapObj.put(Constants.SMARTER_CLIENT_REF_EMAIL, c.Email);
                            mapObj.put(Constants.SMARTER_CLIENT_REF_LASTNAME, c.LastName);
                            mapObj.put(Constants.SMARTER_CLIENT_REF_FIRSTNAME, c.FirstName);
                            mapObj.put(Constants.SMARTER_CLIENT_REF_CLIENT_ID, c.Account.SmartER_Customer_Id__c);
                            mapObj.put(Constants.SMARTER_CONTACT_ONEFORCE_ID, c.Id);

                            buPayLoad.add(mapObj);
                            mapBUPayload.put(c.ER_BUPicklist__c, buPayLoad);
                        }
                    }
                    System.debug('>>>>> ALK - mapMethodBUPayLoads : ' + mapMethodBUPayLoads);

                    for(String method : mapMethodBUPayLoads.keySet()) {
                        Map<String, List<Object>> buPayLoadMap = mapMethodBUPayLoads.get(method);
                        System.debug('>>>>> ALK - buPayLoadMap : ' + buPayLoadMap);
                        if(!buPayLoadMap.isEmpty()) {
                            for(String bu : buPayLoadMap.keySet()) {
                                List<Object> payLoadList = buPayLoadMap.get(bu);
                                if(Limits.getCallouts() < Limits.getLimitCallouts()) {
                                    req.setEndpoint('callout:' + Constants.SMARTER_NAMED_CREDENTIAL + Constants.SLASH
                                            + Constants.SMARTER_CONTACTS_SERVICE_VERSION
                                            + Constants.SLASH + Constants.SMARTER_CONTACTS_SERVICE_NAME);
                                    req.setMethod(method);
                                    req.setHeader('Content-Type', 'application/json');
                                    req.setHeader('Accept', 'application/json');
                                    req.setHeader('X-Tenant', bu);
                                    req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
                                    if(String.isNotBlank(ddTraceId)) req.setHeader(Constants.REQUEST_HEADER_DD_TRACEID, ddTraceId);
                                    req.setHeader('Authorization', tokenType + ' ' + accessToken);

                                    String payload = JSON.serialize(payLoadList);
                                    System.debug('>>>>> AAZ - payload : ' + payload);
                                    req.setBody(payload);
                                    resp = http.send(req);
                                    System.debug('>>>>> ALK - resp.getStatusCode() : ' + resp.getStatusCode());
                                    contactsToUpdate.addAll(updateSmarterContactsSyncFields(payLoadList, method, resp));
                                }
                            }
                        }
                    }

                    if(!contactsToUpdate.isEmpty()) Database.update(contactsToUpdate, false);
                }
            }
        }
    }

  /**
   * @author AAZ
   * @date 23/03/2023
   * @description Update Contacts syc fields
   * @param payLoadList
   * @param methodName
   * @param response
   *
   * @return
   */
  public static List<Contact> updateSmarterContactsSyncFields(
    List<Object> payLoadList,
    String methodName,
    HttpResponse response
  ) {
    List<Contact> contactsToUpdate = new List<Contact>();
    if (payLoadList != null && !payLoadList.isEmpty()) {
      if (response.getStatusCode() == 204) {
        for (Object obj : payLoadList) {
          Contact c = new Contact();
          Map<String, Object> mapObj = (Map<String, Object>) obj;
          c.Id = (Id) mapObj.get(Constants.SMARTER_CONTACT_ONEFORCE_ID);
          if (methodName == Constants.POST_METHOD)
            c.ER_Smarter_1st_Sync_Date__c = Datetime.now();
          c.ER_Smarter_Last_Sync_Date__c = Datetime.now();
          c.ER_Smarter_Sync_Status__c = Constants.SYNCHRONIZED_STATUS;
          c.ER_Smarter_Sync_Error__c = null;
          contactsToUpdate.add(c);
        }
      } else if (response.getBody() != null && response.getStatusCode() != 204) {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> metaMap = (Map<String, Object>) (m.get('meta'));
        List<Object> att = (List<Object>) metaMap.get('messages');
        Map<String, Object> data = (Map<String, Object>) att[0];

        for (Object obj : payLoadList) {
          Map<String, Object> mapObj = (Map<String, Object>) obj;
          contactsToUpdate.add(
            new Contact(
              Id = (Id) mapObj.get(Constants.SMARTER_CONTACT_ONEFORCE_ID),
              ER_Smarter_Last_Sync_Date__c = Datetime.now(),
              ER_Smarter_Sync_Status__c = Constants.NOT_SYNCHRONIZED_STATUS,
              ER_Smarter_Sync_Error__c = data.get('code') +
                ' \\n ' +
                data.get('text') +
                ' \\n ' +
                'traceId (' +
                data.get('traceId') +
                ')'
            )
          );
        }
      }
    }

    System.debug('>>>>> ALK - contactsToUpdate : ' + contactsToUpdate);
    return contactsToUpdate;
  }

  /**
   * @author AAZ
   * @date 21/12/2022
   * @description Sync smarter Contacts to SmartER Client Ref
   * @param newItems
   * @param oldItemsMap
   */
  public static void syncContactsToSmartER(List<Contact> newItems, Map<Id, Contact> oldItemsMap) {
    /* Set<Id> contactsIds = new Set<Id>();

    for (Contact c : newItems) {
      if (c.ER_SmartER_Context__c && c.ER_To_sync_with_smarter__c && String.isNotBlank(c.ER_BUPicklist__c))
        contactsIds.add(c.Id);
    }

    if (!contactsIds.isEmpty()) {
      Set<Id> contactsIdsToPublish = new Set<Id>();

      for (Contact c : getContactsToBeSyncedToSmarter(contactsIds)) {
        if (hasContactChanged(c, oldItemsMap.get(c.Id)))
          contactsIdsToPublish.add(c.Id);
      }

      if (!contactsIdsToPublish.isEmpty())
        publishContactsToBeSyncedWithSmarter(contactsIdsToPublish);
    } */
  }

  /**
   * @author AAZ
   * @date 21/12/2022
   * @description Get Contacts to be synced to smarter
   * @param contactsIds
   *
   * @return
   */
  public static List<Contact> getContactsToBeSyncedToSmarter(Set<Id> contactsIds) {
        if(!contactsIds.isEmpty()) {
            return [
                    SELECT Id, ER_To_sync_with_smarter__c, Account.SmartER_Customer_Id__c, ER_BUPicklist__c, FirstName,
                            LastName, Email, Phone, ER_Language__c, MobilePhone, ER_Smarter_1st_Sync_Date__c,
                            ER_dd_Trace_Id__c,
                    (SELECT Id, AccountId, Account.SmartER_Customer_Id__c, IsDirect, Roles, CreatedBy.Profile.Name
                        FROM AccountContactRelations)
                    FROM Contact
                    WHERE Id IN :contactsIds
            ];
        }

        return null;
    }

  /**
   * @author AAZ
   * @date 23/03/2023
   * @description Publish Contacts to be synced with smarter
   * @param ids
   */
  public static void publishContactsToBeSyncedWithSmarter(Set<Id> ids) {
    if (!ids.isEmpty()) {
      Distributed_Transaction_Event__e evt = new Distributed_Transaction_Event__e();
      evt.Transaction_Name__c = Constants.RUN_SYNC_CONTACTS_TO_SMARTER;
      evt.Transaction_Content__c = JSON.serializePretty(ids);
      EventBus.publish(evt);
    }
  }

  /**
   * @author ALK
   * @date 31/01/2023
   * @description THis method is used to check if a smarter contact has an attribute changed in order to be synced
   * @param newValue
   * @param oldValue
   *
   * @return
   */
    @TestVisible
  private static Boolean hasContactChanged(Contact newValue, Contact oldValue) {
    if (
      newValue != null &&
      oldValue != null &&
      newValue.ER_To_sync_with_smarter__c &&
      (newValue.FirstName != oldValue.FirstName ||
      newValue.LastName != oldValue.LastName ||
      newValue.Phone != oldValue.Phone ||
      newValue.Email != oldValue.Email ||
      newValue.ER_Language__c != oldValue.ER_Language__c)
    )
      return true;

    return false;
  }

  /**
   * @author AAZ
   * @date 19/12/2022
   * @description Tick Contacts to be synced with Smarter for Online process.
   * For the offline process the contacts will be flagged to be sync only when they're linked to an active contract
   * during the activation
   * @param newItems
   * @param oldItemsMap
   */
  public static void markContactToBeSyncedWithSmarter(List<Contact> newItems) {
    Id businessContactRT = Utils.getRecordTypeIdByDeveloperName(Contact.SObjectType, Constants.CONTACT_BUSINESS_RT);
    List<Contact> contacts = new List<Contact>();
    for (Contact c : newItems) {
      if (c.ER_SmartER_Context__c && c.RecordTypeId == businessContactRT && !c.ER_To_sync_with_smarter__c)
        contacts.add(c);
    }
    if (!contacts.isEmpty()) {
      Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.PROFILE_ER_INTEGRATION];
      Map<Id, User> mapIntegnUsers = new Map<Id, User>([SELECT Id, Name, ProfileId FROM User WHERE ProfileId = :p.Id]);

      for (Contact c : contacts) {
        if (UserInfo.getProfileId() == p.Id || mapIntegnUsers.containsKey(c.CreatedById))
          c.ER_To_sync_with_smarter__c = true;
      }
    }
  }

  /**
   * @author AAZ
   * @date 05/04/2023
   * @description Send an onboarding email from OF
   * @param contactId
   * @return String
   */
  @AuraEnabled(Cacheable=true)
  public static String sendContactOnboardingNotification(Id contactId) {
    String message;
    System.debug('>>>>> AAZ - contactId : ' + contactId);
    List<Contact> contacts = [
      SELECT Id, Account.ER_Smarter_1st_Sync_Date__c, CreatedBy.Profile.Name, ER_BUPicklist__c
      FROM Contact
      WHERE Id = :contactId
    ];
    System.debug('>>>>> AAZ - contacts : ' + contacts);
    System.debug('>>>>> AAZ - !contacts.isEmpty() : ' + !contacts.isEmpty());
    System.debug(
      '>>>>> AAZ - contacts[0].Account.ER_Smarter_1st_Sync_Date__c : ' + contacts[0].Account.ER_Smarter_1st_Sync_Date__c
    );
    //System.debug('>>>>> AAZ - contacts[0].CreatedBy.Profile.Name : ' + contacts[0].CreatedBy.Profile.Name);

    if (!contacts.isEmpty() && contacts[0].Account.ER_Smarter_1st_Sync_Date__c != null) {
      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      String tokenType = smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE);
      String accessToken = smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN);
      System.debug('>>>>> AAZ - tokenType ' + tokenType + ' - accessToken : ' + accessToken);

      if (tokenType != null && accessToken != null) {
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HttpResponse resp = new HttpResponse();
        List<Object> payload = new List<Object>();
        Map<String, String> mapObj = new Map<String, String>();
        mapObj.put(Constants.SMARTER_CONTACT_ONEFORCE_ID, contacts[0].Id);
        payload.add(mapObj);

        req.setEndpoint(
          'callout:' +
          Constants.SMARTER_NAMED_CREDENTIAL +
          Constants.SLASH +
          Constants.SMARTER_SEND_ONBOARDING_SERVICE_VERSION +
          Constants.SLASH +
          Constants.SMARTER_SEND_ONBOARDING_SERVICE_NAME
        );
        req.setMethod(Constants.POST_METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('X-Tenant', contacts[0].ER_BUPicklist__c);
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        req.setHeader('Authorization', tokenType + ' ' + accessToken);

        String payloadJson = JSON.serialize(payload);
        System.debug('>>>>> AAZ - payload : ' + payloadJson);
        req.setBody(payloadJson);
        resp = http.send(req);

        System.debug('>>>>> AAZ - resp : ' + resp);

        if (resp.getStatusCode() != 200 && resp.getStatusCode() != 204) {
          if (String.isNotBlank(resp.getBody())) {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            if (m != null) {
              Map<String, Object> metaMap = (Map<String, Object>) (m.get('meta'));
              List<Object> att = (List<Object>) metaMap.get('messages');
              Map<String, Object> data = (Map<String, Object>) att[0];
              message =
                data.get('code') +
                ' \\n ' +
                data.get('text') +
                ' \\n ' +
                'traceId (' +
                data.get('traceId') +
                ')';
            }
          }

          System.debug('>>>>> AAZ - Error : ' + resp.getStatusCode() + ' - ' + resp.getBody());
          message = 'Error: ' + resp.getStatusCode() + ' ' + message;
        }
      } else
        message = Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': ' + Label.LAB_SF_AUTHENTICATION_FAILED;
    } else {
      message = System.Label.LAB_SF_ONBOARDING_EMAIL_ERROR_MSG;
    }

    System.debug('>>>>> AAZ - sendContactOnboardingNotification');
    return message;
  }

  /**
   * @author AAZ
   * @date 25/04/2023
   * @description Ability to sync any contact related to Smarter Account with Customer Id not empty
   * @param contactId
   *
   * @return
   */
  @AuraEnabled
  public static String requestAccessToSmarterApp(Id contactId) {
    System.debug('>>>>> AAZ - requestAccessToSmarterApp ' + contactId);
    String message;

    if (String.isNotBlank(contactId)) {
      List<Contact> contacts = [
        SELECT Id, Account.ER_Smarter_1st_Sync_Date__c, Account.SmartER_Customer_Id__c
        FROM Contact
        WHERE Id = :contactId
      ];
      if (
        !contacts.isEmpty() &&
        (contacts[0].Account.ER_Smarter_1st_Sync_Date__c != null ||
        String.isNotBlank(contacts[0].Account.SmartER_Customer_Id__c))
      ) {
        doSyncContactsToSmartERSynchronous(new Set<Id>{ contactId });
      } else {
        message = System.Label.LAB_SF_ONBOARDING_EMAIL_ERROR_MSG;
      }
    }

    return message;
  }
    
    /**
    * @author Snehil Verma
    * @date 18/11/2024
    * @description Sync account and contact in NEMO when contact is updated
    * @param newItems
    * @param oldContacts
    */
    /*public static void syncContactUpdateInNEMO(List<Contact> contacts, Map<Id, Contact> oldMap) {
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> accUpdateIdSet = new Set<Id>();
        for(Contact conObj : contacts){
            if((oldMap.get(conObj.Id).FirstName != conObj.FirstName || oldMap.get(conObj.Id).LastName != conObj.LastName || oldMap.get(conObj.Id).ER_Language__c != conObj.ER_Language__c || oldMap.get(conObj.Id).Email != conObj.Email || oldMap.get(conObj.Id).Phone != conObj.Phone) && conObj.ER_Card_Operational_System_ID__c != null){
                accIdSet.add(conObj.Id);
            }
        }
        
        for(Account accObj : [SELECT Id from Account where Id IN: accIdSet AND ER_Card_Client_Operational_System_ID__c != null]){
            accUpdateIdSet.add(accObj.Id);
        }
        
        if(!accIdSet.isEmpty()){
            System.enqueueJob(new UpdateClientQueueable(new List<Id>(accUpdateIdSet), 0));
        }
    }*/
    /**
    *   @author Pranjal Tiwari
        * @date   02/10/2025
        * @description: Prevents deletion of Contact records if the current user has the 
        *               Sales Head or Sales Rep profile. The method is called from the 
        *               beforeDelete trigger context using oldItems map. Any restricted 
        *               delete attempt will throw an error message on the Contact record.
    **/
    public static void preventRestrictedDeletions(Map<Id, SObject> oldItems) {
        String profileName = [
            SELECT Name 
            FROM Profile 
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ].Name;

        // Only enforce restriction for Sales Head or Sales Rep
        if(profileName == 'Sales Head' || profileName == 'Sales Rep') {
            for(SObject sobj : oldItems.values()) {
                Contact con = (Contact)sobj;
                if(con.MasterRecordId == null){
                    con.addError('You do not have permission to delete contacts.');
                }
            }
        }
    }
}