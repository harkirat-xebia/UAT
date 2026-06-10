/*
~ Author			: Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date		: 01/10/2018 (dd/mm/yyyy)
~ Description		: In asset Layout, when user click on the button Get balance,
____________________  a call needs to be done to the service << get card balances >> which will fill in the details
____________________  on VFER01_Asset_Transacations_Balance.

VERSION HISTORY
~ Modified By		:  (@.com)
~ Modified Date		: // (dd/mm/yyyy)
~ Description		:
*/
public class WSER01_BalanceDetails {
  /*******************************************************************************************************
   * @description Get the card balance.
   * @param assetName : The Asset number
   * @param productCode : The Product code
   * @return the card balance informations
   */

  public static CardBalanceResponse getCardBalances(string productCode, String assetName) {
    CardBalanceResponse cardBalance;

    string cardBalanceURL = '/cards/' + assetName + '-' + productCode + '/balances';
    system.debug('##### getCardBalanceURL: ' + cardBalanceURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        cardBalance = (CardBalanceResponse) JSON.deserialize(
          VFCER01_Asset_Transactions_Balance_Test.balanceMock,
          WSER01_BalanceDetails.CardBalanceResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(cardBalanceURL, 'GET', '', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        System.debug('#### responseBody: ' + responseBody);
        // We need to replace the currency key word by ccurency because the word is reserved in Apex and we can't use it in the class wrapper.
        responseBody = responseBody.replace('currency', 'ccurrency');
        cardBalance = (CardBalanceResponse) JSON.deserialize(
          responseBody,
          WSER01_BalanceDetails.CardBalanceResponse.class
        );
        System.debug('#### WSER01_BalanceDetails.WSER01_BalanceDetails cardBalance: ' + cardBalance);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### getCardBalances CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### getCardBalances Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return cardBalance;
  }
  /*=========================================================
	DESERIALIZE AND EXCEPTION CLASS
	============================================================*/

  //description Custom error handling class
  class CustomException extends Exception {
  }

  // class to deserialize card balances response (JSON)
  public class CardBalanceResponse {
    public Meta meta;
    public List<CardBalance> data { get; set; }
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
  public class CardBalance {
    public String product_code { get; set; }
    public String remaining_amount { get; set; }
    public String cleared_amount { get; set; }
    public String reserved_amount { get; set; }
    public String name { get; set; }
    //public String ccurrency {get; set;} // currency Name is reserved in Apex so we need to replace in the JSON currency by ccurrency.
    public String status { get; set; }
    public List<Load> loads { get; set; }
  }
  public class Load {
    public String load_ref { get; set; }
    public String loaded_amount { get; set; }
    public String remaining_amount { get; set; }
    public String cleared_amount { get; set; }
    public String start_date { get; set; }
    public String clearing_expiration_date { get; set; }
    public String authorization_expiration_date { get; set; }
    public String ccurrency { get; set; } // currency Name is reserved in Apex so we need to replace in the JSON currency by ccurrency.
    public String creation_date { get; set; }
    public String status { get; set; }
  }
}