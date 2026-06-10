/**
 * Created by noorgoolamnabee on 10/01/2023.
 */

public with sharing class ClientOrderServiceOrderLineMock implements HttpCalloutMock {
  public HttpResponse respond(HttpRequest req) {
    String jsonString;
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');

    if (req.getEndpoint().contains('Smarter_MS_AD')) {
      res.setBody(
        '{"token_type":"Bearer","expires_in":3599,"ext_expires_in":3599,"access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIs"}'
      );
      res.setStatusCode(200);
    } else {
      jsonString = getMockJSON();
      res.setBody(jsonString);
      res.setStatusCode(200);
    }

    return res;
  }

  public static String getMockJSON() {
    String json =
      '{' +
      '    \"meta\": {' +
      '        \"paging\": {' +
      '            \"pageIndex\": 0,' +
      '            \"pageSize\": 0,' +
      '            \"totalCount\": 0,' +
      '            \"totalPages\": 0,' +
      '            \"hasPreviousPage\": false,' +
      '            \"hasNextPage\": false' +
      '        },' +
      '        \"status\": \"Succeeded\"' +
      '    },' +
      '    \"data\": [' +
      '        {' +
      '            \"orderItemLineId\": 3369,' +
      '            \"firstName\": \"Thirty Four\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"ThirtyFour.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e990\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1146,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3368,' +
      '            \"firstName\": \"Thirty Three\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"ThirtyThree.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e98f\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1145,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3367,' +
      '            \"firstName\": \"Thirty Two\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"ThirtyTwo.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e98e\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1151,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3366,' +
      '            \"firstName\": \"Thirty One\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"ThirtyOne.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e98d\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1150,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3365,' +
      '            \"firstName\": \"Twenty Ten\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyTen.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e98c\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1152,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3364,' +
      '            \"firstName\": \"Twenty Nine\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyNine.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e98b\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1136,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3363,' +
      '            \"firstName\": \"Twenty Eight\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyEight.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e98a\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1139,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3362,' +
      '            \"firstName\": \"Twenty Seven\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentySeven.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e989\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1137,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3361,' +
      '            \"firstName\": \"Twenty Six\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentySix.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e988\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1134,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3360,' +
      '            \"firstName\": \"Twenty Five\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyFive.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e987\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1149,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3359,' +
      '            \"firstName\": \"Twenty Four\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyFour.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e986\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1147,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3358,' +
      '            \"firstName\": \"Twenty Three\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyThree.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e985\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1148,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3357,' +
      '            \"firstName\": \"Twenty Two\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyTwo.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e984\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1132,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3356,' +
      '            \"firstName\": \"Twenty One\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"TwentyOne.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e983\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1153,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3355,' +
      '            \"firstName\": \"Twenty\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"Twenty.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e982\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1130,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3354,' +
      '            \"firstName\": \"Nineteen\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"Nineteen.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e981\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1142,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3353,' +
      '            \"firstName\": \"Eighteen\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"Eighteen.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e980\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1129,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3352,' +
      '            \"firstName\": \"Seventeen\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"Seventeen.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e97f\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1144,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3351,' +
      '            \"firstName\": \"Sixteen\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"Sixteen.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e97e\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1138,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        },' +
      '        {' +
      '            \"orderItemLineId\": 3350,' +
      '            \"firstName\": \"Fifteen\",' +
      '            \"lastName\": \"Elf\",' +
      '            \"email\": \"Fifteen.Elf@edenred.com\",' +
      '            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '            \"employeeId\": \"63aad9c3f91e27e4cc19e97d\",' +
      '            \"unitCount\": 1,' +
      '            \"unitAmount\": 11.84,' +
      '            \"totalAmount\": 11.84,' +
      '            \"partFinancedByCompany\": 0.60,' +
      '            \"edenredCodeId\": 1135,' +
      '            \"status\": \"waitingForIssuerAccount\"' +
      '        }' +
      '    ]' +
      '}';

    return json;
  }
}