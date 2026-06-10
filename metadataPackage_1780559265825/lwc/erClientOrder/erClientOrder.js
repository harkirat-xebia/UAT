/**
 * Created by noorgoolamnabee on 04/01/2023.
 */
import { LightningElement, wire, api, track } from 'lwc';
import getOrders from '@salesforce/apex/ClientOrderController.getOrders';
import refreshOrders from '@salesforce/apex/ClientOrderController.refreshOrders';
import getOrderItem from '@salesforce/apex/ClientOrderController.getOrderItemLines';
import cancelOrders from '@salesforce/apex/ClientOrderController.cancelOrders';
import retryOrder from '@salesforce/apex/ClientOrderController.retryOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from '@salesforce/resourceUrl/customModalCss';
import { loadStyle } from 'lightning/platformResourceLoader';
import { reduceErrors } from 'c/utils';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';

//Custom Labels
//OrderItemLine
import LAB_SF_CL_ORDERITEMLINE_FIRSTNAME from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_FIRSTNAME';
import LAB_SF_CL_ORDERITEMLINE_LASTNAME from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_LASTNAME';
import LAB_SF_CL_ORDERITEMLINE_EMAIL from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_EMAIL';
import LAB_SF_CL_ORDERITEMLINE_BIRTHDATE from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_BIRTHDATE';
import LAB_SF_CL_ORDERITEMLINE_UNITCOUNT from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_UNITCOUNT';
import LAB_SF_CL_ORDERITEMLINE_UNITAMOUNT from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_UNITAMOUNT';
import LAB_SF_CL_ORDERITEMLINE_TOTALAMOUNT from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_TOTALAMOUNT';
import LAB_SF_CL_ORDERITEMLINE_PARTFINANCEDBYCOMPANY from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_PARTFINANCEDBYCOMPANY';
import LAB_SF_CL_ORDERITEMLINE_STATUSID from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_STATUSID';
import LAB_SF_CL_ORDERITEMLINE_ORDERITEMID from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_ORDERITEMID';
import LAB_SF_CL_ORDERITEMLINE_ORDERITEMLINEID from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_ORDERITEMLINEID';
import LAB_SF_CL_ORDERITEMLINE_EMPLOYEEID from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_EMPLOYEEID';
import LAB_SF_CL_ORDERITEMLINE_EXTERNALREFERENCENUMBER from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_EXTERNALREFERENCENUMBER';
import LAB_SF_CL_ORDERITEMLINE_CREATEDDATE from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_CREATEDDATE';
import LAB_SF_CL_ORDERITEMLINE_CREATEDBY from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_CREATEDBY';
import LAB_SF_CL_ORDERITEMLINE_LASTMODIFIEDDATE from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_LASTMODIFIEDDATE';
import LAB_SF_CL_ORDERITEMLINE_LASTMODIFIEDBY from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_LASTMODIFIEDBY';
//OrderLine
import LAB_SF_CL_ORDERLINE_COMMERCIALNAME from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_COMMERCIALNAME';
import LAB_SF_CL_ORDERLINE_BENEFITFAMILYNAME from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_BENEFITFAMILYNAME';
import LAB_SF_CL_ORDERLINE_PREFERREDLOADDATE from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_PREFERREDLOADDATE';
import LAB_SF_CL_ORDERLINE_PRODUCTCLASSFAMILYID from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_PRODUCTCLASSFAMILYID';
import LAB_SF_CL_ORDERLINE_TOTALLOADAMOUNT from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_TOTALLOADAMOUNT';
import LAB_SF_CL_ORDERLINE_ITEMLINECOUNT from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_ITEMLINECOUNT';
import LAB_SF_CL_ORDERLINE_EVENTEXPIRYDATE from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_EVENTEXPIRYDATE';
import LAB_SF_CL_ORDERLINE_CREATEDDATE from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_CREATEDDATE';
import LAB_SF_CL_ORDERLINE_CREATEDBY from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_CREATEDBY';
import LAB_SF_CL_ORDERLINE_BENEFITID from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_BENEFITID';
import LAB_SF_CL_ORDERLINE_STATUS from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_STATUS';
import LAB_SF_CL_ORDERLINE_PRODUCTCLASSCODE from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_PRODUCTCLASSCODE';

