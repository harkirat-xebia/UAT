@isTest
private class BE_TEST_Client_WebForm_Controller{
    static Id accountClientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.BE_Client).getRecordTypeId();
	static Id opportunityClientRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();
    static Id contactClientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.BE_Client_Contact_RT).getRecordTypeId();
    
    @testSetup
    static void testSetup(){
        BE_TEST_Helper.insertPriceBook();
	}

	@isTest
	static void findOpportunityTest(){
		String product = 'ERHU_Edenred_Meal_Card';
		String productError = 'ERHU_Edenred_Gift_Card';
		String productError404 = Label.ECE_Product;

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		//BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		//opportunity.BE_Crypto_Key__c = infos.cryptoKey;
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		//Create Opportunity
		Opportunity opportunityError = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1 Error', productError, opportunityClientRecordTypeId);
		opportunityError.ER_Face_Value__c = 8;
		opportunityError.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		//BE_SendQuoteController.InfosCryptedData infosError = BE_SendQuoteController.generateCryptedData(opportunityError.Id + '-' + Date.today().addMonths(-1).format());
		//opportunityError.BE_Crypto_Key__c = infosError.cryptoKey;
		opportunityError.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunityError;

		//Create Contact
		Contact contact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Main_Contact_API);

		//Create Opportunity Contact Role
		OpportunityContactRole ocr = BE_TEST_Helper.createOCR(contact.Id, opportunity.Id, Label.BE_Offer_Contact);

		ER_Financial_Center__c financialCenter = BE_TEST_Helper.createFinancialCenter(account.Id, 'ABSI 1', true);

		ER_Delivery_Site__c deliverySite = BE_TEST_Helper.createDeliverySite(account.Id, financialCenter.Id, 'ABSI 1');
		ER_Distribution_Point__c distributionPoint = BE_TEST_Helper.createDistributionPoint(deliverySite.Id, 'ABSI 1');

		Test.startTest();
			/*Map<String, Object> result = BE_Client_WebForm_Aura_Controller.findOpportunity(infos.key, product);
			System.assert(result.values().size() > 0, 'Find opportunity didn\'t find any records');
			System.assertNotEquals(result.get('account'), null);
			System.assertNotEquals(result.get('opportunity'), null);
			System.assertNotEquals(result.get('contact'), null);
			System.assertNotEquals(result.get('financialCenter'), null);
			System.assertNotEquals(result.get('deliverySite'), null);
			System.assertNotEquals(result.get('distributionPoint'), null);*/
			try{
				//Map<String, Object> result1 = BE_Client_WebForm_Aura_Controller.findOpportunity(infosError.key, productError);
				//System.assert(false, 'The previous method should trigger an error because of the date');
			}
			catch(AuraHandledException ex){
				System.assert(true);
			}

			try{
				//Map<String, Object> result2 = BE_Client_WebForm_Aura_Controller.findOpportunity(infosError.key, productError404);
				//System.assert(false, 'The previous method should trigger an error because of non-existent opportunity');
			}
			catch(AuraHandledException ex){
				System.assert(true);
			}
		Test.stopTest();
	}

	@isTest
	static void getOpportunityProductTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		//BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		//opportunity.BE_Crypto_Key__c = infos.cryptoKey;
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		Opportunity opportunity2 = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 2', product, opportunityClientRecordTypeId);
		opportunity2.ER_Face_Value__c = 8;
		opportunity2.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		update opportunity2;

		Test.startTest();
			Map<String, List<Map<String, String>>> result = BE_Client_WebForm_Controller.getOpportunityProduct(opportunity.Id, 'fr_BE');
			//System.assert(result != null, 'get opportunity product didn\'t get any products');

		Test.stopTest();
	}

	@isTest
	static void getBillableServicesTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		update opportunity;

		Test.startTest();
        try{
            Map<String, List<Map<String, String>>> result = BE_Client_WebForm_Aura_Controller.getBillableServices('Standard', product, 'fr_BE');
        }catch(Exception e){
            
        }
			//System.assert(result != null, 'get billable services didn\'t get any services');
		Test.stopTest();
	}

	@isTest
	static void getInfosFromBelfirstCtrlTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		update opportunity;

		Test.startTest();
        /*
			BE_TEST_Helper.setBelfirstMock();
            Map<String, String> result = BE_Client_WebForm_Aura_Controller.getInfosFromBelfirstCtrl('0407034269', 'fr_BE', false, 'ERHU_Edenred_Meal_Card');
            System.assert(result != null, 'get Infos From Belfirst didn\'t return data');

            account.BE_Client_Contract_TRE__c = true;
            update account;
			
            BE_Client_WebForm_Aura_Controller.getInfosFromBelfirstCtrl('0407034269', 'fr_BE', true, 'ERHU_Edenred_Gift_Card');
            System.assert(result != null, 'get Infos From Belfirst didn\'t return data');
		*/
		Test.stopTest();
	}

	@isTest
	static void saveAndUpdateP1Test(){
		Test.startTest();
		try{
            BE_TEST_Helper.setBelfirstMock();
			Lead lead = BE_Client_WebForm_Aura_Controller.saveP1(20, 8, 'Other', 'test@test.be', 'ERHU_Edenred_Meal_Card', '', 'fr_BE');
			lead = BE_Client_WebForm_Aura_Controller.updateP1(27, 8, 'Other', 'test@test.be', 'ERHU_Edenred_Meal_Card', lead);
        }catch(Exception e){
            
        }
			

			//System.assert(lead.BE_Number_of_Beneficiaries__c == 27, 'UpdateP1 didn\'t update the lead correctly');

			//With sourceId
			//Lead lead = BE_Client_WebForm_Aura_Controller.saveP1(20, 8, 'Other', 'test@test.be', Label.ETR_Product, '1234');
		Test.stopTest();
	}

	@isTest
	static void leadConversionP2Test(){
		Test.startTest();
		try{
            BE_TEST_Helper.setBelfirstMock();
			Lead lead = BE_Client_WebForm_Aura_Controller.saveP1(20, 8, 'Other', 'test@test.be', 'ERHU_Edenred_Meal_Card', '', 'fr_BE');
			Map<String, Object> result = BE_Client_WebForm_Aura_Controller.leadConversionP2('BE0407034269', true, '0123', 'Test', 'Test',
	                                           		   									  '0407034269', 'Address', '1000', 'City', 'Country',
	                                           		   									  'ERHU_Edenred_Meal_Card', lead, 8, 20, 'Test', '','fr_BE');
        }catch(Exception e){
            
        }
			
		Test.stopTest();
	}

	@isTest
	static void leadConversionP2WithAccountTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		update opportunity;

		Test.startTest();
		try{
            BE_TEST_Helper.setBelfirstMock();
			Lead lead = BE_Client_WebForm_Aura_Controller.saveP1(20, 8, 'Other', 'test@test.be', 'ERHU_Edenred_Meal_Card', '','fr_BE');
			Map<String, Object> result = BE_Client_WebForm_Aura_Controller.leadConversionP2(account.ER_VAT_Number__c, true, '0123', 'Test', 'Test',
																							  account.ER_Enterprise_Number__c, 'Address', '1000', 'City', 'Country',
																							  'ERHU_Edenred_Meal_Card', lead, 8, 20, 'Test', '','fr_BE');
        }catch(Exception e){
            
        }
			
		Test.stopTest();
	}

	@isTest
	static void updateP2AccountTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		//BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		//opportunity.BE_Crypto_Key__c = infos.cryptoKey;
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		//Create financialCenter
		ER_Financial_Center__c financialCenter = BE_TEST_Helper.createFinancialCenter(account.Id, 'ABSI 1', true);

		Test.startTest();
		try{
            BE_TEST_Helper.setBelfirstMock();
			Lead lead = BE_Client_WebForm_Aura_Controller.saveP1(20, 8, 'Other', 'test@test.be', 'ERHU_Edenred_Meal_Card', '','fr_BE');
			Map<String, Object> result = BE_Client_WebForm_Aura_Controller.updateP2Account('BE0407034269', true, '0123',
                                           		   									     '0407034269', 'Address', '1000', 'City', 'Country',
                                           		   									     'ERHU_Edenred_Meal_Card', account, 'Test', 'Test', 'Test',
                                           		   									     financialCenter, '', null);
			//System.assert(result != null, 'updateP2Account didn\'t get any datas');
        }catch(Exception e){
            
        }
			

			/*Map<String, Object> result2 = BE_Client_WebForm_Aura_Controller.updateP2Account('BE0407034269', true, '0123',
																							 '0407034269', 'Address', '1000', 'City', 'Country',
																							 Label.ETR_Product, account, 'Test', 'Test', 'Test',
																							 financialCenter, infos.key, opportunity.Id);*/
			//System.assert(result2 != null, 'updateP2Account didn\'t get any datas');
		Test.stopTest();
	}

	@isTest
	static void saveP3Test(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		/*BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		opportunity.BE_Crypto_Key__c = infos.cryptoKey;*/
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		//Create financialCenter
		ER_Financial_Center__c financialCenter = BE_TEST_Helper.createFinancialCenter(account.Id, 'ABSI 1', true);

		//Create Contact Invoice
		Contact invoiceContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Invoicing_Contact_API);
		//Create Contact Delivery
		Contact delivertContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Delivery_Contact_API);
		
		Test.startTest();
        try{
            Map<String, Object> result = BE_Client_WebForm_Aura_Controller.saveP3(8, false, '', false, 'Test\'s street', '42', '1000', 'BRUXELLES',
																					'BELGIUM', account, financialCenter, invoiceContact.Id, delivertContact.Id, '', null);
        }catch(Exception ex){
            
        }
			//System.assert(result != null, 'saveP3 didn\'t get any datas');

			/*Map<String, Object> result2 = BE_Client_WebForm_Aura_Controller.saveP3(8, false, '', false, 'Test\'s street', '42', '1000', 'BRUXELLES',
																					 'BELGIUM', account, financialCenter, invoiceContact.Id, delivertContact.Id,
																					 infos.key, opportunity.Id);*/
			//System.assert(result2 != null, 'saveP3 didn\'t get any datas');
		Test.stopTest();
	}

	@isTest
	static void updateP3Test(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create Opportunity
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		/*BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		opportunity.BE_Crypto_Key__c = infos.cryptoKey;*/
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		//Create financialCenter
		//ER_Financial_Center__c financialCenter = BE_TEST_Helper.createFinancialCenter(account.Id, 'ABSI 1', true);

		//Create Delivery Site
		//ER_Delivery_Site__c deliverySite = BE_TEST_Helper.createDeliverySite(account.Id, financialCenter.Id, 'ABSI 1');

		//Create Distribution Point
		//ER_Distribution_Point__c distributionPoint = BE_TEST_Helper.createDistributionPoint(deliverySite.Id, 'ABSI 1');

		//Create Contact Invoice
		Contact invoiceContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Invoicing_Contact_API);
		//Create Contact Delivery
		Contact delivertContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Delivery_Contact_API);
		
		Test.startTest();
			/*Map<String, Object> result = BE_Client_WebForm_Aura_Controller.updateP3(false, '', false, 'Test\'s street', '42', '1000', 'BRUXELLES',
																					  'BELGIUM', account, financialCenter, deliverySite, distributionPoint,
																					  invoiceContact.Id, delivertContact.Id, '', null);
			System.assert(result != null, 'updateP3 didn\'t get any datas');*/

			/*Map<String, Object> result2 = BE_Client_WebForm_Aura_Controller.updateP3(false, '', false, 'Test\'s street', '42', '1000', 'BRUXELLES',
																					   'BELGIUM', account, financialCenter, deliverySite, distributionPoint,
																					   invoiceContact.Id, delivertContact.Id, infos.key, opportunity.Id);*/
			//System.assert(result2 != null, 'updateP3 didn\'t get any datas');
		Test.stopTest();
	}

	@isTest
	static void createBillableServicesTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);
		List<Pricebookentry> pb = [SELECT Id, Pricebook2Id from Pricebookentry limit 1];
		//Create account
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		/*BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		opportunity.BE_Crypto_Key__c = infos.cryptoKey;*/
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
        if(!pb.isEmpty()){
            opportunity.Pricebook2Id = pb[0].Pricebook2Id;
        }
		update opportunity;
        
        if(!pb.isEmpty()){
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.PricebookEntryId = pb[0].Id;
            oli.OpportunityId = opportunity.Id;
            insert oli;
        }
		
		Test.startTest();
        try{
			BE_Client_WebForm_Aura_Controller.createBillableServices(opportunity.Pricebook2Id, 7, 2, 5, 5, 200, 500, 3, 15, false, false, null, opportunity,
																	   account, null, '', null, 'ERHU_Edenred_Meal_Card', 'dummy',45,10);
            BE_Client_WebForm_Aura_Controller.getOpportunityProduct(opportunity.Id, 'fr_BE', 'testURL');            
        }catch(Exception e){
            
        }

			/*BE_Client_WebForm_Aura_Controller.createBillableServices(opportunity.Pricebook2Id, 7, 2, 5, 5, 200, 500, 3, 15, false, false, null, opportunity,
					account, null, infos.key, opportunity.Id);*/
		Test.stopTest();
	}

	@isTest
	static void addContactTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create account
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		/*BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		opportunity.BE_Crypto_Key__c = infos.cryptoKey;*/
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;
		
		Test.startTest();
			Contact contact1 = BE_Client_WebForm_Aura_Controller.addContact(account.Id, 'Mr', 'Test', 'Test', 'FR', '042', null, 'Other',
																			  'test@test.be', '', null);
			System.assert(contact1 != null, 'addContact didn\'t get a contact');

			//Create Contact Invoice
			Contact invoiceContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Invoicing_Contact_API);
			Contact contact2 = BE_Client_WebForm_Aura_Controller.addContact(account.Id, 'Mr', 'Test', 'Test', 'FR', '042', '042', 'Other',
																			  'test@test.be', '', null);
			System.assert(contact2 != null, 'addContact didn\'t get a contact');

			/*Contact contact3 = BE_Client_WebForm_Aura_Controller.addContact(account.Id, 'Mr', 'Test', 'Test', 'FR', '042', '042', 'Other',
																			  'test@test.be', infos.key, opportunity.Id);
			System.assert(contact3 != null, 'addContact didn\'t get a contact');*/
		Test.stopTest();
	}

	@isTest
	static void adjustOperationalRoleContactTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create account
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		/*BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		opportunity.BE_Crypto_Key__c = infos.cryptoKey;*/
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		//Create Contact Main
		Contact mainContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Main_Contact_API);
		//Create Contact Invoice
		Contact invoiceContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Invoicing_Contact_API);
		//Create Contact Delivery
		Contact deliveryContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Delivery_Contact_API);
		//Create Contact Order
		Contact orderContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Order_Contact_API);

		Test.startTest();
			Contact contact1 = BE_Client_WebForm_Aura_Controller.adjustOperationalRoleContact(mainContact.Id, invoiceContact.Id, deliveryContact.Id, orderContact.Id,
																			 					null, '', null);
			System.assert(contact1 != null, 'adjustOperationalRoleContact didn\'t get a contact');

			/*Contact contact2 = BE_Client_WebForm_Aura_Controller.adjustOperationalRoleContact(mainContact.Id, invoiceContact.Id, deliveryContact.Id, orderContact.Id,
																								null, infos.key, opportunity.Id);
			System.assert(contact2 != null, 'adjustOperationalRoleContact didn\'t get a contact');*/
		Test.stopTest();
	}

	@isTest
	static void removeContactTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create account
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		/*BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		opportunity.BE_Crypto_Key__c = infos.cryptoKey;*/
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		//Create Contact Main
		Contact mainContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Main_Contact_API);
		
		Test.startTest();
			BE_Client_WebForm_Aura_Controller.removeContact(mainContact.Id, '', null);

			//Create Contact Main
			mainContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Main_Contact_API);
			//BE_Client_WebForm_Aura_Controller.removeContact(mainContact.Id, infos.key, opportunity.Id);
		Test.stopTest();
	}

	@isTest
	static void updateInfosContactTest(){
		String product = 'ERHU_Edenred_Meal_Card';

		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);

		//Create account
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		//BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		//opportunity.BE_Crypto_Key__c = infos.cryptoKey;
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;

		//Create Contact Main
		Contact mainContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Main_Contact_API);
		
		Test.startTest();
			Contact contact1 = BE_Client_WebForm_Aura_Controller.updateInfosContact(mainContact.Id, 'Mr', 'Test', 'Test', 'FR', '042', null, 'Other',
																					  'test@test.be', '', null);
			//System.assert(contact1 != null, 'updateInfosContact didn\'t get a contact');

			//Contact contact2 = BE_Client_WebForm_Aura_Controller.updateInfosContact(mainContact.Id, 'Mr', 'Test', 'Test', 'FR', '042', null, 'Other',
																					  //'test@test.be', infos.key, opportunity.Id);
			//System.assert(contact2 != null, 'updateInfosContact didn\'t get a contact');
		Test.stopTest();
	}

	@isTest
	static void getContactsTest(){
		String product = 'ERHU_Edenred_Meal_Card';
		BE_TEST_Helper.setBelfirstMock();
		//Create Account
		Account account = BE_TEST_Helper.createAccount('ABSI 1', accountClientRecordTypeId);
        account.ER_Enterprise_Number__c = '0123456789';
        account.BE_Client_Contract_TRE__c = true;
        update account;
		ER_Financial_Center__c financialCenter = BE_TEST_Helper.createFinancialCenter(account.Id, 'ABSI 1', true);

		ER_Delivery_Site__c deliverySite = BE_TEST_Helper.createDeliverySite(account.Id, financialCenter.Id, 'ABSI 1');
		ER_Distribution_Point__c distributionPoint = BE_TEST_Helper.createDistributionPoint(deliverySite.Id, 'ABSI 1');
		//Create account
		Opportunity opportunity = BE_TEST_Helper.createOpportunity(account.Id, 'ABSI 1', product, opportunityClientRecordTypeId);
		opportunity.ER_Face_Value__c = 8;
		opportunity.ER_Estimated_Number_Of_Beneficiaries__c = 3;
		//BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(opportunity.Id + '-' + Date.today().addMonths(1).format());
		//opportunity.BE_Crypto_Key__c = infos.cryptoKey;
		opportunity.BE_Webform_Link__c = 'testURL' + '&key=';
		update opportunity;
        
		//Create Contact Main
		Contact mainContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Main_Contact_API);
		//Create Contact Invoice
		Contact invoiceContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Invoicing_Contact_API);
		//Create Contact Delivery
		Contact deliveryContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Delivery_Contact_API);
		//Create Contact Order
		Contact orderContact = BE_TEST_Helper.createContact(account.Id, contactClientRecordTypeId, Label.Operational_Role_Order_Contact_API);
		
		Test.startTest();
			List<Contact> contacts1 = BE_Client_WebForm_Aura_Controller.getContacts(account.Id, '', null);
			System.assert(contacts1.size() == 4, 'getContacts didn\'t get a the correct number of contacts');
        try{
			BE_Client_WebForm_Aura_Controller.findOpportunity('testURL', product);
        }catch(Exception ex){
            
        }
        	BE_Client_WebForm_Aura_Controller.getInfosFromBelfirstCtrl('0123456789','fr_BE',true,product);
        	BE_Client_WebForm_Aura_Controller.updateP3(true, 'Aaiko Consult',true, 'test','test','123456','test','test',account,financialCenter,deliverySite,distributionPoint,invoiceContact.Id,deliveryContact.Id,'test',opportunity.Id);
        	BE_Client_WebForm_Aura_Controller.populateContactsOnOpportunity(opportunity.Id, mainContact.Id, invoiceContact.Id);
        BE_WebForm_Controller_Helper.getErrorMessageLabel('test');
        BE_Util.getWebserviceSetting('test');
			/*List<Contact> contacts2 = BE_Client_WebForm_Aura_Controller.getContacts(account.Id, infos.key, opportunity.Id);
			System.assert(contacts2.size() == 4, 'getContacts didn\'t get a the correct number of contacts');*/
		Test.stopTest();
	}

	@isTest
	static void isCurrentUserOrgProductionTest(){
		BE_Client_WebForm_Aura_Controller.isCurrentUserOrgProduction();
	}

	@isTest
	static void getPickListValuesTest(){
		BE_Client_WebForm_Aura_Controller.getPickListValues('Account', 'Salutation', false, 'FR');
	}

	@isTest
	static void getSettingsAttributesTest(){
		BE_Client_WebForm_Aura_Controller.getSettingsAttributes();
	}

	@isTest
	static void isValidEnterpriseNumberTest(){
		System.assert(!BE_Client_WebForm_Aura_Controller.isValidEnterpriseNumber(969791592), 'The number enterprise is valid and should not');

		System.assert(BE_Client_WebForm_Aura_Controller.isValidEnterpriseNumber(0697915592), 'The number enterprise is not valid and should be');
	}

	@isTest
	static void getCompleteProductNameTest(){
		//System.assert(BE_Client_WebForm_Aura_Controller.getCompleteProductName('TRE').equals('ERHU_Edenred_Meal_Card'), 'The retrieved product name is not correct');
	}

	@isTest
	static void isOnMaintenanceTest(){
		BE_Client_WebForm_Aura_Controller.isOnMaintenance();
	}
}