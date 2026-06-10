/*
~ Author			: Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date		: 01/10/2018 (dd/mm/yyyy)
~ Description		: In asset Layout, when user click on the button Block Card,
____________________  a call needs to be done to the service << Block card >>.

VERSION HISTORY
~ Modified By		:  (@.com)
~ Modified Date		: // (dd/mm/yyyy)
~ Description		:
*/
public class WSER03_BlockCardDetails {
  public static CardBlockResponse blockCard(string productCode, String assetName, String blockReason) {
    CardBlockResponse blockCard;

    string cardBlockURL = '/cards/' + assetName + '-' + productCode + '/actions/block';
    system.debug('##### cardBlockURL: ' + cardBlockURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        blockCard = (CardBlockResponse) JSON.deserialize(
          VFCER03_Asset_BlockCard_Test.blockCardMock,
          WSER03_BlockCardDetails.CardBlockResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(
          cardBlockURL,
          'POST',
          '{"reason":"' +
          blockReason +
          '"}',
          null
        );

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        system.debug('##### responseBody: ' + responseBody);
        blockCard = (CardBlockResponse) JSON.deserialize(responseBody, WSER03_BlockCardDetails.CardBlockResponse.class);
        system.debug('##### blockCard: ' + blockCard);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### blockCard CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### blockCard Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return blockCard;
  }

  // class to deserialize card balances response (JSON)
  public class CardBlockResponse {
    public Meta meta;
    public List<CardBlock> data { get; set; }
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
  public class CardBlock {
  }
  //description Custom error handling class
  class CustomException extends Exception {
  }
}