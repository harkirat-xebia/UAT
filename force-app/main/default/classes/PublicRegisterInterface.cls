/**
 * Created by noorgoolamnabee on 16/12/2022.
 */

public interface PublicRegisterInterface {
  /**
   * @description connect to Webservice and get data via search str
   * @param searchStr
   *
   * @return Json
   */
  String getWebserviceResponse(String searchStr);

  /**
   * @description Map json data to PublicRegisterWrapper to be used for Lead or Account
   * @param json
   *
   * @return
   */
  Map<String, String> mapResponse(String json);

  /**
   * @description Get list of fields to display on screen for lead of account
   * @param type object type Account or Lead
   *
   * @return
   */
  Map<String, String> getFieldsToDisplay(String type);

  /**
   * @description Add any validation error before calling the webservice
   * @param sObj sobject
   */
  void addError(SObject sObj);
}