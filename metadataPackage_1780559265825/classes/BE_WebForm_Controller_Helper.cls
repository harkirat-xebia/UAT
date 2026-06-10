/**
*Creator : Snehil Verma
*Date : 2014/11/09
*Helper for the controllers of the webform
*/
public inherited sharing class BE_WebForm_Controller_Helper {

	public static Map<String, String> getPickListValues(String objectApiName, String fieldApiName, Boolean required, String language){
        Map<String, String> picklistTranslations = new Map<String, String>();
        for(BE_Picklist_Value_Translation__mdt pvt : [SELECT Label, BE_Label_Translation__c
                                                      FROM BE_Picklist_Value_Translation__mdt 
                                                      WHERE BE_Language__c = :language]){
            picklistTranslations.put(pvt.Label, pvt.BE_Label_Translation__c);
        }
        Map<String, String> pickListValues = new Map<String, String>();
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        String value, valueTranslated;
        if(!required)
            pickListValues.put('', '');
        for(Schema.PicklistEntry pickListVal : ple){
            if(pickListVal.isActive()){
                value = pickListVal.getValue();
                if(value != Label.No_Secretary_Social_NOT_TRANSLATED){
                    valueTranslated = picklistTranslations.get(value);
                    if(valueTranslated != null)
                        pickListValues.put(value, valueTranslated);
                    else
                        pickListValues.put(value, value);
                }
            }
        }

        return pickListValues;
    }

    public static Map<String, String> getInfosFromBelfirstCtrl(String bvdId, String idType, String language){
        Map<String, String> result = new Map<String, String>();
        WSBE01_Belfirst bw = new WSBE01_Belfirst();
        try{
            result = bw.getInfos(bvdId, idType, language);
            bw.closeConnection();
        }catch(Exception ex){
            bw.closeConnection();
            throw new AuraHandledException(ex.getMessage());
        }
        return result;
    }

    public static String getCorrectCity(String country, String zipCode, String city){
        List<BE_Technical_Address__mdt> techAddresses = [SELECT Id FROM BE_Technical_Address__mdt
                                                       WHERE BE_Country__c = :country
                                                       AND BE_Zip_Code__c = :zipCode
                                                       AND BE_City__c = :city];
        if(techAddresses.size() == 0 && (country == 'BELGIUM' || country == 'LUXEMBOURG')){
            techAddresses = [SELECT BE_City__c FROM BE_Technical_Address__mdt
                             WHERE BE_Country__c = :country
                             AND BE_Zip_Code__c = :zipCode
                             AND BE_Is_Default__c = true];
            if(techAddresses.size() == 0)
                throw new AuraHandledException('Error_Message_Bad_ZipCode');
            else
                return techAddresses[0].BE_City__c;
        }
        else
            return city;
    }

    private static String extractErrorMessage(String errorMessage){
        String error;
        if(errorMessage.contains('INVALID_EMAIL_ADDRESS'))
            error = 'Bad email address';
        else if(errorMessage.contains('Error ID') || errorMessage.contains('ID de l\'erreur') 
                || errorMessage.contains('Fout-ID'))
            error = 'Server not responding';        //To Fix
        else if(errorMessage.contains('DUPLICATE_VALUE'))
            error = 'Duplicate acceptor';
        else if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            error = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1].split(':')[0].removeStart(' ');
        }
        else
            error = 'Unknown error';
            
        return error;
    }

    /**
    *@Return the name of the custom label linked to the error sent in the parameter.
    *If none label are found, the method send the generic label "Unknown Error"
    */
    public static String getErrorMessageLabel(String errorMessage){
        String error = extractErrorMessage(errorMessage);

        List<BE_Error_Message_Translation__mdt> result = [SELECT BE_Custom_Label__c 
                                                          FROM BE_Error_Message_Translation__mdt
                                                          WHERE BE_Error__c = :error];
        if(result.size() == 0)
            return 'Error_Message_Unknown_Error';
        else
            return result[0].BE_Custom_Label__c;
    }

    public static Boolean isOfferLight(String key, Id opportunityId){
        if(opportunityId != null && [SELECT BE_Webform_Link__c FROM Opportunity WHERE Id = :opportunityId].BE_Webform_Link__c != null)
            return !String.isBlank(key.trim()) && [SELECT BE_Webform_Link__c FROM Opportunity WHERE Id = :opportunityId].BE_Webform_Link__c.contains(key);
        else
            return false;
    }
}