public class VFCSK02_Proposal_PDF_SK {
  String quoteId;
  String accountId;
  String ownerId;
  String contractId;

  public String accountName { get; set; }
  public String vatNumber { get; set; }
  public String companyRegistrationNumber { get; set; }
  public Date sysdateToday { get; set; }
  public String sysdate { get; set; }
  public String ownerName { get; set; }
  public Boolean indexation { get; set; }
  public String PaymentTerms { get; set; }
  public String PaymentVoucher { get; set; }
  public Date expirationDate { get; set; }
  public String expirationDateFormat { get; set; }

  public String quotenumber { get; set; }
  public Contact financialCenterContact { get; set; }
  public Map<String, List<QuoteLineItem>> SolutionMap { get; set; }
  public Map<String, QuoteLineItem> serviceMap2 { get; set; }
  public Map<String, pricebookentry> ServiceMap { get; set; }
  public String productCode { get; set; }
  public String priceBookId;

  public List<Pack> Docs { get; set; }
  public List<QuoteLineItem> QuoteServices { get; set; }
  public List<Boolean> oneOrTwo { get; set; }
  public boolean show { get; set; }

  public class tableDisplayer {
    public string code { get; set; }
    public Decimal price { get; set; }
    public Decimal totalPrice { get; set; }
    public string name { get; set; }
    public String discount { get; set; }
    public string unit { get; set; }
    //public string  unit2 {get;set;} only for TR_010
  }

  public class Pack {
    public List<tableDisplayer> QuoteServicesDiscounted { get; set; }
    public List<tableDisplayer> QuoteServicesFirst { get; set; }
    public List<tableDisplayer> QuoteServicesVydanie { get; set; }
    public List<tableDisplayer> QuoteServicesDorucenie { get; set; }
    public List<tableDisplayer> QuoteServicesIne { get; set; }
    public List<tableDisplayer> QuoteServicesSluzby { get; set; }
    public List<tableDisplayer> QuoteServicesUhrada { get; set; }
    public List<tableDisplayer> QuoteServicesBalenie { get; set; }
    public Map<string, string> QuoteServicesMapped { get; set; }
    public Boolean Discount { get; set; }
    public string P01 { get; set; }
    public boolean ThereIsService { get; set; }
    public boolean FirstDoc { get; set; } //to know if I should call a page break
    public string minFee1 { get; set; }
    public string minFee2 { get; set; }
  }

