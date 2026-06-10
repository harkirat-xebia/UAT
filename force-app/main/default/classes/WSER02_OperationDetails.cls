/*
~ Author			: Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date		: 01/10/2018 (dd/mm/yyyy)
~ Description		: In asset Layout, when user click on the button Get Transactions,
____________________  a call needs to be done to the service << get card operations >> which will fill in the details
____________________  on VFER01_Asset_Transacations_Balance.

VERSION HISTORY
~ Modified By		:  (@.com)
~ Modified Date		: // (dd/mm/yyyy)
~ Description		:
*/
public class WSER02_OperationDetails {
  /*******************************************************************************************************
   * @description Get the card operations.
   * @param assetName : The Asset number
   * @return the card operations informations
   */

  public static CardOperationResponse getCardOperations(string productCode, String assetName, String parameters) {
    CardOperationResponse cardOperation;

    string cardOperationURL = '/cards/' + assetName + '-' + productCode + '/operations' + parameters;
    system.debug('##### getCardOperationURL: ' + cardOperationURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        cardOperation = (CardOperationResponse) JSON.deserialize(
          VFCER01_Asset_Transactions_Balance_Test.operationsMock,
          WSER02_OperationDetails.CardOperationResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(cardOperationURL, 'GET', '', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        system.debug('##### getCardOperations response: ' + res);
        system.debug('##### getCardOperations responseBody: ' + res.getbody());

        // We need to replace the currency key word by ccurency because the word is reserved in Apex and we can't use it in the class wrapper.
        responseBody = responseBody.replace('currency', 'ccurrency').replace('date', 'opDate');
        cardOperation = (CardOperationResponse) JSON.deserialize(
          responseBody,
          WSER02_OperationDetails.CardOperationResponse.class
        );
        System.debug('#### WSER02_OperationDetails.WSER02_OperationDetails cardOperation: ' + cardOperation);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### getCardOperations CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### getCardOperations Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return cardOperation;
  }
  /*=========================================================
	DESERIALIZE AND EXCEPTION CLASS
	============================================================*/

  //description Custom error handling class
  class CustomException extends Exception {
  }

  // class to deserialize card operations response (JSON)
  public class CardOperationResponse {
    public Meta meta;
    public List<CardOperation> data { get; set; }
  }
  public class Meta {
    public String status;
    public List<Message> messages;
    public List<Message> message;
  }
  public class Message {
    public String code;
    public String level;
    public String text;
    public String message;
  }
  public class CardOperation {
    //public String operation_ref {get; set;}
    public String csn { get; set; }
    public String type { get; set; }
    public String status_details { get; set; }
    public String status { get; set; }
    public String cleared_status { get; set; }
    public String product_code { get; set; } // currency Name is reserved in Apex so we need to replace in the JSON currency by ccurrency.
    public String amount { get; set; }
    //public String ccurrency {get; set;}
    public String outlet_name { get; set; }
    public String MID_auth { get; set; }
    public String opDate { get; set; }
    public String wallet_service_provider { get; set; }
    public String device_name { get; set; }
    public String device_type { get; set; }
    public string reason { get; set; }
    public string cleared_opDate { get; set; }
    public string acceptance_method { get; set; }
    public Boolean offline { get; set; }
    public String product_balance_code { get; set; }
    public String auth_sub_mid { get; set; }
    public String clear_sub_mid { get; set; }
  }
}