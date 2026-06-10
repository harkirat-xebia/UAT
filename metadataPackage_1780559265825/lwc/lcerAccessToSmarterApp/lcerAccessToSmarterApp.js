/**
 * @author: ALK
 * @date: 25/04/2023
 * @desc: lcerAccessToSmarterApp
 */

import { api, LightningElement } from 'lwc';
import accessSmarterApp from '@salesforce/apex/APER17_Contact_Management.requestAccessToSmarterApp';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import processing from '@salesforce/label/c.LAB_SF_PROCESSING';
import accessSmarterAppTitle from '@salesforce/label/c.LAB_SF_ACCESS_SMARTER_APP_TITLE';
import accessSmarterAppMsg from '@salesforce/label/c.LAB_SF_ACCESS_SMARTER_APP_MSG';

export default class LcerAccessToSmarterApp extends LightningElement {
  @api recordId;
  showLoadingSpinner = true;

  label = {
    processing,
    accessSmarterAppTitle,
    accessSmarterAppMsg
  };

  @api invoke() {
    accessSmarterApp({ contactId: this.recordId }).then((errorMsg) => {
      if (errorMsg) {
        this.showLoadingSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.accessSmarterAppTitle,
            message: errorMsg,
            variant: 'error'
          })
        );
      } else {
        this.showLoadingSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.accessSmarterAppTitle,
            message: this.label.accessSmarterAppMsg,
            variant: 'success'
          })
        );
      }
    });
  }
}