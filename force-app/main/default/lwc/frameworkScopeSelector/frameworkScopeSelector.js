import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getScopeRecords from '@salesforce/apex/FrameworkScopeController.getScopeRecords';
import saveScopeSelections from '@salesforce/apex/FrameworkScopeController.saveScopeSelections';

const COLUMNS = [
    { label: 'Entity Name', fieldName: 'Entity_Name__c', type: 'text' },
    { label: 'Legal Registration Number', fieldName: 'Entity_Legal_Registration_Number__c', type: 'text' }
];

export default class FrameworkScopeSelector extends LightningElement {
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        console.log('[FrameworkScope] recordId set:', value);
        this._recordId = value;
        if (value) this.loadRecords();
    }

    @track scopeRecords = [];
    @track selectedRowIds = [];
    @track isLoading = false;
    @track errorMessage;

    columns = COLUMNS;

    loadRecords() {
        console.log('[FrameworkScope] loadRecords called for quoteId:', this._recordId);
        this.isLoading = true;
        getScopeRecords({ quoteId: this._recordId })
            .then(data => {
                console.log('[FrameworkScope] Apex returned records:', JSON.stringify(data));
                this.scopeRecords = data.map(r => ({ ...r }));
                this.selectedRowIds = data.filter(r => r.Included__c).map(r => r.Id);
                this.errorMessage = null;
            })
            .catch(error => {
                console.error('[FrameworkScope] Apex error:', JSON.stringify(error));
                this.errorMessage = error.body?.message || 'Failed to load scope records';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRowSelection(event) {
        this.selectedRowIds = event.detail.selectedRows.map(r => r.Id);
    }

    get hasRecords() {
        return this.scopeRecords.length > 0;
    }

    get isConfirmDisabled() {
        return this.isLoading || this.selectedRowIds.length === 0;
    }

    handleConfirm() {
        const selectedSet = new Set(this.selectedRowIds);
        const recordsToSave = this.scopeRecords.map(r => ({
            Id: r.Id,
            Included__c: selectedSet.has(r.Id)
        }));

        console.log('[FrameworkScope] Confirm clicked | quoteId:', this._recordId);
        console.log('[FrameworkScope] Selected IDs:', JSON.stringify([...selectedSet]));
        console.log('[FrameworkScope] Records to save:', JSON.stringify(recordsToSave));

        this.isLoading = true;
        saveScopeSelections({ records: recordsToSave, quoteId: this._recordId })
            .then(() => {
                console.log('[FrameworkScope] Save successful — Framework_Scope_Defined__c set to true on Quote');
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Framework scope saved successfully.',
                    variant: 'success'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('[FrameworkScope] Save failed:', JSON.stringify(error));
                this.errorMessage = error.body?.message || 'Failed to save scope selections';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
