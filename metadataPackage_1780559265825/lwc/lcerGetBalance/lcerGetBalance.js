/**
 * @author: ALK
 * @date: 08/01/2023
 * @desc: lcerGetBalance
 */

import { api, LightningElement, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getBalance from '@salesforce/apex/IssuerAPIController.getBalance';
import modal_80 from '@salesforce/resourceUrl/modal_80';
import { loadStyle } from 'lightning/platformResourceLoader';

//LABELS
import processing from '@salesforce/label/c.LAB_SF_PROCESSING';
import close from '@salesforce/label/c.LABS_SF_CLOSE';
import walletName from '@salesforce/label/c.LAB_SF_WALLET_NAME';
import accountNumber from '@salesforce/label/c.LAB_ST_ACCOUNT_NUMBER';
import productClass from '@salesforce/label/c.LAB_SF_PRODUCT_CLASS';
import commercialName from '@salesforce/label/c.LAB_SF_COMMERCIAL_NAME';
import availableBalance from '@salesforce/label/c.LAB_SF_AVAILABLE_BALANCE';
import clearBalance from '@salesforce/label/c.LAB_SF_CLEAR_BALANCE';
import pendingCredit from '@salesforce/label/c.LAB_SF_PENDING_CREDIT';
import pendingDebit from '@salesforce/label/c.LAB_SF_PENDING_DEBIT';
import currency from '@salesforce/label/c.LAB_SF_ASSET_loadsCurrency';
import getBalanceTitle from '@salesforce/label/c.LAB_SF_GET_BALANCE';

export default class LcerGetBalance extends LightningElement {
  @api recordId;
  error;
  data = [];
  showLoadingSpinner = true;

  label = {
    processing,
    close,
    walletName,
    accountNumber,
    productClass,
    commercialName,
    availableBalance,
    clearBalance,
    pendingCredit,
    pendingDebit,
    currency,
    getBalanceTitle
  };

  columns = [
    { label: this.label.walletName, fieldName: 'name', type: 'text' },
    { label: this.label.accountNumber, fieldName: 'accountNumber', type: 'text' },
    { label: this.label.productClass, fieldName: 'productClass', type: 'text' },
    { label: this.label.commercialName, fieldName: 'commercialName', type: 'text' },
    { label: this.label.availableBalance, fieldName: 'availableBalance', type: 'number' },
    { label: this.label.clearBalance, fieldName: 'clearedBalance', type: 'number' },
    { label: this.label.pendingCredit, fieldName: 'pendingCredit', type: 'number' },
    { label: this.label.pendingDebit, fieldName: 'pendingDebit', type: 'number' },
    { label: this.label.currency, fieldName: 'currency' }
  ];

  connectedCallback() {
    Promise.all([loadStyle(this, modal_80)]);
  }

  @wire(getBalance, { assetId: '$recordId' })
  wiredBalance({ error, data }) {
    if (data) {
      let issuerAccount = JSON.parse(data);
      if (issuerAccount.meta.status === 'Succeeded') {
        this.error = undefined;
        let currentData = [];

        issuerAccount.data.wallets.forEach((row) => {
          if (row.status === 'ACTIVE') {
            let rowData = {};
            rowData.accountNumber = issuerAccount.data.accountNumber;
            rowData.productClass = issuerAccount.data.productClassCode;
            rowData.name = row.name;
            rowData.commercialName = issuerAccount.data.commercialName;
            rowData.availableBalance = row.availableBalance;
            rowData.clearedBalance = row.clearedBalance;
            rowData.pendingCredit = row.pendingCredit;
            rowData.pendingDebit = row.pendingDebit;
            rowData.currency = row.currencyCode;
            currentData.push(rowData);
          }
        });

        this.data = currentData;
        this.showLoadingSpinner = false;
      }
    } else if (error) {
      this.error = error;
      console.log('>>>>> ALK - error : ' + JSON.stringify(error));
      this.showLoadingSpinner = false;
    }
  }

  handleClose() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}