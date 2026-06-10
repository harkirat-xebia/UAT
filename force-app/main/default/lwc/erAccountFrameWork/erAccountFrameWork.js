/**
 * Created by noorgoolamnabee on 29/11/2021.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFrameworkContract from '@salesforce/apex/APER12_Contract_Management.getFrameworkContract';
import createOpportunity from '@salesforce/apex/APER04_Opportunity_Management.createOpportunityFromFrameworkContract';
import shouldShowApplyButtonPerContract from '@salesforce/apex/APER12_Contract_Management.shouldShowApplyButtonPerContract';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS_DEFINITION = [
  {
    type: 'url',
    fieldName: 'ContractLink',
    label: 'Contract',
    typeAttributes: {
      label: { fieldName: 'ContractNumber' }
    }
  },
  {
    type: 'text',
    fieldName: 'ProductSolution',
    label: 'Product Solution',
    title: 'ProductSolution'
  },
  {
    type: 'url',
    fieldName: 'AccountLink',
    label: 'Account',
    typeAttributes: {
      label: { fieldName: 'AccountName' }
    }
  },
  {
    type: 'text',
    fieldName: 'Status',
    label: 'Status'
  },
  {
    type: 'text',
    fieldName: 'ER_Contract_Type__c',
    label: 'Contract Type'
  },
  {
    type: 'Date',
    fieldName: 'StartDate',
    label: 'StartDate'
  },
  {
    type: 'button',
    cellAttributes: { alignment: 'right' },
    typeAttributes: {
      iconName: '',
      name: 'apply',
      title: 'Create Opportunity',
      label: 'Apply',
      alternativeText: 'Return',
      class: { fieldName: 'isShow' },
      disabled: { fieldName: 'isDisabled' } 
    }
  }
];
export default class ErAccountFrameWork extends NavigationMixin(LightningElement) {
  @track error;
  @api recordId;
  @track gridColumns = COLUMNS_DEFINITION;
  @track gridData;
  @track contractsSize;
  @track isLoading = false;
  @track expandedRows;
  @track showApplyButton = false;
  @track contractVisibility = {};

  @wire(shouldShowApplyButtonPerContract, { accountId: '$recordId' })
  wiredVisibility({ data, error }) {
      if (data) {
          this.contractVisibility = data;
          console.log('Contract-level visibility:', JSON.stringify(data));
      }
  }

  //Get corresponding contact
  @wire(getFrameworkContract, { accountId: '$recordId' })
  wiredContracts({ data, error }) {
    if (data) {
      this.contractsSize = data.length > 0 ? data.length : 0;
      var tempData = JSON.parse(JSON.stringify(data));
      var rowIds = [];
      tempData = tempData.map((row) => {
        rowIds.push(row.Id);
        return {
          ...row,
          AccountName: row.Account.Name,
          AccountLink: '/lightning/r/Account/' + row.Account.Id + '/view',
          ContractLink: '/lightning/r/Contract/' + row.Id + '/view'
        };
      });

      //Convert JSON to support tree grid
      for (var i = 0; i < tempData.length; i++) {
        tempData[i].isDisabled = !this.contractVisibility[tempData[i].Id];
        const cli = tempData[i].ER_ContractLineItems__r || [];

        tempData[i]._children = cli.map((row) => {
            return {
                ...row,
                ProductSolution: row.Name + '-' + row.ER_Solution__c,
                isShow: 'slds-hide'
            };
        });

        delete tempData[i].ER_ContractLineItems__r;
      }

      this.gridData = tempData;
      this.expandedRows = rowIds;

      this.error = undefined;
    } else if (error) {
      console.log(error);
      this.error = error;
      this.contracts = undefined;
    }
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
      case 'apply':
        this.handleOpportunityCreation(row);
        break;
      default:
    }
  }

  handleOpportunityCreation(row) {
    this.isLoading = true;
    createOpportunity({ contractId: row.Id, currentAccount: this.recordId })
      .then((result) => {
        this.opportunityInserted = result;
        this.error = undefined;
        this.isLoading = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success!!',
            message: 'Opportunity Created with Success!!',
            variant: 'success'
          })
        );
        this.navigateToOpportunity();
      })
      .catch((error) => {
        this.error = error;
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