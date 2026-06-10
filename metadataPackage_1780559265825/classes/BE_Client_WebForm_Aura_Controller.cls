/**
 * Creator : Snehil Verma
 * Date : 2024/10/10
 * Controller for Webform Client
 */
public class BE_Client_WebForm_Aura_Controller {

    //Added for PBI-626 by Killian Degryse
    @AuraEnabled
    public static Boolean isCurrentUserOrgProduction(){
        return BE_Util.isCurrentUserOrgProduction();
    }

    @AuraEnabled
    public static Map<String, String> getPickListValues(String objectApiName, String fieldApiName, Boolean required, String language){
        return BE_WebForm_Controller_Helper.getPicklistValues(objectApiName, fieldApiName, required, language);
    }

    @AuraEnabled
    public static Map<String, String> getSettingsAttributes(){
        Map<String, String> result = new Map<String, String>();

        for(Webform_Client_Settings__mdt wcs : [SELECT MasterLabel, Value__c FROM Webform_Client_Settings__mdt]){
            result.put(wcs.MasterLabel, String.valueOf(wcs.Value__c));
        }

        return result;
    }

    @AuraEnabled
    public static Boolean isValidEnterpriseNumber(Integer enterpriseNumber){
        return BE_Util.checkEnterpriseNumber(enterpriseNumber);
    }

    @AuraEnabled
    public static ProductDetailsWrapper getCompleteProductName(String product) {
        // Fetch metadata record
        List<BE_Product_Name_Mapping__mdt> pnm = [
            SELECT Full_Name__c 
            FROM BE_Product_Name_Mapping__mdt 
            WHERE Name__c = :product
        ];
        
        // Fetch Product2 record
        Product2 productDetails = BE_Client_WebForm_Without_Sharing_Ctrl.fetchProductDetails(product);

        if (pnm.isEmpty() || productDetails == null) {
            throw new AuraHandledException('Error_Message_Server_Error'); // Bad parameter in URL
        }
        
        // Construct and return the wrapper
        return new ProductDetailsWrapper(
            pnm[0].Full_Name__c,
            productDetails.Load_Per_Year__c,
            Integer.valueOf(productDetails.Days_Per_Month__c)
        );
    }


    //Added for PBI-697 : Offer light
    @AuraEnabled
    public static Map<String, Object> findOpportunity(String key, String product){
        return BE_Client_WebForm_Without_Sharing_Ctrl.findOpportunity(key, product);
    }


    @AuraEnabled
    public static Map<String, List<Map<String, String>>> getOpportunityProduct(Id opportunityId, String language, String key){
  		if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
  			return BE_Client_WebForm_Without_Sharing_Ctrl.getOpportunityProduct(opportunityId, language);
  		else
  			return null;
    }

    @AuraEnabled
    public static Map<String, List<Map<String, String>>> getBillableServices(String promoCode, String product, String language){
        return BE_Client_WebForm_Without_Sharing_Ctrl.getBillableServices(promoCode, product, language);
    }

    @AuraEnabled
    public static Map<String, String> getInfosFromBelfirstCtrl(String enterpriseNumber, String language, Boolean offerLight, String product){
        return BE_Client_WebForm_Without_Sharing_Ctrl.getInfosFromBelfirstCtrl(enterpriseNumber, language, offerLight, product);
    }

    @AuraEnabled
    public static Lead saveP1(Decimal numberOfBeneficiaries, Decimal faceValue, String typeOfPosition, String email, String product, String sourceId, String pageLanguage){
        return BE_Client_Webform_Without_Sharing_Ctrl.saveP1(numberOfBeneficiaries, faceValue, typeOfPosition, email, product, sourceId, pageLanguage);
    }

    @AuraEnabled
    public static Lead updateP1(Decimal numberOfBeneficiaries, Decimal faceValue, String typeOfPosition, String email, String product, Lead lead){
        return BE_Client_Webform_Without_Sharing_Ctrl.updateP1(numberOfBeneficiaries, faceValue, typeOfPosition, email, product, lead);
    }

    @AuraEnabled 
    public static Map<String, Object> leadConversionP2(String vatNumber, Boolean subjectToVat, String phone, String name, String legalForm,
                                                       String enterpriseNumber, String billingAddress, String billingPostalCode,
                                                       String billingCity, String billingCountry, String product, Lead lead,
                                                       Decimal faceValue, Decimal numberOfBeneficiaries, String legalName, String sourceId, String pageLanguage){
        return BE_Client_Webform_Without_Sharing_Ctrl.leadConversionP2(vatNumber, subjectToVat, phone, name, legalForm,
                                                       				enterpriseNumber, billingAddress, billingPostalCode,
                                                       				billingCity, billingCountry, product, lead,
                                                       				faceValue, numberOfBeneficiaries, legalName, sourceId, pageLanguage);
    }
    
