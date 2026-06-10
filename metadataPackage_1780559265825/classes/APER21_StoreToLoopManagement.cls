public class APER21_StoreToLoopManagement {
  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Run Store to Loops creation
   * @param accountsToLoop
   */
  public static void runStoreToLoopCreation(List<ER_Account_to_Loop__c> accountsToLoop) {
    System.debug('>>>>> ALK - runStoreToLoopCreation accountsToLoop.size : ' + accountsToLoop.size());
    Map<Id, ER_Account_to_Loop__c> accountToLoopMap = new Map<Id, ER_Account_to_Loop__c>(accountsToLoop);
    Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
    dte.Transaction_Name__c = Constants.RUN_STORE_TO_LOOP_CREATION;
    System.debug(
      '>>>>> ALK - JSON.serializePretty(accountToLoopMap) length : ' +
      JSON.serializePretty(accountToLoopMap.keySet()).length()
    );
    dte.Transaction_Content__c = JSON.serializePretty(accountToLoopMap.keySet());
    EventBus.publish(dte);
  }

  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Run Store to Loops update
   * @param accountsToLoop
   */
  public static void runStoreToLoopUpdate(List<ER_Account_to_Loop__c> accountsToLoop) {
    System.debug('>>>>> ALK - runStoreToLoopUpdate accountsToLoop.size : ' + accountsToLoop.size());
    Map<Id, ER_Account_to_Loop__c> accountToLoopMap = new Map<Id, ER_Account_to_Loop__c>(accountsToLoop);
    Distributed_Transaction_Event__e dte = new Distributed_Transaction_Event__e();
    dte.Transaction_Name__c = Constants.RUN_STORE_TO_LOOP_UPDATE;
    System.debug(
      '>>>>> ALK - JSON.serializePretty(accountToLoopMap) length : ' +
      JSON.serializePretty(accountToLoopMap.keySet()).length()
    );
    dte.Transaction_Content__c = JSON.serializePretty(accountToLoopMap.keySet());
    EventBus.publish(dte);
  }

  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Create Store to Loops based on the new created Account To Loop
   * @param accountsToLoop
   */
  public static void createStoreToLoop(Set<Id> accountsToLoop) {
    System.debug('>>>>> ALK - createStoreToLoop accountsToLoop.size : ' + accountsToLoop.size());
    List<ER_Store_to_Loop__c> storesToLoop = new List<ER_Store_to_Loop__c>();
    Map<Id, List<ER_Account_to_Loop__c>> mapAccountATP = new Map<Id, List<ER_Account_to_Loop__c>>();

    System.debug('>>>>> ALK - accountsToLoop : ' + accountsToLoop);
    for (ER_Account_to_Loop__c atl : [
      SELECT Id, ER_Account__c, ER_Behaviour__c, ER_BUPicklist__c, ER_Loop__c, CurrencyIsoCode
      FROM ER_Account_to_Loop__c
      WHERE Id IN :accountsToLoop
    ]) {
      if (!mapAccountATP.containsKey(atl.ER_Account__c))
        mapAccountATP.put(atl.ER_Account__c, new List<ER_Account_to_Loop__c>());
      mapAccountATP.get(atl.ER_Account__c).add(atl);
    }
    System.debug('>>>>> ALK - mapAccountATP : ' + mapAccountATP.size());

    for (ER_Store__c s : [
      SELECT Id, ER_Financial_Center__r.ER_Account_Name__c, ER_BUPicklist__c
      FROM ER_Store__c
      WHERE ER_Financial_Center__r.ER_Account_Name__c IN :mapAccountATP.keySet()
    ]) {
      for (ER_Account_to_Loop__c atl : mapAccountATP.get(s.ER_Financial_Center__r.ER_Account_Name__c)) {
        storesToLoop.add(
          new ER_Store_to_Loop__c(
            ER_Loop__c = atl.ER_Loop__c,
            ER_Store__c = s.Id,
            ER_Behaviour__c = atl.ER_Behaviour__c,
            ER_BUPicklist__c = s.ER_BUPicklist__c,
            CurrencyIsoCode = atl.CurrencyIsoCode
          )
        );
      }
    }

    System.debug('>>>>> ALK - createStoreToLoop storesToLoop : ' + storesToLoop.size());
    if (!storesToLoop.isEmpty())
      Database.insert(storesToLoop, false);
  }

  /**
   * @author ALK
   * @date 05/02/2023
   * @description CODE REVIEW - Update Store to Loops based on the new created Account To Loop
   * @param accountsToLoop
   */
  public static void updateStoreToLoop(Set<Id> accountsToLoop) {
    System.debug('>>>>> ALK - updateStoreToLoop accountsToLoop.size : ' + accountsToLoop.size());
    List<ER_Store_to_Loop__c> storesToLoop = new List<ER_Store_to_Loop__c>();
    Map<Id, List<ER_Account_to_Loop__c>> mapAccountATP = new Map<Id, List<ER_Account_to_Loop__c>>();

    System.debug('>>>>> ALK - accountsToLoop : ' + accountsToLoop);
    for (ER_Account_to_Loop__c atl : [
      SELECT Id, ER_Account__c, ER_Behaviour__c, ER_BUPicklist__c, ER_Loop__c
      FROM ER_Account_to_Loop__c
      WHERE Id IN :accountsToLoop
    ]) {
      if (!mapAccountATP.containsKey(atl.ER_Account__c))
        mapAccountATP.put(atl.ER_Account__c, new List<ER_Account_to_Loop__c>());
      mapAccountATP.get(atl.ER_Account__c).add(atl);
    }
    System.debug('>>>>> ALK - mapAccountATP : ' + mapAccountATP.size());

    for (ER_Store_to_Loop__c stl : [
      SELECT Id, ER_Store__c, ER_Loop__c, ER_Behaviour__c, ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c
      FROM ER_Store_to_Loop__c
      WHERE ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c IN :mapAccountATP.keySet()
    ]) {
      for (ER_Account_to_Loop__c atl : mapAccountATP.get(stl.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c)) {
        if (stl.ER_Loop__c == atl.ER_Loop__c)
          storesToLoop.add(new ER_Store_to_Loop__c(Id = stl.Id, ER_Behaviour__c = atl.ER_Behaviour__c));
      }
    }

    System.debug('>>>>> ALK - updateStoreToLoop storesToLoop : ' + storesToLoop.size());
    if (!storesToLoop.isEmpty())
      Database.update(storesToLoop, false);
  }

  public static void CreatenewStoreToLoopOnStoreInsert(List<ER_Store__c> NewStoreList) {
    Set<Id> AccountSet = new Set<Id>();
    Set<Id> FinancialCenterSet = new Set<Id>();
    Map<Id, List<ER_Store__c>> AccountToStoreListMap = new Map<id, List<ER_Store__c>>();
    List<ER_Store__c> StoreList;
    for (ER_Store__c InsertedStores : NewStoreList) {
      FinancialCenterSet.add(InsertedStores.ER_Financial_Center__c);
    }
    List<ER_Financial_Center__c> relatedAccounts = [
      SELECT id, ER_Account_Name__c
      FROM ER_Financial_Center__c
      WHERE id IN :FinancialCenterSet
    ];
    Map<id, id> FcToAccountMap = new Map<Id, Id>();
    for (ER_Financial_Center__c fctoaccount : relatedAccounts) {
      FcToAccountMap.put(fctoaccount.id, fctoaccount.ER_Account_Name__c);
      AccountSet.add(fctoaccount.ER_Account_Name__c);
    }

    for (ER_Store__c stores : NewStoreList) {
      Id Accountid = FcToAccountMap.get(stores.ER_Financial_Center__c);
      system.debug('stores.ER_Financial_Center__c : ' + stores.ER_Financial_Center__c);
      system.debug('Account id : ' + FcToAccountMap.get(stores.ER_Financial_Center__c));
      StoreList = new List<ER_Store__c>();
      StoreList.add(stores);
      if (AccountToStoreListMap.containsKey(Accountid)) {
        StoreList.addAll(AccountToStoreListMap.get(Accountid));
      }
      AccountToStoreListMap.put(Accountid, StoreList);
    }
    system.debug('AccountSet : ' + AccountSet);
    List<ER_Account_to_Loop__c> AccountToLoops = [
      SELECT Id, Name, ER_Account__c, ER_Loop__c, ER_Behaviour__c, ER_Business_Unit__c
      FROM ER_Account_to_Loop__c
      WHERE ER_Account__c IN :AccountSet
    ];
    system.debug('AccountToLoops : ' + AccountToLoops);
    List<ER_Store__c> StoreToAdd;
    List<ER_Store_to_Loop__c> StoreToLoopToAdd = new List<ER_Store_to_Loop__c>();
    ER_Store_to_Loop__c NewStoreToLoop;
    for (ER_Account_to_Loop__c accToLoops : AccountToLoops) {
      StoreToAdd = AccountToStoreListMap.get(accToLoops.ER_Account__c);
      for (ER_Store__c strToLoopToAdd : StoreToAdd) {
        NewStoreToLoop = new ER_Store_to_Loop__c(
          ER_Store__c = strToLoopToAdd.Id,
          ER_Behaviour__c = accToLoops.ER_Behaviour__c,
          ER_Loop__c = accToLoops.ER_Loop__c
        );
        StoreToLoopToAdd.add(NewStoreToLoop);
      }
    }
    system.debug('StoreToLoopToAdd : ' + StoreToLoopToAdd);
    if (!StoreToLoopToAdd.isEmpty()) {
      insert StoreToLoopToAdd;
    }
  }

  /**
   *  @author ALK
   *  @date 05/02/2023
   *  @description CODE REVIEW - Check if we have an existing Store to loop with the same Store and Same Loop
   * @param newItems
   */
  public static void checkDuplicateStoreToLoop(List<ER_Store_to_Loop__c> newItems) {
    Map<Id, List<ER_Store_to_Loop__c>> mapStoreSTL = new Map<Id, List<ER_Store_to_Loop__c>>();

    for (ER_Store_to_Loop__c stl : newItems) {
      if (!mapStoreSTL.containsKey(stl.ER_Store__c))
        mapStoreSTL.put(stl.ER_Store__c, new List<ER_Store_to_Loop__c>());
      mapStoreSTL.get(stl.ER_Store__c).add(stl);
    }

    for (ER_Store_to_Loop__c stl : [
      SELECT Id, Name, ER_Store__c, ER_Loop__c, ER_Behaviour__c, ER_Business_Unit__c
      FROM ER_Store_to_Loop__c
      WHERE ER_Store__c IN :mapStoreSTL.keySet()
      LIMIT 50000
    ]) {
      for (ER_Store_to_Loop__c newSTL : mapStoreSTL.get(stl.ER_Store__c)) {
        if (stl.ER_Store__c == newSTL.ER_Store__c && stl.ER_Loop__c == newSTL.ER_Loop__c && stl.Id != newSTL.Id)
          newSTL.addError(Label.LABS_SF_Duplicate_Value + ' ' + stl.Id);
      }
    }
  }
}