/*
----------------------------------------------------------------------
-- - Name          : APER39_DiscountCode_Mangement
-- - Author        : VJOY
-- - Description   : Discount Code Management, This class is used to group all the functionnality linked to the object Discount Codes(ER_Promo_Code__c)
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  MAR-2022    VJOY                1.0         Initial version
---------------------------------------------------------------------------------------
*/

public class APER39_DiscountCode_Mangement {
  /**
   * @author VJOY
   * @date 27/03/2022
   * @description Remove all expired discount codes from open opportunities
   * @param items
   */
  public static void removeDiscountCodesFromOpenOpportunities(
    List<ER_Promo_Code__c> newItems,
    Map<Id, ER_Promo_Code__c> oldPromoMap
  ) {
    if (UtilsBypass.canTrigger('removeDiscountCodesFromOpenOpportunities')) {
      List<Opportunity> oppList = new List<Opportunity>();
      Set<Id> promoCodeIdSet = new Set<Id>();
      Set<Id> opportunityIdSet = new Set<Id>();

      for (ER_Promo_Code__c p : newItems)
        if ((p.ER_Status__c != oldPromoMap.get(p.Id).ER_Status__c) && (p.ER_Status__c == 'Expired'))
          promoCodeIdSet.add(p.Id);

      for (Opportunity o : [
        SELECT Id
        FROM Opportunity
        WHERE ER_Promo_Code2__c IN :promoCodeIdSet AND isClosed = FALSE
      ]) {
        opportunityIdSet.add(o.Id);
      }

      for (Quote q : [
        SELECT Id, OpportunityId
        FROM Quote
        WHERE Opportunity.ER_Promo_Code2__c IN :promoCodeIdSet AND Status != 'Draft'
        LIMIT 50000
      ]) {
        opportunityIdSet.remove(q.OpportunityId);
      }

      for (Opportunity o : [SELECT Id FROM Opportunity WHERE Id IN :opportunityIdSet]) {
        o.ER_Promo_Code2__c = null;
        oppList.add(o);
      }

      if (!oppList.isEmpty())
        update oppList;
    }
  }

  /**
   * @author VJOY
   * @date 12/04/2022
   * @description Check Uniqueness of Discount Codes
   * @param items
   **/
  public static void checkUnicityForDiscountCodes(List<ER_Promo_Code__c> newItems) {
    String uniqueCodeContract;
    String uniqueCodeName;

    for (ER_Promo_Code__c p : newItems) {
      if (p.ER_Promo_Code__c != null) {
        try {
          p.ER_Name_Key__c = p.Name + '_' + p.ER_Business_Unit__c;
          if (p.ER_Contract__c != null)
            p.ER_Code_Key__c = p.ER_Promo_Code__c + '_' + p.ER_Contract__c + '_' + p.ER_Business_Unit__c;
          else
            p.ER_Code_Key__c = p.ER_Promo_Code__c + '_' + p.ER_Business_Unit__c;
        } catch (Exception e) {
          if (e.getMessage().contains('duplicate'))
            p.addError('Discount Code is not unique.');
        }
      }
    }
  }

  /**
   * @author VJOY
   * @date 12/04/2022
   * @description Check if Contract is associated with other Affliation Codes
   * @param items
   **/
  public static void checkForDiscountCodesContractUpdate(
    List<ER_Promo_Code__c> newItems,
    Map<Id, ER_Promo_Code__c> oldPromoMap
  ) {
    List<ER_Promo_Code__c> promoCodeList = new List<ER_Promo_Code__c>();

    for (ER_Promo_Code__c p : newItems) {
      if (p.ER_Contract__c != null && p.ER_Contract__c != oldPromoMap.get(p.Id).ER_Contract__c)
        promoCodeList.add(p);
    }

    checkForDiscountCodesContract(promoCodeList);
  }

