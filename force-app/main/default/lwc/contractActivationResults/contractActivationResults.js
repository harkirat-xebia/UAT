import { LightningElement, api, track } from 'lwc';

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
        label: 'Status',
        fieldName: 'status',
        type: 'text',
        wrapText: true,
        initialWidth: 200,
        cellAttributes: {
            iconName: 'utility:success',
            iconPosition: 'left',
            class: 'slds-text-color_success'
        }
    },
    {
        label: 'Sync Status',
        fieldName: 'syncStatusCode',
        type: 'text',
        wrapText: true,
        initialWidth: 200,
        cellAttributes: {
            class: { fieldName: 'syncStatusClass' }
        }
    }
];

export default class ContractActivationResults extends LightningElement {
    @api invalidContractsJson;
    @api validContractsJson;
    
    @track failedTableData = [];
    xlsxInitialized = false;
    successColumns = SUCCESS_COLUMNS;

    get hasFailedContracts() {
        return this.failedTableData && this.failedTableData.length > 0;
    }

    get hasSuccessfulContracts() {
        return this.successTableData && this.successTableData.length > 0;
    }

    get allSuccessful() {
        return this.hasSuccessfulContracts && !this.hasFailedContracts;
    }

    get successCount() {
        return this.successTableData ? this.successTableData.length : 0;
    }

    get failedCount() {
        return this.failedTableData ? this.failedTableData.length : 0;
    }

    get totalCount() {
        return this.successCount + this.failedCount;
    }

    get successTableData() {
        if (!this.validContractsJson) {
            return [];
        }

        try {
            const contracts = JSON.parse(this.validContractsJson);
            return contracts.map(contract => {
                return {
                    contractId: contract.contractId || contract.Id,
                    contractNumber: contract.contractNumber || contract.ContractNumber || 'N/A',
                    contractCategory: contract.contractCategory || 'N/A',
                    status: contract.status || 'Queued for Activation',
                    syncStatusCode: contract.syncStatusCode || 'Not Synced',
                    syncStatusClass: this.getSyncStatusClass(contract.syncStatusCode),
                    recordUrl: contract.recordUrl || '/' + (contract.contractId || contract.Id)
                };
            });
        } catch (e) {
            console.error('Error parsing validContractsJson:', e);
            return [];
        }
    }

    connectedCallback() {
        this.parseFailedContracts();
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

    // for csv
    downloadFailedContracts() {
        if (!this.failedTableData || this.failedTableData.length === 0) {
            console.warn('No failed contracts to download');
            return;
        }

        try {
            // Generate CSV content
            const csvContent = this.generateCSV(this.failedTableData);
            
            // Create data URI (LWS compatible)
            const dataUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
            
            // Create and trigger download
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
            // Show user-friendly error
            this.showErrorToast();
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
        
        // Replace line breaks with space
        stringValue = stringValue.replace(/\r?\n/g, ' ');
        
        // Escape double quotes
        stringValue = stringValue.replace(/"/g, '""');
        
        // Wrap in quotes
        return `"${stringValue}"`;
    }

    //FORMAT ERROR MESSAGES FOR CSV
    formatErrors(errorDetails) {
        if (!errorDetails) return 'No errors';
        
        // Replace bullet points and newlines with semicolons
        return errorDetails
            .replace(/•/g, '')
            .replace(/\n/g, '; ')
            .trim();
    }
    getFullUrl(relativeUrl) {
        if (!relativeUrl) return '';
        
        // If already full URL, return as is
        if (relativeUrl.startsWith('http')) {
            return relativeUrl;
        }
        
        // Otherwise, prepend the base URL
        const baseUrl = window.location.origin;
        return baseUrl + relativeUrl;
    }

    // GET CURRENT DATE TIME FOR FILENAME
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

    showErrorToast() {
        // If you want to show a toast notification
        const event = new ShowToastEvent({
            title: 'Download Error',
            message: 'Unable to download CSV file. Please try again.',
            variant: 'error'
        });
        this.dispatchEvent(event);
    }
}