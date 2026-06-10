/*
----------------------------------------------------------------------
-- - Name          : APER29_DistributionPoint_Management
-- - Author        : KHAD
-- - Description   : Distribution Point Management, This class is used to group all the functionnality linked to the object Distribution Point
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  FEB-2021       KHAD                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public without sharing class APER29_DistributionPoint_Management {
  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageDPLIFromContract(Contract contract) {
    /*if (UtilsBypass.canTrigger('manageDPLIFromContract')) {
      GenericWithoutSharing.manageDPLIFromContract(contract);
    }*/
  }

  public static void manageDPLIForNewDistributionPoint(Map<Id, ER_Distribution_Point__c> dPointMap) {
    /*if (UtilsBypass.canTrigger('manageDPLIForNewDistributionPoint')) {
      System.debug('manageDPLIForNewDistributionPoint START');

      List<ER_Distribution_Point__c> insertedDP = [
        SELECT id, Name, ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c
        FROM ER_Distribution_Point__c
        WHERE id IN :dPointMap.keySet()
      ];
      ER_Solution_Line_Item__c dpli;
      Set<ER_Solution_Line_Item__c> allActiveDSLineItem = new Set<ER_Solution_Line_Item__c>();
      Map<String, Set<ER_Solution_Line_Item__c>> mapDSActiveDSLineItems = new Map<String, Set<ER_Solution_Line_Item__c>>();
      List<ER_Solution_Line_Item__c> dpliListToInsert = new List<ER_Solution_Line_Item__c>();
      Set<String> companySet = new Set<String>();

      for (ER_Distribution_Point__c dPoint : insertedDP) {
        companySet.add(dPoint.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c);
      }

      Map<Id, ER_Solution_Line_Item__c> alldsliList = APER28_DeliverySite_Management.getAllDeliverySiteLineItems(
        companySet
      ); //get All Delivery Site Line Items for a company.

      //Loop to build Map Delivery Site to Delivery Site Line Items
      for (ER_Solution_Line_Item__c dsli : alldsliList.values()) {
        allActiveDSLineItem = new Set<ER_Solution_Line_Item__c>();

        if (!mapDSActiveDSLineItems.containsKey(dsli.ER_Delivery_Site__c)) {
          allActiveDSLineItem.add(dsli);
          mapDSActiveDSLineItems.put(dsli.ER_Delivery_Site__c, allActiveDSLineItem);
        } else {
          allActiveDSLineItem = mapDSActiveDSLineItems.get(dsli.ER_Delivery_Site__c);
          allActiveDSLineItem.add(dsli);
          mapDSActiveDSLineItems.put(dsli.ER_Delivery_Site__c, allActiveDSLineItem);
        }
      }

      if (!mapDSActiveDSLineItems.isEmpty()) {
        for (ER_Distribution_Point__c dPoint : insertedDP) {
          for (ER_Solution_Line_Item__c dSiteLineItem : mapDSActiveDSLineItems.get(dPoint.ER_Delivery_Site__c)) {
            dpli = new ER_Solution_Line_Item__c();
            dpli.ER_Solution__c = dSiteLineItem.ER_Solution__c;
            dpli.ER_Contract__c = dSiteLineItem.ER_Contract__c;
            dpli.ER_Distribution_Point__c = dPoint.Id;
            dpli.ER_Parent_Line_Item__c = dSiteLineItem.Id;
            dpli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
              .get('ER_Distribution_Point_Line_Item')
              .getRecordTypeId();
            dpli.ER_Status__c = dSiteLineItem.ER_Status__c;

            dpliListToInsert.add(dpli);
          }
        }

        if (!dpliListToInsert.isEmpty()) {
          System.debug('dpliList to insert : ' + dpliListToInsert);
          insert dpliListToInsert;
        }
      }

      System.debug('manageDPLIFromContract END');
    }*/
  }
  
  //Method added by harkirat for acr creation
  public static void createAcrForDistributionPoints(
    Map<Id, SObject> newItems,
    Map<Id, SObject> oldItems
) {
    if (newItems == null || newItems.isEmpty()) {
        return;
    }

    // Cast maps
    Map<Id, ER_Distribution_Point__c> newDpMap =
        (Map<Id, ER_Distribution_Point__c>) newItems;
    Map<Id, ER_Distribution_Point__c> oldDpMap =
        (oldItems != null ? (Map<Id, ER_Distribution_Point__c>) oldItems : null);

    List<ER_Distribution_Point__c> dpToProcess = new List<ER_Distribution_Point__c>();
    Set<Id> contactIds = new Set<Id>();
    Set<Id> deliverySiteIds = new Set<Id>();

    // 1) Collect DPs where ER_Contact__c changed / set
    for (ER_Distribution_Point__c dpNew : newDpMap.values()) {
        ER_Distribution_Point__c dpOld =
            (oldDpMap != null ? oldDpMap.get(dpNew.Id) : null);

        Boolean contactChanged =
            (dpOld == null && dpNew.ER_Contact__c != null) ||
            (dpOld != null && dpNew.ER_Contact__c != dpOld.ER_Contact__c);

        if (!contactChanged) {
            continue;
        }

        if (dpNew.ER_Delivery_Site__c != null &&
            dpNew.ER_Contact__c != null) {

            dpToProcess.add(dpNew);
            contactIds.add(dpNew.ER_Contact__c);
            deliverySiteIds.add(dpNew.ER_Delivery_Site__c);
        }
    }

    if (dpToProcess.isEmpty()) {
        return;
    }

    // 2) Get Account via Delivery Site -> Financial Center -> Account
    Map<Id, Id> dsIdToAccountId = new Map<Id, Id>();
    for (ER_Delivery_Site__c ds : [
        SELECT Id,
               ER_Financial_Center__c,
               ER_Financial_Center__r.ER_Account_Name__c
        FROM ER_Delivery_Site__c
        WHERE Id IN :deliverySiteIds
    ]) {
        if (ds.ER_Financial_Center__r != null &&
            ds.ER_Financial_Center__r.ER_Account_Name__c != null) {

            dsIdToAccountId.put(ds.Id, ds.ER_Financial_Center__r.ER_Account_Name__c);
        }
    }

    Set<Id> accountIds = new Set<Id>();
    Set<String> pairKeys = new Set<String>();

    for (ER_Distribution_Point__c dp : dpToProcess) {
        Id accId = dsIdToAccountId.get(dp.ER_Delivery_Site__c);
        Id conId = dp.ER_Contact__c;

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

    // 3) Existing ACRs
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

    // 4) Create missing ACRs
    List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();

    for (ER_Distribution_Point__c dp : dpToProcess) {
        Id accId = dsIdToAccountId.get(dp.ER_Delivery_Site__c);
        Id conId = dp.ER_Contact__c;

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

  public static void updatePrimaryContactRole(
    Map<id, ER_Distribution_Point__c> newMap,
    Map<id, ER_Distribution_Point__c> oldMap
  ) {
    /*if (UtilsBypass.canTrigger('updatePrimaryContactRole')) {
      Map<id, ER_Distribution_Point__c> dpContactRoleToManage = new Map<id, ER_Distribution_Point__c>();

      for (ER_Distribution_Point__c dp : newMap.values()) {
        if (String.isNotBlank(dp.ER_Contact__c) && dp.ER_Contact__c != oldMap.get(dp.id).ER_Contact__c) {
          dpContactRoleToManage.Put(dp.id, dp);
        }
      }

      if (!dpContactRoleToManage.isEmpty()) {
        try {
          APER24_ContactRole_Management.UpdatePrimaryContactRole(dpContactRoleToManage, oldMap);
        } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
        }
      }
    }*/
  }

  /**
   * @author KHAD
   * @date 01/03/2022
   * @description Update the creation date in ios field for Distribution Point v3
   * @param newItems
   * @param oldItems
   */
  public static void syncDistributionPointFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    /*System.debug('### syncDistributionPointFlags Start');

    Map<Id, ER_Distribution_Point__c> newDeliverySiteMap = (Map<Id, ER_Distribution_Point__c>) newItems;
    Map<Id, ER_Distribution_Point__c> oldStoreMap = (Map<Id, ER_Distribution_Point__c>) oldItems;

    // Loop through the Account lists and add fill the creation date in OS
    for (ER_Distribution_Point__c dp : newDeliverySiteMap.values()) {
      if (
        dp.ER_Sync_result__c != oldStoreMap.get(dp.Id).ER_Sync_result__c &&
        (dp.ER_Sync_result__c == 'synchronized' ||
        dp.ER_Sync_result__c == 'pending_synchronization') &&
        dp.ER_Creation_date_in_OS__c == null
      )
        dp.ER_Creation_date_in_OS__c = Datetime.now();
    }

    System.debug('### syncDistributionPointFlags End');*/
  }

  /**
   * @author KHAD
   * @date 01/03/2022
   * @description Sync Distribution Point with EDG v3
   * @param distributionPoints
   * @param oldItems
   */
  public static void syncDistributionPoint(
    List<ER_Distribution_Point__c> distributionPoints,
    Map<Id, ER_Distribution_Point__c> oldItems
  ) {
    /*Set<Id> deliverySites = new Set<Id>();
    Set<Id> accounts = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();

    if (!distributionPoints.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = distributionPoints[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    System.debug('Aper29_ER_SyncStructureWS.alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync);
    if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
      for (ER_Distribution_Point__c dp : distributionPoints) {
        if (
          dp.ER_Delivery_Site__c != null && (dp.ER_Last_date_of_Sync__c == oldItems.get(dp.Id).ER_Last_date_of_Sync__c)
        ) {
          ModifiedElements.add(dp.Id);
          deliverySites.add(dp.ER_Delivery_Site__c);
        }
      }

      for (ER_Delivery_Site__c ds : [
        SELECT Id, ER_Account_Name__c
        FROM ER_Delivery_Site__c
        WHERE Id IN :deliverySites AND ER_Creation_date_in_OS__c != NULL
      ]) {
        accounts.add(ds.ER_Account_Name__c);
        accountsInputScope.put(ds.ER_Account_Name__c, 'client');
      }

      System.debug('#####KHAD CALLOUT');
      if (!accounts.isEmpty())
        System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', ModifiedElements, accountsInputScope));
    }*/
  }
}