@isTest
public class APCZ03_AresCallout_ById_Test {
  @isTest
  static void testGetDarvBas() {
    // Associate the callout with a mock response
    Test.setMock(HttpCalloutMock.class, new APCZ02_Ares_CalloutResBas_Mock());

    APCZ03_AresCallout_ById myCallout = new APCZ03_AresCallout_ById();
    // Call method to test
    HttpResponse result = myCallout.getDarvBas('24745391');

    //Verify mock response is not null
    System.assertNotEquals(null, result, 'The callout returned a null response.');

    System.debug('Status=' + result.getHeader('Content-Type'));

    //Verify status code
    System.assertEquals(200, result.getStatusCode(), 'The status code is not 200.');

    //Verify content type
    System.assertEquals(
      'application/json;charset=UTF-8',
      result.getHeader('Content-Type'),
      'The content type value is not expected.'
    );

    //XML check
    String sXml = result.getBody();

    APCZ02_AresXmlReader axr = new APCZ02_AresXmlReader();
    String sJson = axr.ReadDarvBasXml(result);
    //System.debug('DarvBas = ' + sJson);

    APCZ01_AresEntity.AresDarvBas myAresResult = new APCZ01_AresEntity.AresDarvBas();
    myAresResult = (APCZ01_AresEntity.AresDarvBas) JSON.deserialize(sJson, APCZ01_AresEntity.AresDarvBas.class);

    System.assertEquals('Edenred CZ s.r.o.', myAresResult.n03_OF_Name, 'The name must be - Edenred CZ s.r.o.');
  }

  @isTest
  static void testGetDarvRes() {
    // Associate the callout with a mock response
    Test.setMock(HttpCalloutMock.class, new APCZ03_Ares_CalloutDarvRes_Mock());

    APCZ03_AresCallout_ById myCallout = new APCZ03_AresCallout_ById();
    // Call method to test
    HttpResponse result = myCallout.getDarvRes('24745391');

    //Verify mock response is not null
    System.assertNotEquals(null, result, 'The callout returned a null response.');

    System.debug('Status=' + result.getHeader('Content-Type'));

    //Verify status code
    System.assertEquals(200, result.getStatusCode(), 'The status code is not 200.');

    //Verify content type
    System.assertEquals(
      'application/json;charset=UTF-8',
      result.getHeader('Content-Type'),
      'The content type value is not expected.'
    );

    //XML check
    String sXml = result.getBody();
    System.debug('sXml = ' + sXml);

    APCZ02_AresXmlReader axr = new APCZ02_AresXmlReader();
    String sJson = axr.ReadDarvResXml(result, '');
    System.debug('DarvRes = ' + sJson);

    //AresEntity.AresNace myAresResult = new AresEntity.AresNace();
    //myAresResult = (AresEntity.AresNace)JSON.deserialize(sJson, AresEntity.AresNace.class);

    //System.assertEquals('Edenred CZ s.r.o.', myAresResult.n03_OF_Name,'The name must be - Edenred CZ s.r.o.');
  }

