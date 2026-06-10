import { LightningElement, api } from 'lwc';
import syncCCRtoOCR from '@salesforce/apex/OpportunityManagementWithoutSharing.syncCCRtoOCR';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CcrOcrSync extends LightningElement {
    @api recordId;
    isLoading = false;
    showConfirmation = true;
    message;

    handleConfirm() {
        this.isLoading = true;
        this.showConfirmation = false;

        syncCCRtoOCR({ contractId: this.recordId })
            .then(result => {
                this.isLoading = false;

                let toastMsg = '';
                if (result === 'UPDATED') {
                    toastMsg = 'OCR records have been successfully synchronized with the latest CCR data.';
                } else {
                    toastMsg = 'No changes found. OCRs are already up to date with CCRs.';
                }

                this.message = toastMsg;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Sync Complete',
                    message: toastMsg,
                    variant: 'success'
                }));

                // Auto close the modal after a short delay
                setTimeout(() => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }, 2000);
            })
            .catch(error => {
                this.isLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message || 'Something went wrong during OCR sync.',
                    variant: 'error'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}