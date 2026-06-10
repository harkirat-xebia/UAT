/**
----------------------------------------------------------------------
-- @author        : Noor
-- @description   : ClientOrderService - service to query Order from SmarterNC
--
-- @Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--05/01/2023    Noor                 1.0         Initial version
--16/08/2023    Malha AMEUR          1.1         COUL-4643 Ability to Retry order with status = SubmissionInError from GetORderByClient
---------------------------------------------------------------------------------------
*/
public with sharing class ClientOrderService {
  /**
   * @description Method to get data from webservice
   *              Query get Order by client when coming from account object
   *              Query get Order by Employee when coming from employee object
   * @author Noor
   * @param searchId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param pageSize page size
   * @param objectType object type Account or Employee
   * @param bu business unit
   *
   * @return Json from the webservice
   */
  public static String getOrders(String searchId, Integer pageIndex, Integer pageSize, String objectType, String bu) {
    Map<String, String> smarterAT = Utils.getSmarterAccessToken();
    if (
      smarterAT != null &&
      !smarterAT.isEmpty() &&
      smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
      smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
    ) {
      HttpRequest req = new HttpRequest();
      String url = getUrl(searchId, pageIndex, pageSize, objectType);
      req.setEndpoint('callout:SmarterNC/' + url);
      req.setHeader(Constants.X_TENANT, bu);
      req.setMethod('GET');
      req.setHeader(
        'Authorization',
        smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
        ' ' +
        smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
      );
      req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
      Http http = new Http();
      HttpResponse res = http.send(req);
      if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
        throw new ApplicationException(Label.LAB_SF_CL_NO_RECORD_FOUND_WITH_ID.replace('{0}', searchId));
      return res.getBody();
    } else {
      throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
    }
  }

  /**
   * @description map the Order fields from the Webservice result with the wrapper to be displayed on screen
   *
   * @author Noor
   * @param json
   *
   * @return list of order wrappers including the orderline
   */
  public static List<OrderWrapper> mapOrders(String json) {
    OrderParser parser = OrderParser.parse(json);
    List<OrderWrapper> fields = new List<OrderWrapper>();

    if (parser.data.isEmpty())
      throw new ApplicationException(Label.LAB_SF_CL_NO_RECORD_FOUND);
    Map<String, Product2> products = new Map<String, Product2>();

    for (Product2 p : [
      SELECT
        Id,
        ER_BenefitId__c,
        ProductCode,
        Name,
        ER_Product_class__r.ER_ProductClassCode__c,
        ER_Product_class__r.ER_ProductClassFamilyId__c,
        ER_Product_class__r.ER_ProductFamilyName__c,
        ER_Product_class__c
      FROM Product2
      WHERE RecordType.DeveloperName = :Constants.PRODUCT2_BENEFIT_RT AND IsActive = TRUE
    ]) {
      products.put(String.valueOf(p.ER_BenefitId__c), p);
    }
    for (OrderParser.Data data : parser.data) {
      OrderWrapper order = new OrderWrapper();

      order.orderId = String.valueOf(data.orderId);

      order.orderNumber = data.orderNumber;
      order.purchaseOrderReference = data.purchaseOrderReference;
      order.orderCreationDateTime = data.orderCreationDateTime;
      order.status = data.status;
      order.totalLoadAmount = String.valueOf(data.totalLoadAmount);
      order.orderPromoCode = String.valueOf(data.promoCode);
      order.itemLineCount = String.valueOf(data.itemLineCount);
      order.distinctEmployeeCount = String.valueOf(data.distinctEmployeeCount);
      order.createdbyContactId = String.valueOf(data.createdbyContactId);
      order.selectedPaymentMean = data.selectedPaymentMean;
      order.financialValidationDate = data.financialValidationDate;
      order.financialValidationType = data.financialValidationType;
      order.firstInvoiceDate = data.firstInvoiceDate;
      order.billingAccountNumber = data.billingAccountNumber;
      order.orderSubmissionDate = data.orderSubmissionDate;
      order.state = data.state;

      order.orderlines = mapOrderline(data, products);
      fields.add(order);
    }

    return fields;
  }

  /**
   * @description map the Order fields from the Webservice result with the wrapper to be displayed on screen
   *
   * @author Noor
   * @param json
   *
   * @return list of order wrappers including the orderline
   */
  public static List<EmployeeOrderWrapper> mapEmployeeOrders(String json) {
    EmployeeOrderParser parser = EmployeeOrderParser.parse(json);
    List<EmployeeOrderWrapper> fields = new List<EmployeeOrderWrapper>();
    Map<String, Product2> products = new Map<String, Product2>();
    if (parser.data.isEmpty())
      throw new ApplicationException(Label.LAB_SF_CL_NO_RECORD_FOUND);

    for (Product2 p : [
      SELECT
        Id,
        ER_BenefitId__c,
        ProductCode,
        Name,
        ER_Product_class__r.ER_ProductClassCode__c,
        ER_Product_class__r.ER_ProductClassFamilyId__c,
        ER_Product_class__r.ER_ProductFamilyName__c,
        ER_Product_class__c
      FROM Product2
      WHERE RecordType.DeveloperName = :Constants.PRODUCT2_BENEFIT_RT AND IsActive = TRUE
    ]) {
      products.put(String.valueOf(p.ER_BenefitId__c), p);
    }
    Map<String, ER_Employee__c> employeeMap = getEmployeeMapFromSmarterId(parser.data);
    for (EmployeeOrderParser.Data data : parser.data) {
      for (EmployeeOrderParser.OrderItems orderItem : data.orderItems) {
        for (EmployeeOrderParser.OrderItemLines orderItemLine : orderItem.orderItemLines) {
          EmployeeOrderWrapper order = new EmployeeOrderWrapper();
          Product2 p;
          if (String.isNotBlank(orderItem.benefitId) && products.containsKey(orderItem.benefitId))
            p = products.get(orderItem.benefitId);
          order.orderId = data.orderId;
          order.orderNumber = data.orderNumber;
          order.preferredLoadDate = orderItem.preferredLoadDate;
          if (p != null)
            order.commercialName = p.Name;
          order.firstName = orderItemLine.firstName;
          order.lastName = orderItemLine.lastName;
          order.email = orderItemLine.email;
          order.birthdate = orderItemLine.birthDate;
          order.totalAmount = orderItemLine.totalAmount;
          order.status = orderItemLine.Status;
          order.employeeId = orderItemLine.EmployeeId;
          order.orderLineItemId = orderItemLine.orderItemLineId;
          if (employeeMap.containsKey(orderItemLine.employeeId))
            order.employeeLink = getLink(employeeMap.get(orderItemLine.employeeId).Id);
          fields.add(order);
        }
      }
    }

    return fields;
  }

  /**
   * @description map the Orderline fields from the Webservice result with the wrapper to be displayed on screen
   *
   * @author Noor
   * @param data order parser
   *
   * @return list of order wrappers including the orderline
   */
  public static List<ClientOrderService.OrderlineWrapper> mapOrderline(
    OrderParser.Data data,
    Map<String, Product2> products
  ) {
    List<ClientOrderService.OrderlineWrapper> orderlines = new List<ClientOrderService.OrderlineWrapper>();
    for (OrderParser.OrderItems item : data.orderItems) {
      OrderlineWrapper orderLine = new OrderlineWrapper();
      Product2 p;
      if (String.isNotBlank(item.benefitId) && products.containsKey(item.benefitId))
        p = products.get(item.benefitId);
      orderLine.orderItemId = item.orderItemId;
      orderLine.orderNumber = data.orderNumber;
      orderLine.orderId = String.valueOf(data.orderId);
      orderLine.totalLoadAmount = item.totalLoadAmount;
      orderline.itemLineCount = item.itemLineCount;
      orderline.preferredLoadDate = item.preferredLoadDate;
      orderline.status = item.status;
      orderLine.benefitId = item.benefitId;
      if (p != null) {
        orderLine.commercialName = p.Name;
        orderLine.benefitFamilyName = p.ER_Product_class__r.ER_ProductFamilyName__c;
      }
      orderlines.add(orderLine);
    }

    return orderlines;
  }

  /**
   * @description Method to get OrderItemLines data by orderId from webservice
   *
   * @author Noor
   * @param orderId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param pageSize page size
   * @param bu business unit
   *
   * @return Json from the webservice
   */
  public static String getOrderItemLines(String orderId, Integer pageIndex, Integer pageSize, String bu) {
    Map<String, String> smarterAT = Utils.getSmarterAccessToken();
    if (
      smarterAT != null &&
      !smarterAT.isEmpty() &&
      smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
      smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
    ) {
      HttpRequest req = new HttpRequest();
      String url = constructOrderLineURL(orderId, pageIndex, pageSize);
      req.setEndpoint('callout:SmarterNC/' + url);
      req.setHeader(Constants.X_TENANT, bu);
      req.setMethod('GET');
      req.setHeader(
        'Authorization',
        smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
        ' ' +
        smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
      );
      req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
      Http http = new Http();
      HttpResponse res = http.send(req);
      System.debug(res.getBody());
      if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
        throw new ApplicationException(Label.LAB_SF_CL_NO_RECORD_FOUND_WITH_ID.replace('{0}', orderId));
      System.debug(res.getBody());
      return res.getBody();
    } else {
      throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
    }
  }

  /**
   * @description Method to cancel order by orderId from webservice
   *
   * @author Noor
   * @param orderId id by which we will search Client
   * @param bu business unit
   *
   * @return Json from the webservice
   */
  public static String cancelOrder(String objectId, String orderId, String orderNumber, String bu) {
    Map<String, String> smarterAT = Utils.getSmarterAccessToken();
    if (
      smarterAT != null &&
      !smarterAT.isEmpty() &&
      smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
      smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
    ) {
      HttpRequest req = new HttpRequest();
      String url =
        Constants.SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_VERSION +
        Constants.SLASH +
        Constants.SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_SERVICE +
        Constants.SLASH +
        orderId +
        Constants.SLASH +
        Constants.SMARTER_CANCEL_ORDER;
      req.setEndpoint('callout:SmarterNC/' + url);
      req.setHeader(Constants.X_TENANT, bu);
      req.setMethod(Constants.POST_METHOD);
      req.setHeader(
        'Authorization',
        smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
        ' ' +
        smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
      );
      req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
      Http http = new Http();
      HttpResponse res = http.send(req);
      System.debug(res.getBody());
      if (res.getStatusCode() != 204)
        throw new ApplicationException(res.getBody());
      createTask(objectId, orderNumber);
      return res.getBody();
    } else {
      throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
    }
  }

  /**
   * @description Method to cancel order by orderId from webservice
   *
   * @author Noor
   * @param orderId id by which we will search Client
   * @param bu business unit
   *
   * @return Json from the webservice
   */
  public static String retryLoad(String loadId, String bu, String recordId, String orderNumber) {
    Map<String, String> smarterAT = Utils.getSmarterAccessToken();
    if (
      smarterAT != null &&
      !smarterAT.isEmpty() &&
      smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
      smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
    ) {
      HttpRequest req = new HttpRequest();
      String url =
        Constants.SMARTER_WEBSERVICE_ORDER_BY_CLIENT_VERSION +
        Constants.SMARTER_WEBSERVICE_LOADS +
        Constants.SLASH +
        loadId +
        Constants.SLASH +
        Constants.SMARTER_RETRY_ORDER;
      req.setEndpoint('callout:SmarterNC/' + url);
      req.setHeader(Constants.X_TENANT, bu);
      req.setMethod(Constants.POST_METHOD);
      req.setHeader(
        'Authorization',
        smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
        ' ' +
        smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
      );
      req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
      Http http = new Http();
      HttpResponse res = http.send(req);
      System.debug(res.getBody());
      if (res.getStatusCode() != 204)
        throw new ApplicationException(res.getBody());
      createTask(recordId, orderNumber, Label.LAB_SF_CL_ORDER_RETRY_LOAD_SUBJECT, Label.LAB_SF_CL_ORDER_RETRY_LOAD_COMMENT, loadId); 
      return res.getBody();
    } else {
      throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
    }
  }

  public static String retryOrder(String orderId, String accountId) {
    Map<String, String> smarterAT = Utils.getSmarterAccessToken();
    if(smarterAT!=null && !smarterAT.isEmpty() && smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) && smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)) {
        HttpRequest req = new HttpRequest();
        String url = Constants.SMARTER_WEBSERVICE_ORDER_BY_CLIENT_VERSION + Constants.SMARTER_WEBSERVICE_ORDERS + Constants.SLASH
                + orderId + Constants.SLASH + Constants.SMARTER_RESTART_SUBMISSION;
        req.setEndpoint('callout:SmarterNC/'+url);
        req.setHeader(Constants.X_TENANT, 'FR');
        req.setMethod(Constants.POST_METHOD);
        req.setHeader('Authorization', smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) + ' ' + smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN));
        req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        if(res.getStatusCode() != 200) throw new ApplicationException(res.getBody());
        createTask(accountId,orderId, Label.LAB_SF_CL_ORDER_RE_SUBMISSION_SUBJECT , Label.LAB_SF_CL_ORDER_RE_SUBMISSION_COMMENT, '');
        return res.getBody();
    } else {
        throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
    }
  }

  private static void createTask(String relatedTo, String orderId, String subject, String comment,String loadId){
    Task t = new Task(
        Subject = subject,
        Status = Constants.CLOSED,
        WhatId = relatedTo, 
        Description = String.format(comment, new List<Object>{orderId, loadId}),
        ER_Channel__c = Constants.SMARTER_BACKOFFICE,
        Priority = Label.LAB_SF_CL_ORDER_TASK_PRIORITY,
        ActivityDate = Date.today()
    );
    insert t;
  }

  private static void createTask(String objectId, String orderNumber) {
    Task t = new Task();
    t.Subject = Label.LAB_SF_CL_ORDER_TASK_SUBJECT;
    t.Description = String.format(Label.LAB_SF_CL_ORDER_TASK_DESCRIPTION, new List<Object>{ orderNumber });
    t.Status = Label.LAB_SF_CL_ORDER_TASK_STATUS;
    t.Priority = Label.LAB_SF_CL_ORDER_TASK_PRIORITY;
    t.ActivityDate = Date.today();
    t.WhatId = objectId;
    insert t;
  }
  /**
   * @description map the OrderItemLine fields from the Webservice result with the wrapper to be displayed on screen
   *
   * @author Noor
   * @param json
   *
   * @return list of orderItemLIne wrappers including the orderline
   */
  public static List<OrderItemLineWrapper> mapOrderItemLines(String json) {
    OrderItemLineParser parser = OrderItemLineParser.parse(json);
    List<OrderItemLineWrapper> fields = new List<OrderItemLineWrapper>();
    if (parser.data.isEmpty())
      throw new ApplicationException(Label.LAB_SF_CL_NO_RECORD_FOUND);

    Map<String, ER_Employee__c> employeeMap = getEmployeeMapFromSmarterId(parser.data);
    Map<String, ClientOrderService.OrderItemLineWrapper> mapItems = new Map<String, ClientOrderService.OrderItemLineWrapper>();
    Integer i = 0;
    for (OrderItemLineParser.Data data : parser.data) {
      OrderItemLineWrapper orderItemLine = new OrderItemLineWrapper();
      orderItemLine.orderItemLineId = String.valueOf(data.orderItemLineId);
      orderItemLine.orderItemId = String.valueOf(data.orderItemId);
      orderItemLine.firstName = data.firstName;
      orderItemLine.lastName = data.lastName;
      orderItemLine.email = data.email;
      orderItemLine.birthDate = data.birthDate;
      orderItemLine.employeeId = data.employeeId;
      if (employeeMap.containsKey(data.employeeId))
        orderItemLine.employeeLink = getLink(employeeMap.get(data.employeeId).Id);
      orderItemLine.unitCount = String.valueOf(data.unitCount);
      orderItemLine.unitAmount = String.valueOf(data.unitAmount);
      orderItemLine.totalAmount = String.valueOf(data.totalAmount);
      orderItemLine.partFinancedByCompany = String.valueOf(data.partFinancedByCompany);
      orderItemLine.externalReferenceNumber = String.valueOf(data.edenredCodeId);
      orderItemLine.statusId = data.status;
      fields.add(orderItemLine);

      if (!mapItems.containsKey(data.lastName))
        mapItems.put(data.lastName, orderItemLine);
      else
        mapItems.put(data.lastName + i, orderItemLine);
      i++;
    }
    List<String> itemsToSort = new List<String>(mapItems.keySet());
    if (itemsToSort != null && !itemsToSort.isEmpty()) {
      itemsToSort.sort();
      for (String item : itemsToSort) {
        fields.add(mapItems.get(item));
      }
    }
    return fields;
  }

  private static String getLink(Id id) {
    return '/lightning/r/ER_Employee__c/' + id + '/view';
  }

  /**
   * @author Noor
   * @description retrieve Employee by Smarter id
   * @param listData
   *
   * @return map of Employee by Smarter Id
   */
  private static Map<String, ER_Employee__c> getEmployeeMapFromSmarterId(List<OrderItemLineParser.Data> listData) {
    Set<String> listSmarterEmployeeIds = new Set<String>();
    Map<String, ER_Employee__c> mapEmployees = new Map<String, ER_Employee__c>();
    for (OrderItemLineParser.Data data : listData)
      if (String.isNotBlank(data.employeeId))
        listSmarterEmployeeIds.add(data.employeeId);

    if (!listSmarterEmployeeIds.isEmpty()) {
      for (ER_Employee__c emp : [
        SELECT Id, ER_SmartER_Employee_Id__c
        FROM ER_Employee__c
        WHERE ER_SmartER_Employee_Id__c IN :listSmarterEmployeeIds
      ])
        mapEmployees.put(emp.ER_SmartER_Employee_Id__c, emp);
    }
    return mapEmployees;
  }

  /**
   * @author Noor
   * @description retrieve Employee by Smarter id
   * @param listData
   *
   * @return map of Employee by Smarter Id
   */
  private static Map<String, ER_Employee__c> getEmployeeMapFromSmarterId(List<EmployeeOrderParser.Data> listData) {
    Set<String> listSmarterEmployeeIds = new Set<String>();
    Map<String, ER_Employee__c> mapEmployees = new Map<String, ER_Employee__c>();

    for (EmployeeOrderParser.Data data : listData) {
      for (EmployeeOrderParser.OrderItems orderItem : data.orderItems) {
        for (EmployeeOrderParser.OrderItemLines orderItemLine : orderItem.orderItemLines) {
          if (String.isNotBlank(orderItemLine.employeeId))
            listSmarterEmployeeIds.add(orderItemLine.employeeId);
        }
      }
    }

    if (!listSmarterEmployeeIds.isEmpty()) {
      for (ER_Employee__c emp : [
        SELECT Id, ER_SmartER_Employee_Id__c
        FROM ER_Employee__c
        WHERE ER_SmartER_Employee_Id__c IN :listSmarterEmployeeIds
      ])
        mapEmployees.put(emp.ER_SmartER_Employee_Id__c, emp);
    }
    return mapEmployees;
  }

  /**
   * @description Method to get OrderItemLines data by orderId from webservice
   *
   * @author Noor
   * @param orderId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param pageSize page size
   * @param bu business unit
   *
   * @return Json from the webservice
   */
  public static String getLoadsByOrder(
    String orderId,
    String queryTypeParam,
    Integer pageIndex,
    Integer pageSize,
    String bu
  ) {
    Map<String, String> smarterAT = Utils.getSmarterAccessToken();
    if (
      smarterAT != null &&
      !smarterAT.isEmpty() &&
      smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
      smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
    ) {
      HttpRequest req = new HttpRequest();
      String url = constructLoadsURL(orderId, queryTypeParam, pageIndex, pageSize);
      req.setEndpoint('callout:SmarterNC/' + url);
      req.setHeader(Constants.X_TENANT, bu);
      req.setMethod('GET');
      req.setHeader(
        'Authorization',
        smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
        ' ' +
        smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
      );
      req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
      Http http = new Http();
      HttpResponse res = http.send(req);
      if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
        throw new ApplicationException(Label.LAB_SF_CL_NO_LOAD_RECORD_FOUND);
      System.debug(res.getBody());
      return res.getBody();
    } else {
      throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
    }
  }

  /**
   * @description Method to get Processing Events data by orderId from webservice
   *
   * @author Noor
   * @param orderId id by which we will search Processing Events
   * @param pageIndex page index search
   * @param pageSize page size
   * @param bu business unit
   *
   * @return Json from the webservice
   */
  public static String getOrderProcessingEvents(String orderId, Integer pageIndex, Integer pageSize, String bu) {
    Map<String, String> smarterAT = Utils.getSmarterAccessToken();
    if (
      smarterAT != null &&
      !smarterAT.isEmpty() &&
      smarterAT.containsKey(Constants.SMARTER_MS_TOKEN_TYPE) &&
      smarterAT.containsKey(Constants.SMARTER_MS_ACCESS_TOKEN)
    ) {
      HttpRequest req = new HttpRequest();
      String url = constructProcessingEventsURL(orderId);
      req.setEndpoint('callout:SmarterNC/' + url);
      req.setHeader(Constants.X_TENANT, bu);
      req.setMethod('GET');
      req.setHeader(
        'Authorization',
        smarterAT.get(Constants.SMARTER_MS_TOKEN_TYPE) +
        ' ' +
        smarterAT.get(Constants.SMARTER_MS_ACCESS_TOKEN)
      );
      req.setHeader(Constants.REQUEST_HEADER_USER_EMAIL, UserInfo.getUserEmail());
      Http http = new Http();
      HttpResponse res = http.send(req);
      if (res.getStatusCode() != 200 || String.isBlank(res.getBody()))
        throw new ApplicationException(Label.LAB_SF_CL_NO_RECORD_FOUND);
      System.debug(res.getBody());
      return res.getBody();
    } else {
      throw new ApplicationException(Label.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN + ': No Smarter access tokens');
    }
  }
  /**
   * @description map the Order fields from the Webservice result with the wrapper to be displayed on screen
   *
   * @author Noor
   * @param json
   *
   * @return list of order wrappers including the orderline
   */
  public static List<OrderLoadWrapper> mapOrderLoad(String json) {
    OrderLoadParser parser = OrderLoadParser.parse(json);
    List<OrderLoadWrapper> fields = new List<OrderLoadWrapper>();
    Map<String, Product2> products = new Map<String, Product2>();
    if (parser.data.isEmpty())
      throw new ApplicationException(Label.LAB_SF_CL_NO_LOAD_RECORD_FOUND);

    for (Product2 p : [
      SELECT
        Id,
        ER_BenefitId__c,
        ProductCode,
        Name,
        ER_Product_class__r.ER_ProductClassCode__c,
        ER_Product_class__r.ER_ProductClassFamilyId__c,
        ER_Product_class__r.ER_ProductFamilyName__c,
        ER_Product_class__c
      FROM Product2
      WHERE RecordType.DeveloperName = :Constants.PRODUCT2_BENEFIT_RT AND IsActive = TRUE
    ]) {
      products.put(String.valueOf(p.ER_BenefitId__c), p);
    }
    Map<String, String> clientMap = new Map<String, String>();

    for (OrderLoadParser.Data data : parser.data) {
      if (String.isNotBlank(data.clientId))
        clientMap.put(data.clientId, data.clientId);
    }
    for (Account a : [
      SELECT Id, Name, SmartER_Customer_Id__c
      FROM Account
      WHERE SmartER_Customer_Id__c IN :clientMap.keySet()
    ])
      clientMap.put(a.SmartER_Customer_Id__c, a.Name);

    //Map<String, ER_Employee__c> employeeMap = getEmployeeMapFromSmarterId(parser.data);
    for (OrderLoadParser.Data data : parser.data) {
      OrderLoadWrapper load = new OrderLoadWrapper();
      Product2 p;
      if (String.isNotBlank(data.benefitId) && products.containsKey(data.benefitId))
        p = products.get(data.benefitId);
      load.loadId = data.loadId;
      load.issuerAccountNumber = data.issuerAccountNumber;
      load.wallet = data.wallet;
      if (p != null)
        load.commercialName = p.Name;

      load.amount = data.amount;
      load.expiryDate = data.expiryDate;
      load.payerName = data.payerName;
      load.priority = data.priority;
      load.employeeId = data.employeeId;
      load.orderNumber = data.orderNumber;
      if (clientMap.containsKey(data.clientId))
        load.clientName = clientMap.get(data.clientId);
      load.createdDate = data.createdDate;
      load.lastModifiedDate = data.lastModifiedDate;
      load.status = data.status;

      fields.add(load);
    }

    return fields;
  }

  /**
   * @description map the Order fields from the Webservice result with the wrapper to be displayed on screen
   *
   * @author Noor
   * @param json
   *
   * @return list of order wrappers including the orderline
   */
  public static List<ProcessingEventWrapper> mapProcessingEvent(
    String json,
    String orderNumber,
    String billingAccount
  ) {
    OrderProcessingEventParser parser = OrderProcessingEventParser.parse(json);
    List<ProcessingEventWrapper> fields = new List<ProcessingEventWrapper>();

    if (parser.data.isEmpty())
      throw new ApplicationException(Label.LAB_SF_CL_NO_LOAD_RECORD_FOUND);

    for (OrderProcessingEventParser.Data data : parser.data) {
      ProcessingEventWrapper event = new ProcessingEventWrapper();
      event.orderNumber = orderNumber;
      event.billingAccount = billingAccount;
      event.processingEvent = data.orderProcessingEventId;
      event.finalOrderState = data.finalOrderState;
      event.errorCode = data.errorCode;
      event.errorDetail = data.errorDetail;
      event.createdDate = data.createdDate;
      fields.add(event);
    }

    return fields;
  }

  /**
   * @description construct the webservice call out url for order
   *
   * @param searchId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param service service to call Client or Employee Id
   * @param searchIdParameter Client or Employee Id
   * @param version version of the service to call
   * @param pageSize page size
   * @param objectType object type Account or Employee
   *
   * @return url form
   */
  private static String constructURL(
    String searchId,
    String searchIdParameter,
    String service,
    String version,
    Integer pageIndex,
    Integer pageSize
  ) {
    return version +
      service +
      '?' +
      Constants.SMARTER_WEBSERVICE_PAGEINDEX +
      pageIndex +
      Constants.AMPERSAND +
      Constants.SMARTER_WEBSERVICE_PAGESIZE +
      pageSize +
      Constants.AMPERSAND +
      searchIdParameter +
      searchId;
  }

  /**
   * @description construct the webservice call out url for orderlineItem
   *
   * @param searchId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param pageSize page size
   *
   * @return url form
   */
  private static String constructLoadsURL(String searchId, String queryTypeParam, Integer pageIndex, Integer pageSize) {
    return Constants.SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_VERSION +
      Constants.SMARTER_WEBSERVICE_LOADS +
      Constants.QUESTION_MARK +
      queryTypeParam +
      '=' +
      searchId +
      Constants.AMPERSAND +
      Constants.SMARTER_WEBSERVICE_PAGEINDEX +
      pageIndex +
      Constants.AMPERSAND +
      Constants.SMARTER_WEBSERVICE_PAGESIZE +
      pageSize +
      Constants.SMARTER_WEBSERVICE_LOADS_ERROR_PARAM;
  }

  /**
   * @description construct the webservice call out url for Processing Events
   *
   * @param searchId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param pageSize page size
   *
   * @return url form
   */
  private static String constructProcessingEventsURL(String searchId) {
    return Constants.SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_VERSION +
      Constants.SLASH +
      Constants.SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_SERVICE +
      Constants.SLASH +
      searchId +
      Constants.SMARTER_WEBSERVICE_PROCESSING_EVENTS;
  }

  /**
   * @description construct the webservice call out url for orderlineItem
   *
   * @param searchId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param pageSize page size
   *
   * @return url form
   */
  private static String constructOrderLineURL(String searchId, Integer pageIndex, Integer pageSize) {
    return Constants.SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_VERSION +
      Constants.SLASH +
      Constants.SMARTER_GET_ORDER_ITEM_LINES_BY_ORDER_SERVICE +
      Constants.SLASH +
      searchId +
      Constants.SMARTER_WEBSERVICE_ORDER_ITEM_LINES +
      Constants.QUESTION_MARK +
      Constants.SMARTER_WEBSERVICE_PAGEINDEX +
      pageIndex +
      Constants.AMPERSAND +
      Constants.SMARTER_WEBSERVICE_PAGESIZE +
      pageSize;
  }

  /**
   * @description Based on objectType create the endpoint url
   * @author Noor
   * @param searchId id by which we will search Client or Employee Id
   * @param pageIndex page index search
   * @param pageSize page size
   * @param objectType object type Account or Employee
   *
   * @return url to call webservice
   */
  private static String getUrl(String searchId, Integer pageIndex, Integer pageSize, String objectType) {
    if (objectType.equals(Constants.ACCOUNT)) {
      return constructURL(
        searchId,
        Constants.SMARTER_WEBSERVICE_CLIENT_ID,
        Constants.SMARTER_WEBSERVICE_ORDER_BY_CLIENT,
        Constants.SMARTER_WEBSERVICE_ORDER_BY_CLIENT_VERSION,
        pageIndex,
        pageSize
      );
    }
    return constructURL(
      searchId,
      Constants.SMARTER_WEBSERVICE_EMPLOYEE_ID,
      Constants.SMARTER_WEBSERVICE_ORDER_BY_EMPLOYEE,
      Constants.SMARTER_WEBSERVICE_ORDER_BY_EMPLOYEE_VERSION,
      pageIndex,
      pageSize
    );
  }

  /**
   * Order Wrapper class to display order (1st) level
   */
  public with sharing class OrderWrapper {
    @AuraEnabled
    public String orderId { get; set; }
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String purchaseOrderReference { get; set; }
    @AuraEnabled
    public String orderCreationDateTime { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String totalLoadAmount { get; set; }
    @AuraEnabled
    public String orderPromoCode { get; set; }
    @AuraEnabled
    public String itemLineCount { get; set; }
    @AuraEnabled
    public String distinctEmployeeCount { get; set; }
    @AuraEnabled
    public String createdbyContactId { get; set; }
    @AuraEnabled
    public String selectedPaymentMean { get; set; }
    @AuraEnabled
    public String financialValidationDate { get; set; }
    @AuraEnabled
    public String financialValidationType { get; set; }
    @AuraEnabled
    public String firstInvoiceDate { get; set; }
    @AuraEnabled
    public String billingAccountNumber { get; set; }
    @AuraEnabled
    public String orderSubmissionDate { get; set; }
    @AuraEnabled
    public String state { get; set; }

    @AuraEnabled
    public List<OrderlineWrapper> orderlines { get; set; }
  }

  /**
   * Order Wrapper class to display orderline (2nd) level
   */
  public with sharing class OrderlineWrapper {
    @AuraEnabled
    public String orderItemId { get; set; }
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String orderId { get; set; }
    @AuraEnabled
    public String commercialName { get; set; }
    @AuraEnabled
    public String benefitFamilyName { get; set; }
    @AuraEnabled
    public String preferredLoadDate { get; set; }
    @AuraEnabled
    public String totalLoadAmount { get; set; }
    @AuraEnabled
    public String itemLineCount { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String benefitId { get; set; }
  }

  /**
   * Order Wrapper class to display orderItemline (3rd) level
   */
  public with sharing class OrderItemLineWrapper {
    @AuraEnabled
    public String orderItemLineId { get; set; }
    @AuraEnabled
    public String orderItemId { get; set; }
    @AuraEnabled
    public String firstName { get; set; }
    @AuraEnabled
    public String lastName { get; set; }
    @AuraEnabled
    public String email { get; set; }
    @AuraEnabled
    public String birthDate { get; set; }
    @AuraEnabled
    public String employeeId { get; set; }
    @AuraEnabled
    public String externalReferenceNumber { get; set; }
    @AuraEnabled
    public String unitCount { get; set; }
    @AuraEnabled
    public String unitAmount { get; set; }
    @AuraEnabled
    public String totalAmount { get; set; }
    @AuraEnabled
    public String partFinancedByCompany { get; set; }
    @AuraEnabled
    public String statusId { get; set; }
    @AuraEnabled
    public String employeeLink { get; set; }
  }

  /**
   * EmployeeOrder Wrapper class to display order (1st) level
   */
  public with sharing class EmployeeOrderWrapper {
    @AuraEnabled
    public String orderId { get; set; }
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String preferredLoadDate { get; set; }
    @AuraEnabled
    public String commercialName { get; set; }
    @AuraEnabled
    public String firstName { get; set; }
    @AuraEnabled
    public String lastName { get; set; }
    @AuraEnabled
    public String email { get; set; }
    @AuraEnabled
    public String birthdate { get; set; }
    @AuraEnabled
    public String totalAmount { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String employeeId { get; set; }
    @AuraEnabled
    public String employeeLink { get; set; }
    @AuraEnabled
    public String orderLineItemId { get; set; }
  }

  /**
   * EmployeeOrder Wrapper class to display order (1st) level
   */
  public with sharing class OrderLoadWrapper {
    @AuraEnabled
    public String loadId { get; set; }
    @AuraEnabled
    public String issuerAccountNumber { get; set; }
    @AuraEnabled
    public String wallet { get; set; }
    @AuraEnabled
    public Double amount { get; set; }
    @AuraEnabled
    public String expiryDate { get; set; }
    @AuraEnabled
    public String payerName { get; set; }
    @AuraEnabled
    public Integer priority { get; set; }
    @AuraEnabled
    public String employeeId { get; set; }
    @AuraEnabled
    public String commercialName { get; set; }
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String clientName { get; set; }
    @AuraEnabled
    public String createdDate { get; set; }
    @AuraEnabled
    public String lastModifiedDate { get; set; }
    @AuraEnabled
    public String status { get; set; }
  }

  /**
   * ProcessingEvent Wrapper class to display Processing Event
   */
  public with sharing class ProcessingEventWrapper implements Comparable {
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String billingAccount { get; set; }
    @AuraEnabled
    public String processingEvent { get; set; }
    @AuraEnabled
    public String finalOrderState { get; set; }
    @AuraEnabled
    public String errorCode { get; set; }
    @AuraEnabled
    public String errorDetail { get; set; }
    @AuraEnabled
    public String createdDate { get; set; }

    public Integer compareTo(Object objToCompare) {
      return ((ProcessingEventWrapper) objToCompare).createdDate.compareTo(this.createdDate);
    }
  }
}