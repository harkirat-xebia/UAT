import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import IS_FRAMEWORK_FIELD from '@salesforce/schema/Quote.Is_Framework_Agreement__c';
import getFrameworkScopeSummary from '@salesforce/apex/FrameworkScopeController.getFrameworkScopeSummary';

const FIELDS = [IS_FRAMEWORK_FIELD];

export default class FrameworkScopeSummary extends LightningElement {
    @api recordId;
    @track summaryData;
    @track isLoading = false;

    // Wired to Quote record — re-fires when Framework_Scope_Defined__c or other quote fields update
    // (e.g., after the Define Framework Scope Quick Action saves and the page refreshes)
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data }) {
        if (data && getFieldValue(data, IS_FRAMEWORK_FIELD)) {
            this.loadSummary();
        }
    }

    loadSummary() {
        this.isLoading = true;
        getFrameworkScopeSummary({ quoteId: this.recordId })
            .then(result => { this.summaryData = result; })
            .catch(() => { this.summaryData = null; })
            .finally(() => { this.isLoading = false; });
    }

    get isFramework() {
        return this.summaryData != null && this.summaryData.isFramework;
    }

    get scopeDefined() {
        return this.summaryData != null && this.summaryData.scopeDefined;
    }

    get includedCount() {
        return this.summaryData != null ? this.summaryData.includedCount : 0;
    }

    get lastModified() {
        if (!this.summaryData || !this.summaryData.lastModified) return null;
        return new Intl.DateTimeFormat('en-GB', {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(new Date(this.summaryData.lastModified));
    }
}
