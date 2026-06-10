@isTest
public class APCZ04_AresByIdControllerTest {
  @isTest
  static void testGetDarvBasWS() {
    //DarvBas
    Test.setMock(HttpCalloutMock.class, new APCZ03_AresCallout_ById_Test.APCZ02_Ares_CalloutResBas_Mock());
    string sJson = APCZ04_AresByIdController.getDarvBasWS('24745391');
    System.debug('JsonDarvBas=' + sJson);
  }

  @isTest
  static void testGetDarvResWS() {
    //DarvRes
    Test.setMock(HttpCalloutMock.class, new APCZ03_AresCallout_ById_Test.APCZ03_Ares_CalloutDarvRes_Mock());
    string sJson = APCZ04_AresByIdController.getDarvResWS('24745391', '');
    //System.debug('JsonDarvRes=' + sJson);
  }

  // @isTest
  // static void testGetFinStatWS() {

  //     WSSK01_GetFinstat.Finstat response = APCZ04_AresByIdController.getFinStatWS('24745391');
  // }

  // @isTest
  // static void testGetBelfirstWS() {

  //     Test.setMock(HttpCalloutMock.class, new APCZ03_AresCallout_ById_Test.APCZ03_Ares_CalloutDarvRes_Mock());
  //     WSBE01_Belfirst.Belfirst response = APCZ04_AresByIdController.getBelfirstWS('24745391');
  // }

  @isTest
  static void testGetAccountWS() {
    Account acc = new Account();
    acc.Name = 'AKO Test';
    acc.ER_Registration_Number__c = 'A79346839';
    acc.ER_VAT_Number__c = '24745391';
    insert acc;

    Account accSel = APCZ04_AresByIdController.getAccountWS(acc.Id);
    //System.debug('AccountSelect=' + accSel.AKO__VAT__c);
  }

  @isTest
  static void testUpdateAccountWS() {
    Account acc = new Account();
    acc.Name = 'AKO Test';
    acc.ER_Registration_Number__c = 'A79346839';
    acc.ER_VAT_Number__c = '24745391';
    //acc.AKO__VAT__c = '24745391';
    insert acc;

    //String jsonAcc = '{"accId" : "' + acc.Id + '","sName" : "Edenred CZ s.r.o.","sBillingStreet" : "Pernerova 691/42","sBillingPostalCode" : "18600","sBillingCity" : "Praha","bGetName" : true,"bGetVatNumber" : true,"bGetLegalForm" : true,"bGetZipCode" : true,"bGetStreet" : true,"bGetCity" : true}';
    String jsonAcc =
      '{"oId" : "' +
      acc.Id +
      '","sName" : "Edenred CZ s.r.o.","sVatNumber" : "CZ24745391","sStreet" : "Pernerova 691/42","sPostalCode" : "18600","sCity" : "Praha","sCountry" : "Czech Republic","bGetName" : true,"bGetVatNumber" : true,"bGetLegalForm" : true,"bGetZipCode" : true,"bGetStreet" : true,"bGetCity" : true,"bGetOtherFiscalId" : true,"bGetCountry" : true,"sNaceList" : ""}';
    String sJsonNace = '[{"n04_Nazev":"Ostatní pomocné činnosti související s finančním zprostředkováním","n04_NACE":"66190","isSelected":false},{"n04_Nazev":"Výroba, obchod a služby neuvedené v přílohách 1 až 3 živnostenského zákona","n04_NACE":"00","isSelected":false},{"n04_Nazev":"Účetnické a auditorské činnosti; daňové poradenství","n04_NACE":"69200","isSelected":false},{"n04_Nazev":"Ostatní profesní, vědecké a technické činnosti","n04_NACE":"74","isSelected":false}]';
    Account accNew = APCZ04_AresByIdController.updateAccountWS(jsonAcc, sJsonNace);

    APCZ01_AresEntity.AresPopUp oPopUp = (APCZ01_AresEntity.AresPopUp) JSON.deserialize(
      jsonAcc,
      APCZ01_AresEntity.AresPopUp.class
    );
    //System.debug('accNew=' + accNew.Name);
  }

