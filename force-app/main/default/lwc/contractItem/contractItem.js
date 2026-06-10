/**
 * Created by davram on 2/10/2021.
 */

import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import createOpportunity from '@salesforce/apex/APER04_Opportunity_Management.createOpportunityFromFrameworkContract';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//LABELS
import LAB_SOMETHING_WENT_WRONG from '@salesforce/label/c.LAB_SF_SOMETHING_WENT_WRONG';

export default class ContractItem extends NavigationMixin(LightningElement) {
  label = { LAB_SOMETHING_WENT_WRONG };

  @api contractId;
  @api contractNumber;
  @api currentAccount;
  @track contractIdParsed = '';
  userId = Id;
  @track opportunityInserted;
  error;
  @track selectedRecordId;
  @track isLoading = false;

  onClickContract(event) {
    const selRecId = event.target.dataset.id;
    console.log('sel rec id ' + selRecId);
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: selRecId,
        objectApiName: 'Contract',
        actionName: 'view'
      }
    });
  }

  handleOpportunityCreation() {
    this.createOppty();
  }

  createOppty() {
    this.isLoading = true;
    createOpportunity({
      contractId: this.contractId,
      currentAccount: this.currentAccount
    })
      .then((result) => {
        this.opportunityInserted = result;
        this.error = undefined;
        this.isLoading = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success!!',
            message: 'Opportunity created Successfully!!',
            variant: 'success'
          })
        );
        this.navigateToOpportunity();
      })
      .catch((error) => {
        this.isLoading = false;
        if (Array.isArray(error.body)) {
          this.error = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
          this.error = error.body.message;
        }
        console.log('>>>>> ALK - Error : ' + this.error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.label.LAB_SOMETHING_WENT_WRONG,
            message: this.error,
            variant: 'error'
          })
        );
        this.opportunityInserted = undefined;
      });
  }

  navigateToOpportunity() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.opportunityInserted.Id,
        objectApiName: 'Opportunity',
        actionName: 'view'
      }
    });
  }
}