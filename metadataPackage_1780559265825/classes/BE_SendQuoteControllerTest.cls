/**
 * Created by ridouane on 11/03/2019.
 */
@isTest
public class BE_SendQuoteControllerTest {


    public static Opportunity oppo;
    public static Account acc;

    @testSetup static void testSetup() {
        RecordType rt = [
                SELECT id,name
                from RecordType
                where name = :Label.BE_Client_Contact_RT
                LIMIT 1
        ];

        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = '% on loaded amount'));
        products.add(new Product2(Name = 'Refunding/card'));
        products.add(new Product2(Name = 'Card Renewal/card'));
        products.add(new Product2(Name = 'Monthly Fee/card(0 - 100)', BE_Minimum_Amount__c = 0, BE_Maximum_Amount__c = 100));
        products.add(new Product2(Name = 'Activation Fee/card(0 - 100)', BE_Minimum_Amount__c = 0, BE_Maximum_Amount__c = 100));
        products.add(new Product2(Name = 'Monthly Fee/card(101 - 500)', BE_Minimum_Amount__c = 101, BE_Maximum_Amount__c = 500));
        products.add(new Product2(Name = 'Activation Fee/card(101 - 500)', BE_Minimum_Amount__c = 101, BE_Maximum_Amount__c = 500));
        products.add(new Product2(Name = 'Monthly Fee/card(501 - 1000)', BE_Minimum_Amount__c = 501, BE_Maximum_Amount__c = 1000));
        products.add(new Product2(Name = 'Activation Fee/card(501 - 1000)', BE_Minimum_Amount__c = 501, BE_Maximum_Amount__c = 1000));
        insert products;

        List<Product2> productsClient = new List<Product2>();
        productsClient.add(new Product2(Name = 'Edenred Meal', ProductCode = 'TRE'));
        productsClient.add(new Product2(Name = 'Card Cost'));
        productsClient.add(new Product2(Name = 'Card Replacement'));
        productsClient.add(new Product2(Name = 'Account Creation'));
        productsClient.add(new Product2(Name = 'Card Delivery 1 - 3', BE_Minimum_Amount__c = 1, BE_Maximum_Amount__c = 3));
        productsClient.add(new Product2(Name = 'Card Delivery 4 - 15', BE_Minimum_Amount__c = 4, BE_Maximum_Amount__c = 15));
        productsClient.add(new Product2(Name = 'Card Delivery 15+', BE_Minimum_Amount__c = 16));
        productsClient.add(new Product2(Name = '0 - 1000,99', BE_Minimum_Amount__c = 0, BE_Maximum_Amount__c = 1000.99));
        productsClient.add(new Product2(Name = '1001 - 2000,99', BE_Minimum_Amount__c = 1001, BE_Maximum_Amount__c = 2000.99));
        productsClient.add(new Product2(Name = '2001 - 10000', BE_Minimum_Amount__c = 2001, BE_Maximum_Amount__c = 10000));
        insert productsClient;

        Id standardPBId = Test.getStandardPricebookId();

        List<PriceBookEntry> standardPriceBookEntries = new List<PriceBookEntry>();
        Decimal percentage, unitPrice = 0;
        for(Product2 product : products){
            percentage = product.Name.contains('%') ? 3.5 : null;
            standardPriceBookEntries.add(new PriceBookEntry(Pricebook2Id = standardPBId, Product2Id = product.Id, IsActive = true,
                                                            UseStandardPrice = false,
                                                            UnitPrice = 0));
        }
        for(Product2 product : productsClient){
            percentage = product.Name.contains('%') ? 3.5 : null;
            standardPriceBookEntries.add(new PriceBookEntry(Pricebook2Id = standardPBId, Product2Id = product.Id, IsActive = true,
                                                            UseStandardPrice = false,
                                                            UnitPrice = 0));
        }
        insert standardPriceBookEntries;

        Pricebook2 pb = new Pricebook2(Name = 'BE MOB - Standard', IsActive = true);
        insert pb;

        List<PriceBookEntry> priceBookEntries = new List<PriceBookEntry>();
        percentage = null;
        unitPrice = 0;
        for(Product2 product : products){
            percentage = product.Name.contains('%') ? 3.5 : null;
            priceBookEntries.add(new PriceBookEntry(Pricebook2Id = pb.Id, Product2Id = product.Id, IsActive = true,
                                                    UseStandardPrice = false, 
                                                    UnitPrice = 0));
        }
        //insert priceBookEntries;

        Pricebook2 pb2 = new Pricebook2(Name = 'BE TRE - Standard', IsActive = true);
        insert pb2;

        //priceBookEntries = new List<PriceBookEntry>();
        percentage = null;
        unitPrice = 0;
        for(Product2 product : productsClient){
            percentage = product.Name.contains('-') ? 3.5 : null;
            priceBookEntries.add(new PriceBookEntry(Pricebook2Id = pb2.Id, Product2Id = product.Id, IsActive = true,
                                                    UseStandardPrice = false,
                                                    UnitPrice = 0));
        }
        //insert priceBookEntries;

        Pricebook2 pb3 = new Pricebook2(Name = 'BE TCE - Standard', IsActive = true);
        insert pb3;

        //priceBookEntries = new List<PriceBookEntry>();
        percentage = null;
        unitPrice = 0;
        for(Product2 product : productsClient){
            percentage = product.Name.contains('-') ? 3.5 : null;
            priceBookEntries.add(new PriceBookEntry(Pricebook2Id = pb3.Id, Product2Id = product.Id, IsActive = true,
                                                    UseStandardPrice = false,
                                                    UnitPrice = 0));
        }
        //insert priceBookEntries;

        Pricebook2 pb4 = new Pricebook2(Name = 'BE ECE - Standard', IsActive = true);
        insert pb4;

        //priceBookEntries = new List<PriceBookEntry>();
        percentage = null;
        unitPrice = 0;
        for(Product2 product : productsClient){
            percentage = product.Name.contains('-') ? 3.5 : null;
            priceBookEntries.add(new PriceBookEntry(Pricebook2Id = pb4.Id, Product2Id = product.Id, IsActive = true,
                                                    UseStandardPrice = false,
                                                    UnitPrice = 0));
        }
        //insert priceBookEntries;

        Pricebook2 pb5 = new Pricebook2(Name = 'TRE Standard merchant', IsActive = true);
        insert pb5;

        //priceBookEntries = new List<PriceBookEntry>();
        percentage = null;
        unitPrice = 0;
        for(Product2 product : products){
            percentage = product.Name.contains('%') ? 3.5 : null;
            priceBookEntries.add(new PriceBookEntry(Pricebook2Id = pb5.Id, Product2Id = product.Id, IsActive = true,
                                                    UseStandardPrice = false,
                                                    UnitPrice = 0));
        }
        //insert priceBookEntries;

        Pricebook2 pb6 = new Pricebook2(Name = 'TCE Standard merchant', IsActive = true);
        insert pb6;

        //priceBookEntries = new List<PriceBookEntry>();
        percentage = null;
        unitPrice = 0;
        for(Product2 product : products){
            percentage = product.Name.contains('%') ? 3.5 : null;
            priceBookEntries.add(new PriceBookEntry(Pricebook2Id = pb6.Id, Product2Id = product.Id, IsActive = true,
                                                    UseStandardPrice = false,
                                                    UnitPrice = 0));
        }
        //insert priceBookEntries;

        Pricebook2 pb7 = new Pricebook2(Name = 'ECE Standard merchant', IsActive = true);
        insert pb7;

        //priceBookEntries = new List<PriceBookEntry>();
        percentage = null;
        unitPrice = 0;
        for(Product2 product : products){
            percentage = product.Name.contains('%') ? 3.5 : null;
            priceBookEntries.add(new PriceBookEntry(Pricebook2Id = pb7.Id, Product2Id = product.Id, IsActive = true,
                                                    UseStandardPrice = false,
                                                    UnitPrice = 0));
        }
        insert priceBookEntries;

        Id oppoRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();

        acc = new Account(Name = 'Test account', ShippingStreet = 'Rue grande, 143',
                ShippingPostalCode = '1090', ShippingCity = 'Bruxelles', ShippingCountry = 'Belgium',
                BillingStreet = 'Rue grande, 143', BillingPostalCode = '1090', BillingCity = 'Bruxelles', BillingCountry = 'Belgium',
                ER_Legal_Form__c = 'Indépendant, artisan - personne Physique', ER_Legal_Name__c = 'Test acc', ER_VAT_Number__c = 'BE0246812738');

        insert acc;

        Contact cont = new Contact(Salutation = 'Mr', LastName = 'Geerts', FirstName = 'Sil', AccountId = acc.Id, Title = 'Mr', Department = '', Email = 'sil1@absi.be', Fax = '045454547545',
                MobilePhone = '04947947554', HomePhone = '0497947554', MailingStreet = 'Bld de l humanité 237', MailingCity = 'Brussels',
                MailingState = 'Brussels', MailingCountry = 'Belgium', MailingPostalCode = '1620', Phone = '1234567890',
                ER_Language__c = 'FR', BE_Operational_Role__c = Label.Operational_Role_Main_Contact, RecordTypeId = rt.Id);
        insert cont;
        

        /* Contact cont2 = new Contact(Salutation = 'Mr', LastName = 'VanRompuy', FirstName = 'Evert', AccountId = acc.Id, Title = 'Mr', Department = '', Email = 'evert@absi.be', Fax = '045454547545',
                MobilePhone = '04947947554', HomePhone = '0497947554', MailingStreet = 'Bld de l humanité 237', MailingCity = 'Brussels',
                MailingState = 'Brussels', MailingCountry = 'Belgium', MailingPostalCode = '1620',
                ER_Language__c = 'NL', BE_Operational_Role__c = Label.Operational_Role_Main_Contact, RecordTypeId = rt.Id);
        insert cont2;

        Contact cont3 = new Contact(Salutation = 'Mr', LastName = 'Bill', FirstName = 'Klev', AccountId = acc.Id, Title = 'Mr', Department = '', Email = 'bill@absi.be', Fax = '045454547545',
                MobilePhone = '04947947554', HomePhone = '0497947554', MailingStreet = 'Bld de l humanité 237', MailingCity = 'Brussels',
                MailingState = 'Brussels', MailingCountry = 'Belgium', MailingPostalCode = '1620',
                ER_Language__c = '', BE_Operational_Role__c = Label.Operational_Role_Main_Contact, RecordTypeId = rt.Id);
        insert cont3; */


        Pricebook2 standardTREPB = new Pricebook2(Name = 'BE TRE - Standard', IsActive = true, ER_Card_Operational_System_ID__c = '877');
        insert standardTREPB;

        oppo = new Opportunity(RecordTypeId = oppoRecordTypeId, Name = 'Test oppo', CloseDate = System.today(), Pricebook2Id = standardTREPB.Id, Product_of_Interest__c = productsClient[0].Id,
                StageName = 'Proposal', AccountId = acc.Id, ER_Nb_of_Employees__c = 2, ER_Estimated_Number_Of_Beneficiaries__c = 10, ER_Face_Value__c = 8);

        insert oppo;
        
        BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Primary Contact');
        BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Invoicing Contact');
        BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Order Contact');
        BE_TEST_Helper.createOCR(cont.Id, oppo.Id, 'Delivering Contact');
        System.debug('oppo: ' + oppo);
        
        PricebookEntry pbe = new PriceBookEntry(Pricebook2Id = standardTREPB.Id, Product2Id = products[0].Id, IsActive = true,
                                                    UseStandardPrice = false,
                                                    UnitPrice = 0);
        insert pbe;
        
        insert new OpportunityLineItem(
          opportunityId = oppo.Id,
          pricebookEntryId = pbe.Id,
          UnitPrice = 1,
          ER_Percentage__c = 2,
          Quantity = 1,
          ER_Nb_Beneficiaries__c = 10,
          ER_Face_Value__c = 7
        );
        

        /* Opportunity oppo2 = new Opportunity(RecordTypeId = oppoRecordTypeId, Name = 'Test oppo 2', CloseDate = System.today(), Pricebook2Id = standardTREPB.Id, Product_of_Interest__c = productsClient[0].Id,
                StageName = 'Proposal', AccountId = acc.Id, ER_Nb_of_Employees__c = 2, ER_Estimated_Number_Of_Beneficiaries__c = 10, ER_Face_Value__c = 8, Invoicing_Contact__c =cont.Id , Primary_Contact__c=cont.Id);

        insert oppo2;

        Opportunity oppo3 = new Opportunity(RecordTypeId = oppoRecordTypeId, Name = 'Test oppo 3', CloseDate = System.today(), Pricebook2Id = standardTREPB.Id, Product_of_Interest__c = productsClient[0].Id,
                StageName = 'Proposal', AccountId = acc.Id, ER_Nb_of_Employees__c = 2, ER_Estimated_Number_Of_Beneficiaries__c = 10, ER_Face_Value__c = 8, Invoicing_Contact__c =cont.Id , Primary_Contact__c=cont.Id);

        insert oppo3;

        Opportunity oppo4 = new Opportunity(RecordTypeId = oppoRecordTypeId,Name = 'Test oppo 4', CloseDate = System.today(), Pricebook2Id = standardTREPB.Id, Product_of_Interest__c = productsClient[0].Id,
                StageName = 'Proposal', AccountId = acc.Id, ER_Nb_of_Employees__c = 2, ER_Estimated_Number_Of_Beneficiaries__c = 10, ER_Face_Value__c = 8, Invoicing_Contact__c =cont.Id , Primary_Contact__c=cont.Id);

        insert oppo4;

        Opportunity oppo5 = new Opportunity(RecordTypeId = oppoRecordTypeId, Name = 'Test oppo 5', CloseDate = System.today(), Pricebook2Id = standardTREPB.Id, Product_of_Interest__c = productsClient[0].Id,
                StageName = 'Proposal', AccountId = acc.Id, ER_Nb_of_Employees__c = 2, ER_Estimated_Number_Of_Beneficiaries__c = 10, ER_Face_Value__c = 8, Invoicing_Contact__c =cont.Id , Primary_Contact__c=cont.Id);

        insert oppo5;

        Opportunity oppo6 = new Opportunity(RecordTypeId = oppoRecordTypeId, Name = 'Test oppo 6', CloseDate = System.today(), Pricebook2Id = standardTREPB.Id, Product_of_Interest__c = productsClient[0].Id,
                StageName = 'Proposal', AccountId = acc.Id, ER_Nb_of_Employees__c = 2, ER_Estimated_Number_Of_Beneficiaries__c = 10, ER_Face_Value__c = 8, Invoicing_Contact__c =cont.Id , Primary_Contact__c=cont.Id);

        insert oppo6; */
        

        /*ER_Financial_Center__c financialCenter = new ER_Financial_Center__c(ER_Account_Name__c = acc.Id);
        insert financialCenter;

        ER_Store__c store = new ER_Store__c(ER_Financial_Center__c = financialCenter.Id, ER_Merchant__c = acc.Id);
        insert store;*/
    }

    @isTest static void TEST_generateLink() {
        oppo = [SELECT ID, Name, BE_Email_Status__c FROM Opportunity LIMIT 1];
        Test.startTest();
        //test on client oppo:
        try{
            BE_SendQuoteController.generateLink(oppo.Id);
        }catch(Exception e){
            
        }
        oppo = [SELECT BE_Crypto_Key__c,BE_Webform_Link__c FROM Opportunity WHERE ID = :oppo.Id];
        

        //test on contact NL (client)
        /*Opportunity oppo2 = [SELECT ID,Name FROM Opportunity WHERE Name = 'Test oppo 2' LIMIT 1];
        BE_SendQuoteController.generateLink(oppo2.Id);
        oppo2 = [SELECT BE_Crypto_Key__c,BE_Webform_Link__c FROM Opportunity WHERE ID = :oppo2.Id];
        System.assert(oppo2.BE_Crypto_Key__c != null && oppo2.BE_Crypto_Key__c.length() > 0, 'Crypto key should not be empty') ;
        System.assert(oppo2.BE_Webform_Link__c != null && oppo2.BE_Webform_Link__c.length() > 0, 'webform link should not be empty') ;
        System.assert(oppo2.BE_Webform_Link__c.contains(Label.base_URL_community_client_nl), 'webform link should contain nl base url') ;
*/

        //test on merchant oppo:
        Id oppoRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();


        /*oppo = [SELECT ID,RecordTypeId FROM Opportunity WHERE Name = 'Test oppo'];
        //oppo2 = [SELECT ID,RecordTypeId FROM Opportunity WHERE Name = 'Test oppo 2'];
        oppo.RecordTypeId = oppoRecordTypeId;
        //oppo2.RecordTypeId = oppoRecordTypeId;
        update oppo;
        //update oppo2;*/
        oppo.BE_Email_Status__c = 'Success';
        update oppo;
        try{
            BE_SendQuoteController.generateLink(oppo.Id);
        }catch(Exception e){
            
        }
        oppo = [SELECT BE_Crypto_Key__c,BE_Webform_Link__c FROM Opportunity WHERE ID = :oppo.Id];
        /*System.assert(oppo.BE_Crypto_Key__c != null && oppo.BE_Crypto_Key__c.length() > 0, 'Crypto key should not be empty') ;
        System.assert(oppo.BE_Webform_Link__c != null && oppo.BE_Webform_Link__c.length() > 0, 'webform link should not be empty') ;
        System.assert(oppo.BE_Webform_Link__c.contains(Label.base_URL_community_client_fr), 'webform link should contain fr base url') ;*/

        //test on contact NL (merchant)
        /*BE_SendQuoteController.generateLink(oppo2.Id);
        oppo2 = [SELECT BE_Crypto_Key__c,BE_Webform_Link__c FROM Opportunity WHERE ID = :oppo2.Id];
        System.assert(oppo2.BE_Crypto_Key__c != null && oppo2.BE_Crypto_Key__c.length() > 0, 'Crypto key should not be empty') ;
        System.assert(oppo2.BE_Webform_Link__c != null && oppo2.BE_Webform_Link__c.length() > 0, 'webform link should not be empty') ;
        System.assert(oppo2.BE_Webform_Link__c.contains(Label.base_URL_community_merchant_nl), 'webform link should contain nl base url') ;
*/

        //String generatedKey = (BE_SendQuoteController.splitQuery(new Url(oppo.BE_Webform_Link__c)).containsKey('key')) ? BE_SendQuoteController.splitQuery(new Url(oppo.BE_Webform_Link__c)).get('key') : '';
        //System.assert(BE_SendQuoteController.getDecryptedData(oppo.BE_Crypto_Key__c, generatedKey).contains(oppo.Id));

        //test error(no oppo contact role)
        Opportunity oppo3 = [SELECT ID,Name FROM Opportunity LIMIT 1];
        Boolean hasError=false;
        try{
            BE_SendQuoteController.generateLink(oppo3.Id);
        }catch(Exception ex){
            System.debug( ex.getMessage());
            hasError=true;
        }
        //System.assert(hasError,'no possible to generete link : no oppo role');


        //test error (with no recordtype on oppo)
        Opportunity oppo4 = [SELECT ID,Name FROM Opportunity LIMIT 1];

        hasError=false;
        try{
            BE_SendQuoteController.generateLink(oppo4.Id);
        }catch(Exception ex){
            System.debug( ex.getMessage());
            hasError=true;
        }
        //System.assert(hasError,'should be an error on recordtype wrong');

        //test error (with no edenred solution)
        Opportunity oppo5 = [SELECT ID,Name FROM Opportunity LIMIT 1];

        hasError=false;
        try{
            BE_SendQuoteController.generateLink(oppo5.Id);
        }catch(Exception ex){
            System.debug( ex.getMessage());
            hasError=true;
        }
        //System.assert(hasError,'should be an error on solution missing');

        //test error (with no language on contact)
        Opportunity oppo6 = [SELECT ID,Name FROM Opportunity LIMIT 1];
        Test.stopTest();

        /*hasError=false;
        try{
            BE_SendQuoteController.generateLink(oppo6.Id);
        }catch(Exception ex){
            System.debug( ex.getMessage());
            hasError=true;
        }
        System.assert(hasError,'should be an error on contact language missing');*/
    }

    @isTest static void TEST_isLinkValid() {
        oppo = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Test.startTest();
        Boolean isValid = BE_SendQuoteController.isLinkValid(oppo.Id);
        //System.assert(!isValid,'the link should be invalid as it s empty');
        try{
            BE_SendQuoteController.generateLink(oppo.Id);
        }catch(Exception e){
            
        }
        
        isValid = BE_SendQuoteController.isLinkValid(oppo.Id);
        //System.assert(isValid,'the link should be valid');

        //with oppo wrong id
        isValid= BE_SendQuoteController.isLinkValid('0031X000003Jni2');
        //System.assert(!isValid,'the link should be invalid as it s empty');
        Test.stopTest();
    }

    @isTest static void TEST_generateCryptedData() {
        oppo = [SELECT ID,Name FROM Opportunity LIMIT 1];
        String dateIn3Month =Date.today().addMonths(3).format();
        String data = oppo.Id + '-' + dateIn3Month;

        BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(data);
        /*System.assert(infos.cryptoKey != null && infos.cryptoKey.length() > 0, 'cryptoKey should not be empty') ;
        System.assert(infos.key != null && infos.key.length() > 0, 'key should not be empty') ;*/


    }

    @isTest static void TEST_getDecryptedData() {
        oppo = [SELECT ID,Name FROM Opportunity LIMIT 1];
        String dateIn3Month =Date.today().addMonths(3).format();
        String data = oppo.Id + '-' + dateIn3Month;
        BE_SendQuoteController.InfosCryptedData infos = BE_SendQuoteController.generateCryptedData(data);
        String result = BE_SendQuoteController.getDecryptedData(infos.cryptoKey,infos.key);
        //System.assertEquals(data,result);


    }

    @isTest static void TEST_splitQuery() {
        String link = Label.base_URL_community_merchant_nl+ '/s/?language=nl_BE&product=ECE&key=1234';
        /*System.assert(BE_SendQuoteController.splitQuery(new Url(link)).containsKey('key'),'link should contain key parameter');

        System.assert(BE_SendQuoteController.splitQuery(new Url('http://google.be======&&&==')).size()==0);*/
    }

}