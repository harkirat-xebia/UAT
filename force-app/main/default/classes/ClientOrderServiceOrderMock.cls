/**
 * Created by noorgoolamnabee on 10/01/2023.
 */

public with sharing class ClientOrderServiceOrderMock implements HttpCalloutMock {
  public string type;

  public ClientOrderServiceOrderMock(String type) {
    this.type = type;
  }

  public HttpResponse respond(HttpRequest param1) {
    String jsonString;
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setStatusCode(200);
    if (param1.getEndpoint().contains('Smarter_MS_AD')) {
      // Mock the token call :
      jsonString = '{"token_type":"Bearer","expires_in":3599,"ext_expires_in":3599,"access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIs"}';
    } else if (type.equals(Constants.EMPLOYEE)) {
      jsonString = getMockJSONEmployee();
    } else if (type.equals(Constants.ACCOUNT)) {
      jsonString = getMockJSON();
    } else if (type.equals(Constants.SMARTER_WEBSERVICE_PROCESSING_EVENTS)) {
      jsonString = getMockProcessingEventJSON();
    } else if (type.equals(Constants.SMARTER_CANCEL_ORDER)) {
      jsonString = '';
      res.setStatusCode(204);
    } else {
      jsonString = getOrderLoadJSON();
    }

    res.setBody(jsonString);

    return res;
  }

  public static String getMockProcessingEventJSON() {
    String json =
      '{' +
      '    \"data\": [' +
      '        {' +
      '            \"orderProcessingEventId\": 50815,' +
      '            \"processingEvent\": \"callToSubmit\",' +
      '            \"finalOrderState\": \"toBeValidated\",' +
      '            \"createdDate\": \"2023-07-14T13:18:49.6871064+00:00\",' +
      '            \"createdBy\": \"SmartERuser\"' +
      '        },' +
      '        {' +
      '            \"orderProcessingEventId\": 50816,' +
      '            \"processingEvent\": \"businessValidation\",' +
      '            \"finalOrderState\": \"validated\",' +
      '            \"createdDate\": \"2023-07-14T13:18:49.8430884+00:00\",' +
      '            \"createdBy\": \"SmartERuser\"' +
      '        },' +
      '        {' +
      '            \"orderProcessingEventId\": 50817,' +
      '            \"processingEvent\": \"callToBilling\",' +
      '            \"finalOrderState\": \"waitingForFinancialValidation\",' +
      '            \"createdDate\": \"2023-07-14T13:18:53.2853851+00:00\",' +
      '            \"createdBy\": \"SmartERuser\"' +
      '        },' +
      '        {' +
      '            \"orderProcessingEventId\": 50818,' +
      '            \"processingEvent\": \"financialValidation\",' +
      '            \"finalOrderState\": \"financiallyValidated\",' +
      '            \"createdDate\": \"2023-07-14T13:36:47.6143587+00:00\",' +
      '            \"createdBy\": \"SmartERuser\"' +
      '        },' +
      '{' +
      '            \"orderProcessingEventId\": 50819,' +
      '            \"processingEvent\": \"releasePreparation\",' +
      '            \"finalOrderState\": \"readyForRelease\",' +
      '            \"createdDate\": \"2023-07-14T13:36:47.7003539+00:00\",' +
      '            \"createdBy\": \"SmartERuser\"' +
      '        },' +
      '        {' +
      '            \"orderProcessingEventId\": 50833,' +
      '            \"processingEvent\": \"releaseStarted\",' +
      '            \"finalOrderState\": \"releaseInProgress\",' +
      '            \"createdDate\": \"2023-07-17T00:00:14.5227529+00:00\",' +
      '            \"createdBy\": \"SmartERuser\"' +
      '        },' +
      '        {' +
      '            \"orderProcessingEventId\": 50834,' +
      '            \"processingEvent\": \"releaseFinalized\",' +
      '            \"finalOrderState\": \"released\",' +
      '            \"createdDate\": \"2023-07-17T00:00:51.5489895+00:00\",' +
      '            \"createdBy\": \"SmartERuser\"' +
      '        }' +
      '    ],' +
      '    \"meta\": {' +
      '        \"status\": \"Succeeded\"' +
      '    }' +
      '}';

    return json;
  }

  public static String getOrderLoadJSON() {
    String json =
      '{' +
      '  \"meta\": {' +
      '    \"paging\": {' +
      '      \"pageIndex\": 0,' +
      '      \"pageSize\": 200,' +
      '      \"totalCount\": 24,' +
      '      \"totalPages\": 1,' +
      '      \"hasPreviousPage\": false,' +
      '      \"hasNextPage\": true' +
      '    },' +
      '    \"status\": \"Succeeded\"' +
      '  },' +
      '  \"data\": [' +
      '{' +
      '      \"loadId\": 9051,' +
      '      \"internalReference\": \"FR230026015_102884\",' +
      '      \"issuerAccountNumber\": \"91600100100129\",' +
      '      \"wallet\": \"walletOne\",' +
      '      \"amount\": 1.00,' +
      '      \"expiryDate\": \"2024-02-29T00:00:00\",' +
      '      \"payerName\": \"GARAGE\",' +
      '      \"priority\": 2,' +
      '      \"source\": \"order\",' +
      '      \"orderItemLineId\": 102884,' +
      '      \"employeeId\": \"642ab1e24c29672c03f285b5\",' +
      '      \"orderItemId\": 13993,' +
      '      \"benefitId\": 1,' +
      '      \"orderId\": 13768,' +
      '      \"orderNumber\": \"EFR230026015\",' +
      '      \"clientId\": \"63f768a392478ebf36bec588\",' +
      '      \"timeLimitedLoadId\": \"230613081227372215\",' +
      '      \"loadTransactionId\": \"23061308122727223\",' +
      '      \"status\": \"executedSuccessfully\",' +
      '      \"createdDate\": \"2023-06-13T07:12:22.4074645+00:00\",' +
      '      \"createdBy\": \"camunda\",' +
      '      \"lastModifiedDate\": \"2023-06-13T07:12:27.638114+00:00\",' +
      '      \"lastModifiedBy\": \"bulkLoad\"' +
      '    },' +
      '    {' +
      '      \"loadId\": 9050,' +
      '      \"internalReference\": \"FR230026015_102883\",' +
      '      \"issuerAccountNumber\": \"91600100100160\",' +
      '      \"wallet\": \"walletOne\",' +
      '      \"amount\": 1.00,' +
      '      \"expiryDate\": \"2024-02-29T00:00:00\",' +
      '      \"payerName\": \"GARAGE\",' +
      '      \"priority\": 2,' +
      '      \"source\": \"order\",' +
      '      \"orderItemLineId\": 102883,' +
      '      \"employeeId\": \"642addcb4c29672c03f28640\",' +
      '      \"orderItemId\": 13993,' +
      '      \"benefitId\": 1,' +
      '      \"orderId\": 13768,' +
      '      \"orderNumber\": \"EFR230026015\",' +
      '      \"clientId\": \"63f768a392478ebf36bec588\",' +
      '      \"timeLimitedLoadId\": \"230613081227372214\",' +
      '      \"loadTransactionId\": \"23061308122727222\",' +
      '      \"status\": \"executedSuccessfully\",' +
      '      \"createdDate\": \"2023-06-13T07:12:22.3243947+00:00\",' +
      '      \"createdBy\": \"camunda\",' +
      '      \"lastModifiedDate\": \"2023-06-13T07:12:27.6461911+00:00\",' +
      '      \"lastModifiedBy\": \"bulkLoad\"' +
      '    }' +
      '  ]' +
      '}';
    return json;
  }

  public static String getMockJSONEmployee() {
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
      '            \"orderId\": 2201,' +
      '            \"orderNumber\": \"EFR230003439\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderCreationDateTime\": \"2023-01-19T22:01:39.0829359+00:00\",' +
      '            \"orderSubmissionDate\": \"2023-01-19\",' +
      '            \"createdbyContactId\": 192,' +
      '            \"status\": \"released\",' +
      '            \"state\": \"released\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 2385,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2023-01-19T00:00:00\",' +
      '                    \"status\": \"released\",' +
      '                    \"orderItemLines\": [' +
      '                        {' +
      '                            \"orderItemLineId\": 6646,' +
      '                            \"firstName\": \"Four\",' +
      '                            \"lastName\": \"Enabler\",' +
      '                            \"email\": \"Four.enabler@yopmail.com\",' +
      '                            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '                            \"employeeId\": \"63c8e5fe8e33196d093b5c13\",' +
      '                            \"unitCount\": 20,' +
      '                            \"unitAmount\": 11.84,' +
      '                            \"totalAmount\": 236.80,' +
      '                            \"partFinancedByCompany\": 0.60,' +
      '                            \"edenredCodeId\": 2129,' +
      '                            \"status\": \"waitingForIssuerAccount\"' +
      '                        }' +
      '                    ]' +
      '                }' +
      '            ]' +
      '        },' +
      '{' +
      '            \"orderId\": 2177,' +
      '            \"orderNumber\": \"EFR230003241\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderCreationDateTime\": \"2023-01-19T06:42:13.0648549+00:00\",' +
      '            \"orderSubmissionDate\": \"2023-01-19\",' +
      '            \"createdbyContactId\": 192,' +
      '            \"status\": \"released\",' +
      '            \"state\": \"released\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 2358,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2023-01-19T00:00:00\",' +
      '                    \"status\": \"released\",' +
      '                    \"orderItemLines\": [' +
      '                        {' +
      '                            \"orderItemLineId\": 6356,' +
      '                            \"firstName\": \"Four\",' +
      '                            \"lastName\": \"Enabler\",' +
      '                            \"email\": \"Four.enabler@yopmail.com\",' +
      '                            \"birthDate\": \"1990-09-10T00:00:00\",' +
      '                            \"employeeId\": \"63c8e5fe8e33196d093b5c13\",' +
      '                            \"unitCount\": 1,' +
      '                            \"unitAmount\": 11.84,' +
      '                            \"totalAmount\": 11.84,' +
      '                            \"partFinancedByCompany\": 0.60,' +
      '                            \"edenredCodeId\": 2129,' +
      '                            \"status\": \"waitingForIssuerAccount\"' +
      '                        }' +
      '                    ]' +
      '                }' +
      '            ]' +
      '        }' +
      '    ]' +
      '}';

    return json;
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
      '            \"orderId\": 1192,' +
      '            \"orderNumber\": \"EFR230000686\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2023-01-04T12:49:48.8379942+00:00\",' +
      '            \"orderSubmissionDate\": \"2023-01-04\",' +
      '            \"totalLoadAmount\": 402.56,' +
      '            \"itemLineCount\": 34,' +
      '            \"distinctEmployeeCount\": 34,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"status\": \"waitingForFinancialValidation\",' +
      '            \"state\": \"waitingForFinancialValidation\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 1358,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2023-01-04T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 402.56,' +
      '                    \"itemLineCount\": 34,' +
      '                    \"status\": \"validated\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 1177,' +
      '            \"orderNumber\": \"EFR230000592\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2023-01-04T06:03:49.5602097+00:00\",' +
      '            \"orderSubmissionDate\": \"2023-01-04\",' +
      '            \"totalLoadAmount\": 402.56,' +
      '            \"itemLineCount\": 34,' +
      '            \"distinctEmployeeCount\": 34,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"status\": \"submissionInError\",' +
      '            \"state\": \"submissionInError\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 1336,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2023-01-04T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 402.56,' +
      '                    \"itemLineCount\": 34,' +
      '                    \"status\": \"validated\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 818,' +
      '            \"orderNumber\": \"EFR220005871\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2022-12-30T06:54:22.8876893+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-30\",' +
      '            \"totalLoadAmount\": 23.68,' +
      '            \"itemLineCount\": 2,' +
      '            \"distinctEmployeeCount\": 2,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-30T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-30T00:00:00+00:00\",' +
      '            \"status\": \"released\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 975,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-30T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 23.68,' +
      '                    \"itemLineCount\": 2,' +
      '                    \"status\": \"released\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 800,' +
      '            \"orderNumber\": \"EFR220005648\",' +
      '            \"purchaseOrderReference\": \"Bulk load\",' +
      '            \"orderChannel\": \"externalApi\",' +
      '            \"orderCreationDateTime\": \"2022-12-28T12:20:00.912+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-09\",' +
      '            \"totalLoadAmount\": 592.00,' +
      '            \"itemLineCount\": 50,' +
      '            \"distinctEmployeeCount\": 50,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-28T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-28T00:00:00+00:00\",' +
      '            \"status\": \"released\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 953,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-28T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 592.00,' +
      '                    \"itemLineCount\": 50,' +
      '                    \"status\": \"released\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 804,' +
      '            \"orderNumber\": \"EFR220005661\",' +
      '            \"purchaseOrderReference\": \"Bulk load\",' +
      '            \"orderChannel\": \"externalApi\",' +
      '            \"orderCreationDateTime\": \"2022-12-28T12:20:00.912+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-28\",' +
      '            \"totalLoadAmount\": 592.00,' +
      '            \"itemLineCount\": 50,' +
      '            \"distinctEmployeeCount\": 50,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-28T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-28T00:00:00+00:00\",' +
      '            \"status\": \"released\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 957,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-28T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 592.00,' +
      '                    \"itemLineCount\": 50,' +
      '                    \"status\": \"released\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 1316,' +
      '            \"orderNumber\": \"EFR230000871\",' +
      '            \"purchaseOrderReference\": \"Bulk load\",' +
      '            \"orderChannel\": \"externalApi\",' +
      '            \"orderCreationDateTime\": \"2022-12-28T12:20:00.912+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-28\",' +
      '            \"totalLoadAmount\": 592.00,' +
      '            \"itemLineCount\": 50,' +
      '            \"distinctEmployeeCount\": 50,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2023-01-05T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2023-01-05T00:00:00+00:00\",' +
      '            \"status\": \"releaseInProgress\",' +
      '            \"state\": \"releaseInProgress\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 1485,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2023-01-05T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 592.00,' +
      '                    \"itemLineCount\": 50,' +
      '                    \"status\": \"releaseInProgress\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 789,' +
      '            \"orderNumber\": \"EFR220005590\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2022-12-27T12:42:57.1704947+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-27\",' +
      '            \"totalLoadAmount\": 402.56,' +
      '            \"itemLineCount\": 34,' +
      '            \"distinctEmployeeCount\": 34,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"status\": \"released\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 939,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-27T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 402.56,' +
      '                    \"itemLineCount\": 34,' +
      '                    \"status\": \"released\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 788,' +
      '            \"orderNumber\": \"EFR220005579\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2022-12-27T12:23:20.02216+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-27\",' +
      '            \"totalLoadAmount\": 236.80,' +
      '            \"itemLineCount\": 1,' +
      '            \"distinctEmployeeCount\": 1,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"status\": \"submissionInError\",' +
      '            \"state\": \"validated\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 938,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-27T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 236.80,' +
      '                    \"itemLineCount\": 1,' +
      '                    \"status\": \"validated\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 787,' +
      '            \"orderNumber\": \"EFR220005577\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2022-12-27T12:14:30.1225216+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-27\",' +
      '            \"totalLoadAmount\": 11.84,' +
      '            \"itemLineCount\": 1,' +
      '            \"distinctEmployeeCount\": 1,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"status\": \"readyForRelease\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 937,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-27T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 11.84,' +
      '                    \"itemLineCount\": 1,' +
      '                    \"status\": \"readyForRelease\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 786,' +
      '            \"orderNumber\": \"EFR220005576\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2022-12-27T12:08:32.6491388+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-27\",' +
      '            \"totalLoadAmount\": 236.80,' +
      '            \"itemLineCount\": 1,' +
      '            \"distinctEmployeeCount\": 1,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"status\": \"released\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 936,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-27T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 236.80,' +
      '                    \"itemLineCount\": 1,' +
      '                    \"status\": \"released\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 785,' +
      '            \"orderNumber\": \"EFR220005575\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2022-12-27T11:58:54.8727544+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-27\",' +
      '            \"totalLoadAmount\": 402.56,' +
      '            \"itemLineCount\": 34,' +
      '            \"distinctEmployeeCount\": 34,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"status\": \"released\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 935,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-27T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 402.56,' +
      '                    \"itemLineCount\": 34,' +
      '                    \"status\": \"released\"' +
      '                }' +
      '            ]' +
      '        },' +
      '        {' +
      '            \"orderId\": 783,' +
      '            \"orderNumber\": \"EFR220005572\",' +
      '            \"purchaseOrderReference\": \"\",' +
      '            \"orderChannel\": \"web\",' +
      '            \"orderCreationDateTime\": \"2022-12-27T11:41:19.7952451+00:00\",' +
      '            \"orderSubmissionDate\": \"2022-12-27\",' +
      '            \"totalLoadAmount\": 402.56,' +
      '            \"itemLineCount\": 34,' +
      '            \"distinctEmployeeCount\": 34,' +
      '            \"createdbyContactId\": 192,' +
      '            \"clientId\": \"63aad93da85a83721f55d37c\",' +
      '            \"billingAccountNumber\": \"AFR00019029\",' +
      '            \"selectedPaymentMean\": \"wireTransfer\",' +
      '            \"hasBusinessValidationErrors\": false,' +
      '            \"financialValidationDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"financialValidationType\": \"manual\",' +
      '            \"firstInvoiceDate\": \"2022-12-27T00:00:00+00:00\",' +
      '            \"status\": \"released\",' +
      '            \"state\": \"readyForRelease\",' +
      '            \"orderItems\": [' +
      '                {' +
      '                    \"orderItemId\": 933,' +
      '                    \"benefitId\": 1,' +
      '                    \"preferredLoadDate\": \"2022-12-27T00:00:00\",' +
      '                    \"productClassFamilyId\": 1,' +
      '                    \"totalLoadAmount\": 402.56,' +
      '                    \"itemLineCount\": 34,' +
      '                    \"status\": \"released\"' +
      '                }' +
      '            ]' +
      '        }' +
      '    ]' +
      '}';

    return json;
  }
}