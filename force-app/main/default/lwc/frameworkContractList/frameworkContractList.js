/**
 * Created by davram on 2/10/2021.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import getFrameworkContract from '@salesforce/apex/APER12_Contract_Management.getFrameworkContract';

const FIELDS = [ACCOUNT_NAME];
const COMPETITOR_RECORD_TYPE = 'Competitor';

export default class FrameworkContractList extends LightningElement {
  @api recordId;
  @track contracts;
  @track error;
  @track hasRecords;
  @track accountrecordType;
  @track companyRecordType = false;
  @track contractsSize;

  connectedCallback() {}

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredAccount({ error, data }) {
    if (data) {
      this.accountrecordType = data;
      this.error = undefined;
      if (data.recordTypeInfo.name === COMPETITOR_RECORD_TYPE) {
        this.companyRecordType = true;
      }
    } else if (error) {
      this.error = error;
      this.accountrecordType = undefined;
    }
  }

  @wire(getFrameworkContract, {
    accountId: '$recordId',
    fields: [ACCOUNT_NAME]
  })
  wiredContracts({ data, error }) {
    if (data) {
      this.contracts = data;
      this.error = undefined;
      this.contractsSize = this.contracts.length > 0 ? this.contracts.length : 0;
    } else if (error) {
      this.error = error;
      this.contracts = undefined;
    }
  }
}