/**
 * @author: ALK
 * @date: 09/11/2022
 * @desc: lcerGetInvoicePDF
 */

import { api, LightningElement, wire } from 'lwc';
import getProforma from '@salesforce/apex/ZuoraInvoiceController.getProformaPDF';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import INVOICE_NAME from '@salesforce/schema/Zuora__ZInvoice__c.Name';
import INVOICE_ID from '@salesforce/schema/Zuora__ZInvoice__c.Zuora__ZuoraId__c';
import INVOICE_BU from '@salesforce/schema/Zuora__ZInvoice__c.ER_Business_Unit__c';
import INVOICE_PROFORMA_VERSION from '@salesforce/schema/Zuora__ZInvoice__c.ER_Proforma_Version__c';
import INVOICE_TRANSACTION_TYPE from '@salesforce/schema/Zuora__ZInvoice__c.ER_Transaction_Type__c';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

//LABELS
import LAB_SOMETHING_WENT_WRONG from '@salesforce/label/c.LAB_SF_SOMETHING_WENT_WRONG';

export default class LcerGetInvoicePdf extends LightningElement {
  invoiceId;
  invoiceName;
  transactionType;
  bu;
  proformaVersion;

  @api recordId;
  label = { LAB_SOMETHING_WENT_WRONG };

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [INVOICE_NAME, INVOICE_ID, INVOICE_BU, INVOICE_PROFORMA_VERSION, INVOICE_TRANSACTION_TYPE]
  })
  inv;

  @api invoke() {
    console.log('>>>> ALK IN INVOKE INVOICE PDF');
    this.invoiceName = getFieldValue(this.inv.data, INVOICE_NAME);
    this.transactionType =
      getFieldValue(this.inv.data, INVOICE_TRANSACTION_TYPE) === 'PROFORMA' ? 'PROFORMA' : 'INVOICE';
    this.bu = getFieldValue(this.inv.data, INVOICE_BU);
    this.proformaVersion = getFieldValue(this.inv.data, INVOICE_PROFORMA_VERSION);
    console.log('>>>>> ALK - invoiceNumber : ' + this.invoiceName);
    console.log('>>>>> ALK - original transactionType : ' + getFieldValue(this.inv.data, INVOICE_TRANSACTION_TYPE));
    console.log('>>>>> ALK - transactionType : ' + this.transactionType);
    console.log('>>>>> ALK - bu : ' + this.bu);
    console.log('>>>>> ALK - proformaVersion : ' + this.proformaVersion);

    getProforma({
      invoiceNumber: this.invoiceName,
      invoiceType: this.transactionType,
      bu: this.bu,
      proformaVersion: this.proformaVersion
    }).then((result) => {
      if (result) {
        const linkSource = 'data:application/pdf;base64,' + result;
        const downloadLink = document.createElement('a');

        //File name
        const fileName = this.invoiceName + '.pdf';

        //Set link's href to point to the blob URL
        downloadLink.href = linkSource;
        downloadLink.download = fileName;

        // Append link to the body
        document.body.appendChild(downloadLink);

        downloadLink.dispatchEvent(
          new MouseEvent('click', {
            bubbles: true,
            cancelable: true
          })
        );

        // Remove link from body
        document.body.removeChild(downloadLink);
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.LAB_SOMETHING_WENT_WRONG,
            message: result,
            variant: 'error'
          })
        );
      }
    });
  }
}