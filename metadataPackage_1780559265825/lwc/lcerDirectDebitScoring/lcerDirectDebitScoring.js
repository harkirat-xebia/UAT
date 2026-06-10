/**
 * @author: ALK
 * @date: 08/05/2023
 * @desc: lcerDirectDebitScoring
 */

import { api, LightningElement } from 'lwc';
import checkAccountProfile from '@salesforce/apex/APER30_FinancialCenter_Management.checkAccountProfileSEPA';

import LAB_SF_PROCESSING from '@salesforce/label/c.LAB_SF_PROCESSING';
import LAB_SF_DIRECT_DEBIT_SCORING_TITLE from '@salesforce/label/c.LAB_SF_DIRECT_DEBIT_SCORING_TITLE';
import LAB_SF_DIRECT_DEBIT_SCORING_SUCCESS from '@salesforce/label/c.LAB_SF_DIRECT_DEBIT_SCORING_SUCCESS';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LcerDirectDebitScoring extends LightningElement {
  @api recordId;
  showLoadingSpinner = true;
  label = {
    LAB_SF_PROCESSING,
    LAB_SF_DIRECT_DEBIT_SCORING_TITLE,
    LAB_SF_DIRECT_DEBIT_SCORING_SUCCESS
  };

  @api invoke() {
    checkAccountProfile({ fcId: this.recordId }).then((errorMsg) => {
      if (errorMsg) {
        this.showLoadingSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.LAB_SF_DIRECT_DEBIT_SCORING_TITLE,
            message: errorMsg,
            variant: 'error'
          })
        );
      } else {
        this.showLoadingSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.LAB_SF_DIRECT_DEBIT_SCORING_TITLE,
            message: this.label.LAB_SF_DIRECT_DEBIT_SCORING_SUCCESS,
            variant: 'success'
          })
        );
        setTimeout(function () {
          window.location.reload();
        }, 3000);
      }
    });
  }
}