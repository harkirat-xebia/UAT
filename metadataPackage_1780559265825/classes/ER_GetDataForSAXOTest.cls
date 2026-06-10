/**
 * @author : ALK
 * @date : 09/06/2021
 * @desc : ER_GetDataForSAXOTest
 * @see ER_GetDataForSAXOTest
 */

@IsTest
public class ER_GetDataForSAXOTest {
  @IsTest
  static void doGet() {
    Profile pr = [SELECT Id FROM Profile WHERE Name = 'ER Integration'];
    User u = new User(
      LastName = 'admin',
      Username = 'test@clientsales.com',
      Email = 'test@clientsales.com',
      Alias = 'cli',
      CommunityNickname = 'cli',
      TimeZoneSidKey = 'Europe/Paris',
      LocaleSidKey = 'fr_FR',
      EmailEncodingKey = 'UTF-8',
      ProfileId = pr.Id,
      LanguageLocaleKey = 'en_US',
      ER_Business_Unit__c = 'PL'
    );
    insert u;

    System.runAs(u) {
      Account a = TestDataFactory.newAccount();
      a.ER_BUPicklist__c = 'PL';
      a.ER_Status__c = 'Active';
      insert a;

      Contact c = TestDataFactory.newContact(a);
      c.ER_BUPicklist__c = 'PL';
      insert c;

      ER_Financial_Center__c f = TestDataFactory.newMerchantFC(a);
      //f.ER_Contact__c = c.Id;
      insert f;

      //getStore(String name, String accountId, String financialCenterId, Date startDate, String street, String city,String zipCode, String country) {
      ER_Store__c s = APER07_UtilityTestMethod.getStore(
        'StoreName' + Datetime.now().getTime(),
        a.Id,
        f.Id,
        Date.today(),
        'Some Street',
        'Warsaw',
        '001',
        'Poland'
      );
      insert s;

      ER_Acceptor__c acc = APER07_UtilityTestMethod.getAcceptor(s.Id);
      acc.ER_MID_Authorization__c = '288994';
      acc.ER_MID_Clearing__c = '288994';
      acc.ER_SubMID_Authorization__c = '';
      acc.ER_Sub_MID_Clearing__c = '';
      insert acc;

      ER_Acceptor__c acc1 = APER07_UtilityTestMethod.getAcceptor(s.Id);
      acc1.ER_MID_Authorization__c = '288994';
      acc1.ER_SubMID_Authorization__c = '';
      acc1.ER_MID_Clearing__c = '';
      acc1.ER_Sub_MID_Clearing__c = '';
      insert acc1;

      Test.startTest();
      String bu = 'PL';

      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/getDataForSAXO';
      req.params.put('bu', bu);
      req.params.put('date', Datetime.now().format('yyyy-MM-dd'));
      req.params.put('accountType', 'affiliate');
      req.httpMethod = 'GET';
      req.addHeader('Content-Type', 'application/json');
      RestContext.request = req;
      RestContext.response = res;

      ER_GetDataForSAXO.SaxoStructureResponse obj = ER_GetDataForSAXO.doGet();
      System.assert(obj != null, 'erreur while calling the service');

      Test.stopTest();
    }

  }
}