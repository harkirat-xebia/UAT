/**
 * @author: AAZ
 * @date: 12/03/2023
 * @desc: lcerGetEmployeeCodes
 */

import { api, LightningElement, wire } from 'lwc';
import getERCodes from '@salesforce/apex/ClientOrderController.getEdenredCodes';
import sendERCOde from '@salesforce/apex/ClientOrderController.sendEdnredCode';
import modal_80 from '@salesforce/resourceUrl/modal_80';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SMARTER_EMPLOYEE_ID from '@salesforce/schema/ER_Employee__c.ER_SmartER_Employee_Id__c';
import USER_ID from '@salesforce/schema/ER_Employee__c.User_EdenredPlus__r.ER_External_Reference__c';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

//LABELS
import processing from '@salesforce/label/c.LAB_SF_PROCESSING';
import close from '@salesforce/label/c.LABS_SF_CLOSE';
import employeeId from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_EMPLOYEEID';
import edenredCodeId from '@salesforce/label/c.LAB_SF_CL_ORDERITEMLINE_EDENREDCODEID';
import productClassId from '@salesforce/label/c.LAB_SF_CL_ORDERLINE_PRODUCTCLASSFAMILYID';
import userId from '@salesforce/label/c.LAB_SF_USER_ID';
import issuerAccountNumber from '@salesforce/label/c.LAB_SF_ISSUER_ACCOUNT_NUMBER';
import isProvisioned from '@salesforce/label/c.LAB_SF_IS_PROVISIONED';
import isSent from '@salesforce/label/c.LAB_SF_IS_SENT';
import lastNotifDate from '@salesforce/label/c.LAB_SF_LAST_NOTIFICATION_DATE';
import actionDone from '@salesforce/label/c.LAB_SF_SUCCESS_MSG';
import send from '@salesforce/label/c.LAB_SF_SEND';
import contactAdminError from '@salesforce/label/c.LAB_SF_PLEASE_CONTACT_YOUR_ADMIN';
import noDataFoundLbl from '@salesforce/label/c.LAB_SF_NO_DATA_FOUND';

export default class LcerGetEmployeeCodes extends LightningElement {
  @api recordId;
  error;
  data = [];
  showLoadingSpinner = true;
  noDataFound = false;

  label = {
    processing,
    close,
    employeeId,
    edenredCodeId,
    productClassId,
    userId,
    issuerAccountNumber,
    isProvisioned,
    isSent,
    lastNotifDate,
    actionDone,
    send,
    contactAdminError,
    noDataFoundLbl
  };

  @wire(getRecord, { recordId: '$recordId', fields: [SMARTER_EMPLOYEE_ID, USER_ID] }) employee;

  /*columns = [
        {label: this.label.employeeId, fieldName: 'employeeId', type: 'text'},
        {label: this.label.edenredCodeId, fieldName: 'edenredCodeId', type: 'text'},
        {label: this.label.productClassId, fieldName: 'productClassId', type: 'text'},
        {label: this.label.userId, fieldName: 'userId', type: 'text'},
        {label: this.label.issuerAccountNumber, fieldName: 'issuerAccountNumber', type: 'test'},
        {label: this.label.isProvisioned, fieldName: 'isProvisioned', type: 'boolean'},
        {label: this.label.isSent, fieldName: 'isSent', type: 'boolean'},
        {label: this.label.lastNotifDate, fieldName: 'lastNotifDate', type: 'date', typeAttributes: {day: 'numeric', month: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true}},
        {type:"button", fixedWidth: 150,
            typeAttributes: {
                label: 'Send',
                name: 'send',
                variant: 'brand'
            }
        },
    ];*/

  connectedCallback() {
    Promise.all([loadStyle(this, modal_80)]);
  }

  @wire(getERCodes, { employeeId: '$recordId' })
  wiredBalance({ error, data }) {
    if (data) {
      let erCodeData = JSON.parse(data);
      if (erCodeData.meta.status === 'Succeeded') {
        this.error = undefined;
        let currentData = [];

        if (erCodeData.data.length > 0) {
          erCodeData.data.forEach((row) => {
            let rowData = {};
            rowData.employeeId = getFieldValue(this.employee.data, SMARTER_EMPLOYEE_ID); //(row.hasOwnProperty('employeeId') ? row.employeeId : '');
            rowData.edenredCodeId = row.edenredCodeId;
            rowData.productClassId = row.productClassFamilyId;
            rowData.userId = getFieldValue(this.employee.data, USER_ID); //(row.hasOwnProperty('userId') ? row.userId : '');
            rowData.isProvisioned = row.isProvisioned;
            rowData.isSent = row.isSent;
            rowData.issuerAccountNumber = row.hasOwnProperty('issuerAccountNumber') ? row.issuerAccountNumber : '';
            rowData.lastNotifDate = row.lastNotificationDateTime;
            currentData.push(rowData);
          });

          this.data = currentData;
          this.noDataFound = false;
        } else {
          console.log('>>>>> ALK - No data found');
          this.data = [];
          this.noDataFound = true;
        }
      }
      this.showLoadingSpinner = false;
    } else if (error) {
      this.error = error;
      this.showLoadingSpinner = false;
    }
  }

  handleSend(event) {
    let code = event.target.dataset.code;
    this.showLoadingSpinner = true;
    sendERCOde({ edenredCode: code, employeeId: this.recordId })
      .then((result) => {
        if (result) {
          let respData = JSON.parse(result);
          if (respData.meta.status === 'Succeeded') {
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'SUCCESS',
                message: this.label.actionDone,
                variant: 'success'
              })
            );
          }
          this.showLoadingSpinner = false;
        } else {
          this.error = this.label.contactAdminError;
          this.showLoadingSpinner = false;
        }
      })
      .catch((error) => {
        this.error = error;
        this.showLoadingSpinner = false;
      });
  }

  handleClose() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}