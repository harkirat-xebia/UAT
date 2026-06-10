/*
~ Author            : Nicolae CIAUSU (Nicolae.Ciausu@edenred.com)
~ Created Date      : 01/04/2020 (dd/mm/yyyy)
~ Description       : Controller of the VFER13_Asset_GetLoads
This class allows users to perform several WS calls:
* getLoadsList

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/

public class VFCER10_Asset_GetLoads {
  public Asset currentAsset { get; set; }
  public Asset updateAsset;
  public WSER10_GetLoads.CardLoadsResponse cardLoadResponse { get; set; }
  public List<LoadWrapper> loadlist { get; set; }
  public String loadParameters;
  public Boolean showError { get; set; }
  public List<String> assetFields;
  public String errorMessages;
  public Map<String, String> errorLabels;
  public String transactionsCallType;
  public Integer indexFilter;
  public Boolean checkMoreButton { get; set; }
  public Boolean isOfflineBU { get; set; }

  public Boolean displayPopup { get; set; }

  public string assetName { get; set; }
  public string assetProductCode { get; set; }
  public string assetId { get; set; }

  public VFCER10_Asset_GetLoads(ApexPages.StandardController controller) {
    assetId = apexpages.currentpage().getparameters().get('id');
    Asset currentAsset = [SELECT ID, Name, ER_Product_Class__c FROM Asset WHERE ID = :assetId];
    assetName = currentAsset.Name;
    assetProductCode = currentAsset.ER_Product_Class__c;

    assetFields = new List<String>();
    assetFields.add('Accountid');
    assetFields.add('Status');
    assetFields.add('Name');
    assetFields.add('ER_Asset_Type__c');
    assetFields.add('ER_Asset_Status_Last_Modified_Date__c');
    assetFields.add('ER_Product_Class__c');
    assetFields.add('recordtype.Developername');

    indexFilter = 0;
    checkMoreButton = true;
    loadParameters = '';

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
  public void getLoadsList() {
    indexFilter = 0;
    try {
      errorMessages = '';
      showError = false;
      if (transactionsCallType == 'init') {
        indexFilter = 0;
      } else {
        transactionsCallType = 'init';
      }
      loadParameters = '?page_index=' + indexFilter + '&page_size=50';
      if (indexFilter == 0)
        loadlist = new List<LoadWrapper>{};
      if (assetProductCode != null && assetName != null) {
        cardLoadResponse = WSER10_GetLoads.getCardLoads(assetProductCode, assetName, loadParameters);
      } else {
        cardLoadResponse = WSER10_GetLoads.getCardLoads(
          currentAsset.ER_Product_Class__c,
          currentAsset.Name,
          loadParameters
        );
      }

      System.debug('#### cardLoadResponse : ' + cardLoadResponse);
      if (
        cardLoadResponse != null &&
        cardLoadResponse.meta != null &&
        cardLoadResponse.meta.status != null &&
        cardLoadResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        for (WSER10_GetLoads.CardLoad cardLoad : cardLoadResponse.data) {
          system.debug('cardLoadResponse.data: ' + cardLoadResponse.data);
          for (WSER10_GetLoads.Load load : cardLoad.loads)
            loadlist.add(
              new LoadWrapper(
                cardLoad.product_code,
                load.load_ref,
                ConvertAmount(load.loaded_amount),
                ConvertAmount(load.remaining_amount),
                ConvertAmount(load.cleared_amount),
                Changeformat(load.start_date),
                Changeformat(load.clearing_expiration_date),
                Changeformat(load.authorization_expiration_date),
                load.ccurrency,
                Changeformat(load.creation_date),
                load.status
              )
            );

          if (math.mod(loadlist.size(), 50) == 0) {
            checkMoreButton = false;
            indexFilter++;
          } else {
            checkMoreButton = true;
          }
        }
      } else {
        Integer index = 0;
        String messageText;
        List<WSER10_GetLoads.Message> cardLoadMessages = (cardLoadResponse.meta.messages != null
          ? cardLoadResponse.meta.messages
          : cardLoadResponse.meta.message);
        for (WSER10_GetLoads.Message message : cardLoadMessages) {
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
      loadlist = new List<LoadWrapper>{};
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      System.debug('### Exception get loads: ' + e.getMessage());
      showError = true;
    }
  }
  /**
   * @author Oussama LASFAR
   * @date 11/07/2019 (dd/mm/yyyy)
   * @description This method is created to call the WS <<operations>> and display the operation list.
   */
  public void getMoreLoadsList() {
    transactionsCallType = 'more';
    getLoadsList();
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
    PageReference p = new Pagereference('/apex/VFER13_Asset_GetLoads');
    p.setRedirect(true);
    return p;
  }

  class LoadWrapper {
    public String product_code { get; set; }
    public String load_ref { get; set; }
    public String loaded_amount { get; set; }
    public String remaining_amount { get; set; }
    public String cleared_amount { get; set; }
    public String start_date { get; set; }
    public String clearing_expiration_date { get; set; }
    public String authorization_expiration_date { get; set; }
    public String ccurrency { get; set; } // currency Name is reserved in Apex so we need to replace in the JSON currency by ccurrency.
    public String creation_date { get; set; }
    public String status { get; set; }

    public LoadWrapper(
      String product_code,
      String load_ref,
      String loaded_amount,
      String remaining_amount,
      String cleared_amount,
      String start_date,
      String clearing_expiration_date,
      String authorization_expiration_date,
      String ccurrency,
      String creation_date,
      String status
    ) {
      this.product_code = product_code;
      this.load_ref = load_ref;
      this.loaded_amount = loaded_amount;
      this.remaining_amount = remaining_amount;
      this.cleared_amount = cleared_amount;
      this.start_date = start_date;
      this.clearing_expiration_date = clearing_expiration_date;
      this.authorization_expiration_date = authorization_expiration_date;
      this.ccurrency = ccurrency;
      this.creation_date = creation_date;
      this.status = status;
    }
  }

  public class VisualforceException extends Exception {
  }
}