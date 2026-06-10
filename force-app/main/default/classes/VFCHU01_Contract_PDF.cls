public class VFCHU01_Contract_PDF {
  String quoteID;
  String accountID;
  public String accountName { get; set; }
  public String legalForm { get; set; }
  public Address legalAddress;
  public String legalStreet { get; set; }
  public String legalZipCode { get; set; }
  public String legalCity { get; set; }
  public Address mailingAdress { get; set; }
  public String mailingStreet { get; set; }
  public String mailingZipCode { get; set; }
  public String mailingCity { get; set; }
  public String nationalCompanyID { get; set; }
  public String vatNumber { get; set; }
  public String bankAccountNumber { get; set; }

  public Contact headContact { get; set; }
  public Contact quoteContact { get; set; }
  public Contact financialCenterContact { get; set; }

  public Boolean hasFixedFee { get; set; }
  public Decimal ValueFixedFeeThreshold { get; set; }

  List<Account> accountList;
  List<Quote> quote;
  public List<Service> serviceList { get; set; }

  Map<String, List<QuoteLineItem>> SolutionMap;

  public VFCHU01_Contract_PDF() {
    bankAccountNumber = '';
    quoteID = ApexPages.currentPage().getParameters().get('id');

    SolutionMap = new Map<String, List<QuoteLineItem>>();
    serviceList = new List<Service>();

    for (Quote quoteInst : [
      SELECT
        AccountId,
        ContactId,
        Contact.Salutation,
        Contact.FirstName,
        Contact.MiddleName,
        Contact.LastName,
        Contact.Suffix,
        Contact.ER_Role__c,
        Contact.Phone,
        Contact.Email,
        Contact.MobilePhone,
        (
          SELECT id, Product2.ER_Solution__r.productCode, Product2.productCode, ER_Percentage__c, UnitPrice
          FROM QuoteLineItems
        )
      FROM Quote
      WHERE id = :quoteID
    ]) {
      accountID = quoteInst.AccountId;
      System.debug('###quoteInst accountID : ' + accountID);
      if (String.isNotBlank(quoteInst.ContactId)) {
        quoteContact = new Contact(
          Id = quoteInst.ContactId,
          Salutation = quoteInst.Contact.Salutation,
          FirstName = quoteInst.Contact.FirstName,
          MiddleName = quoteInst.Contact.MiddleName,
          LastName = quoteInst.Contact.LastName,
          Suffix = quoteInst.Contact.Suffix,
          Phone = quoteInst.Contact.Phone,
          Email = quoteInst.Contact.Email,
          MobilePhone = quoteInst.Contact.MobilePhone,
          ER_Role__c = quoteInst.Contact.ER_Role__c
        );

        System.debug('###OLA quoteContact : ' + quoteContact);
      }
      for (QuoteLineItem qli : quoteInst.QuoteLineItems) {
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        if (SolutionMap.containsKey(qli.Product2.ER_Solution__r.productCode)) {
          qliList = SolutionMap.get(qli.Product2.ER_Solution__r.productCode);
        }

        qliList.add(qli);
        SolutionMap.put(qli.Product2.ER_Solution__r.productCode, qliList);
      }
    }
    for (String solution : SolutionMap.keySet()) {
      Service serviceInst = new Service();
      serviceInst.solutionCode = solution;

      for (QuoteLineItem qli : SolutionMap.get(solution)) {
        if (String.isNotBlank(qli.Product2.productCode) && qli.Product2.productCode.containsIgnoreCase('FixedFee')) {
          serviceInst.serviceType = 'FixedFee';
          serviceInst.serviceCode = qli.Product2.productCode;
          serviceInst.value = qli.UnitPrice;
          hasFixedFee = true;
        } else if (
          String.isNotBlank(qli.Product2.productCode) && qli.Product2.productCode.containsIgnoreCase('Threshold')
        ) {
          ValueFixedFeeThreshold = qli.UnitPrice;
        } else if (
          String.isNotBlank(qli.Product2.productCode) &&
          qli.Product2.productCode.containsIgnoreCase('Part') &&
          serviceInst.serviceType != 'FixedFee'
        ) {
          serviceInst.serviceType = 'Participation';
          serviceInst.serviceCode = qli.Product2.productCode;
          serviceInst.value = qli.ER_Percentage__c;
        }
      }
      System.debug('###OLA serviceInst : ' + serviceInst);
      serviceList.add(serviceInst);
    }
    System.debug('###OLA serviceList : ' + serviceList);
    if (String.isNotBlank(accountID)) {
      for (Account account : [
        SELECT
          id,
          Name,
          ER_Legal_Form__c,
          BillingAddress,
          PersonMailingAddress,
          ER_Registration_Number__c,
          ER_VAT_Number__c,
          HU_HQ_Contact__r.Salutation,
          HU_HQ_Contact__r.FirstName,
          HU_HQ_Contact__r.MiddleName,
          HU_HQ_Contact__r.LastName,
          HU_HQ_Contact__r.Suffix,
          HU_HQ_Contact__r.ER_Role__c,
          HU_HQ_Contact__r.Phone,
          HU_HQ_Contact__r.Email,
          HU_HQ_Contact__r.MobilePhone,
          (
            SELECT
              id,
              ER_Bank_Account__r.ER_IBAN__c,
              ER_Contact__c,
              ER_Contact__r.Salutation,
              ER_Contact__r.FirstName,
              ER_Contact__r.MiddleName,
              ER_Contact__r.LastName,
              ER_Contact__r.Suffix,
              ER_Contact__r.ER_Role__c,
              ER_Contact__r.Phone,
              ER_Contact__r.Email,
              ER_Contact__r.MobilePhone
            FROM Financial_Centers__r
            ORDER BY createdDate ASC
          )
        FROM Account
        WHERE id = :accountID
      ]) {
        System.debug('###OLA account : ' + account);
        if (String.isNotBlank(account.HU_HQ_Contact__c)) {
          headContact = new Contact(
            Id = account.HU_HQ_Contact__c,
            Salutation = account.HU_HQ_Contact__r.Salutation,
            FirstName = account.HU_HQ_Contact__r.FirstName,
            MiddleName = account.HU_HQ_Contact__r.MiddleName,
            LastName = account.HU_HQ_Contact__r.LastName,
            Suffix = account.HU_HQ_Contact__r.Suffix,
            Phone = account.HU_HQ_Contact__r.Phone,
            Email = account.HU_HQ_Contact__r.Email,
            MobilePhone = account.HU_HQ_Contact__r.MobilePhone,
            ER_Role__c = account.HU_HQ_Contact__r.ER_Role__c
          );

          System.debug('###OLA headContact : ' + headContact);
        }

        accountName = account.Name;
        legalForm = account.ER_Legal_Form__c;
        legalAddress = account.BillingAddress;
        if (legalAddress != null) {
          legalStreet = legalAddress.getStreet();
          legalZipCode = legalAddress.getPostalCode();
          legalCity = legalAddress.getCity();
        }
        mailingAdress = account.PersonMailingAddress;
        if (mailingAdress != null) {
          mailingStreet = mailingAdress.getStreet();
          mailingZipCode = mailingAdress.getPostalCode();
          mailingCity = mailingAdress.getCity();
        }
        nationalCompanyID = account.ER_Registration_Number__c;
        vatNumber = account.ER_VAT_Number__c;
        for (ER_Financial_Center__c FC : account.Financial_Centers__r) {
          if (String.isNotBlank(FC.ER_Bank_Account__r.ER_IBAN__c) && String.isBlank(bankAccountNumber)) {
            bankAccountNumber = FC.ER_Bank_Account__r.ER_IBAN__c;
          }
          if (String.isNotBlank(FC.ER_Contact__c)) {
            financialCenterContact = new Contact(
              Id = FC.ER_Contact__c,
              Salutation = FC.ER_Contact__r.Salutation,
              FirstName = FC.ER_Contact__r.FirstName,
              MiddleName = FC.ER_Contact__r.MiddleName,
              LastName = FC.ER_Contact__r.LastName,
              Suffix = FC.ER_Contact__r.Suffix,
              Phone = FC.ER_Contact__r.Phone,
              Email = FC.ER_Contact__r.Email,
              MobilePhone = FC.ER_Contact__r.MobilePhone,
              ER_Role__c = FC.ER_Contact__r.ER_Role__c
            );

            System.debug('###OLA financialCenterContact : ' + financialCenterContact);
          }
        }
      }
    }
  }

  public class service {
    public String serviceType { get; set; }
    public String serviceCode { get; set; }
    public String solutionCode { get; set; }
    public Decimal Value { get; set; }
    public service() {
    }
  }
}