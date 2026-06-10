/*
----------------------------------------------------------------------
-- - Name          : APER26_CategoriesHierarchyHelper_Test
-- - Author        : 
-- - Description   : Test class for APER26_CategoriesHierarchyHelper     
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 24-Aug-2021                     1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
@isTest
public with sharing class APER26_CategoriesHierarchyHelper_Test {
  @testSetup
  static void testSetup() {
    List<ER_DependentValue__c> listCategoriesToCreate = new List<ER_DependentValue__c>();

    ER_DependentValue__c categoryParent1 = new ER_DependentValue__c();
    categoryParent1.Name = 'Parent1';
    categoryParent1.ER_Status__c = 'Active';
    categoryParent1.ER_Business_Unit__c = 'CZ';

    ER_DependentValue__c categoryParent2 = new ER_DependentValue__c();
    categoryParent2.Name = 'Parent2';
    categoryParent2.ER_Status__c = 'Active';
    categoryParent2.ER_Business_Unit__c = 'CZ';

    listCategoriesToCreate.add(categoryParent1);
    listCategoriesToCreate.add(categoryParent2);

    Database.insert(listCategoriesToCreate, true);
    System.assert(categoryParent1.Id != null);

    listCategoriesToCreate = new List<ER_DependentValue__c>();

    ER_DependentValue__c categoryChild = new ER_DependentValue__c();
    categoryChild.Name = 'Child1';
    categoryChild.Parent_Dependent_Value__c = categoryParent1.Id;
    categoryChild.ER_Ordering__c = 2;
    categoryChild.ER_Status__c = 'Active';
    categoryChild.ER_Business_Unit__c = 'CZ';
    listCategoriesToCreate.add(categoryChild);

    ER_DependentValue__c categoryChild2 = new ER_DependentValue__c();
    categoryChild2.Name = 'Child2';
    categoryChild2.Parent_Dependent_Value__c = categoryParent2.Id;
    categoryChild2.ER_Status__c = 'Active';
    categoryChild2.ER_Business_Unit__c = 'CZ';
    listCategoriesToCreate.add(categoryChild2);

    Database.insert(listCategoriesToCreate, true);
    System.assert(categoryChild2.Id != null);

    listCategoriesToCreate = new List<ER_DependentValue__c>();

    ER_DependentValue__c categoryGrandChild = new ER_DependentValue__c();
    categoryGrandChild.Name = 'categoryGrandChild1';
    categoryGrandChild.ER_Status__c = 'Active';
    categoryGrandChild.Parent_Dependent_Value__c = categoryChild.Id;
    categoryGrandChild.ER_Business_Unit__c = 'CZ';
    listCategoriesToCreate.add(categoryGrandChild);
    Database.insert(listCategoriesToCreate, true);
    System.assert(categoryGrandChild.Id != null);

    Account merchantAccount = APER07_UtilityTestMethod.getCompany('APER14_Store_Management_Test');
    insert merchantAccount;

    ER_Financial_Center__c testFinancialCenter = APER07_UtilityTestMethod.getFinancialCenter(
      'APER14_Store_Management_Test',
      merchantAccount.id,
      Label.LABS_SF_FinancialCenter_Merchant,
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testFinancialCenter.ER_Invoicing_Site__c = true;
    insert testFinancialCenter;

    ER_Store__c testStore = APER07_UtilityTestMethod.getStore(
      'APER14_Store_Management_Test',
      merchantAccount.id,
      testFinancialCenter.id,
      Date.today(),
      'Test',
      'Test',
      'Test',
      'Test'
    );
    testStore.ER_BUPicklist__c = 'CZ';
    insert testStore;

    List<ER_Translation__c> translationList = new List<ER_Translation__c>();
    ER_Translation__c translation = new ER_Translation__c();
    translation.Dependent_Value__c = categoryParent1.Id;
    translation.Field_API_Name__c = 'Name';
    translation.Language__c = 'fr';
    translation.Text__c = 'translatedText';

    ER_Translation__c translation2 = new ER_Translation__c();
    translation2.Dependent_Value__c = categoryGrandChild.Id;
    translation2.Field_API_Name__c = 'Name';
    translation2.Language__c = 'fr';
    translation2.Text__c = 'translatedText';

    translationList.add(translation);
    translationList.add(translation2);

    insert translationList;
  }

  static testMethod void Test_setCategoryLevel() {
    Test.startTest();

    ER_DependentValue__c categoryParent2 = [
      SELECT Id, Name, ER_Status__c, Parent_Dependent_Value__c, ER_Ordering__c
      FROM ER_DependentValue__c
      WHERE Name = 'Parent2'
      LIMIT 1
    ];

    List<Id> listCategoriesIdToCreate = new List<Id>();
    List<Id> listCategoriesIdToDelete = new List<Id>();

    ER_DependentValue__c categoryGrandChild = [
      SELECT Id, Name, ER_Status__c, Parent_Dependent_Value__c, ER_Ordering__c
      FROM ER_DependentValue__c
      WHERE Name = 'categoryGrandChild1'
      LIMIT 1
    ];

    listCategoriesIdToCreate.add(categoryGrandChild.Id);

    ER_DependentValue__c categoryChild = [
      SELECT Id, Name, ER_Status__c, Parent_Dependent_Value__c, ER_Ordering__c
      FROM ER_DependentValue__c
      WHERE Name = 'Child1'
      LIMIT 1
    ];
    //Update one parent
    categoryChild.Parent_Dependent_Value__c = categoryParent2.Id;
    APER27_DependentValue_Management.firstRun = true;
    categoryChild.ER_Ordering__c = 1;
    Database.update(categoryChild, true);

    //Update order
    categoryChild.Parent_Dependent_Value__c = categoryParent2.Id;
    Database.update(categoryChild, true);

    ER_DependentValue__c categoryChild2 = [
      SELECT Id, Name, ER_Status__c, Parent_Dependent_Value__c, ER_Ordering__c
      FROM ER_DependentValue__c
      WHERE Name = 'Child2'
      LIMIT 1
    ];
    listCategoriesIdToDelete.add(categoryChild2.Id);
    //Delete Parent
    Database.delete(categoryChild, true);

    //LWC Controllers
    ER_Store__c testStore = [SELECT Id, Name FROM ER_Store__c LIMIT 1];

    //APER25_CategoriesHierarchyController.getCategoriesGraph(testStore.Id);
    //APER25_CategoriesHierarchyController.getCategoriesTranslations(listCategoriesIdToCreate, 'fr');

    APER26_CategoriesHierarchyHelper service = new APER26_CategoriesHierarchyHelper();
    Map<Id, ER_DependentValue__c> categories = service.getCategories(testStore.Id);
    APER26_CategoriesHierarchyHelper.Node catGraph = service.getCategoriesGraph(testStore.Id, categories);
    List<String> catLang = service.getCategoriesLanguages(new List<Id>(categories.keySet()));
    Map<Id, String> catTranslations = service.getCategoriesTranslations(listCategoriesIdToCreate, 'fr');

    APER26_CategoriesHierarchyHelper.getPickListValues('ER_DependentValue__c', 'Language__c');
    //APER25_CategoriesHierarchyController.manageCreationAndDeletion(listCategoriesIdToCreate, listCategoriesIdToDelete, testStore.Id, categoryGrandChild.Id);
    Test.stopTest();
  }
}