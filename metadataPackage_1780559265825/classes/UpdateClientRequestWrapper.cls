public class UpdateClientRequestWrapper {
    public String crm_id { get; set; }
    public String card_id { get; set; }
    public String name { get; set; }
    public String legal_name { get; set; }
    public String company_registration_number { get; set; }
    public String vat_number { get; set; }
    public String vat_type { get; set; }
    public String last_modification_date { get; set; }
    public LegalSite legal_site { get; set; }
    public List<Contact> contacts { get; set; }

    // Wrapper class for Legal Site details
    public class LegalSite {
        public String contact_id { get; set; }
        public Address address { get; set; }
    }

    // Wrapper class for Address inside Legal Site
    public class Address {
        public String street { get; set; }
        public String street_number { get; set; }
        public String po_box { get; set; }
        public String zip_code { get; set; }
        public String city { get; set; }
        public String country_code { get; set; }
        public String last_modification_date { get; set; }
    }

    // Wrapper class for Contact details
    public class Contact {
        public String crm_id { get; set; }
        public String card_id { get; set; }
        public String first_name { get; set; }
        public String last_name { get; set; }
        public String language { get; set; }
        public String email { get; set; }
        public String phone_number { get; set; }
        public String last_modification_date { get; set; }
    }
}