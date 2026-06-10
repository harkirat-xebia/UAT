/*
~ Author            : Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date      : 06/10/2018 (dd/mm/yyyy)
~ Description       : Controller of the VFER02_Asset_PinReset
                      This class allows users to perform :
                        * Pin Reset WS
                        * Create or Link Activity to an existing employee's Case

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/

public class VFCER02_Asset_PinReset {
  public Asset currentAsset { get; set; }
  public Asset updateAsset;
  public String selectedCase { get; set; }
  public Boolean showError { get; set; }
  public List<String> assetFields;
  public String errorMessages;
  public String pinCode { get; set; }
  public String caseID { get; set; }
  public Boolean wsCalledAtLeastOnce { get; set; }
  public Boolean wsSuccess { get; set; }
  public String userBU { get; set; }

  public VFCER02_Asset_PinReset(ApexPages.StandardController controller) {
    userBU = APER10_User_Management.userBU;
    assetFields = new List<String>();
    assetFields.add('Status');
    assetFields.add('Name');
    assetFields.add('ER_Asset_Type__c');
    assetFields.add('ER_Asset_Status_Last_Modified_Date__c');
    assetFields.add('Account.ER_Portal_username__c');
    assetFields.add('ER_Employee__r.ER_National_ID_Number__c');
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
  public void getPinCode() {
    wsCalledAtLeastOnce = true;
    pinCode = '';
    errorMessages = '';
    showError = false;
    try {
      WSER04_PinResetDetails.CardPinResetResponse cardPin = WSER04_PinResetDetails.requestPinReset(
        currentAsset.ER_Product_Class__c,
        currentAsset.Name
      );
      if (
        cardPin != null &&
        cardPin.meta != null &&
        cardPin.meta.status != null &&
        cardPin.meta.status.equalsIgnoreCase('succeeded')
      ) {
        for (WSER04_PinResetDetails.PinCode pin : cardPin.data) {
          pinCode = pin.reset_code;
          wsSuccess = true;
        }
      } else {
        Integer index = 0;
        String messageText;
        List<WSER04_PinResetDetails.Message> cardPinMessages = (cardPin.meta.messages != null
          ? cardPin.meta.messages
          : cardPin.meta.message);
        for (WSER04_PinResetDetails.Message message : cardPinMessages) {
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
      System.debug('VFCER02_Asset_PinReset.getPinCode Exception : ' + e.getMessage());
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
      System.debug('VFCER02_Asset_PinReset.linkCase Exception : ' + e.getMessage());
    }
  }
  public void createNewCase() {
    showError = false;
    try {
      if (wsCalledAtLeastOnce) {
        Case newCase = APER08_Case_Management.CreateCase(
          Label.LAB_SF_Case_Reason_PinReset,
          Label.LAB_SF_Case_PinReset,
          currentAsset.id
        );
        caseID = newCase.id;
        String taskSubject = getTaskSubject();
        APER09_Task_Management.CreateTask(taskSubject, Label.LAB_SF_Task_StatusCompleted, caseID);
      }
    } catch (Exception e) {
      showError = true;
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      System.debug('VFCER02_Asset_PinReset.createNewCase Exception : ' + e.getMessage());
    }
  }
  public String getTaskSubject() {
    String taskSubject = '';

    if (wsSuccess) {
      taskSubject = Label.LAB_SF_Task_PinResetSuccess;
    } else {
      taskSubject = Label.LAB_SF_Task_PinResetFailed;
    }

    return taskSubject;
  }

  public class VisualforceException extends Exception {
  }
}