/**
 * Created by Saad on 06/06/2023.
 */

public without sharing class ManageFinancialCenterWOS {
  public static Map<String, String> getFinancialCenterInfos(String financialCenterId) {
    List<ER_Financial_Center__c> existingFinancialCenter = [
      SELECT
        Id,
        ER_Account_Name__r.Id,
        ER_Account_Name__r.Name,
        ER_Account_Name__r.BillingCity,
        ER_Account_Name__r.BillingPostalCode,
        ER_Account_Name__r.BillingStreet,
        ER_Account_Name__r.Phone,
        ER_Account_Name__r.BillingCountry,
        ER_Contact__r.FirstName,
        ER_Contact__r.LastName,
        ER_Contact__r.Email,
        Name,
        ER_Contact__r.Phone,
        ER_Contact__r.MobilePhone,
        ER_Account_Name__r.ER_Legal_Name__c,
        ER_Preferred_Invoicing_Method__c,
        ER_Bank_Account__r.ER_IBAN__c,
        ER_Bank_Account__r.ER_BIC__c,
        ER_Invoicing_Street__c,
        ER_Invoicing_Zip_Code__c,
        ER_Invoicing_City__c,
        ER_Invoicing_Country__c,
        ER_Contact__c,
        ERFI_OVT_Code__c,
        ERFI_OVT_Operator__c,
        ER_Account_Name__r.ER_Registration_Number__c
      FROM ER_Financial_Center__c
      WHERE Id = :financialCenterId
    ];
    if (!existingFinancialCenter.isEmpty()) {
      return getFinancialCenterInfoMap(existingFinancialCenter[0]);
    }
    return null;
  }

  private static Map<String, String> getFinancialCenterInfoMap(ER_Financial_Center__c aFinancialCenter) {
    Map<String, String> infoMap = new Map<String, String>();
    infoMap.put('accountId', aFinancialCenter.ER_Account_Name__r.Id);
    infoMap.put('company', aFinancialCenter.ER_Account_Name__r.Name);
    infoMap.put('phone', aFinancialCenter.ER_Account_Name__r.Phone);
    infoMap.put('address', aFinancialCenter.ER_Invoicing_Street__c);
    infoMap.put('postalCode', aFinancialCenter.ER_Invoicing_Zip_Code__c);
    infoMap.put('city', aFinancialCenter.ER_Invoicing_City__c);
    infoMap.put('country', aFinancialCenter.ER_Invoicing_Country__c);
    infoMap.put('refundCountry', aFinancialCenter.ER_Account_Name__r.BillingCountry);
    infoMap.put('firstName', aFinancialCenter.ER_Contact__r.FirstName);
    infoMap.put('lastName', aFinancialCenter.ER_Contact__r.LastName);
    infoMap.put('email', aFinancialCenter.ER_Contact__r.Email);
    infoMap.put('contactPhone', aFinancialCenter.ER_Contact__r.MobilePhone);
    infoMap.put('mobile', aFinancialCenter.ER_Contact__r.MobilePhone);
    infoMap.put('legalName', aFinancialCenter.Name);
    infoMap.put('iban', aFinancialCenter.ER_Bank_Account__r.ER_IBAN__c);
    infoMap.put('bic', aFinancialCenter.ER_Bank_Account__r.ER_BIC__c);
    infoMap.put('invoicingMethod', aFinancialCenter.ER_Preferred_Invoicing_Method__c);
    infoMap.put('ovtCode', aFinancialCenter.ERFI_OVT_Code__c);
    infoMap.put('ovtOperator', aFinancialCenter.ERFI_OVT_Operator__c);
    infoMap.put('enterpriseNb', aFinancialCenter.ER_Account_Name__r.ER_Registration_Number__c);
    return infoMap;
  }

  public static void updateFinancialCenter(
    Boolean updatedContact,
    Boolean updatedMainInfos,
    String companyInfosJSON,
    String financialCenterId
  ) {
    if (String.isBlank(financialCenterId) || (!updatedContact && !updatedMainInfos)) {
      return;
    }

    ER_Financial_Center__c financialCenter = new ER_Financial_Center__c();
    financialCenter.Id = financialCenterId;

    if (!String.isBlank(companyInfosJSON)) {
      Map<String, Object> companyInfos = (Map<String, Object>) JSON.deserializeUntyped(companyInfosJSON);

      if (updatedContact) {
        handleContactUpdate(companyInfos, financialCenter);
      }

      if (updatedMainInfos) {
        handleMainInfosUpdate(companyInfos, financialCenter);
      }

      update financialCenter;
    }
  }

  private static void handleContactUpdate(Map<String, Object> companyInfos, ER_Financial_Center__c financialCenter) {
    String contactFirstName = (String) companyInfos.get('firstName');
    String contactEmail = (String) companyInfos.get('email');
    String contactLastName = (String) companyInfos.get('lastName');

        List<Contact> existingContacts = [SELECT Id, ER_Status__c
                                          FROM Contact
                                          WHERE FirstName = :contactFirstName
                                          AND LastName = :contactLastName
                                          AND Email = :contactEmail
                                          AND AccountId = :financialCenter.ER_Account_Name__c
                                          ORDER BY ER_Status__c DESC];

    if (!existingContacts.isEmpty()) {
      if (existingContacts.get(0).ER_Status__c != Constants.ACTIVE) {
        existingContacts.get(0).ER_Status__c = Constants.ACTIVE;
        update existingContacts.get(0);
      }
      financialCenter.ER_Contact__c = existingContacts.get(0).Id;
    } else {
      createContact(companyInfos, financialCenter);
    }
  }

  private static void handleMainInfosUpdate(Map<String, Object> companyInfos, ER_Financial_Center__c financialCenter) {
    financialCenter.Name = (String) companyInfos.get('legalName');
    financialCenter.ER_Invoicing_Street__c = (String) companyInfos.get('address');
    financialCenter.ER_Invoicing_City__c = (String) companyInfos.get('city');
    financialCenter.ER_Invoicing_Zip_Code__c = (String) companyInfos.get('postalCode');
    financialCenter.ER_Invoicing_Country__c = (String) companyInfos.get('country');
    financialCenter.ER_Preferred_Invoicing_Method__c = (String) companyInfos.get('invoicingMethod');
    financialCenter.ERFI_OVT_Operator__c = (String) companyInfos.get('ovtOperator');
    financialCenter.ERFI_OVT_Code__c = (String) companyInfos.get('ovtCode');
    financialCenter.ER_Invoicing_Country_Code__c = String.valueOf(Utils.getCountryCode((String) companyInfos.get('country'))); //DKB : COUL-4754
  }

  private static void createContact(Map<String, Object> companyInfos, ER_Financial_Center__c financialCenter) {
    Contact aContact = new Contact(
      ER_Status__c = 'Active',
      Salutation = 'Mx',
      FirstName = (String) companyInfos.get('firstName'),
      LastName = (String) companyInfos.get('lastName'),
      AccountId = (String) companyInfos.get('accountId'),
      MobilePhone = (String) companyInfos.get('contactPhone'),
      Email = (String) companyInfos.get('email'),
      MailingStreet = (String) companyInfos.get('address'),
      MailingCity = (String) companyInfos.get('city'),
      MailingPostalCode = (String) companyInfos.get('postalCode'),
      MailingCountry = (String) companyInfos.get('country')
    );

    insert aContact;

    financialCenter.ER_Contact__c = aContact.Id;
  }

  @AuraEnabled
  public static void createFinancialCenter(String companyInfosJSON, String scope) {
    if (String.isBlank(companyInfosJSON)) {
      return;
    }
    Map<String, Object> companyInfos = (Map<String, Object>) JSON.deserializeUntyped(companyInfosJSON);

    System.debug('SLI >> ' + companyInfos);

    Contact relatedContact = getRelatedContact(
      (String) companyInfos.get('enterpriseNb'),
      (String) companyInfos.get('email'),
      (String) companyInfos.get('lastName'),
      (String) companyInfos.get('firstName'),
      (String) companyInfos.get('contactPhone')
    );

    String relatedBankId = getRelatedBankId(
      (String) companyInfos.get('IBAN'),
      (String) companyInfos.get('BIC'),
      (String) companyInfos.get('enterpriseNb'),
      scope
    );

    String newFinancialCenterId = createNewFinancialCenter(
        relatedContact.Id,
        relatedContact.AccountId,
        relatedBankId,
        companyInfos,
        scope
      )
      .Id;

    update new ER_Bank_Account__c(Id = relatedBankId, ER_Financial_Center__c = newFinancialCenterId);
  }

    private static Contact getRelatedContact(String crn,
        String email,
        String lastName,
        String firstName,
        String phone
    )
    {
        List<Contact> existingContact = new List<Contact>();

        if(String.isNotBlank(crn)){
            existingContact = [
                SELECT Id, AccountId, ER_Status__c
                FROM Contact
                WHERE Email = :email
                AND LastName = :lastName
                AND FirstName = :firstName
                AND AccountId IN
                    (
                        SELECT Id
                        FROM Account
                        WHERE ER_Registration_Number__c = : crn)
                ORDER BY LastModifiedDate DESC
            ];
        }

        if(!existingContact.isEmpty())
        {
            if(existingContact.get(0).ER_Status__c != Constants.ACTIVE)
            {
                existingContact.get(0).ER_Status__c = Constants.ACTIVE;
                update existingContact.get(0);
            }
            return existingContact.get(0);
        }
        else
        {
            return createContact(
                crn,
                email,
                lastName,
                firstName,
                phone
            );
        }
    }

  private static Contact createContact(String crn, String email, String lastName, String firstName, String phone) {
    Account currentAccount = [
      SELECT Id, BillingCity, BillingState, BillingStreet, BillingCountry, BillingPostalCode
      FROM Account
      WHERE ER_Registration_Number__c = :crn
      LIMIT 1
    ];

    Contact aContact = new Contact(
      ER_Status__c = 'Active',
      Salutation = 'Mx',
      FirstName = firstName,
      LastName = lastName,
      AccountId = currentAccount.Id,
      Phone = phone,
      MobilePhone = phone,
      Email = email,
      MailingStreet = currentAccount.BillingStreet,
      MailingCity = currentAccount.BillingCity,
      MailingPostalCode = currentAccount.BillingPostalCode,
      MailingCountry = currentAccount.BillingCountry,
      MailingState = currentAccount.BillingState
    );

    insert aContact;

    return aContact;
  }

  private static ER_Financial_Center__c createNewFinancialCenter(
    Id contactId,
    Id accountId,
    Id bankId,
    Map<String, Object> companyInfos,
    String scope
  ) {
    ER_Financial_Center__c aFinancialCenter = new ER_Financial_Center__c(
      Name = (String) companyInfos.get('legalName'),
      ER_Invoicing_Street__c = (String) companyInfos.get('address'),
      ER_Invoicing_City__c = (String) companyInfos.get('city'),
      ER_Invoicing_Zip_Code__c = (String) companyInfos.get('postalCode'),
      ER_Invoicing_Country__c = (String) companyInfos.get('country'),
      ER_Invoicing_Country_Code__c = String.valueOf(Utils.getCountryCode((String) companyInfos.get('country'))), //DKB : COUL-4754
      ER_Preferred_Invoicing_Method__c = (String) companyInfos.get('invoicingMethod'),
      ER_BUPicklist__c = companyInfos.get('bu')?.toString()?.toUpperCase(),
      ER_Account_Name__c = accountId,
      ER_Contact__c = contactId,
      ER_Bank_Account__c = bankId,
      ER_Invoicing_Site__c = true,
      ER_Type__c = scope == 'M' ? Constants.MERCHANT : Constants.CLIENT,
      ERFI_OVT_Operator__c = (String) companyInfos.get('ovtOperator'),
      ERFI_OVT_Code__c = (String) companyInfos.get('ovtCode')
    );

    insert aFinancialCenter;

    return aFinancialCenter;
  }

  private static String getRelatedBankId(String iban, String bic, String crn, String scope) {
    String existingBankAccountId;

    if (scope == 'M') {
      existingBankAccountId = [
        SELECT Id
        FROM ER_Bank_Account__c
        WHERE
          ER_IBAN__c = :iban
          AND ER_BIC__c = :bic
          AND ER_Financial_Center__c IN (
            SELECT Id
            FROM ER_Financial_Center__c
            WHERE ER_Account_Name__r.ER_Registration_Number__c = :crn
          )
        ORDER BY LastModifiedDate DESC
        LIMIT 1
      ]
      ?.Id;
    } else if (scope == 'C') {
      existingBankAccountId = [
        SELECT Id
        FROM ER_Bank_Account__c
        WHERE
          ER_IBAN__c = :iban
          AND ER_BIC__c = :bic
          AND ER_Financial_Center__c = NULL
          AND Id NOT IN (SELECT ER_Bank_Account__c FROM ER_Solution_Line_Item__c)
        ORDER BY LastModifiedDate DESC
        LIMIT 1
      ]
      ?.Id;
    }

        if(existingBankAccountId != null)
        {
            update new ER_Bank_Account__c(Id = existingBankAccountId, ER_SEPA_active__c = false);
            return existingBankAccountId;
        }
        else
        {
            return createBankAccount(
                iban,
                bic
            ).Id;
        }
    }

    private static ER_Bank_Account__c createBankAccount(
        String iban,
        String bic
    )
    {
        ER_Bank_Account__c aBankAccount = new ER_Bank_Account__c(
            ER_BIC__c = bic,
            ER_IBAN__c = iban,
            Name = iban,
            ER_Bank_Account_Status__c = Constants.OPEN
        );

    insert aBankAccount;

    return aBankAccount;
  }

  public static String getMainContactInfos(String crn) {
    List<Account> accounts = [
      SELECT Id, HU_HQ_Contact__r.FirstName, HU_HQ_Contact__r.LastName, HU_HQ_Contact__r.Email, HU_HQ_Contact__r.Phone, HU_HQ_Contact__r.MobilePhone
      FROM Account
      WHERE ER_Registration_Number__c = :crn
    ];

    Map<String, String> contactInfos = new Map<String, String>();

    if (!accounts.isEmpty()) {
      contactInfos.put('FirstName', accounts.get(0).HU_HQ_Contact__r.FirstName);
      contactInfos.put('LastName', accounts.get(0).HU_HQ_Contact__r.LastName);
      contactInfos.put('Email', accounts.get(0).HU_HQ_Contact__r.Email);
      contactInfos.put('Phone', accounts.get(0).HU_HQ_Contact__r.MobilePhone);
    }

    return JSON.serialize(contactInfos);
  }

  public static void updateRelatedAccounts(List<Account> accounts) {
    if (!accounts.isEmpty())
      Database.update(accounts);
  }

  public static List<Map<String, String>> getFinCentersInfosByCRN(String crn, String scope) {
    if (String.isNotBlank(crn)) {
      List<Account> accounts = [SELECT Id FROM Account WHERE ER_Registration_Number__c = :crn];

      if (!accounts.isEmpty())
        return getFinCentersInfos(accounts[0].Id, scope);

      return null;
    }

    return null;
  }

  public static List<Map<String, String>> getFinCentersInfos(String accountId, String scope) {
    List<Map<String, String>> resultMapList = new List<Map<String, String>>();

    String fcScope = (scope.toUpperCase() == 'C' ? Constants.CLIENT : Constants.MERCHANT);
    System.debug('>>>>> ALK - fcScope : ' + fcScope);

    Map<Id, Contact> cntMap = new Map<Id, Contact>(
      [
        SELECT Id, Salutation, FirstName, LastName, Email, Phone, MobilePhone, Fax, ER_Language__c, ER_Role__c
        FROM Contact
        WHERE AccountId = :accountId
      ]
    );

    Map<Id, ER_Bank_Account__c> bankAccMap = new Map<Id, ER_Bank_Account__c>(
      [
        SELECT ER_Financial_Center__c, ER_IBAN__c, ER_BIC__c, ER_Bank_Name__c
        FROM ER_Bank_Account__c
        WHERE ER_Financial_Center__r.ER_Account_Name__c = :accountId
      ]
    );

    for (ER_Financial_Center__c finCenter : [
      SELECT
        Id,
        Name,
        ER_Contact__c,
        ER_Bank_Account__c,
        ER_Street__c,
        ER_City__c,
        ER_Zip_Code__c,
        ER_Country__c,
        ER_Account_Name__c,
        ER_Country_Code__c,
        ER_Invoicing_Street__c,
        ER_Invoicing_Zip_Code__c,
        ER_Invoicing_City__c
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c = :accountId AND ER_Type__c = :fcScope
    ]) {
      System.debug('>>>>> ALK - finCenter : ' + finCenter);
      Map<String, String> curFinCenter = new Map<String, String>();
      String curIban = anonymizeString(bankAccMap.get(finCenter.ER_Bank_Account__c)?.ER_IBAN__c, 4, 4);
      Contact curContact = cntMap.get(finCenter.ER_Contact__c);
      String curContactName = curContact == null ? ' ' : curContact.FirstName + ' ' + curContact.LastName;

      curFinCenter.put('name', finCenter.Name);
      curFinCenter.put('contact', curContactName);
      curFinCenter.put(
        'fullAddress',
        finCenter.ER_Street__c + ', ' + finCenter.ER_Zip_Code__c + ' ' + finCenter.ER_City__c
      );
      curFinCenter.put(
        'invoicingAddress',
        finCenter.ER_Invoicing_Street__c +
          ', ' +
          finCenter.ER_Invoicing_Zip_Code__c +
          ' ' +
          finCenter.ER_Invoicing_City__c
      );
      curFinCenter.put('bic', bankAccMap.get(finCenter.ER_Bank_Account__c)?.ER_BIC__c);
      curFinCenter.put('iban', String.isBlank(curIban) ? ' ' : curIban); // Set blankspace if no value in order to display the column in the datatable
      curFinCenter.put('bankName', bankAccMap.get(finCenter.ER_Bank_Account__c)?.ER_Bank_Name__c);
      curFinCenter.put('refundContactId', cntMap.get(finCenter.ER_Contact__c)?.Id);
      curFinCenter.put('refundSalutation', cntMap.get(finCenter.ER_Contact__c)?.Salutation);
      curFinCenter.put('refundFirstName', cntMap.get(finCenter.ER_Contact__c)?.FirstName);
      curFinCenter.put('refundLastName', cntMap.get(finCenter.ER_Contact__c)?.LastName);
      curFinCenter.put('refundLang', cntMap.get(finCenter.ER_Contact__c)?.ER_Language__c);
      curFinCenter.put('refundContactPhone', cntMap.get(finCenter.ER_Contact__c)?.Phone);
      curFinCenter.put('refundMobile', cntMap.get(finCenter.ER_Contact__c)?.MobilePhone);
      curFinCenter.put('refundRole', cntMap.get(finCenter.ER_Contact__c)?.ER_Role__c);
      curFinCenter.put('refundEmail', cntMap.get(finCenter.ER_Contact__c)?.Email);
      curFinCenter.put('refundFax', cntMap.get(finCenter.ER_Contact__c)?.Fax);
      curFinCenter.put('refundAddress', finCenter.ER_Street__c);
      curFinCenter.put('refundPostalCode', finCenter.ER_Zip_Code__c);
      curFinCenter.put('refundCity', finCenter.ER_City__c);
      curFinCenter.put('refundCountry', finCenter.ER_Country__c);
      curFinCenter.put('finCenterSFId', finCenter.Id); // AAM-18.11.21: PBI13440
      curFinCenter.put('finCenterAccountSFId', finCenter.ER_Account_Name__c); // AAM-18.11.21: PBI13440
      curFinCenter.put('bankAccountSFId', bankAccMap.get(finCenter.ER_Bank_Account__c)?.Id); // AAM-18.11.21: PBI13440
      curFinCenter.put('countryCode', finCenter.ER_Country_Code__c);
      curFinCenter.put('finCenterId', finCenter.Name.substringAfterLast('(').substringBefore(')'));

      resultMapList.add(curFinCenter);
    }

    return resultMapList;
  }

  private static String anonymizeString(String curStr, Integer nbCarStart, Integer nbCarEnd) {
    String result;
    if (!String.isBlank(curStr)) {
      Integer nbStars = curStr.length() - nbCarStart - nbCarEnd;
      result =
        curStr.substring(0, nbCarStart) +
        '*'.repeat(nbStars) +
        curStr.substring(curStr.length() - nbCarEnd, curStr.length());
    }
    return result;
  }

  public static void createContactRole(List<ER_Contact_Role__c> crToInsert) {
    insert crToInsert;
  }

  @AuraEnabled
  public static List<Map<String, Object>> getFcStoresInfos(String fcId, String locale) {
    if (fcId == null) {
      return null;
    }

    System.debug('>>> getStoresInfos: fcId = ' + fcId);
    System.debug('>>> getStoresInfos: locale = ' + locale);

    List<Map<String, Object>> resultMapList = new List<Map<String, Object>>();
    List<ER_Store__c> storeList = [
      SELECT
        Id,
        Name,
        ER_Street__c,
        ER_Zip_Code__c,
        ER_City__c,
        ER_Facebook__c,
        ER_Website_URL__c,
        ERBE_Sub_Segment__c,
        ER_Financial_Center__c,
        ER_Financial_Center__r.Name,
        ER_Franchise_type__c,
        ER_Merchant__c,
        ER_Country__c,
        ER_Contact__c,
        ER_Country_Code__c,
        ER_Status__c,
        ER_Start_date__c,
        ER_E_Shop__c,
        ER_Contact__r.Salutation,
        ER_Contact__r.FirstName,
        ER_Contact__r.LastName,
        ER_Contact__r.Email,
        ER_Contact__r.ER_Language__c,
        ER_Store_Phone_Number__c,
        ER_Email__c
      FROM ER_Store__c
      WHERE ER_Financial_Center__c = :fcId
    ];

    List<ER_Acceptor__c> accList = [
      SELECT
        ER_Store__c,
        ER_Acceptor_Provider__c,
        ER_Acceptor_Model__c,
        ER_TID_Authorization__c,
        ER_Cash_Register_Provider__c,
        ER_IS_Acceptor_Linked_To_Cash_Register__c,
        ER_MID_Authorization__c,
        ER_Acceptor_Scheme__c,
        ER_Acceptor_Type__c,
        ER_SubMID_Authorization__c
      FROM ER_Acceptor__c
      WHERE ER_Store__r.ER_Financial_Center__c = :fcId
    ];

    List<ER_StoreCategory__c> catList = [
      SELECT Store__c, Category__c, Main_Category__c
      FROM ER_StoreCategory__c
      WHERE Store__r.ER_Financial_Center__c = :fcId
    ];

    Map<String, String> catTransMap = new Map<String, String>();
    for (ER_Translation__c tra : [
      SELECT Dependent_Value__c, Text__c
      FROM ER_Translation__c
      WHERE Field_API_Name__c = 'ER_StoreCategory__c' AND Language__c = :locale
    ])
      catTransMap.put(tra.Dependent_Value__c, tra.Text__c);

    Integer i = 1;

    System.debug('>>> getStoresInfos: storeList.size = ' + storeList.size());

    for (ER_Store__c st : storeList) {
      Map<String, Object> curStore = new Map<String, Object>();

      curStore.put('name', st.Name);
      curStore.put('storeStatus', st.ER_Status__c);
      curStore.put(
        'storeContactFullName',
        String.valueOf(st.ER_Contact__r.FirstName) + ' ' + String.valueOf(st.ER_Contact__r.LastName)
      );
      curStore.put('fullAddress', st.ER_Street__c + ', ' + st.ER_Zip_Code__c + ' ' + st.ER_City__c);
      curStore.put('website', st.ER_Website_URL__c);
      curStore.put('websiteDisplay', String.isBlank(st.ER_Website_URL__c) ? ' ' : st.ER_Website_URL__c); // Set blankspace if no website in order to display the column in the datatable
      curStore.put('finCenterId', st.ER_Financial_Center__r.Name.substringAfterLast('(').substringBefore(')'));
      curStore.put('address', st.ER_Street__c);
      curStore.put('postalCode', st.ER_Zip_Code__c);
      curStore.put('city', st.ER_City__c);
      curStore.put('country', st.ER_Country__c);
      curStore.put('facebook', st.ER_Facebook__c);
      curStore.put('sector', st.ERBE_Sub_Segment__c);
      curStore.put('isFranchisee', st.ER_Franchise_type__c == 'Franchise' ? 'Yes' : 'No');
      curStore.put('storeId', String.valueOf(i));
      curStore.put('rowIndex', String.valueOf(i - 1));
      curStore.put('storeSFId', st.Id);
      curStore.put('merchantAccSFId', st.ER_Merchant__c);
      curStore.put('finCenterSFId', st.ER_Financial_Center__c);
      curStore.put('finCenterName', st.ER_Financial_Center__r.Name);
      curStore.put('storeContactId', st.ER_Contact__c);
      curStore.put('countryCode', st.ER_Country_Code__c);
      curStore.put('storeStartDate', st.ER_Start_date__c);
      curStore.put('storeContactSalutation', String.valueOf(st.ER_Contact__r.Salutation));
      curStore.put('storeContactFirstName', String.valueOf(st.ER_Contact__r.FirstName));
      curStore.put('storeContactLastName', String.valueOf(st.ER_Contact__r.LastName));
      curStore.put('storeContactEmail', String.valueOf(st.ER_Contact__r.Email));
      curStore.put('storeContactLanguage', String.valueOf(st.ER_Contact__r.ER_Language__c));
      curStore.put('storePhone', st.ER_Store_Phone_Number__c);
      curStore.put('storeEmail', st.ER_Email__c);
      curStore.put('noDelete', 'true');

      // Get terminals for current store
      List<Map<String, String>> accStoreList = new List<Map<String, String>>();
      Integer terminalId = 1;
      for (ER_Acceptor__c acc : accList) {
        if (acc.ER_Store__c == st.Id) {
          if (acc.ER_Acceptor_Type__c == 'Payment Gate') {
            curStore.put('hasOnlineStore', 'true');
            if (acc.ER_Acceptor_Scheme__c == 'MasterCard') {
              curStore.put('isOnlineStoreMastercard', 'true');
              curStore.put('mid', acc.ER_MID_Authorization__c);
              curStore.put('subMid', acc.ER_SubMID_Authorization__c);
            }
          } else if (acc.ER_Acceptor_Type__c == 'Aggregator') {
            curStore.put('hasAgregator', 'true');
          } else if (
            acc.ER_Acceptor_Type__c == 'POS' &&
            acc.ER_Acceptor_Scheme__c == 'MasterCard' &&
            !String.isBlank(acc.ER_MID_Authorization__c)
          ) {
            curStore.put('hasPhysicalAcceptor', 'true');
            curStore.put('isPhysicalAcceptorMastercard', 'true');
            curStore.put('mid2', acc.ER_MID_Authorization__c);
            curStore.put('subMid2', acc.ER_SubMID_Authorization__c);
          } else if (acc.ER_Acceptor_Type__c == 'POS' && !String.isBlank(acc.ER_Acceptor_Provider__c)) {
            curStore.put('hasPhysicalAcceptor', 'true');

            Map<String, String> curAcceptor = new Map<String, String>();

            curAcceptor.put('terminalSFId', acc.Id);
            curAcceptor.put('terminalProvider', acc.ER_Acceptor_Provider__c);
            curAcceptor.put('terminalModel', acc.ER_Acceptor_Model__c);
            curAcceptor.put('terminalModelDisplayValue', acc.ER_Acceptor_Model__c);
            curAcceptor.put('tid', anonymizeString(acc.ER_TID_Authorization__c, 2, 2));
            curAcceptor.put('isLinkedToCashReg', acc.ER_IS_Acceptor_Linked_To_Cash_Register__c);
            curAcceptor.put('isLinkedToCashRegDisplayValue', acc.ER_IS_Acceptor_Linked_To_Cash_Register__c);
            curAcceptor.put(
              'cashRegisterProvider',
              String.isBlank(acc.ER_Cash_Register_Provider__c) ? ' ' : acc.ER_Cash_Register_Provider__c
            );
            curAcceptor.put('storeId', String.valueOf(i));
            curAcceptor.put('isReadOnly', 'true');
            curAcceptor.put('terminalId', String.valueOf(terminalId));

            if (
              acc.ER_Acceptor_Type__c == 'POS' &&
              acc.ER_Acceptor_Scheme__c == 'C-TAP' &&
              !String.isBlank(acc.ER_MID_Authorization__c)
            )
              curStore.put('midCtap', acc.ER_MID_Authorization__c);

            accStoreList.add(curAcceptor);
            terminalId++;
          }
        }
      }

      if (accStoreList.size() > 0)
        curStore.put('hasTerminal', 'true');

      curStore.put('terminalsList', accStoreList);

      // Get current store categories
      List<Map<String, String>> catStoreList = new List<Map<String, String>>();
      for (ER_StoreCategory__c stc : catList) {
        if (stc.Store__c == st.Id) {
          Map<String, String> curCategory = new Map<String, String>();

          curCategory.put('id', stc.Category__c);
          curCategory.put('name', catTransMap.get(stc.Category__c));
          curCategory.put('isMain', String.valueOf(stc.Main_Category__c));
          curCategory.put('isChecked', 'true');

          catStoreList.add(curCategory);
        }
      }

      curStore.put('chosenCategories', catStoreList);

      resultMapList.add(curStore);
      i++;
    }

    return resultMapList;
  }
}