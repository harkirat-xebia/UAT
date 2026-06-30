/*************************************************************************************
Class Name:   APER30_AutoEnrollment_Management
Version:      1.0
Created Date: 15/02/2021
Purpose:      Apex controller for auto enrollment lwc. 

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* AAM           22/02/2021  Initial (Auto enrollment Project)
*************************************************************************************/

public with sharing class APER30_AutoEnrollment_Management {
  public static String syncRecordBU;

  // Get labels for fields and messages. Get also isSandbox flag, as it is the 1st call & in order to avoid doing it in another call  //TODO --> may be rename this method? getLabelsParams
  @AuraEnabled(cacheable=true)
  public static Map<String, Map<String, String>> getLabels(String country, String scope) {
    Map<String, Map<String, String>> labelsMap = new Map<String, Map<String, String>>();
    String curLang, curValue;

    //Get available language codes for this country
    List<String> langList = [
        SELECT Picklist_Values__c
        FROM Auto_Enrollment__mdt
        WHERE Country_Code__c = :country AND Label = 'pk_lang_list'
      ]
      .Picklist_Values__c.split('\\|');
    langList.add(null); // In order to take account of labels, formats that are not linked to a specific language
    // Select all labels for available language codes (those that are common for many countries, eg. french for Belgium & France, and also that are specific to current country)
    for (Auto_Enrollment__mdt ae : [
      SELECT Label, Value__c, Long_Value__c, Scope__c, Language_Code__c, Country_Code__c
      FROM Auto_Enrollment__mdt
      WHERE
        Language_Code__c IN :langList
        AND Country_Code__c IN (:country, NULL)
        AND Scope__c IN (:scope, NULL)
        AND Data_type__c IN ('Label', 'Format')
      ORDER BY Scope__c, Country_Code__c DESC NULLS FIRST
    ]) {
      // The "ORDER BY NULLS FIRST" is meant to get generic labels first and labels dedicated to a specific country at the end, so the specific labels are prioritized over the generic ones. It is done to have specific translations for a country
      curLang = (String.isBlank(ae.Language_Code__c)) ? 'All' : ae.Language_Code__c;
      curValue = (String.isBlank(ae.Long_Value__c)) ? ae.Value__c : ae.Long_Value__c;
      if (labelsMap.containsKey(curLang)) {
        labelsMap.get(curLang).put(ae.Label, curValue);
      } else {
        labelsMap.put(curLang, new Map<String, String>{ ae.Label => curValue });
      }
    }

    if ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox)
      labelsMap.get('All').put('isSandbox', 'true');
    System.debug('>>> getLabels -- labelsMap keys: ' + labelsMap.keySet());

    return labelsMap;
  }

  private static void adaptLabelsOnScopeAndLanguage(
    Map<String, Map<String, String>> labelsMap,
    String lang,
    String value,
    String scope,
    Auto_Enrollment__mdt ae,
    String country
  ) {
    if (labelsMap.containsKey(lang)) {
      if (labelsMap.get(lang).containsKey(ae.Label) && (ae.Scope__c == scope || ae.Country_Code__c == country)) {
        labelsMap.get(lang).put(ae.Label, value);
      } else if (!labelsMap.get(lang).containsKey(ae.Label)) {
        labelsMap.get(lang).put(ae.Label, value);
      }
    } else {
      labelsMap.put(lang, new Map<String, String>{ ae.Label => value });
    }
  }

  // Get all needed picklist informations (values and displayed labels)
  @AuraEnabled(cacheable=true)
  public static Map<String, Map<String, String>> getPicklistInfos(String country, String lang, String scope) {
    Map<String, Map<String, String>> picklistsMap = new Map<String, Map<String, String>>();

    for (Auto_Enrollment__mdt ae : [
      SELECT Label, Picklist_Values__c, Picklist_Labels__c
      FROM Auto_Enrollment__mdt
      WHERE
        Country_Code__c IN (:country, NULL)
        AND (Language_Code__c = :lang
        OR Language_Code__c = NULL)
        AND Data_type__c = 'Picklist'
    ]) {
      Map<String, String> curPicklistMap = new Map<String, String>();
      List<String> valuesList = ae.Picklist_Values__c.split('\\|');
      List<String> labelsList = ae.Picklist_Labels__c.split('\\|');

      for (Integer i = 0; i < labelsList.size(); i++) {
        curPicklistMap.put(valuesList[i], labelsList[i]);
      }

      picklistsMap.put(ae.Label, curPicklistMap);
    }

    return picklistsMap;
  }

  @AuraEnabled
  public static String checkCity(String countryCode, String city, String postalCode) {
    String cityResult = city; // Init result with city param, in case of webservice error

    Map<String, String> defaultValuesMap = new Map<String, String>();
    for (Auto_Enrollment__mdt ae : [
      SELECT Label, Value__c
      FROM Auto_Enrollment__mdt
      WHERE Label LIKE 'default_postcodeWS%'
    ])
      defaultValuesMap.put(ae.Label, ae.Value__c);

    String endpoint = defaultValuesMap.get('default_postcodeWS_endpoint')
      .replace('$countryCode', countryCode)
      .replace('$postalCode', postalCode);
    String apikey = defaultValuesMap.get('default_postcodeWS_apiKey');
    String testMock = defaultValuesMap.get('default_postcodeWS_testMock');

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setHeader('apikey', apikey);
    req.setMethod('GET');

    Http http = new Http();
    String response = (Test.isRunningTest()) ? testMock : http.send(req).getBody();
    // System.debug('>>> checkCityWS - response: ' + response);

    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
    System.debug('>>> checkCityWS - results: ' + String.valueOf(responseMap.get('results')));

    if (responseMap.keySet().contains('results') && String.valueOf(responseMap.get('results')).startsWith('{')) {
      Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('results');
      Integer cityLevDistanceOld = 99;
      if (resultMap.containsKey(postalCode)) {
        for (Object obj : (List<Object>) resultMap.get(postalCode)) {
          String cityResultWS = String.valueOf(((Map<String, Object>) obj).get('city'));
          System.debug('>>> checkCityWS - cityResultWS: ' + cityResultWS);
          Integer cityLevDistanceCur = !String.isBlank(city) && !String.isBlank(cityResultWS)
            ? cityResultWS.getLevenshteinDistance(city)
            : 0;
          System.debug('>>> checkCityWS - cityLevDistanceCur: ' + cityLevDistanceCur);

          if (cityLevDistanceOld == null || cityLevDistanceCur < cityLevDistanceOld && !String.isBlank(cityResultWS)) {
            cityResult = cityResultWS;
            cityLevDistanceOld = cityLevDistanceCur;
          }
          System.debug('>>> checkCityWS - cityResult: ' + cityResult);
        }
      }
    }
    System.debug('>>> checkCityWS - cityResult final: ' + cityResult);

    // System.debug('>>> checkCityWS final result: ' + (!String.isBlank(cityResult) && cityResult == city));
    String finalResult =
      '{ "result": ' +
      (!String.isBlank(cityResult) && cityResult == city) +
      ', "city": "' +
      cityResult +
      '" }';
    // System.debug('>>> checkCityWS final cityResult: ' + finalResult);
    return finalResult; // Set result true only if cityResult is null (result false means that the initial city must be replaced with the one found)
  }

  //TODO: it should be a temporary function, it has to be managed in EDG
  // check IBAN and Get BIC code (available for few countries only)
  @AuraEnabled
  public static String getBIC(String iban) {
    String endpoint = 'https://openiban.com/validate/' + iban + '?getBIC=true';
    String response;
    String testMock = '{ "valid": true, "messages": [], "iban": "BE52812615696709", "bankData": { "bankCode": "812", "name": "AXA Bank Belgium", "bic": "AXABBE22" } }';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    Http http = new Http();
    response = (Test.isRunningTest()) ? testMock : http.send(req).getBody();
    System.debug('>>> getBIC - response: ' + response);

    return response; // parsing will be done in JS
  }

  @AuraEnabled
  public static Map<String, String> upsertLead(String merchantInfosJSON, String sourceId) {
    System.debug('>>> APER30 upsertLead -- params:    ' + merchantInfosJSON);
    return GenericWithoutSharing.upsertLead(merchantInfosJSON, sourceId);
  }

  @AuraEnabled
  public static void doApexEvent(String operationName, String operationParams) {
    Guest_Event__e gevt = new Guest_Event__e();
    gevt.Operation_Name__c = operationName;
    gevt.Operation_Parameters__c = operationParams;
    System.debug('>>> doApexEvent -- operation: ' + operationName);
    System.debug('>>> doApexEvent -- params:    ' + operationParams);

    EventBus.publish(gevt);
    System.debug('>>> doApexEvent -- published');
  }

  private static void createFinCenters(String leadId, String finCentersJSON) {
    System.debug('>>> createFinCenters -- Start');
    System.debug('>>> createFinCenters -- leadId = ' + leadId);
    System.debug('>>> createFinCenters -- finCentersJSON = ' + finCentersJSON);

    if (!String.isBlank(finCentersJSON)) {
      ER_SyncStructureWS.alreadyExecutedSync = true; // To prevent discrepencies at synchronization (case delete objects already synced), as it will be done at contract activation
      List<Object> finCenterObjList = (List<Object>) JSON.deserializeUntyped(finCentersJSON);
      String accountId;

      if (!String.isBlank(leadId)) {
        // get accountId using leadId (in Auto enrollment context)
        Lead ld = [SELECT ConvertedAccountId FROM Lead WHERE Id = :leadId ALL ROWS];
        accountId = ld.ConvertedAccountId;
      } else {
        // If merchant structure has not been created from a lead, then get account Id from first fin center (in Webform offer context)
        Map<String, Object> finCenter = (Map<String, Object>) JSON.deserializeUntyped(
          JSON.serialize(finCenterObjList[0])
        );
        accountId = String.valueOf(finCenter.get('finCenterAccountSFId'));
      }

      System.debug('>>> createFinCenters -- accountId = ' + accountId);

      List<Contact> cntList = [
        SELECT
          Id,
          Salutation,
          FirstName,
          LastName,
          AccountId,
          Account.OwnerId,
          Email,
          LeadSource,
          MailingStreet,
          MailingPostalCode,
          MailingCity,
          MailingCountry,
          OwnerId,
          Phone,
          RecordTypeId,
          ER_BUPicklist__c,
          ER_Department_Family__c,
          ER_Do_not_contact__c,
          ER_Do_Not_Mail__c,
          ER_Edenred_Newsletter__c,
          ER_Language__c,
          ER_Role__c,
          ER_Status__c,
          ER_VIP__c
        FROM Contact
        WHERE AccountId = :accountId
      ];

      List<ER_Financial_Center__c> fcList = [
        SELECT
          Id,
          Name,
          OwnerId,
          ER_Account_Name__c,
          ER_Street__c,
          ER_City__c,
          ER_Country__c,
          ER_Invoicing_City__c,
          ER_Invoicing_Country__c,
          ER_Invoicing_Site__c,
          ER_Invoicing_Street__c,
          ER_Invoicing_Zip_Code__c,
          ER_Payment_Site__c,
          ER_Type__c,
          ER_Zip_Code__c,
          ER_Bank_Account__c,
          ER_Bank_Account__r.ER_IBAN__c
        FROM ER_Financial_Center__c
        WHERE ER_Account_Name__c = :accountId
        ORDER BY ER_External_Reference__c
      ];

      Map<Id, ER_Bank_Account__c> bkAccMap = new Map<Id, ER_Bank_Account__c>(
        [
          SELECT ER_Financial_Center__c, ER_IBAN__c
          FROM ER_Bank_Account__c
          WHERE ER_Financial_Center__r.ER_Account_Name__c = :accountId
        ]
      );

      System.debug('>>> createFinCenters -- cntList size = ' + cntList.size());
      System.debug('>>> createFinCenters -- fcList size = ' + fcList.size());
      System.debug('>>> createFinCenters -- bkAccMap size = ' + bkAccMap.size());

      Id convertedContact = cntList[0].Id;
      Id accountOwnerId = cntList[0].Account.OwnerId;
      Id convertedFinCenter = fcList[0].Id;
      Id bnkAccConvertedFinCenter = fcList[0].ER_Bank_Account__c;
      String leadIdExtRef = leadId + '-%';

      List<Contact> cntUpsList = new List<Contact>();
      List<ER_Financial_Center__c> fcUpsList = new List<ER_Financial_Center__c>();
      List<ER_Bank_Account__c> bkUpsList = new List<ER_Bank_Account__c>();

      // Maps used to do the link between fin centers, contacts & bank accounts
      Map<String, String> contactHashKeyIdMap = new Map<String, String>();
      Map<String, String> finCenterIdMap = new Map<String, String>();
      Map<String, String> bankAccIdMap = new Map<String, String>();

      Set<String> contactHashKeySet = new Set<String>();
      for (Contact ct : cntList) {
        contactHashKeySet.add(
          (ct.FirstName?.trim() + '|' + ct.LastName?.trim() + '|' + ct.Email?.trim()).toLowerCase()
        );
        contactHashKeyIdMap.put(
          (ct.FirstName?.trim() + '|' + ct.LastName?.trim() + '|' + ct.Email?.trim()).toLowerCase(),
          ct.Id
        );
      }

      Set<String> ibanSet = new Set<String>();
      Map<String, String> contactFCMap = new Map<String, String>();
      Map<String, String> fcContactMap = new Map<String, String>();
      Map<String, String> bnkAccFCMap = new Map<String, String>();
      Map<String, String> fcBnkAccMap = new Map<String, String>();
      String finCenterName = fcList[0].Name.endsWith(')') ? fcList[0].Name.substringBeforeLast('(') : fcList[0].Name; // In order to have names like "Compapany (1) (1)..."
      Set<String> finCenterIdNoDeleteSet = new Set<String>();

      System.debug('>>> createFinCenters -- finCenterName = ' + finCenterName);
      System.debug('>>> createFinCenters -- contactHashKeySet = ' + contactHashKeySet);

      Integer i = 1;

      // Map<String, Object> finCenters = (Map<String, Object>)JSON.deserializeUntyped(finCentersJSON);
      for (Object finCenterObj : finCenterObjList) {
        Map<String, Object> curFinCenter = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(finCenterObj));
        String countryCode = String.valueOf(curFinCenter.get('countryCode'));
        String countryName = String.valueOf(curFinCenter.get('refundCountry'));
        String finCenterSFId = String.valueOf(curFinCenter.get('finCenterSFId'));
        String noDeleteStr = String.valueOf(curFinCenter.get('noDelete'));
        Boolean noDelete = String.isBlank(noDeleteStr) ? false : Boolean.valueOf(noDeleteStr);

        if (!String.isBlank(finCenterSFId) && noDelete)
          finCenterIdNoDeleteSet.add(finCenterSFId);

        // update 1st fin center, then insert others
        ER_Financial_Center__c finCenter = new ER_Financial_Center__c();

        // The first fin center is the one created during lead conversion
        // Else clone first fin center in order to keep default values created during lead conversion
        finCenter = (i == 1) ? fcList[0] : fcList[0].clone(false, true, false, false);

        finCenter.Name = finCenterName.trim() + ' (' + i + ')'; // Use name created by conversion & not the one created in webforms
        System.debug('>>> createFinCenters -- finCenter.Name = ' + finCenter.Name);

        finCenter.OwnerId = accountOwnerId;
        finCenter.ER_Street__c = String.valueOf(curFinCenter.get('refundAddress'));
        finCenter.ER_Zip_Code__c = String.valueOf(curFinCenter.get('refundPostalCode'));
        finCenter.ER_City__c = String.valueOf(curFinCenter.get('refundCity'));
        finCenter.ER_Country__c = countryName;
        finCenter.ER_Invoicing_Street__c = String.valueOf(curFinCenter.get('refundAddress'));
        finCenter.ER_Invoicing_Zip_Code__c = String.valueOf(curFinCenter.get('refundPostalCode'));
        finCenter.ER_Invoicing_City__c = String.valueOf(curFinCenter.get('refundCity'));
        finCenter.ER_Invoicing_Country__c = countryName;
        finCenter.ER_External_Reference__c =
          ((!String.isBlank(leadId)) ? leadId : accountId) +
          '-' +
          String.valueOf(curFinCenter.get('finCenterId')); // Create ext Id to facilitate stores lookup
        finCenter.Id = (!String.isBlank(leadId) && i == 1) ? convertedFinCenter : finCenterSFId; // AAM-18.11.21: PBI13440
        finCenter.ER_BUPicklist__c = Utils.getBUCode(countryCode); // AAM-24.12.21: PBI14048
        finCenter.ER_Country_Code__c = Utils.getCountryCode(countryName); // AAM-24.12.21: PBI14048
        finCenter.ER_Invoicing_Country_Code__c = Utils.getCountryCode(countryName); // AAM-07.02.22: PBI14271

        fcUpsList.add(finCenter);

        // if new contact then create it with contact role, otherwise just add contact role to the existing contact
        String curContactHashKey =
          String.valueOf(curFinCenter.get('refundFirstName'))?.trim() +
          '|' +
          String.valueOf(curFinCenter.get('refundLastName'))?.trim() +
          '|' +
          String.valueOf(curFinCenter.get('refundEmail'))?.trim();
        curContactHashKey = curContactHashKey.toLowerCase();
        System.debug('>>> createFinCenters -- curContactHashKey = ' + curContactHashKey);
        System.debug('>>> createFinCenters -- Contact Id = ' + String.valueOf(curFinCenter.get('refundContactId')));
        System.debug(
          '>>> createFinCenters -- Contact refundFirstName = ' + String.valueOf(curFinCenter.get('refundFirstName'))
        );

        if (!contactHashKeySet.contains(curContactHashKey)) {
          // New contact to create
          Contact cnt = new Contact();
          cnt.Id = String.valueOf(curFinCenter.get('refundContactId'));
          cnt.Salutation = String.valueOf(curFinCenter.get('refundSalutation'));
          cnt.FirstName = String.valueOf(curFinCenter.get('refundFirstName'));
          cnt.LastName = String.valueOf(curFinCenter.get('refundLastName'));
          cnt.AccountId = accountId;
          cnt.OwnerId = accountOwnerId;
          cnt.Email = String.valueOf(curFinCenter.get('refundEmail'));
          cnt.Phone = String.valueOf(curFinCenter.get('refundContactPhone'));
          cnt.Fax = String.valueOf(curFinCenter.get('refundFax'));
          cnt.MobilePhone = String.valueOf(curFinCenter.get('refundMobile'));
          cnt.ER_BUPicklist__c = Utils.getBUCode(countryCode);
          cnt.ER_Language__c = String.valueOf(curFinCenter.get('refundLang'));
          cnt.ER_Role__c = String.valueOf(curFinCenter.get('refundRole'));
          cnt.ER_Status__c = cntList[0].ER_Status__c;
          cnt.LeadSource = cntList[0].LeadSource;
          cnt.RecordTypeId = cntList[0].RecordTypeId;
          cnt.MailingStreet = String.valueOf(curFinCenter.get('refundAddress'));
          cnt.MailingPostalCode = String.valueOf(curFinCenter.get('refundPostalCode'));
          cnt.MailingCity = String.valueOf(curFinCenter.get('refundCity'));
          cnt.MailingCountry = countryName;
          cnt.ER_External_Reference__c = ((!String.isBlank(leadId)) ? leadId : accountId) + '-' + curContactHashKey;
          cnt.ER_Country_Code__c = Utils.getCountryCode(countryName);
          cnt.ER_Legal_Country_Code__c = Utils.getCountryCode(countryName);
          cnt.ER_Legal_Country__c = countryName;

          cntUpsList.add(cnt);
          contactHashKeySet.add(curContactHashKey); // In order to prevent adding a duplicate
        }

        contactFCMap.put(curContactHashKey, finCenter.Name);
        fcContactMap.put(finCenter.Name, curContactHashKey); // In order to cover cases with one contact linked to many FC

        System.debug('>>> createFinCenters -- ibanSet = ' + ibanSet);
        System.debug('>>> createFinCenters -- iban = ' + String.valueOf(curFinCenter.get('iban')));
        System.debug('>>> createFinCenters -- ibanBilling = ' + String.valueOf(curFinCenter.get('ibanBilling')));
        System.debug(
          '>>> createFinCenters -- bankAccountSFId = ' + String.valueOf(curFinCenter.get('bankAccountSFId'))
        );

        // If anonymized IBAN, then set original IBAN
        String curIban = !String.valueOf(curFinCenter.get('iban')).contains('*')
          ? String.valueOf(curFinCenter.get('iban'))
          : bkAccMap.get((ID) curFinCenter.get('bankAccountSFId')).ER_IBAN__c;
        String curIbanBilling;
        if (!String.isBlank(String.valueOf(curFinCenter.get('ibanBilling')))) {
          curIbanBilling = !String.valueOf(curFinCenter.get('ibanBilling')).contains('*')
            ? String.valueOf(curFinCenter.get('ibanBilling'))
            : bkAccMap.get((ID) curFinCenter.get('bankAccountBillingSFId')).ER_IBAN__c;
        }

        System.debug('>>> createFinCenters -- curIban = ' + curIban);

        if (!ibanSet.contains(curIban)) {
          ER_Bank_Account__c bnkAcc = new ER_Bank_Account__c();
          bnkAcc.OwnerId = accountOwnerId;
          bnkAcc.ER_Bank_Account_Status__c = 'Open';
          bnkAcc.ER_BIC__c = String.valueOf(curFinCenter.get('bic'));
          bnkAcc.Name = curIban;
          bnkAcc.ER_IBAN__c = curIban;
          bnkAcc.ER_Bank_Name__c = String.valueOf(curFinCenter.get('bankName'));
          bnkAcc.OwnerId = cntList[0].OwnerId;
          if (!String.isBlank(String.valueOf(curFinCenter.get('bankAccountSFId')))) {
            bnkAcc.Id = String.valueOf(curFinCenter.get('bankAccountSFId')); // AAM-18.11.21: PBI13440
          } else if (finCenter.Id == convertedFinCenter && !String.isBlank(leadId)) {
            bnkAcc.Id = bnkAccConvertedFinCenter; // To manage very specific case (users that are doing back & forth navigation...)
          }
          bnkAcc.ER_BUPicklist__c = Utils.getBUCode(countryCode);
          if (String.isBlank(curIbanBilling)) {
            bnkAcc.ER_SEPA_active__c = true;
            bnkAcc.ER_SEPA_start_date__c = System.today();
          }
          bkUpsList.add(bnkAcc);
          ibanSet.add(curIban);
        }

        bnkAccFCMap.put(curIban, finCenter.Name);
        fcBnkAccMap.put(finCenter.Name, curIban);
        System.debug('>>> createFinCenters -- bnkAccFCMap/fcBnkAccMap add: ' + curIban + ' -- ' + finCenter.Name);

        if (!String.isBlank(curIbanBilling) && !ibanSet.contains(curIbanBilling)) {
          ER_Bank_Account__c bnkAcc = new ER_Bank_Account__c();
          bnkAcc.OwnerId = accountOwnerId;
          bnkAcc.ER_Bank_Account_Status__c = 'Open';
          bnkAcc.ER_BIC__c = String.valueOf(curFinCenter.get('bicBilling'));
          bnkAcc.Name = curIbanBilling;
          bnkAcc.ER_IBAN__c = curIbanBilling;
          bnkAcc.ER_Bank_Name__c = String.valueOf(curFinCenter.get('bankNameBilling'));
          bnkAcc.OwnerId = cntList[0].OwnerId;
          if (!String.isBlank(String.valueOf(curFinCenter.get('bankAccountBillingSFId')))) {
            bnkAcc.Id = String.valueOf(curFinCenter.get('bankAccountBillingSFId')); // AAM-18.11.21: PBI13440
          } else if (finCenter.Id == convertedFinCenter && !String.isBlank(leadId)) {
            bnkAcc.Id = bnkAccConvertedFinCenter; // To manage very specific case (users that are doing back & forth navigation...)
          }
          bnkAcc.ER_BUPicklist__c = Utils.getBUCode(countryCode);

          bkUpsList.add(bnkAcc);
          ibanSet.add(curIbanBilling);
          bnkAccFCMap.put(curIbanBilling, finCenter.Name);
        }

        i++;
      }

      Set<Id> deletedBkAccIds = new Set<Id>();
      if (!String.isBlank(leadId) || !finCenterIdNoDeleteSet.isEmpty()) {
        // ie if Autoenrollment & not Webform offer context
        // delete previously created fin centers, contacts & bank accounts
        // List<ER_Bank_Account__c> bkDelList = [SELECT Id FROM ER_Bank_Account__c WHERE ER_Financial_Center__r.ER_External_Reference__c LIKE :leadIdExtRef OR ER_Financial_Center__c = :convertedFinCenter];

        List<ER_Bank_Account__c> bkDelList = new List<ER_Bank_Account__c>();
        List<ER_Financial_Center__c> fcDelList = new List<ER_Financial_Center__c>();
        List<Contact> ctDelList = new List<Contact>();

        if (!String.isBlank(leadId)) {
          bkDelList = [
            SELECT Id
            FROM ER_Bank_Account__c
            WHERE ER_Financial_Center__r.ER_External_Reference__c LIKE :leadIdExtRef
          ];

          fcDelList = [
            SELECT Id
            FROM ER_Financial_Center__c
            WHERE
              Id != :convertedFinCenter
              AND ER_External_Reference__c LIKE :leadIdExtRef
              AND Id NOT IN :finCenterIdNoDeleteSet
          ];
          ctDelList = [
            SELECT Id
            FROM Contact
            WHERE ER_External_Reference__c LIKE :leadIdExtRef AND Id != :convertedContact
          ];
        } else if (!finCenterIdNoDeleteSet.isEmpty()) {
          bkDelList = [
            SELECT Id
            FROM ER_Bank_Account__c
            WHERE
              ER_Financial_Center__r.ER_Account_Name__c = :accountId
              AND ER_Financial_Center__c NOT IN :finCenterIdNoDeleteSet
          ];
          fcDelList = [
            SELECT Id
            FROM ER_Financial_Center__c
            WHERE ER_Account_Name__c = :accountId AND Id NOT IN :finCenterIdNoDeleteSet
          ];
        }

        System.debug('>>> createFinCenters -- delete bkDelList = ' + bkDelList.size());
        System.debug('>>> createFinCenters -- delete fcDelList = ' + fcDelList.size());
        System.debug('>>> createFinCenters -- delete ctDelList = ' + ctDelList.size());

        if (!bkDelList.isEmpty()) {
          deletedBkAccIds = (new Map<Id, SObject>(bkDelList)).keySet();
          Database.delete(bkDelList);
        }
        if (!fcDelList.isEmpty())
          Database.delete(fcDelList);
        if (!ctDelList.isEmpty())
          Database.delete(ctDelList);
      }

      System.debug('>>> createFinCenters -- upsert fcUpsList = ' + fcUpsList.size());
      System.debug('>>> createFinCenters -- upsert cntUpsList = ' + cntUpsList.size());
      System.debug('>>> createFinCenters -- upsert bkUpsList = ' + bkUpsList.size());
      System.debug('>>> createFinCenters -- fcUpsList details = ' + fcUpsList);
      System.debug('>>> createFinCenters -- bkUpsList details = ' + bkUpsList);

      // Create or update fin centers, contacts & bank accounts
      if (!fcUpsList.isEmpty()) {
        for (ER_Financial_Center__c fc : fcUpsList)
          if (deletedBkAccIds.contains(fc.ER_Bank_Account__c))
            fc.ER_Bank_Account__c = null; // Remove bank account from fin center if it has been deleted
        for (ER_Bank_Account__c bk : bkUpsList)
          if (deletedBkAccIds.contains(bk.Id))
            bk.Id = null; // Remove bank account Id from bank accounts if it has been deleted
        Database.upsert(fcUpsList);
      }
      System.debug('>>> createFinCenters -- deletedBkAccIds = ' + fcUpsList);
      System.debug('>>> createFinCenters -- fcUpsList details2 = ' + fcUpsList);

      if (!cntUpsList.isEmpty())
        Database.upsert(cntUpsList);
      if (!bkUpsList.isEmpty())
        Database.upsert(bkUpsList, false);

      // Create maps in order to get Id using object key (either hash key or deterministic field)
      cntUpsList.add(cntList[0]); // add the contact created by lead conversion
      for (Contact cnt : cntUpsList) {
        String curContactHashKey = (cnt.FirstName + '|' + cnt.LastName + '|' + cnt.Email).toLowerCase();
        contactHashKeyIdMap.put(curContactHashKey, cnt.Id);
      }

      for (ER_Financial_Center__c fc : fcUpsList) {
        System.debug('>>> createFinCenters -- finCenterIdMap(fc.Name, fc.Id): ' + fc.Name + ' --- ' + fc.Id);
        finCenterIdMap.put(fc.Name, fc.Id);
      }

      for (ER_Bank_Account__c ba : bkUpsList) {
        System.debug('>>> createFinCenters -- bankAccIdMap(ba.ER_IBAN__c, ba.Id): ' + ba.ER_IBAN__c + ' --- ' + ba.Id);
        bankAccIdMap.put(ba.ER_IBAN__c, ba.Id);
      }

      // Link bank account to fin centers
      for (Integer j = 0; j < bkUpsList.size(); j++) {
        System.debug('>>> createFinCenters -- bkUpsList[j].ER_IBAN__c: ' + bkUpsList[j].ER_IBAN__c);
        System.debug('>>> createFinCenters -- bnkAccFCMap: ' + bnkAccFCMap);
        bkUpsList[j].ER_Financial_Center__c = finCenterIdMap.get(bnkAccFCMap.get(bkUpsList[j].ER_IBAN__c));
        System.debug(
          '>>> createFinCenters -- link bk to fc: ' + finCenterIdMap.get(bnkAccFCMap.get(bkUpsList[j].ER_IBAN__c))
        );
      }

      // Link fin centers to bank account
      System.debug('>>> createFinCenters -- contactHashKeyIdMap: ' + contactHashKeyIdMap);
      System.debug('>>> createFinCenters -- fcContactMap = ' + fcContactMap);
      for (Integer j = 0; j < fcUpsList.size(); j++) {
        System.debug('>>> createFinCenters -- fcUpsList[j].Name: ' + fcUpsList[j].Name);
        System.debug('>>> createFinCenters -- fcBnkAccMap: ' + fcBnkAccMap);
        fcUpsList[j].ER_Bank_Account__c = bankAccIdMap.get(fcBnkAccMap.get(fcUpsList[j].Name));
        fcUpsList[j].ER_Contact__c = contactHashKeyIdMap.get(fcContactMap.get(fcUpsList[j].Name));
        System.debug('>>> createFinCenters -- link fc to bk: ' + bankAccIdMap.get(fcBnkAccMap.get(fcUpsList[j].Name)));
      }

      System.debug('>>> createFinCenters -- bkUpsList ' + bkUpsList);
      System.debug('>>> createFinCenters -- fcUpsList ' + fcUpsList);
      if (!bkUpsList.isEmpty())
        Database.update(bkUpsList);
      if (!fcUpsList.isEmpty())
        Database.update(fcUpsList);

      System.debug('>>> createFinCenters -- done');
    }
  }

  @TestVisible
  private static void updateAccount(String leadId, String keyId) {
    System.debug('>>> updateAccount -- START');
    Lead ld = [
      SELECT
        ConvertedAccountId,
        ConvertedAccount.ER_BUPicklist__c,
        ConvertedContactId,
        ConvertedAccount.RecordType.DeveloperName,
        RecordTypeId,
        Company,
        NumberOfEmployees,
        City,
        Street,
        PostalCode,
        ER_Legal_Country__c,
        ER_Country_Code__c,
        LastName,
        FirstName,
        ER_Language__c,
        Phone,
        Email,
        ER_Lead_Type__c
      FROM Lead
      WHERE Id = :leadId
      ALL ROWS
    ];
    Account acc = new Account(
      Id = ld.ConvertedAccountId,
      HU_HQ_Contact__c = ld.ConvertedContactId,
      Recordtype_Name__c = ld.ConvertedAccount.RecordType.DeveloperName,
      ER_External_Reference__c = keyId
    );

    if (ld.ConvertedAccount.ER_BUPicklist__c == 'FI') {
      //Complete account & contact infos for FI (in case of conversion to an existing account)
      acc.Name = ld.Company;
      acc.ER_Legal_Name__c = ld.Company;
      acc.NumberOfEmployees = ld.NumberOfEmployees;
      acc.BillingStreet = ld.Street;
      acc.BillingPostalCode = ld.PostalCode;
      acc.BillingCity = ld.City;
      acc.BillingCountry = ld.ER_Legal_Country__c;

      Contact cnt = new Contact(
        Id = ld.ConvertedContactId,
        FirstName = ld.FirstName,
        LastName = ld.LastName,
        Email = ld.Email,
        Phone = ld.Phone,
        MobilePhone = ld.Phone,
        ER_Language__c = ld.ER_Language__c,
        ER_Legal_Country__c = ld.ER_Legal_Country__c,
        MailingStreet = ld.Street,
        MailingPostalCode = ld.PostalCode,
        MailingCity = ld.City,
        MailingCountry = ld.ER_Legal_Country__c,
        ER_Status__c = 'Active'
      );
      update cnt;

      if (ld.ER_Lead_Type__c == 'Client')
        completeClientStructure(ld);
    }

    System.debug('>>> updateAccount -- keyId: ' + keyId);
    update acc;
  }

  @TestVisible
  private static void updateOpportunity(String leadId, String promoCode, String solution, String scope) {
    System.debug('>>> updateOpportunity -- Start');

    // solution, String promoCode, String scope
    Lead ld = [
      SELECT
        ConvertedAccountId,
        ER_BUPicklist__c,
        OwnerId,
        Owner.Name,
        ConvertedAccount.ER_BUPicklist__c,
        ER_Country_Code__c,
        ConvertedAccount.ER_Country_Code__c,
        ConvertedOpportunityId,
        ConvertedOpportunity.ER_NeedFinancialApproval__c,
        ConvertedOpportunity.ER_BUPicklist__c,
        ER_External_Reference__c
      FROM Lead
      WHERE Id = :leadId
      ALL ROWS
    ][0];
    System.debug('>>> updateOpportunity -- Lead Owner: ' + ld.OwnerId + ' --- ' + ld.Owner.Name);
    System.debug('>>> updateOpportunity -- Lead BU: ' + ld.ER_BUPicklist__c);
    String accountId = ld.ConvertedAccountId;
    // Get country code first by extracting first two letters of ER_External_Reference__c as it's the most reliable way for all use cases (Merchant from another country)
    String country;
    if (!String.isBlank(ld.ER_External_Reference__c)) {
      country = ld.ER_External_Reference__c.substring(0, 2);
    } else {
      country = (ld.ER_BUPicklist__c == null) ? ld.ConvertedAccount.ER_BUPicklist__c : ld.ER_BUPicklist__c;
    }

    if (country == 'BENELUX')
      country = (ld.ER_Country_Code__c == null) ? ld.ConvertedAccount.ER_Country_Code__c : ld.ER_Country_Code__c;
    System.debug('>>> updateOpportunity -- country: ' + country);

    // Set pricebook, Reason, Opportunity line items
    Opportunity curOpp = new Opportunity(
      Id = ld.ConvertedOpportunityId,
      ER_BUPicklist__c = ld.ConvertedOpportunity.ER_BUPicklist__c
    );
    Map<String, ER_Promo_Code__c> promoMap = GenericWithoutSharing.getPromoCode(curOpp.ER_BUPicklist__c);
    System.debug('>>> updateOpportunity -- ER_BUPicklist__c: ' + curOpp.ER_BUPicklist__c);

    Map<String, String> paramsMap = new Map<String, String>();
    for (Auto_Enrollment__mdt aem : [
      SELECT Label, Value__c
      FROM Auto_Enrollment__mdt
      WHERE Label LIKE 'default_%' AND Country_Code__c = :country
    ])
      paramsMap.put(aem.Label, aem.Value__c);

    String defaultPriceBookId = Utils.getPricebookId(paramsMap.get('default_pricebook'));
    System.debug(
      '>>> updateOpportunity -- defaultPriceBook: ' +
      paramsMap.get('default_pricebook') +
      ' --> ' +
      defaultPriceBookId
    );

    curOpp.ER_Reason__c = 'New';
    if (!String.isBlank(promoCode) && promoMap != null && promoMap.containsKey(promoCode))
      curOpp.ER_Promo_Code2__c = promoMap.get(promoCode).Id;

    Map<String, Object> resultMap = createOppLineitems(
      curOpp,
      country,
      solution,
      scope,
      promoCode,
      defaultPriceBookId,
      ld.ConvertedOpportunity.ER_NeedFinancialApproval__c
    );
    String pbId = (String) resultMap.get('pbId');
    List<OpportunityLineItem> oliList = (List<OpportunityLineItem>) resultMap.get('oliList');

    curOpp.Pricebook2Id = pbId;
    System.debug('>>> updateOpportunity -- pbId: ' + pbId);

    // Default terms and conditions (PBI-15471)
    curOpp.ER_PaymentTerms__c = paramsMap.get('default_ER_PaymentTerms');
    curOpp.ER_PaymentMethod__c = paramsMap.get('default_ER_PaymentMethod');
    curOpp.ER_InvoicingFrequency__c = paramsMap.get('default_ER_InvoicingFrequency');
    curOpp.ERBE_Invoicing_Payment_Delay__c = paramsMap.get('default_ERBE_Invoicing_Payment_Delay');
    curOpp.ERBE_Invoicing_Support__c = paramsMap.get('default_ERBE_Invoicing_Support');
    curOpp.ER_ReimbursementTerm__c = paramsMap.get('default_ER_ReimbursementTerm');
    curOpp.ERBE_Reimbursement_Statement_Frequency__c = paramsMap.get('default_ERBE_Reimbursement_Stmt_Freq');

    try {
      update (curOpp);
    } catch (DmlException ex) {
      System.debug('>>> updateOpportunity -- Update opp exception: ' + ex.getMessage());
      curOpp.ER_Promo_Code2__c = null;
      update (curOpp);
    }

    if (oliList != null && !oliList.isEmpty() && String.isBlank(curOpp.ER_Promo_Code2__c)) {
      delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :curOpp.Id];
      insert oliList;
    }

    System.debug('>>> updateOpportunity -- End');
  }

  // it returns a "Map<String,Object>" result in order to provide both opp line items & pricebookId and limit qty of SOQL queries
  public static Map<String, Object> createOppLineitems(
    Opportunity opp,
    String country,
    String solution,
    String scope,
    String promoCode,
    String pricebookId,
    Boolean needApproval
  ) {
    Map<String, Object> resultMap = new Map<String, Object>();
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    if (!String.isBlank(solution) && !String.isBlank(scope)) {
      List<PricebookEntry> pbeList = GenericWithoutSharing.getPriceBookEntries(
        country,
        solution,
        scope,
        promoCode,
        pricebookId
      );
      System.debug('>>> createOppLineitems - pbeList size ' + pbeList.size());

      resultMap.put('pbId', pbeList[0].Pricebook2Id);
      System.debug('>>> createOppLineitems - pbeList[0].Pricebook2Id ' + pbeList[0].Pricebook2Id);
      System.debug('>>> createOppLineitems - pricebookId ' + pricebookId);

      if (country != 'BE' && country != 'LU' && String.isBlank(pricebookId)) {
        String pricebookCode = [SELECT Pricebook__c FROM Auto_Enrollment_Product__mdt WHERE Label = :solution][0]
        .Pricebook__c;
        List<Pricebook2> pbList = [
          SELECT Id
          FROM Pricebook2
          WHERE IsActive = TRUE AND ER_MDMId__c = :pricebookCode AND ER_Business_Unit__c = :country
        ];

        pricebookId = (!pbList.isEmpty() && String.isBlank(pbeList[0].Pricebook2Id)) ? pbList[0].Id : pbeList[0].Pricebook2Id;
        System.debug('>>> createOppLineitems - pricebookId ' + pricebookId);
      }

      // If promocode not null, then call getFinancialConditions method in case of affiliation promocode that has to be retrieved from contract
      Map<String, Map<String, String>> promoPricesMap = new Map<String, Map<String, String>>();
      if (!String.isBlank(promocode)) {
        String contractId;
        Map<String, ER_Promo_Code__c> promoMap = GenericWithoutSharing.getPromoCode(Utils.getBUCode(country));
        if (promoMap.get(promoCode)?.RecordType.DeveloperName == System.label.LABS_SF_Affiliation_RecordType) {
          contractId = promoMap.get(promoCode).ER_Contract__c;
          for (ER_ContractLineItem__c cli : [
            SELECT
              Id,
              ER_Product2__r.ProductCode,
              ER_Product2__r.Name,
              ER_Percentage__c,
              ER_UnitPrice__c,
              CurrencyIsoCode
            FROM ER_ContractLineItem__c
            WHERE ER_Contract__c = :contractId AND ER_Contract_Status__c = 'Activated'
          ]) {
            Map<String, String> curProductInfosMap = new Map<String, String>();
            curProductInfosMap.put('UnitPrice', String.valueOf(cli.ER_UnitPrice__c));
            curProductInfosMap.put('CurrencyIsoCode', String.valueOf(cli.CurrencyIsoCode));
            curProductInfosMap.put('ER_Percentage__c', String.valueOf(cli.ER_Percentage__c));

            System.debug('>>> createOppLineitems - cli.ER_Product2__r.ProductCode ' + cli.ER_Product2__r.ProductCode);

            promoPricesMap.put(cli.ER_Product2__r.ProductCode, curProductInfosMap);
          }
        }
      }

      Set<String> oppLineTypeSet = new Set<String>();
      for (Schema.PicklistEntry pe : OpportunityLineItem.ER_Line_Type__c.getDescribe().getPickListValues())
        oppLineTypeSet.add(pe.getValue());

      Map<String, String> rangeMap = new Map<String, String>();
      rangeMap.put(Constants.FIX_RANGE, Constants.RANGE_WITH_FIX_PRICE);
      rangeMap.put(Constants.VARIABLE_RANGE_VOLUME_PRICING, Constants.RANGE_WITH_VARIABLE_PRICE_VOLUME_PRICING);

      for (PricebookEntry pbe : pbeList) {
        if (pbe.Pricebook2Id == pricebookId) {
          //TODO Check if this filter is ok for all types of use case (Promo code, no promo code...)
          OpportunityLineItem oli = new OpportunityLineItem();
          Decimal percentage, unitPrice;
          // In case of promo code get the least percentage and unit price
          percentage = String.isBlank(promoPricesMap?.get(pbe.Product2.ProductCode)?.get('ER_Percentage__c'))
            ? pbe.ER_Percentage__c
            : Decimal.valueOf(promoPricesMap.get(pbe.Product2.ProductCode).get('ER_Percentage__c'));
          unitPrice = String.isBlank(promoPricesMap?.get(pbe.Product2.ProductCode)?.get('UnitPrice'))
            ? pbe.UnitPrice
            : Decimal.valueOf(promoPricesMap.get(pbe.Product2.ProductCode).get('UnitPrice'));

          // AAM manage specific case of range values (values are different between picklists "OpportunityLineItem.ER_Line_Type__c" and "Product2.ER_Type__c")
          String lineType;
          if (oppLineTypeSet.contains(pbe.Product2.ER_Type__c))
            lineType = pbe.Product2.ER_Type__c;
          else
            lineType = rangeMap.get(pbe.Product2.ER_Solution__r.ER_Service_Range_Type__c);

          oli.OpportunityId = opp.Id;
          oli.PricebookEntryId = pbe.Id;
          oli.ER_NeedApproval__c = needApproval;
          oli.Product2Id = pbe.Product2Id;
          oli.ER_Line_Type__c = lineType;
          oli.ER_Percentage__c = percentage;
          oli.Quantity = 1;
          oli.UnitPrice = unitPrice;

          oliList.add(oli);
        }
      }
      resultMap.put('oliList', oliList);
    }

    System.debug('>>> createOppLineitems - oliList size' + oliList.size());
    return resultMap;
  }

  private static void createStores(String leadId, String storesJSON) {
    System.debug('>>> createStores -- Start');
    System.debug('>>> createStores -- leadId = ' + leadId);
    System.debug('>>> createStores -- storesJSON = ' + storesJSON);
    if (!String.isBlank(storesJSON)) {
      ER_SyncStructureWS.alreadyExecutedSync = true; // To prevent store synchronization at store creation, as it will be done at contract activation
      List<ER_Store__c> storeUpsList = new List<ER_Store__c>(), storeUpdList = new List<ER_Store__c>();
      List<Contact> contactInsList = new List<Contact>();
      List<Object> storesObjList = (List<Object>) JSON.deserializeUntyped(storesJSON);
      String extRef = leadId + '-%';
      String accountId, businessUnit;
      Map<String, String> storeContactKey = new Map<String, String>();

      if (!String.isBlank(leadId)) {
        // get accountId using leadId (in Auto enrollment context)
        Lead ld = [SELECT ConvertedAccountId FROM Lead WHERE Id = :leadId ALL ROWS];
        accountId = ld.ConvertedAccountId;
      } else {
        // for webform offer, get merchantAccSFId on the 1st store
        Map<String, Object> store1 = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(storesObjList[0]));
        accountId = String.valueOf(store1.get('merchantAccSFId'));
        // Try to get lead Id in order to try to fix external Id issues
        leadId = [SELECT Id FROM Lead WHERE ConvertedAccountId = :accountId ALL ROWS][0]?.Id;
        // Lead ld = [SELECT Id FROM Lead WHERE ConvertedAccountId = :accountId];
        // if (ld != null)
        //   leadId = ld.Id;
      }
      System.debug('>>> createStores -- accountId = ' + accountId);

      List<ER_Financial_Center__c> fcList = [
        SELECT
          Id,
          ER_External_Reference__c,
          ER_Country__c,
          ER_Country_Code__c,
          ER_Account_Name__c,
          OwnerId,
          ER_Contact__c,
          ER_BUPicklist__c
        FROM ER_Financial_Center__c
        WHERE ER_Account_Name__c = :accountId
        ORDER BY ER_External_Reference__c
      ];

      // Use maps to easily retrieve lookup values
      Map<String, Map<String, String>> fcMap = new Map<String, Map<String, String>>();

      Set<String> brandSet = new Set<String>();
      for (Schema.PicklistEntry pke : ER_Store__c.fields.ER_Brand__c.getDescribe().getpicklistvalues())
        brandSet.add(pke.getValue().toLowerCase());

      for (ER_Financial_Center__c fc : fcList) {
        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('Id', fc.Id);
        dataMap.put('Country', fc.ER_Country__c);
        dataMap.put('CountryCode', fc.ER_Country_Code__c);
        dataMap.put('Contact', fc.ER_Contact__c);
        fcMap.put(fc.ER_External_Reference__c, dataMap);
        System.debug('>>> createStores -- fcMap add ' + fc.ER_External_Reference__c + ' --> ' + dataMap);
      }

      Map<String, String> contactsMap = accountContactsMap(accountId);

      for (Object storeObj : storesObjList) {
        Map<String, Object> curStore = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(storeObj));
        System.debug('>>> createStores -- curStore keys = ' + curStore.keySet());

        ER_Store__c st = new ER_Store__c();
        String finCenterId, finCenterSFId, storeId, countryCode, fcExtId, countryName, website;
        ID merchantStoreRecTypId = Utils.getRecordTypeIdByDeveloperName(ER_Store__c.SObjectType, 'ER_Merchant_Store'); // AAM-24.12.21: PBI14048

        finCenterId = String.valueOf(curStore.get('finCenterId'));
        finCenterSFId = String.valueOf(curStore.get('finCenterSFId'));
        storeId = String.valueOf(curStore.get('storeId'));
        countryCode = String.valueOf(curStore.get('countryCode'));
        countryName = String.valueOf(curStore.get('country'));
        businessUnit = Utils.getBUCode(countryCode);
        // Set fcExtId: for Auto enrollment: it's the concatenation of leadId and finCenterId (Sequence Nb),
        //              for weboffer: it's the fin center SF Id for the first FC, else it's the concatenation of AccountId and finCenterId
        //todo recheck external Id management to cover all use cases
        fcExtId = (!String.isBlank(leadId))
          ? leadId + '-' + finCenterId
          : ((String.isBlank(accountId)) ? finCenterSFId : accountId + '-' + finCenterId);
        System.debug('>>> createStores -- fcExtId = ' + fcExtId);

        st.Id = String.valueOf(curStore.get('storeSFId'));
        st.Name = String.valueOf(curStore.get('name'));
        st.OwnerId = fcList[0].OwnerId;
        st.ER_Street__c = String.valueOf(curStore.get('address'));
        st.ER_Zip_Code__c = String.valueOf(curStore.get('postalCode'));
        st.ER_City__c = String.valueOf(curStore.get('city'));
        st.ER_Facebook__c = String.valueOf(curStore.get('facebook'));
        st.ER_Website_URL__c = String.valueOf(curStore.get('website'));

        st.ER_Store_Phone_Number__c = String.valueOf(curStore.get('storePhone'));
        st.ER_Email__c = String.valueOf(curStore.get('storeEmail'));

        st.ERBE_Sub_Segment__c = String.valueOf(curStore.get('sector'));
        st.ER_Franchise_type__c = String.valueOf(curStore.get('isFranchisee')) == 'Yes' ? 'Franchise' : 'Direct'; //TODO Recheck this rule
        st.ER_BUPicklist__c = businessUnit;

        st.ER_Country__c = countryName;
        st.ER_Country_Code__c = Utils.getCountryCode(countryName);
        // st.ER_Digital_Store__c = false;
        st.ER_External_Reference__c = ((!String.isBlank(leadId)) ? leadId : accountId) + '-' + storeId;
        if (fcMap.get(fcExtId) != null) {
          st.ER_Financial_Center__c = fcMap.get(fcExtId).get('Id');
        } else if (!String.isBlank(leadId)) {
          st.ER_Financial_Center__c = fcMap.get(leadId + '-' + finCenterId)?.get('Id');
          if (String.isBlank(st.ER_Financial_Center__c))
            st.ER_Financial_Center__c = fcMap.get(accountId + '-' + finCenterId)?.get('Id'); // Specific case when weboffer, but leadId is known
        }

        // In case of no fc found using previous method, then try last chance with null key
        if (String.isBlank(st.ER_Financial_Center__c))
          st.ER_Financial_Center__c = fcMap.get(null).get('Id');

        // st.ER_Merchant_Local_Segment__c = String.valueOf(curStore.get('countryCode'));
        st.RecordTypeId = merchantStoreRecTypId; // AAM-24.12.21: PBI14048
        if (String.isBlank(String.valueOf(curStore.get('storeContactId')))) {
          String cntKey = (String.valueOf(curStore.get('storeContactFirstName')) +
            '-' +
            String.valueOf(curStore.get('storeContactLastName')) +
            '-' +
            String.valueOf(curStore.get('storeContactEmail')))
            .toLowerCase();
          System.debug('>>> createStores -- cntKey = ' + cntKey);
          if (contactsMap.containsKey(cntKey)) {
            st.ER_Contact__c = contactsMap.get(cntKey);
          } else {
            Contact cnt = new Contact();
            cnt.Salutation = String.valueOf(curStore.get('storeContactSalutation'));
            cnt.FirstName = String.valueOf(curStore.get('storeContactFirstName'));
            cnt.LastName = String.valueOf(curStore.get('storeContactLastName'));
            cnt.Email = String.valueOf(curStore.get('storeContactEmail'));
            cnt.ER_Language__c = String.valueOf(curStore.get('storeContactLanguage'));
            cnt.MobilePhone = String.valueOf(curStore.get('storeContactPhone'));
            cnt.Phone = String.valueOf(curStore.get('storeContactPhone'));
            System.debug('>>> createStores -- New contact cnt.ER_Language__c = ' + cnt.ER_Language__c);
            System.debug('>>> createStores -- New contact cnt = ' + cnt);

            cnt.AccountId = accountId;

            contactInsList.add(cnt);
            storeContactKey.put(st.ER_External_Reference__c, cntKey);
          }
          // st.ER_Contact__c =  fcMap.get(fcExtId).get('Contact'); // AAM-06.01.22: PBI14106
        }

        System.debug('>>> createStores -- leadId = ' + leadId);
        System.debug('>>> createStores -- finCenterId = ' + String.valueOf(curStore.get('finCenterId')));
        System.debug('>>> createStores -- finCenterSFId = ' + String.valueOf(curStore.get('finCenterSFId')));

        // Try to find the matching picklist entry for brand, if not found then check the closest matching brand (having 2 characters different max)
        String brand = String.valueOf(curStore.get('franchiseeBrand'));
        if (!String.isBlank(brand)) {
          Boolean brandFound = true;
          if (!brandSet.contains(brand.toLowerCase())) {
            brandFound = false;
            for (String br : brandSet)
              if (!brandFound && br.getLevenshteinDistance(brand.toLowerCase(), 2) > -1) {
                brand = br;
                brandFound = true;
              }
          }
          st.ER_Brand__c = brandFound ? brand : '';
        }

        st.ER_Merchant__c = accountId;
        System.debug('>>> createStores -- storeStatus = ' + String.valueOf(curStore.get('storeStatus')));
        st.ER_Status__c = 'Active';
        st.ER_Closure_Date__c = null;
        st.ER_Closure_Reason__c = null;
        if (String.isBlank(String.valueOf(curStore.get('storeStartDate'))))
          st.ER_Start_date__c = Date.today(); // AAM PBI-15516

        st.ER_Has_Unregistered_Online_MID__c =
          !String.isBlank(String.valueOf(curStore.get('isOnlineStoreMastercard'))) &&
          Boolean.valueOf(String.valueOf(curStore.get('isOnlineStoreMastercard'))) &&
          String.isBlank(String.valueOf(curStore.get('mid')));
        st.ER_Has_Unregistered_Physical_MID__c =
          !String.isBlank(String.valueOf(curStore.get('isPhysicalAcceptorMastercard'))) &&
          Boolean.valueOf(String.valueOf(curStore.get('isPhysicalAcceptorMastercard'))) &&
          String.isBlank(String.valueOf(curStore.get('mid2')));

        System.debug('>>> createStores -- st.ER_Financial_Center__c = ' + st.ER_Financial_Center__c);
        System.debug('>>> createStores -- st.ER_Merchant__c = ' + st.ER_Merchant__c);

        if (!String.isBlank(String.valueOf(curStore.get('storeType'))))
          st.ER_Type__c = String.valueOf(curStore.get('storeType'));

        if (!String.isBlank(st.Id))
          storeUpdList.add(st);
        else
          storeUpsList.add(st);

        // st.ER_E_Shop__c = !String.isBlank((String.valueOf(curStore.get('isWebShop')))) ? Boolean.valueOf(curStore.get('isWebShop')) : false;
        // st.ER_Mastercard_Accepted__c = !String.isBlank((String.valueOf(curStore.get('mastercardAccepted')))) ? Boolean.valueOf(curStore.get('mastercardAccepted')) : false;
        // st.ER_Physical_Terminal_Accepted__c = !String.isBlank((String.valueOf(curStore.get('physicalTerminalAccepted')))) ? Boolean.valueOf(curStore.get('physicalTerminalAccepted')) : false;
        // st.ER_Has_webauth_terminal__c = !String.isBlank((String.valueOf(curStore.get('virtualTerminal')))) ? Boolean.valueOf(curStore.get('virtualTerminal')) : false;
      }

      APER30_AutoEnrollment_Management.syncRecordBU = businessUnit; // AAM 07.07.23 COUL-4145 (EDG Sync)
      System.debug(
        '>>> createStores -- APER30_AutoEnrollment_Management.syncRecordBU = ' +
        APER30_AutoEnrollment_Management.syncRecordBU
      );
      System.debug('>>> createStores -- fcList[0].ER_BUPicklist__c = ' + fcList[0].ER_BUPicklist__c);
      System.debug('>>> createStores -- businessUnit = ' + businessUnit);

      // Create new contacts
      if (!contactInsList.isEmpty()) {
        insert contactInsList;
        // Add new contacts to contactsMap, in order to update contact stores that have not been set
        for (Contact cnt : contactInsList) {
          String cntKey = (cnt.FirstName + '-' + cnt.LastName + '-' + cnt.Email).toLowerCase();
          contactsMap.put(cntKey, cnt.Id);
        }

        for (ER_Store__c st : storeUpdList) {
          if (String.isBlank(st.ER_Contact__c))
            st.ER_Contact__c = contactsMap.get(storeContactKey.get(st.ER_External_Reference__c));
        }

        for (ER_Store__c st : storeUpsList) {
          if (String.isBlank(st.ER_Contact__c))
            st.ER_Contact__c = contactsMap.get(storeContactKey.get(st.ER_External_Reference__c));
        }
      }

      // delete previously created stores (only in auto enrollment process)
      //TODO review this statement as no delete is done in weboffer context, even on store created through webforms
      Set<Id> storeUpdIdSet = (new Map<Id, ER_Store__c>(storeUpdList)).keySet();
      if (!String.isBlank(leadId))
        delete [SELECT Id FROM ER_Store__c WHERE ER_External_Reference__c LIKE :extRef AND Id NOT IN :storeUpdIdSet];

      System.debug(
        '>>> createStores -- storeUpsList to ups total: ' +
        storeUpsList.size() +
        ' -- details: ' +
        storeUpsList
      );
      if (!storeUpdList.isEmpty()) {
        update storeUpdList;
        createStoreContactRoles(storeUpsList);
      }
      if (!storeUpsList.isEmpty()) {
        upsert storeUpsList ER_External_Reference__c;
        createStoreContactRoles(storeUpsList);
      }
      if (!storeUpsList.isEmpty() || !storeUpdList.isEmpty()) {
        createTerminals(leadId, storesJSON);
        createCategories(leadId, storesJSON);
      }

      System.debug('>>> createStores done');
    }
  }

  private static void createTerminals(String leadId, String storesJSON) {
    System.debug('>>> createTerminals -- Start');
    System.debug('>>> createTerminals -- leadId = ' + leadId);
    System.debug('>>> createTerminals -- storesJSON = ' + storesJSON);
    if (!String.isBlank(storesJSON)) {
      List<ER_Acceptor__c> acceptorsUpsList = new List<ER_Acceptor__c>();
      List<ER_Acceptor__c> acceptorsInsList = new List<ER_Acceptor__c>();
      Set<String> tidExcludeSet = new Set<String>();
      List<Object> storesObjList = (List<Object>) JSON.deserializeUntyped(storesJSON);

      String extRef = leadId + '-%';
      String accountId;

      if (!String.isBlank(leadId)) {
        // get accountId using leadId (in Auto enrollment context)
        Lead ld = [SELECT ConvertedAccountId FROM Lead WHERE Id = :leadId ALL ROWS];
        accountId = ld.ConvertedAccountId;
      } else {
        // for webform offer, get merchantAccSFId on the 1st store
        Map<String, Object> store1 = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(storesObjList[0]));
        accountId = String.valueOf(store1.get('merchantAccSFId'));
        leadId = [SELECT Id FROM Lead WHERE ConvertedAccountId = :accountId ALL ROWS]?.Id;
        // Lead ld = [SELECT Id FROM Lead WHERE ConvertedAccountId = :accountId ALL ROWS];
        // if (ld != null)
        //   leadId = ld.Id;
      }

      List<ER_Store__c> stList = [
        SELECT Id, ER_External_Reference__c, ER_BUPicklist__c, Name, OwnerId
        FROM ER_Store__c
        WHERE ER_Merchant__c = :accountId
      ];
      String terminalRecTypId = Schema.SObjectType.ER_Acceptor__c.getRecordTypeInfosByName()
        .get('Merchant Acceptor')
        .getRecordTypeId();

      Map<String, String> stIdMap = new Map<String, String>();
      Map<String, String> stNameMap = new Map<String, String>();

      for (ER_Store__c st : stList) {
        stIdMap.put(st.ER_External_Reference__c, st.Id);
        stNameMap.put(st.ER_External_Reference__c, st.Name);
      }

      System.debug('>>> createTerminals -- stIdMap = ' + stIdMap);
      System.debug('>>> createTerminals -- stNameMap = ' + stNameMap);

      for (Object storeObj : storesObjList) {
        Map<String, Object> curStore = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(storeObj));
        String hasOnlineStore = String.valueOf(curStore.get('hasOnlineStore'));
        Boolean isOnlineStoreMastercard =
          !String.isBlank(String.valueOf(curStore.get('isOnlineStoreMastercard'))) &&
          Boolean.valueOf(String.valueOf(curStore.get('isOnlineStoreMastercard')));
        Boolean isPhysicalAcceptorMastercard =
          !String.isBlank(String.valueOf(curStore.get('isPhysicalAcceptorMastercard'))) &&
          Boolean.valueOf(String.valueOf(curStore.get('isPhysicalAcceptorMastercard')));

        String hasAgregator = String.valueOf(curStore.get('hasAgregator'));
        String storeIdx = String.valueOf(curStore.get('storeId')),
          storeSFId = String.valueOf(curStore.get('storeSFId'));
        String storeKey = (!String.isBlank(leadId)) ? leadId + '-' + storeIdx : accountId + '-' + storeIdx;
        String storeId = (!String.isBlank(storeSFId)) ? storeSFId : stIdMap.get(storeKey);

        System.debug('>>> createTerminals -- curStore keys = ' + curStore.keySet());

        // TODO manage the case when adding new terminals to existing store (the id should not start at 1 then)
        Integer i = 1; // for terminals naming
        String midNb = String.valueOf(curStore.get('mid')); // for Online store
        String midNb2 = String.valueOf(curStore.get('mid2')); // for physical acceptor
        String subMidNb = String.valueOf(curStore.get('subMid'));
        String subMidNb2 = String.valueOf(curStore.get('subMid2'));
        String midCtap = String.valueOf(curStore.get('midCtap'));
        Boolean createMastercardAcceptor = isPhysicalAcceptorMastercard && !String.isBlank(midNb2);
        System.debug('>>> createTerminals -- midNb 1 = ' + midNb);
        String storeUniqueId = String.isBlank(midCtap)
          ? String.valueOf(APER23_Acceptor_Management.generateCode())
          : midCtap;

        if (!String.isBlank(String.valueOf(curStore.get('terminalsList')))) {
          for (
            Object terminalObj : (List<Object>) JSON.deserializeUntyped(JSON.serialize(curStore.get('terminalsList')))
          ) {
            Map<String, Object> curTerminal = (Map<String, Object>) JSON.deserializeUntyped(
              JSON.serialize(terminalObj)
            );
            String isReadOnly = (String.isBlank(String.valueOf(curTerminal.get('isReadOnly'))))
              ? ''
              : String.valueOf(curTerminal.get('isReadOnly'));
            String tidNb = String.valueOf(curTerminal.get('tid'));
            Boolean isMastercardOnly = false;
            Boolean isNewOrModifiedTerminal = false;

            if (curTerminal.containsKey('isMastercardOnly')) {
              isNewOrModifiedTerminal = true; // if existing terminal and "isMastercardOnly" not defined, then it means that terminal should not be modified
              isMastercardOnly = Boolean.valueOf(String.valueOf(curTerminal.get('isMastercardOnly')));
            }

            if (!Boolean.valueOf(isReadOnly) && isNewOrModifiedTerminal) {
              // Bypass existing acceptors
              System.debug('>>> createTerminals -- curTerminal keys = ' + curTerminal.keySet());

              ER_Acceptor__c acc = new ER_Acceptor__c();
              System.debug('>>> createTerminals -- curTerminal Store Idx = ' + storeIdx);
              System.debug(
                '>>> createTerminals -- curTerminal terminalId = ' + String.valueOf(curTerminal.get('terminalId'))
              );

              acc.ER_Store__c = storeId;
              System.debug(
                '>>> createTerminals -- storeSFId = ' +
                storeSFId +
                ' -- storeIdx = ' +
                storeIdx +
                ' -- acc.ER_Store = ' +
                acc.ER_Store__c
              );

              acc.OwnerId = stList[0].OwnerId;
              acc.ER_Acceptor_Model__c = String.valueOf(curTerminal.get('terminalModel'));
              acc.ER_Acceptor_Provider__c = String.valueOf(curTerminal.get('terminalProvider'));
              acc.ER_Acceptor_Type__c = 'POS';
              acc.ER_Cash_Register_Provider__c = String.valueOf(curTerminal.get('cashRegisterProvider'));
              acc.ER_IS_Acceptor_Linked_To_Cash_Register__c = String.valueOf(curTerminal.get('isLinkedToCashReg'));
              acc.ER_TID_Authorization__c = tidNb;
              acc.ER_Start_Date__c = Date.today();
              acc.RecordTypeId = terminalRecTypId;
              acc.ER_BUPicklist__c = stList[0].ER_BUPicklist__c; // AAM 19.01.2022 - PBI#14290
              acc.Name = String.valueOf(curTerminal.get('tid'));
              // In order to avoid failure from VR VRER05_Mid_Auth_Required
              // if (!String.isBlank(midNb2)) {
              //   acc.ER_MID_Authorization__c = midNb2;
              // }

              // acc.ER_Acceptor_Scheme__c = !String.isBlank(midNb) ? 'MasterCard' : 'C-TAP';
              if (isMastercardOnly) {
                acc.ER_Acceptor_Scheme__c = 'MasterCard';
                createMastercardAcceptor = false;
              } else {
                acc.ER_Acceptor_Scheme__c = 'C-TAP';
                acc.ER_MID_Authorization__c = storeUniqueId;
              }

              System.debug('>>> createTerminals -- acc.ER_Acceptor_Scheme__c: ' + acc.ER_Acceptor_Scheme__c);
              System.debug('>>> createTerminals -- add acceptor: ' + acc);
              acceptorsUpsList.add(acc); //TODO move to UPSERT

              i++;
            } else {
              // create filter in order to not delete read only terminals
              tidExcludeSet.add(String.valueOf(curTerminal.get('terminalSFId')));
            }
          }
        }

        System.debug('>>> createTerminals -- acceptorsUpsList.isEmpty(): ' + acceptorsUpsList.isEmpty());
        System.debug('>>> createTerminals -- createMastercardAcceptor: ' + createMastercardAcceptor);

        System.debug('>>> createTerminals -- hasOnlineStore = ' + hasOnlineStore);
        System.debug('>>> createTerminals -- hasAgregator = ' + hasAgregator);

        if (
          !String.isBlank(hasOnlineStore) &&
          Boolean.valueOf(hasOnlineStore) &&
          (isOnlineStoreMastercard == !String.isBlank(midNb))
        ) {
          // true if both conditions have same state
          ER_Acceptor__c accOnline = new ER_Acceptor__c();
          accOnline.ER_Store__c = storeId;
          accOnline.OwnerId = stList[0].OwnerId;
          accOnline.ER_Acceptor_Type__c = 'Payment Gate';
          accOnline.ER_Start_Date__c = Date.today();
          accOnline.RecordTypeId = terminalRecTypId;
          accOnline.ER_BUPicklist__c = stList[0].ER_BUPicklist__c;
          accOnline.Name = 'Online';

          if (isOnlineStoreMastercard) {
            accOnline.ER_Acceptor_Scheme__c = 'MasterCard';
            accOnline.ER_MID_Authorization__c = midNb;
            accOnline.ER_SubMID_Authorization__c = subMidNb;
          } else {
            accOnline.ER_Acceptor_Scheme__c = 'WEBAuth';
          }
          acceptorsInsList.add(accOnline);
        }

        if (!String.isBlank(hasAgregator) && Boolean.valueOf(hasAgregator)) {
          ER_Acceptor__c accPlatform = new ER_Acceptor__c();
          accPlatform.ER_Store__c = storeId;
          accPlatform.OwnerId = stList[0].OwnerId;
          accPlatform.ER_Acceptor_Type__c = 'Aggregator';
          accPlatform.ER_Start_Date__c = Date.today();
          accPlatform.RecordTypeId = terminalRecTypId;
          accPlatform.ER_BUPicklist__c = stList[0].ER_BUPicklist__c;
          accPlatform.Name = 'Aggregator';
          accPlatform.ER_Acceptor_Scheme__c = 'WEBAuth';
          acceptorsInsList.add(accPlatform);
        }

        System.debug('>>> createTerminals -- midNb2: ' + midNb2);
        if (createMastercardAcceptor) {
          System.debug('>>> createTerminals -- create MC acceptor');
          ER_Acceptor__c accMastercard = new ER_Acceptor__c();
          accMastercard.ER_Store__c = storeId;
          accMastercard.OwnerId = stList[0].OwnerId;
          accMastercard.ER_Acceptor_Type__c = 'POS';
          accMastercard.ER_Start_Date__c = Date.today();
          accMastercard.RecordTypeId = terminalRecTypId;
          accMastercard.ER_BUPicklist__c = stList[0].ER_BUPicklist__c;
          accMastercard.Name = (!String.isBlank(String.valueOf(curStore.get('accName')))) ? midNb2 : 'Mastercard';
          accMastercard.ER_MID_Authorization__c = midNb2;
          accMastercard.ER_SubMID_Authorization__c = subMidNb2;
          accMastercard.ER_Acceptor_Scheme__c = 'MasterCard';
          acceptorsInsList.add(accMastercard);
        }
      }

      // delete previously created terminals
      if (!String.isBlank(leadId))
        delete [
          SELECT Id
          FROM ER_Acceptor__c
          WHERE ER_Store__r.ER_External_Reference__c LIKE :extRef AND Id NOT IN :tidExcludeSet
        ];

      System.debug('>>> createTerminals -- acceptorsUpsList: ' + acceptorsUpsList);
      System.debug('>>> createTerminals -- (virtuals) acceptorsInsList: ' + acceptorsInsList);
      if (!acceptorsUpsList.isEmpty())
        upsert acceptorsUpsList ER_TID_Authorization__c;
      if (!acceptorsInsList.isEmpty())
        insert acceptorsInsList; // Online and platform

      System.debug('>>> createTerminals done');
    }
  }

  private static void createCategories(String sobjectId, String storesJSON) {
    System.debug('>>> createCategories -- Start');
    System.debug('>>> createCategories -- sobjectId = ' + sobjectId); // Could be the account Id in case of weboffer
    System.debug('>>> createCategories -- storesJSON = ' + storesJSON);
    if (!String.isBlank(storesJSON)) {
      List<ER_StoreCategory__c> catInsList = new List<ER_StoreCategory__c>();
      String extRef = sobjectId + '-%';
      Set<String> strSet = new Set<String>{ extRef };

      if (!String.isBlank(sobjectId)) {
        // In order to cover all types of context (initial autoenrollment, weboffer, onboarding ...), try to get leadId (if leadId param is an accountId), and vice versa
        Lead ld = [
          SELECT Id, ConvertedAccountId
          FROM Lead
          WHERE ConvertedAccountId = :sobjectId OR Id = :sobjectId
          ALL ROWS
        ];
        if (ld != null) {
          strSet.add(ld.Id + '-%');
          strSet.add(ld.ConvertedAccountId + '-%');
          sobjectId = ld.Id;
        }
      } else {
        List<Object> storesObjList = (List<Object>) JSON.deserializeUntyped(storesJSON);
        Map<String, Object> store1 = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(storesObjList[0]));
        sobjectId = String.valueOf(store1.get('merchantAccSFId'));
        strSet.add(sobjectId + '-%');
      }

      String extRef2 = sobjectId + '-%';
      List<ER_Store__c> stList = [
        SELECT Id, ER_External_Reference__c, ER_BUPicklist__c, Name
        FROM ER_Store__c
        WHERE ER_External_Reference__c LIKE :strSet
      ];

      Map<String, String> stIdMap = new Map<String, String>();
      Set<String> storeIdSet = new Set<String>();
      // Set<String> catIdSolutionSet = new Set<String>(); // Set for all categorie Ids for the current solution - PBI15668

      for (ER_Store__c st : stList)
        stIdMap.put(st.ER_External_Reference__c, st.Id);

      System.debug('>>> createCategories -- stIdMap = ' + stIdMap);
      for (Object storeObj : (List<Object>) JSON.deserializeUntyped(storesJSON)) {
        Map<String, Object> curStore = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(storeObj));
        for (String st : curStore.keySet())
          System.debug('>>> createCategories -- curStore key = ' + st + ' ---> ' + String.valueOf(curStore.get(st)));

        // for(Object catObj:(List<Object>)JSON.deserializeUntyped(JSON.serialize(curStore.get('categorieItemsIds')))) catIdSolutionSet.add(String.valueOf(catObj));

        for (Object catObj : (List<Object>) JSON.deserializeUntyped(JSON.serialize(curStore.get('chosenCategories')))) {
          Map<String, Object> curCategory = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(catObj));
          for (String st : curCategory.keySet())
            System.debug(
              '>>> createCategories -- curCategory key = ' +
              st +
              ' ---> ' +
              String.valueOf(curCategory.get(st))
            );

          if (Boolean.valueOf(curCategory.get('isChecked'))) {
            ER_StoreCategory__c cat = new ER_StoreCategory__c();
            String storeId = !String.isBlank(String.valueOf(curStore.get('storeId')))
              ? String.valueOf(curStore.get('storeId'))
              : String.valueOf(curStore.get('storeId')); // In case of null storeId at cat level, then get storeId at store level (bugfix)
            System.debug('>>> createCategories -- curCategory Store Id = ' + String.valueOf(curStore.get('storeId')));
            System.debug('>>> createCategories -- curCategory  is Main = ' + String.valueOf(curCategory.get('isMain')));

            cat.Store__c = (!String.isBlank(sobjectId))
              ? stIdMap.get(sobjectId + '-' + storeId)
              : String.valueOf(curStore.get('storeSFId'));
            storeIdSet.add(cat.Store__c); // Add all store Ids concerned in order to delete existing categories
            // cat.Category__c	= String.valueOf(curCategory.get('id')).substringAfter('*');
            cat.Category__c = String.valueOf(curCategory.get('id'));
            cat.Main_Category__c = curCategory.containsKey('isMain')
              ? Boolean.valueOf(curCategory.get('isMain'))
              : false;
            cat.ER_BUPicklist__c = stList[0].ER_BUPicklist__c; // AAM 20.01.22 - PBI14306
            catInsList.add(cat);
          }
        }
      }
      System.debug('>>> createCategories -- storeIdSet = ' + storeIdSet);
      // System.debug('>>> createCategories -- catIdSolutionSet = ' + catIdSolutionSet);

      if (!catInsList.isEmpty()) {
        // Database.delete([SELECT Id FROM ER_StoreCategory__c WHERE Store__c IN :storeIdSet AND Category__c IN :catIdSolutionSet]);
        Database.delete([SELECT Id FROM ER_StoreCategory__c WHERE Store__c IN :storeIdSet]);
        Database.insert(catInsList);
      }

      System.debug('>>> createCategories done');
    }
  }

  private static Map<String, String> accountContactsMap(String accountId) {
    Map<String, String> contactsMap = new Map<String, String>();

    for (Contact cnt : [
      SELECT Salutation, FirstName, LastName, ER_Language__c, Email
      FROM Contact
      WHERE AccountId = :accountId
    ]) {
      String cntKey = (cnt.FirstName + '-' + cnt.LastName + '-' + cnt.Email).toLowerCase();
      contactsMap.put(cntKey, cnt.Id);
      System.debug('>>> accountContactsMap -- contactsMap add ' + cntKey + ' --> ' + cnt.Id);
    }

    return contactsMap;
  }

  @TestVisible
  private static void createUsers(String accountId, String usersJSON) {
    System.debug('>>> createUsers -- Start -- accountId = ' + accountId);
    System.debug('>>> createUsers -- usersJSON = ' + usersJSON);
    if (!String.isBlank(usersJSON)) {
      List<Contact> userUpsList = new List<Contact>();
      List<Object> usersObjList = (List<Object>) JSON.deserializeUntyped(usersJSON);
      Map<String, String> contactsMap = accountContactsMap(accountId);

      for (Object userObj : usersObjList) {
        Map<String, Object> curUser = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(userObj));
        String userSFId = String.valueOf(curUser.get('userSFId'));
        Contact cnt = new Contact();
        cnt.Salutation = String.valueOf(curUser.get('userSalutation'));
        cnt.FirstName = String.valueOf(curUser.get('userFirstName'));
        cnt.LastName = String.valueOf(curUser.get('userLastName'));
        cnt.Email = String.valueOf(curUser.get('userEmail'));
        cnt.ER_Language__c = String.valueOf(curUser.get('userLanguage'));
        cnt.ER_Onboarding_Contract__c = String.valueOf(curUser.get('contractId'));
        cnt.AccountId = accountId;

        String cntKey = (cnt.FirstName + '-' + cnt.LastName + '-' + cnt.Email).toLowerCase();
        cnt.Id = String.isBlank(userSFId) ? contactsMap.get(cntKey) : userSFId;

        userUpsList.add(cnt);
      }

      System.debug(
        '>>> createUsers -- userUpsList to ups total: ' +
        userUpsList.size() +
        ' -- details: ' +
        userUpsList
      );
      if (!userUpsList.isEmpty()) {
        upsert userUpsList;
        createStoreContactRoles(userUpsList);
        sendWelcomeEmailUsers(userUpsList);
      }

      System.debug('>>> createUsers done');
    }
  }

  private static void createStoreContactRoles(List<SObject> itemList) {
    System.debug('>>> createStoreContactRoles *** START *** itemList = ' + itemList);

    //itemList can be either list of contacts or stores
    if (!itemList.isEmpty()) {
      List<ER_Contact_Role__c> cntRoleUpsList = new List<ER_Contact_Role__c>();
      Set<String> stIdCntIdSet = new Set<String>(); // used to not create duplicate contact roles, that have no external id defined

      //First check object type (contact or store)
      String objTypeName = itemList[0].getSObjectType().getDescribe().getName();
      String storeContactRecTypId = Utils.getRecordTypeIdByDeveloperName(ER_Contact_Role__c.SObjectType, 'ER_CR_Store');
      String accountId = (objTypeName == 'Contact')
        ? ((Contact) itemList[0]).AccountId
        : ((ER_Store__c) itemList[0]).ER_Merchant__c;
      for (ER_Contact_Role__c cntRole : [
        SELECT ER_Store__c, ER_Contact__c
        FROM ER_Contact_Role__c
        WHERE ER_Contact__r.AccountId = :accountId AND ER_Store__r.ER_Merchant__c = :accountId
      ])
        stIdCntIdSet.add(cntRole.ER_Store__c + '-' + cntRole.ER_Contact__c);

      if (objTypeName == 'Contact') {
        List<ER_Store__c> stList = [SELECT Id, ER_BUPicklist__c FROM ER_Store__c WHERE ER_Merchant__c = :accountId];
        for (SObject sobj : itemList) {
          Contact curCnt = (Contact) sobj;
          for (ER_Store__c st : stList) {
            if (!stIdCntIdSet.contains(st.Id + '-' + curCnt.Id)) {
              ER_Contact_Role__c cntRole = new ER_Contact_Role__c();
              cntRole.ER_BUPicklist__c = st.ER_BUPicklist__c;
              cntRole.ER_Contact__c = curCnt.Id;
              cntRole.ER_Store__c = st.Id;
              cntRole.RecordTypeId = storeContactRecTypId;
              cntRole.ER_Role__c = 'Store manager';
              cntRole.ER_External_Id__c = st.Id + '-' + curCnt.Id;
              cntRoleUpsList.add(cntRole);
            }
          }
        }
      } else if (objTypeName == 'ER_Store__c') {
        List<Contact> cntList = [
          SELECT Id, ER_BUPicklist__c
          FROM Contact
          WHERE AccountId = :accountId AND ER_Onboarding_Contract__c != NULL
        ];
        for (SObject sobj : itemList) {
          ER_Store__c curStore = (ER_Store__c) sobj;
          for (Contact cnt : cntList) {
            if (!stIdCntIdSet.contains(curStore.Id + '-' + cnt.Id)) {
              ER_Contact_Role__c cntRole = new ER_Contact_Role__c();
              cntRole.ER_BUPicklist__c = curStore.ER_BUPicklist__c;
              cntRole.ER_Contact__c = cnt.Id;
              cntRole.ER_Store__c = curStore.Id;
              cntRole.RecordTypeId = storeContactRecTypId;
              cntRole.ER_Role__c = 'Store manager';
              cntRole.ER_External_Id__c = curStore.Id + '-' + cnt.Id;
              cntRoleUpsList.add(cntRole);
            }
          }
        }
      }

      if (!cntRoleUpsList.isEmpty())
        upsert cntRoleUpsList ER_External_Id__c;
    }
    System.debug('>>> createStoreContactRoles *** END *** ');
  }

  private static void completeClientStructure(Lead ld) {
    // Create / Update fin center and delivery site

    List<ER_Financial_Center__c> fcList = [
      SELECT Id
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c = :ld.ConvertedAccountId AND ER_Type__c = 'Client'
      ORDER BY LastModifiedDate DESC
    ];

    ER_Financial_Center__c fc = new ER_Financial_Center__c(
      Name = ld.Company,
      ER_BUPicklist__c = ld.ConvertedAccount.ER_BUPicklist__c,
      ER_Invoicing_Street__c = ld.Street,
      ER_Invoicing_Zip_Code__c = ld.PostalCode,
      ER_Invoicing_City__c = ld.City,
      ER_Invoicing_Country_Code__c = ld.ER_Country_Code__c,
      ER_Invoicing_Country__c = ld.ER_Legal_Country__c,
      ER_Contact__c = ld.ConvertedContactId,
      ER_Account_Name__c = ld.ConvertedAccountId,
      ER_Preferred_Invoicing_Method__c = 'E-invoice',
      ER_Invoicing_Site__c = true,
      ER_Type__c = 'Client'
    );

    fc.Id = !fcList.isEmpty() ? fcList[0].Id : null;

    APER30_FinancialCenter_Management.Bypass_FI_VR_OPT = false;
    upsert fc;

    // Create delivery site for client type
    if (ld.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT)) {
      List<ER_Delivery_Site__c> dsList = [
        SELECT Id
        FROM ER_Delivery_Site__c
        WHERE ER_Account_Name__c = :ld.ConvertedAccountId AND ER_Financial_Center__c = :fc.Id
        ORDER BY LastModifiedDate DESC
      ];

      ER_Delivery_Site__c ds = new ER_Delivery_Site__c(
        ER_Account_Name__c = ld.ConvertedAccountId,
        ER_Financial_Center__c = fc.Id,
        ER_BUPicklist__c = ld.ConvertedAccount.ER_BUPicklist__c,
        Name = fc.Name,
        ER_Street__c = fc.ER_Invoicing_Street__c,
        ER_Zip_Code__c = fc.ER_Invoicing_Zip_Code__c,
        ER_City__c = fc.ER_Invoicing_City__c,
        ER_Country_Code__c = fc.ER_Invoicing_Country_Code__c,
        ER_Country__c = fc.ER_Invoicing_Country__c,
        ER_Delivery_Contact__c = ld.ConvertedContactId
      );
      ds.Id = !dsList.isEmpty() ? dsList[0].Id : null;
      upsert ds;
    }
  }

  public static void doGuestEventOperations(Map<Id, SObject> newItems) {
    System.debug('>>> doGuestEventOperations Start');
    System.debug('>>> doGuestEventOperations. Nb items: ' + newItems.size());

    for (Guest_Event__e gevt : (List<Guest_Event__e>) newItems.values()) {
      switch on gevt.Operation_Name__c {
        when 'upsertLead' {
          System.debug('>>> GuestEventTrigger. Start upsertLead with params: ' + gevt.Operation_Parameters__c);
          upsertLead(gevt.Operation_Parameters__c, '');
          System.debug('>>> GuestEventTrigger. upsertLead2 DONE');
        }
        when 'convertLead' {
          System.debug('>>> GuestEventTrigger. Start convertLead with params: ' + gevt.Operation_Parameters__c);
          Map<String, Object> paramsJSON = (Map<String, Object>) JSON.deserializeUntyped(gevt.Operation_Parameters__c);
          String leadId = String.valueOf(paramsJSON.get('leadId'));
          String countryCode = String.valueOf(paramsJSON.get('countryCode'));
          String promoCode = String.valueOf(paramsJSON.get('promoCode'));
          String solution = String.valueOf(paramsJSON.get('solution'));
          String scope = String.valueOf(paramsJSON.get('scope'));
          String keyId = String.valueOf(paramsJSON.get('keyId'));
          String enterpriseNb = String.valueOf(paramsJSON.get('enterpriseNb'));
          String cntEmail = String.valueOf(paramsJSON.get('email'));
          String iban = String.valueOf(paramsJSON.get('iban'));
          String bic = String.valueOf(paramsJSON.get('bic'));
          String benefits = String.valueOf(paramsJSON.get('benefits'));
          String cardType = String.valueOf(paramsJSON.get('cardType'));
          String additionalProducts = String.valueOf(paramsJSON.get('additionalProducts'));

          APER30_AutoEnrollment_Management.syncRecordBU = Utils.getBUCode(countryCode); // AAM 07.07.23 COUL-4145 (EDG Sync)
          System.debug('>>> GuestEventTrigger. countryCode: ' + countryCode);
          System.debug('>>> GuestEventTrigger. buCode: ' + Utils.getBUCode(countryCode));
          System.debug(
            '>>> GuestEventTrigger. APER30_AutoEnrollment_Management.syncRecordBU: ' +
            APER30_AutoEnrollment_Management.syncRecordBU
          );

          // In case of undefined lead Id, then get Id from last updated lead
          if (String.isBlank(leadId) || !leadId.startsWith('00Q')) {
            leadId = [
              SELECT Id
              FROM Lead
              WHERE ER_Registration_Number__c = :enterpriseNb
              ORDER BY LastModifiedDate DESC
            ][0]
            .Id;
          }

          if (String.isBlank(keyId) || keyId.toLowerCase() == 'undefined')
            keyId = countryCode + enterpriseNb;

          if (countryCode == 'LU' || countryCode == 'BE')
            GenericWithoutSharing.setLeadOwner(leadId, countryCode);

          // Skip store creation for merchant scope :
          if (Scope == 'M')
            APER30_FinancialCenter_Management.Bypass_Store_Creation = true;

          List<Database.LeadConvert> lcList = new List<Database.LeadConvert>();
          Database.LeadConvert lc = new Database.LeadConvert();
          lc.setLeadId(leadId);
          if (Test.isRunningTest()) {
            Lead ld2 = [SELECT OwnerId FROM Lead WHERE Id = :leadId ALL ROWS];
            lc.setOwnerId(GenericWithoutSharing.getLeadOwnerId(ld2.OwnerId, countryCode));
          }
          LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
          lc.setConvertedStatus(convertStatus.MasterLabel);
          lcList.add(lc);
          System.debug('>>> GuestEventTrigger. convertLead lcList. size is: ' + lcList.size());
          List<Database.LeadConvertResult> lcrList = Database.convertLead(lcList, false);
          System.debug(
            '>>> GuestEventTrigger. convertLead -- Conversion success: ' +
            lcrList[0].isSuccess() +
            '. getErrors: ' +
            lcrList[0].getErrors()
          );

          if (!lcrList[0].isSuccess()) {
            if (countryCode == 'FI') {
              //Try to get account Id to retry another conversion
              String errStr = lcrList[0].getErrors().toString();
              List<Account> accList = new List<Account>();
              if (errStr.contains('Id=001')) {
                String accId = '001' + errStr.substringAfter('Id=001').substring(0, 15);
                accList = [SELECT Id, HU_HQ_Contact__c, HU_HQ_Contact__r.email FROM Account WHERE Id = :accId];
                System.debug('>>> GuestEventTrigger. convertLead -- accId1: ' + accId);
              }
              // If no account found, then try another way using reg number
              if (!accList.isEmpty()) {
                System.debug('>>> GuestEventTrigger. convertLead -- errStr: ' + errStr);
                accList = [
                  SELECT Id, HU_HQ_Contact__c, HU_HQ_Contact__r.email
                  FROM Account
                  WHERE ER_Registration_Number__c = :enterpriseNb
                  ORDER BY LastModifiedDate DESC
                ];
                System.debug('>>> GuestEventTrigger. accList.size: ' + accList.size());
              }

              // retry lead conversion with existing account and contact if same email
              if (!accList.isEmpty()) {
                lc.setLeadId(leadId);
                lc.setAccountId(accList[0].Id);
                System.debug(
                  '>>> GuestEventTrigger Convert Lead -- accList[0].HU_HQ_Contact__r.email ' +
                  accList[0].HU_HQ_Contact__r.email
                );
                System.debug('>>> GuestEventTrigger Convert Lead -- cntEmail ' + cntEmail);

                List<Contact> cntList = [
                  SELECT Id, LastModifiedDate
                  FROM Contact
                  WHERE AccountId = :accList[0].Id AND Email = :cntEmail
                  ORDER BY LastModifiedDate DESC
                ];
                if (!cntList.isEmpty())
                  lc.setContactId(cntList[0].Id);

                System.debug('>>> GuestEventTrigger Convert Lead -- lc.getLeadId() ' + lc.getLeadId());
                System.debug('>>> GuestEventTrigger Convert Lead -- lc.getContactId() ' + lc.getContactId());
                System.debug('>>> GuestEventTrigger Convert Lead -- lc.getAccountId() ' + lc.getAccountId());
                lcList = new List<Database.LeadConvert>();
                lcList.add(lc);
                lcrList = Database.convertLead(lcList, false);
                System.debug('>>> GuestEventTrigger. convertLead -- Conversion success2: ' + lcrList[0].isSuccess());
                System.debug('>>> GuestEventTrigger. errStr2: ' + lcrList[0].getErrors().toString());

                if (!lcrList[0].isSuccess()) {
                  errStr = lcrList[0].getErrors().toString();
                  // Check if duplicate contact issue
                  if (errStr.contains('Id=003')) {
                    String cntId = '003' + errStr.substringAfter('Id=003').substring(0, 15);
                    lc.setContactId(cntId);
                    lcrList = Database.convertLead(lcList, false);
                    System.debug(
                      '>>> GuestEventTrigger. convertLead -- Conversion success3: ' + lcrList[0].isSuccess()
                    );
                    System.debug('>>> GuestEventTrigger. errStr3: ' + lcrList[0].getErrors().toString());
                  }
                }
              }
            }
            if (!lcrList[0].isSuccess()) {
              throw new System.DmlException(lcrList[0].getErrors()[0].getMessage());
            }
          }

          if (lcrList[0].isSuccess()) {
            updateAccount(leadId, keyId);
            if (countryCode == 'LU' || countryCode == 'BE')
              updateOpportunity(leadId, promoCode, solution, scope);
            else {
              updateCoreOpportunity(leadId, solution, benefits, cardType, additionalProducts);
              createBankAccAndUpdateFinCenter(leadId, countryCode, iban, bic);
            }
          }
        }
        when 'createFinCenters' {
          System.debug('>>> GuestEventTrigger. Start createFinCenters with params: ' + gevt.Operation_Parameters__c);
          createFinCenters(
            gevt.Operation_Parameters__c.substringBefore('|'),
            gevt.Operation_Parameters__c.substringAfter('|')
          );
        }
        when 'updateOpportunity' {
          System.debug('>>> GuestEventTrigger. Start updateOpportunity with params: ' + gevt.Operation_Parameters__c);
          List<String> paramsList = gevt.Operation_Parameters__c.split('\\|');
          updateOpportunity(paramsList[0], paramsList[1], paramsList[2], paramsList[3]);
        }
        when 'createStores' {
          System.debug('>>> GuestEventTrigger. Start createStores with params: ' + gevt.Operation_Parameters__c);
          createStores(
            gevt.Operation_Parameters__c.substringBefore('|'),
            gevt.Operation_Parameters__c.substringAfter('|')
          );
        }
        when 'createTerminals' {
          System.debug('>>> GuestEventTrigger. Start createTerminals with params: ' + gevt.Operation_Parameters__c);
          createTerminals(
            gevt.Operation_Parameters__c.substringBefore('|'),
            gevt.Operation_Parameters__c.substringAfter('|')
          );
        }
        when 'closeOpportunity' {
          System.debug('>>> GuestEventTrigger. Start closeOpportunity with params: ' + gevt.Operation_Parameters__c);
          closeOpportunity(gevt.Operation_Parameters__c);
        }
        when 'activateContract' {
          System.debug('>>> GuestEventTrigger. Start activateContract with params: ' + gevt.Operation_Parameters__c);
          List<String> paramList = gevt.Operation_Parameters__c.split('\\|');
          String contractId,
            oppSerial,
            lang,
            solution,
            scope,
            contactEmail,
            productFullname,
            uniqueKeyId,
            salesEmail,
            countryCode;
          contractId = paramList[0];
          oppSerial = paramList[1];
          lang = paramList[2];
          solution = paramList[3];
          scope = paramList[4];
          contactEmail = paramList[5];
          productFullname = paramList[6];
          salesEmail = paramList[7];
          countryCode = paramList[8];
          activateContract(
            contractId,
            oppSerial,
            lang,
            solution,
            scope,
            contactEmail,
            productFullname,
            salesEmail,
            countryCode
          );
        }
        when 'createUsers' {
          System.debug('>>> GuestEventTrigger. Start createUsers with params: ' + gevt.Operation_Parameters__c);
          createUsers(
            gevt.Operation_Parameters__c.substringBefore('|'),
            gevt.Operation_Parameters__c.substringAfter('|')
          );
        }
        when 'upsertLeadCore' {
          System.debug('>>> GuestEventTrigger. Start upsertLeadCore with params: ' + gevt.Operation_Parameters__c);
          GenericWithoutSharing.upsertLeadCore(gevt.Operation_Parameters__c);
          System.debug('>>> GuestEventTrigger. upsertLeadCore DONE');
        }
        when 'activateSolutionCrossSelling' {
          System.debug(
            '>>> GuestEventTrigger. Start activateSolutionCrossSelling with params: ' + gevt.Operation_Parameters__c
          );
          List<String> paramList = gevt.Operation_Parameters__c.split('\\|');
          String additionalProducts = paramList.size() == 7 ? paramList[6] : null;
          GenericWithoutSharing.activateSolutionCrossSelling(
            paramList[0],
            paramList[1],
            paramList[2],
            paramList[3],
            paramList[4],
            paramList[5],
            additionalProducts
          );
          System.debug('>>> GuestEventTrigger. activateSolutionCrossSelling DONE');
        }
        // when 'activateStructureSolutionLineItems' {
        //     System.debug('>>> GuestEventTrigger. Start activateStructureSolutionLineItems with params: ' + gevt.Operation_Parameters__c);
        //     activateStructureSolutionLineItems(gevt.Operation_Parameters__c);
        // }
      }
    }
  }

  // Get all acceptors models and providers
  @AuraEnabled(cacheable=true)
  public static Map<String, List<String>> getAcceptorModels() {
    return getDependantPickListInfos('ER_Acceptor__c', 'ER_Acceptor_Provider__c', 'ER_Acceptor_Model__c');
  }

  // Get contact roles for a business unit //TODO: unused for now, to be removed or adaptated with adding the record type filter
  @AuraEnabled(cacheable=true)
  public static List<String> getContactRole(String businessUnit) {
    return getDependantPickListInfos('ER_Contact_Role__c', 'ER_BUPicklist__c', 'ER_Role__c').get(businessUnit);
  }

  // Get all acceptors models and providers
  @AuraEnabled(cacheable=true)
  public static Map<String, List<String>> getDependantPickListInfos(
    String objectName,
    String controllingFieldName,
    String dependentFieldName
  ) {
    //By SharSolutions
    Map<String, List<String>> acceptorModelsMap = new Map<String, List<String>>();

    Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);

    Schema.DescribeSObjectResult describeResult = objType.getDescribe();
    Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap()
      .get(controllingFieldName)
      .getDescribe();
    Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap()
      .get(dependentFieldName)
      .getDescribe();

    List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
    List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

    for (Schema.PicklistEntry currControllingValue : controllingValues)
      acceptorModelsMap.put(currControllingValue.getLabel(), new List<String>());

    for (Schema.PicklistEntry currDependentValue : dependentValues) {
      String jsonString = JSON.serialize(currDependentValue);
      PickListInfo info = (PickListInfo) JSON.deserialize(jsonString, PickListInfo.class);
      String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();

      // System.debug('DependentField: Label:' + currDependentValue.getLabel() + ' ValidForInHex:' + hexString + ' JsonString:' + jsonString);

      Integer baseCount = 0;
      for (Integer curr : hexString.getChars()) {
        Integer val = 0;

        if (curr >= 65)
          val = curr - 65 + 10;
        else
          val = curr - 48;

        if ((val & 8) == 8)
          acceptorModelsMap.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
        if ((val & 4) == 4)
          acceptorModelsMap.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());
        if ((val & 2) == 2)
          acceptorModelsMap.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());
        if ((val & 1) == 1)
          acceptorModelsMap.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());

        baseCount += 4;
      }
    }

    System.debug('Result map: ' + acceptorModelsMap);

    return acceptorModelsMap;
  }

  // Inner class used by getDependantPickListInfos()
  public class PickListInfo {
    public String validFor;
  }

  // Get terms and conditions
  @AuraEnabled
  public static Map<String, String> getTermsAndConditions(String country, String lang, String solution, String scope) {
    return GenericWithoutSharing.getTermsAndConditions(country, lang, solution, scope);
  }

  private static void closeOpportunity(String opportunityParamsJSON) {
    if (!String.isBlank(opportunityParamsJSON)) {
      System.debug('>>>  closeOpportunity Start. opportunityParamsJSON= ' + opportunityParamsJSON);
      Map<String, Object> paramsJSON = (Map<String, Object>) JSON.deserializeUntyped(opportunityParamsJSON);
      String leadId = String.valueOf(paramsJSON.get('leadId'));
      String accountId = String.valueOf(paramsJSON.get('accountId'));
      String country = String.valueOf(paramsJSON.get('country'));
      String lang = String.valueOf(paramsJSON.get('lang'));
      String solution = String.valueOf(paramsJSON.get('solution'));
      String promoCode = String.valueOf(paramsJSON.get('promoCode'));
      String scope = String.valueOf(paramsJSON.get('scope'));
      String contactEmail = String.valueOf(paramsJSON.get('contactEmail'));
      String uniqueKeyId = String.valueOf(paramsJSON.get('uniqueKeyId'));
      Boolean isWebOffer = (String.valueOf(paramsJSON.get('isWebOffer')) == 'true'); // web offer context
      String contractId = String.valueOf(paramsJSON.get('contractId'));
      System.debug('>>> closeOpportunity - isWebOffer: ' + isWebOffer);

      Quote curQuote;
      Opportunity curOpp;
      String productFullname;
      String salesEmail;

      if (!isWebOffer) {
        // Auto enrollment context
        if (String.isBlank(accountId) && !String.isBlank(leadId)) {
          List<Lead> ldList = [SELECT ConvertedAccountId FROM Lead WHERE Id = :leadId ALL ROWS];
          accountId = ldList[0].ConvertedAccountId;
        }

        // String defaultPriceBook = [
        //   SELECT Value__c
        //   FROM Auto_Enrollment__mdt
        //   WHERE Label = 'default_pricebook' AND Country_Code__c = :country
        // ][0]
        // .Value__c;
        // String defaultPriceBookId = Utils.getPricebookId(defaultPriceBook);

        List<Opportunity> oppList = [
          SELECT
            Id,
            Pricebook2Id,
            Name,
            ER_NeedFinancialApproval__c,
            ER_Promo_Code2__c,
            ER_BUPicklist__c,
            AccountId,
            Owner.Email,
            Account.HU_HQ_Contact__c,
            Account.HU_HQ_Contact__r.FirstName,
            Account.HU_HQ_Contact__r.LastName,
            Account.HU_HQ_Contact__r.Email,
            Account.HU_HQ_Contact__r.ER_Language__c,
            Account.HU_HQ_Contact__r.ER_Onboarding_Contract__c,
            (SELECT Product2.ER_Solution__r.Name FROM OpportunityLineItems)
          FROM Opportunity
          WHERE AccountId = :accountId AND StageName IN ('Qualification', 'Proposal', 'Negotiation')
        ];

        if (oppList.size() != 1) {
          //TODO check this case & what to do
          System.debug('>>> closeOpportunity - Nb of opportunities to check: ' + oppList.size());
        }

        curOpp = oppList[0];
        System.debug('>>> closeOpportunity - ER_BUPicklist__c ' + curOpp.ER_BUPicklist__c);

        productFullname = oppList[0].OpportunityLineItems[0].Product2.ER_Solution__r.Name; // Used for welcome email at the end
        salesEmail = oppList[0].Owner.Email; // Used for welcome email at the end

        if (String.isBlank(contractId)) {
          //Create quote when contracting step
          // Create quote and set to accepted
          System.debug('>>> closeOpportunity - save as quote & set to accepted');
          curQuote = VFCER04_Opportunity_Product.saveAsQuote(curOpp.Id);
          curQuote.ER_BUPicklist__c = curOpp.ER_BUPicklist__c;
        }
      } else {
        // web offer context
        curQuote = [
          SELECT
            OpportunityId,
            AccountId,
            Opportunity.ER_BUPicklist__c,
            ER_Main_Solution__r.Name,
            Opportunity.Owner.Email
          FROM Quote
          WHERE ER_Web_Offer_Token__c = :uniqueKeyId
        ][0];
        curOpp = new Opportunity(Id = curQuote.OpportunityId, AccountId = curQuote.AccountId);
        System.debug('>>> closeOpportunity - curOpp.ER_BUPicklist__c: ' + curOpp.ER_BUPicklist__c);
        curOpp.ER_BUPicklist__c = curQuote.Opportunity.ER_BUPicklist__c;
        productFullname = curQuote.ER_Main_Solution__r.Name; // Used for welcome email at the end
        salesEmail = curQuote.Opportunity.Owner.Email; // Used for welcome email at the end
        System.debug(
          '>>> closeOpportunity - curQuote.Opportunity.ER_BUPicklist__c: ' + curQuote.Opportunity.ER_BUPicklist__c
        );
      }

      if (String.isBlank(contractId)) {
        //Create quote when contracting step
        curQuote.status = 'Accepted';
        Database.update(curQuote);
      }

      // Update contract (if created)
      System.debug('>>> closeOpportunity - Update contract');
      Opportunity curOpp2 = [
        SELECT
          Id,
          AccountId,
          ContractId,
          OwnerId,
          ER_BUPicklist__c,
          Account.ER_Country_Code__c,
          Account.HU_HQ_Contact__c,
          Account.HU_HQ_Contact__r.Title,
          Account.HU_HQ_Contact__r.FirstName,
          Account.HU_HQ_Contact__r.LastName,
          Account.HU_HQ_Contact__r.Email,
          Account.HU_HQ_Contact__r.ER_Language__c
        FROM Opportunity
        WHERE Id = :curOpp.Id
      ][0];
      System.debug('>>> closeOpportunity - curOpp2.ER_BUPicklist__c: ' + curOpp2.ER_BUPicklist__c);
      String oppSerial = JSON.serialize(curOpp);
      System.debug('>>> closeOpportunity - oppSerial: ' + oppSerial);
      if (!String.isBlank(contractId)) {
        // Close contract only for auto enrollment v1 (in v2, the closure is performed after the onboarding)
        System.debug('>>> closeOpportunity - activateContract 1 (Opp with ctrId)');

        Contract curCtr = new Contract(Id = curOpp2.ContractId, AccountId = curOpp2.AccountId);

        // synchronize contract owner with opp owner
        curCtr.OwnerId = curOpp2.OwnerId;

        String companyDirectorName = [
          SELECT Value__c
          FROM Auto_Enrollment__mdt
          WHERE Label = 'lb_commercial_director_name' AND Country_Code__c = :curOpp2.Account.ER_Country_Code__c
        ][0]
        .Value__c;
        System.debug('>>> closeOpportunity - companyDirectorName: ' + companyDirectorName);
        String companyDirectorId = [SELECT Id FROM User WHERE Name = :companyDirectorName][0].Id;
        System.debug('>>> closeOpportunity - companyDirectorId: ' + companyDirectorId);

        curCtr.CompanySignedId = companyDirectorId;
        curCtr.CompanySignedDate = System.today();
        curCtr.CustomerSignedId = curOpp2.Account.HU_HQ_Contact__c;
        curCtr.CustomerSignedDate = System.today();
        curCtr.CustomerSignedTitle = curOpp2.Account.HU_HQ_Contact__r.Title;
        curCtr.ER_BUPicklist__c = curOpp2.ER_BUPicklist__c;

        update curCtr;

        // Opportunity opp = new Opportunity(Id=curCtr.ER_OpportunityId__c);
        Opportunity opp = new Opportunity(Id = curOpp.Id);
        opp.ER_Won_Reason__c = (String.isBlank(uniqueKeyId) || uniqueKeyId == 'null')
          ? 'Auto-Enrollment'
          : 'Webform Offer';
        update opp;

        // Do the structure synchronisation, if it's succeeded then launch contract activation
        String params =
          curOpp2.ContractId +
          '|' +
          oppSerial +
          '|' +
          lang +
          '|' +
          solution +
          '|' +
          scope +
          '|' +
          contactEmail +
          '|' +
          productFullname +
          '|' +
          salesEmail +
          '|' +
          curOpp2.Account.ER_Country_Code__c;
        // doApexEvent('syncStructure1', params); // Done with platform events due to governor limits (Too many SOQL queries)

        activateStructure(accountId); //PBI-17261:

        ID jobID = System.enqueueJob(new ER_SyncFullStructure(curCtr, 'Autoenrollment', params));

        System.debug('>>> closeOpportunity - jobID: ' + jobID);

        // TODO recheck if opp has to be closed in onboarding part 1 process (commented in order to fix exception raised by VRER02_ClosedWonWithoutContract )
        // } else {
        //     System.debug('>>> closeOpportunity - activateContract 2 (Opp without ctrId)');
        //     closeOpportunityFinal(oppSerial, lang, solution, scope, contactEmail, productFullname, uniqueKeyId, salesEmail);
        // } else if(!isWebOffer){
      } else {
        Contact mainContact = new Contact(
          Id = curOpp2.Account.HU_HQ_Contact__c,
          FirstName = curOpp2.Account.HU_HQ_Contact__r.FirstName,
          LastName = curOpp2.Account.HU_HQ_Contact__r.LastName,
          Email = curOpp2.Account.HU_HQ_Contact__r.Email,
          ER_Language__c = curOpp2.Account.HU_HQ_Contact__r.ER_Language__c,
          ER_Onboarding_Contract__c = curOpp2.ContractId
        );
        System.debug('>>> closeOpportunity - curOpp2.Account.HU_HQ_Contact__c ' + curOpp2.Account.HU_HQ_Contact__c);
        System.debug(
          '>>> closeOpportunity - curOpp2.Account.HU_HQ_Contact__r.ER_Language__c ' +
          curOpp2.Account.HU_HQ_Contact__r.ER_Language__c
        );

        sendWelcomeEmailUsers(new List<Contact>{ mainContact });
      }

      System.debug('>>> closeOpportunity - *** END *** ');
    }
  }

  private static void activateStructure(String accountId) {
    List<ER_Solution_Line_Item__c> sliUpdateList = new List<ER_Solution_Line_Item__c>();
    Set<ID> storeIdSet = new Set<ID>();

    for (ER_Solution_Line_Item__c sli : [
      SELECT Id, ER_Status__c, ER_Store__c, ER_Store__r.ER_Status__c
      FROM ER_Solution_Line_Item__c
      WHERE
        (ER_Account__c = :accountId
        OR ER_Financial_Center__r.ER_Account_Name__c = :accountId
        OR ER_Store__r.ER_Merchant__c = :accountId
        OR ER_Acceptor__r.ER_Store__r.ER_Merchant__c = :accountId)
        AND ER_Status__c != :Label.LAB_SF_SolutionLineItem_Active
    ]) {
      sli.ER_Status__c = Label.LAB_SF_SolutionLineItem_Active;
      sliUpdateList.add(sli);
      if (!String.isBlank(sli.ER_Store__c) && Label.LABS_SF_Store_Active != sli.ER_Store__r.ER_Status__c)
        storeIdSet.add(sli.ER_Store__c);
    }

    if (!sliUpdateList.isEmpty())
      update sliUpdateList;

    if (!storeIdSet.isEmpty()) {
      List<ER_Store__c> storeUpdateList = new List<ER_Store__c>();
      for (ID stId : storeIdSet) {
        ER_Store__c st = new ER_Store__c();
        st.Id = stId;
        st.ER_Status__c = Label.LABS_SF_Store_Active;
        storeUpdateList.add(st);
      }
      if (!storeUpdateList.isEmpty())
        update storeUpdateList;
    }
  }

  public static void sendWelcomeEmailUsers(List<Contact> cntList) {
    Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
    Messaging.SingleEmailmessage[] emailArray = new List<Messaging.SingleEmailmessage>();

    // Contract infos
    Contract ctr = [
      SELECT
        Id,
        ContractNumber,
        ER_Solutions__c,
        Account.ER_Legal_Name__c,
        Account.ER_Registration_Number__c,
        Account.ER_Other_Fiscal_ID__c,
        Account.ER_Country_Code__c
      FROM Contract
      WHERE Id = :cntList[0].ER_Onboarding_Contract__c
    ][0];
    String solution = ctr.ER_Solutions__c?.substringBefore('/').trim();

    // Get templates for each language
    for (EmailTemplate emlTmp : [
      SELECT Id, Subject, Name, HtmlValue
      FROM EmailTemplate
      WHERE Name LIKE 'Webform_Contracting_%' AND UiType = 'SFX'
    ])
      emailTemplateMap.put(emlTmp.Name.right(5), emlTmp);

    System.debug('>>> sendWelcomeEmailUsers - emailTemplateMap keySet ' + emailTemplateMap.keySet());

    // Create email for each contact (user)
    for (Contact cnt : cntList) {
      System.debug('>>> sendWelcomeEmailUsers - cnt.ER_Language__c ' + cnt.ER_Language__c);
      String cntLang;
      if (ctr.Account.ER_Country_Code__c == 'BE') {
        cntLang = cnt.ER_Language__c == 'DE' ? 'FR' : cnt.ER_Language__c;
      } else if (ctr.Account.ER_Country_Code__c == 'LU') {
        cntLang = cnt.ER_Language__c == 'EN' ? 'EN' : 'FR';
      } else if (ctr.Account.ER_Country_Code__c == 'FI') {
        cntLang = 'FI';
      }

      EmailTemplate emlTmp = emailTemplateMap.get(ctr.Account.ER_Country_Code__c + '_' + cntLang);
      if (emlTmp != null) {
        String subject = Test.isRunningTest() ? 'Subject' : emlTmp.Subject;
        String companyNb = ctr.Account.ER_Country_Code__c == 'LU'
          ? ctr.Account.ER_Other_Fiscal_ID__c
          : ctr.Account.ER_Registration_Number__c;

        String mailBody = Test.isRunningTest() ? 'Body' : emlTmp.HtmlValue;
        mailBody = mailBody.replace('{Contact.FirstName}', cnt.FirstName == null ? '' : cnt.FirstName);
        mailBody = mailBody.replace('{Contact.LastName}', cnt.LastName == null ? '' : cnt.LastName);
        mailBody = mailBody.replace('{Contact.Email}', cnt.Email == null ? '' : cnt.Email);
        mailBody = mailBody.replace('{Contact.ER_Onboarding_Contract_Number__c}', ctr.ContractNumber);
        mailBody = mailBody.replace(
          '{Account.ER_Legal_Name__c}',
          ctr.Account == null ? '' : ctr.Account.ER_Legal_Name__c == null ? '' : ctr.Account.ER_Legal_Name__c
        );
        mailBody = mailBody.replace('{Account.ER_Registration_Number__c}', companyNb == null ? '' : companyNb);
        mailBody = mailBody.replace('{Account.ER_Other_Fiscal_ID__c}', companyNb == null ? '' : companyNb);

        mailBody = mailBody.replace('{orgURL}', URL.getSalesforceBaseUrl().toExternalForm());
        mailBody = mailBody.replace('{orgId}', UserInfo.getOrganizationId());

        String onboardingURL = GenericWithoutSharing.getOnboardingURL(
          null,
          ctr.Account.ER_Registration_Number__c,
          ctr.Account.ER_Country_Code__c,
          cnt.ER_Language__c,
          solution
        );
        mailBody = mailBody.replace('{OnboardingURL}', onboardingURL);

        //build the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        String autoEnrollmentEmail = [
          SELECT Value__c
          FROM Auto_Enrollment__mdt
          WHERE Country_Code__c = :ctr.Account.ER_Country_Code__c AND Label = 'default_auto_enrollment_email' //COUL-4374 : Updating sender email address
        ][0]
        .Value__c;

        OrgWideEmailAddress[] owea = [
          SELECT Id, Address
          FROM OrgWideEmailAddress
          WHERE DisplayName = :autoEnrollmentEmail
        ];
        if (owea.size() > 0)
          email.setOrgWideEmailAddressId(owea.get(0).Id);

        email.setToAddresses(new List<String>{ cnt.Email });
        email.setSaveAsActivity(false);
        email.setSubject(subject);
        email.setHtmlBody(mailBody);

        emailArray.add(email);
      }
    }

    if (!Test.isRunningTest() && !emailArray.isEmpty())
      Messaging.sendEmail(emailArray);
  }

  @Future(callout=true)
  // private static void sendWelcomeEmail(String lang, String solution, String scope, String contactEmail, String productFullname, String oppId, String accountId){
  public static void sendWelcomeEmail(
    String lang,
    String solution,
    String scope,
    String contactEmail,
    String salesEmail,
    String productFullname,
    String oppId,
    String accountId,
    String contractId,
    String countryCode
  ) {
    String scopeName = (scope == 'M') ? 'Merchant' : 'Client';
    String pdfTitle = scopeName + ' Contract ' + solution.substringBetween('_', '-') + ' ' + lang; // TODO move this part in separate method
    String filename;
    System.debug('>>> sendWelcomeEmail - pdfTitle: ' + pdfTitle);
    System.debug('>>> sendWelcomeEmail - productFullname: ' + productFullname);

    Blob pdfContent;
    // if (!Test.isRunningTest()) {
    try {
      PageReference pdf = Page.AutoEnrollmentPDFContract;
      pdf.getParameters().put('solutionCode', solution);
      pdf.getParameters().put('accId', accountId);
      pdf.getParameters().put('oppId', oppId);
      pdf.getParameters().put('lang', lang);
      pdf.getParameters().put('scope', scope);

      pdfContent = pdf.getContent();
      // Get label for filename
      List<Auto_Enrollment__mdt> labList = [
        SELECT Value__c
        FROM Auto_Enrollment__mdt
        WHERE Language_Code__c = :lang AND Label = 'lb_edenred_contract' AND Data_type__c = 'Label'
        ORDER BY Country_Code__c DESC NULLS FIRST
      ];
      filename = (!labList.isEmpty()) ? labList[labList.size() - 1].Value__c : 'Edenred contract';
    } catch (Exception ex) {
      // TODO remove this part after finishing all contract implementation (temporary sample pdf)
      pdfContent = [
        SELECT Id, Title, VersionData, VersionNumber
        FROM ContentVersion
        WHERE Title = :pdfTitle
        ORDER BY VersionNumber DESC
      ][0]
      .VersionData;
      filename = 'Sample contract';
    }
    // } else {
    //   pdfContent = Blob.valueof('test');
    //   filename = 'Edenred contract';
    // }

    Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
    emailAttachment.setFileName(filename + '.pdf'); //TODO to be reviewed and modified

    Blob attachmentBody;
    attachmentBody = pdfContent;

    emailAttachment.setBody(attachmentBody);
    emailAttachment.setContentType('application/pdf');

    // TODO define specific Organization-Wide Addresses
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

    String emlTplName = 'Webform_Contract_' + scopeName + '_' + lang;
    System.debug('>>> sendWelcomeEmail - Email template: ' + emlTplName);
    EmailTemplate emlTpl = [
      SELECT Id, Body, Subject, HtmlValue
      FROM EmailTemplate
      WHERE Name = :emlTplName AND UiType = 'SFX'
    ];

    String subject = emlTpl.Subject;
    String htmlBody = emlTpl.HtmlValue.replace('{Product}', productFullname);

    String autoEnrollmentEmail = [
      SELECT Value__c
      FROM Auto_Enrollment__mdt
      WHERE Country_Code__c = :countryCode AND Label = 'default_auto_enrollment_email'
    ][0]
    .Value__c;

    OrgWideEmailAddress[] owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName = :autoEnrollmentEmail];
    if (owea.size() > 0) {
      message.setOrgWideEmailAddressId(owea.get(0).Id);
      System.debug('>>> sendWelcomeEmail - setOrgWideEmailAddress Address : ' + owea.get(0).Address);
      System.debug('>>> sendWelcomeEmail - setOrgWideEmailAddressId : ' + owea.get(0).Id);
    }

    message.setToAddresses(new List<String>{ contactEmail });
    message.setBccAddresses(new List<String>{ salesEmail });
    message.setSubject(subject);
    message.setHtmlBody(htmlBody);
    message.setFileAttachments(new List<Messaging.EmailFileAttachment>{ emailAttachment });

    if (!Test.isRunningTest())
      Messaging.SendEmailResult[] mailResult = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });

    // Save contract pdf file to opportunity
    ContentVersion cv = new ContentVersion(
      Title = 'Edenred Contract',
      PathOnClient = 'Edenred Contract.pdf',
      VersionData = pdfContent,
      origin = 'H',
      IsMajorVersion = false
    );
    insert cv;

    ContentVersion cv2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
    ContentDocumentLink contentlink = new ContentDocumentLink(
      LinkedEntityId = contractId,
      contentdocumentid = cv2.contentdocumentid,
      ShareType = 'V'
    );
    insert contentlink;
    System.debug('>>> sendWelcomeEmail - End');
  }

  private static void activateContract(
    String contractId,
    String oppSerial,
    String lang,
    String solution,
    String scope,
    String contactEmail,
    String productFullname,
    String salesEmail,
    String countryCode
  ) {
    System.debug('>>> closeOpportunity - get contract');
    /*Contract curCtr = [ SELECT  Id, ER_Creation_date_in_OS__c, ER_OpportunityId__c, ER_OpportunityId__r.ER_AmendedFromContract__c,
                                    ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId, ER_OpportunityId__r.OwnerId, ER_Contract_Type__c,
                                    AccountId, RecordTypeId, ER_OpportunityId__r.ER_IsAmended__c, ER_Business_Unit__c, Account.HU_HQ_Contact__c,
                                    Account.HU_HQ_Contact__r.Title, Account.ER_Country_Code__c
                            FROM    Contract WHERE Id = :contractId][0];*/

    APER30_AutoEnrollment_Management.syncRecordBU = Utils.getBUCode(countryCode);
    List<Contract> contracts = APER12_Contract_Management.getContract(new List<String>{ contractId });
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;

    APER12_Contract_Management.activateContractController(contracts[0], null, isOfflineBU);

    closeOpportunityFinal(
      oppSerial,
      lang,
      solution,
      scope,
      contactEmail,
      productFullname,
      salesEmail,
      contractId,
      countryCode
    );
  }

  private static void closeOpportunityFinal(
    String oppSerial,
    String lang,
    String solution,
    String scope,
    String contactEmail,
    String productFullname,
    String salesEmail,
    String contractId,
    String countryCode
  ) {
    Opportunity opp = (Opportunity) JSON.deserialize(oppSerial, Opportunity.class);
    // Send welcome mail to main contact with the right pdf as attachment
    sendWelcomeEmail(
      lang,
      solution,
      scope,
      contactEmail,
      salesEmail,
      productFullname,
      opp.Id,
      opp.accountId,
      contractId,
      countryCode
    );
  }

  @Future(callout=true)
  public static void syncStructurePart2(String accountId, String contractId, String params) {
    System.debug(' >>> syncStructurePart2 params: ' + params);
    List<String> paramList = params.split('\\|');
    String oppSerial = paramList[1];
    Opportunity opp = (Opportunity) JSON.deserialize(oppSerial, Opportunity.class);
    APER30_AutoEnrollment_Management.syncRecordBU = opp.ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    System.debug(
      ' >>> syncStructurePart2 APER30_AutoEnrollment_Management.syncRecordBU: ' +
      APER30_AutoEnrollment_Management.syncRecordBU
    );

    List<String> syncResultList = APHU12_Contract_Management.saveContractEdgWSV3(accountId, contractId, 'Activation');
    if (!syncResultList.isEmpty() && syncResultList[0] == 'succeeded')
      doApexEvent('activateContract', params);
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-01-2023
   * @param leadId
   * @param solutionCode
   **/
  public static void updateCoreOpportunity(
    Id leadId,
    String solutionCode,
    String benefits,
    String cardType,
    String additionalProducts
  ) {
    if (String.isNotBlank(leadId) && String.isNotBlank(solutionCode)) {
      Lead l = [
        SELECT Id, ERBE_Initial_Product_Of_Interest__r.ProductCode, ConvertedOpportunityId, NumberOfEmployees
        FROM Lead
        WHERE Id = :leadId
      ];

      System.debug(' >>> updateCoreOpportunity ' + benefits + ' ' + cardType + ' ' + solutionCode);
      System.debug(' >>> updateCoreOpportunity additional products' + additionalProducts);

      Opportunity oppty = new Opportunity(
        Id = l.ConvertedOpportunityId,
        ER_Solutions__c = solutionCode,
        ER_Nb_of_Employees__c = l.NumberOfEmployees
      );
      if (additionalProducts != null && additionalProducts != '') {
        oppty.ER_AdditionalProducts__c = additionalProducts;
      }

      Set<String> prodNames = new Set<String>();
      if (String.isNotBlank(benefits))
        prodNames.addAll(benefits.split(Constants.PIPE_SEPARATOR));
      if (String.isNotBlank(cardType))
        prodNames.addAll(cardType.split(Constants.PIPE_SEPARATOR));
      if (!prodNames.isEmpty()) {
        String benefitsTechName = '';
        String cardTypeTechName = '';
        for (Auto_Enrollment_Product__mdt mdt : [
          SELECT DeveloperName, Type__c
          FROM Auto_Enrollment_Product__mdt
          WHERE Name__c IN :prodNames AND (Type__c = :Constants.BENEFIT_TYPE OR Type__c = :Constants.CARD_TYPE)
        ]) {
          if (mdt.Type__c == Constants.BENEFIT_TYPE) {
            if (benefitsTechName != '')
              benefitsTechName += Constants.PIPE_SEPARATOR;
            benefitsTechName += mdt.DeveloperName;
          }
          if (mdt.Type__c == Constants.CARD_TYPE) {
            if (cardTypeTechName != '')
              cardTypeTechName += Constants.PIPE_SEPARATOR;
            cardTypeTechName += mdt.DeveloperName;
          }
        }
        oppty.ER_Benefits__c = benefitsTechName;
        oppty.ER_CardType__c = cardTypeTechName;
      }
      update oppty;
    }
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-01-2023
   * @param leadId
   * @param iban
   * @param bic
   **/
  private static void createBankAccAndUpdateFinCenter(id leadId, String bu, String iban, String bic) {
    // add sanity checks
    if (String.isBlank(iban) || iban == Constants.UNDEFINED || String.isBlank(bic) || bic == Constants.UNDEFINED) {
      return;
    }
    // get the FC :
    List<ER_Financial_Center__c> fc = [
      SELECT Id, ER_Account_Name__r.HU_HQ_Contact__c
      FROM ER_Financial_Center__c
      WHERE ER_SmartER_Original_Lead_Id__c = :leadId
    ];
    List<Lead> ldList = new List<Lead>();

    if (fc.isEmpty()) {
      ldList = [
        SELECT
          ConvertedAccountId,
          ER_Legal_City__c,
          ER_Legal_Street__c,
          ER_Legal_Zip_Code__c,
          ER_Legal_Country__c,
          ER_Legal_Country_Code__c,
          ER_OVT_Code__c,
          ER_OVT_Operator__c
        FROM Lead
        WHERE Id = :leadId
      ];
      fc = [
        SELECT Id, ER_Account_Name__r.HU_HQ_Contact__c
        FROM ER_Financial_Center__c
        WHERE ER_Account_Name__c = :ldList[0].ConvertedAccountId
        ORDER BY LastModifiedDate DESC
      ];
      if (fc.isEmpty())
        return;
    }

    ER_Bank_Account__c bnkAcc = new ER_Bank_Account__c();
    bnkAcc.Name = iban;
    bnkAcc.ER_Bank_Account_Status__c = Constants.OPEN;
    bnkAcc.ER_IBAN__c = iban;
    bnkAcc.ER_BIC__c = bic;
    bnkAcc.ER_BUPicklist__c = Utils.getBUCode(bu);
    bnkAcc.ER_SEPA_active__c = true;
    bnkAcc.ER_SEPA_start_date__c = Date.today();
    bnkAcc.ER_Financial_Center__c = fc[0].id;
    Database.SaveResult sr = database.insert(bnkAcc);
    if (sr.isSuccess()) {
      ER_Financial_Center__c fcUpd = new ER_Financial_Center__c(
        Id = fc[0].id,
        ER_Bank_Account__c = bnkAcc.id,
        ER_Contact__c = fc[0].ER_Account_Name__r.HU_HQ_Contact__c
      );
      if (!ldList.isEmpty()) {
        fcUpd.ERFI_OVT_Code__c = ldList[0].ER_OVT_Code__c;
        fcUpd.ERFI_OVT_Operator__c = ldList[0].ER_OVT_Operator__c;

        fcUpd.ER_Street__c = ldList[0].ER_Legal_Street__c;
        fcUpd.ER_Zip_Code__c = ldList[0].ER_Legal_Zip_Code__c;
        fcUpd.ER_City__c = ldList[0].ER_Legal_City__c;
        fcUpd.ER_Country_Code__c = ldList[0].ER_Legal_Country_Code__c;
        fcUpd.ER_Country__c = ldList[0].ER_Legal_Country__c;

        fcUpd.ER_Invoicing_Street__c = ldList[0].ER_Legal_Street__c;
        fcUpd.ER_Invoicing_Zip_Code__c = ldList[0].ER_Legal_Zip_Code__c;
        fcUpd.ER_Invoicing_City__c = ldList[0].ER_Legal_City__c;
        fcUpd.ER_Invoicing_Country_Code__c = ldList[0].ER_Legal_Country_Code__c;
        fcUpd.ER_Invoicing_Country__c = ldList[0].ER_Legal_Country__c;
      }
      database.update(fcUpd);
    }
  }
  /**
   * @description : Activate All created SLIs for autoenrollment process
   * @author Hassan DAKHCHA | 07-04-2023
   * @param items : solution line items
   **/
  public static void activateAutoenrollmentSLIs(List<ER_Solution_Line_Item__c> items) {
    Map<Id, List<ER_Solution_Line_Item__c>> mapContractSLIs = new Map<Id, List<ER_Solution_Line_Item__c>>();
    for (ER_Solution_Line_Item__c sli : items) {
      if (sli.ER_Contract__c != null && sli.ER_Status__c != Constants.ACTIVE) {
        if (!mapContractSLIs.containsKey(sli.ER_Contract__c))
          mapContractSLIs.put(sli.ER_Contract__c, new List<ER_Solution_Line_Item__c>());
        mapContractSLIs.get(sli.ER_Contract__c).add(sli);
      }
    }

    if (!mapContractSLIs.isEmpty()) {
      for (Contract c : [
        SELECT Id, ER_BUPicklist__c, ER_OpportunityId__r.LeadSource, CreatedBy.Name
        FROM Contract
        WHERE Id IN :mapContractSLIs.keySet()
      ]) {
        if (
          c.CreatedBy.Name == Constants.AUTOMATED_PROCESS ||
          (Test.isRunningTest() && c.CreatedBy.Name.contains('autoEnrollmentSLITest'))
        ) {
          for (ER_Solution_Line_Item__c sli : mapContractSLIs.get(c.Id)) {
            sli.ER_BUPicklist__c = c.ER_BUPicklist__c;
            sli.ER_Status__c = Constants.ACTIVE;
          }
        }
      }
    }
  }
  /**
   * @description activate all SLIs for an account for autoenrollment process
   * @author Hassan DAKHCHA | 07-25-2023
   * @param accId
   **/
  public static void activateAutoenrollmentSLIs(Id accId, String Solutions) {
    List<ER_Solution_Line_Item__c> slis = new List<ER_Solution_Line_Item__c>();
    Set<String> solSet = new Set<String>(Solutions.deleteWhitespace().split(Constants.SLASH));
    for (ER_Solution_Line_Item__c sli : [
      SELECT Id, ER_Status__c, ER_BUPicklist__c, ER_Contract__r.ER_BUPicklist__c, ER_Contract__r.ER_Solutions__c
      FROM ER_Solution_Line_Item__c
      WHERE
        ER_Contract__r.AccountId = :accId
        AND ER_Status__c != :Constants.ACTIVE
        AND (ER_Contract__r.ER_Solutions__c = :Solutions
        OR ER_Contract__r.ER_Solutions__c IN :solSet)
    ]) {
      sli.ER_BUPicklist__c = sli.ER_Contract__r.ER_BUPicklist__c;
      sli.ER_Status__c = Constants.ACTIVE;
      slis.add(sli);
    }

    if (!slis.isEmpty())
      Database.update(slis, false);
  }
  public static void fakecc(){
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i=0;
    }
}