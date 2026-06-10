/**
 * Vershley Joyejob
 * 14/01/2021
 */

public with sharing class APER25_CategoriesHierarchyController {
  public static APER26_CategoriesHierarchyHelper service = new APER26_CategoriesHierarchyHelper();

  @AuraEnabled
  public static Map<String, Object> getCategoriesGraph(Id storeId) {
    Map<Id, ER_DependentValue__c> categories = service.getCategories(storeId);

    Map<String, Object> payload = new Map<String, Object>{
      'tree' => JSON.serialize(service.getCategoriesGraph(storeId, categories)),
      'languages' => service.getCategoriesLanguages(new List<Id>(categories.keySet()))
    };
    return payload;
  }

  @AuraEnabled
  public static Map<Id, String> getCategoriesTranslations(List<Id> categoriesIds, String selectedLanguage) {
    return service.getCategoriesTranslations(categoriesIds, selectedLanguage);
  }

  /**
   * Manages the creation and deletion of the store categories
   * @param {List<Id>} categories Ids to create
   * @param {List<Id>} categories Ids to delete
   * @param {Id} Selected Store Id
   */
  @AuraEnabled
  public static void manageCreationAndDeletion(
    List<Id> categoriesIdToCreate,
    List<Id> categoriesIdToDelete,
    Id storeId,
    Id newMainCategoryId
  ) {
    deleteStoreCategories(categoriesIdToDelete, storeId); // Create Store categories for each category for the selected store

    createStoreCategories(categoriesIdToCreate, storeId); // Delete Store categories for each category from the selected store

    if (newMainCategoryId != null) {
      setNewMainCategory(newMainCategoryId, storeId);
    }
  }

  public static void setNewMainCategory(Id newMainCategoryId, Id storeId) {
    List<ER_StoreCategory__c> mainStoreCategories = new List<ER_StoreCategory__c>(
      [
        SELECT Category__c, Main_Category__c, Store__c
        FROM ER_StoreCategory__c
        WHERE Store__c = :storeId AND (Category__c = :newMainCategoryId OR Main_Category__c = TRUE)
      ]
    );
    for (ER_StoreCategory__c storeCategory : mainStoreCategories) {
      System.debug('Code is Here ' + newMainCategoryId);
      System.debug('Code is Here ' + storeCategory.Main_Category__c);
      System.debug('Code is Here ' + storeCategory.Category__c);
      if (storeCategory.Main_Category__c == true && storeCategory.Category__c != newMainCategoryId) {
        storeCategory.Main_Category__c = false;
      } else if (storeCategory.Main_Category__c == false && storeCategory.Category__c == newMainCategoryId) {
        storeCategory.Main_Category__c = true;
      }
    }
    update mainStoreCategories;
  }

  /**
   * Remove the selected categories from the selected store (By deleting the according store category)
   * @param {List<Id>} List of Ids of the selected Categories
   * @param {Id} The Id of the selected Store
   */
  public static void deleteStoreCategories(List<Id> categoriesIds, Id storeId) {
    // Fetch Store Category to delete by Store Id and Category Id
    List<ER_StoreCategory__c> storeCategoriesToDelete = [
      SELECT Id, Store__c, Category__c
      FROM ER_StoreCategory__c
      WHERE Store__c = :storeId AND Category__c IN :categoriesIds
    ];
    delete storeCategoriesToDelete;
  }

  /**
   * Add the selected categories for the selected store (By creating the according store category)
   * @param {List<Id>} List of Ids of the selected Categories
   * @param {Id} The Id of the selected Store
   */
  public static void createStoreCategories(List<Id> categoriesIds, Id storeId) {
    Map<Id, ER_StoreCategory__c> storeCategoriesMap = new Map<Id, ER_StoreCategory__c>();
    List<ER_StoreCategory__c> storeCategoriesToCreate = new List<ER_StoreCategory__c>();

    for (ER_StoreCategory__c storeCat : [
      SELECT Id, Category__c
      FROM ER_StoreCategory__c
      WHERE Store__c = :storeId AND Category__c IN :categoriesIds
    ]) {
      storeCategoriesMap.put(storeCat.Category__c, storeCat);
    }

    for (Id categoryId : categoriesIds) {
      ER_StoreCategory__c storeCategory = new ER_StoreCategory__c();

      storeCategory.Store__c = storeId;

      storeCategory.Category__c = categoryId;

      if (!storeCategoriesMap.containsKey(categoryId)) {
        storeCategoriesToCreate.add(storeCategory);
      }
    }
    upsert storeCategoriesToCreate;
  }
}