/*
----------------------------------------------------------------------
-- - Name          : WSHU05_SynchronizeContractWS
-- - Author        : OLA
-- - Description   : Synchronize Contract
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  FEB-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class WSHU05_SynchronizeContractWS {
  public static WSHU04_ContractTemplateWS.ContractResponse callContractWS(
    Contract contractInst,
    Map<String, List<ER_ContractLineItem__c>> contractLineItemMap,
    Boolean isUpdate
  ) {
    String endPoint;
    String method;
    WSHU04_ContractTemplateWS.ContractResponse myResponse;
    WSHU04_ContractTemplateWS.sContract theContract = new WSHU04_ContractTemplateWS.sContract(
      contractInst,
      contractLineItemMap,
      isUpdate
    );
    String body = JSON.serializePretty(theContract, true);
    System.debug('body : ' + body);

    /*  if(isUpdate){

            method='PUT';
            endPoint = '/merchants/ds.merchant.technical_id-' + contractInst.accountId + '/contracts/ds.contractmerchant.technical_id-'+ contractInst.Id;
        }
        else{*/ //KHAD !

    method = 'POST';
    endPoint = '/merchants/ds.merchant.technical_id-' + contractInst.accountId + '/contracts';
    /*}*/
    System.debug('endPoint : ' + endPoint);
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);
    // get the HmacToken to be send
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(endPoint, afterblobToStringbis, currentDate);
    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequest(
      endPoint,
      method,
      hmacToken,
      currentDate,
      afterblobToStringbis
    );
    Http h = new Http();
    HttpResponse res = h.send(req);

    System.debug('Response JSON : ' + res.getBody().replaceAll('\\s+', ''));

    if (res != null) {
      try {
        if (res.getStatusCode() != null && String.valueOf(res.getStatusCode()).startswith('2')) {
          myResponse = (WSHU04_ContractTemplateWS.ContractResponse) JSON.deserialize(
            res.getBody(),
            WSHU04_ContractTemplateWS.ContractResponse.class
          );
          System.debug('### myResponse : ' + myResponse);
        } else {
          throw new CustomException(res.getStatus());
        }
      } catch (Exception e) {
        System.debug('### WSHU05_SynchronizeContractWS Exception : ' + e.getMessage());
        throw new CustomException(e.getMessage());
      }
    } else {
      System.debug('### WSHU05_SynchronizeContractWS Empty response Body.');
      throw new CustomException(Label.LABS_SF_WS_Unavailable);
    }

    return myResponse;
  }

  public static WSHU04_ContractTemplateWS.ContractResponse callCloseContractWS(
    Contract contractInst,
    Map<String, List<ER_ContractLineItem__c>> contractLineItemMap
  ) {
    String endPoint;
    String method;
    WSHU04_ContractTemplateWS.ContractResponse myResponse;
    system.debug('IN KHAD 1');
    WSHU04_ContractTemplateWS.product_contracts ContractProductGone = new WSHU04_ContractTemplateWS.product_contracts(
      contractLineItemMap
    );
    system.debug('IN KHAD 2');
    String body = JSON.serializePretty(ContractProductGone, true);
    System.debug('body : ' + body);
    method = 'POST';
    endPoint =
      '/merchants/ds.merchant.technical_id-' +
      contractInst.accountId +
      '/contracts/ds.contract.technical_id-' +
      contractInst.id +
      '/actions/close';
    System.debug('endPoint : ' + endPoint);
    String currentDate = String.valueOf(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));
    String afterblobToStringbis = APHU06_CryptoTokenGeneration.getEncodedbody(body);
    system.debug('IN KHAD 3');
    // get the HmacToken to be send
    String hmacToken = APHU06_CryptoTokenGeneration.getHmacToken(endPoint, afterblobToStringbis, currentDate);
    HttpRequest req = APHU06_CryptoTokenGeneration.getHttpRequest(
      endPoint,
      method,
      hmacToken,
      currentDate,
      afterblobToStringbis
    );
    Http h = new Http();
    HttpResponse res = h.send(req);

    System.debug('Response JSON close : ' + res.getBody().replaceAll('\\s+', ''));

    if (res != null) {
      try {
        if (res.getStatusCode() != null && String.valueOf(res.getStatusCode()).startswith('2')) {
          myResponse = (WSHU04_ContractTemplateWS.ContractResponse) JSON.deserialize(
            res.getBody(),
            WSHU04_ContractTemplateWS.ContractResponse.class
          );
          System.debug('### myResponse close : ' + myResponse);
        } else {
          throw new CustomException(res.getStatus());
        }
      } catch (Exception e) {
        System.debug('### WSHU05_SynchronizeContractWS close Exception : ' + e.getMessage());
        throw new CustomException(e.getMessage());
      }
    } else {
      System.debug('### WSHU05_SynchronizeContractWS close Empty response Body.');
      throw new CustomException(Label.LABS_SF_WS_Unavailable);
    }

    return myResponse;
  }

  //description Custom error handling class
  class CustomException extends Exception {
  }
}