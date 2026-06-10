/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : Wrapper class used to store field characteristic to be displayed
   @see           : PublicRegister
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--18/12/2022    Noor                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class PublicRegisterWrapper {
  @AuraEnabled
  public String fieldLabel;

  @AuraEnabled
  public String fieldValue;

  @AuraEnabled
  public String fieldData;

  @AuraEnabled
  public Boolean readOnly;

  @AuraEnabled
  public String fieldDataChk;

  public PublicRegisterWrapper(String fieldLabel, String fieldValue, String fieldData, String property) {
    this.fieldLabel = fieldLabel;
    this.fieldValue = fieldValue;
    this.fieldData = fieldData;
    this.fieldDataChk = 'chk_' + fieldData;
    this.readOnly = property != null && property.equals('readonly');
  }
}