/*
----------------------------------------------------------------------
-- - Name          : APER32_Product2_Management
-- - Author        : AAZ
-- - Description   : Product2 Management   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- JUN-2021     AAZ                 1.0         Initial version
---------------------------------------------------------------------------------------
*/

public with sharing class APER32_Product2_Management {
  /**
   * @author AAZ
   * @date 24/06/2021
   * @description Activate all Zuora products created by Zuora API.
   * @param newZuoraSolutions
   */
  public static void activateZuoraProducts(List<Product2> newZuoraSolutions) {
    List<String> zuoraDeployedBU = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU)
      ?.split(Constants.SEMICOLON);

    for (Product2 p : newZuoraSolutions) {
      if (
        String.isNotBlank(p.ER_BUPicklist__c) &&
        zuoraDeployedBU.contains(p.ER_BUPicklist__c) &&
        ((p.zqu__EffectiveEndDate__c != null && p.zqu__EffectiveEndDate__c >= Date.today()) ||
        (p.zqu__EffectiveEndDate__c == null &&
        p.zqu__EffectiveStartDate__c <= Date.today()))
      ) {
        p.IsActive = true;
        p.ProductCode = p.BU_External_Reference__c;
        p.CurrencyIsoCode = (String.isNotBlank(Utils.getGlobalSettingsValueFromKey(p.ER_BUPicklist__c + '_Currency'))
          ? Utils.getGlobalSettingsValueFromKey(p.ER_BUPicklist__c + '_Currency')
          : Constants.CURRENCY_EUR);
      }
    }
  }

  /**
   * @author AAZ
   * @date 24/06/2021
   * @description Zuora Product should be automatically added to Standard PriceBook.
   * @param newZuoraSolutions
   */
  public static void addProductToStandardPriceBook(List<Product2> newZuoraSolutions) {
    List<PricebookEntry> listPBE = new List<PricebookEntry>();
    Map<Id, Product2> mapSolution = new Map<Id, Product2>(newZuoraSolutions);
    Set<Id> setPdctIdHavingPbe = new Set<Id>();
    List<String> zuoraDeployedBU = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU)
      ?.split(Constants.SEMICOLON);

    List<Pricebook2> stdPB = [
      SELECT Id
      FROM Pricebook2
      WHERE IsActive = TRUE AND IsStandard = TRUE AND Name = 'Standard Price Book'
    ];

    if (!stdPB.isEmpty()) {
      for (PricebookEntry pbe : [
        SELECT Id, Product2Id
        FROM PricebookEntry
        WHERE Product2Id IN :mapSolution.keySet() AND Pricebook2Id = :stdPB[0].Id
      ]) {
        setPdctIdHavingPbe.add(pbe.Product2Id);
      }

      for (Product2 p : newZuoraSolutions) {
        if (
          String.isNotBlank(p.ER_Business_Unit__c) &&
          zuoraDeployedBU.contains(p.ER_Business_Unit__c) &&
          String.isNotBlank(p.zqu__ZuoraId__c) &&
          !setPdctIdHavingPbe.contains(p.Id)
        ) {
          listPBE.add(
            new PricebookEntry(
              Pricebook2Id = stdPB[0].Id,
              Product2Id = p.Id,
              UnitPrice = 0,
              ER_ValueType__c = 'Currency',
              CurrencyIsoCode = p.CurrencyIsoCode
            )
          );
        }
      }

      if (!listPBE.isEmpty())
        Database.insert(listPBE, false);
    }
  }

    /**
     * @author AAM
     * @date 28/10/2021
     * @description Get Solution ID using Solution Code
     * @param solutionCode
     * @return
     */
    public static String getSolutionId(String solutionCode) {
      List<Product2> products = [SELECT Id FROM Product2
                                  WHERE ER_Type__c = 'Solution'
                                  AND IsActive = TRUE
                                  AND ProductCode = :solutionCode];
      if(!products.isEmpty()) return products[0].Id;
      return null;
  }

  /**
   * @author Noor
   * @date 20/05/2022
   * @description updateRangeCounterOnService
   * @param solutions new or deleted solutions
   */
  public static void updateRangeAndDiscountCounterOnService(List<Product2> solutions) {
    String recordTypeNameRangeId = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Range');
    String recordTypeNameDiscountId = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Discount');

    Set<Id> parentRangeIds = new Set<Id>();
    Set<Id> parentDiscountIds = new Set<Id>();

    for (Product2 p : solutions) {
      if (p.RecordTypeId == recordTypeNameRangeId)
        parentRangeIds.add(p.ER_Solution__c);
      if (p.RecordTypeId == recordTypeNameDiscountId)
        parentDiscountIds.add(p.ER_Solution__c);
    }

    if (!parentRangeIds.isEmpty())
      updateRangeCounterOnService(parentRangeIds, recordTypeNameRangeId);
    if (!parentDiscountIds.isEmpty())
      updateDiscountCounterOnService(parentDiscountIds, recordTypeNameDiscountId);
  }

  /**
   * @author Noor
   * @date 20/05/2022
   * @description update ER_Service_Number_of_Ranges__c on Service
   * @param serviceIds service ids for Range
   * @param rangeRT recordType Id for range
   */
  private static void updateRangeCounterOnService(Set<Id> serviceIds, String rangeRT) {
    List<Product2> productToUpdate = new List<Product2>();
    for (Product2 p : [
      SELECT Id, (SELECT Id FROM Services__r WHERE RecordTypeId = :rangeRT)
      FROM Product2
      WHERE Id IN :serviceIds
    ])
      productToUpdate.add(new Product2(Id = p.Id, ER_Service_Number_of_Ranges__c = p.Services__r.size()));

    if (!productToUpdate.isEmpty())
      update productToUpdate;
  }

  /**
   * @author Noor
   * @date 20/05/2022
   * @description update ER_Number_of_Discount_Products__c on Service
   * @param serviceIds service Ids for Discount
   * @param discountRT record Type Id for Discount
   */
  private static void updateDiscountCounterOnService(Set<Id> serviceIds, String discountRT) {
    List<Product2> productToUpdate = new List<Product2>();
    for (Product2 p : [
      SELECT Id, (SELECT Id FROM Services__r WHERE RecordTypeId = :discountRT)
      FROM Product2
      WHERE Id IN :serviceIds
    ])
      productToUpdate.add(new Product2(Id = p.Id, ER_Number_of_Discount_Products__c = p.Services__r.size()));

    if (!productToUpdate.isEmpty())
      update productToUpdate;
  }

  /**
   * @author Noor
   * @date 20/05/2022
   * @description populate Range And Discount Product from Service
   * @param solutions
   */
  public static void populateRangeAndDiscountProduct(List<Product2> solutions) {
    List<String> allowRecordTypes = new List<String>{
      Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Range'),
      Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, 'Discount')
    };
    Set<Id> parentIds = new Set<Id>();

    for (Product2 s : solutions)
      if (String.isNotBlank(s.ER_Solution__c))
        parentIds.add(s.ER_Solution__c);

    List<String> rangeOrDiscountType = new List<String>{ 'Range', 'Discount' };

    if (!parentIds.isEmpty()) {
      Map<Id, Product2> parentMap = new Map<Id, Product2>(
        [
          SELECT
            Id,
            QuantityUnitOfMeasure,
            ER_Hidden_In_PDF__c,
            ER_Do_Not_Synchronize__c,
            ER_Line_Order__c,
            CurrencyIsoCode,
            ER_BUPicklist__c,
            ER_Minimum_Fee__c,
            ER_MUC__c,
            ER_Solution2__r.ER_Minimum_Fee__c,
            ProductCode,
            ER_Solution__c,
            ER_Solution__r.ER_Solution__c,
            ER_Type__c,
            ER_Solution__r.ER_Type__c
          FROM Product2
          WHERE Id IN :parentIds
        ]
      );

      for (Product2 p : solutions) {
        //For product range and discount
        if (allowRecordTypes.contains(p.RecordTypeId)) {
          p.QuantityUnitOfMeasure = parentMap.get(p.ER_Solution__c).QuantityUnitOfMeasure;
          p.ER_Hidden_In_PDF__c = parentMap.get(p.ER_Solution__c).ER_Hidden_In_PDF__c;
          p.ER_Do_Not_Synchronize__c = parentMap.get(p.ER_Solution__c).ER_Do_Not_Synchronize__c;
          p.ER_Line_Order__c = parentMap.get(p.ER_Solution__c).ER_Line_Order__c;
          p.CurrencyIsoCode = parentMap.get(p.ER_Solution__c).CurrencyIsoCode;
          p.ER_BUPicklist__c = parentMap.get(p.ER_Solution__c).ER_BUPicklist__c;
          p.ER_MUC__c = parentMap.get(p.ER_Solution__c).ER_MUC__c;
          p.ER_Minimum_Fee__c = parentMap.get(p.ER_Solution__c).ER_Minimum_Fee__c;
          p.ProductCode = parentMap.get(p.ER_Solution__c).ProductCode;
        }
        //For Type Solution
        if (p.ER_Solution__c != null && parentMap.get(p.ER_Solution__c).ER_Type__c == 'Solution')
          p.ER_Solution2__c = p.ER_Solution__c;

        //For Type Range Or discount and parent Type Service
        if (
          parentMap.get(p.ER_Solution__c).ER_Solution__c != null &&
          rangeOrDiscountType.contains(p.ER_Type__c) &&
          parentMap.get(p.ER_Solution__c).ER_Type__c == 'Service'
        )
          p.ER_Solution2__c = parentMap.get(p.ER_Solution__c).ER_Solution__c;

        //For Type Discount and parent Type Range
        if (
          parentMap.get(p.ER_Solution__c).ER_Solution__r.ER_Solution__c != null &&
          p.ER_Type__c == 'Discount' &&
          parentMap.get(p.ER_Solution__c).ER_Type__c == 'Range'
        )
          p.ER_Solution2__c = parentMap.get(p.ER_Solution__c).ER_Solution__r.ER_Solution__c;
      }
    }
  }

  /**
   * @author AAM
   * @date 24/03/2023
   * @description Get Solution Name using Solution Code
   * @param solutionCode
   * @return
   */
  public static String getSolutionName(String solutionCode, String BusinessUnit) {
    return [
      SELECT Id, Name
      FROM Product2
      WHERE
        ER_Type__c = 'Solution'
        AND IsActive = TRUE
        AND ER_BUPicklist__c = :BusinessUnit
        AND ProductCode = :solutionCode
    ][0]
    ?.Name;
  }

  /**
   * @author AAM
   * @date 27/03/2023
   * @description Get Solution services using Solution Code
   * @param solutionCode
   * @return
   */
  public static List<Product2> getSolutionServices(String solutionCode) {
    return [
      SELECT Id, ProductCode, Name
      FROM Product2
      WHERE
        ER_Type__c = 'Service'
        AND IsActive = TRUE
        AND ER_Solution__r.ER_Type__c = 'Solution'
        AND ER_Solution__r.IsActive = TRUE
        AND ER_Solution__r.ProductCode = :solutionCode
    ];
  }
}