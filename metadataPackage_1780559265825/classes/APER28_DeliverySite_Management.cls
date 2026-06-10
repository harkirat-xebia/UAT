/*
----------------------------------------------------------------------
-- - Name          : APER28_DeliverySite_Management
-- - Author        : KHAD
-- - Description   : Delivery Site Management, This class is used to group all the functionnality linked to the object Delivery Site
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  FEB-2021       KHAD                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public without sharing class APER28_DeliverySite_Management {
  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageDSLIFromContract(Contract contract) {
    if (UtilsBypass.canTrigger('manageDSLIFromContract')) {
      GenericWithoutSharing.manageDSLIFromContract(contract);
    }
  }

  //Method added by harkirat for acr creation
  public static void createAcrForDeliverySites(
    Map<Id, SObject> newItems,
    Map<Id, SObject> oldItems
) {
    if (newItems == null || newItems.isEmpty()) {
        return;
    }

    // Cast maps
    Map<Id, ER_Delivery_Site__c> newDsMap =
        (Map<Id, ER_Delivery_Site__c>) newItems;
    Map<Id, ER_Delivery_Site__c> oldDsMap =
        (oldItems != null ? (Map<Id, ER_Delivery_Site__c>) oldItems : null);

    List<ER_Delivery_Site__c> dsToProcess = new List<ER_Delivery_Site__c>();
    Set<Id> contactIds = new Set<Id>();
    Set<Id> fcIds = new Set<Id>();

    // 1) Collect DS where ER_Delivery_Contact__c changed / got set
    for (ER_Delivery_Site__c dsNew : newDsMap.values()) {
        ER_Delivery_Site__c dsOld =
            (oldDsMap != null ? oldDsMap.get(dsNew.Id) : null);

        Boolean contactChanged =
            (dsOld == null && dsNew.ER_Delivery_Contact__c != null) ||
            (dsOld != null && dsNew.ER_Delivery_Contact__c != dsOld.ER_Delivery_Contact__c);

        if (!contactChanged) {
            continue;
        }

        if (dsNew.ER_Financial_Center__c != null &&
            dsNew.ER_Delivery_Contact__c != null) {

            dsToProcess.add(dsNew);
            contactIds.add(dsNew.ER_Delivery_Contact__c);
            fcIds.add(dsNew.ER_Financial_Center__c);
        }
    }

    if (dsToProcess.isEmpty()) {
        return;
    }

    // 2) Get Account for each Financial Center
    Map<Id, Id> fcIdToAccountId = new Map<Id, Id>();
    for (ER_Financial_Center__c fc : [
        SELECT Id, ER_Account_Name__c
        FROM ER_Financial_Center__c
        WHERE Id IN :fcIds
    ]) {
        if (fc.ER_Account_Name__c != null) {
            fcIdToAccountId.put(fc.Id, fc.ER_Account_Name__c);
        }
    }

    // 3) Build Account + Contact pairs
    Set<Id> accountIds = new Set<Id>();
    List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();

    // First gather all unique pairs to check existing ACRs
    Set<String> pairKeys = new Set<String>();

    for (ER_Delivery_Site__c ds : dsToProcess) {
        Id accId = fcIdToAccountId.get(ds.ER_Financial_Center__c);
        Id conId = ds.ER_Delivery_Contact__c;

        if (accId == null || conId == null) {
            continue;
        }

        accountIds.add(accId);
        contactIds.add(conId);
        pairKeys.add(String.valueOf(accId) + '-' + String.valueOf(conId));
    }

    if (accountIds.isEmpty() || contactIds.isEmpty()) {
        return;
    }

    // 4) Existing ACRs
    List<AccountContactRelation> existingAcrs = [
        SELECT Id, AccountId, ContactId
        FROM AccountContactRelation
        WHERE AccountId IN :accountIds
          AND ContactId IN :contactIds
    ];

    Set<String> existingPairs = new Set<String>();
    for (AccountContactRelation acr : existingAcrs) {
        existingPairs.add(
            String.valueOf(acr.AccountId) + '-' + String.valueOf(acr.ContactId)
        );
    }

    // 5) Create missing ACRs
    for (ER_Delivery_Site__c ds : dsToProcess) {
        Id accId = fcIdToAccountId.get(ds.ER_Financial_Center__c);
        Id conId = ds.ER_Delivery_Contact__c;

        if (accId == null || conId == null) {
            continue;
        }

        String key = String.valueOf(accId) + '-' + String.valueOf(conId);
        if (!existingPairs.contains(key)) {
            acrsToInsert.add(new AccountContactRelation(
                AccountId = accId,
                ContactId = conId
            ));
        }
    }

    if (!acrsToInsert.isEmpty()) {
        insert acrsToInsert;
    }
}

  public static Map<Id, ER_Solution_Line_Item__c> getAllDeliverySiteLineItems(Set<String> companyIds) {
    return new Map<Id, ER_Solution_Line_Item__c>(
      [
        SELECT Id, Name, ER_Delivery_Site__c, ER_Solution__c, ER_Contract__c, ER_Status__c
        FROM ER_Solution_Line_Item__c
        WHERE
          RecordType.DeveloperName = 'ER_Delivery_Site_Line_Item'
          AND ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c IN :companyIds
      ]
    );
  }

  public static void manageDSLIForNewDeliverySite(Map<Id, ER_Delivery_Site__c> deliverySiteMap) {
    System.debug('manageDSLIForNewDeliverySite START');

    List<ER_Delivery_Site__c> insertedDeliverySites = [
      SELECT id, Name, ER_Financial_Center__r.ER_Account_Name__c
      FROM ER_Delivery_Site__c
      WHERE id IN :deliverySiteMap.keySet()
    ];
    ER_Solution_Line_Item__c dsli;
    Set<ER_Solution_Line_Item__c> allActiveFCLineItems = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> mapFCActiveFCLineItems = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> dsliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> companySet = new Set<String>();

    for (ER_Delivery_Site__c deliverySite : insertedDeliverySites) {
      companySet.add(deliverySite.ER_Financial_Center__r.ER_Account_Name__c);
    }

    Map<Id, ER_Solution_Line_Item__c> allfcliList = APER30_FinancialCenter_Management.getAllFCLineItems(companySet); //get All FC Line Items for a company.

    //Loop to build Map Financial Centers to FC Line Items
    for (ER_Solution_Line_Item__c fcli : allfcliList.values()) {
      allActiveFCLineItems = new Set<ER_Solution_Line_Item__c>();

      if (!mapFCActiveFCLineItems.containsKey(fcli.ER_Financial_Center__c)) {
        allActiveFCLineItems.add(fcli);
        mapFCActiveFCLineItems.put(fcli.ER_Financial_Center__c, allActiveFCLineItems);
      } else {
        allActiveFCLineItems = mapFCActiveFCLineItems.get(fcli.ER_Financial_Center__c);
        allActiveFCLineItems.add(fcli);
        mapFCActiveFCLineItems.put(fcli.ER_Financial_Center__c, allActiveFCLineItems);
      }
    }

    if (!mapFCActiveFCLineItems.isEmpty()) {
      for (ER_Delivery_Site__c deliverySite : insertedDeliverySites) {
        if (mapFCActiveFCLineItems.get(deliverySite.ER_Financial_Center__c) != null) {
          //add the delivery site line items for delivery site
          for (ER_Solution_Line_Item__c fcLineItem : mapFCActiveFCLineItems.get(deliverySite.ER_Financial_Center__c)) {
            dsli = new ER_Solution_Line_Item__c();
            dsli.ER_Solution__c = fcLineItem.ER_Solution__c;
            dsli.ER_Contract__c = fcLineItem.ER_Contract__c;
            dsli.ER_Delivery_Site__c = deliverySite.Id;
            dsli.ER_Parent_Line_Item__c = fcLineItem.Id;
            dsli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
              .get('ER_Delivery_Site_Line_Item')
              .getRecordTypeId();
            dsli.ER_Status__c = fcLineItem.ER_Status__c;
            dsliListToInsert.add(dsli);
          }
        }
      }

      if (!dsliListToInsert.isEmpty()) {
        System.debug('sliList to insert : ' + dsliListToInsert);
        insert dsliListToInsert;
      }
    }

    System.debug('manageDSLIForNewDeliverySite END');
  }

  public static void updatePrimaryContactRole(
    Map<id, ER_Delivery_Site__c> newMap,
    Map<id, ER_Delivery_Site__c> oldMap
  ) {
   /*  Map<id, ER_Delivery_Site__c> dsContactRoleToManage = new Map<id, ER_Delivery_Site__c>();

    for (ER_Delivery_Site__c ds : newMap.values()) {
      if (
        String.isNotBlank(ds.ER_Delivery_Contact__c) &&
        ds.ER_Delivery_Contact__c != oldMap.get(ds.id).ER_Delivery_Contact__c
      ) {
        dsContactRoleToManage.Put(ds.id, ds);
      }
    }

    if (!dsContactRoleToManage.isEmpty()) {
      System.debug('TRIGGER DS UpdatePrimaryContactRole');

      try {
        APER24_ContactRole_Management.UpdatePrimaryContactRole(dsContactRoleToManage, oldMap);
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    } */
  }

  /**
   * @author KHAD
   * @date 01/03/2022
   * @description Update the creation date in ios field for Delivery Site v3
   * @param newItems
   * @param oldItems
   */
  public static void syncDeliverySiteFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### syncDeliverySiteFlags Start');

    Map<Id, ER_Delivery_Site__c> newDeliverySiteMap = (Map<Id, ER_Delivery_Site__c>) newItems;
    Map<Id, ER_Delivery_Site__c> oldStoreMap = (Map<Id, ER_Delivery_Site__c>) oldItems;

    // Loop through the Account lists and add fill the creation date in OS
    for (ER_Delivery_Site__c ds : newDeliverySiteMap.values()) {
      if (
        ds.ER_Sync_result__c != oldStoreMap.get(ds.Id).ER_Sync_result__c &&
        (ds.ER_Sync_result__c == 'synchronized' ||
        ds.ER_Sync_result__c == 'pending_synchronization') &&
        ds.ER_Creation_date_in_OS__c == null
      )
        ds.ER_Creation_date_in_OS__c = Datetime.now();
    }

    System.debug('### syncDeliverySiteFlags End');
  }

  /**
   * @author KHAD
   * @date 01/03/2022
   * @description Sync Delivery Site with EDG v3
   * @param stores
   */
  public static void syncDeliverySite(List<ER_Delivery_Site__c> deliverySites, Map<Id, ER_Delivery_Site__c> oldItems) {
    Set<Id> accounts = new Set<Id>();
    Set<Id> deliverySiteAccounts = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();

    if (!deliverySites.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = deliverySites[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    System.debug('Aper28_ER_SyncStructureWS.alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync);
    if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
      for (ER_Delivery_Site__c ds : deliverySites) {
        if (
          ds.ER_Account_Name__c != null && (ds.ER_Last_date_of_Sync__c == oldItems.get(ds.Id).ER_Last_date_of_Sync__c)
        ) {
          ModifiedElements.add(ds.Id);
          deliverySiteAccounts.add(ds.ER_Account_Name__c);
          accountsInputScope.put(ds.ER_Account_Name__c, 'client');
        }
      }

      for (Account a : [
        SELECT Id, ER_Status__c
        FROM Account
        WHERE Id = :deliverySiteAccounts AND ER_Creation_date_in_OS__c != NULL
      ])
        accounts.add(a.Id);

      //if(!accounts.isEmpty()) ER_SyncStructureWithLegacy.syncContract(accounts, null, 'PUT');
      System.debug('#####KHAD CALLOUT');
      if (!accounts.isEmpty())
        System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', ModifiedElements, accountsInputScope));
    }
  }
}