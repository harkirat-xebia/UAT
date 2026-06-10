public class CreateClientContractRequestWrapper {
    public Client client { get; set; }
    public List<Contract> contracts { get; set; }
    public List<Contact> contacts { get; set; }

    public class Client {
        public String crm_id { get; set; }
        public String card_id { get; set; }
        public String company_registration_number { get; set; }
        public String last_modification_date { get; set; }
        //Addding new
        public LegalSite legal_site { get; set; }
    }

    //New
    public class LegalSite {
        public List<FinancialCenter> financial_centers { get; set; }
    }

    // NEW
    public class FinancialCenter {
        public String crm_id { get; set; }
        public String name { get; set; }
        public BankAccount bank_account { get; set; }
    }

    // NEW
    public class BankAccount {
        public String iban { get; set; }
        public String bic { get; set; }
    }

    public class Contract {
        public String crm_id { get; set; }
        public String name { get; set; }
        public String start_date { get; set; }
        public String end_date { get; set; }
        public String contact_counterparty_signed_id { get; set; }
        //public String end_reason { get; set; }
        //Uncommenting
        public String program_name { get; set; }
        public String customer_domain { get; set; }
        public String customer_management { get; set; }
        public String selection_method { get; set; }
        //commenting ends
        public String signed_date { get; set; }
        public String delivery_type { get; set; }
        public String invoicing_contact_id { get; set; }
        public String invoicing_frequency { get; set; }
        public String last_modification_date { get; set; }
        //Added New
        public String payment_method { get; set; }
        public String payment_deadline { get; set; }
        public String crediting_delay { get; set; }
        //Added new ends
        public List<ContractProduct> contract_products { get; set; }
    }

    public class ContractProduct {
        public String start_date { get; set; }
        public String end_date { get; set; }
        //public String end_reason { get; set; }
        public String signed_date { get; set; }
        public String order_contact_id { get; set; }
        public String product { get; set; }
        public String promo_code { get; set; }
        //public Decimal licenses { get; set; }
        public List<Service> services { get; set; }
    }

    public class Service {
        public String code { get; set; }
        public Decimal percentage { get; set; }
        public Decimal quantity { get; set; }
        public Decimal amount { get; set; }
        public Decimal minimum_fee { get; set; }
        public Decimal discount { get; set; }
        //public Decimal licenses { get; set; }
        public Decimal sales_price { get; set; }
        public Decimal standard_price { get; set; }
        public String solution { get; set; }
        //public String product_type { get; set; }
        //public String fee_type { get; set; } 
        public String last_modification_date { get; set; }
    }

    public class Contact {
        public String crm_id { get; set; }
        public String first_name { get; set; }
        public String last_name { get; set; }
        public String language { get; set; }
        public String email { get; set; }
        public String phone_number { get; set; }
        //Adding mobile number
        public String mobile_number { get; set; }
        public String last_modification_date { get; set; }
    }
}