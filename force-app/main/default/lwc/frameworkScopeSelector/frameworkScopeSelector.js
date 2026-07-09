import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getScopeRecords from '@salesforce/apex/FrameworkScopeController.getScopeRecords';
import saveScopeSelections from '@salesforce/apex/FrameworkScopeController.saveScopeSelections';
import SCOPE_DEFINED_FIELD from '@salesforce/schema/Quote.Framework_Scope_Defined__c';

const COLUMNS = [
    { label: 'Entity Name', fieldName: 'Entity_Name__c', type: 'text' },
    { label: 'Legal Registration Number', fieldName: 'Entity_Legal_Registration_Number__c', type: 'text' },
    { label: 'Previously Included', fieldName: 'Included__c', type: 'boolean' }
];

export default class FrameworkScopeSelector extends LightningElement {
    @api recordId;
    @track scopeRecords = [];
    @track selectedRowIds = [];
    @track isLoading = false;
    @track errorMessage;
    @track noRecordsFound = false;
    @track currentStep = 'select';
    @track validationMessage;
    columns = COLUMNS;
    _saving = false;

    // Re-fires when recordId is first set AND when the Quote is updated (e.g. after save + notifyRecordUpdateAvailable)
    @wire(getRecord, { recordId: '$recordId', fields: [SCOPE_DEFINED_FIELD] })
    wiredQuote({ data }) {
        if (data && !this._saving) {
            this.loadRecords();
        }
    }

    loadRecords() {
        if (!this.recordId) return;
        console.log('[FrameworkScope] loadRecords for quoteId:', this.recordId);
        this.currentStep = 'select';
        this.selectedRowIds = [];
        this.validationMessage = null;
        this.errorMessage = null;
        this.noRecordsFound = false;
        this.isLoading = true;

        getScopeRecords({ quoteId: this.recordId })
            .then(data => {
                console.log('[FrameworkScope] Records loaded:', JSON.stringify(data));
                if (!data || data.length === 0) {
                    this.noRecordsFound = true;
                } else {
                    this.scopeRecords = data.map(r => ({ ...r }));
                    // Pre-select entities that were previously included
                    this.selectedRowIds = data.filter(r => r.Included__c).map(r => r.Id);
                }
            })
            .catch(error => {
                console.error('[FrameworkScope] Load error:', JSON.stringify(error));
                this.errorMessage = error?.body?.message || 'Failed to load scope records';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRowSelection(event) {
        this.selectedRowIds = event.detail.selectedRows.map(r => r.Id);
        this.validationMessage = null;
    }

    handleNext() {
        if (this.selectedRowIds.length === 0) {
            this.validationMessage = 'Select at least one entity to include in the framework.';
            return;
        }
        this.validationMessage = null;
        this.currentStep = 'confirm';
    }

    handleBack() {
        this.currentStep = 'select';
    }

    handleConfirm() {
        // Save ALL records — selected ones get Included__c = true, unselected get false
        const selectedSet = new Set(this.selectedRowIds);
        const recordsToSave = this.scopeRecords.map(r => ({
            Id: r.Id,
            Included__c: selectedSet.has(r.Id)
        }));

        console.log('[FrameworkScope] Saving | quoteId:', this.recordId, '| records:', JSON.stringify(recordsToSave));

        this._saving = true;
        this.isLoading = true;
        saveScopeSelections({ records: recordsToSave, quoteId: this.recordId })
            .then(() => {
                console.log('[FrameworkScope] Save successful');
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Framework scope saved. You can now send for signature.',
                    variant: 'success'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('[FrameworkScope] Save failed:', JSON.stringify(error));
                this.errorMessage = error?.body?.message || 'Failed to save scope selections';
                this.currentStep = 'select';
            })
            .finally(() => {
                this._saving = false;
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // ── Getters ──────────────────────────────────────────────────────────────

    get selectedRecords() {
        const selectedSet = new Set(this.selectedRowIds);
        return this.scopeRecords.filter(r => selectedSet.has(r.Id));
    }

    get selectedCount() {
        return this.selectedRowIds.length;
    }

    get confirmationMessage() {
        const count = this.selectedCount;
        return `You have selected ${count} ${count === 1 ? 'entity' : 'entities'} to include in this framework agreement.`;
    }

    get isSelectStep() {
        return this.currentStep === 'select';
    }

    get isConfirmStep() {
        return this.currentStep === 'confirm';
    }

    get isNextDisabled() {
        return this.isLoading;
    }

    get isConfirmDisabled() {
        return this.isLoading;
    }
}
