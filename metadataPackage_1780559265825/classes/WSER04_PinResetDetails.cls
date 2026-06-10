/*
~ Author            : Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date      : 01/10/2018 (dd/mm/yyyy)
~ Description       : In asset Layout, when user click on the button Pin Reset,
____________________  a call needs to be done to the service << Pin Reset >>.

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/
public class WSER04_PinResetDetails {
  public static CardPinResetResponse requestPinReset(string productCode, String assetName) {
    CardPinResetResponse cardPin;

    string cardPinResetURL = '/cards/' + assetName + '-' + productCode + '/actions/request-pin-reset';
    system.debug('##### getCardBalanceURL: ' + cardPinResetURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        cardPin = (CardPinResetResponse) JSON.deserialize(
          VFCER02_Asset_PinReset_Test.pinResetMock,
          WSER04_PinResetDetails.CardPinResetResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(cardPinResetURL, 'POST', '{}', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        system.debug('##### responseBody: ' + responseBody);
        cardPin = (CardPinResetResponse) JSON.deserialize(
          responseBody,
          WSER04_PinResetDetails.CardPinResetResponse.class
        );
        system.debug('##### cardPin: ' + cardPin);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### requestPinReset CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### requestPinReset Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return cardPin;
  }

  // class to deserialize card balances response (JSON)
  public class CardPinResetResponse {
    public Meta meta;
    public List<PinCode> data { get; set; }
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
  public class PinCode {
    public String reset_code { get; set; }
  }
  //description Custom error handling class
  class CustomException extends Exception {
  }
}