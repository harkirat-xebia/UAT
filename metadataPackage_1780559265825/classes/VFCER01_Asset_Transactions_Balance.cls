/*
~ Author            : Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date      : 06/10/2018 (dd/mm/yyyy)
~ Description       : Controller of the VFER01_Asset_Transactions_Balance
                      This class allows users to perform several WS calls:
                        * getTransactionList
                        * getBalance
                        * getCard

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/

public class VFCER01_Asset_Transactions_Balance {
  public Asset currentAsset { get; set; }
  public Asset updateAsset;
  public List<TransactionWrapper> transactionlist { get; set; }
  public Boolean showError { get; set; }
  public List<BalanceWrapper> balanceInstList { get; set; }
  public BalanceWrapper balanceInst { get; set; }
  public WSER01_BalanceDetails.CardBalanceResponse cardBalanceResponse { get; set; }
  public WSER02_OperationDetails.CardOperationResponse cardOperationResponse { get; set; }
  public WSER05_GetCardDetails.CardDetailResponse cardDetailResponse;
  public List<String> assetFields;
  public String errorMessages;
  public String status_details;
  public Map<String, String> errorLabels;
  public String daterFilters { get; set; }
  public String transactionsCallType;
  public Integer indexFilter;
  public String transactionsParameters;
  public Boolean checkMoreButton { get; set; }
  public Boolean isOfflineBU { get; set; }
  public Boolean canAccess { get; set; }
  public Boolean isPLAccess { get; set; }

  public Boolean displayPopup { get; set; }

  public string assetPopUp { get; set; }
  public string assetProductClass { get; set; }
  public string assetId { get; set; }

  private String searchDepth {
    get {
      if (searchDepth == null) {
        String userBU = APER10_User_Management.userBU;
        List<ER_Transaction_Search_Depth__mdt> transactionSearchDepth = [
          SELECT ER_Search_Depth__c
          FROM ER_Transaction_Search_Depth__mdt
          WHERE DeveloperName = :userBU
          LIMIT 1
        ];
        if (transactionSearchDepth.size() > 0) {
          searchDepth = transactionSearchDepth[0].ER_Search_Depth__c;
        } else {
          searchDepth = Label.LAB_SF_Default_Search_Depth;
        }
      }
      return searchDepth;
    }
    set;
  }

  public VFCER01_Asset_Transactions_Balance(ApexPages.StandardController controller) {
    if (
      (UtilsByPass.getCurrentUser().Profile.Name == 'Client Sales' ||
      UtilsByPass.getCurrentUser().Profile.Name == 'Merchant Sales') &&
      UtilsBypass.getCurrentUser().ER_Business_Unit__c != 'PL'
    ) {
      canAccess = false;
    } else {
      canAccess = true;
    }
    System.debug(UtilsBypass.getCurrentUser().ER_Business_Unit__c);
    if (UtilsBypass.getCurrentUser().ER_Business_Unit__c == 'PL') {
      isPLAccess = false;
    } else {
      isPLAccess = true;
    }

    assetId = apexpages.currentpage().getparameters().get('id');
    currentAsset = [SELECT ID, Name, ER_Product_Class__c FROM Asset WHERE ID = :assetId];

    assetPopUp = currentAsset.Name;
    assetProductClass = currentAsset.ER_Product_Class__c;

    assetFields = new List<String>();
    balanceInst = new BalanceWrapper();

    assetFields.add('Accountid');
    assetFields.add('Status');
    assetFields.add('Name');
    assetFields.add('ER_Asset_Type__c');
    assetFields.add('ER_Asset_Status_Last_Modified_Date__c');
    /*PBI:10028*/
    assetFields.add('ER_Load_Validity_Lunch__c');
    assetFields.add('ER_Load_Validity_Recreational__c');
    assetFields.add('ER_Load_Validity_Transport__c');
    assetFields.add('ER_Load_Validity_Massage__c');
    assetFields.add('ER_Load_Validity_Dental__c');

    assetFields.add('ER_Product_Class__c');
    assetFields.add('recordtype.Developername');
    /*PBI-11338*/
    assetFields.add('Product2.Name');

    daterFilters = '';
    indexFilter = 0;
    checkMoreButton = true;
    transactionsParameters = '';

    if (!Test.isRunningTest())
      controller.addFields(assetFields);

    currentAsset = (Asset) controller.getRecord();
    updateAsset = currentAsset;
    showError = false;
    errorLabels = geterrorLabels();
    System.debug('errorLabels : ' + errorLabels);
    isOfflineBU = APER06_WebserviceUtility.Offline_Service_WS;
  }
  /**
   * @author Oussama LASFAR
   * @date 26/09/2018 (dd/mm/yyyy)
   * @description This method is created to call the WS <<operations>> and display the operation list.
   */
  public void getTransactionList() {
    indexFilter = 0;
    try {
      errorMessages = '';
      showError = false;

      if (transactionsCallType == 'init') {
        indexFilter = 0;
      } else {
        transactionsCallType = 'init';
      }

      if (String.isBlank(daterFilters)) {
        //transactionsParameters = '?page_index=' + indexFilter + '&page_size=50';
        transactionsParameters = '?status=' + searchDepth + '&page_index=' + indexFilter + '&page_size=50';
      } else {
        daterFilters = daterFilters.replaceAll('(\\s+)', '');
        system.debug(daterFilters);
        List<String> dateParts = daterFilters.split('-');
        DateTime dateTimeFrom = DateTime.newInstance(
          Integer.valueOf(dateParts[0]),
          Integer.valueOf(dateParts[1]),
          Integer.valueOf(dateParts[2]),
          0,
          0,
          0
        );
        DateTime dateTimeTo = DateTime.newInstance(
          Integer.valueOf(dateParts[3]),
          Integer.valueOf(dateParts[4]),
          Integer.valueOf(dateParts[5]),
          23,
          59,
          59
        );
        transactionsParameters =
          '?status=' +
          searchDepth +
          '&page_index=0&page_size=50&date-from=' +
          dateTimeFrom.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') +
          '&date-to=' +
          dateTimeTo.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
      }
      //system.debug('Asset_Type: ' + currentAsset.ER_Asset_Type__c);

      if (indexFilter == 0)
        transactionlist = new List<TransactionWrapper>{};

      if (assetPopUp != null) {
        cardOperationResponse = WSER02_OperationDetails.getCardOperations(
          assetProductClass,
          assetPopUp,
          transactionsParameters
        );
      } else {
        cardOperationResponse = WSER02_OperationDetails.getCardOperations(
          currentAsset.ER_Product_Class__c,
          currentAsset.Name,
          transactionsParameters
        );
      }
      System.debug('#### cardOperationResponse : ' + cardOperationResponse);
      if (
        cardOperationResponse != null &&
        cardOperationResponse.meta != null &&
        cardOperationResponse.meta.status != null &&
        cardOperationResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        for (WSER02_OperationDetails.CardOperation CardOp : cardOperationResponse.data) {
          status_details = '';
          system.debug('cardOperationResponse.data: ' + cardOperationResponse.data);
          /*if (currentAsset.ER_Product_Class__c.equalsIgnoreCase(CardOp.product_code) && currentAsset.Name == CardOp.csn) {*/
          //    system.debug('currentAsset: '+  currentAsset.ER_Product_Class__c);
          if (String.isNotBlank(CardOp.status_details)) {
            status_details = errorLabels.get(CardOp.status_details);
          }
          transactionlist.add(
            new TransactionWrapper(
              CardOp.csn,
              CardOp.type,
              CardOp.status,
              status_details,
              CardOp.cleared_status,
              CardOp.product_code,
              ConvertAmount(CardOp.amount),
              CardOp.outlet_name,
              CardOp.MID_auth,
              Changeformat(CardOp.opDate),
              CardOp.wallet_service_provider,
              CardOp.device_name,
              CardOp.device_type,
              CardOp.reason,
              Changeformat(CardOp.cleared_opDate),
              CardOp.acceptance_method,
              CardOp.offline,
              CardOp.product_balance_code,
              CardOp.auth_sub_mid,
              CardOp.clear_sub_mid
            )
          );

          if (math.mod(transactionlist.size(), 50) == 0) {
            checkMoreButton = false;
            indexFilter++;
          } else {
            checkMoreButton = true;
          }
          //}
        }
      } else {
        Integer index = 0;
        String messageText;
        List<WSER02_OperationDetails.Message> cardOpeationMessages = (cardOperationResponse.meta.messages != null
          ? cardOperationResponse.meta.messages
          : cardOperationResponse.meta.message);
        for (WSER02_OperationDetails.Message message : cardOpeationMessages) {
          if (String.isNotBlank(message.text) || String.isNotBlank(message.message)) {
            messageText = String.isNotBlank(message.text)
              ? message.text
              : (String.isNotBlank(message.message) ? message.message : '');
            if (index > 0)
              errorMessages += '<br/>';
            errorMessages += '<b>' + message.code + '</b> : ' + messageText;
            index++;
          }
        }
        if (String.isBlank(errorMessages)) {
          errorMessages = Label.LABS_SF_WS_Unavailable;
        }
        throw new VisualforceException(errorMessages);
      }
    } catch (Exception e) {
      transactionlist = new List<TransactionWrapper>{};
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      System.debug('### Exception get transaction: ' + e.getMessage());
      showError = true;
    }
  }
  /**
   * @author Oussama LASFAR
   * @date 11/07/2019 (dd/mm/yyyy)
   * @description This method is created to call the WS <<operations>> and display the operation list.
   */
  public void geMoretTransactionList() {
    transactionsCallType = 'more';
    getTransactionList();
  }
  /**
   * @author Oussama LASFAR
   * @date 26/09/2018 (dd/mm/yyyy)
   * @description This method is created to call the WS <<balances>> display the balance values and update the field Status and ER_Asset_Status_Last_Modified_Date__c.
   */
  public void getBalance() {
    errorMessages = '';
    showError = false;
    balanceInstList = new List<balancewrapper>();
    balanceInst = new BalanceWrapper();

    try {
      if (assetPopUp != null) {
        cardBalanceResponse = WSER01_BalanceDetails.getCardBalances(assetProductClass, assetPopUp);
      } else {
        cardBalanceResponse = WSER01_BalanceDetails.getCardBalances(
          currentAsset.ER_Product_Class__c,
          currentAsset.Name
        );
      }
      System.debug('#### cardBalanceResponse : ' + cardBalanceResponse);
      if (
        cardBalanceResponse != null &&
        cardBalanceResponse.meta != null &&
        cardBalanceResponse.meta.status != null &&
        cardBalanceResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        for (WSER01_BalanceDetails.CardBalance cardBal : cardBalanceResponse.data) {
          system.debug('cardBal: ' + cardBal + '|data: ' + cardBalanceResponse.data);
          if (String.isNotBlank(cardBal.product_code) /* && cardBal.product_code.equalsIgnoreCase('Main')*/) {
            balanceInst = new BalanceWrapper(
              (cardBal.cleared_amount != null ? ConvertAmount(cardBal.cleared_amount) : '-'),
              (cardBal.reserved_amount != null ? ConvertAmount(cardBal.reserved_amount) : '-'),
              (cardBal.remaining_amount != null ? ConvertAmount(cardBal.remaining_amount) : '-'),
              cardBal.status,
              cardBal.product_code,
              /*,currentAsset.names?*/
              ConvertBalanceExpiringMonths(cardBal.loads),
              ConvertBalanceExpiringYear(cardBal.loads),
              ConvertBalanceExpiringYears(cardBal.loads),
              currentAsset.Product2.Name,
              currentAsset.ER_Asset_Type__c
            );
            system.debug('Cleared: ' + cardBal.cleared_amount);

            if (String.isNotBlank(cardBal.status)) {
              if (
                String.isBlank(currentAsset.Status) ||
                (String.isNotBlank(currentAsset.Status) && !currentAsset.Status.equalsIgnoreCase(cardBal.status))
              ) {
                updateAsset(cardBal.status, '');
              }
            }
          }
          balanceInstList.add(balanceInst);
        }
        System.debug('#### balanceInstList : ' + balanceInstList);
        System.debug('#### balanceInst : ' + balanceInst);
      } else {
        Integer index = 0;
        String messageText;
        List<WSER01_BalanceDetails.Message> cardBalanceMessages = (cardBalanceResponse.meta.messages != null
          ? cardBalanceResponse.meta.messages
          : cardBalanceResponse.meta.message);
        for (WSER01_BalanceDetails.Message message : cardBalanceMessages) {
          if (String.isNotBlank(message.text) || String.isNotBlank(message.message)) {
            messageText = String.isNotBlank(message.text)
              ? message.text
              : (String.isNotBlank(message.message) ? message.message : '');
            if (index > 0)
              errorMessages += '<br/>';
            errorMessages += '<b>' + message.code + '</b> : ' + messageText;
            index++;
          }
        }
        if (String.isBlank(errorMessages)) {
          errorMessages = Label.LABS_SF_WS_Unavailable;
        }
        throw new VisualforceException(errorMessages);
      }
    } catch (Exception e) {
      balanceInst = new BalanceWrapper();
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      System.debug('### Exception get balance: ' + e.getMessage());
      showError = true;
    }
  }
  /**
   * @author Oussama LASFAR
   * @date 26/09/2018 (dd/mm/yyyy)
   * @description This method is created to call the WS <<cards>> and update the fields status and ER_Asset_Status_Last_Modified_Date__c.
   */
  public void getCard() {
    errorMessages = '';
    showError = false;

    try {
      if (assetPopUp != null) {
        cardDetailResponse = WSER05_GetCardDetails.getCardDetail(assetProductClass, assetPopUp);
      } else {
        cardDetailResponse = WSER05_GetCardDetails.getCardDetail(currentAsset.ER_Product_Class__c, currentAsset.Name);
      }

      System.debug('#### cardDetailResponse : ' + cardDetailResponse);
      if (
        cardDetailResponse != null &&
        cardDetailResponse.meta != null &&
        cardDetailResponse.meta.status != null &&
        cardDetailResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        if (cardDetailResponse.data != null && String.isNotBlank(cardDetailResponse.data.status)) {
          if (cardDetailResponse.data.status == Label.LAB_SF_ASSET_Inactive) {
            updateAsset(Label.LAB_SF_ASSET_Issued, cardDetailResponse.data.employer_ref);
          } else {
            updateAsset(cardDetailResponse.data.status, cardDetailResponse.data.employer_ref);
          }
        }
      } else {
        Integer index = 0;
        String messageText;
        List<WSER05_GetCardDetails.Message> cardDetailMessages = (cardDetailResponse.meta.messages != null
          ? cardDetailResponse.meta.messages
          : cardDetailResponse.meta.message);
        for (WSER05_GetCardDetails.Message message : cardDetailMessages) {
          if (String.isNotBlank(message.text) || String.isNotBlank(message.message)) {
            messageText = String.isNotBlank(message.text)
              ? message.text
              : (String.isNotBlank(message.message) ? message.message : '');
            if (index > 0)
              errorMessages += '<br/>';
            errorMessages += '<b>' + message.code + '</b> : ' + messageText;
            index++;
          }
        }
        if (String.isBlank(errorMessages)) {
          errorMessages = Label.LABS_SF_WS_Unavailable;
        }
        throw new VisualforceException(errorMessages);
      }
    } catch (Exception e) {
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      System.debug('### Exception get Card: ' + e.getMessage());
      showError = true;
    }
  }

  public void updateAsset(String Status, String employer_ref) {
    if (
      String.isBlank(currentAsset.Status) ||
      (String.isNotBlank(Status) && !Status.equalsIgnoreCase(currentAsset.Status))
    ) {
      currentAsset.Status = Status;
      updateAsset.Status = Status;
      updateAsset.ER_Asset_Status_Last_Modified_Date__c = Datetime.now();
      if (String.isBlank(updateAsset.AccountId) && String.isNotBlank(employer_ref)) {
        try {
          Account accountReference = new Account(ER_Card_Operational_System_ID__c = employer_ref);
          updateAsset.Account = accountReference;
          System.debug('### VFCER01_Asset_Transactions_Balance updateAssetWithAccount: ' + updateAsset);
          update updateAsset;
          return;
        } catch (Exception e) {
          System.debug('### VFCER01_Asset_Transactions_Balance updateAsset Exception : ' + e.getMessage());
        }
      }
      updateAsset.Account = null;
      System.debug('### VFCER01_Asset_Transactions_Balance updateAsset : ' + updateAsset);
      update updateAsset;
    }
  }

  public String Changeformat(string thedate) {
    if (String.isNotBlank(thedate)) {
      try {
        thedate = thedate.replace('T', ' ').replace('.000Z', '');
        Datetime dd = Datetime.valueof(thedate);
        return dd.format('yyyy-MM-dd HH:mm:ss');
      } catch (Exception e) {
        try {
          Datetime dd = (datetime) json.deserialize('"' + thedate + '"', datetime.class);
          return dd.format('yyyy-MM-dd HH:mm:ss');
        } catch (Exception ex) {
          return thedate;
        }
      }
    } else {
      return '-';
    }
  }

  public String ConvertAmount(string amount) {
    if (String.isNotBlank(amount)) {
      try {
        return String.valueOf((Decimal.valueOf(amount) / 100).setScale(2));
      } catch (Exception e) {
        System.debug('Exception ConvertAmount :' + e);
        return amount;
      }
    }
    return amount;
  }

  public String ConvertBalanceExpiringMonths(List<WSER01_BalanceDetails.Load> loads) {
    Decimal balanceExpiringMonths = 0.00;
    if (loads != null) {
      try {
        for (WSER01_BalanceDetails.Load load : loads) {
          if (load.status == 'active' && getNrMonths(load.authorization_expiration_date) <= 3)
            balanceExpiringMonths += (Decimal.valueOf(load.remaining_amount) / 100).setScale(2);
        }
        return String.valueOf(balanceExpiringMonths);
      } catch (Exception e) {
        System.debug('Exception Balance Expiring in 3 months :' + e);
        return String.valueOf(balanceExpiringMonths);
      }
    }
    return String.valueOf(balanceExpiringMonths);
  }

  public String ConvertBalanceExpiringYear(List<WSER01_BalanceDetails.Load> loads) {
    Decimal balanceExpiringYear = 0.00;
    if (loads != null) {
      try {
        for (WSER01_BalanceDetails.Load load : loads) {
          if (load.status == 'active' && getExpiringYear(load.authorization_expiration_date))
            balanceExpiringYear += (Decimal.valueOf(load.remaining_amount) / 100).setScale(2);
        }
        return String.valueOf(balanceExpiringYear);
      } catch (Exception e) {
        System.debug('Exception Balance Expiring in 3 months :' + e);
        return String.valueOf(balanceExpiringYear);
      }
    }
    return String.valueOf(balanceExpiringYear);
  }

  public String ConvertBalanceExpiringYears(List<WSER01_BalanceDetails.Load> loads) {
    Decimal balanceExpiringYears = 0.00;
    if (loads != null) {
      try {
        for (WSER01_BalanceDetails.Load load : loads) {
          if (load.status == 'active' && getExpiringYear(load.authorization_expiration_date) == false)
            balanceExpiringYears += (Decimal.valueOf(load.remaining_amount) / 100).setScale(2);
        }
        return String.valueOf(balanceExpiringYears);
      } catch (Exception e) {
        System.debug('Exception Balance Expiring in 3 months :' + e);
        return String.valueOf(balanceExpiringYears);
      }
    }
    return String.valueOf(balanceExpiringYears);
  }

  public Integer getNrMonths(String expiringDate) {
    Datetime currentDate = Datetime.now();
    Date cDay = date.valueOf(currentDate.format('yyyy-MM-dd'));
    Datetime dd = Datetime.valueOf(Changeformat(expiringDate));
    Date expDate = date.valueOf(dd.format('yyyy-MM-dd'));
    Integer monthDiff = cDay.monthsBetween(expDate);
    if (expDate.day() > cDay.day())
      monthDiff++;
    return monthDiff;
  }

  public Boolean getExpiringYear(String expiringdate) {
    Datetime currentDate = date.valueOf(Datetime.now());
    Integer cYear = currentDate.year();
    Datetime dd = date.valueOf(Datetime.valueOf(Changeformat(expiringDate)));
    Integer expYear = dd.year();
    System.debug('Current Year: ' + cYear + ' Exp Year: ' + expYear);
    if (cYear == expYear)
      return true;
    return false;
  }

  public Map<String, String> geterrorLabels() {
    Map<String, String> errorLabels = new Map<String, String>();
    List<CMER03_EDG_Error_Label__mdt> errorLabelList = [
      SELECT id, DeveloperName, MasterLabel
      FROM CMER03_EDG_Error_Label__mdt
    ];
    for (CMER03_EDG_Error_Label__mdt errorLabel : errorLabelList) {
      errorLabels.put(errorLabel.DeveloperName, errorLabel.MasterLabel);
    }

    return errorLabels;
  }

  public void showPopup() {
    displayPopup = true;
  }

  public void closePopup() {
    displayPopup = false;
  }

  public PageReference redirect() {
    //Please uncomment below 3 statements and replace YourObjectId
    PageReference p = new Pagereference('/apex/VFER10_Multi_Wallet_Transactions');
    p.setRedirect(true);
    return p;
  }

  class BalanceWrapper {
    public String balance { get; set; }
    public String pendingDebit { get; set; }
    public String balanceAvailable { get; set; }
    public String status { get; set; }
    public String solution { get; set; }
    public String name { get; set; }
    public String amountExpiringMonths { get; set; }
    public String amountExpiringYear { get; set; }
    public String amountExpiringYears { get; set; }
    public String productName { get; set; }
    public String assetType { get; set; }

    public BalanceWrapper() {
      balance = '-';
      pendingDebit = '-';
      balanceAvailable = '-';
      status = '-';
      solution = '-';
      name = 'Name';
      amountExpiringMonths = '-';
      amountExpiringYear = '-';
      amountExpiringYears = '-';
      productName = '-';
      assetType = '-';
    }

    public BalanceWrapper(
      String balance,
      String pendingDebit,
      String balanceAvailable,
      String status,
      string name /*, string solution*/,
      String amountExpiringMonths,
      String amountExpiringYear,
      String amountExpiringYears,
      String productName,
      String assetType
    ) {
      this.balance = balance;
      this.pendingDebit = pendingDebit;
      this.balanceAvailable = balanceAvailable;
      this.status = status;
      //this.solution = solution;
      this.name = name;
      this.amountExpiringMonths = amountExpiringMonths;
      this.amountExpiringYear = amountExpiringYear;
      this.amountExpiringYears = amountExpiringYears;
      this.productName = productName;
      this.assetType = assetType;
    }
  }

  class TransactionWrapper {
    public String trDate { get; set; }
    public String csn { get; set; }
    public String type { get; set; }
    public String status { get; set; }
    public String status_details { get; set; }
    public String cleared_status { get; set; }
    public String product_code { get; set; }
    public String acceptorName { get; set; }
    public String amount { get; set; }
    public String MIDauth { get; set; }
    public String walletServiceProvider { get; set; }
    public String deviceName { get; set; }
    public String deviceType { get; set; }
    public string reasonText { get; set; }
    public string clearedDate { get; set; }
    public string acceptanceMethod { get; set; }
    public Boolean offline { get; set; }
    public String productBalanceCode { get; set; }
    public String authSubMid { get; set; }
    public String clearSubMid { get; set; }

    public TransactionWrapper(
      String csn,
      String type,
      String status,
      String status_details,
      String cleared_status,
      String product_code,
      String amount,
      String outlet_name,
      String MID_auth,
      String opDate,
      String wallet_service_provider,
      String device_name,
      String device_type,
      String reasonText,
      String clearedDate,
      String acceptanceMethod,
      Boolean offline,
      String productBalanceCode,
      String authSubMid,
      String clearSubMid
    ) {
      this.trDate = opDate;
      this.csn = csn;
      this.type = type;
      this.status = status;
      this.status_details = status_details;
      this.cleared_status = cleared_status;
      this.acceptorName = outlet_name;
      this.product_code = product_code;
      this.amount = amount;
      this.MIDauth = MID_auth;
      this.trDate = opDate;
      this.walletServiceProvider = wallet_service_provider;
      this.deviceName = device_name;
      this.deviceType = device_type;
      this.reasonText = reasonText;
      this.clearedDate = clearedDate;
      this.acceptanceMethod = acceptanceMethod;
      this.offline = offline;
      this.productBalanceCode = productBalanceCode;
      this.authSubMid = authSubMid;
      this.clearSubMid = clearSubMid;
    }
  }

  public class VisualforceException extends Exception {
  }
}