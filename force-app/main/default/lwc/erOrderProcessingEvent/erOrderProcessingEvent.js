/**
 * Created by noorgoolamnabee on 18/07/2023.
 */

import { LightningElement, wire, api, track } from 'lwc';
import getOrderProcessingEvents from '@salesforce/apex/ClientOrderController.getOrderProcessingEvents';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from '@salesforce/resourceUrl/customModalCss';
import { loadStyle } from 'lightning/platformResourceLoader';

//Custom Labels
import LAB_SF_CL_ORDER_ORDER_NUMBER from '@salesforce/label/c.LAB_SF_CL_ORDER_ORDER_NUMBER';
import LAB_SF_CL_ORDERITEMLINE_CREATEDDATE from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_CREATEDDATE';
import LAB_SF_CL_ORDER_BILLING_ACCOUNT_NUMBER from '@salesforce/label/c.LAB_SF_CL_ORDER_BILLING_ACCOUNT_NUMBER';
import LAB_SF_CL_NO_RECORD_FOUND from '@salesforce/label/c.LAB_SF_CL_NO_RECORD_FOUND';
import LAB_SF_CL_ORDER_PROCESSING_EVENT from '@salesforce/label/c.LAB_SF_CL_ORDER_PROCESSING_EVENT';
import LAB_SF_CL_ORDER_FINAL_ORDER_STATE from '@salesforce/label/c.LAB_SF_CL_ORDER_FINAL_ORDER_STATE';
import LAB_SF_CL_ORDER_ERROR_CODE from '@salesforce/label/c.LAB_SF_CL_ORDER_ERROR_CODE';
import LAB_SF_CL_ORDER_ERROR_DETAIL from '@salesforce/label/c.LAB_SF_CL_ORDER_ERROR_DETAIL';

export default class ErOrderProcessingEvent extends LightningElement {
  @api orderId;
  @api orderNumber;
  @api billingAccount;
  loadData;
  allLoadData;
  totalLoadData;
  loaded = false;
  @track pageSize = 10;
  error;

  @wire(getOrderProcessingEvents, {
    orderId: '$orderId',
    orderNumber: '$orderNumber',
    billingAccount: '$billingAccount',
    pageIndex: 0,
    pageSize: 200
  })
  wiredRegisterData({ error, data }) {
    if (data) {
      console.log('data : ' + JSON.stringify(data));
      this.totalLoadData = data.length;
      this.allLoadData = data;
      this.loadData = this.allLoadData.slice(0, this.pageSize);
      this.error = undefined;
      this.loaded = true;
    } else if (error) {
      console.log('data : ' + JSON.stringify(error));
      this.error = error;
      this.loadData = undefined;
      this.loaded = true;
    }
  }

  columnsOrder = [
    {
      label: LAB_SF_CL_ORDER_ORDER_NUMBER,
      fieldName: 'orderNumber'
    },
    {
      label: LAB_SF_CL_ORDER_BILLING_ACCOUNT_NUMBER,
      fieldName: 'billingAccount'
    },
    {
      label: LAB_SF_CL_ORDER_PROCESSING_EVENT,
      fieldName: 'processingEvent'
    },
    {
      label: LAB_SF_CL_ORDER_FINAL_ORDER_STATE,
      fieldName: 'finalOrderState'
    },
    {
      label: LAB_SF_CL_ORDER_ERROR_CODE,
      fieldName: 'errorCode'
    },
    {
      label: LAB_SF_CL_ORDER_ERROR_DETAIL,
      fieldName: 'errorDetail'
    },
    {
      label: LAB_SF_CL_ORDERITEMLINE_CREATEDDATE,
      fieldName: 'createdDate',
      type: 'date',
      typeAttributes: {
        day: 'numeric',
        month: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }
    }
  ];

  LABEL = {
    LAB_SF_CL_NO_RECORD_FOUND
  };

  connectedCallback() {
    loadStyle(this, modal);
  }

  handlePagination(event) {
    const start = (event.detail - 1) * this.pageSize;
    const end = this.pageSize * event.detail;
    this.loadData = this.allLoadData.slice(start, end);
  }
}