public class VFCCZ01_Contract_PDF {
  String quoteId;
  String accountId;
  String ownerId;
  String contractId;
  public Address legalAddress;
  public String accountName { get; set; }
  public String legalStreet { get; set; }
  public String legalZipCode { get; set; }
  public String legalCity { get; set; }
  public String vatNumber { get; set; }
  public String companyRegistrationNumber { get; set; }
  public String sysdate { get; set; }
  public String ownerName { get; set; }
  public Boolean indexation { get; set; }
  public String iban { get; set; }
  public Contact financialCenterContact { get; set; }
  public Map<String, List<QuoteLineItem>> SolutionMap { get; set; }
  public Map<String, QuoteLineItem> serviceMap2 { get; set; }
  public Map<String, pricebookentry> ServiceMap { get; set; }
  public Decimal percentage { get; set; }
  public Decimal minFee { get; set; }
  public String productCode { get; set; }
  public String priceBookId;
  public Map<String, serviceValue> serviceValueMap { get; set; }

  public VFCCZ01_Contract_PDF() {
    iban = '';
    quoteId = ApexPages.currentPage().getParameters().get('id');
    SolutionMap = new Map<String, List<QuoteLineItem>>();
    serviceMap2 = new Map<String, QuoteLineItem>();
    ServiceMap = new Map<String, pricebookentry>();
    serviceValueMap = new Map<String, serviceValue>();
    sysdate = Date.today().format();

    for (Quote insertedQuote : [
      SELECT
        AccountId,
        ContractId,
        OwnerId,
        PriceBook2Id,
        ER_Indexation__c,
        (
          SELECT
            id,
            Product2.ER_Solution__r.productCode,
            Product2.productCode,
            ER_Percentage__c,
            LineNumber,
            Product2.ER_Minimum_Fee__c,
            ER_Minimum_Fee__c
          FROM QuoteLineItems
        )
      FROM Quote
      WHERE id = :quoteId
    ]) {
      priceBookId = insertedQuote.PriceBook2Id;
      accountId = insertedQuote.AccountId;
      contractId = insertedQuote.ContractId;
      ownerId = insertedQuote.OwnerId;
      indexation = insertedQuote.ER_Indexation__c;

      for (QuoteLineItem qli : insertedQuote.QuoteLineItems) {
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        if (SolutionMap.containsKey(qli.Product2.ER_Solution__r.productCode)) {
          productCode = qli.Product2.productCode;
          qliList = SolutionMap.get(qli.Product2.ER_Solution__r.productCode);
        }

        qliList.add(qli);
        SolutionMap.put(qli.Product2.ER_Solution__r.productCode, qliList);
        serviceMap2.put(qli.Product2.productCode, qli);
      }
    }
    List<Pricebookentry> serviceList = [
      SELECT
        id,
        Name,
        ER_Configuration__c,
        UnitPrice,
        ER_Approval_Trigger_Value__c,
        product2.Description,
        product2.ER_solution__c,
        product2.ER_solution__r.Name,
        product2.ER_Solution_Code__c,
        pricebook2.ER_Business_Unit__c,
        ER_Percentage__c,
        isactive,
        CurrencyIsoCode,
        product2.ER_Minimum_Fee__c,
        Product2.productCode
      FROM pricebookentry
      WHERE product2.ER_Type__c = 'service' AND pricebook2Id = :priceBookId AND isactive = TRUE
      ORDER BY product2.ER_solution__r.ER_Line_Order__c, product2.ER_Line_Order__c ASC
    ];
    for (Pricebookentry pbe : serviceList) {
      ServiceMap.put(pbe.Product2.productCode, pbe);
    }
    System.debug('####OLA SolutionMap: ' + SolutionMap);
    System.debug('####OLA ServiceMap: ' + ServiceMap);

    serviceValue sv;
    for (String serviceCode : ServiceMap.keySet()) {
      sv = new serviceValue();
      if (serviceMap2.containsKey(serviceCode)) {
        sv.value = serviceMap2.get(serviceCode).ER_Percentage__c;
      } else {
        sv.value = ServiceMap.get(serviceCode).ER_Percentage__c;
      }
      serviceValueMap.put(serviceCode, sv);
    }
    /*for (String solution : SolutionMap.keySet()) {

			for (QuoteLineItem qli : SolutionMap.get(solution)) {

				if (qli.ER_Percentage__c != null) {

					percentage = qli.ER_Percentage__c;

				} 
				if (qli.Product2.ER_Minimum_Fee__c != null) {

					minFee = qli.Product2.ER_Minimum_Fee__c;

				} 
			}
		}*/

    for (User owner : [SELECT Id, Name FROM User WHERE Id = :ownerId]) {
      ownerName = owner.Name;
    }

    if (String.isNotBlank(accountId)) {
      for (Account account : [
        SELECT
          id,
          Name,
          BillingAddress,
          ER_Registration_Number__c,
          ER_VAT_Number__c,
          (
            SELECT
              id,
              ER_Bank_Account__r.ER_IBAN__c,
              ER_Contact__c,
              ER_Contact__r.FirstName,
              ER_Contact__r.MiddleName,
              ER_Contact__r.LastName,
              ER_Contact__r.Phone,
              ER_Contact__r.Email
            FROM Financial_Centers__r
            ORDER BY createdDate ASC
          )
        FROM Account
        WHERE id = :accountId
      ]) {
        accountName = account.Name;
        vatNumber = account.ER_VAT_Number__c;
        companyRegistrationNumber = account.ER_Registration_Number__c;
        legalAddress = account.BillingAddress;
        if (legalAddress != null) {
          legalStreet = legalAddress.getStreet();
          legalZipCode = legalAddress.getPostalCode();
          legalCity = legalAddress.getCity();
        }

        for (ER_Financial_Center__c FC : account.Financial_Centers__r) {
          if (String.isNotBlank(FC.ER_Bank_Account__r.ER_IBAN__c) && String.isBlank(iban)) {
            iban = FC.ER_Bank_Account__r.ER_IBAN__c;
          }

          if (String.isNotBlank(FC.ER_Contact__c)) {
            financialCenterContact = new Contact(
              Id = FC.ER_Contact__c,
              FirstName = FC.ER_Contact__r.FirstName,
              MiddleName = FC.ER_Contact__r.MiddleName,
              LastName = FC.ER_Contact__r.LastName,
              Phone = FC.ER_Contact__r.Phone,
              Email = FC.ER_Contact__r.Email
            );
          }
        }
      }
    }
  }
  public class serviceValue {
    public Decimal value { get; set; }
    public Decimal defaultValue { get; set; }
    public Decimal minimumValue { get; set; }
    public Decimal defaultMinimumValue { get; set; }

    public serviceValue() {
    }
  }
}