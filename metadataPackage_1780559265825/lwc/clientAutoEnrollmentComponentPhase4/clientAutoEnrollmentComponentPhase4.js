import { LightningElement, api } from 'lwc';
import PHASE4_HEADER from '@salesforce/label/c.Phase4_Header';
import PHASE4_SUBHEADER from '@salesforce/label/c.Phase4_SubHeader';
import PROVISION_LABEL from '@salesforce/label/c.Provision_of_Services';
import CARD_DELIVERY_LABEL from '@salesforce/label/c.Card_Delivery';
import UNIT_PRICE from '@salesforce/label/c.Price';
import PRICE from '@salesforce/label/c.PriceOnly';
import FREE_LABEL from '@salesforce/label/c.Free_Delivery';
import PRICING_LABEL from '@salesforce/label/c.Standard_Pricing';
import VIEW_CONDITIONS from '@salesforce/label/c.View_General_Conditions';
import PROMO_QUESTION from '@salesforce/label/c.Do_You_Have_Promo_Code';
import YES_LABEL from '@salesforce/label/c.Yes';
import NO_LABEL from '@salesforce/label/c.No';
import PROMO_SUCCESS from '@salesforce/label/c.Promo_Success_Label';
import PROMO_ERROR from '@salesforce/label/c.promo_error_label';
import ENTER_PROMO from '@salesforce/label/c.EnterPromoLabel';
import MODAL_HEADER from '@salesforce/label/c.Client_Title_General_Conditions_P4';
import CLOSE_LABEL from '@salesforce/label/c.closeLabel';
import FINANCE_CONDITION from '@salesforce/label/c.General_Conditions_Acceptance_Label';
import BUSINESS_CONDITION_1 from '@salesforce/label/c.BusinessConditionLabelPrefix';
import BUSINESS_CONDITION_2 from '@salesforce/label/c.BusinessConditionLabelSuffix';
import GENERAL_CONDITION from '@salesforce/label/c.Prepayment_Label';
import LEGAL_CONDITION from '@salesforce/label/c.LegalConditionLabel';
import MARKETTING_CONDITION from '@salesforce/label/c.Marketting_Condition_Label';
import PROVISION_LABEL_MULTI from '@salesforce/label/c.Provision_of_Services_Multi_Product';
import PAYMENT_ACK_LABEL from '@salesforce/label/c.Payment_Ack_Label';
import Marketing_Email_Label from '@salesforce/label/c.Marketing_Email_Label';
import PRIVACY_POLICY_TEXT from '@salesforce/label/c.Privacy_Policy_Text';
import Privacy_policy_Text_part_1 from '@salesforce/label/c.Privacy_policy_Text_part_1';
import SALES_CONDITION_PART1 from '@salesforce/label/c.Sales_Condition_Label';
import SALES_CONDITION_PART2 from '@salesforce/label/c.Sales_Condition_Label_Part2';
//import SALES_TERMS_CONDITIONS_URL from '@salesforce/label/c.Sales_Terms_Conditions_Url';
import SALES_CONDITION_EN_LU from '@salesforce/label/c.Sales_Conditions_EN_LU';
import SALES_CONDITION_EN_BE from '@salesforce/label/c.Sales_Conditions_EN_BE';
import GENERAL_TERMS_LINK_TEXT from '@salesforce/label/c.General_Terms_Link_Text';
import IDENTITY_CONFIRM_LABEL from '@salesforce/label/c.Identity_Confirm_Label';
import PRIVACY_POLICY_URL from '@salesforce/label/c.Privacy_Policy_Url';
import fetchPricebookAndPromoId from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchPricebookAndPromoId';
import fetchBillableServices from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchBillableServices';
import fetchBillableServicesFromOpp from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchBillableServicesFromOpp';
import getGeneralCondition from '@salesforce/apex/clientAutoEnrollmentComponentController.getGeneralCondition';


export default class ClientAutoEnrollmentComponentPhase4 extends LightningElement {

    //Primitive Variables
    @api promoCode;
    @api productCode;
    @api businessUnit;
    @api estimatedVolume;
    @api language;
    promoId;
    pricebookId;
    termsAndConditions;
    @api termsAndConditionId;
    @api opportunityId;
    @api promoDescription

