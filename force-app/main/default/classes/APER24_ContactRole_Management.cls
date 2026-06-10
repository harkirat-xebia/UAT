/**
 * @description       :
 * @author            : AAM
 * @group             :
 * @last modified on  : 17-07-2023
 * @last modified by  : AAM
 **/
public class APER24_ContactRole_Management {
  public static Boolean bypassDeletePrimaryContactRole = true;
  public static void CreatePrimaryContactRole(List<Sobject> sObjList) {
    if (UtilsBypass.canTrigger('CreatePrimaryContactRole')) {
      ER_Contact_Role__c cr;
      ER_Financial_Center__c FC;
      ER_Store__c storeRecord;
      ER_Delivery_Site__c deliverySiteRecord;
      ER_Distribution_Point__c distributionPointRecord;

      Id parentId;
      String contactId;
      List<ER_Contact_Role__c> crToInsert = new List<ER_Contact_Role__c>();

      for (Sobject obj : sObjList) {
        parentId = obj.id;
        String objectName = parentId.getSobjectType().getDescribe().getName();
        cr = new ER_Contact_Role__c();
        cr.ER_Primary__c = true;

        if (objectName.equalsIgnoreCase('ER_Financial_Center__c')) {
          FC = (ER_Financial_Center__c) obj;
          cr.ER_Financial_Center__c = parentId;
          cr.ER_Contact__c = FC.ER_Contact__c;
          cr.ER_BUPicklist__c = FC.ER_BUPicklist__c; // AAM-18.02.22 PBI#14166

          if (FC.ER_Type__c == 'Merchant') {
            cr.RecordTypeId = Schema.SObjectType.ER_Contact_Role__c.getRecordTypeInfosByDeveloperName()
              .get('ER_CR_Financial_Center_Merchant')
              .getRecordTypeId();
            if (FC.ER_Business_Unit__c == 'ES')
              cr.ER_Role__c = Label.LAB_SF_CR_Invoicing;
          } else {
            cr.RecordTypeId = Schema.SObjectType.ER_Contact_Role__c.getRecordTypeInfosByDeveloperName()
              .get('ER_CR_Financial_Center_Client')
              .getRecordTypeId();
          }
        } else if (objectName.equalsIgnoreCase('ER_Store__c')) {
          storeRecord = (ER_Store__c) obj;
          cr.ER_Contact__c = storeRecord.ER_Contact__c;
          cr.ER_Store__c = parentId;
          cr.RecordTypeId = Schema.SObjectType.ER_Contact_Role__c.getRecordTypeInfosByDeveloperName()
            .get('ER_CR_Store')
            .getRecordTypeId();
          cr.ER_BUPicklist__c = storeRecord.ER_BUPicklist__c; // AAM-18.02.22 PBI#14166
        } else if (objectName.equalsIgnoreCase('ER_Delivery_Site__c')) {
          deliverySiteRecord = (ER_Delivery_Site__c) obj;
          cr.ER_Contact__c = deliverySiteRecord.ER_Delivery_Contact__c;
          cr.ER_Delivery_Site__c = parentId;
          cr.RecordTypeId = Schema.SObjectType.ER_Contact_Role__c.getRecordTypeInfosByDeveloperName()
            .get('ER_CR_Delivery_Site')
            .getRecordTypeId();
          cr.ER_BUPicklist__c = deliverySiteRecord.ER_BUPicklist__c;
        } else if (objectName.equalsIgnoreCase('ER_Distribution_Point__c')) {
          distributionPointRecord = (ER_Distribution_Point__c) obj;
          cr.ER_Contact__c = distributionPointRecord.ER_Contact__c;
          cr.ER_Distribution_Point__c = parentId;
          cr.RecordTypeId = Schema.SObjectType.ER_Contact_Role__c.getRecordTypeInfosByDeveloperName()
            .get('ER_CR_Distribution_Point')
            .getRecordTypeId();
        }

        if (String.isNotBlank(cr.ER_Contact__c)) {
          crToInsert.add(cr);
        }
      }
      if (!crToInsert.isEmpty()) {
        System.debug('### crToInsert : ' + crToInsert);
        ManageFinancialCenterWOS.createContactRole(crToInsert);
      }
    }
  }

  public static void updateContactRoleUpdate(
    List<ER_Financial_Center__c> aListContactRoleNew,
    Map<Id, ER_Financial_Center__c> fcOldMap
  ) {
    if (UtilsBypass.canTrigger('updateContactRoleUpdate')) {
      Map<Id, ER_Financial_Center__c> contactRoleToManage = new Map<Id, ER_Financial_Center__c>();

      if (!WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter) {
        for (ER_Financial_Center__c fc : aListContactRoleNew) {
          if (String.isNotBlank(fc.ER_Contact__c) && fc.ER_Contact__c != fcOldMap.get(fc.Id).ER_Contact__c) {
            contactRoleToManage.put(fc.Id, fc);
          }
        }
      }

      if (!contactRoleToManage.isEmpty())
        UpdatePrimaryContactRole(contactRoleToManage, fcOldMap);
    }
  }

