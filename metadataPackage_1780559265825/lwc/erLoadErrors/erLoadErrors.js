/**
 * Created by noorgoolamnabee on 19/06/2023.
 */

import { LightningElement, wire, api, track } from 'lwc';
import getLoads from '@salesforce/apex/ClientOrderController.getOrderLoad';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from '@salesforce/resourceUrl/customModalCss';
import { loadStyle } from 'lightning/platformResourceLoader';
import retryLoad from '@salesforce/apex/ClientOrderController.retryLoad';

//Custom Labels
import LAB_SF_CL_LOAD_LOADID from '@salesforce/label/c.LAB_SF_CL_LOAD_LOADID';
import LAB_SF_CL_LOAD_ISSUERACCOUNTNUMBER from '@salesforce/label/c.LAB_SF_CL_LOAD_ISSUERACCOUNTNUMBER';
import LAB_SF_CL_LOAD_WALLET from '@salesforce/label/c.LAB_SF_CL_LOAD_WALLET';
import LAB_SF_CL_LOAD_AMOUNT from '@salesforce/label/c.LAB_SF_CL_LOAD_AMOUNT';
import LAB_SF_CL_LOAD_EXPIRYDATE from '@salesforce/label/c.LAB_SF_CL_LOAD_EXPIRYDATE';
import LAB_SF_CL_LOAD_PAYERNAME from '@salesforce/label/c.LAB_SF_CL_LOAD_PAYERNAME';
import LAB_SF_CL_LOAD_PRIORITY from '@salesforce/label/c.LAB_SF_CL_LOAD_PRIORITY';
import LAB_SF_CL_LOAD_EMPLOYEEID from '@salesforce/label/c.LAB_SF_CL_LOAD_EMPLOYEEID';
import LAB_SF_CL_LOAD_COMMERCIALNAME from '@salesforce/label/c.LAB_SF_CL_LOAD_COMMERCIALNAME';
import LAB_SF_CL_LOAD_ORDERNUMBER from '@salesforce/label/c.LAB_SF_CL_LOAD_ORDERNUMBER';
import LAB_SF_CL_LOAD_CLIENTNAME from '@salesforce/label/c.LAB_SF_CL_LOAD_CLIENTNAME';
import LAB_SF_CL_LOAD_CREATEDDATE from '@salesforce/label/c.LAB_SF_CL_LOAD_CREATEDDATE';
import LAB_SF_CL_LOAD_LASTMODIFIEDDATE from '@salesforce/label/c.LAB_SF_CL_LOAD_LASTMODIFIEDDATE';
import LAB_SF_CL_LOAD_STATUS from '@salesforce/label/c.LAB_SF_CL_LOAD_STATUS';
import LAB_SF_CL_LOAD_IN_ERROR from '@salesforce/label/c.LAB_SF_CL_LOAD_IN_ERROR';
import LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR from '@salesforce/label/c.LAB_SF_CL_LOAD_GET_LOADS_IN_ERROR';
import LAB_SF_CL_LOAD_GET_LOADS_MESSAGE from '@salesforce/label/c.LAB_SF_CL_LOAD_GET_LOADS_MESSAGE';
import LAB_SF_CL_NO_RECORD_FOUND from '@salesforce/label/c.LAB_SF_CL_NO_RECORD_FOUND';
import LAB_SF_CL_LOAD_RETRY from '@salesforce/label/c.LAB_SF_CL_LOAD_RETRY';

export default class LoadErrors extends LightningElement {
  @api orderId;
  @api recordId;
  @api queryTypeParam;
  loadData;
  allLoadData;
  totalLoadData;
  loaded = false;
  @track pageSize = 10;
  error;

  @wire(getLoads, {
    orderId: '$orderId',
    queryTypeParam: '$queryTypeParam',
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
      label: LAB_SF_CL_LOAD_LOADID,
      fieldName: 'loadId'
    },
    {
      label: LAB_SF_CL_LOAD_ISSUERACCOUNTNUMBER,
      fieldName: 'issuerAccountNumber'
    },
    {
      label: LAB_SF_CL_LOAD_WALLET,
      fieldName: 'wallet'
    },
    {
      label: LAB_SF_CL_LOAD_AMOUNT,
      fieldName: 'amount',
      type: 'currency'
    },
    {
      label: LAB_SF_CL_LOAD_EXPIRYDATE,
      fieldName: 'expiryDate',
      type: 'date',
      typeAttributes: {
        day: 'numeric',
        month: 'numeric',
        year: 'numeric'
      }
    },
    {
      label: LAB_SF_CL_LOAD_PAYERNAME,
      fieldName: 'payerName'
    },
    {
      label: LAB_SF_CL_LOAD_PRIORITY,
      fieldName: 'priority'
    },
    {
      label: LAB_SF_CL_LOAD_EMPLOYEEID,
      fieldName: 'employeeId'
    },
    {
      label: LAB_SF_CL_LOAD_COMMERCIALNAME,
      fieldName: 'commercialName'
    },
    {
      label: LAB_SF_CL_LOAD_ORDERNUMBER,
      fieldName: 'orderNumber'
    },
    {
      label: LAB_SF_CL_LOAD_CLIENTNAME,
      fieldName: 'clientName'
    },
    {
      label: LAB_SF_CL_LOAD_CREATEDDATE,
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
    },
    {
      label: LAB_SF_CL_LOAD_LASTMODIFIEDDATE,
      fieldName: 'lastModifiedDate',
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
      label: LAB_SF_CL_LOAD_STATUS,
      fieldName: 'status'
    },
    {
      type: 'action',
      typeAttributes: {
        rowActions: [
          {
            label: LAB_SF_CL_LOAD_RETRY,
            name: 'retry'
          }
        ]
      }
    }
  ];

  LABEL = {
    LAB_SF_CL_NO_RECORD_FOUND
  };

  connectedCallback() {
    loadStyle(this, modal);
  }

  handleRetryAction(event) {
    const actionName = event.detail.action.name;

    if (actionName == 'retry') {
      const row = event.detail.row;
      console.log('NGO' + row.loadId);
      retryLoad({
        loadId: row.loadId,
        recordId : this.recordId ,
        orderNumber : row.orderNumber
      })
        .then((result) => {
          console.log('result : ' + JSON.stringify(result));
          this.error = undefined;
          this.loaded = true;

          this.dispatchEvent(
            new ShowToastEvent({
              title: LAB_SF_CL_LOAD_GET_LOADS_MESSAGE,
              message: LAB_SF_CL_LOAD_GET_LOADS_MESSAGE,
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
            console.log('retry orders : ' + e);
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
  }

  handlePagination(event) {
    const start = (event.detail - 1) * this.pageSize;
    const end = this.pageSize * event.detail;
    this.loadData = this.allLoadData.slice(start, end);
  }
}