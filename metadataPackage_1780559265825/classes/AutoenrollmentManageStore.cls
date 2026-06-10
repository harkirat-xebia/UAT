public without sharing class AutoenrollmentManageStore {
  @AuraEnabled(cacheable=true)
  public static Map<String, Map<String, String>> getStoreCategories(String businessUnit, String lang) {
    Map<id, String> translatedRecords = new Map<id, String>();
    for (ER_Translation__c trans : [
      SELECT Dependent_Value__c, Text__c
      FROM ER_Translation__c
      WHERE
        Field_API_Name__c = 'ER_StoreCategory__c'
        AND Dependent_Value__r.ER_Business_Unit__c = :businessUnit
        AND Dependent_Value__r.ER_Status__c = 'Active'
        AND Language__c LIKE :lang + '%'
      ORDER BY Language__c, Dependent_Value__r.Level__c
    ]) {
      translatedRecords.put(trans.Dependent_Value__c, trans.Text__c);
    }

    Map<String, Map<String, String>> categoriesTranslationsMap = new Map<String, Map<String, String>>();
    Map<String, String> treeParentKeysMap = new Map<String, String>();
    Set<String> parentIdSet = new Set<String>();
    String parentId;
    System.debug('>>> getCategories - businessUnit : ' + businessUnit);
    for (ER_DependentValue__c category : [
      SELECT
        id,
        name,
        ER_Business_Unit__c,
        ER_Category_Code__c,
        ER_Object__c,
        ER_Ordering__c,
        ER_Status__c,
        Level__c,
        Parent_Dependent_Value__c,
        RecordTypeId,
        Solution_and_Service__c,
        Solution_and_Service__r.ProductCode
      FROM ER_DependentValue__c
      WHERE ER_Business_Unit__c = :businessUnit AND ER_Status__c = :Constants.ACTIVE AND ER_Object__c = 'Store Category'
      ORDER BY ER_Ordering__c
    ]) {
      // Build a list of "tree keys" composed by all parent Ids concatenated + current record Ids
      String curParent = category.Parent_Dependent_Value__c;
      parentId = (!String.isBlank(treeParentKeysMap.get(curParent))) ? treeParentKeysMap.get(curParent) + '*' : '';
      parentIdSet.add(curParent);

      treeParentKeysMap.put(category.id, parentId + category.id);

      String text = translatedRecords.get(category.id) == null ? category.Name : translatedRecords.get(category.id);
      categoriesTranslationsMap.put(
        treeParentKeysMap.get(category.id),
        new Map<String, String>{
          'id' => category.id,
          'name' => text,
          'level' => String.valueOf(category.Level__c),
          'solution' => category.Solution_and_Service__r.ProductCode
        }
      );
    }

    // Set IsParent for each category
    Boolean isParent;
    System.debug('parentIdSet: ' + parentIdSet);
    for (String treeKey : categoriesTranslationsMap.keySet()) {
      isParent = parentIdSet.contains(categoriesTranslationsMap.get(treeKey).get('id'));
      System.debug('Current Id ' + categoriesTranslationsMap.get(treeKey).get('id'));
      categoriesTranslationsMap.get(treeKey).put('isParent', String.valueOf(isParent));
      System.debug(treeKey + ' *** ' + categoriesTranslationsMap.get(treeKey));
    }
    return categoriesTranslationsMap;
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-19-2023
   * @param fcId
   * @return Map<String, String>
   **/
  @AuraEnabled
  public static Map<String, String> getFCContact(String fcId) {
    try {
      ER_Financial_Center__c fc = [
        SELECT id, ER_Contact__r.firstName, ER_Contact__r.lastName, ER_Contact__r.phone, ER_Contact__r.email
        FROM ER_Financial_Center__c
        WHERE id = :fcId
      ];
      return new Map<String, String>{
        'firstName' => fc.ER_Contact__r.firstName,
        'lastName' => fc.ER_Contact__r.lastName,
        'phone' => fc.ER_Contact__r.phone,
        'mail' => fc.ER_Contact__r.email
      };
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-19-2023
   * @param eventName
   * @param params
   **/
  @AuraEnabled
  public static void manageStoreEvent(String eventName, String params) {
    Guest_Event__e gevt = new Guest_Event__e();
    gevt.Operation_Name__c = eventName;
    gevt.Operation_Parameters__c = params;
    System.debug('>>> manageStoreEvent -- operation: ' + eventName);
    System.debug('>>> manageStoreEvent -- params:    ' + params);

    EventBus.publish(gevt);
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-20-2023
   * @param storeId
   * @return Map<String, String>
   **/
  @AuraEnabled
  public static Map<String, String> getStoreRecord(String storeId) {
    try {
      ER_Store__c store = [
        SELECT
          id,
          Name,
          ER_Financial_Center__c,
          ER_Street__c,
          ER_City__c,
          ER_Zip_Code__c,
          ER_Country__c,
          ER_Facebook__c,
          ER_Website_URL__c,
          ER_Status__c,
          ER_Country_Code__c,
          ER_Store_Phone_Number__c,
          ER_Email__c,
          ER_Contact__r.FirstName,
          ER_Contact__r.LastName,
          ER_Contact__r.Email,
          ER_Contact__r.phone
        FROM ER_Store__c
        WHERE id = :storeId
      ];
      return new Map<String, String>{
        'parentId' => store.ER_Financial_Center__c,
        'name' => store.Name,
        'status' => store.ER_Status__c,
        'street' => store.ER_Street__c,
        'city' => store.ER_City__c,
        'country' => store.ER_Country_Code__c,
        'postalCode' => store.ER_Zip_Code__c,
        'facebook' => store.ER_Facebook__c,
        'website' => store.ER_Website_URL__c,
        'phone' => store.ER_Store_Phone_Number__c,
        'email' => store.ER_Email__c,
        'firstName' => store.ER_Contact__r.firstName,
        'lastName' => store.ER_Contact__r.lastName,
        'ctcPhone' => store.ER_Contact__r.phone,
        'ctcEmail' => store.ER_Contact__r.email
      };
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-21-2023
   * @param storeId
   * @return List<ER_StoreCategory__c>
   **/
  @AuraEnabled
  public static List<ER_StoreCategory__c> getStoreActivities(String storeId) {
    try {
      return [
        SELECT Main_Category__c, Category__c, Category__r.Name
        FROM ER_StoreCategory__c
        WHERE Store__c = :storeId
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description
   * @author Hassan DAKHCHA | 06-21-2023
   * @param storeId
   * @return List<ER_Acceptor__c>
   **/
  @AuraEnabled
  public static List<ER_Acceptor__c> getStoreTerminals(String storeId) {
    try {
      return [
        SELECT ER_Status__c, ER_MID_Authorization__c, ER_SubMID_Authorization__c, Name
        FROM ER_Acceptor__c
        WHERE ER_Store__c = :storeId
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}