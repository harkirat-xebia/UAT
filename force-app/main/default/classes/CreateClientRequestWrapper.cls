public class CreateClientRequestWrapper {
    public String crm_id { get; set; }
    public String name { get; set; }
    public String legal_name { get; set; }
    public String company_registration_number { get; set; }
    public String vat_number { get; set; }
    public String vat_type { get; set; }
    public String last_modification_date { get; set; }
    public String engagement_platform_id { get; set; }
    //public List<ContractWrapper> contracts { get; set; }
    public List<Object> contracts { get; set; }
    public LegalSiteWrapper legal_site { get; set; }
    public List<ContactWrapper> contacts { get; set; }

    public class ContractWrapper {
        public String crm_id { get; set; }
        public String name { get; set; }
        public String start_date { get; set; }
        public String signed_date { get; set; }
        public String program_name { get; set; }
        public String customer_domain { get; set; }
        public String delivery_type { get; set; }
        public String customer_management { get; set; }

        //New Fields
        public String end_date { get; set; }
        public String payment_method { get; set; }
        public String payment_deadline { get; set; }
        public String crediting_delay { get; set; }
        //Ends

        public String invoicing_contact_id { get; set; }
        public String invoicing_frequency { get; set; }
        public String selection_method { get; set; }
        public String contact_counterparty_signed_id { get; set; }
        public String last_modification_date { get; set; }
        public List<ContractProductWrapper> contract_products { get; set; }
        //public List<Object> services { get; set; }
        public List<ServiceWrapper> services { get; set; }

    }
    
    public class ContractProductWrapper {
        public String start_date { get; set; }
        public String signed_date { get; set; }
        public String order_contact_id { get; set; }
        public Decimal licenses { get; set; }
        public String product { get; set; }
        public String promo_code { get; set; }
        public List<Object> services { get; set; }
    }
    
    public class ServiceWrapper {
        public String code { get; set; }
        public Decimal percentage { get; set; }
        public Decimal quantity { get; set; }
        public Decimal amount { get; set; }
        public Decimal minimum_fee { get; set; }
        public Decimal discount { get; set; }
        public Decimal licenses { get; set; }
        public Decimal sales_price { get; set; }
        public Decimal standard_price { get; set; }
        public String solution { get; set; }
        public String fee_type { get; set; }
        public String product_type { get; set; }
        public String last_modification_date { get; set; }
    }
    
    public class LegalSiteWrapper {
        public String contact_id { get; set; }
        public String language_code { get; set; }
        public AddressWrapper address { get; set; }
        public List<FinancialCenterWrapper> financial_centers { get; set; }
    }
    
    public class FinancialCenterWrapper {
        public String crm_id { get; set; }
        public String name { get; set; }
        public String contact_id { get; set; }
        public String language_code { get; set; }
        public String last_modification_date { get; set; }
        public AddressWrapper address { get; set; }
        public BankAccountWrapper bank_account { get; set; }
        public List<DeliverySiteWrapper> delivery_sites { get; set; }
    }
    
    public class AddressWrapper {
        public String street { get; set; }
        public String street_number { get; set; }
        public String po_box { get; set; }
        public String zip_code { get; set; }
        public String city { get; set; }
        public String country_code { get; set; }
    }
    
    public class BankAccountWrapper {
        public String iban { get; set; }
        public String bic { get; set; }
    }
    
    public class DeliverySiteWrapper {
        public String crm_id { get; set; }
        public String name { get; set; }
        public String contact_id { get; set; }
        public String language_code { get; set; }
        public String last_modification_date { get; set; }
        public AddressWrapper address { get; set; }
        public List<DistributionPointWrapper> distribution_points { get; set; }
    }
    
    public class DistributionPointWrapper {
        public String crm_id { get; set; }
        public String name { get; set; }
        public String contact_id { get; set; }
        public String language_code { get; set; }
        public String last_modification_date { get; set; }
        public AddressWrapper address { get; set; }
    }
    
    public class ContactWrapper {
        public String crm_id { get; set; }
        public String first_name { get; set; }
        public String last_name { get; set; }
        public String language { get; set; }
        public String email { get; set; }
        public String phone_number { get; set; }
        public String mobile_number { get; set; }
        public String last_modification_date { get; set; }
    }
}