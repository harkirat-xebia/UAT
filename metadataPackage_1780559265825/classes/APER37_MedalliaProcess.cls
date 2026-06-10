//Class for Medallia Pulse secure process

public class APER37_MedalliaProcess {
  /**
   * @date 01/02/2022
   * @description Send Medallia Invitation
   * @param accounts
   */
  /*public static void sendInvitationWhenFirstVisitChanged(List<Account> accounts) {
    Set<Id> accountIds = new Set<Id>();
    List<Account> individualAccountList = new List<Account>();
    Map<Id, Account> individualAccountsMap = new Map<Id, Account>();
    Map<Id, Contact> mapClientContacts = new Map<Id, Contact>();
    Map<Id, Contact> mapMerchantContacts = new Map<Id, Contact>();
    List<String> medalliaDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_DEPLOYED_BUS)
      ?.split(Constants.SEMICOLON);

    for (Account acc : accounts) {
      if (
        medalliaDeployedBUs != null &&
        (medalliaDeployedBUs.contains(acc.ER_BUPicklist__c) || medalliaDeployedBUs.contains(Constants.ALL))
      ) {
        if (
          acc.ER_Status__c == Constants.ACTIVE &&
          acc.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT)
        ) {
          accountIds.add(acc.Id);
        } else if (
          acc.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_INDVIDUAL_RT)
        ) {
          List<String> triggerDates = acc.ER_Medallia_Invitation_Trigger_Date__c?.split(Constants.SLASH);
          if (
            (triggerDates != null &&
            triggerDates[0].isNumeric() &&
            triggerDates[1].isNumeric() &&
            Integer.valueOf(triggerDates[0]) == Date.today().day() &&
            Integer.valueOf(triggerDates[1]) == Date.today().month()) ||
            (acc.ER_Medallia_Invitation_Week_Number__c != null &&
            acc.ER_Medallia_Invitation_Week_Number__c == Utils.getWeekNumber(Date.today()))
          ) {
            individualAccountList.add(acc);
            individualAccountsMap.put(acc.Id, acc);
          }
        }
      }
    }

    if (!accounts.isEmpty()) {
      //ALK - Get Contact Scope from Contact Role
      for (ER_Contact_Role__c cr : [
        SELECT
          ER_Contact__c,
          ER_Contact__r.ER_Do_not_contact__c,
          ER_Contact__r.ER_Do_Not_Mail__c,
          ER_Contact__r.HasOptedOutOfEmail,
          RecordType.DeveloperName
        FROM ER_Contact_Role__c
        WHERE ER_Contact__r.AccountId IN :accountIds AND ER_Contact__r.ER_Status__c = :Constants.ACTIVE
      ]) {
        if (cr.RecordType.DeveloperName == Constants.CONTACT_ROLE_DS_RT)
          mapClientContacts.put(
            cr.ER_Contact__c,
            new Contact(
              Id = cr.ER_Contact__c,
              ER_Do_not_contact__c = cr.ER_Contact__r.ER_Do_not_contact__c,
              ER_Do_Not_Mail__c = cr.ER_Contact__r.ER_Do_Not_Mail__c,
              HasOptedOutOfEmail = cr.ER_Contact__r.HasOptedOutOfEmail
            )
          );
        if (cr.RecordType.DeveloperName == Constants.CONTACT_ROLE_DP_RT)
          mapClientContacts.put(
            cr.ER_Contact__c,
            new Contact(
              Id = cr.ER_Contact__c,
              ER_Do_not_contact__c = cr.ER_Contact__r.ER_Do_not_contact__c,
              ER_Do_Not_Mail__c = cr.ER_Contact__r.ER_Do_Not_Mail__c,
              HasOptedOutOfEmail = cr.ER_Contact__r.HasOptedOutOfEmail
            )
          );
        if (cr.RecordType.DeveloperName == Constants.CONTACT_ROLE_FCC_RT)
          mapClientContacts.put(
            cr.ER_Contact__c,
            new Contact(
              Id = cr.ER_Contact__c,
              ER_Do_not_contact__c = cr.ER_Contact__r.ER_Do_not_contact__c,
              ER_Do_Not_Mail__c = cr.ER_Contact__r.ER_Do_Not_Mail__c,
              HasOptedOutOfEmail = cr.ER_Contact__r.HasOptedOutOfEmail
            )
          );
        if (cr.RecordType.DeveloperName == Constants.CONTACT_ROLE_FCM_RT)
          mapMerchantContacts.put(
            cr.ER_Contact__c,
            new Contact(
              Id = cr.ER_Contact__c,
              ER_Do_not_contact__c = cr.ER_Contact__r.ER_Do_not_contact__c,
              ER_Do_Not_Mail__c = cr.ER_Contact__r.ER_Do_Not_Mail__c,
              HasOptedOutOfEmail = cr.ER_Contact__r.HasOptedOutOfEmail
            )
          );
        if (cr.RecordType.DeveloperName == Constants.CONTACT_ROLE_STORE_RT)
          mapMerchantContacts.put(
            cr.ER_Contact__c,
            new Contact(
              Id = cr.ER_Contact__c,
              ER_Do_not_contact__c = cr.ER_Contact__r.ER_Do_not_contact__c,
              ER_Do_Not_Mail__c = cr.ER_Contact__r.ER_Do_Not_Mail__c,
              HasOptedOutOfEmail = cr.ER_Contact__r.HasOptedOutOfEmail
            )
          );
      }

      //ALK - Get Contact Scope from Opportunity Contact Role
      for (OpportunityContactRole ocr : [
        SELECT
          ContactId,
          Contact.ER_Do_not_contact__c,
          Contact.ER_Do_Not_Mail__c,
          Contact.HasOptedOutOfEmail,
          OpportunityId,
          Opportunity.RecordType.DeveloperName
        FROM OpportunityContactRole
        WHERE Opportunity.AccountId IN :accountIds AND Contact.ER_Status__c = :Constants.ACTIVE
      ]) {
        if (ocr.Opportunity.RecordType.DeveloperName == Constants.OPPORTUNITY_MERCHANT_RT)
          mapMerchantContacts.put(
            ocr.ContactId,
            new Contact(
              Id = ocr.ContactId,
              ER_Do_not_contact__c = ocr.Contact.ER_Do_not_contact__c,
              ER_Do_Not_Mail__c = ocr.Contact.ER_Do_Not_Mail__c,
              HasOptedOutOfEmail = ocr.Contact.HasOptedOutOfEmail
            )
          );
        if (ocr.Opportunity.RecordType.DeveloperName == Constants.OPPORTUNITY_CLIENT_RT)
          mapClientContacts.put(
            ocr.ContactId,
            new Contact(
              Id = ocr.ContactId,
              ER_Do_not_contact__c = ocr.Contact.ER_Do_not_contact__c,
              ER_Do_Not_Mail__c = ocr.Contact.ER_Do_Not_Mail__c,
              HasOptedOutOfEmail = ocr.Contact.HasOptedOutOfEmail
            )
          );
      }

      //ALK - If A contact exists in both sets client and merchant this one should be removed from teh merchant set.
      for (Id cId : mapClientContacts.keySet()) {
        if (mapMerchantContacts.containsKey(cId))
          mapMerchantContacts.remove(cId);
      }

      for (Contact c : [
        SELECT Id, ER_Do_not_contact__c, ER_Do_Not_Mail__c, HasOptedOutOfEmail
        FROM Contact
        WHERE
          AccountId IN :accountIds
          AND ER_Status__c = :Constants.ACTIVE
          AND Id NOT IN :mapClientContacts.keySet()
          AND Id NOT IN :mapMerchantContacts.keySet()
      ]) {
        mapClientContacts.put(c.Id, c);
      }

      //update field on contact
      Map<String, List<Contact>> mapContactsPerScope = new Map<String, List<Contact>>{
        Constants.CLIENT => mapClientContacts.values(),
        Constants.MERCHANT => mapMerchantContacts.values()
      };
      updateCustomerType(mapContactsPerScope);

      //Send Client invite
      if (!mapClientContacts.values().isEmpty())
        sendMedalliaInvitation(
          mapClientContacts.values(),
          Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_PULSE_SURVEY),
          Constants.CONTACT
        );

      //Send Merchant invite
      if (!mapMerchantContacts.values().isEmpty())
        sendMedalliaInvitation(
          mapMerchantContacts.values(),
          Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_PULSE_SURVEY),
          Constants.CONTACT
        );
    }

    //Send Individual invite
    if (!individualAccountList.isEmpty()) {
      String npsDateSurvey = Utils.getNPSDateSurvey();
      Integer npsWeekSurvey = Utils.getWeekNumber(Date.today());
      for (Account acc : [
        SELECT
          Id,
          ER_Medallia_Invitation_Week_Number__c,
          ER_Medallia_Invitation_Trigger_Date__c,
          RecordTypeId,
          ER_Status__c,
          (SELECT Id FROM medallia_xm__Invitations__r LIMIT 1)
        FROM Account
        WHERE
          IsPersonAccount = TRUE
          AND ER_Status__c = :Constants.ACTIVE
          AND RecordTypeId = :Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_INDVIDUAL_RT)
          AND (ER_Medallia_Invitation_Week_Number__c = :npsWeekSurvey
          OR ER_Medallia_Invitation_Trigger_Date__c = :npsDateSurvey)
          AND Id NOT IN :individualAccountsMap.keySet()
      ]) {
        if (acc.medallia_xm__Invitations__r.isEmpty())
          individualAccountList.add(acc);
      }

      sendMedalliaInvitation(
        individualAccountList,
        Utils.getGlobalSettingsValueFromKey(Constants.MEDALLIA_PULSE_SURVEY_B2C),
        Constants.INDIVIDUAL
      );
    }
  }*/

