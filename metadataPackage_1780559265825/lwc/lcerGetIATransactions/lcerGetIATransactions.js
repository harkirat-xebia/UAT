/**
 * @author: ALK
 * @date: 23/01/2023
 * @desc: lcerGetIATransactions
 */

import {api, LightningElement, track} from 'lwc';
import getFiltredTransactions from '@salesforce/apex/IssuerAPIController.getTransactions';
import modal_80 from '@salesforce/resourceUrl/modal_80';
import {loadStyle} from "lightning/platformResourceLoader";

//LABELS
import processing from '@salesforce/label/c.LAB_SF_PROCESSING';
import currency from '@salesforce/label/c.LAB_SF_ASSET_loadsCurrency';
import getTransactionLbl from '@salesforce/label/c.LAB_SF_ASSET_GetTransactions';
import fromCreatedDateLbl from '@salesforce/label/c.LAB_SF_FROM_CREATED_DATE';
import toCreatedDateLbl from '@salesforce/label/c.LAB_SF_TO_CREATED_DATE';
import payerNameLbl from '@salesforce/label/c.LAB_SF_PAYER_NAME';
import payeeNameLbl from '@salesforce/label/c.LAB_SF_PAYEE_NAME';
import transactionTypeLbl from '@salesforce/label/c.LAB_SF_TRANSACTION_TYPE';
import lifeCycleStatusLbl from '@salesforce/label/c.LAB_SF_LIFECYCLE_STATUS';
import directionLbl from '@salesforce/label/c.LAB_SF_DIRECTION';
import resultLbl from '@salesforce/label/c.LAB_SF_RESULT';
import resultDetailLbl from '@salesforce/label/c.LAB_SF_RESULT_DETAIL';
import completedDteTimeLbl from '@salesforce/label/c.LAB_SF_COMPLETED_DTE_TIME';
import authorizationDteTimeLbl from '@salesforce/label/c.LAB_SF_AUTHORIZATION_DTE_TIME';
import authorizationAmountLbl from '@salesforce/label/c.LAB_SF_AUTHORIZATION_AMOUNT';
import clearedAmountLbl from '@salesforce/label/c.LAB_SF_AUTHORIZATION_AMOUNT';
import authorizationMid from '@salesforce/label/c.LAB_SF_AUTHORIZATION_MID';
import cardSerialNumber from '@salesforce/label/c.LAB_SF_CARD_SERIAL_NUMBER';
import acceptanceMethodLbl from '@salesforce/label/c.LAB_SF_ASSET_transactionAcceptanceMethod';
import createdDteTimeLbl from '@salesforce/label/c.LAB_SF_CREATED_DTE_TIME';
import noDataFoundLbl from '@salesforce/label/c.LAB_SF_NO_DATA_FOUND';
import nextLbl from '@salesforce/label/c.LABS_SF_Opp_Price_Next';
import previousLbl from '@salesforce/label/c.LABS_SF_Opp_Price_Previous';
import transactionIdLbl from '@salesforce/label/c.LAB_SF_TRANSACTION_ID';
import schemeLbl from '@salesforce/label/c.LAB_SF_SCHEME';

export default class LcerGetIATransactions extends LightningElement {
    @api recordId;
    showLoadingSpinner = false;
    error;
    fromDate;
    toDate;
    noDataFound = false;
    @track data = [];
    @track recordsToDisplay = [];
    displayButtons = false;
    totalRecords = 0;
    pageSize = 20;
    pageNumber = 1;
    totalPages;
    hasPaginationNav = false;

    label = {
        processing,
        currency,
        getTransactionLbl,
        fromCreatedDateLbl,
        toCreatedDateLbl,
        payerNameLbl,
        payeeNameLbl,
        transactionTypeLbl,
        lifeCycleStatusLbl,
        directionLbl,
        resultLbl,
        resultDetailLbl,
        completedDteTimeLbl,
        authorizationDteTimeLbl,
        authorizationAmountLbl,
        clearedAmountLbl,
        acceptanceMethodLbl,
        createdDteTimeLbl,
        noDataFoundLbl,
        nextLbl,
        previousLbl,
        authorizationMid,
        cardSerialNumber,
        transactionIdLbl,
        schemeLbl,
    }

    columns = [
        {label: this.label.transactionIdLbl, fieldName: 'transactionId', type: 'text'},
        {label: this.label.payerNameLbl, fieldName: 'payerName', type: 'text'},
        {label: this.label.schemeLbl, fieldName: 'scheme', type: 'text'},
        {label: this.label.payeeNameLbl, fieldName: 'payeeName', type: 'text'},
        {label: this.label.authorizationMid, fieldName: 'authorizationMid', type: 'text'},
        {label: this.label.transactionTypeLbl, fieldName: 'transactionType', type: 'text'},
        {label: this.label.lifeCycleStatusLbl, fieldName: 'lifecycleStatus', type: 'text'},
        {label: this.label.directionLbl, fieldName: 'direction', type: 'text'},
        {label: this.label.resultLbl, fieldName: 'result', type: 'text'},
        {label: this.label.resultDetailLbl, fieldName: 'resultDetail', type: 'text'},
        {label: this.label.createdDteTimeLbl, fieldName: 'createdDatetime', type: 'date', typeAttributes: {day: 'numeric', month: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true}},
        {label: this.label.authorizationDteTimeLbl, fieldName: 'authorizationDatetime', type: 'date', typeAttributes: {day: 'numeric', month: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true}},
        {label: this.label.authorizationAmountLbl, fieldName: 'authorizedAmount', type: 'number'},
        {label: this.label.clearedAmountLbl, fieldName: 'clearedAmount', type: 'number'},
        {label: this.label.currency, fieldName: 'currencyCode'},
        {label: this.label.acceptanceMethodLbl, fieldName: 'acceptanceMethod', type: 'text'},
        {label: this.label.cardSerialNumber, fieldName: 'cardSerialNumber', type: 'text'}

    ];

