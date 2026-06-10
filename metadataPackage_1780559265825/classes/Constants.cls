/**
 * @author : ALK
 * @date : 01/03/2021
 * @desc : Constants
 * @see Constants
 */

 public with sharing class Constants {
  public static final String SEMICOLON = ';';
  public static final String COMMA = ',';
  public static final String POST_METHOD = 'POST';
  public static final String GET_METHOD = 'GET';
  public static final String PUT_METHOD = 'PUT';
  public static final String PATCH_METHOD = 'PATCH';
  public static final String PDF = 'pdf';
  public static final String SLASH = '/';
  public static final String UNDERSCORE = '_';
  public static final String AMPERSAND = '&';
  public static final String QUESTION_MARK = '?';
  public static final String COLON = ':';
  public static final String SMARTER_MS_TOKEN_TYPE = 'token_type';
  public static final String SMARTER_MS_ACCESS_TOKEN = 'access_token';

  public static final String FC_MERCHANT_TYPE = 'Merchant';
  public static final String FC_CLIENT_TYPE = 'Client';
  public static final String SEQUENCE_AFFILIATE = 'AFFILIATE';
  public static final String SEQUENCE_CUSTOMER = 'CUSTOMER';
  public static final String TYPE_STRING = 'String';
  public static final String TYPE_INTEGER = 'Integer';
  public static final String SUCCEEDED = 'Succeeded';

  public static final String STANDARD_PRICE_BOOK = 'Standard Price Book';
  public static final String SOLUTION_BASE_PRODUCTS = 'Base Products';
  public static final String AUTOMATED_PROCESS = 'AutomatedProcess';

  public static final String UNDEFINED = 'undefined';

  //Quotes/Contracts
  public static final String QUOTE_STATUS_SIGNED = 'Signed';
  public static final String QUOTE_STATUS_ACCEPTED = 'Accepted';
  public static final String CONTRACT_STATUS_DRAFT = 'Draft';
  public static final String CONTRACT_TYPE_OPERATIONAL = 'Operational';

  //Currencies
  public static final String CURRENCY_EUR = 'EUR';

  //Syncronization
  public static final String SYNCHRONIZED_STATUS = 'synchronized';
  public static final String NOT_SYNCHRONIZED_STATUS = 'not_synchronized';

  public static final String NAME_OPP_DELIMITER = '-';

  public static Map<String, Map<String, String>> USER_COUNTRY_PARAMS_MAP = new Map<String, Map<String, String>>{
    'HU' => new Map<String, String>{
      'locale' => 'en_GB',
      'language' => 'en_US',
      'timeZone' => 'Europe/London',
      'bu' => 'HU',
      'currency' => 'PLN'
    },
    'UK' => new Map<String, String>{
      'locale' => 'en_GB',
      'language' => 'en_US',
      'timeZone' => 'Europe/London',
      'bu' => 'UK',
      'currency' => 'GBP'
    },
    'BE' => new Map<String, String>{
      'locale' => 'fr_BE',
      'language' => 'fr',
      'timeZone' => 'Europe/Brussels',
      'bu' => 'BE'
    },
    'BENELUX' => new Map<String, String>{
      'locale' => 'fr_BE',
      'language' => 'fr',
      'timeZone' => 'Europe/Brussels',
      'bu' => 'BENELUX'
    },
    'FR' => new Map<String, String>{
      'locale' => 'fr_FR',
      'language' => 'fr',
      'timeZone' => 'Europe/Paris',
      'bu' => 'FR'
    },
    'CH' => new Map<String, String>{
      'locale' => 'fr_CH',
      'language' => 'fr',
      'timeZone' => 'Europe/Brussels',
      'bu' => 'CH',
      'currency' => 'CHF'
    },
    'CA' => new Map<String, String>{
      'locale' => 'en_CA',
      'language' => 'en_US',
      'timeZone' => 'America/New_York',
      'bu' => 'CA',
      'currency' => 'CAD'
    },
    'NL' => new Map<String, String>{
      'locale' => 'nl_NL',
      'language' => 'nl_NL',
      'timeZone' => 'Europe/Brussels',
      'bu' => 'BENELUX'
    },
    'LU' => new Map<String, String>{
      'locale' => 'fr_LU',
      'language' => 'fr',
      'timeZone' => 'Europe/Brussels',
      'bu' => 'BENELUX'
    },
    'SE' => new Map<String, String>{
      'locale' => 'sv_SE',
      'language' => 'sv',
      'timeZone' => 'Europe/Helsinki',
      'bu' => 'SE'
    },
    'DK' => new Map<String, String>{
      'locale' => 'da_DK',
      'language' => 'da',
      'timeZone' => 'Europe/Helsinki',
      'bu' => 'DK'
    },
    'NO' => new Map<String, String>{
      'locale' => 'no_NO',
      'language' => 'no',
      'timeZone' => 'Europe/Helsinki',
      'bu' => 'NO'
    },
    'FI' => new Map<String, String>{
      'locale' => 'fi_FI',
      'language' => 'fi',
      'timeZone' => 'Europe/Helsinki',
      'bu' => 'FI'
    },
    'US' => new Map<String, String>{
      'locale' => 'en_US',
      'language' => 'en_US',
      'timeZone' => 'America/New_York',
      'bu' => 'United States',
      'currency' => 'USD'
    },
    'DE' => new Map<String, String>{
      'locale' => 'de',
      'language' => 'de',
      'timeZone' => 'Europe/Berlin',
      'bu' => 'DE',
      'currency' => 'EUR'
    },
    'PL' => new Map<String, String>{
      'locale' => 'fr_FR_EURO',
      'language' => 'en_US',
      'timeZone' => 'Europe/Paris',
      'bu' => 'PL',
      'currency' => 'EUR'
    },
    'CZ' => new Map<String, String>{
      'locale' => 'cs_CZ',
      'language' => 'cs',
      'timeZone' => 'Europe/Prague',
      'bu' => 'CZ',
      'currency' => 'CZK'
    },
    'SK' => new Map<String, String>{
      'locale' => 'sk_SK',
      'language' => 'en_US',
      'timeZone' => 'Europe/Paris',
      'bu' => 'SK',
      'currency' => 'EUR'
    },
    'RO' => new Map<String, String>{
      'locale' => 'ro_RO',
      'language' => 'en_US',
      'timeZone' => 'Europe/Bucharest',
      'bu' => 'RO',
      'currency' => 'EUR'
    },
    'ES' => new Map<String, String>{
      'locale' => 'es_ES',
      'language' => 'en_US',
      'timeZone' => 'Europe/Paris',
      'bu' => 'ES',
      'currency' => 'EUR'
    },
    'CEN' => new Map<String, String>{
      'locale' => 'fr_FR',
      'language' => 'fr',
      'timeZone' => 'Europe/Paris',
      'bu' => 'CEN'
    },
    'GR' => new Map<String, String>{
      'locale' => 'fr_FR',
      'language' => 'el',
      'timeZone' => 'Europe/Paris',
      'bu' => 'GR'
    }
  };

  //Zuora
  public static final String ZUORA_CLIENTID = 'Zuora_ClientId';
  public static final String ZUORA_CLIENTSECRET = 'Zuora_ClientSecret';
  public static final String ZUORA_ENDPOINT = 'Zuora_Endpoint';
  public static final String ZUORA_ENTITYID = 'Zuora_EntityId_';
  public static final String ZUORA_SEQUENCESET = 'Zuora_SequenceSet_';
  public static final String ZUORA_DEPLOYED_BU = 'ZUORA_DEPLOYED_BUs';
  public static final String ZUORA_COMMUNICATIONPROFILE_ID = 'Zuora_CommunicationProfile_ID_';
  public static final String ZUORA_INVOICETEMPLATE_ID = 'Zuora_InvoiceTemplate_ID_';
  public static final String ZUORA_CREDITMEMOTEMPLATE_ID = 'Zuora_CreditMemoTemplate_ID_';
  public static final String ZUORA_DEBITMEMOTEMPLATE_ID = 'Zuora_DebitMemoTemplate_ID_';
  public static final String ZUORA_FINANCIALCENTER_CHANGEDFIELDS = 'Zuora_FinancialCenter_ChangedFields_';
  public static final String ZUORA_ACCOUNT_CHANGEDFIELDS = 'Zuora_Account_ChangedFields_';
  public static final String ZUORA_CONTACT_CHANGEDFIELDS = 'Zuora_Contact_ChangedFields_';
  public static final String ZUORA_BA_PAYMENTTERM_14 = '14 days after invoice issuance';
  public static final String ZUORA_RESPONSE_ACCESS_TOKEN = 'access_token';
  public static final String ZUORA_RESPONSE_PDF_FILEID = 'latestPDFFileId';
  public static final String ZUORA_LOCK_TIME = 'Zuora_Lock_Time';
  public static final String ZUORA_SF_ENTITYID = 'Zuora_SF_EntityId_';
  public static final String ZUORA_EXEMPT_NOVAT = 'Exempt - NO VAT';
  public static final String PAYMENT_TERM_AT_RECEPTION_OF_INVOICE = 'At reception of invoice';
  public static final String ZUORA_DEFAULT_PAYMENTMETHOD = 'Zuora_Default_PaymentMethod_';
  public static final String ZUORA_DEFAULT_PAYMENTTERM = 'Zuora_Default_PaymentTerm_';
  public static final String ZUORA_PAYMENTMETHOD_OTHER = 'Zuora_PaymentMethod_OTHER_';
  public static final String ZUORA_PAYMENTMETHOD_WIRETRANSFER = 'Zuora_PaymentMethod_WT_';
  public static final String ZUORA_PAYMENTMETHOD_CREDITCARD = 'Zuora_PaymentMethod_CreditCard_';
  public static final String ZUORA_PAYMENTMETHOD_BANKTRANSFER = 'Zuora_PaymentMethod_BT_';
  public static final String ZUORA_ENTITY_NAME = 'Zuora_EntityName_';
  public static final String ZUORA_TERM_TYPE_EVERGREEN = 'Evergreen';
  public static final String ZUORA_NEW_SUBSCRIPTION = 'New Subscription';
  public static final String ZUORA_BILLING_BATCH1 = 'Batch1';
  public static final String ZUORA_BILLING_METHOD_EMAIL = 'Email';
  public static final String ZUORA_INVOICE_PROCESSING_SUBSCRIPTION = 'Subscription';
  public static final String MERCHANT_UNDERSCORE = 'MERCHANT_';
  public static final String CLIENT_UNDERSCORE = 'CLIENT_';

  //Zuora EndPoints
  public static final String ZUORA_ENDPOINT_OAUTH = '/oauth/token';
  public static final String ZUORA_ENDPOINT_ACCOUNT = '/v1/accounts/';
  public static final String ZUORA_ENDPOINT_ACTION_UPDATE = '/v1/action/update';
  //public static final String ZUORA_ENDPOINT_OBJECT_ACCOUNT = '/v1/object/account/';
  public static final String ZUORA_ENDPOINT_ORDERS = '/v1/orders';
  public static final String ZUORA_ENDPOINT_CREDITMEMOS = '/v1/creditmemos/';
  public static final String ZUORA_ENDPOINT_DEBITMEMOS = '/v1/debitmemos/';
  public static final String ZUORA_ENDPOINT_FILES = '/v1/files/';
  public static final String ZUORA_ENDPOINT_RATEPLANS = '/v1/rateplans/';
  public static final String ZUORA_ENDPOINT_ACTION_QUERY = '/v1/action/query';
  public static final String SMARTER_ENDPOINT_XP_OF = 'Smarter_XP_Endpoint_';
  public static final String SMARTER_ENDPOINT_XP_OF_DEFAULT = 'https://dev.smarter.edenred.io/xp-oneforce-api';
  public static final String SMARTER_PUSH_BACK_IDS_SERVICE_NAME = 'push-back-ids';
  public static final String SMARTER_PUSH_BACK_IDS_VERSION = 'v1';
  //public static final String SMARTER_PROFORMA_SERVICE_NAME = 'SMARTER_PROFORMA_SERVICE_NAME';
  public static final String SMARTER_PROFORMA_SERVICE_NAME = 'billing/documents';
  //public static final String SMARTER_PROFORMA_SERVICE_NAME_DEFAULT = 'billing/documents';
  //public static final String SMARTER_PROFORMA_SERVICE_VERSION = 'SMARTER_PROFORMA_SERVICE_VERSION';
  public static final String SMARTER_PROFORMA_SERVICE_VERSION = 'v0';
  //public static final String SMARTER_PROFORMA_SERVICE_VERSION_DEFAULT = 'v0';
  public static final String SMARTER_PUSH_BACK_LEAD_ID = 'leadOneforceId';
  public static final String SMARTER_PUSH_BACK_ACCOUNT_ID = 'oneforceAccountOneforceId';
  public static final String SMARTER_PUSH_BACK_OPP_ID = 'opportunityOneforceId';
  //public static final String SMARTER_PUSH_BACK_CONTACT_ID = 'contactOneforceId';
  public static final String SMARTER_PUSH_BACK_FC_ID = 'financialCenterOneforceId';
  public static final String SMARTER_PUSH_BACK_BA_ID = 'billingAccountNumber';
  public static final String PROFORMA = 'PROFORMA';
  //public static final String SMARTER_CLIENT_REF_SERVICE_NAME = 'contacts';
  //public static final String SMARTER_CLIENT_REF_VERSION = 'v2';
  public static final String SMARTER_CONTACTS_SERVICE_NAME = 'contacts';
  public static final String SMARTER_CONTACTS_SERVICE_VERSION = 'v2';
  public static final String SMARTER_CONTACT_ONEFORCE_ID = 'contactOneforceId';
  public static final String SMARTER_CLIENT_REF_CLIENT_ID = 'clientId';
  public static final String SMARTER_CLIENT_REF_FIRSTNAME = 'firstName';
  public static final String SMARTER_CLIENT_REF_LASTNAME = 'lastName';
  public static final String SMARTER_CLIENT_REF_EMAIL = 'email';
  public static final String SMARTER_CLIENT_REF_PHONE = 'phone';
  public static final String SMARTER_CLIENT_REF_LANGUAGE = 'languageCode';
  public static final String SMARTER_CLIENT_REF_STATUS = 'status';
  public static final String SMARTER_MS_AD_CLIENTID = 'SMARTER_MS_AD_CLIENTID';
  public static final String SMARTER_MS_AD_CLIENTSECRET = 'SMARTER_MS_AD_CLIENTSECRET';
  public static final String SMARTER_MS_AD_SCOPE = 'SMARTER_MS_AD_SCOPE';
  public static final String SMARTER_MS_AD_NAMED_CREDENTIAL = 'Smarter_MS_AD_Legacy';
  public static final String SMARTER_SEND_ONBOARDING_SERVICE_NAME = 'contacts/send-onboarding-notification';
  public static final String SMARTER_SEND_ONBOARDING_SERVICE_VERSION = 'v2';
  public static final String UTF8_ENCODING = 'UTF-8';
  public static final String SMARTER_VALIDATE_IBAN_SERVICE_NAME = 'payment/validate-iban';
  public static final String SMARTER_VALIDATE_IBAN_SERVICE_VERSION = 'v1';
  public static final String SMARTER_CREATE_MANDAT_SERVICE_NAME = 'payment/create-mandat';
  public static final String SMARTER_CREATE_MANDAT_SERVICE_VERSION = 'v1';

  public static final String SMARTER_ACCOUNT_REF_VERSION = 'v2';
  public static final String SMARTER_ACCOUNT_REF_SERVICE_NAME = 'clients';
  public static final String SMARTER_ACCOUNT_REF_ID = 'accountOneforceId';
  public static final String SMARTER_ACCOUNT_REF_OPP_ID = 'opportunityOneforceId';
  public static final String SMARTER_ACCOUNT_REF_NAME = 'name';
  public static final String SMARTER_ACCOUNT_REF_LEGAL_NAME = 'legalName';
  public static final String SMARTER_ACCOUNT_REF_COMPANY_REGISTRATION_NUM = 'companyRegistrationNumber';
  public static final String SMARTER_ACCOUNT_REF_STREET = 'street';
  public static final String SMARTER_ACCOUNT_REF_CITY = 'city';
  public static final String SMARTER_ACCOUNT_REF_ZIP_CODE = 'zipCode';
  public static final String SMARTER_ACCOUNT_REF_COUNTRY = 'country';
  public static final String SMARTER_ACCOUNT_REF_COUNTRY_CODE = 'countryCode';
  public static final String SMARTER_ACCOUNT_REF_ORIGINAL_LEAD_ID = 'originalLeadId';
  public static final String SMARTER_ACCOUNT_REF_CUSTOMER_NUMBER = 'customerNumber';
  public static final String SMARTER_SYNC_STATUS_SYNCED = 'synchronized';
  public static final String SMARTER_SYNC_STATUS_NOT_SYNCED = 'not_synchronized';

  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_SERVICE_VERSION = 'v2';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_SERVICE_NAME = 'clients/financial-centers';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_ID = 'financialCenterOneforceId';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_ONEFORCE_ACCOUNT_ID = 'accountOneforceId';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_CONTACT_ID = 'contactOneforceId';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_BILLINGACCOUNT_ID = 'billingAccountNumber';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_STREET = 'invoicingStreet';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_CITY = 'invoicingCity';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_ZIPCODE = 'invoicingZipCode';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_COUNTRY = 'invoicingCountry';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_INVOICING_COUNTRY_CODE = 'invoicingCountryCode';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_ISMaster = 'isMaster';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_PRIMARY_EMAIL = 'primaryEmail';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_SECONDARY_EMAIL = 'secondaryEmail';
  public static final String SMARTER_PUSH_BACK_FINANCIAL_CENTER_ORIGINAL_LEAD_ID = 'originalLeadId';
  public static final String SYNC_FC_TO_SMARTER = 'SYNC_FC_TO_SMARTER';

  public static final String SMARTER_GET_TCs_SERVICE_VERSION = 'v1';
  public static final String SMARTER_GET_TCs_SERVICE_NAME = 'notices?notice-type=termsOfSale';
  public static final String SMARTER_GET_CARD_SERVICE_NAME = '/cards/';

  public static final String SMARTER_SYNC_LOOP_SERVICE_VERSION = 'v1';
  public static final String SMARTER_SYNC_LOOP_MERCHANT_SERVICE_NAME = '/merchant-loops';
  public static final String SMARTER_SYNC_LOOP_MERCHANT_GROUP_SERVICE_NAME = '/store-groups';
  public static final String SMARTER_SYNC_LOOP_STORES_NAME = '/stores';
  public static final String SMARTER_LOOP_STORE_GROUP_ID = 'storeGroupId';
  public static final String SMARTER_LOOP_MERCHANT_NAME_ID = 'merchantLoopId';
  public static final String SMARTER_LOOP_MERCHANT_NAME = 'name';
  public static final String SMARTER_LOOP_MERCHANT_CODE = 'code';

  public static final String SMARTER_SYNC_ACCOUNT_CONTACT_RELATIONS_SERVICE_NAME = 'contacts/account-relationships';
  public static final String SMARTER_SYNC_ACCOUNT_CONTACT_RELATIONS_SERVICE_VERSION = 'v2';
  public static final String SMARTER_ACCOUNT_CONTACT_RELATIONS_ID = 'accountContactRelationshipId';
  public static final String SMARTER_ACCOUNT_CONTACT_IS_DIRECT_RELATION = 'isDirectRelationship';
  public static final String SMARTER_ACCOUNT_CONTACT_ROLES = 'roles';
  public static final String SMARTER_ACCOUNT_CONTACT_ROLES_ADMINISTRATOR = 'Administrator';
  public static final String SMARTER_ACCOUNT_CONTACT_ROLES_ADMIN = 'Admin';
  public static final String SMARTER_ACCOUNT_CONTACT_EVENT_TYPE = 'eventType';
  public static final String SMARTER_ACCOUNT_CONTACT_EVENT_TYPE_OFFLINE = 'Offline';
  public static final String SMARTER_ACCOUNT_CONTACT_EVENT_TYPE_ONLINE = 'Online';

  public static final String DELIMITER_PIPE = '|';
  public static final String DELIMITER_HASH = '#';

  //BUs
  public static final String BENELUX = 'BENELUX';
  public static final String AGORIA_PRICE_INDEX = 'Agoria price index';
  public static final String CONSUMER_PRICE_INDEX = 'Consumer price index';
  public static final String ES = 'ES';
  public static final String FI = 'FI';
  public static final String CZ = 'CZ';
  public static final String FR = 'FR';
  public static final String SK = 'SK';
  public static final String GR = 'GR';
  public static final String DOCUSIGN_DEPLOYED_BUS = 'Docusign_Deployed_BUs';
  public static final String SMARTER_DEPLOYED_BUS = 'SmartER_Deployed_BUs';

  public static final String OPP_PAYMENT_TERM_PRE_PAID = 'Pre-paid';
  public static final String OPP_PAYMENT_METHOD_BANK_TRANSFER = 'Bank transfer';
  public static final String INSERT_DML = 'INSERT';
  public static final String UPDATE_DML = 'UPDATE';
  public static final String CREATE_TASK_FOR_CONTRACT_EXCLUDED_BUS = 'CreateTaskForContractExcludedBUs';

  //STATUSES
  public static final String ACTIVE = 'Active';
  public static final String ACTIVE_LOWERCASE = 'active';
  public static final String INACTIVE = 'Inactive';
  public static final String INACTIVE_LOWERCASE = 'inactive';
  public static final String ACTIVATED = 'Activated';
  public static final String TERMINATED = 'Terminated';
  public static final String PENDING_TERMINATION = 'Pending Termination';
  public static final String DRAFT = 'Draft';
  public static final String PRESENTED = 'Presented';
  public static final String ACCEPTED = 'Accepted';
  public static final String DENIED = 'Denied';
  public static final String NEW_STATUS = 'New';
  public static final String CLOSED_WON = 'Closed Won';
  public static final String CLOSED_LOST = 'Closed Lost';
  public static final String CLOSED = 'Closed';
  public static final String RESOLVED = 'Resolved';
  public static final String WAITING_FOR_CLIENT = 'Waiting for Client';
  public static final String WAITING_FOR_SUPPORT = 'Waiting for Support';
  public static final String CANCELLED = 'Cancelled';
  public static final String IN_PROGRESS = 'In_Progress';
  public static final String MERGED = 'Merged';
  public static final String REJECTED = 'Rejected';
  public static final String DUPLICATE_LEAD = 'Duplicates (< 2 weeks)';
  public static final String QUALIFIED = 'Qualified';
  public static final String SPAM = 'Spam';
  public static final String OPEN = 'Open';
  public static final String WAITING_FOR_CUSTOMER = 'Waiting for Customer';
  public static final String APPROVED = 'Approved';
  public static final String PENDING = 'Pending';
  public static final String REMOVED = 'Removed';
  public static final String ZQUOTE_IN_PROGRESS = 'In Progress';
  public static final String PENDING_APPROVAL = 'Pending Approval';
  public static final String CROSS_SELLING_REASON = 'Cross selling';

  //SCOPES
  public static final String MERCHANT = 'Merchant';
  public static final String CLIENT = 'Client';
  public static final String MERCHANT_CLIENT = 'Merchant Client';

  //MEDALLIA
  public static final String MEDALLIA_CASE_CLOSED_SURVEY = 'Medallia_Case_Closed_Survey';
  public static final String MEDALLIA_CASE_CLOSED_SURVEY_B2C = 'Medallia_Case_Closed_Survey_B2C';
  public static final String MEDALLIA_CLOSE_ALERT = 'Medallia_Close_Alert';
  public static final String MEDALLIA_PULSE_SURVEY = 'Medallia_Pulse_Survey';
  public static final String MEDALLIA_PULSE_SURVEY_B2C = 'Medallia_Pulse_Survey_B2C';
  public static final String MEDALLIA_FIELDSET_CREATE_SURVEY = 'ER_medalliaOutbound_createSurvey';
  public static final String CONTACT = 'Contact';
  public static final String INDIVIDUAL = 'Individual';
  public static final String INVITED = 'Invited';
  public static final String RECEIVED = 'Received';
  public static final String ALL = 'All';
  public static final String YES = 'Yes';
  public static final String NO = 'No';
  public static final String MEDALLIA_DEPLOYED_BUS = 'Medallia_Deployed_BUs';
  public static final String MEDALLIA_STRING = 'MEDALLIA';
  public static final String MEDALLIA_BATCH_INVITATION_NB_DAYS = 'Medallia_Batch_Invitation_NB_Days';
  public static final String MEDALLIA_BATCH_PULSE_NB_DAYS = 'Medallia_Batch_Pulse_NB_Days';

  //RECORD TYPES DEV NAMES
  public static final String ACCEPTOR_MERCHANT_RT = 'ER_Merchant_Acceptor_RT';
  public static final String STORE_MERCHANT_RT = 'ER_Merchant_Store';
  public static final String CASE_NPS_ALERT_CASE = 'ER_NPS_Alert_Case';
  public static final String CONTRACT_MERCHANT_RT = 'ER_Merchant_Contract_RT';
  public static final String CONTRACT_CLIENT_RT = 'ER_Client_Contract_RT';
  public static final String OPPORTUNITY_MERCHANT_RT = 'ER_Merchant_Opportunity';
  public static final String OPPORTUNITY_CLIENT_RT = 'ER_Client_Opportunity_RT';
  public static final String ACCOUNT_COMPANY_RT = 'ER_Company_Account_RT';
  public static final String ACCOUNT_INDVIDUAL_RT = 'ER_Individual_Account_RT';
  public static final String CONTACT_ROLE_DS_RT = 'ER_CR_Delivery_Site';
  public static final String CONTACT_ROLE_DP_RT = 'ER_CR_Distribution_Point';
  public static final String CONTACT_ROLE_FCC_RT = 'ER_CR_Financial_Center_Client';
  public static final String CONTACT_ROLE_FCM_RT = 'ER_CR_Financial_Center_Merchant';
  public static final String CONTACT_ROLE_STORE_RT = 'ER_CR_Store';
  public static final String CASE_USER_RT = 'ER_User_Case_RT';
  public static final String CASE_CLIENT_RT = 'ER_Client_Case_RT';
  public static final String CASE_MERCHANT_RT = 'ER_Merchant_Case_RT';
  public static final String PROMO_CODE_AFFILIATION_RT = 'ER_Affiliation_Code';
  public static final String PROMO_CODE_PROMO_RT = 'ER_Promo_Code';
  public static final String QUOTE_MERCHANT_RT = 'ER_Merchant_Quote';
  public static final String STORE_STORE_AGGREGATOR_RT = 'Store_Aggregator';
  public static final String ACCOUNT_AGGREGATOR_MERCHANT_RT = 'Aggregator_Merchant';
  public static final String LEAD_MERCHANT_RT = 'ER_Merchant_Lead_RT';
  public static final String LEAD_CLIENT_RT = 'ER_Client_Lead_RT';
  public static final String CATEGORY_RT = 'Category';
  public static final String PRODUCT2_BENEFIT_RT = 'Benefit';
  public static final String CONTACT_BUSINESS_RT = 'ER_Contact_RT';

  //PROFILES NAME
  public static final String PROFILE_CLIENT_SALES = 'Client Sales';
  public static final String PROFILE_MERCHANT_SALES = 'Merchant Sales';
  public static final String PROFILE_ZUORA_SALES = 'ER Zuora Sales';
  public static final String PROFILE_ER_INTEGRATION = 'ER Integration';
  public static final String PROFILE_SYS_ADMIN = 'System Administrator';
  public static final String AUTOMATED_PROCESS_USERNAME = 'Automated Process';

  //ACCOUNT PARTNER ROLES
  public static final String FEDERATION_MEMBER = 'Federation Member';
  public static final String FRANCHISEE = 'Franchisee';
  public static final String PARTNER_ROLE_AGGREGATOR = 'Aggregator';
  public static final String PARTNER_ROLE_EDENRED_MERCHANT_AGGREGATOR = 'EdenredMerchant';

  //FC
  public static final String FC_DEFAULT_PAYMENTSITE = 'FC_Default_PaymentSite';
  public static final String E_Invoice = 'E-invoice';

  //GLOBAL VALUES
  public static final String NAME = 'Name';
  public static final String SERVICE = 'Service';
  public static final String SOLUTION = 'Solution';
  public static final String PARENT = 'Parent';
  public static final String FEDERATION = 'Federation';
  public static final String FRANCHISER = 'Franchiser';
  public static final String CONTRACT_PAYMENT_METHOD_DIRECT_DEBIT = 'Direct debit';
  public static final String CONTRACT_INVOICING_FREQUENCY_PER_ORDER = 'Per order';
  public static final String CONTRACT_INVOICING_FREQUENCY_DEFERRED = 'Deferred';
  public static final String CONTRACT_INVOICING_FREQUENCY_GROUPED = 'Grouped';
  public static final String RANGE = 'Range';
  public static final String RANGE_WITH_FIX_PRICE = 'Range with Fix Price';
  public static final String FIX_RANGE = 'Fix Range';
  public static final String VARIABLE_RANGE_VOLUME_PRICING = 'Variable Range Volume pricing';
  public static final String RANGE_WITH_VARIABLE_PRICE_VOLUME_PRICING = 'Range with Variable price Volume pricing';
  public static final String WEBAUTH = 'WEBAuth';
  public static final String C_TAP = 'C-TAP';
  public static final String MASTERCARD = 'MasterCard';
  public static final String LEAD_OBJECT_PREFIX = '00Q';
  public static final String CASE_OBJECT_PREFIX = '500';
  public static final String ACCEPTOR_TYPE_AGGREGATOR = 'Aggregator';
  public static final String ACCOUNT = 'Account';
  public static final String LEAD = 'Lead';
  public static final String TASK = 'Task';
  public static final String EMPLOYEE = 'ER_Employee__c';
  public static final String FINANCIAL_CENTER = 'FinancialCenter';
  public static final String CATEGORY_MAX_DEPT = '_CATEGORY_MAX_DEPT';
  public static final String ACCOUNT_OBJECT_PREFIX = '001';
  public static final String USER_OBJECT_PREFIX = '005';
  public static final String GROUP_OBJECT_PREFIX = '00G';
  public static final String CASE_OBJECT = 'Case';
  public static final String BU_FIELD_NAME = 'ER_BUPicklist__c';
  public static final String DISCOUNT = 'Discount';
  public static final String MESSAGE = 'message';
  public static final String USER_OBJECT_TYPE = 'User';
  public static final String GROUP_OBJECT_TYPE = 'Group';
  //public static final String SMARTER_NAMED_CREDENTIAL = 'SmarterNC';
  public static final String SMARTER_NAMED_CREDENTIAL = 'Smarter_NC_Legacy';
  public static final String X_TENANT = 'x-tenant';
  public static final String GET_ISSUER_ACCOUNT_SERVICE_NAME = 'issuer-accounts';
  public static final String GET_ISSUER_ACCOUNT_SERVICE_VERSION = 'v1';
  public static final String WIRE_TRANSFER = 'Wire transfer';
  public static final String AT_RECEPTION_OF_INVOICE = 'At reception of invoice';
  public static final String GET_FC_UPDATES_SERVICE_VERSION = 'v1';
  public static final String GET_FC_UPDATES_SERVICE_NAME = 'financial-centers';
  public static final String GET_IA_TRANSACTIONS_SERVICE_NAME = 'transactions';
  public static final String GET_IA_TRANSACTIONS_SERVICE_VERSION = 'v1';
  public static final String MANAGE_ZQUOTE_SYNC_FIELDS = 'MANAGE_ZQUOTE_SYNC_FIELDS';
  public static final String REQUEST_HEADER_USER_EMAIL = 'User-Email';
  public static final String SEGMENT_SME = 'SME';
  public static final String REQUEST_HEADER_DD_TRACEID = 'dd.trace_id';
  public static final String CONTRACTING_WEBFORM = 'Contracting webform';
  public static final String PROPOSAL = 'Proposal';

  //PLATFORM EVENT MESSAGES
  public static final String MANAGE_SOLUTION_LINE_ITEMS = 'MANAGE_SOLUTION_LINE_ITEMS';
  public static final String SMARTER_PUSH_BACK_IDS = 'SMARTER_PUSH_BACK_IDS';
  public static final String SMARTER_SYNC_CONTACTS = 'SMARTER_SYNC_CONTACTS';
  public static final String RUN_STORE_TO_LOOP_CREATION = 'RUN_STORE_TO_LOOP_CREATION';
  public static final String RUN_STORE_TO_LOOP_UPDATE = 'RUN_STORE_TO_LOOP_UPDATE';
  public static final String RUN_ACCEPTOR_TO_LOOP_CREATION = 'RUN_ACCEPTOR_TO_LOOP_CREATION';
  public static final String RUN_ACCEPTOR_TO_LOOP_UPDATE = 'RUN_ACCEPTOR_TO_LOOP_UPDATE';
  public static final String RUN_SYNC_CLIENT_TO_SMARTER = 'RUN_SYNC_CLIENT_TO_SMARTER';
  public static final String RUN_SYNC_OFFLINE_TCS = 'RUN_SYNC_OFFLINE_TCS';
  public static final String RUN_SYNC_CONTACTS_TO_SMARTER = 'RUN_SYNC_CONTACTS_TO_SMARTER';
  public static final String RUN_SYNC_MERCHANT_LOOP_GROUP_TO_SMARTER = 'RUN_SYNC_MERCHANT_LOOP_GROUP_TO_SMARTER';
  public static final String RUN_SYNC_ACCEPTOR_TO_LOOP_TO_SMARTER = 'RUN_SYNC_ACCEPTOR_TO_LOOP_TO_SMARTER';

  //CASE CUSTOMER SEGMENT
  public static final String CASE_CUSTOMER_SEGMENT_CLIENT = 'Client';
  public static final String CASE_CUSTOMER_SEGMENT_MERCHANT = 'Merchant';
  public static final String CASE_CUSTOMER_SEGMENT_BENEFICIARY = 'Beneficiary';
  public static final String CASE_CUSTOMER_SEGMENT_DELICARD = 'Delicard';

  //CASE ORIGIN
  public static final String CASE_ORIGIN_EMAIL = 'Email';
  public static final String CASE_ORIGIN_WEB = 'Web';
  public static final String CASE_ORIGIN_PHONE = 'Phone';

  //CASE OWNER QUEUE
  public static final String CASE_QUEUE_ERFI_CLIENT = 'ERFI_Client';
  public static final String CASE_QUEUE_ERFI_MERCHANT = 'ERFI_Merchant_1st_line';
  public static final String CASE_QUEUE_ERFI_BENEFICIARY = 'ERFI_Beneficiary';
  public static final String CASE_QUEUE_ERFI_DELICARD = 'ERFI_Delicard';
  public static final String CASE_QUEUE_ERSK_ROBOT_FAILED = 'ERSK_Robot_Failed_Queue';
  public static final String CASE_QUEUE_ERFI_AUTO_ASSIGNMENT = 'ERFI_Balance_adjustments_client';
  public static final String CASE_QUEUE_ERES_SPAM = 'ERES_SPAM';
  public static final String CASE_QUEUE_ERGR_UNMANAGEABLE_CASE = 'ERGR_Unmanageable_cases';

  //CASE REASON
  public static final String CASE_DETAILED_REASON_CARD_LOAD = 'Card and/or load order';
  public static final String CASE_REASON_ORDER_DELIVERY = 'ER_Order_Delivery';

  //CASE STATUS
  public static final String CASE_STATUS_ESCALATED = 'Escalated';
  public static final String CASE_STATUS_NEW = 'New';
  public static final String CASE_STATUS_SPAM = 'Spam';

  //CASE ESCALATION LEVEL
  public static final String CASE_ESCALATION_LEVEL_TECHNICAL = 'Technical';
  public static final String CASE_ESCALATION_LEVEL_TIER2 = 'Tier2';

  //Test endpoints
  /*public static final String STATUS_OK = 'SUCCESS';
    public static final String STATUS_NOTFOUND = 'NOT FOUND';
    public static final String STATUS_BADREQUEST = 'BAD REQUEST';
    public static final String STATUS_FAILURE = 'FAILURE';*/
  public static final Integer STATUS_CODE_BADREQUEST = 400;
  public static final Integer STATUS_CODE_OK = 202;
  public static final Integer STATUS_CODE_NOTFOUND = 404;

  // Priority
  public static final String NORMAL = 'Normal';
  public static final String CASE_PRIORITY_LOW = 'Low';
  public static final String CASE_PRIORITY_HIGH = 'High';

  // Source
  public static final String AUTO_ENROLLMENT = 'Auto Enrollment';
  public static final String LEAD_SOURCE_EFG = 'EFG';

  public static final String PIPE_SEPARATOR = '\\|';
  public static final String AUTO_ENROLLMENT_BU_LIST = 'BUSINESS_UNITS';
  public static final String BENEFIT_TYPE = 'Benefit';
  public static final String CARD_TYPE = 'Card Type';

  //Public Register Custom Metadata
  public static final String PUBLIC_REGISTER_FIELDS_ACCOUNT_FR = 'PUBLIC_REGISTER_FIELDS_ACCOUNT_FR';
  public static final String PUBLIC_REGISTER_FIELDS_LEAD_FR = 'PUBLIC_REGISTER_FIELDS_LEAD_FR';
  public static final String PUBLIC_REGISTER_FIELDS_ACCOUNT_FI = 'PUBLIC_REGISTER_FIELDS_ACCOUNT_FI';
  public static final String PUBLIC_REGISTER_FIELDS_LEAD_FI = 'PUBLIC_REGISTER_FIELDS_LEAD_FI';
  public static final String PUBLIC_REGISTER_FIELDS_ACCOUNT_GR = 'PUBLIC_REGISTER_FIELDS_ACCOUNT_GR';
  public static final String PUBLIC_REGISTER_FIELDS_LEAD_GR = 'PUBLIC_REGISTER_FIELDS_LEAD_GR';
  public static final String PUBLIC_REGISTER_WEBSERVICE_GR = 'PublicRegisterGR';

  //Webservices Parameters
  public static final String SMARTER_WEBSERVICE_PAGEINDEX = 'page-index=';
  public static final String SMARTER_WEBSERVICE_PAGESIZE = 'page-size=';
  public static final String SMARTER_WEBSERVICE_EMPLOYEE_ID = 'employee-id=';
  public static final String SMARTER_WEBSERVICE_CLIENT_ID = 'client-id=';

  public static final String SMARTER_WEBSERVICE_ORDER_BY_CLIENT = '/orders-by-client';
  public static final String SMARTER_WEBSERVICE_ORDER_BY_CLIENT_VERSION = 'v1';
  public static final String SMARTER_WEBSERVICE_ORDER_BY_EMPLOYEE = '/orders-by-employee';
  public static final String SMARTER_WEBSERVICE_ORDER_BY_EMPLOYEE_VERSION = 'v1';
  public static final String SMARTER_WEBSERVICE_ORDER_ITEM_LINES = '/order-item-lines';
  public static final String SMARTER_WEBSERVICE_LOADS_ERROR_PARAM = '&status=executionError';
  public static final String SMARTER_WEBSERVICE_LOADS = '/loads';
  public static final String SMARTER_WEBSERVICE_PROCESSING_EVENTS = '/processing-events';
  public static final String SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_SERVICE = 'orders';
  public static final String SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_VERSION = 'v1';
  public static final String SMARTER_CANCEL_ORDER = 'cancel';
  public static final String SMARTER_RETRY_ORDER = 'retry';
  public static final String SMARTER_WEBSERVICE_ORDERS = '/orders';
  public static final String SMARTER_RESTART_SUBMISSION = 'restart-submission';
  public static final String SMARTER_BACKOFFICE = 'Backoffice';

  public static final String SMARTER_EDENRED_CODES_SERVICE_NAME = 'edenred-codes';
  public static final String SMARTER_EDENRED_CODES_SERVICE_VERSION = 'v1';

  public static final String SMARTER_OFFLINE_TCS_SERVICE_NAME = 'clients/terms-and-conditions';
  public static final String SMARTER_OFFLINE_TCS_SERVICE_VERSION = 'v2';

  public static final String GENESYS_CLOUD_CLIENTID = 'GENESYS_CLOUD_CLIENTID';
  public static final String GENESYS_CLOUD_CLIENTSECRET = 'GENESYS_CLOUD_CLIENTSECRET';
  public static final String GENESYS_CLOUD_CONVERSATION_QUEUE_ID = 'GENESYS_CLOUD_CONVERSATION_QUEUE_ID';
  public static final String GENESYS_CLOUD_AUTH_NAMED_CREDENTIAL = 'Genesys_Cloud_Auth_Legacy';
  public static final String GENESYS_CLOUD_NAMED_CREDENTIAL = 'Genesys_Cloud_Legacy';
  public static final String GENESYS_CLOUD_CALLBACK_SERVICE = '/api/v2/conversations/callbacks';
  public static final String GENESYS_CLOUD_DISCONNECT_CONVERSATION_SERVICE = '/api/v2/conversations/emails';
  public static final String GENESYS_CLOUD_SEARCH = '/api/v2/search';
  public static final String GENESYS_CLOUD_TOKEN_TYPE = 'token_type';
  public static final String GENESYS_CLOUD_ACCESS_TOKEN = 'access_token';
  public static final String GENESYS_TASK_TYPE = 'Tentative de Contact';
  public static final String GENESYS_TASK_STATUS_COMPLETED = 'Completed';
  public static final String GENESYS_TASK_STATUS_OPEN = 'Open';
  public static final String GENESYS_TASK_FOLLOW_UP_SUBJECT = 'Tentative de Contact';
  public static final String GENESYS_TASK_FOLLOW_UP_TYPE = 'Attempted Call';
  public static final String GENESYS_CASE_FLOW_ID_CONFIG = 'GEN_F_C_';
  public static final String GENESYS_TASK_FLOW_ID_CONFIG = 'GEN_F_T_';
  public static final String GENESYS_EMAIL_MESSAGE_FLOW_ID_CONFIG = 'GEN_F_EM_';
  public static final String GENESYS_EMAIL_MESSAGE_QUEUE_ID_CONFIG = 'GEN_Q_EM_';
  public static final String GENESYS_CASE_QUEUE_ID_CONFIG = 'GEN_Q_C_';
  public static final String GENESYS_LEAD_FLOW_ID_CONFIG = 'GEN_F_L_';
  public static final String GENESYS_LEAD_QUEUE_ID_CONFIG = 'GEN_Q_L_';
  public static final String GENESYS_OPPORTUNITY_FLOW_ID_CONFIG = 'GEN_F_O_';
  public static final String GENESYS_OPPORTUNITY_QUEUE_ID_CONFIG = 'GEN_Q_O_';
  public static final String GENESYS_LEAD_ERFR_EP_NS_0_9 = 'ERFR_EP_NS_0_9';
  public static final String GENESYS_LEAD_ERFR_EP_NS_10_29 = 'ERFR_EP_NS_10_29';
  public static final String GENESYS_LEAD_DROP_CASE_QUEUE = 'ERFR_CLIENT_DROP_SME';
  public static final List<String> CASE_LIST_DISTRIBUTION_QUEUE = new List<String>{
    'ERFR_B2B_Contact_form',
    'ERFR_B2C_Contact_form'
  };
  public static final String GENESYS_GR_CHATBOT_QUEUE = 'ERGR_Business_Email_Queue';
  public static final String GENESYS_GR_EMAIL_MESSAGE_QUEUE = 'GENESYS_GR_EMAIL_MESSAGE_QUEUE';
  public static final String GENESYS_MAPPING_METADATA_PREFIX = 'GEN_MAP_';
  public static final String GENESYS_PRIORITY_HIGH = 'Prio_5';
  public static final String GENESYS_PRIORITY_LOW = 'Prio_4';
  public static final String GENESYS_API_ATT_SF_URLPOP = 'sf_urlpop';
  public static final String GENESYS_API_ATT_PREF_AGENT = 'Pref_Agent';
  public static final String GENESYS_API_ATT_PRIORITE = 'Priorite';
  public static final String GENESYS_API_ATT_TYPE_ACTIVITE = 'Type_Activite';
  public static final String GENESYS_API_ATT_FA_SF = 'FA_SF';
  public static final String GENESYS_API_ATT_COMP = 'Comp';
  public static final String GENESYS_API_ATT_SENS = 'Sens';
  public static final String GENESYS_API_ATT_PREF_AGENT_BKP = 'Pref_Agent_Bkp';
  public static final String GENESYS_API_ATT_EMAIL_SUBJECT = 'Email_Subject';
  public static final String GENESYS_API_ATT_PREF_EMAIL_DESCRIPTION = 'Email_Description';
  public static final String GENESYS_API_ATT_CLIENT_PRIORITY = 'Client_Priority';
  public static final String GENESYS_API_ATT_AGENT_BACKUP = 'Agent_Backup';
  public static final String GENESYS_GR_TO_EMAIL_ADD = 'GENESYS_GR_TO_EMAIL_ADD';
  public static final List<String> GENESYS_TASK_FOLLOW_UP_REASON_CODE = new List<String>{
    'Follow-up on NRP',
    'Phone appointment',
    'Follow-up without appointment'
  };
  public static final List<String> GENESYS_TASK_FOLLOW_UP_CODE = new List<String>{
    'Créer relance sur NRP',
    'Créer un RDV Téléphonique',
    'Créer relance sans RDV'
  };
  public static final List<String> GENESYS_DROP_CASE_VALUES = new List<String>{ 'Contact', 'Company' };

  public static final String NAVIGATION_URL = '/lightning/r/{0}/{1}/view';

  public static final String LEAD_UPDATE_PRODUCT_INTEREST_BU = 'LEAD_UPDATE_PRODUCT_INTEREST_BU';

  public static final String SMARTER = 'Smarter';
  public static final String SMARTER_LEGACY = 'Smarter/Legacy';

  public static final String CEGEDIM_API_JSON_VALIDATE_IBAN_MSGID = 'msgId';
  public static final String CEGEDIM_API_JSON_CREATE_MANDAT_MSGID = 'msgId';
  public static final String CEGEDIM_API_JSON_CREDTM = 'creDtTm';
  public static final String CEGEDIM_API_JSON_ID = 'id';
  public static final String CEGEDIM_API_JSON_PRVTID = 'prvtId';
  public static final String CEGEDIM_API_JSON_INITGPTY = 'initgPty';
  public static final String CEGEDIM_API_JSON_IBAN = 'iban';
  public static final String CEGEDIM_API_JSON_INTLACCT = 'intlAcct';
  public static final String CEGEDIM_API_JSON_GRPHDR = 'grpHdr';
  public static final String CEGEDIM_API_JSON_BICIBAN_VLDTNRQST = 'bicIbanVldtnRqst';
  public static final String CEGEDIM_API_JSON_VALIDATEIBAN_RESP = 'bimt190';
  public static final String CEGEDIM_API_JSON_BICIBAN_VLDTNRESP = 'bicIbanVldtnResp';
  public static final String CEGEDIM_API_JSON_NB_TX = 'NbOfTxs';
  public static final String CEGEDIM_API_JSON_CRDT = 'Cdtr';
  public static final String CEGEDIM_API_JSON_IDX = 'idx';
  public static final String CEGEDIM_API_JSON_IS_MIGRATED = 'migrated';
  public static final String CEGEDIM_API_JSON_ORGNID = 'OrgnId';
  public static final String CEGEDIM_API_JSON_ORGNID_EDENRED = 'EDENRED';
  public static final String CEGEDIM_API_JSON_MNDTTP = 'MndtTp';
  public static final String CEGEDIM_API_JSON_SEQTP = 'SeqTp';
  public static final String CEGEDIM_API_JSON_SEQTP_RCUR = 'RCUR';
  public static final String CEGEDIM_API_JSON_DTOFSGNTR = 'DtOfSgntr';
  public static final String CEGEDIM_API_JSON_COUNTRY = 'Ctry';
  public static final String CEGEDIM_API_JSON_DBTR_NAME = 'Nm';
  public static final String CEGEDIM_API_JSON_MNDTTP_B2B = 'B2B';
  public static final String CEGEDIM_API_JSON_PSTLADR = 'PstlAdr';
  public static final String CEGEDIM_API_JSON_DBTR = 'Dbtr';
  public static final String CEGEDIM_API_JSON_DBTR_ACC = 'DbtrAcct';
  public static final String CEGEDIM_API_JSON_MNDTINF = 'MndtInf';
  public static final String CEGEDIM_API_JSON_CDTR_MNDINF = 'CdtrMndtInf';
  public static final String CEGEDIM_API_JSON_STSCODE = 'stsCode';
  public static final String CEGEDIM_API_JSON_STSCODE_ACCEPTED = 'AC00';
  public static final String CEGEDIM_API_JSON_TX_STSCODE = 'txStsCode';
  public static final String CEGEDIM_API_JSON_TX_STS = 'txSts';
  public static final String CEGEDIM_API_JSON_TX_STS_ACCEPTED = 'ACCT';
  public static final String CEGEDIM_API_JSON_TX_STSCODE_CREATED = 'MD00';
  public static final String CEGEDIM_API_JSON_CREATE_MANDAT_RESP = 'mamt101';
  public static final String CEGEDIM_API_JSON_CDTRMND_INFO = 'cdtrMndtAns';
  public static final String CEGEDIM_API_JSON_MNDT_INFO = 'mndtAns';
  public static final String CEGEDIM_API_JSON_RUI = 'intlId';
  public static final String CEGEDIM_API_JSON_RUM = 'mndtId';
  public static final String CEGEDIM_EDENRED_ENTITY_ID = 'Cegedim_Edenred_Entity_ID_';
  public static final String CEGEDIM_EDENRED_CRDT_CODE = 'Cegedim_Edenred_Crdt_Code_';
  
  //NEMO Constants  
  public static final String ADDITIONAL_SERVICE_CODE_BE = 'TRC';
  public static final String ADDITIONAL_SERVICE_CODE_LU = 'CLU'; 
  public static final String BENEFIT = 'benefit';
  public static final String SAVINGS = 'savings';
  public static final String CARD_RP_BF = 'CARD_RP_BF';
  public static final String CARD_RP_CT = 'CARD_RP_CT';

  //Contract Crediting Values
  public static final String CRED_1_DAY = 'CRED_1_DAY';
  public static final String CRED_2_DAY = 'CRED_2_DAY';
  public static final String CRED_3_DAY = 'CRED_3_DAY';
  public static final String CRED_4_DAY = 'CRED_4_DAY';
  public static final String CRED_0_DAY = 'CRED_0_DAY';
    
    public static Map<String, String> getCreditingMap() {
        Map<String, String> creditingMap = new Map<String, String>();
        creditingMap.put('Credit 1 day', CRED_1_DAY);
        creditingMap.put('Credit 2 day', CRED_2_DAY);
        creditingMap.put('Credit 3 day', CRED_3_DAY);
        creditingMap.put('Credit 4 day', CRED_4_DAY);
        creditingMap.put('Credit Express', CRED_0_DAY);
        return creditingMap;
    }
   
  //Contract Payment Terms Values
  public static final String PD_0_DAY = 'PD_0_DAY';
  public static final String PD_10_DAY = 'PD_10_DAY';
  public static final String PD_14_DAY = 'PD_14_DAY';
  public static final String PD_15_DAY = 'PD_15_DAY';
  public static final String PD_21_DAY = 'PD_21_DAY';
  public static final String PD_30_DAY = 'PD_30_DAY';
  public static final String PD_5_DAY = 'PD_5_DAY';
  public static final String PD_60_DAY = 'PD_60_DAY';
  public static final String PD_7_DAY = 'PD_7_DAY';
  public static final String PD_100_DAY = 'PD_100_DAY';
  public static final String PD_4_DAY = 'PD_4_DAY';
  public static final String PD_50_DAY = 'PD_50_DAY';
  public static final String PD_90_DAY = 'PD_90_DAY';
  public static final String PD_PREPAID = 'PD_PREPAID';
  
    public static Map<String, String> getPaymentTermsMap() {
        Map<String, String> paymentTermsMap = new Map<String, String>();
        paymentTermsMap.put('At reception of invoice', PD_0_DAY);
        paymentTermsMap.put('10 days after invoice issuance', PD_10_DAY);
        paymentTermsMap.put('14 days after invoice issuance', PD_14_DAY);
        paymentTermsMap.put('15 days after invoice issuance', PD_15_DAY);
        paymentTermsMap.put('21 days after invoice issuance', PD_21_DAY);
        paymentTermsMap.put('30 days after invoice issuance', PD_30_DAY);
        paymentTermsMap.put('5 days after invoice issuance', PD_5_DAY);
        paymentTermsMap.put('60 days after invoice issuance', PD_60_DAY);
        paymentTermsMap.put('7 days after invoice issuance', PD_7_DAY);
        paymentTermsMap.put('100 days after invoice issuance', PD_100_DAY);
        paymentTermsMap.put('4 days after invoice issuance', PD_4_DAY);
        paymentTermsMap.put('50 days after invoice issuance', PD_50_DAY);
        paymentTermsMap.put('90 days after invoice issuance', PD_90_DAY);
        paymentTermsMap.put('Pre-paid', PD_PREPAID);
        return paymentTermsMap;
    }
    
  //Contract Payment Method Values  
  public static final String PM_DOMCL = 'PM_DOMCL';
  public static final String PM_TRNSF = 'PM_TRNSF';
    
    public static Map<String, String> getPaymentMethodMap() {
    	Map<String, String> paymentMethodMap = new Map<String, String>();
        paymentMethodMap.put('Direct debit', PM_DOMCL);
        paymentMethodMap.put('Bank transfer', PM_TRNSF);
        return paymentMethodMap;
    }


}