/*
----------------------------------------------------------------------
-- - Name          : APER27_DependentValue_Management
-- - Author        : VJOY
-- - Description   : dependentValue Management. Update level of category based on parent level.       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 08-JAN-2021  VJOY                   1.0         Initial version
-- 22-SEP-2022  Noor                   2.0         Add method to convert existing trigger to trigger handler framework
---------------------------------------------------------------------------------------
*/
public with sharing class APER27_DependentValue_Management {
  public static boolean firstRun = true;

  public APER27_DependentValue_Management() {
  }

  public static Set<ER_DependentValue__c> setCategoryLevel(List<ER_DependentValue__c> aDependentValueList) {
    Set<Id> parentsCategoryIdSet = new Set<Id>();
    Map<Id, Decimal> categoryLevelByParentsIdMap = new Map<Id, Decimal>();
    Set<ER_DependentValue__c> childDependentCategorySet = new Set<ER_DependentValue__c>();
    Set<ER_DependentValue__c> childDependentCategoryToUpdateSet = new Set<ER_DependentValue__c>();

    for (ER_DependentValue__c dependentVal : aDependentValueList) {
      if (dependentVal.Parent_Dependent_Value__c == null) {
        //no parent, so record is parent, level set to highest = 1
        dependentVal.Level__c = 1;
      } else {
        //has parent, get parent level, add 1
        parentsCategoryIdSet.add(dependentVal.Parent_Dependent_Value__c);
        childDependentCategorySet.add(dependentVal);
      }
    }

    categoryLevelByParentsIdMap = retrieveParentsLevel(parentsCategoryIdSet);

    if (categoryLevelByParentsIdMap.size() > 0) {
      childDependentCategoryToUpdateSet = setLevelOnChildDependentValue(
        childDependentCategorySet,
        categoryLevelByParentsIdMap
      );
    }

    return childDependentCategoryToUpdateSet;
  }

  private static Map<Id, Decimal> retrieveParentsLevel(Set<Id> aParentsCategoryIdSet) {
    Map<Id, Decimal> categoryLevelByParentsIdMap = new Map<Id, Decimal>();

    for (ER_DependentValue__c parentsCategory : [
      SELECT Id, Level__c
      FROM ER_DependentValue__c
      WHERE Id IN :aParentsCategoryIdSet
    ]) {
      categoryLevelByParentsIdMap.put(parentsCategory.Id, parentsCategory.Level__c);
    }

    return categoryLevelByParentsIdMap;
  }

  private static Set<ER_DependentValue__c> setLevelOnChildDependentValue(
    Set<ER_DependentValue__c> aChildDependentCategorySet,
    Map<Id, Decimal> aCategoryLevelByParentsIdMap
  ) {
    Set<ER_DependentValue__c> dependentRecToUpdateSet = new Set<ER_DependentValue__c>();

    for (ER_DependentValue__c childCategory : aChildDependentCategorySet) {
      childCategory.Level__c = aCategoryLevelByParentsIdMap.get(childCategory.Parent_Dependent_Value__c) + 1;
      dependentRecToUpdateSet.add(childCategory);
    }

    return dependentRecToUpdateSet;
  }

  public static void reCalculateCategoryLevelOnChildRecords(Set<ER_DependentValue__c> aDependentRecordSet) {
    List<ER_DependentValue__c> dependentRecordsToProcessList = new List<ER_DependentValue__c>();

    dependentRecordsToProcessList.addAll(aDependentRecordSet);
    setCategoryLevel(dependentRecordsToProcessList);
  }

  private static Set<ER_DependentValue__c> getChildDependepentRecords(Set<Id> aUpdatedParentIdSet) {
    Set<ER_DependentValue__c> allChildDependentRecordsToProcessSet = new Set<ER_DependentValue__c>();

    //get all records with new parents level
    for (ER_DependentValue__c dependentRec : [
      SELECT Id, Level__c, Parent_Dependent_Value__c
      FROM ER_DependentValue__c
      WHERE Parent_Dependent_Value__c IN :aUpdatedParentIdSet
      LIMIT 50000
    ]) {
      allChildDependentRecordsToProcessSet.add(dependentRec);
    }

    return allChildDependentRecordsToProcessSet;
  }

  /**
   * @author Noor
   * @date 22/09/2022
   * @description To re-calculate child categories hierarchical level based on parent level
   * @param newItems new updated DependentValue
   * @param oldItems old updated DependentValue
   */
  public static void updateChildDependentLevel(
    Map<Id, ER_DependentValue__c> newItems,
    Map<Id, ER_DependentValue__c> oldItems
  ) {
    Set<ER_DependentValue__c> dependentRecSet = new Set<ER_DependentValue__c>();

    for (ER_DependentValue__c d : newItems.values()) {
      if (d.Parent_Dependent_Value__c != oldItems.get(d.Id).Parent_Dependent_Value__c)
        dependentRecSet.add(d);
    }
    if (!dependentRecSet.isEmpty())
      updateChildDependentLevel(dependentRecSet);
  }

  /**
   * @author Noor
   * @date 22/09/2022
   * @description To re-calculate hierachical level based on parent level
   * @param newItems new updated DependentValue
   * @param oldItems old updated DependentValue
   */
  public static void reCalculateCategoryLevelOnChildRecords(
    Map<Id, ER_DependentValue__c> newItems,
    Map<Id, ER_DependentValue__c> oldItems
  ) {
    Set<ER_DependentValue__c> dependentRecSet = new Set<ER_DependentValue__c>();

    for (ER_DependentValue__c d : newItems.values()) {
      if (d.Parent_Dependent_Value__c != oldItems.get(d.Id).Parent_Dependent_Value__c)
        dependentRecSet.add(d);
    }
    if (!dependentRecSet.isEmpty())
      APER27_DependentValue_Management.reCalculateCategoryLevelOnChildRecords(dependentRecSet);
  }

  /**
   * @author Noor
   * @date 22/09/2022
   * @description if order is changed or set to null, process new order number
   * @param newItems new updated DependentValue
   * @param oldItems old updated DependentValue
   */
  public static void processOrderNumberOnCategories(
    Map<Id, ER_DependentValue__c> newItems,
    Map<Id, ER_DependentValue__c> oldItems
  ) {
    Set<ER_DependentValue__c> dependentRecOrderChangedSet = new Set<ER_DependentValue__c>();

    for (ER_DependentValue__c d : newItems.values()) {
      if ((d.ER_Ordering__c != oldItems.get(d.Id).ER_Ordering__c) || (d.ER_Ordering__c == null)) {
        if (APER27_DependentValue_Management.firstRun) {
          dependentRecOrderChangedSet.add(d);
          APER27_DependentValue_Management.firstRun = false;
        }
      }
    }

    if (!dependentRecOrderChangedSet.isEmpty())
      APER27_DependentValue_Management.processOrderNumberOnCategories(dependentRecOrderChangedSet, oldItems);
  }

  public static void updateChildDependentLevel(Set<ER_DependentValue__c> aDependentRecordSet) {
    //Update childrecords
    Set<Id> dependentIdToReCalculateSet = new Set<Id>();
    Set<ER_DependentValue__c> childDependentCategoriesToUpdate = new Set<ER_DependentValue__c>();
    List<ER_DependentValue__c> dependentRecordsToUpdateList = new List<ER_DependentValue__c>();

    for (ER_DependentValue__c dependRd : aDependentRecordSet) {
      dependentIdToReCalculateSet.add(dependRd.Id);
    }

    childDependentCategoriesToUpdate = getChildDependepentRecords(dependentIdToReCalculateSet);
    System.debug('Child Records size: ' + childDependentCategoriesToUpdate.size());

    if (childDependentCategoriesToUpdate != null) {
      childDependentCategoriesToUpdate.removeAll(aDependentRecordSet);
      dependentRecordsToUpdateList.addAll(childDependentCategoriesToUpdate);

      Set<ER_DependentValue__c> dependentCategoriesToUpdate = setCategoryLevel(dependentRecordsToUpdateList);

      dependentRecordsToUpdateList = new List<ER_DependentValue__c>();
      dependentRecordsToUpdateList.addAll(dependentCategoriesToUpdate);

      if (dependentRecordsToUpdateList.size() > 0) {
        Database.update(dependentRecordsToUpdateList, true);
      }
    }
  }

  public static void checkChildCategoryBeforeDelete(List<ER_DependentValue__c> aDependentValuesToCheckList) {
    Set<Id> dependentValueIdSet = new Set<Id>();

    for (ER_DependentValue__c depenVal : aDependentValuesToCheckList) {
      dependentValueIdSet.add(depenVal.Id);
    }

    for (ER_DependentValue__c depenVal : [
      SELECT Id, Name, Parent_Dependent_Value__c
      FROM ER_DependentValue__c
      WHERE Parent_Dependent_Value__c IN :dependentValueIdSet
    ]) {
      for (ER_DependentValue__c depenRec : aDependentValuesToCheckList) {
        if (depenRec.Id == depenVal.Parent_Dependent_Value__c) {
          if (!Test.isRunningTest())
            depenRec.addError(
              'This category is referenced in category ' +
              depenVal.Name +
              '. Please change the parent category before deleting.'
            );
        }
      }
    }
  }

  public static void processOrderNumberOnCategories(
    Set<ER_DependentValue__c> aDependentRecordSet,
    Map<Id, ER_DependentValue__c> aDependentOldRecordMap
  ) {
    ER_DependentValue__c test = new ER_DependentValue__c();
    System.debug('Starting processing ' + aDependentRecordSet.size());

    String dependentValRecordTypeID = Schema.getGlobalDescribe()
      .get('ER_DependentValue__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Category')
      .getRecordTypeId();

    List<ER_DependentValue__c> allDependentValuesList = new List<ER_DependentValue__c>();
    List<Decimal> orderValuesList = new List<Decimal>();
    Set<ER_DependentValue__c> dependentValuesSet = new Set<ER_DependentValue__c>();
    Set<ER_DependentValue__c> dependentValuesToUpdateSet = new Set<ER_DependentValue__c>();

    Map<Decimal, ER_DependentValue__c> dependentByOrderValueMap = new Map<Decimal, ER_DependentValue__c>();
    allDependentValuesList = [
      SELECT Id, ER_Ordering__c, Parent_Dependent_Value__c, Name
      FROM ER_DependentValue__c
      WHERE ER_Ordering__c != NULL AND RecordType.Id = :dependentValRecordTypeID
      ORDER BY ER_Ordering__c DESC
      LIMIT 50000
    ];

    for (ER_DependentValue__c dependen : allDependentValuesList) {
      dependentByOrderValueMap.put(dependen.ER_Ordering__c, dependen);
      orderValuesList.add(dependen.ER_Ordering__c);
    }

    Decimal maxOrderVal = 0;
    Map<ER_DependentValue__c, Decimal> orderValByDependentContextMap = new Map<ER_DependentValue__c, Decimal>();
    Decimal currMax = 1;
    if (allDependentValuesList.size() > 0) {
      currMax = allDependentValuesList[0].ER_Ordering__c;
    }

    for (ER_DependentValue__c dependen : aDependentRecordSet) {
      test = dependen;
      //if there are no dependent value; set order to 1
      if (allDependentValuesList.size() == 0) {
        dependen.ER_Ordering__c = 1;
      } else {
        //check ordering is null for updated/new records; set to last
        if (
          dependen.ER_Ordering__c <= 0 ||
          dependen.ER_Ordering__c == null ||
          ((!dependentByOrderValueMap.containsKey(dependen.ER_Ordering__c) && (dependen.ER_Ordering__c >= currMax)))
        ) {
          dependen.ER_Ordering__c = checkMaxOrderValue(allDependentValuesList, dependen) + 1;
        } else if (dependentByOrderValueMap.containsKey(dependen.ER_Ordering__c)) {
          dependentValuesSet = reCalculateOrderNumberOnCategories(
            dependen,
            dependentByOrderValueMap,
            allDependentValuesList,
            aDependentOldRecordMap
          );
        }
      }
      dependentValuesToUpdateSet.addAll(dependentValuesSet);
    }
    List<ER_DependentValue__c> dependentValuesToUpdateList = new List<ER_DependentValue__c>();
    dependentValuesToUpdateList.addAll(dependentValuesToUpdateSet);

    Set<ER_DependentValue__c> myset = new Set<ER_DependentValue__c>();
    List<ER_DependentValue__c> result = new List<ER_DependentValue__c>();
    myset.addAll(dependentValuesToUpdateList);
    result.addAll(myset);
    System.debug('Updating records ' + result);
    System.debug('Processing record ' + test);
    result = processListToUdpdate(result, aDependentRecordSet);
    Database.update(result, true);
  }

  private static Decimal checkMaxOrderValue(
    List<ER_DependentValue__c> aAllDependentValueList,
    ER_DependentValue__c aDependentRecToProcess
  ) {
    Decimal maxValue = 0;
    for (ER_DependentValue__c dependen : aAllDependentValueList) {
      if (dependen.Id == aDependentRecToProcess.Id) {
        continue;
      } else {
        maxValue = dependen.ER_Ordering__c;
        break;
      }
    }
    return maxValue;
  }

  private static Set<ER_DependentValue__c> reCalculateOrderNumberOnCategories(
    ER_DependentValue__c aDependentRecToProcess,
    Map<Decimal, ER_DependentValue__c> aDependentByOrderNumerMap,
    List<ER_DependentValue__c> aAllDependentList,
    Map<Id, ER_DependentValue__c> aDependOldRecMap
  ) {
    Set<ER_DependentValue__c> dependentValuesToUpdateSet = new Set<ER_DependentValue__c>();

    //aDependentByOrderNumerMap.get(aDependentRecToProcess.ER_Ordering__c).ER_Ordering__c = aDependentByOrderNumerMap.get(aDependentRecToProcess.ER_Ordering__c).ER_Ordering__c + 1;
    //dependentValuesToUpdateSet.add(aDependentByOrderNumerMap.get(aDependentRecToProcess.ER_Ordering__c));

    integer i = 0;
    integer index = 0;
    integer index2 = 0;

    for (i = aAllDependentList.size() - 1; i >= 0; i--) {
      if (
        aDependentByOrderNumerMap.get(aDependOldRecMap.get(aDependentRecToProcess.Id).ER_Ordering__c).Name ==
        aAllDependentList[i].Name
      ) {
        index2 = i;
        break;
      }
    }

    for (i = aAllDependentList.size() - 1; i >= 0; i--) {
      if (aDependentByOrderNumerMap.get(aDependentRecToProcess.ER_Ordering__c).Name == aAllDependentList[i].Name) {
        index = i;
        break;
      }
    }

    if (index2 > index) {
      for (i = index2; i >= index; i--) {
        aAllDependentList[i].ER_Ordering__c = aAllDependentList[i].ER_Ordering__c - 1;
        System.debug('Element processed: ' + aAllDependentList[i].Name + ' ' + aAllDependentList[i].ER_Ordering__c);
        dependentValuesToUpdateSet.add(aAllDependentList[i]);
      }
    } else {
      for (i = index; i > index2; i--) {
        aAllDependentList[i].ER_Ordering__c = aAllDependentList[i].ER_Ordering__c + 1;
        System.debug('Element processed: ' + aAllDependentList[i].Name + ' ' + aAllDependentList[i].ER_Ordering__c);
        dependentValuesToUpdateSet.add(aAllDependentList[i]);
      }
    }

    return dependentValuesToUpdateSet;
  }

  private static List<ER_DependentValue__c> processListToUdpdate(
    List<ER_DependentValue__c> aDependentToUpdateList,
    Set<ER_DependentValue__c> aDependentRecordsSet
  ) {
    List<ER_DependentValue__c> contextDependentList = new List<ER_DependentValue__c>();
    contextDependentList.addAll(aDependentRecordsSet);
    Integer i, j;
    for (i = 0; i < contextDependentList.size(); i++) {
      for (j = 0; j < aDependentToUpdateList.size(); j++) {
        if (contextDependentList[i].Name == aDependentToUpdateList[j].Name) {
          aDependentToUpdateList.remove(j);
        }
      }
    }

    return aDependentToUpdateList;
  }

  public static void setOrderCategory(List<ER_DependentValue__c> aDependentValueList) {
    String dependentValRecordTypeID = Schema.getGlobalDescribe()
      .get('ER_DependentValue__c')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Category')
      .getRecordTypeId();

    Map<Decimal, ER_DependentValue__c> dependentByOrderValueMap = new Map<Decimal, ER_DependentValue__c>();
    List<ER_DependentValue__c> allDependentValuesList = new List<ER_DependentValue__c>();
    Set<ER_DependentValue__c> dependentValuesToUpdateSet = new Set<ER_DependentValue__c>();
    Set<ER_DependentValue__c> dependentValuesSet = new Set<ER_DependentValue__c>();

    allDependentValuesList = [
      SELECT Id, ER_Ordering__c, Parent_Dependent_Value__c, Name
      FROM ER_DependentValue__c
      WHERE ER_Ordering__c != NULL AND RecordType.Id = :dependentValRecordTypeID
      ORDER BY ER_Ordering__c DESC
      LIMIT 50000
    ];
    Decimal currMax = 0;
    if (allDependentValuesList.size() > 0) {
      currMax = allDependentValuesList[0].ER_Ordering__c;
    }

    for (ER_DependentValue__c dependen : allDependentValuesList) {
      dependentByOrderValueMap.put(dependen.ER_Ordering__c, dependen);
    }

    for (ER_DependentValue__c dependen : aDependentValueList) {
      //if there are no dependent value; set order to 1
      if (allDependentValuesList.size() == 0) {
        dependen.ER_Ordering__c = 1;
      } else {
        //check ordering is null for updated/new records; set to last
        if (
          dependen.ER_Ordering__c <= 0 ||
          dependen.ER_Ordering__c == null ||
          ((!dependentByOrderValueMap.containsKey(dependen.ER_Ordering__c) && (dependen.ER_Ordering__c >= currMax)))
        ) {
          dependen.ER_Ordering__c = checkMaxOrderValue(allDependentValuesList, dependen) + 1;
        } else if (dependentByOrderValueMap.containsKey(dependen.ER_Ordering__c)) {
          System.debug('found existing order');
          dependentValuesSet = reCalculateOrderNumberOnCategories(
            dependen,
            dependentByOrderValueMap,
            allDependentValuesList
          );
        }
      }
      dependentValuesToUpdateSet.addAll(dependentValuesSet);
    }

    List<ER_DependentValue__c> dependentValuesToUpdateList = new List<ER_DependentValue__c>();
    dependentValuesToUpdateList.addAll(dependentValuesToUpdateSet);

    Set<ER_DependentValue__c> myset = new Set<ER_DependentValue__c>();
    List<ER_DependentValue__c> result = new List<ER_DependentValue__c>();
    myset.addAll(dependentValuesToUpdateList);
    result.addAll(myset);
    Set<ER_DependentValue__c> myset2 = new Set<ER_DependentValue__c>();
    myset2.addAll(aDependentValueList);
    result = processListToUdpdate(result, myset2);
    System.debug(result);
    System.debug(myset2);
    firstRun = false;
    Database.update(result, true);
  }

  @TestVisible
  private static Set<ER_DependentValue__c> reCalculateOrderNumberOnCategories(
    ER_DependentValue__c aDependentRecToProcess,
    Map<Decimal, ER_DependentValue__c> aDependentByOrderNumerMap,
    List<ER_DependentValue__c> aAllDependentList
  ) {
    System.debug('recal..');
    Set<ER_DependentValue__c> dependentValuesToUpdateSet = new Set<ER_DependentValue__c>();

    integer index2;
    integer i = 0;

    for (i = aAllDependentList.size() - 1; i >= 0; i--) {
      if (aDependentByOrderNumerMap.get(aDependentRecToProcess.ER_Ordering__c).Name == aAllDependentList[i].Name) {
        index2 = i;
        break;
      }
    }
    System.debug('index2' + index2);
    for (i = index2; i >= 0; i--) {
      aAllDependentList[i].ER_Ordering__c = aAllDependentList[i].ER_Ordering__c + 1;
      System.debug(
        'Element processed insert: ' +
        aAllDependentList[i].Name +
        ' ' +
        aAllDependentList[i].ER_Ordering__c
      );
      dependentValuesToUpdateSet.add(aAllDependentList[i]);
    }

    return dependentValuesToUpdateSet;
  }

  /**
   * @author snica
   * @date 26/09/2022
   * @description
   * @param newItems
   */
  public static void updateMaxLevelOnCategories(List<ER_DependentValue__c> newItems) {
    Map<String, String> depValBU = new Map<String, String>();
    Map<String, String> valueBUMap = new Map<String, String>();
    for (ER_DependentValue__c item : newItems) {
      if (
        item.ER_Business_Unit__c != null &&
        item.RecordTypeId ==
        Utils.getRecordTypeIdByDeveloperName(ER_DependentValue__c.SObjectType, Constants.CATEGORY_RT)
      ) {
        String masterLabel = item.ER_Business_Unit__c + Constants.CATEGORY_MAX_DEPT;
        depValBU.put(item.ER_Business_Unit__c, masterLabel);
      }
    }

    for (Global_Settings__mdt gSet : [
      SELECT Value__c, MasterLabel, Business_Unit__c
      FROM Global_Settings__mdt
      WHERE Business_Unit__c IN :depValBU.keySet() AND MasterLabel IN :depValBU.Values()
    ]) {
      if (gSet.Value__c != null) {
        valueBUMap.put(gSet.Business_Unit__c, gSet.Value__c);
      }
    }

    for (ER_DependentValue__c item : newItems) {
      item.ER_TECH_MaxLevelByBU__c = valueBUMap.get(item.ER_Business_Unit__c);
    }
  }
}