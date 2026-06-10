/*
----------------------------------------------------------------------
-- - Name          : APER14_Store_Management
-- - Author        : OLA
-- - Description   : Store Management, This class is used to group all the functionnality linked to the object Store
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Jun-2019       OLA                 1.0         Initial version
--  FEB-2021       KHAD                2.0         Solution at all level
---------------------------------------------------------------------------------------
*/
public class APER14_Store_Management {
  public static Boolean isAPER14Test = false;

  public static void disableStores(List<ER_Store__c> storeList) {
    /*for (ER_Store__c store : storeList) {
      store.ER_Status__c = Label.LABS_SF_Store_Inactive;
      store.ER_Closure_Date__c = Date.today();
      store.ER_Closure_Reason__c = Label.LABS_SF_Store_DoesntAcceptAnySolution;
    }*/
  }

  public static void enableStores(List<ER_Store__c> storeList) {
    /*for (ER_Store__c store : storeList) {
      store.ER_Status__c = Label.LABS_SF_Store_Active;
      store.ER_Closure_Date__c = null;
      store.ER_Closure_Reason__c = '';
      store.ER_Start_date__c = Date.today();
    }*/
  }

  public static void manageStoreStatus(List<ER_Solution_Line_Item__c> storeLiList) {
    /*String limitValue = Utils.getGlobalSettingsValueFromKey('Synchro_Record_Limit');
    Integer recordLimit = (String.isNotBlank(limitValue) ? Integer.valueOf(limitValue) : 100);
    List<ER_Store__c> ActiveStoreList = new List<ER_Store__c>();
    List<ER_Store__c> StoreListToEnable = new List<ER_Store__c>();
    List<ER_Store__c> StoreListToDisable = new List<ER_Store__c>();

    Set<id> StoreList = new Set<id>();
    //Set<id> ActiveStoreList = new Set<id>();
    for (ER_Solution_Line_Item__c strli : storeLiList) {
      system.debug('strli.ER_Store__c : ' + strli.ER_Store__c);
      if (
        !StoreList.contains(strli.ER_Store__c) &&
        (strli.recordtypeid ==
        Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
          .get('ER_Store_Line_Item')
          .getRecordTypeId())
      ) {
        StoreList.add(strli.ER_Store__c);
      }
    }

    if (!StoreList.isEmpty()) {
      for (ER_Store__c store : [
        SELECT
          Id,
          Name,
          ER_Status__c,
          (
            SELECT id, ER_Solution__c, ER_Store__c
            FROM Solution_Line_Items__r
            WHERE
              RecordType.DeveloperName = 'ER_Store_Line_Item'
              AND ER_Status__c = :Label.LAB_SF_SolutionLineItem_Active
          )
        FROM ER_Store__c
        WHERE id IN :StoreList
      ]) {
        system.debug('Store : ' + store.Name);
        system.debug('store.Solution_Line_Items__r..size() : ' + store.Solution_Line_Items__r.size());
        for (ER_Solution_Line_Item__c sli2 : store.Solution_Line_Items__r) {
          if (!ActiveStoreList.contains(store)) {
            ActiveStoreList.add(store);
            system.debug('Store with accepted solution : ' + store.Name);
          }
        }

        if (store.ER_Status__c == 'Active' && !ActiveStoreList.contains(store)) {
          //Stores to disable
          store.ER_Status__c = Label.LABS_SF_Store_Inactive;
          store.ER_Closure_Date__c = Date.today();
          store.ER_Closure_Reason__c = Label.LABS_SF_Store_DoesntAcceptAnySolution;
          StoreListToDisable.add(store);
          system.debug('Store to disable : ' + store.Name);
        }
        if (store.ER_Status__c == 'Inactive' && ActiveStoreList.contains(store)) {
          //Stores to Enable
          store.ER_Status__c = Label.LABS_SF_Store_Active;
          store.ER_Closure_Date__c = null;
          store.ER_Closure_Reason__c = '';
          store.ER_Start_date__c = Date.today();
          StoreListToEnable.add(store);
          system.debug('Store to enable : ' + store.Name);
        }
      }

      if (!StoreListToEnable.isEmpty() && StoreListToEnable.size() <= recordLimit) {
        update StoreListToEnable;
      } else if (StoreListToEnable.size() > recordLimit) {
        System.enqueueJob(new ER_DMLRecordsAsync(null, StoreListToEnable, null, null, null, Constants.UPDATE_DML));
      }
      if (!StoreListToDisable.isEmpty() && StoreListToDisable.size() <= recordLimit) {
        update StoreListToDisable;
      } else if (StoreListToDisable.size() > recordLimit) {
        System.enqueueJob(new ER_DMLRecordsAsync(null, StoreListToDisable, null, null, null, Constants.UPDATE_DML));
      }
    }*/
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param companyId
   */
  public static void manageSLIFromContract(String companyId) {
    /*if (UtilsBypass.canTrigger('manageSLIFromContract')) {
      GenericWithoutSharing.manageSLIFromContract(companyId);
    }*/
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageSLIFromContractNew(Contract contract) {
    /*if (UtilsBypass.canTrigger('manageSLIFromContractNew')) {
      GenericWithoutSharing.manageSLIFromContractNew(contract);
    }*/
  }

  public static Map<Id, ER_Solution_Line_Item__c> getAllStoreLineItems(Set<String> companyIds) {
    return new Map<Id, ER_Solution_Line_Item__c>(
      [
        SELECT Id, Name, ER_Store__c, ER_Solution__c, ER_Contract__c, ER_Status__c
        FROM ER_Solution_Line_Item__c
        WHERE
          RecordType.DeveloperName = 'ER_Store_Line_Item'
          AND ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c IN :companyIds
      ]
    );
  }

  public static void manageSLIForNewStoreNew(Map<Id, ER_Store__c> storeMap) {
    /*System.debug('manageSLIForNewStore START');

    //ER_Financial_Center__r.ER_Account_Name__c is null from trigger ==> need to query to retreive this information.
    List<ER_Store__c> insertedStores = [
      SELECT Id, Name, ER_Financial_Center__c, ER_Financial_Center__r.ER_Account_Name__c, ER_BUPicklist__c
      FROM ER_Store__c
      WHERE Id IN :storeMap.keySet()
    ];
    ER_Solution_Line_Item__c sli;
    Set<ER_Solution_Line_Item__c> allActiveFCLineItems = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> mapFCActiveFCLineItems = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> sliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> companySet = new Set<String>();

    for (ER_Store__c store : insertedStores) {
      if (store.ER_Financial_Center__c != null && store.ER_Financial_Center__r.ER_Account_Name__c != null)
        companySet.add(store.ER_Financial_Center__r.ER_Account_Name__c);
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
      for (ER_Store__c store : insertedStores) {
        if (mapFCActiveFCLineItems.containsKey(store.ER_Financial_Center__c)) {
          //add the store line items for store
          for (ER_Solution_Line_Item__c fcLineItem : mapFCActiveFCLineItems.get(store.ER_Financial_Center__c)) {
            sli = new ER_Solution_Line_Item__c();
            sli.ER_Solution__c = fcLineItem.ER_Solution__c;
            sli.ER_Contract__c = fcLineItem.ER_Contract__c;
            sli.ER_Store__c = store.Id;
            sli.ER_Status__c = fcLineItem.ER_Status__c;
            sli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
              .get('ER_Store_Line_Item')
              .getRecordTypeId();
            sli.ER_Parent_Line_Item__c = fcLineItem.Id;
            sli.ER_BUPicklist__c = store.ER_BUPicklist__c; // AAM 20.01.22 - PBI#14305
            sliListToInsert.add(sli);
          }
        }
      }

      if (!sliListToInsert.isEmpty()) {
        System.debug('sliList to insert : ' + sliListToInsert);
        insert sliListToInsert;
      }
    }

    System.debug('manageSLIForNewStore END');*/
  }

  public static void enableDisableStore(Map<id, ER_Store__c> newStores, Map<id, ER_Store__c> oldStores) {
    /*Boolean CurrentalreadyExecutedStore = false;

    List<ER_Store__c> storeToEnable = new List<ER_Store__c>();
    List<ER_Store__c> storeToDisable = new List<ER_Store__c>();

    System.debug('###:TRER10_ER_StoreBeforeUpdate before update Start');

    for (ER_Store__c store : newStores.values()) {
      if (oldStores.get(store.Id).ER_Solution_Count__c != 0 && store.ER_Solution_Count__c == 0) {
        storeToDisable.add(store);
      } else if (
        oldStores.get(store.Id).ER_Solution_Count__c == 0 &&
        store.ER_Solution_Count__c != 0 &&
        oldStores.get(store.Id).ER_Status__c != 'Active'
      ) {
        storeToEnable.add(store);
      }
    }
    CurrentalreadyExecutedStore = WSCZ01_SynchronizeStoreWS.alreadyExecutedAcceptor;
    WSCZ01_SynchronizeStoreWS.alreadyExecutedAcceptor = true;
    if (!storeToEnable.isEmpty()) {
      System.debug('###:storeToEnable : ' + storeToEnable);
      APER14_Store_Management.enableStores(storeToEnable);
    }

    if (!storeToDisable.isEmpty()) {
      System.debug('###:storeToDisable : ' + storeToDisable);
      APER14_Store_Management.disableStores(storeToDisable);
    }
    WSCZ01_SynchronizeStoreWS.alreadyExecutedAcceptor = CurrentalreadyExecutedStore;
    System.debug('###:TRER10_ER_StoreBeforeUpdate before update End');*/
  }

  public static void handleStoreContactRoleStoreToLoop(
    Map<id, ER_Store__c> newMap,
    Map<id, ER_Store__c> oldMap,
    Boolean afterInsert,
    Boolean afterUpdate
  ) {
    /*if (UtilsBypass.canTrigger('handleStoreContactRoleStoreToLoop')) {
      Set<id> StoreIds = newMap != null ? newMap.keySet() : new Set<Id>();

      List<ER_Store__c> Stores = [
        SELECT
          id,
          ER_Business_Unit__c,
          ER_Financial_Center__r.ER_Creation_date_in_OS__c,
          CreatedDate,
          ER_Creation_Date_In_OS__c
        FROM ER_Store__c
        WHERE id IN :StoreIds
      ];

      Map<id, ER_Store__c> storeContactRoleToManage = new Map<id, ER_Store__c>();
      /*
			if(!WSCZ01_SynchronizeStoreWS.alreadyExecutedAcceptor) {
				for(ER_Store__c store : Stores) {
					if(store.ER_Business_Unit__c == 'CZ' && !System.IsBatch()) {
						system.debug('cond 1 - create :' + (store.ER_Creation_Date_In_OS__c == null && store.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null && store.CreatedDate >= store.ER_Financial_Center__r.ER_Creation_date_in_OS__c));
						system.debug('cond 2 - update:' + (store.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null && (store.CreatedDate < store.ER_Financial_Center__r.ER_Creation_date_in_OS__c || store.ER_Creation_date_in_OS__c != null)));
						if((store.ER_Creation_Date_In_OS__c == null && store.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null && store.CreatedDate >= store.ER_Financial_Center__r.ER_Creation_date_in_OS__c) || (store.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null && (store.CreatedDate < store.ER_Financial_Center__r.ER_Creation_date_in_OS__c || store.ER_Creation_date_in_OS__c != null))) {
							WSCZ01_SynchronizeStoreWS.updateAddStoreFuture(store.Id);
						}

					}
				}
			} 

      if (afterInsert) {
        //// New method to manage Solution line item
        APER14_Store_Management.manageSLIForNewStoreNew(newMap);
      }

      System.debug('###:TRER10_ER_StoreAfterInsert after insert End');

      if (afterInsert) {
        // Create Store to loops related to the new Stores created
        APER21_StoreToLoopManagement.CreatenewStoreToLoopOnStoreInsert(Trigger.new);
      }

      //OLA Update 090402020
      //Contact Role Management on Insert + Update
      //
      if (afterInsert) {
        try {
          APER24_ContactRole_Management.CreatePrimaryContactRole(Trigger.new);
        } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
        }
      }
      if (afterUpdate) {
        for (ER_Store__c store : newMap.values()) {
          if (String.isNotBlank(store.ER_Contact__c) && store.ER_Contact__c != oldMap.get(store.id).ER_Contact__c) {
            storeContactRoleToManage.Put(store.id, store);
          }
        }
      }

      if (!storeContactRoleToManage.isEmpty()) {
        System.debug('TRIGGER STORE UpdatePrimaryContactRole');
        try {
          APER24_ContactRole_Management.UpdatePrimaryContactRole(storeContactRoleToManage, oldMap);
        } catch (DMLException ex) {
          throw new DMLException(ex.getMessage());
        } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
        }
      }
    }*/
  }

  public static void checkDigitalStoreStatusChange(Map<Id, ER_Store__c> newMap, Map<Id, ER_Store__c> oldMap) {
   /* Map<Id, Boolean> mapUnsyncedAcceptors = new Map<Id, Boolean>();
    User currentUser = UtilsBypass.getCurrentUser();
    Id recordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_Acceptor__c.SObjectType, 'Edenred_POS');
    for (ER_Acceptor__c a : [
      SELECT Id, ER_Sync_result__c, ER_Store__c, ER_Creation_date_in_OS__c
      FROM ER_Acceptor__c
      WHERE RecordTypeId = :recordTypeId AND ER_Store__c IN :newMap.keySet()
    ]) {
      if (a.ER_Creation_date_in_OS__c == null)
        mapUnsyncedAcceptors.put(a.ER_Store__c, true);
    }
    System.debug('mapUnsyncedAcceptors: ' + mapUnsyncedAcceptors);
    if (!mapUnsyncedAcceptors.isEmpty()) {
      for (ER_Store__c s : newMap.values()) {
        if (
          !currentUser.ER_BypassVR__c &&
          mapUnsyncedAcceptors.containsKey(s.Id) &&
          s.ER_Digital_Store__c &&
          s.ER_Digital_Store_Status__c != oldMap.get(s.Id).ER_Digital_Store_Status__c &&
          oldMap.get(s.Id).ER_Digital_Store_Status__c == 'Created'
        )
          s.addError(Label.LAB_SF_Store_Digital_Store_Status);
      }
    }*/
  }

  /**
   * @author VJOY
   * @date 06/05/2021
   * @description Control store creation on Payment Financial Centers
   * @param aStoreList
   */
  public static void manageStoreWithPaymentSites(List<ER_Store__c> aStoreList) {
    /*if (UtilsBypass.canTrigger('manageStoreWithPaymentSites')) {
      Map<Id, List<ER_Store__c>> mapFCStore = new Map<Id, List<ER_Store__c>>();
      Map<Id, ER_Financial_Center__c> mapStoreFC = new Map<Id, ER_Financial_Center__c>();

      for (ER_Store__c store : aStoreList) {
        if (!mapFCStore.containsKey(store.ER_Financial_Center__c))
          mapFCStore.put(store.ER_Financial_Center__c, new List<ER_Store__c>());
        mapFCStore.get(store.ER_Financial_Center__c).add(store);
      }

      for (ER_Financial_Center__c fc : [
        SELECT Id, ER_Payment_Site__c
        FROM ER_Financial_Center__c
        WHERE Id IN :mapFCStore.keySet() AND ER_Business_Unit__c = 'ES'
      ]) {
        for (ER_Store__c s : mapFCStore.get(fc.Id)) {
          mapStoreFC.put(s.Id, fc);
        }
      }

      for (ER_Store__c store : [
        SELECT
          Id,
          ER_Financial_Center__c,
          ER_Invoicing_site__c,
          ER_Payment_site__c,
          ER_Financial_Center__r.ER_Payment_Site__c
        FROM ER_Store__c
        WHERE
          ER_Financial_Center__c IN :mapFCStore.keySet()
          AND ER_Financial_Center__r.ER_Type__c = 'Merchant'
          AND ER_Business_Unit__c = 'ES'
      ]) {
        mapFCStore.get(store.ER_Financial_Center__c).add(store);
      }

      for (ER_Store__c store : aStoreList) {
        if (
          !UtilsBypass.getCurrentUser().ER_BypassVR__c &&
          store.ER_Business_Unit__c == 'ES' &&
          mapStoreFC.containsKey(store.Id) &&
          mapStoreFC.get(store.Id).ER_Payment_Site__c &&
          mapFCStore.get(store.ER_Financial_Center__c).size() > 1
        )
          store.addError(Label.LAB_SF_Store_PaymentSiteError);
      }
    }*/
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Sync stores with EDG v3
   * @param stores
   * @param oldItems
   */
  public static void syncStores(List<ER_Store__c> stores, Map<Id, ER_Store__c> oldItems) {
    /*Set<Id> financialCenters = new Set<Id>();
    Set<Id> accounts = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();
    Map<Id, String> accountInputScope = new Map<Id, String>();

    if (!stores.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = stores[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    System.debug('Aper14_ER_SyncStructureWS.alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync);
    if (
      (!Test.isRunningTest() || APER14_Store_Management.isAPER14Test) &&
      !isOfflineBU &&
      !ER_SyncStructureWS.alreadyExecutedSync
    ) {
      for (ER_Store__c s : stores) {
        if (
          s.ER_Financial_Center__c != null && (s.ER_Last_Date_Of_Sync__c == oldItems.get(s.Id).ER_Last_Date_Of_Sync__c)
        ) {
          ModifiedElements.add(s.Id);
          financialCenters.add(s.ER_Financial_Center__c);
        }
      }

      for (ER_Financial_Center__c fc : [
        SELECT Id, ER_Account_Name__c
        FROM ER_Financial_Center__c
        WHERE Id IN :financialCenters AND ER_Creation_date_in_OS__c != NULL
      ]) {
        accounts.add(fc.ER_Account_Name__c);
        accountInputScope.put(fc.ER_Account_Name__c, 'merchant');
      }

      //if(!accounts.isEmpty()) ER_SyncStructureWithLegacy.syncContract(accounts, null, 'PUT');
      system.debug('#####KHAD CALLOUT');
      if (!accounts.isEmpty())
        System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', ModifiedElements, accountInputScope));
    }*/
  }

  /**
   * @author KHAD
   * @date 08/06/2021
   * @description Update the creation date in ios field for Store v3
   * @param newItems
   * @param oldItems
   */
  public static void syncStoreFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    /*System.debug('### syncStoreFlags Start');

    Map<Id, ER_Store__c> newStoreMap = (Map<Id, ER_Store__c>) newItems;
    Map<Id, ER_Store__c> oldStoreMap = (Map<Id, ER_Store__c>) oldItems;

    // Loop through the Account lists and add fill the creation date in OS
    for (ER_Store__c str : newStoreMap.values()) {
      if (
        str.ER_Sync_result__c != oldStoreMap.get(str.Id).ER_Sync_result__c &&
        (str.ER_Sync_result__c == 'synchronized' ||
        str.ER_Sync_result__c == 'pending_synchronization') &&
        str.ER_Creation_Date_In_OS__c == null
      )
        str.ER_Creation_Date_In_OS__c = Datetime.now();
    }*/

    System.debug('### syncStoreFlags End');
  }

  /**
   * @author KHAD
   * @date 08/06/2021
   * @description Update the creation date in ios field for the solution line Items(account,fc,store,acceptor...) v3
   * @param newItems
   * @param oldItems
   */
  public static void syncSLIFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    /*System.debug('### syncSLIFlags Start');

    Map<Id, ER_Solution_Line_Item__c> newSolutionLineItemMap = (Map<Id, ER_Solution_Line_Item__c>) newItems;
    Map<Id, ER_Solution_Line_Item__c> oldSolutionLineItemMap = (Map<Id, ER_Solution_Line_Item__c>) oldItems;

    // Loop through the Account lists and add fill the creation date in OS
    for (ER_Solution_Line_Item__c sli : newSolutionLineItemMap.values()) {
      if (
        sli.ER_Sync_result__c != oldSolutionLineItemMap.get(sli.Id).ER_Sync_result__c &&
        (sli.ER_Sync_result__c == 'synchronized' ||
        sli.ER_Sync_result__c == 'pending_synchronization') &&
        sli.ER_Creation_date_in_OS__c == null
      )
        sli.ER_Creation_date_in_OS__c = Datetime.now();
    }

    System.debug('### syncSLIFlags End');*/
  }

  /**
   * @author ELAK
   * @date 03/11/2021
   * @param newItems
   * @param oldItems
   */
  public static void updateSLIStatus(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    /*System.debug('### updateSLIStatus Start');
    Set<Id> SliIds = new Set<Id>();
    Map<Id, ER_Solution_Line_Item__c> newSolutionLineItemMap = (Map<Id, ER_Solution_Line_Item__c>) newItems;
    Map<Id, ER_Solution_Line_Item__c> oldSolutionLineItemMap = (Map<Id, ER_Solution_Line_Item__c>) oldItems;

    for (ER_Solution_Line_Item__c SLI : newSolutionLineItemMap.values()) {
      if (SLI.ER_Status__c != oldSolutionLineItemMap.get(SLI.id).ER_Status__c) {
        system.debug('SLI : ' + SLI);
        if (SLI.ER_Status_Modified_from_Parent__c == true) {
          SLI.ER_Status_Modified_from_Parent__c = false;
        } else {
          SLI.ER_Status_Manually_Modified__c = true;
        }
      }
    }
    System.debug('### updateSLIStatus End');*/
  }

  /**
   * @author ELAK
   * @date 03/11/2021
   * @param newItems
   * @param oldItems
   */
  public static void manageChildSLI(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    /*System.debug('### manageChildSLI Start');
    List<ER_Solution_Line_Item__c> childSLIToUpdate = new List<ER_Solution_Line_Item__c>();
    Map<Id, ER_Solution_Line_Item__c> newSolutionLineItemMap = (Map<Id, ER_Solution_Line_Item__c>) newItems;
    Map<Id, ER_Solution_Line_Item__c> oldSolutionLineItemMap = (Map<Id, ER_Solution_Line_Item__c>) oldItems;
    Set<Id> SliIds = new Set<Id>();

    for (ER_Solution_Line_Item__c SLI : newSolutionLineItemMap.values()) {
      if (SLI.ER_Status__c != oldSolutionLineItemMap.get(SLI.id).ER_Status__c) {
        system.debug('SLI : ' + SLI);
        SliIds.add(SLI.Id);
      }
    }
    for (List<ER_Solution_Line_Item__c> ChildSLIList : [
      SELECT id, ER_Status__c, ER_Parent_Line_Item__r.ER_Status__c
      FROM ER_Solution_Line_Item__c
      WHERE ER_Status_Manually_Modified__c = FALSE AND ER_Parent_Line_Item__c IN :SliIds
    ]) {
      for (ER_Solution_Line_Item__c ChildSLI : ChildSLIList) {
        if (ChildSLI.ER_Status__c != ChildSLI.ER_Parent_Line_Item__r.ER_Status__c) {
          ChildSLI.ER_Status__c = ChildSLI.ER_Parent_Line_Item__r.ER_Status__c;
          ChildSLI.ER_Status_Modified_from_Parent__c = true;
          childSLIToUpdate.add(ChildSLI);
        }
      }
    }
    if (!childSLIToUpdate.isEmpty()) {
      update childSLIToUpdate;
    }
    System.debug('### manageChildSLI End');*/
  }

  /**
   * @author KHAD
   * @date 09/06/2021
   * @description check if the parent object of the line item is eligible to be synced on the line item after insert
   * @param sliList
   */
  public static void manageSliSync(List<ER_Solution_Line_Item__c> sliList) {
    /*System.debug('###### KHAD  manageSliSync Start');

    if (!sliList.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = sliList[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    if (
      (!Test.isRunningTest() || APER14_Store_Management.isAPER14Test) &&
      !isOfflineBU &&
      !ER_SyncStructureWS.alreadyExecutedSync
    ) {
      Set<Id> accountToSync = new Set<Id>();
      Set<Id> parentAccountList = new Set<Id>();
      Set<Id> parentFinancialCenterList = new Set<Id>();
      Set<Id> parentStoreList = new Set<Id>();
      Set<Id> parentDeliverySiteList = new Set<Id>();
      Set<Id> financialCenterList = new Set<Id>();
      Set<Id> storeList = new Set<Id>();
      Set<Id> acceptorList = new Set<Id>();
      Set<Id> deliverySiteList = new Set<Id>();
      Set<Id> distributionPointList = new Set<Id>();
      Set<Id> ModifiedElements = new Set<Id>();
      Map<Id, ER_Solution_Line_Item__c> newSliMap = new Map<Id, ER_Solution_Line_Item__c>(sliList);
      SET<ID> keys = newSliMap.keySet();
      Map<Id, String> accountsInputScope = new Map<Id, String>();
      List<ER_Solution_Line_Item__c> newSliList = [
        SELECT
          Id,
          RecordType.DeveloperName,
          ER_Account__c,
          ER_Financial_Center__c,
          ER_Financial_Center__r.ER_Type__c,
          ER_Parent_Line_Item__r.ER_Scope__c,
          ER_Store__c,
          ER_Acceptor__c,
          ER_Parent_Line_Item__c,
          ER_Parent_Line_Item__r.ER_Store__c,
          ER_Parent_Line_Item__r.ER_Creation_date_in_OS__c,
          ER_Parent_Line_Item__r.ER_Financial_Center__c,
          ER_Parent_Line_Item__r.ER_Account__c,
          ER_Parent_Line_Item__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c,
          ER_Parent_Line_Item__r.ER_Store__r.ER_Creation_Date_In_OS__c,
          ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c,
          ER_Parent_Line_Item__r.ER_Account__r.ER_Creation_date_in_OS__c,
          ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Account_Name__c,
          ER_Parent_Line_Item__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c,
          ER_Delivery_Site__c,
          ER_Distribution_Point__c,
          ER_Parent_Line_Item__r.ER_Delivery_Site__c,
          ER_Parent_Line_Item__r.ER_Delivery_Site__r.ER_Creation_date_in_OS__c
        FROM ER_Solution_Line_Item__c
        WHERE Id IN :newSliMap.keySet()
      ];
      for (ER_Solution_Line_Item__c sli : newSliList) {
        ModifiedElements.add(sli.Id);
        if (
          sli.ER_Financial_Center__c != null &&
          sli.ER_Financial_Center__r.ER_Type__c == sli.ER_Parent_Line_Item__r.ER_Scope__c &&
          sli.ER_Parent_Line_Item__r.ER_Creation_date_in_OS__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Financial_Center_Line_Item')
            .getRecordTypeId())
        ) {
          parentAccountList.add(sli.ER_Parent_Line_Item__r.ER_Account__c);
          financialCenterList.add(sli.ER_Financial_Center__c);
        }

        if (
          sli.ER_Store__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Store_Line_Item')
            .getRecordTypeId())
        ) {
          parentFinancialCenterList.add(sli.ER_Parent_Line_Item__r.ER_Financial_Center__c);
          storeList.add(sli.ER_Store__c);
        }

        if (
          sli.ER_Acceptor__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Acceptor_Line_Item')
            .getRecordTypeId())
        ) {
          parentStoreList.add(sli.ER_Parent_Line_Item__r.ER_Store__c);
          acceptorList.add(sli.ER_Acceptor__c);
        }

        if (
          sli.ER_Delivery_Site__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Delivery_Site_Line_Item')
            .getRecordTypeId())
        ) {
          parentFinancialCenterList.add(sli.ER_Parent_Line_Item__r.ER_Financial_Center__c);
          deliverySiteList.add(sli.ER_Delivery_Site__c);
        }

        if (
          sli.ER_Distribution_Point__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Distribution_Point_Line_Item')
            .getRecordTypeId())
        ) {
          parentDeliverySiteList.add(sli.ER_Parent_Line_Item__r.ER_Delivery_Site__c);
          distributionPointList.add(sli.ER_Distribution_Point__c);
        }
      }
      System.debug('####### parentAccountList : ' + parentAccountList);
      System.debug('####### financialCenterList : ' + financialCenterList);
      System.debug('####### parentFinancialCenterList : ' + parentFinancialCenterList);
      System.debug('####### storeList : ' + storeList);
      System.debug('####### parentStoreList : ' + parentStoreList);
      System.debug('####### acceptorList : ' + acceptorList);
      System.debug('####### deliverySiteList : ' + deliverySiteList);
      System.debug('####### parentDeliverySiteList : ' + parentDeliverySiteList);
      System.debug('####### distributionPointList : ' + distributionPointList);

      String soql = 'SELECT ID, RecordType.DeveloperName, ER_Account__c, ER_Financial_Center__c, ER_Store__c, ER_Acceptor__c, ER_Delivery_Site__c, ER_Distribution_Point__c  FROM ER_Solution_Line_Item__c WHERE Id IN :keys';
      // Get all the Parent Object Line Item of the current object line item
      if (!parentAccountList.isEmpty())
        soql =
          soql + ' OR (ER_Account__c IN :parentAccountList AND RecordType.DeveloperName = \'ER_Account_Line_Item\')';
      if (!parentFinancialCenterList.isEmpty())
        soql =
          soql +
          ' OR (ER_Financial_Center__c IN :parentFinancialCenterList AND RecordType.DeveloperName = \'ER_Financial_Center_Line_Item\' )';
      if (!financialCenterList.isEmpty())
        soql =
          soql +
          ' OR (ER_Financial_Center__c IN :financialCenterList AND RecordType.DeveloperName = \'ER_Financial_Center_Line_Item\' )';
      if (!parentStoreList.isEmpty())
        soql = soql + ' OR (ER_Store__c IN :parentStoreList AND RecordType.DeveloperName = \'ER_Store_Line_Item\') ';
      if (!storeList.isEmpty())
        soql = soql + ' OR (ER_Store__c IN :storeList AND RecordType.DeveloperName = \'ER_Store_Line_Item\') ';
      if (!acceptorList.isEmpty())
        soql = soql + ' OR (ER_Acceptor__c IN :acceptorList AND RecordType.DeveloperName = \'ER_Acceptor_Line_Item\') ';
      if (!deliverySiteList.isEmpty())
        soql =
          soql +
          ' OR (ER_Delivery_Site__c IN :deliverySiteList AND RecordType.DeveloperName = \'ER_Delivery_Site_Line_Item\') ';
      if (!parentDeliverySiteList.isEmpty())
        soql =
          soql +
          ' OR (ER_Delivery_Site__c IN :parentDeliverySiteList AND RecordType.DeveloperName = \'ER_Delivery_Site_Line_Item\') ';
      if (!distributionPointList.isEmpty())
        soql =
          soql +
          ' OR (ER_Distribution_Point__c IN :distributionPointList AND RecordType.DeveloperName = \'ER_Distribution_Point_Line_Item\') ';
      //Map-List of all the objects line items and their parent's line item

      Map<Id, List<ER_Solution_Line_Item__c>> mapObjectsSli = new Map<Id, List<ER_Solution_Line_Item__c>>();
      System.debug('###" KHAD QUERY : ' + soql);
      for (ER_Solution_Line_Item__c sli : Database.query(soql)) {
        //for(ER_Solution_Line_Item__c sli : [SELECT ID,RecordType.DeveloperName,ER_Account__c,ER_Financial_Center__c,ER_Store__c,ER_Acceptor__c FROM ER_Solution_Line_Item__c WHERE Id IN :newSliMap.keySet()]) {

        //Account Line Item
        if (sli.RecordType.DeveloperName == 'ER_Account_Line_Item' && sli.ER_Account__c != null) {
          if (!mapObjectsSli.containsKey(sli.ER_Account__c))
            mapObjectsSli.put(sli.ER_Account__c, new List<ER_Solution_Line_Item__c>());
          mapObjectsSli.get(sli.ER_Account__c).add(sli);
        }
        //Financial Center Line Item
        if (sli.RecordType.DeveloperName == 'ER_Financial_Center_Line_Item' && sli.ER_Financial_Center__c != null) {
          if (!mapObjectsSli.containsKey(sli.ER_Financial_Center__c))
            mapObjectsSli.put(sli.ER_Financial_Center__c, new List<ER_Solution_Line_Item__c>());
          mapObjectsSli.get(sli.ER_Financial_Center__c).add(sli);
        }
        //Store Line Item
        if (sli.RecordType.DeveloperName == 'ER_Store_Line_Item' && sli.ER_Store__c != null) {
          if (!mapObjectsSli.containsKey(sli.ER_Store__c))
            mapObjectsSli.put(sli.ER_Store__c, new List<ER_Solution_Line_Item__c>());
          mapObjectsSli.get(sli.ER_Store__c).add(sli);
        }
        //Acceptor Line Item
        if (sli.RecordType.DeveloperName == 'ER_Acceptor_Line_Item' && sli.ER_Acceptor__c != null) {
          if (!mapObjectsSli.containsKey(sli.ER_Acceptor__c))
            mapObjectsSli.put(sli.ER_Acceptor__c, new List<ER_Solution_Line_Item__c>());
          mapObjectsSli.get(sli.ER_Acceptor__c).add(sli);
        }
        //Delivery Site
        if (sli.RecordType.DeveloperName == 'ER_Delivery_Site_Line_Item' && sli.ER_Delivery_Site__c != null) {
          if (!mapObjectsSli.containsKey(sli.ER_Delivery_Site__c))
            mapObjectsSli.put(sli.ER_Delivery_Site__c, new List<ER_Solution_Line_Item__c>());
          mapObjectsSli.get(sli.ER_Delivery_Site__c).add(sli);
        }
        //Distribution Point
        if (sli.RecordType.DeveloperName == 'ER_Distribution_Point_Line_Item' && sli.ER_Distribution_Point__c != null) {
          if (!mapObjectsSli.containsKey(sli.ER_Distribution_Point__c))
            mapObjectsSli.put(sli.ER_Distribution_Point__c, new List<ER_Solution_Line_Item__c>());
          mapObjectsSli.get(sli.ER_Distribution_Point__c).add(sli);
        }
      }

      for (ER_Solution_Line_Item__c sli : newSliList) {
        //Financial Center Line Item
        if (
          sli.ER_Financial_Center__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Financial_Center_Line_Item')
            .getRecordTypeId()) &&
          mapObjectsSli?.get(sli.ER_Financial_Center__c)?.size() ==
          mapObjectsSli.get(sli?.ER_Parent_Line_Item__r?.ER_Account__c)?.size() &&
          sli.ER_Parent_Line_Item__r?.ER_Account__r?.ER_Creation_date_in_OS__c != null
        ) {
          //fc to be synced
          accountToSync.add(sli.ER_Parent_Line_Item__r.ER_Account__c);
          accountsInputScope.put(
            sli.ER_Parent_Line_Item__r.ER_Account__c,
            sli.ER_Financial_Center__r.ER_Type__c.toLowerCase()
          ); //add financial center type !
        }
        //Store Line Item
        if (
          sli.ER_Store__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Store_Line_Item')
            .getRecordTypeId()) &&
          mapObjectsSli.get(sli.ER_Store__c)?.size() ==
          mapObjectsSli.get(sli.ER_Parent_Line_Item__r.ER_Financial_Center__c)?.size() &&
          sli.ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null
        ) {
          // Store to be synced
          accountToSync.add(sli.ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(sli.ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Account_Name__c, 'merchant');
        }
        //Acceptor Line Item
        if (
          sli.ER_Acceptor__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Acceptor_Line_Item')
            .getRecordTypeId()) &&
          mapObjectsSli.get(sli.ER_Acceptor__c)?.size() ==
          mapObjectsSli.get(sli.ER_Parent_Line_Item__r.ER_Store__c)?.size() &&
          sli.ER_Parent_Line_Item__r.ER_Store__r.ER_Creation_Date_In_OS__c != null
        ) {
          //Acceptor to be synced
          accountToSync.add(sli.ER_Parent_Line_Item__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(
            sli.ER_Parent_Line_Item__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c,
            'merchant'
          );
        }

        //Delivery Site
        if (
          sli.ER_Delivery_Site__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Delivery_Site_Line_Item')
            .getRecordTypeId()) &&
          mapObjectsSli.get(sli.ER_Delivery_Site__c)?.size() ==
          mapObjectsSli.get(sli.ER_Parent_Line_Item__r.ER_Financial_Center__c)?.size() &&
          sli.ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null
        ) {
          // Delivery Site to be synced
          accountToSync.add(sli.ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(sli.ER_Parent_Line_Item__r.ER_Financial_Center__r.ER_Account_Name__c, 'client');
        }

        //Distribution Point
        if (
          sli.ER_Distribution_Point__c != null &&
          (sli.RecordTypeId ==
          Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Distribution_Point_Line_Item')
            .getRecordTypeId()) &&
          mapObjectsSli.get(sli.ER_Distribution_Point__c)?.size() ==
          mapObjectsSli.get(sli.ER_Parent_Line_Item__r.ER_Delivery_Site__c)?.size() &&
          sli.ER_Parent_Line_Item__r.ER_Delivery_Site__r.ER_Creation_date_in_OS__c != null
        ) {
          //Distribution Point to be synced
          accountToSync.add(sli.ER_Parent_Line_Item__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(
            sli.ER_Parent_Line_Item__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c,
            'client'
          );
        }
      }

      if (!accountToSync.isEmpty()) {
        System.enqueueJob(new ER_SyncStructureWS(accountToSync, null, 'PUT', ModifiedElements, accountsInputScope));
      }
    }*/
  }

  /**
   * @author KHAD
   * @date 14/06/2021
   * @description sync update line items V3
   * @param sliToSync
   * @param oldItems
   */
  public static void syncUpdateLineItems(
    List<ER_Solution_Line_Item__c> sliToSync,
    Map<Id, ER_Solution_Line_Item__c> oldItems
  ) {
    /*System.debug('### syncUpdateLineItems Start ');

    Set<Id> accountToSync = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();

    if (!sliToSync.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = sliToSync[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    System.debug(
      'Aper14_SLI_update_ER_SyncStructureWS.alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync
    );
    if (
      (!Test.isRunningTest() || APER14_Store_Management.isAPER14Test) &&
      !isOfflineBU &&
      !ER_SyncStructureWS.alreadyExecutedSync
    ) {
      for (ER_Solution_Line_Item__c sli : [
        SELECT
          Id,
          ER_Account__c,
          ER_Account__r.ER_Creation_date_in_OS__c,
          ER_Financial_Center__c,
          ER_Financial_Center__r.ER_Creation_date_in_OS__c,
          ER_Last_date_of_Sync__c,
          ER_Delivery_Site__c,
          ER_Delivery_Site__r.ER_Creation_date_in_OS__c,
          ER_Financial_Center__r.ER_Account_Name__c,
          ER_Financial_Center__r.ER_Type__c,
          ER_Store__c,
          ER_Store__r.ER_Creation_Date_In_OS__c,
          ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c,
          ER_Distribution_Point__c,
          ER_Distribution_Point__r.ER_Creation_date_in_OS__c,
          ER_Acceptor__c,
          ER_Acceptor__r.ER_Creation_date_in_OS__c,
          ER_Acceptor__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c,
          RecordType.DeveloperName,
          ER_Contract__r.Status,
          ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c,
          ER_Distribution_Point__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c
        FROM ER_Solution_Line_Item__c
        WHERE Id IN :sliToSync
      ]) {
        ModifiedElements.add(sli.Id);
        //Financial Center Line Item
        if (
          sli.RecordType.DeveloperName == 'ER_Financial_Center_Line_Item' &&
          sli.ER_Financial_Center__c != null &&
          sli.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null &&
          sli.ER_Contract__r.Status == Label.LABS_SF_Contract_Status_Activated &&
          (sli.ER_Last_date_of_Sync__c == oldItems.get(sli.Id).ER_Last_date_of_Sync__c)
        ) {
          accountToSync.add(sli.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(
            sli.ER_Financial_Center__r.ER_Account_Name__c,
            sli.ER_Financial_Center__r.ER_Type__c.toLowerCase()
          );
        }
        //Store Line Item
        if (
          sli.RecordType.DeveloperName == 'ER_Store_Line_Item' &&
          sli.ER_Store__c != null &&
          sli.ER_Store__r.ER_Creation_Date_In_OS__c != null &&
          sli.ER_Contract__r.Status == Label.LABS_SF_Contract_Status_Activated &&
          (sli.ER_Last_date_of_Sync__c == oldItems.get(sli.Id).ER_Last_date_of_Sync__c)
        ) {
          accountToSync.add(sli.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(sli.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c, 'merchant');
        }
        //Acceptor Line Item
        if (
          sli.RecordType.DeveloperName == 'ER_Acceptor_Line_Item' &&
          sli.ER_Acceptor__c != null &&
          sli.ER_Acceptor__r.ER_Creation_date_in_OS__c != null &&
          sli.ER_Contract__r.Status == Label.LABS_SF_Contract_Status_Activated &&
          (sli.ER_Last_date_of_Sync__c == oldItems.get(sli.Id).ER_Last_date_of_Sync__c)
        ) {
          accountToSync.add(sli.ER_Acceptor__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(sli.ER_Acceptor__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c, 'merchant');
        }
        // Delivery Site
        if (
          sli.RecordType.DeveloperName == 'ER_Delivery_Site_Line_Item' &&
          sli.ER_Delivery_Site__c != null &&
          sli.ER_Delivery_Site__r.ER_Creation_date_in_OS__c != null &&
          sli.ER_Contract__r.Status == Label.LABS_SF_Contract_Status_Activated &&
          (sli.ER_Last_date_of_Sync__c == oldItems.get(sli.Id).ER_Last_date_of_Sync__c)
        ) {
          accountToSync.add(sli.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(sli.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c, 'client');
        }
        //Distribution Point
        if (
          sli.RecordType.DeveloperName == 'ER_Distribution_Point_Line_Item' &&
          sli.ER_Distribution_Point__c != null &&
          sli.ER_Distribution_Point__r.ER_Creation_date_in_OS__c != null &&
          sli.ER_Contract__r.Status == Label.LABS_SF_Contract_Status_Activated &&
          (sli.ER_Last_date_of_Sync__c == oldItems.get(sli.Id).ER_Last_date_of_Sync__c)
        ) {
          accountToSync.add(sli.ER_Distribution_Point__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(
            sli.ER_Distribution_Point__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c,
            'client'
          );
        }
      }

      if (!accountToSync.isEmpty()) {
        System.enqueueJob(new ER_SyncStructureWS(accountToSync, null, 'PUT', ModifiedElements, accountsInputScope));
      }

      System.debug('### syncUpdateLineItems End');
    }*/
  }

  /**
   * @author KHAD
   * @date 02/07/2021
   * @description Update the creation date in ios field for the store category edg V3
   * @param newItems
   * @param oldItems
   */
  public static void syncStoreCategoryFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    /*if (UtilsBypass.canTrigger('syncStoreCategoryFlags')) {
      System.debug('### syncStoreCategoryFlags Start');

      Map<Id, ER_StoreCategory__c> newStoreCategory = (Map<Id, ER_StoreCategory__c>) newItems;
      Map<Id, ER_StoreCategory__c> oldStoreCategory = (Map<Id, ER_StoreCategory__c>) oldItems;

      // Loop through the Account lists and add fill the creation date in OS
      for (ER_StoreCategory__c scat : newStoreCategory.values()) {
        if (
          scat.ER_Sync_result__c != oldStoreCategory.get(scat.Id).ER_Sync_result__c &&
          (scat.ER_Sync_result__c == 'synchronized' ||
          scat.ER_Sync_result__c == 'pending_synchronization') &&
          scat.ER_Creation_date_in_OS__c == null
        )
          scat.ER_Creation_date_in_OS__c = Datetime.now();
      }

      System.debug('### syncStoreCategoryFlags End');
    }*/
  }