    //Collection Variables
    label={
        header: PHASE4_HEADER,
        subHeader:PHASE4_SUBHEADER,
        provisionLabel: PROVISION_LABEL,
        cardDelivery: CARD_DELIVERY_LABEL,
        unitPrice: UNIT_PRICE,
        price: PRICE,
        freeLabel: FREE_LABEL,
        pricing: PRICING_LABEL,
        viewConditions: VIEW_CONDITIONS,
        promoQuestionLabel: PROMO_QUESTION,
        yesLabel: YES_LABEL,
        noLabel: NO_LABEL,
        //New labels added by harkirat
        paymentAck: PAYMENT_ACK_LABEL,
        marketingText: Marketing_Email_Label,
        privacyPolicyText: PRIVACY_POLICY_TEXT,
        privacyPolicyUrl:PRIVACY_POLICY_URL,
        salesConditionPart1: SALES_CONDITION_PART1,
        salesConditionPart2: SALES_CONDITION_PART2,
        generalTermsText: GENERAL_TERMS_LINK_TEXT,
        identityConfirm: IDENTITY_CONFIRM_LABEL,
        promoErrorMessage: PROMO_ERROR,
        promoSuccessMessage:PROMO_SUCCESS,
        enterPromoLabel: ENTER_PROMO,
        modalHeader: MODAL_HEADER,
        closeLabel: CLOSE_LABEL,
        generalCondition: GENERAL_CONDITION,
        financeCondition: FINANCE_CONDITION,
        markettingCondition: MARKETTING_CONDITION,
        provisionLabelMulti :PROVISION_LABEL_MULTI,
        legalConditionLabel: LEGAL_CONDITION,
        businessConditionPrefix: BUSINESS_CONDITION_1,
        businessConditionSuffix: BUSINESS_CONDITION_2,
        Privacy_policy_Text_part_1 : Privacy_policy_Text_part_1,
    }
    @api productMap = {};

    //Boolean Variables
    isLoading = false;
    @api hasPromoCode = false;
    @api showPromoError = false;
    @api showPromoSuccess = false;
    @api isWebOffer = false;
    showPromoComp = true;
    showModal = false;
    //commenting old and adding new
    // generalCondition = false;
    // financeCondition = false;
    // markettingCondition = false;
    // legalCondition = false;
    // businessCondition = false;
    paymentAck = false;
    marketingOptIn = false;
    salesConditionAck = false;
    identityConfirm = false;


    //New getters for checkboxes
    get salesConditionText() {
    return this.label.salesConditionPart1; 
}
//New Code
// get nonDiscountedServices() {
//     return (this.productMap?.Service || []).filter(s => !s.isDiscountedItem);
// }

get salesConditionPart2Final() {
    if (this.language.startsWith('en')) {
        return this.businessUnit === 'BE'
            ? SALES_CONDITION_EN_BE
            : SALES_CONDITION_EN_LU;
    }

    return this.label.salesConditionPart2;
}

    get privacyPolicyLink() {
    return this.businessUnit === 'BE'
        ? 'https://myedenred.be/privacy-notice'
        : 'https://myedenred.lu/privacy-notice';
    }

//     get salesTermsLink() {
//     return SALES_TERMS_CONDITIONS_URL;
// }

    get termsLink() {
    return this.businessUnit === 'BE'
        ? 'https://myedenred.be/terms-and-conditions'
        : 'https://myedenred.lu/terms-and-conditions';
    }

    get promoInputClass() {
        if (this.showPromoSuccess) {
            return 'success';
        } else if (this.showPromoError) {
            return 'error';
        }
        return '';
    }

    get euro() {
        return '€';
    }

    get isCurrencyBefore() {
        return this.language === 'nl_BE';
    }

