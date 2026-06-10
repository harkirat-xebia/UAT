/*
~ Author			: Nicolae CIAUSU (nicolae.ciausu@edenred.com)
~ Created Date      : 01/04/2020 (dd/mm/yyyy)
~ Description		: In asset Layout, when user click on the button Get Loads,
____________________  a call needs to be done to the service << get loads >> which will fill in the details
____________________  on VFER13_Asset_GetLoads.

VERSION HISTORY
~ Modified By		:  (@.com)
~ Modified Date		: // (dd/mm/yyyy)
~ Description		:
*/
public class WSER10_GetLoads {
  /*******************************************************************************************************
   * @description Get the card loads.
   * @param assetName : The Asset number
   * @return the card operations informations
   */

  public static CardLoadsResponse getCardLoads(string productCode, String assetName, String parameters) {
    CardLoadsResponse cardLoad;

    string cardLoadURL = '/cards/' + assetName + '-' + productCode + '/balances' + parameters;
    system.debug('##### cardLoadURL: ' + cardLoadURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        String responseBody = VFCER10_Asset_GetLoads_Test.loadsMock;
        responseBody = responseBody.replace('currency', 'ccurrency');
        cardLoad = (CardLoadsResponse) JSON.deserialize(responseBody, WSER10_GetLoads.CardLoadsResponse.class);
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(cardLoadURL, 'GET', '', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        system.debug('##### getCardLoads response: ' + res);
        system.debug('##### getCardLoads responseBody: ' + responseBody);

        // We need to replace the currency key word by ccurency because the word is reserved in Apex and we can't use it in the class wrapper.
        responseBody = responseBody.replace('currency', 'ccurrency');
        cardLoad = (CardLoadsResponse) JSON.deserialize(responseBody, WSER10_GetLoads.CardLoadsResponse.class);
        System.debug('#### WSER10_GetLoads.CardLoadsResponse.class cardLoad: ' + cardLoad);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### getCardLoads CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### getCardLoads Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return cardLoad;
  }
  /*=========================================================
	DESERIALIZE AND EXCEPTION CLASS
	============================================================*/

  //description Custom error handling class
  class CustomException extends Exception {
  }

  // class to deserialize card operations response (JSON)
  public class CardLoadsResponse {
    public Meta meta;
    public List<CardLoad> data { get; set; }
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
  public class CardLoad {
    public String product_code { get; set; }
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