  /**
   * @author VJOY
   * @date 12/04/2022
   * @description Check if Contract is associated with other Affliation Codes
   * @param items
   **/
  public static void checkForDiscountCodesContract(List<ER_Promo_Code__c> newItems) {
    Map<ER_Promo_Code__c, Id> contractIdByPromoCodeMap = new Map<ER_Promo_Code__c, Id>();
    Map<Id, List<ER_Promo_Code__c>> promoCodeByListContractIdMap = new Map<Id, List<ER_Promo_Code__c>>();

    Id AffiliationCode = Schema.SObjectType.ER_Promo_Code__c.getRecordTypeInfosByDeveloperName()
      .get('ER_Affiliation_Code')
      .getRecordTypeId();

    for (ER_Promo_Code__c p : newItems) {
      if (p.RecordTypeId != AffiliationCode && p.ER_Contract__c == null)
        continue;
      contractIdByPromoCodeMap.put(p, p.ER_Contract__c);
      if (!promoCodeByListContractIdMap.containsKey(p.ER_Contract__c))
        promoCodeByListContractIdMap.put(p.ER_Contract__c, new List<ER_Promo_Code__c>());
      promoCodeByListContractIdMap.get(p.ER_Contract__c).add(p);
    }

    for (ER_Promo_Code__c p : [
      SELECT Id, ER_Contract__c, ER_Promo_Code__c
      FROM ER_Promo_Code__c
      WHERE ER_Contract__c IN :contractIdByPromoCodeMap.values()
    ]) {
      if (promoCodeByListContractIdMap.containsKey(p.ER_Contract__c)) {
        for (ER_Promo_Code__c pc : promoCodeByListContractIdMap.get(p.ER_Contract__c)) {
          pc.addError('This contract is already associated with an affiliation code');
        }
      }
    }
  }

  public static void ManageStatusDiscountCode(List<ER_Promo_Code__c> aDiscountCodeList) {
    Map<Id, ER_Promo_Code__c> promoCodeByContractMap = new Map<Id, ER_Promo_Code__c>();
    List<ER_Promo_Code__c> discountCodeToUpdateList = new List<ER_Promo_Code__c>();
    Id AffiliationCode = Schema.SObjectType.ER_Promo_Code__c.getRecordTypeInfosByDeveloperName()
      .get('ER_Affiliation_Code')
      .getRecordTypeId();

    for (ER_Promo_Code__c p : aDiscountCodeList) {
      if (p.RecordTypeId == AffiliationCode && p.ER_Contract__c != null) {
        //affiliation code
        promoCodeByContractMap.put(p.ER_Contract__c, p);
      } else if (p.RecordTypeId != AffiliationCode) {
        //promo code
        if (p.ER_Start_Date__c > Date.today())
          p.ER_Status__c = 'Draft';
        else if (p.ER_End_Date__c == null) {
          if (p.ER_Start_Date__c != null)
            p.ER_Status__c = 'Activated';
          else
            p.ER_Status__c = 'Draft';
        } else if (p.ER_End_Date__c < Date.today())
          p.ER_Status__c = 'Expired';
        else
          p.ER_Status__c = 'Activated';

        discountCodeToUpdateList.add(p);
      }
    }

    if (promoCodeByContractMap.size() > 0) {
      for (Contract c : [SELECT Id, StartDate, EndDate FROM Contract WHERE Id IN :promoCodeByContractMap.keySet()]) {
        if (c.StartDate > Date.today())
          promoCodeByContractMap.get(c.Id).ER_Status__c = 'Draft';
        else if (c.EndDate == null) {
          if (c.StartDate != null)
            promoCodeByContractMap.get(c.Id).ER_Status__c = 'Activated';
          else
            promoCodeByContractMap.get(c.Id).ER_Status__c = 'Draft';
        } else if (c.EndDate < Date.today())
          promoCodeByContractMap.get(c.Id).ER_Status__c = 'Expired';
        else
          promoCodeByContractMap.get(c.Id).ER_Status__c = 'Activated';

        discountCodeToUpdateList.add(promoCodeByContractMap.get(c.Id));
      }
    }

    try {
      if (!discountCodeToUpdateList.isEmpty())
        Database.update(discountCodeToUpdateList, false);
    } catch (Exception e) {
      System.debug('Error found ' + e.getMessage());
    }
  }

  /**
   * @author VJOY
   * @date 04/05/2022
   * @description Set Discount Code Status
   * @param items
   **/
  public static void setDiscountCodeStatus(List<ER_Promo_Code__c> aPromoCodeList) {
    Map<Id, ER_Promo_Code__c> promoCodeByContractMap = new Map<Id, ER_Promo_Code__c>();

    Id AffiliationCode = Schema.SObjectType.ER_Promo_Code__c.getRecordTypeInfosByDeveloperName()
      .get('ER_Affiliation_Code')
      .getRecordTypeId();

    for (ER_Promo_Code__c p : aPromoCodeList) {
      if (p.RecordTypeId == AffiliationCode && p.ER_Contract__c != null) {
        //affiliation code
        promoCodeByContractMap.put(p.ER_Contract__c, p);
      } else if (p.RecordTypeId != AffiliationCode) {
        //promo code
        if (p.ER_Start_Date__c > Date.today())
          p.ER_Status__c = 'Draft';
        else if (p.ER_End_Date__c == null) {
          if (p.ER_Start_Date__c != null)
            p.ER_Status__c = 'Activated';
          else
            p.ER_Status__c = 'Draft';
        } else if (p.ER_End_Date__c < Date.today())
          p.ER_Status__c = 'Expired';
        else
          p.ER_Status__c = 'Activated';
      }
    }

    if (promoCodeByContractMap.size() > 0) {
      for (Contract c : [SELECT Id, StartDate, EndDate FROM Contract WHERE Id IN :promoCodeByContractMap.keySet()]) {
        if (c.StartDate > Date.today())
          promoCodeByContractMap.get(c.Id).ER_Status__c = 'Draft';
        else if (c.EndDate == null) {
          if (c.StartDate != null)
            promoCodeByContractMap.get(c.Id).ER_Status__c = 'Activated';
          else
            promoCodeByContractMap.get(c.Id).ER_Status__c = 'Draft';
        } else if (c.EndDate < Date.today())
          promoCodeByContractMap.get(c.Id).ER_Status__c = 'Expired';
        else
          promoCodeByContractMap.get(c.Id).ER_Status__c = 'Activated';
      }
    }
  }

