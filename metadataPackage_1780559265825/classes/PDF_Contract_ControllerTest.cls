@isTest
public with sharing class PDF_Contract_ControllerTest {
    public static Opportunity oppo;
    public static Account acc;

    @testSetup static void testSetup(){
        User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'BELUX', 'PL');
        runningUser.ER_BypassVR__c = true;
        runningUser.ER_Bypass_Flows__c = true;
        runningUser.ER_bypassTrigger__c = true;

        System.runAs(runningUser) {

            acc = new Account(Name='Test account', ShippingStreet='Rue grande, 143',
                    ShippingPostalCode='1090', ShippingCity='Bruxelles', ShippingCountry='Belgium',
                    BillingStreet='Rue grande, 143',BillingPostalCode='1090', BillingCity='Bruxelles', BillingCountry='Belgium',
                    ER_Legal_Form__c='Indépendant, artisan - personne Physique',ER_Legal_Name__c='Test acc',ER_VAT_Number__c='BE0246812738', ER_BUPicklist__c = 'BE');

            insert acc;
            date dateBirth = date.newInstance(1990, 11, 21);
            RecordType rt =  [SELECT id ,name
            from RecordType
            where name = :Label.BE_Merchant_Contact_RT LIMIT 1];

            Contact cont = new Contact(LastName='Geerts',FirstName='Sil',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil@absi.be',Fax='045454547545',
                    MobilePhone='0497947554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                    ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Main_Contact,RecordTypeId=rt.Id);
            insert cont;
            Contact cont2 = new Contact(LastName='Will',FirstName='Galas',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil@absi.be',Fax='045454547545',
                    MobilePhone='0497947554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                    ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Invoicing_Contact,RecordTypeId=rt.Id);
            insert cont2;

            Contact cont3 = new Contact(LastName='Laf',FirstName='Eric',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil@absi.be',Fax='045454547545',
                    MobilePhone='0497947554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                    ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Refund_Contact,RecordTypeId=rt.Id);
            insert cont3;
            Contact cont4 = new Contact(LastName='firtoz',FirstName='Gareth',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil@absi.be',Fax='045454547545',
                    MobilePhone='0497947554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                    ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Delivery_Contact,RecordTypeId=rt.Id);
            insert cont4;
            Contact cont5 = new Contact(LastName='firtoz',FirstName='Gareth',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sila@absi.be',Fax='045454547545',
                    MobilePhone='0497947554',HomePhone='0497949554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                    ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Order_Contact,RecordTypeId=rt.Id);
            insert cont5;

            
            String segment='Small Distribution';
            String subSegment='Chain Store';

            ER_Financial_Center__c fc = new ER_Financial_Center__c(Name='Test financial center',ER_Account_Name__c=acc.Id
                    ,ER_Contact__c=cont3.id,  ER_Payment_Site__c=true,ER_City__c='Bruxelles',ER_Country__c='Belgique',
                    ER_Street__c='Rue de la licorne',ER_Zip_Code__c='1000');
            insert fc;
            
            ER_Delivery_Site__c ds = new ER_Delivery_Site__c(Name='delivery test', ER_City__c='Brussels',ER_Street__c='rue fbfgfg',ER_Street_additionnal__c='',ER_Zip_Code__c='1000',ER_Account_Name__c =acc.Id);
            insert ds;

            Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
            Pricebook2 standardTREPB = new Pricebook2(Name = 'BE TRE - Standard', IsActive = true);
            insert standardTREPB;
            Product2 solution = new Product2(Name = 'Edenred Meal', IsActive = true, ProductCode ='TRE', Days_Per_Month__c = 10, Load_Per_Year__c=10, ER_Type__c = 'Solution');
            insert solution;
            Product2 solution2 = new Product2(Name = 'Addittional Services', IsActive = true, ProductCode ='TRC', Days_Per_Month__c = 10, Load_Per_Year__c=10, ER_Type__c = 'Solution');
            insert solution2;
            Product2 rangeProduct = new Product2(Name = '60001 - 90000', IsActive = true, ER_Type__c = 'Range', ER_Solution2__c = solution.Id);
            insert rangeProduct;
            Product2 deliveryProduct = new Product2(Name = 'Card Delivery 01 to 03', IsActive = true, ER_Type__c = 'Range',ER_Solution2__c = solution2.Id);
            insert deliveryProduct;

            PricebookEntry stdRangePBE = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = rangeProduct.Id, UnitPrice = 0, ER_Percentage__c = 4.5,
                    IsActive = true);
            insert stdRangePBE;
            PricebookEntry stdDeliveryPBE = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = deliveryProduct.Id, UnitPrice = 3,
                    IsActive = true);
            insert stdDeliveryPBE;

            PricebookEntry rangePBE = new PricebookEntry(Pricebook2Id = standardTREPB.Id, Product2Id = rangeProduct.Id, UnitPrice = 0, ER_Percentage__c = 4.5,
                    IsActive = true, UseStandardPrice = false);
            insert rangePBE;
            PricebookEntry deliveryPBE = new PricebookEntry(Pricebook2Id = standardTREPB.Id, Product2Id = deliveryProduct.Id, UnitPrice = 3,
                    IsActive = true, UseStandardPrice = false);
            insert deliveryPBE;

            Id oppoRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();

            Account testAccount = new Account(Name = 'Testaccount 2', ShippingStreet = 'Ruegrande, 144',
                                            ShippingPostalCode = '1091', ShippingCity = 'Bruxelles', ShippingCountry = 'Belgium',
                                            BillingStreet = 'Ruegrande, 143',BillingPostalCode = '1090', BillingCity = 'Bruxelles', BillingCountry = 'Belgium',
                                            ER_Legal_Form__c = 'Indépendant,artisan - personne Physique',ER_Legal_Name__c = 'Test acc2',ER_VAT_Number__c = 'BE0246818838');
            insert testAccount;

            oppo = new Opportunity(RecordTypeId = oppoRecordTypeId,Name='Test oppo',CloseDate=System.today(),
                    StageName='Proposal',AccountId=testAccount.Id, ER_Nb_of_Employees__c=2,ER_Estimated_Number_Of_Beneficiaries__c=10, ER_BUPicklist__c='BE' );

            insert oppo;

            BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Primary Contact');
            BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Invoicing Contact');
            BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Order Contact');
            BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Delivering Contact');
        }
    }

    @isTest
    static void TEST_PDF_Contract_Controller(){
        oppo = [SELECT ID,AccountId,Name FROM Opportunity LIMIT 1];
		acc = [SELECT Id from Account where Name='Test account' limit 1];
        Test.setCurrentPageReference(Page.PDF_Client_Contract_FR);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('language', 'FR');
        System.currentPageReference().getParameters().put('local', 'fr_BE');
        System.currentPageReference().getParameters().put('productCode', 'TRE');
        System.currentPageReference().getParameters().put('productName', 'Edenred Meal');
        System.currentPageReference().getParameters().put('estimatedVolume', '1000');
        System.currentPageReference().getParameters().put('plang', 'FR');
        PDF_Contract_Controller eceContract = new PDF_Contract_Controller();


        Test.setCurrentPageReference(Page.PDF_Client_Contract_NL);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('language', 'FR');
        System.currentPageReference().getParameters().put('local', 'fr_BE');
        System.currentPageReference().getParameters().put('productCode', 'TRE');
        System.currentPageReference().getParameters().put('productName', 'Edenred Meal');
        System.currentPageReference().getParameters().put('estimatedVolume', '1000');
        System.currentPageReference().getParameters().put('plang', 'FR');
        PDF_Contract_Controller eceContract2 = new PDF_Contract_Controller();
        
        oppo = [SELECT ID,AccountId,Name FROM Opportunity LIMIT 1];
		acc = [SELECT Id from Account where Name='Test account' limit 1];
        Test.setCurrentPageReference(Page.PDF_Client_FR_AutoEnrollment);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('language', 'FR');
        System.currentPageReference().getParameters().put('local', 'fr_BE');
        System.currentPageReference().getParameters().put('productCode', 'TRE');
        System.currentPageReference().getParameters().put('productName', 'Edenred Meal');
        System.currentPageReference().getParameters().put('estimatedVolume', '1000');
        System.currentPageReference().getParameters().put('plang', 'FR');
        PDF_Contract_Controller treContract = new PDF_Contract_Controller();


        Test.setCurrentPageReference(Page.PDF_Client_NL_AutoEnrollment);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('language', 'NL');
        System.currentPageReference().getParameters().put('local', 'nl_BE');
        System.currentPageReference().getParameters().put('productCode', 'TRE');
        System.currentPageReference().getParameters().put('productName', 'Edenred Meal');
        System.currentPageReference().getParameters().put('estimatedVolume', '1000');
        System.currentPageReference().getParameters().put('plang', 'NL');
        PDF_Contract_Controller treContract2 = new PDF_Contract_Controller();
        
        oppo = [SELECT ID,AccountId,Name FROM Opportunity LIMIT 1];
		acc = [SELECT Id from Account where Name='Test account' limit 1];
        Test.setCurrentPageReference(Page.PDF_Client_EN_AutoEnrollment);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('language', 'EN');
        System.currentPageReference().getParameters().put('local', 'en_US');
        System.currentPageReference().getParameters().put('productCode', 'TRE');
        System.currentPageReference().getParameters().put('productName', 'Edenred Meal');
        System.currentPageReference().getParameters().put('estimatedVolume', '1000');
        System.currentPageReference().getParameters().put('plang', 'EN');
        PDF_Contract_Controller treContract3 = new PDF_Contract_Controller();


        Test.setCurrentPageReference(Page.PDF_Client_DE_AutoEnrollment);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('language', 'DE');
        System.currentPageReference().getParameters().put('local', 'de_BE');
        System.currentPageReference().getParameters().put('productCode', 'TRE');
        System.currentPageReference().getParameters().put('productName', 'Edenred Meal');
        System.currentPageReference().getParameters().put('estimatedVolume', '1000');
        System.currentPageReference().getParameters().put('plang', 'DE');
        PDF_Contract_Controller treContract4 = new PDF_Contract_Controller();


    }
}