  /**
   * @author KHAD
   * @date 02/07/2021
   * @description Sync Store Category to EDG v3
   * @param storeCategories
   * @param oldStoreCategory
   */
  public static void syncStoreCategory(
    List<ER_StoreCategory__c> storeCategories,
    Map<Id, ER_StoreCategory__c> oldStoreCategory
  ) {
    /*Set<Id> stores = new Set<Id>();
    Set<Id> accounts = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();

    if (!storeCategories.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = storeCategories[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScope = new Map<Id, String>();

    System.debug(
      'Aper14_store_management ER_SyncStructureWS.alreadyExecutedSync :' + ER_SyncStructureWS.alreadyExecutedSync
    );
    if (
      (!Test.isRunningTest() || APER14_Store_Management.isAPER14Test) &&
      !isOfflineBU &&
      !ER_SyncStructureWS.alreadyExecutedSync
    ) {
      for (ER_StoreCategory__c scat : storeCategories) {
        if (
          (oldStoreCategory == null || oldStoreCategory.isEmpty()) ||
          (oldStoreCategory != null &&
          (scat.ER_Last_date_of_Sync__c == oldStoreCategory.get(scat.Id).ER_Last_date_of_Sync__c))
        ) {
          ModifiedElements.add(scat.Id);
          stores.add(scat.Store__c);
        }
      }

      for (ER_Store__c str : [
        SELECT Id, ER_Financial_Center__r.ER_Account_Name__c
        FROM ER_Store__c
        WHERE Id IN :stores AND ER_Creation_Date_In_OS__c != NULL
      ]) {
        accounts.add(str.ER_Financial_Center__r.ER_Account_Name__c);
        accountsInputScope.put(str.ER_Financial_Center__r.ER_Account_Name__c, 'merchant');
      }

      if (!accounts.isEmpty())
        System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', ModifiedElements, accountsInputScope));
    }*/
  }

