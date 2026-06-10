/**
 * Created by noorgoolamnabee on 04/01/2023.
 */
import { LightningElement, wire, api, track } from 'lwc';
import getOrders from '@salesforce/apex/ClientOrderController.getEmployeeOrders';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from '@salesforce/resourceUrl/customModalCss';
import { loadStyle } from 'lightning/platformResourceLoader';

//Custom Labels
import LAB_SF_CL_ORDER_ORDER_NUMBER from '@salesforce/label/c.LAB_SF_CL_ORDER_ORDER_NUMBER';
import LAB_SF_CL_ORDERLINE_PREFERREDLOADDATE from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_PREFERREDLOADDATE';
import LAB_SF_CL_ORDERLINE_COMMERCIALNAME from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_COMMERCIALNAME';
import LAB_SF_CL_ORDERITEMLINE_FIRSTNAME from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_FIRSTNAME';
import LAB_SF_CL_ORDERITEMLINE_LASTNAME from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_LASTNAME';
import LAB_SF_CL_ORDERITEMLINE_EMAIL from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_EMAIL';
import LAB_SF_CL_ORDERITEMLINE_BIRTHDATE from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_BIRTHDATE';
import LAB_SF_CL_ORDERITEMLINE_TOTALAMOUNT from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_TOTALAMOUNT';
import LAB_SF_CL_ORDERITEMLINE_STATUSID from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_STATUSID';
import LAB_SF_CL_ORDERITEMLINE_EMPLOYEEID from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_EMPLOYEEID';
import LAB_SF_CL_ORDER_EMPLOYEE_TITLE from '@salesforce/label/c.LAB_SF_CL_ORDER_EMPLOYEE_TITLE';
import LAB_SF_CL_NO_RECORD_FOUND from '@salesforce/label/c.LAB_SF_CL_NO_RECORD_FOUND';
import LAB_SF_CL_LOAD_IN_ERROR from '@salesforce/label/c.LAB_SF_CL_LOAD_IN_ERROR';
import LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR from '@salesforce/label/c.LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR';
import LAB_SF_CL_ORDERITEMLINE_ORDERITEMLINEID from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_ORDERITEMLINEID';

export default class ErEmployeeOrder extends LightningElement {
  @api recordId;

  orderData;
  allOrderData;
  totalOrderData;

  orderLineItemId;
  loaded = false;
  @track pageSize = 10;
  error;

  columnsOrder = [
    {
      label: LAB_SF_CL_ORDER_ORDER_NUMBER,
      fieldName: 'orderNumber'
    },
    {
      label: LAB_SF_CL_ORDERITEMLINE_ORDERITEMLINEID,
      fieldName: 'orderLineItemId'
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
      label: LAB_SF_CL_ORDERLINE_COMMERCIALNAME,
      fieldName: 'commercialName'
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
      label: LAB_SF_CL_ORDERITEMLINE_TOTALAMOUNT,
      fieldName: 'totalAmount',
      type: 'currency'
    },
    {
      label: LAB_SF_CL_ORDERITEMLINE_STATUSID,
      fieldName: 'status'
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
      type: 'action',
      typeAttributes: {
        rowActions: [
          {
            label: LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR,
            name: 'load_errors'
          }
        ]
      }
    }
  ];

  connectedCallback() {
    loadStyle(this, modal);
  }

  LABEL = {
    LAB_SF_CL_ORDER_EMPLOYEE_TITLE,
    LAB_SF_CL_NO_RECORD_FOUND,
    LAB_SF_CL_LOAD_IN_ERROR,
    LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR
  };

  @wire(getOrders, {
    objectId: '$recordId',
    pageIndex: 0,
    pageSize: 200
  })
  wiredRegisterData({ error, data }) {
    if (data) {
      console.log('data : ' + JSON.stringify(data));
      this.totalOrderData = data.length;
      this.allOrderData = data;
      this.orderData = this.allOrderData.slice(0, this.pageSize);
      this.error = undefined;
      this.loaded = true;
    } else if (error) {
      console.log('data : ' + JSON.stringify(error));
      this.error = error;
      this.orderData = undefined;
      this.loaded = true;
    }
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;

    if (actionName == 'load_errors') {
      const row = event.detail.row;
      this.orderLineItemId = row.orderLineItemId;
      //this.orderId = "13768";
      console.log('//NGO order Id : ' + this.orderLineItemId);
    }
  }

  handlePagination(event) {
    const start = (event.detail - 1) * this.pageSize;
    const end = this.pageSize * event.detail;
    this.orderData = this.allOrderData.slice(start, end);
  }

  handleNavigateToLevel1(event) {
    event.preventDefault();
    this.orderLineItemId = '';
  }
}