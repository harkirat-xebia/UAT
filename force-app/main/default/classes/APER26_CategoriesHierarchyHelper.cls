/**
 * Vershley Joyejob
 * 14/01/2021
 */

public with sharing class APER26_CategoriesHierarchyHelper {
  public class Node {
    public Id itemId { get; set; }

    public Id parentItemId { get; set; }

    public Boolean hasChildren {
      get {
        return this.items.size() > 0;
      }
      private set;
    }

    public List<Node> items { get; private set; }

    public Decimal level { get; set; }

    public Boolean isExpanded { get; set; }

    public Boolean isChecked { get; set; }

    public Boolean isMain { get; set; }

    public String label { get; set; }

    public String language { get; set; }

    public Node(Id itemId, Id parentItemId, Decimal level, String label) {
      this.itemId = itemId;
      this.parentItemId = parentItemId;
      this.level = level;
      this.label = label;

      this.isExpanded = true;
      this.isChecked = false;
      this.isMain = false;
      this.items = new List<Node>();
    }

    public void addChild(Node child) {
      child.parentItemId = this.itemId;
      this.items.add(child);
      this.hasChildren = true;
    }
  }

  public APER26_CategoriesHierarchyHelper() {
  }

  public List<String> getCategoriesLanguages(List<Id> categoriesIds) {
    List<ER_Translation__c> translations = [
      SELECT Language__c
      FROM ER_Translation__c
      WHERE Dependent_Value__c IN :categoriesIds
    ];

    Set<String> languages = new Set<String>();

    for (ER_Translation__c translation : translations) {
      languages.add(translation.Language__c);
    }

    return new List<String>(languages);
  }

  public Map<Id, String> getCategoriesTranslations(List<Id> categoriesIds, String selectedLanguage) {
    if (String.isBlank(selectedLanguage)) {
      selectedLanguage = UserInfo.getLanguage();
    }

    List<ER_Translation__c> translations = [
      SELECT Dependent_Value__c, Text__c, Text_Area__c, Long_Text_Area__c
      FROM ER_Translation__c
      WHERE Dependent_Value__c IN :categoriesIds AND Language__c = :selectedLanguage
    ];

    Map<Id, String> output = new Map<Id, String>();

    for (ER_Translation__c translation : translations) {
      String value;
      if (!String.isBlank(translation.Text__c)) {
        value = translation.Text__c;
      } else if (!String.isBlank(translation.Text_Area__c)) {
        value = translation.Text_Area__c;
      } else if (!String.isBlank((translation.Long_Text_Area__c))) {
        value = translation.Long_Text_Area__c;
      }
      if (value != null) {
        output.put(translation.Dependent_Value__c, value);
      }
    }

    return output;
  }

  public Node getCategoriesGraph(Id storeId, Map<Id, ER_DependentValue__c> categories) {
    Map<Id, Node> nodes = categoriesToNodes(categories);
    Id mainCategory = getMainCategory(storeId);
    Set<Id> activeCategories = getActiveCategories(storeId);
    return buildCategoryGraph(nodes, mainCategory, activeCategories);
  }

  public Map<Id, ER_DependentValue__c> getCategories(Id storeId) {
    String storeBusinessUnit = [SELECT ER_BUPicklist__c FROM ER_Store__c WHERE Id = :storeId].ER_BUPicklist__c;
    Set<Id> solutionsIds = new Set<Id>(); //getSolutionsIds(storeId);
    solutionsIds = getSolutionsIds(storeId);
    String dependentValRecordTypeID = Utils.getRecordTypeIdByDeveloperName(
      ER_DependentValue__c.SObjectType,
      'Category'
    ); //getDependentValRecordTypeId();

    Map<Id, ER_DependentValue__c> categoryMap = new Map<Id, ER_DependentValue__c>();

    for (ER_DependentValue__c dep : [
      SELECT Id, Name, Parent_Dependent_Value__c, Level__c, ER_Ordering__c
      FROM ER_DependentValue__c
      WHERE
        RecordTypeId = :dependentValRecordTypeID
        AND ER_Status__c = 'Active'
        AND ER_Business_Unit__c = :storeBusinessUnit
        AND ((Solution_and_Service__c IN :solutionsIds
        AND ER_Business_Unit__c = 'BENELUX')
        OR Solution_and_Service__c = NULL)
      ORDER BY Level__c, ER_Ordering__c ASC
    ]) {
      categoryMap.put(dep.Id, dep);
    }

    /*String query =
            '   SELECT ' +
                '   Id, ' +
                '   Name, ' +
                '   Parent_Dependent_Value__c, ' +
                '   Level__c, ' +
                '   ER_Ordering__c ' +
                'FROM ' +
                '   ER_DependentValue__c ' +
                'WHERE ' +
                '   RecordTypeId = :dependentValRecordTypeID AND ' +
                '   ER_Status__c = \'Active\' AND ' +
                '   ER_Business_Unit__c = :storeBusinessUnit ' + (solutionsIds.size() > 0 ? ('AND ' +
                '   Solution_and_Service__c IN :solutionsIds ') : '') +
                'ORDER BY Level__c, ER_Ordering__c ASC ';

        return new Map<Id, ER_DependentValue__c>((List<ER_DependentValue__c>)Database.query(query));*/

    return categoryMap;
  }

  public Set<Id> getSolutionsIds(Id storeId) {
    Set<Id> solutionsIds = new Set<Id>();

    for (ER_Solution_Line_Item__c solutionitem : [
      SELECT Id, ER_Solution__c
      FROM ER_Solution_Line_Item__c
      WHERE ER_Store__c = :storeId AND ER_Status__c = 'Active'
    ]) {
      if (solutionitem.ER_Solution__c != null)
        solutionsIds.add(solutionitem.ER_Solution__c);
    }

    return solutionsIds;
  }

  private Node buildCategoryGraph(Map<Id, Node> nodes, Id mainCategory, Set<Id> activeCategories) {
    Node rootNode = new Node(null, null, 0, 'Categories');
    for (Node node : nodes.values()) {
      if (node.itemId == mainCategory) {
        node.isMain = true;
      }
      if (activeCategories.contains(node.itemId)) {
        node.isChecked = true;
      }
      if (node.parentItemId != null && nodes.containsKey(node.parentItemId)) {
        nodes.get(node.parentItemId).addChild(node);
      } else {
        rootNode.addChild(node);
      }
    }
    return rootNode;
  }

  private Id getMainCategory(Id storeId) {
    return [
      SELECT Id
      FROM ER_DependentValue__c
      WHERE Id IN (SELECT Category__c FROM ER_StoreCategory__c WHERE Store__c = :storeId AND Main_Category__c = TRUE)
      LIMIT 1
    ]
    ?.Id;
  }

  private Set<Id> getActiveCategories(Id storeId) {
    return new Map<Id, ER_DependentValue__c>(
        [
          SELECT Id
          FROM ER_DependentValue__c
          WHERE Id IN (SELECT Category__c FROM ER_StoreCategory__c WHERE Store__c = :storeId)
        ]
      )
      .keySet();
  }

  private Map<Id, Node> categoriesToNodes(Map<Id, ER_DependentValue__c> categories) {
    Map<Id, Node> nodes = new Map<Id, Node>();
    for (ER_DependentValue__c category : categories.values()) {
      nodes.put(
        category.Id,
        new Node(category.Id, category.Parent_Dependent_Value__c, category.Level__c, category.Name)
      );
    }
    return nodes;
  }

  /*private Id getDependentValRecordTypeId()
    {
        return Schema.getGlobalDescribe()
            .get('ER_DependentValue__c')
            .getDescribe()
            .getRecordTypeInfosByName()
            .get('Category')
            .getRecordTypeId();
    }*/

  /**
   * Returns a List of Map name => value for all the options
   * in the translation languages picklist
   * @param {String} Translation Object API Name
   * @param {String} Translation Field API Name
   */
  @AuraEnabled
  public static List<Map<String, String>> getPickListValues(String objApiName, String fieldName) {
    // List of Map name => value of picklists options to return
    List<Map<String, String>> options = new List<Map<String, String>>();

    Map<String, Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();

    // Global description of the object entered in parameters
    Schema.SObjectType objType = Schema.getGlobalDescribe().get(objApiName);

    // Whether the object exists or not
    if (objType == null) {
      return options;
    }

    Schema.DescribeSObjectResult sobjectDescribe = objType.getDescribe();

    // Map of the fields of the object entered in parameters
    Map<String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap();

    // Whether the object contains the field entered in parameters
    if (fieldMap.get(fieldName) == null) {
      return options;
    }
    // Set the picklist values
    List<Schema.PicklistEntry> pickListValues = fieldMap.get(fieldName).getDescribe().getPickListValues();

    // Set the options list to return
    for (Schema.PicklistEntry f : pickListValues) {
      Map<String, String> values = new Map<String, String>{ 'label' => f.getLabel(), 'value' => f.getValue() };
      options.add(values);
    }
    return options;
  }
}