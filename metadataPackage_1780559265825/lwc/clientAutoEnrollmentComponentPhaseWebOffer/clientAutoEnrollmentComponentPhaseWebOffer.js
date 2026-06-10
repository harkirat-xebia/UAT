import { LightningElement, api } from 'lwc';
import fetchBillableServicesFromOpp from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchBillableServicesFromOpp';
import BENEF_SUB from '@salesforce/label/c.Beneficiary_sub_header';
import FACE_VALUE_LABEL from '@salesforce/label/c.FaceValueLabel';
import ESTIMATION_LABEL from '@salesforce/label/c.Order_Estimation_label';
import ORDERFEE_LABEL from '@salesforce/label/c.Order_Fee_Label';
export default class ClientAutoEnrollmentComponentPhaseWebOffer extends LightningElement {

    @api opportunityId;
    @api promoId;
    @api language;

    @api productMap = {};
    label={
        beneficiarySubHeader: BENEF_SUB,
        faceValueLabel: FACE_VALUE_LABEL,
        estimationLabel: ESTIMATION_LABEL,
        orderFee: ORDERFEE_LABEL
    }

    isLoading = false;
    isWebOffer = true;
    
    connectedCallback(){
        this.getBillableServices();
    }

    getBillableServices(){
        this.isLoading = true;
        console.log('opportunityId: ', this.opportunityId);
        console.log('promoCodeId: ', this.promoId);
        console.log('language: ', this.language);
        fetchBillableServicesFromOpp({opportunityId: this.opportunityId, promoCodeId: this.promoId, language: this.language})
        .then(result=>{
            console.log('Phase Offer');
            console.log(result);
            this.productMap = result;
        })
        .catch(error=>{
            console.error(error);
        })
        .finally(() => {
            this.isLoading = false;
            this.highlightInactiveProducts();
        })
    }

    highlightInactiveProducts() {
        setTimeout(() => {
            if (!this.productMap || !this.productMap.Service) return;
    
            this.productMap.Service.forEach(prod => {
                if (prod.productBrand) {
                    const dataId = prod.productId;

                    const allContainers = this.template.querySelectorAll(`div[data-id="${dataId}"]`);
                    allContainers.forEach(container => {
                        container.style.border = `2px solid ${prod.productBrand}`;
                    });
                }
            });
        }, 0);
    }

}