//Order
import LAB_SF_CL_ORDER_ORDER_NUMBER from '@salesforce/label/c.LAB_SF_CL_ORDER_ORDER_NUMBER';
import LAB_SF_CL_ORDER_PURCHASE_ORDER_REFERENCE from '@salesforce/label/c.LAB_SF_CL_ORDER_PURCHASE_ORDER_REFERENCE';
import LAB_SF_CL_ORDER_ORDER_CREATION_DATETIME from '@salesforce/label/c.LAB_SF_CL_ORDER_ORDER_CREATION_DATETIME';
import LAB_SF_CL_ORDER_FINANCIAL_VALIDATION_DATE from '@salesforce/label/c.LAB_SF_CL_ORDER_FINANCIAL_VALIDATION_DATE';
import LAB_SF_CL_ORDER_FINANCIAL_VALIDATION_TYPE from '@salesforce/label/c.LAB_SF_CL_ORDER_FINANCIAL_VALIDATION_TYPE';
import LAB_SF_CL_ORDER_TOTAL_AMOUNT from '@salesforce/label/c.LAB_SF_CL_ORDER_TOTAL_AMOUNT';
import LAB_SF_CL_ORDER_STATE from '@salesforce/label/c.LAB_SF_CL_ORDER_STATE';
import LAB_SF_CL_ORDER_BILLING_ACCOUNT_NUMBER from '@salesforce/label/c.LAB_SF_CL_ORDER_BILLING_ACCOUNT_NUMBER';
import LAB_SF_CL_ORDER_TITLE from '@salesforce/label/c.LAB_SF_CL_ORDER_TITLE';
import LAB_SF_CL_ORDER_ORDERSUBMISSIONDATE from '@salesforce/label/c.LAB_SF_CL_ORDER_ORDERSUBMISSIONDATE';
import LAB_SF_CL_ORDER_STATUS from '@salesforce/label/c.LAB_SF_CL_ORDER_STATUS';
import LAB_SF_CL_ORDER_ITEMLINECOUNT from '@salesforce/label/c.LAB_SF_CL_ORDER_ITEMLINECOUNT';
import LAB_SF_CL_ORDER_DISTINCT_EMPLOYEE_COUNT from '@salesforce/label/c.LAB_SF_CL_ORDER_DISTINCT_EMPLOYEE_COUNT';
import LAB_SF_CL_ORDER_CREATED_BY_CONTACT from '@salesforce/label/c.LAB_SF_CL_ORDER_CREATED_BY_CONTACT';
import LAB_SF_CL_ORDER_SELECTED_PAYMENT_MEAN from '@salesforce/label/c.LAB_SF_CL_ORDER_SELECTED_PAYMENT_MEAN';
import LAB_SF_CL_ORDER_FIRST_INVOICE_DATE from '@salesforce/label/c.LAB_SF_CL_ORDER_FIRST_INVOICE_DATE';
import LAB_SF_CL_CANCEL_ORDER from '@salesforce/label/c.LAB_SF_CL_CANCEL_ORDER';
import LAB_SF_CL_DETAILS_ORDER from '@salesforce/label/c.LAB_SF_CL_DETAILS_ORDER';
import LAB_SF_CL_ORDER_CANCELLED from '@salesforce/label/c.LAB_SF_CL_ORDER_CANCELLED';
import LAB_SF_CL_NO_RECORD_FOUND from '@salesforce/label/c.LAB_SF_CL_NO_RECORD_FOUND';
import LAB_SF_CANCEL_ORDER_CONFIRMATION_MSG from '@salesforce/label/c.LAB_SF_CANCEL_ORDER_CONFIRMATION_MSG';
import LAB_SF_ASSET_ConfirmationButton from '@salesforce/label/c.LAB_SF_ASSET_ConfirmationButton';
import LABS_SF_Opp_Price_Cancel from '@salesforce/label/c.LABS_SF_Opp_Price_Cancel';
import LAB_SF_CL_RETRY_ORDER_SUBMISSION from '@salesforce/label/c.LAB_SF_CL_RETRY_ORDER_SUBMISSION';
import LAB_SF_CL_RETRY_ORDER_MESSAGE from '@salesforce/label/c.LAB_SF_CL_RETRY_ORDER_MESSAGE';
import LAB_SF_CL_LOAD_IN_ERROR from '@salesforce/label/c.LAB_SF_CL_LOAD_IN_ERROR';
import LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR from '@salesforce/label/c.LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR';
import LAB_SF_CL_PROCESSING_EVENT_TITLE from '@salesforce/label/c.LAB_SF_CL_PROCESSING_EVENT_TITLE';
import LAB_SF_CL_ORDER_PROMO_CODE from '@salesforce/label/c.LAB_SF_CL_ORDER_PROMO_CODE';

const ACTIONS = [
  {
    label: 'Show Details',
    name: 'show_items'
  }
];

