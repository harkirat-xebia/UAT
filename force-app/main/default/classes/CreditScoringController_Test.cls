/**
 * Created by noorgoolamnabee on 13/02/2023.
 */

@IsTest
private class CreditScoringController_Test {
  @IsTest
  static void testAccountFR() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Account acc = APER07_UtilityTestMethod.getCompany('testAccountFR');
      acc.ER_Registration_Number__c = '123446';
      insert acc;

      Test.startTest();

      Test.setMock(HttpCalloutMock.class, new PublicRegister_FR_WS_Mock());

      try {
        CreditScoringController.callCreditScoring(new List<Id>{ acc.Id });
      } catch (Exception e) {
      }

      Test.stopTest();
    }
  }

  @IsTest
  static void testLeadFR() {
    User runningUser = TestDataFactory.newUser('APER12', 'APER12', 'Local Admin', 'FR');
    runningUser.ER_BypassVR__c = true;
    runningUser.ER_Bypass_Flows__c = true;
    runningUser.ER_bypassTrigger__c = true;

    System.runAs(runningUser) {
      Lead ld = APER07_UtilityTestMethod.getLead(
        Utils.getRecordTypeIdByDeveloperName(Lead.SObjectType, 'ER_Merchant_Lead_RT')
      );
      ld.ER_Registration_Number__c = '123446';
      ld.ER_BUPicklist__c = 'FR';
      insert ld;

      Test.startTest();

      String json =
        '{\n' +
        '    "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6ImNZOGpqZXByakZOZDdVS1FrQ08zcVVycDZMNCIsInR5cCI6IkpXVCIsIng1dCI6ImNZOGpqZXByakZOZDdVS1FrQ08zcVVycDZMNCJ9.eyJuYmYiOjE2NzYyNzkzOTEsImV4cCI6MTY3NjI4Mjk5MSwiaXNzIjoiaHR0cHM6Ly9teWxvZ2luLXN0YWdlZC5jcmVkaXRzYWZlLmNvbSIsImF1ZCI6WyJodHRwczovL215bG9naW4tc3RhZ2VkLmNyZWRpdHNhZmUuY29tL3Jlc291cmNlcyIsImNvbm5lY3RfYXBpX3Rlc3QiLCJ1Ym9fYXBpX2dhdGV3YXkiXSwiY2xpZW50X2lkIjoiY29ubmVjdC5hcGkuY2xpZW50Iiwic3ViIjoiMTAxNDg3Nzc2IiwiYXV0aF90aW1lIjoxNjc2Mjc5MzkxLCJpZHAiOiJsb2NhbCIsInVzZXJuYW1lIjoiZWRlbnJlZENvbm5lY3QiLCJlbWFpbCI6IkZhYnJpY2UuUk9VVlJFQVVAZWRlbnJlZC5jb20iLCJjdXN0b21lcklkIjoiMTAxNjc5NzE0IiwiY291bnRyeSI6IkMwIiwidXNlclJvbGUiOiJDdXN0b21lclNlbmlvclVzZXIiLCJ3ZWJSb2xlSWQiOiIxMDAiLCJzYl9jb3VudHJ5IjoiRlIiLCJzY29wZSI6WyJjb25uZWN0X2FwaV90ZXN0IiwidWJvX2FwaV9nYXRld2F5Il0sImFtciI6WyJwd2QiXX0.XubS1RJARSIh5gOA3ynGZqp5QyJaNp4OXmzq67svxWj77f9mQEHuyH0ChLdR4w1TUtkHHqMr6ydZESs-g7mhX0B8thY3GYm47YTgqtu_HE4vTyn1nl0LhCaXz7M5hy8HKZ9q2oPE_y86FCuaaunOmZMSno2RF61HvxeJkQGsHYKyA2wXqvrniTegVCUMJy-EBvBlbztf-lvrrH4qwIF5FL5hC60UxInLMaY4VyBfw13LGyor8TL2wB74F2gJ-clG3NpaNcdbwblLZAIf3KtlrTcEq9AHwiN2TKB8yqzbtuxkYBuiyMnDNMskiuZBezgRy-ZkkHedQ5LPO9PaHnL49Q"\n' +
        '}';

      Test.setMock(HttpCalloutMock.class, new CreditScoring_FR_WS_Mock(json));

      String token = CreditScoringFR.getToken();

      String jsonFirstRes =
        '{' +
        '    \"correlationId\": \"a5e37e07-7bd8-4363-8cba-9926056602ab\",' +
        '    \"totalSize\": 1,' +
        '    \"companies\": [' +
        '        {' +
        '            \"id\": \"FR-X-62204428700788\",' +
        '            \"country\": \"FR\",' +
        '            \"regNo\": \"62204428700788\",' +
        '            \"vatNo\": [' +
        '                \"FR22622044287\"' +
        '            ],' +
        '            \"safeNo\": \"FR17717749\",' +
        '            \"name\": \"MERCEDES-BENZ FRANCE\",' +
        '            \"tradingNames\": [' +
        '                \"MERCEDES-BENZ FRANCE\",' +
        '                \"MERCEDES MERCEDES-BENZ CHRYSLER JEEP CHRYSLER JEEP SMART\"' +
        '            ],' +
        '            \"address\": {' +
        '                \"simpleValue\": \"7 AVENUE NIEPCE, MONTIGNY-LE-BRETONNEUX, 78180\",' +
        '                \"street\": \"7 AVENUE NIEPCE\",' +
        '                \"city\": \"MONTIGNY-LE-BRETONNEUX\",' +
        '                \"postCode\": \"78180\",' +
        '                \"province\": \"ILE DE FRANCE\"' +
        '            },' +
        '            \"status\": \"active\",' +
        '            \"officeType\": \"headOffice\",' +
        '            \"dateOfLatestAccounts\": \"2021-12-31T00:00:00.000000Z\",' +
        '            \"dateOfLatestChange\": \"2022-12-03T11:53:52.000Z\",' +
        '            \"phoneNumbers\": [' +
        '                \"0130058000\"' +
        '            ],' +
        '            \"activityCode\": \"4511Z\",' +
        '            \"legalForm\": \"5710\"' +
        '        }' +
        '    ]' +
        '}';

      Test.setMock(HttpCalloutMock.class, new CreditScoring_FR_WS_Mock(jsonFirstRes));

      CreditScoringFR.searchCompanyByRegistrationNumber('123446', token);

      String jsonSecondCall =
        '{' +
        '  \"correlationId\": \"469efdad-0e94-48b8-aeb5-4806e069598b\",' +
        '  \"report\": {' +
        '    \"companyId\": \"FR-X-62204428700788\",' +
        '    \"language\": \"FR\",' +
        '    \"companySummary\": {' +
        '      \"businessName\": \"MERCEDES-BENZ FRANCE\",' +
        '      \"country\": \"FR\",' +
        '      \"companyNumber\": \"FR17717749\",' +
        '      \"companyRegistrationNumber\": \"62204428700788\",' +
        '      \"mainActivity\": {' +
        '        \"code\": \"4511Z\",' +
        '        \"description\": \"Commerce de voitures et de véhicules automobiles légers\",' +
        '        \"classification\": \"NAF/APE\"' +
        '      },' +
        '      \"companyStatus\": {' +
        '        \"status\": \"Active\",' +
        '        \"providerStatus\": \"Actif\",' +
        '        \"isActive\": true,' +
        '        \"description\": \"Actif économiquement\"' +
        '      },' +
        '      \"latestTurnoverFigure\": {' +
        '        \"currency\": \"EUR\",' +
        '        \"value\": 3425182041' +
        '      },' +
        '      \"latestShareholdersEquityFigure\": {' +
        '        \"currency\": \"EUR\",' +
        '        \"value\": 502711943' +
        '      },' +
        '      \"creditRating\": {' +
        '        \"commonValue\": \"A\",' +
        '        \"commonDescription\": \"Risque Très Faible\",' +
        '        \"creditLimit\": {' +
        '          \"currency\": \"EUR\",' +
        '          \"value\": \"5000000\"' +
        '        },' +
        '        \"providerValue\": {' +
        '          \"maxValue\": \"100\",' +
        '          \"minValue\": \"1\",' +
        '          \"value\": \"100\"' +
        '        },' +
        '        \"providerDescription\": \"Risque très faible\",' +
        '        \"pod\": 0.00025' +
        '      }' +
        '    },' +
        '    \"creditScore\": {' +
        '      \"currentCreditRating\": {' +
        '        \"commonValue\": \"A\",' +
        '        \"commonDescription\": \"Risque Très Faible\",' +
        '        \"creditLimit\": {' +
        '          \"currency\": \"EUR\",' +
        '          \"value\": \"5000000\"' +
        '        },' +
        '        \"providerValue\": {' +
        '          \"maxValue\": \"100\",' +
        '          \"minValue\": \"1\",' +
        '          \"value\": \"100\"' +
        '        },' +
        '        \"providerDescription\": \"Risque très faible\",' +
        '        \"pod\": 0.00025' +
        '      },' +
        '      \"previousCreditRating\": {' +
        '        \"commonValue\": \"A\",' +
        '        \"commonDescription\": \"Risque Très Faible\",' +
        '        \"creditLimit\": {' +
        '          \"currency\": \"EUR\",' +
        '          \"value\": \"5000000\"' +
        '        },' +
        '        \"providerValue\": {' +
        '          \"maxValue\": \"100\",' +
        '          \"minValue\": \"1\",' +
        '          \"value\": \"99\"' +
        '        },' +
        '        \"providerDescription\": \"Risque très faible\",' +
        '        \"pod\": 0.00047' +
        '      },' +
        '      \"latestRatingChangeDate\": \"2022-04-28T00:00:00Z\"' +
        '    }' +
        '  },' +
        '  \"companyId\": \"FR-X-62204428700788\",' +
        '  \"dateOfOrder\": \"2023-02-10T05:10:38.048Z\",' +
        '  \"language\": \"fr\",' +
        '  \"userId\": \"101487776\"' +
        '}';

      Test.setMock(HttpCalloutMock.class, new CreditScoring_FR_WS_Mock(jsonSecondCall));
      String jsonSecondRes = CreditScoringFR.searchCompanyReportById('FR-X-62204428700788', token);

      CreditSafeReport report = CreditSafeReport.parse(jsonSecondRes);

      CreditScoringFR.updateRecords(ld.Id, 'Lead', report);

      try {
        CreditScoringController.callCreditScoring(new List<Id>{ ld.Id });
      } catch (Exception e) {
      }

      Test.stopTest();
    }
  }
}