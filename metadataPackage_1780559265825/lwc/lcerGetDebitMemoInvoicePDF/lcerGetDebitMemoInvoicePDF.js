/**
 * @author : ALK
 * @date : 05/11/2021
 * @desc : lcerGetDebitMemoInvoicePDF
 */
import { api, LightningElement, wire } from 'lwc';
import getInvoice from '@salesforce/apex/ZuoraCreditDebitMemoController.getCreditOrDebitMemoInvoice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ZUORA_EXTERNAL_ID from '@salesforce/schema/Zuora__DebitMemo__c.Zuora__External_Id__c';
import ZUORA_NAME from '@salesforce/schema/Zuora__DebitMemo__c.Name';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

//LABELS
import LAB_SOMETHING_WENT_WRONG from '@salesforce/label/c.LAB_SF_SOMETHING_WENT_WRONG';

export default class LcerGetDebitMemoInvoicePdf extends LightningElement {
  @api recordId;
  label = { LAB_SOMETHING_WENT_WRONG };

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [ZUORA_EXTERNAL_ID, ZUORA_NAME]
  })
  debitMemo;

  @api invoke() {
    console.log('>>>> ALK - recordId : ' + this.recordId);
    getInvoice({
      creditMemo: null,
      debitMemo: getFieldValue(this.debitMemo.data, ZUORA_EXTERNAL_ID)
    }).then((result) => {
      if (result) {
        const linkSource = 'data:application/pdf;base64,' + result;
        const downloadLink = document.createElement('a');

        //File name
        const fileName = getFieldValue(this.debitMemo.data, ZUORA_NAME) + '.pdf';

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