    closeModal() {
        this.showModal = false;
    }
    connectedCallback(){
        this.isLoading = true;
        fetchPricebookAndPromoId({
            productCode: this.productCode,
            promoCode: this.promoCode,
            businessUnit: this.businessUnit})
        .then(result=>{
            console.log('MAP of ID: ', JSON.stringify(result));
            console.log('language: ', this.language);
            if(result.promoId){
                this.promoId = result.promoId;
            }
            this.pricebookId = result.pricebookId;
            
            if(!this.hasPromoCode){
                this.showPromoComp = false;
            }

            if(this.isWebOffer){
                fetchBillableServicesFromOpp({opportunityId: this.opportunityId, promoCodeId: this.promoId, language: this.language})
                .then(result=>{
                    console.log(result);
                    this.productMap = result;
                    if(this.promoCode != null){
                        this.hasPromoCode = true;
                        if(this.productMap.Discount){
                            this.showPromoError = false;
                            this.showPromoSuccess = true;
                            this.promoDescription = this.productMap.Discount[0].promoDescription;
                        }else{
                            this.showPromoError = true;
                            this.showPromoSuccess = false;
                        }
                    }else{
                        this.hasPromoCode = false;
                    }
                })
                .catch(error=>{
                    console.error(error);
                })
                .finally(() => {
                    if (this.productMap && Array.isArray(this.productMap['Delivery'])) {
                        const updatedList = this.productMap['Delivery'].map(product => {
                            const newProduct = { ...product };
                            if (!('maxValue' in newProduct) || newProduct.maxValue === null) {
                                newProduct.maxValue = '...';
                            }
                            return newProduct;
                        });
                    
                        this.productMap = {
                            ...this.productMap,
                            Delivery: updatedList
                        };
                    }
                                         
                    console.log('deliveryList: ', JSON.stringify(this.productMap));
                    this.isLoading = false;
                    this.highlightInactiveProducts();
                })
            }else{
                fetchBillableServices({productCode: this.productCode, promoCodeId: this.promoId, pricebookId: this.pricebookId, estimatedVolume: this.estimatedVolume, language: this.language})
                .then(result=>{
                    console.log(result);
                    this.productMap = result;
                    if(this.promoCode != null){
                        this.hasPromoCode = true;
                        if(this.productMap.Discount){
                            this.showPromoError = false;
                            this.showPromoSuccess = true;
                        }else{
                            this.showPromoError = true;
                            this.showPromoSuccess = false;
                        }
                    }else{
                        this.hasPromoCode = false;
                    }
                })
                .catch(error=>{
                    console.error(error);
                })
                .finally(() => {
                    if (this.productMap && Array.isArray(this.productMap['Delivery'])) {
                        const updatedList = this.productMap['Delivery'].map(product => {
                            const newProduct = { ...product };
                            if (!('maxValue' in newProduct) || newProduct.maxValue === null) {
                                newProduct.maxValue = '...';
                            }
                            return newProduct;
                        });
                    
                        this.productMap = {
                            ...this.productMap,
                            Delivery: updatedList
                        };
                    }
                                         
                    console.log('deliveryList: ', JSON.stringify(this.productMap));
                    this.isLoading = false;
                    this.highlightInactiveProducts();
                })
            }      
        })
        .catch(error=>{
            console.error(error);
        })
        


        getGeneralCondition({language: this.language, productCode: this.productCode, businessUnit: this.businessUnit})
        .then(result=>{
            this.termsAndConditions = result.BE_Body__c;
            this.termsAndConditionId = result.Id;
        })
        .catch(error=>{
            console.error(error);
        })
    }

    highlightInactiveProducts() {
        setTimeout(() => {
            if (!this.productMap || !this.productMap.Service) return;
            this.productMap.Service.forEach(prod => {
                if (prod.productBrand) {
                    //const container = this.template.querySelector(`div[data-id="${prod.productId}"]`);
                    const container = this.template.querySelector(`[data-id="${prod.productId}"]`);
                    console.log(container);
                    if (container) {
                        container.style.border = `2px solid ${prod.productBrand}`;
                    }
                    // Set font color specifically for <s> tags
                    const strikeTags = this.template.querySelectorAll(`s[data-id="${prod.productId}"]`);
                    strikeTags.forEach(tag => {
                        tag.style.color = 'black';
                    });

                    // Set font color specifically for <span> tags
                    const spanTags = this.template.querySelectorAll(`span[data-id="${prod.productId}"]`);
                    spanTags.forEach(tag => {
                        tag.style.color = '#00A184';
                    });

                    const h2Tags = this.template.querySelectorAll(`h2[data-id="${prod.productId}"]`);
                    h2Tags.forEach(tag => {
                        tag.style.color = prod.productBrand;
                    });
                }
            });
        }, 0);
    }
    

