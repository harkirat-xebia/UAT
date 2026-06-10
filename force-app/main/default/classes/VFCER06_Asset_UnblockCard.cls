public class VFCER06_Asset_UnblockCard {
  public Asset currentAsset { get; set; }
  public Asset updateAsset;
  public String selectedCase { get; set; }
  public String selectedReason { get; set; }
  public Boolean showError { get; set; }
  public List<String> assetFields;
  public String errorMessages;
  public Boolean wsSuccess { get; set; }
  public String messageStyle { get; set; }
  public String caseID { get; set; }
  public Boolean wsCalledAtLeastOnce { get; set; }

  public VFCER06_Asset_UnblockCard(ApexPages.StandardController controller) {
    assetFields = new List<String>();
    assetFields.add('Status');
    assetFields.add('Name');
    assetFields.add('ER_Asset_Type__c');
    assetFields.add('ER_Asset_Status_Last_Modified_Date__c');
    assetFields.add('Account.ER_Portal_username__c');
    assetFields.add('ER_Employee__r.ER_National_ID_Number__c');
    assetFields.add('ER_Product_Class__c');
    assetFields.add('ER_Block_Card_Reason__c');
    assetFields.add('ER_Employee__c');
    assetFields.add('ER_Employee__r.Name');
    assetFields.add('ER_Employee__r.ER_Client__c');
    assetFields.add('ER_Employee__r.ER_Delivery_Address_City__c');
    assetFields.add('ER_Employee__r.ER_Date_of_birth__c');
    assetFields.add('ER_Employee__r.ER_Delivery_Address_Country__c');
    assetFields.add('ER_Employee__r.ER_Delivery_Address_Street__c');
    assetFields.add('ER_Employee__r.ER_Delivery_Address_Zip_Code__c');

    if (!Test.isRunningTest())
      controller.addFields(assetFields);

    currentAsset = (Asset) controller.getRecord();
    updateAsset = currentAsset;
    selectedReason = currentAsset.ER_Block_Card_Reason__c;
    wsCalledAtLeastOnce = false;
    wsSuccess = false;
  }

  public List<SelectOption> getrequetesOptions() {
    List<SelectOption> requeteOptions = new List<SelectOption>();
    requeteOptions.add(new SelectOption('', '--' + Label.LAB_SF_None + '--'));
    if (String.isNotBlank(currentAsset.ER_Employee__c)) {
      requeteOptions = APER08_Case_Management.GetEmployeeCaseOptions(currentAsset.ER_Employee__c);
    }

    return requeteOptions;
  }

  public void UnblockCard() {
    wsCalledAtLeastOnce = true;
    showError = false;
    errorMessages = '';
    try {
      WSER06_UnblockCardDetails.CardUnblockResponse UnblockCard = WSER06_UnblockCardDetails.UnblockCard(
        currentAsset.ER_Product_Class__c,
        currentAsset.Name
      );

      if (
        UnblockCard != null &&
        UnblockCard.meta != null &&
        UnblockCard.meta.status != null &&
        UnblockCard.meta.status.equalsIgnoreCase('succeeded')
      ) {
        errorMessages = Label.LAB_SF_Asset_UnblockCard_wsSuccessText;
        showError = true;
        wsSuccess = true;
        if (UnblockCard.data.status == Label.LAB_SF_ASSET_Inactive) {
          currentAsset.Status = Label.LAB_SF_ASSET_Issued;
        } else {
          currentAsset.Status = UnblockCard.data.status;
        }
        messageStyle = 'slds-theme_success';
        Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, errorMessages));
      } else {
        Integer index = 0;
        String messageText;
        List<WSER06_UnblockCardDetails.Message> cardUnblockMessages = (UnblockCard.meta.messages != null
          ? UnblockCard.meta.messages
          : UnblockCard.meta.message);
        for (WSER06_UnblockCardDetails.Message message : cardUnblockMessages) {
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
      messageStyle = 'slds-theme_error';
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      showError = true;
      System.debug('###OLA Exception unblock Card: ' + e.getMessage());
    }
  }

  public void linkCase() {
    showError = false;
    try {
      if (wsCalledAtLeastOnce) {
        caseID = selectedCase;
        String taskSubject = getTaskSubject();
        APER09_Task_Management.CreateTask(taskSubject, Label.LAB_SF_Task_StatusCompleted, caseID);
      }
    } catch (Exception e) {
      showError = true;
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
    }
  }

  @RemoteAction
  public static void updateAsset(String recordId, String reason, String status) {
    Asset assetRecord = new Asset();
    assetRecord.id = recordId;
    assetRecord.ER_Block_Card_Reason__c = '';
    assetRecord.Status = status;
    assetRecord.ER_Asset_Status_Last_Modified_Date__c = Datetime.now();
    update assetRecord;
  }

  public void createNewCase() {
    showError = false;
    try {
      if (wsCalledAtLeastOnce) {
        Case newCase = APER08_Case_Management.CreateCase(
          Label.LAB_SF_Case_Reason_Unblock,
          Label.LAB_SF_Case_Unblock,
          currentAsset.id
        ); // reason + detailed reasons ? KHAD
        caseID = newCase.id;
        String taskSubject = getTaskSubject();
        APER09_Task_Management.CreateTask(taskSubject, Label.LAB_SF_Task_StatusCompleted, caseID);
      }
    } catch (Exception e) {
      showError = true;
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
    }
  }

  public String getTaskSubject() {
    String taskSubject = '';
    System.debug(wsSuccess);
    if (wsSuccess) {
      taskSubject = Label.LAB_SF_Task_UnblockCardSuccess;
    } else {
      taskSubject = Label.LAB_SF_Task_UnblockCardFailed;
    }

    return taskSubject;
  }

  public class VisualforceException extends Exception {
  }
}