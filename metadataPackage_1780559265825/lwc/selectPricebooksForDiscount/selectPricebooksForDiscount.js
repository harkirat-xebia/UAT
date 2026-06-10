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
        console.log('data:', data);
        console.log('error:', error);
        
        if (data) {
            this.discountCodeInfo = {
                Id: data.id,
                Name: data.fields.Name.value,
                ER_Promo_Code__c: data.fields.ER_Promo_Code__c.value,
                Discount_Percentage__c: data.fields.Discount_Percentage__c.value,
                Solution__c: data.fields.Solution__c.value,
                ER_Status__c: data.fields.ER_Status__c.value
            };
            
            console.log('Discount Code Info:', this.discountCodeInfo);
            
            // Check if status is Activated
            if (this.discountCodeInfo.ER_Status__c === 'Activated') {
                this.loadPricebooks();
            } else {
                this.errorMessage = 'This discount code is not activated. Status: ' + this.discountCodeInfo.ER_Status__c;
                console.log(this.errorMessage);
            }
        } else if (error) {
            console.error('Error loading discount code:', error);
            this.errorMessage = 'Failed to load discount code: ' + this.getErrorMessage(error);
        }
    }

    // Load pricebooks
    loadPricebooks() {
        console.log('=== loadPricebooks START ===');
        console.log('recordId:', this.recordId);
        
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
                        isSelected: false
                    }));
                    this.showPricebooks = true;
                    console.log('Processed pricebooks:', this.pricebooks);
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
        
        console.log('Pricebook selection:', pricebookId, isChecked);

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
        
        console.log('Selected count:', this.selectedPricebookIds.size);
    }

    handleSelectAll() {
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
        console.log('Selected pricebooks:', Array.from(this.selectedPricebookIds));
        
        if (this.selectedPricebookIds.size === 0) {
            this.showToast('Warning', 'Please select at least one pricebook', 'warning');
            return;
        }

        this.isProcessing = true;
        this.successMessage = '';
        this.errorMessage = '';

        const pricebookIdsArray = Array.from(this.selectedPricebookIds);

        createDiscountedProductsForPricebooks({
            discountCodeId: this.recordId,
            pricebookIds: pricebookIdsArray
        })
            .then(result => {
                console.log('Batch job ID:', result);
                this.successMessage = `Batch job started! Job ID: ${result}`;
                this.showToast('Success', 'Discounted products are being created', 'success');
                
                setTimeout(() => {
                    this.handleDeselectAll();
                }, 3000);
            })
            .catch(error => {
                console.error('Error creating discounts:', error);
                this.errorMessage = 'Failed: ' + this.getErrorMessage(error);
                this.showToast('Error', this.errorMessage, 'error');
            })
            .finally(() => {
                this.isProcessing = false;
                console.log('=== handleCreateDiscounts END ===');
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
        return this.isProcessing || this.selectedPricebookIds.size === 0;
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