    openModal() {
        this.showModal = true;

        requestAnimationFrame(() => {
            const container = this.template.querySelector('.terms-body');
            if (container) {
                container.innerHTML = this.termsAndConditions;
            }
        });
    }

    handleInputChange(event) {
        const field = event.target.name;
        const value = event.detail?.value || event.target.value;
    
        if (event.target.type === 'checkbox' || event.target.type === 'toggle') {
            this[field] = event.target.checked;
            console.log(field, ' result: ', event.target.checked);
            
        }else{
            this[field] = value;
        }
    }

    //Added by harkirat to stop the save if checkbox are not checked
    @api
    validateMandatoryCheckboxes() {
        return (
            this.paymentAck === true &&
            this.salesConditionAck === true &&
            this.identityConfirm === true
        );
    }

    handleApplyPromo(event){
        if (event.key === 'Enter') {
            this.isLoading = true;
            fetchPricebookAndPromoId({
                productCode: this.productCode,
                promoCode: this.promoCode,
                businessUnit: this.businessUnit})
            .then(result=>{
                console.log('MAP of ID: ', JSON.stringify(result));
                console.log('language: ', this.language);
                if(result.promoId){
                    this.promoId = result.promoId;
                }else{
                    this.promoId = null;
                }
                this.pricebookId = result.pricebookId;
                
                fetchBillableServices({productCode: this.productCode, promoCodeId: this.promoId, pricebookId: this.pricebookId, estimatedVolume: this.estimatedVolume, language: this.language})
                .then(result=>{
                    console.log(result);
                    this.productMap = result;
                    if(this.productMap.Discount){
                        this.showPromoError = false;
                        this.showPromoSuccess = true;
                        this.promoDescription = this.productMap.Discount[0].promoDescription;
                    }else{
                        this.showPromoError = true;
                        this.showPromoSuccess = false;
                    }
                    if (this.productMap && Array.isArray(this.productMap['Delivery'])) {
                        const updatedList = this.productMap['Delivery'].map(product => {
                            const newProduct = { ...product };
                            if (!('maxValue' in newProduct) || newProduct.maxValue === null) {
                                newProduct.maxValue = '...';
                            }
                            return newProduct;
                        });
                    
                        this.productMap = {
                            ...this.productMap,
                            Delivery: updatedList
                        };
                    }
                                         
                    console.log('deliveryList: ', JSON.stringify(this.productMap));                 
                })
                .catch(error=>{
                    console.error(error);
                })
                .finally(()=>{
                    this.highlightInactiveProducts();
                })
            })
            .catch(error=>{
                console.error(error);
            })
            .finally(()=>{
                this.isLoading = false;
            })
        }
    }

    @api
    validateFields() {
        let isValid = true;
        const inputs = this.template.querySelectorAll('[data-form-element]');
        inputs.forEach(input => {
            if (typeof input.reportValidity === 'function' && typeof input.checkValidity === 'function') {
                if (!input.checkValidity()) {
                    input.reportValidity();
                    isValid = false;
                }
            }
        }); 
        
        return isValid;
    }
    @api
    getData() {
        return {
            pricebookId: this.pricebookId,
            promoId: this.promoId,
            termsAndConditionId: this.termsAndConditionId,
            productMap: this.productMap,
            hasPromoCode: this.hasPromoCode,
            promoCode: this.promoCode,
            showPromoError: this.showPromoError,
            showPromoSuccess: this.showPromoSuccess,
            //Commenting the old and adding new 
            // generalCondition: this.generalCondition,
            // financeCondition: this.financeCondition,
            // markettingCondition: this.markettingCondition,
            // legalCondition: this.legalCondition,
            // businessCondition: this.businessCondition,
            paymentAck: this.paymentAck,
            marketingOptIn: this.marketingOptIn,
            salesConditionAck: this.salesConditionAck,
            identityConfirm: this.identityConfirm
        };
    }
}