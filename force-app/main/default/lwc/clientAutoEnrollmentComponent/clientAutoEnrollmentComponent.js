import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference, NavigationMixin  } from 'lightning/navigation';
import fetchProductsFromProductCode from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchProductsFromProductCode';
import fetchPromoCodeDetails from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchPromoCodeDetails';
import createLead from '@salesforce/apex/clientAutoEnrollmentComponentController.createLead';
import validateAndConvertLead from '@salesforce/apex/clientAutoEnrollmentComponentController.validateAndConvertLead';
import getInfoFromBelfirst from '@salesforce/apex/clientAutoEnrollmentComponentController.getInfoFromBelfirst';
import updateLeadRegistrationFields from '@salesforce/apex/clientAutoEnrollmentComponentController.updateLeadRegistrationFields';
import getMaxBeneficiaryCount from '@salesforce/apex/clientAutoEnrollmentComponentController.getMaxBeneficiaryCount';
import getSMESizeLimit from '@salesforce/apex/clientAutoEnrollmentComponentController.getSMESizeLimit';
import PREVIOUS from '@salesforce/label/c.Previous_Button';
import NEXT from '@salesforce/label/c.Next_Button';
import WELCOME from '@salesforce/label/c.AutoEnrollment_Welcome_Message';
import WELCOME_SUB from '@salesforce/label/c.AutoEnrollment_Welcome_Message_Sub';
import PHRASE from '@salesforce/label/c.AutoEnrollment_Welcome_Message_Phrase';
import PROMO_HEADER from '@salesforce/label/c.AE_Promo_Header';
import PROMO_SUBHEADER from '@salesforce/label/c.AE_Promo_SubHeader';
import BENEF_FIRST from '@salesforce/label/c.Beneficiary_first_header';
import BENEF_SECOND from '@salesforce/label/c.Beneficiary_second_header';
import BENEF_SUB from '@salesforce/label/c.Beneficiary_sub_header';
import BENEF_ERROR from '@salesforce/label/c.BE_Error_Message_Number_Beneficiaries_Opportunity';
import PHASE4_END_BTN from '@salesforce/label/c.Phase4BtnConfirmLabel';


import PATH_PHASE_1 from '@salesforce/label/c.PathPhase1Label';
import PATH_PHASE_2 from '@salesforce/label/c.PathPhase2Label';
import PATH_PHASE_3 from '@salesforce/label/c.PathPhase3Label';
import PATH_PHASE_4 from '@salesforce/label/c.PathPhase4Label';

import PROCESSING_HEADER from '@salesforce/label/c.ProcessingHeader';
import PROCESSING_SUB_HEADER from '@salesforce/label/c.ProcessingSubHeader';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import ER_CUSTOM_CSS from '@salesforce/resourceUrl/EdenredCustomCSS'; 
import upsertContactsAndRoles from '@salesforce/apex/clientAutoEnrollmentComponentController.upsertContactsAndRoles';
import updateAccountData from '@salesforce/apex/clientAutoEnrollmentComponentController.updateAccountData';
import createServicesAndContract from '@salesforce/apex/clientAutoEnrollmentComponentController.createServicesAndContract';
import createQuote from '@salesforce/apex/clientAutoEnrollmentComponentController.createQuote';
import createContract from '@salesforce/apex/clientAutoEnrollmentComponentController.createContract';
import submitAgreedToGeneralConditions from '@salesforce/apex/clientAutoEnrollmentComponentController.submitAgreedToGeneralConditions';
import fetchDataFromOpportunity from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchDataFromOpportunity';
import fetchMultiProductsFromOpportunity from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchMultiProductsFromOpportunity';
import updateEnterpriseDetails from '@salesforce/apex/clientAutoEnrollmentComponentController.updateAccount';
import LOGO from '@salesforce/resourceUrl/EdenredLogo';
import flagTelpicker from '@salesforce/resourceUrl/flagTelpicker';
import updateMarketingPreference from '@salesforce/apex/clientAutoEnrollmentComponentController.updateMarketingPreference';

export default class ClientAutoEnrollmentComponent extends NavigationMixin(LightningElement) {


    //Primitive Variables
    sourceId = '';
    productCode;
    productName;
    productId;
    noOfBeneficiaries= 0;
    daysPerMonth;
    faceValue = 0;
    noOfEmployees = 0;
    loadPerYear;
    phase = 0;
    promoCode;
    businessUnit;
    description;
    markettingDescription;
    subPhase = '';
    translatedProductName = ' Edenred Repas *';
    createdLeadId;
    salutation;
    firstName;
    lastName;
    language;
    role;
    email;
    phone;
    mobile;
    countryCode = 'BE';
    dialCode = '+32';
    countryCodePhone = 'BE';
    dialCodePhone = '+32';
    enterpriseNumber;
    registrationNumber;
    businessName;
    commercialName;
    codeTVA;
    streetNumber;
    city;
    postalCode;
    pays;
    legalForm;
    maxBenefCount = 0;
    smeSizeLimit = 29;
    opportunityId;
    primaryContactId;
    billingContactId;         
    orderContactId;           
    deliveryContactId;        
    socialSecretary;      
    isSocialSecretaryHandlingOrders = false;
    shippingName;
    shippingStreet;
    shippingPostalCode;
    shippingCity;
    shippingCountry;
    estimatedVolume = 0;
    pricebookId;
    promoId;
    termsAndConditionId;
    quoteId;
    accountId;
    productTranslation;

