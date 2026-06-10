public class VFCER09_Account_UpdateIndividual {
  public Account currentAcc { get; set; }
  public Account updateAcc;
  public Boolean showError { get; set; }
  public String secretQuestion { get; set; }
  public String secretAnswer { get; set; }
  public String OSId { get; set; }
  public List<String> accFields;
  public string indivEmail { get; set; }
  public string indivPostalCode { get; set; }
  public string indivPhoneNumber { get; set; }
  public string indivCity { get; set; }
  public string indivAddress { get; set; } //might become street
  public string indivPortal { get; set; }
  public String errorMessages;
  public String body;
  public String newEmailAddress { get; set; }
  public String newPhoneNumber { get; set; }
  public String newStreet { get; set; }
  public String newPostalCode { get; set; }
  public String newCity { get; set; }
  public String caseID { get; set; }
  public Boolean wsCalledAtLeastOnce { get; set; }
  public Boolean wsSuccess { get; set; }
  public String userBU { get; set; }
  public boolean boolEmailError { get; set; }
  public boolean boolPCError { get; set; }
  public boolean boolPNError { get; set; }
  public boolean boolCityError { get; set; }
  public boolean boolAddressError { get; set; }
  public boolean boolPortalError { get; set; }
  public string emailError { get; set; }

  public VFCER09_Account_UpdateIndividual(ApexPages.StandardController controller) {
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
    accFields.add('Phone');
    accFields.add('ER_Card_Operational_System_ID__c');

    indivAddress = 'Address';
    indivPostalCode = 'PostalCode';
    indivPhoneNumber = 'PhoneNumber';
    indivCity = 'City';
    indivEmail = 'Email';
    indivPortal = 'PortalUSer';

    emailError = 'Email is different, check for errors';
    boolEmailError = false;

    if (!Test.isRunningTest())
      controller.addFields(accFields);
    currentAcc = (Account) controller.getRecord();
    updateAcc = currentAcc;
    wsSuccess = false;
    //newEmailAddress = currentAcc.PersonEmail;
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
      System.debug('VFCER09_Account_UpdateIndividual.createNewCase Exception : ' + e.getMessage());
    }
  }

  public String getTaskSubject() {
    String taskSubject = '';

    if (wsSuccess) {
      taskSubject = Label.LAB_SF_Task_UpdateIndividualSuccess;
    } else {
      taskSubject = Label.LAB_SF_Task_UpdateIndividualFailed;
    }

    return taskSubject;
  }

  public void getSecretQuestion() {
    wsCalledAtLeastOnce = true;
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
  /*
    public void sendNewEmailAddress() {
        System.debug('@@@ newEmailAddress : ' + newEmailAddress);
        wsCalledAtLeastOnce = true;
        errorMessages = '';
        showError = false;
        body = '{"email":"' + newEmailAddress + '"}'; 
        try {
            WSER09_UpdateIndividual.updateIndividualResponse updatePersonAccountResponse = WSER09_UpdateIndividual.updateIndividual(currentAcc.ER_Portal_username__c, body);
            if (updatePersonAccountResponse != null && updatePersonAccountResponse.meta != null && updatePersonAccountResponse.meta.status != null && updatePersonAccountResponse.meta.status.equalsIgnoreCase('succeeded')) {
                // create case & update email
                Account thisAcc = [SELECT ID, PersonEmail FROM Account WHERE ID =: currentAcc.Id];
                thisAcc.PersonEmail = newEmailAddress;
                update thisAcc;
                createNewCase();
                
            } else {
                Integer index = 0;
                String messageText;
                List<WSER09_UpdateIndividual.Message> updateEmailMessages = (updatePersonAccountResponse.meta.messages != null ? updatePersonAccountResponse.meta.messages : updatePersonAccountResponse.meta.message);
                for (WSER09_UpdateIndividual.Message message : updateEmailMessages) {
                    if (String.isNotBlank(message.text) || String.isNotBlank(message.message)) {
                        messageText = String.isNotBlank(message.text) ? message.text : (String.isNotBlank(message.message) ? message.message : '');
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
            System.debug('VFCER09_Account_UpdateIndividual.sendNewEmailAddress Exception : '+e.getMessage());
        }
    }
*/
  public void sendIndividualInfo() {
    System.debug('@@@ newEmailAddress : ' + newEmailAddress);
    wsCalledAtLeastOnce = true;
    OSId = currentAcc.ER_Card_Operational_System_ID__c.substringAfterLast('_');
    system.debug('@@@ Card Op Id: ' + currentAcc.ER_Card_Operational_System_ID__c);
    system.debug('@@@ OSid is: ' + OSId);
    errorMessages = '';
    showError = false;
    body =
      '{"personal_info":{"email":"' +
      indivEmail +
      '","phone_number":"' +
      indivPhoneNumber +
      '","address":{"street":"' +
      indivAddress +
      '","zip_code":"' +
      indivPostalCode +
      '","city":"' +
      indivCity +
      '"}}}';
    try {
      WSER09_UpdateIndividual.updateIndividualResponse updatePersonAccountResponse = WSER09_UpdateIndividual.updateIndividual(
        OSId,
        body
      );
      if (
        updatePersonAccountResponse != null &&
        updatePersonAccountResponse.meta != null &&
        updatePersonAccountResponse.meta.status != null &&
        updatePersonAccountResponse.meta.status.equalsIgnoreCase('succeeded')
      ) {
        // create case & update email
        system.debug('Body: ' + body);
        Account thisAcc = [
          SELECT
            ID,
            PersonEmail,
            PersonMobilePhone,
            Phone,
            PersonMailingStreet,
            PersonMailingPostalCode,
            PersonMailingCity,
            ER_Portal_username__c
          FROM Account
          WHERE ID = :currentAcc.Id
        ];
        thisAcc.PersonEmail = indivEmail;
        thisAcc.Phone = indivPhoneNumber;
        thisAcc.PersonMailingStreet = indivAddress;
        thisAcc.PersonMailingPostalCode = indivPostalCode;
        thisAcc.PersonMailingCity = indivCity;
        thisAcc.ER_Portal_username__c = indivPortal;
        update thisAcc;
        system.debug('Acc: ' + thisacc);
        createNewCase();
      } else {
        Integer index = 0;
        String messageText;
        List<WSER09_UpdateIndividual.Message> updateEmailMessages = (updatePersonAccountResponse.meta.messages != null
          ? updatePersonAccountResponse.meta.messages
          : updatePersonAccountResponse.meta.message);
        for (WSER09_UpdateIndividual.Message message : updateEmailMessages) {
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
      System.debug('VFCER09_Account_UpdateIndividual.sendNewEmailAddress Exception : ' + e.getMessage());
    }
  }

  public void getIndividualInfo() {
    System.debug('@@@ getIndiv');
    wsCalledAtLeastOnce = true;
    errorMessages = '';
    showError = false;
    body = '';

    OSId = currentAcc.ER_Card_Operational_System_ID__c.substringAfterLast('_');
    indivEmail = 'EmailAddress';
    indivPostalCode = 'PostCode';
    indivPhoneNumber = 'Phone';
    indivCity = 'CitiUpdated';
    indivAddress = 'Street';
    indivPortal = 'PortalUsername';

    System.debug('@@@ getIndivAgain');

    try {
      WSER09_UpdateIndividual.CardBalanceResponse getIndiv = WSER09_UpdateIndividual.getIndividual(OSId, body);
      if (
        getIndiv != null &&
        getIndiv.meta != null &&
        getIndiv.meta.status != null &&
        getIndiv.meta.status.equalsIgnoreCase('succeeded')
      ) {
        // create case & update email
        //Account thisAcc = [SELECT ID,ER_Portal_username__c,FirstName,LastName, PersonEmail,PersonMobilePhone,PersonHomePhone, PersonMailingStreet,PersonMailingPostalCode,PersonMailingCity, ER_Employee__c FROM Account WHERE ID =: currentAcc.Id];

        system.debug('Indiv: ' + getIndiv);

        indivEmail = getIndiv.data.personal_info.Email;
        indivPostalCode = getIndiv.data.personal_info.address.zip_code;
        indivPhoneNumber = getIndiv.data.personal_info.phone_number;
        indivCity = getIndiv.data.personal_info.address.city;
        indivAddress = getIndiv.data.personal_info.Address.street;
        indivPortal = getIndiv.data.username;

        system.debug('Email: ' + indivEmail + '| PersonEmail ' + currentAcc.PersonEmail);
        if (indivEmail != currentAcc.PersonEmail) {
          boolEmailError = true;
        }
        if (indivPostalCode != currentAcc.PersonMailingPostalCode) {
          boolPCError = true;
        }
        if (indivPhoneNumber != currentAcc.Phone) {
          boolPNError = true;
        }
        if (indivCity != currentAcc.PersonMailingCity) {
          boolCityError = true;
        }
        if (indivAddress != currentAcc.PersonMailingStreet) {
          boolAddressError = true;
        }
        if (indivPortal != currentAcc.ER_Portal_username__c) {
          boolPortalError = true;
        }

        System.debug('If: ' + indivAddress);
      } else {
        System.debug('Else: ' + indivAddress);
        Integer index = 0;
        String messageText;
        List<WSER09_UpdateIndividual.Message> updateEmailMessages = (getIndiv.meta.messages != null
          ? getIndiv.meta.messages
          : getIndiv.meta.message);
        for (WSER09_UpdateIndividual.Message message : updateEmailMessages) {
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
      System.debug('VFCER09_Account_UpdateIndividual.sendNewEmailAddress Exception : ' + e.getMessage());
    }
  }
}