  @isTest
  static void testUpdateLeadWS() {
    Lead LeadTest = new Lead(
      LastName = 'TestLead',
      Status = 'New',
      Company = 'Edenred',
      ER_Registration_Number__c = '24745391',
      ER_VAT_Number__c = '24745391',
      ER_Store_Name__c = 'StoreName'
    );

    insert LeadTest;
    APCZ04_AresByIdController.getLeadWS(LeadTest.id);
    APCZ04_AresByIdController.fetchUser();
    String sJsonLead =
      '{"oId" : "' +
      LeadTest.Id +
      '","sName" : "Edenred CZ s.r.o.","sVatNumber" : "CZ24745391","sStreet" : "Pernerova 691/42","sPostalCode" : "18600","sCity" : "Praha","sCountry" : "Czech Republic","bGetName" : true,"bGetVatNumber" : true,"bGetLegalForm" : true,"bGetZipCode" : true,"bGetStreet" : true,"bGetCity" : true,"bGetCountry" : true,"bGetOtherFiscalId" : true,"sNaceList" : ""}';

    String sJsonNaceLead = '[{"n04_Nazev":"Ostatní pomocné činnosti související s finančním zprostředkováním","n04_NACE":"66190","isSelected":false},{"n04_Nazev":"Výroba, obchod a služby neuvedené v přílohách 1 až 3 živnostenského zákona","n04_NACE":"00","isSelected":false},{"n04_Nazev":"Účetnické a auditorské činnosti; daňové poradenství","n04_NACE":"69200","isSelected":false},{"n04_Nazev":"Ostatní profesní, vědecké a technické činnosti","n04_NACE":"74","isSelected":false}]';
    Lead NewLead = APCZ04_AresByIdController.updateLeadWS(sJsonLead, sJsonNaceLead);
    APCZ01_AresEntity.AresPopUp oAccPopUp = (APCZ01_AresEntity.AresPopUp) JSON.deserialize(
      sJsonLead,
      APCZ01_AresEntity.AresPopUp.class
    );
    //System.debug('NewLead=' + NewLead.Name);
  }

  //Stefania

  @isTest
  static void testGetSpecificFields() {
    String fields = APCZ04_AresByIdController.getSpecificFields('BENELUX', 'ER_Merchant_Lead_RT');
    system.debug('fields => ' + fields);
    System.assertEquals(fields, '');
  }

  @isTest
  static void testGetName() {
    Lead lead = new Lead();

    lead.LastName = 'NoTestSelligent';
    lead.ER_Enterprise_Number__c = '0436650646';
    lead.ER_Store_Name__c = 'storeName';
    lead.ER_VAT_Number__c = 'GB773831408';
    lead.ER_Registration_Number__c = 'A79346839';

    insert lead;

    Account acc = new Account();
    acc.Name = 'AKO Test';
    acc.ER_Registration_Number__c = 'A79346839';
    acc.ER_VAT_Number__c = '24745391';
    insert acc;

    String accId = [SELECT id FROM Account].id;
    String leadId = [SELECT id FROM Lead].id;

    APCZ04_AresByIdController.getName(accId);
    APCZ04_AresByIdController.getName(leadId);
    APCZ04_AresByIdController.getERESPublicRegister(accId);
    APCZ04_AresByIdController.getERESPublicRegister(leadId);
  }

  @isTest
  static void testGetTableInfo() {
    Test.setMock(HttpCalloutMock.class, new APCZ03_AresCallout_ById_Test.APCZ03_Ares_CalloutDarvRes_Mock());
    string sJson = APCZ04_AresByIdController.getTableInfo();
  }

