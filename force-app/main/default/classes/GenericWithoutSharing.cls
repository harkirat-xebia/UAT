/**
 * @author : ALK
 * @date : 29/03/2021
 * @desc : GenericWithoutSharing - This class is used to call all methods should be executed in a without sharing context
 * @see GenericWithoutSharing
 */

 public without sharing class GenericWithoutSharing {
  private static EncryptionSettings__c encryptionSettings { // SLI => 3443
    get {
      if (encryptionSettings == null) {
        return EncryptionSettings__c.getInstance();
      }
      return encryptionSettings;
    }
    set;
  }

  public static Map<String, String> solutionPricebookMap; // Needed to map right solution to right opp
  public static Map<String, String> pbOppMap; // Needed to map right solution to right opp

  @AuraEnabled
  public static Map<String, String> getCompanyInfos(String crn) {
    if (String.isNotBlank(crn)) {
      List<Account> existingAccount = [
        SELECT
          Id,
          Name,
          Phone,
          ER_Legal_Form__c,
          ER_Legal_Name__c,
          BillingCity,
          BillingPostalCode,
          ER_Other_Fiscal_ID__c,
          BillingStreet,
          BillingCountry,
          ER_Not_subject_to_VAT__c,
          ER_VAT_Number__c,
          ER_Registration_Number__c,
          ER_Country_Code__c,
          HU_HQ_Contact__r.Id,
          HU_HQ_Contact__r.Salutation,
          HU_HQ_Contact__r.FirstName,
          HU_HQ_Contact__r.LastName,
          HU_HQ_Contact__r.Email,
          HU_HQ_Contact__r.Phone,
          HU_HQ_Contact__r.MobilePhone,
          HU_HQ_Contact__r.Fax,
          HU_HQ_Contact__r.ER_Language__c,
          HU_HQ_Contact__r.ER_Role__c,
          ER_External_Reference__c,
          NumberOfEmployees,
          ER_Status__c
        FROM Account
        WHERE ER_Registration_Number__c = :crn
        ORDER BY LastModifiedDate DESC
      ];

      if (!existingAccount.isEmpty())
        return getCompanyInfoMap(existingAccount[0]);
    }

    return null;
  }

  private static Map<String, String> getCompanyInfoMap(Account anAccount) {
    Map<String, String> infoMap = new Map<String, String>();
    infoMap.put('accountId', anAccount.Id);
    infoMap.put('company', anAccount.Name);
    infoMap.put('phone', anAccount.Phone);
    infoMap.put('legalName', anAccount.ER_Legal_Name__c);
    infoMap.put('address', anAccount.BillingStreet);
    infoMap.put('postalCode', anAccount.BillingPostalCode);
    infoMap.put('city', anAccount.BillingCity);
    infoMap.put('country', anAccount.BillingCountry);
    infoMap.put('refundCountry', anAccount.BillingCountry);
    infoMap.put('hasVATCode', String.isBlank(anAccount.ER_VAT_Number__c) ? null : 'true');
    infoMap.put('enterpriseVATCode', anAccount.ER_VAT_Number__c);
    infoMap.put('numberEmployees', String.valueOf(anAccount.NumberOfEmployees));
    infoMap.put('contactId', anAccount.HU_HQ_Contact__c);
    infoMap.put('salutation', anAccount.HU_HQ_Contact__r.Salutation);
    infoMap.put('firstName', anAccount.HU_HQ_Contact__r.FirstName);
    infoMap.put('lastName', anAccount.HU_HQ_Contact__r.LastName);
    infoMap.put('email', anAccount.HU_HQ_Contact__r.Email);
    infoMap.put('contactPhone', anAccount.HU_HQ_Contact__r.Phone);
    infoMap.put('mobile', anAccount.HU_HQ_Contact__r.MobilePhone);
    infoMap.put('fax', anAccount.HU_HQ_Contact__r.Fax);
    infoMap.put('lang', anAccount.HU_HQ_Contact__r.ER_Language__c);
    return infoMap;
  }

  @AuraEnabled
  public static Map<String, String> getFinancialCenterInfos(String financialCenterId) {
    return ManageFinancialCenter.getFinancialCenterInfos(financialCenterId);
  }

  @AuraEnabled
  public static Map<String, String> getEnterpriseInfos(
    String enterpriseNb,
    String country,
    String lang,
    String uniqueKeyId,
    String userEmail
  ) {
    return getEnterpriseInfos2(enterpriseNb, country, lang, uniqueKeyId, userEmail, null);
  }

  @AuraEnabled
  public static Map<String, String> getEnterpriseInfos2(
    String enterpriseNb,
    String country,
    String lang,
    String uniqueKeyId,
    String userEmail,
    String solutionCode
  ) {
    Map<String, String> resultMap = new Map<String, String>();

    // Web offer use case (get account infos using uniqueKeyId)
    String accountId, solutionId, promoCode, contractId;
    String businessUnit = Utils.getBUCode(country);
    String contractStatus;
    String oppMerchantRecType = Utils.getRecordTypeIdByDeveloperName(
      Opportunity.SObjectType,
      Constants.OPPORTUNITY_MERCHANT_RT
    );
    String ldMerchantRecType = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_MERCHANT_RT);

    List<Account> existingAccountList = new List<Account>();
    List<Quote> qtList;
    if (!String.isBlank(uniqueKeyId)) {
      System.debug('>>> getEnterpriseInfos -- uniqueKeyId: ' + uniqueKeyId);
      // Case web offer and also Onboarding
      qtList = [
        SELECT
          AccountId,
          ER_Main_Solution__c,
          Opportunity.ER_Promo_Code2__r.ER_Promo_Code__c,
          Account.Name,
          ContractId,
          Contract.ContractNumber,
          ER_Main_Solution__r.Name,
          ER_Main_Solution__r.ProductCode
        FROM Quote
        WHERE
          (ER_Web_Offer_Token__c = :uniqueKeyId
          AND ER_is_quote_expired__c = FALSE)
          OR Account.ER_External_Reference__c = :uniqueKeyId
      ];
      if (!qtList.isEmpty()) {
        accountId = qtList[0].AccountId;
        contractId = qtList[0].ContractId;
        solutionId = qtList[0].ER_Main_Solution__c;
        promoCode = qtList[0].Opportunity.ER_Promo_Code2__r.ER_Promo_Code__c;

        if (String.isBlank(solutionCode))
          solutionCode = qtList[0].ER_Main_Solution__r.ProductCode;

        existingAccountList = [
          SELECT
            Id,
            Name,
            Phone,
            ER_Legal_Form__c,
            ER_Legal_Name__c,
            BillingCity,
            BillingPostalCode,
            ER_Other_Fiscal_ID__c,
            BillingStreet,
            BillingCountry,
            ER_Not_subject_to_VAT__c,
            ER_VAT_Number__c,
            ER_Registration_Number__c,
            ER_Country_Code__c,
            HU_HQ_Contact__c,
            HU_HQ_Contact__r.Salutation,
            HU_HQ_Contact__r.FirstName,
            HU_HQ_Contact__r.LastName,
            HU_HQ_Contact__r.Email,
            HU_HQ_Contact__r.Phone,
            HU_HQ_Contact__r.MobilePhone,
            HU_HQ_Contact__r.Fax,
            HU_HQ_Contact__r.ER_Language__c,
            HU_HQ_Contact__r.ER_Role__c,
            ER_External_Reference__c,
            NumberOfEmployees,
            ER_Status__c
          FROM Account
          WHERE Id = :accountId
          ORDER BY LastModifiedDate DESC
        ];
        System.debug('>>> getEnterpriseInfos -- accountId: ' + accountId);

        // Check if existing active contract for the same solution
        List<OpportunityLineItem> ctList = [
          SELECT Id, Opportunity.Contract.Status
          FROM OpportunityLineItem
          WHERE
            Opportunity.AccountId = :accountId
            AND Product2.ER_Solution__c = :solutionId
            AND Opportunity.ContractId = :contractId
            AND Opportunity.Contract.Status IN ('Activated', 'Draft')
        ];
        if (!ctList.isEmpty()) {
          contractStatus = ctList[0].Opportunity.Contract.Status;
          if (!String.isBlank(contractStatus))
            resultMap.put(contractStatus, 'true');
          // return new Map<String,String>{contractStatus => 'true', 'accountId' => accountId};
          // TODO add ext ref in account to build msg for onboarding
        }
      } else {
        return null;
      }
    } else if (!String.isBlank(enterpriseNb)) {
      // Check if existing account, if yes then add parameter in the map to edit account in "read-only" (only few informations will be editable)
      // ER_Enterprise_Number__c is not a unique field, so we bring the last one modified in case of several account returned
      existingAccountList = [
        SELECT
          Id,
          Name,
          Phone,
          ER_Legal_Form__c,
          ER_Legal_Name__c,
          BillingCity,
          BillingPostalCode,
          ER_Other_Fiscal_ID__c,
          BillingStreet,
          BillingCountry,
          ER_Not_subject_to_VAT__c,
          ER_VAT_Number__c,
          ER_Registration_Number__c,
          ER_Country_Code__c,
          HU_HQ_Contact__c,
          HU_HQ_Contact__r.Salutation,
          HU_HQ_Contact__r.FirstName,
          HU_HQ_Contact__r.LastName,
          HU_HQ_Contact__r.Email,
          HU_HQ_Contact__r.Phone,
          HU_HQ_Contact__r.MobilePhone,
          HU_HQ_Contact__r.Fax,
          HU_HQ_Contact__r.ER_Language__c,
          HU_HQ_Contact__r.ER_Role__c,
          ER_External_Reference__c,
          NumberOfEmployees,
          ER_Status__c,
          (SELECT Id, Email, ER_Onboarding_Contract__c FROM Contacts)
        FROM Account
        WHERE
          (ER_Registration_Number__c = :enterpriseNb
          OR ER_Other_Fiscal_ID__c = :enterpriseNb)
          AND ER_BUPicklist__c = :businessUnit
        ORDER BY LastModifiedDate DESC
      ];
      if (!existingAccountList.isEmpty())
        accountId = existingAccountList[0].Id;
    }

    System.debug('>>> getEnterpriseInfos -- existingAccountList size: ' + existingAccountList.size());

    //TODO to be reviewed, as no need to query leads if existing accounts
    // String extRef = country + enterpriseNb;
    List<Lead> existingLeadList = new List<Lead>();

    if (String.isBlank(uniqueKeyId) && existingAccountList.isEmpty()) {
      existingLeadList = [
        SELECT
          Id,
          Company,
          Phone,
          ER_Legal_Form__c,
          ER_Legal_Name__c,
          ER_Legal_Street__c,
          ER_Legal_Zip_Code__c,
          ER_Legal_City__c,
          ER_Legal_Country__c,
          ER_VAT_Number__c,
          Salutation,
          FirstName,
          LastName,
          ER_Language__c,
          MobilePhone,
          ER_Role__c,
          Email,
          Fax,
          NumberOfEmployees,
          ERBE_Initial_Product_Of_Interest__c,
          ERBE_Initial_Product_Of_Interest__r.ProductCode
        FROM Lead
        WHERE
          (ER_Registration_Number__c = :enterpriseNb
          OR ER_Other_Fiscal_ID__c = :enterpriseNb)
          AND ER_BUPicklist__c = :businessUnit
          AND RecordTypeId = :ldMerchantRecType
        ORDER BY LastModifiedDate DESC
      ];
    }

    if (existingAccountList.isEmpty() && existingLeadList.isEmpty() && !String.isBlank(enterpriseNb)) {
      if (country == 'BE' || country == 'LU') {
        //TODO handle country parameter, to be ready for future countries?
        System.debug('>>> getEnterpriseInfos -- new company. enterpriseNb: ' + enterpriseNb);
        String locale = 'FR'.equals(lang) ? 'fr_BE' : 'nl_BE';
        Map<String, String> belfirstInfos = new Map<String, String>();

        if (!Test.isRunningTest()) {
          WSBE01_Belfirst belfirstWebservice = new WSBE01_Belfirst();
          String belFirstID;
          if (enterpriseNb.isNumeric())
            belFirstID = 'BE' + enterpriseNb; // Case Belgian Company number
          else
            belFirstID = 'LUL' + enterpriseNb; // Case Company number from Luxembourg

          belfirstInfos = belfirstWebservice.getInfos(belFirstID, country == 'BE' ? 'BVDID' : 'RCSID', locale);
          belfirstWebservice.closeConnection();
        } else {
          belfirstInfos = TestDataFactory.getBelfirstInfosTestDatas();
        }

        resultMap.put('isReadOnly', 'false');
        resultMap.put('legalName', belfirstInfos.get('NAME'));
        resultMap.put('phone', belfirstInfos.get('PHONE'));
        // resultMap.put('legalForm', belfirstInfos.get('TYPE'));
        resultMap.put('company', '');
        resultMap.put('address', belfirstInfos.get('ADDRESS'));
        resultMap.put('postalCode', belfirstInfos.get('POSTCODE'));
        resultMap.put('city', belfirstInfos.get('TOWN'));
        resultMap.put('country', belfirstInfos.get('COUNTRY'));
        resultMap.put('countryCode', belfirstInfos.get('BVDID').substring(0, 2));
        if (!String.isBlank(belfirstInfos.get('LVAT')))
          resultMap.put('enterpriseVATCode', belfirstInfos.get('LVAT'));
        // resultMap.put('solution', solution);
        System.debug('>>> getEnterpriseInfos -- COUNTRY: ' + belfirstInfos.get('COUNTRY'));
      }
    } else {
      if (!existingLeadList.isEmpty() && (country == 'BE' || country == 'LU')) {
        for (Lead ld : existingLeadList) {
          if (
            String.isBlank(ld.ERBE_Initial_Product_Of_Interest__c) ||
            ld.ERBE_Initial_Product_Of_Interest__r.ProductCode != solutionCode ||
            ld.Email != userEmail
          )
            return new Map<String, String>{ 'ongoingProcess' => 'true' };
        }
      }
      if (!existingAccountList.isEmpty()) {
        System.debug('>>> getEnterpriseInfos -- Existing company - Id: ' + existingAccountList[0].Id);
        String isReadOnly = String.isBlank(uniqueKeyId) ? 'true' : 'false';
        String countryCode = existingAccountList[0].ER_Country_Code__c;
        String regNb = existingAccountList[0].ER_Registration_Number__c;
        String fiscalId = existingAccountList[0].ER_Other_Fiscal_ID__c;
        if (String.isBlank(accountId))
          accountId = existingAccountList[0].Id;
        List<Lead> leadList = [SELECT id FROM Lead WHERE ConvertedAccountId = :existingAccountList[0].Id];
        String leadId = '';
        if (!leadList.isEmpty() && String.isBlank(uniqueKeyId))
          leadId = leadList[0].Id; // Do not set leadId in Weboffer context

        //
        // List<OpportunityLineItem> ctList = [ SELECT Id, Opportunity.Contract.Status FROM OpportunityLineItem WHERE Opportunity.AccountId = :accountId AND Product2.ER_Solution__c = :solutionId AND Opportunity.Contract.Status IN ('Activated','Draft') ];
        // , Opportunity.Contract.ER_Main_Solution__r.Name
        // , Opportunity.Contract.ER_Main_Solution__r.ProductCode

        List<OpportunityLineItem> ctList;
        ctList = [
          SELECT
            Id,
            Opportunity.ContractId,
            Opportunity.Contract.ContractNumber,
            Opportunity.Contract.Status,
            Product2.ER_Solution__r.Name,
            Product2.ER_Solution__r.ProductCode,
            Opportunity.Contract.ER_QuoteId__r.ER_Main_Solution__r.ProductCode,
            Opportunity.Contract.ER_QuoteId__r.Status,
            Opportunity.Contract.ER_QuoteId__r.ER_Web_Offer_URL__c
          FROM OpportunityLineItem
          WHERE Opportunity.AccountId = :accountId AND Opportunity.RecordTypeId = :oppMerchantRecType
          ORDER BY Opportunity.Contract.Status
        ];
        System.debug('>>> getEnterpriseInfos -- solutionId: ' + solutionId);
        System.debug('>>> getEnterpriseInfos -- ctList size: ' + ctList.size());

        if ((country == 'BE' || country == 'LU') && String.isBlank(uniqueKeyId)) {
          if (ctList.isEmpty()) {
            // Check contracts uploaded by data mig (ie without opportunity)
            for (Contract ctr : [
              SELECT Id, Status, ER_Solutions__c
              FROM Contract
              WHERE AccountId = :accountId AND ER_OpportunityId__c = NULL
            ]) {
              if (ctr.Status == 'Activated')
                return new Map<String, String>{ 'ongoingProcess' => 'true' };
            }

            existingAccountList = [
              SELECT
                Id,
                Name,
                Phone,
                ER_Legal_Form__c,
                ER_Legal_Name__c,
                BillingCity,
                BillingPostalCode,
                ER_Other_Fiscal_ID__c,
                BillingStreet,
                BillingCountry,
                ER_Not_subject_to_VAT__c,
                ER_VAT_Number__c,
                ER_Registration_Number__c,
                ER_Country_Code__c,
                HU_HQ_Contact__c,
                HU_HQ_Contact__r.Salutation,
                HU_HQ_Contact__r.FirstName,
                HU_HQ_Contact__r.LastName,
                HU_HQ_Contact__r.Email,
                HU_HQ_Contact__r.Phone,
                HU_HQ_Contact__r.MobilePhone,
                HU_HQ_Contact__r.Fax,
                HU_HQ_Contact__r.ER_Language__c,
                HU_HQ_Contact__r.ER_Role__c,
                ER_External_Reference__c,
                NumberOfEmployees
              FROM Account
              WHERE Id = :accountId
              ORDER BY LastModifiedDate DESC
            ];
            System.debug('>>> getEnterpriseInfos -- accountId: ' + accountId);
          } else {
            System.debug('>>> AAMgetEnterpriseInfos -- solutionCode: ' + solutionCode);
            Boolean hasOngoingProcess = false;
            Boolean isWebOffer = false;
            for (OpportunityLineItem oli : ctList) {
              System.debug(
                '>>> AAMgetEnterpriseInfos -- oli.Product2.ER_Solution__r.ProductCode: ' +
                oli.Product2.ER_Solution__r.ProductCode
              );
              System.debug(
                '>>> AAMgetEnterpriseInfos -- oli.Opportunity.Contract.Status: ' + oli.Opportunity.Contract.Status
              );
              if (
                oli.Product2.ER_Solution__r.ProductCode != solutionCode ||
                oli.Opportunity.Contract.Status == 'Activated'
              )
                hasOngoingProcess = true;
              if (
                oli.Opportunity.Contract.ER_QuoteId__r.ER_Main_Solution__r.ProductCode == solutionCode &&
                oli.Opportunity.Contract.ER_QuoteId__r.Status == 'Accepted' &&
                !String.isBlank(oli.Opportunity.Contract.ER_QuoteId__r.ER_Web_Offer_URL__c)
              ) {
                isWebOffer = true;
                contractStatus = oli.Opportunity.Contract.Status;
              }
            }

            // Check contracts uploaded by data mig (ie without opportunity)
            for (Contract ctr : [
              SELECT Id, Status, ER_Solutions__c
              FROM Contract
              WHERE AccountId = :accountId AND ER_OpportunityId__c = NULL
            ]) {
              if (ctr.Status == 'Activated')
                hasOngoingProcess = true;
            }

            if (hasOngoingProcess && !isWebOffer)
              return new Map<String, String>{ 'ongoingProcess' => 'true' };

            // If no draft contract for other product or activated contract, then set contractStatus to enable onboarding part
            if (!isWebOffer || String.isBlank(contractStatus))
              contractStatus = ctList[0].Opportunity.Contract.Status;
          }
          if (!String.isBlank(userEmail)) {
            Set<String> userEmailSet = new Set<String>{ existingAccountList[0].HU_HQ_Contact__r.Email };
            if (existingAccountList[0].Contacts != null) {
              for (Contact cnt : existingAccountList[0].Contacts)
                if (cnt.ER_Onboarding_Contract__c == ctList[0].Id)
                  userEmailSet.add(cnt.Email);
            }
            if (!userEmailSet.contains(userEmail))
              return new Map<String, String>{
                'badUserEmail' => 'true',
                'existingAccount' => 'true',
                'mainContact' => existingAccountList[0].HU_HQ_Contact__r.FirstName +
                ' ' +
                existingAccountList[0].HU_HQ_Contact__r.LastName
              };
          }
        }

        System.debug('>>> getEnterpriseInfos -- contractStatus: ' + contractStatus);

        if (!String.isBlank(contractStatus))
          resultMap.put(contractStatus, 'true'); // In case of draft contract, then complete all account infos

        resultMap.put('isReadOnly', isReadOnly);
        resultMap.put('existingAccount', 'true');
        resultMap.put('accountId', existingAccountList[0].Id);
        resultMap.put('leadId', leadId);
        resultMap.put('company', existingAccountList[0].Name);
        resultMap.put('phone', existingAccountList[0].Phone);
        // resultMap.put('legalForm',       existingAccountList[0].ER_Legal_Form__c);
        resultMap.put('legalName', existingAccountList[0].ER_Legal_Name__c);
        resultMap.put('address', existingAccountList[0].BillingStreet);
        resultMap.put('postalCode', existingAccountList[0].BillingPostalCode);
        resultMap.put('city', existingAccountList[0].BillingCity);
        resultMap.put('country', existingAccountList[0].BillingCountry);
        resultMap.put('refundCountry', existingAccountList[0].BillingCountry);
        resultMap.put('hasVATCode', String.isBlank(existingAccountList[0].ER_VAT_Number__c) ? null : 'true');
        resultMap.put('enterpriseVATCode', existingAccountList[0].ER_VAT_Number__c);
        resultMap.put('numberEmployees', String.valueOf(existingAccountList[0].NumberOfEmployees));
        resultMap.put('countryCode', countryCode);
        resultMap.put('enterpriseNb', (countryCode == 'LU' ? fiscalId : regNb));
        resultMap.put('fiscalId', (countryCode == 'LU' ? regNb : fiscalId));
        resultMap.put('promoCode', promoCode);
        if (qtList != null && !qtList.isEmpty()) {
          // get contract number & solution name for onboarding
          Quote quoteSolution;
          for (Quote qt : qtList)
            if (qt.ER_Main_Solution__r.ProductCode == solutionCode)
              quoteSolution = qt;
          resultMap.put('contractId', quoteSolution.ContractId);
          resultMap.put('contractNumber', quoteSolution.Contract.ContractNumber);
          resultMap.put('solutionName', quoteSolution.ER_Main_Solution__r.Name);
          resultMap.put('solutionCode', solutionCode);
        } else if (!ctList.isEmpty()) {
          OpportunityLineItem oliSolution;
          for (OpportunityLineItem oli : ctList)
            if (oli.Product2.ER_Solution__r.ProductCode == solutionCode)
              oliSolution = oli;
          resultMap.put('contractId', oliSolution.Opportunity.ContractId);
          resultMap.put('contractNumber', oliSolution.Opportunity.Contract.ContractNumber);
          resultMap.put('solutionName', oliSolution.Product2.ER_Solution__r.Name);
          resultMap.put('solutionCode', solutionCode);
        }
        // main contact
        System.debug(
          '>>> getEnterpriseInfos -- Existing company - existingAccountList[0].Id : *' +
          existingAccountList[0].Id +
          '*'
        );

        resultMap.put('contactId', existingAccountList[0].HU_HQ_Contact__c);
        resultMap.put('salutation', existingAccountList[0].HU_HQ_Contact__r.Salutation);
        resultMap.put('firstName', existingAccountList[0].HU_HQ_Contact__r.FirstName);
        resultMap.put('lastName', existingAccountList[0].HU_HQ_Contact__r.LastName);
        resultMap.put('email', existingAccountList[0].HU_HQ_Contact__r.Email);
        resultMap.put('contactPhone', existingAccountList[0].HU_HQ_Contact__r.Phone);
        resultMap.put('mobile', existingAccountList[0].HU_HQ_Contact__r.MobilePhone);
        resultMap.put('fax', existingAccountList[0].HU_HQ_Contact__r.Fax);
        resultMap.put('lang', existingAccountList[0].HU_HQ_Contact__r.ER_Language__c);
        resultMap.put('role', existingAccountList[0].HU_HQ_Contact__r.ER_Role__c);
        resultMap.put('keyId', existingAccountList[0].ER_External_Reference__c);
      } else if (!existingLeadList.isEmpty()) {
        System.debug('>>> getEnterpriseInfos -- Existing lead');
        resultMap.put('isReadOnly', 'false');
        resultMap.put('existingLead', 'true');
        resultMap.put('leadId', existingLeadList[0].Id);
        resultMap.put('company', existingLeadList[0].Company);
        resultMap.put('phone', existingLeadList[0].Phone);
        resultMap.put('legalName', existingLeadList[0].ER_Legal_Name__c);
        resultMap.put('address', existingLeadList[0].ER_Legal_Street__c);
        resultMap.put('postalCode', existingLeadList[0].ER_Legal_Zip_Code__c);
        resultMap.put('city', existingLeadList[0].ER_Legal_City__c);
        resultMap.put('country', existingLeadList[0].ER_Legal_Country__c);
        resultMap.put('refundCountry', existingLeadList[0].ER_Legal_Country__c);
        resultMap.put('hasVATCode', String.isBlank(existingLeadList[0].ER_VAT_Number__c) ? null : 'true');
        resultMap.put('enterpriseVATCode', existingLeadList[0].ER_VAT_Number__c);
        resultMap.put('salutation', existingLeadList[0].Salutation);
        resultMap.put('firstName', existingLeadList[0].FirstName);
        resultMap.put('lastName', existingLeadList[0].LastName);
        resultMap.put('lang', existingLeadList[0].ER_Language__c);
        resultMap.put('mobile', existingLeadList[0].MobilePhone);
        resultMap.put('role', existingLeadList[0].ER_Role__c);
        resultMap.put('email', existingLeadList[0].Email);
        resultMap.put('fax', existingLeadList[0].Fax);
        resultMap.put('numberEmployees', String.valueOf(existingLeadList[0].NumberOfEmployees));
      }
    }
    System.debug('>>> getEnterpriseInfos -- resultMap: ' + resultMap);
    return resultMap;
  }

  public static Map<String, String> upsertLead(String merchantInfosJSON, String sourceId) {
    Map<String, String> result = new Map<String, String>();

    System.debug('>>> GenericWithoutSharing upsertLead0 -- merchantInfosJSON: ' + merchantInfosJSON);

    if (!String.isBlank(merchantInfosJSON)) {
      Map<String, Object> merchantInfos = (Map<String, Object>) JSON.deserializeUntyped(merchantInfosJSON);
      String leadId, solutionId, solutionCode, countryCode, businessUnit, enterpriseNb, fiscalId, country;
      ID merchantLeadRecTypId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT');
      leadId = String.valueOf(merchantInfos.get('leadId'));
      countryCode = String.valueOf(merchantInfos.get('countryCode'));
      solutionCode = String.valueOf(merchantInfos.get('solution'));
      solutionId = APER32_Product2_Management.getSolutionId(solutionCode);
      businessUnit = Utils.getBUCode(countryCode);
      enterpriseNb = String.valueOf(merchantInfos.get('enterpriseNb'));
      fiscalId = String.valueOf(merchantInfos.get('fiscalId'));
      country = String.valueOf(merchantInfos.get('country'));

      System.debug('>>> GenericWithoutSharing upsertLead0 -- countryCode : ' + countryCode);
      System.debug(
        '>>> GenericWithoutSharing upsertLead0 -- solution : ' + String.valueOf(merchantInfos.get('solution'))
      );
      System.debug('>>> GenericWithoutSharing upsertLead0 -- scope : ' + String.valueOf(merchantInfos.get('scope')));

      System.debug('>>> GenericWithoutSharing upsertLead0 -- solutionId : ' + solutionId);
      System.debug('>>> GenericWithoutSharing upsertLead0 -- businessUnit : ' + businessUnit);
      Lead merchantLead = new Lead(
        Company = String.valueOf(merchantInfos.get('company')),
        ER_External_Reference__c = countryCode + enterpriseNb,
        ER_BUPicklist__c = businessUnit,
        ER_Country_Code__c = Utils.getCountryCode(country),
        ER_Legal_Country_Code__c = Utils.getCountryCode(country),
        ER_Registration_Number__c = (countryCode == 'LU' ? fiscalId : enterpriseNb),
        ER_VAT_Number__c = String.valueOf(merchantInfos.get('enterpriseVATCode')),
        ER_Not_Subject_to_VAT__c = String.isBlank(String.valueOf(merchantInfos.get('enterpriseVATCode'))),
        // ER_Legal_Form__c = String.valueOf(merchantInfos.get('legalForm')),
        ER_Legal_Name__c = String.valueOf(merchantInfos.get('legalName')),
        ER_Legal_Street__c = String.valueOf(merchantInfos.get('address')),
        Street = null, // COUL-1028: Set to null to prevent store creation during conversion
        ER_Legal_Zip_Code__c = String.valueOf(merchantInfos.get('postalCode')),
        ER_Legal_City__c = String.valueOf(merchantInfos.get('city')),
        ER_Legal_Country__c = country,
        ER_Lead_Channel__c = 'Merchant',
        ER_Lead_Type__c = System.label.LAB_SF_Lead_Type_Merchant,
        ER_Number_of_outlets__c = 0,
        Salutation = String.valueOf(merchantInfos.get('salutation')),
        FirstName = String.valueOf(merchantInfos.get('firstName')),
        LastName = (String.valueOf(merchantInfos.get('lastName')) == null
          ? String.valueOf(DateTime.now().getTime())
          : String.valueOf(merchantInfos.get('lastName'))),
        ER_Language__c = String.valueOf(merchantInfos.get('lang')),
        Phone = String.valueOf(merchantInfos.get('phone')),
        MobilePhone = String.valueOf(merchantInfos.get('mobile')),
        ER_Role__c = String.valueOf(merchantInfos.get('role')),
        Email = String.valueOf(merchantInfos.get('email')),
        Fax = String.valueOf(merchantInfos.get('fax')),
        LeadSource = 'Auto Enrollment',
        ERBE_Initial_Product_Of_Interest__c = solutionId,
        ER_Other_Fiscal_ID__c = (countryCode == 'LU' ? enterpriseNb : fiscalId),
        RecordTypeId = merchantLeadRecTypId,
        ER_OVT_Code__c = String.valueOf(merchantInfos.get('ovtCode')),
        ER_OVT_Operator__c = String.valueOf(merchantInfos.get('ovtOperator'))
      );

      Database.DMLOptions dmo = new Database.DMLOptions();
      if (String.isBlank(leadId))
        dmo.assignmentRuleHeader.useDefaultRule = true;
      merchantLead.setOptions(dmo);

      System.debug(
        '>>> GenericWithoutSharing upsertLead0 -- ER_External_Reference__c : ' + merchantLead.ER_External_Reference__c
      );
      upsert merchantLead ER_External_Reference__c;
      System.debug('>>> GenericWithoutSharing upsertLead0 -- lead upserted!! Id is : ' + merchantLead.Id);

      // Create campaign member if sourceId provided and if new lead
      if (!String.isBlank(sourceId) && String.isBlank(leadId)) {
        CampaignMember cm = new CampaignMember();
        Campaign cp = new Campaign();
        cp.ER_Source_ID__c = sourceId;
        cm.Campaign = cp;
        cm.LeadId = merchantLead.Id;
        cm.Status = 'Responded';
        insert cm;
      }

      result.put('leadId', merchantLead.Id); // Informations to be returned to lwc form
      result.put('keyId', Utils.generateUniqueId()); // used for Autoenrollment v2 for onboarding process
      System.debug('>>> GenericWithoutSharing upsertLead0 -- keyId : ' + result.get('keyId'));
    }
    return result;
  }

  // Update account & main contact in Web offer context
  @AuraEnabled
  public static void updateAccount(String merchantInfosJSON) {
    //TODO Update exising account and main contact
    System.debug('>>> GenericWithoutSharing updateAccount -- merchantInfosJSON : ' + merchantInfosJSON);

    if (!String.isBlank(merchantInfosJSON)) {
      Map<String, Object> merchantInfos = (Map<String, Object>) JSON.deserializeUntyped(merchantInfosJSON);
      String countryCode = String.valueOf(merchantInfos.get('countryCode'));
      String accountId = String.valueOf(merchantInfos.get('accountId'));
      String contactId;
      if (String.isBlank(accountId)) {
        String leadId = String.valueOf(merchantInfos.get('leadId'));
        Lead ld = [SELECT Id, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id = :leadId][0];
        accountId = ld.ConvertedAccountId;
        contactId = ld.ConvertedContactId;
      }

      if (!String.isBlank(accountId)) {
        Account acc = [SELECT Id, OwnerId, ER_BUPicklist__c FROM Account WHERE Id = :accountId LIMIT 1][0];

        Contact cnt = new Contact();
        cnt.Id = String.valueOf(merchantInfos.get('contactId'));
        cnt.AccountId = accountId;
        cnt.Salutation = String.valueOf(merchantInfos.get('salutation'));
        cnt.FirstName = String.valueOf(merchantInfos.get('firstName'));
        cnt.LastName = String.valueOf(merchantInfos.get('lastName'));
        cnt.Email = String.valueOf(merchantInfos.get('email'));
        cnt.Phone = String.valueOf(merchantInfos.get('contactPhone'));
        cnt.MobilePhone = String.valueOf(merchantInfos.get('mobile'));
        cnt.Fax = String.valueOf(merchantInfos.get('fax'));
        cnt.ER_Language__c = String.valueOf(merchantInfos.get('lang'));
        cnt.ER_Role__c = String.valueOf(merchantInfos.get('role'));
        cnt.ER_BUPicklist__c = acc.ER_BUPicklist__c;
        cnt.OwnerId = acc.OwnerId;
        upsert cnt;

        acc.Name = String.valueOf(merchantInfos.get('company'));
        acc.Phone = String.valueOf(merchantInfos.get('phone'));
        // acc.ER_Legal_Form__c = String.valueOf(merchantInfos.get('legalForm'));
        acc.ER_Legal_Name__c = String.valueOf(merchantInfos.get('legalName'));
        acc.BillingStreet = String.valueOf(merchantInfos.get('address'));
        acc.BillingPostalCode = String.valueOf(merchantInfos.get('postalCode'));
        acc.BillingCity = String.valueOf(merchantInfos.get('city'));
        acc.BillingCountry = String.valueOf(merchantInfos.get('country'));
        if (countryCode == 'LU') {
          acc.ER_Registration_Number__c = String.valueOf(merchantInfos.get('fiscalId'));
        } else {
          acc.ER_Other_Fiscal_ID__c = String.valueOf(merchantInfos.get('fiscalId'));
        }

        acc.HU_HQ_Contact__c = cnt.Id;
        update acc;
      } else {
        // Case lead not converted yet
        upsertLead(merchantInfosJSON, null);
      }
    }
  }

  @AuraEnabled
  public static void setLeadOwner(String leadId, String countryCode) {
    System.debug('>>> setLeadOwner Start');
    // If current lead owner is a queue, then assign it to a user using a "round robin" like function.
    Lead ld = [SELECT Id, OwnerId, Owner.Type FROM Lead WHERE Id = :leadId][0];
    System.debug('>>> setLeadOwner ld.OwnerId: ' + ld.OwnerId);
    System.debug('>>> setLeadOwner ld?.Owner.Type: ' + ld?.Owner.Type);
    if (ld?.Owner.Type == 'Queue' || String.isBlank(ld?.Owner.Type)) {
      // if(ld?.Owner.Type == 'Queue') {
      // The lead will be assigned to the one who have less leads in the past month (the period can be changed further if it's not fine)
      ld.OwnerId = getLeadOwnerId(ld.OwnerId, countryCode);
      System.debug('>>> setLeadOwner new ld.OwnerId: ' + ld.OwnerId);
      update ld;
    }
    System.debug('>>> setLeadOwner End *** ld.OwnerId: ' + ld.OwnerId);
  }

  @AuraEnabled
  public static String getLeadOwnerId(String queueId, String countryCode) {
    String newOwnerId;
    Set<Id> queueUsers, queueUsersClone;
    List<Id> queueUsersSortedNbLeads = new List<Id>();
    queueUsers = Utils.getQueueUsers(queueId);
    System.debug('>>> getLeadOwnerId queueUsers: ' + queueUsers);
    queueUsersClone = new Set<Id>(); //
    queueUsersClone.addAll(queueUsers); //

    String extRefCountry = countryCode + '%';

    AggregateResult[] leadOwnersStatAR = [
      SELECT OwnerId, Count(Id)
      FROM Lead
      WHERE
        ER_External_Reference__c LIKE :extRefCountry
        AND ER_Lead_Channel__c = 'Merchant'
        AND ER_Lead_Type__c = :System.label.LAB_SF_Lead_Type_Merchant
        AND Owner.Type = 'User'
      GROUP BY OwnerId
      ORDER BY Count(Id) ASC
    ];

    Map<Id, Integer> ownerLeadsMap = new Map<Id, Integer>();
    for (AggregateResult ar : leadOwnersStatAR) {
      String ownerId = (String) ar.get('OwnerId');
      Integer nbLeads = (Integer) ar.get('expr0');
      ownerLeadsMap.put(ownerId, nbLeads);
      System.debug('>>> getLeadOwnerId OwnerId: ' + ownerId + ' ---> nb Leads: ' + nbLeads);
      if (queueUsers.contains(ownerId))
        queueUsersSortedNbLeads.add((ID) ownerId);
    }

    // Check if one of the users in the queue has no lead yet, then assign to him
    Set<Id> diffUserSet = ownerLeadsMap.keySet();
    System.debug('>>> getLeadOwnerId queueUsersClone: ' + queueUsersClone);
    System.debug('>>> getLeadOwnerId diffUserSet: ' + diffUserSet);
    queueUsersClone.removeAll(diffUserSet);
    System.debug('>>> getLeadOwnerId queueUsersClone2: ' + queueUsersClone);

    newOwnerId = (queueUsersClone.size() > 0) ? new List<Id>(queueUsersClone)[0] : queueUsersSortedNbLeads[0];

    return newOwnerId;
  }

  @AuraEnabled(cacheable=true) //TODO recheck if queries are OK(if two or only one?)
  public static Map<String, Map<String, String>> getFinancialConditions(
    String country,
    String solution,
    String promoCode,
    String scope,
    String uniqueKeyId,
    String lang
  ) {
    Map<String, Map<String, String>> productInfosMap = new Map<String, Map<String, String>>();
    Boolean hasFoundPromo = false;

    Map<String, String> productTranslationsMap = Utils.getProductTranslationsMap(lang);

    if (String.isBlank(uniqueKeyId)) {
      // If not web offer (ie classic auto enrollment), get fin conditions from pricebook

      // Check Promo code type (Affiliation)
      String contractId;
      if (!String.isBlank(promoCode)) {
        Map<String, ER_Promo_Code__c> promoMap = GenericWithoutSharing.getPromoCode(Utils.getBUCode(country));
        if (promoMap.get(promoCode)?.RecordType.DeveloperName == System.label.LABS_SF_Affiliation_RecordType)
          contractId = promoMap.get(promoCode).ER_Contract__c;
      }

      if (String.isBlank(contractId)) {
        // Case Promo code
        List<PricebookEntry> pbeList = getPriceBookEntries(country, solution, scope, promoCode);
        System.debug('>>> getFinancialConditions -- pbeList size: ' + pbeList.size());

        for (PricebookEntry pbe : pbeList) {
          Map<String, String> curProductInfosMap = new Map<String, String>();
          curProductInfosMap.put('ServiceLabel', productTranslationsMap.get(pbe.Product2Id));
          curProductInfosMap.put('UnitPrice', getPriceFullString(pbe.UnitPrice));
          curProductInfosMap.put('CurrencyIsoCode', String.valueOf(pbe.CurrencyIsoCode));
          curProductInfosMap.put('ER_Percentage__c', getPercentFullString(pbe.ER_Percentage__c));
          // curProductInfosMap.put('ER_ValueType__c', String.valueOf(pbe.ER_ValueType__c));  // Commented as it seems to be unnecessary
          System.debug('>>> getFinancialConditions -- curProductInfosMap: ' + curProductInfosMap);
          if (!String.isBlank(pbe.ER_Promo_Code2__c))
            hasFoundPromo = true;
          productInfosMap.put(pbe.Product2.ProductCode.right(3), curProductInfosMap);
          System.debug(
            '>>> getFinancialConditions -- ProductCode nb - Name: ' +
            pbe.Product2.ProductCode.right(3) +
            ' - ' +
            pbe.Product2.Name
          );
        }
      } else {
        // Case Affiliation code
        for (ER_ContractLineItem__c cli : [
          SELECT
            Id,
            ER_Contract__r.Name,
            ER_Product2__r.Name,
            ER_Product2__r.ProductCode,
            ER_Product2__c,
            ER_Percentage__c,
            ER_UnitPrice__c,
            CurrencyIsoCode,
            ER_Discount__c,
            ER_Offer_validity_end_date__c
          FROM ER_ContractLineItem__c
          WHERE ER_Contract__c = :contractId AND ER_Contract_Status__c = 'Activated'
        ]) {
          Map<String, String> curProductInfosMap = new Map<String, String>();
          curProductInfosMap.put('ServiceLabel', productTranslationsMap.get(cli.ER_Product2__c));
          curProductInfosMap.put('UnitPrice', getPriceFullString(cli.ER_UnitPrice__c));
          curProductInfosMap.put('CurrencyIsoCode', String.valueOf(cli.CurrencyIsoCode));
          curProductInfosMap.put('ER_Percentage__c', getPercentFullString(cli.ER_Percentage__c));
          curProductInfosMap.put('ER_Discount__c', String.valueOf(cli.ER_Discount__c));
          curProductInfosMap.put(
            'ER_Offer_validity_end_date__c',
            ((Datetime) cli.ER_Offer_validity_end_date__c)?.format('dd/MM/YYYY')
          );

          System.debug('>>> getFinancialConditions -- curProductInfosMap: ' + curProductInfosMap);
          hasFoundPromo = true;
          productInfosMap.put(
            'ContractName',
            new Map<String, String>{ 'ContractName' => String.valueOf(cli.ER_Contract__r.Name) }
          );
          productInfosMap.put(cli.ER_Product2__r.ProductCode.right(3), curProductInfosMap);
        }
      }
    } else {
      // If web offer, get fin conditions from quote line items

      for (QuoteLineItem qli : [
        SELECT
          Product2Id,
          Product2.Name,
          Product2.ProductCode,
          CurrencyIsoCode,
          ER_Percentage__c,
          UnitPrice,
          Discount,
          ER_Offer_validity_end_date__c,
          Quote.Opportunity.ER_Promo_Code2__c
        FROM QuoteLineItem
        WHERE Quote.ER_Web_Offer_Token__c = :uniqueKeyId
      ]) {
        Map<String, String> curProductInfosMap = new Map<String, String>();

        curProductInfosMap.put('ServiceLabel', productTranslationsMap.get(qli.Product2Id));
        curProductInfosMap.put('UnitPrice', getPriceFullString(qli.UnitPrice));
        curProductInfosMap.put('CurrencyIsoCode', String.valueOf(qli.CurrencyIsoCode));
        curProductInfosMap.put('ER_Percentage__c', getPercentFullString(qli.ER_Percentage__c));
        curProductInfosMap.put('ER_ValueType__c', String.valueOf(qli.Product2.Name));
        curProductInfosMap.put('ER_Discount__c', String.valueOf(qli.Discount));
        curProductInfosMap.put(
          'ER_Offer_validity_end_date__c',
          ((Datetime) qli.ER_Offer_validity_end_date__c)?.format('dd/MM/YYYY')
        );

        System.debug('>>> getFinancialConditions (Web Offer) -- curProductInfosMap: ' + curProductInfosMap);
        productInfosMap.put(qli.Product2.ProductCode.right(3), curProductInfosMap);

        if (!hasFoundPromo && !String.isBlank(qli.Quote.Opportunity.ER_Promo_Code2__c))
          hasFoundPromo = true;
      }
    }
    System.debug('>>> getFinancialConditions -- hasFoundPromo: ' + hasFoundPromo);
    System.debug('>>> getFinancialConditions -- promoCode: ' + promoCode);
    if ((!hasFoundPromo && !String.isBlank(promoCode)))
      productInfosMap.put('Error', new Map<String, String>()); // In order to inform the webform to show the error message
    System.debug('>>> getFinancialConditions -- productInfosMap: ' + productInfosMap);

    return productInfosMap;
  }

  @AuraEnabled
  public static List<Map<String, String>> getFinCentersInfosByCRN(String crn) {
    if (String.isNotBlank(crn)) {
      List<Account> accounts = [SELECT Id FROM Account WHERE ER_Registration_Number__c = :crn];

      if (!accounts.isEmpty())
        return getFinCentersInfos(accounts[0].Id);

      return null;
    }

    return null;
  }

  @AuraEnabled
  public static List<Map<String, String>> getFinCentersInfos(String accountId) {
    List<Map<String, String>> resultMapList = new List<Map<String, String>>();

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

    List<ER_Financial_Center__c> fcList = [
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
      WHERE ER_Account_Name__c = :accountId AND ER_Type__c = 'Merchant'
    ];
    // AND     ER_Payment_Site__c = true];

    for (ER_Financial_Center__c finCenter : fcList) {
      Map<String, String> curFinCenter = new Map<String, String>();
      String curIban = anonymizeString(bankAccMap.get(finCenter.ER_Bank_Account__c)?.ER_IBAN__c, 4, 4);
      Contact curContact = cntMap.get(finCenter.ER_Contact__c);
      String curContactName = curContact == null ? ' ' : curContact.FirstName + ' ' + curContact.LastName;

      curFinCenter.put('name', finCenter.Name);
      curFinCenter.put('contact', curContactName);
      curFinCenter.put(
        'fullAddress',
        finCenter.ER_Street__c +
        ', ' +
        finCenter.ER_Zip_Code__c +
        ' ' +
        finCenter.ER_City__c
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

  private static String getPercentFullString(Decimal percent) {
    if (percent == null) {
      return String.valueOf(percent);
    }
    // keep precision to at least 2 decimal digits
    Decimal stripped = percent.stripTrailingZeros();
    if (stripped.scale() == 1) {
      return stripped.toPlainString() + '0';
    }

    return stripped.toPlainString();
  }

  private static String getPriceFullString(Decimal price) {
    return price == null ? String.valueOf(price) : price.toPlainString();
  }

  @AuraEnabled
  public static List<Map<String, Object>> getStoresInfos(String accountId, String locale) {
    if (accountId == null) {
      return null;
    }

    System.debug('>>> getStoresInfos: accountId = ' + accountId);
    System.debug('>>> getStoresInfos: locale = ' + locale);

    List<Map<String, Object>> resultMapList = new List<Map<String, Object>>();

    Set<String> fcSet = new Set<String>();
    for (ER_Financial_Center__c fc : [
      SELECT Id
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c = :accountId AND ER_Type__c = 'Merchant'
    ])
      fcSet.add(fc.Id);

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
      WHERE ER_Financial_Center__c IN :fcSet
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
      WHERE ER_Store__r.ER_Financial_Center__c IN :fcSet
    ];

    List<ER_StoreCategory__c> catList = [
      SELECT Store__c, Category__c, Main_Category__c
      FROM ER_StoreCategory__c
      WHERE Store__r.ER_Financial_Center__c IN :fcSet
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
        String.valueOf(st.ER_Contact__r.FirstName) +
        ' ' +
        String.valueOf(st.ER_Contact__r.LastName)
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
              curStore.put('readOnlyOnlineMastercard', 'true');
              curStore.put('mid', acc.ER_MID_Authorization__c);
              curStore.put('subMid', acc.ER_SubMID_Authorization__c);
            }
          } else if (acc.ER_Acceptor_Type__c == 'Aggregator') {
            curStore.put('hasAgregator', 'true');
            curStore.put('readOnlyAgregator', 'true');            
          } else if (
            acc.ER_Acceptor_Type__c == 'POS' &&
            acc.ER_Acceptor_Scheme__c == 'MasterCard' &&
            !String.isBlank(acc.ER_MID_Authorization__c)
          ) {
            curStore.put('hasPhysicalAcceptor', 'true');
            curStore.put('isPhysicalAcceptorMastercard', 'true');
            curStore.put('readOnlyPhysicalMastercard', 'true');
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
            curStore.put('hasReadOnlyPhysicalTerminal', 'true');            
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

  @AuraEnabled(cacheable=true)
  public static Boolean checkExistingAcceptor(String idType, String id1) {
    return checkExistingAcceptor(idType, id1, null, true);
  }

  @AuraEnabled(cacheable=true)
  public static Boolean checkExistingAcceptor(String idType, String id1, String id2) {
    return checkExistingAcceptor(idType, id1, id2, true);
  }

  @AuraEnabled(cacheable=true)
  public static Boolean checkExistingAcceptor(String idType, String id1, String id2, Boolean mastercardOnly) {
    System.debug('>>> checkExistingAcceptor idType: ' + idType);
    System.debug('>>> checkExistingAcceptor id1 & id2: ' + id1 + ' - ' + id2);

    String queryStr = 'SELECT Id FROM ER_Acceptor__c WHERE ';
    switch on idType {
      when 'tid' {
        queryStr += 'ER_TID_Authorization__c = :id1';
      }
      when 'mid' {
        queryStr += ' ER_MID_Authorization__c = :id1 AND ER_STatus__c = \'Active\' ';
        if (
          mastercardOnly == null || mastercardOnly // check if null due to the known issue in lwc with function overloading
        )
          queryStr += ' AND ER_Acceptor_Scheme__c = \'MasterCard\' ';
        if (!String.isBlank(id2))
          queryStr += ' AND ER_SubMID_Authorization__c = :id2 ';
      }
    }

    System.debug('>>> checkExistingAcceptor queryStr: ' + queryStr);
    List<ER_Acceptor__c> accList = (List<ER_Acceptor__c>) Database.query(queryStr);
    System.debug('>>> checkExistingAcceptor result: ' + accList.isEmpty());
    return accList.isEmpty();
  }

  // Get store categories with the hierarchy
  @AuraEnabled(cacheable=true)
  public static Map<String, Map<String, Map<String, String>>> getCategories(
    String country,
    String solution,
    String existingCatsCsv
  ) {
    Map<String, Map<String, Map<String, String>>> categoriesTranslationsMap = new Map<String, Map<String, Map<String, String>>>();
    Map<String, Map<String, String>> categoriesMap = new Map<String, Map<String, String>>();

    Map<String, String> treeParentKeysMap = new Map<String, String>();
    Set<String> parentIdSet = new Set<String>();
    List<String> catsOtherSolutionsList = new List<String>();
    String parentId, previousLanguage, businessUnit;
    businessUnit = Utils.getBUCode(country);
    if (!String.isBlank(existingCatsCsv))
      catsOtherSolutionsList = existingCatsCsv.split(',');
    System.debug('>>> getCategories - businessUnit / solution: ' + businessUnit + ' / ' + solution);

    //TODO check if clause with ER_Business_Unit__c has to be updated for BENELUX case
    for (ER_Translation__c category : [
      SELECT
        Dependent_Value__c,
        Language__c,
        Text__c,
        Dependent_Value__r.Level__c,
        Dependent_Value__r.Name,
        Dependent_Value__r.Parent_Dependent_Value__c,
        Dependent_Value__r.RecordTypeId,
        Dependent_Value__r.Solution_and_Service__c,
        Dependent_Value__r.Solution_and_Service__r.ProductCode
      FROM ER_Translation__c
      WHERE
        Field_API_Name__c = 'ER_StoreCategory__c'
        AND Dependent_Value__r.ER_Business_Unit__c = :businessUnit
        AND (Dependent_Value__r.Solution_and_Service__r.ProductCode = :solution
        OR Dependent_Value__c IN :catsOtherSolutionsList)
        AND Dependent_Value__r.ER_Status__c = 'Active'
      ORDER BY Language__c, Dependent_Value__r.Level__c
    ]) {
      if (String.isBlank(previousLanguage))
        previousLanguage = category.Language__c;
      // Reinit categoriesMap when new language
      if (category.Language__c != previousLanguage) {
        categoriesMap = new Map<String, Map<String, String>>();
        previousLanguage = category.Language__c;
      }

      // Build a list of "tree keys" composed by all parent Ids concatenated + current record Ids
      String curParent = category.Dependent_Value__r.Parent_Dependent_Value__c;
      parentId = (!String.isBlank(treeParentKeysMap.get(curParent))) ? treeParentKeysMap.get(curParent) + '*' : '';
      parentIdSet.add(curParent);

      treeParentKeysMap.put(category.Dependent_Value__c, parentId + category.Dependent_Value__c);
      System.debug('categoriesMap: Add ' + category.Text__c + ' for lang ' + category.Language__c);
      categoriesMap.put(
        treeParentKeysMap.get(category.Dependent_Value__c),
        new Map<String, String>{
          'id' => category.Dependent_Value__c,
          'name' => category.Text__c,
          'level' => String.valueOf(category.Dependent_Value__r.Level__c),
          'solution' => category.Dependent_Value__r.Solution_and_Service__r.ProductCode
        }
      );
      categoriesTranslationsMap.put(category.Language__c, categoriesMap);
    }

    // Set IsParent for each category
    Boolean isParent;
    System.debug('parentIdSet: ' + parentIdSet);
    for (String langKey : categoriesTranslationsMap.keySet()) {
      for (String treeKey : categoriesTranslationsMap.get(langKey).keySet()) {
        isParent = parentIdSet.contains(categoriesTranslationsMap.get(langKey).get(treeKey).get('id'));
        System.debug('Current Id ' + categoriesTranslationsMap.get(langKey).get(treeKey).get('id'));
        categoriesTranslationsMap.get(langKey).get(treeKey).put('isParent', String.valueOf(isParent));
        System.debug(treeKey + ' *** ' + categoriesTranslationsMap.get(langKey).get(treeKey));
      }
    }

    return categoriesTranslationsMap;
  }

  // Get terms and conditions
  @AuraEnabled
  public static Map<String, String> getTermsAndConditions(String country, String lang, String solution, String scope) {
    String docTitle = country + '-' + lang + '-' + solution + '-' + scope + ' Terms and conditions';
    Map<String, String> knowledgeMap = new Map<String, String>();

    System.debug('>>> getTermsAndConditions - doc Title: ' + docTitle);
    /*List<Knowledge__kav> knowledgeList = [
      SELECT Id, ER_Article_Body__c, CreatedDate, VersionNumber
      FROM Knowledge__kav
      WHERE Title = :docTitle AND IsLatestVersion = TRUE AND PublishStatus = 'Online'
    ];

    System.debug('>>> getTermsAndConditions - nb Articles: ' + knowledgeList.size());
    System.debug('>>> getTermsAndConditions - nb Articles total visibles: ' + [SELECT Id FROM Knowledge__kav].size());

    if (!knowledgeList.isEmpty()) {
      Knowledge__kav tcArticle = knowledgeList[0];
      knowledgeMap.put('tcContent', tcArticle.ER_Article_Body__c);
      knowledgeMap.put('Id', tcArticle.Id);
      knowledgeMap.put('tcVersion', String.valueOf(tcArticle.VersionNumber));
    }

    System.debug('>>> Content: ' + knowledgeMap.get('tcContent'));
    System.debug('>>> Version: ' + knowledgeMap.get('tcVersion'));
    return knowledgeMap;*/
    return null;
  }

  public static List<PricebookEntry> getPriceBookEntries(
    String country,
    String solution,
    String scope,
    String promoCode
  ) {
    return getPriceBookEntries(country, solution, scope, promoCode, null);
  }

  public static List<PricebookEntry> getPriceBookEntries(
    String country,
    String solution,
    String scope,
    String promoCode,
    String pricebook2Id
  ) {
    Set<String> product2ServiceSet = getProductCodes(country, solution);
    String businessUnit = Utils.getBUCode(country);
    System.debug('>>> getPriceBookEntries -- country: ' + country);
    System.debug('>>> getPriceBookEntries -- promoCode: ' + promoCode);
    System.debug('>>> getPriceBookEntries -- businessUnit: ' + businessUnit);
    System.debug('>>> getPriceBookEntries -- solutionCodes: ' + product2ServiceSet);

    if (country != 'BE' && country != 'LU' && String.isBlank(pricebook2Id)) {
      String pricebookCode = [SELECT Pricebook__c FROM Auto_Enrollment_Product__mdt WHERE Label = :solution][0]
      .Pricebook__c;
      List<Pricebook2> pbList = [
        SELECT Id
        FROM Pricebook2
        WHERE IsActive = TRUE AND ER_MDMId__c = :pricebookCode AND ER_Business_Unit__c = :country
      ];
      if (!pbList.isEmpty() && String.isBlank(pricebook2Id) && solution != 'ERFI_C_TD_DUALW_EUR_NEW_CRD_VIRT')
        pricebook2Id = pbList[0].Id;
    }

    System.debug('>>> getPriceBookEntries -- pricebook2Id: ' + pricebook2Id);

    String queryStr =
      'SELECT	Id, Product2.Name, ER_ValueType__c, ER_Percentage__c, UnitPrice, CurrencyIsoCode, Pricebook2Id, ER_SolutionName__c, ' +
      '		Product2Id, Product2.ProductCode, Product2.ER_Type__c, Product2.QuantityUnitOfMeasure, Product2.ER_Solution__r.Name, ' +
      '		ER_Promo_Code2__c, Product2.ER_Solution__r.ER_Service_Range_Type__c  ' +
      'FROM   PricebookEntry ' +
      'WHERE	Product2.ProductCode IN :product2ServiceSet ' +
      'AND	Pricebook2.ER_BUPicklist__c = :businessUnit ' +
      'AND    Product2.ER_MUC__c = :scope ' +
      'AND 	IsActive = true ';

    if (String.isBlank(promoCode) && !String.isBlank(pricebook2Id))
      queryStr += 'AND Pricebook2Id = :pricebook2Id AND ER_Promo_Code2__c = null';
    else if (!String.isBlank(promoCode)) {
      queryStr +=
        'AND ((ER_Promo_Code2__r.ER_Promo_Code__c = :promoCode ' +
        'AND ER_Promo_Code2__r.ER_Business_Unit__c = :businessUnit ' +
        'AND ER_Promo_Code2__r.ER_Active__c = true  ' +
        'AND ER_Promo_Code2__r.ER_Start_Date__c < TODAY  ' +
        'AND (ER_Promo_Code2__r.ER_End_Date__c = null OR ER_Promo_Code2__r.ER_End_Date__c > TODAY)) ' +
        'OR ER_Promo_Code2__c = null) ORDER BY ER_Promo_Code2__c, Pricebook2.IsStandard ASC NULLS FIRST';
    } else if (String.isBlank(promoCode)) {
      queryStr += ' AND ER_Promo_Code2__c = null';
    }
    System.debug('>>> getPriceBookEntries - queryStr : ' + queryStr);

    return (List<PricebookEntry>) Database.query(queryStr);
  }

  public static Set<String> getProductCodes(String country, String solution) {
    Set<String> product2ServiceSet = new Set<String>();
    String prodCodesCSV;

    if (country == 'BE' || country == 'LU') {
      // for BENELUX, get product codes using pattern
      String solutionCodePrefix = solution + '_';
      prodCodesCSV = [
        SELECT Value__c
        FROM Auto_Enrollment__mdt
        WHERE Country_Code__c = :country AND Label = 'pk_product_codes'
      ][0]
      .Value__c;

      for (String serviceCode : prodCodesCSV.split('\\|')) {
        product2ServiceSet.add(solutionCodePrefix + serviceCode);
      }
    } else {
      // for other countries, get product codes using custom metadata Auto_Enrollment_Product__mdt
      prodCodesCSV = [SELECT Services__c FROM Auto_Enrollment_Product__mdt WHERE Label = :solution][0].Services__c;
      for (String serviceCode : prodCodesCSV.split('\\|'))
        product2ServiceSet.add(serviceCode);
    }
    return product2ServiceSet;
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param oppId
   */
  public static void setOpportunityToCloseWon(Id oppId) {
    List<Opportunity> oppList = [SELECT Id, StageName, isClosed, ER_Won_Reason__c FROM Opportunity WHERE Id = :oppId];
    if (!oppList.isEmpty() && !oppList[0].isClosed) {
      String wonReason = String.isBlank(oppList[0].ER_Won_Reason__c) ? 'Auto-Enrollment' : oppList[0].ER_Won_Reason__c;
      update new Opportunity(Id = oppId, StageName = Label.LABS_SF_Opp_Status_ClosedWon, ER_Won_Reason__c = wonReason);
    }
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param accountId
   */
  public static void manageStatusOnContractActivation(Id accountId) {
    update new Account(
      Id = accountId,
      ER_Status__c = Label.LABS_SF_Account_Status_Active,
      ER_Inactive_Reason__c = '',
      ER_Inactive_date__c = null
    );
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param companyId
   */
  public static void manageSLIFromContract(String companyId) {
    System.debug('manageSLIFromContract START');

    ER_Store_Line_Item__c sli;
    Set<String> storeSolutions = new Set<String>();
    Set<String> allActiveSolutions = new Set<String>();
    List<ER_Store_Line_Item__c> sliListToInsert = new List<ER_Store_Line_Item__c>();
    Set<String> solutionSetToDelete = new Set<String>();
    Map<Id, ER_ContractLineItem__c> allcliList = APER12_Contract_Management.getAllActiveContractLineItems(
      new Set<String>{ companyId }
    ); //get All active solution for a company.

    for (ER_ContractLineItem__c cli : allcliList.values()) {
      allActiveSolutions.add(cli.ER_Product2__r.ER_Solution__c);
    }

    for (ER_Store__c store : [
      SELECT Id, Name, (SELECT id, ER_Solution__c FROM Store_line_Items__r)
      FROM ER_Store__c
      WHERE ER_Financial_Center__r.ER_Account_Name__c = :companyId
    ]) {
      storeSolutions = new Set<String>();
      //Build a set of store's solutions
      for (ER_Store_Line_Item__c sli2 : store.Store_line_Items__r) {
        storeSolutions.add(sli2.ER_Solution__c);
      }

      //check if the store has all company's solutions
      for (String activeSolution : allActiveSolutions) {
        if (!storeSolutions.contains(activeSolution)) {
          sli = new ER_Store_Line_Item__c();
          sli.ER_Solution__c = activeSolution;
          sli.ER_Status__c = Label.LABS_SF_StoreLineItem_Accept;
          sli.ER_Store__c = store.Id;
          sliListToInsert.add(sli);
        }
      }
      //get all solutions to be deleted from store
      storeSolutions.removeAll(allActiveSolutions);
      solutionSetToDelete.addAll(storeSolutions);
    }

    if (!sliListToInsert.isEmpty()) {
      System.debug('sliList to insert : ' + sliListToInsert);
      insert sliListToInsert;
    }

    if (!solutionSetToDelete.isEmpty()) {
      System.debug('solutionSetToDelete : ' + solutionSetToDelete);
      deleteStoreLineItemsForAccount(solutionSetToDelete, companyId);
    }
    System.debug('manageSLIFromContract END');
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param solutions
   * @param companyId
   */
  @TestVisible
  private static void deleteStoreLineItemsForAccount(Set<String> solutions, String companyId) {
    delete [
      SELECT Id
      FROM ER_Store_Line_Item__c
      WHERE ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c = :companyId AND ER_Solution__c IN :solutions
    ];
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageAccountLineItemsForContract(Contract contract) {
    /* System.debug('manageAccountLineItemsFromContract START - contract.Id: ' + contract.Id);
    ER_Solution_Line_Item__c ali;
    Set<String> accountSolutions = new Set<String>();
    Set<String> allNewContractSolutions = new Set<String>();
    List<ER_Solution_Line_Item__c> aliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> solutionSetToUpdate = new Set<String>();
    Map<String, String> ProductCodeId = new Map<String, String>();
    Map<Id, ER_ContractLineItem__c> allcliList = APER12_Contract_Management.getContractLineItems(contract.Id);
    Contract ct = [SELECT RecordTypeId, ER_Business_Unit__c, OwnerId FROM Contract WHERE Id = :contract.Id]; // Used for ER_Scope__c field
    System.debug('>>> AAM - ct.ER_Business_Unit__c : ' + ct.ER_Business_Unit__c);
    System.debug('>>> AAM - ct.OwnerId : ' + ct.OwnerId);

    for (Product2 Solution : [
      SELECT Id, name, productcode
      FROM Product2
      WHERE ER_Business_Unit__c = :ct.ER_Business_Unit__c
    ]) {
      ProductCodeId.put(Solution.productcode, Solution.Id);
      System.debug('>>> AAM - Solution productcode / Id : ' + Solution.productcode + ' / ' + Solution.Id);
    }

    for (ER_ContractLineItem__c cli : allcliList.values()) {
      System.debug('>>> AAM - cli.ER_Solution__c : ' + cli.ER_Solution__c);
      allNewContractSolutions.add(ProductCodeId.get(cli.ER_Solution__c));
    }
    System.debug('All new contract solutions to be added: ' + allNewContractSolutions);

    for (Account acc : [
      SELECT
        Id,
        Name,
        ER_BUPicklist__c,
        (
          SELECT id, ER_Solution__c, ER_Contract__c
          FROM Solution_Line_Items__r
          WHERE RecordType.DeveloperName = 'ER_Account_Line_Item'
        )
      FROM Account
      WHERE Id = :contract.AccountId
    ]) {
      accountSolutions = new Set<String>();
      //Build a set of account's solutions
      for (ER_Solution_Line_Item__c ali2 : acc.Solution_Line_Items__r) {
        accountSolutions.add(ali2.ER_Solution__c);
      }

      System.debug('All Account Line Item solutions: ' + accountSolutions);

      //check if the account has all company's solutions
      for (String NewSolution : allNewContractSolutions) {
        System.debug('accountSolutions: ' + accountSolutions);

        if (!accountSolutions.contains(NewSolution)) {
          ali = new ER_Solution_Line_Item__c();
          ali.ER_Solution__c = NewSolution;
          ali.ER_Contract__c = contract.Id;
          ali.ER_Status__c = Label.LAB_SF_SolutionLineItem_Active;
          ali.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Account_Line_Item')
            .getRecordTypeId();
          ali.ER_Account__c = acc.Id;
          if (
            ct.RecordTypeId ==
            Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
              .get('ER_Client_Contract_RT')
              .getRecordTypeId()
          )
            ali.ER_Scope__c = 'Client';
          else if (
            ct.RecordTypeId ==
            Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
              .get('ER_Merchant_Contract_RT')
              .getRecordTypeId()
          )
            ali.ER_Scope__c = 'Merchant';
          ali.ER_BUPicklist__c = acc.ER_BUPicklist__c; // AAM 20.01.22 - PBI#14305

          aliListToInsert.add(ali);
          System.debug('ALI to insert: ' + aliListToInsert);
        }
      }
      //get all solutions to be updated for Account
      solutionSetToUpdate.addAll(accountSolutions);
      solutionSetToUpdate.retainAll(allNewContractSolutions);
    }

    if (!aliListToInsert.isEmpty()) {
      insert aliListToInsert;
    }

    if (!solutionSetToUpdate.isEmpty()) {
      updateAccountLineItemsForAccount(solutionSetToUpdate, contract.Id, contract.AccountId, contract.Status);
    }

    System.debug('contract.Status : ' + contract.Status);
    System.debug('manageAccountLineItemsFromContract END'); */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param solutions
   * @param contractId
   * @param AccountId
   * @param contractStatus
   */
  @TestVisible
  private static void updateAccountLineItemsForAccount(
    Set<String> solutions,
    String contractId,
    String AccountId,
    String contractStatus
  ) {
    /* System.debug(LoggingLevel.DEBUG, 'updateAccountLineItemsForAccount Start');
    List<ER_Solution_Line_Item__c> accLineItemstoUpdate = new List<ER_Solution_Line_Item__c>();

    for (ER_Solution_Line_Item__c ali : [
      SELECT Id, ER_Contract__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Account_Line_Item'
        AND ER_Solution__c IN :solutions
        AND ER_Account__c = :AccountId
    ]) {
      if (contractStatus == Label.LABS_SF_Contract_Status_Activated) {
        System.debug(LoggingLevel.DEBUG, 'updateAccountLineItemsForAccount In Loop : ' + ali.Id);
        ali.ER_Contract__c = contractId;
        accLineItemstoUpdate.add(ali);
      }
    }

    if (!accLineItemstoUpdate.isEmpty())
      update accLineItemstoUpdate;
    System.debug(LoggingLevel.DEBUG, 'updateAccountLineItemsForAccount END'); */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageFCLIForFinancialCenter(Contract contract) {
    /* System.debug(LoggingLevel.DEBUG, 'manageFCLineItemsFromContract START');

    ER_Solution_Line_Item__c fcli;
    Set<String> financialStoreSolutions = new Set<String>();
    Set<String> NewContractSolutions = new Set<String>();
    Set<ER_Solution_Line_Item__c> AccLineItems = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> AcclisAcc = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> fcliListToInsert = new List<ER_Solution_Line_Item__c>();
    List<ER_Financial_Center__c> FCIlistTest = new List<ER_Financial_Center__c>();
    Set<String> solutionSetToUpdate = new Set<String>();
    Map<String, ER_Solution_Line_Item__c> AccliSolutionsMap = new Map<String, ER_Solution_Line_Item__c>();
    Map<Id, ER_ContractLineItem__c> allcliList = APER12_Contract_Management.getContractLineItems(contract.id);
    Map<Id, ER_Solution_Line_Item__c> allAccliList = APER20_Account_Management.getAllAccountLineItems(
      new Set<String>{ contract.AccountId }
    ); //get All Account Line Items for a company
    Map<String, String> ProductCodeId = new Map<String, String>();
    String FcType;
    for (Product2 Solution : [
      SELECT Id, name, productcode
      FROM Product2
      WHERE ER_Business_Unit__c = :allcliList.values().get(0).ER_Business_Unit__c
    ]) {
      ProductCodeId.put(Solution.productcode, Solution.Id);
    }

    for (ER_ContractLineItem__c cli : allcliList.values()) {
      NewContractSolutions.add(ProductCodeId.get(cli.ER_Solution__c));
    }

    //Loop to build Map Account to Account Line Items
    for (ER_Solution_Line_Item__c Accli : allAccliList.values()) {
      AccLineItems = new Set<ER_Solution_Line_Item__c>();

      if (!AcclisAcc.containsKey(Accli.ER_Account__c)) {
        AccLineItems.add(Accli);
        AcclisAcc.put(Accli.ER_Account__c, AccLineItems);
      } else {
        AccLineItems = AcclisAcc.get(Accli.ER_Account__c);
        AccLineItems.add(Accli);
        AcclisAcc.put(Accli.ER_Account__c, AccLineItems);
      }
    }
    System.debug(LoggingLevel.DEBUG, 'FCLIS of Financial Centers: ' + AcclisAcc);

    System.debug(LoggingLevel.DEBUG, 'All active solutions to be added: ' + NewContractSolutions);
    System.debug(LoggingLevel.DEBUG, 'contract.recordtypeid : ' + contract.RecordTypeId);
    if (
      contract.RecordTypeId ==
      Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Merchant_Contract_RT').getRecordTypeId()
    )
      FcType = Label.LABS_SF_FinancialCenter_Merchant;
    else if (
      contract.RecordTypeId ==
      Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ER_Client_Contract_RT').getRecordTypeId()
    )
      FcType = Label.LABS_SF_FinancialCenter_Client;
    System.debug(LoggingLevel.DEBUG, 'FcType : ' + FcType);

    FCIlistTest = [
      SELECT
        Id,
        Name,
        ER_Type__c,
        ER_Account_Name__c,
        ER_BUPicklist__c,
        (
          SELECT id, ER_Solution__c, ER_Contract__c
          FROM Solution_Line_Items__r
          WHERE RecordType.DeveloperName = 'ER_Financial_Center_Line_Item'
        )
      FROM ER_Financial_Center__c
      WHERE ER_Type__c = :FcType AND ER_Account_Name__c = :contract.AccountId
    ];
    System.debug('FCIlistTest.size : ' + FCIlistTest.size());

    //for (ER_Financial_Center__c fc : [select Id, Name, ER_Type__c, ER_Account_Name__c, (select id, ER_Solution__c, ER_Contract__c from Solution_Line_Items__r where RecordType.DeveloperName ='ER_Financial_Center_Line_Item') from ER_Financial_Center__c where ER_Type__c = : FcType and  ER_Account_Name__c = : contract.AccountId]) {
    for (ER_Financial_Center__c fc : FCIlistTest) {
      financialStoreSolutions = new Set<String>();
      //Build a set of financial store's solutions
      for (ER_Solution_Line_Item__c fcli2 : fc.Solution_Line_Items__r) {
        financialStoreSolutions.add(fcli2.ER_Solution__c);
      }
      System.debug('All FC Line Item solutions: ' + financialStoreSolutions);

      //Build a Map of Account's solutions with Account Line Items
      for (ER_Solution_Line_Item__c Accli : AcclisAcc.get(fc.ER_Account_Name__c)) {
        AccliSolutionsMap.put(Accli.ER_Solution__c, Accli);
      }

      //check if the account has all company's solutions
      for (String NewSolution : NewContractSolutions) {
        if (!financialStoreSolutions.contains(NewSolution)) {
          fcli = new ER_Solution_Line_Item__c();
          fcli.ER_Solution__c = NewSolution;
          fcli.ER_Contract__c = contract.Id;
          fcli.ER_Financial_Center__c = fc.Id;
          fcli.ER_BUPicklist__c = fc.ER_BUPicklist__c;
          if (FCIlistTest.size() == 1) {
            fcli.ER_Status__c = Label.LAB_SF_SolutionLineItem_Active;
          } else {
            fcli.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
          }
          fcli.ER_Parent_Line_Item__c = AccliSolutionsMap.get(NewSolution)?.Id;
          fcli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Financial_Center_Line_Item')
            .getRecordTypeId();
          if (fc.ER_Type__c == Label.LABS_SF_FinancialCenter_Client)
            fcli.ER_Scope__c = Label.LABS_SF_FinancialCenter_Client;
          else if (fc.ER_Type__c == Label.LABS_SF_FinancialCenter_Merchant)
            fcli.ER_Scope__c = Label.LABS_SF_FinancialCenter_Merchant;

          fcliListToInsert.add(fcli);
          System.debug('ALI to insert: ' + fcliListToInsert);
        }
      }
      //get all solutions to be updated for Account

      solutionSetToUpdate.addAll(financialStoreSolutions);
      solutionSetToUpdate.retainAll(NewContractSolutions);
    }

    if (!fcliListToInsert.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'aliList to insert : ' + fcliListToInsert);
      insert fcliListToInsert;
    }
    if (!solutionSetToUpdate.isEmpty()) {
      System.debug('solutionSetToUpdate : ' + solutionSetToUpdate);
      updateFCLIForFinancialCenter(solutionSetToUpdate, contract.Id, contract.AccountId, contract.Status); // test in account management to replace it
    }

    System.debug(LoggingLevel.DEBUG, 'manageFCLineItemsFromContract END'); */
  }

  /**
   * @param solutions
   * @param contractId
   * @param AccountId
   * @param contractStatus
   */
  @TestVisible
  private static void updateFCLIForFinancialCenter(
    Set<String> solutions,
    String contractId,
    String AccountId,
    String contractStatus
  ) {
    /* System.debug(LoggingLevel.DEBUG, 'updateFCLIForFinancialCenter Start');
    List<ER_Solution_Line_Item__c> fcLineItemstoUpdate = new List<ER_Solution_Line_Item__c>();

    for (ER_Solution_Line_Item__c fcli : [
      SELECT id, ER_Contract__c, ER_Solution__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Financial_Center_Line_Item'
        AND ER_Financial_Center__r.ER_Account_Name__c = :AccountId
        AND ER_Solution__c IN :solutions
    ]) {
      if (contractStatus == Label.LABS_SF_Contract_Status_Activated) {
        System.debug('updateFCLIForFinancialCenter in Loop : ' + fcli.id);
        fcli.ER_Contract__c = contractId;
        fcLineItemstoUpdate.add(fcli);
      }
    }

    if (!fcLineItemstoUpdate.isEmpty())
      update fcLineItemstoUpdate;

    System.debug(LoggingLevel.DEBUG, 'updateFCLIForFinancialCenter END'); */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageSLIFromContractNew(Contract contract) {
    /* System.debug(LoggingLevel.DEBUG, 'manageSLIFromContract START');

    ER_Solution_Line_Item__c sli;
    Set<String> storeSolutions = new Set<String>();
    Set<String> allActiveSolutions = new Set<String>();
    Set<ER_Solution_Line_Item__c> fcenterLineItems = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> fclisFinancialCenter = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> sliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> solutionSetToUpdate = new Set<String>();
    Map<Id, ER_ContractLineItem__c> allcliList = APER12_Contract_Management.getContractLineItems(contract.Id);
    Map<Id, ER_Solution_Line_Item__c> allfcliList = APER30_FinancialCenter_Management.getAllFCLineItems(
      new Set<String>{ contract.AccountId }
    ); //get All FC Line Items for a company
    //Map<String, String> fcliSolutions = new Map<String, String>();
    Map<String, ER_Solution_Line_Item__c> fcliSolutionsMap = new Map<String, ER_Solution_Line_Item__c>();
    Map<String, String> ProductCodeId = new Map<String, String>();

    for (Product2 Solution : [
      SELECT Id, name, productcode
      FROM Product2
      WHERE ER_Business_Unit__c = :allcliList.values().get(0).ER_Business_Unit__c
    ]) {
      ProductCodeId.put(Solution.productcode, Solution.Id);
    }

    for (ER_ContractLineItem__c cli : allcliList.values()) {
      allActiveSolutions.add(ProductCodeId.get(cli.ER_Solution__c));
    }

    //Loop to build Map Financial Centers to FC Line Items
    for (ER_Solution_Line_Item__c fcli : allfcliList.values()) {
      fcenterLineItems = new Set<ER_Solution_Line_Item__c>();

      if (!fclisFinancialCenter.containsKey(fcli.ER_Financial_Center__c)) {
        fcenterLineItems.add(fcli);
        fclisFinancialCenter.put(fcli.ER_Financial_Center__c, fcenterLineItems);
      } else {
        fcenterLineItems = fclisFinancialCenter.get(fcli.ER_Financial_Center__c);
        fcenterLineItems.add(fcli);
        fclisFinancialCenter.put(fcli.ER_Financial_Center__c, fcenterLineItems);
      }
    }

    System.debug(LoggingLevel.DEBUG, 'FCLIS of Financial Centers: ' + fclisFinancialCenter);

    for (ER_Store__c store : [
      SELECT
        Id,
        Name,
        ER_BUPicklist__c,
        (
          SELECT id, ER_Solution__c, ER_Status__c
          FROM Solution_Line_Items__r
          WHERE RecordType.DeveloperName = 'ER_Store_Line_Item'
        ),
        ER_Financial_Center__c
      FROM ER_Store__c
      WHERE ER_Financial_Center__r.ER_Account_Name__c = :contract.AccountId
    ]) {
      storeSolutions = new Set<String>();
      //Build a set of store's solutions
      for (ER_Solution_Line_Item__c sli2 : store.Solution_Line_Items__r) {
        storeSolutions.add(sli2.ER_Solution__c);
      }

      //Build a Map of financial center's solutions with Financial Center Line Items
      if (store.ER_Financial_Center__c != null && fclisFinancialCenter.containsKey(store.ER_Financial_Center__c)) {
        for (ER_Solution_Line_Item__c fcli : fclisFinancialCenter.get(store.ER_Financial_Center__c)) {
          //fcliSolutions.put(fcli.ER_Solution__c, fcli.Id);
          fcliSolutionsMap.put(fcli.ER_Solution__c, fcli);
        }
      }

      //check if the store has all company's solutions
      for (String activeSolution : allActiveSolutions) {
        if (!storeSolutions.contains(activeSolution)) {
          sli = new ER_Solution_Line_Item__c();
          sli.ER_Solution__c = activeSolution;
          sli.ER_Store__c = store.Id;
          sli.ER_Contract__c = contract.Id;
          //sli.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
          sli.ER_Status__c = fcliSolutionsMap.get(activeSolution)?.ER_Status__c;
          sli.ER_Parent_Line_Item__c = fcliSolutionsMap.get(activeSolution)?.Id;
          //sli.ER_Parent_Line_Item__c = fcliSolutions.get(activeSolution);
          sli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Store_Line_Item')
            .getRecordTypeId();
          sli.ER_BUPicklist__c = store.ER_BUPicklist__c; // AAM 20.01.22 - PBI#14305

          sliListToInsert.add(sli);
        }
      }
      //get all solutions to be updated from store
      solutionSetToUpdate.addAll(storeSolutions);
      solutionSetToUpdate.retainAll(allActiveSolutions);
    }

    if (!sliListToInsert.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'sliList to insert : ' + sliListToInsert);
      insert sliListToInsert;
    }

    if (!solutionSetToUpdate.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'solutionSetToDelete : ' + solutionSetToUpdate);
      updateStoreLineItemsForAccount(solutionSetToUpdate, contract.Id, contract.AccountId, contract.Status);
    }

    System.debug(LoggingLevel.DEBUG, 'manageSLIFromContract END'); */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param solutions
   * @param contractId
   * @param accId
   * @param contractStatus
   */
  @TestVisible
  private static void updateStoreLineItemsForAccount(
    Set<String> solutions,
    String contractId,
    String accId,
    String contractStatus
  ) {
    /* List<ER_Solution_Line_Item__c> storeLineItemstoUpdate = new List<ER_Solution_Line_Item__c>();

    for (ER_Solution_Line_Item__c sli : [
      SELECT id, ER_Contract__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Store_Line_Item'
        AND ER_Solution__c IN :solutions
        AND ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c = :accId
    ]) {
      if (contractStatus == Label.LABS_SF_Contract_Status_Activated) {
        sli.ER_Contract__c = contractId;
        storeLineItemstoUpdate.add(sli);
      }
    }

    if (!storeLineItemstoUpdate.isEmpty())
      update storeLineItemstoUpdate; */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param solutions
   * @param contractId
   * @param accId
   * @param contractStatus
   */
  @TestVisible
  private static void updateAcceptorLineItemsForAccount(
    Set<String> solutions,
    String contractId,
    String accId,
    String contractStatus
  ) {
    /* List<ER_Solution_Line_Item__c> acceptorLineItemstoUpdate = new List<ER_Solution_Line_Item__c>();
    for (ER_Solution_Line_Item__c accli : [
      SELECT id, ER_Contract__c
      FROM ER_Solution_Line_Item__c
      WHERE
        ER_Solution__c IN :solutions
        AND ER_Acceptor__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c = :accId
    ]) {
      if (contractStatus == Label.LABS_SF_Contract_Status_Activated) {
        accli.ER_Contract__c = contractId;
        acceptorLineItemstoUpdate.add(accli);
      }
    }

    if (!acceptorLineItemstoUpdate.isEmpty())
      update acceptorLineItemstoUpdate; */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageAcceptorLIFromContract(Contract contract) {
    /* System.debug(LoggingLevel.DEBUG, 'manageAcceptorLIFromContract START');
    ER_Solution_Line_Item__c accli;
    Set<String> acceptorSolutions = new Set<String>();
    Set<String> allActiveSolutions = new Set<String>();
    Set<ER_Solution_Line_Item__c> storeLineItems = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> slisStore = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> accliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> solutionSetToUpdate = new Set<String>();
    Map<Id, ER_ContractLineItem__c> allcliList = APER12_Contract_Management.getContractLineItems(contract.id);
    Map<Id, ER_Solution_Line_Item__c> allsliList = APER14_Store_Management.getAllStoreLineItems(
      new Set<String>{ contract.AccountId }
    ); //get All Store Line Items for a company.
    //Map<String, String> sliSolutions = new Map<String, String>();
    Map<String, ER_Solution_Line_Item__c> sliSolutionsMap = new Map<String, ER_Solution_Line_Item__c>();
    Map<String, String> ProductCodeId = new Map<String, String>();

    System.debug(LoggingLevel.DEBUG, 'allcliList.values().get(0).ER_Business_Unit__c');
    System.debug(LoggingLevel.DEBUG, 'allcliList.values().get(0).ER_Business_Unit__c contract.id : ' + contract.id);
    System.debug(LoggingLevel.DEBUG, 'allcliList.values().get(0).ER_Business_Unit__c list : ' + allcliList);
    System.debug(
      LoggingLevel.DEBUG,
      'allcliList.values().get(0).ER_Business_Unit__c : ' + allcliList.values().get(0).ER_Business_Unit__c
    );

    for (Product2 Solution : [
      SELECT Id, name, productcode
      FROM Product2
      WHERE ER_Business_Unit__c = :allcliList.values().get(0).ER_Business_Unit__c
    ]) {
      ProductCodeId.put(Solution.productcode, Solution.Id);
    }

    for (ER_ContractLineItem__c cli : allcliList.values()) {
      //allActiveSolutions.add(cli.ER_Product2__r.ER_Solution__c);
      allActiveSolutions.add(ProductCodeId.get(cli.ER_Solution__c));
    }

    //Loop to build Map Stores to Store Line Items
    for (ER_Solution_Line_Item__c sli : allsliList.values()) {
      storeLineItems = new Set<ER_Solution_Line_Item__c>();

      if (!slisStore.containsKey(sli.ER_Store__c)) {
        storeLineItems.add(sli);
        slisStore.put(sli.ER_Store__c, storeLineItems);
      } else {
        storeLineItems = slisStore.get(sli.ER_Store__c);
        storeLineItems.add(sli);
        slisStore.put(sli.ER_Store__c, storeLineItems);
      }
    }

    for (ER_Acceptor__c acceptor : [
      SELECT
        Id,
        Name,
        ER_Store__c,
        (SELECT Id, ER_Solution__c FROM Solution_Line_Items__r WHERE RecordType.DeveloperName = 'ER_Acceptor_Line_Item')
      FROM ER_Acceptor__c
      WHERE ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c = :contract.AccountId
    ]) {
      acceptorSolutions = new Set<String>();

      //Build a set of Acceptor's solutions
      for (ER_Solution_Line_Item__c accli2 : acceptor.Solution_Line_Items__r) {
        acceptorSolutions.add(accli2.ER_Solution__c);
      }

      //Build a Map of store's solutions with Store Line Items
      for (ER_Solution_Line_Item__c sli : slisStore.get(acceptor.ER_Store__c)) {
        //sliSolutions.put(sli.ER_Solution__c, sli.Id);
        sliSolutionsMap.put(sli.ER_Solution__c, sli);
      }

      //check if the acceptor has all company's solutions
      for (String activeSolution : allActiveSolutions) {
        if (!acceptorSolutions.contains(activeSolution)) {
          accli = new ER_Solution_Line_Item__c();
          accli.ER_Solution__c = activeSolution;
          accli.ER_Acceptor__c = acceptor.Id;
          accli.ER_Contract__c = contract.Id;
          //accli.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
          accli.ER_Status__c = sliSolutionsMap.get(activeSolution)?.ER_Status__c;
          accli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Acceptor_Line_Item')
            .getRecordTypeId();
          //accli.ER_Parent_Line_Item__c = sliSolutions.get(activeSolution);
          accli.ER_Parent_Line_Item__c = sliSolutionsMap.get(activeSolution)?.Id;
          // accli.ER_BUPicklist__c = contract.ER_BUPicklist__c;  // AAM 20.01.22 - PBI#14305
          accli.ER_BUPicklist__c = allcliList.values().get(0).ER_Business_Unit__c; // AAM 20.01.22 - PBI#14305

          accliListToInsert.add(accli);
        }
      }
      //get all solutions to be updated from store
      solutionSetToUpdate.addAll(acceptorSolutions);
      solutionSetToUpdate.retainAll(allActiveSolutions);
    }

    if (!accliListToInsert.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'accliList to insert : ' + accliListToInsert);
      insert accliListToInsert;
    }

    if (!solutionSetToUpdate.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'solutionSetToDelete : ' + solutionSetToUpdate);
      updateAcceptorLineItemsForAccount(solutionSetToUpdate, contract.Id, contract.AccountId, contract.Status);
    }

    System.debug(LoggingLevel.DEBUG, 'manageAcceptorLIFromContract END'); */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param solutions
   * @param contractId
   * @param accId
   * @param contractStatus
   */
  @TestVisible
  private static void updateDeliverySiteLineItemsForAccount(
    Set<String> solutions,
    String contractId,
    String accId,
    String contractStatus
  ) {
    /* List<ER_Solution_Line_Item__c> deliverySiteLineItemstoUpdate = new List<ER_Solution_Line_Item__c>();

    for (ER_Solution_Line_Item__c dsli : [
      SELECT id, ER_Contract__c
      FROM ER_Solution_Line_Item__c
      WHERE ER_Solution__c IN :solutions AND ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c = :accId
    ]) {
      if (contractStatus == Label.LABS_SF_Contract_Status_Activated) {
        dsli.ER_Contract__c = contractId;
        deliverySiteLineItemstoUpdate.add(dsli);
      }
    }

    if (!deliverySiteLineItemstoUpdate.isEmpty())
      update deliverySiteLineItemstoUpdate; */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageDSLIFromContract(Contract contract) {
    /* System.debug(LoggingLevel.DEBUG, 'manageDSLIFromContract START');
    ER_Solution_Line_Item__c dsli;
    Set<String> deliverySiteSolutions = new Set<String>();
    Set<String> allActiveSolutions = new Set<String>();
    Set<ER_Solution_Line_Item__c> fcenterLineItems = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> fclisFinancialCenter = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> dsliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> solutionSetToUpdate = new Set<String>();
    Map<Id, ER_ContractLineItem__c> allcliList = APER12_Contract_Management.getContractLineItems(contract.id);
    Map<Id, ER_Solution_Line_Item__c> allfcliList = APER30_FinancialCenter_Management.getAllFCLineItems(
      new Set<String>{ contract.AccountId }
    ); //get All FC Line Items for a company
    //Map<String, String> fcliSolutions = new Map<String, String>();
    Map<String, ER_Solution_Line_Item__c> fcliSolutionsMap = new Map<String, ER_Solution_Line_Item__c>();
    Map<String, String> ProductCodeId = new Map<String, String>();

    for (Product2 Solution : [
      SELECT Id, name, productcode
      FROM Product2
      WHERE ER_Business_Unit__c = :allcliList.values().get(0).ER_Business_Unit__c
    ]) {
      ProductCodeId.put(Solution.productcode, Solution.Id);
    }

    for (ER_ContractLineItem__c cli : allcliList.values()) {
      allActiveSolutions.add(ProductCodeId.get(cli.ER_Solution__c));
    }

    //Loop to build Map Financial Centers to FC Line Items
    for (ER_Solution_Line_Item__c fcli : allfcliList.values()) {
      fcenterLineItems = new Set<ER_Solution_Line_Item__c>();

      if (!fclisFinancialCenter.containsKey(fcli.ER_Financial_Center__c)) {
        fcenterLineItems.add(fcli);
        fclisFinancialCenter.put(fcli.ER_Financial_Center__c, fcenterLineItems);
      } else {
        fcenterLineItems = fclisFinancialCenter.get(fcli.ER_Financial_Center__c);
        fcenterLineItems.add(fcli);
        fclisFinancialCenter.put(fcli.ER_Financial_Center__c, fcenterLineItems);
      }
    }

    for (ER_Delivery_Site__c deliverySite : [
      SELECT
        Id,
        Name,
        ER_Financial_Center__c,
        ER_BUPicklist__c,
        (
          SELECT id, ER_Solution__c
          FROM Solution_Line_Items__r
          WHERE RecordType.DeveloperName = 'ER_Delivery_Site_Line_Item'
        )
      FROM ER_Delivery_Site__c
      WHERE ER_Financial_Center__r.ER_Account_Name__c = :contract.AccountId
    ]) {
      deliverySiteSolutions = new Set<String>();
      //Build a set of delivery site's solutions
      for (ER_Solution_Line_Item__c dsli2 : deliverySite.Solution_Line_Items__r) {
        deliverySiteSolutions.add(dsli2.ER_Solution__c);
      }

      //Build a Map of financial center's solutions with Financial Center Line Items
      for (ER_Solution_Line_Item__c fcli : fclisFinancialCenter.get(deliverySite.ER_Financial_Center__c)) {
        //fcliSolutions.put(fcli.ER_Solution__c, fcli.Id);
        fcliSolutionsMap.put(fcli.ER_Solution__c, fcli);
      }

      //check if the delivery site has all company's solutions
      for (String activeSolution : allActiveSolutions) {
        if (!deliverySiteSolutions.contains(activeSolution)) {
          dsli = new ER_Solution_Line_Item__c();
          dsli.ER_Solution__c = activeSolution;
          dsli.ER_Delivery_Site__c = deliverySite.Id;
          dsli.ER_Contract__c = contract.Id;
          dsli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Delivery_Site_Line_Item')
            .getRecordTypeId();
          //dsli.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
          //dsli.ER_Parent_Line_Item__c = fcliSolutions.get(activeSolution);
          dsli.ER_Status__c = fcliSolutionsMap.get(activeSolution)?.ER_Status__c;
          dsli.ER_Parent_Line_Item__c = fcliSolutionsMap.get(activeSolution)?.Id;
          dsli.ER_BUPicklist__c = deliverySite.ER_BUPicklist__c;
          dsliListToInsert.add(dsli);
        }
      }
      //get all solutions to be updated from delivery site
      solutionSetToUpdate.addAll(deliverySiteSolutions);
      solutionSetToUpdate.retainAll(allActiveSolutions);
    }

    if (!dsliListToInsert.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'sliList to insert : ' + dsliListToInsert);
      insert dsliListToInsert;
    }

    if (!solutionSetToUpdate.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'solutionSetToDelete : ' + solutionSetToUpdate);
      updateDeliverySiteLineItemsForAccount(solutionSetToUpdate, contract.Id, contract.AccountId, contract.Status);
    }

    System.debug(LoggingLevel.DEBUG, 'manageDSLIFromContract END'); */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param solutions
   * @param contractId
   * @param accId
   * @param contractStatus
   */
  @TestVisible
  private static void updateDistributionPointLineItemsForAccount(
    Set<String> solutions,
    String contractId,
    String accId,
    String contractStatus
  ) {
    /* List<ER_Solution_Line_Item__c> dPointLineItemstoUpdate = new List<ER_Solution_Line_Item__c>();

    for (ER_Solution_Line_Item__c dpli : [
      SELECT id, ER_Contract__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Distribution_Point_Line_Item'
        AND ER_Solution__c IN :solutions
        AND ER_Distribution_Point__r.ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c = :accId
    ]) {
      if (contractStatus == Label.LABS_SF_Contract_Status_Activated) {
        dpli.ER_Contract__c = contractId;
        dPointLineItemstoUpdate.add(dpli);
      }
    }

    if (!dPointLineItemstoUpdate.isEmpty())
      update dPointLineItemstoUpdate; */
  }

  /**
   * @author AAZ
   * @date 17/01/2022
   * @param contract
   */
  public static void manageDPLIFromContract(Contract contract) {
    /* System.debug(LoggingLevel.DEBUG, 'manageDPLIFromContract START');
    ER_Solution_Line_Item__c dpli;
    Set<String> dPointSolutions = new Set<String>();
    Set<String> allActiveSolutions = new Set<String>();
    Set<ER_Solution_Line_Item__c> deliverySiteLineItems = new Set<ER_Solution_Line_Item__c>();
    Map<String, Set<ER_Solution_Line_Item__c>> dslisDeliverySite = new Map<String, Set<ER_Solution_Line_Item__c>>();
    List<ER_Solution_Line_Item__c> dpliListToInsert = new List<ER_Solution_Line_Item__c>();
    Set<String> solutionSetToUpdate = new Set<String>();
    Map<Id, ER_ContractLineItem__c> allcliList = APER12_Contract_Management.getContractLineItems(contract.id);
    Map<Id, ER_Solution_Line_Item__c> alldsliList = APER28_DeliverySite_Management.getAllDeliverySiteLineItems(
      new Set<String>{ contract.AccountId }
    ); //get All Delivery Site Line Items for a company.
    //Map<String, String> dsliSolutions = new Map<String, String>();
    Map<String, ER_Solution_Line_Item__c> dsliSolutionsMap = new Map<String, ER_Solution_Line_Item__c>();
    Map<String, String> ProductCodeId = new Map<String, String>();

    for (Product2 Solution : [
      SELECT Id, name, productcode
      FROM Product2
      WHERE ER_Business_Unit__c = :allcliList.values().get(0).ER_Business_Unit__c
    ]) {
      ProductCodeId.put(Solution.productcode, Solution.Id);
    }

    for (ER_ContractLineItem__c cli : allcliList.values()) {
      allActiveSolutions.add(ProductCodeId.get(cli.ER_Solution__c));
    }

    //Loop to build Map Delivery Sites to Delivery Site Line Items
    for (ER_Solution_Line_Item__c dsli : alldsliList.values()) {
      deliverySiteLineItems = new Set<ER_Solution_Line_Item__c>();

      if (!dslisDeliverySite.containsKey(dsli.ER_Delivery_Site__c)) {
        deliverySiteLineItems.add(dsli);
        dslisDeliverySite.put(dsli.ER_Delivery_Site__c, deliverySiteLineItems);
      } else {
        deliverySiteLineItems = dslisDeliverySite.get(dsli.ER_Delivery_Site__c);
        deliverySiteLineItems.add(dsli);
        dslisDeliverySite.put(dsli.ER_Delivery_Site__c, deliverySiteLineItems);
      }
    }

    for (ER_Distribution_Point__c dPoint : [
      SELECT
        Id,
        Name,
        ER_Delivery_Site__c,
        ER_BUPicklist__c,
        (
          SELECT Id, ER_Solution__c
          FROM Solution_Line_Items__r
          WHERE RecordType.DeveloperName = 'ER_Distribution_Point_Line_Item'
        )
      FROM ER_Distribution_Point__c
      WHERE ER_Delivery_Site__r.ER_Financial_Center__r.ER_Account_Name__c = :contract.AccountId
    ]) {
      dPointSolutions = new Set<String>();

      //Build a set of Distribution Point's solutions
      for (ER_Solution_Line_Item__c dpli2 : dPoint.Solution_Line_Items__r) {
        dPointSolutions.add(dpli2.ER_Solution__c);
      }

      //Build a Map of Delivery Site's solutions with Delivery Site Line Items
      for (ER_Solution_Line_Item__c dsli : dslisDeliverySite.get(dPoint.ER_Delivery_Site__c)) {
        //dsliSolutions.put(dsli.ER_Solution__c, dsli.Id);
        dsliSolutionsMap.put(dsli.ER_Solution__c, dsli);
      }

      //check if the distribution point has all company's solutions
      for (String activeSolution : allActiveSolutions) {
        if (!dPointSolutions.contains(activeSolution)) {
          dpli = new ER_Solution_Line_Item__c();
          dpli.ER_Solution__c = activeSolution;
          dpli.ER_Distribution_Point__c = dPoint.Id;
          dpli.ER_Contract__c = contract.Id;
          //dpli.ER_Parent_Line_Item__c = dsliSolutions.get(activeSolution);
          dpli.ER_Parent_Line_Item__c = dsliSolutionsMap.get(activeSolution)?.Id;
          dpli.RecordTypeId = Schema.SObjectType.ER_Solution_Line_Item__c.getRecordTypeInfosByDeveloperName()
            .get('ER_Distribution_Point_Line_Item')
            .getRecordTypeId();
          //dpli.ER_Status__c = Label.LAB_SF_SolutionLineItem_Undefined;
          dpli.ER_Status__c = dsliSolutionsMap.get(activeSolution)?.ER_Status__c;
          dpli.ER_BUPicklist__c = dPoint.ER_BUPicklist__c;
          dpliListToInsert.add(dpli);
        }
      }
      //get all solutions to be updated from distribution point
      solutionSetToUpdate.addAll(dPointSolutions);
      solutionSetToUpdate.retainAll(allActiveSolutions);
    }

    if (!dpliListToInsert.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'dpliList to insert : ' + dpliListToInsert);
      insert dpliListToInsert;
    }

    if (!solutionSetToUpdate.isEmpty()) {
      System.debug(LoggingLevel.DEBUG, 'solutionSetToDelete : ' + solutionSetToUpdate);
      updateDistributionPointLineItemsForAccount(solutionSetToUpdate, contract.Id, contract.AccountId, contract.Status);
    }

    System.debug(LoggingLevel.DEBUG, 'manageDPLIFromContract END'); */
  }

  public static Map<String, ER_Promo_Code__c> getPromoCode(String BU) {
    Map<String, ER_Promo_Code__c> promoCodeMap = new Map<String, ER_Promo_Code__c>();

    for (ER_Promo_Code__c promo : [
      SELECT Id, ER_Promo_Code__c, ER_Business_Unit__c, ER_Contract__c, RecordType.DeveloperName
      FROM ER_Promo_Code__c
      WHERE ER_Status__c = 'Activated' AND ER_Business_Unit__c = :BU
    ]) {
      promoCodeMap.put(promo.ER_Promo_Code__c, promo);
    }
    return promoCodeMap;
  }

  @AuraEnabled
  public static void saveToFile(String merchantInfosJSON) {
    System.debug('>>> saveToFile *** Start *** merchantInfosJSON: ' + merchantInfosJSON);

    if (!String.isBlank(merchantInfosJSON)) {
      Map<String, Object> merchantInfos = (Map<String, Object>) JSON.deserializeUntyped(merchantInfosJSON);
      String fileTitle =
        String.valueOf(merchantInfos.get('countryCode')) + String.valueOf(merchantInfos.get('enterpriseNb'));
      String parentId = String.valueOf(merchantInfos.get('leadId'));
      if (String.isBlank(parentId))
        parentId = String.valueOf(merchantInfos.get('accountId'));
      Blob textBlob = Blob.valueOf(merchantInfosJSON);

      System.debug('>>>> saveToFile - fileTitle = ' + fileTitle);
      List<Attachment> atcList = [SELECT Id FROM Attachment WHERE Name = :fileTitle];

      Attachment atc = new Attachment(
        Body = textBlob,
        Name = fileTitle,
        ParentId = parentId,
        Description = 'Autoenrollment'
      );
      if (!atcList.isEmpty())
        atc.Id = atcList[0].Id; // Set Id in case of existing file to update it
      upsert atc;
      System.debug('>>>> saveToFile - upsert done. Id = ' + atc.Id);
    }
    System.debug('>>> saveToFile *** End ***');
  }

  // Get onboarding URL
  @AuraEnabled
  public static Map<String, String> getFileDatas(String keyId) {
    System.debug('>>> getFileDatas *** START *** - keyId: ' + keyId);
    Map<String, String> resultMap = new Map<String, String>();

    // Get external ref and accountId from lead using the account keyId external reference provided in the onboarding url
    List<Lead> ldList = [
      SELECT ER_External_Reference__c, ConvertedAccountId
      FROM Lead
      WHERE ConvertedAccount.ER_External_Reference__c = :keyId
    ];
    resultMap.put('accountId', ldList[0].ConvertedAccountId);

    List<Attachment> atcList = [SELECT Body FROM Attachment WHERE Name = :ldList[0].ER_External_Reference__c];
    String merchantJSON = EncodingUtil.base64Decode(EncodingUtil.base64Encode(atcList[0].Body)).toString();
    resultMap.put('merchantJSON', merchantJSON);
    System.debug('>>> getFileDatas - Merchant JSON: ' + merchantJSON);
    return resultMap;
  }

  // Get onboarding URL
  @AuraEnabled
  public static String getOnboardingURL(String keyId, String countryCode, String langCode, String solution) {
    String onBoardingURL = getOnboardingURL(countryCode, langCode, solution);
    return onBoardingURL += '&v=2&key=' + keyId;
  }

  // Get onboarding URL
  @AuraEnabled
  public static String getOnboardingURL(
    String keyId,
    String crn,
    String countryCode,
    String langCode,
    String solution
  ) {
    System.debug('>>> getOnboardingURL *** START ***');

    // Get portal base URL
    Network portalNetwork = [SELECT Id FROM Network WHERE Name = 'Edenred portal'];
    String portalBaseURL = Network.getLoginUrl(portalNetwork.id).substringBeforeLast('/login');

    Map<String, Map<String, String>> pklistMap = APER30_AutoEnrollment_Management.getPicklistInfos(
      countryCode,
      langCode,
      null
    );
    String locale = pklistMap.get('pk_locale_list').get(langCode);
    String onBoardingURL;
    if (countryCode == 'LU' || countryCode == 'BE') {
      onBoardingURL =
        portalBaseURL +
        '/autoenrollment-' +
        countryCode.toLowerCase() +
        '?language=' +
        locale +
        '&product=' +
        solution;
    } else if (countryCode == 'FI') {
      onBoardingURL =
        portalBaseURL +
        '/auto-enrollment-onboarding-' +
        countryCode.toLowerCase() +
        '?language=' +
        locale +
        '&scope=M' +
        '&crn=' +
        crn +
        '&product=' +
        solution;
    }
    return onBoardingURL;
  }

  @AuraEnabled
  public static String getOnboardingURL(String countryCode, String langCode, String solution) {
    return getOnboardingURL(null, null, countryCode, langCode, solution);
  }

  /**
   * @author KHAD
   * @date 13/06/2022
   * @param contactRoleToDelete
   */
  public static void deleteContactRoles(List<ER_Contact_Role__c> contactRoleToDelete) {
    delete contactRoleToDelete;
  }

  /**
   * @author KHAD
   * @date 05/07/2022
   * @param contactRoleToUpdate
   */
  public static void UpdateContactRoles(List<ER_Contact_Role__c> contactRoleToUpdate) {
    update contactRoleToUpdate;
  }

  /**
   * @author AAM
   * @date 20/06/2022
   * @desc : For autoenrollment onboarding, get users informations (all contacts linked to an account)
   * @param accountId
   */
  @AuraEnabled
  public static List<Map<String, String>> getUsersInfos(String accountId, String contractId) {
    List<Map<String, String>> resultMapList = new List<Map<String, String>>();
    Set<ID> fcCntIdSet = new Set<ID>();
    // Get users from contact of financial centers or those who are linked to the onboarding contract
    for (ER_Financial_Center__c fc : [
      SELECT Id, ER_Contact__c
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c = :accountId
    ])
      fcCntIdSet.add(fc.ER_Contact__c);
    System.debug('>>> getUsersInfos fcCntIdSet: ' + fcCntIdSet);

    for (Contact ct : [
      SELECT Id, Salutation, FirstName, LastName, Email, ER_Language__c, ER_Onboarding_Contract__c
      FROM Contact
      WHERE ER_Onboarding_Contract__c = :contractId OR Id IN :fcCntIdSet
      ORDER BY FirstName, LastName
    ]) {
      Map<String, String> curContact = new Map<String, String>();
      String curContactName = ct.FirstName + ' ' + ct.LastName;

      curContact.put('userSFId', ct.Id);
      curContact.put('userName', curContactName);
      curContact.put('userEmail', ct.Email);
      curContact.put('contractId', String.valueOf(ct.ER_Onboarding_Contract__c));
      curContact.put('userSalutation', ct.Salutation);
      curContact.put('userFirstName', ct.FirstName);
      curContact.put('userLastName', ct.LastName);
      curContact.put('userLanguage', ct.ER_Language__c);

      resultMapList.add(curContact);
    }
    return resultMapList;
  }

  /**
   * @author AAM
   * @date 20/06/2022
   * @desc : For autoenrollment onboarding, agregate all structure datas for a merchant
   * @param keyId
   */
  @AuraEnabled
  public static Map<String, Object> getOnBoardingDatas(String accountId, String contractId) {
    System.debug('>>> getOnBoardingDatas ***START*** accountId: ' + accountId + ' contractId: ' + contractId);
    Map<String, Object> curStructure = new Map<String, Object>();
    List<Map<String, String>> finCentersList = GenericWithoutSharing.getFinCentersInfos(accountId);
    List<Map<String, Object>> storesList = GenericWithoutSharing.getStoresInfos(accountId, 'FR');

    // List<Map<String,String>> usersList = GenericWithoutSharing.getUsersInfos(accountId, contractId);
    // System.debug('>>> getOnBoardingDatas - usersList Nb ' + usersList.size());

    // curStructure.putAll(enterpriseInfosMap);
    curStructure.put('finCentersList', finCentersList);
    curStructure.put('storesList', storesList);
    // curStructure.put('usersList', usersList);

    System.debug('>>> getOnBoardingDatas - curStructure: ' + curStructure.toString());
    return curStructure;
  }

  /**
   * @author AAM
   * @date 20/06/2022
   * @desc : For autoenrollment onboarding, check if existing Draft contract
   * @param enterpriseNb
   * @param contractNb
   *
   * @return
   */
  @AuraEnabled
  public static Boolean checkContractNb(String enterpriseNb, String contractNb, String solutionCode) {
    return (![
        SELECT Id
        FROM OpportunityLineItem
        WHERE
          Opportunity.Contract.ContractNumber = :contractNb
          AND (Opportunity.Account.ER_Registration_Number__c = :enterpriseNb
          OR Opportunity.Account.ER_Other_Fiscal_ID__c = :enterpriseNb)
          AND Product2.ER_Solution__r.ProductCode = :solutionCode
          AND Opportunity.Contract.Status = 'Draft'
      ]
      .isEmpty());
  }

  @AuraEnabled
  public static String checkEmailAndContractNb(String enterpriseNb, String contractNb, String email) {
    // SLI 3443
    if (enterpriseNb == null || contractNb == null) {
      return 'Wrong contract';
    }
    List<Opportunity> opportunities = [
      SELECT Id, Account.HU_HQ_Contact__r.Email
      FROM Opportunity
      WHERE
        Contract.ContractNumber = :contractNb
        AND (Account.ER_Registration_Number__c = :enterpriseNb
        OR Account.ER_Other_Fiscal_ID__c = :enterpriseNb)
    ];

    if (opportunities.isEmpty()) {
      return 'Wrong contract';
    }

    for (Opportunity anOpportunity : opportunities) {
      if (anOpportunity.Account.HU_HQ_Contact__r.Email == email) {
        return 'Success';
      }
    }
    return 'Wrong email';
  }

  /**
   * @author AAZ
   * @date 08/12/2022
   * @description Return the last customer number
   * @return
   */
  public static String getLastCustomerNumberSequence() {
    List<Account> accounts = [
      SELECT ER_Customer_Number__c
      FROM Account
      WHERE RecordType.DeveloperName = :Constants.ACCOUNT_COMPANY_RT AND ER_Customer_Number__c != NULL
      ORDER BY ER_Customer_Number__c DESC
      LIMIT 1
    ];
    if (!accounts.isEmpty() && String.isNotBlank(accounts[0].ER_Customer_Number__c))
      return accounts[0].ER_Customer_Number__c;
    else
      return '00000000';
  }

  /**
   * @author AAZ
   * @description Unlock Approval Record
   * @param recordId
   */
  public static void unLockApprovalRecord(Id recordId) {
    if (recordId != null) {
      System.debug(
        '>>>>> ALK - unLockApprovalRecord recordId : ' +
        recordId +
        ' - isLocked : ' +
        Approval.isLocked(recordId)
      );
      if (Approval.isLocked(recordId))
        Approval.unlock(recordId);
    }
  }

  /**
   * @author AAZ
   * @description Update the Zuora Approval Status to be used later in the other transaction to unlock the ZQuote record
   * @param quotes
   * @param oldItems
   */
  public static void updateZuoraApprovalStatus(List<zqu__Quote__c> quotes, Map<Id, zqu__Quote__c> oldItems) {
    List<zqu__Quote__c> quotesToBeUpdated = new List<zqu__Quote__c>();

    for (zqu__Quote__c q : quotes) {
      if (
        oldItems != null &&
        q.ER_Has_Discount_Requires_Approval__c != oldItems.get(q.Id).ER_Has_Discount_Requires_Approval__c &&
        q.ER_SmartER_Context__c
      ) {
        if (q.ER_Has_Discount_Requires_Approval__c)
          quotesToBeUpdated.add(new zqu__Quote__c(Id = q.Id, zqu__ApprovalStatus__c = Constants.ZQUOTE_IN_PROGRESS));
      }
    }

    if (!quotesToBeUpdated.isEmpty()) {
      Database.SaveResult[] results = Database.update(quotesToBeUpdated, false);
      Set<Id> quoteIds = new Set<Id>();
      for (Database.SaveResult sr : results) {
        if (sr.isSuccess())
          quoteIds.add(sr.getId());
      }

      if (!quoteIds.isEmpty())
        unLockZQuoteRecords(quoteIds);
    }
  }

  /**
   * @author AAZ
   * @description Unlock the ZQuote record if locked
   * @param ids
   */
  @Future
  public static void unLockZQuoteRecords(Set<Id> ids) {
    if (!ids.isEmpty()) {
      for (Id qId : ids)
        unLockApprovalRecord(qId);
    }
  }

  public static String getWebserviceResponse(String countryCode, String companyNb) {
    Map<String, String> paramWSMap = new Map<String, String>();
    for (Auto_Enrollment__mdt ae : [
      SELECT Label, Value__c
      FROM Auto_Enrollment__mdt
      WHERE Country_Code__c = :countryCode AND Label LIKE 'pr_%'
    ]) {
      paramWSMap.put(ae.Label, ae.Value__c);
    }

    HttpRequest req = new HttpRequest();

    String endpoint =
      paramWSMap.get('pr_endpoint') +
      '/?country=FI&fields=' +
      PublicRegister_FI.FIELD_TO_QUERY +
      '&business_id=' +
      companyNb;
    req.setEndpoint(endpoint);

    req.setHeader('Authorization', decryptData('AES256', paramWSMap.get('pr_key'), paramWSMap.get('pr_auth')));
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept-Encoding', 'gzip, deflate, br');
    req.setHeader('Accept', '*/*');
    req.setMethod('GET');

    Http http = new Http();
    HttpResponse res = http.send(req);
    if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
      throw new ApplicationException(Label.LAB_SF_PublicRegister_NoData.replace('{0}', companyNb));
    System.debug(res.getBody());
    return res.getBody();
  }

  //TODO to be moved to utils?
  public static String decryptData(String encryptionAlgo, String encryptionKey, String bodyToDecrypt) {
    Blob toBeDecrypted = EncodingUtil.base64Decode(bodyToDecrypt);
    Blob key = EncodingUtil.base64Decode(encryptionKey);
    Crypto.decryptWithManagedIV(encryptionAlgo, key, toBeDecrypted);
    Blob decrypted = Crypto.decryptWithManagedIV(encryptionAlgo, key, toBeDecrypted);
    return decrypted.toString();
  }

  /**
   * @author AAM
   * @date 04/04/2023
   * @description Get additional product names using a set of product Codes
   * @param Map of product codes with their names
   * @return
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, String> getProductListNames(String buCode) {
    Map<String, String> resultMap = new Map<String, String>();
    Set<String> autoEnrollmentProductSet = new Set<String>();
    for (Auto_Enrollment_Product__mdt aep : [SELECT Label FROM Auto_Enrollment_Product__mdt])
      autoEnrollmentProductSet.add(aep.Label);

    for (Product2 prod : [
      SELECT Id, ProductCode, Name
      FROM Product2
      WHERE
        ER_Type__c = 'Solution'
        AND IsActive = TRUE
        AND ER_BUPicklist__c = :buCode
        AND ProductCode = :autoEnrollmentProductSet
    ]) {
      resultMap.put(prod.ProductCode, prod.Name);
    }
    return resultMap;
  }

  @AuraEnabled
  public static Map<String, String> getCompanyInfosCore(
    String enterpriseNb,
    String country,
    String lang,
    String solutionCode,
    String scopeFlow,
    Boolean crossSelling,
    Boolean isOnBoarding
  ) {
    Map<String, String> resultMap = new Map<String, String>();

    String accountId, solutionId, promoCode, contractId;
    String businessUnit = Utils.getBUCode(country);
    String oppRecType;
    String ldRecType;
    String ctrRecTypId;
    Id companyRT = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, Constants.ACCOUNT_COMPANY_RT);
    String scopeName = (scopeFlow == 'C') ? Constants.CLIENT : Constants.MERCHANT;
    String extRef = businessUnit + '_' + scopeName + '_AutoEnrollment_' + solutionCode + '_' + enterpriseNb;
    String curDraftContract;
    String activeProductsCsv = '';
    String ongoingOppProductsCsv = '';

    if (isOnBoarding == null)
      isOnBoarding = false;

    if (scopeFlow == 'M') {
      oppRecType = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, Constants.OPPORTUNITY_MERCHANT_RT);
      ldRecType = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_MERCHANT_RT);
      ctrRecTypId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_MERCHANT_RT);
    } else if (scopeFlow == 'C') {
      oppRecType = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, Constants.OPPORTUNITY_CLIENT_RT);
      ldRecType = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT);
      ctrRecTypId = Utils.getRecordTypeIdByDeveloperName(Contract.SObjectType, Constants.CONTRACT_CLIENT_RT);
    } else {
      resultMap.put('invalidScope', 'true');
    }

    List<Account> existingAccountList = new List<Account>();
    List<Opportunity> oppList = new List<Opportunity>();
    List<Contract> ctrCurScopeList = new List<Contract>();

    // Check if existing account, if yes then add parameter in the map to edit account in "read-only" (only few informations will be editable)
    // ER_Enterprise_Number__c is not a unique field, so we bring the last one modified in case of several account returned

    System.debug('>>> getCompanyInfosCore -- enterpriseNb: ' + enterpriseNb);
    System.debug('>>> getCompanyInfosCore -- businessUnit: ' + businessUnit);

    existingAccountList = [
      SELECT
        Id,
        Name,
        Phone,
        ER_Legal_Form__c,
        ER_Legal_Name__c,
        BillingCity,
        BillingPostalCode,
        BillingStreet,
        BillingCountry,
        ER_Not_subject_to_VAT__c,
        ER_VAT_Number__c,
        ER_Registration_Number__c,
        ER_Country_Code__c,
        HU_HQ_Contact__c,
        HU_HQ_Contact__r.Salutation,
        HU_HQ_Contact__r.FirstName,
        HU_HQ_Contact__r.LastName,
        HU_HQ_Contact__r.Email,
        HU_HQ_Contact__r.Phone,
        HU_HQ_Contact__r.MobilePhone,
        HU_HQ_Contact__r.Fax,
        HU_HQ_Contact__r.ER_Language__c,
        HU_HQ_Contact__r.ER_Role__c,
        ER_External_Reference__c,
        NumberOfEmployees,
        ER_Status__c,
        ER_BUPicklist__c
      FROM Account
      WHERE ER_Registration_Number__c = :enterpriseNb AND RecordTypeId = :companyRT AND ER_BUPicklist__c = :businessUnit
      ORDER BY LastModifiedDate DESC
    ];
    if (!existingAccountList.isEmpty()) {
      accountId = existingAccountList[0].Id;
      resultMap.put('existingAccount', 'true');
      resultMap.put('accountId', existingAccountList[0].Id);

      // Check if Merchant has store for Finland :
      if (
        scopeFlow == 'M' &&
        country == 'FI' &&
        ![
            SELECT id
            FROM ER_Store__c
            WHERE ER_Merchant__c = :existingAccountList[0].Id AND ER_Status__c = :Constants.ACTIVE
          ]
          .isEmpty()
      ) {
        resultMap.put('existingMerchantStore', 'true');
      }
    }

    System.debug('>>> getCompanyInfosCore -- existingAccountList size: ' + existingAccountList.size());

    //TODO to be reviewed, as no need to query leads if existing accounts
    // String extRef = country + enterpriseNb;
    // System.debug('>>> getCompanyInfosCore -- extRef: ' + extRef);
    List<Lead> existingLeadList = new List<Lead>();
    Boolean hasOtherSolutionLead = false;
    String contractsJSON;

    // Check if current lead with same scope and solution
    if (existingAccountList.isEmpty()) {
      existingLeadList = [
        SELECT
          Id,
          Company,
          Phone,
          ER_Legal_Form__c,
          ER_Legal_Name__c,
          ER_Legal_Street__c,
          ER_Legal_Zip_Code__c,
          ER_Legal_City__c,
          ER_Legal_Country__c,
          ER_VAT_Number__c,
          Salutation,
          FirstName,
          LastName,
          ER_Language__c,
          MobilePhone,
          ER_Role__c,
          Email,
          Fax,
          NumberOfEmployees,
          ERBE_Initial_Product_Of_Interest__c,
          ERBE_Initial_Product_Of_Interest__r.ProductCode,
          ER_External_Reference__c,
          ER_Country_Code__c
        FROM Lead
        WHERE
          ER_Registration_Number__c = :enterpriseNb
          AND ER_BUPicklist__c = :businessUnit
          AND RecordTypeId = :ldRecType
        ORDER BY LastModifiedDate DESC
      ];

      for (Lead ld : existingLeadList)
        if (ld.ER_External_Reference__c != extRef)
          hasOtherSolutionLead = true;
      if (hasOtherSolutionLead) {
        resultMap.put('ongoingOpp', 'true');
        return resultMap;
      }
    } else {
      //AAM 12.06.23 Exclude cross selling context
      // Check if active client contract or active client opp
      System.debug('>>> getCompanyInfosCore -- Existing company - Id: ' + existingAccountList[0].Id);
      String countryCode = existingAccountList[0].ER_Country_Code__c;
      String regNb = existingAccountList[0].ER_Registration_Number__c;
      if (String.isBlank(accountId))
        accountId = existingAccountList[0].Id;
      List<Lead> leadList = [SELECT id FROM Lead WHERE ConvertedAccountId = :existingAccountList[0].Id];
      String leadId = '';
      if (!leadList.isEmpty())
        leadId = leadList[0].Id; // Do not set leadId in Weboffer context

      // List<OpportunityLineItem> ctList;
      // ctList = [
      //   SELECT
      //     Id,
      //     Opportunity.ContractId,
      //     Opportunity.Contract.ContractNumber,
      //     Opportunity.Contract.Status,
      //     Product2.ER_Solution__r.Name,
      //     Product2.ER_Solution__r.ProductCode,
      //     Opportunity.Contract.ER_QuoteId__r.ER_Main_Solution__r.ProductCode,
      //     Opportunity.Contract.ER_QuoteId__r.Status,
      //     Opportunity.Contract.ER_QuoteId__r.ER_Web_Offer_URL__c
      //   FROM OpportunityLineItem
      //   WHERE Opportunity.AccountId = :accountId AND Opportunity.RecordTypeId = :oppRecType
      //   ORDER BY Opportunity.Contract.Status
      // ];
      System.debug('>>> getCompanyInfosCore -- solutionId: ' + solutionId);
      // System.debug('>>> getCompanyInfosCore -- ctList size: ' + ctList.size());

      //For Finland and Spain, check if ongoing opp and no active contract
      oppList = [
        SELECT Id, ER_Solutions__c, LeadSource, ContractId, Contract.Status, IsClosed
        FROM Opportunity
        WHERE AccountId = :accountId AND IsClosed = FALSE AND RecordTypeId = :oppRecType
      ]; // SLI 3443

      for (Opportunity opp : oppList) {
        if (!opp.IsClosed && opp.ER_Solutions__c != null)
          ongoingOppProductsCsv += opp.ER_Solutions__c?.replace(' / ', ',') + ',';
      }

      List<Contract> ctrSolutionList = new List<Contract>();
      contractsJSON = '[';

      for (Contract ctr : [
        SELECT Id, ER_Solutions__c, RecordTypeId, Status, RecordType.Name, Pricebook2.ER_MDMId__c
        FROM Contract
        WHERE AccountId = :accountId AND Status IN ('Draft', 'Activated')
      ]) {
        if (
          !String.isBlank(ctr.ER_Solutions__c) &&
          !String.isBlank(solutionCode) &&
          ctr.ER_Solutions__c.contains(solutionCode)
        ) {
          if (ctr.Status == 'Activated')
            ctrSolutionList.add(ctr);
          if (ctr.Status == 'Draft')
            curDraftContract = ctr.Id;
        }
        if (ctr.RecordTypeId == ctrRecTypId && ctr.Status == 'Activated')
          ctrCurScopeList.add(ctr);

        if (ctr.Status == 'Activated')
          activeProductsCsv += ctr.ER_Solutions__c?.replace(' / ', ',') + ',';

        if (contractsJSON.length() > 1)
          contractsJSON += ', ';
        contractsJSON +=
          '{"Id": "' +
          ctr.Id +
          '", "Type": "' +
          ctr.RecordType.Name +
          '", "Status": "' +
          ctr.Status +
          '", "Pricebook": "' +
          ctr.Pricebook2.ER_MDMId__c +
          '", "Solutions": "' +
          ctr.ER_Solutions__c +
          '"}';
      }
      contractsJSON += ']';

      System.debug('>>> getCompanyInfosCore -- contractsJSON: ' + contractsJSON);
      /*// Used by cross celling checks !
      if (!ctrSolutionList.isEmpty()) {
        resultMap.put('activeProduct', 'true');
      }
      if (!oppList.isEmpty() && ctrSolutionList.isEmpty()) {
        resultMap.put('ongoingOpp', 'true');
      }
      if ((!oppList.isEmpty() || !ctrCurScopeList.isEmpty()) && !isOnBoarding && !crossSelling) {
        // SLI 3443
        resultMap.put('existingClient', 'true');
      }
      // Cross selling end*/

      if (!isOnBoarding && scopeFlow == 'M') {
        Boolean shouldOnboard = checkOnboarding(oppList, solutionCode);

        if (shouldOnboard) {
          // SLI 3443
          System.debug('>>> getCompanyInfosCore -- shouldOnboard');
          resultMap.put('shouldOnboard', 'true');
          return resultMap;
        }
      }

      if ((!oppList.isEmpty() || !ctrCurScopeList.isEmpty()) && !isOnBoarding && !crossSelling) {
        // SLI 3443
        System.debug('>>> getCompanyInfosCore -- existingClient');
        resultMap.put('existingClient', 'true');
        return resultMap;
      }

      if (!oppList.isEmpty() && ctrSolutionList.isEmpty()) {
        System.debug('>>> getCompanyInfosCore -- ongoingOpp');
        resultMap.put('ongoingOpp', 'true');
        if (!isOnBoarding && !crossSelling)
          return resultMap;
      }

      if (!ctrSolutionList.isEmpty()) {
        resultMap.put('activeProduct', 'true');
        return resultMap;
      }
    }

    if (!String.isBlank(solutionCode)) {
      String solutionName = APER32_Product2_Management.getSolutionName(solutionCode, businessUnit);
      resultMap.put('mainSolutionName', solutionName);

      if (solutionName == null || solutionName == '') {
        resultMap.put('solutionNotListedInProducts', 'true');
      }
    }

    // if(existingAccountList.isEmpty() && existingLeadList.isEmpty() && !String.isBlank(enterpriseNb)) {
    if (
      oppList.isEmpty() &&
      ctrCurScopeList.isEmpty() &&
      !String.isBlank(enterpriseNb) &&
      (!crossSelling || existingAccountList.isEmpty())
    ) {
      if (country == 'FI') {
        // Get product infos
        if (!String.isBlank(solutionCode)) {
          resultMap.put('mainSolutionName', APER32_Product2_Management.getSolutionName(solutionCode, businessUnit));
          List<Product2> serviceList = APER32_Product2_Management.getSolutionServices(solutionCode);
          //TODO to be reviewed in further user stories
          Set<String> virtualCardsServiceSet = new Set<String>{
            'ERFI_C_TTR_EUR_NEW_CRD_VIRT',
            'ERFI_C_DENT_EUR_NEW_CRD_VIRT',
            'ERFI_C_MASS_EUR_NEW_CRD_VIRT'
          };
          for (Product2 prod : serviceList) {
            if (virtualCardsServiceSet.contains(prod.ProductCode))
              resultMap.put('isVirtualCard', 'true');
          }
        }

        PublicRegister register = new PublicRegister('FI');
        String jsonResponseTest = '{"results": [{"status": "inactive", "postal": "37860", "company_name": "Jave-tech Oy", "business_id": "23134036", "form_of_company": "Osakeyhtiö", "address": "Palokunnantie 9", "city": null, "vat_number": "FI23134036", "staff_number": 4}]}';
        String jsonResponse = Test.isRunningTest() ? jsonResponseTest : getWebserviceResponse(country, enterpriseNb);
        Map<String, String> wsValues = register.mapResponse(jsonResponse);

        String status = wsValues.get('ER_Legal_Status__c');

        if (status.toLowerCase() != 'inactive') {
          resultMap.put('isReadOnly', 'false');
          resultMap.put('legalName', wsValues.get('Name'));
          resultMap.put('address', wsValues.get('ER_Legal_Street__c'));
          resultMap.put('postalCode', wsValues.get('ER_Legal_Zip_Code__c'));
          resultMap.put('city', wsValues.get('ER_Legal_City__c'));
          resultMap.put('country', wsValues.get('ER_Legal_Country__c'));
          resultMap.put('countryCode', wsValues.get('ER_Legal_Country_Code__c').toUpperCase());
          resultMap.put('numberEmployees', wsValues.get('ER_Employee_Size_Range__c'));
          if (!String.isBlank(wsValues.get('ER_VAT_Number__c')))
            resultMap.put('enterpriseVATCode', wsValues.get('ER_VAT_Number__c'));
        } else {
          System.debug('>>> getCompanyInfosCore -- inactive status');
          resultMap.put('inactive', 'true');
          return resultMap;
        }
      }
    } else if (!existingAccountList.isEmpty()) {
      resultMap.put('isReadOnly', 'false');
      resultMap.put('legalName', existingAccountList[0].ER_Legal_Name__c);
      resultMap.put('companyName', existingAccountList[0].Name);
      resultMap.put('address', existingAccountList[0].BillingStreet);
      resultMap.put('postalCode', existingAccountList[0].BillingPostalCode);
      resultMap.put('city', existingAccountList[0].BillingCity);
      resultMap.put('countryCode', existingAccountList[0].ER_Country_Code__c);

      String countryAccount = existingAccountList[0].BillingCountry;
      if (String.isBlank(countryAccount))
        countryAccount = existingAccountList[0].ER_Country_Code__c;
      resultMap.put('country', countryAccount);

      resultMap.put('numberEmployees', String.valueOf(existingAccountList[0].NumberOfEmployees));
      resultMap.put('enterpriseVATCode', existingAccountList[0].ER_VAT_Number__c);
      resultMap.put('firstName', existingAccountList[0].HU_HQ_Contact__r.FirstName);
      resultMap.put('lastName', existingAccountList[0].HU_HQ_Contact__r.LastName);
      resultMap.put('email', existingAccountList[0].HU_HQ_Contact__r.Email);

      String contactPhone = existingAccountList[0].HU_HQ_Contact__r.MobilePhone;
      if (String.isBlank(contactPhone))
        contactPhone = existingAccountList[0].HU_HQ_Contact__r.Phone;
      resultMap.put('contactPhone', contactPhone);

      resultMap.put('lang', existingAccountList[0].HU_HQ_Contact__r.ER_Language__c);
      resultMap.put('accountId', existingAccountList[0].Id);
      resultMap.put('contractId', curDraftContract);
      resultMap.put('contactId', existingAccountList[0].HU_HQ_Contact__c);
      resultMap.put('activeProductsCsv', activeProductsCsv);
      resultMap.put('ongoingOppProductsCsv', ongoingOppProductsCsv);
      if (scopeFlow == 'M' && crossSelling) {
        List<ER_Financial_Center__c> fcList = [
          SELECT
            ER_Bank_Account__r.ER_IBAN__c,
            ER_Bank_Account__r.ER_BIC__c,
            ERFI_OVT_Code__c,
            ERFI_OVT_Operator__c,
            ER_Preferred_Invoicing_Method__c
          FROM ER_Financial_Center__c
          WHERE ER_Account_Name__c = :accountId AND ER_Master__c = TRUE AND ER_Type__c = :Constants.FC_MERCHANT_TYPE
          ORDER BY LastModifiedDate ASC
        ];
        if (!fcList.isEmpty()) {
          resultMap.put('ovtCode', fcList[0].ERFI_OVT_Code__c);
          resultMap.put('ovtOperator', fcList[0].ERFI_OVT_Operator__c);
          resultMap.put('IBAN', fcList[0].ER_Bank_Account__r.ER_IBAN__c);
          resultMap.put('BIC', fcList[0].ER_Bank_Account__r.ER_BIC__c);
          resultMap.put('Invoicing method', fcList[0].ER_Preferred_Invoicing_Method__c);
        }
      }
      resultMap.put('contractsJSON', contractsJSON);
      resultMap.put('businessUnit', existingAccountList[0].ER_BUPicklist__c);
    } else if (!existingLeadList.isEmpty()) {
      resultMap.put('isReadOnly', 'false');
      resultMap.put('legalName', existingLeadList[0].ER_Legal_Name__c);
      resultMap.put('address', existingLeadList[0].ER_Legal_Street__c);
      resultMap.put('postalCode', existingLeadList[0].ER_Legal_Zip_Code__c);
      resultMap.put('city', existingLeadList[0].ER_Legal_City__c);
      resultMap.put('country', existingLeadList[0].ER_Legal_Country__c);
      resultMap.put('countryCode', existingLeadList[0].ER_Country_Code__c);
      resultMap.put('numberEmployees', String.valueOf(existingLeadList[0].NumberOfEmployees));
      resultMap.put('firstName', existingLeadList[0].FirstName);
      resultMap.put('lastName', existingLeadList[0].LastName);
      resultMap.put('email', existingLeadList[0].Email);
      resultMap.put('contactPhone', existingLeadList[0].Phone);
      resultMap.put('lang', existingLeadList[0].ER_Language__c);
    }
    System.debug('>>> getCompanyInfosCore -- resultMap: ' + resultMap);
    return resultMap;
  }

  /**
   * @param opportunities
   * @param solutionCode
   *
   * @return whether the account has an opportunity for the same webform's solution
   */
  private static Boolean checkOnboarding(List<Opportunity> opportunities, String solutionCode) {
    for (Opportunity anOpportunity : opportunities) {
      if (
        !String.isBlank(anOpportunity.ER_Solutions__c) &&
        !String.isBlank(solutionCode) &&
        anOpportunity.ER_Solutions__c.contains(solutionCode) &&
        anOpportunity.LeadSource == Constants.CONTRACTING_WEBFORM &&
        anOpportunity.ContractId != null &&
        anOpportunity.Contract.Status == Constants.DRAFT
      ) {
        return true;
      }
    }
    return false;
  }

  @AuraEnabled
  public static Map<String, String> upsertLeadCore(String companyInfosJSON) {
    Map<String, String> result = new Map<String, String>();

    System.debug('>>> GenericWithoutSharing upsertLeadCore -- companyInfosJSON: ' + companyInfosJSON);

    if (!String.isBlank(companyInfosJSON)) {
      Map<String, Object> companyInfos = (Map<String, Object>) JSON.deserializeUntyped(companyInfosJSON);
      String leadId,
        solutionId,
        solutionCode,
        countryCode,
        businessUnit,
        enterpriseNb,
        country,
        ownerId,
        scope,
        scopeName,
        recTypName;

      leadId = String.valueOf(companyInfos.get('leadId'));
      countryCode = String.valueOf(companyInfos.get('countryCode'));
      solutionCode = String.valueOf(companyInfos.get('solution'));
      scope = String.valueOf(companyInfos.get('scope'));
      solutionId = APER32_Product2_Management.getSolutionId(solutionCode);
      businessUnit = Utils.getBUCode(countryCode);
      enterpriseNb = String.valueOf(companyInfos.get('enterpriseNb'));
      country = String.valueOf(companyInfos.get('country'));
      ownerId = getUserIdByName('Data Finland'); //TODO Temporary, to be modified with further BUs

      recTypName = scope == 'C' ? Constants.LEAD_CLIENT_RT : Constants.LEAD_MERCHANT_RT;
      scopeName = scope == 'C' ? Constants.CLIENT : Constants.MERCHANT;

      ID leadRecTypId = Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, recTypName);

      System.debug('>>> GenericWithoutSharing upsertLeadCore -- countryCode : ' + countryCode);
      System.debug(
        '>>> GenericWithoutSharing upsertLeadCore -- solution : ' + String.valueOf(companyInfos.get('solution'))
      );
      System.debug('>>> GenericWithoutSharing upsertLeadCore -- scope : ' + String.valueOf(companyInfos.get('scope')));

      System.debug('>>> GenericWithoutSharing upsertLeadCore -- solutionId : ' + solutionId);
      System.debug('>>> GenericWithoutSharing upsertLeadCore -- businessUnit : ' + businessUnit);
      Lead companyLead = new Lead(
        ER_Registration_Number__c = enterpriseNb,
        ER_Legal_Name__c = String.valueOf(companyInfos.get('legalName')),
        LastName = (String.valueOf(companyInfos.get('lastName')) == null
          ? String.valueOf(DateTime.now().getTime())
          : String.valueOf(companyInfos.get('lastName'))),
        FirstName = String.valueOf(companyInfos.get('firstName')),
        Status = Constants.NEW_STATUS,
        ER_Lead_Channel__c = scopeName,
        ER_Lead_Type__c = scopeName,
        Rating = 'Hot',
        LeadSource = 'Contracting webform',
        ER_BUPicklist__c = businessUnit,
        RecordTypeId = leadRecTypId,
        ER_Legal_City__c = String.valueOf(companyInfos.get('city')),
        ER_Legal_Street__c = String.valueOf(companyInfos.get('address')),
        ER_Legal_Zip_Code__c = String.valueOf(companyInfos.get('postalCode')),
        ER_Legal_Country__c = country,
        city = String.valueOf(companyInfos.get('city')),
        street = String.valueOf(companyInfos.get('address')),
        postalCode = String.valueOf(companyInfos.get('postalCode')),
        country = country,
        ER_Language__c = String.valueOf(companyInfos.get('lang')),
        Salutation = 'Mx',
        Company = String.valueOf(companyInfos.get('legalName')),
        Phone = String.valueOf(companyInfos.get('contactPhone')),
        MobilePhone = String.valueOf(companyInfos.get('contactPhone')),
        Email = String.valueOf(companyInfos.get('email')),
        ER_VAT_Number__c = enterpriseNb,
        NumberOfEmployees = Integer.valueOf(companyInfos.get('numberEmployees')),
        ER_Country_Code__c = countryCode,
        ER_Legal_Country_Code__c = countryCode,
        ERBE_Initial_Product_Of_Interest__c = solutionId,
        ER_External_Reference__c = businessUnit +
          '_' +
          scopeName +
          '_AutoEnrollment_' +
          solutionCode +
          '_' +
          enterpriseNb,
        ER_OVT_Code__c = String.valueOf(companyInfos.get('ovtCode')),
        ER_OVT_Operator__c = String.valueOf(companyInfos.get('ovtOperator'))
      );

      if (!String.isBlank(ownerId) && countryCode == 'FI')
        companyLead.OwnerId = ownerId;

      if (
        !String.isBlank(companyLead.FirstName) &&
        !String.isBlank(companyLead.Email) &&
        !String.isBlank(companyLead.Phone)
      )
        companyLead.Status = 'Qualification';

      if (scope == 'M')
        companyLead.ER_Number_of_outlets__c = 0;

      // Database.DMLOptions dmo = new Database.DMLOptions();
      // if(String.isBlank(leadId)) dmo.assignmentRuleHeader.useDefaultRule = true;
      // companyLead.setOptions(dmo);

      System.debug('>>> GenericWithoutSharing upsertLeadCore -- companyLead.OwnerId : ' + companyLead.OwnerId);
      System.debug(
        '>>> GenericWithoutSharing upsertLeadCore -- ER_External_Reference__c : ' + companyLead.ER_External_Reference__c
      );

      if (String.isBlank(leadId)) {
        // AAM 14.06.23 This complex code is to avoid issues like fin center creation...
        Database.upsertResult upResult = Database.upsert(companyLead, Lead.ER_External_Reference__c, false);
        if (!upResult.isSuccess() && upResult.getErrors()[0].getStatusCode() == StatusCode.DUPLICATE_VALUE) {
          leadId = upResult.getErrors()[0].getMessage().substringAfter('id: ');
          companyLead.Id = leadId;
          System.debug('>>> GenericWithoutSharing upsertLeadCore -- getUserType() : ' + UserInfo.getUserType());
          if (UserInfo.getUserType() != 'AutomatedProcess')
            APER30_AutoEnrollment_Management.doApexEvent('upsertLeadCore', companyInfosJSON);
          else
            update companyLead;
        }
      } else {
        companyLead.Id = leadId;
        update companyLead;
      }

      System.debug('>>> GenericWithoutSharing upsertLeadCore -- lead upserted!! Id is : ' + companyLead.Id);

      result.put('leadId', companyLead.Id); // Informations to be returned to lwc form
    }
    return result;
  }

  /**
   * @author AAM
   * @date 13/04/2023
   * @description get user Id based on Name
   * @param user name
   *
   * @return user Id
   */
  public static String getUserIdByName(String userName) {
    List<User> userList = [SELECT Id FROM User WHERE Name = :userName];
    return !userList.isEmpty() ? userList[0].Id : null;
  }

  public static void updateQuoteNbOfStores(List<Quote> quoteListToUpdate) {
    update quoteListToUpdate;
  }

  // Encrypt a text // SLI => 3443
  @AuraEnabled
  public static String encrypt(String text) {
    if (text == null) {
      return '';
    }
    Blob key = EncodingUtil.base64Decode(encryptionSettings.Key__c);
    Blob data = Blob.valueOf(text);
    Blob encrypted = Crypto.encryptWithManagedIV(encryptionSettings.Algorithm__c, key, data);

    return EncodingUtil.base64Encode(encrypted);
  }

  // Decrypt a text // SLI => 3443
  @AuraEnabled
  public static String decrypt(String encryptedText) {
    //String value = EncodingUtil.urlDecode(encryptedText, 'UTF-8');
    Blob encryptedData = EncodingUtil.base64Decode(encryptedText);
    //Blob iv = Blob.valueOf(encryptionSettings.InitializationVector__c);
    Blob key = EncodingUtil.base64Decode(encryptionSettings.Key__c);
    //Blob decrypted = Crypto.decrypt(encryptionSettings.Algorithm__c, key, iv, encryptedData);
    Blob decrypted = Crypto.decryptWithManagedIV(encryptionSettings.Algorithm__c, key, encryptedData);
    System.debug(decrypted.toString());
    return decrypted.toString();
  }

  @AuraEnabled
  public static String getBreadcrumbs(Id recId) {
      String breadCrumbsJSON;
      if(String.isNotBlank(recId)) {
          switch on String.valueOf(recId.getSobjectType()) {
              when 'Account' {
                  Account acc = [SELECT Id, ER_Registration_Number__c, ER_BUPicklist__c FROM Account WHERE Id = :recId];
                  String t = encrypt(acc.Id);
                  breadCrumbsJSON =
                          '{"crn" : "' +
                                  acc.ER_Registration_Number__c +
                                  '", "bu" : "' +
                                  acc.ER_BUPicklist__c +
                                  '", "aId" : "' +
                                  acc.Id +
                                  '", "home" : "' +
                                  true +
                                  '"}';
              }
              when 'ER_Financial_Center__c' {
                  ER_Financial_Center__c fc = [
                          SELECT Id, Name, ER_Account_Name__c, ER_Account_Name__r.ER_Registration_Number__c, ER_BUPicklist__c
                          FROM ER_Financial_Center__c
                          WHERE Id = :recId
                  ];
                  breadCrumbsJSON =
                          '{"crn" : "' +
                                  fc.ER_Account_Name__r.ER_Registration_Number__c +
                                  '", "aId" : "' +
                                  fc.ER_Account_Name__c +
                                  '", "fcId" : "' +
                                  fc.Id +
                                  '", "fcName" : "' +
                                  fc.Name +
                                  '", "bu" : "' +
                                  fc.ER_BUPicklist__c +
                                  '"}';
              }
              when 'ER_Store__c' {
                  ER_Store__c s = [
                          SELECT
                                  Id, Name, ER_Financial_Center__c, ER_Financial_Center__r.Name, ER_Financial_Center__r.ER_Account_Name__c, ER_BUPicklist__c, ER_Financial_Center__r.ER_Account_Name__r.ER_Registration_Number__c
                          FROM ER_Store__c
                          WHERE Id = :recId
                  ];
                  breadCrumbsJSON =
                          '{"crn" : "' +
                                  s.ER_Financial_Center__r.ER_Account_Name__r.ER_Registration_Number__c +
                                  '", "aId" : "' +
                                  s.ER_Financial_Center__r.ER_Account_Name__c +
                                  '", "fcId" : "' +
                                  s.ER_Financial_Center__c +
                                  '", "fcName" : "' +
                                  s.ER_Financial_Center__r.Name +
                                  '", "stId" : "' +
                                  s.Id +
                                  '", "stName" : "' +
                                  s.Name +
                                  '", "bu" : "' +
                                  s.ER_BUPicklist__c +
                                  '"}';
              }
              when 'ER_Acceptor__c' {
                  ER_Acceptor__c a = [
                          SELECT
                                  Id, Name, ER_Store__c, ER_Store__r.Name, ER_Store__r.ER_Financial_Center__c, ER_MID_Authorization__c, ER_Store__r.ER_Financial_Center__r.Name, ER_BUPicklist__c, ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c, ER_Store__r.ER_Financial_Center__r.ER_Account_Name__r.ER_Registration_Number__c
                          FROM ER_Acceptor__c
                          WHERE Id = :recId
                  ];
                  breadCrumbsJSON =
                          '{"crn" : "' +
                                  a.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__r.ER_Registration_Number__c +
                                  '", "aId" : "' +
                                  a.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c +
                                  '", "fcId" : "' +
                                  a.ER_Store__r.ER_Financial_Center__c +
                                  '", "fcName" : "' +
                                  a.ER_Store__r.ER_Financial_Center__r.Name +
                                  '", "stId" : "' +
                                  a.ER_Store__c +
                                  '", "stName" : "' +
                                  a.ER_Store__r.Name +
                                  '", "aName" : "' +
                                  a.ER_MID_Authorization__c +
                                  '", "bu" : "' +
                                  a.ER_BUPicklist__c +
                                  '"}';
              }
          }
      }

    return breadCrumbsJSON;
  }

  /* *
   * Author : Dinesh Kumar Bussunt
   * Ticket : COUL-3721 && COUL-3722
   * Date : 06/06/223
   * Description : Fetches the Acceptor Data to edit in the LWC
   * Component : erPortalAcceptor
   */
  @AuraEnabled(Cacheable=true)
  public static ER_Acceptor__c getOnBoardingAcceptor(String acceptorId) {
    ER_Acceptor__c acceptorQueryObject = new ER_Acceptor__c();
    if (String.isNotBlank(acceptorId)) {
      acceptorQueryObject = [
        SELECT
          Id,
          Name,
          ER_MID__c,
          ER_MID_Authorization__c,
          ER_SubMID_Authorization__c,
          ER_Status__c,
          ER_Store__c,
          ER_BUPicklist__c
        FROM ER_Acceptor__c
        WHERE Id = :Id.valueOf(acceptorId)
      ];
    }

    return acceptorQueryObject;
  }
  /* *
   * Author : Dinesh Kumar Bussunt
   * Ticket : COUL-3721 && COUL-3722
   * Date : 06/06/223
   * Description : Updates the Acceptor Data from the LWC
   * Component : erPortalAcceptor
   */
  @AuraEnabled
  public static Boolean updateAcceptor(String acceptorId, String statusVal, String midAuth, String subMIDAuth) {
    Boolean isUpdateSuccessfull = false;
    try {
      if (String.isNotBlank(acceptorId)) {
        ER_Acceptor__c acceptorToUpdate = [
          SELECT Id, Name, ER_MID_Authorization__c, ER_SubMID_Authorization__c, ER_Status__c, ER_BUPicklist__c
          FROM ER_Acceptor__c
          WHERE Id = :Id.valueOf(acceptorId)
        ];
        acceptorToUpdate.ER_Status__c = statusVal;
        acceptorToUpdate.ER_MID_Authorization__c = midAuth;
        acceptorToUpdate.ER_SubMID_Authorization__c = subMIDAuth;
        APER30_AutoEnrollment_Management.syncRecordBU = acceptorToUpdate.ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)

        Database.SaveResult[] srList = Database.update(new List<ER_Acceptor__c>{ acceptorToUpdate }, true);
        for (Database.SaveResult sr : srList) {
          if (sr.isSuccess()) {
            isUpdateSuccessfull = true;
          } else {
            for (Database.Error err : sr.getErrors()) {
              System.debug('updateAcceptor : ' + err.getStatusCode() + ': ' + err.getMessage());
              System.debug('updateAcceptor : Acceptor fields that caused this error: ' + err.getFields());
            }
          }
        }
      }
    } catch (DmlException dmlExcept) {
      System.debug('updateAcceptor : The following exception has occurred: ' + dmlExcept.getMessage());
    }
    return isUpdateSuccessfull;
  }
  /* *
   * Author : Dinesh Kumar Bussunt
   * Ticket : COUL-3723
   * Date : 06/06/223
   * Description : Creates NEW Acceptor Data from the LWC
   * Component : erPortalAcceptor
   */
  @AuraEnabled
  public static String insertAcceptor(
    String parentId,
    String statusVal,
    String midAuth,
    String subMIDAuth,
    String parentBU
  ) {
    String createdAcceptorId = '';
    try {
      if (String.isNotBlank(parentId)) {
        ER_Acceptor__c acceptorToInsert = new ER_Acceptor__c();
        acceptorToInsert.Name = 'MUSAcceptor' + DateTime.now().getTime();
        acceptorToInsert.ER_Status__c = statusVal;
        acceptorToInsert.ER_MID_Authorization__c = midAuth;
        acceptorToInsert.ER_SubMID_Authorization__c = subMIDAuth;
        acceptorToInsert.ER_Store__c = Id.valueOf(parentId);
        acceptorToInsert.ER_BUPicklist__c = parentBU;
        if (statusVal == 'Active') {
          acceptorToInsert.ER_Start_Date__c = System.today();
        }

        List<ER_Store__c> stList = [SELECT ER_BUPicklist__c FROM ER_Store__c WHERE Id = :parentId];
        APER30_AutoEnrollment_Management.syncRecordBU = stList[0].ER_BUPicklist__c; // AAM 07.07.23 COUL-4145 (EDG Sync)

        Database.SaveResult[] srList = Database.insert(new List<ER_Acceptor__c>{ acceptorToInsert }, true);
        for (Database.SaveResult sr : srList) {
          if (sr.isSuccess()) {
            createdAcceptorId = String.valueOf(sr.getId());
          } else {
            for (Database.Error err : sr.getErrors()) {
              System.debug('insertAcceptor : ' + err.getStatusCode() + ': ' + err.getMessage());
              System.debug('insertAcceptor : Acceptor fields that caused this error: ' + err.getFields());
            }
          }
        }
      }
    } catch (DmlException dmlExcept) {
      System.debug('insertAcceptor : The following exception has occurred: ' + dmlExcept.getMessage());
    }
    return createdAcceptorId;
  }
  /* *
   * Author : Dinesh Kumar Bussunt
   * Ticket : COUL-3723
   * Date : 22/06/223
   * Description : Gets the metadata labels to be used for the LWC Component
   * Component : erPortalAcceptor
   */
  @AuraEnabled(Cacheable=true)
  public static String getAutoEnrollmentAcceptorMetadata() {
    String autoEnrollmentJSONStr = '';
    try {
      List<String> acceptorNamesList = new List<String>{
        'lb_edit_en',
        'lb_step1_save_en',
        'lb_step2b_previous_en',
        'lb_cancel_en',
        'lb_general_information_en',
        'lb_store_status_m_en',
        'lb_mid2_en',
        'lb_sub_mid2_en'
      };
      Map<String, String> autoEnrollMetadataMap = new Map<String, String>();
      for (Auto_Enrollment__mdt eachMetadata : [
        SELECT DeveloperName, Value__c
        FROM Auto_Enrollment__mdt
        WHERE DeveloperName IN :acceptorNamesList
      ]) {
        autoEnrollMetadataMap.put(eachMetadata.DeveloperName, eachMetadata.Value__c);
      }
      autoEnrollmentJSONStr = JSON.serialize(autoEnrollMetadataMap);
    } catch (DmlException dmlExcept) {
      System.debug(
        'getAutoEnrollmentAcceptorMetadata : The following exception has occurred: ' + dmlExcept.getMessage()
      );
    }
    return autoEnrollmentJSONStr;
  }
  /////////////////////////////////////////////////////: STORE

  @AuraEnabled(cacheable=true)
  public static Map<String, Map<String, String>> getStoreCategories(String businessUnit, String lang) {
    /*try {
          List<ER_DependentValue__c> depList = [SELECT id , name, ER_Business_Unit__c,
                                                ER_Category_Code__c, ER_Object__c, ER_Ordering__c,
                                                ER_Status__c, Solution_and_Service__c
                                                FROM ER_DependentValue__c
                                                WHERE ER_Business_Unit__c =:BU AND ER_Status__c=:Constants.ACTIVE
                                                ORDER BY ER_Ordering__c];
          Map<String, String> mapValues = new  Map<String, String>();
          for(ER_DependentValue__c dep : depList) {
            mapValues.put(dep.ER_Category_Code__c, dep.Name);
          }
          return mapValues;
        } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
        } */

    Map<String, Map<String, String>> categoriesTranslationsMap = new Map<String, Map<String, String>>();
    Map<String, Map<String, String>> categoriesMap = new Map<String, Map<String, String>>();

    Map<String, String> treeParentKeysMap = new Map<String, String>();
    Set<String> parentIdSet = new Set<String>();
    List<String> catsOtherSolutionsList = new List<String>();
    String parentId, previousLanguage;
    //businessUnit = Utils.getBUCode(country);
    System.debug('>>> getCategories - businessUnit / solution: ' + businessUnit + ' / ');
    //TODO check if clause with ER_Business_Unit__c has to be updated for BENELUX case
    for (ER_Translation__c category : [
      SELECT
        Dependent_Value__c,
        Language__c,
        Text__c,
        Dependent_Value__r.Level__c,
        Dependent_Value__r.Name,
        Dependent_Value__r.Parent_Dependent_Value__c,
        Dependent_Value__r.RecordTypeId,
        Dependent_Value__r.Solution_and_Service__c,
        Dependent_Value__r.Solution_and_Service__r.ProductCode
      FROM ER_Translation__c
      WHERE
        Field_API_Name__c = 'ER_StoreCategory__c'
        AND Dependent_Value__r.ER_Business_Unit__c = :businessUnit
        AND Dependent_Value__r.ER_Status__c = 'Active'
        AND Language__c LIKE :lang + '%'
      ORDER BY Language__c, Dependent_Value__r.Level__c
      LIMIT 10
    ]) {
      if (String.isBlank(previousLanguage))
        previousLanguage = category.Language__c;
      // Reinit categoriesMap when new language
      if (category.Language__c != previousLanguage) {
        categoriesMap = new Map<String, Map<String, String>>();
        previousLanguage = category.Language__c;
      }

      // Build a list of "tree keys" composed by all parent Ids concatenated + current record Ids
      String curParent = category.Dependent_Value__r.Parent_Dependent_Value__c;
      parentId = (!String.isBlank(treeParentKeysMap.get(curParent))) ? treeParentKeysMap.get(curParent) + '*' : '';
      parentIdSet.add(curParent);

      treeParentKeysMap.put(category.Dependent_Value__c, parentId + category.Dependent_Value__c);
      System.debug('categoriesMap: Add ' + category.Text__c + ' for lang ' + category.Language__c);
      categoriesTranslationsMap.put(
        treeParentKeysMap.get(category.Dependent_Value__c),
        new Map<String, String>{
          'id' => category.Dependent_Value__c,
          'name' => category.Text__c,
          'level' => String.valueOf(category.Dependent_Value__r.Level__c),
          'solution' => category.Dependent_Value__r.Solution_and_Service__r.ProductCode
        }
      );
      //categoriesTranslationsMap.put(category.Language__c, categoriesMap);
    }

    // Set IsParent for each category
    Boolean isParent;
    System.debug('parentIdSet: ' + parentIdSet);
    //for(String langKey : categoriesTranslationsMap.keySet()) {
    for (String treeKey : categoriesTranslationsMap.keySet()) {
      isParent = parentIdSet.contains(categoriesTranslationsMap.get(treeKey).get('id'));
      System.debug('Current Id ' + categoriesTranslationsMap.get(treeKey).get('id'));
      categoriesTranslationsMap.get(treeKey).put('isParent', String.valueOf(isParent));
      System.debug(treeKey + ' *** ' + categoriesTranslationsMap.get(treeKey));
    }
    //}

    return categoriesTranslationsMap;
  }

  @AuraEnabled
  public static List<ER_Store__c> getStoreRecord(String storeId) {
    return [
      SELECT
        id,
        Name,
        ER_Street__c,
        ER_City__c,
        ER_Zip_Code__c,
        ER_Country__c,
        ER_Facebook__c,
        ER_Website_URL__c,
        ER_Store_Phone_Number__c,
        ER_Email__c,
        ER_Contact__r.FirstName,
        ER_Contact__r.LastName,
        ER_Contact__r.Email,
        ER_Contact__r.phone
      FROM ER_Store__c
      WHERE Id = :storeId
    ];
  }

  @AuraEnabled
  public static List<ER_Store__c> createStore(String storeInfos, String contactInfos, String mainActivity) {
    return [
      SELECT
        id,
        Name,
        ER_Street__c,
        ER_City__c,
        ER_Zip_Code__c,
        ER_Country__c,
        ER_Facebook__c,
        ER_Website_URL__c,
        ER_Store_Phone_Number__c,
        ER_Email__c,
        ER_Contact__r.FirstName,
        ER_Contact__r.LastName,
        ER_Contact__r.Email,
        ER_Contact__r.phone
      FROM ER_Store__c
      WHERE Id = :storeInfos
    ];
  }

  /*
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, String>> getLabels(String country) {
        Map<String, Map<String, String>> labelsMap = new Map<String, Map<String, String>>();
        String curLang, curValue;

        //Get available language codes for this country
        List<String> langList = [
                SELECT Picklist_Values__c
                FROM Auto_Enrollment__mdt
                WHERE Country_Code__c = :country AND Label = 'pk_lang_list'
        ].Picklist_Values__c.split('\\|');

        langList.add(null); // In order to take account of labels, formats that are not linked to a specific language
        // Select all labels for available language codes (those that are common for many countries, eg. french for Belgium & France, and also that are specific to current country)
        for(Auto_Enrollment__mdt ae : [
                SELECT Label, Value__c, Long_Value__c, Scope__c, Language_Code__c, Country_Code__c
                FROM Auto_Enrollment__mdt
                WHERE
                        Language_Code__c IN :langList
                        AND Country_Code__c IN (:country, NULL )
                        AND Data_type__c IN ('Label', 'Format')
                ORDER BY Country_Code__c DESC NULLS FIRST
        ]) {
            // The "ORDER BY NULLS FIRST" is meant to get generic labels first and labels dedicated to a specific country at the end, so the specific labels are prioritized over the generic ones. It is done to have specific translations for a country
            curLang = (String.isBlank(ae.Language_Code__c)) ? 'All' : ae.Language_Code__c;
            curValue = (String.isBlank(ae.Long_Value__c)) ? ae.Value__c : ae.Long_Value__c;
            adaptLabelsOnScopeAndLanguage(labelsMap, curLang, curValue, scope, ae, country);
        }

        if([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox)
            labelsMap.get('All').put('isSandbox', 'true');
        System.debug('>>> getLabels -- labelsMap keys: ' + labelsMap.keySet());

        return labelsMap;
    } */

  // Activate new solution for an account in Cross selling context
  @AuraEnabled
  public static String activateSolutionCrossSelling(
    String accountId,
    String headContactId,
    String buCode,
    String scope,
    String solution,
    String cardType,
    String additionalSelectedProducts
  ) {
    List<String> oppIdList;
    Boolean isOliCreated;
    try {
      System.debug('>>> activateSolutionCrossSelling ***START*** accountId: ' + accountId);
      oppIdList = createOpportunityCs(
        accountId,
        buCode,
        scope,
        solution,
        headContactId,
        cardType,
        additionalSelectedProducts
      );
      isOliCreated = createOpportunityLineItemsCs(
        accountId,
        buCode,
        scope,
        solution,
        cardType,
        additionalSelectedProducts
      );
    } catch (Exception ex) {
      System.debug('Exception message: ' + ex.getMessage());
      System.debug('Exception line: ' + ex.getLineNumber());
      System.debug('Exception cause: ' + ex.getCause());
      return 'OppQuoteIssue';
    }
    if (isOliCreated) {
      acceptQuoteCs(oppIdList);
      activateContractCs(oppIdList);
    } else {
      for (String oppId : oppIdList)
        delete new Opportunity(Id = oppId);
    }
    System.debug('>>> activateSolutionCrossSelling ***END OK***');
    return 'OppQuoteOk';
  }

  // Create opportunity for Cross selling
  private static List<String> createOpportunityCs(
    String accountId,
    String bu,
    String scope,
    String solution,
    String contactId,
    String cardType,
    String additionalSelectedProducts
  ) {
    String oppRTName, oppLeadSource;
    if (scope == 'C') {
      oppRTName = Constants.OPPORTUNITY_CLIENT_RT;
      oppLeadSource = Constants.CLIENT;
    } else if (scope == 'M') {
      oppRTName = Constants.OPPORTUNITY_MERCHANT_RT;
      oppLeadSource = Constants.MERCHANT;
    }

    List<String> solutionList = new List<String>{ solution };
    if (!String.isBlank(additionalSelectedProducts))
      solutionList.addAll(additionalSelectedProducts.split(','));
    if (cardType == 'Physical card')
      solutionList.add('ERFI_C_TD_DUALW_EUR_NEW_CRD_PHYS');
    // else if (cardType == 'Virtual card')
    //   solutionList.add('ERFI_C_TD_DUALW_EUR_NEW_CRD_VIRT');

    Id oppRTId = Utils.getRecordTypeIdByDeveloperName(Opportunity.SObjectType, oppRTName);

    Set<String> curPricebook2CodeSet = new Set<String>();
    solutionPricebookMap = new Map<String, String>();
    for (Auto_Enrollment_Product__mdt aep : [
      SELECT Pricebook__c, Label
      FROM Auto_Enrollment_Product__mdt
      WHERE Label IN :solutionList
      AND Label != 'ERFI_C_TD_DUALW_EUR_NEW_CRD_VIRT'
    ]) {
      curPricebook2CodeSet.add(aep.Pricebook__c);
      solutionPricebookMap.put(aep.Label, aep.Pricebook__c);
    }

    List<Opportunity> oppInsList = new List<Opportunity>();

    Map<String, String> pbIdNameMap = new Map<String, String>(); // Needed to map right solution to right opp
    for (Pricebook2 pb : [
      SELECT Id, ER_MDMId__c
      FROM Pricebook2
      WHERE IsActive = TRUE AND ER_MDMId__c = :curPricebook2CodeSet AND ER_Business_Unit__c = :bu
    ]) {
      Opportunity opp = new Opportunity(
        AccountId = accountId,
        LeadSource = Constants.CONTRACTING_WEBFORM,
        StageName = Constants.PROPOSAL,
        ER_PaymentTerms__c = Constants.OPP_PAYMENT_TERM_PRE_PAID,
        Type = Label.LABS_SF_Opportunity_Type_Operational,
        ER_Reason__c = Constants.CROSS_SELLING_REASON,
        ER_Contract_Duration__c = Constants.ZUORA_TERM_TYPE_EVERGREEN,
        ER_BUPicklist__c = bu,
        ER_Lead_Source_Type__c = oppLeadSource,
        RecordTypeId = oppRTId,
        Pricebook2Id = pb.Id,
        CloseDate = Date.today().addMonths(1)
      );

      APER04_Opportunity_Management.setOppName(new List<Opportunity>{ opp });

      oppInsList.add(opp);

      pbIdNameMap.put(pb.Id, pb.ER_MDMId__c);
    }

    List<String> oppIdList = new List<String>();
    if (!oppInsList.isEmpty()) {
      insert oppInsList;
      List<OpportunityContactRole> oppCRList = new List<OpportunityContactRole>();
      pbOppMap = new Map<String, String>();
      for (Opportunity opp : oppInsList) {
        oppCRList.add(new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contactId, IsPrimary = true));
        oppIdList.add(opp.Id);
        pbOppMap.put(pbIdNameMap.get(opp.Pricebook2Id), opp.Id);
      }
      insert oppCRList;
    }

    return oppIdList;
  }

  // Create opportunity line items for Cross selling
  private static Boolean createOpportunityLineItemsCs(
    String accountId,
    String bu,
    String scope,
    String solution,
    String cardType,
    String additionalSelectedProducts
  ) {
    Boolean result = false;
    System.debug('>>> createOpportunityLineItemsCs - solution: ' + solution);
    System.debug('>>> createOpportunityLineItemsCs - additionalSelectedProducts: ' + additionalSelectedProducts);

    Set<String> solutionSet = new Set<String>{ solution };
    Set<String> solutionExcludeSet = new Set<String>();
    if (!String.isBlank(additionalSelectedProducts))
      solutionSet.addAll(additionalSelectedProducts.split(','));
    if (cardType == 'Physical card') {
      solutionSet.add('ERFI_C_TD_DUALW_EUR_NEW_CRD_PHYS');
      solutionExcludeSet.add('ERFI_C_TD_DUALW_EUR_NEW_CRD_VIRT');
    } else if (cardType == 'Virtual card') {
      solutionSet.add('ERFI_C_TD_DUALW_EUR_NEW_CRD_VIRT');
      solutionExcludeSet.add('ERFI_C_TD_DUALW_EUR_NEW_CRD_PHYS');
    }
    List<OpportunityLineItem> oliFinalList = new List<OpportunityLineItem>();
    Set<String> prodIdSet = new Set<String>();
    for (String sol : solutionSet) {
      System.debug('>>> createOpportunityLineItemsCs - sol: ' + sol);
      String oppId = pbOppMap.get(solutionPricebookMap.get(sol));
      if(String.isBlank(oppId) && sol == 'ERFI_C_TD_DUALW_EUR_NEW_CRD_VIRT') {
        List<String> oppIdList = solutionPricebookMap.values(); // bad fix (until better slution)
        oppId = pbOppMap.get(oppIdList[0]);
      }
      Opportunity opp = new Opportunity(Id = oppId);
      String pricebookId = Utils.getPricebookId(solutionPricebookMap.get(sol));
      System.debug('>>> createOpportunityLineItemsCs - oppId: ' + oppId);

      Map<String, Object> resultMap = APER30_AutoEnrollment_Management.createOppLineitems(
        opp,
        bu,
        sol,
        scope,
        null,
        pricebookId,
        false
      );
      List<OpportunityLineItem> oliList = (List<OpportunityLineItem>) resultMap.get('oliList');
      System.debug('>>> createOpportunityLineItemsCs - prodIdSet: ' + prodIdSet);
      for (OpportunityLineItem oli : oliList) {
        // To avoid duplicates oli
        if (!prodIdSet.contains(oli.Product2Id)) {
          oliFinalList.add(oli);
          prodIdSet.add(oli.Product2Id);
        }
      }
      System.debug('>>> createOpportunityLineItemsCs - prodIdSet2: ' + prodIdSet);
    }

    System.debug('>>> createOpportunityLineItemsCs - oliFinalList size: ' + oliFinalList.size());
    List<OpportunityLineItem> oliFilteredList = filterOpportunityLineItemsCs(
      oliFinalList,
      accountId,
      solutionExcludeSet
    );
    System.debug('>>> createOpportunityLineItemsCs - oliFilteredList size: ' + oliFilteredList.size());
    if (!oliFilteredList.isEmpty()) {
      insert oliFilteredList;
      result = true;
    }
    return result;
  }

  // Filter line items in case of already existing solution for the account (Cross selling case)
  private static List<OpportunityLineItem> filterOpportunityLineItemsCs(
    List<OpportunityLineItem> oliList,
    String accountId,
    Set<String> solutionExcludeSet
  ) {
    List<OpportunityLineItem> oliFilteredList = new List<OpportunityLineItem>();
    Set<String> solIdExcludeSet = new Set<String>();
    if (!solutionExcludeSet.isEmpty()) {
      for (Product2 prod : [SELECT Id FROM Product2 WHERE ProductCode IN :solutionExcludeSet])
        solIdExcludeSet.add(prod.Id);
    }

    if (!oliList.isEmpty()) {
      Set<String> activeSolutionsSet = new Set<String>();
      for (ER_Solution_Line_Item__c sli : [
        SELECT ER_Solution__c
        FROM ER_Solution_Line_Item__c
        WHERE ER_Account__c = :accountId AND ER_Global_Status__c = 'Active'
      ]) {
        System.debug('>>> filterOpportunityLineItemsCs - sli.ER_Solution__c: ' + sli.ER_Solution__c);
        if (!String.isBlank(sli.ER_Solution__c))
          activeSolutionsSet.add(sli.ER_Solution__c);
      }
      System.debug('>>> filterOpportunityLineItemsCs - activeSolutionsSet: ' + activeSolutionsSet);

      Set<String> oliProductSet = new Set<String>();
      for (OpportunityLineItem oli : oliList)
        oliProductSet.add(oli.Product2Id);
      Map<String, String> parentSolutionMap = new Map<String, String>();
      for (Product2 prod : [SELECT Id, ER_Solution__c FROM Product2 WHERE Id IN :oliProductSet])
        parentSolutionMap.put(prod.Id, prod.ER_Solution__c);

      for (OpportunityLineItem oli : oliList) {
        System.debug('>>> filterOpportunityLineItemsCs - oli.Product2Id / oppId: ' + oli.Product2Id + ' / ' + oli.OpportunityId);
        if (
          !activeSolutionsSet.contains(oli.Product2Id) &&
          !activeSolutionsSet.contains(parentSolutionMap.get(oli.Product2Id)) &&
          !solIdExcludeSet.contains(oli.Product2Id)
        )
          oliFilteredList.add(oli);
      }
    }
    System.debug('oliFilteredList size: ' + oliFilteredList.size());
    return oliFilteredList;
  }

  // Accept quote for Cross selling
  private static void acceptQuoteCs(List<String> oppIdList) {
    System.debug('acceptQuoteCs ***START*** - oppIdList: ' + oppIdList);
    List<Quote> qtList = [SELECT Id, Status FROM Quote WHERE OpportunityId IN :oppIdList AND Status = 'Draft'];
    // use ER_Solutions__c to check against solution?
    if (qtList.isEmpty()) {
      for (String oppId : oppIdList) {
        Quote curQuote = VFCER04_Opportunity_Product.saveAsQuote(oppId);
        curQuote.Status = 'Accepted';
        qtList.add(curQuote);
      }
    }
    qtList[0].Status = 'Accepted';
    update qtList;
    System.debug('acceptQuoteCs ***END***');
  }

  // Activate contract for Cross selling
  private static void activateContractCs(List<String> oppIdList) {
    List<Quote> qtList = [SELECT Id, ContractId FROM Quote WHERE OpportunityId IN :oppIdList AND Status = 'Accepted'];
    for (Quote qt : qtList) {
      List<Contract> contractList = APER12_Contract_Management.getContract(new List<String>{ qt.contractId });
      APER12_Contract_Management.activateContractController(contractList[0], null, true);
    }
  }

  @AuraEnabled
  public static String getAccountIdFromCRN(String crn) {
    List<Account> accounts = [SELECT Id FROM Account WHERE ER_Registration_Number__c = :crn];
    if (!accounts.isEmpty()) {
      return accounts[0].Id;
    }
    return null;
  }

  @AuraEnabled
  public static Boolean checkStoreNameDuplicate(String storeName, String businessUnit) {
    return [
        SELECT Id
        FROM ER_Store__c
        WHERE Name = :storeName AND ER_BUPicklist__c = :businessUnit AND ER_STatus__c = 'Active'
      ]
      .isEmpty();
  }
}