  public static void UpdatePrimaryContactRole(Map<id, Sobject> objMap, Map<id, Sobject> objOldMap) {
    if (UtilsBypass.canTrigger('UpdatePrimaryContactRole')) {
      List<ER_Contact_Role__c> contactRoleToDelete = new List<ER_Contact_Role__c>();
      List<ER_Contact_Role__c> contactRoleToInsert = new List<ER_Contact_Role__c>();
      List<sObject> objListForNewContactRole = new List<sObject>();
      Map<String, List<ER_Contact_Role__c>> mapContactToContactRole;
      List<Map<String, List<ER_Contact_Role__c>>> listMapContactToContactRole;
      Map<String, List<Map<String, List<ER_Contact_Role__c>>>> mapOBJtoContact = new Map<String, List<Map<String, List<ER_Contact_Role__c>>>>();
      String crRecordType;
      String objectName;
      String newContactId;
      String oldContactId;

      //get all CR linked to updated Objects
      Map<id, ER_Contact_Role__c> crMap = new Map<id, ER_Contact_Role__c>(
        [
          SELECT
            id,
            ER_Primary__c,
            ER_Contact__c,
            ER_Financial_Center__c,
            ER_Store__c,
            ER_Distribution_Point__c,
            ER_Delivery_Site__c,
            RecordType.DeveloperName
          FROM ER_Contact_Role__c
          WHERE
            ER_Financial_Center__c IN :objMap.keySet()
            OR ER_Store__c IN :objMap.keySet()
            OR ER_Distribution_Point__c IN :objMap.keySet()
            OR ER_Delivery_Site__c IN :objMap.keySet()
        ]
      );

      //Build necessary Maps
      for (ER_Contact_Role__c cr : crMap.values()) {
        crRecordType = cr.RecordType.DeveloperName;
        mapContactToContactRole = new Map<String, List<ER_Contact_Role__c>>();
        if (
          crRecordType.equals('ER_CR_Financial_Center_Client') || crRecordType.equals('ER_CR_Financial_Center_Merchant')
        ) {
          if (!mapOBJtoContact.containsKey(cr.ER_Financial_Center__c))
            mapOBJtoContact.put(cr.ER_Financial_Center__c, new List<Map<String, List<ER_Contact_Role__c>>>());

          listMapContactToContactRole = mapOBJtoContact.get(cr.ER_Financial_Center__c);
          for (Map<String, List<ER_Contact_Role__c>> mapContactCR : listMapContactToContactRole) {
            if (mapContactCR.containsKey(cr.ER_Contact__c))
              mapContactToContactRole = mapContactCR;
          }

          if (!mapContactToContactRole.containsKey(cr.ER_Contact__c))
            mapContactToContactRole.put(cr.ER_Contact__c, new List<ER_Contact_Role__c>());
          mapContactToContactRole.get(cr.ER_Contact__c).add(cr);
          System.debug('mapContactToContactRole : ' + mapContactToContactRole);
          mapOBJtoContact.get(cr.ER_Financial_Center__c).add(mapContactToContactRole);
        } else if (crRecordType.equals('ER_CR_Store')) {
          if (!mapOBJtoContact.containsKey(cr.ER_Store__c))
            mapOBJtoContact.put(cr.ER_Store__c, new List<Map<String, List<ER_Contact_Role__c>>>());

          listMapContactToContactRole = mapOBJtoContact.get(cr.ER_Store__c);
          for (Map<String, List<ER_Contact_Role__c>> mapContactCR : listMapContactToContactRole) {
            if (mapContactCR.containsKey(cr.ER_Contact__c))
              mapContactToContactRole = mapContactCR;
          }

          if (!mapContactToContactRole.containsKey(cr.ER_Contact__c))
            mapContactToContactRole.put(cr.ER_Contact__c, new List<ER_Contact_Role__c>());
          mapContactToContactRole.get(cr.ER_Contact__c).add(cr);
          System.debug('mapContactToContactRole : ' + mapContactToContactRole);
          mapOBJtoContact.get(cr.ER_Store__c).add(mapContactToContactRole);
        } else if (crRecordType.equals('ER_CR_Delivery_Site')) {
          if (!mapOBJtoContact.containsKey(cr.ER_Delivery_Site__c))
            mapOBJtoContact.put(cr.ER_Delivery_Site__c, new List<Map<String, List<ER_Contact_Role__c>>>());

          listMapContactToContactRole = mapOBJtoContact.get(cr.ER_Delivery_Site__c);
          for (Map<String, List<ER_Contact_Role__c>> mapContactCR : listMapContactToContactRole) {
            if (mapContactCR.containsKey(cr.ER_Contact__c))
              mapContactToContactRole = mapContactCR;
          }

          if (!mapContactToContactRole.containsKey(cr.ER_Contact__c))
            mapContactToContactRole.put(cr.ER_Contact__c, new List<ER_Contact_Role__c>());
          mapContactToContactRole.get(cr.ER_Contact__c).add(cr);
          System.debug('mapContactToContactRole : ' + mapContactToContactRole);
          mapOBJtoContact.get(cr.ER_Delivery_Site__c).add(mapContactToContactRole);
        } else if (crRecordType.equals('ER_CR_Distribution_Point')) {
          if (!mapOBJtoContact.containsKey(cr.ER_Distribution_Point__c))
            mapOBJtoContact.put(cr.ER_Distribution_Point__c, new List<Map<String, List<ER_Contact_Role__c>>>());

          listMapContactToContactRole = mapOBJtoContact.get(cr.ER_Distribution_Point__c);
          for (Map<String, List<ER_Contact_Role__c>> mapContactCR : listMapContactToContactRole) {
            if (mapContactCR.containsKey(cr.ER_Contact__c))
              mapContactToContactRole = mapContactCR;
          }

          if (!mapContactToContactRole.containsKey(cr.ER_Contact__c))
            mapContactToContactRole.put(cr.ER_Contact__c, new List<ER_Contact_Role__c>());
          mapContactToContactRole.get(cr.ER_Contact__c).add(cr);
          System.debug('mapContactToContactRole : ' + mapContactToContactRole);
          mapOBJtoContact.get(cr.ER_Distribution_Point__c).add(mapContactToContactRole);
        }
      }
      System.debug('mapOBJtoContact : ' + mapOBJtoContact);
      ER_Contact_Role__c contactRole;
      for (sObject parentObj : objMap.values()) {
        objectName = parentObj.Id.getSobjectType().getDescribe().getName();
        if (objectName.equalsIgnoreCase('ER_Financial_Center__c')) {
          //
          newContactId = ((ER_Financial_Center__c) parentObj).ER_Contact__c;
          oldContactId = ((ER_Financial_Center__c) objOldMap.get(parentObj.id)).ER_Contact__c;
        } else if (objectName.equalsIgnoreCase('ER_Store__c')) {
          newContactId = ((ER_Store__c) parentObj).ER_Contact__c;
          oldContactId = ((ER_Store__c) objOldMap.get(parentObj.id)).ER_Contact__c;
        } else if (objectName.equalsIgnoreCase('ER_Delivery_Site__c')) {
          newContactId = ((ER_Delivery_Site__c) parentObj).ER_Delivery_Contact__c;
          oldContactId = ((ER_Delivery_Site__c) objOldMap.get(parentObj.id)).ER_Delivery_Contact__c;
        }
        if (objectName.equalsIgnoreCase('ER_Distribution_Point__c')) {
          newContactId = ((ER_Distribution_Point__c) parentObj).ER_Contact__c;
          oldContactId = ((ER_Distribution_Point__c) objOldMap.get(parentObj.id)).ER_Contact__c;
        }
        if (mapOBJtoContact.containsKey(parentObj.id)) {
          //The Object already have some Contact Roles
          System.debug('The Object already have some Contact Roles');
          if (mapOBJtoContact.containsKey(parentObj.id)) {
            for (Map<String, List<ER_Contact_Role__c>> mapContactCR : mapOBJtoContact.get(parentObj.id)) {
              if (mapContactCR.containsKey(oldContactId)) {
                for (List<ER_Contact_Role__c> crList : mapContactCR.values()) {
                  for (ER_Contact_Role__c cr : crList) {
                    if (cr.ER_Primary__c) {
                      cr.ER_Primary__c = false;
                      contactRoleToDelete.add(cr);
                    }
                  }
                }
              }
            }
            System.debug('Update old Contact role set primary to False');
            //Update old Contact role set primary to False
            //contactRole = crMap.get(mapOBJtoContact.get(parentObj.id).get(oldContactId));
            //contactRole.ER_Primary__c = false;
            //contactRoleToUpdate.add(contactRole);
          } /*
                    if(mapOBJtoContact.get(parentObj.id).containsKey(newContactId)){
                        System.debug('The Object new Main Contact already exist as Contact Role');
                        //The Object new Main Contact already exist as Contact Role
                        //Update contact Role to become Primary
                        contactRole = crMap.get(mapOBJtoContact.get(parentObj.id).get(newContactId));
                        contactRole.ER_Primary__c = true;
                        contactRoleToUpdate.add(contactRole);
                    } */
          //else{
          System.debug('The Object new Main Contact Does not exist as Contact Role');
          //The Object new Main Contact Does not exist as Contact Role
          //Create new Primary contact Role
          objListForNewContactRole.add(parentObj);
          //}
        } else {
          System.debug('Create new Primary Contact Role');
          //Create new Primary Contact Role
          objListForNewContactRole.add(parentObj);
        }
      }
      //insted of deleting the old pripary contact role on the ticket 16769 it was requested to keep it as secondary
      if (!contactRoleToDelete.isEmpty()) {
        System.debug('CONTACT ROLE UPDATE');
        bypassDeletePrimaryContactRole = false;
        GenericWithoutSharing.UpdateContactRoles(contactRoleToDelete);
        bypassDeletePrimaryContactRole = true;
      }

      if (!objListForNewContactRole.isEmpty()) {
        System.debug('CONTACT ROLE INSERT');
        CreatePrimaryContactRole(objListForNewContactRole);
      }
    }
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Sync Contact Roles to EDG v3
   * @param contactRoles
   */
  public static void syncContactRoles(
    List<ER_Contact_Role__c> contactRoles,
    Map<Id, ER_Contact_Role__c> oldContactRole
  ) {
    Set<Id> contacts = new Set<Id>();
    Set<Id> accounts = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();

    if (!contactRoles.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = contactRoles[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScope = new Map<Id, String>(); // enrich the scope
    System.debug(
      'Aper24_contactrole ER_SyncStructureWS.alreadyExecutedSync :' + ER_SyncStructureWS.alreadyExecutedSync
    );
    if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
      for (ER_Contact_Role__c cr : contactRoles) {
        //(cr.ER_Primary__c != oldContactRole.get(cr.Id).ER_Primary__c ) // don't sync in this case too ! it generates a 2nd call because the primary is unflaged when the contact is no longer primary
        //if(!cr.ER_Primary__c){
        if (
          ((oldContactRole == null || oldContactRole.isEmpty()) && !cr.ER_Primary__c) ||
          (oldContactRole != null &&
          (cr.ER_Last_date_of_Sync__c == oldContactRole.get(cr.Id).ER_Last_date_of_Sync__c) &&
          (cr.ER_Primary__c == oldContactRole.get(cr.Id).ER_Primary__c))
        ) {
          ModifiedElements.add(cr.Id);
          contacts.add(cr.ER_Contact__c);
        }
        //}
      }

      for (Contact c : [
        SELECT Id, AccountId
        FROM Contact
        WHERE Id IN :contacts AND Account.ER_Creation_date_in_OS__c != NULL
      ])
        accounts.add(c.AccountId);

      //if(!accounts.isEmpty()) ER_SyncStructureWithLegacy.syncContract(accounts, null, 'PUT');
      if (!accounts.isEmpty())
        System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', ModifiedElements, accountsInputScope));
    }
  }

  /**
   * @author KHAD
   * @date 08/06/2021
   * @description Update the creation date in ios field for contact role v3
   * @param newItems
   * @param oldItems
   */
  public static void syncContactRoleFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### syncContactRoleFlags Start');

    Map<Id, ER_Contact_Role__c> newContactMap = (Map<Id, ER_Contact_Role__c>) newItems;
    Map<Id, ER_Contact_Role__c> oldContactMap = (Map<Id, ER_Contact_Role__c>) oldItems;

    // Loop through the contact roles lists and add fill the creation date in OS
    for (ER_Contact_Role__c c : newContactMap.values()) {
      if (
        c.ER_Sync_result__c != oldContactMap.get(c.Id).ER_Sync_result__c &&
        (c.ER_Sync_result__c == 'synchronized' ||
        c.ER_Sync_result__c == 'pending_synchronization') &&
        c.ER_Creation_date_in_OS__c == null
      )
        c.ER_Creation_date_in_OS__c = Datetime.now();
    }

    System.debug('### syncContactRoleFlags End');
  }

  /**
   * @author VJOY
   * @date 08/10/2021
   * @description Avoid Primary contact role deletion
   * @param contactRoleList
   */
  public static void primaryContactDeleteErrorNotification(List<ER_Contact_Role__c> contactRoleList) {
    if (UtilsBypass.canTrigger('primaryContactDeleteErrorNotification') && bypassDeletePrimaryContactRole) {
      for (ER_Contact_Role__c cr : contactRoleList) {
        if (cr.ER_Primary__c)
          cr.adderror(Label.LAB_SF_Contact_Role_DeleteError);
      }
    }
  }
}