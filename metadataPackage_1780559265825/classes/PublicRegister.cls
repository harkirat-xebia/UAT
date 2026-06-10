/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : PublicRegister factory to choose the BU implementation
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--18/12/2022    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class PublicRegister implements PublicRegisterInterface {
  private final Map<String, System.Type> BU_SERVICES = new Map<String, System.Type>{
    'FR' => PublicRegister_FR.class,
    'FI' => PublicRegister_FI.class,
    'GR' => PublicRegister_GR.class
  };

  public String BU;

  /**
   * @author Noor
   * @description instantiate class with the BU
   * @param BU
   */
  public PublicRegister(String BU) {
    this.BU = BU;
  }

  /**
   * @description Connect to the webservice by using the namedCredential
   * @param searchStr
   *
   * @return the json result
   */
  public String getWebserviceResponse(String searchStr) {
    PublicRegisterInterface publicRegister = (PublicRegisterInterface) BU_SERVICES.get(BU).newInstance();

    return publicRegister.getWebserviceResponse(searchStr);
  }

  /**
   * @description map the json result into the common wrapper
   * @param json
   *
   * @return the wrapper with the values of the webservice needed
   */
  public Map<String, String> mapResponse(String json) {
    PublicRegisterInterface publicRegister = (PublicRegisterInterface) BU_SERVICES.get(BU).newInstance();
    return publicRegister.mapResponse(json);
  }

  /**
   * @description Get list of fields to display on screen for lead of account
   * @param type object type Account or Lead
   *
   * @return
   */
  public Map<String, String> getFieldsToDisplay(String type) {
    PublicRegisterInterface publicRegister = (PublicRegisterInterface) BU_SERVICES.get(BU).newInstance();
    return publicRegister.getFieldsToDisplay(type);
  }

  /**
   * @description Add any validation error before calling the webservice
   * @param sObj sobject
   */
  public void addError(SObject sObj) {
    PublicRegisterInterface publicRegister = (PublicRegisterInterface) BU_SERVICES.get(BU).newInstance();
    publicRegister.addError(sObj);
  }
}