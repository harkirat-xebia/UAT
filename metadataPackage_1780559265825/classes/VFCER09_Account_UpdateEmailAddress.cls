public class VFCER09_Account_UpdateEmailAddress {
  public Account currentAcc { get; set; }
  public Account updateAcc;
  public Boolean showError { get; set; }
  public String secretQuestion { get; set; }
  public String secretAnswer { get; set; }
  public String OSId { get; set; }
  public List<String> accFields;
  public String errorMessages;
  public String body;
  public String newEmailAddress { get; set; }
  public String caseID { get; set; }
  public Boolean wsCalledAtLeastOnce { get; set; }
  public Boolean wsSuccess { get; set; }
  public String userBU { get; set; }
  public Boolean isDisabled { get; set; }

  public VFCER09_Account_UpdateEmailAddress(ApexPages.StandardController controller) {
    userBU = APER10_User_Management.userBU;
    accFields = new List<String>();
    accFields.add('Name');
    accFields.add('PersonBirthdate');
    accFields.add('ER_Portal_username__c');
    accFields.add('ER_National_ID_Number__c');
    accFields.add('PersonMailingStreet');
    accFields.add('PersonMailingCity');
    accFields.add('PersonMailingCountry');
    accFields.add('PersonMailingPostalCode');
    accFields.add('PersonEmail');
    accFields.add('ER_Card_Operational_System_ID__c');

    if (!Test.isRunningTest())
      controller.addFields(accFields);
    currentAcc = (Account) controller.getRecord();
    updateAcc = currentAcc;
    wsSuccess = false;
    isDisabled = true;
    newEmailAddress = currentAcc.PersonEmail;
  }

  public void createNewCase() {
    showError = false;
    try {
      if (wsCalledAtLeastOnce) {
        Case newCase = APER08_Case_Management.CreateIndividualCase(currentAcc.id);
        String taskSubject = getTaskSubject();
        caseId = newCase.id;
        APER09_Task_Management.CreateTask(taskSubject, Label.LAB_SF_Task_StatusCompleted, caseId);
      }
    } catch (Exception e) {
      showError = true;
      Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
      System.debug('VFCER09_Account_UpdateEmailAddress.createNewCase Exception : ' + e.getMessage());
    }
  }

  public String getTaskSubject() {
    String taskSubject = '';

    if (wsSuccess) {
      taskSubject = Label.LAB_SF_Task_UpdateEmailAddressSuccess;
    } else {
      taskSubject = Label.LAB_SF_Task_UpdateEmailAddressFailed;
    }

    return taskSubject;
  }

  public void getSecretQuestion() {
    wsCalledAtLeastOnce = true;
    OSId = currentAcc.ER_Card_Operational_System_ID__c.substringAfterLast('_');
    system.debug('@@@ Card Op Id: ' + currentAcc.ER_Card_Operational_System_ID__c);
    system.debug('@@@ OSid is: ' + OSId);
    secretQuestion = '';
    secretAnswer = '';
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
        system.debug('#### security question: ' + secretQAResponse);
        system.debug('#### security question question: ' + secretQAResponse.data.secret_question);
        system.debug('#### security question answer: ' + secretQAResponse.data.secret_answer);
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

  public void sendNewEmailAddress() {
    System.debug('@@@ newEmailAddress : ' + newEmailAddress);
    wsCalledAtLeastOnce = true;
    OSId = currentAcc.ER_Card_Operational_System_ID__c.substringAfterLast('_');
    system.debug('@@@ Card Op Id: ' + currentAcc.ER_Card_Operational_System_ID__c);
    system.debug('@@@ OSid is: ' + OSId);
    errorMessages = '';
    showError = false;
    body = '{"personal_info":{"email":"' + newEmailAddress + '"}}';
    try {
      WSER09_UpdateEmailAddress.UpdateEmailAddressResponse updateEmailResponse = WSER09_UpdateEmailAddress.updateEmailAddress(
        OSId,
        body
      );
      if (
        updateEmailResponse != null &&
        updateEmailResponse.meta != null &&
        updateEmailResponse.meta.status != null &&
        updateEmailResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        // create case & update email
        Account thisAcc = [SELECT ID, PersonEmail FROM Account WHERE ID = :currentAcc.Id];
        thisAcc.PersonEmail = newEmailAddress;
        update thisAcc;
        createNewCase();
      } else {
        Integer index = 0;
        String messageText;
        List<WSER09_UpdateEmailAddress.Message> updateEmailMessages = (updateEmailResponse.meta.messages != null
          ? updateEmailResponse.meta.messages
          : updateEmailResponse.meta.message);
        for (WSER09_UpdateEmailAddress.Message message : updateEmailMessages) {
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
      System.debug('VFCER09_Account_UpdateEmailAddress.sendNewEmailAddress Exception : ' + e.getMessage());
    }
  }
}