    //Collections
    productDetail;
    promoDetail;
    label = {
        previous: PREVIOUS,
        next: NEXT,
        welcomeMessage: WELCOME,
        welcomePhrase: PHRASE,
        beneficiaryFirstHeader: BENEF_FIRST,
        beneficiarySecondHeader: BENEF_SECOND,
        beneficiarySubHeader: BENEF_SUB,
        welcomeMessageSub: WELCOME_SUB,
        promoHeader: PROMO_HEADER,
        promoSubHeader: PROMO_SUBHEADER,
        pathPhase1: PATH_PHASE_1,
        pathPhase2: PATH_PHASE_2,
        pathPhase3: PATH_PHASE_3,
        pathPhase4: PATH_PHASE_4,
        phaseEndNextButton:  PHASE4_END_BTN,
        processingHeader: PROCESSING_HEADER,
        processingSubHeader: PROCESSING_SUB_HEADER
    };
    welcomeMessage = WELCOME;
    enterpriseDetails;
    mapOfObj;
    mapOfContacts = {}; 
    opportunityContactRolesMap ={};
    productMap = {};
    multiProductList;
    
    //Boolean Variables
    isLoading = false;
    isWebOffer = false;
    promoExists = false;
    showBeneficiaryComp = false;
    isLeadCreated = false;
    hasEnterpriseNumber = false;
    companyValidated = false;
    companyValuesAreNull = true;
    vatCheckbox = false;
    showErrorComponent = false;
    showMMErrorComp = false;
    isEmployeeSameAsBenef = true;
    isBillingSameAsShipping = true;
    showEnd = false;
    hasPromoCode = false;
    showPromoError = false;
    showPromoSuccess = false;
    generalCondition = false;
    financeCondition = false;
    //Commenting and adding new line
    //markettingCondition = false;
    marketingOptIn = false;
    legalCondition = false;
    businessCondition = false;
    optin = false;
    disableNext = false;
    fetchedPromoId;
    jobTitle;
    department;
    subDepartment;

    @track data;
    @track progress = 0;
    intervalId;
    @track showProgress = false;

    @wire(CurrentPageReference)
    currentPageReference;

    @wire(getMaxBeneficiaryCount)
    wiredBenefValue({ error, data }) {
        if (data) {
            console.log('data: ', data);
            this.maxBenefCount = data;
        } else if (error) {
            console.error('Error fetching custom metadata:', error);
        }
    }
    @wire(getSMESizeLimit)
    wiredSizeValue({ error, data }) {
        if (data) {
            this.smeSizeLimit = data;
        } else if (error) {
            console.error('Error fetching custom metadata:', error);
        }
    }

    get showPath(){
        return this.phase !== 0 || this.showBeneficiaryComp 
    }

    get isPhase0() {
        return this.phase === 0;
    }
    get hidePrevious(){
        return this.phase === 0 || this.subPhase == 'contact' || (this.phase === 2 && this.isWebOffer);
    }

    get isPhase1() {
        return this.phase === 1;
    }

    get isPhase2() {
        return this.phase === 2 && this.subPhase !== 'contact';
    }

    get isPhase2Contact() {
        return this.phase === 2 && this.subPhase === 'contact';
    }

    get isPhase3() {
        return this.phase === 3;
    }

    get isPhase4() {
        return this.phase === 4;
    }
    get nextButton() {
        return this.phase === 4 ? this.label.phaseEndNextButton : this.label.next;
    }
    get isPhaseWebOffer() {
        return this.isWebOffer && this.phase == -1;
    }

    get isPhaseNegative() {
        return this.phase == -1;
    }
    
    get contactStepClass() {
        return this.phase >= 1 ? 'step-item slds-is-active' : 'step-item';
    }

    get enterpriseStepClass() {
        return this.phase >= 2 ? 'step-item slds-is-active' : 'step-item';
    }

    get commandeStepClass() {
        return this.phase >= 3 ? 'step-item slds-is-active' : 'step-item';
    }

    get signatureStepClass() {
        return this.phase >= 4 ? 'step-item slds-is-active' : 'step-item';
    }

    logoUrl = LOGO;

    @track selectedLanguage = 'en_US';

    get languageOptions() {
        return [
            { label: 'FR', value: 'fr_BE' },
            { label: 'NL', value: 'nl_BE' },
            { label: 'EN', value: 'en_US' }
        ];
    }

    renderedCallback(){
        Promise.all([
            loadStyle(this, flagTelpicker + '/css/intlTelInput.css'),
            loadScript(this, flagTelpicker + '/js/utils.js'),
            loadScript(this, flagTelpicker + '/js/intlTelInput.js')
        ])
        .then(() => {
            console.log('FlagTelPicker resources loaded successfully');
        })
        .catch(error => {
            console.error('Error loading FlagTelPicker resources:', error);
        });
    }

    handleLanguageChange(event) {
        const newLanguage = event.detail.value;
    
        const currentState = this.currentPageReference.state;
    
        const newState = {
            ...currentState,
            language: newLanguage
        };
    
        const newUrl = window.location.pathname + '?' + this.encodeStateToQueryString(newState);
    
        window.location.href = newUrl;
    }
    