const ORDERLINE_COLS = [
  {
    label: LAB_SF_CL_ORDERLINE_COMMERCIALNAME,
    fieldName: 'commercialName'
  },
  {
    label: LAB_SF_CL_ORDERLINE_BENEFITFAMILYNAME,
    fieldName: 'benefitFamilyName'
  },
  {
    label: LAB_SF_CL_ORDERLINE_PREFERREDLOADDATE,
    fieldName: 'preferredLoadDate',
    type: 'date',
    typeAttributes: {
      day: 'numeric',
      month: 'numeric',
      year: 'numeric'
    }
  },
  {
    label: LAB_SF_CL_ORDERLINE_TOTALLOADAMOUNT,
    fieldName: 'totalLoadAmount',
    type: 'currency'
  },
  {
    label: LAB_SF_CL_ORDERLINE_ITEMLINECOUNT,
    fieldName: 'itemLineCount'
  },
  {
    label: LAB_SF_CL_ORDERLINE_STATUS,
    fieldName: 'status'
  },
  {
    type: 'action',
    typeAttributes: {
      rowActions: ACTIONS
    }
  }
];

const ORDER_LINE_ITEM_COLS = [
  {
    label: LAB_SF_CL_ORDERITEMLINE_ORDERITEMLINEID,
    fieldName: 'orderItemLineId'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_ORDERITEMID,
    fieldName: 'orderItemId'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_FIRSTNAME,
    fieldName: 'firstName'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_LASTNAME,
    fieldName: 'lastName'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_EMAIL,
    fieldName: 'email',
    type: 'email'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_BIRTHDATE,
    fieldName: 'birthDate',
    type: 'date',
    typeAttributes: {
      day: 'numeric',
      month: 'numeric',
      year: 'numeric'
    }
  },
  {
    type: 'url',
    label: LAB_SF_CL_ORDERITEMLINE_EMPLOYEEID,
    fieldName: 'employeeLink',
    typeAttributes: {
      label: {
        fieldName: 'employeeId'
      }
    }
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_UNITCOUNT,
    fieldName: 'unitCount'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_UNITAMOUNT,
    fieldName: 'unitAmount',
    type: 'currency'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_TOTALAMOUNT,
    fieldName: 'totalAmount',
    type: 'currency'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_PARTFINANCEDBYCOMPANY,
    fieldName: 'partFinancedByCompany'
  },
  {
    label: LAB_SF_CL_ORDERITEMLINE_STATUSID,
    fieldName: 'statusId'
  }
];

export default class erClientOrder extends LightningElement {
  @api recordId;
  columns = [
    {
      label: LAB_SF_CL_ORDER_ORDER_NUMBER,
      fieldName: 'orderNumber'
    },
    {
      label: LAB_SF_CL_ORDER_PURCHASE_ORDER_REFERENCE,
      fieldName: 'purchaseOrderReference'
    },
    {
      label: LAB_SF_CL_ORDER_ORDER_CREATION_DATETIME,
      fieldName: 'orderCreationDateTime',
      type: 'date',
      typeAttributes: {
        day: 'numeric',
        month: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }
    },
    {
      label: LAB_SF_CL_ORDER_STATUS,
      fieldName: 'status'
    },
    {
      label: LAB_SF_CL_ORDER_TOTAL_AMOUNT,
      fieldName: 'totalLoadAmount',
      type: 'currency'
    },
    {
      label: LAB_SF_CL_ORDER_PROMO_CODE,
      fieldName: 'orderPromoCode'
    },
    {
      label: LAB_SF_CL_ORDER_ITEMLINECOUNT,
      fieldName: 'itemLineCount'
    },
    {
      label: LAB_SF_CL_ORDER_DISTINCT_EMPLOYEE_COUNT,
      fieldName: 'distinctEmployeeCount'
    },
    {
      label: LAB_SF_CL_ORDER_CREATED_BY_CONTACT,
      fieldName: 'createdbyContactId'
    },
    {
      label: LAB_SF_CL_ORDER_SELECTED_PAYMENT_MEAN,
      fieldName: 'selectedPaymentMean'
    },
    {
      label: LAB_SF_CL_ORDER_FINANCIAL_VALIDATION_DATE,
      fieldName: 'financialValidationDate',
      type: 'date',
      typeAttributes: {
        day: 'numeric',
        month: 'numeric',
        year: 'numeric'
      }
    },
    {
      label: LAB_SF_CL_ORDER_FINANCIAL_VALIDATION_TYPE,
      fieldName: 'financialValidationType'
    },
    {
      label: LAB_SF_CL_ORDER_FIRST_INVOICE_DATE,
      fieldName: 'firstInvoiceDate',
      type: 'date',
      typeAttributes: {
        day: 'numeric',
        month: 'numeric',
        year: 'numeric'
      }
    },
    {
      label: LAB_SF_CL_ORDER_BILLING_ACCOUNT_NUMBER,
      fieldName: 'billingAccountNumber'
    },
    {
      label: LAB_SF_CL_ORDER_ORDERSUBMISSIONDATE,
      fieldName: 'orderSubmissionDate',
      type: 'date',
      typeAttributes: {
        day: 'numeric',
        month: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }
    },
    {
      label: LAB_SF_CL_ORDER_STATE,
      fieldName: 'state'
    },
    {
      type: 'action',
      typeAttributes: { rowActions: this.getRowActions.bind(this) }
    }
  ];

