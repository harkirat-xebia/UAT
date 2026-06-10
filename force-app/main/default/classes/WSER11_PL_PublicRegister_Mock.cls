/**
 * Created by noorg on 30/06/2021.
 */

public with sharing class WSER11_PL_PublicRegister_Mock implements HttpCalloutMock {
  public HTTPResponse respond(HTTPRequest req) {
    String jsonString;
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');

    jsonString = getMockJSON();

    res.setBody(jsonString);
    res.setStatusCode(200);
    return res;
  }

  public static String getMockJSON() {
    String response =
      '{\n' +
      '    "status": "done",\n' +
      '    "ident": "8854ccb0-586d-4bdb-8d0d-92d6dfeb0c5b",\n' +
      '    "user_account": null,\n' +
      '    "progress": 100,\n' +
      '    "data": [\n' +
      '        {\n' +
      '            "task_id": 1601259,\n' +
      '            "source": "krs",\n' +
      '            "method": "data",\n' +
      '            "params": {\n' +
      '                "krs": "0000020710",\n' +
      '                "timeout": 300\n' +
      '            },\n' +
      '            "meta": null,\n' +
      '            "result": {\n' +
      '                "data_acquisition_date": "2021-06-10",\n' +
      '                "name": "CARREFOUR POLSKA SPÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚCIĄ",\n' +
      '                "legal_form": "SPÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚCIĄ",\n' +
      '                "krs": "0000020710",\n' +
      '                "nip": "9370008168",\n' +
      '                "regon": "070569406",\n' +
      '                "company_status": "Aktywny",\n' +
      '                "address": {\n' +
      '                    "street": "ul. TARGOWA",\n' +
      '                    "number": "72",\n' +
      '                    "local": null,\n' +
      '                    "postcode": "03-734",\n' +
      '                    "post": "WARSZAWA",\n' +
      '                    "city": "WARSZAWA",\n' +
      '                    "county": "M.ST. WARSZAWA",\n' +
      '                    "region": "MAZOWIECKIE",\n' +
      '                    "country": "POLSKA"\n' +
      '                },\n' +
      '                "equity": "1970719050.00",\n' +
      '                "stock": {\n' +
      '                    "quantity": null,\n' +
      '                    "value": null\n' +
      '                },\n' +
      '                "incorporation": "2001-07-18",\n' +
      '                "created_at": "1995-07-06",\n' +
      '                "last_registry_update": "2020-10-09",\n' +
      '                "removed_at": null,\n' +
      '                "opp": false,\n' +
      '                "opp_start": null,\n' +
      '                "pkd": "4711Z",\n' +
      '                "representation": "DO REPREZENTOWANIA SPÓŁKI UPRAWNIENI SĄ PREZES I WICEPREZESI ZARZĄDU, KAŻDY Z NICH\\nJEDNOOSOBOWO, POZOSTALI CZŁONKOWIE ZARZĄDU ŁĄCZNIE Z PREZESEM LUB WICEPREZESEM\\nZARZĄDU",\n' +
      '                "representation_body": "ZARZĄD SPÓŁKI",\n' +
      '                "supervisory_authority": null,\n' +
      '                "in_bankruptcy": false,\n' +
      '                "liquidation_start": null,\n' +
      '                "liquidation_end": null,\n' +
      '                "liquidation_representation": null,\n' +
      '                "court": {\n' +
      '                    "name": "SĄD REJONOWY DLA M. ST. WARSZAWY W WARSZAWIE, XIV WYDZIAŁ GOSPODARCZY KRAJOWEGO REJESTRU SĄDOWEGO",\n' +
      '                    "ident": "WA.XIV NS-REJ.KRS/32908/20/282"\n' +
      '                },\n' +
      '                "www": "",\n' +
      '                "email": "",\n' +
      '                "relation": [\n' +
      '                    {\n' +
      '                        "name": "CARREFOUR NEDERLAND B.V.",\n' +
      '                        "first_name": "CARREFOUR NEDERLAND B.V.",\n' +
      '                        "last_name": "",\n' +
      '                        "relation": "shareholder",\n' +
      '                        "relation_extra_info": "19.320.775 UDZIAŁÓW O ŁĄCZNEJ WARTOŚCI 1.970.719.050 ZŁ",\n' +
      '                        "shares": {\n' +
      '                            "quantity": "19320775.00",\n' +
      '                            "value": "1970719050.00"\n' +
      '                        },\n' +
      '                        "ident": {\n' +
      '                            "name": "other",\n' +
      '                            "value": "carrefournederland"\n' +
      '                        }\n' +
      '                    },\n' +
      '                    {\n' +
      '                        "name": "TARECK OUAIBI",\n' +
      '                        "first_name": "TARECK",\n' +
      '                        "last_name": "OUAIBI",\n' +
      '                        "relation": "board_member",\n' +
      '                        "relation_extra_info": "WICEPREZES ZARZĄDU",\n' +
      '                        "ident": {\n' +
      '                            "name": "pesel",\n' +
      '                            "value": "67021816115"\n' +
      '                        }\n' +
      '                    },\n' +
      '                    {\n' +
      '                        "name": "JUSTYNA IZABELA ORZEŁ",\n' +
      '                        "first_name": "JUSTYNA IZABELA",\n' +
      '                        "last_name": "ORZEŁ",\n' +
      '                        "relation": "board_member",\n' +
      '                        "relation_extra_info": "WICEPREZES ZARZĄDU",\n' +
      '                        "ident": {\n' +
      '                            "name": "pesel",\n' +
      '                            "value": "71051001081"\n' +
      '                        }\n' +
      '                    },\n' +
      '                    {\n' +
      '                        "name": "MICHAŁ WITOLD SACHA",\n' +
      '                        "first_name": "MICHAŁ WITOLD",\n' +
      '                        "last_name": "SACHA",\n' +
      '                        "relation": "board_member",\n' +
      '                        "relation_extra_info": "CZŁONEK ZARZĄDU",\n' +
      '                        "ident": {\n' +
      '                            "name": "pesel",\n' +
      '                            "value": "76041114132"\n' +
      '                        }\n' +
      '                    },\n' +
      '                    {\n' +
      '                        "name": "MAREK LIPKA",\n' +
      '                        "first_name": "MAREK",\n' +
      '                        "last_name": "LIPKA",\n' +
      '                        "relation": "board_member",\n' +
      '                        "relation_extra_info": "CZŁONEK ZARZĄDU",\n' +
      '                        "ident": {\n' +
      '                            "name": "pesel",\n' +
      '                            "value": "76010904171"\n' +
      '                        }\n' +
      '                    },\n' +
      '                    {\n' +
      '                        "name": "JEANFRANÇOIS FRÉDÉRIC P. DOHOGNE",\n' +
      '                        "first_name": "JEANFRANÇOIS FRÉDÉRIC P.",\n' +
      '                        "last_name": "DOHOGNE",\n' +
      '                        "relation": "board_member",\n' +
      '                        "relation_extra_info": "WICEPREZES ZARZĄDU",\n' +
      '                        "ident": {\n' +
      '                            "name": "pesel",\n' +
      '                            "value": "80090120233"\n' +
      '                        }\n' +
      '                    }\n' +
      '                ],\n' +
      '                "debts": []\n' +
      '            }\n' +
      '        }\n' +
      '    ]\n' +
      '}';
    return response;
  }
}