  /**
   * @author AAZ
   * @date 01/03/2022
   * @description Create Docugen records to be used for the contract template
   * @param stores
   */
  public static void createDocugenQuoteStoreAcceptor(List<ER_Store__c> stores) {
    /*Map<Id, ER_Store__c> mapStores = new Map<Id, ER_Store__c>(stores);
    Map<Id, Id> mapStoreAccount = new Map<Id, Id>();
    List<ER_Docugen_Quote_Store_Acceptor__c> docugenQuoteStoreAcceptors = new List<ER_Docugen_Quote_Store_Acceptor__c>();
    List<String> docusignDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.DOCUSIGN_DEPLOYED_BUS)
      ?.split(Constants.SEMICOLON);

    for (ER_Store__c s : [
      SELECT Id, ER_Financial_Center__r.ER_Account_Name__c, ER_BUPicklist__c
      FROM ER_Store__c
      WHERE Id IN :mapStores.keySet() AND RecordType.DeveloperName = :Constants.STORE_MERCHANT_RT
    ]) {
      if (
        docusignDeployedBUs != null &&
        (docusignDeployedBUs.contains(s.ER_BUPicklist__c) || docusignDeployedBUs.contains(Constants.ALL))
      )
        mapStoreAccount.put(s.Id, s.ER_Financial_Center__r.ER_Account_Name__c);
    }

    if (!mapStoreAccount.isEmpty()) {
      List<String> quotesStatuses = new List<String>{ Constants.DRAFT, Constants.PRESENTED };
      for (Quote q : [
        SELECT Id, AccountId
        FROM Quote
        WHERE AccountId IN :mapStoreAccount.values() AND Status IN :quotesStatuses
      ]) {
        for (Id sId : mapStoreAccount.keySet()) {
          if (q.AccountId == mapStoreAccount.get(sId))
            docugenQuoteStoreAcceptors.add(
              new ER_Docugen_Quote_Store_Acceptor__c(
                ER_Quote__c = q.Id,
                ER_Store__c = sId,
                ER_Acceptor__c = null,
                ER_Financial_Center__c = mapStores.get(sId).ER_Financial_Center__c
              )
            );
        }
      }

      if (!docugenQuoteStoreAcceptors.isEmpty())
        insert docugenQuoteStoreAcceptors;
    }*/
  }

