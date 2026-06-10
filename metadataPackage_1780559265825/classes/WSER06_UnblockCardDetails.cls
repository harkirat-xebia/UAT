public class WSER06_UnblockCardDetails {
  public static CardUnblockResponse UnblockCard(string productCode, String assetName) {
    CardUnblockResponse UnblockCard;

    string cardUnblockURL = '/cards/' + assetName + '-' + productCode + '/actions/unblock';
    system.debug('##### cardUnblockURL: ' + cardUnblockURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        UnblockCard = (CardUnblockResponse) JSON.deserialize(
          VFCER06_Asset_UnblockCard_Test.unblockCardMock,
          WSER06_UnblockCardDetails.CardUnblockResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(cardUnblockURL, 'POST', '{}', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        system.debug('##### responseBody: ' + responseBody);
        UnblockCard = (CardUnblockResponse) JSON.deserialize(
          responseBody,
          WSER06_UnblockCardDetails.CardUnblockResponse.class
        );
        system.debug('##### UnblockCard: ' + UnblockCard);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### UnblockCard CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### UnblockCard Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return UnblockCard;
  }

  // class to deserialize card balances response (JSON)
  public class CardUnblockResponse {
    public Meta meta;
    public CardUnblock data { get; set; }
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
  public class CardUnblock {
    public String status;
  }
  //description Custom error handling class
  class CustomException extends Exception {
  }
}