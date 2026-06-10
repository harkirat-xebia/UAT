/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 08-17-2023
 * @last modified by  : Malha AMEUR
**/

public with sharing class APHU11_EdgSyncCallout {
  public static Boolean isToUpdate = false;

  /* All Salesforce attributes */
  public static List<Account> merchantList;
  public static List<Contract> ContracttList;
  public static List<ER_Financial_Center__c> financialC;
  public static List<ER_Store__c> storeList;
  public static List<Contact> contactList;
  public static String merchantID;

  // Contructor needed for data initialization for the queuing
  public APHU11_EdgSyncCallout(String myId) {
    merchantID = myId;
  }

  @AuraEnabled
  public static String beforeEdgWS(Id merchantId, ID contractId) {
    Set<Id> listofMerchant = new Set<Id>();
    listofMerchant.add(merchantId);
    System.debug('-- APHU11_EdgSyncCallout listofMerchant : ' + listofMerchant);

    Set<Id> listofContract = new Set<Id>();
    listofContract.add(contractId);
    System.debug('-- APHU11_EdgSyncCallout listofMerchant : ' + listofContract);

    String sJson = JSON.serialize(beforeEdg(listofMerchant, listofContract, true));
    System.debug('-- APHU11_EdgSyncCallout Json bafore Edg: ' + sJson);
    return sJson;
  }

  @AuraEnabled
  public static String[] saveEdgWS(Id merchantId, Id contractId) {
    Set<Id> listofMerchant = new Set<Id>();
    listofMerchant.add(merchantId);

    Set<Id> listofContract = new Set<Id>();
    listofContract.add(contractId);
    System.debug('-- APHU11_EdgSyncCallout listofMerchant : ' + listofMerchant);
    Set<Id> ModifiedElements = new Set<Id>();
    List<Contract> contractInst = APER12_Contract_Management.getContract(contractId);
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    accountsInputScope.put(
      merchantId,
      (contractInst[0].RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? 'merchant' : 'client')
    );
    //Call Ahmada's function! Yeah!
    //return WSHU02_SynchronizeMerchantWS.addUpdateMerchants(listofMerchant, true,contractId);

    APER30_AutoEnrollment_Management.syncRecordBU = contractInst[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)
    System.debug(
      '-- APHU11_EdgSyncCallout APER30_AutoEnrollment_Management.syncRecordBU : ' +
      APER30_AutoEnrollment_Management.syncRecordBU
    );
    //test sync V3
    return ER_SyncStructureWS.createStructureWS(
      listofMerchant,
      listofContract,
      'POST',
      'Activation',
      ModifiedElements,
      accountsInputScope
    );
  }

  public static APHU14_ResponseBeforeEdg beforeEdg(Set<Id> merchantId, Set<Id> contractId, Boolean fromAura) {
    System.debug('--- There are ' + merchantId.size() + ' merchants triggered, which are');
    System.debug('--- merchantIds : ' + merchantId);

    APHU14_ResponseBeforeEdg beforeEdg = new APHU14_ResponseBeforeEdg();
    beforeEdg.count = 0;
    beforeEdg.existing = false;

    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();
    merchantList = APHU11_EdgSyncCallout.getMerchants(merchantId);
    ContracttList = APHU11_EdgSyncCallout.getContracts(contractId);

    isToUpdate = merchantList[0].ER_Creation_date_in_OS__c != null;
    System.debug('--- Merchant already created in OS : ' + (merchantList[0].ER_Creation_date_in_OS__c != null));
    Boolean isTypeOperational = !ContracttList.isEmpty() && ContracttList[0].ER_Contract_Type__c.equals('Operational');

    //AKO checking before EDG Save
    if (isToUpdate == false && fromAura == true && isTypeOperational) {
      //**********Billing-LEGAL********
      if (merchantList[0].BillingStreet == null) {
        APHU13_ErrorBeforeEdg rowAccStreet = new APHU13_ErrorBeforeEdg();
        rowAccStreet.sObjName = 'Account';
        rowAccStreet.sName = merchantList[0].Name;
        rowAccStreet.sMessage = 'Legal street is empty';
        rowAccStreet.sLink = '/lightning/r/Account/' + merchantList[0].Id + '/view';
        rowAccStreet.sSection = 'Address Information-Legal Address';
        listError.add(rowAccStreet);
      }

      if (merchantList[0].BillingPostalCode == null) {
        APHU13_ErrorBeforeEdg rowAccZip = new APHU13_ErrorBeforeEdg();
        rowAccZip.sObjName = 'Account';
        rowAccZip.sName = merchantList[0].Name;
        rowAccZip.sMessage = 'Legal Zip/Postal Code is empty';
        rowAccZip.sLink = '/lightning/r/Account/' + merchantList[0].Id + '/view';
        rowAccZip.sSection = 'Address Information-Legal Address';
        listError.add(rowAccZip);
      }

      if (merchantList[0].BillingCity == null) {
        APHU13_ErrorBeforeEdg rowAccCity = new APHU13_ErrorBeforeEdg();
        rowAccCity.sObjName = 'Account';
        rowAccCity.sName = merchantList[0].Name;
        rowAccCity.sMessage = 'Legal City is empty';
        rowAccCity.sLink = '/lightning/r/Account/' + merchantList[0].Id + '/view';
        rowAccCity.sSection = 'Address Information-Legal Address';
        listError.add(rowAccCity);
      }

      System.debug('*** VAT Number = ' + merchantList[0].ER_VAT_Number__c);
      //OLA Update 07112019: VAT is not mandatory for CZ
      /*if (merchantList[0].ER_VAT_Number__c == null && merchantList[0].ER_Business_Unit__c == 'HU') {
        APHU13_ErrorBeforeEdg rowAccVAT = new APHU13_ErrorBeforeEdg();
        rowAccVAT.sObjName = 'Account';
        rowAccVAT.sName = merchantList[0].Name;
        rowAccVAT.sMessage = 'VAT Number is empty';
        rowAccVAT.sLink = '/lightning/r/Account/' + merchantList[0].Id + '/view';
        rowAccVAT.sSection = 'Account Information';
        listError.add(rowAccVAT);
      }*/

      /*if (merchantList[0].ER_Registration_Number__c == null && merchantList[0].ER_Business_Unit__c == 'CZ') {
        APHU13_ErrorBeforeEdg rowCRN = new APHU13_ErrorBeforeEdg();
        rowCRN.sObjName = 'Account';
        rowCRN.sName = merchantList[0].Name;
        rowCRN.sMessage = 'Company Registration Number is empty';
        rowCRN.sLink = '/lightning/r/Account/' + merchantList[0].Id + '/view';
        rowCRN.sSection = 'Account Information';
        listError.add(rowCRN);
      }*/

      //**********HEAD QUARTER CONTACT***************
      if (
        merchantList[0].HU_HQ_Contact__c == null &&
        (merchantList[0].ER_Business_Unit__c == 'CZ' ||
        merchantList[0].ER_Business_Unit__c == 'HU')
      ) {
        //The Head Quarter contact is missing on Account !
        APHU13_ErrorBeforeEdg rowFinA1 = new APHU13_ErrorBeforeEdg();
        rowFinA1.sObjName = 'Account';
        rowFinA1.sName = merchantList[0].Name;
        rowFinA1.sMessage = 'No Head Office Contact attached to Account';
        rowFinA1.sLink = '/lightning/r/Account/' + merchantList[0].Id + '/view';
        rowFinA1.sSection = 'Address Information';
        listError.add(rowFinA1);
      }

      System.debug('*** HQ Contact=' + merchantList[0].HU_HQ_Contact__c);
      /*if (
        merchantList[0].HU_HQ_Contact__c != null &&
        merchantList[0].HU_HQ_Contact__r.Salutation == null &&
        (merchantList[0].ER_Business_Unit__c == 'CZ' ||
        merchantList[0].ER_Business_Unit__c == 'HU')
      ) {
        System.debug('*** Salutations' + merchantList[0].HU_HQ_Contact__r.Salutation);
        APHU13_ErrorBeforeEdg rowCntSalutation = new APHU13_ErrorBeforeEdg();
        rowCntSalutation.sObjName = 'Contact';
        rowCntSalutation.sName =
          merchantList[0].HU_HQ_Contact__r.FirstName +
          ' ' +
          merchantList[0].HU_HQ_Contact__r.LastName;
        rowCntSalutation.sMessage = 'Salutations are empty on Head Office Contact';
        rowCntSalutation.sLink = '/lightning/r/Contact/' + merchantList[0].HU_HQ_Contact__r.Id + '/view';
        rowCntSalutation.sSection = 'Contact Information-(Name Zone)';
        listError.add(rowCntSalutation);
      }*/
    } else if (isToUpdate == true && fromAura == true) {
      //The merchand had been already created
      // ***** Very important : Existing true***
      beforeEdg.existing = true;
      beforeEdg.CreationDateInOS = 'Creation date in OS - ' + merchantList[0].ER_Creation_date_in_OS__c;
    }

    if (!ContracttList.isEmpty())
      listError.addAll(checkFinancials(isTypeOperational, merchantId, merchantList[0], ContracttList[0]));

    if (isTypeOperational) {
      /*if (
        !ContracttList.isEmpty() &&
        ContracttList[0].CustomerSignedId == null &&
        merchantList[0].ER_Business_Unit__c == 'CZ'
      ) {
        APHU13_ErrorBeforeEdg rowSignee = new APHU13_ErrorBeforeEdg();
        rowSignee.sObjName = 'Contract';
        rowSignee.sName = ContracttList[0].ContractNumber;
        rowSignee.sMessage = 'Customer Signed By is empty';
        rowSignee.sLink = '/lightning/r/Contract/' + ContracttList[0].Id + '/view';
        rowSignee.sSection = 'Signature Information';
        listError.add(rowSignee);
      }*/
      /*if (
        !ContracttList.isEmpty() &&
        ContracttList[0].CustomerSigned.Email == null &&
        ContracttList[0].CustomerSignedId != null &&
        merchantList[0].ER_Business_Unit__c == 'CZ'
      ) {
        APHU13_ErrorBeforeEdg rowSigneeEmail = new APHU13_ErrorBeforeEdg();
        rowSigneeEmail.sObjName = 'Contract';
        rowSigneeEmail.sName = ContracttList[0].ContractNumber;
        rowSigneeEmail.sMessage = 'Customer Signed By must have an Email';
        rowSigneeEmail.sLink = '/lightning/r/Contract/' + ContracttList[0].Id + '/view';
        rowSigneeEmail.sSection = 'Signature Information';
        listError.add(rowSigneeEmail);
      }*/

      /*if (!ContracttList.isEmpty() && ContracttList[0].ER_Business_Unit__c.equalsIgnoreCase('BENELUX')) {
        listError.addAll(checkLegalAddress(merchantList[0]));
        listError.addAll(checkStoreContact(merchantList[0]));
        listError.addAll(checkLegalName(merchantList[0]));
        listError.addAll(checkHeadOfficeContact(merchantList[0]));
        //listError.addAll(checkStartDateAcceptor(merchantList[0]));
        listError.addAll(checkSEPABankAccount(merchantList[0], ContracttList[0]));
        listError.addAll(checkSignature(ContracttList[0]));
      }*/

      /*if (
        !ContracttList.isEmpty() &&
        ContracttList[0].ER_BUPicklist__c == Constants.ES &&
        ContracttList[0].RecordType.DeveloperName == Constants.CONTRACT_CLIENT_RT &&
        ContracttList[0].ER_InvoicingFrequency2__c != null &&
        ContracttList[0].ER_InvoicingFrequency2__c != Constants.CONTRACT_INVOICING_FREQUENCY_DEFERRED &&
        ContracttList[0].ER_InvoicingFrequency2__c != Constants.CONTRACT_INVOICING_FREQUENCY_GROUPED &&
        ContracttList[0].ER_InvoicingFrequency2__c != Constants.CONTRACT_INVOICING_FREQUENCY_PER_ORDER
      ) {
        APHU13_ErrorBeforeEdg rowSignee = new APHU13_ErrorBeforeEdg();
        rowSignee.sObjName = 'Contract';
        rowSignee.sName = ContracttList[0].ContractNumber;
        rowSignee.sMessage = 'The Invoicing Frequency should be either : Per Order, Deferred or Grouped';
        rowSignee.sLink = '/lightning/r/Contract/' + ContracttList[0].Id + '/view';
        rowSignee.sSection = 'Financial Conditions';
        listError.add(rowSignee);
      }*/
    }

    System.debug('--- Check for Errors before EDG :' + beforeEdg);
    beforeEdg.data = listError;
    beforeEdg.count = listError.size();
    return beforeEdg;
  }

  /**
   * @author Noor
   * @description For Opportunity linked to the contract
   *              If payment method = Direct debit
   *                  Sepa bank account should be linked to the opp
   *                  Sepa bank account linked to the opp should have field SEPA start date not empty
   *                  Sepa bank account linked to the opp should have field SEPA active checked (VR Already exist)
   * @param a account
   * @param c contract
   * @return list of errors
   */
  public static List<APHU13_ErrorBeforeEdg> checkSEPABankAccount(Account a, Contract c) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    /*String section = 'SEPA Bank Account';

    //if (c.ER_OpportunityId__r.ER_PaymentMethod__c.equalsIgnoreCase('Direct Debit')) {
    if (c.ER_OpportunityId__r.ER_PaymentMethod__c == 'Direct Debit') {
      if (String.isBlank(c.ER_OpportunityId__r.ER_SEPA_Bank_Account__c)) {
        APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
        rowLegalName.sObjName = 'Opportunity';
        rowLegalName.sName = c.ER_OpportunityId__r.Name;
        rowLegalName.sMessage = 'SEPA Bank Account should be linked to the opportunity';
        rowLegalName.sLink = '/lightning/r/Opportunity/' + c.ER_OpportunityId__c + '/view';
        rowLegalName.sSection = section;
        listError.add(rowLegalName);
      } else {
        if (c.ER_OpportunityId__r.ER_SEPA_Bank_Account__r.ER_SEPA_start_date__c == null) {
          APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
          rowLegalName.sObjName = 'ER_Bank_Account__c';
          rowLegalName.sName = c.ER_OpportunityId__r.Name;
          rowLegalName.sMessage = 'SEPA Start Date should be filled on SEPA Bank Account';
          rowLegalName.sLink =
            '/lightning/r/ER_Bank_Account__c/' +
            c.ER_OpportunityId__r.ER_SEPA_Bank_Account__c +
            '/view';
          rowLegalName.sSection = section;
          listError.add(rowLegalName);
        }
        if (!c.ER_OpportunityId__r.ER_SEPA_Bank_Account__r.ER_SEPA_active__c) {
          APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
          rowLegalName.sObjName = 'ER_Bank_Account__c';
          rowLegalName.sName = c.ER_OpportunityId__r.Name;
          rowLegalName.sMessage = 'SEPA Active should be checked on SEPA Bank Account';
          rowLegalName.sLink =
            '/lightning/r/ER_Bank_Account__c/' +
            c.ER_OpportunityId__r.ER_SEPA_Bank_Account__c +
            '/view';
          rowLegalName.sSection = section;
          listError.add(rowLegalName);
        }
      }
    }*/
    return listError;
  }

  /**
   * @author Noor
   * @description The fields Customer Signed By
   *                        Company Signed By
   *                        Company Signed Date
   *                        Customer Signed Date
   *               must be mandatory
   * @param c contract
   * @return list of errors
   */
  public static List<APHU13_ErrorBeforeEdg> checkSignature(Contract c) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    /*String section = 'Signature Information';

    if (String.isBlank(c.CustomerSignedId)) {
      APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
      rowLegalName.sObjName = 'Contract';
      rowLegalName.sName = c.Name;
      rowLegalName.sMessage = 'Customer Signed By is Mandatory';
      rowLegalName.sLink = '/lightning/r/Opportunity/' + c.Id + '/view';
      rowLegalName.sSection = section;
      listError.add(rowLegalName);
    }
    if (c.CustomerSignedDate == null) {
      APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
      rowLegalName.sObjName = 'Contract';
      rowLegalName.sName = c.Name;
      rowLegalName.sMessage = 'Customer Signed Date is Mandatory';
      rowLegalName.sLink = '/lightning/r/Opportunity/' + c.Id + '/view';
      rowLegalName.sSection = section;
      listError.add(rowLegalName);
    }
    if (String.isBlank(c.CompanySignedId)) {
      APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
      rowLegalName.sObjName = 'Contract';
      rowLegalName.sName = c.Name;
      rowLegalName.sMessage = 'Company Signed By is Mandatory';
      rowLegalName.sLink = '/lightning/r/Opportunity/' + c.Id + '/view';
      rowLegalName.sSection = section;
      listError.add(rowLegalName);
    }
    if (c.CompanySignedDate == null) {
      APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
      rowLegalName.sObjName = 'Contract';
      rowLegalName.sName = c.Name;
      rowLegalName.sMessage = 'Company Signed Date is Mandatory';
      rowLegalName.sLink = '/lightning/r/Opportunity/' + c.Id + '/view';
      rowLegalName.sSection = section;
      listError.add(rowLegalName);
    }*/

    return listError;
  }

  /**
   * @description check  Financial Center of type Operational and Employee Engagement Platform
   *
   * @param m account merchant
   * @param c contract
   *
   * @return list APHU13_ErrorBeforeEdg to display on screen
   */
  public static List<APHU13_ErrorBeforeEdg> checkOperationalFinancialCenter(Account m, Contract c) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    //All BUs
    if (financialC.size() == 0) {
      //Financial Center not related to Account
      /*APHU13_ErrorBeforeEdg rowFinA0 = new APHU13_ErrorBeforeEdg();
      rowFinA0.sObjName = 'Account';
      rowFinA0.sName = m.Name;
      rowFinA0.sMessage =
        'No ' +
        (c.RecordType.DeveloperName == Constants.CONTRACT_MERCHANT_RT ? Constants.MERCHANT : Constants.CLIENT) +
        ' Financial Center related to Account';
      rowFinA0.sLink = '/lightning/r/Account/' + merchantList[0].Id + '/view';
      rowFinA0.sSection = 'Financial Center not related to Account';
      listError.add(rowFinA0);*/
    }

    if (financialC.size() > 0) {
      for (ER_Financial_Center__c financialCe : financialC) {
        if (
          financialCe.ER_Contact__c == null &&
          (m.ER_Creation_date_in_OS__c == null ||
          financialCe.ER_Creation_date_in_OS__c != null)
        ) {
          APHU13_ErrorBeforeEdg rowFin1 = new APHU13_ErrorBeforeEdg();
          rowFin1.sObjName = 'Financial Center';
          rowFin1.sName = financialCe.Name;
          rowFin1.sMessage = 'Contact is missing on Financial Center';
          rowFin1.sLink = '/lightning/r/ER_Financial_Center__c/' + financialCe.Id + '/view';
          rowFin1.sSection = 'Information';
          listError.add(rowFin1);
        }

        /*if (
          (merchantList[0].ER_Business_Unit__c == 'CZ' ||
          merchantList[0].ER_Business_Unit__c == 'HU') &&
          financialCe.ER_Contact__c != null &&
          m.ER_Creation_date_in_OS__c == null &&
          financialCe.ER_Contact__r.Salutation == null
        ) {
          APHU13_ErrorBeforeEdg rowCntSalutationInv = new APHU13_ErrorBeforeEdg();
          rowCntSalutationInv.sObjName = 'Contact';
          rowCntSalutationInv.sName = financialCe.ER_Contact__r.FirstName + ' ' + financialCe.ER_Contact__r.FirstName;
          rowCntSalutationInv.sMessage = 'Salutations are empty on FC Contact';
          rowCntSalutationInv.sLink = '/lightning/r/Contact/' + financialCe.ER_Contact__c + '/view';
          rowCntSalutationInv.sSection = 'Contact Information-(Name Zone)';
          listError.add(rowCntSalutationInv);
        }*/

        if (
          financialCe.ER_Bank_Account__c == null &&
          ((financialCe.ER_Type__c != Constants.FC_CLIENT_TYPE &&
          financialCe.ER_BUPicklist__c != Constants.ES &&
          m.ER_Creation_date_in_OS__c == null) ||
          ((m.ER_Creation_date_in_OS__c == null ||
          financialCe.ER_Creation_date_in_OS__c != null) &&
          financialCe.ER_Type__c == Constants.FC_CLIENT_TYPE &&
          financialCe.ER_BUPicklist__c == Constants.ES &&
          c.RecordType.DeveloperName == Constants.CONTRACT_CLIENT_RT &&
          c.ER_PaymentMethod2__c == Constants.CONTRACT_PAYMENT_METHOD_DIRECT_DEBIT &&
          financialC.size() == 1))
        ) {
          APHU13_ErrorBeforeEdg rowFin2 = new APHU13_ErrorBeforeEdg();
          rowFin2.sObjName = 'Financial Center';
          rowFin2.sName = financialCe.Name;
          rowFin2.sMessage = 'Bank Account is missing on Financial Center';
          rowFin2.sLink = '/lightning/r/ER_Financial_Center__c/' + financialCe.Id + '/view';
          rowFin2.sSection = 'Information';
          listError.add(rowFin2);
        }
        if (
          financialCe.ER_Business_Unit__c != 'CZ' &&
          financialCe.ER_Bank_Account__c != null &&
          m.ER_Creation_date_in_OS__c == null &&
          financialCe.ER_Bank_Account__r.ER_IBAN__c == null
        ) {
          APHU13_ErrorBeforeEdg rowIBAN = new APHU13_ErrorBeforeEdg();
          rowIBAN.sObjName = 'Bank Account';
          rowIBAN.sName = financialCe.ER_Bank_Account__r.Name;
          rowIBAN.sMessage = 'IBAN is empty';
          rowIBAN.sLink = '/lightning/r/ER_Bank_Account__c/' + financialCe.ER_Bank_Account__r.Id + '/view';
          rowIBAN.sSection = 'Bank Account Detail';
          listError.add(rowIBAN);
        }
      }
    }
    return listError;
  }

  /**
   * @description check  Financial Center of type Operational and Employee Engagement Platform
   *
   * @param m account merchant
   * @param c contract
   *
   * @return list APHU13_ErrorBeforeEdg to display on screen
   */
  public static List<APHU13_ErrorBeforeEdg> checkGeneralFinancialCenter(Account m, Contract c) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    /*if (financialC.size() > 0) {
      for (ER_Financial_Center__c financialCe : financialC) {
        if (
          financialCe.ER_BUPicklist__c == Constants.FI &&
          financialCe.ER_Preferred_Invoicing_Method__c == 'E-invoice' &&
          (financialCe.ERFI_OVT_Code__c == null ||
          financialCe.ERFI_OVT_Operator__c == null)
        ) {
          APHU13_ErrorBeforeEdg rowFin3 = new APHU13_ErrorBeforeEdg();
          rowFin3.sObjName = 'Financial Center';
          rowFin3.sName = financialCe.Name;
          rowFin3.sMessage = 'Missing OVT Code or OVT Operator';
          rowFin3.sLink = '/lightning/r/ER_Financial_Center__c/' + financialCe.Id + '/view';
          rowFin3.sSection = 'Information';
          listError.add(rowFin3);
        }
      }
    }*/
    return listError;
  }

  /**
   * @description check if financial center is valid
   *
   * @param merchantId list of merchant id
   * @param m account merchant
   * @param c contract
   *
   * @return list APHU13_ErrorBeforeEdg to display on screen
   */
  public static List<APHU13_ErrorBeforeEdg> checkFinancials(
    Boolean isTypeOperational,
    Set<Id> merchantId,
    Account m,
    Contract c
  ) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    financialC = APHU11_EdgSyncCallout.getFinancialCenters(
      merchantId,
      ' and ER_Type__c = \'' +
      (c.RecordType.DeveloperName == Constants.CONTRACT_MERCHANT_RT
        ? Constants.FC_MERCHANT_TYPE
        : Constants.FC_CLIENT_TYPE) +
      '\''
    );
    //Check financial  except for BU Finland and Type Employee Engagement Platform
    if (
      isTypeOperational && !(m.ER_Business_Unit__c == 'FI' && c.ER_Contract_Type__c == 'Employee Engagement Platform')
    )
    listError = checkOperationalFinancialCenter(m, c);
    listError.addAll(checkGeneralFinancialCenter(m,c));
    listError.addAll(checkMasterFinancialCenter(m, c));
    return listError;
  }

  /**
   * @author Noor
   * @description check if account has a master Financial Center and that the Financial Center contains a Preferred Invoicing Method
   *
   * @param m account merchant
   * @param c contract
   *
   * @return list APHU13_ErrorBeforeEdg to display on screen
   */
  public static List<APHU13_ErrorBeforeEdg> checkMasterFinancialCenter(Account m, Contract c) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    //Check Client
    /*if (
      (m.ER_BUPicklist__c == Constants.FI ||
      m.ER_BUPicklist__c == Constants.GR) &&
      c.RecordType.DeveloperName.equals(Constants.CONTRACT_CLIENT_RT) &&
      (String.isBlank(m.ER_Client_Master_FinancialCenter__c) ||
      (String.isNotBlank(m.ER_Client_Master_FinancialCenter__c) &&
      String.isBlank(m.ER_Client_Master_FinancialCenter__r.ER_Preferred_Invoicing_Method__c)))
    ) {
      APHU13_ErrorBeforeEdg log = new APHU13_ErrorBeforeEdg();
      log.sObjName = SObjectType.Account.getLabel();
      log.sName = m.Name;
      log.sMessage = Label.LAB_SF_MISSING_CLIENT_MASTER_FC;
      log.sLink = String.format(Constants.NAVIGATION_URL, new List<String>{ SObjectType.Account.getLabel(), m.Id });
      log.sSection = SObjectType.ER_Financial_Center__c.getLabel();
      listError.add(log);
    }*/

    //Check Merchant
    /*if (
      (m.ER_BUPicklist__c == Constants.FI ||
      m.ER_BUPicklist__c == Constants.GR) &&
      c.RecordType.DeveloperName.equals(Constants.CONTRACT_MERCHANT_RT) &&
      (String.isBlank(m.ER_Merchant_Master_FinancialCenter__c) ||
      (String.isNotBlank(m.ER_Merchant_Master_FinancialCenter__c) &&
      String.isBlank(m.ER_Merchant_Master_FinancialCenter__r.ER_Preferred_Invoicing_Method__c)))
    ) {
      APHU13_ErrorBeforeEdg log = new APHU13_ErrorBeforeEdg();
      log.sObjName = SObjectType.Account.getLabel();
      log.sName = m.Name;
      log.sMessage = Label.LAB_SF_MISSING_MERCHANT_MASTER_FC;
      log.sLink = String.format(Constants.NAVIGATION_URL, new List<String>{ SObjectType.Account.getLabel(), m.Id });
      log.sSection = SObjectType.ER_Financial_Center__c.getLabel();
      listError.add(log);
    }*/
    return listError;
  }

  /**
    * @author snica
    * @date 07/02/2022
    * @description Check if startDate is populated on acceptor
     *
    * @param merchant Account
    * @return

    public static List<APHU13_ErrorBeforeEdg> checkStartDateAcceptor(Account merchant) {
        List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

        ER_Acceptor__c acceptor= new ER_Acceptor__c();
        List<ER_Acceptor__c> acceptors = [SELECT Id, Name, ER_Start_Date__c FROM ER_Acceptor__c WHERE ER_Aggregator__c = :merchant.Id];
        if (!acceptors.isEmpty() && acceptors[0].ER_Start_Date__c == null) {
            APHU13_ErrorBeforeEdg rowStartDate = new APHU13_ErrorBeforeEdg();
            rowStartDate.sObjName = 'Acceptor';
            rowStartDate.sName = acceptor.Name;
            rowStartDate.sMessage = Label.FIELD_START_DATE_MANDATORY;
            rowStartDate.sLink = '/lightning/r/ER_Acceptor__c/' + acceptor.Id + '/view';
            rowStartDate.sSection = 'Acceptor Information-Start Date';
            listError.add(rowStartDate);
        }

        return listError;
    }*/

  /**
   * @author snica
   * @date 07/02/2022
   * @description Check if legalName is populated on Account
   *
   * @param merchant Account
   * @return
   */
  public static List<APHU13_ErrorBeforeEdg> checkLegalName(Account merchant) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    /*String accountLegalName = merchant.ER_Legal_Name__c;
    String accountLink = '/lightning/r/Account/' + merchant.Id + '/view';
    String section = 'Account Information-Legal Name';

    if (merchant.ER_Creation_date_in_OS__c == null) {
      if (String.isBlank(merchant.ER_Legal_Name__c)) {
        APHU13_ErrorBeforeEdg rowLegalName = new APHU13_ErrorBeforeEdg();
        rowLegalName.sObjName = 'Account';
        rowLegalName.sName = accountLegalName;
        rowLegalName.sMessage = Label.FIELD_LEGAL_NAME_MANDATORY;
        rowLegalName.sLink = accountLink;
        rowLegalName.sSection = section;
        listError.add(rowLegalName);
      }
    }*/

    return listError;
  }

  /**
   * @author snica
   * @date 07/02/2022
   * @description Check if Head office contact is populated on Account
   *
   * @param merchant Account
   * @return
   */
  public static List<APHU13_ErrorBeforeEdg> checkHeadOfficeContact(Account merchant) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    /*String accountHeadOfficeContact = merchant.HU_HQ_Contact__c;
    String accountLink = '/lightning/r/Account/' + merchant.Id + '/view';
    String section = 'Account Information - Head Office Contact';

    if (merchant.ER_Creation_date_in_OS__c == null) {
      if (String.isBlank(merchant.HU_HQ_Contact__c)) {
        APHU13_ErrorBeforeEdg rowHeadOfficeContact = new APHU13_ErrorBeforeEdg();
        rowHeadOfficeContact.sObjName = 'Account';
        rowHeadOfficeContact.sName = accountHeadOfficeContact;
        rowHeadOfficeContact.sMessage = Label.FIELD_HEAD_OFFICE_CONTACT_MANDATORY;
        rowHeadOfficeContact.sLink = accountLink;
        rowHeadOfficeContact.sSection = section;
        listError.add(rowHeadOfficeContact);
      }
    }*/

    return listError;
  }

  /**
   * @author Noor
   * @date 14/09/2021
   * @description Check if legal address is populated
   *
   * @param merchant Account
   * @return
   */
  @AuraEnabled
  public static List<APHU13_ErrorBeforeEdg> checkLegalAddress(Account merchant) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    /*String accountName = merchant.Name;
    String accountLink = '/lightning/r/Account/' + merchant.Id + '/view';
    String section = 'Address Information-Legal Address';

    if (merchant.ER_Creation_date_in_OS__c == null) {
      if (String.isBlank(merchant.BillingStreet)) {
        APHU13_ErrorBeforeEdg rowAccStreet = new APHU13_ErrorBeforeEdg();
        rowAccStreet.sObjName = 'Account';
        rowAccStreet.sName = accountName;
        rowAccStreet.sMessage = Label.FIELD_LEGAL_STREET_MANDATORY;
        rowAccStreet.sLink = accountLink;
        rowAccStreet.sSection = section;
        listError.add(rowAccStreet);
      }

      if (String.isBlank(merchant.BillingPostalCode)) {
        APHU13_ErrorBeforeEdg rowAccZip = new APHU13_ErrorBeforeEdg();
        rowAccZip.sObjName = 'Account';
        rowAccZip.sName = accountName;
        rowAccZip.sMessage = Label.FIELD_LEGAL_ZIP_CODE_MANDATORY;
        rowAccZip.sLink = accountLink;
        rowAccZip.sSection = section;
        listError.add(rowAccZip);
      }

      if (String.isBlank(merchant.BillingCity)) {
        APHU13_ErrorBeforeEdg rowAccCity = new APHU13_ErrorBeforeEdg();
        rowAccCity.sObjName = 'Account';
        rowAccCity.sName = accountName;
        rowAccCity.sMessage = Label.FIELD_LEGAL_CITY_MANDATORY;
        rowAccCity.sLink = accountLink;
        rowAccCity.sSection = section;
        listError.add(rowAccCity);
      }
    }*/

    return listError;
  }

  /**
   * @author Noor
   * @date 19/01/2022
   * @description Check if contact is populated on Store
   *
   * @param merchant Account
   * @return
   */
  public static List<APHU13_ErrorBeforeEdg> checkStoreContact(Account merchant) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    /*for (ER_Store__c store : merchant.Stores__r) {
      if (String.isBlank(store.ER_Contact__c) && merchant.ER_Creation_date_in_OS__c == null) {
        APHU13_ErrorBeforeEdg rowAccStreet = new APHU13_ErrorBeforeEdg();
        rowAccStreet.sObjName = 'Store';
        rowAccStreet.sName = store.Name;
        rowAccStreet.sMessage = Label.FIELD_STORE_CONTACT_MANDATORY;
        rowAccStreet.sLink = '/lightning/r/ER_Store__c/' + store.Id + '/view';
        rowAccStreet.sSection = 'Store information';
        listError.add(rowAccStreet);
      }
    }*/
    return listError;
  }

  // retrieve account list
  public static List<Account> getMerchants(Set<Id> merchantIdList) {
    String soql =
      'SELECT Id,ER_BUPicklist__c,ER_Registration_Number__c, Name, ER_Card_Operational_System_ID__c, ER_Paper_Operational_System_ID__c, ' +
      'Industry, ER_VAT_Number__c, CreatedDate, CreatedById, ER_Status__c,ER_Business_Unit__c,ER_Legal_Name__c, ' +
      'ER_Client_Master_FinancialCenter__c,ER_Client_Master_FinancialCenter__r.ER_Preferred_Invoicing_Method__c, ' +
      'ER_Merchant_Master_FinancialCenter__c, ER_Merchant_Master_FinancialCenter__r.ER_Preferred_Invoicing_Method__c, ' +
      /* HQ contact information */
      'HU_HQ_Contact__c, ' +
      'HU_HQ_Contact__r.Email, HU_HQ_Contact__r.Phone, HU_HQ_Contact__r.MobilePhone, HU_HQ_Contact__r.Fax, ' +
      'HU_HQ_Contact__r.FirstName, HU_HQ_Contact__r.LastName,HU_HQ_Contact__r.ER_BUPicklist__c,HU_HQ_Contact__r.CZ_AcademicTitle__c, HU_HQ_Contact__r.Salutation, ' +
      'HU_HQ_Contact__r.MailingStreet, HU_HQ_Contact__r.MailingCity, HU_HQ_Contact__r.MailingPostalCode, ' +
      'HU_HQ_Contact__r.MailingCountry, HU_HQ_Contact__r.MailingLatitude, HU_HQ_Contact__r.MailingLongitude, ' +
      'ER_Creation_date_in_OS__c, ER_Last_date_of_Sync__c, ' +
      'BillingAddress, BillingStreet, BillingCity, BillingPostalCode, ' +
      'BillingCountry, BillingLatitude, BillingLongitude, ' +
      '(SELECT Id,Name, ER_Contact__c FROM Stores__r WHERE ER_Status__c = \'Active\') ' +
      'FROM Account ' +
      'WHERE Id IN: merchantIdList';

    return Database.query(soql);
  }

  // retrieve contract list
  public static List<Contract> getContracts(Set<Id> contractsIdList) {
    system.debug('contractsIdList : ' + contractsIdList);
    String soql =
      'select Id,Name, AccountId,ContractNumber, RecordType.DeveloperName, Account.Name, Pricebook2Id, CurrencyIsoCode, ' +
      'ER_business_unit__c, CustomerSignedId, CustomerSigned.Email, ER_Contract_Type__c, ER_OpportunityId__c, ' +
      'CustomerSignedDate, CompanySignedId, CompanySignedDate, ER_PaymentMethod2__c, ER_InvoicingFrequency2__c, ER_BUPicklist__c,' +
      'ER_OpportunityId__r.Name, ER_OpportunityId__r.ER_PaymentMethod__c, ER_OpportunityId__r.ER_SEPA_Bank_Account__c, ' +
      'ER_OpportunityId__r.ER_SEPA_Bank_Account__r.ER_SEPA_start_date__c, ER_OpportunityId__r.ER_SEPA_Bank_Account__r.ER_SEPA_active__c , '+
      'ER_OpportunityId__r.LeadSource,RecordTypeId ' +
      'from Contract ' +
      'WHERE Id IN: contractsIdList';
    system.debug(' soql : ' + soql);
    return Database.query(soql);
  }

  // retrieve contact list
  public static List<Contact> getContacts(Set<Id> contactsIdList) {
    String soql =
      'SELECT Id,ER_Role__c,ER_BUPicklist__c,CZ_AcademicTitle__c,  AccountId, Salutation, ' +
      'Email, Phone, MobilePhone, ' +
      'Fax, FirstName, ' +
      'LastName, Title, Department, ' +
      'MailingStreet, MailingCity, MailingPostalCode, ' +
      'MailingCountry, MailingLatitude, MailingLongitude ' +
      'FROM Contact ' +
      'WHERE Id IN: contactsIdList';

    return Database.query(soql);
  }

  // retrieve Store list
  public static List<ER_Store__c> getStores(Set<Id> merchantIdList) {
    string firstelement = (new List<Id>(merchantIdList))[0];
    String mycondition = (firstelement.startsWithIgnoreCase('001')) ? 'ER_Merchant__c' : 'ER_Financial_Center__c';

    String soql =
      'SELECT Id,ER_Website_URL__c,ER_Brand__c,CZ_Store_reference__c,CreatedDate,ER_E_Shop__c,ER_Do_not_publish__c,ER_Description__c,ER_Business_Unit__c, ER_Merchant__c, Name, ' +
      'ER_Contact__c, ER_Street__c, ER_City__c, ER_Creation_Date_In_OS__c,ER_Latitude_Longitude__Latitude__s,ER_Latitude_Longitude__Longitude__s,' +
      'ER_Zip_Code__c, ER_Financial_Center__c,ER_Financial_Center__r.ER_Creation_date_in_OS__c,ER_Contact__r.ER_Role__c, ER_Contact__r.Fax, ' +
      'ER_Contact__r.Email,ER_Contact__r.ER_BUPicklist__c,ER_Contact__r.CZ_AcademicTitle__c, ER_Contact__r.Phone, ER_Contact__r.MobilePhone, ' +
      'ER_Contact__r.FirstName, ER_Contact__r.LastName, ER_Contact__r.Salutation,ER_Status__c, ' +
      'ER_Contact__r.MailingStreet, ER_Contact__r.MailingCity, ER_Contact__r.MailingPostalCode, ' +
      'ER_Contact__r.MailingCountry, ER_Contact__r.MailingLatitude, ER_Contact__r.MailingLongitude, ' +
      '( ' +
      'SELECT id, Name, ER_MID_Authorization__c, ER_MID_Clearing__c, ' +
      'ER_TID_Clearing__c, ER_Card_Operational_System_ID__c,ER_Store__r.ER_Financial_Center__c ' +
      'FROM Acceptors__r) ' +
      'FROM ER_Store__c ' +
      'WHERE ' +
      mycondition +
      ' IN: merchantIdList';

    return Database.query(soql);
  }

  // retrieve acceptor list
  public static List<ER_Acceptor__c> getAcceptors(Set<Id> accpId) {
    return [
      SELECT
        id,
        Name,
        ER_MID_Authorization__c,
        ER_TID_Clearing__c,
        ER_Card_Operational_System_ID__c,
        ER_MID_Clearing__c,
        ER_Store__r.ER_Financial_Center__c,
        ER_Store__r.ER_Merchant__c,
        ER_Store__r.ER_Creation_Date_In_OS__c,
        ER_Last_date_of_Sync__c,
        CreatedDate
      FROM ER_Acceptor__c
      WHERE Id IN :accpId
    ];
  }

  // retrieve Financial Center list
  public static List<ER_Financial_Center__c> getFinancialCenters(Set<Id> merchantIdList, String additionalCondition) {
    // Convert Set<Id> to Set<String>
    String themerchantId = ((List<String>) new List<Id>(merchantIdList))[0];

    String soql =
      'SELECT Id,ER_Business_Unit__c, ER_Account_Name__c, Name,ER_Email__c,ER_Secondary_Email__c, ' +
      'ER_Bank_Account__c, ER_Contact__c, ER_Street__c, ER_Type__c, ' +
      'ER_City__c, ER_Zip_Code__c, ER_Contact__r.Fax, ER_BUPicklist__c,' +
      'ER_Card_Operational_System_ID__c, ER_Creation_date_in_OS__c, ' +
      'ER_Preferred_Invoicing_Method__c,ERFI_OVT_Code__c,ERFI_OVT_Operator__c,' +
      /* and referenced Bank Account*/
      'ER_Contact__r.FirstName,ER_Contact__r.ER_Role__c, ER_Contact__r.LastName, ' +
      'ER_Contact__r.Salutation,ER_Contact__r.ER_BUPicklist__c,ER_Contact__r.CZ_AcademicTitle__c, ER_Contact__r.Email, ' +
      'ER_Contact__r.Phone, ER_Contact__r.MobilePhone, ' +
      'ER_Contact__r.MailingStreet, ER_Contact__r.MailingCity, ER_Contact__r.MailingPostalCode, ' +
      'ER_Contact__r.MailingCountry, ER_Contact__r.MailingLatitude, ER_Contact__r.MailingLongitude, ' +
      /* and referenced Bank Account*/
      'ER_Bank_Account__r.Name, ER_Bank_Account__r.ER_Bank_Name__c, ' +
      'ER_Bank_Account__r.ER_Bank_Account_Number__c, ER_Bank_Account__r.ER_IBAN__c, ' +
      'ER_Bank_Account__r.ER_Bank_Account_Number_Prefix__c ' +
      'FROM ER_Financial_Center__c ' +
      'WHERE ';

    /* if an account id or an invoice center id */
    if (themerchantId.startsWithIgnoreCase('001')) {
      /* account id */
      soql += 'ER_Account_Name__c IN: merchantIdList';
    } else {
      soql += 'Id IN: merchantIdList';
    }
    soql += additionalCondition;

    System.debug('--- Invoice center request : ' + soql);

    System.debug('--- Invoice center request : ' + merchantIdList);

    return (List<ER_Financial_Center__c>) Database.query(soql);
  }

  @AuraEnabled
  public static Account getAccountWS(Id accId) {
    return [SELECT Name FROM Account WHERE Id = :accId];
  }
}