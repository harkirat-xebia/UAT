public class WSHU04_ContractTemplateWS {
  /*
    ----------------------------------------------------------------------
    -- - Name          : WSHU04_ContractTemplateWS
    -- - Author        : OLA
    -- - Description   : Define the Contract Template for the web service  (Request + response)
    -- Maintenance History:
    --
    -- Date         Name               Version     Remarks
    -- -----------  -----------        --------    ---------------------------------------
    -- 25-FEB-2019  OLA                    1.0     Initial version

    ---------------------------------------------------------------------------------------
    */

  public class sContract {
    public List<Ref> refs { get; set; }

    public String start_date { get; set; }
    public String end_date { get; set; }
    public String status { get; set; }
    public String version { get; set; }
    public Boolean is_vip { get; set; }
    public String description { get; set; }
    public List<ContractProduct> contractProducts { get; set; }
    public Signatory_info signatory_info { get; set; }

    // Constructor from Account object to JSON
    public sContract(
      Contract contractInst,
      Map<String, List<ER_ContractLineItem__c>> contractLineItemMap,
      Boolean isUpdate
    ) {
      this.refs = new List<Ref>();
      //this.refs.add(new Ref('mdm.contractmerchant.technical_id', '25'));
      this.refs.add(new Ref('ds.contractmerchant.technical_id', contractInst.id));
      Datetime contractStartDate = contractInst.StartDate;
      Datetime contractEndDate = contractInst.EndDate;

      if (contractStartDate != null) {
        this.start_date = contractStartDate.format('yyyy-MM-dd');
      } else {
        this.start_date = Datetime.now().format('yyyy-MM-dd');
      }

      if (contractEndDate != null) {
        this.end_date = contractEndDate.format('yyyy-MM-dd');
      }

      this.status = 'active';
      /*this.version = '1.0';
       this.description = 'Contract merchant n°1';*/
      this.contractProducts = new List<ContractProduct>();

      for (String solution : contractLineItemMap.keyset()) {
        //if(contractLineItemMap.get(solution)[0].ER_Creation_date_in_OS__c == null || isUpdate){

        this.contractProducts.add(new ContractProduct(solution, contractLineItemMap.get(solution)));
        //}
      }

      this.signatory_info = new Signatory_info(contractInst);
      this.is_vip = contractInst.Account.ER_VIP__c;
    }
  }

  public class Ref {
    public String authority { get; set; }
    public String reference { get; set; }

    public Ref(String auth, String ref) {
      this.authority = auth;
      this.reference = ref;
    }
  }

  public class Address {
    public String building_number { get; set; }
    public String street { get; set; }
    public String street2 { get; set; }
    public String city { get; set; }
    public String zip_code { get; set; }
    public String postal_box { get; set; }
    public String district_code { get; set; }
    public String municipality { get; set; }
    public String country_ref { get; set; }
    public String additional_info { get; set; }
    public Double latitude { get; set; }
    public Double longitude { get; set; }

    public Address(
      String thebuilding_number,
      String thestreet,
      String thestreet2,
      String thecity,
      String thezip_code,
      String thepostal_box,
      String thedistrict_code,
      String themunicipality,
      String thecountry_ref,
      String theadditional_info,
      Double thelatitude,
      Double thelongitude
    ) {
      this.street = (thestreet != null) ? thestreet : '';
      this.city = (String.isNotBlank(thecity) != null) ? thecity : '';
      this.zip_code = (String.isNotBlank(thezip_code) != null) ? thezip_code : ''; /* Is limited to 10 characters */
      this.country_ref = (String.isNotBlank(thecountry_ref) != null) ? thecountry_ref : '';
    }
  }

  public class Personal_info {
    public String first_name { get; set; }
    public String middle_name { get; set; }
    public String last_name { get; set; }
    public String birth_date { get; set; }
    public String birth_place { get; set; }
    public String title { get; set; }
    public String profession_ref { get; set; }
    public String language_ref { get; set; }
    public Address address { get; set; }

    public Personal_info(
      String firstName,
      String lastname,
      String salutation,
      String mailingStreet,
      String mailingCity,
      String mailingPostCode
    ) {
      this.first_name = (firstName != null) ? firstName : 'firstnameismissing'; /* Contact Name -- optional */

      this.last_name = (lastname != null) ? lastname : 'lastnameismissing'; /* Contact Name -- required */

      /* Possible values : mr/ms/mrs/dr/prof */
      this.title = (!String.isEmpty(salutation))
        ? (salutation.removeEndIgnoreCase('.')).toLowerCase()
        : 'mr'; /* Title -- required */

      if (this.title == 'prof') {
        this.title = 'pr';
      }
      this.language_ref = 'HUN'; /* default value */

      if (mailingStreet != null && mailingCity != null && mailingPostCode != null) {
        this.address = new Address(
          '',
          mailingStreet,
          '',
          mailingCity,
          mailingPostCode,
          '',
          '',
          '',
          'HU',
          '',
          double.valueOf('48.819947'),
          double.valueOf('2.309554')
        );
      }
    }
  }

  public class ContractProduct {
    public Product product { get; set; }
    public String status { get; set; }
    public String end_date { get; set; }
    public List<Applicable_service> applicable_services { get; set; }
    public List<Invoicing_service> invoicing_services { get; set; }
    public payment_service payment_service { get; set; }
    public reimbursement_service reimbursement_service { get; set; }

    public ContractProduct(String solution, List<ER_ContractLineItem__c> cliList) {
      Invoicing_service invoicing_service;
      Boolean invoicingDone = false;
      Datetime contractEndDate;
      //this.product = new Product('er.product.ref', 'T prod Multi Wallet');
      this.product = new Product('er.product.ref', solution);
      this.applicable_services = new List<Applicable_service>();
      this.invoicing_services = new List<Invoicing_service>();
      this.status = 'active';

      for (ER_ContractLineItem__c cli : cliList) {
        if (cli.ER_end_Date__c != null && contractEndDate == null) {
          contractEndDate = cli.ER_end_Date__c;
          this.end_date = contractEndDate.format('yyyy-MM-dd');
        }
        //if (!cli.ER_product2__r.ER_Do_Not_Synchronize__c) {

        if (String.isNotBlank(cli.ER_ProductCode__c)) {
          if (
            cli.ER_ProductCode__c.containsIgnoreCase('ERHU') &&
            (cli.ER_ProductCode__c.containsIgnoreCase('LowInvoice') ||
            cli.ER_ProductCode__c.containsIgnoreCase('FixedFee'))
          ) {
            if (!invoicingDone) {
              cli.ER_UnitPrice__c = 100;
              if (cli.ER_ProductCode__c.containsIgnoreCase('LowInvoice')) {
                invoicingDone = true;
                this.invoicing_services.add(new Invoicing_service(cli, true));
              } else {
                invoicing_service = new Invoicing_service(cli, false);
              }
            }
          } else if (!cli.ER_product2__r.ER_Do_Not_Synchronize__c) {
            this.applicable_services.add(new Applicable_service(cli));
          }
        } else {
          throw new ContractException('No product Code Found for: ' + solution + ' - ' + cli.Name);
        }
        //}
      }
      if (!invoicingDone && invoicing_service != null) {
        this.invoicing_services.add(invoicing_service);
      }
      if (
        cliList[0].ER_Contract__r.ER_PaymentTerms2__c != null &&
        cliList[0].ER_Contract__r.ER_PaymentMethod2__c != null
      ) {
        this.payment_service = new payment_service(cliList[0].ER_Contract__r);
      }
      //ER_ReimbursementTerm2__c
      if (cliList[0].ER_Contract__r.ER_ReimbursementTerm2__c != null) {
        this.reimbursement_service = new reimbursement_service(cliList[0].ER_Contract__r);
      }
    }
  }

  public class Product {
    public String authority { get; set; }
    public String reference { get; set; }
    public String product_ref { get; set; }

    public Product(String authority, String reference) {
      this.authority = authority;
      this.reference = reference;
    }
  }

  public class Signatory_info {
    public String sign_date { get; set; }
    public Er_signatory er_signatory { get; set; }
    public List<Company_signatory> company_signatory { get; set; }

    public Signatory_info(Contract contractInst) {
      this.sign_date = Datetime.now().format('yyyy-MM-dd');
      if (contractInst.CustomerSignedDate != null) {
        this.sign_date = DateTime.newInstance(
            contractInst.CustomerSignedDate.year(),
            contractInst.CustomerSignedDate.month(),
            contractInst.CustomerSignedDate.day()
          )
          .format('yyyy-MM-dd');
      }

      //this.er_signatory = new Er_signatory(contractInst.CustomerSignedId);
      this.company_signatory = new List<Company_signatory>();
      Company_signatory test = new Company_signatory(
        'TEST',
        'TEST',
        'Mr',
        'primary contact',
        '+33 101010101',
        'test@test.com',
        '+33 101010101',
        '+33 606060606',
        'boulevard Gabriel Péri',
        'Malakoff',
        '92240'
      );
      this.company_signatory.add(test);
      if (contractInst.CustomerSigned.email != null) {
        this.er_signatory = new er_signatory(contractInst.CustomerSigned.email);
      }
    }
  }

  public class Company_signatory {
    public List<Ref> refs { get; set; }
    public String name { get; set; }
    public String email { get; set; }
    public String phone_number { get; set; }
    public String mobile_number { get; set; }
    public String fax { get; set; }
    public String website { get; set; }
    public String contact_type_ref { get; set; }
    public String function_ref { get; set; }
    public Personal_info personal_info { get; set; }

    public Company_signatory(
      String contactfirstName,
      String contactLastName,
      String salutation,
      String contactType,
      String faxNumber,
      String emailAdd,
      String phoneNumber,
      String mobileNumber,
      String mailingStreet,
      String mailingCity,
      String mailingPostCode
    ) {
      this.refs = new List<Ref>();
      this.refs.add(new Ref('mdm.contact.technical_id', ''));

      this.personal_info = new Personal_info(
        contactfirstName,
        contactLastName,
        salutation,
        mailingStreet,
        mailingCity,
        mailingPostCode
      );
    }

    public Company_signatory(Contact contactInst) {
      this.refs = new List<Ref>();
      this.refs.add(new Ref('mdm.contact.technical_id', ''));

      if (String.isNotBlank(contactInst.Email)) {
        this.email = contactInst.Email;
      }
      if (String.isNotBlank(contactInst.Phone)) {
        this.phone_number = contactInst.Phone;
      }
      if (String.isNotBlank(contactInst.MobilePhone)) {
        this.mobile_number = contactInst.MobilePhone;
      }
      if (String.isNotBlank(contactInst.Fax)) {
        this.fax = contactInst.Fax;
      }
      //this.website = 'www.edenred.com'; /**/
      //this.contact_type_ref = contactType;
      //this.function_ref = 'Manager';
      //this.name = 'EDG Team'; /* not needed */
      //this.personal_info = new Personal_info(contactfirstName, contactLastName, salutation, mailingStreet, mailingCity, mailingPostCode);
    }
  }

  public class Er_signatory {
    public String login { get; set; }
    public String last_name { get; set; }
    public String first_name { get; set; }

    public Er_signatory(String CustomerSignedEmail) {
      //this.login = 'david.slezek@edenred.com';
      this.login = CustomerSignedEmail;
      /* this.login = '';
            this.last_name = '';
            this.first_name = '';*/
    }
  }

  public class reimbursement_service {
    public String ref { get; set; }
    public String start_date { get; set; }
    public Periodicity periodicity { get; set; }

    public reimbursement_service(Contract contractInst) {
      this.ref = '';
      this.start_date = '2018-01-01'; //KHAD
      if (contractInst.ER_ReimbursementTerm2__c != null) {
        this.periodicity = new periodicity(contractInst.ER_ReimbursementTerm2__c);
      }
    }
  }

  public class Applicable_service {
    public String ref { get; set; }
    public Applicable_fee applicable_fee { get; set; }
    public String selection_mode { get; set; }
    public String start_date { get; set; }
    public String end_date { get; set; }
    public Boolean valued_only_first_invoice { get; set; }
    public Boolean is_service_active { get; set; }
    public String applicable_site_ref { get; set; }
    public Boolean is_fees_increased { get; set; }
    public Periodicity periodicity { get; set; }

    public Applicable_service(ER_ContractLineItem__c cli) {
      //this.ref = 'SRV_TX_PARTICIPATION';
      this.ref = cli.ER_ProductCode__c;
      this.applicable_fee = new Applicable_fee(cli, false);
      this.selection_mode = 'active';

      Datetime contractStartDate = cli.ER_Contract__r.StartDate;
      Datetime contractEndDate = cli.ER_Contract__r.EndDate;

      if (contractStartDate != null) {
        this.start_date = contractStartDate.format('yyyy-MM-dd');
      } else {
        this.start_date = Datetime.now().format('yyyy-MM-dd');
      }

      //this.end_date = '2019-01-01';
      this.valued_only_first_invoice = true;
      this.is_service_active = cli.ER_IsActive__c;

      //this.applicable_site_ref = 'DDE';//KHAD
      this.applicable_site_ref = cli.ER_ProductCode__c; //KHAD
      this.is_fees_increased = cli.ER_Contract__r.ER_OppIndexation2__c;
      if (cli.ER_Contract__r.ER_InvoicingFrequency2__c != null) {
        this.periodicity = new periodicity(cli.ER_Contract__r.ER_InvoicingFrequency2__c);
      }
    }
  }

  public class Invoicing_service {
    public Boolean end_of_period { get; set; }
    public List<String> invoicing_supports { get; set; }
    public String invoicing_layout_ref { get; set; }
    public String product_name_on_invoice { get; set; }

    public String ref { get; set; }
    public Applicable_fee applicable_fee { get; set; }
    public String selection_mode { get; set; }
    public String start_date { get; set; }
    public String end_date { get; set; }
    public Boolean valued_only_first_invoice { get; set; }
    public String applicable_site_ref { get; set; }

    public Periodicity periodicity { get; set; }
    public Boolean automatic_sending { get; set; }

    public Invoicing_service(ER_ContractLineItem__c cli, Boolean isEndOfPeriod) {
      Datetime contractStartDate = cli.ER_Contract__r.StartDate;

      this.invoicing_supports = new List<String>();
      this.invoicing_supports.add('code invoice support');
      this.invoicing_supports.add('code invoice support 2');
      this.invoicing_layout_ref = 'code invoice layout';
      this.product_name_on_invoice = 'product name on invoice';

      this.ref = cli.ER_ProductCode__c;

      this.end_of_period = isEndOfPeriod;

      this.applicable_fee = new Applicable_fee(cli, true);
      this.selection_mode = 'active';

      this.start_date = '2018-01-01';
      if (contractStartDate != null) {
        this.start_date = contractStartDate.format('yyyy-MM-dd');
      }

      //this.end_date = '2019-01-01';
      this.valued_only_first_invoice = true;
      this.applicable_site_ref = 'ZZ5468';

      this.periodicity = new Periodicity();
      this.automatic_sending = true;
    }
  }

  public class Periodicity {
    public String frequency_value { get; set; }
    public String day_of_week { get; set; }
    public String frequency_unit_ref { get; set; }

    public Periodicity() {
      this.frequency_value = '1';
      this.day_of_week = 'monday';
      this.frequency_unit_ref = 'M';
    }
    public Periodicity(String frequency_value) {
      this.frequency_value = frequency_value;
    }
  }

  public class Applicable_fee {
    public Decimal min_value { get; set; }
    public Decimal value { get; set; }
    public String fee_unit_ref { get; set; }
    public List<Fee_range> fee_ranges { get; set; }

    public Applicable_fee(ER_ContractLineItem__c cli, Boolean isInvoice) {
      if (isInvoice) {
        this.min_value = (cli.ER_Percentage__c != null) ? cli.ER_Percentage__c : cli.ER_UnitPrice__c;
      } else {
        //this.min_value = 0;
        this.min_value = (cli.ER_Minimum_Fee__c != null) ? cli.ER_Minimum_Fee__c : 0;
      }
      this.value = 0; //(cli.ER_Percentage__c != null) ? cli.ER_Percentage__c : cli.ER_UnitPrice__c;
      this.fee_unit_ref = (cli.ER_Percentage__c != null) ? '%' : cli.CurrencyIsoCode;
      this.fee_ranges = new List<Fee_range>();
      this.fee_ranges.add(new Fee_range(cli));
    }
  }

  public class Fee_range {
    public Decimal min_volume { get; set; }
    public Decimal max_volume { get; set; }
    public Decimal value { get; set; }

    public Fee_range(ER_ContractLineItem__c cli) {
      this.min_volume = 0;
      this.value = (cli.ER_Percentage__c != null) ? cli.ER_Percentage__c : cli.ER_UnitPrice__c;
    }
  }

  public class payment_service {
    public String payment_term_ref { get; set; }
    public String payment_method_ref { get; set; }
    public String ref { get; set; }
    public String start_date { get; set; }

    public payment_service(Contract contractInst) {
      this.ref = '';
      this.start_date = '2018-01-01'; //KHAD
      system.debug('contractInst.ER_OpportunityId__r.ER_PaymentTerms__c' + contractInst.ER_PaymentTerms2__c);
      this.payment_term_ref = contractInst.ER_PaymentTerms2__c;
      this.payment_method_ref = contractInst.ER_PaymentMethod2__c;
    }
  }

  public class product_contracts {
    public List<product_id> product_contracts { get; set; }

    public product_contracts(Map<String, List<ER_ContractLineItem__c>> contractLineItemMap) {
      system.debug('KHAAAAD 1');
      this.product_contracts = new List<product_id>();
      system.debug('KHAAAAD 2');
      for (String solution : contractLineItemMap.keyset()) {
        this.product_contracts.add(new product_id(contractLineItemMap.get(solution)));
      }
      system.debug('KHAAAAD 3');
    }
  }
  public class product_id {
    public Ref product_id { get; set; }
    //public product_id product_id;

    public product_id(List<ER_ContractLineItem__c> contractLineItem) {
      for (ER_ContractLineItem__c cli : contractLineItem) {
        this.product_id = new Ref('os.product.ref', cli.ER_Solution__c);
        //this.product_id.add( new Ref('os.product.ref', cli.ER_Solution__c));
      }
    }
  }

  public class ContractResponse {
    public Meta meta { get; set; }
    public List<Data> data { get; set; }
  }

  public class Meta {
    public String status;
    public List<Message> messages;
    //public Message message;
  }

  public class Message {
    public String code;
    public String level;
    public String text;
    public String message;
    public String description;
    public String product_ref;
  }

  public class Data {
    public List<ContractsProduct> contractsProducts { get; set; }
  }

  public class ContractsProduct {
    public Ref refs { get; set; }
    public Ref merchant_ref { get; set; }
    public Product product { get; set; }
  }

  public class ContractException extends Exception {
  }
}