  @isTest
  static void testUpdateCreditScoring() {
    Lead lead = new Lead();

    lead.LastName = 'NoTestSelligent';
    lead.ER_Enterprise_Number__c = '0436650646';
    lead.ER_Store_Name__c = 'storeName';
    lead.ER_VAT_Number__c = 'GB773831408';
    lead.ER_Registration_Number__c = 'A79346839';
    lead.Company = 'Company';
    lead.ER_Legal_City__c = 'ER_Legal_City__c';
    lead.ER_Legal_Country__c = 'ER_Legal_Country__c';
    lead.Phone = '0494844';
    lead.Email = 'e@e.com';
    lead.NumberOfEmployees = 1;
    lead.ER_NaceList__c = 'ER_NaceList__c';

    insert lead;

    Account acc = new Account();
    acc.Name = 'AKO Test';
    acc.ER_Registration_Number__c = 'A79346839';
    acc.ER_VAT_Number__c = '24745391';
    acc.ER_Legal_Name__c = 'legal';
    acc.Phone = '0847437484';
    acc.ER_Email__c = 'e@e.com';
    acc.NumberOfEmployees = 1;
    acc.ER_NaceList__c = 'ER_NaceList__c';
    insert acc;

    String accId = [SELECT id FROM Account].id;
    String leadId = [SELECT id FROM Lead].id;

    Contact cont = new Contact();
    cont.AccountId = accId;
    cont.FirstName = 'firstNAme';
    cont.Email = 'a@a.com';
    cont.LastName = 'lastName';
    cont.ER_Legal_City__c = 'ER_Legal_City__c';
    cont.ER_Legal_Country__c = 'ER_Legal_Country__c';
    cont.ER_Language__c = 'FR';

    insert cont;

    Map<String, String> fieldsToUpdate = new Map<String, String>();
    fieldsToUpdate.put('legalForm', 'legalForm');
    fieldsToUpdate.put('street', 'street');
    fieldsToUpdate.put('zipCode', '111111');
    fieldsToUpdate.put('scoring', '3');
    fieldsToUpdate.put('limit', '2');
    fieldsToUpdate.put('legalName', 'legalName');
    fieldsToUpdate.put('city', 'city');
    fieldsToUpdate.put('country', 'country');
    fieldsToUpdate.put('phone', '111111');
    fieldsToUpdate.put('email', 'mllantad@elcorteingles.es');
    fieldsToUpdate.put('nbEmployees', '109');
    system.debug('fields =? ' + fieldsToUpdate);

    Map<String, String> fieldsToUpdate2 = new Map<String, String>();
    fieldsToUpdate2.put('legalForm', 'legalForm');
    fieldsToUpdate2.put('street', 'street');
    fieldsToUpdate2.put('zipCode', '111111');
    fieldsToUpdate2.put('scoring', '3');
    fieldsToUpdate2.put('limit', '');
    fieldsToUpdate.put('legalName', 'legalName');
    fieldsToUpdate.put('city', 'city');
    fieldsToUpdate.put('country', 'country');
    fieldsToUpdate.put('phone', '111111');
    fieldsToUpdate.put('email', 'mllantad@elcorteingles.es');
    fieldsToUpdate.put('nbEmployees', '109');

    APCZ04_AresByIdController.updateCreditScoring(fieldsToUpdate, leadId);
    APCZ04_AresByIdController.updateCreditScoring(fieldsToUpdate, accId);
    APCZ04_AresByIdController.updateCreditScoring(fieldsToUpdate2, leadId);
    APCZ04_AresByIdController.updateCreditScoring(fieldsToUpdate2, accId);

    APCZ04_AresByIdController.updatePublicRegister(fieldsToUpdate, leadId);
    APCZ04_AresByIdController.updatePublicRegister(fieldsToUpdate, accId);
    APCZ04_AresByIdController.updatePublicRegister(fieldsToUpdate2, leadId);
    APCZ04_AresByIdController.updatePublicRegister(fieldsToUpdate2, accId);
  }

  //Stefania
}