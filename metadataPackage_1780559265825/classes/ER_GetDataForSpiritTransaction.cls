/**
 * @author : AAZ
 * @date : 09/05/2021
 * @desc : ERPL_GetDataForSpirit - This Custom REST API will be used to return needed data for Spirit
 * @see ERPL_GetDataForSpirit
 */

@RestResource(UrlMapping='/getDataForSpiritTransaction/*')
global with sharing class ER_GetDataForSpiritTransaction {
  /**
   * @author AAZ
   * @date 07/05/2021
   * @description Get Data to be sent to SPIRIT - Get all structure objects created or updated since a date in param for a BU
   * @return
   * ERROR CODE DESCRIPTION
   *  0 - Success
   *  1- No Acceptor found or many acceptors found for the authorizationMID provided and starting before the transaction date
   *  2- Contract at the transaction date (No active Contract / Subscription for the provided solution at the transaction date).
   *  3- Contract / Subscription Found but not active at the transaction date for the provided solution
   */
  @HttpPost
  global static List<SpiritStructureResponse> doPost(List<SpiritStructureRequest> Usages) {
    Map<String, List<ER_GetDataForSpiritTransaction.SpiritStructureRequest>> mapAuthMIDRequest = new Map<String, List<ER_GetDataForSpiritTransaction.SpiritStructureRequest>>();
    Map<Integer, List<ER_Acceptor__c>> mapRule1 = new Map<Integer, List<ER_Acceptor__c>>();
    Map<Integer, List<ER_Acceptor__c>> mapRule2 = new Map<Integer, List<ER_Acceptor__c>>();
    Map<Integer, List<ER_Acceptor__c>> mapRule3 = new Map<Integer, List<ER_Acceptor__c>>();
    Map<Integer, List<ER_Acceptor__c>> mapRule4 = new Map<Integer, List<ER_Acceptor__c>>();
    Map<Integer, List<ER_Acceptor__c>> mapRule5 = new Map<Integer, List<ER_Acceptor__c>>();
    Set<String> bus = new Set<String>();
    Map<Integer, ER_Acceptor__c> mapCheckinAcceptor = new Map<Integer, ER_Acceptor__c>();
    Map<Integer, Id> mapCheckinFC = new Map<Integer, Id>();
    Map<Integer, SpiritStructureResponse> mapCheckinResp = new Map<Integer, SpiritStructureResponse>();

    //Find acceptor & Identify Store & FC
    System.debug('>>>>> ALK - Usages : ' + Usages);
    for (SpiritStructureRequest u : Usages) {
      if (!mapAuthMIDRequest.containsKey(u.authorizationMID))
        mapAuthMIDRequest.put(u.authorizationMID, new List<SpiritStructureRequest>());
      mapAuthMIDRequest.get(u.authorizationMID).add(u);
      if (String.isNotBlank(u.bu))
        bus.add(u.bu);
    }
    System.debug('>>>>> ALK - mapAuthMIDRequest : ' + mapAuthMIDRequest);

    for (ER_Acceptor__c a : [
      SELECT
        Id,
        Name,
        ER_MID_Authorization__c,
        ER_SubMID_Authorization__c,
        ER_MID_Clearing__c,
        ER_Sub_MID_Clearing__c,
        ER_Start_Date__c,
        ER_End_Date__c,
        ER_Business_Unit__c,
        ER_Store__r.Name,
        ER_Store__r.ER_Financial_Center__c
      FROM ER_Acceptor__c
      WHERE ER_MID_Authorization__c IN :mapAuthMIDRequest.keySet() AND ER_Business_Unit__c IN :bus
    ]) {
      System.debug('>>>>> ALK - a : ' + a);
      Date startDate = (a.ER_Start_Date__c == null ? Date.valueOf('1900-01-01') : a.ER_Start_Date__c);
      Date endDate = (a.ER_End_Date__c == null ? Date.valueOf('2900-01-01') : a.ER_End_Date__c);
      String existSubMIDAuth = (String.isBlank(a.ER_SubMID_Authorization__c) ? null : a.ER_SubMID_Authorization__c);
      String existMIDClear = (String.isBlank(a.ER_MID_Clearing__c) ? null : a.ER_MID_Clearing__c);
      String existSubMIDClear = (String.isBlank(a.ER_Sub_MID_Clearing__c) ? null : a.ER_Sub_MID_Clearing__c);

      for (SpiritStructureRequest r : mapAuthMIDRequest.get(a.ER_MID_Authorization__c)) {
        Date transactionDate = Date.valueOf(r.transactionDate);
        String reqSubMidAuth = (String.isBlank(r.authorizationSubMID) ? null : r.authorizationSubMID);
        String reqMIDClear = (String.isBlank(r.clearingMID) ? null : r.clearingMID);
        String reqSubMIDClear = (String.isBlank(r.clearingSubMID) ? null : r.clearingSubMID);
        String reqBu = (String.isBlank(r.bu) ? null : r.bu); // AAM-11.08.2021: PBI#12525
        System.debug(
          '>>>>> ALK - CheckinId : ' +
          r.checkinId +
          ' : ' +
          (transactionDate >= startDate &&
          transactionDate <= endDate &&
          reqBu == a.ER_Business_Unit__c)
        );
        if (transactionDate >= startDate && transactionDate <= endDate && reqBu == a.ER_Business_Unit__c) {
          // AAM-11.08.2021: PBI#12525, PBI#12531
          mapCheckinAcceptor.put(r.checkinId, a);
          System.debug(
            '>>>>> ALK - : a.ER_MID_Authorization__c ' +
            a.ER_MID_Authorization__c +
            ' - r.authorizationMID : ' +
            r.authorizationMID
          );
          System.debug('>>>>> ALK - : existSubMIDAuth ' + existSubMIDAuth + ' - reqSubMidAuth : ' + reqSubMidAuth);
          System.debug('>>>>> ALK - : existMIDClear ' + existMIDClear + ' - reqMIDClear : ' + reqMIDClear);
          System.debug('>>>>> ALK - : existSubMIDClear ' + existSubMIDClear + ' - reqSubMIDClear : ' + reqSubMIDClear);
          //1 - Search by all fields received
          if (
            a.ER_MID_Authorization__c == r.authorizationMID &&
            existSubMIDAuth == reqSubMidAuth &&
            existMIDClear == reqMIDClear &&
            existSubMIDClear == reqSubMIDClear
          ) {
            System.debug('>>>>> ALK - : rule 1 - CheckinId : ' + r.checkinId);
            if (!mapRule1.containsKey(r.checkinId))
              mapRule1.put(r.checkinId, new List<ER_Acceptor__c>());
            mapRule1.get(r.checkinId).add(a);
          } else if (
            a.ER_MID_Authorization__c == r.authorizationMID &&
            existSubMIDAuth == null &&
            existMIDClear == reqMIDClear &&
            existSubMIDClear == null
          ) {
            //2 - Search by AuthMID - NUll (AuthSubMID) - ClearMid - NUll (ClearSubMID)
            System.debug('>>>>> ALK - : rule 2 - CheckinId : ' + r.checkinId);
            if (!mapRule2.containsKey(r.checkinId))
              mapRule2.put(r.checkinId, new List<ER_Acceptor__c>());
            mapRule2.get(r.checkinId).add(a);
          } else if (
            a.ER_MID_Authorization__c == r.authorizationMID &&
            existSubMIDAuth == reqSubMidAuth &&
            existMIDClear == null &&
            existSubMIDClear == null
          ) {
            //3 - Search by AuthMID - AuthSubMID - NULL (ClearMID) - NULL (ClearSubMID)
            System.debug('>>>>> ALK - : rule 3 - CheckinId : ' + r.checkinId);
            if (!mapRule3.containsKey(r.checkinId))
              mapRule3.put(r.checkinId, new List<ER_Acceptor__c>());
            mapRule3.get(r.checkinId).add(a);
          } else if (a.ER_MID_Authorization__c == r.authorizationMID && existSubMIDAuth == reqSubMidAuth) {
            //4 - Search AuthMID - AuthSubMID Only
            System.debug('>>>>> ALK - : rule 4 - CheckinId : ' + r.checkinId);
            if (!mapRule4.containsKey(r.checkinId))
              mapRule4.put(r.checkinId, new List<ER_Acceptor__c>());
            mapRule4.get(r.checkinId).add(a);
          } else if (a.ER_MID_Authorization__c == r.authorizationMID && existSubMIDAuth == null) {
            //5 - Search by AuthMID - NULL (AuthSubMID) Only
            System.debug('>>>>> ALK - : rule 5 - CheckinId : ' + r.checkinId);
            if (!mapRule5.containsKey(r.checkinId))
              mapRule5.put(r.checkinId, new List<ER_Acceptor__c>());
            mapRule5.get(r.checkinId).add(a);
          }
        }
      }
    }

    System.debug('>>>>> ALK - mapRule1 : ' + mapRule1.size());
    System.debug('>>>>> ALK - mapRule2 : ' + mapRule2.size());
    System.debug('>>>>> ALK - mapRule3 : ' + mapRule3.size());
    System.debug('>>>>> ALK - mapRule4 : ' + mapRule4.size());
    System.debug('>>>>> ALK - mapRule5 : ' + mapRule5.size());

    for (SpiritStructureRequest r : Usages) {
      if (mapRule1.get(r.checkinId)?.size() == 1)
        mapCheckinFC.put(r.checkinId, mapRule1.get(r.checkinId)[0].ER_Store__r.ER_Financial_Center__c);
      else if (mapRule2.get(r.checkinId)?.size() == 1)
        mapCheckinFC.put(r.checkinId, mapRule2.get(r.checkinId)[0].ER_Store__r.ER_Financial_Center__c);
      else if (mapRule3.get(r.checkinId)?.size() == 1)
        mapCheckinFC.put(r.checkinId, mapRule3.get(r.checkinId)[0].ER_Store__r.ER_Financial_Center__c);
      else if (mapRule4.get(r.checkinId)?.size() == 1)
        mapCheckinFC.put(r.checkinId, mapRule4.get(r.checkinId)[0].ER_Store__r.ER_Financial_Center__c);
      else if (mapRule5.get(r.checkinId)?.size() == 1)
        mapCheckinFC.put(r.checkinId, mapRule5.get(r.checkinId)[0].ER_Store__r.ER_Financial_Center__c);
      else
        mapCheckinResp.put(r.checkinId, new SpiritStructureResponse(1, '', '', r.checkinId, ''));
    }
    System.debug('>>>>> ALK - mapCheckinFC : ' + mapCheckinFC);
    System.debug('>>>>> ALK - mapCheckinAcceptor : ' + mapCheckinAcceptor);

    //Get parent subscription for secondary Financial Centers
    Map<Integer, List<Id>> mapCheckInContract = new Map<Integer, List<Id>>();
    Map<Integer, String> mapCheckInChildBAs = new Map<Integer, String>();
    Set<Id> contractsIds = new Set<Id>();
    Map<String, Map<Id, String>> mapBAChildSubs = new Map<String, Map<Id, String>>();
    for (Zuora__CustomerAccount__c ba : [
      SELECT
        Id,
        Zuora__AccountNumber__c,
        ER_Financial_Center__c,
        (SELECT Id, Name, ER_Master__c, ER_Contract__c FROM Zuora__Subscriptions__r)
      FROM Zuora__CustomerAccount__c
      WHERE ER_Financial_Center__c IN :mapCheckinFC.values() AND ER_Master__c = FALSE
    ]) {
      for (Zuora__Subscription__c s : ba.Zuora__Subscriptions__r) {
        for (Integer i : mapCheckinFC.keySet()) {
          if (mapCheckinFC.get(i) == ba.ER_Financial_Center__c && s.ER_Master__c == 'No' && s.ER_Contract__c != null) {
            contractsIds.add(s.ER_Contract__c);
            if (!mapCheckInContract.containsKey(i))
              mapCheckInContract.put(i, new List<Id>());
            mapCheckInContract.get(i).add(s.ER_Contract__c);
            mapCheckInChildBAs.put(i, ba.Zuora__AccountNumber__c);
            if (!mapBAChildSubs.containsKey(ba.Zuora__AccountNumber__c))
              mapBAChildSubs.put(ba.Zuora__AccountNumber__c, new Map<Id, String>());
            mapBAChildSubs.get(ba.Zuora__AccountNumber__c).put(s.ER_Contract__c, s.Name);
          }
        }
      }
    }
    System.debug('>>>>> ALK - mapCheckInContract : ' + mapCheckInContract);

    for (ER_ContractLineItem__c cli : [
      SELECT
        Id,
        ER_Solution__c,
        ER_Contract__r.ContractNumber,
        ER_Contract__r.Subscription__r.Name,
        ER_Contract__r.Subscription__r.Zuora__CustomerAccount__r.ER_Financial_Center__c,
        ER_Contract__r.StartDate,
        ER_Contract__r.EndDate,
        ER_Business_Unit__c,
        ER_Contract__r.Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c
      FROM ER_ContractLineItem__c
      WHERE
        (ER_Contract__r.Subscription__r.Zuora__CustomerAccount__r.ER_Financial_Center__c IN :mapCheckinFC.values()
        OR ER_Contract__c IN :contractsIds)
        AND ER_Contract__r.Status NOT IN ('Draft', 'In Approval Process')
      ORDER BY ER_Contract__r.ContractNumber DESC
    ]) {
      for (SpiritStructureRequest u : Usages) {
        if (
          mapCheckinFC.containsKey(u.checkinId) &&
          (mapCheckinFC.get(u.checkinId) ==
          cli.ER_Contract__r.Subscription__r.Zuora__CustomerAccount__r.ER_Financial_Center__c ||
          (mapCheckInContract.containsKey(u.checkinId) &&
          mapCheckInContract.get(u.checkinId).contains(cli.ER_Contract__c)))
        ) {
          Date transactionDate = Date.valueOf(u.transactionDate);
          Date contractStartDate = (cli.ER_Contract__r.StartDate == null
            ? Date.valueOf('1900-01-01')
            : cli.ER_Contract__r.StartDate);
          Date contractEndDate = (cli.ER_Contract__r.EndDate == null
            ? Date.valueOf('2900-01-01')
            : cli.ER_Contract__r.EndDate);
          System.debug(
            '>>>>> ALK - CheckInId : ' +
            u.checkinId +
            ' - transactionDate = ' +
            transactionDate +
            ' - ContractNumber : ' +
            cli.ER_Contract__r.ContractNumber +
            +' - contractStartDate = ' +
            contractStartDate +
            ' - contractEndDate = ' +
            contractEndDate
          );

          if (
            !mapCheckinResp.containsKey(u.checkinId) ||
            mapCheckinResp.containsKey(u.checkinId) && mapCheckinResp.get(u.checkinId).returnCode != 0
          ) {
            List<String> solutions = cli.ER_Solution__c.split('\\|');

            if (solutions.contains(u.productCode)) {
              if (
                transactionDate >= contractStartDate &&
                transactionDate <= contractEndDate &&
                u.bu == cli.ER_Business_Unit__c
              ) {
                if (mapCheckInContract.containsKey(u.checkinId)) {
                  String subscriptionNAme = mapBAChildSubs.get(mapCheckInChildBAs.get(u.checkinId))
                    .get(cli.ER_Contract__c);
                  mapCheckinResp.put(
                    u.checkinId,
                    new SpiritStructureResponse(
                      0,
                      subscriptionNAme,
                      mapCheckinAcceptor.get(u.checkinId).ER_Store__r.Name,
                      u.checkinId,
                      mapCheckInChildBAs.get(u.checkinId)
                    )
                  );
                } else
                  mapCheckinResp.put(
                    u.checkinId,
                    new SpiritStructureResponse(
                      0,
                      cli.ER_Contract__r.Subscription__r.Name,
                      mapCheckinAcceptor.get(u.checkinId).ER_Store__r.Name,
                      u.checkinId,
                      cli.ER_Contract__r.Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                    )
                  );
              } else
                mapCheckinResp.put(u.checkinId, new SpiritStructureResponse(3, '', '', u.checkinId, ''));
            } else if (
              !mapCheckinResp.containsKey(u.checkinId) ||
              mapCheckinResp.containsKey(u.checkinId) && mapCheckinResp.get(u.checkinId).returnCode != 3
            )
              mapCheckinResp.put(u.checkinId, new SpiritStructureResponse(2, '', '', u.checkinId, ''));
          }
        }
      }
    }
    System.debug('>>>>> ALK - mapCheckinResp : ' + mapCheckinResp);

    for (Integer checkinId : mapCheckinAcceptor.keySet()) {
      if (!mapCheckinResp.containsKey(checkinId))
        mapCheckinResp.put(checkinId, new SpiritStructureResponse(2, '', '', checkinId, ''));
    }

    return mapCheckinResp.values();
  }

  /**
   * Spirit Structure Response
   */
  global class SpiritStructureResponse {
    public Integer returnCode { get; set; }
    public String subscriptionNumber { get; set; }
    public String storeName { get; set; }
    public Integer checkinId { get; set; }
    public String billingAccountNumber { get; set; }

    public SpiritStructureResponse(
      Integer returnCode,
      String subscriptionNumber,
      String storeName,
      Integer checkinId,
      String billingAccountNumber
    ) {
      this.returnCode = returnCode;
      this.subscriptionNumber = subscriptionNumber;
      this.storeName = storeName;
      this.checkinId = checkinId;
      this.billingAccountNumber = billingAccountNumber;
    }
  }

  /**
   * Spirit Structure Request
   */
  global class SpiritStructureRequest {
    public Integer checkinId { get; set; }
    public String productCode { get; set; }
    public String transactionDate { get; set; }
    public String scheme { get; set; }
    public String authorizationMID { get; set; }
    public String authorizationSubMID { get; set; }
    public String authorizationAID { get; set; }
    public String clearingMID { get; set; }
    public String clearingSubMID { get; set; }
    public String clearingAID { get; set; }
    public String bu { get; set; }
  }
}