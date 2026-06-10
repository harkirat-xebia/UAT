/**
 * @description       :
 * @author            : AAM
 * @group             :
 * @last modified on  : 27-10-2022
 * @last modified by  : AAM
 **/
public with sharing class APER30_PDFContractController {
  public String lang { get; set; }
  public Map<String, String> varMap { get; set; }
  public transient List<String> htmlMarkupList { get; set; }
  public String mainColor { get; set; }

  public APER30_PDFContractController() {
    Map<String, String> paramMap = ApexPages.CurrentPage().getparameters();
    //Params to prepare: accountId, opportunityId, solution code, lang, scope
    String accountId = paramMap.get('accId');
    this.lang = paramMap.get('lang');
    String oppId = paramMap.get('oppId');
    String scope = paramMap.get('scope');
    String solutionCode = paramMap.get('solutionCode');

    Account acc = [
      SELECT
        Id,
        BillingStreet,
        BillingPostalCode,
        BillingCity,
        BillingCountry,
        ER_BUPicklist__c,
        ER_Country_Code__c,
        ER_Legal_Name__c,
        ER_Legal_Form__c,
        ER_Registration_Number__c,
        ER_VAT_Number__c,
        HU_HQ_Contact__c,
        HU_HQ_Contact__r.FirstName,
        HU_HQ_Contact__r.LastName,
        HU_HQ_Contact__r.ER_Role__c,
        Phone,
        ER_Other_Fiscal_ID__c
      FROM Account
      WHERE Id = :accountId
    ][0];
    Contact cnt = [
      SELECT Id, Salutation, FirstName, LastName, MobilePhone, Phone, email, ER_Language__c
      FROM Contact
      WHERE Id = :acc.HU_HQ_Contact__c
    ][0];

    String contractPDFTitleSolution =
      acc.ER_Country_Code__c +
      '-' +
      this.lang +
      '-' +
      solutionCode +
      '-' +
      scope +
      ' Contract PDF';
    String termsConditionsTitle =
      acc.ER_Country_Code__c +
      '-' +
      this.lang +
      '-' +
      solutionCode +
      '-' +
      scope +
      ' Terms and conditions';

    System.debug('>>> contractPDFTitleSolution: ' + contractPDFTitleSolution);
    System.debug('>>> termsConditionsTitle: ' + termsConditionsTitle);

    Map<String, Map<String, String>> labelsMap = APER30_AutoEnrollment_Management.getLabels(
      acc.ER_Country_Code__c,
      scope
    );
    Map<String, Map<String, String>> picklistMap = APER30_AutoEnrollment_Management.getPicklistInfos(
      acc.ER_Country_Code__c,
      this.lang,
      scope
    );

    this.varMap = new Map<String, String>();
    this.htmlMarkupList = new List<String>();

    String companyInfosStructure, contactInfosStructure, finConditionsStructure;

    //TODO automate the list of picklist parameters
    varMap.put('pk_header_image', picklistMap.get('pk_header_image')?.get(solutionCode));
    varMap.put('pk_img_solution_logo', picklistMap.get('pk_img_solution_logo')?.get(solutionCode));
    varMap.put('pk_solution_name', picklistMap.get('pk_solution_name')?.get(solutionCode));
    this.mainColor = picklistMap.get('pk_solution_main_color')?.get(solutionCode);

    varMap.putAll(labelsMap.get('All'));
    varMap.putAll(labelsMap.get(this.lang));
    varMap.putAll(objectToMap(acc));
    varMap.putAll(objectToMap(cnt));
    varMap.put('currentDate', String.valueOf(System.now().format('dd/MM/yyyy')));
    varMap.put('currentTime', String.valueOf(System.now().format('HH:mm')));
    varMap.put('lb_merchant_contact_name', acc.HU_HQ_Contact__r.FirstName + ' ' + acc.HU_HQ_Contact__r.LastName);
    varMap.put('lb_merchant_contact_role', picklistMap.get('pk_role')?.get(acc.HU_HQ_Contact__r.ER_Role__c));

    // build structures tables and add them to htmlMarkupList
    String fcListMarkup = buildVerticalTableInfos(getFinCentersMap(accountId));
    String stListMarkup = buildVerticalTableInfos(getStoresMap(accountId));
    String acListMarkup = buildVerticalTableInfos(getAcceptorsMap(accountId));
    String storeCatListMarkup = buildActivitiesTableInfos(getStoreCatsMap(accountId));
    String finConditionsListMarkup = buildFinConditionsTableInfos(getFinConditions(oppId));

    varMap.put('finCentersTable', resolveVariables(fcListMarkup, varMap));
    varMap.put('storesTable', resolveVariables(stListMarkup, varMap));
    varMap.put('acceptorsTable', resolveVariables(acListMarkup, varMap));
    varMap.put('storeCatsTable', resolveVariables(storeCatListMarkup, varMap));
    varMap.put('finConditionsTable', resolveVariables(finConditionsListMarkup, varMap));

    // get Contract and terms & conditions to build the final PDF
    /*List<Knowledge__kav> knowledgeList = [
      SELECT Id, Title, ER_Article_Body__c, ER_Sequence__c
      FROM Knowledge__kav
      WHERE Title IN (:contractPDFTitleSolution, :termsConditionsTitle) AND PublishStatus = 'Online'
      ORDER BY ER_Sequence__c ASC NULLS LAST
    ];*/
    //htmlMarkupList.add(resolveVariables(knowledgeList[0].ER_Article_Body__c, varMap));
    String termsCondsBlock = '<div style="page-break-after:always;"/> <div style="margin: 5%;width: 90%;font-size: 8pt;color: #88898b;font-family:sans-serif;">';
    //termsCondsBlock += knowledgeList[1].ER_Article_Body__c;
    //termsCondsBlock += '</div>';
    htmlMarkupList.add(termsCondsBlock);
  }

  private String resolveVariables(String fullText, Map<String, String> variablesMap) {
    if (!String.isBlank(fullText)) {
      for (String var : variablesMap.keySet())
        fullText = fullText.replace(
          '{' +
          var +
          '}',
          String.isBlank(variablesMap.get(var)) ? ' ' : variablesMap.get(var)
        );
      fullText = fullText.replaceAll('\\{(.*?)\\}', '&nbsp;'); //Remove unresolved variables by replacing with blank space
      System.debug('>>> fullText2: ' + fullText);
    }
    return fullText;
  }

  private String buildVerticalTableInfos(List<Map<String, String>> datasMap) {
    //TODO Add div for title??
    String htmlMarkup;
    if (!datasMap.isEmpty()) {
      List<String> colNamesList = new List<String>();
      htmlMarkup = '<table class="styled-table" style="word-wrap: break-word; table-layout:fixed;"> <thead> <tr> ';
      // Build table header using the keys of the first map in the list
      for (String colName : datasMap[0].keySet()) {
        colNamesList.add(colName);
        htmlMarkup += '<th>' + colName + '</th>';
      }
      htmlMarkup += '</tr> </thead> <tbody> ';
      // Build table rows
      for (Map<String, String> row : datasMap) {
        htmlMarkup += '<tr> ';
        for (String colName : colNamesList)
          htmlMarkup += '<td>' + row.get(colName) + '</td> ';
        htmlMarkup += '</tr> ';
      }
      htmlMarkup += '</tbody> </table>';
    }
    return htmlMarkup;
  }

  private List<Map<String,String>> getFinConditions(String oppId){
    List<Map<String,String>> finCondList = new List<Map<String,String>>();
    String freeLabel = this.varMap.get('lb_free_service');
    Map<String, String> productTranslationsMap = Utils.getProductTranslationsMap(this.lang);

    for(QuoteLineItem qli:[SELECT Id,Product2Id,ER_Percentage__c,UnitPrice FROM QuoteLineItem WHERE Quote.OpportunityId = :oppId]){
        System.debug('>>> AAM : ProductCode: ' + qli.Product2Id);
        System.debug('>>> AAM : ER_Percentage__c: ' + qli.ER_Percentage__c);
        System.debug('>>> AAM : UnitPrice: ' + qli.UnitPrice);

        String prodLabel = productTranslationsMap.get(qli.Product2Id);
        String prodValue;
        if(qli.ER_Percentage__c == null && qli.UnitPrice == 0.0) prodValue = freeLabel;
        else {
            prodValue = qli.ER_Percentage__c != null ? Double.valueOf(qli.ER_Percentage__c) + '%' : Double.valueOf(qli.UnitPrice) + '€';
        }
        System.debug('>>> AAM : prodLabel: ' + prodLabel);
        System.debug('>>> AAM : prodValue: ' + prodValue);
        finCondList.add(new Map<String, String>{ prodLabel => prodValue});
    }
    return finCondList;
  }

  private Map<String, String> objectToMap(SObject obj) {
    String objStr = JSON.serialize(obj);
    System.debug('>>> objStr: ' + objStr);
    Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(objStr);
    Map<String, Object> attMap = (Map<String, Object>) objMap.get('attributes');
    String objName = String.valueOf(attMap.get('type'));
    objMap.remove('attributes');
    Map<String, String> obj2Map = new Map<String, String>();
    for (String key : objMap.keySet())
      obj2Map.put(objName + '.' + key, String.valueOf(objMap.get(key)));
    return obj2Map;
  }

  private List<Map<String, String>> getFinCentersMap(String accId) {
    List<Map<String, String>> fcMapList = new List<Map<String, String>>();
    for (ER_Financial_Center__c fc : [
      SELECT
        Id,
        Name,
        ER_Contact__r.FirstName,
        ER_Contact__r.LastName,
        ER_Bank_Account__r.ER_IBAN__c,
        ER_Street__c,
        ER_City__c,
        ER_Zip_Code__c
      FROM ER_Financial_Center__c
      WHERE ER_Account_Name__c = :accId AND ER_Type__c = 'Merchant'
    ]) {
      Map<String, String> fcMap = new Map<String, String>();
      fcMap.put('{lb_step2_fin_center}', fc.Name);
      fcMap.put('{lb_step2_contact}', fc.ER_Contact__r.FirstName + ' ' + fc.ER_Contact__r.LastName);
      fcMap.put('{lb_address}', fc.ER_Street__c + ', ' + fc.ER_Zip_Code__c + ' ' + fc.ER_City__c);
      fcMap.put('{lb_step2_iban}', fc.ER_Bank_Account__r.ER_IBAN__c);
      fcMapList.add(fcMap);
    }
    return fcMapList;
  }

  private List<Map<String, String>> getStoresMap(String accId) {
    List<Map<String, String>> stMapList = new List<Map<String, String>>();
    for (ER_Store__c st : [
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
        ER_Merchant__c
      FROM ER_Store__c
      WHERE ER_Financial_Center__r.ER_Account_Name__c = :accId
    ]) {
      Map<String, String> stMap = new Map<String, String>();
      stMap.put('{lb_step2b_store}', st.Name);
      stMap.put('{lb_step2b_store_address}', st.ER_Street__c + ', ' + st.ER_Zip_Code__c + ' ' + st.ER_City__c);
      stMap.put('{lb_step2_fin_center}', st.ER_Financial_Center__r.Name);
      stMapList.add(stMap);
    }
    return stMapList;
  }

  private List<Map<String, String>> getAcceptorsMap(String accId) {
    List<Map<String, String>> acMapList = new List<Map<String, String>>();
    for (ER_Acceptor__c ac : [
      SELECT
        ER_Store__r.Name,
        ER_Store__c,
        ER_Acceptor_Provider__c,
        ER_Acceptor_Model__c,
        ER_TID_Authorization__c,
        ER_Cash_Register_Provider__c,
        ER_IS_Acceptor_Linked_To_Cash_Register__c
      FROM ER_Acceptor__c
      WHERE ER_Store__r.ER_Financial_Center__r.ER_Account_Name__c = :accId
    ]) {
      Map<String, String> acMap = new Map<String, String>();
      acMap.put('{lb_step2b_terminal_provider}', ac.ER_Acceptor_Provider__c);
      acMap.put('{lb_step2b_terminal_model}', String.isBlank(ac.ER_Acceptor_Model__c) ? '' : ac.ER_Acceptor_Model__c);
      acMap.put('{lb_step2b_tid}', ac.ER_TID_Authorization__c);
      String yesNo = (ac.ER_IS_Acceptor_Linked_To_Cash_Register__c == 'Yes') ? '{lb_step2b_yes}' : '{lb_step2b_no}';
      acMap.put('{lb_step2b_is_linked_to_cash_register}', yesNo);
      acMap.put(
        '{lb_step2b_cash_register_provider}',
        String.isBlank(ac.ER_Cash_Register_Provider__c) ? '' : ac.ER_Cash_Register_Provider__c
      );
      acMap.put('{lb_step2b_store}', ac.ER_Store__r.Name);

      acMapList.add(acMap);
    }
    return acMapList;
  }

  private List<Map<String,String>> getStoreCatsMap(String accId){
    List<Map<String, String>> catStoreList = new List<Map<String, String>>();
    Map<String, String> catTransMap = new Map<String, String>();
    String langSearch = this.lang + '%';
    for (ER_Translation__c tra : [
      SELECT Dependent_Value__c, Text__c
      FROM ER_Translation__c
      WHERE Field_API_Name__c = 'ER_StoreCategory__c' AND Language__c LIKE :langSearch
    ])
      catTransMap.put(tra.Dependent_Value__c, tra.Text__c);

    String curStore, catList, storeName;
    for (ER_StoreCategory__c stc : [
      SELECT Store__c, Store__r.Name, Category__c, Main_Category__c
      FROM ER_StoreCategory__c
      WHERE Store__r.ER_Merchant__c = :accId
      ORDER BY Store__c, Main_Category__c DESC
    ]) {
      if (stc.Store__c != curStore) {
        if (!String.isBlank(catList)) {
          catList += '</ul>';
          catStoreList.add(new Map<String, String>{ storeName => catList });
        }
        catList = '<ul>';
      }
      catList +=
        '<li>' +
        catTransMap.get(stc.Category__c) +
        (stc.Main_Category__c ? '{lb_main_storecat}' : '') +
        '</li>';
      curStore = stc.Store__c;
      storeName = stc.Store__r.Name;
    }
    if (!String.isBlank(catList)) {
      catList += '</ul>';
      catStoreList.add(new Map<String, String>{ storeName => catList });
    }
    return catStoreList;
  }

  private String buildActivitiesTableInfos(List<Map<String, String>> datasMap) {
    String htmlMarkup;
    if (!datasMap.isEmpty()) {
      htmlMarkup = '<table class="styled-table"> <thead> <tr> ';
      htmlMarkup += '<th>{lb_step2b_store}</th> <th>{lb_store_activities}</th>';
      htmlMarkup += '</tr> </thead> <tbody> ';
      // Build table rows
      for (Map<String, String> row : datasMap)
        htmlMarkup +=
          '<tr> <td>' +
          new List<String>(row.keySet())[0] +
          '</td> <td>' +
          new List<String>(row.values())[0] +
          '</tr> ';
      htmlMarkup += '</tbody> </table>';
    }
    return htmlMarkup;
  }

  private String buildFinConditionsTableInfos(List<Map<String,String>> datasMap){
    String htmlMarkup;
    if(!datasMap.isEmpty()){
        htmlMarkup = '<table class="styled-table"> <thead> <tr> ';
        htmlMarkup += '<th colspan="6" rowspan="1">{lb_membership_conditions}</th>';
        htmlMarkup += '</tr> </thead> <tbody> ';
        // Build table rows
        for(Map<String,String> row:datasMap) htmlMarkup += '<tr> <td colspan="1" rowspan="1"><span class="label">' + new List<String>(row.keySet())[0] + ':</span><br /> <span class="value" style="text-align: right;">' + new List<String>(row.values())[0] + '</span></td> </tr>';
        htmlMarkup += '</tbody> </table>';
    }
    return htmlMarkup;
  }

}