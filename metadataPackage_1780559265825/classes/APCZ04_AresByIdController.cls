/*
----------------------------------------------------------------------
-- - Name          : APCZ04_AresByIdController
-- - Author        : XXX
-- - Description   : The controller of the page APCZ04_AresByIdController
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  XXX            XXX                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public with sharing class APCZ04_AresByIdController {
  @AuraEnabled
  public static String getDarvBasWS(String sId) {
    HttpResponse res = new HttpResponse();
    APCZ03_AresCallout_ById ac = new APCZ03_AresCallout_ById();
    res = ac.getDarvBas(sId);
    System.debug('### getDarvBasWS ARES RESPONSE : ' + res.getBody());
    APCZ02_AresXmlReader axr = new APCZ02_AresXmlReader();
    return axr.ReadDarvBasXml(res);
  }

  @AuraEnabled
  public static String getDarvResWS(String sId, String sExistingNace) {
    HttpResponse res = new HttpResponse();
    APCZ03_AresCallout_ById ac = new APCZ03_AresCallout_ById();
    res = ac.getDarvRes(sId);
    System.debug('### getDarvResWS ARES RESPONSE : ' + res.getBody());
    APCZ02_AresXmlReader axr = new APCZ02_AresXmlReader();
    return axr.ReadDarvResXml(res, sExistingNace);
  }

  @AuraEnabled
  public static WSSK01_GetFinstat.Finstat getFinStatWS(String sId) {
    WSSK01_GetFinstat.Finstat response = WSSK01_GetFinstat.GetFinstatInfos(sId);
    System.debug('APCZ04_AresByIdController getFinStatWS : ' + response);
    return response;
  }

  @AuraEnabled
  public static WSBE01_Belfirst.Belfirst getBelfirstWS(String sId, String idType) {
    // WSBE01_Belfirst.Belfirst response = WSBE01_Belfirst.getBelfirstData(sId, 'fr_BE');
    System.debug('sId1'+sId);
    Map<String, String> response = new Map<String, String>();
    WSBE01_Belfirst.Belfirst BelfirstInstance = new WSBE01_Belfirst.Belfirst();
    WSBE01_Belfirst w = new WSBE01_Belfirst();
    try{
      response = w.getinfos(sId, idType ,'fr_BE');
      // WSBE01_Belfirst.closeConnection();
      System.debug('APCZ04_AresByIdController getBelfirstWS : ' + response);

      BelfirstInstance.Street = response.get('ADDRESS');
      BelfirstInstance.Name = response.get('NAME');
      BelfirstInstance.Dic = response.get('BVDID');
      BelfirstInstance.IcDPH = response.get('COMPANY_NUMBER');
      BelfirstInstance.LegalFormText = response.get('TYPE');
      BelfirstInstance.StreetNumber = response.get('ADDRESS');
      BelfirstInstance.ZipCode = response.get('POSTCODE');
      BelfirstInstance.City = response.get('TOWN');
      BelfirstInstance.Country = response.get('COUNTRY');
      BelfirstInstance.NaceCode = response.get('NACEBELCCOD2008');
      BelfirstInstance.NaceText = response.get('NACEBELCDES2008');
      BelfirstInstance.Website = response.get('WEBSITE');
      BelfirstInstance.Phone = response.get('PHONE');
      BelfirstInstance.Email = response.get('EMAIL');
      BelfirstInstance.SubjectToVAT = response.get('VATLIABILITY');
      BelfirstInstance.NumberOfEmployees = response.get('EMPLOYEE');
      BelfirstInstance.VatNumber = response.get('BVDID').startsWith('BE') ? response.get('BVDID') : response.get('LVAT'); //AAM 16.03.22: PBI#15235 Set VAT number for BE
      w.closeConnection();
    }catch(Exception ex){
      w.closeConnection();
      throw new AuraHandledException(ex.getMessage());
    }
    
    return BelfirstInstance;
  }

  @AuraEnabled
  public static Account getAccountWS(Id objId) {
    return [
      SELECT ER_Registration_Number__c, ER_NaceList__c, ER_VAT_Number__c, ER_Other_Fiscal_ID__c
      FROM Account
      WHERE Id = :objId
    ];
  }

  @AuraEnabled
  public static Lead getLeadWS(Id objId) {
    return [
      SELECT ER_Registration_Number__c, ER_NaceList__c, ER_VAT_Number__c, ER_Other_Fiscal_ID__c
      FROM Lead
      WHERE Id = :objId
    ];
  }

  @AuraEnabled
  public static user fetchUser() {
    // query current user information
    return [SELECT ER_Business_Unit__c FROM User WHERE id = :userInfo.getUserId()];
  }
    
    @AuraEnabled
    public static String fetchBU(String recId) {
        String bu;
        if(recId.startsWith('00Q')){
            bu = [SELECT Id, ER_BUPicklist__c from Lead where Id=: recId].ER_BUPicklist__c;
        }else if(recId.startsWith('001')){
            bu = [SELECT Id, ER_BUPicklist__c from Account where Id=: recId].ER_BUPicklist__c;
        }
        return bu;
    }

  @AuraEnabled
  public static Account updateAccountWS(String sJson, String sJsonNace) {
    APCZ01_AresEntity.AresPopUp oPopUp = (APCZ01_AresEntity.AresPopUp) JSON.deserialize(
      sJson,
      APCZ01_AresEntity.AresPopUp.class
    );

    List<Account> oList = [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingPostalCode,
        BillingCity,
        BillingCountry,
        ER_NaceList__c,
        ER_NaceNameList__c,
        ER_VAT_Number__c,
        ER_Legal_Form__c,
        ER_Legal_Name__c,
        Phone,
        ER_Email__c,
        Website
      FROM Account
      WHERE Id = :oPopUp.oId
    ];
    try {
      if (oPopUp.bGetName == true) {
        oList[0].ER_Legal_Name__c = oPopUp.sName;
      }

      if (oPopUp.bGetStreet == true) {
        oList[0].BillingStreet = oPopUp.sStreet;
      }

      if (oPopUp.bGetZipCode == true) {
        oList[0].BillingPostalCode = oPopUp.sPostalCode;
      }

      if (oPopUp.bGetCity == true) {
        oList[0].BillingCity = oPopUp.sCity;
      }
      if (oPopUp.bGetCountry == true && String.isNotBlank(oPopUp.sCountry)) {
        oList[0].BillingCountry = oPopUp.sCountry;
        // AAM 22.03.22: PBI#15298
        if (oPopUp.sCountry.equalsIgnoreCase('belgium') || oPopUp.sCountry.equalsIgnoreCase('luxembourg')) {
          oList[0].ER_Country_Code__c = oPopUp.sCountry.toUpperCase().substring(0, 2);
        }
      }
      if (oPopUp.bGetVatNumber == true) {
        oList[0].ER_VAT_Number__c = oPopUp.sVatNumber;
      }
      if (oPopUp.bGetLegalForm == true) {
        oList[0].ER_Legal_Form__c = oPopUp.sLegalForm;
      }
      if (oPopUp.bGetOtherFiscalId == true) {
        oList[0].ER_Other_Fiscal_ID__c = oPopUp.sOtherFiscalId;
      }
      if (oPopUp.bGetBEPhone == true) {
        oList[0].Phone = oPopUp.sBEPhone;
      }
      if (oPopUp.bGetBEEmail == true) {
        oList[0].ER_Email__c = oPopUp.sBEEmail;
      }
      if (oPopUp.bGetBEWebsite == true) {
        oList[0].Website = oPopUp.sBEWebsite;
      }
      if (oPopUp.bGetBENumberOfEmployees == true) {
        oList[0].NumberOfEmployees = Integer.valueOf(oPopUp.sBENumberOfEmployees);
      }
      if (oPopUp.bGetBESubjectToVAT == true) {
        switch on oPopUp.sBESubjectToVAT {
          when 'Oui' {
            oList[0].ER_Not_subject_to_VAT__c = false;
          }
          when 'Non' {
            oList[0].ER_Not_subject_to_VAT__c = true;
          }
        }
      }

      oList[0].ER_NaceList__c = oPopUp.sNaceList;

      List<APCZ01_AresEntity.AresNace> listAllNace = (List<APCZ01_AresEntity.AresNace>) JSON.deserialize(
        sJsonNace,
        List<APCZ01_AresEntity.AresNace>.class
      );

      List<String> lstExistingNace;

      if (oPopUp.sNaceList != null) {
        //system.debug('oPopUp.sNaceList : '+oPopUp.sNaceList);
        lstExistingNace = oPopUp.sNaceList.split(',');
        //system.debug('KHAAAAAAAAAAD'+lstExistingNace);
      }

      List<String> lstNaceNames = new List<String>();

      for (String rowNace : lstExistingNace) {
        for (APCZ01_AresEntity.AresNace oAresNace : listAllNace) {
          //system.debug('oAresNace.n04_NACE'+oAresNace.n04_NACE+'Rownace'+rowNace);
          if (oAresNace.n04_NACE == rowNace) {
            lstNaceNames.add('[' + oAresNace.n04_NACE + ' - ' + oAresNace.n04_Nazev + ']');
          }
        } //looking for a name
      }

      //system.debug('ListNames=' + lstNaceNames);

      String sNaceNames = String.join(lstNaceNames, ',\r\n');

      oList[0].ER_NaceNameList__c = sNaceNames;

      update oList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return oList[0];
  }

  @AuraEnabled
  public static Lead updateLeadWS(String sJson, String sJsonNace) {
    APCZ01_AresEntity.AresPopUp oPopUp = (APCZ01_AresEntity.AresPopUp) JSON.deserialize(
      sJson,
      APCZ01_AresEntity.AresPopUp.class
    );

    //System.debug('***Get_oNace=' + sJsonNace);

    List<Lead> oList = [
      SELECT
        Id,
        Name,
        Street,
        PostalCode,
        City,
        Country,
        ER_NaceList__c,
        ER_VAT_Number__c,
        ER_Legal_Form__c,
        ER_Legal_Name__c,
        ER_Legal_Country__c,
        Company,
        RecordType.DeveloperName
      FROM Lead
      WHERE Id = :oPopUp.oId
    ];

    // System.debug('***GetName=' + oPopUp.bGetName);
    try {
      if (oPopUp.bGetName == true) {
        oList[0].Company = oPopUp.sName;
        oList[0].ER_Legal_Name__c = oPopUp.sName;
      }

      if (oPopUp.bGetStreet == true) {
        oList[0].ER_Legal_Street__c = oPopUp.sStreet;
        if (oList[0].RecordType.DeveloperName == 'ER_Client_Lead_RT') {
          oList[0].Street = oPopUp.sStreet;
        }
      }

      if (oPopUp.bGetZipCode == true) {
        oList[0].ER_Legal_Zip_Code__c = oPopUp.sPostalCode;
        if (oList[0].RecordType.DeveloperName == 'ER_Client_Lead_RT') {
          oList[0].PostalCode = oPopUp.sPostalCode;
        }
      }

      if (oPopUp.bGetCity == true) {
        oList[0].ER_Legal_City__c = oPopUp.sCity;
        if (oList[0].RecordType.DeveloperName == 'ER_Client_Lead_RT') {
          oList[0].City = oPopUp.sCity;
        }
      }

      if (oPopUp.bGetCountry == true && String.isNotBlank(oPopUp.sCountry)) {
        oList[0].ER_Legal_Country__c = oPopUp.sCountry;
        if (oList[0].RecordType.DeveloperName == 'ER_Client_Lead_RT') {
          oList[0].Country = oPopUp.sCountry;
        }
        // AAM 22.03.22: PBI#15298
        if (oPopUp.sCountry.equalsIgnoreCase('belgium') || oPopUp.sCountry.equalsIgnoreCase('luxembourg')) {
          oList[0].ER_Legal_Country_Code__c = oPopUp.sCountry.toUpperCase().substring(0, 2);
          oList[0].ER_Country_Code__c = oPopUp.sCountry.toUpperCase().substring(0, 2);
        }
      }

      if (oPopUp.bGetVatNumber == true) {
        oList[0].ER_VAT_Number__c = oPopUp.sVatNumber;
      }
      if (oPopUp.bGetLegalForm == true) {
        oList[0].ER_Legal_Form__c = oPopUp.sLegalForm;
      }
      if (oPopUp.bGetOtherFiscalId == true) {
        oList[0].ER_Other_Fiscal_ID__c = oPopUp.sOtherFiscalId;
      }
      if (oPopUp.bGetBEPhone == true) {
        oList[0].Phone = oPopUp.sBEPhone;
      }
      if (oPopUp.bGetBEEmail == true) {
        oList[0].Email = oPopUp.sBEEmail;
      }
      if (oPopUp.bGetBEWebsite == true) {
        oList[0].Website = oPopUp.sBEWebsite;
      }
      if (oPopUp.bGetBENumberOfEmployees == true) {
        oList[0].NumberOfEmployees = Integer.valueOf(oPopUp.sBENumberOfEmployees);
      }

      if (oPopUp.bGetBESubjectToVAT == true) {
        switch on oPopUp.sBESubjectToVAT {
          when 'Oui' {
            oList[0].ER_Not_subject_to_VAT__c = false;
          }
          when 'Non' {
            oList[0].ER_Not_subject_to_VAT__c = true;
          }
        }
      }

      oList[0].ER_NaceList__c = oPopUp.sNaceList;

      List<APCZ01_AresEntity.AresNace> listAllNace = (List<APCZ01_AresEntity.AresNace>) JSON.deserialize(
        sJsonNace,
        List<APCZ01_AresEntity.AresNace>.class
      );

      List<String> lstExistingNace;

      if (oPopUp.sNaceList != null) {
        lstExistingNace = oPopUp.sNaceList.split(',');
      }

      List<String> lstNaceNames = new List<String>();

      for (String rowNace : lstExistingNace) {
        for (APCZ01_AresEntity.AresNace oAresNace : listAllNace) {
          if (oAresNace.n04_NACE == rowNace) {
            lstNaceNames.add('[' + oAresNace.n04_NACE + ' - ' + oAresNace.n04_Nazev + ']');
          }
        } //looking for a name
      }

      String sNaceNames = String.join(lstNaceNames, ',\r\n');

      oList[0].ER_NaceNameList__c = sNaceNames;

      update oList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return oList[0];
  }

  @AuraEnabled
  public static String getSpecificFields(String BU, String recordType) {
    String specificFields = '';
    System.debug('BU : ' + BU);
    String clause = recordType.toUpperCase() + '%PUBLIC_REGISTER%';
    Global_Settings__mdt[] globalSettings = [
      SELECT Label
      FROM Global_Settings__mdt
      WHERE Business_Unit__c = :BU AND Active__c = TRUE AND Label LIKE :clause
      ORDER BY Label
    ];

    for (Global_Settings__mdt gB : globalSettings) {
      specificFields = specificFields + gB.Label + ',';
    }
    specificFields = specificFields.removeEnd(',');
    return specificFields;
  }

  @AuraEnabled
  public static WSER11_PL_PublicRegister.WSERPL11_Response_Wrapper getPLWSResult(String sIdentification) {
    WSER11_PL_PublicRegister.WSERPL11_Response_Wrapper response = WSER11_PL_PublicRegister.queryAccountInfo(
      sIdentification
    );
    System.debug('APCZ04_AresByIdController getPLWSResult : ' + response);
    return response;
  }

  @AuraEnabled
  public static String getPLWSIdentification(String sId) {
    String identificationNumber = WSER11_PL_PublicRegister.getJobIdentificationNumber(sId);
    System.debug('APCZ04_AresByIdController getPLWSResult : ' + identificationNumber);
    return identificationNumber;
  }

  @AuraEnabled
  public static String getName(String recordId) {
    String name;
    Id sId = Id.valueOf(recordId);
    String sobjectType = sId.getSObjectType().getDescribe().getName();

    if (sobjectType == 'Lead') {
      name = [SELECT Name FROM Lead WHERE Id = :recordId LIMIT 1].Name;
    } else if (sobjectType == 'Account') {
      name = [SELECT Name FROM Account WHERE Id = :recordId LIMIT 1].Name;
    }
    return name;
  }

  @AuraEnabled
  public static String getERESPublicRegister(String recordId) {
    String CRN;
    Id sId = Id.valueOf(recordId);
    String sobjectType = sId.getSObjectType().getDescribe().getName();
    HttpResponse res = new HttpResponse();

    if (sobjectType == 'Lead') {
      CRN = [SELECT ER_Registration_Number__c FROM Lead WHERE Id = :recordId LIMIT 1].ER_Registration_Number__c;
    } else if (sobjectType == 'Account') {
      CRN = [SELECT ER_Registration_Number__c FROM Account WHERE Id = :recordId LIMIT 1].ER_Registration_Number__c;
    }
    if (!Test.isRunningTest()) {
      APCZ03_AresCallout_ById ac = new APCZ03_AresCallout_ById();
      res = ac.getCreditScoringInfo(CRN);
    }
    return res.getBody();
  }

  @AuraEnabled
  public static String updateCreditScoring(Map<String, String> fieldsToUpdate, String recordId) {
    List<Account> accToUpdate;
    List<Lead> leadToUpdate;
    Id sId = Id.valueOf(recordId);
    String sobjectType = sId.getSObjectType().getDescribe().getName();

    if (sobjectType == 'Account') {
      accToUpdate = [
        SELECT ER_Credit_Scoring__c, ER_Credit_Limit__c, ER_Last_Credit_Scoring_Update__c
        FROM Account
        WHERE Id = :recordId
        LIMIT 1
      ];

      if (String.isNotBlank(fieldsToUpdate.get('scoring')))
        accToUpdate[0].ER_Credit_Scoring__c = Integer.valueOf(fieldsToUpdate.get('scoring'));
      else
        accToUpdate[0].ER_Credit_Scoring__c = null;
      if (String.isNotBlank(fieldsToUpdate.get('limit')))
        accToUpdate[0].ER_Credit_Limit__c = Integer.valueOf(fieldsToUpdate.get('limit'));
      else
        accToUpdate[0].ER_Credit_Limit__c = null;

      accToUpdate[0].ER_Last_Credit_Scoring_Update__c = Date.today();
      update accToUpdate[0];
    } else if (sobjectType == 'Lead') {
      leadToUpdate = [
        SELECT ER_Credit_Scoring__c, ER_Credit_Limit__c, ER_Last_Credit_Scoring_Update__c
        FROM Lead
        WHERE Id = :recordId
        LIMIT 1
      ];

      if (String.isNotBlank(fieldsToUpdate.get('scoring')))
        leadToUpdate[0].ER_Credit_Scoring__c = Integer.valueOf(fieldsToUpdate.get('scoring'));
      else
        leadToUpdate[0].ER_Credit_Scoring__c = null;
      if (String.isNotBlank(fieldsToUpdate.get('limit')))
        leadToUpdate[0].ER_Credit_Limit__c = Integer.valueOf(fieldsToUpdate.get('limit'));
      else
        leadToUpdate[0].ER_Credit_Limit__c = null;

      leadToUpdate[0].ER_Last_Credit_Scoring_Update__c = Date.today();
      update leadToUpdate[0];
    }

    return 'Success';
  }

  @AuraEnabled
  public static String updatePublicRegister(Map<String, String> fieldsToUpdate, String recordId) {
    List<Account> accToUpdate;
    List<Lead> leadToUpdate;
    List<Contact> contactToUpdate;
    Id sId = Id.valueOf(recordId);
    String sobjectType = sId.getSObjectType().getDescribe().getName();

    if (sobjectType == 'Account') {
      accToUpdate = [
        SELECT
          ER_NaceList__c,
          ER_Credit_Scoring__c,
          ER_Credit_Limit__c,
          ER_Last_Credit_Scoring_Update__c,
          ER_Legal_Name__c,
          ER_Legal_Form__c,
          Phone,
          ER_Email__c,
          NumberOfEmployees
        FROM Account
        WHERE Id = :recordId
        LIMIT 1
      ];
      contactToUpdate = [
        SELECT ER_Legal_Street__c, ER_Legal_Zip_Code__c, ER_Legal_City__c, ER_Legal_Country__c
        FROM Contact
        WHERE AccountId = :recordId
        LIMIT 1
      ];

      if (fieldsToUpdate.get('scoring') != null || fieldsToUpdate.get('limit') != null) {
        accToUpdate[0].ER_Last_Credit_Scoring_Update__c = Date.today();
      }
      if (fieldsToUpdate.get('scoring') != null) {
        accToUpdate[0].ER_Credit_Scoring__c = Integer.valueOf(fieldsToUpdate.get('scoring'));
      }
      if (fieldsToUpdate.get('limit') != null) {
        if (fieldsToUpdate.get('limit') != '') {
          accToUpdate[0].ER_Credit_Limit__c = Integer.valueOf(fieldsToUpdate.get('limit'));
        } else {
          accToUpdate[0].ER_Credit_Limit__c = null;
        }
      }
      if (fieldsToUpdate.get('legalName') != null) {
        accToUpdate[0].ER_Legal_Name__c = fieldsToUpdate.get('legalName');
      }
      if (fieldsToUpdate.get('legalForm') != null) {
        accToUpdate[0].ER_Legal_Form__c = fieldsToUpdate.get('legalForm');
      }
      if (fieldsToUpdate.get('street') != null) {
        accToUpdate[0].BillingStreet = fieldsToUpdate.get('street');
      }
      if (fieldsToUpdate.get('zipCode') != null) {
        accToUpdate[0].BillingPostalCode = fieldsToUpdate.get('zipCode');
      }
      if (fieldsToUpdate.get('city') != null) {
        accToUpdate[0].BillingCity = fieldsToUpdate.get('city');
      }
      if (fieldsToUpdate.get('country') != null) {
        accToUpdate[0].BillingCountry = fieldsToUpdate.get('country');
        accToUpdate[0].ER_Country_Code__c = 'ES';
      }
      if (fieldsToUpdate.get('phone') != null) {
        accToUpdate[0].Phone = fieldsToUpdate.get('phone');
      }
      if (fieldsToUpdate.get('email') != null) {
        accToUpdate[0].ER_Email__c = fieldsToUpdate.get('email');
      }
      if (fieldsToUpdate.get('nbEmployees') != null) {
        accToUpdate[0].NumberOfEmployees = Integer.valueOf(fieldsToUpdate.get('nbEmployees'));
      }
      if (fieldsToUpdate.get('naceChk') != null) {
        accToUpdate[0].ER_NaceList__c = fieldsToUpdate.get('naceChk');
      }

      update accToUpdate[0];
    } else if (sobjectType == 'Lead') {
      leadToUpdate = [
        SELECT
          ER_NaceList__c,
          ER_Credit_Scoring__c,
          ER_Credit_Limit__c,
          ER_Last_Credit_Scoring_Update__c,
          Company,
          ER_Legal_Form__c,
          Phone,
          Email,
          NumberOfEmployees,
          ER_Legal_Street__c,
          ER_Legal_Zip_Code__c,
          ER_Legal_City__c,
          ER_Legal_Country__c
        FROM Lead
        WHERE Id = :recordId
        LIMIT 1
      ];

      if (fieldsToUpdate.get('scoring') != null || fieldsToUpdate.get('limit') != null) {
        leadToUpdate[0].ER_Last_Credit_Scoring_Update__c = Date.today();
      }
      if (fieldsToUpdate.get('scoring') != null) {
        leadToUpdate[0].ER_Credit_Scoring__c = Integer.valueOf(fieldsToUpdate.get('scoring'));
      }
      if (fieldsToUpdate.get('limit') != null) {
        if (fieldsToUpdate.get('limit') != '') {
          leadToUpdate[0].ER_Credit_Limit__c = Integer.valueOf(fieldsToUpdate.get('limit'));
        } else {
          leadToUpdate[0].ER_Credit_Limit__c = null;
        }
      }
      if (fieldsToUpdate.get('legalName') != null) {
        leadToUpdate[0].Company = fieldsToUpdate.get('legalName');
      }
      if (fieldsToUpdate.get('legalForm') != null) {
        leadToUpdate[0].ER_Legal_Form__c = fieldsToUpdate.get('legalForm');
      }
      if (fieldsToUpdate.get('street') != null) {
        leadToUpdate[0].ER_Legal_Street__c = fieldsToUpdate.get('street');
        leadToUpdate[0].Street = fieldsToUpdate.get('street');
      }
      if (fieldsToUpdate.get('zipCode') != null) {
        leadToUpdate[0].ER_Legal_Zip_Code__c = fieldsToUpdate.get('zipCode');
        leadToUpdate[0].PostalCode = fieldsToUpdate.get('zipCode');
      }
      if (fieldsToUpdate.get('city') != null) {
        leadToUpdate[0].ER_Legal_City__c = fieldsToUpdate.get('city');
        leadToUpdate[0].City = fieldsToUpdate.get('city');
      }
      if (fieldsToUpdate.get('country') != null) {
        leadToUpdate[0].ER_Legal_Country__c = fieldsToUpdate.get('country');
        leadToUpdate[0].Country = fieldsToUpdate.get('country');
      }
      if (fieldsToUpdate.get('phone') != null) {
        leadToUpdate[0].Phone = fieldsToUpdate.get('phone');
      }
      if (fieldsToUpdate.get('email') != null) {
        leadToUpdate[0].Email = fieldsToUpdate.get('email');
      }
      if (fieldsToUpdate.get('nbEmployees') != null) {
        leadToUpdate[0].NumberOfEmployees = Integer.valueOf(fieldsToUpdate.get('nbEmployees'));
      }
      if (fieldsToUpdate.get('naceChk') != null) {
        leadToUpdate[0].ER_NaceList__c = fieldsToUpdate.get('naceChk');
      }

      update leadToUpdate[0];
    }

    return 'Success';
  }

  @AuraEnabled
  public static String getTableInfo() {
    HttpResponse res = new HttpResponse();
    APCZ03_AresCallout_ById ac = new APCZ03_AresCallout_ById();
    res = ac.getTableInfo();
    return res.getBody();
  }
}