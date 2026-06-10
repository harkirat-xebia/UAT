/*
~ Author            : Nicolae CIAUSU
~ Created Date      : 30/12/2019 (dd/mm/yyyy)
~ Description       : Get the security Question linked to the beneficiary.

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/
public class WSER07_GetSecurityQuestion {
  /*******************************************************************************************************
   * @description Get security question and answer.
   * @param OSId :
   * @return the security question and answer
   */

  public static SecurityQuestionResponse getSecurityQuestion(String OSId) {
    SecurityQuestionResponse securityQuestion;

    string securityQuestionURL = '/users/' + OSId + '/security-question?with-answer=true';
    system.debug('##### securityQuestionURL: ' + securityQuestionURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        securityQuestion = (SecurityQuestionResponse) JSON.deserialize(
          VFCER07_Asset_MobileActivation_Test.secretQAMock,
          WSER07_GetSecurityQuestion.SecurityQuestionResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(securityQuestionURL, 'GET', '', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        System.debug('#### responseBody: ' + responseBody);
        securityQuestion = (SecurityQuestionResponse) JSON.deserialize(
          responseBody,
          WSER07_GetSecurityQuestion.SecurityQuestionResponse.class
        );
        System.debug(
          '#### WSER01_MobileActivationDetails.SecurityQuestionResponse securityQuestion: ' + securityQuestion
        );
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### getSecurityQuestion CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### getSecurityQuestion Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return securityQuestion;
  }

  /*=========================================================
                    DESERIALIZE AND EXCEPTION CLASS
    ============================================================*/

  //description Custom error handling class
  class CustomException extends Exception {
  }

  // class to deserialize card balances response (JSON)
  public class SecurityQuestionResponse {
    public Meta meta;
    public SecurityQuestion data { get; set; }
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
  public class SecurityQuestion {
    public String secret_question { get; set; }
    public String secret_answer { get; set; }
  }
}