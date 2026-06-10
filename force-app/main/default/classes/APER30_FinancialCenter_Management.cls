/*
----------------------------------------------------------------------
-- - Name          : APER30_FinancialCenter_Management
-- - Author        : KHAD
-- - Description   : Financial Center Management, This class is used to group all the functionnality linked to the object Financial Center      
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- FEB-2021     KHAD                 1.0         Initial version
-- JUNE-2021    NOOR                 1.1         Add duplicate rule when creating or updating financial center
---------------------------------------------------------------------------------------
*/
public without sharing class APER30_FinancialCenter_Management {
  public static Boolean Bypass_FI_VR_OPT = true;
  public static Boolean Bypass_Store_Creation = false;
  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageFCLIForFinancialCenter(Contract contract) {
    if (UtilsBypass.canTrigger('manageFCLIForFinancialCenter')) {
      GenericWithoutSharing.manageFCLIForFinancialCenter(contract);
    }
  }

  public static Map<Id, ER_Solution_Line_Item__c> getAllFCLineItems(Set<String> companyIds) {
    return new Map<Id, ER_Solution_Line_Item__c>(
      [
        SELECT Id, Name, ER_Financial_Center__c, ER_Solution__c, ER_Contract__c, ER_Status__c
        FROM ER_Solution_Line_Item__c
        WHERE
          RecordType.DeveloperName = 'ER_Financial_Center_Line_Item'
          AND ER_Financial_Center__r.ER_Account_Name__c IN :companyIds
      ]
    );
  }

  //Method added by harkirat to create ACR
  public static void createAcrForFinancialCenters(
    Map<Id, sObject> newItems,
    Map<Id, sObject> oldItems
) {
      Map<Id, ER_Financial_Center__c> newFcMap = (Map<Id, ER_Financial_Center__c>) newItems;
      Map<Id, ER_Financial_Center__c> oldFcMap = (Map<Id, ER_Financial_Center__c>) oldItems;
    if (newFcMap == null || newFcMap.isEmpty()) {
        return;
    }

    List<ER_Financial_Center__c> fcToProcess = new List<ER_Financial_Center__c>();
    Set<Id> contactIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();

    // 1) Collect FCs where ER_Contact__c actually changed
    for (ER_Financial_Center__c fcNew : newFcMap.values()) {
        ER_Financial_Center__c fcOld =
            (oldFcMap != null ? oldFcMap.get(fcNew.Id) : null);

        Boolean contactChanged =
            (fcOld == null && fcNew.ER_Contact__c != null) ||
            (fcOld != null && fcNew.ER_Contact__c != fcOld.ER_Contact__c);

        if (!contactChanged) {
            continue;
        }

        if (fcNew.ER_Account_Name__c != null && fcNew.ER_Contact__c != null) {
            fcToProcess.add(fcNew);
            contactIds.add(fcNew.ER_Contact__c);
            accountIds.add(fcNew.ER_Account_Name__c);
        }
    }

    if (fcToProcess.isEmpty()) {
        return;
    }

    // 2) Find existing ACRs for these Account + Contact combos
    List<AccountContactRelation> existingAcrs = [
        SELECT Id, AccountId, ContactId
        FROM AccountContactRelation
        WHERE AccountId IN :accountIds
          AND ContactId IN :contactIds
    ];

    Set<String> existingPairs = new Set<String>();
    for (AccountContactRelation acr : existingAcrs) {
        existingPairs.add(String.valueOf(acr.AccountId) + '-' + String.valueOf(acr.ContactId));
    }

    // 3) Create missing ACRs
    List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();

    for (ER_Financial_Center__c fc : fcToProcess) {
        String key = String.valueOf(fc.ER_Account_Name__c) + '-' + String.valueOf(fc.ER_Contact__c);
        if (!existingPairs.contains(key)) {
            acrsToInsert.add(new AccountContactRelation(
                AccountId = fc.ER_Account_Name__c,
                ContactId = fc.ER_Contact__c
            ));
        }
    }

    if (!acrsToInsert.isEmpty()) {
        insert acrsToInsert;
    }
}
  public static void manageFCLIForNewFinancialCenter(Map<Id, ER_Financial_Center__c> financialCenterMap) {
    if (UtilsBypass.canTrigger('manageFCLIForNewFinancialCenter')) {
      try {
        List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();
        for (ER_Financial_Center__c fc : financialCenterMap.values()) {
          if (!fc.ER_SmartER_Context__c)
            financialCenters.add(fc);
        }

        if (!financialCenters.isEmpty()) {
          System.debug('manageAccLIForNewAcceptor START');
          ER_Solution_Line_Item__c fcli;
          List<ER_Financial_Center__c> insertedFinancialCenters = [
            SELECT Id, Name, ER_Account_Name__c, ER_Type__c, ER_BUPicklist__c
            FROM ER_Financial_Center__c
            WHERE Id IN :financialCenters
          ];
          Set<ER_Solution_Line_Item__c> allActiveAccountLineItem = new Set<ER_Solution_Line_Item__c>();
          Map<String, Set<ER_Solution_Line_Item__c>> mapAccountActiveAccountLineItems = new Map<String, Set<ER_Solution_Line_Item__c>>();
          List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();
          Set<String> companySet = new Set<String>();

          for (ER_Financial_Center__c fcenter : insertedFinancialCenters) {
            companySet.add(fcenter.ER_Account_Name__c);
          }

          Map<Id, ER_Solution_Line_Item__c> allaccliList = APER20_Account_Management.getAllAccountLineItems(companySet);

          for (ER_Solution_Line_Item__c accli : allaccliList.values()) {
            allActiveAccountLineItem = new Set<ER_Solution_Line_Item__c>();

            if (!mapAccountActiveAccountLineItems.containsKey(accli.ER_Account__c)) {
              allActiveAccountLineItem.add(accli);
              mapAccountActiveAccountLineItems.put(accli.ER_Account__c, allActiveAccountLineItem);
            } else {
              allActiveAccountLineItem = mapAccountActiveAccountLineItems.get(accli.ER_Account__c);
              allActiveAccountLineItem.add(accli);
              mapAccountActiveAccountLineItems.put(accli.ER_Account__c, allActiveAccountLineItem);
            }
          }

          if (!mapAccountActiveAccountLineItems.isEmpty()) {
            for (ER_Financial_Center__c fcenter : insertedFinancialCenters) {
              for (
                ER_Solution_Line_Item__c AccountLineItem : mapAccountActiveAccountLineItems.get(
                  fcenter.ER_Account_Name__c
                )
              ) {
                if (fcenter.ER_Type__c == AccountLineItem.ER_Scope__c) {
                  fcli = new ER_Solution_Line_Item__c();
                  fcli.ER_Solution__c = AccountLineItem.ER_Solution__c;
                  fcli.ER_Contract__c = AccountLineItem.ER_Contract__c;
                  fcli.ER_Financial_Center__c = fcenter.Id;
                  fcli.ER_Status__c = 'Undefined';
                  fcli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
                    .get('ER_Financial_Center_Line_Item')
                    .getRecordTypeId();
                  fcli.ER_Parent_Line_Item__c = AccountLineItem.Id;
                  fcli.ER_BUPicklist__c = fcenter.ER_BUPicklist__c; // AAM 19.01.2022 - PBI#14217
                  fcliListToInsert.add(fcli);
                }
              }
            }

            if (!fcliListToInsert.isEmpty()) {
              System.debug('sliList to insert : ' + fcliListToInsert);
              insert fcliListToInsert;
            }
          }

          System.debug('manageAccLIForNewAcceptor END');
        }
      } catch (Exception e) {
        Trigger.new[0].addError(e.getMessage());
      }
    }
  }

  /**
   * @author VJB
   * @date 06/05/2021
   * @description PBI 10658 ERES - Group type management (Financial center)
   * @param aFinancialCentersList
   */
  public static void manageFinancialCenterInvoicingCenter(List<ER_Financial_Center__c> aFinancialCentersList) {
    System.debug('manageFinancialCenterInvoicingCenter');
    if (UtilsBypass.canTrigger('manageFinancialCenterInvoicingCenter')) {
      Map<Id, List<ER_Financial_Center__c>> mapAccountFC = new Map<Id, List<ER_Financial_Center__c>>();
      Map<Id, List<ER_Financial_Center__c>> mapInputAccountFC = new Map<Id, List<ER_Financial_Center__c>>();
      List<ER_Financial_Center__c> fcList = new List<ER_Financial_Center__c>();
      List<Id> fcIds = new List<Id>();

      for (ER_Financial_Center__c fc : aFinancialCentersList) {
        if (!fc.ER_SmartER_Context__c) {
          if (fc.ER_Type__c == 'Client')
            continue;
          if (!mapAccountFC.containsKey(fc.ER_Account_Name__c))
            mapAccountFC.put(fc.ER_Account_Name__c, new List<ER_Financial_Center__c>());
          mapAccountFC.get(fc.ER_Account_Name__c).add(fc);
          if (fc.Id != null && !fcIds.contains(fc.Id))
            fcIds.add(fc.Id);
          fcList.add(fc);
          if (!mapInputAccountFC.containsKey(fc.ER_Account_Name__c))
            mapInputAccountFC.put(fc.ER_Account_Name__c, new List<ER_Financial_Center__c>());
          mapInputAccountFC.get(fc.ER_Account_Name__c).add(fc);
        }
      }

      if (!fcList.isEmpty()) {
        for (ER_Financial_Center__c fc : [
          SELECT Id, ER_Account_Name__c, ER_Invoicing_Site__c, ER_Payment_Site__c, ER_Business_Unit__c, ER_Type__c
          FROM ER_Financial_Center__c
          WHERE ER_Account_Name__c IN :mapAccountFC.keySet() AND ER_Business_Unit__c = 'ES' AND ER_Type__c = 'Merchant'
        ]) {
          if (!fcIds.contains(fc.Id)) {
            fcIds.add(fc.Id);
            mapAccountFC.get(fc.ER_Account_Name__c).add(fc);
            fcList.add(fc);
          }
        }

        System.debug('aFinancialCentersList ' + fcList);
        for (ER_Financial_Center__c fc : fcList) {
          //Rule 1 - Invoicing FC can't have Sibling
          if (
            !UtilsBypass.getCurrentUser().ER_BypassVR__c &&
            fc.ER_Business_Unit__c == 'ES' &&
            fc.ER_Invoicing_Site__c &&
            mapAccountFC.get(fc.ER_Account_Name__c).size() > 1 &&
            mapInputAccountFC.containsKey(fc.ER_Account_Name__c)
          ) {
            for (ER_Financial_Center__c financialCenter : mapInputAccountFC.get(fc.ER_Account_Name__c)) {
              financialCenter.addError(Label.LAB_SF_FC_InvoicingSiteError);
            }
          }
        }
      }
    }
  }

  /**
   * @author VJB
   * @date 01/06/2021
   * @description PBI 10658 ERES - Group type management (Financial center)
   * @param Map<Id, SObject> newItems, Map<Id, SObject> oldItems
   */
  public static void manageFinancialCenterStores(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    if (UtilsBypass.canTrigger('manageFinancialCenterStores')) {
      Map<Id, ER_Financial_Center__c> newFcMap = (Map<Id, ER_Financial_Center__c>) newItems;
      Map<Id, ER_Financial_Center__c> oldFcMap = (Map<Id, ER_Financial_Center__c>) oldItems;
      Map<Id, List<ER_Store__c>> listStoresByFcMap = new Map<Id, List<ER_Store__c>>();
      List<ER_Store__c> storeList = new List<ER_Store__c>();

      Set<Id> fcIdSet = new Set<Id>();
      Set<ER_Financial_Center__c> fcSet = new Set<ER_Financial_Center__c>();
      List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();

      for (ER_Financial_Center__c fc : newFcMap.values()) {
        if (!fc.ER_SmartER_Context__c && fc.ER_BUPicklist__c == Constants.ES)
          financialCenters.add(fc);
      }

      if (!financialCenters.isEmpty()) {
        // Loop through the FC lists
        for (ER_Financial_Center__c fc : financialCenters) {
          if (fc.ER_Payment_Site__c != oldFcMap.get(fc.Id).ER_Payment_Site__c && fc.ER_Payment_Site__c) {
            fcIdSet.add(fc.Id);
            fcSet.add(fc);
          }
        }

        if (!fcIdSet.isEmpty()) {
          for (ER_Store__c store : [
            SELECT
              Id,
              ER_Financial_Center__c,
              ER_Invoicing_site__c,
              ER_Payment_site__c,
              ER_Financial_Center__r.ER_Payment_Site__c,
              ER_Business_Unit__c
            FROM ER_Store__c
            WHERE ER_Financial_Center__c IN :fcIdSet
          ]) {
            storeList.add(store);
            if (!listStoresByFcMap.containsKey(store.ER_Financial_Center__c))
              listStoresByFcMap.put(store.ER_Financial_Center__c, new List<ER_Store__c>());
            listStoresByFcMap.get(store.ER_Financial_Center__c).add(store);
          }

          for (ER_Financial_Center__c fc : fcSet) {
            if (
              !UtilsBypass.getCurrentUser().ER_BypassVR__c &&
              fc.ER_Business_Unit__c == Constants.ES &&
              fc.ER_Type__c == Constants.MERCHANT &&
              listStoresByFcMap.get(fc.Id).size() > 1
            )
              fc.addError(Label.LAB_SF_Store_PaymentSiteError);
          }
        }
      }
    }
  }

  /**
   * @author AAZ
   * @date 26/04/2021
   * @description Create a Billing Account (Asynchronously) each time we create/update  a Financial Center for BUs having Zuora live or in deployment
   * @param newFinancialCenters
   */
  public static void createZuoraBillingAccount(List<ER_Financial_Center__c> newFinancialCenters) {
    Map<String, List<ER_Financial_Center__c>> mapFinancialCentersByBU = new Map<String, List<ER_Financial_Center__c>>();
    List<String> deployedZuoraBUs = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU)
      ?.split(Constants.SEMICOLON);
    Map<Id, ER_Financial_Center__c> financialCentersMap = new Map<Id, ER_Financial_Center__c>(newFinancialCenters);
    Integer zuoraLockTimeInt = 0;
    List<String> zuoraDeployedBU = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU)
      ?.split(Constants.SEMICOLON);
    List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();

    for (ER_Financial_Center__c fc : newFinancialCenters) {
      if (
        String.isNotBlank(fc.ER_BUPicklist__c) &&
        zuoraDeployedBU != null &&
        zuoraDeployedBU.contains(fc.ER_BUPicklist__c)
      )
        financialCenters.add(fc);
    }

    if (!financialCenters.isEmpty()) {
      //Get FC should be pushed to Zuora (in order to create Billing Accounts) and group them per BU
      for (ER_Financial_Center__c fc : [
        SELECT
          Id,
          Name,
          ER_Type__c,
          ER_BUPicklist__c,
          ER_Business_Unit__c,
          ER_Account_Name__c,
          ER_Contact__c,
          ER_Contact__r.FirstName,
          ER_Contact__r.LastName,
          ER_Contact__r.Email,
          ER_Email__c,
          ER_Secondary_Email__c,
          ER_Contact__r.Fax,
          ER_Contact__r.Phone,
          CurrencyIsoCode,
          Owner.Name,
          ER_Account_Name__r.ER_Legal_Name__c,
          ER_Account_Name__r.ER_VAT_Number__c,
          ER_Account_Name__r.Name,
          ER_SmartER_Context__c,
          ER_Bank_Account__r.ER_IBAN__c,
          ER_Card_Operational_System_ID__c,
          LastModifiedDate,
          ER_Zuora_Lock_Time__c,
          ER_Account_Name__r.ER_Not_subject_to_VAT__c,
          ER_Last_Lock_Date__c,
          ER_Invoicing_Street__c,
          ER_Invoicing_Zip_Code__c,
          ER_Invoicing_City__c,
          ER_Invoicing_Region_State__c,
          ER_Invoicing_Country__c,
          ER_Invoicing_Country_Code__c,
          ER_Account_Name__r.ER_Customer_Number__c,
          ER_Account_Name__r.BillingStreet,
          ER_Account_Name__r.BillingCity,
          ER_Account_Name__r.BillingPostalCode,
          ER_Account_Name__r.BillingState,
          ER_Account_Name__r.BillingCountry,
          ER_Account_Name__r.ER_Country_Code__c,
          ER_Account_Name__r.ER_Registration_Number__c,
          (SELECT Id FROM Billing_Accounts__r)
        FROM ER_Financial_Center__c
        WHERE Id IN :financialCentersMap.keySet() AND ER_Contact__c != NULL AND ER_Contact__r.Email != NULL
      ]) {
        if (fc.ER_Zuora_Lock_Time__c != null)
          zuoraLockTimeInt = Integer.valueOf(fc.ER_Zuora_Lock_Time__c);

        if (
          deployedZuoraBUs != null &&
          String.isNotBlank(fc.ER_BUPicklist__c) &&
          deployedZuoraBUs.contains(fc.ER_BUPicklist__c) &&
          fc.Billing_Accounts__r.isEmpty() &&
          (fc.ER_Zuora_Lock_Time__c == null ||
          (fc.ER_Last_Lock_Date__c != null &&
          fc.ER_Last_Lock_Date__c.addMinutes(zuoraLockTimeInt) <= Datetime.now()))
        ) {
          System.debug('##### AA createZuoraBillingAccount zuoraLockTimeInt:' + zuoraLockTimeInt);

          if (!mapFinancialCentersByBU.containsKey(fc.ER_BUPicklist__c))
            mapFinancialCentersByBU.put(fc.ER_BUPicklist__c, new List<ER_Financial_Center__c>());
          mapFinancialCentersByBU.get(fc.ER_BUPicklist__c).add(fc);
        }
      }

      System.debug('>>>>> AAZ - mapFinancialCentersByBU : ' + mapFinancialCentersByBU);
      if (!mapFinancialCentersByBU.isEmpty())
        System.enqueueJob(new ER_CreateZuoraBillingAccount(mapFinancialCentersByBU, null));
    }
  }

  /**
   * @author AAZ
   * @date 26/04/2021
   * @description create Zuora Customer Account
   * @param mapFinancialCentersByBU
   * @param token
   */
  public static void createZuoraCustomerAccount(
    Map<String, List<ER_Financial_Center__c>> mapFinancialCentersByBU,
    String token
  ) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    String endpoint = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENDPOINT);
    String zuoraLockTimeSetting = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_LOCK_TIME);
    Integer zuoraLockTimeSettingInt = (String.isNotBlank(zuoraLockTimeSetting)
      ? Integer.valueOf(zuoraLockTimeSetting)
      : 60);
    List<ER_Financial_Center__c> listFCtoUpdate = new List<ER_Financial_Center__c>();
    List<String> additionalEmailAddresses = new List<String>();

    try {
      for (String bu : mapFinancialCentersByBU.keySet()) {
        //Get EntityId
        String entityId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_ENTITYID + bu);
        if (entityId != null)
          req.setHeader('entityId', entityId);

        System.debug('>>>>> AAZ - bu : ' + bu);
        System.debug('>>>>> AAZ - entityId : ' + entityId);

        //Populate the Billing Account
        for (ER_Financial_Center__c fc : mapFinancialCentersByBU.get(bu)) {
          Map<String, Object> billingAccount = new Map<String, Object>();
          String scope = (fc.ER_Type__c == Constants.MERCHANT
            ? Constants.MERCHANT_UNDERSCORE
            : Constants.CLIENT_UNDERSCORE);
          //Get SequenceSet value according to the FC type, as well as other Zuora templates IDs
          String communicationProfileId = Utils.getGlobalSettingsValueFromKey(
            Constants.ZUORA_COMMUNICATIONPROFILE_ID + fc.ER_Business_Unit__c
          );
          String sequenceSetId = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_SEQUENCESET + scope + bu);
          String invoiceTemplateId = Utils.getGlobalSettingsValueFromKey(
            Constants.ZUORA_INVOICETEMPLATE_ID +
            scope +
            fc.ER_Business_Unit__c
          );
          String creditMemoTemplateId = Utils.getGlobalSettingsValueFromKey(
            Constants.ZUORA_CREDITMEMOTEMPLATE_ID +
            scope +
            fc.ER_Business_Unit__c
          );
          String debitMemoTemplateId = Utils.getGlobalSettingsValueFromKey(
            Constants.ZUORA_DEBITMEMOTEMPLATE_ID +
            scope +
            fc.ER_Business_Unit__c
          );
          //Get default payment term
          String defaultPaymentTerm = Utils.getGlobalSettingsValueFromKey(
            Constants.ZUORA_DEFAULT_PAYMENTTERM +
            scope +
            fc.ER_Business_Unit__c
          );
          System.debug(
            '######## AAZ - ZUORA_DEFAULT_PAYMENTTERM : ' +
            (Constants.ZUORA_DEFAULT_PAYMENTTERM +
            scope +
            fc.ER_Business_Unit__c)
          );
          System.debug('######## AAZ - defaultPaymentTerm : ' + defaultPaymentTerm);

          if (String.isNotBlank(fc.ER_Email__c))
            additionalEmailAddresses.add((String.isNotBlank(fc.ER_Email__c) ? fc.ER_Email__c : ''));
          if (String.isNotBlank(fc.ER_Secondary_Email__c))
            additionalEmailAddresses.add(String.isNotBlank(fc.ER_Secondary_Email__c) ? fc.ER_Secondary_Email__c : '');

          //Populate needed fields
          billingAccount.put('crmId', fc.ER_Account_Name__c);
          billingAccount.put('currency', fc.CurrencyIsoCode);
          billingAccount.put('invoiceDeliveryPrefsEmail', true);
          billingAccount.put('invoiceDeliveryPrefsPrint', false);
          billingAccount.put('name', fc.Name);
          billingAccount.put('billCycleDay', 1);
          billingAccount.put('autoPay', false);
          billingAccount.put('paymentTerm', defaultPaymentTerm);
          billingAccount.put('sequenceSetId', sequenceSetId);
          billingAccount.put('salesRep', fc.Owner.Name);
          billingAccount.put('ER_Customer_Number__c', fc.ER_Account_Name__r.ER_Customer_Number__c);
          billingAccount.put('ER_Registration_Number__c', fc.ER_Account_Name__r.ER_Registration_Number__c);

          if (String.isNotBlank(communicationProfileId))
            billingAccount.put('communicationProfileId', communicationProfileId);
          if (String.isNotBlank(invoiceTemplateId))
            billingAccount.put('invoiceTemplateId', invoiceTemplateId);
          if (String.isNotBlank(creditMemoTemplateId))
            billingAccount.put('creditMemoTemplateId', creditMemoTemplateId);
          if (String.isNotBlank(debitMemoTemplateId))
            billingAccount.put('debitMemoTemplateId', debitMemoTemplateId);

          billingAccount.put(
            'SEQUENCE_SET__c',
            (fc.ER_Type__c == Constants.FC_MERCHANT_TYPE ? Constants.SEQUENCE_AFFILIATE : Constants.SEQUENCE_CUSTOMER)
          );
          billingAccount.put(
            'LEGAL_NAME__c',
            (String.isNotBlank(fc.ER_Account_Name__r.ER_Legal_Name__c)
              ? fc.ER_Account_Name__r.ER_Legal_Name__c
              : fc.ER_Account_Name__r.Name)
          );
          billingAccount.put('IBAN__c', fc.ER_Bank_Account__r.ER_IBAN__c);
          billingAccount.put('TECH_Financial_Center__c', fc.Id);
          if (!additionalEmailAddresses.isEmpty())
            billingAccount.put('additionalEmailAddresses', additionalEmailAddresses);

          if (fc.ER_SmartER_Context__c) {
            billingAccount.put(
              'ER_BillingStreet__c',
              String.isNotBlank(fc.ER_Account_Name__r.BillingStreet) ? fc.ER_Account_Name__r.BillingStreet : ''
            );
            billingAccount.put(
              'ER_BillingCity__c',
              String.isNotBlank(fc.ER_Account_Name__r.BillingCity) ? fc.ER_Account_Name__r.BillingCity : ''
            );
            billingAccount.put(
              'ER_BillingPostalCode__c',
              String.isNotBlank(fc.ER_Account_Name__r.BillingPostalCode) ? fc.ER_Account_Name__r.BillingPostalCode : ''
            );
            billingAccount.put(
              'ER_BillingState__c',
              String.isNotBlank(fc.ER_Account_Name__r.BillingState) ? fc.ER_Account_Name__r.BillingState : ''
            );
            billingAccount.put(
              'ER_BillingCountry__c',
              String.isNotBlank(fc.ER_Account_Name__r.BillingCountry) ? fc.ER_Account_Name__r.BillingCountry : ''
            );
            billingAccount.put(
              'ER_Country_Code__c',
              String.isNotBlank(fc.ER_Account_Name__r.ER_Country_Code__c)
                ? fc.ER_Account_Name__r.ER_Country_Code__c
                : ''
            );
          }

          //Populate the BillToContact
          Map<String, Object> billingToContact = new Map<String, Object>();
          billingToContact.put('CRM_CONTACT_ID__c', fc.ER_Contact__c);
          billingToContact.put('firstName', fc.ER_Contact__r.FirstName);
          billingToContact.put('lastName', fc.ER_Contact__r.LastName);
          billingToContact.put('workEmail', String.isNotBlank(fc.ER_Contact__r.Email) ? fc.ER_Contact__r.Email : '');
          billingToContact.put('address1', fc.ER_Invoicing_Street__c);
          billingToContact.put('city', fc.ER_Invoicing_City__c);
          billingToContact.put('state', fc.ER_Invoicing_Region_State__c);
          billingToContact.put('zipCode', fc.ER_Invoicing_Zip_Code__c);
          billingToContact.put('country', fc.ER_Invoicing_Country_Code__c);
          billingToContact.put('COUNTRY_NAME__c', fc.ER_Invoicing_Country__c);
          billingToContact.put('fax', String.isNotBlank(fc.ER_Contact__r.Fax) ? fc.ER_Contact__r.Fax : '');
          billingToContact.put('workPhone', fc.ER_Contact__r.Phone);

          billingAccount.put('billToContact', billingToContact);
          billingAccount.put('soldToSameAsBillTo', true);

          //Populate the Tax Info
          Map<String, Object> taxInfo = new Map<String, Object>();
          taxInfo.put('exemptStatus', (fc.ER_Account_Name__r.ER_Not_subject_to_VAT__c ? Constants.YES : Constants.NO));
          taxInfo.put(
            'exemptEntityUseCode',
            (fc.ER_Account_Name__r.ER_Not_subject_to_VAT__c ? Constants.ZUORA_EXEMPT_NOVAT : '')
          );
          taxInfo.put('VATId', fc.ER_Account_Name__r.ER_VAT_Number__c);
          billingAccount.put('taxInfo', taxInfo);

          //Get default payment method
          //String defaultPaymentMethod = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_PAYMENTMETHOD_OTHER + fc.ER_Business_Unit__c);
          //billingAccount.put('DefaultPaymentMethodId', defaultPaymentMethod);
          //

          if (Limits.getCallouts() < Limits.getLimitCallouts() && entityId != null) {
            req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACCOUNT);
            req.setMethod(Constants.POST_METHOD);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'bearer ' + token);

            String payload = JSON.serialize(billingAccount);
            System.debug('>>>>> AAZ - payload : ' + payload);
            req.setBody(payload);
            Zuora.zApi zApiInstance = new Zuora.zApi();

            if (!Test.isRunningTest())
              resp = zApiInstance.sendRequest(req);
            else
              resp = SendToZuoraMock.respond(req);

            if (resp.getStatusCode() == 200) {
              Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
              System.debug('>>>>> AAZ - mapRespData : ' + mapRespData);
              updateBillingAccountOnceCreated(mapRespData, fc, token, entityId, endpoint);
            }
          }

          if (fc.ER_Zuora_Lock_Time__c == null)
            listFCtoUpdate.add(
              new ER_Financial_Center__c(
                Id = fc.Id,
                ER_Zuora_Lock_Time__c = zuoraLockTimeSettingInt,
                ER_Last_Lock_Date__c = Datetime.now()
              )
            );
        }
      }

      if (!listFCtoUpdate.isEmpty())
        update listFCtoUpdate;
      System.debug('##### AA createZuoraBillingAccount zuoraLockTimeInt listFCtoUpdate:' + listFCtoUpdate);
    } catch (CalloutException ce) {
      System.debug('>>>>> AAZ - createZuoraCustomerAccount CalloutException : ' + ce.getMessage());
    }
  }

  /**
   * @author AAZ
   * @date 15/06/2021
   * @description update Zuora Customer Account
   * @param mapAccount
   * @param fc
   * @param token
   * @param entityId
   * @param endpoint
   */
  public static void updateBillingAccountOnceCreated(
    Map<String, Object> mapAccount,
    ER_Financial_Center__c fc,
    String token,
    String entityId,
    String endpoint
  ) {
    String bAccountId = (String) mapAccount.get('accountId');
    if (String.isNotBlank(bAccountId)) {
      HttpRequest req = new HttpRequest();
      Http http = new Http();
      HttpResponse resp;

      //Get default payment method
      String scope = (fc.ER_Type__c == Constants.MERCHANT
        ? Constants.MERCHANT_UNDERSCORE
        : Constants.CLIENT_UNDERSCORE);
      System.debug('>>>>> AAZ - updateBillingAccountOnceCreated scope : ' + scope);
      String defaultPaymentMethod = Utils.getGlobalSettingsValueFromKey(
        Constants.ZUORA_DEFAULT_PAYMENTMETHOD +
        scope +
        fc.ER_Business_Unit__c
      );
      System.debug('>>>>> AAZ - updateBillingAccountOnceCreated defaultPaymentMethod : ' + defaultPaymentMethod);

      List<Map<String, Object>> accounts = new List<Map<String, Object>>();
      Map<String, Object> billingAccountToUpdate = new Map<String, Object>();
      Map<String, Object> action = new Map<String, Object>();

      billingAccountToUpdate.put('Id', bAccountId);
      billingAccountToUpdate.put('DefaultPaymentMethodId', defaultPaymentMethod);
      //billingAccountToUpdate.put('VATId', fc.ER_Account_Name__r.ER_VAT_Number__c);

      accounts.add(billingAccountToUpdate);
      action.put('objects', accounts);
      action.put('type', 'Account');

      if (Limits.getCallouts() < Limits.getLimitCallouts()) {
        req.setEndpoint(endpoint + Constants.ZUORA_ENDPOINT_ACTION_UPDATE);
        req.setMethod(Constants.POST_METHOD);
        req.setHeader('entityId', entityId);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'bearer ' + token);

        String payload = JSON.serialize(action);
        req.setBody(payload);
        Zuora.zApi zApiInstance = new Zuora.zApi();

        if (!Test.isRunningTest())
          resp = zApiInstance.sendRequest(req);
        else
          resp = SendToZuoraMock.respond(req);

        if (resp.getStatusCode() == 200) {
          string mapRespData = resp.getBody();
          System.debug('>>>>> AAZ - updateBillingAccount mapRespData : ' + mapRespData);
        }
      }
    }
  }

  /**
   * @author AAZ
   * @date 26/04/2021
   * @description flag the first FC as master
   * @param financialCenters
   */
  public static void setMaster(List<ER_Financial_Center__c> financialCenters) {
    Map<Id, ER_Financial_Center__c> mapFirstMerchantMaster = new Map<Id, ER_Financial_Center__c>();
    Map<Id, ER_Financial_Center__c> mapFirstClientMaster = new Map<Id, ER_Financial_Center__c>();
    Set<Id> accounts = new Set<Id>();

    //Check One Master in the bulk
    for (ER_Financial_Center__c fc : financialCenters) {
      if (fc.ER_Type__c == Constants.FC_MERCHANT_TYPE) {
        if (fc.ER_Master__c && !mapFirstMerchantMaster.containsKey(fc.ER_Account_Name__c))
          mapFirstMerchantMaster.put(fc.ER_Account_Name__c, fc);
        else
          fc.ER_Master__c = false;
      } else {
        if (fc.ER_Master__c && !mapFirstClientMaster.containsKey(fc.ER_Account_Name__c))
          mapFirstClientMaster.put(fc.ER_Account_Name__c, fc);
        else
          fc.ER_Master__c = false;
      }
    }
    //Add default master if no master found
    for (ER_Financial_Center__c fc : financialCenters) {
      accounts.add(fc.ER_Account_Name__c);
      if (fc.ER_Type__c == Constants.FC_MERCHANT_TYPE) {
        if (!mapFirstMerchantMaster.containsKey(fc.ER_Account_Name__c)) {
          fc.ER_Master__c = true;
          mapFirstMerchantMaster.put(fc.ER_Account_Name__c, fc);
        }
      } else {
        if (!mapFirstClientMaster.containsKey(fc.ER_Account_Name__c)) {
          fc.ER_Master__c = true;
          mapFirstClientMaster.put(fc.ER_Account_Name__c, fc);
        }
      }
    }

    //Check existing master in the database
    for (ER_Financial_Center__c fc : [
      SELECT Id, ER_Master__c, ER_Account_Name__c, ER_Type__c
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c IN :accounts AND ER_Master__c = TRUE
    ]) {
      if (fc.ER_Type__c == Constants.FC_MERCHANT_TYPE && mapFirstMerchantMaster.containsKey(fc.ER_Account_Name__c))
        mapFirstMerchantMaster.get(fc.ER_Account_Name__c).ER_Master__c = false;
      else if (fc.ER_Type__c == Constants.FC_CLIENT_TYPE && mapFirstClientMaster.containsKey(fc.ER_Account_Name__c))
        mapFirstClientMaster.get(fc.ER_Account_Name__c).ER_Master__c = false;
    }
  }

  /**
   * @author Noor
   * @date 20/04/2023
   * @description updates the Master Financial Center field on the related Account records when
   *              new master Financial Center records are inserted,
   * @param newItems new financial center created
   */
  public static void setMasterFC_OnAccount(Map<Id, ER_Financial_Center__c> newItems) {
    List<String> zuoraDeployedBU = Utils.splitValues(Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU));

    List<Account> accounts = new List<Account>();

    for (ER_Financial_Center__c fc : newItems.values()) {
      if (!zuoraDeployedBU.contains(fc.ER_Business_Unit__c) && fc.ER_Master__c && fc.ER_Account_Name__c != null) {
        if (fc.ER_Type__c == Constants.FC_MERCHANT_TYPE)
          accounts.add(new Account(Id = fc.ER_Account_Name__c, ER_Merchant_Master_FinancialCenter__c = fc.Id));
        if (fc.ER_Type__c == Constants.FC_CLIENT_TYPE)
          accounts.add(new Account(Id = fc.ER_Account_Name__c, ER_Client_Master_FinancialCenter__c = fc.Id));
      }
    }
    ManageFinancialCenterWOS.updateRelatedAccounts(accounts);
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Sync the new Financial Centers with EDG v3
   * @param financialCenters
   */
  public static void syncFinancialcenters(
    List<ER_Financial_Center__c> financialCenters,
    Map<Id, ER_Financial_Center__c> oldFinancialCenter
  ) {
    Set<Id> accounts = new Set<Id>();
    Set<Id> accountsRetrySync = new Set<Id>();
    Set<Id> modifiedElements = new Set<Id>();

    if (!financialCenters.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = financialCenters[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScopeFc = new Map<Id, String>();
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    System.debug('####APER30_ER_SyncStructureWS.alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync);

    if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
      for (ER_Financial_Center__c fc : financialCenters) {
        //if (fc.ER_Account_Name__c != null && fc.ER_Contact__c != null && fc.ER_Bank_Account__c != null && (fc.ER_Last_Synchronization_Date__c == oldFinancialCenter.get(fc.Id).ER_Last_Synchronization_Date__c)) {
        if (
          !fc.ER_SmartER_Context__c &&
          fc.ER_Account_Name__c != null &&
          fc.ER_Contact__c != null &&
          (fc.ER_Last_Synchronization_Date__c == oldFinancialCenter.get(fc.Id).ER_Last_Synchronization_Date__c)
        ) {
          modifiedElements.add(fc.Id);
          if (fc.ER_Creation_date_in_OS__c != null)
            accounts.add(fc.ER_Account_Name__c);
          else
            //retry sync for failed 1st try
            accountsRetrySync.add(fc.ER_Account_Name__c);
          accountsInputScopeFc.put(fc.ER_Account_Name__c, fc.ER_Type__c.toLowerCase());
          System.debug('######KHAD accountsRetrySync : ' + accountsRetrySync);
          System.debug('######KHAD fc to update accounts : ' + accounts);
        }
      }

      // add nested query to check if the scope of the financial center is already connected before pushing the financial center to be created
      if (!accountsRetrySync.isEmpty()) {
        for (Account a : [
          SELECT
            Id,
            ER_Status__c,
            (
              SELECT Id, ER_Creation_date_in_OS__c, ER_Scope__c
              FROM Solution_Line_Items__r
              WHERE ER_Creation_date_in_OS__c != NULL
            )
          FROM Account
          WHERE Id = :accountsRetrySync AND ER_Creation_date_in_OS__c != NULL
        ]) {
          for (ER_Solution_Line_Item__c accLiInst : a.Solution_Line_Items__r) {
            if (accLiInst.ER_Scope__c == accountsInputScopeFc.get(a.Id)) {
              accounts.add(a.Id);
              accountsInputScope.put(a.Id, accountsInputScopeFc.get(a.Id));
            }
          }
        }
      }

      if (!accounts.isEmpty())
        System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', modifiedElements, accountsInputScope));
    }
  }

  /**
   * @author KHAD
   * @date 08/06/2021
   * @description Update the creation date in ios field for financial center v3
   * @param newItems
   * @param oldItems
   */
  public static void syncFinancialCenterFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### syncFinancialCenterFlags Start');
    Map<Id, ER_Financial_Center__c> newFinancialCenterMap = (Map<Id, ER_Financial_Center__c>) newItems;
    Map<Id, ER_Financial_Center__c> oldFinancialCenterMap = (Map<Id, ER_Financial_Center__c>) oldItems;

    // Loop through the Account lists and add fill the creation date in OS
    for (ER_Financial_Center__c fc : newFinancialCenterMap.values()) {
      if (
        !fc.ER_SmartER_Context__c &&
        fc.ER_Sync_result__c != oldFinancialCenterMap.get(fc.Id).ER_Sync_result__c &&
        (fc.ER_Sync_result__c == 'synchronized' ||
        fc.ER_Sync_result__c == 'pending_synchronization') &&
        fc.ER_Creation_date_in_OS__c == null
      )
        fc.ER_Creation_date_in_OS__c = Datetime.now();
    }
    System.debug('### syncFinancialCenterFlags End');
  }

  /**
   * @author AAZ
   * @date 25/06/2021
   * @description update Zuora Customer Account after an update in SF
   * @param newFinancialCenters
   * @param oldFinancialCenters
   */
  public static void updateZuoraBillingAccount(
    List<ER_Financial_Center__c> newFinancialCenters,
    Map<Id, ER_Financial_Center__c> oldFinancialCenters
  ) {
    List<String> changedFields = new List<String>();
    List<ER_Financial_Center__c> listFcToSync = new List<ER_Financial_Center__c>();
    List<String> zuoraDeployedBU = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU)
      ?.split(Constants.SEMICOLON);
    List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();
    List<ER_Financial_Center__c> newItems = new List<ER_Financial_Center__c>();

    for (ER_Financial_Center__c fc : newFinancialCenters) {
      if (
        String.isNotBlank(fc.ER_BUPicklist__c) &&
        zuoraDeployedBU != null &&
        zuoraDeployedBU.contains(fc.ER_BUPicklist__c)
      )
        financialCenters.add(fc);
    }

    if (!financialCenters.isEmpty()) {
      //TODO
      // This block of of code has is duplicated on APER17_Contact_MAnagement.updateZuoraBillingAccount
      // It should be done inside a methode getFinancialCentersWithBAs and the soql query should be dynamic to cover new added fields in the custom metadata
      for (ER_Financial_Center__c newF : [
        SELECT
          Id,
          Name,
          ER_Type__c,
          ER_Business_Unit__c,
          ER_BUPicklist__c,
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
          ER_Account_Name__r.ER_Customer_Number__c,
          ER_Account_Name__r.ER_Registration_Number__c,
          ER_Invoicing_Street__c,
          ER_Invoicing_Zip_Code__c,
          ER_Invoicing_City__c,
          ER_Invoicing_Region_State__c,
          ER_Invoicing_Country__c,
          ER_Invoicing_Country_Code__c,
          (SELECT Id, Zuora__AccountNumber__c FROM Billing_Accounts__r)
        FROM ER_Financial_Center__c
        WHERE Id IN :financialCenters
      ]) {
        if (newF.ER_Contact__c != null && oldFinancialCenters.get(newF.Id).ER_Contact__c == null) {
          newItems.add(newF);
        } else {
          changedFields = Utils.splitValues(
            Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_FINANCIALCENTER_CHANGEDFIELDS + newF.ER_BUPicklist__c)
          );
          ER_Financial_Center__c oldF = oldFinancialCenters.get(newF.Id);

          for (String fld : changedFields) {
            if (!newF.Billing_Accounts__r.isEmpty() && newF.get(fld) != oldF.get(fld)) {
              listFcToSync.add(newF);
              break;
            }
          }
        }
      }

      if (!newItems.isEmpty())
        createZuoraBillingAccount(newItems);
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
  public static void updateLastModifiedDateFunctionalUser(List<ER_Financial_Center__c> newItems) {
    ER_Validation_Rules_Settings__c profileSetting = ER_Validation_Rules_Settings__c.getInstance(
      UserInfo.getProfileId()
    );
    ER_Validation_Rules_Settings__c userSetting = ER_Validation_Rules_Settings__c.getInstance(UserInfo.getUserId());

    for (ER_Financial_Center__c fc : newItems) {
      if (
        !profileSetting.ER_Last_Modified_Date_Functional_User__c &&
        !userSetting.ER_Last_Modified_Date_Functional_User__c
      )
        fc.ER_Last_Modified_Date_Functional_User__c = Datetime.now();
    }
  }

  /**
   * @author AAZ
   * @date 05/07/2022
   * @description Manage Financial Center Addresses
   * @param newItems
   */
  public static void manageFinancialCenterAddresses(List<ER_Financial_Center__c> newItems) {
    for (ER_Financial_Center__c fc : newItems) {
      if (!isFCPaymentAddressEmpty(fc) && isFCInvoicingAddressEmpty(fc)) {
        fc.ER_Invoicing_Street__c = fc.ER_Street__c;
        fc.ER_Invoicing_Zip_Code__c = fc.ER_Zip_Code__c;
        fc.ER_Invoicing_City__c = fc.ER_City__c;
        fc.ER_Invoicing_Region_State__c = fc.ER_State_Province__c;
        fc.ER_Invoicing_Country__c = fc.ER_Country__c;
        fc.ER_Invoicing_Country_Code__c = fc.ER_Country_Code__c;
      } else if (isFCPaymentAddressEmpty(fc) && !isFCInvoicingAddressEmpty(fc)) {
        fc.ER_Street__c = fc.ER_Invoicing_Street__c;
        fc.ER_Zip_Code__c = fc.ER_Invoicing_Zip_Code__c;
        fc.ER_City__c = fc.ER_Invoicing_City__c;
        fc.ER_State_Province__c = fc.ER_Invoicing_Region_State__c;
        fc.ER_Country__c = fc.ER_Invoicing_Country__c;
        fc.ER_Country_Code__c = fc.ER_Invoicing_Country_Code__c;
      }
    }
  }

  /**
   * @author AAZ
   * @description Check if FC payment address is empty
   * @param fc
   *
   * @return
   */
  private static Boolean isFCPaymentAddressEmpty(ER_Financial_Center__c fc) {
    if (
      String.isBlank(fc.ER_Street__c) &&
      String.isBlank(fc.ER_Zip_Code__c) &&
      String.isBlank(fc.ER_City__c) &&
      String.isBlank(fc.ER_State_Province__c) &&
      String.isBlank(fc.ER_Country__c) &&
      String.isNotBlank(fc.ER_Country_Code__c)
    )
      return true;
    return false;
  }

  /**
   * @author AAZ
   * @description Check if FC invoicing address is empty
   * @param fc
   *
   * @return
   */
  private static Boolean isFCInvoicingAddressEmpty(ER_Financial_Center__c fc) {
    if (
      String.isBlank(fc.ER_Invoicing_Street__c) &&
      String.isBlank(fc.ER_Invoicing_Zip_Code__c) &&
      String.isBlank(fc.ER_Invoicing_City__c) &&
      String.isBlank(fc.ER_Invoicing_Region_State__c) &&
      String.isBlank(fc.ER_Invoicing_Country__c) &&
      String.isBlank(fc.ER_Invoicing_Country_Code__c)
    )
      return true;
    return false;
  }

  /**
   * @author KHAD
   * @date 19/01/2023
   * @description Tick Financial center to be synced with Smarter
   * @param newItems
   */
  public static void markFinancialCenterToBeSyncedWithSmarter(List<ER_Financial_Center__c> newItems) {
    for (ER_Financial_Center__c fc : newItems) {
      if (fc.ER_SmartER_Context__c && !fc.ER_To_sync_with_smarter__c)
        fc.ER_To_sync_with_smarter__c = true;
    }
  }

  /**
   * @author KHAD
   * @date 19/01/2023
   * @description Tick Financial center to be synced with Smarter
   * @param newItems
   * @param oldItemsMap
   */
  public static void syncFinancialCenterToSmartER(
    List<ER_Financial_Center__c> newItems,
    Map<Id, ER_Financial_Center__c> oldItemsMap
  ) {
    List<id> fcToProcess = new List<id>();
    for (ER_Financial_Center__c fc : newItems) {
      if (fc.ER_SmartER_Context__c && fc.ER_To_sync_with_smarter__c && String.isNotBlank(fc.ER_BUPicklist__c)) {
        fcToProcess.add(fc.id);
      }
    }
    if (!fcToProcess.isEmpty()) {
      Set<id> fcToPublish = new Set<id>();
      for (ER_Financial_Center__c fc : [
        SELECT
          Id,
          ER_To_sync_with_smarter__c,
          ER_Invoicing_Street__c,
          ER_Invoicing_City__c,
          ER_Invoicing_Zip_Code__c,
          ER_Invoicing_Country__c,
          ER_Invoicing_Country_Code__c,
          ER_Master__c,
          ER_Email__c,
          ER_Secondary_Email__c
        FROM ER_Financial_Center__c
        WHERE Id IN :fcToProcess AND ER_Account_Name__r.SmartER_Customer_Id__c != NULL
      ]) {
        if (
          oldItemsMap == null ||
          (oldItemsMap != null &&
          (fc.ER_To_sync_with_smarter__c != oldItemsMap.get(fc.Id).ER_To_sync_with_smarter__c ||
          fc.ER_Invoicing_Street__c != oldItemsMap.get(fc.Id).ER_Invoicing_Street__c ||
          fc.ER_Invoicing_City__c != oldItemsMap.get(fc.Id).ER_Invoicing_City__c ||
          fc.ER_Invoicing_Zip_Code__c != oldItemsMap.get(fc.Id).ER_Invoicing_Zip_Code__c ||
          fc.ER_Invoicing_Country__c != oldItemsMap.get(fc.Id).ER_Invoicing_Country__c ||
          fc.ER_Invoicing_Country_Code__c != oldItemsMap.get(fc.Id).ER_Invoicing_Country_Code__c ||
          fc.ER_Master__c != oldItemsMap.get(fc.Id).ER_Master__c ||
          fc.ER_Email__c != oldItemsMap.get(fc.Id).ER_Email__c ||
          fc.ER_Secondary_Email__c != oldItemsMap.get(fc.Id).ER_Secondary_Email__c))
        ) {
          //PUT + check if some of the fields are changed !
          fcToPublish.add(fc.id);
        }
      }
      syncFinancialCenterToSmartER(fcToPublish);
    }
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 03-23-2023
   * @param financialCentersSet
   **/
  public static void syncFinancialCenterToSmartER(set<Id> financialCentersSet) {
    if (!financialCentersSet.isEmpty()) {
      Distributed_Transaction_Event__e evt = new Distributed_Transaction_Event__e();
      evt.Transaction_Name__c = Constants.SYNC_FC_TO_SMARTER;
      evt.Transaction_Content__c = JSON.serializePretty(financialCentersSet);
      EventBus.publish(evt);
    }
  }

  /**
   * @author KHAD
   * @date 19/01/2023
   * @description Tick Financial center to be synced with Smarter
   * @param financialCentersSet
   */
  @future(Callout=true)
  public static void doSyncFinancialCentersToSmartER(Set<Id> financialCentersSet) {
    if (financialCentersSet.isEmpty()) {
      return;
    }
    try {
      System.debug('>>>>> HD - doSync : ' + financialCentersSet);

      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      if (
        smarterAT == null ||
        smarterAT.isEmpty() ||
        !smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) ||
        !smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
      ) {
        return;
      }

      //Map< method ; BU ; List>
      Map<String, Map<String, List<Object>>> mapMethodBUPayLoads = new Map<String, Map<String, List<Object>>>{
        Constants.POST_METHOD => new Map<String, List<Object>>(),
        Constants.PATCH_METHOD => new Map<String, List<Object>>()
      };

      // Query FCs:
      List<ER_Financial_Center__c> financialCenters = [
        SELECT
          Id,
          ER_Account_Name__c,
          ER_To_sync_with_smarter__c,
          ER_Invoicing_Street__c,
          ER_Invoicing_City__c,
          ER_Invoicing_Zip_Code__c,
          ER_Invoicing_Country__c,
          ER_Invoicing_Country_Code__c,
          ER_Master__c,
          ER_Email__c,
          ER_Secondary_Email__c,
          ER_BUPicklist__c,
          ER_Smarter_1st_Sync_Date__c,
          ER_Contact__c,
          ER_SmartER_Original_Lead_Id__c,
          (SELECT Id, Zuora__AccountNumber__c FROM Billing_Accounts__r)
        FROM ER_Financial_Center__c
        WHERE
          Id IN :financialCentersSet
          AND ER_Account_Name__r.SmartER_Customer_Id__c != NULL
          AND ER_To_sync_with_smarter__c = TRUE
      ];

      for (ER_Financial_Center__c fc : financialCenters) {
        System.debug('>>>>> HD - doSync : ' + fc);

        String method = fc.ER_Smarter_1st_Sync_Date__c == null ? Constants.POST_METHOD : Constants.PATCH_METHOD;
        Map<String, List<Object>> buPayLoadMap = mapMethodBUPayLoads.get(method);
        List<Object> buPayLoad = buPayLoadMap.get(fc.ER_BUPicklist__c);
        if (buPayLoad == null) {
          buPayLoad = new List<Object>();
        }
        // TODO Check fields
        Map<String, Object> mapObj = new Map<String, Object>();
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_ONEFORCE_ACCOUNT_ID, fc.ER_Account_Name__c);
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_ID, fc.Id);
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_CONTACT_ID, fc.ER_Contact__c);
        if (fc.Billing_Accounts__r != null && !fc.Billing_Accounts__r.isEmpty()) {
          mapObj.put(
            Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_BILLINGACCOUNT_ID,
            fc.Billing_Accounts__r[0].Zuora__AccountNumber__c
          );
        } else {
          mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_BILLINGACCOUNT_ID, '');
        }
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_STREET, fc.ER_Invoicing_Street__c);
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_CITY, fc.ER_Invoicing_City__c);
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_ZIPCODE, fc.ER_Invoicing_Zip_Code__c);
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_COUNTRY, fc.ER_Invoicing_Country__c);
        mapObj.put(
          Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_COUNTRY_CODE,
          fc.ER_Invoicing_Country_Code__c
        );
        mapObj.put(
          Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_PRIMARY_EMAIL,
          (fc.ER_Email__c != null ? fc.ER_Email__c : '')
        );
        mapObj.put(
          Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_SECONDARY_EMAIL,
          (fc.ER_Secondary_Email__c != null ? fc.ER_Secondary_Email__c : '')
        );
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_ISMaster, fc.ER_Master__c);
        mapObj.put(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_ORIGINAL_LEAD_ID, fc.ER_SmartER_Original_Lead_Id__c);

        buPayLoad.add(mapObj);
        buPayLoadMap.put(fc.ER_BUPicklist__c, buPayLoad);
      }
      System.debug('>>>>> HD - doSync : ' + mapMethodBUPayLoads);

      // Send POST requests :
      HttpRequest req = new HttpRequest();
      Http http = new Http();
      HttpResponse resp = new HttpResponse();
      List<ER_Financial_Center__c> fcToUpdate = new List<ER_Financial_Center__c>();
      for (String method : mapMethodBUPayLoads.keySet()) {
        Map<String, List<Object>> buPayLoadMap = mapMethodBUPayLoads.get(method);
        if (!buPayLoadMap.isEmpty()) {
          for (String bu : buPayLoadMap.keySet()) {
            List<Object> payLoadList = buPayLoadMap.get(bu);
            if (Limits.getCallouts() < Limits.getLimitCallouts()) {
              req.setEndpoint(
                'callout:' +
                Constants.SMARTER_NAMED_CREDENTIAL +
                Constants.SLASH +
                Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_SERVICE_VERSION +
                Constants.SLASH +
                Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_SERVICE_NAME +
                Constants.SLASH
              );
              req.setMethod(method);
              req.setHeader('Content-Type', 'application/json');
              req.setHeader('Accept', 'application/json');
              req.setHeader('X-Tenant', bu);
              req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
              //req.setHeader('X-Correlation-Id', '426983445D5a65208249DAAC3D29ab7d');
              req.setHeader(
                'Authorization',
                smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
                ' ' +
                smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
              );

              String payload = JSON.serialize(payLoadList);
              System.debug('>>>>> HD - payload : ' + payload);
              req.setBody(payload);
              resp = http.send(req);
              fcToUpdate.addAll(getFCListToUpdate(payLoadList, method, resp));
            }
          }
        }
      }
      database.update(fcToUpdate, false);
    } catch (Exception e) {
      System.debug(' >>>> doSyncFinancialCentersToSmartER Exception : ' + e.getMessage());
    }
  }

  static List<ER_Financial_Center__c> getFCListToUpdate(
    List<Object> payLoadList,
    String methodName,
    HttpResponse response
  ) {
    List<ER_Financial_Center__c> updateList = new List<ER_Financial_Center__c>();
    if (payLoadList.isEmpty()) {
      return updateList;
    }

    if (response.getStatusCode() == 204) {
      for (Object obj : payLoadList) {
        ER_Financial_Center__c newFC = new ER_Financial_Center__c();
        Map<String, Object> mapObj = (Map<String, Object>) obj;
        newFc.id = (id) mapObj.get(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_ID);
        if (methodName == 'POST') {
          newFC.ER_Smarter_1st_Sync_Date__c = dateTime.now();
        }
        newFc.ER_Smarter_Last_Sync_Date__c = dateTime.now();
        newFc.ER_Smarter_Sync_Status__c = constants.SYNCHRONIZED_STATUS;
        newFc.ER_Smarter_Sync_Error__c = null;
        updateList.add(newFC);
      }
    } else if (response.getBody() != null && (response.getStatusCode() == 400 || response.getStatusCode() == 500)) {
      try {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> metaMap = (Map<String, Object>) (m.get('meta'));
        List<Object> att = (List<Object>) metaMap.get('messages');
        Map<String, Object> data = (Map<String, Object>) att[0];

        for (Object obj : payLoadList) {
          Map<String, Object> mapObj = (Map<String, Object>) obj;
          updateList.add(
            new ER_Financial_Center__c(
              id = (id) mapObj.get(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_ID),
              ER_Smarter_Last_Sync_Date__c = dateTime.now(),
              ER_Smarter_Sync_Status__c = constants.NOT_SYNCHRONIZED_STATUS,
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
      } catch (Exception e) {
        System.debug(' >>>> getFCListToUpdate Exception : ' + e.getMessage());
      }
    }
    return updateList;
  }

  /**
   * @author AAZ
   * @date 05/09/2022
   * @description Pushback to smartER all generated ids (AccountId, ContactId, FCId, OpportunityId) after a lead conversion
   * @param newItems
   */
  public static void pushBackSmartERIds(List<ER_Financial_Center__c> newItems) {
    Set<Id> fcIds = new Set<Id>();
    System.debug('>>>>> ALK - pushBackSmartERIds');

    for (ER_Financial_Center__c fc : newItems) {
      System.debug(
        '>>>>> ALK - fc.ER_SmartER_Context__c ' +
        fc.ER_SmartER_Context__c +
        ' - fc.ER_SmartER_Original_Lead_Id__c : ' +
        fc.ER_SmartER_Original_Lead_Id__c
      );
      if (fc.ER_SmartER_Context__c && String.isNotBlank(fc.ER_SmartER_Original_Lead_Id__c))
        fcIds.add(fc.Id);
    }

    if (!fcIds.isEmpty()) {
      Distributed_Transaction_Event__e evt = new Distributed_Transaction_Event__e();
      evt.Transaction_Name__c = Constants.SMARTER_PUSH_BACK_IDS;
      evt.Transaction_Content__c = JSON.serializePretty(fcIds);
      EventBus.publish(evt);
    }
  }

  /**
   * @author AAZ
   * @date 05/09/2022
   * @description Pushback to smartER all lead generated ids after a lead conversion
   * <ul>
   *     <li>AccountId</li>
   *     <li>ContactId</li>
   *     <li>OpportunityId</li>
   *     <li>FinancialCenterId</li>
   *     <li>BillingAccountNumber</li>
   * </ul>
   * @param financialCenters
   */
  @Future(Callout=true)
  public static void pushBackLeadConversionIds(Set<Id> financialCenters) {
    System.debug('>>>>> ALK - pushBackLeadConversionIds - financialCenters : ' + financialCenters);
    if (financialCenters != null && !financialCenters.isEmpty()) {
      HttpRequest req = new HttpRequest();
      Http http = new Http();
      HttpResponse resp = new HttpResponse();
      Set<Id> mapFcLeadId = new Set<Id>();
      Map<String, Id> mapLeadIdOppId = new Map<String, Id>();
      Map<String, Object> mapData = new Map<String, Object>();
      Map<Id, ER_Financial_Center__c> mapFcs = new Map<Id, ER_Financial_Center__c>();
      Map<String, List<Object>> mapBUPayload = new Map<String, List<Object>>();
      String ddTraceId;

      for (ER_Financial_Center__c fc : [
        SELECT
          Id,
          ER_SmartER_Original_Lead_Id__c,
          ER_Account_Name__c,
          ER_Contact__c,
          ER_BUPicklist__c,
          ER_dd_Trace_Id__c
        FROM ER_Financial_Center__c
        WHERE
          Id IN :financialCenters
          AND ER_SmartER_Context__c = TRUE
          AND ER_SmartER_Original_Lead_Id__c != NULL
          AND CreatedBy.Profile.Name = :Constants.PROFILE_ER_INTEGRATION
      ]) {
        if (ddTraceId == null && String.isNotBlank(fc.ER_dd_Trace_Id__c))
          ddTraceId = fc.ER_dd_Trace_Id__c;
        mapFcs.put(fc.Id, fc);
        mapFcLeadId.add(fc.ER_SmartER_Original_Lead_Id__c);
      }

      if (!mapFcs.isEmpty()) {
        for (Opportunity o : [
          SELECT Id, ER_SmartER_Original_Lead_Id__c
          FROM Opportunity
          WHERE ER_SmartER_Original_Lead_Id__c IN :mapFcLeadId
        ]) {
          mapLeadIdOppId.put(o.ER_SmartER_Original_Lead_Id__c, o.Id);
        }

        for (ER_Financial_Center__c fc : mapFcs.values()) {
          if (String.isNotBlank(fc.ER_BUPicklist__c)) {
            if (!mapBUPayload.containsKey(fc.ER_BUPicklist__c))
              mapBUPayload.put(fc.ER_BUPicklist__c, new List<Object>());
            Map<String, Object> mapStructureIds = new Map<String, Object>();
            mapStructureIds.put(Constants.SMARTER_PUSH_BACK_BA_ID, '');
            mapStructureIds.put(
              Constants.SMARTER_PUSH_BACK_OPP_ID,
              mapLeadIdOppId.get(fc.ER_SmartER_Original_Lead_Id__c)
            );
            mapStructureIds.put(Constants.SMARTER_PUSH_BACK_FC_ID, fc.Id);
            mapStructureIds.put(Constants.SMARTER_CONTACT_ONEFORCE_ID, fc.ER_Contact__c);
            mapStructureIds.put(Constants.SMARTER_PUSH_BACK_ACCOUNT_ID, fc.ER_Account_Name__c);
            mapStructureIds.put(Constants.SMARTER_PUSH_BACK_LEAD_ID, fc.ER_SmartER_Original_Lead_Id__c);
            mapBUPayload.get(fc.ER_BUPicklist__c).add(mapStructureIds);
          }
        }

        if (!mapBUPayload.isEmpty()) {
          Map<String, String> smarterAT = Utils.getSmarterAccessToken();
          if (smarterAT != null && !smarterAT.isEmpty()) {
            String tokenType = smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE);
            String accessToken = smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN);
            if (tokenType != null && accessToken != null) {
              for (String bu : mapBUPayload.keySet()) {
                mapData.put('data', mapBUPayload.get(bu));

                if (Limits.getCallouts() < Limits.getLimitCallouts()) {
                  req.setEndpoint(
                    'callout:' +
                    Constants.SMARTER_NAMED_CREDENTIAL +
                    Constants.SLASH +
                    Constants.SMARTER_PUSH_BACK_IDS_VERSION +
                    Constants.SLASH +
                    Constants.SMARTER_PUSH_BACK_IDS_SERVICE_NAME
                  );

                  req.setMethod(Constants.POST_METHOD);
                  req.setHeader('Content-Type', 'application/json');
                  req.setHeader('Accept', 'application/json');
                  req.setHeader('X-Tenant', bu);
                  req.setHeader('Authorization', tokenType + ' ' + accessToken);
                  if (String.isNotBlank(ddTraceId))
                    req.setHeader(Constants.REQUEST_HEADER_DD_TRACEID, ddTraceId);
                  //req.setHeader('X-Correlation-Id','426983445D5a65208249DAAC3D29ab7d');
                  req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
                  req.setHeader('Authorization', tokenType + ' ' + accessToken);

                  String payload = JSON.serialize(mapData);
                  System.debug('>>>>> AAZ - payload : ' + payload);
                  req.setBody(payload);
                  resp = http.send(req);

                  System.debug('>>>>> ALK - pushBackLeadConversionIds resp.getStatusCode() : ' + resp.getStatusCode());
                  if (resp.getStatusCode() == 204) {
                    //Map<String, Object> mapRespData = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                    System.debug('>>>>> AAZ - Success resp.getStatusCode(): ' + resp.getStatusCode());
                  } else {
                    System.debug('>>>>> ALK - status code : ' + resp.getStatusCode());
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  /**
   * @author ALK
   * @date 28/06/2022
   * @description SmartER Set SmartER context on the FC
   * @param newItems
   */
  public static void setFCAsSmartERContext(List<ER_Financial_Center__c> newItems) {
    List<String> smartERDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
      ?.split(Constants.SEMICOLON);

    for (ER_Financial_Center__c fc : newItems) {
      if (
        smartERDeployedBUs != null &&
        (smartERDeployedBUs.contains(fc.ER_BUPicklist__c) || smartERDeployedBUs.contains(Constants.ALL)) &&
        !fc.ER_SmartER_Context__c
      ) {
        fc.ER_SmartER_Context__c = false;
      }
    }
  }

  /**
   * @author AAZ
   * @date 05/05/2023
   * @description Check account profile for SEPA payment
   * @param fcId
   *
   * @return
   */
  @AuraEnabled
  public static String checkAccountProfileSEPA(Id fcId) {
    String message;
    System.debug('>>>>> ALK - fcId : ' + fcId);
    if (String.isNotBlank(fcId)) {
      List<Account> accounts = [
        SELECT
          Id,
          ER_Legal_Status__c,
          ER_Credit_Scoring__c,
          (SELECT Id FROM Zuora__Payments__r WHERE Zuora__AppliedCreditBalanceAmount__c > 0)
        FROM Account
        WHERE Id IN (SELECT ER_Account_Name__c FROM ER_Financial_Center__c WHERE Id = :fcId)
      ];

      if (
        !accounts.isEmpty() &&
        accounts[0].ER_Legal_Status__c == Constants.ACTIVE &&
        accounts[0].ER_Credit_Scoring__c != null &&
        accounts[0].ER_Credit_Scoring__c >= 50 &&
        accounts[0].Zuora__Payments__r.isEmpty()
      ) {
        System.debug('>>>>> ALK - All criteria are met');
        update new ER_Financial_Center__c(Id = fcId, ER_Direct_Debit_Scoring__c = true);
      } else {
        message =
          Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN +
          ' - ' +
          String.format(Label.LAB_SF_DIRECT_DEBIT_SCORING_CANNOT_BE_CALCULATED, new List<String>{ fcId });
      }
    } else {
      message =
        Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN +
        ' - ' +
        String.format(Label.LAB_SF_UNKNOWN_FC_ERROR, new List<String>{ fcId });
    }

    return message;
  }

  /**
   * @author Noor
   * @date 28/08/2023
   * @description Get Docusign Template Id
   *
   * @param newItems updated ER_Financial_Center__c
   */
  public static void updateDocusignTemplateId(List<ER_Financial_Center__c> newItems) {
    Map<String, Global_Settings__mdt> globalSettingsMap = Utils.getGlobalSettings();
    String PREFIX = 'DOCUSIGN_FC_';

    for (ER_Financial_Center__c f : newItems) {
      String filterKey = PREFIX;
      filterKey += f.ER_Business_Unit__c;
      if (f.ER_SmartER_Context__c && globalSettingsMap.containsKey(filterKey))
        f.ER_Docusign_Template__c = globalSettingsMap.get(filterKey).Valueforformula__c;
    }
  }

  /**
   * @author Noor
   * @date 28/08/2023
   * @description Get Docusign Template Id
   *
   * @param newItems updated ER_Financial_Center__c
   * @param oldMaps
   */
  public static void generateBankAccount(
    Map<Id, ER_Financial_Center__c> newItems,
    Map<Id, ER_Financial_Center__c> oldMaps
  ) {
    Map<String, Id> ibanFCMap = new Map<String, Id>();
    Map<String, Id> existingIbansBAMap = new Map<String, Id>();
    Map<Id, ER_Bank_Account__c> newBankAccounts = new Map<Id, ER_Bank_Account__c>();

    for (ER_Financial_Center__c f : newItems.values())
      if (String.isNotBlank(f.ER_DocuGen_IBAN__c) && f.ER_DocuGen_IBAN__c != oldMaps.get(f.Id).ER_DocuGen_IBAN__c)
        ibanFCMap.put(f.ER_DocuGen_IBAN__c, f.Id);

    for (ER_Bank_Account__c ba : [
      SELECT Id, ER_Financial_Center__c, ER_IBAN__c
      FROM ER_Bank_Account__c
      WHERE ER_IBAN__c IN :ibanFCMap.keySet()
    ])
      existingIbansBAMap.put(ba.ER_IBAN__c, ba.Id);

    for (String iban : ibanFCMap.keySet())
      if (!existingIbansBAMap.containsKey(iban))
        newBankAccounts.put(ibanFCMap.get(iban), createBankAccount(newItems.get(ibanFCMap.get(iban))));

    if (!newBankAccounts.isEmpty()) {
      List<ER_Financial_Center__c> fcToUpdates = new List<ER_Financial_Center__c>();

      try {
        Database.insert(newBankAccounts.values(), false);

        for (Id fc : newBankAccounts.keySet()) {
          if (newBankAccounts.get(fc).Id != null)
            fcToUpdates.add(new ER_Financial_Center__c(Id = fc, ER_Bank_Account__c = newBankAccounts.get(fc).Id));
        }

        if (!fcToUpdates.isEmpty())
          update fcToUpdates;
      } catch (DmlException e) {
        throw new ApplicationException('Unable to Perform the DML Operation on Account : ' + e.getMessage());
      }
    }
  }

  /**
   * @author Noor
   * @date 28/08/2023
   * @description Create bank account from FC
   *
   * @param fc financial center
   * @return Bank Account
   */
  public static ER_Bank_Account__c createBankAccount(ER_Financial_Center__c fc) {
    ER_Bank_Account__c ba = new ER_Bank_Account__c();
    ba.Name = fc.Name;
    ba.ER_Financial_Center__c = fc.Id;
    ba.ER_IBAN__c = fc.ER_DocuGen_IBAN__c;
    ba.ER_BIC__c = fc.ER_DocuGen_BIC__c;
    ba.ERFI_Payment_Reference_Type__c = 'Standard';
    ba.ER_SEPA_Direct_Debit_Type__c = 'CORE';
    ba.ER_BUPicklist__c = fc.ER_Business_Unit__c;
    return ba;
  }

  /**
   * @author AAZ
   * @date 28/08/2023
   * @description Call CEGEDIM after a Bank Account is linked to a FC in order to validate the IBAN
   *
   * @param newItems
   * @param oldMaps
   */
  public static void validateIban(List<ER_Financial_Center__c> newItems, Map<Id, ER_Financial_Center__c> oldMaps) {
    List<Id> financialCenters = new List<Id>();
    for (ER_Financial_Center__c f : newItems) {
      if (
        f.ER_SmartER_Context__c &&
        String.isNotBlank(f.ER_DocuGen_IBAN__c) &&
        f.ER_Bank_Account__c != null &&
        oldMaps.get(f.Id).ER_Bank_Account__c == null
      )
        financialCenters.add(f.Id);
    }

    if (!financialCenters.isEmpty())
      doValidateIban(financialCenters);
  }

  /**
   * @author AAZ
   * @date 28/08/2023
   * @description Call CEGEDIM after a Bank Account is linked to a FC in order to validate the IBAN
   *
   * @param fcIds
   */
  @Future(Callout=true)
  public static void doValidateIban(List<Id> fcIds) {
    if (!fcIds.IsEmpty()) {
      List<ER_Bank_Account__c> listBankAccountToUpdate = new List<ER_Bank_Account__c>();
      List<Id> listBAToUpdate = new List<Id>();
      List<ER_Financial_Center__c> fcs = [
        SELECT
          Id,
          ER_BUPicklist__c,
          ER_DocuGen_IBAN__c,
          ER_Bank_Account__c,
          ER_Bank_Account__r.ER_SEPA_Direct_Debit_Type__c,
          ER_Contact__r.Name,
          ER_Account_Name__r.Name
        FROM ER_Financial_Center__c
        WHERE Id IN :fcIds
      ];

      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      String tokenType = smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE);
      String accessToken = smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN);
      System.debug('>>>>> AAZ - tokenType ' + tokenType + ' - accessToken : ' + accessToken);

      if (tokenType != null && accessToken != null) {
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HttpResponse resp = new HttpResponse();
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> mapGrpHdr = new Map<String, Object>();
        Map<String, Object> mapBicIbanVldtnRqst = new Map<String, Object>();
        Map<String, Object> mapInitgPty = new Map<String, Object>();
        Map<String, Object> mapPrvtId = new Map<String, Object>();
        Map<String, Object> mapIntlAcct = new Map<String, Object>();

        for (ER_Financial_Center__c fc : fcs) {
          String edeneredCegedimEntityId = Utils.getGlobalSettingsValueFromKey(
            Constants.CEGEDIM_EDENRED_ENTITY_ID + fc.ER_BUPicklist__c
          );
          mapGrpHdr.put(Constants.CEGEDIM_API_JSON_VALIDATE_IBAN_MSGID, 'validateIban');
          mapGrpHdr.put(Constants.CEGEDIM_API_JSON_CREDTM, Datetime.now());
          mapPrvtId.put(Constants.CEGEDIM_API_JSON_ID, edeneredCegedimEntityId);
          mapInitgPty.put(Constants.CEGEDIM_API_JSON_PRVTID, mapPrvtId);
          mapGrpHdr.put(Constants.CEGEDIM_API_JSON_INITGPTY, mapInitgPty);
          mapIntlAcct.put(Constants.CEGEDIM_API_JSON_IBAN, fc.ER_DocuGen_IBAN__c);
          mapBicIbanVldtnRqst.put(Constants.CEGEDIM_API_JSON_INTLACCT, mapIntlAcct);
          payload.put(Constants.CEGEDIM_API_JSON_GRPHDR, mapGrpHdr);
          payload.put(Constants.CEGEDIM_API_JSON_BICIBAN_VLDTNRQST, mapBicIbanVldtnRqst);

          if (Limits.getCallouts() < Limits.getLimitCallouts()) {
            req.setEndpoint(
              'callout:' +
              Constants.SMARTER_NAMED_CREDENTIAL +
              Constants.SLASH +
              Constants.SMARTER_VALIDATE_IBAN_SERVICE_VERSION +
              Constants.SLASH +
              Constants.SMARTER_VALIDATE_IBAN_SERVICE_NAME
            );
            req.setMethod(Constants.POST_METHOD);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
            req.setHeader('Authorization', tokenType + ' ' + accessToken);

            String reqPayload = JSON.serialize(payload);
            System.debug('>>>>> AAZ - payload : ' + reqPayload);
            req.setBody(reqPayload);
            resp = http.send(req);
            System.debug('>>>>> AAZ - resp.getStatusCode() : ' + resp.getStatusCode());

            if (resp.getStatusCode() == 200) {
              System.debug('>>>>> AAZ - IBAN is VALID');
              Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
              Map<String, Object> bimtMap = (Map<String, Object>) (m.get(Constants.CEGEDIM_API_JSON_VALIDATEIBAN_RESP));
              List<Object> ibanResps = (List<Object>) bimtMap.get(Constants.CEGEDIM_API_JSON_BICIBAN_VLDTNRESP);
              Map<String, Object> ibanResp = (Map<String, Object>) ibanResps[0];
              Map<String, Object> respMandateCreation = new Map<String, Object>();

              if (
                (String) ibanResp.get(Constants.CEGEDIM_API_JSON_STSCODE) == Constants.CEGEDIM_API_JSON_STSCODE_ACCEPTED
              ) {
                //Iban is valid
                respMandateCreation = activateDirectDebit(fc, tokenType, accessToken);

                if (
                  respMandateCreation != null &&
                  (String) respMandateCreation.get(Constants.CEGEDIM_API_JSON_TX_STS) ==
                  Constants.CEGEDIM_API_JSON_TX_STS_ACCEPTED &&
                  (String) respMandateCreation.get(Constants.CEGEDIM_API_JSON_TX_STSCODE) ==
                  Constants.CEGEDIM_API_JSON_TX_STSCODE_CREATED
                ) {
                  //Mandate is created

                  Decimal rui = ((String) respMandateCreation.get(Constants.CEGEDIM_API_JSON_RUI)).isNumeric()
                    ? Decimal.valueOf((String) respMandateCreation.get(Constants.CEGEDIM_API_JSON_RUI))
                    : null;
                  listBankAccountToUpdate.add(
                    new ER_Bank_Account__c(
                      Id = fc.ER_Bank_Account__c,
                      ER_SEPA_reference__c = (String) respMandateCreation.get(Constants.CEGEDIM_API_JSON_RUM),
                      ERFI_Settlement_Reference_Number__c = rui,
                      ER_SEPA_active__c = true, //check mndtSts ??
                      ER_Bank_Account_Status__c = Constants.OPEN
                    )
                  );
                  listBAToUpdate.add(fc.Id);
                }
              }
            } else
              System.debug('>>>>> AAZ - Validate Iban: Error returned');
          }
        }

        if (!listBankAccountToUpdate.IsEmpty())
          update listBankAccountToUpdate;
        if (!listBAToUpdate.IsEmpty())
          updateBillingAccounts(listBAToUpdate);
      }
    }
  }

  /**
   * @author AAZ
   * @date 30/08/2023
   * @description Call CEGEDIM if an IBAN is valid in order to activate the direct debit
   *
   * @param fc
   * @param tokenType
   * @param accessToken
   * @return
   */
  public static Map<String, Object> activateDirectDebit(
    ER_Financial_Center__c fc,
    String tokenType,
    String accessToken
  ) {
    if (tokenType != null && accessToken != null) {
      String edeneredCegedimEntityId = Utils.getGlobalSettingsValueFromKey(
        Constants.CEGEDIM_EDENRED_ENTITY_ID + fc.ER_BUPicklist__c
      );
      String edeneredCegedimCrdtCode = Utils.getGlobalSettingsValueFromKey(
        Constants.CEGEDIM_EDENRED_CRDT_CODE + fc.ER_BUPicklist__c
      );

      HttpRequest req = new HttpRequest();
      Http http = new Http();
      HttpResponse resp = new HttpResponse();
      Map<String, Object> payload = new Map<String, Object>();
      Map<String, Object> mapGrpHdr = new Map<String, Object>();
      Map<String, Object> mapInitgPty = new Map<String, Object>();
      Map<String, Object> mapPrvtId = new Map<String, Object>();
      Map<String, Object> mapCdtrMndtInf = new Map<String, Object>();
      Map<String, Object> mapCdtr = new Map<String, Object>();
      Map<String, Object> mapCdtrPrvtId = new Map<String, Object>();
      List<Map<String, Object>> mapMndtInfList = new List<Map<String, Object>>();
      Map<String, Object> mapMndtInfObj = new Map<String, Object>();
      Map<String, Object> mapDbtr = new Map<String, Object>();
      Map<String, Object> mapPstlAdr = new Map<String, Object>();
      Map<String, Object> mapDbtrAcct = new Map<String, Object>();

      mapGrpHdr.put(Constants.CEGEDIM_API_JSON_CREATE_MANDAT_MSGID, 'activateDirectDebit');
      mapGrpHdr.put(Constants.CEGEDIM_API_JSON_CREDTM, Datetime.now());
      mapGrpHdr.put(Constants.CEGEDIM_API_JSON_NB_TX, '1');
      mapPrvtId.put(Constants.CEGEDIM_API_JSON_ID, edeneredCegedimEntityId);
      mapInitgPty.put(Constants.CEGEDIM_API_JSON_PRVTID, mapPrvtId);
      mapGrpHdr.put(Constants.CEGEDIM_API_JSON_INITGPTY, mapInitgPty);

      mapCdtrPrvtId.put(Constants.CEGEDIM_API_JSON_ID, edeneredCegedimCrdtCode);
      mapCdtr.put(Constants.CEGEDIM_API_JSON_PRVTID, mapCdtrPrvtId);
      mapCdtrMndtInf.put(Constants.CEGEDIM_API_JSON_CRDT, mapCdtr);
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_IDX, fc.Id);
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_IS_MIGRATED, false);
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_ORGNID, Constants.CEGEDIM_API_JSON_ORGNID_EDENRED);
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_RUI, fc.ER_Bank_Account__c);
      mapMndtInfObj.put(
        Constants.CEGEDIM_API_JSON_MNDTTP,
        String.IsNotBlank(fc.ER_Bank_Account__r.ER_SEPA_Direct_Debit_Type__c)
          ? fc.ER_Bank_Account__r.ER_SEPA_Direct_Debit_Type__c
          : Constants.CEGEDIM_API_JSON_MNDTTP_B2B
      );
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_SEQTP, Constants.CEGEDIM_API_JSON_SEQTP_RCUR);
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_DTOFSGNTR, Datetime.now());
      mapPstlAdr.put(Constants.CEGEDIM_API_JSON_COUNTRY, fc.ER_BUPicklist__c);
      mapDbtr.put(
        Constants.CEGEDIM_API_JSON_DBTR_NAME,
        fc.ER_Bank_Account__r.ER_SEPA_Direct_Debit_Type__c == Constants.CEGEDIM_API_JSON_MNDTTP_B2B
          ? fc.ER_Account_Name__r.Name
          : fc.ER_Contact__r.Name
      );
      mapDbtr.put(Constants.CEGEDIM_API_JSON_PSTLADR, mapPstlAdr);
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_DBTR, mapDbtr);
      mapDbtrAcct.put(Constants.CEGEDIM_API_JSON_IBAN, fc.ER_DocuGen_IBAN__c);
      mapMndtInfObj.put(Constants.CEGEDIM_API_JSON_DBTR_ACC, mapDbtrAcct);
      mapMndtInfList.add(mapMndtInfObj);
      mapCdtrMndtInf.put(Constants.CEGEDIM_API_JSON_MNDTINF, mapMndtInfList);

      payload.put(Constants.CEGEDIM_API_JSON_GRPHDR, mapGrpHdr);
      payload.put(Constants.CEGEDIM_API_JSON_CDTR_MNDINF, mapCdtrMndtInf);

      if (Limits.getCallouts() < Limits.getLimitCallouts()) {
        req.setEndpoint(
          'callout:' +
          Constants.SMARTER_NAMED_CREDENTIAL +
          Constants.SLASH +
          Constants.SMARTER_CREATE_MANDAT_SERVICE_VERSION +
          Constants.SLASH +
          Constants.SMARTER_CREATE_MANDAT_SERVICE_NAME
        );
        req.setMethod(Constants.POST_METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        req.setHeader('Authorization', tokenType + ' ' + accessToken);

        String reqPayload = JSON.serializePretty(payload);
        System.debug('>>>>> AAZ - payload : ' + reqPayload);
        req.setBody(reqPayload);
        resp = http.send(req);
        System.debug('>>>>> AAZ - resp.getStatusCode() : ' + resp.getStatusCode());

        if (resp.getStatusCode() == 200 || resp.getStatusCode() == 400) {
          Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
          Map<String, Object> mamtMap = (Map<String, Object>) (m.get(Constants.CEGEDIM_API_JSON_CREATE_MANDAT_RESP));
          Map<String, Object> cdtrMndtAnsMap = (Map<String, Object>) (mamtMap.get(
            Constants.CEGEDIM_API_JSON_CDTRMND_INFO
          ));
          List<Object> mndtAnsArray = (List<Object>) cdtrMndtAnsMap.get(Constants.CEGEDIM_API_JSON_MNDT_INFO);
          Map<String, Object> mndtAns = (Map<String, Object>) mndtAnsArray[0];
          return mndtAns;
        } else {
          System.debug('>>>>> AAZ - Mandat not created successfully');
          return null;
        }
      }
    }
    return null;
  }

  /**
   * @author AAZ
   * @date 01/09/2023
   * @description once the mandates are created successfully, we update the billing accounts linked to the FCs
   *
   * @param fcs
   * @return
   */
  public static void updateBillingAccounts(List<Id> fcs) {
    String zuoraToken = ZuoraUtils.getZuoraToken();
    List<Zuora__CustomerAccount__c> zAccounts = [
      SELECT Zuora__AccountNumber__c, ER_Financial_Center__r.ER_BUPicklist__c, ER_Financial_Center__r.ER_Type__c
      FROM Zuora__CustomerAccount__c
      WHERE ER_Financial_Center__c IN :fcs
    ];

    for (Zuora__CustomerAccount__c zAcc : zAccounts) {
      if (Limits.getCallouts() < Limits.getLimitCallouts()) {
        //Get Direct Debit payment method
        String scope = (zAcc.ER_Financial_Center__r.ER_Type__c == Constants.MERCHANT
          ? Constants.MERCHANT_UNDERSCORE
          : Constants.CLIENT_UNDERSCORE);
        String directDebitPaymentMethod = Utils.getGlobalSettingsValueFromKey(
          Constants.ZUORA_PAYMENTMETHOD_BANKTRANSFER +
          scope +
          zAcc.ER_Financial_Center__r.ER_BUPicklist__c
        );

        ZuoraUtils.ZuoraCustomerWrapper zAccountWrap = new ZuoraUtils.ZuoraCustomerWrapper();
        zAccountWrap.BillAccNumber = zAcc.Zuora__AccountNumber__c;
        zAccountWrap.BusinessUnit = zAcc.ER_Financial_Center__r.ER_BUPicklist__c;
        zAccountWrap.PaymentTerm = Constants.PAYMENT_TERM_AT_RECEPTION_OF_INVOICE;
        zAccountWrap.PaymentMethodId = directDebitPaymentMethod;
        ZuoraUtils.updateZuoraAccount(zAccountWrap, zuoraToken);
      }
    }
  }
}