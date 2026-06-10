@IsTest
public class WSHU04_ContractTemplateWS_Test {
    @IsTest
    static void test_sContract() {
        // Setup test data using APER07_UtilityTestMethod
        Account acc = APER07_UtilityTestMethod.getCompany('Test Account');
        Pricebook2 pb = APER07_UtilityTestMethod.getPricebook();
        Contract contract = APER07_UtilityTestMethod.getContract(acc.Id, Date.today(), 'Draft', pb.Id);
		Product2 product = new Product2(Name = 'Edenred Meal', ER_Type__c = 'Solution', IsActive = true);
        PricebookEntry pbe = new PriceBookEntry(
                          Pricebook2Id = pb.Id,
                          Product2Id = product.Id,
                          UnitPrice = 1,
                          //ER_Percentage__c = 1,
                          IsActive = true,
                          ER_ValueType__c = Label.LABS_SF_Opp_Product_Currency
                        );
        // Create Contract Line Items
        Map<String, List<ER_ContractLineItem__c>> contractLineItemMap = new Map<String, List<ER_ContractLineItem__c>>();
        ER_ContractLineItem__c cli1 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product.Id, pbe.Id, 1, 0 );
        ER_ContractLineItem__c cli2 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product.Id, pbe.Id, 1, 2 );
        List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
        cliList.add(cli1);
        cliList.add(cli2);
        contractLineItemMap.put('Solution1', cliList);

        // Test sContract constructor
        //WSHU04_ContractTemplateWS.sContract contractObj = new WSHU04_ContractTemplateWS.sContract(contract, contractLineItemMap, false);
    }

    @IsTest
    static void test_Ref() {
        // Test Ref constructor
        WSHU04_ContractTemplateWS.Ref refObj = new WSHU04_ContractTemplateWS.Ref('Test Authority', 'Test Reference');
    }

    @IsTest
    static void test_Address() {
        // Test Address constructor
        //WSHU04_ContractTemplateWS.Address addressObj = new WSHU04_ContractTemplateWS.Address('Building 101', 'Main Street', 'Apt 202', 'CityTest', '12345', 'null', 'null', 'null', 'BE', 'null', 48.819947, 2.309554);
    }

    @IsTest
    static void test_Personal_info() {
        // Test Personal_info constructor
        WSHU04_ContractTemplateWS.Personal_info personalInfoObj = new WSHU04_ContractTemplateWS.Personal_info('John', 'Doe', 'Mr', 'Street1', 'City1', '11111');
    }

    @IsTest
    static void test_ContractProduct() {
        Account acc = APER07_UtilityTestMethod.getCompany('Test Account');
        Pricebook2 pb = APER07_UtilityTestMethod.getPricebook();
        Contract contract = APER07_UtilityTestMethod.getContract(acc.Id, Date.today(), 'Draft', pb.Id);
		Product2 product = new Product2(Name = 'Edenred Meal', ER_Type__c = 'Solution', IsActive = true, ProductCode = 'ERHU');
        Product2 product2 = new Product2(Name = 'Edenred Meal', ER_Type__c = 'Solution', IsActive = true, ProductCode = 'FixedFee');
        PricebookEntry pbe = new PriceBookEntry(
                          Pricebook2Id = pb.Id,
                          Product2Id = product.Id,
                          UnitPrice = 1,
                          //ER_Percentage__c = 1,
                          IsActive = true,
                          ER_ValueType__c = Label.LABS_SF_Opp_Product_Currency
                        );
        // Create Contract Line Items
        Map<String, List<ER_ContractLineItem__c>> contractLineItemMap = new Map<String, List<ER_ContractLineItem__c>>();
        ER_ContractLineItem__c cli1 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product.Id, pbe.Id, 1, 0 );
        ER_ContractLineItem__c cli2 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product2.Id, pbe.Id, 1, 2 );
        List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
        cliList.add(cli1);
        cliList.add(cli2);
        contractLineItemMap.put('Solution1', cliList);

        // Test ContractProduct constructor
        //WSHU04_ContractTemplateWS.ContractProduct contractProductObj = new WSHU04_ContractTemplateWS.ContractProduct('Solution1', cliList);
    }

    @IsTest
    static void test_Signatory_info() {
        // Setup test data
        Account acc = APER07_UtilityTestMethod.getCompany('Test Account');
        Pricebook2 pb = APER07_UtilityTestMethod.getPricebook();
        Contract contract = APER07_UtilityTestMethod.getContract(acc.Id, Date.today(), 'Draft', pb.Id);

        // Test Signatory_info constructor
        WSHU04_ContractTemplateWS.Signatory_info signatoryInfoObj = new WSHU04_ContractTemplateWS.Signatory_info(contract);
    }

    @IsTest
    static void test_Company_signatory() {
        // Test Company_signatory constructor
        WSHU04_ContractTemplateWS.Company_signatory companySignatoryObj = new WSHU04_ContractTemplateWS.Company_signatory(
            'John', 'Doe', 'Mr', 'primary contact', '1234567890', 'john.doe@example.com', '1234567890', '9876543210', '123 Main St', 'CityTest', '54321');
    }

    @IsTest
    static void test_Er_signatory() {
        // Test Er_signatory constructor
        WSHU04_ContractTemplateWS.Er_signatory erSignatoryObj = new WSHU04_ContractTemplateWS.Er_signatory('test@example.com');
    }

    @IsTest
    static void test_reimbursement_service() {
        // Setup test data
        Account acc = APER07_UtilityTestMethod.getCompany('Test Account');
        Pricebook2 pb = APER07_UtilityTestMethod.getPricebook();
        Contract contract = APER07_UtilityTestMethod.getContract(acc.Id, Date.today(), 'Draft', pb.Id);

        // Test reimbursement_service constructor
        WSHU04_ContractTemplateWS.reimbursement_service reimbursementServiceObj = new WSHU04_ContractTemplateWS.reimbursement_service(contract);
    }

    @IsTest
    static void test_Applicable_service() {
        // Setup test data
       Account acc = APER07_UtilityTestMethod.getCompany('Test Account');
        Pricebook2 pb = APER07_UtilityTestMethod.getPricebook();
        Contract contract = APER07_UtilityTestMethod.getContract(acc.Id, Date.today(), 'Draft', pb.Id);

        // Create Contract Line Items
        Product2 product = new Product2(Name = 'Edenred Meal', ER_Type__c = 'Solution', IsActive = true);
        PricebookEntry pbe = new PriceBookEntry(
                          Pricebook2Id = pb.Id,
                          Product2Id = product.Id,
                          UnitPrice = 1,
                          //ER_Percentage__c = 1,
                          IsActive = true,
                          ER_ValueType__c = Label.LABS_SF_Opp_Product_Currency
                        );
        // Create Contract Line Items
        Map<String, List<ER_ContractLineItem__c>> contractLineItemMap = new Map<String, List<ER_ContractLineItem__c>>();
        ER_ContractLineItem__c cli1 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product.Id, pbe.Id, 1, 0 );
        ER_ContractLineItem__c cli2 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product.Id, pbe.Id, 1, 2 );
        List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
        cliList.add(cli1);
        cliList.add(cli2);
        contractLineItemMap.put('Solution1', cliList);

        // Test Applicable_service constructor
        WSHU04_ContractTemplateWS.Applicable_service applicableServiceObj = new WSHU04_ContractTemplateWS.Applicable_service(cli1);
    }

    @IsTest
    static void test_Invoicing_service() {
        // Setup test data
        Account acc = APER07_UtilityTestMethod.getCompany('Test Account');
        Pricebook2 pb = APER07_UtilityTestMethod.getPricebook();
        Contract contract = APER07_UtilityTestMethod.getContract(acc.Id, Date.today(), 'Draft', pb.Id);
		Product2 product = new Product2(Name = 'Edenred Meal', ER_Type__c = 'Solution', IsActive = true);
        PricebookEntry pbe = new PriceBookEntry(
                          Pricebook2Id = pb.Id,
                          Product2Id = product.Id,
                          UnitPrice = 1,
                          //ER_Percentage__c = 1,
                          IsActive = true,
                          ER_ValueType__c = Label.LABS_SF_Opp_Product_Currency
                        );
        // Create Contract Line Items
        Map<String, List<ER_ContractLineItem__c>> contractLineItemMap = new Map<String, List<ER_ContractLineItem__c>>();
        ER_ContractLineItem__c cli1 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product.Id, pbe.Id, 1, 0 );
        ER_ContractLineItem__c cli2 = APER07_UtilityTestMethod.getContractLineItem(contract.Id, product.Id, pbe.Id, 1, 2 );
        List<ER_ContractLineItem__c> cliList = new List<ER_ContractLineItem__c>();
        cliList.add(cli1);
        cliList.add(cli2);
        contractLineItemMap.put('Solution1', cliList);

        // Test Invoicing_service constructor
        WSHU04_ContractTemplateWS.Invoicing_service invoicingServiceObj = new WSHU04_ContractTemplateWS.Invoicing_service(cli1, true);
    }
}