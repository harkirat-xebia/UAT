/*
----------------------------------------------------------------------
-- - Name          : BAER02_SetInactiveAcceptor
-- - Author        : RBR
-- - Description   : Batch that retrieve all inactive acceptor    
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 10-MAR-2020  RBR                 1.0         Initial version
--  
---------------------------------------------------------------------------------------
*/
global with sharing class BAER02_SetInactiveAcceptor implements Schedulable, Database.Batchable<sObject> {
  global void execute(System.SchedulableContext bc) {
    Database.executeBatch(new BAER02_SetInactiveAcceptor());
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    //Get all acceptors that End Date already expire.
    return Database.getQueryLocator(
      'SELECT Id, ER_Status__c , ER_End_Date__c FROM ER_Acceptor__c WHERE ER_End_Date__c <= TODAY'
    );
  }

  global void execute(Database.BatchableContext bc, List<ER_Acceptor__c> scope) {
    //Set the acceptor to Inactve and update them
    APER23_Acceptor_Management.setInactiveAcceptors(scope);
  }

  global void finish(Database.BatchableContext bc) {
    // execute any post-processing operations
  }
}