  /**
   * @author ALK
   * @date 08/08/2022
   * @description Create Aggregator merchant for Store Aggregator
   * @param newItems
   */
  public static void createAggregatorMerchant(List<ER_Store__c> newItems) {
    /*Id storeAggregatorRTId = Utils.getRecordTypeIdByDeveloperName(
      ER_Store__c.SObjectType,
      Constants.STORE_STORE_AGGREGATOR_RT
    );
    Map<String, List<ER_Store__c>> mapVatStores = new Map<String, List<ER_Store__c>>();
    Map<String, List<ER_Store__c>> mapAggIdStores = new Map<String, List<ER_Store__c>>();
    Id aggregatorMerchantRTId = Utils.getRecordTypeIdByDeveloperName(
      Account.SObjectType,
      Constants.ACCOUNT_AGGREGATOR_MERCHANT_RT
    );
    Id companyRTId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);
    Set<Id> accountRecordTypes = new Set<Id>{ aggregatorMerchantRTId, companyRTId };
    Map<String, Account> mapAggregators = new Map<String, Account>();
    Map<String, Account> mapMerchants = new Map<String, Account>();
    Map<String, Account> mapAggMerchants = new Map<String, Account>();
    List<ER_Store__c> aggregatorStores = new List<ER_Store__c>();
    Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
    Map<String, Account> mapStoreAggMerchantToInsert = new Map<String, Account>();

    for (ER_Store__c s : newItems) {
      if (s.RecordTypeId == storeAggregatorRTId) {
        String uuid = Utils.generateUniqueId();
        s.ER_MDMId__c = uuid;
        aggregatorStores.add(s);

        if (String.isNotBlank(s.ER_VAT_Number__c)) {
          if (!mapVatStores.containsKey(s.ER_VAT_Number__c))
            mapVatStores.put(s.ER_VAT_Number__c, new List<ER_Store__c>());
          mapVatStores.get(s.ER_VAT_Number__c).add(s);
        }

        if (String.isNotBlank(s.ER_Aggregator_Id__c)) {
          if (!mapAggIdStores.containsKey(s.ER_Aggregator_Id__c))
            mapAggIdStores.put(s.ER_Aggregator_Id__c, new List<ER_Store__c>());
          mapAggIdStores.get(s.ER_Aggregator_Id__c).add(s);
        }
      }
    }

    if (!mapVatStores.isEmpty() || !mapAggIdStores.isEmpty()) {
      for (Account a : [
        SELECT Id, ER_VAT_Number__c, ER_Aggregator_Id__c, Description, RecordTypeId, ER_Aggregator__c
        FROM Account
        WHERE
          RecordTypeId IN :accountRecordTypes
          AND (ER_VAT_Number__c IN :mapVatStores.keySet()
          OR ER_Aggregator_Id__c IN :mapAggIdStores.keySet())
      ]) {
        if (mapVatStores.containsKey(a.ER_VAT_Number__c)) {
          if (a.RecordTypeId == aggregatorMerchantRTId)
            mapAggMerchants.put(a.ER_VAT_Number__c, a);
          else if (a.RecordTypeId == companyRTId)
            mapMerchants.put(a.ER_VAT_Number__c, a);
        }

        if (mapAggIdStores.containsKey(a.ER_Aggregator_Id__c) && a.RecordTypeId == companyRTId)
          mapAggregators.put(a.ER_Aggregator_Id__c, a);
      }

      for (ER_Store__c s : aggregatorStores) {
        if (mapMerchants.containsKey(s.ER_VAT_Number__c))
          s.ER_Merchant__c = mapMerchants.get(s.ER_VAT_Number__c).Id;
        if (mapAggregators.containsKey(s.ER_Aggregator_Id__c))
          s.ER_Aggregator__c = mapAggregators.get(s.ER_Aggregator_Id__c).Id;
        if (mapAggMerchants.containsKey(s.ER_VAT_Number__c)) {
          s.ER_Aggregator_Merchant__c = mapAggMerchants.get(s.ER_VAT_Number__c).Id;
          Account a = mapAggMerchants.get(s.ER_VAT_Number__c);
          if (String.isBlank(a.Description))
            a.Description = s.ER_Description__c;
          else
            a.Description += ';' + s.ER_Description__c;
          accountsToUpdate.put(a.Id, a);
        } else if (mapStoreAggMerchantToInsert.containsKey(s.ER_VAT_Number__c)) {
          //Case when store aggregator contain same VAT Number in the same batch insert
        } else {
          //create new Aggregator Merchant
          Account a = new Account();
          a.Name = s.Name.length() > 250 ? s.Name.substring(0, 250) + ' - AM' : s.Name + ' - AM';
          a.RecordTypeId = aggregatorMerchantRTId;
          a.ER_VAT_Number__c = s.ER_VAT_Number__c;
          a.ER_Legal_Name__c = a.Name;
          a.ER_BUPicklist__c = (String.isNotBlank(s.ER_BUPicklist__c)
            ? s.ER_BUPicklist__c
            : UtilsBypass.getCurrentUser().ER_Business_Unit__c);
          a.ER_Status__c = Constants.ACTIVE;
          a.Description = s.ER_Description__c;
          mapStoreAggMerchantToInsert.put(s.ER_VAT_Number__c, a);
        }
      }

      if (!mapStoreAggMerchantToInsert.isEmpty())
        insert mapStoreAggMerchantToInsert.values();
      if (!accountsToUpdate.isEmpty())
        update accountsToUpdate.values();

      for (ER_Store__c s : aggregatorStores) {
        if (mapStoreAggMerchantToInsert.containsKey(s.ER_VAT_Number__c))
          s.ER_Aggregator_Merchant__c = mapStoreAggMerchantToInsert.get(s.ER_VAT_Number__c).Id;
      }
    }*/
  }