    connectedCallback() {
        Promise.all([
            loadStyle(this, modal_80)
        ]);
    }

    handleClick() {
        this.showLoadingSpinner = true;
        this.fromDate = this.template.querySelector(".fromDate").value;
        this.toDate = this.template.querySelector(".toDate").value;

        getFiltredTransactions({assetId: this.recordId, fromDate: this.fromDate, toDate: this.toDate}).then(result => {
            if(result) {
                let transactionsData = JSON.parse(result);
                let currentData = [];
                if(transactionsData.meta.status === "Succeeded") {
                    this.error = undefined;

                    if(transactionsData.data.length > 0) {
                        this.totalRecords = transactionsData.data.length;
                        transactionsData.data.forEach((row) => {
                            let rowData = {};
                            rowData.transactionId = row.transactionId;
                            rowData.payerName = row.payer?.locationName;
                            rowData.scheme = row.schemeId;
                            rowData.payeeName = row.payee?.locationName;
                            rowData.transactionType = row.transactionType;
                            rowData.lifecycleStatus = row.lifecycleStatus;
                            rowData.direction = row.direction;
                            rowData.result = row.result;
                            rowData.resultDetail = row.resultDetail;
                            rowData.authorizationMid = row.payee?.authorizationMid;
                            rowData.cardSerialNumber = row.payer?.cardSerialNumber;
                            rowData.authorizationDatetime = row.authorizationDatetime;
                            rowData.authorizedAmount = row.authorizedAmount;
                            rowData.clearedAmount = row.clearedAmount;
                            rowData.currencyCode = row.currencyCode;
                            rowData.acceptanceMethod = row.acceptanceMethod;
                            rowData.createdDatetime = row.createdDatetime;
                            currentData.push(rowData);
                        });
                        this.data = currentData;
                        this.noDataFound = false;
                        this.paginationHelper();
                    } else {
                        console.log(">>>>> ALK - No data found");
                        this.data = [];
                        this.displayButtons = false;
                        this.noDataFound = true;
                    }
                }
                this.showLoadingSpinner = false;
            } else {
                this.error = "Some error";
                this.showLoadingSpinner = false;
            }
        }).catch(error => {
            this.error = error;
            this.showLoadingSpinner = false;
        })
    }

    handlePrevious() {
        console.log(">>>> ALK - Previous");
        this.pageNumber = this.pageNumber - 1;
        if (this.pageNumber <= 1) this.template.querySelector(".previous-btn").setAttribute("disabled", "true");
        this.paginationHelper();
    }

    handleNext() {
        console.log(">>>> ALK - Next");
        this.pageNumber = this.pageNumber + 1;
        if (this.pageNumber >= this.totalPages) this.template.querySelector(".next-btn").setAttribute("disabled", "true");
        this.paginationHelper();
    }

    paginationHelper() {
        this.recordsToDisplay = [];
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);

        // set page number
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }

        // set records to display on current page
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.data[i]);
        }

        console.log(">>>> ALK - paginationHelper this.totalPages : " + this.totalPages);
        console.log(">>> ALK paginationHelper page Number : " + this.pageNumber);
        //Manage Buttons display
        if(this.totalRecords <= this.pageSize) {
            this.displayButtons = false;
        } else {
            this.displayButtons = true;
            console.log(">>>>> this.hasPaginationNav : " + this.hasPaginationNav);
            if(this.pageNumber === 1 && this.hasPaginationNav) {
                //this.template.querySelector(".previous-btn").removeAttribute("disabled");
                this.template.querySelector(".next-btn").removeAttribute("disabled");
            } else if(this.pageNumber > 1 && this.pageNumber < this.totalPages) {
                this.hasPaginationNav = true;
                this.template.querySelector(".previous-btn").removeAttribute("disabled");
                this.template.querySelector(".next-btn").removeAttribute("disabled");
            } else if(this.pageNumber > 1 && this.pageNumber === this.totalPages) {
                this.hasPaginationNav = true;
                this.template.querySelector(".previous-btn").removeAttribute("disabled");
                this.template.querySelector(".next-btn").setAttribute("disabled", "true");
            }
        }
    }

    /*handlePagination(event) {
        const start = (event.detail-1) * this.pageSize;
        const end = this.pageSize * event.detail;
        this.accounts = this.recordsToDisplay.slice(start, end);
    }*/
}