  /**
   * @author VJOY
   * @date 12/05/2022
   * @description Deactivate affilication codes for terminated contracts
   * @param contactsIds
   */
  public static void deactivateAffiliationCodesForTerminatedContracts(Set<Id> contactsIds) {
    Set<Id> terminatedContractIdSet = new Set<Id>();
    List<ER_Promo_Code__c> promoCodeToDeactivateList = new List<ER_Promo_Code__c>();

    for (Contract c : [
      SELECT Id, Status
      FROM Contract
      WHERE Id IN :contactsIds AND Status = :Label.LABS_SF_Contract_Status_Terminated
    ]) {
      terminatedContractIdSet.add(c.Id);
    }

    if (!terminatedContractIdSet.isEmpty()) {
      for (ER_Promo_Code__c p : [
        SELECT Id
        FROM ER_Promo_Code__c
        WHERE ER_Contract__c IN :terminatedContractIdSet AND ER_Status__c != 'Expired' AND ER_Contract__c != NULL
      ]) {
        p.ER_Status__c = 'Expired';
        promoCodeToDeactivateList.add(p);
      }

      if (!promoCodeToDeactivateList.isEmpty())
        Database.update(promoCodeToDeactivateList, false);
    }
  }

  /**
   * @author Pranjal:  Xebia
   * @date 25/07/2025
   * @description Updated Related Pricebook Enteries
   * @param items
   **/
  public static void updateDatesOnPricebookEnteries(
    List<ER_Promo_Code__c> newItems,
    Map<Id, ER_Promo_Code__c> oldPromoMap
  ) {
    List<PricebookEntry> pbeListToUpdate = new List<PricebookEntry>();
    Set<Id> promoIdSet = new Set<Id>();
    Map<Id,ER_Promo_Code__c>  proIdObjectMap = new Map<Id,ER_Promo_Code__c>();
    for(ER_Promo_Code__c promoObj : newItems){
      Boolean isStartDateChanged = promoObj.ER_Start_Date__c != null && oldPromoMap.get(promoObj.Id).ER_Start_Date__c != promoObj.ER_Start_Date__c;
      Boolean isEndDateChanged = promoObj.ER_End_Date__c != null && oldPromoMap.get(promoObj.Id).ER_End_Date__c != promoObj.ER_End_Date__c;
      if(isStartDateChanged || isEndDateChanged){
        promoIdSet.add(promoObj.Id);
        proIdObjectMap.put(promoObj.Id, promoObj);
      }
      
    }

    if(!promoIdSet.isEmpty()){
      for(PricebookEntry pbe : [Select Id, ER_Offer_validity_start_date__c, ER_Offer_validity_end_date__c, ER_Promo_Code2__c FROM PricebookEntry WHERE ER_Promo_Code2__c IN: promoIdSet]){
        pbe.ER_Offer_validity_start_date__c = proIdObjectMap.get(pbe.ER_Promo_Code2__c).ER_Start_Date__c;
        pbe.ER_Offer_validity_end_date__c = proIdObjectMap.get(pbe.ER_Promo_Code2__c).ER_End_Date__c;
        pbeListToUpdate.add(pbe);
      } 
    }

    if(!pbeListToUpdate.isEmpty()){
      update pbeListToUpdate;
    }

  }

  public static void insertPbeForDiscountCodes(List<ER_Promo_Code__c> newDiscountCodes) {
        if (newDiscountCodes.isEmpty()) return;

        Set<Id> discountCodeIds = new Set<Id>();
        for (ER_Promo_Code__c dc : newDiscountCodes) {
            discountCodeIds.add(dc.Id);
        }
        //Database.executeBatch(new CreateDiscountedProductsBatch(discountCodeIds), 1);
    }
}