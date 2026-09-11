import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import terminateContract from '@salesforce/apex/TerminateContractComponentController.terminateContract';
import checkErrors from '@salesforce/apex/TerminateContractComponentController.checkErrors';
import NAME_FIELD from '@salesforce/schema/Contract.ER_TerminationReason__c';
import SUB_NAME_FIELD from '@salesforce/schema/Contract.Termination_Sub_Reason__c';
import END_DATE_FIELD from '@salesforce/schema/Contract.EndDate';
import { getRecord } from 'lightning/uiRecordApi';
export default class TerminateContractComponent extends LightningElement {
    @api recordId;
    @api objectApiName;
    Spinner = false;
    errorMessage = false;
    terminationReason;
    subTerminationReason;
    contractEndDate;
    nameField = NAME_FIELD;
    dateField = END_DATE_FIELD;
    subNameField = SUB_NAME_FIELD;
    formError = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            //it gets executed before the connected callback and avilable to use
            this.recordId = currentPageReference.state.recordId;
        }
    }
    @wire(getRecord, {
    recordId: '$recordId',
    fields: [END_DATE_FIELD, NAME_FIELD, SUB_NAME_FIELD]
    })
    wiredRecord({ error, data }) {
        console.log('=== WIRE TRIGGERED ===');

        if (data) {
            console.log('WIRE DATA:', JSON.parse(JSON.stringify(data)));

            this.contractEndDate = data.fields.EndDate.value;
            this.terminationReason = data.fields.ER_TerminationReason__c.value;
            this.subTerminationReason = data.fields.Termination_Sub_Reason__c.value;
        }

        if (error) {
            console.error('WIRE ERROR:', JSON.parse(JSON.stringify(error)));
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    connectedCallback(){
        this.fetchError();
    }
    async handleTerminateContract(){
        if (!this.validateRequiredFields()) {
            return;
        }
        this.Spinner = true;
        terminateContract({contractId: this.recordId, terminationReason: this.terminationReason, subTerminationReason: this.subTerminationReason, contractEndDate: this.contractEndDate})
            .then((result) => {
                console.log(result);
                if(result!= null){
                    this.Spinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Contract updated successfully.',
                            variant: 'success',
                            mode: 'dismissable'
                        })
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                }else{
                    this.Spinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error terminating contract in NEMO. Try again later.',
                            variant: 'error',
                            mode: 'dismissable'
                        })
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            }).catch((error)=>{
                console.error(error);
            })
    }
    fetchError(){
        this.spinner = true;
        checkErrors({contractId: this.recordId})
            .then((result) => {
                this.Spinner = false;
                console.log(result);
                this.errorMessage = result;
            }).catch((error)=>{
                console.error(error);
            })
    }
    handleChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        console.log('fieldName: ',fieldName);
        console.log('fieldValue: ',fieldValue);

        if (fieldName === 'date') {
            this.contractEndDate = fieldValue;
        } else if (fieldName === 'reason') {
            this.terminationReason = fieldValue;
        } else if (fieldName === 'subReason') {
            this.subTerminationReason = fieldValue;
        }
    }

    validateRequiredFields() {
        this.formError = '';

        let errors = [];

        if (!this.contractEndDate) {
            errors.push("• Please provide Contract End Date");
        }

        if (!this.terminationReason) {
            errors.push("• Please select a Termination Reason");
        }

        const subEl = this.template.querySelector('[name="subReason"]');
        if (subEl && !this.subTerminationReason) {
            errors.push("• Please select a Sub Termination Reason");
        }

        if (errors.length > 0) {
            this.formError = errors.join('\n');
            return false;
        }

        return true;
    }

}