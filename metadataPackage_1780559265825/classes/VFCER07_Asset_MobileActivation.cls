/*
~ Author            : Nicolae CIAUSU
~ Created Date      : 27/12/2019 (dd/mm/yyyy)
~ Description       : Controller of the VFER07_Asset_MobileActivation
                      This class allows users to perform :
                        * Mobile Activation WS
                        * Create or Link Activity to an existing employee's Case

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/

public class VFCER07_Asset_MobileActivation {
  public Asset currentAsset { get; set; }
  public Asset updateAsset;
  public String selectedCase { get; set; }
  public Boolean showError { get; set; }
  public List<String> assetFields;
  public String errorMessages;
  public String secretQuestion { get; set; }
  public String secretAnswer { get; set; }
  public String OSId { get; set; }
  public String panNumber { get; set; }
  public String caseID { get; set; }
  public Boolean wsCalledAtLeastOnce { get; set; }
  public Boolean wsSuccess { get; set; }
  public String userBU { get; set; }
  public Boolean isDisabled { get; set; }

  public VFCER07_Asset_MobileActivation(ApexPages.StandardController controller) {
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
    assetFields.add('ER_Card_Operational_System_ID__c');

    if (!Test.isRunningTest())
      controller.addFields(assetFields);

    currentAsset = (Asset) controller.getRecord();
    updateAsset = currentAsset;
    wsSuccess = false;
    isDisabled = true;
  }
  public List<SelectOption> getrequetesOptions() {
    List<SelectOption> requeteOptions = new List<SelectOption>();
    requeteOptions.add(new SelectOption('', '--' + Label.LAB_SF_None + '--'));
    if (String.isNotBlank(currentAsset.ER_Employee__c)) {
      requeteOptions = APER08_Case_Management.GetEmployeeCaseOptions(currentAsset.ER_Employee__c);
    }
    return requeteOptions;
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
      System.debug('VFCER07_Asset_MobileActivation.linkCase Exception : ' + e.getMessage());
    }
  }
  public void createNewCase() {
    showError = false;
    try {
      if (wsCalledAtLeastOnce) {
        Case newCase = APER08_Case_Management.CreateCase(
          Label.LAB_SF_Case_Reason_MobileActivation,
          null,
          currentAsset.id
        );
        caseID = newCase.id;
        String taskSubject = getTaskSubject();
        APER09_Task_Management.CreateTask(taskSubject, Label.LAB_SF_Task_StatusCompleted, caseID);
      }
    } catch (Exception e) {
      showError = true;
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      System.debug('VFCER07_Asset_MobileActivation.createNewCase Exception : ' + e.getMessage());
    }
  }
  public String getTaskSubject() {
    String taskSubject = '';

    if (wsSuccess) {
      taskSubject = Label.LAB_SF_Task_MobileActivationSuccess;
    } else {
      taskSubject = Label.LAB_SF_Task_MobileActivationFailed;
    }

    return taskSubject;
  }

  public void getSecretQuestion() {
    wsCalledAtLeastOnce = true;
    secretQuestion = '';
    secretAnswer = '';
    OSId = currentAsset.ER_Card_Operational_System_ID__c.substringAfterLast('_');
    system.debug('@@@ Card Op Id: ' + currentAsset.ER_Card_Operational_System_ID__c);
    system.debug('@@@ OSid is: ' + OSId);
    errorMessages = '';
    showError = false;
    try {
      WSER07_GetSecurityQuestion.SecurityQuestionResponse secretQAResponse = WSER07_GetSecurityQuestion.getSecurityQuestion(
        OSId
      );
      if (
        secretQAResponse != null &&
        secretQAResponse.meta != null &&
        secretQAResponse.meta.status != null &&
        secretQAResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        //for (WSER07_GetSecurityQuestion.SecurityQuestion securityQuestion : secretQAResponse.data) {
        //secretQuestion = securityQuestion.secret_question;
        //secretAnswer = securityQuestion.secret_answer;
        secretQuestion = secretQAResponse.data.secret_question;
        secretAnswer = secretQAResponse.data.secret_answer;
        wsSuccess = true;
        isDisabled = false;
        //}
      } else {
        Integer index = 0;
        String messageText;
        List<WSER07_GetSecurityQuestion.Message> secretQAMessages = (secretQAResponse.meta.messages != null
          ? secretQAResponse.meta.messages
          : secretQAResponse.meta.message);
        for (WSER07_GetSecurityQuestion.Message message : secretQAMessages) {
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
      System.debug('VFCER07_Asset_MobileActivation.getSecretQuestion Exception : ' + e.getMessage());
    }
  }
  public void getPanNumber() {
    wsCalledAtLeastOnce = true;
    panNumber = '';
    showError = false;
    try {
      WSER05_GetCardDetails.CardDetailResponse partialPanResponse = WSER05_GetCardDetails.getCardDetail(
        currentAsset.ER_Product_Class__c,
        currentAsset.Name
      );
      if (
        partialPanResponse != null &&
        partialPanResponse.meta != null &&
        partialPanResponse.meta.status != null &&
        partialPanResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        if (partialPanResponse.data != null) {
          panNumber = partialPanResponse.data.pan;
          wsSuccess = true;
        }
      } else {
        Integer index = 0;
        String messageText;
        List<WSER05_GetCardDetails.Message> partialPanMessages = (partialPanResponse.meta.messages != null
          ? partialPanResponse.meta.messages
          : partialPanResponse.meta.message);
        for (WSER05_GetCardDetails.Message message : partialPanMessages) {
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
      System.debug('VFCER07_Asset_MobileActivation.getPartialPan Exception : ' + e.getMessage());
    }
  }

  public class VisualforceException extends Exception {
  }
}