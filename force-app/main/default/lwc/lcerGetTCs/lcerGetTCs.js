/**
 * @description       : Get last version of T&Cs -- COUL-1859
 * @author            : Hassan DAKHCHA
 * @group             :
 * @last modified on  : 03-23-2023
 * @last modified by  : Hassan DAKHCHA
 **/
import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GET_TCS_SUCCESS_LABEL from '@salesforce/label/c.LAB_SF_SMARTER_GET_TCS_SUCCESS';
import GET_TCS_TITLE_LABEL from '@salesforce/label/c.LAB_SF_SMARTER_GET_TCS_TITLE';
import getTCs from '@salesforce/apex/ZuoraQuote_Management_AP01.getTCs';

export default class LcerGetTCs extends LightningElement {
  @api recordId;

  @api invoke() {
    getTCs({
      recordId: this.recordId
    }).then((errorMsg) => {
      if (errorMsg) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: GET_TCS_TITLE_LABEL,
            message: errorMsg,
            variant: 'error'
          })
        );
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: GET_TCS_TITLE_LABEL,
            message: GET_TCS_SUCCESS_LABEL,
            variant: 'success'
          })
        );
        location.reload();
      }
    });
  }
}