/**
 * Created by ridouane on 30/05/2018.
 */
@IsTest
public with sharing class WSBE01_Belfirst_Test {
  public class WSBE01_Belfirst_Test_CalloutInfos_Mock implements HttpCalloutMock {
    //Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      String testBody = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><FindByBVDIdResponse xmlns="http://bvdep.com/webservices/"><FindByBVDIdResult><Token>0</Token><SelectionCount>1</SelectionCount></FindByBVDIdResult></FindByBVDIdResponse></soap:Body></soap:Envelope>';
      // Create a fake response
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json;charset=UTF-8');
      response.setBody(testBody);

      response.setStatusCode(200);
      return response;
    }
  }

  public class WSBE01_Belfirst_Test_CalloutData_Mock implements HttpCalloutMock {
    //Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      String testBody = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetListDataResponse xmlns="http://bvdep.com/webservices/"><GetListDataResult><?xml version="1.0" encoding="utf-16"?><queryResults version="1.0" xmlns="http://www.bvdep.com/schemas/RemoteAccessDataResults.xsd"><record id="BE0663563934" dataModelId="Financial" selectionId="BE0663563934"><item field="NAME" alias="NAME" valueType="AccountValue" resultType="String" fieldType="String">ASSOCIATION PHILANTHROPIQUE DE LA COMMEDIA DELL\'ARTE</item><item field="-9001" alias="-9001" fieldType="String" dimSelType="Relative" dim="NrOfShareholders" resultType="NotAvailable" index="-1" valueType="AccountValue"></item><item field="BVDID" alias="BVDID" valueType="AccountValue" resultType="String" fieldType="String">BE0663563934</item><item field="COMPANY_NUMBER" alias="COMPANY_NUMBER" valueType="AccountValue" resultType="String" fieldType="String">0663 563 934</item><item field="RC" alias="RC" valueType="AccountValue" resultType="String" fieldType="String">-</item><item field="LVAT" alias="LVAT" valueType="AccountValue" resultType="NotAvailable" fieldType="String"></item><item field="ADDRESS" alias="ADDRESS" valueType="AccountValue" resultType="String" fieldType="String">Rue Saint-Jacques 33</item><item field="POSTCODE" alias="POSTCODE" valueType="AccountValue" resultType="String" fieldType="String">7130</item><item field="TOWN" alias="TOWN" valueType="AccountValue" resultType="String" fieldType="String">BINCHE</item><item field="COUNTRY" alias="COUNTRY" valueType="AccountValue" resultType="String" fieldType="String">BELGIUM</item><item field="PHONE" alias="PHONE" valueType="AccountValue" resultType="NotAvailable" fieldType="String"></item><item field="FAX" alias="FAX" valueType="AccountValue" resultType="NotAvailable" fieldType="String"></item><item field="LANGEMPL" alias="LANGEMPL" valueType="AccountValue" resultType="String" fieldType="String">Français</item><item field="TYPE" alias="TYPE" valueType="AccountValue" resultType="String" fieldType="String">Association sans but lucratif</item><item field="EMPLOYEE" alias="EMPLOYEE" valueType="AccountValue" resultType="NotAvailable" units="0" fieldType="Value">n.d.</item><item field="NACEBELCCOD2008" alias="NACEBELCCOD2008" valueType="AccountValue" resultType="String" fieldType="String">94900</item><item field="NACEBELCDES2008" alias="NACEBELCDES2008" valueType="AccountValue" resultType="String" fieldType="String">Activités des autres organisations associatives</item><item field="NACEBELSCOD" alias="NACEBELSCOD" fieldType="String" dimSelType="Relative" dim="NrNaceBel2008Sec" resultType="NotAvailable" index="-1" valueType="AccountValue"></item><item field="NACEBELSDES" alias="NACEBELSDES" fieldType="String" dimSelType="Relative" dim="NrNaceBel2008Sec" resultType="NotAvailable" index="-1" valueType="AccountValue"></item></record></queryResults></GetListDataResult></GetListDataResponse></soap:Body></soap:Envelope>';
      // Create a fake response
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json;charset=UTF-8');
      response.setBody(testBody);

      response.setStatusCode(200);
      return response;
    }
  }

  public class WSBE01_Belfirst_Test_CalloutLogin_Mock implements HttpCalloutMock {
    //Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      String testBody = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><OpenResponse xmlns="http://bvdep.com/webservices/"><OpenResult>1CHODHT03KIFZM1</OpenResult></OpenResponse></soap:Body></soap:Envelope>';
      // Create a fake response
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json;charset=UTF-8');
      response.setBody(testBody);

      response.setStatusCode(200);
      return response;
    }
  }

  @isTest
  static void testWebservice() {
    //initMock('BelfirstMock');
    Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test_CalloutLogin_Mock());
    WSBE01_Belfirst w = new WSBE01_Belfirst();
    Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test_CalloutInfos_Mock());
    w.setLanguage('fr_BE');
    w.findByBVDId('BE0663563934');
    Test.setMock(HttpCalloutMock.class, new WSBE01_Belfirst_Test_CalloutData_Mock());
    Map<String, String> infos = w.getListData();
    // Map<String, String> infos = w.getInfos('BE0663563934', 'fr_BE');
    w.closeConnection();

    WSBE01_Belfirst.Belfirst BelfirstInstance = new WSBE01_Belfirst.Belfirst();

    BelfirstInstance.Street = infos.get('ADDRESS');
    BelfirstInstance.Name = infos.get('NAME');
    BelfirstInstance.Dic = infos.get('BVDID');
    BelfirstInstance.IcDPH = infos.get('COMPANY_NUMBER');
    BelfirstInstance.LegalFormText = infos.get('NAME');
    BelfirstInstance.StreetNumber = infos.get('ADDRESS');
    BelfirstInstance.ZipCode = infos.get('POSTCODE');
    BelfirstInstance.City = infos.get('TOWN');
    BelfirstInstance.Country = infos.get('COUNTRY');
    BelfirstInstance.NaceCode = infos.get('NACEBELCCOD2008');
    BelfirstInstance.NaceText = infos.get('NACEBELCDES2008');

    System.assertEquals(BelfirstInstance.Street, 'Rue Saint-Jacques 33');
    System.assertEquals(BelfirstInstance.Dic, 'BE0663563934');
    System.assertEquals(BelfirstInstance.IcDPH, '0663 563 934');
    System.assertEquals(BelfirstInstance.Country, 'BELGIUM');
    System.assertEquals(BelfirstInstance.LegalFormText, 'ASSOCIATION PHILANTHROPIQUE DE LA COMMEDIA DELL\'ARTE');
    System.assertEquals(BelfirstInstance.ZipCode, '7130');
    System.assertEquals(BelfirstInstance.City, 'BINCHE');
  }
}