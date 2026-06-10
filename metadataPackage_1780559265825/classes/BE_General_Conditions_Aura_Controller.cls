public class BE_General_Conditions_Aura_Controller {

    private static Integer MAX_SIZE = 255;//max size for text field

    @AuraEnabled
    public static BE_General_Condition__c getGeneralCondition(String language, String product, Id opportunityId,
    														  String stakeholderType){
        	return BE_General_Conditions_With_Sharing_Ctrl.getGeneralCondition(language, product, opportunityId, stakeholdertype);
    }

    @AuraEnabled
    public static String submitAgreedToGeneralConditions(Boolean agreedToGeneralConditions, Boolean prepaymentAccepted,
                                                       Id opportunityId, Id accountId, String stakeholderType,
                                                       String productName, String emailAddress, String formLanguage,
                                                       String key){
        //if(BE_General_Cond_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
        	return BE_General_Cond_Without_Sharing_Ctrl.submitAgreedToGeneralConditions(agreedToGeneralConditions, prepaymentAccepted,
                                                       									opportunityId, accountId, stakeholderType,
                                                       									productName, emailAddress, formLanguage);
        /*else
        	return BE_General_Conditions_With_Sharing_Ctrl.submitAgreedToGeneralConditions(agreedToGeneralConditions, prepaymentAccepted,
                                                       									   opportunityId, accountId, stakeholderType,
                                                       									   productName, emailAddress, formLanguage);*/
	}
    
    @AuraEnabled
    public static String createQuote(String opportunityId){
        return BE_General_Cond_Without_Sharing_Ctrl.createQuote(opportunityId);
	}
    
    @AuraEnabled
    public static void createContract(String quoteId){
        BE_General_Cond_Without_Sharing_Ctrl.createContract(quoteId);
	}
}