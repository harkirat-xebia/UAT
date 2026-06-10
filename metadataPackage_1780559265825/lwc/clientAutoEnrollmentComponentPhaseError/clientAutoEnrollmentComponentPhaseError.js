import { LightningElement, api, track } from 'lwc';
import fetchActiveProducts from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchActiveProducts';
import getActiveContractStatus from '@salesforce/apex/clientAutoEnrollmentComponentController.getActiveContractStatus';
import { NavigationMixin } from 'lightning/navigation';
import PHASEERROR_HEADER from '@salesforce/label/c.PhaseError_Header';
import PHASEERROR_SUBHEADER from '@salesforce/label/c.PhaseError_SubHeader';
import MM_OPP_ERROR from '@salesforce/label/c.Error_Message_Size_Too_Big';
import MM_OPP_ERROR_END from '@salesforce/label/c.MM_error_offer_end';
import MM_OPP_ERROR_HEADER from '@salesforce/label/c.MM_Error_header';
import BUTTON_LABEL_HELP from '@salesforce/label/c.helpCenterLabel';
import BUTTON_LABEL_MYEDENRED from '@salesforce/label/c.MyEdenredLabel';
import BUTTON_LINK_HELP_BE from '@salesforce/label/c.helpCenterLinkBE';
import BUTTON_LINK_MYEDENRED_BE from '@salesforce/label/c.MyEdenredLinkBE';
import BUTTON_LINK_HELP_LU from '@salesforce/label/c.helpCenterLinkLU';
import BUTTON_LINK_MYEDENRED_LU from '@salesforce/label/c.MyEdenredLinkLU';
import CELEBRATION_ICON from '@salesforce/resourceUrl/celebIcon';


export default class ClientAutoEnrollmentComponentPhaseError extends NavigationMixin(LightningElement) {
    
    //Primitive Variables
    @api enterpriseNumber;
    @api language;
    @api businessUnit;
    @api productCode;
    iconUrl = CELEBRATION_ICON;

    //Collections
    activeProducts = [];
    label = {
        header: PHASEERROR_HEADER,
        subHeader: PHASEERROR_SUBHEADER,
        mmError: MM_OPP_ERROR,
        mmErrorEnd: MM_OPP_ERROR_END,
        mmErrorHeader: MM_OPP_ERROR_HEADER,
        helpCenterLabel: BUTTON_LABEL_HELP,
        myEdenredLabel: BUTTON_LABEL_MYEDENRED,
        helpCenterLinkBE: BUTTON_LINK_HELP_BE,
        helpCenterLinkLU: BUTTON_LINK_HELP_LU,
        myEdenredLinkBE: BUTTON_LINK_MYEDENRED_BE,
        myEdenredLinkLU: BUTTON_LINK_MYEDENRED_LU

    }

    //Boolean Variables
    isActiveContract = false; //Added by harkirat to hide products
    isLoading = false;
    rendered = false;
    @api showMMErrorComp = false;

    connectedCallback() {
        this.checkActiveContract();
    }
    renderedCallback() {
        if (this.activeProducts && this.activeProducts.length > 0) {
            this.activeProducts.forEach(product => {
                if (!product.isActive && product.productBrand) {
                    const container = this.template.querySelector(`div[data-id="${product.id}"]`);
                    if (container) {
                        container.style.borderColor = product.productBrand;
                    }
                }else{
                        const container = this.template.querySelector(`div[data-id="${product.id}"]`);
                        console.log(container);
                        if (container) {
                            container.style.border = `2px solid grey`;
                        }
                    }
            });
        }
    }

    //New method added by harkirat
    checkActiveContract() {
    getActiveContractStatus({ enterpriseNumber: this.enterpriseNumber })
        .then(result => {
            console.log('Raw Apex result:', result);

            this.isActiveContract = (result === 'Active' || result === 'Activated');
            console.log('Computed isActiveContract:', this.isActiveContract);

            if (!this.isActiveContract) {
                console.log('Loading products because NOT active');
                this.loadActiveProducts();
            } else {
                console.log('NOT loading products because contract IS active');
            }
        })
        .catch(error => {
            console.error('Error checking contract status', error);
            this.loadActiveProducts();
        });
}


    
    loadActiveProducts() {
        this.isLoading = true;
        this.error = null;
    
        fetchActiveProducts({
            enterpriseNumber: this.enterpriseNumber,
            language: this.language,
            businessUnit: this.businessUnit
        })
        .then(result => {
            this.activeProducts = result.map(prod => ({
                id: prod.Id,
                name: prod.Name,
                isActive: prod.IsActive,
                productBrand: prod.ProductBrand,
                productCode: prod.ProductCode,
                imageUrl: `/resource/ProductImages/${prod.ProductCode}.svg`
            }));
            console.log(JSON.stringify(this.activeProducts));
            setTimeout(() => {
                this.activeProducts.forEach(prod => {
                    if (!prod.isActive && prod.productBrand) {
                        const container = this.template.querySelector(`div[data-id="${prod.id}"]`);
                        console.log(container);
                        if (container) {
                            container.style.border = `2px solid ${prod.productBrand}`;
                        }
                    }else{
                        const container = this.template.querySelector(`div[data-id="${prod.id}"]`);
                        console.log(container);
                        if (container) {
                            container.style.border = `2px solid grey`;
                        }
                    }
                });
            }, 0);

        })
        .catch(error => {
            this.error = 'Failed to load products';
            console.error(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    get helpCenterLink() {
        if (this.businessUnit === 'BE') {
            return this.label.helpCenterLinkBE;
        } else if (this.businessUnit === 'LU') {
            return this.label.helpCenterLinkLU;
        }
        return '';
    }
    
    get myEdenredLink() {
        if (this.businessUnit === 'BE') {
            return this.label.myEdenredLinkBE;
        } else if (this.businessUnit === 'LU') {
            return this.label.myEdenredLinkLU;
        }
        return '';
    }

    
    handleMyEdenredOnClick(){
        window.open(this.myEdenredLink, '_blank');
    }
    handleEdenredBEOnClick(){
        window.open(this.helpCenterLink, '_blank');
    }    
}