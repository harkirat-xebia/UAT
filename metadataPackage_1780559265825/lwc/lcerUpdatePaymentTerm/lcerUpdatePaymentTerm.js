/**
 * @author : ALK
 * @date : 25/10/2021
 * @desc : lcerUpdatePaymentTerm
 */
import { LightningElement, wire, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updatePaymentTerms from '@salesforce/apex/ZuoraBillingAccountController.updatePaymentTerm';
import BILLING_ACCOUNT_NUMBER from '@salesforce/schema/Zuora__CustomerAccount__c.Zuora__AccountNumber__c';
import ZQUOTE_PAYMENT_TERM from '@salesforce/schema/zqu__Quote__c.zqu__PaymentTerm__c';
import ZQUOTE_OBJECT from '@salesforce/schema/zqu__Quote__c';

//LABELS
import PROCESSING from '@salesforce/label/c.LAB_SF_PROCESSING';
import LAB_CANCEL from '@salesforce/label/c.LAB_SF_PublicRegister_Cancel';
import LAB_SAVE from '@salesforce/label/c.LABS_SF_Opp_Price_Save';
import LAB_UPDATE_PAYMENT_TERM from '@salesforce/label/c.LABS_SF_UPDATE_PAYMENT_TERMS';
import LAB_PAYMENT_TERM_UPDATED_MSG from '@salesforce/label/c.LAB_SF_PAYMENT_TERM_UPDATED_MSG';
import LAB_SOMETHING_WENT_WRONG from '@salesforce/label/c.LAB_SF_SOMETHING_WENT_WRONG';

export default class LcerUpdatePaymentTerm extends LightningElement {
  @api recordId;
  showLoadingSpinner = false;
  selectedValue;
  LAB_TERM;
  label = {
    PROCESSING,
    LAB_CANCEL,
    LAB_SAVE,
    LAB_UPDATE_PAYMENT_TERM,
    LAB_PAYMENT_TERM_UPDATED_MSG,
    LAB_SOMETHING_WENT_WRONG
  };
  error;

  @wire(getObjectInfo, { objectApiName: ZQUOTE_OBJECT }) zquoteLab({ data, error }) {
    if (data) {
      this.LAB_TERM = data.fields.zqu__PaymentTerm__c.label;
    }
  }
  @wire(getObjectInfo, { objectApiName: ZQUOTE_OBJECT }) zquoteInfo;
  @wire(getPicklistValues, {
    recordTypeId: '$zquoteInfo.data.defaultRecordTypeId',
    fieldApiName: ZQUOTE_PAYMENT_TERM
  })
  terms;
  @wire(getRecord, { recordId: '$recordId', fields: [BILLING_ACCOUNT_NUMBER] })
  billingAccount;

  saveBA() {
    this.showLoadingSpinner = true;
    console.log('>>>> ALK - Save Billing Account');
    updatePaymentTerms({
      newPaymentTerm: this.selectedValue,
      billAccNumber: getFieldValue(this.billingAccount.data, BILLING_ACCOUNT_NUMBER)
    }).then((result) => {
      console.log('>>>> ALK - result : ' + result);
      if (result === 'SUCCESS') {
        console.log('>>>> ALK in if success');
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success !!!',
            message: this.label.LAB_PAYMENT_TERM_UPDATED_MSG,
            variant: 'success'
          })
        );
        this.closeAction();
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.LAB_SOMETHING_WENT_WRONG,
            message: result,
            variant: 'error'
          })
        );
        this.closeAction();
      }
      this.showLoadingSpinner = false;
    });
  }

  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  handleTermChange(event) {
    this.selectedValue = event.detail.value;
  }
}