import { LightningElement, api, wire } from 'lwc';
import getOpportunityDataFromWorkItem from '@salesforce/apex/ER_RecordInfoOnApprovalController.getOpportunityDataFromWorkItem';

export default class ErRecordInfoOnApproval extends LightningElement {
  @api recordId;
  opportunity;
  lineItems = [];
  error;

  @wire(getOpportunityDataFromWorkItem, { workItemId: '$recordId' })
  wiredData({ error, data }) {
    if (data) {
      console.log('Data ": ',data);
      this.opportunity = data.opportunity;
      this.lineItems = data.lineItems;
      this.error = undefined;
    } else if (error) {
      console.log('error ": ',error);
      this.error = 'Error loading data';
      this.opportunity = undefined;
      this.lineItems = [];
    }
  }
}