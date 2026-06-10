@isTest
private class BE_General_Conditions_ControllerTest {
    public static BE_General_Condition__c condition;
    public static Opportunity oppo;
    public static Account acc;

    @testSetup static void testSetup(){
        acc = new Account(Name='Test account', ShippingStreet='Rue grande, 143',
                ShippingPostalCode='1090', ShippingCity='Bruxelles', ShippingCountry='Belgium',
                BillingStreet='Rue grande, 143',BillingPostalCode='1090', BillingCity='Bruxelles', BillingCountry='Belgium',
                ER_Legal_Form__c='Indépendant, artisan - personne Physique',ER_Legal_Name__c='Test acc',ER_VAT_Number__c='BE0996812738');

        insert acc;

        RecordType rt =  [SELECT id ,name
        from RecordType
        where name = :Label.BE_Client_Contact_RT LIMIT 1];

        Account accMerch = new Account(Name = 'Test 2', ER_Legal_Form__c = 'Société test', ER_Registration_Number__c = '0415536815',
                ER_VAT_Number__c = 'BE0415536815',
                Phone = '024444444', BillingStreet = 'rue du test, 42', BillingPostalCode = '1000', BillingCity = 'BRUXELLES',
                BillingCountry = 'BELGIUM', ER_External_Reference__c = 'test');
        insert accMerch;
        String segment='Small Distribution';
        String subSegment='Chain Store';

        /*ER_Store__c store = new ER_Store__c(Name = 'BASTELEUS Freddy', ER_City__c = 'SINT-PIETERS-LEEUW', ERBE_Segment__c = segment, ERBE_Sub_Segment__c = subSegment,
                                            BE_Franchised__c = 'No', ER_Street__c = 'Georges Wittouckstraat 0045', ER_Zip_Code__c = '1600', ER_Merchant__c = accMerch.Id);*/
        //insert store;

        /*ER_Bank_Account__c bankAccount = new ER_Bank_Account__c(Name = 'ING', ER_Bank_Name__c = 'ING', ER_BIC__c = 'BPOTBEB1', ER_IBAN__c = 'BE96000535178605');
        insert bankAccount;*/



        /*ER_Acceptor__c acceptor = new ER_Acceptor__c(Name='accept', ER_Terminal_Scheme__c = 'Web', ER_MID_Authorization__c = '321654987', ER_MID_Clearing__c = '123456789',
                                                     BE_Terminal_Provider__c = 'Atos-Worldline', BE_Terminal_Model__c = 'CZAM/XENTA-M1', ER_TID_Authorization__c = '01451247', ER_Store__c = store.Id);
        insert acceptor;*/

        date dateBirth = date.newInstance(1990, 11, 21);

        Contact contMerch = new Contact(LastName='Geerts',FirstName='Sil',AccountId = accMerch.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil1@absi1.be',Fax='045454547545',
                MobilePhone='04947947554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Main_Contact,RecordTypeId=rt.Id);
        insert contMerch;

        Contact contMerch2 = new Contact(LastName='Will',FirstName='Galas',AccountId = accMerch.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil2@absi2.be',Fax='045454547545',
                MobilePhone='04979447554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Invoicing_Contact,RecordTypeId=rt.Id);
        insert contMerch2;   

        // Contact contMerch3 = new Contact(LastName='Laf',FirstName='Eric',AccountId = accMerch.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil3@absi3.be',Fax='045454547545',
        //         MobilePhone='04957947554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
        //         ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Refund_Contact,RecordTypeId=rt.Id);
        // insert contMerch3;
        Contact contMerch4 = new Contact(LastName='firtoz',FirstName='Gareth',AccountId = accMerch.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil4@absi4.be',Fax='045454547545',
                MobilePhone='04979547554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Delivery_Contact,RecordTypeId=rt.Id);
        insert contMerch4;
        Contact contMerch5 = new Contact(LastName='firdtoz',FirstName='Gardeth',AccountId = accMerch.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sigggl5@absi5.be',Fax='045454547545',
                MobilePhone='04976665554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Order_Contact,RecordTypeId=rt.Id);
        insert contMerch5;

        /*ER_Financial_Center__c fc = new ER_Financial_Center__c(Name='Test financial center',ER_Account_Name__c=accMerch.Id
                ,ER_Contact__c=contMerch2.id,  ER_Payment_Site__c=true,ER_City__c='Bruxelles',ER_Country__c='Belgique',
                ER_Street__c='Rue de la licorne',ER_Zip_Code__c='1000',ER_Bank_Account__c=bankAccount.Id);
        insert fc;

        bankAccount.ER_Financial_Center__c = fc.Id;
        update bankAccount;*/
        
        ER_Financial_Center__c fc = new ER_Financial_Center__c(Name='Test financial center',ER_Account_Name__c=accMerch.Id
                ,ER_Contact__c=contMerch2.id,  ER_Payment_Site__c=true,ER_City__c='Bruxelles',ER_Country__c='Belgique',
                ER_Street__c='Rue de la licorne',ER_Zip_Code__c='1000');
        insert fc;

        /*ER_Delivery_Site__c ds = new ER_Delivery_Site__c(Name='delivery test', ER_City__c='Brussels',ER_Street__c='rue fbfgfg',
                ER_Street_additionnal__c='',ER_Zip_Code__c='1000',ER_Account_Name__c =accMerch.Id,ER_Delivery_Contact__c=contMerch4.Id,
                ER_Financial_Center__c=fc.Id);
        insert ds;*/

        /*ER_Distribution_Point__c dp = new ER_Distribution_Point__c(Name='dp point',ER_City__c='Bruxelles',ER_Country__c='Belgique',
                ER_Street__c='Rue de la licorne',ER_Zip_Code__c='1000',ER_Delivery_Site__c=ds.Id);
        insert dp;*/

        //---------------
        Contact cont = new Contact(LastName='Geerts',FirstName='Sil',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='silgggtt1@absi6.be',Fax='045454547545',
                MobilePhone='04947922554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Main_Contact,RecordTypeId=rt.Id);
        insert cont;
        Contact cont2 = new Contact(LastName='Will',FirstName='Galas',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='silnhgdd2@absi7.be',Fax='045454547545',
                MobilePhone='04979444444',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Invoicing_Contact,RecordTypeId=rt.Id);
        insert cont2;

        // Contact cont3 = new Contact(LastName='Laf',FirstName='Eric',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sil3@absi.be',Fax='045454547545',
        //         MobilePhone='04957947554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
        //         ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Refund_Contact,RecordTypeId=rt.Id);
        // insert cont3;
        Contact cont4 = new Contact(LastName='firtoz',FirstName='Gareth',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='sihgfl4@absi8.be',Fax='045454547545',
                MobilePhone='04911147554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Delivery_Contact,RecordTypeId=rt.Id);
        insert cont4;
        Contact cont5 = new Contact(LastName='firdtoz',FirstName='Gardeth',AccountId = acc.Id, Birthdate=dateBirth,Title='Mr',Department='',Email='silytrfdcx5@absi9.be',Fax='045454547545',
                MobilePhone='04979585554',HomePhone='0497947554',MailingStreet='Bld de l humanité 237',MailingCity='Brussels',MailingState='Brussels',MailingCountry='Belgium',MailingPostalCode='1620',
                ER_Language__c='FR',BE_Operational_Role__c=Label.Operational_Role_Order_Contact,RecordTypeId=rt.Id);
        insert cont5;

        Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 standardTREPB = new Pricebook2(Name = 'BE TRE - Standard', IsActive = true,ER_Card_Operational_System_ID__c='877');
        insert standardTREPB;
        Pricebook2 standardTCEPB = new Pricebook2(Name = 'TCE standard merchant', IsActive = true,ER_Card_Operational_System_ID__c='857');
        insert standardTCEPB;

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
        PricebookEntry rangePBE2 = new PricebookEntry(Pricebook2Id = standardTCEPB.Id, Product2Id = rangeProduct.Id, UnitPrice = 0, ER_Percentage__c = 4.5,
                IsActive = true, UseStandardPrice = false);
        insert rangePBE2;
        PricebookEntry deliveryPBE2 = new PricebookEntry(Pricebook2Id = standardTCEPB.Id, Product2Id = deliveryProduct.Id, UnitPrice = 3,
                IsActive = true, UseStandardPrice = false);
        insert deliveryPBE2;

        condition = new BE_General_Condition__c(BE_Body__c = 'bla', BE_Edenred_Solution__c = 'ERHU_Edenred_Meal_Card',
                                                BE_Type__c = 'Customer', BE_Language__c = 'en_US', BE_Active__c = true);

        insert condition;

        Id oppoRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.BE_Client_Opportunity).getRecordTypeId();

        Account testAccount = new Account(Name = 'Test accnt 2', ShippingStreet = 'Rue grande, 143',
                                          ShippingPostalCode = '1090', ShippingCity = 'Bruxelles', ShippingCountry = 'Belgium',
                                          BillingStreet = 'Rue grande, 143',BillingPostalCode = '1090', BillingCity = 'Bruxelles', BillingCountry = 'Belgium',
                                          ER_Legal_Form__c = 'Indépendant, artisan - personne Physique',ER_Legal_Name__c = 'Test acc3',ER_VAT_Number__c = 'BE0246110038');
        insert testAccount;

        oppo = new Opportunity(RecordTypeId = oppoRecordTypeId,Name='Test oppo',CloseDate=System.today(),Pricebook2Id = standardTREPB.Id,
                StageName='StageName',AccountId=testAccount.Id, ER_Nb_of_Employees__c=2,ER_Estimated_Number_Of_Beneficiaries__c=10, ER_BUPicklist__c ='BE');
        

        Opportunity oppo2 = new Opportunity(RecordTypeId = oppoRecordTypeId,Name='Test oppo2',CloseDate=System.today(),Pricebook2Id = standardTCEPB.Id,
                StageName='Proposal',AccountId=testAccount.Id, ER_Nb_of_Employees__c=2,ER_Estimated_Number_Of_Beneficiaries__c=10);

        insert oppo;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = oppo.Id;
        oli.PricebookEntryId = deliveryPBE.Id;
        insert oli;

        insert oppo2;

        OpportunityContactRole ocr1 = new OpportunityContactRole(OpportunityId = oppo.Id, ContactId = cont.Id, Role = Label.BE_Offer_Contact);
        insert ocr1;
        OpportunityContactRole ocr2 = new OpportunityContactRole(OpportunityId = oppo2.Id, ContactId = cont2.Id, Role = Label.BE_Offer_Contact);
        insert ocr2;
    }
    
    @isTest static void TEST_getGeneralCondition(){
        oppo = [SELECT Id, Name FROM Opportunity WHERE StageName = 'StageName' LIMIT 1];

        BE_General_Condition__c cond = BE_General_Conditions_Aura_Controller.getGeneralCondition('en_US', 'ERHU_Edenred_Meal_Card', oppo.Id, 'Customer');
        cond = [SELECT ID, BE_Body__c, BE_Edenred_Solution__c, BE_Type__c, BE_Language__c FROM BE_General_Condition__c WHERE ID=:cond.Id ];
        condition = [SELECT ID, BE_Body__c, BE_Edenred_Solution__c, BE_Type__c, BE_Language__c FROM BE_General_Condition__c WHERE BE_Edenred_Solution__c = 'ERHU_Edenred_Meal_Card' LIMIT 1 ];

        System.assertEquals(condition.BE_Body__c, cond.BE_Body__c);
        System.assertEquals(condition.BE_Edenred_Solution__c, cond.BE_Edenred_Solution__c);
        System.assertEquals(condition.BE_Type__c, cond.BE_Type__c);
        System.assertEquals(condition.BE_Language__c, cond.BE_Language__c);

    }
    
    @isTest static void TEST_submitAgreedToGeneralCondition1(){
        String mockResponseBody = '{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1731935419","not_before":"1731931519","resource":"7f73991c-df92-4a33-9668-81e58b5ebfe7","access_token":"test"}';
        HTTPCalloutServiceMock testMock = new HTTPCalloutServiceMock(200, mockResponseBody);
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, testMock);
        oppo = [SELECT ID, StageName, Name,BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,ER_PaymentMethod__c
        FROM Opportunity WHERE StageName = 'StageName' LIMIT 1];
        acc = [SELECT ID,Name FROM Account WHERE Name='Test 2' LIMIT 1];
        Test.startTest();

        String response = '{ "meta": { "culture": "en-GB", "status": "Success", "messages": [] }, "data": { "legal_name": "BURTON ET ALAIME", "commercial_name": "bur", "identifiers": [ { "authority": "NEMOREFERENCE", "id": "BE0472107512" }, { "authority": "COMPANYREGISTRATIONNUMBER", "id": "0472107512" }, { "authority": "VATIDENTIFICATIONNUMBER", "id": "BE0472107512" }, { "authority": "DSREFERENCE", "id": "0034E00000ipGvNQAU" }, { "authority": "NEMOTECHNICALID", "id": "32927" }, { "authority": "CUSTOMERCODEREFERENCE", "id": "224941" } ], "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "57443" }, "vip": "false", "structure": { "legal_site": { "name": "BURTON ET ALAIME", "identifiers": [ { "authority": "DSREFERENCE", "id": "0034E00000ipGvNQAU" }, { "authority": "NEMOREFERENCE", "id": "126777" } ], "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "41258" }, "address": { "country": { "code": "BEL", "culture": "en-GB", "group": "Country", "site_term_type": "None", "value": "Belgium" }, "street": "Rue Fernand Marchand 30", "street2": "", "street3": "null", "building_number": "", "additional_info1": "null", "additional_info2": "null", "postal_box": "", "municipality": "null", "town": "FLAWINNE", "zip_code": "5020 ", "district": "null", "phone_number": "987", "fax_number": "", "url": "", "email": "fd@fd.df" } }, "internal_transfer_activated": "true", "invoicing_sites": [ { "name": "BURTON ET ALAIME", "identifiers": [ { "authority": "DSREFERENCE", "id": "0014E00000sYjTzQAK" }, { "authority": "NEMOREFERENCE", "id": "1617578" }, { "authority": "ACCOUNTINGREFERENCE", "id": "0258374001" } ], "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "5175443" }, "address": { "country": { "code": "BEL", "culture": "en-GB", "group": "Country", "site_term_type": "None", "value": "Belgium" }, "street": "Rue Fernand Marchand 30", "street2": "", "street3": "null", "building_number": "", "additional_info1": "null", "additional_info2": "null", "postal_box": "", "municipality": "null", "town": "FLAWINNE", "zip_code": "5020 ", "district": "null", "phone_number": "987", "fax_number": "", "url": "", "email": "fd@fd.df" }, "legal_site_identifier": { "authority": "NEMOREFERENCE", "id": "1617577" }, "bank_account": { "reference": "27943", "bank_name": "BE96000535178605", "iban": "BE96000535178605", "bic": "BPOTBEB1" } } ], "delivery_sites": [ { "name": "BURTON ET ALAIME", "identifiers": [ { "authority": "DSREFERENCE", "id": "0014E00000sYjTzQAK" }, { "authority": "NEMOREFERENCE", "id": "1765779" } ], "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "57553" }, "address": { "country": { "code": "BEL", "culture": "en-GB", "group": "Country", "site_term_type": "None", "value": "Belgium" }, "street": "Rue Fernand Marchand 30", "street2": "", "street3": "null", "building_number": "", "additional_info1": "null", "additional_info2": "null", "postal_box": "", "municipality": "null", "town": "FLAWINNE", "zip_code": "5020 ", "district": "null", "phone_number": "987", "fax_number": "", "url": "", "email": "fd@fd.df" }, "invoicing_site_identifier": { "authority": "NEMOREFERENCE", "id": "14564778" } } ], "distribution_points": [ { "name": "BURTON ET ALAIME", "identifiers": [ { "authority": "DSREFERENCE", "id": "0014E00000sYjTzQAK" }, { "authority": "NEMOREFERENCE", "id": "165780" } ], "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "5774543" }, "address": { "country": { "code": "BEL", "culture": "en-GB", "group": "Country", "site_term_type": "None", "value": "Belgium" }, "street": "Rue Fernand Marchand 30", "street2": "", "street3": "null", "building_number": "", "additional_info1": "null", "additional_info2": "null", "postal_box": "", "municipality": "null", "town": "FLAWINNE", "zip_code": "5020 ", "district": "null", "phone_number": "94887", "fax_number": "", "url": "", "email": "fd@fd.df" }, "delivery_site_identifier": { "authority": "NEMOREFERENCE", "id": "1674479" } } ] }, "nb_of_beneficiaries": "0" } }';
        //Test.setMock(HttpCalloutMock.class, new BE_EDGMock(response));

        BE_General_Conditions_Aura_Controller.submitAgreedToGeneralConditions (true,true,oppo.Id,acc.Id,'Customer','TCE','test@gmail.com','fr_BE', '');

        oppo = [SELECT ID, StageName, Name,BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,ER_PaymentMethod__c
        FROM Opportunity WHERE StageName = 'StageName' LIMIT 1];
        Datetime dT = oppo.BE_Date_Time_accepted_general_conditions__c;

        //System.assertEquals('Closed Won', oppo.StageName);
        //System.assertEquals('Prepayment',oppo.BE_Payment_Method__c);
        Test.stopTest();
    }

    @isTest static void TEST_submitAgreedToGeneralCondition2(){
        String mockResponseBody = '{"token_type":"Bearer","expires_in":"3599","ext_expires_in":"3599","expires_on":"1731935419","not_before":"1731931519","resource":"7f73991c-df92-4a33-9668-81e58b5ebfe7","access_token":"test"}';
        HTTPCalloutServiceMock testMock = new HTTPCalloutServiceMock(200, mockResponseBody);
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, testMock);
        oppo = [SELECT ID, StageName, Name,BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,ER_PaymentMethod__c
        FROM Opportunity WHERE StageName = 'StageName' LIMIT 1];
        Account acc =  [SELECT ID FROM ACCOUNT WHERE NAME='Test 2'];
        Test.startTest();

        String response = '{ "meta": { "culture": "en-GB", "status": "Success", "messages": [] }, "data": { "legal_name": "BELGIUM BUSINESS CONSULTING", "commercial_name": "BBC", "identifiers": [ { "authority": "NEMOREFERENCE", "id": "BE0415536815" }, { "authority": "COMPANYREGISTRATIONNUMBER", "id": "0415536815" }, { "authority": "VATIDENTIFICATIONNUMBER", "id": "BE0415536815" }, { "authority": "DSREFERENCE", "id": "0011x000002NCbwAAG" }, { "authority": "NEMOTECHNICALID", "id": "4617" }, { "authority": "AFFILIATECODEREFERENCE", "id": "1021016" } ], "nature": { "code": "Branch", "culture": "", "group": "StakeholderNature", "site_term_type": "None", "value": "[StakeholderNature]" }, "vat_type": { "code": "0", "culture": "", "group": "VatType", "site_term_type": "None", "value": "[VatType]" }, "activity_sector": { "code": "1", "culture": "", "group": "OwnerShip", "site_term_type": "None", "value": "[OwnerShip]" }, "default_language": { "code": "NL", "culture": "", "group": "Language", "site_term_type": "None", "value": "[Language]" }, "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "6954" }, "status": { "code": "2", "culture": "", "group": "Status", "site_term_type": "None", "value": "[Status]" }, "structure": { "legal_site": { "name": "BELGIUM BUSINESS CONSULTING", "identifiers": [ { "authority": "DSREFERENCE", "id": "0011x000002NCbwAAG" }, { "authority": "NEMOREFERENCE", "id": "19118" } ], "stakeholder_identifier": { "authority": "NEMOREFERENCE", "id": "BE0415536815" }, "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "6954" }, "address": { "country": { "code": "BEL", "culture": "en-GB", "group": "Country", "site_term_type": "None", "value": "Belgium" }, "latitude": "0", "longitude": "0", "street": "Avenue de lHippodrome 208 b.1", "street2": "", "building_number": "", "postal_box": "", "municipality": "", "town": "IXELLES", "zip_code": "1050 ", "district": "" }, "default_language": { "code": "NL", "culture": "", "group": "Language", "site_term_type": "None", "value": "[Language]" } }, "payment_sites": [ { "site_name": "BELGIUM BUSINESS CONSULTING", "identifiers": [ { "authority": "DSREFERENCE", "id": "0011x000002NCbwAAG" }, { "authority": "NEMOREFERENCE", "id": "19119" } ], "stakeholder_identifier": { "authority": "NEMOREFERENCE", "id": "BE0415536815" }, "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "6954" }, "address": { "country": { "code": "BEL", "culture": "en-GB", "group": "Country", "site_term_type": "None", "value": "Belgium" }, "street": "Avenue de lHippodrome 208 b.1", "street2": "", "building_number": "", "postal_box": "", "municipality": "", "town": "IXELLES", "zip_code": "1050 ", "district": "" }, "default_language": { "code": "NL", "culture": "en-GB", "group": "Language", "site_term_type": "None", "value": "Dutch" }, "legal_site_identifier": { "authority": "NEMOREFERENCE", "id": "19118" }, "bank_account": { "reference": "3347", "bank_name": "BE15363144984930", "iban": "BE15363144984930", "bic": "BBRUBEBB" } } ], "outlets": [ { "site_name": "BBC", "identifiers": [ { "authority": "DSREFERENCE", "id": "a091x0000009qu1AAA" }, { "authority": "NEMOREFERENCE", "id": "19120" } ], "stakeholder_identifier": { "authority": "NEMOREFERENCE", "id": "BE0415536815" }, "primary_contact_identifier": { "authority": "NEMOREFERENCE", "id": "6954" }, "address": { "country": { "code": "BEL", "culture": "en-GB", "group": "Country", "site_term_type": "None", "value": "Belgium" }, "latitude": "0", "longitude": "0", "street": "Avenue de lippodrome 208 b.1", "street2": "", "building_number": "", "postal_box": "", "municipality": "", "town": "IXELLES", "zip_code": "1050 ", "district": "" }, "default_language": { "code": "NL", "culture": "en-GB", "group": "Language", "site_term_type": "None", "value": "Dutch" }, "payment_site_identifier": { "authority": "NEMOREFERENCE", "id": "19119" }, "sector": { "code": "4", "culture": "en-GB", "group": "Sector", "site_term_type": "None", "value": "[Sector]" }, "subsector": { "code": "1", "culture": "en-GB", "group": "SubSector", "site_term_type": "None", "value": "[SubSector]" }, "activity": { "code": "43", "culture": "en-GB", "group": "Activity", "site_term_type": "None", "value": "[Activity]" }, "acceptance_points": [ { "stakeholder_identifier": { "authority": "NEMOREFERENCE", "id": "BE0415536815" }, "identifiers": [ { "authority": "NEMOREFERENCE", "id": "01237548" }, { "authority": "SVPMIDAUTH", "id": "19120" }, { "authority": "SVPACQIDAUTH", "id": "00006201" }, { "authority": "SVPMIDCLEAR", "id": "19120" }, { "authority": "SVPACQIDCLEAR", "id": "00006201" } ], "terminal": { "identifiers": [ { "authority": "NEMOREFERENCE", "id": "01237548" }, { "authority": "OPERATORREFERENCE", "id": "01237548" } ], "name": "TN01237548", "manager": { "code": "23", "culture": "", "group": "TerminalModel", "site_term_type": "None", "value": "Edenred - Test" }, "category": { "code": "1", "culture": "", "group": "TerminalCategory", "site_term_type": "None", "value": "C-TAP" }, "acquirer_identifier": { "authority": "NEMOREFERENCE", "id": "00006201" } }, "requested_activation_date": "2018-10-18T00:00:00", "status": { "code": "51", "culture": "", "group": "Status", "site_term_type": "None", "value": "[Status]" }, "scheme": { "code": "CTAP_BELGIUM", "culture": "", "group": "Scheme", "site_term_type": "None", "value": "C-TAP" }, "type": { "code": "Bank", "culture": "", "group": "AcceptancePoint", "site_term_type": "None", "value": "[AcceptancePoint]" } } ] } ] } } }';
        //Test.setMock(HttpCalloutMock.class, new BE_EDGMock(response));

        BE_General_Conditions_Aura_Controller.submitAgreedToGeneralConditions (true,true,oppo.Id,acc.Id,'Customer','TCE','test@gmail.com','fr_BE', '');


        oppo = [SELECT ID, StageName, Name,BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,ER_PaymentMethod__c
        FROM Opportunity WHERE StageName = 'StageName' LIMIT 1];
        Datetime dT = oppo.BE_Date_Time_accepted_general_conditions__c;
        String quoteId = BE_General_Conditions_Aura_Controller.createQuote(oppo.Id);
        BE_General_Conditions_Aura_Controller.createContract(quoteId);
        BE_General_Cond_Without_Sharing_Ctrl.isOfferLight('TEST',oppo.Id);
        //System.assertEquals('Closed Won', oppo.StageName);
        //System.assertEquals('Prepayment', oppo.BE_Payment_Method__c);
        Test.stopTest();
    }


    @isTest static void TEST_TRE_Email_Contracts_Sending(){
        oppo = [SELECT ID, AccountId,Name,BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,ER_PaymentMethod__c
        FROM Opportunity LIMIT 1];
        Test.startTest();

        //BE_General_Conditions_Controller.sendContractViaEmail(acc.Id,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.MERCHANT_STAKEHOLDER, 'TRE', null, 'fr_BE');
        BE_General_Conditions_Controller.sendContractViaEmail(oppo.Id, oppo.AccountId,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.CUSTOMER_STAKEHOLDER, 'TRE', null, 'fr_BE');
        //BE_General_Conditions_Controller.sendContractViaEmail(acc.Id,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.MERCHANT_STAKEHOLDER, 'TRE', null, 'nl_BE');
        BE_General_Conditions_Controller.sendContractViaEmail(oppo.Id, oppo.AccountId,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.CUSTOMER_STAKEHOLDER, 'TRE', null, 'nl_BE');

        Test.stopTest();
    }

    @isTest static void TEST_TCE_Email_Contracts_Sending(){
        oppo = [SELECT ID, AccountId,Name,BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,ER_PaymentMethod__c
        FROM Opportunity LIMIT 1];
        Test.startTest();

        //BE_General_Conditions_Controller.sendContractViaEmail(acc.Id,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.MERCHANT_STAKEHOLDER, 'TCE', null, 'fr_BE');
        BE_General_Conditions_Controller.sendContractViaEmail(oppo.Id, oppo.AccountId,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.CUSTOMER_STAKEHOLDER, 'TCE', null, 'fr_BE');
        //BE_General_Conditions_Controller.sendContractViaEmail(acc.Id,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.MERCHANT_STAKEHOLDER, 'TCE', null, 'nl_BE');
        BE_General_Conditions_Controller.sendContractViaEmail(oppo.Id, oppo.AccountId,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.CUSTOMER_STAKEHOLDER, 'TCE', null, 'nl_BE');
        Test.stopTest();
    }

    @isTest static void TEST_ECE_Email_Contracts_Sending(){
        oppo = [SELECT ID, AccountId,Name,BE_Date_Time_accepted_general_conditions__c,BE_Accepted_general_conditions__c,ER_PaymentMethod__c
        FROM Opportunity LIMIT 1];
        Test.startTest();

        //BE_General_Conditions_Controller.sendContractViaEmail(acc.Id,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.MERCHANT_STAKEHOLDER, 'ECE', null, 'fr_BE');
        BE_General_Conditions_Controller.sendContractViaEmail(oppo.Id, oppo.AccountId,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.CUSTOMER_STAKEHOLDER, 'ECE', null, 'fr_BE');
        //BE_General_Conditions_Controller.sendContractViaEmail(acc.Id,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.MERCHANT_STAKEHOLDER, 'ECE', null, 'nl_BE');
        BE_General_Conditions_Controller.sendContractViaEmail(oppo.Id, oppo.AccountId,'test@gmail.com', oppo.Id, BE_ContractEmailGenerator.CUSTOMER_STAKEHOLDER, 'ECE', null, 'nl_BE');

        Test.stopTest();
    }
}