  /**
   * @author ALK
   * @date 17/06/2022
   * @description Create Merchant Aggregator Partner Accounts
   * @param newItems
   */
  public static void createAccountPartnerStoreAggregators(List<ER_Store__c> newItems) {
    /*Id storeAggregatorRT = Utils.getRecordTypeIdByDeveloperName(
      ER_Store__c.SObjectType,
      Constants.STORE_STORE_AGGREGATOR_RT
    );
    Map<String, AccountPartner> mapPartners = new Map<String, AccountPartner>();
    Set<Id> aggregatorMerchantsIds = new Set<Id>();

    for (ER_Store__c s : newItems) {
      if (s.RecordTypeId == storeAggregatorRT && s.ER_Aggregator_Merchant__c != null) {
        aggregatorMerchantsIds.add(s.ER_Aggregator_Merchant__c);

        if (
          s.ER_Merchant__c != null &&
          !mapPartners.containsKey(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Merchant__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR
          )
        )
          mapPartners.put(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Merchant__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR,
            new AccountPartner(
              AccountFromId = s.ER_Aggregator_Merchant__c,
              AccountToId = s.ER_Merchant__c,
              Role = Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR
            )
          );
        if (
          s.ER_Aggregator__c != null &&
          !mapPartners.containsKey(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Aggregator__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_AGGREGATOR
          )
        )
          mapPartners.put(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Aggregator__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_AGGREGATOR,
            new AccountPartner(
              AccountFromId = s.ER_Aggregator_Merchant__c,
              AccountToId = s.ER_Aggregator__c,
              Role = Constants.PARTNER_ROLE_AGGREGATOR
            )
          );
      }
    }

    if (!mapPartners.isEmpty()) {
      for (AccountPartner ap : [
        SELECT Id, AccountFromId, AccountToId, Role
        FROM AccountPartner
        WHERE AccountFromId IN :aggregatorMerchantsIds
      ]) {
        String key = ap.AccountFromId + Constants.UNDERSCORE + ap.AccountToId + Constants.UNDERSCORE + ap.Role;
        if (mapPartners.containsKey(key))
          mapPartners.remove(key);
      }

      if (!mapPartners.isEmpty())
        insert mapPartners.values();
    }*/
  }

