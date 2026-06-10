public class VFCSK01_Contract_PDF {
  public class tableDisplayer {
    public string code { get; set; }
    public String price { get; set; }
    public String totalPrice { get; set; }
    public string name { get; set; }
    public string discount { get; set; }
    public string unit { get; set; }
    public string unit2 { get; set; } //only for TR_010
  }

  public class Pack {
    public List<tableDisplayer> QuoteServicesDiscounted { get; set; }
    public List<tableDisplayer> QuoteServicesFirst { get; set; }
    public List<tableDisplayer> QuoteServicesVydanie { get; set; }
    public List<tableDisplayer> QuoteServicesDorucenie { get; set; }
    public List<tableDisplayer> QuoteServicesIne { get; set; }
    public List<tableDisplayer> QuoteServicesSluzby { get; set; }
    //public List<QuoteLineItem> QuoteServicesDiscounted { get; set;}
    //public List<QuoteLineItem> QuoteServicesFirst { get; set;}
    //public List<QuoteLineItem> QuoteServicesVydanie { get; set;}
    //public List<QuoteLineItem> QuoteServicesDorucenie { get; set;}
    //public List<QuoteLineItem> QuoteServicesIne { get; set;}
    //public List<QuoteLineItem> QuoteServicesSluzby { get; set;}
    public Map<string, string> QuoteServicesMapped { get; set; }
    public Boolean Discount { get; set; }
    public string P01 { get; set; }
    public string P02 { get; set; }
    public string P03 { get; set; }
    public string P04 { get; set; }
    public string P05 { get; set; }
    public boolean ThereIsService { get; set; }
    public boolean FirstDoc { get; set; } //to know if I should call a page break
    public string minFee1 { get; set; }
    public string minFee2 { get; set; }
    public string minFee3 { get; set; }
  }

  public List<Pack> Docs { get; set; }
  public List<QuoteLineItem> QuoteServices { get; set; }
  public List<Boolean> oneOrTwo { get; set; }
  public boolean show { get; set; }
  public boolean showVoucher { get; set; }
  public string PaymentTerm { get; set; }
  public string PaymentTermVoucher { get; set; }
  public String quoteId;

  //cover stuff
  String accountId;
  String ownerId;
  String contractId;
  public Address legalAddress;
  public String accountName { get; set; }
  public String legalStreet { get; set; }
  public String legalZipCode { get; set; }
  public String legalCity { get; set; }
  public String vatNumber { get; set; }
  public String otherFiscalId { get; set; }
  public String companyRegistrationNumber { get; set; }
  public String sysdate { get; set; }
  public String ownerName { get; set; }
  public String ownerTitle { get; set; }
  public Boolean indexation { get; set; }
  public String iban { get; set; }
  public String bic { get; set; }
  public String regNumberText { get; set; }
  public String quotenumber { get; set; }
  public Contact financialCenterContact { get; set; }
  public Map<String, List<QuoteLineItem>> SolutionMap { get; set; }
  public Map<String, QuoteLineItem> serviceMap2 { get; set; }
  public Map<String, pricebookentry> ServiceMap { get; set; }
  //public Decimal percentage { get; set; }
  //public Decimal minFee { get; set; }
  public String productCode { get; set; }
  public String priceBookId;
  //end of cover stuff

  public VFCSK01_Contract_PDF() {
    iban = '';
    bic = '';
    regNumberText = '';
    SolutionMap = new Map<String, List<QuoteLineItem>>();
    serviceMap2 = new Map<String, QuoteLineItem>();
    ServiceMap = new Map<String, pricebookentry>();

    quoteId = ApexPages.currentPage().getParameters().get('id');

    sysdate = Date.today().format();

    for (Quote insertedQuote : [
      SELECT
        AccountId,
        ContractId,
        OwnerId,
        QuoteNumber,
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
      quotenumber = insertedQuote.QuoteNumber;
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
    for (Account acc : [SELECT Id, SK_RegistrationNumberText__c FROM Account WHERE Id = :accountId]) {
      regNumberText = acc.SK_RegistrationNumberText__c;
    }

    for (User owner : [SELECT Id, Name, Title FROM User WHERE Id = :ownerId]) {
      ownerName = owner.Name;
      ownerTitle = owner.Title;
    }

    if (String.isNotBlank(accountId)) {
      for (Account account : [
        SELECT
          id,
          Name,
          ER_Legal_Name__c,
          BillingAddress,
          ER_Registration_Number__c,
          ER_VAT_Number__c,
          ER_Other_Fiscal_ID__c,
          (
            SELECT
              id,
              ER_Bank_Account__r.ER_IBAN__c,
              ER_Bank_Account__r.ER_BIC__c,
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
        //accountName = account.Name;
        accountName = account.ER_Legal_Name__c;
        vatNumber = account.ER_VAT_Number__c;
        otherFiscalId = account.ER_Other_Fiscal_ID__c;
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
          if (String.isNotBlank(FC.ER_Bank_Account__r.ER_BIC__c) && String.isBlank(bic)) {
            bic = FC.ER_Bank_Account__r.ER_BIC__c;
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

    Quote Q = [SELECT ID, ER_PaymentTerms__c, SK_Payment_Terms_Voucher__c FROM Quote WHERE id = :quoteId];

    if (Q.ER_PaymentTerms__c != null && Q.ER_PaymentTerms__c != '') {
      show = true;
      PaymentTerm = Q.ER_PaymentTerms__c;
      // transco payment terms
      switch on PaymentTerm {
        when 'At reception of invoice' {
          PaymentTerm = '0';
        }
        when '3 days after invoice issuance' {
          PaymentTerm = '3';
        }
        when '4 days after invoice issuance' {
          PaymentTerm = '4';
        }
        when '5 days after invoice issuance' {
          PaymentTerm = '5';
        }
        when '7 days after invoice issuance' {
          PaymentTerm = '7';
        }
        when '10 days after invoice issuance' {
          PaymentTerm = '10';
        }
        when '14 days after invoice issuance' {
          PaymentTerm = '14';
        }
        when '15 days after invoice issuance' {
          PaymentTerm = '15';
        }
        when '20 days after invoice issuance' {
          PaymentTerm = '20';
        }
        when '21 days after invoice issuance' {
          PaymentTerm = '21';
        }
        when '30 days after invoice issuance' {
          PaymentTerm = '30';
        }
        when '45 days after invoice issuance' {
          PaymentTerm = '45';
        }
        when '50 days after invoice issuance' {
          PaymentTerm = '50';
        }
        when '60 days after invoice issuance' {
          PaymentTerm = '60';
        }
        when '90 days after invoice issuance' {
          PaymentTerm = '90';
        }
        when '100 days after invoice issuance' {
          PaymentTerm = '100';
        }
      }
      //
    } else {
      show = false;
    }

    if (Q.SK_Payment_Terms_Voucher__c != null && Q.SK_Payment_Terms_Voucher__c != '') {
      showVoucher = true;
      //PaymentTerm = Q.SK_Payment_Terms_Voucher__c;
      PaymentTermVoucher = Q.SK_Payment_Terms_Voucher__c;
    } else {
      showVoucher = false;
    }
    QuoteServices = [
      SELECT
        ID,
        QuoteId,
        Product2.Name,
        ListPrice,
        Discount,
        TotalPrice,
        UnitPrice,
        ER_Minimum_Fee__c,
        Product2.ProductCode,
        Product2.ER_Minimum_Fee__c,
        ER_Percentage__c
      FROM QuoteLineItem
      WHERE QuoteId = :quoteId
    ];
    List<string> Codes = new List<string>();
    set<string> cleanDocType = new Set<string>();
    if (QuoteServices.size() == 0) {
      //    ThereIsService = false;
    } else {
      //    ThereIsService = true;
      for (QuoteLineItem QS : QuoteServices) {
        Codes.add(QS.Product2.ProductCode);
      }
      integer b = 0;
      for (string a : Codes) {
        cleanDocType.add(a.substringBetween('ERSK_', '_'));
      }
    }

    oneOrTwo = new List<Boolean>();

    if (cleanDocType.contains('TRV')) {
      //0
      oneOrTwo.add(true);
    } else
      oneOrTwo.add(false);
    if (cleanDocType.contains('HC')) {
      //1
      oneOrTwo.add(true);
    } else
      oneOrTwo.add(false);
    if (cleanDocType.contains('TR')) {
      //2
      oneOrTwo.add(true);
    } else
      oneOrTwo.add(false);
    if (cleanDocType.contains('TC')) {
      //3
      oneOrTwo.add(true);
    } else
      oneOrTwo.add(false);
    if (cleanDocType.contains('TM')) {
      //4
      oneOrTwo.add(true);
    } else
      oneOrTwo.add(false);
    if (cleanDocType.contains('EB')) {
      //5
      oneOrTwo.add(true);
    } else
      oneOrTwo.add(false);

    Docs = new List<Pack>();

    integer first;

    for (integer i = 0; i <= oneOrTwo.size(); i++) {
      Pack p = new Pack();
      switch on i {
        when 0 {
          if (oneOrTwo[i] == true) {
            p = new Pack();
            first = 0;
            p.firstDoc = true;
            p.ThereIsService = false;
            p.Discount = false;
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.contains('TRV')) {
                  p.ThereIsService = true;
                  if (
                    !String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)) &&
                    (QS.Product2.ProductCode == 'ERSK_TRV_001' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_002')
                  ) {
                    p.P03 = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',') + ' EUR';
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TRV_001' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_002' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    if (!String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TRV_001') {
                      p.P01 = string.valueof(QS.ListPrice.setScale(2)).replace('.', ',');
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    } else if (
                      !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TRV_002'
                    ) {
                      p.P02 = string.valueof(QS.ListPrice.setScale(2)).replace('.', ',');
                      tD.unit = 'EUR';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    } else if (QS.Product2.ProductCode == 'ERSK_TRV_013') {
                      tD.unit = '%';
                      if (!String.isBlank(string.valueof(QS.ER_Percentage__c)))
                        tD.price = string.valueof(QS.ER_Percentage__c.setScale(2)).replace('.', ',');
                    }
                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.quoteServicesFirst.add(tDMin);
                    }
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TRV_003' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_008' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_009'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    if (QS.Product2.ProductCode == 'ERSK_TRV_003') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                          tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                      } else {
                        tdMin.price = '0,00';
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }
                    p.QuoteServicesVydanie.add(tD);
                    if (p.minFee2 == tD.code) {
                      p.QuoteServicesVydanie.add(tDMin);
                    }
                  } else if (QS.Product2.ProductCode == 'ERSK_TRV_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_TRV_010' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_012' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_011'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesIne.add(tD);
                  }
                  if (QS.discount != 0 && QS.discount != null) {
                    p.Discount = true;
                    if (
                      QS.Product2.ProductCode == 'ERSK_TRV_001' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_002' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_003' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_008' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_009' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_005' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_010' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_012' ||
                      QS.Product2.ProductCode == 'ERSK_TRV_011'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      if (!String.isBlank(string.valueof(QS.ListPrice)))
                        tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                      tD.code = QS.Product2.ProductCode;
                      if (!String.isBlank(string.valueof(QS.discount.SetScale(2))))
                        tD.discount = string.valueof(QS.discount.SetScale(2)).replace('.', ',') + '%';
                      if (!String.isBlank(string.valueof(QS.UnitPrice.SetScale(2))))
                        tD.totalPrice = string.valueof(QS.UnitPrice.SetScale(2)).replace('.', ',');
                      if (QS.Product2.ProductCode == 'ERSK_TRV_001') {
                        tD.unit = '%';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                      }
                      p.QuoteServicesDiscounted.add(tD);
                    }
                  }
                }
              }
            }
          }
          Docs.add(p);
        }
        when 1 {
          if (oneOrTwo[i] == true) {
            p = new Pack();
            if (first == null) {
              first = 1;
              p.firstDoc = true;
            } else {
              p.firstDoc = false;
            }
            p.ThereIsService = false;
            p.Discount = false;
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.contains('HC')) {
                  p.ThereIsService = true;
                  if (
                    !String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)) &&
                    (QS.Product2.ProductCode == 'ERSK_HC_001' ||
                    QS.Product2.ProductCode == 'ERSK_HC_002')
                  ) {
                    p.P03 = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',') + ' EUR';
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_HC_001' ||
                    QS.Product2.ProductCode == 'ERSK_HC_002' ||
                    QS.Product2.ProductCode == 'ERSK_HC_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    if (!String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_HC_001') {
                      p.P01 = string.valueof(QS.ListPrice.setScale(2)).replace('.', ',');
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    } else if (
                      !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_HC_002'
                    ) {
                      p.P02 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                      tD.unit = 'EUR';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    } else if (QS.Product2.ProductCode == 'ERSK_HC_013') {
                      tD.unit = '%';
                      if (!String.isBlank(string.valueof(QS.ER_Percentage__c)))
                        tD.price = string.valueof(QS.ER_Percentage__c.setScale(2)).replace('.', ',');
                    }
                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.quoteServicesFirst.add(tDMin);
                    }
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_HC_003' ||
                    QS.Product2.ProductCode == 'ERSK_HC_008' ||
                    QS.Product2.ProductCode == 'ERSK_HC_009'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    if (QS.Product2.ProductCode == 'ERSK_HC_003') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                          tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                      } else {
                        tdMin.price = '0,00';
                      }
                      tDMin.unit = 'EUR';
                      p.minFee2 = QS.Product2.ProductCode;
                    }
                    p.QuoteServicesVydanie.add(tD);
                    if (p.minFee2 == td.code) {
                      p.QuoteServicesVydanie.add(tDMin);
                    }
                  } else if (QS.Product2.ProductCode == 'ERSK_HC_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_HC_010' ||
                    QS.Product2.ProductCode == 'ERSK_HC_012' ||
                    QS.Product2.ProductCode == 'ERSK_HC_011'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesIne.add(tD);
                  }
                  if (QS.discount != 0 && QS.discount != null) {
                    p.Discount = true;
                    if (
                      QS.Product2.ProductCode == 'ERSK_HC_001' ||
                      QS.Product2.ProductCode == 'ERSK_HC_002' ||
                      QS.Product2.ProductCode == 'ERSK_HC_003' ||
                      QS.Product2.ProductCode == 'ERSK_HC_008' ||
                      QS.Product2.ProductCode == 'ERSK_HC_009' ||
                      QS.Product2.ProductCode == 'ERSK_HC_005' ||
                      QS.Product2.ProductCode == 'ERSK_HC_010' ||
                      QS.Product2.ProductCode == 'ERSK_HC_012' ||
                      QS.Product2.ProductCode == 'ERSK_HC_011'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      if (!String.isBlank(string.valueof(QS.ListPrice)))
                        tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                      tD.code = QS.Product2.ProductCode;
                      if (!String.isBlank(string.valueof(QS.discount.SetScale(2))))
                        tD.discount = string.valueof(QS.discount.SetScale(2)).replace('.', ',') + ' %';
                      if (!String.isBlank(string.valueof(QS.UnitPrice.SetScale(2))))
                        tD.totalPrice = string.valueof(QS.UnitPrice.SetScale(2)).replace('.', ',');
                      if (QS.Product2.ProductCode == 'ERSK_HC_001') {
                        tD.unit = '%';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                      }
                      p.QuoteServicesDiscounted.add(tD);
                    }
                  }
                }
              }
            }
          }
          Docs.add(p);
        }
        when 3 {
          if (oneOrTwo[i] == true) {
            p = new Pack();
            if (first == null) {
              first = 3;
              p.firstDoc = true;
            } else {
              p.firstDoc = false;
            }
            p.ThereIsService = false;
            p.Discount = false;
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.minFee3 = '0';
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            p.QuoteServicesMapped = new Map<string, string>();
            p.QuoteServicesMapped.put('ERSK_TM_014', '');
            p.QuoteServicesMapped.put('ERSK_TM_015', '');
            p.QuoteServicesMapped.put('ERSK_TM_016', '');
            p.QuoteServicesMapped.put('ERSK_TM_017', '');
            p.QuoteServicesMapped.put('ERSK_TM_018', '');
            p.QuoteServicesMapped.put('ERSK_TM_019', '');
            p.QuoteServicesMapped.put('ERSK_TM_016_minFee', '');
            p.QuoteServicesMapped.put('ERSK_TM_018_minFee', '');
            p.QuoteServicesMapped.put('ERSK_TC_014', '');
            p.QuoteServicesMapped.put('ERSK_TC_015', '');
            p.QuoteServicesMapped.put('ERSK_TC_016', '');
            p.QuoteServicesMapped.put('ERSK_TC_017', '');
            p.QuoteServicesMapped.put('ERSK_TC_018', '');
            p.QuoteServicesMapped.put('ERSK_TC_019', '');
            p.QuoteServicesMapped.put('ERSK_TC_016_minFee', '');
            p.QuoteServicesMapped.put('ERSK_TC_018_minFee', '');
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.contains('TC')) {
                  p.ThereIsService = true;

                  if (
                    !String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)) &&
                    (QS.Product2.ProductCode == 'ERSK_TC_001' ||
                    QS.Product2.ProductCode == 'ERSK_TC_002')
                  ) {
                    p.P01 = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',') + ' EUR';
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TC_004'
                  ) {
                    p.P05 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TC_003'
                  ) {
                    p.P02 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TC_005'
                  ) {
                    p.P03 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TC_006'
                  ) {
                    p.P04 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  }

                  if (
                    QS.Product2.ProductCode == 'ERSK_TC_001' ||
                    QS.Product2.ProductCode == 'ERSK_TC_002' ||
                    QS.Product2.ProductCode == 'ERSK_TC_020'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    if (QS.Product2.ProductCode == 'ERSK_TC_001' || QS.Product2.ProductCode == 'ERSK_TC_020') {
                      tD.unit = '%';
                      //tD.price = QS.ER_Percentage__c;
                    } else {
                      tD.unit = 'EUR';
                    }

                    if (
                      QS.Product2.ProductCode == 'ERSK_TC_001' ||
                      QS.Product2.ProductCode == 'ERSK_TC_002' &&
                      p.minFee1 == '0'
                    ) {
                      tDMin.name = 'Minimálny poplatok (administratívny)';
                      if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                        tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                      if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                        tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                      tDMin.unit = 'EUR';
                      p.minFee1 = QS.Product2.ProductCode;
                    }
                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == QS.Product2.ProductCode) {
                      p.QuoteServicesFirst.add(tDMin);
                    }
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_TC_008' ||
                    QS.Product2.ProductCode == 'ERSK_TC_009' ||
                    QS.Product2.ProductCode == 'ERSK_TC_010' ||
                    QS.Product2.ProductCode == 'ERSK_TC_011' ||
                    QS.Product2.ProductCode == 'ERSK_TC_012' ||
                    QS.Product2.ProductCode == 'ERSK_TC_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesVydanie.add(tD);
                  } else if (QS.Product2.ProductCode == 'ERSK_TC_014' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_014',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (QS.Product2.ProductCode == 'ERSK_TC_015' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_015',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_TC_016' &&
                    QS.listPrice != null &&
                    QS.ER_Minimum_Fee__c != null
                  ) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_016',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_016_minFee',
                      string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',')
                    );
                  } else if (QS.Product2.ProductCode == 'ERSK_TC_019' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_019',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (QS.Product2.ProductCode == 'ERSK_TC_017' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_017',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_TC_018' &&
                    QS.listPrice != null &&
                    QS.ER_Minimum_Fee__c != null
                  ) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_018',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                    p.QuoteServicesMapped.put(
                      'ERSK_TC_018_minFee',
                      string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',')
                    );
                  }
                  if (QS.discount != 0 && QS.discount != null) {
                    p.Discount = true;
                    if (
                      QS.Product2.ProductCode == 'ERSK_TC_001' ||
                      QS.Product2.ProductCode == 'ERSK_TC_002' ||
                      QS.Product2.ProductCode == 'ERSK_TC_004' ||
                      QS.Product2.ProductCode == 'ERSK_TC_003' ||
                      QS.Product2.ProductCode == 'ERSK_TC_005' ||
                      QS.Product2.ProductCode == 'ERSK_TC_006' ||
                      QS.Product2.ProductCode == 'ERSK_TC_008' ||
                      QS.Product2.ProductCode == 'ERSK_TC_009' ||
                      QS.Product2.ProductCode == 'ERSK_TC_010' ||
                      QS.Product2.ProductCode == 'ERSK_TC_011' ||
                      QS.Product2.ProductCode == 'ERSK_TC_012' ||
                      QS.Product2.ProductCode == 'ERSK_TC_013' ||
                      QS.Product2.ProductCode == 'ERSK_TC_014' ||
                      QS.Product2.ProductCode == 'ERSK_TC_015' ||
                      QS.Product2.ProductCode == 'ERSK_TC_016' ||
                      QS.Product2.ProductCode == 'ERSK_TC_019' ||
                      QS.Product2.ProductCode == 'ERSK_TC_017' ||
                      QS.Product2.ProductCode == 'ERSK_TC_018' ||
                      QS.Product2.ProductCode == 'ERSK_TC_022'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      if (!String.isBlank(string.valueof(QS.ListPrice)))
                        tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                      tD.code = QS.Product2.ProductCode;
                      if (!String.isBlank(string.valueof(QS.discount.SetScale(2))))
                        tD.discount = string.valueof(QS.discount.SetScale(2)).replace('.', ',') + '%';
                      if (!String.isBlank(string.valueof(QS.UnitPrice.SetScale(2))))
                        tD.totalPrice = string.valueof(QS.UnitPrice.SetScale(2)).replace('.', ',');
                      if (
                        QS.Product2.ProductCode == 'ERSK_TC_001' ||
                        QS.Product2.ProductCode == 'ERSK_TC_015' ||
                        QS.Product2.ProductCode == 'ERSK_TC_018'
                      ) {
                        tD.unit = '%';
                      } else if (
                        QS.Product2.ProductCode == 'ERSK_TC_008' ||
                        QS.Product2.ProductCode == 'ERSK_TC_009' ||
                        QS.Product2.ProductCode == 'ERSK_TC_010' ||
                        QS.Product2.ProductCode == 'ERSK_TC_011' ||
                        QS.Product2.ProductCode == 'ERSK_TC_012' ||
                        QS.Product2.ProductCode == 'ERSK_TC_013'
                      ) {
                        tD.unit = 'EUR/kus';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (
                        QS.Product2.ProductCode == 'ERSK_TC_001' ||
                        QS.Product2.ProductCode == 'ERSK_TC_002' &&
                        p.minFee1 == '0'
                      ) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                          tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                          tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                      if (QS.Product2.ProductCode == 'ERSK_TC_016' || QS.Product2.ProductCode == 'ERSK_TC_018') {
                        tDMin.name = QS.Product2.Name + ' – minimálny poplatok';
                        tDMin.unit = 'EUR';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.code = QS.Product2.ProductCode;
                        if (QS.Product2.ProductCode == 'ERSK_TC_016') {
                          p.minFee2 = QS.Product2.ProductCode;
                        } else {
                          p.minFee3 = QS.Product2.ProductCode;
                        }
                      }
                      p.QuoteServicesDiscounted.add(tD);
                    }
                  }
                }
              }
            }
          }
          Docs.add(p);
        }
        when 2 {
          if (oneOrTwo[i] == true) {
            p = new Pack();
            if (first == null) {
              first = 2;
              p.firstDoc = true;
            } else {
              p.firstDoc = false;
            }
            p.ThereIsService = false;
            p.Discount = false;
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.minFee3 = '0';
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            P.QuoteServicesSluzby = new List<tableDisplayer>();
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.equals('TR')) {
                  p.ThereIsService = true;
                  if (
                    QS.Product2.ProductCode == 'ERSK_TR_001' ||
                    QS.Product2.ProductCode == 'ERSK_TR_002' ||
                    QS.Product2.ProductCode == 'ERSK_TR_003' ||
                    QS.Product2.ProductCode == 'ERSK_TR_016'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    if (QS.Product2.ProductCode == 'ERSK_TR_001') {
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    } else if (QS.Product2.ProductCode == 'ERSK_TR_002' && p.minFee1 == '0') {
                      tDMin.name = 'Minimálny poplatok (administratívny)';
                      if (QS.ER_Minimum_Fee__c != null) {
                        if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                          tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                      } else {
                        tdMin.price = '0,00';
                      }
                      tDMin.unit = 'EUR';
                      tD.unit = 'EUR';
                      p.minFee1 = QS.Product2.ProductCode;
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TR_016') {
                      tD.unit = '%';
                      if (!String.isBlank(string.valueof(QS.ER_Percentage__c)))
                        tD.price = string.valueof(QS.ER_Percentage__c.setScale(2)).replace('.', ',');
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TR_003' || QS.Product2.ProductCode == 'ERSK_TR_002') {
                      tD.unit = 'EUR';
                    }

                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.quoteServicesFirst.add(tDMin);
                    }
                  }
                  if (
                    !String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)) &&
                    (QS.Product2.ProductCode == 'ERSK_TR_001' ||
                    QS.Product2.ProductCode == 'ERSK_TR_002')
                  ) {
                    p.P03 = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',') + ' EUR';
                  }

                  if (!String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TR_001') {
                    p.P01 = string.valueof(QS.ListPrice.setScale(2)).replace('.', ',');
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TR_002'
                  ) {
                    p.P02 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');

                    //}else if(QS.Product2.ProductCode == 'ERSK_TR_020'){ p.P04 = string.valueof(Qs.ListPrice);
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TR_003'
                  ) {
                    p.P04 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TR_004' || QS.Product2.ProductCode == 'ERSK_TR_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesVydanie.add(tD);
                  } else if (QS.Product2.ProductCode == 'ERSK_TR_008' || QS.Product2.ProductCode == 'ERSK_TR_009') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  } else if (QS.Product2.ProductCode == 'ERSK_TR_010') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = '% z celkovej Hodnoty TR poukážok';
                    p.QuoteServicesIne.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TR_013' ||
                    QS.Product2.ProductCode == 'ERSK_TR_015' ||
                    QS.Product2.ProductCode == 'ERSK_TR_011' ||
                    QS.Product2.ProductCode == 'ERSK_TR_012' ||
                    QS.Product2.ProductCode == 'ERSK_TR_014'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    if (QS.Product2.ProductCode == 'ERSK_TR_013') {
                      tD.unit = 'EUR za 1 ks';
                      if (p.minFee2 == '0') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        p.minFee2 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                    } else if (QS.Product2.ProductCode == 'ERSK_TR_014') {
                      tD.unit = '% z celkového súčtu Hodnôt TR poukážok vrátených Klientom';
                      if (p.minFee3 == '0') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        p.minFee3 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                    } else {
                      tD.unit = 'EUR';
                    }
                    p.QuoteServicesSluzby.add(tD);
                    if (p.minFee2 == tD.code || p.minFee3 == tD.code) {
                      p.QuoteServicesSluzby.add(tDMin);
                    }
                  }

                  if (QS.discount != 0 && QS.discount != null) {
                    p.Discount = true;
                    if (
                      QS.Product2.ProductCode == 'ERSK_TR_001' ||
                      QS.Product2.ProductCode == 'ERSK_TR_002' ||
                      QS.Product2.ProductCode == 'ERSK_TR_004' ||
                      QS.Product2.ProductCode == 'ERSK_TR_003' ||
                      QS.Product2.ProductCode == 'ERSK_TR_005' ||
                      QS.Product2.ProductCode == 'ERSK_TR_008' ||
                      QS.Product2.ProductCode == 'ERSK_TR_009' ||
                      QS.Product2.ProductCode == 'ERSK_TR_010' ||
                      QS.Product2.ProductCode == 'ERSK_TR_013' ||
                      QS.Product2.ProductCode == 'ERSK_TR_015' ||
                      QS.Product2.ProductCode == 'ERSK_TR_011' ||
                      QS.Product2.ProductCode == 'ERSK_TR_012' ||
                      QS.Product2.ProductCode == 'ERSK_TR_014' ||
                      QS.Product2.ProductCode == 'ERSK_TR_017'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      if (!String.isBlank(string.valueof(QS.ListPrice)))
                        tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                      tD.code = QS.Product2.ProductCode;
                      if (!String.isBlank(string.valueof(QS.discount.SetScale(2))))
                        tD.discount = string.valueof(QS.discount.SetScale(2)).replace('.', ',') + '%';
                      if (!String.isBlank(string.valueof(QS.UnitPrice.SetScale(2))))
                        tD.totalPrice = string.valueof(QS.UnitPrice.SetScale(2)).replace('.', ',');
                      if (QS.Product2.ProductCode == 'ERSK_TR_001') {
                        tD.unit = '%';
                        tD.unit2 = '%';
                      } else if (QS.Product2.ProductCode == 'ERSK_TR_010') {
                        tD.unit = '% z celkovej Hodnoty TR poukážok';
                        tD.unit2 = '%';
                      } else if (QS.Product2.ProductCode == 'ERSK_TR_013') {
                        tD.unit = 'EUR za 1 ks';
                        tD.unit2 = 'EUR za 1 ks';
                      } else if (QS.Product2.ProductCode == 'ERSK_TR_014') {
                        tD.unit = '% z celkového súčtu Hodnôt TR poukážok vrátených Klientom';
                        tD.unit2 = '% z celkového súčtu Hodnôt TR poukážok vrátených Klientom';
                      } else {
                        tD.unit = 'EUR';
                        tD.unit2 = 'EUR';
                      }

                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        tDMin.unit2 = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode || p.minFee3 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        tDMin.unit2 = 'EUR';
                      }

                      p.QuoteServicesDiscounted.add(tD);
                    }
                  }
                }
              }
            }
          }
          Docs.add(p);
        }
        when 5 {
          if (oneOrTwo[i] == true) {
            p = new Pack();
            if (first == null) {
              first = 1;
              p.firstDoc = true;
            } else {
              p.firstDoc = false;
            }
            p.ThereIsService = false;
            p.Discount = false;
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.contains('EB')) {
                  p.ThereIsService = true;
                  if (
                    !String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)) &&
                    (QS.Product2.ProductCode == 'ERSK_EB_001' ||
                    QS.Product2.ProductCode == 'ERSK_EB_002')
                  ) {
                    p.P03 = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',') + ' EUR';
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_EB_001' ||
                    QS.Product2.ProductCode == 'ERSK_EB_002' ||
                    QS.Product2.ProductCode == 'ERSK_EB_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    if (!String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_EB_001') {
                      p.P01 = string.valueof(QS.ListPrice.setScale(2)).replace('.', ',');
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    } else if (
                      !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_EB_002'
                    ) {
                      p.P02 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                      tD.unit = 'EUR';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    } else if (QS.Product2.ProductCode == 'ERSK_EB_013') {
                      tD.unit = '%';
                      if (!String.isBlank(string.valueof(QS.ER_Percentage__c)))
                        tD.price = string.valueof(QS.ER_Percentage__c.setScale(2)).replace('.', ',');
                    }
                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.quoteServicesFirst.add(tDMin);
                    }
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_EB_003' ||
                    QS.Product2.ProductCode == 'ERSK_EB_008' ||
                    QS.Product2.ProductCode == 'ERSK_EB_009'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    if (QS.Product2.ProductCode == 'ERSK_EB_003') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                          tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                      } else {
                        tdMin.price = '0,00';
                      }
                      tDMin.unit = 'EUR';
                      p.minFee2 = QS.Product2.ProductCode;
                    }
                    p.QuoteServicesVydanie.add(tD);
                    if (p.minFee2 == td.code) {
                      p.QuoteServicesVydanie.add(tDMin);
                    }
                  } else if (QS.Product2.ProductCode == 'ERSK_EB_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_EB_010' ||
                    QS.Product2.ProductCode == 'ERSK_EB_012' ||
                    QS.Product2.ProductCode == 'ERSK_EB_011'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesIne.add(tD);
                  }
                  if (QS.discount != 0 && QS.discount != null) {
                    p.Discount = true;
                    if (
                      QS.Product2.ProductCode == 'ERSK_EB_001' ||
                      QS.Product2.ProductCode == 'ERSK_EB_002' ||
                      QS.Product2.ProductCode == 'ERSK_EB_003' ||
                      QS.Product2.ProductCode == 'ERSK_EB_008' ||
                      QS.Product2.ProductCode == 'ERSK_EB_009' ||
                      QS.Product2.ProductCode == 'ERSK_EB_005' ||
                      QS.Product2.ProductCode == 'ERSK_EB_010' ||
                      QS.Product2.ProductCode == 'ERSK_EB_012' ||
                      QS.Product2.ProductCode == 'ERSK_EB_011'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      if (!String.isBlank(string.valueof(QS.ListPrice)))
                        tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                      tD.code = QS.Product2.ProductCode;
                      if (!String.isBlank(string.valueof(QS.discount.SetScale(2))))
                        tD.discount = string.valueof(QS.discount.SetScale(2)).replace('.', ',') + '%';
                      if (!String.isBlank(string.valueof(QS.UnitPrice.SetScale(2))))
                        tD.totalPrice = string.valueof(QS.UnitPrice.SetScale(2)).replace('.', ',');
                      if (QS.Product2.ProductCode == 'ERSK_EB_001') {
                        tD.unit = '%';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                      }
                      p.QuoteServicesDiscounted.add(tD);
                    }
                  }
                }
              }
            }
          }
          Docs.add(p);
        }
        when 4 {
          if (oneOrTwo[i] == true) {
            p = new Pack();
            if (first == null) {
              first = 4;
              p.firstDoc = true;
            } else {
              p.firstDoc = false;
            }
            p.ThereIsService = false;
            p.Discount = false;
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.minFee3 = '0';
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            p.QuoteServicesSluzby = new List<tableDisplayer>();
            p.QuoteServicesMapped = new Map<string, string>();
            p.QuoteServicesMapped.put('ERSK_TM_014', '');
            p.QuoteServicesMapped.put('ERSK_TM_015', '');
            p.QuoteServicesMapped.put('ERSK_TM_016', '');
            p.QuoteServicesMapped.put('ERSK_TM_017', '');
            p.QuoteServicesMapped.put('ERSK_TM_018', '');
            p.QuoteServicesMapped.put('ERSK_TM_019', '');
            p.QuoteServicesMapped.put('ERSK_TM_016_minFee', '');
            p.QuoteServicesMapped.put('ERSK_TM_018_minFee', '');
            p.QuoteServicesMapped.put('ERSK_TC_014', '');
            p.QuoteServicesMapped.put('ERSK_TC_015', '');
            p.QuoteServicesMapped.put('ERSK_TC_016', '');
            p.QuoteServicesMapped.put('ERSK_TC_017', '');
            p.QuoteServicesMapped.put('ERSK_TC_018', '');
            p.QuoteServicesMapped.put('ERSK_TC_019', '');
            p.QuoteServicesMapped.put('ERSK_TC_016_minFee', '');
            p.QuoteServicesMapped.put('ERSK_TC_018_minFee', '');
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.contains('TM')) {
                  p.ThereIsService = true;

                  if (
                    !String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)) &&
                    (QS.Product2.ProductCode == 'ERSK_TM_001' ||
                    QS.Product2.ProductCode == 'ERSK_TM_002')
                  ) {
                    p.P01 = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',') + ' EUR';
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TM_003'
                  ) {
                    p.P02 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TM_004'
                  ) {
                    p.P05 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TM_005'
                  ) {
                    p.P03 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  } else if (
                    !String.isBlank(string.valueof(QS.ListPrice)) && QS.Product2.ProductCode == 'ERSK_TM_006'
                  ) {
                    p.P04 = string.valueof(Qs.ListPrice.setScale(2)).replace('.', ',');
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TM_001' ||
                    QS.Product2.ProductCode == 'ERSK_TM_002' ||
                    QS.Product2.ProductCode == 'ERSK_TM_020'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = '%';
                    if (QS.Product2.ProductCode == 'ERSK_TM_020') {
                      if (!String.isBlank(string.valueof(QS.ER_Percentage__c)))
                        tD.price = string.valueof(QS.ER_Percentage__c.setScale(2)).replace('.', ',');
                    } else if (QS.Product2.ProductCode == 'ERSK_TM_002') {
                      tD.unit = 'EUR';
                    }
                    if (
                      (QS.Product2.ProductCode == 'ERSK_TM_001' || QS.Product2.ProductCode == 'ERSK_TM_002') &&
                      p.minFee1 == '0'
                    ) {
                      tDMin.name = 'Minimálny poplatok (administratívny)';
                      if (QS.ER_Minimum_Fee__c != null) {
                        if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                          tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                      } else {
                        tdMin.price = '0,00';
                      }
                      tDMin.unit = 'EUR';
                      p.minFee1 = QS.Product2.ProductCode;
                    }

                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.quoteServicesFirst.add(tDMin);
                    }
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_TM_008' ||
                    QS.Product2.ProductCode == 'ERSK_TM_009' ||
                    QS.Product2.ProductCode == 'ERSK_TM_010' ||
                    QS.Product2.ProductCode == 'ERSK_TM_011' ||
                    QS.Product2.ProductCode == 'ERSK_TM_012' ||
                    QS.Product2.ProductCode == 'ERSK_TM_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    if (!String.isBlank(string.valueof(QS.ListPrice)))
                      tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesVydanie.add(tD);
                  } else if (QS.Product2.ProductCode == 'ERSK_TM_014' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_014',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (QS.Product2.ProductCode == 'ERSK_TM_015' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_015',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_TM_016' &&
                    QS.listPrice != null &&
                    QS.ER_Minimum_Fee__c != null
                  ) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_016',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_016_minFee',
                      string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',')
                    );
                  } else if (QS.Product2.ProductCode == 'ERSK_TM_019' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_019',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (QS.Product2.ProductCode == 'ERSK_TM_017' && QS.listPrice != null) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_017',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                  } else if (
                    QS.Product2.ProductCode == 'ERSK_TM_018' &&
                    QS.listPrice != null &&
                    QS.ER_Minimum_Fee__c != null
                  ) {
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_018',
                      string.valueof(QS.listPrice.setScale(2)).replace('.', ',')
                    );
                    p.QuoteServicesMapped.put(
                      'ERSK_TM_018_minFee',
                      string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',')
                    );
                  }
                  if (QS.discount != 0 && QS.discount != null) {
                    p.Discount = true;
                    if (
                      QS.Product2.ProductCode == 'ERSK_TM_001' ||
                      QS.Product2.ProductCode == 'ERSK_TM_002' ||
                      QS.Product2.ProductCode == 'ERSK_TM_004' ||
                      QS.Product2.ProductCode == 'ERSK_TM_003' ||
                      QS.Product2.ProductCode == 'ERSK_TM_005' ||
                      QS.Product2.ProductCode == 'ERSK_TM_006' ||
                      QS.Product2.ProductCode == 'ERSK_TM_008' ||
                      QS.Product2.ProductCode == 'ERSK_TM_009' ||
                      QS.Product2.ProductCode == 'ERSK_TM_010' ||
                      QS.Product2.ProductCode == 'ERSK_TM_011' ||
                      QS.Product2.ProductCode == 'ERSK_TM_012' ||
                      QS.Product2.ProductCode == 'ERSK_TM_013' ||
                      QS.Product2.ProductCode == 'ERSK_TM_014' ||
                      QS.Product2.ProductCode == 'ERSK_TM_015' ||
                      QS.Product2.ProductCode == 'ERSK_TM_016' ||
                      QS.Product2.ProductCode == 'ERSK_TM_017' ||
                      QS.Product2.ProductCode == 'ERSK_TM_018' ||
                      QS.Product2.ProductCode == 'ERSK_TM_019'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      if (!String.isBlank(string.valueof(QS.ListPrice)))
                        tD.price = string.valueof(QS.listPrice.setScale(2)).replace('.', ',');
                      tD.code = QS.Product2.ProductCode;
                      if (!String.isBlank(string.valueof(QS.discount.SetScale(2))))
                        tD.discount = string.valueof(QS.discount.SetScale(2)).replace('.', ',') + '%';
                      if (!String.isBlank(string.valueof(QS.UnitPrice.SetScale(2))))
                        tD.totalPrice = string.valueof(QS.UnitPrice.SetScale(2)).replace('.', ',');
                      if (
                        QS.Product2.ProductCode == 'ERSK_TM_001' ||
                        QS.Product2.ProductCode == 'ERSK_TM_015' ||
                        QS.Product2.ProductCode == 'ERSK_TM_018'
                      ) {
                        tD.unit = '%';
                      } else if (
                        QS.Product2.ProductCode == 'ERSK_TM_008' ||
                        QS.Product2.ProductCode == 'ERSK_TM_009' ||
                        QS.Product2.ProductCode == 'ERSK_TM_010' ||
                        QS.Product2.ProductCode == 'ERSK_TM_011' ||
                        QS.Product2.ProductCode == 'ERSK_TM_012' ||
                        QS.Product2.ProductCode == 'ERSK_TM_013'
                      ) {
                        tD.unit = 'EUR/kus';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (
                        Qs.Product2.ProductCode == 'ERSK_TM_001' ||
                        Qs.Product2.ProductCode == 'ERSK_TM_002' &&
                        p.minFee1 == '0'
                      ) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = Qs.Product2.ProductCode;
                      }
                      if (Qs.Product2.ProductCode == 'ERSK_TM_016' || QS.Product2.ProductCode == 'ERSK_TM_018') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.price = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                          if (!String.isBlank(string.valueof(QS.ER_Minimum_Fee__c)))
                            tDMin.totalPrice = string.valueof(QS.ER_Minimum_Fee__c.setScale(2)).replace('.', ',');
                        } else {
                          tdMin.price = '0,00';
                          tDMin.totalPrice = '0,00';
                        }
                        tDMin.unit = 'EUR';
                        if (Qs.Product2.ProductCode == 'ERSK_TM_016') {
                          p.minFee2 = Qs.Product2.ProductCode;
                        } else {
                          p.minFee3 = Qs.Product2.productCode;
                        }
                      }
                      p.QuoteServicesDiscounted.add(tD);
                    }
                  }
                }
              }
            }
          }
          Docs.add(p);
        }
      }
    }
  }
}