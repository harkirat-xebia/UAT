/**
 * @author: ALK
 * @date: 18/10/2022
 * @desc: SmarterAPIMock
 * @see: SmarterAPIMock
 */

 public with sharing class SmarterAPIMock implements HttpCalloutMock {
    public static HttpResponse res = new HttpResponse();
    public static String serviceToFail {set; get;}

    public static HttpResponse respond(HttpRequest req) {
        String jsonString;
        res.setHeader('Content-Type', 'application/json');
        
        System.debug('>>>>> AAZ SmarterAPIMock -  req.getEndpoint(): ' + req.getEndpoint());

        if(req.getEndpoint().endsWith('push-back-ids')) {
            jsonString = '{"data":[{"leadOneforceId":"00Q5r000002yKYbEAM","oneforceAccountOneforceId":"0015r00000cGdAxAAK","contactOneforceId":"0035r00000TMpGcAAL","financialCenterOneforceId":"a055r000003R9d3AAC","opportunityOneforceId":"0065r000005vwHpAAI","billingAccountNumber":"AFR00018427"}]}';
            res.setBody(jsonString);
            res.setStatusCode(204);
        } else if(req.getEndpoint().contains(Constants.SMARTER_GET_TCs_SERVICE_NAME)) {
            if(serviceToFail == null || serviceToFail != Constants.SMARTER_GET_TCs_SERVICE_NAME) {
                res.setBody('{"data": {"version": "20220130","noticeType": "termsOfSale","fileUrl": "https://assets.ctfassets.net/emupgefw7b1n/5rr/TCs.pdf","language": "fr"},"meta":{"status": "Succeeded"}}');
                res.setStatusCode(200);
            } else if(serviceToFail == Constants.SMARTER_GET_TCs_SERVICE_NAME) {
                res.setBody('{"meta": {"messages":[{"code": "CMS_ERROR","text": "ASSERT ERROR MESSAGE","level":"Error","traceId":"3729291103750323818"}],"status":"Failed"}}');
                res.setStatusCode(500);
            }
        } else if(req.getEndpoint().contains('xp-oneforce-api')) {
            res.setBody('VBERi0xLjQKJdPr6eEKMSAwIG9iago8PC9DcmVhdG9yIChDaHJvbWl1bSkKL1Byb2R1Y');
            res.setStatusCode(200);
        } else if(req.getEndpoint().contains('issuer-accounts')) {
            jsonString = '{"data":{"accountNumber":"91600100001418","productClassCode":"SRN_ERFR_MB1_EUR_1","accountProfile":"DEFAULT_SRN_ERFR_MB1_EUR","accountholderId":"2228148b-4f8c-4a56-9483-81217ff0be5e","status":"ACTIVE","wallets":[{"type":"PREPAID","name":"walletOne","availableBalance":632.25,"clearedBalance":632.25,"pendingCredit":0,"pendingDebit":0,"currencyCode":"EUR","status":"ACTIVE"},{"type":"PREPAID","name":"walletTwo","availableBalance":0,"clearedBalance":0,"pendingCredit":0,"pendingDebit":0,"currencyCode":"EUR","status":"INACTIVE"},{"type":"PREPAID","name":"walletThree","availableBalance":0,"clearedBalance":0,"pendingCredit":0,"pendingDebit":0,"currencyCode":"EUR","status":"INACTIVE"}]},"meta":{"status":"Succeeded"}}';
            res.setBody(jsonString);
            res.setStatusCode(200);
        } else if(req.getEndpoint().contains(Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_SERVICE_NAME)) {
            if(serviceToFail == Constants.SMARTER_PUSH_BACK_FINANCIAL_CENTER_SERVICE_NAME) {
                jsonString = '{ "meta": { "messages": [ { "code": "ERROR_CODE", "text": "SYNC IN ERROR", "level": "0:Info", "traceId": "234324DFREF" } ], "status": "0:Succeeded" } }';
                res.setBody(jsonString);
                res.setStatusCode(400);
            } else {
                //jsonString = '[{"id": "a055r000003TGarAAG","invoicingStreet": "6 RUE JOLIOT CURIE","invoicingCity": "THOUROTTE","invoicingZipCode": "60150","invoicingCountry": "France","invoicingCountryCode":"FR","isMaster": true}]';
                //res.setBody(jsonString);
                res.setStatusCode(204);
            }
        }  else if(req.getEndpoint().contains(Constants.GET_IA_TRANSACTIONS_SERVICE_NAME)) {
            jsonString = '{"meta":{"paging":{"pageIndex":0,"pageSize":100,"totalCount":100,"totalPages":1,"hasPreviousPage":false,"hasNextPage":true},"status":"Succeeded"},"data":[{"transactionId":"22110813554723520","schemeId":"PPS_BATCH","payer":{"locationName":"MY NEW EMPLOYER"},"payee":{"accountNumber":"91600100001418","walletId":"walletOne"},"transactionType":"TOPUP","direction":"CREDIT","lifecycleStatus":"COMPLETE","result":"APPROVED","resultDetail":"SUCCESSFUL","createdDatetime":"2022-11-08T13:55:47","completedDatetime":"2022-11-08T13:55:47","authorizationDatetime":"2022-11-08T13:55:47","authorizationLocalDatetime":"2022-11-08T13:55:47","authorizedAmount":237.2,"clearedAmount":0,"currencyCode":"EUR","acceptanceMethod":"UNKNOWN","isReversal":false}]}';
            res.setBody(jsonString);
            res.setStatusCode(200);
        } else if(req.getEndpoint().contains('assets.ctfassets.net/emupgefw7b1n/5rr')) {
            return res;
        } else if(req.getEndpoint().contains(Constants.SMARTER_GET_CARD_SERVICE_NAME)) {
            res.setBody('{"data": {"currentStatus": "ISSUED","updatedDatetime": "2023-03-09T10:16:06.118951"},"meta": {"status": "Succeeded"}}');
            res.setStatusCode(200);

        } else if(req.getEndpoint().contains('/v1/edenred-codes?employee-id=')) {
            res.setBody('{"data": [{"edenredCodeId": 2129,"productClassFamilyId": 1,"isProvisioned": false,"isSent": true,"lastNotificationDateTime": "2023-03-13T18:57:45.0067741+00:00"}],"meta":{"status": "Succeeded"}}');
            res.setStatusCode(200);

        } else if(req.getEndpoint().contains('/v1/edenred-codes/')) {
            res.setBody('{"meta": {"status": "Succeeded"}}');
            res.setStatusCode(200);
        } else if(req.getEndpoint().contains(Constants.SMARTER_ACCOUNT_REF_SERVICE_NAME)) {
            if(serviceToFail == Constants.SMARTER_ACCOUNT_REF_SERVICE_NAME) {
                jsonString = '{ "meta": { "messages": [ { "code": "ERROR_CODE", "text": "SYNC IN ERROR", "level": "0:Info", "traceId": "234324DFREF" } ], "status": "Failed" } }';
                res.setBody(jsonString);
                res.setStatusCode(400);
            } else {
                res.setStatusCode(200);
            }
        } else if(req.getEndpoint().contains(Constants.SMARTER_OFFLINE_TCS_SERVICE_NAME)) {
            res.setStatusCode(204);
        } else if(req.getEndpoint().contains('Smarter_MS_AD') || req.getEndpoint().contains(Constants.SMARTER_MS_AD_NAMED_CREDENTIAL)) {
            res.setBody('{"token_type":"Bearer","expires_in":3599,"ext_expires_in":3599,"access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIs"}');
            res.setStatusCode(200);
        } else if (req.getEndpoint().contains(Constants.SMARTER_PROFORMA_SERVICE_NAME)) {
            res.setBody('VBERi0xLjQKJdPr6eEKMSAwIG9iago8PC9DcmVhdG9yIChDaHJvbWl1bSkKL1Byb2R1Y');
            res.setStatusCode(200);
        } else if(req.getEndpoint().endsWith('oauth/token') || req.getEndpoint().endsWith('oauth/token/')) {
            jsonString = '{"access_token":"47efd258cecc49578b5d569e3963e3a8","token_type":"bearer","expires_in":3598,"scope":"entity.8adc8f99-77f2-67df-0177-f7762a022cdd entity.8adc9dee-78ef-3458-0178-f02508a62960 entity.8adce421-6daf-d3bc-016d-afe8e470079b platform.write service.events.read service.events.write service.notifications.read service.notifications.write service.usage.delete service.usage.update service.usage.write tenant.2000534 user.8adc9dee78ef34580178ef8fda863f32","jti":"47efd258cecc49578b5d569e3963e3a8"}';
        } else if(req.getEndpoint().contains(Constants.SMARTER_SEND_ONBOARDING_SERVICE_NAME)) {
            if(serviceToFail == Constants.SMARTER_SEND_ONBOARDING_SERVICE_NAME) {
                jsonString = '{"meta":{"messages":[{"code":"ERROR_CODE","text":"SYNC ERROR","level":"0:Info","traceId":"' + Datetime.now().getTime() + '"}],"status":"0:Succeeded"}}';
                res.setBody(jsonString);
                res.setStatusCode(400);
            } else {
                res.setStatusCode(204);
            }
        } else if(req.getEndpoint().contains(Constants.SMARTER_CONTACTS_SERVICE_NAME)) {
            if(serviceToFail == null || serviceToFail != Constants.SMARTER_CONTACTS_SERVICE_NAME) {
                res.setBody('[{"contactOneforceId":"String","clientId":"string","firstName":"{{$randomFileName}}","lastName":"{{$randomLastName}}","email":"{{$randomExampleEmail}}","phone":"{{$randomPhoneNumber}}","language":"FR"}]');
                res.setStatusCode(204);
            } else if(serviceToFail == Constants.SMARTER_CONTACTS_SERVICE_NAME) {
                res.setBody('{"meta":{"messages":[{"code":"NotEmptyValidator","text":"\'Contact Oneforce Id\' must not be empty.","level":"Error","traceId":"2406276572935644404"}],"status":"Failed"}}');
                res.setStatusCode(400);
            }
        } else if(req.getEndpoint().contains(Constants.SMARTER_SYNC_LOOP_MERCHANT_GROUP_SERVICE_NAME)) {
            if(serviceToFail == null || serviceToFail != Constants.SMARTER_SYNC_LOOP_MERCHANT_GROUP_SERVICE_NAME) {
                res.setBody('{"data": {"storeGroupId": "a0A5r000000jgYjEA"},"meta": {"status": "Succeeded"}');
                res.setStatusCode(200);
            } else if(serviceToFail == Constants.SMARTER_SYNC_LOOP_MERCHANT_GROUP_SERVICE_NAME) {
                res.setBody('{"meta":{"messages":[{"code":"BAD_REQUEST","text":"Resource with the given id already exists: ","level":"Error","traceId":"1466258435923864792"}],"status":"Failed"}}');
                res.setStatusCode(400);
            }
        } else if(req.getEndpoint().endsWith(Constants.SMARTER_SYNC_LOOP_MERCHANT_SERVICE_NAME)) {
            if(serviceToFail == null || serviceToFail != Constants.SMARTER_SYNC_LOOP_MERCHANT_SERVICE_NAME) {
                res.setBody('{"data":{"merchantLoopId":"' + Datetime.now().getTime() + '"},"meta":{"status":"Succeeded"}}');
                res.setStatusCode(200);
            } else if(serviceToFail == Constants.SMARTER_SYNC_LOOP_MERCHANT_SERVICE_NAME) {
                res.setBody('{"meta":{"messages":[{"code":"BAD_REQUEST","text":"Request data is invalid: A merchant loop already exists with external reference \'1234567ALK2\'","level":"Error","traceId":"3977776862361977166"}],"status":"Failed"}}');
                res.setStatusCode(400);
            }
        } else if(req.getEndpoint().endsWith(Constants.SMARTER_SYNC_LOOP_STORES_NAME)) {
            if(serviceToFail == null || serviceToFail != Constants.SMARTER_SYNC_LOOP_STORES_NAME) {
                res.setBody('{"data":{"storeId":"' + Datetime.now().getTime() + '"},"meta":{"status":"Succeeded"}}');
                res.setStatusCode(200);
            } else if(serviceToFail == Constants.SMARTER_SYNC_LOOP_STORES_NAME) {
                res.setBody('{"meta":{"messages":[{"code":"BAD_REQUEST","text":"Request data is invalid: A merchant loop already exists with external reference \'1234567ALK2\'","level":"Error","traceId":"3977776862361977166"}],"status":"Failed"}}');
                res.setStatusCode(400);
            }
        } else if(req.getEndpoint().endsWith(Constants.SMARTER_SYNC_ACCOUNT_CONTACT_RELATIONS_SERVICE_NAME)) {
            if(serviceToFail == null || serviceToFail != Constants.SMARTER_SYNC_ACCOUNT_CONTACT_RELATIONS_SERVICE_NAME) {
                res.setBody('');
                res.setStatusCode(204);
            } else if(serviceToFail == Constants.SMARTER_SYNC_ACCOUNT_CONTACT_RELATIONS_SERVICE_NAME) {
                res.setBody('{"meta":{"messages":[{"code":"NotEmptyValidator","text":"\'Roles\' must not be empty.","level":"Error","traceId":"8212759852197146971"}],"status":"Failed"}}');
                res.setStatusCode(400);
            }
        } else if(req.getEndpoint().endsWith(Constants.SMARTER_VALIDATE_IBAN_SERVICE_NAME)) {
            jsonString = '{"bimt190": {"bicIbanVldtnResp": [{"stsCode": "AC00","ntnlAcct": {"ban": "30004000031234567890143","countryCode": "FR"},"intlAcct": {"iban": "FR7630004000031234567890143"},"agt": {"bic": "BNPAFRPPXXX"},"b2b": true,"b2bSpecified": true}]}}';
            res.setBody(jsonString);
            res.setStatusCode(200);
        } else if(req.getEndpoint().endsWith(Constants.SMARTER_CREATE_MANDAT_SERVICE_NAME)) {
            jsonString = '{"mamt101":{"cdtrMndtAns": {"cdtr": {"prvtId": {"id": "FR64ZZZ409362"}},"mndtAns": [{"txSts": "ACCT","txStsCode": "MD00","intlId": "test_1693581695658","mndtId": "5649CD32935244148789F91B480BDF28","mndtSts": "DEACTIVATED","mndtTp": "B2B","mndtTpSpecified": true,"seqTp": "RCUR","seqTpSpecified": true,"idx": "?"}]}}}';
            res.setBody(jsonString);
            res.setStatusCode(400);
        }
        else {
            System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
            res.setBody(jsonString);
            res.setStatusCode(200);
        }

        return res;
    }
}