  /**
   * @author ALK
   * @date 17/06/2022
   * @description Recalculate Account Partners once an aggregator store has been updated
   * @param newItems
   * @param oldMap
   */
  public static void recalculateAccountPartnerAggregator(List<ER_Store__c> newItems, Map<Id, ER_Store__c> oldMap) {
    /*Id storeAggregatorRT = Utils.getRecordTypeIdByDeveloperName(
      ER_Store__c.SObjectType,
      Constants.STORE_STORE_AGGREGATOR_RT
    );
    Map<String, Id> mapKeyAggregatorMerchants = new Map<String, Id>();
    List<AccountPartner> partnersToBeDeleted = new List<AccountPartner>();
    Map<Id, ER_Store__c> stores = new Map<Id, ER_Store__c>();

    for (ER_Store__c s : newItems) {
      if (s.RecordTypeId == storeAggregatorRT) {
        stores.put(s.Id, s);
        //Change on Aggregator Merchant
        if (
          s.ER_Aggregator_Merchant__c != oldMap.get(s.Id).ER_Aggregator_Merchant__c &&
          (oldMap.get(s.Id).ER_Aggregator_Merchant__c != null ||
          s.ER_Aggregator_Merchant__c == null)
        ) {
          if (s.ER_Aggregator__c != null) {
            Id aggMerchantId = (s.ER_Aggregator_Merchant__c != null
              ? s.ER_Aggregator_Merchant__c
              : oldMap.get(s.Id).ER_Aggregator_Merchant__c);
            mapKeyAggregatorMerchants.put(
              aggMerchantId +
              Constants.UNDERSCORE +
              s.ER_Aggregator__c +
              Constants.UNDERSCORE +
              Constants.PARTNER_ROLE_AGGREGATOR,
              aggMerchantId
            );
          }
          if (s.ER_Merchant__c != null) {
            Id aggMerchantId = (s.ER_Aggregator_Merchant__c != null
              ? s.ER_Aggregator_Merchant__c
              : oldMap.get(s.Id).ER_Aggregator_Merchant__c);
            mapKeyAggregatorMerchants.put(
              aggMerchantId +
              Constants.UNDERSCORE +
              s.ER_Merchant__c +
              Constants.UNDERSCORE +
              Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR,
              aggMerchantId
            );
          }
        }

        //Change on Aggregator
        if (
          s.ER_Aggregator_Merchant__c != null &&
          s.ER_Aggregator__c != oldMap.get(s.Id).ER_Aggregator__c &&
          (oldMap.get(s.Id).ER_Aggregator__c != null ||
          s.ER_Aggregator__c == null)
        ) {
          Id AggregatorId = (s.ER_Aggregator__c != null ? s.ER_Aggregator__c : oldMap.get(s.Id).ER_Aggregator__c);
          mapKeyAggregatorMerchants.put(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            AggregatorId +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_AGGREGATOR,
            s.ER_Aggregator_Merchant__c
          );
        }

        //Change on Merchant
        if (
          s.ER_Aggregator_Merchant__c != null &&
          s.ER_Merchant__c != oldMap.get(s.Id).ER_Merchant__c &&
          (oldMap.get(s.Id).ER_Merchant__c != null ||
          s.ER_Merchant__c == null)
        ) {
          Id merchantId = (s.ER_Merchant__c != null ? s.ER_Merchant__c : oldMap.get(s.Id).ER_Merchant__c);
          mapKeyAggregatorMerchants.put(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            merchantId +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR,
            s.ER_Aggregator_Merchant__c
          );
        }
      }
    }

    if (!mapKeyAggregatorMerchants.isEmpty()) {
      for (ER_Store__c s : [
        SELECT Id, ER_Aggregator_Merchant__c, ER_Aggregator__c, ER_Merchant__c
        FROM ER_Store__c
        WHERE RecordTypeId = :storeAggregatorRT AND ER_Aggregator_Merchant__c IN :mapKeyAggregatorMerchants.values()
      ]) {
        if (
          s.ER_Aggregator__c != null &&
          mapKeyAggregatorMerchants.containsKey(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Aggregator__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_AGGREGATOR
          )
        ) {
          mapKeyAggregatorMerchants.remove(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Aggregator__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_AGGREGATOR
          );
        }

        if (
          s.ER_Merchant__c != null &&
          mapKeyAggregatorMerchants.containsKey(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Merchant__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR
          )
        ) {
          mapKeyAggregatorMerchants.remove(
            s.ER_Aggregator_Merchant__c +
            Constants.UNDERSCORE +
            s.ER_Merchant__c +
            Constants.UNDERSCORE +
            Constants.PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR
          );
        }
      }

      for (AccountPartner ap : [
        SELECT Id, AccountFromId, AccountToId, Role
        FROM AccountPartner
        WHERE AccountFromId IN :mapKeyAggregatorMerchants.values()
      ]) {
        if (
          mapKeyAggregatorMerchants.containsKey(
            ap.AccountFromId +
            Constants.UNDERSCORE +
            ap.AccountToId +
            Constants.UNDERSCORE +
            ap.Role
          )
        )
          partnersToBeDeleted.add(ap);
      }

      if (!partnersToBeDeleted.isEmpty())
        delete partnersToBeDeleted;
    }

    if (!stores.isEmpty())
      createAccountPartnerStoreAggregators(stores.values());*/
  }

