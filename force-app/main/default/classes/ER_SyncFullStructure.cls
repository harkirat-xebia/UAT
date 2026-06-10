/**
 * @author : AAM
 * @date : 27/06/2022
 * @desc : Synchronize structure
 */

public with sharing class ER_SyncFullStructure implements Queueable, Database.AllowsCallouts {
  public Contract ctr { get; set; }
  public String context { get; set; }
  public String params { get; set; }

  public ER_SyncFullStructure(Contract ctr, String context, String params) {
    this.ctr = ctr;
    this.context = context;
    this.params = params;
  }

  public void execute(QueueableContext ctxt) {
    System.debug('>>> ER_SyncFullStructure - *** Start *** ');
    APER30_AutoEnrollment_Management.syncRecordBU = ctr.ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    System.debug(
      '>>> ER_SyncFullStructure - APER30_AutoEnrollment_Management.syncRecordBU: ' +
      APER30_AutoEnrollment_Management.syncRecordBU
    );
    System.debug(
      '>>> ER_SyncFullStructure - APER06_WebserviceUtility.Offline_Sales_WS: ' +
      APER06_WebserviceUtility.Offline_Sales_WS
    );
    if (!APER06_WebserviceUtility.Offline_Sales_WS) {
      List<String> syncResultList = APHU12_Contract_Management.saveEdgWS(ctr.AccountId, ctr.Id);
      if (!syncResultList.isEmpty() && syncResultList[0] == 'succeeded')
        APER30_AutoEnrollment_Management.syncStructurePart2(ctr.AccountId, ctr.Id, params);
    }
    System.debug('>>> ER_SyncFullStructure - *** END *** ');
  }
}