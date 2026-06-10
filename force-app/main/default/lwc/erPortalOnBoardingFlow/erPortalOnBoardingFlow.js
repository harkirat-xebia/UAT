/*************************************************************************************
LWC Name:     ErPortalOnBoardingFlow
Version:      1.0
Created Date: 16/05/2023
Purpose:      Main component for auto enrollment onboarding (merchant only).

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* AAM           16/05/2023  Initial (Auto enrollment on boarding for core (all BUs except BE))
* SLI           01/06/2023  Add onboarding entry page
*************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

// Apex methods
import getLabels from '@salesforce/apex/APER30_AutoEnrollment_Management.getLabels';
import getPicklistInfos from '@salesforce/apex/APER30_AutoEnrollment_Management.getPicklistInfos';
import getCompanyInfosCore from '@salesforce/apex/GenericWithoutSharing.getCompanyInfosCore';
import getCategories from '@salesforce/apex/GenericWithoutSharing.getCategories';
import doApexEvent from '@salesforce/apex/APER30_AutoEnrollment_Management.doApexEvent';
import decrypt from '@salesforce/apex/GenericWithoutSharing.decrypt'; // SLI => 3443
import checkEmailAndContractNb from '@salesforce/apex/GenericWithoutSharing.checkEmailAndContractNb'; // SLI => 3443
import checkStoreNameDuplicate from '@salesforce/apex/GenericWithoutSharing.checkStoreNameDuplicate';
import checkExistingAcceptor from '@salesforce/apex/GenericWithoutSharing.checkExistingAcceptor';

// Captcha resources
import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService';
import challengeValidated from '@salesforce/messageChannel/Challenge_Validated__c';
import selectedLanguage from '@salesforce/messageChannel/Selected_Language__c';
import languageList from '@salesforce/messageChannel/Language_List__c';

// Misceleanous (toast messages, utils functions, platform evt)
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
  isValidEnterpriseNb,
  formatPicklist,
  initPicklistValue,
  initPicklistDisplay,
  resetPicklist,
  checkRequiredFields,
  initFields,
  eraseFieldsAndEnable,
  validateFormat,
  debugLog,
  buildTemplate
} from 'c/erPortalUtils';


export default class ErPortalOnBoardingFlow extends LightningElement {
    currentPageReference = null;
    urlStateParameters = null;
  
    @api country; // Parameter to be set in the builder for the page variation dedicated to the country
    @api lang; // Lang parameter get from url
    @api locale; // Locale parameter get from url
    @api solution; // Product parameter get from url
    @api dbg; // Debug mode (to enable logs display)
    @api obt; // onBoarding token // SLI => 3443
    // @api isFromWebOffer; // Parameter added when url is from quote web offer
    @api scope; // scope parameter get from url
    currentStep = '0';
    phaseTable = {"1":"1", "2":"1", "3":"1", "4":"2", "5":"3"};
    stepValidated;
  
    subscription = null; // used for recaptcha component
    isRecaptchaSuccess;
    @wire(MessageContext)
    messageContext;
  
    showSpinner;
    isReadOnly;
    isReadOnlyEditable;
    hasCheckedEnterpriseNb = true; //TODO Temporary
    existingAccount;
    activatedAccount;
    hasContract;
    ongoingOpp;
    existingClient;
    onboardingAccount;
  
    // Labels for fields, format patterns, error messages
    @track labels = {};
    labelsAllLangs = {};
    isSandbox;
  
    // Picklist values
    @track picklistGroup = {};
    @track companyInfos = {};
    @track storeInfos = {};
  
    @track financialConditions = [];
    @track finCenterInfos = {};
  
    // Store categories (Dependant values)
    @track categories = {};
    @track categorieItems = [];
    @track chosenCategories = [];
    
    stepsCount = 0;
    showHeader;
    @track stepList = [];

    formEmail;
    formContractNumber;
    formCompanyNumber;

    // Get params from URL
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
      if (currentPageReference) {
        this.urlStateParameters = currentPageReference.state;
        this.setParametersBasedOnUrl();
      }
    }
  
    // Init properties from URL params
    setParametersBasedOnUrl() {
      this.solution = this.urlStateParameters.product;
      this.lang = this.urlStateParameters.language.substring(0, 2).toUpperCase();
      this.scope = this.urlStateParameters.scope;
      this.obt = this.urlStateParameters?.obt;
      if(this.obt) {
          this.getEncryptedToken(this.obt);
      }
      this.dbg = this.urlStateParameters.dbg === 'true' ? true : false;
      this.companyInfos.enterpriseNb = this.urlStateParameters.crn;

      this.locale = this.urlStateParameters.language;
  
    }
  
    async connectedCallback() {
      let pkGrp = this.picklistGroup;
      pkGrp.uiLang =
        pkGrp.country =
        pkGrp.salutation =
        pkGrp.lang =
        pkGrp.role =
        pkGrp.storeCountry =
        pkGrp.yesNo =
        pkGrp.isFranchisee =
        pkGrp.sector =
        pkGrp.storeContactSalutation =
        pkGrp.storeContactLang =
        pkGrp.userSalutation =
        pkGrp.userLang =
        pkGrp.terminalType =
        pkGrp.invoicingMethod =
          [];
  
      this.subscribeToMessageChannel(); // Subscribe to recaptcha message service
  
      // Get all labels for fields, messages, etc...
      getLabels({ country: this.country, scope: this.scope })
        .then((data) => {
          this.labelsAllLangs = data;
          this.isSandbox = data.All.isSandbox;
          debugLog(this.dbg, '>>> getLabels() - this.isSandbox ' + this.isSandbox);
          this.switchLanguage(this.lang);

          if(this.labels.lb_steps_onboarding != null){
              let stepCounter = 0;
              this.stepsCount = this.labels.lb_steps_onboarding.split('|').length;
              this.labels.lb_steps_onboarding.split('|').forEach((step) => {
                  stepCounter++;
                  this.stepList.push({nb: stepCounter.toString(), label: step});
              })
              this.showHeader = true;          
          }

          debugLog(this.dbg, '>>> connectedCallback() - this.isWebOffer ' + this.isWebOffer);
  
          getCompanyInfosCore({ enterpriseNb: this.companyInfos.enterpriseNb, country: this.country, lang: this.lang, solutionCode: this.solution, scopeFlow: this.scope, crossSelling: false, isOnBoarding: true })
            .then((data) => {
              debugLog(this.dbg, '>>> getCompanyInfosCore() - data ' + JSON.stringify(data));
              this.companyInfos = {};

              Object.keys(data).forEach((key) => { this.companyInfos[key] = data[key]; });

              this.activatedContract = this.companyInfos.activeProduct; // Show message already have active contract for weboffer
              debugLog(this.dbg, '>>> getCompanyInfosCore() - this.activatedContract ' + this.activatedContract);

              if (!this.activatedContract) {
                this.hasCheckedEnterpriseNb = true;
              }

            })
            .catch((error) => {
              this.expiredQuote = true;
              this.showSpinner = false;
              debugLog(this.dbg, '>>> getCompanyInfosCore()1 - error ' + JSON.stringify(error));
            });

            debugLog(this.dbg, '>>> getCompanyInfosCore() - this.initCategories() 1');
            this.initCategories();
            debugLog(this.dbg, '>>> getCompanyInfosCore() - this.initCategories() 2');

          debugLog(true, '>>> connectedCallback() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> getLabels() - error ' + error);
        });
    }
  
      // Initialise all the number of steps and their respective name
    //   get stepList() {
    //       if(this.labels.lb_steps_onboarding != null){
    //           let steps = [];
    //           let stepCounter = 0;
    //           this.stepsCount = this.labels.lb_steps_onboarding.split('|').length;
    //           this.labels.lb_steps_onboarding.split('|').forEach((step, index) => {
    //               stepCounter++;
    //               steps.push({nb: stepCounter.toString(), label: step});
    //           })
    //           this.showHeader = true;
    //           return steps;
    //       }
    //     //   else{
    //     //       return [ { nb: '1', label: ' ' }];
    //     //   }
    //   }
  
    get phase() {
        return this.phaseTable[this.currentStep];
    }
    // Initialise all the number of steps and their respective name
    // get backgroundImage() {
    //   return "background-image: url('/resource/SRER_Portal/img/wood-lightgrey.jpg');background-size: cover;padding: 0.3rem;";
    // }

    get isStepZeroStoreInfos() {
      return this.currentStep === '0';
    }
    get isStepOneStoreInfos() {
      return this.currentStep === '1';
    }
    get isStepTwoStoreCats() {
      return this.currentStep === '2';
    }
    get isStepThreeStoreMainCat() {
      return this.currentStep === '3';
    }

    get isStepFourTerminal() {
      return this.currentStep === '4';
    }

    get isSummary() {
      return this.currentStep === '5';
    }
  
    get isEndPage() {
      return this.currentStep === '6';
    }

    get isShowHeader() {
      return (this.showHeader && !this.isEndPage && this.currentStep != '0'); // SLI => 3443
    }
  
    get isMerchant(){
        return this.scope == 'M';
    }
  
  
    get isEnableNext() {
      debugLog(true, '>>> isEnableNext() - this.hasCheckedEnterpriseNb ' + this.hasCheckedEnterpriseNb);
      return this.hasCheckedEnterpriseNb && ['1', '2', '3', '4'].includes(this.currentStep);
    }
  
    get isEnablePrev() {
      return this.currentStep != '1' && this.currentStep != '0' && this.currentStep != '6'; // SLI => 3443
    }
  
    get isEnableFinish() {
      return this.currentStep === '5'; 
    }
  
    get showMsg() {
      let result = (
        (this.activatedAccount && !this.onboardingAccount && this.hasContract) ||
         this.ongoingOpp || this.existingClient || this.urlStateParameters.crn || 
        this.companyInfos.badUserEmail
      ); 
      debugLog(this.dbg, '>>> showMsg() - this.ongoingOpp / existingClient' + this.ongoingOpp + ' - ' + this.existingClient);
      debugLog(this.dbg, '>>> showMsg() - result ' + result);
      return result;
    }
  
    get infoMsg() {
      debugLog(this.dbg, '>>> infoMsg() - this.companyInfos ' + JSON.stringify(this.companyInfos));
      return this.activatedAccount && !this.onboardingAccount && this.hasContract
        ? this.labels.lb_err_msg_existing_company
        : this.existingClient
        ? this.labels.lb_err_msg_existing_company_oa
        : null;
    }
  
    get showAddFinCenter() {
      return this.companyInfos.finCentersList.length && !this.isReadOnly;
    }
  
  
    switchLanguage(lang) {
      this.lang = lang;
      this.labels = {
        ...this.labelsAllLangs[this.lang],
        ...this.labelsAllLangs['All']
      };
  
      this.setPicklistInfos();
  
    //   if (this.currentStep == '5') this.initCategories();
    }

    getEncryptedToken(value) { // SLI => 3443
        if(value) {
            if(this.getObjectType(value) == 'Account'
                || this.getObjectType(value) == 'Contract') {
                this.currentStep = '1';
            }
            decrypt({ encryptedText : value})
            .then((data) => {
                console.log('data returned ' + this.getObjectType(data));
                console.log('data returned data ' + data);
                if(this.getObjectType(data) == 'Account'
                    || this.getObjectType(data) == 'Contract') {
                    this.currentStep = '1';
                }
            })
            .catch((error) => {
                debugLog(this.dbg, '>>> obt() - error ' + error);
            })
        }
    }

    getObjectType(value) { // SLI => 3443
        let prefix = value.substring(0, 3);
        switch(prefix) {
            case '001':
                return 'Account';
            case '800':
                return 'Contract';
            default:
                return 'Unknown';
        }
    }

    verifyEmailAndContractNb() { // SLI => 3443
          checkEmailAndContractNb({
            enterpriseNb: this.formCompanyNumber,
            contractNb: this.formContractNumber,
            email: this.formEmail
          }).then((response) => {
             if(response === 'Success') {
                 this.currentStep = '1';
                 debugLog(this.dbg, '>>> handleCheckContractNb() - result OK ');
             }
             if(response === 'Wrong contract') {
                 this.showToast(this.labels.lb_error, this.labels.lb_err_msg_wrong_contract_nb, 'error');
                 debugLog(this.dbg, '>>> handleCheckContractNb() - result wrong contract ');
             }
             else if (response === 'Wrong email') {
                 this.showToast(this.labels.lb_error, this.labels.lb_err_msg_wrong_email, 'error');
                 debugLog(this.dbg, '>>> handleCheckContractNb() - result wrong email ');
             }
          })
          .catch((error) => {
            debugLog(this.dbg, '>>> setPicklistInfos() - error ' + error);
          });
      }

    setPicklistInfos() {
      getPicklistInfos({ country: this.country, lang: this.lang, scope: this.scope })
        .then((data) => {
          debugLog(this.dbg, '>>> setPicklistInfos() - data ' + JSON.stringify(data));
  
          // Set language picklist of the header first
          this.picklistGroup.uiLang = formatPicklist(data.pk_lang_list, this.lang);
          publish(this.messageContext, languageList, this.picklistGroup.uiLang);
  
          this.picklistGroup.country = formatPicklist(data.pk_country, this.storeInfos.country);
          this.picklistGroup.lang = formatPicklist(data.pk_lang, this.storeInfos.lang);
        //   this.picklistGroup.salutation = formatPicklist(data.pk_salutation, this.companyInfos.salutation);
  
        })
        .catch((error) => {
          debugLog(this.dbg, '>>> setPicklistInfos() - error ' + error);
        });
    }
  
    async handleNext() {
      this.validateStep();
      if (this.stepValidated) {
        switch (this.currentStep) {
        case '0':
          this.currentStep = '1'
          break;
        case '1':
          if (await this.verifyStoreNameDuplicate()) this.currentStep = '2';
          break;
        case '2':
          let selectedCats = 0;
          this.chosenCategories.forEach((cat) => {
            if (cat.isChecked == 'true' || cat.isChecked === true) selectedCats++;
          });
          if(selectedCats == 0) this.showToast(this.labels.lb_error, this.labels.lb_step5_errmsg_nb_storecat, 'error'); 
          else this.currentStep = '3';
          // this.showHeader = true;
          break;
        case '3':
          let mainCats = 0;
          if (this.chosenCategories)
            this.chosenCategories.forEach((cat) => { if (cat.isMain == 'true' || cat.isMain === true) mainCats++; });
          if(mainCats == 0) this.showToast(this.labels.lb_error, this.labels.lb_step6_errmsg_nb_main_storecat, 'error'); 
          else this.currentStep = '4';
          break;
        case '4':
          if (await this.verifyAcceptorMidDuplicate()) this.currentStep = '5';
          break;
        case '5':
          this.storeInfos.storeId = 1;
          this.storeInfos.finCenterId = 1;
          this.storeInfos.merchantAccSFId = this.companyInfos.accountId;
          this.storeInfos.storeContactLanguage = this.lang;
          this.storeInfos.hasPhysicalAcceptor = true;
          this.storeInfos.isPhysicalAcceptorMastercard = true;
          this.storeInfos.chosenCategories = this.chosenCategories;
          this.storeInfos.storeType = 'Restaurant';
          this.storeInfos.accName = this.storeInfos.mid2;

          debugLog(this.dbg, '>>> createStores() - storeInfos before create: ' + JSON.stringify(this.storeInfos));
          doApexEvent({ operationName: 'createStores', operationParams: '|' + JSON.stringify([this.storeInfos]) })
          .then((data) => {
            debugLog(this.dbg, '>>> createStores() - data ' + JSON.stringify(data));

            // Contract activation
            let paramsJSON = {
              accountId: this.companyInfos.accountId,
              country: this.country,
              contactEmail: this.companyInfos.email,
              lang: this.lang,
              solution: this.solution,
              scope: this.scope,
              contractId: this.companyInfos.contractId
            };
  
            debugLog(this.dbg, '>>> closeOpportunity() - paramsJSON ' + JSON.stringify(paramsJSON));
  
            doApexEvent({ operationName: 'closeOpportunity', operationParams: JSON.stringify(paramsJSON) })
            .then((data) => { debugLog(this.dbg, '>>> closeOpportunity() - data ' + JSON.stringify(data)); })
            .catch((error) => { debugLog(this.dbg, '>>> closeOpportunity() - error ' + error); });
  
          })
          .catch((error) => {
            debugLog(this.dbg, '>>> createStores() - error ' + error);
          });
          this.currentStep = '6';
          break;
        }
        debugLog(this.dbg, '>>> handleNext() - this.currentStep ' + this.currentStep);
      }
    }
  
    handlePrev() {
      let curStep = this.currentStep;
      debugLog(this.dbg, 'handlePrev - curStep = ' + curStep);
  
      this.currentStep = String(this.currentStep - 1);
      this.template.querySelector('c-er-portal-progress-indicator').scrollIntoView();
      // this.currentStep = curStep;
      debugLog(this.dbg, 'handlePrev - END - this.currentStep = ' + this.currentStep);
    }
  
  
    // generic handler as binding in lwc is one way and to avoid creating one handler per property
    handleStoreInfos(event) {
      debugLog(this.dbg, 'handleStoreInfos - name: ' + event.detail.field + ' - val: ' + event.detail.value);
      this.storeInfos[event.detail.field] = event.detail.value;
      debugLog(this.dbg, 'handleStoreInfos - new value for the field: ' + this.storeInfos[event.detail.field]);
  
      // set picklist to the right option
      if (event.detail.picklist) {
        debugLog(this.dbg, 'handleStoreInfos is picklist ');
        this.picklistGroup[event.detail.field] = initPicklistValue( this.picklistGroup[event.detail.field], event.detail.value );
        debugLog(this.dbg, 'handleStoreInfos new picklist: ' + JSON.stringify(this.picklistGroup[event.detail.field]));
      }
      debugLog(this.dbg, 'handleStoreInfos ***END*** ');
    }

    handleCompanyNumber(event) {
        this.formCompanyNumber = event.detail.value;
    }

    handleContractNumber(event) {
        this.formContractNumber = event.detail.value;
    }

    handleEmail(event) {
        this.formEmail = event.detail.value;
    }


    // generic handler as binding in lwc is one way and to avoid creating one handler per property
    handleCopyCompanyInfos(event) {
        debugLog(this.dbg, 'handleCopyCompanyInfos ***START*** event.detail: ' + event.detail);

        if (event.detail) {
            Object.keys(this.companyInfos).forEach((key) => { this.storeInfos[key] = this.companyInfos[key]; });
            this.storeInfos.name = this.companyInfos.legalName;
            this.storeInfos.storeContactFirstName = this.companyInfos.firstName;
            this.storeInfos.storeContactLastName = this.companyInfos.lastName;
            this.storeInfos.storeContactEmail = this.companyInfos.email;
            this.storeInfos.storeContactPhone = this.companyInfos.contactPhone;
            this.picklistGroup.lang = initPicklistValue( this.picklistGroup.lang, this.storeInfos.lang );
        } else {
            this.storeInfos = {};
            this.picklistGroup.lang = initPicklistValue( this.picklistGroup.lang, null );
        }
        debugLog(this.dbg, 'handleCopyCompanyInfos ***END*** this.storeInfos: ' + JSON.stringify(this.storeInfos));
    }


    validateStep() {
      debugLog(this.dbg, 'validateStep - Start ');
      this.stepValidated = true;
      if (!this.isReadOnly) {
        // Get input and picklist fields
        let inputFields = [...this.template.querySelectorAll('c-er-portal-input')]; // this kind of assignment is done in order to be able to use .filter() function later

        if (this.stepValidated) {
          let checkFormats, requiredFields;
          let pkListFields = this.template.querySelectorAll('c-er-portal-picklist');
          switch (this.currentStep) {
            case '0': // SLI => 3443
              debugLog(this.dbg, 'validateStep - step0 ');
              // // Check required fields in the 1st step
              requiredFields = checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field) && checkRequiredFields(pkListFields, this.labels.lb_err_msg_required_field);

              checkFormats = this.validateFieldsFormat(inputFields);
              this.stepValidated = requiredFields && checkFormats;
              debugLog(this.dbg, 'validateStep (0) - this.stepValidated = ' + this.stepValidated);
              break;
            case '1':
              debugLog(this.dbg, 'validateStep - step1 ');
              // // Check required fields in the 1st step
              requiredFields = checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field) && checkRequiredFields(pkListFields, this.labels.lb_err_msg_required_field);

              checkFormats = this.validateFieldsFormat(inputFields);
              this.stepValidated = requiredFields && checkFormats;
              debugLog(this.dbg, 'validateStep (1) - this.stepValidated = ' + this.stepValidated);
              break;
            case '2':
              debugLog(this.dbg, 'validateStep - step2 ');
              // requiredFields = checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field);
              // checkFormats = this.validateFieldsFormat(inputFields);
              // this.stepValidated = requiredFields && checkFormats;
              break;
            case '3':
              debugLog(this.dbg, 'validateStep - step3 ');
              // if(this.scope == 'M') {
                // requiredFields = checkRequiredFields(inputFields, this.labels.lb_err_msg_required_field);
                // checkFormats = this.validateFieldsFormat(inputFields);
                // this.stepValidated = requiredFields && checkFormats;
              // } else {
                // this.convertLead();
              // }
              break;
            case '4':
              // this.convertLead();
              break;
          }
  
        }
  
      }
      debugLog (this.dbg, 'validateStep - finish: ' + this.stepValidated);
    }
  
    validateFieldsFormat(inputFields) {
      let fieldValidationList = []; // Build array for fields that have a format to be validated
      let otherChecks = true;
  
      inputFields.forEach((field) => {
        switch (field.propertyName) {
          case 'email':
          case 'refundEmail':
          case 'userEmail':
            fieldValidationList.push({
              field: field,
              regex: this.labels.regex_email,
              errMsg: this.labels.lb_err_msg_email_format
            });
            break;
          case 'phone':
          case 'fax':
          case 'refundFax':
          case 'refundContactPhone':
          case 'refundMobile':
          case 'contactPhone':
          case 'mobile':
            fieldValidationList.push({
              field: field,
              regex: this.labels.regex_phone,
              errMsg: this.labels.lb_err_msg_phone_format
            });
            break;
          case 'facebook':
          case 'website':
            fieldValidationList.push({
              field: field,
              regex: this.labels.regex_url,
              errMsg: this.labels.lb_err_msg_url_format
            });
            break;
          case 'fiscalId':
            if (this.displayFiscalId)
              fieldValidationList.push({
                field: field,
                regex: this.labels.regex_fiscalId,
                errMsg: this.labels.lb_err_msg_fiscalId_format
              });
            break;
        }
      });
  
      return validateFormat(fieldValidationList) && otherChecks;
    }
  
  
    // checkDataQty() {
      // debugLog(this.dbg, 'checkDataQty *** START *** ');
      // let isQtyOK = false;
      // // Check if sufficient datas have been filled according to current step
      // switch (this.currentStep) {
        // case '1': //TODO temporary bypass
        // case '2': //TODO temporary bypass
        // case '3': //TODO temporary bypass
        // case '4': //TODO temporary bypass
        // case '7': //TODO temporary bypass
          // isQtyOK = true;
          // break;
      // }
      // debugLog(this.dbg, 'checkDataQty - isQtyOK = ' + isQtyOK + ' for step ' + this.currentStep);
      // return isQtyOK;
    // }
  


    initCategories() {
        debugLog( this.dbg, '>>> initCategories() ***START***');
        this.categorieItems = [];
        debugLog( this.dbg, '>>> initCategories() - this.chosenCategories: ' + JSON.stringify(this.chosenCategories) );

        // getCategories({ country: this.country, solution: this.solution, existingCatsCsv: null })
          //TODO to replace line below by the one before (just for test purpose)
        getCategories({ country: 'BE', solution: 'ERBE_TRE-M', existingCatsCsv: null })
          .then((data) => {
            const lang = this.lang.toLowerCase();
            let locale = Object.keys(data).filter((elem) => elem.toLowerCase().includes(lang))[0];
            debugLog(this.dbg, '>>> initCategories() - data: ' + JSON.stringify(data));
            debugLog(this.dbg, '>>> initCategories() - lang: ' + this.lang + ' , locale: ' + locale);
            //TODO temporary force locale for testing purpose
            if(!locale) locale = 'fr';

            debugLog(this.dbg, '>>> initCategories() - locale2: ' + locale);
            this.categories = JSON.parse(JSON.stringify(data[locale])); // Dirty hack to prevent from "object is not extensible" exception
    
            // Init list of categories (1st step) & list of chosen categories (2nd step) for existing stores
            let sortedtreeKeys = Object.keys(this.categories).sort();
            sortedtreeKeys.forEach((elem) => {
            //   if (this.categories[elem].solution == this.solution) {
          //TODO to replace line below by the one before (just for test purpose)
              if (this.categories[elem].solution == 'ERBE_TRE-M') {
                this.categories[elem].treeKey = elem; // In order to manage display hide cat in handleToggleCategorie()
                this.categories[elem].showItem = this.categories[elem].level === '1'; //  Show only level 1 Items in the beginning
                this.categories[elem].className = this.categories[elem].level === '1' || this.categories[elem].isParent == 'true' ? 'categorie-item__parent' : 'categorie-item__child';
                this.categories[elem].selectable = this.categories[elem].isParent == 'true' ? false : true;
                this.categories[elem].levelOffset = 'margin-left:' + (this.categories[elem].level - 1) * 10 + '%;'; // Set the margin according to cat level
                if (!this.categories[elem].selectable) this.categories[elem].showChilds = false;
    
                this.categorieItems.push(this.categories[elem]);
              } else {
                this.categories[elem].isChecked = true;
                this.chosenCategories.push(this.categories[elem]);
              }
            });
    
            debugLog( this.dbg, '>>> initCategories() - this.categorieItems: ' + JSON.stringify(this.categorieItems) );
    
            // let chosenCategoriesIds = this.chosenCategories.map((value) => value.id);
    
            // if (this.chosenCategories.length > 0) {
            //   this.chosenCategories.forEach((cat) => {
            //     debugLog(this.dbg, '>>> initCategories() - cat: ' + JSON.stringify(cat));
    
            //     let catFound = false;
            //     this.categorieItems.forEach((cat2) => {
            //       if (cat2.id == cat.id && !catFound) {
            //         cat2.isChecked = cat.isChecked;
            //         cat2.isMain = cat.isMain;
            //         catFound = true;
            //         if (cat2.isChecked && !chosenCategoriesIds.includes(cat2.id)) this.chosenCategories.unshift(cat2);
            //       }
            //     });
    
            //     if (!catFound) {
            //       // case category from another solution
            //       this.chosenCategories.forEach((cat3) => {
            //         if (cat3.id == cat.id) cat3.isMain = cat.isMain;
            //       });
            //     }
            //   });
            // }
            debugLog(this.dbg, '>>> initCategories() - ***END1*** ' + JSON.stringify(this.categorieItems));
          })
          .catch((error) => {
            debugLog(this.dbg, '>>> initCategories() - error ' + error);
            debugLog(this.dbg, '>>> initCategories() - error str ' + JSON.stringify(error));
          });
        debugLog(this.dbg, '>>> initCategories() - ***END2*** ');
    }
  

    handleToggleCategorie(event) {
      debugLog(this.dbg, 'handleToggleCategorie -- event.target.id: ' + event.target.id);
      const curCatId = event.target.id.substring(0, event.target.id.indexOf('-'));
      const catId = event.target.id.substring(event.target.id.indexOf('*') + 1, event.target.id.indexOf('-')); //Used for treeKey filtering
         // get current category
      const curCat = this.categorieItems.filter((elem) => elem.id == curCatId)[0];
         // get items to display
      let catsToShow = this.categorieItems.filter(
        (elem) => elem.treeKey.includes(catId) && elem.level == parseInt(curCat.level) + 1
      );
      // check wether childs are not displayed, then they have to be displayed, otherwise they have to be hidden
      if (!catsToShow[0].showItem) {
        debugLog(this.dbg, 'handleToggleCategorie -- catsToShow length: ' + catsToShow.length);
        catsToShow.forEach((childCat) => (childCat.showItem = true));
      } else {
        // get items to be hidden
        let catsToHide = this.categorieItems.filter(
          (elem) => elem.treeKey.includes(catId) && elem.level > parseInt(curCat.level)
        );
        catsToHide.forEach((childCat) => (childCat.showItem = false));
      }
      if (typeof curCat.showChilds !== 'undefined') curCat.showChilds = !curCat.showChilds;
         debugLog(this.dbg, 'handleToggleCategorie -- END ');
    }
       handleSelectCategorie(event) {
      debugLog(
        this.dbg,
        'handleSelectCategorie -- event.target.id: ' + event.target.id + ' event.target.checked: ' + event.target.checked
      );
      const curCatId = event.target.id.substring(0, event.target.id.indexOf('-'));
      debugLog(this.dbg, 'handleSelectCategorie -- this.chosenCategories: ' + JSON.stringify(this.chosenCategories));
      debugLog(this.dbg, 'handleSelectCategorie -- this.categorieItems: ' + JSON.stringify(this.categorieItems));
         this.categorieItems.forEach((cat) => {
        if (cat.id == curCatId) {
          cat.isChecked = event.target.checked;
          cat.isMain = false;
          let catFound = false;
          if (event.target.checked) {
            this.chosenCategories.forEach((cat2) => {
              if (cat2.id == curCatId && !catFound) {
                catFound = true;
              }
            });
            if (!catFound) this.chosenCategories.push(cat);
          } else {
            let catIndex;
            this.chosenCategories.forEach((cat3, index) => {
              if (cat3.id == curCatId) catIndex = index;
            });
            this.chosenCategories.splice(catIndex, 1);
          }
        }
      });
         debugLog(this.dbg, 'handleSelectCategorie -- this.chosenCategories2: ' + JSON.stringify(this.chosenCategories));
      debugLog(
        this.dbg,
        'handleSelectCategorie -- ***END*** -- this.chosenCategories: ' + JSON.stringify(this.chosenCategories)
      );
    }
       handleSelectMainCategory(event) {
      debugLog(
        this.dbg,
        'handleSelectMainCategory -- event.target.id: ' +
          event.target.id +
          ' event.target.checked: ' +
          event.target.checked
      );
      const curCatId = event.target.id.substring(event.target.id.indexOf('*') + 1, event.target.id.indexOf('-')); // get Category Id
      debugLog(this.dbg, 'handleSelectMainCategory -- curCatId: ' + curCatId);
      // this.chosenCategories.forEach((cat) => {if(cat.id == curCatId) cat.isMain = event.target.checked;});
      this.chosenCategories.forEach((cat) => (cat.isMain = cat.id == curCatId));
         debugLog(this.dbg, 'handleSelectMainCategory -- ***END***');
    }

    async verifyStoreNameDuplicate() {
      let result = await checkStoreNameDuplicate({ storeName: this.storeInfos.name, businessUnit: this.companyInfos.businessUnit });
      debugLog(this.dbg, '>>> verifyStoreNameDuplicate() - result ' + result);
      if(!result) this.showToast(this.labels.lb_error, this.labels.lb_err_msg_duplicate_store_name, 'error');
      return result;
    }
    
    async verifyAcceptorMidDuplicate() {
      let result = await checkExistingAcceptor({ idType: 'mid', id1: this.storeInfos.mid2, id2: this.storeInfos.subMid2, mastercardOnly: false });
      debugLog(this.dbg, '>>> verifyAcceptorMidDuplicate() - result ' + result);
      if(!result) this.showToast(this.labels.lb_error, this.labels.lb_err_msg_duplicate_mid_submid, 'error');
      return result;
    }
    
    // Message service subscribe and unsubsubscribe for recaptcha component and select language
    subscribeToMessageChannel() {
      if (!this.subscription) {
        this.subscription = subscribe(
          this.messageContext,
          challengeValidated,
          (message) => this.handleRecaptcha(message),
          { scope: APPLICATION_SCOPE }
        );
      }
      subscribe(this.messageContext, selectedLanguage, (message) => this.switchLanguage(message.lang), {
        scope: APPLICATION_SCOPE
      });
    }
  
    // Handler for message received by recaptcha component
    handleRecaptcha(message) {
      this.isRecaptchaSuccess = message.isSuccess;
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