  /**
   * @author ALK
   * @date 17/06/2022
   * @description Create Virtual Web Auth Acceptor
   * @param newItems
   * @param oldMap
   */
  public static void createWebAuthAccepterStoreAggregator(List<ER_Store__c> newItems, Map<Id, ER_Store__c> oldMap) {
    /*Id storeAggregatorRT = Utils.getRecordTypeIdByDeveloperName(
      ER_Store__c.SObjectType,
      Constants.STORE_STORE_AGGREGATOR_RT
    );
    Id acceptorMerchantId = Utils.getRecordTypeIdByDeveloperName(
      ER_Acceptor__c.SObjectType,
      Constants.ACCEPTOR_MERCHANT_RT
    );
    Map<Id, List<ER_Store__c>> mapEdenredStores = new Map<Id, List<ER_Store__c>>();
    List<ER_Virtual_Acceptor_Store_Aggregator__c> virtualAcceptorsToBeCreated = new List<ER_Virtual_Acceptor_Store_Aggregator__c>();
    List<ER_Acceptor__c> acceptorsWebAuth = new List<ER_Acceptor__c>();

    for (ER_Store__c s : newItems) {
      if (
        s.RecordTypeId == storeAggregatorRT &&
        s.Edenred_Store__c != null &&
        s.Edenred_Store__c != oldMap?.get(s.Id).Edenred_Store__c
      ) {
        if (!mapEdenredStores.containsKey(s.Edenred_Store__c))
          mapEdenredStores.put(s.Edenred_Store__c, new List<ER_Store__c>());
        mapEdenredStores.get(s.Edenred_Store__c).add(s);
      }
    }

    if (!mapEdenredStores.isEmpty()) {
      for (ER_Acceptor__c a : [
        SELECT Id, ER_Store__c
        FROM ER_Acceptor__c
        WHERE
          RecordTypeId = :acceptorMerchantId
          AND ER_Store__c IN :mapEdenredStores.keySet()
          AND ER_Acceptor_Scheme__c = :Constants.WEBAUTH
      ]) {
        if (mapEdenredStores.containsKey(a.ER_Store__c)) {
          for (ER_Store__c s : mapEdenredStores.get(a.ER_Store__c)) {
            virtualAcceptorsToBeCreated.add(
              new ER_Virtual_Acceptor_Store_Aggregator__c(
                ER_Acceptor_Id__c = a.Id,
                ER_Store_Id__c = s.Id,
                ER_Virtual_Acceptor_Key__c = a.Id + Constants.UNDERSCORE + s.Id
              )
            );
          }

          mapEdenredStores.remove(a.ER_Store__c);
        }
      }

      for (List<ER_Store__c> stores : mapEdenredStores.values()) {
        for (ER_Store__c s : stores) {
          String extId = Utils.generateUniqueId();
          ER_Acceptor__c newAcceptor = new ER_Acceptor__c();
          newAcceptor.RecordTypeId = acceptorMerchantId;
          newAcceptor.Name = ('WA-' + Datetime.now().getTime()).length() > 16
            ? ('WA-' + Datetime.now().getTime()).substring(0, 16)
            : 'WA-' + Datetime.now().getTime();
          newAcceptor.ER_Status__c = Constants.ACTIVE;
          newAcceptor.ER_Store__c = s.Edenred_Store__c;
          newAcceptor.ER_Acceptor_Scheme__c = Constants.WEBAUTH;
          //newAcceptor.ER_MID__c = String.valueOf(Datetime.now().getTime());
          newAcceptor.ER_MID_Authorization__c = String.valueOf(Datetime.now().getTime());
          newAcceptor.ER_Start_Date__c = Date.today();
          newAcceptor.ER_TID_Authorization__c = String.valueOf(Datetime.now().getTime());
          newAcceptor.ER_MDMId__c = extId;
          newAcceptor.ER_Acceptor_Type__c = Constants.ACCEPTOR_TYPE_AGGREGATOR;
          acceptorsWebAuth.add(newAcceptor);

          virtualAcceptorsToBeCreated.add(
            new ER_Virtual_Acceptor_Store_Aggregator__c(
              ER_Acceptor_Id__r = new ER_Acceptor__c(ER_MDMId__c = extId),
              ER_Store_Id__c = s.Id
            )
          );
        }
      }

      if (!acceptorsWebAuth.isEmpty())
        insert acceptorsWebAuth;
      if (!virtualAcceptorsToBeCreated.isEmpty())
        insert virtualAcceptorsToBeCreated;
    }*/
  }

