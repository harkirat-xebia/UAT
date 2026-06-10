/*
----------------------------------------------------------------------
-- - Name          : APER23_Acceptor_Management
-- - Author        : RB
-- - Description   : Acceptor Management, This class is used to group all the functionnality linked to the object Acceptor       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 10-MAR-2020  RB                   1.0         Initial version
-- FEB-2021     KHAD                 2.0         Solution at all level
---------------------------------------------------------------------------------------
*/

public with sharing class APER23_Acceptor_Management {
  private static final String STATUS_INACTIVE = Label.LAB_SF_Acceptor_Inactive;

  public static void setInactiveAcceptors(List<ER_Acceptor__c> acceptors) {
    List<Database.SaveResult> srList = new List<Database.SaveResult>();

    //Iterate over list of acceptor and set them to Inactive.
    for (ER_Acceptor__c acceptor : acceptors) {
      acceptor.ER_Status__c = STATUS_INACTIVE;
    }
    // to bypass the synchronization
    WSHU09_SynchronizeAcceptorWS.alreadyExecutedAcceptor = true;
    //Update all acceptors
    srList = Database.update(acceptors, false);

    //Check the update process
    checkUpdatedAcceptors(srList);
  }

  private static void checkUpdatedAcceptors(List<Database.SaveResult> srList) {
    // Verify that the update should process by the batch
    // Iterate through each returned result
    System.debug('## >>> Check the Database delete  <<< ');
    for (Database.SaveResult sr : srList) {
      if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('The batch has been successfully proceed. Acceptor ID: ' + sr.getId());
      } else {
        // Operation failed, so get all errors
        for (Database.Error err : sr.getErrors()) {
          System.debug('The following error has occurred.');
          System.debug(err.getStatusCode() + ': ' + err.getMessage());
          System.debug('Acceptor fields that affected this error: ' + err.getFields());
        }
      }
    }
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageAcceptorLIFromContract(Contract contract) {
    if (UtilsBypass.canTrigger('manageAcceptorLIFromContract')) {
      GenericWithoutSharing.manageAcceptorLIFromContract(contract);
    }
  }

  public static void manageAccLIForNewAcceptor(Map<Id, ER_Acceptor__c> acceptorMap) {
    System.debug('manageAccLIForNewAcceptor START');

    List<ER_Acceptor__c> insertedAcceptors = [
      SELECT id, Name, ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c, ER_BUPicklist__c
      FROM ER_Acceptor__c
      WHERE id IN :acceptorMap.keySet()
    ];
    ER_Solution_Line_Item__c accli;
    Set<ER_Solution_Line_Item__c> allActiveStoreLineItem = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> mapStoreActiveStoreLineItems = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> accliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> companySet = new Set<String>();

    for (ER_Acceptor__c acceptor : insertedAcceptors) {
      companySet.add(acceptor.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c);
    }

    Map<Id, ER_Solution_Line_Item__c> allsliList = APER14_Store_Management.getAllStoreLineItems(companySet); //get All Store Line Items for a company.

    //Loop to build Map Stores to Store Line Items
    for (ER_Solution_Line_Item__c sli : allsliList.values()) {
      allActiveStoreLineItem = new Set<ER_Solution_Line_Item__c>();

      if (!mapStoreActiveStoreLineItems.containsKey(sli.ER_Store__c)) {
        allActiveStoreLineItem.add(sli);
        mapStoreActiveStoreLineItems.put(sli.ER_Store__c, allActiveStoreLineItem);
      } else {
        allActiveStoreLineItem = mapStoreActiveStoreLineItems.get(sli.ER_Store__c);
        allActiveStoreLineItem.add(sli);
        mapStoreActiveStoreLineItems.put(sli.ER_Store__c, allActiveStoreLineItem);
      }
    }

    if (!mapStoreActiveStoreLineItems.isEmpty()) {
      for (ER_Acceptor__c acceptor : insertedAcceptors) {
        if(mapStoreActiveStoreLineItems.containsKey(acceptor.ER_Store__c)){
          for (ER_Solution_Line_Item__c storeLineItem : mapStoreActiveStoreLineItems.get(acceptor.ER_Store__c)) {
            accli = new ER_Solution_Line_Item__c();
            accli.ER_Solution__c = storeLineItem.ER_Solution__c;
            accli.ER_Contract__c = storeLineItem.ER_Contract__c;
            accli.ER_Acceptor__c = acceptor.Id;
            accli.ER_Status__c = storeLineItem.ER_Status__c;
            accli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
              .get('ER_Acceptor_Line_Item')
              .getRecordTypeId();
            accli.ER_Parent_Line_Item__c = storeLineItem.Id;
            accli.ER_BUPicklist__c = acceptor.ER_BUPicklist__c; // AAM 19.01.2022 - PBI#14290

            accliListToInsert.add(accli);
          }
        }
      }

      if (!accliListToInsert.isEmpty()) {
        System.debug('sliList to insert : ' + accliListToInsert);
        insert accliListToInsert;
      }
    }

    System.debug('manageAccLIForNewAcceptor END');
  }

  public static void updateAddAcceptorFuture(List<ER_Acceptor__c> acceptors) {
    System.Debug('--- APHU09_SynchronizeAcceptorWS begin prepare');

    Set<Id> acceptorSet = new Set<Id>();

    if (!WSHU09_SynchronizeAcceptorWS.alreadyExecutedAcceptor) {
      // Loop through the acceptors list and add them all to the set
      for (ER_Acceptor__c accPoint : acceptors) {
        /*if (accPoint.ER_MID_Authorization__c == null && accPoint.RecordType.DeveloperName == 'ER_Merchant_Acceptor_RT') {
                    accPoint.addError('The MID Authorization is missing');
                } else*/
        if (accPoint.ER_Business_Unit__c == 'HU' || accPoint.ER_Business_Unit__c == 'CZ') {
          acceptorSet.add(accPoint.Id);
        }
      }
    }

    System.Debug('--- APHU09_SynchronizeAcceptorWS end prepare');

    if (!acceptorSet.isEmpty()) {
      System.debug('update add acceptor future');
      WSHU09_SynchronizeAcceptorWS.updateAddAcceptorsFuture(acceptorSet);
    }
  }

  public static void updateDigitalStoreStatus(List<ER_Acceptor__c> acceptors, Map<Id, ER_Acceptor__c> oldMap) {
    System.debug('List acceptors ' + acceptors);
    System.debug('List acceptors ' + oldMap);
    Id posRecordTypeId = Schema.SObjectType.ER_Acceptor__c.getRecordTypeInfosByDeveloperName()
      .get('Edenred_POS')
      .getRecordTypeId();
    List<String> storeIds = new List<String>();

    for (ER_Acceptor__c acc : acceptors) {
      if (acc.RecordTypeId == posRecordTypeId)
        storeIds.add(acc.ER_Store__c);
    }

    if (!storeIds.isEmpty()) {
      Map<Id, ER_Store__c> storeMap = new Map<Id, ER_Store__c>(
        [SELECT Id, ER_Digital_Store__c, ER_Digital_Store_Status__c FROM ER_Store__c WHERE Id IN :storeIds]
      );
      System.debug('Store map = ' + storeMap.values());
      List<ER_Store__c> digitalStores = new List<ER_Store__c>();
      for (ER_Acceptor__c acc : acceptors) {
        System.debug(
          'acc.storeMap.ER_Digital_Store_Status__c' + storeMap.get(acc.ER_Store__c).ER_Digital_Store_Status__c
        );
        System.debug('acc.storeMap.ER_Digital_Store__c' + storeMap.get(acc.ER_Store__c).ER_Digital_Store__c);
        System.debug('merchantRecordTypeId' + posRecordTypeId);
        System.debug('acc.acc.ER_Store__r.Id' + acc.ER_Store__c);
        //System.debug('oldMap.get(acc.Id).ER_Store__r.ER_Digital_Store_Status__c' + oldMap.get(acc.Id).ER_Store__r.ER_Digital_Store_Status__c);
        if (
          acc.RecordTypeId == posRecordTypeId &&
          acc.ER_Sync_result__c == '1' &&
          storeMap.get(acc.ER_Store__c).ER_Digital_Store__c &&
          (storeMap.get(acc.ER_Store__c).ER_Digital_Store_Status__c == null ||
          storeMap.get(acc.ER_Store__c).ER_Digital_Store_Status__c == '')
        ) {
          //ER_Store__c parentStore = acc.ER_Store__r.clone(true, true, false, false);
          ER_Store__c parentStore = [
            SELECT id, ER_Digital_Store_Status__c
            FROM ER_Store__c
            WHERE id = :acc.ER_Store__c
            LIMIT 1
          ];
          parentStore.ER_Digital_Store_Status__c = 'Created';
          //System.debug('trigger update digital store' + parentStore);
          digitalStores.add(parentStore);
        }

        if (!digitalStores.isEmpty()) {
          update digitalStores;
        }
      }
    }
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Prevent Duplicate Acceptors - ERPL Model
   * @param acceptors
   */
  public static void checkAcceptorUniquenessPL(List<ER_Acceptor__c> acceptors, Map<Id, ER_Acceptor__c> oldMap) {
    Map<String, ER_Acceptor__c> mapMIDAcceptors = new Map<String, ER_Acceptor__c>();
    Map<String, List<ER_Acceptor__c>> mapKeyAcceptors = new Map<String, List<ER_Acceptor__c>>();
    Map<String, List<ER_Acceptor__c>> mapElectedAcceptors = new Map<String, List<ER_Acceptor__c>>();
    Map<String, List<ER_Acceptor__c>> mapStoreAcceptors = new Map<String, List<ER_Acceptor__c>>();
    List<ER_Acceptor__c> changedAcceptors = new List<ER_Acceptor__c>();

    if (oldMap == null)
      changedAcceptors = acceptors;
    else {
      for (ER_Acceptor__c a : acceptors) {
        if (hasAcceptorMIDsChanged(a, oldMap.get(a.Id)))
          changedAcceptors.add(a);
      }
    }

    if (!changedAcceptors.isEmpty()) {
      for (ER_Acceptor__c a : changedAcceptors) {
        if (!mapStoreAcceptors.containsKey(a.ER_Store__c))
          mapStoreAcceptors.put(a.ER_Store__c, new List<ER_Acceptor__c>());
        mapStoreAcceptors.get(a.ER_Store__c).add(a);
      }

      for (ER_Store__c s : [
        SELECT Id, ER_Financial_Center__r.ER_Account_Name__c
        FROM ER_Store__c
        WHERE Id IN :mapStoreAcceptors.keySet()
      ]) {
        for (ER_Acceptor__c a : mapStoreAcceptors.get(s.Id))
          a.ER_Store__r = s;
      }

      for (ER_Acceptor__c a : changedAcceptors) {
        if (String.isNotBlank(a.ER_MID_Authorization__c)) {
          String key =
            a.ER_BUPicklist__c +
            '_' +
            a.ER_MID_Authorization__c +
            '_' +
            (String.isNotBlank(a.ER_SubMID_Authorization__c) ? a.ER_SubMID_Authorization__c : '') +
            '_' +
            (String.isNotBlank(a.ER_MID_Clearing__c) ? a.ER_MID_Clearing__c : '') +
            '_' +
            (String.isNotBlank(a.ER_Sub_MID_Clearing__c) ? a.ER_Sub_MID_Clearing__c : '');

          if (!mapMIDAcceptors.containsKey(a.ER_BUPicklist__c + '_' + a.ER_MID_Authorization__c)) {
            mapMIDAcceptors.put(a.ER_BUPicklist__c + '_' + a.ER_MID_Authorization__c, a);

            if (!mapKeyAcceptors.containsKey(key))
              mapKeyAcceptors.put(key, new List<ER_Acceptor__c>());
            mapKeyAcceptors.get(key).add(a);

            if (!mapElectedAcceptors.containsKey(a.ER_MID_Authorization__c))
              mapElectedAcceptors.put(a.ER_MID_Authorization__c, new List<ER_Acceptor__c>());
            mapElectedAcceptors.get(a.ER_MID_Authorization__c).add(a);
          } else {
            ER_Acceptor__c old = mapMIDAcceptors.get(a.ER_BUPicklist__c + '_' + a.ER_MID_Authorization__c);
            if (
              a.ER_BUPicklist__c == old.ER_BUPicklist__c &&
              Utils.checkDatesBetween2Dates(
                a.ER_Start_Date__c,
                a.ER_End_Date__c,
                old.ER_Start_Date__c,
                old.ER_End_Date__c
              )
            ) {
              if (mapKeyAcceptors.containsKey(key))
                a.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MIDs);
              else if (
                old.ER_MID_Authorization__c == a.ER_MID_Authorization__c &&
                old.ER_SubMID_Authorization__c == a.ER_SubMID_Authorization__c &&
                old.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c !=
                a.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c &&
                UserInfo.getUserType() != Constants.AUTOMATED_PROCESS
              )
                a.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MID_RULE2);
              else if (
                a.ER_MID_Authorization__c == old.ER_MID_Authorization__c &&
                (String.isNotBlank(a.ER_SubMID_Authorization__c) && String.isBlank(old.ER_SubMID_Authorization__c) ||
                (String.isNotBlank(old.ER_SubMID_Authorization__c) && String.isBlank(a.ER_SubMID_Authorization__c)))
              )
                a.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MID_RULE4);
            } else {
              if (!mapKeyAcceptors.containsKey(key))
                mapKeyAcceptors.put(key, new List<ER_Acceptor__c>());
              mapKeyAcceptors.get(key).add(a);

              mapElectedAcceptors.get(a.ER_MID_Authorization__c).add(a);
            }
          }
        }
      }

      if (!mapElectedAcceptors.isEmpty()) {
        for (ER_Acceptor__c a : [
          SELECT
            Id,
            ER_MID__c,
            ER_MID_Authorization__c,
            ER_SubMID_Authorization__c,
            ER_MID_Clearing__c,
            ER_Sub_MID_Clearing__c,
            ER_Start_Date__c,
            ER_End_Date__c,
            ER_BUPicklist__c,
            ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c
          FROM ER_Acceptor__c
          WHERE ER_MID_Authorization__c IN :mapElectedAcceptors.keySet()
          ORDER BY ER_Start_Date__c
        ]) {
          String existingKey =
            a.ER_BUPicklist__c +
            '_' +
            a.ER_MID_Authorization__c +
            '_' +
            (String.isNotBlank(a.ER_SubMID_Authorization__c) ? a.ER_SubMID_Authorization__c : '') +
            '_' +
            (String.isNotBlank(a.ER_MID_Clearing__c) ? a.ER_MID_Clearing__c : '') +
            '_' +
            (String.isNotBlank(a.ER_Sub_MID_Clearing__c) ? a.ER_Sub_MID_Clearing__c : '');
          for (ER_Acceptor__c item : mapElectedAcceptors.get(a.ER_MID_Authorization__c)) {
            String newKey =
              item.ER_BUPicklist__c +
              '_' +
              item.ER_MID_Authorization__c +
              '_' +
              (String.isNotBlank(item.ER_SubMID_Authorization__c) ? item.ER_SubMID_Authorization__c : '') +
              '_' +
              (String.isNotBlank(item.ER_MID_Clearing__c) ? item.ER_MID_Clearing__c : '') +
              '_' +
              (String.isNotBlank(item.ER_Sub_MID_Clearing__c) ? item.ER_Sub_MID_Clearing__c : '');
            if (
              item.ER_BUPicklist__c == a.ER_BUPicklist__c &&
              item.Id != a.Id &&
              Utils.checkDatesBetween2Dates(
                item.ER_Start_Date__c,
                item.ER_End_Date__c,
                a.ER_Start_Date__c,
                a.ER_End_Date__c
              )
            ) {
              if (newKey == existingKey)
                item.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MIDs);
              else if (
                item.ER_MID_Authorization__c == a.ER_MID_Authorization__c &&
                item.ER_SubMID_Authorization__c == a.ER_SubMID_Authorization__c &&
                item.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c !=
                a.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c &&
                UserInfo.getUserType() != Constants.AUTOMATED_PROCESS
              )
                item.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MID_RULE2);
              else if (
                item.ER_MID_Authorization__c == a.ER_MID_Authorization__c &&
                (String.isNotBlank(item.ER_SubMID_Authorization__c) && String.isBlank(a.ER_SubMID_Authorization__c) ||
                String.isNotBlank(a.ER_SubMID_Authorization__c) && String.isBlank(item.ER_SubMID_Authorization__c))
              )
                item.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MID_RULE4);
            }
          }
        }
      }
    }
  }

  /**
   * @author ALK
   * @description Check if the ERPL Acceptor has MIDs Changed
   * @date 02/06/2021
   *
   * @param newItem
   * @param oldItem
   *
   * @return
   */
  public static Boolean hasAcceptorMIDsChanged(ER_Acceptor__c newItem, ER_Acceptor__c oldItem) {
    if (
      newItem.ER_MID_Authorization__c != oldItem.ER_MID_Authorization__c ||
      newItem.ER_SubMID_Authorization__c != oldItem.ER_SubMID_Authorization__c ||
      newItem.ER_MID_Clearing__c != oldItem.ER_MID_Clearing__c ||
      newItem.ER_Sub_MID_Clearing__c != oldItem.ER_Sub_MID_Clearing__c
    )
      return true;
    return false;
  }

  /**
   * @author ALK
   * @date 17/11/2021
   * @description PBI 13292 - Prevent Duplicate Acceptors - ERES Model
   * Duplicate Acceptor : Same ER_MID_Authorization__c and Same ER_SubMID_Authorization__c
   * @param acceptors
   */
  public static void checkAcceptorUniquenessES(List<ER_Acceptor__c> acceptors) {
    Map<String, ER_Acceptor__c> mapMIDAcceptors = new Map<String, ER_Acceptor__c>();
    Set<String> setMIds = new Set<String>();
    Id acceptorRTId = Utils.getRecordTypeIdByDeveloperName(ER_Acceptor__c.SObjectType, 'ER_Merchant_Acceptor_RT');

    //Check duplicates in the bulk list
    for (ER_Acceptor__c a : acceptors) {
      if (a.RecordTypeId == acceptorRTId) {
        String key =
          a.ER_BUPicklist__c +
          '_' +
          a.ER_MID_Authorization__c +
          (String.isNotBlank(a.ER_SubMID_Authorization__c) ? '_' + a.ER_SubMID_Authorization__c : '');

        if (!mapMIDAcceptors.containsKey(key)) {
          mapMIDAcceptors.put(key, a);
          setMIds.add(a.ER_MID_Authorization__c);
        } else if (
          !UtilsBypass.getCurrentUser().ER_BypassVR__c &&
          Utils.checkDatesBetween2Dates(
            a.ER_Start_Date__c,
            a.ER_End_Date__c,
            mapMIDAcceptors.get(key).ER_Start_Date__c,
            mapMIDAcceptors.get(key).ER_End_Date__c
          )
        )
          a.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MIDs);
      }
    }

    //Check duplicates with database data
    for (ER_Acceptor__c a : [
      SELECT Id, ER_MID_Authorization__c, ER_SubMID_Authorization__c, ER_Start_Date__c, ER_End_Date__c, ER_BUPicklist__c
      FROM ER_Acceptor__c
      WHERE ER_MID_Authorization__c IN :setMIds
      ORDER BY ER_Start_Date__c
    ]) {
      String key =
        a.ER_BUPicklist__c +
        '_' +
        a.ER_MID_Authorization__c +
        (String.isNotBlank(a.ER_SubMID_Authorization__c) ? '_' + a.ER_SubMID_Authorization__c : '');
      ER_Acceptor__c newItem = mapMIDAcceptors.get(key);
      if (
        !UtilsBypass.getCurrentUser().ER_BypassVR__c &&
        mapMIDAcceptors.containsKey(key) &&
        a.Id != newItem.Id &&
        Utils.checkDatesBetween2Dates(
          newItem.ER_Start_Date__c,
          newItem.ER_End_Date__c,
          a.ER_Start_Date__c,
          a.ER_End_Date__c
        )
      )
        newItem.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_MIDs);
    }
  }
  /**
   * @author Noor
   * @date 05/18/2023
   * @description  Prevent Duplicate Acceptors - ERGR Model
   * Duplicate Acceptor : Same ER_MID_Authorization__c,ER_Acceptor_Type__c,ER_Acceptor_Scheme__c
   * @param acceptors
   */
  public static void checkAcceptorUniquenessGR(List<ER_Acceptor__c> acceptors) {
    Map<String, ER_Acceptor__c> mapMIDAcceptors = new Map<String, ER_Acceptor__c>();
    Set<String> setMIds = new Set<String>();
    Id acceptorRTId = Utils.getRecordTypeIdByDeveloperName(ER_Acceptor__c.SObjectType, 'ER_Merchant_Acceptor_RT');

    //Check duplicates in the bulk list
    for (ER_Acceptor__c a : acceptors) {
      if (a.RecordTypeId == acceptorRTId) {
        String key =
          a.ER_BUPicklist__c +
          '_' +
          a.ER_MID_Authorization__c +
          '_' +
          a.ER_Acceptor_Type__c +
          '_' +
          a.ER_Acceptor_Scheme__c;

        if (!mapMIDAcceptors.containsKey(key)) {
          mapMIDAcceptors.put(key, a);
          setMIds.add(a.ER_MID_Authorization__c);
        } else if (!UtilsBypass.getCurrentUser().ER_BypassVR__c)
          a.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_GR);
      }
    }

    //Check duplicates with database data
    for (ER_Acceptor__c a : [
      SELECT
        Id,
        ER_MID_Authorization__c,
        ER_Acceptor_Type__c,
        ER_Acceptor_Scheme__c,
        ER_Start_Date__c,
        ER_End_Date__c,
        ER_BUPicklist__c
      FROM ER_Acceptor__c
      WHERE ER_MID_Authorization__c IN :setMIds
      ORDER BY ER_Start_Date__c
    ]) {
      String key =
        a.ER_BUPicklist__c +
        '_' +
        a.ER_MID_Authorization__c +
        '_' +
        a.ER_Acceptor_Type__c +
        '_' +
        a.ER_Acceptor_Scheme__c;
      ER_Acceptor__c newItem = mapMIDAcceptors.get(key);
      if (!UtilsBypass.getCurrentUser().ER_BypassVR__c && mapMIDAcceptors.containsKey(key) && a.Id != newItem.Id)
        newItem.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_GR);
    }
  }

  /**
   * @author Noor
   * @date 01/04/2022
   * @description PBI 14315 - Prevent Duplicate Acceptors - ER BENELUX Model
   * Duplicate Acceptor : Same ER_TID_Authorization__c for same Scheme and Status
   * @param acceptors
   */
  public static void checkAcceptorUniquenessBENELUX(List<ER_Acceptor__c> acceptors) {
    if (UserInfo.getUserType() != Constants.AUTOMATED_PROCESS) {
      Set<String> setTIDs = new Set<String>();
      Set<String> setMIDs = new Set<String>();
      Map<String, ER_Acceptor__c> mapKeyAcceptors = new Map<String, ER_Acceptor__c>();
      Id acceptorRTId = Utils.getRecordTypeIdByDeveloperName(
        ER_Acceptor__c.SObjectType,
        Constants.ACCEPTOR_MERCHANT_RT
      );

      //Check duplicates in the bulk list
      for (ER_Acceptor__c a : acceptors) {
        if (a.RecordTypeId == acceptorRTId) {
          //Check for TID
          String keyTID = a.ER_BUPicklist__c + '_' + a.ER_TID_Authorization__c + '_' + a.ER_Acceptor_Scheme__c;
          if (!mapKeyAcceptors.containsKey(keyTID)) {
            mapKeyAcceptors.put(keyTID, a);
            setTIDs.add(a.ER_TID_Authorization__c);
          } else
            a.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_TIDs);

          //Check for MID and Sub Mid Authorization only Master Card
          if (
            a.ER_Acceptor_Scheme__c.equalsIgnoreCase(Constants.MASTERCARD) && String.isNotBlank(a.ER_Acceptor_Scheme__c)
          ) {
            //Check should be made org wide
            String keyMID = a.ER_BUPicklist__c + '_' + a.ER_MID_Authorization__c;
            String keySub_MID =
              a.ER_BUPicklist__c +
              '_' +
              a.ER_MID_Authorization__c +
              '_' +
              a.ER_SubMID_Authorization__c;
            if (!mapKeyAcceptors.containsKey(keyMID)) {
              mapKeyAcceptors.put(keyMID, a);
              setMIDs.add(a.ER_MID_Authorization__c);
            } else if (String.isBlank(a.ER_SubMID_Authorization__c))
              a.addError(Label.LAB_SF_ACCEPTOR_Sub_MIDs_REQUIRED);

            if (!mapKeyAcceptors.containsKey(keySub_MID)) {
              mapKeyAcceptors.put(keySub_MID, a);
              setMIDs.add(a.ER_MID_Authorization__c);
            } else
              a.addError(Label.LAB_SF_BENELUX_DUPLICATE_ACCEPTOR_MIDs);
          }
        }
      }

      //Check duplicates with database data
      for (ER_Acceptor__c a : [
        SELECT
          Id,
          ER_TID_Authorization__c,
          ER_Acceptor_Scheme__c,
          ER_Status__c,
          ER_BUPicklist__c,
          ER_MID_Authorization__c,
          ER_SubMID_Authorization__c,
          ER_Store__c
        FROM ER_Acceptor__c
        WHERE
          ER_Status__c = :Constants.ACTIVE
          AND (ER_TID_Authorization__c IN :setTIDs
          OR (ER_MID_Authorization__c IN :setMIDs
          AND ER_Acceptor_Scheme__c = :Constants.MASTERCARD))
      ]) {
        //Check for TID
        String keyTID = a.ER_BUPicklist__c + '_' + a.ER_TID_Authorization__c + '_' + a.ER_Acceptor_Scheme__c;
        ER_Acceptor__c newItem = mapKeyAcceptors.get(keyTID);
        if (mapKeyAcceptors.containsKey(keyTID) && String.isNotBlank(a.ER_TID_Authorization__c) && a.Id != newItem.Id)
          newItem.addError(Label.LAB_SF_DUPLICATE_ACCEPTOR_TIDs);

        //Check for MID and Sub Mid Authorization only Master Card
        String keyMID = a.ER_BUPicklist__c + '_' + a.ER_MID_Authorization__c;
        String keySub_MID = a.ER_BUPicklist__c + '_' + a.ER_MID_Authorization__c + '_' + a.ER_SubMID_Authorization__c;
        newItem = mapKeyAcceptors.get(keyMID);
        if (
          mapKeyAcceptors.containsKey(keyMID) &&
          String.isNotBlank(mapKeyAcceptors.get(keyMID).ER_Acceptor_Scheme__c) &&
          mapKeyAcceptors.get(keyMID).ER_Acceptor_Scheme__c.equalsIgnoreCase(Constants.MASTERCARD) &&
          String.isBlank(mapKeyAcceptors.get(keyMID).ER_SubMID_Authorization__c) &&
          a.Id != newItem.Id
        )
          newItem.addError(Label.LAB_SF_ACCEPTOR_Sub_MIDs_REQUIRED);

        if (
          mapKeyAcceptors.containsKey(keySub_MID) &&
          String.isNotBlank(mapKeyAcceptors.get(keySub_MID).ER_Acceptor_Scheme__c) &&
          mapKeyAcceptors.get(keySub_MID).ER_Acceptor_Scheme__c.equalsIgnoreCase(Constants.MASTERCARD) &&
          String.isNotBlank(mapKeyAcceptors.get(keySub_MID).ER_SubMID_Authorization__c) &&
          a.Id != newItem.Id
        )
          newItem.addError(Label.LAB_SF_BENELUX_DUPLICATE_ACCEPTOR_MIDs);
      }
    }
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Check the Acceptor Uniqueness
   * @param acceptors
   * @param oldMap
   */
  public static void checkAcceptorUniqueness(List<ER_Acceptor__c> acceptors, Map<Id, ER_Acceptor__c> oldMap) {
    if (!UtilsBypass.getCurrentUser().ER_BypassVR__c) {
      List<ER_Acceptor__c> acceptorsERPL = new List<ER_Acceptor__c>();
      List<ER_Acceptor__c> acceptorsERES = new List<ER_Acceptor__c>();
      List<ER_Acceptor__c> acceptorsERBENELUX = new List<ER_Acceptor__c>();
      List<ER_Acceptor__c> acceptorsERGR = new List<ER_Acceptor__c>();
      List<String> ERPLDuplicateModel = Utils.getGlobalSettingsValueFromKey('AcceptorDuplicateModel_ERPL')
        ?.split(Constants.SEMICOLON);
      List<String> ERESDuplicateModel = Utils.getGlobalSettingsValueFromKey('AcceptorDuplicateModel_ERES')
        ?.split(Constants.SEMICOLON);
      List<String> ERBENELUXDuplicateModel = Utils.getGlobalSettingsValueFromKey('AcceptorDuplicateModel_ERBENELUX')
        ?.split(Constants.SEMICOLON);
      List<String> ERGRDuplicateModel = Utils.getGlobalSettingsValueFromKey('AcceptorDuplicateModel_ERGR')
        ?.split(Constants.SEMICOLON);
      for (ER_Acceptor__c a : acceptors) {
        if (ERPLDuplicateModel != null && ERPLDuplicateModel.contains(a.ER_BUPicklist__c))
          acceptorsERPL.add(a);
        else if (ERESDuplicateModel != null && ERESDuplicateModel.contains(a.ER_BUPicklist__c))
          acceptorsERES.add(a);
        else if (
          ERBENELUXDuplicateModel != null &&
          ERBENELUXDuplicateModel.contains(a.ER_BUPicklist__c) &&
          a.ER_Status__c.equalsIgnoreCase(Constants.ACTIVE)
        )
          acceptorsERBENELUX.add(a);
        else if (ERGRDuplicateModel != null && ERGRDuplicateModel.contains(a.ER_BUPicklist__c))
          acceptorsERGR.add(a);
      }

      if (!acceptorsERPL.isEmpty())
        checkAcceptorUniquenessPL(acceptorsERPL, oldMap);
      if (!acceptorsERES.isEmpty())
        checkAcceptorUniquenessES(acceptorsERES);
      if (!acceptorsERBENELUX.isEmpty())
        checkAcceptorUniquenessBENELUX(acceptorsERBENELUX);
      if (!acceptorsERGR.isEmpty())
        checkAcceptorUniquenessGR(acceptorsERGR);
    }
  }

  /**
   * @author VJOY
   * @date 08/06/2021
   * @description Count Acceptor per Store
   * @param accsptors
   */
  public static void checkAndUpdateStore(List<ER_Acceptor__c> aAcceptorList) {
    Set<Id> storeToUpdateSet = new Set<Id>();
    List<ER_Store__c> storeToUpdateList = new List<ER_Store__c>();

    Id posRecordTypeId = Schema.SObjectType.ER_Acceptor__c.getRecordTypeInfosByDeveloperName()
      .get('Edenred_POS')
      .getRecordTypeId();
    List<String> statusList = new List<String>{ 'Created', 'Demo', 'Active', 'Lost/stolen', 'Blocked', 'Damaged' };

    for (ER_Acceptor__c acc : aAcceptorList) {
      if (acc.RecordTypeId == posRecordTypeId && acc.ER_Status__c != null && statusList.contains(acc.ER_Status__c))
        storeToUpdateSet.add(acc.ER_Store__c);
    }

    if (!storeToUpdateSet.isEmpty()) {
      for (ER_Store__c store : [SELECT Id, ER_Digital_Store__c FROM ER_Store__c WHERE Id IN :storeToUpdateSet]) {
        store.ER_Digital_Store__c = true;
        storeToUpdateList.add(store);
      }

      if (storeToUpdateSet.size() > 0)
        update storeToUpdateList;
    }
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Sync Acceptors with EDG v3
   * @param acceptors
   */
  public static void syncAcceptors(List<ER_Acceptor__c> acceptors, Map<Id, ER_Acceptor__c> oldAcceptor) {
    Set<Id> stores = new Set<Id>();
    Set<Id> accounts = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();
    Map<Id, String> accountsInputScope = new Map<Id, String>();

    if (!acceptors.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = acceptors[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;

    System.debug('APER23_ER_SyncStructureWS.alreadyExecutedSync : ' + ER_SyncStructureWS.alreadyExecutedSync);
    if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
      for (ER_Acceptor__c acc : acceptors) {
        ModifiedElements.add(acc.Id);
        if (acc.ER_Store__c != null && (acc.ER_Last_date_of_Sync__c == oldAcceptor.get(acc.Id).ER_Last_date_of_Sync__c))
          stores.add(acc.ER_Store__c);
      }

      if (!stores.isEmpty()) {
        for (ER_Store__c s : [
          SELECT Id, ER_Financial_Center__r.ER_Account_Name__c
          FROM ER_Store__c
          WHERE Id IN :stores AND ER_Creation_Date_In_OS__c != NULL
        ]) {
          accounts.add(s.ER_Financial_Center__r.ER_Account_Name__c);
          accountsInputScope.put(s.ER_Financial_Center__r.ER_Account_Name__c, 'merchant');
        }

        if (!accounts.isEmpty())
          System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', ModifiedElements, accountsInputScope));
      }
    }
  }

  /**
   * @author VJOY
   * @date 17/06/2021
   * @description Update Store Digital Status
   * @param aAcceptorList
   */
  public static void checkAndUpdateStoreStatus(List<ER_Acceptor__c> aAcceptorList) {
    Set<Id> storeToUpdateSet = new Set<Id>();
    List<ER_Store__c> storeToUpdateList = new List<ER_Store__c>();
    Id posRecordTypeId = Schema.SObjectType.ER_Acceptor__c.getRecordTypeInfosByDeveloperName()
      .get('Edenred_POS')
      .getRecordTypeId();

    for (ER_Acceptor__c acc : aAcceptorList) {
      if (acc.RecordtypeId == posRecordTypeId && acc.ER_Creation_date_in_OS__c != null)
        storeToUpdateSet.add(acc.ER_Store__c);
    }

    for (ER_Store__c store : [
      SELECT Id, ER_Digital_Store__c, ER_Digital_Store_Status__c
      FROM ER_Store__c
      WHERE Id IN :storeToUpdateSet
    ]) {
      if (store.ER_Digital_Store_Status__c == null || store.ER_Digital_Store_Status__c == '')
        store.ER_Digital_Store_Status__c = 'Created';
      storeToUpdateList.add(store);
    }

    if (storeToUpdateSet.size() > 0)
      update storeToUpdateList;
  }

  /**
   * @author KHAD
   * @date 08/06/2021
   * @description Update the creation date in ios field for Acceptor v3
   * @param newItems
   * @param oldItems
   */
  public static void syncAcceptorFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### syncAcceptorFlags Start');

    Map<Id, ER_Acceptor__c> newAcceptorMap = (Map<Id, ER_Acceptor__c>) newItems;
    Map<Id, ER_Acceptor__c> oldAcceptorMap = (Map<Id, ER_Acceptor__c>) oldItems;

    // Loop through the Acceptor lists and add fill the creation date in OS
    for (ER_Acceptor__c acc : newAcceptorMap.values()) {
      if (
        acc.ER_Sync_result__c != oldAcceptorMap.get(acc.Id).ER_Sync_result__c &&
        (acc.ER_Sync_result__c == 'synchronized' ||
        acc.ER_Sync_result__c == 'pending_synchronization') &&
        acc.ER_Creation_date_in_OS__c == null
      )
        acc.ER_Creation_date_in_OS__c = Datetime.now();
    }

    System.debug('### syncAcceptorFlags End');
  }

  /**
   * @author VJOY
   * @date 09/07/2021
   * @description
   * @param newItems
   * @param oldItems
   */
  public static void updateAcceptorAggregator(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### updateAcceptorAggregator Start');

    Map<Id, ER_Acceptor__c> newAcceptorMap = (Map<Id, ER_Acceptor__c>) newItems;
    Map<Id, ER_Acceptor__c> oldAcceptorMap = (Map<Id, ER_Acceptor__c>) oldItems;

    List<ER_Acceptor__c> acceptorToProcessList = new List<ER_Acceptor__c>();
    for (ER_Acceptor__c acc : newAcceptorMap.values()) {
      if (acc.Aggregator_Store__c != oldAcceptorMap.get(acc.Id).Aggregator_Store__c && acc.Aggregator_Store__c != null)
        acceptorToProcessList.add(acc);
    }

    if (acceptorToProcessList.size() > 0)
      updateAggregatorAcceptor(acceptorToProcessList);
    System.debug('### updateAcceptorAggregator End');
  }

  /**
   * @author VJOY
   * @date 09/07/2021
   * @description
   * @param newItems
   * @param oldItems
   */
  public static void updateAcceptorAggregatorOnInsert(List<ER_Acceptor__c> aAcceptorList) {
    System.debug('### updateAcceptorAggregatorOnInsert Start');

    List<ER_Acceptor__c> acceptorToProcessList = new List<ER_Acceptor__c>();
    for (ER_Acceptor__c acc : aAcceptorList) {
      if (acc.ER_Aggregator__c == null)
        acceptorToProcessList.add(acc);
    }

    if (acceptorToProcessList.size() > 0)
      updateAggregatorAcceptor(acceptorToProcessList);
    System.debug('### updateAcceptorAggregatorOnInsert End');
  }

  /**
   * @author VJOY
   * @date 09/07/2021
   * @description
   * @param acceptor list
   */
  public static void updateAggregatorAcceptor(List<ER_Acceptor__c> aAcceptorList) {
    System.debug('### updateAggregatorAcceptor Start');

    List<ER_Acceptor__c> acceptorList = new List<ER_Acceptor__c>();
    Map<Id, Id> storeIdByAcceptorIdMap = new Map<Id, Id>();
    Map<Id, Id> merchantIdByStoreIdMap = new Map<Id, Id>();
    Map<Id, Id> aggregatorIdByMerchantIdMap = new Map<Id, Id>();

    Set<Id> idStore = new Set<Id>();
    Set<Id> idAcc = new Set<Id>();
    List<ER_Acceptor__c> acceptorToUpdateList = new List<ER_Acceptor__c>();

    for (ER_Acceptor__c acc : aAcceptorList) {
      if (acc.Aggregator_Store__c != null) {
        acceptorList.add(acc);
        storeIdByAcceptorIdMap.put(acc.Id, acc.Aggregator_Store__c);
        idStore.add(acc.Aggregator_Store__c);
      }
    }

    for (ER_Store__c store : [SELECT Id, ER_Merchant__c FROM ER_Store__c WHERE Id IN :idStore]) {
      if (store.ER_Merchant__c != null)
        merchantIdByStoreIdMap.put(store.Id, store.ER_Merchant__c);
      idAcc.add(store.ER_Merchant__c);
    }

    for (AccountPartner accPartner : [
      SELECT Id, AccountFromId, AccountToId
      FROM AccountPartner
      WHERE AccountFromId IN :idAcc AND Role = 'Aggregator'
    ]) {
      aggregatorIdByMerchantIdMap.put(accPartner.AccountFromId, accPartner.AccountToId);
    }

    System.debug('1 ' + storeIdByAcceptorIdMap);
    System.debug('2 ' + merchantIdByStoreIdMap);
    System.debug('3 ' + aggregatorIdByMerchantIdMap);

    for (ER_Acceptor__c acc : aAcceptorList) {
      acc.ER_Aggregator__c = aggregatorIdByMerchantIdMap.get(
        merchantIdByStoreIdMap.get(storeIdByAcceptorIdMap.get(acc.Id))
      );
      acceptorToUpdateList.add(acc);
      System.debug('Setting: ' + acc.ER_Aggregator__c);
    }

    //if(acceptorToUpdateList.size() > 0) Database.update(acceptorToUpdateList);

    System.debug('### updateAggregatorAcceptor End');
  }

  /**
   * @author Noor
   * @date 26/11/2021
   * @description Rules for BU ES
   *              At the parent store level we should have at least one contact with contact role : Edenred End User App
   *              At contact level, the contact which have the role Edenred End User App should have an email address
   *              At the parent store level we should have the fields Latitude Longitude filled
   * @param acceptors new created acceptors
   */
  public static void addBlockingRulesForEdenredPOS(List<ER_Acceptor__c> acceptors) {
    System.debug('//NGO : addBlockingRulesForEdenredPOS' + acceptors);
    Set<Id> storeSet = new Set<Id>();
    List<ER_Acceptor__c> electedAcceptors = new List<ER_Acceptor__c>();
    Id posRecordTypeId = Utils.getRecordTypeIdByDeveloperName(ER_Acceptor__c.SObjectType, 'Edenred_POS');

    for (ER_Acceptor__c a : acceptors) {
      if (a.RecordTypeId == posRecordTypeId && a.ER_Business_Unit__c == 'ES') {
        storeSet.add(a.ER_Store__c);
        electedAcceptors.add(a);
      }
    }

    if (!electedAcceptors.isEmpty()) {
      Map<Id, ER_Store__c> mapStores = new Map<Id, ER_Store__c>(
        [
          SELECT
            Id,
            ER_Contact__c,
            ER_Contact__r.Email,
            ER_Latitude_Longitude__c,
            (SELECT Id, ER_Contact__c, ER_Role__c FROM ER_Contact_Roles__r WHERE ER_Role__c = 'Edenred End User App')
          FROM ER_Store__c
          WHERE Id IN :storeSet
        ]
      );

      for (ER_Acceptor__c acceptor : electedAcceptors) {
        String errorMessage = '';
        if (
          mapStores.containsKey(acceptor.ER_Store__c) &&
          mapStores.get(acceptor.ER_Store__c).ER_Latitude_Longitude__c == null
        )
          errorMessage = Label.LAB_SF_ACCEPTOR_VALIDATION_LAT_LON + '<br/>';

        if (
          mapStores.containsKey(acceptor.ER_Store__c) &&
          (String.isEmpty(mapStores.get(acceptor.ER_Store__c).ER_Contact__c) ||
          mapStores.get(acceptor.ER_Store__c).ER_Contact_Roles__r.isEmpty())
        )
          errorMessage += Label.LAB_SF_ACCEPTOR_VALIDATION_CONTACT_ROLE + '<br/>';

        if (
          mapStores.containsKey(acceptor.ER_Store__c) &&
          String.isEmpty(mapStores.get(acceptor.ER_Store__c).ER_Contact__r.Email)
        )
          errorMessage += Label.LAB_SF_ACCEPTOR_VALIDATION_CONTACT_EMAIL + '<br/>';

        if (String.isNotBlank(errorMessage))
          acceptor.addError(errorMessage);
      }
    }
  }

  /**
   * @author AAZ
   * @date 01/03/2022
   * @description Create Docugen records to be used for the contract template
   * @param acceptors
   */
  public static void createDocugenQuoteStoreAcceptor(List<ER_Acceptor__c> acceptors) {
    Map<Id, ER_Acceptor__c> mapAcceptors = new Map<Id, ER_Acceptor__c>(acceptors);
    Map<Id, Id> mapAcceptorAccount = new Map<Id, Id>();
    List<ER_Docugen_Quote_Store_Acceptor__c> docugenQuoteStoreAcceptors = new List<ER_Docugen_Quote_Store_Acceptor__c>();
    List<ER_Docugen_Quote_Store_Acceptor__c> docugenListToBeDeleted = new List<ER_Docugen_Quote_Store_Acceptor__c>();
    List<String> docusignDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.DOCUSIGN_DEPLOYED_BUS)
      ?.split(Constants.SEMICOLON);

    for (ER_Acceptor__c a : [
      SELECT
        Id,
        ER_BUPicklist__c,
        ER_Store__c,
        ER_Store__r.ER_Financial_Center__c,
        ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c
      FROM ER_Acceptor__c
      WHERE Id IN :mapAcceptors.keySet()
    ]) {
      if (
        docusignDeployedBUs != null &&
        (docusignDeployedBUs.contains(a.ER_BUPicklist__c) || docusignDeployedBUs.contains(Constants.ALL))
      ) {
        mapAcceptorAccount.put(a.Id, a.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c);
        mapAcceptors.put(a.Id, a);
      }
    }

    if (!mapAcceptorAccount.isEmpty()) {
      List<String> quotesStatuses = new List<String>{ Constants.DRAFT, Constants.PRESENTED };

      for (ER_Docugen_Quote_Store_Acceptor__c doc : [
        SELECT Id, ER_Acceptor__c, ER_Quote__r.AccountId
        FROM ER_Docugen_Quote_Store_Acceptor__c
        WHERE
          ER_Quote__r.AccountId IN :mapAcceptorAccount.values()
          AND ER_Quote__r.Opportunity.IsClosed = FALSE
          AND ER_Acceptor__c = NULL
          AND ER_Store__c != NULL
      ]) {
        docugenListToBeDeleted.add(doc);
      }

      if (!Test.isRunningTest()) {
        for (Quote q : [
          SELECT Id, AccountId
          FROM Quote
          WHERE
            AccountId IN :mapAcceptorAccount.values()
            AND Status IN :quotesStatuses
            AND Opportunity.IsClosed = FALSE
            AND RecordType.DeveloperName = :Constants.QUOTE_MERCHANT_RT
        ]) {
          for (Id aId : mapAcceptorAccount.keySet()) {
            if (q.AccountId == mapAcceptorAccount.get(aId)) {
              docugenQuoteStoreAcceptors.add(
                new ER_Docugen_Quote_Store_Acceptor__c(
                  ER_Quote__c = q.Id,
                  ER_Financial_Center__c = mapAcceptors.get(aId).ER_Store__r.ER_Financial_Center__c,
                  ER_Store__c = mapAcceptors.get(aId).ER_Store__c,
                  ER_Acceptor__c = aId
                )
              );
            }
          }
        }
      }

      if (!docugenListToBeDeleted.isEmpty())
        delete docugenListToBeDeleted;
      if (!docugenQuoteStoreAcceptors.isEmpty())
        insert docugenQuoteStoreAcceptors;
    }
  }

  /**
   * @author Noor
   * @date 01/04/2022
   * @description generate MID Authorization
   * @param acceptors
   */
  public static void generateMID_TID_Authorization(List<ER_Acceptor__c> acceptors) {
    List<ER_Acceptor__c> updatedAcceptorsCTAP = new List<ER_Acceptor__c>();
    Set<Id> storeIds = new Set<Id>();

    Long previousUniqueId = 0;
    for (ER_Acceptor__c a : acceptors) {
      if (
        String.isNotBlank(a.ER_Business_Unit__c) &&
        a.ER_Business_Unit__c.equalsIgnoreCase(Constants.BENELUX) &&
        String.isNotBlank(a.ER_Acceptor_Scheme__c)
      ) {
        Long uniqueId = generateCode();
        if (uniqueId <= previousUniqueId)
          uniqueId = previousUniqueId + 1;
        if (a.ER_Acceptor_Scheme__c.equalsIgnoreCase(Constants.C_TAP)) {
          updatedAcceptorsCTAP.add(a);
          storeIds.add(a.ER_Store__c);
        } else if (a.ER_Acceptor_Scheme__c.equalsIgnoreCase(Constants.WEBAUTH)) {
          a.ER_TID_Authorization__c = Label.LAB_SF_ACCEPTOR_WEBAUTH + uniqueId;
          a.ER_MID_Authorization__c = String.valueOf(uniqueId) + String.valueOf(Math.mod(uniqueId, 97));
          a.ER_MID_Clearing__c = String.valueOf(uniqueId) + String.valueOf(Math.mod(uniqueId, 97));
          a.Name = Label.LAB_SF_ACCEPTOR_WEBAUTH + String.valueOf(uniqueId);
        } else if (a.ER_Acceptor_Scheme__c.equalsIgnoreCase(Constants.MASTERCARD)) {
          a.Name = Label.LAB_SF_ACCEPTOR_MASTERCARD_PREFIX + a.ER_MID_Authorization__c;
          a.ER_TID_Authorization__c = Label.LAB_SF_ACCEPTOR_WEBAUTH + uniqueId;
          a.ER_MID_Clearing__c = a.ER_MID_Authorization__c;
          a.ER_Sub_MID_Clearing__c = a.ER_SubMID_Authorization__c;
        }
        previousUniqueId = uniqueId;
      }
    }

    if (!updatedAcceptorsCTAP.isEmpty()) {
      Map<Id, ER_Acceptor__c> storeAcceptorMap = new Map<Id, ER_Acceptor__c>();

      for (ER_Acceptor__c a : [
        SELECT Id, ER_Store__c, ER_MID_Authorization__c
        FROM ER_Acceptor__c
        WHERE ER_Store__c IN :storeIds AND ER_Acceptor_Scheme__c = :Constants.C_TAP
      ]) {
        storeAcceptorMap.put(a.ER_Store__c, a);
      }

      for (ER_Acceptor__c a : updatedAcceptorsCTAP) {
        if (String.isBlank(a.ER_MID_Authorization__c)) {
          if (storeAcceptorMap.containsKey(a.ER_Store__c))
            a.ER_MID_Authorization__c = storeAcceptorMap.get(a.ER_Store__c).ER_MID_Authorization__c;
          else
            a.ER_MID_Authorization__c = String.valueOf(generateCode());
        }

        a.ER_MID_Clearing__c = a.ER_MID_Authorization__c;
        a.ER_AID_Authorization__c = Label.LAB_SF_ACCEPTOR_AID_DEFAULT;
        a.ER_AID_Clearing__c = Label.LAB_SF_ACCEPTOR_AID_DEFAULT;
        a.Name = a.ER_TID_Authorization__c;
      }
    }
  }

  /**
   * @author Noor
   * @date 05/08/2022
   * @description generate code for MID with 8 characters
   * @return
   */
  public static Long generateCode() {
    String timestamp = String.valueOf(DateTime.now().getTime());
    return Long.valueOf(timestamp.left(8)) + Long.valueOf(timestamp.right(5));
  }

  /**
   * @author AAM
   * @date 01/03/2023
   * @description Update the flags for MID in the store that indicates missing MID
   * @param newItems
   */
  public static void updateMIDFlag(List<ER_Acceptor__c> newItems) {
    System.debug('### updateMIDFlag Start');

    Set<ID> storesIdOnlineSet = new Set<ID>();
    Set<ID> storesIdPhysicalSet = new Set<ID>();

    // Loop through the Acceptor lists and add fill the creation date in OS
    for (ER_Acceptor__c acc : newItems) {
      if (!String.isBlank(acc.ER_MID_Authorization__c) && acc.ER_Acceptor_Scheme__c == 'MasterCard') {
        if (acc.ER_Acceptor_Type__c == 'Payment Gate')
          storesIdOnlineSet.add(acc.ER_Store__c);
        if (acc.ER_Acceptor_Type__c == 'POS')
          storesIdPhysicalSet.add(acc.ER_Store__c);
      }
    }

    if (!storesIdOnlineSet.isEmpty() || !storesIdPhysicalSet.isEmpty()) {
      List<ER_Store__c> storeUpdList = new List<ER_Store__c>();
      Boolean addStore;
      for (ER_Store__c st : [
        SELECT Id, ER_Has_Unregistered_Online_MID__c, ER_Has_Unregistered_Physical_MID__c
        FROM ER_Store__c
        WHERE
          (Id IN :storesIdOnlineSet
          OR Id IN :storesIdPhysicalSet)
          AND (ER_Has_Unregistered_Online_MID__c = TRUE
          OR ER_Has_Unregistered_Physical_MID__c = TRUE)
      ]) {
        addStore = false;
        if (st.ER_Has_Unregistered_Online_MID__c && storesIdOnlineSet.contains(st.Id)) {
          st.ER_Has_Unregistered_Online_MID__c = false;
          addStore = true;
        }
        if (st.ER_Has_Unregistered_Physical_MID__c && storesIdPhysicalSet.contains(st.Id)) {
          st.ER_Has_Unregistered_Physical_MID__c = false;
          addStore = true;
        }

        if (addStore)
          storeUpdList.add(st);
      }

      if (!storeUpdList.isEmpty())
        update storeUpdList;
    }

    System.debug('### updateMIDFlag End');
  }
}