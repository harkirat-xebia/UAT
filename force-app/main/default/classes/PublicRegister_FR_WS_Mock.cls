/**
 * Created by noorgoolamnabee on 23/12/2022.
 */

public with sharing class PublicRegister_FR_WS_Mock implements HttpCalloutMock {
  public HttpResponse respond(HttpRequest param1) {
    String jsonString;
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');

    jsonString = getMockJSON();

    res.setBody(jsonString);
    res.setStatusCode(200);
    return res;
  }

  public static String getMockJSON() {
    String json =
      '{' +
      '    \"societes\": [' +
      '        {' +
      '            \"adresse1\": \"\",' +
      '            \"adresse2\": \"7 PL D IENA\",' +
      '            \"adresse3\": \"\",' +
      '            \"categorieJuridique\": \"5499\",' +
      '            \"codePostal\": \"75116\",' +
      '            \"dateDeCreation\": \"1981-10-01T00:00:00\",' +
      '            \"libelleCodeJuridique\": \"\",' +
      '            \"libelleNaf08\": \"\",' +
      '            \"naf08\": \"7311Z\",' +
      '            \"nic\": \"00208\",' +
      '            \"nom\": \"APPLE FRANCE\",' +
      '            \"siren\": \"322120916\",' +
      '            \"trancheEffective\": \"200 - 249\",' +
      '            \"ville\": \"PARIS 16\",' +
      '            \"siretActif\": \"oui\",' +
      '            \"maxScore\": 100.0,' +
      '            \"score\": 100.0,' +
      '            \"statutDiffusion\": \"O\",' +
      '            \"enseigne\": \"\",' +
      '            \"nomCommercial\": null,' +
      '            \"numeroTVA\": \"FR66322120916\"' +
      '        }' +
      '    ]' +
      '}';

    return json;
  }
}