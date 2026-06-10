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
public class WSER09_UpdateIndividual {
  /*******************************************************************************************************
   * @description: Send and update Email Address.
   * @param username : username of the Account
   * @param body : body of the request
   * @return response from server after updating the email address
   */

  public static updateIndividualResponse updateIndividual(String username, String body) {
    updateIndividualResponse updatePersonAccountResponse;

    //string updateEmailURL = '/beneficiaries/' + username;
    string updateEmailURL = '/users/' + username; //not sure if I have to add V2
    system.debug('##### updateEmailURL: ' + updateEmailURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        updatePersonAccountResponse = (updateIndividualResponse) JSON.deserialize(
          VFCER09_Account_UpdateEmailAddress_Test.updateEmailMock,
          WSER09_UpdateIndividual.updateIndividualResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(updateEmailURL, 'PUT', body, null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        System.debug('#### responseBody: ' + responseBody);
        updatePersonAccountResponse = (updateIndividualResponse) JSON.deserialize(
          responseBody,
          WSER09_UpdateIndividual.updateIndividualResponse.class
        );
        System.debug(
          '#### WSER09_UpdateIndividual.updateIndividualResponse updatePersonAccountResponse: ' +
          updatePersonAccountResponse
        );
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### updateIndividual CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### updateIndividual Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return updatePersonAccountResponse;
  }

  public static CardBalanceResponse GetIndividual(String username, String body) {
    CardBalanceResponse getIndiv;

    string updateEmailURL = '/users/' + username;
    system.debug('##### updateEmailURL: ' + updateEmailURL);

    try {
      if (!Test.isRunningTest() && APER06_WebserviceUtility.Offline_Service_WS) {
        //throw new CustomException('OFFLINE BU');
        //MOCK ?
        getIndiv = (CardBalanceResponse) JSON.deserialize(
          VFCER09_Account_UpdateEmailAddress_Test.updateEmailMock,
          WSER09_UpdateIndividual.CardBalanceResponse.class
        );
      } else {
        //declare the http request to perform the REST call
        Http h = new Http();
        HttpRequest req = APER06_WebserviceUtility.getHttpRequest(updateEmailURL, 'GET', null, null);

        HttpResponse res = h.send(req);
        String responseBody = res.getbody();
        System.debug('#### responseBody: ' + responseBody);
        getIndiv = (CardBalanceResponse) JSON.deserialize(
          responseBody,
          WSER09_UpdateIndividual.CardBalanceResponse.class
        );
        System.debug('#### WSER09_UpdateIndividual.updateIndividualResponse updatePersonAccountResponse: ' + getIndiv);
      }
    } catch (APER06_WebserviceUtility.CustomException e) {
      system.debug('##### updateIndividual CustomException Exception : ' + e);
      throw new CustomException(e.getmessage());
    } catch (Exception e) {
      system.debug('##### updateIndividual Exception : ' + e);
      throw new CustomException(Label.LABS_SF_WS_GenericError1);
    }

    return getIndiv;
  }

  /*=========================================================
	DESERIALIZE AND EXCEPTION CLASS
	============================================================*/

  //description Custom error handling class
  class CustomException extends Exception {
  }

  // class to deserialize card balances response (JSON)
  public class updateIndividualResponse {
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

  public class CardBalanceResponse {
    public Meta meta;
    public PersonalDetails data;
  }

  public class PersonalDetails {
    public Individual personal_info;
    public String username;
  }

  public class Individual {
    //public String Email {get; set;}
    //public String Phone {get; set;}
    //public String Address {get; set;}
    //public String PostalCode {get; set;}
    //public String City {get; set;}
    public String username;
    public String last_name;
    public String first_name;
    public String email;
    public String phone_number;
    public location address;
  }

  public class location {
    public String street;
    public String zip_code;
    public String city;
  }
}