public class BE_TEST_Helper{
    static Id contactClientRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.BE_Client_Contact_RT).getRecordTypeId();

    public static void setBelfirstMock(){
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('BelfirstMock');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/soap+xml');
            Test.setMock(HttpCalloutMock.class, mock);
    }

    public static void insertPriceBook() {
        // Step 1: Create product lists
        List<Product2> products = new List<Product2>{
            new Product2(Name = '% on loaded amount', ER_EDG_Product_Ref__c = 'CH_TRANS', ProductCode = 'TRE', IsActive = true),
            new Product2(Name = 'Refunding/card', IsActive = true),
            new Product2(Name = 'Card Renewal/card', IsActive = true),
            new Product2(Name = 'Monthly Fee/card(0 - 100)', IsActive = true),
            new Product2(Name = 'Activation Fee/card(0 - 100)', IsActive = true),
            new Product2(Name = 'Monthly Fee/card(101 - 500)', IsActive = true),
            new Product2(Name = 'Activation Fee/card(101 - 500)', IsActive = true),
            new Product2(Name = 'Monthly Fee/card(501 - 1000)', IsActive = true),
            new Product2(Name = 'Activation Fee/card(501 - 1000)')
        };
    
        List<Product2> productsClient = new List<Product2>{
            new Product2(Name = 'Card Cost', IsActive = true),
            new Product2(Name = 'Card Replacement', IsActive = true),
            new Product2(Name = 'Account Creation', IsActive = true),
            new Product2(Name = 'Card Delivery 1 - 3', IsActive = true),
            new Product2(Name = 'Card Delivery 4 - 15', IsActive = true),
            new Product2(Name = 'Card Delivery 15+', IsActive = true),
            new Product2(Name = '0 - 1000,99', IsActive = true),
            new Product2(Name = '1001 - 2000,99', IsActive = true),
            new Product2(Name = '2001 - 10000')
        };
    
        insert products;
        insert productsClient;
    
        // Step 2: Insert entries in Standard Pricebook (all unitPrice = 0)
        Id stdPbId = Test.getStandardPricebookId();
        List<PricebookEntry> stdEntries = new List<PricebookEntry>();
        for (Product2 p : products) {
            stdEntries.add(new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = p.Id,
                IsActive = true,
                UseStandardPrice = false,
                UnitPrice = 0,
                ER_ValueType__c = 'Currency'
            ));
        }
        for (Product2 p : productsClient) {
            stdEntries.add(new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = p.Id,
                IsActive = true,
                UseStandardPrice = false,
                UnitPrice = 0,
                ER_ValueType__c = 'Currency'
            ));
        }
        insert stdEntries;
    
        // Step 3: Create custom pricebooks
        List<Pricebook2> books = new List<Pricebook2>{
            new Pricebook2(Name = 'BE MOB - Standard', IsActive = true),
            new Pricebook2(Name = 'BE TRE - Standard', IsActive = true),
            new Pricebook2(Name = 'BE TCE - Standard', IsActive = true),
            new Pricebook2(Name = 'BE ECE - Standard', IsActive = true),
            new Pricebook2(Name = 'TRE Standard merchant', IsActive = true),
            new Pricebook2(Name = 'TCE Standard merchant', IsActive = true),
            new Pricebook2(Name = 'ECE Standard merchant', IsActive = true)
        };
        insert books;
    
        // Step 4: Insert entries for custom books
        List<PricebookEntry> customEntries = new List<PricebookEntry>();
        Integer runningPrice = 1;
    
        // Helper to generate valid entries for a given list and book
        for (Integer i = 0; i < books.size(); i++) {
            Pricebook2 book = books[i];
            List<Product2> prodList = (i == 0 || i >= 4) ? products : productsClient;
    
            for (Product2 p : prodList) {
                Boolean isPct = p.Name.contains('%') || p.Name.contains('-');
    
                customEntries.add(new PricebookEntry(
                    Pricebook2Id = book.Id,
                    Product2Id = p.Id,
                    IsActive = true,
                    UseStandardPrice = false,
                    UnitPrice = isPct ? 0 : runningPrice++,
                    ER_Percentage__c = isPct ? 3.5 : null,
                    ER_ValueType__c = isPct ? 'Percentage' : 'Currency'
                ));
            }
        }
    
        insert customEntries;
    }

    public static OpportunityLineItem createOLI(
        Opportunity  opp,
        Pricebook2   pb,
        Product2     prod,
        String prodId,
        Decimal      unitPrice,
        Decimal      percentage
    )
    {
        

        // Ensure opp is attached to the same pricebook
        if (opp.Pricebook2Id == null)
        {
            opp.Pricebook2Id = pb.Id;
            update opp;
        }
        
        System.debug('prod: ' + prod);
        List<PricebookEntry> rows = [
            SELECT Id
            FROM   PricebookEntry
            WHERE  Pricebook2Id = :pb.Id
            AND    Product2Id   = :prod.Id
            LIMIT  1
        ];
        System.debug('rows: ' + rows);
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId        = opp.Id,
            Product2Id     = prodId,
            Quantity             = 1,
            UnitPrice            = unitPrice,       // money line
            ER_Percentage__c     = percentage,      // set 0 or a real %
            ER_Face_Value__c     = 10,
            ER_Nb_Beneficiaries__c = 3,
            ER_Load_Per_Year__c  = 365,
            ER_Days_Per_Month__c = 30,
            ER_BUPicklist__c     = 'BE'
        );
        insert oli;
        return oli;
    }
    

	public static Account createAccount(String name, Id recordTypeId){
		Account account = new Account(Name = 'Test-'+name, ER_Legal_Form__c = 'Company test',
									   ER_Enterprise_Number__c = '0407034269', ER_VAT_Number__c = 'BE0407034269',
                                      Phone = '024444444', BillingStreet = 'rue du test, 42',
                                      BillingPostalCode = '1000', BillingCity = 'BRUXELLES',
                                      BillingCountry = 'BELGIUM', ER_Card_Operational_System_ID__c='454',
                                      RecordTypeId = recordTypeId);
		insert account;

		return account;
	}

	public static Account createAccount(String name, String legalForm, String enterpriseNumber, String vatNumber,
										String phone, String billingStreet, String billingPostalCode,
										String billingCity, String billingCountry, String operationalSystem,
										Id recordTypeId){
		Account account = new Account(Name = 'Test-' + name, ER_Legal_Form__c = legalForm,
									   ER_Enterprise_Number__c = enterpriseNumber, ER_VAT_Number__c = vatNumber,
                                      Phone = phone, BillingStreet = BillingStreet,
                                      BillingPostalCode = billingPostalCode, BillingCity = billingCity,
                                      BillingCountry = billingCountry, ER_Card_Operational_System_ID__c = operationalSystem,
                                      RecordTypeId = recordTypeId);
		insert account;

		return account;
	}

	public static Contact createContact(Id accountId, Id recordTypeId, String role){
		Contact contact = new Contact(LastName='Test', FirstName=role + 'Silly', Birthdate = date.newInstance(1990, 11, 21),
						  			  Title = 'Mr', Department = '', Email = 'silly@absi.be', Fax = '0498765432',
    					  			  MobilePhone = '0497947554', HomePhone = '0498765432',
    					  			  MailingStreet = 'Bld de l\'humanité 237', MailingCity = 'BRUXELLES',
    					  			  MailingState = 'BRUXELLES', MailingCountry = 'BELGIUM', MailingPostalCode = '1620',
    					  			  ER_Language__c = 'FR', BE_Operational_Role__c = role,
    					  			  AccountId = accountId, RecordTypeId = recordTypeId);
        insert contact;

        return contact;
	}

	public static Opportunity createOpportunity(Id accountId, String name, String product, Id recordTypeId){
		String productAcr = [SELECT Name__c FROM BE_Product_Name_Mapping__mdt WHERE Full_Name__c = :product].Name__c;
		Opportunity opportunity = new Opportunity(Name = 'Test-' + productAcr + '-' + name, StageName = 'Qualification',
												  CloseDate = System.today(), BE_Edenred_Solution__c = product,
												  AccountId = accountId, RecordTypeId = recordTypeId);
		insert opportunity;

		return opportunity;
	}

	public static OpportunityContactRole createOCR(Id contactId, Id opportunityId, String role){
		OpportunityContactRole ocr = new OpportunityContactRole(ContactId = contactId, OpportunityId = opportunityId,
																  Role = role);
		insert ocr;

		return ocr;
	}

	public static ER_Financial_Center__c createFinancialCenter(Id accountId, String name, Boolean isInvoicingSite){
		//Contact contact = createContact(accountId, contactClientRecordTypeId, Label.Operational_Role_Invoicing_Contact_API);
		ER_Financial_Center__c financialCenter = new ER_Financial_Center__c(Name = 'Test-' + name, ER_Street__c = 'rue du test, 42',
																			ER_Zip_Code__c = '1000', ER_City__c = 'BRUXELLES',
																			ER_Country__c = 'BEGIUM', ER_Invoicing_Site__c = isInvoicingSite,
                                                                            ER_Payment_Site__c = !isInvoicingSite, ER_Account_Name__c = accountId, ER_Type__c = 'Client');
		insert financialCenter;

		return financialCenter;
	}

    /* public static ER_Bank_Account__c createBankAccount(Id financialCenterId, String type){
         ER_Bank_Account__c bankAccount = new ER_Bank_Account__c(ER_IBAN__c = 'BE52310022341109');
        insert bankAccount;

        BE_FCtoBankAccount__c fcToBa = new BE_FCtoBankAccount__c(BE_Type__c = type,
                                                                 BE_Financial_Center__c = financialCenterId,
                                                                 BE_Bank_Account__c = bankAccount.Id);
        insert fcToBa;

        return bankAccount;
    } */

    public static ER_Store__c createStore(Id accountId, Id financialCenterId, String name){
        ER_Store__c store = new ER_Store__c(Name = 'Test-' + name, ER_Merchant__c = accountId, ER_Financial_Center__c = financialCenterId);

        insert store;

        return store;
    }

   /*  public static BE_Category__c createCategory(Id storeId, Boolean isMain){
        BE_Category__c category = new BE_Category__c(BE_Label_FR__c = 'Test');
        insert category;

        BE_Store_Categorization__c storeCategorization = new BE_Store_Categorization__c(BE_Is_Main_Category__c = isMain,
                                                                                        BE_Category__c = category.Id,
                                                                                        BE_Store__c = storeId);
        insert storeCategorization;

        return category;
    } */

    /* public static ER_Acceptor__c createAcceptor(Id storeId, String tid){
        ER_Acceptor__c acceptor = new ER_Acceptor__c(ER_TID_Authorization__c = tid, ER_Terminal_Scheme__c = 'Web', ER_Store__c = storeId);

        insert acceptor;

        return acceptor;
    } */

	public static ER_Delivery_Site__c createDeliverySite(Id accountId, Id financialCenterId, String name){
		ER_Delivery_Site__c deliverySite = new ER_Delivery_Site__c(Name = 'Test-' + name, ER_Street__c = 'rue du test, 42',
																   ER_Zip_Code__c = '1000', ER_City__c = 'BRUXELLES',
																   ER_Country__c = 'BEGIUM', ER_Account_Name__c = accountId,
                                                                   ER_Financial_Center__c = financialCenterId);
		insert deliverySite;

		return deliverySite;
	}

	public static ER_Distribution_Point__c createDistributionPoint(Id deliverySite, String name){
		ER_Distribution_Point__c distributionPoint = new ER_Distribution_Point__c(Name = 'Test-' + name,
																				  ER_Street__c = 'rue du test, 42',
															   			 		  ER_Zip_Code__c = '1000',
															   			 		  ER_City__c = 'BRUXELLES',
															   			 		  ER_Country__c = 'BEGIUM',
															   			 		  ER_Delivery_Site__c = deliverySite);
		insert distributionPoint;

		return distributionPoint;
	}
}