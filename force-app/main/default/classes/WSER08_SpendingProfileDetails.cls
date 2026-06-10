public class WSER08_SpendingProfileDetails {
  /*
~ Author			: Nicolae CIAUSU
~ Created Date		: 30/12/2019 (dd/mm/yyyy)
~ Description		: In asset Layout, when user click on the button Get Spending Profile,
____________________  a call needs to be done to the service << get spending profile >> which will fill in the details
____________________  on VFER08_Asset_SpendingProfile.

VERSION HISTORY
~ Modified By		:  (@.com)
~ Modified Date		: // (dd/mm/yyyy)
~ Description		:
*/
  public static SpendingProfileResponse getSpendingProfile(String username) {
    SpendingProfileResponse securityQuestion;

    string securityQuestionURL = '/TBD/' + username + '/spending-profile';
    system.debug('##### securityQuestionURL: ' + securityQuestionURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        securityQuestion = (SpendingProfileResponse) JSON.deserialize(
          VFCER08_Asset_SpendingProfile_Test.spendingProfileMock,
          WSER08_SpendingProfileDetails.SpendingProfileResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(securityQuestionURL, 'GET', '', null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        System.debug('#### responseBody: ' + responseBody);
        securityQuestion = (SpendingProfileResponse) JSON.deserialize(
          responseBody,
          WSER08_SpendingProfileDetails.SpendingProfileResponse.class
        );
        System.debug(
          '#### WSER08_SpendingProfileDetails.SpendingProfileResponse securityQuestion: ' + securityQuestion
        );
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### getSpendingProfile CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### getSpendingProfile Exception : ' + e);
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
  public class SpendingProfileResponse {
    public Meta meta;
    public List<SpendingProfile> data { get; set; }
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
  public class SpendingProfile {
    public String transactionValueLimit { get; set; }
    public String transactionCountLimit { get; set; }
    public List<SpendingCategoryRule> spendingCategoryRules { get; set; }
    public List<TimeRule> timeRulesLimits { get; set; }
  }

  public class SpendingCategoryRule {
    public String balance { get; set; }
    public String decision { get; set; }
    public String category { get; set; }
  }

  public class TimeRule {
    public String day { get; set; }
    public String decision { get; set; }
    public String slotSpendLimit { get; set; }
    public String startTime { get; set; }
    public String endTime { get; set; }
  }
}