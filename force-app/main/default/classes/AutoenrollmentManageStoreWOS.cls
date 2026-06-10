/**
 * @description       :
 * @author            : AAM
 * @group             :
 * @last modified on  : 08-30-2023
 * @last modified by  : Hassan DAKHCHA
 **/
public without sharing class AutoenrollmentManageStoreWOS {
  /**
   * @description : process manage store events
   * @author Hassan DAKHCHA | 06-19-2023
   * @param insertedEvents
   **/
  public static void manageStoreEvents(List<Guest_Event__e> insertedEvents) {
    for (Guest_Event__e event : insertedEvents) {
      switch on event.Operation_Name__c {
        when 'manageStoreCreation' {
          createStore(event.Operation_Parameters__c);
        }
        when 'manageStoreInfoSave' {
          updateStoreInfo(event.Operation_Parameters__c);
        }
        when 'manageStoreActivitySave' {
          updateStoreActivities(event.Operation_Parameters__c);
        }
      }
    }
  }

  /**
   * @description : creates stores, contact and categories
   * @author Hassan DAKHCHA | 06-18-2023
   * @param params
   **/
  public static void createStore(String params) {
    // extract params
    // String storeId, String fcId, String storeInfosArg, String chosenCategories, String mainActivity
    if (String.isBlank(params)) {
      return;
    }
    Map<String, Object> paramList = (Map<String, Object>) JSON.deserializeUntyped(params);
    string fcId = (String) paramList.get('fcid');
    Map<String, Object> storeInfos = (Map<String, Object>) paramList.get('store');
    List<String> chosenCategories = ((String) paramList.get('categories')).split(Constants.PIPE_SEPARATOR);
    String mainActivity = (String) paramList.get('maincategory');

    System.debug('>>> createdStore fcId ' + fcId);
    System.debug('>>> createdStore storeInfos ' + storeInfos);
    System.debug('>>> createdStore chosenCategories ' + chosenCategories);
    System.debug('>>> createdStore mainActivity ' + mainActivity);
    // Check the FC id :
    try {
      List<ER_Financial_Center__c> fcL = [
        SELECT ER_Account_Name__c, ER_Contact__r.email, ER_Contact__c, ER_BUPicklist__c
        FROM ER_Financial_Center__c
        WHERE id = :fcId
      ];
      if (fcL.isEmpty()) {
        return;
      }

      APER30_AutoEnrollment_Management.syncRecordBU = fcL[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)

      ER_Store__c store = new ER_Store__c();
      store.name = String.valueOf(storeInfos.get('name'));
      store.ER_Street__c = String.valueOf(storeInfos.get('street'));
      store.ER_City__c = String.valueOf(storeInfos.get('city'));
      store.ER_Zip_Code__c = String.valueOf(storeInfos.get('postalCode'));
      store.ER_Country_Code__c = String.valueOf(storeInfos.get('country'));
      store.ER_Facebook__c = String.valueOf(storeInfos.get('facebook'));
      store.ER_Website_URL__c = String.valueOf(storeInfos.get('website'));
      store.ER_Store_Phone_Number__c = String.valueOf(storeInfos.get('phone'));
      store.ER_Email__c = String.valueOf(storeInfos.get('email'));
      store.ER_Financial_Center__c = fcId;
      store.recordTypeid = Utils.getRecordTypeIdByDeveloperName(ER_Store__c.SObjectType, Constants.STORE_MERCHANT_RT);
      store.ER_Merchant__c = fcL[0].ER_Account_Name__c;
      store.ER_BUPicklist__c = store.ER_Country_Code__c;
      store.ER_Status__c = Constants.ACTIVE;
      store.ER_Country__c = store.ER_Country_Code__c;

      String firstName = String.valueOf(storeInfos.get('firstName'));
      String lastName = String.valueOf(storeInfos.get('lastName'));
      String email = String.valueOf(storeInfos.get('ctcEmail'));
      String phone = String.valueOf(storeInfos.get('ctcPhone'));

      Map<String, Contact> contactsMap = getMapAccountContacts(fcL[0].ER_Account_Name__c);
      String currentKey = LastName.toLowerCase() + FirstName.toLowerCase() + email.toLowerCase();
      Contact existingContact = contactsMap.get(currentKey);
      if (existingContact != null) {
        store.ER_Contact__c = existingContact.id;
      } else {
        // Add new contact :
        // check if the contact is under Account:
        Account acc = [
          SELECT id, BillingStreet, BillingCity, BillingCountry, BillingPostalCode
          FROM Account
          WHERE id = :fcL[0].ER_Account_Name__c
        ];
        // Create New contact :
        Contact ctc = new Contact(
          accountId = fcL[0].ER_Account_Name__c,
          title = 'Mx',
          email = email,
          firstName = firstName,
          lastName = lastName,
          phone = phone,
          MobilePhone = phone,
          ER_Status__c = Constants.ACTIVE,
          MailingCity = acc.BillingCity,
          MailingPostalCode = acc.BillingPostalCode,
          MailingStreet = acc.BillingStreet,
          MailingCountry = acc.BillingCountry
        );
        dataBase.SaveResult sr = database.insert(ctc);
        if (sr.isSuccess()) {
          System.debug('>>> New contact created ' + ctc);
          store.ER_Contact__c = ctc.id;
        } else
          store.ER_Contact__c = fcL[0].ER_Contact__c;
      }

      insert (store);

      // Create Store categories :
      createStoreCategories(store.id, store.ER_Country_Code__c, chosenCategories, mainActivity);
    } catch (Exception ex) {
      System.debug('Exception message: ' + ex.getMessage());
    }
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-20-2023
   * @param params
   **/
  public static void updateStoreInfo(String params) {
    // extract params
    // String storeId, String fcId, String storeInfosArg, String chosenCategories, String mainActivity
    if (String.isBlank(params)) {
      return;
    }
    try {
      Map<String, Object> paramList = (Map<String, Object>) JSON.deserializeUntyped(params);
      string storeId = (String) paramList.get('id');
      if (String.isBlank(storeId))
        return;
      Map<String, Object> storeInfos = (Map<String, Object>) paramList.get('storeInfos');

      System.debug('>>> saved store ' + storeId);
      System.debug('>>> saved store info ' + storeInfos);

      ER_Store__c store = [SELECT id, ER_Merchant__c, ER_BUPicklist__c FROM ER_Store__c WHERE id = :storeId];
      APER30_AutoEnrollment_Management.syncRecordBU = store.ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)

      store.name = String.valueOf(storeInfos.get('name'));
      store.ER_Street__c = String.valueOf(storeInfos.get('street'));
      store.ER_City__c = String.valueOf(storeInfos.get('city'));
      store.ER_Zip_Code__c = String.valueOf(storeInfos.get('postalCode'));
      store.ER_Country_Code__c = String.valueOf(storeInfos.get('country'));
      store.ER_Facebook__c = String.valueOf(storeInfos.get('facebook'));
      store.ER_Website_URL__c = String.valueOf(storeInfos.get('website'));
      store.ER_Store_Phone_Number__c = String.valueOf(storeInfos.get('phone'));
      store.ER_Email__c = String.valueOf(storeInfos.get('email'));
      store.ER_Status__c = String.valueOf(storeInfos.get('status'));
      store.ER_BUPicklist__c = store.ER_Country_Code__c;
      store.ER_Country__c = store.ER_Country_Code__c;

      String firstName = String.valueOf(storeInfos.get('firstName'));
      String lastName = String.valueOf(storeInfos.get('lastName'));
      String email = String.valueOf(storeInfos.get('ctcEmail'));
      String phone = String.valueOf(storeInfos.get('ctcPhone'));

      Map<String, Contact> contactsMap = getMapAccountContacts(store.ER_Merchant__c);
      String currentKey = LastName.toLowerCase() + FirstName.toLowerCase() + email.toLowerCase();
      System.debug('>>> currentKey ' + currentKey);
      Contact existingContact = contactsMap.get(currentKey);
      if (existingContact != null) {
        database.update(
          new Contact(
            id = existingContact.id,
            firstName = FirstName,
            lastName = lastName,
            phone = phone,
            MobilePhone = phone,
            ER_Status__c = Constants.ACTIVE
          )
        );
        store.ER_Contact__c = existingContact.id;
      } else {
        // Add new contact :
        // check if the contact is under Account:
        Account acc = [
          SELECT id, BillingStreet, BillingCity, BillingCountry, BillingPostalCode
          FROM Account
          WHERE id = :store.ER_Merchant__c
        ];
        // Create New contact :
        Contact ctc = new Contact(
          accountId = store.ER_Merchant__c,
          title = 'Mx',
          email = email,
          firstName = firstName,
          lastName = lastName,
          phone = phone,
          MobilePhone = phone,
          ER_Status__c = Constants.ACTIVE,
          MailingCity = acc.BillingCity,
          MailingPostalCode = acc.BillingPostalCode,
          MailingStreet = acc.BillingStreet,
          MailingCountry = acc.BillingCountry
        );
        dataBase.SaveResult sr = database.insert(ctc);
        if (sr.isSuccess()) {
          System.debug('>>> New contact created ' + ctc);
          store.ER_Contact__c = ctc.id;
        }
      }

      update (store);
    } catch (Exception ex) {
      System.debug('Exception message: ' + ex.getMessage());
    }
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-18-2023
   * @param AccountId
   * @return Map<String, Contact>
   **/
  private static Map<String, Contact> getMapAccountContacts(Id AccountId) {
    List<Contact> ctcList = [
      SELECT id, firstName, lastName, phone, email
      FROM Contact
      WHERE AccountId = :AccountId
      ORDER BY lastModifiedDate DESC
    ];
    Map<String, Contact> resultMap = new Map<String, Contact>();
    if (ctcList.isEmpty())
      return resultMap;

    for (Contact ctc : ctcList) {
      String key = ctc.lastName.toLowerCase() + ctc.firstName.toLowerCase() + ctc.email.toLowerCase();
      System.debug('>>> key contact ' + key + ' /' + ctc);
      resultMap.put(key, ctc);
    }
    return resultMap;
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-18-2023
   * @param chosenCategories
   * @param mainActivity
   **/
  private static void createStoreCategories(id storeId, String bu, List<String> chosenCategories, String mainActivity) {
    List<ER_StoreCategory__c> sCat = new List<ER_StoreCategory__c>();
    for (String cat : chosenCategories) {
      System.debug('>>> creating Cat ' + cat + ' / list => ' + chosenCategories + ' / Main => ' + mainActivity);
      sCat.add(
        new ER_StoreCategory__c(
          Store__c = storeId,
          Category__c = cat,
          ER_BUPicklist__c = bu,
          main_category__c = cat == mainActivity ? true : false
        )
      );
    }
    APER30_AutoEnrollment_Management.syncRecordBU = bu; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Database.insert(sCat);
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-21-2023
   * @param params
   **/
  public static void updateStoreActivities(String params) {
    // extract params
    // String storeId, String fcId, String storeInfosArg, String chosenCategories, String mainActivity
    if (String.isBlank(params))
      return;

    try {
      Map<String, Object> paramList = (Map<String, Object>) JSON.deserializeUntyped(params);
      string storeId = (String) paramList.get('id');

      if (String.isBlank(storeId))
        return;

      Set<String> chosenCategories = new Set<String>(
        ((String) paramList.get('categories')).split(Constants.PIPE_SEPARATOR)
      );
      String mainActivity = (String) paramList.get('maincategory');

      System.debug('>>> updateStoreActivities chosenCategories ' + chosenCategories);
      System.debug('>>> updateStoreActivities mainActivity ' + mainActivity);

      // get current categories :
      List<ER_StoreCategory__c> catToUpdate = new List<ER_StoreCategory__c>();
      List<ER_StoreCategory__c> catToDelete = new List<ER_StoreCategory__c>();
      String currentBU;

      for (ER_StoreCategory__c cat : [
        SELECT id, Main_Category__c, Category__c, Store__r.ER_BUPicklist__c
        FROM ER_StoreCategory__c
        WHERE Store__c = :storeId
      ]) {
        // delete non chosen cat
        if (!chosenCategories.contains((String) cat.Category__c)) {
          catToDelete.add(cat);
          continue;
        }
        System.debug('>>> loop  ' + cat);

        // Skip existing cat
        chosenCategories.remove((String) cat.Category__c);
        System.debug('>>> loop 1 ' + chosenCategories);

        if (mainActivity == (String) cat.Category__c && !cat.Main_Category__c) {
          catToUpdate.add(new ER_StoreCategory__c(id = cat.id, Main_Category__c = true));
        }
        if (mainActivity != (String) cat.Category__c && cat.Main_Category__c) {
          catToUpdate.add(new ER_StoreCategory__c(id = cat.id, Main_Category__c = false));
        }
        currentBU = cat.Store__r.ER_BUPicklist__c;
      }

      if (!String.isBlank(currentBU))
        APER30_AutoEnrollment_Management.syncRecordBU = currentBU; // AAM 07.07.23 COUL-4145 (EDG Sync)

      if (!catToDelete.isEmpty()) {
        Database.delete(catToDelete);
      }

      if (!catToUpdate.isEmpty())
        database.update(catToUpdate);

      if (!chosenCategories.isEmpty()) {
        ER_Store__c store = [SELECT id, ER_Country_Code__c FROM ER_Store__c WHERE id = :storeId];
        createStoreCategories(store.id, store.ER_Country_Code__c, new List<String>(chosenCategories), mainActivity);
      }
    } catch (Exception ex) {
      System.debug('Exception message: ' + ex.getMessage());
    }
  }
}