  public VFCSK02_Proposal_PDF_SK() {
    quoteId = ApexPages.currentPage().getParameters().get('id');
    SolutionMap = new Map<String, List<QuoteLineItem>>();
    serviceMap2 = new Map<String, QuoteLineItem>();
    ServiceMap = new Map<String, pricebookentry>();

    sysdateToday = Date.today();
    sysdate = Datetime.newInstance(sysdateToday.year(), sysdateToday.month(), sysdateToday.day()).format('dd.MM.YYYY');

    for (Quote insertedQuote : [
      SELECT
        AccountId,
        ContractId,
        ER_PaymentTerms__c,
        SK_Payment_Terms_Voucher__c,
        ExpirationDate,
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
      accountId = insertedQuote.AccountId;
      contractId = insertedQuote.ContractId;
      ownerId = insertedQuote.OwnerId;
      quotenumber = insertedQuote.QuoteNumber;
      indexation = insertedQuote.ER_Indexation__c;
      PaymentTerms = insertedQuote.ER_PaymentTerms__c;
      PaymentVoucher = insertedQuote.SK_Payment_Terms_Voucher__c;
      expirationDate = insertedQuote.ExpirationDate;
      expirationDateFormat = '';

      if (insertedQuote.ER_PaymentTerms__c != null || insertedQuote.ER_PaymentTerms__c != '') {
        show = true;
        PaymentTerms = insertedQuote.ER_PaymentTerms__c;
        /////////// transco payment terms

        switch on PaymentTerms {
          when 'At reception of invoice' {
            PaymentTerms = '0';
          }
          when '3 days after invoice issuance' {
            PaymentTerms = '3';
          }
          when '4 days after invoice issuance' {
            PaymentTerms = '4';
          }
          when '5 days after invoice issuance' {
            PaymentTerms = '5';
          }
          when '7 days after invoice issuance' {
            PaymentTerms = '7';
          }
          when '10 days after invoice issuance' {
            PaymentTerms = '10';
          }
          when '14 days after invoice issuance' {
            PaymentTerms = '14';
          }
          when '15 days after invoice issuance' {
            PaymentTerms = '15';
          }
          when '20 days after invoice issuance' {
            PaymentTerms = '20';
          }
          when '21 days after invoice issuance' {
            PaymentTerms = '21';
          }
          when '30 days after invoice issuance' {
            PaymentTerms = '30';
          }
          when '45 days after invoice issuance' {
            PaymentTerms = '45';
          }
          when '50 days after invoice issuance' {
            PaymentTerms = '50';
          }
          when '60 days after invoice issuance' {
            PaymentTerms = '60';
          }
          when '90 days after invoice issuance' {
            PaymentTerms = '90';
          }
          when '100 days after invoice issuance' {
            PaymentTerms = '100';
          }
        }

        //////////
      } else {
        show = false;
      }
      if (insertedQuote.SK_Payment_Terms_Voucher__c != null || insertedQuote.SK_Payment_Terms_Voucher__c != '') {
        show = true;
        PaymentVoucher = insertedQuote.SK_Payment_Terms_Voucher__c;
      } else {
        show = false;
      }

      if (expirationDate != null) {
        //expirationDateFormat = Datetime.newInstance(expirationDate.year(), expirationDate.month(), expirationDate.day()).format('YYYY-MM-dd');
        //expirationDateFormat = Datetime.newInstance(expirationDate.year(), expirationDate.month(), expirationDate.day()).format('dd/MM/YYYY');
        expirationDateFormat = Datetime.newInstance(expirationDate.year(), expirationDate.month(), expirationDate.day())
          .format('dd.MM.YYYY');
      }
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
    for (User owner : [SELECT Id, Name FROM User WHERE Id = :ownerId]) {
      ownerName = owner.Name;
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
        companyRegistrationNumber = account.ER_Registration_Number__c;
      }
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
        Product2.ProductCode,
        ER_Minimum_Fee__c,
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
                    QS.Product2.ProductCode == 'ERSK_TRV_001' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_002' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;

                    if (QS.Product2.ProductCode == 'ERSK_TRV_001') {
                      tD.unit = '%';
                      tD.price = QS.listPrice.setScale(2);
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null)
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        p.minFee1 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TRV_002') {
                      tD.unit = 'EUR';
                      tD.price = QS.listPrice.setScale(2);
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        p.minFee1 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TRV_013') {
                      tD.unit = '%';
                      tD.price = QS.ER_Percentage__c.setScale(2);
                    }

                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.QuoteServicesFirst.add(tDMin);
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
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';

                    if (QS.Product2.ProductCode == 'ERSK_TRV_003') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }

                    p.QuoteServicesVydanie.add(tD);
                    if (p.minFee2 == tD.code) {
                      p.QuoteServicesVydanie.add(tDMin);
                    }
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TRV_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TRV_010' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_012' ||
                    QS.Product2.ProductCode == 'ERSK_TRV_011'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
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
                      tD.price = QS.listPrice.setScale(2);
                      tD.code = QS.Product2.ProductCode;
                      tD.discount = QS.discount.SetScale(2) + ' %';
                      tD.totalPrice = QS.UnitPrice.SetScale(2);
                      if (QS.Product2.ProductCode == 'ERSK_TRV_001') {
                        tD.unit = '%';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      p.QuoteServicesDiscounted.add(tD);
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        p.QuoteServicesDiscounted.add(tDMin);
                      }
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
                    QS.Product2.ProductCode == 'ERSK_HC_001' ||
                    QS.Product2.ProductCode == 'ERSK_HC_002' ||
                    QS.Product2.ProductCode == 'ERSK_HC_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;

                    if (QS.Product2.ProductCode == 'ERSK_HC_001') {
                      p.P01 = string.valueof(QS.ListPrice.setScale(2));
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_HC_002') {
                      tD.unit = 'EUR';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_HC_013') {
                      tD.unit = '%';
                      tD.price = QS.ER_Percentage__c.setScale(2);
                    }

                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.QuoteServicesFirst.add(tDMin);
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
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';

                    if (QS.Product2.ProductCode == 'ERSK_HC_003') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }

