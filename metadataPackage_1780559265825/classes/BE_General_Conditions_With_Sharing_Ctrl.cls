public with sharing class BE_General_Conditions_With_Sharing_Ctrl {  

    public static BE_General_Condition__c getGeneralCondition(String language, String product, Id opportunityId,
    														  String stakeholderType){
    	return BE_General_Conditions_Controller.getGeneralCondition(language, product, opportunityId, stakeholdertype);
    }
}