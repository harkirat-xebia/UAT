/**
 * Created by imalka on 7/18/2018.
 */
@isTest
public class PDF_BE_ECEContractController_Test {
    public static Opportunity oppo;
    public static Account acc;

    @testSetup static void testSetup(){
        acc = new Account(Name='Test account', ShippingStreet='Rue grande, 143',
                ShippingPostalCode='1090', ShippingCity='Bruxelles', ShippingCountry='Belgium',
                BillingStreet='Rue grande, 143',BillingPostalCode='1090', BillingCity='Bruxelles', BillingCountry='Belgium',
                ER_Legal_Form__c='Indépendant, artisan - personne Physique',ER_Legal_Name__c='Test acc',ER_VAT_Number__c='BE0246812738');

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
        ER_Store__c store = new ER_Store__c(Name='BASTELEUS Freddy',ER_City__c='SINT-PIETERS-LEEUW',ERBE_Segment__c=segment,ERBE_Sub_Segment__c=subSegment,
                 ER_Street__c='Georges Wittouckstraat 0045', ER_Zip_Code__c='1600',ER_Merchant__c = acc.Id);
        insert store;

        ER_Bank_Account__c bankAccount = new ER_Bank_Account__c(Name='ING',ER_Bank_Name__c='ING',ER_BIC__c='AGRIFRPP836',ER_IBAN__c='FR7611808009101234567890147');
        insert bankAccount;

        ER_Financial_Center__c fc = new ER_Financial_Center__c(Name='Test financial center',ER_Account_Name__c=acc.Id
                ,ER_Contact__c=cont3.id,  ER_Payment_Site__c=true,ER_City__c='Bruxelles',ER_Country__c='Belgique',
                ER_Street__c='Rue de la licorne',ER_Zip_Code__c='1000',ER_Bank_Account__c=bankAccount.Id);
        insert fc;
        
        BE_FCtoBankAccount__c fcto = new BE_FCtoBankAccount__c();
        fcto.BE_Financial_Center__c = fc.Id;
        fcto.BE_Bank_Account__c = bankAccount.Id;
        fcto.BE_Type__c = 'Refund;Invoicing;';
        insert fcto;

        bankAccount.ER_Financial_Center__c = fc.Id;
        update bankAccount;

        ER_Delivery_Site__c ds = new ER_Delivery_Site__c(Name='delivery test', ER_City__c='Brussels',ER_Street__c='rue fbfgfg',ER_Street_additionnal__c='',ER_Zip_Code__c='1000',ER_Account_Name__c =acc.Id);
        insert ds;


        ER_Acceptor__c acceptor = new ER_Acceptor__c(Name = 'accept', ER_MID_Authorization__c = '321654987', ER_MID_Clearing__c = '123456789',
                                                     ER_TID_Authorization__c = '12345689', ER_Store__c = store.Id);
        insert acceptor;

        Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 standardTREPB = new Pricebook2(Name = 'BE TRE - Standard', IsActive = true);
        insert standardTREPB;
        Product2 solution = new Product2(Name = 'Edenred Meal', IsActive = true, ProductCode ='TRE', Days_Per_Month__c = 10, Load_Per_Year__c=10);
        insert solution;
        Product2 rangeProduct = new Product2(Name = '60001 - 90000', IsActive = true);
        insert rangeProduct;
        Product2 deliveryProduct = new Product2(Name = 'Card Delivery 01 to 03', IsActive = true);
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

        //Added to test NodeCategory and the initTree for the categories table
        List<BE_Category__c> listOfCategories = new List<BE_Category__c>();
        BE_Category__c cat;
        for(Integer i = 0; i < 10; ++i){
            cat = new BE_Category__c(BE_Label_FR__c = 'test'+i);
            listOfCategories.add(cat);
        }
        insert listOfCategories;

        List<BE_Store_Categorization__c> listOfStoreCategories = new List<BE_Store_Categorization__c>();
        BE_Store_Categorization__c sc;
        for(BE_Category__c c : listOfCategories){
            sc = new BE_Store_Categorization__c(BE_Store__c = store.Id, BE_Category__c = c.Id);
            listOfStoreCategories.add(sc);
        }
        insert listOfStoreCategories;
    }

    @isTest
    static void TEST_PDF_BE_ECE_Client_Contract(){
        oppo = [SELECT ID,AccountId,Name FROM Opportunity LIMIT 1];
		acc = [SELECT Id from Account where Name='Test account' limit 1];
        Test.setCurrentPageReference(Page.PDF_BE_ECE_Client_Contract_FR);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('productAcr', 'TRE');
        PDF_BE_ECE_Client_Contract_Controller eceContract = new PDF_BE_ECE_Client_Contract_Controller();


        Test.setCurrentPageReference(Page.PDF_BE_ECE_Client_Contract_NL);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('productAcr', 'TRE');
        PDF_BE_ECE_Client_Contract_Controller eceContract2 = new PDF_BE_ECE_Client_Contract_Controller();


    }

    @isTest
    static void TEST_PDF_BE_TCE_Client_Contract(){
        oppo = [SELECT ID,AccountId,Name FROM Opportunity LIMIT 1];
		acc = [SELECT Id from Account where Name='Test account' limit 1];
        Test.setCurrentPageReference(Page.PDF_BE_TCE_Client_Contract_FR);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('productAcr', 'TRE');
        PDF_BE_ECE_Client_Contract_Controller tceContract = new PDF_BE_ECE_Client_Contract_Controller();

        Test.setCurrentPageReference(Page.PDF_BE_TCE_Client_Contract_NL);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('productAcr', 'TRE');
        PDF_BE_ECE_Client_Contract_Controller tceContract2 = new PDF_BE_ECE_Client_Contract_Controller();

        PDF_BE_ECE_Client_Contract_Controller.isDutch();
    }

    @isTest
    static void TEST_PDF_BE_TRE_Client_Contract(){
        oppo = [SELECT ID, AccountId,Name FROM Opportunity LIMIT 1];
		acc = [SELECT Id from Account where Name='Test account' limit 1];
        Test.setCurrentPageReference(Page.PDF_BE_TRE_Client_Contract_FR);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('productAcr', 'TRE');
        PDF_BE_TREContractController treContract = new PDF_BE_TREContractController();

        Test.setCurrentPageReference(Page.PDF_BE_TRE_Client_Contract_NL);
        System.currentPageReference().getParameters().put('aid', acc.Id);
        System.currentPageReference().getParameters().put('oid', oppo.Id);
        System.currentPageReference().getParameters().put('productAcr', 'TRE');
        PDF_BE_TREContractController treContract2 = new PDF_BE_TREContractController();


    }


}