    @AuraEnabled
    public static Map<String, Object> updateP2Account(String vatNumber, Boolean subjectToVat, String phone, String enterpriseNumber, 
                                                      String billingAddress, String billingPostalCode,
                                                      String billingCity, String billingCountry, String product,
                                                      Account account, String legalName, String name, String legalForm,
                                                      ER_Financial_Center__c financialCenter, String key, Id opportunityId){
		//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			return BE_Client_WebForm_Without_Sharing_Ctrl.updateP2Account(vatNumber, subjectToVat, phone, enterpriseNumber, 
                                                      					  billingAddress, billingPostalCode,
                                                      					  billingCity, billingCountry, product,
                                                      					  account, legalName, name, legalForm,
                                                      					  financialCenter);
		/*else
			return BE_Client_WebForm_With_Sharing_Ctrl.updateP2Account(vatNumber, subjectToVat, phone, enterpriseNumber, 
                                                      				   billingAddress, billingPostalCode,
                                                      				   billingCity, billingCountry, product,
                                                      				   account, legalName, name, legalForm,
                                                      				   financialCenter);*/
    }
    
    @AuraEnabled
    public static Map<String, Object> saveP3(Decimal numberOfEmployees, Boolean socialSecretary, String socialSecretaryName,
                                             Boolean socialSecretaryInChargeOfOrders, String shippingAddress, 
                                             String shippingNumber, String shippingPostalCode, String shippingCity, 
                                             String shippingCountry, Account account, ER_Financial_Center__c financialCenter,
                                             Id invoicingContactId, Id deliveryContactId, String key, Id opportunityId){
		//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			return BE_Client_WebForm_Without_Sharing_Ctrl.saveP3(numberOfEmployees, socialSecretary, socialSecretaryName,
                                             					 socialSecretaryInChargeOfOrders, shippingAddress, 
                                             					 shippingNumber, shippingPostalCode, shippingCity, 
                                             					 shippingCountry, account, financialCenter,
                                             					 invoicingContactId, deliveryContactId, opportunityId);
		/*else
			return BE_Client_WebForm_With_Sharing_Ctrl.saveP3(numberOfEmployees, socialSecretary, socialSecretaryName,
                                             				  socialSecretaryInChargeOfOrders, shippingAddress, 
                                             				  shippingNumber, shippingPostalCode, shippingCity, 
                                             				  shippingCountry, account, financialCenter,
                                             				  invoicingContactId, deliveryContactId);*/
    }
    
    @AuraEnabled
    public static Map<String, Object> updateP3(Boolean socialSecretary, String socialSecretaryName,
                                               Boolean socialSecretaryInChargeOfOrders, String shippingAddress, 
                                               String shippingNumber, String shippingPostalCode, String shippingCity, 
                                               String shippingCountry, Account account, ER_Financial_Center__c financialCenter,
                                               ER_Delivery_Site__c deliverySite, ER_Distribution_Point__c distributionPoint,
                                               Id invoicingContactId, Id deliveryContactId, String key, Id opportunityId){
		//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			return BE_Client_WebForm_Without_Sharing_Ctrl.updateP3(socialSecretary, socialSecretaryName,
                                               					   socialSecretaryInChargeOfOrders, shippingAddress, 
                                               					   shippingNumber, shippingPostalCode, shippingCity, 
                                               					   shippingCountry, account, financialCenter,
                                               					   deliverySite, distributionPoint,
                                               					   invoicingContactId, deliveryContactId, opportunityId);
		/*else
			return BE_Client_WebForm_With_Sharing_Ctrl.updateP3(socialSecretary, socialSecretaryName,
                                               					socialSecretaryInChargeOfOrders, shippingAddress, 
                                               					shippingNumber, shippingPostalCode, shippingCity, 
                                               					shippingCountry, account, financialCenter,
                                               					deliverySite, distributionPoint,
                                               					invoicingContactId, deliveryContactId);*/
    }
    
    @AuraEnabled
    public static void createBillableServices(Id priceBookId, Decimal faceValue, Decimal rateZone, Decimal numberOfEmployees,
                                              Decimal numberOfBeneficiaries, Decimal minRate, Decimal maxRate, 
                                              Decimal minDelivery, Decimal maxDelivery, Boolean isByUnit, Boolean offerLight,
                                              Id promoCodeId, Opportunity opportunity, Account account, Id generalConditionId,
                                              String key, Id opportunityId, String productCode, String promoCode, Integer loadPerYear, Integer daysPerYear){
		//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			BE_Client_WebForm_Without_Sharing_Ctrl.createBillableServices(priceBookId, faceValue, rateZone, numberOfEmployees,
                                      									  numberOfBeneficiaries, minRate, maxRate, 
                                      									  minDelivery, maxDelivery, isByUnit, offerLight,
                                      									  promoCodeId, opportunity, account, generalConditionId, productCode, promoCode, loadPerYear, daysPerYear);
		/*else
			BE_Client_WebForm_With_Sharing_Ctrl.createBillableServices(priceBookId, faceValue, rateZone, numberOfEmployees,
                          								   			   numberOfBeneficiaries, minRate, maxRate, 
                          								   			   minDelivery, maxDelivery, isByUnit,
                          								   			   promoCodeId, opportunity, account, generalConditionId);*/
    }

    //PBI-667 : Maintenance page
    @AuraEnabled
    public static Boolean isOnMaintenance(){
        return BE_Util.isOnMaintenance('Customer');
    }

    //Contact form :
    @AuraEnabled
    public static Contact addContact(String accId, String salutation, String firstName, String lastName,
    								 String lang, String phone, String mobilePhone, String funct, String email,
    								 String key, Id opportunityId){
    	//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			return BE_Client_WebForm_Without_Sharing_Ctrl.addContact(accId, salutation, firstName, lastName,
							 								  		 lang, phone, mobilePhone, funct, email);
		/*else
			return BE_Client_WebForm_With_Sharing_Ctrl.addContact(accId, salutation, firstName, lastName,
							 							   		  lang, phone, mobilePhone, funct, email);*/
    }

    @AuraEnabled
    public static Contact adjustOperationalRoleContact(String respId1, String respId2, String respId3, String respId4,
    												   String sourceId, String key, Id opportunityId){
    	//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			return BE_Client_WebForm_Without_Sharing_Ctrl.adjustOperationalRoleContact(respId1, respId2, respId3, respId4, sourceId);
		/*else
			return BE_Client_WebForm_With_Sharing_Ctrl.adjustOperationalRoleContact(respId1, respId2, respId3, respId4, sourceId);*/
    }

    @AuraEnabled
    public static void removeContact(String contId, String key, Id opportunityId){
    	//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			BE_Client_WebForm_Without_Sharing_Ctrl.removeContact(contId);
		/*else
			BE_Client_WebForm_With_Sharing_Ctrl.removeContact(contId);*/
    }

    @AuraEnabled
    public static Contact updateInfosContact(String contId, String salutation, String firstName, String lastName,
    										 String lang, String phone, String mobilePhone, String funct, String email,
    										 String key, Id opportunityId){
    	//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			return BE_Client_WebForm_Without_Sharing_Ctrl.updateInfosContact(contId, salutation, firstName, lastName,
										 							  		 lang, phone, mobilePhone, funct, email);
		/*else
			return BE_Client_WebForm_With_Sharing_Ctrl.updateInfosContact(contId, salutation, firstName, lastName,
										 					   			  lang, phone, mobilePhone, funct, email);*/
    }

    @AuraEnabled
    public static List<Contact> getContacts(Id accountId, String key, Id opportunityId){
    	//if(BE_Client_WebForm_Without_Sharing_Ctrl.isOfferLight(key, opportunityId))
			return BE_Client_WebForm_Without_Sharing_Ctrl.getContacts(accountId);
		/*else
			return BE_Client_WebForm_With_Sharing_Ctrl.getContacts(accountId);*/
    }

    @AuraEnabled
    public static void populateContactsOnOpportunity(String opportunityId, String primaryContactId, String invoicingContactId){
		BE_Client_WebForm_Without_Sharing_Ctrl.populateContactsOnOpportunity(opportunityId, primaryContactId, invoicingContactId);
    }

    public class ProductDetailsWrapper {
        @AuraEnabled
        public String fullName;
        @AuraEnabled
        public Decimal loadPerYear;
        @AuraEnabled
        public Integer daysPerMonth;

        public ProductDetailsWrapper(String fullName, Decimal loadPerYear, Integer daysPerMonth) {
            this.fullName = fullName;
            this.loadPerYear = loadPerYear;
            this.daysPerMonth = daysPerMonth;
        }
    }
    
}