  public class APCZ02_Ares_CalloutResBas_Mock implements HttpCalloutMock {
    //Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      //StaticResource sr = [select Body from StaticResource where Name = 'SRCZ01_AresResBas'];
      //String testBody = sr.Body.toString();
      String testBody = '<are:Ares_odpovedi xmlns:are="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer_basic/v_1.0.3" xmlns:D="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_datatypes/v_1.0.3" xmlns:U="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/uvis_datatypes/v_1.0.3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" odpoved_datum_cas="2018-11-27T11:53:36" odpoved_pocet="1" odpoved_typ="Basic" vystup_format="XML" xslt="klient" validation_XSLT="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_odpovedi.xsl" xsi:schemaLocation="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer_basic/v_1.0.3 http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer_basic/v_1.0.3/ares_answer_basic_v_1.0.3.xsd" Id="ares"><are:Odpoved><D:PID>0</D:PID><D:VH><D:K>1</D:K></D:VH><D:PZA>1</D:PZA><D:UVOD><D:ND>Výpis z dat Registru ARES - aktuální stav ke dni 2018-11-26</D:ND><D:ADB>2018-11-26</D:ADB><D:DVY>2018-11-27</D:DVY><D:CAS>11:53:36</D:CAS><D:Typ_odkazu>0</D:Typ_odkazu></D:UVOD><D:VBAS><D:ICO zdroj="OR">24745391</D:ICO><D:DIC zdroj="DPH">CZ24745391</D:DIC><D:OF zdroj="OR">Edenred CZ s.r.o.</D:OF><D:DV>2010-11-01</D:DV><D:PF zdroj="OR"><D:KPF>112</D:KPF><D:NPF>Společnost s ručením omezeným</D:NPF></D:PF><D:AD zdroj="ARES"><D:UC>Pernerova 691</D:UC><D:PB>18600 Praha</D:PB></D:AD><D:AA zdroj="ARES"><D:IDA>207445855</D:IDA><D:KS>203</D:KS><D:NS>Česká republika</D:NS><D:N>Praha</D:N><D:NCO>Karlín</D:NCO><D:NMC>Praha 8</D:NMC><D:NU>Pernerova</D:NU><D:CD>691</D:CD><D:TCD>1</D:TCD><D:CO>42</D:CO><D:PSC>18600</D:PSC><D:AU><U:KOL>19</U:KOL><U:KK>19</U:KK><U:KOK>3100</U:KOK><U:KO>554782</U:KO><U:KPO>86</U:KPO><U:KN>86</U:KN><U:KCO>400637</U:KCO><U:KMC>500208</U:KMC><U:PSC>18600</U:PSC><U:KUL>463906</U:KUL><U:CD>691</U:CD><U:TCD>1</U:TCD><U:CO>42</U:CO><U:KA>77976096</U:KA><U:KOB>93188161</U:KOB></D:AU></D:AA><D:PSU>NAAANANNNNNNNNNNNNNNPNNNANNNNN</D:PSU><D:ROR><D:SZ><D:SD><D:K>1</D:K><D:T>Městský soud v Praze</D:T></D:SD><D:OV>C 170804</D:OV></D:SZ><D:SOR><D:SSU>Aktivní</D:SSU><D:KKZ><D:K>0</D:K></D:KKZ><D:VY><D:K>0</D:K></D:VY><D:ZAM><D:K>0</D:K></D:ZAM><D:LI><D:K>0</D:K></D:LI></D:SOR></D:ROR><D:RRZ><D:ZU><D:KZU>310008</D:KZU><D:NZU>Úřad městské části Praha 8</D:NZU></D:ZU><D:FU><D:KFU>8</D:KFU><D:NFU>Praha 8</D:NFU></D:FU></D:RRZ><D:KPP zdroj="RES">100 - 199 zaměstnanců</D:KPP><D:Nace><D:NACE zdroj="RES">66190</D:NACE><D:NACE zdroj="RES">00</D:NACE><D:NACE zdroj="RES">69200</D:NACE><D:NACE zdroj="RES">74</D:NACE></D:Nace><D:PPI><D:PP zdroj="OR"><D:T>Výroba, obchod a služby neuvedené v přílohách 1 až 3 živnostenského zákona</D:T><D:T>Činnost účetních poradců, vedení účetnictví, vedení daňové evidence</D:T></D:PP><D:PP zdroj="RZP"><D:T>Výroba, obchod a služby neuvedené v přílohách 1 až 3 živnostenského zákona</D:T><D:T>Činnost účetních poradců, vedení účetnictví, vedení daňové evidence</D:T></D:PP></D:PPI><D:Obory_cinnosti><D:Obor_cinnosti><D:K>Z01014</D:K><D:T>Vydavatelské činnosti, polygrafická výroba, knihařské a kopírovací práce</D:T></D:Obor_cinnosti><D:Obor_cinnosti><D:K>Z01047</D:K><D:T>Zprostředkování obchodu a služeb</D:T></D:Obor_cinnosti><D:Obor_cinnosti><D:K>Z01048</D:K><D:T>Velkoobchod a maloobchod</D:T></D:Obor_cinnosti><D:Obor_cinnosti><D:K>Z01056</D:K><D:T>Poskytování software, poradenství v oblasti informačních technologií, zpracování dat, hostingové a související činnosti a webové portály</D:T></D:Obor_cinnosti><D:Obor_cinnosti><D:K>Z01060</D:K><D:T>Poradenská a konzultační činnost, zpracování odborných studií a posudků</D:T></D:Obor_cinnosti><D:Obor_cinnosti><D:K>Z01066</D:K><D:T>Reklamní činnost, marketing, mediální zastoupení</D:T></D:Obor_cinnosti><D:Obor_cinnosti><D:K>Z01080</D:K><D:T>Výroba, obchod a služby jinde nezařazené</D:T></D:Obor_cinnosti></D:Obory_cinnosti></D:VBAS></are:Odpoved></are:Ares_odpovedi>';
      // Create a fake response
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json;charset=UTF-8');
      response.setBody(testBody);

