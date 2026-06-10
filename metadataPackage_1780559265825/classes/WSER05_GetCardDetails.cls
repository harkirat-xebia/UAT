/*
~ Author            : Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date      : 06/10/2018 (dd/mm/yyyy)
~ Description       : In asset Layout, when user click on the button Get CArd,
____________________  a call needs to be done to the service << Card Detail >>.
____________________  This Service is used for anonymous card, after creation we need to call te WS to get the status and the Account linked to the Asset.

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/
public class WSER05_GetCardDetails {
  public static CardDetailResponse getCardDetail(string productCode, String assetName) {
    CardDetailResponse cardDetail;

    string cardDetailURL = '/cards/' + assetName + '-' + productCode;
    system.debug('##### getCardDetailURL: ' + cardDetailURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        cardDetail = (CardDetailResponse) JSON.deserialize(
          VFCER01_Asset_Transactions_Balance_Test.cardDetailMock,
          WSER05_GetCardDetails.CardDetailResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(cardDetailURL, 'GET', '', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        system.debug('##### getCardDetails response: ' + res);
        system.debug('##### getCardDetails responseBody: ' + res.getbody());

        cardDetail = (CardDetailResponse) JSON.deserialize(
          responseBody,
          WSER05_GetCardDetails.CardDetailResponse.class
        );
        System.debug('#### WSER05_GetCardDetails.getCardDetail cardDetail: ' + cardDetail);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### getCardDetails CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### getCardDetail Exception : ' + e.getMessage());
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return cardDetail;
  }

  /*=========================================================
DESERIALIZE AND EXCEPTION CLASS
============================================================*/

  //description Custom error handling class
  class CustomException extends Exception {
  }

  // class to deserialize card operations response (JSON)
  public class CardDetailResponse {
    public Meta meta;
    public CardDetail data { get; set; }
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
  public class CardDetail {
    public String issue_date;
    public String pan;
    public String expiration_date;
    public String acceptance_profile;
    public String employer_ref;
    public String employer_name;
    public String cardholder_name;
    public String status;
    public String order_ref;
  }
}