    encodeStateToQueryString(state) {
        return Object.keys(state)
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(state[key])}`)
            .join('&');
    }

    connectedCallback() {      
        loadStyle(this, ER_CUSTOM_CSS)
            .then(() => {
                console.log('Custom CSS loaded successfully');
            })
            .catch(error => {
                console.error('Error loading custom CSS:', error);
            });
            
        console.log('params: ', this.currentPageReference.state); 
        this.selectedLanguage = this.currentPageReference.state.language;
        this.productCode = this.currentPageReference.state.product;
        this.key = this.currentPageReference.state.key;
        if(this.key){
            this.key = this.key.replaceAll(' ', '+');
        }
        
        this.promoCode = this.currentPageReference.state.promocode;
        this.sourceId = this.currentPageReference.state.sourceId;

        if(!this.productCode && !this.key){
            window.location.href = 'https://www.edenred.be';
        }else if(this.productCode && !this.key ){
            this.fetchProductDetails();
        }else if((!this.productCode && this.key) || (this.productCode && this.key)){
            this.isLoading = true;
            this.isWebOffer = true;
            this.fetchProductDetails();
            this.fetchDataFromOpportunity();
        }
        window.dataLayer = window.dataLayer || [];
        window.dataLayer.push({
            event: 'funnel',
            funnel_step: 'Step0homescreen',
            promoCode: this.promoCode || '',
            light_offer: this.isWebOffer,
            funnel_product: this.productCode,
            error_status: []
        });

    }

    fetchProductDetails(){
        this.isLoading = true;
        fetchProductsFromProductCode({productCode: this.productCode, language: this.selectedLanguage})
        .then((result)=>{
            this.isLoading = false;
            this.productDetail = result.product;
            this.productId = this.productDetail.Id;
            this.productName = result.translatedName;
            this.daysPerMonth = this.productDetail.Days_per_Month__c;
            this.faceValue = this.productDetail.Face_Value__c;
            this.loadPerYear = this.productDetail.Load_Per_Year__c;
            this.businessUnit = this.productDetail.ER_BUPicklist__c;
            if (this.businessUnit === 'BE') {
                this.countryCode = 'BE';
                this.dialCode = '+32';
                this.countryCodePhone = 'BE';
                this.dialCodePhone = '+32';
            } else if (this.businessUnit === 'LU') {
                this.countryCode = 'LU';
                this.dialCode = '+352';
                this.countryCodePhone = 'LU';
                this.dialCodePhone = '+352';
            }
            this.translatedProductName = ' ' + result.translatedName + ' *';
            this.productTranslation = result.translatedName;
            this.welcomeMessage = this.welcomeMessage.replace("{0}", result.translatedName);
            console.log('result: ', this.productDetail);
            if(this.promoCode){
                this.fetchPromoDetails();
            }
        })
        .catch((error)=>{
            console.error(error);
        })
    }
    fetchPromoDetails(){
        this.isLoading = true;
        fetchPromoCodeDetails({promoCode: this.promoCode, businessUnit: this.businessUnit, language: this.selectedLanguage, productId: this.productId})
        .then((result)=>{
            this.isLoading = false;
            if(Object.keys(result).length !== 0){
                this.promoExists = true;
                this.promoDetail = result;
                this.description = this.promoDetail.description;
                this.markettingDescription = this.promoDetail.markettingDescription;
                this.fetchedPromoId = this.promoDetail.promoId;
            }
            console.log('result: ', result);
        })
        .catch((error)=>{
            console.error(error);
        })
    }
    handleNext(){
        if(this.phase == 0 ){
            console.log('noOfBeneficiaries: ', this.noOfBeneficiaries);
            
            if(this.noOfBeneficiaries != 0){
                if(this.validateCurrentPhaseFields()){
                    this.phase++;
                    window.dataLayer = window.dataLayer || [];
                    window.dataLayer.push({
                        event: 'funnel',
                        funnel_step: 'Step0numberofbeneficiaries',
                        promoCode: this.promoCode || '',
                        light_offer: this.isWebOffer,
                        funnel_product: this.productCode,
                        error_status: []
                    });
                }else{
                    console.log('Required Fields not filled');
                }
            }else{
                if(!this.showBeneficiaryComp){
                    this.showBeneficiaryComp = true;
                }else{
                    const errMessage = BENEF_ERROR;
                    this.showError(errMessage);
                }
                
            }
            
        }else if(this.phase == 1){
            this.fetchLeadDetailsFromChild();
            if(this.validateCurrentPhaseFields()){
                if(!this.isWebOffer){
                    this.createLead();
                }else{
                    this.phase++;
                    window.dataLayer = window.dataLayer || [];
                    window.dataLayer.push({
                        event: 'funnel',
                        funnel_step: 'Step1contact',
                        promoCode: this.promoCode || '',
                        light_offer: this.isWebOffer,
                        funnel_product: this.productCode,
                        numberofBeneficiaries: this.noOfBeneficiaries,
                        error_status: []
                    });
                }
            }else{
                console.log('Required Fields not filled');
                
            }
        }else if(this.phase == 2){
            this.fetchEnterpriseDetailsFromChild();
            if(this.subPhase != 'contact'){
                if((this.enterpriseNumber != null && this.enterpriseNumber != undefined) && !this.hasEnterpriseNumber){
                    if(this.validateCurrentPhaseFields()){
                        if(!this.isWebOffer){
                            this.getCompanyInfo();
                        }else{
                            this.hasEnterpriseNumber = true;
                            window.dataLayer = window.dataLayer || [];
                            window.dataLayer.push({
                                event: 'funnel',
                                funnel_step: 'Step2enterpriseaftercompanynumber',
                                promoCode: this.promoCode || '',
                                light_offer: this.isWebOffer,
                                funnel_product: this.productCode,
                                numberofBeneficiaries: this.noOfBeneficiaries,
                                error_status: []
                            });
                        }
                    }else{
                        console.log('Required Fields not filled');
                    }
                }else if(this.hasEnterpriseNumber && this.companyValuesAreNull){
                    this.showError();
                }else{
                    console.log('Came HERE');
                    if(this.validateCurrentPhaseFields()){
                        if(!this.isWebOffer){
                            this.validateCompanyDetails();
                        }else{
                            this.updateCompany();
                        }
                    }else{
                        console.log('Required Fields not filled');
                    }
                } 
            }else{
                this.fetchContactDetailsFromChild();
                if(this.validateCurrentPhaseFields()){
                    this.upsertContactAndRoles();
                }
            }  
        }else if(this.phase == 3){
            this.fetchAddressDetailsFromChild()
            if(this.validateCurrentPhaseFields()){
                if(!this.isWebOffer){
                    this.updateAccountStructureAndData();
                }else{
                    this.updateAccountStructureAndData();
                }
            }
        }else if(this.phase == 4){
            this.fetchProductDetailsFromChild();

            if(this.validateCurrentPhaseFields()){

                //Mandatory checkbox validation (Phase 4) Added by harkirat
                const phase4Cmp = this.template.querySelector(
                    'c-client-auto-enrollment-component-phase-4'
                );

                if (phase4Cmp && !phase4Cmp.validateMandatoryCheckboxes()) {
                    this.showError('Please accept all mandatory terms and conditions before confirming.');
                    return; // Stop execution
                }

                // Marketing preference update
                updateMarketingPreference({
                    contactId: this.primaryContactId,
                    marketingOptIn: this.marketingOptIn
                })
                .then(() => {
                    console.log('Marketing preference updated');
                })
                .catch(error => {
                    console.error('Error updating marketing preference', error);
                });

                //  Final submission
                this.createServicesAndContract();

                // Analytics
                window.dataLayer = window.dataLayer || [];
                window.dataLayer.push({
                    event: 'funnel',
                    funnel_step: 'Step5confirmation',
                    promoCode: this.promoCode || '',
                    light_offer: this.isWebOffer,
                    funnel_product: this.productCode,
                    numberofBeneficiaries: this.noOfBeneficiaries,
                    numberofEmployees: this.noOfEmployees,
                    face_value: this.faceValue,
                    error_status: []
                });
            }
        }else if(this.phase == -1){
            this.showBeneficiaryComp = false;
            this.hasEnterpriseNumber = true;
            this.phase = 2;
        }
    }   
    
    handleBack(){
        if(this.phase == 1 ){
            this.fetchLeadDetailsFromChild();
            if(this.isWebOffer){
                this.phase = -1;
            }else{
                this.phase--;
            }
            
        }else if(this.phase == 2 ){
            if(this.isWebOffer){
                this.phase = -1;
            }else{
                if(this.subPhase === 'contact'){
                    this.subPhase = '';
                }else{
                    this.fetchEnterpriseDetailsFromChild()
                    if(this.hasEnterpriseNumber){
                        this.hasEnterpriseNumber = false;
                    }else{
                        this.phase--;
                    }
                }
            }
        }else if(this.phase == 3){
            this.fetchAddressDetailsFromChild();
            if(this.subPhase != 'contact'){
                this.subPhase = 'contact';
            }
            this.phase--;
        }else if(this.phase == 4){
            this.fetchProductDetailsFromChild();
            this.phase--;
        }
    }

    increase() {
        if(this.noOfBeneficiaries < this.maxBenefCount){
            this.noOfBeneficiaries++;
        }  
    }

    decrease() {
        if (this.noOfBeneficiaries > 0) {
            this.noOfBeneficiaries--;
        }
    }

    handleInput(event) {
        const value = parseInt(event.target.value, 10);
        this.noOfBeneficiaries = isNaN(value) || value < 0 ? 0 : value;
    }
    showError(errMessage){
        const event = new ShowToastEvent({
            title: 'Error',
            message: errMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
    createLead(){
        this.isLoading = true;
        createLead({ leadId: this.createdLeadId, salutation: this.salutation, firstName: this.firstName, lastName: this.lastName, language: this.language, role: this.role, 
            email: this.email, phone: this.dialCodePhone + this.phone, mobile: this.dialCode + this.mobile, optin: this.optin, numberOfBeneficiaries: this.noOfBeneficiaries,
            productId: this.productId, sourceId: this.sourceId, businessUnit: this.businessUnit, promoId: this.fetchedPromoId})
        .then(result => {
            this.isLoading = false;
            console.log('result: ', result);
            this.createdLeadId = result;
            this.isLeadCreated = true;
            this.phase++;
        })
        .catch(error => {
            console.log(error);
        });
    }
    validateCompanyDetails(){
        //this.isLoading = true;
        this.progress = 0;
        this.updateProgressBar();
        this.showProgress =  true;

        this.intervalId = setInterval(() => {
            if (this.progress < 90) {
                this.progress += 2;
                this.updateProgressBar();
            }
        }, 300);

        const apexEnterpriseNum = this.businessUnit === 'LU' ? this.registrationNumber : this.enterpriseNumber;
        const apexRegistrationNum = this.businessUnit === 'LU' ? this.enterpriseNumber : this.registrationNumber;
        validateAndConvertLead({vatNumber: this.codeTVA, subjectToVat: this.vatCheckbox, phone: this.dialCodePhone + this.phone, commercialName: this.commercialName, legalForm: this.legalForm,
            numberOfBeneficiaries: this.noOfBeneficiaries, enterpriseNumber: apexEnterpriseNum, registrationNumber: apexRegistrationNum, billingAddress: this.streetNumber, billingPostalCode: this.postalCode, businessUnit: this.businessUnit,
            productCode: this.productCode, billingCity: this.city, billingCountry: this.pays, productId: this.productId, productName: this.productName, leadId: this.createdLeadId,
            legalName: this.businessName, sourceId: this.sourceId, pageLanguage: this.language, jobTitle: this.jobTitle, department: this.department,
            subDepartment: this.subDepartment
         })
        .then(result=>{
            console.log(JSON.stringify(result));
            this.isLoading = false;
            this.mapOfObj = result;
            this.primaryContactId = this.mapOfObj.contact ? this.mapOfObj.contact.Id : this.mapOfObj.account.HU_HQ_Contact__c;
            this.accountId = this.mapOfObj.account.Id;
            
            if(this.mapOfObj.existingcustomercontract){ 
                this.showErrorComponent = true;
            }else{
                this.opportunityId = this.mapOfObj.opportunity.Id;
                this.subPhase = 'contact';
                window.dataLayer = window.dataLayer || [];
                window.dataLayer.push({
                    event: 'funnel',
                    funnel_step: 'Step2contactdetails',
                    promoCode: this.promoCode || '',
                    light_offer: this.isWebOffer,
                    funnel_product: this.productCode,
                    numberofBeneficiaries: this.noOfBeneficiaries,
                    error_status: []
                });
            }       
        })
        .catch(error =>{
            console.error(error);
            this.isLoading = false;
            
        }) 
        .finally(()=>{
            this.progress = 100;
                this.updateProgressBar();

                clearInterval(this.intervalId);

                // Reset after short delay
                setTimeout(() => {
                    this.progress = 0;
                    this.updateProgressBar();
                }, 1000);

                this.showProgress =  false;
        });
    }
    updateProgressBar() {
        const bar = this.template.querySelector('[data-id="bar"]');
        if (bar) {
            bar.style.setProperty('--progress-width', `${this.progress}%`);
        }
    }
    getCompanyInfo(){
        this.isLoading = true;
        const apexEnterpriseNum = this.businessUnit === 'LU' ? this.registrationNumber : this.enterpriseNumber;
        const apexRegistrationNum = this.businessUnit === 'LU' ? this.enterpriseNumber : this.registrationNumber;
        updateLeadRegistrationFields({
            leadId: this.createdLeadId,
            enterpriseNumber: apexEnterpriseNum,
            registrationNumber: apexRegistrationNum,
            businessUnit: this.businessUnit
        }).catch(error => console.error('updateLeadRegistrationFields failed:', error));
        getInfoFromBelfirst({enterpriseNumber: this.enterpriseNumber, language: this.language, businessUnit: this.businessUnit})
        .then(result=>{
            this.hasEnterpriseNumber = true;
            this.isLoading = false;
            this.enterpriseDetails = result;
            console.log('this.enterpriseDetails: ', this.enterpriseDetails); 
            this.businessName = this.enterpriseDetails.NAME;
            if(this.enterpriseDetails.COMMERCIALNAME != ""){
                this.commercialName = this.enterpriseDetails.COMMERCIALNAME;
            }
            this.codeTVA = this.businessUnit == 'BE' ? this.enterpriseDetails.BVDID: this.enterpriseDetails.LVAT;
            this.streetNumber = this.enterpriseDetails.ADDRESS;
            this.city = this.enterpriseDetails.TOWN;
            this.postalCode = this.enterpriseDetails.POSTCODE;
            this.pays = this.enterpriseDetails.COUNTRY;
            if(this.enterpriseDetails.SUBJECTTOVAT !== ""){
                if(this.enterpriseDetails.SUBJECTTOVAT === "true"){
                    this.vatCheckbox = true;
                }
                else{
                    this.vatCheckbox = false;
                }
            } 
            this.legalForm = this.enterpriseDetails.TYPE;       
        })
        .catch(error=>{
            console.log(error);
            this.showError('We are having a problem with the company information.');
            this.hasEnterpriseNumber = true;
            this.isLoading = false;
        })
    }

    validateCurrentPhaseFields() {
        let isValid = true;
        let currentComponent = null;
        
        const parentInputs = this.template.querySelectorAll('[data-form-element]');
        parentInputs.forEach(input => {
            if (typeof input.checkValidity === 'function' && typeof input.reportValidity === 'function') {
                if (!input.checkValidity()) {
                    input.reportValidity();
                    isValid = false;
                }
            }
        });

        if (this.isPhase1) {
            currentComponent = this.template.querySelector('c-client-auto-enrollment-component-phase-1');
        } else if (this.isPhase2 && this.subPhase == '') {
            currentComponent = this.template.querySelector('c-client-auto-enrollment-component-phase-2');
        } else if (this.isPhase2Contact) {
            currentComponent = this.template.querySelector('c-client-auto-enrollment-component-phase-contact');
        }else if (this.isPhase3) {
            currentComponent = this.template.querySelector('c-client-auto-enrollment-component-phase-3');
        }else if (this.isPhase4) {
            currentComponent = this.template.querySelector('c-client-auto-enrollment-component-phase-4');
        }
        console.log('currentComponent: ', currentComponent);
        if(currentComponent != null){   
            console.log('currentComponent: ', currentComponent.validateFields);
        }
        if (currentComponent && typeof currentComponent.validateFields === 'function') {
            isValid = isValid && currentComponent.validateFields();
        }
    
        return isValid;
    }
    fetchContactDetailsFromChild() {
        const child = this.template.querySelector('c-client-auto-enrollment-component-phase-contact');
        if (child) {
            const {
                primaryContactId,
                billingContactId,
                orderContactId,
                deliveryContactId,
                mapOfContacts,
                isSocialSecretaryHandlingOrders,
                selectedSocialSecretary 
            } = child.getData();
    
            console.log('Got from child (Contacts Phase):', JSON.stringify({
                primaryContactId,
                billingContactId,
                orderContactId,
                deliveryContactId,
                mapOfContacts,
                isSocialSecretaryHandlingOrders,
                selectedSocialSecretary
            }));
            this.primaryContactId = primaryContactId;
            this.billingContactId = billingContactId;
            this.orderContactId = orderContactId;
            this.deliveryContactId = deliveryContactId;
            this.mapOfContacts = mapOfContacts;
            this.isSocialSecretaryHandlingOrders = isSocialSecretaryHandlingOrders;
            this.socialSecretary = selectedSocialSecretary;
        }
    }
    fetchAddressDetailsFromChild() {
        const child = this.template.querySelector('c-client-auto-enrollment-component-phase-3');
        if (child) {
            const {
                faceValue,
                noOfEmployees,
                noOfBeneficiaries,
                shippingName,
                shippingStreet,
                shippingPostalCode,
                shippingCity,
                shippingCountry,
                isEmployeeSameAsBenef,
                isBillingSameAsShipping
            } = child.getData();
    
            console.log('Got from child (Address Phase):', JSON.stringify({
                faceValue,
                noOfEmployees,
                noOfBeneficiaries,
                shippingName,
                shippingStreet,
                shippingPostalCode,
                shippingCity,
                shippingCountry,
                isEmployeeSameAsBenef,
                isBillingSameAsShipping
            }));
    
            this.faceValue = faceValue;
            this.noOfEmployees = noOfEmployees;
            this.noOfBeneficiaries = noOfBeneficiaries;
            this.shippingName = shippingName;
            this.shippingStreet = shippingStreet;
            this.shippingPostalCode = shippingPostalCode;
            this.shippingCity = shippingCity;
            this.shippingCountry = shippingCountry;
            this.isEmployeeSameAsBenef = isEmployeeSameAsBenef;
            this.isBillingSameAsShipping = isBillingSameAsShipping;
            this.estimatedVolume = this.faceValue*this.noOfBeneficiaries*this.daysPerMonth*this.loadPerYear;
        }
    }
    fetchProductDetailsFromChild() {
        const child = this.template.querySelector('c-client-auto-enrollment-component-phase-4');
        if (child) {
            const {
                pricebookId,
                promoId,
                termsAndConditionId,
                productMap,
                hasPromoCode,
                promoCode,
                showPromoError,
                showPromoSuccess,
                //New methods
                //generalCondition,
                //financeCondition,
                //New change by harkirat
                //markettingCondition,
                //businessCondition,
                paymentAck,
                salesConditionAck,
                identityConfirm,
                marketingOptIn,
                legalCondition
            } = child.getData();
    
            console.log('Got from child (Contacts Phase):', JSON.stringify({
                pricebookId,
                promoId,
                termsAndConditionId,
                productMap,
                hasPromoCode,
                promoCode,
                showPromoError,
                showPromoSuccess,
                // generalCondition,
                // financeCondition,
                // //markettingCondition,
                // marketingOptIn,
                // legalCondition,
                // businessCondition
                paymentAck,
                salesConditionAck,
                identityConfirm,
                marketingOptIn,
                legalCondition
            }));
            this.pricebookId = pricebookId;
            this.promoId = promoId;
            this.termsAndConditionId = termsAndConditionId;
            this.productMap = productMap;
            this.hasPromoCode = hasPromoCode;
            this.promoCode = promoCode;
            this.showPromoError = showPromoError;
            this.showPromoSuccess = showPromoSuccess;
            //this.generalCondition = generalCondition;
            //this.financeCondition = financeCondition;
            //Commenting and adding 4 new line
            //this.markettingCondition = markettingCondition;
            this.generalCondition  = true;
            this.financeCondition  = paymentAck;
            this.businessCondition = salesConditionAck;   
            this.legalCondition    = identityConfirm;     
            this.marketingOptIn    = marketingOptIn;
            //this.legalCondition = legalCondition;
            //this.businessCondition = businessCondition;
        }
    }
    fetchEnterpriseDetailsFromChild(){
        const child = this.template.querySelector('c-client-auto-enrollment-component-phase-2');
        if (child) {
            const {
                enterpriseNum,
                registrationNumber,
                businessName,
                commercialName,
                codeTVA,
                streetNumber,
                city,
                postalCode,
                pays,
                vatCheckbox
            } = child.getData();

            console.log('Got from child:', enterpriseNum, registrationNumber, businessName, commercialName, codeTVA, streetNumber, city, postalCode, pays, vatCheckbox);

            // For LU the RCS Number is held in enterpriseNum; keep enterpriseNumber as the Belfirst/account-lookup key
            this.enterpriseNumber = enterpriseNum;
            this.registrationNumber = registrationNumber;
            this.businessName = businessName;
            this.commercialName = commercialName;
            this.codeTVA = codeTVA;
            this.streetNumber = streetNumber;
            this.city = city;
            this.postalCode = postalCode;
            this.pays = pays;
            this.vatCheckbox = vatCheckbox;
            const allValuesNullOrEmpty = [
                enterpriseNum,
                businessName,
                commercialName,
                codeTVA,
                streetNumber,
                city,
                postalCode,
                pays
            ].every(value => !value);

            this.companyValuesAreNull = allValuesNullOrEmpty;
        }
    }
    fetchLeadDetailsFromChild(){
        const child = this.template.querySelector('c-client-auto-enrollment-component-phase-1');
        
        if (child) {
            const { salutation, firstName, lastName, language, role, email, phone, countryCode, dialCode, countryCodePhone, dialCodePhone,  mobile, optin, jobTitle, department, subDepartment} = child.getData();
            console.log('Got from child:', salutation, firstName, lastName, language, role, email, phone, countryCode, dialCode, countryCodePhone, dialCodePhone, mobile, optin);
            this.salutation = salutation;
            this.firstName = firstName;
            this.lastName = lastName;
            this.language = language;
            this.role = role;
            this.email = email;
            this.phone = phone;
            this.mobile = mobile;
            this.countryCode = countryCode;
            this.dialCode = dialCode;
            this.countryCodePhone = countryCodePhone;
            this.dialCodePhone = dialCodePhone;
            this.optin = optin;
            this.jobTitle = jobTitle;
            this.department = department;
            this.subDepartment =subDepartment;
        }
    }
    updateAccountStructureAndData() {
        this.isLoading = true;
        
        updateAccountData({
                noOfEmployees: this.noOfEmployees,
                shippingName: this.shippingName,
                shippingStreet: this.shippingStreet,
                shippingPostalCode: this.shippingPostalCode,
                shippingCity: this.shippingCity,
                shippingCountry: this.shippingCountry,
                isEmployeeSameAsBenef: this.isEmployeeSameAsBenef,
                isBillingSameAsShipping: this.isBillingSameAsShipping,
                enterpriseNumber: this.businessUnit === 'LU' ? this.registrationNumber : this.enterpriseNumber,
                noOfBeneficiaries: this.noOfBeneficiaries,
                opportunityContactRolesMap: this.opportunityContactRolesMap,
                opportunityId: this.opportunityId
        })
        .then(() => {
            this.isLoading = false;
            this.phase++;
            window.dataLayer = window.dataLayer || [];
            window.dataLayer.push({
                event: 'funnel',
                funnel_step: 'Step4signature',
                promoCode: this.promoCode || '',
                light_offer: this.isWebOffer,
                funnel_product: this.productCode,
                numberofBeneficiaries: this.noOfBeneficiaries,
                numberofEmployees: this.noOfEmployees,
                face_value: this.faceValue,
                error_status: []
            });
            console.log('Account structure and data updated successfully.');
            
        })
        .catch(error => {
            this.isLoading = false;
            console.error(error);
            this.showError('Something went wrong while updating account structure and data.');
        });
    }
    upsertContactAndRoles() {
        console.log('Starting upsertContactAndRoles');
    
        const mapOfContactsPayload = {};
        for (const [key, value] of Object.entries(this.mapOfContacts)) {
            mapOfContactsPayload[key] = { ...value };
        }
    
        console.log('Sending mapOfContacts:', JSON.stringify(mapOfContactsPayload));
        console.log('secretaryHandlingOrders:', this.isSocialSecretaryHandlingOrders);
        this.isLoading = true;
        upsertContactsAndRoles({
            opportunityId: this.opportunityId,
            mapOfContacts: mapOfContactsPayload,
            primaryContactId: this.primaryContactId,
            billingContactId: this.billingContactId,
            orderContactId: this.orderContactId,
            deliveryContactId: this.deliveryContactId,
            secretaryHandlingOrders: this.isSocialSecretaryHandlingOrders,
            secretaryName : this.socialSecretary
        })
        .then(result => {
            console.log('Contacts and OCR created successfully:', result);
            this.opportunityContactRolesMap = result;
            this.subPhase = '';
            if(this.noOfBeneficiaries > this.smeSizeLimit){
                this.showMMErrorComp = true;
                this.showErrorComponent = true;
            }else{
                this.phase++;
                window.dataLayer = window.dataLayer || [];
                window.dataLayer.push({
                    event: 'funnel',
                    funnel_step: 'Step3orderdetails',
                    promoCode: this.promoCode || '',
                    light_offer: this.isWebOffer,
                    funnel_product: this.productCode,
                    numberofBeneficiaries: this.noOfBeneficiaries,
                    error_status: []
                });
            }
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error while upserting contacts and OCR:', error);
            this.isLoading = false;
        });
    }

    createServicesAndContract(){
        if (this.productMap && Array.isArray(this.productMap['Delivery'])) {
            const updatedList = this.productMap['Delivery'].map(product => {
                const newProduct = { ...product };
                if (newProduct.maxValue === '...') {
                    delete newProduct.maxValue;
                }
                return newProduct;
            });
 
            this.productMap = {
                ...this.productMap,
                Delivery: updatedList
            };
        }
        const productArray = Object.values(this.productMap).flatMap(list => list);
        console.log('productList: ', JSON.stringify(productArray));
        
        this.isLoading = true;
        createServicesAndContract({promoId: this.promoId, pricebookId: this.pricebookId, generalConditionId: this.generalConditionId,
            noOfBeneficiaries: this.noOfBeneficiaries, faceValue: this.faceValue, daysPerMonth: this.daysPerMonth, loadPerYear: this.loadPerYear,
            estimatedVolume: this.estimatedVolume, opportunityId: this.opportunityId, businessUnit: this.businessUnit, productList: JSON.stringify(productArray)
        })
        .then(result=>{
            console.log(result);
            
            if(result == 'success'){
                this.createQuote();     
            }
        })
        .catch(error=>{
            console.error(error);
        })
    }
    createQuote(){
        createQuote({opportunityId: this.opportunityId})
        .then(result=>{
            console.log(result);
            this.quoteId = result;
            this.createAndSyncContract();
        })
        .catch(error=>{
            this.isLoading = false;
            console.error(error);
        })
    }

    createAndSyncContract(){
        createContract({quoteId: this.quoteId})
        .then(result=>{
            console.log(result);
            if(result != null && result!= ''){
                this.sendPDFToContact(result);
                this.showEnd = true;
                this.showErrorComponent = true;
            } 
        })
        .catch(error=>{
            console.error(error);
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }
    sendPDFToContact(contractId){
        console.log('Checkbox values being sent →', {
        generalCondition: this.generalCondition,
        financeCondition: this.financeCondition,
        businessCondition: this.businessCondition,
        legalCondition: this.legalCondition,
        marketingOptIn: this.marketingOptIn
    });

        submitAgreedToGeneralConditions({contractId: contractId, agreedToGeneralConditions: this.generalCondition, prepaymentAccepted: this.financeCondition, markettingAccepted: this.marketingOptIn, businessAccepted: this.businessCondition, legalAccepted: this.legalCondition,
            opportunityId: this.opportunityId, accountId: this.accountId, stakeholderType: 'Customer', productName: this.productName, productCode: this.productCode, emailAddress: this.email, formLanguage: this.selectedLanguage, 
            estimatedVolume: isNaN(this.estimatedVolume) ? 0 : this.estimatedVolume
        })
        .then(result=>{
            console.log(result);
        })
        .catch(error=>{
            console.error(error);
        })
    }

    fetchDataFromOpportunity(){
        console.log('Final KEY: ', this.key);
        fetchDataFromOpportunity({key: this.key})
        .then(result=>{
            console.log(result);
            if(result.account && result.primaryContact && result.opportunity){
                this.noOfBeneficiaries = result.opportunity.ER_Estimated_Number_Of_Beneficiaries__c;
                this.salutation  = result.primaryContact.Salutation;
                this.firstName  = result.primaryContact.FirstName;
                this.lastName  = result.primaryContact.LastName;
                this.language  = result.primaryContact.ER_Language__c;
                this.role  = result.primaryContact.Business_Role__c;
                this.email  = result.primaryContact.Email;
                this.phone  = result.primaryContact.Phone;
                this.mobile  = result.primaryContact.MobilePhone;
                this.optin = true;
                
                const nifValue = result.account.ER_Enterprise_Number__c
                    ? result.account.ER_Enterprise_Number__c
                    : result.account.ER_Registration_Number__c;
                if (this.businessUnit === 'LU') {
                    this.enterpriseNumber = result.account.RCS_Number__c;
                    this.registrationNumber = nifValue;
                } else {
                    this.enterpriseNumber = nifValue;
                    this.registrationNumber = result.account.RCS_Number__c;
                }
                this.businessName = result.account.ER_Legal_Name__c;
                this.commercialName = result.account.Name;
                this.codeTVA = result.account.ER_VAT_Number__c;
                this.legalForm = result.account.ER_Legal_Form__c;
                this.streetNumber = result.account.BillingStreet;
                this.city = result.account.BillingCity;
                this.postalCode = result.account.BillingPostalCode;
                this.pays = result.account.BillingCountry;
                this.vatCheckbox = result.account.ER_Not_subject_to_VAT__c;

                this.accountId = result.account.Id;

                this.opportunityId = result.opportunity.Id;
                this.primaryContactId = result.primaryContact.Id;
                this.billingContactId = result.billingContact.Id;
                this.orderContactId = result.orderContact.Id;
                this.deliveryContactId = result.deliveryContact.Id;
                this.socialSecretary = result.account.BE_Social_Secretary_Name__c;
                this.isSocialSecretaryHandlingOrders = result.account.ERBE_Social_secretary_needed_for_Orders__c;

                this.promoCode = result.opportunity.ER_Promo_Code2__r.ER_Promo_Code__c;
                this.promoId = result.opportunity.ER_Promo_Code2__c;
                if(this.promoCode){
                    this.hasPromoCode = true;
                }
                

            }else{
                this.showError('Error fetching data or Invalid Key from URL');
            }
        })
        .catch(error=>{
            console.error(error);
            this.showError(error.body.message);
            this.disableNext = true;

        })
        .finally(()=>{
            this.showBeneficiaryComp = false;
            this.hasEnterpriseNumber = true;
            this.phase = 2;
            this.fetchMultiProductDetails();
        })
    }
    fetchMultiProductDetails(){
        fetchMultiProductsFromOpportunity({ opportunityId: this.opportunityId, language: this.selectedLanguage })
        .then(result => {    
            console.log(result);
            this.multiProductList = Object.keys(result).map(key => {
                return {
                    productCode: key,
                    ...result[key]
                };
            });
            console.log(JSON.stringify(this.multiProductList));
        })
        .catch(error => {
            console.error('Error fetching products:', error);
        });
    }

    updateCompany(){
        this.isLoading = true;
        updateEnterpriseDetails({
            accountId:          this.accountId,
            vatNumber:          this.codeTVA,
            subjectToVat:       this.vatCheckbox,
            commercialName:     this.commercialName,
            legalName:          this.businessName,
            billingAddress:     this.streetNumber,
            billingPostalCode:  this.postalCode,
            billingCity:        this.city,
            billingCountry:     this.pays,
            registrationNumber: this.businessUnit === 'LU' ? this.enterpriseNumber : this.registrationNumber
        })
        .then(result=>{
            this.isLoading = false;
            this.subPhase = 'contact';
        })
        .catch(error=>{
            console.error(error);
        })
    }
}