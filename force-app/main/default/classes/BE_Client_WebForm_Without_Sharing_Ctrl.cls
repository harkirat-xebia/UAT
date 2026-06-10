/**
 * Creator : Snehil Verma
 * Date : 2024/10/10
 */
public without sharing class BE_Client_WebForm_Without_Sharing_Ctrl {

  public static Boolean isOfferLight(String key, Id opportunityId){
      return BE_Webform_Controller_Helper.isOfferLight(key, opportunityId);
  }

  public static Map<String, Object> findOpportunity(String key, String product){
      return BE_Client_WebForm_Controller.findOpportunity(key, product);
  }

  public static Map<String, List<Map<String, String>>> getOpportunityProduct(Id opportunityId, String language){
  return BE_Client_WebForm_Controller.getOpportunityProduct(opportunityId, language);
  }

  public static Map<String, List<Map<String, String>>> getBillableServices(String promoCode, String product, String language){
      return BE_Client_Webform_Controller.getBillableServices(promoCode, product, language);
  }

/*    public static Map<String, String> getInfosFromBelfirstCtrl(String enterpriseNumber, String language, String product){
  return BE_Client_Webform_Controller.getInfosFromBelfirstCtrl(enterpriseNumber, language, true, product);
  }*/

  public static Map<String, String> getInfosFromBelfirstCtrl(String enterpriseNumber, String language, Boolean offerLight, String product){
      return BE_Client_Webform_Controller.getInfosFromBelfirstCtrl(enterpriseNumber, language, offerLight, product);
  }
  
  public static Lead saveP1(Decimal numberOfBeneficiaries, Decimal faceValue, String typeOfPosition, String email, String product, String sourceId, String pageLanguage){
      return BE_Client_Webform_Controller.saveP1(numberOfBeneficiaries, faceValue, typeOfPosition, email, product, sourceId, pageLanguage);
  }

  public static Lead updateP1(Decimal numberOfBeneficiaries, Decimal faceValue, String typeOfPosition, String email, String product, Lead lead){
      return BE_Client_Webform_Controller.updateP1(numberOfBeneficiaries, faceValue, typeOfPosition, email, product, lead);
  }
  
  public static Map<String, Object> leadConversionP2(String vatNumber, Boolean subjectToVat, String phone, String name, String legalForm,
                                                     String enterpriseNumber, String billingAddress, String billingPostalCode,
                                                     String billingCity, String billingCountry, String product, Lead lead,
                                                     Decimal faceValue, Decimal numberOfBeneficiaries, String legalName, String sourceId, String pageLanguage){
      return BE_Client_Webform_Controller.leadConversionP2(vatNumber, subjectToVat, phone, name, legalForm,
                                                     enterpriseNumber, billingAddress, billingPostalCode,
                                                     billingCity, billingCountry, product, lead,
                                                     faceValue, numberOfBeneficiaries, legalName, sourceId, pageLanguage);
  }

  public static Map<String, Object> updateP2Account(String vatNumber, Boolean subjectToVat, String phone, String enterpriseNumber, 
                                                    String billingAddress, String billingPostalCode,
                                                    String billingCity, String billingCountry, String product,
                                                    Account account, String legalName, String name, String legalForm,
                                                    ER_Financial_Center__c financialCenter){
  return BE_Client_Webform_Controller.updateP2Account(vatNumber, subjectToVat, phone, enterpriseNumber, 
                                                billingAddress, billingPostalCode,
                                                billingCity, billingCountry, product,
                                                account, legalName, name, legalForm,
                                                financialCenter);
  }

  public static Map<String, Object> saveP3(Decimal numberOfEmployees, Boolean socialSecretary, String socialSecretaryName,
                                           Boolean socialSecretaryInChargeOfOrders, String shippingAddress, 
                                           String shippingNumber, String shippingPostalCode, String shippingCity, 
                                           String shippingCountry, Account account, ER_Financial_Center__c financialCenter,
                                           Id invoicingContactId, Id deliveryContactId, Id opportunityId){
  return BE_Client_Webform_Controller.saveP3(numberOfEmployees, socialSecretary, socialSecretaryName,
                                        socialSecretaryInChargeOfOrders, shippingAddress, 
                                        shippingNumber, shippingPostalCode, shippingCity, 
                                        shippingCountry, account, financialCenter,
                                        invoicingContactId, deliveryContactId, opportunityId);
  }

  public static Map<String, Object> updateP3(Boolean socialSecretary, String socialSecretaryName,
                                             Boolean socialSecretaryInChargeOfOrders, String shippingAddress, 
                                             String shippingNumber, String shippingPostalCode, String shippingCity, 
                                             String shippingCountry, Account account, ER_Financial_Center__c financialCenter,
                                             ER_Delivery_Site__c deliverySite, ER_Distribution_Point__c distributionPoint,
                                             Id invoicingContactId, Id deliveryContactId, Id opportunityId){
  return BE_Client_Webform_Controller.updateP3(socialSecretary, socialSecretaryName,
                                           socialSecretaryInChargeOfOrders, shippingAddress, 
                                           shippingNumber, shippingPostalCode, shippingCity, 
                                           shippingCountry, account, financialCenter,
                                           deliverySite, distributionPoint,
                                           invoicingContactId, deliveryContactId, opportunityId);
  }

  public static void createBillableServices(Id priceBookId, Decimal faceValue, Decimal rateZone, Decimal numberOfEmployees,
                                            Decimal numberOfBeneficiaries, Decimal minRate, Decimal maxRate, 
                                            Decimal minDelivery, Decimal maxDelivery, Boolean isByUnit, Boolean offerLight,
                                            Id promoCodeId, Opportunity opportunity, Account account, Id generalConditionId, String productCode, String promoCode, Integer loadPerYear, Integer daysPerYear){
  BE_Client_Webform_Controller.createBillableServices(priceBookId, faceValue, rateZone, numberOfEmployees,
                                          numberOfBeneficiaries, minRate, maxRate, 
                                          minDelivery, maxDelivery, isByUnit, offerLight,
                                          promoCodeId, opportunity, account, generalConditionId, productCode, promoCode, loadPerYear, daysPerYear);
  }

  //Contact form :
  public static Contact addContact(String accId, String salutation, String firstName, String lastName,
                   String lang, String phone, String mobilePhone, String funct, String email){
  return BE_Client_Webform_Controller.addContact(accId, salutation, firstName, lastName,
                            lang, phone, mobilePhone, funct, email);
  }

  public static Contact adjustOperationalRoleContact(String respId1, String respId2, String respId3, String respId4,
                             String sourceId){
  return BE_Client_Webform_Controller.adjustOperationalRoleContact(respId1, respId2, respId3, respId4, sourceId);
  }
  
  public static void removeContact(String contId){
  BE_Client_Webform_Controller.removeContact(contId);
  }
  
  public static Contact updateInfosContact(String contId, String salutation, String firstName, String lastName,
                       String lang, String phone, String mobilePhone, String funct, String email){
  return BE_Client_Webform_Controller.updateInfosContact(contId, salutation, firstName, lastName,
                                  lang, phone, mobilePhone, funct, email);
  }
  
  public static List<Contact> getContacts(Id accountId){
  return BE_Client_Webform_Controller.getContacts(accountId);
  }

  public static void populateContactsOnOpportunity(String opportunityId, String primaryContactId, String invoicingContactId){
    BE_Client_Webform_Controller.populateContactsOnOpportunity(opportunityId, primaryContactId, invoicingContactId);
  }

  public static Product2 fetchProductDetails(String productCode){
    return [Select Load_Per_Year__c, Days_per_Month__c FROM Product2 WHERE ProductCode =: productCode LIMIT 1];
  }
}