  /**
   * @author Noor
   * @date 18/05/2022
   * @description update Main Category on Store field each time a Store Category Main is created or updated
   * @param storeCategories new or updated storeCategories
   */
  public static void updateStoreMainCategory(List<ER_StoreCategory__c> storeCategories) {
    /*Map<Id, Id> storeMainCategoryMap = new Map<Id, Id>();

    for (ER_StoreCategory__c sc : storeCategories) {
      if (sc.Main_Category__c && String.isNotBlank(sc.Category__c))
        storeMainCategoryMap.put(sc.Store__c, sc.Category__c);
    }

    if (!storeMainCategoryMap.isEmpty()) {
      List<ER_Store__c> storeToUpdate = new List<ER_Store__c>();

      Map<Id, ER_DependentValue__c> categoriesMap = retrieveCategoryName(storeMainCategoryMap.values());

      for (Id storeId : storeMainCategoryMap.keySet()) {
        storeToUpdate.add(
          new ER_Store__c(
            Id = StoreId,
            ER_Docugen_Main_Category__c = categoriesMap.get(storeMainCategoryMap.get(storeId)).Name
          )
        );
      }
      if (!storeToUpdate.isEmpty())
        update storeToUpdate;
    }*/
  }

  /**
   * @author Noor
   * @date 18/05/2022
   * @description retrieve list of  Categories (ER_DependentValue__c) by Id
   * @param categoryIds Ids of Categories (ER_DependentValue__c)
   */
  private static Map<Id, ER_DependentValue__c> retrieveCategoryName(List<Id> categoryIds) {
    return new Map<Id, ER_DependentValue__c>([SELECT Id, Name FROM ER_DependentValue__c WHERE Id IN :categoryIds]);
  }

  public class APER14_Store_Management_Exception extends Exception {
  }
}