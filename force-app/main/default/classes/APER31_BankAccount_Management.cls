/**
 * @description       :
 * @author            : AAM
 * @group             :
 * @last modified on  : 17-07-2023
 * @last modified by  : AAM
 **/

/*
----------------------------------------------------------------------
-- - Name          : APER31_BankAccount_Management
-- - Author        : Dragos Avram
-- - Description   : Bank Account Management, This class is used to group all the functionnality linked to the object Bank Account
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- MAR-2021     davram               1.0         Initial version
---------------------------------------------------------------------------------------
*/

public with sharing class APER31_BankAccount_Management {
  /*
    public static void saveFinancialCenterEDGWs(List<ER_Bank_Account__c> bankAccounts) {

        System.Debug('--- APHU07_SynchronizeFinancialWS begin prepare' + bankAccounts );

        Set <Id> financialSetToUpdate = new Set <Id> ();

        if (!WSHU07_SynchronizeFinancialWS.alreadyExecutedFinancialCenter) {
            // Loop through the Financial Center lists and add the necessary invoice center to the set
            for (ER_Bank_Account__c fc : bankAccounts) {
                if (fc.ER_Business_Unit__c == 'HU') {
                    financialSetToUpdate.add(fc.ER_Financial_Center__c);
                }
            }
        }

        System.Debug('--- APHU07_SynchronizeFinancialWS end prepare');

        if (!financialSetToUpdate.isEmpty()) {
            WSHU07_SynchronizeFinancialWS.addupdateFinancialCentersFuture(financialSetToUpdate);
        }
    } */

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Sync Bank Accounts with EDG v3
   * @param bankAccounts
   */
  public static void syncBankAccounts(
    List<ER_Bank_Account__c> bankAccounts,
    Map<Id, ER_Bank_Account__c> oldBankAccount
  ) {
    Set<Id> financialCenters = new Set<Id>();
    Set<Id> accounts = new Set<Id>();
    Set<Id> ModifiedElements = new Set<Id>();

    if (!bankAccounts.isEmpty())
      APER30_AutoEnrollment_Management.syncRecordBU = bankAccounts[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    Boolean isOfflineBU = APER06_WebserviceUtility.Offline_Sales_WS;
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    System.debug(
      '####### BANK_ACCOUNT : ER_SyncStructureWS.alreadyExecutedSync : :' + ER_SyncStructureWS.alreadyExecutedSync
    );
    if (!Test.isRunningTest() && !isOfflineBU && !ER_SyncStructureWS.alreadyExecutedSync) {
      for (ER_Bank_Account__c ba : bankAccounts) {
        if (
          ba.ER_Financial_Center__c != null &&
          ((oldBankAccount == null || oldBankAccount.isEmpty()) ||
          (oldBankAccount != null &&
          ba.ER_Last_date_of_Sync__c == oldBankAccount.get(ba.Id).ER_Last_date_of_Sync__c))
        ) {
          ModifiedElements.add(ba.Id);
          financialCenters.add(ba.ER_Financial_Center__c);
        }
      }

      for (ER_Financial_Center__c fc : [
        SELECT Id, ER_Account_Name__c, ER_Type__c
        FROM ER_Financial_Center__c
        WHERE Id IN :financialCenters AND ER_Creation_date_in_OS__c != NULL
      ]) {
        accounts.add(fc.ER_Account_Name__c);
        accountsInputScope.put(fc.ER_Account_Name__c, fc.ER_Type__c.toLowerCase());
      }

      //if(!accounts.isEmpty()) ER_SyncStructureWithLegacy.syncContract(accounts, null, 'PUT');
      if (!accounts.isEmpty())
        System.enqueueJob(new ER_SyncStructureWS(accounts, null, 'PUT', ModifiedElements, accountsInputScope));
    }
  }

  /**
   * @author KHAD
   * @date 08/06/2021
   * @description Update the creation date in ios field for Bank Account v3
   * @param newItems
   * @param oldItems
   */
  public static void syncBankAccountFlags(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    System.debug('### syncBankAccountFlags Start');

    Map<Id, ER_Bank_Account__c> newBankAccountMap = (Map<Id, ER_Bank_Account__c>) newItems;
    Map<Id, ER_Bank_Account__c> oldBankAccountMap = (Map<Id, ER_Bank_Account__c>) oldItems;

    // Loop through the Acceptor lists and add fill the creation date in OS
    for (ER_Bank_Account__c ba : newBankAccountMap.values()) {
      if (
        ba.ER_Sync_result__c != oldBankAccountMap.get(ba.Id).ER_Sync_result__c &&
        (ba.ER_Sync_result__c == 'synchronized' ||
        ba.ER_Sync_result__c == 'pending_synchronization') &&
        ba.ER_Creation_date_in_OS__c == null
      )
        ba.ER_Creation_date_in_OS__c = Datetime.now();
    }
    System.debug('### syncBankAccountFlags End');
  }

  /**
   * @author Noor
   * @date 16/07/2021
   * @description migrate code from old trigger to synchronize Financials
   * @param bankAccounts on the back account
   */
  /*  
    public static void synchronizeFinancials(List<ER_Bank_Account__c> bankAccounts){

        Set <Id> financialSetToUpdate = new Set <Id> ();
        // Loop through the Financial Center lists and add the necessary invoice center to the set
        for (ER_Bank_Account__c fc: bankAccounts)
            if (fc.ER_Business_Unit__c == 'HU')financialSetToUpdate.add(fc.ER_Financial_Center__c);

        if (!financialSetToUpdate.isEmpty() ) WSHU07_SynchronizeFinancialWS.addupdateFinancialCentersFuture(financialSetToUpdate);
    }
    */
  /**
   * @author AAZ
   * @date 29/11/2021
   * @description Update the ER_Last_Modified_Date_Functional_User__c field to ignore last updates done by technical users
   * @param newItems
   */
  public static void updateLastModifiedDateFunctionalUser(List<ER_Bank_Account__c> newItems) {
    ER_Validation_Rules_Settings__c profileSetting = ER_Validation_Rules_Settings__c.getInstance(
      UserInfo.getProfileId()
    );
    ER_Validation_Rules_Settings__c userSetting = ER_Validation_Rules_Settings__c.getInstance(UserInfo.getUserId());

    for (ER_Bank_Account__c ba : newItems) {
      if (
        !profileSetting.ER_Last_Modified_Date_Functional_User__c &&
        !userSetting.ER_Last_Modified_Date_Functional_User__c
      )
        ba.ER_Last_Modified_Date_Functional_User__c = Datetime.now();
    }
  }

  /**
   * @author AAM
   * @date 07/04/2022
   * @description Set BIC and Bank name when Iban is filled & BIC is empty
   * @param newItems
   */
  public static void setBankAccountInfos(List<ER_Bank_Account__c> newBnkAcc, Map<Id, ER_Bank_Account__c> oldBnkAccMap) {
    System.debug('### setBankAccountInfos Start');
    List<String> deployedBUsList = Utils.getGlobalSettingsValueFromKey('BnkAccountInfos_Deployed_BUs')
      ?.split(Constants.SEMICOLON);
    ID jobID;

    List<ER_Bank_Account__c> bnkAccList = new List<ER_Bank_Account__c>();
    System.debug('### setBankAccountInfos deployedBUsList: ' + deployedBUsList);
    for (ER_Bank_Account__c bnkAcc : newBnkAcc) {
      System.debug('### setBankAccountInfos bnkAcc.ER_IBAN__c: ' + bnkAcc.ER_IBAN__c + ' -- bnkAcc.Id: ' + bnkAcc.Id);
      System.debug(
        '### setBankAccountInfos oldBnkAccMap?.get(bnkAcc.Id).ER_IBAN__c: ' + oldBnkAccMap?.get(bnkAcc.Id).ER_IBAN__c
      );
      if (
        bnkAcc.ER_IBAN__c != oldBnkAccMap?.get(bnkAcc.Id).ER_IBAN__c &&
        deployedBUsList.contains(bnkAcc.ER_BUPicklist__c)
      )
        bnkAccList.add(bnkAcc);
    }
    if (!bnkAccList.isEmpty()) {
      List<ER_Bank_Account__c> newBnkAcc2 = newBnkAcc.deepClone(true, false, false); // In order to get rid of the isReadOnly flag
      jobID = System.enqueueJob(new ER_SetBankAccountInfos(newBnkAcc2));
    }
    System.debug('### setBankAccountInfos End -- newBnkAcc size: ' + newBnkAcc.size() + '. jobID: ' + jobID);
  }

  /**
   * @author AAZ
   * @date 27/06/2022
   * @description Update the related Billing Accounts after an IBAN has changed
   * @param newBnkAcc
   * @param oldBnkAccMap
   */
  public static void updateZuoraBillingAccounts(
    List<ER_Bank_Account__c> newBnkAcc,
    Map<Id, ER_Bank_Account__c> oldBnkAccMap
  ) {
    List<String> deployedZuoraBUs = Utils.getGlobalSettingsValueFromKey(Constants.ZUORA_DEPLOYED_BU)
      ?.split(Constants.SEMICOLON);
    List<ER_Bank_Account__c> bnkAccList = new List<ER_Bank_Account__c>();

    for (ER_Bank_Account__c bnkAcc : newBnkAcc) {
      if (
        bnkAcc.ER_IBAN__c != oldBnkAccMap?.get(bnkAcc.Id).ER_IBAN__c &&
        deployedZuoraBUs.contains(bnkAcc.ER_BUPicklist__c)
      )
        bnkAccList.add(bnkAcc);
    }

    System.debug('>>>>> AAZ - APER31.updateZuoraBillingAccounts bnkAccList: ' + bnkAccList);

    if (!bnkAccList.isEmpty()) {
      List<Zuora__CustomerAccount__c> listBAToSync = [
        SELECT
          Id,
          Name,
          ER_Financial_Center__r.Name,
          ER_Financial_Center__r.ER_Bank_Account__r.Name,
          ER_Financial_Center__r.ER_Bank_Account__r.ER_IBAN__c,
          Zuora__Zuora_Id__c,
          Zuora__Account__r.ER_BUPicklist__c,
          Zuora__Account__r.ER_Business_Unit__c,
          Zuora__Account__r.ER_Legal_Name__c,
          Zuora__Account__r.ER_VAT_Number__c,
          ER_Financial_Center__r.ER_Type__c,
          Zuora__Account__r.BillingStreet,
          Zuora__Account__r.ER_Not_subject_to_VAT__c,
          Zuora__Account__r.BillingCity,
          Zuora__Account__r.BillingPostalCode,
          Zuora__Account__r.BillingState,
          Zuora__Account__r.BillingCountry,
          Zuora__Account__r.ER_Country_Code__c,
          ER_Financial_Center__r.ER_SmartER_Context__c
        FROM Zuora__CustomerAccount__c
        WHERE ER_Financial_Center__r.ER_Bank_Account__c IN :bnkAccList
      ];

      System.debug('>>>>> AAZ - APER31.updateZuoraBillingAccounts listBAToSync size: ' + listBAToSync.size());
      System.debug('>>>>> AAZ - APER31.updateZuoraBillingAccounts listBAToSync: ' + listBAToSync);

      if (!listBAToSync.isEmpty())
        System.enqueueJob(new ER_CreateZuoraBillingAccount(null, listBAToSync));
    }
  }

  /**
   * @author snica
   * @date 15/09/2022
   * @description Rule to have only 1 Active SEPA per Financial center
   * @param newBnkAcc
   */
  public static void allowOnlyOneActiveSepaPerFC(List<ER_Bank_Account__c> newBnkAcc) {
    if (!UtilsBypass.getCurrentUser().ER_BypassVR__c) {
      Map<Id, ER_Bank_Account__c> mapFCBA = new Map<Id, ER_Bank_Account__c>();

      for (ER_Bank_Account__c ba : newBnkAcc) {
        if (
          ba.ER_BUPicklist__c == Constants.BENELUX &&
          ba.ER_SEPA_active__c &&
          ba.ER_Financial_Center__c != null &&
          ba.ER_Bank_Account_Status__c == Constants.OPEN
        ) {
          //In case in the bulk we have more then 1 SEPA BA linked to the same FC
          if (!mapFCBA.containsKey(ba.ER_Financial_Center__c))
            mapFCBA.put(ba.ER_Financial_Center__c, ba);
          else
            ba.addError(Label.LABS_SF_BankAccount_OnlyOneSepaActive);
        }
      }

      if (!mapFCBA.isEmpty()) {
        for (ER_Financial_Center__c fc : [
          SELECT
            Id,
            ER_Bank_Account__c,
            ER_Bank_Account__r.ER_SEPA_active__c,
            ER_Bank_Account__r.ER_Bank_Account_Status__c,
            (
              SELECT Id, ER_SEPA_active__c, ER_Bank_Account_Status__c
              FROM Bank_Accounts__r
              WHERE
                ER_SEPA_active__c = TRUE
                AND ER_BUPicklist__c = :Constants.BENELUX
                AND ER_Bank_Account_Status__c = :Constants.OPEN
            )
          FROM ER_Financial_Center__c
          WHERE Id IN :mapFCBA.keySet()
        ]) {
          ER_Bank_Account__c bAccount = mapFCBA.get(fc.Id);
          if (
            fc.ER_Bank_Account__r.ER_SEPA_active__c == true &&
            fc.ER_Bank_Account__r.ER_Bank_Account_Status__c == Constants.OPEN &&
            fc.ER_Bank_Account__c != bAccount.Id &&
            UserInfo.getUserType() != Constants.AUTOMATED_PROCESS
          )
            bAccount.addError(Label.LABS_SF_BankAccount_OnlyOneSepaActive);
          else {
            for (ER_Bank_Account__c ba : fc.Bank_Accounts__r) {
              if (ba.Id != bAccount.Id) {
                ba.addError(Label.LABS_SF_BankAccount_OnlyOneSepaActive);
                break;
              }
            }
          }
        }
      }
    }
  }
}