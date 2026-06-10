/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : PublicRegisterController used by LWC
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--18/12/2022    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class PublicRegisterController {
  @AuraEnabled(Cacheable=true)
  public static List<PublicRegisterWrapper> getData(String accountId) {
    String type = getSObjectType(accountId);
    SObject sObj;
    String Registration_Number;
    String BU;

    if (type == Constants.ACCOUNT) {
      Account ac = [
        SELECT Id, ER_BUPicklist__c, ER_Registration_Number__c, ER_Legal_Status__c
        FROM Account
        WHERE Id = :accountId
      ];
      Registration_Number = ac.ER_Registration_Number__c;
      BU = ac.ER_BUPicklist__c;
      sObj = ac;
    } else {
      Lead l = [
        SELECT Id, ER_BUPicklist__c, ER_Registration_Number__c, ER_Legal_Status__c
        FROM Lead
        WHERE Id = :accountId
      ];
      Registration_Number = l.ER_Registration_Number__c;
      BU = l.ER_BUPicklist__c;
      sObj = l;
    }

    if (String.isBlank(Registration_Number))
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoRegistrationNumberFound);

    //Instantiate Public Register for corresponding BU
    PublicRegister register = new PublicRegister(BU);
    register.addError(sObj);
    String json = register.getWebserviceResponse(Registration_Number);
    Map<String, String> wsValues = register.mapResponse(json);
    Map<String, String> fields = register.getFieldsToDisplay(type);
    List<PublicRegisterWrapper> wrappers = new List<PublicRegisterWrapper>();
    Map<String, Schema.SObjectField> fieldMapLabel = getFieldMapLabel(type);

    for (String field : fields.keySet())
      wrappers.add(
        new PublicRegisterWrapper(
          fieldMapLabel.get(field).getDescribe().getLabel(),
          wsValues.get(field),
          field,
          fields.get(field)
        )
      );

    return wrappers;
  }

  private static String getSObjectType(Id str) {
    return Utils.getSObjectType(str);
  }

  public static Map<String, Schema.SObjectField> getFieldMapLabel(String type) {
    Schema.SObjectType accountSchema = Schema.getGlobalDescribe().get(type);
    return accountSchema.getDescribe().fields.getMap();
  }
}