/*
----------------------------------------------------------------------
-- - Name          : WSBE03_CbeApi
-- - Author        : Harkirat Singh
-- - Description   : Client for the CBE/BCE/KBO API (https://cbeapi.be/api), the Belgian
--                   Crossroads Bank for Enterprises. Replaces WSBE01_Belfirst for the BE
--                   auto-enrollment company lookup. Belgium only - LU has no coverage in
--                   this register and stays on Belfirst.
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Aug-2026     Harkirat Singh       1.0         Initial version
----------------------------------------------------------------------
*/
public with sharing class WSBE03_CbeApi {
  private static final String MDT_LOOKUP = 'CBE_COMPANY_LOOKUP';
  private static final String DEFAULT_BASE_URL = 'https://cbeapi.be/api';
  private static final String COMPANY_PATH = '/v1/company/';
  private static final Integer DEFAULT_TIMEOUT_MS = 20000;

  private static final String CACHE_PARTITION = 'local.CbeApi';
  private static final Integer CACHE_TTL_SECONDS = 21600;

  // harkirat - the form only ever deals with Belgian companies on this path
  private static final String COUNTRY_LONG_FORM = 'BELGIUM';
  private static final String VAT_PREFIX = 'BE';

  private static final Set<String> SUPPORTED_LANGUAGES = new Set<String>{ 'fr', 'nl', 'de' };
  private static final String DEFAULT_LANGUAGE = 'fr';

  /*------------------------------------------------------------
	Description:   Normalized lookup result, decoupled from the API payload
	------------------------------------------------------------*/
  public class CompanyInfo {
    public Boolean found = false;
    public String legalName = '';
    public String commercialName = '';
    public String vatNumber = '';
    public String registrationNumber = '';
    public String legalForm = '';
    public String street = '';
    public String postCode = '';
    public String city = '';
    public String country = '';
    public String errorMessage = '';

    /*  Emits every key the LWC reads. Keys are never omitted and values are never null:
        clientAutoEnrollmentComponent reads COMMERCIALNAME with `!= ""`, so a missing key
        would pass that test and write "undefined" into the form field. A blank instance
        therefore yields a fully blank but perfectly usable form. */
    public Map<String, String> toLegacyMap() {
      return new Map<String, String>{
        'NAME' => blankIfNull(legalName),
        'COMMERCIALNAME' => blankIfNull(commercialName),
        'BVDID' => blankIfNull(vatNumber),
        'COMPANY_NUMBER' => blankIfNull(registrationNumber),
        'LVAT' => '',
        'ADDRESS' => blankIfNull(street),
        'POSTCODE' => blankIfNull(postCode),
        'TOWN' => blankIfNull(city),
        'COUNTRY' => blankIfNull(country),
        'TYPE' => blankIfNull(legalForm),
        'SUBJECTTOVAT' => '',
        'ERROR_MESSAGE' => blankIfNull(errorMessage)
      };
    }
  }

  /*=================================================================
    PUBLIC ENTRY POINT
  =================================================================*/

  /*  Looks up a Belgian company by enterprise number. Returns found = false when the
      register has no such company (HTTP 404); throws WSBE03_CbeApiException for any
      other failure, so the caller can log a miss and an outage differently. Callers are
      expected to fall back to a blank CompanyInfo so the user can still type the details. */
  public static CompanyInfo fetchByEnterpriseNumber(String enterpriseNumber, String language) {
    String cbeNumber = digitsOnly(enterpriseNumber);
    if (String.isBlank(cbeNumber)) {
      throw new WSBE03_CbeApiException('Enterprise number is required.');
    }

    CompanyInfo cached = readCache(cbeNumber);
    if (cached != null) {
      return cached;
    }

    HttpResponse response = sendLookup(cbeNumber, language);
    Integer statusCode = response.getStatusCode();

    if (statusCode == 404) {
      CompanyInfo missing = new CompanyInfo();
      missing.found = false;
      return missing;
    }
    if (statusCode != 200) {
      throw new WSBE03_CbeApiException(
        'CBE API returned ' + statusCode + ' ' + response.getStatus() + ' - ' + extractApiError(response.getBody())
      );
    }

    CompanyInfo info = parseCompany(response.getBody());
    writeCache(cbeNumber, info);
    return info;
  }

  /*  Blank result carrying a user-facing message. Lets the caller degrade to a manually
      fillable form instead of leaving the LWC without a payload. */
  public static CompanyInfo blankResult(String userMessage) {
    CompanyInfo info = new CompanyInfo();
    info.found = false;
    info.errorMessage = blankIfNull(userMessage);
    return info;
  }

  /*=================================================================
    CALLOUT
  =================================================================*/

  private static HttpResponse sendLookup(String cbeNumber, String language) {
    HTTPCalloutService service = new HTTPCalloutService(MDT_LOOKUP);
    // harkirat - read-only lookup on a public form, no integration log per keystroke
    service.setILFlag(false);

    // harkirat - metadata may not be deployed yet, fall back so tests still run
    String baseUrl = String.isNotBlank(service.getEndpointURL()) ? service.getEndpointURL() : DEFAULT_BASE_URL;
    if (String.isBlank(service.getRequestMethod())) {
      service.setRequestMethod('GET');
    }
    if (service.getRequestTimeout() == null) {
      service.setRequestTimeout(DEFAULT_TIMEOUT_MS);
    }

    // harkirat - path parameter, not a query string, so build the URL directly
    service.setEndpointURL(baseUrl.removeEnd('/') + COMPANY_PATH + EncodingUtil.urlEncode(cbeNumber, 'UTF-8'));
    service.setHeaderParameter('Accept', 'application/json');
    service.setHeaderParameter('Accept-Language', toAcceptLanguage(language));

    return service.sendRequest();
  }

  /*=================================================================
    PARSING
  =================================================================*/

  /*  The documented CompanyResource schema describes the inner object only - the live
      payload wraps it in `data`, so unwrap before reading any field. */
  private static CompanyInfo parseCompany(String body) {
    Map<String, Object> root = asMap(safeDeserialize(body));
    Map<String, Object> company = asMap(root.get('data'));
    if (company.isEmpty()) {
      // harkirat - tolerate an unwrapped payload in case the envelope ever changes
      company = root;
    }
    if (!company.containsKey('cbe_number') && !company.containsKey('denomination')) {
      throw new WSBE03_CbeApiException('CBE API response did not contain a company payload.');
    }

    Map<String, Object> address = asMap(company.get('address'));

    CompanyInfo info = new CompanyInfo();
    info.found = true;
    info.legalName = str(company.get('denomination'));
    info.commercialName = str(company.get('commercial_name'));
    info.legalForm = str(company.get('juridical_form'));
    info.registrationNumber = str(company.get('cbe_number'));
    info.vatNumber = String.isBlank(info.registrationNumber) ? '' : VAT_PREFIX + info.registrationNumber;

    info.street = composeStreet(address);
    info.postCode = str(address.get('post_code'));
    info.city = str(address.get('city'));
    info.country = resolveCountry(str(address.get('country_code')));

    return info;
  }

  /*  Builds "Grand-Place 1" from the parts. full_address is deliberately unused: it also
      carries post code, city and country, which would corrupt the street field. */
  private static String composeStreet(Map<String, Object> address) {
    List<String> parts = new List<String>();
    for (String key : new List<String>{ 'street', 'street_number', 'box' }) {
      String part = str(address.get(key));
      if (String.isNotBlank(part)) {
        parts.add(part.trim());
      }
    }
    return String.join(parts, ' ');
  }

  /*  Downstream code compares against the long form: getCorrectCity matches
      BE_Technical_Address__mdt.BE_Country__c, and validateAndConvertLead tests
      billingCountry == 'BELGIUM' to derive the country code. */
  private static String resolveCountry(String countryCode) {
    return String.isBlank(countryCode) || VAT_PREFIX.equalsIgnoreCase(countryCode)
      ? COUNTRY_LONG_FORM
      : countryCode.toUpperCase();
  }

  /*  Pulls errors[0].message out of the API's error envelope for a diagnosable log line */
  @TestVisible
  private static String extractApiError(String body) {
    try {
      Object errorList = asMap(safeDeserialize(body)).get('errors');
      List<Object> entries = errorList instanceof List<Object> ? (List<Object>) errorList : new List<Object>();
      if (!entries.isEmpty()) {
        String apiMessage = str(asMap(entries[0]).get('message'));
        if (String.isNotBlank(apiMessage)) {
          return apiMessage;
        }
      }
    } catch (Exception parseEx) {
      // harkirat - error body was not the documented shape, fall through to the raw body
    }
    return String.isBlank(body) ? 'no response body' : body.abbreviate(255);
  }

  /*=================================================================
    CACHE
  =================================================================*/

  /*  Org cache keeps the free plan's 2500/day quota away from retyped numbers on a public
      form. Every access is guarded: with no cache partition configured the lookup simply
      goes to the network instead of failing. */
  private static CompanyInfo readCache(String cbeNumber) {
    try {
      Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
      if (partition == null) {
        return null;
      }
      Object cached = partition.get(cacheKey(cbeNumber));
      return cached instanceof CompanyInfo ? (CompanyInfo) cached : null;
    } catch (Exception cacheEx) {
      return null;
    }
  }

  private static void writeCache(String cbeNumber, CompanyInfo info) {
    try {
      Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
      if (partition != null) {
        partition.put(cacheKey(cbeNumber), info, CACHE_TTL_SECONDS);
      }
    } catch (Exception cacheEx) {
      // harkirat - caching is best effort, never fail a lookup because of it
    }
  }

  // harkirat - platform cache keys must be alphanumeric only
  private static String cacheKey(String cbeNumber) {
    return 'cbe' + cbeNumber;
  }

  /*=================================================================
    HELPERS
  =================================================================*/

  /*  fr_BE -> fr, nl_BE -> nl, de_BE -> de. Drives denomination, juridical_form and
      activity descriptions in the response. */
  @TestVisible
  private static String toAcceptLanguage(String language) {
    if (String.isBlank(language)) {
      return DEFAULT_LANGUAGE;
    }
    String prefix = language.substringBefore('_').toLowerCase();
    return SUPPORTED_LANGUAGES.contains(prefix) ? prefix : DEFAULT_LANGUAGE;
  }

  @TestVisible
  private static String digitsOnly(String value) {
    return String.isBlank(value) ? '' : value.replaceAll('[^0-9]', '');
  }

  private static Object safeDeserialize(String body) {
    try {
      return JSON.deserializeUntyped(String.isBlank(body) ? '{}' : body);
    } catch (Exception parseEx) {
      throw new WSBE03_CbeApiException('CBE API returned a malformed JSON response.');
    }
  }

  private static Map<String, Object> asMap(Object value) {
    return value instanceof Map<String, Object> ? (Map<String, Object>) value : new Map<String, Object>();
  }

  // harkirat - schema leaves cbe_number untyped, so coerce rather than cast
  private static String str(Object value) {
    return value == null ? '' : String.valueOf(value);
  }

  private static String blankIfNull(String value) {
    return value == null ? '' : value;
  }
}