  columnsOrderline = ORDERLINE_COLS;
  columnsOrderlineItem = ORDER_LINE_ITEM_COLS;

  // Variable for Order Level One
  @track islevelOne = true;
  orderData;
  allOrderData;
  totalOrderData;

  // Variable for Order Level Two
  @track islevelTwo = false;
  orderLineData;

  // Variable for Order Level Three
  @track islevelThree = false;
  orderlineItemData;
  allOrderlineItemData;
  totalOrderlineItemData;

  orderId;
  orderNumber;
  billingAccount;
  orderItemId;

  loadOrderId;
  processEventOrderId;

  loaded = false;

  @track orderLinePageIndex;
  @track pageSize = 10;

  error;
  @track isDialogVisible = false;
  @track rowToBeCancelled;

  @wire(getRecord, {
    recordId: USER_ID,
    fields: [PROFILE_NAME_FIELD]
  })
  userRecord({ error, data }) {
    if (data) {
      this.profileName = getFieldValue(data, PROFILE_NAME_FIELD);
    } else if (error) {
      // Handle error
      console.error(error);
    }
  }

  get userProfileName() {
    return this.profileName;
  }

  connectedCallback() {
    loadStyle(this, modal);
  }

  LABEL = {
    LAB_SF_CL_ORDER_TITLE,
    LAB_SF_CL_NO_RECORD_FOUND,
    LAB_SF_CL_CANCEL_ORDER,
    LAB_SF_CL_ORDER_CANCELLED,
    LAB_SF_CL_DETAILS_ORDER,
    LAB_SF_CANCEL_ORDER_CONFIRMATION_MSG,
    LAB_SF_ASSET_ConfirmationButton,
    LABS_SF_Opp_Price_Cancel,
    LAB_SF_CL_LOAD_IN_ERROR,
    LAB_SF_CL_PROCESSING_EVENT_TITLE,
    LAB_SF_CL_RETRY_ORDER_SUBMISSION,
    LAB_SF_CL_RETRY_ORDER_MESSAGE
  };

  getRowActions(row, doneCallback) {
    const actions = [];
    actions.push({
      label: this.LABEL.LAB_SF_CL_DETAILS_ORDER,
      name: 'show_items'
    });

    let pName = this.userProfileName;
    console.log('>>>>> ALK - pName : ' + pName);

    if (
      pName === 'Customer Service' &&
      (row['status'] === 'waitingForFinancialValidation' ||
        row['status'] === 'submissionInError' ||
        row['status'] === 'Draft')
    ) {
      actions.push({
        label: this.LABEL.LAB_SF_CL_CANCEL_ORDER,
        name: 'cancel_order'
      });
    }

    if (row['status'] === 'submissionInError') {
      actions.push({
          label: this.LABEL.LAB_SF_CL_RETRY_ORDER_SUBMISSION,
          name: 'retry_submission'
      });
    }

    if (row['status'] != 'cancelled') {
      actions.push({
        label: LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR,
        name: 'load_errors'
      });
    }

    actions.push({
      label: LAB_SF_CL_PROCESSING_EVENT_TITLE,
      name: 'processing_events'
    });
    setTimeout(() => {
      doneCallback(actions);
    }, 200);
  }

  @wire(getOrders, {
    objectId: '$recordId',
    pageIndex: 0,
    pageSize: 200
  })
  wiredRegisterData({ error, data }) {
    if (data) {
      this.totalOrderData = data.length;
      this.allOrderData = data;
      this.orderData = this.allOrderData.slice(0, this.pageSize);
      this.error = undefined;
      this.loaded = true;
    } else if (error) {
      this.error = error;
      this.orderData = undefined;
      this.loaded = true;
    }
  }

  handlePagination(event) {
    const start = (event.detail - 1) * this.pageSize;
    const end = this.pageSize * event.detail;
    this.orderData = this.allOrderData.slice(start, end);
  }

