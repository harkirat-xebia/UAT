/*
 * @author : KHAD
 * @date : 03/06/2021
 * @desc : ER_SyncStructureWithLegacy - This class is used to sync the whole structure with the legacy systems via EDG
 * @see ER_SyncStructureWithLegacy
----------------------------------------------------------------------
-- Maintenance History:
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
-- 02-JUN-2021  KHAD                 1.0         Initial version (EDG Sync V3)
-- 26-JUL-2021  ALK                  1.1         F-12229 - ERES Temporary Discount EDG V3
---------------------------------------------------------------------------------------
*/

public without sharing class ER_SyncStructureWithLegacy {
  public static String scope = 'merchant';
  public static List<String> scopeList = new List<String>();

  /**
   * @author KHAD
   * @date 31/05/2021
   * @param accounts
   * @param contracts
   * @param action
   * @param ModifiedElements
   * @description Sync Contract (Structure) V3
   * @return String
   */
  //Add argument map accountsInputScope
  public static String syncContract(Set<Id> accounts, Set<Id> contracts, String action, Set<Id> ModifiedElements) {
    return 'syncContract Mock';
  }
  public static String syncContract(
    Set<Id> accounts,
    Set<Id> contracts,
    String action,
    Set<Id> ModifiedElements,
    Map<Id, String> accountsInputScope
  ) {
    Map<String, List<Map<String, Object>>> structureMap = new Map<String, List<Map<String, Object>>>();
    Set<Id> ctrId = new Set<Id>();
    //mock the input accountsInputScope
    //Map<Id,String> accountsInputScope = new Map<Id, String>();
    //Common section ---- Add scope in arguments per methode ?
    //Account
    structureMap.put('accounts', buildAccounts(accounts, contracts, ModifiedElements, accountsInputScope));
    //Account Partner
    structureMap.put('account_partners', buildAccountPartners(accounts, ModifiedElements));
    //Account Line Item
    structureMap.put('account_line_items', buildAccountLineItem(accounts, contracts, ModifiedElements));
    //Contacts
    structureMap.put('contacts', buildContacts(accounts, ModifiedElements));
    //Contacts Roles
    structureMap.put('contact_roles', buildContactsRole(accounts, ModifiedElements));
    //Bank Account
    structureMap.put('bank_accounts', buildBankAccount(accounts, ModifiedElements));
    //Financial Centers
    structureMap.put('financial_centers', buildFinancialCenter(accounts, ModifiedElements));
    //Financial Centers Line Item
    structureMap.put(
      'financial_center_line_items',
      buildFinancialCenterLineItem(accounts, contracts, ModifiedElements)
    );
    //Merchant section
    if (scope.contains('merchant')) {
      //Stores
      structureMap.put('stores', buildStores(accounts, ModifiedElements));
      //Stores Line Item
      structureMap.put('store_line_items', buildStoresLineItem(accounts, contracts, ModifiedElements));
      //Store Categories
      structureMap.put('store_categories', buildStoresCategories(accounts, ModifiedElements));
      //Acceptors
      structureMap.put('acceptors', buildAcceptors(accounts, ModifiedElements));
      //Acceptor Line Item buildAcceptorsLineItem
      structureMap.put('acceptor_line_items', buildAcceptorsLineItem(accounts, contracts, ModifiedElements));
    }
    //Client section
    if (scope.contains('client')) {
      //Delivery Sites
      structureMap.put('delivery_sites', buildDeliverySite(accounts, ModifiedElements));
      //Delivery Sites Line Items
      structureMap.put('delivery_site_line_items', buildDeliverySiteLineItem(accounts, contracts, ModifiedElements));
      //Distribution Points
      structureMap.put('distribution_points', buildDistributionPoint(accounts, ModifiedElements));
      //Distribution Points Line Items
      structureMap.put(
        'distribution_point_line_items',
        buildDistributionPointLineItem(accounts, contracts, ModifiedElements)
      );
    }

    // Send contracts and contract line items only when the contract is specified on the imput : post account, contract activation and contract termination use cases
    if (contracts != null && !contracts.isEmpty()) {
      String contractId = null;
      List<Contract> contractList = [
        SELECT
          Id,
          AccountId,
          ER_OpportunityId__c,
          Status,
          ER_OpportunityId__r.ER_IsAmended__c,
          ER_OpportunityId__r.ER_AmendedFromContract__c,
          ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId
        FROM Contract
        WHERE Id IN :contracts
      ];
      //Add the ref to the contract to terminate in case of an amendment
      if (
        String.isNotBlank(contractList[0].ER_OpportunityId__c) && contractList[0].ER_OpportunityId__r.ER_IsAmended__c
      ) {
        if (contractList[0].ER_OpportunityId__r.ER_AmendedFromContract__c != null)
          contractId = contractList[0].ER_OpportunityId__r.ER_AmendedFromContract__c;
        else
          contractId = contractList[0].ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId;
        ctrId.add(contractId);
        //structureMap.put('contracts', buildContracts(null, contracts, ctrId, 'Amendment'));
        //if(contractId != null) contracts.remove(contractId);
      }
    }
    /*
        else{// test send empty body
            List<Map<String, Object>> testlist = new List<Map<String, Object>>();
            //Contracts
            structureMap.put('contracts', testlist);
            //Contracts Line Item
            structureMap.put('contract_line_items', testlist);
        } */
    //Contracts
    structureMap.put('contracts', buildContracts(accounts, contracts, ctrId, action));
    //Contracts Line Item
    structureMap.put('contract_line_items', buildContractsLineItem(accounts, contracts));

    return JSON.serialize(structureMap);
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Account Structure
   * @param accounts
   * @param contracts
   * @param ModifiedElements
   * @param accountsInputScope
   *
   * @return
   */
  public static List<Map<String, Object>> buildAccounts(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> ModifiedElements,
    Map<Id, String> accountsInputScope
  ) {
    //Add  and ER_Creation_date_in_OS__c != null on the solution line item sub query for account scope + calculate global scope based on the input scope + synced scope of the account
    List<Map<String, Object>> listAccountAttributes = new List<Map<String, Object>>();
    Boolean isClient = false;
    Boolean isMerchant = false;
    // Add status = active for the account line items that we query ! or in contract !
    for (Account a : [
      SELECT
        Id,
        Name,
        ParentId,
        ER_Legal_Name__c,
        ER_Decision_maker__c,
        ER_Status__c,
        ER_Registration_Number__c,
        ER_Card_Client_Operational_System_ID__c,
        ER_Not_subject_to_VAT__c,
        ER_VAT_Number__c,
        ER_Other_Fiscal_ID__c,
        ER_VIP__c,
        ER_Insolvency_Executed_Account__c,
        ER_Language__c,
        ER_Legal_Form__c,
        ER_BUPicklist__c,
        Phone,
        CreatedDate,
        HU_HQ_Contact__c,
        LastModifiedDate,
        Website,
        ER_Brands__c,
        ERBE_Has_a_Social_secretary__c,
        ERBE_Social_secretary_needed_for_Orders__c,
        ER_Country_Code__c,
        ER_Segment__c,
        ER_NaceList__c,
        CreatedBy.Email,
        BillingCountry,
        BillingPostalCode,
        BillingState,
        BillingCity,
        BillingStreet,
        BillingLatitude,
        BillingLongitude,
        ER_Sync_result__c,
        ER_WS_result_Text_Long__c,
        ER_Last_date_of_Sync__c,
        ER_Card_Operational_System_ID__c,
        ER_Number_of_stores__c,
        NumberOfEmployees,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c,
        Owner.Email, 
        ER_Email__c, 
        Fax, 
        ER_Industry__c, 
        ER_Tax_Office__c, 
        ER_NaceNameList__c,
        (
          SELECT Id, ER_Scope__c
          FROM Solution_Line_Items__r
          WHERE
            RecordType.DeveloperName = 'ER_Account_Line_Item'
            AND (ER_Global_Status__c = 'Active'
            OR ER_Contract__c IN :contracts)
        )
      FROM Account
      WHERE Id IN :accounts
    ]) {
      String inputScope = accountsInputScope.get(a.Id);
      for (ER_Solution_Line_Item__c ali : a.Solution_Line_Items__r) {
        if (ali.ER_Scope__c == 'client')
          isClient = true;
        if (ali.ER_Scope__c == 'merchant')
          isMerchant = true;
      }
      System.debug('#### KHAD inputScope :' + inputScope);
      System.debug('#### KHAD isClient :' + isClient);
      System.debug('#### KHAD isMerchant :' + isMerchant);
      System.debug('#### KHAD scope :' + scope);
      //Scope = account scope
      if (isClient && isMerchant) {
        scope = 'merchant_client';
      } else if (isClient) {
        scope = 'client';
      }
      // inputscope = connected scope
      if (inputScope != null)
        scope = inputScope;
      //else if (!scope.contains(inputscope)) scope = 'merchant client' ;
      //ScopeList = list of scopes to use in the query
      if (scope.contains('merchant')) {
        scopeList.add('merchant');
      }
      if (scope.contains('client')) {
        scopeList.add('client');
      }
      System.debug('#### KHAD scope after :' + scope);
      Map<String, Object> accountAttributes = new Map<String, Object>();
      Map<String, Object> accountAttributesValues = new Map<String, Object>();
      accountAttributesValues.put('name', a.Name);
      accountAttributesValues.put('legal_name', a.ER_Legal_Name__c);
      accountAttributesValues.put('decision_maker', a.ER_Decision_maker__c);
      accountAttributesValues.put('insert_user_id', a.Owner.Email);
      accountAttributesValues.put(
        'status',
        (a.ER_Status__c != null && a.ER_Status__c == 'Inactive' ? 'Inactive' : 'Active')
      );
      accountAttributesValues.put('registration_number', a.ER_Registration_Number__c);
      accountAttributesValues.put('not_subject_to_vat', a.ER_Not_subject_to_VAT__c);
      accountAttributesValues.put('vat_number', a.ER_VAT_Number__c);
      accountAttributesValues.put('other_fiscal_id', a.ER_Other_Fiscal_ID__c);
      accountAttributesValues.put('vip', a.ER_VIP__c);
      accountAttributesValues.put('insolvency_executed_account', a.ER_Insolvency_Executed_Account__c);
      accountAttributesValues.put('language', a.ER_Language__c);
      accountAttributesValues.put('legal_form', a.ER_Legal_Form__c);
      accountAttributesValues.put('business_unit', a.ER_BUPicklist__c);
      accountAttributesValues.put('stores_number', a.ER_Number_of_stores__c);
      accountAttributesValues.put('employees_number', a.NumberOfEmployees);
      accountAttributesValues.put('phone', a.Phone);
      accountAttributesValues.put('created_date', a.CreatedDate);
      accountAttributesValues.put('last_sync_date', a.ER_Last_date_of_Sync__c);
      accountAttributesValues.put('sync_result', a.ER_Sync_result__c);
      accountAttributesValues.put('client_last_sync_date', null);
      accountAttributesValues.put('client_sync_result', null);
      accountAttributesValues.put('brands', a.ER_Brands__c);
      accountAttributesValues.put('federation_name', null);
      accountAttributesValues.put('has_social_secretary', a.ERBE_Has_a_Social_secretary__c);
      accountAttributesValues.put('social_secretary_name', null);
      accountAttributesValues.put('social_secretary_orders', a.ERBE_Social_secretary_needed_for_Orders__c);
      accountAttributesValues.put('created_by', a.CreatedBy.Email);
      accountAttributesValues.put('nace_code', a.ER_NaceList__c);
      accountAttributesValues.put('local_client_segmentation', a.ER_Segment__c);
      accountAttributesValues.put('website', a.Website);
      accountAttributesValues.put('email', a.ER_Email__c);
      accountAttributesValues.put('fax', a.Fax);
      accountAttributesValues.put('industry', a.ER_Industry__c);
      accountAttributesValues.put('city', a.ER_Tax_Office__c);
      accountAttributesValues.put('local_activity', a.ER_NaceNameList__c);
      //Account Address
      Map<String, Object> accountAddressValues = new Map<String, Object>();
      accountAddressValues.put('country', a.BillingCountry);
      accountAddressValues.put('country_code', (a.BillingStreet != null ? a.ER_Country_Code__c : null));
      accountAddressValues.put('zip_code', a.BillingPostalCode);
      accountAddressValues.put('state', a.BillingState);
      accountAddressValues.put('city', a.BillingCity);
      accountAddressValues.put('street', a.BillingStreet);
      accountAddressValues.put('street_additional', null);
      accountAddressValues.put('address_complement', null);
      accountAddressValues.put('latitude', a.BillingLatitude);
      accountAddressValues.put('longitude', a.BillingLongitude);
      accountAddressValues.put('address_type', null);
      accountAttributesValues.put('address', accountAddressValues);
      accountAttributes.put('attributes', accountAttributesValues);
      //authorities
      List<Map<String, Object>> listAccountAuthorities = new List<Map<String, Object>>();
      Map<String, Object> accountContactAuthoritiesMap = new Map<String, Object>();
      accountContactAuthoritiesMap.put('legacy_name', 'ref_contact_hq');
      accountContactAuthoritiesMap.put('legacy_reference', a.HU_HQ_Contact__c);
      listAccountAuthorities.add(accountContactAuthoritiesMap);
      Map<String, Object> accountAuthoritiesMap = new Map<String, Object>();
      accountAuthoritiesMap.put('legacy_name', 'record_id');
      accountAuthoritiesMap.put('legacy_reference', a.Id);
      listAccountAuthorities.add(accountAuthoritiesMap);
      Map<String, Object> accountParentAuthoritiesMap = new Map<String, Object>();
      accountParentAuthoritiesMap.put('legacy_name', 'ref_account_parent');
      accountParentAuthoritiesMap.put('legacy_reference', a.ParentId);
      listAccountAuthorities.add(accountParentAuthoritiesMap);
      accountAttributes.put('authorities', listAccountAuthorities);
      //synchronization_states
      List<Map<String, Object>> listAccountSyncState = new List<Map<String, Object>>();
      Map<String, Object> accountSyncState = new Map<String, Object>();
      accountSyncState.put('local_id', a.ER_Card_Operational_System_ID__c);
      accountSyncState.put('local_client_id', a.ER_Card_Client_Operational_System_ID__c);
      accountSyncState.put('scope', scope);
      accountSyncState.put(
        'status',
        (a.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(a.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      accountSyncState.put('message', a.ER_WS_result_Text_Long__c);
      accountSyncState.put('code', a.ER_Sync_Code__c);
      accountSyncState.put('event_date', a.ER_Last_date_of_Sync__c);
      accountSyncState.put('last_modification_date', a.LastModifiedDate);
      listAccountSyncState.add(accountSyncState);
      accountAttributes.put('synchronization_states', listAccountSyncState);
      listAccountAttributes.add(accountAttributes);
    }
    return listAccountAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Account Line Item Structure
   * @param accounts
   * @param contracts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildAccountLineItem(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> ModifiedElements
  ) {
    List<Map<String, Object>> listAccountLineItemAttributes = new List<Map<String, Object>>();
    for (ER_Solution_Line_Item__c accli : [
      SELECT
        Id,
        ER_Account__c,
        ER_Parent_Line_Item__r.ER_Global_Status__c,
        ER_Global_Status__c,
        ER_Status__c,
        ER_Terms_Conditions__c,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Solution__r.ProductCode,
        LastModifiedDate,
        ER_Scope__c,
        ER_Contract__r.Status,
        ER_Global_Status_Sync__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Account_Line_Item'
        AND ER_Account__c IN :accounts
        AND (ER_Contract__c IN :contracts
        OR ER_Contract__r.Status = 'Activated')
        AND ER_Scope__c IN :scopeList
    ]) {
      Map<String, Object> accountLineItemAttributes = new Map<String, Object>();
      Map<String, Object> accountLineItemAttributesValues = new Map<String, Object>();
      accountLineItemAttributesValues.put(
        'global_status',
        (accli.ER_Contract__r.Status == 'Draft' ? accli.ER_Global_Status_Sync__c : accli.ER_Global_Status__c)
      );
      accountLineItemAttributesValues.put('status', accli.ER_Status__c);
      accountLineItemAttributesValues.put('specificities', accli.ER_Terms_Conditions__c);
      accountLineItemAttributes.put('attributes', accountLineItemAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> accountAuthoritiesMap = new Map<String, Object>();
      accountAuthoritiesMap.put('legacy_name', 'ref_account');
      accountAuthoritiesMap.put('legacy_reference', accli.ER_Account__c);
      authorities.add(accountAuthoritiesMap);
      Map<String, Object> accountLineItemAuthoritiesMap = new Map<String, Object>();
      accountLineItemAuthoritiesMap.put('legacy_name', 'record_id');
      accountLineItemAuthoritiesMap.put('legacy_reference', accli.Id);
      authorities.add(accountLineItemAuthoritiesMap);
      Map<String, Object> productAuthoritiesMap = new Map<String, Object>();
      productAuthoritiesMap.put('legacy_name', 'ref_product');
      productAuthoritiesMap.put('legacy_reference', accli.ER_Solution__r.ProductCode);
      authorities.add(productAuthoritiesMap);
      accountLineItemAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put(
        'local_id',
        (accli.ER_Scope__c == 'Merchant' ? accli.ER_Card_Operational_System_ID__c : null)
      );
      syncStateValues.put(
        'local_client_id',
        (accli.ER_Scope__c == 'Client' ? accli.ER_Card_Operational_System_ID__c : null)
      );
      syncStateValues.put('scope', accli.ER_Scope__c.toLowerCase());
      syncStateValues.put(
        'status',
        (accli.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(accli.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', accli.ER_WS_result_Text__c); // New fields to be created
      syncStateValues.put('code', accli.ER_Sync_Code__c);
      syncStateValues.put('event_date', accli.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', accli.LastModifiedDate);
      syncState.add(syncStateValues);
      accountLineItemAttributes.put('synchronization_states', syncState);
      listAccountLineItemAttributes.add(accountLineItemAttributes);
    }
    return listAccountLineItemAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Account Partners Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildAccountPartners(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listAccountPartnersAttributes = new List<Map<String, Object>>();
    for (AccountPartner accPrtnr : [
      SELECT Id, IsPrimary, CreatedDate, LastModifiedDate, Role, AccountToId, AccountFromId
      FROM AccountPartner
      WHERE AccountFromId IN :accounts
    ]) {
      Map<String, Object> accountPartnersAttributes = new Map<String, Object>();
      Map<String, Object> accountPartnersAttributesValues = new Map<String, Object>();
      accountPartnersAttributesValues.put('role', accPrtnr.Role);
      accountPartnersAttributesValues.put('primary', accPrtnr.IsPrimary);
      accountPartnersAttributesValues.put('created_date', accPrtnr.CreatedDate);
      accountPartnersAttributesValues.put('last_modified_date', accPrtnr.LastModifiedDate);
      accountPartnersAttributesValues.put('deleted', null);
      accountPartnersAttributes.put('attributes', accountPartnersAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'ref_account_partner');
      authoritiesMap.put('legacy_reference', accPrtnr.AccountToId);
      authorities.add(authoritiesMap);
      accountPartnersAttributes.put('authorities', authorities);
      Map<String, Object> recordIdAuthoritiesMap = new Map<String, Object>();
      recordIdAuthoritiesMap.put('legacy_name', 'record_id');
      recordIdAuthoritiesMap.put('legacy_reference', accPrtnr.Id);
      authorities.add(recordIdAuthoritiesMap);
      accountPartnersAttributes.put('authorities', authorities);
      Map<String, Object> accountAuthoritiesMap = new Map<String, Object>();
      accountAuthoritiesMap.put('legacy_name', 'ref_account');
      accountAuthoritiesMap.put('legacy_reference', accPrtnr.AccountFromId);
      authorities.add(accountAuthoritiesMap);
      accountPartnersAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', null);
      syncStateValues.put('local_client_id', null);
      syncStateValues.put('scope', scope);
      syncStateValues.put('status', null);
      syncStateValues.put('message', null);
      syncStateValues.put('code', null);
      syncStateValues.put('event_date', null);
      syncStateValues.put('last_modification_date', accPrtnr.LastModifiedDate);
      syncState.add(syncStateValues);
      accountPartnersAttributes.put('synchronization_states', syncState);
      listAccountPartnersAttributes.add(accountPartnersAttributes);
    }
    return listAccountPartnersAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Financial Center Structure
   * @param accounts
   * @param ModifiedElements
   * @see APER04_Opportunity_Management
   * @return
   */
  public static List<Map<String, Object>> buildFinancialCenter(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listFinancialCentersAttributes = new List<Map<String, Object>>();
    // Add ER_Type__c in 'Merchant' or 'Client' or both depending on the scope/context
    for (ER_Financial_Center__c fc : [
      SELECT
        Id,
        Name,
        ER_Account_Name__c,
        CreatedDate,
        ER_Card_Operational_System_ID__c,
        ER_Bank_Account__c,
        Owner.Email,
        CreatedBy.Email,
        ER_Paper_Operational_System_ID__c,
        ER_Type__c,
        ER_Payment_Site__c,
        ER_Invoicing_Site__c,
        LastModifiedDate,
        ER_Account_Name__r.ER_BUPicklist__c,
        ER_Accounting_System_ID__c,
        ER_Email__c,
        ER_Contact__c,
        ER_Country_Code__c,
        ER_Invoicing_Country_Code__c,
        ER_Secondary_Email__c,
        ER_Country__c,
        ER_Zip_Code__c,
        ER_State_Province__c,
        ER_City__c,
        ER_Street__c,
        ER_Invoicing_Country__c,
        ER_Invoicing_Zip_Code__c,
        ER_Invoicing_Region_State__c,
        ER_Invoicing_City__c,
        ER_Invoicing_Street__c,
        ER_Sync_result__c,
        ER_WS_result_Text__c,
        ER_Last_Synchronization_Date__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c,
        ER_Preferred_Invoicing_Method__c, 
        ERFI_OVT_Code__c, 
        ERFI_OVT_Operator__c
      FROM ER_Financial_Center__c
      WHERE
        ER_Account_Name__c IN :accounts
        AND ER_Contact__c != NULL
        //AND ER_Bank_Account__c != NULL
        AND ER_Type__c IN :scopeList
    ]) {
      Map<String, Object> financialCentersAttributes = new Map<String, Object>();
      Map<String, Object> financialCentersAttributesValues = new Map<String, Object>();
      financialCentersAttributesValues.put('name', fc.Name);
      financialCentersAttributesValues.put('created_date', fc.CreatedDate);
      financialCentersAttributesValues.put('mid_office_card', fc.ER_Card_Operational_System_ID__c);
      financialCentersAttributesValues.put('mid_office_paper', fc.ER_Paper_Operational_System_ID__c);
      financialCentersAttributesValues.put('fc_type', fc.ER_Type__c);
      financialCentersAttributesValues.put('payment_site', fc.ER_Payment_Site__c);
      financialCentersAttributesValues.put('invoicing_site', fc.ER_Invoicing_Site__c);
      financialCentersAttributesValues.put('business_unit', fc.ER_Account_Name__r.ER_BUPicklist__c);
      financialCentersAttributesValues.put('accounting_system_id', fc.ER_Accounting_System_ID__c);
      financialCentersAttributesValues.put('email', fc.ER_Email__c);
      financialCentersAttributesValues.put('primary_email', fc.ER_Email__c);
      financialCentersAttributesValues.put('secondary_email', fc.ER_Secondary_Email__c);
      financialCentersAttributesValues.put('owner', fc.Owner.Email);
      financialCentersAttributesValues.put('created_by', fc.CreatedBy.Email);
      financialCentersAttributesValues.put('invoicing_method', fc.ER_Preferred_Invoicing_Method__c);
      financialCentersAttributesValues.put('edi_code', fc.ERFI_OVT_Code__c);
      financialCentersAttributesValues.put('edi_operator', fc.ERFI_OVT_Operator__c);
      //Financial Center Billing Address
      Map<String, Object> BillingAddressValues = new Map<String, Object>();
      BillingAddressValues.put('country', fc.ER_Country__c);
      BillingAddressValues.put('country_code', (fc.ER_Street__c != null ? fc.ER_Country_Code__c : null));
      BillingAddressValues.put('zip_code', fc.ER_Zip_Code__c);
      BillingAddressValues.put('state', fc.ER_State_Province__c);
      BillingAddressValues.put('city', fc.ER_City__c);
      BillingAddressValues.put('street', fc.ER_Street__c);
      BillingAddressValues.put('street_additional', null);
      BillingAddressValues.put('address_complement', null);
      BillingAddressValues.put('latitude', null);
      BillingAddressValues.put('longitude', null);
      BillingAddressValues.put('address_type', null);
      financialCentersAttributesValues.put('billing_address', BillingAddressValues);
      //Financial Center Invoicing Address
      Map<String, Object> InvoicingAddressValues = new Map<String, Object>();
      InvoicingAddressValues.put('country', fc.ER_Invoicing_Country__c);
      InvoicingAddressValues.put(
        'country_code',
        (fc.ER_Invoicing_Street__c != null ? fc.ER_Invoicing_Country_Code__c : null)
      );
      InvoicingAddressValues.put('zip_code', fc.ER_Invoicing_Zip_Code__c);
      InvoicingAddressValues.put('state', fc.ER_Invoicing_Region_State__c);
      InvoicingAddressValues.put('city', fc.ER_Invoicing_City__c);
      InvoicingAddressValues.put('street', fc.ER_Invoicing_Street__c);
      InvoicingAddressValues.put('street_additional', null);
      InvoicingAddressValues.put('address_complement', null);
      InvoicingAddressValues.put('latitude', null);
      InvoicingAddressValues.put('longitude', null);
      InvoicingAddressValues.put('address_type', null);
      financialCentersAttributesValues.put('invoicing_address', InvoicingAddressValues);
      financialCentersAttributes.put('attributes', financialCentersAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'ref_contact');
      authoritiesMap.put('legacy_reference', fc.ER_Contact__c);
      authorities.add(authoritiesMap);
      Map<String, Object> authoritiesBankAccountValueMap = new Map<String, Object>();
      authoritiesBankAccountValueMap.put('legacy_name', 'ref_bank_account');
      authoritiesBankAccountValueMap.put('legacy_reference', fc.ER_Bank_Account__c);
      authorities.add(authoritiesBankAccountValueMap);
      Map<String, Object> authoritiesAccountValueMap = new Map<String, Object>();
      authoritiesAccountValueMap.put('legacy_name', 'ref_account');
      authoritiesAccountValueMap.put('legacy_reference', fc.ER_Account_Name__c);
      authorities.add(authoritiesAccountValueMap);
      Map<String, Object> authoritiesFcValueMap = new Map<String, Object>();
      authoritiesFcValueMap.put('legacy_name', 'record_id');
      authoritiesFcValueMap.put('legacy_reference', fc.Id);
      authorities.add(authoritiesFcValueMap);
      financialCentersAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', (fc.ER_Type__c == 'Merchant' ? fc.ER_Card_Operational_System_ID__c : null));
      syncStateValues.put('local_client_id', (fc.ER_Type__c == 'Client' ? fc.ER_Card_Operational_System_ID__c : null));
      syncStateValues.put('scope', fc.ER_Type__c.toLowerCase());
      syncStateValues.put(
        'status',
        (fc.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(fc.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', fc.ER_WS_result_Text__c);
      syncStateValues.put('code', fc.ER_Sync_Code__c);
      syncStateValues.put('event_date', fc.ER_Last_Synchronization_Date__c);
      syncStateValues.put('last_modification_date', fc.LastModifiedDate);
      syncState.add(syncStateValues);
      financialCentersAttributes.put('synchronization_states', syncState);
      listFinancialCentersAttributes.add(financialCentersAttributes);
    }
    return listFinancialCentersAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Financial Center Line Item Structure
   * @param accounts
   * @param contracts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildFinancialCenterLineItem(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> ModifiedElements
  ) {
    List<Map<String, Object>> listFinancialCenterLineItemAttributes = new List<Map<String, Object>>();
    // Add ER_Type__c in 'Merchant' or 'Client' or both depending on the scope/context same as in the financial center
    for (ER_Solution_Line_Item__c fcli : [
      SELECT
        Id,
        ER_Financial_Center__c,
        ER_Parent_Line_Item__r.ER_Global_Status__c,
        ER_Global_Status__c,
        LastModifiedDate,
        ER_Status__c,
        ER_Financial_Center__r.ER_Type__c,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_Terms_Conditions__c,
        ER_WS_result_Text__c,
        ER_Solution__r.ProductCode,
        ER_Bank_Account__c,
        ER_Contract__r.Status,
        LastModifiedBy.Email,
        ER_Global_Status_Sync__c,
        ER_Parent_Line_Item__r.ER_Global_Status_Sync__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Financial_Center_Line_Item'
        AND ER_Financial_Center__r.ER_Account_Name__c IN :accounts
        AND (ER_Contract__c IN :contracts
        OR ER_Contract__r.Status = 'Activated')
        AND ER_Financial_Center__r.ER_Type__c IN :scopeList
    ]) {
      Map<String, Object> financialCenterLineItemAttributes = new Map<String, Object>();
      Map<String, Object> financialCentersLineItemAttributesValues = new Map<String, Object>();
      financialCentersLineItemAttributesValues.put(
        'parent_global_status',
        (fcli.ER_Contract__r.Status == 'Draft'
          ? fcli.ER_Parent_Line_Item__r.ER_Global_Status_Sync__c
          : fcli.ER_Parent_Line_Item__r.ER_Global_Status__c)
      );
      financialCentersLineItemAttributesValues.put(
        'global_status',
        (fcli.ER_Contract__r.Status == 'Draft' ? fcli.ER_Global_Status_Sync__c : fcli.ER_Global_Status__c)
      );
      financialCentersLineItemAttributesValues.put('status', fcli.ER_Status__c);
      financialCentersLineItemAttributesValues.put('specificities', fcli.ER_Terms_Conditions__c);
      financialCentersLineItemAttributesValues.put('last_modified_by', fcli.LastModifiedBy.Email);
      financialCenterLineItemAttributes.put('attributes', financialCentersLineItemAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> financialCenterAuthoritiesMap = new Map<String, Object>();
      financialCenterAuthoritiesMap.put('legacy_name', 'ref_financial_center');
      financialCenterAuthoritiesMap.put('legacy_reference', fcli.ER_Financial_Center__c);
      authorities.add(financialCenterAuthoritiesMap);
      financialCenterLineItemAttributes.put('authorities', authorities);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', fcli.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> productAuthoritiesMap = new Map<String, Object>();
      productAuthoritiesMap.put('legacy_name', 'ref_product');
      productAuthoritiesMap.put('legacy_reference', fcli.ER_Solution__r.ProductCode);
      authorities.add(productAuthoritiesMap);
      Map<String, Object> bankAccountAuthoritiesMap = new Map<String, Object>();
      bankAccountAuthoritiesMap.put('legacy_name', 'ref_bank_account');
      bankAccountAuthoritiesMap.put('legacy_reference', fcli.ER_Bank_Account__c);
      authorities.add(bankAccountAuthoritiesMap);
      financialCenterLineItemAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put(
        'local_id',
        (fcli.ER_Financial_Center__r.ER_Type__c == 'Merchant' ? fcli.ER_Card_Operational_System_ID__c : null)
      );
      syncStateValues.put(
        'local_client_id',
        (fcli.ER_Financial_Center__r.ER_Type__c == 'Client' ? fcli.ER_Card_Operational_System_ID__c : null)
      );
      syncStateValues.put('scope', fcli.ER_Financial_Center__r.ER_Type__c.toLowerCase());
      syncStateValues.put(
        'status',
        (fcli.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(fcli.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', fcli.ER_WS_result_Text__c);
      syncStateValues.put('code', fcli.ER_Sync_Code__c);
      syncStateValues.put('event_date', fcli.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', fcli.LastModifiedDate);
      syncState.add(syncStateValues);
      financialCenterLineItemAttributes.put('synchronization_states', syncState);
      listFinancialCenterLineItemAttributes.add(financialCenterLineItemAttributes);
    }
    return listFinancialCenterLineItemAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Store Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildStores(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listStoressAttributes = new List<Map<String, Object>>();
    for (ER_Store__c str : [
      SELECT
        Id,
        Name,
        ER_Financial_Center__c,
        ER_Status__c,
        ER_Franchise_type__c,
        ER_Brand__c,
        ER_Association_member__c,
        LastModifiedDate,
        ER_Association_name__c,
        ER_Meal_delivery_platform_affiliate__c,
        ER_Store_opening_date__c,
        ERBE_Segment__c,
        ER_Country_Code__c,
        Owner.Email,
        ERBE_Sub_Segment__c,
        ER_Start_date__c,
        ER_Closure_Date__c,
        ER_Closure_Reason__c,
        ER_E_Shop__c,
        ER_Contact__c,
        ER_VAT_Number__c,
        ER_Website_URL__c,
        ER_Do_not_publish__c,
        ER_Financial_Center__r.ER_Account_Name__r.ER_BUPicklist__c,
        CreatedBy.Email,
        ER_Email__c,
        ER_Shopping_center__c,
        CZ_Verified_Address__c,
        ER_Country__c,
        ER_Zip_Code__c,
        ER_State_Province__c,
        ER_Store_Phone_Number__c,
        ER_City__c,
        ER_Street__c,
        ER_Latitude_Longitude__Latitude__s,
        ER_Latitude_Longitude__Longitude__s,
        ER_Digital_Store_Status__c,
        ER_Last_Date_Of_Sync__c,
        ER_Sync_result__c,
        ER_WS_result_Text__c,
        CZ_Store_reference__c,
        ER_Financial_Center__r.ER_Type__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_Date_In_OS__c,
        ER_Sync_Code__c
      FROM ER_Store__c
      WHERE ER_Financial_Center__r.ER_Account_Name__c IN :accounts
    ]) {
      Map<String, Object> storesAttributes = new Map<String, Object>();
      Map<String, Object> storesAttributesValues = new Map<String, Object>();
      storesAttributesValues.put('name', str.Name);
      storesAttributesValues.put('status', str.ER_Status__c);
      storesAttributesValues.put('vat_number', null);
      storesAttributesValues.put('store_type', str.ER_VAT_Number__c);
      storesAttributesValues.put('franchise_type', str.ER_Franchise_type__c);
      storesAttributesValues.put('brand', str.ER_Brand__c);
      storesAttributesValues.put('association_member', str.ER_Association_member__c);
      storesAttributesValues.put('association_name', str.ER_Association_name__c);
      storesAttributesValues.put('meal_delivery_platform_affiliate', str.ER_Meal_delivery_platform_affiliate__c);
      storesAttributesValues.put('opening_date', str.ER_Store_opening_date__c);
      storesAttributesValues.put('myorder_store', null);
      storesAttributesValues.put('segment', str.ERBE_Segment__c);
      storesAttributesValues.put('sub_segment', str.ERBE_Sub_Segment__c);
      storesAttributesValues.put('start_date', str.ER_Start_date__c);
      storesAttributesValues.put('closure_date', str.ER_Closure_Date__c);
      storesAttributesValues.put('closure_reason', str.ER_Closure_Reason__c);
      storesAttributesValues.put('e_shop', str.ER_E_Shop__c);
      storesAttributesValues.put('website_url', str.ER_Website_URL__c);
      storesAttributesValues.put('do_not_publish', str.ER_Do_not_publish__c);
      storesAttributesValues.put('business_unit', str.ER_Financial_Center__r.ER_Account_Name__r.ER_BUPicklist__c);
      storesAttributesValues.put('bu_picklist', str.ER_Financial_Center__r.ER_Account_Name__r.ER_BUPicklist__c);
      storesAttributesValues.put('shopping_center', str.ER_Shopping_center__c);
      storesAttributesValues.put('verified_address', str.CZ_Verified_Address__c);
      storesAttributesValues.put('digital_store_status', str.ER_Digital_Store_Status__c);
      storesAttributesValues.put('phone_number', str.ER_Store_Phone_Number__c);
      storesAttributesValues.put('owner', str.Owner.Email);
      storesAttributesValues.put('created_by', str.CreatedBy.Email);
      storesAttributesValues.put('email', str.ER_Email__c);
      //Store Address
      Map<String, Object> storeAddressValues = new Map<String, Object>();
      storeAddressValues.put('country', str.ER_Country__c);
      storeAddressValues.put('country_code', (str.ER_Street__c != null ? str.ER_Country_Code__c : null));
      storeAddressValues.put('zip_code', str.ER_Zip_Code__c);
      storeAddressValues.put('state', str.ER_State_Province__c);
      storeAddressValues.put('city', str.ER_City__c);
      storeAddressValues.put('street', str.ER_Street__c);
      storeAddressValues.put('street_additional', null);
      storeAddressValues.put('address_complement', null);
      storeAddressValues.put('latitude', str.ER_Latitude_Longitude__Latitude__s);
      storeAddressValues.put('longitude', str.ER_Latitude_Longitude__Longitude__s);
      storeAddressValues.put('address_type', null);
      storesAttributesValues.put('address', storeAddressValues);
      storesAttributes.put('attributes', storesAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'ref_contact');
      authoritiesMap.put('legacy_reference', str.ER_Contact__c);
      authorities.add(authoritiesMap);
      Map<String, Object> storeAuthoritiesMap = new Map<String, Object>();
      storeAuthoritiesMap.put('legacy_name', 'record_id');
      storeAuthoritiesMap.put('legacy_reference', str.Id);
      authorities.add(storeAuthoritiesMap);
      Map<String, Object> fcAuthoritiesMap = new Map<String, Object>();
      fcAuthoritiesMap.put('legacy_name', 'ref_financial_center');
      fcAuthoritiesMap.put('legacy_reference', str.ER_Financial_Center__c);
      authorities.add(fcAuthoritiesMap);
      Map<String, Object> storeRefAuthoritiesMap = new Map<String, Object>();
      storeRefAuthoritiesMap.put('legacy_name', 'ref_Store_reference');
      storeRefAuthoritiesMap.put('legacy_reference', str.CZ_Store_reference__c);
      authorities.add(storeRefAuthoritiesMap);
      storesAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', str.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'merchant');
      syncStateValues.put(
        'status',
        (str.ER_Creation_Date_In_OS__c != null
          ? (ModifiedElements.contains(str.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', str.ER_WS_result_Text__c);
      syncStateValues.put('code', str.ER_Sync_Code__c);
      syncStateValues.put('event_date', str.ER_Last_Date_Of_Sync__c);
      syncStateValues.put('last_modification_date', str.LastModifiedDate);
      syncState.add(syncStateValues);
      storesAttributes.put('synchronization_states', syncState);
      listStoressAttributes.add(storesAttributes);
    }
    return listStoressAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Stores Line Item Structure
   * @param accounts
   * @param contracts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildStoresLineItem(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> ModifiedElements
  ) {
    List<Map<String, Object>> listStoreLineItemAttributes = new List<Map<String, Object>>();
    for (ER_Solution_Line_Item__c sli : [
      SELECT
        Id,
        ER_Store__c,
        ER_Parent_Line_Item__r.ER_Global_Status__c,
        ER_Global_Status__c,
        ER_Status__c,
        LastModifiedDate,
        LastModifiedBy.Email,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Solution__r.ProductCode,
        ER_Terms_Conditions__c,
        ER_Contract__r.Status,
        ER_Global_Status_Sync__c,
        ER_Parent_Line_Item__r.ER_Global_Status_Sync__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Store_Line_Item'
        AND ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c IN :accounts
        AND (ER_Contract__c IN :contracts
        OR ER_Contract__r.Status = 'Activated')
    ]) {
      Map<String, Object> storesLineItemAttributes = new Map<String, Object>();
      Map<String, Object> storessLineItemAttributesValues = new Map<String, Object>();
      storessLineItemAttributesValues.put(
        'parent_global_status',
        (sli.ER_Contract__r.Status == 'Draft'
          ? sli.ER_Parent_Line_Item__r.ER_Global_Status_Sync__c
          : sli.ER_Parent_Line_Item__r.ER_Global_Status__c)
      );
      storessLineItemAttributesValues.put(
        'global_status',
        (sli.ER_Contract__r.Status == 'Draft' ? sli.ER_Global_Status_Sync__c : sli.ER_Global_Status__c)
      );
      storessLineItemAttributesValues.put('status', sli.ER_Status__c);
      //storessLineItemAttributesValues.put('specificities', sli.ER_Terms_Conditions__c);
      storessLineItemAttributesValues.put('specificities', null);
      storessLineItemAttributesValues.put('last_modified_by', sli.LastModifiedBy.Email);
      storesLineItemAttributes.put('attributes', storessLineItemAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> storeAuthoritiesMap = new Map<String, Object>();
      storeAuthoritiesMap.put('legacy_name', 'ref_store');
      storeAuthoritiesMap.put('legacy_reference', sli.ER_Store__c);
      authorities.add(storeAuthoritiesMap);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', sli.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> productAuthoritiesMap = new Map<String, Object>();
      productAuthoritiesMap.put('legacy_name', 'ref_product');
      productAuthoritiesMap.put('legacy_reference', sli.ER_Solution__r.ProductCode);
      authorities.add(productAuthoritiesMap);
      storesLineItemAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', sli.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'merchant');
      syncStateValues.put(
        'status',
        (sli.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(sli.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', sli.ER_WS_result_Text__c);
      syncStateValues.put('code', sli.ER_Sync_Code__c);
      syncStateValues.put('event_date', sli.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', sli.LastModifiedDate);
      syncState.add(syncStateValues);
      storesLineItemAttributes.put('synchronization_states', syncState);
      listStoreLineItemAttributes.add(storesLineItemAttributes);
    }
    return listStoreLineItemAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Stores Line Item Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildStoresCategories(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listStoreCategoriesAttributes = new List<Map<String, Object>>();
    for (ER_StoreCategory__c strcat : [
      SELECT
        Id,
        Store__c,
        Category__r.ER_Category_Code__c,
        Category__r.Name,
        Business_Unit__c,
        Main_Category__c,
        LastModifiedDate,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM ER_StoreCategory__c
      WHERE Store__r.ER_Financial_Center__r.ER_Account_Name__c IN :accounts
    ]) {
      Map<String, Object> storesCategoriesAttributes = new Map<String, Object>();
      Map<String, Object> storessCategoriesAttributesValues = new Map<String, Object>();
      storessCategoriesAttributesValues.put('name', strcat.Category__r.Name);
      storessCategoriesAttributesValues.put('business_unit', strcat.Business_Unit__c);
      storessCategoriesAttributesValues.put('main_category', strcat.Main_Category__c);
      storesCategoriesAttributes.put('attributes', storessCategoriesAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> storeCategoryAuthoritiesMap = new Map<String, Object>();
      storeCategoryAuthoritiesMap.put('legacy_name', 'record_id');
      storeCategoryAuthoritiesMap.put('legacy_reference', strcat.Id);
      authorities.add(storeCategoryAuthoritiesMap);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'ref_store');
      authoritiesMap.put('legacy_reference', strcat.Store__c);
      authorities.add(authoritiesMap);
      Map<String, Object> categoryAuthoritiesMap = new Map<String, Object>();
      categoryAuthoritiesMap.put('legacy_name', 'ref_category');
      categoryAuthoritiesMap.put('legacy_reference', strcat.Category__r.ER_Category_Code__c);
      authorities.add(categoryAuthoritiesMap);
      storesCategoriesAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', strcat.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'merchant');
      syncStateValues.put(
        'status',
        (strcat.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(strcat.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', strcat.ER_WS_result_Text__c);
      syncStateValues.put('code', strcat.ER_Sync_Code__c);
      syncStateValues.put('event_date', strcat.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', strcat.LastModifiedDate);
      syncState.add(syncStateValues);
      storesCategoriesAttributes.put('synchronization_states', syncState);
      listStoreCategoriesAttributes.add(storesCategoriesAttributes);
    }
    return listStoreCategoriesAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Acceptor Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildAcceptors(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listAcceptorsAttributes = new List<Map<String, Object>>();
    for (ER_Acceptor__c acc : [
      SELECT
        Id,
        Name,
        ER_Store__c,
        ER_Acceptor_Type__c,
        ER_Acceptor_Provider__c,
        ER_Acceptor_Model__c,
        LastModifiedDate,
        ER_IS_Acceptor_Linked_To_Cash_Register__c,
        ER_Cash_Register_Provider__c,
        ER_Status__c,
        ER_Start_Date__c,
        ER_End_Date__c,
        ER_MID_Authorization__c,
        ER_MID_Clearing__c,
        ER_AID_Authorization__c,
        Owner.Email,
        ER_MCC_Authorization__c,
        ER_TID_Authorization__c,
        ER_AID_Clearing__c,
        ER_MCC_Clearing__c,
        ER_TID_Clearing__c,
        ER_Last_date_of_Sync__c,
        ER_Sync_result__c,
        ER_WS_result_Text__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c,
        ER_Aggregator__c,
        RecordType.Name,
        ER_MDMId__c,
        ER_Terminal_ID_Certificate__c,
        ER_Acceptor_Scheme__c,
        ER_SubMID_Authorization__c, 
        ER_Sub_MID_Clearing__c
      FROM ER_Acceptor__c
      WHERE ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c IN :accounts
    ]) {
      Map<String, Object> acceptorsAttributes = new Map<String, Object>();
      Map<String, Object> acceptorsAttributesValues = new Map<String, Object>();
      acceptorsAttributesValues.put('name', acc.Name);
      acceptorsAttributesValues.put('scope', 'merchant');
      acceptorsAttributesValues.put('acc_type', acc.ER_Acceptor_Type__c);
      acceptorsAttributesValues.put('provider', acc.ER_Acceptor_Provider__c);
      acceptorsAttributesValues.put('model', acc.ER_Acceptor_Model__c);
      acceptorsAttributesValues.put('is_linked_to_cash_register', acc.ER_IS_Acceptor_Linked_To_Cash_Register__c);
      acceptorsAttributesValues.put('cash_register_provider', acc.ER_Cash_Register_Provider__c);
      acceptorsAttributesValues.put('status', acc.ER_Status__c);
      acceptorsAttributesValues.put('start_date', acc.ER_Start_Date__c);
      acceptorsAttributesValues.put('end_date', acc.ER_End_Date__c);
      acceptorsAttributesValues.put('authorization_mid', acc.ER_MID_Authorization__c);
      acceptorsAttributesValues.put('clearing_mid', acc.ER_MID_Clearing__c);
      acceptorsAttributesValues.put('authorization_aid', acc.ER_AID_Authorization__c);
      acceptorsAttributesValues.put('authorization_mcc', acc.ER_MCC_Authorization__c);
      acceptorsAttributesValues.put('authorization_tid', acc.ER_TID_Authorization__c);
      acceptorsAttributesValues.put('clearing_aid', acc.ER_AID_Clearing__c);
      acceptorsAttributesValues.put('clearing_mcc', acc.ER_MCC_Clearing__c);
      acceptorsAttributesValues.put('clearing_tid', acc.ER_TID_Clearing__c);
      acceptorsAttributesValues.put('record_type', acc.RecordType.Name);
      acceptorsAttributesValues.put('card_id', acc.ER_Card_Operational_System_ID__c);
      acceptorsAttributesValues.put('mdm_id', acc.ER_MDMId__c);
      acceptorsAttributesValues.put('terminal_certificate', acc.ER_Terminal_ID_Certificate__c);
      acceptorsAttributesValues.put('acceptor_scheme', acc.ER_Acceptor_Scheme__c);
      acceptorsAttributesValues.put('authorization_sub_mid', acc.ER_SubMID_Authorization__c);
      acceptorsAttributesValues.put('activated_by', acc.Owner.Email);
      acceptorsAttributesValues.put('clearing_sub_mid', acc.ER_Sub_MID_Clearing__c);
      acceptorsAttributes.put('attributes', acceptorsAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', acc.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> storeAuthoritiesMap = new Map<String, Object>();
      storeAuthoritiesMap.put('legacy_name', 'ref_store');
      storeAuthoritiesMap.put('legacy_reference', acc.ER_Store__c);
      authorities.add(storeAuthoritiesMap);
      Map<String, Object> storeAggregatorAuthoritiesMap = new Map<String, Object>();
      storeAggregatorAuthoritiesMap.put('legacy_name', 'ref_account_aggregator');
      storeAggregatorAuthoritiesMap.put('legacy_reference', acc.ER_Aggregator__c);
      authorities.add(storeAggregatorAuthoritiesMap);
      acceptorsAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', acc.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'merchant');
      syncStateValues.put(
        'status',
        (acc.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(acc.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', acc.ER_WS_result_Text__c);
      syncStateValues.put('code', acc.ER_Sync_Code__c);
      syncStateValues.put('event_date', acc.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', acc.LastModifiedDate);
      syncState.add(syncStateValues);
      acceptorsAttributes.put('synchronization_states', syncState);
      listAcceptorsAttributes.add(acceptorsAttributes);
    }
    return listAcceptorsAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Acceptor Line Item Structure
   * @param accounts
   * @param contracts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildAcceptorsLineItem(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> ModifiedElements
  ) {
    List<Map<String, Object>> listAcceptorLineItemAttributes = new List<Map<String, Object>>();
    for (ER_Solution_Line_Item__c accli : [
      SELECT
        Id,
        ER_Acceptor__c,
        ER_Parent_Line_Item__r.ER_Global_Status__c,
        ER_Global_Status__c,
        ER_Status__c,
        LastModifiedDate,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Solution__r.ProductCode,
        ER_Terms_Conditions__c,
        ER_Contract__r.Status,
        ER_Global_Status_Sync__c,
        ER_Parent_Line_Item__r.ER_Global_Status_Sync__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Acceptor_Line_Item'
        AND ER_Acceptor__r.ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c IN :accounts
        AND (ER_Contract__c IN :contracts
        OR ER_Contract__r.Status = 'Activated')
    ]) {
      Map<String, Object> acceptorsLineItemAttributes = new Map<String, Object>();
      Map<String, Object> acceptorsLineItemAttributesValues = new Map<String, Object>();
      acceptorsLineItemAttributesValues.put(
        'parent_global_status',
        (accli.ER_Contract__r.Status == 'Draft'
          ? accli.ER_Parent_Line_Item__r.ER_Global_Status_Sync__c
          : accli.ER_Parent_Line_Item__r.ER_Global_Status__c)
      );
      acceptorsLineItemAttributesValues.put(
        'global_status',
        (accli.ER_Contract__r.Status == 'Draft' ? accli.ER_Global_Status_Sync__c : accli.ER_Global_Status__c)
      );
      acceptorsLineItemAttributesValues.put('status', accli.ER_Status__c);
      acceptorsLineItemAttributesValues.put('specificities', accli.ER_Terms_Conditions__c);
      //acceptorsLineItemAttributesValues.put('specificities', null);
      acceptorsLineItemAttributes.put('attributes', acceptorsLineItemAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> acceptorAuthoritiesMap = new Map<String, Object>();
      acceptorAuthoritiesMap.put('legacy_name', 'record_id');
      acceptorAuthoritiesMap.put('legacy_reference', accli.Id);
      authorities.add(acceptorAuthoritiesMap);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'ref_acceptor');
      authoritiesMap.put('legacy_reference', accli.ER_Acceptor__c);
      authorities.add(authoritiesMap);
      Map<String, Object> productAuthoritiesMap = new Map<String, Object>();
      productAuthoritiesMap.put('legacy_name', 'ref_product');
      productAuthoritiesMap.put('legacy_reference', accli.ER_Solution__r.ProductCode);
      authorities.add(productAuthoritiesMap);
      acceptorsLineItemAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', accli.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'merchant');
      syncStateValues.put(
        'status',
        (accli.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(accli.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', accli.ER_WS_result_Text__c);
      syncStateValues.put('code', accli.ER_Sync_Code__c);
      syncStateValues.put('event_date', accli.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', accli.LastModifiedDate);
      //syncStateValues.put('last_modification_date', null);
      syncState.add(syncStateValues);
      acceptorsLineItemAttributes.put('synchronization_states', syncState);
      listAcceptorLineItemAttributes.add(acceptorsLineItemAttributes);
    }
    return listAcceptorLineItemAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Contacts Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildContacts(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listContactsAttributes = new List<Map<String, Object>>();
    for (Contact c : [
      SELECT
        Id,
        AccountId,
        ER_Status__c,
        Account.ER_BUPicklist__c,
        Salutation,
        CZ_AcademicTitle__c,
        FirstName,
        LastModifiedDate,
        MiddleName,
        LastName,
        Suffix,
        Name,
        ER_Role__c,
        Birthdate,
        ER_Language__c,
        Email,
        Phone,
        MobilePhone,
        ER_Country_Code__c,
        Fax,
        DoNotCall,
        HasOptedOutOfEmail,
        ER_Do_Not_Mail__c,
        ER_Edenred_Newsletter__c,
        ER_Do_not_contact__c,
        ER_Client_Card_Operational_System_ID__c,
        MailingCountry,
        MailingPostalCode,
        MailingState,
        MailingCity,
        MailingStreet,
        MailingLatitude,
        MailingLongitude,
        ER_Last_date_of_Sync__c,
        ER_Sync_result__c,
        ER_WS_result_Text__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM Contact
      WHERE AccountId IN :accounts
    ]) {
      Map<String, Object> contactsAttributes = new Map<String, Object>();
      Map<String, Object> contactsAttributesValues = new Map<String, Object>();
      contactsAttributesValues.put('status', c.ER_Status__c);
      contactsAttributesValues.put('business_unit', c.Account.ER_BUPicklist__c);
      contactsAttributesValues.put('salutations', c.Salutation);
      contactsAttributesValues.put('academic_title', c.CZ_AcademicTitle__c);
      contactsAttributesValues.put('first_name', c.FirstName);
      contactsAttributesValues.put('middle_name', c.MiddleName);
      contactsAttributesValues.put('last_name', c.LastName);
      contactsAttributesValues.put('suffix', c.Suffix);
      contactsAttributesValues.put('name', c.Name);
      contactsAttributesValues.put('role', c.ER_Role__c);
      contactsAttributesValues.put('birthdate', c.Birthdate);
      contactsAttributesValues.put('preferred_language', c.ER_Language__c);
      contactsAttributesValues.put('email', c.Email);
      contactsAttributesValues.put('phone', c.Phone);
      contactsAttributesValues.put('mobile_number', c.MobilePhone);
      contactsAttributesValues.put('fax', c.Fax);
      contactsAttributesValues.put('donotcall', c.DoNotCall);
      contactsAttributesValues.put('opted_outof_email', c.HasOptedOutOfEmail);
      contactsAttributesValues.put('opted_outin_email', null);
      contactsAttributesValues.put('do_not_email', c.ER_Do_Not_Mail__c);
      contactsAttributesValues.put('edenred_newsletter', c.ER_Edenred_Newsletter__c);
      contactsAttributesValues.put('do_not_contact', c.ER_Do_not_contact__c);
      //Store Address
      Map<String, Object> contactsAddressValues = new Map<String, Object>();
      contactsAddressValues.put('country', c.MailingCountry);
      contactsAddressValues.put('country_code', (c.MailingStreet != null ? c.ER_Country_Code__c : null));
      contactsAddressValues.put('zip_code', c.MailingPostalCode);
      contactsAddressValues.put('state', c.MailingState);
      contactsAddressValues.put('city', c.MailingCity);
      contactsAddressValues.put('street', c.MailingStreet);
      contactsAddressValues.put('street_additional', null);
      contactsAddressValues.put('address_complement', null);
      contactsAddressValues.put('latitude', c.MailingLatitude);
      contactsAddressValues.put('longitude', c.MailingLongitude);
      contactsAddressValues.put('address_type', null);
      contactsAttributesValues.put('mailing_address', contactsAddressValues);
      contactsAttributes.put('attributes', contactsAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> contactAuthoritiesMap = new Map<String, Object>();
      contactAuthoritiesMap.put('legacy_name', 'record_id');
      contactAuthoritiesMap.put('legacy_reference', c.Id);
      authorities.add(contactAuthoritiesMap);
      Map<String, Object> accountAuthoritiesMap = new Map<String, Object>();
      accountAuthoritiesMap.put('legacy_name', 'ref_account');
      accountAuthoritiesMap.put('legacy_reference', c.AccountId);
      authorities.add(accountAuthoritiesMap);
      contactsAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', c.ER_Card_Operational_System_ID__c);
      syncStateValues.put('local_client_id', c.ER_Client_Card_Operational_System_ID__c);
      syncStateValues.put('scope', scope);
      syncStateValues.put(
        'status',
        (c.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(c.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', c.ER_WS_result_Text__c);
      syncStateValues.put('code', c.ER_Sync_Code__c);
      syncStateValues.put('event_date', c.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', c.LastModifiedDate);
      syncState.add(syncStateValues);
      contactsAttributes.put('synchronization_states', syncState);
      listContactsAttributes.add(contactsAttributes);
    }
    return listContactsAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Contact Role Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildContactsRole(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listContactsRoleAttributes = new List<Map<String, Object>>();
    String soql = 'SELECT Id, ER_Role__c, ER_Primary__c, ER_Email__c, ER_Billing_Account__c, ER_Financial_Center__c, ER_Financial_Center__r.ER_Type__c, ER_External_Id__c, ER_Store__c, ER_Sync_result__c, ER_Last_date_of_Sync__c, ER_WS_result_Text__c, ER_Contact__c, LastModifiedDate, ER_Card_Operational_System_ID__c, ER_Creation_date_in_OS__c, ER_Sync_Code__c, ER_Status__c, ER_Global_Status__c,ER_Delivery_Site__c, ER_Distribution_Point__c FROM ER_Contact_Role__c WHERE ER_Contact__r.AccountId IN :accounts';
    if (scope == 'merchant')
      soql = soql + ' AND RecordType.DeveloperName in ( \'ER_CR_Store\' , \'ER_CR_Financial_Center_Merchant\' )';
    if (scope == 'client')
      soql =
        soql +
        ' AND RecordType.DeveloperName in ( \'ER_CR_Delivery_Site\' ,  \'ER_CR_Distribution_Point\' , \'ER_CR_Financial_Center_Client\'  )';
    for (ER_Contact_Role__c cr : Database.query(soql)) {
      /*
        for(ER_Contact_Role__c cr : [
                SELECT Id, ER_Role__c, ER_Primary__c, ER_Email__c, ER_Billing_Account__c, ER_Financial_Center__c, ER_External_Id__c,
                        ER_Store__c, ER_Sync_result__c, ER_Last_date_of_Sync__c, ER_WS_result_Text__c, ER_Contact__c, LastModifiedDate,
                        ER_Card_Operational_System_ID__c, ER_Creation_date_in_OS__c, ER_Sync_Code__c, ER_Status__c, ER_Global_Status__c,
                        ER_Delivery_Site__c, ER_Distribution_Point__c
                FROM ER_Contact_Role__c
                WHERE ER_Contact__r.AccountId IN :accounts
        ]) { */
      /*String crScope = 'client';
      if (
        (cr.ER_Financial_Center__c != null && cr.ER_Financial_Center__r.ER_Type__c == 'Merchant') ||
        cr.ER_Store__c != null
      )
        crScope = 'merchant';
      Map<String, Object> contactsRoleAttributes = new Map<String, Object>();
      Map<String, Object> contactsRolesAttributesValues = new Map<String, Object>();
      contactsRolesAttributesValues.put('role', cr.ER_Role__c);
      contactsRolesAttributesValues.put('is_primary', cr.ER_Primary__c);
      contactsRolesAttributesValues.put('secondary_email', cr.ER_Email__c);
      contactsRolesAttributesValues.put('status', cr.ER_Status__c);
      contactsRolesAttributesValues.put('global_status', cr.ER_Global_Status__c);
      contactsRoleAttributes.put('attributes', contactsRolesAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', cr.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> accountAuthoritiesMap = new Map<String, Object>();
      accountAuthoritiesMap.put('legacy_name', 'ref_account');
      accountAuthoritiesMap.put('legacy_reference', cr.ER_Billing_Account__c);
      authorities.add(accountAuthoritiesMap);
      Map<String, Object> fcAuthoritiesMap = new Map<String, Object>();
      fcAuthoritiesMap.put('legacy_name', 'ref_financial_center');
      fcAuthoritiesMap.put('legacy_reference', cr.ER_Financial_Center__c);
      authorities.add(fcAuthoritiesMap);
      Map<String, Object> storeAuthoritiesMap = new Map<String, Object>();
      storeAuthoritiesMap.put('legacy_name', 'ref_store');
      storeAuthoritiesMap.put('legacy_reference', cr.ER_Store__c);
      authorities.add(storeAuthoritiesMap);
      Map<String, Object> deliverySiteAuthoritiesMap = new Map<String, Object>();
      deliverySiteAuthoritiesMap.put('legacy_name', 'ref_delivery_site');
      deliverySiteAuthoritiesMap.put('legacy_reference', cr.ER_Delivery_Site__c);
      authorities.add(deliverySiteAuthoritiesMap);
      Map<String, Object> distributionPointAuthoritiesMap = new Map<String, Object>();
      distributionPointAuthoritiesMap.put('legacy_name', 'ref_distribution_point');
      distributionPointAuthoritiesMap.put('legacy_reference', cr.ER_Distribution_Point__c);
      authorities.add(distributionPointAuthoritiesMap);
      Map<String, Object> contactAuthoritiesMap = new Map<String, Object>();
      contactAuthoritiesMap.put('legacy_name', 'ref_contact');
      contactAuthoritiesMap.put('legacy_reference', cr.ER_Contact__c);
      authorities.add(contactAuthoritiesMap);
      contactsRoleAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', (crScope == 'merchant' ? cr.ER_External_Id__c : null));
      syncStateValues.put('local_client_id', (crScope == 'client' ? cr.ER_External_Id__c : null));
      syncStateValues.put('scope', crScope);
      syncStateValues.put(
        'status',
        (cr.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(cr.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', cr.ER_WS_result_Text__c);
      syncStateValues.put('code', cr.ER_Sync_Code__c);
      syncStateValues.put('event_date', cr.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', cr.LastModifiedDate);
      syncState.add(syncStateValues);
      contactsRoleAttributes.put('synchronization_states', syncState);
      listContactsRoleAttributes.add(contactsRoleAttributes);*/
    }
    return listContactsRoleAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Contract Structure
   * @param accounts
   * @param contracts
   * @param amendedContract
   * @param action
   *
   * @return
   */
  public static List<Map<String, Object>> buildContracts(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> amendedContract,
    String action
  ) {
    //send the contract only if we have a post account, post contract, put contract or post close contract ?
    List<Map<String, Object>> listContractsAttributes = new List<Map<String, Object>>();
    for (Contract ctr : [
      SELECT
        Id,
        AccountId,
        ContractNumber,
        Status,
        ER_Last_date_of_Sync__c,
        StartDate,
        EndDate,
        LastModifiedDate,
        Owner.FirstName,
        Owner.LastName,
        Owner.Email,
        OwnerId,
        Owner.ER_External_Id__c,
        CompanySigned.FirstName,
        CompanySigned.LastName,
        CompanySigned.Email,
        CompanySignedId,
        CompanySigned.ER_External_Id__c,
        ER_OpportunityId__r.ER_IsAmended__c,
        ER_OpportunityId__r.ER_AmendedFromContract__c,
        ER_OpportunityId__r.ER_AmendedFromOpportunity__r.ContractId,
        ER_Original_Agreement__c,
        CustomerSignedDate,
        ActivatedDate,
        ER_TerminationReason__c,
        ER_Type__c,
        RecordType.DeveloperName,
        ERBE_Invoicing_Support__c,
        ER_Indexation__c,
        CustomerSignedId,
        CustomerSigned.Email,
        ER_Indexation_Index2__c,
        ER_Credit_Limit2__c,
        CurrencyIsoCode,
        ActivatedBy.Email,
        ERBE_Reimbursement_Statement_Frequency__c,
        ER_InvoicingFrequency2__c,
        ER_PaymentMethod2__c,
        ER_PaymentTerms2__c,
        SK_Payment_Terms_Voucher2__c,
        Pricebook2.ER_MDMId__c,
        ERBE_Reimbursement_statement_Support__c,
        ER_ReimbursementTerm2__c,
        Account.ER_BUPicklist__c,
        ER_Card_Operational_System_ID__c,
        ER_WS_Message_Long__c,
        ER_WS_StatusCode__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c,
        ERBE_Weekly_Frequence__c,
        ERBE_Invoicing_day_of_week__c
      FROM Contract
      WHERE Id IN :contracts OR (AccountId IN :accounts AND Status = 'Activated')
    ]) {
      Map<String, Object> contractsAttributes = new Map<String, Object>();
      Map<String, Object> contractsAttributesValues = new Map<String, Object>();
      contractsAttributesValues.put('contract_number', ctr.ContractNumber);
      if (
        (amendedContract != null && !amendedContract.isEmpty() && amendedContract.contains(ctr.Id)) ||
        (contracts != null &&
        !contracts.isEmpty() &&
        contracts.contains(ctr.Id) &&
        action == 'Termination')
      )
        contractsAttributesValues.put('status', Label.LABS_SF_Contract_Status_Terminated);
      else if (action == 'Activation')
        contractsAttributesValues.put('status', Label.LABS_SF_Contract_Status_Activated); // commented for ERES client purpose
      else
        //else if(action == 'Activation') contractsAttributesValues.put('status','Active');
        contractsAttributesValues.put('status', ctr.Status);
      //contractsAttributesValues.put('status', ((contracts != null && !contracts.isEmpty()) ? 'Activated' : ctr.Status));
      contractsAttributesValues.put('last_sync_date', ctr.ER_Last_date_of_Sync__c);
      contractsAttributesValues.put('sync_status_code', null);
      contractsAttributesValues.put('sync_status', null);
      contractsAttributesValues.put('sync_message', null);
      contractsAttributesValues.put('start_date', ctr.StartDate);
      contractsAttributesValues.put('end_date', (amendedContract.contains(ctr.Id) ? Date.today() : ctr.EndDate));
      contractsAttributesValues.put('cancelation_date', null);
      contractsAttributesValues.put('customer_signed_date', ctr.CustomerSignedDate);
      contractsAttributesValues.put('activated_date', ctr.ActivatedDate);
      contractsAttributesValues.put(
        'termination_reason',
        (amendedContract.contains(ctr.Id) ? Label.LAB_SF_Contract_Amendment : ctr.ER_TerminationReason__c)
      );
      contractsAttributesValues.put('contract_type', ctr.ER_Type__c);
      contractsAttributesValues.put('indexation', ctr.ER_Indexation__c);
      contractsAttributesValues.put('indexation_index', ctr.ER_Indexation_Index2__c);
      contractsAttributesValues.put('credit_limit', ctr.ER_Credit_Limit2__c);
      contractsAttributesValues.put('currency', ctr.CurrencyIsoCode);
      contractsAttributesValues.put('invoicing_frequency', ctr.ER_InvoicingFrequency2__c);
      contractsAttributesValues.put('payment_method', ctr.ER_PaymentMethod2__c);
      contractsAttributesValues.put('payment_terms', ctr.ER_PaymentTerms2__c);
      contractsAttributesValues.put('payment_terms_voucher', ctr.SK_Payment_Terms_Voucher2__c);
      contractsAttributesValues.put('reimbursement_term', ctr.ER_ReimbursementTerm2__c);
      contractsAttributesValues.put('business_unit', ctr.Account.ER_BUPicklist__c);
      contractsAttributesValues.put('invoicing_support', ctr.ERBE_Invoicing_Support__c);
      contractsAttributesValues.put('reimbursement_statement_support', ctr.ERBE_Reimbursement_statement_Support__c);
      contractsAttributesValues.put('reimbursement_statement_frequency', ctr.ERBE_Reimbursement_Statement_Frequency__c);
      if (action == 'Activation')
        contractsAttributesValues.put('activated_by', UserInfo.getUserEmail());
      else
        contractsAttributesValues.put('activated_by', ctr.ActivatedBy.Email);
      contractsAttributesValues.put('parent_external_reference', ctr.ER_OpportunityId__r.ER_AmendedFromContract__c);
      contractsAttributesValues.put('weekly_frequence', ctr.ERBE_Weekly_Frequence__c);
      contractsAttributesValues.put('invoicing_day_of_week', ctr.ERBE_Invoicing_day_of_week__c);
      Map<String, Object> contractOwner = new Map<String, Object>();
      contractOwner.put('first_name', ctr.Owner.FirstName);
      contractOwner.put('last_name', ctr.Owner.LastName);
      contractOwner.put('email', ctr.Owner.Email);
      contractOwner.put('id', ctr.OwnerId);
      contractOwner.put('external_ref', ctr.Owner.ER_External_Id__c);
      contractsAttributesValues.put('owner', contractOwner);
      Map<String, Object> contractSignatory = new Map<String, Object>();
      contractSignatory.put('first_name', ctr.CompanySigned.FirstName);
      contractSignatory.put('last_name', ctr.CompanySigned.LastName);
      contractSignatory.put('email', ctr.CompanySigned.Email);
      contractSignatory.put('id', ctr.CompanySignedId);
      contractSignatory.put('external_ref', ctr.CompanySigned.ER_External_Id__c);
      contractsAttributesValues.put('signatory', contractSignatory);
      contractsAttributes.put('attributes', contractsAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', ctr.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> accountAuthoritiesMap = new Map<String, Object>();
      accountAuthoritiesMap.put('legacy_name', 'ref_account');
      accountAuthoritiesMap.put('legacy_reference', ctr.AccountId);
      authorities.add(accountAuthoritiesMap);
      Map<String, Object> originalContractAuthoritiesMap = new Map<String, Object>();
      originalContractAuthoritiesMap.put('legacy_name', 'ref_contract_original');
      originalContractAuthoritiesMap.put('legacy_reference', ctr.ER_Original_Agreement__c);
      authorities.add(originalContractAuthoritiesMap);
      Map<String, Object> signedByAuthoritiesMap = new Map<String, Object>();
      signedByAuthoritiesMap.put('legacy_name', 'ref_contact_signatory');
      signedByAuthoritiesMap.put('legacy_reference', ctr.CustomerSignedId);
      authorities.add(signedByAuthoritiesMap);
      Map<String, Object> pricebookAuthoritiesMap = new Map<String, Object>();
      pricebookAuthoritiesMap.put('legacy_name', 'ref_pricebook');
      pricebookAuthoritiesMap.put('legacy_reference', ctr.Pricebook2.ER_MDMId__c);
      authorities.add(pricebookAuthoritiesMap);
      contractsAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put(
        'local_id',
        (ctr.RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? ctr.ER_Card_Operational_System_ID__c : null)
      );
      syncStateValues.put(
        'local_client_id',
        (ctr.RecordType.DeveloperName == 'ER_Client_Contract_RT' ? ctr.ER_Card_Operational_System_ID__c : null)
      );
      syncStateValues.put('scope', (ctr.RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? 'merchant' : 'client'));
      syncStateValues.put('status', (ctr.ER_Creation_date_in_OS__c != null ? 'synchronized' : 'not_synchronized')); // ER_Sync_result__c
      syncStateValues.put('message', ctr.ER_WS_Message_Long__c); // New fields to be created
      syncStateValues.put('code', ctr.ER_Sync_Code__c);
      syncStateValues.put('event_date', ctr.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', ctr.LastModifiedDate);
      syncState.add(syncStateValues);
      contractsAttributes.put('synchronization_states', syncState);
      listContractsAttributes.add(contractsAttributes);
    }
    return listContractsAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Contract Line Item Structure
   * @param accounts
   * @param contracts
   * @param requestMethod
   *
   * @return
   */
  public static List<Map<String, Object>> buildContractsLineItem(Set<Id> accounts, Set<Id> contracts) {
    // Apply same filter as on the contract level ?
    List<Map<String, Object>> listContractsLineItemAttributes = new List<Map<String, Object>>();
    Map<Id, ER_ContractLineItem__c> mapParentServicePBE = new Map<Id, ER_ContractLineItem__c>();

    //ALK - F-12229 - ERES Temporary Discount EDG V3
    for (ER_ContractLineItem__c cli : [
      SELECT Id, ER_Product2__c, ER_Product2__r.ER_Solution__c
      FROM ER_ContractLineItem__c
      WHERE
        ER_Contract__r.AccountId IN :accounts
        AND ER_Line_Type__c = :Constants.DISCOUNT
        AND ER_Product2__r.ER_Solution__c != NULL
    ]) {
      mapParentServicePBE.put(cli.ER_Product2__r.ER_Solution__c, null);
    }

    for (ER_ContractLineItem__c cli : [
      SELECT Id, ER_Product2__c, ER_ListPrice__c, ER_UnitPrice__c, ER_Discount__c, ER_Percentage__c
      FROM ER_ContractLineItem__c
      WHERE ER_Contract__r.AccountId IN :accounts AND ER_Product2__c IN :mapParentServicePBE.keySet()
    ]) {
      mapParentServicePBE.put(cli.ER_Product2__c, cli);
    }

    for (ER_ContractLineItem__c cli : [
      SELECT
        Id,
        ER_Contract__c,
        ER_ProductCode__c,
        ER_Contract__r.Account.ER_BUPicklist__c,
        LastModifiedDate,
        CurrencyIsoCode,
        Name,
        ER_Description__c,
        ER_Line_Type__c,
        ER_What__c,
        ER_Max__c,
        ER_Min__c,
        ER_Contract__r.RecordType.DeveloperName,
        ER_ListPrice__c,
        ER_Discount__c,
        ER_Percentage__c,
        ER_UnitPrice__c,
        ER_Minimum_Fee__c,
        ER_Product2__r.ER_Solution__c,
        ER_Quantity_Unit_of_Measure__c,
        ER_Product2__r.ER_Service_Range_Type__c,
        ER_Price_End_Date__c,
        ER_Product2__r.ER_Solution__r.ER_Service_Range_Type__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Sync_result__c,
        ER_Product2__r.ER_Solution2__r.ProductCode,
        ER_Product2__r.ER_Type__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c,
        ER_IsActive__c,
        ER_Contract__r.ER_OppIndexation2__c
      FROM ER_ContractLineItem__c
      WHERE
        ER_Contract__r.AccountId IN :accounts
        AND (ER_Contract__c IN :contracts
        OR ER_Contract__r.Status = 'Activated')
        AND (ER_Price_End_Date__c >= TODAY
        OR ER_Price_Start_Date__c <= TODAY
        OR (ER_Price_End_Date__c = NULL
        AND ER_Price_Start_Date__c = NULL))
    ]) {
      Map<String, Object> contractsLineItemAttributes = new Map<String, Object>();
      Map<String, Object> contractsLineItemAttributesValues = new Map<String, Object>();
      contractsLineItemAttributesValues.put('name', cli.Name);
      contractsLineItemAttributesValues.put('product_code', cli.ER_Product2__r.ER_Solution2__r.ProductCode);
      contractsLineItemAttributesValues.put('business_unit', cli.ER_Contract__r.Account.ER_BUPicklist__c);
      contractsLineItemAttributesValues.put('currency', cli.CurrencyIsoCode);
      contractsLineItemAttributesValues.put('description', cli.ER_Description__c);
      contractsLineItemAttributesValues.put('line_type', cli.ER_Line_Type__c);
      contractsLineItemAttributesValues.put('what', cli.ER_What__c);
      contractsLineItemAttributesValues.put('range_minimum', cli.ER_Min__c);
      contractsLineItemAttributesValues.put('range_maximum', cli.ER_Max__c);
      contractsLineItemAttributesValues.put('standard_price', (cli.ER_ListPrice__c == 0 ? 0: cli.ER_ListPrice__c ));
      contractsLineItemAttributesValues.put('discount', cli.ER_Discount__c);
      contractsLineItemAttributesValues.put('percentage', (cli.ER_Percentage__c == 0 ? 0: cli.ER_Percentage__c ));
      contractsLineItemAttributesValues.put('sale_price', (cli.ER_UnitPrice__c == 0 ? 0: cli.ER_UnitPrice__c ));
      contractsLineItemAttributesValues.put('minimum_fee', cli.ER_Minimum_Fee__c);
      contractsLineItemAttributesValues.put('invoicing_unit', cli.ER_Quantity_Unit_of_Measure__c);
      //contractsLineItemAttributesValues.put('range_type', cli.ER_Product2__r.ER_Service_Range_Type__c);
      contractsLineItemAttributesValues.put(
        'range_type',
        (cli.ER_Product2__r.ER_Type__c == 'Range'
          ? cli.ER_Product2__r.ER_Solution__r.ER_Service_Range_Type__c
          : cli.ER_Product2__r.ER_Service_Range_Type__c)
      );
      contractsLineItemAttributesValues.put('discount_end_date', cli.ER_Price_End_Date__c);
      contractsLineItemAttributesValues.put('discount_duration', null);
      contractsLineItemAttributesValues.put('is_service_active', cli.ER_IsActive__c);
      contractsLineItemAttributesValues.put('is_fees_increased', cli.ER_Contract__r.ER_OppIndexation2__c);
      contractsLineItemAttributesValues.put('discount_default_value', (cli.ER_UnitPrice__c == 0 ? 0: cli.ER_UnitPrice__c ));
      contractsLineItemAttributesValues.put('discount_value', cli.ER_Discount__c);
      //ALK - F-12229 - Add info linked to parent service -F-12683
      contractsLineItemAttributesValues.put(
        'service_value_type',
        (cli.ER_Percentage__c != null && cli.ER_Percentage__c > 0 ? 'percentage' : 'currency')
      );
      contractsLineItemAttributesValues.put(
        'service_standard_value',
        (cli.ER_Line_Type__c == 'Discount' && mapParentServicePBE.containsKey(cli.ER_Product2__r.ER_Solution__c)
          ? (mapParentServicePBE.get(cli.ER_Product2__r.ER_Solution__c).ER_ListPrice__c == 0 ? 0 : mapParentServicePBE.get(cli.ER_Product2__r.ER_Solution__c).ER_ListPrice__c)
          : 0)
      );
      contractsLineItemAttributesValues.put(
        'service_sales_value',
        (cli.ER_Line_Type__c == 'Discount' && mapParentServicePBE.containsKey(cli.ER_Product2__r.ER_Solution__c)
          ? ((cli.ER_Percentage__c != null &&
              cli.ER_Percentage__c >= 0)
              ? (mapParentServicePBE.get(cli.ER_Product2__r.ER_Solution__c).ER_Percentage__c == 0 ? 0 : mapParentServicePBE.get(cli.ER_Product2__r.ER_Solution__c).ER_Percentage__c)
              : (mapParentServicePBE.get(cli.ER_Product2__r.ER_Solution__c).ER_UnitPrice__c == 0 ? 0 : mapParentServicePBE.get(cli.ER_Product2__r.ER_Solution__c).ER_UnitPrice__c))
          : 0)
      );
      contractsLineItemAttributesValues.put(
        'service_discount_value',
        (cli.ER_Line_Type__c == 'Discount' && mapParentServicePBE.containsKey(cli.ER_Product2__r.ER_Solution__c)
          ? mapParentServicePBE.get(cli.ER_Product2__r.ER_Solution__c).ER_Discount__c
          : 0)
      );

      contractsLineItemAttributes.put('attributes', contractsLineItemAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', cli.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> contractAuthoritiesMap = new Map<String, Object>();
      contractAuthoritiesMap.put('legacy_name', 'ref_contract');
      contractAuthoritiesMap.put('legacy_reference', cli.ER_Contract__c);
      authorities.add(contractAuthoritiesMap);
      Map<String, Object> productAuthoritiesMap = new Map<String, Object>();
      productAuthoritiesMap.put('legacy_name', 'ref_product');
      productAuthoritiesMap.put('legacy_reference', cli.ER_ProductCode__c);
      authorities.add(productAuthoritiesMap);
      contractsLineItemAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put(
        'local_id',
        (cli.ER_Contract__r.RecordType.DeveloperName == 'ER_Merchant_Contract_RT'
          ? cli.ER_Card_Operational_System_ID__c
          : null)
      );
      syncStateValues.put(
        'local_client_id',
        (cli.ER_Contract__r.RecordType.DeveloperName == 'ER_Client_Contract_RT'
          ? cli.ER_Card_Operational_System_ID__c
          : null)
      );
      syncStateValues.put(
        'scope',
        (cli.ER_Contract__r.RecordType.DeveloperName == 'ER_Merchant_Contract_RT' ? 'merchant' : 'client')
      );
      syncStateValues.put('status', (cli.ER_Creation_date_in_OS__c != null ? 'synchronized' : 'not_synchronized')); // New fields to be created
      syncStateValues.put('message', cli.ER_WS_result_Text__c); // New fields to be created
      syncStateValues.put('code', cli.ER_Sync_Code__c);
      syncStateValues.put('event_date', cli.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', cli.LastModifiedDate);
      syncState.add(syncStateValues);
      contractsLineItemAttributes.put('synchronization_states', syncState);
      listContractsLineItemAttributes.add(contractsLineItemAttributes);
    }
    return listContractsLineItemAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Bank Account Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildBankAccount(Set<Id> accounts, Set<Id> ModifiedElements) {
    // Use same filter as on the financial center ?
    List<Map<String, Object>> listBankAccountAttributes = new List<Map<String, Object>>();
    Set<Id> bankAccountsIds = new Set<Id>();
    for (ER_Financial_Center__c fc : [
      SELECT Id, ER_Bank_Account__c
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c IN :accounts
    ]) {
      bankAccountsIds.add(fc.ER_Bank_Account__c);
    }

    for (ER_Solution_Line_Item__c fcli : [
      SELECT Id, ER_Bank_Account__c
      FROM ER_Solution_Line_Item__c
      WHERE ER_Bank_Account__c != NULL AND ER_Financial_Center__r.ER_Account_Name__c IN :accounts
    ]) {
      bankAccountsIds.add(fcli.ER_Bank_Account__c);
    }

    for (ER_Bank_Account__c ba : [
      SELECT
        Id,
        ER_Financial_Center__c,
        ER_IBAN__c,
        CZ_Variable_symbol__c,
        CZ_Specific_symbol__c,
        ER_BIC__c,
        Name,
        ER_Bank_Account_Status__c,
        CurrencyIsoCode,
        ER_Business_Unit__c,
        ER_Bank_Name__c,
        ER_SEPA_active__c,
        LastModifiedDate,
        ER_Client_Card_Operational_System_ID__c,
        ER_SEPA_start_date__c,
        ER_SEPA_end_date__c,
        ER_SEPA_reference__c,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c, 
        Owner.Email
      FROM ER_Bank_Account__c
      WHERE ER_Financial_Center__r.ER_Account_Name__c IN :accounts OR Id IN :bankAccountsIds
    ]) {
      Map<String, Object> bankAccountAttributes = new Map<String, Object>();
      Map<String, Object> bankAccountAttributesValues = new Map<String, Object>();
      bankAccountAttributesValues.put('name', ba.Name);
      bankAccountAttributesValues.put('iban', ba.ER_IBAN__c);
      bankAccountAttributesValues.put('variable_symbol', ba.CZ_Variable_symbol__c);
      bankAccountAttributesValues.put('specific_symbol', ba.CZ_Specific_symbol__c);
      bankAccountAttributesValues.put('bic', ba.ER_BIC__c);
      bankAccountAttributesValues.put('status', ba.ER_Bank_Account_Status__c);
      bankAccountAttributesValues.put('currency', ba.CurrencyIsoCode);
      bankAccountAttributesValues.put('business_unit', ba.ER_Business_Unit__c);
      bankAccountAttributesValues.put('bank_name', ba.ER_Bank_Name__c);
      bankAccountAttributesValues.put('bank_account_owner', ba.Owner.Email);
      //Sepa Infos
      Map<String, Object> sepaValues = new Map<String, Object>();
      sepaValues.put('active', ba.ER_SEPA_active__c);
      sepaValues.put('start_date', ba.ER_SEPA_start_date__c);
      sepaValues.put('end_date', ba.ER_SEPA_end_date__c);
      sepaValues.put('reference', ba.ER_SEPA_reference__c);
      bankAccountAttributesValues.put('SEPA', sepaValues);
      bankAccountAttributes.put('attributes', bankAccountAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', ba.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> fcAuthoritiesMap = new Map<String, Object>();
      fcAuthoritiesMap.put('legacy_name', 'ref_financial_center_preferred');
      fcAuthoritiesMap.put('legacy_reference', ba.ER_Financial_Center__c);
      authorities.add(fcAuthoritiesMap);
      bankAccountAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_id', ba.ER_Card_Operational_System_ID__c);
      syncStateValues.put('local_client_id', ba.ER_Client_Card_Operational_System_ID__c);
      syncStateValues.put('scope', scope);
      syncStateValues.put(
        'status',
        (ba.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(ba.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', ba.ER_WS_result_Text__c);
      syncStateValues.put('code', ba.ER_Sync_Code__c);
      syncStateValues.put('event_date', ba.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', ba.LastModifiedDate);
      syncState.add(syncStateValues);
      bankAccountAttributes.put('synchronization_states', syncState);
      listBankAccountAttributes.add(bankAccountAttributes);
    }
    return listBankAccountAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 17/02/2022
   * @description Build Delivery Site Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildDeliverySite(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listDeliverySitesAttributes = new List<Map<String, Object>>();
    /*for (ER_Delivery_Site__c ds : [
      SELECT
        Id,
        Name,
        ER_Account_Name__c,
        ER_Financial_Center__c,
        ER_Card_Operational_System_ID__c,
        LastModifiedDate,
        ER_Creation_date_in_OS__c,
        ER_WS_result_Text__c,
        ER_Sync_Code__c,
        ER_Last_date_of_Sync__c,
        ER_City__c,
        ER_Country__c,
        ER_Delivery_Contact__c,
        ER_Street__c,
        ER_Zip_Code__c,
        ER_Street_additionnal__c,
        ER_Country_Code__c
      FROM ER_Delivery_Site__c
      WHERE ER_Account_Name__c IN :accounts
    ]) {
      Map<String, Object> deliverySitesAttributes = new Map<String, Object>();
      Map<String, Object> deliverySitesAttributesValues = new Map<String, Object>();
      deliverySitesAttributesValues.put('name', ds.Name);
      //Address
      Map<String, Object> deliverySitesAddressValues = new Map<String, Object>();
      deliverySitesAddressValues.put('country', ds.ER_Country__c);
      deliverySitesAddressValues.put('country_code', (ds.ER_Street__c != null ? ds.ER_Country_Code__c : null));
      deliverySitesAddressValues.put('zip_code', ds.ER_Zip_Code__c);
      deliverySitesAddressValues.put('state', null);
      deliverySitesAddressValues.put('city', ds.ER_City__c);
      deliverySitesAddressValues.put('street', ds.ER_Street__c);
      deliverySitesAddressValues.put('street_additional', ds.ER_Street_additionnal__c);
      deliverySitesAddressValues.put('address_complement', null);
      deliverySitesAddressValues.put('latitude', null);
      deliverySitesAddressValues.put('longitude', null);
      deliverySitesAddressValues.put('address_type', null);
      deliverySitesAttributesValues.put('address', deliverySitesAddressValues);
      deliverySitesAttributes.put('attributes', deliverySitesAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> contactAuthoritiesMap = new Map<String, Object>();
      contactAuthoritiesMap.put('legacy_name', 'ref_contact');
      contactAuthoritiesMap.put('legacy_reference', ds.ER_Delivery_Contact__c);
      authorities.add(contactAuthoritiesMap);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', ds.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> fcAuthoritiesMap = new Map<String, Object>();
      fcAuthoritiesMap.put('legacy_name', 'ref_financial_center');
      fcAuthoritiesMap.put('legacy_reference', ds.ER_Financial_Center__c);
      authorities.add(fcAuthoritiesMap);
      deliverySitesAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_client_id', ds.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'client');
      syncStateValues.put(
        'status',
        (ds.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(ds.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', ds.ER_WS_result_Text__c);
      syncStateValues.put('code', ds.ER_Sync_Code__c);
      syncStateValues.put('event_date', ds.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', ds.LastModifiedDate);
      syncState.add(syncStateValues);
      deliverySitesAttributes.put('synchronization_states', syncState);
      listDeliverySitesAttributes.add(deliverySitesAttributes);
    }*/
    return listDeliverySitesAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Delivery Site Line Item Structure
   * @param accounts
   * @param contracts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildDeliverySiteLineItem(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> ModifiedElements
  ) {
    List<Map<String, Object>> listDeliverySiteLineItemAttributes = new List<Map<String, Object>>();
    /*for (ER_Solution_Line_Item__c dsli : [
      SELECT
        Id,
        ER_Delivery_Site__c,
        ER_Parent_Line_Item__r.ER_Global_Status__c,
        ER_Global_Status__c,
        ER_Status__c,
        LastModifiedDate,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Solution__r.ProductCode,
        ER_Terms_Conditions__c,
        ER_Contract__r.Status,
        ER_Global_Status_Sync__c,
        ER_Parent_Line_Item__r.ER_Global_Status_Sync__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Delivery_Site_Line_Item'
        AND ER_Delivery_Site__r.ER_Account_Name__c IN :accounts
        AND (ER_Contract__c IN :contracts
        OR ER_Contract__r.Status = 'Activated')
    ]) {
      Map<String, Object> deliverySiteLineItemAttributes = new Map<String, Object>();
      Map<String, Object> deliverySiteLineItemAttributesValues = new Map<String, Object>();
      deliverySiteLineItemAttributesValues.put(
        'parent_global_status',
        (dsli.ER_Contract__r.Status == 'Draft'
          ? dsli.ER_Parent_Line_Item__r.ER_Global_Status_Sync__c
          : dsli.ER_Parent_Line_Item__r.ER_Global_Status__c)
      );
      deliverySiteLineItemAttributesValues.put(
        'global_status',
        (dsli.ER_Contract__r.Status == 'Draft' ? dsli.ER_Global_Status_Sync__c : dsli.ER_Global_Status__c)
      );
      deliverySiteLineItemAttributesValues.put('status', dsli.ER_Status__c);
      deliverySiteLineItemAttributesValues.put('specificities', dsli.ER_Terms_Conditions__c);
      deliverySiteLineItemAttributes.put('attributes', deliverySiteLineItemAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> acceptorAuthoritiesMap = new Map<String, Object>();
      acceptorAuthoritiesMap.put('legacy_name', 'record_id');
      acceptorAuthoritiesMap.put('legacy_reference', dsli.Id);
      authorities.add(acceptorAuthoritiesMap);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'ref_delivery_site');
      authoritiesMap.put('legacy_reference', dsli.ER_Delivery_Site__c);
      authorities.add(authoritiesMap);
      Map<String, Object> productAuthoritiesMap = new Map<String, Object>();
      productAuthoritiesMap.put('legacy_name', 'ref_product');
      productAuthoritiesMap.put('legacy_reference', dsli.ER_Solution__r.ProductCode);
      authorities.add(productAuthoritiesMap);
      deliverySiteLineItemAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_client_id', dsli.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'client');
      syncStateValues.put(
        'status',
        (dsli.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(dsli.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', dsli.ER_WS_result_Text__c);
      syncStateValues.put('code', dsli.ER_Sync_Code__c);
      syncStateValues.put('event_date', dsli.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', dsli.LastModifiedDate);
      syncState.add(syncStateValues);
      deliverySiteLineItemAttributes.put('synchronization_states', syncState);
      listDeliverySiteLineItemAttributes.add(deliverySiteLineItemAttributes);
    }*/
    return listDeliverySiteLineItemAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 17/02/2022
   * @description Build Distribution Point Structure
   * @param accounts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildDistributionPoint(Set<Id> accounts, Set<Id> ModifiedElements) {
    List<Map<String, Object>> listDistributionPointAttributes = new List<Map<String, Object>>();
    /*for (ER_Distribution_Point__c dp : [
      SELECT
        Id,
        Name,
        ER_Delivery_Site__c,
        ER_Card_Operational_System_ID__c,
        LastModifiedDate,
        ER_Country_Code__c,
        ER_Creation_date_in_OS__c,
        ER_WS_result_Text__c,
        ER_Sync_Code__c,
        ER_Last_date_of_Sync__c,
        ER_City__c,
        ER_Country__c,
        ER_Contact__c,
        ER_Street__c,
        ER_Zip_Code__c
      FROM ER_Distribution_Point__c
      WHERE ER_Delivery_Site__r.ER_Account_Name__c IN :accounts
    ]) {
      Map<String, Object> distributionPointAttributes = new Map<String, Object>();
      Map<String, Object> distributionPointAttributesValues = new Map<String, Object>();
      distributionPointAttributesValues.put('name', dp.Name);
      //Address
      Map<String, Object> distributionPointAddressValues = new Map<String, Object>();
      distributionPointAddressValues.put('country', dp.ER_Country__c);
      distributionPointAddressValues.put('country_code', (dp.ER_Street__c != null ? dp.ER_Country_Code__c : null));
      distributionPointAddressValues.put('zip_code', dp.ER_Zip_Code__c);
      distributionPointAddressValues.put('state', null);
      distributionPointAddressValues.put('city', dp.ER_City__c);
      distributionPointAddressValues.put('street', dp.ER_Street__c);
      distributionPointAddressValues.put('street_additional', null);
      distributionPointAddressValues.put('address_complement', null);
      distributionPointAddressValues.put('latitude', null);
      distributionPointAddressValues.put('longitude', null);
      distributionPointAddressValues.put('address_type', null);
      distributionPointAttributesValues.put('address', distributionPointAddressValues);
      distributionPointAttributes.put('attributes', distributionPointAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> contactAuthoritiesMap = new Map<String, Object>();
      contactAuthoritiesMap.put('legacy_name', 'ref_contact');
      contactAuthoritiesMap.put('legacy_reference', dp.ER_Contact__c);
      authorities.add(contactAuthoritiesMap);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'record_id');
      authoritiesMap.put('legacy_reference', dp.Id);
      authorities.add(authoritiesMap);
      Map<String, Object> fcAuthoritiesMap = new Map<String, Object>();
      fcAuthoritiesMap.put('legacy_name', 'ref_delivery_site');
      fcAuthoritiesMap.put('legacy_reference', dp.ER_Delivery_Site__c);
      authorities.add(fcAuthoritiesMap);
      distributionPointAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_client_id', dp.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'client');
      syncStateValues.put(
        'status',
        (dp.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(dp.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', dp.ER_WS_result_Text__c);
      syncStateValues.put('code', dp.ER_Sync_Code__c);
      syncStateValues.put('event_date', dp.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', dp.LastModifiedDate);
      syncState.add(syncStateValues);
      distributionPointAttributes.put('synchronization_states', syncState);
      listDistributionPointAttributes.add(distributionPointAttributes);
    }*/
    return listDistributionPointAttributes;
  }

  /**
   * @AUTHOR KHAD
   * @date 05/31/2021
   * @description Build Distribution Point Line Item Structure
   * @param accounts
   * @param contracts
   * @param ModifiedElements
   *
   * @return
   */
  public static List<Map<String, Object>> buildDistributionPointLineItem(
    Set<Id> accounts,
    Set<Id> contracts,
    Set<Id> ModifiedElements
  ) {
    List<Map<String, Object>> listDistributionPointLineItemAttributes = new List<Map<String, Object>>();
    /*for (ER_Solution_Line_Item__c dsli : [
      SELECT
        Id,
        ER_Distribution_Point__c,
        ER_Parent_Line_Item__r.ER_Global_Status__c,
        ER_Global_Status__c,
        ER_Status__c,
        LastModifiedDate,
        ER_Sync_result__c,
        ER_Last_date_of_Sync__c,
        ER_WS_result_Text__c,
        ER_Solution__r.ProductCode,
        ER_Terms_Conditions__c,
        ER_Contract__r.Status,
        ER_Global_Status_Sync__c,
        ER_Parent_Line_Item__r.ER_Global_Status_Sync__c,
        ER_Card_Operational_System_ID__c,
        ER_Creation_date_in_OS__c,
        ER_Sync_Code__c
      FROM ER_Solution_Line_Item__c
      WHERE
        RecordType.DeveloperName = 'ER_Distribution_Point_Line_Item'
        AND ER_Distribution_Point__r.ER_Delivery_Site__r.ER_Account_Name__c IN :accounts
        AND (ER_Contract__c IN :contracts
        OR ER_Contract__r.Status = 'Activated')
    ]) {
      Map<String, Object> distributionPointLineItemAttributes = new Map<String, Object>();
      Map<String, Object> distributionPointLineItemAttributesValues = new Map<String, Object>();
      distributionPointLineItemAttributesValues.put(
        'parent_global_status',
        (dsli.ER_Contract__r.Status == 'Draft'
          ? dsli.ER_Parent_Line_Item__r.ER_Global_Status_Sync__c
          : dsli.ER_Parent_Line_Item__r.ER_Global_Status__c)
      );
      distributionPointLineItemAttributesValues.put(
        'global_status',
        (dsli.ER_Contract__r.Status == 'Draft' ? dsli.ER_Global_Status_Sync__c : dsli.ER_Global_Status__c)
      );
      distributionPointLineItemAttributesValues.put('status', dsli.ER_Status__c);
      distributionPointLineItemAttributesValues.put('specificities', dsli.ER_Terms_Conditions__c);
      distributionPointLineItemAttributes.put('attributes', distributionPointLineItemAttributesValues);
      //authorities
      List<Map<String, Object>> authorities = new List<Map<String, Object>>();
      Map<String, Object> acceptorAuthoritiesMap = new Map<String, Object>();
      acceptorAuthoritiesMap.put('legacy_name', 'record_id');
      acceptorAuthoritiesMap.put('legacy_reference', dsli.Id);
      authorities.add(acceptorAuthoritiesMap);
      Map<String, Object> authoritiesMap = new Map<String, Object>();
      authoritiesMap.put('legacy_name', 'ref_distribution_point');
      authoritiesMap.put('legacy_reference', dsli.ER_Distribution_Point__c);
      authorities.add(authoritiesMap);
      Map<String, Object> productAuthoritiesMap = new Map<String, Object>();
      productAuthoritiesMap.put('legacy_name', 'ref_product');
      productAuthoritiesMap.put('legacy_reference', dsli.ER_Solution__r.ProductCode);
      authorities.add(productAuthoritiesMap);
      distributionPointLineItemAttributes.put('authorities', authorities);
      //synchronization_states
      List<Map<String, Object>> syncState = new List<Map<String, Object>>();
      Map<String, Object> syncStateValues = new Map<String, Object>();
      syncStateValues.put('local_client_id', dsli.ER_Card_Operational_System_ID__c);
      syncStateValues.put('scope', 'client');
      syncStateValues.put(
        'status',
        (dsli.ER_Creation_date_in_OS__c != null
          ? (ModifiedElements.contains(dsli.Id) ? 'changed' : 'synchronized')
          : 'not_synchronized')
      );
      syncStateValues.put('message', dsli.ER_WS_result_Text__c);
      syncStateValues.put('code', dsli.ER_Sync_Code__c);
      syncStateValues.put('event_date', dsli.ER_Last_date_of_Sync__c);
      syncStateValues.put('last_modification_date', dsli.LastModifiedDate);
      syncState.add(syncStateValues);
      distributionPointLineItemAttributes.put('synchronization_states', syncState);
      listDistributionPointLineItemAttributes.add(distributionPointLineItemAttributes);
    }*/
    return listDistributionPointLineItemAttributes;
  }

  /**
   * @author ALK
   * @date 02/06/2021
   * @description Operate the response returned by EDG v3
   * @param jsonInput
   */
  public static void operateLegacyResponse(String jsonInput) {
    if (UtilsBypass.canTrigger('operateLegacyResponse')) {
      List<Account> accounts = new List<Account>();
      List<ER_Solution_Line_Item__c> solutionsItems = new List<ER_Solution_Line_Item__c>();
      List<Contact> contacts = new List<Contact>();
      List<ER_Financial_Center__c> financialCenters = new List<ER_Financial_Center__c>();
      List<ER_Store__c> stores = new List<ER_Store__c>();
      List<ER_StoreCategory__c> storeCategories = new List<ER_StoreCategory__c>();
      List<ER_Acceptor__c> acceptors = new List<ER_Acceptor__c>();
      List<ER_Bank_Account__c> bankAccounts = new List<ER_Bank_Account__c>();
      List<ER_Contact_Role__c> contactRoles = new List<ER_Contact_Role__c>();
      List<ER_Delivery_Site__c> deliverySites = new List<ER_Delivery_Site__c>();
      List<ER_Distribution_Point__c> distributionPoints = new List<ER_Distribution_Point__c>();
      List<Contract> contracts = new List<Contract>();
      List<ER_ContractLineItem__c> contractItems = new List<ER_ContractLineItem__c>();
      String limitValue = Utils.getGlobalSettingsValueFromKey('Synchro_Record_Limit');
      Integer recordLimit = (String.isNotBlank(limitValue) ? Integer.valueOf(limitValue) : 100);
      Boolean asyncFlag = false;
      System.debug('####KHAD jsonInput : ' + jsonInput);
      Map<String, Object> obj = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
      Map<String, Object> meta = (Map<String, Object>) obj.get('meta');
      Map<String, Object> data = (Map<String, Object>) obj.get('data');
      if (data != null) {
        List<Object> synchronizationResults = (List<Object>) data.get('synchronization_results');
        for (Object o : synchronizationResults) {
          Map<String, Object> results = (Map<String, Object>) o;
          Map<String, Object> attributes = (Map<String, Object>) results.get('attributes');
          Map<String, Object> syncResult = (Map<String, Object>) results.get('synchronization_result');
          System.debug('>>>>> ALK - o : ' + o);
          System.debug('>>>>> ALK - attributes.type : ' + attributes.get('type'));
          System.debug('>>>>> ALK - attributes.record_id : ' + attributes.get('record_id'));
          System.debug('>>>>> ALK - syncResults.scope : ' + syncResult.get('scope'));
          System.debug('>>>>> ALK - syncResults.status : ' + syncResult.get('status'));
          System.debug('>>>>> ALK - syncResults.code : ' + syncResult.get('code'));
          System.debug('>>>>> ALK - syncResults.event_date : ' + syncResult.get('event_date'));
          if (attributes != null && syncResult != null) {
            String objectType = (String) attributes.get('type');
            switch on objectType {
              when 'account' {
                accounts.add(
                  new Account(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    //Removed the 254 logic
                    ER_WS_result_Text_Long__c = (String) syncResult.get('message'),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Card_Client_Operational_System_ID__c = (String) syncResult.get('local_client_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              /*when 'account_line_item' {
                solutionsItems.add(
                  new ER_Solution_Line_Item__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = ((String) syncResult.get('local_id') != ''
                      ? (String) syncResult.get('local_id')
                      : (String) syncResult.get('local_client_id')),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }*/
              when 'contact' {
                contacts.add(
                  new Contact(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Client_Card_Operational_System_ID__c = (String) syncResult.get('local_client_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              /*when 'financial_center' {
                financialCenters.add(
                  new ER_Financial_Center__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_Synchronization_Date__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = ((String) syncResult.get('local_id') != ''
                      ? (String) syncResult.get('local_id')
                      : (String) syncResult.get('local_client_id')),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'financial_center_line_item' {
                solutionsItems.add(
                  new ER_Solution_Line_Item__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = ((String) syncResult.get('local_id') != ''
                      ? (String) syncResult.get('local_id')
                      : (String) syncResult.get('local_client_id')),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'store' {
                stores.add(
                  new ER_Store__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_Date_Of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'store_line_item' {
                solutionsItems.add(
                  new ER_Solution_Line_Item__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'store_category' {
                storeCategories.add(
                  new ER_StoreCategory__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'acceptor' {
                acceptors.add(
                  new ER_Acceptor__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'acceptor_line_item' {
                solutionsItems.add(
                  new ER_Solution_Line_Item__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'bank_account' {
                bankAccounts.add(
                  new ER_Bank_Account__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_id'),
                    ER_Client_Card_Operational_System_ID__c = (String) syncResult.get('local_client_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'contact_role' {
                contactRoles.add(
                  new ER_Contact_Role__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_External_Id__c = ((String) syncResult.get('local_id') != ''
                      ? (String) syncResult.get('local_id')
                      : (String) syncResult.get('local_client_id')),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'delivery_site' {
                deliverySites.add(
                  new ER_Delivery_Site__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_client_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'delivery_site_line_item' {
                solutionsItems.add(
                  new ER_Solution_Line_Item__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_client_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'distribution_point' {
                distributionPoints.add(
                  new ER_Distribution_Point__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_client_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'distribution_point_line_item' {
                solutionsItems.add(
                  new ER_Solution_Line_Item__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = (String) syncResult.get('local_client_id'),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'contract' {
                contracts.add(
                  new Contract(
                    Id = (Id) attributes.get('record_id'),
                    ER_WS_StatusCode__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_Message__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = ((String) syncResult.get('local_id') != ''
                      ? (String) syncResult.get('local_id')
                      : (String) syncResult.get('local_client_id')),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }
              when 'contract_line_item' {
                contractItems.add(
                  new ER_ContractLineItem__c(
                    Id = (Id) attributes.get('record_id'),
                    ER_Sync_result__c = (String) syncResult.get('status'),
                    ER_Last_date_of_Sync__c = Datetime.now(),
                    ER_WS_result_Text__c = (((String) syncResult.get('message'))?.length() > 254
                      ? (((String) syncResult.get('message'))?.substring(0, 250) + '...')
                      : ((String) syncResult.get('message'))),
                    ER_Card_Operational_System_ID__c = ((String) syncResult.get('local_id') != ''
                      ? (String) syncResult.get('local_id')
                      : (String) syncResult.get('local_client_id')),
                    ER_Sync_Code__c = (String) syncResult.get('code')
                  )
                );
              }*/
            }
          }
        }

        // We insert one sObject type at a time in order to avoid the chunk limits
        //Accounts
        if (!accounts.isEmpty())
          update accounts;

        //Contacts
        /*if (!contacts.isEmpty())
          update contacts;

        //Financial Centers
        if (!financialCenters.isEmpty())
          update financialCenters;

        //Bank Accounts
        if (!bankAccounts.isEmpty())
          update bankAccounts;

        //Delivery Sites
        if (!deliverySites.isEmpty())
          update deliverySites;

        //Distribution Points
        if (!distributionPoints.isEmpty())
          update distributionPoints;

        //Contracts
        if (!contracts.isEmpty())
          update contracts;

        //Contract line Items
        if (!contractItems.isEmpty())
          update contractItems;

        //Solution Line Items
        if (!solutionsItems.isEmpty() && solutionsItems.size() <= recordLimit)
          update solutionsItems;
        else if (solutionsItems.size() > recordLimit)
          asyncFlag = true;

        //Stores
        if (!stores.isEmpty() && stores.size() <= recordLimit)
          update stores;
        else if (stores.size() > recordLimit)
          asyncFlag = true;

        //Categories
        if (!storeCategories.isEmpty() && storeCategories.size() <= recordLimit)
          update storeCategories;
        else if (storeCategories.size() > recordLimit)
          asyncFlag = true;

        //Acceptors
        if (!acceptors.isEmpty() && acceptors.size() <= recordLimit)
          update acceptors;
        else if (acceptors.size() > recordLimit)
          asyncFlag = true;

        //Contact Roles
        if (!contactRoles.isEmpty() && contactRoles.size() <= recordLimit)
          update contactRoles;
        else if (contactRoles.size() > recordLimit)
          asyncFlag = true;

        if (asyncFlag) {
          List<ER_Solution_Line_Item__c> solutionsItemsAsync = (solutionsItems.size() > recordLimit
            ? solutionsItems
            : null);
          List<ER_Store__c> storesAsync = (stores.size() > recordLimit ? stores : null);
          List<ER_StoreCategory__c> storeCategoriesAsync = (storeCategories.size() > recordLimit
            ? storeCategories
            : null);
          List<ER_Acceptor__c> acceptorsAsync = (acceptors.size() > recordLimit ? acceptors : null);
          List<ER_Contact_Role__c> contactRolesAsync = (contactRoles.size() > recordLimit ? contactRoles : null);
          System.enqueueJob(
            new ER_DMLRecordsAsync(
              solutionsItemsAsync,
              storesAsync,
              storeCategoriesAsync,
              acceptorsAsync,
              contactRolesAsync,
              Constants.UPDATE_DML
            )
          );
        }*/
      }
    }
  }
}