      response.setStatusCode(200);
      return response;
    }

    //Ares_DarvRes_SampleResponse
  }

  public class APCZ03_Ares_CalloutDarvRes_Mock implements HttpCalloutMock {
    //Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      //StaticResource sr = [select Body from StaticResource where Name = 'SRCZ02_AresDarvRes'];
      //String testBody = sr.Body.toString();

      String testBody = '<are:Ares_odpovedi xmlns:are="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer_res/v_1.0.3" xmlns:D="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_datatypes/v_1.0.3" xmlns:U="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/uvis_datatypes/v_1.0.3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" odpoved_datum_cas="2018-11-27T14:55:10" odpoved_pocet="1" odpoved_typ="Vypis_RES" vystup_format="XML" xslt="klient" validation_XSLT="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_odpovedi.xsl" xsi:schemaLocation="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer_res/v_1.0.3 http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer_res/v_1.0.3/ares_answer_res_v_1.0.3.xsd" Id="ares"><are:Odpoved><D:PID>1</D:PID><D:VH><D:K>1</D:K></D:VH><D:PZA>1</D:PZA><D:Vypis_RES><D:UVOD><D:ND>Výpis z registru ekonomických subjektu v ARES</D:ND><D:ADB>2018-11-15</D:ADB><D:DVY>2018-11-27</D:DVY><D:CAS>14:55:10</D:CAS><D:Typ_odkazu>0</D:Typ_odkazu></D:UVOD><D:ZAU><D:ICO>24745391</D:ICO><D:OF>Edenred CZ s.r.o.</D:OF><D:PF><D:KPF>112</D:KPF><D:NPF>Společnost s ručením omezeným</D:NPF></D:PF><D:DV>2010-11-01</D:DV></D:ZAU><D:SI><D:IDA>338076702</D:IDA><D:N>Praha</D:N><D:NCO>Karlín</D:NCO><D:NU>Pernerova</D:NU><D:CD>691</D:CD><D:TCD>1</D:TCD><D:CO>42</D:CO><D:PSC>18600</D:PSC></D:SI><D:ZUJ><D:Zuj_kod_orig>500208</D:Zuj_kod_orig><D:NZUJ>Praha 8</D:NZUJ><D:NUTS4>CZ0100</D:NUTS4><D:Nazev_NUTS4>Praha</D:Nazev_NUTS4></D:ZUJ><D:SU><D:Esa2010>12603</D:Esa2010><D:Esa2010t>Pomocné finanční instituce pod zahraniční kontrolou</D:Esa2010t><D:KPP>100 - 199 zaměstnanců</D:KPP></D:SU><D:Nace><D:NACE>66190</D:NACE><D:Nazev_NACE>Ostatní pomocné činnosti související s finančním zprostředkováním</D:Nazev_NACE></D:Nace><D:Nace><D:NACE>00</D:NACE><D:Nazev_NACE>Výroba, obchod a služby neuvedené v přílohách 1 až 3 živnostenského zákona</D:Nazev_NACE></D:Nace><D:Nace><D:NACE>69200</D:NACE><D:Nazev_NACE>Účetnické a auditorské činnosti; daňové poradenství</D:Nazev_NACE></D:Nace><D:Nace><D:NACE>74</D:NACE><D:Nazev_NACE>Ostatní profesní, vědecké a technické činnosti</D:Nazev_NACE></D:Nace></D:Vypis_RES></are:Odpoved></are:Ares_odpovedi>';
      // Create a fake response
      HttpResponse response = new HttpResponse();

      response.setHeader('Content-Type', 'application/json;charset=UTF-8');
      response.setBody(testBody);

      response.setStatusCode(200);
      return response;
    }
    //Ares_DarvRes_SampleResponse
  }
}