trigger TRER11_StoreLineItemAfterUpdate on ER_Store_Line_Item__c(before update) {
  Map<id, ER_Store_Line_Item__c> OldStriMap = Trigger.oldMap;
  Map<id, ER_Store_Line_Item__c> NewStriMap = Trigger.newMap;
  Set<id> SliIds = Trigger.newMap.keySet();
  List<ER_Store_Line_Item__c> SliList = [
    SELECT
      id,
      ER_Store__c,
      ER_Store__r.ER_Solution_Count__c,
      ER_Status__c,
      ER_Store__r.ER_Business_Unit__c,
      ER_Store__r.ER_Creation_Date_In_OS__c,
      ER_Store__r.CreatedDate,
      ER_Store__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c
    FROM ER_Store_Line_Item__c
    WHERE id IN :SliIds
  ];
  if (APER10_User_Management.canTrigger) {
    System.debug('###:TRER11_StoreLineItemAfterUpdate  Start');
    for (ER_Store_Line_Item__c sli : SliList) {
      if (OldStriMap.get(sli.Id).ER_Status__c != sli.ER_Status__c && sli.ER_Store__r.ER_Solution_Count__c != 0) {
        if (
          sli.ER_Store__r.ER_Business_Unit__c == 'CZ' &&
          ((sli.ER_Store__r.ER_Creation_Date_In_OS__c == null &&
          sli.ER_Store__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null &&
          sli.ER_Store__r.CreatedDate >= sli.ER_Store__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c) ||
          (sli.ER_Store__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c != null &&
          (sli.ER_Store__r.CreatedDate < sli.ER_Store__r.ER_Financial_Center__r.ER_Creation_date_in_OS__c ||
          sli.ER_Store__r.ER_Creation_date_in_OS__c != null)))
        ) {
          WSCZ01_SynchronizeStoreWS.updateAddStoreFuture(sli.ER_Store__c);
        }
      }
    }

    /*
        for(ER_Store_Line_Item__c Stri : NewStriMap.values())
        {
            if(OldStriMap.get(Stri.Id).ER_Status__c != Stri.ER_Status__c && Stri.ER_Store__r.ER_Solution_Count__c != 0)
            {
               //WSCZ01_SynchronizeStoreWS.updateAddStore(Stri.ER_Store__c);
                WSCZ01_SynchronizeStoreWS.updateAddStoreFuture(Stri.ER_Store__c);
            }
        } */

    System.debug('###:TRER11_StoreLineItemAfterUpdate End');
  }

}