  handleOrderlineItemPagination(event) {
    const start = (event.detail - 1) * this.pageSize;
    const end = this.pageSize * event.detail;
    this.orderlineItemData = this.allOrderlineItemData.slice(start, end);
  }

  fetchOrders() {
    refreshOrders({
      objectId: this.recordId,
      pageIndex: this.pageIndex,
      pageSize: 200
    })
      .then((result) => {
        this.totalOrderData = data.length;
        this.allOrderData = data;
        this.orderData = this.allOrderData.slice(0, this.pageSize);
        this.error = undefined;
        this.loaded = true;
      })
      .catch((error) => {
        this.error = error;
        this.orderData = undefined;
        this.loaded = true;
      });
  }

  firstRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    if (actionName == 'show_items') {
      this.islevelOne = false;
      this.islevelTwo = true;
      this.islevelThree = false;
      this.orderNumber = row.orderNumber;
      this.orderId = row.orderId;
      this.orderLineData = row.orderlines;
    }
    if (actionName == 'cancel_order') {
      this.rowToBeCancelled = event.detail.row;
      this.isDialogVisible = true;
    }
    if (actionName == 'load_errors') {
      this.loadOrderId = row.orderId;
      this.orderNumber = row.orderNumber;
      console.log('//NGO order Id : ' + this.loadOrderId);
    } else if (actionName == 'processing_events') {
      this.processEventOrderId = row.orderId;
      this.orderNumber = row.orderNumber;
      this.billingAccount = row.billingAccountNumber;
      console.log('//NGO order Id : ' + this.processEventOrderId);
    }else if (actionName === 'retry_submission'){
      this.loaded = false;
      const row = event.detail.row;
      retryOrder({
          orderId: row.orderId, 
          accountId : this.recordId
      }).then(result => {
              console.log('result : ' + JSON.stringify(result));
              this.error = undefined;
              this.loaded = true;

              this.dispatchEvent(
                  new ShowToastEvent({
                      title: 'Success',
                      message: this.LABEL.LAB_SF_CL_RETRY_ORDER_MESSAGE,
                      variant: 'success'
                  })
              );
          })
          .catch(error => {
              this.loaded = true;
              var webServiceError = 'Internal Error';
              try{
                  webServiceError = reduceErrors(error);
                  if(webServiceError){ webServiceError = JSON.parse(webServiceError).meta.messages[0].text; }
              }catch(e){console.log('retry orders : ' + e)}
              this.dispatchEvent(
                  new ShowToastEvent({
                      title: 'Error Message',
                      message: webServiceError,
                      variant: 'warning'
                  })
              );
          })
    }
  }

  secondRowAction(event) {
    this.loaded = false;
    this.islevelOne = false;
    this.islevelTwo = false;
    this.islevelThree = true;
    const row = event.detail.row;
    this.orderItemId = row.orderItemId;
    getOrderItem({
      objectId: this.recordId,
      orderId: this.orderId,
      pageIndex: 0,
      pageSize: 200
    })
      .then((result) => {
        this.totalOrderlineItemData = result.length;
        this.allOrderlineItemData = result;
        this.orderlineItemData = this.allOrderlineItemData.slice(0, this.pageSize);

        this.error = undefined;
        this.loaded = true;
      })
      .catch((error) => {
        this.error = error;
        this.orderData = undefined;
        this.loaded = true;
      });
  }

  handleConfirmationModal(event) {
    let message = event.detail;
    if (message === 'confirm') {
      let row = this.rowToBeCancelled;
      cancelOrders({
        objectId: this.recordId,
        orderId: row.orderId,
        orderNumber: row.orderNumber
      })
        .then((result) => {
          console.log('result : ' + JSON.stringify(result));
          this.error = undefined;
          this.loaded = true;
          this.fetchOrders();
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.LABEL.LAB_SF_CL_ORDER_CANCELLED,
              message: '',
              variant: 'success'
            })
          );
        })
        .catch((error) => {
          this.loaded = true;
          var webServiceError = 'Internal Error';
          try {
            webServiceError = reduceErrors(error);
            if (webServiceError) {
              webServiceError = JSON.parse(webServiceError).meta.messages[0].text;
            }
          } catch (e) {
            console.log('Cancel order errors : ' + e);
          }
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error Message',
              message: webServiceError,
              variant: 'warning'
            })
          );
        });
    }
    this.isDialogVisible = false;
  }

  handleNavigateToLevel1(event) {
    event.preventDefault();
    this.loadOrderId = '';
    this.processEventOrderId = '';
  }

  get showOrderPage() {
    return this.loadOrderId || this.processEventOrderId;
  }
}