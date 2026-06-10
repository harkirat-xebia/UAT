public without sharing class APER03_Lead_CreateFinancialCenter {
  /*
----------------------------------------------------------------------
-- - Name          : APER03_Lead_CreateFinancialCenter
-- - Author        : AAB
-- - Description   : Process the Financial Center creation on lead conversion       
-- Maintenance History:
--
-- Date         Name                Version     Remarks 
-- -----------  -----------         --------    ---------------------------------------
-- 16-JUL-2018  AAB                 1.0         Initial version
-- 17-JUL-2018  AAB                 2.0         Add the related store creation
-- 29-APR-2019  OLA                 2.1         Add Financial center type condition
-- 26-MAY-2021  OLA                 2.2         PBI#11122 - ERBE - Financial Center creation at the 
												lead conversion > Payment site by default (not invoicing)
---------------------------------------------------------------------------------------
*/

  public static void createFinancialCenter(List<Lead> leads) {
    Account accConverted;
    //String financialCenterType;
    Set<Id> accountIds = new Set<Id>();
    List<Lead> listLeads = new List<Lead>();
    List<Account> accountsToUpdate = new List<Account>();
    List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    List<ER_Financial_Center__c> fcToBeUpdated = new List<ER_Financial_Center__c>();
    Map<Id, Map<String, List<ER_Financial_Center__c>>> mapAccountPerFCType = new Map<Id, Map<String, List<ER_Financial_Center__c>>>();

    APER05_DoNotRunTrigger donotRunTrigger = new APER05_DoNotRunTrigger();
    donotRunTrigger.setDoNotRunTrigger();

    for(Lead lead :leads) {
        if(lead.IsConverted && lead.ConvertedAccountId != null) {
            listLeads.add(lead);
            accountIds.add(lead.ConvertedAccountId);
        }
    }

    for(ER_Financial_Center__c fc :[SELECT Id, ER_Type__c, ER_Account_Name__c, ER_SmartER_Context__c,
                                        ER_Account_Name__r.ER_Registration_Number__c
                                        FROM ER_Financial_Center__c
                                        WHERE ER_Account_Name__c IN :accountIds]) {
        if(!mapAccountPerFCType.containsKey(fc.ER_Account_Name__c)) mapAccountPerFCType.put(fc.ER_Account_Name__c, new Map<String, List<ER_Financial_Center__c>>());
        if(!mapAccountPerFCType.get(fc.ER_Account_Name__c).containsKey(fc.ER_Type__c)) mapAccountPerFCType.get(fc.ER_Account_Name__c).put(fc.ER_Type__c, new List<ER_Financial_Center__c>());
        mapAccountPerFCType.get(fc.ER_Account_Name__c).get(fc.ER_Type__c).add(fc);
    }

    for(Lead ld :listLeads) {
        String fcType = (ld.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT) ? Constants.FC_CLIENT_TYPE : Constants.FC_MERCHANT_TYPE);

        //OLA BUG 5009 28/11/2019
        if(ld.ConvertedOpportunityId != null) opportunitiesToUpdate.add(new Opportunity(Id = ld.ConvertedOpportunityId, Description = ld.Description));

        //OLA Add New Conditions for Type. 29042019
        if(ld.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_MERCHANT_RT)) {
            //////// Update the address of the account with the custom address of the lead
            accConverted = new Account();
            accConverted.Id = ld.ConvertedAccountId;
            accConverted.BillingStreet = ld.ER_Legal_Street__c;
            accConverted.BillingCity = ld.ER_Legal_City__c;
            accConverted.BillingCountry = ld.ER_Legal_Country__c;
            accConverted.BillingPostalCode = ld.ER_Legal_Zip_Code__c;
            accConverted.BillingState = ld.ER_Legal_State_Province__c;
            accConverted.ER_Country_Code__c = ld.ER_Legal_Country_Code__c;
            accountsToUpdate.add(accConverted);

        } else if(ld.RecordTypeId == Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, Constants.LEAD_CLIENT_RT)) {
            accountsToUpdate.add(new Account(Id = ld.ConvertedAccountId, ER_Country_Code__c = ld.ER_Country_Code__c));
        }

        //Create FC and Structure only if no FC having same lead's type exists for the account
        if(mapAccountPerFCType.isEmpty() || !mapAccountPerFCType.get(ld.ConvertedAccountId).containsKey(fcType)) {
            insertFinancialCenter(ld, fcType);
        } else if(ld.ER_SmartER_Context__c) {
            //Flag the existing FC as smarter if it wasn't already the case
            for(ER_Financial_Center__c fc :mapAccountPerFCType.get(ld.ConvertedAccountId).get(fcType)) {
                if(String.isNotBlank(ld.ER_Registration_Number__c)
                        && ld.ER_Registration_Number__c == fc.ER_Account_Name__r.ER_Registration_Number__c
                        && !fc.ER_SmartER_Context__c) {
                    fc.ER_SmartER_Context__c = false;
                    fcToBeUpdated.add(fc);
                }
            }
            System.debug('>>>>> ALK - fcToBeUpdated : ' + fcToBeUpdated);
        }
    }

    if(!accountsToUpdate.isEmpty()) update accountsToUpdate;
    if(!opportunitiesToUpdate.isEmpty()) update opportunitiesToUpdate;
    if(!fcToBeUpdated.isEmpty()) Database.update(fcToBeUpdated, false);
  }

  private static void insertFinancialCenter(Lead ld, String financialCenterType) {
    List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey(Constants.FC_DEFAULT_PAYMENTSITE));

    Database.SaveResult sr;
    Database.SaveResult sr1;
    Database.SaveResult sr2;
    Database.SaveResult sr3;
    ER_Store__c mystore = null;
    APER30_FinancialCenter_Management.Bypass_FI_VR_OPT = false;
    //Boolean isPaymentSite = ((ld.ER_BUPicklist__c == 'BENELUX'|| ld.ER_BUPicklist__c == 'ES')&& ld.ER_Lead_Type__c == System.Label.LAB_SF_Lead_Type_Merchant);
    Boolean isPaymentSite = (bus.contains(ld.ER_BUPicklist__c) &&
    ld.ER_Lead_Type__c == System.Label.LAB_SF_Lead_Type_Merchant);

    ER_Financial_Center__c myFinancialCenter = new ER_Financial_Center__c(
      Name = ld.Company?.left(80),
      ER_Account_Name__c = ld.ConvertedAccountId,
      ER_Street__c = (String.isNotBlank(ld.ER_Legal_Street__c) ? ld.ER_Legal_Street__c : ld.Street),
      ER_City__c = (String.isNotBlank(ld.ER_Legal_City__c) ? ld.ER_Legal_City__c : ld.City),
      ER_Zip_Code__c = (String.isNotBlank(ld.ER_Legal_Zip_Code__c) ? ld.ER_Legal_Zip_Code__c : ld.PostalCode),
      ER_State_Province__c = (String.isNotBlank(ld.ER_Legal_State_Province__c)
        ? ld.ER_Legal_State_Province__c
        : ld.State),
      ER_Country__c = (String.isNotBlank(ld.ER_Legal_Country__c) ? ld.ER_Legal_Country__c : ld.Country),
      ER_Country_Code__c = ld.ER_Legal_Country_Code__c,
      ER_Invoicing_Site__c = !isPaymentSite,
      ER_Invoicing_Street__c = (String.isNotBlank(ld.ER_Legal_Street__c) ? ld.ER_Legal_Street__c : ld.Street),
      ER_Invoicing_City__c = (String.isNotBlank(ld.ER_Legal_City__c) ? ld.ER_Legal_City__c : ld.City),
      ER_Invoicing_Zip_Code__c = (String.isNotBlank(ld.ER_Legal_Zip_Code__c) ? ld.ER_Legal_Zip_Code__c : ld.PostalCode),
      ER_Invoicing_Country__c = (String.isNotBlank(ld.ER_Legal_Country__c) ? ld.ER_Legal_Country__c : ld.Country),
      ER_Invoicing_Country_Code__c = ld.ER_Legal_Country_Code__c,
      ER_Invoicing_Region_State__c = (String.isNotBlank(ld.ER_Legal_State_Province__c)
        ? ld.ER_Legal_State_Province__c
        : ld.State),
      ER_SmartER_Context__c = ld.ER_SmartER_Context__c,
      ER_Contact__c = (ld.ER_SmartER_Context__c ? ld.ConvertedContactId : null),
      ER_SmartER_Original_Lead_Id__c = ld.Id,
      ER_Payment_Site__c = isPaymentSite,
      ER_BUPicklist__c = ld.ER_BUPicklist__c,
      OwnerId = (ld.ER_SmartER_Context__c && String.valueOf(ld.OwnerId).left(3) == Constants.USER_OBJECT_PREFIX
        ? ld.OwnerId
        : UserInfo.getUserId()),
      ER_Type__c = financialCenterType,
      ER_dd_Trace_Id__c = (ld.ER_SmartER_Context__c ? ld.ER_dd_Trace_Id__c : null),
      ERFI_OVT_Code__c = ld.ER_OVT_Code__c,
      ERFI_OVT_Operator__c = ld.ER_OVT_Operator__c
    );

    if (myFinancialCenter.ER_BUPicklist__c == 'FI')
      myFinancialCenter.ER_Preferred_Invoicing_Method__c = Constants.E_Invoice;

    // Insert the "Financial Center"
    sr = Database.insert(myFinancialCenter, false);

    if (sr.isSuccess() && !APER30_FinancialCenter_Management.Bypass_Store_Creation) {
      // Operation was successful, so get the ID of the record that was processed
      System.debug('The batch has been successfully proceed. Financial Center ID: ' + sr.getId());

      if (myFinancialCenter.ER_Type__c == Label.LABS_SF_FinancialCenter_Merchant) {
        mystore = new ER_Store__c(
          Name = ld.ER_Store_Name__c != null ? ld.ER_Store_Name__c : ld.Company,
          ER_Merchant__c = ld.ConvertedAccountId,
          ER_Financial_Center__c = myFinancialCenter.Id,
          ER_Street__c = ld.Street,
          ER_City__c = ld.City,
          ER_Zip_Code__c = ld.PostalCode,
          ER_Country__c = ld.Country,
          ER_Country_Code__c = ld.ER_Country_Code__c,
          TECH_StoreCreationViaLeadConversion__c = true
        );

        // Insert the "Financial Center"
        sr1 = Database.insert(mystore, false);

        System.debug('The batch has been successfully proceed. Store Center ID: ' + sr1.getId() + mystore);
        ER_Acceptor__c myAcceptor = null;

        if (sr1.isSuccess()) {
          mystore.TECH_StoreCreationViaLeadConversion__c = false;
          sr2 = Database.update(mystore, false);
          if (ld.ER_Terminal__c == 'Yes') {
            myAcceptor = new ER_Acceptor__c(
              Name = mystore.Name,
              ER_Store__c = mystore.Id,
              ER_Start_Date__c = Date.today(),
              ER_AID__c = ld.ER_AID__c,
              ER_AID_Authorization__c = ld.ER_AID_Authorization__c,
              ER_AID_Clearing__c = ld.ER_AID_Clearing__c,
              ER_MCC_Authorization__c = ld.ER_MCC_Authorization__c,
              ER_MCC_Clearing__c = ld.ER_MCC_Clearing__c,
              ER_MID__c = ld.ER_MID__c,
              ER_MID_Authorization__c = ld.ER_MID_Authorization__c,
              ER_MID_Clearing__c = ld.ER_MID_Clearing__c,
              ER_MID_AID__c = ld.ER_MID_AID__c,
              ER_SubMID_Authorization__c = ld.ER_Sub_MID_Authorization__c,
              ER_Sub_MID_Clearing__c = ld.ER_Sub_MID_Clearing__c,
              ER_TID_Authorization__c = ld.ER_TID_Authorization__c,
              ER_TID_Clearing__c = ld.ER_TID_Clearing__c,
              TECH_AcceptorCreationViaLeadConversion__c = true
            );

            sr1 = Database.insert(myAcceptor, false);

            if (sr1.isSuccess()) {
              myAcceptor.TECH_AcceptorCreationViaLeadConversion__c = false;
              sr3 = Database.update(myAcceptor, false);
            }
            myAcceptor = null;
          }
        } else {
          for (Database.Error err : sr.getErrors())
            System.debug('>>>>> insertFinancialCenter - insert err: ' + err.getMessage());
        }
      }
    }
    myFinancialCenter = null;
  }
}