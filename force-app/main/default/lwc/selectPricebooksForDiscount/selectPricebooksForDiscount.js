import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPricebooksForDiscount from '@salesforce/apex/DiscountPricebookController.getPricebooksForDiscount';
import createDiscountedProductsForPricebooks from '@salesforce/apex/DiscountPricebookController.createDiscountedProductsForPricebooks';

// Import fields
const FIELDS = [
    'ER_Promo_Code__c.ER_Promo_Code__c',
    'ER_Promo_Code__c.Name',
    'ER_Promo_Code__c.Discount_Percentage__c',
    'ER_Promo_Code__c.Solution__c',
    'ER_Promo_Code__c.ER_Status__c'
];

export default class SelectPricebooksForDiscount extends LightningElement {
    @api recordId;

    @track pricebooks = [];
    @track selectedPricebookIds = new Set();
    discountCodeInfo;

    isLoadingPricebooks = false;
    isProcessing = false;
    showPricebooks = false;
    successMessage = '';
    errorMessage = '';

    // Wire to get current discount code record
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        console.log('=== Wire getRecord ===');
        console.log('recordId:', this.recordId);

        if (data) {
            this.discountCodeInfo = {
                Id: data.id,
                Name: data.fields.Name.value,
                ER_Promo_Code__c: data.fields.ER_Promo_Code__c.value,
                Discount_Percentage__c: data.fields.Discount_Percentage__c.value,
                Solution__c: data.fields.Solution__c.value,
                ER_Status__c: data.fields.ER_Status__c.value
            };

            if (this.discountCodeInfo.ER_Status__c === 'Activated') {
                this.loadPricebooks();
            } else {
                this.errorMessage = 'This discount code is not activated. Status: ' + this.discountCodeInfo.ER_Status__c;
            }
        } else if (error) {
            console.error('Error loading discount code:', error);
            this.errorMessage = 'Failed to load discount code: ' + this.getErrorMessage(error);
        }
    }

    // Load pricebooks. The controller stamps hasExistingPBE on each pricebook so we
    // know which ones were already processed (by the auto-trigger batch or a previous
    // manual run) without a separate server call.
    loadPricebooks() {
        console.log('=== loadPricebooks START ===');

        this.isLoadingPricebooks = true;
        this.errorMessage = '';
        this.successMessage = '';

        getPricebooksForDiscount({ discountCodeId: this.recordId })
            .then(result => {
                console.log('Pricebooks loaded:', result);

                if (result && result.length > 0) {
                    this.pricebooks = result.map(pb => ({
                        Id: pb.Id,
                        Name: pb.Name,
                        Description: pb.Description,
                        IsActive: pb.IsActive,
                        hasExistingPBE: pb.hasExistingPBE === true,
                        isSelected: false
                    }));
                    this.showPricebooks = true;
                } else {
                    this.pricebooks = [];
                    this.showPricebooks = true;
                    this.showToast('Info', 'No pricebooks found for this discount code', 'info');
                }
            })
            .catch(error => {
                console.error('Error loading pricebooks:', error);
                this.errorMessage = 'Failed to load pricebooks: ' + this.getErrorMessage(error);
                this.showToast('Error', this.errorMessage, 'error');
            })
            .finally(() => {
                this.isLoadingPricebooks = false;
                console.log('=== loadPricebooks END ===');
            });
    }

    handlePricebookSelection(event) {
        const pricebookId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.pricebooks = this.pricebooks.map(pb => {
            if (pb.Id === pricebookId) {
                return { ...pb, isSelected: isChecked };
            }
            return pb;
        });

        if (isChecked) {
            this.selectedPricebookIds.add(pricebookId);
        } else {
            this.selectedPricebookIds.delete(pricebookId);
        }
    }

    handleSelectAll() {
        if (this.anyPricebookAlreadyCreated) return;
        this.pricebooks = this.pricebooks.map(pb => ({ ...pb, isSelected: true }));
        this.selectedPricebookIds = new Set(this.pricebooks.map(pb => pb.Id));
    }

    handleDeselectAll() {
        this.pricebooks = this.pricebooks.map(pb => ({ ...pb, isSelected: false }));
        this.selectedPricebookIds.clear();
    }

    handleRefresh() {
        this.selectedPricebookIds.clear();
        this.loadPricebooks();
    }

    handleCreateDiscounts() {
        console.log('=== handleCreateDiscounts START ===');

        if (this.selectedPricebookIds.size === 0) {
            this.showToast('Warning', 'Please select at least one pricebook', 'warning');
            return;
        }

        this.isProcessing = true;
        this.successMessage = '';
        this.errorMessage = '';

        const pricebookIdsArray = Array.from(this.selectedPricebookIds);
        const submittedPricebookIds = new Set(this.selectedPricebookIds);

        createDiscountedProductsForPricebooks({
            discountCodeId: this.recordId,
            pricebookIds: pricebookIdsArray
        })
            .then(result => {
                console.log('Batch job ID:', result);
                this.successMessage = `Batch job started successfully. Refresh the page to see the updated status.`;
                this.showToast('Success', 'Discounted products are being created', 'success');

                // Optimistically mark submitted pricebooks as already having PBEs so the
                // warning banners appear immediately and the user cannot trigger a duplicate run
                // before refreshing the page (the batch runs async so server won't reflect
                // this yet, but we know we just submitted it).
                this.pricebooks = this.pricebooks.map(pb => ({
                    ...pb,
                    isSelected: false,
                    hasExistingPBE: pb.hasExistingPBE || submittedPricebookIds.has(pb.Id)
                }));
                this.selectedPricebookIds = new Set();
            })
            .catch(error => {
                console.error('Error creating discounts:', error);
                this.errorMessage = 'Failed: ' + this.getErrorMessage(error);
                this.showToast('Error', this.errorMessage, 'error');
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    // Getters
    get hasPricebooks() {
        return this.pricebooks && this.pricebooks.length > 0;
    }

    get selectedCount() {
        return this.selectedPricebookIds.size;
    }

    get isCreateDisabled() {
        return this.isProcessing || this.selectedPricebookIds.size === 0 || this.anyPricebookAlreadyCreated;
    }

    // True when ANY pricebook already has PBEs — blocks all further creation for this discount code
    get anyPricebookAlreadyCreated() {
        return this.pricebooks.length > 0 && this.pricebooks.some(pb => pb.hasExistingPBE);
    }

    // Utility methods
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getErrorMessage(error) {
        if (error && error.body) {
            if (error.body.message) {
                return error.body.message;
            }
            if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors[0].message;
            }
            if (error.body.fieldErrors) {
                const fieldErrors = [];
                Object.keys(error.body.fieldErrors).forEach(field => {
                    error.body.fieldErrors[field].forEach(err => {
                        fieldErrors.push(err.message);
                    });
                });
                if (fieldErrors.length > 0) {
                    return fieldErrors.join(', ');
                }
            }
        }
        if (error && error.message) {
            return error.message;
        }
        if (typeof error === 'string') {
            return error;
        }
        return 'Unknown error occurred';
    }
}
