/*
----------------------------------------------------------------------
-- - Name          : APHU12_Contract_Management
-- - Author        : OLA
-- - Description   : Contract Management, This class is used to group all the functionnality linked to the object Contract
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  FEB-2019       OLA                 1.0         Initial version.
--  Jan-2020       OLA                 2.0         Add Offline Mode.
--  FEB-2020       VJOY                3.0         Add Max, Min, LineType in query CLI.
---------------------------------------------------------------------------------------
*/
public class APHU12_Contract_Management {
  public static List<Contract> createContractFromQuote(Map<id, Quote> acceptedQuoteMap) {
    return APER12_Contract_Management.createContractFromQuote(acceptedQuoteMap);
  }

  public static Void createCLIAndUpdateOpportunity(Map<id, Quote> acceptedQuoteMap) {
    APER12_Contract_Management.createCLIAndUpdateOpportunity(acceptedQuoteMap);
  }

  @Future
  public static void deleteContractFromQuote(Set<id> deniedQuoteContractids) {
    APER12_Contract_Management.deleteContractFromQuote(deniedQuoteContractids);
  }

  @AuraEnabled
  public static List<Contract> getContract(String contractId) {
    return APER12_Contract_Management.getContract(contractId);
  }

  public static Map<Id, ER_ContractLineItem__c> getContractLineItems(String contractId) {
    return APER12_Contract_Management.getContractLineItems(contractId);
  }

  /*
	* LASFAR
	* 14/02/2019
	* contractAmendment : 2 cases:
				1- Clone the opportunity linked to the current contract
				2- Create new Opportunity from the current contract (contract came from data init)
	*/
  @AuraEnabled
  public static Opportunity contractAmendment(String contractId, String opportunityId) {
    return APER12_Contract_Management.contractAmendment(contractId, opportunityId);
  }

  @AuraEnabled
  public static void activateContractController(Contract contract, String opportunityId, Boolean isOfflineBU) {
    APER12_Contract_Management.activateContractController(contract, opportunityId, isOfflineBU);
  }

  /*
   * LASFAR
   * 27/03/2019
   * terminateContract : For batch process, update status to Terminated when WS status is succeeded.
   */
  public static void terminateContract(Contract contract, Boolean isOfflineBU) {
    APER12_Contract_Management.terminateContract(contract, isOfflineBU);
  }

  /*
   * LASFAR
   * 14/02/2019
   * deleteCLIFromContract : For each deleted contract delete linked contract line items (no Master detail RelationShip)
   */
  public static void deleteCLIFromContract(Map<id, Contract> contractMap) {
    APER12_Contract_Management.deleteCLIFromContract(contractMap);
  }

  /*
   *
   */
  @AuraEnabled
  public static Account getAccountWS(Id accId) {
    return APHU11_EdgSyncCallout.getAccountWS(accId);
  }

  @AuraEnabled
  public static String beforeEdgWS(Id merchantId, ID contractId) {
    return APHU11_EdgSyncCallout.beforeEdgWS(merchantId, contractId);
  }

  /**
   * @author Noor
   * @date 14/09/2021
   * @description Check if the solution Product Code to be added, already exist on an active contract within same contract period
   *
   * @param merchantId Account
   * @param contractId Contract
   * @return
   */
  @AuraEnabled
  public static String checkExistingSolutionsContractOnAccount(Id merchantId, ID contractId) {
    APHU14_ResponseBeforeEdg validationWrapper = new APHU14_ResponseBeforeEdg();
    List<APHU13_ErrorBeforeEdg> existingSolutionErr = new List<APHU13_ErrorBeforeEdg>();

    validationWrapper.count = 0;
    validationWrapper.existing = false;
    if (!UtilsBypass.getCurrentUser().ER_BypassVR__c) {
      List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('Bypass_Active_Contract_Process'));
      List<String> zuoraDeployedBU = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('ZUORA_DEPLOYED_BUs'));

      List<Contract> contractList = getContract(contractId);

      Boolean isTypeOperational = contractList[0].ER_Contract_Type__c.equals('Operational');

