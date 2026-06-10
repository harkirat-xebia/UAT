public class VFCER08_Asset_SpendingProfile {
  public Asset currentAsset { get; set; }
  public Boolean showError { get; set; }
  public List<String> assetFields;
  public String errorMessages;
  public String transactionValueLimit { get; set; }
  public String transactionCountLimit { get; set; }
  public List<SpendingCategoryRuleWrapper> spendingCategoryRulesList { get; set; }
  public List<TimeRuleWrapper> timeRulesList { get; set; }
  public Boolean isOfflineBU { get; set; }

  public VFCER08_Asset_SpendingProfile(ApexPages.StandardController controller) {
    assetFields = new List<String>();

    assetFields.add('Accountid');
    assetFields.add('Account.ER_Portal_username__c');
    assetFields.add('Status');
    assetFields.add('Name');
    assetFields.add('ER_Asset_Type__c');
    assetFields.add('ER_Asset_Status_Last_Modified_Date__c');
    assetFields.add('ER_Product_Class__c');
    assetFields.add('recordtype.Developername');

    if (!Test.isRunningTest())
      controller.addFields(assetFields);

    currentAsset = (Asset) controller.getRecord();
    showError = false;
    isOfflineBU = APER06_WebserviceUtility.Offline_Service_WS;
  }

  public void getSpendingProfileList() {
    transactionValueLimit = '';
    transactionCountLimit = '';
    errorMessages = '';
    showError = false;
    spendingCategoryRulesList = new List<SpendingCategoryRuleWrapper>{};
    timeRulesList = new List<TimeRuleWrapper>{};

    try {
      WSER08_SpendingProfileDetails.SpendingProfileResponse spendingProfileResponse = WSER08_SpendingProfileDetails.getSpendingProfile(
        currentAsset.Account.ER_Portal_username__c
      );
      if (
        spendingProfileResponse != null &&
        spendingProfileResponse.meta != null &&
        spendingProfileResponse.meta.status != null &&
        spendingProfileResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        for (WSER08_SpendingProfileDetails.SpendingProfile spendingProfile : spendingProfileResponse.data) {
          transactionValueLimit = spendingProfile.transactionValueLimit;
          transactionCountLimit = spendingProfile.transactionCountLimit;
          for (WSER08_SpendingProfileDetails.SpendingCategoryRule scr : spendingProfile.spendingCategoryRules)
            spendingCategoryRulesList.add(new SpendingCategoryRuleWrapper(scr.balance, scr.decision, scr.category));
          for (WSER08_SpendingProfileDetails.TimeRule tr : spendingProfile.timeRulesLimits)
            timeRulesList.add(new TimeRuleWrapper(tr.day, tr.decision, tr.slotSpendLimit, tr.startTime, tr.endTime));
        }
      } else {
        Integer index = 0;
        String messageText;
        List<WSER08_SpendingProfileDetails.Message> spendingProfileMessages = (spendingProfileResponse.meta.messages !=
          null
          ? spendingProfileResponse.meta.messages
          : spendingProfileResponse.meta.message);
        for (WSER08_SpendingProfileDetails.Message message : spendingProfileMessages) {
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
      showError = true;
      System.debug('VFCER08_Asset_SpendingProfile.getSecretQuestion Exception : ' + e.getMessage());
    }
  }

  public class SpendingCategoryRuleWrapper {
    public String balance { get; set; }
    public String decision { get; set; }
    public String category { get; set; }

    public SpendingCategoryRuleWrapper(String balance, String decision, String category) {
      this.balance = balance;
      this.decision = decision;
      this.category = category;
    }
  }

  public class TimeRuleWrapper {
    public String day { get; set; }
    public String decision { get; set; }
    public String slotSpendLimit { get; set; }
    public String startTime { get; set; }
    public String endTime { get; set; }

    public TimeRuleWrapper(String day, String decision, String slotSpendLimit, String startTime, string endTime) {
      this.day = day;
      this.decision = decision;
      this.slotSpendLimit = slotSpendLimit;
      this.startTime = startTime;
      this.endTime = endTime;
    }
  }
}