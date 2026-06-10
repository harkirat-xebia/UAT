/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : ClientOrderController - used by LWC Client Order to query Smarter
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--05/01/2023    Noor                 1.0         Initial version
--16/08/2023    Malha AMEUR          1.1         COUL-4643 Ability to Retry order with status = SubmissionInError from GetORderByClient
---------------------------------------------------------------------------------------
*/
public with sharing class ClientOrderController {
  /**
   * @description retrive order from Webservice and get a wrapper result
   * @param objectId record object Id
   * @param pageIndex page index base on the webservice
   * @param pageSize number of records to display
   *
   * @return wrapper
   */
  @AuraEnabled(Cacheable=true)
  public static List<ClientOrderService.OrderWrapper> getOrders(String objectId, Integer pageIndex, Integer pageSize) {
    Account a = [SELECT Id, SmartER_Customer_Id__c, ER_BUPicklist__c FROM Account WHERE Id = :objectId];
    if (String.isBlank(a.SmartER_Customer_Id__c))
      throw new ApplicationException(Label.LAB_SF_CL_SMARTER_ID_BLANK);
    String json = ClientOrderService.getOrders(
      a.SmartER_Customer_Id__c,
      pageIndex,
      pageSize,
      Constants.ACCOUNT,
      a.ER_BUPicklist__c
    );
    List<ClientOrderService.OrderWrapper> orders = ClientOrderService.mapOrders(json);
    return orders;
  }

  /**
   * @description refresh order from Webservice and get a wrapper result
   *              Note this method should not be cacheable since we need to refresh the data after cancellation
   * @param objectId record object Id
   * @param pageIndex page index base on the webservice
   * @param pageSize number of records to display
   *
   * @return wrapper
   */
  @AuraEnabled(Cacheable=false)
  public static List<ClientOrderService.OrderWrapper> refreshOrders(
    String objectId,
    Integer pageIndex,
    Integer pageSize
  ) {
    return getOrders(objectId, pageIndex, pageSize);
  }

  /**
   * @description method to cancel order in Smarter,
   *              Note that the cacheable has been removed to be able to do DML after the callout
   * @param objectId record object Id
   * @param orderId order Id as in smarter
   * @param orderNumber
   * @return wrapper
   */
  @AuraEnabled
  public static String cancelOrders(String objectId, String orderId, String orderNumber) {
    String objectType = getSObjectType(objectId);
    String bu;

    if (objectType.equalsIgnoreCase(Constants.ACCOUNT)) {
      Account a = [SELECT Id, SmartER_Customer_Id__c, ER_BUPicklist__c FROM Account WHERE Id = :objectId];
      bu = a.ER_BUPicklist__c;
    } else {
      ER_Employee__c a = [
        SELECT Id, ER_SmartER_Employee_Id__c, ER_BUPicklist__c
        FROM ER_Employee__c
        WHERE Id = :objectId
      ];
      bu = a.ER_BUPicklist__c;
    }
    String result = ClientOrderService.cancelOrder(objectId, orderId, orderNumber, bu);
    return result;
  }

  /**
   * @description method to retry,
   *              Note that the cacheable has been removed to be able to do DML after the callout
   * @param loadId order Id as in smarter
   * @return wrapper
   */
  @AuraEnabled
  public static String retryLoad(String loadId ,String recordId, String orderNumber) {
    String result = ClientOrderService.retryLoad(loadId, Constants.FR, recordId, orderNumber);
    return result;
  }


  @AuraEnabled
  public static String retryOrder(String orderId, String accountId){
      String result = ClientOrderService.retryOrder(orderId, accountId);
      return result;
  }

  @AuraEnabled(Cacheable=true)
  public static List<ClientOrderService.EmployeeOrderWrapper> getEmployeeOrders(
    String objectId,
    Integer pageIndex,
    Integer pageSize
  ) {
    ER_Employee__c a = [
      SELECT Id, ER_SmartER_Employee_Id__c, ER_BUPicklist__c
      FROM ER_Employee__c
      WHERE Id = :objectId
    ];
    if (String.isBlank(a.ER_SmartER_Employee_Id__c))
      throw new ApplicationException(Label.LAB_SF_CL_SMARTER_ID_BLANK);
    String json = ClientOrderService.getOrders(
      a.ER_SmartER_Employee_Id__c,
      pageIndex,
      pageSize,
      Constants.EMPLOYEE,
      a.ER_BUPicklist__c
    );
    List<ClientOrderService.EmployeeOrderWrapper> orders = ClientOrderService.mapEmployeeOrders(json);
    System.debug('//NGO getEmployeeOrders orders' + orders);
    return orders;
  }

  @AuraEnabled(Cacheable=true)
  public static List<ClientOrderService.OrderLoadWrapper> getOrderLoad(
    String orderId,
    String queryTypeParam,
    Integer pageIndex,
    Integer pageSize
  ) {
    String json = ClientOrderService.getLoadsByOrder(orderId, queryTypeParam, pageIndex, pageSize, Constants.FR);
    System.debug('//NGO getEmployeeOrders json' + json);
    List<ClientOrderService.OrderLoadWrapper> orders = ClientOrderService.mapOrderLoad(json);
    System.debug('//NGO getEmployeeOrders orders' + orders);
    return orders;
  }

  /**
   * @author Noor
   * @date 19/07/2023
   * @description get Order Processing Events bu OrderId
   * @param orderId
   * @param orderNumber
   * @param billingAccount
   * @param pageIndex
   * @param pageSize
   *
   * @return events wrapper
   */
  @AuraEnabled(Cacheable=true)
  public static List<ClientOrderService.ProcessingEventWrapper> getOrderProcessingEvents(
    String orderId,
    String orderNumber,
    String billingAccount,
    Integer pageIndex,
    Integer pageSize
  ) {
    String json = ClientOrderService.getOrderProcessingEvents(orderId, pageIndex, pageSize, Constants.FR);
    System.debug('//NGO getOrderProcessingEvents json' + json);
    List<ClientOrderService.ProcessingEventWrapper> events = ClientOrderService.mapProcessingEvent(
      json,
      orderNumber,
      billingAccount
    );
    System.debug('//NGO getOrderProcessingEvents events' + events);
    events.sort();
    return events;
  }

  /**
   * @description retrive orderlineItems from Webservice and get a wrapper result
   * @param objectId
   * @param orderId selected order Id
   * @param pageIndex page index base on the webservice
   * @param pageSize number of records to display
   *
   * @return orderline wrapper
   */
  @AuraEnabled(Cacheable=true)
  public static List<ClientOrderService.OrderItemLineWrapper> getOrderItemLines(
    String objectId,
    String orderId,
    Integer pageIndex,
    Integer pageSize
  ) {
    System.debug('//NGO ' + objectId);
    String objectType = getSObjectType(objectId);
    String bu;

    if (objectType.equalsIgnoreCase(Constants.ACCOUNT)) {
      Account a = [SELECT Id, SmartER_Customer_Id__c, ER_BUPicklist__c FROM Account WHERE Id = :objectId];
      bu = a.ER_BUPicklist__c;
    } else {
      ER_Employee__c a = [
        SELECT Id, ER_SmartER_Employee_Id__c, ER_BUPicklist__c
        FROM ER_Employee__c
        WHERE Id = :objectId
      ];
      bu = a.ER_BUPicklist__c;
    }

    String json = ClientOrderService.getOrderItemLines(orderId, pageIndex, pageSize, bu);
    List<ClientOrderService.OrderItemLineWrapper> orders = ClientOrderService.mapOrderItemLines(json);
    return orders;
  }

  /**
   * @description get the object API Name
   * @param sObjectId sObject record Id
   *
   * @return object API Name
   */
  private static String getSObjectType(String sObjectId) {
    if (sObjectId.startsWith(Constants.ACCOUNT_OBJECT_PREFIX))
      return Constants.ACCOUNT;
    else
      return Constants.EMPLOYEE;
  }

  /**
   * @author AAZ
   * @date 10/03/2023
   * @description Get Edenred Employee Codes
   * @param employeeId
   *
   * @return
   */
  @AuraEnabled(Cacheable=true)
  public static String getEdenredCodes(Id employeeId) {
    System.debug('>>>>> AAZ - getEdenredCodes employeeId : ' + employeeId);
    String body;
    try {
      if (String.isNotBlank(employeeId)) {
        ER_Employee__c employee = getEmployeeById(employeeId);
        if (employee != null) {
          HttpRequest req = new HttpRequest();
          Http http = new Http();
          HttpResponse resp;

          Map<String, String> accessToken = Utils.getSmarterAccessToken();
          System.debug('>>>>> ALK - getEdenredCodes accessToken : ' + accessToken);
          if (
            accessToken != null &&
            !accessToken.isEmpty() &&
            accessToken.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
            accessToken.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
          ) {
            String serviceAttribute = '?employee-id=' + employee.ER_SmartER_Employee_Id__c;
            req.setEndpoint(
              'callout:' +
              Constants.SMARTER_NAMED_CREDENTIAL +
              Constants.SLASH +
              Constants.SMARTER_EDENRED_CODES_SERVICE_VERSION +
              Constants.SLASH +
              Constants.SMARTER_EDENRED_CODES_SERVICE_NAME +
              serviceAttribute
            );
            req.setMethod(Constants.GET_METHOD);
            req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
            req.setHeader(Constants.X_TENANT, employee.ER_BUPicklist__c);
            req.setHeader(
              'Authorization',
              accessToken.get(Constants.SMARTER_MS_TOKEN_TYPE) +
              ' ' +
              accessToken.get(Constants.SMARTER_MS_ACCESS_TOKEN)
            );
            resp = http.send(req);

            System.debug('>>>>> ALK - getEdenredCodes resp.getStatusCode() ' + resp.getStatusCode());
            if (resp.getStatusCode() == 200)
              body = resp.getBody();
            else
              throw new ApplicationException(
                (String.isNotBlank(resp.getBody())
                  ? resp.getBody()
                  : Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ' ' + resp.getStatusCode())
              );
          } else
            throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
        }
      } else
        throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': Employee Id not valid');
    } catch (ApplicationException ae) {
      System.debug('>>>>> AAZ getEdenredCodes ApplicationException - ' + ae.getMessage());
      throw new AuraHandledException(ae.getMessage());
    } catch (AuraHandledException ahe) {
      System.debug('>>>>> AAZ - getEdenredCodes AuraHandledException : ' + ahe.getMessage());
    } catch (Exception e) {
      System.debug('>>>>> AAZ - getEdenredCodes Exception : ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }

    return body;
  }

  /**
   * @author AAZ
   * @date 10/03/2023
   * @description Send Edenred Code to the employee
   * @param edenredCode
   * @param employeeId
   *
   * @return
   */
  @AuraEnabled(Cacheable=true)
  public static String sendEdnredCode(String edenredCode, Id employeeId) {
    System.debug('>>>>> AAZ - edenredCode : ' + edenredCode);
    System.debug('>>>>> AAZ - employeeId : ' + employeeId);
    String body;
    try {
      ER_Employee__c employee = getEmployeeById(employeeId);
      if (String.isNotBlank(edenredCode) && employee != null) {
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HttpResponse resp;
        Map<Object, Object> mapRequestBody = new Map<Object, Object>();

        Map<String, String> accessToken = Utils.getSmarterAccessToken();
        if (
          accessToken != null &&
          !accessToken.isEmpty() &&
          accessToken.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
          accessToken.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
        ) {
          req.setEndpoint(
            'callout:' +
            Constants.SMARTER_NAMED_CREDENTIAL +
            Constants.SLASH +
            Constants.SMARTER_EDENRED_CODES_SERVICE_VERSION +
            Constants.SLASH +
            Constants.SMARTER_EDENRED_CODES_SERVICE_NAME +
            Constants.SLASH +
            edenredCode +
            Constants.SLASH +
            'send'
          );
          req.setMethod(Constants.POST_METHOD);
          req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
          req.setHeader(Constants.X_TENANT, employee.ER_BUPicklist__c);
          req.setHeader('Content-Type', 'application/json');
          req.setHeader(
            'Authorization',
            accessToken.get(Constants.SMARTER_MS_TOKEN_TYPE) +
            ' ' +
            accessToken.get(Constants.SMARTER_MS_ACCESS_TOKEN)
          );
          mapRequestBody.put('notificationType', 'reminded');
          String requestJson = JSON.serialize(mapRequestBody);
          System.debug('>>>>> AAZ - requestJson : ' + requestJson);
          req.setBody(requestJson);
          resp = http.send(req);

          System.debug('>>>>> AAZ - sendEdnredCode resp.getStatusCode() : ' + resp.getStatusCode());
          if (resp.getStatusCode() == 200)
            body = resp.getBody();
          else
            throw new ApplicationException(
              (String.isNotBlank(resp.getBody())
                ? resp.getBody()
                : Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ' ' + resp.getStatusCode())
            );
        } else
          throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
      } else
        throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': Edenred code  not valid');
    } catch (ApplicationException ae) {
      System.debug('>>>>> AAZ sendEdnredCode ApplicationException - ' + ae.getMessage());
      throw new AuraHandledException(ae.getMessage());
    } catch (AuraHandledException ahe) {
      System.debug('>>>>> AAZ - sendEdnredCode AuraHandledException : ' + ahe.getMessage());
    } catch (Exception e) {
      System.debug('>>>>> AAZ - sendEdnredCode Exception : ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }

    return body;
  }

  /**
   * @author AAZ
   * @date 10/03/2023
   * @description Get Employee by Id
   * @param employeeId
   *
   * @return
   */
  private static ER_Employee__c getEmployeeById(Id employeeId) {
    if (String.isNotBlank(employeeId)) {
      return [SELECT Id, ER_BUPicklist__c, ER_SmartER_Employee_Id__c FROM ER_Employee__c WHERE Id = :employeeId];
    }
    return null;
  }
}