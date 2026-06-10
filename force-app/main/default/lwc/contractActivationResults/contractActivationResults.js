import { LightningElement, api, track } from 'lwc';
import getContractStatuses from '@salesforce/apex/ContractActivationController.getContractStatuses';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SUCCESS_COLUMNS = [
    {
        label: 'Contract Number',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'contractNumber' },
            target: '_blank',
            tooltip: 'Open Contract'
        },
        wrapText: true,
        initialWidth: 180
    },
    {
        label: 'Category', 
        fieldName: 'contractCategory',
        type: 'text',
        wrapText: true,
        initialWidth: 220
    },
    {
        label: 'Activation Status',
        fieldName: 'activationStatus',
        type: 'text',
        wrapText: true,
        initialWidth: 180,
        cellAttributes: {
            iconName: { fieldName: 'activationIcon' },
            iconPosition: 'left',
            class: { fieldName: 'activationStatusClass' }
        }
    },
    {
        label: 'Sync Status',
        fieldName: 'syncStatusCode',
        type: 'text',
        wrapText: true,
        initialWidth: 200,
        cellAttributes: {
            iconName: { fieldName: 'syncIcon' },
            iconPosition: 'left',
            class: { fieldName: 'syncStatusClass' }
        }
    },
    {
        label: 'Last Updated',
        fieldName: 'lastUpdated',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        },
        wrapText: true,
        initialWidth: 180
    }
];

export default class ContractActivationResults extends LightningElement {
    @api invalidContractsJson;
    @api validContractsJson;
    
    @track failedTableData = [];
    @track successTableDataInternal = [];
    @track isRefreshing = false;
    
    xlsxInitialized = false;
    successColumns = SUCCESS_COLUMNS;
    
    get hasFailedContracts() {
        return this.failedTableData && this.failedTableData.length > 0;
    }
    
    get hasSuccessfulContracts() {
        return this.successTableDataInternal && this.successTableDataInternal.length > 0;
    }
    
    get allSuccessful() {
        return this.hasSuccessfulContracts && !this.hasFailedContracts;
    }
    
    get successCount() {
        return this.successTableDataInternal ? this.successTableDataInternal.length : 0;
    }
    
    get failedCount() {
        return this.failedTableData ? this.failedTableData.length : 0;
    }
    
    get totalCount() {
        return this.successCount + this.failedCount;
    }
    
    get successTableData() {
        return this.successTableDataInternal;
    }
    
    get refreshButtonLabel() {
        return this.isRefreshing ? 'Refreshing...' : 'Refresh Status';
    }
    
    connectedCallback() {
        this.parseFailedContracts();
        this.initializeSuccessTableData();
    }
    
    initializeSuccessTableData() {
        if (!this.validContractsJson) {
            this.successTableDataInternal = [];
            return;
        }
        
        try {
            const contracts = JSON.parse(this.validContractsJson);
            this.successTableDataInternal = contracts.map(contract => {
                return this.formatContractData(contract);
            });
        } catch (e) {
            console.error('Error parsing validContractsJson:', e);
            this.successTableDataInternal = [];
        }
    }
    
    formatContractData(contract) {
        const activationStatus = this.getActivationStatus(contract.status);
        const syncStatus = this.getSyncStatus(contract.syncStatusCode);
        
        return {
            contractId: contract.contractId || contract.Id,
            contractNumber: contract.contractNumber || contract.ContractNumber || 'N/A',
            contractCategory: contract.contractCategory || 'N/A',
            status: contract.status || 'Queued for Activation',
            activationStatus: activationStatus.label,
            activationStatusClass: activationStatus.class,
            activationIcon: activationStatus.icon,
            syncStatusCode: syncStatus.label,
            syncStatusClass: syncStatus.class,
            syncIcon: syncStatus.icon,
            recordUrl: contract.recordUrl || '/' + (contract.contractId || contract.Id),
            lastUpdated: contract.lastModifiedDate || new Date().toISOString()
        };
    }
    
    getActivationStatus(status) {
        const statusLower = (status || '').toLowerCase();
        
        if (statusLower === 'activated' || statusLower === 'active') {
            return {
                label: 'Activated',
                class: 'slds-text-color_success',
                icon: 'utility:success'
            };
        } else if (statusLower.includes('progress') || statusLower.includes('pending') || statusLower.includes('queued')) {
            return {
                label: 'In Progress',
                class: 'slds-text-color_default',
                icon: 'utility:clock'
            };
        } else if (statusLower.includes('draft')) {
            return {
                label: 'Not Activated',
                class: 'slds-text-color_weak',
                icon: 'utility:info'
            };
        } else if (statusLower.includes('error') || statusLower.includes('failed')) {
            return {
                label: 'Failed',
                class: 'slds-text-color_error',
                icon: 'utility:error'
            };
        } else {
            return {
                label: status || 'Unknown',
                class: 'slds-text-color_default',
                icon: 'utility:info'
            };
        }
    }
    