                    p.QuoteServicesVydanie.add(tD);
                    if (p.minFee2 == tD.code) {
                      p.QuoteServicesVydanie.add(tDMin);
                    }
                  }
                  if (QS.Product2.ProductCode == 'ERSK_HC_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_HC_010' ||
                    QS.Product2.ProductCode == 'ERSK_HC_012' ||
                    QS.Product2.ProductCode == 'ERSK_HC_011'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
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
                      tD.price = QS.listPrice.setScale(2);
                      tD.code = QS.Product2.ProductCode;
                      tD.discount = QS.discount.SetScale(2) + ' %';
                      tD.totalPrice = QS.UnitPrice.SetScale(2);
                      if (QS.Product2.ProductCode == 'ERSK_HC_001') {
                        tD.unit = '%';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      p.QuoteServicesDiscounted.add(tD);
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        p.QuoteServicesDiscounted.add(tDMin);
                      }
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
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.ThereIsService = false;
            p.Discount = false;
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            p.QuoteServicesSluzby = new List<tableDisplayer>();
            P.QuoteServicesUhrada = new List<tableDisplayer>();
            p.QuoteServicesBalenie = new List<tableDisplayer>();
            p.QuoteServicesMapped = new Map<string, string>();
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.contains('TC')) {
                  p.ThereIsService = true;

                  if (
                    QS.Product2.ProductCode == 'ERSK_TC_001' ||
                    QS.Product2.ProductCode == 'ERSK_TC_002' ||
                    QS.Product2.ProductCode == 'ERSK_TC_020'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    if (QS.Product2.ProductCode == 'ERSK_TC_001' || QS.Product2.ProductCode == 'ERSK_TC_020') {
                      tD.unit = '%';
                      //tD.price = QS.ER_Percentage__c;
                    } else {
                      tD.unit = 'EUR';
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TC_001') {
                      p.P01 = string.valueof(QS.ListPrice.setScale(2));
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TC_002') {
                      tD.unit = 'EUR';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.QuoteServicesFirst.add(tDMin);
                    }
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TC_003' || QS.Product2.ProductCode == 'ERSK_TC_004') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TC_005' || QS.Product2.ProductCode == 'ERSK_TC_006') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesUhrada.add(tD);
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TC_014' || QS.Product2.ProductCode == 'ERSK_TC_015') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = QS.Product2.ProductCode == 'ERSK_TC_014' ? 'EUR/Kus' : '%';
                    p.QuoteServicesBalenie.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TC_008' ||
                    QS.Product2.ProductCode == 'ERSK_TC_009' ||
                    QS.Product2.ProductCode == 'ERSK_TC_010' ||
                    QS.Product2.ProductCode == 'ERSK_TC_011' ||
                    QS.Product2.ProductCode == 'ERSK_TC_012' ||
                    QS.Product2.ProductCode == 'ERSK_TC_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR/Kus';
                    p.QuoteServicesVydanie.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TC_016' ||
                    QS.Product2.ProductCode == 'ERSK_TC_019' ||
                    QS.Product2.ProductCode == 'ERSK_TC_017' ||
                    QS.Product2.ProductCode == 'ERSK_TC_018'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    if (QS.Product2.ProductCode == 'ERSK_TC_018') {
                      tD.unit = '%';
                    } else {
                      tD.unit = 'EUR';
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TC_016') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TC_018') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }
                    p.QuoteServicesSluzby.add(tD);
                    if (p.minFee2 == td.code) {
                      p.QuoteServicesSluzby.add(tDMin);
                    }
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
                      tD.price = QS.listPrice.setScale(2);
                      tD.code = QS.Product2.ProductCode;
                      tD.discount = QS.discount.SetScale(2) + ' %';
                      tD.totalPrice = QS.UnitPrice.SetScale(2);
                      if (
                        QS.Product2.ProductCode == 'ERSK_TC_001' ||
                        QS.Product2.ProductCode == 'ERSK_TC_015' ||
                        QS.Product2.ProductCode == 'ERSK_TC_018'
                      ) {
                        tD.unit = '%';
                      } //else
                      if (
                        QS.Product2.ProductCode == 'ERSK_TC_008' ||
                        QS.Product2.ProductCode == 'ERSK_TC_009' ||
                        QS.Product2.ProductCode == 'ERSK_TC_010' ||
                        QS.Product2.ProductCode == 'ERSK_TC_011' ||
                        QS.Product2.ProductCode == 'ERSK_TC_012' ||
                        QS.Product2.ProductCode == 'ERSK_TC_013' ||
                        QS.Product2.ProductCode == 'ERSK_TC_014'
                      ) {
                        tD.unit = 'EUR/kus';
                      }
                      //else
                      if (
                        QS.Product2.ProductCode == 'ERSK_TC_002' ||
                        QS.Product2.ProductCode == 'ERSK_TC_003' ||
                        QS.Product2.ProductCode == 'ERSK_TC_004' ||
                        QS.Product2.ProductCode == 'ERSK_TC_005' ||
                        QS.Product2.ProductCode == 'ERSK_TC_006' ||
                        QS.Product2.ProductCode == 'ERSK_TC_016' ||
                        QS.Product2.ProductCode == 'ERSK_TC_019' ||
                        QS.Product2.ProductCode == 'ERSK_TC_017' ||
                        QS.Product2.ProductCode == 'ERSK_TC_022'
                      ) {
                        tD.unit = 'EUR';
                      }

                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (QS.Product2.ProductCode == 'ERSK_TC_016') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        p.minFee2 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                      if (QS.Product2.ProductCode == 'ERSK_TC_018') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        p.minFee2 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }

                      p.QuoteServicesDiscounted.add(tD);
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        p.QuoteServicesDiscounted.add(tDMin);
                      }
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
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            p.QuoteServicesSluzby = new List<tableDisplayer>();
            P.QuoteServicesUhrada = new List<tableDisplayer>();
            p.QuoteServicesBalenie = new List<tableDisplayer>();
            p.QuoteServicesMapped = new Map<string, string>();
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.equalsIgnoreCase('TR')) {
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
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.discount = QS.discount.SetScale(2) + ' %';
                    tD.totalPrice = QS.UnitPrice;

                    if (QS.Product2.ProductCode == 'ERSK_TR_016') {
                      tD.unit = '%';
                      tD.price = QS.ER_Percentage__c.setScale(2);
                    } else {
                      tD.unit = 'EUR';
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TR_001') {
                      p.P01 = string.valueof(QS.ListPrice);
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TR_002') {
                      tD.unit = 'EUR';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }

                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.QuoteServicesFirst.add(tDMin);
                    }
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TR_004' || QS.Product2.ProductCode == 'ERSK_TR_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TR_008' || QS.Product2.ProductCode == 'ERSK_TR_009') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesUhrada.add(tD);
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TR_010') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = '%';
                    p.QuoteServicesBalenie.add(tD);
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
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.discount = QS.discount.SetScale(2) + ' %';
                    tD.totalPrice = QS.UnitPrice;

                    if (QS.Product2.ProductCode == 'ERSK_TR_014') {
                      tD.unit = '%';
                    } else if (QS.Product2.ProductCode == 'ERSK_TR_013') {
                      tD.unit = 'EUR/kus';
                    } else {
                      tD.unit = 'EUR';
                    }

                    if (QS.Product2.ProductCode == 'ERSK_TR_013') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TR_014') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }

                    p.QuoteServicesIne.add(tD);
                    if (p.minFee2 == tD.code) {
                      p.QuoteServicesIne.add(tDMin);
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
                      QS.Product2.ProductCode == 'ERSK_TR_014'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      tD.price = QS.listPrice.setScale(2);
                      tD.code = QS.Product2.ProductCode;
                      tD.discount = QS.discount.SetScale(2) + ' %';
                      tD.totalPrice = QS.UnitPrice.SetScale(2);
                      if (
                        QS.Product2.ProductCode == 'ERSK_TR_001' ||
                        QS.Product2.ProductCode == 'ERSK_TR_010' ||
                        QS.Product2.ProductCode == 'ERSK_TR_014'
                      ) {
                        tD.unit = '%';
                      } else if (QS.Product2.ProductCode == 'ERSK_TR_013') {
                        tD.unit = 'EUR/kus';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (QS.Product2.ProductCode == 'ERSK_TR_013') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        p.minFee2 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                      if (QS.Product2.ProductCode == 'ERSK_TR_014') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        p.minFee2 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }

                      p.QuoteServicesDiscounted.add(tD);
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        p.QuoteServicesDiscounted.add(tDMin);
                      }
                    }
                  }
                }
              }
            }
          }
          Docs.add(p);
        }
        when 5{
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
                    QS.Product2.ProductCode == 'ERSK_EB_001' ||
                    QS.Product2.ProductCode == 'ERSK_EB_002' ||
                    QS.Product2.ProductCode == 'ERSK_EB_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;

                    if (QS.Product2.ProductCode == 'ERSK_EB_001') {
                      p.P01 = string.valueof(QS.ListPrice.setScale(2));
                      tD.unit = '%';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_EB_002') {
                      tD.unit = 'EUR';
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_EB_013') {
                      tD.unit = '%';
                      tD.price = QS.ER_Percentage__c.setScale(2);
                    }
                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.QuoteServicesFirst.add(tDMin);
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
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';

                    if (QS.Product2.ProductCode == 'ERSK_EB_003') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }

                    p.QuoteServicesVydanie.add(tD);
                    if (p.minFee2 == tD.code) {
                      p.QuoteServicesVydanie.add(tDMin);
                    }
                  }
                  if (QS.Product2.ProductCode == 'ERSK_EB_005') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_EB_010' ||
                    QS.Product2.ProductCode == 'ERSK_EB_012' ||
                    QS.Product2.ProductCode == 'ERSK_EB_011'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
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
                      tD.price = QS.listPrice.setScale(2);
                      tD.code = QS.Product2.ProductCode;
                      tD.discount = QS.discount.SetScale(2) + ' %';
                      tD.totalPrice = QS.UnitPrice.SetScale(2);
                      if (QS.Product2.ProductCode == 'ERSK_EB_001') {
                        tD.unit = '%';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      p.QuoteServicesDiscounted.add(tD);
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        p.QuoteServicesDiscounted.add(tDMin);
                      }
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
            p.minFee1 = '0';
            p.minFee2 = '0';
            p.ThereIsService = false;
            p.Discount = false;
            p.QuoteServicesDiscounted = new List<tableDisplayer>();
            p.QuoteServicesFirst = new List<tableDisplayer>();
            p.QuoteServicesVydanie = new List<tableDisplayer>();
            p.QuoteServicesDorucenie = new List<tableDisplayer>();
            p.QuoteServicesIne = new List<tableDisplayer>();
            p.QuoteServicesSluzby = new List<tableDisplayer>();
            P.QuoteServicesUhrada = new List<tableDisplayer>();
            p.QuoteServicesBalenie = new List<tableDisplayer>();
            p.QuoteServicesMapped = new Map<string, string>();
            for (QuoteLineItem QS : QuoteServices) {
              if (QS.ER_Percentage__c != null) {
                QS.UnitPrice = QS.ER_Percentage__c;
              }
              string a = (QS.Product2.ProductCode.substringBetween('ERSK_', '_'));
              if (a != null) {
                if (a.contains('TM')) {
                  p.ThereIsService = true;
                  if (
                    QS.Product2.ProductCode == 'ERSK_TM_001' ||
                    QS.Product2.ProductCode == 'ERSK_TM_002' ||
                    QS.Product2.ProductCode == 'ERSK_TM_020'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.discount = QS.discount.SetScale(2) + ' %';
                    tD.totalPrice = QS.UnitPrice.setScale(2);
                    if (QS.Product2.ProductCode == 'ERSK_TM_001' || QS.Product2.ProductCode == 'ERSK_TM_020') {
                      tD.unit = '%';
                      tD.price = QS.ER_Percentage__c.setScale(2);
                    } else {
                      tD.unit = 'EUR';
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TM_001') {
                      tD.unit = '%';
                      tD.price = QS.listPrice.setScale(2);
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TM_002') {
                      tD.unit = 'EUR';
                      tD.price = QS.listPrice.setScale(2);
                      if (p.minFee1 == '0') {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        tDMin.unit = 'EUR';
                        p.minFee1 = QS.Product2.ProductCode;
                      }
                    }
                    p.QuoteServicesFirst.add(tD);
                    if (p.minFee1 == td.code) {
                      p.QuoteServicesFirst.add(tDMin);
                    }
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TM_003' || QS.Product2.ProductCode == 'ERSK_TM_004') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesDorucenie.add(tD);
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TM_005' || QS.Product2.ProductCode == 'ERSK_TM_006') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR';
                    p.QuoteServicesUhrada.add(tD);
                  }
                  if (QS.Product2.ProductCode == 'ERSK_TM_014' || QS.Product2.ProductCode == 'ERSK_TM_015') {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = QS.Product2.ProductCode == 'ERSK_TM_014' ? 'EUR/Kus' : '%';
                    p.QuoteServicesBalenie.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TM_008' ||
                    QS.Product2.ProductCode == 'ERSK_TM_009' ||
                    QS.Product2.ProductCode == 'ERSK_TM_010' ||
                    QS.Product2.ProductCode == 'ERSK_TM_011' ||
                    QS.Product2.ProductCode == 'ERSK_TM_012' ||
                    QS.Product2.ProductCode == 'ERSK_TM_013'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;
                    tD.unit = 'EUR/Kus';
                    p.QuoteServicesVydanie.add(tD);
                  }
                  if (
                    QS.Product2.ProductCode == 'ERSK_TM_016' ||
                    QS.Product2.ProductCode == 'ERSK_TM_019' ||
                    QS.Product2.ProductCode == 'ERSK_TM_017' ||
                    QS.Product2.ProductCode == 'ERSK_TM_018'
                  ) {
                    tableDisplayer tD = new tableDisplayer();
                    tableDisplayer tDMin = new tableDisplayer();
                    tD.name = QS.Product2.Name;
                    tD.price = QS.listPrice.setScale(2);
                    tD.code = QS.Product2.ProductCode;

                    if (QS.Product2.ProductCode == 'ERSK_TM_018') {
                      tD.unit = '%';
                    } else {
                      tD.unit = 'EUR';
                    }

                    if (QS.Product2.ProductCode == 'ERSK_TM_016') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }
                    if (QS.Product2.ProductCode == 'ERSK_TM_018') {
                      tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                      if (QS.ER_Minimum_Fee__c != null) {
                        tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                      } else {
                        tdMin.price = 0.00;
                      }
                      p.minFee2 = QS.Product2.ProductCode;
                      tDMin.unit = 'EUR';
                    }
                    p.QuoteServicesSluzby.add(tD);
                    if (p.minFee2 == td.code) {
                      p.QuoteServicesSluzby.add(tDMin);
                    }
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
                      QS.Product2.ProductCode == 'ERSK_TM_019' ||
                      QS.Product2.ProductCode == 'ERSK_TM_017' ||
                      QS.Product2.ProductCode == 'ERSK_TM_018'
                    ) {
                      tableDisplayer tD = new tableDisplayer();
                      tableDisplayer tDMin = new tableDisplayer();
                      tD.name = QS.Product2.Name;
                      tD.price = QS.listPrice.setScale(2);
                      tD.code = QS.Product2.ProductCode;
                      tD.discount = QS.discount.SetScale(2) + ' %';
                      tD.totalPrice = QS.UnitPrice.SetScale(2);

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
                        QS.Product2.ProductCode == 'ERSK_TM_013' ||
                        QS.Product2.ProductCode == 'ERSK_TM_014'
                      ) {
                        tD.unit = 'EUR/kus';
                      } else {
                        tD.unit = 'EUR';
                      }
                      if (p.minFee1 == QS.Product2.ProductCode) {
                        tDMin.name = 'Minimálny poplatok (administratívny)';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.totalPrice = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                          tDMin.totalPrice = 0.00;
                        }
                        tDMin.unit = 'EUR';
                      }
                      if (QS.Product2.ProductCode == 'ERSK_TM_016') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        p.minFee2 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                      if (QS.Product2.ProductCode == 'ERSK_TM_018') {
                        tDMin.name = QS.Product2.Name + '– minimálny poplatok';
                        if (QS.ER_Minimum_Fee__c != null) {
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                          tDMin.price = QS.ER_Minimum_Fee__c.setScale(2);
                        } else {
                          tdMin.price = 0.00;
                        }
                        p.minFee2 = QS.Product2.ProductCode;
                        tDMin.unit = 'EUR';
                      }
                      p.QuoteServicesDiscounted.add(tD);
                      if (p.minFee2 == QS.Product2.ProductCode) {
                        p.QuoteServicesDiscounted.add(tDMin);
                      }
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