      if (isTypeOperational) {
        Id amendmentContractId = getAmendmentContractId(contractList[0]);

        List<Account> merchantList = getExistingSolutionByAccount(
            new List<Id>{ merchantId },
            amendmentContractId,
            contractList[0].Id,
            contractList[0].StartDate,
            contractList[0].EndDate
          )
          .values();

        if (
          !bus.contains(contractList[0].ER_Business_Unit__c) &&
          zuoraDeployedBU.contains(contractList[0].ER_Business_Unit__c)
        )
          existingSolutionErr = APER12_Contract_Management.checkExistingSolutionsContractOnAccount(
            merchantList[0],
            contractList[0]
          );
      }
      if (!existingSolutionErr.isEmpty()) {
        validationWrapper.data = existingSolutionErr;
        validationWrapper.count = existingSolutionErr.size();
      }
    }
    return JSON.serialize(validationWrapper);
  }

  /**
   * @author snica
   * @date 10/02/2022
   * @description Check if startDate is populated on acceptor
   *
   * @param merchant Account
   * @return
   */
  public static List<APHU13_ErrorBeforeEdg> checkStartDateAcceptor(Account merchant) {
    List<APHU13_ErrorBeforeEdg> listError = new List<APHU13_ErrorBeforeEdg>();

    ER_Acceptor__c acceptor = new ER_Acceptor__c();
    acceptor = [SELECT id, name, ER_Start_Date__c FROM ER_Acceptor__c WHERE ER_Aggregator__c = :merchant.Id];
    if (acceptor.ER_Start_Date__c == null) {
      APHU13_ErrorBeforeEdg rowStartDate = new APHU13_ErrorBeforeEdg();
      rowStartDate.sObjName = 'Acceptor';
      rowStartDate.sName = acceptor.Name;
      rowStartDate.sMessage = Label.FIELD_START_DATE_MANDATORY;
      rowStartDate.sLink = '/lightning/r/ER_Acceptor__c/' + acceptor.Id + '/view';
      rowStartDate.sSection = 'Acceptor Information-Start Date';
      listError.add(rowStartDate);
    }

    return listError;
  }

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

    String accountLegalName = merchant.ER_Legal_Name__c;
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
    }

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

    String accountHeadOfficeContact = merchant.HU_HQ_Contact__c;
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
    }

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

    String accountName = merchant.Name;
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
    }

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

    for (ER_Store__c store : merchant.Stores__r) {
      if (String.isBlank(store.ER_Contact__c) && merchant.ER_Creation_date_in_OS__c == null) {
        APHU13_ErrorBeforeEdg rowAccStreet = new APHU13_ErrorBeforeEdg();
        rowAccStreet.sObjName = 'Store';
        rowAccStreet.sName = store.Name;
        rowAccStreet.sMessage = Label.FIELD_STORE_CONTACT_MANDATORY;
        rowAccStreet.sLink = '/lightning/r/ER_Store__c/' + store.Id + '/view';
        rowAccStreet.sSection = 'Store information';
        listError.add(rowAccStreet);
      }
    }
    return listError;
  }

  public static Map<Id, Account> getExistingSolutionByAccount(
    List<Id> accountIds,
    Id amendmentContractId,
    Id contractId,
    Date startDate,
    Date endDate
  ) {
    //Get ER_Account_Line_Item record Type Id
    String Account_Line_ItemRTId = Utils.getRecordTypeIdByDeveloperName(
      ER_Solution_Line_Item__c.SObjectType,
      'ER_Account_Line_Item'
    );

    return new Map<Id, Account>(
      [
        SELECT
          Id,
          Name,
          ER_BUPicklist__c,
          BillingStreet,
          BillingCity,
          BillingPostalCode,
          ER_Creation_date_in_OS__c,
          ER_Legal_Name__c,
          HU_HQ_Contact__c,
          (
            SELECT
              Id,
              ER_Solution__c,
              ER_Solution__r.BU_External_Reference__c,
              ER_Contract__c,
              ER_Contract__r.ContractNumber,
              ER_Contract__r.EndDate,
              ER_Contract__r.StartDate
            FROM Solution_Line_Items__r
            WHERE
              ER_Contract__c != :amendmentContractId
              AND ER_Contract__c != :contractId
              AND RecordTypeId = :Account_Line_ItemRTId
              AND ER_Solution__r.zqu__Category__c = 'Base Products'
              AND ER_Contract__r.StartDate <= :endDate
              AND (ER_Contract__r.EndDate >= :startDate
              OR ER_Contract__r.EndDate = NULL)
          ),
          (SELECT Id, Name, ER_Contact__c FROM Stores__r WHERE ER_Status__c = 'Active')
        FROM Account
        WHERE Id IN :accountIds
      ]
    );
  }

  public static Id getAmendmentContractId(Contract con) {
    return con.ER_OpportunityId__r.ER_IsAmended__c ? con.ER_OpportunityId__r.ER_AmendedFromContract__c : null;
  }

  @AuraEnabled
  public static String[] saveEdgWS(Id merchantId, ID contractId) {
    return APHU11_EdgSyncCallout.saveEdgWS(merchantId, contractId);
  }

	public static String checkExistingSolutionsContract(Contract contractInst) {
		Set<String> solutionSetToCheck = new Set<String>();
		Map<String,String> mapContractSolutionToCheck = new Map<String,String>();
		Set<String> currentsolutionSet = new Set<String>();
		Map<String,String> mapContractCurrentSolution = new Map<String,String>();
		String amendedFrom = '';
		System.debug('***DA contractInst ' + contractInst);
		System.debug('***DA contractInst ' + contractInst.ER_OpportunityId__r);
		System.debug('***DA contractInst ' + contractInst.ER_OpportunityId__r.ER_IsAmended__c);

    List<String> bus = Utils.splitValues(Utils.getGlobalSettingsValueFromKey('Bypass_Active_Contract_Process'));

		if (contractInst.ER_OpportunityId__r.ER_IsAmended__c) {
			amendedFrom = String.isNotBlank(contractInst.ER_OpportunityId__r.ER_AmendedFromContract__c)
					? contractInst.ER_OpportunityId__r.ER_AmendedFromContract__c
					: contractInst.ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId;
		}

		for (Contract contrat : [SELECT Id, Status, ContractNumber,
										(SELECT Id, ER_Contract__c, ER_Solution__c FROM ER_ContractLineItems__r)
									FROM Contract
									WHERE AccountId = : contractInst.AccountId
									AND ER_Contract_Type__c = :contractInst.ER_Contract_Type__c
                                 	AND Status = : Constants.ACTIVATED
                                 	AND Id != : amendedFrom
									AND RecordType.DeveloperName = :contractInst.RecordType.DeveloperName
                                 	AND ER_BUPicklist__c NOT IN :bus]) {
			for (ER_ContractLineItem__c cli : contrat.ER_ContractLineItems__r) {
				if (contrat.Id == contractInst.Id) {

					currentsolutionSet.add(cli.ER_Solution__c);
					mapContractCurrentSolution.put(cli.ER_Solution__c,contrat.ContractNumber);
				} else if(contrat.Status == Label.LABS_SF_Contract_Status_Activated) {

					solutionSetToCheck.add(cli.ER_Solution__c);
					mapContractSolutionToCheck.put(cli.ER_Solution__c,contrat.ContractNumber);
				}
			}
		}
		System.debug('### checkExistingSolutionsContract');
		System.debug('### currentsolutionSet : '+currentsolutionSet);
		System.debug('### solutionSetToCheck : '+solutionSetToCheck);
        System.debug('### mapContractCurrentSolution : '+mapContractCurrentSolution);
        System.debug('### mapContractSolutionToCheck : '+mapContractSolutionToCheck);

		for (String newSolutions : mapContractCurrentSolution.keySet()) {
			if (mapContractSolutionToCheck.containsKey(newSolutions)) {
				return newSolutions + ':' + mapContractSolutionToCheck.get(newSolutions);
			}
		}
		
		return '';
	}


  /* VJO - Method commented as not in use
	@AuraEnabled
	public static String[] saveContractEdgWS(Contract contractInst,String action) {

		List<String> responseToshow =  new List<String>();
		WSHU04_ContractTemplateWS.ContractResponse contractWSResponse;
        WSHU04_ContractTemplateWS.ContractResponse contractCloseWSResponse;
		HttpResponse res;
		String responseErrorStatusMessage;
		String messageToDisplay = '';
		Boolean isUpdate = false;

		// Get linked contract line items
		Map<String, List<ER_ContractLineItem__c>> mapSolutionCliToInsert= new Map<String, List<ER_ContractLineItem__c>>();
		Map<String, List<ER_ContractLineItem__c>> mapSolutionCliToUpdate= new Map<String, List<ER_ContractLineItem__c>>();
        Map<String, List<ER_ContractLineItem__c>> mapProductSolCodeGone= new Map<String, List<ER_ContractLineItem__c>>();
		List<ER_ContractLineItem__c> cliListToMap = new List<ER_ContractLineItem__c>();
		List<ER_ContractLineItem__c> cliList = [Select id, ER_IsActive__c, Name,ER_Contract__r.ER_PaymentTerms2__c,ER_Contract__r.ER_PaymentMethod2__c,ER_Contract__r.ER_InvoicingFrequency2__c,ER_Contract__r.ER_ReimbursementTerm2__c ,ER_Contract__r.StartDate, ER_Contract__r.EndDate,ER_Contract__r.ER_Indexation__c,ER_Contract__r.ER_OppIndexation2__c, ER_ProductCode__c, ER_Solution__c, ER_Product2__r.ER_Do_Not_Synchronize__c, ER_UnitPrice__c, ER_Percentage__c, CurrencyIsoCode, ER_Creation_date_in_OS__c, ER_End_Date__c, ER_Minimum_Fee__c, ER_Line_Type__c, ER_Max__c, ER_Min__c from ER_ContractLineItem__c where ER_Contract__c = : contractInst.Id];
		Map<String, ER_ContractLineItem__c> mapProductSolCodeToCLI = new Map<String, ER_ContractLineItem__c>();
		Map<String, ER_ContractLineItem__c> mapProductCodeToCLI = new Map<String, ER_ContractLineItem__c>();
        

		List<Contract> allAcountContracts = [Select id, ER_Creation_date_in_OS__c, ER_Last_date_of_Sync__c  from Contract where AccountId = : contractInst.AccountId and Status = :Label.LABS_SF_Contract_Status_Activated ];
		String checkResult = '';

		if(action != 'Termination'){//exclude batch processes
			System.Debug('**DA ' + contractInst );
			checkResult = checkExistingSolutionsContract(contractInst);
		}

		if(String.isNotBlank(checkResult)){

			responseToshow.add('failed');
			responseToshow.add(Label.LABS_SF_ActivateContract_SolutionExist+checkResult);
			return responseToshow;
		}

		for (Contract contract : allAcountContracts) {
			if(contract.ER_Creation_date_in_OS__c != null || contract.ER_Last_date_of_Sync__c != null){
				//update
				isUpdate = true;
			}
		}
		
		if (isUpdate) {
			
			for (ER_ContractLineItem__c cli : cliList) {
				cli.ER_IsActive__c = true;
				if (mapSolutionCliToUpdate.get(cli.ER_Solution__c) != null) {

					cliListToMap = mapSolutionCliToUpdate.get(cli.ER_Solution__c);
					cliListToMap.add(cli);
					mapSolutionCliToUpdate.put(cli.ER_Solution__c, cliListToMap);
				} else {

					cliListToMap = new List<ER_ContractLineItem__c>();
					cliListToMap.add(cli);
					mapSolutionCliToUpdate.put(cli.ER_Solution__c, cliListToMap);
				}
				mapProductCodeToCLI.put(cli.ER_ProductCode__c, cli);
				mapProductSolCodeToCLI.put(cli.ER_Solution__c, cli);
				
			}
            System.debug('### mapSolutionCliToUpdate befooooooooooooore : '+mapSolutionCliToUpdate);
			System.Debug('*DA contractInst' + contractInst);
			System.Debug('*DA contractInst isammend' + contractInst.ER_OpportunityId__r.ER_IsAmended__c);
			System.Debug('*DA action ' + action);
			//Check Disabled Services
			if (contractInst.ER_OpportunityId__r.ER_IsAmended__c && action != 'Termination') {

				String amendedFrom = String.isNotBlank(contractInst.ER_OpportunityId__r.ER_AmendedFromContract__c) ? contractInst.ER_OpportunityId__r.ER_AmendedFromContract__c : contractInst.ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId;
				List<ER_ContractLineItem__c> oldCliList = [Select id, ER_IsActive__c, Name,ER_Contract__r.ER_PaymentTerms2__c,ER_Contract__r.ER_PaymentMethod2__c,ER_Contract__r.ER_InvoicingFrequency2__c, ER_Contract__r.StartDate, ER_Contract__r.EndDate,ER_Contract__r.ER_Indexation__c,ER_Contract__r.ER_OppIndexation2__c, ER_ProductCode__c, ER_Solution__c, ER_Product2__r.ER_Do_Not_Synchronize__c, ER_UnitPrice__c, ER_Percentage__c, CurrencyIsoCode, ER_Creation_date_in_OS__c, ER_End_Date__c, ER_Minimum_Fee__c, ER_Line_Type__c, ER_Max__c, ER_Min__c  from ER_ContractLineItem__c where ER_Contract__c = : amendedFrom];
				Boolean serviceExist = false;
				List<ER_ContractLineItem__c> cliToDisable = new List<ER_ContractLineItem__c>();
				for (ER_ContractLineItem__c cli : oldCliList) {
					cliToDisable = new List<ER_ContractLineItem__c>();
					/*if (!mapProductSolCodeToCLI.containsKey(cli.ER_Solution__c) && !cli.ER_Product2__r.ER_Do_Not_Synchronize__c) {

						//cli.ER_end_Date__c = Date.today();
						//cliToDisable.add(cli);
						System.debug('Solution GONE : '+cli.ER_Solution__c+' Service GONE : '+cli.ER_ProductCode__c);
						cli.ER_end_Date__c = Date.today();
						cli.ER_IsActive__c = false;
						if(mapSolutionCliToUpdate.containsKey(cli.ER_Solution__c)){

							cliToDisable = mapSolutionCliToUpdate.get(cli.ER_Solution__c);
						}
						cliToDisable.add(cli);
						mapSolutionCliToUpdate.put(cli.ER_Solution__c, cliToDisable);
                        mapProductSolCodeGone.put(cli.ER_Solution__c, cliToDisable); // KHAD
						//mapProductCodeToCLI.put(cli.ER_Solution__c, cli);
					}
					else if(!mapProductCodeToCLI.containsKey(cli.ER_ProductCode__c) && !cli.ER_Product2__r.ER_Do_Not_Synchronize__c){
						System.debug('Service GONE : '+cli.ER_ProductCode__c);	
						cli.ER_IsActive__c = false;
						cliToDisable = mapSolutionCliToUpdate.get(cli.ER_Solution__c);
						cliToDisable.add(cli);
						mapSolutionCliToUpdate.put(cli.ER_Solution__c, cliToDisable);
					} */

  /*VJO
					if (!mapProductSolCodeToCLI.containsKey(cli.ER_Solution__c) && !cli.ER_Product2__r.ER_Do_Not_Synchronize__c) {

						//cli.ER_end_Date__c = Date.today();
						//cliToDisable.add(cli);
						System.debug('Solution GONE : '+cli.ER_Solution__c+' Service GONE : '+cli.ER_ProductCode__c);
						cli.ER_end_Date__c = Date.today();
						cli.ER_IsActive__c = false;
						if(mapSolutionCliToUpdate.containsKey(cli.ER_Solution__c)){

							cliToDisable = mapSolutionCliToUpdate.get(cli.ER_Solution__c);
						}
						cliToDisable.add(cli);
						//mapSolutionCliToUpdate.put(cli.ER_Solution__c, cliToDisable);
                        mapProductSolCodeGone.put(cli.ER_Solution__c, cliToDisable); // KHAD
						//mapProductCodeToCLI.put(cli.ER_Solution__c, cli);
					}
					else if(!mapProductCodeToCLI.containsKey(cli.ER_ProductCode__c) && !cli.ER_Product2__r.ER_Do_Not_Synchronize__c){
						System.debug('Service GONE : '+cli.ER_ProductCode__c);	
						cli.ER_IsActive__c = false;
						cliToDisable = mapSolutionCliToUpdate.get(cli.ER_Solution__c);
						cliToDisable.add(cli);
						//mapSolutionCliToUpdate.put(cli.ER_Solution__c, cliToDisable);
					}                    
				}
			}
		} else{
			for (ER_ContractLineItem__c cli : cliList) {
				cli.ER_IsActive__c = true;
				if (mapSolutionCliToInsert.get(cli.ER_Solution__c) != null) {

					cliListToMap = mapSolutionCliToInsert.get(cli.ER_Solution__c);
					cliListToMap.add(cli);
					mapSolutionCliToInsert.put(cli.ER_Solution__c, cliListToMap);
				} else {

					cliListToMap = new List<ER_ContractLineItem__c>();
					cliListToMap.add(cli);
					mapSolutionCliToInsert.put(cli.ER_Solution__c, cliListToMap);
				}
			}
		}
		
		System.debug('### mapSolutionCliToInsert : '+mapSolutionCliToInsert);
		System.debug('### mapSolutionCliToUpdate : '+mapSolutionCliToUpdate);
        System.debug('### mapProductSolCodeGone : '+mapProductSolCodeGone);
		if (!mapSolutionCliToInsert.isEmpty() || !mapSolutionCliToUpdate.isEmpty()) {
			try {
				//OLA 07112019 : Add conditions to support batch termination.
				if(!mapSolutionCliToUpdate.isEmpty()){
                    if(action == 'Termination'){

                    	contractCloseWSResponse = WSHU05_SynchronizeContractWS.callCloseContractWS(contractInst, mapSolutionCliToUpdate);
                    }
                    else{

                    	contractCloseWSResponse = WSHU05_SynchronizeContractWS.callCloseContractWS(contractInst, mapProductSolCodeGone);
                    }
                    
                    System.debug('### contractWSClose Response : ' + contractCloseWSResponse);
                	
					if((contractCloseWSResponse != null && contractCloseWSResponse.meta != null && contractCloseWSResponse.meta.status == 'succeeded')|| contractCloseWSResponse.meta.messages[0].code == Label.LABS_SF_Contract_AlreadyClosed)
                    {	
                    	if(action == 'Termination'){

                			updateContractWsInfos(contractInst, false, action);
                			return null;
                    	}
                    	else{

							contractWSResponse = WSHU05_SynchronizeContractWS.callContractWS(contractInst, mapSolutionCliToUpdate, true);
                    	}
                    }
                    else if(contractCloseWSResponse != null && contractCloseWSResponse.meta != null && contractCloseWSResponse.meta.messages != null){
						for (WSHU04_ContractTemplateWS.Message message : contractCloseWSResponse.meta.messages) {

							messageToDisplay += message.text + ' ';
						}
						if(String.isNotBlank(messageToDisplay)){

							throw new APHU12_Contract_Management_Exception(messageToDisplay);
						}
                    	else{

                    		throw new APHU12_Contract_Management_Exception(Label.LAB_SF_Contract_Close_ErrorWS);
                    	}
                    }
                    else{

                    	throw new APHU12_Contract_Management_Exception(Label.LAB_SF_Contract_Close_ErrorWS);
                    }
				}
				else if(!mapSolutionCliToInsert.isEmpty()){

					contractWSResponse = WSHU05_SynchronizeContractWS.callContractWS(contractInst, mapSolutionCliToInsert, false);
				}
				System.debug('### contractWSResponse : ' + contractWSResponse);

				System.debug('### contractWSResponse.meta.messages : ' + contractWSResponse.meta.messages);

				for (WSHU04_ContractTemplateWS.Message message : contractWSResponse.meta.messages) {
					
					String productRef = String.isNotBlank(message.product_ref)?' : '+message.product_ref:' ';
					messageToDisplay += message.code + productRef;
				}

				Map<String, String> mapSolutionsCMOid = new Map<String, String>();
			/*	if (contractWSResponse.data != null && contractWSResponse.data.contractsProducts != null) {
					System.debug('### IN contractWSResponse.data : ' + contractWSResponse.data);
					
                    for (WSHU04_ContractTemplateWS.ContractsProduct contProduct : contractWSResponse.data.contractsProducts) {
						if (contProduct.product != null && String.isNotBlank(contProduct.product.product_ref)) {
							if (!mapSolutionsCMOid.containsKey(contProduct.product.product_ref)) {
								if (contProduct.refs != null && String.isNotBlank(contProduct.refs.reference)) {

									mapSolutionsCMOid.put(contProduct.product.product_ref, contProduct.refs.reference);
								} else {

									mapSolutionsCMOid.put(contProduct.product.product_ref, '');
								}
							}
						}
					}
				}*/

  /*VJO
				if (contractWSResponse.data != null ) {
                    for ( WSHU04_ContractTemplateWS.Data data : contractWSResponse.data ) {
                        System.debug('### IN contractWSResponse.data : ' + data);
                        
                        for (WSHU04_ContractTemplateWS.ContractsProduct contProduct : data.contractsProducts) {
                            if (contProduct.product != null && String.isNotBlank(contProduct.product.product_ref)) {
                                if (!mapSolutionsCMOid.containsKey(contProduct.product.product_ref)) {
                                    if (contProduct.refs != null && String.isNotBlank(contProduct.refs.reference)) {
                                        
                                        mapSolutionsCMOid.put(contProduct.product.product_ref, contProduct.refs.reference);
                                    } else {
                                        
                                        mapSolutionsCMOid.put(contProduct.product.product_ref, '');
                                    }
                                }
                            }
                        }
                    }
                }	
                
                
                /////////////KHAD
				System.debug('### contractWSResponse.meta.status : ' + contractWSResponse.meta.status);
				responseErrorStatusMessage = contractWSResponse.meta.status;
				if (responseErrorStatusMessage == 'failed' && !mapSolutionsCMOid.isEmpty()) {

					responseErrorStatusMessage = 'warning';
				}
				System.debug('responseErrorStatusMessage: ' + responseErrorStatusMessage);
				responseToshow.add(responseErrorStatusMessage);
				responseToshow.add(messageToDisplay);

				if (!mapSolutionsCMOid.isEmpty()) {
					if(responseErrorStatusMessage=='warning'){

						contractInst.ER_WS_StatusCode__c = '3';
						contractInst.ER_WS_Message__c = messageToDisplay;
						updateContractLineItemsFromWS(mapSolutionsCMOid, contractInst, true, action);
					}
					else{
						contractInst.ER_WS_StatusCode__c = 'synchronized';
						contractInst.ER_WS_Message__c = responseErrorStatusMessage;
						updateContractLineItemsFromWS(mapSolutionsCMOid, contractInst, false, action);
					}
				}
				else{
					contractInst.ER_WS_StatusCode__c = 'not_synchronized';
					contractInst.ER_WS_Message__c = messageToDisplay;
					//contractInst.ER_Last_date_of_Sync__c = Datetime.now();
					update contractInst;
				}

			} catch (Exception e) {

				System.debug('### Error message : ' + e.getMessage());
				responseToshow.add('failed');
				//responseToshow.add('Unable to parse the server message.');
				responseToshow.add(e.getMessage());
				contractInst.ER_WS_StatusCode__c = 'not_synchronized';
				contractInst.ER_WS_Message__c = e.getMessage();
				//contractInst.ER_Last_date_of_Sync__c = Datetime.now();
				update contractInst;
				return responseToshow;
			}
		}
		

		return responseToshow;
	}*/

  @AuraEnabled
  public static String[] saveContractEdgWSV3(Id merchantId, Id contractId, String action) {
    /*List<String> responseToshow = new List<String>();
    Set<Id> listofMerchant = new Set<Id>();
    listofMerchant.add(merchantId);
    Set<Id> listofContract = new Set<Id>();
    listofContract.add(contractId);
    Set<Id> ModifiedElements = new Set<Id>();
    List<Contract> contractInst = APER12_Contract_Management.getContract(contractId);
    Map<Id, String> accountsInputScope = new Map<Id, String>();
    String checkResult = '';

    if (action != 'Termination') {
      System.Debug('**DA ' + contractInst);
      checkResult = checkExistingSolutionsContract(contractInst[0]);
    }*/
    //List<Contract> syncScontractSameScope = [SELECT Id FROM Contract WHERE ER_Creation_date_in_OS__c != NULL AND AccountId := contractInst[0].AccountId AND RecordType.DeveloperName := contractInst[0].RecordType.DeveloperName ];
    //accountsInputScope.put(merchantId,(contractInst[0].RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? 'merchant' : 'client'));
    //check if we have another contract with the opposite scope to calculate the input scope on the payload and leave the method parameter empty
    /*List<Contract> syncScontractSameScope = [
      SELECT Id, RecordType.DeveloperName, Status
      FROM Contract
      WHERE
        ER_Creation_date_in_OS__c != NULL
        AND AccountId = :contractInst[0].AccountId
        AND RecordType.DeveloperName = :contractInst[0].RecordType.DeveloperName
    ];
    if (!syncScontractSameScope.isEmpty())
      accountsInputScope.put(
        merchantId,
        (contractInst[0].RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? 'merchant' : 'client')
      );
    system.debug('### syncScontractSameScope : ' + syncScontractSameScope);
    if (String.isNotBlank(checkResult)) {
      responseToshow.add('failed');
      responseToshow.add(Label.LABS_SF_ActivateContract_SolutionExist + checkResult);
      return responseToshow;
    }*/
    //return responseToshow;
    //test sync V3
    /*if (Test.isRunningTest())
      return null;
    else
      return ER_SyncStructureWS.createStructureWS(
        listofMerchant,
        listofContract,
        'PUT',
        'Activation',
        ModifiedElements,
        accountsInputScope
      );
    */
    return null;
  }

  public static void updateContractWsInfos(Contract contractInst, Boolean hasError, String action) {
    if (contractInst.ER_Creation_date_in_OS__c == null) {
      contractInst.ER_Creation_date_in_OS__c = Datetime.now();
    }

    contractInst.ER_Last_date_of_Sync__c = Datetime.now();
    //If Contract was totally synchronized ==> Activate contract
    if (!hasError) {
      if (action == 'Activation') {
        // Hardcoded technical variable. it come from Aura Activation component & Termination Batch.

        activateContractController(contractInst, contractInst.ER_OpportunityId__c, true);
      } else if (action == 'Termination') {
        contractInst.ER_TerminationReason__c = Label.LAB_SF_Contract_Amendment;
        contractInst.ER_Termination_date_in_OS__c = Datetime.now();
        contractInst.ER_Terminated_Date__c = Datetime.now();
        terminateContract(contractInst, false);
      }
    } else {
      //If Contract was partially synchronized ==> Update Sync Dates fields on Contract object
      update contractInst;
    }
  }

  public static void updateContractLineItemsFromWS(
    Map<String, String> mapSolutionsCMOid,
    Contract contractInst,
    Boolean hasError,
    String action
  ) {
    List<Sobject> cliList = new List<Sobject>();
    List<ER_ContractLineItem__c> cliQuery = [
      SELECT
        Id,
        Name,
        ER_Solution__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Line_Type__c,
        ER_Max__c,
        ER_Min__c
      FROM ER_ContractLineItem__c
      WHERE ER_Contract__c = :contractInst.Id AND ER_Solution__c IN :mapSolutionsCMOid.keySet()
    ];
    System.debug('mapSolutionsCMOid : ' + mapSolutionsCMOid);
    System.debug('cliQuery : ' + cliQuery);
    for (ER_ContractLineItem__c cli : cliQuery) {
      if (cli.ER_Card_Operational_System_ID__c == null) {
        cli.ER_Card_Operational_System_ID__c = mapSolutionsCMOid.get(cli.ER_Solution__c);
      }
      if (cli.ER_Creation_date_in_OS__c == null) {
        cli.ER_Creation_date_in_OS__c = Datetime.now();
      }
      cli.ER_Last_date_of_Sync__c = Datetime.now();
      cliList.add(cli);
    }
    if (!cliList.isEmpty()) {
      update cliList;
      updateContractWsInfos(contractInst, hasError, action);
    }
  }

  /*
   * LASFAR
   * 02/01/2020
   * isOfflineBU : Check if the BU is Offline and All Contract's products are synchronized.
   */
  @AuraEnabled
  public static Boolean isOfflineBU(Contract contractInst) {
    return APER12_Contract_Management.isOfflineBU(contractInst);
  }

  public class APHU12_Contract_Management_Exception extends Exception {
  }
}