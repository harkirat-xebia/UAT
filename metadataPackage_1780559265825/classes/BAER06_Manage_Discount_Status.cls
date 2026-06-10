/*
----------------------------------------------------------------------
-- - Name          : BAER06_Manage_Discount_Status
-- - Author        : AAB
-- - Description   : Batch that manage discount codes statuses
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 28-APR-2022  VJOY                 1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
global class BAER06_Manage_Discount_Status implements Database.Batchable<sObject> {
  String query;

  global BAER06_Manage_Discount_Status(String aQuery) {
    query = aQuery;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    Database.QueryLocator qloc = Database.getQueryLocator(query);
    return qloc;
  }

  global void execute(Database.BatchableContext BC, List<ER_Promo_Code__c> aPromoCodeList) {
    APER39_DiscountCode_Mangement.ManageStatusDiscountCode(aPromoCodeList);
  }

  global void finish(Database.BatchableContext BC) {
  }
}