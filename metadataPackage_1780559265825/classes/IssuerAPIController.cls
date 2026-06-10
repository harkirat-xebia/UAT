/**
 * @author : AAZ
 * @date : 02/01/2022
 * @desc : IssuerAPIController
 * @see IssuerAPIController
 */

public with sharing class IssuerAPIController {
  /**
   * @author AAZ
   * @date 04/01/2023
   * @description Get Issuer Account Balnce
   * @param assetId
   *
   * @return
   */
  @AuraEnabled(Cacheable=true)
  public static String getBalance(Id assetId) {
    String body;
    try {
      Asset a = getIssuerAccountById(assetId);
      if (a != null) {
        System.debug('>>>>> AAZ - IssuerAPIController getBalance accountNumber : ' + a.Issuer_Account_code__c);
        System.debug('>>>>> AAZ - IssuerAPIController getBalance bu : ' + a.ER_BUPicklist__c);
        body = getIssuerAccount(a.Issuer_Account_code__c, a.ER_BUPicklist__c, true);
        System.debug('>>>>> AAZ - getBalance body : ' + body);
      }
    } catch (ApplicationException ae) {
      System.debug('>>>>> AAZ getBalance ApplicationException - ' + ae.getMessage());
      throw new AuraHandledException(ae.getMessage());
    } catch (AuraHandledException ahe) {
      System.debug('>>>>> AAZ - getBalance AuraHandledException : ' + ahe.getMessage());
    } catch (Exception e) {
      System.debug('>>>>> AAZ - getBalance Exception : ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }

    return body;
  }

  /**
   * @author AAZ
   * @date 04/01/2023
   * @description Get Issuer Account
   * @param accountNumber
   * @param bu
   * @param shouldEmbedBalance
   *
   * @return
   */
  public static String getIssuerAccount(String accountNumber, String bu, Boolean shouldEmbedBalance) {
    System.debug('>>>>> AAZ - IssuerAPIController getIssuerAccount accountNumber : ' + accountNumber);
    System.debug('>>>>> AAZ - IssuerAPIController getIssuerAccount bu : ' + bu);
    System.debug('>>>>> AAZ - IssuerAPIController getIssuerAccount shouldEmbedBalance : ' + shouldEmbedBalance);

    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    String body;

    try {
        Map<String, String> smarterAT = Utils.getSmarterAccessToken();
        if(smarterAT!=null && !smarterAT.isEmpty() && smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) && smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)) {
            String embedBalanceParam = '';
            String pagination = '?page-index=0&page-size=200';
            if(shouldEmbedBalance) embedBalanceParam = '&should-embed-balances=true';
            req.setEndpoint('callout:' + Constants.SMARTER_NAMED_CREDENTIAL + Constants.SLASH
                    + Constants.GET_ISSUER_ACCOUNT_SERVICE_VERSION + Constants.SLASH
                    + Constants.GET_ISSUER_ACCOUNT_SERVICE_NAME + Constants.SLASH
                    + accountNumber
                    + pagination
                    + embedBalanceParam);
            req.setMethod(Constants.GET_METHOD);
            req.setHeader(Constants.X_TENANT, bu);
            req.setHeader('Authorization', smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) + ' ' + smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN));
            req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());

            resp = http.send(req);

            if(resp.getStatusCode() == 200) {
                Map<String, Product2> mapProductClassName = new Map<String, Product2>();
                Id benefitRTId = Utils.getRecordTypeIdByDeveloperName(Product2.SObjectType, Constants.PRODUCT2_BENEFIT_RT);
                for(Product2 p :[SELECT Id, Name, ER_Product_class__r.ER_ProductClassCode__c, ER_Wallet__c FROM Product2 WHERE RecordTypeId = :benefitRTId]) {
                    mapProductClassName.put(p.ER_Product_class__r.ER_ProductClassCode__c, p);
                }
                System.debug('>>>>> AAZ - Success resp.getStatusCode(): ' + resp.getStatusCode());
                System.debug('>>>>> AAZ - resp.getBody(): ' + resp.getBody());
                Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                System.debug('>>>>> AAZ - mapResponse : ' + mapResponse);
                Map<String, Object> meta = (Map<String, Object>) mapResponse.get('meta');
                System.debug('>>>>> AAZ - meta : ' + meta);
                if(meta != null) {
                    String status = (String) meta.get('status');
                    System.debug('>>>>> AAZ - status : ' + status);
                    if(String.isNotBlank(status) && status == 'Succeeded') {
                        Map<String, Object> respData = (Map<String, Object>) mapResponse.get('data');
                        String productClass = (String) respData.get('productClassCode');
                        System.debug('>>>>> AAZ - productClass : ' + productClass);
                        List<Object> wallets = (List<Object>) respData.get('wallets');
                        System.debug('>>>>> AAZ - wallets : ' + wallets);

                        if(wallets != null) {
                            for(Integer i = 0; i < wallets.size(); i++) {
                                Map<String, Object> wallet = (Map<String, Object>) wallets[i];
                                System.debug('>>>>> AAZ - row : ' + wallet);
                                String walletStatus = (String)wallet.get('status');
                                String walletName = (String) wallet.get('name');
                                if(String.isNotBlank(walletStatus)
                                        && String.isNotBlank(walletName)
                                        && walletStatus == 'ACTIVE'
                                        && String.isNotBlank(productClass) && mapProductClassName.containsKey(productClass) && mapProductClassName.get(productClass).ER_Wallet__c == walletName)
                                    respData.put('commercialName', mapProductClassName.get(productClass).Name);
                            }
                        }

                        System.debug('>>>>> AAZ - respData : ' + respData);
                        System.debug('>>>>> AAZ - mapResponse : ' + mapResponse);
                        body = JSON.serialize(mapResponse);
                    }
                }
            } else {
                System.debug('>>>>> AAZ - Status code : ' + resp.getStatusCode());
                System.debug('>>>>> AAZ - Failed resp.getBody(): ' + resp.getBody());
                throw new ApplicationException((String.isNotBlank(resp.getBody()) ? resp.getBody() : Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + resp.getStatusCode()));
            }
        } else {
            throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
        }
    } catch(AuraHandledException ahe) {
        System.debug('>>>>> AAZ - getIssuerAccount Exception : ' + ahe.getMessage());
        throw new ApplicationException(ahe.getMessage());
    } catch(Exception e) {
        System.debug('>>>>> AAZ - getIssuerAccount Exception : ' + e.getMessage());
        throw new ApplicationException(e.getMessage());
    }

    return body;
}

  /**
   * @author AAZ
   * @date 23/01/2023
   * @description Get Issuer Account Transactions
   * @param assetId
   * @param fromDAte
   * @param toDate
   *
   * @return
   */
  @AuraEnabled(Cacheable=true)
  public static String getTransactions(Id assetId, String fromDate, String toDate) {
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HttpResponse resp;
    String body;

    try {
      Map<String, String> smarterAT = Utils.getSmarterAccessToken();
      if (
        smarterAT != null &&
        !smarterAT.isEmpty() &&
        smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
        smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
      ) {
        Asset a = getIssuerAccountById(assetId);
        if (a != null) {
          System.debug('>>>>> AAZ - IssuerAPIController getTransactions accountNumber : ' + a.Issuer_Account_code__c);
          System.debug('>>>>> AAZ - IssuerAPIController getTransactions bu : ' + a.ER_BUPicklist__c);
          System.debug('>>>>> AAZ - fromDate : ' + fromDate);
          System.debug('>>>>> AAZ - toDate : ' + toDate);

          String params =
            '?account-number=' +
            a.Issuer_Account_code__c +
            '&from-created-datetime=' +
            (String.isNotBlank(fromDate) ? fromDate : '') +
            '&to-created-datetime=' +
            (String.isNotBlank(toDate) ? toDate : '');
          req.setEndpoint(
            'callout:' +
            Constants.SMARTER_NAMED_CREDENTIAL +
            Constants.SLASH +
            Constants.GET_IA_TRANSACTIONS_SERVICE_VERSION +
            Constants.SLASH +
            Constants.GET_IA_TRANSACTIONS_SERVICE_NAME +
            params
          );
          req.setMethod(Constants.GET_METHOD);
          req.setHeader(Constants.X_TENANT, a.ER_BUPicklist__c?.toUpperCase());
          req.setHeader(
            'Authorization',
            smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
            ' ' +
            smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
          );
          req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());

          resp = http.send(req);

          if (resp.getStatusCode() == 200)
            body = resp.getBody();
          else {
            System.debug('>>>>> AAZ - Status code : ' + resp.getStatusCode());
            System.debug('>>>>> AAZ - Failed resp.getBody(): ' + resp.getBody());
            throw new ApplicationException(
              (String.isNotBlank(resp.getBody())
                ? resp.getBody()
                : Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + resp.getStatusCode())
            );
          }
        }
      } else {
        throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
      }
    } catch (ApplicationException ae) {
      System.debug('>>>>> AAZ getTransactions ApplicationException - ' + ae.getMessage());
      throw new AuraHandledException(ae.getMessage());
    } catch (AuraHandledException ahe) {
      System.debug('>>>>> AAZ - getBalance AuraHandledException : ' + ahe.getMessage());
    } catch (Exception e) {
      System.debug('>>>>> AAZ - getBalance Exception : ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
    return body;
  }

  /**
   * @author AAZ
   * @date 04/01/2023
   * @description Get Issuer Account by Id
   * @param assetId
   *
   * @return
   */
  private static Asset getIssuerAccountById(Id assetId) {
    if (String.isNotBlank(assetId)) {
      return [SELECT Id, Issuer_Account_code__c, ER_BUPicklist__c FROM Asset WHERE Id = :assetId];
    }
    return null;
  }
}