/*
~ Author			: Nicolae CIAUSU
~ Created Date		: 30/12/2019 (dd/mm/yyyy)
~ Description		: In PersonAccount - Individual Layout, when user click on the button Update Email Address,
____________________  a call needs to be done to the service << update email address >> with the email address filled in
____________________  on VFER09_Account_UpdateEmailAddress and update the email address with the entered value.

VERSION HISTORY
~ Modified By		:  (@.com)
~ Modified Date		: // (dd/mm/yyyy)
~ Description		:
*/
public class WSER09_UpdateEmailAddress {
  /*******************************************************************************************************
   * @description: Send and update Email Address.
   * @param OSId : OSId of the Account
   * @param body : body of the request
   * @return response from server after updating the email address
   */

  public static UpdateEmailAddressResponse updateEmailAddress(String OSId, String body) {
    UpdateEmailAddressResponse updateEmailResponse;

    string updateEmailURL = '/users/' + OSId;
    system.debug('##### updateEmailURL: ' + updateEmailURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        updateEmailResponse = (UpdateEmailAddressResponse) JSON.deserialize(
          VFCER09_Account_UpdateEmailAddress_Test.updateEmailMock,
          WSER09_UpdateEmailAddress.UpdateEmailAddressResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(updateEmailURL, 'PUT', body, null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        System.debug('#### responseBody: ' + responseBody);
        updateEmailResponse = (UpdateEmailAddressResponse) JSON.deserialize(
          responseBody,
          WSER09_UpdateEmailAddress.UpdateEmailAddressResponse.class
        );
        System.debug(
          '#### WSER09_UpdateEmailAddress.UpdateEmailAddressResponse updateEmailResponse: ' + updateEmailResponse
        );
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### updateEmailAddress CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### updateEmailAddress Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return updateEmailResponse;
  }

  /*=========================================================
	DESERIALIZE AND EXCEPTION CLASS
	============================================================*/

  //description Custom error handling class
  class CustomException extends Exception {
  }

  // class to deserialize card balances response (JSON)
  public class UpdateEmailAddressResponse {
    public Meta meta;
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
}