    getSyncStatus(syncStatus) {
        const statusLower = (syncStatus || '').toLowerCase();
        
        if (statusLower === 'synchronized' || statusLower === 'synced') {
            return {
                label: 'Synchronized',
                class: 'slds-text-color_success',
                icon: 'utility:check'
            };
        } else if (statusLower.includes('progress') || statusLower.includes('syncing')) {
            return {
                label: 'Syncing',
                class: 'slds-text-color_default',
                icon: 'utility:sync'
            };
        } else if (statusLower.includes('error') || statusLower.includes('failed')) {
            return {
                label: 'Sync Failed',
                class: 'slds-text-color_error',
                icon: 'utility:error'
            };
        } else if (statusLower === 'not synced' || statusLower === 'pending') {
            return {
                label: 'Not Synced',
                class: 'slds-text-color_weak',
                icon: 'utility:warning'
            };
        } else {
            return {
                label: syncStatus || 'Unknown',
                class: 'slds-text-color_default',
                icon: 'utility:info'
            };
        }
    }
    
    async handleRefreshStatus() {
        if (this.isRefreshing || !this.successTableDataInternal || this.successTableDataInternal.length === 0) {
            return;
        }
        
        this.isRefreshing = true;
        
        try {
            // Get contract IDs
            const contractIds = this.successTableDataInternal.map(contract => contract.contractId);
            
            // Call Apex to get updated statuses
            const updatedContracts = await getContractStatuses({ contractIds: contractIds });
            
            // Update the table data
            this.successTableDataInternal = updatedContracts.map(contract => {
                return this.formatContractData(contract);
            });
            
            // Show success message
            this.showToast('Success', 'Contract statuses refreshed successfully', 'success');
            
        } catch (error) {
            console.error('Error refreshing contract statuses:', error);
            this.showToast('Error', 'Failed to refresh contract statuses: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isRefreshing = false;
        }
    }
    
    parseFailedContracts() {
        if (!this.invalidContractsJson) {
            this.failedTableData = [];
            return;
        }
        
        try {
            const contracts = JSON.parse(this.invalidContractsJson);
            this.failedTableData = contracts.map(contract => {
                return {
                    contractId: contract.contractId,
                    contractNumber: contract.contractNumber || 'N/A',
                    contractCategory: contract.contractCategory || 'N/A',
                    status: contract.status || 'Unknown',
                    syncStatusCode: contract.syncStatusCode || 'Unknown',
                    recordUrl: contract.recordUrl || '/' + contract.contractId,
                    errorDetails: contract.errorDetails || 'No error details available',
                    showErrors: false,
                    errorIconName: 'utility:chevrondown'
                };
            });
        } catch (e) {
            console.error('Error parsing invalidContractsJson:', e);
            this.failedTableData = [];
        }
    }
    
    getSyncStatusClass(syncStatus) {
        if (syncStatus === 'Synchronized') {
            return 'slds-text-color_success';
        } else if (syncStatus === 'In Progress') {
            return 'slds-text-color_default';
        } else {
            return 'slds-text-color_error';
        }
    }
    
    toggleErrors(event) {
        const contractId = event.currentTarget.dataset.id;
        
        this.failedTableData = this.failedTableData.map(contract => {
            if (contract.contractId === contractId) {
                return {
                    ...contract,
                    showErrors: !contract.showErrors,
                    errorIconName: contract.showErrors ? 'utility:chevrondown' : 'utility:chevronup' 
                };
            }
            return contract;
        });
    }
    
    downloadFailedContracts() {
        if (!this.failedTableData || this.failedTableData.length === 0) {
            console.warn('No failed contracts to download');
            return;
        }
        
        try {
            const csvContent = this.generateCSV(this.failedTableData);
            const dataUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
            
            const link = document.createElement('a');
            link.setAttribute('href', dataUri);
            link.setAttribute('download', `Failed_Contracts_${this.getCurrentDateTime()}.csv`);
            link.style.display = 'none';
            
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            console.log('CSV download initiated successfully');
        } catch (error) {
            console.error('Error downloading CSV:', error);
            this.showToast('Error', 'Unable to download CSV file. Please try again.', 'error');
        }
    }
    
    generateCSV(data) {
        // CSV Headers
        const headers = [
            'Contract Number',
            'Contract Category',
            'Status',
            'Sync Status',
            'Validation Errors',
            'Record URL'
        ];

        // Start CSV with headers
        let csv = headers.join(',') + '\r\n';

        // Add data rows
        data.forEach(contract => {
            const row = [
                this.escapeCSV(contract.contractNumber),
                this.escapeCSV(contract.contractCategory),
                this.escapeCSV(contract.status),
                this.escapeCSV(contract.syncStatusCode),
                this.escapeCSV(this.formatErrors(contract.errorDetails)),
                this.escapeCSV(this.getFullUrl(contract.recordUrl))
            ];
            csv += row.join(',') + '\r\n';
        });
        
        return csv;
    }
    
    escapeCSV(value) {
        if (value === null || value === undefined || value === 'N/A') {
            return '""';
        }
        
        // Convert to string
        let stringValue = String(value);
        stringValue = stringValue.replace(/\r?\n/g, ' ');
        stringValue = stringValue.replace(/"/g, '""');
        
        return `"${stringValue}"`;
    }
    
    formatErrors(errorDetails) {
        if (!errorDetails) return 'No errors';
        
        return errorDetails
            .replace(/•/g, '')
            .replace(/\n/g, '; ')
            .trim();
    }
    
    getFullUrl(relativeUrl) {
        if (!relativeUrl) return '';
        
        if (relativeUrl.startsWith('http')) {
            return relativeUrl;
        }
        
        const baseUrl = window.location.origin;
        return baseUrl + relativeUrl;
    }
    
    getCurrentDateTime() {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');
        
        return `${year}${month}${day}_${hours}${minutes}${seconds}`;
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}