  /**
   * @author ALK
   * @description Send Medallia Invitation
   * @date 14/02/2022
   * @param items
   * @param serviceType
   * @param objectType
   */
  /*public static void sendMedalliaInvitation(List<SObject> items, String serviceType, String objectType) {
    List<medallia_xm.QueueItemPayload> itemPayloads = new List<medallia_xm.QueueItemPayload>();
    for (SObject obj : items) {
      medallia_xm.QueueItemPayload payload = new medallia_xm.QueueItemPayload();
      payload.fieldSet = Constants.MEDALLIA_FIELDSET_CREATE_SURVEY;
      payload.service = serviceType;
      payload.whenToSend = Datetime.now();
      payload.sendInvite = true;
      //payload.medProgramId = 'Replace with Program Id or Medallia Spec Id';

      if (objectType == Constants.CONTACT) {
        Contact c = (Contact) obj;
        if (!c.ER_Do_not_contact__c && !c.ER_Do_Not_Mail__c && !c.HasOptedOutOfEmail)
          payload.recordId = c.Id;
      } else if (objectType == Constants.INDIVIDUAL) {
        Account a = (Account) obj;
        if (!a.ER_Do_not_contact__pc && !a.ER_Do_Not_Mail__pc && !a.PersonHasOptedOutOfEmail)
          payload.recordId = a.Id;
      }
      if (String.isNotBlank(payload.recordId))
        itemPayloads.add(payload);
    }

    if (!itemPayloads.isEmpty())
      medallia_xm.MedGenericProcess.Process(itemPayloads);
  }*/

  /**
   * @date 01/02/2022
   * @description Update the contact type
   * @param mapContacts
   */
  /*public static void updateCustomerType(Map<String, List<Contact>> mapContacts) {
    Map<Id, Contact> contacts = new Map<Id, Contact>();
    for (String scope : mapContacts.keySet()) {
      if (scope == Constants.MERCHANT) {
        for (Contact c : mapContacts.get(scope))
          contacts.put(c.Id, new Contact(Id = c.Id, ER_med_pr_customer_type__c = Constants.MERCHANT));
      } else if (scope == Constants.CLIENT) {
        for (Contact c : mapContacts.get(scope))
          contacts.put(c.Id, new Contact(Id = c.Id, ER_med_pr_customer_type__c = Constants.CLIENT));
      }
    }

    if (!contacts.isEmpty())
      update contacts.values();
  }*/
}