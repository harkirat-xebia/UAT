/*
~ Author            : Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date      : 06/10/2018 (dd/mm/yyyy)
~ Description       : Controller of the VFER03_Asset_BlockCard
                      This class allows users to perform :
                        * Block Card WS
                        * Create or Link Activity to an existing employee's Case

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/

public class VFCER03_Asset_BlockCard {
  public Asset currentAsset { get; set; }
  public Asset updateAsset;
  public String selectedCase { get; set; }
  public String selectedReason { get; set; }
  public Boolean showError { get; set; }
  public Boolean isValidReason { get; set; }
  public List<String> assetFields;
  public String errorMessages;
  public Boolean wsSuccess { get; set; }
  public String messageStyle { get; set; }
  public String caseID { get; set; }
  public Boolean wsCalledAtLeastOnce { get; set; }

  public VFCER03_Asset_BlockCard(ApexPages.StandardController controller) {
    assetFields = new List<String>();
    assetFields.add('Status');
    assetFields.add('Name');
    assetFields.add('ER_Asset_Type__c');
    assetFields.add('ER_Asset_Status_Last_Modified_Date__c');
    assetFields.add('Account.ER_Portal_username__c');
    assetFields.add('ER_Employee__r.ER_National_ID_Number__c');
    assetFields.add('ER_Block_Card_Reason__c');
    assetFields.add('ER_Product_Class__c');
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

  public void blockCard() {
    wsCalledAtLeastOnce = true;
    showError = false;
    errorMessages = '';
    isValidReason = false;
    try {
      if ((selectedReason != null)) {
        if (selectedReason.equalsIgnoreCase(currentAsset.ER_Block_Card_Reason__c)) {
          errorMessages =
            '<b>' +
            Label.LAB_SF_Asset_BlockCard_Invalid_Action +
            ' :</b> ' +
            Label.LAB_SF_Asset_BlockCard_Temporary_Blocked_Error;
          throw new VisualforceException(errorMessages);
        }
      }
      selectedReason = currentAsset.ER_Block_Card_Reason__c;
      System.debug('selectedReason : ' + selectedReason);
      WSER03_BlockCardDetails.CardBlockResponse blockCard = WSER03_BlockCardDetails.blockCard(
        currentAsset.ER_Product_Class__c,
        currentAsset.Name,
        selectedReason.toUpperCase()
      );

      if (
        blockCard != null &&
        blockCard.meta != null &&
        blockCard.meta.status != null &&
        blockCard.meta.status.equalsIgnoreCase('succeeded')
      ) {
        errorMessages = Label.LAB_SF_Asset_BlockCard_wsSuccessText;
        showError = true;
        wsSuccess = true;
        isValidReason = true;
        messageStyle = 'slds-theme_success';
        Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, errorMessages));
      } else {
        Integer index = 0;
        String messageText;
        List<WSER03_BlockCardDetails.Message> cardBlockMessages = (blockCard.meta.messages != null
          ? blockCard.meta.messages
          : blockCard.meta.message);
        for (WSER03_BlockCardDetails.Message message : cardBlockMessages) {
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
      System.debug('###OLA Exception block Card: ' + e.getMessage());
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
  public static void updateAsset(String recordId, String reason) {
    Asset assetRecord = new Asset();
    assetRecord.id = recordId;
    assetRecord.ER_Block_Card_Reason__c = reason;
    //assetRecord.Status = Label.LAB_SF_Asset_Blocked;
    assetRecord.ER_Asset_Status_Last_Modified_Date__c = Datetime.now();
    update assetRecord;
  }

  public void createNewCase() {
    showError = false;
    try {
      if (wsCalledAtLeastOnce) {
        Case newCase;
        system.debug('er block card reason: ' + currentAsset.ER_Block_Card_Reason__c);
        if (currentAsset.ER_Block_Card_Reason__c == Label.LAB_SF_Asset_TemporaryBlocked)
          newCase = APER08_Case_Management.CreateCase(
            Label.LAB_SF_Case_Reason_Block,
            Label.LAB_SF_Case_TemporaryBlock,
            currentAsset.id
          );
        else
          newCase = APER08_Case_Management.CreateCase(
            Label.LAB_SF_Case_Reason_Block,
            Label.LAB_SF_Case_PermanentBlock,
            currentAsset.id
          );
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
      taskSubject = Label.LAB_SF_Task_BlockCardSuccess;
    } else {
      taskSubject = Label.LAB_SF_Task_BlockCardFailed;
    }

    return taskSubject;
  }

  public class VisualforceException extends Exception {
  }
}