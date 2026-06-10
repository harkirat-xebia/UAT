/*
----------------------------------------------------------------------
-- - Name          : APER18_Lead_Management
-- - Author        : OLA
-- - Description   : Lead Management, This class is used to group all the functionnality linked to the object Lead
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  Sep-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class APER18_Lead_Management {
  /** @author OLA
   * @date Sep 2019
   * @description manageRating: Manage rating based on lead source value.
   * @param leadList
   */
  public static void manageRating(List<Lead> leadList) {
    for (Lead l : leadList) {
      if (!l.ER_SmartER_Context__c && String.isBlank(l.Rating)) {
        if (Label.LAB_SF_Map_LeadSource_Rating_Cold.split(';').contains(l.LeadSource)) {
          l.Rating = Label.LAB_SF_Lead_Rating_Cold;
        } else if (Label.LAB_SF_Map_LeadSource_Rating_Hot.split(';').contains(l.LeadSource)) {
          l.Rating = Label.LAB_SF_Lead_Rating_Hot;
        } else if (Label.LAB_SF_Map_LeadSource_Rating_Warm.split(';').contains(l.LeadSource)) {
          l.Rating = Label.LAB_SF_Lead_Rating_Warm;
        }
      } else if (l.LeadSource == Constants.LEAD_SOURCE_EFG && String.isBlank(l.Rating))
        l.Rating = Label.LAB_SF_Lead_Rating_Hot;
    }
  }

  /**
   * @author ELAK
   * @param oldItems
   * @param aLeads
   * Manage rating for changed leadSources before updating leads
   */
  public static void manageRatingChangedLS(List<Lead> aLeads, Map<Id, SObject> oldItems) {
    Map<Id, Lead> aLeadMap = (Map<Id, Lead>) oldItems;
    List<Lead> ChangedLeadSource = new List<Lead>();

    for (Lead l : aLeads) {
      if (!l.ER_SmartER_Context__c && l.LeadSource != aLeadMap.get(l.Id).LeadSource) {
        ChangedLeadSource.add(l);
      }
    }

    if (!ChangedLeadSource.isEmpty())
      manageRating(ChangedLeadSource);
  }

  /*
    * COMMENTED AS THIS METHOD IS NOT USED
    * Daniel Sandu
    * Sep 2020
    * manageMerchantLeadCreation: Manage merchant leads created from Case
    *

    public static Void manageMerchantLeadCreation( List<Lead> leadList) {
        for(Lead lead : leadList) {
            lead.ER_Store_Name__c = lead.Company;
        }
    }
    */

  /*
   *
   * Daniel Sandu
   * OCT 2020
   * manageMerchantLeadCreation: Manage merchant leads created by Client Sales users
   *
   */
  public static void manageMerchantLeadCreationByClientSales(List<Lead> leadList) {
    Id merchantRecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT');
    Id clientSalesProfileId = [SELECT Id FROM Profile WHERE Name = 'Client Sales'].Id;
    for (Lead l : leadList) {
      if (!l.ER_SmartER_Context__c) {
        if (l.RecordTypeId == merchantRecordTypeId && System.UserInfo.getProfileId() == clientSalesProfileId) {
          l.Description = Label.LAB_SF_Lead_Description;
          l.ER_Store_Name__c = l.Company;
          l.ER_Lead_Channel__c = Label.LAB_SF_Lead_Channel_Client;
        }
        if (l.RecordTypeId == merchantRecordTypeId)
          l.ER_Lead_Type__c = 'Merchant';
        else
          l.ER_Lead_Type__c = 'Client';
      }
    }
  }

  /*
   *
   * Dragos Avram
   * OCT 2020
   * futureLeadAssignRule: Enforce assignment rule when leads are bulk imported.
   *
   */
  @future
  public static void futureLeadAssignRule(Set<Id> leadAssignmentRule) {
    List<Lead> leadUpdList = [SELECT Id FROM Lead WHERE Id IN :leadAssignmentRule];
    for (Lead l : leadUpdList) {
      Database.DMLOptions dmo = new Database.DMLOptions();
      dmo.assignmentRuleHeader.useDefaultRule = true;
      l.setOptions(dmo);
    }
    update leadUpdList;
  }

  /**
   * @author ELAK
   * @param leads
   */
  public static void manageLeadAssignRule(List<Lead> leads) {
    Set<Id> importedUnmatchedMCC = new Set<Id>();
    Id merchantRecordTypeId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT');
    for (Lead l : leads) {
      /* if (
        !l.ER_SmartER_Context__c &&
        l.RecordTypeId == merchantRecordTypeId &&
        l.ER_Lead_Channel__c.equals(Label.LAB_SF_Lead_Channel_Auto) &&
        l.ER_BUPicklist__c.equals(Label.LAB_SF_Lead_BU_ES)
      ) {
        importedUnmatchedMCC.add(l.Id);
      } */
    }

    if (!importedUnmatchedMCC.isEmpty())
      futureLeadAssignRule(importedUnmatchedMCC);
  }

  /*
   *
   * Dragos Avram
   * OCT 2020
   * checkMIDClearingOnAcceptors: Check the MID clearing checkbox based on Unmatch Transaction conditions.
   *
   */
  /*
    public static void checkMIDClearingOnAcceptors(Map<String,Lead> midClearing, Map<String,Lead> subMidClearing){
        Map<Id,Lead>updateLeads = new Map<Id,Lead>();
        System.debug('** DA midClearing ' +midClearing);
        System.debug('** DA subMidClearing ' +subMidClearing);
        List<ER_Acceptor__c> matchedAcceptors =[Select id,ER_MID_Clearing__c,ER_Sub_MID_Clearing__c
                                                from ER_Acceptor__c where ER_MID_Clearing__c in: midClearing.keyset() OR ER_Sub_MID_Clearing__c in: subMidClearing.keyset()];
        System.debug('** DA matchedAcceptors ' +matchedAcceptors);
        List<ER_Acceptor__c> matchedAcceptors2 =[Select id,ER_MID_Clearing__c,ER_Sub_MID_Clearing__c
                                                from ER_Acceptor__c];
        System.debug('** DA matchedAcceptors2 ' +matchedAcceptors2);
        if(!matchedAcceptors.isEmpty()){
            for(ER_Acceptor__c acc :  matchedAcceptors){
                if(midClearing.containsKey(acc.ER_MID_Clearing__c)){
                   Lead l = midClearing.get(acc.ER_MID_Clearing__c).clone(true,true,false,false);
                 l.ER_MID_Clearing_on_Acceptors__c = true;
                    if(!updateLeads.containsKey(l.Id)){
                        updateLeads.put(l.Id,l);
                      }
              }
                    if(subMidClearing.containsKey(acc.ER_Sub_MID_Clearing__c)){
                      Lead l = subMidClearing.get(acc.ER_Sub_MID_Clearing__c).clone(true,true,false,false);
                      l.ER_MID_Clearing_on_Acceptors__c = true;
                      if(!updateLeads.containsKey(l.Id)){
                        updateLeads.put(l.Id,l);
                      }
                }
            }
        }
        if(!updateLeads.isEmpty()){
            update updateLeads.values();
        }
    }
  */
  /*
   *
   * Dragos Avram
   * OCT 2020
   * getGroupID: get the id of the group that you want to assign.
   *
   */
  public static ID getGroupID(String type, String name) {
    ID groupId = [SELECT Id FROM Group WHERE Type = :type AND Name = :name LIMIT 1].Id;
    return groupId != null ? groupId : '';
  }

  /*
    * COMMENTED AS THIS METHOD IS NOT USED
    * Daniel Sandu
    * OCT 2020
    * manageTaskCreationAfterLeadInsert: create task after merchant lead created from a case
    *
    public static void manageTaskCreationAfterLeadInsert(Map<Id,Id> mapLeadsCases){

        List<Task> taskList = new List<Task>();
        List<Case> caseList = [select id, ER_Lead__c, ER_Lead__r.CreatedById, OwnerId, ER_Resolution__c from Case where id IN : mapLeadsCases.keySet()];

        if(!caseList.isEmpty()) {
                for(Case c : caseList) {
                    c.ER_Resolution__c = Label.LAB_SF_Case_Resolution;
                    c.ER_Lead__c = mapLeadsCases.get(c.id);

                    String taskOwner = '';

                    if(String.valueOf(c.OwnerId).startsWith('00G'))
                        taskOwner = c.ER_Lead__r.CreatedById;
                    else if(String.valueOf(c.OwnerId).startsWith('005'))
                        taskOwner = c.OwnerId;

                    Task newTask = APER09_Task_Management.CreateTaskForLeadCreation(Label.LAB_SF_Lead_Subject_UpdateAffiliationRequest, taskOwner, date.today(), c.id);

                    taskList.add(newTask);
                }
                update caseList;
            }
            System.debug('List of Tasks to insert' + taskList);

            if(!taskList.isEmpty())
                insert taskList;
    }
    */
  /*
   *
   * Dragos Avram
   * FEB 2021
   * updateCompetitors: update competitors after lead conversion
   */
  public static void updateCompetitors(List<Lead> convertedLeads) {
    List<ER_Competitor__c> competitorsToUpdate = new List<ER_Competitor__c>();
    Set<Id> setIdLeadsConverted = new Set<Id>();
    for (Lead ld : convertedLeads) {
      if (ld.IsConverted && ld.ConvertedAccountId != null && ld.ConvertedOpportunityId != null) {
        setIdLeadsConverted.add(ld.Id);
      }
    }

    if (!setIdLeadsConverted.isEmpty()) {
      for (ER_Competitor__c comp : [
        SELECT id, ER_Lead__c, ER_Lead__r.ConvertedOpportunityId, ER_Lead__r.ConvertedAccountId
        FROM ER_Competitor__c
        WHERE ER_Lead__c IN :setIdLeadsConverted
      ]) {
        comp.ER_Company__c = comp.ER_Lead__r.ConvertedAccountId;
        comp.ER_Opportunity__c = comp.ER_Lead__r.ConvertedOpportunityId;
        competitorsToUpdate.add(comp);
      }
      if (!competitorsToUpdate.isEmpty()) {
        update competitorsToUpdate;
      }
    }
  }

  /**
   * @author VJOY
   * @date 28/02/2022
   * @description Map the lead Promo Code to the linked Opportunity
   * @param leads
   */
  public static void assignPromoCodeToOpp(List<Lead> leads) {
    List<Opportunity> opportunitiesToBeUpdated = new List<Opportunity>();
    Set<String> promoCodes = new Set<String>();
    Map<String, ER_Promo_Code__c> promoCodeMap = new Map<String, ER_Promo_Code__c>();

    for (Lead l : leads) {
      if (!l.ER_SmartER_Context__c && l.IsConverted && l.ConvertedOpportunityId != null && l.ER_Promo_Code__c != null) {
        promoCodes.add(l.ER_Promo_Code__c);
      }
    }

    if (!promoCodes.isEmpty()) {
      for (ER_Promo_Code__c pc : [
        SELECT Id, ER_Promo_Code__c
        FROM ER_Promo_Code__c
        WHERE ER_Promo_Code__c IN :promoCodes
      ]) {
        promoCodeMap.put(pc.ER_Promo_Code__c, pc);
      }

      for (Lead l : leads) {
        if (
          l.IsConverted &&
          l.ConvertedOpportunityId != null &&
          l.ER_Promo_Code__c != null &&
          promoCodeMap.containsKey(l.ER_Promo_Code__c)
        ) {
          opportunitiesToBeUpdated.add(
            new Opportunity(Id = l.ConvertedOpportunityId, ER_Promo_Code2__c = promoCodeMap.get(l.ER_Promo_Code__c).Id)
          );
        }
      }

      if (!opportunitiesToBeUpdated.isEmpty())
        update opportunitiesToBeUpdated;
    }
  }

  /**
   * @Author ELAK
   * @param leads
   */
  public static void createUnmatchedTrTasks(List<Lead> leads, Map<Id, SObject> oldItems) {
    List<Task> unmatchedTransactionTasks = new List<Task>();
    Map<Id, Lead> oldLeadMap = (Map<Id, Lead>) oldItems;
    for (Lead ld : leads) {
      Lead oldLead = oldLeadMap.get(ld.Id);
      if (
        !ld.ER_SmartER_Context__c &&
        ld.Status != oldLead.Status &&
        ld.Status.equals(Label.LABS_SF_Status_Lead_Excluded) &&
        ld.ER_BUPicklist__c.equals(Label.LAB_SF_Lead_BU_ES) &&
        (ld.ER_Rejected_Reason__c.equals(Label.LAB_SF_Lead_Rejected_Interest) ||
        ld.ER_Rejected_Reason__c.equals(Label.LAB_SF_Lead_Rejected_Budget))
      ) {
        Id queueID = getGroupID(Label.LAB_SF_Group_Type_Queue, 'Default Task Assignment Queue'/*Label.LAB_SF_Queue_Name_ES_Afiliados*/);
        Task task = APER09_Task_Management.CreateTaskForLeadUpdate(
          Label.LAB_SF_Task_Subject_MID,
          queueID,
          System.today().addDays(5),
          ld.Id
        );
        unmatchedTransactionTasks.add(task);
      }
    }
    if (!unmatchedTransactionTasks.isEmpty())
      insert unmatchedTransactionTasks;
  }

  /**
   * @author ALK
   * @date 14/03/2022
   * @description Convert the lead once the ER_Convert_Lead__c is flagged true (This function is used by Smarter APIs)
   * @param leads
   */
  public static void convertLeads(List<Lead> leads) {
    Map<Id, Lead> leadsToBeConverted = new Map<Id, Lead>();
    List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
    List<Account> accountsToBeUpdated = new List<Account>();
    List<Contact> contactsToBeUpdated = new List<Contact>();
    Map<Id, Account> mapAccountsToBeUpdated = new Map<Id, Account>();
    Map<Id, Contact> mapContactsToBeUpdated = new Map<Id, Contact>();

    for (Lead l : leads) {
      if (
        l.ER_To_Be_Converted__c &&
        !l.IsConverted &&
        String.isNotBlank(l.ER_Registration_Number__c) &&
        String.isNotBlank(l.Email)
      )
        leadsToBeConverted.put(l.Id, l);
    }

    if (!leadsToBeConverted.isEmpty()) {
      String defaultConvertedStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1]
      .MasterLabel;
      Map<String, Map<String, SObject>> mapObjects = checkExistingSmartERStructure(leadsToBeConverted.values());

      for (Lead l : leadsToBeConverted.values()) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setConvertedStatus(defaultConvertedStatus);
        lc.leadId = l.Id;

        if (!mapObjects.isEmpty()) {
          if (
            mapObjects.containsKey(Constants.ACCOUNT) &&
            mapObjects.get(Constants.ACCOUNT).containsKey(l.ER_Registration_Number__c)
          ) {
            Account a = (Account) mapObjects.get(Constants.ACCOUNT).get(l.ER_Registration_Number__c);
            if (!a.ER_SmartER_Context__c) {
              a.ER_SmartER_Context__c = false;
              mapAccountsToBeUpdated.put(l.Id, a);
            }
            lc.setAccountId(a.Id);
          }
          System.debug('>>>>> ALK - mapObjects Account' + mapObjects);

          if (
            mapObjects.containsKey(Constants.CONTACT) &&
            mapObjects.get(Constants.CONTACT).containsKey(l.ER_Registration_Number__c)
          ) {
            Contact c = (Contact) mapObjects.get(Constants.CONTACT).get(l.ER_Registration_Number__c);
            if (!c.ER_SmartER_Context__c) {
              c.ER_SmartER_Context__c = false;
              mapContactsToBeUpdated.put(l.Id, c);
            }
            lc.setContactId(c.Id);
          }
          System.debug('>>>>> ALK - mapObjects Contact' + mapObjects);
        }
        leadConverts.add(lc);
      }

      if (!leadConverts.isEmpty()) {
        Database.LeadConvertResult[] results = Database.convertLead(leadConverts, false);

        for (Database.LeadConvertResult lcr : results) {
          if (!lcr.isSuccess()) {
            String errorMessage = '';
            for (Database.Error err : lcr.getErrors()) {
              errorMessage += err.getMessage() + ' - ';
            }
            leadsToBeConverted.get(lcr.getLeadId()).addError(Label.LAB_SF_Smarter_Lead_Conversion_Error + errorMessage);
          } else {
            if (mapAccountsToBeUpdated.containsKey(lcr.getLeadId()))
              accountsToBeUpdated.add(mapAccountsToBeUpdated.get(lcr.getLeadId()));
            if (mapContactsToBeUpdated.containsKey(lcr.getLeadId()))
              contactsToBeUpdated.add(mapContactsToBeUpdated.get(lcr.getLeadId()));
          }
        }

        System.debug('>>>>> ALK - accountsToBeUpdated : ' + accountsToBeUpdated);
        System.debug('>>>>> ALK - contactsToBeUpdated : ' + contactsToBeUpdated);
        if (!accountsToBeUpdated.isEmpty())
          Database.update(accountsToBeUpdated, false);
        if (!contactsToBeUpdated.isEmpty())
          Database.update(contactsToBeUpdated, false);
      }
    }
  }

  /**
   * @author AAZ
   * @date 27/07/2022
   * @param leads
   * @return
   */
  public static Map<String, Map<String, SObject>> checkExistingSmartERStructure(List<Lead> leads) {
    Map<String, Lead> mapCRNLeads = new Map<String, Lead>();
    Map<String, Account> mapCRNAccounts = new Map<String, Account>();
    Map<String, Contact> mapCRNContacts = new Map<String, Contact>();
    Map<String, Map<String, SObject>> mapObjects = new Map<String, Map<String, SObject>>();
    Id businessContactRTId = Utils.getRecordTypeIdByDeveloperName(Contact.SObjectType, Constants.CONTACT_BUSINESS_RT);
    Id companyRTId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);

    for (Lead l : leads) {
      if (String.isNotBlank(l.ER_Registration_Number__c) && String.isNotBlank(l.Email))
        mapCRNLeads.put(l.ER_Registration_Number__c, l);
    }

    System.debug('>>>>> ALK - mapCRNLeads : ' + mapCRNLeads);
    if (!mapCRNLeads.isEmpty()) {
      List<Account> accounts = [
        SELECT Id, ER_SmartER_Context__c, ER_Registration_Number__c
        FROM Account
        WHERE RecordTypeId = :companyRTId AND ER_Registration_Number__c IN :mapCRNLeads.keySet()
        ORDER BY LastModifiedDate DESC
      ];

      if (!accounts.isEmpty()) {
        for (Account a : accounts) {
          //Link the account based on its CRN
          if (!mapCRNAccounts.containsKey(a.ER_Registration_Number__c))
            mapCRNAccounts.put(a.ER_Registration_Number__c, a);
        }
        System.debug('>>>>> ALK - mapCRNAccounts : ' + mapCRNAccounts);

        for (Contact c : [
          SELECT Id, Email, ER_SmartER_Context__c, Account.ER_Registration_Number__c
          FROM Contact
          WHERE AccountId IN :accounts AND RecordTypeId = :businessContactRTId
        ]) {
          if (
            c.Email == mapCRNLeads.get(c.Account.ER_Registration_Number__c).Email &&
            !mapCRNContacts.containsKey(c.Account.ER_Registration_Number__c)
          ) {
            mapCRNContacts.put(c.Account.ER_Registration_Number__c, c);
          }
        }
        System.debug('>>>>> ALK - mapCRNContacts : ' + mapCRNContacts);
      }
    }

    if (!mapCRNAccounts.isEmpty())
      mapObjects.put(Constants.ACCOUNT, mapCRNAccounts);
    if (!mapCRNContacts.isEmpty())
      mapObjects.put(Constants.CONTACT, mapCRNContacts);

    return mapObjects;
  }

  /**
   * @author AAZ
   * @date 27/06/2022
   * @description SMARTER - Check if is there an existing lead having the same email address and same CRN
   * @param newItems
   */
  public static void checkExistingLeads(List<Lead> newItems) {
    Map<String, Lead> mapNewLeadsByEmails = new Map<String, Lead>();
    Map<Id, Lead> mapLeadsToBeRejected = new Map<Id, Lead>();
    Set<String> existingLeadsIds = new Set<String>();

    for (Lead l : newItems) {
      if (l.ER_SmartER_Context__c && String.isNotBlank(l.Email) && !mapNewLeadsByEmails.containsKey(l.Email)) {
        mapNewLeadsByEmails.put(l.Email, l);
      } else if (mapNewLeadsByEmails.containsKey(l.Email)) {
        //l.addError('This lead is a duplicate of an existing lead in the same data bulk');
        l.Status = Constants.REJECTED;
        l.ER_Rejected_Reason__c = Constants.DUPLICATE_LEAD;
      }
    }

    if (!mapNewLeadsByEmails.isEmpty()) {
      for (Lead l : [
        SELECT
          Id,
          ER_Registration_Number__c,
          Email,
          ER_Product_Family_Interest__c,
          ERBE_Initial_Product_Of_Interest__c,
          ER_UTM_tag__c,
          RecordTypeId,
          ER_Promo_Code__c,
          ER_Language__c,
          ER_Role__c,
          Description,
          ER_Credit_Scoring__c,
          ER_Credit_Limit__c,
          ER_Business_Risk__c,
          ER_Last_Credit_Scoring_Update__c
        FROM Lead
        WHERE
          Email IN :mapNewLeadsByEmails.keySet()
          AND ER_SmartER_Context__c = FALSE
          AND Status NOT IN (:Constants.REJECTED, :Constants.QUALIFIED)
        ORDER BY LastModifiedDate DESC
      ]) {
        if (!existingLeadsIds.contains(l.Email)) {
          existingLeadsIds.add(l.Email);
          if (
            mapNewLeadsByEmails.containsKey(l.Email) &&
            mapNewLeadsByEmails.get(l.Email).ER_Registration_Number__c == l.ER_Registration_Number__c &&
            mapNewLeadsByEmails.get(l.Email).RecordTypeId == l.RecordTypeId
          ) {
            Lead newLead = mapNewLeadsByEmails.get(l.Email);
            newLead.ER_Product_Family_Interest__c = (String.isNotBlank(newLead.ER_Product_Family_Interest__c)
              ? newLead.ER_Product_Family_Interest__c
              : l.ER_Product_Family_Interest__c);
            newLead.ERBE_Initial_Product_Of_Interest__c = (newLead.ERBE_Initial_Product_Of_Interest__c != null
              ? newLead.ERBE_Initial_Product_Of_Interest__c
              : l.ERBE_Initial_Product_Of_Interest__c);
            newLead.ER_UTM_tag__c = (String.isNotBlank(newLead.ER_UTM_tag__c)
              ? newLead.ER_UTM_tag__c
              : l.ER_UTM_tag__c);
            newLead.ER_Promo_Code__c = (String.isNotBlank(newLead.ER_Promo_Code__c)
              ? newLead.ER_Promo_Code__c
              : l.ER_Promo_Code__c);
            newLead.ER_Language__c = (String.isNotBlank(newLead.ER_Language__c)
              ? newLead.ER_Language__c
              : l.ER_Language__c);
            newLead.ER_Role__c = (String.isNotBlank(newLead.ER_Role__c) ? newLead.ER_Role__c : l.ER_Role__c);
            newLead.Description = (String.isNotBlank(newLead.Description) ? newLead.Description : l.Description);
            newLead.ER_Credit_Scoring__c = (newLead.ER_Credit_Scoring__c != null
              ? newLead.ER_Credit_Scoring__c
              : l.ER_Credit_Scoring__c);
            newLead.ER_Credit_Limit__c = (newLead.ER_Credit_Limit__c != null
              ? newLead.ER_Credit_Limit__c
              : l.ER_Credit_Limit__c);
            newLead.ER_Last_Credit_Scoring_Update__c = (newLead.ER_Last_Credit_Scoring_Update__c != null
              ? newLead.ER_Last_Credit_Scoring_Update__c
              : l.ER_Last_Credit_Scoring_Update__c);

            //Reject existing duplicate leads
            mapLeadsToBeRejected.put(
              l.Id,
              new Lead(Id = l.Id, Status = Constants.REJECTED, ER_Rejected_Reason__c = Constants.DUPLICATE_LEAD)
            );
          }
        } else if (
          existingLeadsIds.contains(l.Email) &&
          mapNewLeadsByEmails.get(l.Email).ER_Registration_Number__c == l.ER_Registration_Number__c
        ) {
          //Reject existing duplicate leads
          mapLeadsToBeRejected.put(
            l.Id,
            new Lead(Id = l.Id, Status = Constants.REJECTED, ER_Rejected_Reason__c = Constants.DUPLICATE_LEAD)
          );
        }
      }
    }

    if (!mapLeadsToBeRejected.isEmpty())
      update mapLeadsToBeRejected.values();
  }

  /**
   * @author AAZ
   * @date 27/06/2022
   * @description - SmartER - Link a lead to an existing contact
   * @param newItems
   *
   */
  public static void linkLeadToExistingContact(List<Lead> newItems) {
    Map<String, Lead> mapNewLeadsByEmails = new Map<String, Lead>();
    Set<String> existingContactsIds = new Set<String>();
    Map<Id, Contact> mapContactsTobeUpdated = new Map<Id, Contact>();

    for (Lead l : newItems) {
      if (
        l.ER_SmartER_Context__c &&
        l.IsConverted &&
        String.isNotBlank(l.Email) &&
        !mapNewLeadsByEmails.containsKey(l.Email)
      ) {
        mapNewLeadsByEmails.put(l.Email, l);
      }
    }

    if (!mapNewLeadsByEmails.isEmpty()) {
      for (Contact c : [
        SELECT
          Id,
          Email,
          ER_Language__c,
          ER_Role__c,
          Description,
          Account.ER_Credit_Scoring__c,
          Account.ER_Last_Credit_Scoring_Update__c,
          ER_SmartER_Context__c,
          Account.ER_Credit_Limit__c,
          Account.ER_Business_Risk__c,
          Account.ER_Registration_Number__c,
          ER_SmartER_Original_Lead_Id__c
        FROM Contact
        WHERE Email IN :mapNewLeadsByEmails.keySet()
        ORDER BY LastModifiedDate
      ]) {
        if (!existingContactsIds.contains(c.Email)) {
          existingContactsIds.add(c.Email);

          if (
            mapNewLeadsByEmails.containsKey(c.Email) &&
            mapNewLeadsByEmails.get(c.Email).ER_Registration_Number__c == c.Account.ER_Registration_Number__c
          ) {
            Lead newLead = mapNewLeadsByEmails.get(c.Email);
            newLead.ER_Language__c = (String.isNotBlank(newLead.ER_Language__c)
              ? newLead.ER_Language__c
              : c.ER_Language__c);
            newLead.ER_Role__c = (String.isNotBlank(newLead.ER_Role__c) ? newLead.ER_Role__c : c.ER_Role__c);
            newLead.Description = (String.isNotBlank(newLead.Description) ? newLead.Description : c.Description);
            newLead.ER_Credit_Scoring__c = (newLead.ER_Credit_Scoring__c != null
              ? newLead.ER_Credit_Scoring__c
              : c.Account.ER_Credit_Scoring__c);
            newLead.ER_Last_Credit_Scoring_Update__c = (newLead.ER_Last_Credit_Scoring_Update__c != null
              ? newLead.ER_Last_Credit_Scoring_Update__c
              : c.Account.ER_Last_Credit_Scoring_Update__c);

            if (!c.ER_SmartER_Context__c && String.isBlank(c.ER_SmartER_Original_Lead_Id__c)) {
              mapContactsTobeUpdated.put(
                c.Id,
                new Contact(Id = c.Id, ER_SmartER_Context__c = true, ER_SmartER_Original_Lead_Id__c = newLead.Id)
              );
            }
          }
        }
      }

      if (!mapContactsTobeUpdated.isEmpty())
        update mapContactsTobeUpdated.values();
    }
  }

  /**
   * @author AAZ
   * @date 19/12/2022
   * @description Tick Contacts to be synced with Smarter
   * @param newItems
   */
  public static void markContactToBeSyncedWithSmarter(List<Lead> newItems) {
    List<Contact> contactsToUpdate = new List<Contact>();

    for (Lead l : [
      SELECT Id, ConvertedContactId
      FROM Lead
      WHERE
        Id IN :newItems
        AND IsConverted = TRUE
        AND ER_SmartER_Context__c = TRUE
        AND CreatedBy.Profile.Name = :Constants.PROFILE_ER_INTEGRATION
    ]) {
      if (l.ConvertedContactId != null)
        contactsToUpdate.add(new Contact(Id = l.ConvertedContactId, ER_To_sync_with_smarter__c = true));
    }

    if (!contactsToUpdate.isEmpty())
      Database.update(contactsToUpdate, false);
  }
  /**
   * @author CWA
   * @date 03/03/2023
   * @description - Update the field Initial Product Interest for BUs configured in global settings - LEAD_UPDATE_PRODUCT_INTEREST_BU
   * @param leadList new created Leads
   *
   */
  public static void UpdateProductOfInterest(List<Lead> leadList) {
    List<String> allowedBUs = Utils.getGlobalSettingsValueFromKey(Constants.LEAD_UPDATE_PRODUCT_INTEREST_BU)
      ?.split(Constants.SEMICOLON);
    Set<String> productExternalRefs = new Set<String>();
    Map<String, Id> mapProductExternalRefs = new Map<String, Id>();

    for (Lead l : leadList)
      if (l.ER_Initial_Product_Interest_External_ID__c != null && allowedBus.contains(l.ER_BUPicklist__c))
        productExternalRefs.add(l.ER_Initial_Product_Interest_External_ID__c);

    if (!productExternalRefs.isEmpty()) {
      for (Product2 p : [
        SELECT Id, BU_External_Reference__c
        FROM Product2
        WHERE BU_External_Reference__c IN :productExternalRefs AND IsActive = TRUE AND ER_Type__c = 'Solution'
      ])
        mapProductExternalRefs.put(p.BU_External_Reference__c, p.Id);

      for (Lead l : leadList)
        if (mapProductExternalRefs.containsKey(l.ER_Initial_Product_Interest_External_ID__c))
          l.ERBE_Initial_Product_Of_Interest__c = mapProductExternalRefs.get(
            l.ER_Initial_Product_Interest_External_ID__c
          );
    }
  }

  /**
   * @author ALK
   * @date 30/03/2023
   * @description SmartER Set SmartER context on the Lead
   * @param newItems
   */
  public static void setLeadAsSmartERContext(List<Lead> newItems) {
    List<String> smartERDeployedBUs = Utils.getGlobalSettingsValueFromKey(Constants.SMARTER_DEPLOYED_BUS)
      ?.split(Constants.SEMICOLON);

    for (Lead l : newItems) {
      if (
        smartERDeployedBUs != null &&
        (smartERDeployedBUs.contains(l.ER_BUPicklist__c) || smartERDeployedBUs.contains(Constants.ALL)) &&
        !l.ER_SmartER_Context__c
      ) {
        l.ER_SmartER_Context__c = false;
      }
    }
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description Send Lead to Genesys and Create a task on Salesforce

   * @param newItems
   * @param oldItems
   */
  public static void routeLeadToGenesys(Map<Id, Lead> newItems, Map<Id, Lead> oldItems) {
    List<GenesysRoutingRequest> genesysRoutingRequests = new List<GenesysRoutingRequest>();
    Map<String, String> mapIdRecordType = Utils.getRecordTypeMapIdByDeveloperName(Lead.SObjectType);

    for (Lead l : newItems.values()) {
      Boolean isEFG = l.LeadSource == 'EFG';
      String keyFlow =
        Constants.GENESYS_LEAD_FLOW_ID_CONFIG +
        l.ER_BUPicklist__c +
        Constants.UNDERSCORE +
        mapRecordTypeCode(mapIdRecordType, l.RecordTypeId);
      String keyQueue =
        Constants.GENESYS_LEAD_QUEUE_ID_CONFIG +
        l.ER_BUPicklist__c +
        Constants.UNDERSCORE +
        mapRecordTypeCode(mapIdRecordType, l.RecordTypeId) +
        Constants.UNDERSCORE +
        getQueueAssignment(l, isEFG);

      String flowName = Utils.getGlobalSettingsValueFromKey(keyFlow.toUpperCase());
      String queueId = Utils.getGlobalSettingsValueFromKey(keyQueue.toUpperCase());
      System.debug('//NGO routeCaseToGenesys key Flow : ' + keyFlow + ' value : ' + flowName);

      if (
        (l.LeadSource == 'EFG' ||
        ((Constants.GENESYS_DROP_CASE_VALUES.contains(l.ER_SmartER_Drop_Case_Step__c) ||
        (l.ER_SmartER_Drop_Case_Step__c == Constants.ACCOUNT && !l.ER_To_Be_Converted__c)) &&
        l.ER_SmartER_Context__c)) &&
        flowName != null &&
        queueId != null &&
        isValidCRN(l) &&
        isValidPostalCode(l)
      ) {
        genesysRoutingRequests.add(createLeadGenesysRoutingRequest(flowName, queueId, l));
      }
    }

    if (!genesysRoutingRequests.isEmpty())
      GenesysCloud_API.createConversation(JSON.serializePretty(genesysRoutingRequests));
  }

  /**
     * @author Noor
     * @date 02/06/2023
     * @description create Genesys Routing Request

     * @param flowName
     * @param queueId
     * @param c case
     * @return GenesysRoutingRequest
     */
  public static GenesysRoutingRequest createLeadGenesysRoutingRequest(String flowName, String queueId, Lead l) {
    GenesysRoutingRequest req = new GenesysRoutingRequest();
    req.flowId = flowName;
    req.fromName = 'Lead_Inbound';
    req.attributes.fa_sf = queueId;
    req.attributes.sf_urlpop = l.Id;
    req.attributes.type_activite = 'Lead';
    req.attributes.owner_id = l.OwnerId;
    req.attributes.priorite = Constants.GENESYS_PRIORITY_HIGH;
    System.debug('//NGO createGenesysRoutingRequest: ' + req);
    return req;
  }

  /**
     * @author Noor
     * @date 02/06/2023
     * @description isValidCRN

     * @param l lead
     * @return true if registration number does not start with 1 or 2
     */
  public static boolean isValidCRN(Lead l) {
    return String.isBlank(l.ER_Registration_Number__c) ||
      (l.ER_Registration_Number__c != null &&
      !(l.ER_Registration_Number__c.startsWith('1') || l.ER_Registration_Number__c.startsWith('2')));
  }

  /**
     * @author Noor
     * @date 02/06/2023
     * @description is Valid Postal Code

     * @param l lead
     * @return true if postal code does not start with 96 or 97 or 98
     */
  public static boolean isValidPostalCode(Lead l) {
    return String.isBlank(l.PostalCode) ||
      (l.PostalCode != null &&
      !(l.PostalCode.startsWith('96') ||
      l.PostalCode.startsWith('97') ||
      l.PostalCode.startsWith('98')));
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description map RecordType with code used for Custom metadata
   *              ER_Client_Case_RT -> CL
   *              ER_User_Case_RT -> UR
   * @param mapIdRecordType
   * @param recordTypeId
   * @return code
   */
  public static String mapRecordTypeCode(Map<String, String> mapIdRecordType, String recordTypeId) {
    String recordType = mapIdRecordType.get(recordTypeId);
    if (recordType == Constants.LEAD_CLIENT_RT)
      return 'CL';
    if (recordType == Constants.LEAD_MERCHANT_RT)
      return 'MR';
    return '';
  }

  /**
   * @author Noor
   * @date 02/06/2023
   * @description disconnect Related Task On Closed lead
   * @param newItems
   * @param oldItems
   */
  public static void disconnectRelatedTaskOnClosedLead(Map<Id, Lead> newItems, Map<Id, Lead> oldItems) {
    Set<Id> closedLead = new Set<Id>();
    List<String> rejectedLeadStatuses = new List<String>{ 'Qualified', 'Rejected' };
    Map<String, String> conversationIds = new Map<String, String>();
    for (Lead l : newItems.values())
      if (l.Status != oldItems.get(l.Id).Status && rejectedLeadStatuses.contains(l.Status))
        closedLead.add(l.Id);

    if (!closedLead.isEmpty()) {
      for (Task t : [
        SELECT Id, Gsys_Call_ConversationId__c
        FROM Task
        WHERE WhoId IN :closedLead AND Gsys_Call_ConversationId__c != ''
      ])
        conversationIds.put(t.Gsys_Call_ConversationId__c, t.Id);

      if (!conversationIds.isEmpty())
        GenesysCloud_API.disconnectConversation(conversationIds);
    }
  }

  /*
  public static void routeConvertedOpportunityToGenesys(Map<Id, Lead> newItems, Map<Id, Lead> oldItems) {
    List<GenesysRoutingRequest> genesysRoutingRequests = new List<GenesysRoutingRequest>();

    System.debug('//NGO routeConvertedOpportunityToGenesys');

    Map<Id, Lead> opportunityIdsMapLead = new Map<Id, Lead>();
    Map<Id, Opportunity> opportunityMapWithoutContract = new Map<Id, Opportunity>();

    for (Lead l : newItems.values()) {
      System.debug('//NGO routeConvertedOpportunityToGenesys ER_SmartER_Context__c :' + l.ER_SmartER_Context__c);
      System.debug('//NGO routeConvertedOpportunityToGenesys l.IsConverted : ' + l.IsConverted);
      System.debug('//NGO routeConvertedOpportunityToGenesys old .IsConverted : ' + oldItems.get(l.Id).IsConverted);
      System.debug(
        '//NGO routeConvertedOpportunityToGenesys ER_SmartER_Drop_Case_Step__c : ' + l.ER_SmartER_Drop_Case_Step__c
      );
      if (
        l.ER_SmartER_Context__c &&
        l.IsConverted &&
        !oldItems.get(l.Id).IsConverted &&
        l.ConvertedOpportunityId != null &&
        l.ER_SmartER_Drop_Case_Step__c == 'Account' &&
        isValidCRN(l) &&
        isValidPostalCode(l)
      )
        opportunityIdsMapLead.put(l.ConvertedOpportunityId, l);
    }

    if (!opportunityIdsMapLead.isEmpty()) {
      //Get relatedContract
      opportunityMapWithoutContract = new Map<Id, Opportunity>(
        [
          SELECT Id, OwnerId, Owner.Email
          FROM Opportunity
          WHERE Id IN :opportunityIdsMapLead.keySet() AND ContractId = ''
        ]
      );
      System.debug(
        '//NGO routeConvertedOpportunityToGenesys opportunityMapWithoutContract : ' + opportunityMapWithoutContract
      );
    }

    if (!opportunityMapWithoutContract.isEmpty()) {
      //Map<Id, Group> queueMap = Utils.getQueueMap();
      for (Id oId : opportunityMapWithoutContract.keySet()) {
        Lead l = opportunityIdsMapLead.get(oId);
        String keyFlow = Constants.GENESYS_OPPORTUNITY_FLOW_ID_CONFIG + l.ER_BUPicklist__c;
        String keyQueue =
          Constants.GENESYS_OPPORTUNITY_QUEUE_ID_CONFIG +
          l.ER_BUPicklist__c +
          Constants.UNDERSCORE +
          getQueueAssignment(l);

        String flowName = Utils.getGlobalSettingsValueFromKey(keyFlow.toUpperCase());
        String queueId = Utils.getGlobalSettingsValueFromKey(keyQueue.toUpperCase());
        System.debug('//NGO routeConvertedOpportunityToGenesys key Flow : ' + keyFlow + ' value : ' + flowName);
        System.debug('//NGO routeConvertedOpportunityToGenesys key Queue : ' + keyQueue + ' value : ' + queueId);
        if (flowName != null && queueId != null)
          genesysRoutingRequests.add(
            createOpportunityGenesysRoutingRequest(flowName, queueId, l, opportunityMapWithoutContract.get(oId))
          );
      }
    }
    if (!genesysRoutingRequests.isEmpty())
      GenesysCloud_API.createConversation(JSON.serializePretty(genesysRoutingRequests));
  }*/

  /**
   * @author Noor
   * @date 02/06/2023
   * @description get the assignment queue based on the number of employees
   * @param l lead
   *
   * @return the queue name
   */
  public static String getQueueAssignment(Lead l, Boolean isEFG) {
    if (!isEFG)
      return Constants.GENESYS_LEAD_DROP_CASE_QUEUE;
    if (l.NumberOfEmployees >= 0 && l.NumberOfEmployees < 10)
      return Constants.GENESYS_LEAD_ERFR_EP_NS_0_9;
    else if (l.NumberOfEmployees > 9 && l.NumberOfEmployees < 30)
      return Constants.GENESYS_LEAD_ERFR_EP_NS_10_29;
    else
      return '';
  }
  /**
   * @author Noor
   * @date 02/06/2023
   * @description Update field employees with the min Range of Employee Range field
   *
   * @param leads
   */
  public static void manageNumberOfEmployees(List<Lead> leads) {
    for (Lead l : leads) {
      if (
        l.NumberOfEmployees == null &&
        l.ER_Employee_Size_Range__c != null &&
        l.ER_Employee_Size_Range__c.indexOf('-') > 0
      ) {
        if (l.ER_Employee_Size_Range__c.split('-')[0].trim().isNumeric())
          l.NumberOfEmployees = Integer.valueOf(l.ER_Employee_Size_Range__c.split('-')[0].trim());
      }
    }
  }

  /**
     * @author Noor
     * @date 02/06/2023
     * @description create Genesys Routing Request

     * @param flowName
     * @param queueId
     * @param c case
     * @return GenesysRoutingRequest

  private static GenesysRoutingRequest createOpportunityGenesysRoutingRequest(
    String flowName,
    String queueId,
    Lead l,
    Opportunity o
  ) {
    GenesysRoutingRequest req = new GenesysRoutingRequest();
    req.flowId = flowName;
    req.fromName = 'Opportunite';
    req.attributes.fa_sf = queueId;
    req.attributes.sf_urlpop = o.Id;
    req.attributes.type_activite = 'Opportunity';
    req.attributes.owner_id = o.OwnerId;
    req.attributes.pref_Agent = o.Owner.Email;
    req.attributes.priorite = 'Prio_5';
    System.debug('//NGO createOpportunityGenesysRoutingRequest: ' + req);
    return req;
    }*/
  /**
   * @author Dinesh
   * @date 30/06/2023
   * @description Update autoenrollment Ext Ref to avoid having duplicates for incoming ones
   * @param items
   */
  public static void updateAutoenrollmentExtId(List<Lead> leadsFromTrigger) {
    Set<String> autoenrollmentBUs = new Set<String>();

    autoenrollmentBUs.addAll(
      Auto_Enrollment__mdt.getInstance(Constants.AUTO_ENROLLMENT_BU_LIST).value__c.split(Constants.PIPE_SEPARATOR)
    );

    List<Lead> leadsList = new List<Lead>();

    for (Lead eachLead : leadsFromTrigger) {
      if (autoenrollmentBUs.contains(eachLead.ER_BUPicklist__c) && eachLead.IsConverted) {
        leadsList.add(eachLead);
      }
    }
    if (!leadsList.isEmpty()) {
      for (Lead eachLead : leadsList) {
        if (String.isNotBlank(eachLead.ER_External_Reference__c)) {
          eachLead.ER_External_Reference__c = eachLead.ER_External_Reference__c + '_' + Datetime.now().getTime();
        }
      }
    }
  }
}