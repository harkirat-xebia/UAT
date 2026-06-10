@isTest
public class WSHU07_SynchronizeFinancialWS_Test {
  /*
    ----------------------------------------------------------------------
    -- - Name          : APHU07_SynchronizeFiancialWS_Test
    -- - Author        : AAB
    -- - Description   : Test class related to the Apex classes cited below
                        - WSHU07_SynchronizeFinancialWS
    -- Maintenance History:
    --
    -- Date         Name                Version     Remarks
    -- -----------  -----------         --------    ---------------------------------------
    -- 05-MAR-2018  AAB                 1.0         Initial version
    ---------------------------------------------------------------------------------------
    */

  @testSetup
  static void testSetup() {
    String merchantRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('ER_Company_Account_RT')
      .getRecordTypeId();
    List<Account> accList = APHU15_UtilityTestMethod.createAccountsStandard(
      1,
      merchantRecordtypeId,
      '11111111-1-11',
      true
    );
    Test.setMock(HttpCalloutMock.class, new WSMockImpl(200));
    if (!accList.isEmpty()) {
      List<Contact> contactList = APHU15_UtilityTestMethod.createcontactsStandard(1, accList[0].id, true);

      if (!contactList.isEmpty()) {
        List<ER_Financial_Center__c> finCenterList = APHU15_UtilityTestMethod.createFinCentersStandard(
          1,
          accList[0].id,
          contactList[0].id,
          true,
          Label.LABS_SF_FinancialCenter_Merchant
        );

        if (!finCenterList.isEmpty()) {
          List<ER_Bank_Account__c> bankAccountList = APHU15_UtilityTestMethod.createbankAccountsStandard(
            1,
            finCenterList[0].id,
            true
          );

          if (!bankAccountList.isEmpty()) {
            finCenterList[0].ER_Bank_Account__c = bankAccountList[0].id;
            update finCenterList[0];
          }

          List<ER_Store__c> storeList = APHU15_UtilityTestMethod.createstoresStandard(
            accList[0].id,
            finCenterList,
            contactList[0].id,
            true
          );

          if (!storeList.isEmpty()) {
            List<ER_Acceptor__c> acceptorList = APHU15_UtilityTestMethod.createacceptorsStandard(storeList, true);
          }
        }
      }
    }
  }

  static testMethod void test() {
    List<Account> accList = [SELECT id FROM Account];
    Set<Id> accountIds = new Set<Id>();

    for (Account accountInst : accList) {
      accountIds.add(accountInst.id);
    }
    if (!accountIds.isEmpty()) {
      Test.setMock(HttpCalloutMock.class, new WSMockImpl(200));
      WSHU07_SynchronizeFinancialWS.addupdateFinancialCentersFuture(accountIds);
    }
  }

  public class WSMockImpl implements HttpCalloutMock {
    Integer statusCode;

    public WSMockImpl(Integer statusCode) {
      this.statusCode = statusCode;
    }

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      List<ER_Financial_Center__c> fcList = [SELECT id FROM ER_Financial_Center__c limit 1];
      String wsOK =
        '{' +
        '"meta": {' +
        '"status": "succeeded",' +
        '"messages": [' +
        '{' +
        '"code": "WAR_INFO_MISSING",' +
        '"description": "When a field which should be filled in",' +
        '"level": "warning"' +
        '},' +
        '{' +
        '"code": "WAR_NOT_PERMIT_FIELD",' +
        '"description": "When a field which should be empty is filled",' +
        '"level": "warning"' +
        '}' +
        ']' +
        '},' +
        '"data": [' +
        '{' +
        '"identifiers": [' +
        '{' +
        '"authority": "state.merchant.vat_number",' +
        '"reference": "12245678-0-11"' +
        '},' +
        '{' +
        '"authority": "ds.invoicecenter.technical_id",' +
        '"reference": "'+fcList[0].id+'"' +
        '},' +
        '{' +
        '"authority": "rs.financial_center.technical_id",' +
        '"reference": "2885"' +
        '}' +
        ']' +
        '}' +
        ']' +
        '}';

      String wsKO =
        '{' +
        '"meta": {' +
        '"status": "failed",' +
        '"messages": [' +
        '{' +
        '"code": "INTERNAL_ERROR",' +
        '"level": "error",' +
        '"text": "Oups... Something wrong on the server! Please contact the administrator to report the issue."' +
        '}' +
        ']' +
        '}' +
        '}';

      System.debug('####TEST req.getEndpoint() : ' + req.getEndpoint());

      if (statusCode == 200) {
        res.setBody(wsOK);
      } else if (statusCode == 500) {
        res.setBody(wsKO);
      }

      res.setStatusCode(statusCode);
      return res;
    }
  }
}