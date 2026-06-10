/*
----------------------------------------------------------------------
-- - Name          : BAER03_DeleteSpamCases
-- - Author        : AAB
-- - Description   : Batch that retrieve all spam closed cases and hard delete them   
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 09-MAR-2021  VJOY                 1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
global class BAER03_DeleteSpamCases implements Database.Batchable<sObject> {
  String query;

  global BAER03_DeleteSpamCases(String aQuery) {
    query = aQuery;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    Database.QueryLocator qloc = Database.getQueryLocator(query);
    return qloc;
  }

  global void execute(Database.BatchableContext BC, List<Case> aSpamCasesList) {
    APER08_Case_Management.deleteSpamCases(aSpamCasesList);
  }

  global void finish(Database.BatchableContext BC) {
  }
}